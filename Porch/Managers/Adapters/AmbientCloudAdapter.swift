//
//  AmbientCloudAdapter.swift
//  Porch
//
//  Concrete StationAdapter that connects to Ambient Weather's cloud WebSocket.
//  Wraps the existing AmbientWeather package and converts data to PorchWeatherData.
//

import Foundation
import Combine
import AmbientWeather
import PorchStationKit

@MainActor
final class AmbientCloudAdapter: StationAdapter, @unchecked Sendable {

    // MARK: - StationAdapter Identity

    static let brand: StationBrand = .ambient
    static let connectionType: ConnectionType = .cloud

    static let supportedModels: [StationModel] = [
        StationModel(
            id: "ambient-ws2902",
            brand: .ambient,
            name: "WS-2902",
            connectionTypes: [.cloud],
            capabilities: .fullSuite
        ),
        StationModel(
            id: "ambient-ws5000",
            brand: .ambient,
            name: "WS-5000",
            connectionTypes: [.cloud],
            capabilities: .fullSuite
        )
    ]

    static let configurationFields: [ConfigurationField] = [
        ConfigurationField(id: "applicationKey", label: "Application Key", placeholder: "Your Ambient Weather application key", isSecure: true),
        ConfigurationField(id: "apiKey", label: "API Key(s)", placeholder: "Comma-separated API keys", isSecure: true)
    ]

    // MARK: - State

    private var socket: AmbientWebSocket?
    private var observationContinuation: AsyncStream<PorchWeatherData>.Continuation?
    private var statusContinuation: AsyncStream<StationConnectionStatus>.Continuation?
    private var cancellables = Set<AnyCancellable>()

    private(set) var isConnected = false

    // MARK: - Streams

    lazy var observations: AsyncStream<PorchWeatherData> = {
        AsyncStream { [weak self] continuation in
            self?.observationContinuation = continuation
        }
    }()

    lazy var connectionStatusStream: AsyncStream<StationConnectionStatus> = {
        AsyncStream { [weak self] continuation in
            self?.statusContinuation = continuation
        }
    }()

    // MARK: - Connection

    func connect(configuration: StationConfiguration) async throws {
        guard let appKey = configuration.applicationKey, !appKey.isEmpty else {
            statusContinuation?.yield(.failed("No application key configured"))
            return
        }

        let apiKeys: [String] = (configuration.apiKey ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !apiKeys.isEmpty else {
            statusContinuation?.yield(.failed("No API keys configured"))
            return
        }

        let ws = AmbientWebSocket(applicationKey: appKey)
        self.socket = ws

        statusContinuation?.yield(.connecting)

        // Observe status via Combine
        ws.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .connected:
                    self.isConnected = true
                    self.statusContinuation?.yield(.connected)
                case .connecting:
                    self.statusContinuation?.yield(.connecting)
                case .disconnected:
                    self.isConnected = false
                    self.statusContinuation?.yield(.disconnected)
                }
            }
            .store(in: &cancellables)

