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
                Toggle(isOn: manager.deferredBinding(for: \.alertsEnabled)) {
                    Label("Enable Alerts", systemImage: "bell.badge.fill")
                }
                .onChange(of: manager.alertsEnabled) { _, enabled in
                    if enabled {
                        manager.requestNotificationPermission()
                    }
                }
            }

            Section {
                Picker(selection: manager.deferredBinding(for: \.defaultReAlertInterval)) {
                    Text("30 Minutes").tag(TimeInterval(1800))
                    Text("1 Hour").tag(TimeInterval(3600))
                    Text("4 Hours").tag(TimeInterval(14400))
                    Text("8 Hours").tag(TimeInterval(28800))
                    Text("24 Hours").tag(TimeInterval(86400))
                } label: {
                    Label("Re-Alert Interval", systemImage: "clock.arrow.circlepath")
                }

                Text("How often to repeat an alert if you don't interact with the notification. Snooze options on each notification override this.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Notification Timing", systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(.blue)
            }
            .disabled(!manager.alertsEnabled)

            Section {
                Toggle(isOn: manager.deferredBinding(for: \.severeWeatherAlertEnabled)) {
                    Label("Severe Weather Notifications", systemImage: "exclamationmark.triangle.fill")
                }

                Text("Sends notifications for Severe and Extreme weather alerts from the National Weather Service via Apple WeatherKit. Alerts are checked every 15 minutes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Severe Weather", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            } footer: {
                Text("Active alerts always appear in the popover regardless of this setting.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .disabled(!manager.alertsEnabled)

            Section {
                Toggle(isOn: manager.deferredBinding(for: \.tempAlertEnabled)) {
                    Label("Temperature Alerts", systemImage: "thermometer.sun.fill")
                }

                HStack {
                    Text("High Temp (\u{00B0}F)")
                    Spacer()
                    TextField("", value: manager.deferredBinding(for: \.highTempAlert), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(!manager.tempAlertEnabled)

                HStack {
                    Text("Low Temp (\u{00B0}F)")
                    Spacer()
                    TextField("", value: manager.deferredBinding(for: \.lowTempAlert), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(!manager.tempAlertEnabled)
            } header: {
                Label("Temperature", systemImage: "thermometer.sun.fill")
                    .foregroundStyle(.red)
            }
            .disabled(!manager.alertsEnabled)

            Section {
                Toggle(isOn: manager.deferredBinding(for: \.windAlertEnabled)) {
                    Label("Wind Alerts", systemImage: "wind")
                }

                HStack {
                    Text("High Wind (mph)")
                    Spacer()
                    TextField("", value: manager.deferredBinding(for: \.highWindAlert), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(!manager.windAlertEnabled)
            } header: {
                Label("Wind", systemImage: "wind")
                    .foregroundStyle(.teal)
            }
            .disabled(!manager.alertsEnabled)

            Section {
                Toggle(isOn: manager.deferredBinding(for: \.weatherAlertEnabled)) {
                    Label("Weather Alerts", systemImage: "cloud.sun.fill")
                }

                HStack {
                    Text("High UV Index")
                    Spacer()
                    TextField("", value: manager.deferredBinding(for: \.highUVAlert), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(!manager.weatherAlertEnabled)

                HStack {
                    Text("Heavy Rain (\"/hr)")
                    Spacer()
                    TextField("", value: manager.deferredBinding(for: \.heavyRainAlert), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(!manager.weatherAlertEnabled)

                HStack {
                    Text("High Humidity (%)")
                    Spacer()
                    TextField("", value: manager.deferredBinding(for: \.highHumidityAlert), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(!manager.weatherAlertEnabled)
            } header: {
                Label("Weather", systemImage: "cloud.sun.fill")
                    .foregroundStyle(.cyan)
            }
            .disabled(!manager.alertsEnabled)

            Section {
                Toggle(isOn: manager.deferredBinding(for: \.lightningAlertEnabled)) {
                    Label("Lightning Detection", systemImage: "bolt.fill")
                }
                Toggle(isOn: manager.deferredBinding(for: \.leakAlertEnabled)) {
                    Label("Water Leak Detection", systemImage: "drop.triangle.fill")
                }
                Toggle(isOn: manager.deferredBinding(for: \.batteryAlertEnabled)) {
                    Label("Low Battery Warning", systemImage: "battery.25percent")
                }
            } header: {
                Label("Sensors", systemImage: "sensor.fill")
                    .foregroundStyle(.yellow)
            }
            .disabled(!manager.alertsEnabled)

            Section {
                Toggle(isOn: manager.deferredBinding(for: \.airQualityAlertEnabled)) {
                    Label("Air Quality Alerts", systemImage: "aqi.medium")
                }

                HStack {
                    Text("PM2.5 (µg/m³)")
                    Spacer()
                    TextField("", value: manager.deferredBinding(for: \.highPM25Alert), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(!manager.airQualityAlertEnabled)

                HStack {
                    Text("CO₂ (ppm)")
                    Spacer()
                    TextField("", value: manager.deferredBinding(for: \.highCO2Alert), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                }
                .disabled(!manager.airQualityAlertEnabled)
            } header: {
                Label("Air Quality", systemImage: "aqi.medium")
                    .foregroundStyle(.purple)
            }
            .disabled(!manager.alertsEnabled)
        }
        .formStyle(.grouped)
    }
}
