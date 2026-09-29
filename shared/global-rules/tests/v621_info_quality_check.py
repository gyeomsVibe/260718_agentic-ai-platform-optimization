"""Fixed acceptance for v6.2.1: the report rule states its goal as information quality, not length.

Receipt (2026-09-29): 윤겸스 asked to check that a Data Optimization Expert principle — raise information quality,
not just cut text — is built into the three tools' rules. v6.2.0 carried it only as a list of what not to cut.
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
GOAL = "Optimize information quality, not length"
QUALITY = "specific and decision-relevant"


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
require(tuple(int(p) for p in version.split(".")) >= (6, 2, 1), f"VERSION must be at least 6.2.1, got {version}")
for name in ("core.md",) + DISTS:
    shape = communication(read(name))
    require(GOAL in shape and QUALITY in shape, f"{name} report shape lacks the information-quality goal")
    # The goal governs the cutting rule, so it must come before it.
    require(shape.index(GOAL) < shape.index("cut words, never facts"), f"{name}: goal must precede the cut rule")
# Verified vs unknown already lives in Reporting; the shape must not repeat it (each fact once applies to rules too).
require("Separate verified facts, assumptions, and unknowns" in read("core.md"), "Reporting lost verified/unknown split")
require("목표는 길이가 아니라 정보의 질" in read("GLOBAL_RULES.ko.md"), "ko mirror lacks the information-quality goal")
for dist in DISTS:
    require(f"v{version}" in read(dist), f"{dist} is stale: run sync-global-rules.ps1 -Mode Build")
require(len(read("dist/antigravity/GEMINI.md")) <= 11600, "dist/antigravity/GEMINI.md exceeds 11600 characters")

print("PASS v621_info_quality_check")
sys.exit(0)
