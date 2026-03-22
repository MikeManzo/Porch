//
//  EcowittScanner.swift
//  Porch
//
//  Scans the local network for Ecowitt gateways by probing each IP
//  on the subnet for the /get_livedata_info endpoint.
//

import SwiftUI
import Combine
import os.log

/// Represents a discovered Ecowitt gateway on the local network
struct DiscoveredGateway: Identifiable, Hashable {
    let id: String  // IP address
    let host: String
    let port: Int
    let model: String

    init(host: String, port: Int = 80, model: String = "Ecowitt Gateway") {
        self.id = host
        self.host = host
        self.port = port
        self.model = model
    }
}

/// Scans the local /24 subnet for Ecowitt gateways
@MainActor
class EcowittScanner: ObservableObject {

    @Published private(set) var discoveredGateways: [DiscoveredGateway] = []
    @Published private(set) var isScanning = false
    @Published private(set) var scanProgress: Double = 0

    private var scanTask: Task<Void, Never>?

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Porch",
        category: "EcowittScanner"
    )

    func startScan() {
        stopScan()
        discoveredGateways = []
        isScanning = true
        scanProgress = 0

        scanTask = Task {
            await performScan()
            isScanning = false
        }
    }

    func stopScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }

    // MARK: - Private

    private func performScan() async {
        guard let subnet = Self.localSubnet() else {
            Self.logger.warning("Could not determine local subnet")
            return
        }

        Self.logger.info("Scanning subnet \(subnet).0/24")

        let batchSize = 20
        let totalIPs = 254

        for batchStart in stride(from: 1, through: totalIPs, by: batchSize) {
            guard !Task.isCancelled else { return }

            let batchEnd = min(batchStart + batchSize - 1, totalIPs)
            let ips = (batchStart...batchEnd).map { "\(subnet).\($0)" }

            await withTaskGroup(of: DiscoveredGateway?.self) { group in
                for ip in ips {
                    group.addTask {
                        await Self.probeGateway(at: ip)
                    }
                }
                for await result in group {
                    if let gateway = result {
                        discoveredGateways.append(gateway)
                    }
                }
            }

            scanProgress = Double(batchEnd) / Double(totalIPs)
        }

        scanProgress = 1.0
        Self.logger.info("Scan complete. Found \(self.discoveredGateways.count) gateway(s)")
    }

    private static func probeGateway(at ip: String, port: Int = 80) async -> DiscoveredGateway? {
        guard let url = URL(string: "http://\(ip):\(port)/get_livedata_info") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["common_list"] != nil || json["wh25"] != nil else { return nil }

            let model = detectModel(from: json)
            return DiscoveredGateway(host: ip, port: port, model: model)
        } catch {
            return nil
        }
    }

    private static func detectModel(from json: [String: Any]) -> String {
        if json["piezoRain"] != nil {
            return "Ecowitt Gateway (Piezo)"
        }
        if json["co2"] != nil {
            return "Ecowitt Gateway (CO2)"
        }
        return "Ecowitt Gateway"
    }

    private static func localSubnet() -> String? {
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
