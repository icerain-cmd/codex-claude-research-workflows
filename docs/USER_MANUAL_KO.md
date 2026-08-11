# Codex · Claude Code 통합 사용 매뉴얼
## Research-to-Skill + 학술 한국어→영어 번역

> 기준 소프트웨어
> - Research-to-Skill: `icerain-cmd/book-to-skill` (`master`)
> - Scholarly KO→EN Translation: `icerain-cmd/translate-book` (`main`)
> - 문서 기준선: 2026-08-11
>
> 이 문서는 **실사용자용 운영 매뉴얼**이다. 개발 내부 구조보다 “어느 에이전트에게 무엇을 맡기고, 어떤 명령으로 검증하고, 어떻게 다음 에이전트에게 넘길 것인가”에 초점을 맞춘다.

---

# 1. 전체 구조

두 workflow는 공통적으로 **생성/수정과 검증을 분리하고, 상태를 명시적으로 인계**한다.

## Research-to-Skill

```text
Codex 또는 Claude Code
   ↓
canonical research data 작업
   ↓
validate
   ↓
HANDOFF.md
   ↓
다음 에이전트
```

핵심은 **single writer**다. 한 시점에 한 에이전트만 canonical research data를 수정한다.

## 학술 한국어→영어 번역

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

일반 production에서는 같은 논문을 Codex와 Claude Code에 각각 처음부터 번역시키지 않는다. Claude Code의 추가 가치는 **두 번째 번역**보다 **첫 번역의 국소적 문제를 독립 검증하고 제한적으로 수정하는 것**에 둔다.

---

# 2. 권장 저장 구조

공유 드라이브를 사용하는 예:

```text
R:\
├── tools\
│   ├── book-to-skill\
│   └── translate-book\
├── research\
│   └── project-a\
└── translation\
    └── paper-a\
```

WSL에서는 같은 위치가 보통:

```text
/mnt/r/tools/book-to-skill
/mnt/r/tools/translate-book
/mnt/r/research/project-a
/mnt/r/translation/paper-a
```

공유 권장:

- canonical repositories
- research projects
- source documents
- semantic artifacts
- `HANDOFF.md`
- translation source/draft/audit/handoff/final files

각 PC 로컬 권장:

- `.venv`
- `__pycache__`
- pip cache
- `node_modules`
- OS-specific runtime/cache files
- 대규모 테스트 출력

---

# Part I. Research-to-Skill

# 3. 설치

리포지토리:

```text
https://github.com/icerain-cmd/book-to-skill.git
```

## Windows PowerShell

```powershell
git clone https://github.com/icerain-cmd/book-to-skill.git R:\tools\book-to-skill
cd R:\tools\book-to-skill
py -m pip install -e .
research-to-skill --help
```

## WSL / Linux

```bash
git clone https://github.com/icerain-cmd/book-to-skill.git /mnt/r/tools/book-to-skill
cd /mnt/r/tools/book-to-skill
python3 -m pip install -e .
research-to-skill --help
```

이미 설치한 경우:

```bash
git -C <BOOK_TO_SKILL_REPO> pull --ff-only
python -m pip install -e <BOOK_TO_SKILL_REPO>
```

---

# 4. 에이전트/PC identity

선택적으로 각 PC의 로컬 사용자 홈에 설정한다.

```text
~/.config/research-to-skill/config.json
```

Codex PC 예:

```json
{
  "agent": "codex",
  "machine": "PC1"
}
```

Claude Code PC 예:

```json
{
  "agent": "claude-code",
  "machine": "PC2"
}
```

공유 프로젝트 안에 두지 않는다. 설정이 없으면 agent는 `local`, machine은 hostname을 사용한다.

---

# 5. 프로젝트 생성

```bash
research-to-skill init "My Research" --dir ./my-research
```

공유 드라이브:

```bash
research-to-skill init "My Research" --dir R:/research/my-research
```

생성 직후:

```bash
research-to-skill preflight --project R:/research/my-research
research-to-skill status --project R:/research/my-research
```

---

# 6. 주요 명령

