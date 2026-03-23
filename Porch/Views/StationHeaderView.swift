//
//  StationHeaderView.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather

struct StationHeaderView: View {
    let stationName: String
    let stationLocation: String
    let status: SocketStatus
    var activeSource: ActiveSource = .none

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stationName)
                    .font(.headline)
                if !stationLocation.isEmpty {
                    Text(stationLocation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .font(.system(size: 10))
                .help(statusHelpText)
        }
        .padding(12)
    }

    private var statusIcon: String {
        switch activeSource {
        case .ambient: "cloud.fill"
        case .ecowitt: "point.3.filled.connected.trianglepath.dotted"
        case .none: "circle.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .connected:    .green
        case .connecting:   .orange
        case .disconnected: .red
        }
    }

    private var statusHelpText: String {
        switch (status, activeSource) {
        case (.connected, .ambient):  "Connected via Cloud"
        case (.connected, .ecowitt):  "Connected via Local"
        case (.connected, .none):     "Connected"
        case (.connecting, _):        "Connecting..."
        case (.disconnected, _):      "Disconnected"
        }
    }
}
