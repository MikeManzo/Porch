//
//  WeatherHeroView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import PorchStationKit

/// Large hero display showing the primary temperature reading and feels-like
struct WeatherHeroView: View {
    let porchData: PorchWeatherData
    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var forecastManager: ForecastManager

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        VStack(spacing: 4) {
            // Weather condition icon (Open-Meteo if available, else station sensors)
            Image(systemName: currentConditionIcon)
                .font(.system(size: 32))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 1)

            // Primary temperature
            if let temp = porchData.temperatureF {
                let displayTemp = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
                Text("\(displayTemp, specifier: "%.1f")\u{00B0}")
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 1)
                    .contentTransition(.numericText())
            } else {
                Text("--\u{00B0}")
                    .font(.system(size: 56, weight: .thin, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Feels like + condition summary
            HStack(spacing: 6) {
                if let feelsLike = porchData.feelsLikeF {
                    let displayFL = isMetric ? (feelsLike - 32) * 5.0 / 9.0 : feelsLike
                    heroPill(Label("Feels \(displayFL, specifier: "%.0f")\u{00B0}", systemImage: "person.and.background.dotted"))
                }

                if let humidity = porchData.humidity {
                    heroPill(Label("\(humidity)%", systemImage: "humidity"))
                }
            }
            .padding(.top, 2)

            // Observation time
            Text("Updated \(porchData.observationDateFormatted)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(heroGradient)
                .overlay(
                    RadialGradient(colors: [.white.opacity(0.25), .clear], center: .topLeading, startRadius: 0, endRadius: 150)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 12)
    }

    private func heroPill(_ label: Label<Text, Image>) -> some View {
        label
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.white.opacity(0.22), in: Capsule())
    }

    // MARK:  Condition-Driven Gradient

    /// Diagonal gradient that reflects the current condition and time of day,
    /// so the hero card visually matches what it's reporting instead of sitting on flat black.
    private var heroGradient: LinearGradient {
        LinearGradient(colors: [gradientColors.0, gradientColors.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var gradientColors: (Color, Color) {
        if let current = forecastManager.currentWeather {
            return Self.gradientColors(forWeatherCode: current.weatherCode, isDay: current.isDay)
        }
        // No forecast yet — fall back to station-sensor mood so the hero still isn't flat black.
        let hasRain = (porchData.rainRateInPerHr ?? 0) > 0
        let hasLightning = porchData.lightningDayCount.map { $0 > 0 } ?? false
        if hasLightning { return Self.gradientColors(forWeatherCode: 95, isDay: true) }
        if hasRain { return Self.gradientColors(forWeatherCode: 63, isDay: true) }
        return Self.gradientColors(forWeatherCode: 0, isDay: true)
    }

    private static func gradientColors(forWeatherCode code: Int, isDay: Bool) -> (Color, Color) {
        switch code {
        case 0, 1: // clear
            return isDay
                ? (Color(red: 1.00, green: 0.71, blue: 0.28), Color(red: 0.18, green: 0.42, blue: 0.68))
                : (Color(red: 0.10, green: 0.12, blue: 0.30), Color(red: 0.03, green: 0.04, blue: 0.11))
        case 2: // partly cloudy
            return isDay
                ? (Color(red: 0.55, green: 0.68, blue: 0.85), Color(red: 0.30, green: 0.42, blue: 0.62))
                : (Color(red: 0.20, green: 0.24, blue: 0.38), Color(red: 0.06, green: 0.08, blue: 0.16))
        case 3, 45, 48: // overcast / fog
            return (Color(red: 0.55, green: 0.58, blue: 0.62), Color(red: 0.30, green: 0.33, blue: 0.38))
        case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: // drizzle / rain / showers
            return (Color(red: 0.33, green: 0.52, blue: 0.66), Color(red: 0.12, green: 0.22, blue: 0.40))
        case 71, 73, 75, 77, 85, 86: // snow
            return (Color(red: 0.80, green: 0.86, blue: 0.94), Color(red: 0.50, green: 0.58, blue: 0.70))
        case 95, 96, 99: // thunderstorm
            return (Color(red: 0.95, green: 0.78, blue: 0.30), Color(red: 0.22, green: 0.14, blue: 0.34))
        default:
            return (Color(red: 1.00, green: 0.71, blue: 0.28), Color(red: 0.18, green: 0.42, blue: 0.68))
        }
    }

    // MARK:  Weather Condition Logic

    /// Uses Open-Meteo current conditions if available, else falls back to station sensors
    private var currentConditionIcon: String {
        if let current = forecastManager.currentWeather {
            return current.icon
        }
        return sensorConditionIcon
    }

    // MARK:  Station Sensor Fallbacks

    private var sensorConditionIcon: String {
        let hasRain = (porchData.rainRateInPerHr ?? 0) > 0
        let hasLightning = porchData.lightningDayCount.map { $0 > 0 } ?? false
        let highUV = (porchData.uvIndex ?? 0) >= 6
        let highWind = (porchData.windSpeedMPH ?? 0) >= 20

        if hasLightning && hasRain { return "cloud.bolt.rain.fill" }
        if hasLightning { return "cloud.bolt.fill" }
        if hasRain { return "cloud.rain.fill" }
        if highWind { return "wind" }
        if highUV { return "sun.max.fill" }
        if (porchData.solarRadiation ?? 0) > 0 { return "sun.max.fill" }
        return "cloud.sun.fill"
    }
}
