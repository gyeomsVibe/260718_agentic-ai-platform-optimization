# 260718_agentic-ai-platform-optimization

Claude Code / Codex / Antigravity 세 플랫폼의 최적화·유지관리 워크스페이스.
플랫폼별 작업은 `claude/`, `codex/`, `antigravity/` 폴더에서 관리한다.

## Skill 분류 원칙

- Skill 정본, 후보, 플러그인 패키지, 평가 근거는 모두 `skills/` 아래에서 관리한다.
- 윤겸스가 직접 설계·소유하는 MIA 시리즈는 `skills/custom/mia/`에 둔다.
- 외부에서 가져와 정제하는 Skill은 `skills/external/<publisher>/<skill-name>/`에 두고
  `SOURCE.md`에 원본, 라이선스, 버전, 변경 이력을 기록한다.
- `shared/`나 플랫폼 폴더에 Skill 정본을 중복 배치하지 않는다. 이전 경로는 평가·이관
  증거의 `historical_path`로만 보존한다.

## 저장소 동기화 원칙

- **상시 자동 동기화 (2026-07-20 상시 위임)**: 이 워크스페이스에서 파일을 변경하면,
  별도 지시가 없어도 작업 마무리 시 검증 → 커밋 → `git push`까지 자동 수행해 GitHub
  원격(main)과 동기 상태를 유지한다. push는 이 저장소에 한해 상시 승인된 것으로 본다.
- 커밋 전 점검: `npm run check`(있을 때)를 통과시키고, 비밀정보(쿠키·토큰·`.env`·키)와
  대용량 바이너리는 `.gitignore`로 반드시 제외한 뒤 스테이징한다.
- 커밋은 의미 단위로 나누고 Conventional Commits로 작성한다. 커밋 안 된 변경이나
  미푸시 커밋을 남긴 채 세션을 끝내지 않는다.
- **동기화 범위 밖(별도 승인 필요)**: 전역 Skill 설치, 배포, 계정·권한·외부 서비스 변경,
  다른 저장소로의 push는 상시 위임에 포함되지 않는다. 영향과 복구 방법을 설명한 뒤
  개별 승인을 받는다. `git push --force`·히스토리 재작성 등 되돌리기 어려운 작업도 별도 승인.

## NotebookLM MCP 운영 수칙

이 워크스페이스에는 `notebooklm-mcp` MCP 서버(jacob-bd/notebooklm-mcp-cli, 쿠키+내부 API 방식)가
세 플랫폼 공용으로 연결되어 있다. MCP 관련 자료는 모두 `mcp/` 섹션에서 관리한다.
상세 설계: `mcp/notebooklm/MIA_NOTEBOOKLM_MCP_OPTIMIZATION_2026-07-19.md`

- **캐시 우선**: NotebookLM에 질의하기 전에 `mcp/notebooklm/research-vault/`를 먼저 검색하고,
  새 답변은 그 폴더의 `README.md` 형식으로 저장한다. (무료 쿼터 50쿼리/일)
- **적재적소**: 로컬 파일은 직접 읽는다. NotebookLM은 외부 문서 코퍼스 질의,
  웹 리서치 축적, 오디오/비디오 생성에만 사용한다.
- **인증 만료 시** (2~4주 주기): `nlm login` 재실행. 이 PC는 Chrome이 RUNASADMIN
  플래그라 실행 불가 → `auth.browser=edge` 설정 유지 (Edge로 로그인).
- **파손 시 복구 순서**: ① `nlm login` 재실행 → ② `uv tool upgrade notebooklm-mcp-cli`
  → ③ 예비 서버(PleasePrompto `npx notebooklm-mcp@latest`)로 전환.
- **업그레이드 주의**: NotebookLM UI/API 개편 뉴스 후 24~72시간 기다렸다가 업그레이드.
