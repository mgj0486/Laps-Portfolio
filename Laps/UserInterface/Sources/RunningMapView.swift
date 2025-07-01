//
//  RunningMapView.swift
//  UserInterface
//
//  Created by Assistant on 2025/06/22.
//

import SwiftUI
import MapKit
import CoreLocation
import Core
import CoreData

public struct RunningMapView: UIViewRepresentable {
    let currentLocation: CLLocation?
    let heading: CLHeading?
    let runningPath: [CLLocationCoordinate2D]
    let nearbyTracks: [TrackMapItem]
    @Binding var region: MKCoordinateRegion
    @Environment(\.colorScheme) var colorScheme
    
    public struct TrackMapItem: Equatable {
        public let id: UUID
        public let name: String
        public let route: [CLLocationCoordinate2D]
        public let distance: Double // in meters
        
        public init(id: UUID, name: String, route: [CLLocationCoordinate2D], distance: Double) {
            self.id = id
            self.name = name
            self.route = route
            self.distance = distance
        }
        
        public static func == (lhs: TrackMapItem, rhs: TrackMapItem) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    public init(currentLocation: CLLocation?, heading: CLHeading? = nil, runningPath: [CLLocationCoordinate2D], nearbyTracks: [TrackMapItem], region: Binding<MKCoordinateRegion>) {
        self.currentLocation = currentLocation
        self.heading = heading
        self.runningPath = runningPath
        self.nearbyTracks = nearbyTracks
        self._region = region
    }
    
    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false  // We'll use custom annotation
        mapView.userTrackingMode = .none  // Don't auto-follow to allow manual dragging
        mapView.mapType = .standard
        mapView.showsBuildings = false
        mapView.showsPointsOfInterest = false
        
        // Allow only scrolling, disable zoom but enable rotation for heading
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = true  // Enable rotation for heading
        mapView.isPitchEnabled = false
        
        return mapView
    }
    
    public func updateUIView(_ mapView: MKMapView, context: Context) {
        // Apply dark mode style
        mapView.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        
        // Set fixed zoom level
        let fixedSpan = MKCoordinateSpan(
            latitudeDelta: 0.005,  // Approximately 500m
            longitudeDelta: 0.005
        )
        
        // Update center and rotation if current location is available and user is not dragging
        if let location = currentLocation, !context.coordinator.isUserDragging {
            // Update map rotation based on heading
            if let heading = heading {
                print("Heading available: \(heading.trueHeading) degrees")
                
                // Calculate heading difference for smoother animation
                let headingDifference = abs(heading.trueHeading - context.coordinator.lastHeading)
                let timeSinceLastUpdate = Date().timeIntervalSince(context.coordinator.lastUpdateTime)
                
                // Only update if heading changed significantly or enough time passed
                if headingDifference > 3.0 || timeSinceLastUpdate > 0.5 {
                    context.coordinator.lastHeading = heading.trueHeading
                    context.coordinator.lastUpdateTime = Date()
                    
                    // Determine animation duration based on heading change
                    let animationDuration = headingDifference > 30 ? 0.8 : 0.5
                    
                    // Create smooth camera animation
                    UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                        let camera = MKMapCamera()
                        camera.heading = heading.trueHeading
                        camera.centerCoordinate = location.coordinate
                        camera.altitude = self.getAltitudeForSpan(fixedSpan, at: location.coordinate)
                        camera.pitch = 0
                        
                        mapView.setCamera(camera, animated: true)
                    })
                }
            } else {
                print("No heading available")
                let newRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: fixedSpan
                )
                
                // Check if we need to update (location changed significantly)
                let centerDelta = abs(mapView.region.center.latitude - location.coordinate.latitude) + 
                                  abs(mapView.region.center.longitude - location.coordinate.longitude)
                
