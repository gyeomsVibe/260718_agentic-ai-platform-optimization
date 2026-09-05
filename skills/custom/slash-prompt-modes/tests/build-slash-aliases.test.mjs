import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const script = path.resolve(
  import.meta.dirname,
  '../scripts/build-slash-aliases.ps1'
);
const commandScript = path.resolve(
  import.meta.dirname,
  '../scripts/build-claude-uppercase-commands.ps1'
);
const manifestPath = path.resolve(
  import.meta.dirname,
  '../references/mode-manifest.json'
);

test('별칭 10개가 실제 토큰과 MIT 메타데이터를 포함한다', () => {
  const outputRoot = mkdtempSync(path.join(tmpdir(), 'slash-aliases-'));
  try {
    const result = spawnSync(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, '-OutputRoot', outputRoot],
      { encoding: 'utf8' }
    );
    assert.equal(result.status, 0, `stdout:\n${result.stdout}\nstderr:\n${result.stderr}`);

    const expected = new Map([
      ['selfrefine', '/SELFREFINE'],
      ['redteam', '/REDTEAM'],
      ['eli10', '/ELI10'],
      ['deepdive', '/DEEPDIVE'],
      ['alt3', '/ALT3'],
      ['critic', '/CRITIC'],
      ['optimize', '/OPTIMIZE'],
      ['stepbystep', '/STEPBYSTEP'],
      ['expert', '/EXPERT'],
      ['structured', '/STRUCTURED FEW-SHOT']
    ]);

    for (const [name, token] of expected) {
      const text = readFileSync(path.join(outputRoot, name, 'SKILL.md'), 'utf8');
      const licenseText = readFileSync(path.join(outputRoot, name, 'LICENSE.md'), 'utf8');
      assert.ok(text.includes(`license: MIT`), `${name}: license 누락`);
      assert.ok(licenseText.startsWith('MIT License'), `${name}: MIT 원문 누락`);
      assert.ok(text.includes(`\`${token}\``), `${name}: 모드 토큰 누락`);
      assert.ok(text.includes('즉시 적용할 최소 계약:'), `${name}: 자급형 최소 계약 누락`);
      assert.ok(!text.includes('System.Collections.Hashtable.Token'), `${name}: 보간 잔재`);
      assert.ok(!text.includes('$('), `${name}: 미해석 PowerShell 표현식`);
    }
  } finally {
    rmSync(outputRoot, { recursive: true, force: true });
  }
});

test('하나의 모드 매니페스트가 Claude 대문자 command와 별칭 계약을 함께 생성한다', () => {
  const outputRoot = mkdtempSync(path.join(tmpdir(), 'slash-commands-'));
  try {
    const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
    const result = spawnSync(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', commandScript, '-OutputRoot', outputRoot],
      { encoding: 'utf8' }
    );
    assert.equal(result.status, 0, `stdout:\n${result.stdout}\nstderr:\n${result.stderr}`);
    assert.equal(manifest.length, 10);

    for (const mode of manifest) {
      const commandName = mode.name.toUpperCase();
      const text = readFileSync(path.join(outputRoot, `${commandName}.md`), 'utf8');
      assert.ok(text.includes(mode.token), `${commandName}: 정본 토큰 누락`);
      assert.ok(text.includes(mode.contract), `${commandName}: 공통 매니페스트 계약 누락`);
    }

    const structured = readFileSync(path.join(outputRoot, 'STRUCTURED.md'), 'utf8');
    assert.ok(structured.includes('축약하지 않는다'), 'STRUCTURED: 두 단어 정본 보존 규칙 누락');
  } finally {
    rmSync(outputRoot, { recursive: true, force: true });
  }
});
