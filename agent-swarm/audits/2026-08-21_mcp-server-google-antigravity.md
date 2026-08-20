# 소스 감사 — `mcp-server-google-antigravity`

- **일시**: 2026-08-21
- **대상**: `mcp-server-google-antigravity@1.0.2` (GitHub `TurkerYakup/mcp-server-google-antigravity`)
- **감사 사유**: 보고서 §8 R4. 실험 1 F4로 셸 호출 경로가 막힌 뒤, **샌드박스를 유지한 채 위임을 성립시킬 유일한 후보**로 우선순위가 올라감
- **감사 방식**: 설치하지 않고 원격 소스·레지스트리 메타데이터·락파일·README를 직접 열람
- **결론**: ❌ **현 상태로는 설치 권고하지 않음.** 조건부 대안은 §5

---

## 1. 결론 요약

**이 브리지는 R4가 아니다. 포장만 다른 R1이다.**

`AGY_AUTO_APPROVE`의 기본값이 `true`이고, 이것이 `--dangerously-skip-permissions`로 직결된다.
즉 아무 설정 없이 설치하면 **모든 위임 작업이 전체 자동승인으로 실행된다.**

```javascript
// index.js line 12
const DEFAULT_AUTO_APPROVE = String(process.env.AGY_AUTO_APPROVE || "true").toLowerCase() !== "false";

// index.js line ~823
if (effectiveAutoApprove) args.push("--dangerously-skip-permissions");
```

R4를 검토한 이유는 "R1을 치르지 않고 위임을 성립시키기 위해서"였다.
**그 목적이 소스 수준에서 무너진다.** 샌드박스는 유지되지만, 그 안에서 도는 실행자가 무제한이 된다.

---

## 2. 위험 항목

### H1 (높음) — 기본값이 전체 자동승인

위 코드 참조. README도 이를 숨기지 않고 명시한다:

> `auto_approve` defaults to **true** (`--dangerously-skip-permissions`) — agy will create/edit files and run terminal commands without prompting. This is intentional: in headless `--print` mode agy otherwise blocks on a permission prompt and the job hangs.

**저자의 설명이 우리 실험 결과와 정확히 일치한다.** 실험 1 F2에서 관찰한 "프린트 모드는 이미 허용적"과,
자료 C가 권한 프롬프트 없이 24시간 루프를 돌린 이유가 여기서 설명된다.

> **핵심 통찰**: "질문 없이 원샷"은 Codex 고유의 문제가 아니라 **헤드리스 agy 위임 자체의 구조적 요구**다.
> 셸 경로든 MCP 경로든 같은 벽에 부딪힌다. **전송 방식을 바꿔도 전제는 따라온다.**

### H2 (높음) — 경로 제한 없는 임의 파일 읽기·쓰기 도구를 모델에 노출

`antigravity_create_file`의 핸들러 전문:

```javascript
async ({ path: p, content, overwrite }) => {
  try {
    if (fs.existsSync(p) && overwrite === false) ...
    fs.mkdirSync(path.dirname(p), { recursive: true });
    fs.writeFileSync(p, content == null ? "" : content, "utf8");
    ...
```

`path.resolve`·`path.normalize`·루트 allowlist·`startsWith` 검사가 **파일 전체 어디에도 없다.**
`antigravity_read_file`도 동일하게 임의 절대경로를 읽는다.

영향 받는 도구 6개: `antigravity_create_file`, `antigravity_create_folder`, `antigravity_create_tree`,
`antigravity_list_dir`, `antigravity_read_file`, 그리고 `use_antigravity`의 `write_to_file` 파라미터.

**이 도구들은 우리에게 필요 없다.** Codex와 Claude Code는 이미 자체 파일 도구를 갖고 있다.
순수한 공격면 증가일 뿐이다.

### H3 (중간) — 자식 프로세스가 부모 환경변수 전체를 상속

```javascript
env: process.env   // pty.spawn() 호출부
```

오케스트레이터 프로세스에 다른 서비스용 토큰·키가 들어 있으면 그대로 `agy`에 전달된다.

### H4 (중간) — 공급 경로의 성숙도가 낮다

| 지표 | 값 |
|---|---|
| GitHub stars | 2 |
| forks | 0 |
| watchers | 0 |
| open issues | 1 |
| 저장소 생성 | 2026-07-12 |
| 마지막 푸시 | 2026-07-14 |
| **이후 경과** | **5주 넘게 변경 없음** |
| npm 버전 | 1.0.0 / 1.0.1 / 1.0.2 — **전부 2026-07-14 28분 사이에 발행** |
| 메인테이너 | 1인 (`turkeryakup`) |
| 소유자 유형 | 개인 계정 |

취약점이 발견돼도 **패치될 것이라 기대할 근거가 없다.**

### H5 (낮음) — 의존성 94개

직접 의존성은 3개(`@modelcontextprotocol/sdk`, `@xterm/headless`, `zod`)로 단정하지만,
락파일 기준 전이 의존성 포함 **94개 패키지**가 설치된다.
대부분 공식 MCP SDK가 끌어오는 것들(`express`, `hono`, `jose`, `eventsource`, `qs` 등 HTTP 전송용)이며,
**stdio 전송만 쓰는 우리 용도에서는 실행되지 않지만 디스크에는 존재한다.**
전부 `registry.npmjs.org` 출처이고 비표준 레지스트리는 0건이다.

---

## 3. 안전한 항목 (실측 확인)

