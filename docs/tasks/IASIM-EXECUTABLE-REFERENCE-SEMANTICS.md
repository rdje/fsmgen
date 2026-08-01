# IASIM-EXECUTABLE-REFERENCE-SEMANTICS: Intent Abstraction Simulator

## Metadata

- Tree ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS`
- Status: `proposed`
- Roadmap lane: `HIAL/VIAL / native executable Intent Abstraction semantics / signoff`
- Created: `2026-08-01`
- Last updated: `2026-08-01`
- Owner: repo-local workflow

## Goal

Create IASIM, a deterministic, signoff-caliber executable semantics for the
Intent Abstraction world itself. IASIM should accept HIAL intent expressed at
IAL2, IAL1, or IAL0, execute VIAL verification intent against that design
model, and emit normalized traces and result manifests. Its semantic authority
must come from a precise native Intent Abstraction contract, not from any HDL,
HDL event scheduler, simulator, methodology library, or currently available
backend.

IASIM is both an executable specification of HIAL/VIAL meaning and a first-class
useful runtime even when no HDL is generated. The project must qualify its
accuracy natively through explicit semantics, independent executable oracles,
conformance vectors, bounded exhaustive cases, properties, cross-level
equivalence, deterministic replay, and measured semantic-rule coverage. HDL is
one optional downstream realization: later comparison with generated HDL tests
the lowering/backend, not the definition of IASIM semantics.

## Non-Goals

- Do not activate or implement IASIM in this capture; this is a proposed owner
  for architecture selection and later roadmap prioritization.
- Do not constrain IASIM's types, time model, events, updates, scheduling,
  hierarchy, verification mechanisms, or diagnostics to SystemVerilog, VHDL,
  UVM, an HDL simulator, or the least-common denominator of HDL backends.
- Do not implement a miniature SystemVerilog/VHDL simulator. Native Intent
  Abstraction meaning is primary; HDL-specific mappings belong to downstream
  lowering contracts and differential qualification.
- Do not claim that IASIM replaces HDL parsing, compilation, elaboration,
  simulator scheduling, four-state runtime qualification, or backend parity.
- Do not create three divergent schedulers for IAL2, IAL1, and IAL0. Each tier
  may require a direct semantic adapter into one canonical native execution
  model so IASIM can compare tier meaning without duplicating the engine.
- Do not reuse an HDL emitter's evaluator, scheduler, or translation logic as
  the IASIM engine; shared implementation could hide common-mode defects.
- Do not make IASIM compete with PGEN or NEXSIM. PGEN remains the HDL parser,
  NEXSIM remains the future HDL simulator, and IASIM should provide both a
  useful pre-HDL oracle and a future differential reference.
- Do not widen HIAL or VIAL semantics merely to make the first simulator slice
  easy. Unsupported behavior must be capability-gated and reported honestly.

## Acceptance Criteria

- A normative, versioned native Intent Abstraction semantics defines exactly
  what IASIM claims to simulate independently of all HDL languages and tools.
- An architecture audit proves which current HIAL semantic/lowered/structural
  IR projections are executable, identifies every missing semantic fact, and
  distinguishes native intent meaning from backend mapping choices.
- One versioned, immutable native execution model is selected. IAL2, IAL1, and
  IAL0 use level-specific semantic adapters into that model; production
  IAL2 -> IAL1 -> IAL0 lowering remains a separately comparable path so direct
  and lowered meaning can expose translation defects.
- VIAL continues to use its existing versioned `VIALExecutionIR`; a typed
  HIAL/VIAL bridge defines stimulus, clock/reset, settle/update, observation,
  reaction, and checking order without backend-specific behavior.
- Native value, time, event, concurrency, and update semantics are exact and
  explicit: widths, signedness, truncation, enums/aggregates, intent-level
  unknown/uninitialized/conflict values, equality and logic, settling,
  state updates, reset, domains/clocks, ordering, and deterministic randomness
  are implemented or capability-gated. HDL X/Z and event regions are mappings,
  not unexamined semantic defaults.
- The implementation is independent from HDL backends while schemas, type
  definitions, source identity, and normalized result contracts may be shared.
- The first bounded runtime profile is deterministic, repository-local,
  resource-bounded, and honest about deferred multi-domain, analog, physical-
  timing, or native-extension behavior.
- IASIM signoff has an explicit evidence contract: a small definition-oriented
  reference interpreter or equivalent independent executable oracle; manually
  derived boundary vectors; semantic-rule and negative-path coverage;
  property/metamorphic testing; bounded exhaustive state exploration;
  IAL2/IAL1/IAL0 direct-versus-lowered equivalence; deterministic replay; and
  mutation or fault-seeding evidence that the suite detects plausible engine
  defects. Any optimized engine is differentially checked against the reference.
- The checked AHB HIAL/VIAL fixture provides the first end-to-end oracle and
  compares the same normalized public outcomes already shared by the
  handwritten and Verilator paths.
- Later differential gates distinguish: native IASIM semantic signoff,
  IAL-level lowering equivalence, HDL code-generation validation, open-tool
  parsing/compile/elaboration/runtime evidence, and capability-qualified
  HDL-simulator parity. None is silently substituted for another.
- Public commands, artifacts, limits, diagnostics, examples, mdBook guidance,
  Knowledge Map facts, and same-volume storage behavior are documented and
  tested before IASIM becomes a supported surface.
- Each completed active leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS`
  Status: `proposed`
  Goal: `Deliver a deterministic independent HIAL/VIAL runtime whose native Intent Abstraction semantics and accuracy are signoff-qualified without dependence on HDL.`
  Children: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.2, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.3, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.4, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.5, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.6, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.7, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.8, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.9`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1`
  Status: `proposed`
  Goal: `Select IASIM's native semantic authority, executable boundary, independence rules, signoff evidence contract, and first bounded profile.`
  Acceptance: `Define the rule that IASIM semantics are native Intent Abstraction semantics rather than HDL-derived behavior. Inventory the exact HIAL facts exposed by intent_hir, lowered_rtl_ir, structural_rtl_ir, canonical IAL lowering, and the HIALVIALBridgeManifest; inventory VIALExecutionIR and normalized result contracts; identify gaps needed for execution; select one canonical execution engine with direct IAL2/IAL1/IAL0 semantic adapters; define how production lowering remains an independently compared path; define the implementation/common-mode-defect boundary, HIAL/VIAL scheduling seam, and signoff evidence stack; distinguish native intent signoff from backend and HDL-simulator evidence; record capabilities, resource bounds, public/non-public boundaries, risks, alternatives, and the smallest implementation sequence. This leaf is documentation and selection only.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.2`
  Status: `proposed`
  Goal: `Specify the versioned native Intent Abstraction execution model and direct IAL2/IAL1/IAL0 semantic adapters selected by .1.`
  Acceptance: `Specify an immutable HDL-independent executable model for hierarchy, types, parameters, signals, state, domains/clocks/resets, combinational and state updates, expressions, assertions/properties in scope, source maps, capabilities, and limits; specify each IAL tier's direct semantic adapter; keep production reviewable lowering as a distinct route whose normalized meaning can be compared rather than reused as the oracle.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.3`
  Status: `proposed`
  Goal: `Specify exact native IASIM value, time, event, concurrency, update, and deterministic replay semantics.`
  Acceptance: `Define arbitrary-width signed and unsigned values, truncation/extension, native unknown/uninitialized/conflict algebra, equality/logic, aggregate behavior, settling and non-convergence, domain/clock/reset transitions, atomic or staged state updates, multi-domain ordering or explicit deferral, deterministic randomness, diagnostics, and resource ceilings. Justify each rule from Intent Abstraction meaning rather than HDL precedent; specify HDL X/Z and scheduler mappings separately; publish executable and manually derived conformance vectors.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.4`
  Status: `proposed`
  Goal: `Implement the first simple definition-oriented native IASIM reference engine.`
  Acceptance: `Implement the .2/.3 contracts for the selected bounded profile with clarity and semantic correspondence as the priority; import no HDL-emitter evaluation, lowering, or scheduling logic; preserve source-to-execution diagnostics; fail closed on unsupported capabilities and exhausted resource limits; prove deterministic byte-identical normalized traces across reruns. Treat this engine as an independently testable oracle, not a performance implementation.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.5`
  Status: `proposed`
  Goal: `Co-simulate VIALExecutionIR against the HIAL reference engine through the typed bridge.`
  Acceptance: `Bind existing VIAL types/endpoints/domains/transactions/events/scenarios/models/scoreboards/coverage/faults/randomness to HIAL carriers; specify and implement deterministic drive -> HIAL settle/edge/update -> sample -> react -> check behavior; reject unresolved or capability-incompatible bindings before execution.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.6`
  Status: `proposed`
  Goal: `Ship bounded public IASIM commands, atomic artifacts, normalized traces/results, and diagnostics.`
  Acceptance: `Select the smallest intent-oriented CLI/API surface; keep inputs and all outputs repository-relative and same-volume; write artifacts atomically; expose exact engine/schema/profile identity, source identity, seed/replay data, capability truth, limits, and source-mapped diagnostics; preserve normal/terse equivalence where applicable.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.7`
  Status: `proposed`
  Goal: `Qualify IASIM accuracy through an independent native semantic signoff campaign.`
  Acceptance: `Build manually derived positive/negative boundary vectors for every supported semantic rule; add property and metamorphic suites, bounded exhaustive small-model exploration, cross-level direct-versus-lowered equivalence, deterministic replay, semantic-rule/branch/error coverage, and mutation or seeded-defect detection; if an optimized engine exists, prove normalized differential parity with the definition-oriented reference engine. Publish exact tool versions, seeds, limits, exclusions, residual risks, and a versioned signoff manifest.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.8`
  Status: `proposed`
  Goal: `Establish AHB reference execution and optional staged differential parity with available and future HDL realizations.`
  Acceptance: `Run the checked AHB HIAL/VIAL fixture under IASIM; first judge it by the native .7 signoff contract, then compare its normalized public outcomes with the existing handwritten and Verilator paths; classify disagreements by source intent, IAL lowering, IASIM, HDL generation, or HDL runtime; define future capability-gated comparison with native UVM, VHDL, PGEN plus NEXSIM, and commercial HDL simulators without making any external HDL path an IASIM dependency or semantic authority.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.9`
  Status: `proposed`
  Goal: `Close supported native semantics, scale, documentation, and long-term signoff maintenance.`
  Acceptance: `Exercise representative HIAL/VIAL families, unsupported-capability failures, native unknown/conflict and scheduling edge cases, deterministic replay, and bounded large fixtures; document IASIM thoroughly in the mdBook with runnable examples that require no HDL; publish the exact native signoff claim and optional downstream proof ladder; prevent semantic drift between specification, adapters, engines, generators, and external-runtime comparisons.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed and not PNT-eligible until the roadmap or director
explicitly activates it. Its first activation must complete the architecture
and proof-boundary audit before any simulator code, command, or artifact is
implemented.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1` | `proposed` | Define native Intent Abstraction authority, determine whether current HIAL/VIAL projections are executable, and select an independent signoff stack before implementation. |

