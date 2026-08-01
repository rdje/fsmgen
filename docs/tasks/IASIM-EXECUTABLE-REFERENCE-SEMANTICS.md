# IASIM-EXECUTABLE-REFERENCE-SEMANTICS: Intent Abstraction Simulator

## Metadata

- Tree ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS`
- Status: `proposed`
- Roadmap lane: `HIAL/VIAL / executable intent reference semantics / differential validation`
- Created: `2026-08-01`
- Last updated: `2026-08-01`
- Owner: repo-local workflow

## Goal

Create IASIM, a deterministic executable reference-semantics engine for the
Intent Abstraction stack. IASIM should accept HIAL intent through the canonical
IAL2/IAL1/IAL0 lowering routes, execute VIAL verification intent against that
design model, and emit normalized traces and result manifests. Its primary role
is to validate intent now and later serve as an independent golden oracle for
differential comparison with generated HDL running under Verilator, PGEN plus
NEXSIM, or a capability-qualified commercial simulator.

IASIM is an executable specification of HIAL/VIAL meaning. A passing IASIM run
is strong evidence that the intent and reference semantics behave as designed;
it is not proof that an HDL backend preserved those semantics or that generated
HDL compiles, elaborates, schedules, or runs correctly in an HDL simulator.

## Non-Goals

- Do not activate or implement IASIM in this capture; this is a proposed owner
  for architecture selection and later roadmap prioritization.
- Do not claim that IASIM replaces HDL parsing, compilation, elaboration,
  simulator scheduling, four-state runtime qualification, or backend parity.
- Do not create three divergent simulators for IAL2, IAL1, and IAL0 before the
  architecture audit decides the smallest canonical executable boundary.
- Do not reuse an HDL emitter's evaluator, scheduler, or translation logic as
  the IASIM engine; shared implementation could hide common-mode defects.
- Do not make IASIM compete with PGEN or NEXSIM. PGEN remains the HDL parser,
  NEXSIM remains the future HDL simulator, and IASIM should provide both a
  useful pre-HDL oracle and a future differential reference.
- Do not widen HIAL or VIAL semantics merely to make the first simulator slice
  easy. Unsupported behavior must be capability-gated and reported honestly.

## Acceptance Criteria

- An architecture audit proves which current HIAL semantic/lowered/structural
  IR projections are executable and identifies every missing semantic fact.
- One versioned, immutable executable boundary is selected for HIAL, or a
  narrower alternative is justified; IAL2/IAL1/IAL0 inputs reach it only
  through canonical reviewable lowering routes.
- VIAL continues to use its existing versioned `VIALExecutionIR`; a typed
  HIAL/VIAL bridge defines stimulus, clock/reset, settle/update, observation,
  reaction, and checking order without backend-specific behavior.
- Value and time semantics are exact and explicit: arbitrary widths,
  signedness, truncation, enums/aggregates where present, four-state values,
  equality and logic, combinational settling, sequential updates, reset,
  clocks, event ordering, and deterministic randomness are either implemented
  or capability-gated.
- The implementation is independent from HDL backends while schemas, type
  definitions, source identity, and normalized result contracts may be shared.
- The first bounded runtime profile is deterministic, repository-local,
  resource-bounded, and honest about deferred multi-clock, analog, timing, or
  native-language behavior.
- The checked AHB HIAL/VIAL fixture provides the first end-to-end oracle and
  compares the same normalized public outcomes already shared by the
  handwritten and Verilator paths.
- Later differential gates distinguish: intent validation in IASIM, lowering
  and code-generation validation, open-tool parsing/compile/elaboration/runtime
  evidence, and capability-qualified HDL-simulator parity.
- Public commands, artifacts, limits, diagnostics, examples, mdBook guidance,
  Knowledge Map facts, and same-volume storage behavior are documented and
  tested before IASIM becomes a supported surface.
- Each completed active leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS`
  Status: `proposed`
  Goal: `Deliver a deterministic independent HIAL/VIAL executable reference engine and normalized differential oracle without conflating intent validation with HDL signoff.`
  Children: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.2, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.3, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.4, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.5, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.6, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.7, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.8`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1`
  Status: `proposed`
  Goal: `Audit executable completeness and select IASIM's semantic boundary, independence rules, proof claims, and first bounded profile.`
  Acceptance: `Inventory the exact HIAL facts exposed by intent_hir, lowered_rtl_ir, structural_rtl_ir, canonical IAL lowering, and the HIALVIALBridgeManifest; inventory VIALExecutionIR and normalized result contracts; identify gaps needed for execution; select one canonical execution model versus tier-specific interpreters; define the independent-implementation/common-mode-defect boundary; define the HIAL/VIAL scheduling seam; distinguish intent evidence from backend and HDL-simulator evidence; record capabilities, resource bounds, public/non-public boundaries, risks, alternatives, and the smallest implementation sequence. This leaf is documentation and selection only.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.2`
  Status: `proposed`
  Goal: `Specify the versioned HIAL executable IR and canonical IAL2/IAL1/IAL0 ingestion routes selected by .1.`
  Acceptance: `Specify an immutable target-neutral executable model for hierarchy, types, parameters, signals, state, clocks/resets, combinational and sequential updates, expressions, assertions/properties in scope, source maps, capabilities, and limits; prove every accepted IAL route reaches it through existing reviewable lowering rather than a hidden direct path.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.3`
  Status: `proposed`
  Goal: `Specify exact IASIM value, time, event, update, and deterministic replay semantics.`
  Acceptance: `Define arbitrary-width signed and unsigned values, truncation/extension, four-state X/Z algebra, equality/logic, aggregate behavior in scope, combinational fixpoint and non-convergence handling, clock/reset transitions, nonblocking-style state updates, multi-domain ordering or explicit deferral, deterministic randomness, diagnostics, and resource ceilings with executable conformance vectors.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.4`
  Status: `proposed`
  Goal: `Implement the first independent deterministic HIAL reference engine.`
  Acceptance: `Implement the .2/.3 contracts without importing HDL-emitter evaluation or scheduling logic; support the selected bounded profile; preserve source-to-execution diagnostics; fail closed on unsupported capabilities and exhausted resource limits; prove deterministic byte-identical normalized traces across reruns.`
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
  Goal: `Establish AHB reference execution and staged differential parity across available and future backends.`
  Acceptance: `Run the checked AHB HIAL/VIAL fixture under IASIM and compare its normalized public outcomes with the existing handwritten and Verilator result paths; classify disagreements by source intent, lowering, IASIM, backend generation, or runtime; define future capability-gated comparison with native UVM, VHDL, PGEN plus NEXSIM, and commercial HDL simulators without claiming unavailable evidence.`
  Verification: `pending`
  Commit: `pending`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.8`
  Status: `proposed`
  Goal: `Close supported semantics, scale, documentation, and long-term oracle maintenance.`
  Acceptance: `Exercise representative HIAL/VIAL families, unsupported-capability failures, four-state and scheduling edge cases, deterministic replay, and bounded large fixtures; document IASIM thoroughly in the mdBook with runnable lowering-clean examples; publish the exact proof ladder and prevent semantic drift between contracts, engine, generators, and external-runtime comparisons.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

