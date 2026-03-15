//
//  SensorCategorySection.swift
//  Porch
//
//  Created by Mike Manzo on 3/13/26.
//

import SwiftUI
import AmbientWeather

struct SensorCategorySection: View {
    let category: SensorCategory
    let sensorKeys: [String]
    let observation: AmbientLastData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category header
            Label(
                String(describing: category).camelCaseToWords(),
                systemImage: category.iconName
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)

            // 2-column grid of sensor tiles
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(sensorKeys, id: \.self) { key in
                    SensorTileView(sensorKey: key, observation: observation)
                }
            }
        }
    }
}
