"""U45 G7 fixed acceptance (written 2026-09-26 by Claude Code, acting conductor; frozen before the worker run).

Goal: the three global rule files are one shared core plus a small per-tool adapter. Claude stops being a
standalone rule file and is generated from core.md + adapters/claude.md like Codex and Antigravity.
Run from the global-rules folder: python tests/u45_g7_check.py  (exit 0 = pass, prints the first failure otherwise).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def read(rel):
    return (ROOT / rel).read_text(encoding="utf-8").replace("\r\n", "\n")


def fail(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


core = read("core.md")
adapter_path = ROOT / "adapters" / "claude.md"
if not adapter_path.is_file():
    fail("adapters/claude.md is missing")
adapter = read("adapters/claude.md")
sync = read("scripts/sync-global-rules.ps1")
version = read("VERSION").strip()
mirror = read("GLOBAL_RULES.ko.md")

# 1. Claude target is generated from core + adapter, like the other two.
claude_block = re.search(r"Name = 'Claude'(.*?)\n    \}", sync, re.S)
if not claude_block:
    fail("Claude target block not found in sync-global-rules.ps1")
block = claude_block.group(1)
if "adapters\\claude.md" not in block or not re.search(r"SourcePath = \$null", block):
    fail("Claude target must use Adapter = adapters\\claude.md and SourcePath = $null")

# 2. The core says it is shared by all three tools.
first_quote = next((l for l in core.splitlines() if l.startswith(">")), "")
if "standalone" in first_quote or "Claude" not in first_quote:
    fail("core.md header must name Claude as a consumer of the shared core, not a standalone file")

# 3. Succession invariant (G3) in the core: Codex -> Claude acting -> Antigravity acting, with return re-review.
if not any(all(k in l for k in ("Codex", "Claude", "Antigravity")) and "re-review" in l for l in core.splitlines()):
    fail("core.md needs one line with the Codex -> Claude -> Antigravity succession and the return re-review")

# 4. Ollama calculator invariant (G4) stays in the core.
if "unagentic calculator" not in core or "UNMEASURED" not in core:
    fail("core.md lost the Ollama calculator or UNMEASURED rule")

# 5. The Claude adapter is small and keeps only Claude-specific rules.
bullets = [l for l in adapter.splitlines() if l.startswith("- ")]
if not adapter.lstrip().startswith("## Claude Code adapter"):
    fail("adapters/claude.md must start with '## Claude Code adapter'")
if not 4 <= len(bullets) <= 14:
    fail(f"adapter bullet count {len(bullets)} not in 4..14")
for needle in ("brief-ko", "/CRITIC", "Edit", "Write", "scratchpad", "deputy"):
    if needle not in adapter:
        fail(f"adapters/claude.md lacks the Claude-specific rule keyword {needle!r}")

# 6. No bullet appears in both the core and any adapter (the sync script also checks this).
core_bullets = {l.strip() for l in core.splitlines() if l.startswith("- ")}
dups = [b for b in bullets if b.strip() in core_bullets]
if dups:
    fail(f"adapter repeats core bullets: {dups[:2]}")

# 7. Version bumped (MINOR: a new adapter, same rules) and mirrored.
if version != "5.26.0":
    fail(f"VERSION must be 5.26.0, got {version}")
if f"> Canonical version: {version}" not in mirror:
    fail("GLOBAL_RULES.ko.md canonical version line not updated")
if "별도 정본" in mirror:
    fail("GLOBAL_RULES.ko.md still says Claude has a separate canon")

print("PASS u45_g7_check")
