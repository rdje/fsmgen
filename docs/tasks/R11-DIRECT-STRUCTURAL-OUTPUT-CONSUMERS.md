# R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS: Direct Output Consumer Connectivity

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Represent direct-root output-drive and always-block consumer connectivity in
`StructuralRTLIR` as structured data when a future selector proves the exact
first safe slice.

## Non-Goals

- Do not change behavior in selector `.1`; implementation starts only at the
  selected `.2` leaf.
- Do not claim direct port dependency connectivity, direct instances/links, or
  HDL rerouting through this owner.
- Do not change generated HDL or output-drive scheduling semantics unless a
  future activated implementation leaf explicitly owns that behavior.
- Do not use rendered HDL text as the durable connectivity source of truth.
- Do not model nested RHS-enable-family internals or always-block body
  consumers in the first implementation slice.

## Acceptance Criteria

- A selector leaf identifies the first output-drive/always-block consumer
  family, structural schema, fixture set, and validation matrix before code
  changes.
- Any implementation leaf populates the selected consumer connectivity in a
  machine-readable shape and preserves existing generated HDL behavior unless
  the leaf explicitly owns output changes.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS`
  Status: `active`
  Goal: `Represent direct output-drive and always-block consumers in StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1`,
    `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2`

- ID: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1`
  Status: `done`
  Goal: `Select the first direct output consumer connectivity slice.`
  Acceptance: `The selector records source facts, target structural schema, focused fixtures, validation gates, rollback boundary, and docs/contracts to update before any behavior-bearing output consumer connectivity change.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1: select output port sources`

- ID: `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2`
  Status: `pending`
  Goal: `Populate direct output-port source summaries from lowered output-drive families.`
  Acceptance: `Direct output ports whose names match bounded LoweredRTLIR output_drive_families expose a structured source summary on their StructuralRTLIR port entries; the source is derived from structured LoweredRTLIR data, not rendered HDL text; the source summary includes kind, signal_name, multiplexer_type, driver_count, driver_blocks, rhs_values, driver_enable_signals, and family_enable_signals; nested rhs_enable_families, default/reset values, always-block body consumers, direct instances/links, and HDL emission remain unchanged.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1` | `done` | Selected a narrow output-port source summary derived from already-bounded LoweredRTLIR output-drive families. |
| 2 | `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2` | `pending` | Existing direct normalized semantic JSON already exposes `lowered_rtl_ir.output_drive_families[]`; the first structural bridge should attach a compact source summary to matching direct output ports without changing HDL. |

## Decisions

- `2026-06-12`: Track output-drive and always-block consumers separately from
  port dependencies and HDL rerouting because they may require a wider direct
  lowered/structural handoff before they are safe to expose.
- `2026-06-12`: Selector `.1` chose a compact direct output-port `source`
  summary as the first safe implementation slice. The source comes from the
  existing bounded `LoweredRTLIR.output_drive_families[]` data and deliberately
  excludes nested `rhs_enable_families[]`, default/reset values, always-block
  body modeling, and HDL emission changes.

## Open Questions

- None for the selected `.2` scope.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1` | Evidence review: `KNOWLEDGE_MAP.md`; `docs/knowledge/normalized-semantic-output-drive-entry-schema.md`; `perl/FSM/IR/LoweredRTLIR.pm`; `perl/FSM/IR/LoweredRTLIRBuilder.pm`; `perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm`; `perl/FSM/IR/StructuralRTLIR.pm`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm`; `t/311-normalized-semantic-report-contract.t`; `fsm/apb_requester.fsm`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git --no-pager diff --check` | `passed`; selected `.2` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1` | `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.1: select output port sources` | Selector slice. |
| `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed owner tree.
- `2026-06-12`: Activated selector `.1`, selected direct output-port source
  summaries derived from lowered output-drive families as `.2`, and left
  nested RHS-family/body modeling to later owner leaves.
