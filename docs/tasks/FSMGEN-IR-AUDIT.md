# FSMGEN-IR-AUDIT: IR Inventory And Consolidation Audit

## Metadata

- Tree ID: `FSMGEN-IR-AUDIT`
- Status: `proposed`
- Roadmap lane: `architecture backlog`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Audit the IR structures currently used across FSMGen, decide which ones are
canonical phase boundaries versus local implementation conveniences, and define
a standard for when future work may introduce, reuse, merge, or retire an IR.

The goal is not to force one universal IR. The goal is to prevent accidental
IR sprawl: every IR should have a named owner, source-of-truth role, consumer
set, lifecycle, and documented handoff contract.

## Non-Goals

- Do not pause the active `R14` ISF feature work for this audit.
- Do not refactor compiler internals before the inventory and recommendation
  leaves establish the exact target.
- Do not freeze every private implementation structure as public API.
- Do not collapse semantically different phases into one oversized IR merely
  for naming uniformity.

## Acceptance Criteria

- The current IR and IR-like structures are inventoried with file/package
  ownership, producers, consumers, serialized/report surfaces, and mutability
  assumptions.
- Each structure is classified as parsed syntax, semantic intent, scheduling,
  lowered behavior, structural/connectivity, backend/emission, composition
  planning, or report/contract projection.
- Redundant or overlapping structures are called out with concrete risks and
  possible consolidation paths.
- A repo-local IR policy defines when a new feature should reuse an existing
  IR, extend an existing IR, create a new IR, or emit through a textual
  handoff.
- Any accepted refactor follow-up is split into executable leaves before code
  changes start.
- Live docs, roadmap status, and task-tree state stay synchronized.

## Task Tree

- ID: `FSMGEN-IR-AUDIT`
  Status: `proposed`
  Goal: `Audit and rationalize FSMGen IR ownership, boundaries, and creation policy.`
  Children: `FSMGEN-IR-AUDIT.1`, `FSMGEN-IR-AUDIT.2`,
  `FSMGEN-IR-AUDIT.3`, `FSMGEN-IR-AUDIT.4`

- ID: `FSMGEN-IR-AUDIT.1`
  Status: `proposed`
  Goal: `Inventory current IR and IR-like structures.`
  Acceptance: `The task file or companion doc lists all known IR structures,
  including ISF AST/lowering IR, CoreAST, IntentHIR, LoweredRTLIR,
  StructuralRTLIR, composition parse/plan objects, backend helper structures,
  and normalized report contracts, with producer and consumer notes.`
  Verification: `pending`
  Commit: `pending`

- ID: `FSMGEN-IR-AUDIT.2`
  Status: `proposed`
  Goal: `Classify canonical boundaries versus local projections.`
  Acceptance: `Every inventoried structure has a phase classification,
  source-of-truth status, public/private status, and reason it should be kept,
  merged, or treated as derived data.`
  Verification: `pending`
  Commit: `pending`

- ID: `FSMGEN-IR-AUDIT.3`
  Status: `proposed`
  Goal: `Define the repo-local policy for adding or extending IRs.`
  Acceptance: `The policy says what a new IR must document before landing:
  owner, producer, consumers, invariants, serialization/report contract,
  defensive-copy boundary, and migration/retirement plan if temporary.`
  Verification: `pending`
  Commit: `pending`

- ID: `FSMGEN-IR-AUDIT.4`
  Status: `proposed`
  Goal: `Propose consolidation or standardization follow-up slices.`
  Acceptance: `Concrete follow-up leaves are created only where the audit
  finds actionable duplication, unsafe handoffs, or missing canonical
  ownership. Non-actionable differences are documented as deliberate.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed, not active. It is not PNT-eligible until explicitly
activated or until the active roadmap lane selects architecture consolidation
work.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `FSMGEN-IR-AUDIT.1` | `proposed` | The first useful step is factual inventory before prescribing consolidation. |

## Initial IR Inventory Targets

The first inventory leaf should at least inspect these families:

- ISF parse/actor shell: `FSM::Adapter::ISF` and
  `FSM::Adapter::ISF::LispishAdapter`.
- ISF scheduling/lowering IR: `FSM::Scheduler::ISF::LoweringIR` plus the
  `.fsm`, JSON, and generated-top emitters that consume it.
- Direct `.fsm` syntax and semantic model: `FSM::CoreAST` and related parser
  products.
- Forward compiler IRs: `FSM::IR::IntentHIR`, `FSM::IR::LoweredRTLIR`, and
  `FSM::IR::StructuralRTLIR`.
- Composition structures: `FSM::Composition::Top`, ports, child declarations,
  `RealizedInstance`, `Plan`, nets, links, and shared-datapath metadata.
- Backend/emission structures that are IR-like but not currently named as IR.
- Normalized public report contracts under `FSM::Support::NormalizedSemantic*`
  and related serializable snapshot helpers.

## Decisions

- `2026-05-14`: Multiple IRs are acceptable when they represent distinct
  compiler phases or public projection boundaries. The audit should reduce
  accidental duplication and unclear ownership, not collapse the compiler into
  a single mega-IR.
- `2026-05-14`: Future IR additions should be treated as architectural
  decisions. A new IR needs an owner, phase name, invariants, producer,
  consumers, public/private status, and an explanation of why extending an
  existing IR or using an existing handoff is not enough.
- `2026-05-14`: The current `.isf -> ISF LoweringIR -> scheduled .fsm text ->
  normal .fsm pipeline -> forward/backend IRs -> SV` flow is valid as a
  shipped boundary, but it should be audited as part of this tree because the
  textual `.fsm` handoff may or may not remain the best long-term boundary.

## Open Questions

- Which IRs are canonical enough to become explicitly documented phase
  boundaries, and which are private projections that should stay flexible?
- Should ISF eventually lower into an existing FSM/CoreAST or forward IR
  directly, or is the scheduled `.fsm` textual handoff the right reviewable
  and debuggable boundary?
- Which public normalized semantic report objects are true IR projections and
  which are intentionally report-only summaries?

## Blockers

- None. This tree is proposed and intentionally does not block `R14` feature
  delivery.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `FSMGEN-IR-AUDIT` | `git diff --check -- docs/tasks/FSMGEN-IR-AUDIT.md docs/TASK_TREE.md README.md ROADMAP_STATUS.md CHANGES.md DEVELOPMENT_NOTES.md MEMORY.md LIVE_ACHIEVEMENT_STATUS.md` | `pass` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `FSMGEN-IR-AUDIT` | `FSMGEN-IR-AUDIT: capture IR audit task tree` | Created proposed task tree. |

## Changelog

- `2026-05-14`: Created proposed task tree to capture IR inventory and
  consolidation audit work without interrupting active `R14` ISF feature
  delivery.
