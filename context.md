# BSFA 프로젝트 컨텍스트

> 이 문서는 논의를 진행하며 계속 확장하는 살아있는 문서입니다.
> 마지막 갱신: 2026-06-16

## 1. 회사 소개

- **부산자동화시스템 (BSFA)**: 산업 자동화 시스템 회사
- 주력 작업 도구: Siemens **TIA Portal** (PLC 프로그래밍)
- <!-- TODO: 주요 사업 분야, 고객사 유형, 팀 규모 등 추가 -->

## 2. 프로젝트 목표

- Claude(Claude Code)를 도입하여 회사 업무 효율화
- TIA Portal 작업과 AI 연동 가능성 테스트 및 검증
- 참고 모델: ControlByte Automation의 TIA Portal Copilot 사례 → [워크숍 요약](docs/references/tia-portal-claude-code-workshop.md)

## 3. 기술 환경 (2026-06-11 점검)

- OS: Windows 11
- TIA Portal: **V20 설치됨** (`C:\Program Files\Siemens\Automation\Portal V20`)
- TIA Portal Openness: **설치됨** — API 라이브러리 확인 완료
  - `C:\Program Files\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll`
- .NET Framework 4.8.1 설치됨 (PowerShell로 Openness DLL 직접 호출 가능)
- .NET SDK(dotnet CLI 빌드 도구): 미설치 — 당장은 불필요, PowerShell로 대체
- "Siemens TIA Openness" 사용자 그룹: **부산자동화 계정 추가 완료** (2026-06-11)
- 기타 도구: <!-- TODO: EPLAN, Excel 태그 시트 등 사용 여부 -->

## 4. 자동화 후보 업무 (워크숍 기반 아이디어)

- Excel/EPLAN → 태그 테이블 자동 입력
- 자연어 설명 → FB(Function Block) 생성
- Ladder Logic → SCL 변환
- 프로젝트 구조 분석 및 문서화 (Markdown)
- 프로젝트 간 라이브러리/UDT 이식
- Git 기반 PLC 코드 버전 관리

## 5. 결정 기록

| 날짜 | 결정 | 배경 |
|------|------|------|
| 2026-06-11 | CLAUDE.md(자동 로드 핵심 요약) + context.md(상세 컨텍스트) 이중 구조 채택 | Claude Code가 CLAUDE.md를 세션마다 자동으로 읽기 때문 |

## 6. 진행 로그

### 2026-06-11 — 환경 점검 및 Openness 권한 설정
- ControlByte 워크숍 요약 확보 → `docs/references/tia-portal-claude-code-workshop.md`
- CLAUDE.md + context.md 이중 문서 구조 수립
- 환경 점검 완료: TIA Portal V20 ✓, Openness DLL ✓, .NET Framework 4.8.1 ✓
- "Siemens TIA Openness" 그룹에 사용자 계정 추가 완료 (관리자 PowerShell로 직접 수행)
- **중단 지점**: 그룹 추가 후 재로그인/재부팅 필요 → 사용자가 재부팅하러 감

### 2026-06-12 — Openness 첫 연결 성공 & 실제 프로젝트 열기 시도
- 재부팅 후 Openness 그룹 권한 적용 확인 ✓
- **Openness API 연결 성공**: PowerShell `Add-Type`으로 DLL 로드 → TIA Portal V20 실행(WithUserInterface) → Attach → Project1 열기/닫기까지 검증
  - 참고: `Add-Type` 시 ReflectionTypeLoadException 경고가 뜨지만 무시해도 됨 (HMI 부가 타입 문제, 핵심 기능 정상)
- 실제 프로젝트 발견: A2_전착오븐, A3_전착버퍼 (Desktop), A2_PANELTEST (Desktop\프로그램), Project1 (Documents\Automation)
- 원본 보호를 위해 사본을 `tia-projects/` 폴더에 생성 후 열기 시도
- **차단 지점**: 실제 프로젝트 3개 모두 열기 실패 — **HSP0398 (SCALANCE X200 X300 V4.6) 하드웨어 지원 패키지 미설치** 때문
  - 다른 PC에서 작성된 프로젝트로 추정. PC 내 HSP 설치 파일 검색했으나 없음
- **다음 단계**: 사용자가 HSP0398 설치 (TIA Portal GUI: 옵션 → 지원 패키지 → 인터넷에서 다운로드, 또는 SiePortal에서 수동 다운로드) → TIA Portal 재시작 → 사본 프로젝트 열기 재시도

