//
//  SensorDashboardView.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather
import PorchStationKit

struct SensorDashboardView: View {
    let porchData: PorchWeatherData?
    let observation: AmbientLastData?

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

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            if let porchData {
                ForEach(porchData.availableSensorsByCategory, id: \.0) { category, sensorKeys in
                    SensorCategorySection(
                        category: category,
                        sensorKeys: sensorKeys,
                        porchData: porchData
                    )
                }
            } else if let observation {
                ForEach(observation.availableSensorsbyCategorySorted, id: \.0) { category, sensorKeys in
                    SensorCategorySection(
                        category: category,
                        sensorKeys: sensorKeys,
                        observation: observation
                    )
                }
            }
        }
    }
}
