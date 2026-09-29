"""Fixed acceptance for U77 adaptive, nonstop three-tool control rules."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parent.parent


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
core = read("core.md")
mirror = read("GLOBAL_RULES.ko.md")
readme = read("README.md")

# v5.30.0: a later version keeps these rules, so the pin is a floor (an exact pin failed every later release, as u45_g7 does).
require(tuple(int(p) for p in version.split(".")) >= (5, 29, 1), f"VERSION must be at least 5.29.1, got {version}")
require("material change" in core and "re-plan" in core, "core lacks the material-change re-planning trigger")
for phrase in (
    "requirements, evidence, design, ownership, or a confirmed tool route",
    "invalidate affected assumptions/cards",
    "update design, fixed acceptance, and contract manual",
    "internal dependencies, not user work",
    "Codex, Claude, or Antigravity review or approval",
    "another start or continue command",
    "terminal check",
    "durable handoff and zero-paid-token watcher",
    "UNKNOWN is not one",
    "at most twice",
    "never overrides the human list",
    "watcher expiry",
    "never self-approve",
    "OPEN and mergeable",
):
    require(phrase in core, f"core lacks invariant: {phrase}")

for phrase in (
    "요구·증거·설계·소유권 또는",
    "영향받은 가정과 카드",
    "설계·고정 인수·계약 매뉴얼",
    "내부 의존성이지 사용자 일이 아닙니다",
    "다시 시작하거나 계속하라는 명령",
    "종료 관문",
    "영속 인계와 유료 토큰 0인 감시",
    "`UNKNOWN`은 변화가 아님",
    "최대 2회",
    "절대 바꾸지 않습니다",
    "감시 만료",
    "자기 승인하지 않으며",
    "`OPEN`이고 병합 가능",
):
    require(phrase in mirror, f"Korean mirror lacks invariant: {phrase}")

require(f"> Canonical version: {version}" in mirror, "Korean mirror version drift")
require("세 도구가 공유하는" in readme, "README still documents a split core")
require("Claude는 `claude.md`" not in readme, "README still directs Claude edits to the legacy canon")

design = read("docs/adaptive-nonstop-control-loop.md")
for heading in ("## State machine", "## Change-impact gate", "## Terminal gate", "## Red-team cases"):
    require(heading in design, f"design lacks {heading}")

for target in (
    "dist/antigravity/GEMINI.md",
    "dist/codex/AGENTS.md",
    "dist/claude/CLAUDE.md",
):
    generated = read(target)
    require(f"v{version}" in generated, f"{target} has stale version")
    require("material change" in generated and "terminal check" in generated, f"{target} lacks U77 rules")

print("PASS u77_adaptive_nonstop_check")
