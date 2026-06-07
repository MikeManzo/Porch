//
//  DashboardTheme.swift
//  Porch
//
//  Created by Mike Manzo on 4/3/26.
//

import SwiftUI

// MARK: - Theme Identifier

/// User-selectable dashboard themes
enum DashboardThemeID: String, CaseIterable, Codable, Identifiable {
    case midnight
    case slate
    case aurora
    case desert
    case stormfront

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight:   "Midnight"
        case .slate:      "Slate"
        case .aurora:     "Aurora"
        case .desert:     "Desert"
        case .stormfront: "Stormfront"
        }
    }

    var resolved: DashboardTheme {
        switch self {
        case .midnight:   .midnight
        case .slate:      .slate
        case .aurora:     .aurora
        case .desert:     .desert
        case .stormfront: .stormfront
        }
    }
}

// MARK: - Theme Definition

/// Resolved color palette for the weather station dashboard
struct DashboardTheme {
    // Background mesh gradient (3x3 = 9 colors)
    let meshColors: [Color]

    // Text colors
    let primaryText: Color
    let secondaryText: Color

    // Panel header icon colors (per sensor category)
    let temperatureColor: Color
    let humidityColor: Color
    let pressureColor: Color
    let windColor: Color
    let rainColor: Color
    let solarColor: Color
    let uvColor: Color
    let indoorColor: Color
    let environmentColor: Color
    let leakColor: Color
    let gardenColor: Color
    let relayColor: Color
    let pm25Color: Color

    // Extremes panel
    let highTempColor: Color
    let lowTempColor: Color

    // Misc
    let accentColor: Color
    let gustColor: Color
    let windDirAvgColor: Color
}

// MARK: - Built-in Themes

extension DashboardTheme {

    /// Deep navy — the current/original look
    static let midnight = DashboardTheme(
        meshColors: [
            Color(red: 0.05, green: 0.05, blue: 0.15),
            Color(red: 0.04, green: 0.08, blue: 0.20),
            Color(red: 0.06, green: 0.06, blue: 0.18),
            Color(red: 0.03, green: 0.10, blue: 0.18),
            Color(red: 0.05, green: 0.07, blue: 0.22),
            Color(red: 0.04, green: 0.06, blue: 0.16),
            Color(red: 0.06, green: 0.04, blue: 0.14),
            Color(red: 0.04, green: 0.08, blue: 0.19),
            Color(red: 0.05, green: 0.05, blue: 0.15)
        ],
        primaryText: .white,
        secondaryText: .white.opacity(0.4),
        temperatureColor: .orange,
        humidityColor: .cyan,
        pressureColor: .purple,
        windColor: .cyan,
        rainColor: .blue,
        solarColor: .yellow,
        uvColor: .purple,
        indoorColor: .green,
        environmentColor: .orange,
        leakColor: .blue,
        gardenColor: .green,
        relayColor: .indigo,
        pm25Color: .green,
        highTempColor: .red,
        lowTempColor: .cyan,
        accentColor: .blue,
        gustColor: .orange,
        windDirAvgColor: .orange
    )

    /// Cool gray tones — professional and understated
    static let slate = DashboardTheme(
        meshColors: [
            Color(red: 0.10, green: 0.10, blue: 0.12),
            Color(red: 0.12, green: 0.12, blue: 0.14),
            Color(red: 0.09, green: 0.10, blue: 0.13),
            Color(red: 0.11, green: 0.11, blue: 0.14),
            Color(red: 0.13, green: 0.13, blue: 0.16),
            Color(red: 0.10, green: 0.11, blue: 0.13),
            Color(red: 0.09, green: 0.09, blue: 0.12),
            Color(red: 0.11, green: 0.12, blue: 0.14),
            Color(red: 0.10, green: 0.10, blue: 0.13)
        ],
        primaryText: .white,
        secondaryText: .white.opacity(0.45),
        temperatureColor: .orange,
        humidityColor: .teal,
        pressureColor: .indigo,
        windColor: .teal,
        rainColor: .blue,
        solarColor: .yellow,
        uvColor: .indigo,
        indoorColor: .mint,
        environmentColor: .orange,
        leakColor: .blue,
        gardenColor: .mint,
        relayColor: .indigo,
        pm25Color: .mint,
        highTempColor: .red,
        lowTempColor: .teal,
        accentColor: .teal,
        gustColor: .orange,
        windDirAvgColor: .orange
    )

