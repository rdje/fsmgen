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

IASIM is both an executable specification of HIAL/VIAL meaning and the small,
independently qualified execution kernel for the proposed complete xIAL-native
development framework. It remains directly useful even when no HDL is
generated. The project must qualify its
accuracy natively through explicit semantics, independent executable oracles,
conformance vectors, bounded exhaustive cases, properties, cross-level
equivalence, deterministic replay, and measured semantic-rule coverage. HDL is
a downstream realization rather than IASIM's semantic authority: later
comparison with generated HDL tests the lowering/backend, not the definition of
IASIM semantics. The sibling xIAL framework separately requires signoff-grade
HDL export qualification for every profile FSMGen advertises as publishable.

The definition-oriented IASIM reference kernel is Perl 5 first. Perl is an
appropriate fast implementation language for this control- and semantics-heavy
work, matches FSMGen's current semantic authority, and optimizes development
clarity before speculative throughput work. Performance claims must come from
representative xIAL workloads and profiling. If a measured hot path later
justifies native acceleration, Rust may implement only that bounded component
behind a stable versioned C ABI and shared library consumed by Perl; Perl keeps
semantic orchestration and reference authority, and the accelerated route must
remain differentially equivalent to the pure-Perl route.

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
- Do not absorb workspaces, reusable IP/VIP package management, authoring/IDE
  services, rich trace storage, interactive clients, regression orchestration,
  visualization, coverage closure, or signoff governance into the trusted
  engine. `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK` owns that ecosystem around a
  stable IASIM kernel/session boundary.
- Do not pre-emptively rewrite IASIM in Rust or treat a full-language migration
  as the default performance plan. Native acceleration is optional, measured,
  component-scoped, and subordinate to the Perl reference semantics.

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
  HDL-simulator parity. When an HDL simulator exposes versioned semantic
  introspection, common source-mapped checkpoints identify the first
  divergence instead of comparing only final results. None is silently
  substituted for another.
- Public commands, artifacts, limits, diagnostics, examples, mdBook guidance,
  Knowledge Map facts, and same-volume storage behavior are documented and
  tested before IASIM becomes a supported surface.
- A stable versioned kernel/session/query contract exposes IASIM to the xIAL
  framework without allowing clients or framework orchestration to redefine
  values, time, events, updates, randomness, or normalized results.
- The first definition-oriented engine is implemented in Perl 5. Any later
  Rust accelerator is admitted only after representative profiling identifies
  a bounded hotspot, uses a stable versioned C ABI (`Rust -> shared library ->
  Perl`), defines ownership and error/panic boundaries explicitly, and proves
  deterministic normalized differential equivalence with the pure-Perl path.
- Each completed active leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS`
  Status: `proposed`
  Goal: `Deliver a deterministic independent HIAL/VIAL runtime whose native Intent Abstraction semantics and accuracy are signoff-qualified without dependence on HDL.`
  Children: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.2, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.3, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.4, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.5, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.6, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.7, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.8, IASIM-EXECUTABLE-REFERENCE-SEMANTICS.9`

