//
//  ConditionsGridView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Displays common secondary weather conditions in a compact 2-column grid.
struct ConditionsGridView: View {
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
        if let porchData {
            return buildFromPorch(porchData)
        } else if let observation {
            return buildFromAmbient(observation)
        }
        return []
    }

    private func buildFromPorch(_ data: PorchWeatherData) -> [ConditionItem] {
        var items: [ConditionItem] = []

        if let dew = data.dewPointF {
            let value = isMetric
                ? String(format: "%.1f\u{00B0}C", (dew - 32) * 5.0 / 9.0)
                : String(format: "%.1f\u{00B0}F", dew)
            items.append(ConditionItem(icon: "drop.degreesign", label: "Dew Point", value: value, tint: .teal))
        }

        if let solar = data.solarRadiation {
            items.append(ConditionItem(icon: "sun.max.fill", label: "Solar Radiation",
                                       value: String(format: "%.0f W/m\u{00B2}", solar), tint: .orange))
        }

        if let uv = data.uvIndex {
            items.append(ConditionItem(icon: "sun.max.trianglebadge.exclamationmark", label: "UV Index",
                                       value: "\(uv) \(uvDescription(uv))", tint: uvColor(uv)))
        }

        if let pm = data.pm25 {
            items.append(ConditionItem(icon: "aqi.medium", label: "PM2.5",
                                       value: String(format: "%.1f \u{03BC}g/m\u{00B3}", pm), tint: pm25Color(pm)))
        }

        if let co2 = data.co2 {
            items.append(ConditionItem(icon: "carbon.dioxide.cloud", label: "CO\u{2082}",
                                       value: "\(co2) ppm", tint: co2Color(co2)))
        }

        if let indoorTemp = data.indoorTempF {
            let value = isMetric
                ? String(format: "%.1f\u{00B0}C", (indoorTemp - 32) * 5.0 / 9.0)
                : String(format: "%.1f\u{00B0}F", indoorTemp)
            items.append(ConditionItem(icon: "house.fill", label: "Indoor Temp", value: value, tint: .purple))
        }

        if let indoorHumidity = data.indoorHumidity {
            items.append(ConditionItem(icon: "humidity", label: "Indoor Humidity",
                                       value: "\(indoorHumidity)%", tint: .purple))
        }

        if let gust = data.maxDailyGustMPH {
            let value = isMetric
                ? String(format: "%.1f km/h", gust * 1.60934)
                : String(format: "%.1f mph", gust)
            items.append(ConditionItem(icon: "wind", label: "Max Gust Today", value: value, tint: .blue))
        }

        if let strikes = data.lightningDayCount, strikes > 0 {
            var lightningValue = "\(strikes) strikes"
            if let dist = data.lightningDistanceMi {
                let distStr = isMetric
                    ? String(format: "%.1f km", dist * 1.60934)
                    : String(format: "%.1f mi", dist)
                lightningValue += " · \(distStr)"
            }
            items.append(ConditionItem(icon: "bolt.fill", label: lightningLabelPorch(data),
                                       value: lightningValue, tint: .yellow))
        }

        return items
    }

    private func buildFromAmbient(_ obs: AmbientLastData) -> [ConditionItem] {
        var items: [ConditionItem] = []

        if let dew = obs.dewPoint {
            let value = isMetric
                ? String(format: "%.1f\u{00B0}C", (dew - 32) * 5.0 / 9.0)
                : String(format: "%.1f\u{00B0}F", dew)
            items.append(ConditionItem(icon: "drop.degreesign", label: "Dew Point", value: value, tint: .teal))
        }

        if let solar = obs.solarRadiation {
            items.append(ConditionItem(icon: "sun.max.fill", label: "Solar Radiation",
                                       value: String(format: "%.0f W/m\u{00B2}", solar), tint: .orange))
        }

        if let uv = obs.uv {
            items.append(ConditionItem(icon: "sun.max.trianglebadge.exclamationmark", label: "UV Index",
                                       value: "\(uv) \(uvDescription(uv))", tint: uvColor(uv)))
        }

        if let pm = obs.pm25 {
            items.append(ConditionItem(icon: "aqi.medium", label: "PM2.5",
                                       value: String(format: "%.1f \u{03BC}g/m\u{00B3}", pm), tint: pm25Color(pm)))
        }

        if let co2 = obs.co2 {
            items.append(ConditionItem(icon: "carbon.dioxide.cloud", label: "CO\u{2082}",
                                       value: "\(co2) ppm", tint: co2Color(co2)))
        }

        if let indoorTemp = obs.tempInF {
            let value = isMetric
                ? String(format: "%.1f\u{00B0}C", (indoorTemp - 32) * 5.0 / 9.0)
                : String(format: "%.1f\u{00B0}F", indoorTemp)
            items.append(ConditionItem(icon: "house.fill", label: "Indoor Temp", value: value, tint: .purple))
        }

        if let indoorHumidity = obs.humidityIn {
            items.append(ConditionItem(icon: "humidity", label: "Indoor Humidity",
                                       value: "\(indoorHumidity)%", tint: .purple))
        }

        if let gust = obs.maxDailyGust {
            let value = isMetric
                ? String(format: "%.1f km/h", gust * 1.60934)
                : String(format: "%.1f mph", gust)
            items.append(ConditionItem(icon: "wind", label: "Max Gust Today", value: value, tint: .blue))
        }

        if let strikes = obs.lightningDay, strikes > 0 {
            var lightningValue = "\(strikes) strikes"
            if let dist = obs.lightningDistance {
                let distStr = isMetric
                    ? String(format: "%.1f km", dist * 1.60934)
                    : String(format: "%.1f mi", dist)
                lightningValue += " · \(distStr)"
            }
            items.append(ConditionItem(icon: "bolt.fill", label: lightningLabelAmbient(obs),
                                       value: lightningValue, tint: .yellow))
        }

        if let lastRain = obs.lastRain, !lastRain.isEmpty {
            items.append(ConditionItem(icon: "clock", label: "Last Rain",
                                       value: SensorFormatter.menuBarString(for: "lastRain", from: obs),
                                       tint: .cyan))
        }

        return items
    }

    // MARK: - Lightning Labels

    private func lightningLabelPorch(_ data: PorchWeatherData) -> String {
        guard let ts = data.lightningTime else { return "Lightning Today" }
        let minutes = Int(Date().timeIntervalSince(ts) / 60)
        if minutes < 60 { return "Lightning · \(minutes)m ago" }
        let hours = minutes / 60
        return "Lightning · \(hours)h ago"
    }

    private func lightningLabelAmbient(_ obs: AmbientLastData) -> String {
        guard let ts = obs.lightningTime, ts > 0 else { return "Lightning Today" }
        let date = Date(timeIntervalSince1970: TimeInterval(ts) / 1000.0)
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 { return "Lightning · \(minutes)m ago" }
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
