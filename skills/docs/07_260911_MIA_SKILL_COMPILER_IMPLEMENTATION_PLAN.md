# [구현 계획서] MIA Skill Compiler 및 skill-creation-bible.md 최적화 정제 (Alternative 2)

최신 챗봇 정본(`gyeomsVibe/-260901_gpt-chatbot-section/docs` 11대 문헌)의 핵심 철학인 **회수 시점 모듈화(KMGS 8대 게이트)**, **품질 신경회로(QVRC 10단계 & ERR 7항목 & $Q^3$ 공식)**, **Frame-First 사전배분 헌법**, **Standalone Visual Artifacts**를 Agentic AI 3대 도구(Antigravity, Claude Code, Codex) 환경에 맞추어 완전하게 최적화 승화시키는 정밀 개정 작업입니다.

---

## 1. 사용자 검토 요구사항 (User Review Required)

> [!IMPORTANT]
> **핵심 개정 원칙: "지능 철학은 온전히 계승하고, 실행 메커니즘은 3대 도구에 맞게 승화한다"**
> 1. `skill-creation-bible.md`를 v2.0.0으로 전면 승격하고, 근거 지도를 2026-09-01 최신 정본(`-260901_gpt-chatbot-section/docs`)으로 공식 연결합니다.
> 2. 챗봇의 8000-Frame-First를 에이전트의 **"500-Line Frame-First (Context Budget 사전배분 헌법)"**으로 승화하여 안전/권위 조항 전방 배치를 강제합니다.
> 3. KMGS 9대 게이트를 에이전트 환경에 맞춘 **"Agent KMGS 8대 사이징 게이트"**로 정립하고 `Module Budget Rationale` 작성을 의무화합니다.
> 4. `04_WORKFLOWS.md §5`의 미완성 과제(6대 변환 불변조항 준수 여부)를 공식 해소하고 검증 테스트케이스(`evals/`)를 신설합니다.
> 5. 3대 도구의 엄격한 파서 규격(`validate-skill-manifests.py`, YAML 문법, UTF-8 인코딩)을 100% 준수합니다.

---

## 2. 세부 변경 계획 (Proposed Changes)

### Component 1: 상위 헌법 및 정본 바이블 개정

#### [MODIFY] [skill-creation-bible.md](file:///d:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/skills/custom/mia/1_mia-skill-compiler/candidates/mia-skill-compiler/references/skill-creation-bible.md)
- **문서 메타데이터**: 버전 `2.0.0`, 최종 근거 검토일 `2026-09-11`, 상태 `STATIC_CANONICAL_CONSOLIDATED / RUNTIME_NOT_YET_EVALUATED`.
- **§3 21대 불변 상위원칙 고도화**:
  - 원칙 5 (`SKILL.md`는 얇은 코어여야 한다): **500-Line Frame-First 사전 배분 헌법** 명시.
  - 원칙 12~13: **Quality-First 신경회로 (QVRC 10단계 & ERR 7항목 & $Q^3$ 공식)** 탑재.
  - 원칙 22 (신설): **Standalone Visual Artifacts (HTML-First의 에이전트적 승화)** 원칙 추가.
- **§4 모듈 설계 헌법**:
  - **Agent KMGS 8대 사이징 게이트** (G1 Identity DNA ~ G8 Maintenance) 복원.
  - `Module Budget Rationale` 산정 근거 의무화.
- **§5 표준 회로**:
  - QCF 9단계 컴파일 공식 및 QVRC 상세 회로 삽입.
- **§10 근거 지도**:
  - 로컬 핵심 근거를 `-260901_gpt-chatbot-section/docs`의 11개 정본 문헌으로 공식 갱신.
  - `04_WORKFLOWS.md §5` 변환 헌법 6대 불변 조항 명시.

---

### Component 2: Compiler 지식 모듈 참조 파일 고도화

#### [MODIFY] [module-architecture.md](file:///d:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/skills/custom/mia/1_mia-skill-compiler/candidates/mia-skill-compiler/references/module-architecture.md)
- Agent KMGS 8대 게이트 세부 판정표 및 분리/병합 의사결정 알고리즘 추가.
- `Module Budget Rationale` 표준 템플릿 명세 추가.
- 논리 모듈 > 기능 모듈 절대 위계 조항 명시.

#### [MODIFY] [research-prd-contract.md](file:///d:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/skills/custom/mia/1_mia-skill-compiler/candidates/mia-skill-compiler/references/research-prd-contract.md)
- `User Intent Lock` 스키마(요청 이탈 방지 7대 실패 차단) 탑재.
- `ERR 7대 회귀 검사표` (Intent, Evidence, Hallucination, Constraint, Implementation, Density, User-Effort) 정식 삽입.
- $Q^3$ 품질 측정 공식 수식화.

#### [MODIFY] [fast-path-budget.md](file:///d:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/skills/custom/mia/1_mia-skill-compiler/candidates/mia-skill-compiler/references/fast-path-budget.md)
- 500-Line Frame-First 사전 배분 가이드라인(Identity, Safety, Workflow, Router, Reserve) 통합.
- 예산 중단 규칙과 최소 유효 검증 원칙 강화.

---

### Component 3: 검증 자산 및 평가 레코드 갱신

#### [NEW] [bible-validation-2026-09-11.json](file:///d:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/skills/custom/mia/1_mia-skill-compiler/evals/mia-skill-compiler/bible-validation-2026-09-11.json)
- 2026-09-11 기준 `-260901_gpt-chatbot-section/docs` 11대 문헌 전수 검증 결과 기록.
- 정적 무결성 통과, 04_WORKFLOWS §5 불변 6조 준수 검증 완료, 런타임 미실측 상태 정직성 유지.

#### [MODIFY] [cases.json](file:///d:/D_Workspace_NB/-agentic-ai-workspace/260718_agentic-ai-platform-optimization/skills/custom/mia/1_mia-skill-compiler/evals/mia-skill-compiler/cases.json)
- `04_WORKFLOWS.md §5.2`의 6대 불변 조항(Frame-First, 논리>기능 위계, Budget Rationale, QVRC/ERR, 최종보고 7항목, Permission Boundary) 준수 여부를 검증하는 테스트 케이스 6종 추가.

---

## 3. 검증 계획 (Verification Plan)

### 자동화 정적 검증
1. **MIA 스킬 매니페스트 검사**:
   ```powershell
   python skills/custom/mia/scripts/validate-skill-manifests.py
   ```
   통과 기준: 오류 0건, frontmatter/YAML 문법 완벽 통과.
2. **사전 승격 검사 (Preflight Promotion Check)**:
   ```powershell
   python skills/custom/mia/1_mia-skill-compiler/candidates/mia-skill-compiler/scripts/preflight_skill_promotion.py skills/custom/mia/1_mia-skill-compiler/candidates/mia-skill-compiler --allowed-target-root .agents/skills
   ```
3. **내부 링크 및 마크다운 무결성 검사**:
   모든 상대 경로 링크 및 파일 경로 유효성 확인.

### 수동 검증
- `git diff`를 통해 기존 코드 및 참조의 불필요한 삭제가 없는지, 정제된 논리 모듈이 단일 소유권을 만족하는지 전수 검토.
