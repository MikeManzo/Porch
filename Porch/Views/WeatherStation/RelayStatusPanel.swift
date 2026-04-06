//
//  RelayStatusPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI
import AmbientWeather

/// Panel displaying smart relay On/Off status
struct RelayStatusPanel: View {
    let observation: AmbientLastData
    @Environment(\.dashboardTheme) private var theme

    private var relays: [(name: String, value: Int)] {
        var items: [(String, Int)] = []
        if let v = observation.relay1 { items.append(("Relay 1", v)) }
        if let v = observation.relay2 { items.append(("Relay 2", v)) }
        if let v = observation.relay3 { items.append(("Relay 3", v)) }
        if let v = observation.relay4 { items.append(("Relay 4", v)) }
        if let v = observation.relay5 { items.append(("Relay 5", v)) }
        if let v = observation.relay6 { items.append(("Relay 6", v)) }
        if let v = observation.relay7 { items.append(("Relay 7", v)) }
        if let v = observation.relay8 { items.append(("Relay 8", v)) }
        if let v = observation.relay9 { items.append(("Relay 9", v)) }
        if let v = observation.relay10 { items.append(("Relay 10", v)) }
        return items
    }

    var body: some View {
        if !relays.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "app.connected.to.app.below.fill")
                        .foregroundStyle(theme.relayColor)
                    Text("Relays")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6)
                ], spacing: 6) {
                    ForEach(relays, id: \.name) { relay in
                        let isOn = relay.value == 1
                        HStack(spacing: 8) {
                            Circle()
                                .fill(isOn ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(relay.name)
                                .font(.caption)
                                .foregroundStyle(theme.primaryText)
                            Spacer()
                            Text(isOn ? "ON" : "OFF")
                                .font(.system(.caption2, design: .rounded, weight: .semibold))
                                .foregroundStyle(isOn ? .green : .gray)
                        }
                        .padding(8)
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }
}
