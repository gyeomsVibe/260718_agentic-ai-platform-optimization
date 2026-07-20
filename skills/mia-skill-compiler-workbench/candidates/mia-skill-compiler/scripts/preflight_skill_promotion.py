#!/usr/bin/env python3
"""Agent Skill 후보를 변경 없이 설치·승격 전에 검사한다."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path


NAME_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FRONTMATTER_PATTERN = re.compile(r"\A---\s*\n(.*?)\n---\s*\n", re.DOTALL)
LINK_PATTERN = re.compile(r"(?<!!)\[[^\]]+\]\((?!https?://|mailto:|#)([^)]+)\)")
ALLOWED_TOP_LEVEL = {"SKILL.md", "agents", "assets", "references", "scripts"}
TEXT_SUFFIXES = {".md", ".json", ".py", ".txt", ".yaml", ".yml"}
SENSITIVE_PATTERNS = (
    re.compile(r"^\.env(?:\..+)?$", re.IGNORECASE),
    re.compile(r"credentials?", re.IGNORECASE),
    re.compile(r"secret", re.IGNORECASE),
    re.compile(r"\.(?:pem|key|p12|pfx)$", re.IGNORECASE),
)
RISKY_COMMANDS = {
    "recursive forced deletion": re.compile(r"\brm\s+-rf\b", re.IGNORECASE),
    "hard git reset": re.compile(r"\bgit\s+reset\s+--hard\b", re.IGNORECASE),
    "git hook bypass": re.compile(r"\bgit\s+[^\n]*--no-" r"verify\b", re.IGNORECASE),
    "remote script pipe": re.compile(
        r"\b(?:curl|wget)\b[^\n|]*\|\s*(?:sh|bash|zsh)\b", re.IGNORECASE
    ),
    "PowerShell expression execution": re.compile(
        r"\bInvoke-" r"Expression\b|\biex\s+", re.IGNORECASE
    ),
}


@dataclass(frozen=True)
class Finding:
    """검사 결과 한 건을 표현한다."""

    severity: str
    code: str
    message: str
    path: str


def sha256(path: Path) -> str:
    """파일의 SHA-256을 반환한다.

    Args:
        path: 해시를 계산할 파일 경로.

    Returns:
        대문자 16진수 SHA-256 문자열.
    """

    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def sensitive_name(path: Path) -> bool:
    """민감 파일처럼 보이는 이름인지 확인한다."""

    return any(pattern.search(path.name) for pattern in SENSITIVE_PATTERNS)


def add(
    findings: list[Finding], severity: str, code: str, message: str, path: Path
) -> None:
    """검사 결과를 목록에 추가한다."""

    findings.append(Finding(severity, code, message, path.as_posix()))


def parse_name(skill_file: Path, findings: list[Finding]) -> str | None:
    """SKILL.md 프런트매터에서 name을 읽는다."""

    try:
        text = skill_file.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        add(findings, "error", "unreadable_skill", str(exc), skill_file)
        return None
    match = FRONTMATTER_PATTERN.match(text)
    if not match:
        add(findings, "error", "invalid_frontmatter", "YAML 프런트매터가 없습니다.", skill_file)
        return None
    for line in match.group(1).splitlines():
        field = re.match(r"^name:\s*(.+?)\s*$", line)
        if field:
            return field.group(1).strip().strip("\"'")
    add(findings, "error", "missing_name", "프런트매터에 name이 없습니다.", skill_file)
    return None


def audit_candidate(
    candidate: Path,
    target: Path | None,
    target_state: str,
    allowed_target_root: Path | None,
) -> dict[str, object]:
    """후보와 선택적 설치 대상을 읽기 전용으로 검사한다.

    Args:
        candidate: 후보 Skill 디렉터리.
        target: 설치 대상 경로 또는 None.
        target_state: 대상 기대 상태. absent, required, ignore 중 하나.
        allowed_target_root: 설치가 허용된 루트 또는 None.

    Returns:
        JSON 직렬화 가능한 검사 결과.
    """

    candidate = candidate.resolve()
    findings: list[Finding] = []
    manifest: list[dict[str, object]] = []
    if not candidate.is_dir():
        add(findings, "error", "missing_candidate", "후보 디렉터리가 없습니다.", candidate)
        return build_result(candidate, target, findings, manifest)

    skill_file = candidate / "SKILL.md"
    if not skill_file.is_file():
        add(findings, "error", "missing_skill", "SKILL.md가 없습니다.", skill_file)
    else:
        name = parse_name(skill_file, findings)
        if name and (not NAME_PATTERN.fullmatch(name) or name != candidate.name):
            add(
                findings,
                "error",
                "invalid_or_mismatched_name",
                f"name '{name}'이 폴더 이름 '{candidate.name}'과 맞지 않습니다.",
                skill_file,
            )

    for path in sorted(candidate.rglob("*")):
        relative = path.relative_to(candidate)
        if path.is_symlink():
            add(findings, "error", "symlink_forbidden", "심볼릭 링크는 허용하지 않습니다.", relative)
            continue
        if not path.is_file():
            continue
        if relative.parts[0] not in ALLOWED_TOP_LEVEL:
            add(findings, "error", "unexpected_top_level", "허용되지 않은 최상위 항목입니다.", relative)
        if sensitive_name(path):
            add(findings, "error", "sensitive_filename", "민감 파일처럼 보이는 이름입니다.", relative)
            continue
        manifest.append({"path": relative.as_posix(), "size": path.stat().st_size, "sha256": sha256(path)})
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            add(findings, "error", "unreadable_utf8", str(exc), relative)
            continue
        if relative.as_posix() == "scripts/preflight_skill_promotion.py":
            continue
        if path.suffix.lower() == ".md":
            for raw_link in LINK_PATTERN.findall(content):
                link = raw_link.strip().split("#", 1)[0]
                if not link:
                    continue
                destination = (path.parent / link).resolve(strict=False)
                try:
                    destination.relative_to(candidate)
                except ValueError:
                    add(
                        findings,
                        "error",
                        "link_escapes_candidate",
                        f"후보 밖으로 나가는 링크입니다: {raw_link}",
                        relative,
                    )
                else:
                    if not destination.exists():
                        add(
                            findings,
                            "error",
                            "broken_link",
                            f"대상이 없는 링크입니다: {raw_link}",
                            relative,
                        )
        for label, pattern in RISKY_COMMANDS.items():
            if pattern.search(content):
                add(findings, "error", "risky_command", f"위험 명령 패턴: {label}", relative)

    if target is not None:
        resolved_target = target.resolve(strict=False)
        if allowed_target_root is None:
            add(
                findings,
                "error",
                "missing_allowed_target_root",
                "대상이 허용된 설치 루트 안인지 확인할 기준 경로가 없습니다.",
                resolved_target,
            )
        else:
            resolved_root = allowed_target_root.resolve(strict=False)
            try:
                resolved_target.relative_to(resolved_root)
            except ValueError:
                add(
                    findings,
                    "error",
                    "target_outside_allowed_root",
                    f"대상이 허용된 설치 루트 밖에 있습니다: {resolved_root.as_posix()}",
                    resolved_target,
                )
        exists = resolved_target.exists()
        if target_state == "absent" and exists:
            add(findings, "error", "target_collision", "설치 대상이 이미 존재합니다.", resolved_target)
        if target_state == "required" and not exists:
            add(findings, "error", "missing_target", "검증할 설치 대상이 없습니다.", resolved_target)
        if resolved_target == candidate:
            add(findings, "error", "same_source_target", "원본과 대상 경로가 같습니다.", resolved_target)

    return build_result(candidate, target, findings, manifest)


def build_result(
    candidate: Path,
    target: Path | None,
    findings: list[Finding],
    manifest: list[dict[str, object]],
) -> dict[str, object]:
    """최종 검사 결과를 만든다."""

    errors = sum(item.severity == "error" for item in findings)
    warnings = sum(item.severity == "warning" for item in findings)
    return {
        "schema_version": 1,
        "candidate": candidate.as_posix(),
        "target": target.resolve(strict=False).as_posix() if target else None,
        "mode": "read_only_preflight",
        "status": "pass" if errors == 0 else "fail",
        "safe_to_plan": errors == 0,
        "safe_to_install": False,
        "errors": errors,
        "warnings": warnings,
        "manifest": manifest,
        "findings": [asdict(item) for item in findings],
    }


def main() -> int:
    """명령줄 인자를 처리하고 검사 결과를 출력한다."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--target", type=Path)
    parser.add_argument("--allowed-target-root", type=Path)
    parser.add_argument(
        "--target-state", choices=("absent", "required", "ignore"), default="absent"
    )
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()
    report = audit_candidate(
        args.candidate, args.target, args.target_state, args.allowed_target_root
    )
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    print(rendered)
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(rendered + "\n", encoding="utf-8")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
