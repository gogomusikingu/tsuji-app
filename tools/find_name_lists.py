"""List the verses that are nothing but strings of names (places, people, clans), so the
book never opens at one: "フムタ、キルヤテ・アルバ、すなわちヘブロン、およびツィオル。" gives a
reader nothing to bend to their dilemma. They stay in the text for "read around it".

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


if __name__ == "__main__":
    rows = [line.split("\t") for line in (RES / "bible.tsv").read_text(encoding="utf-8").splitlines()]
    hits = [r[:3] for r in rows if len(r) == 5 and is_name_list(r[3])]
    (RES / "name_lists.tsv").write_text("".join("\t".join(h) + "\n" for h in hits), encoding="utf-8")
    print(f"{len(hits)} of {len(rows)} verses are name lists")