                if centerDelta > 0.0001 {
                    // Smooth animation for region updates
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                        mapView.setRegion(newRegion, animated: true)
                    })
                }
            }
        } else if !isSpanEqual(mapView.region.span, fixedSpan) {
            // Just fix the zoom if it changed
            let fixedRegion = MKCoordinateRegion(
                center: mapView.region.center,
                span: fixedSpan
            )
            mapView.setRegion(fixedRegion, animated: false)
        }
        
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { 
            !($0 is MKUserLocation) && !($0 is UserLocationAnnotation) 
        })
        
        // Add custom user location if available
        if let location = currentLocation {
            // Remove existing user location annotation if any
            let existingUserAnnotations = mapView.annotations.compactMap { $0 as? UserLocationAnnotation }
            mapView.removeAnnotations(existingUserAnnotations)
            
            // Add new user location annotation
            let userAnnotation = UserLocationAnnotation(
                coordinate: location.coordinate,
                heading: heading?.trueHeading
            )
            mapView.addAnnotation(userAnnotation)
        }
        
        print("Updating map with \(nearbyTracks.count) nearby tracks")
        
        // Add nearby tracks
        for track in nearbyTracks {
            if track.route.count > 1 {
                let polyline = MKPolyline(coordinates: track.route, count: track.route.count)
                polyline.title = "track-\(track.id.uuidString)"
                polyline.subtitle = "\(track.name)|\(track.distance)"
                mapView.addOverlay(polyline, level: .aboveRoads)
                
                // Add label annotation for track name at the middle point
                if track.route.count > 1 {
                    let midIndex = track.route.count / 2
                    let labelAnnotation = TrackLabelAnnotation(
                        coordinate: track.route[midIndex],
                        title: track.name,
                        distance: track.distance
                    )
                    mapView.addAnnotation(labelAnnotation)
                }
                
                print("Added track overlay: \(track.name)")
            }
        }
        
        // Add current running path on top
        if runningPath.count > 1 {
            let polyline = MKPolyline(coordinates: runningPath, count: runningPath.count)
            polyline.title = "running"
            mapView.addOverlay(polyline, level: .aboveRoads)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func isRegionEqual(_ region1: MKCoordinateRegion, _ region2: MKCoordinateRegion) -> Bool {
        let threshold = 0.001
        return abs(region1.center.latitude - region2.center.latitude) < threshold &&
               abs(region1.center.longitude - region2.center.longitude) < threshold &&
               abs(region1.span.latitudeDelta - region2.span.latitudeDelta) < threshold &&
               abs(region1.span.longitudeDelta - region2.span.longitudeDelta) < threshold
    }
    
    private func isSpanEqual(_ span1: MKCoordinateSpan, _ span2: MKCoordinateSpan) -> Bool {
        let threshold = 0.00001
        return abs(span1.latitudeDelta - span2.latitudeDelta) < threshold &&
               abs(span1.longitudeDelta - span2.longitudeDelta) < threshold
    }
    
    private func getAltitudeForSpan(_ span: MKCoordinateSpan, at coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        // Calculate altitude to match the desired span
        // Approximate altitude for 0.005 degree span (about 500m)
        return 1000 // Fixed altitude for consistent zoom level
    }
    
    public class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RunningMapView
        var isUserDragging = false
        var lastHeading: CLLocationDirection = 0
        var lastUpdateTime: Date = Date()
        
        init(_ parent: RunningMapView) {
            self.parent = parent
        }
        
        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            
            let renderer = MKPolylineRenderer(polyline: polyline)
            
            if polyline.title == "running" {
                // Current running path - bright and solid
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4
                renderer.lineCap = .round
            } else if polyline.title?.starts(with: "track-") == true {
                // Saved tracks - more visible colors
                let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
                if isDarkMode {
                    renderer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.7)
                } else {
                    renderer.strokeColor = UIColor.systemPurple.withAlphaComponent(0.6)
                }
                renderer.lineWidth = 3
                renderer.lineDashPattern = [8, 4]
            }
            
            return renderer
        }
        
        public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Check if the change is due to user dragging
            if mapView.isUserInteractionEnabled {
                let gestureRecognizers = mapView.gestureRecognizers ?? []
                for recognizer in gestureRecognizers {
                    if recognizer.state == .began || recognizer.state == .changed {
                        isUserDragging = true
                        break
                    }
                }
            }
        }
        
        public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
            // Reset dragging flag after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isUserDragging = false
            }
        }
        
        public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let userAnnotation = annotation as? UserLocationAnnotation {
                let identifier = "UserLocation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? UserLocationView
                
                if annotationView == nil {
                    annotationView = UserLocationView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                
                annotationView?.updateHeading(userAnnotation.heading)
                
                return annotationView
            } else if let labelAnnotation = annotation as? TrackLabelAnnotation {
                let identifier = "TrackLabel"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? TrackLabelView
                
                if annotationView == nil {
                    annotationView = TrackLabelView(annotation: annotation, reuseIdentifier: identifier)
                } else {
                    annotationView?.annotation = annotation
                }
                
                annotationView?.configure(with: labelAnnotation.title ?? "", distance: labelAnnotation.distance)
                
                return annotationView
            }
            
            return nil
        }
    }
}

