# 플랫폼 Agent Skill 계약

## 공통 정본

- 산출물은 GPT 챗봇이 아니라 Antigravity·Claude Code·Codex용 Agent Skill입니다.
- 공통 정본은 폴더 이름과 일치하는 `name`, 명확한 `description`을 가진 `SKILL.md`입니다.
- 세부 지식은 `references/`, 반복 가능 실행은 `scripts/`, 정적 자원은 `assets/`에 둡니다.
- 플랫폼 전용 메타데이터는 공통 지침을 복제하지 않는 얇은 어댑터로 관리합니다.
- 설치 경로와 지원 필드는 제품 버전에 따라 바뀔 수 있으므로 실제 설치 직전에 공식 문서와 현재 런타임을 다시 확인합니다.

## Codex

- 프로젝트 범위 후보는 `.agents/skills/<name>/`를 우선합니다.
- 사용자 범위 설치는 `~/.codex/skills/<name>/`를 사용합니다.
- 표시 정보와 기본 호출문은 필요할 때 `agents/openai.yaml`에 두고, 기본 호출문에는 `$<name>`을 포함합니다.
- 파일이 존재한다는 사실과 Available skills에서 발견된 사실을 구분합니다.

## Claude Code

- 프로젝트 범위는 `.claude/skills/<name>/`, 사용자 범위는 `~/.claude/skills/<name>/`를 사용합니다.
- 직접 호출은 `/skill-name` 형식을 평가합니다.
- Claude 전용 프런트매터가 필요하면 배포 단계에서 파생 어댑터에만 추가하고 공통 정본을 플랫폼 종속 필드로 채우지 않습니다.

## Antigravity

- 프로젝트 범위는 `.agents/skills/<name>/`를 우선합니다.
- 전역 경로 표기가 공식 자료와 버전 사이에서 다를 수 있으므로 고정값으로 가정하지 않습니다. 설치 직전에 현재 Antigravity 문서와 실제 검색 경로를 확인합니다.
- 규칙 파일이나 단순 복사를 Skill 발견 성공으로 간주하지 않습니다.

## 플랫폼별 검증

플랫폼마다 다음 상태를 별도로 기록하세요.

1. 설치 대상과 원본 해시가 일치합니다.
2. 새 작업 또는 재시작된 환경의 Available skills에 이름이 보입니다.
3. 명시 호출이 발동하고 일반 요청에는 과도하게 발동하지 않습니다.
4. 핵심 작업, 불완전 입력, 오류 복구와 안전 거부가 계약대로 동작합니다.
5. 무-Skill 기준선과 가장 가까운 대안보다 측정 가능한 가치가 있습니다.

한 플랫폼의 성공을 다른 플랫폼에 상속하지 마세요. 세 플랫폼 모두 통과하기 전에는 `cross_platform_verified`를 선언하지 마세요.

## 확인 근거

- Codex: 현재 설치된 공식 `skill-creator` 계약과 현재 Available skills 런타임을 우선합니다.
- Claude Code: `https://code.claude.com/docs/en/slash-commands`
- Antigravity: `https://codelabs.developers.google.com/getting-started-with-antigravity-skills` 및 `https://codelabs.developers.google.com/antigravity/how-to-create-agent-skills-for-antigravity-cli`
- 교차 플랫폼 개요: `https://developers.google.com/admob/android/next-gen/agent-skills`

이 근거는 2026-07-20에 확인했습니다. 설치 직전에는 경로와 지원 필드를 다시 확인하세요.
