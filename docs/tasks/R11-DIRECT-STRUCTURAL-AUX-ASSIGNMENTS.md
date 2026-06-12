# R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS: Direct Structural Enable Assignments

## Metadata

- Tree ID: `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-06-12`
- Last updated: `2026-06-12`
- Owner: repo-local workflow

## Goal

Project the already-rendered direct backend enable assignment lines into direct
`StructuralRTLIR` auxiliary assignments, using the existing scalar-string
assignment-line contract without changing HDL emission.

## Non-Goals

- Do not reroute HDL emission through `StructuralRTLIR`.
- Do not add direct instances, declared links, resolved links, or parsed
  structured assignment records.
- Do not populate direct net `source` or `targets` connectivity in this tree.
- Do not project direct mux, combinational, or sequential always-block
  assignments beyond the generated enable-wire assignment lines selected here.

## Acceptance Criteria

- Direct roots expose deterministic scalar-string auxiliary assignments for
  generated top-level state/standalone-DT enable lines, DT-specific WEN/EN
  lines, and LHS-level WEN/EN lines already produced by the direct backend.
- Direct `auxiliary_assignment_count` matches the projected scalar-string
  assignment entries.
- Direct instances, declared links, resolved links, and direct net connectivity
  remain unchanged.
- Generated HDL remains byte-for-byte behaviorally equivalent for the focused
  fixtures; this tree only mirrors existing rendered assignment facts into the
  structural summary.
- Focused direct structural tests, public structural contract tests, mdBook
  sync checks, Knowledge Map, memory architecture, and diff whitespace checks
  pass before the implementation leaf commits.

## Task Tree

- ID: `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS`
  Status: `done`
  Goal: `Project direct enable assignment lines into StructuralRTLIR auxiliary assignments.`
  Children: `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.1`, `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2`

- ID: `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.1`
  Status: `done`
  Goal: `Select the next exact direct StructuralRTLIR auxiliary-assignment slice.`
  Acceptance: `The leaf records reviewed files/tests, identifies one safe direct auxiliary-assignment projection slice, and updates this tree with the implementation frontier.`
  Verification: `passed`
  Commit: `dead9700 R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.1: select direct enable auxiliary assignments`

- ID: `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2`
  Status: `done`
  Goal: `Project generated direct enable assignment lines into StructuralRTLIR auxiliary_assignments.`
  Acceptance: `Direct structural_rtl_ir.auxiliary_assignments[] includes scalar assignment-line text for state/standalone-DT enable assignments plus DT-specific and LHS-level WEN/EN assignments; direct instances/links/net connectivity and HDL emission remain unchanged; docs/contracts/tests are synced.`
  Verification: `passed`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2` | `done` | Projected already-rendered direct generated enable assignment lines into `StructuralRTLIR.auxiliary_assignments[]`; no active next leaf remains in this tree. |

## Decisions

- `2026-06-12`: Selected only generated enable assignment lines for the first
  direct `auxiliary_assignments[]` projection. The structural contract already
  advertises scalar-string assignment entries, and direct backend support
  already renders deterministic state/DT, DT-specific, and LHS-level enable
  assignments. Parsed assignment records and direct net source/target
  connectivity remain future exact work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.1` | Evidence review: `docs/TASK_TREE.md`; `ROADMAP_V2.md`; `docs/book/src/09-generated-hdl-debugging-and-inspection.md`; `docs/book/src/11-extensions-and-embedding.md`; `docs/book/src/14-feature-backlog.md`; `docs/tasks/R11-DIRECT-BACKEND-COORDINATION-FRONTIER.md`; `docs/tasks/R11-DIRECT-STRUCTURAL-WEN-EN-NETS.md`; `docs/knowledge/normalized-semantic-structural-net-entry-schema.md`; `perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl/FSM/IR/StructuralRTLIR.pm`; `perl/FSM/Synthesis/EnableGraph/EnableSupport.pm`; `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `t/1333-direct-structural-rtl-ir-projection.t`; `t/206-enable-graph-enable-support.t`; `t/311-normalized-semantic-report-contract.t` | `passed`; selected `.2` |
| `2026-06-12` | `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2` | `perl -Iperl -c perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/624-hdl-generator-stateful-direct-structural-rtl-ir-alias-boundary-audit.t t/193-forward-structural-rtl-ir-builder-direct-root.t t/196-generated-module-info-builder.t`; `prove -Iperl t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t t/442-normalized-semantic-payload-contract-defensive-copy-boundary-audit.t t/443-normalized-semantic-report-contract-defensive-copy-boundary-audit.t`; `mdbook build docs/book`; `prove -Iperl t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t t/1414-docs-relative-paths-audit.t`; `prove -Iperl t/206-enable-graph-enable-support.t t/293-systemverilog-post-flattening-assembly-support.t`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `prove -Iperl t/303-normalized-semantic-json-supported-corpus.t t/304-normalized-semantic-json-regression-corpus.t`; `scripts/check_memory_architecture.sh`; `git --no-pager diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.1` | `dead9700 R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.1: select direct enable auxiliary assignments` | Selector leaf committed. |
| `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2` | `pending` | Implementation pending. |

## Changelog

- `2026-06-12`: Created task tree; completed selector leaf `.1`; current
  frontier is implementation leaf `.2`.
- `2026-06-12`: Completed `.2`; direct `StructuralRTLIR` auxiliary assignments
  now include already-rendered generated enable assignment lines as scalar
  strings, while parsed assignment records and net connectivity remain outside
  the projection.
