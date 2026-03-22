//
//  WeatherStationView.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import SwiftData
import AmbientWeather

/// Full weather station dashboard window with Liquid Glass panels
struct WeatherStationView: View {
    @EnvironmentObject var manager: WeatherManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Rich dark background for Liquid Glass
            backgroundGradient

            if let data = manager.weatherData {
                dashboardContent(data: data)
            } else {
                emptyState
            }
        }
        .frame(minWidth: 1100, minHeight: 780)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.04, green: 0.08, blue: 0.20),
                Color(red: 0.06, green: 0.06, blue: 0.18),
                Color(red: 0.03, green: 0.10, blue: 0.18),
                Color(red: 0.05, green: 0.07, blue: 0.22),
                Color(red: 0.04, green: 0.06, blue: 0.16),
                Color(red: 0.06, green: 0.04, blue: 0.14),
                Color(red: 0.04, green: 0.08, blue: 0.19),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private func dashboardContent(data: AmbientWeatherData) -> some View {
        ScrollView {
            GlassEffectContainer {
            VStack(spacing: 16) {
                // Top bar
                topBar(data: data)

                // Main two-column layout
                HStack (alignment: .top, spacing: 16) {
                    // Left column (flexible width)
                    VStack(spacing: 16) {
                            CurrentConditionsPanel(observation: data.observation)

                            HStack(alignment: .top, spacing: 16) {
                                AtmosphericPanel(observation: data.observation)
                                PrecipitationPanel(observation: data.observation)
                            }

                            // Temperature trend (outdoor + indoor overlay)
                            TrendChartView(
                                title: "Temperature",
                                icon: "thermometer.medium",
                                valuePath: \.temperature,
                                unitSuffix: manager.unitSystem == .metric ? "°C" : "°F",
                                color: .orange,
                                unitSystem: manager.unitSystem,
                                convertToMetric: { ($0 - 32) * 5.0 / 9.0 },
                                secondary: data.observation.tempInF != nil
                                    ? SecondarySeries(
                                        label: "Indoor",
                                        valuePath: \.indoorTemp,
                                        color: .green,
                                        convertToMetric: { ($0 - 32) * 5.0 / 9.0 }
                                    ) : nil
                            )

                            // Humidity trend (outdoor + indoor overlay)
                            TrendChartView(
                                title: "Humidity",
                                icon: "humidity",
                                valuePath: \.humidityDouble,
                                unitSuffix: "%",
                                color: .cyan,
                                unitSystem: manager.unitSystem,
                                secondary: data.observation.humidityIn != nil
                                    ? SecondarySeries(
                                        label: "Indoor",
                                        valuePath: \.indoorHumidityDouble,
                                        color: .green
                                    ) : nil
                            )

                            // Pressure trend
                            TrendChartView(
                                title: "Pressure",
                                icon: "barometer",
                                valuePath: \.pressure,
                                unitSuffix: manager.unitSystem == .metric ? " hPa" : " inHg",
                                color: .purple,
                                unitSystem: manager.unitSystem,
                                convertToMetric: { $0 * 33.8639 }
                            )

                            // Wind speed trend (with gust overlay)
                            TrendChartView(
                                title: "Wind Speed",
                                icon: "wind",
                                valuePath: \.windSpeed,
                                unitSuffix: manager.unitSystem == .metric ? " km/h" : " mph",
                                color: .cyan,
                                unitSystem: manager.unitSystem,
                                convertToMetric: { $0 * 1.60934 },
                                secondary: SecondarySeries(
                                    label: "Gust",
                                    valuePath: \.windGust,
                                    color: .orange,
                                    convertToMetric: { $0 * 1.60934 }
                                )
                            )

                            // Solar radiation & UV trend
                            if data.observation.solarRadiation != nil {
                                TrendChartView(
                                    title: "Solar & UV",
                                    icon: "sun.max.fill",
                                    valuePath: \.solarRadiation,
                                    unitSuffix: " W/m²",
                                    color: .yellow,
                                    unitSystem: manager.unitSystem,
                                    secondary: data.observation.uv != nil
                                        ? SecondarySeries(
                                            label: "UV",
                                            valuePath: \.uvDouble,
                                            color: .purple
                                        ) : nil
                                )
                            }

                            // Rain accumulation trend
                            if data.observation.dailyRainIn != nil {
                                TrendChartView(
                                    title: "Rain (Daily)",
                                    icon: "cloud.rain",
                                    valuePath: \.dailyRain,
                                    unitSuffix: manager.unitSystem == .metric ? " mm" : "\"",
                                    color: .blue,
                                    unitSystem: manager.unitSystem,
                                    convertToMetric: { $0 * 25.4 }
                                )
                            }

                            // PM2.5 air quality trend
                            if data.observation.pm25 != nil {
                                TrendChartView(
                                    title: "PM2.5 Air Quality",
                                    icon: "aqi.medium",
                                    valuePath: \.pm25,
                                    unitSuffix: " µg/m³",
                                    color: .green,
                                    unitSystem: manager.unitSystem
                                )
                            }

                            // Weekly extremes history
                            WeeklyExtremesPanel()
                        }
                    .frame(maxWidth: .infinity)

                    // Right column (fixed width)
                    VStack(spacing: 16) {
                        WindPanel(observation: data.observation)
                        WindRosePanel()
                        IndoorPanel(observation: data.observation)
                        EnvironmentPanel(observation: data.observation)
                        LeakDetectionPanel(observation: data.observation)
                        RelayStatusPanel(observation: data.observation)
                        GardenPanel(observation: data.observation)
                    }
                    .frame(width: 360)
                    }
                }
                .padding(24)
            }
        }
    }

    // MARK: - Top Bar

    private func topBar(data: AmbientWeatherData) -> some View {
        HStack {
            // Station info
            VStack(alignment: .leading, spacing: 2) {
                Text(data.info.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Updated \(data.observation.observationDateFormatted)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
                .symbolRenderingMode(.hierarchical)
            Text("Waiting for weather data…")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
