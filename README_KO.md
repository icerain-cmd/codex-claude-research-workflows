# Codex · Claude Code Research Workflows

**한국어** · [English](README.md)

**Codex와 Claude Code를 활용한 재현 가능한 인문·사회과학 연구를 위한 배포·문서 허브입니다.**

> **이 저장소의 성격:** 이제 이 저장소에는 설치·진단 스크립트가 포함되어 있지만, 두 workflow의 실제 엔진 코드는 각각 `icerain-cmd/book-to-skill`과 `icerain-cmd/translate-book`에서 유지합니다. 코드를 중복 복제하지 않으면서도 사용자가 한 저장소에서 설치·검증·매뉴얼·예제를 모두 찾을 수 있도록 만든 통합 진입점입니다.

## 빠른 시작

### Windows PowerShell

```powershell
git clone https://github.com/icerain-cmd/codex-claude-research-workflows.git
cd codex-claude-research-workflows
powershell -ExecutionPolicy Bypass -File .\install.ps1
powershell -ExecutionPolicy Bypass -File .\doctor.ps1
```

공유 드라이브 등 원하는 위치에 설치하려면:

```powershell
.\install.ps1 -InstallRoot "R:\tools\codex-claude-research-tools"
.\doctor.ps1 -InstallRoot "R:\tools\codex-claude-research-tools"
```

### WSL / Linux / macOS

```bash
git clone https://github.com/icerain-cmd/codex-claude-research-workflows.git
cd codex-claude-research-workflows
bash install.sh
bash doctor.sh
```

공유 드라이브 예:

```bash
bash install.sh --root /mnt/r/tools/codex-claude-research-tools
bash doctor.sh --root /mnt/r/tools/codex-claude-research-tools
```

설치 스크립트는 다음 작업을 수행합니다.

1. `icerain-cmd/book-to-skill`을 clone하거나 fast-forward update합니다.
2. `icerain-cmd/translate-book`을 clone하거나 fast-forward update합니다.
3. `research-to-skill` Python CLI와 일반적인 PDF/DOCX 의존성을 설치합니다.
4. 번역 workflow에 필요한 `pypandoc`, `beautifulsoup4`를 설치합니다.
5. 유지보수 중인 `translate-book` checkout을 Codex와 Claude Code의 skill 경로에 연결합니다.
6. Pandoc, Calibre `ebook-convert` 등 외부 도구가 없으면 경고합니다.

`doctor`는 저장소, Python 버전, `research-to-skill`, 번역 Python 모듈, Pandoc/Calibre, Codex/Claude 명령, skill 경로를 검사합니다. 핵심 설치가 깨졌으면 FAIL, 선택적 도구가 없으면 WARN으로 구분합니다.

환경의 일부만 설치하려면 `--skip-skill-links` / `-SkipSkillLinks`, `--skip-python-deps` / `-SkipPythonDeps` 옵션을 사용할 수 있습니다.

## 저장소 구조

```text
codex-claude-research-workflows/
├── install.ps1              # Windows 설치 / 업데이트
├── install.sh               # WSL/Linux/macOS 설치 / 업데이트
├── doctor.ps1               # Windows 환경 진단
├── doctor.sh                # Unix 환경 진단
├── components.lock.json     # 문서화된 구성요소 기준 커밋
├── examples/                # 복사해서 쓸 수 있는 운영 예제
├── docs/                    # 전체 매뉴얼과 빠른 시작 문서
└── .github/workflows/       # 배포 스크립트 smoke test
```

`components.lock.json`에는 이 배포판을 문서화할 때 검증한 두 구성요소의 기준 커밋이 기록됩니다. 설치 스크립트는 이후 수정사항도 받을 수 있도록 유지보수 중인 `master` / `main`을 따라가며, 정확한 재현 기준이 필요할 때 lock 파일의 커밋을 참조하면 됩니다.

## 이 저장소가 다루는 두 workflow

이 저장소는 인문학·사회과학 연구자가 **Codex와 Claude Code를 서로 교체 가능한 챗봇이 아니라 역할이 분리된 연구 agent로 운용**할 수 있도록 만든 공개 실사용 workflow입니다.

1. **Research-to-Skill** — 논문·책·노트·보고서를 장기적으로 축적하면서 source provenance, concept, claim, argument와 locator를 보존하는 연구 메모리 workflow.
2. **Scholarly Korean → English Translation** — Codex가 번역을 생성하고 Claude Code가 처음부터 재번역하지 않은 채 독립 검증·출판 편집을 수행하는 비대칭 학술 한→영 workflow.

공통 설계는 다음과 같습니다.

```text
생성 / 구조화 작업
      ↓
독립 검증
      ↓
제한적 수정
      ↓
명시적 인간 판단
```

## 1. Research-to-Skill

기본 운영 원칙은 다음과 같습니다.

```text
Agent A writes
   ↓
validate
   ↓
HANDOFF.md
   ↓
Agent B verifies / continues
```

한 시점에는 한 writer만 canonical research data를 수정합니다. Codex와 Claude Code가 같은 프로젝트를 사용할 수 있지만 `preflight`, writer lock, `validate`, Git 상태, `HANDOFF.md`를 통해 작업을 넘기며 대화 기억에 의존하지 않습니다.

주요 용도:

