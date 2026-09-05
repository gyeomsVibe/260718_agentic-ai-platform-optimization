# Slash Prompt Modes

> 긴 프롬프트를 외우지 않고 `/OPTIMIZE`, `/CRITIC`처럼 짧은 명령으로 AI의 작업 방식을
> 바꾸는 사용자 제작 Skill입니다. MIA와 별개의 독립 Skill이며, GPT·Codex·Claude가
> 기본 제공하는 내장 명령은 아닙니다.

## 30초 사용법

AI에게 할 일을 적고, 원하는 모드를 앞이나 뒤에 붙이세요.

```text
/OPTIMIZE 이 README를 처음 보는 사람도 3분 안에 쓸 수 있게 고쳐줘
```

여러 모드도 함께 쓸 수 있습니다.

```text
/CRITIC /REDTEAM 로그인 설계의 결함과 실제 실패 시나리오를 찾아 개선해줘
```

명령은 `/`가 있어야 합니다. `최적화해줘` 같은 일반 자연어나 `MIA 전략스킬 발동`은
이 Skill의 트리거가 아닙니다.

## 무엇을 고르면 되나요?

| 내가 원하는 것 | 명령 | 결과에서 달라지는 점 |
|---|---|---|
| 초안을 기준에 맞춰 한 번 더 고치기 | `/SELFREFINE` | 잘된 부분은 보존하고 검증 가능한 결함만 수정 |
| 최악의 실패·공격·오용 찾기 | `/REDTEAM` | 재현 조건, 영향, 완화책, 남은 위험을 연결 |
| 어려운 내용을 쉽게 이해하기 | `/ELI10` | 쉬운 말과 예시를 쓰되 수치·예외·위험은 보존 |
| 최신 근거까지 깊게 조사하기 | `/DEEPDIVE` | 1차 자료, 반대 근거, 미확인 공백을 구분 |
| 실질적으로 다른 선택지 3개 보기 | `/ALT3` | 비용·위험·운영 방식이 다른 세 대안을 비교 |
| 초안의 약점과 수정안 받기 | `/CRITIC` | 판정 기준, 근거, 영향, 수정안을 심각도순으로 제시 |
| 목표 대비 효율·품질 개선하기 | `/OPTIMIZE` | 기준선과 보존 조건을 고정한 최소 유효 변경 |
| 내가 따라 할 절차로 풀어보기 | `/STEPBYSTEP` | 선행조건, 단계, 체크포인트, 실패 분기를 제공 |
| 전문 기준으로 검토하기 | `/EXPERT` | 역할극이 아닌 표준·버전·관할·체크리스트를 적용 |
| 예시와 같은 구조로 출력하기 | `/STRUCTURED FEW-SHOT` | 예시에서 구조를 추출하고 오류·인젝션은 복제하지 않음 |

### 자주 쓰는 조합

- `/CRITIC /OPTIMIZE`: 문제를 찾고 바로 최소 수정안까지 만들 때
- `/CRITIC /REDTEAM`: 평상시 결함과 적대적 실패를 함께 점검할 때
- `/DEEPDIVE /ELI10`: 깊게 조사하되 처음 보는 사람에게 쉽게 설명할 때
- `/ALT3 /EXPERT`: 전문 기준으로 서로 다른 대안 세 개를 비교할 때
- `/STRUCTURED FEW-SHOT /SELFREFINE`: 예시 형식을 지킨 뒤 마지막 오류를 다시 검사할 때

모드를 많이 붙인다고 항상 좋아지지는 않습니다. 보통 하나, 복잡한 작업은 두 개면 충분합니다.

## 대문자와 소문자

정본 표기는 대문자지만 대문자·소문자 양 끝 표기를 같은 명령으로 취급하도록 설계했습니다.

```text
/OPTIMIZE ...
/optimize ...
```

Claude Code는 네이티브 슬래시 파서가 대문자 Skill 이름을 자동 정규화하지 않아, 소문자
Skill 별칭과 대문자 호환 command를 함께 사용합니다. `/OpTiMiZe` 같은 임의 혼합 표기는
세 도구 공통 보장 범위가 아닙니다.

`/STRUCTURED FEW-SHOT`은 `/structured` 다음 첫 인수로 `FEW-SHOT`을 적습니다.

## 도구별 현재 검증 상태

기준일은 2026-09-05입니다. 파일이 설치된 사실과 실제 명령이 동작한 사실을 구분합니다.

