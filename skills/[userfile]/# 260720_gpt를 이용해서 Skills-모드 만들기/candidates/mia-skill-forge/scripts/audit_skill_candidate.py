#!/usr/bin/env python3
"""Deterministically audit an Agent Skill static candidate."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable


NAME_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
LINK_PATTERN = re.compile(r"(?<!!)\[[^\]]+\]\((?!https?://|mailto:|#)([^)]+)\)")
BANNED_DOCS = {
    "readme.md",
    "installation_guide.md",
    "quick_reference.md",
    "changelog.md",
}
SENSITIVE_PATTERNS = (
    re.compile(r"^\.env(?:\..+)?$", re.IGNORECASE),
    re.compile(r"credentials?", re.IGNORECASE),
    re.compile(r"secret", re.IGNORECASE),
    re.compile(r"\.(?:pem|key|p12|pfx)$", re.IGNORECASE),
)
RISKY_COMMANDS = {
    "recursive forced deletion": re.compile(r"\brm\s+-rf\b", re.IGNORECASE),
    "hard git reset": re.compile(r"\bgit\s+reset\s+--hard\b", re.IGNORECASE),
    "git hook bypass": re.compile(r"\bgit\s+[^\n]*--no-verify\b", re.IGNORECASE),
    "remote script pipe": re.compile(r"\b(?:curl|wget)\b[^\n|]*\|\s*(?:sh|bash|zsh)\b", re.IGNORECASE),
    "PowerShell expression execution": re.compile(r"\bInvoke-Expression\b|\biex\s+", re.IGNORECASE),
}
TEXT_SUFFIXES = {".md", ".yaml", ".yml", ".py", ".json", ".txt"}


@dataclass(frozen=True)
class Finding:
    severity: str
    code: str
    message: str
    path: str


def add(findings: list[Finding], severity: str, code: str, message: str, path: Path) -> None:
    findings.append(Finding(severity, code, message, path.as_posix()))


def is_sensitive(path: Path) -> bool:
    return any(pattern.search(path.name) for pattern in SENSITIVE_PATTERNS)


def read_text(path: Path, findings: list[Finding]) -> str | None:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        add(findings, "error", "unreadable_utf8", f"Cannot read as UTF-8: {exc}", path)
        return None


def parse_frontmatter(text: str) -> tuple[dict[str, str], str] | None:
    match = re.match(r"\A---\s*\n(.*?)\n---\s*\n?(.*)\Z", text, re.DOTALL)
    if not match:
        return None
    fields: dict[str, str] = {}
    for raw_line in match.group(1).splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        field = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", raw_line)
        if field:
            fields[field.group(1)] = field.group(2).strip().strip('"\'')
    return fields, match.group(2)


def iter_text_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES and not is_sensitive(path):
            yield path


def normalized_body(skill_file: Path, findings: list[Finding]) -> str | None:
    text = read_text(skill_file, findings)
    if text is None:
        return None
    parsed = parse_frontmatter(text)
    if parsed is None:
        return None
    return "\n".join(line.rstrip() for line in parsed[1].strip().splitlines())


def audit(target: Path, compare_paths: list[Path]) -> dict[str, object]:
    target = target.resolve()
    findings: list[Finding] = []
    if not target.is_dir():
        add(findings, "error", "missing_directory", "Candidate directory does not exist.", target)
        return result(target, findings)

    skill_file = target / "SKILL.md"
    fields: dict[str, str] = {}
    body = ""
    if not skill_file.is_file():
        add(findings, "error", "missing_skill", "SKILL.md is required.", skill_file)
    else:
        text = read_text(skill_file, findings)
        if text is not None:
            parsed = parse_frontmatter(text)
            if parsed is None:
                add(findings, "error", "invalid_frontmatter", "Expected YAML frontmatter delimited by ---.", skill_file)
            else:
                fields, body = parsed
                for required in ("name", "description"):
                    if not fields.get(required):
                        add(findings, "error", f"missing_{required}", f"Frontmatter requires {required}.", skill_file)
                extras = sorted(set(fields) - {"name", "description"})
                if extras:
                    add(findings, "warning", "extra_frontmatter", f"Common candidate has extra fields: {', '.join(extras)}.", skill_file)
                name = fields.get("name", "")
                if name and (len(name) > 64 or not NAME_PATTERN.fullmatch(name)):
                    add(findings, "error", "invalid_name", "Name must be <=64 lowercase letters, digits, and hyphens.", skill_file)
                if name and name != target.name:
                    add(findings, "error", "folder_name_mismatch", f"Folder '{target.name}' does not match name '{name}'.", skill_file)
                if len(body.splitlines()) >= 500:
                    add(findings, "error", "body_too_long", "SKILL.md body must remain under 500 lines.", skill_file)

                for raw_link in LINK_PATTERN.findall(body):
                    link = raw_link.strip().split("#", 1)[0]
                    if not link:
                        continue
                    destination = (skill_file.parent / link).resolve()
                    try:
                        destination.relative_to(target)
                    except ValueError:
                        add(findings, "error", "link_escapes_candidate", f"Relative link leaves candidate: {raw_link}", skill_file)
                    else:
                        if not destination.exists():
                            add(findings, "error", "broken_link", f"Relative link does not resolve: {raw_link}", skill_file)

    for path in target.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(target)
        if path.name.lower() in BANNED_DOCS:
            add(findings, "error", "auxiliary_doc", "Runnable candidate contains an unnecessary auxiliary document.", relative)
        if is_sensitive(path):
            add(findings, "error", "sensitive_filename", "Sensitive-looking file is forbidden and was not read.", relative)
        if len(relative.parts) >= 3 and relative.parts[0] == "references":
            add(findings, "error", "nested_reference", "References must be one level deep.", relative)

    for path in iter_text_files(target):
        content = read_text(path, findings)
        if content is None:
            continue
        relative = path.relative_to(target)
        if relative.as_posix() != "scripts/audit_skill_candidate.py":
            for label, pattern in RISKY_COMMANDS.items():
                if pattern.search(content):
                    add(findings, "error", "risky_command", f"Detected {label} pattern.", relative)
        if re.search(r"(?:status|result_status|maturity)\s*[:=]\s*[\"']?VERIFIED_RESULT\b", content, re.IGNORECASE):
            add(findings, "warning", "status_overclaim", "File appears to assign VERIFIED_RESULT statically.", relative)

    openai_file = target / "agents" / "openai.yaml"
    if openai_file.is_file() and fields.get("name"):
        metadata = read_text(openai_file, findings)
        if metadata is not None:
            expected = f"${fields['name']}"
            prompt_match = re.search(r"^\s*default_prompt:\s*[\"']?(.*?)[\"']?\s*$", metadata, re.MULTILINE)
            if not prompt_match or expected not in prompt_match.group(1):
                add(findings, "error", "missing_explicit_prompt", f"default_prompt must mention {expected}.", openai_file.relative_to(target))
            if not re.search(r"^\s*allow_implicit_invocation:\s*false\s*$", metadata, re.MULTILINE):
                add(findings, "warning", "implicit_invocation", "Keep implicit invocation disabled until trigger evaluation passes.", openai_file.relative_to(target))

    if compare_paths and skill_file.is_file():
        candidate_body = normalized_body(skill_file, findings)
        for compare_path in compare_paths:
            other = compare_path / "SKILL.md" if compare_path.is_dir() else compare_path
            other_body = normalized_body(other.resolve(), findings)
            if candidate_body is not None and other_body is not None and candidate_body != other_body:
                add(findings, "error", "body_drift", f"Normalized body differs from {other}.", skill_file)

    return result(target, findings)


def result(target: Path, findings: list[Finding]) -> dict[str, object]:
    errors = sum(item.severity == "error" for item in findings)
    warnings = sum(item.severity == "warning" for item in findings)
    return {
        "candidate": target.as_posix(),
        "status": "pass" if errors == 0 else "fail",
        "errors": errors,
        "warnings": warnings,
        "findings": [asdict(item) for item in findings],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--compare-body", action="append", default=[], type=Path)
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()

    report = audit(args.candidate, args.compare_body)
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    print(rendered)
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(rendered + "\n", encoding="utf-8")
    return 0 if report["status"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