### 2026-06-12 (이어서) — 테스트 프로젝트 생성 & 라이선스 문제 발견
- HSP0398 다운로드 시도: SiePortal 페이지 오류로 미완. 공식 다운로드 문서는 https://support.industry.siemens.com/cs/document/72341852 (HSP0398 = SCALANCE X200/X300 FW V4.6, V20 섹션에서 받기)
- 방향 전환: HSP 없이도 가능한 **새 테스트 프로젝트 생성**으로 진행
- **BSFA_TEST 프로젝트 API로 생성 성공** (`tia-projects\BSFA_TEST`)
- **차단 지점(중요)**: PLC 장치 추가 실패 — **"STEP 7 Basic 라이선스 없음"**
  - 전체 드라이브에서 라이선스 키 폴더(`AX NF ZZ`) 검색 → 없음. ALM은 설치되어 있음
  - 추정: 체험판(21일) 만료. 이 PC에 5월말~6월초 작업 흔적 있음
- 사용자가 PLC 기초 개념 학습 완료 (블록=레고 조각, OB/FB/FC/DB, 래더=그림 코드, SCL=글자 코드, XML=포장지, 태그=이름표)
- 참고: TIA GUI에서 PANELTEST 원본을 열다 멈춘 상태가 API 작업을 막았었음 → TIA 재시작으로 해결

### ▶ 다음 세션에서 할 일 (이어서 진행)
1. **라이선스 확인 결과 듣기** (사용자가 회사에 확인 중):
   - 라이선스 USB 스틱 존재 여부 / 다른 PC에 라이선스 / 플로팅 서버 여부
   - 또는 TIA GUI에서 "Add new device" 시도 시 Trial 활성화 창이 떴는지
2. 라이선스 해결되면 **눈으로 보는 데모** 진행: BSFA_TEST 열기 → PLC 추가 → 태그 10개 자동 입력 → SCL로 FB 생성·import → 사용자가 TIA GUI에서 확인
3. 병행 과제: HSP0398 다운로드 (위 링크, 지멘스 무료 계정 필요) → 설치 후 실제 프로젝트(A2_전착오븐 사본) 분석
4. PLC 추가 보일러플레이트: `$project.Devices.CreateWithItem("OrderNumber:6ES7 214-1AG40-0XB0/V4.7", "PLC_1", "BSFA_Station")` — 라이선스 없으면 'Necessary license STEP 7 Basic is missing' 오류
- 연결 보일러플레이트: `Add-Type -Path "C:\Program Files\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll"` → `([Siemens.Engineering.TiaPortal]::GetProcesses() | Select -First 1).Attach()` (TIA 미실행 시 `New-Object Siemens.Engineering.TiaPortal([Siemens.Engineering.TiaPortalMode]::WithUserInterface)`)
- 첫 Attach 시 TIA Portal에 접근 허용 팝업 → "예" 클릭 필요

## 7. 검증된 기술 사실 (재조사 불필요)

- **Openness는 HSP/제품 누락 시 프로젝트를 절대 못 엶**: `Siemens.Engineering.xml` 공식 문서 확인. 모든 `ProjectComposition.Open*` 메서드가 `MissingProductsException`을 던짐. 열기 옵션 `ProjectOpenMode`는 `Primary`/`Secondary` 두 값뿐 — "누락 무시 열기" 없음. → 회사 프로젝트(SCALANCE 포함)는 **HSP0398 설치 후에만** API로 열림. GUI는 경고 무시 후 열기 가능(별개).
- **GUI로 연 프로젝트는 Attach해도 `tia.Projects.Count = 0`**: 사람이 화면에서 연 프로젝트를 API가 읽지 못함 (2분 폴링해도 0). → API로 읽으려면 내가 직접 Open 해야 함.
- **데스크톱 TIA Portal 화면 제어 불가**: Claude의 화면 제어(computer use)는 웹브라우저(Chrome) 전용. TIA Portal은 네이티브 Windows 앱이라 직접 클릭 불가.
- **API 정확한 클래스/메서드는 `Siemens.Engineering.xml`에서 검증** (추측 금지 원칙 준수용 레퍼런스).
- **데스크톱 컴퓨터 유즈는 PowerShell로 자체 구현 가능**: 전용 도구는 브라우저(Chrome)용뿐이지만, `tools/desktop/Ui.ps1`로 화면 캡처(System.Drawing) + 마우스/키보드(user32)를 만들어 TIA Portal을 직접 조작 성공. 주의점: ① 클릭 전 `WScript.Shell.AppActivate($pid)`로 TIA를 확실히 포그라운드로(SetForegroundWindow만으론 불안정) ② `SetProcessDPIAware`로 캡처 픽셀=커서 픽셀 일치 ③ 한글 경로는 SendKeys 대신 클립보드 붙여넣기 ④ **축소 표시된 전체 스크린샷을 눈대중하면 실제 좌표와 ~1.6배 어긋남** → 항상 해당 영역을 크롭/확대해 실제 픽셀로 좌표 계산.
- **태그 테이블 내보내기 = GUI에서 테이블 열기 → 편집기 툴바의 Export 아이콘(우클릭 메뉴엔 없음)** → 경로 입력 → OK → "Export completed successfully" 확인창 닫기. 라이선스 없는 제한 모드에서도 내보내기 성공.
- **실제 태그 테이블 XML 형식 확인됨** (`tia-projects/sample_tags.xml`, TIA V20 내보내기):
  ```xml
  <?xml version='1.0' encoding='utf-8'?>
  <Tagtable name='테이블이름'>
    <Tag type='DInt' hmiVisible='True' hmiWriteable='True' hmiAccessible='True' retain='False' remark='주석' addr='%MD1000'>태그이름</Tag>
  </Tagtable>
  ```
  → 표의 한 행 = `<Tag>` 한 줄. 이름은 태그 사이 텍스트, 나머지는 속성(type/addr/retain/remark/hmi*). **우리 변환 도구의 출력 목표 = 이 형식.**

