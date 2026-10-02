"""Fixed acceptance for v7.4.1: paid windows and workers run on subscription logins, never API-key billing.

Receipt (2026-10-02): the U129 card window (`claude --bg`) died on "Login expired"; the only working CLI login was
"API Usage Billing". Measured at Opus 5.5 API rates ($4 in / $20 out per Mtok): the U115 card window, 46 calls,
cost about US$3.01; a long user thread, 151 calls, about US$17.08. A card loop on API billing is a spend (human list).
"""

from pathlib import Path
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # a Korean console (cp949) cannot print every FAIL
ROOT = Path(__file__).resolve().parent.parent
DISTS = ("dist/claude/CLAUDE.md", "dist/codex/AGENTS.md", "dist/antigravity/GEMINI.md")
RULE = "paid windows use subscription logins, not API-key billing"
KO = "유료 창·작업자는 구독 로그인으로만 열고"
# Same cap and reason as v720_quiet_output_check.py (Codex's 32 KiB shared AGENTS.md budget).
MAX_DIST_BYTES = 15_000


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8").replace("\r\n", "\n")


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        raise SystemExit(1)


version = read("VERSION").strip()
require(tuple(int(p) for p in version.split(".")) >= (7, 4, 1), f"VERSION must be at least 7.4.1, got {version}")
for name in ("core.md",) + DISTS:
    require(read(name).count(RULE) == 1, f"{name} must state once: {RULE}")
require(KO in read("GLOBAL_RULES.ko.md"), "GLOBAL_RULES.ko.md must carry the Korean rule")
for name in DISTS:
    size = len((ROOT / name).read_bytes())
    require(size <= MAX_DIST_BYTES, f"{name} is {size} bytes, over {MAX_DIST_BYTES}")
print("PASS v741 subscription windows")
