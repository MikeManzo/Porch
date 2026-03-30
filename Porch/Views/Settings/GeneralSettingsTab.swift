//
//  GeneralSettingsTab.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import ServiceManagement
import Sparkle

struct GeneralSettingsTab: View {
    @EnvironmentObject var appUpdater: AppUpdater
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $launchAtLogin) {
                    Label("Launch at Login", systemImage: "sunrise.fill")
                }
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
            } header: {
                Label("Startup", systemImage: "power")
                    .foregroundStyle(.purple)
            }

            Section {
                if appUpdater.updateAvailable {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Update Available")
                                .font(.subheadline.weight(.semibold))
                            Text("A new version of Porch is ready to install.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Install Update") {
                            appUpdater.checkForUpdates()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(.vertical, 4)
                }

                Button {
                    appUpdater.checkForUpdates()
                } label: {
                    Label("Check for Updates…", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(!appUpdater.canCheckForUpdates)

                Toggle(isOn: Binding(
                    get: { appUpdater.updater.automaticallyChecksForUpdates },
                    set: { appUpdater.updater.automaticallyChecksForUpdates = $0 }
                )) {
                    Label("Automatically check for updates", systemImage: "clock.arrow.2.circlepath")
                }

                Toggle(isOn: Binding(
                    get: { appUpdater.updater.automaticallyDownloadsUpdates },
                    set: { appUpdater.updater.automaticallyDownloadsUpdates = $0 }
                )) {
                    Label("Automatically download updates", systemImage: "arrow.down.circle")
                }
            } header: {
                Label("Software Update", systemImage: "arrow.uturn.down.circle")
                    .foregroundStyle(.blue)
            }
        }
        .formStyle(.grouped)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = !enabled  // Revert on failure
        }
    }
}
