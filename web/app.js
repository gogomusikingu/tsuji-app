// 辻 web version: the same rituals as the iPhone app, in plain DOM. All records stay in this browser.
import {
  DAY, KINDS, strings, verseText, reference, randomIndex, drawable, parseBook, context, formatRemaining,
  clock, shortTime, longDate, newEntry, writeNote, toggleStrike, isStruck, current, noteCount, hasReading,
  lastWritten, wear, seeded, EXAMPLES, exampleCaption, TOPICS,
} from "./core.js";
import { markSVG, OUTLINE, INNER, VERSE } from "./mark.js";

const FADE = 700;
const params = new URLSearchParams(location.search);
// Testing: ?cooldown=10 lets the book open again after 10 seconds instead of a day.
const INTERVAL = params.has("cooldown") ? Number(params.get("cooldown")) * 1000 : DAY;

// --- Storage (this browser only) ---------------------------------------------------------------

const KEY = { lang: "tsuji.lang", guide: "tsuji.guideSeen", last: "tsuji.lastDrawAt", pending: "tsuji.pendingDraw", topic: "tsuji.pendingTopic", journal: "tsuji.journal" };
const store = {
  get(k) { try { return localStorage.getItem(k); } catch { return null; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch { /* private mode: lives for this visit only */ } },
  remove(k) { try { localStorage.removeItem(k); } catch { /* ignore */ } },
};

let lang = store.get(KEY.lang) || (navigator.language?.startsWith("ja") ? "ja" : "en");
let L = strings(lang);
let journal = JSON.parse(store.get(KEY.journal) || "[]");
const saveJournal = () => store.set(KEY.journal, JSON.stringify(journal));
const entryByID = (id) => journal.find((e) => e.id === id);

const lastDrawAt = () => Number(store.get(KEY.last) || 0);
const remaining = (now = Date.now()) => Math.max(0, INTERVAL - (now - lastDrawAt()));
const pendingDraw = () => store.get(KEY.pending);

// --- The Bible, one book per file, fetched on demand ---------------------------------------------

let indexPromise = null;
const books = new Map();
function loadIndex() {
  indexPromise ??= fetch("data/index.json").then((r) => { if (!r.ok) throw new Error(r.status); return r.json(); })
    .catch((e) => { indexPromise = null; throw e; });
  return indexPromise;
}
function loadBook(code) {
  if (!books.has(code)) {
    books.set(code, fetch(`data/${code}.tsv`).then((r) => { if (!r.ok) throw new Error(r.status); return r.text(); })
      .then((t) => parseBook(code, t))
      .catch((e) => { books.delete(code); throw e; }));
  }
  return books.get(code);
}

/** Turns the committed draw (a position among all verses) into a journal entry. */
async function resolvePending() {
  const n = Number(pendingDraw());
  const index = await loadIndex();
  const [book, pos] = drawable(index)[n];
  const verses = await loadBook(book);
  const entry = newEntry(verses[pos], lastDrawAt() || Date.now(), store.get(KEY.topic));
  journal.unshift(entry);
  saveJournal();
  store.remove(KEY.pending);
  store.remove(KEY.topic);
  return entry;
}

// --- DOM helpers --------------------------------------------------------------------------------

function h(tag, props = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (v == null || v === false) continue;
    if (k === "class") el.className = v;
    else if (k === "text") el.textContent = v;
    else if (k === "html") el.innerHTML = v;
    else if (k.startsWith("on")) el.addEventListener(k.slice(2), v);
    else el.setAttribute(k, v === true ? "" : v);
  }
  el.append(...clean(children));
  return el;
}
const clean = (nodes) => nodes.flat().filter((c) => c != null && c !== false);
const button = (text, onclick, filled = false) => h("button", { class: `ink-button${filled ? " filled" : ""}`, text, onclick });
const link = (text, onclick) => h("button", { class: "link", text, onclick });
const later = (ms) => new Promise((r) => setTimeout(r, ms));
const countdown = (cls = "small") => h("span", { class: `countdown faint digits ${cls}`, text: L.nextDraw(formatRemaining(remaining())) });

