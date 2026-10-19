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
        let bible = Bible.shared
        let verse = bible.verses.first { $0.book == "JOS" && $0.chapter == 22 && $0.verse == 21 }!

        render(TsujiMark().frame(width: 512, height: 512).background(Theme.paper), "mark", dir)
        // App icon: 1024 px with no transparency (iOS requirement); the mark carries its own margin.
        let icon = ImageRenderer(content: TsujiMark().frame(width: 1024, height: 1024).background(Theme.paper))
        icon.scale = 1
        if let tiff = icon.nsImage?.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: dir.appendingPathComponent("AppIcon.png"))
        }
        // System launch screen image: the mark alone on transparency, at the size CenterStage shows it.
        for scale in 1...3 {
            let r = ImageRenderer(content: TsujiMark(tight: true).frame(width: CenterStage<EmptyView>.markSize, height: CenterStage<EmptyView>.markSize))
            r.scale = CGFloat(scale)
            if let tiff = r.nsImage?.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: dir.appendingPathComponent("LaunchStage@\(scale)x.png"))
            }
        }
        for lang in AppLanguage.allCases {
            render(VersePage(bible: bible, verse: verse, lang: lang, showContext: .constant(false))
                .padding(40).frame(width: 640).background(Theme.paper), "page-\(lang.rawValue)", dir)
            render(VersePage(bible: bible, verse: verse, lang: lang, showContext: .constant(true))
                .padding(40).frame(width: 640).background(Theme.paper), "page-context-\(lang.rawValue)", dir)
            render(DrawView(bible: bible, journal: Journal(directory: dir), lang: lang)
                .frame(width: 640, height: 560).background(Theme.paper).foregroundStyle(Theme.ink), "idle-\(lang.rawValue)", dir)
            var shared = JournalEntry(verse: verse)
            let ja = lang == .ja
            shared.write(ja ? "答えて" : "answered", to: .keyword)
            shared.write(ja ? "黙って従えということ。" : "Keep quiet and obey.", to: .interpretation)
            shared.write(ja ? "隠れずに、自分の考えをはっきり言えということ。" : "Speak plainly instead of hiding.", to: .interpretation)
            shared.write(ja ? "明日の会議で反対意見を言う。" : "Raise my objection at tomorrow's meeting.", to: .action)
            shared.write(ja ? "言ってみたら、案が一つ通った。" : "I spoke up, and one proposal went through.", to: .outcome)
            // Wear the first reading as if struck and restored a few times, ending struck.
            let first = shared.interpretationNotes[0].id
            for _ in 0..<5 { shared.toggleStrike(first, in: .interpretation) }
            render(ShareCard(entry: shared, lang: lang), "share-\(lang.rawValue)", dir)
            let notesJournal = Journal(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
            notesJournal.upsert(shared)
            render(NotesSection(entryID: shared.id, journal: notesJournal, lang: lang)
                .padding(24).frame(width: 390).background(Theme.paper).foregroundStyle(Theme.ink), "notes-\(lang.rawValue)", dir)
            // Home while the book is closed for the day (body of the scroll view, without the scroll view).
            let l = L10n(lang: lang)
            render(VStack(alignment: .leading, spacing: 18) {
                Text(l.todayTitle).font(Theme.mincho(15))
                VersePage(bible: bible, verse: verse, lang: lang, showContext: .constant(false))
                NotesDisclosure(entryID: shared.id, journal: notesJournal, lang: lang)
                Text(l.nextDraw("23:12:05")).font(Theme.mincho(12)).foregroundStyle(Theme.inkFaint).frame(maxWidth: .infinity)
            }.padding(18).frame(width: 390).background(Theme.paper).foregroundStyle(Theme.ink), "today-\(lang.rawValue)", dir)
            render(StrikeSheet(note: shared.interpretationNotes[1], lang: lang, onConfirm: {}, onCancel: {})
                .frame(width: 390), "strike-\(lang.rawValue)", dir)
            // Wear stages 0...6 for the same line.
            render(VStack(alignment: .leading, spacing: 14) {
                ForEach([0, 1, 3, 6, 10, 20, 30, 40, 50], id: \.self) { n in
                    NoteRow(note: Note(text: ja ? "隠れずに、自分の考えを言え" : "Speak plainly, don't hide",
                                       strikes: Array(repeating: Date(), count: n)), lang: lang)
                }
            }.padding(24).frame(width: 390).background(Theme.paper).foregroundStyle(Theme.ink), "wear-\(lang.rawValue)", dir)
            render(SplashView(lang: lang, animated: false).frame(width: 390, height: 844), "splash-\(lang.rawValue)", dir)
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
