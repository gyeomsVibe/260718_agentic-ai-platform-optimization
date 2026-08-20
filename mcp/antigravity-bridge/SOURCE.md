# SOURCE — `mcp/antigravity-bridge`

외부 소스를 벤더링한 포크다. 원본, 라이선스, 버전, 변경 이력을 여기에 기록한다.

## 원본 (Upstream)

| 항목 | 값 |
|---|---|
| 패키지 | `mcp-server-google-antigravity@1.0.2` |
| 저장소 | https://github.com/TurkerYakup/mcp-server-google-antigravity |
| 저자 | Türker Yakup |
| 라이선스 | MIT (`LICENSE.upstream`에 원문 보존) |
| 취득 경로 | `raw.githubusercontent.com/.../main/index.js` — **npm tarball이 아니라 감사한 GitHub 소스에서 직접 취득** |
| 취득 일시 | 2026-08-21 |
| 원본 크기 | 37,647 bytes / 943 lines |
| 원본 SHA-256 | `84c9dd1ba716678598c9510a4a76f1f0bb5030fc233fa9220ffcb1b79db1b360` |

> npm 발행본과 GitHub 소스의 동일성은 검증되지 않았다([감사 §7](../../agent-swarm/audits/2026-08-21_mcp-server-google-antigravity.md)).
> 그래서 **감사한 대상 그 자체**인 GitHub 소스를 취득해 이 불확실성을 제거했다.

## 포크 (This copy)

| 항목 | 값 |
|---|---|
| 버전 | `1.0.2-fork.1` |
| MCP 서버 이름 | `antigravity-bridge-fork` (상류는 `antigravity`) |
| 크기 | 34,393 bytes / 879 lines |
| SHA-256 | `184d4e5fcdddcede2b18d9c7c8f5e2c6a4179841eab35c51889593eef4182671` |
| 제거된 줄 수 | 64 |

## 포크 사유

[소스 감사](../../agent-swarm/audits/2026-08-21_mcp-server-google-antigravity.md)에서 확인한 3건 때문이다.

1. **H1** — `AGY_AUTO_APPROVE` 기본값이 `true`이고 `--dangerously-skip-permissions`로 직결된다. 이 브리지를 검토한 목적(보고서 §8 R1 회피)이 기본 경로에서 무너진다.
2. **H2** — 경로 제한이 전혀 없는 파일 읽기·쓰기 도구 6종을 모델에 노출한다. 오케스트레이터가 이미 자체 파일 도구를 갖고 있어 **효용은 0, 공격면만 증가**한다.
3. **H3** — 자식 프로세스가 부모 환경변수 전체를 상속한다.

## 변경 이력

### 1.0.2-fork.1 (2026-08-21)

**제거 — 경로 제한 없는 파일 도구 6종 (H2)**

| 제거 대상 | 상류 줄 |
|---|---|
| `antigravity_create_folder` | 806–815 |
| `antigravity_create_file` | 816–829 |
| `buildTree()` 헬퍼 (create_tree 전용) | 830–840 |
| `antigravity_create_tree` | 841–851 |
| `antigravity_list_dir` | 852–863 |
| `antigravity_read_file` | 883–900 |
| `use_antigravity`의 `write_to_file` 파라미터 + 출력 미러링 블록 | 552–563, 600, 603, 624 |

**변경 — 자동승인 기본값 (H1)**

```js
// 상류
const DEFAULT_AUTO_APPROVE = String(process.env.AGY_AUTO_APPROVE || "true").toLowerCase() !== "false";
// 포크
const DEFAULT_AUTO_APPROVE = false;
```

`AGY_AUTO_APPROVE` 환경변수는 **무시된다.** 환경변수로 조용히 켜지는 경로를 없애기 위함이다.
호출별 `auto_approve: true`는 여전히 동작하지만, 이제 **호출마다 명시적으로 드러나는 선택**이 된다.

**변경 — 샌드박스 기본값**

```js
// 상류: AGY_SANDBOX || "false"   →   포크: AGY_SANDBOX || "true"
```

`--sandbox`(터미널 제한)를 기본으로 건다. 상류 README의 권고와도 일치한다.

**변경 — 환경변수 상속 범위 (H3)**

`env: process.env` → `env: childEnv()`. `pty.spawn`과 `spawn` 두 곳 모두 적용.

허용 목록: `PATH` 계열, 임시 디렉터리, 홈·사용자 경로, 로케일, 프로세서 정보,
그리고 접두사 `AGY_` / `GOOGLE_` / `GEMINI_`.

> **의도적 선택**: `GOOGLE_*`·`GEMINI_*`는 남겼다. agy가 Google 도구이므로 필요할 수 있다.
> 목적은 **다른 서비스의 비밀정보 차단**이지 agy 자신의 자격증명 차단이 아니다.
> 이 판단은 재검토 대상이다.

**변경 — 식별자**

MCP 서버 이름을 `antigravity` → `antigravity-bridge-fork`로 바꿨다.
클라이언트 로그와 도구 목록에서 상류와 혼동되지 않게 하기 위함이다.

**보존한 도구 9종**

`use_antigravity`, `antigravity_continue`, `antigravity_result`, `antigravity_jobs`,
`antigravity_cancel`, `antigravity_cleanup`, `antigravity_models`, `antigravity_agents`,
`antigravity_health` — 위임과 결과 회수에 필요한 전부다.

## 검증

| 항목 | 결과 |
|---|---|
| `node --check` | ✅ 통과 |
| 제거 식별자 잔존 검색 | ✅ 0건 |
| `env: process.env` 실제 전달 잔존 | ✅ 0건 (주석 내 언급 1건만 존재) |
| 런타임 동작 | ❌ **미검증** — 의존성 미설치, MCP 클라이언트 미등록 |

## 상류 추적 방침

이 파일을 직접 수정해 상류를 따라가지 않는다.
상류가 갱신되면 **새 원본을 받아 위 변경 목록을 다시 적용**하고, 해시와 줄 번호를 갱신한다.
패치 스크립트는 재현 가능하도록 작성됐다 (문자열 기반 치환 + 줄 범위 삭제, 각 단계 assert).

상류는 2026-07-14 이후 변경이 없다. 갱신을 기대하기 어렵다.

## 남은 한계 (정직 보고)

**포크해도 근본 문제는 남는다.** 헤드리스 `agy`는 권한 프롬프트에서 멈추므로,
`auto_approve: false`로 돌리면 작업이 타임아웃될 수 있다. 상류가 기본값을 `true`로 둔 이유가 이것이다.

포크가 한 일은 **무제한 실행을 기본값에서 예외로 강등**한 것이다. 없앤 것이 아니다.
읽기 계열은 프롬프트 없이 자동 실행되는 것을 관찰했으므로
([실험 1 F2](../../agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md)),
**읽기 전용 위임에 한해서는 `auto_approve: false`로도 동작할 여지가 있다.** 이것은 측정으로 확인할 문제다.
