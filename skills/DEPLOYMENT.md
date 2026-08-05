# 도구별 Skill 배포 정본

> 어느 Skill을 어느 도구에 올렸고 **왜 그렇게 정했는지**의 정본입니다.
> 규격·검증 절차는 [`custom/mia/AUTHORING_HANDBOOK.md`](custom/mia/AUTHORING_HANDBOOK.md)가,
> 외부 반입 출처는 [`external/`](external/)이 정본입니다.
>
> 최종 갱신: 2026-08-05 (3대 도구 CLI 실측 + 선별 배포 완료)

## 1. 대원칙 — 전부 다 올리지 않는다

**스킬이 많을수록 목록 컨텍스트가 커지고 오발동이 늘어난다.** 저장소가 2026-07-19부터
지켜 온 원칙이다. 따라서 배포 판단은 세 질문을 통과해야 한다.

1. **실사용 근거가 있는가** — 워크스페이스 실측 기준. 취향이나 "있으면 좋을 것" 은 근거가 아니다
2. **그 도구가 이미 덮지 못하는가** — 내장 명령·기존 스킬·서브에이전트와 중복이면 올리지 않는다
3. **트리거가 충돌하지 않는가** — 같은 요청에 두 경로가 경쟁하면 둘 다 신뢰할 수 없어진다

## 2. 도구별 루트 (2026-08-05 실측 확정)

**공용 경로는 없다.** 세 도구 CLI에 각각 스킬 목록을 나열시켜 확인했다.

| 도구 | 읽는 루트 | 확인 명령 |
|---|---|---|
| Claude Code | `~/.claude/skills` | `claude -p` |
| Codex | `~/.codex/skills` + `~/.agents/skills` | `codex exec` |
| Antigravity | `~/.gemini/config/skills`, `~/.gemini/skills`, `~/.gemini/config/plugins/*/skills` | `agy --print` |

`~/.agents/skills` 는 오래 "3대 도구 공용" 으로 문서화됐으나 **Codex 전용**이다.
Claude Code·Antigravity 는 이 경로의 40개 중 **0개**를 인식한다.

## 3. 실사용 패턴 (2026-08-05 실측)

배포 근거로 쓴 수치다. 추정이 아니다.

| 지표 | 값 |
|---|---|
| 최근 30일 수정 파일 | `.md` **666** · `.png` 700 · `.json` 345 · `.js` 206 · `.py` 58 · `.ps1` 49 · `.jsx` 49 |
| 활성 프로젝트 6종의 구성 | 전부 문서(md 4~138) + React 3/6 + Python 3/6 |
| package.json 39개 중 | react 11 · vitest 7 · next 4 · express 4 · **supabase 0 · playwright 0 · docker 0** |
| 도구 사용량 | Codex 세션 44 · Claude Code 프로젝트 2 · Antigravity 대화 12 |

**결론: 문서 작성이 1순위, React 웹앱과 Python 스크립트가 2순위, 스킬·에이전트 엔지니어링이
상시 배경.** 인프라(Docker/K8s/Terraform)와 Supabase, E2E 는 실사용 근거가 없다.

## 4. 최적화 배포 결과

2026-08-05 REDTEAM 전수조사로 파일 기반 Skill을 **127개 → 43개**로 정리했다.
상세한 개별 판정과 웹 근거는
[`research/MIA_SKILL_PORTFOLIO_REDTEAM_2026-08-05.md`](research/MIA_SKILL_PORTFOLIO_REDTEAM_2026-08-05.md)가 정본이다.

| 도구 | 정리 전 | 정리 후 | 유지 기준 |
|---|---:|---:|---|
| Claude Code | 11 | **10** | 문서·Python·UX·MIA·안전 최소층 |
| Codex 전역 파일 | 50 | **20** | `.agents/skills` 10 + `.codex/skills` 10 |
| Antigravity | 66 | **13** | config 12 + MIA 플러그인 1 |

### Claude Code 10

`accidental-data-loss-prevention`, `error-path-analysis`, MIA 3종, `product-thinking`,
`python-refactor`, `vibe-check`, `web-design-guidelines`, `writing-guidelines`.

### Codex 20

- `.agents/skills` 10: 안전, 에러 UX, 프론트엔드 디자인, Python 의존성/리팩터링,
  제품 사고, React 성능, 진단, 웹 감사, 글쓰기.
- `.codex/skills` 10: Codex 시스템·제작 Skill 6, `hatch-pet`, MIA 3종.
- 프로젝트 `.agents/skills/mia-strategic`은 저장소 범위 어댑터라 전역본과 별도로 유지한다.

### Antigravity 13

- `~/.gemini/config/skills` 12: Codex 공통 최소층에서 MIA 전략절차를 제외한 구성.
- `~/.gemini/config/plugins/mia-modular-intelligence-architect` 1: `mia-strategic`.
- 레거시 `~/.gemini/skills`, `~/.gemini/antigravity-ide/skills`는 중복본을 모두 격리해 0개다.

## 5. 격리 기준과 복구

격리 대상은 다음 중 하나 이상에 해당했다.

1. 내장 기능·다른 Skill·서브에이전트와 트리거가 겹침.
2. 최근 작업·프로젝트 의존성에서 사용 근거가 없음.
3. 상류·라이선스·실행 계약이 불명확하거나 현재 도구와 맞지 않음.
4. SAFE-SYNC·권한·부작용 규칙과 경쟁함.
5. 다른 활성 루트와 SHA-256이 같은 물리 중복본임.

삭제는 0개다. 격리한 `SKILL.md` 84개는 아래 백업에 있다.

`C:\Users\Kimyoongyeom\.mia-skill-backups\20260805-redteam-optimization-01`

필요한 Skill만 백업의 도구별 하위 구조를 따라 원래 경로로 되돌린다. 전체 일괄 복구는
중복과 오발동을 다시 만든다.

## 6. 검증 결과 (2026-08-05)

| 검사 | 결과 |
|---|---|
| 이동 preflight·사후 경로 확인 | **46/46 통과** |
| 파일 기반 활성 수 | **127 → 43** |
| 엄격 감사 `npm run skills:audit` | **exit 0**, 오류 0·경고 11 |
| `npm run check` | **exit 0**, 전체 게이트 통과 |
| Claude Code 새 세션 | **미통과** — 180초 타임아웃(exit 124) |
| Antigravity 새 세션 | **미통과** — 로그 권한·미로그인 인증 타임아웃(exit 1) |
| Codex 새 세션 | **미통과** — WebSocket/HTTPS 네트워크 차단(exit 1) |

파일 구조와 해시가 맞는다는 사실을 런타임 발동 성공으로 바꿔 말하지 않는다. 인증·네트워크가
정상인 다음 새 세션에서 도구별 목록 확인이 남아 있다.

## 7. 남은 위험

- **Codex 앱 플러그인**: 사용 근거가 없는 커넥터 11종 제거 호출이 모두
  `No handler registered for tool: uninstall_plugin`으로 실패했다. 캐시를 직접 지우지 않았다.
- **Claude 자동발동**: 지금은 10개로 작지만, 수동 전용 워크플로가 생기면
  `disable-model-invocation: true` 또는 `skillOverrides`로 목록 문맥에서 숨긴다.
- **배포본 드리프트**: 정본은 `skills/` 아래다. 사용자 홈 배포본을 직접 고치지 말고 정본 수정 →
  대상 도구 재배포 → `npm run skills:audit` 순서를 지킨다.
