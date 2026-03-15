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
            Section("Menubar Sensor") {
                if !manager.sensorsByCategory.isEmpty {
                    Picker("Sensor to Display", selection: $manager.selectedSensorKey) {
                        ForEach(manager.sensorsByCategory, id: \.0) { category, keys in
                            Section(header: Label(
                                String(describing: category).camelCaseToWords(),
                                systemImage: category.iconName
                            )) {
                                ForEach(keys, id: \.self) { key in
                                    Text(AmbientLastData.sensorDescriptions[key] ?? key)
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
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                    }
                } else {
                    ContentUnavailableView(
                        "No Sensors Available",
                        systemImage: "sensor",
                        description: Text("Connect to a station in the Connection tab to see available sensors.")
                    )
                }
            }
        }
        .formStyle(.grouped)
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