This tree is proposed and not PNT-eligible until the roadmap or director
explicitly activates it. Its first activation must complete the architecture
and proof-boundary audit before any simulator code, command, or artifact is
implemented.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1` | `proposed` | Determine whether current HIAL projections are executable, select the canonical boundary, and prevent IASIM from becoming either three divergent interpreters or a self-validating copy of the HDL backend. |

## Decisions

- `2026-08-01`: Name the proposed engine **IASIM**, for Intent Abstraction
  Simulator. The broader name intentionally covers HIAL and VIAL rather than
  presenting the engine as only an interpreter for one IAL tier.
- `2026-08-01`: Preserve IASIM as an executable reference-semantics and
  differential-oracle proposal. It may establish intent-level confidence but
  cannot replace generated-HDL compilation, elaboration, runtime, or parity.
- `2026-08-01`: Prefer one canonical executable model reached from
  IAL2/IAL1/IAL0 through normal lowering. The audit may select a different
  boundary if the existing IR evidence shows that this would hide a material
  class of lowering defects.
- `2026-08-01`: Require implementation independence from HDL backend evaluators
  and schedulers. Sharing contracts and schemas is acceptable; sharing the
  translation mechanism whose correctness IASIM should check is not.
- `2026-08-01`: Treat PGEN and NEXSIM as complementary. IASIM provides a
  pre-HDL executable oracle now and can later provide golden normalized results
  for PGEN/NEXSIM and commercial-simulator differential qualification.

## Open Questions

- Do the current public HIAL semantic projections contain a complete execution
  model, or must FSMGen add a private `HIALExecutionIR` distinct from their
  bounded report projections?
- Should selected IAL2 or IAL1 constructs later gain independent high-level
  semantic oracles to test tier-to-tier lowering, after the canonical engine
  exists, rather than duplicating the whole simulator initially?
- Which four-state semantics are intrinsic HIAL meaning and which are properties
  of a particular HDL lowering or external runtime?
- What is the smallest useful first profile beyond the existing single-clock
  checked AHB fixture, and which multi-clock/event semantics must be present in
  v1 rather than capability-deferred?
- Should the public entry point be `fsmgen iasim`, a mode under `fsmgen vial`,
  or both through one underlying API?

## Blockers

- None for the architecture audit. The tree is intentionally proposed until
  selected by roadmap/director priority; no HDL simulator is required to audit
  or implement the bounded reference engine.

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
