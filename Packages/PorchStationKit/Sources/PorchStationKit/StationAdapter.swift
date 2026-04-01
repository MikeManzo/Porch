//
//  StationAdapter.swift
//  PorchStationKit
//
//  The core protocol that all weather station adapters must conform to.
//  Each adapter translates vendor-specific data into PorchWeatherData.
//

import Foundation

/// A discovered station on the local network or cloud account
public struct DiscoveredStation: Identifiable, Sendable, Hashable {
    /// Unique identifier (IP address, MAC, serial, etc.)
    public let id: String
    /// Human-readable label (model name, hostname, etc.)
    public let name: String
    /// The brand of the discovered station
    public let brand: StationBrand
    /// Connection details (host/port for local, device ID for cloud)
    public let host: String?
    public let port: Int?
    public let deviceID: String?

    public init(
        id: String,
        name: String,
        brand: StationBrand,
        host: String? = nil,
        port: Int? = nil,
        deviceID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.host = host
        self.port = port
        self.deviceID = deviceID
    }
}

/// Describes what configuration fields an adapter needs from the user
public struct ConfigurationField: Sendable, Identifiable {
    public let id: String
    public let label: String
    public let placeholder: String
    public let isRequired: Bool
    public let isSecure: Bool  // For API keys, passwords

    public init(id: String, label: String, placeholder: String = "",
                isRequired: Bool = true, isSecure: Bool = false) {
        self.id = id
        self.label = label
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.isSecure = isSecure
    }
}

/// The core protocol for weather station adapters.
///
/// Each adapter handles one brand/protocol family (e.g., Ecowitt local HTTP,
/// Ambient Weather WebSocket, Davis WeatherLink). The adapter is responsible for:
/// - Describing what configuration it needs
/// - Optionally discovering stations on the network or in a cloud account
/// - Connecting to the station and streaming observations as `PorchWeatherData`
public protocol StationAdapter: AnyObject, Sendable {

    // MARK: - Identity

    /// The brand this adapter supports
    static var brand: StationBrand { get }

    /// The connection type this adapter uses
    static var connectionType: ConnectionType { get }

    /// Known station models this adapter can talk to
    static var supportedModels: [StationModel] { get }

    /// Configuration fields the adapter needs from the user
    static var configurationFields: [ConfigurationField] { get }

    // MARK: - Discovery (optional)

    /// Scan for stations (network scan for local, account listing for cloud).
    /// Returns an empty array if discovery is not supported.
    func discover() async -> [DiscoveredStation]

    // MARK: - Connection Lifecycle

    /// Connect to the station with the given configuration.
    func connect(configuration: StationConfiguration) async throws

    /// Disconnect from the station and clean up resources.
    func disconnect()

    /// Whether the adapter is currently connected
    var isConnected: Bool { get }

    // MARK: - Data Streams

    /// A stream of weather observations. Yields a new value each time the
    /// station reports updated data (polling interval varies by adapter).
    var observations: AsyncStream<PorchWeatherData> { get }

    /// A stream of connection status changes.
    var connectionStatusStream: AsyncStream<StationConnectionStatus> { get }
}

// MARK: - Default Implementations

extension StationAdapter {
    /// Default: no discovery support
    public func discover() async -> [DiscoveredStation] { [] }
}
