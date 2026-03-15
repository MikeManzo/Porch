//
//  SensorFormatter.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import Foundation
import AmbientWeather

/// The unit system for displaying weather data
enum UnitSystem: String, CaseIterable, Identifiable {
    case imperial
    case metric

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .imperial: return "Imperial"
        case .metric: return "Metric"
        }
    }
}

/// Formats sensor values from AmbientLastData for display in the menubar and dashboard
struct SensorFormatter {

    // MARK: - Sensor Key Classification

    /// Keys whose raw imperial value is a temperature in Fahrenheit
    private static let temperatureKeys: Set<String> = [
        "tempF", "tempInF", "feelsLike", "feelsLikeIn", "dewPoint", "dewPointIn",
        "soiltemp1f", "soiltemp2f", "soiltemp3f", "soiltemp4f", "soiltemp5f",
        "soiltemp6f", "soiltemp7f", "soiltemp8f", "soiltemp9f", "soiltemp10f"
    ]

    /// Keys whose raw imperial value is wind speed in mph
    private static let windSpeedKeys: Set<String> = [
        "windSpeedMPH", "windGustMPH", "maxDailyGust"
    ]

    /// Keys whose raw imperial value is pressure in inHg
    private static let pressureKeys: Set<String> = [
        "baromAbsIn", "baromRelIn"
    ]

    /// Keys whose raw imperial value is rain in inches
    private static let rainKeys: Set<String> = [
        "eventRainIn", "dailyRainIn", "weeklyRainIn", "monthlyRainIn",
        "yearlyRainIn", "hourlyRainIn"
    ]

    /// Keys whose raw imperial value is distance in miles
    private static let distanceKeys: Set<String> = [
        "lightningDistance"
    ]

    // MARK: - Public API

    /// Produces a compact string for the menubar (e.g., "72.1°F" or "22.3°C")
    static func menuBarString(for sensorKey: String, from observation: AmbientLastData,
                              unitSystem: UnitSystem = .imperial) -> String {
        guard let value = mirrorValue(for: sensorKey, from: observation) else {
            return "--"
        }
        return formatValue(value, forSensor: sensorKey, unitSystem: unitSystem)
    }

    /// Full display string with label (e.g., "Outdoor Temp: 72.1°F")
    static func displayString(for sensorKey: String, from observation: AmbientLastData,
                              unitSystem: UnitSystem = .imperial) -> String {
        let label = sensorDescription(for: sensorKey, unitSystem: unitSystem)
        guard let value = mirrorValue(for: sensorKey, from: observation) else {
            return "\(label): --"
        }
        return "\(label): \(formatValue(value, forSensor: sensorKey, unitSystem: unitSystem))"
    }

    /// Raw numeric value for a sensor key, optionally converted to metric
    static func numericValue(for sensorKey: String, from observation: AmbientLastData,
                             unitSystem: UnitSystem = .imperial) -> Double? {
        guard let value = mirrorValue(for: sensorKey, from: observation) else { return nil }
        var raw: Double?
        if let d = value as? Double { raw = d }
        else if let i = value as? Int { raw = Double(i) }
        else if let i64 = value as? Int64 { raw = Double(i64) }

        guard let rawValue = raw else { return nil }

        if unitSystem == .metric, let converted = convertToMetric(rawValue, forSensor: sensorKey) {
            return converted
        }
        return rawValue
    }

    /// Returns a user-facing description for the sensor, with units appropriate to the selected system
    static func sensorDescription(for sensorKey: String, unitSystem: UnitSystem = .imperial) -> String {
        if unitSystem == .metric {
            return metricSensorDescriptions[sensorKey]
                ?? AmbientLastData.sensorDescriptions[sensorKey]
                ?? sensorKey
        }
        return AmbientLastData.sensorDescriptions[sensorKey] ?? sensorKey
    }

    // MARK: - Unit Conversion

    /// Convert a raw imperial Double value to its metric equivalent based on sensor key
    private static func convertToMetric(_ value: Double, forSensor key: String) -> Double? {
        if temperatureKeys.contains(key) {
            return (value - 32) * 5.0 / 9.0
        }
        if windSpeedKeys.contains(key) {
            return value * 1.60934
        }
        if pressureKeys.contains(key) {
            return value * 33.8639
        }
        if rainKeys.contains(key) {
            return value * 25.4
        }
        if distanceKeys.contains(key) {
            return value * 1.60934
        }
        return nil
    }

    // MARK: - Private Helpers

    /// Uses Mirror to extract the value of a named property from AmbientLastData
    private static func mirrorValue(for key: String, from observation: AmbientLastData) -> Any? {
        let mirror = Mirror(reflecting: observation)
        for child in mirror.children {
            if child.label == key {
                let childMirror = Mirror(reflecting: child.value)
                if childMirror.displayStyle == .optional {
                    return childMirror.children.first?.value
                }
                return child.value
            }
        }
        return nil
    }

    /// Format a raw sensor value with the appropriate unit suffix, applying conversion if metric
    private static func formatValue(_ value: Any, forSensor key: String,
                                    unitSystem: UnitSystem = .imperial) -> String {
        let suffix = unitSuffix(for: key, unitSystem: unitSystem)

        if let doubleVal = value as? Double {
            let displayVal: Double
            if unitSystem == .metric, let converted = convertToMetric(doubleVal, forSensor: key) {
                displayVal = converted
            } else {
                displayVal = doubleVal
            }

            // Metric-specific precision
            if unitSystem == .metric && pressureKeys.contains(key) {
                return String(format: "%.1f%@", displayVal, suffix)
            }
            if unitSystem == .metric && rainKeys.contains(key) {
                return String(format: "%.1f%@", displayVal, suffix)
            }

            let decimals = needsDecimal(key) ? 1 : 0
            return String(format: "%.\(decimals)f%@", displayVal, suffix)
        } else if let intVal = value as? Int {
            if unitSystem == .metric, let converted = convertToMetric(Double(intVal), forSensor: key) {
                let decimals = needsDecimal(key) ? 1 : 0
                return String(format: "%.\(decimals)f%@", converted, suffix)
            }
            return "\(intVal)\(suffix)"
        } else if let int64Val = value as? Int64 {
            return "\(int64Val)\(suffix)"
        }
        return "\(value)\(suffix)"
    }