    /// Green and purple — northern lights
    static let aurora = DashboardTheme(
        meshColors: [
            Color(red: 0.02, green: 0.08, blue: 0.06),
            Color(red: 0.04, green: 0.12, blue: 0.10),
            Color(red: 0.08, green: 0.06, blue: 0.14),
            Color(red: 0.03, green: 0.14, blue: 0.08),
            Color(red: 0.06, green: 0.10, blue: 0.16),
            Color(red: 0.10, green: 0.04, blue: 0.14),
            Color(red: 0.04, green: 0.10, blue: 0.06),
            Color(red: 0.06, green: 0.08, blue: 0.12),
            Color(red: 0.08, green: 0.05, blue: 0.12)
        ],
        primaryText: .white,
        secondaryText: .white.opacity(0.45),
        temperatureColor: .green,
        humidityColor: .mint,
        pressureColor: .purple,
        windColor: .mint,
        rainColor: .cyan,
        solarColor: .yellow,
        uvColor: .pink,
        indoorColor: .green,
        environmentColor: .green,
        leakColor: .cyan,
        gardenColor: .green,
        relayColor: .purple,
        pm25Color: .green,
        highTempColor: .pink,
        lowTempColor: .mint,
        accentColor: .green,
        gustColor: .pink,
        windDirAvgColor: .green
    )

    /// Warm amber and sand tones
    static let desert = DashboardTheme(
        meshColors: [
            Color(red: 0.14, green: 0.08, blue: 0.04),
            Color(red: 0.16, green: 0.10, blue: 0.05),
            Color(red: 0.12, green: 0.07, blue: 0.04),
            Color(red: 0.18, green: 0.10, blue: 0.04),
            Color(red: 0.15, green: 0.09, blue: 0.05),
            Color(red: 0.13, green: 0.08, blue: 0.06),
            Color(red: 0.16, green: 0.09, blue: 0.03),
            Color(red: 0.14, green: 0.08, blue: 0.05),
            Color(red: 0.12, green: 0.07, blue: 0.04)
        ],
        primaryText: .white,
        secondaryText: .white.opacity(0.45),
        temperatureColor: .orange,
        humidityColor: .teal,
        pressureColor: .indigo,
        windColor: .teal,
        rainColor: .cyan,
        solarColor: .yellow,
        uvColor: .orange,
        indoorColor: .mint,
        environmentColor: .yellow,
        leakColor: .cyan,
        gardenColor: .mint,
        relayColor: .orange,
        pm25Color: .mint,
        highTempColor: .red,
        lowTempColor: .teal,
        accentColor: .orange,
        gustColor: .red,
        windDirAvgColor: .yellow
    )

    /// Moody dark grays with electric blue accents
    static let stormfront = DashboardTheme(
        meshColors: [
            Color(red: 0.06, green: 0.06, blue: 0.08),
            Color(red: 0.07, green: 0.07, blue: 0.10),
            Color(red: 0.05, green: 0.06, blue: 0.09),
            Color(red: 0.08, green: 0.08, blue: 0.12),
            Color(red: 0.06, green: 0.07, blue: 0.11),
            Color(red: 0.05, green: 0.05, blue: 0.08),
            Color(red: 0.07, green: 0.07, blue: 0.10),
            Color(red: 0.06, green: 0.06, blue: 0.09),
            Color(red: 0.05, green: 0.05, blue: 0.08)
        ],
        primaryText: .white,
        secondaryText: .white.opacity(0.4),
        temperatureColor: Color(red: 0.3, green: 0.6, blue: 1.0),
        humidityColor: Color(red: 0.3, green: 0.6, blue: 1.0),
        pressureColor: .indigo,
        windColor: Color(red: 0.3, green: 0.6, blue: 1.0),
        rainColor: Color(red: 0.2, green: 0.5, blue: 1.0),
        solarColor: Color(red: 0.6, green: 0.8, blue: 1.0),
        uvColor: .indigo,
        indoorColor: Color(red: 0.4, green: 0.7, blue: 1.0),
        environmentColor: Color(red: 0.3, green: 0.6, blue: 1.0),
        leakColor: Color(red: 0.2, green: 0.5, blue: 1.0),
        gardenColor: Color(red: 0.4, green: 0.7, blue: 1.0),
        relayColor: .indigo,
        pm25Color: Color(red: 0.4, green: 0.7, blue: 1.0),
        highTempColor: Color(red: 0.5, green: 0.7, blue: 1.0),
        lowTempColor: Color(red: 0.2, green: 0.4, blue: 0.8),
        accentColor: Color(red: 0.3, green: 0.6, blue: 1.0),
        gustColor: Color(red: 0.5, green: 0.7, blue: 1.0),
        windDirAvgColor: Color(red: 0.6, green: 0.8, blue: 1.0)
    )
}

// MARK: - Environment Key

private struct DashboardThemeKey: EnvironmentKey {
    static let defaultValue: DashboardTheme = .midnight
}

extension EnvironmentValues {
    var dashboardTheme: DashboardTheme {
        get { self[DashboardThemeKey.self] }
        set { self[DashboardThemeKey.self] = newValue }
    }
}
