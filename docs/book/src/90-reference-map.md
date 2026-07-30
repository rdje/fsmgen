# Reference Map

This chapter helps you navigate between the new book and the older focused
reference docs.

## What The Book Is For

Use the book when you want:

- progressive learning
- example-rich explanations
- topic-based navigation
- a friendlier path from beginner to advanced use

Start here:

- [Introduction](00-introduction.md)
- [Your First FSM](01-first-fsm.md)
- [Cookbook](12-cookbook.md)
- [Implementation Blueprint](15-implementation-blueprint.md)

## What Still Lives Outside The Book

Some docs are intentionally still focused references:

- [../../COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md)
- [../../EXTENSION_MODEL.md](../../EXTENSION_MODEL.md)
- [../../REGRESSION_CORPUS.md](../../REGRESSION_CORPUS.md)
- [../../FEATURE_BACKLOG.md](../../FEATURE_BACKLOG.md)
- [../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md](../../ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
- [../../ISF_SPEC.md](../../ISF_SPEC.md)
- [../../ISF_PUBLIC_INTERFACE_CONTRACT.md](../../ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [../../BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md](../../BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md)
- [../../BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md)
- [../../BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md)
- [../../BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md)
- [../../BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md](../../BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md)
- [../../BIN_FSMGEN_IMPORT_TREE.md](../../BIN_FSMGEN_IMPORT_TREE.md)
- [../../TASK_TREE.md](../../TASK_TREE.md)
- [../../tasks/ISF-PUBLIC-CONTRACT-SYNC.md](../../tasks/ISF-PUBLIC-CONTRACT-SYNC.md)
- [../../COMPOSITION_LEGACY_MAPPING.md](../../COMPOSITION_LEGACY_MAPPING.md)
- [../../../MEMORY.md](../../../MEMORY.md)
- [../../../ROADMAP_V2.md](../../../ROADMAP_V2.md)
- [../../../README_POLICY.md](../../../README_POLICY.md)
- [../../../TASK_ACCEPTANCE.md](../../../TASK_ACCEPTANCE.md)
- [../../../COMMIT.md](../../../COMMIT.md)

These should stay precise and sometimes narrower than the book.

`MEMORY.md` is the bounded resume pointer and `TASK_TREE.md` indexes the live
work frontier. `ROADMAP_V2.md` carries high-level direction.
`ROADMAP_STATUS.md` is retained only as a frozen legacy record under decision
0025 and must not be used as current status. `CHANGES.md` records one concise
entry for every completed slice; `DEVELOPMENT_NOTES.md` is updated only when a
slice produces durable engineering rationale that lacks a better canonical
home. `LIVE_ACHIEVEMENT_STATUS.md` remains frozen with `ROADMAP_STATUS.md`
pending their scheduled lifecycle review.

`README_POLICY.md` is the project-neutral landing-page maintenance standard:
adopting projects keep the canonical tracked copy at repository root beside
`README.md`. It defines stable content, routes dynamic detail elsewhere, and
requires deterministic line/byte budgets in both pre-commit and CI.

`TASK_ACCEPTANCE.md` is the project-neutral evidence-backed code-slice
standard. FSMGen's registered checker reads data-only staged-path and evidence
registries, requires fresh one-file ROOT CAUSE / ADDRESSED / NO REGRESSION
boxes for matching implementation changes, and leaves actual behavioral proof
to the cited focused and CI oracles.

`ISF_DOWNSTREAM_INTEGRATION_SPEC.md` is the canonical human handoff contract
for SPECFORGE-style downstream consumers. The book includes that file directly
in the ISF downstream integration chapter, so edits to the handoff document and
the book view cannot drift apart.

`BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md` records the selected
implementation-blueprint structure for future backend-language variants. The
book-facing entry point is Chapter 15, which links to the portable API, host
abstraction, and parity-harness selectors instead of duplicating their full
maintainer detail.

`BIN_FSMGEN_IMPORT_TREE.md` is the live maintainer-facing architecture map for
the `bin/fsmgen` runtime spine. It is not a tutorial chapter, but it is the
right place to verify whether the saved CLI/import-tree picture still matches
the source at the start of an engineering session.

Keep detailed static measurements in that focused doc; the book should point to
the current maintainer map rather than duplicate volatile line-count tables.

`COMMIT.md` is the process safety reference: every completed task, slice, lane,
or task-scoped activity must close with that workflow before the next work
starts, so crash recovery and agent handoff can resume from task-scoped
commits instead of a dirty worktree.

Tracked raw standards PDFs under `docs/vendor/` are local reference artifacts
for future task-tree-owned evidence or design probes. The current set includes
the Arm AMBA AXI specification plus Accellera SystemRDL 2.0, Portable Test and
Stimulus 3.0, and UVM 1.2 references. These PDFs do not by themselves ship
standard extraction, parser, lowering, scheduler, or HDL behavior.

`TASK_TREE.md` is the active-tree and PNT frontier reference. For ISF feature
work, it points to the reusable synchronization checklist in
`docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md` so public specs, book chapters,
contracts, manifests, tests, live docs, and commit hygiene stay aligned without
duplicating the checklist in every feature tree.

## What The Old User Guide Still Does

[../../USER_GUIDE.md](../../USER_GUIDE.md) still remains the broad migration
reference during the migration, but it should no longer be the only home for
normative user-facing contract. When the guide contains contractual language,
that language should be dispatched into the chapter that owns the topic.

Use it when:

- checking whether a detail still needs to be split into the book
- you want the current monolithic reference section
- you are comparing older sections against the new chapter layout

## Old Guide To Book Map

- `1) What FSMGen is` -> [Introduction](00-introduction.md)
- `2) Core concepts` -> [Language Basics](02-language-basics.md)
- `2.1) Currently supported .fsm constructs` -> split across Chapters 02-08
- `3) Basic usage` -> [Your First FSM](01-first-fsm.md) and
  [Generated HDL, Debugging, and Inspection](09-generated-hdl-debugging-and-inspection.md)
- `4) Useful options` ->
  [Generated HDL, Debugging, and Inspection](09-generated-hdl-debugging-and-inspection.md)
- `5) Input resolution and FSMLIB` -> [Packages and Sharing](07-packages-and-sharing.md)
- `6) Debug workflow` ->
  [Generated HDL, Debugging, and Inspection](09-generated-hdl-debugging-and-inspection.md)
- `7) Typed extensions` -> [Extensions and Embedding](11-extensions-and-embedding.md)
- `8) External compatibility flow` -> [Extensions and Embedding](11-extensions-and-embedding.md)
- `9) Troubleshooting` -> [Errors, Strict Mode, and Troubleshooting](10-errors-strict-mode-and-troubleshooting.md)
- `10) Practical authoring guidelines` -> spread through the chapter intros and
  [Cookbook](12-cookbook.md)

## Migration Status

The mdBook scaffold is real and buildable now.

The old guide's major section families now have book homes:

- `1) What FSMGen is` -> Chapter 00
- `2) Core concepts` and `2.1) Currently supported .fsm constructs` ->
  Chapters 02-08 and Chapter 10
- `3) Basic usage`, `4) Useful options`, `5) Input resolution and FSMLIB`, and
  `6) Debug workflow` -> Chapter 09
- `7) Typed extensions` and `8) External compatibility flow` -> Chapter 11
- `9) Troubleshooting` -> Chapter 10
- `10) Practical authoring guidelines` -> Chapter 02

The migration discipline remains active:

- the book is the progressive learning surface and primary normative target
- runtime diagnostics now use book-owned documentation hints for the current
  supported, strict-mode, and package boundaries
- Chapter 09 now owns the operational CLI/options, report-only JSON mode,
  source-resolution, and trace/debug workflow material from the old guide
- Chapter 02 now owns the practical authoring guidance for assignment
  operator choice, guard readability, and bring-up checks
- Chapter 11 now explicitly owns the typed-extension definition, non-goals,
  and CLI/config loading prerequisites
- focused docs may still carry narrow maintainer or machine-contract detail
- the old guide remains a migration checklist and compatibility reference, not
  a place to leave user-facing contract stranded or to introduce new normative
  wording without updating the owning book chapter
- sections 3-10 of the old guide have already been reduced to chapter pointers
  so operational and extension/troubleshooting prose does not drift in two
  places
- sections 1-2.1 of the old guide have also been reduced to chapter pointers
  so product, direct-language, declaration/import, aggregate, composition, and
  diagnostic contract prose does not drift in two places
- the remaining cleanup is duplication reduction and drift prevention, not
  finding homes for the major guide sections from scratch
