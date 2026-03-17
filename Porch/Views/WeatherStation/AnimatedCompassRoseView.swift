//
//  AnimatedCompassRoseView.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI

/// A large animated compass rose showing wind direction, speed, and gust
struct AnimatedCompassRoseView: View {
    let windDirection: Int
    let windDirAvg10m: Int?
    let windSpeed: Double?
    let windGust: Double?
    let isMetric: Bool

    @State private var animatedDirection: Double = 0

    private let size: CGFloat = 240
    private let outerRadius: CGFloat = 112
    private let labelRadius: CGFloat = 92
    private let tickOuterRadius: CGFloat = 108
    private let majorTickLength: CGFloat = 12
    private let minorTickLength: CGFloat = 6

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            .cyan.opacity(0.15), .blue.opacity(0.3),
                            .cyan.opacity(0.15), .blue.opacity(0.3),
                            .cyan.opacity(0.15)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: outerRadius * 2, height: outerRadius * 2)

            // Inner ring
            Circle()
                .stroke(.white.opacity(0.06), lineWidth: 1)
                .frame(width: (outerRadius - 20) * 2, height: (outerRadius - 20) * 2)

            // Tick marks (36 ticks at every 10°, major at 30°)
            ForEach(0..<36, id: \.self) { index in
                let isMajor = index % 3 == 0
                Rectangle()
                    .fill(isMajor ? Color.white.opacity(0.5) : Color.white.opacity(0.15))
                    .frame(width: isMajor ? 2 : 1, height: isMajor ? majorTickLength : minorTickLength)
                    .offset(y: -(tickOuterRadius - (isMajor ? majorTickLength : minorTickLength) / 2))
                    .rotationEffect(.degrees(Double(index) * 10))
            }

            // Cardinal and intercardinal labels
            ForEach(compassLabels, id: \.label) { point in
                Text(point.label)
                    .font(point.isCardinal
                        ? .system(size: 15, weight: .bold, design: .rounded)
                        : .system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(point.isCardinal ? .white.opacity(0.9) : .white.opacity(0.45))
                    .offset(
                        x: labelRadius * CGFloat(sin(point.angle * .pi / 180)),
                        y: -labelRadius * CGFloat(cos(point.angle * .pi / 180))
                    )
            }

            // 10-minute average direction indicator
            if let avg = windDirAvg10m {
                CompassTriangle()
                    .fill(.orange.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .offset(y: -(outerRadius + 6))
                    .rotationEffect(.degrees(Double(avg)))
            }

            // Main direction arrow (animated)
            CompassNeedle()
                .rotationEffect(.degrees(animatedDirection))

            // Center hub with speed display
            centerHub
        }
        .frame(width: size, height: size)
        .onChange(of: windDirection) { _, newValue in
            let target = shortestRotation(from: animatedDirection, to: Double(newValue))
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animatedDirection = target
            }
        }
        .onAppear {
            animatedDirection = Double(windDirection)
        }
    }

    // MARK: - Center Hub

    private var centerHub: some View {
        VStack(spacing: 2) {
            Text(formatSpeed(windSpeed))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(isMetric ? "km/h" : "mph")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            if let gust = windGust, gust > 0 {
                Text("G: \(formatSpeed(gust))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.orange)
            }
        }
        .frame(width: 80, height: 80)
        .background(.ultraThinMaterial, in: Circle())
    }

    // MARK: - Helpers

    private var compassLabels: [CompassLabel] {
        [
            CompassLabel(label: "N", angle: 0, isCardinal: true),
            CompassLabel(label: "NE", angle: 45, isCardinal: false),
            CompassLabel(label: "E", angle: 90, isCardinal: true),
            CompassLabel(label: "SE", angle: 135, isCardinal: false),
            CompassLabel(label: "S", angle: 180, isCardinal: true),
            CompassLabel(label: "SW", angle: 225, isCardinal: false),
            CompassLabel(label: "W", angle: 270, isCardinal: true),
            CompassLabel(label: "NW", angle: 315, isCardinal: false),
        ]
    }

    private func formatSpeed(_ speed: Double?) -> String {
        guard let speed else { return "--" }
        let value = isMetric ? speed * 1.60934 : speed
        return String(format: "%.0f", value)
    }

    /// Calculate the shortest rotation path (handles 350° → 10° correctly)
    private func shortestRotation(from: Double, to: Double) -> Double {
        var delta = (to - from).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        return from + delta
    }
}

// MARK: - Supporting Types

private struct CompassLabel {
    let label: String
    let angle: Double
    let isCardinal: Bool
}

/// The main compass needle shape — an elongated diamond pointing north
private struct CompassNeedle: View {
    var body: some View {
        ZStack {
            // North half — bright cyan/blue
            CompassTriangle()
                .fill(
                    LinearGradient(
                        colors: [.cyan, .blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 16, height: 65)
                .offset(y: -32)

            // South half — subtle gray
            CompassTriangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 12, height: 45)
                .rotationEffect(.degrees(180))
                .offset(y: 22)

            // Center dot
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
        }
    }
}

/// A simple triangle shape pointing up
private struct CompassTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
