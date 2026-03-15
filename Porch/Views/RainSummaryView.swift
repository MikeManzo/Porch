//
//  RainSummaryView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather

/// Compact card showing all rain accumulation periods and last rain time
struct RainSummaryView: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        let periods = buildRainPeriods()
        if !periods.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Rainfall", systemImage: "cloud.rain")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 6) {
                    ForEach(periods, id: \.label) { period in
                        VStack(spacing: 2) {
                            Text(period.value)
                                .font(.system(.callout, design: .rounded, weight: .medium))
                            Text(period.label)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                }

                // Last rain timestamp
                if let lastRain = observation.lastRain, !lastRain.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("Last rain: \(SensorFormatter.menuBarString(for: "lastRain", from: observation))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private func buildRainPeriods() -> [(label: String, value: String)] {
        var periods: [(label: String, value: String)] = []

        if let val = observation.hourlyRainIn {
            periods.append(("Hourly", formatRain(val)))
        }
        if let val = observation.dailyRainIn {
            periods.append(("Today", formatRain(val)))
        }
        if let val = observation.weeklyRainIn {
            periods.append(("Week", formatRain(val)))
        }
        if let val = observation.monthlyRainIn {
            periods.append(("Month", formatRain(val)))
        }
        if let val = observation.yearlyRainIn {
            periods.append(("Year", formatRain(val)))
        }
        if let val = observation.eventRainIn {
            periods.append(("Event", formatRain(val)))
        }

        return periods
    }

    private func formatRain(_ inches: Double) -> String {
        if isMetric {
            return String(format: "%.1f mm", inches * 25.4)
        }
        return String(format: "%.2f\"", inches)
    }
}