// Custom annotation for user location
class UserLocationAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var heading: CLLocationDirection?
    
    init(coordinate: CLLocationCoordinate2D, heading: CLLocationDirection?) {
        self.coordinate = coordinate
        self.heading = heading
        super.init()
    }
}

// Custom annotation view for user location
class UserLocationView: MKAnnotationView {
    private let locationView = UIView()
    private let triangleLayer = CAShapeLayer()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        canShowCallout = false
        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerOffset = CGPoint(x: 0, y: 0)
        
        // Location circle (bigger)
        locationView.frame = CGRect(x: 20, y: 20, width: 20, height: 20)
        locationView.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0) : // Soft blue
                UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)   // Darker blue
        }
        locationView.layer.cornerRadius = 10
        locationView.layer.borderWidth = 2
        locationView.layer.borderColor = UIColor.white.cgColor
        
        // Triangle shape for heading
        let trianglePath = UIBezierPath()
        trianglePath.move(to: CGPoint(x: 30, y: 10))  // Top point
        trianglePath.addLine(to: CGPoint(x: 22, y: 24))  // Bottom left
        trianglePath.addLine(to: CGPoint(x: 38, y: 24))  // Bottom right
        trianglePath.close()
        
        triangleLayer.path = trianglePath.cgPath
        triangleLayer.fillColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0) : // Soft blue
                UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)   // Darker blue
        }.cgColor
        triangleLayer.strokeColor = UIColor.white.cgColor
        triangleLayer.lineWidth = 2
        
        layer.addSublayer(triangleLayer)
        addSubview(locationView)
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.4
    }
    
    func updateHeading(_ heading: CLLocationDirection?) {
        // Since the map rotates, we keep the user icon always pointing up
        // Keep the user location view always pointing up (no rotation)
        UIView.animate(withDuration: 0.3) {
            self.transform = CGAffineTransform.identity
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Update colors when theme changes
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            locationView.backgroundColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                    UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0) : // Soft blue
                    UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)   // Darker blue
            }
            
            triangleLayer.fillColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                    UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0) : // Soft blue
                    UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)   // Darker blue
            }.cgColor
        }
    }
}

// Custom annotation for track labels
class TrackLabelAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let distance: Double
    
    init(coordinate: CLLocationCoordinate2D, title: String, distance: Double) {
        self.coordinate = coordinate
        self.title = title
        self.distance = distance
        super.init()
    }
}

// Custom annotation view for track labels
class TrackLabelView: MKAnnotationView {
    private let label = UILabel()
    private let containerView = UIView()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        canShowCallout = false
        
        // Configure container
        containerView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        containerView.layer.cornerRadius = 4
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemOrange.cgColor
        
        // Configure label
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        
        // Add label to container
        containerView.addSubview(label)
        addSubview(containerView)
        
        // Layout
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -2),
            
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(with name: String, distance: Double) {
        label.text = "\(name) • \(String(format: "%.1fkm", distance / 1000))"
        
        // Update frame based on text
        label.sizeToFit()
        let width = label.frame.width + 12
        let height = label.frame.height + 4
        containerView.frame = CGRect(x: -width/2, y: -height/2, width: width, height: height)
        frame = containerView.frame
    }
}


