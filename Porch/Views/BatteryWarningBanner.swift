//
//  BatteryWarningBanner.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Warning banner shown when any sensor has low battery
struct BatteryWarningBanner: View {
    let lowSensors: [String]

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "battery.0percent")
                .foregroundStyle(.red)
                .font(.caption)

            Text(batteryMessage)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 12)
    }

    private var batteryMessage: String {
        let names = lowSensors.map { key in
            // Try PorchWeatherData registry first, then fall back to Ambient
            let porchDesc = PorchWeatherData.sensorDescription(for: key)
            let desc = porchDesc != key ? porchDesc : (AmbientLastData.sensorDescriptions[key] ?? key)
            return desc
                .replacingOccurrences(of: "Battery", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        if names.count == 1 {
            return "Low battery: \(names[0])"
        }
        return "Low battery: \(names.count) sensors"
    }
}
