import SwiftUI

struct RecordsView: View {
    @ObservedObject var journal: Journal
    let lang: AppLanguage

    var body: some View {
        let l = L10n(lang: lang)
        if journal.entries.isEmpty {
            Text(l.noRecords).font(Theme.mincho(14)).foregroundStyle(Theme.inkFaint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    StatsBar(stats: journal.stats, lang: lang)
                    ForEach(journal.entries) { entry in
                        EntryRow(entry: entry, journal: journal, lang: lang)
                    }
                }
                .padding(24)
            }
        }
    }
}

/// A running tally that shows the book as a tool for acting, not a fortune.
struct StatsBar: View {
    let stats: (opened: Int, decided: Int, reflected: Int)
    let lang: AppLanguage

    var body: some View {
        let l = L10n(lang: lang)
        HStack(spacing: 0) {
            cell(stats.opened, l.statsOpened, l)
            divider
            cell(stats.decided, l.statsDecided, l)
            divider
            cell(stats.reflected, l.statsReflected, l)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Rectangle().fill(Theme.paperDeep.opacity(0.6)))
    }

    private var divider: some View { Rectangle().fill(Theme.ink.opacity(0.12)).frame(width: 1, height: 36) }

    private func cell(_ n: Int, _ label: String, _ l: L10n) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(n)").font(Theme.mincho(24, bold: true).monospacedDigit())
                Text(l.statsUnit).font(Theme.mincho(11))
            }
            Text(label).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EntryRow: View {
    @State var entry: JournalEntry
    let journal: Journal
    let lang: AppLanguage
    @State private var sharing = false

    var body: some View {
        let l = L10n(lang: lang)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
                Spacer()
                Button { sharing = true } label: { Image(systemName: "square.and.arrow.up") }
                    .buttonStyle(.plain).foregroundStyle(Theme.shu)
                    .accessibilityLabel(l.share)
            }
            Text(entry.verse.text(lang)).font(Theme.verse(16)).lineSpacing(6)
            Text(entry.verse.reference(lang)).font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
            TextField(l.keyword, text: $entry.keyword, axis: .vertical)
            TextField(l.interpretation, text: $entry.interpretation, axis: .vertical)
            TextField(l.action, text: $entry.action, axis: .vertical)
            TextField(l.outcome, text: $entry.outcome, axis: .vertical)
        }
        .textFieldStyle(.roundedBorder)
        .font(Theme.mincho(13))
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Rectangle().fill(Color.white.opacity(0.55)).shadow(color: Theme.ink.opacity(0.08), radius: 4, y: 1))
        .onChange(of: entry) { _, new in journal.upsert(new) }
        .sheet(isPresented: $sharing) { ShareSheet(entry: entry, lang: lang) }
    }
}
