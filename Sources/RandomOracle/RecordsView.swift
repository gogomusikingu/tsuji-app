import SwiftUI

/// Past days as a tear-off calendar: one day per page, newest first. Turn the pages with the
/// arrows or a sideways swipe; each page dissolves into the next.
struct RecordsView: View {
    @ObservedObject var journal: Journal
    let lang: AppLanguage
    /// For the "read around it" toggle; pages still show while the text is loading.
    var bible: Bible?
    @State private var index = 0

    var body: some View {
        let l = L10n(lang: lang)
        let entries = journal.entries
        if entries.isEmpty {
            Text(l.noRecords).font(Theme.mincho(14)).foregroundStyle(Theme.inkFaint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let i = min(index, entries.count - 1)
            VStack(spacing: 14) {
                ZStack {
                    DayPage(entry: entries[i], journal: journal, lang: lang, bible: bible)
                        .id(entries[i].id)
                        .transition(.opacity)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 30).onEnded { drag in
                    if drag.translation.width > 60 { turn(to: i + 1, of: entries.count) }
                    if drag.translation.width < -60 { turn(to: i - 1, of: entries.count) }
                })
                HStack {
                    Button(l.olderDay) { turn(to: i + 1, of: entries.count) }
                        .disabled(i >= entries.count - 1)
                    Spacer()
                    Text("\(entries.count - i) / \(entries.count)")
                        .font(Theme.mincho(11).monospacedDigit()).foregroundStyle(Theme.inkFaint)
                    Spacer()
                    Button(l.newerDay) { turn(to: i - 1, of: entries.count) }
                        .disabled(i == 0)
                }
                .buttonStyle(.plain)
                .font(Theme.mincho(13))
                .foregroundStyle(Theme.shu)
                .padding(.horizontal, 8)
            }
            .padding(Theme.screenPadding)
        }
    }

    private func turn(to target: Int, of count: Int) {
        guard (0..<count).contains(target) else { return }
        withAnimation(Fade.animation) { index = target }
    }
}

/// One day: laid out like today's verse at home, with the date above it.
private struct DayPage: View {
    let entry: JournalEntry
    @ObservedObject var journal: Journal
    let lang: AppLanguage
    let bible: Bible?
    @State private var sharing = false
    @State private var showContext = false

    var body: some View {
        let l = L10n(lang: lang)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Self.format(lang == .ja ? "yyyy年M月d日（E）" : "EEEE, MMMM d, yyyy", entry.date, lang))
                        .font(Theme.mincho(15))
                    Spacer()
                    Text(l.openedAt(Self.format("HH:mm", entry.date, lang)))
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
                    Button { sharing = true } label: { Label(l.share, systemImage: "square.and.arrow.up") }
                        .buttonStyle(.plain).font(Theme.mincho(13)).foregroundStyle(Theme.shu)
                    Spacer()
                }
            }
            .padding(8)
        }
        .scrollContentBackground(.hidden)
        .fadeCover(isPresented: $sharing) {
            ShareSheet(entry: journal.entry(entry.id) ?? entry, lang: lang) { sharing = false }
        }
    }

    static func format(_ pattern: String, _ date: Date, _ lang: AppLanguage) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == .ja ? "ja_JP" : "en_US")
        f.dateFormat = pattern
        return f.string(from: date)
    }
}

/// Tab icon for the journal: a stack of calendar leaves, drawn in the same thin line as the book.
struct KoyomiIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let style = StrokeStyle(lineWidth: max(1.2, w * 0.06), lineCap: .round, lineJoin: .round)
            func leaf(_ dx: CGFloat, _ dy: CGFloat) -> Path {
                Path(roundedRect: CGRect(x: w * 0.12 + dx, y: h * 0.22 + dy, width: w * 0.66, height: h * 0.66), cornerRadius: w * 0.06)
            }
            // Earlier leaves behind, then the front leaf with its binding band and the day.
            ctx.stroke(leaf(w * 0.16, -h * 0.14), with: .foreground, style: style)
            ctx.stroke(leaf(w * 0.08, -h * 0.07), with: .foreground, style: style)
            ctx.fill(leaf(0, 0), with: .color(Theme.paper))
            ctx.stroke(leaf(0, 0), with: .foreground, style: style)
            var band = Path()
            band.move(to: CGPoint(x: w * 0.12, y: h * 0.40)); band.addLine(to: CGPoint(x: w * 0.78, y: h * 0.40))
            ctx.stroke(band, with: .foreground, style: style)
            var day = Path()
            day.move(to: CGPoint(x: w * 0.32, y: h * 0.62)); day.addLine(to: CGPoint(x: w * 0.58, y: h * 0.62))
            ctx.stroke(day, with: .foreground, style: style)
        }
    }
}