/** A place where views dissolve into each other: the old one fades out as the new one fades in. */
function slot(el = h("div", { class: "stack" })) {
  el.show = (view, animated = true) => {
    for (const old of [...el.children]) {
      if (!animated) { old.remove(); continue; }
      old.classList.add("fade", "out");
      setTimeout(() => old.remove(), FADE);
    }
    view.classList.add("fade");
    if (animated) { view.classList.add("out"); el.append(view); view.offsetWidth; view.classList.remove("out"); } else el.append(view);
  };
  return el;
}

/** The mark at the exact centre of the screen, with words underneath. */
function stage(verse, ...below) {
  const el = h("div", { class: "stage", html: markSVG({ tight: true, verse }) });
  el.append(h("div", { class: "below" }, ...below));
  return el;
}

/** Lays `build(close)` over a veil of paper. Touches wait until it has fully faded in;
 *  tapping the paper around it closes it, so it can never trap the user. */
function cover(build) {
  const el = h("div", { class: "cover" });
  let closed = false;
  const close = () => {
    if (closed) return;
    closed = true;
    el.classList.remove("ready", "shown");
    setTimeout(() => el.remove(), FADE);
  };
  el.append(build(close));
  el.addEventListener("click", (e) => { if (e.target === el) close(); });
  document.body.append(el);
  el.offsetWidth;
  el.classList.add("shown");
  setTimeout(() => { if (!closed) el.classList.add("ready"); }, FADE);
  return close;
}

// --- Shared pieces --------------------------------------------------------------------------------

/** The verse alone on its page; surrounding verses appear faintly only when asked for. */
function versePage(verse) {
  const verses = h("div", { class: "verses fade" });
  let around = false;
  const toggle = link(L.showContext, async () => {
    around = !around;
    toggle.textContent = around ? L.hideContext : L.showContext;
    let shown = [verse];
    if (around) { try { shown = context(await loadBook(verse.book), verse, 2); } catch { /* offline: verse only */ } }
    verses.classList.add("out");
    await later(FADE / 2);
    fill(shown);
    verses.classList.remove("out");
  });
  const fill = (list) => {
    verses.replaceChildren(...list.map((v) => {
      const drawn = v.chapter === verse.chapter && v.verse === verse.verse;
      return h("div", { class: "v" },
        around && h("span", { class: "n", text: String(v.verse) }),
        h("p", { class: drawn ? "text" : "around", text: verseText(drawn ? verse : v, lang) }));
    }));
  };
  fill([verse]);
  return h("div", { class: "page" }, verses,
    h("div", { class: "foot" }, toggle, h("span", { class: "ref", text: reference(verse, lang) })));
}

function exampleCard(item) {
  const [, , [worry, words, reading, action]] = item;
  const row = (label, value) => h("div", { class: "er" }, h("b", { text: label }), h("span", { text: value }));
  return h("div", { class: "example" }, h("div", { class: "ev", text: exampleCaption(item, lang) }),
    row(L.exWorry, worry), row(L.exWords, words), row(L.exReading, reading), row(L.exAction, action));
}

