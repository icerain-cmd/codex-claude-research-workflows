# Codex · Claude Code User Manual
## Research-to-Skill + Scholarly Korean → English Translation

> Reference software
> - Research-to-Skill: `icerain-cmd/book-to-skill` (`master`)
> - Scholarly Korean→English Translation: `icerain-cmd/translate-book` (`main`)
> - Documentation baseline: 2026-08-11
>
> This is an **operational user manual**. It focuses less on internal implementation and more on four practical questions: **which agent should do which job, which commands should be run, how should the result be verified, and how should work be handed to the next agent?**

[한국어 매뉴얼](USER_MANUAL_KO.md) · **English Manual**

---

# 1. The overall architecture

Both workflows separate **generation/modification from independent verification** and use explicit state transfer between agents.

## Research-to-Skill

```text
Codex or Claude Code
   ↓
work on canonical research data
   ↓
validate
   ↓
HANDOFF.md
   ↓
next agent
```

The key rule is **single writer**: only one agent should modify canonical research data at a time.

## Scholarly Korean → English translation

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

In routine production, do **not** ask Codex and Claude Code to translate the same paper independently from scratch. Claude Code adds the most value as an **independent reviewer of the first translation**, detecting and correcting local problems without discarding the translator's work.

---

# 2. Recommended storage layout

A shared drive is optional, but it is useful when Codex and Claude Code run on different machines.

Example:

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

The same drive under WSL is commonly visible as:

```text
/mnt/r/tools/book-to-skill
/mnt/r/tools/translate-book
/mnt/r/research/project-a
/mnt/r/translation/paper-a
```

Recommended items to keep in the shared workspace:

- canonical repositories;
- research projects;
- source documents;
- semantic artifacts;
- `HANDOFF.md`;
- translation source, draft, audit, handoff, and final files.

Recommended items to keep local to each machine:

- `.venv`;
- `__pycache__`;
- pip caches;
- `node_modules`;
- OS-specific runtime/cache files;
- large generated test outputs.

---

# Part I. Research-to-Skill

# 3. Installing Research-to-Skill

Repository:

```text
https://github.com/icerain-cmd/book-to-skill.git
```

Research-to-Skill is a separate CLI added to the `book-to-skill` fork. The original `book-to-skill` workflow remains available.

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

If the repository is already installed:

```bash
git -C <BOOK_TO_SKILL_REPO> pull --ff-only
python -m pip install -e <BOOK_TO_SKILL_REPO>
```

---

# 4. Optional agent / machine identity

Each machine may define a local identity outside the shared project.

Path:

```text
~/.config/research-to-skill/config.json
```

Example for a Codex machine:

```json
{
  "agent": "codex",
  "machine": "PC1"
}
```

Example for a Claude Code machine:

```json
{
  "agent": "claude-code",
  "machine": "PC2"
}
```

Do **not** put this file inside the shared research project. If no identity is configured, the CLI falls back to `local` and the machine hostname.

---

# 5. Creating a new research project

```bash
research-to-skill init "My Research" --dir ./my-research
```

On a shared drive:

```bash
research-to-skill init "My Research" --dir R:/research/my-research
```

Immediately check the project:

```bash
research-to-skill preflight --project R:/research/my-research
research-to-skill status --project R:/research/my-research
```

---

# 6. Core Research-to-Skill commands

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

For collaboration, the most important operations are:

```text
preflight
lock status
validate
handoff
```

---

# 7. Start every research session the same way

Before Codex or Claude Code modifies a canonical project:

```bash
git status
research-to-skill preflight --project <PROJECT>
research-to-skill lock status --project <PROJECT>
git log -1 --oneline
```

If `HANDOFF.md` exists, read it **before** making changes.

## Copy-ready Codex start prompt

```text
Start work on this Research-to-Skill project.
First read HANDOFF.md, then inspect git status, research-to-skill preflight,
lock status, and the latest git log.
Treat canonical research.json as the source of truth.
Do not silently change the meaning of existing claims, concepts, or graph relations.
```

## Copy-ready Claude Code start prompt

