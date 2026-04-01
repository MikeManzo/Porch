//
//  RainSummaryView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Compact card showing all rain accumulation periods and last rain time
struct RainSummaryView: View {
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?
    @EnvironmentObject var manager: WeatherManager

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

                // Last rain timestamp (Ambient only — not available in PorchWeatherData)
                if let observation, let lastRain = observation.lastRain, !lastRain.isEmpty {
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
        if let porchData {
            return buildFromPorch(porchData)
        } else if let observation {
            return buildFromAmbient(observation)
        }
        return []
    }

    private func buildFromPorch(_ data: PorchWeatherData) -> [(label: String, value: String)] {
        var periods: [(label: String, value: String)] = []
        if let val = data.rainRateInPerHr { periods.append(("Rate", formatRain(val))) }
        if let val = data.dailyRainIn { periods.append(("Today", formatRain(val))) }
        if let val = data.weeklyRainIn { periods.append(("Week", formatRain(val))) }
        if let val = data.monthlyRainIn { periods.append(("Month", formatRain(val))) }
        if let val = data.yearlyRainIn { periods.append(("Year", formatRain(val))) }
        if let val = data.eventRainIn { periods.append(("Event", formatRain(val))) }
        return periods
    }

    private func buildFromAmbient(_ obs: AmbientLastData) -> [(label: String, value: String)] {
        var periods: [(label: String, value: String)] = []
        if let val = obs.hourlyRainIn { periods.append(("Hourly", formatRain(val))) }
        if let val = obs.dailyRainIn { periods.append(("Today", formatRain(val))) }
        if let val = obs.weeklyRainIn { periods.append(("Week", formatRain(val))) }
        if let val = obs.monthlyRainIn { periods.append(("Month", formatRain(val))) }
        if let val = obs.yearlyRainIn { periods.append(("Year", formatRain(val))) }
        if let val = obs.eventRainIn { periods.append(("Event", formatRain(val))) }
        return periods
    }

    private func formatRain(_ inches: Double) -> String {
        if isMetric {
            return String(format: "%.1f mm", inches * 25.4)
        }
        return String(format: "%.2f\"", inches)
    }
}
