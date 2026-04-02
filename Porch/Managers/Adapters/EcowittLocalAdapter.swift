//
//  EcowittLocalAdapter.swift
//  Porch
//
//  Concrete StationAdapter that connects to Ecowitt gateways via LAN HTTP polling.
//  Wraps the existing EcowittLocal package and converts data to PorchWeatherData.
//

import Foundation
import Combine
import EcowittLocal
import PorchStationKit

@MainActor
final class EcowittLocalAdapter: StationAdapter, @unchecked Sendable {

    // MARK: - StationAdapter Identity

    static let brand: StationBrand = .ecowitt
    static let connectionType: ConnectionType = .local

    static let supportedModels: [StationModel] = [
        StationModel(
            id: "ecowitt-gw2000",
            brand: .ecowitt,
            name: "GW2000 / GW1100",
            connectionTypes: [.local],
            capabilities: .fullSuite
        ),
        StationModel(
            id: "ecowitt-hp2551",
            brand: .ecowitt,
            name: "HP2551 / HP3501",
            connectionTypes: [.local],
            capabilities: .fullSuite
        )
    ]

    static let configurationFields: [ConfigurationField] = [
        ConfigurationField(id: "host", label: "IP Address", placeholder: "192.168.1.100"),
        ConfigurationField(id: "port", label: "Port", placeholder: "80", isRequired: false),
        ConfigurationField(id: "stationName", label: "Station Name", placeholder: "My Ecowitt", isRequired: false),
        ConfigurationField(id: "latitude", label: "Latitude", placeholder: "40.7128", isRequired: false),
        ConfigurationField(id: "longitude", label: "Longitude", placeholder: "-74.0060", isRequired: false)
    ]

    // MARK: - State

    private let client = EcowittClient()
    private var observationContinuation: AsyncStream<PorchWeatherData>.Continuation?
    private var statusContinuation: AsyncStream<StationConnectionStatus>.Continuation?
    private var configuration: StationConfiguration?
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

    // MARK: - Discovery

    nonisolated func discover() async -> [DiscoveredStation] {
        guard let subnet = Self.localSubnet() else { return [] }

        var found: [DiscoveredStation] = []
        let batchSize = 20

        for batchStart in stride(from: 1, through: 254, by: batchSize) {
            let batchEnd = min(batchStart + batchSize - 1, 254)
            let ips = (batchStart...batchEnd).map { "\(subnet).\($0)" }

            await withTaskGroup(of: DiscoveredStation?.self) { group in
                for ip in ips {
                    group.addTask {
                        await Self.probeForDiscovery(ip: ip)
                    }
                }
                for await result in group {
                    if let station = result {
                        found.append(station)
                    }
                }
            }
        }

        return found
    }

    // MARK: - Connection

    func connect(configuration: StationConfiguration) async throws {
        guard let host = configuration.host, !host.isEmpty else {
            statusContinuation?.yield(.failed("No host configured"))
            return
        }

        self.configuration = configuration
        let port = configuration.port ?? 80

        statusContinuation?.yield(.connecting)

        // Observe EcowittClient status changes via Combine
        client.$connectionStatus
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

        // Observe live data and convert
        client.$liveData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ecowittData in
                guard let self else { return }
                let porchData = self.convert(ecowittData)
                self.observationContinuation?.yield(porchData)
            }
            .store(in: &cancellables)

