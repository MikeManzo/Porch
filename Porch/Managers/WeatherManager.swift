//
//  WeatherManager.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import Combine
import AmbientWeather
import UserNotifications
import WeatherKit
import CoreLocation

/// Central state manager that wraps AmbientWebSocket and manages user preferences
@MainActor
class WeatherManager: ObservableObject {

    // MARK: - Published WebSocket State

    @Published private(set) var connectionStatus: SocketStatus = .disconnected
    @Published private(set) var weatherData: AmbientWeatherData?
    @Published private(set) var connectionError: Error?

    // MARK: - Multi-Station Support

    /// All discovered stations keyed by stationID
    @Published private(set) var allStations: [String: AmbientWeatherData] = [:]

    /// Currently selected station ID
    @Published var selectedStationID: String? {
        didSet {
            if let id = selectedStationID {
                UserDefaults.standard.set(id, forKey: "selectedStationID")
                weatherData = allStations[id]
            }
        }
    }

    /// Whether multiple stations are available
    var hasMultipleStations: Bool { allStations.count > 1 }

    // MARK: - Pressure Trend

    @Published private(set) var pressureTrend: PressureTrend = .steady
    private var previousPressure: Double?

    enum PressureTrend: String {
        case rising, falling, steady

        var icon: String {
            switch self {
            case .rising: return "arrow.up"
            case .falling: return "arrow.down"
            case .steady: return "arrow.forward"
            }
        }
    }

    // MARK: - Daily Extremes

    @Published private(set) var dailyHighTemp: Double?
    @Published private(set) var dailyLowTemp: Double?
    @Published private(set) var dailyHighWind: Double?
    private var extremesDate: String = "" // tracks which day we're on

    // MARK: - Low Battery

    /// Sensor keys with low battery (value = 0)
    var lowBatterySensors: [String] {
        guard let observation = weatherData?.observation else { return [] }
        let batteryKeys = ["battIn", "battRain", "battLightning", "battOut",
                           "batleak1", "batleak2", "batleak3", "batleak4",
                           "battsm1", "battsm2", "battsm3", "battsm4",
                           "batt_co2", "batt_cellgateway"]
        var lowKeys: [String] = []
        let mirror = Mirror(reflecting: observation)
        for child in mirror.children {
            guard let label = child.label, batteryKeys.contains(label) else { continue }
            let childMirror = Mirror(reflecting: child.value)
            if childMirror.displayStyle == .optional {
                if let inner = childMirror.children.first?.value {
                    if let intVal = inner as? Int, intVal == 0 {
                        lowKeys.append(label)
                    } else if let strVal = inner as? String, strVal == "0" {
                        lowKeys.append(label)
                    }
                }
            }
        }
        return lowKeys
    }

    // MARK: - Severe Weather (WeatherKit)

    /// Active weather alerts from WeatherKit, filtered to non-expired
    @Published private(set) var activeWeatherAlerts: [WeatherAlert] = []

    // MARK: - User Preferences (persisted via UserDefaults)

    @Published var applicationKey: String = UserDefaults.standard.string(forKey: "applicationKey") ?? "" {
        didSet { UserDefaults.standard.set(applicationKey, forKey: "applicationKey") }
    }
    @Published var apiKeysRaw: String = UserDefaults.standard.string(forKey: "apiKeysRaw") ?? "" {
        didSet { UserDefaults.standard.set(apiKeysRaw, forKey: "apiKeysRaw") }
    }
    @Published var selectedSensorKey: String = UserDefaults.standard.string(forKey: "selectedSensorKey") ?? "tempF" {
        didSet { UserDefaults.standard.set(selectedSensorKey, forKey: "selectedSensorKey") }
    }
    @Published var unitSystem: UnitSystem = UnitSystem(rawValue: UserDefaults.standard.string(forKey: "unitSystem") ?? "imperial") ?? .imperial {
        didSet { UserDefaults.standard.set(unitSystem.rawValue, forKey: "unitSystem") }
    }

    // MARK: - Quick Stats Customization

