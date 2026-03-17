//
//  TrendChartView.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import Charts

/// A generic trend chart that plots a WeatherSnapshot metric over time using Swift Charts
struct TrendChartView: View {
    let title: String
    let icon: String
    let snapshots: [WeatherSnapshot]
    let valuePath: KeyPath<WeatherSnapshot, Double?>
    let unitSuffix: String
    let color: Color
    let unitSystem: UnitSystem
    var convertToMetric: ((Double) -> Double)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if let latest = chartData.last?.value {
                    Text("\(latest, specifier: "%.1f")\(unitSuffix)")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(color)
                }
            }

            if chartData.isEmpty {
                Text("Collecting data…")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
            } else {
                // Chart
                Chart {
                    ForEach(chartData, id: \.timestamp) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value(title, point.value)
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
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) {
                        AxisValueLabel(format: .dateTime.hour())
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
                .frame(height: 120)
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Data Processing

    private var chartData: [(timestamp: Date, value: Double)] {
        let raw: [(timestamp: Date, value: Double)] = snapshots.compactMap { snapshot in
            guard var value = snapshot[keyPath: valuePath] else { return nil }
            if let convert = convertToMetric, unitSystem == .metric {
                value = convert(value)
            }
            return (timestamp: snapshot.timestamp, value: value)
        }
        // Downsample if too many points for smooth rendering
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
        // Final bucket
        if !bucketValues.isEmpty {
            let avg = bucketValues.reduce(0, +) / Double(bucketValues.count)
            let midIndex = bucketTimestamps.count / 2
            result.append((timestamp: bucketTimestamps[midIndex], value: avg))
        }
        return result
    }
}
