//
//  ForecastManager.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI
import Combine

// MARK: - Daily Forecast Model

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let highTemp: Double      // °F
    let lowTemp: Double       // °F
    let feelsLikeHigh: Double? // °F apparent
    let feelsLikeLow: Double?  // °F apparent
    let weatherCode: Int      // WMO code
    let precipProbability: Int?
    let precipAmount: Double?  // inches
    let windSpeedMax: Double?  // mph
    let windGustMax: Double?   // mph
    let windDirection: Int?    // degrees
    let uvIndexMax: Double?
    let sunrise: Date?
    let sunset: Date?

    /// SF Symbol for the WMO weather code
    var icon: String {
        Self.wmoIcon(for: weatherCode)
    }

    /// Human-readable condition text
    var conditionText: String {
        Self.wmoCondition(for: weatherCode)
    }

    /// Short condition label for compact layouts (3-day outlook)
    var shortConditionText: String {
        Self.wmoShortCondition(for: weatherCode)
    }

    /// Icon color based on weather type
    var iconColor: Color { Self.wmoIconColor(for: weatherCode) }

    static func wmoIconColor(for code: Int) -> Color {
        switch code {
        case 0: return .orange
        case 1, 2: return .orange
        case 3: return .gray
        case 45, 48: return .gray
        case 51, 53, 55, 56, 57: return .cyan
        case 61, 63, 65, 66, 67: return .blue
        case 71, 73, 75, 77: return .white
        case 80, 81, 82: return .blue
        case 85, 86: return .white
        case 95, 96, 99: return .yellow
        default: return .gray
        }
    }

    // MARK: - WMO Weather Code Mappings

    static func wmoIcon(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1: return "sun.min.fill"
        case 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 56, 57: return "cloud.sleet.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 66, 67: return "cloud.sleet.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 77: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95: return "cloud.bolt.rain.fill"
        case 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    static func wmoCondition(for code: Int) -> String {
        switch code {
        case 0: return "Clear Sky"
        case 1: return "Mainly Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Overcast"
        case 45: return "Fog"
        case 48: return "Depositing Rime Fog"
        case 51: return "Light Drizzle"
        case 53: return "Moderate Drizzle"
        case 55: return "Dense Drizzle"
        case 56: return "Light Freezing Drizzle"
        case 57: return "Dense Freezing Drizzle"
        case 61: return "Light Rain"
        case 63: return "Moderate Rain"
        case 65: return "Heavy Rain"
        case 66: return "Light Freezing Rain"
        case 67: return "Heavy Freezing Rain"
        case 71: return "Light Snow"
        case 73: return "Moderate Snow"
        case 75: return "Heavy Snow"
        case 77: return "Snow Grains"
        case 80: return "Light Showers"
        case 81: return "Moderate Showers"
        case 82: return "Violent Showers"
        case 85: return "Light Snow Showers"
        case 86: return "Heavy Snow Showers"
        case 95: return "Thunderstorm"
        case 96: return "Thunderstorm with Light Hail"
        case 99: return "Thunderstorm with Heavy Hail"
        default: return "Unknown"
        }
    }

    static func wmoShortCondition(for code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1: return "Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Frz. Drizzle"
        case 61: return "Light Rain"
        case 63: return "Rain"
        case 65: return "Heavy Rain"
        case 66, 67: return "Frz. Rain"
        case 71: return "Light Snow"
        case 73: return "Snow"
        case 75: return "Heavy Snow"
        case 77: return "Snow"
        case 80: return "Showers"
        case 81: return "Showers"
        case 82: return "Heavy Showers"
        case 85, 86: return "Snow Shwrs"
        case 95: return "T-Storms"
        case 96: return "T-Storms"
        case 99: return "T-Storms"
        default: return "Unknown"
        }
    }
}

// MARK: - Current Weather Model

struct CurrentWeather {
    let weatherCode: Int
    let isDay: Bool
    let time: Date

    /// SF Symbol for the WMO weather code, adjusted for day/night
    var icon: String {
        if isDay {
            return DailyForecast.wmoIcon(for: weatherCode)
        }
        // Night variants: swap sun symbols for moon symbols
        switch weatherCode {
        case 0: return "moon.stars.fill"
        case 1: return "moon.fill"
        case 2: return "cloud.moon.fill"
        default: return DailyForecast.wmoIcon(for: weatherCode)
        }
    }

    /// Human-readable condition text
    var conditionText: String {
        if !isDay && weatherCode == 0 { return "Clear Night" }
        return DailyForecast.wmoCondition(for: weatherCode)
    }

    /// Icon color based on weather type, adjusted for night
    var iconColor: Color {
        if !isDay {
            switch weatherCode {
            case 0, 1: return .indigo
            case 2: return .indigo
            default: return DailyForecast.wmoIconColor(for: weatherCode)
            }
        }
        return DailyForecast.wmoIconColor(for: weatherCode)
    }
}

