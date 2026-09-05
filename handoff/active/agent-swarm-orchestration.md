---
handoff_id: agent-swarm-orchestration-2026-08-21
status: STALE
workstream: agent-swarm-orchestration
objective: 3대 AI 도구가 실제로 서로에게 작업을 위임하고 결과를 교차 검증하는 경로를 확정하고, 그 경로를 프로토콜과 감사 로그로 고정한다
repository: gyeomsVibe/260718_agentic-ai-platform-optimization
branch: main
base_sha: 9479f88867f428eed2165bcdec8056dd72d5fac1
work_sha: 315906feda6dbf36450e8a7d6fc66c3e0a04c9c6
owned_paths:
  - agent-swarm/
  - mcp/antigravity-bridge/
  - mcp/README.md
completed:
  - 입력 자료 3건(agent-swarm 글로벌룰 md, 클로드 크로스세션 메시징 카드뉴스, 코덱스로 안티그래비티 조종 문서)을 웹 리서치와 로컬 실측으로 전수 검증하고 통합 보고서로 정리했다
  - 자료 A의 파일 기반 메시지 버스 원안을 폐기하고 agent-swarm 섹션을 프로토콜 정본 및 감사 로그 보관소로 재정의했다
  - 실험 1~5를 실행하고 회차별 로그 4개를 남겼다. F1부터 F24까지 발견을 번호로 고정했다
  - 외부 MCP 브리지 mcp-server-google-antigravity를 설치 없이 소스 감사하고 결과를 audits/에 기록했다
  - 감사 결과에 따라 권한 강화 포크를 mcp/antigravity-bridge/에 벤더링하고 SOURCE.md에 원본 해시와 변경 이력을 남겼다
  - 포크를 설치하고 Codex에 antigravity-bridge로 등록한 뒤 stdio 핸드셰이크와 실제 위임으로 런타임 검증을 마쳤다
  - Codex에서 Antigravity로의 위임이 샌드박스를 켠 채 자동승인 없이 성립함을 확인했다. 이것으로 3층 구조의 1층과 2층이 실제로 연결됐다
remaining:
  - 진짜 위반에 대한 감독자의 적발 능력이 미측정이다. 실행자가 2회 시행 모두 제약을 지켜 잡아낼 위반이 발생하지 않았다
  - Claude Code Agent Teams는 v2.1.220에서 성립하지 않는다. v2.1.237 업그레이드 후 재검증이 필요하다
  - Codex 폰 원격조종은 서브커맨드 존재만 확인했고 페어링을 수행하지 않았다
  - Codex와 Claude Code 사이의 MCP 연결은 명령 존재만 확인했고 실제 연결을 검증하지 않았다
  - agy의 지시 순응도는 2회 관찰이다. 경향으로 부르려면 반복 시행이 필요하다
verification:
  - 2026-09-05 최신성 재검사에서 work_sha 이후 agent-swarm/ 및 mcp/README.md 변경을 확인했다. 현재 HEAD의 해당 변경은 이 레코드의 기존 검증을 상속하지 않으므로 STALE로 강등했다
  - npm run check 실패 0건 (마지막 실행 2026-08-21)
  - node --check mcp/antigravity-bridge/index.js 통과
  - 패치 스크립트 재현성 확인. 상류에 재적용한 결과가 저장소 사본과 sha256 184d4e5fcdddcede2b18d9c7c8f5e2c6a4179841eab35c51889593eef4182671 로 일치
  - MCP stdio 핸드셰이크로 도구 9종 확인. 제거한 파일 도구 0건, write_to_file 파라미터 부재
  - 실험 4에서 AUTH_SUCCEEDED yes, DEFAULT_AUTO_APPROVE false, DEFAULT_SANDBOX true, 작업 상태 done
  - 실험 5에서 프로젝트 작업트리 무변화를 독립 확인. git status 9줄 유지, agy 하우스키핑은 1929에서 1943으로 증가
  - npm install --omit=optional --ignore-scripts 결과 취약점 0건
decisions:
  - 셸 호출 대신 MCP 경유를 채택했다. 셸 경로는 완화책 5종을 모두 적용해도 agy 인증에 실패하지만 MCP 서버 프로세스는 오케스트레이터의 명령 샌드박스 밖에서 실행되어 성립한다
  - 상류 브리지를 그대로 쓰지 않고 포크했다. 자동승인 기본값이 true로 skip-permissions에 직결되어 도입 목적 자체를 무효화하기 때문이다
  - 파일 도구 6종을 제거했다. 오케스트레이터가 자체 파일 도구를 갖고 있어 효용 없이 공격면만 늘린다
  - 의존성은 선택 의존성과 생명주기 스크립트를 모두 끄고 설치했다. 전이 의존성의 설치 시 코드 실행을 0으로 만들기 위함이다
  - 샌드박스 해제는 채택하지 않는다. 실험 1과 2 시점에는 필수 전제로 판단했으나 실험 4에서 회피 가능함이 확인되어 판정을 되돌렸다
