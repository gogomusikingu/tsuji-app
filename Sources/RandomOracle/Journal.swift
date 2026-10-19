import Foundation

struct JournalEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    var verse: Verse
    var keyword = ""
    var interpretation = ""
    var action = ""
    var outcome = ""

    init(verse: Verse) { self.verse = verse }

    var hasReading: Bool { !interpretation.isEmpty || !action.isEmpty }

    // Tolerates journals saved by older versions that lack newer fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        verse = try c.decode(Verse.self, forKey: .verse)
        keyword = try c.decodeIfPresent(String.self, forKey: .keyword) ?? ""
        interpretation = try c.decodeIfPresent(String.self, forKey: .interpretation) ?? ""
        action = try c.decodeIfPresent(String.self, forKey: .action) ?? ""
        outcome = try c.decodeIfPresent(String.self, forKey: .outcome) ?? ""
    }
}

/// Local-only storage: entries never leave the device.
@MainActor
final class Journal: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []
    private let url: URL

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RandomOracle", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("journal.json")
        if let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            entries = saved
        }
    }

    /// How often the book was opened, how often it led to a decision, and how often the user looked back.
    var stats: (opened: Int, decided: Int, reflected: Int) {
        (entries.count,
         entries.filter { !$0.action.isEmpty }.count,
         entries.filter { !$0.outcome.isEmpty }.count)
    }

    func upsert(_ entry: JournalEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
