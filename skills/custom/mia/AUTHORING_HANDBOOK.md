# MIA 시리즈 커스텀 스킬 제작 교본

> **이 문서가 MIA 스킬 제작의 단일 진입점이다.** 새 스킬을 만들거나 기존 스킬을 고칠 때
> 여기서 시작한다. 규격은 3대 도구 중 **가장 엄격한 Codex 기준**으로 고정한다.
>
> 강제 수단: `scripts/validate-skill-manifests.py` — 위반 시 배포가 중단된다.
> 최종 개정: 2026-08-03 (3대 도구 실발동 검증 완료 시점)

---

## 0. 문서 지도 — 무엇을 어디서 보는가

교본은 **실무 절차와 준수 규격**을 담는다. 깊은 지식은 아래 문서가 정본이며 여기서 복제하지 않는다.

| 알고 싶은 것 | 참조할 문서 |
|---|---|
| **제작 절차·규격·검증** (지금 이 문서) | `AUTHORING_HANDBOOK.md` |
| 설계 철학 — 20개 불변 상위원칙, 모듈 헌법, 평가 사다리 | [`skill-creation-bible.md`](1_mia-skill-compiler/candidates/mia-skill-compiler/references/skill-creation-bible.md) |
| 플랫폼별 설치 경로·어댑터 계약 | [`platform-skill-contracts.md`](1_mia-skill-compiler/candidates/mia-skill-compiler/references/platform-skill-contracts.md) |
| 결함 주입·변이·실사용 진단 프로토콜 | [`vaccine-protocol.md`](2_mia-vaccine-test/references/vaccine-protocol.md) |
| 카탈로그 구성과 배포 개요 | [`README.md`](README.md) |

**충돌 시 우선순위**: 이 교본의 §2 규격 > 다른 문서. 규격은 도구가 실제로 강제하는 것이라 타협 대상이 아니다.

---

## 1. 왜 최엄격 기준인가

세 도구가 **같은 정본 파일**을 읽지만 파서와 정책 준수 수준이 다르다. 관대한 도구에서만
확인하면 결함이 은폐된다. 실제로 세 번 그랬다.

| 도구 | YAML 파서 | `allow_implicit_invocation` | PowerShell |
|---|---|---|---|
| **Codex** | **엄격** — 위반 시 스킬 로딩 거부 | **준수** — false면 목록에서 감춤 | — |
| Claude Code | 관대 — 잘못된 YAML도 통과 | 무시 — 전부 노출 | — |
| Antigravity | 동일 정본 상속 | 미확인 | — |
| Windows PowerShell 5.1 | — | — | **엄격** — BOM 없으면 CP949 오독 |
| PowerShell 7 (pwsh) | — | — | 관대 — BOM 없어도 UTF-8 |

**규칙: 가장 엄격한 쪽을 통과시켜라. 그러면 나머지는 자동으로 통과한다.**
반대로 하면 통과했다는 사실이 아무것도 보장하지 않는다.

---

## 2. 준수 규격 (위반 시 배포 차단)

### 2.1 SKILL.md frontmatter

- 파일은 `---` 로 시작하고 `---` 로 닫는다.
- `name`, `description` 필수. 빈 값 불가.
- `name` 은 배포 폴더명과 **정확히** 일치한다.
- **값을 인용부호로 시작하지 않는다.** 시작했다면 같은 부호로 끝내야 한다.

```yaml
# ❌ YAML이 'MIA 전략절차'를 완결된 스칼라로 읽고 뒤 텍스트를 오류 처리한다
description: 'MIA 전략절차' 스킬 — 전략적 가설 검증

# ✅ 평문 스칼라. 내부 큰따옴표는 안전하다
description: MIA 전략절차 스킬 — 전략적 가설 검증. "MIA모드 발동" 시 활성화된다.
```

- 평문 스칼라 안에 `: `(콜론+공백)을 넣지 않는다. YAML이 매핑으로 오인한다.

### 2.2 agents/openai.yaml (Codex 표시·발동 계약)

```yaml
interface:
  display_name: "표시 이름"
  short_description: "한 줄 설명"
  default_prompt: "$스킬명 기본 호출문"
policy:
  allow_implicit_invocation: true   # 또는 false — 반드시 명시
```

- `interface` 3개 키 필수.
- `policy.allow_implicit_invocation` 을 **반드시 명시**한다. 생략하면 도구 기본값에 의존한다.
  - `true` — Codex 사용가능 목록에 노출. 안전한 스킬에만.
  - `false` — 목록에서 감춰지고 `$스킬명` 명시 호출만 가능.
    **코드를 의도적으로 파괴하는 계열은 반드시 `false`.**

