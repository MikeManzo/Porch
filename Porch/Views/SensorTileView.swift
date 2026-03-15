//
//  SensorTileView.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather

struct SensorTileView: View {
    let sensorKey: String
    let observation: AmbientLastData

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(SensorFormatter.menuBarString(for: sensorKey, from: observation))
                .font(.system(.body, design: .rounded, weight: .medium))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var label: String {
        AmbientLastData.sensorDescriptions[sensorKey] ?? sensorKey
    }
}
