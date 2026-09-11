# Ollama 노트북 기준선 — 2026-08-24

## 목적

현재 노트북에서 Ollama의 적합성과 D: 모델 저장 구성을 재현하기 위한 실측 기록입니다.
이 문서는 모델 파일이나 Windows 사용자 설정 자체가 아니라 검증 결과만 보존합니다.

## 하드웨어

| 항목 | 실측 |
|---|---|
| CPU | Intel Core i7-9750H, 6코어 12스레드 |
| RAM | 약 31.8GB |
| GPU | NVIDIA GTX 1660 Ti, VRAM 6GB, CUDA Compute Capability 7.5 |
| C: | 총 317.2GB, 여유 109.9GB (34.6%) |
| D: | 총 635.9GB, 여유 584.1GB (91.9%) |

## 설치 및 실행 검증

| 항목 | 결과 |
|---|---|
| Ollama 실행 파일 | `%LOCALAPPDATA%\Programs\Ollama\ollama.exe` |
| 버전 | `0.32.15` |
| 모델 | `qwen3.5:4b`, 약 3.4GB |
| 모델 저장소 | `D:\AI-Models\Ollama`, 실제 사용량 약 3.16GB |
| API | `127.0.0.1:11434` LISTENING 확인 |
| 실제 생성 | 한국어 응답 성공, 종료 코드 0 |
| GPU 적재 | `ollama ps`에서 `100% GPU`, 컨텍스트 8192 확인 |
| 생성 중 GPU | 약 4,943MiB 사용, 71°C, 사용률 82%, 약 81W 관측 |

첫 모델 로딩과 최초 프롬프트 처리는 약 1분이 걸렸고, 생성 단계는 약 56 tokens/s가
관측됐습니다. 이 수치는 드라이버·온도·프롬프트·백그라운드 부하에 따라 달라질 수 있습니다.

## 판정

- 이 PC에는 4B급 양자화 모델이 가장 안정적인 기본값입니다.
- 6GB VRAM에서 9B 이상 모델은 CPU 오프로딩과 체감 지연 가능성이 커 상시 기본값으로 부적합합니다.
- 모델을 D:에 두면 C:의 추가 점유를 약 3.4GB 줄일 수 있습니다.
- C: 40% 여유 목표는 Ollama 설치와 별개이며, 검증되지 않은 시스템 파일 삭제로 해결하지 않습니다.

## 남은 사용자 작업

Codex 샌드박스에서는 Windows 사용자 환경변수의 영구 저장이 차단됐습니다. 저장소 루트에서
다음 명령을 한 번 실행하면 재부팅 이후에도 D: 모델 저장소 설정이 유지됩니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\ollama\scripts\Configure-OllamaWindows.ps1 -ModelsPath 'D:\AI-Models\Ollama'
```
