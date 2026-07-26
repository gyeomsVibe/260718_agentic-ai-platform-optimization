# 🛠 앱 진단·오류해결·패치 (app-diagnostics)

> Codex 앱 자체에서 생기는 문제(파일 쓰기 거부, 로컬 이미지 다운로드 오동작, 압축 미리보기 실패)를
> **진단·복구하는 도구와 기록을 한 폴더에** 모은 섹션입니다. 문서만이 아니라 실행 도구까지 함께 둡니다.

## 이 폴더 구성

| 파일 | 종류 | 역할 |
|---|---|---|
| ⭐ [ROOT_CAUSE_c-tmp-write-root_2026-07-22.md](ROOT_CAUSE_c-tmp-write-root_2026-07-22.md) | 문서 | **근본 원인·1순위 해결책** — `SetNamedSecurityInfoW failed: 5`의 진짜 이유(C:\tmp 쓰기 루트)와 `excludeSlashTmp=true` 수리. **샌드박스 에러는 여기부터.** |
| [codex-sandbox-check.ps1](codex-sandbox-check.ps1) | 실행 스크립트 | **자가진단** — app.asar 무결성·gh 인증·폴더 권한(ACL)·로그 에러 4단계 점검 (PS 5.1·pwsh 7 공용) |
| [fix-sandbox-acl.bat](fix-sandbox-acl.bat) | 실행 배치 | **워크스페이스 하위폴더** 권한 복구용. ⚠️ **C:\tmp에는 쓰지 말 것**(제외가 정답 — 위 근본원인 문서 참조) |
| [1.Codex 샌드박스 오류 및 미리보기 난제 검증 완료 보고서 (Walkthrough).md](<1.Codex 샌드박스 오류 및 미리보기 난제 검증 완료 보고서 (Walkthrough).md>) | 문서 | 초기 조치·검증 기록(ACL 접근 시기) |
| [HANDOFF_CLAUDE_CODE_CODEX_DOWNLOAD_FIX_2026-07-19.md](HANDOFF_CLAUDE_CODE_CODEX_DOWNLOAD_FIX_2026-07-19.md) | 문서 | 이미지 다운로드 이슈 분석 근거·승인 경계(인수인계) |
| ⭐ [ROOT_CAUSE_db-malformed_2026-07-26.md](ROOT_CAUSE_db-malformed_2026-07-26.md) | 문서 | **근본 원인·해결** — 앱이 `database disk image is malformed`로 안 켜질 때. `~/.codex`의 SQLite DB 손상 진단·격리 수리·검증 기록. **시작 오류는 여기부터.** |
| [codex-db-doctor.py](codex-db-doctor.py) | 실행 스크립트 | **자가진단·수리** — `~/.codex` 전체 SQLite 무결성 검사, `--quarantine`로 손상 DB만 안전 격리(백업 후 이동) |

> **샌드박스 쓰기 거부(`SetNamedSecurityInfoW failed: 5`)를 만나면 → 먼저 ⭐C:\tmp 근본원인 문서를 보세요.**
> C:\tmp 문제는 ACL 부여가 아니라 `excludeSlashTmp=true`(config.toml)로 영구 해결합니다.
> **앱이 `database disk image is malformed`로 안 켜지면 → ⭐DB 근본원인 문서 + `codex-db-doctor.py`.**

## 먼저: "샌드박스"가 뭐고 왜 에러가 났나 (모르는 사람용)

**샌드박스(sandbox)** 는 Codex가 시스템을 함부로 못 건드리게 가둬 두는 **안전 우리**입니다.
문제는 이 우리 안의 Codex에게 **특정 폴더에 파일을 쓸 권한이 없을 때** 생겼습니다.

- 증상(로그): `SetNamedSecurityInfoW failed: 5` = **"접근 거부(Access Denied)"**
- 원인: 워크스페이스 폴더에 Codex 샌드박스 전용 그룹(`CodexSandboxUsers`)의 **수정(Modify) 권한(ACL)** 이 빠짐.
- 해결: 앱을 건드리는 위험한 방법 대신, **그 폴더에 권한을 부여**하는 정공법으로 고침.

> **왜 앱 바이너리 패치를 버렸나?** 예전엔 앱 파일(`app.asar`)을 직접 고치려 했지만, 스토어 서명이
> 깨져 앱이 안 켜지거나 강제 복구되는 위험이 있어 폐기했습니다. 지금은 순정 앱을 그대로 두고 **권한만 복구**합니다.

## 어떻게 쓰나 (따라 하기)

**1) 진단만 (읽기 전용, 안전):**
```powershell
pwsh -File codex/app-diagnostics/codex-sandbox-check.ps1
```
- `✅ 진단 완료: ... 모두 양호` → 정상. 끝.
- `❌ ... 경고/오류` → 아래 2번으로 복구.

**2) 권한이 꼬였을 때 복구 (관리자 권한 필요):**
```powershell
# 방법 A: 진단하며 복구까지 물어보기
pwsh -File codex/app-diagnostics/codex-sandbox-check.ps1 -Interactive
# 방법 B: 같은 폴더의 fix-sandbox-acl.bat 우클릭 → '관리자 권한으로 실행'
```

> 진단 스크립트는 Windows PowerShell 5.1과 pwsh 7 **양쪽에서 실행**됩니다(UTF-8 BOM 저장).

## 진단 [4/4] 판정 방식 (2026-07-20 개선)

로그 스캔 단계는 "지금 권한이 OK다"라는 간접 근거가 아니라, **로그의 setup refresh 시각을 비교해 판정**합니다:

- 마지막 **에러 이후 무오류 setup이 실제 실행됨** → `✅ 복구 확인` (복구됐는데 실패로 오판하지 않음)
- 가장 **최근 setup이 여전히 에러** → `❌ 현재 진행형` + Codex 재시작 안내 (재발을 합격으로 놓치지 않음)

## 남은 리스크

- **Windows 스토어 앱 업데이트** 시 폴더 권한 인덱스가 재지정되면 권한이 다시 풀릴 수 있습니다.
  → 그때 위 **2) 복구**를 한 번 돌리면 해결됩니다.
- 로컬 파일 다운로드가 필요하면, 미리보기 버튼 대신 **실제 파일을 export** 하는 것이 원칙입니다
  (루트 [AGENTS.md](../../AGENTS.md)의 "아티팩트 전달 수칙" 참조).