```text
Continue work on this Research-to-Skill project.
First read HANDOFF.md and the current Git state, then run preflight and lock status.
Preserve the previous agent's completed work, unfinished items, and do-not-reverse decisions.
Prioritize canonical research.json and source evidence over derived Markdown views.
```

---

# 8. Ingesting papers, books, and notes

Single file:

```bash
research-to-skill add paper.pdf --project <PROJECT>
```

Multiple inputs or directories:

```bash
research-to-skill add ./papers ./notes --project <PROJECT>
```

Structure-heavy document:

```bash
research-to-skill add paper.pdf --project <PROJECT> --mode technical
```

Then inspect the project:

```bash
research-to-skill status --project <PROJECT>
research-to-skill list --project <PROJECT>
```

Identical content is detected by SHA-256, so renamed copies of the same source can be skipped rather than ingested twice.

---

# 9. What `compile` actually does

```bash
research-to-skill compile --project <PROJECT>
```

This command does **not** directly call an LLM. It writes a provider-independent **`compile-plan.json`**.

The host agent should then:

1. read only the sources listed in `compile-plan.json`;
2. compare them against existing concepts, claims, arguments, and paper records;
3. identify duplicates and conflicts before creating new artifacts;
4. preserve `author`, `external`, and `mixed` provenance;
5. verify evidence locators;
6. merge semantic results into canonical data;
7. run `validate`;
8. run `compile --complete` only after validation succeeds.

Recommended prompt:

```text
Process only the sources listed in compile-plan.json.
Before creating a new concept or claim, compare it against the existing research memory.
Do not change author/external/mixed provenance without evidence.
Verify the source locator and evidence for every important claim.
Run validate after semantic integration, and run compile --complete only if validation passes.
```

Finalize all planned sources:

```bash
research-to-skill validate --project <PROJECT>
research-to-skill compile --project <PROJECT> --complete
```

Finalize selected sources only:

```bash
research-to-skill compile --project <PROJECT> --complete source-001 source-002
```

---

# 10. Inspecting research data

List registered sources:

```bash
research-to-skill list --project <PROJECT>
```

Inspect a source:

```bash
research-to-skill inspect source source-001 --project <PROJECT>
```

Inspect a concept:

```bash
research-to-skill inspect concept <CONCEPT_ID> --project <PROJECT>
```

Inspect a claim:

```bash
research-to-skill inspect claim claim-001 --project <PROJECT>
```

Recommended retrieval depth:

```text
concepts → claims → arguments → papers → source text
```

Descend to source text when direct evidence, a locator, or conflict resolution is required.

---

# 11. Canonical data vs. derived artifacts

The direction of authority is:

```text
research.json → derived artifacts
```

If concept Markdown, claim artifacts, or `topic-index.md` drift from canonical data, do not manually repair every derived file first. Instead run:

```bash
research-to-skill sync-artifacts --project <PROJECT>
research-to-skill validate --project <PROJECT>
```

Do not silently reconstruct canonical research data from a stale derived Markdown view.

---

# 12. Writer Lock

The following write operations acquire and release the project lock automatically:

- `add`;
- `remove`;
- `compile`;
- `compile --complete`.

Check lock state:

```bash
research-to-skill lock status --project <PROJECT>
```

Manual acquire/release example:

```bash
research-to-skill lock acquire --project <PROJECT> --owner codex --operation semantic-write
research-to-skill lock release --project <PROJECT> --owner codex
```

If a stale lock is reported, first verify that no other machine or agent is actually writing. Only then break it explicitly:

```bash
research-to-skill lock break --project <PROJECT> --force
```

Expired locks are intentionally **not** deleted automatically.

---

# 13. Removing a source safely

Normal removal:

```bash
research-to-skill remove source-001 --project <PROJECT>
```

If dependent claims, concepts, arguments, citations, or paper records exist, removal is blocked.

Cascading removal:

```bash
research-to-skill remove source-001 --project <PROJECT> --cascade
```

`--cascade` is a destructive operation. Create a Git recovery point or export a backup first:

```bash
research-to-skill export --format json --output backup.json --project <PROJECT>
```

---

# 14. Ending a research session and writing HANDOFF

Before stopping work:

