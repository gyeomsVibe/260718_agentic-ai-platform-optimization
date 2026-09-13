import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readdirSync, readFileSync, rmSync } from 'node:fs';
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

      // 명시 호출 전용 계약은 Codex 어댑터 정책으로도 강제돼야 한다.
      // openai.yaml 이 없으면 Codex 는 자동 선택을 기본 허용해 계약과 반대로 동작한다.
      const adapter = readFileSync(path.join(outputRoot, name, 'agents', 'openai.yaml'), 'utf8');
      assert.match(adapter, /^\s*allow_implicit_invocation:\s*false\s*$/m, `${name}: 암묵 발동 차단 누락`);
      assert.ok(adapter.includes(`$${name}`), `${name}: 기본 호출문에 $${name} 누락`);
      assert.ok(adapter.includes(token), `${name}: 표시 정보에 토큰 누락`);
      assert.ok(!adapter.includes('$('), `${name}: 어댑터 보간 잔재`);
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

    // 스크립트 본문에 박힌 한글 문구가 온전해야 한다. 매니페스트에서 오는 한글은 .NET 이
    // UTF-8 로 읽어 항상 멀쩡하므로, 그것만 확인하면 BOM 이 빠져 Windows PowerShell 5.1 이
    // 스크립트 자체를 CP949 로 오독하는 사고를 놓친다. (2026-09-13 재배포 회귀)
    for (const mode of manifest) {
      const text = readFileSync(path.join(outputRoot, `${mode.name.toUpperCase()}.md`), 'utf8');
      assert.ok(text.includes('대문자 호환 어댑터'), `${mode.name}: 스크립트 고정 한글 손상(BOM 누락 의심)`);
      assert.ok(text.includes('사용자 작업:'), `${mode.name}: 스크립트 고정 한글 손상(BOM 누락 의심)`);
    }
  } finally {
    rmSync(outputRoot, { recursive: true, force: true });
  }
});

test('한글이 든 slash-prompt-modes 스크립트는 UTF-8 BOM 을 가진다', () => {
  const scriptsDir = path.resolve(import.meta.dirname, '../scripts');
  const offenders = readdirSync(scriptsDir)
    .filter((name) => name.endsWith('.ps1'))
    .filter((name) => {
      const bytes = readFileSync(path.join(scriptsDir, name));
      const hasBom = bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf;
      return /[가-힣]/.test(bytes.toString('utf8')) && !hasBom;
    });
  assert.deepEqual(offenders, [], `BOM 없는 한글 스크립트: ${offenders.join(', ')}`);
});
