import SwiftUI
import Combine
import CoreData
import Usecase
import Core
import CoreLocation

class ActivityViewModel: ObservableObject {
    // MARK: - Properties
    let context: NSManagedObjectContext?
    private let healthKitAPI: HealthKitAPI
    
    @Published private(set) var state: State = .idle() {
        didSet {
            print("ActivityView", state)
            handleStateChange(state)
        }
    }
    
    @Published var selectedDate: Date = Date() {
        didSet {
            send(event: .monthChanged(selectedDate))
        }
    }
    
    @Published var expandedSections: Set<Date> = []
    @Published private(set) var similarTrackCache: [UUID: Bool] = [:]
    @Published private(set) var isAnalyzingPatterns = false
    @Published var selectedWorkoutForCourse: WorkoutData?
    
    private var patternAnalysisQueue = DispatchQueue(label: "com.laps.patternAnalysis", qos: .utility)
    private var patternAnalysisTasks: [UUID: Task<Void, Never>] = [:]
    
    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext? = nil) {
        self.context = context
        self.healthKitAPI = HealthKitAPI()
        
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.processing(healthKitAPI: healthKitAPI, selectedDate: $selectedDate),
                Self.userInput(input: input.eraseToAnyPublisher()),
                Self.sideEffects(viewModel: self)
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
        
        // Listen for new course creation
        NotificationCenter.default.publisher(for: .newCourseCreated)
            .sink { [weak self] _ in
                self?.handleNewCourseCreated()
            }
            .store(in: &bag)
    }
    
    deinit {
        bag.removeAll()
    }
}

// MARK: - State Management
extension ActivityViewModel {
    func send(event: Event) {
        input.send(event)
    }
    
    private func handleStateChange(_ newState: State) {
        if case .idle(let data) = newState {
            if data == nil {
                send(event: .loadData)
            } else {
                // Start pattern analysis for all workouts
                if let workouts = data?.workouts, !workouts.isEmpty {
                    preloadPatternAnalysis(for: workouts)
                }
            }
        }
    }
}


// MARK: - State & Event Types
extension ActivityViewModel {
    enum State: Equatable {
        case idle(data: ActivityData? = nil)
        case authorizationRequested
        case dataLoading
        case error(ActivityError)
    }
    
    enum Event {
        case requestAuthorization
        case authorizationGranted
        case authorizationDenied
        case monthChanged(Date)
        case loadData
        case dataLoaded(ActivityData)
        case loadDataFailed(ActivityError)
        case retry
        case toggleSection(Date)
    }
}

// MARK: - State Machine
extension ActivityViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle(let data):
            switch event {
            case .requestAuthorization:
                return .authorizationRequested
            case .monthChanged, .loadData:
                return .dataLoading
            case .toggleSection:
                return state  // State remains the same, but side effect is handled elsewhere
            default:
                return state
            }
        case .authorizationRequested:
            switch event {
            case .authorizationGranted:
                return .dataLoading
            case .authorizationDenied:
                return .error(.authorizationDenied)
            default:
                return state
            }
        case .dataLoading:
            switch event {
            case .dataLoaded(let data):
                return .idle(data: data)
            case .loadDataFailed(let error):
                return .error(error)
            default:
                return state
            }
        case .error:
            switch event {
            case .retry:
                return .dataLoading
            case .requestAuthorization:
                return .authorizationRequested
            default:
                return state
            }
        }
    }
}

// MARK: - Feedback System
extension ActivityViewModel {
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
    
    static func sideEffects(viewModel: ActivityViewModel) -> Feedback<State, Event> {
        Feedback { _ in
            viewModel.input
                .handleEvents(receiveOutput: { event in
                    switch event {
                    case .toggleSection(let date):
                        if viewModel.expandedSections.contains(date) {
                            viewModel.expandedSections.remove(date)
                        } else {
                            viewModel.expandedSections.insert(date)
                        }
                    case .dataLoaded(let data):
                        // Initialize all sections as expanded when new data is loaded
                        let groupedWorkouts = Dictionary(grouping: data.workouts) { workout in
                            Calendar.current.startOfDay(for: workout.date)
                        }
                        viewModel.initializeExpandedSections(with: Set(groupedWorkouts.keys))
                    default:
                        break
                    }
                })
                .filter { _ in false }  // Don't emit any events back
                .eraseToAnyPublisher()
        }
    }

