# ISF-COOKBOOK-WALKTHROUGHS: Add Walkthrough Explanations To Cookbook ISF Recipes

## Metadata

- Tree ID: `ISF-COOKBOOK-WALKTHROUGHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Address the user's standard that "every example shall be thoroughly
explained — examples will help users understand ISF and FSM formats,
not just the prose of the documentation." The cookbook ISF recipes
shipped by `ISF-COOKBOOK-RECIPES-G1.2` (recipes 9-13) currently
include only a "Use this when:" usage list. They do not walk through
each clause. This slice adds a clause-by-clause walkthrough beneath
each recipe so the reader learns the syntax by reading the example.

## Non-Goals

- Do not modify the `.isf` source itself. Each fixture already
  parses+lowers.
- Do not touch the existing 8 `.fsm` recipes (1-8) in this slice.
  A future slice can extend the same walkthrough pattern to those.
- Do not add validator-level test fixtures from these examples.

## Acceptance Criteria

- Each of recipes 9-13 in `docs/book/src/12-cookbook.md` includes:
    * the existing source block (unchanged),
    * the existing "Use this when:" bullet list,
    * a new clause-by-clause walkthrough section that names each
      top-level clause used by the recipe and explains what it
      contributes to the schedule.
- The walkthroughs use the prose voice already established by the
  rest of the cookbook (terse, second-person where appropriate).
- The walkthroughs cover the new ISF clauses the recipe introduces
  (`(actor ...)`, `(clock ...)`, `(reset ...)`, `(interface ...)`,
  `(transaction ...)`, `(on ...)`, `(wait ...)`, `(complete ...)`,
  `(spawn ...)`, `(await_all ...)`, `(do ...)`, `(params ...)`,
  `(rule ...)`, `(trigger ...)`, `(repeat ...)`).
- Audits `t/1305`, `t/1307`, `t/1332` continue to pass.
- mdBook builds clean; `git diff --check` clean.
- Live docs reflect the slice.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-COOKBOOK-WALKTHROUGHS`
  Status: `done`
  Goal: `Add clause-by-clause walkthroughs to cookbook recipes 9-13.`
  Children:
    `ISF-COOKBOOK-WALKTHROUGHS.1`,
    `ISF-COOKBOOK-WALKTHROUGHS.2`

- ID: `ISF-COOKBOOK-WALKTHROUGHS.1`
  Status: `done`
  Goal: `Select the cookbook walkthroughs slice.`
  Acceptance: `Task tree exists.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-COOKBOOK-WALKTHROUGHS.2`
  Status: `done`
  Goal: `Ship the walkthroughs for recipes 9-13 plus live-doc updates.`
  Acceptance: `Each recipe has a clause walkthrough; audits still pass.`
  Verification: `prove -Iperl t/1305 t/1307 t/1332; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` added clause walkthroughs to recipes 9-13. |

## Decisions

- `2026-05-29`: Walkthroughs use a "Walkthrough" sub-heading per
  recipe to keep the pattern uniform. The walkthrough names each
  clause used by the recipe in source order and explains what it
  contributes to the lowered schedule.
- `2026-05-29`: Limit walkthroughs to the clauses each specific
  recipe uses. A later slice can extend the cookbook with a
  "shared clauses reference" appendix if cross-recipe duplication
  becomes a problem.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-COOKBOOK-WALKTHROUGHS.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-29` | `ISF-COOKBOOK-WALKTHROUGHS.2` | `prove -Iperl t/1305 t/1307 t/1332` (Files=3, Tests=709); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-COOKBOOK-WALKTHROUGHS.1` | `2eaa48b6 ISF-COOKBOOK-WALKTHROUGHS.1: select cookbook walkthroughs` | Selection commit. |
| `ISF-COOKBOOK-WALKTHROUGHS.2` | `ISF-COOKBOOK-WALKTHROUGHS.2: ship cookbook walkthroughs` | `pending` |

## Changelog

- `2026-05-29`: Created task tree to add clause-by-clause
  walkthroughs to the five ISF cookbook recipes. Walkthroughs make
  the recipes self-teaching rather than mere illustrations.
- `2026-05-29`: Shipped `.2`. Added a `**Walkthrough.**` paragraph
  beneath the "Use this when:" list for each of recipes 9-13.
  Each walkthrough names every top-level clause used by the
  recipe in source order and explains its contribution to the
  schedule (clock/reset polarity, port widths, transaction entry
  guard, repeat counter initialization, generated-child vs local
  vs rule-trigger differences, accept-path vs fail-closed
  semantics for parameter overrides).
