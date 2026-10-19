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
                    ForEach(journal.entries) { entry in
                        EntryRow(entry: entry, journal: journal, lang: lang)
                    }
                }
                .padding(24)
            }
        }
    }
}

private struct EntryRow: View {
    @State var entry: JournalEntry
    let journal: Journal
    let lang: AppLanguage

    var body: some View {
        let l = L10n(lang: lang)
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                .font(Theme.mincho(11)).foregroundStyle(Theme.inkFaint)
            Text(entry.verse.text(lang)).font(Theme.mincho(16)).lineSpacing(6)
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
    }
}
