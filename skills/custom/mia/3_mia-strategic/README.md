# MIA Strategic

> 사용자가 `MIA모드 발동`을 명시했을 때 기획, 비판, 실행, 검증을 순서대로 조율하는
> Claude Code·Codex·Antigravity 공용 Skill입니다. 이 폴더가 실행 로직의 정본입니다.

## 파일 소유권

| 경로 | 역할 | 직접 수정 |
|---|---|---|
| [`SKILL.md`](SKILL.md) | 세 플랫폼 공통 동작 정본 | 예 |
| [`agents/openai.yaml`](agents/openai.yaml) | Codex 표시명과 명시 발동 정책 | 필요할 때 |
| `CLAUDE-SKILL.md` | Claude Code용 생성 어댑터 | 아니요 |
| [`plugin/`](plugin/) | Antigravity 패키지와 동기화 도구 | 패키지 설정만 |
| `plugin/skills/mia-strategic/SKILL.md` | 플러그인에 포함되는 생성 복제본 | 아니요 |

동작을 바꾸려면 `SKILL.md`만 수정합니다. 생성본을 직접 고치면 다음 동기화에서
덮어써지거나 플랫폼별 동작이 어긋납니다.

## 발동 계약

- 사용자가 `MIA모드 발동`을 명시해야 시작합니다.
- `CRITIC`, `OPTIMIZE`, `DEEPDIVE` 같은 지시어만으로 MIA 전체 흐름을 자동 발동하지 않습니다.
- 실행 중에도 설치, 전역 배포, 외부 실행, 커밋, 푸시는 각각의 승인 경계를 따릅니다.

## 안전하게 수정하는 순서

1. `SKILL.md` 정본을 수정합니다.
2. 아래 `Check`로 정본과 생성본의 차이를 확인합니다.
3. 정적 검사와 필요한 런타임 평가를 실행합니다.
4. 배포 영향과 복구 방법을 설명한 뒤 승인받아 `Apply`를 실행합니다.
5. 새 작업에서 Available skills 노출과 명시 발동을 다시 확인합니다.

```powershell
../scripts/sync-mia-catalog.ps1 -Mode Check
```

`Check`는 파일을 바꾸지 않습니다. `Apply`는 사용자 홈의 전역 Skill과 플러그인 설치본을
바꾸므로 별도 승인 없이 실행하지 않습니다. 자세한 대상과 복구 경계는
[`plugin/README.md`](plugin/README.md)를 확인하세요.

## 검증 결과를 해석하는 법

- 정적 검사 통과는 문법과 구조가 맞다는 뜻입니다.
- 동기화 `Check` 통과는 정본과 배포본 내용이 일치한다는 뜻입니다.
- 실제 발견과 발동 성공은 새 작업에서 별도로 확인해야 합니다.

세 검사를 서로 대신할 수 없습니다.
