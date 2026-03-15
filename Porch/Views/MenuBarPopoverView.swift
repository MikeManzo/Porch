//
//  MenuBarPopoverView.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather

struct MenuBarPopoverView: View {
    @EnvironmentObject var manager: WeatherManager
    @State private var showAllSensors = false

    var body: some View {
        VStack(spacing: 0) {
            if let data = manager.weatherData {
                connectedContent(data: data)
            } else {
                emptyStateView
            }

            Divider()

            footerView
        }
        .frame(width: 340)
    }

    // MARK: - Connected Content

    @ViewBuilder
    private func connectedContent(data: AmbientWeatherData) -> some View {
        // Station header with optional multi-station picker
        StationHeaderView(
            stationName: data.info.name,
            stationLocation: data.info.coords.location,
            status: manager.connectionStatus
        )

        // Multi-station picker
        if manager.hasMultipleStations {
            stationPicker
        }

        // Low battery warning
        if !manager.lowBatterySensors.isEmpty {
            BatteryWarningBanner(lowSensors: manager.lowBatterySensors)
                .padding(.top, 4)
        }

        // Hero temperature display
        WeatherHeroView(observation: data.observation)

        // Daily extremes (high/low/gust)
        DailyExtremesView()

        // Quick stats bar with Liquid Glass
        QuickStatsBar(observation: data.observation)

        Divider()
            .padding(.top, 8)

        // Scrollable conditions + rain summary + garden + full sensor list
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Common conditions grid
                ConditionsGridView(observation: data.observation)

                // Rain totals summary
                RainSummaryView(observation: data.observation)

                // Garden & soil section (conditional)
                GardenSectionView(observation: data.observation)

                // Expandable full sensor list
                DisclosureGroup(isExpanded: $showAllSensors) {
                    SensorDashboardView(observation: data.observation)
                        .padding(.top, 4)
                } label: {
                    Label("All Sensors", systemImage: "sensor")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 400)
    }

    // MARK: - Multi-Station Picker

    private var stationPicker: some View {
        Picker("Station", selection: Binding(
            get: { manager.selectedStationID ?? "" },
            set: { manager.selectStation($0) }
        )) {
            ForEach(Array(manager.allStations.keys.sorted()), id: \.self) { stationID in
                Text(manager.allStations[stationID]?.info.name ?? stationID)
                    .tag(stationID)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            Text(statusMessage)
                .font(.headline)

            if !manager.isConfigured {
                Text("Open Settings to add your API keys.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if manager.connectionStatus == .connecting {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var statusMessage: String {
        switch manager.connectionStatus {
        case .connected:    "Waiting for data..."
        case .connecting:   "Connecting..."
        case .disconnected: manager.isConfigured ? "Disconnected" : "Not Configured"
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            SettingsLink {
                Label("Settings", systemImage: "gear")
            }
            .buttonStyle(.borderless)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit Porch", systemImage: "power")
            }
            .buttonStyle(.borderless)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
