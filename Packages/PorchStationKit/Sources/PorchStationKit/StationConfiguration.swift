//
//  StationConfiguration.swift
//  PorchStationKit
//
//  User-provided configuration needed to connect to a station.
//

import Foundation

/// Configuration values an adapter needs to connect to a station.
/// Each adapter uses the fields relevant to its connection type.
public struct StationConfiguration: Sendable, Codable {

    // MARK: - Local Connection

    /// IP address or hostname for local connections
    public var host: String?
    /// Port number for local connections (default varies by adapter)
    public var port: Int?

    // MARK: - Cloud Connection

    /// API key for cloud services
    public var apiKey: String?
    /// Application key / client ID for cloud services
    public var applicationKey: String?
    /// OAuth token or device token for some cloud APIs
    public var accessToken: String?

    // MARK: - Station Identity

    /// MAC address or device ID (some APIs require this to select a station)
    public var deviceID: String?

    // MARK: - Location (for stations that don't report their own)

    /// Manual latitude override
    public var latitude: Double?
    /// Manual longitude override
    public var longitude: Double?

    /// Human-readable name the user gives this station
    public var stationName: String?

    public init(
        host: String? = nil,
        port: Int? = nil,
        apiKey: String? = nil,
        applicationKey: String? = nil,
        accessToken: String? = nil,
        deviceID: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        stationName: String? = nil
    ) {
        self.host = host
        self.port = port
        self.apiKey = apiKey
        self.applicationKey = applicationKey
        self.accessToken = accessToken
        self.deviceID = deviceID
        self.latitude = latitude
        self.longitude = longitude
        self.stationName = stationName
    }
}
