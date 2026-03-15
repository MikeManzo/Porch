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

    var body: some View {
        Form {
            Section("Ambient Weather Credentials") {
                TextField("Application Key", text: $appKeyInput)
                    .textFieldStyle(.roundedBorder)

                TextField("API Key", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)

                Text("Get your keys from [ambientweather.net/account](https://ambientweather.net/account)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Connection") {
                HStack {
                    Button("Search for Stations") {
                        manager.applicationKey = appKeyInput
                        manager.apiKeysRaw = apiKeyInput
                        manager.connect()
                    }
                    .disabled(appKeyInput.isEmpty || apiKeyInput.isEmpty)

                    Button("Disconnect") {
                        manager.disconnect()
                    }
                    .disabled(manager.connectionStatus == .disconnected)

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(manager.connectionStatus.rawValue.capitalized)
                            .font(.caption)
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

    private var statusColor: Color {
        switch manager.connectionStatus {
        case .connected:    return .green
        case .connecting:   return .orange
        case .disconnected: return .red
        }
    }
}
