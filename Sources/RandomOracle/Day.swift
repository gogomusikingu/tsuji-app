import SwiftUI

/// One day's verse page, shared by "today's verse" at home and every page of the journal,
/// so the two line up exactly and nothing jumps when switching between them.
struct VerseDay<Footer: View>: View {
    let title: String
    let entry: JournalEntry
    @ObservedObject var journal: Journal
    let lang: AppLanguage
    let bible: Bible?
    let onShare: () -> Void
    @ViewBuilder var footer: () -> Footer
    @State private var showContext = false

    var body: some View {
        let l = L10n(lang: lang)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(Theme.mincho(15))
                    Spacer()
                    Text(l.openedAt(NoteTime.clock(entry.date)))
                        .font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                }
                if let bible {
                    VersePage(bible: bible, verse: entry.verse, lang: lang, showContext: $showContext)
                } else {
                    Text(entry.verse.text(lang)).font(Theme.verse(21)).lineSpacing(12)
                        .fixedSize(horizontal: false, vertical: true)
                }
                NotesDisclosure(entryID: entry.id, journal: journal, lang: lang)
                HStack {
                    Button(action: onShare) { Label(l.share, systemImage: "square.and.arrow.up") }
                        .buttonStyle(.plain).font(Theme.mincho(13)).foregroundStyle(Theme.shu)
                    Spacer()
                }
                footer()
            }
            .padding(8)
        }
        .scrollContentBackground(.hidden)
    }
}

/// The window's full size (including safe areas), so a view anywhere can find the screen's centre.
private struct WindowSizeKey: EnvironmentKey { static let defaultValue: CGSize = .zero }
extension EnvironmentValues {
    var windowSize: CGSize {
        get { self[WindowSizeKey.self] }
        set { self[WindowSizeKey.self] = newValue }
    }
}

/// The mark at the exact centre of the screen, at one fixed size, with `below` underneath it.
/// The system launch screen, the splash and the home screens all use this, so the mark never moves
/// or changes size from the moment the app is tapped.
struct CenterStage<Below: View>: View {
    static var markSize: CGFloat { 130 }
    @Environment(\.windowSize) private var window
    @ViewBuilder var below: () -> Below

    var body: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            // Fall back to this view's own centre where the window size is unknown (Mac previews).
            let centre = window == .zero
                ? CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                : CGPoint(x: window.width / 2 - frame.minX, y: window.height / 2 - frame.minY)
            ZStack(alignment: .top) {
                TsujiMark(tight: true)
                    .frame(width: Self.markSize, height: Self.markSize)
                    .position(centre)
                below()
                    .frame(maxWidth: .infinity)
                    .padding(.top, centre.y + Self.markSize / 2 + 32)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }
}
