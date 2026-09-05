# Codex 앱 진단

## 현재 진입점

```powershell
pwsh -NoProfile -File codex/app-diagnostics/codex-sandbox-check.ps1 -ProbeWorkspaceWrite
```

- 종료 코드 0: 요청한 검사만 통과. 모든 작업이나 경로가 정상이라는 뜻은 아니다.
- 종료 코드 1: 최신 setup 오류 또는 실제 파일 접근 실패.
- 종료 코드 2: 로그 누락·파싱 불가·오래된 증거로 판단 불가.
- 기본 로그 신선도는 10분. `-MaxAgeMinutes`로 바꿀 수 있으나 오래된 기록을 현재 정상의 증거로 쓰지 않는다.
- 쓰기 검사는 이 스크립트 폴더에 고유한 임시 파일 하나를 만들고 쓰고 읽은 후 닫을 때 제거한다.
  `-ProbeWorkspaceWrite`를 생략하면 로그만 읽는다.
- `-Interactive`는 호환 인수로 남겼지만 자동 ACL 복구를 실행하지 않는다.
- 자격증명 파일 읽기, 토큰 저장 방식 변경, 고정 버전 앱 해시 검사, 전체 재귀 ACL 복구는 진단에서 제거했다.

`C:\tmp` ACL 실패를 겪은 이 환경에는 사용자 설정에
`[sandbox_workspace_write]`와 `exclude_slash_tmp = true`가 적용되어 있다. 이 값은
`C:\tmp`만 쓰기 루트에서 제외한다. 네트워크·`%TEMP%`·Git 보호를 넓히지 않는다.

## 실패별 다음 행동

| 증상 | 분류 | 다음 행동 |
|---|---|---|
| `.git/index.lock` 접근 거부 | 보호된 Git 메타데이터 | 승인된 Git 쓰기는 처음부터 플랫폼의 외부 실행 승인 경로 사용. DENY 제거 금지 |
| `write ACE failed on ...` | setup 권한 설정 실패 | 정확한 대상과 현재 실행 시각 확인. 드라이브 루트를 작업 폴더로 사용하지 않음 |
| WMI/CIM 접근 거부 | 명령별 권한 차이 | OS 버전만 필요하면 `Test-CodexCommandAccess.ps1` 기본 조회 사용 |
| Git ignore 읽기 거부 | 사용자 설정 경로 접근 차이 | 승인된 읽기 전용 비교로 확인. ignore를 빈 파일로 대체하지 않음 |
| push 후 오류 | 원격/로컬 결과 분리 필요 | 재시도 전에 `git ls-remote`로 원격 SHA 확인. 추적 ref만으로 판정하지 않음 |
| pre-push 훅 거부 | 저장소 운영 승인 | 샌드박스 복구로 취급하지 않음. 훅 수정·비활성화 금지 |

네트워크·보호 경로 접근은 각 플랫폼의 정식 승인 절차를 따른다. 이 문서는 실행 권한을 부여하지 않는다.
실패가 확인된 동일 명령을 승인 없이 다른 도구로 우회 실행하지 않는다.

## 검증과 조사

```powershell
node --test codex/app-diagnostics/tests/sandbox-check.test.mjs
```

- [LTSC 및 GitHub 근거와 검증 기록](LTSC_COMMAND_ACCESS_2026-09-05.md)
- [OS 명령별 접근 조회](Test-CodexCommandAccess.ps1)
- [현재 진단기](codex-sandbox-check.ps1)

## 과거 사건 기록

다음 기록은 각 사건의 당시 조건에만 적용한다. 현재 실패 대상으로 확인되지 않은 경로에 적용하지 않는다.

- [C:\tmp 사건](ROOT_CAUSE_c-tmp-write-root_2026-07-22.md)
- [초기 ACL 복구 보고서](<1.Codex 샌드박스 오류 및 미리보기 난제 검증 완료 보고서 (Walkthrough).md>)
- [기존 ACL 배치](fix-sandbox-acl.bat): 전체 소유권·권한을 바꾸므로 일반 진단 후 자동 실행하지 않는다.
- [DB 손상 진단](ROOT_CAUSE_db-malformed_2026-07-26.md) / [DB 도구](codex-db-doctor.py)
- [다운로드 사건 인계](HANDOFF_CLAUDE_CODE_CODEX_DOWNLOAD_FIX_2026-07-19.md)
