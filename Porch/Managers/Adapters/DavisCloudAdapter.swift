//
//  DavisCloudAdapter.swift
//  Porch
//
//  Stub adapter for Davis Instruments stations via the WeatherLink Cloud API.
//  Actual API integration to be implemented in a future update.
//

import Foundation
import PorchStationKit

@MainActor
final class DavisCloudAdapter: StationAdapter, @unchecked Sendable {

    // MARK: - StationAdapter Identity

    static let brand: StationBrand = .davis
    static let connectionType: ConnectionType = .cloud

    static let supportedModels: [StationModel] = [
        StationModel(
            id: "davis-vantage-vue",
            brand: .davis,
            name: "Vantage Vue",
            connectionTypes: [.cloud],
            capabilities: .basic
        ),
        StationModel(
            id: "davis-vantage-pro2",
            brand: .davis,
            name: "Vantage Pro2",
            connectionTypes: [.cloud],
            capabilities: .fullSuite
        ),
        StationModel(
            id: "davis-vantage-pro2-plus",
            brand: .davis,
            name: "Vantage Pro2 Plus",
            connectionTypes: [.cloud],
            capabilities: .fullSuite
        )
    ]

    static let configurationFields: [ConfigurationField] = [
        ConfigurationField(id: "apiKey", label: "WeatherLink API Key", placeholder: "Your WeatherLink v2 API key", isSecure: true),
        ConfigurationField(id: "applicationKey", label: "API Secret", placeholder: "Your WeatherLink v2 API secret", isSecure: true),
        ConfigurationField(id: "deviceID", label: "Station ID", placeholder: "Your station ID", isRequired: false)
    ]

    // MARK: - State

    private var observationContinuation: AsyncStream<PorchWeatherData>.Continuation?
    private var statusContinuation: AsyncStream<StationConnectionStatus>.Continuation?

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
        statusContinuation?.yield(.failed("Davis WeatherLink support coming soon"))
    }

    func disconnect() {
        isConnected = false
        statusContinuation?.yield(.disconnected)
    }
}
