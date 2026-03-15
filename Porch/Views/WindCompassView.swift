//
//  WindCompassView.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI

/// Small circular compass rose showing wind direction with a rotatable arrow
struct WindCompassView: View {
    let degrees: Int

    var body: some View {
        ZStack {
            // Compass ring
            Circle()
                .stroke(.quaternary, lineWidth: 1)
                .frame(width: 20, height: 20)

            // Direction arrow
            Image(systemName: "location.north.fill")
                .font(.system(size: 10))
                .foregroundStyle(.primary)
                .rotationEffect(.degrees(Double(degrees)))
        }
    }
}
