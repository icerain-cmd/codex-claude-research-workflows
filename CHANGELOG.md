# Changelog

## v1.2.0 — 2026-08-12

Distribution-hub release.

### Added

- `install.ps1` for Windows installation and component updates.
- `install.sh` for WSL/Linux/macOS installation and component updates.
- `doctor.ps1` and `doctor.sh` for environment diagnostics.
- `components.lock.json` recording the documented component baselines.
- `examples/README.md` with copy-ready Research-to-Skill and scholarly KO→EN operating examples.
- GitHub Actions smoke checks for shell syntax, PowerShell parsing, and component-manifest JSON validity.
- `LICENSE-CODE` applying MIT licensing to original installer and diagnostic code in this hub.

### Changed

- Reframed the repository explicitly as a **distribution and documentation hub**, rather than an executable monorepo.
- Added one-command entry points that clone/update the maintained `book-to-skill` and `translate-book` repositories without duplicating their source code here.
- Added automatic linking of the maintained `translate-book` checkout into Codex and Claude Code skill directories, with opt-out switches.
- Moved installation and repository-layout guidance to the top of both English and Korean landing pages.
- Clarified licensing boundaries between CC BY 4.0 documentation, MIT hub scripts, and separately licensed component repositories.

### Documented component baselines

- `icerain-cmd/book-to-skill` — `9355188b292ede45262d2871049385d310d6b106`
- `icerain-cmd/translate-book` — `89289c5be53610cd48959db699760396bee4ba60`

## v1.1.1 — 2026-08-11

International-first repository layout.

### Changed

- English is now the default GitHub landing page in `README.md`.
- Korean README moved to `README_KO.md` and remains directly linked from the English landing page.
- Removed the redundant `README_EN.md` alias to avoid maintaining duplicate English landing content.
- Language navigation now follows the conventional `README.md` (English) / `README_KO.md` (Korean) structure.

## v1.1.0 — 2026-08-11

International documentation release.

### Added

- Full English README for international researchers and instructors.
- Full English user manual covering Research-to-Skill and scholarly Korean→English workflows.
- Copy-ready English prompts for Codex Translator, Claude Code Reviewer, Research-to-Skill session start/end, semantic integration, and independent verification.
- English explanations of single-writer collaboration, explicit HANDOFF, schema-v2 scholarly handoff, fidelity vs. publication-readiness gates, and human decision boundaries.

### Changed

- Korean README included direct language navigation to the English documentation during the initial bilingual rollout.

## v1.0.0 — 2026-08-11

Initial public documentation baseline.

### Added

- Integrated Korean user manual for Codex + Claude Code research workflows.
- Research-to-Skill quickstart covering installation, ingest, compile, validation, writer locks, and HANDOFF.
- Scholarly Korean→English quickstart covering Codex Translator → Claude Code Reviewer role separation, fidelity gates, SCHOLARLY_HANDOFF, and publication review.
- CC BY 4.0 license for original documentation.
- Third-party notices preserving MIT licensing and upstream attribution for `book-to-skill` and `translate-book`.
- Citation metadata and contribution guidance.

### Software baselines documented

- `icerain-cmd/book-to-skill` — Research-to-Skill baseline commit `9355188b292ede45262d2871049385d310d6b106`
- `icerain-cmd/translate-book` — scholarly KO→EN baseline commit `89289c5be53610cd48959db699760396bee4ba60`
