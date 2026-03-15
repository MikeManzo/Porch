//
//  WeatherHeroView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather

/// Large hero display showing the primary temperature reading and feels-like
struct WeatherHeroView: View {
    let observation: AmbientLastData

    var body: some View {
        VStack(spacing: 4) {
            // Weather condition icon
            Image(systemName: weatherConditionIcon)
                .font(.system(size: 32))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(weatherConditionColor)

            // Primary temperature
            if let temp = observation.tempF {
                Text("\(temp, specifier: "%.1f")\u{00B0}")
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .contentTransition(.numericText())
            } else {
                Text("--\u{00B0}")
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Feels like + condition summary
            HStack(spacing: 12) {
                if let feelsLike = observation.feelsLike {
                    Label("Feels \(feelsLike, specifier: "%.0f")\u{00B0}", systemImage: "person.and.background.dotted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let humidity = observation.humidity {
                    Label("\(humidity)%", systemImage: "humidity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Observation time
            Text("Updated \(observation.observationDateFormatted)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Weather Condition Logic

    /// Derive an appropriate weather icon from sensor data
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
