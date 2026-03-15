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

            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .help(status.rawValue.capitalized)
        }
        .padding(12)
    }

    private var statusColor: Color {
        switch status {
        case .connected:    .green
        case .connecting:   .orange
        case .disconnected: .red
        }
    }
}
