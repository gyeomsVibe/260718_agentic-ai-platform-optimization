"""Fixed acceptance for v6.1.0: every tool's report shape ends a finished card with a plain core-summary line.

Receipt (2026-09-29): 윤겸스 reported the closing user summary asked for in v5.27.0 was not followed. The line had
been blurred into general Reporting wording and was absent from the report shape itself, so no tool wrote it.
"""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parent.parent
LINE = "`- **핵심요약**:`"
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


def communication(text: str) -> str:
    """The first Communication bullet: the report shape every tool renders."""
    section = text[text.index("## Communication\n"):]
    return next(line for line in section.splitlines() if line.startswith("- "))


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (6, 1, 0), f"VERSION must be at least 6.1.0, got {version}")
shape = communication(read("core.md"))
require(LINE in shape, "core report shape lacks the core-summary line")
# The summary closes finished work only; a mid-progress report must not grow a second summary.
require("finishes" in shape and "1–2 plain Korean sentences" in shape, "core-summary line lacks its trigger or size")
require("`- **핵심요약**: …`" in read("GLOBAL_RULES.ko.md"), "ko mirror lacks the core-summary line")
for dist in DISTS:
    text = read(dist)
    require(f"v{version}" in text, f"{dist} is stale: run sync-global-rules.ps1 -Mode Build")
    require(LINE in communication(text), f"{dist} report shape lacks the core-summary line")
require(len(read("dist/antigravity/GEMINI.md")) <= 11600, "dist/antigravity/GEMINI.md exceeds 11600 characters")

print("PASS v610_core_summary_check")
sys.exit(0)
