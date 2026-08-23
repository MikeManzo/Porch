//
//  MenuBarPopoverView.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

struct MenuBarPopoverView: View {
    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var appUpdater: AppUpdater
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
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
        .frame(width: 290)
    }

    // MARK:  Connected Content

    @ViewBuilder
    private func connectedContent(data: AmbientWeatherData) -> some View {
        // Station header with optional multi-station picker
        StationHeaderView(
            stationName: data.info.name,
            stationLocation: manager.stationLocation,
            status: manager.connectionStatus,
            activeSource: manager.activeDataSource
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

        // Severe weather alerts
        if !manager.activeWeatherAlerts.isEmpty {
            SevereWeatherBanner(alerts: manager.activeWeatherAlerts)
                .padding(.top, 4)
        }

        // Hero temperature display
        if let porchData = manager.porchWeatherData {
            WeatherHeroView(porchData: porchData)
        } else {
            WeatherHeroView(porchData: makeFallbackPorchData(from: data))
        }

        // Daily extremes (high/low/gust)
        DailyExtremesView()

        // Quick stats bar with Liquid Glass
        if let porchData = manager.porchWeatherData {
            QuickStatsBar(porchData: porchData)
        } else {
            QuickStatsBar(observation: data.observation)
        }

        // Station-specific sensors surfaced above the fold — indoor climate, soil,
        // lightning, air quality. This is what differentiates Porch from a generic
        // weather app, so it shouldn't be hidden behind "All Sensors".
        StationPulseView(porchData: manager.porchWeatherData ?? makeFallbackPorchData(from: data))
            .padding(.top, 8)

        Divider()
            .padding(.top, 8)

        // Scrollable conditions + rain summary + garden + full sensor list
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Common conditions grid
                if let porchData = manager.porchWeatherData {
                    ConditionsGridView(porchData: porchData)
                } else {
                    ConditionsGridView(observation: data.observation)
                }

                // Rain totals summary
                if let porchData = manager.porchWeatherData {
                    RainSummaryView(porchData: porchData)
                } else {
                    RainSummaryView(observation: data.observation)
                }

                // Garden & soil section (conditional)
                if let porchData = manager.porchWeatherData {
                    GardenSectionView(porchData: porchData)
                } else {
                    GardenSectionView(observation: data.observation)
                }

                // Expandable full sensor list
                DisclosureGroup(isExpanded: $showAllSensors) {
                    if let porchData = manager.porchWeatherData {
                        SensorDashboardView(porchData: porchData)
                            .padding(.top, 4)
                    } else {
                        SensorDashboardView(observation: data.observation)
                            .padding(.top, 4)
                    }
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

    // MARK:  Multi-Station Picker

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

    // MARK:  Empty State

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

    // MARK:  Footer

    private var footerView: some View {
        HStack {
            Spacer(minLength: 0)

            GlassEffectContainer(spacing: 4) {
                HStack(spacing: 4) {
                    footerButton(icon: "gear", help: "Settings") {
                        NSApp.keyWindow?.close()
                        openSettings()
                        NSApp.activate(ignoringOtherApps: true)
                    }

                    footerButton(icon: "gauge.with.dots.needle.67percent", help: "Weather Station", disabled: manager.weatherData == nil) {
                        NSApp.keyWindow?.close()
                        // Focus existing station window or open a new one
                        if let existing = NSApp.windows.first(where: { $0.title == "Weather Station" }) {
                            existing.makeKeyAndOrderFront(nil)
                        } else {
                            openWindow(id: "weather-station")
                        }
                        NSApp.activate(ignoringOtherApps: true)
                    }

                    if appUpdater.updateAvailable {
                        footerButton(icon: "arrow.down.circle.fill", help: "Update Available", tint: .green) {
                            NSApp.keyWindow?.close()
                            appUpdater.checkForUpdates()
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }

                    footerButton(icon: "power", help: "Quit Porch") {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding(4)
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func footerButton(
        icon: String,
        help: String,
        tint: Color = .primary,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(help)
    }

    // MARK:  Fallback

    /// Creates a minimal PorchWeatherData from AmbientWeatherData when no porchWeatherData exists
    private func makeFallbackPorchData(from data: AmbientWeatherData) -> PorchWeatherData {
        var porch = PorchWeatherData(
            stationID: manager.weatherData?.stationID ?? "--",
            stationName: data.info.name,
            brand: .ambient,
            timestamp: Date()
        )
        porch.temperatureF = data.observation.tempF
        porch.feelsLikeF = data.observation.feelsLike
        porch.humidity = data.observation.humidity
        return porch
    }
}
// MARK:  Preview

#if DEBUG
#Preview("Connected") {
    MenuBarPopoverView()
        .environmentObject(WeatherManager.preview())
        .environmentObject(AppUpdater())
        .environmentObject(ForecastManager())
}

#Preview("Disconnected") {
    MenuBarPopoverView()
        .environmentObject(WeatherManager())
        .environmentObject(AppUpdater())
        .environmentObject(ForecastManager())
}
#endif

