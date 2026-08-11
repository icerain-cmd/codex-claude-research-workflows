# Codex · Claude Code Research Workflows

**English** · [한국어](README_KO.md)

**Distribution and documentation hub for reproducible AI-assisted humanities and social-science research with Codex and Claude Code.**

> **What this repository is:** a lightweight distribution entry point plus the public operating manuals. It now contains installer and diagnostic scripts, but the two workflow engines themselves remain in their maintained component repositories: `icerain-cmd/book-to-skill` and `icerain-cmd/translate-book`. This avoids duplicating code while giving users one place to install, verify, learn, and reproduce the complete workflow.

## Quick start

### Windows PowerShell

```powershell
git clone https://github.com/icerain-cmd/codex-claude-research-workflows.git
cd codex-claude-research-workflows
powershell -ExecutionPolicy Bypass -File .\install.ps1
powershell -ExecutionPolicy Bypass -File .\doctor.ps1
```

Custom install root:

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

Custom install root:

```bash
bash install.sh --root /mnt/r/tools/codex-claude-research-tools
bash doctor.sh --root /mnt/r/tools/codex-claude-research-tools
```

The installer:

1. clones or fast-forward updates `icerain-cmd/book-to-skill`;
2. clones or fast-forward updates `icerain-cmd/translate-book`;
3. installs the `research-to-skill` Python CLI and common PDF/DOCX dependencies;
4. installs `pypandoc` and `beautifulsoup4` for the translation pipeline;
5. links the maintained `translate-book` checkout into Codex and Claude Code skill directories;
6. reports missing external tools such as Pandoc or Calibre `ebook-convert`.

The `doctor` scripts check the repositories, Python version, `research-to-skill`, translation helpers, Pandoc/Calibre, agent commands, and skill paths. Missing optional agent/tooling is reported as a warning; broken core installation is reported as a failure.

Use `--skip-skill-links` / `-SkipSkillLinks` or `--skip-python-deps` / `-SkipPythonDeps` when you want the hub to manage only part of the environment.

## Repository layout

```text
codex-claude-research-workflows/
├── install.ps1              # Windows installer / updater
├── install.sh               # WSL/Linux/macOS installer / updater
├── doctor.ps1               # Windows environment diagnostics
├── doctor.sh                # Unix environment diagnostics
├── components.lock.json     # documented component release baselines
├── examples/                # copy-ready operating examples
├── docs/                    # full manuals and quickstarts
└── .github/workflows/       # distribution smoke checks
```

`components.lock.json` records the component commits used as the documented release baseline. The installers deliberately follow the maintained `master` / `main` branches so an existing installation can receive later fixes; use the lock file when you need an exact reproducibility reference.

## What the workflows cover

This project documents reproducible ways to use **Codex and Claude Code as role-separated research agents** rather than as interchangeable chatbots. It focuses on two concrete workflows developed through real scholarly use:

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

## Documentation and examples

### English

- **[Full User Manual](docs/USER_MANUAL_EN.md)** — installation, daily operation, handoff, validation, recovery, and copy-ready prompts.
- **[Copy-ready examples](examples/README.md)** — minimal command and handoff examples for both workflows.

### Korean

- **[한국어 README](README_KO.md)**
- **[통합 사용 매뉴얼](docs/USER_MANUAL_KO.md)** — 전체 한국어 매뉴얼
- **[Research-to-Skill 빠른 시작](docs/RESEARCH_TO_SKILL_QUICKSTART_KO.md)**
- **[학술 한→영 번역 빠른 시작](docs/SCHOLARLY_KO_EN_QUICKSTART_KO.md)**

## Component repositories

The workflow engines are maintained separately so they can preserve their own upstream history, tests, and licenses.

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

## Licensing

Original documentation in this repository is released under **Creative Commons Attribution 4.0 International (CC BY 4.0)** unless otherwise noted; see [LICENSE](LICENSE).

Original distribution code in this repository, including the installer and doctor scripts, is released under the **MIT License**; see [LICENSE-CODE](LICENSE-CODE).

The component repositories and third-party materials retain their respective licenses. This hub does not relicense them.

## Citation

A `CITATION.cff` file is included so the repository can be cited in academic work and teaching materials.

## Maintainer

Maintained by **Lee Yong Wook** (`icerain-cmd`).

This documentation and lightweight distribution layer were developed with AI assistance and organized as an open, reproducible research workflow guide.
