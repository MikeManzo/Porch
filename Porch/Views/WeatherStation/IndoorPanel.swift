//
//  IndoorPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather

/// Panel displaying indoor temperature, humidity, and related readings
struct IndoorPanel: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    /// Only show this panel when indoor sensor data exists
    var hasData: Bool {
        observation.tempInF != nil || observation.humidityIn != nil
    }

    var body: some View {
        if hasData {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(.green)
                    Text("Indoor")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }

                HStack(spacing: 16) {
                    if let temp = observation.tempInF {
                        statView(
                            icon: "thermometer.medium",
                            label: "Temperature",
                            value: formatTemp(temp),
                            tint: .orange
                        )
                    }
                    if let humidity = observation.humidityIn {
                        statView(
                            icon: "humidity",
                            label: "Humidity",
                            value: "\(humidity)%",
                            tint: .cyan
                        )
                    }
                }

                if let feelsLike = observation.feelsLikeIn {
                    HStack(spacing: 16) {
                        statView(
                            icon: "person.and.background.dotted",
                            label: "Feels Like",
                            value: formatTemp(feelsLike),
                            tint: .orange
                        )
                        if let dewPoint = observation.dewPointIn {
                            statView(
                                icon: "drop.degreesign",
                                label: "Dew Point",
                                value: formatTemp(dewPoint),
                                tint: .blue
                            )
                        }
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }

    // MARK: - Helpers

    private func statView(icon: String, label: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text(value)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatTemp(_ temp: Double) -> String {
        let display = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
        return String(format: "%.0f°", display)
    }
}
