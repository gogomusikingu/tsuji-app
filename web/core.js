// Logic shared by the web app and its tests: strings, the Bible index, drawing, the journal.
// No DOM here, so `node --test` can run it.

export const WEAR_LIMIT = 50;
export const DAY = 24 * 60 * 60 * 1000;
export const KINDS = ["keyword", "interpretation", "action", "outcome"];

// UI strings, matching Language.swift.
const T = {
  appName: ["辻", "Tsuji"],
  tagline: ["迷ったら、偶然の一節に問う", "In doubt? Ask a chance verse"],
  tabDraw: ["ひらく", "Open"],
  tabRecords: ["記録", "Journal"],
  intro: ["迷いをひとつ、心に思い浮かべてください\n書は無作為にひらかれます\n引き直しはできません",
    "Hold one dilemma in your mind.\nThe book opens at random.\nThere is no second draw."],
  openButton: ["書をひらく", "Open the book"],
  topicQuestion: ["何についての迷いですか？", "What is your dilemma about?"],
  focusingOpen: ["一節が、浮かび上がります", "A verse rises to the page"],
  step1: ["いちばん目に止まった言葉はどれですか？", "Which words caught your eye first?"],
  step3: ["では、どうしますか？", "So, what will you do?"],
  next: ["次へ", "Next"],
  stepOutcome: ["その後、どうなりましたか？", "What happened afterwards?"],
  write: ["＋ 書き込む", "+ Write"],
  writePlaceholder: ["書き込む…", "Write…"],
  keep: ["残す", "Keep"],
  strikeHint: ["書き込んだ行を押すと、線を引けます。", "Tap a line to strike it through."],
  strikeTitle: ["考えが、変わりましたか。", "Has your mind changed?"],
  strikeBody: ["線を引いても、文字は消えずに残ります。", "A line through it leaves the words in place."],
  restoreTitle: ["やはり、この考えに戻りますか。", "Back to this thought after all?"],
  restoreBody: ["行ったり来たりした跡も、記録になります。", "Going back and forth leaves its own trace."],
  strike: ["線を引く", "Strike through"],
  restore: ["線を戻す", "Restore"],
  leaveAsIs: ["そのままにする", "Leave it"],
  todayAlreadyOpen: ["今日の書は、もうひらかれました", "Today the book has already been opened"],
  openToday: ["今日の一節を読み返す", "Read today’s verse again"],
  todayTitle: ["今日の一節", "Today’s verse"],
  done: ["書を閉じる", "Close the book"],
  showContext: ["前後を読む", "Read around it"],
  hideContext: ["この一節だけにする", "Show this verse only"],
  showOthers: ["他の人の読み方を見る", "See how others read it"],
  othersCaption: ["別の節を引いた人たちの、架空の読み方の例です。正しい答えではありません。",
    "Fictional readings of other verses. They are not the right answer."],
  exWorry: ["悩み", "Dilemma"],
  exWords: ["目に止まった言葉", "Words"],
  exReading: ["読み方", "Reading"],
  exAction: ["行動", "Action"],
  exOutcome: ["その後", "Afterwards"],
  guideTitle: ["書のひらき方", "How to open the book"],
  poemSource: ["『万葉集』巻十一・二五〇六", "Man’yōshū, Book 11, No. 2506 (8th century Japan)"],
  poemMeaning: ["言葉に霊が宿るという、いくつもの道が交わる辻で、夕暮れに行き交う人の言葉に問うてみた。答えははっきりと出た。あの人は、私に心を寄せるだろう。",
    "At the crossroads where many paths meet and words hold spirit, I asked the evening voices of passers-by. The answer came clear: she will come to me."],
  guideHistory: ["千年以上前の日本では、迷った人は辻（道の交わる所）に立ち、通りがかった人の何気ない言葉を手がかりにしました。古代ローマでは、詩集を無作為に開いた一行に従いました。偶然の言葉に迷いを預けることは、洋の東西を問わない知恵です。",
    "Over a thousand years ago in Japan, people in doubt stood at a crossroads and took the chance words of passers-by as their guide. In ancient Rome, they followed a line from a book of poetry opened at random. Entrusting a dilemma to chance words is an old wisdom, East and West."],
  guideBody: ["出てくる一節は、あなたの悩みと無関係に見えるのが普通です。\n正しい意味を探す必要はありません。目に止まった言葉を、自分の悩みに勝手にこじつけてください。同じ一節から、人によって正反対の結論が出てもかまいません。",
    "The verse will usually look unrelated to your dilemma.\nDon’t look for the correct meaning. Take the words that catch your eye and bend them to your situation. The same verse may lead different people to opposite conclusions."],
  guideExamples: ["読み方の例", "Examples"],
  guideStart: ["はじめる", "Start"],
  share: ["シェア", "Share"],
  shareTitle: ["この一節をシェア", "Share this verse"],
  shareIncludeReading: ["自分の読み方も載せる", "Include my reading"],
  cancel: ["やめる", "Cancel"],
  olderDay: ["‹ 前の日", "‹ Earlier"],
  newerDay: ["次の日 ›", "Later ›"],
  noRecords: ["まだ記録はありません", "No entries yet"],
  disclaimer: ["最終的な判断は、あなた自身が行ってください。", "The final decision is always yours."],
  loadFailed: ["書を読み込めませんでした。通信を確かめて、もう一度押してください。", "The book could not be loaded. Check your connection and try again."],
  langToggle: ["EN", "日本語"],
};

