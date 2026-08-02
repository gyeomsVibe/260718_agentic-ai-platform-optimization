#!/usr/bin/env python3
"""MIA 스킬 매니페스트 엄격 검증 — 3대 도구 중 가장 엄격한 Codex 기준을 적용한다.

배경: 2026-08-02 에 mia-strategic 의 description 이 작은따옴표로 시작해
YAML 인용 스칼라로 오인되면서 Codex 가 스킬 로딩을 거부했다. Claude Code 는
관대한 파서라 아무 경고 없이 통과시켰고, 결함이 3주간 은폐됐다.

따라서 배포 전에 반드시 엄격 파서로 검증한다. 통과하지 못하면 배포하지 않는다.
"""

import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml 이 필요합니다.  pip install pyyaml", file=sys.stderr)
    sys.exit(2)

CATALOG = Path(__file__).resolve().parent.parent

# 회귀 테스트가 픽스처 카탈로그를 지정할 수 있게 한다.
# 이 옵션이 없으면 검증기가 자기 자신을 잡아내는지 확인할 방법이 없어,
# 가드를 무력화해도 통과하는 무의미한 항체만 만들 수 있다. (2026-08-02 관측)
if "--catalog" in sys.argv:
    _idx = sys.argv.index("--catalog")
    if _idx + 1 >= len(sys.argv):
        print("ERROR: --catalog 뒤에 경로가 필요합니다.", file=sys.stderr)
        sys.exit(2)
    CATALOG = Path(sys.argv[_idx + 1]).resolve()

# 정본 스킬 위치 (sync-mia-catalog.ps1 의 definitions 와 일치해야 한다)
SKILLS = {
    "mia-skill-compiler": CATALOG / "1_mia-skill-compiler" / "candidates" / "mia-skill-compiler",
    "mia-vaccine-test": CATALOG / "2_mia-vaccine-test",
    "mia-strategic": CATALOG / "3_mia-strategic",
}

REQUIRED_SKILL_KEYS = ["name", "description"]
REQUIRED_OPENAI_PATHS = [
    ("interface", "display_name"),
    ("interface", "short_description"),
    ("interface", "default_prompt"),
]

errors = []
warnings = []


def extract_frontmatter(text, label):
    """SKILL.md 선두 --- 블록을 뽑는다."""
    if not text.startswith("---"):
        errors.append(f"{label}: frontmatter 없음 (파일이 '---' 로 시작해야 함)")
        return None
    end = text.find("\n---", 3)
    if end == -1:
        errors.append(f"{label}: frontmatter 종료 '---' 없음")
        return None
    return text[3:end]


def check_plain_scalar_hazards(raw, label):
    """엄격 파서가 통과시켜도 사람이 실수하기 쉬운 패턴을 경고한다."""
    for line in raw.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if ":" not in stripped:
            continue
        key, _, value = stripped.partition(":")
        value = value.strip()
        if not value:
            continue
        # 값이 인용부호로 시작하는데 같은 부호로 끝나지 않으면 위험
        for q in ("'", '"'):
            if value.startswith(q) and not value.endswith(q):
                warnings.append(
                    f"{label}: '{key.strip()}' 값이 {q} 로 시작하는데 같은 부호로 끝나지 않습니다. "
                    f"엄격 파서에서 깨지기 쉽습니다."
                )


for name, root in SKILLS.items():
    skill_md = root / "SKILL.md"
    openai_yaml = root / "agents" / "openai.yaml"

    # 1) SKILL.md frontmatter
    if not skill_md.exists():
        errors.append(f"{name}: SKILL.md 없음 ({skill_md})")
    else:
        raw = extract_frontmatter(skill_md.read_text(encoding="utf-8-sig"), f"{name}/SKILL.md")
        if raw is not None:
            try:
                data = yaml.safe_load(raw)
            except yaml.YAMLError as exc:
                first = str(exc).splitlines()[0]
                errors.append(f"{name}/SKILL.md: YAML 파싱 실패 - {first}")
            else:
                if not isinstance(data, dict):
                    errors.append(f"{name}/SKILL.md: frontmatter 가 매핑이 아닙니다")
                else:
                    for key in REQUIRED_SKILL_KEYS:
                        if not data.get(key):
                            errors.append(f"{name}/SKILL.md: 필수 키 '{key}' 누락 또는 빈 값")
                    if data.get("name") and data["name"] != name:
                        errors.append(
                            f"{name}/SKILL.md: name 이 '{data['name']}' 로 폴더 계약과 다릅니다"
                        )
            check_plain_scalar_hazards(raw, f"{name}/SKILL.md")

    # 2) agents/openai.yaml (Codex 표시·발동 계약)
    if not openai_yaml.exists():
        errors.append(f"{name}: agents/openai.yaml 없음 ({openai_yaml})")
    else:
        try:
            data = yaml.safe_load(openai_yaml.read_text(encoding="utf-8-sig"))
        except yaml.YAMLError as exc:
            first = str(exc).splitlines()[0]
            errors.append(f"{name}/agents/openai.yaml: YAML 파싱 실패 - {first}")
        else:
            if not isinstance(data, dict):
                errors.append(f"{name}/agents/openai.yaml: 최상위가 매핑이 아닙니다")
            else:
                for section, key in REQUIRED_OPENAI_PATHS:
                    node = data.get(section)
                    if not isinstance(node, dict) or not node.get(key):
                        errors.append(
                            f"{name}/agents/openai.yaml: '{section}.{key}' 누락 또는 빈 값"
                        )
                policy = data.get("policy")
                implicit = policy.get("allow_implicit_invocation") if isinstance(policy, dict) else None
                if implicit is None:
                    warnings.append(
                        f"{name}: policy.allow_implicit_invocation 미지정 - Codex 기본값에 의존합니다. "
                        f"의도를 명시하세요."
                    )
                elif implicit is False:
                    warnings.append(
                        f"{name}: allow_implicit_invocation=false 이므로 Codex 사용가능 목록에 "
                        f"노출되지 않습니다. 명시 호출($ 접두사)만 가능합니다. (의도된 설계면 정상)"
                    )

