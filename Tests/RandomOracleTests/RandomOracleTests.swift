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
