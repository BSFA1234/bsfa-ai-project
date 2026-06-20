# BSFA TIA Portal × Claude 프로젝트

## 회사 / 프로젝트 개요
- 회사: **부산자동화시스템 (BSFA)** — 산업 자동화 시스템 회사
- 주력 도구: **Siemens TIA Portal** (PLC 프로그래밍)
- 이 프로젝트의 목적: Claude(Claude Code)를 도입하여 PLC 프로그래밍 및 회사 업무 효율화. 다양한 테스트와 확장을 진행하는 실험/검증 공간.

## 세션 시작 시
- **[context.md](context.md)의 "진행 로그" 섹션을 먼저 확인**하고, 마지막 중단 지점부터 이어서 진행한다.

## 작업 규칙
- 사용자와의 대화는 **한국어**로 진행한다.
- 사용자는 AI/웹은 알지만 **PLC·TIA Portal은 비전문가**이며, 목표는 **개념 마스터가 아니라 BSFA 업무 효율화**다. 아래 **학습·설명 방식을 항상 적용**한다:
  - **한 번에 하나씩, 천천히.** 긴 설명 벽돌 금지. 각 단계 후 이해를 확인하고, 막힌 부분만 콕 집어 다시 설명한다.
  - **전문용어 최소화** — 나오면 쉬운 비유로 한 줄 풀이 (예: FB=함수/컴포넌트, 태그=변수 이름표).
  - **가능하면 실제 화면·실물을 캡처해 보여주며** 설명한다 ("보면서 따라가기").
  - **"사용자가 알아야 할 것"과 "Claude가 처리할 것"을 분리**한다. 깊은 PLC 이론(주소·XML·SCL 문법 등)은 Claude가 맡고, 사용자는 방향 지시·결과 승인에 필요한 만큼만.
  - 사용자가 헷갈려하면 **즉시 속도를 늦추고** 더 쉽게 다시 설명한다.
- 회사·업무 컨텍스트는 [context.md](context.md)에 누적 기록한다. 새 논의에서 중요한 맥락이 나오면 context.md를 갱신할 것.
- 참고자료(워크숍 요약, 외부 문서 등)는 `docs/references/`에 보관한다.
- TIA Portal 프로젝트 파일을 수정하는 작업은 반드시 **드라이런(변경 내용 사전 확인) 후 적용**한다.

## 주요 문서
- [context.md](context.md) — 회사/업무 상세 컨텍스트 (살아있는 문서)
- [docs/references/tia-portal-claude-code-workshop.md](docs/references/tia-portal-claude-code-workshop.md) — TIA Portal + Claude Code 연동 워크숍 요약 (ControlByte)
