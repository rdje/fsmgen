# `LIVE_ACHIEVEMENT_STATUS.md` Present-Value Audit

- Date: `2026-08-01`
- Owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11`
- Audited revision: `e8bd8f05ad8e814f2121f886f8425ed7d0c99f43`
- Lifecycle outcome: retire, independently selected by the director
- Frozen file changed by the audit commit: no; retirement is a later `.11` slice

## Question

Does `LIVE_ACHIEVEMENT_STATUS.md` still answer a present reader question that
the current task-tree, bounded Memory, decision/fact, mdBook, and Git layers do
not answer well enough? The answer must be independent of the retired
`CHANGES.md`: that document cannot serve as a replacement in this comparison.

Size alone does not decide the outcome. This audit measures provenance,
current accuracy, unique presentation, consumers, canonical overlap, and exact
recovery before asking the director to retain, retire, or re-form the file.

## Exact identity and provenance

| Evidence | Value |
| --- | --- |
| introduced by | `d4c8d1a9213d12d6e6fcd4bef20aadd4f3e6c4fa` on `2026-05-10` |
| last changed by / recovery revision | `b4d07fee5ffd6621503007958dcac3af8d44b345` on `2026-06-01` |
| current Git blob | `98a6c69bf9e81b35fd80d5606dfbb80852281e93` |
| SHA-256 | `46c3c8ad2a0b7375a02b0a111bcc65410f78e0dd1df97709aeabe5f97b735d18` |
| lines / bytes / longest line | `16,618` / `955,308` / `358` |
| commits that touched the path | `1,339` |
| commits after the freeze through the audited revision | `1,784` |

The initial object was 12 lines / 698 bytes. The final object is byte-identical
at the last-changing revision and the audited revision. Exact recovery is:

```sh
git show b4d07fee5ffd6621503007958dcac3af8d44b345:LIVE_ACHIEVEMENT_STATUS.md \
  | shasum -a 256
```

The expected digest is the SHA-256 above. This reconstruction reads the
project's required Git history and writes no off-volume project data.

## What the file actually contains

The opening contract says the file tracks the latest completed roadmap-aligned
slice for fast recovery. Its measured content is a much broader hand-written
journal:

- 1,289 level-two entries, followed by a headingless continuation through
  `2026-06-01`;
- 32 headings explicitly recording selection rather than completion;
- 643 `Completed` bullets and 317 `Validation passed` bullets;
- 192 recorded active-task values and 178 recorded frontier values, all now
  historical snapshots;
- entries from `2026-05-10` through `2026-06-01`, with mixed insertion and
  append ordering rather than one stable current projection.

The file therefore has historical narrative value, but it does not satisfy its
claimed live question. It has been frozen for 1,784 subsequent commits, and it
mixes completed achievements with selected work and obsolete recovery state.

## Current consumers

This deterministic census reports 55 tracked referring files:

```sh
rg -l 'LIVE_ACHIEVEMENT_STATUS\.md' --glob '!LIVE_ACHIEVEMENT_STATUS.md' \
  | sort
```

Classification of every result is:

- product, compiler, runtime, build, or test content consumers: zero;
- current executable references: zero;
- current policy/navigation references: the bootstrap and commit contracts,
  README route, bounded Memory/task frontier, mdBook reference map, current
  decisions/audits/fact card, and live-document route/surface registries;
- historical evidence references: prior workflow, decision, task, audit, and
  sealed-task records.

The README route is a real human navigation benefit: a reader can browse one
large historical digest without querying Git. The surface registry verifies
only the frozen digest; neither registry interprets the content. Historical
references remain true if the exact object becomes revision-retrievable, so
they are not migration consumers.

## Canonical overlap and distinct value

| Reader question | Current authority |
| --- | --- |
| What is active and what is next? | `MEMORY.md`, then `docs/TASK_TREE.md` and the owning task node |
| What completed, and with what acceptance evidence? | the owning `docs/tasks/*.md` node plus its work-unit Git commit |
| What does shipped behavior do? | `docs/book/src/SUMMARY.md` and the linked feature chapters |
| Why was a cross-cutting choice made? | `docs/decisions/INDEX.md` and the selected decision |
| What durable fact was established? | `KNOWLEDGE_MAP.md` and its canonical fact card |
| What exactly did a historical revision contain? | `git show`, `git log`, and the exact commit tree |

The file's facts overlap those authorities, but its presentation does not: it
is a single, directly browsable, prose achievement digest from a 23-day period.
That presentation is the only independent retention case found. It is not a
current view, a recovery input, a complete project history, or a canonical
behavior/evidence authority.

## Options for director selection

1. **Retire the live path (audit recommendation).** Preserve the exact object
   with a checked revision/digest retrieval contract, remove only current
   policy/navigation/registry consumers, and leave historical evidence intact.
   This avoids presenting a stale partial journal as live project status.
2. **Retain it frozen.** Keep the direct root-level historical browse path and
   its SHA-256 guard. Rename its documented role from live/recovery status to a
   frozen May-June 2026 digest; it remains intentionally partial and unbounded.
3. **Re-form a bounded view.** Define a genuinely wanted reader query first,
   then derive a bounded view from canonical task/Git/book sources. This adds a
   maintained projection and should be selected only if the direct digest is
   worth its new generation, integrity, and navigation contract.

The director subsequently selected option 1. Decision `0048` owns the atomic
live-path retirement and exact version-retention contract; this audit remains
the unchanged-before-selection evidence.
