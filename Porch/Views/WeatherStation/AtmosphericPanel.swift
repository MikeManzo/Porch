//
//  AtmosphericPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Panel displaying pressure, humidity, and dew point
struct AtmosphericPanel: View {
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?
    @EnvironmentObject var manager: WeatherManager
    @State private var showAbsolute = false

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

    private var relPressure: Double? { porchData?.pressureRelativeInHg ?? observation?.baromRelIn }
    private var absPressure: Double? { porchData?.pressureAbsoluteInHg ?? observation?.baromAbsIn }
    private var humidityVal: Int? { porchData?.humidity ?? observation?.humidity }
    private var dewPointVal: Double? { porchData?.dewPointF ?? observation?.dewPoint }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "barometer")
                    .foregroundStyle(.purple)
                Text("Atmospheric")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            if let relPressure {
                let displayPressure = showAbsolute ? (absPressure ?? relPressure) : relPressure

                HStack(spacing: 6) {
                    Image(systemName: manager.pressureTrend.icon)
                        .font(.caption)
                        .foregroundStyle(pressureTrendColor)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(showAbsolute ? "Absolute" : "Relative")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                            if absPressure != nil {
                                Button {
                                    showAbsolute.toggle()
                                } label: {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(formatPressure(displayPressure))
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

            if let humidity = humidityVal {
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
                    GeometryReader { geometry in
                        let fillWidth = geometry.size.width * CGFloat(humidity) / 100
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .green, .yellow, .orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: fillWidth)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 8)
                }
            }

            if let dewPoint = dewPointVal {
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
}
