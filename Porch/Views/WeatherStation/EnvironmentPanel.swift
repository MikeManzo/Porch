//
//  EnvironmentPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Panel displaying solar, UV, lightning, and air quality data
struct EnvironmentPanel: View {
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

    private var solarVal: Double? { porchData?.solarRadiation ?? observation?.solarRadiation }
    private var uvVal: Int? { porchData?.uvIndex ?? observation?.uv }
    private var lightningCount: Int? { porchData?.lightningDayCount ?? observation?.lightningDay }
    private var lightningDist: Double? { porchData?.lightningDistanceMi ?? observation?.lightningDistance }
    private var pm25Val: Double? { porchData?.pm25 ?? observation?.pm25 }
    private var co2Val: Int? { porchData?.co2 ?? observation?.co2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sun.max.trianglebadge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("Environment")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            // Solar & UV
            if solarVal != nil || uvVal != nil {
                HStack(spacing: 16) {
                    if let solar = solarVal {
                        envStat(icon: "sun.max.fill", label: "Solar", value: String(format: "%.0f W/m²", solar), tint: .yellow)
                    }
                    if let uv = uvVal {
                        envStat(icon: "sun.max.trianglebadge.exclamationmark", label: uvDescription(uv), value: "\(uv)", tint: uvColor(uv))
                    }
                }
            }

            // Lightning
            if let strikes = lightningCount {
                Divider().opacity(0.2)
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(strikes > 0 ? .yellow : .white.opacity(0.3))
                        .font(.callout)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strikes > 0
                            ? "\(strikes) strike\(strikes == 1 ? "" : "s") today"
                            : "0 strikes today")
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            if strikes > 0, let dist = lightningDist {
                                let distStr = isMetric
                                    ? String(format: "%.1f km", dist * 1.60934)
                                    : String(format: "%.1f mi", dist)
                                Text("Nearest: \(distStr)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            if strikes > 0 {
                                if let porchData, let ts = porchData.lightningTime {
                                    Text("Last: \(timeAgoPorch(ts))")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                } else if let observation, let ts = observation.lightningTime, ts > 0 {
                                    Text("Last: \(timeAgoAmbient(ts))")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                            if strikes == 0 {
                                Text("All clear")
                                    .font(.caption)
                                    .foregroundStyle(.green.opacity(0.6))
                            }
                        }
                    }
                    Spacer()
                }
            }

            // Air Quality
            if pm25Val != nil || co2Val != nil {
                Divider().opacity(0.2)
                HStack(spacing: 16) {
                    if let pm25 = pm25Val {
                        let aqi = AQICalculator.calculate(pm25: pm25)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "aqi.medium")
                                    .font(.caption)
                                    .foregroundStyle(aqi.color)
                                Text(aqi.category)
                                    .font(.caption)
                                    .foregroundStyle(aqi.color)
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(aqi.value)")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundStyle(aqi.color)
                                Text("AQI")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Text(String(format: "%.1f µg/m³", pm25))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let co2 = co2Val {
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

    private func timeAgoPorch(_ date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }

    private func timeAgoAmbient(_ timestampMs: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0)
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }

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