- ID: `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1`
  Status: `proposed`
  Goal: `Select IASIM's native semantic authority, executable boundary, independence rules, signoff evidence contract, and first bounded profile.`
  Acceptance: `Define the rule that IASIM semantics are native Intent Abstraction semantics rather than HDL-derived behavior. Inventory the exact HIAL facts exposed by intent_hir, lowered_rtl_ir, structural_rtl_ir, canonical IAL lowering, and the HIALVIALBridgeManifest; inventory VIALExecutionIR and normalized result contracts; identify gaps needed for execution; select one canonical execution engine with direct IAL2/IAL1/IAL0 semantic adapters; define how production lowering remains an independently compared path; define the implementation/common-mode-defect boundary, HIAL/VIAL scheduling seam, and signoff evidence stack; select Perl 5 as the definition-oriented reference-engine language; require representative profiling before optimization; constrain any later Rust acceleration to measured bounded hotspots behind a versioned C ABI/shared-library boundary with explicit ownership, error, panic, determinism, and pure-Perl differential-equivalence rules; distinguish native intent signoff from backend and HDL-simulator evidence; record capabilities, resource bounds, public/non-public boundaries, risks, alternatives, and the smallest implementation sequence. This leaf is documentation and selection only.`
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
  Acceptance: `Implement the .2/.3 contracts in Perl 5 for the selected bounded profile with clarity and semantic correspondence as the priority; import no HDL-emitter evaluation, lowering, or scheduling logic; preserve source-to-execution diagnostics; fail closed on unsupported capabilities and exhausted resource limits; prove deterministic byte-identical normalized traces across reruns. Treat this engine as an independently testable oracle, not a performance implementation, and gather representative profiles before proposing native acceleration.`
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
  Goal: `Ship bounded public IASIM commands plus the stable kernel/session/query contract consumed by the xIAL framework.`
  Acceptance: `Select the smallest intent-oriented CLI and kernel/session/query API surface; keep inputs and all outputs repository-relative and same-volume; write artifacts atomically; expose exact engine/schema/profile identity, source identity, seed/replay data, capability truth, limits, source-mapped diagnostics, state/control/query boundaries, cancellation, and deterministic normalized traces/results; preserve normal/terse equivalence where applicable; prevent framework/client policy from changing semantic execution.`
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
  Acceptance: `Run the checked AHB HIAL/VIAL fixture under IASIM; first judge it by the native .7 signoff contract, then compare its normalized public outcomes with the existing handwritten and Verilator paths. Define a versioned common-checkpoint vocabulary over source/semantic IDs, logical time, values, transitions, events, transactions, checks, coverage, and results. For future PGEN plus NEXSIM qualification, consume only the exact capability-declared NEXSIM semantic-introspection API/MCP profile selected by HIAL/VIAL .13.3; map stable snapshot identities through generated source maps; compare snapshot-consistent bounded observations against IASIM without allowing MCP control to change either semantic oracle; stop at and preserve the first divergence with replay evidence; and classify disagreements by source intent, direct-versus-lowered IAL meaning, IASIM, UVM generation, PGEN handoff, elaboration, NEXSIM scheduler/runtime, provider adapter, or unsupported capability. Keep final normalized parity as a required closure gate, and define equivalent optional comparisons with native UVM, VHDL, and commercial HDL simulators without making any external HDL path an IASIM dependency or semantic authority.`
  Verification: `NEXSIM deep-semantic API/MCP direction is captured for future differential design; exact checkpoint schema and provider identities remain pending .1/.2/.3 IASIM contracts plus capability-ready .13.3 releases`
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
- `2026-08-01`: NEXSIM's planned deep semantic-introspection API operated via
  MCP upgrades future differential qualification from final-result comparison
  to first-divergence localization. IASIM owns the native side of a versioned
  common-checkpoint vocabulary; `.13.3` owns the exact provider API/MCP profile.
  Stable source-mapped identities and replay evidence join the two without
  making NEXSIM, MCP, or the adapter authoritative over Intent Abstraction.
- `2026-08-01`: IASIM is the small trusted execution kernel inside the proposed
  `XIAL-NATIVE-DEVELOPMENT-FRAMEWORK`. The sibling tree owns the complete
  authoring/reuse/debug/regression/visualization/signoff ecosystem through a
  stable kernel/session contract; it does not enlarge or redefine IASIM meaning.
- `2026-08-01`: IASIM does not require HDL for native qualification, but its
  normalized outcomes are mandatory golden evidence for every supported
  publishable xIAL-to-HDL framework profile; export quality and standards
  conformance remain separate first-class product signoff claims.
- `2026-08-01`: Use Perl 5 for the definition-oriented IASIM reference kernel.
  Treat current performance as adequate until representative xIAL profiling
  proves otherwise. A future measured hotspot may be delegated to Rust as a
  shared library through a stable versioned C ABI; Perl remains the semantic
  orchestrator/reference, and differential equivalence is mandatory. A full
  IASIM rewrite is neither required nor the default plan.

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
  an xIAL-framework command, or several clients over one underlying kernel API?
- Which representative xIAL workloads and budgets should establish whether a
  particular Perl kernel path is genuinely hot enough to justify acceleration?
- What is the smallest common semantic-checkpoint vocabulary that can compare
  IASIM with NEXSIM deeply enough to localize a first divergence without
  encoding SystemVerilog scheduler details as native Intent Abstraction rules?

## Blockers

