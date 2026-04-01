//
//  LaCrosseCloudAdapter.swift
//  Porch
//
//  Stub adapter for La Crosse Technology stations via the La Crosse View cloud API.
//  Actual API integration to be implemented in a future update.
//

import Foundation
import PorchStationKit

@MainActor
final class LaCrosseCloudAdapter: StationAdapter, @unchecked Sendable {

    // MARK: - StationAdapter Identity

    static let brand: StationBrand = .lacrosse
    static let connectionType: ConnectionType = .cloud

    static let supportedModels: [StationModel] = [
        StationModel(
            id: "lacrosse-v40-pro",
            brand: .lacrosse,
            name: "V40-PRO",
            connectionTypes: [.cloud],
            capabilities: .basic
        ),
        StationModel(
            id: "lacrosse-v50",
            brand: .lacrosse,
            name: "V50 / C83100",
            connectionTypes: [.cloud],
            capabilities: .basic
        ),
        StationModel(
            id: "lacrosse-s81120",
            brand: .lacrosse,
            name: "S81120 Wi-Fi",
            connectionTypes: [.cloud],
            capabilities: .basic
        )
    ]

    static let configurationFields: [ConfigurationField] = [
        ConfigurationField(id: "apiKey", label: "API Token", placeholder: "Your La Crosse View API token", isSecure: true),
        ConfigurationField(id: "deviceID", label: "Device ID", placeholder: "Your device ID", isRequired: false)
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
        statusContinuation?.yield(.failed("La Crosse Technology support coming soon"))
    }

    func disconnect() {
        isConnected = false
        statusContinuation?.yield(.disconnected)
    }
}
