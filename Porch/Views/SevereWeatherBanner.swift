//
//  SevereWeatherBanner.swift
//  Porch
//
//  Created by Mike Manzo on 3/16/26.
//

import SwiftUI
import WeatherKit

/// Warning banner shown when WeatherKit reports active severe weather alerts
struct SevereWeatherBanner: View {
    let alerts: [WeatherAlert]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(alerts.prefix(3), id: \.event) { alert in
                HStack(spacing: 6) {
                    Image(systemName: iconForSeverity(alert.severity))
                        .foregroundStyle(colorForSeverity(alert.severity))
                        .font(.caption)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(alert.event)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if let region = alert.region {
                            Text(region)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    if let url = alert.detailsURL {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.forward.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(bannerBackground, in: RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 12)
    }

    private var bannerBackground: Color {
        let maxSeverity = alerts.map(\.severity).max(by: { severityRank($0) < severityRank($1) })
        switch maxSeverity {
        case .extreme: return .red.opacity(0.15)
        case .severe: return .orange.opacity(0.15)
        default: return .yellow.opacity(0.12)
        }
    }

    private func iconForSeverity(_ severity: WeatherSeverity) -> String {
        switch severity {
        case .extreme, .severe: return "exclamationmark.triangle.fill"
        case .moderate: return "exclamationmark.circle.fill"
        case .minor: return "info.circle.fill"
        default: return "exclamationmark.circle"
        }
    }

    private func colorForSeverity(_ severity: WeatherSeverity) -> Color {
        switch severity {
        case .extreme: return .red
        case .severe: return .orange
        case .moderate: return .yellow
        case .minor: return .blue
        default: return .secondary
        }
    }

    private func severityRank(_ severity: WeatherSeverity) -> Int {
        switch severity {
        case .extreme: return 4
        case .severe: return 3
        case .moderate: return 2
        case .minor: return 1
        default: return 0
        }
    }
}
