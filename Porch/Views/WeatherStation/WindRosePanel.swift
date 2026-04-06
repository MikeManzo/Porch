//
//  WindRosePanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI

/// Glass panel wrapping WindRoseView with a time range picker and data loading
struct WindRosePanel: View {
    @EnvironmentObject var manager: WeatherManager
    @Environment(\.dashboardTheme) private var theme
    @State private var timeRange: ChartTimeRange = .day
    @State private var snapshots: [WeatherSnapshot] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with time range picker
            HStack {
                Image(systemName: "tornado")
                    .foregroundStyle(theme.windColor)
                Text("Wind Rose")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Picker("", selection: $timeRange) {
                    ForEach(ChartTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                //.frame(width: 120)
            }

            if snapshots.isEmpty {
                VStack {
                    Text("Collecting data…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(height: 240)
                .frame(maxWidth: .infinity)
            } else {
                WindRoseView(snapshots: snapshots)
                    .frame(width: 240, height: 240)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .onAppear { loadData() }
        .onDisappear { snapshots = [] }
        .onChange(of: timeRange) { loadData() }
    }

    private func loadData() {
        guard let stationID = manager.selectedStationID,
              let historyManager = manager.historyManager else { return }

        switch timeRange {
        case .day:
            snapshots = historyManager.fetchSnapshots(for: stationID, lastHours: 24)
        case .threeDays:
            snapshots = historyManager.fetchSnapshots(for: stationID, lastDays: 3)
        case .week:
            snapshots = historyManager.fetchSnapshots(for: stationID, lastDays: 7)
        }
    }
}
