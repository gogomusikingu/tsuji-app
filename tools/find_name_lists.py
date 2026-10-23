"""List the verses that give a reader nothing to bend to their dilemma, so the book never opens
at one. They stay in the text for "read around it". Four kinds:
  - bare strings of names: "フムタ、キルヤテ・アルバ、すなわちヘブロン、およびツィオル。"
  - genealogies: "ユダとタマルの間にペレツとゼラが生まれ、ペレツにヘツロンが生まれ、…"
  - census counts: "パロシュの子らは二千百七十二人。"
  - measurements and offering tallies: "一枚の幕の長さは二十八キュビト、幅は四キュビトとし、…"

Writes Sources/RandomOracle/Resources/name_lists.tsv (book, chapter, verse).
Usage: python3 tools/find_name_lists.py
"""

import re
from pathlib import Path

RES = Path(__file__).resolve().parent.parent / "Sources/RandomOracle/Resources"

NAME = re.compile(r"[ァ-ヶー][ァ-ヶー・]*")
# Words that only tie names together in such lists ("the sons of", "and", "nine cities").
FILLER = re.compile(
    r"その子ら?|の子ら?|子ら|および|すなわち|また|その村々|村々|[一二三四五六七八九十百]+つ?の町|の家系では|家系|氏族|出身"
    r"|の人々|人々|の父|長子|次に|であった|である|[人のはとらでにがも]")


NUMBER = r"[〇一二三四五六七八九十百千万]+"
KANA = r"[ァ-ヶー・]+"
# "AにBが生まれ", "AはBの父とな(った)", "AはBの子," : one link of a family line.
BIRTH = re.compile(
    rf"{KANA}(?:には|に){KANA}(?:と{KANA})*(?:とその兄弟たち)?が生まれ|{KANA}の父とな|{KANA}は{KANA}の子(?=[、。，]|$)")
CENSUS = re.compile(
    rf"^[^「]{{0,40}}?(?:の子ら|の子孫|の人々|部族から数えられた者|数えられた者)[はがの、]*(?:全部で)?{NUMBER}人(?:であった)?。?$")
MEASURE = re.compile(rf"{NUMBER}(?:キュビト|シェケル|ゲラ|エファ|ホメル|オメル|ヒン|タラント|ミナ|竿|手幅|頭)")


def kind(segment: str) -> str:
    rest = FILLER.sub("", NAME.sub("", segment))
    if len(rest) > 1:
        return "text"
    return "name" if NAME.search(segment) else "filler"


def is_name_list(ja: str) -> bool:
    if "「" in ja:  # someone speaks: there is something to read
        return False
    kinds = [kind(s.strip()) for s in re.split(r"[、。，]", ja) if s.strip()]
    names, text = kinds.count("name"), kinds.count("text")
    return names >= 3 and names / (names + text) >= 0.7


def is_genealogy(ja: str) -> bool:
    return "「" not in ja and len(BIRTH.findall(ja)) >= 2


def is_census(ja: str) -> bool:
    return bool(CENSUS.match(ja))


def is_measurements(ja: str) -> bool:
    """Most clauses are a number with a unit. A story that mentions a few oxen stays."""
    if "「" in ja:
        return False
    clauses = [c for c in re.split(r"[、。，]", ja) if c.strip()]
    measured = sum(1 for c in clauses if MEASURE.search(c))
    return measured >= 2 and measured / len(clauses) >= 0.6


def is_unreadable(ja: str) -> bool:
    return is_name_list(ja) or is_genealogy(ja) or is_census(ja) or is_measurements(ja)


if __name__ == "__main__":
    rows = [line.split("\t") for line in (RES / "bible.tsv").read_text(encoding="utf-8").splitlines()]
    hits = [r[:3] for r in rows if len(r) == 5 and is_unreadable(r[3])]
    (RES / "name_lists.tsv").write_text("".join("\t".join(h) + "\n" for h in hits), encoding="utf-8")
    print(f"{len(hits)} of {len(rows)} verses have nothing to read")
