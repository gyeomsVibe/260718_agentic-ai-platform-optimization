# Windows Codex sandbox 재발 방지 조사 기록

대상: Windows 11 Enterprise LTSC에서 Codex workspace-write를 사용하는 운영자
작성일: 2026-09-05
범위: `C:\tmp` ACL 초기화 실패의 재발 방지와 일반 워크스페이스 파일 작업 검증

## 결론

Windows 11 Enterprise LTSC 자체가 이번 샌드박스 실패의 근본 원인이라는 증거는 없다.
원인은 workspace-write가 `C:\tmp`를 쓰기 루트로 포함할 때 ACL 설정이 거부되는 경로였다.
사용자 설정에 `exclude_slash_tmp = true`를 명시하고 실제 `:workspace` 프로필에서
파일 생성·읽기·삭제를 검증해 이 경로를 차단했다.

## 적용 범위와 가정

- 호스트 설정은 `C:\Users\Kimyoongyeom\.codex\config.toml`이다.
- 성공은 일반 작업 파일의 편집·검사·빌드가 workspace-write에서 완료되는 것으로 정의한다.
- `.git`, `.agents`, `.codex`는 Codex가 문서화한 재귀 읽기 전용 보호 경계이므로 Git 메타데이터
  쓰기 실패를 일반 파일 샌드박스 실패와 혼동하지 않는다.

## 근거와 결정

1. 공개 Codex 소스는 `[sandbox_workspace_write]`의 `exclude_slash_tmp` 기본값을 `false`로
   둔다. Windows에서 `/tmp`가 `C:\tmp`로 대응될 수 있으므로, 과거의
   `SetNamedSecurityInfoW failed: 5` 경로를 피하려면 값을 명시해야 한다.
2. Codex의 Windows 샌드박스 문서는 elevated sandbox를 권장한다. 이 호스트는 이미
   `sandbox = "elevated"`이므로 unelevated 모드로 낮추지 않았다.
3. Codex 보안 문서는 workspace-write에서도 `.git`, `.agents`, `.codex`를 보호 대상으로
   둔다. 이 경계를 해제하면 보안 모델을 약화하므로 해결책으로 채택하지 않았다.
4. 공개 이슈는 `C:\tmp` ACL 실패 및 Git 쓰기 거부와 유사한 증상을 보고하지만, 이 호스트의
   결론은 설정 확인과 실제 실행 증거에 한정했다.

## 검증 기록

- 호스트 설정에 `[sandbox_workspace_write]`와 `exclude_slash_tmp = true`가 존재한다.
- `codex sandbox -P :workspace`에서 워크스페이스의 고유 검사 파일을 생성·쓰기·읽기·삭제했다.
- 검사 뒤 고유 파일은 0개였다.
- 새 샌드박스 setup 기록은 2~3개 쓰기 루트와 `errors=[]`를 보였다.

## 한계와 운영 지침

`codex doctor`를 이미 샌드박스 내부에서 실행하면 별도 오프라인 프로필을 읽을 수 있다.
따라서 호스트 설정의 판정은 이 명령 하나가 아니라 설정값, 실제 `:workspace` 실행, 새 setup
기록을 함께 사용한다. Git 메타데이터 변경은 보호 경계를 우회하지 말고 Codex의 정식 승인
경로로 수행한다. 되돌리려면 추가한 `[sandbox_workspace_write]` 섹션의 두 줄을 삭제한다.

## 출처 원장

| 용도 | 출처 | 신뢰도 |
| --- | --- | --- |
| Windows sandbox 권장 모드 | [OpenAI Windows sandbox 문서](https://learn.chatgpt.com/docs/windows/windows-sandbox) | 공식 문서 |
| 보호 경계 정의 | [OpenAI approvals and security 문서](https://learn.chatgpt.com/docs/agent-approvals-security) | 공식 문서 |
| Windows 보호 경계 구현·검증 | [openai/codex PR #17365](https://github.com/openai/codex/pull/17365) | 공개 소스 변경 |
| `C:\tmp` ACL 실패 유사 사례 | [openai/codex issue #33806](https://github.com/openai/codex/issues/33806) | 사용자 보고, 보조 근거 |
| Git 쓰기 거부 유사 사례 | [openai/codex issue #32880](https://github.com/openai/codex/issues/32880) | 사용자 보고, 보조 근거 |
