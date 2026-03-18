//
//  AQICalculator.swift
//  Porch
//
//  Created by Mike Manzo on 3/18/26.
//

import SwiftUI

/// Calculates the EPA Air Quality Index (AQI) from PM2.5 concentration
struct AQICalculator {
    struct AQIResult {
        let value: Int
        let category: String
        let color: Color
    }

    /// EPA PM2.5 breakpoint table for AQI calculation
    private static let breakpoints: [(pmLow: Double, pmHigh: Double, aqiLow: Double, aqiHigh: Double, category: String, color: Color)] = [
        (0.0,   12.0,   0,   50,  "Good",                          .green),
        (12.1,  35.4,   51,  100, "Moderate",                      .yellow),
        (35.5,  55.4,   101, 150, "Unhealthy for Sensitive Groups", .orange),
        (55.5,  150.4,  151, 200, "Unhealthy",                     .red),
        (150.5, 250.4,  201, 300, "Very Unhealthy",                .purple),
        (250.5, 500.4,  301, 500, "Hazardous",                     .brown)
    ]

    static func calculate(pm25: Double) -> AQIResult {
        let clamped = min(max(pm25, 0), 500.4)
        for bp in breakpoints {
            if clamped >= bp.pmLow && clamped <= bp.pmHigh {
                let aqi = ((bp.aqiHigh - bp.aqiLow) / (bp.pmHigh - bp.pmLow)) * (clamped - bp.pmLow) + bp.aqiLow
                return AQIResult(value: Int(round(aqi)), category: bp.category, color: bp.color)
            }
        }
        return AQIResult(value: 500, category: "Hazardous", color: .brown)
    }
}
