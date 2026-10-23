import AppKit
import CoreText
import Foundation
import Testing
@testable import RandomOracle

@Test func bundledBibleHasAllVersesInBothLanguages() {
    let bible = Bible.shared
    #expect(bible.verses.count == 31098)
    #expect(bible.verses.allSatisfy { !$0.ja.isEmpty && !$0.en.isEmpty })
}

@Test func nameListsAreNeverDrawn() {
    let bible = Bible.shared
    let skipped = bible.verses.count - bible.drawable.count
    #expect(skipped > 700 && skipped < 900)
    // Joshua 15:54 is a bare list of towns.
    let i = bible.verses.firstIndex { $0.book == "JOS" && $0.chapter == 15 && $0.verse == 54 }!
    #expect(!bible.drawable.contains(i))
    // Matthew 1:3 is a genealogy.
    let g = bible.verses.firstIndex { $0.book == "MAT" && $0.chapter == 1 && $0.verse == 3 }!
    #expect(!bible.drawable.contains(g))
    // Still there for "read around it".
    #expect(bible.context(of: bible.verses[i + 1], radius: 2).contains(bible.verses[i]))
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
    entry.write("went well", to: .outcome)
    Journal(directory: dir).upsert(entry)
    let reloaded = Journal(directory: dir)
    #expect(reloaded.entries.count == 1)
    #expect(reloaded.entries.first?.outcome == "went well")
}

@Test func contextStaysWithinChapter() {
    let bible = Bible.shared
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
    let bible = Bible.shared
    for lang in AppLanguage.allCases {
        for item in FixedExamples.all(lang) {
            #expect(bible.verses.contains { $0.text(lang) == item.verse }, "\(item.ref)")
        }
    }
}

@Test func emptyEntryHasNoReading() {
    #expect(!JournalEntry(verse: Bible.shared.verses[0]).hasReading)
}

@Test func verseFontIsBundledAndLoads() throws {
    let url = try #require(Bundle.module.url(forResource: "ShipporiMincho-Regular", withExtension: "ttf"))
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    #expect(NSFont(name: "ShipporiMincho-Regular", size: 12) != nil)
}

@Test func notesCanOnlyBeAddedOrStruckAndKeepTheirHistory() throws {
    var e = JournalEntry(verse: Bible.shared.verses[0])
    e.write("first", to: .interpretation)
    e.write("  ", to: .interpretation)                 // blank lines are ignored
    e.write("second", to: .interpretation)
    #expect(e.interpretationNotes.count == 2)
    #expect(e.interpretation == "second")
    let second = e.interpretationNotes[1].id
    e.toggleStrike(second, in: .interpretation)
    #expect(e.interpretation == "first")                 // struck lines no longer count as current
    e.toggleStrike(second, in: .interpretation)
    e.toggleStrike(second, in: .interpretation)
    #expect(e.interpretationNotes[1].isStruck)
    #expect(e.interpretationNotes[1].wear == 3)
    #expect(e.interpretationNotes[1].text == "second")   // the words themselves never change

    let data = try JSONEncoder().encode([e])
    let back = try JSONDecoder().decode([JournalEntry].self, from: data)
    #expect(back.first?.interpretationNotes == e.interpretationNotes)
}

@Test func legacyTextBecomesFirstNote() throws {
    let old = #"[{"id":"\#(UUID().uuidString)","date":0,"verse":{"book":"GEN","chapter":1,"verse":1,"ja":"a","en":"b"},"keyword":"k","interpretation":"x","action":"","outcome":"o"}]"#
    let e = try #require(try JSONDecoder().decode([JournalEntry].self, from: Data(old.utf8)).first)
    #expect(e.keywordNotes.map(\.text) == ["k"])
    #expect(e.actionNotes.isEmpty)
    #expect(e.outcomeNotes.first?.date == e.date)
    #expect(e.noteCount == 3)
}

@Test func bookOpensOncePerDay() {
    #expect(Cooldown.defaultInterval == 24 * 60 * 60)
}
