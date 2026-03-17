//
//  GardenPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather

/// Panel displaying soil temperature, moisture, tension, and leaf wetness sensors
struct GardenPanel: View {
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

    /// Only show when garden sensor data exists
    var hasData: Bool { !gardenSensors.isEmpty }

    var body: some View {
        if hasData {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                    Text("Garden & Soil")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6)
                ], spacing: 6) {
                    ForEach(gardenSensors, id: \.0) { _, keys in
                        ForEach(keys, id: \.self) { key in
                            gardenTile(key: key)
                        }
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }

    // MARK: - Tile

    private func gardenTile(key: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: tintIcon(for: key))
                .font(.caption)
                .foregroundStyle(tintColor(for: key))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                Text(SensorFormatter.menuBarString(for: key, from: observation, unitSystem: manager.unitSystem))
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Icons & Colors

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
