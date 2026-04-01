//
//  WeatherHeroView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import PorchStationKit

/// Large hero display showing the primary temperature reading and feels-like
struct WeatherHeroView: View {
    let porchData: PorchWeatherData
    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var forecastManager: ForecastManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        VStack(spacing: 4) {
            // Weather condition icon (Open-Meteo if available, else station sensors)
            Image(systemName: currentConditionIcon)
                .font(.system(size: 32))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(currentConditionColor)

            // Primary temperature
            if let temp = porchData.temperatureF {
                let displayTemp = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
                Text("\(displayTemp, specifier: "%.1f")\u{00B0}")
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .contentTransition(.numericText())
            } else {
                Text("--\u{00B0}")
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Feels like + condition summary
            HStack(spacing: 12) {
                if let feelsLike = porchData.feelsLikeF {
                    let displayFL = isMetric ? (feelsLike - 32) * 5.0 / 9.0 : feelsLike
                    Label("Feels \(displayFL, specifier: "%.0f")\u{00B0}", systemImage: "person.and.background.dotted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let humidity = porchData.humidity {
                    Label("\(humidity)%", systemImage: "humidity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Observation time
            Text("Updated \(porchData.observationDateFormatted)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Weather Condition Logic

    /// Uses Open-Meteo current conditions if available, else falls back to station sensors
    private var currentConditionIcon: String {
        if let current = forecastManager.currentWeather {
            return current.icon
        }
        return sensorConditionIcon
    }

    private var currentConditionColor: Color {
        if let current = forecastManager.currentWeather {
            return current.iconColor
        }
        return sensorConditionColor
    }

    // MARK: - Station Sensor Fallbacks

    private var sensorConditionIcon: String {
        let hasRain = (porchData.rainRateInPerHr ?? 0) > 0
        let hasLightning = porchData.lightningDayCount.map { $0 > 0 } ?? false
        let highUV = (porchData.uvIndex ?? 0) >= 6
        let highWind = (porchData.windSpeedMPH ?? 0) >= 20

        if hasLightning && hasRain { return "cloud.bolt.rain.fill" }
        if hasLightning { return "cloud.bolt.fill" }
        if hasRain { return "cloud.rain.fill" }
        if highWind { return "wind" }
        if highUV { return "sun.max.fill" }
        if (porchData.solarRadiation ?? 0) > 0 { return "sun.max.fill" }
        return "cloud.sun.fill"
    }

    private var sensorConditionColor: Color {
        let hasRain = (porchData.rainRateInPerHr ?? 0) > 0
        let hasLightning = porchData.lightningDayCount.map { $0 > 0 } ?? false

        if hasLightning { return .yellow }
        if hasRain { return .cyan }
        return .orange
    }
}