    @Published var quickStatKeys: [String] = {
        if let data = UserDefaults.standard.data(forKey: "quickStatKeys"),
           let keys = try? JSONDecoder().decode([String].self, from: data) {
            return keys
        }
        return ["windSpeedMPH", "humidity", "baromRelIn", "uv"]
    }() {
        didSet {
            if let data = try? JSONEncoder().encode(quickStatKeys) {
                UserDefaults.standard.set(data, forKey: "quickStatKeys")
            }
        }
    }

    // MARK: - Alert Thresholds

    @Published var highTempAlert: Double = UserDefaults.standard.double(forKey: "highTempAlert") {
        didSet { UserDefaults.standard.set(highTempAlert, forKey: "highTempAlert") }
    }
    @Published var lowTempAlert: Double = UserDefaults.standard.double(forKey: "lowTempAlert") {
        didSet { UserDefaults.standard.set(lowTempAlert, forKey: "lowTempAlert") }
    }
    @Published var highWindAlert: Double = UserDefaults.standard.double(forKey: "highWindAlert") {
        didSet { UserDefaults.standard.set(highWindAlert, forKey: "highWindAlert") }
    }
    @Published var alertsEnabled: Bool = UserDefaults.standard.bool(forKey: "alertsEnabled") {
        didSet { UserDefaults.standard.set(alertsEnabled, forKey: "alertsEnabled") }
    }
    @Published var tempAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "tempAlertEnabled") {
        didSet { UserDefaults.standard.set(tempAlertEnabled, forKey: "tempAlertEnabled") }
    }
    @Published var windAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "windAlertEnabled") {
        didSet { UserDefaults.standard.set(windAlertEnabled, forKey: "windAlertEnabled") }
    }
    @Published var weatherAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "weatherAlertEnabled") {
        didSet { UserDefaults.standard.set(weatherAlertEnabled, forKey: "weatherAlertEnabled") }
    }
    @Published var airQualityAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "airQualityAlertEnabled") {
        didSet { UserDefaults.standard.set(airQualityAlertEnabled, forKey: "airQualityAlertEnabled") }
    }
    @Published var highUVAlert: Double = UserDefaults.standard.double(forKey: "highUVAlert") {
        didSet { UserDefaults.standard.set(highUVAlert, forKey: "highUVAlert") }
    }
    @Published var lightningAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "lightningAlertEnabled") {
        didSet { UserDefaults.standard.set(lightningAlertEnabled, forKey: "lightningAlertEnabled") }
    }
    @Published var heavyRainAlert: Double = UserDefaults.standard.double(forKey: "heavyRainAlert") {
        didSet { UserDefaults.standard.set(heavyRainAlert, forKey: "heavyRainAlert") }
    }
    @Published var highHumidityAlert: Double = UserDefaults.standard.double(forKey: "highHumidityAlert") {
        didSet { UserDefaults.standard.set(highHumidityAlert, forKey: "highHumidityAlert") }
    }
    @Published var highPM25Alert: Double = UserDefaults.standard.double(forKey: "highPM25Alert") {
        didSet { UserDefaults.standard.set(highPM25Alert, forKey: "highPM25Alert") }
    }
    @Published var highCO2Alert: Double = UserDefaults.standard.double(forKey: "highCO2Alert") {
        didSet { UserDefaults.standard.set(highCO2Alert, forKey: "highCO2Alert") }
    }
    @Published var leakAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "leakAlertEnabled") {
        didSet { UserDefaults.standard.set(leakAlertEnabled, forKey: "leakAlertEnabled") }
    }
    @Published var batteryAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "batteryAlertEnabled") {
        didSet { UserDefaults.standard.set(batteryAlertEnabled, forKey: "batteryAlertEnabled") }
    }
    @Published var severeWeatherAlertEnabled: Bool = UserDefaults.standard.bool(forKey: "severeWeatherAlertEnabled") {
        didSet { UserDefaults.standard.set(severeWeatherAlertEnabled, forKey: "severeWeatherAlertEnabled") }
    }

    // MARK: - Deferred Bindings

    /// Creates a Binding that defers the property set to the next run loop,
    /// preventing "Publishing changes from within view updates" warnings.
    func deferredBinding<T>(for keyPath: ReferenceWritableKeyPath<WeatherManager, T>) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { newValue in
                DispatchQueue.main.async {
                    self[keyPath: keyPath] = newValue
                }
            }
        )
    }

    // MARK: - Private

    private var socket: AmbientWebSocket?
    private var cancellables = Set<AnyCancellable>()
    private var lastAlertTimes: [String: Date] = [:]
    private var weatherKitTimer: Timer?
    var historyManager: HistoryManager?

    // MARK: - Init

    init() {
        selectedStationID = UserDefaults.standard.string(forKey: "selectedStationID")

        // Restore daily extremes
        extremesDate = UserDefaults.standard.string(forKey: "extremesDate") ?? ""
        dailyHighTemp = UserDefaults.standard.object(forKey: "dailyHighTemp") as? Double
        dailyLowTemp = UserDefaults.standard.object(forKey: "dailyLowTemp") as? Double
        dailyHighWind = UserDefaults.standard.object(forKey: "dailyHighWind") as? Double

        // Set default alert thresholds if never configured
        if UserDefaults.standard.object(forKey: "highTempAlert") == nil { highTempAlert = 100 }
        if UserDefaults.standard.object(forKey: "lowTempAlert") == nil { lowTempAlert = 32 }
        if UserDefaults.standard.object(forKey: "highWindAlert") == nil { highWindAlert = 40 }
        if UserDefaults.standard.object(forKey: "highUVAlert") == nil { highUVAlert = 8 }
        if UserDefaults.standard.object(forKey: "heavyRainAlert") == nil { heavyRainAlert = 0.5 }
        if UserDefaults.standard.object(forKey: "highHumidityAlert") == nil { highHumidityAlert = 90 }
        if UserDefaults.standard.object(forKey: "highPM25Alert") == nil { highPM25Alert = 55 }
        if UserDefaults.standard.object(forKey: "highCO2Alert") == nil { highCO2Alert = 1000 }
        if UserDefaults.standard.object(forKey: "severeWeatherAlertEnabled") == nil { severeWeatherAlertEnabled = true }

        // Auto-connect at launch if credentials are stored
        if !applicationKey.isEmpty && !apiKeysRaw.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.connect()
            }
        }
    }

    // MARK: - Computed Properties

    /// Parse comma-separated API keys
    var apiKeys: [String] {
        apiKeysRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Whether credentials have been configured
    var isConfigured: Bool {
        !applicationKey.isEmpty && !apiKeys.isEmpty
    }

    /// The string displayed in the macOS menubar
    var menuBarLabel: String {
        guard let data = weatherData else {
            return connectionStatus == .connecting ? "..." : "--"
        }
        return SensorFormatter.menuBarString(for: selectedSensorKey, from: data.observation, unitSystem: unitSystem)
    }

    /// The SF Symbol displayed in the macOS menubar
    var menuBarIcon: String {
        guard weatherData != nil else {
            return "cloud.fill"
        }
        let category = AmbientLastData.propertyCategories[selectedSensorKey] ?? .unknown
        return category.iconName
    }

    /// Categorized non-nil sensors from the connected station
    var sensorsByCategory: [(SensorCategory, [String])] {
        weatherData?.observation.availableSensorsbyCategorySorted ?? []
    }

    /// Station name, if connected
    var stationName: String {
        weatherData?.info.name ?? "Unknown Station"
    }

    /// Station location, if connected
    var stationLocation: String {
        weatherData?.info.coords.location ?? ""
    }

    // MARK: - Connection Management

    func connect() {
        guard isConfigured else { return }

        // Tear down any existing connection
        disconnect()

        let ws = AmbientWebSocket(applicationKey: applicationKey)
        self.socket = ws

        ws.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status
            }
            .store(in: &cancellables)

        ws.$weatherData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self, let data else { return }
                // Store in multi-station dictionary
                let stationID = data.stationID
                self.allStations[stationID] = data

                // Auto-select first station if none selected
                if self.selectedStationID == nil {
                    self.selectedStationID = stationID
                }

                // Update active weather data if this is the selected station
                if stationID == self.selectedStationID {
                    self.weatherData = data
                    self.processNewObservation(data.observation)
                }
            }
            .store(in: &cancellables)

        ws.$connectionError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.connectionError = error
            }
            .store(in: &cancellables)

        ws.connectStations(apiKeys: apiKeys)

        // Start WeatherKit polling (15-minute interval)
        startWeatherKitPolling()
    }

    func disconnect() {
        weatherKitTimer?.invalidate()
        weatherKitTimer = nil
        activeWeatherAlerts = []
        cancellables.removeAll()
        socket?.disconnectStations()
        socket = nil
        connectionStatus = .disconnected
        weatherData = nil
        connectionError = nil
        allStations.removeAll()
    }

    func autoConnectIfNeeded() {
        if isConfigured && connectionStatus == .disconnected {
            connect()
        }
    }

    /// Switch to a different station
    func selectStation(_ stationID: String) {
        selectedStationID = stationID
        weatherData = allStations[stationID]
    }

    // MARK: - Observation Processing

    private func processNewObservation(_ observation: AmbientLastData) {
        updatePressureTrend(observation)
        updateDailyExtremes(observation)
        if alertsEnabled {
            checkAlerts(observation)
        }
        if let data = weatherData {
            historyManager?.saveSnapshot(from: data)
        }
    }

    // MARK: - Pressure Trend

    private func updatePressureTrend(_ observation: AmbientLastData) {
        guard let current = observation.baromRelIn else { return }
        if let previous = previousPressure {
            let diff = current - previous
            if diff > 0.02 {
                pressureTrend = .rising
            } else if diff < -0.02 {
                pressureTrend = .falling
            } else {
                pressureTrend = .steady
            }
        }
        previousPressure = current
    }

    // MARK: - Daily Extremes

    private func updateDailyExtremes(_ observation: AmbientLastData) {
        let today = formattedToday()

        // Reset if new day
        if today != extremesDate {
            extremesDate = today
            dailyHighTemp = nil
            dailyLowTemp = nil
            dailyHighWind = nil
            UserDefaults.standard.set(today, forKey: "extremesDate")
        }

        if let temp = observation.tempF {
            if dailyHighTemp == nil || temp > dailyHighTemp! {
                dailyHighTemp = temp
                UserDefaults.standard.set(temp, forKey: "dailyHighTemp")
            }
            if dailyLowTemp == nil || temp < dailyLowTemp! {
                dailyLowTemp = temp
                UserDefaults.standard.set(temp, forKey: "dailyLowTemp")
            }
        }

        if let wind = observation.windSpeedMPH {
            if dailyHighWind == nil || wind > dailyHighWind! {
                dailyHighWind = wind
                UserDefaults.standard.set(wind, forKey: "dailyHighWind")
            }
        }
    }

    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Notification Alerts

    private func checkAlerts(_ observation: AmbientLastData) {
        if tempAlertEnabled, let temp = observation.tempF {
            if highTempAlert > 0 && temp >= highTempAlert {
                sendAlert(key: "highTemp", title: "High Temperature Alert",
                          body: "Temperature is \(String(format: "%.1f", temp))\u{00B0}F")
            }
            if lowTempAlert > 0 && temp <= lowTempAlert {
                sendAlert(key: "lowTemp", title: "Low Temperature Alert",
                          body: "Temperature is \(String(format: "%.1f", temp))\u{00B0}F")
            }
        }

        if windAlertEnabled, let wind = observation.windSpeedMPH, highWindAlert > 0, wind >= highWindAlert {
            sendAlert(key: "highWind", title: "High Wind Alert",
                      body: "Wind speed is \(String(format: "%.0f", wind)) mph")
        }

        if weatherAlertEnabled {
            if let uv = observation.uv, highUVAlert > 0, Double(uv) >= highUVAlert {
                sendAlert(key: "highUV", title: "High UV Index Alert",
                          body: "UV index is \(uv) — protect your skin!")
            }

            if let rain = observation.hourlyRainIn, heavyRainAlert > 0, rain >= heavyRainAlert {
                sendAlert(key: "heavyRain", title: "Heavy Rain Alert",
                          body: "Rain rate is \(String(format: "%.2f", rain))\"/hr")
            }

            if let humidity = observation.humidity, highHumidityAlert > 0, Double(humidity) >= highHumidityAlert {
                sendAlert(key: "highHumidity", title: "High Humidity Alert",
                          body: "Humidity is \(humidity)%")
            }
        }

        if lightningAlertEnabled, let strikes = observation.lightningDay, strikes > 0 {
            let distInfo: String
            if let dist = observation.lightningDistance {
                distInfo = " (nearest: \(String(format: "%.1f", dist)) mi)"
            } else {
                distInfo = ""
            }
            sendAlert(key: "lightning", title: "Lightning Detected!",
                      body: "\(strikes) strike\(strikes == 1 ? "" : "s") today\(distInfo)")
        }

        if airQualityAlertEnabled {
            if let pm25 = observation.pm25, highPM25Alert > 0, pm25 >= highPM25Alert {
                sendAlert(key: "highPM25", title: "Poor Air Quality Alert",
                          body: "PM2.5 is \(String(format: "%.1f", pm25)) µg/m³")
            }

            if let co2 = observation.co2, highCO2Alert > 0, Double(co2) >= highCO2Alert {
                sendAlert(key: "highCO2", title: "High CO₂ Alert",
                          body: "CO₂ is \(co2) ppm — ventilate!")
            }
        }

        if leakAlertEnabled {
            let leakKeys = ["leak1", "leak2", "leak3", "leak4"]
            let mirror = Mirror(reflecting: observation)
            for child in mirror.children {
                guard let label = child.label, leakKeys.contains(label) else { continue }
                let childMirror = Mirror(reflecting: child.value)
                if childMirror.displayStyle == .optional,
                   let inner = childMirror.children.first?.value,
                   let intVal = inner as? Int, intVal == 1 {
                    let desc = AmbientLastData.sensorDescriptions[label] ?? label
                    sendAlert(key: "leak_\(label)", title: "Water Leak Detected!",
                              body: "\(desc) reports water detected")
                }
            }
        }

        if batteryAlertEnabled && !lowBatterySensors.isEmpty {
            let names = lowBatterySensors.map {
                AmbientLastData.sensorDescriptions[$0] ?? $0
            }.joined(separator: ", ")
            sendAlert(key: "battery", title: "Low Battery Warning",
                      body: "Low battery: \(names)")
        }
    }

    private func sendAlert(key: String, title: String, body: String) {
        // Throttle: max once per 30 minutes per alert key
        let now = Date()
        if let last = lastAlertTimes[key], now.timeIntervalSince(last) < 1800 { return }
        lastAlertTimes[key] = now

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: "porch_\(key)_\(Int(now.timeIntervalSince1970))",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - WeatherKit Severe Weather Polling

    private func startWeatherKitPolling() {
        // Fetch immediately on connect
        Task { await fetchWeatherKitAlerts() }

        // Then poll every 15 minutes
        weatherKitTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchWeatherKitAlerts()
            }
        }
    }

    private func fetchWeatherKitAlerts() async {
        guard let coords = weatherData?.info.coords.coords else { return }

        let location = CLLocation(latitude: coords.lat, longitude: coords.lon)

        do {
            let alerts = try await WeatherService.shared.weather(for: location, including: .alerts)
            let now = Date()

            // Filter to non-expired alerts
            let currentAlerts = (alerts ?? []).filter { alert in
                alert.metadata.expirationDate > now
            }

            self.activeWeatherAlerts = currentAlerts

            // Send notifications for severe/extreme alerts (if enabled)
            if alertsEnabled && severeWeatherAlertEnabled {
                for alert in currentAlerts where alert.severity == .severe || alert.severity == .extreme {
                    let key = "weatherkit_\(alert.summary)_\(alert.region ?? "unknown")"
                    sendAlert(
                        key: key,
                        title: "\(alert.severity == .extreme ? "EXTREME" : "SEVERE"): \(alert.summary)",
                        body: alert.region ?? "Weather alert for your area"
                    )
                }
            }
        } catch {
            // Silently fail — WeatherKit unavailability should not disrupt the app
        }
    }
}
