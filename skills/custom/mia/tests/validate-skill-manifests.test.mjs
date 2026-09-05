// validate-skill-manifests.py 회귀 테스트 (항체)
//
// 배경: 2026-08-02 백신테스트에서 변이 B1(필수키 가드 무력화)·B2(한국어 무결성
// 가드 무력화)가 살아남았다. 이후 작성된 1차 항체는 "정상 입력에서 exit 0" 만
// 확인해, 가드를 통째로 제거해도 그대로 통과했다. 실측으로 재확인됨.
//
// 따라서 이 항체는 반대 방향을 검증한다: 검증기가 결함을 실제로 "잡아내는가".
// 각 테스트는 대응하는 변이를 죽인다.

import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

const validatorScript = path.resolve(import.meta.dirname, '../scripts/validate-skill-manifests.py');

const OPENAI_YAML = [
  'interface:',
  '  display_name: "테스트"',
  '  short_description: "테스트용"',
  '  default_prompt: "테스트"',
  'policy:',
  '  allow_implicit_invocation: false',
  ''
].join('\n');

function skillMd(name, description, license = 'MIT') {
  return `---\nname: ${name}\ndescription: ${description}\nlicense: ${license}\n---\n\n# ${name}\n`;
}

/** 정상 카탈로그 픽스처를 만든다. overrides 로 특정 파일만 오염시킨다. */
function makeCatalog(overrides = {}) {
  const root = mkdtempSync(path.join(tmpdir(), 'mia-fixture-'));
  writeFileSync(path.join(root, 'LICENSE.md'), 'MIT License\n\nfixture only\n', 'utf8');

  const skills = {
    'mia-skill-compiler': path.join(root, '1_mia-skill-compiler', 'candidates', 'mia-skill-compiler'),
    'mia-vaccine-test': path.join(root, '2_mia-vaccine-test'),
    'mia-strategic': path.join(root, '3_mia-strategic')
  };

  for (const [name, dir] of Object.entries(skills)) {
    mkdirSync(path.join(dir, 'agents'), { recursive: true });
    const desc = overrides[`${name}/description`] ?? `${name} 설명. MIA모드 발동 으로 전략 실행.`;
    writeFileSync(path.join(dir, 'SKILL.md'), skillMd(name, desc), 'utf8');
    writeFileSync(path.join(dir, 'agents', 'openai.yaml'), OPENAI_YAML, 'utf8');
  }

  // 생성본 2종
  const genDesc = overrides['generated/description'] ?? 'MIA모드 발동 으로 시작하는 전략 절차.';
  writeFileSync(
    path.join(skills['mia-strategic'], 'CLAUDE-SKILL.md'),
    skillMd('mia-strategic', genDesc),
    'utf8'
  );
  const pluginDir = path.join(skills['mia-strategic'], 'plugin', 'skills', 'mia-strategic');
  mkdirSync(pluginDir, { recursive: true });
  writeFileSync(path.join(pluginDir, 'SKILL.md'), skillMd('mia-strategic', genDesc), 'utf8');

  return { root, skills };
}

function runValidator(catalogRoot) {
  return spawnSync('python', [validatorScript, '--catalog', catalogRoot], {
    encoding: 'utf8',
    env: { ...process.env, PYTHONIOENCODING: 'utf-8' }
  });
}

function withCatalog(overrides, fn) {
  const fixture = makeCatalog(overrides);
  try {
    fn(fixture);
  } finally {
    rmSync(fixture.root, { recursive: true, force: true });
  }
}

test('정상 카탈로그는 통과한다 (exit 0, ERROR 없음)', () => {
  withCatalog({}, ({ root }) => {
    const r = runValidator(root);
    assert.equal(r.status, 0, `stdout:\n${r.stdout}`);
    assert.ok(!r.stdout.includes('ERROR'), r.stdout);
  });
});

