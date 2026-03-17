//
//  TrendChartView.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import Charts

/// Time range options for trend charts
enum ChartTimeRange: String, CaseIterable {
    case day = "24H"
    case threeDays = "3D"
    case week = "7D"
}

/// An optional second data series overlaid on the same chart
struct SecondarySeries {
    let label: String
    let valuePath: KeyPath<WeatherSnapshot, Double?>
    let color: Color
    var convertToMetric: ((Double) -> Double)? = nil
}

/// A generic trend chart that plots a WeatherSnapshot metric over time using Swift Charts.
/// Each chart manages its own time range and data loading.
/// Supports an optional secondary series for indoor/outdoor overlays.
struct TrendChartView: View {
    let title: String
    let icon: String
    let valuePath: KeyPath<WeatherSnapshot, Double?>
    let unitSuffix: String
    let color: Color
    let unitSystem: UnitSystem
    var convertToMetric: ((Double) -> Double)? = nil
    var secondary: SecondarySeries? = nil

    @EnvironmentObject var manager: WeatherManager
    @State private var timeRange: ChartTimeRange = .day
    @State private var snapshots: [WeatherSnapshot] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header with inline range picker
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                // Legend for secondary series
                if let sec = secondary {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Circle().fill(sec.color).frame(width: 6, height: 6)
                    Text(sec.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Inline time range picker
                Picker("Range", selection: $timeRange) {
                    ForEach(ChartTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)

                if let latest = primaryData.last?.value {
                    Text("\(latest, specifier: "%.1f")\(unitSuffix)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(color)
                        .frame(width: 80, alignment: .trailing)
                }
            }

            if primaryData.isEmpty {
                Text("Collecting data…")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else {
                // Chart
                Chart {
                    // Primary series
                    ForEach(primaryData, id: \.timestamp) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value(title, point.value),
                            series: .value("Series", "Primary")
                        )
                        .foregroundStyle(color.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value(title, point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color.opacity(0.25), color.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    // Secondary series (if present)
                    if let sec = secondary {
                        ForEach(secondaryData, id: \.timestamp) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value(title, point.value),
                                series: .value("Series", "Secondary")
                            )
                            .foregroundStyle(sec.color)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) {
                        AxisValueLabel(format: xAxisFormat)
                            .foregroundStyle(.secondary)
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(.white.opacity(0.08))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(.white.opacity(0.08))
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 120)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .onAppear { loadData() }
        .onChange(of: timeRange) { loadData() }
    }

    // MARK: - X-Axis Format

    private var xAxisFormat: Date.FormatStyle {
        switch timeRange {
        case .day:
            .dateTime.hour()
        case .threeDays, .week:
            .dateTime.weekday(.abbreviated)
        }
    }

    // MARK: - Data Loading

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

    // MARK: - Data Processing

    private var primaryData: [(timestamp: Date, value: Double)] {
        processData(path: valuePath, converter: convertToMetric)
    }

    private var secondaryData: [(timestamp: Date, value: Double)] {
        guard let sec = secondary else { return [] }
        return processData(path: sec.valuePath, converter: sec.convertToMetric)
    }

    private func processData(path: KeyPath<WeatherSnapshot, Double?>, converter: ((Double) -> Double)?) -> [(timestamp: Date, value: Double)] {
        let raw: [(timestamp: Date, value: Double)] = snapshots.compactMap { snapshot in
            guard var value = snapshot[keyPath: path] else { return nil }
            if let convert = converter, unitSystem == .metric {
                value = convert(value)
            }
            return (timestamp: snapshot.timestamp, value: value)
        }
        if raw.count > 2000 {
            return downsample(raw, targetCount: 500)
        }
        return raw
    }

    /// Reduce data points by averaging within time buckets
    private func downsample(_ data: [(timestamp: Date, value: Double)], targetCount: Int) -> [(timestamp: Date, value: Double)] {
        guard data.count > targetCount, let first = data.first, let last = data.last else { return data }
        let totalInterval = last.timestamp.timeIntervalSince(first.timestamp)
        let bucketSize = totalInterval / Double(targetCount)
        var result: [(timestamp: Date, value: Double)] = []
        var bucketStart = first.timestamp
        var bucketValues: [Double] = []
        var bucketTimestamps: [Date] = []

        for point in data {
            if point.timestamp.timeIntervalSince(bucketStart) < bucketSize {
                bucketValues.append(point.value)
                bucketTimestamps.append(point.timestamp)
            } else {
                if !bucketValues.isEmpty {
                    let avg = bucketValues.reduce(0, +) / Double(bucketValues.count)
                    let midIndex = bucketTimestamps.count / 2
                    result.append((timestamp: bucketTimestamps[midIndex], value: avg))
                }
                bucketStart = point.timestamp
                bucketValues = [point.value]
                bucketTimestamps = [point.timestamp]
            }
        }
        if !bucketValues.isEmpty {
            let avg = bucketValues.reduce(0, +) / Double(bucketValues.count)
            let midIndex = bucketTimestamps.count / 2
            result.append((timestamp: bucketTimestamps[midIndex], value: avg))
        }
        return result
    }
}
