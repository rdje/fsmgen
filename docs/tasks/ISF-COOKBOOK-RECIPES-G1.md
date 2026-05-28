# ISF-COOKBOOK-RECIPES-G1: Add ISF Recipes To Cookbook Chapter

## Metadata

- Tree ID: `ISF-COOKBOOK-RECIPES-G1`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-27`
- Last updated: `2026-05-27`
- Owner: repo-local workflow

## Goal

Address gap G1 from
[`docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md`](../audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md):
the cookbook chapter (`docs/book/src/12-cookbook.md`) currently
contains zero ISF recipes. `spawn`, `rule`, `trigger`, and
`transaction` mention count is zero. A new reader following the
book in order reaches the cookbook with no compact end-to-end ISF
examples even though ISF is the primary authoring layer for new
work.

This slice adds five focused ISF recipes that follow the existing
cookbook style (numbered heading, code block, "Use this when:"
list).

## Non-Goals

- Do not modify the existing 8 `.fsm` recipes. They remain valid
  reference patterns for the IAL0 layer.
- Do not introduce ISF features that are still backlog or partially
  shipped. Each recipe must be a shipped, accepted shape.
- Do not change validator behavior, tests, or runtime.

## Acceptance Criteria

- `docs/book/src/12-cookbook.md` gains five new ISF recipes
  appended after recipe 8:
    9. A Small ISF Actor (basic transaction with on/wait/complete)
    10. Generated Child Via Spawn (parent spawns a worker with
        same-body await_all drain)
    11. Blocking Do Call With Parameter Override (parameterized do
        with same-value override)
    12. Rule-Triggered Transaction (rule triggers a parameterized
        worker)
    13. Repeat-Body With Generated Do (top-level repeat-body
        plain generated-child do)
- Each recipe shows a complete, copyable `.isf` source. The recipes
  parse and lower cleanly through `FSM::Adapter::ISF`/
  `FSM::Scheduler::ISF`.
- Each recipe includes a 2-4 bullet "Use this when:" list.
- Audits `t/1305-isf-book-feature-matrix-audit.t`,
  `t/1307-isf-loop-body-doc-truth-audit.t`,
  `t/1332-isf-atl-doc-status-audit.t` continue to pass.
- mdBook builds clean; `git diff --check` clean.
- Live docs reflect the slice.
- The slice is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-COOKBOOK-RECIPES-G1`
  Status: `pending`
  Goal: `Address audit gap G1 by adding ISF recipes to the cookbook chapter.`
  Children:
    `ISF-COOKBOOK-RECIPES-G1.1`,
    `ISF-COOKBOOK-RECIPES-G1.2`

- ID: `ISF-COOKBOOK-RECIPES-G1.1`
  Status: `pending`
  Goal: `Select the cookbook ISF recipes slice; record scope and recipe list.`
  Acceptance: `Task tree exists and is committed before any cookbook change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-COOKBOOK-RECIPES-G1.2`
  Status: `pending`
  Goal: `Ship the five ISF cookbook recipes plus live-doc updates.`
  Acceptance: `Five recipes added, each parses/lowers; audits still pass.`
  Verification: `prove -Iperl t/1305 t/1307 t/1332; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Both leaves shipped. `.2` added recipes 9-13 to cookbook chapter 12; each verified to parse+lower cleanly. Audits reverified. |

## Decisions

- `2026-05-27`: Five recipes chosen to span the core ISF authoring
  surface: basic actor, spawn, parameterized blocking do, rule
  trigger, and repeat-body generated do. Each recipe is a complete
  fixture, so the user can copy-paste it.
- `2026-05-27`: Cross-domain and aggregate examples deliberately
  excluded from this slice to keep each recipe small. Those land in
  the broader 13-section gap slices (G6 and G7).

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-27` | `ISF-COOKBOOK-RECIPES-G1.1` | `mdbook build docs/book`; `git diff --check` | `PASS`; selection-only commit |
| `2026-05-27` | `ISF-COOKBOOK-RECIPES-G1.2` | each of recipes 9-13 parses+lowers (5/5 OK); `prove -Iperl t/1305 t/1307 t/1332` (Files=3, Tests=709); `mdbook build docs/book`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-COOKBOOK-RECIPES-G1.1` | `bc32972e ISF-COOKBOOK-RECIPES-G1.1: select cookbook ISF recipes` | Selection commit. |
| `ISF-COOKBOOK-RECIPES-G1.2` | `ISF-COOKBOOK-RECIPES-G1.2: ship cookbook ISF recipes` | `pending commit hash` |

## Changelog

- `2026-05-27`: Created task tree addressing audit gap G1.
  Cookbook ISF recipes will land as recipes 9-13 following the
  existing `.fsm` recipe style.
- `2026-05-27`: Shipped `.2`. Added recipes 9-13 to
  `docs/book/src/12-cookbook.md`. Each verified to parse via
  `FSM::Adapter::ISF` and lower via `FSM::Scheduler::ISF` before
  commit. Recipe contents: basic actor (on/wait/complete),
  spawn-await_all, parameterized blocking do, rule trigger, and
  top-level repeat-body local do. Audits `t/1305`, `t/1307`,
  `t/1332` reverified clean. The G1 gap from
  `ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` is now closed.
