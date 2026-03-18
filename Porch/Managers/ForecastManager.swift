//
//  ForecastManager.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI

// MARK: - Daily Forecast Model

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let highTemp: Double      // °F
    let lowTemp: Double       // °F
    let weatherCode: Int      // WMO code
    let precipProbability: Int?

    /// SF Symbol for the WMO weather code
    var icon: String {
        Self.wmoIcon(for: weatherCode)
    }

    /// Human-readable condition text
    var conditionText: String {
        Self.wmoCondition(for: weatherCode)
    }

    /// Icon color based on weather type
    var iconColor: Color {
        switch weatherCode {
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
}

// MARK: - Forecast Manager

@MainActor
class ForecastManager: ObservableObject {

    @Published private(set) var dailyForecasts: [DailyForecast] = []
    @Published private(set) var lastFetchDate: Date?

    private var refreshTimer: Timer?
    private var currentLatitude: Double?
    private var currentLongitude: Double?

    /// Fetch daily forecast from Open-Meteo
    func fetchForecast(latitude: Double, longitude: Double) async {
        currentLatitude = latitude
        currentLongitude = longitude

        // Throttle: don't re-fetch if last fetch was less than 1 hour ago
        if let last = lastFetchDate, Date().timeIntervalSince(last) < 3600 {
            return
        }

        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(latitude)"
            + "&longitude=\(longitude)"
            + "&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max"
            + "&temperature_unit=fahrenheit"
            + "&timezone=auto"
            + "&forecast_days=4"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            var forecasts: [DailyForecast] = []
            let count = response.daily.time.count

            for i in 0..<count {
                guard let date = dateFormatter.date(from: response.daily.time[i]) else { continue }
                let forecast = DailyForecast(
                    date: date,
                    highTemp: response.daily.temperature_2m_max[i],
                    lowTemp: response.daily.temperature_2m_min[i],
                    weatherCode: response.daily.weather_code[i],
                    precipProbability: i < response.daily.precipitation_probability_max.count
                        ? response.daily.precipitation_probability_max[i] : nil
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

    /// Schedule periodic refresh every 6 hours
    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 21600, repeats: true) { [weak self] _ in
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
}

// MARK: - Open-Meteo JSON Response

private struct OpenMeteoResponse: Decodable {
    let daily: DailyData

    struct DailyData: Decodable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let weather_code: [Int]
        let precipitation_probability_max: [Int]
    }
}
