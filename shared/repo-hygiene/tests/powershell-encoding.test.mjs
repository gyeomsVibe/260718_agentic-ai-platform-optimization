// 저장소 전체 PowerShell 인코딩 항체
//
// Windows PowerShell 5.1 은 BOM 없는 UTF-8 을 CP949 로 읽는다. pwsh 7 은 정상으로 읽어서
// 한쪽 환경에서만 확인하면 결함이 숨는다. 2026-08-02 ~ 2026-09-13 사이 같은 유형이
// 파일을 바꿔 가며 네 번 반복됐다. 파일 하나씩 고치는 대신 유형 전체를 여기서 막는다.

import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

const repoRoot = path.resolve(import.meta.dirname, '../../..');

function trackedPowerShellFiles() {
  const out = execFileSync('git', ['-c', 'core.quotepath=false', 'ls-files', '-z', '--', '*.ps1'], {
    cwd: repoRoot,
    encoding: 'utf8'
  });
  return out
    .split('\0')
    .filter(Boolean)
    .filter((rel) => existsSync(path.join(repoRoot, rel)));
}

// 한글만이 아니다. 5.1 은 BOM 없는 UTF-8 의 비ASCII 바이트 전체를 CP949 로 해석하므로
// 스크립트에 흔한 —, →, ·, 이모지 한 글자도 같은 사고를 낸다. (2026-09-13 검사 범위 확대)
const NON_ASCII = /[^\x00-\x7F﻿]/;

// 5.1 에서 인코딩을 생략하면 기본값이 ANSI(Set-Content·Add-Content) 또는 UTF-16LE(Out-File)이라
// 비ASCII 를 쓰면 깨지거나, 다른 도구가 읽지 못하는 파일이 된다.
const WRITE_CMDLETS = /\b(Set-Content|Add-Content|Out-File)\b/i;

function codeLines(rel) {
  return readFileSync(path.join(repoRoot, rel), 'utf8')
    .split(/\r?\n/)
    .map((line, index) => ({ code: line.replace(/(^|\s)#.*$/, '$1'), number: index + 1 }));
}

test('추적 중인 PowerShell 스크립트가 하나 이상 있다 (검사 대상 확인)', () => {
  assert.ok(trackedPowerShellFiles().length > 0, 'git ls-files 가 .ps1 을 찾지 못했다 - 검사가 공회전한다');
});

test('비ASCII 문자가 든 추적 .ps1 은 UTF-8 BOM 을 가진다', () => {
  const offenders = trackedPowerShellFiles().filter((rel) => {
    const bytes = readFileSync(path.join(repoRoot, rel));
    const hasBom = bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf;
    return NON_ASCII.test(bytes.toString('utf8')) && !hasBom;
  });
  assert.deepEqual(
    offenders,
    [],
    `BOM 없는 비ASCII .ps1 (PowerShell 5.1 이 CP949 로 오독한다):\n  ${offenders.join('\n  ')}`
  );
});

test('Set-Content·Add-Content·Out-File 는 -Encoding 을 지정한다', () => {
  const offenders = [];
  for (const rel of trackedPowerShellFiles()) {
    for (const { code, number } of codeLines(rel)) {
      if (WRITE_CMDLETS.test(code) && !/-Encoding\b/i.test(code)) {
        offenders.push(`${rel}:${number}`);
      }
    }
  }
  assert.deepEqual(
    offenders,
    [],
    `인코딩 미지정 파일 쓰기 (5.1 기본값은 ANSI 또는 UTF-16LE 라 비ASCII 가 깨진다):\n  ${offenders.join('\n  ')}`
  );
});

test('Get-Content 를 인코딩 지정 없이 ConvertFrom-Json 에 넘기지 않는다', () => {
  const offenders = [];
  for (const rel of trackedPowerShellFiles()) {
    const lines = readFileSync(path.join(repoRoot, rel), 'utf8').split(/\r?\n/);
    lines.forEach((line, index) => {
      const code = line.replace(/#.*$/, '');
      if (/Get-Content\b/i.test(code) && /ConvertFrom-Json\b/i.test(code) && !/-Encoding\b/i.test(code)) {
        offenders.push(`${rel}:${index + 1}`);
      }
    });
  }
  assert.deepEqual(
    offenders,
    [],
    `인코딩 미지정 JSON 읽기 (5.1 에서 한글이 CP949 로 오독된다. 예외 없이 깨진 값으로 조용히 읽히거나, ` +
      `JSON 이 망가져 -ErrorAction 으로도 막히지 않는 예외가 난다):\n  ${offenders.join('\n  ')}`
  );
});
