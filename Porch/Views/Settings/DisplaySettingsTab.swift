//
//  DisplaySettingsTab.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather

struct DisplaySettingsTab: View {
    @EnvironmentObject var manager: WeatherManager

    var body: some View {
        Form {
            Section("Units") {
                Picker("Unit System", selection: manager.deferredBinding(for: \.unitSystem)) {
                    ForEach(UnitSystem.allCases) { system in
                        Text(system.displayName).tag(system)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Menubar Sensor") {
                if !manager.sensorsByCategory.isEmpty {
                    Picker("Sensor to Display", selection: manager.deferredBinding(for: \.selectedSensorKey)) {
                        ForEach(manager.sensorsByCategory, id: \.0) { category, keys in
                            Section(header: Label(
                                String(describing: category).camelCaseToWords(),
                                systemImage: category.iconName
                            )) {
                                ForEach(keys, id: \.self) { key in
                                    Text(SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem))
                                        .tag(key)
                                }
                            }
                        }
                    }

                    // Live preview of what the menubar will show
                    LabeledContent("Menubar Preview") {
                        HStack(spacing: 4) {
                            Image(systemName: manager.menuBarIcon)
                                .foregroundStyle(.secondary)
                            Text(manager.menuBarLabel)
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                } else {
                    ContentUnavailableView(
                        "No Sensors Available",
                        systemImage: "sensor",
                        description: Text("Connect to a station in the Connection tab to see available sensors.")
                    )
                }
            }
            Section("Quick Stats Bar") {
                if !manager.sensorsByCategory.isEmpty {
                    Text("Choose up to 4 sensors for the quick stats bar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(0..<4, id: \.self) { index in
                        Picker("Slot \(index + 1)", selection: quickStatBinding(at: index)) {
                            Text("None").tag("")
                            ForEach(manager.sensorsByCategory, id: \.0) { category, keys in
                                Section(header: Text(String(describing: category).camelCaseToWords())) {
                                    ForEach(keys, id: \.self) { key in
                                        Text(SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem))
                                            .tag(key)
                                    }
                                }
                            }
                        }
                    }

                    // Live preview of Quick Stats Bar
                    if let observation = manager.weatherData?.observation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PREVIEW")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .tracking(1.2)

                            HStack(spacing: 0) {
                                ForEach(Array(manager.quickStatKeys.enumerated()), id: \.element) { index, key in
                                    if index > 0 {
                                        Rectangle()
                                            .fill(.quaternary)
                                            .frame(width: 1, height: 36)
                                    }
                                    VStack(spacing: 3) {
                                        Image(systemName: quickStatIcon(for: key))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(SensorFormatter.menuBarString(for: key, from: observation, unitSystem: manager.unitSystem))
                                            .font(.system(.callout, design: .rounded, weight: .semibold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                        Text(quickStatLabel(for: key))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func quickStatLabel(for key: String) -> String {
        switch key {
        case "tempF", "tempf": return "Temp"
        case "feelsLike": return "Feels"
        case "windSpeedMPH", "windspeedmph": return "Wind"
        case "windGustMPH", "windgustmph": return "Gust"
        case "maxDailyGust", "maxdailygust": return "Max Gust"
        case "humidity": return "Humidity"
        case "baromRelIn", "baromrelin": return "Pressure"
        case "baromAbsIn", "baromabsin": return "Abs Press"
        case "uv": return "UV"
        case "solarRadiation", "solarradiation": return "Solar"
        case "dailyRainIn", "dailyrainin": return "Rain"
        case "hourlyRainIn", "hourlyrainin": return "Rain/hr"
        case "dewPoint": return "Dew Pt"
        case "tempInF", "tempinf": return "Indoor"
        case "humidityIn", "humidityin": return "In Humid"
        case "windDir", "winddir": return "Wind Dir"
        case "pm25": return "PM2.5"
        case "co2": return "CO₂"
        default:
            return SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem)
                .components(separatedBy: " ").first ?? key
        }
    }

    private func quickStatIcon(for key: String) -> String {
        switch key {
        case "windSpeedMPH": return "wind"
        case "humidity": return "humidity"
        case "baromRelIn": return "gauge.with.dots.needle.33percent"
        case "uv": return "sun.max.trianglebadge.exclamationmark"
        default:
            return (AmbientLastData.propertyCategories[key] ?? .unknown).iconName
        }
    }

    private func quickStatBinding(at index: Int) -> Binding<String> {
        Binding(
            get: { index < manager.quickStatKeys.count ? manager.quickStatKeys[index] : "" },
            set: { newValue in
                DispatchQueue.main.async {
                    var keys = manager.quickStatKeys
                    while keys.count <= index { keys.append("") }
                    keys[index] = newValue
                    manager.quickStatKeys = keys.filter { !$0.isEmpty }
                }
            }
        )
    }
}

// MARK: - String Helper

extension String {
    /// Converts "camelCase" to "Camel Case"
    func camelCaseToWords() -> String {
        unicodeScalars.reduce("") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar) && !result.isEmpty {
                return result + " " + String(scalar)
            }
            return result + String(scalar)
        }
        .localizedCapitalized
    }
}


