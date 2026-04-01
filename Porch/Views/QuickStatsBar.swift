//
//  QuickStatsBar.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Compact horizontal bar showing key weather stats with Liquid Glass treatment.
/// Stats are customizable via manager.quickStatKeys.
struct QuickStatsBar: View {
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?
    @EnvironmentObject var manager: WeatherManager
    @Namespace private var glassNamespace

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
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(Array(manager.quickStatKeys.enumerated()), id: \.element) { index, key in
                    if index > 0 {
                        verticalDivider
                    }
                    statView(for: key)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Dynamic Stat View

    @ViewBuilder
    private func statView(for key: String) -> some View {
        // Map ambient keys to porch keys for lookup
        let porchKey = WeatherManager.ambientToPorchKeyMap[key] ?? key

        switch key {
        case "windSpeedMPH":
            windStat
        case "humidity":
            quickStat(
                icon: "humidity",
                value: humidityValue,
                label: "Humidity"
            )
        case "baromRelIn":
            pressureStat
        case "uv":
            quickStat(
                icon: "sun.max.trianglebadge.exclamationmark",
                value: uvValue,
                label: "UV"
            )
        default:
            if let porchData {
                let category = PorchWeatherData.category(for: porchKey)
                quickStat(
                    icon: category.iconName,
                    value: SensorFormatter.menuBarString(for: porchKey, from: porchData, unitSystem: manager.unitSystem),
                    label: SensorFormatter.sensorDescription(for: porchKey, unitSystem: manager.unitSystem)
                )
            } else if let observation {
                let category = AmbientLastData.propertyCategories[key] ?? .unknown
                quickStat(
                    icon: category.iconName,
                    value: SensorFormatter.menuBarString(for: key, from: observation, unitSystem: manager.unitSystem),
                    label: SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem)
                )
            }
        }
    }

    // MARK: - Value Accessors

    private var humidityValue: String {
        if let porchData, let h = porchData.humidity { return "\(h)%" }
        if let observation, let h = observation.humidity { return "\(h)%" }
        return "--"
    }

    private var uvValue: String {
        if let porchData, let uv = porchData.uvIndex { return "\(uv)" }
        if let observation, let uv = observation.uv { return "\(uv)" }
        return "--"
    }

    // MARK: - Wind Stat with Compass

    private var windStat: some View {
        VStack(spacing: 6) {
            Group {
                let dir = porchData?.windDirection ?? observation?.windDir
                if let dir {
                    WindCompassView(degrees: dir)
                } else {
                    Image(systemName: "wind")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 28)
            Text(formatWind())
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(isMetric ? "km/h" : "mph")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pressure Stat with Trend Arrow

    private var pressureStat: some View {
        VStack(spacing: 6) {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(height: 28)
            HStack(spacing: 2) {
                Text(formatPressure())
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: manager.pressureTrend.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(pressureTrendColor)
            }
            Text("Pressure")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var pressureTrendColor: Color {
        switch manager.pressureTrend {
        case .rising: return .green
        case .falling: return .red
        case .steady: return .secondary
        }
    }

    // MARK: - Generic Stat

    private func quickStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(height: 28)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 1, height: 48)
    }

    // MARK: - Formatting

    private func formatWind() -> String {
        let speed = porchData?.windSpeedMPH ?? observation?.windSpeedMPH
        guard let speed else { return "--" }
        let displaySpeed = isMetric ? speed * 1.60934 : speed
        return String(format: "%.1f", displaySpeed)
    }

    private func formatPressure() -> String {
        let pressure = porchData?.pressureRelativeInHg ?? observation?.baromRelIn
        guard let pressure else { return "--" }
        if isMetric {
            return String(format: "%.0f", pressure * 33.8639)
        }
        return String(format: "%.2f\"", pressure)
    }
}