/** One handwritten line. Striking and restoring it again and again wears it away. */
function noteRow(note, onTap) {
  const words = h("div", { class: "words", text: note.text });
  const strike = h("div", { class: "strike", text: note.text });
  const smudge = h("div", { class: "smudge" });
  const rng = seeded(note.id);
  for (let i = 0; i < 5; i++) {
    const w = rng(25, 55), hh = rng(90, 160);
    smudge.append(h("i", { style: `width:${w}%;height:${hh}%;left:${rng(-5, 85) - w * 0.2}%;top:${rng(-30, 10)}%` }));
  }
  const row = h("div", { class: "note", onclick: onTap },
    h("div", { class: "body" }, h("div", { class: "ink" }, smudge, words, strike)), h("time", { text: shortTime(note.date) }));
  row.update = (n) => {
    const f = wear(n);
    words.style.color = `rgba(43, 41, 39, ${1 - 0.9 * f ** 0.8})`;
    // Browsers redraw any blurred text coarsely, so a near-zero blur already looks smudged.
    // Leave the words sharp until the blur is large enough to be seen, as on the iPhone.
    const blur = 4 * f ** 1.4;
    words.style.filter = blur >= 0.3 ? `blur(${blur.toFixed(2)}px)` : "none";
    smudge.style.opacity = n.strikes.length ? 0.15 + 0.8 * f ** 0.6 : 0;
    // A fresh pen line each time: never quite straight, never in quite the same place.
    const r = seeded(n.id, n.strikes.length);
    strike.style.transform = `translate(${r(-3, 3)}px, ${r(-1.5, 1.5)}px) rotate(${r(-1.2, 1.2)}deg)`;
    strike.style.opacity = isStruck(n) ? 1 : 0;
  };
  row.update(note);
  return row;
}

function strikeSheet(note, onConfirm) {
  const restoring = isStruck(note);
  return cover((close) => h("div", { class: "sheet" },
    h("h2", { text: restoring ? L.restoreTitle : L.strikeTitle }),
    h("p", { class: "quote", text: `「${note.text}」` }),
    h("p", { class: "faint small", text: restoring ? L.restoreBody : L.strikeBody }),
    h("div", { class: "buttons" }, button(L.leaveAsIs, close),
      button(restoring ? L.restore : L.strike, () => { close(); onConfirm(); }, true))));
}

/** The questions with everything written under each. Lines can be added any time and struck
 *  through (or restored) by tapping them, never edited or removed. */
function notesSection(entryID, kinds, { openFirst = false, onChange } = {}) {
  const el = h("div", { class: "notes" });
  let writing = null;
  let draft = "";
  const rows = new Map();

  const save = (kind) => {
    const entry = entryByID(entryID);
    if (entry && writeNote(entry, kind, draft)) { saveJournal(); onChange?.(); }
    draft = "";
    writing = null;
  };
  const open = (kind, focus = true) => {
    if (writing && writing !== kind && draft.trim()) save(writing);
    draft = "";
    writing = kind;
    render(focus);
  };
  const tap = (kind, note) => strikeSheet(note, () => {
    // Let the question fade away before the line changes underneath it.
    setTimeout(() => {
      const entry = entryByID(entryID);
      const n = entry && toggleStrike(entry, kind, note.id);
      if (!n) return;
      saveJournal();
      rows.get(n.id)?.update(n);
      onChange?.();
    }, FADE);
  });

  function render(focus = false) {
    const entry = entryByID(entryID);
    if (!entry) return;
    rows.clear();
    let input = null;
    el.replaceChildren(...clean([
      noteCount(entry) > 0 && h("div", { class: "hint", text: L.strikeHint }),
      ...kinds.map((kind) => {
        const lines = entry.notes[kind].map((n) => { const r = noteRow(n, () => tap(kind, n)); rows.set(n.id, r); return r; });
        let tail;
        if (writing === kind) {
          input = h("textarea", { rows: 1, placeholder: L.writePlaceholder });
          input.value = draft;
          const keep = button(L.keep, () => { save(kind); render(); });
          keep.disabled = !draft.trim();
          const grow = () => { input.style.height = "auto"; input.style.height = `${input.scrollHeight + 2}px`; };
          input.addEventListener("input", () => { draft = input.value; keep.disabled = !draft.trim(); grow(); });
          requestAnimationFrame(grow);
          tail = h("div", { class: "compose" }, input, keep);
        } else {
          tail = h("div", { class: "add" }, link(L.write, () => open(kind)));
        }
        return h("div", {}, h("p", { class: "q", text: L.question(kind, entry.topic) }), ...lines, tail);
      })]));
    if (focus && input) input.focus();
  }

  el.setKinds = (next) => {
    const grew = next.length > kinds.length;
    kinds = next;
    // When the next question appears, open it for writing straight away.
    if (openFirst && grew) open(kinds[kinds.length - 1]); else render();
  };
  // The first question is open from the start, but the keyboard waits for a tap: it must not
  // rise over the verse the moment the page turns.
  if (openFirst) open(kinds[0], false); else render();
  return el;
}

