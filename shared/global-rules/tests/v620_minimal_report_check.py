"""Fixed acceptance for v6.2.0: one plain summary, each fact once, no fact dropped, every project at a glance.

Receipt (2026-09-29): 윤겸스 showed a report whose `결과` and closing `핵심요약` said the same thing and asked for a
minimal user output that still loses nothing: see every project and process at a glance, no duplication, and no
omission (dropping a fact to look short is a design failure). Output tokens cost 5x input tokens per token.
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print "–" in a FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
# What the shape must carry, and why each piece exists (acceptance criteria 1-3 of the request).
REQUIRED = {
    "`**결과**:` 1–2 plain sentences": "one plain summary at the top (BLUF)",
    "`- 근거:`": "proof lives in one line, not repeated in the summary",
    "only when present": "optional lines appear only with content",
    "`- <name>: <state> → <next>`": "criterion 1: every project or card at a glance",
    "State each fact once": "criterion 2: no duplication",
    "never facts (changed files, failed checks, risks, human actions)": "criterion 3: minimal is not omission",
}
# Lines that restated another line: a closing summary repeated 결과, 과정 repeated 근거.
RETIRED = ("핵심요약", "`- 과정:`")


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


def communication(text: str) -> str:
    """The first Communication bullet: the report shape every tool renders."""
    section = text[text.index("## Communication\n"):]
    return next(line for line in section.splitlines() if line.startswith("- "))


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (6, 2, 0), f"VERSION must be at least 6.2.0, got {version}")
for name, text in [("core.md", read("core.md"))] + [(d, read(d)) for d in DISTS]:
    shape = communication(text)
    for phrase, why in REQUIRED.items():
        require(phrase in shape, f"{name} report shape lacks {phrase!r} ({why})")
    for phrase in RETIRED:
        require(phrase not in text, f"{name} still carries the duplicate line {phrase!r}")
# Reporting must not restate the shape: the old 'summarize what works, proof, next action' and 'report changed
# files, checks, risks, approvals' lines duplicated the Communication shape and its never-drop list.
for phrase in ("summarize what works", "Report changed files"):
    require(phrase not in read("core.md"), f"Reporting restates the Communication shape: {phrase!r}")
mirror = read("GLOBAL_RULES.ko.md")
for phrase in ("`**결과**:`", "`- <이름>: <상태> → <다음>`", "같은 사실은 한 번만", "사실(바뀐 파일·실패한 검사·위험·사람이 할 일)은 빼지 않습니다"):
    require(phrase in mirror, f"ko mirror lacks {phrase!r}")
for phrase in RETIRED:
    require(phrase not in mirror.split("## 소통", 1)[1].split("\n## ", 1)[0], f"ko mirror still carries {phrase!r}")
for dist in DISTS:
    require(f"v{version}" in read(dist), f"{dist} is stale: run sync-global-rules.ps1 -Mode Build")
require(len(read("dist/antigravity/GEMINI.md")) <= 11600, "dist/antigravity/GEMINI.md exceeds 11600 characters")

print("PASS v620_minimal_report_check")
sys.exit(0)
