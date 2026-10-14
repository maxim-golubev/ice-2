//
//  AboutConfig.swift
//  Ice
//

import DragonKit
import Foundation

/// Ice 2's content for DragonKit's shared About pane: URLs and proper nouns only. The kit owns
/// every row title, symbol and ordering, and the version comes from the bundle.
enum AboutConfig {
    /// The fork's home, which is also where releases are published.
    private static let repositoryURL = URL(string: "https://github.com/maxim-golubev/ice-2")!

    static var content: AboutContent {
        AboutContent(
            appName: Constants.displayName,
            versionString: DragonAbout.versionString(),
            // The row names who maintains and distributes this build. The lineage (Jordan Baird's
            // Ice, then Teddy Chan's Ice 2) is carried by `LICENSE`, the `Original project` link
            // and the `Based on` credit below.
            copyright: DragonAbout.copyright(years: "2026", holder: "Maxim Golubev"),
            websiteURL: repositoryURL,
            supportURL: repositoryURL.appending(path: "issues"),
            // The bundled notices, as published in the repository.
            licensesURL: repositoryURL.appending(path: "blob/main/Ice/Resources/Acknowledgements.pdf"),
            license: "GPL-3.0",
            originalWork: OriginalWork(
                name: "Ice",
                author: "Jordan Baird",
                url: URL(string: "https://github.com/jordanbaird/Ice")!
            ),
            // Every third-party package Ice 2 links, as `name → licence`. `AcknowledgementsTests`
            // pins it to the linked packages. DragonKit is left out because the kit already adds
            // its own `Built with` row.
            attributions: [
                Attribution(name: "AXSwift", license: "MIT"),
                Attribution(name: "Ifrit", license: "MIT"),
                Attribution(name: "Semaphore", license: "MIT"),
                Attribution(name: "Sparkle", license: "MIT"),
            ]
        )
    }
}
