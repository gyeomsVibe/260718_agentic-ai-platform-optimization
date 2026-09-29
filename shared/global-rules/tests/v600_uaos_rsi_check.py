"""Fixed acceptance for v6.0.0: UAOS-RSI is the base operating system in every tool's global rules."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parent.parent
TOOLS = {  # dist file -> the adapter heading that must be the only one in it
    "dist/claude/CLAUDE.md": "## Claude Code adapter",
    "dist/codex/AGENTS.md": "## Codex adapter",
    "dist/antigravity/GEMINI.md": "## Antigravity adapter",
}


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (6, 0, 0), f"VERSION must be at least 6.0.0, got {version}")
core = read("core.md")
mirror = read("GLOBAL_RULES.ko.md")
require(f"> Canonical version: {version}" in mirror, "ko mirror version drift")

# The OS comes first: its title and its section precede Communication, the first behaviour section.
require(core.startswith("# UAOS-RSI "), "core title is not UAOS-RSI")
require(0 < core.index("## UAOS-RSI\n") < core.index("## Communication"), "## UAOS-RSI must come before ## Communication")
for phrase in ("default operating system of every agentic AI environment", "Operate first", "Card loop:",
               "runtime reinstall", "Authority:", "fails closed", "Budget:", "never convert a remaining-quota",
               "Self-improvement makes evidence only", "never auto-merge", "Evaluators", "No paid cron or polling"):
    require(phrase in core, f"core lacks: {phrase}")
# One writer: the stale installer block is gone from the canon (the generator owns the home rule files, U65-G).
require("UAOS:BEGIN" not in core, "core still embeds the installer's UAOS block")
for phrase in ("## UAOS-RSI", "기본 운영체제", "카드 순환", "예산:", "먼저 쓰고 고칩니다"):
    require(phrase in mirror, f"ko mirror lacks: {phrase}")

# Each tool's own role and budget, and only its own adapter, reach its generated rule file.
for dist, heading in TOOLS.items():
    text = read(dist)
    require(f"v{version}" in text, f"{dist} is stale: run sync-global-rules.ps1 -Mode Build")
    require("## UAOS-RSI\n" in text, f"{dist} lacks the UAOS-RSI section")
    tail = text[text.index(heading):]
    require(tail.count("- UAOS-RSI role:") == 1 and tail.count("- UAOS-RSI budget:") == 1,
            f"{dist} lacks exactly one role and one budget line in {heading}")
    for other in set(TOOLS.values()) - {heading}:
        require(other not in text, f"{dist} carries another tool's adapter: {other}")
require(len(read("dist/antigravity/GEMINI.md")) <= 11600, "dist/antigravity/GEMINI.md exceeds 11600 characters")

print("PASS v600_uaos_rsi_check")
sys.exit(0)
