# Windows Codex sandbox 복구 안내서

대상: Windows 11 Enterprise LTSC에서 Codex를 사용하는 사람
기록일: 2026-09-05
목적: “샌드박스가 작업을 계속 거부한다”는 문제를 이해하고 안전하게 확인하기

## 먼저 결론

복구를 적용했고, 일반 작업 파일은 샌드박스 안에서 만들고, 고치고, 읽고, 지우는 데
성공했다. Windows 11 Enterprise LTSC 자체가 문제의 원인이라는 증거는 없다.

문제는 Codex가 작업할 수 있는 임시 장소 목록에 `C:\tmp`를 넣을 때, Windows 권한표
(ACL)를 준비하다가 거부될 수 있었던 점이다. 책상 서랍 하나의 자물쇠가 걸려서 작업대
전체를 못 쓰던 상황과 비슷하다. `C:\tmp`만 작업 대상에서 뺐고, 실제 작업대인
워크스페이스는 그대로 사용할 수 있게 했다.

## 무엇을 바꿨나

사용자 Codex 설정 파일 `C:\Users\Kimyoongyeom\.codex\config.toml`에 아래 두 줄을
추가했다.

```toml
[sandbox_workspace_write]
exclude_slash_tmp = true
```

뜻: Codex가 workspace-write sandbox를 준비할 때 `C:\tmp`는 건드리지 않는다.
네트워크 권한, 사용자 `%TEMP%`, 추가 작업 폴더, Git 보호 규칙은 바꾸지 않았다.

## 지금 정상이라고 판단한 이유

다음 네 가지를 모두 확인했다.

| 확인한 것 | 결과 | 쉬운 뜻 |
| --- | --- | --- |
| 설정값 존재 | 통과 | 다음 sandbox 실행에도 `C:\tmp`를 제외한다. |
| 실제 sandbox 파일 작업 | 통과 | 고유 검사 파일을 만들고, 쓰고, 읽고, 삭제했다. |
| 검사 파일 잔여 | 0개 | 시험 파일이 작업 폴더에 남지 않았다. |
| 최신 setup 기록 | `errors=[]` | sandbox 준비 과정에서 권한 오류가 보이지 않았다. |

추가로 진단 회귀 테스트 8개와 저장소 전체 검사 `npm run check`도 통과했다.

## 정상 사용 중 자주 헷갈리는 점

`.git`, `.agents`, `.codex` 안쪽 파일은 workspace-write에서도 일부러 읽기 전용이다.
이것은 Codex가 프로젝트의 기록, 설정, 자동화 규칙을 실수로 바꾸지 않게 하는 잠금장치다.

그래서 `.git/index.lock` 접근 거부는 “일반 파일 sandbox가 또 고장 났다”는 뜻이 아니다.
Git 커밋·push처럼 Git 내부 파일을 바꾸는 작업은 Codex의 정식 승인 경로를 사용한다.
잠금장치를 제거하거나 모든 폴더의 권한을 넓히는 방식으로 해결하지 않는다.

## 다음에 이상해 보일 때 할 일

1. 워크스페이스에서 아래 검사를 실행한다.

   ```powershell
   pwsh -NoProfile -File codex/app-diagnostics/codex-sandbox-check.ps1 -ProbeWorkspaceWrite
   ```

2. 종료 코드가 `0`이면, 이 검사 범위의 setup과 파일 쓰기는 정상이다.
3. 종료 코드가 `1`이면, 출력에 나온 정확한 경로와 시각을 기록한다. `C:\tmp` 또는
   `write ACE failed`가 보이면 sandbox 준비 권한 문제로 분류한다.
4. 종료 코드가 `2`이면, 로그가 오래됐거나 판독할 수 없다는 뜻이다. 새 작업에서 다시
   실행해 최신 증거를 만든다.
5. `.git` 접근 거부만 보이면 Git 승인 경로를 사용한다. ACL 삭제나 sandbox 해제는 하지 않는다.

## 되돌리는 방법

이 설정이 다른 문제의 원인으로 확인될 때만 `config.toml`에서 아래 두 줄을 삭제한다.

```toml
[sandbox_workspace_write]
exclude_slash_tmp = true
```

삭제 뒤에는 위의 파일 쓰기 검사를 다시 실행해야 한다. 확인 없이 되돌리거나 전역 권한을
바꾸지 않는다.

## 확인하지 않은 것

이 복구는 모든 명령, 모든 네트워크 요청, 모든 외부 프로그램이 항상 성공한다는 보증은
아니다. 특히 조직 정책, WMI, 네트워크, Git 보호 경계는 각각 다른 규칙을 따른다.
이 문서의 통과 범위는 일반 워크스페이스 파일 작업과 sandbox 준비다.

## 근거와 상세 기록

- [기술 진단과 실제 검증 기록](WINDOWS_LTSC_CODEX_SANDBOX_DIAGNOSIS_2026-09-05.md)
- [OpenAI Windows sandbox 문서](https://learn.chatgpt.com/docs/windows/windows-sandbox)
- [OpenAI 승인 및 보안 문서](https://learn.chatgpt.com/docs/agent-approvals-security)
- [Windows 보호 경계 구현 PR](https://github.com/openai/codex/pull/17365)
- [`C:\tmp` ACL 실패 유사 사례](https://github.com/openai/codex/issues/33806)