```text
research-to-skill init NAME [--dir PATH]
research-to-skill add INPUT [INPUT ...] [--project PATH]
research-to-skill remove SOURCE_ID [--project PATH] [--cascade]
research-to-skill status [--project PATH]
research-to-skill list [--project PATH]
research-to-skill inspect source|concept|claim ID [--project PATH]
research-to-skill compile [--project PATH]
research-to-skill compile [--project PATH] --complete [SOURCE_ID ...]
research-to-skill validate [--project PATH]
research-to-skill sync-artifacts [--project PATH]
research-to-skill export --format skill|json|markdown [--output PATH] [--project PATH]
```

협업에서 특히 중요한 명령:

```text
preflight
lock status
validate
handoff
```

---

# 7. 모든 세션의 시작 루틴

Codex든 Claude Code든 canonical project를 수정하기 전:

```bash
git status
research-to-skill preflight --project <PROJECT>
research-to-skill lock status --project <PROJECT>
git log -1 --oneline
```

`HANDOFF.md`가 있으면 가장 먼저 읽는다.

## Codex 시작 프롬프트

```text
이 Research-to-Skill 프로젝트 작업을 시작해.
먼저 HANDOFF.md, git status, preflight, lock status, 최신 git log를 확인해.
canonical research.json을 단일 진실원천으로 취급하고 기존 claim·concept·graph 의미를 임의로 변경하지 마.
```

## Claude Code 시작 프롬프트

```text
이 Research-to-Skill 프로젝트를 이어서 작업해.
먼저 HANDOFF.md와 현재 git 상태를 읽고 preflight와 lock status를 실행해.
이전 에이전트의 완료 사항, 미완료 사항, 수정 금지 사항을 보존해.
canonical research.json과 source evidence를 우선하고 파생 Markdown을 진실원천으로 간주하지 마.
```

---

# 8. 논문·책·노트 ingest

파일 하나:

```bash
research-to-skill add paper.pdf --project <PROJECT>
```

폴더/다중 입력:

```bash
research-to-skill add ./papers ./notes --project <PROJECT>
```

구조가 복잡한 문서:

```bash
research-to-skill add paper.pdf --project <PROJECT> --mode technical
```

확인:

```bash
research-to-skill status --project <PROJECT>
research-to-skill list --project <PROJECT>
```

동일 콘텐츠는 SHA-256으로 식별하므로 파일명이 달라도 중복 ingest를 피할 수 있다.

---

# 9. compile의 의미

```bash
research-to-skill compile --project <PROJECT>
```

이 명령은 LLM을 직접 호출하지 않는다. **`compile-plan.json`**을 만든다.

에이전트가 해야 할 semantic 작업:

1. `compile-plan.json`에 포함된 source만 읽기
2. 기존 concept / claim / argument / paper 대조
3. 중복과 충돌 확인
4. author / external / mixed provenance 보존
5. locator와 source evidence 확인
6. semantic result를 canonical data에 병합
7. `validate`
8. 성공하면 `compile --complete`

권장 프롬프트:

```text
compile-plan.json에 포함된 source만 의미 구조화해.
새 concept/claim을 기존 것과 먼저 대조하고 중복을 만들지 마.
author / external / mixed provenance를 근거 없이 변경하지 마.
각 claim의 locator와 source evidence를 확인해.
작업 후 validate를 통과시킨 뒤에만 compile --complete를 실행해.
```

완료:

```bash
research-to-skill validate --project <PROJECT>
research-to-skill compile --project <PROJECT> --complete
```

특정 source만:

```bash
research-to-skill compile --project <PROJECT> --complete source-001 source-002
```

---

# 10. 조회와 증거 확인

```bash
research-to-skill list --project <PROJECT>
research-to-skill inspect source source-001 --project <PROJECT>
research-to-skill inspect concept <CONCEPT_ID> --project <PROJECT>
research-to-skill inspect claim claim-001 --project <PROJECT>
```

권장 검색 깊이:

```text
concepts → claims → arguments → papers → source text
```

source text는 evidence/locator/conflict resolution이 필요할 때 내려간다.

---

# 11. canonical data와 derived artifacts

원칙:

```text
research.json → derived artifacts
```

concept Markdown, claim artifacts, `topic-index.md`가 어긋났으면 각각 수동으로 고치는 대신:

