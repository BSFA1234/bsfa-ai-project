# TIA Openness 데이터 추출 — 방법론 & 형식 레퍼런스 (이 PC 기준)

> **독립 문서.** context.md / CLAUDE.md 와 섞지 않는 standalone 레퍼런스다.
> 목적: 이 PC(현재 작업 환경)에서 TIA Portal 프로젝트의 데이터를 **Openness API로 정확하게 추출**하는 방법과, 추출물의 **형식(SimaticML XML)** 을 한 문서로 정리해 앞으로 재현·확장 가능하게 한다.
> 작성/검증: 2026-06-20, 프로젝트 `CP_A4_전착스키드회송`(S7-1500)에서 실측.
>
> ⚠️ **공개 저장소 주의**: 이 repo는 현재 Public이다. **이 문서는 "방법론·형식"만** 담는다. 실제 추출된 블록 데이터(피연산자·주소·심볼·로직)는 **repo에 커밋하지 않고** repo 밖(예: `C:\Users\user\Desktop\bsfa-extract-test\`)에 둔다. 아래 XML 예시는 실데이터가 아니라 **구조를 보여주는 골격(placeholder)** 이다.
> ⚠️ **안전(절대선)**: 모든 추출은 **read-only**. 실장비 Download 금지, `05_Safety` F-블록은 읽기만(수정·생성 금지), 원본 프로젝트는 사본에서만 다룬다.

---

## 0. TL;DR (한 줄 요약)

실행 중인 TIA에 Openness로 **attach → PLC 소프트웨어 탐색 → 블록 트리 walk → `block.Export()`** 하면, PLC 블록이 **읽을 수 있는 SimaticML XML(텍스트)** 로 빠진다. 이 PC에서는 **HSP/SCALANCE 우회가 전혀 필요 없다** (옛 문서와 다른 핵심).

---

## 1. 이 PC의 검증된 환경 (2026-06-20 실측)

| 항목 | 값 |
|---|---|
| TIA Portal | **V20 Update 4** (STEP 7 Professional / Safety / WinCC / Startdrive 옵션 설치됨) |
| Openness DLL | `C:\Program Files\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll` (v2000.4.401.2) |
| 의존 DLL 폴더 | `…\PublicAPI\V20` (Engineering, Hmi) + `…\Bin\PublicAPI` (Contract 등) — **둘 다** 리졸버에 등록해야 함 |
| 권한 그룹 | 로컬 그룹 **`Siemens TIA Openness`** 에 현재 계정 가입됨 (필수) |
| 화면 | 듀얼모니터 + **150% 배율** → **GUI 좌표 자동화는 불안정** (좌표 하드코딩 깨짐). 그래서 **API 추출이 정답.** |

> 즉, "데이터 추출"은 GUI 클릭이 아니라 **Openness API**로 한다. (GUI 좌표 자동화는 이 PC 해상도/배율 때문에 어긋난다.)

---

## 2. 옛 문서 대비 — 이 PC에서 바뀐 핵심

옛 추출 정리 문서(`\\100.68.178.75\…\01_TIA_텍스트추출_정리.md`)의 가장 큰 전제는 *"현장 프로젝트는 HSP0398(SCALANCE) 누락 때문에 Openness가 `Projects.Count=0`으로 못 연다 → SCALANCE 삭제 사본 우회 필요"* 였다.

**이 PC에서는 그 블로커가 없다.** 실측:
- SCALANCE 스위치 5개(HUB01/11/12/21/22)가 **그대로 있는 채로** attach → `Projects.Count = 1`, 226개 블록 전부 트리 읽힘.
- 따라서 **SCALANCE 삭제·사본 우회·`.zap20` retrieve 같은 우회 절차는 이 PC에선 불필요.** 실행 중인 프로젝트에 attach해서 바로 Export하면 된다.

> 여전히 유효한 옛 교훈(검증됨): ① Export는 **일관(컴파일된) 블록만** 가능 → inconsistent면 선컴파일 ② 포맷은 원블록 언어 따라감(LAD/FBD/DB=XML, SCL=GenerateSource) ③ 리졸버 2폴더 / C#에서 등록 / V20 DLL / LoadFrom 사용 / `.ps1` 본문 ASCII.

---

## 3. 추출이 동작하는 원리 (단계별)

추출 1건은 내부적으로 이 순서로 동작한다:

1. **어셈블리 리졸버 등록 (C# 안에서)** — `AppDomain.CurrentDomain.AssemblyResolve` 핸들러를 **C# 코드 내부**에서 등록한다.
   - 동작: ① 이미 로드된 어셈블리 중 이름이 같으면 그걸 반환 ② 아니면 `PublicAPI\V20`·`Bin\PublicAPI` 두 폴더에서 `<이름>.dll`을 `Assembly.LoadFrom` ③ 없으면 null.
   - ⚠ PowerShell 스크립트블록으로 등록하면 **StackOverflow** → 반드시 C#에서.
2. **엔진 DLL 로드** — `Siemens.Engineering.dll`을 **`Assembly.LoadFrom`** 으로 로드 (`Add-Type -Path`로 로드하면 `ReflectionTypeLoadException`).
3. **인스턴스 attach** — `TiaPortal.GetProcesses()`로 실행 중 인스턴스 목록 → 원하는 프로젝트(PID 또는 `ProjectPath` 부분일치)를 골라 `.Attach()` → `tiaPortal.Projects`의 첫 프로젝트 채택.
   - attach는 **읽기 전용**이고 GUI 창을 닫지 않는다. (Dispose 안 하면 GUI 그대로 유지)
4. **PLC 소프트웨어 탐색** — `project.Devices → DeviceItem`을 **재귀**로 내려가며 `GetService<SoftwareContainer>()` 시도 → `Software`가 `PlcSoftware`면 그게 PLC.
5. **블록 트리 walk** — `plc.BlockGroup`부터 `.Blocks[]` / `.Groups[]`를 **재귀**. 각 블록은 `Name`, 종류(`OB/FB/FC/GlobalDB/InstanceDB`), `ProgrammingLanguage`, `IsConsistent`, `Number`를 가짐.
   - ⚠ 그룹명에 `Safety`가 있으면 정책에 따라 **skip**(쓰기성 작업) 또는 **읽기전용 격리**(텍스트 미러).
6. **(필요 시) 선컴파일** — `block.IsConsistent == false`면 Export가 거부됨 → `block.GetService<ICompilable>().Compile()` 후 재시도. (컴파일은 다운로드와 무관하나 프로젝트를 메모리상 "수정됨"으로 만든다 → 사본에서만, 저장 안 함.)
7. **Export** — `block.Export(new FileInfo(경로), ExportOptions.WithDefaults)` → SimaticML **XML** 파일 생성.
   - 파일이 이미 있으면 먼저 삭제(Export는 기존 파일에 덮어쓰지 않고 throw).

### 추출에 쓰는 Openness API 요약

| 동작 | 호출 |
|---|---|
| LAD/FBD/DB 블록 → XML | `block.Export(fileInfo, ExportOptions.WithDefaults)` |
| SCL로 *작성된* 블록 → .scl | `plc.ExternalSourceGroup.GenerateSource(List<IGenerateSource>, fileInfo)` |
| UDT → XML | `udt.Export(fileInfo, WithDefaults)` (`plc.TypeGroup` 재귀) |
| 태그테이블 → XML | `tagtable.Export(fileInfo, WithDefaults)` (`plc.TagTableGroup` 재귀) |
| 컴파일 | `block(또는 plc).GetService<ICompilable>().Compile()` → `.State`/`.ErrorCount`/`.Messages` |
| 트리 | `plc.BlockGroup.Groups[].Blocks[]` / `.TypeGroup` / `.TagTableGroup` |
| 인스턴스 | `TiaPortal.GetProcesses()[].Attach()` |

### 포맷 선택 규칙 (중요)
- **LAD / FBD / DB** → `block.Export` (SimaticML **XML**)
- **SCL로 작성된 블록** → `GenerateSource` (**.scl** 텍스트)
- ⚠ **LAD/FBD를 SCL로는 변환 불가** — LAD 블록에 GenerateSource 쓰면 throw/빈결과. LAD는 무조건 XML.

---

## 4. 추출물의 형식 — SimaticML XML 구조

`block.Export(... WithDefaults)`로 나오는 XML의 골격 (LAD FC 기준, **placeholder**):

```xml
<?xml version="1.0" encoding="utf-8"?>
<Document>
  <Engineering version="V20" />
  <DocumentInfo>
    <Created>…ISO8601 타임스탬프…</Created>
    <ExportSetting>WithDefaults</ExportSetting>
    <InstalledProducts>…TIA 버전·옵션패키지 목록…</InstalledProducts>
  </DocumentInfo>

  <!-- 블록 1개 = 루트 바로 아래 1개 요소. 종류에 따라 태그명이 다름:
       SW.Blocks.FC / SW.Blocks.FB / SW.Blocks.OB / SW.Blocks.GlobalDB / SW.Blocks.InstanceDB -->
  <SW.Blocks.FC ID="0">
    <AttributeList>
      <Interface><Sections xmlns="…/Interface/v5">
        <Section Name="Input" />     <!-- 인터페이스: 입력/출력/InOut/임시/상수/반환 -->
        <Section Name="Output" />
        <Section Name="InOut" />
        <Section Name="Temp" />
        <Section Name="Constant"><Member Name="…" Datatype="Byte" /></Section>
        <Section Name="Return"><Member Name="Ret_Val" Datatype="Void" /></Section>
      </Sections></Interface>
      <MemoryLayout>Optimized</MemoryLayout>
      <Name>블록이름</Name>                 <!-- 한글 가능 -->
      <Number>10000</Number>
      <ProgrammingLanguage>LAD</ProgrammingLanguage>
    </AttributeList>

    <ObjectList>
      <!-- 블록 주석 (다국어) -->
      <MultilingualText CompositionName="Comment">…</MultilingualText>

      <!-- ★ 네트워크(rung) 1개 = CompileUnit 1개. 블록 안에 여러 개 -->
      <SW.Blocks.CompileUnit ID="3" CompositionName="CompileUnits">
        <AttributeList>
          <NetworkSource>
            <FlgNet xmlns="…/NetworkSource/FlgNet/v5">

              <Parts>
                <!-- (a) 피연산자(태그/DB멤버/상수) = Access. UId로 식별 -->
                <Access Scope="GlobalVariable" UId="21">
                  <Symbol>
                    <Component Name="DB_이름" />     <!-- 예: DB → 멤버 경로 -->
                    <Component Name="멤버_이름" />
                  </Symbol>
                </Access>
                <Access Scope="GlobalConstant" UId="24">
                  <Constant Name="…" />
                </Access>

                <!-- (b) LAD 명령 = Part. Name이 명령종류(Contact/Coil/Not/…) -->
                <Part Name="Contact" UId="25">
                  <Negated Name="operand" />          <!-- Negated 있으면 b접점(NC), 없으면 a접점(NO) -->
                </Part>

                <!-- (c) FB/FC 호출 = Call -->
                <Call UId="29">
                  <CallInfo Name="호출블록" BlockType="FB">
                    <Instance Scope="GlobalVariable" UId="30"><Component Name="인스턴스DB" /></Instance>
                    <Parameter Name="…" Section="Input"  Type="Bool" />
                    <Parameter Name="…" Section="Output" Type="Bool" />
                  </CallInfo>
                </Call>
              </Parts>

              <Wires>
                <!-- 배선: 부품 핀끼리/전원레일/피연산자 연결 = 래더 토폴로지 -->
                <Wire UId="35">
                  <Powerrail />                        <!-- 왼쪽 전원레일 -->
                  <NameCon UId="29" Name="en" />        <!-- UId 부품의 명명된 핀(en/in/out 등) -->
                  <NameCon UId="25" Name="in" />
                </Wire>
                <Wire UId="36">
                  <IdentCon UId="21" />                 <!-- 피연산자(Access)로의 연결 -->
                  <NameCon UId="25" Name="operand" />
                </Wire>
              </Wires>

            </FlgNet>
          </NetworkSource>

          <!-- 네트워크 제목/주석은 별도 MultilingualText (CompositionName="Title"/"Comment").
               문화권이 en-US여도 안에 한글 텍스트가 들어 있음. -->
        </AttributeList>
      </SW.Blocks.CompileUnit>

      <!-- … 네트워크 수만큼 CompileUnit 반복 … -->
    </ObjectList>
  </SW.Blocks.FC>
</Document>
```

### 형식 읽는 법 (핵심 개념)
- **`<Document>`** 루트 → `<Engineering version>` + `<DocumentInfo>`(생성시각·Export옵션·설치제품) + **블록 요소 1개**.
- **블록 요소** `SW.Blocks.<종류>`: `AttributeList`(이름/번호/언어/메모리레이아웃/**Interface**(섹션·멤버)) + `ObjectList`.
- **네트워크 = `SW.Blocks.CompileUnit`** (블록 안 rung 1개당 1개). 핵심은 그 안의 **`FlgNet`**.
- **`FlgNet` = `<Parts>` + `<Wires>`**:
  - **Access** = 피연산자(심볼/상수). `Scope`(GlobalVariable/GlobalConstant/LocalVariable…), `Symbol > Component` 체인(DB→멤버).
  - **Part** = LAD 명령(`Contact`/`Coil`/`Not`/`Add`…). `Negated`면 **b접점(NC)**.
  - **Call** = FB/FC 호출(`CallInfo` + `Instance` + `Parameter`들).
  - **Wire** = 연결선. `Powerrail`(전원레일), `NameCon`(부품 핀: en/in/out/operand), `IdentCon`(피연산자로의 연결) → **래더 배선 구조**를 인코딩.
- **`UId`** = 네트워크 내부 고유번호(Parts/Wires 상호참조용). **export마다 값이 임의로 달라질 수 있음** → 블록 비교 시 정규화 대상.
- **다국어 텍스트**: 블록 주석·네트워크 제목은 `MultilingualText`로 분리. en-US 컬처라도 **한글 본문 포함**.

> 이 구조 덕분에 다운스트림(블록 비교기)이 "네트워크 제목 + 명령 순서 + 피연산자 + 배선"을 읽어 형제 블록 간 누락·오타·구조차이를 검출할 수 있다.

---

## 5. 실측 예시 (이번 작은-단위 테스트)

- 대상: `01_공통 / 01_PNIO` 의 FC 1개 (`IO_Card_PNIO_경고`), 언어 LAD, consistent=True.
- 명령: attach(PID로 선택) → 그룹경로 `01_공통/01_PNIO`에서 이름 일치 블록 → `Export(WithDefaults)`.
- 결과: **140.4 KB / 4387줄 / well-formed XML** (루트 `<Document>`, 블록요소 `SW.Blocks.FC`).
- 저장 위치(=repo 밖): `C:\Users\user\Desktop\bsfa-extract-test\pnio\IO_Card_PNIO_경고.xml`
- 확인된 내용: 인터페이스(Constant=`Zero:Byte`, Return=`Ret_Val:Void`), 네트워크들, 첫 네트워크에서 `FB_DIAG_PN`(PROFINET 진단 FB) 호출 + Contact(NC) 체인 + Powerrail 배선.

---

## 6. 추출 산출물 저장 규칙

- **추출된 실데이터(XML/SCL/태그/UDT)는 이 repo에 넣지 않는다** (Public repo). repo 밖 작업폴더(`bsfa-extract-test\` 등) 또는 회사 표준 저장소(`\\100.68.178.75\bsfa_ai\999. AI TEMP STORAGE`)에 저장.
- repo에는 **이 문서 같은 방법론/형식 레퍼런스만** 둔다.

---

## 7. 다음에 확장할 것 (단계적)

1. **inconsistent 블록 추출** — OP01/02/03/06/07/08처럼 미컴파일 블록은 선컴파일 후 Export (사본에서, 저장 안 함).
2. **태그테이블 / UDT / 프로젝트텍스트** 추출 (위 API 표대로).
3. **블록 비교** — 추출 XML을 기준 블록과 비교(형제 일관성 검사).
4. **재현 스크립트화** — 위 동작을 파라미터(블록정규식/출력폴더/PID) 받는 스크립트로. (`.ps1` 본문 ASCII, 한글은 파일시스템/데이터로.)

> 최종 검증은 항상 **컴파일 + PLCSIM + 엔지니어 검토** (추출/비교는 보조 도구일 뿐).
