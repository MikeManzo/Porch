//
//  WeatherDataBridge.swift
//  Porch
//
//  Converts PorchWeatherData → AmbientWeatherData for backward compatibility.
//  This bridge allows the new adapter system to produce PorchWeatherData while
//  existing views continue consuming AmbientWeatherData. Views can be migrated
//  to PorchWeatherData incrementally.
//

import Foundation
import AmbientWeather
import PorchStationKit

struct WeatherDataBridge {

    /// Convert PorchWeatherData to AmbientWeatherData via JSON round-trip.
    /// This reuses the same approach as the original EcowittAdapter.
    static func toAmbientWeatherData(from porch: PorchWeatherData) -> AmbientWeatherData? {
        guard let observation = buildObservationDict(from: porch) else { return nil }

        let lat = porch.location?.latitude ?? 0
        let lon = porch.location?.longitude ?? 0

        let fullDict: [String: Any] = [
            "lastData": observation,
            "macAddress": porch.stationID,
            "apiKey": "local",
            "info": [
                "name": porch.stationName,
                "coords": [
                    "address": "",
                    "elevation": 0.0,
                    "geo": [
                        "type": "Point",
                        "coordinates": [lon, lat]
                    ],
                    "location": porch.location?.displayName ?? "\(lat), \(lon)",
                    "coords": [
                        "lat": lat,
                        "lon": lon
                    ]
                ] as [String: Any]
            ] as [String: Any]
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: fullDict)
            return try JSONDecoder().decode(AmbientWeatherData.self, from: jsonData)
        } catch {
            print("[Porch] WeatherDataBridge error: \(error)")
            return nil
        }
    }

    private static func buildObservationDict(from porch: PorchWeatherData) -> [String: Any]? {
        var dict: [String: Any] = [:]

        // Metadata
        dict["dateutc"] = Int64(porch.timestamp.timeIntervalSince1970 * 1000)
        dict["date"] = ISO8601DateFormatter().string(from: porch.timestamp)
        dict["deviceId"] = porch.stationID
        dict["tz"] = TimeZone.current.identifier

        // Outdoor
        if let v = porch.temperatureF { dict["tempf"] = v }
        if let v = porch.humidity { dict["humidity"] = v }
        if let v = porch.dewPointF { dict["dewPoint"] = v }
        if let v = porch.feelsLikeF { dict["feelsLike"] = v }

        // Indoor
        if let v = porch.indoorTempF { dict["tempinf"] = v }
        if let v = porch.indoorHumidity { dict["humidityin"] = v }

        // Pressure
        if let v = porch.pressureRelativeInHg { dict["baromrelin"] = v }
        if let v = porch.pressureAbsoluteInHg { dict["baromabsin"] = v }

        // Wind
        if let v = porch.windSpeedMPH { dict["windspeedmph"] = v }
        if let v = porch.windGustMPH { dict["windgustmph"] = v }
        if let v = porch.windDirection { dict["winddir"] = v }
        if let v = porch.maxDailyGustMPH { dict["maxdailygust"] = v }

        // Rain
        if let v = porch.eventRainIn { dict["eventrainin"] = v }
        if let v = porch.rainRateInPerHr { dict["hourlyrainin"] = v }
        if let v = porch.dailyRainIn { dict["dailyrainin"] = v }
        if let v = porch.weeklyRainIn { dict["weeklyrainin"] = v }
        if let v = porch.monthlyRainIn { dict["monthlyrainin"] = v }
        if let v = porch.yearlyRainIn { dict["yearlyrainin"] = v }

        // Solar & UV
        if let v = porch.solarRadiation { dict["solarradiation"] = v }
        if let v = porch.uvIndex { dict["uv"] = v }

        // Lightning
        if let v = porch.lightningDistanceMi { dict["lightning_distance"] = v }
        if let v = porch.lightningTime {
            dict["lightning_time"] = Int64(v.timeIntervalSince1970 * 1000)
        }
        if let v = porch.lightningDayCount { dict["lightning_day"] = v }

        // Air Quality
        if let v = porch.co2 { dict["co2"] = v }
        if let v = porch.pm25 { dict["pm25"] = v }

        // Soil
        for (ch, temp) in porch.soilTempF where ch >= 1 && ch <= 10 {
            dict["soiltemp\(ch)f"] = temp
        }
        for (ch, moisture) in porch.soilMoisture where ch >= 1 && ch <= 10 {
            dict["soilhum\(ch)"] = moisture
        }

        // Leak
        for (ch, leaked) in porch.leakDetected where ch >= 1 && ch <= 4 {
            dict["leak\(ch)"] = leaked ? 1 : 0
        }

        // Battery mappings
        if let status = porch.batteries["outdoor"] {
            dict["battout"] = status.isLow ? 0 : 1
        }
        if let status = porch.batteries["indoor"] {
            dict["battin"] = status.isLow ? 0 : 1
        }
        if let status = porch.batteries["rain"] {
            dict["battrain"] = status.isLow ? "0" : "1"
        }
        if let status = porch.batteries["lightning"] {
            dict["batt_lightning"] = status.isLow ? 1 : 0
        }
        if let status = porch.batteries["co2"] {
            dict["batt_co2"] = status.isLow ? 0 : 1
        }
        if let status = porch.batteries["cellgateway"] {
            dict["batt_cellgateway"] = status.isLow ? 0 : 1
        }
        for ch in 1...4 {
            if let status = porch.batteries["leak\(ch)"] {
                dict["batleak\(ch)"] = status.isLow ? 0 : 1
            }
            if let status = porch.batteries["soil\(ch)"] {
                dict["battsm\(ch)"] = status.isLow ? 0 : 1
            }
        }
        // Note: ch1-ch8 (multi-channel temp/humidity) batteries have no Ambient equivalent;
        // they are handled directly via PorchWeatherData.batteries in the Porch path.

        return dict
    }
}
