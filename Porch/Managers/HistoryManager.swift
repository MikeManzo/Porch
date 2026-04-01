//
//  HistoryManager.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import Foundation
import SwiftData
import AmbientWeather
import PorchStationKit

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

        // Explicit save to flush the in-memory object graph and prevent unbounded growth
        try? modelContext.save()
    }

    /// Save a snapshot from PorchWeatherData (new adapter system)
    func saveSnapshot(from data: PorchWeatherData) {
        let now = Date()

        if let last = lastSaveTime, now.timeIntervalSince(last) < saveInterval {
            return
        }
        lastSaveTime = now

        let snapshot = WeatherSnapshot(timestamp: now, stationID: data.stationID)

        snapshot.temperature = data.temperatureF
        snapshot.humidity = data.humidity
        snapshot.feelsLike = data.feelsLikeF
        snapshot.dewPoint = data.dewPointF
        snapshot.windSpeed = data.windSpeedMPH
        snapshot.windGust = data.windGustMPH
        snapshot.windDirection = data.windDirection
        snapshot.pressure = data.pressureRelativeInHg
        snapshot.dailyRain = data.dailyRainIn
        snapshot.hourlyRain = data.rainRateInPerHr
        snapshot.solarRadiation = data.solarRadiation
        snapshot.uv = data.uvIndex
        snapshot.pm25 = data.pm25
        snapshot.co2 = data.co2
        snapshot.indoorTemp = data.indoorTempF
        snapshot.indoorHumidity = data.indoorHumidity

        modelContext.insert(snapshot)
        pruneOldData()
        try? modelContext.save()
    }

    // MARK: - Query Methods

    /// Fetch snapshots for a station within a date range, ordered by timestamp
    func fetchSnapshots(
        for stationID: String,
        from startDate: Date,
        to endDate: Date = Date()
    ) -> [WeatherSnapshot] {
        let predicate = #Predicate<WeatherSnapshot> { snapshot in
            snapshot.stationID == stationID &&
            snapshot.timestamp >= startDate &&
            snapshot.timestamp <= endDate
        }
        let descriptor = FetchDescriptor<WeatherSnapshot>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Convenience: fetch snapshots for the last N hours
    func fetchSnapshots(for stationID: String, lastHours hours: Int) -> [WeatherSnapshot] {
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        return fetchSnapshots(for: stationID, from: startDate)
    }

    /// Convenience: fetch snapshots for the last N days
    func fetchSnapshots(for stationID: String, lastDays days: Int) -> [WeatherSnapshot] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return fetchSnapshots(for: stationID, from: startDate)
    }

    // MARK: - Pruning

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