```bash
research-to-skill sync-artifacts --project <PROJECT>
research-to-skill validate --project <PROJECT>
```

파생 문서에서 canonical data로 임의 역전파하지 않는다.

---

# 12. Writer Lock

자동 lock 대상:

- `add`
- `remove`
- `compile`
- `compile --complete`

상태:

```bash
research-to-skill lock status --project <PROJECT>
```

수동 획득/해제 예:

```bash
research-to-skill lock acquire --project <PROJECT> --owner codex --operation semantic-write
research-to-skill lock release --project <PROJECT> --owner codex
```

stale lock을 발견하면 다른 PC/agent가 실제로 작업 중인지 먼저 확인한다. writer가 없다는 것이 확실할 때만:

```bash
research-to-skill lock break --project <PROJECT> --force
```

expired lock은 자동 제거되지 않는다.

---

# 13. source 삭제

```bash
research-to-skill remove source-001 --project <PROJECT>
```

의존 artifact가 있으면 삭제가 거부된다.

의존 항목까지 제거:

```bash
research-to-skill remove source-001 --project <PROJECT> --cascade
```

`--cascade` 전에 backup 또는 Git 복구 지점을 만든다.

```bash
research-to-skill export --format json --output backup.json --project <PROJECT>
```

---

# 14. 종료 루틴과 HANDOFF

```bash
research-to-skill validate --project <PROJECT>
research-to-skill status --project <PROJECT>
research-to-skill lock status --project <PROJECT>
git diff
git status
research-to-skill handoff --project <PROJECT>
```

생성:

```text
<PROJECT>/HANDOFF.md
```

HANDOFF에는 적어도 다음 정보가 다음 에이전트에게 전달되어야 한다.

- 완료한 작업
- 미완료 작업
- 다음 작업
- 변경된 파일/대상
- 검증 상태
- 되돌리면 안 되는 결정

## Codex 종료 프롬프트

```text
이 세션을 종료해.
validate, status, lock status를 확인하고 git diff를 검토해.
완료한 작업, 남은 작업, 다음 작업, 되돌리면 안 되는 결정이 다음 에이전트에게 전달되도록 HANDOFF.md를 생성해.
```

## Claude Code 종료 프롬프트

```text
작업 종료 전에 validate를 통과시켜.
canonical data와 derived artifacts의 정합성을 확인하고 lock이 해제되었는지 확인해.
다음 에이전트가 바로 이어갈 수 있도록 HANDOFF.md를 갱신해.
```

---

# 15. Research-to-Skill 실전 레시피

새 논문 한 편을 Codex가 ingest하고 Claude Code가 검증하는 경우:

## Codex

```bash
research-to-skill preflight --project <PROJECT>
research-to-skill add <PAPER.pdf> --project <PROJECT>
research-to-skill compile --project <PROJECT>
```

```text
compile-plan을 수행해서 새 source의 concept/claim/argument를 기존 연구 메모리와 통합해.
provenance와 locator를 보존하고 validate 후 compile --complete까지 수행해.
마지막에 HANDOFF.md를 생성해.
```

## Claude Code

```bash
research-to-skill preflight --project <PROJECT>
research-to-skill validate --project <PROJECT>
```

```text
HANDOFF.md를 읽고 직전 Codex 작업을 독립 검증해.
특히 새 claim의 source locator, author/external 구분, concept membership, 기존 개념과의 중복을 점검해.
오류가 있을 때만 제한적으로 수정하고 다시 validate해.
```

모든 source를 반드시 두 모델이 검증할 필요는 없다. 핵심 개념 변경, provenance 충돌, 중요한 evidence 수정처럼 **오류 비용이 큰 작업에서 두 번째 검증자**를 붙이는 것이 효율적이다.

---

# 16. Export

skill ZIP:

```bash
research-to-skill export --format skill --output <PATH> --project <PROJECT>
```

canonical JSON:

```bash
research-to-skill export --format json --output research-export.json --project <PROJECT>
```

portable Markdown:

```bash
research-to-skill export --format markdown --output research-index.md --project <PROJECT>
```

---

# Part II. 학술 한국어→영어 번역

# 17. Skill 설치

리포지토리:

