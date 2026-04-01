//
//  TempestCloudAdapter.swift
//  Porch
//
//  Stub adapter for WeatherFlow Tempest stations via the Tempest REST/WebSocket API.
//  Actual API integration to be implemented in a future update.
//

import Foundation
import PorchStationKit

@MainActor
final class TempestCloudAdapter: StationAdapter, @unchecked Sendable {

    // MARK: - StationAdapter Identity

    static let brand: StationBrand = .tempest
    static let connectionType: ConnectionType = .cloud

    static let supportedModels: [StationModel] = [
        StationModel(
            id: "tempest-weatherflow",
            brand: .tempest,
            name: "Tempest",
            connectionTypes: [.cloud, .local],
            capabilities: .fullSuite
        ),
        StationModel(
            id: "tempest-air-sky",
            brand: .tempest,
            name: "Air + Sky",
            connectionTypes: [.cloud],
            capabilities: .basic
        )
    ]

    static let configurationFields: [ConfigurationField] = [
        ConfigurationField(id: "accessToken", label: "Personal Access Token", placeholder: "Your Tempest access token", isSecure: true),
        ConfigurationField(id: "deviceID", label: "Station ID", placeholder: "Your Tempest station ID", isRequired: false)
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
        statusContinuation?.yield(.failed("WeatherFlow Tempest support coming soon"))
    }

    func disconnect() {
        isConnected = false
        statusContinuation?.yield(.disconnected)
    }
}
