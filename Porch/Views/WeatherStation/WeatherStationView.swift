//
//  WeatherStationView.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import SwiftUI
import SwiftData
import AmbientWeather
import UniformTypeIdentifiers

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
    @State private var draggingGraph: GraphPanel?
    @State private var hoveredGraph: GraphPanel?

    private static let graphOrderKey = "dashboardGraphOrder"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.graphOrderKey),
           let saved = try? JSONDecoder().decode([GraphPanel].self, from: data) {
            // Restore saved order, adding any new graphs from app updates
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
            // Rich dark background for Liquid Glass
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
                        CurrentConditionsPanel(observation: data.observation)

                        // Fixed: Atmospheric & Precipitation
                        HStack(alignment: .top, spacing: 16) {
                            AtmosphericPanel(observation: data.observation)
                            PrecipitationPanel(observation: data.observation)
                        }

                        // Reorderable graph panels
                        ForEach(visibleGraphs(for: data)) { graph in
                            graphContent(for: graph, data: data)
                                .overlay(alignment: .top) {
                                    GraphDragHandle(isVisible: hoveredGraph == graph) {
                                        draggingGraph = graph
                                        return NSItemProvider(object: graph.rawValue as NSString)
                                    }
                                }
                                .background {
                                    HoverTracker { hovering in
                                        if hovering {
                                            hoveredGraph = graph
                                        } else if hoveredGraph == graph {
                                            hoveredGraph = nil
                                        }
                                    }
                                }
                                .onDrop(of: [.plainText], delegate: GraphDropDelegate(
                                    graph: graph,
                                    graphs: $graphOrder,
                                    draggingGraph: $draggingGraph,
                                    onReorder: saveGraphOrder
                                ))
                                .opacity(draggingGraph == graph ? 0.5 : 1.0)
                        }

                        // Fixed: Weekly Extremes
                        WeeklyExtremesPanel()
                    }
                    .frame(maxWidth: .infinity)

                    // Right column (fixed width)
                    VStack(spacing: 16) {
                        WindPanel(observation: data.observation)
                        WindRosePanel()
                        IndoorPanel(observation: data.observation)
                        EnvironmentPanel(observation: data.observation)
                        LeakDetectionPanel(observation: data.observation)
                        RelayStatusPanel(observation: data.observation)
                        GardenPanel(observation: data.observation)
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
        graphOrder.filter { graph in
            switch graph {
            case .solarUV: data.observation.solarRadiation != nil
            case .rain: data.observation.dailyRainIn != nil
            case .pm25: data.observation.pm25 != nil
            default: true
            }
        }
    }

    private func saveGraphOrder() {
        if let data = try? JSONEncoder().encode(graphOrder) {
            UserDefaults.standard.set(data, forKey: Self.graphOrderKey)
        }
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
                    ) : nil
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
                    ) : nil
            )

        case .pressure:
            TrendChartView(
                title: "Pressure",
                icon: "barometer",
                valuePath: \.pressure,
                unitSuffix: manager.unitSystem == .metric ? " hPa" : " inHg",
                color: .purple,
                unitSystem: manager.unitSystem,
                convertToMetric: { $0 * 33.8639 }
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
                )
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
                    ) : nil
            )

        case .rain:
            TrendChartView(
                title: "Rain (Daily)",
                icon: "cloud.rain",
                valuePath: \.dailyRain,
                unitSuffix: manager.unitSystem == .metric ? " mm" : "\"",
                color: .blue,
                unitSystem: manager.unitSystem,
                convertToMetric: { $0 * 25.4 }
            )

        case .pm25:
            TrendChartView(
                title: "PM2.5 Air Quality",
                icon: "aqi.medium",
                valuePath: \.pm25,
                unitSuffix: " µg/m³",
                color: .green,
                unitSystem: manager.unitSystem
            )
        }
    }

    // MARK: - Top Bar

    private func topBar(data: AmbientWeatherData) -> some View {
        HStack {
            // Station info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(data.info.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    // Connection source indicator
                    Image(systemName: sourceIcon)
                        .foregroundStyle(statusColor)
                        .font(.system(size: 10))
                        .help(statusHelpText)
                }
                Text("Updated \(data.observation.observationDateFormatted)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            // Close button
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

// MARK: - Graph Drag Handle

/// Grip handle that appears on hover and serves as the drag source for reordering graphs
struct GraphDragHandle: View {
    var isVisible: Bool
    var onDragStarted: () -> NSItemProvider

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 36, height: 20)
            .background(.white.opacity(0.12), in: Capsule())
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: isVisible)
            .padding(.top, 6)
            .onDrag(onDragStarted)
    }
}

// MARK: - Graph Drop Delegate

/// Handles drag-and-drop reordering of graph panels
struct GraphDropDelegate: DropDelegate {
    let graph: GraphPanel
    @Binding var graphs: [GraphPanel]
    @Binding var draggingGraph: GraphPanel?
    let onReorder: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggingGraph = nil
        onReorder()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingGraph,
              dragging != graph,
              let fromIndex = graphs.firstIndex(of: dragging),
              let toIndex = graphs.firstIndex(of: graph) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            graphs.move(fromOffsets: IndexSet(integer: fromIndex),
                        toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        true
    }
}
