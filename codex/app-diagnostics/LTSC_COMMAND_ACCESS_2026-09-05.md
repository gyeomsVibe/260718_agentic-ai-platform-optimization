# Windows 11 LTSC 명령별 접근 진단

## 판정과 범위

Windows 11 Enterprise LTSC 2024 (EnterpriseS, 24H2, 26100.8875)를 실측했다.
LTSC 자체가 반복 거부의 근본원인이라는 증거는 확보되지 않았다. LTSC 고유의
호환성 또는 이 장치의 보안 정책이 기여할 가능성까지 배제한 것은 아니다.

동일한 `Get-CimInstance Win32_OperatingSystem` 조회가 샌드박스 안에서는 접근
거부, 승인된 밖의 실행에서는 성공했다. 이는 실행 컨텍스트에 따른 접근 차이의
증거다. 어느 WMI ACL, 토큰 권한 또는 조직 정책이 최종적으로 거부했는지는 미확인이다.
레지스트리의 OS 버전 필드 조회는 샌드박스 안에서 성공했다.

## 앞선 진단에 대한 비판

- `setup refresh ... errors=[]`는 초기화 결과다. 개별 명령이나 앱 전체의 성공을 보증하지 않는다.
- 8월 24일 기록의 실패 대상은 `D:\`였다. 과거 `C:\tmp` 사례를 모든 접근 거부에 적용하면 안 된다.
- 기존 진단기는 그룹 이름 포함 여부를 유효 접근 권한으로 취급하고, 감지한 오류에
  명시적 비영 종료 코드를 반환하지 않는다. 이를 전체 정상 판정에 사용하지 않는다.
- 기존 진단기의 인증 파일 검사와 재귀 ACL 복구는 이번 조사에 실행하지 않았다.

## GitHub 대조 조사와 수정 (2026-09-05 후속)

대상은 이 로컬 Windows 작업의 반복 거부와 잘못된 복구 루프다. 공개 PR은 구현 의도의
근거, 이슈는 제보자의 관측으로 구분했다. 설치된 Desktop 빌드와 공개 커밋의 정확한
대응은 검증하지 않았다. LTSC 전용 결함은 이번 검색에서 입증하지 못했다.

| 근거 | 주장과 적용 한계 |
|---|---|
| [OpenAI PR #17365](https://github.com/openai/codex/pull/17365), 2026-04-13 병합 | elevated/unelevated 모두 .git 등의 쓰기를 보호하도록 구현·검증. 전면 ACL 허용 및 unelevated 전환을 Git 해결책으로 삼을 수 없음 |
| [OpenAI 이슈 #32880](https://github.com/openai/codex/issues/32880), 2026-07-13 제보 | Windows 11 Git 메타데이터 거부와 외부 실행 성공, 원격 push 성공 뒤 로컬 ref 실패 보고. 현재 PC가 같은 Desktop 회귀를 겪었다는 증거는 아님 |
| [OpenAI 이슈 #33806](https://github.com/openai/codex/issues/33806), 2026-09-05 열람 | C:\tmp가 setup 전체를 막는 사례. 현재 관측된 일반 파일 쓰기 성공과는 다름 |
| [OpenAI 이슈 #21304](https://github.com/openai/codex/issues/21304), 2026-09-05 열람 | 유사 Git 거부 제보. 이슈 제목만으로 제품 결함 확정 불가 |

로컬 .git에는 DENY 항목 8개가 관측됐다. 항목 수는 유효 권한 계산이나 각 SID의
귀속 판정이 아니다. 세션의 명시적 읽기 전용 경계 및 앞선 승인 실행 성공과 함께
Git 접근 실패를 설명하는 근거로만 사용한다.

### 드러난 맹점과 정제

- **P1: 보호 동작을 ACL 고장으로 오인.** Git 쓰기는 처음부터 승인 경로로 요청한다.
  DENY 삭제, 전체 소유권 변경, 샌드박스 해제는 수행하지 않는다.
- **P1: 진단기가 자격증명에 접근하고 잘못된 합격을 출력.** 기존 진단기를 교체해
  토큰 관련 코드와 자동 복구 호출을 제거했다. 오래되거나 없는 증거는 Unknown/2,
  관측 실패는 Failed/1로 구분한다.
- **P1: 시작 메시지와 성공 메시지 혼동.** 완료된 setup 레코드만 해석한다.
  오류 뒤 spawn 메시지, 인용된 성공 문자열, 파싱 오류를 통과시키지 않는다.
- **P1: push 부분 성공 후 중복 재시도.** 원격 SHA를 먼저 확인하고 로컬 추적 정보와
  별도로 검증한다. 훅의 거부를 네트워크나 샌드박스 장애로 처리하지 않는다.
- **P2: 진단 개선을 샌드박스 엔진 수리로 표현.** 변경 범위는 로컬 진단·운영 절차다.
  실제 스크립트 폴더 생성/쓰기/읽기 및 setup 결과만 검증한다.

후속 검증: 8개 회귀 사례 통과, 실제 `-ProbeWorkspaceWrite` 실행 종료 코드 0.
보호 경로가 허용되었다거나 모든 명령이 성공하게 되었다는 주장은 하지 않는다.

검색은 `openai/codex`의 Windows index.lock, SetNamedSecurityInfoW, LTSC를 대상으로
시작해 관련 PR과 반대 사례를 대조했다. 핵심 구분이 공개 PR·현재 권한 경계·실행
결과에서 일치하여 추가 유사 이슈 수집을 중단했다. 계획 도구는 현재 도구 목록에
없어 범위와 단계는 진행 메시지와 이 기록으로 관리했다.

## 실제 재발 방지 적용과 검증

호스트 사용자 설정 `C:\Users\Kimyoongyeom\.codex\config.toml`에 다음 최소 설정을
추가했다.

```toml
[sandbox_workspace_write]
exclude_slash_tmp = true
```

목적은 Windows의 `C:\tmp`를 workspace-write 쓰기 루트에서 제외해, 과거의
`SetNamedSecurityInfoW failed: 5` 초기화 실패 경로를 다시 열지 않는 것이다. 네트워크,
사용자 `%TEMP%`, 추가 writable root, Git 보호 정책은 바꾸지 않았다. 되돌리려면 이
섹션의 두 줄을 삭제한다.

적용 뒤의 증거는 다음과 같다.

- 실제 `codex sandbox -P :workspace`에서 워크스페이스 고유 파일의 생성·쓰기·읽기·삭제 성공.
- 고유 검사 파일 잔여 0개.
- 새 setup 완료 기록은 2~3개 쓰기 루트와 `errors=[]`.
- `config.toml`에 `exclude_slash_tmp = true` 존재 확인.

`codex doctor`를 이미 샌드박스 안에서 실행하면 `CodexSandboxOffline`의 별도 프로필을
보일 수 있다. 따라서 이 경우에는 호스트 사용자 설정의 적용 여부를 판정하는 근거로
쓰지 않는다. 호스트 설정·실제 `:workspace` 검사·새 setup 완료 기록을 함께 확인한다.

성공 기준은 일반 파일의 편집·빌드·검사가 workspace-write에서 완료되고, setup 오류가
발생하지 않는 것이다. `.git`, `.agents`, `.codex`의 재귀 읽기 전용 보호는 Codex의
문서화된 보안 경계이므로 이 기준의 실패로 세지 않는다. Git 메타데이터 변경은 정식
승인 경로를 사용한다.

## 최소 개선

`Test-CodexCommandAccess.ps1`은 정해진 읽기 전용 조회만 실행한다.
기본 `OsRegistry`는 OS 버전 확인용이며, `OsCim`은 WMI 접근 비교용이다.
성공은 종료 코드 0, 실행 실패는 1이다. 원문 오류·자격증명은 출력하지 않는다.
샌드박스 종류를 자동 추정하거나 스스로 승격하지 않는다.

```powershell
pwsh -NoProfile -File codex/app-diagnostics/Test-CodexCommandAccess.ps1
pwsh -NoProfile -File codex/app-diagnostics/Test-CodexCommandAccess.ps1 -Probe OsCim
```

실패한 경우 같은 명령을 정식 승인 절차로 밖에서 비교한다. 실패한 프로그램의
종료 코드는 호출자가 즉시 확인한다. 자동으로 재귀 ACL 변경, 보안 기능 해제,
OS 교체를 하지 않는다. 새로 거부되는 명령은 대상·실행 컨텍스트·종료 코드와
함께 따로 분류한다. 이 두 probe의 성공을 다른 명령의 성공으로 일반화하지 않는다.

## 실행 검증

- 기본 OsRegistry 실제 실행: 종료 코드 0, EnterpriseS / 24H2 / 26100.8875.
- 별도 PowerShell 프로세스에서 접근 거부 예외 주입: Failed JSON 및 종료 코드 1 확인.
- `npm run check`: 종료 코드 0. 기존 skills audit 경고 20건은 남아 있음.
- Git 상태 조회의 전역 ignore 접근 경고도 승인된 밖의 동일 조회에서는 사라졌다.
  이 역시 실행 컨텍스트 차이를 보여주며, OS 전체 고장의 근거가 아니다.

## 판단을 바꿀 증거

동일한 정책과 Codex 버전에서 일반 Windows 11은 성공하지만 LTSC만 실패하거나,
실패 시각과 일치하는 AppLocker/WDAC/WMI 정책 이벤트 또는 공식 호환성 결함이
확인되면 LTSC/정책 가설의 우선순위를 높인다. 현재 그런 대조 실험은 수행하지 않았다.

## 공식 근거

- [Microsoft LTSC 2024](https://learn.microsoft.com/en-us/windows/whats-new/ltsc/whats-new-windows-11-2024):
  24H2와 유사한 기능 기반이며 일부 일반 채널 앱·Store 지원이 제한될 수 있음.
- [OpenAI Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox):
  Windows 11 권장, elevated sandbox의 낮은 권한 사용자 및 정책 경계 설명.
- [OpenAI 승인 및 보안](https://learn.chatgpt.com/docs/agent-approvals-security):
  승인 정책과 실행 권한의 구분, workspace-write 내부 보호 경로 설명.
