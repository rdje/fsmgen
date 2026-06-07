# ARCHITECTURE-DEBT-FRONTIER: Architecture Debt Frontier

## Metadata

- Tree ID: `ARCHITECTURE-DEBT-FRONTIER`
- Status: `done`
- Roadmap lane: `architecture`
- Created: `2026-06-05`
- Last updated: `2026-06-07`
- Owner: repo-local workflow

## Goal

Own the architecture debt items named in the 2026-06-05 remaining-work
inventory so convergence/refactor work is selected through task-tree leaves
rather than informal cleanup.

## Non-Goals

- Do not perform broad refactors without selecting an exact active leaf first.
- Do not change public behavior under an architecture-debt label without the
  same behavior, docs, and regression responsibilities as a feature leaf.
- Do not extract modules merely for aesthetics; extraction must reduce real
  complexity or stabilize a proven boundary.

## Acceptance Criteria

- Each architecture-debt backlog item has a leaf-level owner.
- When selected, the tree activates one executable leaf at a time.
- Behavior-preserving refactors are validated with focused and broader gates
  according to blast radius.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ARCHITECTURE-DEBT-FRONTIER`
  Status: `done`
  Goal: `Track architecture convergence and extraction backlog directions.`
  Children: `ARCHITECTURE-DEBT-FRONTIER.1`,
    `ARCHITECTURE-DEBT-FRONTIER.2`,
    `ARCHITECTURE-DEBT-FRONTIER.3`

- ID: `ARCHITECTURE-DEBT-FRONTIER.1`
  Status: `done`
  Goal: `Select the next executable architecture-debt leaf from evidence.`
  Acceptance: `One architecture item is activated, explicitly deferred, or linked to a stronger prerequisite owner.`
  Verification: `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ARCHITECTURE-DEBT-FRONTIER.1: select direct backend convergence`

- ID: `ARCHITECTURE-DEBT-FRONTIER.2`
  Status: `done`
  Goal: `Converge the direct backend path toward StructuralRTLIR-to-emitter where one bounded step is safe.`
  Acceptance: `One exact backend convergence boundary is selected, implemented or deferred, documented if user-visible, and regression-covered.`
  Children: `ARCHITECTURE-DEBT-FRONTIER.2.1`
  Verification: `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ARCHITECTURE-DEBT-FRONTIER.2: select direct structural internal nets`

- ID: `ARCHITECTURE-DEBT-FRONTIER.2.1`
  Status: `done`
  Goal: `Project direct backend internal storage/helper declarations into StructuralRTLIR nets.`
  Acceptance: `Direct-root structural_rtl_ir.nets[] is built from the existing backend internal declaration plan's signal_decls and aux_decls, preserving width/signed/state-model/declared-type metadata without rerouting HDL emission or claiming direct instances, links, auxiliary assignments, or generated enable wires.`
  Verification: `perl -Iperl -c perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl -Iperl -c perl/FSM/Pipeline/DirectGenerationOrchestrator.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/190-pipeline-direct-generation-orchestrator.t t/204-enable-graph-module-planning-support.t t/303-normalized-semantic-json-supported-corpus.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `git diff --check`
  Commit: `ARCHITECTURE-DEBT-FRONTIER.2.1: project direct structural nets`

- ID: `ARCHITECTURE-DEBT-FRONTIER.3`
  Status: `deferred`
  Goal: `Extract large ISF parser/lowerer responsibilities only after stable families are identified.`
  Acceptance: `One exact extraction boundary is selected, implemented or deferred, and validated without behavior drift.`
  Verification: `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ARCHITECTURE-DEBT-FRONTIER.3: defer ISF extraction`

## Current Frontier

This tree is closed. Direct structural internal declaration nets shipped in
`.2.1`; ISF parser/lowerer extraction remains deferred until a future exact
owner can prove one stable behavior family.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ARCHITECTURE-DEBT-FRONTIER.1` | `done` | Selected direct backend convergence from completed architecture evidence. |
| 2 | `ARCHITECTURE-DEBT-FRONTIER.2` | `done` | Selected direct structural internal declaration nets as the first behavior-bearing convergence step. |
| 3 | `ARCHITECTURE-DEBT-FRONTIER.2.1` | `done` | Implemented direct storage/helper declaration-plan nets in `structural_rtl_ir.nets[]`; generated enable wires, assignments, instances, links, and HDL rerouting remain outside the slice. |
| 4 | `ARCHITECTURE-DEBT-FRONTIER.3` | `deferred` | No extraction is selected: the prior LoweringIR extraction tree already chose no candidate, later ISF commits show continued feature churn, and the import-tree audit still says extraction should wait for a stable family. |

## Decisions

- `2026-06-05`: Keep this tree proposed while the user-selected active focus is
  Composition/type.
- `2026-06-07`: Activated after `BACKEND-API-VALIDATION-FRONTIER.132` exhausted
  the active backend/API frontier and routed PNT to architecture-debt selection.
- `2026-06-07`: Selector leaf `ARCHITECTURE-DEBT-FRONTIER.1` chose
  `ARCHITECTURE-DEBT-FRONTIER.2` as the next executable lane. Evidence came from
  the completed direct-structural convergence tree's open behavior-bearing
  follow-up, the completed ISF LoweringIR extraction tree's no-extraction-yet
  outcome, and the import-tree audit's current direct-backend pressure notes.
