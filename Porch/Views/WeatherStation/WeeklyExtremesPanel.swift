//
//  WeeklyExtremesPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI

/// Compact panel showing the past 7 days of daily high/low temperature and peak wind
struct WeeklyExtremesPanel: View {
    @EnvironmentObject var manager: WeatherManager
    @Environment(\.dashboardTheme) private var theme

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        if !manager.extremesHistory.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(theme.temperatureColor)
                    Text("Weekly Extremes")
                        .font(.caption.weight(.semibold))
                    Spacer()
                }

                // Column headers
                HStack(spacing: 0) {
                    Text("Day")
                        .frame(width: 32, alignment: .leading)
                    Text("High")
                        .frame(maxWidth: .infinity)
                    Text("Low")
                        .frame(maxWidth: .infinity)
                    Text("Wind")
                        .frame(maxWidth: .infinity)
                }
                .font(.system(size: 9))
                .foregroundStyle(theme.secondaryText)

                Divider().opacity(0.2)

                ForEach(manager.extremesHistory.reversed()) { record in
                    HStack(spacing: 0) {
                        Text(shortDay(record.date))
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 32, alignment: .leading)

                        if let hi = record.highTemp {
                            HStack(spacing: 1) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 7))
                                Text(formatTemp(hi))
                            }
                            .font(.caption2)
                            .foregroundStyle(theme.highTempColor)
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(theme.secondaryText)
                                .frame(maxWidth: .infinity)
                        }

                        if let lo = record.lowTemp {
                            HStack(spacing: 1) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 7))
                                Text(formatTemp(lo))
                            }
                            .font(.caption2)
                            .foregroundStyle(theme.lowTempColor)
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(theme.secondaryText)
                                .frame(maxWidth: .infinity)
                        }

                        if let wind = record.highWind {
                            HStack(spacing: 1) {
                                Image(systemName: "wind")
                                    .font(.system(size: 7))
                                Text(formatWind(wind))
                            }
                            .font(.caption2)
                            .foregroundStyle(theme.windColor)
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.2))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(12)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private func shortDay(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        return dayFormatter.string(from: date)
    }

    private func formatTemp(_ temp: Double) -> String {
        let display = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
        return String(format: "%.0f°", display)
    }

    private func formatWind(_ speed: Double) -> String {
        let display = isMetric ? speed * 1.60934 : speed
        return String(format: "%.0f", display)
    }
}
