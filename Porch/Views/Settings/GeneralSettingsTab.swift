//
//  GeneralSettingsTab.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import ServiceManagement

struct GeneralSettingsTab: View {
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
                HStack(spacing: 14) {
                    Image(systemName: "cloud.sun.rain.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.cyan, .orange, .blue)
                        .symbolRenderingMode(.hierarchical)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Porch")
                            .font(.title3.weight(.semibold))
                        HStack(spacing: 8) {
                            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")")
                                .font(.caption)
                                .foregroundStyle(.quaternary)
                        }
                    }
                }
                .padding(.vertical, 4)

                Link(destination: URL(string: "https://ambientweather.net")!) {
                    Label("Ambient Weather Dashboard", systemImage: "globe")
                }
                .buttonStyle(.glass)
            } header: {
                Label("About", systemImage: "info.circle")
                    .foregroundStyle(.purple)
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