- `2026-06-07`: Selector leaf `ARCHITECTURE-DEBT-FRONTIER.2` chose
  `ARCHITECTURE-DEBT-FRONTIER.2.1` as the first exact direct StructuralRTLIR
  convergence leaf. The selected boundary is storage/helper declaration-plan
  nets only; generated enable wires, behavior assignments, instances, links,
  and HDL emission rerouting remain outside this slice.
- `2026-06-07`: Implementation leaf `ARCHITECTURE-DEBT-FRONTIER.2.1` projected
  direct backend `signal_decls` and `aux_decls` into `structural_rtl_ir.nets[]`
  as declaration-only internal storage/helper nets, preserving width,
  signedness, state-model, and declared-type metadata. The next active
  architecture-debt frontier is `.3`.
- `2026-06-07`: Selector leaf `ARCHITECTURE-DEBT-FRONTIER.3` selected no ISF
  parser/lowerer extraction candidate now. The completed
  `ISF-LOWERINGIR-BOUNDARY-EXTRACTION` tree already deferred extraction, later
  `LoweringIR`/parser git history shows continued active feature delivery, and
  the import-tree audit still requires a stable family before extraction.
  `ARCHITECTURE-DEBT-FRONTIER` is exhausted.

## Open Questions

- None for this closed tree. Future ISF parser/lowerer extraction and future
  direct StructuralRTLIR enable-wire or assignment/connectivity work require a
  new or reactivated exact owner leaf before source changes.

## Blockers

- None for the active selector leaf.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- |
| `2026-06-05` | `ARCHITECTURE-DEBT-FRONTIER.1` | `pending` | `pending` |
| `2026-06-07` | `ARCHITECTURE-DEBT-FRONTIER.1` | Evidence review: `docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md`, `docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md`, `docs/BIN_FSMGEN_IMPORT_TREE.md`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | pass; selected `ARCHITECTURE-DEBT-FRONTIER.2` |
| `2026-06-07` | `ARCHITECTURE-DEBT-FRONTIER.2` | Evidence review: `perl/FSM/IR/StructuralRTLIRBuilder.pm`, `perl/FSM/Pipeline/DirectGenerationOrchestrator.pm`, `perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm`, `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm`, `t/1333-direct-structural-rtl-ir-projection.t`, `t/204-enable-graph-module-planning-support.t`; temp full-pipeline probe of the module-planning fixture; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | pass; selected `ARCHITECTURE-DEBT-FRONTIER.2.1` |
| `2026-06-07` | `ARCHITECTURE-DEBT-FRONTIER.2.1` | `perl -Iperl -c perl/FSM/IR/StructuralRTLIRBuilder.pm`; `perl -Iperl -c perl/FSM/Pipeline/DirectGenerationOrchestrator.pm`; `perl -Iperl -c perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm`; `prove -Iperl t/1333-direct-structural-rtl-ir-projection.t t/163-forward-structural-rtl-ir-surface.t t/190-pipeline-direct-generation-orchestrator.t t/204-enable-graph-module-planning-support.t t/303-normalized-semantic-json-supported-corpus.t t/341-normalized-semantic-structural-rtl-ir-contract.t t/334-normalized-semantic-forward-ir-contract.t t/330-normalized-semantic-payload-contract.t t/311-normalized-semantic-report-contract.t t/297-capability-manifest.t`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `bash knowledge-map/scripts/gen_knowledge_map.sh`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `mdbook build docs/book`; `git diff --check` | pass |
| `2026-06-07` | `ARCHITECTURE-DEBT-FRONTIER.3` | Evidence review: `docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md`, `docs/BIN_FSMGEN_IMPORT_TREE.md`, `git log --oneline -20 -- perl/FSM/Scheduler/ISF/LoweringIR.pm perl/FSM/Adapter/ISF/Parser.pm docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md`; `bash knowledge-map/scripts/check_knowledge_map.sh`; `scripts/check_memory_architecture.sh`; `prove -Iperl t/1414-docs-relative-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1303-isf-public-live-book-paths-audit.t`; `mdbook build docs/book`; `git diff --check` | pass; selected no extraction candidate |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ARCHITECTURE-DEBT-FRONTIER.1` | `ARCHITECTURE-DEBT-FRONTIER.1: select direct backend convergence` | selected `.2` after direct/backend and ISF extraction evidence review |
| `ARCHITECTURE-DEBT-FRONTIER.2` | `ARCHITECTURE-DEBT-FRONTIER.2: select direct structural internal nets` | selected `.2.1` as the first behavior-bearing direct StructuralRTLIR convergence leaf |
| `ARCHITECTURE-DEBT-FRONTIER.2.1` | `ARCHITECTURE-DEBT-FRONTIER.2.1: project direct structural nets` | shipped declaration-only direct storage/helper nets and routed PNT to `.3` |
| `ARCHITECTURE-DEBT-FRONTIER.3` | `ARCHITECTURE-DEBT-FRONTIER.3: defer ISF extraction` | selected no extraction candidate and exhausted active PNT |

## Changelog

- `2026-06-05`: Created proposed architecture-debt frontier owner tree.
- `2026-06-07`: Completed selector leaf `.1`; activated `.2` for direct backend
  StructuralRTLIR convergence selection.
- `2026-06-07`: Completed selector leaf `.2`; activated `.2.1` for direct
  internal storage/helper declaration nets in StructuralRTLIR.
- `2026-06-07`: Implemented `.2.1`; activated `.3` for ISF parser/lowerer
  extraction selection or deferral.
- `2026-06-07`: Deferred `.3`; closed the architecture-debt frontier with no
  active or proposed follow-up task tree remaining.
