# plan-review-execute

MIA의 기획·검토·실행·검증 흐름을 제공하는 세 플랫폼 공용 Skill의 유일한 편집 정본입니다.

- `SKILL.md`: 공통 동작 정본. 사용자가 `MIA모드 발동`을 명시할 때만 시작합니다.
- `agents/openai.yaml`: Codex 표시명과 명시 발동 정책입니다.
- `CLAUDE-SKILL.md`: Claude Code용 어댑터입니다. 동기화 스크립트가 공통 정본에서 만듭니다.

플러그인 패키지와 실제 설치본을 확인하려면 다음 명령을 실행합니다. `Check`는 파일을
바꾸지 않습니다.

```powershell
plugin/scripts/sync-mia-skills.ps1 -Mode Check
```

`Apply`는 전역 Skill·플러그인 설치본을 바꾸므로 별도 승인이 있을 때만 사용합니다.
