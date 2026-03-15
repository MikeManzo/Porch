//
//  AlertsSettingsTab.swift
//  Porch
//
//  Created by Mike Manzo on 3/15/26.
//

import SwiftUI

struct AlertsSettingsTab: View {
    @EnvironmentObject var manager: WeatherManager

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $manager.alertsEnabled) {
                    Label("Enable Alerts", systemImage: "bell.badge.fill")
                }
                .onChange(of: manager.alertsEnabled) { _, enabled in
                    if enabled {
                        manager.requestNotificationPermission()
                    }
                }
            }

            Section {
                HStack {
                    Text("High Temp (\u{00B0}F)")
                    Spacer()
                    TextField("", value: $manager.highTempAlert, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Low Temp (\u{00B0}F)")
                    Spacer()
                    TextField("", value: $manager.lowTempAlert, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
            } header: {
                Label("Temperature", systemImage: "thermometer.sun.fill")
                    .foregroundStyle(.red)
            }
            .disabled(!manager.alertsEnabled)

            Section {
                HStack {
                    Text("High Wind (mph)")
                    Spacer()
                    TextField("", value: $manager.highWindAlert, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
            } header: {
                Label("Wind", systemImage: "wind")
                    .foregroundStyle(.teal)
            }
            .disabled(!manager.alertsEnabled)

            Section {
                Toggle(isOn: $manager.leakAlertEnabled) {
                    Label("Water Leak Detection", systemImage: "drop.triangle.fill")
                }
                Toggle(isOn: $manager.batteryAlertEnabled) {
                    Label("Low Battery Warning", systemImage: "battery.25percent")
                }
            } header: {
                Label("Sensors", systemImage: "sensor.fill")
                    .foregroundStyle(.yellow)
            }
            .disabled(!manager.alertsEnabled)
        }
        .formStyle(.grouped)
    }
}
