//
//  SensorCategorySection.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

struct SensorCategorySection: View {
    let categoryName: String
    let categoryIcon: String
    let sensorKeys: [String]
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?

    /// Init from PorchStationKit.SensorCategory + PorchWeatherData (new path)
    init(category: PorchStationKit.SensorCategory, sensorKeys: [String], porchData: PorchWeatherData) {
        self.categoryName = String(describing: category).camelCaseToWords()
        self.categoryIcon = category.iconName
        self.sensorKeys = sensorKeys
        self.porchData = porchData
        self.observation = nil
    }

    /// Init from AmbientWeather.SensorCategory + AmbientLastData (legacy path)
    init(category: AmbientWeather.SensorCategory, sensorKeys: [String], observation: AmbientLastData) {
        self.categoryName = String(describing: category).camelCaseToWords()
        self.categoryIcon = category.iconName
        self.sensorKeys = sensorKeys
        self.porchData = nil
        self.observation = observation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category header
            Label(categoryName, systemImage: categoryIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            // 2-column grid of sensor tiles
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(sensorKeys, id: \.self) { key in
                    if let porchData {
                        SensorTileView(sensorKey: key, porchData: porchData)
                    } else if let observation {
                        SensorTileView(sensorKey: key, observation: observation)
                    }
                }
            }
        }
    }
}
