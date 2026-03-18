//
//  WindRoseView.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI

/// A polar chart showing wind direction distribution across 16 compass sectors,
/// color-coded by average wind speed: blue (calm) → green (light) → yellow (moderate) → red (high)
struct WindRoseView: View {
    let snapshots: [WeatherSnapshot]

    private let sectors = 16
    private let sectorLabels = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                                 "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]

    /// Per-sector data: count and average wind speed
    private struct SectorData {
        var count: Int = 0
        var totalSpeed: Double = 0

        var averageSpeed: Double {
            count > 0 ? totalSpeed / Double(count) : 0
        }
    }

    private var sectorData: [SectorData] {
        var data = Array(repeating: SectorData(), count: sectors)
        for snapshot in snapshots {
            guard let dir = snapshot.windDirection else { continue }
            let index = Int(round(Double(dir) / 22.5)) % sectors
            data[index].count += 1
            // Use gust if available, fall back to wind speed
            let speed = snapshot.windGust ?? snapshot.windSpeed ?? 0
            data[index].totalSpeed += speed
        }
        return data
    }

    /// Map average wind speed to a color: blue → green → yellow → red
    private func colorForSpeed(_ speed: Double) -> Color {
        switch speed {
        case ..<3:    return Color(red: 0.2, green: 0.4, blue: 0.9)   // Blue - calm
        case ..<10:   return Color(red: 0.2, green: 0.7, blue: 0.4)   // Green - light
        case ..<20:   return Color(red: 0.9, green: 0.8, blue: 0.2)   // Yellow - moderate
        default:      return Color(red: 0.9, green: 0.2, blue: 0.2)   // Red - high
        }
    }

    var body: some View {
        let data = sectorData
        let maxCount = max(data.map(\.count).max() ?? 1, 1)

        VStack(spacing: 4) {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxRadius = size / 2 - 24

            Canvas { context, _ in
                // Concentric guide rings
                for fraction in [0.25, 0.5, 0.75, 1.0] {
                    let r = maxRadius * fraction
                    let ringRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                    context.stroke(
                        Path(ellipseIn: ringRect),
                        with: .color(.white.opacity(0.06)),
                        lineWidth: 0.5
                    )
                }

                // Cross lines (N-S, E-W)
                for angle in stride(from: 0.0, to: 360.0, by: 90.0) {
                    let rad = angle * .pi / 180
                    var line = Path()
                    line.move(to: center)
                    line.addLine(to: CGPoint(
                        x: center.x + maxRadius * CGFloat(sin(rad)),
                        y: center.y - maxRadius * CGFloat(cos(rad))
                    ))
                    context.stroke(line, with: .color(.white.opacity(0.06)), lineWidth: 0.5)
                }

                // Sector wedge bars — colored by average wind speed
                let innerRadius: CGFloat = 16
                for i in 0..<sectors {
                    let fraction = CGFloat(data[i].count) / CGFloat(maxCount)
                    guard fraction > 0 else { continue }

                    let outerRadius = innerRadius + (maxRadius - innerRadius) * fraction
                    let startAngle = Angle.degrees(Double(i) * 22.5 - 90 - 11.25)
                    let endAngle = Angle.degrees(Double(i) * 22.5 - 90 + 11.25)

                    var wedge = Path()
                    wedge.addArc(center: center, radius: innerRadius,
                                 startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    wedge.addArc(center: center, radius: outerRadius,
                                 startAngle: endAngle, endAngle: startAngle, clockwise: true)
                    wedge.closeSubpath()

                    let sectorColor = colorForSpeed(data[i].averageSpeed)
                    let opacity = 0.4 + 0.5 * Double(fraction)
                    context.fill(wedge, with: .color(sectorColor.opacity(opacity)))
                    context.stroke(wedge, with: .color(sectorColor.opacity(0.7)), lineWidth: 0.5)
                }
            }

            // Cardinal and intercardinal labels
            ForEach(0..<sectors, id: \.self) { i in
                let angle = Double(i) * 22.5
                let isCardinal = i % 4 == 0
                let isIntercardinal = i % 2 == 0

                if isCardinal || isIntercardinal {
                    let labelRadius = maxRadius + 14
                    let rad = angle * .pi / 180
                    Text(sectorLabels[i])
                        .font(isCardinal ? .caption.bold() : .system(size: 8))
                        .foregroundStyle(isCardinal ? .white.opacity(0.8) : .white.opacity(0.35))
                        .position(
                            x: center.x + labelRadius * CGFloat(sin(rad)),
                            y: center.y - labelRadius * CGFloat(cos(rad))
                        )
                }
            }

        }
        .aspectRatio(1, contentMode: .fit)

        // Legend below the chart
        HStack(spacing: 8) {
            legendDot(color: Color(red: 0.2, green: 0.4, blue: 0.9), label: "Calm")
            legendDot(color: Color(red: 0.2, green: 0.7, blue: 0.4), label: "Light")
            legendDot(color: Color(red: 0.9, green: 0.8, blue: 0.2), label: "Mod")
            legendDot(color: Color(red: 0.9, green: 0.2, blue: 0.2), label: "High")
        }
        .font(.system(size: 9))
        } // VStack
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}
