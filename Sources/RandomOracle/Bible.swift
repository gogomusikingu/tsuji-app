import Foundation

struct Verse: Codable, Hashable {
    let book: String
    let chapter: Int
    let verse: Int
    let ja: String
    let en: String

    func text(_ lang: AppLanguage) -> String { lang == .ja ? ja : en }

    func reference(_ lang: AppLanguage) -> String {
        let name = Bible.bookName(book, lang)
        return lang == .ja ? "\(name) \(chapter)章\(verse)節" : "\(name) \(chapter):\(verse)"
    }
}

final class Bible {
    let verses: [Verse]

    init(tsv: String) {
        verses = tsv.split(separator: "\n").compactMap { line in
            let f = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard f.count == 5, let ch = Int(f[1]), let vs = Int(f[2]) else { return nil }
            return Verse(book: String(f[0]), chapter: ch, verse: vs, ja: String(f[3]), en: String(f[4]))
        }
    }

    static func bundled() -> Bible {
        guard let url = Platform.resourceBundle.url(forResource: "bible", withExtension: "tsv"),
              let tsv = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("bible.tsv is missing from the bundle")
        }
        return Bible(tsv: tsv)
    }

    /// Uniformly random verse, using the system's cryptographically secure generator.
    func draw() -> Verse {
        var rng = SystemRandomNumberGenerator()
        return verses.randomElement(using: &rng)!
    }

    /// The verse with up to `radius` neighbours on each side, staying within the same chapter.
    func context(of target: Verse, radius: Int) -> [Verse] {
        guard let i = verses.firstIndex(of: target) else { return [target] }
        let range = max(0, i - radius)...min(verses.count - 1, i + radius)
        return verses[range].filter { $0.book == target.book && $0.chapter == target.chapter }
    }

    static func bookName(_ code: String, _ lang: AppLanguage) -> String {
        guard let names = bookNames[code] else { return code }
        return lang == .ja ? names.0 : names.1
    }

    private static let bookNames: [String: (String, String)] = [
        "GEN": ("創世記", "Genesis"), "EXO": ("出エジプト記", "Exodus"), "LEV": ("レビ記", "Leviticus"),
        "NUM": ("民数記", "Numbers"), "DEU": ("申命記", "Deuteronomy"), "JOS": ("ヨシュア記", "Joshua"),
        "JDG": ("士師記", "Judges"), "RUT": ("ルツ記", "Ruth"), "1SA": ("サムエル記上", "1 Samuel"),
        "2SA": ("サムエル記下", "2 Samuel"), "1KI": ("列王紀上", "1 Kings"), "2KI": ("列王紀下", "2 Kings"),
        "1CH": ("歴代志上", "1 Chronicles"), "2CH": ("歴代志下", "2 Chronicles"), "EZR": ("エズラ記", "Ezra"),
        "NEH": ("ネヘミヤ記", "Nehemiah"), "EST": ("エステル記", "Esther"), "JOB": ("ヨブ記", "Job"),
        "PSA": ("詩篇", "Psalms"), "PRO": ("箴言", "Proverbs"), "ECC": ("伝道の書", "Ecclesiastes"),
        "SOL": ("雅歌", "Song of Solomon"), "ISA": ("イザヤ書", "Isaiah"), "JER": ("エレミヤ書", "Jeremiah"),
        "LAM": ("哀歌", "Lamentations"), "EZE": ("エゼキエル書", "Ezekiel"), "DAN": ("ダニエル書", "Daniel"),
        "HOS": ("ホセア書", "Hosea"), "JOE": ("ヨエル書", "Joel"), "AMO": ("アモス書", "Amos"),
        "OBA": ("オバデヤ書", "Obadiah"), "JON": ("ヨナ書", "Jonah"), "MIC": ("ミカ書", "Micah"),
        "NAH": ("ナホム書", "Nahum"), "HAB": ("ハバクク書", "Habakkuk"), "ZEP": ("ゼパニヤ書", "Zephaniah"),
        "HAG": ("ハガイ書", "Haggai"), "ZEC": ("ゼカリヤ書", "Zechariah"), "MAL": ("マラキ書", "Malachi"),
        "MAT": ("マタイによる福音書", "Matthew"), "MAR": ("マルコによる福音書", "Mark"),
        "LUK": ("ルカによる福音書", "Luke"), "JOH": ("ヨハネによる福音書", "John"),
        "ACT": ("使徒行伝", "Acts"), "ROM": ("ローマ人への手紙", "Romans"),
        "1CO": ("コリント人への第一の手紙", "1 Corinthians"), "2CO": ("コリント人への第二の手紙", "2 Corinthians"),
        "GAL": ("ガラテヤ人への手紙", "Galatians"), "EPH": ("エペソ人への手紙", "Ephesians"),
        "PHI": ("ピリピ人への手紙", "Philippians"), "COL": ("コロサイ人への手紙", "Colossians"),
        "1TH": ("テサロニケ人への第一の手紙", "1 Thessalonians"), "2TH": ("テサロニケ人への第二の手紙", "2 Thessalonians"),
        "1TI": ("テモテへの第一の手紙", "1 Timothy"), "2TI": ("テモテへの第二の手紙", "2 Timothy"),
        "TIT": ("テトスへの手紙", "Titus"), "PHM": ("ピレモンへの手紙", "Philemon"),
        "HEB": ("ヘブル人への手紙", "Hebrews"), "JAM": ("ヤコブの手紙", "James"),
        "1PE": ("ペテロの第一の手紙", "1 Peter"), "2PE": ("ペテロの第二の手紙", "2 Peter"),
        "1JO": ("ヨハネの第一の手紙", "1 John"), "2JO": ("ヨハネの第二の手紙", "2 John"),
        "3JO": ("ヨハネの第三の手紙", "3 John"), "JUD": ("ユダの手紙", "Jude"),
        "REV": ("ヨハネの黙示録", "Revelation"),
    ]
}
