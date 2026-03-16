//
//  SensorsSettingsTab.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI
import MapKit
import AmbientWeather

struct SensorsSettingsTab: View {
    @EnvironmentObject var manager: WeatherManager

    var body: some View {
        if let observation = manager.weatherData?.observation {
            let categories = observation.availableSensorsbyCategorySorted

            Form {
                if let coords = manager.weatherData?.info.coords.coords {
                    Section {
                        let position = MapCameraPosition.region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: coords.lat, longitude: coords.lon),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                        Map(initialPosition: position) {
                            Marker(manager.stationName, coordinate: CLLocationCoordinate2D(
                                latitude: coords.lat, longitude: coords.lon
                            ))
                        }
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .allowsHitTesting(false)

                        LabeledContent("Station", value: manager.stationName)
                        LabeledContent("Location", value: manager.stationLocation)
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(.red, in: RoundedRectangle(cornerRadius: 5))
                            Text("Station Location")
                        }
                    }
                }

                ForEach(categories, id: \.0) { category, keys in
                    Section {
                        ForEach(keys, id: \.self) { key in
                            LabeledContent {
                                if category == .batteryStatus {
                                    batteryStatusIndicator(for: key, observation: observation)
                                } else {
                                    Text(SensorFormatter.menuBarString(for: key, from: observation, unitSystem: manager.unitSystem))
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundStyle(.primary)
                                }
                            } label: {
                                Text(SensorFormatter.sensorDescription(for: key, unitSystem: manager.unitSystem))
                            }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(categoryColor(for: category), in: RoundedRectangle(cornerRadius: 5))
                            Text(String(describing: category).camelCaseToWords())
                        }
                    }
                }
            }
            .formStyle(.grouped)
        } else {
            ContentUnavailableView(
                "No Station Connected",
                systemImage: "sensor",
                description: Text("Connect to a station in the Connection tab to view sensor readings.")
            )
        }
    }

    // MARK: - Category Colors

    private func categoryColor(for category: SensorCategory) -> Color {
        switch category {
        case .temperature: .red
        case .humidityDewPoint: .blue
        case .wind: .teal
        case .pressure: .indigo
        case .rainPrecipitation: .cyan
        case .solarUV: .orange
        case .lightning: .yellow
        case .airQuality: .purple
        case .soilTemperature, .soilMoisture, .soilTension: .brown
        case .leafWetness: .green
        case .batteryStatus: .gray
        default: .secondary
        }
    }

    // MARK: - Battery Status

    /// Shows a green (good) or red (bad) circle for battery sensors. 1 = good, 0 = bad.
    private func batteryStatusIndicator(for key: String, observation: AmbientLastData) -> some View {
        let isGood: Bool = {
            guard let value = SensorFormatter.numericValue(for: key, from: observation) else {
                if let str = Mirror(reflecting: observation).children.first(where: { $0.label == key })?.value as? Optional<String>,
                   let unwrapped = str {
                    return unwrapped == "1"
                }
                return false
            }
            return value >= 1
        }()

        return HStack(spacing: 6) {
            Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(isGood ? .green : .red)
            Text(isGood ? "Good" : "Low")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(isGood ? Color.primary : Color.red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            (isGood ? Color.green : Color.red).opacity(0.1),
            in: Capsule()
        )
    }
}
