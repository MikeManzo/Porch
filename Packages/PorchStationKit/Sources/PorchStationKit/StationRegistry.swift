//
//  StationRegistry.swift
//  PorchStationKit
//
//  Central registry that tracks available station adapters.
//  The app registers adapters at launch; the registry provides
//  lookup by brand, model, or connection type.
//

import Foundation

/// Manages available station adapter types.
///
/// Usage:
/// ```swift
/// // At app launch, register all shipped adapters:
/// StationRegistry.shared.register(EcowittLocalAdapter.self)
/// StationRegistry.shared.register(AmbientCloudAdapter.self)
///
/// // Later, find adapters for a brand:
/// let adapters = StationRegistry.shared.adapters(for: .ecowitt)
/// ```
public final class StationRegistry: @unchecked Sendable {

    public static let shared = StationRegistry()

    /// A factory closure that creates a new adapter instance
    public typealias AdapterFactory = @Sendable () -> any StationAdapter

    private struct Registration {
        let brand: StationBrand
        let connectionType: ConnectionType
        let supportedModels: [StationModel]
        let configurationFields: [ConfigurationField]
        let factory: AdapterFactory
    }

    private var registrations: [Registration] = []
    private let lock = NSLock()

    private init() {}

    // MARK: - Registration

    /// Register a station adapter type. Call once per adapter at app launch.
    public func register<T: StationAdapter>(_ adapterType: T.Type, factory: @escaping @Sendable () -> T) {
        lock.lock()
        defer { lock.unlock() }

        let registration = Registration(
            brand: adapterType.brand,
            connectionType: adapterType.connectionType,
            supportedModels: adapterType.supportedModels,
            configurationFields: adapterType.configurationFields,
            factory: factory
        )
        registrations.append(registration)
    }

    // MARK: - Lookup

    /// All registered brands
    public var availableBrands: [StationBrand] {
        lock.lock()
        defer { lock.unlock() }
        return Array(Set(registrations.map(\.brand))).sorted { $0.displayName < $1.displayName }
    }

    /// All registered adapters for a given brand
    public func adapters(for brand: StationBrand) -> [(connectionType: ConnectionType, factory: AdapterFactory)] {
        lock.lock()
        defer { lock.unlock() }
        return registrations
            .filter { $0.brand == brand }
            .map { ($0.connectionType, $0.factory) }
    }

    /// Create a new adapter instance for a specific brand and connection type
    public func createAdapter(brand: StationBrand, connectionType: ConnectionType) -> (any StationAdapter)? {
        lock.lock()
        defer { lock.unlock() }
        return registrations
            .first { $0.brand == brand && $0.connectionType == connectionType }?
            .factory()
    }

    /// All known models across all registered adapters
    public var allModels: [StationModel] {
        lock.lock()
        defer { lock.unlock() }
        return registrations.flatMap(\.supportedModels)
    }

    /// Configuration fields needed for a given brand + connection type
    public func configurationFields(brand: StationBrand, connectionType: ConnectionType) -> [ConfigurationField] {
        lock.lock()
        defer { lock.unlock() }
        return registrations
            .first { $0.brand == brand && $0.connectionType == connectionType }?
            .configurationFields ?? []
    }
}
