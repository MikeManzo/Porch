//
//  StationPulseView.swift
//  Porch
//
//  Created by Mike Manzo on 3/20/26.
//

import SwiftUI
import PorchStationKit

/// Permanent, above-the-fold strip surfacing the sensors that make this station
/// a personal-weather-station dashboard rather than a generic weather app
/// (indoor climate, soil moisture, lightning, air quality) — previously only
/// visible after expanding "All Sensors" at the bottom of the scroll view.
struct StationPulseView: View {
    let porchData: PorchWeatherData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        let items = buildItems()

        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("STATION")
                    .font(.system(size: 9.5, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(items) { item in
                            pulseChip(item)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }

    private func pulseChip(_ item: PulseItem) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(item.tint)
                .frame(width: 6, height: 6)
            Text(item.text)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK:  Build Items

    private func buildItems() -> [PulseItem] {
        var items: [PulseItem] = []

        if let indoorTemp = porchData.indoorTempF {
            let value = isMetric
                ? String(format: "%.0f\u{00B0}C", (indoorTemp - 32) * 5.0 / 9.0)
                : String(format: "%.0f\u{00B0}F", indoorTemp)
            items.append(PulseItem(text: "Indoor \(value)", tint: .purple))
        }

        if let moisture = averageSoilMoisture {
            items.append(PulseItem(text: "Soil \(moisture)%", tint: .brown))
        }

        if let strikes = porchData.lightningDayCount {
            let text = strikes > 0 ? "Lightning \(strikes)" : "No Strikes"
            items.append(PulseItem(text: text, tint: strikes > 0 ? .yellow : .green))
        }

        if let pm = porchData.pm25 {
            items.append(PulseItem(text: "AQI \(String(format: "%.0f", pm))", tint: pm25Tint(pm)))
        }

        if let co2 = porchData.co2 {
            items.append(PulseItem(text: "CO\u{2082} \(co2)", tint: co2Tint(co2)))
        }

        return items
    }

    private var averageSoilMoisture: Int? {
        let values = porchData.soilMoisture.values
        guard !values.isEmpty else { return nil }
        return Int(values.reduce(0, +) / values.count)
    }

    private func pm25Tint(_ pm: Double) -> Color {
        switch pm {
        case ..<12: return .green
        case 12..<35.5: return .yellow
        case 35.5..<55.5: return .orange
        default: return .red
        }
    }

    private func co2Tint(_ co2: Int) -> Color {
        switch co2 {
        case ..<800: return .green
        case 800..<1200: return .yellow
        default: return .orange
        }
    }
}

// MARK:  Model

private struct PulseItem: Identifiable {
    let id = UUID()
    let text: String
    let tint: Color
}