/** What the dilemma is about, chosen before the book opens. It never changes which verse comes;
 *  it only names the dilemma in the questions. "other" leaves the dilemma unnamed. */
export const TOPICS = {
  people: ["人間関係", "Relationships", "人間関係の迷い", "your relationship dilemma"],
  work: ["仕事・学び", "Work & study", "仕事・学びの迷い", "your work or study dilemma"],
  money: ["お金", "Money", "お金の迷い", "your money dilemma"],
  health: ["からだ・こころ", "Body & mind", "からだ・こころの迷い", "your body or mind dilemma"],
  life: ["暮らし", "Daily life", "暮らしの迷い", "your everyday dilemma"],
  other: ["その他", "Something else", "迷い", "your dilemma"],
};

export function strings(lang) {
  const i = lang === "ja" ? 0 : 1;
  const s = Object.fromEntries(Object.entries(T).map(([k, v]) => [k, v[i]]));
  s.topic = (t) => TOPICS[t]?.[i] ?? "";
  const dilemma = (t) => (TOPICS[t] ?? TOPICS.other)[2 + i];
  s.focusing = (t) => (i === 0 ? `目を閉じて、\n${dilemma(t)}を思い浮かべて…` : `Close your eyes and\nhold ${dilemma(t)}…`);
  s.step2 = (t) => (i === 0 ? `その言葉を、${dilemma(t)}に置き換えるとしたら？`
    : `If those words were about ${dilemma(t)}, what would they mean?`);
  s.writings = (n) => (i === 0 ? `書き込み（${n}）` : `Writings (${n})`);
  s.lastWritten = (t) => (i === 0 ? `最後の書き込み ${t}` : `Last written ${t}`);
  s.openedAt = (t) => (i === 0 ? `${t} にひらいた` : `opened ${t}`);
  s.nextDraw = (r) => (i === 0 ? `次に書をひらけるまで ${r}` : `Next opening in ${r}`);
  s.question = (kind, topic) => ({
    keyword: `一　${s.step1}`, interpretation: `二　${s.step2(topic)}`, action: `三　${s.step3}`, outcome: s.stepOutcome,
  })[kind];
  return s;
}

