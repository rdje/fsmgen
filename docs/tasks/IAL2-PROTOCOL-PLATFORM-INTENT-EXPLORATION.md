# IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION: IAL2 Protocol And Platform Intent Exploration

## Metadata

- Tree ID: `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Decide whether an intent layer above current `.isf` / IAL1 has enough
independent semantic value to exist, using protocol-level intent objects and
platform/resource mapping decisions as the first concrete exploration axis.

## Non-Goals

- Do not implement IAL2 parser, scheduler, lowering, or HDL behavior in this
  tree until a later leaf explicitly selects a concrete source contract.
- Do not reclassify current ATL actor/network syntax as IAL2; explicit `.isf`
  actor/network source remains IAL1.
- Do not accept aliases, macros, wrappers, or syntax sugar as sufficient IAL2
  justification.
- Do not claim automated PDF/spec-to-FSM capture as shipped behavior.

## Acceptance Criteria

- The mdBook IAL2 backlog is task-tree owned before any implementation or
  behavior work begins.
- The first exploration boundary distinguishes IAL2 semantic value from IAL1
  syntax convenience.
- The exploration uses existing concrete evidence from the AXI intent-capture
  case study and intent-scheduling brainstorm before proposing new behavior.
- Live docs, the task index, and `MEMORY.md` point at the active frontier.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION`
  Status: `done`
  Goal: `Task-tree-own and evaluate whether protocol/platform intent deserves an IAL2 layer.`
  Children: `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.1`,
  `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.2`

- ID: `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.1`
  Status: `done`
  Goal: `Select the first exact IAL2 exploration boundary.`
  Acceptance: `Audit the mdBook IAL2 backlog, ATL/IAL1 boundary notes, AXI case-study note, and intent-scheduling brainstorm; activate one non-code exploration leaf that can judge IAL2 semantic value without changing parser/lowering behavior.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.1: select protocol intent boundary`

- ID: `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.2`
  Status: `done`
  Goal: `Write the first IAL2 protocol/platform intent evaluation note.`
  Acceptance: `Define a reviewable, non-code IAL2 evaluation note that states the minimum semantic contract for protocol-level intent objects, the AXI-valid/ready evidence to inspect first, explicit IAL1 non-goals, and go/no-go criteria for any future implementation leaf.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.2: evaluate protocol intent boundary`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.1` | `done` | The mdBook has an IAL2 backlog section but no task-tree owner; selection must happen before any IAL2 work. |
| 2 | `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.2` | `done` | A non-code evaluation note is the smallest safe next step because IAL2 is not yet justified as a source/lowering implementation. |

## Decisions

- `2026-06-12`: Selected protocol-level intent objects and platform/resource
  mapping as the first IAL2 exploration axis because the mdBook names them as
  the first worthwhile areas, and the AXI intent-capture case study provides
  concrete evidence without requiring new parser/lowering behavior.
- `2026-06-12`: Kept this tree non-code until a later leaf establishes a
  source contract. Explicit `.isf` actor/network syntax, including ATL,
  remains IAL1; IAL2 must prove semantics above individual transactions.
- `2026-06-12`: Completed the first IAL2 evaluation with no implementation
  selected. IAL2 is design/probe ready only; a future implementation leaf must
  first specify a bounded protocol/platform intent object, source/capture
  report contract, IAL1/IAL0 lowering artifacts, and focused validation gates.

## Open Questions

- Whether IAL2 should become a source language, a protocol library format, or
  a capture/report workflow remains open. The current evaluation selects no
  implementation leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |
| `2026-06-12` | `.2` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.1: select protocol intent boundary` | Selection commit for the non-code IAL2 protocol/platform evaluation frontier. |
| `.2` | `IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.2: evaluate protocol intent boundary` | Evaluation note completed with no IAL2 implementation selected. |

## Changelog

- `2026-06-12`: Created active task tree, completed selection leaf `.1`, and
  activated non-code exploration leaf `.2`.
- `2026-06-12`: Completed `.2`, wrote
  `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md`, synchronized the mdBook
  backlog, and closed the tree with no IAL2 implementation selected.
