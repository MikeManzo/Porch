//
//  ConnectionStatus.swift
//  PorchStationKit
//
//  Connection lifecycle states for station adapters.
//

import Foundation

/// The connection state of a station adapter
public enum StationConnectionStatus: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    /// Connection failed with a reason
    case failed(String)
}
