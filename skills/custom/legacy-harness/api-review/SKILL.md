---
name: api-review
description: Use this skill when designing, modifying, or reviewing API endpoints, request and response schemas, authentication, authorization, validation, error handling, or API tests.
---

# API Review Skill

## Goal
API 변경 작업에서 보안, 입력 검증, 권한, 에러 응답, 테스트 누락을 점검한다.

## When to Use
- 새 API 엔드포인트를 만들 때
- 기존 API 응답 구조를 바꿀 때
- 인증(Authentication)이나 권한(Authorization)이 관련될 때
- 외부 API 연동, Webhook, 결제, 메일 발송, DB 쓰기가 포함될 때
- API 테스트나 문서화를 보강할 때

## Steps
1. HTTP method, path, request schema, response schema를 확인한다.
2. 인증(Authentication)이 필요한지 확인한다.
3. 권한(Authorization) 검사가 필요한지 확인한다.
4. 입력값 검증(Validation)이 충분한지 확인한다.
5. 에러 응답 형식이 일관적인지 확인한다.
6. 민감정보가 로그나 응답에 노출되지 않는지 확인한다.
7. 외부 API 호출은 mock, dry-run, sandbox를 먼저 사용한다.
8. 성공/실패/권한 없음/잘못된 입력 테스트가 있는지 확인한다.
9. 위험 항목과 수정 제안을 요약한다.

## Constraints
- 실제 외부 API 호출은 사용자 승인 없이 실행하지 않는다.
- 운영 DB 쓰기, 결제, 메일 발송은 사용자 승인 없이 실행하지 않는다.
- 비밀키, 토큰, 개인정보를 출력하지 않는다.
- 보안상 불확실한 부분은 안전한 기본값을 제안한다.

## Output
- API 변경 요약
- 발견된 위험
- 수정 제안
- 필요한 테스트
- 검증 방법
