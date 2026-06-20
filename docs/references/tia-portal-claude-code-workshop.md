# TIA Portal + Claude Code 워크숍 요약 (ControlByte Automation)

> 출처: ControlByte Automation YouTube 워크숍 "AI in PLC Programming"
> lilys.ai 요약: https://lilys.ai/digest/10045189/11677994
> 저장일: 2026-06-11

## 핵심 요지

TIA Portal 프로젝트에 AI를 적용하는 방법. Claude Code와 **TIA Portal Openness API**를 연동하면 태그 테이블 자동 입력, SCL 코드 변환, 프로젝트 간 파일 이식 등 반복 작업을 자동화하여 PLC 프로그래밍 워크플로우를 크게 개선할 수 있다.

## 1. Claude Code ↔ TIA Portal 연동의 필요성

- 목적: PLC 프로그래머·자동화 전문가의 일상 업무 개선
- 수동으로 작성된 태그 테이블을 Claude Code에 입력하면 TIA Portal 프로젝트로 자동 전송
- 대화형 인터페이스로 클릭 위주의 반복 작업을 대체
- Claude Code는 SCL, XML, Excel 문서를 다룰 수 있고, 생성된 데이터를 TIA Portal로 푸시

## 2. TIA Portal Openness 설정

### 필수 소프트웨어
- Siemens **TIA Portal V20 이상** + TIA Portal Openness (TIA Portal 패키지에 포함)
- .NET Framework 팩 + Visual Studio 또는 .NET CLI
- Anthropic Claude Code (대규모 작업 시 유료 플랜 권장)

### Windows 환경 설정
- TIA Openness 사용자 그룹 권한 부여 (API가 프로젝트/파일에 접근 가능하도록)
- TIA Portal Openness 활성화 및 작업 권한 확인
- 라이브러리 경로 확인 (`Siemens.Engineering.dll` 등 필수 라이브러리 검증)

### Openness 개요
- 기존 TIA Portal = GUI 작업 / Openness = **API 인터페이스**
- 프로젝트 내 모든 요소를 참조할 수 있는 객체 그래프 제공
- C# 또는 Python 라이브러리 사용 가능 (C#이 기능이 더 많음)
- PLC 블록에 직접 접근: 내보내기, 편집기에서 보기, 삭제 등

## 3. Claude Code 활용 기능 (16가지)

### 코드 생성 및 데이터 관리
- **태그 테이블 자동 입력**: Excel의 태그 200개를 수동 입력 없이 가져오기
- EPLAN 리스트 → 태그 리스트 생성 → TIA Portal 자동 가져오기
- Word 문서 내용 기반으로 전역 DB(Global DB) 자동 생성

### 코드 작성 및 변환
- 일반 영어(자연어) 설명으로 FB(Function Block) 작성
- UDT(사용자 정의 타입) 및 라이브러리를 다른 프로젝트로 가져오기/내보내기
- 블록을 SCL(텍스트 기반 언어) 형식으로 내보내기

### 프로젝트 관리 및 정리
- 블록을 하위 그룹/폴더로 구성
- 프로젝트 정리, 다국어 주석 정리(sanitize)
- **Ladder Logic → SCL 변환**
- 상태 머신(State Machine) 생성 — Claude Code의 강점
- 블록 문서를 Markdown으로 생성
- 두 프로젝트 서명 비교
- 태그 일괄 이름 변경
- FB로부터 DB 인스턴스 생성 (프로젝트 전체 템플릿 구축)

### 버전 관리 및 안전성
- 생성 코드를 GitHub에 커밋하여 버전 관리
- **파괴적 변경 전 드라이런(Dry Run) 보장**: 프로젝트를 덮어쓰기 전에 변경사항 확인 후 적용

## 4. ControlByte TIA Portal Copilot 프레임워크

- Claude Code + Windows 표준 명령줄을 활용하는 프레임워크
- 주요 스킬(Skill):
  - Excel 스킬: Excel 형식으로 태그·전역 DB 가져오기
  - SCL 소스 가져오기: FB, FC, UDT, DB 형식의 SCL 파일 가져오기
  - XML 가져오기/내보내기: TIA Portal의 Automation XML 처리
  - 프로젝트 구성: 블록·UDT를 폴더로 이동
  - 열려 있는 TIA Portal 인스턴스/프로젝트 목록 확인

### 데모 1: 프로젝트 분석
- TIA Portal V20 + Claude Code 실행, 열려 있는 인스턴스 목록 요청
- 로봇 스테이션 프로젝트(robots 01 done template) 구조 분석
- 결과: 로봇 셀 2개와 해당 FB 이름·호출 구조 확인

### 데모 2: Ladder → SCL 변환 및 프로젝트 이식
- FB_robot (Ladder Logic, PackML 표준 상태 머신) 분석
- FB_robot을 XML로 내보내기 → Claude Code가 네트워크·인터페이스·로직 요약
- Ladder Logic을 SCL로 변환하여 지정 폴더에 저장
- 새 프로젝트(sample project W1)로 Robotic Station 파일 일괄 이식
  - OB, FB, FC + PLC 데이터 타입(PackML, 로봇 타입)까지 함께 이전
  - 가져오기 후 컴파일로 데이터 타입·태그·변수 정의 검증
- 결과: 언어 변환 + 라이브러리 전체 이전 성공

## 5. 워크숍 요약

- TIA Portal ↔ Openness ↔ Claude Code 연결 성공
- 프로젝트 데이터 읽기, Ladder FB 분석, SCL 변환, 프레임워크 이식까지 시연
- 추가 정보: Control Byte Automation YouTube 채널, controlbyte.tech

## BSFA 프로젝트에 주는 시사점

- TIA Portal Openness가 연동의 핵심 — V20 이상 + Openness 권한 설정이 선행 조건
- Excel/EPLAN 태그 자동 입력, Ladder→SCL 변환, 프로젝트 분석이 즉시 효과를 볼 수 있는 후보 업무
- 파괴적 변경 전 드라이런·Git 버전 관리 등 안전장치를 처음부터 함께 도입할 것
