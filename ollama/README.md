# Ollama 로컬 추론 워크스페이스

Ollama 설치·모델 저장소·실행 설정·초보자 사용법을 재현 가능하게 관리하는 섹션입니다.
모델 본체와 캐시는 크기가 크고 PC마다 다르므로 Git에 넣지 않습니다.

## 현재 노트북 기준 상태

2026-08-24에 다음 구성을 실제 실행으로 확인했습니다.

| 항목 | 값 |
|---|---|
| Ollama | `0.32.15` |
| 기본 모델 | `qwen3.5:4b` (약 3.4GB) |
| 모델 저장소 | `D:\AI-Models\Ollama` |
| GPU | NVIDIA GTX 1660 Ti 6GB, 모델 `100% GPU` 적재 확인 |
| 메모리 | 약 32GB |
| 컨텍스트 | 8192 토큰 |
| 병렬 요청 | 1 |
| 동시 적재 모델 | 1 |

상세 실측 근거는 [노트북 기준선](docs/notebook-baseline-2026-08-24.md)에 있습니다.

## 폴더 지도

| 경로 | 역할 |
|---|---|
| `scripts/Configure-OllamaWindows.ps1` | 모델 경로와 자원 제한을 사용자 환경변수에 저장하고 서버를 재시작 |
| `scripts/Start-OllamaChat.ps1` | 초보자용 대화 실행기 |
| `docs/` | PC별 실측·검증 기록 |
| `.gitignore` | 모델·캐시·로그·대용량 가중치의 커밋 방지 |

## 처음 한 번만 실행

저장소 루트에서 PowerShell을 열고 다음 명령을 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\ollama\scripts\Configure-OllamaWindows.ps1 -ModelsPath 'D:\AI-Models\Ollama'
```

이 스크립트는 다음 사용자 환경변수를 저장합니다.

- `OLLAMA_MODELS=D:\AI-Models\Ollama`
- `OLLAMA_CONTEXT_LENGTH=8192`
- `OLLAMA_NUM_PARALLEL=1`
- `OLLAMA_MAX_LOADED_MODELS=1`

기존 모델 파일을 삭제하거나 다시 다운로드하지 않습니다. 실행 중인 Ollama 프로세스만 종료한
뒤 같은 설치본으로 서버를 다시 시작합니다.

## 가장 쉬운 사용법

```powershell
powershell -ExecutionPolicy Bypass -File .\ollama\scripts\Start-OllamaChat.ps1
```

검은 창에 질문을 입력하고 `Enter`를 누릅니다. 종료는 `/bye`입니다. 첫 실행은 GPU에 모델을
올리느라 약 1분이 걸릴 수 있습니다.

다른 모델이나 추론 강도를 지정할 수도 있습니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\ollama\scripts\Start-OllamaChat.ps1 -Model 'qwen3.5:4b' -Think low
```

일반 대화는 기본값인 `-Think false`가 더 빠릅니다.

## 자주 쓰는 명령

```powershell
ollama list
ollama ps
ollama stop qwen3.5:4b
ollama run qwen3.5:4b --think=false
```

- `ollama list`: 설치된 모델 확인
- `ollama ps`: 실행 중인 모델과 GPU 적재 상태 확인
- `ollama stop`: 모델을 GPU·메모리에서 내림
- `ollama run`: 터미널 대화 시작

## 이 PC의 운영 기준

- 4B급 모델을 기본으로 사용합니다.
- GTX 1660 Ti의 VRAM이 6GB이므로 9B 이상 모델의 상시 사용은 권장하지 않습니다.
- 여러 모델이나 여러 요청을 동시에 실행하지 않습니다.
- 모델은 D:에 두고 C:에는 Ollama 프로그램만 둡니다.
- 의료·법률·금융 결론은 로컬 모델 답변만으로 결정하지 않습니다.

## 설정 되돌리기

PowerShell에서 아래 명령을 실행하면 이 섹션이 추가한 사용자 환경변수를 제거할 수 있습니다.
모델 파일은 삭제되지 않습니다.

```powershell
[Environment]::SetEnvironmentVariable('OLLAMA_MODELS', $null, 'User')
[Environment]::SetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH', $null, 'User')
[Environment]::SetEnvironmentVariable('OLLAMA_NUM_PARALLEL', $null, 'User')
[Environment]::SetEnvironmentVariable('OLLAMA_MAX_LOADED_MODELS', $null, 'User')
```

환경변수 제거 후 Ollama를 다시 시작해야 반영됩니다.
