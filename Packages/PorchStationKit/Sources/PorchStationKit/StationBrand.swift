//
//  StationBrand.swift
//  PorchStationKit
//
//  Enumerates supported weather station brands and their metadata.
//

import Foundation

/// A weather station manufacturer/brand
public enum StationBrand: String, CaseIterable, Codable, Sendable, Identifiable {
    case ecowitt
    case ambient
    case davis
    case tempest
    case acurite
    case lacrosse
    case sainlogic

    public var id: String { rawValue }

    /// Human-readable brand name
    public var displayName: String {
        switch self {
        case .ecowitt: return "Ecowitt"
        case .ambient: return "Ambient Weather"
        case .davis: return "Davis Instruments"
        case .tempest: return "WeatherFlow Tempest"
        case .acurite: return "AcuRite"
        case .lacrosse: return "La Crosse Technology"
        case .sainlogic: return "Sainlogic"
        }
    }

    /// How the station communicates with the app
    public var supportedConnectionTypes: [ConnectionType] {
        switch self {
        case .ecowitt:   return [.local, .cloud]
        case .ambient:   return [.cloud]
        case .davis:     return [.local, .cloud]
        case .tempest:   return [.local, .cloud]
        case .acurite:   return [.cloud]
        case .lacrosse:  return [.cloud]
        case .sainlogic:  return [.local]  // Ecowitt-compatible firmware
        }
    }
}

/// How the adapter connects to the station hardware
public enum ConnectionType: String, Codable, Sendable {
    case local   // LAN: HTTP polling, UDP broadcast, etc.
    case cloud   // Internet: REST API, WebSocket, etc.
}
