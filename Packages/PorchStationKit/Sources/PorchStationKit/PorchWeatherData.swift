//
//  PorchWeatherData.swift
//  PorchStationKit
//
//  The canonical weather observation model. All station adapters produce this type.
//  Values are stored in imperial units (matching the dominant US consumer station ecosystem).
//  Unit conversion to metric is handled at the display layer.
//

import Foundation

/// A single weather observation from any supported station
public struct PorchWeatherData: Sendable {

    // MARK: - Identity

    /// Unique station identifier (MAC address, serial number, etc.)
    public var stationID: String
    /// Human-readable station name
    public var stationName: String
    /// Which brand produced this data
    public var brand: StationBrand
    /// When this observation was captured
    public var timestamp: Date
    /// Station location, if known
    public var location: StationLocation?

    // MARK: - Outdoor Temperature & Derived

    /// Outdoor temperature in Fahrenheit
    public var temperatureF: Double?
    /// Outdoor humidity as a percentage (0–100)
    public var humidity: Int?
    /// Dew point in Fahrenheit
    public var dewPointF: Double?
    /// Feels-like temperature in Fahrenheit (wind chill or heat index)
    public var feelsLikeF: Double?

    // MARK: - Indoor

    /// Indoor temperature in Fahrenheit
    public var indoorTempF: Double?
    /// Indoor humidity as a percentage (0–100)
    public var indoorHumidity: Int?

    // MARK: - Wind

    /// Current wind speed in mph
    public var windSpeedMPH: Double?
    /// Current wind gust in mph
    public var windGustMPH: Double?
    /// Wind direction in degrees (0–360, 0 = North)
    public var windDirection: Int?
    /// Maximum daily gust in mph
    public var maxDailyGustMPH: Double?

    // MARK: - Pressure

    /// Relative (sea-level adjusted) barometric pressure in inHg
    public var pressureRelativeInHg: Double?
    /// Absolute barometric pressure in inHg
    public var pressureAbsoluteInHg: Double?

    // MARK: - Rain

    /// Current rain rate in inches/hour
    public var rainRateInPerHr: Double?
    /// Event rain total in inches
    public var eventRainIn: Double?
    /// Daily rain total in inches
    public var dailyRainIn: Double?
    /// Weekly rain total in inches
    public var weeklyRainIn: Double?
    /// Monthly rain total in inches
    public var monthlyRainIn: Double?
    /// Yearly rain total in inches
    public var yearlyRainIn: Double?

    // MARK: - Solar & UV

    /// Solar radiation in W/m²
    public var solarRadiation: Double?
    /// UV index (integer)
    public var uvIndex: Int?

    // MARK: - Lightning

    /// Distance to last lightning strike in miles
    public var lightningDistanceMi: Double?
    /// Timestamp of last lightning strike
    public var lightningTime: Date?
    /// Number of lightning strikes today
    public var lightningDayCount: Int?

    // MARK: - Air Quality

    /// PM2.5 concentration in µg/m³
    public var pm25: Double?
    /// CO₂ concentration in ppm
    public var co2: Int?

    // MARK: - Soil Sensors (keyed by channel 1–10)

    /// Soil temperature per channel in Fahrenheit
    public var soilTempF: [Int: Double]
    /// Soil moisture per channel (percentage)
    public var soilMoisture: [Int: Int]

    // MARK: - Leak Sensors (keyed by channel 1–4)

    /// Leak detection status per channel (true = leak detected)
    public var leakDetected: [Int: Bool]

    // MARK: - Battery Status

    /// Battery status per sensor name
    public var batteries: [String: BatteryStatus]

    // MARK: - Init

    public init(
        stationID: String,
        stationName: String,
        brand: StationBrand,
        timestamp: Date = Date(),
        location: StationLocation? = nil
    ) {
        self.stationID = stationID
        self.stationName = stationName
        self.brand = brand
        self.timestamp = timestamp
        self.location = location
        self.soilTempF = [:]
        self.soilMoisture = [:]
        self.leakDetected = [:]
        self.batteries = [:]
    }
}

// MARK: - Supporting Types

/// Geographic location of a station
public struct StationLocation: Sendable, Codable, Hashable {
    public var latitude: Double
    public var longitude: Double
    public var displayName: String?

    public init(latitude: Double, longitude: Double, displayName: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.displayName = displayName
    }
}

/// Battery health for a sensor
public enum BatteryStatus: Sendable, Codable, Hashable {
    /// Battery level is normal/OK
    case ok
    /// Battery is low and needs replacement
    case low
    /// Numeric battery level (0.0–1.0 normalized, or raw voltage)
    case level(Double)

    /// Whether the battery needs attention
    public var isLow: Bool {
        switch self {
        case .ok: return false
        case .low: return true
        case .level(let v): return v < 0.2
        }
    }
}
