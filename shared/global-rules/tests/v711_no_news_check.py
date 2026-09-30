"""Fixed acceptance for v7.1.1: a turn with nothing new gets one line, never a second `결과`.

Receipt (2026-09-30): 윤겸스 showed a screen where a watch wake-up turn repeated the previous turn's `결과` and
`남은 일`, and reported the same in all three tools. "One line for no change" was read inside one report only.
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
NO_NEWS = "No news: one line, never a second `결과`"
WAKES = "log `verdict_requested=no`, wakes, liveness"


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


def communication(text: str) -> str:
    section = text[text.index("## Communication\n"):]
    return next(line for line in section.splitlines() if line.startswith("- "))


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 1, 1), f"VERSION must be at least 7.1.1, got {version}")
for name in ("core.md",) + DISTS:
    text = read(name)
    require(NO_NEWS in communication(text), f"{name} report shape lacks the no-news rule")
    require("One line for no change" not in text, f"{name} still carries the ambiguous per-report wording")
    require(WAKES in text, f"{name} relay line does not log wake-ups silently")
mirror = read("GLOBAL_RULES.ko.md")
require("새 소식이 없는 턴(깨움·전달)은 한 줄이고 `결과`를 다시 쓰지 않습니다" in mirror, "ko mirror lacks the no-news rule")
require("`verdict_requested=no`·깨움·" in mirror, "ko mirror relay line lacks wake-ups")
for dist in DISTS:
    require(f"v{version}" in read(dist), f"{dist} is stale: run sync-global-rules.ps1 -Mode Build")
require(len(read("dist/antigravity/GEMINI.md")) <= 13500, "dist/antigravity/GEMINI.md exceeds 13500 characters")  # v7.2.0 cap (윤겸스 2026-09-30: 제한선을 여유있게)

print("PASS v711_no_news_check")
sys.exit(0)
