//
//  WeatherStationView.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import SwiftData
import AmbientWeather
import PorchStationKit

// MARK: - Graph Panel Identifier

/// Identifies each reorderable trend-chart graph in the left column
enum GraphPanel: String, CaseIterable, Codable, Identifiable {
    case temperature
    case humidity
    case pressure
    case windSpeed
    case solarUV
    case rain
    case pm25

    var id: String { rawValue }

    static let defaultOrder: [GraphPanel] = allCases
}

// MARK: - Weather Station View

/// Full weather station dashboard window with Liquid Glass panels
struct WeatherStationView: View {
    @EnvironmentObject var manager: WeatherManager
    @Environment(\.dismiss) private var dismiss
    @State private var graphOrder: [GraphPanel]
    @State private var hoveredGraph: GraphPanel?

    private static let graphOrderKey = "dashboardGraphOrder"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.graphOrderKey),
           let saved = try? JSONDecoder().decode([GraphPanel].self, from: data) {
            var order = saved.filter { GraphPanel.allCases.contains($0) }
            for graph in GraphPanel.allCases where !order.contains(graph) {
                order.append(graph)
            }
            _graphOrder = State(initialValue: order)
        } else {
            _graphOrder = State(initialValue: GraphPanel.defaultOrder)
        }
    }

    var body: some View {
        ZStack {
            backgroundGradient

            if let data = manager.weatherData {
                dashboardContent(data: data)
            } else {
                emptyState
            }
        }
        .frame(minWidth: 1100, minHeight: 780)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.04, green: 0.08, blue: 0.20),
                Color(red: 0.06, green: 0.06, blue: 0.18),
                Color(red: 0.03, green: 0.10, blue: 0.18),
                Color(red: 0.05, green: 0.07, blue: 0.22),
                Color(red: 0.04, green: 0.06, blue: 0.16),
                Color(red: 0.06, green: 0.04, blue: 0.14),
                Color(red: 0.04, green: 0.08, blue: 0.19),
                Color(red: 0.05, green: 0.05, blue: 0.15)
            ]
        )
        .ignoresSafeArea()
    }

    // MARK: - Dashboard Content

    @ViewBuilder
    private func dashboardContent(data: AmbientWeatherData) -> some View {
        let porchData = manager.porchWeatherData

        ScrollView {
            GlassEffectContainer {
            VStack(spacing: 16) {
                // Top bar
                topBar(data: data)

                // Main two-column layout
                HStack (alignment: .top, spacing: 16) {
                    // Left column (flexible width)
                    VStack(spacing: 16) {
                        // Fixed: Current Conditions
                        if let porchData {
                            CurrentConditionsPanel(porchData: porchData)
                        } else {
                            CurrentConditionsPanel(observation: data.observation)
                        }

                        // Fixed: Atmospheric & Precipitation (equal height)
                        HStack(spacing: 16) {
                            if let porchData {
                                AtmosphericPanel(porchData: porchData)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                PrecipitationPanel(porchData: porchData)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            } else {
                                AtmosphericPanel(observation: data.observation)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                PrecipitationPanel(observation: data.observation)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)

                        // Reorderable graph panels
                        let visible = visibleGraphs(for: data)
                        ForEach(visible) { graph in
                            VStack(spacing: 0) {
                                GraphReorderBar(
                                    isVisible: hoveredGraph == graph,
                                    canMoveUp: visible.first != graph,
                                    canMoveDown: visible.last != graph,
                                    onMoveUp: { moveGraph(graph, direction: .up, in: visible) },
                                    onMoveDown: { moveGraph(graph, direction: .down, in: visible) }
                                )

                                graphContent(for: graph, data: data)
                            }
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                            .background {
                                HoverTracker { hovering in
                                    if hovering {
                                        hoveredGraph = graph
                                    } else if hoveredGraph == graph {
                                        hoveredGraph = nil
                                    }
                                }
                            }
                        }

                    }
                    .frame(maxWidth: .infinity)

                    // Right column (fixed width)
                    VStack(spacing: 16) {
                        if let porchData {
                            WindPanel(porchData: porchData)
                        } else {
                            WindPanel(observation: data.observation)
                        }
                        WindRosePanel()
                        if let porchData {
                            IndoorPanel(porchData: porchData)
                            EnvironmentPanel(porchData: porchData)
                        } else {
                            IndoorPanel(observation: data.observation)
                            EnvironmentPanel(observation: data.observation)
                        }
                        WeeklyExtremesPanel()
                        if let porchData {
                            LeakDetectionPanel(porchData: porchData)
                            GardenPanel(porchData: porchData)
                        } else {
                            LeakDetectionPanel(observation: data.observation)
                            GardenPanel(observation: data.observation)
                        }
                        // Relay panel stays Ambient-only
                        RelayStatusPanel(observation: data.observation)
                    }
                    .frame(width: 360)
                    }
                }
                .padding(24)
            }
        }
    }

    // MARK: - Graph Order

    /// Returns only graphs whose sensor data is available, preserving the user's custom order
    private func visibleGraphs(for data: AmbientWeatherData) -> [GraphPanel] {
        let porchData = manager.porchWeatherData
        return graphOrder.filter { graph in
            switch graph {
            case .solarUV:
                porchData?.solarRadiation != nil || data.observation.solarRadiation != nil
            case .rain:
                porchData?.dailyRainIn != nil || data.observation.dailyRainIn != nil
            case .pm25:
                porchData?.pm25 != nil || data.observation.pm25 != nil
            default: true
            }
        }
    }

    private func saveGraphOrder() {
        if let data = try? JSONEncoder().encode(graphOrder) {
            UserDefaults.standard.set(data, forKey: Self.graphOrderKey)
        }
    }

    private enum MoveDirection { case up, down }

    private func moveGraph(_ graph: GraphPanel, direction: MoveDirection, in visible: [GraphPanel]) {
        guard let visibleIndex = visible.firstIndex(of: graph) else { return }
        let adjacentIndex = direction == .up ? visibleIndex - 1 : visibleIndex + 1
        guard visible.indices.contains(adjacentIndex) else { return }

        let adjacent = visible[adjacentIndex]
        guard let from = graphOrder.firstIndex(of: graph),
              let to = graphOrder.firstIndex(of: adjacent) else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            graphOrder.swapAt(from, to)
        }
        saveGraphOrder()
    }

    // MARK: - Graph Content

    @ViewBuilder
    private func graphContent(for graph: GraphPanel, data: AmbientWeatherData) -> some View {
        switch graph {
        case .temperature:
            TrendChartView(
                title: "Temperature",
                icon: "thermometer.medium",
                valuePath: \.temperature,
                unitSuffix: manager.unitSystem == .metric ? "°C" : "°F",
                color: .orange,
                unitSystem: manager.unitSystem,
                convertToMetric: { ($0 - 32) * 5.0 / 9.0 },
                secondary: data.observation.tempInF != nil
                    ? SecondarySeries(
                        label: "Indoor",
                        valuePath: \.indoorTemp,
                        color: .green,
                        convertToMetric: { ($0 - 32) * 5.0 / 9.0 }
                    ) : nil,
                showGlass: false
            )

        case .humidity:
            TrendChartView(
                title: "Humidity",
                icon: "humidity",
                valuePath: \.humidityDouble,
                unitSuffix: "%",
                color: .cyan,
                unitSystem: manager.unitSystem,
                secondary: data.observation.humidityIn != nil
                    ? SecondarySeries(
                        label: "Indoor",
                        valuePath: \.indoorHumidityDouble,
                        color: .green
                    ) : nil,
                showGlass: false
            )

        case .pressure:
            TrendChartView(
                title: "Pressure",
                icon: "barometer",
                valuePath: \.pressure,
                unitSuffix: manager.unitSystem == .metric ? " hPa" : " inHg",
                color: .purple,
                unitSystem: manager.unitSystem,
                convertToMetric: { $0 * 33.8639 },
                showGlass: false
            )

        case .windSpeed:
            TrendChartView(
                title: "Wind Speed",
                icon: "wind",
                valuePath: \.windSpeed,
                unitSuffix: manager.unitSystem == .metric ? " km/h" : " mph",
                color: .cyan,
                unitSystem: manager.unitSystem,
                convertToMetric: { $0 * 1.60934 },
                secondary: SecondarySeries(
                    label: "Gust",
                    valuePath: \.windGust,
                    color: .orange,
                    convertToMetric: { $0 * 1.60934 }
                ),
                showGlass: false
            )

        case .solarUV:
            TrendChartView(
                title: "Solar & UV",
                icon: "sun.max.fill",
                valuePath: \.solarRadiation,
                unitSuffix: " W/m²",
                color: .yellow,
                unitSystem: manager.unitSystem,
                secondary: data.observation.uv != nil
                    ? SecondarySeries(
                        label: "UV",
                        valuePath: \.uvDouble,
                        color: .purple
                    ) : nil,
                showGlass: false
            )

        case .rain:
            TrendChartView(
                title: "Rain (Daily)",
                icon: "cloud.rain",
                valuePath: \.dailyRain,
                unitSuffix: manager.unitSystem == .metric ? " mm" : "\"",
                color: .blue,
                unitSystem: manager.unitSystem,
                convertToMetric: { $0 * 25.4 },
                yFloorZero: true,
                showGlass: false
            )

        case .pm25:
            TrendChartView(
                title: "PM2.5 Air Quality",
                icon: "aqi.medium",
                valuePath: \.pm25,
                unitSuffix: " µg/m³",
                color: .green,
                unitSystem: manager.unitSystem,
                showGlass: false
            )
        }
    }

    // MARK: - Top Bar

    private func topBar(data: AmbientWeatherData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(data.info.name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Image(systemName: sourceIcon)
                        .foregroundStyle(statusColor)
                        .font(.system(size: 10))
                        .help(statusHelpText)
                }
                if let porchData = manager.porchWeatherData {
                    Text("Updated \(porchData.observationDateFormatted)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    Text("Updated \(data.observation.observationDateFormatted)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Status Indicator

    private var sourceIcon: String {
        switch manager.activeDataSource {
        case .ambient: "cloud.fill"
        case .ecowitt: "point.3.filled.connected.trianglepath.dotted"
        case .none: "circle.fill"
        }
    }

    private var statusColor: Color {
        switch manager.connectionStatus {
        case .connected:    .green
        case .connecting:   .orange
        case .disconnected: .red
        }
    }

    private var statusHelpText: String {
        switch (manager.connectionStatus, manager.activeDataSource) {
        case (.connected, .ambient):  "Connected via Cloud"
        case (.connected, .ecowitt):  "Connected via Local"
        case (.connected, .none):     "Connected"
        case (.connecting, _):        "Connecting..."
        case (.disconnected, _):      "Disconnected"
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.3))
                .symbolRenderingMode(.hierarchical)
            Text("Waiting for weather data…")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Hover Tracker (AppKit-backed)

/// Reliable mouse hover detection using NSTrackingArea, bypassing SwiftUI's
/// onHover limitations with complex child views and glass effects.
struct HoverTracker: NSViewRepresentable {
    var onHoverChanged: (Bool) -> Void

    func makeNSView(context: Context) -> HoverTrackingNSView {
        let view = HoverTrackingNSView()
        view.onHoverChanged = onHoverChanged
        return view
    }

    func updateNSView(_ nsView: HoverTrackingNSView, context: Context) {
        nsView.onHoverChanged = onHoverChanged
    }

    class HoverTrackingNSView: NSView {
        var onHoverChanged: ((Bool) -> Void)?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach { removeTrackingArea($0) }
            addTrackingArea(NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
                owner: self,
                userInfo: nil
            ))
        }

        override func mouseEntered(with event: NSEvent) {
            onHoverChanged?(true)
        }

        override func mouseExited(with event: NSEvent) {
            onHoverChanged?(false)
        }
    }
}

// MARK: - Graph Reorder Bar

/// Reorder controls shown on hover — up/down buttons for moving graph panels.
struct GraphReorderBar: View {
    var isVisible: Bool
    var canMoveUp: Bool
    var canMoveDown: Bool
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Spacer()

            Button(action: onMoveUp) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary.opacity(canMoveUp ? 0.5 : 0.15))
            }
            .buttonStyle(.plain)
            .disabled(!canMoveUp)

            Button(action: onMoveDown) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary.opacity(canMoveDown ? 0.5 : 0.15))
            }
            .buttonStyle(.plain)
            .disabled(!canMoveDown)

            Spacer()
        }
        .frame(height: 20)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isVisible)
    }
}