const BOOK_NAMES = {
  GEN: ["創世記", "Genesis"], EXO: ["出エジプト記", "Exodus"], LEV: ["レビ記", "Leviticus"],
  NUM: ["民数記", "Numbers"], DEU: ["申命記", "Deuteronomy"], JOS: ["ヨシュア記", "Joshua"],
  JDG: ["士師記", "Judges"], RUT: ["ルツ記", "Ruth"], "1SA": ["サムエル記上", "1 Samuel"],
  "2SA": ["サムエル記下", "2 Samuel"], "1KI": ["列王紀上", "1 Kings"], "2KI": ["列王紀下", "2 Kings"],
  "1CH": ["歴代志上", "1 Chronicles"], "2CH": ["歴代志下", "2 Chronicles"], EZR: ["エズラ記", "Ezra"],
  NEH: ["ネヘミヤ記", "Nehemiah"], EST: ["エステル記", "Esther"], JOB: ["ヨブ記", "Job"],
  PSA: ["詩篇", "Psalms"], PRO: ["箴言", "Proverbs"], ECC: ["伝道の書", "Ecclesiastes"],
  SOL: ["雅歌", "Song of Solomon"], ISA: ["イザヤ書", "Isaiah"], JER: ["エレミヤ書", "Jeremiah"],
  LAM: ["哀歌", "Lamentations"], EZE: ["エゼキエル書", "Ezekiel"], DAN: ["ダニエル書", "Daniel"],
  HOS: ["ホセア書", "Hosea"], JOE: ["ヨエル書", "Joel"], AMO: ["アモス書", "Amos"],
  OBA: ["オバデヤ書", "Obadiah"], JON: ["ヨナ書", "Jonah"], MIC: ["ミカ書", "Micah"],
  NAH: ["ナホム書", "Nahum"], HAB: ["ハバクク書", "Habakkuk"], ZEP: ["ゼパニヤ書", "Zephaniah"],
  HAG: ["ハガイ書", "Haggai"], ZEC: ["ゼカリヤ書", "Zechariah"], MAL: ["マラキ書", "Malachi"],
  MAT: ["マタイによる福音書", "Matthew"], MAR: ["マルコによる福音書", "Mark"],
  LUK: ["ルカによる福音書", "Luke"], JOH: ["ヨハネによる福音書", "John"],
  ACT: ["使徒行伝", "Acts"], ROM: ["ローマ人への手紙", "Romans"],
  "1CO": ["コリント人への第一の手紙", "1 Corinthians"], "2CO": ["コリント人への第二の手紙", "2 Corinthians"],
  GAL: ["ガラテヤ人への手紙", "Galatians"], EPH: ["エペソ人への手紙", "Ephesians"],
  PHI: ["ピリピ人への手紙", "Philippians"], COL: ["コロサイ人への手紙", "Colossians"],
  "1TH": ["テサロニケ人への第一の手紙", "1 Thessalonians"], "2TH": ["テサロニケ人への第二の手紙", "2 Thessalonians"],
  "1TI": ["テモテへの第一の手紙", "1 Timothy"], "2TI": ["テモテへの第二の手紙", "2 Timothy"],
  TIT: ["テトスへの手紙", "Titus"], PHM: ["ピレモンへの手紙", "Philemon"],
  HEB: ["ヘブル人への手紙", "Hebrews"], JAM: ["ヤコブの手紙", "James"],
  "1PE": ["ペテロの第一の手紙", "1 Peter"], "2PE": ["ペテロの第二の手紙", "2 Peter"],
  "1JO": ["ヨハネの第一の手紙", "1 John"], "2JO": ["ヨハネの第二の手紙", "2 John"],
  "3JO": ["ヨハネの第三の手紙", "3 John"], JUD: ["ユダの手紙", "Jude"],
  REV: ["ヨハネの黙示録", "Revelation"],
};

export function verseText(v, lang) { return lang === "ja" ? v.ja : v.en; }

export function reference(v, lang) {
  const names = BOOK_NAMES[v.book];
  const name = names ? names[lang === "ja" ? 0 : 1] : v.book;
  return lang === "ja" ? `${name} ${v.chapter}章${v.verse}節` : `${name} ${v.chapter}:${v.verse}`;
}

/** Uniform integer in [0, n) from the cryptographic generator, without modulo bias. */
export function randomIndex(n, crypto = globalThis.crypto) {
  const limit = Math.floor(0x100000000 / n) * n;
  const buf = new Uint32Array(1);
  for (;;) {
    crypto.getRandomValues(buf);
    if (buf[0] < limit) return buf[0] % n;
  }
}

/** Every verse the book may open at, as [book, position within that book]: all of them
 *  except bare lists of names, which give nothing to read into a dilemma. */
export function drawable(index) {
  const out = [];
  for (const [book, count, skipped = []] of index) {
    const skip = new Set(skipped);
    for (let i = 0; i < count; i++) if (!skip.has(i)) out.push([book, i]);
  }
  return out;
}

export function parseBook(book, tsv) {
  return tsv.split("\n").filter(Boolean).map((line) => {
    const [chapter, verse, ja, en] = line.split("\t");
    return { book, chapter: Number(chapter), verse: Number(verse), ja, en };
  });
}

/** The verse with up to `radius` neighbours on each side, within the same chapter. */
export function context(verses, target, radius) {
  const i = verses.findIndex((v) => v.chapter === target.chapter && v.verse === target.verse);
  if (i < 0) return [target];
  return verses.slice(Math.max(0, i - radius), i + radius + 1).filter((v) => v.chapter === target.chapter);
}

