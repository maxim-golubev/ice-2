//
//  IceUninstallConfig.swift
//  Ice
//

import DragonKit
import Foundation

/// App-owned Uninstall configuration for Ice 2, rendered by DragonKit's
/// ``UninstallSettingsPane`` and performed by ``DragonUninstaller``.
///
/// Only Ice 2's own content lives here — the confirmation layout and the teardown are owned
/// by DragonKit. Ice 2's settings live in its `UserDefaults` domain (`Defaults.store` is
/// `.standard`), which the shared teardown wipes from `bundleID` along with the matching
/// preference plist and saved application state, so there are no extra suites. Ice 2 keeps no
/// separate user data either — its settings *are* its data, always removed — so there is no
/// optional "also delete data" toggle, unlike ClipMenu.
///
/// `extraCleanupPaths` covers the per-bundle-id folders the shared teardown can't know about:
/// the `Caches` and `HTTPStorages` folders macOS creates for the app's own network traffic
/// (Sparkle's appcast fetches), plus `Application Support`. Ice 2 writes nothing to
/// `Application Support` today, but it is listed so the in-app uninstall and the manual `rm -rf`
/// in `README.md` remove the same five paths, and removing an absent folder is a no-op.
enum IceUninstallConfig {
    @MainActor
    static var config: UninstallConfig {
        // The running bundle's id, so a debug build (com.maximgolubev.Ice2.debug) cleans its OWN
        // domain/state/caches and never the installed release's.
        let bundleID = Bundle.main.bundleIdentifier ?? Constants.releaseBundleIdentifier
        let library = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
        return UninstallConfig(
            appName: Constants.displayName,
            bundleID: bundleID,
            // Resolved here, not keyed: `UninstallConfig` is built fresh each time the pane
            // renders and the kit shows these strings as-is (its own doc comment says to
            // localize them in the app), so `L(_:)` reads the language selected right now.
            checklistItems: [
                L("app.uninstall.item.app"),
                L("app.uninstall.item.settings"),
                L("app.uninstall.item.state"),
                L("app.uninstall.item.caches"),
            ],
            extraCleanupPaths: [
                library.appending(path: "Application Support/\(bundleID)"),
                library.appending(path: "Caches/\(bundleID)"),
                library.appending(path: "HTTPStorages/\(bundleID)"),
            ]
        )
    }
}
