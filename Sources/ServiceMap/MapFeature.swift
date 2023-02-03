//
//  MapFeature.swift
//  AthenaSecurity
//
//  Created by Tshimega Belmont on 2022/11/22.
//

import Foundation
import SwiftUI
import MapboxMaps
import ComposableArchitecture
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

public struct MapFeature: ReducerProtocol {
    
    
    public init() {}
    
    public struct State: Equatable {
        
        public var mapStatus: MapStatus = .idle
        public var mapMode: MapMode
        public var route: Route?
        public var securityLocation: CLLocationCoordinate2D?
        public var citizenLocation: CLLocationCoordinate2D?
        public var tappedCoordinate: CLLocationCoordinate2D?
        
        public init(mapMode: MapMode) {
            self.mapMode = mapMode
        }
    }
    
    public enum MapStatus: Equatable {
        case idle
        case showingUser
        case showingDirections
        case trackingUser
    }
    
    public enum MapMode: Equatable {
        case citizen
        case security
    }
    
    public enum Action: Equatable {
        case getDirections
        case removeCitizen
        case calculateRoute(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D)
        case routeResponse(TaskResult<Route>)
        case longPress(CLLocationCoordinate2D)
        case updateSecurityLocation(CLLocationCoordinate2D)
        case updateCitizenLocation(CLLocationCoordinate2D)
    }
    
    @Dependency(\.navigation) private var navigation
    
    public var body: some ReducerProtocol<State, Action>{
        Reduce { state , action in
            switch action {
                
            case .getDirections:
                return .none
                
            case .removeCitizen:
                return .none
                
            case .calculateRoute(origin: let origin, destination: let destination):
                let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
                let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
                // The Destination will need to be fed in the location coordinate from the User Model that's communicating with the Security in the WebSocket Group
                let routeOptions = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
                
                return .task {
                    await .routeResponse(TaskResult { try await navigation.calculateRoute(routeOptions) })
                }
                
            case let .longPress(coordinate):
                state.tappedCoordinate = coordinate
                return .none
                
            case let .routeResponse(.success(result)):
                state.route = result
                return .none
                
            case let .routeResponse(.failure(error)):
                print(error)
                return .none
                
            case let .updateSecurityLocation(coordinate):
                state.securityLocation = coordinate
                return .none
                
            case let .updateCitizenLocation(coordinate):
                state.citizenLocation = coordinate
                return .none
            }
        }
    }
}

