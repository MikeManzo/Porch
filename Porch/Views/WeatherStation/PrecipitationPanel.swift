//
//  PrecipitationPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather

/// Panel displaying rainfall accumulation periods and last rain time
struct PrecipitationPanel: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "cloud.rain")
                    .foregroundStyle(.blue)
                Text("Precipitation")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            // Rain periods grid
            let periods = buildRainPeriods()
            if !periods.isEmpty {
                let rows = stride(from: 0, to: periods.count, by: 3).map {
                    Array(periods[$0..<min($0 + 3, periods.count)])
                }
                VStack(spacing: 6) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 6) {
                            ForEach(row, id: \.label) { period in
                                VStack(spacing: 4) {
                                    Text(period.value)
                                        .font(.system(.callout, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(period.label)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                Text("No rain data")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }

            // Last rain timestamp
            if let lastRain = observation.lastRain, !lastRain.isEmpty {
                Divider().opacity(0.2)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Last rain: \(SensorFormatter.menuBarString(for: "lastRain", from: observation))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Rain Periods

    private func buildRainPeriods() -> [(label: String, value: String)] {
        var periods: [(label: String, value: String)] = []
        if let val = observation.hourlyRainIn { periods.append(("Hourly", formatRain(val))) }
        if let val = observation.dailyRainIn { periods.append(("Today", formatRain(val))) }
        if let val = observation.weeklyRainIn { periods.append(("Week", formatRain(val))) }
        if let val = observation.monthlyRainIn { periods.append(("Month", formatRain(val))) }
        if let val = observation.yearlyRainIn { periods.append(("Year", formatRain(val))) }
        if let val = observation.eventRainIn { periods.append(("Event", formatRain(val))) }
        return periods
    }

    private func formatRain(_ inches: Double) -> String {
        if isMetric {
            return String(format: "%.1f mm", inches * 25.4)
        }
        return String(format: "%.2f\"", inches)
    }
}