```text
https://github.com/icerain-cmd/translate-book.git
```

## Codex

```bash
npx skills add icerain-cmd/translate-book -a codex -g
```

수동 설치:

```bash
mkdir -p ~/.agents/skills
git clone https://github.com/icerain-cmd/translate-book.git ~/.agents/skills/translate-book
```

## Claude Code

```bash
npx skills add icerain-cmd/translate-book -a claude-code -g
```

수동 설치:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/icerain-cmd/translate-book.git ~/.claude/skills/translate-book
```

주요 외부 도구:

```text
Python 3
Pandoc
Calibre / ebook-convert
pypandoc
beautifulsoup4 (권장)
```

---

# 18. 일반 번역과 scholarly KO→EN 구분

일반 책 번역 예:

```text
/translate-book translate book.pdf to Korean
```

학술 한국어→영어는 요청에 명시한다.

```text
학술 한영 번역
scholarly Korean-to-English
academic Korean-to-English
논문 영어 번역
```

route 확인:

```bash
python scripts/scholarly_dispatch.py --source-lang ko --target-lang en --mode scholarly --request "학술논문 영어 번역"
```

정상:

```text
scholarly-ko-en
```

---

# 19. 학술 모드의 검증 축

일반 번역 위에 다음 integrity/theory-preservation 검사를 추가한다.

```text
citation_integrity
locked_terminology
epistemic_strength
semantic_fidelity
concept_preservation
claim_preservation
negation_preservation
condition_preservation
relation_preservation
```

학술 번역에서 “더 자연스러운 영어”는 이 축을 훼손할 권한이 아니다.

---

# 20. 계약 파일

가능하면 다음을 준비한다.

```text
terminology.json
author_concepts.json
claims.json
```

## terminology.json

- `LOCKED`: 무단 변경 금지
- `PREFERRED`: 특별한 이유가 없으면 유지
- `FLEXIBLE`: 문맥상 조정 가능

자동 추출 용어를 agent가 임의로 LOCKED로 승격하지 않는다.

## author_concepts.json

저자 고유 개념과 정의, 금지되는 함의를 기록한다.

## claims.json

핵심 주장의 다음 요소를 보존한다.

- modality
- polarity
- conditions
- exceptions
- forbidden reformulations

---

# 21. Codex = Translator

Codex는 최초 완전 영문 draft를 만드는 주 에이전트다.

권장 프롬프트:

```text
이 한국어 학술논문을 영어로 번역해.
반드시 scholarly Korean-to-English 모드로 작업해.
너의 역할은 Codex Translator다.

원칙:
1. 원문의 논증 강도, 부정, 조건, 예외, 양태를 보존한다.
2. LOCKED terminology를 임의로 바꾸지 않는다.
3. author_concepts와 claims 계약이 있으면 최우선 적용한다.
4. citation을 보호하고 정확히 복원한다.
5. chunk별 번역 후 epistemic/semantic/theory fidelity를 검사한다.
6. 실패 chunk만 제한적으로 재번역한다.
7. 전체 번역 후 global consistency와 translation fidelity audit를 수행한다.
8. 완성된 Codex draft는 immutable translator artifact로 취급한다.
9. 마지막에 SCHOLARLY_HANDOFF.json과 HANDOFF.md를 만들어 Claude Code Reviewer에게 넘긴다.
10. Claude Code가 두 번째 독립 번역을 하도록 지시하지 않는다.
```

---

# 22. Scholarly preflight

정규화된 한국어 Markdown 원문:

```bash
python scripts/scholarly_preflight.py <SOURCE.md> --out <TEMP>/scholarly-preflight.json
```

preflight는 source language, heading 구조, citation inventory, QA axes를 정리한다.

---

# 23. Codex → Claude SCHOLARLY_HANDOFF

Codex draft와 translation audit가 완성되면:

```bash
python scripts/scholarly_handoff.py create \
  --source "<SOURCE.md>" \
  --translation "<DRAFT_EN.md>" \
  --output "<TEMP>/SCHOLARLY_HANDOFF.json" \
  --temp-dir "<TEMP>" \
  --translation-audit "<TEMP>/translation-audit.md" \
  --terminology "<TEMP>/terminology.json" \
  --concepts "<TEMP>/author_concepts.json" \
  --claims "<TEMP>/claims.json" \
  --fresh-translation