// MARK: - Forecast Manager

@MainActor
class ForecastManager: ObservableObject {

    @Published private(set) var dailyForecasts: [DailyForecast] = []
    @Published private(set) var currentWeather: CurrentWeather?
    @Published private(set) var lastFetchDate: Date?

    private var refreshTimer: Timer?
    private var currentLatitude: Double?
    private var currentLongitude: Double?

    /// Fetch daily forecast from Open-Meteo
    func fetchForecast(latitude: Double, longitude: Double) async {
        currentLatitude = latitude
        currentLongitude = longitude

        // Throttle: don't re-fetch if last fetch was less than 10 minutes ago
        if let last = lastFetchDate, Date().timeIntervalSince(last) < 600 {
            return
        }

        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(latitude)"
            + "&longitude=\(longitude)"
            + "&current=weather_code,is_day"
            + "&daily=temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,weather_code,precipitation_probability_max,precipitation_sum,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant,uv_index_max,sunrise,sunset"
            + "&temperature_unit=fahrenheit"
            + "&wind_speed_unit=mph"
            + "&precipitation_unit=inch"
            + "&timezone=auto"
            + "&forecast_days=4"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            // Parse current conditions
            if let currentData = response.current {
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
                let currentTime = isoFormatter.date(from: currentData.time) ?? Date()
                currentWeather = CurrentWeather(
                    weatherCode: currentData.weather_code,
                    isDay: currentData.is_day == 1,
                    time: currentTime
                )
            }

            var forecasts: [DailyForecast] = []
            let count = response.daily.time.count

            // Open-Meteo returns sunrise/sunset as "yyyy-MM-dd'T'HH:mm" (no seconds)
            let sunFormatter = DateFormatter()
            sunFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            sunFormatter.locale = Locale(identifier: "en_US_POSIX")

            for i in 0..<count {
                guard let date = dateFormatter.date(from: response.daily.time[i]) else { continue }
                let d = response.daily
                let forecast = DailyForecast(
                    date: date,
                    highTemp: d.temperature_2m_max[i],
                    lowTemp: d.temperature_2m_min[i],
                    feelsLikeHigh: d.apparent_temperature_max?[safe: i],
                    feelsLikeLow: d.apparent_temperature_min?[safe: i],
                    weatherCode: d.weather_code[i],
                    precipProbability: i < d.precipitation_probability_max.count
                        ? d.precipitation_probability_max[i] : nil,
                    precipAmount: d.precipitation_sum?[safe: i],
                    windSpeedMax: d.wind_speed_10m_max?[safe: i],
                    windGustMax: d.wind_gusts_10m_max?[safe: i],
                    windDirection: d.wind_direction_10m_dominant?[safe: i],
                    uvIndexMax: d.uv_index_max?[safe: i],
                    sunrise: i < d.sunrise.count
                        ? sunFormatter.date(from: d.sunrise[i]) : nil,
                    sunset: i < d.sunset.count
                        ? sunFormatter.date(from: d.sunset[i]) : nil
                )
                forecasts.append(forecast)
            }

            dailyForecasts = forecasts
            lastFetchDate = Date()
            print("[Porch] Open-Meteo: fetched \(forecasts.count)-day forecast")

            startRefreshTimer()
        } catch {
            print("[Porch] Open-Meteo error: \(error.localizedDescription)")
        }
    }

    /// Schedule periodic refresh every 10 minutes
    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let lat = self.currentLatitude,
                      let lon = self.currentLongitude else { return }
                // Reset lastFetchDate so throttle doesn't block
                self.lastFetchDate = nil
                await self.fetchForecast(latitude: lat, longitude: lon)
            }
        }
    }

    func stopRefreshing() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Clear cached data so the next fetch uses the latest API parameters
    func reset() {
        dailyForecasts = []
        currentWeather = nil
        lastFetchDate = nil
        stopRefreshing()
    }
}

// MARK: - Open-Meteo JSON Response

private struct OpenMeteoResponse: Decodable {
    let current: CurrentData?
    let daily: DailyData

    struct CurrentData: Decodable {
        let time: String
        let weather_code: Int
        let is_day: Int  // 1 = day, 0 = night
    }

    struct DailyData: Decodable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let apparent_temperature_max: [Double]?
        let apparent_temperature_min: [Double]?
        let weather_code: [Int]
        let precipitation_probability_max: [Int]
        let precipitation_sum: [Double]?
        let wind_speed_10m_max: [Double]?
        let wind_gusts_10m_max: [Double]?
        let wind_direction_10m_dominant: [Int]?
        let uv_index_max: [Double]?
        let sunrise: [String]
        let sunset: [String]
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