```bash
research-to-skill validate --project <PROJECT>
research-to-skill status --project <PROJECT>
research-to-skill lock status --project <PROJECT>
git diff
git status
research-to-skill handoff --project <PROJECT>
```

This creates:

```text
<PROJECT>/HANDOFF.md
```

A useful handoff should communicate at least:

- completed work;
- unfinished work;
- the next task;
- changed files/artifacts;
- current validation state;
- decisions that should not be reversed casually.

## Copy-ready Codex end prompt

```text
End this session cleanly.
Run validate, status, and lock status, then review git diff.
Generate HANDOFF.md so the next agent can see what was completed,
what remains unfinished, what should happen next, and which decisions must not be reversed.
```

## Copy-ready Claude Code end prompt

```text
Before ending the session, make validation pass.
Check consistency between canonical data and derived artifacts and confirm that the writer lock is released.
Update HANDOFF.md so the next agent can continue immediately without reconstructing the context from scratch.
```

---

# 15. Practical Research-to-Skill recipe

Scenario: Codex ingests a new paper and Claude Code independently verifies the integration.

## Codex

```bash
research-to-skill preflight --project <PROJECT>
research-to-skill add <PAPER.pdf> --project <PROJECT>
research-to-skill compile --project <PROJECT>
```

Prompt:

```text
Execute the compile plan and integrate the new source into the existing research memory.
Preserve provenance and locators, avoid duplicate concepts/claims,
run validate, then run compile --complete only if validation passes.
Finish by generating HANDOFF.md.
```

## Claude Code

```bash
research-to-skill preflight --project <PROJECT>
research-to-skill validate --project <PROJECT>
```

Prompt:

```text
Read HANDOFF.md and independently verify the previous Codex integration.
Pay special attention to source locators, author vs. external provenance,
concept membership, and duplication against existing concepts/claims.
Correct only concrete problems, then validate again.
```

Not every source needs two-model verification. Add the second verifier when the cost of error is high—for example, when changing a core concept, correcting provenance, or modifying critical evidence.

---

# 16. Exporting research

Complete workspace as a skill ZIP:

```bash
research-to-skill export --format skill --output <PATH> --project <PROJECT>
```

Canonical JSON:

```bash
research-to-skill export --format json --output research-export.json --project <PROJECT>
```

Portable Markdown index:

```bash
research-to-skill export --format markdown --output research-index.md --project <PROJECT>
```

---

# Part II. Scholarly Korean → English Translation

# 17. Installing the translation skill

Repository:

```text
https://github.com/icerain-cmd/translate-book.git
```

## Codex

Recommended installation:

```bash
npx skills add icerain-cmd/translate-book -a codex -g
```

Manual installation:

```bash
mkdir -p ~/.agents/skills
git clone https://github.com/icerain-cmd/translate-book.git ~/.agents/skills/translate-book
```

## Claude Code

Recommended installation:

```bash
npx skills add icerain-cmd/translate-book -a claude-code -g
```

Manual installation:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/icerain-cmd/translate-book.git ~/.claude/skills/translate-book
```

Update a manual clone:

```bash
git -C ~/.agents/skills/translate-book pull --ff-only
```

or:

```bash
git -C ~/.claude/skills/translate-book pull --ff-only
```

Restart the agent host if a newly installed skill is not detected.

---

# 18. Translation prerequisites

The general translation pipeline expects:

```text
Python 3
Pandoc
Calibre / ebook-convert
pypandoc
beautifulsoup4 (recommended)
```

Check installed tools:

```bash
python --version
pandoc --version
ebook-convert --version
```

Python packages:

```bash
pip install pypandoc beautifulsoup4
```

---

# 19. Distinguish general translation from scholarly KO→EN

## General translation

Claude Code:

```text
/translate-book translate book.pdf to Korean
```

Codex:

```text
$translate-book Translate book.pdf into Korean.
```

This uses the general book-translation pipeline.

## Scholarly Korean → English

Make the scholarly mode explicit with phrases such as:

```text
scholarly Korean-to-English
academic Korean-to-English
translate this Korean academic paper into English
```

You can also inspect the conservative dispatcher directly:

```bash
python scripts/scholarly_dispatch.py \
  --source-lang ko \
  --target-lang en \
  --mode scholarly \
  --request "scholarly Korean-to-English translation"
