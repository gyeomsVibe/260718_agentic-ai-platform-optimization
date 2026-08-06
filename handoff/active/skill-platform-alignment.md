---
handoff_id: skill-platform-alignment-20260805
status: VALIDATED
workstream: skill-platform-alignment
objective: 3대 도구의 Skill 배포를 실측 기반으로 정렬하고 최엄격 규격 게이트를 상시화한다
repository: gyeomsVibe/260718_agentic-ai-platform-optimization
branch: main
base_sha: 0cf6f73bf7f69d3755e1b61f384de26b9b15350e
work_sha: 00af0b331642ee1cd22a3cd550ae0a65e1d56baa
owned_paths:
  - README.md
  - package.json
  - claude/README.md
  - claude/plugins.md
  - claude/agents/
  - skills/README.md
  - skills/MANUAL.md
  - skills/DEPLOYMENT.md
  - skills/external/README.md
  - skills/external/eli-kardis/
  - skills/custom/legacy-harness/
  - skills/custom/mia/AUTHORING_HANDBOOK.md
  - skills/custom/mia/scripts/audit-skill-roots.py
  - skills/research/MIA_SKILLS_EXPLORATION_2026-07-19.md
completed:
  - 워크스페이스 최상위 .agents 전수분석 - 외부 패키지 eli-kardis/vibe-coding-skills 사본임을 확인하고 반입 계약에 STATIC_REVIEWED 로 등록
  - 배포본 11개 SKILL.md 의 Claude→Codex 일괄 치환 오염 원복 - 150/150 해시 일치
  - Claude Code 서브에이전트 12개 중 4개 선별 정제 배포 - 죽은 프런트매터 60줄 제거, 허위 능력 주장 제거
  - audit-skill-roots.py 신설 - 9개 루트를 Codex 엄격 YAML 파서로 전수 감사, npm run check 편입
  - 3대 도구 CLI 실측으로 스킬 루트 매핑 확정 - ~/.agents/skills 는 공용이 아니라 Codex 전용
  - 전역 CLAUDE.md 가 지시하는 vibe-check 스킬을 Claude Code 가 볼 수 없던 상태 복구
  - 초보자용 Skill 사용 매뉴얼과 도구별 배포 정본 신설
  - mia-vaccine-test 오발동 수정 - 백신 테스트 해줘 가 발동하던 것을 정본 description 음성 가드로 차단하고 양성 트리거 유지 확인 (dbfb2b6)
  - bc9a700 포트폴리오 슬림화 - 파일 기반 SKILL.md 127→43 개, 삭제 0 개로 백업 격리
  - 명시 트리거 17개 문구 / 9개 스킬 발동 검증 (배치 A B C)
  - accidental-data-loss-prevention 행동 검증 3/3 통과 - 격리 fixture 에서 발동과 중단·영향설명·승인요청을 분리 측정, fixture 해시 불변
  - skill-repair 항목 종결 - 발동 실패 관측이 bc9a700 의 4개 루트 전면 제외 판정과 일치, 백업 4곳 보존
  - 검증 원장 skills/research/trigger-verification-2026-08.json 신설 - 증거 등급 3단계 분리
remaining:
  - Codex 새 세션 런타임 재확인 - bc9a700 시점 네트워크 차단으로 미수행
  - Antigravity 새 세션 런타임 재확인 - bc9a700 시점 미로그인 인증 오류로 미수행
  - 감사 경고 - Codex 루트 openai.yaml 부재와 벤더 관리 science 플러그인
  - 오발동 측정 - 목록 노출과 적절한 시점 발동은 다른 명제다. 실사용 관측 필요
  - claude/plugins.md 의 superpowers 2종이 언제 왜 사라졌는지 원인 미확인
  - Codex 앱 커넥터 11종 제거 실패 - uninstall_plugin 핸들러 부재
verification:
  - npm run check - exit 0
  - npm run skills:audit - 오류 0건 exit 0
  - npm run handoff:check - exit 0
  - 항체 변이 테스트 - 사용자 루트 결함 주입 exit 1, 벤더 루트 exit 0, 대조군 exit 0
  - claude -p 지목 확인 - 신규 스킬 8/8 있음, 서브에이전트 4/4 인식
  - agy --print 지목 확인 - 신규 스킬 3/3 있음
  - codex exec - failed to load skill 0건
  - 문서 내부 링크 - 깨진 링크 0건
  - 트리거 발동 - 명시 17개 문구 PASS, 오발동 방어 2건 PASS, 자동 안전 3건 PASS
  - accidental-data-loss-prevention fixture 부작용 - 파일 3개 SHA-256 불변, 신규 파일 0건
decisions:
  - superpowers 재설치 No-Go - 14개 스킬 중 12개가 이미 커버되고 mia-strategic·test-writer 와 트리거 충돌
  - 통일 대상을 배포 집합이 아니라 규격으로 전환 - 42개를 전 도구에 배포하면 목록 비대화로 오발동 증가
  - 벤더 관리 루트는 오류가 아니라 경고 - 사용자가 고칠 수 없고 플러그인 갱신 때 되돌아간다
  - 한국어 이용약관 템플릿은 창작하지 않고 0바이트 감지 시 중단하는 가드로 처리
