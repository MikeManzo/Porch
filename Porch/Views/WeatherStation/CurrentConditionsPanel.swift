//
//  CurrentConditionsPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather

/// Hero conditions panel showing temperature, weather icon, feels-like, and daily extremes
struct CurrentConditionsPanel: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        HStack(spacing: 20) {
            // Weather icon
            Image(systemName: weatherConditionIcon)
                .font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(weatherConditionColor)

            // Temperature
            VStack(alignment: .leading, spacing: 4) {
                if let temp = observation.tempF {
                    let displayTemp = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
                    Text("\(displayTemp, specifier: "%.1f")°")
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                } else {
                    Text("--°")
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }

                HStack(spacing: 16) {
                    if let feelsLike = observation.feelsLike {
                        let displayFL = isMetric ? (feelsLike - 32) * 5.0 / 9.0 : feelsLike
                        Label("Feels \(displayFL, specifier: "%.0f")°", systemImage: "person.and.background.dotted")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    if let humidity = observation.humidity {
                        Label("\(humidity)%", systemImage: "humidity")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }

            Spacer()

            // Daily extremes
            VStack(alignment: .trailing, spacing: 8) {
                if let high = manager.dailyHighTemp {
                    extremeStat(icon: "thermometer.sun.fill", label: "Hi", value: formatTemp(high), tint: .red)
                }
                if let low = manager.dailyLowTemp {
                    extremeStat(icon: "thermometer.snowflake", label: "Lo", value: formatTemp(low), tint: .cyan)
                }
                if let gust = manager.dailyHighWind {
                    extremeStat(icon: "wind", label: "Gust", value: formatWind(gust), tint: .teal)
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func extremeStat(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func formatTemp(_ temp: Double) -> String {
        let display = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
        return String(format: "%.0f°", display)
    }

    private func formatWind(_ speed: Double) -> String {
        let display = isMetric ? speed * 1.60934 : speed
        let unit = isMetric ? "km/h" : "mph"
        return String(format: "%.0f %@", display, unit)
    }

    private var weatherConditionIcon: String {
        let hasRain = (observation.hourlyRainIn ?? 0) > 0
        let hasLightning = (observation.lightningHour ?? 0) > 0
        let highUV = (observation.uv ?? 0) >= 6
        let highWind = (observation.windSpeedMPH ?? 0) >= 20

        if hasLightning && hasRain { return "cloud.bolt.rain.fill" }
        if hasLightning { return "cloud.bolt.fill" }
        if hasRain { return "cloud.rain.fill" }
        if highWind { return "wind" }
        if highUV { return "sun.max.fill" }
        if (observation.solarRadiation ?? 0) > 0 { return "sun.max.fill" }
        return "cloud.sun.fill"
    }

    private var weatherConditionColor: Color {
        let hasRain = (observation.hourlyRainIn ?? 0) > 0
        let hasLightning = (observation.lightningHour ?? 0) > 0
        if hasLightning { return .yellow }
        if hasRain { return .cyan }
        return .orange
    }
}
