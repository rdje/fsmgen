# FSMGen User Guide

This guide remains a compatibility waypoint and migration reference while the
progressive mdBook is being built under `docs/book/`.

Recommended entry points now are:

- `docs/book/src/SUMMARY.md` for the book table of contents
- `docs/book/src/00-introduction.md` for the conceptual starting point
- `docs/book/src/90-reference-map.md` for the old-guide-to-book map
- `docs/book/src/10-errors-strict-mode-and-troubleshooting.md` for runtime
  diagnostic and strict-mode guidance
- `docs/book/src/12-cookbook.md` for copyable patterns

This file now points migrated section families at the owning book chapters.
Contractual user-facing material should be moved into the mdBook chapter that
owns the topic. When this guide and the book differ, treat the difference as a
documentation bug to reconcile rather than as permission to leave normative
language only in this compatibility guide.
Runtime diagnostics should point at the mdBook chapter map or owning chapter,
not at this file as the primary normative target.

## 1) What FSMGen is

Migrated to `docs/book/src/00-introduction.md`.
The book owns the product overview, output/back-end boundaries, and current
product boundaries.

## 2) Core concepts

Migrated to these mdBook chapters:

- `docs/book/src/02-language-basics.md` for core syntax, assignment timing,
  expressions, guards, and authoring guidance
- `docs/book/src/03-decision-trees-and-fsms.md` for direct roots, state DTs,
  non-state DTs, transitions, and direct FSM/DT structure
- `docs/book/src/04-symbols-types-and-imports.md` for parameters, constants,
  enums, types, imports, and declarative scope
- `docs/book/src/07-packages-and-sharing.md` for package sources and package
  lookup
- `docs/book/src/08-type-inference-and-aggregate-data.md` for aggregate data
  and type inference

This guide keeps the old section heading as a compatibility waypoint during
the split.

## 2.1) Currently supported `.fsm` constructs (live reference)

Migrated to the mdBook. Use these chapter homes as the normative contract:

- Direct root and DT/FSM structure:
  `docs/book/src/03-decision-trees-and-fsms.md`
- Guard, suffix, expression, assignment, and update surfaces:
  `docs/book/src/02-language-basics.md`
- Declarations, package imports, and type aliases:
  `docs/book/src/04-symbols-types-and-imports.md` and
  `docs/book/src/07-packages-and-sharing.md`
- Aggregate data and type-aware behavior:
  `docs/book/src/08-type-inference-and-aggregate-data.md`
- Composition root shape, ports, child sources, `.rtlif`, links, structural
  actuals, and current lanes: `docs/book/src/05-composition-basics.md` and
  `docs/book/src/06-composition-advanced.md`
- Strict mode, unsupported syntax, diagnostics, and backend expectations:
  `docs/book/src/10-errors-strict-mode-and-troubleshooting.md`

When this guide and the book differ, the difference is a documentation bug.
Update the owning book chapter first.

## 3) Basic usage

Migrated to the mdBook. Use these book chapters as the normative user-facing
homes:

- `docs/book/src/01-first-fsm.md` for first-run examples
- `docs/book/src/09-generated-hdl-debugging-and-inspection.md` for CLI usage,
  options, report-only JSON modes, input resolution, tracing, and HDL
  inspection
- `docs/book/src/05-composition-basics.md` and
  `docs/book/src/06-composition-advanced.md` for composition examples and
  structural linking details

This heading remains as a compatibility waypoint during the guide split.

## 4) Useful options

Migrated to `docs/book/src/09-generated-hdl-debugging-and-inspection.md`.
The book owns the current option semantics for output paths, target language
aliases, trace/debug flags, source search paths, extension loading, capability
manifests, check JSON, semantic JSON, HDL validation, quiet mode, and help.

## 5) Input resolution and FSMLIB

Migrated to `docs/book/src/09-generated-hdl-debugging-and-inspection.md` and
`docs/book/src/07-packages-and-sharing.md`.
The book owns the current source-resolution order for bare names, repeated
`--path` roots, `FSMLIB`, relative paths, absolute paths, and package lookup.

## 6) Debug workflow

Migrated to `docs/book/src/09-generated-hdl-debugging-and-inspection.md`.
The book owns the current trace verbosity, trace log, origin metadata, JSON
stdout, and practical debug loop guidance.

## 7) Typed extensions

Migrated to `docs/book/src/11-extensions-and-embedding.md`.
The book owns the current typed-extension definition, non-goals, hook names,
context accessor behavior, programmatic loading, CLI/config loading, facade
boundary, debug-runtime embedding seam, and result-surface guidance.

## 8) External compatibility flow

Migrated to `docs/book/src/11-extensions-and-embedding.md`.
The legacy `generate_fsm_hdl.pl` flow remains environment-specific
compatibility, not the main forward surface.

## 9) Troubleshooting

Migrated to `docs/book/src/10-errors-strict-mode-and-troubleshooting.md`.
The book owns parser/shape errors, composition planning errors, direct
generation errors, strict-mode guidance, diagnostic-code guidance, backend
expectations, unsupported syntax, practical debug checklist, and regression
guidance.

## 10) Practical authoring guidelines

Migrated to `docs/book/src/02-language-basics.md`.
The book owns assignment-operator timing guidance, delayed-pulse guidance,
guard readability guidance, and bring-up checks.