## 8. 스킬/도구 제작 진행 (2026-06-15~)

목표: 오늘 검증된 "TIA 조작" 과정을 재사용 스킬로. **스크립트(작은 단위) + SKILL.md(작업 단위)** 2층 구조. 스킬 2개 예정: `tia-open-project`(트리거: "프로젝트 열어줘"), `tia-export-tags`(트리거: "태그 내보내줘"). 스크립트는 공유.

**완성·검증 완료 (2026-06-15):**
스크립트(작은 단위, `tools/`):
- `tools/desktop/Ui.ps1` (토대) — 화면캡처 / 마우스·키보드 / **창 강제 활성화(ForceForeground)** / **좌표 격자(Capture-Screen -Grid, Save-Crop -Grid)**. ✅
- `tools/tia/Start-Tia.ps1` — TIA 실행→활성화→최대화. ✅
- `tools/tia/Open-Project.ps1` — 시작화면에서 프로젝트 열기(더블클릭+HSP). ✅ (단, 행 선택은 아래 주의)
- `tools/tia/Export-TagTable.ps1 -OutPath` — 열린 태그테이블 내보내기(자기완결: Export→경로→OK→성공창 닫기→파일검증). ✅ 483B 생성 확인
- `tools/tia/Close-Project.ps1` — Ctrl+W로 저장없이 닫기. ✅
- `tools/tia/Coords.ps1` — 모든 화면 좌표 한 곳 모음(범용화). 새 컴퓨터/해상도는 이 파일만 수정.

**범용화(이식성) 1차 패스 완료 (2026-06-15):** Start-Tia 버전 자동탐지(V18/19/20), 좌표 전부 `Coords.ps1`로 분리 + 해상도 불일치 경고(`Test-TiaResolution`), 스크립트 간 경로 `$PSScriptRoot` 상대, SKILL.md 절대경로 제거. → 다른 컴퓨터에선 **Coords.ps1만 조정**하면 동작(또는 Claude가 격자로 재조정). 완전 비전-only 자동화는 추후 과제.

스킬(작업 단위, `.claude/skills/`): ✅ 생성
- `tia-open-project` (트리거: "프로젝트 열어줘") / `tia-export-tags` ("태그 내보내줘") / `tia-close-project` ("닫아줘")