> **중요**: Claude Code는 이 플래그를 무시하고 전부 노출한다. 따라서 **같은 스킬이 Codex에서는
> 안 보이고 Claude에서는 보이는 것이 정상 동작**이다. "Codex 목록에 없음"을 결함으로 오판하지 마라.

### 2.3 폴더 구조

```
<스킬명>/
  SKILL.md            필수 — 얇은 코어 (바이블 원칙 5)
  agents/openai.yaml  필수 — Codex 어댑터
  references/         선택 — 세부 지식
  scripts/            선택 — 반복·결정적 실행
```

`<스킬명>/<스킬명>/` 이중 중첩 절대 금지.

### 2.4 인코딩

- 한국어가 든 `.ps1` 은 **UTF-8 BOM 필수**. BOM이 없으면 Windows PowerShell 5.1이
  CP949로 읽어 생성물이 깨진다. `pwsh` 로만 돌리면 드러나지 않는다.
- `.md`·`.py`·`.yaml` 은 BOM 없는 UTF-8.

---

## 3. 트리거 계약 설계

**형식**: `MIA` 접두사 + 모드용어(**붙여 씀**) + `발동` 또는 `해줘`

접두사와 붙여쓰기를 **모두** 요구해 오발동을 막는다. 코드를 파괴하는 계열은 특히 엄격히 한다.

```
✅ MIA 백신테스트 발동      접두사 O, 붙여씀 O
❌ 백신 테스트 해줘          접두사 X, 띄어씀  → 발동하지 않는 것이 정답
```

**실사용 변형을 반드시 열거한다.** 계약에 없는 표현은 발동하지 않는다.
2026-08-02에 소유자 본인이 `MIA 전략스킬 발동` 으로 호출했으나 계약에는 `MIA모드 발동` 만
있었다. 사람이 의도를 읽어 넘어갔을 뿐 기계 매칭은 실패였다.

새 스킬을 만들 때는 **자기가 실제로 부를 법한 문장 3개 이상**을 적어보고 전부 계약에 넣어라.

---

## 4. 제작 절차 7단계

1. **필요성 증명** — 새 스킬이 정말 필요한가? (바이블 원칙 2) 기존 스킬 확장으로 되면 그렇게 한다.
2. **정본 작성** — `skills/custom/mia/<번호>_<이름>/` 에 §2 규격대로. 모범: `3_mia-strategic/`.
3. **트리거 계약 확정** — §3. 실사용 변형 열거.
4. **정책 결정** — `allow_implicit_invocation` 을 위험도에 맞춰 명시.
5. **검증기 등록** — `scripts/validate-skill-manifests.py` 의 `SKILLS` 에 경로 추가.
6. **배포 정의 등록** — `scripts/sync-mia-catalog.ps1` 의 `$definitions` 에 추가.
7. **배포·검증** — §5, §6.

---

## 5. 배포와 게이트

```powershell
pwsh -File skills/custom/mia/scripts/sync-mia-catalog.ps1 -Mode Check   # 검증만
pwsh -File skills/custom/mia/scripts/sync-mia-catalog.ps1 -Mode Apply   # 검증 후 배포
```

배포는 **15개 위치**(workspace / 공용 사용자 / Codex / Claude 각 3개 + Antigravity 2개 + 플러그인 1개)에
정본을 복사하고 SHA-256으로 대조한다. `Apply` 는 기존 설치본을 `~/.mia-skill-backups/<timestamp>/` 에
자동 백업한다.

**게이트는 우회할 수 없다.** `sync-mia-catalog.ps1` 은 스테이징 **이전에**
`validate-skill-manifests.py` 를 실행하고, 오류가 하나라도 있으면 `throw` 로 중단한다.
검증기가 없거나 실행 불가여도 중단한다. **조용히 건너뛰지 않는다** — 결함이 통과했던
이유가 정확히 검증 부재였다.

CI 편입: `npm run check` 가 `skills:check`(배포 정합성)와 `skills:test`(항체)를 포함한다.

---

## 6. 검증 회로 — 파일 일치는 발동이 아니다

해시가 같다는 것과 도구가 스킬을 불러온다는 것은 **다른 명제**다. 세 도구를 각각 확인한다.
한 도구의 성공을 다른 도구에 상속하지 마라.

| 도구 | 확인 방법 | 통과 기준 |
|---|---|---|
| **Codex** | `codex exec "<스킬명> 사용 가능 여부를 있음/없음으로만 답하라."` | 출력에 `failed to load skill` 이 **없어야** 한다 |
| **Claude Code** | 새 세션의 사용 가능 스킬 목록 확인 | 스킬명이 보인다 |
| **Antigravity** | 새 대화창에 트리거 문구 입력 | 스킬 고유 절차가 시작된다 |

**오발동 방어도 함께 검증한다.** 접두사 없이·띄어쓰기로 호출해 **발동하지 않는지** 확인한다.
발동하면 계약이 뚫린 것이다.

