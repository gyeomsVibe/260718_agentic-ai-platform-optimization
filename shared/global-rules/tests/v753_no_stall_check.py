"""Fixed acceptance for v7.5.3: a blocked step never idles a tool; it is the everyday default, not a night mode.

Receipt (2026-10-04 22:18, diet repository coord log 20261004T2218-claude-0001): the U157L commit gate needed an
answered Antigravity audit, the U120 auto-reply daily cap was spent, and nothing re-sent the letter after midnight, so
all three tools waited on a sleeping user. 윤겸스 ordered (22:20, restated 22:50) that no tool stalls on one blocked step.
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
PHRASE = "A blocked step idles no tool: log `BLOCKED`, wake at its reset, take the next ready card."
STOP = "every safe route and ready card blocked"
KO = "막힌 단계 하나로 어떤 도구도 놀지 않습니다"
# Same caps and reasons as v751_result_relay_check.py (v7.2.0 GEMINI cap).
MAX_DIST_BYTES = 15_000
MAX_GEMINI_CHARS = 13_500


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 5, 3), f"VERSION must be at least 7.5.3, got {version}")
for name in ("core.md",) + DISTS:
    text = read(name)
    require(text.count(PHRASE) == 1, f"{name} must state the no-stall rule once")
    line = next((ln for ln in text.split("\n") if ln.startswith("- Before ending, run a terminal check.")), "")
    require(PHRASE in line and STOP in line, f"{name}: the no-stall rule belongs on the Autonomy terminal-check line")
    require("night" not in line.lower() and "unattended" not in line.lower(),
            f"{name}: the rule is the everyday default, not a night or unattended mode")
require(KO in read("GLOBAL_RULES.ko.md"), "GLOBAL_RULES.ko.md must carry the Korean no-stall rule")
for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} bytes, over {MAX_DIST_BYTES}")
gemini = len(read("dist/antigravity/GEMINI.md"))
require(gemini <= MAX_GEMINI_CHARS, f"dist/antigravity/GEMINI.md is {gemini} characters, over {MAX_GEMINI_CHARS}")
print("PASS v753 no stall")
