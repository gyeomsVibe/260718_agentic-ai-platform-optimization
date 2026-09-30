"""Fixed acceptance for v7.2.0: progress between tool calls is quiet Korean, the final report is the one summary,
code goes to Ollama or Antigravity first, and every deployed rule file stays under a size cap with margin.

Receipt (2026-09-30): 윤겸스 showed a Claude Code screen where every step between tool calls printed an English
progress sentence and the last message did not say what comes next ("출력양식이 이게 뭐니? … 다음에 어떻게 하라는거니?").
The rule for progress lines lived only in the Claude adapter, so Codex and Antigravity never read it, and the same
adapter still called `worker: apply` the 0-token default, which the U98-D ledger (174 apply rows against 31
delegate rows) shows steered code away from Ollama and Antigravity.
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
PROGRESS = "Between tool calls stay silent by default"
PROGRESS_DETAIL = "never one per command and never English to 윤겸스"
FINAL = "The final report is the only summary"
NEXT = "`- 다음:`"
OLD_ADAPTER_PROGRESS = "Between tool calls, write one short Korean line"
OLD_APPLY_DEFAULT = "`worker: apply` (0 paid tokens) or a contracted worker"
DELEGATE_FIRST = "Ollama or Antigravity first"
# Codex merges the global and project AGENTS.md under one 32 KiB `project_doc_max_bytes` budget. A 15,000 B cap on
# each global file leaves a project 32,768 - 15,000 - 2,048 (margin) = 15,720 B, and sits about 5% above the largest
# file after v7.2.0, so small edits fit without raising it. Antigravity also keeps its 13,500-character build cap.
MAX_DIST_BYTES = 15_000


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


def communication_section(text: str) -> str:
    start = text.index("## Communication\n")
    end = text.find("\n## ", start + 1)
    return text[start:end if end != -1 else len(text)]


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 2, 0), f"VERSION must be at least 7.2.0, got {version}")
for name in ("core.md",) + DISTS:
    section = communication_section(read(name))
    for phrase in (PROGRESS, PROGRESS_DETAIL, FINAL):
        require(phrase in section, f"{name} Communication lacks: {phrase}")
for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} B > {MAX_DIST_BYTES} B cap")
    require(read(name).count(PROGRESS) == 1, f"{name} states the progress rule more than once")
adapter = read("adapters/claude.md")
require(OLD_ADAPTER_PROGRESS not in adapter, "Claude adapter still repeats the progress rule core now owns")
require(OLD_APPLY_DEFAULT not in adapter, "Claude adapter still calls apply the 0-token default for code")
require(DELEGATE_FIRST in adapter, "Claude adapter does not send code to Ollama or Antigravity first")
require("brief-ko" in adapter, "Claude adapter must still name its output style")
mirror = read("GLOBAL_RULES.ko.md")
require(f"> Canonical version: {version}" in mirror, "ko mirror version differs from VERSION")
require("도구 호출 사이" in mirror, "ko mirror lacks the progress-line rule")
require(NEXT in read("core.md"), "core report shape lost its next-step line")
print("PASS v7.2.0 quiet output, delegate-first adapter, size cap")
