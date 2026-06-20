---
name: tia-block-extract
description: TIA Openness로 현재 열린(실행 중) TIA Portal 프로젝트의 PLC 블록을 SimaticML XML로 추출(export)한다. 그룹 경로/이름 정규식으로 대상을 고르고, 미컴파일 블록은 자동 컴파일해서 추출 가능하게 만들며, 진짜 에러가 있어 컴파일이 안 되는 블록은 "어디가 어떻게 틀렸는지"를 _extract_errors.txt로 정리한다. 05_Safety는 기본 skip, 저장·다운로드 없음. "블록 추출", "OP 블록 XML로 뽑아줘", "01_PNIO 블록 추출", "블록 데이터 빼줘" 같은 요청에 사용. 이 PC(TIA V20, Openness 동작 확인됨)에서 검증된 project-local 버전.
---

# PLC 블록 추출 (TIA Openness -> SimaticML XML)

실행 중인 TIA Portal 인스턴스에 **attach**해서 PLC 블록을 **SimaticML XML**로 내보낸다.
디스크/장비에는 **read-only** — 프로젝트 저장 안 함, 다운로드 안 함, GUI 창 안 닫음.
(자동 컴파일은 attach된 인스턴스의 **메모리 상태만** 바꾼다 → TIA를 저장 없이 닫으면 원래대로.)

> 이 PC에서 실측 검증됨: `block.Export()` 한 호출이 OB/FB/FC/DB는 물론 SCL 블록까지 모두 정상 XML로 추출. HSP/SCALANCE 우회 불필요(attach로 바로 읽힘).

## 핵심 정책 (미컴파일 처리)
PLC 블록은 편집 후 컴파일하지 않으면 `IsConsistent=False`가 되고, Openness Export는 **일관(컴파일된) 블록만** 내보낸다. 이 스킬은:
1. **컴파일 가능한 건 최대한 자동 컴파일**해서 추출한다(`-AutoCompile` 기본 ON).
2. 컴파일해도 **진짜 에러**가 남는 블록은 추출하지 않고, **에러 위치+내용**을 `OutDir\_extract_errors.txt`에 사람이 보기 쉽게 적는다(사람이 고쳐야 함).
- 배경/사례: `docs/tia-extraction-edge-cases.md` 참조. (대부분의 `IsConsistent=False`는 에러가 아니라 "아직 컴파일 안 함"일 뿐이라, 자동 컴파일하면 그대로 추출된다.)

## 사전 조건
- TIA Portal **V20** 실행 중 + 대상 프로젝트 열림. 계정이 Windows 로컬 그룹 **`Siemens TIA Openness`** 포함.

## 실행
```
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill>\scripts\extract_blocks.ps1" `
  -ProjMatch "CP_A4" -GroupPath "02_제어/03_OP" -NameRegex "^OP[0-9]+$" -OutDir "C:\...\out"
```
| 파라미터 | 기본값 | 뜻 |
|---|---|---|
| `-ProjMatch` | `""` | 여러 TIA가 떴을 때 **프로젝트 경로 부분문자열**로 인스턴스 선택. 빈값=첫 인스턴스 |
| `-GroupPath` | `""` | 블록 그룹 경로 필터(정확 일치 또는 그 하위). 예 `02_제어/03_OP`. 빈값=전체 |
| `-NameRegex` | `.*` | 블록 이름 정규식. 예 `^OP[0-9]+$`, `^P_.*_DB$` |
| `-OutDir` | `…\bsfa-extract-test\blocks_out` | XML 저장 폴더(없으면 생성). **repo 밖에 둘 것**(회사 데이터, public repo 금지) |
| `-IncludeSafety` | (꺼짐) | 켜면 `05_Safety` 블록도 **읽기 전용**으로 추출. 기본은 Safety 전체 skip |
| `-AutoCompile` | `$true` | 미컴파일 블록 자동 컴파일 후 추출. `-AutoCompile:$false`면 그냥 skip |

## 동작 (내부 절차)
1. C# 헬퍼 컴파일(`Add-Type`). 리졸버를 **C# 안에서** 등록(두 폴더 `PublicAPI\V20`+`Bin\PublicAPI`). DLL은 `LoadFrom`.
2. `TiaPortal.GetProcesses()` -> `ProjMatch`로 인스턴스 선택 -> `.Attach()` -> 첫 프로젝트.
3. `Devices -> DeviceItem` 재귀로 `GetService<SoftwareContainer>()` -> `PlcSoftware`.
4. `plc.BlockGroup` 재귀 walk. 그룹 경로에 `Safety` 포함 + `-IncludeSafety` 없으면 그 서브트리 skip.
5. `GroupPath`/`NameRegex` 매칭 블록마다:
   - consistent -> `block.Export(fi, ExportOptions.WithDefaults)` -> `<이름>.xml`
   - inconsistent + AutoCompile -> `GetService<ICompilable>().Compile()` -> 일관되면 export(`CMPL`), 에러 남으면 `_extract_errors.txt`에 위치+내용 기록(`ERR`)
6. 산출 XML 전부 well-formed 파싱 검증. 끝에 `ok / auto-compiled / skip / compile-error / export-fail` 요약.

## 출력
- XML: `Document > SW.Blocks.<FC|FB|OB|GlobalDB|...>` (형식 상세: `docs/tia-openness-extraction.md`).
- 에러 리포트: 컴파일 안 되는 블록이 있으면 `OutDir\_extract_errors.txt` (블록별 에러 위치/설명).

## 안전
- read-only(저장/다운로드 없음). 자동 컴파일은 메모리 상태만 변경 → 저장 안 하면 원복. `05_Safety` 기본 skip.
- 추출 실데이터(XML)는 **public repo에 커밋 금지** — repo 밖/회사 표준 저장소에.
- 최종 검증은 항상 **컴파일 + PLCSIM + 엔지니어 검토**.

## 한계 / 다음
- LAD/FBD/DB/OB/FB/SCL 모두 `Export`(XML). `.scl` 텍스트가 필요하면 SCL 블록에 `GenerateSource`(옵션, 미구현).
- UDT/태그테이블/프로젝트텍스트 추출은 향후 확장(같은 attach 경로 재사용).
