//
//  WhatsNewConfig.swift
//  Ice
//

import DragonKit

/// App-owned "What's New" content for Ice 2, rendered by DragonKit's ``WhatsNewPane``.
///
/// Only the app's own content lives here — the layout is owned by DragonKit. The version is not
/// passed at all: ``WhatsNewContent`` reads `CFBundleShortVersionString` itself and renders it
/// through ``DragonVersion/display(_:)``, so it always matches About and the update checker and
/// carries the same single `v` prefix. Update the `date` and `sections` per release.
///
/// Updating this file is part of every release (docs/RELEASING.md); it describes that release alone.
enum WhatsNewConfig {
    @MainActor
    static var content: WhatsNewContent {
        WhatsNewContent(
            date: "2026-10-14",
            summary: L("app.whatsNew.summary"),
            sections: [
                // The keys are stable across releases (app.whatsNew.summary, .added1, .fixed1, …):
                // each release overwrites their text in every .strings file rather than adding
                // version-named keys and abandoning the last release's.
                ChangeSection(kind: .added, entries: [
                    L("app.whatsNew.added1"),
                    L("app.whatsNew.added2"),
                ]),
                ChangeSection(kind: .fixed, entries: [
                    L("app.whatsNew.fixed1"),
                    L("app.whatsNew.fixed2"),
                    L("app.whatsNew.fixed3"),
                ]),
            ]
        )
    }
}
