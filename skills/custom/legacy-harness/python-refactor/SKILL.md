---
name: python-refactor
description: Use this skill when improving Python code quality, refactoring functions, adding type hints, adding docstrings, reducing duplication, or preparing tests and lint checks.
---

# Python Refactor Skill

## Goal
Python 코드를 더 읽기 쉽고, 유지보수 가능하며, 검증 가능한 구조로 개선한다.

## When to Use
- Python 함수나 클래스 리팩토링이 필요할 때
- Type Hint, Docstring, 테스트, lint 기준을 보강할 때
- 중복 코드, 긴 함수, 복잡한 조건문을 정리할 때
- 성능 병목이나 불필요한 반복을 줄여야 할 때

## Steps
1. 수정 대상 파일과 관련 테스트를 먼저 확인한다.
2. 현재 함수의 입력, 출력, 부작용을 파악한다.
3. 큰 변경을 작은 단위로 나눈다.
4. 가능한 경우 테스트를 먼저 작성하거나 기존 테스트를 확인한다.
5. 함수와 메서드에 Type Hint를 추가한다.
6. 공개 함수와 클래스에는 Google Style Docstring을 추가한다.
7. 중복 코드는 함수나 모듈로 분리하되 과도한 추상화는 피한다.
8. 수정 후 `ruff check .`와 `pytest` 실행을 우선한다.
9. 실행하지 못한 검증은 이유와 수동 확인 방법을 보고한다.

## Constraints
- `.env`, token, credential 파일을 읽거나 수정하지 않는다.
- 기존 공개 API는 사용자 요청 없이 바꾸지 않는다.
- 기존 주석과 문서를 임의로 삭제하지 않는다.
- 새 패키지 설치가 필요하면 사용자 승인을 요청한다.

## Output
- 변경 요약
- 수정한 파일
- 테스트/검증 결과
- 남은 위험 또는 후속 작업
