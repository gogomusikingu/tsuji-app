#if os(macOS)
import AppKit
import SwiftUI

/// Developer check: `RandomOracle --render-previews <dir>` writes PNGs of key screens and exits.
/// Lets the design be reviewed without screen-recording permission.
@MainActor
enum PreviewRenderer {
    static func runIfRequested() -> Bool {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--render-previews"), i + 1 < args.count else { return false }
        let dir = URL(fileURLWithPath: args[i + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let bible = Bible.bundled()
        let verse = bible.verses.first { $0.book == "JOS" && $0.chapter == 22 && $0.verse == 21 }!

        render(TsujiMark().frame(width: 512, height: 512).background(Theme.paper), "mark", dir)
        // App icon: 1024 px with no transparency (iOS requirement); the mark sits on paper with margin.
        let icon = ImageRenderer(content: TsujiMark().padding(84).frame(width: 1024, height: 1024).background(Theme.paper))
        icon.scale = 1
        if let tiff = icon.nsImage?.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: dir.appendingPathComponent("AppIcon.png"))
        }
        for lang in AppLanguage.allCases {
            render(VersePage(bible: bible, verse: verse, lang: lang, showContext: .constant(false))
                .padding(40).frame(width: 640).background(Theme.paper), "page-\(lang.rawValue)", dir)
            render(VersePage(bible: bible, verse: verse, lang: lang, showContext: .constant(true))
                .padding(40).frame(width: 640).background(Theme.paper), "page-context-\(lang.rawValue)", dir)
            render(DrawView(bible: bible, journal: Journal(directory: dir), lang: lang)
                .frame(width: 640, height: 560).background(Theme.paper).foregroundStyle(Theme.ink), "idle-\(lang.rawValue)", dir)
            var shared = JournalEntry(verse: verse)
            shared.interpretation = lang == .ja ? "隠れずに、自分の考えをはっきり言えということ。" : "Speak plainly instead of hiding."
            shared.action = lang == .ja ? "明日の会議で反対意見を言う。" : "Raise my objection at tomorrow's meeting."
            render(ShareCard(entry: shared, lang: lang), "share-\(lang.rawValue)", dir)
            render(StatsBar(stats: (12, 7, 3), lang: lang).padding(24).frame(width: 390).background(Theme.paper).foregroundStyle(Theme.ink), "stats-\(lang.rawValue)", dir)
            render(SplashView(lang: lang).frame(width: 390, height: 844), "splash-\(lang.rawValue)", dir)
            render(GuideContent(lang: lang).padding(32).frame(width: 580).background(Theme.paper).foregroundStyle(Theme.ink), "guide-\(lang.rawValue)", dir)
        }
        return true
    }

    private static func render(_ view: some View, _ name: String, _ dir: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
            print("failed:", name); return
        }
        try? png.write(to: dir.appendingPathComponent("\(name).png"))
        print("wrote", name)
    }
}
#endif
