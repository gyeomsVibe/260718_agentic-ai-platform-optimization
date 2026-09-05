# 교차 플랫폼 슬래시 어댑터

## 문제

`slash-prompt-modes` 본체의 description만으로는 모든 도구에서 `/OPTIMIZE` 같은 입력을 동일하게 처리할 수 없다. Claude Code는 `/이름`을 해당 디렉터리 이름의 Skill 호출로 먼저 해석하고 로컬 명령에서 대문자 `/OPTIMIZE`와 소문자 `/optimize`를 동일하게 정규화하지 않는다. 따라서 명령 이름별 얇은 Skill 별칭과 Claude용 대문자 호환 command가 필요하다.

## 매핑

| 사용자 입력 | 별칭 디렉터리 | 정본 모드 |
|---|---|---|
| `/SELFREFINE` | `selfrefine/` | `/SELFREFINE` |
| `/REDTEAM` | `redteam/` | `/REDTEAM` |
| `/ELI10` | `eli10/` | `/ELI10` |
| `/DEEPDIVE` | `deepdive/` | `/DEEPDIVE` |
| `/ALT3` | `alt3/` | `/ALT3` |
| `/CRITIC` | `critic/` | `/CRITIC` |
| `/OPTIMIZE` | `optimize/` | `/OPTIMIZE` |
| `/STEPBYSTEP` | `stepbystep/` | `/STEPBYSTEP` |
| `/EXPERT` | `expert/` | `/EXPERT` |
| `/STRUCTURED FEW-SHOT` | `structured/` + 첫 인수 `FEW-SHOT` | `/STRUCTURED FEW-SHOT` |

소문자 별칭은 공통 본체와 모드 계약을 상대 링크로 읽는다. 정책과 성능 근거를 별칭에 복제하지 않는다. `scripts/build-slash-aliases.ps1`는 세 도구용 Skill 별칭을, `scripts/build-claude-uppercase-commands.ps1`는 Claude Code의 대문자 호환 command를 생성한다.

정본 토큰은 대문자로 문서화하지만 내부 비교는 ASCII 대소문자를 구분하지 않는다. Claude Code에서는 공식 Skill 이름 규격에 맞춘 소문자 Skill과 대문자 command가 각각 양 끝 표기를 보장한다. 임의 혼합 대소문자 표기는 Claude Code 네이티브 파서가 공식 정규화 계약을 제공하지 않으므로 런타임 보장 범위가 아니다.

## 설치 경계

- 공통 본체: `slash-prompt-modes/`
- 생성 별칭: 위 10개 디렉터리와 Claude Code 전용 대문자 command 10개
- 설치 대상마다 기존 동일 이름이 하나라도 있으면 덮어쓰지 않고 중단한다.
- 설치 후 원본과 본체 파일 해시, 별칭 집합, 각 `SKILL.md` 구조를 검증한다.
- 롤백은 이번 설치가 새로 만든 11개 디렉터리만 제거하는 것이다.
