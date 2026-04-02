//
//  PorchWeatherData+Sensors.swift
//  PorchStationKit
//
//  Provides a dictionary-based sensor key/value system for dynamic UI rendering.
//  Replaces the Mirror-reflection approach used with AmbientLastData.
//

import Foundation

// MARK: - Sensor Key Definitions

/// Metadata for a single sensor key
public struct SensorKeyInfo: Sendable {
    public let key: String
    public let description: String
    public let category: SensorCategory
    public let unit: SensorUnit

    public init(key: String, description: String, category: SensorCategory, unit: SensorUnit) {
        self.key = key
        self.description = description
        self.category = category
        self.unit = unit
    }
}

/// Physical unit type for formatting and conversion
public enum SensorUnit: Sendable {
    case temperatureF
    case percent
    case degrees       // wind direction degrees
    case speedMPH
    case pressureInHg
    case rainInches
    case solarWm2
    case uvIndex
    case distanceMiles
    case timestampMs
    case ppm
    case microgramsM3
    case count
    case boolean       // leak, relay
    case batteryStatus
    case string
    case none
}

// MARK: - Sensor Registry

extension PorchWeatherData {

    /// All known sensor keys and their metadata
    public static let sensorKeyRegistry: [String: SensorKeyInfo] = {
        var reg: [String: SensorKeyInfo] = [:]
        func add(_ key: String, _ desc: String, _ cat: SensorCategory, _ unit: SensorUnit) {
            reg[key] = SensorKeyInfo(key: key, description: desc, category: cat, unit: unit)
        }

        // Temperature
        add("temperatureF", "Outdoor Temp (\u{00B0}F)", .temperature, .temperatureF)
        add("feelsLikeF", "Feels Like (\u{00B0}F)", .temperature, .temperatureF)
        add("dewPointF", "Dew Point (\u{00B0}F)", .temperature, .temperatureF)

        // Humidity
        add("humidity", "Humidity (%)", .humidity, .percent)

        // Wind
        add("windSpeedMPH", "Wind Speed (mph)", .wind, .speedMPH)
        add("windGustMPH", "Wind Gust (mph)", .wind, .speedMPH)
        add("windDirection", "Wind Direction", .wind, .degrees)
        add("maxDailyGustMPH", "Max Daily Gust (mph)", .wind, .speedMPH)

        // Pressure
        add("pressureRelativeInHg", "Relative Pressure (inHg)", .pressure, .pressureInHg)
        add("pressureAbsoluteInHg", "Absolute Pressure (inHg)", .pressure, .pressureInHg)

        // Rain
        add("rainRateInPerHr", "Rain Rate (in/hr)", .rain, .rainInches)
        add("eventRainIn", "Event Rain (in)", .rain, .rainInches)
        add("dailyRainIn", "Daily Rain (in)", .rain, .rainInches)
        add("weeklyRainIn", "Weekly Rain (in)", .rain, .rainInches)
        add("monthlyRainIn", "Monthly Rain (in)", .rain, .rainInches)
        add("yearlyRainIn", "Yearly Rain (in)", .rain, .rainInches)

        // Solar & UV
        add("solarRadiation", "Solar Radiation (W/m\u{00B2})", .solar, .solarWm2)
        add("uvIndex", "UV Index", .solar, .uvIndex)

        // Lightning
        add("lightningDistanceMi", "Lightning Distance (mi)", .lightning, .distanceMiles)
        add("lightningDayCount", "Lightning Strikes Today", .lightning, .count)

        // Air Quality
        add("pm25", "PM2.5 (\u{03BC}g/m\u{00B3})", .airQuality, .microgramsM3)
        add("co2", "CO\u{2082} (ppm)", .airQuality, .ppm)

        // Indoor
        add("indoorTempF", "Indoor Temp (\u{00B0}F)", .indoor, .temperatureF)
        add("indoorHumidity", "Indoor Humidity (%)", .indoor, .percent)

        // Soil (channels 1-10)
        for ch in 1...10 {
            add("soilTempF_\(ch)", "Soil Temp \(ch) (\u{00B0}F)", .soilTemperature, .temperatureF)
            add("soilMoisture_\(ch)", "Soil Moisture \(ch) (%)", .soilMoisture, .percent)
        }

        // Leak (channels 1-4)
        for ch in 1...4 {
            add("leak_\(ch)", "Leak Sensor \(ch)", .leak, .boolean)
        }

        // Battery sensors
        add("outdoor", "Outdoor Sensor Battery", .battery, .batteryStatus)
        add("indoor", "Indoor Sensor Battery", .battery, .batteryStatus)
        add("rain", "Rain Sensor Battery", .battery, .batteryStatus)
        add("lightning", "Lightning Sensor Battery", .battery, .batteryStatus)
        add("co2", "CO\u{2082}/PM2.5 Sensor Battery", .battery, .batteryStatus)
        add("cellgateway", "Cell Gateway Battery", .battery, .batteryStatus)
        for ch in 1...8 {
            add("ch\(ch)", "Channel \(ch) Sensor Battery", .battery, .batteryStatus)
        }
        for ch in 1...8 {
            add("soil\(ch)", "Soil Sensor \(ch) Battery", .battery, .batteryStatus)
        }
        for ch in 1...4 {
            add("leak\(ch)", "Leak Sensor \(ch) Battery", .battery, .batteryStatus)
        }

        return reg
    }()

