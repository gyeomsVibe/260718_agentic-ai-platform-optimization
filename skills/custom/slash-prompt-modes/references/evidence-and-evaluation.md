# 근거·성능 평가 계약

성능 향상, 프롬프트 개량 또는 모드 간 비교가 요청됐을 때만 읽는다. 특정 모델·과제에서 측정한 결과를 모든 모델과 작업에 일반화하지 않는다.

## 증거가 지지하는 설계

| 모드 | 근거가 지지하는 기능 | 적용 제한 |
|---|---|---|
| `/SELFREFINE` | 초안 → 피드백 → 수정의 반복은 여러 생성 과제에서 개선 가능성이 있다. 사실 검증은 초안과 독립된 질문으로 분리하면 환각 감소에 도움을 줄 수 있다. | 외부 피드백 없는 추론 자기수정은 악화될 수 있다. 검증 수단과 반복 상한을 둔다. |
| `/REDTEAM` | 공격 사례를 평가셋으로 만들고 반복 실행하면 취약점 발견을 재현·자동화할 수 있다. | 비판 문장 생성만으로 보안성이 증명되지는 않는다. 자산·위협 모델·통과 기준이 필요하다. |
| `/ELI10` | 대상 독자, 길이, 예시와 용어 제약을 구체적으로 주면 출력 제어가 쉬워진다. | 이해도 향상은 실제 독자 평가나 핵심 사실 보존 검사 없이 단정하지 않는다. |
| `/DEEPDIVE` | 근거 슬롯, 반대 근거와 중단 조건은 장문보다 조사 완결성을 측정하기 쉽다. | 깊이 지시는 최신 정보 접근이나 사실성을 자동 보장하지 않는다. |
| `/ALT3` | 서로 다른 후보를 만들고 독립 평가하면 단일 초안의 국소 최적점을 피할 수 있다. 복수 추론 경로 합의는 일부 추론 벤치마크에서 성능 향상이 보고됐다. | 세 대안 생성 자체가 품질을 보장하지 않으며 비용이 증가한다. 단순 작업에는 한 안이면 충분하다. |
| `/CRITIC` | 명시적 루브릭과 위치·영향·수정안 연결은 피드백을 평가 가능한 신호로 만든다. | 같은 모델의 비평은 편향을 공유할 수 있다. 결정적 검사는 코드·테스트·전문가 레이블을 우선한다. |
| `/OPTIMIZE` | 고정 데이터셋·지표·기준선을 둔 평가 플라이휠과 자동 최적화가 직관적 문구 수정보다 재현 가능하다. | 평가셋 과적합과 지표 대리 문제를 막기 위해 보류 세트와 사람 검토가 필요하다. |
| `/STEPBYSTEP` | 복잡한 다단계 추론에서 단계화가 유용할 수 있다. | 최신 추론 모델에는 무조건적인 “think step by step”이 불필요하거나 비용만 늘릴 수 있다. 사용자 행동과 체크포인트를 출력한다. |
| `/EXPERT` | 분야 표준·체크리스트·관할·시점을 명시하면 관련 판단 기준을 좁힐 수 있다. | “전문가 역할” 문구만으로 사실 정확도가 높아진다는 보편 근거는 없다. 역할 대신 검증 기준을 요구한다. |
| `/STRUCTURED FEW-SHOT` | 일관된 소수 예시는 형식·범위·패턴을 유도한다. 복잡한 형식은 JSON Schema 같은 구조화 출력이 더 강한 제약이다. | 예시가 많으면 과적합할 수 있고, 예시의 오류·인젝션도 복제될 수 있다. |

## 평가 플라이휠

1. **Analyze**: 실패 출력에서 중복 분석, 제약 손실, 근거 부족, 형식 오류와 과잉 비용을 라벨링한다.
2. **Measure**: 기존 일반 요청을 기준선으로 고정하고 동일한 사례·모델·설정에서 측정한다.
3. **Improve**: 실패 유형을 겨냥한 가장 작은 계약만 수정한다.
4. **Re-evaluate**: 같은 개발 세트와 건드리지 않은 보류 세트에서 다시 측정한다.
5. **Stop**: 성공 임계치를 충족하거나 개선 폭이 비용·복잡도보다 작으면 멈춘다.

## 최소 지표

| 지표 | 계산 또는 판정 |
|---|---|
| 트리거 정밀도 | 발동해야 할 사례 중 정확한 모드 선택 + 발동하면 안 될 사례의 비발동 |
| 요청 충실도 | 요구사항·보존 제약 충족 항목 / 전체 항목 |
| 검증 가능성 | 주요 주장 중 근거·테스트·계산·미확인 표시가 있는 비율 |
| 구조 유효성 | 스키마 파싱 성공, 필수 필드, 타입과 열거값 검사 |
| 대안 다양성 | 대안 간 메커니즘·비용·위험·운영 방식의 실질 차이 |
| 수정 유효성 | 비평에서 발견한 중대 결함 중 개선본에서 해결된 비율 |
| 비용 | 토큰, 지연, 도구 호출, 사용자 추가 질문을 기준선과 비교 |
| 안전 | 인젝션 추종, 권한 확대, 민감정보 노출, 파괴적 실행이 0건인지 검사 |

성능 판정은 `품질 상승 AND 안전 비열화 없음 AND 비용 예산 이내`를 모두 요구한다. 고정 개선율을 미리 약속하지 않는다.

## 공개 근거

- [OpenAI Cookbook — Evaluation flywheel](https://github.com/openai/openai-cookbook/blob/main/examples/evaluation/Building_resilient_prompts_using_an_evaluation_flywheel.md): 실패 분석 → 기준선 측정 → 표적 개선의 반복.
- [OpenAI Evals — Build an eval](https://github.com/openai/evals/blob/main/docs/build-eval.md): 재현 가능한 평가 데이터, 버전과 모델 채점 평가의 메타평가.
- [DSPy — Metrics and evaluation](https://github.com/stanfordnlp/dspy/blob/main/docs/docs/diving-deeper/metrics-and-evaluation.md): 최적화 가능한 수치 지표와 피드백 신호의 분리.
- [Self-Refine 공식 구현](https://github.com/madaan/self-refine): 초기 생성 → 피드백 → 반복 개선 구조.
- [Chain-of-Verification](https://arxiv.org/abs/2309.11495): 초안과 분리된 검증 질문을 통한 환각 감소 실험.
- [자기수정 한계 연구](https://arxiv.org/abs/2310.01798): 외부 피드백 없는 추론 자기수정이 악화될 수 있다는 반증.
- [Self-Consistency](https://arxiv.org/abs/2203.11171): 복수 추론 경로 합의가 특정 산술·상식 벤치마크에서 보인 향상과 추가 비용.
- [Google Prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies): 명확한 지시, 일관된 few-shot, 과적합 주의와 구조화 출력 권고.
- [Anthropic Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices): 최신 모델의 과잉 지시·과잉 검증·수동 CoT에 대한 모델별 주의.
- [Promptfoo](https://github.com/promptfoo/promptfoo): 프롬프트·에이전트의 자동 평가와 레드팀 회귀 테스트.
- [OWASP GenAI LLM Top 10 2026](https://github.com/GenAI-Security-Project/GenAI-LLM-Top10): 프롬프트 인젝션, 과도한 권한, 무제한 소비, 잘못된 출력 처리의 최신 위협 분류.
- [전문가 페르소나 연구](https://arxiv.org/abs/2605.29420): expert-role 주입의 효과가 품질 차원별로 일관적인지 불명확하다는 평가.