    /// Determine unit suffix based on sensor key and unit system
    static func unitSuffix(for key: String, unitSystem: UnitSystem = .imperial) -> String {
        // For metric mode, check explicit key sets first
        if unitSystem == .metric {
            if temperatureKeys.contains(key) { return "\u{00B0}C" }
            if windSpeedKeys.contains(key) { return " km/h" }
            if pressureKeys.contains(key) { return " hPa" }
            if rainKeys.contains(key) { return " mm" }
            if distanceKeys.contains(key) { return " km" }
        }

        // Imperial mode or unit-agnostic sensors (humidity, UV, solar, battery, etc.)
        let lowered = key.lowercased()

        // Temperature
        if lowered.hasSuffix("f") && (lowered.contains("temp") || lowered.contains("feelslike") || lowered.contains("dewpoint")) {
            return "\u{00B0}F"
        }
        if lowered.hasSuffix("c") && (lowered.contains("temp") || lowered.contains("feelslike") || lowered.contains("dewpoint")) {
            return "\u{00B0}C"
        }
        if lowered.hasSuffix("k") && (lowered.contains("temp") || lowered.contains("feelslike") || lowered.contains("dewpoint")) {
            return " K"
        }

        // Humidity
        if lowered.contains("humidity") || lowered.hasPrefix("soilhum") {
            return "%"
        }

        // Wind
        if lowered.contains("mph") { return " mph" }
        if lowered.contains("kph") { return " kph" }
        if lowered.contains("knots") { return " kts" }
        if lowered.contains("winddir") { return "\u{00B0}" }

        // Pressure
        if lowered.contains("barom") {
            if lowered.contains("mb") { return " mb" }
            if lowered.contains("kpa") { return " kPa" }
            if lowered.contains("hpa") { return " hPa" }
            return " inHg"
        }

        // Rain
        if lowered.contains("rain") {
            if lowered.contains("cm") { return " cm" }
            if lowered.contains("mm") { return " mm" }
            if lowered.hasSuffix("in") { return " in" }
        }

        // Solar
        if lowered.contains("solarradiation") { return " W/m\u{00B2}" }
        if lowered == "uv" { return "" }

        // Lightning
        if lowered.contains("lightningdistance") {
            if lowered.contains("km") { return " km" }
            return " mi"
        }

        // CO2
        if lowered == "co2" { return " ppm" }

        // PM2.5
        if lowered.contains("pm25") { return " \u{03BC}g/m\u{00B3}" }

        return ""
    }

    private static func needsDecimal(_ key: String) -> Bool {
        let lowered = key.lowercased()
        return lowered.contains("temp") || lowered.contains("feelslike") ||
               lowered.contains("dewpoint") || lowered.contains("mph") ||
               lowered.contains("kph") || lowered.contains("rain") ||
               lowered.contains("barom") || lowered.contains("solarradiation") ||
               lowered.contains("gust") || lowered.contains("lightning_distance")
    }

    // MARK: - Metric Sensor Descriptions

    /// Metric-specific sensor descriptions (only entries that differ from imperial)
    private static let metricSensorDescriptions: [String: String] = [
        "tempF": "Outdoor Temp (\u{00B0}C)",
        "tempInF": "Indoor Temp (\u{00B0}C)",
        "feelsLike": "Outdoor Feels Like (\u{00B0}C)",
        "feelsLikeIn": "Indoor Feels Like (\u{00B0}C)",
        "dewPoint": "Dew Point (\u{00B0}C)",
        "dewPointIn": "Indoor Dew Point (\u{00B0}C)",
        "windSpeedMPH": "Wind Speed (km/h)",
        "windGustMPH": "Wind Gust (km/h)",
        "maxDailyGust": "Max Daily Gust (km/h)",
        "baromAbsIn": "Absolute Pressure (hPa)",
        "baromRelIn": "Relative Pressure (hPa)",
        "eventRainIn": "Event Rain (mm)",
        "dailyRainIn": "Daily Rain (mm)",
        "weeklyRainIn": "Weekly Rain (mm)",
        "monthlyRainIn": "Monthly Rain (mm)",
        "yearlyRainIn": "Yearly Rain (mm)",
        "hourlyRainIn": "Hourly Rain (mm)",
        "lightningDistance": "Lightning Distance (km)",
        "soiltemp1f": "Soil Temp 1 (\u{00B0}C)",
        "soiltemp2f": "Soil Temp 2 (\u{00B0}C)",
        "soiltemp3f": "Soil Temp 3 (\u{00B0}C)",
        "soiltemp4f": "Soil Temp 4 (\u{00B0}C)",
        "soiltemp5f": "Soil Temp 5 (\u{00B0}C)",
        "soiltemp6f": "Soil Temp 6 (\u{00B0}C)",
        "soiltemp7f": "Soil Temp 7 (\u{00B0}C)",
        "soiltemp8f": "Soil Temp 8 (\u{00B0}C)",
        "soiltemp9f": "Soil Temp 9 (\u{00B0}C)",
        "soiltemp10f": "Soil Temp 10 (\u{00B0}C)",
    ]
}
