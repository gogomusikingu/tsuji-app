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
    let entry: JournalEntry
    @ObservedObject var journal: Journal
    let lang: AppLanguage
    @State private var sharing = false

    var body: some View {
        let l = L10n(lang: lang)
        VStack(alignment: .leading, spacing: 10) {
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
            NotesDisclosure(entryID: entry.id, journal: journal, lang: lang)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Rectangle().fill(Color.white.opacity(0.55)).shadow(color: Theme.ink.opacity(0.08), radius: 4, y: 1))
        .sheet(isPresented: $sharing) { ShareSheet(entry: journal.entry(entry.id) ?? entry, lang: lang) }
    }
}
