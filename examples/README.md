# Copy-ready examples

These examples assume the component repositories were installed by `install.ps1` or `install.sh` and that `doctor` reports no core failures.

## 1. Research-to-Skill on a shared project

Example project layout:

```text
R:\research\kant\
├── sources\
├── research.json
└── HANDOFF.md
```

Create and inspect a project:

```bash
research-to-skill init "Kant Research" --dir R:/research/kant
research-to-skill preflight --project R:/research/kant
research-to-skill status --project R:/research/kant
```

Add source material and validate:

```bash
research-to-skill add R:/papers/kant --project R:/research/kant
research-to-skill compile --project R:/research/kant
research-to-skill validate --project R:/research/kant
```

Recommended agent handoff rule:

```text
Agent A writes canonical research state
        ↓
validate
        ↓
HANDOFF.md
        ↓
Agent B verifies before continuing
```

Do not let Codex and Claude Code write the same canonical research project concurrently.

## 2. Scholarly Korean → English translation

Example project layout:

```text
R:\translation\paper-a\
├── source\paper-ko.md
├── draft\paper-en-codex.md
├── temp\
│   ├── terminology.json
│   ├── author_concepts.json
│   ├── claims.json
│   ├── translation-audit.md
│   └── SCHOLARLY_HANDOFF.json
└── review\
```

Codex Translator creates the English draft and handoff. From the `translate-book` repository:

```bash
python scripts/scholarly_handoff.py create \
  --source "R:/translation/paper-a/source/paper-ko.md" \
  --translation "R:/translation/paper-a/draft/paper-en-codex.md" \
  --output "R:/translation/paper-a/temp/SCHOLARLY_HANDOFF.json" \
  --temp-dir "R:/translation/paper-a/temp" \
  --translation-audit "R:/translation/paper-a/temp/translation-audit.md" \
  --fresh-translation
```

Validate before review:

```bash
python scripts/scholarly_handoff.py validate R:/translation/paper-a/temp/SCHOLARLY_HANDOFF.json
```

Claude Code then reviews the existing Codex draft against the Korean source. It should not silently replace the workflow with a second full translation.

## 3. Minimal session prompts

### Research session start

```text
Read the current project state and HANDOFF.md first.
Run preflight before any write operation.
Do not reverse explicit do-not-reverse decisions from the previous agent.
Keep one writer for canonical research state.
```

### Research session end

```text
Validate the project.
Update HANDOFF.md with completed work, unresolved items, the next task,
working files, and decisions that the next agent must not reverse.
```

### Scholarly translation reviewer

```text
Act as Reviewer / Publication Editor.
Validate SCHOLARLY_HANDOFF.json with normal file checks before editing.
Review the existing Codex translation against the Korean source.
Do not perform a second full translation.
Preserve locked terminology, claim strength, negation, conditions, and modality.
Write reviewer outputs separately from the immutable Codex translator artifact.
```

For the complete procedures and failure recovery rules, use the full manuals in `docs/`.