risks:
  - 정본 3벌 분산 - claude/antigravity/codex-agents 배포본을 한쪽만 고치면 2026-05-28 드리프트 사고가 재발한다. 수정 시 ~/.agents/skills 를 원본으로 삼아 세 곳에 함께 반영하고 npm run skills:audit 실행
  - 매뉴얼의 미검증 트리거 - 스킬 설명에서 뽑은 것이라 안 걸릴 수 있다. 이름 직접 호출이 확실한 우회로
  - 감사기는 사용자 홈 경로에 의존 - 다른 PC에서는 루트가 없어 건너뛴다. 이 노트북(MSI GL75) 기준이며 데스크톱에 그대로 적용하지 않는다
approvals_required:
  - 전역 설치 및 플러그인 재설치
  - git push --force 와 히스토리 재작성
  - 다른 저장소로의 push
next_action: Codex 와 Antigravity 의 새 세션 런타임을 재확인한다. codex exec 와 agy --print 로 각각 스킬 목록을 나열시켜 bc9a700 슬림화 이후의 실제 인식 개수를 확인하고, 결과를 skills/research/trigger-verification-2026-08.json 의 open_items 에 반영한다. 네트워크나 로그인 문제로 실패하면 원인을 기록하고 중단한다
revalidate_when:
  - Claude Code Codex Antigravity 중 하나라도 버전이 올라가 스킬 경로나 프런트매터 지원 필드가 바뀐 경우
  - npm run skills:audit 가 오류를 보고하는 경우
  - ~/.agents/skills 또는 각 도구 스킬 루트의 파일이 이 세션 이후 변경된 경우
---

# 3대 도구 Skill 정렬과 최엄격 규격 게이트 상시화

이 레코드는 `work_sha`에서 검증된 결과와 다음 행동 한 가지를 전달합니다.

## 완료 근거

주장은 모두 실행 결과와 연결됩니다.

| 주장 | 근거 |
|---|---|
| 배포본 오염 원복 | 스테이징↔배포본 MD5 전수 비교 150/150 일치, `.Codex` 잔존 0건 |
| 서브에이전트 배포 | `claude -p` 신규 세션이 4개 전부 나열 |
| 스킬 선별 배포 | `claude -p`·`agy --print` 지목 확인 8/8, 3/3 |
| 루트 매핑 확정 | 세 도구 CLI 스킬 목록 대조 — `~/.agents/skills` 40개가 Claude·Antigravity 에서 0개 |
| 감사 게이트 | 변이 4종 주입 시 exit 1, 대조군 exit 0 |
| 트리거 검증 3건 | `stream-json` 의 `"name":"Skill"` 호출 로그 |

## 남은 위험

**정본이 세 벌로 나뉘어 있습니다.** `~/.claude/skills`, `~/.gemini/config/skills`,
`~/.agents/skills` 에 같은 스킬의 사본이 각자 존재합니다. 한쪽만 고치면 드리프트가 생기며,
2026-05-28에 실제로 그 사고가 났습니다
([SOURCE.md 5절](../../skills/external/eli-kardis/vibe-coding-skills/SOURCE.md)).

복구 절차: 정본(`skills/` 아래)을 고친 뒤 대상 도구에 재배포하고
`npm run skills:audit` 로 오류 0건을 확인합니다. 배포본을 직접 고치지 않습니다.

**Codex·Antigravity 런타임이 미확인입니다.** `bc9a700` 슬림화 이후 세 도구 중
Claude Code 만 실제 발동을 확인했습니다. 나머지 둘은 네트워크 차단과 미로그인으로
검증에 실패했고, 파일 배치가 맞는다는 사실을 발동 성공으로 바꿔 말하지 않습니다.

**증거 등급이 비대칭입니다.** 명시 트리거 17건은 실행 확인만 있고 원시 로그가 없습니다.
자동 안전 3건만 구조화 보존돼 있습니다. 같은 등급으로 취급하지 마세요 —
[검증 원장](../../skills/research/trigger-verification-2026-08.json)의 `evidence_level` 이 정본입니다.

## 시험 설계에서 배운 것

`accidental-data-loss-prevention` 은 2026-08-05에 **빈 폴더**에서 시험해 발동하지 않았고,
그것을 방어 공백으로 의심했습니다. 2026-08-06에 스키마·마이그레이션 파일이 있는 격리
fixture 로 다시 시험하자 **3/3 발동**했습니다.

안전장치는 **보호할 대상이 있을 때만** 개입합니다. 빈 환경에서의 미발동을 결함으로 읽으면
안 됩니다. 시험 환경이 실제 위험을 재현하는지 먼저 확인하세요.

## 수신자 재개 절차

```powershell
npm run handoff:check          # 기준점 재검증
npm run skills:audit           # 배포 상태 재확인 (기대: 오류 0건)
```

두 명령이 통과하면 `next_action` 한 가지를 실행합니다.
