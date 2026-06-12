# AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE: AXI IAL2 Valid-Ready Generator First Slice

## Metadata

- Tree ID: `AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Ship the first narrow in-process AXI Valid-Ready IAL2 generator slice that
accepts one contract object, emits reviewable generated `.isf`, validates and
lowers it through the existing IAL1 path to reviewable `.fsm`, and returns a
source-anchor/residue report.

## Non-Goals

- Do not add public `.pif`, `.ppi`, `.ppif`, `.axi`, or other CLI suffix
  support.
- Do not add a public IAL2 file parser.
- Do not lower IAL2 directly to `.fsm`.
- Do not implement the full AXI manager, transaction IDs, outstanding-window
  scheduling, response matching, bursts, or channel dependency rules.
- Do not revive deprecated ISF `(handshake ...)` metadata as the implementation
  path.

## Acceptance Criteria

- The code adds an internal in-process entrypoint for one AXI Valid-Ready
  contract object.
- Required clock, reset, channel, role, valid, ready, and payload bindings fail
  closed when missing or malformed.
- The result exposes generated `.isf` text before generated `.fsm` text and
  proves that the generated `.isf` parses through `FSM::Adapter::ISF`.
- The result lowers through `FSM::Scheduler::ISF` and returns generated `.fsm`
  files, not a direct IAL2-to-IAL0 path.
- The report includes source object identity, source anchors, generated
  artifact names, bindings, transfer/fire condition, generated assertions,
  assumptions, enforced static rules, explicit residue, and mode.
- Focused tests, mdBook, README, Knowledge Map, task tree, and MEMORY are
  synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE`
  Status: `done`
  Goal: `Implement the first in-process AXI Valid-Ready IAL2 generator slice.`
  Children: `AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.1`

- ID: `AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.1`
  Status: `done`
  Goal: `Add the internal generator, report contract, focused tests, and user-facing docs for one AXI Valid-Ready channel contract.`
  Acceptance: `A focused in-process API emits reviewable .isf before .fsm, validates through the existing IAL1 parser/lowerer, returns a source-anchor/residue report, and leaves public CLI suffixes deferred.`
  Verification: `passed`
  Commit: `AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.1: ship Valid-Ready generator`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.1` | `done` | The first in-process generator slice is implemented, tested, documented, and ready for commit workflow. |

## Decisions

- `2026-06-12`: Start with an in-process API, not CLI/file suffix support, so
  the generated IAL1 artifact and report contract can be proven first.
- `2026-06-12`: Keep `.isf` as generated IAL1; do not extend the `.isf` parser
  with IAL2 source forms.

## Open Questions

- Exact future public file syntax and suffix remain deferred to a later owner;
  they did not block this in-process generator leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ValidReadyChannel.pm`; `prove -Iperl t/1435-axi-ial2-valid-ready-generator.t t/1117-isf-public-lower-result-files-audit.t t/1410-isf-assert-carrier.t t/1411-isf-assert-emit.t t/1412-isf-property-implication.t t/1417-isf-property-sampled-value.t`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1376-isf-book-example-lowering-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.1: ship Valid-Ready generator` | `pending commit workflow` |

## Changelog

- `2026-06-12`: Created active implementation task tree for the first
  in-process AXI Valid-Ready IAL2 generator slice.
- `2026-06-12`: Implemented the in-process generator, focused tests,
  source-anchor/residue docs, mdBook sync, Knowledge Map fact, and live status
  updates.
