//
//  ConnectionSettingsTab.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import Combine
import AmbientWeather
import CoreLocation

/// One-shot location helper using CLLocationManager
private class LocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isFetching = false
    @Published var errorMessage: String?

    private let locationManager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation(completion: @escaping (CLLocationCoordinate2D) -> Void) {
        self.completion = completion
        errorMessage = nil
        isFetching = true
        locationManager.requestLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coord = location.coordinate
        Task { @MainActor in
            self.completion?(coord)
            self.completion = nil
            self.isFetching = false
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
            self.completion = nil
            self.isFetching = false
        }
    }
}

struct ConnectionSettingsTab: View {
    @EnvironmentObject var manager: WeatherManager
    @State private var appKeyInput: String = ""
    @State private var apiKeyInput: String = ""
    @State private var showingKeyHelp = false

    // Ecowitt local fields
    @State private var ecowittHostInput: String = ""
    @State private var ecowittPortInput: String = "80"
    @State private var ecowittStationNameInput: String = ""
    @State private var latitudeInput: String = ""
    @State private var longitudeInput: String = ""

    // Network scanner
    @StateObject private var scanner = EcowittScanner()

    // Location helper
    @StateObject private var locationHelper = LocationHelper()

    var body: some View {
        Form {
            // MARK: - Data Source Picker

            Section("Data Source") {
                Picker("Source", selection: $manager.dataSourceMode) {
                    ForEach(DataSourceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: manager.dataSourceMode) {
                    manager.disconnect()
                }
            }

            // MARK: - Source-Specific Configuration

            if manager.dataSourceMode == .ambientCloud {
                ambientSection
            } else {
                ecowittSection
            }

            // MARK: - Connection Controls (shared)

            connectionSection

            // MARK: - Discovered Station Info

            if manager.weatherData != nil && manager.dataSourceMode == .ambientCloud {
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
            ecowittHostInput = manager.ecowittHost
            ecowittPortInput = "\(manager.ecowittPort)"
            ecowittStationNameInput = manager.ecowittStationName
            latitudeInput = manager.manualLatitude
            longitudeInput = manager.manualLongitude
        }
    }

    // MARK: - Ambient Weather Section

    private var ambientSection: some View {
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
    }

    // MARK: - Ecowitt Local Section

    private var ecowittSection: some View {
        Group {
            Section("Ecowitt Gateway") {
                TextField("Station Name", text: $ecowittStationNameInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: ecowittStationNameInput) {
                        manager.ecowittStationName = ecowittStationNameInput
                    }
                TextField("IP Address", text: $ecowittHostInput)
                    .textFieldStyle(.roundedBorder)
                TextField("Port", text: $ecowittPortInput)
                    .textFieldStyle(.roundedBorder)

                // Network scan button and results
                HStack {
                    Button {
                        if scanner.isScanning {
                            scanner.stopScan()
                        } else {
                            scanner.startScan()
                        }
                    } label: {
                        Label(
                            scanner.isScanning ? "Stop Scan" : "Scan Network",
                            systemImage: scanner.isScanning ? "stop.circle" : "wifi.router"
                        )
                    }
                    .buttonStyle(.glass)

                    if scanner.isScanning {
                        ProgressView(value: scanner.scanProgress)
                            .frame(width: 100)
                        Text("\(Int(scanner.scanProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Spacer()
                }

                if !scanner.discoveredGateways.isEmpty {
                    ForEach(scanner.discoveredGateways) { gateway in
                        Button {
                            ecowittHostInput = gateway.host
                            ecowittPortInput = "\(gateway.port)"
                        } label: {
                            HStack {
                                Image(systemName: "wifi.router")
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading) {
                                    Text(gateway.model)
                                        .font(.body)
                                    Text(gateway.host)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if ecowittHostInput == gateway.host {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } else if !scanner.isScanning && scanner.scanProgress >= 1.0 {
                    Text("No Ecowitt gateways found on local network")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Station Location") {
                TextField("Latitude", text: $latitudeInput)
                    .textFieldStyle(.roundedBorder)
                TextField("Longitude", text: $longitudeInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button {
                        locationHelper.requestLocation { coord in
                            latitudeInput = String(format: "%.6f", coord.latitude)
                            longitudeInput = String(format: "%.6f", coord.longitude)
                            manager.manualLatitude = latitudeInput
                            manager.manualLongitude = longitudeInput
                        }
                    } label: {
                        Label(
                            locationHelper.isFetching ? "Locating…" : "Use Current Location",
                            systemImage: "location.fill"
                        )
                    }
                    .buttonStyle(.glass)
                    .disabled(locationHelper.isFetching)

                    if locationHelper.isFetching {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()
                }

                if let error = locationHelper.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text("Required for weather forecasts and severe weather alerts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Connection Section (shared)

    private var connectionSection: some View {
        Section("Connection") {
            HStack {
                Button {
                    applyInputs()
                    manager.connect()
                } label: {
                    Label(
                        manager.dataSourceMode == .ambientCloud ? "Search for Stations" : "Connect to Gateway",
                        systemImage: manager.dataSourceMode == .ambientCloud ? "antenna.radiowaves.left.and.right" : "wifi.router"
                    )
                }
                .buttonStyle(.glass)
                .disabled(isConnectDisabled)

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
    }

    // MARK: - Helpers

    private var isConnectDisabled: Bool {
        switch manager.dataSourceMode {
        case .ambientCloud:
            return appKeyInput.isEmpty || apiKeyInput.isEmpty
        case .ecowittLocal:
            return ecowittHostInput.isEmpty
        }
    }

    /// Push local state into the manager before connecting
    private func applyInputs() {
        switch manager.dataSourceMode {
        case .ambientCloud:
            manager.applicationKey = appKeyInput
            manager.apiKeysRaw = apiKeyInput
        case .ecowittLocal:
            manager.ecowittHost = ecowittHostInput
            manager.ecowittPort = Int(ecowittPortInput) ?? 80
            manager.ecowittStationName = ecowittStationNameInput
            manager.manualLatitude = latitudeInput
            manager.manualLongitude = longitudeInput
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