> 스킬 설명 캐시는 **새 세션부터** 반영된다. 기존 세션에서 안 보인다고 실패로 판단하지 마라.

---

## 7. 항체 원칙 — 테스트는 변이를 죽여야 한다

백신테스트로 결함을 찾았으면 항체(회귀 테스트)를 남긴다. 그런데 **항체가 진짜인지 반드시
검증하라.**

2026-08-02에 남긴 1차 항체는 "정상 입력에서 exit 0" 만 확인했다. 검증 가드를 통째로 제거하고
다시 돌렸더니 **그대로 통과**했다. 지키려던 대상을 전혀 지키지 못한 것이다.

**항체 작성 규칙**

1. 정상 통과만 확인하는 테스트는 항체가 아니다. **결함을 주입했을 때 실패하는지**가 본질이다.
2. 검증 대상이 픽스처를 받을 수 있어야 한다. 그래야 결함 주입 테스트를 쓸 수 있다.
   (`validate-skill-manifests.py --catalog <경로>`)
3. 작성 후 **가드를 무력화한 변이를 재주입**해 테스트가 실패하는지 확인한다. 통과하면 가짜다.
4. 느슨한 단언을 쓰지 마라. `output.includes('0')` 같은 것은 거의 항상 참이라 무의미하다.

현재 항체: `tests/validate-skill-manifests.test.mjs` — 6종, 변이 4종 사살 확인 완료.

---

## 8. 출고 전 체크리스트

- [ ] `SKILL.md` frontmatter 가 엄격 YAML 파서를 통과한다 (인용부호 시작 없음)
- [ ] `name` 이 폴더명과 일치한다
- [ ] `agents/openai.yaml` 3개 키 + `allow_implicit_invocation` 명시
- [ ] 트리거 계약에 실사용 변형이 3개 이상 열거돼 있다
- [ ] 한국어 `.ps1` 에 UTF-8 BOM 이 있다
- [ ] `sync-mia-catalog.ps1 -Mode Check` 가 전 타깃 `MatchesCanonical=True`
- [ ] `npm run check` 가 exit 0
- [ ] **Codex 새 세션에서 로딩 오류 없이 인식된다**
- [ ] **Claude Code 새 세션 목록에 보인다**
- [ ] **Antigravity 새 대화창에서 트리거로 발동한다**
- [ ] 오발동 방어가 작동한다 (접두사·붙여쓰기 없이는 발동 안 함)
- [ ] 새로 만든 항체가 대응 변이를 실제로 죽인다

세 도구를 모두 통과하기 전에는 `cross_platform_verified` 를 선언하지 마라.

---

## 9. 사고 기록 — 규칙의 근거

규칙마다 실제 사고가 있다. 근거 없이 만든 규칙은 없다.

| 날짜 | 사고 | 도입한 규칙 |
|---|---|---|
| 2026-08-02 | `description: 'MIA 전략절차' …` 가 YAML 인용 스칼라로 오인돼 Codex가 3개 경로 전부 로딩 거부. Claude는 통과시켜 3주간 은폐 | §2.1 인용부호 시작 금지 + 엄격 파서 게이트 |
| 2026-08-02 | 소유자가 `MIA 전략스킬 발동` 으로 호출했으나 계약에 없어 기계 매칭 실패 | §3 실사용 변형 열거 의무 |
| 2026-08-02 | `sync-mia-catalog.ps1` BOM 소실 → PowerShell 5.1이 CP949로 읽어 Claude 어댑터 생성물 손상. `pwsh` 로만 돌려 은폐 | §2.4 BOM 필수 + 검증기 BOM 가드 |
| 2026-08-02 | `mia-vaccine-test` 가 Codex 목록에 없어 결함으로 오판할 뻔함 — 실제로는 `allow_implicit_invocation: false` 설계대로 동작 | §2.2 정책 명시 의무 + 오판 방지 주석 |
| 2026-08-02 | 백신테스트 항체가 정상 케이스만 확인해 가드 제거 변이가 생존 | §7 항체 원칙 |
| 2026-08-02 | `Get-FileHash` 모듈 자동 로드 실패로 `npm run check` 전체 중단 | 배포 스크립트에서 환경 의존 cmdlet 제거 |

---

## 10. 최신성 관리

- 도구 버전 업데이트 후에는 §6 검증 회로를 다시 돌린다. 설치 경로와 지원 필드는 바뀔 수 있다.
- 새 사고가 나면 §9에 기록하고, 대응 규칙을 §2~§7에 반영하며, 가능하면 **검증기에 가드를 추가**한다.
  문서만 고치면 같은 결함이 다시 통과한다.
- 이 교본이 실제 도구 동작과 어긋나면 **도구가 정본**이다. 실측을 우선하고 교본을 고쳐라.
