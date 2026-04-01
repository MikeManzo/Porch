//
//  AcuRiteCloudAdapter.swift
//  Porch
//
//  Stub adapter for AcuRite stations via the My AcuRite cloud API.
//  Actual API integration to be implemented in a future update.
//

import Foundation
import PorchStationKit

@MainActor
final class AcuRiteCloudAdapter: StationAdapter, @unchecked Sendable {

    // MARK: - StationAdapter Identity

    static let brand: StationBrand = .acurite
    static let connectionType: ConnectionType = .cloud

    static let supportedModels: [StationModel] = [
        StationModel(
            id: "acurite-atlas",
            brand: .acurite,
            name: "Atlas",
            connectionTypes: [.cloud],
            capabilities: .fullSuite
        ),
        StationModel(
            id: "acurite-iris",
            brand: .acurite,
            name: "Iris (5-in-1)",
            connectionTypes: [.cloud],
            capabilities: .basic
        ),
        StationModel(
            id: "acurite-notos",
            brand: .acurite,
            name: "Notos (3-in-1)",
            connectionTypes: [.cloud],
            capabilities: .basic
        )
    ]

    static let configurationFields: [ConfigurationField] = [
        ConfigurationField(id: "apiKey", label: "API Key", placeholder: "Your My AcuRite API key", isSecure: true),
        ConfigurationField(id: "deviceID", label: "Device ID", placeholder: "Your AcuRite device ID", isRequired: false)
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
        statusContinuation?.yield(.failed("AcuRite support coming soon"))
    }

    func disconnect() {
        isConnected = false
        statusContinuation?.yield(.disconnected)
    }
}
