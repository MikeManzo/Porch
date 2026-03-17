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
    @State private var historySnapshots: [WeatherSnapshot] = []
    @State private var chartTimeRange: ChartTimeRange = .day

    enum ChartTimeRange: String, CaseIterable {
        case day = "24H"
        case threeDays = "3D"
        case week = "7D"
    }

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
        .onAppear { loadHistory() }
        .onChange(of: chartTimeRange) { loadHistory() }
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
            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 16) {
                    // Top bar
                    topBar(data: data)

                    // Main two-column layout
                    HStack(alignment: .top, spacing: 16) {
                        // Left column (flexible width)
                        VStack(spacing: 16) {
                            CurrentConditionsPanel(observation: data.observation)

                            HStack(alignment: .top, spacing: 16) {
                                AtmosphericPanel(observation: data.observation)
                                PrecipitationPanel(observation: data.observation)
                            }

                            // Temperature trend chart
                            TrendChartView(
                                title: "Temperature",
                                icon: "thermometer.medium",
                                snapshots: historySnapshots,
                                valuePath: \.temperature,
                                unitSuffix: manager.unitSystem == .metric ? "C" : "F",
                                color: .orange,
                                unitSystem: manager.unitSystem,
                                convertToMetric: { ($0 - 32) * 5.0 / 9.0 }
                            )

                            // Pressure trend chart
                            TrendChartView(
                                title: "Pressure",
                                icon: "barometer",
                                snapshots: historySnapshots,
                                valuePath: \.pressure,
                                unitSuffix: manager.unitSystem == .metric ? " hPa" : " inHg",
                                color: .purple,
                                unitSystem: manager.unitSystem,
                                convertToMetric: { $0 * 33.8639 }
                            )
                        }
                        .frame(maxWidth: .infinity)

                        // Right column (fixed width)
                        VStack(spacing: 16) {
                            WindPanel(observation: data.observation)
                            EnvironmentPanel(observation: data.observation)
                            IndoorPanel(observation: data.observation)
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

            // Time range picker
            Picker("Range", selection: $chartTimeRange) {
                ForEach(ChartTimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

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

    // MARK: - History Loading

    private func loadHistory() {
        guard let stationID = manager.selectedStationID,
              let historyManager = manager.historyManager else { return }
        switch chartTimeRange {
        case .day:
            historySnapshots = historyManager.fetchSnapshots(for: stationID, lastHours: 24)
        case .threeDays:
            historySnapshots = historyManager.fetchSnapshots(for: stationID, lastDays: 3)
        case .week:
            historySnapshots = historyManager.fetchSnapshots(for: stationID, lastDays: 7)
        }
    }
}