    static func processing(healthKitAPI: HealthKitAPI, selectedDate: Published<Date>.Publisher) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            switch state {
            case .authorizationRequested:
                return requestAuthorization(healthKitAPI: healthKitAPI)
            case .dataLoading:
                return selectedDate
                    .first()
                    .flatMap { date in
                        fetchActivityData(healthKitAPI: healthKitAPI, date: date)
                    }
                    .eraseToAnyPublisher()
            default:
                return Empty().eraseToAnyPublisher()
            }
        }
    }
    
    private static func requestAuthorization(healthKitAPI: HealthKitAPI) -> AnyPublisher<Event, Never> {
        return healthKitAPI.requestReadAuthorization()
            .map { success in
                success ? Event.authorizationGranted : Event.authorizationDenied
            }
            .catch { _ in
                Just(Event.authorizationDenied)
            }
            .eraseToAnyPublisher()
    }

    private static func fetchActivityData(healthKitAPI: HealthKitAPI, date: Date) -> AnyPublisher<Event, Never> {
        return healthKitAPI.fetchActivityData(date: date)
            .map { data in
                let totalSteps = data.steps.reduce(0) { $0 + $1.value }
                let totalDistance = data.distance.reduce(0) { $0 + $1.value }
                let totalCalories = data.calories.reduce(0) { $0 + $1.value }
                
                let workoutsData = data.workouts.map { workout in
                    WorkoutData(
                        id: UUID(),
                        healthKitId: workout.id,
                        date: workout.date,
                        activityType: workout.activityType.name,
                        duration: workout.duration,
                        totalEnergyBurned: workout.totalEnergyBurned,
                        totalDistance: workout.distance,
                        pace: workout.avgPace ?? 0,
                        sourceName: workout.sourceName,
                        route: workout.route.map { LocationData(from: $0) }
                    )
                }
                
                // Calculate daily calories from data.calories
                let calendar = Calendar.current
                var dailyCalories: [Date: Double] = [:]
                for calorie in data.calories {
                    let dayStart = calendar.startOfDay(for: calorie.date)
                    dailyCalories[dayStart] = calorie.value
                }
                
                
                let activityData = ActivityData(
                    date: date,
                    steps: Int(totalSteps),
                    walkingDistance: totalDistance,
                    activeEnergy: totalCalories,
                    latestHeartRate: data.heartRate ?? 0,
                    workouts: workoutsData,
                    dailyCalories: dailyCalories
                )
                
                return Event.dataLoaded(activityData)
            }
            .catch { _ in
                Just(Event.loadDataFailed(.dataFetchFailed("Failed to fetch health data")))
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - UI State Methods
extension ActivityViewModel {
    func initializeExpandedSections(with dates: Set<Date>) {
        expandedSections = dates
    }
    
    func selectWorkoutForCourse(_ workout: WorkoutData) {
        selectedWorkoutForCourse = workout
    }
    
    func clearSelectedWorkoutForCourse() {
        selectedWorkoutForCourse = nil
    }
}

// MARK: - Pattern Analysis
extension ActivityViewModel {
    func hasSimilarTrack(for workout: WorkoutData) -> Bool {
        // Return cached result if available
        if let cached = similarTrackCache[workout.id] {
            return cached
        }
        
        // If no cache and route is empty, return false immediately
        guard !workout.route.isEmpty else {
            similarTrackCache[workout.id] = false
            return false
        }
        
        // Check CoreData cache first
        if let healthKitId = workout.healthKitId,
           let cachedResult = fetchCachedAnalysis(for: healthKitId) {
            similarTrackCache[workout.id] = cachedResult
            return cachedResult
        }
        
        // Start background analysis if not already running
        startPatternAnalysisIfNeeded(for: workout)
        
        // Return false for now (will update when analysis completes)
        return false
    }
    
    func preloadPatternAnalysis(for workouts: [WorkoutData]) {
        // Start analysis for all workouts with routes
        for workout in workouts where !workout.route.isEmpty && similarTrackCache[workout.id] == nil {
            startPatternAnalysisIfNeeded(for: workout)
        }
    }
    
    private func startPatternAnalysisIfNeeded(for workout: WorkoutData) {
        // Skip if already analyzing this workout
        guard patternAnalysisTasks[workout.id] == nil else { return }
        guard let context = context else { return }
        
        // Create background task
        let task = Task { @MainActor in
            // Mark as analyzing
            if patternAnalysisTasks.isEmpty {
                isAnalyzingPatterns = true
            }
            
            let workoutId = workout.id
            let workoutCoords = workout.route.map { 
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
            }
            
            // Perform analysis in background
            let hasSimilar = await withCheckedContinuation { continuation in
                patternAnalysisQueue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume(returning: false)
                        return
                    }
                    
                    let result = self.performPatternAnalysis(
                        workoutCoords: workoutCoords,
                        context: context
                    )
                    continuation.resume(returning: result)
                }
            }
            
            // Update cache on main thread
            similarTrackCache[workoutId] = hasSimilar
            
            // Save to CoreData cache if healthKitId exists
            if let healthKitId = workout.healthKitId {
                self.saveCachedAnalysis(workoutId: healthKitId, hasSimilar: hasSimilar, context: context)
            }
            
            // Clean up task
            patternAnalysisTasks.removeValue(forKey: workoutId)
            
            // Update analyzing state
            if patternAnalysisTasks.isEmpty {
                isAnalyzingPatterns = false
            }
        }
        
        patternAnalysisTasks[workout.id] = task
    }
    
    private func performPatternAnalysis(
        workoutCoords: [CLLocationCoordinate2D],
        context: NSManagedObjectContext
    ) -> Bool {
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        
        do {
            let tracks = try context.fetch(fetchRequest)
            
            for track in tracks {
                if let encodedRoute = track.route, 
                   let trackRoute = encodedRoute.decodePolyline() {
                    
                    let result = RouteSimilarityChecker.checkSimilarity(
                        route1: workoutCoords,
                        route2: trackRoute,
                        distanceThreshold: 30.0,  // 30 meters threshold
                        coverageThreshold: 0.7    // 70% coverage required
                    )
                    
                    if result.isSimilar {
                        print("Similar track found: \(track.name ?? "Unknown") - \(result.reason)")
                        return true
                    }
                }
            }
        } catch {
            print("Error fetching tracks: \(error)")
        }
        
        return false
    }
}

