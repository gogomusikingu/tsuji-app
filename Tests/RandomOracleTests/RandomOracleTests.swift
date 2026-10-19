import Foundation
import Testing
@testable import RandomOracle

@Test func bundledBibleHasAllVersesInBothLanguages() {
    let bible = Bible.bundled()
    #expect(bible.verses.count == 31098)
    #expect(bible.verses.allSatisfy { !$0.ja.isEmpty && !$0.en.isEmpty })
}

@Test func referenceFormatting() {
    let v = Verse(book: "PRO", chapter: 16, verse: 9, ja: "", en: "")
    #expect(v.reference(.ja) == "箴言 16章9節")
    #expect(v.reference(.en) == "Proverbs 16:9")
}

@Test func cooldownBlocksSecondDraw() {
    let defaults = UserDefaults(suiteName: "test-\(UUID())")!
    let cooldown = Cooldown(defaults: defaults, interval: 3600)
    let t0 = Date()
    #expect(cooldown.remaining(now: t0) == 0)
    cooldown.markDrawn(now: t0)
    #expect(abs(cooldown.remaining(now: t0.addingTimeInterval(600)) - 3000) < 0.001)
    #expect(cooldown.remaining(now: t0.addingTimeInterval(3601)) == 0)
}

@MainActor
@Test func journalPersistsEntries() {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    var entry = JournalEntry(verse: Verse(book: "GEN", chapter: 1, verse: 1, ja: "a", en: "b"))
    Journal(directory: dir).upsert(entry)
    entry.outcome = "went well"
    Journal(directory: dir).upsert(entry)
    let reloaded = Journal(directory: dir)
    #expect(reloaded.entries.count == 1)
    #expect(reloaded.entries.first?.outcome == "went well")
}

@Test func contextStaysWithinChapter() {
    let bible = Bible.bundled()
    let first = bible.verses.first { $0.book == "PRO" && $0.chapter == 16 && $0.verse == 1 }!
    let context = bible.context(of: first, radius: 2)
    #expect(context.map(\.verse) == [1, 2, 3])
    let mid = bible.verses.first { $0.book == "PRO" && $0.chapter == 16 && $0.verse == 9 }!
    #expect(bible.context(of: mid, radius: 2).map(\.verse) == [7, 8, 9, 10, 11])
}

@Test func journalLoadsEntriesWithoutKeywordField() throws {
    let old = #"[{"id":"\#(UUID().uuidString)","date":0,"verse":{"book":"GEN","chapter":1,"verse":1,"ja":"a","en":"b"},"interpretation":"x","action":"","outcome":""}]"#
    let entries = try JSONDecoder().decode([JournalEntry].self, from: Data(old.utf8))
    #expect(entries.first?.keyword == "")
    #expect(entries.first?.interpretation == "x")
}

@Test func fixedExampleVersesMatchBundledText() {
    let bible = Bible.bundled()
    for lang in AppLanguage.allCases {
        for item in FixedExamples.all(lang) {
            #expect(bible.verses.contains { $0.text(lang) == item.verse }, "\(item.ref)")
        }
    }
}