        client.connect(host: host, port: port)
    }

    func disconnect() {
        cancellables.removeAll()
        client.disconnect()
        isConnected = false
        statusContinuation?.yield(.disconnected)
    }

    // MARK: - Data Conversion

    private func convert(_ ecowitt: EcowittLiveData) -> PorchWeatherData {
        let config = configuration ?? StationConfiguration()

        var data = PorchWeatherData(
            stationID: "ecowitt-\(config.host ?? "local")",
            stationName: config.stationName ?? "Ecowitt Gateway",
            brand: .ecowitt,
            timestamp: ecowitt.timestamp
        )

        if let lat = config.latitude, let lon = config.longitude {
            data.location = StationLocation(latitude: lat, longitude: lon)
        }

        // Outdoor
        data.temperatureF = ecowitt.outdoorTemp
        data.humidity = ecowitt.outdoorHumidity.map { Int($0) }
        data.dewPointF = ecowitt.dewPoint
        data.feelsLikeF = ecowitt.feelsLike

        // Indoor
        data.indoorTempF = ecowitt.indoorTemp
        data.indoorHumidity = ecowitt.indoorHumidity.map { Int($0) }

        // Wind
        data.windSpeedMPH = ecowitt.windSpeed
        data.windGustMPH = ecowitt.windGust
        data.windDirection = ecowitt.windDir.map { Int($0) }
        data.maxDailyGustMPH = ecowitt.maxDailyGust

        // Pressure
        data.pressureRelativeInHg = ecowitt.pressureRelative
        data.pressureAbsoluteInHg = ecowitt.pressureAbsolute

        // Rain
        data.rainRateInPerHr = ecowitt.rainRate
        data.eventRainIn = ecowitt.rainEvent
        data.dailyRainIn = ecowitt.dailyRain
        data.weeklyRainIn = ecowitt.weeklyRain
        data.monthlyRainIn = ecowitt.monthlyRain
        data.yearlyRainIn = ecowitt.yearlyRain

        // Solar & UV
        data.solarRadiation = ecowitt.solarRadiation
        data.uvIndex = ecowitt.uvIndex.map { Int($0) }

        // Lightning
        data.lightningDistanceMi = ecowitt.lightningDistance
        data.lightningTime = ecowitt.lightningTime.map {
            Date(timeIntervalSince1970: TimeInterval($0) / 1000.0)
        }
        data.lightningDayCount = ecowitt.lightningDayCount.map { Int($0) }

        // Air Quality
        data.pm25 = ecowitt.pm25
        data.co2 = ecowitt.co2.map { Int($0) }

        // Soil
        for (ch, temp) in ecowitt.soilTemp {
            data.soilTempF[ch] = temp
        }
        for (ch, moisture) in ecowitt.soilMoisture {
            data.soilMoisture[ch] = Int(moisture)
        }

        // Leak
        for (ch, status) in ecowitt.leakSensors {
            data.leakDetected[ch] = status == 1
        }

        // Batteries
        // Outdoor sensor — battery is reported on a common_list item (varies by firmware;
        // could be windDirection, outdoorTemp, etc.). Any "common_*" key is the outdoor array battery.
        if let outdoorBatt = ecowitt.batteries.first(where: { $0.key.hasPrefix("common_") }) {
            data.batteries["outdoor"] = outdoorBatt.value == 0 ? .low : .ok
        }
        if let v = ecowitt.batteries["rain"] {
            data.batteries["rain"] = v == 0 ? .low : .ok
        }
        if let v = ecowitt.batteries["lightning"] {
            data.batteries["lightning"] = v == 1 ? .low : .ok  // inverted
        }
        if let v = ecowitt.batteries["co2"] {
            data.batteries["co2"] = v == 0 ? .low : .ok
        }
        // Multi-channel temp/humidity sensor batteries
        for ch in 1...8 {
            if let v = ecowitt.batteries["ch\(ch)"] {
                data.batteries["ch\(ch)"] = v == 0 ? .low : .ok
            }
        }
        for ch in 1...4 {
            if let v = ecowitt.batteries["leak\(ch)"] {
                data.batteries["leak\(ch)"] = v == 0 ? .low : .ok
            }
        }
        for ch in 1...8 {
            if let v = ecowitt.batteries["soil\(ch)"] {
                data.batteries["soil\(ch)"] = v == 0 ? .low : .ok
            }
        }

        return data
    }

    // MARK: - Network Helpers

    private nonisolated static func probeForDiscovery(ip: String, port: Int = 80) async -> DiscoveredStation? {
        guard let url = URL(string: "http://\(ip):\(port)/get_livedata_info") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["common_list"] != nil || json["wh25"] != nil else { return nil }

            let model = json["piezoRain"] != nil ? "Ecowitt (Piezo)" :
                        json["co2"] != nil ? "Ecowitt (CO2)" : "Ecowitt Gateway"

            return DiscoveredStation(
                id: ip,
                name: model,
                brand: .ecowitt,
                host: ip,
                port: port
            )
        } catch {
            return nil
        }
    }

    private nonisolated static func localSubnet() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var result: String?
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr

        while let addr = ptr {
            let flags = Int32(addr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            if isUp && !isLoopback,
               addr.pointee.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: addr.pointee.ifa_name)
                if name.hasPrefix("en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addr.pointee.ifa_addr, socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, 0, NI_NUMERICHOST) == 0 {
                        let ip: String
                        if let nullIndex = hostname.firstIndex(of: 0) {
                            ip = String(decoding: hostname[..<nullIndex].map { UInt8(bitPattern: $0) }, as: UTF8.self)
                        } else {
                            ip = String(decoding: hostname.map { UInt8(bitPattern: $0) }, as: UTF8.self)
                        }
                        let components = ip.split(separator: ".")
                        if components.count == 4 {
                            result = "\(components[0]).\(components[1]).\(components[2])"
                            if name == "en0" { break }
                        }
                    }
                }
            }
            ptr = addr.pointee.ifa_next
        }

        return result
    }
}
