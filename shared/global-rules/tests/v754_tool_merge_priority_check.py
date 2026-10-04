"""Fixed acceptance for v7.5.4: PR merge is automated by tool priority (1. Antigravity, 2. Codex), never waiting on human merge."""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
MERGE_RULE = "tool merge (priority: 1. Antigravity, 2. Codex; never wait for user)"
AUTONOMY_RULE = "PR merge (priority: 1. Antigravity, 2. Codex)"
KO_RULE = "도구 자동 병합(우선순위: 1순위 Antigravity, 2순위 Codex; 게이트 통과 후 사람 대기 없이 자동 완결)"
MAX_DIST_BYTES = 15_000
MAX_GEMINI_CHARS = 13_500


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 5, 4), f"VERSION must be at least 7.5.4, got {version}")

for name in ("core.md",) + DISTS:
    text = read(name)
    require(MERGE_RULE in text, f"{name} must state tool merge rule in card loop")
    require(AUTONOMY_RULE in text, f"{name} must state tool merge priority in autonomy")

require(KO_RULE in read("GLOBAL_RULES.ko.md"), "GLOBAL_RULES.ko.md must carry the Korean tool merge rule")

for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} bytes, over {MAX_DIST_BYTES}")

gemini = len(read("dist/antigravity/GEMINI.md"))
require(gemini <= MAX_GEMINI_CHARS, f"dist/antigravity/GEMINI.md is {gemini} characters, over {MAX_GEMINI_CHARS}")

print("PASS v754 tool merge priority")
