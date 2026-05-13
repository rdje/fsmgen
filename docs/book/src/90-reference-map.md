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

## What Still Lives Outside The Book

Some docs are intentionally still focused references:

- [../../COMPOSITION_SCOPE.md](../../COMPOSITION_SCOPE.md)
- [../../EXTENSION_MODEL.md](../../EXTENSION_MODEL.md)
- [../../REGRESSION_CORPUS.md](../../REGRESSION_CORPUS.md)
- [../../ISF_SPEC.md](../../ISF_SPEC.md)
- [../../ISF_PUBLIC_INTERFACE_CONTRACT.md](../../ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [../../BIN_FSMGEN_IMPORT_TREE.md](../../BIN_FSMGEN_IMPORT_TREE.md)
- [../../COMPOSITION_LEGACY_MAPPING.md](../../COMPOSITION_LEGACY_MAPPING.md)
- [../../../ROADMAP_STATUS.md](../../../ROADMAP_STATUS.md)
- [../../../ROADMAP_V2.md](../../../ROADMAP_V2.md)
- [../../../COMMIT.md](../../../COMMIT.md)

These should stay precise and sometimes narrower than the book.

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

The migration is still ongoing:

- the book is the progressive learning surface
- runtime diagnostics now use book-owned documentation hints for the current
  supported, strict-mode, and package boundaries
- Chapter 09 now owns the operational CLI/options, report-only JSON mode,
  source-resolution, and trace/debug workflow material from the old guide
- Chapter 02 now owns the practical authoring guidance for assignment
  operator choice, guard readability, and bring-up checks
- focused docs may still carry narrow maintainer or machine-contract detail
- the old guide remains a migration checklist, not a place to leave
  user-facing contract stranded
