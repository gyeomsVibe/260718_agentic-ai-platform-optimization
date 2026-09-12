const path = require('path');
const { run, verdict } = require('./_shared');

module.exports = {
  id: 'platform-gate',
  name: '01 플랫폼 통합 게이트 검증 (npm run check)',
  layer: 'SYSTEM',

  async run(ctx) {
    const root = ctx.projectDir || ctx.cwd;
    const r = run('npm run check', root);

    const notChecked = '원격 네트워크 라이브 실행, 실제 모델 API 과금, 외부 제3자 서비스 상태';

    if (!r.ok) {
      const snippet = (r.out || r.err || '원인 불명').split('\n').slice(-10).join('\n');
      return verdict(
        'ERROR',
        `npm run check 실패 (종료 코드: ${r.code}).\n세부 출력 요약:\n${snippet}`,
        notChecked
      );
    }

    // exit 0 은 "오류 없음"일 뿐 "경고 없음"이 아니다.
    // 종료 코드만 보면 skills:audit 이 경고 20건을 찍어도 OK 로 보고되어,
    // 그 OK 가 "모든 경고가 해소됐다"는 상위 보고로 세탁된다. (2026-09-12 감사)
    // 따라서 audit-skill-roots.py 가 소유한 요약줄을 읽어 경고를 그대로 드러낸다.
    const summary = /결과:\s*오류\s*(\d+)건\s*\/\s*경고\s*(\d+)건(?:\s*\/\s*설명 불일치\s*(\d+)건)?/.exec(r.out || '');

    if (!summary) {
      // 요약줄을 못 찾으면 조용히 통과시키지 않는다. 침묵이 곧 이 결함의 원인이었다.
      return verdict(
        'WARN',
        'npm run check 는 exit 0 이지만 skills:audit 요약줄을 찾지 못해 경고 수를 확인할 수 없습니다. ' +
          'audit-skill-roots.py 의 출력 형식이 바뀌었는지 확인하세요.',
        notChecked
      );
    }

    const [, errCount, warnCount, driftCount] = summary;
    const warnings = Number(warnCount);
    const drift = Number(driftCount || 0);

    if (warnings > 0 || drift > 0) {
      return verdict(
        'WARN',
        `플랫폼 통합 게이트 통과(exit 0)이나 미해소 경고가 남아 있습니다: ` +
          `스킬 루트 감사 경고 ${warnings}건, 설명 불일치 ${drift}건 (오류 ${errCount}건). ` +
          `세부는 npm run skills:audit 로 확인하세요. 경고가 0이 되기 전에는 "전수 통과"로 보고하지 마세요.`,
        notChecked
      );
    }

    return verdict(
      'OK',
      '플랫폼 통합 게이트 통과: TypeScript, ESLint, Handoff, MIA 매니페스트, 3대 도구 스킬 배포 감사, 스킬 테스트 전수 통과 (exit 0, 경고 0건)',
      notChecked
    );
  }
};
