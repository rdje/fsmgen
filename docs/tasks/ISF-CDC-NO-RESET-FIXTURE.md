# ISF-CDC-NO-RESET-FIXTURE: No-Reset CDC Event Fixture

## Metadata

- Tree ID: `ISF-CDC-NO-RESET-FIXTURE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Add focused schedule/report fixture coverage for an acknowledged-event CDC
crossing between two clock domains that intentionally declare no resets, and
lock the current HDL fail-closed boundary for no-reset domain artifacts.

## Non-Goals

- Do not introduce a new CDC primitive or payload protocol.
- Do not change reset semantics for existing reset-bearing CDC fixtures.
- Do not widen direct cross-domain reads, writes, activations, or bindings.
- Do not add no-reset scheduled `.fsm` HDL support; the direct HDL path still
  requires a clock plus reset declaration in generated domain artifacts.

## Acceptance Criteria

- A no-reset multi-domain `.isf` fixture lowers to bus/core domain artifacts
  plus one generated top and one CDC child.
- The generated top and CDC interface metadata publish absent source and
  destination resets with `SOURCE_RESET_PRESENT 0d0` and
  `DEST_RESET_PRESENT 0d0`.
- Schedule JSON and CLI schedule JSON preserve the no-reset crossing metadata.
- CLI HDL generation for the no-reset fixture fails closed with the existing
  incomplete `+system` diagnostic rather than emitting misleading HDL.
- Public docs and the mdBook backlog reflect that no-reset acknowledged-event
  CDC schedule/report fixture coverage is now shipped, while no-reset HDL and
  richer CDC payload/reset combinations remain backlog.
- Focused validation passes, broader ISF validation runs because a public
  fixture/source/test surface changes, and the leaf is committed through
  `COMMIT.md`.

## Task Tree

- ID: `ISF-CDC-NO-RESET-FIXTURE`
  Status: `done`
  Goal: `Harden the acknowledged-event CDC matrix with no-reset schedule/report fixture coverage.`
  Children: `ISF-CDC-NO-RESET-FIXTURE.1`

- ID: `ISF-CDC-NO-RESET-FIXTURE.1`
  Status: `done`
  Goal: `Add no-reset CDC event schedule/report fixture coverage and docs.`
  Acceptance: `The fixture covers lowering, report parity, CDC metadata, the current no-reset HDL fail-closed boundary, docs/book sync, validation, and commit workflow.`
  Verification: `syntax check; focused clock-domain/book audits Files=4, Tests=376; ./bin/ci-regression isf --no-book Files=275, Tests=1756; mdbook build docs/book; git diff --check`
  Commit: `ISF-CDC-NO-RESET-FIXTURE.1: cover no-reset CDC boundary`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `ISF-CDC-NO-RESET-FIXTURE.1` shipped no-reset acknowledged-event CDC schedule/report fixture coverage and locked the current HDL fail-closed boundary. |

## Decisions

- `2026-05-25`: Keep this as fixture hardening for the existing
  acknowledged-event primitive. No new CDC semantics are introduced.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-CDC-NO-RESET-FIXTURE.1` | syntax check; focused clock-domain/book audits; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | passed; focused `Files=4, Tests=376`; ISF regression `Files=275, Tests=1756` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CDC-NO-RESET-FIXTURE.1` | `ISF-CDC-NO-RESET-FIXTURE.1: cover no-reset CDC boundary` | task-scoped commit subject |

## Changelog

- `2026-05-25`: Created and activated task tree.
- `2026-05-25`: Added the no-reset acknowledged-event CDC fixture,
  synchronized docs, and closed the tree.
