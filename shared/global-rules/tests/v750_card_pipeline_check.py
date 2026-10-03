"""Fixed acceptance for v7.5.0: every card opens from one four-stage template whose default workers are Ollama and
Antigravity, and `uaos card audit` gates the commit and `rsi ship` on their use.

Receipt (2026-10-02): the U129 card window used Antigravity but made 0 Ollama calls and the ledger had 0 U129 rows,
so non-use was invisible; the delegate-first rule lived only in the Claude adapter (diet repository U130, docs/67).
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
CORE_TERMS = ("`uaos card new`", "research → decide → execute → verify", "Ollama first, Antigravity audits and reviews",
              "`uaos card audit`", "gates commit and `rsi ship`", "`card skip`")
CODEX_ORDER = "implementation goes to Ollama, Antigravity, Claude Code, or `worker: apply`"
AGY_ROLE = "research and design auditor"
OLD_CLAUDE_ROUTE = "send code over 20 lines to Ollama or Antigravity first"
KO = "`uaos card new` 매뉴얼(조사 → 판단 → 실행 → 검증 네 칸"
# Same cap and reason as v720_quiet_output_check.py (Codex's 32 KiB shared AGENTS.md budget).
MAX_DIST_BYTES = 15_000


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 5, 0), f"VERSION must be at least 7.5.0, got {version}")
for name in ("core.md",) + DISTS:
    text = read(name)
    for term in CORE_TERMS:
        require(text.count(term) == 1, f"{name} must state once: {term}")
require(CODEX_ORDER in read("adapters/codex.md") and CODEX_ORDER in read("dist/codex/AGENTS.md"),
        "the Codex adapter must route implementation Ollama -> Antigravity -> Claude Code -> apply")
require(AGY_ROLE in read("adapters/antigravity.md") and AGY_ROLE in read("dist/antigravity/GEMINI.md"),
        "the Antigravity adapter must own the research/design audit and review slots")
require(OLD_CLAUDE_ROUTE not in read("adapters/claude.md"), "the Claude adapter still owns the shared delegate route")
require(KO in read("GLOBAL_RULES.ko.md"), "GLOBAL_RULES.ko.md must carry the Korean card loop")
for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} bytes, over {MAX_DIST_BYTES}")
print("PASS v750 card pipeline")
