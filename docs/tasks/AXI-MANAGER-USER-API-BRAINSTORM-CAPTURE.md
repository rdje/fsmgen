# AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE: AXI Manager User API Brainstorm Capture

## Metadata

- Tree ID: `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Capture the AXI manager user-facing API brainstorming in durable project
documentation and the mdBook, without selecting implementation behavior.

## Non-Goals

- Do not implement an AXI manager.
- Do not implement IAL2 syntax, parser, lowering, `.fsm`, HDL, tests, or
  generated artifacts.
- Do not claim the exact AXI ID, ordering, interleaving, or concurrency rules
  until they have been separately source-anchored from the tracked AXI spec.
- Do not treat the brainstorm as a shipped user feature.

## Acceptance Criteria

- The brainstorm is captured outside the session chat log in a repo-local
  design note.
- The mdBook backlog points at the capture and summarizes the intended Easy,
  Power, and supervised Raw mode boundary.
- The task tree records that the capture is non-implementation work and that
  future AXI rule extraction/design requires a new exact owner.
- Live docs and memory remain synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE`
  Status: `done`
  Goal: `Persist the AXI manager user API brainstorming in durable docs.`
  Children: `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.1`

- ID: `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.1`
  Status: `done`
  Goal: `Capture the AXI manager user API brainstorm in docs and the mdBook.`
  Acceptance: `Record Easy mode as conventions-over-configuration rather than a reduced subset, define the manager-as-protocol-authority principle, describe Power and supervised Raw mode latitude, capture flow-control/status feedback expectations, and preserve no-implementation status.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.1: capture AXI manager API direction`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.1` | `done` | The AXI manager API brainstorming is now captured in durable docs and the mdBook. |

## Decisions

- `2026-06-12`: Capture this as a design/backlog note, not a behavior-bearing
  implementation selection. The next technical prerequisite was a
  source-anchored AXI ID/order/concurrency rule extraction, later recorded by
  `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1`.
- `2026-06-12`: Shape the capture explicitly as future IAL2 user-facing
  surface direction: Easy, Power, and supervised Raw are API levels on one AXI
  rule engine, not separate legality regimes.

## Open Questions

- The first AXI ID/order/concurrency evidence inventory is now recorded by
  `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1`. A full source-anchored rule matrix
  still needs a future exact owner before any AXI manager design can be
  selected.

## Blockers

- None for capture. Future implementation is blocked on a source-anchored AXI
  rule-matrix design/probe and a new exact task-tree owner.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `AXI-MANAGER-USER-API-BRAINSTORM-CAPTURE.1: capture AXI manager API direction` | Captures the user-facing IAL2 AXI manager API direction and no-implementation status. |

## Changelog

- `2026-06-12`: Created active task tree for durable AXI manager API
  brainstorm capture.
- `2026-06-12`: Captured the brainstorm in
  [docs/AXI_MANAGER_USER_API_BRAINSTORM.md](../AXI_MANAGER_USER_API_BRAINSTORM.md),
  linked it from the mdBook and IAL2 evaluation, and added a Knowledge Map
  signpost.
