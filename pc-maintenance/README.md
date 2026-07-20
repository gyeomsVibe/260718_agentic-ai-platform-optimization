# 💻 노트북 PC 유지 및 관리 (pc-maintenance)

이 섹션은 윤겸스 노트북 PC의 하드웨어/OS 설정 및 시스템 유지보수와 관련된 스크립트, 진단 도구, 조치 히스토리를 관리하는 곳입니다.

## 🗂 구성 요소

- `scripts/`: 자동화 및 시스템 복구를 위한 PowerShell 스크립트 모음
- `README.md`: 유지보수 내역 및 수동 조치 절차 가이드

---

## 🛠 조치 및 유지보수 이력

### 1. 윈도우 시작 시 알림(Toast) 자동 꺼짐 현상 해결
* **해결 일자**: 2026-07-21
* **관찰 현상**: 노트북 부팅 혹은 사용자 로그인 시 시스템 알림(Toast Notifications) 허용 설정이 꺼져(비활성화) 알림이 수신되지 않는 현상.
* **원인 추정**: 
  - WPN(Windows Push Notification) 데이터베이스(`wpndatabase.db`) 손상으로 인한 설정 저장 실패.
  - 로그인 세션 시 전역 알림 레지스트리(`NOC_GLOBAL_SETTING_TOASTS_ENABLED`) 초기화.
* **해결 조치**:
  1. **알림 DB 재빌드**: WPN 관련 서비스 중단 후 손상 의심 데이터베이스(`wpndatabase.db`)를 리셋.
  2. **시작 시 강제 보정**: 사용자 로그인 시 `NOC_GLOBAL_SETTING_TOASTS_ENABLED = 1`을 강제 주입하는 PowerShell 스크립트를 작성하여 윈도우 작업 스케줄러(`AutoEnableNotifications`)에 관리자 권한으로 등록.
* **관련 스크립트**:
  - `scripts/Fix-WindowsNotifications.ps1`: 알림 DB 초기화 및 알림 강제 활성화 레지스트리 적용.
  - `scripts/Register-NotificationStartupTask.ps1`: 위의 조치 스크립트를 윈도우 작업 스케줄러에 등록.
