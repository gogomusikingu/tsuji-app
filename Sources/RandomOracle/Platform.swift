import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Small wrappers so the same views build for both the Mac prototype and the iPhone app.
enum Platform {
    static func haptic() {
        #if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        #else
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }

    static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }
}
