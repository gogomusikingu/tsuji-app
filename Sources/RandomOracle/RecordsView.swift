import SwiftUI

/// Past days as a tear-off calendar: one day per page, newest first. Turn the pages with the
/// arrows or a sideways swipe; each page dissolves into the next.
struct RecordsView: View {
    @ObservedObject var journal: Journal
    let lang: AppLanguage
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
                    DayPage(entry: entries[i], journal: journal, lang: lang)
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

/// One calendar leaf: the date set large, the verse drawn that day, and what was written about it.
private struct DayPage: View {
    let entry: JournalEntry
    @ObservedObject var journal: Journal
    let lang: AppLanguage
    @State private var sharing = false

    var body: some View {
        let l = L10n(lang: lang)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .lastTextBaseline, spacing: 14) {
                    Text(Self.format("d", entry.date, lang)).font(Theme.mincho(60, bold: true))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Self.format(lang == .ja ? "M月" : "MMMM", entry.date, lang)).font(Theme.mincho(15))
                        Text(Self.format("EEEE", entry.date, lang)).font(Theme.mincho(12)).foregroundStyle(Theme.inkFaint)
                    }
                    Spacer()
                    Text(Self.format("yyyy", entry.date, lang)).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                }
                Rectangle().fill(Theme.ink.opacity(0.15)).frame(height: 1)
                Text(entry.verse.text(lang)).font(Theme.verse(18)).lineSpacing(9)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(l.openedAt(Self.format("HH:mm", entry.date, lang)))
                    Spacer()
                    Text(entry.verse.reference(lang))
                }
                .font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                NotesDisclosure(entryID: entry.id, journal: journal, lang: lang)
                    .padding(.top, 6)
                HStack {
                    Spacer()
                    Button { sharing = true } label: { Label(l.share, systemImage: "square.and.arrow.up") }
                        .buttonStyle(.plain).font(Theme.mincho(13)).foregroundStyle(Theme.shu)
                }
            }
            .padding(26)
            .background(StackedLeaves())
            .padding(.top, 10)
            .padding(.trailing, 10)
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

/// The page on top of a small stack of earlier leaves, slightly offset behind it.
struct StackedLeaves: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Theme.paperDeep.opacity(0.7)).offset(x: 8, y: -8)
            Rectangle().fill(Theme.paperDeep).offset(x: 4, y: -4)
            Rectangle().fill(Color.white.opacity(0.6))
                .background(Theme.paper)
                .shadow(color: Theme.ink.opacity(0.10), radius: 4, y: 1)
        }
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
