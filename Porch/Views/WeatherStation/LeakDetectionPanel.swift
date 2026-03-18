//
//  LeakDetectionPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI
import AmbientWeather

/// Panel displaying water leak sensor status (Dry/Wet) with color coding
struct LeakDetectionPanel: View {
    let observation: AmbientLastData

    private var leakSensors: [(name: String, value: Int)] {
        var sensors: [(String, Int)] = []
        if let v = observation.leak1 { sensors.append(("Leak Sensor 1", v)) }
        if let v = observation.leak2 { sensors.append(("Leak Sensor 2", v)) }
        if let v = observation.leak3 { sensors.append(("Leak Sensor 3", v)) }
        if let v = observation.leak4 { sensors.append(("Leak Sensor 4", v)) }
        return sensors
    }

    var body: some View {
        if !leakSensors.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "drop.triangle.fill")
                        .foregroundStyle(.blue)
                    Text("Leak Detection")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }

                ForEach(leakSensors, id: \.name) { sensor in
                    let isWet = sensor.value == 1
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isWet ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        Text(sensor.name)
                            .font(.callout)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(isWet ? "WET" : "Dry")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(isWet ? .red : .green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((isWet ? Color.red : Color.green).opacity(0.15), in: Capsule())
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }
}
