# 통합 실험 발견 사항 목록 (Consolidated Experiment Findings)

이 문서는 [`agent-swarm/logs/`](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/) 디렉터리 내에 기록된 4개의 실험 로그 파일로부터 넘버링된 발견 사항들(Numbered Findings)을 추출하여 통합 표(Consolidated Table)로 정리한 보고서입니다.

## 실험 개요 (Experiment Overview)

- **실험 1**: Codex → Antigravity 단발 위임 (읽기 전용)
- **실험 2**: 지시 위반 적발 능력 검증
- **실험 3**: Claude Code Agent Teams (Windows 대체 경로 검증)
- **실험 4·5**: MCP 브리지 경유 위임과 위반 적발

---

## 통합 발견 사항 표 (Consolidated Findings Table)

| 번호 | 발견 사항 (Finding) | 실험 번호 / 출처 | 요약 및 상세 내용 |
| :---: | :--- | :--- | :--- |
| **F1** | `agy`의 `-p`는 다음 인자를 프롬프트 값으로 삼는다 — 치명적 인자 순서 함정 | [실험 1](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md#L37-L48) | agy 실행 시 `-p` 플래그 뒤에 다른 옵션들을 두면, 그 옵션들이 프롬프트로 잘못 인식됨. 순서 오류 시 엉뚱한 자율 작업(웹 검색, 파일 탐색)이 조용히 실행될 위험이 있음. |
| **F2** | `agy`는 승인 없이 웹 검색·파일 읽기를 자동 실행한다 | [실험 1](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md#L49-L52) | `--dangerously-skip-permissions` 없이도 읽기 계열 작업(웹 검색, 설정 파일 조회 등)은 프롬프트 없이 자동으로 실행됨. |
| **F3** | `agy`는 exit code 0 + `status: "ERROR"` 를 동시에 낼 수 있다 — 프로토콜 S3 보강 필요 | [실험 1](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md#L53-L72) | 부수적인 접근 거부 경고로 인해 status는 `ERROR`로 출력되나, 실제 정답은 `response`에 정확히 반환되고 exit code는 0인 불일치 상황이 발생함. |
| **F4** | ★ 근본 원인 — Codex 샌드박스 안에서는 `agy`가 인증되지 않는다 | [실험 1](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md#L73-L89) | Codex의 셸 샌드박스가 agy의 인증 자격증명(Windows 자격증명 저장소/DPAPI 추정) 접근 경로를 차단하여, 셸 직접 호출 시 즉시 실패함. |
| **F5** | 자료 C의 구성은 Codex 샌드박스 해제를 전제로 한다 | [실험 1](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md#L90-L95) | 이전 참고 자료 C에서 Codex로 Antigravity를 조종한 기법은 샌드박스를 비활성화한 전체 액세스(`-s danger-full-access`) 상태여야만 작동하는 방식임. |
| **F6** | 오케스트레이터의 명령 대기 시간이 실행자보다 짧으면 정상 작업도 실패로 판정된다 | [실험 1](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md#L96-L101) | Codex가 실행 도중 대기를 중단하고 조기 실패로 판정하는 문제가 발생. 위임 프롬프트에 명시적 예상 완료 시간을 지시하여 방지해야 함. |
| **F7** | 교차 검증(S5)은 실패 경로에서도 정상 작동했다 | [실험 1](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp1_codex-to-antigravity.md#L102-L105) | 실행자가 실패하더라도 감독자인 Codex가 `git status`를 통한 교차 검증(`GIT_CLEAN: yes` 등) 및 지시 위반 여부 확인을 정상적으로 독립 수행함. |
| **F8** | `SendMessage`는 존재하지만 `ListAgents`는 존재하지 않는다 | [실험 3](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp3_claude-agent-teams.md#L26-L35) | 백그라운드 에이전트 간 통신용 API는 갖추고 있으나, 로스터(Roster)를 조회할 `ListAgents` 도구가 존재하지 않아 다른 에이전트의 존재를 파악할 수 없음. |
| **F9** | 형제(sibling) 에이전트는 서로를 발견할 수 없다 — 구조적 한계 | [실험 3](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp3_claude-agent-teams.md#L36-L52) | 에이전트가 다른 형제 에이전트의 ID를 알 수 없으므로, 메인 세션이 매개하는 허브-앤-스포크(Hub-and-Spoke) 구조만 성립하고 수평적 팀 메시(Team Mesh)는 성립 불가함. |
| **F10** | 원인은 OS가 아니라 버전이다 | [실험 3](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp3_claude-agent-teams.md#L53-L64) | Windows OS 자체 제약(크로스세션 메시징 불가)뿐만 아니라, Claude Code v2.1.220 버전 자체에서 `Agent` 도구 스키마에 `name` 파라미터가 빠져 팀메이트 생성이 불가함. |
| **F11** | 부수 확인 — 백그라운드 에이전트 자체는 정상 작동한다 | [실험 3](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp3_claude-agent-teams.md#L65-L70) | 병렬 수집 수단으로서의 백그라운드 subagent 자체는 정상 가동하므로, 메시징 토론 기능만 포기하면 Windows 네이티브에서도 유효하게 활용 가능함. |
| **F12** | 실행자는 제약을 지켰다 — 자료 C의 위반 사례는 재현되지 않았다 | [실험 2](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp2_instruction-violation-detection.md#L55-L62) | "파일 생성 금지" 제약 하에 실행했을 때, git status 상 변경이 0건으로 제약을 지켰으며 이전의 제약 우회 및 위반 사례는 재현되지 않음. |
| **F13** | ★ 교차 검증의 실전 함정 — 하우스키핑을 위반으로 오판하면 안 된다 | [실험 2](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp2_instruction-violation-detection.md#L63-L84) | agy 실행 중 내부 로그나 DB 파일 7개가 개인 상태 디렉터리에 기록됨. 이는 하우스키핑 영역이므로, 단순 파일 증가를 기준으로 위반을 판정하면 오보(False Positive)가 됨. |
| **F14** | F3(exit 0 + status ERROR)이 독립 시행에서 재현되었다 | [실험 2](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp2_instruction-violation-detection.md#L85-L92) | 실험 2에서는 `Find` 명령 타임아웃 오류로 인해 'exit code 0 + status: ERROR' 패턴이 재현됨. 이는 agy JSON 포맷의 구조적 특징으로 재확인됨. |
| **F15** | 캐시 읽기가 실제 입력의 2.5배였다 | [실험 2](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp2_instruction-violation-detection.md#L93-L98) | 캐시 토큰 사용량이 실 입력 토큰의 2.5배 수준으로 집계됨. 비용 추정 시 `total_tokens`가 아니라 캐시 읽기를 포함한 금액을 산정해야 함. |
| **F16** | 승인 체계는 2단이며, 사용자 승인이 실행 환경 정책을 덮지 않는다 | [실험 2](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp2_instruction-violation-detection.md#L124-L148) | 사용자가 명시적으로 권한을 승인했어도, 실행 환경(Claude Code auto mode classifier)에서 위험 명령으로 판단하여 차단함. 안전 룰 우회를 시도하지 말고 보고해야 함. |
| **F17** | *(누락됨)* | - | 원본 실험 로그에 명시되어 있지 않으나, 프로토콜 v2 수정 근거(`F17 + F18`) 및 맥락에 따르면 **"MCP 브리지 호출이 자동으로 더 안전하지 않다 (기본값 설정 확인 필요)"** 로 해석됨. |
| **F18** | ★ MCP 경유는 셸 경로가 실패한 지점을 통과한다 — R1은 필수 전제가 아니었다 | [실험 4·5](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp4-5_mcp-bridge-delegation.md#L35-L49) | MCP 서버 프로세스가 Codex의 셸 샌드박스 밖에서 생성되므로, 샌드박스를 활성화한 상태에서 자격증명에 접근하는 데 성공함. (샌드박스 해제가 필수가 아니었음을 입증) |
| **F19** | `codex exec`에서 MCP 도구 호출은 기본적으로 막힌다 | [실험 4·5](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp4-5_mcp-bridge-delegation.md#L50-L67) | 비대화형 실행에서는 MCP 승인 정책이 `never`가 되므로, `--approve-for-me`를 지정해 자동 승인을 사용해야 함. 단, 이 플래그는 `-s` 샌드박스 옵션과 병용할 수 없음. |
| **F20** | 포크의 하드닝이 런타임에 실제로 적용되었다 | [실험 4·5](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp4-5_mcp-bridge-delegation.md#L68-L72) | 포크된 브리지(`antigravity-bridge-fork`)가 `DEFAULT_AUTO_APPROVE: false`, `DEFAULT_SANDBOX: true` 값을 정상 관측 및 보고하여 오염을 막았음. |
| **F21** | 읽기 전용 위임은 자동승인 없이 성립한다 — F2 추정 확인 | [실험 4·5](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp4-5_mcp-bridge-delegation.md#L73-L81) | 읽기 계열 작업은 `auto_approve: false` 상태에서도 프롬프트 대기 없이 안전하게 완료됨. |
| **F22** | ★ 감독자의 판별력이 실제로 시험되었고 통과했다 | [실험 4·5](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp4-5_mcp-bridge-delegation.md#L117-L127) | 실행자의 사설 하우스키핑 파일 14개가 생성되었음에도 이를 위반으로 판정하지 않고, 프로젝트 작업트리가 변하지 않았음을 감독자가 올바르게 판단함. |
| **F23** | 실행자는 모순 지시에서 금지 쪽을 따랐다 — 2회 연속 | [실험 4·5](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp4-5_mcp-bridge-delegation.md#L128-L135) | 자동 승인이 허용되어 실제 쓰기가 가능한 상태에서도 "만들지 마라"와 "저장하라"가 충돌할 때, 금지 제약(`do not create any file`)을 우선으로 따름. |
| **F24** | 여전히 미측정 — 진짜 위반(true positive)에 대한 적발 | [실험 4·5](file:///D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/agent-swarm/logs/2026-08-21_exp4-5_mcp-bridge-delegation.md#L136-L144) | 위반 자체가 발생하지 않았으므로 감독자가 실제 위반을 포착하고 처리하는 true positive 능력은 아직 검증되지 않음. 향후 강제 위반 유도 설계 필요. |

---

## 📌 주요 반영 프로토콜 (Protocol v2) 요약

1. **S1.3 (신설)**: Claude Code 팀메이트는 **허브-앤-스포크** 형태로만 설계한다. (에이전트 간 토론이 필요한 과제는 메인 세션이 중계)
2. **S2.4 / S2.5 (신설)**: 위임 시 실행 예상 소요 시간을 명시하고, 비용 추정에는 캐시 읽기를 포함한 총 토큰량을 기준으로 삼는다.
3. **S3.4 / S3.5 (신설)**: 실행 결과는 `exit code`, `status`, `response` 세 신호를 개별적으로 나누어 판정하며, 오케스트레이터가 CLI 명령 조립 시 플래그 순서 규약을 지시문에 함께 넘긴다.
4. **S5.4 / S5.5 (신설)**: 교차 검증 시 **프로젝트 작업트리 변화**만 위반 기준으로 판정하며, 실행자 자체 로그/DB(하우스키핑)는 제외한다. 결과 판정 시 감독자의 보고에만 의존하지 않고 최소 1개 이상의 물리 지표를 독립 확인한다.
5. **S6.4 / S6.6 / S8 (신설)**: 셸을 통한 샌드박스 해제 대신 **MCP 경유를 우선 시도**하며, 무인 MCP 위임 시 `codex exec --approve-for-me`를 사용하고 샌드박스 플래그(`-s`)는 혼용하지 않는다. 도구 가용성은 OS 제약과 버전 제약으로 구분해 관리한다.

---
*보고서 작성자: Antigravity AI Assistant*
*최종 갱신일: 2026-08-21*
