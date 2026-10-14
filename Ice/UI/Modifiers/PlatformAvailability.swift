//
//  PlatformAvailability.swift
//  Ice
//

import SwiftUI

// The one place that knows which SwiftUI modifiers need macOS 26. Views call
// these and keep a single layout; on macOS 15 each falls back to the closest
// earlier look, or to no change where the modifier is purely cosmetic.

extension View {
    /// Applies a hard scroll edge effect on macOS 26 and later.
    @ViewBuilder
    func hardScrollEdgeEffect(for edges: Edge.Set) -> some View {
        if #available(macOS 26.0, *) {
            scrollEdgeEffectStyle(.hard, for: edges)
        } else {
            self
        }
    }

    /// Adds a flexible toolbar spacer on macOS 26 and later, where the
    /// toolbar groups its items into glass capsules.
    @ViewBuilder
    func flexibleToolbarSpacer() -> some View {
        if #available(macOS 26.0, *) {
            toolbar {
                ToolbarSpacer(.flexible)
            }
        } else {
            self
        }
    }

    /// Places a bar along the bottom edge: in the safe area on macOS 26 and
    /// later, so content scrolls beneath it, and below the view before that.
    @ViewBuilder
    func bottomSafeAreaBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(macOS 26.0, *) {
            safeAreaBar(edge: .bottom, spacing: 0, content: bar)
        } else {
            VStack(spacing: 0) {
                self
                bar()
            }
        }
    }
}
