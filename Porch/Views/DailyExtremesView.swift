//
//  DailyExtremesView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI

/// Compact row showing daily high/low temperature and peak wind
struct DailyExtremesView: View {
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        HStack(spacing: 16) {
            if let high = manager.dailyHighTemp {
                extremeStat(
                    icon: "thermometer.sun.fill",
                    label: "Hi",
                    value: formatTemp(high),
                    tint: .red
                )
            }

            if let low = manager.dailyLowTemp {
                extremeStat(
                    icon: "thermometer.snowflake",
                    label: "Lo",
                    value: formatTemp(low),
                    tint: .blue
                )
            }

            if let wind = manager.dailyHighWind {
                extremeStat(
                    icon: "wind",
                    label: "Gust",
                    value: formatWind(wind),
                    tint: .teal
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
    }

    private func extremeStat(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(tint)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
        }
    }

    private func formatTemp(_ temp: Double) -> String {
        let display = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
        return String(format: "%.0f\u{00B0}", display)
    }

    private func formatWind(_ speed: Double) -> String {
        let display = isMetric ? speed * 1.60934 : speed
        let unit = isMetric ? "km/h" : "mph"
        return String(format: "%.0f %@", display, unit)
    }
}
