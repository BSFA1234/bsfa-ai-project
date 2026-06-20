# BSFA TIA Portal × Claude 프로젝트

## 회사 / 프로젝트 개요
- 회사: **부산자동화시스템 (BSFA)** — 산업 자동화 시스템 회사
- 주력 도구: **Siemens TIA Portal** (PLC 프로그래밍)
- 이 프로젝트의 목적: Claude(Claude Code)를 도입하여 PLC 프로그래밍 및 회사 업무 효율화. 다양한 테스트와 확장을 진행하는 실험/검증 공간.

## 세션 시작 시
- **[context.md](context.md)의 가장 최신 "진행 로그" 항목을 먼저 확인**하고, 마지막 중단 지점/다음 할 일부터 이어서 진행한다.

## 문서 자동 최신화 & 세션 연속성 (상시 정책 — 매우 중요)
> 사용자가 요청하지 않아도 Claude가 **스스로** 문서를 항상 최신 상태로 관리한다. (세션 종료 요청이 없어도 상시 적용.)
- **의미 있는 변경·개선·수정·새 발견이 생기면 요청 없이도** 관련 문서를 알아서 갱신한다: 이 `CLAUDE.md`, `context.md`(진행 로그), `docs/*`, 각 스킬의 `SKILL.md`. **옛 내용이 새 사실과 어긋나면 정정**한다(옛 기록은 필요 시 보존).
- **`context.md`의 "진행 로그"를 살아있는 상태로 유지**한다 — 의미 있는 작업이 끝날 때마다 그 세션의 진행·결정·다음 할 일을 추가해, **다음 세션이 맥락 손실 없이 자연스럽게 이어지게** 한다.
- 새 엣지/에러 케이스는 [docs/tia-extraction-edge-cases.md](docs/tia-extraction-edge-cases.md)처럼 별도 문서로 누적한다.
- **커밋은 유의미한 시점마다 자동, 푸시는 사용자 요청 시에만.** repo는 **Public**이라 실데이터(PLC 블록·태그)·비밀정보는 **절대 커밋하지 않는다**(추출물은 repo 밖에 보관).

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
- [context.md](context.md) — 회사/업무 상세 컨텍스트 + **진행 로그**(살아있는 문서, 세션 연속성의 핵심)
- [docs/tia-openness-extraction.md](docs/tia-openness-extraction.md) — TIA Openness 데이터 추출 **방법론 & SimaticML 형식** 레퍼런스 (이 PC 검증본)
- [docs/tia-extraction-edge-cases.md](docs/tia-extraction-edge-cases.md) — 추출 **엣지/에러 케이스** 누적 정리
- [.claude/skills/tia-block-extract](.claude/skills/tia-block-extract/SKILL.md) — 블록 추출 스킬(자동컴파일+에러리포트) / [tools/block-excel/blocks_to_excel.py](tools/block-excel/blocks_to_excel.py) — 고정/변동 엑셀 도구
- [docs/program-blocks-and-license.md](docs/program-blocks-and-license.md) · [docs/tia-gui-troubleshooting.md](docs/tia-gui-troubleshooting.md) — 학습노트 / GUI 병목 기록
- [docs/references/tia-portal-claude-code-workshop.md](docs/references/tia-portal-claude-code-workshop.md) — TIA Portal + Claude Code 연동 워크숍 요약 (ControlByte)