    /// Category for a sensor key
    public static func category(for key: String) -> SensorCategory {
        sensorKeyRegistry[key]?.category ?? .unknown
    }

    /// Human-readable description for a sensor key
    public static func sensorDescription(for key: String) -> String {
        sensorKeyRegistry[key]?.description ?? key
    }
}

// MARK: - Dynamic Sensor Value Access

extension PorchWeatherData {

    /// Returns all sensor keys that have non-nil values in this observation
    public var availableSensorKeys: [String] {
        sensorValues.keys.sorted()
    }

    /// All current sensor values as a dictionary [key: value]
    public var sensorValues: [String: Any] {
        var dict: [String: Any] = [:]

        if let v = temperatureF { dict["temperatureF"] = v }
        if let v = humidity { dict["humidity"] = v }
        if let v = dewPointF { dict["dewPointF"] = v }
        if let v = feelsLikeF { dict["feelsLikeF"] = v }

        if let v = indoorTempF { dict["indoorTempF"] = v }
        if let v = indoorHumidity { dict["indoorHumidity"] = v }

        if let v = windSpeedMPH { dict["windSpeedMPH"] = v }
        if let v = windGustMPH { dict["windGustMPH"] = v }
        if let v = windDirection { dict["windDirection"] = v }
        if let v = maxDailyGustMPH { dict["maxDailyGustMPH"] = v }

        if let v = pressureRelativeInHg { dict["pressureRelativeInHg"] = v }
        if let v = pressureAbsoluteInHg { dict["pressureAbsoluteInHg"] = v }

        if let v = rainRateInPerHr { dict["rainRateInPerHr"] = v }
        if let v = eventRainIn { dict["eventRainIn"] = v }
        if let v = dailyRainIn { dict["dailyRainIn"] = v }
        if let v = weeklyRainIn { dict["weeklyRainIn"] = v }
        if let v = monthlyRainIn { dict["monthlyRainIn"] = v }
        if let v = yearlyRainIn { dict["yearlyRainIn"] = v }

        if let v = solarRadiation { dict["solarRadiation"] = v }
        if let v = uvIndex { dict["uvIndex"] = v }

        if let v = lightningDistanceMi { dict["lightningDistanceMi"] = v }
        if let v = lightningDayCount { dict["lightningDayCount"] = v }

        if let v = pm25 { dict["pm25"] = v }
        if let v = co2 { dict["co2"] = v }

        for (ch, temp) in soilTempF {
            dict["soilTempF_\(ch)"] = temp
        }
        for (ch, moisture) in soilMoisture {
            dict["soilMoisture_\(ch)"] = moisture
        }
        for (ch, leaked) in leakDetected {
            dict["leak_\(ch)"] = leaked
        }

        return dict
    }

    /// Numeric value for a sensor key (for charts, comparisons, etc.)
    public func numericValue(for key: String) -> Double? {
        guard let value = sensorValues[key] else { return nil }
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let b = value as? Bool { return b ? 1.0 : 0.0 }
        return nil
    }

    /// Sensors grouped by category, sorted by category order, with only non-nil sensors
    public var availableSensorsByCategory: [(SensorCategory, [String])] {
        let values = sensorValues
        var grouped: [SensorCategory: [String]] = [:]

        for key in values.keys {
            let category = Self.category(for: key)
            grouped[category, default: []].append(key)
        }

        return grouped
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted()) }
    }

    /// Formatted observation date string
    public var observationDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: timestamp)
    }
}
