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
import PorchStationKit

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

    // Manual source preference (when Auto is off)
    @State private var manualSource: DataSourceMode = .ecowittLocal

    // Network scanner
    @StateObject private var scanner = EcowittScanner()

    // Location helper
    @StateObject private var locationHelper = LocationHelper()

    /// Whether the selected brand is one of the original two with full support
    private var isLegacyBrand: Bool {
        manager.selectedBrand == .ecowitt || manager.selectedBrand == .ambient
    }

    var body: some View {
        Form {
            // MARK: - Station Brand Picker

            Section("Station Brand") {
                Picker("Brand", selection: $manager.selectedBrand) {
                    ForEach(StationRegistry.shared.availableBrands) { brand in
                        Text(brand.displayName).tag(brand)
                    }
                }
                .onChange(of: manager.selectedBrand) {
                    // Sync DataSourceMode for legacy brands
                    switch manager.selectedBrand {
                    case .ecowitt:
                        if manager.dataSourceMode == .ambientCloud {
                            manager.dataSourceMode = .ecowittLocal
                        }
                        manualSource = .ecowittLocal
                    case .ambient:
                        if manager.dataSourceMode == .ecowittLocal {
                            manager.dataSourceMode = .ambientCloud
                        }
                        manualSource = .ambientCloud
                    default:
                        break
                    }
                }
            }

            // MARK: - Legacy Brand Configuration

            if isLegacyBrand {
                legacyDataSourceSection
            }

            // MARK: - Source Configuration

            if manager.selectedBrand == .ecowitt || (isLegacyBrand && manager.dataSourceMode == .auto) {
                ecowittSection
            }
            if manager.selectedBrand == .ambient || (isLegacyBrand && manager.dataSourceMode == .auto) {
                ambientSection
            }

            // MARK: - Generic Brand Configuration

            if !isLegacyBrand {
                genericBrandSection
            }

            // MARK: - Connection Controls (shared)

            connectionSection

            // MARK: - Discovered Station Info

            if manager.weatherData != nil {
                Section("Connected Station") {
                    LabeledContent("Name", value: manager.stationName)
                    LabeledContent("Location", value: manager.stationLocation)
                    LabeledContent("Station ID", value: manager.weatherData?.stationID ?? "--")

                    LabeledContent("Active Sensors", value: "\(manager.activeSensorCount)")

                    if manager.dataSourceMode == .auto {
                        LabeledContent("Source", value: "via \(manager.activeDataSource.rawValue)")
                    }
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
            if manager.dataSourceMode != .auto {
                manualSource = manager.dataSourceMode
            }
        }
    }

    // MARK: - Legacy Data Source Toggle (Ecowitt/Ambient only)

    private var legacyDataSourceSection: some View {
        Section("Data Source") {
            Picker("Source", selection: $manualSource) {
                Text("Ecowitt (Local)").tag(DataSourceMode.ecowittLocal)
                Text("Ambient Weather").tag(DataSourceMode.ambientCloud)
            }
            .pickerStyle(.segmented)
            .disabled(manager.dataSourceMode == .auto)
            .onChange(of: manualSource) {
                if manager.dataSourceMode != .auto {
                    manager.dataSourceMode = manualSource
                    // Sync brand selection
                    manager.selectedBrand = manualSource == .ecowittLocal ? .ecowitt : .ambient
                }
            }

            Toggle(isOn: Binding(
                get: { manager.dataSourceMode == .auto },
                set: { isAuto in
                    manager.dataSourceMode = isAuto ? .auto : manualSource
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto (Local Priority)")
                    Text("Use local gateway when home, cloud API when away")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(!manager.isAutoAvailable)
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
                            locationHelper.isFetching ? "Locating..." : "Use Current Location",
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

    // MARK: - Generic Brand Configuration (for new brands)

    private var genericBrandSection: some View {
        let brand = manager.selectedBrand
        let connType = brand.supportedConnectionTypes.first ?? .cloud
        let fields = StationRegistry.shared.configurationFields(brand: brand, connectionType: connType)

        return Section("\(brand.displayName) Configuration") {
            if fields.isEmpty {
                Text("No configuration needed")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(fields) { field in
                    let binding = Binding<String>(
                        get: { manager.brandConfigValues[field.id] ?? "" },
                        set: { manager.brandConfigValues[field.id] = $0 }
                    )

                    if field.isSecure {
                        SecureField(field.label, text: binding, prompt: Text(field.placeholder))
                            .textFieldStyle(.roundedBorder)
                    } else {
                        TextField(field.label, text: binding, prompt: Text(field.placeholder))
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            Label("Support for \(brand.displayName) is coming in a future update.", systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                    Label(connectButtonLabel, systemImage: connectButtonIcon)
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

                    if manager.dataSourceMode == .auto && manager.connectionStatus == .connected {
                        Text("via \(manager.activeDataSource.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
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

    private var connectButtonLabel: String {
        if !isLegacyBrand {
            return "Connect to \(manager.selectedBrand.displayName)"
        }
        switch manager.dataSourceMode {
        case .ambientCloud: return "Search for Stations"
        case .ecowittLocal: return "Connect to Gateway"
        case .auto: return "Auto Connect"
        }
    }

    private var connectButtonIcon: String {
        if !isLegacyBrand {
            return "antenna.radiowaves.left.and.right"
        }
        switch manager.dataSourceMode {
        case .ambientCloud: return "antenna.radiowaves.left.and.right"
        case .ecowittLocal: return "wifi.router"
        case .auto: return "arrow.triangle.2.circlepath"
        }
    }

    private var isConnectDisabled: Bool {
        if !isLegacyBrand {
            // For new brands, check that at least one required field is filled
            let brand = manager.selectedBrand
            let connType = brand.supportedConnectionTypes.first ?? .cloud
            let fields = StationRegistry.shared.configurationFields(brand: brand, connectionType: connType)
            let requiredFields = fields.filter(\.isRequired)
            return requiredFields.contains { field in
                (manager.brandConfigValues[field.id] ?? "").isEmpty
            }
        }
        switch manager.dataSourceMode {
        case .ambientCloud:
            return appKeyInput.isEmpty || apiKeyInput.isEmpty
        case .ecowittLocal:
            return ecowittHostInput.isEmpty
        case .auto:
            return ecowittHostInput.isEmpty || appKeyInput.isEmpty || apiKeyInput.isEmpty
        }
    }

    /// Push local state into the manager before connecting
    private func applyInputs() {
        manager.applicationKey = appKeyInput
        manager.apiKeysRaw = apiKeyInput
        manager.ecowittHost = ecowittHostInput
        manager.ecowittPort = Int(ecowittPortInput) ?? 80
        manager.ecowittStationName = ecowittStationNameInput
        manager.manualLatitude = latitudeInput
        manager.manualLongitude = longitudeInput
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
