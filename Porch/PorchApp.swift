//
//  PorchApp.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import SwiftData
import AmbientWeather

@main
struct PorchApp: App {
    @StateObject private var weatherManager = WeatherManager()
    private let appUpdater = AppUpdater()
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: WeatherSnapshot.self)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        let _ = setupHistoryManager()

        MenuBarExtra {
            MenuBarPopoverView()
                .environmentObject(weatherManager)
                .modelContainer(modelContainer)
        } label: {
            MenuBarLabel(manager: weatherManager)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("Weather Station", id: "weather-station") {
            WeatherStationView()
                .environmentObject(weatherManager)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 1280, height: 900)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(weatherManager)
                .environmentObject(appUpdater)
        }
        .defaultSize(width: 640, height: 460)
    }

    @discardableResult
    private func setupHistoryManager() -> Bool {
        if weatherManager.historyManager == nil {
            weatherManager.historyManager = HistoryManager(modelContainer: modelContainer)
        }
        return true
    }
}

/// Dedicated view for the menubar label.
struct MenuBarLabel: View {
    @ObservedObject var manager: WeatherManager

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: manager.menuBarIcon)
            Text(manager.menuBarLabel)
        }
    }
}
