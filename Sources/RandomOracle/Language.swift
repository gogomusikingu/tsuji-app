import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case ja, en
    var id: String { rawValue }
    var label: String { self == .ja ? "日本語" : "English" }
}

/// UI strings. Kept as a plain table for the Mac prototype; move to a String Catalog in the iOS app.
struct L10n {
    let lang: AppLanguage
    private func t(_ ja: String, _ en: String) -> String { lang == .ja ? ja : en }

    var appName: String { t("辻", "Tsuji") }
    var tagline: String { t("迷ったら、偶然の一節に問う", "In doubt? Ask a chance verse") }
    var tabDraw: String { t("ひらく", "Open") }
    var followupTitle: String { t("辻", "Tsuji") }
    var followupBody: String { t("数日前に書をひらいた迷いは、その後どうなりましたか？", "A few days ago you opened the book. How did it turn out?") }
    var tabRecords: String { t("記録", "Journal") }
    var intro: String { t("迷いをひとつ、心に思い浮かべてください\n書は無作為にひらかれます\n引き直しはできません",
                          "Hold one dilemma in your mind.\nThe book opens at random.\nThere is no second draw.") }
    var openButton: String { t("書をひらく", "Open the book") }
    var focusing: String { t("目を閉じて、迷いを思い浮かべて…", "Close your eyes and hold your dilemma…") }
    var focusingOpen: String { t("一節が、浮かび上がります", "A verse rises to the page") }
    var step1: String { t("いちばん目に止まった言葉はどれですか？", "Which words caught your eye first?") }
    var step2: String { t("その言葉を、迷いに置き換えるとしたら？", "If those words were about your dilemma, what would they mean?") }
    var step3: String { t("では、どうしますか？", "So, what will you do?") }
    var next: String { t("次へ", "Next") }
    var stepOutcome: String { t("その後、どうなりましたか？", "What happened afterwards?") }
    func writings(_ n: Int) -> String { t("書き込み（\(n)）", "Writings (\(n))") }
    func lastWritten(_ time: String) -> String { t("最後の書き込み \(time)", "Last written \(time)") }
    var write: String { t("＋ 書き込む", "+ Write") }
    var writePlaceholder: String { t("書き込む…", "Write…") }
    var keep: String { t("残す", "Keep") }
    var strikeHint: String { t("書き込んだ行を押すと、線を引けます。", "Tap a line to strike it through.") }
    var strikeTitle: String { t("考えが、変わりましたか。", "Has your mind changed?") }
    var strikeBody: String { t("線を引いても、文字は消えずに残ります。", "A line through it leaves the words in place.") }
    var restoreTitle: String { t("やはり、この考えに戻りますか。", "Back to this thought after all?") }
    var restoreBody: String { t("行ったり来たりした跡も、記録になります。", "Going back and forth leaves its own trace.") }
    var strike: String { t("線を引く", "Strike through") }
    var restore: String { t("線を戻す", "Restore") }
    var leaveAsIs: String { t("そのままにする", "Leave it") }
    var todayAlreadyOpen: String { t("今日の書は、もうひらかれました", "Today the book has already been opened") }
    var openToday: String { t("今日の一節を読み返す", "Read today’s verse again") }
    var todayTitle: String { t("今日の一節", "Today’s verse") }
    var done: String { t("書を閉じる", "Close the book") }
    var showContext: String { t("前後を読む", "Read around it") }
    var hideContext: String { t("この一節だけにする", "Show this verse only") }
    var showOthers: String { t("他の人の読み方を見る", "See how others read it") }
    var othersCaption: String { t("別の節を引いた人たちの、架空の読み方の例です。正しい答えではありません。",
                                  "Fictional readings of other verses. They are not the right answer.") }
    var exWorry: String { t("悩み", "Dilemma") }
    var exWords: String { t("目に止まった言葉", "Words") }
    var exReading: String { t("読み方", "Reading") }
    var exAction: String { t("行動", "Action") }
    var exOutcome: String { t("その後", "Afterwards") }
    var guideTitle: String { t("書のひらき方", "How to open the book") }
    var poemSource: String { t("『万葉集』巻十一・二五〇六", "Man’yōshū, Book 11, No. 2506 (8th century Japan)") }
    var poemMeaning: String { t("言葉に霊が宿るという、いくつもの道が交わる辻で、夕暮れに行き交う人の言葉に問うてみた。答えははっきりと出た。あの人は、私に心を寄せるだろう。",
                                "At the crossroads where many paths meet and words hold spirit, I asked the evening voices of passers-by. The answer came clear: she will come to me.") }
    var guideHistory: String { t("千年以上前の日本では、迷った人は辻（道の交わる所）に立ち、通りがかった人の何気ない言葉を手がかりにしました。古代ローマでは、詩集を無作為に開いた一行に従いました。偶然の言葉に迷いを預けることは、洋の東西を問わない知恵です。",
                                 "Over a thousand years ago in Japan, people in doubt stood at a crossroads and took the chance words of passers-by as their guide. In ancient Rome, they followed a line from a book of poetry opened at random. Entrusting a dilemma to chance words is an old wisdom, East and West.") }
    var guideBody: String { t("出てくる一節は、あなたの悩みと無関係に見えるのが普通です。\n正しい意味を探す必要はありません。目に止まった言葉を、自分の悩みに勝手にこじつけてください。同じ一節から、人によって正反対の結論が出てもかまいません。",
                              "The verse will usually look unrelated to your dilemma.\nDon’t look for the correct meaning. Take the words that catch your eye and bend them to your situation. The same verse may lead different people to opposite conclusions.") }
    var guideExamples: String { t("読み方の例", "Examples") }
    var guideStart: String { t("はじめる", "Start") }
    var share: String { t("シェア", "Share") }
    var shareTitle: String { t("この一節をシェア", "Share this verse") }
    var shareIncludeReading: String { t("自分の読み方も載せる", "Include my reading") }
    var cancel: String { t("やめる", "Cancel") }
    var olderDay: String { t("‹ 前の日", "‹ Earlier") }
    var newerDay: String { t("次の日 ›", "Later ›") }
    func openedAt(_ time: String) -> String { t("\(time) にひらいた", "opened \(time)") }
    var noRecords: String { t("まだ記録はありません", "No entries yet") }
    var disclaimer: String { t("最終的な判断は、あなた自身が行ってください。", "The final decision is always yours.") }
    func nextDraw(_ remaining: String) -> String { t("次に書をひらけるまで \(remaining)", "Next opening in \(remaining)") }
}
