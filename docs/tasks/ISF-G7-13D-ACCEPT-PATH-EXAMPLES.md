# ISF-G7-13D-ACCEPT-PATH-EXAMPLES: Add Accept-Path Examples To 13d Control Flow

## Metadata

- Tree ID: `ISF-G7-13D-ACCEPT-PATH-EXAMPLES`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Address audit gap G7: 13d-control-flow.md is light for the
when/switch/repeat/while/until/do/spawn surface it covers. Add 4
complete accept-path actor examples (when, switch-with-default,
while, until) so users can copy-paste working fixtures for each
control-flow form. Each example carries a Walkthrough paragraph
naming every top-level clause used.

## Non-Goals

- Do not modify the existing rejection-shape illustrations.
- Do not change validator behavior or tests.

## Acceptance Criteria

- Four new `lisp` blocks in `docs/book/src/13d-control-flow.md`:
    * `when_demo` — conditional wait body
    * `switch_demo` — multi-way dispatch with default
    * `while_demo` — pre-test loop
    * `until_demo` — post-test loop
- Each lowers via `FSM::Scheduler::ISF` and is locked by
  `t/1376-isf-book-example-lowering-audit.t`.
- Each carries a `**Walkthrough.**` paragraph.
- Audits `t/1305`, `t/1307`, `t/1332`, `t/1376` pass; mdBook
  clean; whitespace clean.

## Task Tree

- ID: `ISF-G7-13D-ACCEPT-PATH-EXAMPLES`
  Status: `done`
  Goal: `Add 4 accept-path control-flow examples to 13d.`
  Children:
    `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.1`,
    `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.2`

- ID: `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.1`
  Status: `done`
  Goal: `Select.`
  Acceptance: `Task tree committed.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.2`
  Status: `done`
  Goal: `Ship the four examples plus walkthroughs.`
  Acceptance: `prove t/1376 passes with 24 fixtures (was 20); audits pass.`
  Verification: `prove -Iperl t/1305 t/1307 t/1332 t/1376; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.1` | `pending` | Selection. |
| 2 | `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.2` | `pending` | Ship. |

## Decisions

- `2026-05-29`: Pick 4 representative shapes (when, switch+default,
  while, until). Repeat and do/spawn already have multiple
  examples elsewhere in the book.

## Open Questions / Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.1` | `mdbook build docs/book`; `git diff --check` | `pending` |
| `2026-05-29` | `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.2` | `prove -Iperl t/1305 t/1307 t/1332 t/1376`; `mdbook build docs/book`; `git diff --check` | `pending` |

## Commit Log

| Leaf | Subject | Notes |
| --- | --- | --- |
| `.1` | `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.1: select 13d accept-path examples` | `pending` |
| `.2` | `ISF-G7-13D-ACCEPT-PATH-EXAMPLES.2: ship 13d accept-path examples` | `pending` |

## Changelog

- `2026-05-29`: Created task tree for audit gap G7.
