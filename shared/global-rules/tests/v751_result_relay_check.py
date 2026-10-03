"""Fixed acceptance for v7.5.1: a finished card writes its result in its own checkout and sends one RESULT line to the
user window, which batches the merges into one report.

Receipt (2026-10-03): 윤겸스 found hopping between card windows to merge hard (interim rule RESULT_RELAY.md); a grep
of these rules found 0 lines for it, and U132's card worktree could not write .coord/results/U132.md into the base
checkout (diet repository U135).
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
PHRASE = ("a finished card writes `.coord/results/<card>.md` in its own checkout and sends one RESULT line "
          "(card, PR url, mergeable, tests, blocker) to the user window, which batches merges into one report")
KO = "RESULT 한 줄(카드, PR 주소, 병합 가능 여부, 테스트, 막힘)을 사용자 대화창에 보내며"
# Same caps and reasons as v750_card_pipeline_check.py and v530_operate_first_check.py (v7.2.0 GEMINI cap).
MAX_DIST_BYTES = 15_000
MAX_GEMINI_CHARS = 13_500


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 5, 1), f"VERSION must be at least 7.5.1, got {version}")
for name in ("core.md",) + DISTS:
    text = read(name)
    require(text.count(PHRASE) == 1, f"{name} must state the RESULT relay once")
    windows = next((line for line in text.split("\n") if line.startswith("- Windows:")), "")
    require(PHRASE in windows, f"{name}: the RESULT relay belongs on the Windows line")
require(KO in read("GLOBAL_RULES.ko.md"), "GLOBAL_RULES.ko.md must carry the Korean RESULT relay")
for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} bytes, over {MAX_DIST_BYTES}")
gemini = len(read("dist/antigravity/GEMINI.md"))
require(gemini <= MAX_GEMINI_CHARS, f"dist/antigravity/GEMINI.md is {gemini} characters, over {MAX_GEMINI_CHARS}")
print("PASS v751 result relay")
