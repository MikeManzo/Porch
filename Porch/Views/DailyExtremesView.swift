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
        HStack(spacing: 7) {
            if let high = manager.dailyHighTemp {
                StatChip(icon: "thermometer.sun.fill", value: formatTemp(high), label: "Hi", tint: .red)
            }

            if let low = manager.dailyLowTemp {
                StatChip(icon: "thermometer.snowflake", value: formatTemp(low), label: "Lo", tint: .blue)
            }

            if let wind = manager.dailyHighWind {
                StatChip(icon: "wind", value: formatWind(wind), label: "Gust", tint: .teal)
            }
        }
        .padding(.horizontal, 12)
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
