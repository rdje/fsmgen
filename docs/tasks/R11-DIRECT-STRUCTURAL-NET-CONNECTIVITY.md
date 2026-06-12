# R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY: Direct Structural Net Connectivity

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Add machine-readable source/target connectivity to the direct
`StructuralRTLIR` surface so downstream consumers can inspect which structural
assignments, ports, and generated helper nets drive or consume each net without
parsing emitted HDL text.

## Non-Goals

- Do not change code while this tree remains `proposed`; an explicit active
  leaf must own any implementation slice.
- Do not reroute HDL emission through `StructuralRTLIR`; that is tracked by
  `R11-DIRECT-STRUCTURAL-HDL-REROUTING`.
- Do not parse arbitrary rendered HDL back into connectivity.
- Do not widen to direct instances, declared links, or resolved links unless a
  later activated leaf explicitly selects that scope.
- Do not remove the scalar `auxiliary_assignments[]` compatibility mirror.

## Acceptance Criteria

- Direct `StructuralRTLIR` has a documented, stable source/target connectivity
  schema for the selected first slice.
- The selected first slice connects generated enable assignment records to their
  driven nets and known source dependencies using structured identifiers.
- Focused direct structural tests prove the connectivity records are
  machine-readable and clone-isolated.
- Public contracts, mdBook, roadmap, Knowledge Map, and task-tree evidence are
  updated when an implementation leaf is activated.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY`
  Status: `active`
  Goal: `Add direct StructuralRTLIR machine-readable source/target connectivity.`
  Children: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1`, `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2`

- ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1`
  Status: `done`
  Goal: `Select the direct StructuralRTLIR source/target connectivity schema and first generated-enable connectivity slice.`
  Acceptance: `A readiness/selection slice records the exact connectivity schema, first generated-enable implementation boundary, validation plan, and documentation targets before any connectivity code changes.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1: select direct net connectivity`

- ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2`
  Status: `pending`
  Goal: `Populate generated-enable source/target connectivity on direct StructuralRTLIR nets.`
  Acceptance: `Direct structural_rtl_ir.nets[] entries for generated-enable assignment-record LHS nets carry structured source objects, and direct net entries that feed another generated-enable assignment-record RHS carry structured target entries; public contracts, docs, Knowledge Map, and tests are synced without changing HDL emission.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` | `pending` | The schema is selected; generated-enable assignment-record drivers and direct-net RHS consumers can now be projected into the existing `nets[].source` and `nets[].targets` fields. |

## Decisions

- `2026-06-12`: Track direct net source/target connectivity as its own R11
  tree so it does not hide inside assignment-record work or HDL rerouting work.
- `2026-06-12`: Select the first implementation slice as generated-enable
  assignment-record connectivity only. For a direct net whose name matches an
  `assignment_records[].lhs.name`, `nets[].source` will become a structured
  object identifying the assignment record that drives it. For a direct net
  that appears as a signal reference inside another generated-enable
  assignment-record RHS AST, `nets[].targets[]` will receive a structured
  object identifying the consuming assignment record. Direct port
  dependencies, `current_state`/state encoding dependencies that are not
  structural nets, output-drive/always-block consumers, direct instances,
  declared/resolved links, and HDL rerouting remain deferred.
- `2026-06-12`: The public contract for `.2` should advertise nested net
  source and target entry-key families instead of leaving the value shape in
  prose.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1` | Selection audit/read of `docs/tasks/R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md`; `docs/TASK_TREE.md`; `README.md`; `ROADMAP_V2.md`; `docs/book/src/09-generated-hdl-debugging-and-inspection.md`; `docs/book/src/11-extensions-and-embedding.md`; `docs/knowledge/normalized-semantic-structural-net-entry-schema.md`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `t/1333-direct-structural-rtl-ir-projection.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git --no-pager diff --check` | `passed`; selected `.2` |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1` | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1: select direct net connectivity` | Selected the generated-enable assignment-record connectivity schema and opened `.2`. |
| `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` | `pending` | `pending` |

## Changelog

- `2026-06-12`: Created proposed task tree.
- `2026-06-12`: Activated `.1`, selected the generated-enable assignment-record
  net connectivity schema, and opened implementation frontier `.2`.
