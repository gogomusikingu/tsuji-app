import CoreGraphics
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

    static func cgImage(from data: Data) -> CGImage? {
        #if os(macOS)
        return NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return UIImage(data: data)?.normalizedCGImage
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

#if os(iOS)
extension UIImage {
    /// Camera photos carry an orientation flag; redraw upright so text recognition sees it the right way up.
    var normalizedCGImage: CGImage? {
        guard imageOrientation != .up else { return cgImage }
        return UIGraphicsImageRenderer(size: size).image { _ in draw(at: .zero) }.cgImage
    }
}
#endif
