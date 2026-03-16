//
//  ConnectionSettingsTab.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather

struct ConnectionSettingsTab: View {
    @EnvironmentObject var manager: WeatherManager
    @State private var appKeyInput: String = ""
    @State private var apiKeyInput: String = ""
    @State private var showingKeyHelp = false

    var body: some View {
        Form {
            Section {
                TextField("Application Key", text: $appKeyInput)
                    .textFieldStyle(.roundedBorder)

                TextField("API Key", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Text("Get your keys from [ambientweather.net/account](https://ambientweather.net/account)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        showingKeyHelp = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                    .popover(isPresented: $showingKeyHelp, arrowEdge: .trailing) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Getting Your API Keys")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 6) {
                                stepRow(1, "Go to **ambientweather.net** and sign in")
                                stepRow(2, "Click your profile name → **Account**")
                                stepRow(3, "Under **API Keys**, click **Create API Key**")
                                stepRow(4, "Copy the key and paste it into **API Key** above")
                                stepRow(5, "Under **Application Keys**, click **Create Application Key**")
                                stepRow(6, "Copy the key and paste it into **Application Key** above")
                            }
                            .font(.callout)
                        }
                        .padding(16)
                        .frame(width: 420)
                    }
                }
            } header: {
                Text("Ambient Weather Credentials")
            }

            Section("Connection") {
                HStack {
                    Button {
                        manager.applicationKey = appKeyInput
                        manager.apiKeysRaw = apiKeyInput
                        manager.connect()
                    } label: {
                        Label("Search for Stations", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .buttonStyle(.glass)
                    .disabled(appKeyInput.isEmpty || apiKeyInput.isEmpty)

                    Button {
                        manager.disconnect()
                    } label: {
                        Label("Disconnect", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.glass)
                    .disabled(manager.connectionStatus == .disconnected)

                    Spacer()

                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)
                            .shadow(color: statusColor.opacity(0.6), radius: manager.connectionStatus == .connecting ? 6 : 0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: manager.connectionStatus == .connecting)
                        Text(manager.connectionStatus.rawValue.capitalized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = manager.connectionError {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if manager.weatherData != nil {
                Section("Discovered Station") {
                    LabeledContent("Name", value: manager.stationName)
                    LabeledContent("Location", value: manager.stationLocation)
                    LabeledContent("Station ID", value: manager.weatherData?.stationID ?? "--")

                    let sensorCount = manager.sensorsByCategory
                        .flatMap(\.1)
                        .count
                    LabeledContent("Active Sensors", value: "\(sensorCount)")
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            appKeyInput = manager.applicationKey
            apiKeyInput = manager.apiKeysRaw
        }
    }

    private func stepRow(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)
            Text(text)
                .foregroundStyle(.primary)
        }
    }

    private var statusColor: Color {
        switch manager.connectionStatus {
        case .connected:    return .green
        case .connecting:   return .orange
        case .disconnected: return .red
        }
    }
}
