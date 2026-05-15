# ISF-CLOCK-DOMAINS: Multi-Clock And CDC Semantics

## Metadata

- Tree ID: `ISF-CLOCK-DOMAINS`
- Status: `proposed`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Define and eventually ship a deliberate ISF model for multi-clock,
asynchronous, and interacting clock-domain designs.

## Non-Goals

- Do not treat different clock signal names as different clock domains without
  an explicit source-level domain model.
- Do not infer CDC safety from direct signal reads, direct signal writes, or
  generated-top system-port links.
- Do not add arbitrary combinational logic to asynchronous reset trees.
- Do not change the shipped single-clock actor semantics in this tree without
  a focused compatibility and migration leaf.

## Acceptance Criteria

- The current one-clock-domain ISF boundary is documented in the spec, book,
  roadmap, and task-tree index.
- Future implementation leaves define source syntax, lowering, diagnostics,
  schedule-report projection, and regression fixtures before accepting any
  multi-clock source.
- Cross-domain interaction has explicit runtime semantics. Direct same-cycle
  sampling across domains is rejected unless a shipped CDC primitive or
  protocol construct owns the crossing.
- The completed leaves are committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CLOCK-DOMAINS`
  Status: `proposed`
  Goal: `Design and ship explicit ISF multi-clock and CDC semantics.`
  Children: `ISF-CLOCK-DOMAINS.1`, `ISF-CLOCK-DOMAINS.2`,
  `ISF-CLOCK-DOMAINS.3`, `ISF-CLOCK-DOMAINS.4`,
  `ISF-CLOCK-DOMAINS.5`, `ISF-CLOCK-DOMAINS.6`

- ID: `ISF-CLOCK-DOMAINS.1`
  Status: `done`
  Goal: `Capture the current single-clock boundary and backlog the multi-clock/CDC work.`
  Acceptance: `Spec, mdBook, roadmap, task-tree index, README, and live docs state that ISF currently has one clock domain per actor/generated top and that multi-clock/CDC semantics remain unshipped.`
  Verification: `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.1: capture multi-clock backlog`

- ID: `ISF-CLOCK-DOMAINS.2`
  Status: `pending`
  Goal: `Specify the source model for named clock domains.`
  Acceptance: `The book and spec define whether domains are actor-scoped, port-scoped, transaction-scoped, child-instance-scoped, or a combination, and malformed combinations fail closed.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.3`
  Status: `pending`
  Goal: `Specify reset ownership for each clock domain.`
  Acceptance: `The model distinguishes synchronous resets per domain from asynchronous reset pins and forbids arbitrary DT glue on async reset trees.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.4`
  Status: `pending`
  Goal: `Specify cross-domain interaction primitives.`
  Acceptance: `The first shipped CDC surface identifies legal crossings, such as synchronized single-bit events, handshakes, or dual-clock FIFO-like actors, and rejects unowned direct crossings.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.5`
  Status: `pending`
  Goal: `Lower multi-domain ISF into explicit scheduled artifacts.`
  Acceptance: `Lowering emits reviewable domain-specific scheduled .fsm artifacts or a documented multi-domain .fsm structure with clear clock/reset ownership.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.6`
  Status: `pending`
  Goal: `Add diagnostics, reports, and fixtures for multi-clock behavior.`
  Acceptance: `Schedule JSON exposes bounded domain and crossing metadata, direct unsafe crossings fail closed, and realistic CDC fixtures reach HDL where supported.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CLOCK-DOMAINS.2` | `pending` | A public source model must exist before any parser, scheduler, or backend work accepts multi-clock ISF input. |
| 2 | `ISF-CLOCK-DOMAINS.3` | `pending` | Reset ownership is part of the domain model and must be specified before lowering. |
| 3 | `ISF-CLOCK-DOMAINS.4` | `pending` | Cross-domain behavior needs explicit legal primitives before generated RTL can be considered meaningful. |

## Decisions

- `2026-05-15`: Current ISF remains single-clock-domain. A different signal
  name in `(clock ...)` or a library binding is only signal-name remapping
  inside the one-domain model.
- `2026-05-15`: Multi-clock, asynchronous, and interacting clock-domain
  support must be designed as a public feature, not inferred from existing
  composition links or direct signal access.
- `2026-05-15`: Direct cross-domain same-cycle reads/writes are not a safe
  default. A shipped CDC primitive or protocol actor must own the runtime
  crossing semantics.

## Open Questions

- Should named clock domains be actor-scoped only, or can individual
  interface ports, child instances, transactions, or rules declare a domain?
- Which CDC primitive ships first: event synchronizer, level handshake,
  request/acknowledge channel, dual-clock FIFO, or another actor-library
  pattern?
- How should schedule reports summarize domains and crossings without exposing
  unstable internal lowering objects?
- How should generated HDL validation distinguish simulation-only assertions
  from synthesizable CDC structure checks?

## Blockers

- No source-level domain model has been selected.
- No first CDC primitive has been selected.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.1` | `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CLOCK-DOMAINS.1` | `ISF-CLOCK-DOMAINS.1: capture multi-clock backlog` | Documents the shipped single-clock boundary and proposed multi-clock/CDC design tree. |

## Changelog

- `2026-05-15`: Created proposed tree and completed the first documentation
  leaf that records the current single-clock-domain boundary.