- None for the architecture audit. The tree is intentionally proposed until
  selected by roadmap/director priority; no HDL language, generator, parser,
  simulator, or methodology library is required to audit, implement, or
  signoff the native IASIM engine.

## Acceptance Checklist (enforced) — Perl-first proposal refinement

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Perl 5 first' --all
  --oneline -- docs/tasks/IASIM-EXECUTABLE-REFERENCE-SEMANTICS.md
  docs/book/src/16d-hial-vial-verification-architecture.md
  doctrine/live_document_size/surfaces.jsonl` returns no commit. The proposed
  IASIM tree selected an independent definition-oriented engine and optional
  optimized-engine differential checking but did not durably select its first
  implementation language, profiling threshold, or native-acceleration
  boundary; those facts otherwise existed only in the director conversation.
- [x] **ADDRESSED (verified)** — The task-tree, task index, mdBook, fact card,
  generated Knowledge Map, and bounded Memory now select Perl 5 for the
  proposed reference kernel, require representative xIAL profiling before
  optimization, and constrain optional Rust acceleration to measured bounded
  hotspots behind a stable versioned C ABI/shared library while Perl retains
  semantic authority. Maintained-reference verification accepts the exact
  mdBook transition 50/47,781/2,531,937 -> 50/47,809/2,533,568, or delta
  0/+28/+1,631.
- [x] **NO REGRESSION** — `prove -l t/1414-docs-relative-paths-audit.t
  t/1549-task-tree-integrity-doctrine.t
  t/1560-live-document-ceiling-authority.t
  t/1561-live-document-reference-authority.t
  t/1567-knowledge-map-shards.t t/1568-knowledge-card-history.t` reports `All
  tests successful` at `Files=6, Tests=62`. All 49 mdBook chapters test and the
  repository-local HTML build passes before exact cleanup; Knowledge Map is
  current at 1,104 facts/5,619 questions/5,785 occurrences/117 shards, Memory
  is 47 lines, and IASIM remains proposed with no engine, command, artifact,
  runtime, performance, or signoff claim.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-01` | `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1` | `pending` | `pending` |
| `2026-08-01` | `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.8` provider clarification | task/index/Memory continuity; relative paths/task integrity/Knowledge Map/diff/staged docs-only acceptance/doctrines | `passed`; focused docs/task checks report `All tests successful` at Files=2/Tests=43; task integrity remains three trees/907 nodes/one segment/one index archive; Knowledge Map remains current at 1,104 facts/5,627 questions/5,793 occurrences/117 shards; Memory is 45 lines; all nine staged doctrines pass; the mdBook/fact API/MCP explanation from clean predecessor `ae2f29f01` remains unchanged; proposed `.8` owns common checkpoints, stable source-map identity correlation, first-divergence replay, and mismatch taxonomy without implementation or provider capability claims |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.1` | `pending` | Proposed architecture/proof-boundary audit only; no implementation selected. |
| `.8` provider clarification | `IASIM-EXECUTABLE-REFERENCE-SEMANTICS.8: capture NEXSIM MCP differential checkpoints` | Refine the proposed future differential boundary only; IASIM and provider work remain inactive. |

## Changelog

- `2026-08-01`: Captured the director's IASIM proposal as a proposed owner so
  the executable-intent and differential-oracle idea, proof boundary, and
  independence risk do not live only in session chat.
- `2026-08-01`: Refined IASIM as a fully native Intent Abstraction world that
  is neither constrained nor qualified by HDL; added the independent evidence
  stack required for an accurate, signoff-caliber simulator claim.
- `2026-08-01`: Positioned IASIM as the small independently qualified kernel
  inside the separately owned complete xIAL-native development framework.
- `2026-08-01`: Recorded the director-confirmed Perl-first implementation
  strategy and optional measured `Rust -> shared library -> Perl` acceleration
  boundary without activating IASIM implementation.
- `2026-08-01`: Recorded NEXSIM's planned deep-semantic API/MCP surface in
  proposed `.8`: IASIM-to-NEXSIM qualification will correlate stable
  source-mapped common checkpoints, preserve the first divergence and replay
  evidence, and classify the responsible semantic/lowering/generation/
  handoff/elaboration/runtime/adapter layer instead of relying only on a final
  result mismatch.
