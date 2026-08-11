# Codex · Claude Code Research Workflows

**한국어** · [English](README_EN.md)

**Open, practical workflows for AI-assisted humanities research with Codex and Claude Code.**

이 저장소는 인문학·사회과학 연구자가 **Codex와 Claude Code를 역할 분리형으로 활용**할 수 있도록 정리한 공개 실사용 가이드입니다. 단순 프롬프트 모음이 아니라, 연구 자료의 구조화·에이전트 간 인계·학술 한→영 번역의 생성/검증 분업을 재현 가능한 워크플로로 설명합니다.

## What this repository covers

### 1. Research-to-Skill

논문·책·노트·보고서를 장기적으로 축적하면서 source provenance, concept, claim, argument와 locator를 보존하는 연구 메모리 워크플로입니다.

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

한 시점에는 한 writer만 canonical research data를 수정하며, `preflight`, writer lock, `validate`, `HANDOFF.md`를 이용해 Codex와 Claude Code 사이의 작업 연속성을 유지합니다.

### 2. Scholarly Korean → English Translation

학술논문 번역에서는 두 모델에게 같은 원고를 두 번 독립 번역시키는 대신 역할을 비대칭적으로 나눕니다.

```text
Korean manuscript
   ↓
Codex = Translator
   ↓
English draft + fidelity audit + SCHOLARLY_HANDOFF
   ↓
Claude Code = Reviewer / Publication Editor
   ↓
final-en.md + publication-audit.md + review-changes.md
   ↓
Human = final publication decisions
```

핵심은 `생성 → 독립 검증 → 제한적 수정 → 인간 최종 판단`입니다.

## Documentation

### 한국어

- **[통합 사용 매뉴얼](docs/USER_MANUAL_KO.md)** — 설치부터 실전 운영·인계·복구까지 전체 가이드
- **[Research-to-Skill 빠른 시작](docs/RESEARCH_TO_SKILL_QUICKSTART_KO.md)** — 연구 프로젝트를 바로 시작하기 위한 최소 절차
- **[학술 한→영 번역 빠른 시작](docs/SCHOLARLY_KO_EN_QUICKSTART_KO.md)** — Codex Translator → Claude Reviewer 생산 워크플로

### English

- **[English README](README_EN.md)** — international overview of the project and its design principles
- **[Full English User Manual](docs/USER_MANUAL_EN.md)** — installation, daily operation, handoff, validation, recovery, and copy-ready prompts

## Related repositories

이 문서는 다음 공개 소프트웨어를 실제 운용한 경험을 바탕으로 작성되었습니다.

- **Research-to-Skill fork:** `icerain-cmd/book-to-skill`
  - upstream: `virgiliojr94/book-to-skill`
- **Scholarly translation fork:** `icerain-cmd/translate-book`
  - upstream: `deusyu/translate-book`

각 소프트웨어와 원 프로젝트의 저작권·라이선스는 해당 저장소에 따릅니다. 자세한 내용은 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참조하세요.

## Who this is for

- 생성형 AI를 연구 보조자가 아니라 **연구 workflow의 역할 분리된 agent**로 사용하려는 연구자
- 여러 AI agent 사이에서 연구 판단과 미완료 작업을 안전하게 넘기려는 사용자
- 논문 번역에서 의미 충실성과 출판 가능성을 분리해 검증하려는 연구자
- Windows / WSL 공유 드라이브에서 Codex와 Claude Code를 함께 사용하는 사용자

## Core principles

1. **Canonical data before prose views** — 파생 Markdown보다 canonical source/data를 우선합니다.
2. **Single writer** — 공유 연구 상태는 동시에 두 agent가 수정하지 않습니다.
3. **Explicit handoff** — 기억에 기대지 않고 `HANDOFF.md`와 검증 가능한 산출물로 작업을 넘깁니다.
4. **Generation and review are different jobs** — 최초 생성과 독립 검증을 같은 역할로 취급하지 않습니다.
5. **Fidelity is not publication readiness** — 번역 충실성과 출판 준비도를 별도 gate로 평가합니다.
6. **Human decisions remain explicit** — 공식 로마자 표기, 저널 스타일, 원전의 불확실성과 같은 최종 판단은 인간이 담당합니다.

## License

이 저장소에서 새로 작성한 문서(original documentation)는 별도 표기가 없는 한 **Creative Commons Attribution 4.0 International (CC BY 4.0)**로 공개합니다. 자유롭게 공유·수정·번역·교육·연구에 활용할 수 있으며 적절한 출처 표기가 필요합니다.

소프트웨어 코드와 제3자 자료는 이 문서 라이선스의 적용 대상이 아니며 각각의 원 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE)와 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참조하세요.

## Attribution

Maintained by **Lee Yong Wook** (`icerain-cmd`).

This documentation was developed with AI assistance and then organized as an open research workflow guide.

## Disclaimer

이 저장소는 OpenAI 또는 Anthropic의 공식 문서가 아니며 두 회사와 제휴·후원 관계를 의미하지 않습니다. Codex, Claude Code 및 관련 제품의 인터페이스와 기능은 변경될 수 있으므로 실제 사용 시 최신 제품 문서를 함께 확인하세요.