/** "Writings (n) ▾": folded by default so the page stays quiet. */
function notesDisclosure(entryID) {
  let expanded = false;
  const label = h("button", { class: "disclosure" });
  const body = slot();
  const refresh = () => {
    const entry = entryByID(entryID);
    label.replaceChildren(L.writings(entry ? noteCount(entry) : 0), h("i", { text: expanded ? "▲" : "▼" }));
  };
  const show = (animated) => {
    const entry = entryByID(entryID);
    const last = entry && lastWritten(entry);
    body.show(expanded ? notesSection(entryID, KINDS, { onChange: refresh })
      : h("div", { class: "tiny faint", text: last ? L.lastWritten(shortTime(last)) : "" }), animated);
  };
  label.onclick = () => { expanded = !expanded; refresh(); show(true); };
  refresh();
  show(false);
  return h("div", { class: "col", style: "gap:14px" }, h("div", {}, label), body);
}

/** One day's page, shared by today's verse at home and each page of the journal. */
function verseDay(title, entry, footer) {
  return h("div", { class: "scroll" }, h("div", { class: "col", style: "gap:18px;padding-bottom:12px" },
    h("div", { class: "day-head" }, h("span", { text: title }), h("span", { class: "tiny faint", text: [L.topic(entry.topic), L.openedAt(clock(entry.date))].filter(Boolean).join("　") })),
    versePage(entry.verse),
    notesDisclosure(entry.id),
    h("div", {}, link(L.share, () => shareSheet(entryByID(entry.id) ?? entry))),
    footer));
}

// --- Opening the book ---------------------------------------------------------------------------

const draw = { phase: "idle", topic: null, entryID: null, step: 0, showToday: false, error: false, gen: 0, idleKey: "" };
let drawSlot = null;

function idleKey() {
  const today = journal[0];
  if (remaining() > 0 && !pendingDraw() && today) return draw.showToday ? "today" : "closed";
  return remaining() > 0 && !pendingDraw() ? "wait" : "ready";
}

function renderDraw(animated = true) {
  if (!drawSlot) return;
  let view;
  if (draw.phase === "choosing") view = topicView();
  else if (draw.phase === "focusing") view = focusingView();
  else if (draw.phase === "revealed") view = revealedView();
  else {
    draw.idleKey = idleKey();
    view = { today: todayView, closed: closedView }[draw.idleKey]?.() ?? introView();
  }
  drawSlot.show(view, animated);
}

function introView() {
  const ready = draw.idleKey === "ready";
  return h("div", {}, stage(0,
    h("p", { class: "lede", text: L.intro }),
    ready ? button(L.openButton, choose, true) : countdown(),
    draw.error && h("p", { class: "tiny faint", style: "max-width:300px", text: L.loadFailed })));
}

/** The book is closed for today; its verse line surfaces gently on the mark. */
function closedView() {
  const view = h("div", {}, stage(0,
    h("p", { class: "lede", text: L.todayAlreadyOpen }),
    button(L.openToday, () => { draw.showToday = true; renderDraw(); }),
    countdown()));
  const line = view.querySelector(".mark-verse");
  setTimeout(() => { line.style.opacity = 1; }, 400);
  return view;
}

