import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct TsujiApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    #if DEBUG
    init() {
        // Testing: each new build (e.g. pressing Run in Xcode) may open the book again,
        // without waiting out the day. Release builds never do this.
        guard let exe = Bundle.main.executableURL,
              let built = (try? FileManager.default.attributesOfItem(atPath: exe.path))?[.modificationDate] as? Date
        else { return }
        let key = "debugBuildDate"
        if UserDefaults.standard.object(forKey: key) as? Date != built {
            UserDefaults.standard.removeObject(forKey: "lastDrawAt")
            UserDefaults.standard.set(built, forKey: key)
        }
    }
    #endif

    var body: some Scene {
        WindowGroup("辻") {
            ContentView()
                // No white from the window itself, ever: the whole window is paper.
                .background(Theme.paper.ignoresSafeArea())
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
