//
//  AboutSettingsTab.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI

struct AboutSettingsTab: View {
    @State private var isHovering = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero Section
                VStack(spacing: 16) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .cyan.opacity(0.3), radius: 16, y: 4)

                    VStack(spacing: 6) {
                        Text("Porch")
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        Text("Version \(version) (\(build))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("A real-time macOS menubar dashboard for\nAmbient Weather personal weather stations.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.top, 28)
                .padding(.bottom, 24)

                Divider()
                    .padding(.horizontal, 32)

                // MARK: - Highlights
                VStack(spacing: 12) {
                    highlightRow(
                        icon: "bolt.horizontal.fill",
                        color: .cyan,
                        title: "Real-Time Streaming",
                        detail: "Live WebSocket connection delivers sensor updates as they happen"
                    )
                    highlightRow(
                        icon: "sensor.fill",
                        color: .green,
                        title: "50+ Sensor Types",
                        detail: "Temperature, wind, rain, soil, air quality, lightning, and more"
                    )
                    highlightRow(
                        icon: "bell.badge.fill",
                        color: .orange,
                        title: "Smart Alerts",
                        detail: "Configurable thresholds for temperature, wind, leaks, and battery"
                    )
                    highlightRow(
                        icon: "clock.arrow.circlepath",
                        color: .purple,
                        title: "Historical Logging",
                        detail: "7-day rolling data archive powered by SwiftData"
                    )
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 32)

                // MARK: - Built With
                VStack(spacing: 10) {
                    Text("Built With")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    HStack(spacing: 16) {
                        techBadge("SwiftUI")
                        techBadge("SwiftData")
                        techBadge("Combine")
                        techBadge("Liquid Glass")
                    }
                }
                .padding(.vertical, 16)

                Divider()
                    .padding(.horizontal, 32)

                // MARK: - Acknowledgments
                VStack(spacing: 12) {
                    Text("Acknowledgments")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    acknowledgmentRow(
                        icon: "arrow.triangle.2.circlepath",
                        color: .blue,
                        title: "Sparkle",
                        detail: "Secure and reliable software update framework",
                        url: "https://sparkle-project.org"
                    )
                    acknowledgmentRow(
                        icon: "cloud.sun.fill",
                        color: .orange,
                        title: "Open-Meteo",
                        detail: "Free weather forecast API — no key required",
                        url: "https://open-meteo.com"
                    )
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)

                Divider()
                    .padding(.horizontal, 32)

                // MARK: - Links
                VStack(spacing: 10) {
                    Link(destination: URL(string: "https://github.com/MikeManzo/Porch")!) {
                        linkRow(icon: "chevron.left.forwardslash.chevron.right", title: "Source Code on GitHub")
                    }

                    Link(destination: URL(string: "https://github.com/MikeManzo/AmbientWeatherSocket")!) {
                        linkRow(icon: "shippingbox.fill", title: "AmbientWeatherSocket Package")
                    }

                    Link(destination: URL(string: "https://ambientweather.net")!) {
                        linkRow(icon: "globe", title: "Ambient Weather Dashboard")
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)

                // MARK: - Copyright
                VStack(spacing: 4) {
                    Text("\u{00A9} \(Calendar.current.component(.year, from: Date())) Mike Manzo")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                    Text("All rights reserved.")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Components

    private func highlightRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private func techBadge(_ name: String) -> some View {
        Text(name)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private func acknowledgmentRow(icon: String, color: Color, title: String, detail: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func linkRow(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.cyan)
                .frame(width: 20)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
