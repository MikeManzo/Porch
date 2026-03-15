//
//  HistoryManager.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import Foundation
import SwiftData
import AmbientWeather

/// Manages historical weather data storage using SwiftData
@MainActor
class HistoryManager {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private var lastSaveTime: Date?

    /// Minimum interval between saves (60 seconds to match station reporting)
    private let saveInterval: TimeInterval = 60

    /// How many days of history to keep
    private let retentionDays: Int = 7

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }

    /// Save a snapshot of the current observation
    func saveSnapshot(from data: AmbientWeatherData) {
        let now = Date()

        // Throttle: skip if less than saveInterval since last save
        if let last = lastSaveTime, now.timeIntervalSince(last) < saveInterval {
            return
        }
        lastSaveTime = now

        let snapshot = WeatherSnapshot(timestamp: now, stationID: data.stationID)
        let obs = data.observation

        snapshot.temperature = obs.tempF
        snapshot.humidity = obs.humidity
        snapshot.feelsLike = obs.feelsLike
        snapshot.dewPoint = obs.dewPoint
        snapshot.windSpeed = obs.windSpeedMPH
        snapshot.windGust = obs.windGustMPH
        snapshot.windDirection = obs.windDir
        snapshot.pressure = obs.baromRelIn
        snapshot.dailyRain = obs.dailyRainIn
        snapshot.hourlyRain = obs.hourlyRainIn
        snapshot.solarRadiation = obs.solarRadiation
        snapshot.uv = obs.uv
        snapshot.pm25 = obs.pm25
        snapshot.co2 = obs.co2
        snapshot.indoorTemp = obs.tempInF
        snapshot.indoorHumidity = obs.humidityIn

        modelContext.insert(snapshot)

        // Prune old data periodically
        pruneOldData()
    }

    /// Remove snapshots older than the retention period
    private func pruneOldData() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let predicate = #Predicate<WeatherSnapshot> { snapshot in
            snapshot.timestamp < cutoff
        }
        do {
            try modelContext.delete(model: WeatherSnapshot.self, where: predicate)
        } catch {
            // Silently ignore prune failures
        }
    }
}
