//
//  StationModel.swift
//  PorchStationKit
//
//  Describes a specific weather station model within a brand.
//

import Foundation

/// A specific station model (e.g., Davis Vantage Pro2, Ecowitt GW2000)
public struct StationModel: Identifiable, Codable, Sendable, Hashable {
    /// Unique identifier, e.g. "ecowitt-gw2000", "davis-vp2"
    public let id: String
    /// The brand this model belongs to
    public let brand: StationBrand
    /// Human-readable model name
    public let name: String
    /// How this model can connect
    public let connectionTypes: [ConnectionType]
    /// Which sensor categories this model supports out of the box
    public let capabilities: StationCapabilities

    public init(
        id: String,
        brand: StationBrand,
        name: String,
        connectionTypes: [ConnectionType],
        capabilities: StationCapabilities
    ) {
        self.id = id
        self.brand = brand
        self.name = name
        self.connectionTypes = connectionTypes
        self.capabilities = capabilities
    }
}

/// Declares what sensor categories a station model supports
public struct StationCapabilities: Codable, Sendable, Hashable {
    public var hasOutdoorTemp: Bool
    public var hasIndoorTemp: Bool
    public var hasWind: Bool
    public var hasPressure: Bool
    public var hasRain: Bool
    public var hasSolar: Bool
    public var hasUV: Bool
    public var hasLightning: Bool
    public var hasAirQuality: Bool
    public var hasSoilSensors: Bool
    public var hasLeakSensors: Bool
    public var maxSoilChannels: Int
    public var maxLeakChannels: Int

    public init(
        hasOutdoorTemp: Bool = true,
        hasIndoorTemp: Bool = false,
        hasWind: Bool = false,
        hasPressure: Bool = false,
        hasRain: Bool = false,
        hasSolar: Bool = false,
        hasUV: Bool = false,
        hasLightning: Bool = false,
        hasAirQuality: Bool = false,
        hasSoilSensors: Bool = false,
        hasLeakSensors: Bool = false,
        maxSoilChannels: Int = 0,
        maxLeakChannels: Int = 0
    ) {
        self.hasOutdoorTemp = hasOutdoorTemp
        self.hasIndoorTemp = hasIndoorTemp
        self.hasWind = hasWind
        self.hasPressure = hasPressure
        self.hasRain = hasRain
        self.hasSolar = hasSolar
        self.hasUV = hasUV
        self.hasLightning = hasLightning
        self.hasAirQuality = hasAirQuality
        self.hasSoilSensors = hasSoilSensors
        self.hasLeakSensors = hasLeakSensors
        self.maxSoilChannels = maxSoilChannels
        self.maxLeakChannels = maxLeakChannels
    }

    /// A full-featured station (Ecowitt GW2000 class)
    public static let fullSuite = StationCapabilities(
        hasOutdoorTemp: true, hasIndoorTemp: true, hasWind: true,
        hasPressure: true, hasRain: true, hasSolar: true, hasUV: true,
        hasLightning: true, hasAirQuality: true, hasSoilSensors: true,
        hasLeakSensors: true, maxSoilChannels: 8, maxLeakChannels: 4
    )

    /// A basic outdoor station (temp, humidity, wind, rain)
    public static let basic = StationCapabilities(
        hasOutdoorTemp: true, hasIndoorTemp: true, hasWind: true,
        hasPressure: true, hasRain: true
    )
}