| 항목 | 결과 |
|---|---|
| **설치 시 코드 실행** | ✅ **없음.** `scripts`는 `start`/`check`/`test`/`prepublishOnly`뿐이고 전부 `node --check`. **`postinstall` 없음** |
| **아웃바운드 네트워크 호출** | ✅ **없음.** `fetch(`·`http.request`·`https.request`·`axios`·`WebSocket`·`net.connect`·`dgram` 전부 0건. 문자열 리터럴에 `://` 0건 |
| **텔레메트리·수집** | ✅ 없음. 로깅은 MCP 프로토콜의 `sendLoggingMessage`로 클라이언트에만 전달 |
| **위험 원시함수** | ✅ `eval`·`new Function`·`vm`·동적 `require` 0건. 프로토타입 오염 패턴 없음 |
| **셸 인젝션** | ✅ 위험 낮음. 사용자 입력은 `args` 배열에 `push`되어 `spawn`/`pty.spawn`에 argv로 전달. 셸 문자열 보간 아님. `execSync` 사용처는 `agy models`·`agy agents`·`agy --version`·`where agy` 등 **사용자 입력 없는 고정 명령**만 |
| **라이선스** | ✅ MIT |
| **비표준 레지스트리** | ✅ 0건 |
| **README의 정직성** | ✅ 위험을 숨기지 않고 명시. 이유까지 설명 |

**코드 품질 자체는 나쁘지 않다.** 단일 파일 1,026줄, 네트워크·평가 원시함수 없음, argv 안전.
문제는 코드 결함이 아니라 **기본값 설계와 불필요한 권한 노출**이다.

---

## 4. 판정

> ❌ **현 상태 그대로 설치하지 않는다.**
>
> R4를 검토한 목적(R1 회피)이 H1로 무효화되고, H2가 없어도 되는 공격면을 추가한다.
> H4는 그 위험을 장기간 방치할 것임을 시사한다.

보고서 §8 R4의 등급을 **"우선순위 상향"에서 "조건부 보류"로 정정**한다.

---

## 5. 그래도 진행한다면 — 조건부 경로

두 가지 선택지가 있고, 둘 다 H1을 해결하지는 못한다.

### 경로 ① 상류 패키지 + 강제 설정 (빠름 / H2 미해결)

```
AGY_AUTO_APPROVE=false
AGY_SANDBOX=true
```
버전은 `1.0.2`로 고정한다.

- **문제**: `AGY_AUTO_APPROVE=false`면 헤드리스 작업이 권한 프롬프트에서 멈춰 타임아웃될 수 있다.
  저자가 기본값을 `true`로 둔 바로 그 이유다. **즉 "안전하게 쓰면 안 돌아갈 가능성이 높다."**
  실험 1 F2에서 읽기 계열은 프롬프트 없이 자동 실행되는 것을 관찰했으므로,
  **읽기 전용 위임에 한해서는 동작할 여지가 있다.** 이건 측정으로 확인할 문제다.
- H2(임의 경로 파일 도구 6종)는 그대로 노출된다.

### 경로 ② 최소 포크 벤더링 (권장 / H1 완화·H2 해결)

`index.js` 단일 파일이므로 포크 비용이 낮다.

1. 파일시스템 도구 6종을 **삭제**한다 — 오케스트레이터가 이미 자체 파일 도구를 갖고 있어 손실이 없다.
2. `DEFAULT_AUTO_APPROVE`를 **`false`로 하드코딩**하고, 자동승인이 필요한 호출은 **건별 명시**로만 허용한다.
3. `env: process.env` → 필요한 `AGY_*`와 `PATH`만 화이트리스트로 전달 (H3 해결).
4. 남는 도구: `use_antigravity`, `antigravity_continue`, `antigravity_result`, `antigravity_jobs`,
   `antigravity_cancel`, `antigravity_models`, `antigravity_health` — 위임에 필요한 전부.

**남는 한계**: 그래도 H1의 근본은 안 풀린다. 헤드리스 agy가 프롬프트에서 멈추는 구조는 브리지가 아니라
`agy` 쪽 문제이기 때문이다. 포크는 "무제한을 기본값에서 예외로 강등"할 뿐이다.

---

## 6. 이 감사가 보고서에 미치는 영향

| 대상 | 변경 |
|---|---|
| §8 R4 | "우선순위 상향" → **"조건부 보류"**. 이유: 목적 자체가 H1로 무효화 |
| §8 R1 | **재확인·강화.** 전송 방식을 바꿔도 전제가 따라온다는 것이 소스로 증명됨 |
| §4.2 매트릭스 | `mcp-server-google-antigravity` 행: "승인 대기" → **"감사 완료·현 상태 부적합"** |
| 프로토콜 S6.4 | *"샌드박스 해제 대신 MCP 경유를 먼저 검토한다"* → **수정 필요.** MCP 경유가 자동으로 더 안전하지 않다 |

---

## 7. 감사 범위의 한계 (정직 보고)

- **설치·실행하지 않았다.** 정적 열람만 했다. 런타임 동작은 검증하지 않았다.
- **직접 의존성 3개의 소스는 감사하지 않았다.** 공식 MCP SDK를 신뢰 기반으로 삼았다.
- **전이 의존성 91개는 이름과 버전, 레지스트리 출처만 확인**했다. 개별 감사는 하지 않았다.
- npm에 발행된 **tarball과 GitHub 소스의 동일성을 대조하지 않았다.** 두 산출물이 다를 가능성이 남는다.
  설치를 결정한다면 이 대조가 다음 단계다.
- `.github/workflows` 내부 파일 목록은 확인하지 못했다 (디렉터리 존재만 확인).
  자동 발행 파이프라인의 유무와 provenance 서명 여부는 미확인이다.