```

존재하지 않는 optional contract 파일의 flag는 생략한다.

실제 provenance를 정확하게 기록한다.

```text
--translated-chunk chunk0001
--retranslated-chunk chunk0017
--reused-chunk chunk0004
```

생성:

```text
SCHOLARLY_HANDOFF.json
HANDOFF.md
```

즉시 검증:

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

정상 production에서는 `--no-file-check`를 기본 우회로 사용하지 않는다.

---

# 24. Path portability

schema v2에서 canonical artifact identity는:

```text
relative_path + sha256
```

OS별 absolute path:

```text
R:\...
/mnt/r/...
```

는 locator다.

따라서 WSL에서 Codex가 만든 handoff를 native Windows의 Claude Code가 읽더라도 **같은 shared project tree**라면 SHA 검증이 통과해야 한다.

hash mismatch가 나면:

하지 않는다:

```text
JSON hash 수동 수정
--no-file-check로 문제 숨기기
```

대신:

1. source/draft 파일 변경 여부 확인
2. `R:/`와 `/mnt/r/`가 같은 project tree인지 확인
3. 잘못된 파일이면 복원
4. translator artifact가 정당하게 변경됐다면 새 handoff 생성

---

# 25. Claude Code = Reviewer / Publication Editor

Claude Code는 번역을 처음부터 다시 하지 않는다.

가장 먼저:

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

실패하면 review를 시작하지 않는다.

읽을 대상:

```text
한국어 원문
Codex draft
translation-audit.md
terminology.json
author_concepts.json
claims.json
SCHOLARLY_HANDOFF.json
HANDOFF.md
```

권장 프롬프트:

```text
이 번역의 Reviewer / Publication Editor 역할을 수행해.

먼저 SCHOLARLY_HANDOFF.json을 정상 file check로 validate해.
검증이 실패하면 번역문을 수정하지 말고 원인을 보고해.

중요:
- 한국어 원문을 처음부터 독립 재번역하지 마.
- Codex draft를 기준으로 원문과 대조해.
- Codex translator artifact 자체를 덮어쓰지 마.
- LOCKED terminology를 임의 변경하지 마.
- claim strength, 부정, 조건, modality, 이론적 관계를 강화하거나 약화하지 마.

검토 항목:
1. 의미 오류
2. 미세 concept drift
3. epistemic strength
4. terminology-family consistency
5. negation / condition / modality
6. academic English
7. citation localization
8. bibliography normalization
9. publication readiness

필요한 부분만 국소 수정해.
모든 substantive 수정은 review-changes.md에 BEFORE / AFTER / reason / change type / meaning changed 여부를 기록해.

최종 출력:
- final-en.md
- publication-audit.md
- review-changes.md

공식 로마자 저자명, 목표 학술지 citation style, 원전 자체의 불확실성처럼 인간 판단이 필요한 문제는 자의적으로 결정하지 말고 open item으로 남겨.
```

---

# 26. Reviewer 수정 범위

허용:

```text
semantic correction
academic-English editing
terminology consistency
citation localization
bibliography normalization
front-matter cleanup
```

금지:

```text
원고 전체 재번역
한국어 source 수정
Codex draft 원본 덮어쓰기
LOCKED 용어 무단 변경
이론 주장 강화/약화
부정 제거
조건 제거
modality 임의 변경
저자 고유 구분의 임의 통합
```

---

# 27. Reviewer 출력

```text
final-en.md
publication-audit.md
review-changes.md
```

## final-en.md

검토를 마친 출판 후보 영문 원고.

## publication-audit.md

최소 점검:

- 남은 한국어
- citation localization/spacing
- bibliography normalization
- duplicate abstracts/front matter
- terminology-family drift
- academic-English fluency
- editorial change 후 source/claim fidelity
- 인간 판단이 필요한 open items

## review-changes.md

substantive 수정마다:

```text
location
BEFORE
AFTER
reason
change type
meaning changed: yes/no
```

---

# 28. Translation Fidelity와 Publication Readiness 분리

`translation-audit.md`의 질문:

```text
한국어 원문의 논증이 영어 번역에서 보존되었는가?
```

`publication-audit.md`의 질문:

```text
이 영문 원고가 실제 목표 출판 환경에 제출 가능한가?
```

따라서 다음 상태는 정상이다.

```text
translation fidelity = PASS
publication readiness = NOT READY
```

예:

- 공식 저자명 로마자 표기 미확정
- target journal citation style 미지정
- 원문 자체의 모순/불확실성

이는 곧바로 번역 실패를 뜻하지 않는다.

---

# 29. Reviewer 최종 Gate

```bash
python scripts/reviewer_gate.py <TEMP>/SCHOLARLY_HANDOFF.json \
  --final-en <TEMP>/final-en.md \
  --publication-audit <TEMP>/publication-audit.md \
  --review-changes <TEMP>/review-changes.md
