# BSFA TIA Portal × Claude 자동화 툴킷

부산자동화시스템(BSFA)에서 **Claude Code로 Siemens TIA Portal을 자동 조작**하기 위한 스크립트·스킬 모음입니다.
Claude가 화면을 캡처해 "보고", 마우스·키보드로 "조작"하는 방식(컴퓨터 유즈)으로 동작합니다.

> ⚠️ **이 저장소는 회사 내부 private 전용.** 회사 실제 프로젝트(`tia-projects/`)는 `.gitignore`로 제외됩니다. 공개 저장소로 올리지 마세요.

> 📐 **전체 구조와 흐름이 궁금하면 → [ARCHITECTURE.md](ARCHITECTURE.md)** (GitHub에서 다이어그램이 자동으로 그려집니다).

## 구성

```
bsfa-tia-test/
├─ tools/
│  ├─ desktop/Ui.ps1          # 토대: 화면캡처 · 클릭/키보드 · 창 강제활성화 · 좌표격자
│  └─ tia/
│     ├─ Coords.ps1           # ★ 화면 좌표 한 곳 모음 (새 컴퓨터에선 이 파일만 수정)
│     ├─ Start-Tia.ps1        # TIA 실행(버전 자동탐지)→활성화→최대화
│     ├─ Open-Project.ps1     # 시작화면에서 프로젝트 열기(더블클릭+HSP)
│     ├─ Export-TagTable.ps1  # 열린 태그테이블 → XML 내보내기(자기완결)
│     └─ Close-Project.ps1    # Ctrl+W로 저장없이 닫기
├─ .claude/skills/            # Claude Code 스킬 (작업 단위)
│  ├─ tia-open-project/       # "프로젝트 열어줘"
│  ├─ tia-export-tags/        # "태그 내보내줘"
│  └─ tia-close-project/      # "닫아줘"
├─ docs/references/           # 워크숍 요약 등 참고자료
├─ context.md · CLAUDE.md     # 프로젝트 컨텍스트(회사 정보 포함 → private 유지)
└─ tia-projects/              # 회사 프로젝트 사본 (.gitignore로 제외)
```

## 작동 원리

스크립트(작은 단위) = 마우스/키보드 기계 동작. 스킬(SKILL.md) = Claude가 따르는 작업 절차.
핵심: **Claude가 `Capture-Screen -Grid`로 좌표 격자를 입힌 화면을 읽어 클릭 위치를 정한다.**
→ 하드코딩 좌표는 "이 컴퓨터(1920×1080·100%)용 속도 단축키"이고, 다른 화면에서는 Claude가 격자로 다시 읽어 적응한다.

## 사용법

Claude Code에서 자연어로 요청하면 해당 스킬이 자동 실행됩니다:
- "TIA 프로젝트 열어줘" → `tia-open-project`
- "태그 내보내줘" / "태그 추출해줘" → `tia-export-tags`
- "프로젝트 닫아줘" → `tia-close-project`

(또는 `/tia-open-project` 처럼 직접 호출)

## 하드코딩 좌표 기록 (기준: 최대화 1920×1080, 배율 100%)

> 이 값들은 **`tools/tia/Coords.ps1` 한 파일에 모여 있음** — 새 컴퓨터/다른 해상도에선 그 파일만 고치면 됨. 스크립트는 해상도가 기준과 다르면 자동으로 경고하고, Claude가 `-Grid` 캡처로 재확인해 조정한다. (아래 표는 사람이 보기 위한 사본)

| 화면 | 요소 | 좌표 (x,y) |
|---|---|---|
| 시작화면(Portal) | "Open existing project" 옵션 | 290, 162 |
| 시작화면 | 최근 프로젝트 1행 (이후 +30/행) | 800, 180 |
| 시작화면 | ※최근목록 **순서는 가변** → 이름 보고 행 선택 | — |
| 열기 | HSP "Open"(제품 누락 경고) | 1125, 672 |
| 포털↔프로젝트 | "Project view" 링크 | 60, 1016 |
| 프로젝트뷰 | "Portal view" 토글 | 45, 1016 |
| 메뉴 | "Project" 메뉴 | 45, 31 |
| 메뉴 | (메뉴 내) 최근 프로젝트 1행 | 200, 308 |
| 트리 | PLC 노드 펼치기 ▶ | 49, 239 |
| 트리 | "PLC tags" 펼치기 ▶ | 69, 391 |
| 트리 | "Default tag table" | 160, 448 |
| 태그편집기 | Export 아이콘 | 352, 135 |
| 내보내기창 | 경로 입력칸 | 830, 443 |
| 내보내기창 | OK | 1054, 623 |
| 성공창 | OK | 1085, 562 |
| 닫기 | Project 닫기 | 단축키 Ctrl+W |

## 새 컴퓨터 설정 체크리스트 (이식성)

1. **Windows + TIA Portal 설치** (V18 이상 권장). `Start-Tia.ps1`이 버전을 자동탐지.
2. **화면 해상도/배율 확인**: 1920×1080·100%면 좌표 그대로. 다르면 **`tools/tia/Coords.ps1` 한 파일만** 그 화면 기준으로 수정(스크립트가 불일치 시 경고). Claude가 `-Grid` 캡처로 재조정 가능.
3. **경로**: `Ui.ps1` 참조는 `$PSScriptRoot` 상대경로라 위치 무관. 스킬(SKILL.md) 안의 프로젝트 절대경로만 그 컴퓨터에 맞게 수정.
4. **Openness 사용 시(선택)**: 'Siemens TIA Openness' 그룹 가입 + STEP 7 라이선스 필요(아래 한계 참고).
5. **회사 프로젝트**: 각자 자기 프로젝트를 열어 사용. 최근목록 순서가 다르므로 이름으로 선택.

## 안전 규칙

- **읽기 전용 우선**: 태그/블록 내보내기·분석 등 비파괴 작업만 자동화. 저장·다운로드·실장비 반영 금지.
- 프로젝트 닫기는 **저장 안 함**(원본 보존). 변경 저장이 필요하면 사람이 직접.
- AI가 만든 제어 로직은 **사람 100% 검토·승인 후**에만, PLCSIM→정지 실장비 순으로 검증.

## 한계 & 다음 단계

- GUI 클릭 방식은 화면 배치가 바뀌면 깨질 수 있음(좌표 의존). 점진적으로 비전 가이드 비중을 늘려 범용성 확대 예정.
- 근본적 견고화 = **TIA Openness(API)로 직접 추출**. 현재 STEP 7 라이선스 부재 + HSP 미설치로 보류. 라이선스 해결 시 GUI 스킬을 Openness 호출로 업그레이드.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
