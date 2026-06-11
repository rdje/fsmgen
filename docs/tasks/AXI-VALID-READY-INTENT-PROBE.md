# AXI-VALID-READY-INTENT-PROBE: AXI Valid/Ready Intent Probe

## Metadata

- Tree ID: `AXI-VALID-READY-INTENT-PROBE`
- Status: `active`
- Roadmap lane: `IAL2 horizon exploration`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Probe whether the AXI valid/ready transport contract can become a bounded
protocol-intent evidence object for future IAL2 work, without selecting parser,
lowering, or HDL implementation behavior yet.

## Non-Goals

- Do not implement an IAL2 source language in this tree.
- Do not implement parser, scheduler, lowering, `.fsm`, or HDL changes.
- Do not claim full AXI capture, AXI manager/subordinate behavior, burst
  semantics, ordering, interconnect, or optional AXI feature layers.
- Do not treat a hand-written reusable `.fsm` library as sufficient IAL2
  evidence by itself.

## Acceptance Criteria

- The valid/ready probe is task-tree owned before any PDF extraction,
  conversion, or evidence artifact is generated.
- The first implementation leaf extracts only source anchors and a bounded
  evidence inventory from the tracked AXI PDF reference.
- The probe distinguishes source facts, inferred rules, explicit abstractions,
  unresolved ambiguity, and unsupported residue.
- The mdBook/backlog and live docs remain synchronized with the selected
  non-implementation status.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `AXI-VALID-READY-INTENT-PROBE`
  Status: `active`
  Goal: `Evaluate valid/ready transport as the smallest AXI-derived IAL2 evidence object.`
  Children: `AXI-VALID-READY-INTENT-PROBE.1`,
  `AXI-VALID-READY-INTENT-PROBE.2`

- ID: `AXI-VALID-READY-INTENT-PROBE.1`
  Status: `done`
  Goal: `Select the bounded AXI valid/ready source-anchor probe.`
  Acceptance: `Audit the IAL2 evaluation note, AXI case-study note, tracked AXI PDF artifact, and available PDF tooling; activate one non-code extraction/evidence leaf without selecting implementation behavior.`
  Verification: `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check`
  Commit: `AXI-VALID-READY-INTENT-PROBE.1: select source-anchor probe`

- ID: `AXI-VALID-READY-INTENT-PROBE.2`
  Status: `pending`
  Goal: `Extract the first AXI valid/ready source-anchor evidence inventory.`
  Acceptance: `Use the tracked AXI PDF reference to produce a repo-local, reviewable evidence note for valid/ready transport semantics, including source anchors, classification of facts vs inference vs abstraction/residue, and explicit no-implementation status.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `AXI-VALID-READY-INTENT-PROBE.1` | `done` | The IAL2 evaluation identifies valid/ready as the smallest plausible AXI-derived protocol-intent probe, and the AXI PDF is now tracked locally. |
| 2 | `AXI-VALID-READY-INTENT-PROBE.2` | `pending` | Source-anchor evidence must exist before any IAL2 source contract or lowering behavior can be considered. |

## Decisions

- `2026-06-12`: Selected AXI valid/ready transport as the first source-anchor
  probe because it is smaller than manager/subordinate/interconnect behavior,
  yet has real protocol semantics, role structure, stability obligations, and
  liveness assumptions.
- `2026-06-12`: Keep `.2` as evidence extraction only. Any parser/lowering,
  reusable library, generated `.fsm`, or HDL behavior needs a later exact
  task-tree leaf after the evidence note exists.

## Open Questions

- Whether the evidence note should preserve a generated plaintext extraction
  artifact, or only a curated source-anchor note, remains open for `.2`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `.1` | `pdfinfo docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`; `mdbook build docs/book`; `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `scripts/check_memory_architecture.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `git diff --check` | pass |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `AXI-VALID-READY-INTENT-PROBE.1: select source-anchor probe` | Pending selection commit; local PDF is 320 pages, unencrypted, and text-extractable. |
| `.2` | `pending` | Pending evidence inventory. |

## Changelog

- `2026-06-12`: Created active task tree, completed selection leaf `.1`, and
  activated evidence leaf `.2`.
