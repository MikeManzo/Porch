//
//  GardenSectionView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Conditional section showing soil, leaf, and agricultural sensor data.
struct GardenSectionView: View {
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?
    @EnvironmentObject var manager: WeatherManager

    /// Init from PorchWeatherData (new path)
    init(porchData: PorchWeatherData) {
        self.porchData = porchData
        self.observation = nil
    }

    /// Init from AmbientLastData (legacy path)
    init(observation: AmbientLastData) {
        self.observation = observation
        self.porchData = nil
    }

    /// Garden-related PorchStationKit sensor categories
    private static let porchGardenCategories: Set<PorchStationKit.SensorCategory> = [
        .soilTemperature, .soilMoisture
    ]

    /// Garden-related AmbientWeather sensor categories
    private static let ambientGardenCategories: Set<AmbientWeather.SensorCategory> = [
        .soilTemperature, .soilMoisture, .soilTension, .leafWetness, .agriculturalDerived
    ]

    /// Extract garden sensors from PorchWeatherData
    private var porchGardenSensors: [(PorchStationKit.SensorCategory, [String])] {
        porchData?.availableSensorsByCategory.filter {
            Self.porchGardenCategories.contains($0.0)
        } ?? []
    }

    /// Extract garden sensors from AmbientLastData
    private var ambientGardenSensors: [(AmbientWeather.SensorCategory, [String])] {
        observation?.availableSensorsbyCategorySorted.filter {
            Self.ambientGardenCategories.contains($0.0)
        } ?? []
    }

    private var hasData: Bool {
        !porchGardenSensors.isEmpty || !ambientGardenSensors.isEmpty
    }

    var body: some View {
        if hasData {
            VStack(alignment: .leading, spacing: 6) {
                Label("Garden & Soil", systemImage: "leaf.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    if let porchData {
                        ForEach(porchGardenSensors, id: \.0) { _, keys in
                            ForEach(keys, id: \.self) { key in
                                gardenTilePorch(key: key, data: porchData)
                            }
                        }
                    } else if let observation {
                        ForEach(ambientGardenSensors, id: \.0) { _, keys in
                            ForEach(keys, id: \.self) { key in
                                gardenTileAmbient(key: key, obs: observation)
                            }
                        }
                    }
                }
            }
        }
    }

    private func gardenTilePorch(key: String, data: PorchWeatherData) -> some View {
        HStack(spacing: 8) {
            Image(systemName: tintIcon(for: key))
                .font(.caption)
                .foregroundStyle(tintColor(for: key))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(SensorFormatter.menuBarString(for: key, from: data, unitSystem: manager.unitSystem))
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func gardenTileAmbient(key: String, obs: AmbientLastData) -> some View {
        HStack(spacing: 8) {
            Image(systemName: tintIcon(for: key))
                .font(.caption)
                .foregroundStyle(tintColor(for: key))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(SensorFormatter.menuBarString(for: key, from: obs, unitSystem: manager.unitSystem))
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func tintIcon(for key: String) -> String {
        let lowered = key.lowercased()
        if lowered.contains("soiltemp") { return "thermometer.medium" }
        if lowered.contains("soilhum") || lowered.contains("soilmoisture") { return "drop.fill" }
        if lowered.contains("soiltens") { return "arrow.down.to.line" }
        if lowered.contains("leafwet") { return "leaf.fill" }
        if lowered.contains("gdd") { return "sun.horizon.fill" }
        if lowered.contains("et") { return "drop.triangle.fill" }
        return "leaf"
    }

    private func tintColor(for key: String) -> Color {
        let lowered = key.lowercased()
        if lowered.contains("soiltemp") { return .orange }
        if lowered.contains("soilhum") || lowered.contains("soilmoisture") { return .brown }
        if lowered.contains("soiltens") { return .brown }
        if lowered.contains("leafwet") { return .green }
        if lowered.contains("gdd") || lowered.contains("et") { return .teal }
        return .green
    }
}
