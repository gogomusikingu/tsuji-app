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

    var appName: String { t("辻", "Sortes") }
    var tagline: String { t("迷ったら、偶然の一節に聞く", "In doubt? Ask a chance verse") }
    var tabDraw: String { t("ひらく", "Open") }
    var tabMenu: String { t("メニュー", "Menu") }
    var menuIntro: String { t("メニューが決められないときは、写真を撮るだけ。\n書かれた品から、ひとつを無作為に選びます。",
                              "Can’t choose from the menu? Just take a photo.\nOne dish is picked at random.") }
    var menuChoosePhoto: String { t("メニューの写真を選ぶ", "Choose a menu photo") }
    var menuTakePhoto: String { t("メニューを撮る", "Take a photo") }
    var menuFromLibrary: String { t("写真から選ぶ", "Choose from Photos") }
    var followupTitle: String { t("辻", "Sortes") }
    var followupBody: String { t("数日前に書をひらいた迷いは、その後どうなりましたか？", "A few days ago you opened the book. How did it turn out?") }
    var menuDropHint: String { t("写真をここにドラッグしても読み込めます", "You can also drop a photo here") }
    var menuReading: String { t("文字を読み取っています…", "Reading the menu…") }
    var menuCheck: String { t("読み取った品です。料理でないものはチェックを外してください。", "Dishes found. Untick anything that isn’t a dish.") }
    var menuAdd: String { t("品を追加", "Add a dish") }
    var menuAddButton: String { t("追加", "Add") }
    var menuDecide: String { t("ひとつ選ぶ", "Pick one") }
    var menuStartOver: String { t("別の写真にする", "Use another photo") }
    var menuResultLead: String { t("今日は、これにしましょう。", "Today, go with this.") }
    var menuAgain: String { t("もう一度選ぶ", "Pick again") }
    var menuBack: String { t("一覧に戻る", "Back to list") }
    var menuLoadFailed: String { t("画像を読み込めませんでした。", "Couldn’t open the image.") }
    var menuNoText: String { t("文字を読み取れませんでした。明るく、正面から撮った写真で試してください。",
                               "No text found. Try a brighter photo taken straight on.") }
    var tabRecords: String { t("記録", "Journal") }
    var intro: String { t("迷いをひとつ、心に思い浮かべてください。\n書は無作為にひらかれます。引き直しはできません。",
                          "Hold one dilemma in your mind.\nThe book opens at random. There is no second draw.") }
    var openButton: String { t("書をひらく", "Open the book") }
    var focusing: String { t("目を閉じて、迷いを思い浮かべて…", "Close your eyes and hold your dilemma…") }
    var step1: String { t("いちばん目に止まった言葉はどれですか？", "Which words caught your eye first?") }
    var step2: String { t("その言葉を、あなたの迷いに置き換えるとしたら？", "If those words were about your dilemma, what would they mean?") }
    var step3: String { t("では、どうしますか？", "So, what will you do?") }
    var optional: String { t("書かなくても構いません", "Optional") }
    var next: String { t("次へ", "Next") }
    var keyword: String { t("目に止まった言葉（任意）", "Words that caught your eye (optional)") }
    var interpretation: String { t("どう読んだか（任意）", "How you read it (optional)") }
    var action: String { t("どうするか（任意）", "What you will do (optional)") }
    var outcome: String { t("その後どうなった？（任意）", "What happened afterwards? (optional)") }
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
    var statsOpened: String { t("ひらいた", "Opened") }
    var statsDecided: String { t("行動を決めた", "Decided") }
    var statsReflected: String { t("振り返った", "Looked back") }
    var statsUnit: String { t("回", "") }
    var noRecords: String { t("まだ記録はありません", "No entries yet") }
    var disclaimer: String { t("最終的な判断は、あなた自身が行ってください。", "The final decision is always yours.") }
    func nextDraw(_ remaining: String) -> String { t("次に書をひらけるまで \(remaining)", "Next opening in \(remaining)") }
}