```

Expected route:

```text
scholarly-ko-en
```

Scholarly mode adds extra integrity and theory-preservation checks, including:

- citation integrity;
- LOCKED / PREFERRED / FLEXIBLE terminology;
- epistemic strength;
- semantic fidelity;
- author-concept preservation;
- claim preservation;
- negation preservation;
- condition preservation;
- relation preservation.

---

# 20. Codex is the default Translator

Codex owns the first complete scholarly translation in the normal production workflow.

## Copy-ready Codex Translator prompt

```text
Translate this Korean academic paper into English using scholarly Korean-to-English mode.
Your role is Codex Translator.

Requirements:
1. Preserve the argumentative force, negation, conditions, exceptions, and modality of the source.
2. Do not silently change LOCKED terminology.
3. If author_concepts.json and claims.json exist, treat them as binding scholarly contracts.
4. Protect and restore citation spans correctly.
5. Run epistemic, semantic, and theory-fidelity checks after chunk translation.
6. Retranslate only failed chunks when possible.
7. Run global consistency and translation-fidelity auditing after the manuscript is merged.
8. Treat the completed Codex draft as an immutable translator artifact for the reviewer stage.
9. Finish by generating SCHOLARLY_HANDOFF.json and HANDOFF.md for Claude Code Reviewer.
10. Do not instruct Claude Code to produce a second independent translation from scratch.
```

---

# 21. Scholarly preflight

For a normalized Korean Markdown source:

```bash
python scripts/scholarly_preflight.py <SOURCE.md> --out <TEMP>/scholarly-preflight.json
```

Preflight inventories:

- source language;
- heading structure;
- protected citation spans;
- required QA axes.

Recommended nine QA axes:

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

---

# 22. Scholarly contract files

For high-stakes papers, use explicit contract files whenever possible:

```text
terminology.json
author_concepts.json
claims.json
```

## `terminology.json`

Recommended policy levels:

- `LOCKED` — must not be changed casually;
- `PREFERRED` — default form unless there is a justified exception;
- `FLEXIBLE` — may vary with context.

An automatically extracted term should **not** be promoted to LOCKED merely because an agent thinks it is important. LOCKED status should come from author/user configuration.

## `author_concepts.json`

Stores author-defined concepts and forbidden implications or conceptual collapses.

## `claims.json`

Stores important claims together with properties such as:

- modality;
- polarity;
- conditions;
- exceptions;
- forbidden reformulations.

Agents may help draft these contracts, but high-stakes author terminology and theoretical distinctions should be human-reviewed whenever possible.

---

# 23. Generate SCHOLARLY_HANDOFF after Codex finishes

Example:

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

If some chunks were reused, do not pretend the whole run was freshly regenerated. Record provenance with options such as:

```text
--translated-chunk chunk0001
--retranslated-chunk chunk0017
--reused-chunk chunk0004
```

The command generates:

```text
SCHOLARLY_HANDOFF.json
HANDOFF.md
```

Immediately validate it:

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

Expected result:

```json
{
  "valid": true,
  "errors": []
}
```

In normal production, do **not** bypass verification with:

```text
--no-file-check
```

---

# 24. What SCHOLARLY_HANDOFF means

Schema v2 treats the pair below as canonical artifact identity:

```text
relative_path + sha256
```

OS-dependent absolute paths such as:

```text
R:\...
/mnt/r/...
```

are locators, not identity.

This allows a handoff created by Codex under WSL to be consumed by Claude Code under native Windows, provided both hosts see the same project tree.

If a hash does not match, do **not** edit the JSON hash manually just to make validation pass. Investigate whether the source or translator draft changed, restore the correct artifact, or generate a new handoff if a legitimate translator-side change occurred.

---

# 25. Claude Code Reviewer start procedure

Claude Code does **not** begin by retranslating the Korean paper.

First run:

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

If validation fails, stop the review and diagnose the handoff.

Then read:

```text
Korean source
Codex English draft
translation-audit.md
terminology.json
author_concepts.json
claims.json
SCHOLARLY_HANDOFF.json
HANDOFF.md
```

---

# 26. Copy-ready Claude Code Reviewer prompt

```text
Act as Reviewer / Publication Editor for this scholarly translation.

