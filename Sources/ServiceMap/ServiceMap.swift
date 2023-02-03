//
//  MapView.swift
//  AthenaSecurity
//
//  Created by Tshimega Belmont on 2022/11/21.
//


import SwiftUI
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import ComposableArchitecture
import Combine

@available(iOS 13.0, *)
public struct ServiceMapView: UIViewControllerRepresentable {
    var store: StoreOf<MapFeature>
    
    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }
    
    public func makeUIViewController(context: Context) -> MapViewController {
//        print("CONTEXT: \(context)")
        return MapViewController(store: store)
    }
    
    public func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        
    }
}

public class MapViewController: UIViewController, AnnotationInteractionDelegate {
    open var viewStore: ViewStoreOf<MapFeature>
    var cancellables: Set<AnyCancellable> = []
    
    
    public init(store: StoreOf<MapFeature>) {
        self.viewStore = ViewStore(store)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable) public required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    
    internal var locationManager: CLLocationManager?
    internal var cameraLocationConsumer: CameraLocationConsumer!
    
    // NavigationMapView Variables
    var navigationMapView: NavigationMapView!
    var routeOptions: NavigationRouteOptions?
    var routeResponse: RouteResponse?
    
    // Annotations
    var securityAnnotation: PointAnnotation?
    var userAnnotation: CircleAnnotation!
    
    var circleAnnotationManager: CircleAnnotationManager!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        navigationMapView = NavigationMapView(frame: view.bounds)
        navigationMapView.autoresizingMask = [.flexibleHeight]
        view.addSubview(navigationMapView)
        
//        let myResourceOptions = ResourceOptions(accessToken: "sk.eyJ1IjoidHNoaW1lZ2EiLCJhIjoiY2xham9qdXY0MDA5dzNxbXZvYnhweHp3eCJ9.AACTDu0VM5PEhfhpejujwA")
        
        cameraLocationConsumer = CameraLocationConsumer(mapView: navigationMapView.mapView, viewStore: self.viewStore)
        
        // Set the annotation manager's delegate
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoaded) { [weak self] _ in
            guard let self = self else { return }
            self.navigationMapView.pointAnnotationManager?.delegate = self
            self.navigationMapView.mapView.location.addLocationConsumer(newConsumer: self.cameraLocationConsumer)
            
        }
        
        // Configure how map displays the user's location
        navigationMapView.userLocationStyle = .puck2D()
        // Switch viewport datasource to track `raw` location updates instead of `passive` mode.
        navigationMapView.navigationCamera.viewportDataSource = NavigationViewportDataSource(navigationMapView.mapView, viewportDataSourceType: .raw)
        
        // Create the `CircleAnnotationManager` which will be responsible for handling this annotation
        circleAnnotationManager = navigationMapView.mapView.annotations.makeCircleAnnotationManager()
        
        
        // Add a gesture recognizer to the map view
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        navigationMapView.addGestureRecognizer(longPress)
        
        self.viewStore.publisher.tappedCoordinate
            .sink { [weak self] tappedCoordinate in
                
                if let tappedCoordinate = tappedCoordinate {
                    
                    if let origin = self?.navigationMapView.mapView.location.latestLocation?.coordinate {
                        //self?.viewStore.send(.calculateRoute(origin: origin, destination: tappedCoordinate))
                        switch self?.viewStore.state.mapMode {
                            
                        case .citizen:
                            self?.viewStore.send(.updateCitizenLocation(tappedCoordinate))
                            
                        case .security:
                            self?.viewStore.send(.updateSecurityLocation(tappedCoordinate))
                        case .none:
                            return
                        }
                        
                    } else {
                        print("Failed to get user location, make sure to allow location access for this application.")
                    }
                }
            }
            .store(in: &self.cancellables)
        
        self.viewStore.publisher.route
            .sink { [weak self] route in
                
                if let route = route {
                    
                    self?.drawRoute(route: route)
                    if var annotation = self?.navigationMapView.pointAnnotationManager?.annotations.first {
                        // Display callout view on destination annotation
                        annotation.textField = "Start navigation"
                        annotation.textColor = .init(UIColor.white)
                        annotation.textHaloColor = .init(UIColor.systemBlue)
                        annotation.textHaloWidth = 2
                        annotation.textAnchor = .top
                        annotation.textRadialOffset = 1.0
                        
                        self?.navigationMapView.pointAnnotationManager?.annotations = [annotation]
                    }
                }
            }
            .store(in: &self.cancellables)
        
        switch viewStore.state.mapMode {
            
        case .citizen:
            self.viewStore.publisher.securityLocation
                .sink { [weak self] securityLocation in
                    
                    if let securityLocation = securityLocation {
                        (self?.userAnnotation == nil) ? self?.addAnnotation(coordinate: securityLocation) : self?.updateAnnotation(coordinate: securityLocation)
                    }
                    else {
                        self?.removeAnnotation()
                    }
                }
                .store(in: &self.cancellables)
            
        case .security:
            self.viewStore.publisher.citizenLocation
                .sink { [weak self] citizenLocation in
                    if let citizenLocation = citizenLocation {
                        (self?.userAnnotation == nil) ? self?.addAnnotation(coordinate: citizenLocation) : self?.updateAnnotation(coordinate: citizenLocation)
                    }
                    else {
                        self?.removeAnnotation()
                    }
                }
                .store(in: &self.cancellables)
        }
    }
    
    @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let location = navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: gesture.view))
        
        self.viewStore.send(
            .longPress(location)
        )
    }
    
    private func addAnnotation(coordinate: CLLocationCoordinate2D) {
        userAnnotation = CircleAnnotation(centerCoordinate: coordinate)
        userAnnotation.circleColor = StyleColor(.blue)
        circleAnnotationManager.annotations = [userAnnotation]
    }
    
    private func updateAnnotation(coordinate: CLLocationCoordinate2D) {
        userAnnotation.point = Point(coordinate)
        circleAnnotationManager.annotations = [userAnnotation]
    }
    
    private func removeAnnotation() {
        userAnnotation = nil
        circleAnnotationManager.annotations = []
    }
    
    private func drawRoute(route: Route) {
        navigationMapView.show([route])
        navigationMapView.showRouteDurations(along: [route])
        navigationMapView.showWaypoints(on: route)
    }
    
    
    // Present the navigation view controller when the annotation is selected
    public func annotationManager(_ manager: AnnotationManager, didDetectTappedAnnotations annotations: [Annotation]) {
        guard annotations.first?.id == securityAnnotation?.id,
              let routeResponse = routeResponse, let routeOptions = routeOptions else {
            return
        }
        let navigationViewController = NavigationViewController(for: routeResponse, routeIndex: 0, routeOptions: routeOptions)
        navigationViewController.modalPresentationStyle = .fullScreen
        self.present(navigationViewController, animated: true, completion: nil)
    }
}

public class CameraLocationConsumer: LocationConsumer {
    weak var mapView: MapView?
    weak var viewStore: ViewStoreOf<MapFeature>?
    
    init(mapView: MapView, viewStore: ViewStoreOf<MapFeature>) {
        self.mapView = mapView
        self.viewStore = viewStore
    }
    
    public func locationUpdate(newLocation: Location) {
        
        mapView?.camera.ease(to: CameraOptions(center: newLocation.coordinate, zoom: 15), duration: 1.3)
    
        
        switch viewStore?.state.mapMode {
            
        case .citizen:
            viewStore?.send(.updateCitizenLocation(newLocation.coordinate))
            
        case .security:
            viewStore?.send(.updateSecurityLocation(newLocation.coordinate))
            
        case .none:
            return
        }
    }
}


