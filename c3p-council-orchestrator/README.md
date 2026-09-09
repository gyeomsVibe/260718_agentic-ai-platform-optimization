# 🧬 C3P 협의체 (C3P Council) 3도구 오케스트레이터 및 예산절약·사용자부재 모드

> **C3P 협의체(C3P Council)**는 **Codex(사령관) · Claude Code(면역계/로직) · Antigravity(감각기/실측)** 3대 인공지능 도구가 역할을 분담하여 단일 지능 유기체처럼 협력하는 3중 병렬 오케스트레이션 시스템입니다.

---

## 📌 핵심 기능 안내 (Key Features)

### 1. 🛡️ C3P 예산절약 모드 (Budget-Saving Mode)
- **외부 토큰 비용 0원 (Zero-Token Passive Standby)**: 유휴 대기 시 외부 클라우드 인공지능을 반복 호출하지 않고, 로컬 파이썬 소켓 브로커가 0원으로 대기합니다.
- **사령관 보호 (Commander Shield)**: 단순 하트비트와 잡담은 로컬에서 걸러내고, 사령관 Codex에는 3줄 요약 핵심 작업 카드만 전달하여 쿼터 소모를 85% 이상 절감합니다.

### 2. 🤖 C3P 사용자부재 모드 (User-Absence Mode)
- **변화 기반 유한 토론회 (Bounded Deliberation)**: 사용자가 외출하거나 자리를 비웠을 때, AI끼리 끝없는 대화로 토큰을 탕진하지 않도록 **최대 5턴·15분 이내**로 제한된 토론회만 개최합니다.
- **P2 절대 경계 자동 동결 (P2 Freeze)**: 토론 도중 소스코드 삭제, 패키지 설치, 깃 커밋·푸시 등 파괴적 행동이 언급되면 즉시 `PAUSED`(일시정지) 상태로 전환하여 사용자의 승인을 대기합니다.

---

## 🚀 1초 빠른 시작 (Quick Start)

### 1) 모드 켜기 (발동)
```bash
# 사용자 부재 시 안전 준비 모드 발동
python csc.py trigger "C3P 사용자부재 모드"

# 또는 예산절약 모드 발동
python csc.py trigger "C3P 예산절약 모드"
```

### 2) 시스템 상태 확인
```bash
python csc.py status
```
- 브로커 및 워커의 실제 생존 여부(`LIVE` / `DEAD`)를 기계적으로 실측하여 초록불(`READY`, 종료 코드 0)을 반환합니다.

---

## 📚 직관적인 문서 목차 (Documentation)

- [`docs/01_사용자안내_C3P_예산절약_및_사용자부재_모드_운용_종합가이드(c3p_budget_and_absence_mode_guide).md`](docs/01_사용자안내_C3P_예산절약_및_사용자부재_모드_운용_종합가이드(c3p_budget_and_absence_mode_guide).md): 초보자도 쉽게 따라 할 수 있는 3단 병기 종합 운용 가이드
- [`docs/02_C3P_사용자부재_모드_상태머신_및_유한토론회_설계계획서(c3p_user_absence_mode_plan).md`](docs/02_C3P_사용자부재_모드_상태머신_및_유한토론회_설계계획서(c3p_user_absence_mode_plan).md): 6대 방어선과 상태 전이 규칙 설계서
- [`docs/03_C3P_예산절약_모드_사용자부재_중_협의_결과보고서(c3p_absence_collaboration_report).md`](docs/03_C3P_예산절약_모드_사용자부재_중_협의_결과보고서(c3p_absence_collaboration_report).md): 사령관 Codex와의 실시간 협의 결과 보고서
- [`docs/06_C3P_실시간_메시지_감시_자동화_및_예산절약_정본_규격서(c3p_zero_token_auto_watch_spec).md`](docs/06_C3P_실시간_메시지_감시_자동화_및_예산절약_정본_규격서(c3p_zero_token_auto_watch_spec).md): 0원 감시 규약 아키텍처 정본
- [`docs/07_C3P_협의체_공식명칭_및_사용안내(c3p_council_official_name_and_guide).md`](docs/07_C3P_협의체_공식명칭_및_사용안내(c3p_council_official_name_and_guide).md): C3P 협의체의 공식 정의 및 속칭 사용법
- [`docs/00_C3P_전체_문서_목록(00_PROJECT_INDEX).md`](docs/00_C3P_전체_문서_목록(00_PROJECT_INDEX).md): 62개 전체 개발 문서 인덱스
