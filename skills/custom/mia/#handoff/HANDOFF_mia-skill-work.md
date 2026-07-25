# HANDOFF — MIA 스킬 제작·정리 작업 인계

> 생성: 2026-07-26 (Claude Opus 4.8, Claude Code) · 목적: 새 대화창에서 데이터 손실 없이 이어가기
> 호칭: 사용자는 **윤겸스**, 한국어 응답, 기술용어 영문 병기.
> 신뢰 순서: **코드·파일 실측 > 이 문서 > 기억**. 이 문서는 스냅샷이니 새 창은 항상 현재 파일을 다시 읽어 확인한다.

---

## 0. 30초 요약

MIA 시리즈 커스텀 스킬을 **카탈로그(260718) 단일 정본**으로 통일하고, **3대 AI 도구
(Claude Code·Antigravity·Codex)에 전역 배포**하는 작업. 이번 세션에 백신 테스트 스킬 제작 +
교본 3장 + 카탈로그 전수정리(forge 폐기·plan-review-execute 개명·중첩 제거)를 완료하고 전부
커밋·푸시했다. 두 저장소·3도구 모두 clean·동기화 상태. 다음은 §5(미완) 참고.

---

## 1. 경로 지도 (실측 기준)

> ⚠️ 워크스페이스가 평탄화됐다: 옛 경로의 `-antigravity-workspace` 중간 폴더가 **없어졌다**.
> 그리고 그 이전엔 `-google-workspace`였다 → 현재는 `-agentic-ai-workspace`.

| 대상 | 절대 경로 |
|---|---|
| **vibe-clinic 저장소** | `D:/D_Workspace_NB/-agentic-ai-workspace/260709_vibe-clinic` |
| **스킬 카탈로그 저장소** | `D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization` |
| 카탈로그 mia 스킬 | `<카탈로그>/skills/custom/mia/` (`1_mia-skill-compiler`, `2_mia-vaccine-test`, `3_mia-strategic`, `README.md`) |
| 이 handoff | `<카탈로그>/skills/custom/mia/#handoff/HANDOFF_mia-skill-work.md` |
| 교본(개념) | `<vibe-clinic>/handbook/` (01~08장) |
| 3도구 전역 스킬 | Claude `~/.claude/skills/` · Antigravity `~/.gemini/config/skills/` · Codex `~/.codex/skills/` |
| 전역 스킬 백업 | `%TEMP%/claude/.../scratchpad/mia-global-backup-*` (되돌리기용) |

원격: vibe-clinic `git@github-gyeoms:gyeomsVibe/260709_vibe-clinic.git`,
카탈로그 `https://github.com/gyeomsVibe/260718_agentic-ai-platform-optimization.git`. 둘 다 `main`.

---

## 2. 3대 스킬 정본 (확정)

카탈로그가 **단일 정본**(single source of truth). 3도구 전역엔 카탈로그를 그대로 배포한다.

| 스킬 | 카탈로그 정본 위치 | 한글명 / 역할 |
|---|---|---|
| `mia-skill-compiler` | `1_mia-skill-compiler/candidates/mia-skill-compiler/` | MIA 스킬 컴파일러 — 아이디어·GPT·문서·코드를 스킬로 생성·검증하는 워크벤치 |
| `mia-vaccine-test` | `2_mia-vaccine-test/` | MIA 백신테스트 — 실패를 일부러 만들어 숨은 결함을 찾고 항체(진단)를 남김 |
| `mia-strategic` | `3_mia-strategic/` | 'MIA 전략절차' — 기획·검토·실행·검증 4단계 (구 `plan-review-execute`) |

- **`mia-skill-forge` 는 폐기**됐다(compiler에 흡수). 전역에서 제거, 이력만 `1_mia-skill-compiler/candidates/mia-skill-forge/`.
- 표준 폴더 형식(3_mia-strategic 모범): `SKILL.md` + `references/` + `agents/openai.yaml` + `README.md`.

### 트리거 규칙 (오발동 방지 — 매우 중요)

- **`MIA` + 모드용어(붙여 씀) + `해줘`|`발동`.** 어미 둘은 동일 취급.
- `mia-vaccine-test`: `MIA 백신테스트 해줘`, `MIA 변이테스트 발동`, `MIA 실사용진단해줘`, `MIA 실패주입해줘`, `MIA 항체 만들어줘`, `MIA 숨은결함 찾아줘`
- `mia-strategic`: `MIA모드 발동` 또는 `$mia-strategic`
- **모드용어를 띄어 쓰거나(`백신 테스트`) `MIA` 접두사가 없으면 발동 안 함.** 백신테스트는 코드를 일부러 망가뜨리므로 오발동이 미발동보다 비싸다.

---

## 3. 이번 세션에 완료한 것 (전부 커밋·푸시됨)

