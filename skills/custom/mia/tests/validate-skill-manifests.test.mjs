import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import path from 'node:path';

const rootDir = path.resolve(import.meta.dirname, '../../../../');
const validatorScript = path.resolve(import.meta.dirname, '../scripts/validate-skill-manifests.py');

test('validate-skill-manifests.py clean run passes with exit code 0', () => {
  const output = execFileSync('python', [validatorScript], {
    cwd: rootDir,
    encoding: 'utf8',
    env: { ...process.env, PYTHONIOENCODING: 'utf-8' }
  });
  assert.ok(!output.includes('ERROR'));
  assert.ok(output.includes('0건') || output.includes('0'));
});