function todayView() {
  return verseDay(L.todayTitle, journal[0], h("div", { style: "text-align:center;padding-top:12px" }, countdown("tiny")));
}

function choose() {
  draw.phase = "choosing";
  renderDraw();
}

/** Naming what the dilemma is about, so there is something to hold in mind. The verse stays
 *  wholly random; the choice only names the dilemma in the questions. */
function topicView() {
  const chips = h("div", { class: "topics" },
    Object.keys(TOPICS).map((t) => h("button", { class: "topic", text: L.topic(t), onclick: () => begin(t) })));
  return h("div", {}, stage(0, h("p", { class: "lede", text: L.topicQuestion }), chips));
}

/** The pause before the page turns: the mark stays still; only its verse line surfaces. */
function focusingView() {
  const words = h("div", { class: "focus-words" }, h("span", { text: L.focusing(draw.topic) }), h("span", { text: L.focusingOpen }));
  const view = h("div", {}, stage(0, words));
  const line = view.querySelector(".mark-verse");
  line.style.transition = "opacity 5.5s ease-in-out 0.6s";
  const gen = draw.gen;
  requestAnimationFrame(() => requestAnimationFrame(() => { line.style.opacity = 1; }));
  setTimeout(() => { if (gen === draw.gen) words.children[0].classList.add("on"); }, 1000);
  setTimeout(() => { if (gen === draw.gen) { words.children[0].classList.remove("on"); words.children[1].classList.add("on"); } }, 4000);
  return view;
}

function revealedView() {
  const entry = entryByID(draw.entryID);
  const turn = h("div", { class: "turn" }, versePage(entry.verse));
  const steps = ["keyword", "interpretation", "action"];
  const notes = notesSection(entry.id, steps.slice(0, draw.step + 1), { openFirst: true });
  const controls = h("div", { class: "col", style: "gap:10px" });
  const renderControls = () => {
    controls.replaceChildren(...clean([
      h("div", { class: "row" },
        link(L.share, () => shareSheet(entryByID(entry.id))),
        h("span", { class: "spacer" }),
        draw.step < steps.length - 1 && button(L.next, () => {
          draw.step += 1;
          notes.setKinds(steps.slice(0, draw.step + 1));
          renderControls();
        }),
        button(L.done, finish, true)),
      draw.step === steps.length - 1 && h("div", { class: "tiny faint", style: "text-align:right", text: L.disclaimer })]));
  };
  renderControls();
  const others = h("div", { class: "col", style: "gap:12px" });
  others.append(link(L.showOthers, () => {
    others.classList.add("fade", "out");
    setTimeout(() => {
      others.replaceChildren(h("div", { class: "tiny faint", text: L.othersCaption }), ...EXAMPLES[lang].map(exampleCard));
      others.classList.remove("out");
    }, FADE / 2);
  }));
  others.firstChild.style.alignSelf = "flex-start";
  const rest = h("div", { class: "col fade out" }, h("div", { class: "col", style: "gap:14px" }, notes, controls), h("div", { class: "rule" }), others);
  const view = h("div", { class: "scroll" }, h("div", { class: "col", style: "padding-bottom:24px" }, turn, rest));
  if (draw.turned) { turn.classList.add("turned"); rest.classList.remove("out"); } else {
    draw.turned = true;
    requestAnimationFrame(() => requestAnimationFrame(() => turn.classList.add("turned")));
    setTimeout(() => rest.classList.remove("out"), 900);
  }
  return view;
}

