---
name: tia-block-extract
description: TIA Openness로 현재 열린(실행 중) TIA Portal 프로젝트의 PLC 블록을 SimaticML XML로 추출(export)한다. 그룹 경로/이름 정규식으로 대상을 고르고, 컴파일된 블록만 추출하며 미컴파일 블록은 건너뛰고 목록으로 보고한다. 05_Safety는 기본 skip, read-only(저장·다운로드·수정 안 함). "블록 추출", "OP 블록 XML로 뽑아줘", "01_PNIO 블록 추출", "블록 데이터 빼줘" 같은 요청에 사용. 이 PC(TIA V20, Openness 동작 확인됨)에서 검증된 project-local 버전.
---

# PLC 블록 추출 (TIA Openness -> SimaticML XML)

실행 중인 TIA Portal 인스턴스에 **attach**해서 PLC 블록을 **SimaticML XML**로 내보낸다.
**완전 read-only** — 프로젝트를 저장/다운로드/수정하지 않고, GUI 창도 닫지 않는다.

> 이 스킬은 이 PC에서 실측 검증됨: `block.Export()` 한 호출이 OB/FB/FC/DB는 물론 **SCL 블록까지** 모두 정상 XML로 추출된다. HSP/SCALANCE 우회 불필요(이 PC에선 attach로 바로 읽힘).

## 사전 조건
- TIA Portal **V20** 실행 중 + 대상 프로젝트가 열려 있을 것.
- 계정이 Windows 로컬 그룹 **`Siemens TIA Openness`** 에 포함.
- 추출은 **컴파일된(consistent) 블록만** 가능. 미컴파일 블록은 사람이 TIA에서 먼저 컴파일해 두면 다음 실행에 포함된다.

## 실행
```
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill>\scripts\extract_blocks.ps1" `
  -ProjMatch "CP_A4" -GroupPath "01_공통/01_PNIO" -NameRegex ".*" -OutDir "C:\...\out"
```
| 파라미터 | 기본값 | 뜻 |
|---|---|---|
| `-ProjMatch` | `""` | 여러 TIA가 떴을 때 **프로젝트 경로 부분문자열**로 인스턴스 선택. 빈값=첫 인스턴스 |
| `-GroupPath` | `""` | 블록 그룹 경로 필터(정확히 일치 또는 그 하위). 예 `02_제어/03_OP`. 빈값=전체 |
| `-NameRegex` | `.*` | 블록 이름 정규식. 예 `^OP[0-9]+$`, `^P_.*_DB$` |
| `-OutDir` | `…\bsfa-extract-test\blocks_out` | XML 저장 폴더(없으면 생성). **repo 밖에 둘 것**(회사 데이터, public repo 금지) |
| `-IncludeSafety` | (꺼짐) | 켜면 `05_Safety` 블록도 **읽기 전용**으로 추출. 기본은 Safety 전체 skip |

## 동작 (내부 절차)
1. C# 헬퍼 컴파일(`Add-Type`, `-ReferencedAssemblies`=V20 DLL). 리졸버를 **C# 안에서** 등록(두 폴더 `PublicAPI\V20`+`Bin\PublicAPI` 검색). DLL은 `LoadFrom`으로 로드.
2. `TiaPortal.GetProcesses()` -> `ProjMatch`로 인스턴스 선택 -> `.Attach()` -> 첫 프로젝트.
3. `Devices -> DeviceItem` 재귀로 `GetService<SoftwareContainer>()` -> `PlcSoftware` 탐색.
4. `plc.BlockGroup` 재귀 walk. 그룹 경로에 `Safety` 포함 + `-IncludeSafety` 없으면 그 서브트리 통째 skip.
5. `GroupPath`/`NameRegex` 매칭 블록만: **consistent면** `block.Export(fi, ExportOptions.WithDefaults)` -> `<이름>.xml`, **inconsistent면 skip+보고**.
6. 산출 XML 전부 well-formed 파싱 검증. 끝에 `ok / skip / fail` 요약.

## 출력 형식
`Document > SW.Blocks.<FC|FB|OB|GlobalDB|...>` 안에 `AttributeList`(인터페이스/이름/언어) + `ObjectList`(네트워크=`SW.Blocks.CompileUnit`). 각 네트워크의 `FlgNet` = `Parts`(Access=피연산자, Part=명령(Contact 등, `Negated`=b접점), Call=FB호출) + `Wires`(배선). 네트워크 제목은 `MultilingualText`(한글 포함).
상세: 프로젝트 문서 `docs/tia-openness-extraction.md`.

## 안전
- read-only. 실장비 Download 금지, 원본은 사본에서만. `05_Safety` F-블록은 기본 skip(켜도 읽기만).
- 추출된 실데이터(XML)는 **public repo에 커밋하지 말 것** — repo 밖 또는 회사 표준 저장소에 보관.
- 추출/비교는 보조 도구일 뿐, 최종 검증은 항상 **컴파일 + PLCSIM + 엔지니어 검토**.

## 한계 / 다음
- LAD/FBD/DB/OB/FB/SCL 모두 `Export`(XML)로 추출됨. `.scl` 텍스트가 따로 필요하면 SCL 블록에 `GenerateSource`(미구현 옵션).
- 미컴파일 블록 자동 컴파일은 일부러 미포함(안전/단순). 사람이 컴파일 후 재실행.
- UDT/태그테이블/프로젝트텍스트 추출은 향후 확장(같은 attach 경로 재사용).
