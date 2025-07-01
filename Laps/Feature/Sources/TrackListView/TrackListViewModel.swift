//
//  TrackListViewModel.swift
//  Feature
//
//  Created by Assistant on 2025/06/21.
//

import SwiftUI
import Combine
import CoreData
import Core
import CoreLocation

class TrackListViewModel: ObservableObject {
    @Published private(set) var state: State = .idle
    @Published var selectedTrack: TrackItem?
    
    private let context: NSManagedObjectContext
    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()
    
    init(context: NSManagedObjectContext) {
        self.context = context
        
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.whenLoading(context: context),
                Self.whenDeleting(context: context, input: input.eraseToAnyPublisher()),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
    }
    
    deinit {
        bag.removeAll()
    }
    
    func send(event: Event) {
        input.send(event)
    }
    
    // MARK: - State & Events
    
    enum State: Equatable {
        case idle
        case loading
        case loaded(TrackListData)
        case error(TrackListError)
    }
    
    enum Event {
        case loadTracks
        case tracksLoaded([Track])
        case loadFailed(TrackListError)
        case deleteTrack(TrackItem)
        case deleteCompleted
        case deleteFailed(TrackListError)
        case retry
    }
    
    // MARK: - State Reducer
    
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle:
            switch event {
            case .loadTracks:
                return .loading
            default:
                return state
            }
            
        case .loading:
            switch event {
            case .tracksLoaded(let tracks):
                let trackItems = tracks.compactMap { track -> TrackItem? in
                    guard let id = track.id,
                          let name = track.name,
                          let createdDate = track.createdate,
                          let encodedRoute = track.route else {
                        return nil
                    }
                    
                    return TrackItem(
                        id: id,
                        name: name,
                        createdDate: createdDate,
                        distance: track.distance,
                        centerCoordinate: CLLocationCoordinate2D(
                            latitude: track.centerLatitude,
                            longitude: track.centerLongitude
                        ),
                        encodedRoute: encodedRoute
                    )
                }
                return .loaded(TrackListData(tracks: trackItems))
                
            case .loadFailed(let error):
                return .error(error)
                
            default:
                return state
            }
            
        case .loaded:
            switch event {
            case .loadTracks:
                return .loading
            case .deleteTrack:
                return state // Stay in loaded state during deletion
            case .deleteCompleted:
                return .loading // Reload after successful deletion
            case .deleteFailed(let error):
                return .error(error)
            default:
                return state
            }
            
        case .error:
            switch event {
            case .retry, .loadTracks:
                return .loading
            default:
                return state
            }
        }
    }
    
    // MARK: - Feedbacks
    
    static func whenLoading(context: NSManagedObjectContext) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            guard case .loading = state else { return Empty().eraseToAnyPublisher() }
            
            let request: NSFetchRequest<Track> = Track.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Track.createdate, ascending: false)]
            
            return CoreDataFetchResultsPublisher(
                request: request,
                context: context
            )
            .map { tracks in
                Event.tracksLoaded(tracks)
            }
            .catch { error in
                Just(Event.loadFailed(.fetchFailed(error.localizedDescription)))
            }
            .eraseToAnyPublisher()
        }
    }
    
    static func whenDeleting(context: NSManagedObjectContext, input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in
            input
                .compactMap { event -> TrackItem? in
                    if case .deleteTrack(let track) = event {
                        return track
                    }
                    return nil
                }
                .flatMap { track -> AnyPublisher<Event, Never> in
                    let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Track")
                    request.predicate = NSPredicate(format: "id == %@", track.id as CVarArg)
                    
                    return CoreDataDeleteModelPublisher(
                        delete: request,
                        context: context
                    )
                    .tryMap { result -> Event in
                        try context.save()
                        return Event.deleteCompleted
                    }
                    .catch { error in
                        Just(Event.deleteFailed(.deleteFailed(error.localizedDescription)))
                    }
                    .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
    
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
    
    // MARK: - Public Methods
    
    var tracks: [TrackItem] {
        if case .loaded(let data) = state {
            return data.tracks
        }
        return []
    }
}
