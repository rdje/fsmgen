# R11-DIRECT-STRUCTURAL-INSTANCES-LINKS: Direct Instances And Links

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Audit and, when selected, represent any direct-root instance/link structural
surface in `StructuralRTLIR` without conflating it with composition-top
instances and links.

## Non-Goals

- Do not change behavior in selector `.1`.
- Do not widen composition-top `instances[]`, `declared_links[]`, or
  `resolved_links[]`; those already have their own structural contracts.
- Do not invent direct instances/links if the selector proves the current
  direct-root model should keep those arrays empty.
- Do not reroute HDL emission or alter generated-child realization under this
  owner unless a later activated leaf explicitly selects that scope.

## Acceptance Criteria

- A selector leaf determines whether direct roots have a real instance/link
  structural surface to expose or should remain explicitly empty.
- Any implementation leaf, if selected, exposes only the chosen direct
  instance/link schema with focused tests and stable public contracts.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS`
  Status: `done`
  Goal: `Own the direct-root instances/links StructuralRTLIR question.`
  Children: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1`

- ID: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1`
  Status: `done`
  Goal: `Select the direct instances/links contract.`
  Acceptance: `The selector records current direct-root instance/link facts, whether implementation is warranted, the exact schema if warranted, focused fixtures, validation gates, rollback boundary, and docs/contracts to update before behavior changes.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1: select empty direct links contract`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` | `done` | Selector confirmed direct roots intentionally keep `instances[]`, `declared_links[]`, and `resolved_links[]` empty; no active next leaf remains in this tree. |

## Decisions

- `2026-06-12`: Track direct instances/links as an explicit question rather
  than assuming composition-top structural arrays should automatically apply to
  direct roots.
- `2026-06-12`: Selector `.1` found no current direct-root instance/link
  implementation is warranted. `StructuralRTLIRBuilder->build_from_generated_module_info`
  still builds direct roots as leaf modules with empty `instances[]`,
  `declared_links[]`, and `resolved_links[]`; composition-top and generated
  wrapper/top paths already own real child instances and links through
  `build_from_composition_plan`.

## Open Questions

- None blocking while proposed.

## Blockers

- Not active.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` | Audit/read: `docs/tasks/R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.md`; `docs/TASK_TREE.md`; `README.md`; `ROADMAP_V2.md`; `docs/book/src/09-generated-hdl-debugging-and-inspection.md`; `docs/book/src/11-extensions-and-embedding.md`; `docs/book/src/14-feature-backlog.md`; `docs/knowledge/direct-structural-remaining-owner-coverage.md`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl/FSM/IR/StructuralRTLIR.pm`; `perl/FSM/Pipeline/GeneratedModuleInfoBuilder.pm`; `perl/FSM/Composition/ChildExportBuilder.pm`; `perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `t/1333-direct-structural-rtl-ir-projection.t`; `t/162-composition-top-structural-rtl-ir-surface.t`; `t/163-forward-structural-rtl-ir-surface.t`; `mdbook build docs/book`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/162-composition-top-structural-rtl-ir-surface.t t/163-forward-structural-rtl-ir-surface.t`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed`; no direct-root implementation leaf selected |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` | `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1: select empty direct links contract` | Selector confirmed direct roots intentionally expose empty instance/link arrays; composition keeps the populated instance/link contract. |

## Changelog

- `2026-06-12`: Created proposed owner tree.
- `2026-06-12`: Completed selector `.1`; direct roots remain leaf structural
  summaries with empty instance/link arrays, and no implementation leaf was
  opened.