# ── 3) 생성본 검증 (CLAUDE-SKILL.md, plugin SKILL.md) ──────────────────────
# 정본만 검사하면 생성 파이프라인의 인코딩 결함이 은폐된다.
# 2026-08-02 에 실제로 발생: 정본 정상 + CLAUDE-SKILL.md 모지바케.

KOREAN_INTEGRITY_PHRASES = ["MIA모드 발동", "전략"]
"""생성본 description 에 반드시 포함되어야 하는 한국어. 하나라도 없으면 인코딩 손상."""


def check_korean_integrity(text, label):
    """description 내 한국어 트리거 문구가 온전한지 확인한다."""
    for phrase in KOREAN_INTEGRITY_PHRASES:
        if phrase not in text:
            errors.append(
                f"{label}: 한국어 '{phrase}' 가 description 에 없습니다. "
                f"인코딩 손상(mojibake) 가능성이 높습니다."
            )


GENERATED_FILES = {
    "CLAUDE-SKILL.md": CATALOG / "3_mia-strategic" / "CLAUDE-SKILL.md",
    "plugin/SKILL.md": CATALOG / "3_mia-strategic" / "plugin" / "skills" / "mia-strategic" / "SKILL.md",
}

for gen_label, gen_path in GENERATED_FILES.items():
    if not gen_path.exists():
        errors.append(f"생성본 {gen_label}: 파일 없음 ({gen_path})")
        continue
    gen_text = gen_path.read_text(encoding="utf-8-sig")
    raw = extract_frontmatter(gen_text, f"생성본 {gen_label}")
    if raw is None:
        continue
    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError as exc:
        first = str(exc).splitlines()[0]
        errors.append(f"생성본 {gen_label}: YAML 파싱 실패 - {first}")
        continue
    if not isinstance(data, dict):
        errors.append(f"생성본 {gen_label}: frontmatter 가 매핑이 아닙니다")
        continue
    for key in REQUIRED_SKILL_KEYS:
        if not data.get(key):
            errors.append(f"생성본 {gen_label}: 필수 키 '{key}' 누락 또는 빈 값")
    desc = data.get("description", "")
    check_korean_integrity(desc, f"생성본 {gen_label}")
    check_plain_scalar_hazards(raw, f"생성본 {gen_label}")

# ── 4) 배포 스크립트 BOM 검사 ──────────────────────────────────────────────
# Windows PowerShell 5.1 은 BOM 없는 UTF-8 을 시스템 코드페이지(CP949)로 읽는다.
# sync-mia-catalog.ps1 의 here-string 에는 한국어가 들어 있어, BOM 이 빠지면
# 5.1 에서 다른 내용이 생성되고 claude/mia-strategic 가 정본과 어긋난다.
# 2026-08-02 에 실제로 발생했고, pwsh(7) 로만 돌리면 드러나지 않아 은폐된다.

BOM = b"\xef\xbb\xbf"
BOM_REQUIRED_SCRIPTS = [CATALOG / "scripts" / "sync-mia-catalog.ps1"]

for script_path in BOM_REQUIRED_SCRIPTS:
    if not script_path.exists():
        # 픽스처 카탈로그에는 배포 스크립트가 없을 수 있다.
        continue
    head = script_path.read_bytes()[:3]
    if head != BOM:
        errors.append(
            f"{script_path.name}: UTF-8 BOM 없음 (선두 {head.hex(' ') or '빈 파일'}). "
            f"Windows PowerShell 5.1 이 CP949 로 오독해 한국어 생성물이 깨집니다."
        )

# ── 결과 출력 ──────────────────────────────────────────────────────────────

for w in warnings:
    print(f"WARN  {w}")
for e in errors:
    print(f"ERROR {e}")

print()
total_checked = len(SKILLS) + len(GENERATED_FILES)
print(f"검사 스킬 {len(SKILLS)}개 + 생성본 {len(GENERATED_FILES)}개 / 경고 {len(warnings)}건 / 오류 {len(errors)}건")

sys.exit(1 if errors else 0)

