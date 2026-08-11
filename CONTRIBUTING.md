# Contributing

Contributions that improve accuracy, portability, reproducibility, and clarity are welcome.

## Good contributions

- Correct a command that changed upstream.
- Add a verified Windows / WSL / Linux variation.
- Improve a Codex or Claude Code workflow without weakening the role separation described here.
- Add a reproducible failure case and recovery procedure.
- Improve Korean wording or add a translation while preserving technical meaning.
- Report a mismatch between this guide and the current `icerain-cmd/book-to-skill` or `icerain-cmd/translate-book` implementation.

## Before opening a pull request

1. Check the current default branches of the related repositories.
2. Verify commands against an actual installation when possible.
3. Do not present unexecuted tests as passed.
4. Preserve the distinction between canonical data and derived views in Research-to-Skill.
5. Preserve the `Codex Translator → Claude Code Reviewer → Human` production role boundary for scholarly KO→EN unless the contribution is explicitly documenting an alternative experiment.
6. Do not silently weaken integrity gates such as SHA validation, writer locks, fidelity checks, or reviewer outputs.

## Documentation style

- Prefer copy-pasteable commands.
- Clearly distinguish required steps from optional recommendations.
- State assumptions such as OS, shell, shared drive, or source format.
- Separate observed behavior from recommendations.
- When a workflow is version-specific, record the relevant repository/commit or date.

## Licensing

By contributing original documentation to this repository, you agree that your contribution may be distributed under the repository's **CC BY 4.0** documentation license unless otherwise stated.

Do not submit third-party text, code, images, or other material unless you have the right to redistribute it and its license/attribution is preserved. See `THIRD_PARTY_NOTICES.md`.

## Product references

This is an independent community documentation project, not official OpenAI or Anthropic documentation. Product behavior can change; corrections based on newer product versions are welcome.
