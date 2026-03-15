//
//  SettingsView.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case display = "Display"
    case sensors = "Sensors"
    case alerts = "Alerts"
    case connection = "Connection"
    case general = "General"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .display: "menubar.rectangle"
        case .sensors: "sensor"
        case .alerts: "bell.badge"
        case .connection: "wifi"
        case .general: "gear"
        }
    }

    var accent: Color {
        switch self {
        case .display: .cyan
        case .sensors: .green
        case .alerts: .orange
        case .connection: .blue
        case .general: .purple
        }
    }

    var subtitle: String {
        switch self {
        case .display: "Units, menubar & quick stats"
        case .sensors: "Live sensor readings"
        case .alerts: "Notification thresholds"
        case .connection: "API keys & station"
        case .general: "Startup & about"
        }
    }
}

struct SettingsView: View {
    @State private var selectedPane: SettingsPane = .display

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(SettingsPane.allCases, selection: $selectedPane) { pane in
                    HStack(spacing: 10) {
                        Image(systemName: pane.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selectedPane == pane ? .white : pane.accent)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedPane == pane ? pane.accent : pane.accent.opacity(0.15))
                            )

                        Text(pane.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .tag(pane)
                }

                // Branded footer
                Divider()
                HStack(spacing: 6) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    Text("Porch")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .padding(.vertical, 8)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 210)
        } detail: {
            VStack(spacing: 0) {
                // Themed pane header
                paneHeader

                Divider()

                // Pane content
                detailView
            }
        }
        .preferredColorScheme(.dark)
        .frame(width: 640, height: 460)
    }

    // MARK: - Pane Header

    private var paneHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: selectedPane.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(selectedPane.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedPane.rawValue)
                    .font(.title3.weight(.semibold))
                Text(selectedPane.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailView: some View {
        switch selectedPane {
        case .display:
            DisplaySettingsTab()
        case .sensors:
            SensorsSettingsTab()
        case .alerts:
            AlertsSettingsTab()
        case .connection:
            ConnectionSettingsTab()
        case .general:
            GeneralSettingsTab()
        }
    }
}
