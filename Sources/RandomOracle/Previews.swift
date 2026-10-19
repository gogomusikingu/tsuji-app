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
        for lang in AppLanguage.allCases {
            render(VersePage(bible: bible, verse: verse, lang: lang, showContext: .constant(false))
                .padding(40).frame(width: 640).background(Theme.paper), "page-\(lang.rawValue)", dir)
            render(VersePage(bible: bible, verse: verse, lang: lang, showContext: .constant(true))
                .padding(40).frame(width: 640).background(Theme.paper), "page-context-\(lang.rawValue)", dir)
            render(DrawView(bible: bible, journal: Journal(directory: dir), lang: lang)
                .frame(width: 640, height: 560).background(Theme.paper).foregroundStyle(Theme.ink), "idle-\(lang.rawValue)", dir)
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
