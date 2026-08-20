# 실험 1 — Codex → Antigravity 단발 위임 (읽기 전용)

- **일시**: 2026-08-21 00:20 ~ 00:35 KST
- **환경**: MSI GL75 / Windows 11 / `agy` 1.1.16 / `codex-cli` 0.148.0 / repo HEAD `6f9ccf0`
- **상한**: 1회 위임, 10분, 자동승인 플래그 미사용
- **판정**: ⚠️ **부분 성공 (Partial)** — 실행자 단독은 PASS, 오케스트레이터 경유는 FAIL

---

## 수용 기준 대비 결과

| 기준 | 결과 | 비고 |
|---|---|---|
| ① JSON 결과 회수 | ✅ **PASS** (직접 실행) / ❌ FAIL (Codex 경유) | 직접 실행 시 요청한 4개 키를 정확히 반환 |
| ② git 작업트리 변경 0건 | ✅ **PASS** (전 회차) | 6회 실행 내내 baseline 8줄 유지, `agent-swarm/` 신규 항목 0 |
| ③ 오케스트레이터의 결과 요약 보고 | ✅ PASS (형식) / ❌ FAIL (내용) | Codex는 지정 형식대로 8줄 보고했으나 내용은 실패 보고 |

---

## 실행 이력

| # | 구성 | 소요 | 결과 |
|---|---|---|---|
| 1a-i | `agy` 직접 (Git Bash) — 인자 순서 오류 | 44s | ⚠️ 프롬프트 오인식 (아래 F1) |
| 1a-ii | `agy` 직접 (Git Bash) — 인자 순서 수정 | 24s | ✅ **정상 JSON 반환** |
| 1b-1 | `codex exec -s read-only` | 88s | ❌ agy: "You are not logged into Antigravity" |
| 1b-2 | `codex exec -s workspace-write --add-dir ~/.gemini` | 59s | ❌ agy 실행 중인데 Codex가 대기 포기 |
| 1b-3 | `+ disk-full-read-access` | 81s | ❌ agy: "Waiting for authentication (timeout 60s)" → 타임아웃 |
| 1b-4 | `+ network_access=true` | 84s | ❌ 동일 |
| 1c | `+ shell_environment_policy.inherit=all`, `agy models`만 | 13s | ❌ **1초 만에** "Please sign in to view available models" |
| 대조군 | `agy models` (PowerShell, 샌드박스 없음) | 1s | ✅ **모델 15종 정상 조회** |

---

## 발견 (Findings)

### F1. `agy`의 `-p`는 다음 인자를 프롬프트 값으로 삼는다 — 치명적 인자 순서 함정

```bash
# ❌ 잘못됨: 프롬프트가 문자열 "--print-timeout" 이 되어버린다
agy -p --print-timeout 90s --model gemini-3.5-flash-low "Reply with exactly: OK"

# ✅ 올바름: -p 를 맨 뒤에 두고 프롬프트를 바로 붙인다
agy --model gemini-3.5-flash-medium --output-format json --print-timeout 150s -p "실제 프롬프트"
```

1a-i에서 agy는 프롬프트 `"--print-timeout"`을 받고 **그게 뭔지 조사하기 위해 웹 검색 4회 + 파일 탐색 8회를 자율 수행**했다. 44초와 상당한 토큰이 소모됐다. 오케스트레이터가 명령을 조립할 때 이 순서를 어기면 **엉뚱한 작업이 조용히 실행된다.**

### F2. `agy`는 승인 없이 웹 검색·파일 읽기를 자동 실행한다

1a-i에서 `--dangerously-skip-permissions` 없이도 웹 검색과 홈 디렉터리 설정 파일 읽기(`settings.json`)가 프롬프트 없이 실행됐다. 프린트 모드의 기본 동작이 이미 상당히 허용적이라는 뜻이다. "질문 없이 원샷" 설정을 굳이 켜지 않아도 읽기 계열은 이미 자동이다.

### F3. `agy`는 exit code 0 + `status: "ERROR"` 를 동시에 낼 수 있다 — 프로토콜 S3 보강 필요

1a-ii 실제 반환값:

```json
{"conversation_id":"11c31a27-...","status":"ERROR",
 "response":"{\n  \"title\": \"agent-swarm\", ... }\n",
 "error":"denying access to C:\\Program Files: Access is denied.",
 "duration_seconds":17.03,"num_turns":1,
 "usage":{"input_tokens":49038,"output_tokens":4078,"thinking_tokens":3538,
          "cache_read_tokens":126081,"total_tokens":53116}}
```

**답은 완벽히 맞는데 status는 ERROR이고 exit code는 0이다.** 부수적 접근 거부 1건이 전체 상태를 ERROR로 물들였다.

- exit code만 보는 오케스트레이터 → 실패를 성공으로 오판
- `status`만 보는 오케스트레이터 → 정상 답변을 폐기

→ **프로토콜 S3에 조항 추가**: 실행자 결과는 `exit code`, `status`, `response` **세 가지를 각각** 판정하고, `response`가 과제를 실제로 만족하면 `status: ERROR`여도 `error` 필드를 부수 경고로 분류한다.