```

`valid: true`가 나와야 Reviewer 단계가 완료된다.

---

# 30. 실제 논문 번역 최소 레시피

## STEP A — Codex

```text
이 프로젝트의 한국어 논문을 scholarly Korean-to-English 모드로 번역해.
너는 Translator다.
9축 fidelity 검증까지 마치고 draft-en.md와 translation-audit.md를 만든 뒤,
SCHOLARLY_HANDOFF.json과 HANDOFF.md를 생성하고 정상 file-check validation까지 수행해.
Claude용 최종본을 만들지 말고 여기서 handoff해.
```

Codex 완료 조건:

```text
한국어 source 보존
Codex draft 생성
translation fidelity audit
SCHOLARLY_HANDOFF.json
HANDOFF.md
handoff validate = true
```

## STEP B — Claude Code

```text
SCHOLARLY_HANDOFF.json을 읽어.
너는 Translator가 아니라 Reviewer / Publication Editor다.
먼저 정상 file check로 handoff를 validate하고,
Codex draft를 한국어 원문 및 terminology/concept/claim 계약과 대조해.
전체 재번역은 금지한다.
필요한 국소 수정만 하고 final-en.md, publication-audit.md, review-changes.md를 생성한 뒤 reviewer_gate까지 통과시켜.
```

Claude 완료 조건:

```text
final-en.md
publication-audit.md
review-changes.md
reviewer_gate valid = true
```

## STEP C — Human

최종 확인:

- 공식 영문 저자명
- 소속명
- target journal style
- bibliography style
- 고유 개념 최종 표기
- open items

---

# 31. 일반 translate-book 산출물

일반 책 번역 workflow는 보통 `{book_name}_temp/`에 다음을 만든다.

```text
output.md
book.html
book.docx
book.epub
book.pdf
```

주요 중간 산출물:

```text
input.md
chunk0001.md ...
output_chunk0001.md ...
manifest.json
source_fingerprint.json
glossary.json
run_state.json
```

중단 후 재실행하면 유효한 chunk를 재사용하며 resume할 수 있다.

---

# 32. 번역 오류 대응

## `Calibre ebook-convert not found`

Calibre 설치와 PATH를 확인한다.

## `Manifest validation failed`

source chunk가 변했을 가능성이 높다. `convert.py`를 다시 실행한다.

## `was created from different source bytes`

기존 temp dir가 다른 source bytes에 속한다. 기존 temp dir를 제거하거나 새 `--temp-root`를 사용한다.

## Blank / Empty output

해당 chunk를 재번역한다.

## Incomplete translation

같은 skill을 다시 실행해 resume한다.

## Scholarly handoff hash mismatch

source/draft 변경, 경로 매핑, shared tree를 확인하고 정당한 변경이면 handoff를 새로 만든다. hash 수동 수정으로 통과시키지 않는다.

---

# 33. 역할 선택 표

| 작업 | Codex | Claude Code | Human |
|---|---:|---:|---:|
| 대량 source ingest | ◎ | ○ | - |
| compile plan 의미 작업 | ◎ | ◎ | - |
| provenance/locator 검증 | ○ | ◎ | 필요시 |
| research handoff | ◎ | ◎ | - |
| 한국어 논문 최초 영문 번역 | **◎ 기본** | △ A/B 실험 | - |
| 번역 chunk 대량 처리 | **◎** | △ | - |
| 원문-영문 미세 대조 | ○ | **◎** | 필요시 |
| concept-family drift | ○ | **◎** | 필요시 |
| epistemic strength 검토 | ◎ | **◎** | 중요 쟁점 |
| academic English polish | ○ | **◎** | - |
| 공식 로마자 저자명 | - | open item | **◎** |
| target journal style | - | open item | **◎** |

---

# 34. 하지 말아야 할 운영 방식

## Research-to-Skill

- Codex와 Claude Code가 동시에 canonical project에 write
- stale lock을 확인 없이 강제 삭제
- `research.json`보다 파생 Markdown을 우선
- source evidence 없이 claim origin 변경
- `validate` 실패 상태에서 `compile --complete`
- 의존관계 확인 없이 `--cascade`

## 학술 번역

- 매 논문마다 Codex/Claude 독립 번역 두 번 수행
- Claude Reviewer가 Codex draft를 폐기하고 전체 재번역
- LOCKED terminology 무단 변경
- 자연스러운 영어를 이유로 claim strength 변경
- 부정/조건/modality 약화
- fidelity와 publication readiness 혼동
- handoff hash 불일치를 우회 옵션으로 숨김

---

# 35. 업데이트

## Research-to-Skill

```bash
git -C <BOOK_TO_SKILL_REPO> pull --ff-only
python -m pip install -e <BOOK_TO_SKILL_REPO>
```

## translate-book manual clone

Codex:

```bash
git -C ~/.agents/skills/translate-book pull --ff-only
```

Claude Code:

```bash
git -C ~/.claude/skills/translate-book pull --ff-only
```

중요 production 작업 전에는 repo 변경 내역, 테스트 상태, 기존 backup/HANDOFF를 확인한다.

---

# 36. v1 기준선

이 문서 최초 공개 기준:

## Research-to-Skill

```text
repository: icerain-cmd/book-to-skill
branch: master
baseline commit: 9355188b292ede45262d2871049385d310d6b106
```

## Scholarly KO→EN Translation

```text
repository: icerain-cmd/translate-book
branch: main
baseline commit: 89289c5be53610cd48959db699760396bee4ba60
```

소프트웨어가 변경되면 문서의 명령과 계약도 재검증해야 한다.

---

# 37. 초단기 치트시트

## Research-to-Skill

```bash
# 시작
research-to-skill preflight --project <PROJECT>
research-to-skill lock status --project <PROJECT>

