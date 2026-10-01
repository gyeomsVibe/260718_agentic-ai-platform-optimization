"""Fixed acceptance for v7.4.0: the user's thread stays the user's, and each card runs in its own named window per tool.

Receipt (2026-10-01): 윤겸스 asked for Codex's habit, a lone user thread plus one "[U##] ..." thread per process, in all
three tools, and then to confirm it is fixed in the global rules. The runtime command shipped in diet U114 (PR #85).
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
WINDOWS = "- Windows: the user's thread stays the user's; each card runs in its own named window per tool"
COMMAND = "`uaos coord window --card U## --tool <tool>`"
KO = "사용자 대화창은 사용자 전용입니다"
# Same cap and reason as v720_quiet_output_check.py (Codex's 32 KiB shared AGENTS.md budget).
MAX_DIST_BYTES = 15_000


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 4, 0), f"VERSION must be at least 7.4.0, got {version}")
for name in ("core.md",) + DISTS:
    text = read(name)
    uaos = text[text.index("## UAOS-RSI\n"):]
    uaos = uaos[:uaos.find("\n## ", 1)]
    for phrase in (WINDOWS, COMMAND):
        require(uaos.count(phrase) == 1, f"{name} UAOS-RSI section must state once: {phrase}")
for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} B > {MAX_DIST_BYTES} B cap")
require(KO in read("GLOBAL_RULES.ko.md"), "Korean mirror lacks the windows rule")
print("PASS v7.4.0 card windows")
