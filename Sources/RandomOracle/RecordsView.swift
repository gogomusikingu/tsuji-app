import SwiftUI

struct RecordsView: View {
    @ObservedObject var journal: Journal
    let lang: AppLanguage

    var body: some View {
        let l = L10n(lang: lang)
        if journal.entries.isEmpty {
            Text(l.noRecords).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(journal.entries) { entry in
                EntryRow(entry: entry, journal: journal, lang: lang)
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
                .font(.caption).foregroundStyle(.secondary)
            Text(entry.verse.text(lang)).font(.system(.body, design: .serif))
            Text(entry.verse.reference(lang)).font(.caption).foregroundStyle(.secondary)
            TextField(l.keyword, text: $entry.keyword, axis: .vertical)
            TextField(l.interpretation, text: $entry.interpretation, axis: .vertical)
            TextField(l.action, text: $entry.action, axis: .vertical)
            TextField(l.outcome, text: $entry.outcome, axis: .vertical)
        }
        .textFieldStyle(.roundedBorder)
        .padding(.vertical, 8)
        .onChange(of: entry) { _, new in journal.upsert(new) }
    }
}
