import Foundation

/// The four things a user can write about a verse, in the order they are asked.
enum NoteKind: String, Codable, CaseIterable {
    case keyword, interpretation, action, outcome
}

/// One handwritten line. It can never be edited or deleted; it can only be struck through
/// and un-struck, and every such change is kept. Each change wears the line a little more,
/// like a spot in a paper notebook that has been rubbed out too many times.
struct Note: Codable, Identifiable, Hashable {
    var id = UUID()
    var text: String
    var date = Date()
    /// Times the strike-through was toggled; odd count = currently struck.
    var strikes: [Date] = []

    var isStruck: Bool { strikes.count % 2 == 1 }
    var wear: Int { strikes.count }
}

struct JournalEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = Date()
    var verse: Verse
    var keywordNotes: [Note] = []
    var interpretationNotes: [Note] = []
    var actionNotes: [Note] = []
    var outcomeNotes: [Note] = []

    init(verse: Verse) { self.verse = verse }

    func notes(_ kind: NoteKind) -> [Note] {
        switch kind {
        case .keyword: keywordNotes
        case .interpretation: interpretationNotes
        case .action: actionNotes
        case .outcome: outcomeNotes
        }
    }

    private mutating func update(_ kind: NoteKind, _ change: (inout [Note]) -> Void) {
        switch kind {
        case .keyword: change(&keywordNotes)
        case .interpretation: change(&interpretationNotes)
        case .action: change(&actionNotes)
        case .outcome: change(&outcomeNotes)
        }
    }

    mutating func write(_ text: String, to kind: NoteKind, at date: Date = Date()) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update(kind) { $0.append(Note(text: trimmed, date: date)) }
    }

    mutating func toggleStrike(_ noteID: UUID, in kind: NoteKind, at date: Date = Date()) {
        update(kind) { notes in
            if let i = notes.firstIndex(where: { $0.id == noteID }) { notes[i].strikes.append(date) }
        }
    }

    /// The most recent line that is not struck through: what the user currently stands by.
    func current(_ kind: NoteKind) -> String { notes(kind).last(where: { !$0.isStruck })?.text ?? "" }

    var keyword: String { current(.keyword) }
    var interpretation: String { current(.interpretation) }
    var action: String { current(.action) }
    var outcome: String { current(.outcome) }

    var noteCount: Int { NoteKind.allCases.reduce(0) { $0 + notes($1).count } }
    var lastWritten: Date? { NoteKind.allCases.flatMap { notes($0).map(\.date) }.max() }
    var hasReading: Bool { NoteKind.allCases.contains { !current($0).isEmpty } }

    private enum CodingKeys: String, CodingKey {
        case id, date, verse, keywordNotes, interpretationNotes, actionNotes, outcomeNotes
        // Single-text fields written by earlier versions.
        case keyword, interpretation, action, outcome
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        verse = try c.decode(Verse.self, forKey: .verse)
        keywordNotes = try c.decodeIfPresent([Note].self, forKey: .keywordNotes) ?? []
        interpretationNotes = try c.decodeIfPresent([Note].self, forKey: .interpretationNotes) ?? []
        actionNotes = try c.decodeIfPresent([Note].self, forKey: .actionNotes) ?? []
        outcomeNotes = try c.decodeIfPresent([Note].self, forKey: .outcomeNotes) ?? []
        // Carry over what older versions stored as plain text, as the first line of each.
        let legacy: [(CodingKeys, NoteKind)] = [(.keyword, .keyword), (.interpretation, .interpretation), (.action, .action), (.outcome, .outcome)]
        for (key, kind) in legacy where notes(kind).isEmpty {
            if let text = try c.decodeIfPresent(String.self, forKey: key) { write(text, to: kind, at: date) }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(verse, forKey: .verse)
        try c.encode(keywordNotes, forKey: .keywordNotes)
        try c.encode(interpretationNotes, forKey: .interpretationNotes)
        try c.encode(actionNotes, forKey: .actionNotes)
        try c.encode(outcomeNotes, forKey: .outcomeNotes)
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

    func entry(_ id: UUID) -> JournalEntry? { entries.first { $0.id == id } }

    func upsert(_ entry: JournalEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        persist()
    }

    func write(_ text: String, to kind: NoteKind, of entryID: UUID) {
        guard var e = entry(entryID) else { return }
        e.write(text, to: kind)
        upsert(e)
    }

    func toggleStrike(_ noteID: UUID, in kind: NoteKind, of entryID: UUID) {
        guard var e = entry(entryID) else { return }
        e.toggleStrike(noteID, in: kind)
        upsert(e)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
