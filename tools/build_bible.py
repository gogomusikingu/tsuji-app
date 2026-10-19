"""Build the bundled parallel Bible (Japanese / English) from eBible.org VPL files.

Usage: python3 -I tools/build_bible.py <jpnm_vpl.txt> <engwebp_vpl.txt> <out.tsv>

Sources (both Public Domain, from https://ebible.org):
  - jpnm:    Japanese Freedom Bible
  - engwebp: World English Bible
Output columns: book code, chapter, verse, Japanese text, English text.
Verses empty in either translation are skipped.
"""
import re
import sys

LINE = re.compile(r"^(\w{3}) (\d+):(\d+) ?(.*)$")


def load(path):
    verses = []
    with open(path, encoding="utf-8") as f:
        for raw in f:
            m = LINE.match(raw.rstrip("\n"))
            if not m:
                raise ValueError(f"unexpected line in {path}: {raw!r}")
            book, ch, vs, text = m.groups()
            verses.append(((book, int(ch), int(vs)), " ".join(text.split())))
    return verses


def main():
    ja_path, en_path, out_path = sys.argv[1:4]
    ja, en = load(ja_path), load(en_path)
    if [k for k, _ in ja] != [k for k, _ in en]:
        raise ValueError("verse keys do not line up between translations")
    count = 0
    with open(out_path, "w", encoding="utf-8") as out:
        for ((book, ch, vs), ja_text), (_, en_text) in zip(ja, en):
            if not ja_text or not en_text:
                continue
            out.write(f"{book}\t{ch}\t{vs}\t{ja_text}\t{en_text}\n")
            count += 1
    print(f"wrote {count} verses to {out_path}")


if __name__ == "__main__":
    main()