**검증된 제작 교훈 (재학습 불필요):**
- **스크립트는 반드시 ASCII로**: PowerShell 5.1이 자식 프로세스(`-File`)에서 .ps1을 CP949로 읽어 한글 주석이 깨지면 Add-Type(C#) 컴파일 실패. 내부 주석/메시지는 영문.
- **창 활성화는 SetForegroundWindow만으론 불안정** → `AttachThreadInput`+ALT 트릭(ForceForeground)으로 자식 프로세스에서도 확실히 동작.
- **좌표는 항상 격자 캡처(`-Grid`)로 읽기** — 축소표시 눈대중은 실제와 ~1.6배 어긋남.
- **클릭 전 반드시 `Ui-Activate`** (안 하면 클릭이 Claude 창으로 샘).
- **확인창 닫기 전엔 내보내기 파일이 0바이트** — 성공창 OK(1085,562) 누른 뒤에야 디스크에 flush.
- **시작화면 최근목록 순서는 가변적** → 고정 행번호 신뢰 금지. 캡처로 대상 프로젝트 행을 찾아 더블클릭(=Open은 "비전 가이드" 단계). 주요 좌표: 최근행 x=800/y≈180부터 +30, HSP Open (1125,672), Project view 링크 (60,1016), "Open existing project" 옵션 (290,162).

**다음 세션 (사용자 요청: 점검 + 개념 정리 한꺼번에):**
1. 스킬 실사용 점검: "프로젝트 열어줘"/"태그 내보내줘"/"닫아줘"로 트리거되는지 확인.
2. **학습 로드맵** 진행 (PANELTEST를 교과서로): 큰그림→구성→데이터(추출 가능/불가, 이유)→래더 vs SCL→자동화 적용점.
3. GitHub 공유 준비 (진행 중):
   - ✅ `.gitignore`(tia-projects/·settings.local.json 제외), `README.md`(스킬+좌표기록+새컴퓨터 체크리스트), `Start-Tia.ps1` TIA버전 자동탐지
   - ✅ 로컬 git init + 커밋 완료 (branch `main`, 13파일, 회사프로젝트 제외 검증됨)
   - ✅ 범용화 1차 패스 완료 (Coords.ps1 중앙화 등 — 위 참고)
   - ✅ `ARCHITECTURE.md` 추가 (Mermaid 구조도 GitHub 자동렌더 + 역할표 + 예시흐름 + 시작안내), README에서 링크. 시각화 구조도도 보여줌(visualize).
   - ✅ **포터블 zip 생성**: `Desktop\bsfa-tia-toolkit.zip` (28.5KB, 커밋된 15파일, 회사 프로젝트 제외, ARCHITECTURE 포함)
   - ⬜ **push**: 사용자가 zip을 **본인 메일로 직접 발송 → 맥북에서 풀고 push** 예정. 맥북: 압축해제 → `git init && git add -A && git commit` → private 저장소 생성 후 push(gh 또는 웹). 인증은 사용자 직접.
   - 로컬 흔적: 이 컴퓨터의 `.git` 폴더(자격증명 없음, 로컬 전용)는 남아 있음 — 원하면 제거 가능.

## 10. 최신 진행 (2026-06-16) — 학습 세션 + IO 변환 도구(효율화 1순위)

**학습 (방식은 CLAUDE.md에 규정함 — 한번에 하나씩/비유/화면보며/사용자가 알 것과 Claude가 할 것 분리):**
사용자가 **태그 · 태그 테이블 · Export/Import · 전체 루프(추출→변환→넣기)** 를 큰 그림으로 이해. PANELTEST의 `CC01` 태그 테이블을 실제로 열어 설명: 한 줄=태그 1개, 주소(`%I`입력/`%Q`출력/`%M`메모리, 바이트.비트), `Bool`, 명명규칙(`P_스테이션_방향_기능`), 비상정지 2채널=안전이중화(F-CPU), MCC On 피드백, `예비`. CC01을 XML로 export(88태그→`tia-projects/CC01_export.xml`, 14.4KB)해 **표↔글자 1:1 대응** 확인. 사용자가 수동 export도 직접 성공.

**역할 분담 확정:** Claude=기술 디테일(주소·XML·SCL), 사용자=방향 지시+결과 승인, BSFA PLC 엔지니어=기술 검증. **사용자는 PLC 개념을 깊이 몰라도 됨** — 목표는 효율.

**효율화 1순위 = 태그/IO 입력 자동화** (사용자 선택, 워크숍 최고효과·저위험):
- **`tools/io-convert/Convert-IoListToTags.ps1`** (+ `sample-io-list.csv`): CSV(엑셀 저장본) → TIA 태그테이블 XML. ✅ 검증 (한글·`%I/%Q/%IW`·`Bool/Int` 보존, 출력 형식이 TIA export와 **동일** → import 가능). **TIA·라이선스 불필요**(순수 텍스트 변환).
- CSV 컬럼: `Name, DataType, Address, Comment`.
- ⚠️ **import(TIA에 넣기)는 라이선스 필요** → 변환·읽기는 되고, 실제 넣기는 라이선스 PC에서.

### 2026-06-16 (이어서) — 프로그램 블록 개념 학습 + 라이선스 경계 발견
**학습(웹/IT 비유로):** "프로그램 블록"은 **폴더**이고 그 안에 블록 4종류가 산다 — **OB**(=main()/콜백, 자동실행), **FC**(=순수함수, 기억X), **FB**(=클래스 인스턴스, 상태 기억 → 전용 DB를 달고 다님), **DB**(=값만 저장, 로직X). 사용자 핵심 혼동("프로그램블록=데이터블록?")을 **폴더📁 vs 그 안의 파일📄**로 해소. **태그≠블록**, DB는 'Program blocks 폴더' 안의 한 종류.
**구조 확인(PANELTEST, GUI 제한모드):** PLC 1대 `A2_CC01_CPU [CPU 1517F-3]`(F=안전) → 📋태그(Default[725]/Timer[254]/InOut(CC01[88]...) 등) + 📦Program blocks(기능폴더: 01_공통/02_제어/03_장비/04_인터록/05_Safety/09_PCR/System). 예) **02_제어 = FC_Global[FC300] + 하위폴더(01_CC01, 02_DP, 03_OP, 04_WOP_DBs)**.
**★ 핵심 발견 — 라이선스 경계:** 블록(FC_Global)을 열자 **"License 'STEP 7 Professional' was not found"** 오류. → **블록 편집·컴파일·다운로드·import = STEP 7 Professional 필요**. 단 **블록 열람(래더/SCL 보기)은 라이선스 없이 제한모드로 가능**(오류창 떠도 OK/Esc로 닫으면 열람됨 — ⚠️초기에 '블록 열기 전면 불가'로 **오판했다가 사용자 지적으로 정정**). **태그 보기·XML내보내기·IO변환 = 라이선스 무관**. **태그/IO 자동화가 1순위인 이유 재확인**(라이선스 없이 당장 가능).
**입력 방식 교훈(이 PC):** TIA 자동조작 시 **마우스 단일 좌클릭 + 저수준 키입력(keybd_event)만 안정**. 더블클릭/우클릭 컨텍스트메뉴/SendKeys는 불안정 → 폴더 펼치기는 토글(▶) 단일클릭, 키는 keybd_event.
**산출물:** 학습노트 `docs/program-blocks-and-license.md`. **울트라코드(멀티에이전트)는 이 작업(단일화면 조작+대화형 교육)엔 부적합** 판단 → 단일 흐름 자율 진행.
**후속(스킬화·범용화·공유):** 검증된 keybd 입력을 `Ui.ps1` 헬퍼(`Ui-Enter`/`Ui-Down`/`Ui-Up`/`Ui-Expand`/`Ui-Collapse`/`Ui-Esc`/`Ui-FocusClick`)로 굳힘 — **좌표 무관이라 타 PC 범용**. 병목·착오 누적 로그 `docs/tia-gui-troubleshooting.md` 신설. **GitHub 업로드용 폴더** `Desktop\bsfa-upload` 생성(회사프로젝트·.git·settings.local 제외, 20파일) → 사용자가 웹에서 드래그앤드롭 예정(1회성, 비메인 PC).

