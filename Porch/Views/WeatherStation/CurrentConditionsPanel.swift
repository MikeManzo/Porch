//
//  CurrentConditionsPanel.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

/// Hero conditions panel showing temperature, weather icon, feels-like, and daily extremes
struct CurrentConditionsPanel: View {
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?
    @EnvironmentObject var manager: WeatherManager
    @EnvironmentObject var forecastManager: ForecastManager
    @Environment(\.dashboardTheme) private var theme
    @State private var selectedForecastID: UUID?

    /// Init from PorchWeatherData (new path)
    init(porchData: PorchWeatherData) {
        self.porchData = porchData
        self.observation = nil
    }

    /// Init from AmbientLastData (legacy path)
    init(observation: AmbientLastData) {
        self.observation = observation
        self.porchData = nil
    }

    private var isMetric: Bool { manager.unitSystem == .metric }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                // Current condition icon (Open-Meteo if available, else station sensors)
                Image(systemName: currentConditionIcon)
                    .font(.system(size: 48))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(currentConditionColor)

                // Temperature
                VStack(alignment: .leading, spacing: 4) {
                    if let temp = porchData?.temperatureF ?? observation?.tempF {
                        let displayTemp = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
                        Text("\(displayTemp, specifier: "%.1f")°")
                            .font(.system(size: 72, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    } else {
                        Text("--°")
                            .font(.system(size: 72, weight: .thin, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    HStack(spacing: 16) {
                        if let feelsLike = porchData?.feelsLikeF ?? observation?.feelsLike {
                            let displayFL = isMetric ? (feelsLike - 32) * 5.0 / 9.0 : feelsLike
                            Label("Feels \(displayFL, specifier: "%.0f")°", systemImage: "person.and.background.dotted")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        if let humidity = porchData?.humidity ?? observation?.humidity {
                            Label("\(humidity)%", systemImage: "humidity")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                Spacer()

                // Daily extremes & sun times
                VStack(alignment: .trailing, spacing: 8) {
                    if let high = manager.dailyHighTemp {
                        extremeStat(icon: "thermometer.sun.fill", label: "Hi", value: formatTemp(high), tint: theme.highTempColor)
                    }
                    if let low = manager.dailyLowTemp {
                        extremeStat(icon: "thermometer.snowflake", label: "Lo", value: formatTemp(low), tint: theme.lowTempColor)
                    }
                    if let gust = manager.dailyHighWind {
                        extremeStat(icon: "wind", label: "Gust", value: formatWind(gust), tint: theme.windColor)
                    }
                    if let today = forecastManager.dailyForecasts.first {
                        if let rise = today.sunrise {
                            extremeStat(icon: "sunrise.fill", label: "Rise", value: rise.formatted(date: .omitted, time: .shortened), tint: theme.solarColor)
                        }
                        if let set = today.sunset {
                            extremeStat(icon: "sunset.fill", label: "Set", value: set.formatted(date: .omitted, time: .shortened), tint: theme.accentColor)
                        }
                    }
                }
            }

            // Forecast section
            if let today = forecastManager.dailyForecasts.first {
                Divider()
                    .overlay(Color.white.opacity(0.15))
                    .padding(.vertical, 12)

                HStack(alignment: .top, spacing: 0) {
                    // Today's forecast
                    HStack(spacing: 12) {
                        Image(systemName: today.icon)
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(today.iconColor)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Today's Forecast")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(today.conditionText)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                            Text("Hi \(formatTemp(today.highTemp)) / Lo \(formatTemp(today.lowTemp))")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    Spacer()

                    // 3-day look-ahead
                    let upcoming = Array(forecastManager.dailyForecasts.dropFirst().prefix(3))
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(upcoming) { day in
                            VStack(spacing: 5) {
                                Text(dayAbbreviation(day.date))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                                Image(systemName: day.icon)
                                    .font(.system(size: 20))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(day.iconColor)
                                    .frame(height: 22)
                                Text(formatTemp(day.highTemp))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                                Text(day.shortConditionText)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 80)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedForecastID = selectedForecastID == day.id ? nil : day.id
                                }
                            }
                            .popover(isPresented: Binding(
                                get: { selectedForecastID == day.id },
                                set: { if !$0 { selectedForecastID = nil } }
                            )) {
                                forecastPopover(for: day)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Forecast Popover

    private func forecastPopover(for day: DailyForecast) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: day.icon)
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(day.iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(day.date.formatted(.dateTime.weekday(.wide)))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(day.date.formatted(.dateTime.month(.wide).day()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(day.conditionText)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Divider()

            HStack(spacing: 16) {
                Label(formatTemp(day.highTemp), systemImage: "thermometer.sun.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.highTempColor)
                Label(formatTemp(day.lowTemp), systemImage: "thermometer.snowflake")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.lowTempColor)
            }

            if let flHigh = day.feelsLikeHigh, let flLow = day.feelsLikeLow {
                HStack(spacing: 16) {
                    Label("Feels \(formatTemp(flHigh))", systemImage: "person.and.background.dotted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("Feels \(formatTemp(flLow))", systemImage: "person.and.background.dotted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if day.precipProbability != nil || day.precipAmount != nil {
                HStack(spacing: 16) {
                    if let prob = day.precipProbability {
                        Label("\(prob)%", systemImage: "drop.fill")
                            .font(.subheadline)
                            .foregroundStyle(theme.rainColor)
                    }
                    if let amount = day.precipAmount, amount > 0 {
                        Label(formatRain(amount), systemImage: "cloud.rain")
                            .font(.subheadline)
                            .foregroundStyle(theme.rainColor)
                    }
                }
            }

            if day.windSpeedMax != nil || day.windGustMax != nil {
                HStack(spacing: 16) {
                    if let speed = day.windSpeedMax {
                        Label(formatWind(speed), systemImage: "wind")
                            .font(.subheadline)
                            .foregroundStyle(theme.windColor)
                    }
                    if let gust = day.windGustMax {
                        Label("Gusts \(formatWind(gust))", systemImage: "wind")
                            .font(.subheadline)
                            .foregroundStyle(theme.windColor)
                    }
                    if let dir = day.windDirection {
                        Text(windDirectionLabel(dir))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let uv = day.uvIndexMax {
                Label("UV \(String(format: "%.0f", uv)) — \(uvDescription(uv))", systemImage: "sun.max.trianglebadge.exclamationmark.fill")
                    .font(.subheadline)
                    .foregroundStyle(uvColor(uv))
            }

            if day.sunrise != nil || day.sunset != nil {
                HStack(spacing: 16) {
                    if let rise = day.sunrise {
                        Label(rise.formatted(date: .omitted, time: .shortened), systemImage: "sunrise.fill")
                            .font(.subheadline)
                            .foregroundStyle(theme.solarColor)
                    }
                    if let set = day.sunset {
                        Label(set.formatted(date: .omitted, time: .shortened), systemImage: "sunset.fill")
                            .font(.subheadline)
                            .foregroundStyle(theme.accentColor)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    // MARK: - Helpers

    private func extremeStat(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func formatTemp(_ temp: Double) -> String {
        let display = isMetric ? (temp - 32) * 5.0 / 9.0 : temp
        return String(format: "%.0f°", display)
    }

    private func formatWind(_ speed: Double) -> String {
        let display = isMetric ? speed * 1.60934 : speed
        let unit = isMetric ? "km/h" : "mph"
        return String(format: "%.0f %@", display, unit)
    }

    private func formatRain(_ inches: Double) -> String {
        if isMetric {
            return String(format: "%.1f mm", inches * 25.4)
        }
        return String(format: "%.2f\"", inches)
    }

    private func windDirectionLabel(_ degrees: Int) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((Double(degrees) + 11.25) / 22.5) % 16
        return directions[index]
    }

    private func uvDescription(_ uv: Double) -> String {
        switch uv {
        case ..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
        }
    }

    private func uvColor(_ uv: Double) -> Color {
        switch uv {
        case ..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }

    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    /// Icon for the 48pt hero — uses Open-Meteo current conditions if available, else station sensors
    private var currentConditionIcon: String {
        if let current = forecastManager.currentWeather {
            return current.icon
        }
        return sensorConditionIcon
    }

    private var currentConditionColor: Color {
        if let current = forecastManager.currentWeather {
            return current.iconColor
        }
        return sensorConditionColor
    }

    // MARK: - Station Sensor Fallbacks

    private var sensorConditionIcon: String {
        let hasRain: Bool
        let hasLightning: Bool
        let highUV: Bool
        let highWind: Bool
        let hasSolar: Bool

        if let porchData {
            hasRain = (porchData.rainRateInPerHr ?? 0) > 0
            hasLightning = porchData.lightningDayCount.map { $0 > 0 } ?? false
            highUV = (porchData.uvIndex ?? 0) >= 6
            highWind = (porchData.windSpeedMPH ?? 0) >= 20
            hasSolar = (porchData.solarRadiation ?? 0) > 0
        } else if let observation {
            hasRain = (observation.hourlyRainIn ?? 0) > 0
            hasLightning = (observation.lightningHour ?? 0) > 0
            highUV = (observation.uv ?? 0) >= 6
            highWind = (observation.windSpeedMPH ?? 0) >= 20
            hasSolar = (observation.solarRadiation ?? 0) > 0
        } else {
            return "cloud.sun.fill"
        }

        if hasLightning && hasRain { return "cloud.bolt.rain.fill" }
        if hasLightning { return "cloud.bolt.fill" }
        if hasRain { return "cloud.rain.fill" }
        if highWind { return "wind" }
        if highUV { return "sun.max.fill" }
        if hasSolar { return "sun.max.fill" }
        return "cloud.sun.fill"
    }

    private var sensorConditionColor: Color {
        let hasRain: Bool
        let hasLightning: Bool

        if let porchData {
            hasRain = (porchData.rainRateInPerHr ?? 0) > 0
            hasLightning = porchData.lightningDayCount.map { $0 > 0 } ?? false
        } else if let observation {
            hasRain = (observation.hourlyRainIn ?? 0) > 0
            hasLightning = (observation.lightningHour ?? 0) > 0
        } else {
            return .orange
        }

        if hasLightning { return theme.solarColor }
        if hasRain { return theme.rainColor }
        return theme.temperatureColor
    }
}
