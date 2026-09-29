"""Fixed acceptance for v5.30.0 operate-first (use while fixing) rule."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parent.parent


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (5, 30, 0), f"VERSION must be at least 5.30.0, got {version}")
core = read("core.md")
mirror = read("GLOBAL_RULES.ko.md")
require(f"Canonical version: {version}" in mirror, "ko mirror Canonical version differs from VERSION")

# The rule's testable parts: a receipt is required, the recurrence threshold, one card with a reproducing test,
# and the park rule. Losing any of them lets development drift back without a real-use failure.
for phrase in ("Operate first", "real-use failure receipt", "`coord log --kind BLOCKED`", "seen twice, or once at P1",
               "one card with a reproducing test", "return to use", "park a fix that fails twice"):
    require(phrase in core, f"core lacks: {phrase}")
for phrase in ("먼저 쓰고 고칩니다", "실사용 실패 영수증", "두 번(P1은 한 번)", "재현 테스트가 있는 카드 하나", "보류"):
    require(phrase in mirror, f"ko mirror lacks: {phrase}")

# Every generated rule file must carry the rule (Build copies core into each tool's dist).
for dist in ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md"):
    require("Operate first" in read(dist), f"{dist} lacks the operate-first rule: run sync-global-rules.ps1 -Mode Build")
# Antigravity's global rule file limit (MaxCharacters in sync-global-rules.ps1).
require(len(read("dist/antigravity/GEMINI.md")) <= 11600, "dist/antigravity/GEMINI.md exceeds 11600 characters")

print("PASS v530_operate_first_check")
sys.exit(0)
