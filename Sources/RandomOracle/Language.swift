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

    var tabDraw: String { t("書を開く", "Open the Book") }
    var tabRecords: String { t("記録", "Journal") }
    var intro: String { t("迷いをひとつ、心に思い浮かべてください。\n書は無作為に開かれます。引き直しはできません。",
                          "Hold one dilemma in your mind.\nThe book opens at random. There is no second draw.") }
    var openButton: String { t("書を開く", "Open the Book") }
    var focusing: String { t("目を閉じて、迷いを思い浮かべて…", "Close your eyes and hold your dilemma…") }
    var prompt: String { t("この言葉は、あなたの迷いのどこに重なりますか？\n解釈は、あなただけのものです。",
                           "Where does this touch your dilemma?\nThe interpretation is yours alone.") }
    var interpretation: String { t("どう読んだか（任意）", "How you read it (optional)") }
    var action: String { t("どうするか（任意）", "What you will do (optional)") }
    var outcome: String { t("その後どうなった？（任意）", "What happened afterwards? (optional)") }
    var done: String { t("書を閉じる", "Close the book") }
    var noRecords: String { t("まだ記録はありません", "No entries yet") }
    var disclaimer: String { t("最終的な判断は、あなた自身が行ってください。", "The final decision is always yours.") }
    func nextDraw(_ remaining: String) -> String { t("次に書を開けるまで \(remaining)", "Next opening in \(remaining)") }
}
