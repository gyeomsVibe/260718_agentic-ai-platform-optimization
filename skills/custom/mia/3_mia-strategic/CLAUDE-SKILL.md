---
name: mia-strategic
description: Activate the MIA strategic hypothesis-verification workflow when the user says "MIA모드 발동", "MIA 전략스킬 발동", "MIA 전략절차 발동", "MIA 전략스킬 해줘", "MIA 전략절차 해줘", or invokes $mia-strategic for planning, review, execution, or validation.
license: MIT
argument-hint: "MIA모드 발동: [기획|검토|실행|검증] <목표>"
user-invocable: true
---

# 🎯 'MIA 전략절차' 스킬 (MIA Strategic Skill)
> **풀네임**: 전략적 가설 검증 스킬 (Strategic Hypothesis Verification Skill)

## 개요
'MIA 전략절차' 스킬은 가설 검증(Evidence-backed Hypothesis Testing) 기반으로 제품, 비즈니스, 주요 기술 결정을 기획 -> 검토 -> 실행 -> 검증의 4단계로 오차 없이 전개하는 전략적 프레임워크입니다.

사용자가 **"MIA모드 발동"**, **"$mia-strategic"**, 또는 전략적 가설 검증을 요청할 때 활성화됩니다.

---

## 4단계 실행 프로세스 (4-Stage Workflow)

| 단계 (Stage) |목적 (Purpose) | 권한 및 범위 |
|---|---|---|
| **1. 기획 (Frame)** | 문제 정의, 이해관계자, 목표 성과, 가설 및 증거 지도 작성 | 읽기 및 기획 문서 수립 |
| **2. 검토 (Review)** | 대안 비교, 가치/기술/비즈니스/위험도 종합 검토, Go/Pivot/No-Go 결정을 위한 Decision Memo 작성 | 읽기 전용 검토 |
| **3. 실행 (Execute)** | 승인된 가설의 최소 단위 실험(MVP / Scoped Edit) 정의 및 실행 카드(Delivery Card) 작성 | 승인된 가역적 로컬 수정만 수행 |
| **4. 검증 (Verify)** | 임계치 대비 실제 수집 증거 비교 및 학습 보고서(Learning Report) 작성 | 결과 검증 및 차기 가설 수립 |

---

## Professional Workflow 상세 수칙

### 1. 기획 (Frame the Opportunity)
- Opportunity Brief 작성 (결정 과제, 데드라인, 제약 조건)
- Target User & Observable Problem 정의
- Measurable Success Signal & Non-goals 명시
- Evidence Map (인증된 사실, 가설, 불확실성 축소 방안) 작성

### 2. 검토 (Make the Decision Auditable)
- 2~3가지 실질적 대안 비교
- 4대 렌즈 평가:
  - **Value (가치성)**: 실제 사용자/이해관계자 문제를 해결하는가?
  - **Feasibility (실현가능성)**: 리소스, 기술, 시간, 의존성이 지원되는가?
  - **Viability (지속가능성)**: 비용, 보안, 운영, 정책적 영향이 허용되는가?
  - **Risk (위험도)**: 최대 영향 불확실성 및 롤백 경로 확인
- Decision Gate 결정: `Go`, `Pivot`, `No-Go`, `Research More`

### 3. 실행 (Deliver the Smallest Useful Proof)
- `Go` 결정에 따라 최소 단위 가역적 실험 정의
- Milestones, Acceptance Criteria, Success Threshold 지정
- 승인된 범위 내 소스코드/설정 가역적 수정 및 검증 실행

### 4. 검증 (Close the Learning Loop)
- 임계치 대비 실제 수집된 증거 기록
- `Iterate`, `Scale`, `Stop` 추천 제출 및 학습 리포트 작성

---

## Execution & Quality Control Rules
- 결정을 내릴 때 추측이 아닌 실측 증거(Observed Evidence)를 기반으로 작성합니다.
- 파괴적 행위, 외부 배포, 계정 변경 등 비가역적 행위는 개별 명시적 승인 필요.
