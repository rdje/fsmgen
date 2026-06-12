# AXI-ID-ORDERING-RULE-EVIDENCE-PROBE: AXI ID/Ordering Rule Evidence Probe

## Metadata

- Tree ID: `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE`
- Status: `done`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Extract the first source-anchor inventory for AXI transaction IDs, ordering,
interleaving, outstanding transaction concurrency, and response matching as a
future IAL2 rule-engine prerequisite.

## Non-Goals

- Do not implement an AXI manager.
- Do not implement IAL2 syntax, parser, lowering, `.isf`, `.fsm`, HDL, tests,
  or generated artifacts.
- Do not claim full AXI rule coverage.
- Do not design from memory; only source-anchored facts from the tracked AXI
  reference are in scope.
- Do not track raw PDF text extraction dumps.

## Acceptance Criteria

- The extraction is task-tree owned before any PDF extraction or evidence
  artifact is generated.
- A repo-local evidence note records source anchors for the first AXI ID,
  ordering, interleaving, concurrency, and response-matching facts needed by a
  future IAL2 AXI rule engine.
- The note distinguishes source facts, inferred rule-engine needs, explicit
  abstractions, unresolved questions, and unsupported residue.
- The mdBook backlog, IAL2 evaluation, AXI manager brainstorm, task tree,
  Knowledge Map, README, and memory remain synchronized.
- No implementation behavior is selected.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE`
  Status: `done`
  Goal: `Capture AXI ID/order/concurrency source anchors for future IAL2 rule-engine work.`
  Children: `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1`

- ID: `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1`
  Status: `done`
  Goal: `Extract the first AXI ID/order/concurrency source-anchor evidence inventory.`
  Acceptance: `Use the tracked AXI PDF reference to produce a curated evidence note for ID allocation/matching, ordering, interleaving, outstanding concurrency, response association, and explicit residue, with no parser/lowering/HDL implementation selected.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1` | `done` | The first source-anchor inventory is recorded in `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`; later rule-matrix/design work needs a new exact owner. |

## Decisions

- `2026-06-12`: Start with evidence extraction only. Future parser, lowering,
  generated IAL1/IAL0, and HDL behavior need later exact task-tree owners.
- `2026-06-12`: Source extraction records enough evidence to justify a later
  AXI manager rule-matrix design/probe leaf, but selects no implementation.

## Open Questions

- No open question remains for this bounded first inventory. Full AXI
  transaction-class, cacheability, Resource Plane, chunking, Atomic, exclusive,
  subordinate, and interconnect rule matrices remain future exact-owner work.

## Blockers

- None for evidence extraction.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `pdfinfo docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`; `pdftotext -layout` temporary extraction for pages `21-22`, `90-102`, `116`, and `305-306`; temporary rendered visual checks for pages `90` and `100`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git diff --check` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `AXI-ID-ORDERING-RULE-EVIDENCE-PROBE.1: record ID ordering evidence` | Records the first AXI ID/order/concurrency source-anchor inventory and no-implementation status. |

## Changelog

- `2026-06-12`: Created active task tree for AXI ID/order/concurrency source
  evidence extraction.
- `2026-06-12`: Recorded the curated AXI ID/order/concurrency evidence note
  and synchronized README, mdBook, IAL2 evaluation, AXI manager brainstorm,
  Knowledge Map, task tree, and memory.
