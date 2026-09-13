// skills/ 섹션 문서 보관소 단일화 항체
//
// 배경: 2026-09-11 대화에서 skills/research/ 가 생겨 보고서가 skills/docs/ 와 두 곳에
// 흩어졌고, 같은 보고서가 양쪽에 바이트 동일하게 복사되기까지 했다. 2026-09-13에
// 모두 skills/docs/ 로 통합했다. 문서 보관소가 다시 둘로 갈라지면 여기서 실패한다.

import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

const skillsRoot = path.resolve(import.meta.dirname, '../../..');
const docsRoot = path.join(skillsRoot, 'docs');

// skills/ 바로 아래에 문서만 담는 폴더를 새로 만들면 안 된다.
const FORBIDDEN_DOC_FOLDERS = ['research', 'reports', 'report', 'analysis', 'notes', 'documents'];

test('skills/ 아래에 docs 외 문서 보관 폴더가 없다', () => {
  const found = FORBIDDEN_DOC_FOLDERS.filter((name) => existsSync(path.join(skillsRoot, name)));
  assert.deepEqual(found, [], `문서는 skills/docs/ 에만 둔다. 발견된 폴더: ${found.join(', ')}`);
});

test('skills/docs 의 모든 문서가 README 목차에 등재돼 있고 링크가 살아 있다', () => {
  const readme = readFileSync(path.join(docsRoot, 'README.md'), 'utf8');
  const files = readdirSync(docsRoot).filter((name) => name !== 'README.md');

  const unlisted = files.filter((name) => !readme.includes(`](${name})`));
  assert.deepEqual(unlisted, [], `목차에 없는 문서: ${unlisted.join(', ')}`);

  const links = [...readme.matchAll(/\]\(([^)#]+\.(?:md|json))\)/g)].map((m) => decodeURIComponent(m[1]));
  const broken = links.filter((rel) => !existsSync(path.join(docsRoot, rel)));
  assert.deepEqual(broken, [], `깨진 목차 링크: ${broken.join(', ')}`);

  const outside = links.filter((rel) => rel.startsWith('..'));
  assert.deepEqual(outside, [], `목차가 docs 밖을 가리킨다: ${outside.join(', ')}`);
});

test('skills/docs 파일명에 공백이나 대괄호가 없다', () => {
  const bad = readdirSync(docsRoot).filter((name) => /[\s[\]]/.test(name));
  assert.deepEqual(bad, [], `공백·대괄호 파일명: ${bad.join(', ')}`);
});