### ▶ 다음 세션 (최신 — 이게 우선)
0. **블록 열람·래더→SCL 분석은 이 PC에서도 가능**(제한모드, 라이선스 무관). FC_Global(LAD, 0.1초 펄스 생성기) 열람·SCL 번역 시연 완료. SCL 소스 생성(export)·편집·import는 STEP 7 Professional 라이선스 PC에서. (★ '블록 전면 불가'는 오판이었음 — 열람은 됨. 입력 방식·병목은 `docs/tia-gui-troubleshooting.md` 참고)
1. BSFA **실제 I/O 리스트(Excel) 샘플**을 받아 converter 컬럼을 실제 양식에 맞추기 (없으면 현재 4컬럼 양식 사용).
2. (선택) converter가 `.xlsx`를 직접 읽도록 확장 (현재는 CSV; 엑셀→CSV 저장 필요).
3. 라이선스 PC에서 **import 테스트**로 전체 루프 완성 (라이선스 확인: USB/다른PC/서버 — 여전히 열린 과제).
4. GitHub push: zip `Desktop\bsfa-tia-toolkit.zip`는 **io-convert 추가 전 버전 → 공유 전 재생성 필요**.

> 참고: 위 6·8번의 옛 "다음 세션" 목록은 과거 기록. **이 10번 항목이 최신.**

## 9. 용어집

| 용어 | 설명 |
|------|------|
| TIA Portal | Siemens의 통합 자동화 엔지니어링 툴 (PLC/HMI 프로그래밍) |
| TIA Portal Openness | TIA Portal을 코드로 제어할 수 있는 공식 API (C#/.NET) |
| SCL | Structured Control Language — 텍스트 기반 PLC 언어 (IEC 61131-3 ST) |
| Ladder Logic (LAD) | 릴레이 회로 형태의 그래픽 PLC 언어 |
| FB / FC / OB / DB | Function Block / Function / Organization Block / Data Block |
| UDT | User Defined Type — 사용자 정의 데이터 타입 |
| PackML | 포장 기계 표준 상태 머신 모델 (ISA-TR88) |
| EPLAN | 전기 설계 CAD 소프트웨어 |
