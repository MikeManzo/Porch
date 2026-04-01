//
//  IndoorPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Panel displaying indoor temperature, humidity, and related readings
struct IndoorPanel: View {
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

    private var indoorTemp: Double? { porchData?.indoorTempF ?? observation?.tempInF }
    private var indoorHumidity: Int? { porchData?.indoorHumidity ?? observation?.humidityIn }
    // feelsLikeIn and dewPointIn are Ambient-only
    private var feelsLikeIn: Double? { observation?.feelsLikeIn }
    private var dewPointIn: Double? { observation?.dewPointIn }

    var hasData: Bool {
        indoorTemp != nil || indoorHumidity != nil
    }

    var body: some View {
        if hasData {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(.green)
                    Text("Indoor")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }

                HStack(spacing: 16) {
                    if let temp = indoorTemp {
                        statView(icon: "thermometer.medium", label: "Temperature", value: formatTemp(temp), tint: .orange)
                    }
                    if let humidity = indoorHumidity {
                        statView(icon: "humidity", label: "Humidity", value: "\(humidity)%", tint: .cyan)
                    }
                }

                if let feelsLike = feelsLikeIn {
                    HStack(spacing: 16) {
                        statView(icon: "person.and.background.dotted", label: "Feels Like", value: formatTemp(feelsLike), tint: .orange)
                        if let dewPoint = dewPointIn {
                            statView(icon: "drop.degreesign", label: "Dew Point", value: formatTemp(dewPoint), tint: .blue)
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
