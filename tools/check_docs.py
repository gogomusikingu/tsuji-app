#!/usr/bin/env python3
"""Check a project's markdown layout: size limits, pointers between files, and the section-number map.

Usage:
    python3 check_docs.py [project_dir]          check one project (default: current directory)
    python3 check_docs.py --shared path/CLAUDE.md  check only the size of a shared CLAUDE.md

Exit status is 1 when at least one error is found, 0 otherwise (warnings do not fail).
Messages are printed in Japanese, one finding per line, so the output can be handed back as is.
Only the standard library is used.
"""
import re
import sys
from pathlib import Path
from urllib.parse import unquote

# (max lines, max characters). Characters, not bytes: Japanese takes 3 bytes per character.
LIMIT_CLAUDE = (100, 6000)
LIMIT_ENTRY = (200, 12000)  # specification.md, TODO.md
LIMIT_CHAPTER = (200, 12000)  # files under spec/ (a warning only)

SPEC_DIR = "spec"
PLAN_DIR = "計画"
HISTORY_DIR = "履歴"  # spec/履歴/: no limits, not followed, may hold stale pointers
SECTION_MAP = "章番号.md"  # spec/章番号.md: | section number | file |
ARCHIVE_MARK = "整理前"  # spec/履歴/*整理前*.md: the specification as it was before the split

SKIP_DIRS = {".git", ".venv", "venv", "node_modules", "vendor", "wip", "__pycache__", ".pytest_cache", "dist",
             "build", ".claude", ".godot", "export", "00 Share"}
CODE_SUFFIXES = {".py", ".js", ".ts", ".sh", ".html", ".command", ".gd"}

LINK = re.compile(r"\]\(([^)#]+?\.md)(?:#[^)]*)?\)")
BARE = re.compile(r"[^\s`()\[\]「」（）、。|:：→<>\"'*]+\.md")
HEADING_NUMBER = re.compile(r"^#{1,6}\s+(\d+(?:\.\d+)*[a-z]?)(?=[.\s])")
MAP_ROW = re.compile(r"^\|\s*(\d+(?:\.\d+)*[a-z]?)\s*\|\s*([^|]+?)\s*\|")
CODE_CITATION = re.compile(r"[sS]pecification\.md[\s,:§]*(\d+(?:\.\d+)+[a-z]?)")


class Report:
    def __init__(self):
        self.errors, self.warnings = [], []

    def error(self, text):
        self.errors.append(text)

    def warn(self, text):
        self.warnings.append(text)

    def show(self):
        for e in self.errors:
            print(f"[エラー] {e}")
        for w in self.warnings:
            print(f"[警告] {w}")
        print(f"結果: エラー {len(self.errors)} 件、警告 {len(self.warnings)} 件")
        return 1 if self.errors else 0


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def check_size(path: Path, name: str, limit, report: Report, warn_only=False):
    text = read(path)
    lines, chars = len(text.splitlines()), len(text)
    say = report.warn if warn_only else report.error
    word = "目安" if warn_only else "上限"
    if lines > limit[0]:
        say(f"{name}: {lines} 行（{word} {limit[0]} 行）。テーマごとに分けるか、経緯を {SPEC_DIR}/{HISTORY_DIR}/ へ移す")
    if chars > limit[1]:
        say(f"{name}: {chars:,} 字（{word} {limit[1]:,} 字）。1 行が長すぎないかも確かめる")


def find_ci(root: Path, name: str):
    """A file in root whose name matches without regard to case (maneroku has Specification.md)."""
    for p in sorted(root.iterdir()):
        if p.is_file() and p.name.lower() == name.lower():
            return p
    return None


def md_under(folder: Path):
    if not folder.is_dir():
        return []
    return sorted(p for p in folder.rglob("*.md") if not (set(p.relative_to(folder).parts[:-1]) & SKIP_DIRS))


def in_history(path: Path, root: Path) -> bool:
    return HISTORY_DIR in path.relative_to(root).parts[:-1]


def pointers(path: Path, root: Path):
    """(text as written, resolved path or None) for every .md file named in path. Paths outside the project,
    URLs and patterns are left out."""
    text = read(path)
    found = [unquote(m) for m in LINK.findall(text)] + BARE.findall(text)
    out, seen = [], set()
    for raw in found:
        ref = raw.strip().lstrip("（(「")
        if ref.startswith("./"):
            ref = ref[2:]
        if not ref or ref in seen:
            continue
        seen.add(ref)
        if ref.startswith(("/", "~", "..")) or "://" in ref or "*" in ref or "$" in ref:
            continue
        if ref.split("/")[0] in SKIP_DIRS:  # vendor/, wip/ and the like: not tracked, may be absent
            continue
        hit = None
        for base in (path.parent, root):
            cand = base / ref
            if cand.is_file():
                hit = cand.resolve()
                break
        if hit is None and "/" not in ref:
            # a bare file name such as "specification.md" in prose: accept it when any tracked doc has that name
            same = [p for p in md_under(root) if p.name.lower() == ref.lower()]
            if same:
                hit = same[0].resolve()
        out.append((ref, hit))
    return out


