# BOOK-COOKBOOK-COMPOSITION-RUNNABLE: Make Cookbook Composition Recipes Inline-Runnable

## Metadata

- Tree ID: `BOOK-COOKBOOK-COMPOSITION-RUNNABLE`
- Status: `pending`
- Roadmap lane: `R14` (documentation-synchronization invariant)
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

The cookbook chapter (`docs/book/src/12-cookbook.md`) opens with "This
chapter collects practical, copyable patterns." The prior slice
`BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS` honestly demoted cookbook
composition recipes 3, 4, 5 (and 7) to `text` because they were
multi-file schematics that referenced external child sources and so
could not be copy-pasted and generated as-is.

That was the correct interim fix, but a `text` recipe is not the
"copyable pattern" the cookbook promises. Composition examples *can*
be self-contained: the active composition contract realizes embedded
generated child roots, embedded `?rtlif` metadata roots, and (for the
single-child C1 lane) port-inferred tops. The composition test suite
(`t/101-composition-explicit-link-implicit-ports.t`) carries minimal
known-good patterns.

This slice upgrades cookbook recipes 3, 4, 5 from `text` schematics to
self-contained, inline-runnable `lisp` examples, each grounded in a
pattern verified to pass `./bin/fsmgen --check-json`, and each picked
up by the `t/1377` build gate so they cannot silently regress.

## Verified patterns (all confirmed `--check` success standalone)

- C1 single embedded child, inferred ports: `(?top ... (?fsmc:core
  worker_src))` + embedded `(?fsm:worker_src ...)`.
- C2 two embedded children, slash-delimited wiring `/src/dst/`:
  `(?top ... (?fsmc:producer producer_src) (?fsmc:consumer
  consumer_src) (?wiring ... /start/producer.go/ ...))` + embedded
  `(?fsm:producer_src ...)` + `(?fsm:consumer_src ...)`.
- C3 external RTL with embedded `?rtlif` and structural actual
  defaults: `(?top ... (?rtl:uart_tx) (?wiring /=8'hA5/uart_tx.data_in/
  /=open/uart_tx.enable/ ...))` + embedded `(?rtlif:uart_tx ...)`.

The key correction is the wiring spelling: composition wiring uses the
slash-delimited `/source/dest/` form, not the `(source dest)` list
form the demoted schematics had used.

## Non-Goals

- Recipe 6 (package) stays `text`: a file containing a `?pkg:` root is
  a package container that "does not generate HDL directly."
- Recipe 7 (typed aggregate) stays `text`: an aggregate top port needs
  a child endpoint to infer its declared aggregate contract, which
  cannot be expressed in a minimal self-contained recipe without
  obscuring the point.
- Chapter 05/06 composition teaching snippets stay schematic `text`:
  they intentionally illustrate isolated root/port/wiring shapes, and
  forcing embedded children into each would obscure the specific point
  of each snippet.
- No validator, parser, scheduler, backend, or runtime change.

## Acceptance Criteria

- Cookbook recipes 3, 4, 5 become self-contained `lisp` blocks that
  pass `./bin/fsmgen --check-json` (verified by `t/1377`).
- Each upgraded recipe keeps its "Use this when:" list and gains a
  brief walkthrough consistent with recipes 9-13.
- `t/1377` reports the increased standalone count (was 11) with zero
  failures; the rest of the book-audit family stays green.
- mdBook builds clean; `git diff --check` clean; live docs synced.
- Each leaf committed through `COMMIT.md`.

## Task Tree

- ID: `BOOK-COOKBOOK-COMPOSITION-RUNNABLE`
  Status: `pending`
  Goal: `Upgrade cookbook composition recipes 3/4/5 to verified inline-runnable lisp examples.`
  Children:
    `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.1`,
    `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.2`

- ID: `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.1`
  Status: `pending`
  Goal: `Select the slice; record verified patterns and scope.`
  Acceptance: `Task tree committed before any book change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.2`
  Status: `pending`
  Goal: `Replace recipes 3/4/5 with verified runnable lisp + walkthroughs; re-run t/1377 + book-audit family.`
  Acceptance: `t/1377 standalone count increases with 0 failures; audits green.`
  Verification: `prove -Iperl t/1377 t/1376 t/1305 t/1307 t/1332; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.1` | `pending` | Selection commit before any book change. |
| 2 | `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.2` | `pending` | Upgrade recipes + revalidate. |

## Decisions

- `2026-05-29`: Ground every upgraded recipe in a pattern lifted from
  `t/101`, which the composition suite already asserts generates. Do
  not fabricate composition wiring from scratch — the repo's own
  legacy composition samples (`fsm/trial_2.fsm`) do not even
  `--check` cleanly, so an unverified inline recipe would risk
  shipping a subtly-wrong "signoff" example.

## Open Questions / Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.1` | `mdbook build docs/book`; `git diff --check` | `pending` |
| `2026-05-29` | `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.2` | `prove -Iperl t/1377 t/1376 t/1305 t/1307 t/1332`; `mdbook build docs/book`; `git diff --check` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.1` | `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.1: select cookbook composition recipes runnable` | `pending commit hash` |
| `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.2` | `BOOK-COOKBOOK-COMPOSITION-RUNNABLE.2: ship cookbook composition recipes runnable` | `pending commit hash` |

## Changelog

- `2026-05-29`: Created task tree to upgrade cookbook composition
  recipes 3/4/5 from honest `text` schematics (left by the prior
  example-correctness slice) to verified inline-runnable `lisp`
  examples, closing the gap between the cookbook's "copyable
  patterns" promise and composition's multi-file reality.
