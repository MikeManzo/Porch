//
//  SensorTileView.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

struct SensorTileView: View {
    let sensorKey: String
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?
    @EnvironmentObject var manager: WeatherManager

    /// Convenience init for PorchWeatherData (new path)
    init(sensorKey: String, porchData: PorchWeatherData) {
        self.sensorKey = sensorKey
        self.porchData = porchData
        self.observation = nil
    }

    /// Convenience init for AmbientLastData (legacy path)
    init(sensorKey: String, observation: AmbientLastData) {
        self.sensorKey = sensorKey
        self.observation = observation
        self.porchData = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(formattedValue)
                .font(.system(.body, design: .rounded, weight: .medium))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var formattedValue: String {
        if let porchData {
            return SensorFormatter.menuBarString(for: sensorKey, from: porchData, unitSystem: manager.unitSystem)
        } else if let observation {
            return SensorFormatter.menuBarString(for: sensorKey, from: observation, unitSystem: manager.unitSystem)
        }
        return "--"
    }

    private var label: String {
        SensorFormatter.sensorDescription(for: sensorKey, unitSystem: manager.unitSystem)
    }
}
