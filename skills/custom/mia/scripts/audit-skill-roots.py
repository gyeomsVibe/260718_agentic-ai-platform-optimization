#!/usr/bin/env python3
"""4개 배포 루트 전체를 AUTHORING_HANDBOOK §2 최엄격 규격으로 감사한다 (읽기 전용).

`validate-skill-manifests.py` 는 MIA 정본 카탈로그만 본다. 이 스크립트는 그 게이트가
닿지 않는 **실제 배포본 전체**를 본다. 두 도구는 역할이 다르므로 대체하지 않는다.

최엄격 기준은 교본 §1에 따라 Codex 다. Codex 의 엄격 YAML 파서를 `yaml.safe_load` 로
재현하여, 예외가 나면 그 스킬은 Codex 가 로딩을 거부하는 상태로 판정한다.

사용:
    python skills/custom/mia/scripts/audit-skill-roots.py
    python skills/custom/mia/scripts/audit-skill-roots.py --strict   # 경고도 실패 처리

종료 코드: 오류 있으면 1, 없으면 0 (--strict 는 경고도 1)
"""
from __future__ import annotations

import argparse
import collections
import os
import pathlib
import sys

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml 이 필요합니다. `python -m pip install pyyaml`", file=sys.stderr)
    raise SystemExit(2)

HOME = pathlib.Path(os.path.expanduser("~"))
BOM = b"\xef\xbb\xbf"

# 교본 §5 배포 위치 중 사용자 홈의 4개 루트
ROOTS: "collections.OrderedDict[str, pathlib.Path]" = collections.OrderedDict([
    ("claude", HOME / ".claude" / "skills"),
    ("codex", HOME / ".codex" / "skills"),
    ("antigravity", HOME / ".gemini" / "config" / "skills"),
    ("shared", HOME / ".agents" / "skills"),
])

# 스킬이 아닌 도구 내부 디렉터리
NOT_A_SKILL = {".system"}

Finding = collections.namedtuple("Finding", "root skill severity code message")


