"""Mutation tests for the MIA Skill Compiler promotion preflight.

The tests copy the candidate into an OS temporary directory, inject one defect,
and verify that the read-only preflight rejects it. No canonical or installed
skill file is changed.
"""

from __future__ import annotations

import importlib.util
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


sys.dont_write_bytecode = True

EVAL_DIR = Path(__file__).resolve().parent
WORKBENCH = EVAL_DIR.parents[1]
CANDIDATE = WORKBENCH / "candidates" / "mia-skill-compiler"
PREFLIGHT = CANDIDATE / "scripts" / "preflight_skill_promotion.py"


def load_preflight():
    spec = importlib.util.spec_from_file_location("promotion_preflight", PREFLIGHT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load preflight script: {PREFLIGHT}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


PREFLIGHT_MODULE = load_preflight()


class PromotionPreflightMutationTests(unittest.TestCase):
    def mutate(self, relative_path: str, content: str) -> dict[str, object]:
        with tempfile.TemporaryDirectory(prefix="mia-skill-compiler-mutation-") as temp:
            mutant = Path(temp) / "mia-skill-compiler"
            shutil.copytree(CANDIDATE, mutant)
            target = mutant / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
            return PREFLIGHT_MODULE.audit_candidate(
                mutant, None, "absent", None
            )

    def assert_blocked(self, result: dict[str, object], code: str) -> None:
        findings = result["findings"]
        self.assertEqual("fail", result["status"])
        self.assertIn(code, {finding["code"] for finding in findings})

    def test_baseline_candidate_passes(self) -> None:
        result = PREFLIGHT_MODULE.audit_candidate(CANDIDATE, None, "absent", None)
        self.assertEqual("pass", result["status"])
        self.assertEqual([], result["findings"])

    def test_blocks_sensitive_filename(self) -> None:
        result = self.mutate("references/.env", "TOKEN=not-a-real-token\n")
        self.assert_blocked(result, "sensitive_filename")

    def test_blocks_broken_relative_link(self) -> None:
        result = self.mutate("references/injected.md", "[missing](missing.md)\n")
        self.assert_blocked(result, "broken_link")

    def test_blocks_powershell_recursive_force_removal(self) -> None:
        result = self.mutate(
            "scripts/injected.ps1", "Remove-Item -Recurse -Force C:\\temporary-target\n"
        )
        self.assert_blocked(result, "risky_command")

    def test_blocks_powershell_force_before_recurse(self) -> None:
        result = self.mutate(
            "scripts/injected.ps1", "Remove-Item -Force -Recurse C:\\temporary-target\n"
        )
        self.assert_blocked(result, "risky_command")

    def test_blocks_cmd_recursive_removal(self) -> None:
        result = self.mutate("scripts/injected.cmd", "rmdir /s /q C:\\temporary-target\n")
        self.assert_blocked(result, "risky_command")

    def test_blocks_modified_installation_manifest(self) -> None:
        with tempfile.TemporaryDirectory(prefix="mia-skill-compiler-target-") as temp:
            target_root = Path(temp) / "install-root"
            target = target_root / "mia-skill-compiler"
            shutil.copytree(CANDIDATE, target)
            skill_file = target / "SKILL.md"
            skill_file.write_text(
                skill_file.read_text(encoding="utf-8") + "\nUnexpected change.\n",
                encoding="utf-8",
            )
            result = PREFLIGHT_MODULE.audit_candidate(
                CANDIDATE, target, "required", target_root
            )
            self.assert_blocked(result, "target_manifest_mismatch")


if __name__ == "__main__":
    unittest.main(verbosity=2)
