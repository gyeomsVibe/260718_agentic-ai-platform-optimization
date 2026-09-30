"""Fixed acceptance for v7.1.0: the owner's goal, yardstick and default mode are the foundation of every tool's rules.

Receipt (2026-09-30): 윤겸스 asked whether UAOS-RSI really carries its goal ("the same budget buys a much longer,
more complex automation workflow") and premise (one Claude or Codex conversation drains a 5-hour or weekly limit
before one process is done), and ordered both to be the operating system's foundation, with token-thrift as the
default mode. Audit before this version: the words "Token-thrift is default" existed only as an Ollama routing line
in Scope, and no rule stated the goal or the premise.
"""

from pathlib import Path
import re
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent
HEADING = "## Goal, yardstick, and default mode"
PHRASES = (
    "- Goal: the same budget buys 윤겸스 a much longer, more complex automation workflow.",
    "paid tokens per finished step",
    "- Yardstick: today one conversation drains a Claude or Codex 5-hour or weekly limit before one process, "
    "let alone a project, is done.",
    "split a card over its share instead of continuing it",
    "- Token-thrift is the default mode of all three tools, read by the runtime; only 윤겸스's explicit instruction",
    "cost ≈ calls × context",
    "Cut in this order: paid calls",
)
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
# Codex merges AGENTS.md files under one 32 KiB project_doc_max_bytes budget (Codex adapter); the global file keeps
# at least half of it for project files, so the foundation cannot grow by crowding project rules out.
CODEX_GLOBAL_MAX_BYTES = 16 * 1024


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 1, 0), f"VERSION must be at least 7.1.0, got {version}")

# Criterion: the foundation comes first, before the UAOS-RSI section, in the source and in every deployed file.
for name in ("core.md",) + DISTS:
    text = read(name)
    require(HEADING in text, f"{name} lacks {HEADING!r}")
    require(text.index(HEADING) < text.index("## UAOS-RSI\n"), f"{name}: the goal section must precede ## UAOS-RSI")
    section = re.search(re.escape(HEADING) + r"\n(.*?)(?=\n## )", text, re.S).group(1)
    for phrase in PHRASES:
        require(phrase in section, f"{name}: goal section lacks {phrase!r}")

# The older routing line stays: it is how token-thrift delegates, and v7.0.0 traceability pins it (C44, C49).
core = read("core.md")
require("Token-thrift is default: deterministic extraction first" in core, "Scope delegation line was lost")
require("unagentic calculator" in core, "Ollama calculator line was lost")

ko = read("GLOBAL_RULES.ko.md")
require(f"> Canonical version: {version}" in ko, "ko mirror version drift")
require("## 목표·척도·기본 모드" in ko and ko.index("## 목표·척도·기본 모드") < ko.index("## UAOS-RSI\n"),
        "ko mirror lacks the goal section before UAOS-RSI")
for phrase in ("같은 예산으로 훨씬 길고 복잡한 실무 자동화 워크플로우", "5시간·1주 한도가 바닥나",
               "토큰예산절약 모드(Token-thrift)가 세 도구 모두의 기본 모드", "| 목표·척도·기본 모드 |"):
    require(phrase in ko, f"ko mirror lacks {phrase!r}")

size = len(read("dist/codex/AGENTS.md").encode("utf-8"))
require(size <= CODEX_GLOBAL_MAX_BYTES, f"Codex global AGENTS.md is {size} bytes > {CODEX_GLOBAL_MAX_BYTES}")
require("MaxCharacters = 13500" in read("scripts/sync-global-rules.ps1"), "Antigravity cap moved without this check")

trace = read("docs/v7-rewrite-traceability.md")
for row in ("N17", "N18", "N19", "N20"):
    require(f"| {row} | core 목표 |" in trace, f"traceability lacks {row}")

print(f"PASS v{version}: goal, yardstick and token-thrift default lead core, 3 dists and the ko mirror; "
      f"Codex global {size} bytes")
