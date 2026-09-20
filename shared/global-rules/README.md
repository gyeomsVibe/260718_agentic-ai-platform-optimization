# 글로벌 룰 영문 정본

이 디렉터리는 Antigravity·Codex의 전역 행동 규칙을 생성하는 단일 영문 정본(Source of Truth)이다. v4.0.0부터 항상 로드되는 규칙을 약 40줄로 줄였다.

## 정본 구조

- `core.md`: 두 도구가 공유하는 경량 핵심 규칙(소통·안전·소유권·검증·보고·범위)
- `adapters/`: 도구별 2~3줄 어댑터(Codex 지휘, Antigravity 작업자)
- `dist/`: 세 도구에 장착되는 생성본
- `GLOBAL_RULES.ko.md`: 사용자 열람용 한글 해설본. 런타임에는 포함하지 않음
- `scripts/sync-global-rules.ps1`: 생성, 백업, 장착, 정합성 검사
- `tests/`: 오프라인 행동 픽스처와 A/B 측정 스키마
- `VERSION`: 정본 버전

MIA(Modular Intelligence Architect)는 별도 사용자 제작 Skill이므로 글로벌 룰에 포함하지 않는다. [`../../skills/custom/mia/`](../../skills/custom/mia/)에서 관리한다.

## 완성형 영문 정본과 장착 위치

| 도구 | 저장소 영문 정본 | 실제 장착 위치 |
|---|---|---|
| Antigravity | `dist/antigravity/GEMINI.md` | `~/.gemini/GEMINI.md` |
| Codex | `dist/codex/AGENTS.md` | `~/.codex/AGENTS.md` |

Antigravity의 글로벌 룰은 `~/.gemini/GEMINI.md` 하나만 사용한다. 과거 보조 글로벌 룰 `~/.gemini/config/AGENTS.md`가 발견되면 `Check`는 실패하고 `Apply`는 백업 후 제거한다.

## 설계 기준

- 항상 로드되는 규칙은 짧게 유지한다. 규칙이 길수록 각 규칙의 준수율이 떨어진다.
- 코드를 읽으면 알 수 있는 내용, 모델 기본 동작과 겹치는 일반론, 측정되지 않은 최적화 이론은 넣지 않는다.
- 특정 저장소 전용 역할·호출문·진단 워크플로는 해당 저장소 규칙이나 스킬에 둔다.
- Markdown은 행동 지침이다. 예외 없이 지켜야 하는 조건은 도구별 Permission·Hook·Sandbox·Policy로 강제한다.
- `Check`는 필수 제목 순서, 소통·안전·검증 필수 문구, 규칙 줄 중복, 한글본 버전, 오프라인 픽스처 계약을 검사한다.
- 한글본은 사용자 검토용이며 `Canonical version`이 `VERSION`과 일치해야 한다.

공식 기준:

- [Antigravity IDE 규칙](https://antigravity.google/docs/ide-rules)
- [Antigravity IDE 설정](https://antigravity.google/docs/ide-settings)
- [OpenAI Codex AGENTS.md 안내](https://developers.openai.com/codex/guides/agents-md)

## 운영

```powershell
# 저장소 영문 정본과 실제 장착본의 일치 여부 확인
./scripts/sync-global-rules.ps1 -Mode Check

# 실제 사용자 홈을 건드리지 않고 저장소의 완성형 영문 정본만 다시 생성
./scripts/sync-global-rules.ps1 -Mode Build

# 현재 장착본을 사용자 홈에 백업하고 영문 정본 생성·장착
./scripts/sync-global-rules.ps1 -Mode Apply
```

규칙을 변경할 때는 `dist/`나 실제 장착 파일을 직접 편집하지 않는다. `core.md`, `routes/`, `adapters/`를 수정하고 `VERSION`을 올린 뒤 `Build`로 저장소 정본을 확인한다. 실제 사용자 홈에 적용할 때만 `Apply`를 사용한다.

`Check`는 LF와 CRLF의 줄바꿈 차이를 정규화해 비교한다. 따라서 실제 내용이 같은데 운영체제 줄바꿈만 달라서 동기화 실패로 오인하지 않는다. 또한 P0~P7 순서, 한글본 버전, 정본의 완전 중복 규칙, `Repository synchronization` 섹션 수를 검사한다.

## 한글본 백업

v1.0.0 한글 장착본 세 개는 사용자 홈의 `~/.agent-global-rules-backups/ko-v1.0.0-20260714-231721/`에 각각 보존한다.
