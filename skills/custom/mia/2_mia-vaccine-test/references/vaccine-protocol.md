# 💉 MIA Vaccine Test Protocol & Reference

## 변이 주입 (Mutation Testing) 원칙
1. **Target Identification**: 검증하고자 하는 핵심 방어 로직(예: 금지어 패턴, 토큰 검출기, 타입 체크) 선택.
2. **Mutation Injection**: 해당 로직을 일시적으로 빈 값/True로 리턴하도록 수정.
3. **Antibody Kill Test**: 테스트 실행 후 FAIL(KILLED) 메시지 확인.
4. **Restoration**: 코드 즉시 원복 후 `npm run check` 100% PASS 확인.

## 무오류 실측 5대 조항 준수
- 물리적 워크스페이스 실측
- 컬럼/상호 연관성 검증
- 시각적 캡처 실측
- 명령 실패 무조건 명시
- 푸시 후 원격 정합성 검증
