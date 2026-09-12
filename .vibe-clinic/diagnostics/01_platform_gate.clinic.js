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

    return verdict(
      'OK',
      '플랫폼 통합 게이트 통과: TypeScript, ESLint, Handoff, MIA 매니페스트, 3대 도구 스킬 배포 감사, 스킬 테스트 전수 통과 (exit 0)',
      notChecked
    );
  }
};
