# IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE: IAL2 Protocol/Platform Surface Decision Capture

## Metadata

- Tree ID: `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Capture the IAL2 protocol/platform-generic file-surface and lowering-chain
decision in durable project documentation.

## Non-Goals

- Do not implement `.pif`, `.ppi`, `.ppif`, or any other IAL2 parsing/tooling.
- Do not implement IAL2 syntax, lowering, `.isf`, `.fsm`, HDL, tests, or
  generated artifacts.
- Do not select a protocol-specific extension such as `.axi`.
- Do not claim a shipped IAL2 user surface.
- Do not finalize the exact IAL2 extension spelling in this leaf.

## Acceptance Criteria

- A decision record captures the protocol/platform-generic IAL2 file-surface
  direction.
- The decision rejects protocol-specific IAL2 extensions for protocol families
  such as AXI, CHI, ACE, AHB, APB, and ATB.
- The decision records `.pif`, `.ppi`, and `.ppif` as extension candidates
  while leaving exact spelling open.
- The decision records the lowering invariant:
  `IAL2 -> IAL1/ISF -> IAL0/FSM`, with direct `IAL2 -> IAL0` lowering
  forbidden.
- The IAL2 evaluation, AXI manager API brainstorm, mdBook backlog, task tree,
  Knowledge Map, README, and memory are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE`
  Status: `done`
  Goal: `Persist the protocol/platform-generic IAL2 surface and lowering-chain decision.`
  Children: `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.1`

- ID: `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.1`
  Status: `done`
  Goal: `Capture protocol/platform-generic IAL2 surface candidates and layered lowering.`
  Acceptance: `Record the generic Protocol/Platform Intent surface direction; record that protocol-specific extensions such as .axi are rejected; record .pif, .ppi, and .ppif as open candidates; record that IAL2 must lower through IAL1 before IAL0.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.1: record generic IAL2 surface decision`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.1` | `done` | The protocol/platform-generic IAL2 surface and mandatory lowering-chain decision is now captured. |

## Decisions

- `2026-06-12`: Capture this as a durable decision because it defines the
  future IAL2 file-surface direction and cross-layer lowering invariant.
- `2026-06-12`: Reject protocol-specific extensions such as `.axi`; keep the
  IAL2 file surface generic across protocol and platform vocabularies.
- `2026-06-12`: Keep exact extension spelling open among `.pif`, `.ppi`,
  `.ppif`, or a later accepted generic alternative.
- `2026-06-12`: Lock future IAL2 lowering to IAL2 -> IAL1 `.isf` -> IAL0
  `.fsm`; direct IAL2-to-IAL0 lowering is forbidden.

## Open Questions

- Exact IAL2 extension spelling remains open.
- Exact IAL2 syntax, version declarations, protocol vocabulary declarations,
  and tooling behavior remain unselected.

## Blockers

- None for decision capture. Future implementation needs a new exact
  task-tree owner.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `IAL2-PROTOCOL-PLATFORM-SURFACE-DECISION-CAPTURE.1: record generic IAL2 surface decision` | Records generic IAL2 extension candidates and the mandatory IAL2 -> IAL1 -> IAL0 lowering chain. |

## Changelog

- `2026-06-12`: Created and completed task tree for IAL2 protocol/platform
  surface decision capture.
