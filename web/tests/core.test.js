// Run with: node --test web/tests/*.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import {
  randomIndex, drawable, parseBook, context, formatRemaining, newEntry, writeNote, toggleStrike, isStruck,
  current, noteCount, hasReading, wear, seeded, strings, reference, EXAMPLES,
} from "../core.js";

const verse = { book: "GEN", chapter: 1, verse: 1, ja: "初めに", en: "In the beginning" };

test("randomIndex stays in range and reaches both ends", () => {
  const seen = new Set();
  for (let i = 0; i < 2000; i++) {
    const n = randomIndex(5);
    assert.ok(n >= 0 && n < 5);
    seen.add(n);
  }
  assert.equal(seen.size, 5);
});

test("drawable spans books and skips name lists", () => {
  const index = [["GEN", 3, [1]], ["EXO", 2, []]];
  assert.deepEqual(drawable(index), [["GEN", 0], ["GEN", 2], ["EXO", 0], ["EXO", 1]]);
});

test("context stays within the chapter", () => {
  const verses = parseBook("GEN", "1\t30\ta\tA\n1\t31\tb\tB\n2\t1\tc\tC\n2\t2\td\tD\n");
  assert.deepEqual(context(verses, verses[1], 2).map((v) => v.verse), [30, 31]);
  assert.deepEqual(context(verses, verses[2], 2).map((v) => v.verse), [1, 2]);
});

test("writing lines and striking them through", () => {
  const e = newEntry(verse, 0);
  assert.equal(writeNote(e, "keyword", "   "), false);
  writeNote(e, "keyword", " 光 ", 1);
  writeNote(e, "keyword", "闇", 2);
  assert.equal(noteCount(e), 2);
  assert.equal(current(e, "keyword"), "闇");
  const second = e.notes.keyword[1];
  toggleStrike(e, "keyword", second.id);
  assert.ok(isStruck(second));
  assert.equal(current(e, "keyword"), "光");
  toggleStrike(e, "keyword", second.id);
  assert.equal(current(e, "keyword"), "闇");
  assert.equal(second.strikes.length, 2);
  assert.ok(hasReading(e));
  assert.equal(noteCount(e), 2, "lines are never removed");
});

test("wear reaches 1 at the limit", () => {
  assert.equal(wear({ strikes: [] }), 0);
  assert.equal(wear({ strikes: Array(50).fill(0) }), 1);
  assert.equal(wear({ strikes: Array(80).fill(0) }), 1);
});

test("seeded random is repeatable", () => {
  const a = seeded("abc", 1), b = seeded("abc", 1), c = seeded("abc", 2);
  const x = a(0, 1);
  assert.equal(x, b(0, 1));
  assert.notEqual(x, c(0, 1));
});

test("countdown format", () => {
  assert.equal(formatRemaining(0), "0:00:00");
  assert.equal(formatRemaining(1), "0:00:01");
  assert.equal(formatRemaining(24 * 3600 * 1000), "24:00:00");
});

test("strings and references in both languages", () => {
  assert.equal(strings("ja").appName, "辻");
  assert.equal(strings("en").appName, "Tsuji");
  assert.equal(reference(verse, "ja"), "創世記 1章1節");
  assert.equal(reference(verse, "en"), "Genesis 1:1");
});

// Checks against the generated data, when it has been built (tools/build_web.py).
const dataDir = new URL("../data/", import.meta.url);
test("fixed examples quote the bundled text", { skip: !existsSync(new URL("index.json", dataDir)) }, () => {
  const codes = { "マタイによる福音書": "MAT", "ヨシュア記": "JOS", "エズラ記": "EZR", "レビ記": "LEV", "士師記": "JDG", "申命記": "DEU" };
  for (const [text, ref] of EXAMPLES.ja) {
    const [, name, ch, vs] = ref.match(/^(.+) (\d+)章(\d+)節$/);
    const book = parseBook(codes[name], readFileSync(new URL(`${codes[name]}.tsv`, dataDir), "utf8"));
    const v = book.find((x) => x.chapter === Number(ch) && x.verse === Number(vs));
    assert.equal(v.ja, text, ref);
  }
  const index = JSON.parse(readFileSync(new URL("index.json", dataDir), "utf8"));
  assert.equal(index.reduce((n, [, c]) => n + c, 0), 31098);
  // Joshua 15:54, a bare list of towns, is never drawn.
  const jos = parseBook("JOS", readFileSync(new URL("JOS.tsv", dataDir), "utf8"));
  const pos = jos.findIndex((v) => v.chapter === 15 && v.verse === 54);
  assert.ok(!drawable(index).some(([b, i]) => b === "JOS" && i === pos));
});