risks:
  - 상류 브리지는 2026-07-14 이후 변경이 없다. 취약점이 발견되어도 패치를 기대하기 어렵다. 포크를 직접 유지해야 한다
  - 헤드리스 agy는 쓰기를 동반한 작업에서 권한 프롬프트에 막혀 타임아웃될 수 있다. 포크는 무제한 실행을 기본값에서 예외로 강등했을 뿐 제거하지 못했다
  - childEnv 허용 목록에 GOOGLE_ 과 GEMINI_ 접두사를 남겼다. agy에 필요할 수 있다는 판단이며 재검토 대상이다
  - 사용자 승인과 실행 환경 정책은 별개 관문이다. 채팅상의 승인이 로컬 권한 분류기를 해제하지 않는다
  - npm 발행본과 GitHub 소스의 동일성은 대조하지 않았다. 벤더링은 감사한 GitHub 소스에서 직접 취득해 이 위험을 우회했다
approvals_required:
  - Claude Code를 v2.1.237로 업그레이드하는 작업
  - WSL2 배포판 설치
  - 이 저장소 밖으로의 push 또는 다른 계정 및 권한 변경
  - 되돌리기 어려운 작업 일반. 강제 push와 히스토리 재작성 포함
next_action: 현재 HEAD에서 owned_paths 변경 내역과 도구 버전을 다시 감사하고, 기존 remaining·verification·risks를 사실에 맞게 갱신한 뒤 새 work_sha 후보를 만든다
revalidate_when:
  - agy 버전이 1.1.16에서 바뀌었을 때
  - codex-cli 버전이 0.148.0에서 바뀌었을 때
  - Claude Code 버전이 2.1.220에서 바뀌었을 때
  - 상류 mcp-server-google-antigravity 가 1.0.2 이후로 갱신되었을 때
  - mcp/antigravity-bridge/index.js 의 sha256 이 184d4e5fcdddcede2b18d9c7c8f5e2c6a4179841eab35c51889593eef4182671 에서 바뀌었을 때
---

# agent-swarm 오케스트레이션 인계

이 레코드는 `work_sha`에서 검증된 결과와 다음 행동 한 가지를 전달합니다.

## 완료 근거

세 자료의 주장을 검증하는 과정에서 판정이 두 번 뒤집혔습니다. 그 경로가 근거의 핵심입니다.

1. **실험 1** — Codex가 셸로 `agy`를 부르면 인증에 실패합니다. `-s read-only`, `--add-dir`,
   전면 읽기 권한, 네트워크 허용, 환경변수 전체 상속까지 다섯 완화책을 쌓아도 실패했고,
   마지막 프로브는 1초 만에 `Please sign in`으로 떨어졌습니다. 네트워크 타임아웃이 아니라
   자격증명 경로 자체가 차단된 것입니다. 반면 샌드박스 없는 직접 실행은 정상이었습니다.

2. **중간 오판** — 여기서 자료 C의 스크린샷에 `전체 액세스` 배지가 켜져 있던 것과 결합해
   "샌드박스 해제가 이 기법의 필수 전제"라고 결론지었습니다. **이 판단은 틀렸습니다.**

3. **소스 감사** — 대안으로 검토한 MCP 브리지는 `AGY_AUTO_APPROVE` 기본값이 `true`이고
   `--dangerously-skip-permissions`로 직결됩니다. 도입 목적이 기본 경로에서 무너지므로
   상류 그대로는 부적합으로 판정하고 포크했습니다.

4. **실험 4** — 포크를 등록하고 위임하자 **샌드박스를 켠 채, 자동승인 없이 인증에 성공**했습니다.
   `AUTH_SUCCEEDED: yes`. MCP 서버 프로세스가 오케스트레이터의 명령 샌드박스 밖에서 실행되기
   때문입니다. 셸 경로를 고집할 때만 치르는 대가였던 것입니다.

5. **실험 5** — 감독자가 하우스키핑 14개가 실제로 생성된 상태에서 프로젝트 작업트리 무변화를
   정확히 판정했습니다. 오보를 내지 않았고, 그 판정을 그대로 믿지 않고 독립 대조했습니다.

## 남은 위험

가장 큰 미완은 **적발 능력의 절반이 여전히 미측정**이라는 점입니다.

측정된 것은 감독자의 판별력, 즉 하우스키핑을 위반으로 오보하지 않는 능력입니다.
실행자가 두 번 모두 제약을 지켰기 때문에 **실제 위반을 잡아내는 능력은 시험되지 않았습니다.**
자료 C의 최대 가치 주장은 아직 재현되지 않은 상태입니다. `next_action`이 이것을 겨냥합니다.

운영상의 위험은 상류 브리지의 유지보수 공백입니다. 5주째 변경이 없고 star 2개, fork 0입니다.
포크를 직접 유지해야 하며, 상류가 갱신되면 사본을 고치지 말고
`mcp/antigravity-bridge/tools/apply-fork-patches.py`로 새 원본에 패치를 재적용해야 합니다.
그 스크립트는 각 단계마다 예상 문자열을 assert하므로 상류가 해당 영역을 바꾸면 조용히
반쯤 패치되는 대신 실패합니다.