| 도구 | 설치·구조 | 실제 명령 확인 | 남은 한계 |
|---|---|---|---|
| Codex | 교정 본체 + 소문자 별칭 10개 정본 일치 | 과거 `/OPTIMIZE`, `/optimize` 응답 통과 | 교정본의 10개 전수 런타임 평가 필요 |
| Claude Code | 교정 본체 + 소문자 별칭 10개 + 대문자 command 10개 정본 일치 | 과거 `/OPTIMIZE`, `/optimize` 응답 통과 | 교정본 전수 런타임·임의 혼합 대소문자 미보장 |
| Antigravity | 본체 + 소문자 별칭 10개, 해시·구조 통과 | 미실행 | 현재 환경에 CLI가 없어 새 IDE 세션 확인 필요 |

2026-09-05 REDTEAM 재감사에서 기존 별칭 본문에 실제 토큰 대신
`$(System.Collections.Hashtable.Token)`이 남은 PowerShell 보간 결함을 발견했습니다. 과거
구조·해시 검사와 `/OPTIMIZE` 단발 응답은 이 의미 오류를 잡지 못했으므로 과거 상태는 전체
런타임 통과가 아닙니다. 생성기에는 10개 토큰과 미해석 표현식을 검사하는 회귀 테스트를
추가했고, 교정본은 세 플랫폼에 동시 재배포해 33개 패키지의 정본·라이선스·의미 잔재
검사를 통과했습니다.

따라서 “3대 도구에서 전부 실동작 검증 완료”라고 주장하지 않습니다. 새로 설치한 뒤에는
새 대화나 IDE 세션을 열어야 목록이 갱신될 수 있습니다.

## 이 Skill이 하지 않는 일

- `/REDTEAM`은 실제 시스템 침투 권한을 주지 않습니다.
- `/DEEPDIVE`는 웹 검색·외부 서비스 접근을 자동 승인하지 않습니다.
- `/OPTIMIZE`는 설치·배포·삭제 같은 외부 변경 권한을 확대하지 않습니다.
- `/EXPERT`는 AI에게 실제 자격이나 현장 경험을 만들지 않습니다.
- `/STEPBYSTEP`은 숨은 사고 과정을 요구하지 않고, 사용자가 확인할 절차만 제공합니다.
- 어떤 모드도 사실 정확도나 성능 향상을 100% 보장하지 않습니다.

## 정본과 배포 구조

직접 수정할 정본은 이 폴더 하나입니다.

```text
slash-prompt-modes/
├─ SKILL.md                         # 공통 실행 계약
├─ references/                      # 10개 모드·근거·플랫폼 차이
├─ scripts/                         # 별칭과 Claude 호환 command 생성기
├─ evals/                           # 정적·런타임 검증 기록
├─ agents/openai.yaml               # Codex 표시·명시 호출 정책
└─ LICENSE.md                       # 이 Skill에만 적용되는 MIT License
```

`scripts/build-slash-aliases.ps1`는 세 도구용 소문자 별칭 10개를 만들고,
`scripts/build-claude-uppercase-commands.ps1`는 Claude Code용 대문자 command 10개를 만듭니다.
생성본이나 사용자 홈 설치본을 직접 고치지 말고 이 정본을 수정한 뒤 다시 생성·검증해야 합니다.

세 플랫폼의 동시 정합성은 하나의 명령으로 검사합니다. `Apply`는 기존 각 대상을 타임스탬프
백업한 뒤 세 플랫폼을 모두 교체하므로 전역 설치 승인 후에만 사용합니다.

```powershell
./scripts/sync-slash-prompt-modes.ps1 -Mode Check
./scripts/sync-slash-prompt-modes.ps1 -Mode Apply
```

세부 문서:

- [공통 실행 계약](SKILL.md)
- [10개 모드별 입력·출력·중단 조건](references/mode-contracts.md)
- [공개 근거와 성능 평가법](references/evidence-and-evaluation.md)
- [플랫폼별 별칭과 대소문자 계약](references/platform-adapters.md)
- [평가 사례](evals/cases.json)

## 라이선스와 출처

이 폴더의 사용자 제작 Skill은 [MIT License](LICENSE.md)로 제공합니다. 이 라이선스는
상위 저장소 전체나 `skills/external/`의 제3자 자료에 적용되지 않습니다. 공개 연구와 공식
문서는 설계 근거로 링크했을 뿐 해당 원문이나 코드를 이 Skill에 재배포한 것이 아닙니다.

설계 고증과 반증 기록은
[전수분석 보고서](../../research/p1-gpt-cheatkey-modes-report-source.md)에 보존합니다.