// MARK: - CoreData Cache Methods
extension ActivityViewModel {
    private func fetchCachedAnalysis(for workoutId: UUID) -> Bool? {
        guard let context = context else { return nil }
        
        let fetchRequest: NSFetchRequest<WorkoutAnalysisCache> = WorkoutAnalysisCache.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutId == %@", workoutId as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first?.hasSimilarTrack
        } catch {
            print("Error fetching cached analysis: \(error)")
            return nil
        }
    }
    
    private func saveCachedAnalysis(workoutId: UUID, hasSimilar: Bool, context: NSManagedObjectContext) {
        context.perform {
            // Check if cache already exists
            let fetchRequest: NSFetchRequest<WorkoutAnalysisCache> = WorkoutAnalysisCache.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "workoutId == %@", workoutId as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let results = try context.fetch(fetchRequest)
                let cache = results.first ?? WorkoutAnalysisCache(context: context)
                
                cache.workoutId = workoutId
                cache.hasSimilarTrack = hasSimilar
                cache.analyzedAt = Date()
                
                try context.save()
            } catch {
                print("Error saving cached analysis: \(error)")
            }
        }
    }
    
    private func clearFalseCaches() {
        guard let context = context else { return }
        
        context.perform {
            let fetchRequest: NSFetchRequest<WorkoutAnalysisCache> = WorkoutAnalysisCache.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "hasSimilarTrack == %@", NSNumber(value: false))
            
            do {
                let cachesToDelete = try context.fetch(fetchRequest)
                cachesToDelete.forEach { context.delete($0) }
                try context.save()
                print("Cleared \(cachesToDelete.count) false caches")
            } catch {
                print("Error clearing false caches: \(error)")
            }
        }
    }
}

// MARK: - New Course Created Handler
extension ActivityViewModel {
    private func handleNewCourseCreated() {
        guard let context = context else { return }
        
        // Clear false caches from CoreData
        clearFalseCaches()
        
        // Clear in-memory cache for workouts without similar tracks
        let workoutsToReanalyze = similarTrackCache.compactMap { (key, value) -> UUID? in
            return value == false ? key : nil
        }
        
        // Remove from cache
        workoutsToReanalyze.forEach { id in
            similarTrackCache.removeValue(forKey: id)
        }
        
        // Re-analyze workouts that previously had no similar tracks
        if case .idle(let data) = state, let workouts = data?.workouts {
            let workoutsWithoutSimilarTracks = workouts.filter { workout in
                workoutsToReanalyze.contains(workout.id) && !workout.route.isEmpty
            }
            
            // Trigger re-analysis
            for workout in workoutsWithoutSimilarTracks {
                _ = hasSimilarTrack(for: workout)
            }
        }
    }
}

// MARK: - View Support Methods
extension ActivityViewModel {
    func generateMonthOptions() -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Generate last 12 months including current month
        for monthOffset in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate) {
                // Set to first day of month
                if let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start {
                    dates.append(startOfMonth)
                }
            }
        }
        
        return dates
    }
    
    func calculateDailyCalories(for date: Date) -> Double? {
        guard case .idle(let data) = state,
              let activityData = data else { return nil }
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        return activityData.dailyCalories[dayStart]
    }
}
