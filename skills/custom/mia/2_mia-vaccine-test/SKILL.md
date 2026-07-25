---
name: mia-vaccine-test
description: MIA 백신 테스트(MIA Vaccine Test) - 인계 계약 및 주요 기능에 변이(Mutation)를 재주입하여 항체(Antibody)가 결함을 탐지·박멸(KILLED)하는지 검증하고 백신 치료 및 무오류 자가진단을 수행합니다. $mia-vaccine-test 또는 "백신 테스트 해줘", "항체 검증해줘" 요청 시 사용합니다.
---

# 💉 MIA Vaccine Test (MIA 백신 테스트 스킬)

## 개요
MIA Vaccine Test는 워크스페이스의 코드베이스 및 인계(Handoff) 계약, 보안 가드레일에 **돌연변이(Mutation)를 재주입**하여 기존 항체(Antibody Test)가 결함을 정확히 탐지하고 박멸(KILLED)하는지 실측 검증하는 무오류 진단·치료 체계입니다.

---

## 🔬 핵심 실행 절차 (5대 수칙)

### Step 1. 기저 진단 (Baseline Audit)
- `npm run check` 또는 해당 프로젝트의 전체 진단 스위트 실행.
- 기존 수칙 및 테스트의 100% 그린라이트(PASS) 상태를 먼저 확인.

### Step 2. 무오류 결함 탐지 (Pre-existing Defect Check)
- 인계 레코드(`handoff/active/*.md`)의 `work_sha` 및 상태 실측.
- 불일치 발견 시 `HANDOFF_READY` -> `STALE`로 즉시 무오류 교정.

### Step 3. 변이 재주입 (Mutation Injection)
- 검증 대상 로직에 미세 결함/금지 패턴 무력화 코드 주입 (예: `forbiddenContent = []`).
- 테스트 실행 후 해당 변이가 항체에 의해 **FAIL(KILLED)** 조치되는지 확인.
- 변이가 테스트를 통과(SURVIVED)할 경우, 즉시 신규 항체 테스트 케이스를 수록.

### Step 4. 변이 원복 및 전수 완치 (Revert & Cure)
- 변이 코드를 원본으로 즉시 원복.
- 전체 테스트 스위트를 재실행하여 100% 그린라이트 확인.

### Step 5. SAFE-SYNC 동기화 및 보고
- SAFE-SYNC 게이트 수칙 준수 (이번 에이전트 변경 파일만 명시적 스테이징).
- 임의의 `git add .` 사용 엄금.
- 결과 보고서 작성.

---

## 🛠️ 스크립트 및 참조 자산
- `references/vaccine-protocol.md`: 백신 테스트 설계 원칙 및 변이 주입 패턴
- `scripts/run_vaccine_test.js`: 백신 검증 자동화 스크립트
