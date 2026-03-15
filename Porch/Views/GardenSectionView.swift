//
//  GardenSectionView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather

/// Conditional section showing soil, leaf, and agricultural sensor data.
/// Uses category-based sensor lookup since the package's helper arrays are internal.
struct GardenSectionView: View {
    let observation: AmbientLastData
    @EnvironmentObject var manager: WeatherManager

    /// Garden-related sensor categories
    private static let gardenCategories: Set<SensorCategory> = [
        .soilTemperature, .soilMoisture, .soilTension, .leafWetness, .agriculturalDerived
    ]

    /// Extract garden sensors from the categorized sensor list
    private var gardenSensors: [(SensorCategory, [String])] {
        observation.availableSensorsbyCategorySorted.filter {
            Self.gardenCategories.contains($0.0)
        }
    }

    var body: some View {
        if !gardenSensors.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Garden & Soil", systemImage: "leaf.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(gardenSensors, id: \.0) { _, keys in
                        ForEach(keys, id: \.self) { key in
                            gardenTile(key: key)
                        }
                    }
                }
            }
        }
    }

    private func gardenTile(key: String) -> some View {
        return HStack(spacing: 8) {
            Image(systemName: tintIcon(for: key))
                .font(.caption)
                .foregroundStyle(tintColor(for: key))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(SensorFormatter.menuBarString(for: key, from: observation, unitSystem: manager.unitSystem))
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
        if lowered.contains("soilhum") { return "drop.fill" }
        if lowered.contains("soiltens") { return "arrow.down.to.line" }
        if lowered.contains("leafwet") { return "leaf.fill" }
        if lowered.contains("gdd") { return "sun.horizon.fill" }
        if lowered.contains("et") { return "drop.triangle.fill" }
        return "leaf"
    }

    private func tintColor(for key: String) -> Color {
        let lowered = key.lowercased()
        if lowered.contains("soiltemp") { return .orange }
        if lowered.contains("soilhum") { return .brown }
        if lowered.contains("soiltens") { return .brown }
        if lowered.contains("leafwet") { return .green }
        if lowered.contains("gdd") || lowered.contains("et") { return .teal }
        return .green
    }
}
