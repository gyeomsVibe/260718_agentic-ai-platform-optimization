# 🤖 Claude Code 에이전트 환경설정 기록 (데스크톱)

> 이관: `260713_pc-optimization` 워크스페이스에서 완전 이동 (2026-07-19). 문서 내 일부 상대 링크(optimization_result.md, scratch/ 등)는 구 워크스페이스 기준이라 연결되지 않을 수 있다.

> 대상 환경: **데스크톱** (Intel i7-6700K / Windows 10 Pro 64-bit)
> 기록일: 2026-07-13 · 최종 정리 기준
> 이 문서는 본 데스크톱 환경의 Claude Code(에이전트 CLI) 환경설정을 재현·복구·정리하기 위해 남기는 기록입니다.

---

## 1. 개념 및 구성 층위

Claude Code는 터미널 기반의 초강력 자율 코딩 에이전트입니다. 확장 층위는 크게 **세 가지**로 나뉘며, 각 층위에 따른 리소스(토큰 및 프로세스) 점유 상태를 최적화하여 사용합니다.

| 층위 | 무엇인가 | 데스크톱 환경 구성 상태 | 리소스 영향 |
|---|---|---|---|
| **① 로컬 플러그인** | 마켓플레이스에서 설치한 기능/스킬 묶음 | 불필요한 데모/타 용도 3개 제거 완료 | 프롬프트 토큰 절감 |
| **② 로컬 MCP 서버** | 로컬 설정에 연동된 외부 도구 서버 | 현재 로컬 구성 비어 있음 | 프로세스 점유 최소화 |
| **③ 계정 커넥터 번들** | claude.ai 클라우드 계정에 바인딩된 서비스 | Notion(연결됨), Canva(인증 만료 상태 확인) | 초기 딜레이에 영향 |

---

## 2. 로컬 플러그인 최적화 내역 (① 층위)

에이전트 작동 시 불필요하게 프롬프트 컨텍스트(Context Space)를 점유하던 **3개의 플러그인을 제거**하여 기동 속도와 토큰 효율을 보완했습니다.

### 1) 제거 완료된 플러그인 (3개)
- `example-skills@anthropic-agent-skills` (샘플 예제 코드로, 실무 코딩에 불필요)
- `plugin-dev@claude-plugins-official` (플러그인 자체 제작을 위한 개발자 툴로, 일반 코딩에 무의미)
- `frontend-design@claude-plugins-official` (파이썬/최적화 중심인 본 데스크톱 개발 환경에서 무관한 프론트엔드 분석 도구)

### 2) 유지된 필수 활성 플러그인
- `claude-api@anthropic-agent-skills` (Claude API 활용 보조)
- `code-review@claude-plugins-official` (코드 보안/구조 심층 분석 및 `/code-review` 명령어 제공)
- `commit-commands@claude-plugins-official` (git 자동 커밋 및 푸시 유틸리티)
- `document-skills@anthropic-agent-skills` (docx, pdf, pptx, xlsx 문서 생성 지원)
- `feature-dev@claude-plugins-official` (자율 기능 개발 도구)
- `pr-review-toolkit@claude-plugins-official` (PR 코드 심사 자동화)
- `security-guidance@claude-plugins-official` (안전한 코딩 가이드 준수)

---

## 3. 계정 커넥터 번들 분석 (③ 층위)

- **`claude.ai Notion`**: `✓ Connected` (노션 연동이 정상 유지되어 연계 분석 가능)
- **`claude.ai Canva`**: `! Needs authentication` (인증 만료 상태)
  - 이 서비스는 로컬이 아닌 `claude.ai` 계정 레벨에서 주입된 클라우드 MCP 설정입니다.
  - 에이전트 구동 시 미세한 연동 체크 딜레이를 방지하기 위해, 추후 사용하지 않을 시 [claude.ai/settings](https://claude.ai/settings) 웹페이지에서 연결 해제를 진행하시는 것을 추천합니다.

---

## 4. 로컬 환경 권한 설정 (`.claude/settings.local.json`)

로컬 디렉토리 내 에이전트의 Bash 및 네트워크 실행 도구 권한을 묻지 않고 신속하게 실행하도록 허용하는 보안 설정이 다음과 같이 공유 추적됩니다.

```json
{
  "permissions": {
    "allow": [
      "Bash(gh repo *)",
      "Bash(curl -s \"https://api.github.com/repos/gyeomsVibe/260713_pc-optimization/git/trees/main?recursive=1\")",
      "Bash(curl -s \"https://api.github.com/repos/gyeomsVibe/260713_pc-optimization\")",
      "Bash(curl -s \"https://api.github.com/users/gyeomsVibe/repos?per_page=100\")",
      "Bash(gh api *)",
      "WebFetch(domain:github.com)",
      "Bash(curl -s -o /dev/null -w \"%{http_code}\\\\n\" https://api.github.com/repos/gyeomsVibe/260713_pc-optimization)",
      "Bash(git --version)",
      "Bash(gh --version)"
    ]
  }
}
```
> 이 권한 리스트 파일은 머신 고유의 비밀키를 포함하지 않으므로, `.gitignore` 예외 규칙을 거쳐 git에 추적 등록되어 팀원 간 안전하게 공유됩니다.