def audit_skill(root: str, d: pathlib.Path, out: list) -> str | None:
    """스킬 하나를 감사하고 description 을 돌려준다 (실패 시 None)."""
    name = d.name

    def add(sev, code, msg):
        out.append(Finding(root, name, sev, code, msg))

    skill_md = d / "SKILL.md"
    if not skill_md.exists():
        add("ERROR", "no_skill_md", "SKILL.md 없음 - 어떤 도구에서도 로딩되지 않는다")
        return None

    raw = skill_md.read_bytes()
    if raw.startswith(BOM):
        add("ERROR", "md_has_bom", "SKILL.md 에 BOM - .md 는 BOM 없는 UTF-8 이어야 한다 (§2.4)")
        raw = raw[len(BOM):]
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        add("ERROR", "not_utf8", f"UTF-8 디코드 실패: {exc}")
        return None

    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        add("ERROR", "no_frontmatter", "--- 로 시작하지 않는다 (§2.1)")
        return None
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        add("ERROR", "unclosed_frontmatter", "닫는 --- 가 없다 (§2.1)")
        return None

    block = "\n".join(lines[1:end])

    # 최엄격: Codex 의 엄격 YAML 파서 재현
    try:
        front = yaml.safe_load(block)
    except yaml.YAMLError as exc:
        add("ERROR", "yaml_parse_fail",
            f"엄격 YAML 파싱 실패 -> Codex 로딩 거부: {str(exc).splitlines()[0]}")
        return None
    if not isinstance(front, dict):
        add("ERROR", "yaml_not_mapping", "frontmatter 가 매핑이 아니다")
        return None

    declared = front.get("name")
    description = front.get("description")
    if not declared or not str(declared).strip():
        add("ERROR", "name_missing", "name 누락 또는 빈 값 (§2.1)")
    elif str(declared) != name:
        add("ERROR", "name_mismatch", f"name='{declared}' 가 폴더명 '{name}' 과 다르다 (§2.1)")
    if not description or not str(description).strip():
        add("ERROR", "desc_missing", "description 누락 또는 빈 값 (§2.1)")

    # §2.1 인용부호로 시작하고 닫히지 않는 스칼라 (파서가 통과시켜도 의미가 잘린다)
    for key in ("name", "description"):
        for line in block.splitlines():
            stripped = line.strip()
            if stripped.startswith(key + ":"):
                value = stripped[len(key) + 1:].strip()
                if value[:1] in ("'", '"') and not (len(value) > 1 and value[-1] == value[0]):
                    add("ERROR", "quote_start",
                        f"{key} 값이 {value[:1]} 로 시작하고 닫히지 않는다 - 스칼라 조기 종료 (§2.1)")

    # §2.2 Codex 어댑터 계약
    openai_yaml = d / "agents" / "openai.yaml"
    if not openai_yaml.exists():
        add("WARN", "no_openai_yaml",
            "agents/openai.yaml 없음 - Codex 표시·발동 계약 미이행 (§2.2)")
    else:
        try:
            adapter = yaml.safe_load(openai_yaml.read_text("utf-8")) or {}
        except yaml.YAMLError as exc:
            add("ERROR", "openai_yaml_parse",
                f"openai.yaml 파싱 실패: {str(exc).splitlines()[0]}")
        else:
            interface = adapter.get("interface") or {}
            for key in ("display_name", "short_description", "default_prompt"):
                if not interface.get(key):
                    add("ERROR", "iface_key_missing", f"openai.yaml interface.{key} 누락 (§2.2)")
            policy = adapter.get("policy") or {}
            if "allow_implicit_invocation" not in policy:
                add("WARN", "implicit_unset",
                    "policy.allow_implicit_invocation 미지정 - 도구 기본값에 의존한다 (§2.2)")

    # §2.3 이중 중첩
    if (d / name).is_dir():
        add("ERROR", "double_nest", f"{name}/{name}/ 이중 중첩 (§2.3)")

    # §2.4 한국어 .ps1 은 BOM 필수
    for script in d.rglob("*.ps1"):
        data = script.read_bytes()
        has_korean = any("가" <= ch <= "힣" for ch in data.decode("utf-8", "ignore"))
        if has_korean and not data.startswith(BOM):
            add("ERROR", "ps1_no_bom",
                f"{script.name}: 한국어 .ps1 에 UTF-8 BOM 없음 - PS5.1 이 CP949 로 오독 (§2.4)")

    return str(description or "")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--strict", action="store_true", help="경고도 실패로 처리한다")
    args = parser.parse_args()

    findings: list[Finding] = []
    descriptions: dict[str, dict[str, str]] = collections.defaultdict(dict)
    counts: dict[str, int] = {}

    for root, path in ROOTS.items():
        if not path.exists():
            print(f"NOTE  루트 없음, 건너뜀: {root} ({path})")
            counts[root] = 0
            continue
        dirs = sorted(p for p in path.iterdir() if p.is_dir() and p.name not in NOT_A_SKILL)
        counts[root] = len(dirs)
        for d in dirs:
            desc = audit_skill(root, d, findings)
            if desc is not None:
                descriptions[d.name][root] = desc

    errors = [f for f in findings if f.severity == "ERROR"]
    warnings = [f for f in findings if f.severity == "WARN"]
    drift = sorted(
        (name, sorted(per)) for name, per in descriptions.items()
        if len(per) > 1 and len({v.strip() for v in per.values()}) > 1
    )

    print("=" * 78)
    print("스킬 배포 루트 엄격 감사 (AUTHORING_HANDBOOK §2 / 최엄격 기준: Codex)")
    print("=" * 78)
    print("\n[루트별 스킬 수]")
    for root, n in counts.items():
        print(f"  {root:<14} {n:>3}개   {ROOTS[root]}")

    if errors:
        print(f"\n[오류 {len(errors)}건]")
        for f in sorted(errors):
            print(f"  {f.root:<12} {f.skill:<32} {f.code:<20} {f.message}")
    else:
        print("\n[오류] 없음")

    if warnings:
        print(f"\n[경고 {len(warnings)}건 - 유형별]")
        for code, n in collections.Counter(f.code for f in warnings).most_common():
            print(f"  {code:<24} {n}건")

    if drift:
        print(f"\n[루트 간 description 불일치 {len(drift)}건]")
        for name, roots in drift:
            print(f"  {name:<34} {roots}")
        print("  주의: MIA 스킬의 Claude 어댑터는 영문 description 을 의도적으로 생성한다.")
        print("        sync-mia-catalog.ps1 이 관리하는 항목은 불일치가 정상이다.")

    print(f"\n결과: 오류 {len(errors)}건 / 경고 {len(warnings)}건 / 설명 불일치 {len(drift)}건")

    if errors:
        return 1
    if args.strict and warnings:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