test('[B1 변이 사살] description 이 비면 오류로 잡는다', () => {
  withCatalog({ 'mia-strategic/description': '' }, ({ root }) => {
    const r = runValidator(root);
    assert.equal(r.status, 1, `가드가 무력화되면 여기서 0 이 나온다.\nstdout:\n${r.stdout}`);
    assert.ok(r.stdout.includes('ERROR'), r.stdout);
    assert.ok(r.stdout.includes('description'), r.stdout);
  });
});

test('[B2 변이 사살] 생성본 한국어가 손상되면 오류로 잡는다', () => {
  // mojibake 흉내: 한국어 트리거가 사라진 상태
  withCatalog({ 'generated/description': 'MIA ??? ?? mojibake placeholder' }, ({ root }) => {
    const r = runValidator(root);
    assert.equal(r.status, 1, `한국어 무결성 가드가 무력화되면 0 이 나온다.\nstdout:\n${r.stdout}`);
    assert.ok(r.stdout.includes('ERROR'), r.stdout);
    assert.ok(r.stdout.includes('생성본'), r.stdout);
  });
});

test('[YAML 엄격 파싱] 인용 스칼라 조기 종료를 오류로 잡는다', () => {
  // 2026-08-02 에 Codex 가 스킬 로딩을 거부했던 실제 결함 패턴
  withCatalog({ 'mia-strategic/description': "'MIA 전략절차' 스킬 — 뒤에 오는 텍스트" }, ({ root }) => {
    const r = runValidator(root);
    assert.equal(r.status, 1, `엄격 파서 가드가 없으면 0 이 나온다.\nstdout:\n${r.stdout}`);
    assert.ok(r.stdout.includes('ERROR'), r.stdout);
  });
});

test('[BOM 가드] 배포 스크립트에 BOM 이 없으면 오류로 잡는다', () => {
  // 2026-08-02 재발: BOM 이 빠지자 PowerShell 5.1 이 CP949 로 읽어
  // claude/mia-strategic 생성물이 정본과 어긋났다. pwsh(7)로만 돌리면 은폐된다.
  withCatalog({}, ({ root }) => {
    const scriptsDir = path.join(root, 'scripts');
    mkdirSync(scriptsDir, { recursive: true });
    const target = path.join(scriptsDir, 'sync-mia-catalog.ps1');

    // BOM 있는 정상본 → 통과
    writeFileSync(target, '﻿# 한국어 주석\n', 'utf8');
    assert.equal(runValidator(root).status, 0);

    // BOM 없는 상태 → 반드시 잡아야 한다
    writeFileSync(target, '# 한국어 주석\n', 'utf8');
    const r = runValidator(root);
    assert.equal(r.status, 1, `BOM 가드가 무력화되면 0 이 나온다.\nstdout:\n${r.stdout}`);
    assert.ok(r.stdout.includes('BOM'), r.stdout);
  });
});

test('[name 계약] SKILL.md name 이 폴더명과 다르면 오류로 잡는다', () => {
  withCatalog({}, ({ root, skills }) => {
    writeFileSync(
      path.join(skills['mia-vaccine-test'], 'SKILL.md'),
      skillMd('엉뚱한이름', 'MIA모드 발동 전략 설명'),
      'utf8'
    );
    const r = runValidator(root);
    assert.equal(r.status, 1, `stdout:\n${r.stdout}`);
    assert.ok(r.stdout.includes('폴더 계약'), r.stdout);
  });
});

test('[license 계약] MIA Skill의 license 누락을 오류로 잡는다', () => {
  withCatalog({}, ({ root, skills }) => {
    writeFileSync(
      path.join(skills['mia-skill-compiler'], 'SKILL.md'),
      '---\nname: mia-skill-compiler\ndescription: MIA모드 발동 전략 설명\n---\n',
      'utf8'
    );
    const r = runValidator(root);
    assert.equal(r.status, 1, `stdout:\n${r.stdout}`);
    assert.ok(r.stdout.includes('license'), r.stdout);
  });
});