async function begin(topic) {
  // Commit the draw before showing it, so leaving mid-way cannot be used to draw again.
  if (!pendingDraw()) {
    if (remaining() > 0) return;
    let index;
    try { index = await loadIndex(); } catch { draw.phase = "idle"; draw.error = true; renderDraw(false); return; }
    store.set(KEY.pending, String(randomIndex(drawable(index).length)));
    store.set(KEY.topic, topic);
    store.set(KEY.last, String(Date.now()));
  }
  draw.topic = store.get(KEY.topic) ?? topic;
  const gen = ++draw.gen;
  const started = Date.now();
  draw.error = false;
  draw.phase = "focusing";
  renderDraw();
  let entry;
  try { entry = await resolvePending(); } catch {
    if (gen !== draw.gen) return;
    draw.phase = "idle";
    draw.error = true;
    renderDraw();
    return;
  }
  // About six seconds of quiet before the page turns.
  await later(Math.max(0, 6500 - (Date.now() - started)));
  if (gen !== draw.gen) return;
  Object.assign(draw, { phase: "revealed", entryID: entry.id, step: 0, turned: false });
  renderDraw();
  navigator.vibrate?.(30);
}

function finish() {
  Object.assign(draw, { phase: "idle", entryID: null, showToday: false });
  renderDraw();
}

// --- Journal: a tear-off calendar ---------------------------------------------------------------

let recordIndex = 0;

function recordsView() {
  if (!journal.length) return h("div", { class: "empty", text: L.noRecords });
  recordIndex = Math.min(recordIndex, journal.length - 1);
  const pages = slot();
  const older = link(L.olderDay, () => turnTo(recordIndex + 1));
  const newer = link(L.newerDay, () => turnTo(recordIndex - 1));
  const count = h("span", { class: "tiny faint digits" });
  const show = (animated) => {
    const e = journal[recordIndex];
    pages.show(verseDay(longDate(e.date, lang), e, null), animated);
    older.disabled = recordIndex >= journal.length - 1;
    newer.disabled = recordIndex === 0;
    count.textContent = `${journal.length - recordIndex} / ${journal.length}`;
  };
  const turnTo = (i) => { if (i < 0 || i >= journal.length || i === recordIndex) return; recordIndex = i; show(true); };
  let start = null;
  pages.addEventListener("touchstart", (e) => { start = [e.touches[0].clientX, e.touches[0].clientY]; }, { passive: true });
  pages.addEventListener("touchend", (e) => {
    if (!start) return;
    const dx = e.changedTouches[0].clientX - start[0], dy = e.changedTouches[0].clientY - start[1];
    start = null;
    if (Math.abs(dx) < 60 || Math.abs(dx) < Math.abs(dy)) return;
    turnTo(recordIndex + (dx > 0 ? 1 : -1));
  });
  show(false);
  return h("div", { class: "records" }, pages, h("nav", {}, older, count, newer));
}

// --- Sharing: the verse (and optionally the reading) as an image -----------------------------------

const INK = "#2B2927", FAINT = "rgba(43, 41, 39, 0.55)", SHU = "#C64730", PAPER = "#F5F0E6";
const MINCHO = '"Hiragino Mincho ProN", "Yu Mincho", "YuMincho", "Noto Serif JP", serif';
const VERSE_FONT = `"Shippori Verse", ${MINCHO}`;

/** Breaks text into lines: Latin words stay whole, Japanese breaks between any characters,
 *  and closing punctuation never starts a line. */
