//  NavigationClient.swift
//  AthenaSecurity
//
//  Created by Dev Jacobson on 2022/11/27.
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

struct User {
    var username: String
    var accessToken: AccessToken
}

struct AccessToken {
    var accessToken: String
    var tokenType: String
}

struct NavigationClient {
    
    var calculateRoute: @Sendable (NavigationRouteOptions) async throws -> Route
}

extension NavigationClient {
    
    static let live = Self (
        calculateRoute: { routeOptions in
            return try await withCheckedThrowingContinuation { continuation in
                
                Directions.shared.calculate(routeOptions) { session, result in
                    switch result {
                        
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    case let .success(response):
                        guard let route = response.routes?.first else {
                            return
                        }
                        continuation.resume(returning: route)
                    }
                }
            }
        }
    )
}

private enum NavigationClientKey: DependencyKey {
    static var liveValue = NavigationClient.live
}

extension DependencyValues {
    var navigation: NavigationClient {
        get { self[NavigationClientKey.self] }
        set { self[NavigationClientKey.self] = newValue }
    }
}


