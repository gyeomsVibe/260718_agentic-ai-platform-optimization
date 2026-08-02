# MIA 플러그인 패키지

> 이 폴더는 `mia-strategic`을 플랫폼에 전달하는 패키지입니다. 실행 로직의 정본은
> 상위 [`../SKILL.md`](../SKILL.md)이며, 플러그인 내부의 `SKILL.md`는 생성된 배포본입니다.

## 가장 중요한 규칙

`skills/mia-strategic/SKILL.md`를 직접 수정하지 마세요. 동작 변경은 반드시
[`../SKILL.md`](../SKILL.md)에서 시작하고 동기화 스크립트로 생성본을 갱신합니다.

## 정본과 생성본

| 경로 | 역할 | 직접 수정 |
|---|---|---|
| `../SKILL.md` | 세 플랫폼 공통 실행 정본 | 예 |
| `../agents/openai.yaml` | Codex 표시·발동 메타데이터 | 필요할 때 |
| `../CLAUDE-SKILL.md` | Claude Code용 생성 어댑터 | 아니요 |
| `skills/mia-strategic/SKILL.md` | 플러그인에 포함되는 생성 복제본 | 아니요 |
| `.claude-plugin/`, `.codex-plugin/` | 플랫폼 패키지 메타데이터 | 패키지 변경 시 |
| `scripts/sync-mia-skills.ps1` | 카탈로그 동기화 도구로 위임하는 호환 래퍼 | 아니요 |

## 먼저 확인만 하기

저장소 루트에서 다음 명령을 실행합니다.

```powershell
./skills/custom/mia/scripts/sync-mia-catalog.ps1 -Mode Check
```

`Check`는 파일을 쓰지 않습니다. 정본, 생성본, 현재 전역 설치본이 같은지 비교하고
불일치가 있으면 실패 코드와 대상 경로를 보여 줍니다. 불일치는 배포가 필요하다는 뜻이지,
자동으로 배포해도 된다는 뜻이 아닙니다.

## 승인 후 배포하기

```powershell
./skills/custom/mia/scripts/sync-mia-catalog.ps1 -Mode Apply
```

`Apply`는 다음 위치를 갱신할 수 있습니다.

- 저장소 안의 Claude 어댑터와 플러그인 패키지 복제본
- Codex, Claude Code, Antigravity가 읽는 사용자 홈의 전역 설치본

따라서 실행 전에 변경 대상, 복구 방법, 전역 배포 승인을 확인해야 합니다. 저장소 문서만
수정하는 작업에는 `Apply`가 필요하지 않습니다.

카탈로그 `Apply`는 새 플러그인 배포를 먼저 만든 뒤 기존 `plan-review-execute` 및
Antigravity 독립 `mia-strategic` 설치본을 백업하고 제거해 중복 발동을 막습니다.

## 변경과 검증 순서

1. 상위 `SKILL.md` 정본을 수정합니다.
2. `Check`로 차이를 확인합니다.
3. 정적 검사와 평가를 통과시킵니다.
4. 전역 배포 승인을 받은 뒤 `Apply`를 실행합니다.
5. 다시 `Check`를 실행합니다.
6. 새 작업에서 Skill 발견과 `MIA모드 발동` 동작을 확인합니다.

파일 일치만으로 런타임 성공을 주장하지 않습니다. 발견, 명시 발동, 안전 거부, 작업 품질은
각각 별도의 런타임 증거가 필요합니다.
