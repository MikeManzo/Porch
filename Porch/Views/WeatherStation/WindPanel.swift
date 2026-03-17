//
//  WindPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather

/// Wind panel with animated compass rose and wind stats
struct WindPanel: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "wind")
                    .foregroundStyle(.cyan)
                Text("Wind")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            // Compass rose
            AnimatedCompassRoseView(
                windDirection: observation.windDir ?? 0,
                windDirAvg10m: observation.windDirAvg10m,
                windSpeed: observation.windSpeedMPH,
                windGust: observation.windGustMPH,
                isMetric: isMetric
            )

            // Direction label
            HStack(spacing: 8) {
                Text(cardinalDirection(for: observation.windDir ?? 0))
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(observation.windDir ?? 0)°")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Wind stats row
            HStack(spacing: 0) {
                windStat(label: "Speed", value: formatSpeed(observation.windSpeedMPH), icon: "gauge.with.dots.needle.33percent")
                Divider().frame(height: 30)
                windStat(label: "Gust", value: formatSpeed(observation.windGustMPH), icon: "gauge.with.dots.needle.67percent")
                Divider().frame(height: 30)
                windStat(label: "Max", value: formatSpeed(observation.maxDailyGust), icon: "gauge.with.dots.needle.100percent")
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func windStat(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.cyan.opacity(0.7))
            Text(value)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private func formatSpeed(_ speed: Double?) -> String {
        guard let speed else { return "--" }
        let value = isMetric ? speed * 1.60934 : speed
        let unit = isMetric ? "km/h" : "mph"
        return String(format: "%.0f %@", value, unit)
    }

    private func cardinalDirection(for degrees: Int) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int(round(Double(degrees) / 22.5)) % 16
        return directions[index]
    }
}
