//
//  LeakDetectionPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Panel displaying water leak sensor status (Dry/Wet) with color coding
struct LeakDetectionPanel: View {
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?
    @Environment(\.dashboardTheme) private var theme

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

    private var leakSensors: [(name: String, isWet: Bool)] {
        if let porchData {
            return porchData.leakDetected
                .sorted { $0.key < $1.key }
                .map { ("Leak Sensor \($0.key)", $0.value) }
        } else if let observation {
            var sensors: [(String, Bool)] = []
            if let v = observation.leak1 { sensors.append(("Leak Sensor 1", v == 1)) }
            if let v = observation.leak2 { sensors.append(("Leak Sensor 2", v == 1)) }
            if let v = observation.leak3 { sensors.append(("Leak Sensor 3", v == 1)) }
            if let v = observation.leak4 { sensors.append(("Leak Sensor 4", v == 1)) }
            return sensors
        }
        return []
    }

    var body: some View {
        if !leakSensors.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "drop.triangle.fill")
                        .foregroundStyle(theme.leakColor)
                    Text("Leak Detection")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }

                ForEach(leakSensors, id: \.name) { sensor in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(sensor.isWet ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        Text(sensor.name)
                            .font(.callout)
                            .foregroundStyle(theme.primaryText)
                        Spacer()
                        Text(sensor.isWet ? "WET" : "Dry")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(sensor.isWet ? .red : .green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((sensor.isWet ? Color.red : Color.green).opacity(0.15), in: Capsule())
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }
}
