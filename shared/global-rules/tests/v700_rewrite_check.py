"""Fixed acceptance for v7.0.0: the rewritten rules keep every old rule's meaning, think by MIA, and follow the vendors' prompting guides.

Receipts (2026-09-29): 윤겸스 asked to rewrite the three tools' global rules from scratch rather than patch them
("minimalizing by omission is a design failure"), to plant the MIA strategic procedure instead of "take a deep breath,
step by step", to show every project and process at a glance, and then to fold in the current Claude, Codex, and
Antigravity prompting guides, removing rules that contradict them.
"""

from pathlib import Path
import re
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
SOURCES = ("core.md", "adapters/codex.md", "adapters/claude.md", "adapters/antigravity.md")
TRACE = "docs/v7-rewrite-traceability.md"
OLD_BULLETS = "tests/fixtures/v621_bullets.tsv"


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 0, 0), f"VERSION must be at least 7.0.0, got {version}")
require(f"> Canonical version: {version}" in read("GLOBAL_RULES.ko.md"), "ko mirror version drift")

core = read("core.md")
rules = "\n".join(read(name) for name in SOURCES)

# Criterion: no old rule is lost. Every old ID has a row, and every row's key phrase is really in the new rules.
old_ids = [line.split("\t", 1)[0] for line in read(OLD_BULLETS).splitlines() if line.strip()]
require(len(old_ids) == 80, f"fixture should hold the 80 v6.2.1 bullets, found {len(old_ids)}")
rows = {}
for line in read(TRACE).splitlines():
    match = re.match(r"\| ([CXLAN]\d\d) \|.*?«(.+?)»", line)
    if match:
        rows[match.group(1)] = match.group(2)
missing_ids = [old for old in old_ids if old not in rows]
require(not missing_ids, f"traceability lacks old bullets: {missing_ids}")
lost = [(key, phrase) for key, phrase in rows.items() if phrase not in rules]
require(not lost, f"key phrases missing from the new rules: {lost[:3]}")

# Criterion: MIA replaces free-form step-by-step; its four stages exist, its workflow detail stays in the skill.
for stage in ("- Frame:", "- Review:", "- Execute:", "- Verify:"):
    require(stage in core, f"core lacks the MIA stage {stage!r}")
for artifact in ("Opportunity Brief", "Decision Memo", "Delivery Card", "Learning Report", "plan-review-execute"):
    require(artifact not in rules, f"MIA workflow detail {artifact!r} leaked into the rules")
guard = read("scripts/sync-global-rules.ps1")
require("Opportunity Brief|Decision Memo|Delivery Card|Learning Report" in guard, "build guard no longer bans MIA workflow detail")
require("not free-form step-by-step" not in core and "deep breath" not in core, "negative or legacy thinking prompt came back")

# Criterion: every project and process at a glance, by a data optimization expert.
require("a briefing lists all of them" in core, "core lacks the brief-everything rule")
require("Act as a Data Optimization Expert" in core, "core lacks the Data Optimization Expert role")

# Criterion: no duplication. Facts that used to be stated in two to five places now appear once.
for phrase in ("never a self-report", "a path alone is not delivery", "3x regression", "`.work/backup_<date>/`",
               "COST_EXCEEDED", "unagentic calculator", "for Codex's re-review"):
    count = rules.count(phrase)
    require(count == 1, f"{phrase!r} appears {count} times across core and adapters, expected once")

# Vendor guides (REFERENCES §7): no shouted emphasis, and the rules that contradicted the guides stay removed.
shouted = re.findall(r"\b(?:MUST|CRITICAL|ALWAYS|IMPORTANT|NEVER)\b", rules)
require(not shouted, f"rules use shouted emphasis, which makes current models overreact: {shouted[:3]}")
require("Deny > Ask > Allow" not in rules, "permission settings belong in Antigravity's config, not its rules")
require("`local_read_map` before" not in rules, "olla tool triggers belong in the olla server's own instructions")
references = read("REFERENCES.md")
for source in ("prompting-claude-opus-5-5", "codex_prompting_guide", "antigravity.google/docs/rules"):
    require(source in references, f"REFERENCES lacks the primary source {source!r}")

print("PASS v700_rewrite_check")
