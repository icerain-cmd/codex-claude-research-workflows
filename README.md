# Codex · Claude Code Research Workflows

**English** · [한국어](README_KO.md)

**Open, practical workflows for AI-assisted humanities and social-science research with Codex and Claude Code.**

This repository documents reproducible ways to use **Codex and Claude Code as role-separated research agents** rather than as interchangeable chatbots. It focuses on two concrete workflows developed through real scholarly use:

1. **Research-to-Skill** — persistent, provenance-aware research memory for papers, books, notes, claims, concepts, arguments, and evidence locators.
2. **Scholarly Korean → English Translation** — an asymmetric production workflow in which Codex produces the translation and Claude Code independently reviews it without retranslating the manuscript from scratch.

The central design pattern is:

```text
generation / structured writing
        ↓
independent verification
        ↓
limited correction
        ↓
explicit human decisions
```

## 1. Research-to-Skill

Research-to-Skill is a long-lived research workspace built on the `icerain-cmd/book-to-skill` fork. It adds persistent source ingestion, concept and claim identity, provenance, validation, incremental semantic compilation, safe shared-workspace collaboration, and explicit agent handoff.

The basic collaboration pattern is:

```text
Agent A writes
   ↓
validate
   ↓
HANDOFF.md
   ↓
Agent B verifies / continues
```

Only **one writer** should modify canonical research state at a time. Codex and Claude Code can both work on the same project, but they should coordinate through `preflight`, writer locks, validation, Git state, and `HANDOFF.md` rather than through implicit memory.

Typical uses include:

- building a persistent research memory from papers and books;
- distinguishing author claims from external claims;
- preserving evidence locators and source provenance;
- tracking concept evolution across multiple sources;
- handing unfinished research work from one agent to another;
- exporting structured research as JSON, Markdown, or an agent skill.

## 2. Scholarly Korean → English Translation

For scholarly translation, this repository does **not** recommend asking two models to translate the same paper independently by default.

Instead, it uses asymmetric roles:

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

Codex handles full-manuscript generation, chunked translation, terminology and theory contracts, citation integrity, and translation-fidelity checks. Claude Code then compares the existing English draft against the Korean source and makes only justified local corrections.

The reviewer is specifically asked to check:

- semantic drift;
- concept-family inconsistency;
- epistemic strength;
- negation, conditions, and modality;
- academic English;
- citation localization;
- bibliography normalization;
- publication-readiness issues.

Official author romanization, target-journal style, and genuine source ambiguity remain explicit **human decisions**.

## Documentation

### English

- **[Full User Manual](docs/USER_MANUAL_EN.md)** — installation, daily operation, handoff, validation, recovery, and copy-ready prompts.

### Korean

- **[한국어 README](README_KO.md)**
- **[통합 사용 매뉴얼](docs/USER_MANUAL_KO.md)** — 전체 한국어 매뉴얼
- **[Research-to-Skill 빠른 시작](docs/RESEARCH_TO_SKILL_QUICKSTART_KO.md)**
- **[학술 한→영 번역 빠른 시작](docs/SCHOLARLY_KO_EN_QUICKSTART_KO.md)**

## Related repositories

The workflows documented here are based on the following public software:

### Research-to-Skill

- Maintained fork: `icerain-cmd/book-to-skill`
- Upstream: `virgiliojr94/book-to-skill`
- Software license: MIT

### Scholarly translation

- Maintained fork: `icerain-cmd/translate-book`
- Upstream: `deusyu/translate-book`
- Software license: MIT

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for attribution and license boundaries.

## Core principles

1. **Canonical data before prose views**  
   Canonical source/data takes precedence over derived Markdown views.

2. **Single writer**  
   Shared research state should not be modified concurrently by multiple agents.

3. **Explicit handoff**  
   Use `HANDOFF.md`, hashes, validation results, and working-file references instead of relying on conversational memory.

4. **Generation and review are different jobs**  
   The agent that produces a draft and the agent that verifies it should not be treated as performing the same task.

5. **Fidelity is not publication readiness**  
   A translation can accurately preserve the source argument and still require publication-specific editorial decisions.

6. **Human decisions remain explicit**  
   AI should surface unresolved scholarly or editorial questions rather than silently inventing authoritative answers.

## Who this repository is for

This repository is especially useful for:

- humanities and social-science researchers using multiple coding agents;
- digital-humanities projects that need traceable AI-assisted research workflows;
- researchers who want persistent claim/concept memory rather than disposable chat sessions;
- scholars translating Korean academic writing into English;
- teams working across Windows, WSL, and shared drives;
- instructors teaching reproducible human–AI research practice.

## What this repository is not

This is **not** an official OpenAI or Anthropic repository, and it does not imply endorsement, sponsorship, or affiliation with either company. Product interfaces and capabilities can change; always verify current product behavior against the relevant official documentation.

This repository also does not replace scholarly judgment. The workflows are designed to make AI-assisted work more auditable, not to remove human responsibility.

## Documentation license

Original documentation in this repository is released under **Creative Commons Attribution 4.0 International (CC BY 4.0)** unless otherwise noted.

You may:

- share the documentation;
- adapt it;
- translate it;
- use it in research, teaching, workshops, and institutional workflows;

provided appropriate attribution is given.

Software code and third-party materials are **not** relicensed by this documentation repository and remain under their respective licenses.

See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Citation

A `CITATION.cff` file is included so the repository can be cited in academic work and teaching materials.

## Maintainer

Maintained by **Lee Yong Wook** (`icerain-cmd`).

This documentation was developed with AI assistance and organized as an open, reproducible research workflow guide.
