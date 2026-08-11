# 학술 한국어→영어 번역 빠른 시작

이 문서는 `icerain-cmd/translate-book` 포크의 학술 한→영 workflow를 Codex와 Claude Code에서 사용하는 최소 절차를 정리한다.

## 기본 역할

```text
한국어 원문
   ↓
Codex = Translator
   ↓
영문 draft + translation fidelity audit + SCHOLARLY_HANDOFF
   ↓
Claude Code = Reviewer / Publication Editor
   ↓
final-en.md + publication-audit.md + review-changes.md
   ↓
Human = 최종 출판 판단
```

A/B 실험이 아니라면 동일 논문을 Codex와 Claude Code에 각각 처음부터 번역시키지 않는다.

## 1. Skill 설치

### Codex

```bash
npx skills add icerain-cmd/translate-book -a codex -g
```

수동 설치:

```bash
mkdir -p ~/.agents/skills
git clone https://github.com/icerain-cmd/translate-book.git ~/.agents/skills/translate-book
```

### Claude Code

```bash
npx skills add icerain-cmd/translate-book -a claude-code -g
```

수동 설치:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/icerain-cmd/translate-book.git ~/.claude/skills/translate-book
```

필수 외부 도구: Python 3, Pandoc, Calibre `ebook-convert`, `pypandoc`; `beautifulsoup4` 권장.

## 2. scholarly route 확인

학술 한국어→영어 번역임을 프롬프트에 명시한다.

```text
학술 한영 번역
scholarly Korean-to-English
academic Korean-to-English
논문 영어 번역
```

필요하면:

```bash
python scripts/scholarly_dispatch.py --source-lang ko --target-lang en --mode scholarly --request "학술논문 영어 번역"
```

정상 route는 `scholarly-ko-en`이다.

## 3. Codex = Translator

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
8. 완성된 Codex draft를 immutable translator artifact로 취급한다.
9. 마지막에 SCHOLARLY_HANDOFF.json과 HANDOFF.md를 만들어 Claude Code Reviewer에게 넘긴다.
10. Claude Code가 두 번째 독립 번역을 하도록 지시하지 않는다.
```

## 4. Scholarly preflight

정규화된 한국어 Markdown 원문:

```bash
python scripts/scholarly_preflight.py <SOURCE.md> --out <TEMP>/scholarly-preflight.json
```

핵심 QA 축:

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

## 5. 계약 파일

가능하면 다음을 사용한다.

```text
terminology.json
author_concepts.json
claims.json
```

- `terminology.json`: LOCKED / PREFERRED / FLEXIBLE 용어 정책
- `author_concepts.json`: 저자 고유 개념 정의와 금지되는 함의
- `claims.json`: modality, polarity, conditions, exceptions, forbidden reformulations

자동 추출 용어를 agent가 임의로 LOCKED로 승격하지 않는다.

## 6. Codex → Claude HANDOFF

Codex draft 완료 후:

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

resume/cached chunk가 있다면 provenance를 정확히 기록한다.

```text
--translated-chunk chunk0001
--retranslated-chunk chunk0017
--reused-chunk chunk0004
```

생성 파일:

```text
SCHOLARLY_HANDOFF.json
HANDOFF.md
```

검증:

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

정상 production에서는 `--no-file-check`로 우회하지 않는다.

## 7. path portability

schema v2의 canonical artifact identity:

```text
relative_path + sha256
```

`R:\...`와 `/mnt/r/...`는 locator다. 같은 shared project tree가 PC1/PC2에 보인다면 WSL에서 만든 handoff를 native Windows에서 정상 SHA 검증할 수 있어야 한다.

hash mismatch가 나면 JSON hash를 수동 수정하지 않는다. 실제 source/draft가 바뀌었는지 확인하고, 정당한 translator artifact 변경이면 새 handoff를 생성한다.

## 8. Claude Code = Reviewer / Publication Editor

시작 전에 반드시:

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

실패하면 review를 시작하지 않는다.

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
2. concept drift
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

## 9. Reviewer가 허용받은 수정

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
부정·조건·modality 임의 변경
저자 고유 구분의 임의 통합
```

## 10. Reviewer 출력과 최종 gate

필수 출력:

```text
final-en.md
publication-audit.md
review-changes.md
```

최종 검증:

```bash
python scripts/reviewer_gate.py <TEMP>/SCHOLARLY_HANDOFF.json \
  --final-en <TEMP>/final-en.md \
  --publication-audit <TEMP>/publication-audit.md \
  --review-changes <TEMP>/review-changes.md
```

`valid: true`가 나와야 Reviewer 단계 완료다.

## 11. Fidelity와 Publication Readiness를 분리한다

```text
translation-audit.md
= 한국어 원문의 논증이 영어에서 보존되었는가?

publication-audit.md
= 이 영문 원고가 실제 목표 출판 환경에 제출 가능한가?
```

따라서 다음은 정상 상태다.

```text
translation fidelity = PASS
publication readiness = NOT READY
```

예: 공식 저자명 로마자 표기 미확정, target journal style 미지정, 원문 자체의 모순.

## 초단기 치트시트

```text
Codex:
scholarly KO→EN → 번역 → 9축 fidelity audit → SCHOLARLY_HANDOFF
```

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

```text
Claude Code:
원문 대조 → 국소 수정 → final-en + publication-audit + review-changes
```

```bash
python scripts/reviewer_gate.py <TEMP>/SCHOLARLY_HANDOFF.json --final-en <TEMP>/final-en.md --publication-audit <TEMP>/publication-audit.md --review-changes <TEMP>/review-changes.md
```
