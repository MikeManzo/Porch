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
    var yFloorZero: Bool = false
    var showGlass: Bool = true

    @EnvironmentObject var manager: WeatherManager
    @State private var timeRange: ChartTimeRange = .day
    @State private var snapshots: [WeatherSnapshot] = []
    @State private var isExpanded = true
    @State private var selectedDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tappable header
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 10)

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

                if let selected = selectedPoint {
                    Text("\(selected.value, specifier: "%.1f")\(unitSuffix)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(color)
                        .frame(width: 80, alignment: .trailing)
                        .contentTransition(.numericText())
                } else if let latest = primaryData.last?.value {
                    Text("\(latest, specifier: "%.1f")\(unitSuffix)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(color)
                        .frame(width: 80, alignment: .trailing)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                // Inline time range picker
                HStack {
                    Spacer()
                    Picker("Range", selection: $timeRange) {
                        ForEach(ChartTimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
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

                    // Scrub indicator
                    if let selected = selectedPoint {
                        RuleMark(x: .value("Selected", selected.timestamp))
                            .foregroundStyle(.white.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                        PointMark(
                            x: .value("Selected", selected.timestamp),
                            y: .value(title, selected.value)
                        )
                        .foregroundStyle(color)
                        .symbolSize(36)
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
                .chartXSelection(value: $selectedDate)
                .chartYScale(domain: yDomain)
                .chartPlotStyle { plotArea in
                    plotArea.clipped()
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        if let selected = selectedPoint,
                           let anchor = proxy.plotFrame,
                           let xPos = proxy.position(forX: selected.timestamp) {
                            let plotFrame = geometry[anchor]
                            let xClamped = min(max(xPos + plotFrame.origin.x, plotFrame.origin.x + 40), plotFrame.origin.x + plotFrame.width - 40)
                            VStack(spacing: 2) {
                                Text("\(selected.value, specifier: "%.1f")\(unitSuffix)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(color)
                                Text(selected.timestamp, format: .dateTime.hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 6))
                            .position(x: xClamped, y: plotFrame.origin.y - 16)
                        }
                    }
                }
                .frame(height: 120)
                }
            } // isExpanded
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .modifier(OptionalGlassModifier(enabled: showGlass))
        .onAppear { loadData() }
        .onDisappear { snapshots = [] }
        .onChange(of: timeRange) { loadData() }
    }

    // MARK: - Selection

    /// The nearest primary data point to the scrub position
    private var selectedPoint: (timestamp: Date, value: Double)? {
        guard let selectedDate else { return nil }
        return primaryData.min(by: {
            abs($0.timestamp.timeIntervalSince(selectedDate)) < abs($1.timestamp.timeIntervalSince(selectedDate))
        })
    }

    // MARK: - Y-Axis Domain

    /// Fixed Y domain from data so selection marks don't shift the scale
    private var yDomain: ClosedRange<Double> {
        let allValues = primaryData.map(\.value) + secondaryData.map(\.value)
        guard let lo = allValues.min(), let hi = allValues.max() else {
            return 0...1
        }
        let range = hi - lo
        let padding: Double
        if yFloorZero {
            padding = max(range * 0.1, 0.01)
            return 0...(hi + padding)
        } else {
            padding = max(range * 0.05, 0.5)
            return (lo - padding)...(hi + padding)
        }
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

/// Conditionally applies the standard glass effect used by trend charts
struct OptionalGlassModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.glassEffect(.regular, in: .rect(cornerRadius: 16))
        } else {
            content
        }
    }
}