- 논문·책에서 장기 연구 메모리 구축
- 저자 자신의 주장과 외부 문헌의 주장 구분
- 근거 locator와 source provenance 보존
- 여러 자료에 걸친 개념 진화 추적
- Codex ↔ Claude Code 미완료 작업 인계
- JSON / Markdown / agent skill 형태의 구조화된 연구 산출물 생성

## 2. Scholarly Korean → English Translation

학술논문 번역에서는 두 모델에게 같은 원고를 두 번 독립 번역시키는 것을 기본값으로 삼지 않습니다.

```text
한국어 원문
   ↓
Codex = Translator
   ↓
영문 draft + fidelity audit + SCHOLARLY_HANDOFF
   ↓
Claude Code = Reviewer / Publication Editor
   ↓
final-en.md + publication-audit.md + review-changes.md
   ↓
Human = 최종 출판 판단
```

Codex는 전체 번역 생성, chunk 처리, terminology/theory contract, citation integrity, translation fidelity 검사를 담당합니다. Claude Code는 기존 Codex draft를 한국어 원문과 대조하고 정당화되는 국소 수정만 수행합니다.

주요 검토 항목:

- semantic drift
- concept-family inconsistency
- epistemic strength
- negation / condition / modality
- academic English
- citation localization
- bibliography normalization
- publication readiness

저자명 공식 로마자 표기, 목표 저널 스타일, 원전 자체의 불확실성은 인간의 최종 판단으로 남깁니다.

## 문서와 예제

### 한국어

- **[통합 사용 매뉴얼](docs/USER_MANUAL_KO.md)** — 설치부터 실전 운영·인계·복구까지 전체 가이드
- **[Research-to-Skill 빠른 시작](docs/RESEARCH_TO_SKILL_QUICKSTART_KO.md)**
- **[학술 한→영 번역 빠른 시작](docs/SCHOLARLY_KO_EN_QUICKSTART_KO.md)**
- **[복사해서 쓰는 예제](examples/README.md)** — 두 workflow의 최소 명령과 handoff 예제

### English

- **[English README](README.md)**
- **[Full English User Manual](docs/USER_MANUAL_EN.md)**

## 구성요소 저장소

실제 workflow 엔진은 upstream 이력·테스트·라이선스를 보존하기 위해 별도 저장소에서 유지합니다.

### Research-to-Skill

- maintained fork: `icerain-cmd/book-to-skill`
- upstream: `virgiliojr94/book-to-skill`
- software license: MIT

### Scholarly translation

- maintained fork: `icerain-cmd/translate-book`
- upstream: `deusyu/translate-book`
- software license: MIT

자세한 출처와 라이선스 경계는 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참조하세요.

## Core principles

1. **Canonical data before prose views** — 파생 Markdown보다 canonical source/data를 우선합니다.
2. **Single writer** — 공유 연구 상태는 동시에 두 agent가 수정하지 않습니다.
3. **Explicit handoff** — 기억에 기대지 않고 `HANDOFF.md`, hash, 검증 결과, 작업 파일 참조로 작업을 넘깁니다.
4. **Generation and review are different jobs** — 최초 생성과 독립 검증을 같은 역할로 취급하지 않습니다.
5. **Fidelity is not publication readiness** — 번역 충실성과 출판 준비도를 별도 gate로 평가합니다.
6. **Human decisions remain explicit** — 공식 로마자 표기, 저널 스타일, 원전의 불확실성과 같은 최종 판단은 인간이 담당합니다.

## 대상 사용자

- 여러 coding agent를 연구에 사용하는 인문·사회과학 연구자
- 추적 가능한 AI-assisted research workflow가 필요한 디지털인문학 프로젝트
- 일회성 채팅이 아니라 지속적인 claim/concept memory가 필요한 연구자
- 한국어 학술논문을 영어로 번역하는 연구자
- Windows / WSL / 공유 드라이브에서 Codex와 Claude Code를 함께 사용하는 사용자
- 재현 가능한 인간–AI 연구 실천을 교육하는 교수자

## 이 저장소가 아닌 것

이 저장소는 OpenAI 또는 Anthropic의 공식 저장소가 아니며 두 회사와의 제휴·후원 관계를 의미하지 않습니다. 제품 인터페이스와 기능은 변경될 수 있으므로 실제 사용 시 최신 공식 문서를 함께 확인해야 합니다.

또한 이 workflow는 학술적 판단을 대체하지 않습니다. AI 보조 작업을 더 추적 가능하고 검증 가능하게 만드는 것이 목적입니다.

## 라이선스

이 저장소의 원본 문서는 별도 표기가 없는 한 **Creative Commons Attribution 4.0 International (CC BY 4.0)**로 공개합니다. [LICENSE](LICENSE)를 참조하세요.

이 저장소에서 새로 작성한 설치·진단 등 배포 코드는 **MIT License**로 공개합니다. [LICENSE-CODE](LICENSE-CODE)를 참조하세요.

두 구성요소 저장소와 제3자 자료의 라이선스는 각각 그대로 유지되며 이 허브가 재라이선스하지 않습니다.

## Attribution

Maintained by **Lee Yong Wook** (`icerain-cmd`).

This documentation and lightweight distribution layer were developed with AI assistance and organized as an open, reproducible research workflow guide.
