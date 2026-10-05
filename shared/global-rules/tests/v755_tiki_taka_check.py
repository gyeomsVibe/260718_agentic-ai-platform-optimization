"""Fixed acceptance for v7.5.5: tools talk through `uaos coord deliver` by tiki-taka in every generated rule file."""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
RULE = "Tools talk through `uaos coord deliver` by tiki-taka (≤5 evidence turns a decision; non-author judges)"
KO_RULE = "`uaos coord deliver`로 티키타카(한 결정당 증거 턴 최대 5회, 판정은 작성하지 않은 도구)"
MAX_DIST_BYTES = 15_000
MAX_GEMINI_CHARS = 13_500


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 5, 5), f"VERSION must be at least 7.5.5, got {version}")

for name in ("core.md",) + DISTS:
    require(read(name).count(RULE) == 1, f"{name} must state the tiki-taka rule exactly once")

require(KO_RULE in read("GLOBAL_RULES.ko.md"), "GLOBAL_RULES.ko.md must carry the Korean tiki-taka rule")

for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} bytes, over {MAX_DIST_BYTES}")
require(len(read("dist/antigravity/GEMINI.md")) <= MAX_GEMINI_CHARS, "GEMINI.md is over its character cap")

print("PASS: v7.5.5 tiki-taka rule")
