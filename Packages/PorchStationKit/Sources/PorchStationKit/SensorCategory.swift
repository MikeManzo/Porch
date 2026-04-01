//
//  SensorCategory.swift
//  PorchStationKit
//
//  Sensor categories for grouping and display.
//

import Foundation

/// Categories for organizing weather sensors in the UI
public enum SensorCategory: String, CaseIterable, Codable, Sendable, Hashable, Comparable {
    case temperature
    case humidity
    case wind
    case pressure
    case rain
    case solar
    case lightning
    case airQuality
    case indoor
    case soilTemperature
    case soilMoisture
    case soilTension
    case leafWetness
    case agriculturalDerived
    case leak
    case relay
    case battery
    case metadata
    case unknown

    /// SF Symbol icon name for this category
    public var iconName: String {
        switch self {
        case .temperature:          return "thermometer.medium"
        case .humidity:             return "humidity"
        case .wind:                 return "wind"
        case .pressure:             return "gauge.with.dots.needle.33percent"
        case .rain:                 return "cloud.rain"
        case .solar:                return "sun.max.fill"
        case .lightning:            return "bolt.fill"
        case .airQuality:           return "aqi.medium"
        case .indoor:               return "house.fill"
        case .soilTemperature:      return "thermometer.medium"
        case .soilMoisture:         return "drop.fill"
        case .soilTension:          return "arrow.down.to.line"
        case .leafWetness:          return "leaf.fill"
        case .agriculturalDerived:  return "sun.horizon.fill"
        case .leak:                 return "drop.triangle.fill"
        case .relay:                return "app.connected.to.app.below.fill"
        case .battery:              return "battery.25"
        case .metadata:             return "info.circle"
        case .unknown:              return "questionmark.circle"
        }
    }

    /// Display sort order
    private var sortOrder: Int {
        switch self {
        case .temperature:          return 0
        case .humidity:             return 1
        case .wind:                 return 2
        case .pressure:             return 3
        case .rain:                 return 4
        case .solar:                return 5
        case .lightning:            return 6
        case .airQuality:           return 7
        case .indoor:               return 8
        case .soilTemperature:      return 9
        case .soilMoisture:         return 10
        case .soilTension:          return 11
        case .leafWetness:          return 12
        case .agriculturalDerived:  return 13
        case .leak:                 return 14
        case .relay:                return 15
        case .battery:              return 16
        case .metadata:             return 17
        case .unknown:              return 99
        }
    }

    public static func < (lhs: SensorCategory, rhs: SensorCategory) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