### F4. ★ 근본 원인 — Codex 샌드박스 안에서는 `agy`가 인증되지 않는다

시도한 완화책과 결과:

| 완화책 | 결과 |
|---|---|
| `-s read-only` | ❌ "You are not logged into Antigravity" |
| `--add-dir ~/.gemini` (상태 디렉터리 쓰기 허용) | ❌ 여전히 실패 |
| `sandbox_permissions=["disk-full-read-access"]` (전면 읽기) | ❌ 여전히 실패 |
| `sandbox_workspace_write.network_access=true` (네트워크 허용) | ❌ 여전히 실패 |
| `shell_environment_policy.inherit=all` (환경변수 전체 상속) | ❌ **1초 만에** "Please sign in" |
| 샌드박스 없이 PowerShell 직접 실행 | ✅ **정상** |

1c에서 실패까지 걸린 시간이 **1초**라는 점이 중요하다. 네트워크 타임아웃이 아니라 **자격증명 자체를 찾지 못한 즉시 실패**다. 즉 agy의 자격증명은 단순 파일 읽기로 접근되는 것이 아니며(Windows 자격증명 저장소/DPAPI 또는 로컬 IPC 추정), Codex의 샌드박스가 그 경로를 차단한다. 전면 읽기 권한으로도 뚫리지 않았다.

**결론: `codex exec`의 어떤 샌드박스 모드로도 `agy` 위임이 성립하지 않는다.**

### F5. 자료 C의 구성은 Codex 샌드박스 해제를 전제로 한다

자료 C의 폰 스크린샷 하단 배지를 다시 보면 **`전체 액세스`** 가 켜져 있다. F4의 소거법 결과와 정확히 일치한다.

> 즉, "코덱스로 안티그래비티를 조종하기"는 **샌드박스를 끈 상태에서만 작동하는 기법**이다. 원문은 이 전제를 명시하지 않았다. 이것이 자료 C가 감춘 실제 비용이며, 보고서 §8 R1 위험이 선택이 아니라 **필수 조건**이었음을 뜻한다.

### F6. 오케스트레이터의 명령 대기 시간이 실행자보다 짧으면 정상 작업도 실패로 판정된다

1b-2에서 Codex는 *"`agy` 실행이 아직 진행 중입니다"* 라고 인지하고도 결과를 기다리지 않고 다음 단계로 넘어가 FAIL을 선언했다. agy 자체는 정상 동작 중이었다. 프롬프트에 명시적 대기 지시를 넣자(1b-3) 이 증상은 사라졌다.

→ **프로토콜 S2에 조항 추가**: 위임 지시에는 실행자의 예상 소요 시간을 명시하고, 오케스트레이터가 완료 전 판정하는 것을 금지한다.

### F7. 교차 검증(S5)은 실패 경로에서도 정상 작동했다

네 번의 실패 회차 모두에서 Codex는 `git status --porcelain`을 실행해 **`GIT_CLEAN: yes`를 정확히 판정**했다. 1b-4에서는 지시 위반 항목까지 스스로 기재했다. 교차 검증 메커니즘 자체는 실행자가 실패하더라도 독립적으로 작동한다 — 실험 2의 전제가 확보됐다.

---

## 프로토콜 v2 반영 사항

| 조항 | 추가/수정 내용 | 근거 |
|---|---|---|
| S2.4 (신설) | 위임 지시에 실행자 예상 소요를 명시하고, 오케스트레이터의 조기 판정을 금지한다 | F6 |
| S3.4 (신설) | 실행자 결과는 exit code·status·response를 각각 판정한다. response가 과제를 만족하면 status ERROR는 부수 경고로 분류한다 | F3 |
| S3.5 (신설) | 오케스트레이터가 CLI 명령을 조립할 때 플래그 순서 규약을 지시문에 함께 전달한다 | F1 |
| S6.4 (신설) | 실행자가 샌드박스 밖 자격증명을 요구하면, 샌드박스 해제 대신 MCP 경유를 우선 검토한다. 해제는 게이트 G2 승인 대상이다 | F4·F5 |

---

## 미해결 · 다음 결정

`agy` 위임을 성립시키는 경로는 두 가지뿐이며 **둘 다 별도 승인이 필요**하다.

- **경로 A — Codex 샌드박스 해제** (`-s danger-full-access`): 자료 C의 실제 구성. 즉시 가능하지만 Codex의 모든 셸 명령이 무제한이 된다.
- **경로 B — MCP 브리지 경유** (`mcp-server-google-antigravity` 설치): MCP 서버 프로세스는 셸 샌드박스 밖에서 뜨므로 자격증명 문제를 우회할 수 있다. 다만 저성숙(star 2개) 외부 패키지 설치가 필요하다 (보고서 §8 R4).

실험 2(지시 위반 적발)는 위임이 성립해야 수행 가능하므로, 위 결정 전까지 **보류**한다.
실험 3(Agent Teams)은 이 결정과 독립이므로 **선행 수행 가능**하다.
