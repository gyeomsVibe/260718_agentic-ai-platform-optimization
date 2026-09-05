# Slash Prompt Modes 검증 증거 안내

이 폴더는 “파일을 설치했다”는 기록과 “AI 도구에서 명령이 실제로 작동했다”는 기록을
구분해 보관합니다.

처음 보는 사용자는 먼저
[설계·진단·수정·검증 전체 과정](BEGINNER-GUIDE-TO-SLASH-MODE-DESIGN-FIXES-AND-VALIDATION.md)을
읽으세요. 문제가 무엇이었고, 왜 단순 설치 확인만으로 부족했으며, 어떤 실패를 거쳐
Antigravity·Claude Code·Codex에서 검증했는지 쉬운 말로 설명합니다.

## 무엇을 어디서 확인하나요?

| 궁금한 내용 | 파일 |
|---|---|
| 전체 과정과 초보자용 설명 | [설계·진단·수정·검증 전체 과정](BEGINNER-GUIDE-TO-SLASH-MODE-DESIGN-FIXES-AND-VALIDATION.md) |
| 세 도구의 최종 런타임 판정 | [교차 플랫폼 런타임 요약](cross-platform-runtime-summary-2026-09-05.json) |
| 설치 위치·개수·백업·해시 상태 | [교차 플랫폼 설치 무결성](cross-platform-installation-integrity-2026-09-05.json) |
| 재사용할 양성·음성 시험 항목 | [프롬프트 모드 시험 사례](prompt-mode-test-cases.json) |
| Antigravity 대·소문자 20개 결과 | [Antigravity 런타임 매트릭스](runtime-matrix-antigravity-2026-09-05.json) |
| Codex 최초 진단과 최종 재검증 | [Codex 최초 매트릭스](runtime-matrix-codex-2026-09-05.json), [Codex 최종 매트릭스](runtime-matrix-codex-final-2026-09-05.json) |
| Claude Code 최초 진단과 최종 재검증 | [Claude 최초 매트릭스](runtime-matrix-claude-2026-09-05.json), [Claude 최종 소문자 매트릭스](runtime-matrix-claude-final-lower-2026-09-05.json) |
| Claude 예산 실패 후 제한적 재시도 | [CRITIC 재시도](runtime-retry-claude-critic-lower-2026-09-05.json), [STRUCTURED 재시도](runtime-retry-claude-structured-upper-2026-09-05.json) |
| 생성 별칭에 잘못된 문자열이 남았던 결함 | [생성 별칭 의미 결함 감사](generated-alias-semantic-defect-audit.json) |
| README를 실행 패키지에서 제외한 이유 | [README 패키징 예외 감사](skill-readme-packaging-exception-audit.json) |

## 판정 읽는 법

- `pass`: 그 파일에 적힌 조건에서 관찰된 결과가 기대값과 일치했습니다.
- `cumulative`: 수정 전 통과 사례와 수정 후 표적 재검증을 합친 근거입니다.
- `unknown_command: 0`: Claude Code가 대문자 명령을 거부한 사례가 최종 검증에서 없었습니다.
- `cross_platform_trigger_matrix_verified: true`: 명령 인식과 대소문자 처리를 세 도구에서 확인했습니다.
- `cross_platform_behavioral_quality_verified: false`: 모든 실제 과제의 답변 품질 향상까지 증명한 것은 아닙니다.

JSON은 기계가 읽는 원시 기록입니다. 결론을 빠르게 이해하려면 전체 과정 가이드를 읽고,
세부 수치가 필요할 때 해당 JSON을 확인하세요.
