"""Fixed acceptance for v7.3.0: UAOS-RSI changes are built for all three tools and any project, and a relay counts as
delivered only when the receiver's own hook shows it.

Receipt (2026-10-01): 윤겸스 twice had to paste a status line from Claude into Antigravity. Claude's own-letter fix
had first landed for Claude only, and the verdict letter to Antigravity never showed in Antigravity's hook (it listed
the five oldest of twelve letters by name). 윤겸스: "3대 도구 공통 … 범용이 기본 로직이다 … 전역 규칙으로 영구 고정".
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
UNIVERSAL = "Universal by default: UAOS-RSI runs every project and all three tools."
RECEIVER = "delivered only once the receiver's own hook output shows it"
KO = "범용이 기본입니다(Universal by default)"
# Same cap and reason as v720_quiet_output_check.py (Codex's 32 KiB shared AGENTS.md budget).
MAX_DIST_BYTES = 15_000


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 3, 0), f"VERSION must be at least 7.3.0, got {version}")
for name in ("core.md",) + DISTS:
    text = read(name)
    uaos = text[text.index("## UAOS-RSI\n"):]
    uaos = uaos[:uaos.find("\n## ", 1)]
    for phrase in (UNIVERSAL, RECEIVER):
        require(uaos.count(phrase) == 1, f"{name} UAOS-RSI section must state once: {phrase}")
for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} B > {MAX_DIST_BYTES} B cap")
require(KO in read("GLOBAL_RULES.ko.md"), "Korean mirror lacks the universal rule")
print("PASS v7.3.0 universal OS")
