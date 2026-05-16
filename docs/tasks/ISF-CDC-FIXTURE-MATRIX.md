# ISF-CDC-FIXTURE-MATRIX: CDC Fixture Matrix Hardening

## Metadata

- Tree ID: `ISF-CDC-FIXTURE-MATRIX`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Harden the ISF multi-clock/CDC fixture matrix beyond the first single-event
crossing by adding a file-backed fixture that proves multiple acknowledged
event CDC children can coexist in one generated top with report-visible
metadata and generated HDL.

## Non-Goals

- Do not add a new CDC primitive.
- Do not add payload, FIFO, handshake, or direct cross-domain data semantics.
- Do not change the authored semantics of the shipped acknowledged event
  crossing.

## Acceptance Criteria

- A realistic file-backed ISF fixture covers two acknowledged event crossings
  in opposite directions between the same two domains.
- Focused tests prove the fixture's scheduled artifacts, top wiring, bounded
  schedule-report metadata, and generated HDL modules.
- The ISF spec, mdBook, downstream integration handoff, roadmap status, task
  index, and live docs stay synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CDC-FIXTURE-MATRIX`
  Status: `done`
  Goal: `Harden multi-clock/CDC fixture coverage for multiple event crossings.`
  Children: `ISF-CDC-FIXTURE-MATRIX.1`

- ID: `ISF-CDC-FIXTURE-MATRIX.1`
  Status: `done`
  Goal: `Add dual event-crossing fixture coverage.`
  Acceptance: `A new file-backed fixture with two opposite-direction event
  crossings reaches scheduled .fsm emission, schedule JSON, and generated
  SystemVerilog/Verilog-family HDL with both CDC children visible.`
  Verification: `prove -Iperl t/1247-isf-clock-domain-partition.t`;
  `./bin/ci-regression isf --no-book`; `mdbook build docs/book`;
  `git diff --check`
  Commit: `ISF-CDC-FIXTURE-MATRIX.1: harden CDC fixture matrix`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | - | `closed` | `ISF-CDC-FIXTURE-MATRIX.1` completed the dual event-crossing fixture hardening slice and closed the tree. |

## Decisions

- `2026-05-16`: The first hardening slice will exercise two acknowledged
  event crossings in opposite directions. This verifies repeated CDC child
  generation and mixed source/destination reset metadata without widening CDC
  semantics.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-CDC-FIXTURE-MATRIX.1` | `prove -Iperl t/1247-isf-clock-domain-partition.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CDC-FIXTURE-MATRIX.1` | `ISF-CDC-FIXTURE-MATRIX.1: harden CDC fixture matrix` | Dual event-crossing fixture, focused assertions, public docs, and live docs. |

## Changelog

- `2026-05-16`: Created task tree and selected the dual event-crossing fixture
  hardening leaf.
- `2026-05-16`: Added `isf/clock_domain_dual_event_crossing.isf`, extended
  `t/1247-isf-clock-domain-partition.t`, synchronized the ISF spec, mdBook,
  downstream integration handoff, public contract doc, roadmap, task-tree
  index, and live docs, then closed the tree.