First validate SCHOLARLY_HANDOFF.json with normal file checking.
If validation fails, do not edit the translation; report the cause first.

Important constraints:
- Do not independently retranslate the Korean manuscript from scratch.
- Review the existing Codex draft against the Korean source.
- Do not overwrite the Codex translator artifact.
- Do not silently change LOCKED terminology.
- Do not strengthen or weaken claim force, negation, conditions, modality, or theoretical relations.

Review for:
1. semantic errors;
2. subtle concept drift;
3. epistemic strength;
4. terminology-family consistency;
5. negation / condition / modality;
6. academic English;
7. citation localization;
8. bibliography normalization;
9. publication readiness.

Make only justified local corrections.
For every substantive change, record BEFORE / AFTER / reason / change type / whether meaning changed in review-changes.md.

Required outputs:
- final-en.md
- publication-audit.md
- review-changes.md

If an issue requires human authority—such as official author romanization,
target-journal citation style, or genuine ambiguity in the source—leave it as an explicit open item rather than inventing a decision.
```

---

# 27. What the Reviewer may and may not change

Allowed change classes:

```text
semantic correction
academic-English editing
terminology consistency
citation localization
bibliography normalization
front-matter cleanup
```

Not allowed as silent reviewer behavior:

```text
retranslate the whole paper from scratch
modify the Korean source
overwrite the Codex translator draft
change LOCKED terminology without justification
strengthen or weaken a theoretical claim
remove negation
remove conditions
change modality
collapse an author-defined distinction
```

---

# 28. Reviewer outputs

Claude Code writes three separate files:

```text
final-en.md
publication-audit.md
review-changes.md
```

## `final-en.md`

The reviewed publication candidate.

## `publication-audit.md`

At minimum, check:

- remaining Korean text outside intentionally preserved material;
- citation localization and spacing;
- bibliography normalization policy;
- duplicate abstracts/front matter;
- terminology-family drift;
- academic-English fluency;
- source/claim fidelity after editorial changes;
- unresolved human-decision items.

## `review-changes.md`

For substantive edits, record:

```text
location
BEFORE
AFTER
reason
change type
meaning changed: yes/no
```

This file provides an auditable trace of what the reviewer changed and why.

---

# 29. Translation fidelity is not publication readiness

Keep these two judgments separate.

## `translation-audit.md`

Question:

```text
Did the English translation preserve the Korean argument accurately?
```

## `publication-audit.md`

Question:

```text
Is the reviewed English manuscript ready for a specific publication context?
```

Therefore this state is perfectly valid:

```text
translation fidelity = PASS
publication readiness = NOT READY
```

Possible reasons:

- official romanization of an author's name has not been confirmed;
- the target journal's citation style has not been specified;
- the source itself contains a wording or conceptual ambiguity.

These are not necessarily translation failures.

---

# 30. Final Reviewer Gate

After the three reviewer outputs exist:

```bash
python scripts/reviewer_gate.py \
  <TEMP>/SCHOLARLY_HANDOFF.json \
  --final-en <TEMP>/final-en.md \
  --publication-audit <TEMP>/publication-audit.md \
  --review-changes <TEMP>/review-changes.md
