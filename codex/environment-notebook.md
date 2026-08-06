# 🧩 Codex 에이전트 환경설정 기록 (노트북)

> 이관: `260713_pc-optimization` 워크스페이스에서 완전 이동 (2026-07-19). 문서 내 일부 상대 링크(optimization_result.md, scratch/ 등)는 구 워크스페이스 기준이라 연결되지 않을 수 있다.

> 대상 환경: **노트북** (MSI GL75 9SDK / Windows 11 Enterprise LTSC 2024)
> 관리 도메인: `~/.codex/` · `codex plugin` CLI / Codex Desktop
> 이 문서는 **Codex 전용**이다. Claude·Antigravity 설정은 각자의 문서에서 다룬다.

---

## 1. Codex란 (학습모드)

Codex는 대화 중 사용할 도구·스킬·지침을 확장하는 에이전트다. Claude Code와 마찬가지로
확장은 **3층위**로 이해하면 관리가 쉽다. (개념 표는 [노트북 PC 개요](https://github.com/gyeomsVibe/260713_pc-optimization/blob/main/notebook/README.md) 참조)

| 층위 | Codex에서의 위치 | 로컬에서 끌 수 있나 |
|---|---|---|
| **① 로컬 플러그인** | `~/.codex/config.toml` 의 `[plugins."<이름>@<마켓>"]` + 플러그인 캐시 | **가능** — `enabled = false` |
| **② 로컬 MCP / 마켓플레이스** | `~/.codex/.tmp/marketplaces`, `bundled-marketplaces` | 가능 |
| **③ 계정·업무 연동** | ChatGPT 계정에 연결된 원격 커넥터 (Google Workspace, GitHub, Notion, Figma 등) | **불가능 — 앱·계정 UI에서만** |

> **①과 ③을 혼동하면 제거에 실패한다.** 2026-08-05에 `uninstall_plugin` 도구 호출로 커넥터
> 11종을 지우려다 `No handler registered for tool: uninstall_plugin` 으로 전부 실패했다.
> ①은 그 도구가 아니라 `config.toml` 편집으로 끄고, ③은 **로컬에서 아예 끌 수 없다.**

> ⚠️ `config.toml`에는 인증 정보가 포함될 수 있어 **이 저장소에 원문을 커밋하지 않는다.** 이 문서는 위치·구조만 기록한다.

### 1.1 커넥터 정리 실측 (2026-08-07)

Codex가 스스로 경고를 띄웠다.

> *Skill descriptions were shortened to fit the 2% skills context budget. Codex can still see
> every skill, but some descriptions are shorter. Disable unused skills or plugins to leave
> more room for the rest.*

**로컬 플러그인 5종을 껐다.** 근거는 CLI 세션 46개에서 실제 도구 호출 **4,869건 / 고유 13종**을
집계한 결과 **커넥터 호출이 단 1건도 없었다**는 것과, 워크스페이스 파일 유형 실측이다.

| 끈 것 | 근거 |
|---|---|
| `sites@openai-bundled` | 사이트 구축·호스팅 작업 근거 없음 |
| `presentations@openai-primary-runtime` | 워크스페이스 `.pptx` **0개**, 데스크톱 로그 **0건** |
| `google-calendar@openai-curated` | `.ics` **0개** |
| `slack@openai-curated` | Slack 연동 흔적 없음 |
| `computer-use@openai-bundled` | 화면·입력 제어라 노출면이 큰데 사용 근거 0 |

**끄지 않은 것과 이유**: `documents`(`.docx` 202개), `pdf`·`pdf-viewer`(`.pdf` 609개),
`spreadsheets`(`.xlsx` 20 + `.csv` 74), `browser`·`chrome`(크롤링 프로젝트 존재),
`visualize`, `template-creator`. **11종을 끄려던 원래 계획을 따르지 않았다** — 문서·파일 계열을
끄는 것은 이 사용자의 실사용 근거에 정면으로 반한다.

**효과 검증**: `codex exec` 목록에서 `computer-use`·`presentations`·`sites` 2종이 사라졌다(4종 제거 확인).

### 1.2 그러나 목록은 오히려 늘었다 — 계정 커넥터 73종

같은 날 목록이 **30종 → 99종**이 됐다. 로컬에서 4종을 뺐지만 계정 레벨 커넥터 **73종**이 들어왔다.

| 접두사 | 개수 | | 접두사 | 개수 |
|---|---:|---|---|---:|
| `data-analytics` | 15 | | `google-calendar` | 5 |
| `superpowers` | **14** | | `notion` | 4 |
| `figma` | 12 | | `github` | 4 |
| Adobe(`app-…`) | 6 | | `heygen` | 2 |
| `product-design` | 5 | | `gmail` | 1 |
| `google-drive` | 5 | | | |

**이것들은 `config.toml`·로컬 DB 어디에도 없다.** `state_5.sqlite` 등에 플러그인 테이블이
없고 원격 스테이징 폴더도 비어 있다. 서버 측 계정 설정이므로 **Codex 앱 또는 계정 웹 UI에서만**
정리할 수 있다. 로컬 에이전트가 할 수 있는 일이 아니다.

> **부수 발견**: `superpowers:*` 14종이 **Codex 계정 커넥터로 이미 살아 있다.**
> Claude Code 플러그인 재설치 판단에 영향을 준다 —
> [`../claude/plugins.md` §6](../claude/plugins.md) 참조.

**남은 조치는 사용자 몫이다.** Codex 앱 설정에서 안 쓰는 커넥터(Adobe, Figma, HeyGen, Notion,
Gmail, Google Drive/Calendar 등)를 해제하면 컨텍스트 예산이 회복된다.

---

## 2. 실제 설정 위치 (검증됨)

`~/.codex/` 하위 구조 (2026-07-13 확인):

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

## 3. 정리 원칙 (노트북 최적화 관점)

Codex도 로컬 플러그인이 늘수록 **컨텍스트 토큰과 캐시 용량**을 소모한다. 따라서 노트북에서는
**실제로 쓰는 기능만 활성화**하는 것을 원칙으로 한다.

**유지 대상 (실사용 핵심):**
- 개발: GitHub, 코드 리뷰, 기능 개발, 커밋, 보안 가이드
- 문서: 문서·PDF·스프레드시트·프레젠테이션 스킬
- 업무: Gmail, Google Drive, Google Calendar, Notion
- 조작·표현: 내장 브라우저, 화면 제어, 시각화

**정리 대상 (미사용·중복):**
- Claude 계열과 중복되는 문서/예제 스킬 묶음
- 노트북에서 안 쓰는 업무 커넥터(예: Asana, 사설 레지스트리 등)

> 구체적인 활성/비활성 개수는 Codex Desktop의 플러그인 화면 기준으로 그때그때 달라지므로,
> **"안 쓰는 것은 비활성화"** 규칙만 유지하고 수치는 도구 화면에서 직접 확인한다.

---

## 4. 관리 방법

```bash
codex plugin list          # 설치·활성 상태 확인
codex plugin disable <id>  # 미사용 플러그인 비활성 (컨텍스트 절약)
codex plugin enable  <id>  # 원복
```

- 계정 커넥터(③층위)는 **Codex Desktop의 연결 설정**에서만 관리된다. CLI로 못 지운다.
- 변경을 완전히 반영하려면 **Codex Desktop을 재시작**해 메모리에 올라온 도구 정의를 해제한다.
- 마켓플레이스 공유 캐시는 재설치·업데이트용이므로, **설치 목록에 없는 캐시 항목까지 수동 삭제하지 않는다.**

---

## 5. 도메인 격리

- 이 문서와 Codex는 **`~/.codex/` 만** 다룬다.
- Claude 설정(`.claude/`)·Antigravity 설정(`.agents/`)은 **건드리지 않는다.**
- 관련: [Claude 환경](../claude/environment-notebook.md) · [Antigravity 환경](../antigravity/environment-notebook.md)

> 보안 주의: 이 문서에는 토큰·API 키·머신 고유 경로를 포함하지 않는다. `config.toml` 등 인증 파일은 열람·커밋하지 않았다.

---

## 6. 트러블슈팅

### 사례 1: 샌드박스에서 GitHub CLI 인증 실패 (2026-07-19 해결)

**증상**
- 일반 터미널에서는 `gh auth status`가 로그인 상태로 나오는데, Codex가 실행하는 `gh` 명령만 "로그인 안 됨"으로 실패한다.

**원인 (검증됨)**
- `gh` 토큰이 **Windows 자격 증명 관리자(keyring)** 에만 저장되어 있었다 (`hosts.yml`에는 토큰 없음).
- Codex는 **Windows 제한 토큰 샌드박스** 안에서 명령을 실행하므로 자격 증명 관리자(DPAPI) 접근이 차단된다. 금고(자격 증명 관리자)에 열쇠를 넣어뒀는데, 샌드박스는 금고 접근 권한이 없는 방인 셈이다.

**해결**
- 토큰 저장 위치를 keyring에서 `gh` 설정 파일(`%APPDATA%\GitHub CLI\hosts.yml`)로 옮긴다. 파일은 샌드박스에서도 읽을 수 있다.

```powershell
# 토큰을 화면에 출력하지 않고 파이프로만 전달한다
gh auth token | gh auth login --with-token --insecure-storage --hostname github.com
```

**검증 (전부 실행함)**
- `gh auth status` → 저장 위치가 keyring에서 `hosts.yml` 경로로 변경됨.
- `codex sandbox -- gh auth status` → 샌드박스 안에서 로그인 인식 성공.
- `codex sandbox -- gh api user` → 샌드박스 안에서 실제 GitHub API 호출 성공.

> 💡 `codex sandbox -- <명령>` 은 AI 에이전트를 돌리지 않고 Codex의 실제 샌드박스 안에서 명령만 실행하는 검증 도구다. 샌드박스 관련 이슈 재현·확인에 유용하다.

**주의사항**
- `--insecure-storage`는 토큰을 `hosts.yml`에 **평문으로** 저장한다(사용자 파일 권한으로만 보호). 샌드박스 도구에서 `gh`를 쓰기 위한 표준 절충안이며, 유출 의심 시 GitHub에서 토큰을 폐기(revoke)하고 `gh auth login`으로 재발급하면 된다.
- 기존 keyring 항목은 삭제하지 않았으므로 실패해도 원래 인증은 유지된다(되돌리기 안전).
- 같은 증상이 다른 샌드박스 에이전트(Claude Code 등)에서 나와도 동일 원인일 가능성이 높다.

### 사례 2: 압축 파일 미리보기 미지원 (2026-07-19, 우회 절차 검증됨)

**증상**
- Codex에서 zip 등 압축 파일을 열면 "압축 파일 미리보기는 아직 지원되지 않습니다. 이 파일을 보려면 다른 앱에서 여세요" 메시지가 뜬다.

**원인 (검증됨)**
- 샌드박스 차단이 아니라 **뷰어의 기능 미구현**이다. `codex features list` 전수 확인 결과 zip/preview 관련 기능 플래그가 없어 설정으로 켤 수 없다.

**우회 절차 (샌드박스 안에서 실행 검증 완료)**
- 핵심: 샌드박스 밖으로 나갈 필요 없이, **압축을 풀지 않고 메모리에서 바로 읽어 출력**하면 된다. 읽기 전용 샌드박스에서도 동작한다.

```powershell
# 1) 목록만 보기 (Windows 11 내장 tar가 zip 목록을 지원)
tar -tf 대상파일.zip

# 2) 텍스트 파일 내용까지 보기 (디스크 쓰기 없음)
$zip = [System.IO.Compression.ZipFile]::OpenRead('대상파일.zip')
$zip.Entries | ForEach-Object {
    "--- $($_.FullName) ($($_.Length) bytes) ---"
    if ($_.Length -le 4096) { (New-Object System.IO.StreamReader($_.Open())).ReadToEnd() }
}
$zip.Dispose()
```

**주의: 압축 해제(Expand-Archive)는 위치를 가려야 한다**
- `codex sandbox` 단독 실행은 읽기 전용 모드가 기본이라 임의 경로 쓰기가 `Access denied`로 막힌다. 이것은 **정상 보호 동작**이지 오류가 아니다.
- 실제 에이전트 세션에서는 작업 폴더(workspace)가 쓰기 허용 경로(write root)이므로, 해제가 필요하면 **작업 폴더 안**으로 풀도록 지시한다.

### 사례 3: Codex 앱 폴더 read ACE 실패 (2026-07-17 일시 발생, 자연 해소 — 관찰 항목)

- 로그 시그니처: `grant read ACE failed on C:\Program Files\WindowsApps\OpenAI.Codex_...\app for sandbox_group: SetNamedSecurityInfoW failed: 5`
- 2026-07-17에만 3건 발생하고 이후 0건. Store 앱 업데이트로 버전 폴더가 교체되는 시점의 일시 현상으로 추정(가정)된다.
- **재발 시 대응**: 사례 1과 같은 ACL 계열 원인이므로, 발생 지속 시 해당 앱 폴더 경로에 대해 관리자 권한 `icacls` 점검부터 시작한다. 1회성이면 무시한다.

### 잔여 차단 오류 전수 조사 결과 (2026-07-19 검증)

- `~/.codex/.sandbox/sandbox.*.log` 전체(2026-06-14~07-18)를 조사한 결과, 실제 접근차단은 위 사례들(C:\tmp write ACE, WindowsApps read ACE)뿐이며 **현재 활성 차단은 0건**이다.
- 로그의 `failed/error` 검색 결과 대부분은 실행한 명령의 출력 텍스트(예: `rg` 검색어에 'failed' 포함)나 종료 시 파이프 닫힘 메시지(`os error 232`)로 **무해한 노이즈**다. 판별 기준: `setup refresh ... errors=[]`이면 샌드박스는 정상이다.

```powershell
# 활성 차단 여부 재확인 (errors=[] 가 아닌 setup 오류만 걸러 보기)
Select-String -Path "$env:USERPROFILE\.codex\.sandbox\sandbox.*.log" -Pattern 'errors=\["' |
    Select-Object -Last 10
```

### 재발 방지 체크리스트: 새 쓰기 루트(write root) 추가 시

`C:\tmp` 사례(2026-07-18 해결, 상세: `custom-pet-manual/codex-image-viewer-sandbox-fix/`)의 재발을 막기 위해, 샌드박스에 새 쓰기 경로가 추가될 때는 아래 3가지를 사전 점검한다.

- [ ] **폴더 소유자 확인**: `icacls <경로>` 로 소유자가 `BUILTIN\Administrators` 등 제한적인지 확인
- [ ] **ACE 부여 가능 여부**: `CodexSandboxUsers` 그룹에 Modify ACE를 부여할 수 있는 권한(WRITE_DAC)이 있는지 확인. 없으면 관리자 권한으로 선부여: `icacls <경로> /grant "CodexSandboxUsers:(OI)(CI)M"`
- [ ] **셋업 로그 확인**: 당일 `sandbox.*.log`에서 `setup refresh ... errors=[]` 인지 확인. `errors=["write ACE failed..."]`가 보이면 위 ACL 조치로 해결
