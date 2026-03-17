//
//  AppUpdater.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import Sparkle
import Combine

/// Lightweight wrapper around Sparkle's updater for SwiftUI integration
final class AppUpdater: NSObject, ObservableObject {
    private let controller: SPUStandardUpdaterController

    /// The underlying updater — use for binding to `automaticallyChecksForUpdates`, etc.
    var updater: SPUUpdater { controller.updater }

    @Published var canCheckForUpdates = false

    private var cancellable: AnyCancellable?

    override init() {
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        super.init()
        // Mirror Sparkle's canCheckForUpdates into a @Published property
        cancellable = controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    /// Trigger a manual update check
    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
