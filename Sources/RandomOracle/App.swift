import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct TsujiApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup("辻") {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 520, minHeight: 640)
                #endif
        }
    }
}

#if os(macOS)
/// Needed when launched via `swift run` (no app bundle) so the window comes to the front.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if PreviewRenderer.runIfRequested() { exit(0) }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
#endif
