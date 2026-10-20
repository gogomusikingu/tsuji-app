"""Generate the web version's data files from the bundled Bible text.

Writes (all git-ignored, rebuilt on deploy):
  web/data/index.json        book codes and verse counts, in Bible order
  web/data/<BOOK>.tsv        chapter, verse, Japanese, English (one book per file,
                             so a draw only downloads the book it lands in)
  web/fonts/verse.woff2      Shippori Mincho cut down to the characters used in the
                             Bible text and the app (the full font is 8.6 MB)
  web/icon-*.png             home-screen icons resized from the iPhone app icon (Mac only;
                             the icons are committed, so the deploy does not need this step)

Usage: tools/.venv/bin/python tools/build_web.py
Needs fonttools and brotli (pip install fonttools brotli) for the font step.
"""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "Sources/RandomOracle/Resources"
WEB = ROOT / "web"


def build_data() -> set[str]:
    out = WEB / "data"
    out.mkdir(parents=True, exist_ok=True)
    books: dict[str, list[str]] = {}
    chars: set[str] = set()
    for line in (RES / "bible.tsv").read_text(encoding="utf-8").splitlines():
        f = line.split("\t")
        if len(f) != 5:
            continue
        book, ch, vs, ja, en = f
        books.setdefault(book, []).append("\t".join([ch, vs, ja, en]))
        chars.update(ja)
        chars.update(en)
    for book, rows in books.items():
        (out / f"{book}.tsv").write_text("\n".join(rows) + "\n", encoding="utf-8")
    index = [[book, len(rows)] for book, rows in books.items()]
    (out / "index.json").write_text(json.dumps(index), encoding="utf-8")
    print(f"data: {len(books)} books, {sum(n for _, n in index)} verses")
    return chars


def build_font(chars: set[str]) -> None:
    from fontTools import subset

    # Everything the app itself may set in the verse face (examples, labels).
    for path in WEB.glob("*.js"):
        chars.update(path.read_text(encoding="utf-8"))
    chars.update(chr(c) for c in range(0x20, 0x7F))
    chars = {c for c in chars if c.isprintable()}
    (WEB / "fonts").mkdir(exist_ok=True)
    out = WEB / "fonts/verse.woff2"
    options = subset.Options()
    options.flavor = "woff2"
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    font = subset.load_font(str(RES / "ShipporiMincho-Regular.ttf"), options)
    sub = subset.Subsetter(options)
    sub.populate(text="".join(chars))
    sub.subset(font)
    subset.save_font(font, str(out), options)
    # The font licence must travel with the font.
    (WEB / "fonts/OFL.txt").write_text((RES / "ShipporiMincho-OFL.txt").read_text(encoding="utf-8"), encoding="utf-8")
    print(f"font: {len(chars)} characters, {out.stat().st_size / 1e6:.2f} MB")


def build_icons() -> None:
    src = ROOT / "ios/Tsuji/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    if sys.platform != "darwin":
        return
    for size in (180, 192, 512):
        dst = WEB / f"icon-{size}.png"
        subprocess.run(["sips", "-z", str(size), str(size), str(src), "--out", str(dst)],
                       check=True, capture_output=True)
    print("icons: 180, 192, 512")


if __name__ == "__main__":
    build_font(build_data())
    build_icons()