# ingest + compile plan
research-to-skill add <SOURCE> --project <PROJECT>
research-to-skill compile --project <PROJECT>

# semantic 작업 후
research-to-skill validate --project <PROJECT>
research-to-skill compile --project <PROJECT> --complete

# 종료
research-to-skill validate --project <PROJECT>
research-to-skill handoff --project <PROJECT>
```

## 학술 KO→EN

```text
Codex Translator
→ translation
→ 9축 fidelity audit
→ SCHOLARLY_HANDOFF
```

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

```text
Claude Reviewer
→ 원문 대조
→ 국소 수정
→ final-en + publication-audit + review-changes
```

```bash
python scripts/reviewer_gate.py <TEMP>/SCHOLARLY_HANDOFF.json --final-en <TEMP>/final-en.md --publication-audit <TEMP>/publication-audit.md --review-changes <TEMP>/review-changes.md
```

이 구조가 실제 운영의 핵심이다.

---

# 38. 라이선스와 책임 범위

이 저장소에서 새로 작성한 original documentation은 별도 표기가 없는 한 **CC BY 4.0**이다. 공유·수정·번역·교육·연구·상업적 활용이 가능하며 적절한 attribution이 필요하다.

이 문서는 `book-to-skill`, `translate-book` 또는 다른 제3자 소프트웨어의 MIT License를 변경하지 않는다. 소프트웨어와 제3자 자료는 각각의 원 라이선스에 따른다.

또한 이 저장소는 OpenAI 또는 Anthropic의 공식 문서가 아니다. Codex와 Claude Code의 제품 기능·설치 방식·UI는 변경될 수 있으므로 최신 제품 문서를 함께 확인해야 한다.
