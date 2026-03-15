# Porch

**A real-time macOS menubar weather station dashboard for [Ambient Weather](https://ambientweather.net) personal weather stations.**

Porch lives quietly in your menubar, streaming live sensor data from your Ambient Weather station over WebSocket. One click opens a rich, dark-themed dashboard with everything from temperature and wind to soil moisture, air quality, and lightning strikes — all updating in real-time.

---

## Features

### Live Menubar Display
- Configurable sensor shown directly in the menubar (temperature, wind, humidity, or any available sensor)
- Always-visible at a glance — no window to manage

### Rich Weather Dashboard
- **Weather Hero** — Large temperature readout with feels-like, humidity, and dynamic condition icons (rain, lightning, wind, sun) that adapt to current weather
- **Daily Extremes** — Today's high/low temperature and peak wind gust, resetting automatically at midnight
- **Quick Stats Bar** — Four customizable stat slots with Liquid Glass treatment; includes a wind compass rose and barometric pressure trend arrows (rising/falling/steady)
- **Conditions Grid** — Dew point, solar radiation, UV index (with severity labels), indoor climate, max daily gust, lightning detail (distance + time since last strike), and last rain timestamp
- **Air Quality** — PM2.5 with full EPA AQI color scale and CO2 with health-level coloring
- **Rain Summary** — Hourly, daily, weekly, monthly, yearly, and event rainfall in a compact grid
- **Garden & Soil** — Conditional section for soil temperature, moisture, tension, leaf wetness, GDD, and evapotranspiration (appears only when agricultural sensors are detected)
- **All Sensors** — Expandable categorized list of every sensor reporting from your station

### Multi-Station Support
- Connect multiple stations with comma-separated API keys
- Segmented station picker to switch between them without disconnecting
- Per-station data tracking and history

### Customizable Quick Stats
- Choose up to 4 sensors for the quick stats bar
- Live preview in settings shows exactly what you'll see
- Wind direction rendered as a miniature compass rose

### Smart Alerts
- **Temperature** — Configurable high and low thresholds
- **Wind** — High wind speed alerts
- **Water Leak** — Monitors up to 4 leak sensors with per-sensor identification
- **Low Battery** — Tracks 14 battery keys across all connected sensors
- Delivered via macOS Notification Center, throttled to one alert per key every 30 minutes

### Historical Data Logging
- Automatic snapshots saved every 60 seconds via SwiftData
- 7-day rolling window with automatic pruning
- Tracks temperature, humidity, wind, pressure, rain, solar, UV, air quality, and indoor readings

### Imperial & Metric Units
- One-toggle switch between Imperial and Metric
- Automatic conversion across all views: °F↔°C, mph↔km/h, inHg↔hPa, in↔mm, mi↔km
- Smart formatting with appropriate decimal precision per measurement type

### Polished Settings
- Dark-themed sidebar navigation with color-coded category icons
- **Display** — Unit system, menubar sensor picker with live preview, quick stats customization
- **Sensors** — Live categorized readings with color-coded section badges and battery status pills (green/red)
- **Alerts** — Per-category threshold configuration with colored section headers
- **Connection** — API credential management, Liquid Glass connect/disconnect buttons, animated status indicator
- **General** — Launch at login, app info, and link to Ambient Weather dashboard

### Low Battery Warning
- Red banner appears at the top of the dashboard when any sensor reports low battery
- Lists affected sensors by name

---

## Requirements

- **macOS 26** (Tahoe) or later
- **Xcode 26** for building from source
- An [Ambient Weather](https://ambientweather.net) personal weather station
- Ambient Weather **Application Key** and **API Key** — get yours at [ambientweather.net/account](https://ambientweather.net/account)

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/MikeManzo/Porch.git
   cd Porch
   ```

2. Open `Porch.xcodeproj` in Xcode

3. Build and run (the app appears in your menubar — no Dock icon)

4. Click the menubar icon → **Settings** → **Connection**

5. Enter your Application Key and API Key, then click **Search for Stations**

6. Your station data will begin streaming in real-time

---

## Architecture

```
Ambient Weather WebSocket API
            │
            ▼
┌───────────────────────────────────┐
│   AmbientWeatherSocket Package    │
│   (WebSocket transport + models)  │
└───────────┬───────────────────────┘
            │
            ▼
┌───────────────────────────────────┐
│        WeatherManager             │
│  (@MainActor ObservableObject)    │
│                                   │
│  • Multi-station routing          │
│  • Pressure trend analysis        │
│  • Daily extreme tracking         │
│  • Alert threshold checking       │
│  • History snapshot scheduling    │
│  • Unit system management         │
└───────┬───────────┬───────────────┘
        │           │
        ▼           ▼
   MenuBar       Settings
   Popover        Window
```

**Data flows** from WebSocket → `WeatherManager` → SwiftUI views via `@EnvironmentObject`. On each observation, the manager runs a processing pipeline: pressure trend calculation → daily extreme updates → alert checks → historical snapshot save.

**Persistence** uses two layers:
- **UserDefaults** for preferences, credentials, daily extremes, and quick stat configuration
- **SwiftData** for 7-day rolling historical snapshots (`WeatherSnapshot` model)

---

## Dependencies

| Package | Purpose |
|---------|---------|
| [AmbientWeatherSocket](https://github.com/MikeManzo/AmbientWeatherSocket) | WebSocket connection to Ambient Weather API, data models, and sensor categorization |

All other frameworks are Apple system frameworks: SwiftUI, SwiftData, Combine, UserNotifications, and ServiceManagement.

---

## Sensor Categories

Porch organizes sensor data into categories provided by the AmbientWeatherSocket package:

| Category | Examples |
|----------|----------|
| **Temperature** | Outdoor temp, indoor temp, feels-like, dew point |
| **Humidity & Dew Point** | Outdoor/indoor humidity, dew point |
| **Wind** | Speed, gust, direction, max daily gust |
| **Atmospheric Pressure** | Absolute and relative with trend analysis |
| **Rain/Precipitation** | Hourly, daily, weekly, monthly, yearly, event, last rain |
| **Solar & UV** | Solar radiation (W/m²), UV index |
| **Lightning** | Strike count, distance, time since last |
| **Air Quality** | PM2.5 (EPA AQI scale), CO2 |
| **Soil Temperature** | Up to 10 sensors |
| **Soil Moisture** | Up to 10 sensors |
| **Soil Tension** | Water potential sensors |
| **Leaf Wetness** | Leaf moisture sensors |
| **Leak Detection** | Up to 4 water leak sensors |
| **Battery Status** | 14 battery indicators across all sensor types |
| **Agricultural/Derived** | GDD, evapotranspiration |

---

## Project Structure

```
Porch/
├── PorchApp.swift                          # App entry, MenuBarExtra, SwiftData container
├── Porch.entitlements                      # Sandbox + network client
├── Assets.xcassets/                        # App icon and assets
│
├── Managers/
│   ├── WeatherManager.swift                # Central state, WebSocket, alerts, extremes
│   └── HistoryManager.swift                # SwiftData snapshots, 7-day retention
│
├── Models/
│   └── WeatherSnapshot.swift               # SwiftData @Model for historical data
│
├── Utilities/
│   └── SensorFormatter.swift               # Unit conversion, value formatting, descriptions
│
└── Views/
    ├── MenuBarPopoverView.swift            # Main dashboard layout
    ├── WeatherHeroView.swift               # Large temp display with condition icon
    ├── QuickStatsBar.swift                 # Customizable 4-stat Liquid Glass bar
    ├── DailyExtremesView.swift             # Hi/Lo temp + peak wind
    ├── ConditionsGridView.swift            # Secondary conditions (UV, solar, PM2.5, etc.)
    ├── RainSummaryView.swift               # Rain totals grid
    ├── GardenSectionView.swift             # Soil & agricultural sensors
    ├── BatteryWarningBanner.swift          # Low battery alert banner
    ├── StationHeaderView.swift             # Station name, location, status
    ├── WindCompassView.swift               # Miniature compass rose
    ├── SensorDashboardView.swift           # Full expandable sensor list
    ├── SensorCategorySection.swift         # Category grouping
    ├── SensorTileView.swift                # Individual sensor tile
    │
    └── Settings/
        ├── SettingsView.swift              # Sidebar navigation shell
        ├── DisplaySettingsTab.swift         # Units, menubar sensor, quick stats
        ├── SensorsSettingsTab.swift         # Live sensor readings by category
        ├── AlertsSettingsTab.swift          # Alert threshold configuration
        ├── ConnectionSettingsTab.swift      # API keys and connection control
        └── GeneralSettingsTab.swift         # Launch at login, about
```

---

## Design

Porch uses a dark, vibrant aesthetic throughout:

- **Menubar Popover** — `ultraThinMaterial` tiles with color-coded sensor values and Liquid Glass effects on the quick stats bar
- **Settings Window** — Dark color scheme with a sidebar featuring color-coded icon badges (cyan, green, orange, blue, purple) and Liquid Glass buttons for actions
- **Typography** — Rounded design system for numeric values, hierarchical SF Symbols for weather conditions
- **Color Language** — Green for good/connected, orange for warning/connecting, red for alert/disconnected; EPA AQI palette for air quality; health-level coloring for CO2

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Ambient Weather](https://ambientweather.net) for their WebSocket API
- [AmbientWeatherSocket](https://github.com/MikeManzo/AmbientWeatherSocket) Swift package for the connection layer
- Built with SwiftUI, SwiftData, and Liquid Glass