```

Expected result:

```json
{
  "valid": true,
  "errors": []
}
```

If this gate fails, the reviewer should not report the workflow as complete.

---

# 31. Minimal production recipe for one academic paper

## Step A — Codex Translator

Prompt:

```text
Translate the Korean academic paper in <PROJECT_DIR> using scholarly Korean-to-English mode.
You are the Translator.
Complete the nine-axis fidelity audit, create draft-en.md and translation-audit.md,
then generate SCHOLARLY_HANDOFF.json and HANDOFF.md and validate the handoff with normal file checking.
Do not create Claude's final reviewed version yourself; stop at the handoff boundary.
```

Codex completion criteria:

```text
Korean source preserved
Codex draft created
translation fidelity audited
SCHOLARLY_HANDOFF.json created
HANDOFF.md created
handoff validation = true
```

## Step B — Claude Code Reviewer

Prompt:

```text
Open SCHOLARLY_HANDOFF.json in <PROJECT_DIR>.
You are Reviewer / Publication Editor, not Translator.
Validate the handoff with normal file checking first.
Then review the Codex draft against the Korean source and the terminology/concept/claim contracts.
Do not retranslate the whole manuscript.
Make only justified local corrections, create final-en.md, publication-audit.md,
and review-changes.md, then pass reviewer_gate.py.
```

Claude completion criteria:

```text
final-en.md
publication-audit.md
review-changes.md
reviewer_gate valid = true
```

## Step C — Human finalization

Confirm any remaining open items, especially:

- official author romanization;
- affiliation names;
- target-journal style;
- bibliography style;
- final terminology for author-defined concepts;
- unresolved source ambiguity.

---

# 32. General book-translation outputs

The general `translate-book` pipeline typically creates the following under `{book_name}_temp/`:

```text
output.md
book.html
book.docx
book.epub
book.pdf
```

Important working files include:

```text
input.md
chunk0001.md ...
output_chunk0001.md ...
manifest.json
source_fingerprint.json
glossary.json
run_state.json
```

If a general translation is interrupted, rerunning the skill usually resumes from valid chunk outputs rather than retranslating everything.

---

# 33. Translation troubleshooting

## `Calibre ebook-convert not found`

Install Calibre and ensure `ebook-convert` is available in `PATH`.

## `Manifest validation failed`

Source chunks changed after splitting. Re-run conversion.

## `was created from different source bytes`

The temp directory belongs to a different source file.

Use one of these approaches:

- delete the old temp directory; or
- use a fresh `--temp-root`.

## Blank / empty output

Retranslate the affected chunk.

## Incomplete translation

Rerun the skill. Valid output chunks should be reused when possible.

## Scholarly handoff hash mismatch

Do **not** solve it by:

```text
manually editing the JSON hash
using --no-file-check as a production workaround
```

Instead:

1. check whether the source or draft changed;
2. confirm both machines see the same project tree;
3. restore the intended artifact if the wrong file is present;
4. if the translator artifact legitimately changed, generate a fresh handoff.

---

# 34. Frequently used one-line prompts

## Start Research-to-Skill work

```text
Read HANDOFF.md first, then run preflight, lock status, and git status before continuing.
```

## Add new research material

```text
Ingest this source into the Research-to-Skill project and execute the compile plan.
Check for duplicate/conflicting concepts and claims, preserve provenance and locators,
then validate and write a handoff.
```

## Independently verify the previous agent

```text
Verify the previous agent's work against source evidence and canonical research.json.
Correct only concrete errors, validate, and update HANDOFF.md.
```

## Codex scholarly translation

```text
Translate this paper in scholarly Korean-to-English mode.
Act only as Codex Translator and complete the nine-axis fidelity audit plus SCHOLARLY_HANDOFF.
```

## Claude scholarly review

```text
Validate SCHOLARLY_HANDOFF first and review the Codex translation against the Korean source.
Do not retranslate from scratch. Make only local justified corrections,
then create final-en, publication-audit, review-changes, and pass reviewer_gate.
```

---

# 35. Recommended division of labor

| Task | Codex | Claude Code | Human |
|---|---:|---:|---:|
| Large-scale source ingestion | **Primary** | Capable | — |
| Execute semantic compile plan | Primary | Primary | — |
| Provenance / locator verification | Capable | **Strong fit** | When needed |
| Research handoff writing | Primary | Primary | — |
| First Korean→English scholarly translation | **Default** | A/B only | — |
| Large chunked translation | **Primary** | Optional | — |
| Fine-grained source/draft comparison | Capable | **Primary** | When needed |
| Concept-family drift review | Capable | **Primary** | When needed |
| Epistemic-strength review | Primary | **Primary** | High-stakes cases |
| Academic-English polishing | Capable | **Primary** | — |
| Official author romanization | — | Open item | **Final authority** |
| Target-journal style decision | — | Open item | **Final authority** |

---

# 36. Operating patterns to avoid

## Research-to-Skill

Avoid:

- allowing Codex and Claude Code to write canonical project state concurrently;
- breaking a stale lock without checking whether another writer is active;
- treating derived Markdown as more authoritative than `research.json`;
- changing claim provenance without source evidence;
- running `compile --complete` while validation is failing;
- using `--cascade` without a recovery point.

## Scholarly translation

Avoid:

- translating every paper twice independently by default;
- letting Claude Code discard the Codex draft and start over during reviewer stage;
- silently changing LOCKED terminology;
- changing claim force for smoother English;
- weakening negation, conditions, or modal expressions;
- confusing translation fidelity with publication readiness;
- hiding hash mismatches behind bypass flags.

---

# 37. Recommended daily operating pattern

## Research

```text
collect sources
  ↓
