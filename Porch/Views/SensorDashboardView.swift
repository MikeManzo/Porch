//
//  SensorDashboardView.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather

struct SensorDashboardView: View {
    let observation: AmbientLastData

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
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