## Decisions

- `2026-08-01`: Name the proposed engine **IASIM**, for Intent Abstraction
  Simulator. The broader name intentionally covers HIAL and VIAL rather than
  presenting the engine as only an interpreter for one IAL tier.
- `2026-08-01`: Preserve IASIM as an executable reference-semantics and
  differential-oracle proposal. It is a first-class runtime in its own right;
  no HDL generation or simulator is required to use or sign off its native
  Intent Abstraction semantics.
- `2026-08-01`: Prefer one canonical executable model and engine with direct
  semantic adapters for IAL2, IAL1, and IAL0. Keep production tier lowering as
  an independently comparable route so IASIM can expose lowering defects
  without maintaining three divergent schedulers.
- `2026-08-01`: Require implementation independence from HDL backend evaluators
  and schedulers. Sharing contracts and schemas is acceptable; sharing the
  translation mechanism whose correctness IASIM should check is not.
- `2026-08-01`: IASIM value/time/event/update semantics must be chosen from
  Intent Abstraction meaning. HDL X/Z values, event regions, timing, and
  methodology behavior are explicit downstream mappings, never implicit
  constraints on the IASIM world.
- `2026-08-01`: Define IASIM accuracy by a versioned native signoff contract,
  including an independent definition-oriented interpreter or equivalent
  oracle, manually derived conformance vectors, properties/metamorphic tests,
  bounded exhaustive cases, cross-level equivalence, deterministic replay,
  semantic coverage, and mutation/seeded-defect detection.