function wrap(ctx, text, width) {
  const lines = [];
  for (const para of text.split("\n")) {
    const tokens = para.match(/[A-Za-z0-9’'“”",.;:!?()\-]+\s*|\s+|./gu) ?? [""];
    let line = "";
    for (const t of tokens) {
      if (line && ctx.measureText(line + t).width > width && !/^[、。，．」』）！？ー]/.test(t)) {
        lines.push(line.trimEnd());
        line = t.trimStart();
      } else line += t;
    }
    lines.push(line.trimEnd());
  }
  return lines;
}

async function shareImage(entry, includeReading) {
  const text = verseText(entry.verse, lang);
  await document.fonts.load(`20px "Shippori Verse"`, text).catch(() => {});
  const W = 360, S = 3, X = 32, inner = W - 64;
  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d");
  const ops = [];
  let y = 52;
  const textBlock = (str, font, size, lh, color, x, width, align = "left") => {
    ctx.font = `${size}px ${font}`;
    for (const line of wrap(ctx, str, width)) {
      const yy = y;
      ops.push(() => { ctx.font = `${size}px ${font}`; ctx.fillStyle = color; ctx.textAlign = align; ctx.fillText(line, align === "right" ? x + width : x, yy + size); });
      y += lh;
    }
  };
  textBlock(text, VERSE_FONT, 20, 34, INK, X, inner);
  y += 16;
  textBlock(reference(entry.verse, lang), MINCHO, 11, 16, FAINT, X, inner, "right");
  if (includeReading && hasReading(entry)) {
    y += 22;
    const top = y;
    const rows = [[L.exWords, "keyword"], [L.exReading, "interpretation"], [L.exAction, "action"], [L.exOutcome, "outcome"]]
      .filter(([, k]) => current(entry, k));
    rows.forEach(([label, k], i) => {
      if (i) y += 10;
      textBlock(label, MINCHO, 10, 14, SHU, X + 12, inner - 12);
      y += 3;
      textBlock(current(entry, k), MINCHO, 13, 20, INK, X + 12, inner - 12);
    });
    const bottom = y;
    ops.push(() => { ctx.fillStyle = SHU; ctx.fillRect(X, top, 2, bottom - top); });
  }
  y += 28;
  const footY = y;
  ops.push(() => {
    ctx.save();
    ctx.translate(X, footY);
    ctx.scale(18 / 1024, 18 / 1024);
    ctx.lineCap = ctx.lineJoin = "round";
    ctx.strokeStyle = INK;
    ctx.lineWidth = 36; ctx.stroke(new Path2D(OUTLINE));
    ctx.lineWidth = 10; ctx.stroke(new Path2D(INNER));
    ctx.strokeStyle = SHU; ctx.lineWidth = 22; ctx.stroke(new Path2D(VERSE));
    ctx.restore();
    ctx.font = `10px ${MINCHO}`; ctx.fillStyle = FAINT; ctx.textAlign = "left";
    ctx.fillText(`${L.tagline}｜${L.appName}`, X + 26, footY + 13);
  });
  y += 18 + 24;
  canvas.width = W * S;
  canvas.height = Math.ceil(y * S);
  ctx.scale(S, S);
  ctx.fillStyle = PAPER;
  ctx.fillRect(0, 0, W, y);
  ctx.fillStyle = SHU;
  ctx.fillRect(W - 28 - 6, 0, 6, 44);
  for (const op of ops) op();
  return canvas;
}

/** Shows the card before sharing, so the user sees exactly what leaves the device. */
function shareSheet(entry) {
  let include = true;
  let canvas = null;
  const img = h("img", { alt: "" });
  const refresh = async () => { canvas = await shareImage(entry, include); img.src = canvas.toDataURL("image/png"); };
  const send = () => canvas?.toBlob(async (blob) => {
    const file = new File([blob], "tsuji.png", { type: "image/png" });
    if (navigator.canShare?.({ files: [file] })) {
      try { await navigator.share({ files: [file] }); } catch { /* cancelled */ }
    } else {
      // Browsers without file sharing (most desktops) save the image instead.
      const a = h("a", { href: URL.createObjectURL(blob), download: "tsuji.png" });
      a.click();
      setTimeout(() => URL.revokeObjectURL(a.href), 10000);
    }
  }, "image/png");
  refresh();
  cover((close) => {
    const toggle = hasReading(entry) && h("label", {},
      h("input", { type: "checkbox", checked: true, onchange: (e) => { include = e.target.checked; refresh(); } }),
      L.shareIncludeReading);
    return h("div", { class: "share" }, h("h2", { text: L.shareTitle }), img, toggle,
      h("div", { class: "buttons" }, button(L.cancel, close), button(L.share, send, true)));
  });
}

// --- First-run guide ------------------------------------------------------------------------------

function guide() {
  cover((close) => h("div", { class: "guide" },
    h("div", { class: "scroll" },
      h("h1", { text: L.guideTitle }),
      h("div", { class: "poem" },
        h("p", { class: "waka", text: "言霊の　八十の衢に　夕占問ふ\n占正に告る　妹相寄らむ" }),
        h("div", { class: "tiny faint", text: L.poemSource }),
        h("p", { text: L.poemMeaning })),
      h("p", { text: L.guideHistory }),
      h("p", { text: L.guideBody }),
      h("h3", { text: L.guideExamples }),
      h("div", { class: "examples" }, EXAMPLES[lang].slice(0, 3).map(exampleCard))),
    h("div", { class: "end" }, button(L.guideStart, () => { store.set(KEY.guide, "1"); close(); }, true))));
}

// --- Shell: header, tabs, splash --------------------------------------------------------------------

const main = slot(document.getElementById("main"));
let tab = "draw";

function showTab(next, animated = true) {
  // Leaving the draw tab sets the ritual down: coming back starts from the home page.
  if (tab === "draw" && next !== "draw") { draw.gen++; Object.assign(draw, { phase: "idle", entryID: null, showToday: false }); }
  tab = next;
  for (const b of document.querySelectorAll("#tabs button")) b.classList.toggle("on", b.dataset.tab === tab);
  if (tab === "draw") { drawSlot = slot(); main.show(drawSlot, animated); renderDraw(false); } else { drawSlot = null; main.show(recordsView(), animated); }
}

function applyLanguage() {
  L = strings(lang);
  document.documentElement.lang = lang;
  document.title = `${L.tagline}｜${L.appName}`;
  document.getElementById("tagline").textContent = L.tagline;
  document.getElementById("appname").textContent = L.appName;
  document.getElementById("lang").textContent = L.langToggle;
  const [d, r] = document.querySelectorAll("#tabs button span");
  d.textContent = L.tabDraw;
  r.textContent = L.tabRecords;
}

document.getElementById("lang").onclick = () => {
  lang = lang === "ja" ? "en" : "ja";
  store.set(KEY.lang, lang);
  applyLanguage();
  if (tab === "draw") renderDraw(); else main.show(recordsView());
};
document.getElementById("help").onclick = guide;
for (const b of document.querySelectorAll("#tabs button")) b.onclick = () => { if (b.dataset.tab !== tab) showTab(b.dataset.tab); };

// Countdowns tick; when the day is up, the home page changes by itself.
setInterval(() => {
  for (const el of document.querySelectorAll(".countdown")) el.textContent = L.nextDraw(formatRemaining(remaining()));
  if (tab === "draw" && draw.phase === "idle" && idleKey() !== draw.idleKey) renderDraw();
}, 1000);

/** Title page: the mark, then the tagline, then the name. About 4.5 s; a tap skips it. */
async function splash() {
  const t1 = h("div", { class: "t1", text: L.tagline }), t2 = h("div", { class: "t2", text: L.appName });
  const el = h("div", { id: "splash" }, stage(0, t1, t2));
  let skip = false;
  el.onclick = () => { skip = true; };
  document.body.append(el);
  const loading = loadIndex().catch(() => {});
  setTimeout(() => t1.classList.add("on"), 600);
  setTimeout(() => t2.classList.add("on"), 1700);
  for (let i = 0; i < 45 && !skip; i++) await later(100);
  await loading;
  // A draw committed on an earlier visit but never shown (e.g. the page was closed) is recorded now.
  if (pendingDraw()) { try { await resolvePending(); } catch { /* retried from the home page */ } }
  el.classList.add("fade", "out");
  setTimeout(() => el.remove(), FADE);
}

applyLanguage();
showTab("draw", false);
splash().then(async () => {
  renderDraw(false);
  if (!store.get(KEY.guide)) { await later(1000); guide(); }
});
