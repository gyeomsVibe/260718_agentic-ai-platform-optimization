# 글로벌 룰 영문 정본

이 디렉터리는 노트북 환경의 Antigravity·Codex·Claude Code 전역 행동 규칙을 생성하는 단일 영문 정본(Source of Truth)이다. 규칙 본문과 도구별 어댑터는 영어로 관리하고, 사용자 고유 이름과 명시 호출 문구만 원문을 유지한다.

## 정본 구조

- `core.md`: 세 도구가 공유하는 영어 핵심 규칙
- `routes/vibe-check.md`: Vibe Check의 영어 라우팅과 원문 트리거
- `routes/repository-sync.md`: 자동 Git 동기화·명시형 handoff의 공통 안전 계약
- `adapters/`: 각 도구의 로딩·권한·컨텍스트 특성에 맞춘 영어 어댑터
- `dist/`: 세 도구에 장착되는 완성형 영어 정본
- `GLOBAL_RULES.ko.md`: 사용자가 읽는 통합 한글 해설본. 런타임에는 포함하지 않음
- `scripts/sync-global-rules.ps1`: 정본 생성, 백업, 장착, 정합성 검사
- `VERSION`: 정본 버전

MIA(Modular Intelligence Architect)는 별도 사용자 제작 Skill이므로 글로벌 룰에 포함하지 않는다. MIA의 발동과 전체 절차는 [`../../skills/custom/mia/`](../../skills/custom/mia/)에서 관리한다.

## 완성형 영문 정본과 장착 위치

| 도구 | 저장소 영문 정본 | 실제 장착 위치 |
|---|---|---|
| Antigravity | `dist/antigravity/GEMINI.md` | `~/.gemini/GEMINI.md` |
| Codex | `dist/codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| Claude Code | `dist/claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |

Antigravity의 글로벌 룰은 `~/.gemini/GEMINI.md` 하나만 사용한다. 과거 Vibe Check 보조 글로벌 룰이었던 `~/.gemini/config/AGENTS.md`가 발견되면 `Check`는 실패하고, `Apply`는 해당 파일을 백업한 뒤 제거한다. 상세 절차는 설치된 `vibe-check` 스킬과 프로젝트 범위 규칙에서 관리한다.

## 설계 기준

- Antigravity: 전역 `GEMINI.md`의 12,000자 제한과 IDE 권한·비작업공간 접근 경계를 지킨다.
- Codex: 전역 `AGENTS.md`, `AGENTS.override.md`, 프로젝트·경로 지침의 발견 우선순위를 보존한다.
- Claude Code: 항상 로드되는 `CLAUDE.md`를 200줄 이하로 유지하고 절차는 스킬로 분리한다.
- 공통: 짧고 명령형이며 검증 가능한 문장만 항상 로드하고, 장기 절차는 전용 스킬에 둔다.
- 중복 방지: 글로벌 룰은 도구별 한 개의 정본만 장착하고, 기능별 상세 절차를 별도 글로벌 파일로 중복 등록하지 않는다.
- 우선순위: 영문 정본은 P0 권한부터 P7 완료 보고 순서로 배치하고, 더 중요한 규칙을 먼저 읽게 한다.
- 강제 경계: Markdown은 행동 지침이다. 예외 없이 지켜야 하는 조건은 도구별 Permission·Hook·Sandbox·Policy로 구현한다.
- 번역본: 한글본은 사용자 검토용이며 `Canonical version`이 `VERSION`과 일치해야 한다.

공식 기준:

- [Antigravity IDE 규칙](https://antigravity.google/docs/ide-rules)
- [Antigravity IDE 설정](https://antigravity.google/docs/ide-settings)
- [OpenAI Codex AGENTS.md 안내](https://developers.openai.com/codex/guides/agents-md)
- [Claude Code 모범 사례](https://code.claude.com/docs/en/best-practices)
- [Claude Code 기능 개요](https://code.claude.com/docs/en/features-overview)

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
