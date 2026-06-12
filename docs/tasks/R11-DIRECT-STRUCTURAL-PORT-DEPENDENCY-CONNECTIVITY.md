# R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY: Direct Port Dependency Connectivity

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Represent direct-root port dependency connectivity in `StructuralRTLIR` with a
machine-readable structural contract when a future selector proves the exact
first safe slice.

## Non-Goals

- Do not claim generated-enable assignment-record source/target connectivity;
  that shipped under `R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY`.
- Do not include output-drive/always-block consumers, direct instances/links,
  full direct module rerouting, or VHDL rerouting unless a later activated leaf
  explicitly widens this tree.
- Do not use raw HDL-string parsing as the connectivity contract.
- Do not add output-port driver/source connectivity in the first selected
  implementation slice; output-drive consumers have their own proposed owner.

## Acceptance Criteria

- A selector leaf identifies the exact direct port dependency family, schema,
  fixtures, and validation matrix before code changes.
- Any implementation leaf populates the selected connectivity as structured
  data and keeps compatibility surfaces stable unless a compatibility-specific
  owner approves a change.
- Public contracts, mdBook, roadmap, README, and Knowledge Map are updated when
  behavior or user-visible inspection changes.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY`
  Status: `done`
  Goal: `Represent direct port dependency connectivity in StructuralRTLIR.`
  Children: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1`,
    `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2`

- ID: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1`
  Status: `done`
  Goal: `Select the first direct port dependency connectivity slice.`
  Acceptance: `The selector records source facts, target structural schema, focused fixtures, validation gates, rollback boundary, and docs/contracts to update before any behavior-bearing direct port dependency connectivity change.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1: select direct input port targets`

- ID: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2`
  Status: `done`
  Goal: `Populate direct input-port generated-enable RHS target connectivity.`
  Acceptance: `Direct input ports consumed by generated-enable assignment-record RHS ASTs expose structured target connectivity on their structural port entries; the target endpoint shape reuses the generated-enable assignment-record target keys; output-port source/driver connectivity, output-drive/always-block consumers, direct instances/links, and HDL emission remain unchanged.`
  Verification: `passed`
  Commit: `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2: populate direct input port targets`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1` | `done` | Selected direct input-port generated-enable RHS target connectivity as the first safe port dependency slice. |
| 2 | `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2` | `done` | Direct assignment-record ASTs already exposed input-port RHS refs; the implementation now maps those refs to structured direct input-port `targets[]`. |

## Decisions

- `2026-06-12`: Track direct port dependency connectivity separately from
  generated-enable net source/target connectivity and output-drive consumers
  so the future schema can stay reviewable and machine-readable.
- `2026-06-12`: Selector `.1` chose a narrow machine-readable input-port
  target slice: when a direct input port appears in a generated-enable
  assignment-record RHS AST, the structural port entry should expose the
  assignment-record consumer as a structured target. Output-port source
  connectivity remains deferred to the output-consumer owner.
- `2026-06-12`: Implementation `.2` populated direct input-port `targets[]`
  from generated-enable assignment-record RHS AST dependencies, reusing the
  generated-enable assignment-record target endpoint shape while leaving
  output-port source/driver connectivity and HDL emission unchanged.

## Open Questions

- None for the selected `.2` scope.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1` | Evidence review: `KNOWLEDGE_MAP.md`; `docs/knowledge/normalized-semantic-structural-port-entry-schema.md`; `docs/knowledge/normalized-semantic-structural-net-entry-schema.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.md`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `t/1333-direct-structural-rtl-ir-projection.t`; `t/163-forward-structural-rtl-ir-surface.t`; `t/341-normalized-semantic-structural-rtl-ir-contract.t`; `scripts/check_memory_architecture.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t`; `git --no-pager diff --check` | `passed`; selected `.2` |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2` | `perl -Iperl -c perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticForwardIRContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticPayloadContract.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticReportContract.pm`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t`; `prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t`; `prove -Iperl t/297-capability-manifest.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t` | `passed`; direct input-port target connectivity populated |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1` | `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.1: select direct input port targets` | Selector slice. |
| `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2` | `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2: populate direct input port targets` | Populated direct input-port generated-enable RHS target connectivity. |

## Changelog

- `2026-06-12`: Created proposed owner tree.
- `2026-06-12`: Activated selector `.1`, selected direct input-port
  generated-enable RHS target connectivity as `.2`, and left output-port
  source/driver connectivity to the output-consumer owner.
- `2026-06-12`: Completed `.2`; direct input ports consumed by
  generated-enable assignment-record RHS ASTs now expose structured
  `targets[]` entries in `StructuralRTLIR`.
