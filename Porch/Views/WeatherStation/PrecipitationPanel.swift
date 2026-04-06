//
//  PrecipitationPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Panel displaying rainfall accumulation periods and last rain time
struct PrecipitationPanel: View {
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?
    @EnvironmentObject var manager: WeatherManager
    @Environment(\.dashboardTheme) private var theme

    /// Init from PorchWeatherData (new path)
    init(porchData: PorchWeatherData) {
        self.porchData = porchData
        self.observation = nil
    }

    /// Init from AmbientLastData (legacy path)
    init(observation: AmbientLastData) {
        self.observation = observation
        self.porchData = nil
    }

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.rain")
                    .foregroundStyle(theme.rainColor)
                Text("Precipitation")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

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
                                        .foregroundStyle(theme.primaryText)
                                    Text(period.label)
                                        .font(.caption2)
                                        .foregroundStyle(theme.secondaryText)
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
                    .foregroundStyle(theme.secondaryText)
            }

            // Last rain timestamp (Ambient only)
            if let observation, let lastRain = observation.lastRain, !lastRain.isEmpty {
                Divider().opacity(0.2)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                    Text("Last rain: \(SensorFormatter.menuBarString(for: "lastRain", from: observation))")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Rain Periods

    private func buildRainPeriods() -> [(label: String, value: String)] {
        if let porchData {
            var periods: [(label: String, value: String)] = []
            if let val = porchData.rainRateInPerHr { periods.append(("Rate", formatRain(val))) }
            if let val = porchData.dailyRainIn { periods.append(("Today", formatRain(val))) }
            if let val = porchData.weeklyRainIn { periods.append(("Week", formatRain(val))) }
            if let val = porchData.monthlyRainIn { periods.append(("Month", formatRain(val))) }
            if let val = porchData.yearlyRainIn { periods.append(("Year", formatRain(val))) }
            if let val = porchData.eventRainIn { periods.append(("Event", formatRain(val))) }
            return periods
        } else if let observation {
            var periods: [(label: String, value: String)] = []
            if let val = observation.hourlyRainIn { periods.append(("Hourly", formatRain(val))) }
            if let val = observation.dailyRainIn { periods.append(("Today", formatRain(val))) }
            if let val = observation.weeklyRainIn { periods.append(("Week", formatRain(val))) }
            if let val = observation.monthlyRainIn { periods.append(("Month", formatRain(val))) }
            if let val = observation.yearlyRainIn { periods.append(("Year", formatRain(val))) }
            if let val = observation.eventRainIn { periods.append(("Event", formatRain(val))) }
            return periods
        }
        return []
    }

    private func formatRain(_ inches: Double) -> String {
        if isMetric {
            return String(format: "%.1f mm", inches * 25.4)
        }
        return String(format: "%.2f\"", inches)
    }
}
