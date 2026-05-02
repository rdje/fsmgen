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
- [../../COMPOSITION_LEGACY_MAPPING.md](../../COMPOSITION_LEGACY_MAPPING.md)
- [../../../ROADMAP_STATUS.md](../../../ROADMAP_STATUS.md)
- [../../../ROADMAP_V2.md](../../../ROADMAP_V2.md)
- [../../../COMMIT.md](../../../COMMIT.md)

These should stay precise and sometimes narrower than the book.

`COMMIT.md` is the process safety reference: every completed task, slice, lane,
or task-scoped activity must close with that workflow before the next work
starts, so crash recovery and agent handoff can resume from task-scoped
commits instead of a dirty worktree.

## What The Old User Guide Still Does

[../../USER_GUIDE.md](../../USER_GUIDE.md) still remains the broad live
reference during the migration.

Use it when:

- a detail has not been fully split into the book yet
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
- focused docs still carry some of the most exact normative boundaries
- the old guide remains authoritative when a topic has not been fully split yet
