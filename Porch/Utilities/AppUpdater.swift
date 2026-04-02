//
//  AppUpdater.swift
//  Porch
//
//  Created by Mike Manzo on 3/17/26.
//

import AppKit
import Sparkle
import Combine
import UserNotifications

/// Lightweight wrapper around Sparkle's updater for SwiftUI integration.
/// Implements gentle reminders for menubar (background) apps.
@MainActor
final class AppUpdater: NSObject, ObservableObject {
    private var controller: SPUStandardUpdaterController!

    /// The underlying updater — use for binding to `automaticallyChecksForUpdates`, etc.
    var updater: SPUUpdater { controller.updater }

    @Published var canCheckForUpdates = false

    /// Persisted so the indicator survives app restarts and popover open/close cycles.
    @Published var updateAvailable: Bool {
        didSet { UserDefaults.standard.set(updateAvailable, forKey: "updateAvailable") }
    }

    /// Display version of the available update (e.g. "0.8.4")
    @Published var availableVersion: String? {
        didSet { UserDefaults.standard.set(availableVersion, forKey: "availableVersion") }
    }

    override init() {
        // Restore persisted state before super.init
        self.updateAvailable = UserDefaults.standard.bool(forKey: "updateAvailable")
        self.availableVersion = UserDefaults.standard.string(forKey: "availableVersion")

        super.init()

        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: self
        )
        controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)
    }

    /// Trigger a manual update check
    func checkForUpdates() {
        updater.checkForUpdates()
    }
}

// MARK: - SPUUpdaterDelegate (Update Discovery)

extension AppUpdater: SPUUpdaterDelegate {
    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        MainActor.assumeIsolated {
            updateAvailable = true
            availableVersion = item.displayVersionString
        }
    }

    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        MainActor.assumeIsolated {
            updateAvailable = false
            availableVersion = nil
        }
    }

    nonisolated func updater(_ updater: SPUUpdater, userDidMake choice: SPUUserUpdateChoice, forUpdate updateItem: SUAppcastItem, state: SPUUserUpdateState) {
        MainActor.assumeIsolated {
            if choice == .skip {
                updateAvailable = false
                availableVersion = nil
            }
        }
    }
}

// MARK: - SPUStandardUserDriverDelegate (Gentle Reminders)

extension AppUpdater: SPUStandardUserDriverDelegate {
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        MainActor.assumeIsolated {
            updateAvailable = true
            availableVersion = update.displayVersionString

            // Show in Dock so the user notices
            NSApp.setActivationPolicy(.regular)
            NSApp.dockTile.badgeLabel = "1"

            // Post a local notification
            let content = UNMutableNotificationContent()
            content.title = "Porch Update Available"
            content.body = "Version \(update.displayVersionString) is ready to install."
            let request = UNNotificationRequest(identifier: "porch-update", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    nonisolated func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        MainActor.assumeIsolated {
            // Clear dock badge but keep updateAvailable = true so the in-app
            // indicator persists until the user installs or explicitly skips.
            NSApp.dockTile.badgeLabel = nil
        }
    }

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        MainActor.assumeIsolated {
            // Return to menubar-only (background) mode
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