Codex ingest + semantic integration
  ↓
validate + HANDOFF
  ↓
Claude independent verification when warranted
  ↓
validate + HANDOFF
  ↓
Human judgment where needed
```

A second verifier is most useful when the cost of error is high.

## Scholarly translation

```text
Codex Translator
  ↓
translation fidelity PASS
  ↓
SCHOLARLY_HANDOFF
  ↓
Claude Reviewer
  ↓
publication audit
  ↓
Human final decision
```

This is the recommended default production workflow.

---

# 38. Updating the software

## Research-to-Skill

```bash
git -C <BOOK_TO_SKILL_REPO> pull --ff-only
```

Refresh editable install if necessary:

```bash
python -m pip install -e <BOOK_TO_SKILL_REPO>
```

## Manually cloned translate-book skill

Codex:

```bash
git -C ~/.agents/skills/translate-book pull --ff-only
```

Claude Code:

```bash
git -C ~/.claude/skills/translate-book pull --ff-only
```

Before a high-stakes production run after an update, review repository changes and preserve a backup/handoff of active projects.

---

# 39. v1 software baseline referenced by this manual

## Research-to-Skill

```text
repository: icerain-cmd/book-to-skill
branch: master
merge baseline: 9355188b292ede45262d2871049385d310d6b106
```

## Scholarly translation

```text
repository: icerain-cmd/translate-book
branch: main
merge baseline: 89289c5be53610cd48959db699760396bee4ba60
```

If the repositories change substantially, this manual should be revised accordingly.

---

# 40. Ultra-short cheat sheet

## Research-to-Skill

Start:

```bash
research-to-skill preflight --project <PROJECT>
research-to-skill lock status --project <PROJECT>
```

Add material:

```bash
research-to-skill add <SOURCE> --project <PROJECT>
research-to-skill compile --project <PROJECT>
```

After semantic integration:

```bash
research-to-skill validate --project <PROJECT>
research-to-skill compile --project <PROJECT> --complete
```

End session:

```bash
research-to-skill validate --project <PROJECT>
research-to-skill handoff --project <PROJECT>
```

## Scholarly Korean → English

Codex:

```text
scholarly KO→EN → translation → nine-axis fidelity audit → SCHOLARLY_HANDOFF
```

Validate handoff:

```bash
python scripts/scholarly_handoff.py validate <TEMP>/SCHOLARLY_HANDOFF.json
```

Claude Code:

```text
source comparison → limited local correction → final-en + publication-audit + review-changes
```

Final gate:

```bash
python scripts/reviewer_gate.py \
  <TEMP>/SCHOLARLY_HANDOFF.json \
  --final-en <TEMP>/final-en.md \
  --publication-audit <TEMP>/publication-audit.md \
  --review-changes <TEMP>/review-changes.md
```

**These four operations capture the core production workflow.**

---

# License and attribution

This English manual is original documentation in `icerain-cmd/codex-claude-research-workflows` and is released under **CC BY 4.0** unless otherwise noted.

The software repositories documented here remain under their own licenses. See the repository's `LICENSE` and `THIRD_PARTY_NOTICES.md` for details.

Maintained by **Lee Yong Wook** (`icerain-cmd`).

This documentation was developed with AI assistance. It is not official OpenAI or Anthropic documentation and does not imply endorsement, sponsorship, or affiliation with either company.
