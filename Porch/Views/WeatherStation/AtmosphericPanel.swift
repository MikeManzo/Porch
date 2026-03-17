//
//  AtmosphericPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather

/// Panel displaying pressure, humidity, and dew point
struct AtmosphericPanel: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "barometer")
                    .foregroundStyle(.purple)
                Text("Atmospheric")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            // Pressure with trend
            if let pressure = observation.baromRelIn {
                HStack(spacing: 6) {
                    Image(systemName: manager.pressureTrend.iconName)
                        .font(.caption)
                        .foregroundStyle(pressureTrendColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pressure")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Text(formatPressure(pressure))
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(manager.pressureTrend.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(pressureTrendColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(pressureTrendColor.opacity(0.15), in: Capsule())
                }
            }

            Divider().opacity(0.2)

            // Humidity
            if let humidity = observation.humidity {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Humidity")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("\(humidity)%")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    // Humidity bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(humidityColor(humidity))
                                .frame(width: geometry.size.width * CGFloat(humidity) / 100)
                        }
                    }
                    .frame(width: 80, height: 6)
                }
            }

            // Dew point
            if let dewPoint = observation.dewPoint {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dew Point")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        Text(formatTemp(dewPoint))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func formatPressure(_ inHg: Double) -> String {
        if isMetric {
            return String(format: "%.1f hPa", inHg * 33.8639)
        }
        return String(format: "%.2f inHg", inHg)
    }

    private func formatTemp(_ temp: Double) -> String {
        let display = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
        return String(format: "%.0f°", display)
    }

    private var pressureTrendColor: Color {
        switch manager.pressureTrend {
        case .rising: .green
        case .falling: .orange
        case .steady: .blue
        }
    }

    private func humidityColor(_ value: Int) -> Color {
        switch value {
        case 0..<30: .orange
        case 30..<60: .green
        case 60..<80: .cyan
        default: .blue
        }
    }
}