**vibe-clinic (260709):**
- `handbook/` 06(변이 테스트)·07(항체 설계, 파이썬 브리지 실측 포함)·08(임상 시험) 추가
- `mia-vaccine-test` 스킬 최초 제작 → 이후 카탈로그 정본과 바이트 일치(`735b311`)
- `sync-rules.js` 결함 수정(파티션 후 경로 깨짐) + `--check` 모드 + 테스트, `run --filter` 추가, 변이 테스트로 summarize 중복 제거 등
- 병렬 세션의 워크스페이스 경로 동기화(google→agentic) 마무리 커밋(`9d45cdc`)
- HEAD `9d45cdc`, 트리 clean, origin 동기화. 백엔드 테스트 52 + 프론트 10 통과.

**카탈로그 (260718):**
- `2_mia-vaccine-test` 를 안티그래비티 저질본(2.2KB)에서 **실제 정본(15KB)** 으로 재구축 + 표준 형식(`5a37101`)
- 카탈로그 `README.md` 정확화(3도구 경로·forge 폐기·strategic 개명 명시)
- `[user data]` 문서 3건 커밋(`2cdb270`) — **영상(.mp4)은 제외**, `.gitignore`에 `*.mp4` 등 전역 차단
- HEAD `2cdb270`, mia 트리 clean, origin 동기화.

**3도구 전역:**
- 3대 스킬 **바이트 동일** 배포, forge·plan-review-execute 제거, `<이름>/<이름>` 중첩 버그 전부 정리.
- 작업 전 전역 스킬 백업 확보(§1 백업 경로).

---

## 4. 핵심 결정·규칙 이력

- **정본 = 카탈로그 단일 정본** (윤겸스 결정). vibe-clinic의 `.claude/skills/mia-vaccine-test`는 카탈로그와 동기화된 사본.
- **영상 커밋 금지** (`.gitignore` 차단). 대상 폴더에 있어도 올리지 않는다. 로컬 원본은 보관.
- **동기화 규칙**(윤겸스 상시): 커밋하면 별도 push 승인 없이 origin/main 자동 동기화하되 — 원격 미분기 + 이번 세션 변경만 분리 + 검증 통과 + 민감파일 없음일 때만. `git add -A` 금지, 선별 스테이징. 애매하면 중단·보고.
- **형제 워크스페이스**(260718 등)는 윤겸스 명시 승인이 있을 때만 수정. 이번 세션엔 승인받음.
- 보고는 **고정 6분류**: 실행한 것 / 발견한 것 / 수정한 것 / 다시 실행한 검증 / 아직 실행하지 않은 것 / 다음 승인 필요 항목.

---

## 5. 미완 / 다음 작업 (우선순위)

1. **[확인 대기] 로컬 영상 삭제 여부** — `<카탈로그>/[user data]/260723_...플로그인.mp4` (1.9MB) 로컬 원본을 지울지 윤겸스 확인 대기. git·원격에서는 이미 완전 제거됨.
2. **[선택] mia-skill-compiler 세부 정합성** — 3도구에 이미 통일 배포됐으나(11554), 카탈로그 워크벤치 구조(candidates/evals/fixtures) 정리는 미완. 윤겸스가 "vaccine-test + skill-compiler 전수정리"를 택했으므로 compiler 워크벤치 검토가 남은 범위.
3. **[선택] `.agents/skills` 로컬 사본 동기화** — 우선순위 낮음. 카탈로그가 정본이므로 필요 시 미러.
4. **[정보] vibe-clinic은 병렬 세션이 활동 중일 수 있음** — 새 작업 전 `git -C <vibe-clinic> status`로 미커밋 확인. 이번 세션 종료 시엔 clean이었음.

---

## 6. 금지·주의 (오판 방지)

- **비밀정보 금지**: `.env`·API 키·자격증명을 읽거나 출력하지 않는다. 이 handoff에도 없다.
- **git add -A / git clean / reset --hard 금지.** 선별 스테이징만.
- **force push는 방금 만든 최신 커밋 정정 등 안전한 경우 + 명시 승인에만.** 이번에 영상 제거 때 `--force-with-lease` 1회 사용함(카탈로그).
- 안티그래비티가 남긴 산출물은 **품질 낮을 수 있음** — 실측으로 검증하고 신뢰하지 말 것(이번에 저질 mia-vaccine-test 확인·교체함).
- 스킬 설명 캐시: 새로 만든/바꾼 스킬의 description은 **새 세션부터** 반영된다.

---

## 7. 검증 명령 (새 창에서 상태 재확인)

```bash
# 두 저장소 clean·동기화 확인
git -C "D:/D_Workspace_NB/-agentic-ai-workspace/260709_vibe-clinic" status -sb
git -C "D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization" status -sb

# 3도구 스킬 통일 확인 (전부 mia-skill-compiler / mia-strategic / mia-vaccine-test 여야)
ls ~/.claude/skills | grep -iE 'mia|strategic'
ls ~/.gemini/config/skills | grep -iE 'mia|strategic'
ls ~/.codex/skills | grep -iE 'mia|strategic'

# 원격에 영상 없음 확인 (카탈로그)
git -C "D:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization" ls-tree -r origin/main --name-only | grep -i '.mp4' || echo "영상 없음 OK"
```
