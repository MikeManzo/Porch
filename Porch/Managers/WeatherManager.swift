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

// MARK: - Daily Extreme Record

/// A single day's high/low values for the weekly extremes history
struct DailyExtremeRecord: Codable, Identifiable {
    var id: String { date }
    let date: String           // "yyyy-MM-dd"
    var highTemp: Double?
    var lowTemp: Double?
    var highIndoorTemp: Double?
    var lowIndoorTemp: Double?
    var highWind: Double?
}

// MARK: - Snooze Types

/// Describes how an alert is currently snoozed
enum SnoozeKind: Codable, Equatable {
    case timed(until: Date)
    case untilCleared
}

/// Persisted snooze state for one alert key
struct SnoozeEntry: Codable, Equatable {
    let kind: SnoozeKind
    var hasCleared: Bool
}

// MARK: - Notification Delegate

/// Lightweight delegate that forwards notification actions back to WeatherManager
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var manager: WeatherManager?

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionID = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        let alertKey: String
        if let key = userInfo["alertKey"] as? String {
            alertKey = key
        } else {
            alertKey = response.notification.request.identifier
        }

        // If user clicked the notification (not a snooze action), open the details URL
        if actionID == UNNotificationDefaultActionIdentifier,
           let urlString = userInfo["detailsURL"] as? String,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }

        Task { @MainActor [weak self] in
            self?.manager?.handleSnoozeAction(actionID: actionID, alertKey: alertKey)
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

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
    @Published private(set) var dailyHighIndoorTemp: Double?
    @Published private(set) var dailyLowIndoorTemp: Double?
    @Published private(set) var dailyHighWind: Double?
    @Published private(set) var extremesHistory: [DailyExtremeRecord] = []
    private var extremesDate: String = "" // tracks which day we're on

    // MARK: - Low Battery

    /// Sensor keys with low battery
    /// Note: Most sensors use 0 = low, but battLightning is inverted (0 = OK, 1 = low)
    var lowBatterySensors: [String] {
        guard let observation = weatherData?.observation else { return [] }
        let batteryKeys = ["battIn", "battRain", "battLightning", "battOut",
                           "batleak1", "batleak2", "batleak3", "batleak4",
                           "battsm1", "battsm2", "battsm3", "battsm4",
                           "batt_co2", "batt_cellgateway"]
        // Lightning detector battery is inverted: 0 = OK, 1 = low
        let invertedKeys: Set<String> = ["battLightning"]
        var lowKeys: [String] = []
        let mirror = Mirror(reflecting: observation)
        for child in mirror.children {
            guard let label = child.label, batteryKeys.contains(label) else { continue }
            let childMirror = Mirror(reflecting: child.value)
            if childMirror.displayStyle == .optional {
                if let inner = childMirror.children.first?.value {
                    let isInverted = invertedKeys.contains(label)
                    if let intVal = inner as? Int {
                        if isInverted ? intVal == 1 : intVal == 0 {
                            lowKeys.append(label)
                        }
                    } else if let strVal = inner as? String {
                        if isInverted ? strVal == "1" : strVal == "0" {
                            lowKeys.append(label)
                        }
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

    /// Default re-alert interval in seconds (replaces hardcoded 30 min).
    @Published var defaultReAlertInterval: TimeInterval = {
        let stored = UserDefaults.standard.double(forKey: "defaultReAlertInterval")
        return stored > 0 ? stored : 1800
    }() {
        didSet { UserDefaults.standard.set(defaultReAlertInterval, forKey: "defaultReAlertInterval") }
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
    private let notificationDelegate = NotificationDelegate()
    var historyManager: HistoryManager?

    /// Per-key snooze state, persisted as JSON in UserDefaults.
    private var snoozeStates: [String: SnoozeEntry] = {
        guard let data = UserDefaults.standard.data(forKey: "snoozeStates"),
              let decoded = try? JSONDecoder().decode([String: SnoozeEntry].self, from: data)
        else { return [:] }
        return decoded
    }()

    private func persistSnoozeStates() {
        if let data = try? JSONEncoder().encode(snoozeStates) {
            UserDefaults.standard.set(data, forKey: "snoozeStates")
        }
    }

    // MARK: - Init

    init() {
        selectedStationID = UserDefaults.standard.string(forKey: "selectedStationID")

        // Restore daily extremes
        extremesDate = UserDefaults.standard.string(forKey: "extremesDate") ?? ""
        dailyHighTemp = UserDefaults.standard.object(forKey: "dailyHighTemp") as? Double
        dailyLowTemp = UserDefaults.standard.object(forKey: "dailyLowTemp") as? Double
        dailyHighIndoorTemp = UserDefaults.standard.object(forKey: "dailyHighIndoorTemp") as? Double
        dailyLowIndoorTemp = UserDefaults.standard.object(forKey: "dailyLowIndoorTemp") as? Double
        dailyHighWind = UserDefaults.standard.object(forKey: "dailyHighWind") as? Double

        // Restore extremes history
        if let data = UserDefaults.standard.data(forKey: "extremesHistory"),
           let records = try? JSONDecoder().decode([DailyExtremeRecord].self, from: data) {
            extremesHistory = records
        }

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

        // Register notification actions and delegate (must happen before sending any notifications)
        registerNotificationCategory()
        notificationDelegate.manager = self
        UNUserNotificationCenter.current().delegate = notificationDelegate

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
        // Trigger first WeatherKit fetch once we have valid data
        if severeWeatherAlertEnabled && !hasFetchedWeatherKitOnce {
            hasFetchedWeatherKitOnce = true
            Task {
                await fetchWeatherKitAlerts()
            }
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
            // Archive the previous day's extremes before resetting
            if !extremesDate.isEmpty {
                let record = DailyExtremeRecord(
                    date: extremesDate,
                    highTemp: dailyHighTemp,
                    lowTemp: dailyLowTemp,
                    highIndoorTemp: dailyHighIndoorTemp,
                    lowIndoorTemp: dailyLowIndoorTemp,
                    highWind: dailyHighWind
                )
                extremesHistory.append(record)
                if extremesHistory.count > 7 {
                    extremesHistory = Array(extremesHistory.suffix(7))
                }
                persistExtremesHistory()
            }

            extremesDate = today
            dailyHighTemp = nil
            dailyLowTemp = nil
            dailyHighIndoorTemp = nil
            dailyLowIndoorTemp = nil
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

        if let temp = observation.tempInF {
            if dailyHighIndoorTemp == nil || temp > dailyHighIndoorTemp! {
                dailyHighIndoorTemp = temp
                UserDefaults.standard.set(temp, forKey: "dailyHighIndoorTemp")
            }
            if dailyLowIndoorTemp == nil || temp < dailyLowIndoorTemp! {
                dailyLowIndoorTemp = temp
                UserDefaults.standard.set(temp, forKey: "dailyLowIndoorTemp")
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

    private func persistExtremesHistory() {
        if let data = try? JSONEncoder().encode(extremesHistory) {
            UserDefaults.standard.set(data, forKey: "extremesHistory")
        }
    }

    // MARK: - Notification Alerts

    private func checkAlerts(_ observation: AmbientLastData) {
        // Track which conditions are currently active for "Until Cleared" logic
        var activeKeys = Set<String>()

        if tempAlertEnabled, let temp = observation.tempF {
            if highTempAlert > 0 && temp >= highTempAlert {
                activeKeys.insert("highTemp")
                sendAlert(key: "highTemp", title: "High Temperature Alert",
                          body: "Temperature is \(String(format: "%.1f", temp))\u{00B0}F")
            }
            if lowTempAlert > 0 && temp <= lowTempAlert {
                activeKeys.insert("lowTemp")
                sendAlert(key: "lowTemp", title: "Low Temperature Alert",
                          body: "Temperature is \(String(format: "%.1f", temp))\u{00B0}F")
            }
        }

        if windAlertEnabled, let wind = observation.windSpeedMPH, highWindAlert > 0, wind >= highWindAlert {
            activeKeys.insert("highWind")
            sendAlert(key: "highWind", title: "High Wind Alert",
                      body: "Wind speed is \(String(format: "%.0f", wind)) mph")
        }

        if weatherAlertEnabled {
            if let uv = observation.uv, highUVAlert > 0, Double(uv) >= highUVAlert {
                activeKeys.insert("highUV")
                sendAlert(key: "highUV", title: "High UV Index Alert",
                          body: "UV index is \(uv) — protect your skin!")
            }

            if let rain = observation.hourlyRainIn, heavyRainAlert > 0, rain >= heavyRainAlert {
                activeKeys.insert("heavyRain")
                sendAlert(key: "heavyRain", title: "Heavy Rain Alert",
                          body: "Rain rate is \(String(format: "%.2f", rain))\"/hr")
            }

            if let humidity = observation.humidity, highHumidityAlert > 0, Double(humidity) >= highHumidityAlert {
                activeKeys.insert("highHumidity")
                sendAlert(key: "highHumidity", title: "High Humidity Alert",
                          body: "Humidity is \(humidity)%")
            }
        }

        if lightningAlertEnabled, let strikes = observation.lightningDay, strikes > 0 {
            activeKeys.insert("lightning")
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
                activeKeys.insert("highPM25")
                sendAlert(key: "highPM25", title: "Poor Air Quality Alert",
                          body: "PM2.5 is \(String(format: "%.1f", pm25)) µg/m³")
            }

            if let co2 = observation.co2, highCO2Alert > 0, Double(co2) >= highCO2Alert {
                activeKeys.insert("highCO2")
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
                    activeKeys.insert("leak_\(label)")
                    let desc = AmbientLastData.sensorDescriptions[label] ?? label
                    sendAlert(key: "leak_\(label)", title: "Water Leak Detected!",
                              body: "\(desc) reports water detected")
                }
            }
        }

        if batteryAlertEnabled && !lowBatterySensors.isEmpty {
            activeKeys.insert("battery")
            let names = lowBatterySensors.map {
                AmbientLastData.sensorDescriptions[$0] ?? $0
            }.joined(separator: ", ")
            sendAlert(key: "battery", title: "Low Battery Warning",
                      body: "Low battery: \(names)")
        }

        // Update "Until Cleared" snooze states
        var didChange = false
        for (key, entry) in snoozeStates {
            guard case .untilCleared = entry.kind, !entry.hasCleared, !key.hasPrefix("weatherkit_") else { continue }
            if !activeKeys.contains(key) {
                snoozeStates[key] = SnoozeEntry(kind: .untilCleared, hasCleared: true)
                didChange = true
            }
        }
        if didChange { persistSnoozeStates() }
    }

    private func sendAlert(key: String, title: String, body: String, detailsURL: URL? = nil) {
        let now = Date()

        // 1. Check snooze state
        if let snooze = snoozeStates[key] {
            switch snooze.kind {
            case .timed(let until):
                if now < until {
                    return // Still snoozed
                } else {
                    snoozeStates.removeValue(forKey: key)
                    persistSnoozeStates()
                }
            case .untilCleared:
                if !snooze.hasCleared {
                    return // Condition hasn't cleared yet
                } else {
                    snoozeStates.removeValue(forKey: key)
                    persistSnoozeStates()
                }
            }
        }

        // 2. Configurable throttle (replaces hardcoded 30 min)
        if let last = lastAlertTimes[key], now.timeIntervalSince(last) < defaultReAlertInterval { return }
        lastAlertTimes[key] = now

        // 3. Build and send notification with snooze actions
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "PORCH_ALERT"
        var info: [String: Any] = ["alertKey": key]
        if let url = detailsURL {
            info["detailsURL"] = url.absoluteString
        }
        content.userInfo = info

        let request = UNNotificationRequest(identifier: "porch_\(key)_\(Int(now.timeIntervalSince1970))",
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func registerNotificationCategory() {
        let snooze1h = UNNotificationAction(identifier: "SNOOZE_1H", title: "Snooze 1 Hour", options: [])
        let snooze8h = UNNotificationAction(identifier: "SNOOZE_8H", title: "Snooze 8 Hours", options: [])
        let snooze24h = UNNotificationAction(identifier: "SNOOZE_24H", title: "Snooze 24 Hours", options: [])
        let snoozeCleared = UNNotificationAction(identifier: "SNOOZE_UNTIL_CLEARED", title: "Until Cleared", options: [])

        let category = UNNotificationCategory(
            identifier: "PORCH_ALERT",
            actions: [snooze1h, snooze8h, snooze24h, snoozeCleared],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Called from the notification delegate when user taps a snooze action
    func handleSnoozeAction(actionID: String, alertKey: String) {
        let entry: SnoozeEntry?
        switch actionID {
        case "SNOOZE_1H":
            entry = SnoozeEntry(kind: .timed(until: Date().addingTimeInterval(3600)), hasCleared: false)
        case "SNOOZE_8H":
            entry = SnoozeEntry(kind: .timed(until: Date().addingTimeInterval(28800)), hasCleared: false)
        case "SNOOZE_24H":
            entry = SnoozeEntry(kind: .timed(until: Date().addingTimeInterval(86400)), hasCleared: false)
        case "SNOOZE_UNTIL_CLEARED":
            entry = SnoozeEntry(kind: .untilCleared, hasCleared: false)
        default:
            entry = nil
        }
        if let entry {
            snoozeStates[alertKey] = entry
            persistSnoozeStates()
        }
    }

    // MARK: - WeatherKit Severe Weather Polling

    private var hasFetchedWeatherKitOnce = false

    private func startWeatherKitPolling() {
        hasFetchedWeatherKitOnce = false

        // Poll every 15 minutes (first fetch triggers when data arrives in processNewObservation)
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
            print("[Porch] WeatherKit: \(currentAlerts.count) active alert(s)")
            for alert in currentAlerts {
                print("[Porch]   → \(alert.summary) | severity: \(alert.severity) | region: \(alert.region ?? "unknown")")
            }

            // Send notifications for moderate/severe/extreme alerts (if enabled)
            if alertsEnabled && severeWeatherAlertEnabled {
                for alert in currentAlerts where alert.severity == .moderate || alert.severity == .severe || alert.severity == .extreme {
                    let key = "weatherkit_\(alert.summary)_\(alert.region ?? "unknown")"
                    let prefix: String
                    switch alert.severity {
                    case .extreme: prefix = "EXTREME"
                    case .severe: prefix = "SEVERE"
                    default: prefix = "WATCH"
                    }
                    sendAlert(
                        key: key,
                        title: "\(prefix): \(alert.summary)",
                        body: alert.region ?? "Weather alert for your area",
                        detailsURL: alert.detailsURL
                    )
                }
            }
            // Update "Until Cleared" snooze states for WeatherKit alerts
            var didChange = false
            for (key, entry) in snoozeStates {
                guard key.hasPrefix("weatherkit_"), case .untilCleared = entry.kind, !entry.hasCleared else { continue }
                let stillActive = currentAlerts.contains { alert in
                    "weatherkit_\(alert.summary)_\(alert.region ?? "unknown")" == key
                }
                if !stillActive {
                    snoozeStates[key] = SnoozeEntry(kind: .untilCleared, hasCleared: true)
                    didChange = true
                }
            }
            if didChange { persistSnoozeStates() }
        } catch {
            print("[Porch] WeatherKit error: \(error.localizedDescription)")
        }
    }
}
