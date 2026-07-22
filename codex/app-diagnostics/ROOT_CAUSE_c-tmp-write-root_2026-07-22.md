# 근본 원인: C:\tmp 쓰기 루트 (40일 반복 실패의 진짜 이유)

> 상태: `VERIFIED_RESULT` (2026-07-22 규명·수리·재시작 검증 완료)
> 한 줄 요약: **샌드박스가 `C:\tmp`를 쓰기 루트로 강제했는데 그 폴더는 Administrators 소유라
> 비관리자 setup이 권한을 못 바꿔 매번 실패했다. 해결은 ACL 부여가 아니라 `excludeSlashTmp=true`.**

## 1. 증상

- Codex 샌드박스 setup 로그에 `write ACE failed on C:\tmp: SetNamedSecurityInfoW failed: 5`.
- `5`는 Windows 오류 코드 **ERROR_ACCESS_DENIED(접근 거부)**.
- 최근 40일 로그에서 **C:\tmp 실패 852회** (압도적 다수). 워크스페이스 하위폴더 실패는 소수(~40회).

## 2. 근본 원인 (왜 나는가)

1. Codex의 `workspace-write` 샌드박스 정책은 기본값 **`excludeSlashTmp = false`** 상태다.
2. 이 값이 false면 Codex는 유닉스 관습대로 **`/tmp`(윈도우에선 `C:\tmp`)를 쓰기 루트에 자동 추가**한다.
3. 그래서 매 세션 setup이 `C:\tmp`에 "샌드박스 그룹 쓰기 권한(ACE)"을 부여하려 한다.
4. 그런데 **`C:\tmp`의 소유자는 `BUILTIN\Administrators`**다. 폴더의 권한(DACL)을 바꾸려면
   그 폴더를 **소유**하거나 `WRITE_DAC` 권한이 있어야 하는데, 샌드박스 setup은 **일반 사용자
   권한**으로 돈다 → 남의 폴더 권한을 못 바꿔 **접근 거부(5)로 영구 실패**.

```
excludeSlashTmp=false → C:\tmp 를 쓰기 루트로 요구
                      → setup(일반권한) 이 Administrators 소유 폴더의 ACL 수정 시도
                      → SetNamedSecurityInfoW failed: 5  (매 세션 반복)
```

## 3. 왜 40일간 안 고쳐졌나 (메타 원인)

지금까지 모든 수리는 **`C:\tmp`에 ACL을 부여**하는 증상 치료였다([`fix-sandbox-acl.bat`](fix-sandbox-acl.bat)도 C:\tmp를 grant). 이게 근본적으로 실패하는 이유:

- **엉뚱한 대상**: `excludeSlashTmp`가 false인 한, Codex는 **매번 C:\tmp를 다시 요구**한다. ACL을
  아무리 부여해도 정책이 안 바뀌면 계속 시도·실패.
- **관리자 영역과의 싸움**: C:\tmp는 시스템 소유라 부여는 관리자 권한으로 매번 다시 해야 하고,
  temp 정리·재생성 시 리셋된다.
- **아무도 근본 플래그를 안 건드림**: 40일간 이 한 줄 설정을 끈 사람이 없었다.

## 4. 진짜 해결책 (1순위)

**`excludeSlashTmp = true`로 Codex가 C:\tmp를 아예 쓰기 루트에서 빼게 한다.** 그러면 관리자 소유
폴더에 ACL을 시도할 일이 없어져 에러가 **원천 소멸**한다. 샌드박스는 워크스페이스 + 사용자 소유
임시폴더(`%LOCALAPPDATA%\Temp`, 항상 정상)만 쓴다.

적용은 **2중 층**으로 영구 고정한다:

| 층 | 위치 | 방법 | 특성 |
|---|---|---|---|
| 앱 상태 | `~/.codex/.codex-global-state.json` | `"excludeSlashTmp":false` → `true` | ⚠️ **Codex 완전 종료 상태에서** 편집(실행 중 편집은 종료 시 되돌려짐) |
| **config (영구)** | `~/.codex/config.toml` | `[sandbox_workspace_write]`\n`exclude_slash_tmp = true` | 앱이 안 덮어씀 · **Store 업데이트에도 생존** |

> `exclude_tmpdir_env_var`는 **false로 둔다** — `%TEMP%`는 사용자 소유라 정상 작동·필요하다.
> 적용 후 `codex doctor`로 `config.toml parse ok`를 확인하고, Codex 재시작 후 setup 로그가
> `errors=[]`·write roots 감소(6→3)인지 검증한다.

## 5. 검증 결과 (2026-07-22)

| 지표 | 수리 전 | 수리 후 |
|---|---|---|
| C:\tmp 에러 | 852회 | **0회** |
| write roots | 6 (C:\tmp 포함) | **3** (C:\tmp 제외) |
| setup 판정 | `errors=["...C:\tmp..."]` | **`errors=[]`** (재시작 후 연속) |

**잔여(무해)**: 앱 상태의 정책 프리셋 4개 중 1개는 시작 시 앱이 false로 되돌린다. 그러나 그건
실제 샌드박스를 구동하는 활성 정책이 아니다(로그가 클린한 것이 증거). 100% 균일화는 Codex
**설정 UI의 sandbox 토글**이 정본.

## 6. 도구 사용 순서 (갱신)

1. **[codex-sandbox-check.ps1](codex-sandbox-check.ps1)** 로 진단 (읽기 전용).
2. C:\tmp 에러가 보이면 → **이 문서 4장(excludeSlashTmp=true)**가 1순위 해결책.
3. 워크스페이스 하위폴더(정상 write root) ACL 실패만 남으면 → [`fix-sandbox-acl.bat`](fix-sandbox-acl.bat)
   로 상속 권한 복구(이건 정당한 write root라 ACL 부여가 맞다).

> 즉, `fix-sandbox-acl.bat`(ACL 부여)는 **C:\tmp에는 쓰지 말 것**. C:\tmp는 제외가 정답이다.
