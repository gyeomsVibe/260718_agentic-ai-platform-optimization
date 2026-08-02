# MIA 스킬 작성 표준 — 최엄격 도구 기준

> 정본 위치: `skills/custom/mia/SKILL_AUTHORING_STANDARD.md`
> 강제 수단: `scripts/validate-skill-manifests.py` (배포 전 자동 차단)
> 제정 근거: 2026-08-02 3대 도구 전수 검사에서 관측한 실측 결과

## 0. 왜 최엄격 기준인가

같은 정본 파일을 세 도구가 읽지만 **파서 엄격도가 다릅니다.** 관대한 도구에서만
테스트하면 결함이 은폐됩니다. 실제로 그런 일이 있었습니다.

| 도구 | YAML 파서 | `allow_implicit_invocation` | 결함 노출 |
|---|---|---|---|
| **Codex** | **엄격** — 위반 시 스킬 로딩 거부 | **준수** | 즉시 드러남 |
| Claude Code | 관대 — 잘못된 YAML도 통과 | 무시(전부 노출) | **은폐됨** |
| Antigravity | 동일 정본 사용 | — | 정본 결함 그대로 상속 |

**관측된 사고**: `mia-strategic` 의 `description` 이 작은따옴표로 시작해
(`description: 'MIA 전략절차' 스킬 — …`) YAML이 이를 완결된 인용 스칼라로 읽고
뒤따르는 텍스트를 문법 오류로 판정했습니다. Codex는 세 경로 모두에서
`failed to load skill … invalid YAML` 로 거부했고, Claude Code는 아무 경고 없이
정상 동작했습니다. 결함은 3주간 발견되지 않았습니다.

**따라서 표준은 Codex 기준으로 고정합니다.** Codex를 통과하면 나머지도 통과합니다.

## 1. SKILL.md frontmatter

- 파일은 반드시 `---` 로 시작하고 `---` 로 닫는다.
- `name`, `description` 은 필수이며 빈 값을 허용하지 않는다.
- `name` 은 배포 폴더명과 정확히 일치해야 한다.
- **값을 인용부호로 시작하지 않는다.** 시작했다면 반드시 같은 부호로 끝내야 한다.
  - ❌ `description: 'MIA 전략절차' 스킬 — 설명…`  ← 인용 스칼라 조기 종료
  - ✅ `description: MIA 전략절차 스킬 — 설명…`     ← 평문 스칼라
- 평문 스칼라 안에 `: `(콜론+공백)을 넣지 않는다. YAML이 매핑으로 오인한다.
- 평문 스칼라 안의 큰따옴표는 안전하다. 트리거 문구 인용에 사용한다.

## 2. agents/openai.yaml (Codex 표시·발동 계약)

- `interface.display_name`, `interface.short_description`, `interface.default_prompt` 필수.
- `policy.allow_implicit_invocation` 을 **명시**한다. 생략하면 도구 기본값에 의존하게 된다.
  - `true` — Codex 사용가능 목록에 노출. 안전한 스킬에만 부여한다.
  - `false` — 목록에서 감춰지고 `$스킬명` 명시 호출만 가능하다.
    코드를 의도적으로 파괴하는 계열(`mia-vaccine-test`)은 반드시 `false`.

> 주의: Claude Code 는 이 플래그를 무시하고 모든 스킬을 노출한다. 즉
> **같은 스킬이 Codex 에서는 안 보이고 Claude 에서는 보이는 것이 정상 동작**이다.
> "Codex 목록에 없음"이 곧 결함은 아니다.

## 3. 트리거 계약

- 형식: `MIA` 접두사 + 모드용어(**붙여 씀**) + `발동` 또는 `해줘`.
- 접두사와 붙여쓰기를 모두 요구해 오발동을 막는다.
- **실사용 변형을 반드시 description 에 열거한다.** 계약에 없는 표현은 발동하지 않는다.
  2026-08-02 에 소유자 본인이 `MIA 전략스킬 발동` 으로 호출했으나 계약에는
  `MIA모드 발동` 만 있었다. 사람이 의도를 읽어 넘어갔을 뿐 기계 매칭은 실패였다.

## 4. 배포 게이트 (우회 금지)

```powershell
pwsh -File skills/custom/mia/scripts/sync-mia-catalog.ps1 -Mode Check   # 검증만
pwsh -File skills/custom/mia/scripts/sync-mia-catalog.ps1 -Mode Apply   # 검증 후 배포
```

`sync-mia-catalog.ps1` 은 스테이징 **이전에** `validate-skill-manifests.py` 를 실행하고,
오류가 하나라도 있으면 `throw` 로 배포를 중단한다. 검증기가 없거나 실행 불가여도 중단한다.
**조용히 건너뛰지 않는다** — 이번 결함이 통과한 이유가 바로 검증 부재였다.

## 5. 변경 후 확인 절차

1. `-Mode Check` 로 15개 배포 대상이 전부 `MatchesCanonical=True` 인지 확인한다.
2. Codex 로 실발동을 확인한다. 이것이 최종 관문이다.
   ```bash
   codex exec "mia-strategic 사용 가능 여부를 있음/없음으로만 답하라."
   ```
   출력에 `failed to load skill` 이 없어야 한다.
3. 스킬 설명 캐시는 **새 세션부터** 반영된다. 기존 세션에서 안 보인다고 실패로 판단하지 않는다.
