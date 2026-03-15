//
//  ConditionsGridView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather

/// Displays common secondary weather conditions in a compact 2-column grid.
struct ConditionsGridView: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        let items = buildConditionItems()

        if !items.isEmpty {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(items) { item in
                    conditionTile(item)
                }
            }
        }
    }

    // MARK: - Tile View

    private func conditionTile(_ item: ConditionItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.caption)
                .foregroundStyle(item.tint)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(item.value)
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Build Items from Available Sensors

    private func buildConditionItems() -> [ConditionItem] {
        var items: [ConditionItem] = []

        // Dew Point
        if let dew = observation.dewPoint {
            let value = isMetric
                ? String(format: "%.1f\u{00B0}C", (dew - 32) * 5.0 / 9.0)
                : String(format: "%.1f\u{00B0}F", dew)
            items.append(ConditionItem(
                icon: "drop.degreesign", label: "Dew Point",
                value: value, tint: .teal
            ))
        }

        // Solar Radiation (W/m² is universal)
        if let solar = observation.solarRadiation {
            items.append(ConditionItem(
                icon: "sun.max.fill", label: "Solar Radiation",
                value: String(format: "%.0f W/m\u{00B2}", solar), tint: .orange
            ))
        }

        // UV Index (dimensionless)
        if let uv = observation.uv {
            items.append(ConditionItem(
                icon: "sun.max.trianglebadge.exclamationmark", label: "UV Index",
                value: "\(uv) \(uvDescription(uv))", tint: uvColor(uv)
            ))
        }

        // PM2.5 Air Quality
        if let pm = observation.pm25 {
            items.append(ConditionItem(
                icon: "aqi.medium", label: "PM2.5",
                value: String(format: "%.1f \u{03BC}g/m\u{00B3}", pm), tint: pm25Color(pm)
            ))
        }

        // CO2
        if let co2 = observation.co2 {
            items.append(ConditionItem(
                icon: "carbon.dioxide.cloud", label: "CO\u{2082}",
                value: "\(co2) ppm", tint: co2Color(co2)
            ))
        }

        // Indoor Temperature
        if let indoorTemp = observation.tempInF {
            let value = isMetric
                ? String(format: "%.1f\u{00B0}C", (indoorTemp - 32) * 5.0 / 9.0)
                : String(format: "%.1f\u{00B0}F", indoorTemp)
            items.append(ConditionItem(
                icon: "house.fill", label: "Indoor Temp",
                value: value, tint: .purple
            ))
        }

        // Indoor Humidity (% is universal)
        if let indoorHumidity = observation.humidityIn {
            items.append(ConditionItem(
                icon: "humidity", label: "Indoor Humidity",
                value: "\(indoorHumidity)%", tint: .purple
            ))
        }

        // Max Daily Gust
        if let gust = observation.maxDailyGust {
            let value = isMetric
                ? String(format: "%.1f km/h", gust * 1.60934)
                : String(format: "%.1f mph", gust)
            items.append(ConditionItem(
                icon: "wind", label: "Max Gust Today",
                value: value, tint: .blue
            ))
        }

        // Lightning — enhanced with distance and time
        if let strikes = observation.lightningDay, strikes > 0 {
            var lightningValue = "\(strikes) strikes"

            if let dist = observation.lightningDistance {
                let distStr = isMetric
                    ? String(format: "%.1f km", dist * 1.60934)
                    : String(format: "%.1f mi", dist)
                lightningValue += " · \(distStr)"
            }

            items.append(ConditionItem(
                icon: "bolt.fill", label: lightningLabel,
                value: lightningValue, tint: .yellow
            ))
        }

        // Last Rain
        if let lastRain = observation.lastRain, !lastRain.isEmpty {
            items.append(ConditionItem(
                icon: "clock", label: "Last Rain",
                value: SensorFormatter.menuBarString(for: "lastRain", from: observation),
                tint: .cyan
            ))
        }

        return items
    }

    /// Lightning label includes time since last strike if available
    private var lightningLabel: String {
        guard let ts = observation.lightningTime, ts > 0 else {
            return "Lightning Today"
        }
        let date = Date(timeIntervalSince1970: TimeInterval(ts) / 1000.0)
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 {
            return "Lightning · \(minutes)m ago"
        }
        let hours = minutes / 60
        return "Lightning · \(hours)h ago"
    }

    // MARK: - UV Helpers

    private func uvDescription(_ uv: Int) -> String {
        switch uv {
        case 0...2: return "Low"
        case 3...5: return "Moderate"
        case 6...7: return "High"
        case 8...10: return "Very High"
        default: return "Extreme"
        }
    }

    private func uvColor(_ uv: Int) -> Color {
        switch uv {
        case 0...2: return .green
        case 3...5: return .yellow
        case 6...7: return .orange
        case 8...10: return .red
        default: return .purple
        }
    }

    // MARK: - Air Quality Helpers

    /// EPA AQI color scale for PM2.5
    private func pm25Color(_ pm: Double) -> Color {
        switch pm {
        case ..<12: return .green
        case 12..<35.5: return .yellow
        case 35.5..<55.5: return .orange
        case 55.5..<150.5: return .red
        case 150.5..<250.5: return .purple
        default: return .brown
        }
    }

    private func co2Color(_ co2: Int) -> Color {
        switch co2 {
        case ..<800: return .green
        case 800..<1200: return .yellow
        case 1200..<2000: return .orange
        default: return .red
        }
    }
}

// MARK: - Model

private struct ConditionItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
    let tint: Color
}
