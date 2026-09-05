import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const script = resolve('codex/app-diagnostics/codex-sandbox-check.ps1');
const line = (errors = '[]', time = new Date().toISOString()) =>
  `[${time}] setup refresh: processed 3 write roots (read roots delegated); errors=${errors}`;
for (const [name, content, expected] of [
  ['fresh completed setup', () => line(), 0],
  ['latest failure', () => `${line()}\n${line('["access denied"]')}`, 1],
  ['spawn is not recovery', () => `${line('["access denied"]')}\n[${new Date().toISOString()}] setup refresh: spawning helper`, 1],
  ['stale success is unknown', () => line('[]', '2020-01-01T00:00:00Z'), 2],
  ['empty log is unknown', () => '', 2],
  ['quoted success is not evidence', () => `command output: ${line()}`, 2],
  ['invalid errors cannot pass', () => line('{broken'), 2],
  ['later valid setup has limited success', () => `${line('["error"]', new Date(Date.now()-1000).toISOString())}\n${line()}`, 0],
]) {
  test(name, () => {
    const dir = mkdtempSync(join(tmpdir(), 'sandbox-check-test-'));
    try {
      const log = join(dir, 'fixture.log');
      writeFileSync(log, content());
      const run = spawnSync('pwsh', ['-NoProfile', '-File', script, '-LogPath', log], {encoding:'utf8'});
      assert.equal(run.status, expected, run.stderr || run.stdout);
      assert.equal(JSON.parse(run.stdout).ExitCode, expected);
    } finally {
      // Only this uniquely created fixture directory, never user data.
      rmSync(dir, {recursive:true, force:true});
    }
  });
}
