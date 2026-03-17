//
//  EnvironmentPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather

/// Panel displaying solar, UV, lightning, and air quality data
struct EnvironmentPanel: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sun.max.trianglebadge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("Environment")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            // Solar & UV
            if observation.solarRadiation != nil || observation.uv != nil {
                HStack(spacing: 16) {
                    if let solar = observation.solarRadiation {
                        envStat(icon: "sun.max.fill", label: "Solar", value: String(format: "%.0f W/m²", solar), tint: .yellow)
                    }
                    if let uv = observation.uv {
                        envStat(icon: "sun.max.trianglebadge.exclamationmark", label: uvDescription(uv), value: "\(uv)", tint: uvColor(uv))
                    }
                }
            }

            // Lightning
            if let strikes = observation.lightningDay, strikes > 0 {
                Divider().opacity(0.2)
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.callout)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(strikes) strike\(strikes == 1 ? "" : "s") today")
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            if let dist = observation.lightningDistance {
                                let distStr = isMetric
                                    ? String(format: "%.1f km", dist * 1.60934)
                                    : String(format: "%.1f mi", dist)
                                Text("Nearest: \(distStr)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            if let ts = observation.lightningTime, ts > 0 {
                                Text("Last: \(timeAgo(ts))")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    Spacer()
                }
            }

            // Air Quality
            if observation.pm25 != nil || observation.co2 != nil {
                Divider().opacity(0.2)
                HStack(spacing: 16) {
                    if let pm25 = observation.pm25 {
                        envStat(icon: "aqi.medium", label: pm25Label(pm25), value: String(format: "%.1f µg/m³", pm25), tint: pm25Color(pm25))
                    }
                    if let co2 = observation.co2 {
                        envStat(icon: "carbon.dioxide.cloud", label: co2Label(co2), value: "\(co2) ppm", tint: co2Color(co2))
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func envStat(icon: String, label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeAgo(_ timestampMs: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0)
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }

    // UV color coding
    private func uvColor(_ uv: Int) -> Color {
        switch uv {
        case 0...2: .green
        case 3...5: .yellow
        case 6...7: .orange
        case 8...10: .red
        default: .purple
        }
    }

    private func uvDescription(_ uv: Int) -> String {
        switch uv {
        case 0...2: "UV Low"
        case 3...5: "UV Moderate"
        case 6...7: "UV High"
        case 8...10: "UV Very High"
        default: "UV Extreme"
        }
    }

    // PM2.5 EPA AQI color scale
    private func pm25Color(_ pm25: Double) -> Color {
        switch pm25 {
        case ..<12.1: .green
        case ..<35.5: .yellow
        case ..<55.5: .orange
        case ..<150.5: .red
        case ..<250.5: .purple
        default: .brown
        }
    }

    private func pm25Label(_ pm25: Double) -> String {
        switch pm25 {
        case ..<12.1: "Good"
        case ..<35.5: "Moderate"
        case ..<55.5: "Unhealthy*"
        case ..<150.5: "Unhealthy"
        default: "Hazardous"
        }
    }

    // CO2 thresholds
    private func co2Color(_ co2: Int) -> Color {
        switch co2 {
        case ..<800: .green
        case ..<1000: .yellow
        case ..<2000: .orange
        default: .red
        }
    }

    private func co2Label(_ co2: Int) -> String {
        switch co2 {
        case ..<800: "Normal"
        case ..<1000: "Fair"
        case ..<2000: "Poor"
        default: "Bad"
        }
    }
}
