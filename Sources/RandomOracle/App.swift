import AppKit
import SwiftUI

@main
struct RandomOracleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("辻") {
            ContentView()
                .frame(minWidth: 520, minHeight: 640)
        }
    }
}

/// Needed when launched via `swift run` (no app bundle) so the window comes to the front.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if PreviewRenderer.runIfRequested() { exit(0) }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