/** "H:MM:SS" until the next opening. */
export function formatRemaining(ms) {
  const s = Math.ceil(ms / 1000);
  return `${Math.floor(s / 3600)}:${String(Math.floor((s % 3600) / 60)).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}`;
}

const pad = (n) => String(n).padStart(2, "0");
export function clock(t) { const d = new Date(t); return `${pad(d.getHours())}:${pad(d.getMinutes())}`; }
export function shortTime(t) { const d = new Date(t); return `${d.getMonth() + 1}/${d.getDate()} ${clock(t)}`; }
export function longDate(t, lang) {
  const d = new Date(t);
  if (lang === "ja") {
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日（${"日月火水木金土"[d.getDay()]}）`;
  }
  return d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" });
}

export function uuid() {
  return globalThis.crypto.randomUUID ? globalThis.crypto.randomUUID()
    : Array.from(globalThis.crypto.getRandomValues(new Uint8Array(16)), (b) => b.toString(16).padStart(2, "0")).join("");
}

// --- Journal entries: lines can be added and struck through (or restored), never edited or removed.

export function newEntry(verse, now = Date.now(), topic = null) {
  return { id: uuid(), date: now, verse, topic, notes: { keyword: [], interpretation: [], action: [], outcome: [] } };
}

export function writeNote(entry, kind, text, now = Date.now()) {
  const trimmed = text.trim();
  if (!trimmed) return false;
  entry.notes[kind].push({ id: uuid(), text: trimmed, date: now, strikes: [] });
  return true;
}

export function toggleStrike(entry, kind, noteID, now = Date.now()) {
  const note = entry.notes[kind].find((n) => n.id === noteID);
  if (note) note.strikes.push(now);
  return note;
}

export const isStruck = (note) => note.strikes.length % 2 === 1;

/** The latest line that is not struck through: what the user currently stands by. */
export function current(entry, kind) {
  const live = entry.notes[kind].filter((n) => !isStruck(n));
  return live.length ? live[live.length - 1].text : "";
}

export const noteCount = (entry) => KINDS.reduce((n, k) => n + entry.notes[k].length, 0);
export const hasReading = (entry) => KINDS.some((k) => current(entry, k) !== "");
export function lastWritten(entry) {
  const dates = KINDS.flatMap((k) => entry.notes[k].map((n) => n.date));
  return dates.length ? Math.max(...dates) : null;
}

/** 0 when freshly written, 1 when worn through by striking and restoring. */
export const wear = (note) => Math.min(note.strikes.length / WEAR_LIMIT, 1);

/** Deterministic random numbers per note, so each worn patch keeps its shape. */
export function seeded(id, salt = 0) {
  let h = 2166136261 ^ salt;
  for (const c of id) h = Math.imul(h ^ c.charCodeAt(0), 16777619);
  return (lo, hi) => {
    h = (h + 0x6d2b79f5) | 0;
    let t = Math.imul(h ^ (h >>> 15), 1 | h);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return lo + (hi - lo) * (((t ^ (t >>> 14)) >>> 0) / 4294967296);
  };
}

// --- Fixed sample readings of other verses (Examples.swift).

export const EXAMPLES = {
  ja: [
    ["そのとき弟子たちは、イエスが用心するように言われたのはパンに入れるパン種のことではなく、パリサイ人とサドカイ人の教えのことだと理解した。", "マタイによる福音書 16章12節",
      ["転職するか迷っている", "パンのことではなく、教えのことだった", "給料（パン）の話だと思っていたが、本当の悩みは「誰から学べるか」かもしれない", "今の職場と転職先で、学べる人がいるかを書き出す"]],
    ["するとルベン人、ガド人、およびマナセの半部族は答えて、イスラエルの千人隊のかしらたちに言った。", "ヨシュア記 22章21節",
      ["上司に不満を伝えるか迷っている", "答えて、かしらたちに言った", "答えたのは一人ではなく三つの部族。一人で抱えず、仲間とそろって言えばいい", "同僚に声をかけ、一緒に伝える"]],
    ["ユダとタマルの間にペレツとゼラが生まれ、ペレツにヘツロンが生まれ、ヘツロンにラムが生まれた。", "マタイによる福音書 1章3節",
      ["昼ごはんを何にするか迷っている", "タマル", "タマルは、タマゴに字面が似ている。意味がわからなくても、字面からこじつけていい", "昼ごはんは玉子料理にする"]],
    ["そこで、ユダとベニヤミンの父祖の家の長たち、祭司たち、レビ人たち、すなわち、エルサレムにある主の家を建てるために上るよう神がその霊を奮い立たせられたすべての者が立ち上がった。", "エズラ記 1章5節",
      ["地方へ引っ越すか迷っている", "霊を奮い立たせられたすべての者が立ち上がった", "立ち上がったのは、心が奮い立った者だけ。理屈より、心が動くかどうかで決めていい", "引っ越し先を一度訪ねて、心が動くか確かめる"]],
    ["主はモーセに告げられた。", "レビ記 24章1節",
      ["習い事を始めるか迷っている", "告げられた", "モーセは自分で考える前に、まず告げられるのを聞いた。先に詳しい人の話を聞けばいい", "体験レッスンを申し込み、先生の話を聞いてから決める"]],
    ["ユダの人々は言った。「なぜあなたがたは私たちに向かって上って来たのか。」彼らは言った。「私たちはサムソンを縛り、彼が私たちにしたのと同じように彼にするために上って来た。」", "士師記 15章10節",
      ["友人とけんかして、謝るか迷っている", "なぜ向かって来たのか", "相手にも「なぜ」がある。謝るかどうかの前に、まず理由を聞けばいい", "「なぜ怒ったのか」を聞くメッセージを送る"]],
    ["もし、あなたの神、主があなたに住むために与えられた町々の一つについて、あなたがこう聞くなら、", "申命記 13章12節",
      ["夕飯をどうするか迷っている", "町々の一つについて、聞くなら", "町のことは、町の人に聞けばいい", "近所の人におすすめの店を一つ聞いて、そこへ行く"]],
  ],
  en: [
    ["Then they understood that he didn’t tell them to beware of the yeast of bread, but of the teaching of the Pharisees and Sadducees.", "Matthew 16:12",
      ["Whether to change jobs", "not the yeast of bread, but the teaching", "I thought it was about pay (bread), but the real question may be who I can learn from", "List the people I could learn from at each workplace"]],
    ["Then the children of Reuben and the children of Gad and the half-tribe of Manasseh answered, and spoke to the heads of the thousands of Israel,", "Joshua 22:21",
      ["Whether to raise a complaint with my boss", "answered, and spoke to the heads", "It was not one person who answered, but three tribes together. I don’t have to do it alone", "Ask a colleague to raise it with me"]],
    ["Judah became the father of Perez and Zerah by Tamar. Perez became the father of Hezron. Hezron became the father of Ram.", "Matthew 1:3",
      ["What to have for lunch", "Tamar", "Tamar sounds a little like tomato. Even without knowing what it means, I can bend the sound of it", "Have something with tomatoes for lunch"]],
    ["Then the heads of fathers’ households of Judah and Benjamin, the priests and the Levites, all whose spirit God had stirred to go up, rose up to build the LORD’s house which is in Jerusalem.", "Ezra 1:5",
      ["Whether to move to the countryside", "all whose spirit God had stirred … rose up", "Only those whose spirit was stirred rose up. I can decide by whether my heart moves, not by logic", "Visit the town once and see if my heart is stirred"]],
    ["The LORD spoke to Moses, saying,", "Leviticus 24:1",
      ["Whether to take up a new hobby class", "spoke to Moses", "Moses listened before acting. I should hear from someone who knows first", "Book a trial lesson and talk to the teacher before deciding"]],
    ["The men of Judah said, “Why have you come up against us?” They said, “We have come up to bind Samson, to do to him as he has done to us.”", "Judges 15:10",
      ["Whether to apologise after a fight with a friend", "Why have you come up against us?", "They have a “why” too. Before deciding whether to apologise, ask for their reason", "Send a message asking why they were upset"]],
    ["If you hear about one of your cities, which the LORD your God gives you to dwell there, that", "Deuteronomy 13:12",
      ["What to have for dinner", "If you hear about one of your cities", "Ask the town about the town", "Ask a neighbour for one restaurant and go there"]],
  ],
};

export function exampleCaption([verse, ref], lang) {
  return lang === "ja" ? `${verse}（${ref}）` : `${verse} (${ref})`;
}
