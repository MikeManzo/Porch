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
final class AppUpdater: NSObject, ObservableObject {
    private var controller: SPUStandardUpdaterController!

    /// The underlying updater — use for binding to `automaticallyChecksForUpdates`, etc.
    var updater: SPUUpdater { controller.updater }

    @Published var canCheckForUpdates = false
    @Published var updateAvailable = false

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: self
        )
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    /// Trigger a manual update check
    func checkForUpdates() {
        updater.checkForUpdates()
    }
}

// MARK: - SPUUpdaterDelegate (Update Discovery)

extension AppUpdater: SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        updateAvailable = true
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        updateAvailable = false
    }

    func updater(_ updater: SPUUpdater, userDidMake choice: SPUUserUpdateChoice, forUpdate updateItem: SUAppcastItem, state: SPUUserUpdateState) {
        if choice == .skip {
            updateAvailable = false
        }
    }
}

// MARK: - SPUStandardUserDriverDelegate (Gentle Reminders)

extension AppUpdater: SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        updateAvailable = true

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

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        // Clear the badge once the user sees the update dialog
        NSApp.dockTile.badgeLabel = nil
        updateAvailable = false
    }

    func standardUserDriverWillFinishUpdateSession() {
        // Return to menubar-only (background) mode
        NSApp.setActivationPolicy(.accessory)
    }
}
