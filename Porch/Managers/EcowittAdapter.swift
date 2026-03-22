//
//  EcowittAdapter.swift
//  Porch
//
//  Maps EcowittLiveData → AmbientLastData via JSON round-trip.
//  AmbientLastData uses immutable `let` properties and Codable,
//  so we build a dictionary matching its CodingKeys and decode.
//

import Foundation
import AmbientWeather
import EcowittLocal

struct EcowittAdapter {

    /// Convert Ecowitt live data to an AmbientLastData observation.
    /// Returns nil if the JSON round-trip fails.
    static func toAmbientLastData(from ecowitt: EcowittLiveData) -> AmbientLastData? {
        var dict: [String: Any] = [:]

        // Metadata
        dict["dateutc"] = Int64(ecowitt.timestamp.timeIntervalSince1970 * 1000)
        dict["date"] = ISO8601DateFormatter().string(from: ecowitt.timestamp)
        dict["deviceId"] = "ecowitt-local"

        // Outdoor temperature & derived
        if let v = ecowitt.outdoorTemp { dict["tempf"] = v }
        if let v = ecowitt.outdoorHumidity { dict["humidity"] = v }
        if let v = ecowitt.dewPoint { dict["dewPoint"] = v }
        if let v = ecowitt.feelsLike { dict["feelsLike"] = v }

        // Indoor (WH25)
        if let v = ecowitt.indoorTemp { dict["tempinf"] = v }
        if let v = ecowitt.indoorHumidity { dict["humidityin"] = v }
        if let v = ecowitt.pressureRelative { dict["baromrelin"] = v }
        if let v = ecowitt.pressureAbsolute { dict["baromabsin"] = v }

        // Wind
        if let v = ecowitt.windSpeed { dict["windspeedmph"] = v }
        if let v = ecowitt.windGust { dict["windgustmph"] = v }
        if let v = ecowitt.windDir { dict["winddir"] = v }
        if let v = ecowitt.maxDailyGust { dict["maxdailygust"] = v }

        // Rain
        if let v = ecowitt.rainEvent { dict["eventrainin"] = v }
        if let v = ecowitt.rainRate { dict["hourlyrainin"] = v }
        if let v = ecowitt.dailyRain { dict["dailyrainin"] = v }
        if let v = ecowitt.weeklyRain { dict["weeklyrainin"] = v }
        if let v = ecowitt.monthlyRain { dict["monthlyrainin"] = v }
        if let v = ecowitt.yearlyRain { dict["yearlyrainin"] = v }

        // Solar & UV
        if let v = ecowitt.solarRadiation { dict["solarradiation"] = v }
        if let v = ecowitt.uvIndex { dict["uv"] = v }

        // Lightning
        if let v = ecowitt.lightningDistance { dict["lightning_distance"] = v }
        if let v = ecowitt.lightningTime { dict["lightning_time"] = v }
        if let v = ecowitt.lightningDayCount { dict["lightning_day"] = v }

        // Air quality
        if let v = ecowitt.co2 { dict["co2"] = v }
        if let v = ecowitt.pm25 { dict["pm25"] = v }

        // Soil temperature (channels 1-10 → soiltemp1f...soiltemp10f)
        for (ch, temp) in ecowitt.soilTemp {
            if ch >= 1 && ch <= 10 {
                dict["soiltemp\(ch)f"] = temp
            }
        }

        // Soil moisture (channels 1-10 → soilhum1...soilhum10)
        for (ch, humidity) in ecowitt.soilMoisture {
            if ch >= 1 && ch <= 10 {
                dict["soilhum\(ch)"] = humidity
            }
        }

        // Leak sensors (channels 1-4 → leak1...leak4)
        for (ch, status) in ecowitt.leakSensors {
            if ch >= 1 && ch <= 4 {
                dict["leak\(ch)"] = status
            }
        }

        // Battery mappings
        if let v = ecowitt.batteries["rain"] { dict["battrain"] = "\(v)" }
        if let v = ecowitt.batteries["lightning"] { dict["batt_lightning"] = v }
        if let v = ecowitt.batteries["co2"] { dict["batt_co2"] = v }
        for ch in 1...4 {
            if let v = ecowitt.batteries["leak\(ch)"] { dict["batleak\(ch)"] = v }
            if let v = ecowitt.batteries["soil\(ch)"] { dict["battsm\(ch)"] = v }
        }

        // JSON round-trip to construct immutable AmbientLastData
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            return try JSONDecoder().decode(AmbientLastData.self, from: jsonData)
        } catch {
            print("[Porch] EcowittAdapter error: \(error.localizedDescription)")
            return nil
        }
    }
}