def check_pointers(root: Path, entries, report: Report):
    """Dead pointers in the live docs, and files under spec/ and 計画/ that no entry file leads to."""
    tracked = [p for d in (SPEC_DIR, PLAN_DIR) for p in md_under(root / d) if not in_history(p, root)]
    live = {p.resolve() for p in tracked} | {p.resolve() for p in entries}
    reached, queue = set(), [p.resolve() for p in entries]
    while queue:
        cur = queue.pop()
        if cur in reached:
            continue
        reached.add(cur)
        for ref, hit in pointers(cur, root):
            if hit is None:
                # a bare name with no folder is often prose ("changelog.md は作らない"), so it only warns
                say = report.error if "/" in ref else report.warn
                say(f"{cur.relative_to(root.resolve())}: 案内先 {ref} が見つからない")
            elif hit in live and hit not in reached:
                queue.append(hit)
    for p in tracked:
        if p.resolve() not in reached:
            report.error(f"{p.relative_to(root)}: どの案内からもたどれない（CLAUDE.md・specification.md・"
                         f"フォルダの目次のどれかに「いつ読むか」つきで書く）")


def headings(path: Path):
    return [m.group(1) for line in read(path).splitlines() if (m := HEADING_NUMBER.match(line))]


def check_sections(root: Path, report: Report):
    """Section numbers must survive the split: code and other documents cite them."""
    history = root / SPEC_DIR / HISTORY_DIR
    archives = [p for p in md_under(history) if ARCHIVE_MARK in p.name]
    map_path = root / SPEC_DIR / SECTION_MAP
    if not map_path.is_file():
        if archives:
            report.error(f"{SPEC_DIR}/{SECTION_MAP} が無い（整理前の章番号 → 今のファイル の対応表。"
                         f"形: | 2.28 | spec/怪獣型.md |）")
        return
    table = {}
    for line in read(map_path).splitlines():
        m = MAP_ROW.match(line)
        if m:
            table[m.group(1)] = m.group(2).strip().strip("`")
    for number, target in table.items():
        if not (root / target).is_file():
            report.error(f"{SPEC_DIR}/{SECTION_MAP}: {number} の行き先 {target} が見つからない")
    for archive in archives:
        for number in headings(archive):
            if number not in table:
                report.error(f"{SPEC_DIR}/{SECTION_MAP}: 整理前の章 {number} が対応表に無い"
                             f"（{archive.relative_to(root)} にある）")
    for p in sorted(root.rglob("*")):
        if not p.is_file() or p.suffix not in CODE_SUFFIXES or set(p.relative_to(root).parts[:-1]) & SKIP_DIRS:
            continue
        for number in sorted(set(CODE_CITATION.findall(read(p)))):
            if number not in table:
                report.error(f"{p.relative_to(root)}: 引用している章 {number} が {SPEC_DIR}/{SECTION_MAP} に無い")


def check_project(root: Path) -> Report:
    report = Report()
    claude = find_ci(root, "CLAUDE.md")
    spec = find_ci(root, "specification.md")
    todo = find_ci(root, "TODO.md")
    if claude is None:
        report.error("CLAUDE.md が無い")
    else:
        check_size(claude, claude.name, LIMIT_CLAUDE, report)
    if spec is None:
        report.error("specification.md が無い")
    else:
        check_size(spec, spec.name, LIMIT_ENTRY, report)
    if todo is not None:
        check_size(todo, todo.name, LIMIT_ENTRY, report)
    for d in (SPEC_DIR, PLAN_DIR):
        for p in md_under(root / d):
            if not in_history(p, root):
                check_size(p, str(p.relative_to(root)), LIMIT_CHAPTER, report, warn_only=True)
    entries = [p for p in (claude, spec, todo) if p is not None]
    check_pointers(root, entries, report)
    check_sections(root, report)
    return report


def main(argv):
    if len(argv) >= 2 and argv[0] == "--shared":
        report = Report()
        path = Path(argv[1])
        check_size(path, path.name, LIMIT_CLAUDE, report)
        return report.show()
    root = Path(argv[0]) if argv else Path.cwd()
    if not root.is_dir():
        print(f"[エラー] フォルダが無い: {root}")
        return 1
    return check_project(root).show()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