        // Observe data via Combine
        ws.$weatherData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ambientData in
                guard let self else { return }
                let porchData = self.convert(ambientData)
                self.observationContinuation?.yield(porchData)
            }
            .store(in: &cancellables)

        ws.connectStations(apiKeys: apiKeys)
    }

    func disconnect() {
        cancellables.removeAll()
        socket?.disconnectStations()
        socket = nil
        isConnected = false
        statusContinuation?.yield(.disconnected)
    }

    // MARK: - Data Conversion

    private func convert(_ ambient: AmbientWeatherData) -> PorchWeatherData {
        let obs = ambient.observation

        var data = PorchWeatherData(
            stationID: ambient.stationID,
            stationName: ambient.info.name,
            brand: .ambient,
            timestamp: obs.observationDate
        )

        // Location from station info
        let coords = ambient.info.coords.coords
        data.location = StationLocation(
            latitude: coords.lat,
            longitude: coords.lon,
            displayName: ambient.info.coords.location
        )

        // Outdoor
        data.temperatureF = obs.tempF
        data.humidity = obs.humidity
        data.dewPointF = obs.dewPoint
        data.feelsLikeF = obs.feelsLike

        // Indoor
        data.indoorTempF = obs.tempInF
        data.indoorHumidity = obs.humidityIn

        // Wind
        data.windSpeedMPH = obs.windSpeedMPH
        data.windGustMPH = obs.windGustMPH
        data.windDirection = obs.windDir
        data.maxDailyGustMPH = obs.maxDailyGust

        // Pressure
        data.pressureRelativeInHg = obs.baromRelIn
        data.pressureAbsoluteInHg = obs.baromAbsIn

        // Rain
        data.rainRateInPerHr = obs.hourlyRainIn
        data.eventRainIn = obs.eventRainIn
        data.dailyRainIn = obs.dailyRainIn
        data.weeklyRainIn = obs.weeklyRainIn
        data.monthlyRainIn = obs.monthlyRainIn
        data.yearlyRainIn = obs.yearlyRainIn

        // Solar & UV
        data.solarRadiation = obs.solarRadiation
        data.uvIndex = obs.uv

        // Lightning
        data.lightningDistanceMi = obs.lightningDistance
        if let ts = obs.lightningTime {
            data.lightningTime = Date(timeIntervalSince1970: TimeInterval(ts) / 1000.0)
        }
        data.lightningDayCount = obs.lightningDay.map { Int($0) }

        // Air Quality
        data.pm25 = obs.pm25
        data.co2 = obs.co2

        // Soil sensors
        if let v = obs.soiltemp1f { data.soilTempF[1] = v }
        if let v = obs.soiltemp2f { data.soilTempF[2] = v }
        if let v = obs.soiltemp3f { data.soilTempF[3] = v }
        if let v = obs.soiltemp4f { data.soilTempF[4] = v }
        if let v = obs.soiltemp5f { data.soilTempF[5] = v }
        if let v = obs.soiltemp6f { data.soilTempF[6] = v }
        if let v = obs.soiltemp7f { data.soilTempF[7] = v }
        if let v = obs.soiltemp8f { data.soilTempF[8] = v }
        if let v = obs.soiltemp9f { data.soilTempF[9] = v }
        if let v = obs.soiltemp10f { data.soilTempF[10] = v }

        if let v = obs.soilhum1 { data.soilMoisture[1] = v }
        if let v = obs.soilhum2 { data.soilMoisture[2] = v }
        if let v = obs.soilhum3 { data.soilMoisture[3] = v }
        if let v = obs.soilhum4 { data.soilMoisture[4] = v }
        if let v = obs.soilhum5 { data.soilMoisture[5] = v }
        if let v = obs.soilhum6 { data.soilMoisture[6] = v }
        if let v = obs.soilhum7 { data.soilMoisture[7] = v }
        if let v = obs.soilhum8 { data.soilMoisture[8] = v }
        if let v = obs.soilhum9 { data.soilMoisture[9] = v }
        if let v = obs.soilhum10 { data.soilMoisture[10] = v }

        // Leak sensors
        if let v = obs.leak1 { data.leakDetected[1] = v == 1 }
        if let v = obs.leak2 { data.leakDetected[2] = v == 1 }
        if let v = obs.leak3 { data.leakDetected[3] = v == 1 }
        if let v = obs.leak4 { data.leakDetected[4] = v == 1 }

        // Battery status
        // Ambient uses 0 = low, 1 = ok for most sensors; lightning is inverted (1 = low)
        if let v = obs.battOut { data.batteries["outdoor"] = v == 0 ? .low : .ok }
        if let v = obs.battIn { data.batteries["indoor"] = v == 0 ? .low : .ok }
        if let v = obs.battLightning { data.batteries["lightning"] = v == 1 ? .low : .ok }
        if let v = obs.batt_co2 { data.batteries["co2"] = v == 0 ? .low : .ok }
        if let v = obs.battRain { data.batteries["rain"] = v == "0" ? .low : .ok }
        if let v = obs.batt_cellgateway { data.batteries["cellgateway"] = v == 0 ? .low : .ok }

        // Soil moisture sensor batteries
        if let v = obs.battsm1 { data.batteries["soil1"] = v == 0 ? .low : .ok }
        if let v = obs.battsm2 { data.batteries["soil2"] = v == 0 ? .low : .ok }
        if let v = obs.battsm3 { data.batteries["soil3"] = v == 0 ? .low : .ok }
        if let v = obs.battsm4 { data.batteries["soil4"] = v == 0 ? .low : .ok }

        // Leak sensor batteries
        if let v = obs.batleak1 { data.batteries["leak1"] = v == 0 ? .low : .ok }
        if let v = obs.batleak2 { data.batteries["leak2"] = v == 0 ? .low : .ok }
        if let v = obs.batleak3 { data.batteries["leak3"] = v == 0 ? .low : .ok }
        if let v = obs.batleak4 { data.batteries["leak4"] = v == 0 ? .low : .ok }

        return data
    }
}
