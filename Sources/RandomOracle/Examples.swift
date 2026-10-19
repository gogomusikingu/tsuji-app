import Foundation

/// One fictional person's way of reading a verse into their own dilemma.
struct ReadingExample: Hashable {
    var worry: String
    var words: String
    var reading: String
    var action: String
}

/// Hand-written sample readings of ordinary, randomly drawn verses. Shown in the first-run guide
/// and behind "see how others read it" — never tied to the user's own verse, so they teach the
/// method without steering the answer.
enum FixedExamples {
    typealias Item = (verse: String, ref: String, example: ReadingExample)

    static func all(_ lang: AppLanguage) -> [Item] { lang == .ja ? ja : en }

    private static let ja: [Item] = [
        ("そのとき弟子たちは、イエスが用心するように言われたのはパンに入れるパン種のことではなく、パリサイ人とサドカイ人の教えのことだと理解した。", "マタイによる福音書 16章12節",
         ReadingExample(worry: "転職するか迷っている", words: "パンのことではなく、教えのことだった",
                        reading: "給料（パン）の話だと思っていたが、本当の悩みは「誰から学べるか」かもしれない",
                        action: "今の職場と転職先で、学べる人がいるかを書き出す")),
        ("するとルベン人、ガド人、およびマナセの半部族は答えて、イスラエルの千人隊のかしらたちに言った。", "ヨシュア記 22章21節",
         ReadingExample(worry: "上司に不満を伝えるか迷っている", words: "答えて、かしらたちに言った",
                        reading: "答えたのは一人ではなく三つの部族。一人で抱えず、仲間とそろって言えばいい",
                        action: "同僚に声をかけ、一緒に伝える")),
        ("そこで、ユダとベニヤミンの父祖の家の長たち、祭司たち、レビ人たち、すなわち、エルサレムにある主の家を建てるために上るよう神がその霊を奮い立たせられたすべての者が立ち上がった。", "エズラ記 1章5節",
         ReadingExample(worry: "地方へ引っ越すか迷っている", words: "霊を奮い立たせられたすべての者が立ち上がった",
                        reading: "立ち上がったのは、心が奮い立った者だけ。理屈より、心が動くかどうかで決めていい",
                        action: "引っ越し先を一度訪ねて、心が動くか確かめる")),
        ("主はモーセに告げられた。", "レビ記 24章1節",
         ReadingExample(worry: "習い事を始めるか迷っている", words: "告げられた",
                        reading: "モーセは自分で考える前に、まず告げられるのを聞いた。先に詳しい人の話を聞けばいい",
                        action: "体験レッスンを申し込み、先生の話を聞いてから決める")),
        ("ユダの人々は言った。「なぜあなたがたは私たちに向かって上って来たのか。」彼らは言った。「私たちはサムソンを縛り、彼が私たちにしたのと同じように彼にするために上って来た。」", "士師記 15章10節",
         ReadingExample(worry: "友人とけんかして、謝るか迷っている", words: "なぜ向かって来たのか",
                        reading: "相手にも「なぜ」がある。謝るかどうかの前に、まず理由を聞けばいい",
                        action: "「なぜ怒ったのか」を聞くメッセージを送る")),
        ("もし、あなたの神、主があなたに住むために与えられた町々の一つについて、あなたがこう聞くなら、", "申命記 13章12節",
         ReadingExample(worry: "夕飯をどうするか迷っている", words: "町々の一つについて、聞くなら",
                        reading: "町のことは、町の人に聞けばいい",
                        action: "近所の人におすすめの店を一つ聞いて、そこへ行く")),
    ]

    private static let en: [Item] = [
        ("Then they understood that he didn’t tell them to beware of the yeast of bread, but of the teaching of the Pharisees and Sadducees.", "Matthew 16:12",
         ReadingExample(worry: "Whether to change jobs", words: "not the yeast of bread, but the teaching",
                        reading: "I thought it was about pay (bread), but the real question may be who I can learn from",
                        action: "List the people I could learn from at each workplace")),
        ("Then the children of Reuben and the children of Gad and the half-tribe of Manasseh answered, and spoke to the heads of the thousands of Israel,", "Joshua 22:21",
         ReadingExample(worry: "Whether to raise a complaint with my boss", words: "answered, and spoke to the heads",
                        reading: "It was not one person who answered, but three tribes together. I don’t have to do it alone",
                        action: "Ask a colleague to raise it with me")),
        ("Then the heads of fathers’ households of Judah and Benjamin, the priests and the Levites, all whose spirit God had stirred to go up, rose up to build the LORD’s house which is in Jerusalem.", "Ezra 1:5",
         ReadingExample(worry: "Whether to move to the countryside", words: "all whose spirit God had stirred … rose up",
                        reading: "Only those whose spirit was stirred rose up. I can decide by whether my heart moves, not by logic",
                        action: "Visit the town once and see if my heart is stirred")),
        ("The LORD spoke to Moses, saying,", "Leviticus 24:1",
         ReadingExample(worry: "Whether to take up a new hobby class", words: "spoke to Moses",
                        reading: "Moses listened before acting. I should hear from someone who knows first",
                        action: "Book a trial lesson and talk to the teacher before deciding")),
        ("The men of Judah said, “Why have you come up against us?” They said, “We have come up to bind Samson, to do to him as he has done to us.”", "Judges 15:10",
         ReadingExample(worry: "Whether to apologise after a fight with a friend", words: "Why have you come up against us?",
                        reading: "They have a “why” too. Before deciding whether to apologise, ask for their reason",
                        action: "Send a message asking why they were upset")),
        ("If you hear about one of your cities, which the LORD your God gives you to dwell there, that", "Deuteronomy 13:12",
         ReadingExample(worry: "What to have for dinner", words: "If you hear about one of your cities",
                        reading: "Ask the town about the town",
                        action: "Ask a neighbour for one restaurant and go there")),
    ]
}