- `2026-08-01`: Treat PGEN and NEXSIM as complementary. IASIM provides a
  pre-HDL executable oracle now and can later provide golden normalized results
  for PGEN/NEXSIM and commercial-simulator differential qualification.

## Open Questions

- Do the current public HIAL semantic projections contain a complete execution
  model, or must FSMGen add a private `HIALExecutionIR` distinct from their
  bounded report projections?
- How independent must each IAL2/IAL1/IAL0 semantic adapter be from production
  lowering to reveal realistic translation bugs without needless duplication?
- Which unknown, uninitialized, conflict, or high-impedance concepts belong to
  native Intent Abstraction semantics, and which exist only in an HDL mapping?
- What is the smallest useful first profile beyond the existing single-clock
  checked AHB fixture, and which multi-clock/event semantics must be present in
  v1 rather than capability-deferred?
- Should the public entry point be `fsmgen iasim`, a mode under `fsmgen vial`,
  or both through one underlying API?

## Blockers

- None for the architecture audit. The tree is intentionally proposed until
  selected by roadmap/director priority; no HDL language, generator, parser,
  simulator, or methodology library is required to audit, implement, or
  signoff the native IASIM engine.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-01` | `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1` | `pending` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1` | `pending` | Proposed architecture/proof-boundary audit only; no implementation selected. |

## Changelog

- `2026-08-01`: Captured the director's IASIM proposal as a proposed owner so
  the executable-intent and differential-oracle idea, proof boundary, and
  independence risk do not live only in session chat.
- `2026-08-01`: Refined IASIM as a fully native Intent Abstraction world that
  is neither constrained nor qualified by HDL; added the independent evidence
  stack required for an accurate, signoff-caliber simulator claim.
