# R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY: Direct Structural Net Connectivity

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY`
- Status: `done`
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
  Status: `done`
  Goal: `Add direct StructuralRTLIR machine-readable source/target connectivity.`
  Children: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1`, `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2`

- ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1`
  Status: `done`
  Goal: `Select the direct StructuralRTLIR source/target connectivity schema and first generated-enable connectivity slice.`
  Acceptance: `A readiness/selection slice records the exact connectivity schema, first generated-enable implementation boundary, validation plan, and documentation targets before any connectivity code changes.`
  Verification: `passed`
  Commit: `a0c28479 R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1: select direct net connectivity`

- ID: `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2`
  Status: `done`
  Goal: `Populate generated-enable source/target connectivity on direct StructuralRTLIR nets.`
  Acceptance: `Direct structural_rtl_ir.nets[] entries for generated-enable assignment-record LHS nets carry structured source objects, and direct net entries that feed another generated-enable assignment-record RHS carry structured target entries; public contracts, docs, Knowledge Map, and tests are synced without changing HDL emission.`
  Verification: `passed`
  Commit: `055dfb2e R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2: populate direct net connectivity`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` | `done` | Populated generated-enable assignment-record drivers and direct-net RHS consumers into the existing `nets[].source` and `nets[].targets` fields; no active next leaf remains in this tree. |

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
- `2026-06-12`: `.2` keeps the selected connectivity bounded to generated
  enable assignment records. Direct port dependency connectivity, output-drive
  and always-block consumers, direct instances/links, and HDL rerouting through
  `StructuralRTLIR` remain deferred to future exact owners.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1` | Selection audit/read of `docs/tasks/R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-HDL-REROUTING.md`; `docs/TASK_TREE.md`; `README.md`; `ROADMAP_V2.md`; `docs/book/src/09-generated-hdl-debugging-and-inspection.md`; `docs/book/src/11-extensions-and-embedding.md`; `docs/knowledge/normalized-semantic-structural-net-entry-schema.md`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `t/1333-direct-structural-rtl-ir-projection.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git --no-pager diff --check` | `passed`; selected `.2` |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` | `perl -Iperl -c perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticForwardIRContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticPayloadContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticReportContract.pm`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t`; `prove -Iperl t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t t/498-structural-rtl-ir-accessor-defensive-copy-boundary-audit.t t/162-composition-top-structural-rtl-ir-surface.t`; `prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t`; `mdbook build docs/book`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/303-normalized-semantic-json-supported-corpus.t t/304-normalized-semantic-json-regression-corpus.t`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1` | `a0c28479 R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.1: select direct net connectivity` | Selected the generated-enable assignment-record connectivity schema and opened `.2`. |
| `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` | `055dfb2e R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2: populate direct net connectivity` | Populated generated-enable assignment-record source/target connectivity on direct structural nets without changing HDL emission. |

## Changelog

- `2026-06-12`: Created proposed task tree.
- `2026-06-12`: Activated `.1`, selected the generated-enable assignment-record
  net connectivity schema, and opened implementation frontier `.2`.
- `2026-06-12`: Completed `.2`; direct generated-enable nets now expose
  structured assignment-record driver `source` objects and structured
  assignment-record RHS-consumer `targets[]` entries where both endpoints are
  direct structural nets.
