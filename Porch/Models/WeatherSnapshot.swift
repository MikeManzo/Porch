//
//  WeatherSnapshot.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import Foundation
import SwiftData

/// A point-in-time snapshot of key weather sensor values for historical tracking
@Model
final class WeatherSnapshot {
    var timestamp: Date
    var stationID: String

    // Key sensor values
    var temperature: Double?
    var humidity: Int?
    var feelsLike: Double?
    var dewPoint: Double?
    var windSpeed: Double?
    var windGust: Double?
    var windDirection: Int?
    var pressure: Double?
    var dailyRain: Double?
    var hourlyRain: Double?
    var solarRadiation: Double?
    var uv: Int?
    var pm25: Double?
    var co2: Int?
    var indoorTemp: Double?
    var indoorHumidity: Int?

    init(timestamp: Date, stationID: String) {
        self.timestamp = timestamp
        self.stationID = stationID
    }
}

// MARK: - Double? Accessors for Chart KeyPaths

extension WeatherSnapshot {
    var humidityDouble: Double? { humidity.map(Double.init) }
    var uvDouble: Double? { uv.map(Double.init) }
    var co2Double: Double? { co2.map(Double.init) }
    var windDirectionDouble: Double? { windDirection.map(Double.init) }
    var indoorHumidityDouble: Double? { indoorHumidity.map(Double.init) }
}
