# 🧩 Codex 에이전트 환경설정 기록 (데스크톱)

> 대상 환경: **데스크톱** (Intel i7-6700K / Windows 10 Pro 64-bit)
> 관리 도메인: `~/.codex/` · `codex plugin` CLI / Codex Desktop
> 이 문서는 **Codex 전용**이다. Claude·Antigravity 설정은 각자의 문서에서 다룬다.

---

## 1. Codex란 (학습모드)

Codex는 대화 중 사용할 도구·스킬·지침을 확장하는 에이전트입니다. 확장은 **3층위**로 이해하면 관리가 쉽습니다.

| 층위 | Codex에서의 위치 |
|---|---|
| **① 로컬 플러그인** | `~/.codex/config.toml` + `codex plugin` CLI, 플러그인 캐시 `~/.codex/.tmp/plugins` |
| **② 로컬 MCP / 마켓플레이스** | `~/.codex/.tmp/marketplaces`, `bundled-marketplaces` |
| **③ 계정·업무 연동** | Codex Desktop에서 연결한 계정·커넥터 (Google Workspace, GitHub, Notion 등) |

> ⚠️ `config.toml`에는 인증 정보가 포함될 수 있어 **이 저장소에 원문을 커밋하지 않습니다.** 이 문서는 위치·구조만 기록합니다.

---

## 2. 실제 설정 위치 (검증됨)

`~/.codex/` 하위 구조:

```
~/.codex/
├─ config.toml                 # Codex 주 설정 (인증 포함 가능 → 비커밋)
├─ .codex-global-state.json    # 전역 상태
├─ .tmp/
│  ├─ plugins/                 # 설치 플러그인 캐시
│  ├─ marketplaces/            # 사용자 추가 마켓플레이스
│  └─ bundled-marketplaces/    # 내장 마켓플레이스
├─ .sandbox/                   # 샌드박스 실행 로그
└─ .sandbox-bin/               # codex 실행 바이너리(버전별)
```

---

## 3. 정리 원칙 (데스크톱 최적화 관점)

데스크톱 환경(i7-6700K)은 노트북에 비해 CPU/메모리 자원이 상대적으로 여유로우나, 에이전트 호출 시의 **컨텍스트 토큰 소모량 절감 및 시작 병목 최소화**를 위해 불필요한 플러그인은 비활성화하는 노트북의 린(Lean) 원칙을 유지합니다.

**유지 대상 (실사용 핵심):**
- 개발: GitHub, 코드 리뷰, 기능 개발, 커밋, 보안 가이드
- 문서: 문서·PDF·스프레드시트·프레젠테이션 스킬
- 업무: Gmail, Google Drive, Google Calendar, Notion
- 조작·표현: 내장 브라우저, 화면 제어, 시각화

---

## 4. 관리 방법

```bash
codex plugin list          # 설치·활성 상태 확인
codex plugin disable <id>  # 미사용 플러그인 비활성 (컨텍스트 절약)
codex plugin enable  <id>  # 원복
```

- 계정 커넥터(③층위)는 **Codex Desktop의 연결 설정**에서만 관리됩니다.
- 변경을 완전히 반영하려면 **Codex Desktop을 재시작**해야 합니다.

---

## 5. 도메인 격리

- 이 문서와 Codex는 **`~/.codex/` 만** 다룹니다.
- Claude 설정(`.claude/`)·Antigravity 설정(`.agents/`)은 혼재되지 않도록 격리하여 유지합니다.

---

## 6. 트러블슈팅 및 현지화 수칙

### 사례 1: 샌드박스에서 GitHub CLI 인증 실패 (데스크톱 적용 완료)

**증상**
- 일반 터미널에서는 `gh auth status`가 정상이나, Codex가 실행하는 `gh` 명령만 "로그인 안 됨"으로 실패하는 현상.
- **원인**: 샌드박스는 제한된 토큰 환경으로 실행되어 Windows 자격 증명 관리자(keyring/DPAPI)에 대한 접근 권한이 없습니다.

**해결 (데스크톱 샌드박스 우회 적용)**
- 토큰 저장 방식을 평문 파일로 전환하여 샌드박스 내부에서도 읽을 수 있도록 조치합니다 (`%APPDATA%\GitHub CLI\hosts.yml`에 저장).
- 다음 명령어를 PowerShell에서 실행하여 토큰을 파일 영역에 강제 기록합니다:

```powershell
gh auth token | gh auth login --with-token --insecure-storage --hostname github.com
```

### 사례 2: 압축 파일 미리보기 미지원 우회

**증상**
- Codex 앱 내에서 zip 압축 파일을 미리보기 할 때 미지원 오류가 발생합니다 (뷰어 기능 미구현).

**우회 조치 (디스크 쓰기 없이 메모리 내에서 직접 읽기)**
- 샌드박스 내부 터미널 환경에서 PowerShell을 활용해 디스크에 직접 압축을 풀지 않고 파일 목록이나 내용을 즉석 출력합니다.

```powershell
# 1) 파일 목록 조회 (tar 사용)
tar -tf 대상파일.zip

# 2) 내용 스트림으로 직접 읽기
$zip = [System.IO.Compression.ZipFile]::OpenRead('대상파일.zip')
$zip.Entries | ForEach-Object {
    "--- $($_.FullName) ($($_.Length) bytes) ---"
    if ($_.Length -le 4096) { (New-Object System.IO.StreamReader($_.Open())).ReadToEnd() }
}
$zip.Dispose()
```

### 사례 3: Codex 앱 폴더 read ACE 실패 대응 수칙

- 로그 형식: `grant read ACE failed on C:\Program Files\WindowsApps\OpenAI.Codex_...\app for sandbox_group: SetNamedSecurityInfoW failed: 5`
- 윈도우 스토어 앱 업데이트 또는 권한 인덱스 재지정 시 발생하는 일시적 소유권/보안 정보 충돌로, 지속해서 발생 시 해당 WindowsApps 하위 폴더에 대해 관리자 권한으로 `icacls` 권한 재설정을 진행해야 합니다.

---

## 7. 재발 방지 체크리스트: 새 쓰기 루트(write root) 추가 시

- [ ] **폴더 소유자 확인**: `icacls <경로>` 로 소유자가 `BUILTIN\Administrators` 등 제한적인지 확인
- [ ] **ACE 부여 가능 여부**: `CodexSandboxUsers` 그룹에 Modify ACE를 부여할 수 있는 권한(WRITE_DAC)이 있는지 확인. 없으면 관리자 권한으로 선부여: `icacls <경로> /grant "CodexSandboxUsers:(OI)(CI)M"`
- [ ] **셋업 로그 확인**: `~/.codex/.sandbox/sandbox.*.log`에서 `setup refresh ... errors=[]` 확인
