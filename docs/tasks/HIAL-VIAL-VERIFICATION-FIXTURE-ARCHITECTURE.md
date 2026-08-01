# HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE: Hardware And Verification Intent Architecture

## Metadata

- Tree ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`
- Status: `active`
- Roadmap lane: `Verification code generation / intent architecture`
- Created: `2026-07-29`
- Last updated: `2026-08-01`
- Owner: repo-local workflow

## Goal

Define two peer intent systems for FSMGen: Hardware IAL (HIAL), preserving the
current synthesizable IAL0/IAL1/IAL2 lowering stack, and Verification IAL
(VIAL), a pure-verification intent system capable of describing extensive,
elegant test fixtures for HIAL-generated designs. HIAL must target
synthesizable SystemVerilog and synthesizable VHDL; VIAL must target native
SystemVerilog/UVM or VHDL verification code through a typed, language-neutral
HIAL/VIAL bridge.

## Origin And Current Boundary

The director established this product requirement on `2026-07-29` after the
handwritten AHB subordinate arbitration harness demonstrated behavior well
beyond the shipped verification-output skeletons. Today, IAL1 passive
`(observe ...)` metadata can emit an inert UVM passive-monitor package skeleton
or an inert VHDL observation package. It cannot sample a DUT, generate
stimulus, publish transactions, run scenarios, compare expected results,
scoreboard, collect behavioral coverage, inject faults, or generate a runnable
testbench. Those facts remain owned by completed
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER`; this tree now selects and
decomposes the architecture needed to move beyond that bounded foundation.

## Non-Goals

- Do not rename current IAL0/IAL1/IAL2 files, suffixes, public commands, or
  diagnostics merely to introduce the HIAL term; compatibility and migration
  require an explicit later contract.
- Do not assume that VIAL must have VIAL0/VIAL1/VIAL2 layers. The first audit
  must derive the minimum useful topology from verification semantics and
  lowering boundaries.
- Do not recreate SystemVerilog, UVM, or VHDL as a closed domain-specific
  language. Portable intent must compose with typed, reviewable native
  extension points for backend-specific power.
- Do not mix non-synthesizable VIAL behavior into HIAL's synthesizable output
  contract.
- Do not claim behavioral UVM/VHDL verification generation, backend parity,
  mixed-language execution, or large-design scalability before exact
  implementation and validation owners ship.
- Do not treat architecture selection as implicit activation of source,
  lowering, backend, simulator, report, support, or runtime implementation.

## Acceptance Criteria

- The architecture names current synthesizable IAL0/IAL1/IAL2 collectively as
  HIAL while preserving their compatibility contract unless a later migration
  leaf explicitly selects a public change.
- The VIAL topology audit either selects VIAL0/VIAL1/VIAL2 with precise roles
  or selects a different minimal layering and records why.
- A typed, language-neutral HIAL/VIAL bridge identifies DUT interfaces,
  clocks/resets, transactions, protocol facts, configuration, and source
  identity without binding portable intent to one HDL.
- The portable VIAL semantic model covers stimulus, transactions, scenarios,
  concurrency, expected outcomes, temporal checks, reference models,
  scoreboards, functional coverage, and fault injection.
- The backend contract distinguishes HIAL-to-synthesizable-SystemVerilog and
  HIAL-to-synthesizable-VHDL from VIAL-to-SystemVerilog/UVM and
  VIAL-to-VHDL-verification lowerings.
- Equivalent VIAL intent has explicit cross-backend semantic-parity criteria;
  mixed-language HIAL/VIAL combinations remain a separately gated target where
  supported by the selected toolchain.
- The validation matrix separates a fast portable SystemVerilog profile using
  Verilator's supported synthesis-oriented subset from an authoritative
  full-language/SystemVerilog-UVM profile using a capability-qualified
  simulator. Tool versions and exercised capabilities are reported, and the
  portable profile never implies full SystemVerilog LRM or UVM support.
- VHDL verification receives an equally explicit analyzer/simulator profile;
  open-source portability, full-language qualification, and mixed-language
  qualification are separate claims rather than one inferred capability.
- Native extension points are typed, scoped, traceable to VIAL source, and
  readable in generated artifacts; they extend rather than clone the target
  verification languages.
- The audit maps migration and reuse of current IAL1 checks/properties,
  `(observe ...)` metadata, the inert UVM monitor skeleton, and the inert VHDL
  observation package.
- A worked architecture example maps the handwritten
  `t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt` fixture to
  proposed portable VIAL intent and typed native escape points without
  implementing or claiming generated behavior.
- Scalability, deterministic output, source traceability, generated-code
  readability, compile/simulation/formal validation, and support-accounting
  gates are defined for large to very large designs before implementation.
- Roadmap, mdBook, task index, Memory, Knowledge Map, and git history remain
  aligned, and every implementation slice is committed through `COMMIT.md`.

## Task Tree

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`
  Status: `active`
  Goal: `Define peer HIAL and VIAL intent systems and their typed bridge so synthesizable hardware and powerful generated verification share one traceable architecture.`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.8, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.16, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1`
  Status: `done`
  Goal: `Audit and select the HIAL/VIAL architecture, VIAL layer topology, typed bridge, portable verification semantics, native extension model, backend matrix, migration path, scalability contract, and validation gates.`
  Acceptance: `The audit reads the current IAL0/IAL1/IAL2 contracts and lowerings, SystemVerilog and VHDL hardware backends, IAL1 verification metadata and generated skeletons, public artifact/report/support surfaces, the handwritten AHB arbitration fixture, UVM and VHDL reference constraints, and large-design doctrine; it produces a reviewable architecture decision and decomposes implementation into exact source-model, bridge, backend, tooling, validation, migration, documentation, and scale-proof leaves. It makes no parser, lowering, generated artifact, CLI, report, support-accounting, HDL, UVM, VHDL, test, or runtime behavior change.`
  Verification: `Selected decision 0032 and the canonical audit after reading the live HIAL layer/lowering, backend, verification-output, manifest/accounting, AHB harness, UVM, VHDL/tool-profile, SourceHIR/IR-policy, and scale evidence. The selected topology is one public .vial language, private immutable VIALSemanticIR and VIALExecutionIR, bounded versioned HIALVIALBridgeManifest, typed native extensions, normalized result parity, plain-SV/Verilator first, and separately qualified UVM, VHDL, methodology, and mixed-language profiles. The AHB fixture has an exact portable-versus-probe/native mapping. Leaves .2-.18 own source, bridge, execution, tooling, backends, migration, qualification, scale, and docs. Task-tree integrity passes at two active trees / 864 nodes; documentation audits pass at Files=3, Tests=40; all 37 mdBook chapters test and the 73-file / 16,810,633-byte HTML build passes; Knowledge Map generation/check passes at 1,085 facts / 5,600 question keys; memory, diff, staged acceptance exemption, all eight doctrines, and exact repository-local output cleanup pass. Parser/lowering/source/artifacts, CLI/API/report/manifest/accounting, HDL/UVM/VHDL, tests/runtime, and product behavior are unchanged.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1: select one-source dual-IR architecture`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2`
  Status: `done`
  Goal: `Select the exact public .vial version-1 source contract and private immutable VIALSemanticIR version-1 record.`
  Acceptance: `A documentation-only contract selects grammar/topology, types and four-state policy, reusable declarations/packages, DUT references, transactions, scenarios, concurrency, stimulus, observations, expectations, models, scoreboards, coverage, fault intent, randomness/replay identity, diagnostics/source maps, owner/producers/consumers/invariants/defensive-copy policy, parser/report surfaces, first bounded fixture, negative boundaries, and implementation owner without changing product behavior.`
  Verification: `Clean activation commit d70f07e29 permits only documentation contract selection. docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md and decision 0033 select closed span-aware S-expression .vial version 1, core_directed_single_clock_v1, target-neutral two-/four-state values, reusable declarations, unbound typed DUT bindings, canonical shared =>/next/within properties, deterministic models/fibers, bounded scoreboards/coverage/faults/randomness/scenarios, private immutable VIALSemanticIR, defensive sanitized semantic reports/diagnostics, exact resource/negative boundaries, planned vial/ahb_subordinate_base_output_arbitration.vial, four implementation packages, and focused t1550. Proposed .3 alone owns implementation after separate clean activation. Task-tree integrity passes at two active trees / 864 nodes; docs audits pass at Files=3, Tests=40; relative-path audit passes Files=1, Tests=2; all 37 mdBook chapters test and the 73-file / 16,842,038-byte build passes; Knowledge Map generation/check passes at 1,086 facts / 5,617 question keys; memory, diff, docs-only staged acceptance, all eight doctrines, and exact repository-local cleanup pass. Parser/source/artifacts, CLI/API/report/manifest/accounting, HDL/UVM/VHDL, tests/runtime, and product behavior are unchanged in selection.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2: select spanned VIAL semantic contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3`
  Status: `done`
  Goal: `Implement the selected bounded .vial parser, validator, VIALSemanticIR, and check/semantic report surface.`
  Acceptance: `The exact .2 grammar and IR contract parse one checked-in directed single-clock fixture into immutable typed semantic intent with deterministic order/source maps, fail closed on the selected negative corpus, expose only the selected sanitized reports/diagnostics/capabilities/support entries, and emit no bridge, execution plan, HDL, UVM, or VHDL artifact.`
  Verification: `Implemented four private FSM::VIAL packages and the 4,986-byte / 123-line / SHA-256 2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd AHB fixture. Focused t1550 proves the selected grammar, typed immutable SemanticIR, authored-order multi-diagnostics with dependent-cascade suppression, resource limits, stable spans/order, defensive copies, exact report, symmetric contextual literal inference, and explicit no-output boundaries; t248/t297 prove semantic-only support/capability accounting at Files=3 / Tests=7,055. Four Perl syntax checks pass; nine adjacent accounting/runtime/defensive-copy audits pass at Files=9 / Tests=32; docs audits pass at Files=3 / Tests=40 and relative paths at Files=1 / Tests=2. Task-tree integrity, all 37 mdBook chapters/build, Knowledge Map generation/check, bounded Memory, diff, staged acceptance, all doctrines, and exact repository-local cleanup pass. The broader t261 and t296 failures reproduce independently as stale non-VIAL oracles and are durably owned by proposed SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC and SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT; no VIAL source owns those expectations. No bridge, execution plan, public CLI/API, HDL/UVM/VHDL artifact, compile, simulation, result, parity, mixed-language, or scale claim is emitted.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3: implement VIAL semantic intent`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.4`
  Status: `done`
  Goal: `Select HIALVIALBridgeManifest version 1 and its HIAL-layer production contract.`
  Acceptance: `A documentation-only contract freezes bridge identity, HIAL review-artifact provenance, unit/config/type/endpoint/domain/transaction/event/protocol/residue/observation/probe/backend-binding/capability/source-map families, public-port/probe/native access classes, schema/defensive-copy/report paths, exact IAL0/IAL1/IAL2 reviewable routes, no-direct-IAL2 bypass, negative boundaries, and the bounded first implementation scope.`
  Verification: `Accepted decision 0035 and docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md after auditing normalized IAL0/IAL1/IAL2 outputs, the IAL1 observation parser/schedule report, the AHB PPIF generated-IAL1/IAL0/report route, current public semantic/result contracts, the checked VIAL bridge IDs, and decisions 0018/0031-0034. The selected fsmgen.hial_vial_bridge_manifest.v1/core_single_unit_v1 contract freezes direct IAL0, direct IAL1, and IAL2-via-generated-IAL1 routes; an additive parsed (verification-bridge ...) IAL1 annotation; exact units/config/types/endpoints/domains/transactions/events/protocols/observations/probes/backend-name bindings/capabilities/residue/source maps; stable IDs/hash/order; honest semantic-path provenance; private immutable defensive producer/report; limits/diagnostics/negative gates; and focused t1551. Proposed .5 alone owns implementation after separate clean activation. Current IAL1 observation, AHB IAL2, and VIAL source evidence passes at Files=3 / Tests=21; task-tree integrity passes at two active trees / 865 nodes; docs pass at Files=4 / Tests=42; all 37 mdBook chapters test and the 73-file / 16,930,263-byte local build passes; Knowledge Map generation/check passes at 1,088 facts / 5,640 question keys; Memory is bounded at 54 lines; diff, docs-only staged acceptance, all eight doctrines, and exact output cleanup pass. No parser, annotation, bridge object/report, generated review artifact, capability/support entry, HDL, VIAL binding, runtime, or product behavior changes in selection.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.4: select review-routed bridge manifest`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5`
  Status: `done`
  Goal: `Implement the bounded HIALVIALBridgeManifest producer through canonical HIAL review paths.`
  Acceptance: `Direct IAL0, direct IAL1, and ppif/ahb_lite_subordinate.ppif through a deterministically generated, reparsed IAL1 (verification-bridge ...) annotation emit the selected private in-process versioned bridge with stable logical IDs, full field source maps, defensive public-data projection, exact capability/support accounting, and fail-closed unsupported facts. The AHB manifest resolves every checked VIAL bridge ID/type but does not bind VIAL; PPIF AST/report data never bypasses generated IAL1; generated IAL0 and HIAL HDL behavior remain byte/semantically preserved; no bridge file, CLI/API, plan, verification artifact, runtime, or backend-parity claim is emitted.`
  Verification: `Implemented the private Builder/Manifest/Report and contract owner, additive IAL1 parser/schedule/report projection, and the exact base-AHB IAL2 annotation. Focused t1551 plus IAL1/AHB/support/capability audits pass at Files=6 / Tests=7,058; 28 adjacent capability/support/accounting contract/runtime/round-trip/defensive-copy files pass at Files=28 / Tests=56; all changed Perl modules compile. The tests prove all three canonical routes, immutable defensive JSON-safe data, exact 27-key manifest/schema/profile/IDs/types/configuration/domain/transaction/event/protocol/observation/probe/backend-binding/capability/residue/source-map families, checked VIAL ID/type/access resolution, full semantic-field provenance, no PPIF bypass, fail-closed annotation/access/capability/limit errors, exact private support discovery, and no file/public embedding surface. Generated IAL1 is deterministic at 4,174 bytes / SHA-256 b0f3446874367787d0dd134701ff9e89a3b24af6ef9c03d6eb9dc484093f9e4c; generated IAL0 remains 5,854 bytes / SHA-256 3d8fa7ac7c3a7f2c9ca063aca2cf707106b511219243d8b277ac3e2e8cf47bcf; direct HIAL SystemVerilog normalized-date and VHDL hashes remain 95dbfc0fb7efecc5b1a04f98365cacad3dcb250d9c69523562368aebe8cfd28c and a82f42e0015b662d432df842633854d16c73cc7805f355d84a902bf553f77e62. Task-tree integrity passes at trees=2 / nodes=865; docs pass at Files=4 / Tests=51; all 37 mdBook chapters test and the 73-file / 16,965,845-byte repository-local build passes; Knowledge Map generation/check passes at 1,089 facts / 5,643 keys; build output is removed exactly. VIAL remains unbound; no bridge file, CLI/API, plan, verification artifact, compile, simulation, result, parity, UVM, VHDL-methodology, mixed-language, or scale claim is emitted. Independently stale t370 discovery-map drift is parked under proposed CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5: implement review-routed bridge manifest`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.6`
  Status: `done`
  Goal: `Select VIALExecutionIR version 1, deterministic logical-time execution, typed native-extension, plan, result, and parity contracts.`
  Acceptance: `A documentation-only contract freezes binder/elaborator ownership and invariants, drive/sample/react/check phases, fiber/tie/cancel/timeout behavior, stable random-decision/replay identity, model/scoreboard/coverage/fault execution, capability negotiation, methodology-owned native lifecycle hooks and typed external artifacts without imposing a synthesizability ceiling on VIAL, sanitized vial-plan.json, normalized verification-result-manifest.json, cross-backend parity fields, defensive-copy policy, diagnostics, and negative boundaries.`
  Verification: `Decision 0036 and the 1,148-line docs/VIAL_EXECUTION_IR_V1_CONTRACT.md select target-neutral fsmgen.vial_execution_ir.v1/core_directed_single_clock_execution_v1, exact SemanticIR/bridge binding, normalized values, deterministic (domain,cycle,drive|sample|react|check,ordinal) execution and tie order, closed action/fiber/temporal/model/scoreboard/coverage/fault semantics, plan-time sha256_counter_rejection_v1 randomness and strict replay, declarative repository-relative typed native manifests distinct from Perl callbacks, defensive fsmgen.vial_plan.v1, normalized fsmgen.verification_result_manifest.v1, canonical portable parity projection/report, diagnostics, limits, exact AHB binding/plan oracle, owners, non-claims, and rollback. Current SemanticIR/bridge/extension evidence passes at Files=3/Tests=24; task-tree integrity passes at trees=2/nodes=865; docs pass at Files=4/Tests=51; all 37 mdBook chapters test and the 73-file/17,008,064-byte repository-local build passes; Knowledge Map passes at 1,090 facts/5,658 question keys; Memory is 56 lines; diff, docs-only staged acceptance, all eight doctrines, and exact build-output cleanup pass. Proposed .7 alone is selected next for separate clean activation. No VIAL source/parser/SemanticIR, HIAL bridge/parser/annotation/report, VIAL binding/ExecutionIR implementation, plan/result file, scheduler, native extension implementation, backend, CLI/API, compile, simulation, runtime, parity, or product behavior changes in selection.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.6: select deterministic VIAL execution contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7`
  Status: `done`
  Goal: `Implement bounded bridge binding and VIALExecutionIR elaboration without a target-language backend.`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.3`
  Acceptance: `The selected .vial fixture plus bridge bind into an immutable deterministic plan, the plan projection and strict replay match their contracts, selected future result/parity schemas retain explicit later owners rather than false shipped capabilities, logical-time and timeout/concurrency structure passes bounded oracles, unsupported capabilities/native extensions fail before emission, and no SV/UVM/VHDL verification artifact or runtime behavior is claimed.`
  Verification: `Completed by .7.3 after the .7.1 type-binding audit and decision-0037/.7.2 directional-relation correction. The private exact-class binder now produces immutable target-neutral ExecutionIR and a defensive no-file plan with deterministic logical phases, operation/fiber order, random/replay, bindings, capabilities, source maps, limits, and atomic diagnostics. Signoff caught and corrected an ownership contradiction in the selected oracle prose: result production begins in .10 and parity comparison in .11, so .7.3 publishes those selected schema names with explicit later owners but does not mark their capabilities satisfied. Focused/adjacent code and documentation evidence is recorded below. No public API/file, backend artifact, compile, simulation, runtime result, parity pass, UVM/VHDL methodology, mixed-language, or scale claim ships.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7: activate VIAL execution implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.1`
  Status: `done`
  Goal: `Audit whether the selected VIAL execution binding contract can bind the checked AHB SemanticIR and bridge manifest exactly.`
  Acceptance: `Direct SemanticIR and bridge-manifest evidence identifies every type-domain match or mismatch, traces the producing code and selected contract clauses, records the exact implementation consequence, and creates an explicit decision owner before implementation proceeds.`
  Verification: `Direct in-memory SemanticIR and IAL2-via-generated/reparsed-IAL1 bridge projections confirm address/size/data and all sampled endpoint/probe types match, while transfer is enum versus logic, write is two-state Boolean versus four-state logic, and wait_cycles is two-state unsigned versus four-state logic. Source, bridge-builder, contract, and prior t1551 evidence trace the root cause: decision 0036 omitted the authored-semantic-to-hardware-carrier representation relation, while .5 checked endpoint types plus transaction ID/order but not each transaction field type. docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md records exact evidence, alternatives, recommendation, reverify commands, and unblock condition; .7.2 is blocked for the director's choice and .7.3 owns later implementation. Focused frontend/bridge evidence passes at Files=2/Tests=21; docs audits pass at Files=4/Tests=309; task integrity passes at trees=2/nodes=868; all 37 mdBook chapters test and the 73-file/17,024,906-byte repository-local build passes; Knowledge Map passes at 1,091 facts/5,666 keys; Memory is 49 lines; diff, docs-only staged acceptance, all doctrines, and exact output/off-route residue cleanup pass. No parser, SemanticIR, bridge, generated HIAL, binder, ExecutionIR, plan/result object or file, backend, public API, compile, simulation, runtime, parity, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.1: confirm transaction type-binding blocker`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.2`
  Status: `done`
  Goal: `Select the exact semantic rule for binding expressive VIAL value types to HIAL hardware boundary types.`
  Acceptance: `The director-approved rule either requires exact type identity and aligns the fixture/bridge accordingly, or defines a closed proof-carrying directional representation adapter that preserves VIAL intent without target-language casts or implicit runtime coercion; the execution contract, decision record, source contract, bridge contract, examples, and negative boundaries are synchronized before implementation.`
  Verification: `Director approved the recommended rule on 2026-07-31. Decision 0037 now keeps VIAL semantic and HIAL carrier types independently authoritative and selects exactly three compiler-proved directional relations: bit_domain_identity_v1 for equal state-domain/width/signedness in either direction, known_value_injection_v1 for same-width/signed two-state-to-four-state drives, and enum_encoding_injection_v1 for exact unique representable enum-base encodings into logic drives. Exact stable relation/proof records, the AHB field oracle, drive/sample/inout direction rules, required probe-adapter independence, VIAL execution capability, VIAL/source/bridge ownership, fail-closed inverse X/Z/width/sign/enum/coercion/cast boundaries, diagnostics, book examples, decision/audit/fact/live-doc continuity, and .7.3 implementation ownership are synchronized. Focused frontend/bridge, docs, task-tree, mdBook, Knowledge Map, Memory, diff, staged docs-only acceptance, doctrine, and cleanup evidence is recorded in the verification log. No parser, SemanticIR, bridge, binder, ExecutionIR, plan/result object or file, backend, public API, compile, simulation, runtime, parity, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.2: select directional type binding`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.3`
  Status: `done`
  Goal: `Implement the selected bounded binder, immutable VIALExecutionIR, deterministic random/replay, defensive plan support, explicit future result/parity schema ownership, and focused contract oracles.`
  Acceptance: `Implementation follows the resolved .7.2 binding rule, passes fresh box-scoped implementation acceptance and all focused/broader gates, updates bounded private capability/support accounting, and emits no target backend, public file/API, compile, simulation, runtime, or parity claim.`
  Verification: `Private FSM::VIAL ExecutionBuilder/ExecutionIR/ExecutionRandom/ExecutionReport and FSM::Support::VIALExecutionContract now bind the checked SemanticIR and review-routed bridge into a defensive no-file target-neutral plan. The exact AHB oracle has 21 operations, four total fibers, three maximum simultaneous fibers, ten proof-carrying directional relations, 22 bindings, two scalar state cells, scoreboard capacity four, two coverage bins, and one scenario decision occurrence referenced twice. Event expressions resolve through explicit transaction-adapter inputs and opaque adapter state without raw HDL literal or actor-storage leakage. SHA-256 counter/rejection randomness is arbitrary-width and strict replay is sign-aware. Support accounting is private and closed; selected future result/parity schemas name .10/.11 owners and are not satisfied .7.3 capabilities. Focused/adjacent evidence passes at Files=10/Tests=7135; nine changed Perl modules report syntax OK; documentation evidence passes at Files=4/Tests=609 plus relative paths Files=1/Tests=2, all 37 mdBook chapters test, and the 73-file/17,058,063-byte local build succeeds and is removed. Task integrity passes at trees=2/nodes=868; Knowledge Map passes at 1,092 facts/5,674 keys; Memory is 56 lines. Pre-existing t370 verification-output discovery drift remains separately owned by CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1. Staged acceptance/doctrine and final cleanup evidence is recorded in the verification log. No target backend, public file/API, compile, simulation, runtime result, parity pass, UVM/VHDL methodology, mixed-language, or scale claim ships.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.3: implement private VIAL execution plan`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.8`
  Status: `done`
  Goal: `Select the public VIAL CLI/API, project-local artifact layout, manifest/report/capability/diagnostic/support-accounting contract, and compatibility rules.`
  Acceptance: `The contract selects exact .vial terse and verbose normal projections of one typed semantic model that can be learned and authored without SV/UVM/VHDL knowledge, plus HIAL/bridge inputs, output/profile options, in-memory source-catalog/artifact-sink equivalents, repository-derived path policy, bridge/plan/artifact/result layout and schemas, schema migration for existing verification-output-manifest v1, capability discovery, stable diagnostics, support families, incompatible options, cleanup, and rollback before backend implementation.`
  Verification: `Decision 0039 and docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md select the intent-oriented fsmgen vial capabilities/check/format/plan/run family, exact normal_v1/terse_v1 semantic-equivalent projections, separate VIAL/HIAL inputs and canonical HIAL review routes, closed portable request/result plus source-catalog/artifact-sink API, repository-relative same-volume content-addressed atomic artifact trees, sanitized bridge/plan/tool/result projections, explicit verification-output-manifest v1 preservation and v2 VIAL runtime schema, capability/support families, diagnostics, incompatible options, implementation ownership, non-claims, validation, and rollback. Final docs/task/mdBook/Knowledge Map/Memory/doctrine evidence is recorded below. No parser/API/CLI/file/backend/runtime or product behavior changes in selection.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.8: select public VIAL tooling contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9`
  Status: `done`
  Goal: `Select the plain-SystemVerilog sv_portable_verilator backend and runtime-library contract.`
  Acceptance: `The contract maps the bounded VIALExecutionIR subset to efficient, readable, deterministic, source-mapped non-UVM SystemVerilog without requiring SystemVerilog knowledge from a VIAL author, freezes clock/phase race avoidance, values/types, drivers/samplers, scenarios/fibers, checks/models/scoreboards/coverage/fault subset, artifacts/results, exact Verilator version/capabilities/options, compile/elaboration/runtime gates, non-claims, and implementation fixture.`
  Verification: `Decision 0043 and docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md select static partial evaluation into a small plain-SV runtime package, one fixture module, the generated DUT, exact source maps, a closed JSONL runtime trace, and the normalized result contract. One inactive-edge scheduler preserves drive/sample/react/check order without exposing simulator regions. The exact reference profile is Verilator 5.046 with --binary/--timing/--assert, one build/runtime thread, deterministic X concretization, explicit timescale/top/local object root, six independent gates, and no blanket warning suppression. The profile is explicitly known-value/two-state at runtime, rejects authored X/Z-sensitive semantics, satisfies only exact declared probe adapters, and cannot imply full four-state SV, full LRM, UVM, parity, or scale. A repository-local substrate probe compiled and ran the existing 178-line AHB oracle at success accepts=1/captures=1/holds=2/completions=1/ready_low=15/storage=cafebabe and ERROR accepts=1/captures=1/holds=2/completions=1/error_cycles=2/storage=00000000, then its exact tree was removed. Final source/bridge/execution, docs, task, mdBook, Knowledge Map, Memory, staged acceptance, doctrine, and cleanup evidence is recorded below. No parser, CLI/API, generated backend, runtime, result producer, capability/support claim, parity, or product behavior ships in selection; proposed .10 is selected next for separate clean activation.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9: select portable SV backend contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10`
  Status: `done`
  Goal: `Implement the selected public VIAL tool path, bounded plain-SystemVerilog portable backend, Verilator behavioral profile, and normalized result producer.`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.4`
  Acceptance: `The selected fixture emits efficient, deterministic, readable, source-mapped SystemVerilog plus manifests without requiring SystemVerilog knowledge from a VIAL author, compiles and runs under the exact recorded Verilator --binary --timing profile, produces the normalized result oracle, preserves all non-claims, and leaves UVM/VHDL/mixed-language output unchanged.`
  Verification: `Clean .9 selection commit ab3e73b72 activates only implementation leaf .10. Clean activation commit 5fd766600 permits decomposition into four independently accepted children: .10.1 public source tooling, .10.2 canonical plan/artifact transaction, .10.3 portable backend/trace projection, and .10.4 exact Verilator run/result integration. The selected contracts and product behavior remain unchanged during decomposition.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10: activate portable SV backend implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.1`
  Status: `done`
  Goal: `Implement the public VIAL capabilities, check, and normal/terse format surfaces through one portable in-memory API and the fsmgen vial command family.`
  Acceptance: `The selected normal_v1 and terse_v1 forms parse and format to one byte-stable semantic meaning; capabilities/check/format expose only defensive JSON-safe reports through CLI and in-memory requests, perform no HIAL binding or artifact write, preserve every legacy CLI path, diagnose incompatible options atomically, and pass fresh implementation acceptance plus focused and adjacent regression gates.`
  Verification: `Implemented one normal/terse SourceProjection normalization/formatter over the unchanged SemanticBuilder, the closed fsmgen.vial_tool_request.v1/result.v1 source-only API, explicit fsmgen vial capabilities/check/format dispatch, exact language-surface capability and support accounting, repository-root-relative non-symlink same-volume reads, defensive JSON-safe reports/diagnostics, and focused t1555 coverage. Normal and terse canonical reparses have the same semantic-projection SHA-256; mixed styles, reordered terse declaration families, style mismatch, syntax, unsafe paths, callbacks, non-Boolean options, unavailable plan, and incompatible legacy options fail closed. The guarded semantic/bridge/execution/source-tool/support/capability suite reports All tests successful at Files=6, Tests=7083. Final task/docs/mdBook/Knowledge Map/staged doctrine evidence is recorded below; no HIAL binding, plan/artifact write, backend, compile, simulation, runtime/result, parity, UVM, VHDL, mixed-language, or scale claim ships.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.1: ship public VIAL source tooling`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.2`
  Status: `done`
  Goal: `Implement public VIAL planning through canonical HIAL review routes and one deterministic repository-local or virtual artifact transaction.`
  Acceptance: `The selected direct IAL0, direct IAL1, and IAL2-via-generated/reparsed-IAL1 routes bind checked VIAL through the existing private bridge and execution builders; CLI paths are repository-relative, in-memory callers use the closed source-catalog/artifact-sink boundary, canonical bridge/plan/tool manifests and review artifacts are hash-ordered and byte-stable, and every failure publishes no partial tree.`
  Verification: `Clean .10.1 implementation commit 50a0d7d39 activates only canonical planning/artifact implementation .10.2. Implementation adds the private canonical HIAL PlanBuilder, closed public plan request/result projection, exact virtual artifact graph, and atomic repository-local ArtifactTransaction. Direct IAL0 now admits transaction-free endpoint/reset fixtures, direct IAL1 consumes reviewed bridge metadata then generated IAL0, and IAL2 must generate and reparse IAL1 before generated IAL0; the checked AHB route publishes canonical normal VIAL, exact generated IAL1/IAL0 review sources, defensive bridge/plan projections, and a non-recursive self-excluding tool-manifest inventory. Identical trees return unchanged; unsafe, partial, non-identical, symlinked, traversing, colliding, malformed, or failed graphs publish nothing and leave exact staging clean. Public capability/support accounting now distinguishes plan from source tooling while backend/runtime/result/parity non-claims remain explicit. Final focused/broad/docs/mdBook/Knowledge Map/task-acceptance/doctrine and cleanup evidence is recorded below. Clean implementation commit 045629c97 permits separate backend/trace activation .10.3.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.2: ship VIAL planning artifacts`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.3`
  Status: `done`
  Goal: `Implement deterministic sv_portable_verilator artifact emission and closed runtime-trace projection without executing an external simulator.`
  Acceptance: `The bounded ExecutionIR lowers by static partial evaluation into readable source-mapped non-UVM SystemVerilog, backend/runtime manifests, declared-probe adapters, and a closed prefixed JSONL trace contract; known-value negotiation and every selected limit fail before publication, trace validation projects normalized results without replaying verification semantics, and no compile/runtime/parity claim is made.`
  Verification: `Clean .10.2 implementation commit 045629c97 activates only deterministic portable-SystemVerilog artifact emission and closed trace projection. Implementation retains the exact immutable ExecutionIR, defensive reviewed bridge, and date-normalized generated HIAL DUT at the private planner boundary; emits one sorted eight-artifact virtual graph with readable one-scheduler plain SV, complete operation/state-family source maps, generated declared-probe aliases, exact selected-but-unexecuted Verilator command/profile records, and honest emission-only manifests; and validates caller-supplied closed canonical prefixed JSONL into a defensive trace projection without replaying semantics. Backend-only limits remain outside target-neutral ExecutionIR identity. Capability/support discovery reports private emission/validation while the public action set remains capabilities/check/format/plan. Syntax, focused/impacted VIAL/support, docs/live/path/task, all 37 mdBook chapters/build, Knowledge Map, Memory, staged acceptance/doctrines, diff, and exact cleanup pass as recorded below. No filesystem publication, external compile, simulation, runtime capture, normalized result, parity, UVM, VHDL, mixed-language, or scale claim ships; proposed .10.4 owns publication/tool/runtime/result integration after a separate clean activation.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.3: ship portable SV backend emission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.4`
  Status: `done`
  Goal: `Integrate the exact Verilator 5.046 compile/run profile and normalized VIAL result producer through the public run surface.`
  Acceptance: `The public CLI/API run action publishes atomically, invokes only the exact repository-local --binary/--timing/--assert profile with bounded resources, separates compile/executable/run/trace/schema/outcome gates, emits the selected result and verification-output manifests, proves deterministic reruns and cleanup, preserves known-value/non-parity non-claims, and leaves UVM/VHDL/mixed-language output unchanged.`
  Verification: `Clean .10.3 implementation commit 201590d84 and clean activation commit 8ba4278d8 permit only .10.4 implementation. Public CLI/API run now composes the immutable reviewed plan with deterministic portable-SV emission, exact digest/argv-qualified Verilator 5.046 compile/run, bounded repository-local execution staging, closed trace validation, normalized result production, and atomic virtual/filesystem publication. The checked AHB fixture passes both scenarios and emits all ten semantic streams in a deterministic 19-artifact graph; identical API bytes and CLI unchanged replay, exact cleanup, support/capability truth, known-value/four-state/parity non-claims, and unchanged legacy UVM/VHDL/mixed-language surfaces are regression-locked by t1558 plus the guarded VIAL/support suite. Final task/docs/mdBook/Knowledge Map/live-doc/staged-doctrine evidence is recorded below. .11 retains cross-backend parity.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.4: ship Verilator run results`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11`
  Status: `done`
  Goal: `Migrate the handwritten AHB base output-arbitration success/ERROR fixture to portable VIAL and prove runtime parity.`
  Acceptance: `A checked-in .vial fixture and bridge-backed generated plain-SV harness reproduce the portable public-port acceptance/stall/response/data/completion/storage-or-readback outcomes of t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt; internal capture/hold/completion/storage references are either declared typed probes with explicit profile limits or excluded from the portable oracle; old and new harnesses run against the same generated DUT with normalized result parity and unchanged HIAL behavior.`
  Verification: `Clean .10.4 implementation commit dfe87f536 and activation commit 04f22f689 permit only bounded AHB parity. The private closed AHBBaseOutput comparator consumes an exact zero-exit handwritten oracle plus the shipped candidate result, requires byte-identical generated DUT digests, projects 19 public/shared success and unsupported-size outcome paths, emits deterministic fsmgen.vial_parity_report.v1, explicitly excludes undeclared internal capture/hold/completion observations, reports semantic mismatches, and fails closed on malformed/duplicate/nonzero/ineligible/different-DUT evidence. Focused t1559 independently compiles/runs both harnesses under exact Verilator 5.046; support/capability discovery claims only vial.parity.ahb_base_output_arbitration.v1 while general cross-backend parity remains unclaimed. Final task/docs/mdBook/Knowledge Map/live-doc/staged-doctrine and cleanup evidence is recorded below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11: prove portable AHB result parity`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12`
  Status: `done`
  Goal: `Select the native SystemVerilog/UVM backend, exact UVM revision, component/runtime mapping, open-source emission/qualification tiers, and existing-skeleton migration.`
  Acceptance: `The contract chooses the exact UVM revision and source identity; selects deterministic native emission now, optional explicitly experimental open-source probes, and a future capability-qualified runtime tuple without inventing unavailable versions; establishes typed VIAL intent families for notification/interception (identity, registration, ordering, filtering, lifecycle, reentrancy/cancellation, and effects), lifecycle control, stimulus orchestration, producer/observer communication, implementation selection/substitution, scoped configuration, register intent, constrained decisions, coverage/properties, timed interface interaction, transactions/scenarios/analysis/models/scoreboards/faults/results, and an explicit residual-intent taxonomy; maps those intents to UVM events/callbacks, phases/objections, sequences, TLM, factories/config DB, RAL, randomization/coverage/assertions, and virtual interfaces/clocking without leaking those mechanisms into the VIAL surface or requiring SV/UVM knowledge from a VIAL author; selects target-artifact efficiency/readability/source-map criteria; separates emission, experimental, parse, compile, elaboration, simulation, result, and licensing/CI claims; and defines compatibility/versioning for the shipped UVM 1.2 inert skeleton without treating the first bounded native implementation as VIAL's expressive ceiling.`
  Verification: `Decision 0050 and the canonical architecture audit select IEEE 1800.2-2020 / Accellera UVM 2020-3.1 at exact tag 2020.3.1 and commit 78c06547a2a0a29b3dc9dcafae62b75b2ff61544. Director clarification rejects commercial simulators as a required near-term dependency, identifies PGEN as the developing HDL parser and NEXSIM as the developing open-source commercial-grade simulator, and selects three honest tiers: sv_uvm_emit.accellera_2020_3_1, optional sv_uvm_experimental.<tool-and-version>, and future sv_uvm_qualified through an exact PGEN+NEXSIM tuple once executable versions and their handoff exist. Full-shaped simulator-neutral generation may proceed across all selected mappings using typed-IR preview fixtures and public authoring routes as they exist; static checks and visual review are emission evidence, exact open tools probe compile/elaboration as early as the first gallery, and syntax/implementation strategy may converge iteratively without changing VIAL meaning. The contract freezes typed intent/UVM mappings, ordered notification/interception semantics, lifecycle/logical-time ownership, component/TLM/factory/config/RAL/randomization/coverage/property/interface mappings, residual taxonomy, deterministic artifacts/source maps, open-source data locality, capability gates, and unchanged inert UVM 1.2 compatibility. `.13.1.1` is the next unblocked implementation leaf; no parse/compile/elaboration/simulation/runtime/result capability is selected or claimed by this documentation slice. Final measured doctrine evidence is recorded below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12: select open-source native UVM architecture`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13`
  Status: `active`
  Goal: `Implement native SystemVerilog/UVM through independently honest emission, experimental-probe, and PGEN+NEXSIM qualification slices.`
  Acceptance: `The parent closes only when deterministic efficient readable source-mapped emission ships, any experimental open-source probe remains explicitly non-product evidence, and an exact PGEN+NEXSIM tuple parses/compiles/elaborates/runs the selected native subset into normalized results. Notification/interception semantics use UVM event/callback machinery without exposing target classes or requiring SV/UVM knowledge in authored VIAL; factory/config/TLM plumbing stays backend-private; every exercised/missing capability and applicable parity oracle is exact; inert UVM 1.2 compatibility follows the selected contract; and no first subset or tool result becomes full UVM/VIAL breadth.`
  Verification: `pending children .13.1-.13.3`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1`
  Status: `active`
  Goal: `Implement complete reviewable simulator-neutral sv_uvm_emit.accellera_2020_3_1 generation through bounded children without a parser or simulator gate.`
  Acceptance: `Representative typed-IR fixtures and public authorable paths where available emit the full selected UVM environment shape across topology, interfaces, lifecycle, notification/interception, stimulus, TLM, factory/configuration, RAL, constrained decisions, coverage/properties, models/scoreboards/faults/results, with efficient readable deterministic artifacts, complete source maps, an accumulating review gallery, and explicit static/manual-review versus compile/elaboration/run/result states. No child waits for a simulator merely to generate broader UVM; unknown defects remain possible and are tracked when found rather than hidden. Raw SV/UVM knowledge stays absent from authored VIAL, legacy UVM 1.2 remains compatible, and neither visual review nor static shape checks become syntax/runtime/full-VIAL qualification.`
  Verification: `.13.1.1` ships the native emitter foundation and `.13.1.2` ships complete selected topology, lifecycle, and notification/interception structures; proposed children .13.1.3-.13.1.5 remain unblocked by simulator availability`
  Commit: `pending children`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.1`
  Status: `done`
  Goal: `Implement the native UVM emission substrate and first reviewable artifact gallery without requiring UVM library bytes or an executable simulator.`
  Acceptance: `The exact Accellera UVM identity/API target is recorded without making an ordinary emission depend on a network fetch; the backend/profile, deterministic artifact graph, source map, typed packages, interface/top/component foundations, static shape validators, review-gallery fixtures, capability states, atomic repository-local publication, limits, and cleanup ship; library materialization is required only before a later library-dependent parser/compile gate; and parse/compile/elaboration/run/result remain explicitly not run.`
  Verification: `The private SVUVMAccellera2020_3_1 emitter consumes exact ExecutionIR/bridge/DUT inputs and emits the deterministic ten-artifact sv_uvm_emit.accellera_2020_3_1 foundation: exact methodology profile, typed logical-time context, component bases, AHB timed interface, fixture configuration/environment/test, bound top, deterministic HIAL DUT, complete line/column source map, structural-only validation, and closed backend manifest. Five UVM-facing sources are byte-locked in the first review gallery. Capability discovery, support accounting, fail-closed malformed/provider/balance/digest/profile tests, identical rerender, atomic same-volume publication, collision rejection, exact cleanup, and syntax/non-claim truth pass. Ordinary emission performs no network fetch and does not inspect UVM bytes. Manual review remains pending; preprocessing, parse, UVM-library compile, fixture compile, elaboration, runtime, result, parity, complete UVM breadth, and public emitter API remain explicitly unclaimed. Focused t1560 plus capability/support accounting pass at Files=3/Tests=7095; final doctrine evidence is recorded below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.1: ship native UVM emitter foundation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.2`
  Status: `done`
  Goal: `Emit complete selected component topology, timed interfaces, lifecycle control, and notification/interception structures for visual and static review.`
  Acceptance: `Generated tests/environments/agents/interfaces/controllers/result collectors express strict lifecycle/logical-time ownership and the complete notification/interception record, including stable registration order, filters, effects, cancellation, bounded queue/reject reentrancy, source maps, static negative oracles, and representative review-gallery artifacts; no simulator gate or runtime result is required.`
  Verification: `Emitter revision 2 now produces an exact eleven-artifact graph with seven SystemVerilog sources and 42 complete source-map entries. Typed lifecycle/lifetime/reentrancy/filter/effect records, a context-owning agent base, passive timed monitor/agent, lifecycle controller, result-collector structure, complete environment/root-test topology, six typed event channels, exact UVM event callbacks, immutable/effective payload separation, stable rank/semantic-ID registration, cancellation/skipped accounting, and bounded queue-or-reject reentrancy are emitted and byte-locked across six gallery sources. Ten static checks cover roles/text/provider/balance/foundation/notification/topology/single-root-objection boundaries; focused negative oracles reject missing callback/bounds, active-agent residue, duplicate objections, and phase jumps. Public VIAL v1 events own channel identity; interceptor tables remain a private typed preview. Manual review and every parse/compile/elaboration/runtime/result/parity claim remain pending or unclaimed. Focused/broader implementation evidence and documentation/doctrine evidence are recorded below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.2: ship complete native UVM structures`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.3`
  Status: `active`
  Goal: `Emit representative stimulus, sequence, TLM, factory/configuration, RAL, and constrained-decision UVM structures without waiting for runtime qualification.`
  Acceptance: `Typed-IR fixtures and public source routes where selected generate efficient readable sequence items/sequences/sequencers/drivers, analysis/TLM wiring, scoped factory/configuration plumbing, RAL objects/adapters/predictors, and controlled native constraint structures with exact semantic ownership, source maps, deterministic galleries, static checks, honest unimplemented/public-authoring boundaries, and no inferred compile or simulation claim.`
  Verification: `clean cross-tree predecessor ddfa980a1 activates this leaf alone after completed .13.1.2; implementation remains unperformed until this continuity slice commits`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.4`
  Status: `proposed`
  Goal: `Emit representative coverage, property, model, scoreboard, fault, diagnostic, and result UVM structures without waiting for runtime qualification.`
  Acceptance: `Typed-IR fixtures and selected public routes generate covergroups, bound SVA checkers, analysis/model/scoreboard components, declared fault interception, report/result collection, capability/non-claim records, source maps, and deterministic review-gallery artifacts; structural and visual evidence is recorded separately from syntax/compile/runtime truth, and later simulator findings remain ordinary tracked defects rather than a reason to block emission breadth.`
  Verification: `pending after .13.1.3`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.5`
  Status: `proposed`
  Goal: `Close the full native UVM emission matrix, review workflow, examples, and deferred-runtime defect boundary.`
  Acceptance: `Every selected UVM mapping has an emitted representative or exact unsupported reason; normal/terse and typed-IR entry availability is distinguished from private preview fixtures; the checked gallery is easy to regenerate and inspect; automated static findings and director visual-review findings become exact task-tree defects; all emitted artifacts remain simulator-neutral and deterministic; legacy compatibility and docs are complete; and the matrix says emitted/reviewed/unqualified rather than waiting for or pretending full simulation.`
  Verification: `pending after .13.1.4; no simulator prerequisite`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.2`
  Status: `proposed`
  Goal: `Implement the first reusable exact open-source UVM compile/elaboration feasibility probe without converting experimental evidence into product support.`
  Acceptance: `As soon as .13.1.1 publishes the first gallery, select exact available open-source tool/version and immutable UVM source variant identities; separately attempt preprocessing/parsing, library compile, fixture compile, elaboration, and any supported runtime smoke; record argv, deviations/patches/failures and every not-exercised capability; expose a reusable nonblocking probe for later emission children; classify a demonstrated generator defect separately from a tool limitation; keep discovery labelled experimental; preserve qualified/runtime non-claims; and close honestly even when some or all stages are unsupported.`
  Verification: `pending immediately after .13.1.1; local Verilator UVM support is officially still in development`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.3`
  Status: `proposed`
  Goal: `Select, integrate, and capability-qualify the first exact PGEN parser plus MCP-operated NEXSIM simulator UVM runtime tuple.`
  Acceptance: `Once executable provider releases exist, a documentation selection freezes exact PGEN and NEXSIM versions/content/commands, parser-to-simulator handoff schema, NEXSIM semantic-introspection API schema, MCP protocol/profile, Accellera UVM identity, capability matrix, project-local artifacts, permissions, limits, and failure boundaries before implementation. The selected NEXSIM contract must expose stable source-mapped semantic identities; snapshot-consistent deterministic bounded queries; explicit side-effect-free inspection versus authorized control; hierarchy, types, four-state values, processes/events/scheduler state, assertions/coverage, and UVM topology/phases/objections/factory/configuration/TLM/sequences/RAL state where supported; plus run/step/pause/breakpoint/checkpoint/replay/cancel controls where selected. Implementation then proves parse, UVM/DUT compile, elaboration, four-state timed execution, notification/interception results, semantic checkpoint correlation, first-divergence localization against applicable IASIM/portable normalized oracles, deterministic rerun, cleanup, and every applicable normalized parity oracle without borrowing experimental or commercial-tool evidence. NEXSIM introspection remains provider evidence: it cannot redefine VIAL meaning, leak into canonical generated source, or turn one observed subset into full SystemVerilog/UVM qualification.`
  Verification: `provider direction is clarified: NEXSIM will expose deep semantic introspection through a clean API operated via MCP; exact release/API/schema/protocol/capability identities remain blocked on capability-ready PGEN and NEXSIM releases`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14`
  Status: `proposed`
  Goal: `Select the VHDL-2008 verification backend, methodology-provider mapping, existing-package migration, and GHDL/qualified profiles.`
  Acceptance: `The contract chooses pure VHDL-2008 portable responsibilities and an exact OSVVM/UVVM/no-provider decision for advanced semantics, maps drivers/samplers/scenarios/models/scoreboards/coverage/faults/results without requiring VHDL knowledge from a VIAL author, freezes efficient/readable/source-mapped artifact criteria plus standard/library/options and GHDL and broader qualified profiles, records PSL and language non-claims, and versions/migrates the inert VHDL observation package without inferring analyzer support.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15`
  Status: `proposed`
  Goal: `Implement and capability-qualify the selected VHDL verification backend.`
  Acceptance: `The bounded VIAL subset emits deterministic, efficient, readable, source-mapped VHDL artifacts without requiring VHDL knowledge from a VIAL author, analyzes/elaborates/runs under the exact installed profile, matches the portable normalized result oracle, reports exact standard/methodology/PSL capabilities and non-claims, migrates or versions the inert package exactly as contracted, and leaves HIAL VHDL synthesis output distinct.`
  Verification: `pending GHDL or selected analyzer/simulator availability`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.16`
  Status: `proposed`
  Goal: `Select and validate the first mixed-language HIAL/VIAL binding profile.`
  Acceptance: `An exact HIAL HDL plus VIAL verification-language combination, tool/version, bridge binding adapter, compile/elaboration/run sequence, capability/non-claim matrix, result parity oracle, project-local artifacts, licensing/CI policy, and unsupported combinations are selected and executed; no mixed-language claim is inferred from single-language gates.`
  Verification: `pending compatible mixed-language tool availability`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17`
  Status: `proposed`
  Goal: `Define and prove architecture-specific large-fixture scalability and bounded failure.`
  Acceptance: `Deterministic workload profiles scale bridge units/endpoints/domains/transactions/probes and VIAL declarations/scenarios/fibers/events/checks/models/scoreboards/coverage/random decisions; stage correctness oracles, wall/CPU time, descendant RSS, artifact/result size, compile/simulation cost, explicit caps, graceful failures, and stable gates are measured without substituting for the separately owned whole-product big/really-big qualification.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18`
  Status: `proposed`
  Goal: `Complete user documentation, runnable examples, migration guidance, backend/parity matrix, and architecture closeout.`
  Acceptance: `The mdBook fully documents shipped .vial/bridge/plan/tool/backend/result behavior with runnable examples and honest profile limits; public contracts, capability/support accounting, migration from observe and inert skeletons, AHB example, diagnostics, scale evidence, Knowledge Map, roadmap, task index, Memory, changelog, and all exact regression/doctrine gates agree before the tree closes.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19`
  Status: `proposed`
  Goal: `Select and decompose the post-first-backend expressive VIAL frontier without a synthesizability ceiling.`
  Acceptance: `Decision 0034 is converted into detailed task-tree leaves for terse/normal syntax equivalence and the complete selected verification-intent taxonomy: notification/interception, lifecycle control, stimulus orchestration, producer/observer communication, implementation selection/substitution, scoped configuration, register intent, constrained decisions, coverage/properties, timed interface interaction, debugging/introspection, and later justified intent families. Each records semantic compression, native/portable SV/UVM/VHDL mappings, backend-private mechanisms (including factories/config DB/TLM plumbing), fail-closed profiles, tests, docs, and non-claims; each applies the author test that no SV/UVM/VHDL knowledge is required and the backend test that generated artifacts remain efficient, readable, and source-mapped, without cloning raw target syntax or allowing the initial portable/native slices to masquerade as the language ceiling.`
  Verification: `pending activation after the first bounded backend/profile evidence establishes concrete decomposition inputs`
  Commit: `pending activation`

## Current Frontier

Architecture audit `.1` is complete. Decision `0032` selects one public
`.vial` source language, private immutable `VIALSemanticIR` and
`VIALExecutionIR`, bounded versioned `HIALVIALBridgeManifest`, typed external
native extensions, normalized result parity, plain SystemVerilog/Verilator as
the first runnable backend, and independently qualified UVM, VHDL methodology,
and mixed-language profiles. The canonical audit maps the handwritten AHB
fixture and exact migration/scale/public-surface boundaries. Clean audit commit
`2e2f7d25e` activated only `.2` through a separate continuity transition.
Completed `.2` accepts decision `0033` and the exact source/semantic-IR v1
contract. Clean contract commit `08f59167b` activated `.3` through a separate
continuity transition; `.3` now ships the bounded semantic-only parser,
validator, immutable `VIALSemanticIR`, sanitized report, checked AHB source,
and exact support/capability accounting. Clean implementation commit
`be9c74163` activated documentation contract `.4` through a separate
continuity transition. Completed `.4` accepts decision `0035` and the exact
review-routed `HIALVIALBridgeManifest` v1 contract. Clean selection commit
`0366dfe30` activated implementation `.5` through a separate continuity
transition. Completed `.5` now ships the private in-process/no-file bridge
producer through direct IAL0, direct IAL1, and generated/reparsed IAL1 for
IAL2. Clean implementation commit `51434a2ae` and activation commit
`bf1e25274` permit completed `.6` to accept decision `0036` and the exact
target-neutral ExecutionIR/logical-time/random-replay/native/plan/result/parity
contract. Clean selection commit `eaf3f95dc` permits this separate continuity
transition to activate `.7`; activation committed cleanly at `3ec8eab93`.
Audit `.7.1` then confirmed the exact type-binding mismatch. Completed `.7.2`
and accepted decision `0037` select a closed directional proof relation
between independently authoritative VIAL semantic and HIAL carrier types.
Completed `.7.3` now ships the private bounded binder, immutable ExecutionIR,
deterministic random/replay, and defensive in-process plan after clean
selection commit `2a1b3cefc` and its separate continuity activation. Completed
`.8` selects the public tooling contract under decision `0039`; clean commit
`d34da3254` activated `.9`. Completed `.9` accepts decision `0043` and the
exact `sv_portable_verilator` contract: static partial evaluation, inactive-
edge deterministic scheduling, declared probe adapters, source maps, closed
runtime trace/result projection, and exact Verilator 5.046 qualification with
an explicit known-value/two-state limit. Clean selection commit `ab3e73b72`
activates `.10` alone for public-tool/backend/result implementation. Clean
activation commit `5fd766600` decomposes that parent, and completed `.10.1`
now ships public capabilities/check/canonical normal-terse formatting through
one defensive source-only CLI/API with exact discovery/support accounting.
Both source styles enter the same typed semantic builder. Completed `.10.2`
now ships canonical HIAL-routed planning and virtual/atomic repository-local
artifact transactions. Clean `.10.2` commit `045629c97` activates `.10.3`
alone for backend/trace implementation. Completed `.10.3` now ships the
private deterministic `sv_portable_verilator` emitter, eight-artifact virtual
graph, source-mapped one-scheduler fixture, honest emission-only tool records,
and pure closed-JSONL trace validator. Completed `.10.4` now ships public run,
exact Verilator 5.046 compile/runtime, validated trace capture, normalized
results, deterministic reruns, and atomic cleanup. `.11` retains cross-backend
parity ownership after clean `.10.4` implementation commit `dfe87f536`.
Completed `.11` now qualifies 19 shared AHB outcome paths against the
handwritten oracle on byte-identical DUT source, while general cross-backend
parity remains unclaimed.
Clean cross-tree predecessor `ea1b76dd54` activated `.12` alone. Completed
`.12` accepts decision `0050`, selects simulator-neutral IEEE 1800.2-2020 and
exact Accellera UVM 2020-3.1 source, and separates deterministic emission from
optional experimental probes and future PGEN+NEXSIM runtime qualification.
Active containers `.13`/`.13.1` own five full-shaped reviewable emission
leaves that do not wait for simulation. Completed `.13.1.1` now ships the
  private emitter substrate, structural validator, exact capability truth, and
  first byte-checked artifact gallery. Completed `.13.1.2` now ships complete
  topology, timed interfaces, lifecycle, and notification/interception
  structures. Clean cross-tree predecessor `ddfa980a1` activates `.13.1.3`
  alone for stimulus/TLM/factory/configuration/RAL/constrained-decision
  emission;
`.13.2` is dependency-ready for an exact reusable open-tool compile/
elaboration probe, while `.13.3` remains blocked on capability-ready PGEN and
NEXSIM releases.
Decision `0034` records that
this bounded profile is not VIAL's language ceiling: target SV/UVM/VHDL
machinery is compiler-owned in the same architectural sense that assembly is
compiler-owned beneath C/C++ or Rust.

## Decisions

- `2026-08-01`: Clean cross-tree predecessor
  `ddfa980a132ee38b0af060c6ef2fcf20856cf9f4` permits `.13.1.3` to activate
  alone after completed `.13.1.2`. Activation changes durable continuity only:
  no emitter byte, artifact graph, review gallery, public capability, parser,
  compile, elaboration, runtime, result, or parity evidence changes.

- `2026-08-01`: Clean predecessor
  `254806049bf9d545d36e5a4f5e9666f1ef4cbcb4` permits `.13.1.2` to activate
  alone for complete selected component topology, timed interfaces, lifecycle
  control, and notification/interception structures. Activation changes only
  durable continuity: no emitter bytes, review artifact, public capability,
  parser, compile, elaboration, runtime, result, or parity evidence changes.

- `2026-08-01`: Ship the private `sv_uvm_emit.accellera_2020_3_1`
  foundation without widening public `vial run`. Exact typed/context/
  component/interface/fixture/top sources, line/column maps, methodology and
  structural evidence, atomic artifacts, and the checked gallery are product
  emission evidence; every parser, compile, elaboration, runtime, result,
  parity, manual-review completion, and complete-breadth state remains
  separately unclaimed.

- `2026-08-01`: Clean predecessor `6c6b70048913fa1c7ebb5967217bc463bbdfbd2b`
  permits `.13.1.1` to activate alone for the selected native UVM emitter
  substrate, deterministic artifact graph, source maps, static validators,
  atomic publication, limits, cleanup, and first gallery. Activation changes no
  implementation or public capability and claims no parse, compile,
  elaboration, run, result, or parity evidence.

- `2026-07-29`: Name the two peer domains HIAL (hardware intent) and VIAL
  (verification intent). HIAL is the architectural name for the current
  synthesizable IAL0/IAL1/IAL2 stack; VIAL is pure verification intent.
- `2026-07-29`: Require HIAL lowerings to synthesizable SystemVerilog and VHDL,
  and VIAL lowerings to native SystemVerilog/UVM or VHDL verification code.
- `2026-07-29`: Join the domains through a typed, language-neutral bridge and
  typed native extension points. Do not solve expressiveness by cloning the
  target verification languages.
- `2026-07-29`: Treat VIAL0/VIAL1/VIAL2 as a topology hypothesis, not a
  decision. The architecture audit must select and justify the layers.
- `2026-07-29`: Park this architecture as proposed/inactive and resume the
  existing IAL2 roadmap priority after the parking commit.
- `2026-07-29`: Require explicit verification-tool capability profiles. Use
  Verilator as the fast portable SystemVerilog subset tier, not as full-LRM or
  UVM authority; require a separately qualified full-language/UVM simulator
  tier for advanced native VIAL output. Apply the same claim-by-capability rule
  to VHDL and mixed-language verification. This requirement records the
  director's agreement but does not itself activate this proposed tree.
- `2026-07-29`: Describe Verilator precisely as event-capable compiled
  simulation, not a traditional full-language event-driven simulator. Its
  explicit model-evaluation loop and `--timing` scheduling of supported delays,
  event controls, waits, forks, and delayed processes strengthen rather than
  erase the separate full-language/UVM profile requirement.
- `2026-07-29`: Parent selector `.819` retains this proposed boundary and
  selects the smaller adjacent two-window exact-three AHB readiness audit.
- `2026-07-30`: Parent selector `.832` selects the smaller no-behavior nested-
  bitwise concurrent-assertion precedence audit before this broader
  architecture. HIAL/VIAL remains proposed with every topology, bridge,
  semantics, backend, qualification, parity, migration, and scale requirement
  unchanged.
- `2026-07-30`: Parent selector `.833` selects the smaller mdBook VHDL
  introduction/backend-summary truth repair after assertion precedence ships.
  HIAL/VIAL remains proposed with its complete architecture contract unchanged.
- `2026-07-30`: Parent selector `.841` selects the narrower IR-policy-governed
  source-facing HIR boundary before this comprehensive dual-intent audit.
  HIAL/VIAL remains proposed with every architecture requirement unchanged.
- `2026-07-31`: Parent selector `.844` selects proposed no-behavior audit `.1`
  after the private HIR boundary closes and live task-tree integrity ships.
  The audit remains inactive until a separate clean activation commit.
- `2026-07-31`: Clean parent selector commit `031b21d4f` activates only audit
  `.1`; architecture selection and decomposition remain unperformed until the
  activation commits cleanly.
- `2026-07-31`: Audit `.1` accepts decision `0032`: VIAL uses one public
  `.vial` source plus two private IR stages around a bounded versioned HIAL/VIAL
  bridge, not VIAL0/VIAL1/VIAL2. Plain SystemVerilog/Verilator is first;
  UVM, VHDL methodology, and mixed-language profiles remain separately
  qualified. Proposed `.2` owns the exact source/semantic-IR contract.
- `2026-07-31`: Clean architecture audit commit `2e2f7d25e` activates only
  source/semantic-IR contract `.2`; contract findings and product behavior
  remain unchanged until activation commits cleanly.
- `2026-07-31`: Contract `.2` accepts decision `0033`: VIAL v1 is a closed
  span-aware S-expression language with target-neutral typed semantics and a
  private immutable `VIALSemanticIR`, not raw Lispish forms. Proposed `.3`
  owns the exact bounded implementation after separate activation.
- `2026-07-31`: Clean contract commit `08f59167b` activates only `.3`; every
  parser/source/report/capability/support/test implementation change remains
  unperformed until activation commits cleanly.
- `2026-07-31`: Director clarification accepts decision `0034`: unlike HIAL,
  VIAL follows “full power underneath, simpler intent above” and is not
  synthesis-bounded. The portable core is an initial profile, not
  the language ceiling; native typed VIAL must abstract the verification
  intents enabled by full SV/UVM/VHDL capabilities while keeping
  `uvm_event`/callbacks, phases/objections, factories/config DB/TLM, and similar
  target plumbing behind backend mappings. Terse and verbose normal forms
  share one semantic model. Bounded `.3` remains unchanged; proposed `.19`
  owns durable post-first-backend intent taxonomy and task-tree decomposition.
- `2026-07-31`: “Abstraction means simplification” is made an explicit VIAL
  usability and backend criterion: an author need not know SV/UVM/VHDL; those
  languages are conceptually backend targets, while the compiler owns target
  expertise and emits efficient, readable, source-mapped artifacts.
- `2026-07-31`: Director-approved decision `0037` selects compiler-proved
  directional type relations rather than forcing VIAL semantic types to copy
  HIAL hardware carriers. Version 1 admits only bit-domain identity,
  two-state known-value injection, and exact enum-encoding injection; inverse
  X/Z collapse and every broader coercion remain fail-closed. Proposed `.7.3`
  owns implementation after separate clean activation.
- `2026-07-31`: Clean `.7.2` selection commit `2a1b3cefc` permits a separate
  continuity-only activation of `.7.3`. Activation changes only durable
  ownership/frontier records; exact binder, ExecutionIR, random/replay, plan,
  capability/support, backend, runtime, and product behavior remain unchanged.
- `2026-07-31`: Clean `.7.3` implementation commit `44dbecd1a` permits a
  separate continuity-only activation of public tooling-contract leaf `.8`.
  Activation changes durable ownership/frontier records only; no CLI/API,
  file/layout/schema implementation, artifact, backend, runtime, parity, or
  product behavior changes.
- `2026-07-31`: Decision `0043` selects `sv_portable_verilator` as an exact
  Verilator 5.046 known-value runtime profile. Static partial evaluation,
  inactive-edge scheduling, generated declared-probe adapters, closed trace,
  result projection, source maps, artifacts, gates, limits, and non-claims are
  frozen before `.10` implementation; no target artifact or runtime ships.
- `2026-07-31`: Clean `.9` selection commit `ab3e73b72` activates `.10` alone
  for implementation of the selected public tool path, plain-SV backend,
  Verilator runtime, and normalized result producer. Activation changes no
  implementation or product behavior.
- `2026-07-31`: Completed `.10.1` implements the public VIAL source-only
  tooling boundary: capabilities/check/normal-terse formatting, closed
  request/result records, one semantic projection, exact discovery/support,
  atomic diagnostics, and no writes. Proposed `.10.2` owns planning/artifacts.
- `2026-07-31`: Clean `.10.1` commit `50a0d7d39` activates only `.10.2`
  canonical planning/artifact implementation. Activation changes no API,
  plan/file, artifact transaction, backend, runtime, or product behavior.
- `2026-07-31`: Completed `.10.2` ships defensive public planning through all
  three canonical HIAL review routes and virtual or atomic repository-local
  artifact graphs. The direct-IAL0 compatibility gap is closed by admitting
  transaction-free endpoint fixtures, while transaction-bearing plans still
  require exact reviewed transaction truth. Backend/runtime/parity stay
  unclaimed.
- `2026-07-31`: Clean `.10.2` implementation commit `045629c97` activates
  `.10.3` alone for portable SystemVerilog backend and trace projection.
  Activation changes no implementation, artifact, capability/support,
  compile/runtime, result, parity, or product behavior.
- `2026-07-31`: Completed `.10.3` ships private deterministic portable-
  SystemVerilog emission and pure trace validation. The emitter negotiates the
  exact bounded known-value profile, keeps backend caps outside target-neutral
  ExecutionIR identity, emits one virtual graph with complete source maps and
  selected-but-unexecuted command records, and preserves one logical scheduler
  as parallel-order authority. The validator checks caller-supplied canonical
  prefixed JSONL without executing a simulator or replaying verification
  semantics. Then-proposed `.10.4` alone owns public publication, compile/run,
  runtime capture, and normalized result production; `.11` retains parity.
- `2026-07-31`: Clean `.10.3` implementation commit `201590d84` activates
  `.10.4` alone for public atomic backend publication, exact Verilator 5.046
  compile/run, trace capture, and normalized result production. Activation
  changes continuity ownership only and introduces no behavior or capability
  claim.
- `2026-07-31`: Completed `.10.4` ships public `fsmgen vial run`, exact
  Verilator execution, validated trace/result/output manifests, deterministic
  virtual and atomic filesystem publication, and exact cleanup. Known-value,
  complete-four-state, parity, UVM, VHDL, mixed-language, and scale boundaries
  remain explicit; `.11` retains parity.
- `2026-07-31`: Clean `.10.4` implementation commit `dfe87f536` activates
  `.11` alone to compare the generated portable result with the handwritten
  AHB oracle. Activation changes continuity ownership only and introduces no
  parity report, capability claim, or product behavior.
- `2026-07-31`: Completed `.11` executes the handwritten and generated-VIAL
  harnesses independently over byte-identical generated DUT source, compares
  19 public/shared success and ERROR outcome paths, and emits one deterministic
  closed parity report. Undeclared internal capture/hold/completion signals
  are explicit exclusions; general cross-backend parity remains unclaimed.
- `2026-08-01`: Decision `0050` selects IEEE 1800.2-2020 / exact Accellera UVM
  2020-3.1 as the native methodology source while rejecting a commercial
  simulator as a required near-term dependency. Native work is split into
  deterministic `sv_uvm_emit.accellera_2020_3_1`, optional explicitly
  experimental open-source probes, and future `sv_uvm_qualified` runtime.
- `2026-08-01`: Director clarification identifies the separately developing
  PGEN project as the HDL parser provider and NEXSIM as the intended
  open-source commercial-grade simulator provider. Their future exact
  versioned handoff is a qualification tuple, not a current capability claim;
  `.13.1` emission can progress independently now.
- `2026-08-01`: Director clarification states that NEXSIM will expose deep
  semantic introspection through a clean API operated via MCP. Future `.13.3`
  qualification must therefore consume versioned semantic objects and
  snapshot-consistent read/control operations, correlate them through source
  maps to generated UVM and HIAL/VIAL identities, and localize the first
  differential mismatch rather than relying only on logs, waveforms, or a
  final pass/fail. This strengthens provider evidence without making NEXSIM or
  MCP the authority over VIAL meaning.
- `2026-08-01`: Simulator availability does not limit native generation
  breadth. Active `.13.1` is decomposed into five full-shaped reviewable
  emission leaves; `.13.2` probes exact open-tool compile/elaboration as soon
  as the first gallery exists. Static checks and director visual review are
  honest emission evidence, while generated syntax/strategy may iterate from
  tool feedback without changing VIAL meaning or implying qualification.

## Open Questions

- `.13.2` is now dependency-ready and must select the exact optional open-
  source feasibility tool in a separate activation; an unsupported result is
  still useful if it is measured and remains experimental.
- `.13.3` must select exact PGEN/NEXSIM versions, handoff schema, semantic-
  introspection API schema, and MCP profile when capability-ready releases
  exist; no version or unsupported query/control capability is invented in
  advance.
- `.14` must choose the VHDL methodology provider and exact analyzer/simulator;
  GHDL and other VHDL tools are currently absent locally.
- `.16` must choose the first available mixed-language tool/profile.
- `.17` must select measured architecture-specific capacity budgets; the
  separate whole-product scale tree retains big/really-big qualification.
- `.19` must convert decision `0034` into detailed implementable native-
  verification semantic-family leaves before the architecture closes.

## Blockers

- None for active `.13.1.2` or later `.13.1` native UVM emission leaves;
  they generate and expose review galleries without simulator availability and
  make explicit per-stage not-run/experimental claims.
- `.13.3` runtime qualification is intentionally blocked on capability-ready
  PGEN and NEXSIM releases. The planned NEXSIM API/MCP direction removes no
  release/schema/capability prerequisite. Commercial simulator availability
  is not a roadmap prerequisite, and Verilator/Icarus cannot be promoted from
  experimental evidence to `sv_uvm_qualified`.
- Later UVM, VHDL, and mixed-language implementation/qualification leaves
  retain explicit tool availability prerequisites and cannot borrow the
  current Verilator result.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-29` | architecture parking | `knowledge-map/scripts/gen_knowledge_map.sh`; `knowledge-map/scripts/check_knowledge_map.sh`; `mdbook build docs/book --dest-dir build`; `scripts/check_doctrines.sh`; task/roadmap/book/fact positive scans; `git diff --check`; all heavyweight commands under authorized `--host-max-pct 100 --process-max-rss-mb 4096` | `passed`; Knowledge Map is current at 1,017 facts / 5,175 question keys; mdBook built 72 files / 15,852 KiB under repository-root `build/`, which was removed with no residue; all doctrine gates passed; exact post-gate Stats-compatible capacity was 46.7% (11.21/24.00 GiB) and kernel pressure was 1 (normal); the guard percentage was not used as capacity truth |
| `2026-07-31` | `.1` | architecture evidence audit; decision `0032`; exact AHB mapping; `.2`-.18 decomposition; `scripts/check_task_tree_integrity.pl`; docs audits; `mdbook test`; repository-local `mdbook build`; Knowledge Map generation/check; memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; selected one public `.vial`, two private IRs, versioned bridge, portable/native/result/profile contracts, and plain-SV/Verilator first; trees=2 / nodes=864; docs Files=3 / Tests=40; 37 chapters; 73 files / 16,810,633 bytes; Knowledge Map 1,085 facts / 5,600 keys; no product behavior change |
| `2026-07-31` | `.2` activation | clean `.1` predecessor; task/index/roadmap/book/fact/Memory/changelog continuity; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; `.2` alone active; trees=2 / nodes=864; docs Files=3 / Tests=40; 37 chapters; 73 files / 16,812,484 bytes; Knowledge Map 1,085 facts / 5,600 keys; Memory 46 lines; contract and product behavior unchanged |
| `2026-07-31` | `.2` selection | decision `0033`; exact source/grammar/type/property/declaration/fixture/IR/report/diagnostic/limit/negative contract; task/roadmap/book/fact consistency; task-tree/docs/relative-path/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; `.3` alone selected; trees=2 / nodes=864; docs Files=3 / Tests=40; paths Files=1 / Tests=2; 37 chapters; 73 files / 16,842,038 bytes; Knowledge Map 1,086 facts / 5,617 keys; no product behavior change |
| `2026-07-31` | `.3` activation | clean `.2` predecessor; task/index/roadmap/book/fact/Memory/changelog continuity; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; `.3` alone active; trees=2 / nodes=864; docs Files=3 / Tests=40; 37 chapters; 73 files / 16,845,901 bytes; Knowledge Map 1,086 facts / 5,617 keys; Memory 43 lines; implementation and product behavior unchanged |
| `2026-07-31` | `.3` implementation | dedicated parser/builder/SemanticIR/report syntax; focused t1550; support/capability/accounting and defensive-copy audits; task-tree/docs/relative-path/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; checked AHB source is 4,986 bytes / 123 lines / SHA-256 2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd; focused Files=3 / Tests=7,055; adjacent Files=9 / Tests=32; docs Files=3 / Tests=40; paths Files=1 / Tests=2; 37 chapters; build 73 files / 16,896,993 bytes; Knowledge Map 1,087 facts / 5,631 keys; explicit semantic-only non-claims; unrelated t261/t296 failures routed to separate proposed task trees; output removed exactly |
| `2026-07-31` | `.4` activation | clean `.3` predecessor; task/index/roadmap/audit/book/fact/Memory/changelog continuity; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; trees=2 / nodes=865; docs Files=4 / Tests=42; 37 chapters; build 73 files / 16,900,280 bytes; Knowledge Map 1,087 facts / 5,631 keys; Memory 54 lines; bridge contract and all product behavior unchanged; output removed exactly |
| `2026-07-31` | `.4` selection | decision `0035`; exact review-route/annotation/manifest/identity/type/event/provenance/API/diagnostic/limit/non-claim contract; current IAL0/IAL1/IAL2 and checked VIAL evidence; task/roadmap/audit/book/fact consistency; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; evidence Files=3 / Tests=21; trees=2 / nodes=865; docs Files=4 / Tests=42; 37 chapters; build 73 files / 16,930,263 bytes; Knowledge Map 1,088 facts / 5,640 keys; Memory 54 lines; `.5` alone selected; no product behavior change; output removed exactly |
| `2026-07-31` | `.5` activation | clean `.4` predecessor; task/index/roadmap/audit/contract/book/fact/Memory/changelog continuity; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; `.5` alone active; trees=2 / nodes=865; docs Files=4 / Tests=42; 37 chapters; build 73 files / 16,932,359 bytes; Knowledge Map 1,088 facts / 5,640 keys; Memory 57 lines; implementation and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.5` implementation | private bridge Builder/Manifest/Report; additive parsed/reported IAL1 annotation; exact direct IAL0/direct IAL1/IAL2-via-IAL1 routes; t1551 and adjacent support/capability audits; preservation hashes; task/docs/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; focused Files=6 / Tests=7,058; adjacent Files=28 / Tests=56; trees=2 / nodes=865; docs Files=4 / Tests=51; 37 chapters; build 73 files / 16,965,845 bytes; Knowledge Map 1,089 facts / 5,643 keys; generated IAL1 4,174 bytes / SHA-256 b0f3446874367787d0dd134701ff9e89a3b24af6ef9c03d6eb9dc484093f9e4c; generated IAL0 unchanged at 5,854 bytes / SHA-256 3d8fa7ac7c3a7f2c9ca063aca2cf707106b511219243d8b277ac3e2e8cf47bcf; no public file/API, binding, plan, backend, or runtime claim; `.6` selected next for clean activation; output removed exactly |
| `2026-07-31` | `.6` activation | clean `.5` predecessor; task/index/roadmap/audit/bridge-contract/book/fact/Memory/changelog continuity; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.6` alone active; trees=2/nodes=865; docs Files=4/Tests=51; 37 chapters; build 73 files/16,971,000 bytes; Knowledge Map 1,089 facts/5,643 keys; Memory 51 lines; execution contract and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.6` selection | decision `0036`; exact binding/ExecutionIR/logical-time/action/random-replay/native/plan/result/parity/diagnostic/limit/AHB/non-claim contract; current SemanticIR/bridge/extension/report evidence; task/roadmap/audit/book/fact consistency; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; contract 1,148 lines; evidence Files=3/Tests=24; trees=2/nodes=865; docs Files=4/Tests=51; 37 chapters; build 73 files/17,008,064 bytes; Knowledge Map 1,090 facts/5,658 keys; Memory 56 lines; `.7` alone selected next; no implementation/product change; output removed exactly |
| `2026-07-31` | `.7` activation | clean `.6` predecessor; task/index/roadmap/audit/execution-contract/book/fact/Memory/changelog continuity; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.7` alone active; trees=2/nodes=865; docs Files=4/Tests=51; 37 chapters; build 73 files/17,011,689 bytes; Knowledge Map 1,090 facts/5,658 keys; Memory 55 lines; implementation and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.7.1` audit | direct SemanticIR/bridge field projection; source/producer/contract/prior-test root cause; task split; canonical audit/fact/decision/roadmap/book/live-doc sync; focused frontend/bridge and docs evidence; task/mdBook/Knowledge Map/memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; three transaction type-relation mismatches confirmed; Files=2/Tests=21 and docs Files=4/Tests=309; trees=2/nodes=868; 37 chapters; build 73 files/17,024,906 bytes; Knowledge Map 1,091 facts/5,666 keys; Memory 49 lines; `.7.2` blocked pending director choice; no implementation/product change; output and failed off-route destination absent |
| `2026-07-31` | `.7.2` selection | decision `0037`; exact directional relation records/proofs/directions/AHB oracle/capability/diagnostics/negative boundaries; source/bridge/execution contracts; audit/book/fact/live-doc continuity; focused frontend/bridge and docs evidence; task/mdBook/Knowledge Map/memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; director-approved bit-domain identity, known-value injection, and enum-encoding injection selected; Files=2/Tests=21 and docs Files=4/Tests=309; trees=2/nodes=868; 37 chapters; build 73 files/17,029,957 bytes; Knowledge Map 1,092 facts/5,674 keys; Memory 53 lines; `.7.3` alone selected next for clean activation; no implementation/product change; output and `.bin`/`.log` residue absent |
| `2026-07-31` | `.7.3` activation | clean `.7.2` predecessor; task/index/roadmap/audit/contracts/book/fact/Memory/changelog continuity; task-tree/docs/mdBook/Knowledge Map/memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.7.3` alone active; trees=2/nodes=868; docs Files=4/Tests=309; 37 chapters; build 73 files/17,031,568 bytes; Knowledge Map 1,092 facts/5,674 keys; Memory 53 lines; implementation and product behavior unchanged; output and `.bin`/`.log` residue absent |
| `2026-07-31` | `.7.3` implementation | private binder/ExecutionIR/random/replay/plan syntax and t1552; current semantic/bridge/capability/support/accounting/provenance audits; result/parity ownership correction; task/roadmap/audit/book/fact continuity; task-tree/docs/relative-path/mdBook/Knowledge Map/Memory/diff/staged implementation acceptance/doctrines; exact cleanup | `passed`; focused/adjacent Files=10/Tests=7135; nine changed Perl modules syntax OK; exact AHB plan 21 operations/4 fibers/3 simultaneous/10 relations/22 bindings/2 scalar cells/scoreboard capacity 4/2 coverage bins; trees=2/nodes=868; docs Files=4/Tests=609 and paths Files=1/Tests=2; 37 chapters; build 73 files/17,058,063 bytes; Knowledge Map 1,092 facts/5,674 keys; Memory 56 lines; selected result/parity schemas retain .10/.11 owners without false capability claims; known unrelated t370 drift remains separately owned; no target/public/runtime claim; output removed exactly |
| `2026-07-31` | `.8` activation | clean `.7.3` implementation predecessor; task/index/roadmap/audit/execution-contract/book/fact/Memory/changelog continuity; task-tree/docs/relative-path/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.8` alone active for public tooling-contract selection; trees=2/nodes=868; docs Files=4/Tests=609 and paths Files=1/Tests=2; 37 chapters; build 73 files/17,058,744 bytes; Knowledge Map 1,092 facts/5,674 keys; Memory 56 lines; CLI/API/file/layout/artifact/backend/runtime and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.8` selection | decision `0039`; exact source projections/CLI/API/HIAL routes/layout/manifests/capabilities/support/diagnostics/compatibility/non-claims; current source/bridge/execution and docs evidence; task/roadmap/audit/book/fact continuity; task/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; contract 514 lines/19,071 bytes; source/bridge/execution Files=3/Tests=27; docs Files=4/Tests=305 and paths Files=1/Tests=2; trees=2/nodes=868; 37 chapters; build 73 files/17,082,320 bytes; Knowledge Map 1,093 facts/5,689 keys; Memory 47 lines; `.9` selected next for clean activation; parser/CLI/API/files/backend/runtime/product behavior unchanged; output removed exactly |
| `2026-07-31` | `.9` activation | clean `.8` selection predecessor `d34da3254`; task/index/roadmap/audit/tooling-contract/book/fact/Memory/changelog continuity; task-tree/docs/relative-path/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.9` alone active; trees=2/nodes=868; docs Files=4/Tests=314 and paths Files=1/Tests=2; 37 chapters; repository-local build 73 files/17,083,185 bytes; Knowledge Map 1,093 facts/5,689 keys; Memory 47 lines; an initially misresolved same-volume off-repository build was measured at 73 files/16,828 KiB, its exact project-owned directory removed, the corrected local build rerun, and both destinations proven absent; contract selection and product behavior unchanged |
| `2026-07-31` | `.9` selection | decision `0043`; exact known-value plain-SV lowering/scheduler/value/adapter/artifact/trace/source-map/tool/gate/limit/non-claim contract; local Verilator 5.046 substrate run; source/bridge/execution and docs evidence; task/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; contract 584 lines/26,066 bytes; source/bridge/execution/AHB runtime Files=4/Tests=30; docs Files=4/Tests=323 and paths Files=1/Tests=2; trees=3/nodes=885/one segment/one index archive; 37 chapters; build 73 files/17,133,866 bytes; Knowledge Map 1,096 facts/5,733 keys; Memory 37 lines; all nine doctrines pass at 20 surfaces/2,780 paths; proposed `.10` selected next for clean activation; no implementation/product change; output removed exactly |
| `2026-07-31` | `.10` activation | clean `.9` predecessor `ab3e73b72`; task/index/roadmap/audit/contracts/book/facts/Memory/changelog continuity; task/docs/path/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.10` alone active; docs Files=4/Tests=323 and paths Files=1/Tests=2; trees=3/nodes=885/one segment/one index archive; 37 chapters; build 73 files/17,134,244 bytes; Knowledge Map 1,096 facts/5,733 keys; Memory 36 lines; all nine doctrines pass at 20 surfaces/2,780 paths; implementation and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.10` decomposition | clean activation predecessor `5fd766600`; four child boundaries; task/index/roadmap/audit/contracts/book/facts/Memory/changelog continuity; task/live-doc/docs/path/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.10.1` alone active under parent `.10`; focused docs Files=7/Tests=56; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-root build 73 files/16,880 KiB; Knowledge Map 1,096 facts/5,734 keys; Memory 36 lines; all nine doctrines pass at 20 surfaces/2,780 paths; no implementation or product behavior change; output removed exactly |
| `2026-07-31` | `.10.1` implementation | source projection/CLI/API/discovery/support implementation and syntax; guarded semantic/bridge/execution/tool tests; README/live-doc/docs/path/task gates; mdBook test/build; Knowledge Map; Memory/diff; staged acceptance/doctrines; exact cleanup | `passed`; source suite Files=6/Tests=7,083; docs/live/path/task Files=11/Tests=106; 15 changed/new Perl/test paths report syntax OK; README is 245 lines/9,916 bytes, below its 246-line/9,952-byte predecessor baseline; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-root build 73 files/16,900 KiB; Knowledge Map 1,096 facts/5,735 keys; Memory 37 lines; all nine staged doctrines pass at 20 live-document surfaces and 2,780/2,780 tracked Markdown paths; output removed exactly |
| `2026-07-31` | `.10.2` activation | clean `.10.1` implementation predecessor `50a0d7d39`; task/index/roadmap/audit/contracts/book/facts/Memory/changelog continuity; task/docs/live/path/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.10.2` alone active for planning/artifacts; docs Files=4/Tests=8 and live/path/task Files=7/Tests=98; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-root build 73 files/16,900 KiB; Knowledge Map 1,096 facts/5,735 keys; Memory 38 lines; implementation and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.10.2` implementation | canonical direct-IAL0/direct-IAL1/IAL2-via-IAL1 PlanBuilder; public plan CLI/API; deterministic bridge/plan/tool-manifest graph; virtual and atomic repository-local transactions; direct-IAL0 contract correction; syntax/focused/adjacent/docs/path/task/live-doc/mdBook/Knowledge Map/Memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; guarded focused/adjacent Files=11/Tests=7,108 and all changed/new Perl/test paths report syntax OK; direct IAL0 endpoint/reset planning and IAL1/IAL2 AHB routes pass while transaction-dependent direct IAL0, unsafe paths, collisions, symlinks, traversal, malformed inputs, and unavailable runtime fail atomically; docs Files=6/Tests=357; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-root build 73 files/16,916 KiB; Knowledge Map 1,096 facts/5,736 keys; README 245 lines/9,913 bytes; Memory 39 lines; all nine staged doctrines pass at 20 live-document surfaces and 2,780/2,780 tracked Markdown paths; output and `.bin`/`.log` residue absent |
| `2026-07-31` | `.10.3` activation | clean `.10.2` implementation predecessor `045629c97`; task/index/roadmap/audit/contracts/book/facts/Memory/changelog continuity; task/docs/live/path/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.10.3` alone active for portable-SystemVerilog artifact/trace implementation; docs Files=6/Tests=357; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-root build 73 files/16,916 KiB; Knowledge Map 1,096 facts/5,736 keys; README unchanged at 245 lines/9,913 bytes; Memory remains bounded; all nine staged doctrines pass at 20 live-document surfaces and 2,780/2,780 tracked Markdown paths; implementation and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.10.3` implementation | exact private ExecutionIR/bridge/DUT handoff; deterministic portable-SV emitter; complete source map; one-scheduler parallel lowering; pure closed-trace validator; capability/support truth; syntax/focused/impacted/docs/live/path/task/mdBook/Knowledge Map/Memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; 13 changed/new Perl/test paths syntax OK; guarded impacted VIAL/support suite `All tests successful` at Files=27/Tests=7,190; docs/live/path/task suite `All tests successful` at Files=8/Tests=378; all 37 mdBook chapters test and repository-local build has 73 files/16,952 KiB before exact removal; Knowledge Map 1,096 facts/5,736 keys; task integrity three trees/889 nodes/one segment/one index archive; Memory 47 lines; README 245 lines/9,913 bytes; final staged doctrines cover all nine checks, 20 live-document surfaces, and 2,780/2,780 tracked Markdown paths; public actions unchanged and compile/runtime/result/parity explicitly unclaimed; independently stale t296 PPIF module-name failures reproduce under their existing separate owner and no implicated corpus/pipeline path changes here |
| `2026-07-31` | `.10.4` activation | clean `.10.3` implementation predecessor `201590d84`; task/index/roadmap/audit/contracts/book/facts/Memory/changelog continuity; task/docs/live/path/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.10.4` alone active for public publication, Verilator run integration, trace capture, and normalized results; docs/live/path/task Files=8/Tests=378; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-root build 73 files/16,952 KiB; Knowledge Map 1,096 facts/5,736 keys; README unchanged at 245 lines/9,913 bytes; Memory 47 lines; implementation and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.10.4` implementation | public API/CLI run; exact Verilator 5.046 version/argv/digests; bounded process/output/staging; both selected AHB scenarios; ten semantic trace/result streams; deterministic virtual and unchanged filesystem reruns; same-barrier any-join tie/cancellation; atomic failures/cleanup; syntax/focused/support/docs/live/path/task/mdBook/Knowledge Map/Memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; 19 changed/new Perl/test paths syntax OK; guarded VIAL/support Files=10/Tests=7,170; docs/live/path Files=5/Tests=323; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-local build 73 files/16,964 KiB; Knowledge Map 1,096 facts/5,736 keys; README 245 lines/9,917 bytes; Memory 44 lines; initial default RAM guard stopped on its conservative free-page estimate while kernel pressure reported 83% free, then bounded 100%-host/4,096-MiB-process mdBook gates passed; `.10` complete; `.11` retains parity; output removed exactly |
| `2026-07-31` | `.11` activation | clean `.10.4` implementation predecessor `dfe87f536`; task/index/roadmap/audit/contracts/book/facts/Memory/changelog continuity; docs/live/path/task/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.11` alone active for normalized result parity against the handwritten AHB oracle; docs/live/path Files=5/Tests=323; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-local build 73 files/16,964 KiB; Knowledge Map 1,096 facts/5,736 keys; README unchanged at 245 lines/9,917 bytes; Memory 46 lines; implementation and product behavior unchanged; output removed exactly |
| `2026-07-31` | `.11` implementation | private closed AHB oracle comparator; independent handwritten/generated execution over identical DUT bytes; exact result/oracle projections; mismatches/exclusions/failures; capability/support truth; syntax/focused/impacted/docs/live/path/task/mdBook/Knowledge Map/Memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; all 15 changed/new Perl/test paths syntax OK; exact Verilator 5.046 impacted suite Files=11/Tests=7,183; 19 shared paths compare equivalent across two scenarios while two undeclared-internal families are explicitly excluded; malformed, duplicate, nonzero, ineligible, different-DUT, and semantic-mismatch evidence is regression-locked; docs/live/path Files=5/Tests=323; trees=3/nodes=889/one segment/one index archive; all 37 chapters test; repository-local build 73 files/16,976 KiB before exact removal; Knowledge Map 1,096 facts/5,736 keys; README 245 lines/9,917 bytes; Memory 47 lines; general cross-backend parity remains unclaimed; final staged doctrines and residue census pass |
| `2026-08-01` | `.12` activation | clean `ea1b76dd54` predecessor; exact local simulator command census; task/index/book/fact/Memory continuity; task/live/path/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; `.12` alone active for native SystemVerilog/UVM contract selection; Verilator and Icarus present, no qualified UVM simulator found; paths Files=1/Tests=2; trees=3/nodes=899/one segment/one index archive; 22 live surfaces/2,937 paths; maintained-reference delta 0/+6/+361; zero ceiling increases; Knowledge Map 1,104 facts/5,585 questions; Memory 46 lines; all 49 chapters; removed build 85 files/16,600,519 bytes; all nine staged doctrines pass; no revision/profile/backend/artifact/capability/runtime/product behavior selected or changed |
| `2026-08-01` | `.12` selection | exact Accellera source/release and open-source tool evidence; director PGEN/NEXSIM/commercial-tool/simulator-neutral/full-emission/compiler-iteration clarifications; legacy UVM 1.2 and current VIAL contract audit; decision `0050`; exact mapping/profile/artifact/gate/non-claim contract; task/roadmap/audit/book/fact/Memory continuity; focused docs/live/task/mdBook/Knowledge Map/memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; simulator-neutral IEEE 1800.2-2020 / Accellera UVM 2020-3.1 tag/commit selected; active `.13.1` decomposes five full-shaped reviewable emission leaves with `.13.1.1` next, `.13.2` probes exact open-tool compile/elaboration from the first gallery, and `.13.3` retains future PGEN+NEXSIM qualification; generated syntax/strategy may iterate under exact emitter identity while VIAL meaning stays fixed; task integrity three trees/907 nodes/one segment/one index archive; focused docs `All tests successful` at Files=4/Tests=13; 22 live surfaces/2,938 paths and exact maintained-reference delta 0/+190/+8,769 pass; all 49 mdBook chapters test and the repository-local 85-file/16,674,248-byte build is removed exactly; Knowledge Map is current at 1,104 facts/5,593 questions/5,759 occurrences; Memory is 46 lines; no native implementation, parser, compile, elaboration, simulation, runtime, result, parity, or commercial-tool dependency ships |
| `2026-08-01` | `.13.1.1` activation | clean predecessor; task/index/fact/Memory continuity; task integrity; Knowledge Map; relative paths; memory; live-document containment; diff; staged docs-only acceptance; doctrines | `passed`; `.13.1.1` alone active; task integrity remains three trees/907 nodes/one segment/one index archive; Knowledge Map is current at 1,104 facts/5,602 questions/5,768 occurrences; relative paths report `All tests successful` at Files=1/Tests=2; Memory is 46 lines; all 22 live-document surfaces and 2,939/2,939 paths pass with zero maintained-reference changes and zero ceiling increases; all nine staged doctrines pass; no implementation, generated artifact, parser, compile, elaboration, simulation, result, parity, or public capability change |
| `2026-08-01` | `.13.1.1` implementation | private native emitter/validator/contract syntax; exact AHB ExecutionIR/bridge/DUT handoff; deterministic ten-artifact graph; exact methodology/library state; typed context/component/interface/fixture/top sources; complete line/column source map; structural positive/negative oracles; checked gallery; capability/support truth; atomic publication/collision/cleanup; focused and broader VIAL/support/docs/task/mdBook/Knowledge Map/Memory/staged-doctrine gates | `passed`; three new Perl modules and t1560 report syntax OK; focused native/capability/support Files=3/Tests=7,095 and guarded impacted VIAL/support Files=16/Tests=7,215 pass; docs/history Files=16/Tests=128 pass; task integrity is three trees/907 nodes/one segment/one index archive; all 49 mdBook chapters test and the repository-local 85-file/16,688,654-byte build passes before exact removal; all 22 live surfaces and 2,941/2,941 declared paths pass with exact maintained-reference delta 0/+41/+1,903 and zero ceiling increases; Knowledge Map is current at 1,104 facts/5,615 questions/5,781 occurrences/117 shards; Memory is 47 lines; manual review remains pending and every parser/compile/elaboration/runtime/result/parity/breadth non-claim remains exact |
| `2026-08-01` | `.13.1.2` activation | clean `254806049` predecessor; task/index/fact/Memory continuity; task integrity; Knowledge Map; relative paths; memory; live-document containment; diff; staged docs-only acceptance; doctrines | `passed pre-stage checks`; `.13.1.2` alone active; task integrity remains three trees/907 nodes/one segment/one index archive; Knowledge Map is current at 1,104 facts/5,619 questions/5,785 occurrences/117 shards; relative paths report `All tests successful` at Files=1/Tests=2; Memory remains below its warning boundary; all 22 live-document surfaces and 2,941/2,941 paths pass with zero maintained-reference changes and zero ceiling increases; implementation and product behavior remain unchanged |
| `2026-08-01` | `.13.1.2` implementation | emitter/static-validator/support/test syntax; revision-2 exact graph; complete passive topology and lifecycle; typed notification/interception order/filter/effect/cancellation/reentrancy; 42-entry source map; six-source gallery; support/capability truth; focused/broader VIAL runtime and structural regressions; docs/task/mdBook/Knowledge Map/Memory/staged-doctrine gates | `passed`; guarded non-runtime VIAL/support suite reports `All tests successful` at Files=15/Tests=7,158; separately captured exact Verilator integration and parity gates pass at Files=1/Tests=5 and Files=1/Tests=4 after one interrupted guard run's exact 30-MiB operation staging residue was identified, removed, and proven absent; docs/task/live/reference/Knowledge Map suite passes at Files=11/Tests=393; all 49 mdBook chapters test and its repository-local 85-file/16,727,608-byte build passes before exact removal; task integrity remains three trees/907 nodes/one segment/one index archive; live containment accepts all 22 surfaces/2,941 paths and exact mdBook aggregate delta 0/+52/+2,400 with zero ceiling increases; Knowledge Map is current at 1,104 facts/5,624 questions/5,790 occurrences/117 shards; Memory is 47 lines; final staged acceptance and all nine doctrine checks pass before commit |
| `2026-08-01` | `.13.3` semantic-introspection clarification | exact NEXSIM API/MCP qualification-plane requirements; canonical audit/task/index/book/fact/Memory continuity; relative paths/task/live-reference/Knowledge Map; mdBook test/build; diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; docs/live/task/Knowledge Map suite reports `All tests successful` at Files=6/Tests=62; all 49 mdBook chapters test and the corrected repository-local build contains 85 files/16,737,521 bytes before exact removal; an initial incorrectly prefixed destination was rejected before creation and proven absent; task integrity remains three trees/907 nodes/one segment/one index archive; all nine staged doctrines pass; exact mdBook delta is 0/+32/+1,929 with zero ceiling increases; Knowledge Map is current at 1,104 facts/5,627 questions/5,793 occurrences/117 shards; Memory is 47 lines; no NEXSIM/PGEN release, API/schema/protocol version, implementation, runtime, result, parity, or product capability is claimed |
| `2026-08-01` | `.13.1.3` activation | clean cross-tree predecessor `ddfa980a1`; task/index/audit/book/fact/Memory continuity; relative paths/task/live-reference/Knowledge Map; mdBook test/build; diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; docs/live/task/Knowledge Map suite reports `All tests successful` at Files=6/Tests=62; all 49 mdBook chapters test and the repository-local build contains 85 files/16,738,855 bytes before exact removal; task integrity remains three trees/907 nodes/one segment/one index archive; exact mdBook delta is 0/+4/+209; Knowledge Map remains 1,104 facts/5,627 questions/5,793 occurrences/117 shards; Memory is 45 lines; all nine staged doctrines pass with zero ceiling increases; implementation, generated artifacts, public capability, parser, compile, elaboration, runtime, result, and parity remain unchanged |

## Acceptance Checklist (enforced) — `.13.1.3` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.3' --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies selection commit `67778a49d`, while `git show ddfa980a1:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` records `.13.1.2` done and `.13.1.3` proposed with verification pending after `.13.1.2`. The clean predecessor therefore leaves exactly the selected stimulus/TLM/factory/configuration/RAL/constrained-decision leaf ready for a continuity-only activation before any implementation.
- [x] **ADDRESSED (verified)** — Only durable ownership/continuity surfaces now mark `.13.1.3` active: its task node, current-frontier narrative, index, canonical audit, mdBook status paragraph, fact card/Knowledge Map, bounded Memory, and exact maintained-reference authority. The implementation acceptance and non-claims are unchanged. The exact mdBook transition is `50/47,893/2,537,897 -> 50/47,897/2,538,106`, or `0/+4/+209`.
- [x] **NO REGRESSION** — The focused docs/live/task/Knowledge Map suite reports `All tests successful` at `Files=6, Tests=62`; all 49 mdBook chapters test and the repository-local build contains 85 files/16,738,855 bytes before exact removal. Task integrity remains three trees/907 nodes/one segment/one index archive; Knowledge Map is current at 1,104 facts/5,627 questions/5,793 occurrences/117 shards; Memory is 45 lines; final staged doctrines pass with zero ceiling increases; the build destination is absent. No emitter, artifact, gallery, public capability, parser, compile, elaboration, runtime, result, or parity behavior changes.

## Acceptance Checklist (enforced) — `.13.3` NEXSIM API/MCP clarification

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'NEXSIM will expose deep semantic introspection' --oneline --all -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` returns no commit. Existing `.13.3` named only PGEN/NEXSIM versions, handoff, commands,
  and final runtime gates; it did not own the director-confirmed deep semantic
  API/MCP plane, its trust boundary, or first-divergence use.
- [x] **ADDRESSED (verified)** — Proposed `.13.3`, the canonical audit, task
  index, mdBook, fact card/Knowledge Map, and bounded Memory now require exact
  API/MCP schemas, stable source-mapped semantic identities, snapshot-
  consistent bounded deterministic queries, separate authorized controls,
  supported HDL/UVM object domains, checkpoint correlation, first-divergence
  localization, and an explicit provider-evidence rather than VIAL-authority
  boundary. The exact maintained-reference change is `0/+32/+1,929`.
- [x] **NO REGRESSION** — The focused docs/live/task/Knowledge Map suite
  reports `All tests successful` at `Files=6, Tests=62`; all 49 mdBook chapters
  test and the corrected repository-local build contains 85 files/16,737,521
  bytes before exact removal. Task integrity remains three trees/907 nodes/one
  segment/one index archive; Knowledge Map is current at 1,104 facts/5,627
  questions/5,793 occurrences/117 shards; Memory is 47 lines; all nine staged
  doctrines pass with zero ceiling increases. The rejected off-route build
  destination and the exact successful build destination are both absent.
  `.13.3` remains proposed/release-blocked, with no invented provider identity,
  implementation, runtime, result, parity, or product-capability claim.

## Acceptance Checklist (enforced) — `.13.1.2` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation commit
  `d3f05e3f2`, `git log -S'package
  base_output_arbitration_notifications_pkg;' --oneline --
  perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm` returns no commit. The
  revision-1 backend emitted only configuration/environment/test foundations;
  it had no agent context owner, monitor/controller/result-collector topology,
  lifecycle-state machine, notification package, typed event callback,
  interceptor ordering/filter/effect/cancellation record, or bounded
  reentrancy implementation. The initial revision-2 focused run then reported
  `VIAL_UVM_STATIC_BALANCE_ERROR` at the generated fixture package: the
  validator counted `endfunction` but its opening-token expression omitted
  legal `protected function` declarations. This identified the exact
  validator locus rather than an unavailable simulator or UVM-library defect.
- [x] **ADDRESSED (verified)** — `prove -Iperl
  t/1560-vial-native-uvm-emitter-substrate.t
  t/1570-vial-native-uvm-topology-lifecycle-notification.t` reports `All tests
  successful` at `Files=2, Tests=15`. Box-scoped evidence: emitter revision 2
  produces the exact 11-artifact/7-source graph and 42-entry source map; all ten
  structural checks pass; the six-source gallery is byte-identical; and exact
  negative mutations reject missing notification roles/pre-trigger/bounds,
  active-agent residue, duplicate objection ownership, and phase jumps. The
  protected-function counter accepts generated access qualifiers, the agent
  owns its retrieved execution context, and support/capability records expose
  only selected topology/lifecycle/notification/reentrancy emission while
  retaining every syntax/runtime/breadth non-claim.
- [x] **NO REGRESSION** — The five changed Perl/support modules and three
  changed/new tests report `syntax OK`. The RAM-guarded non-runtime VIAL/support
  suite reports `All tests successful` at `Files=15, Tests=7158`; separately
  captured exact Verilator runtime and AHB parity gates report `All tests
  successful` at `Files=1, Tests=5` and `Files=1, Tests=4`. The first combined
  guard run ended during compilation and left one exact 30-MiB operation-owned
  staging tree; process census proved it unused, exact cleanup removed it, the
  two gates then passed, and the staging census is empty. Final documentation,
  mdBook, Knowledge Map, Memory, staged acceptance, and `[doctrine] all
  doctrine checks passed` evidence is appended here before commit. The
  documentation/task/live/reference/Knowledge Map suite reports `All tests
  successful` at `Files=11, Tests=393`; all 49 mdBook chapters test and its
  repository-local 85-file/16,727,608-byte build passes before exact removal.
  Task integrity remains three trees/907 nodes/one segment/one index archive;
  live containment accepts all 22 surfaces/2,941 paths and the exact mdBook
  delta `0/+52/+2,400` with zero ceiling increases; `knowledge-map: OK` reports
  1,104 facts/5,624 questions/5,790 occurrences/117 shards; Memory is 47 lines.
  Parse, UVM library/fixture compile, elaboration, native runtime/result/parity,
  public interceptor authoring, and complete UVM breadth remain unclaimed.

## Acceptance Checklist (enforced) — `.13.1.1` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation predecessor
  `d04c84dd6`, `git log -S
  'package FSM::VIAL::Backend::SVUVMAccellera2020_3_1' --all --oneline --
  perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm` returns no commit and the
  selected backend, validator, native capability contract, artifact graph, and
  review-gallery paths are absent. The exact defect is therefore the
  unimplemented `.13.1.1` emission substrate, not a failure in the shipped
  portable Verilator backend or an unavailable UVM simulator. During commit
  recovery, `git check-ignore -v vial/review_gallery/*/*/*.sv` also identified
  the repository-wide `.gitignore:5:*.sv` rule as the exact reason the first
  commit attempt retained the gallery README but omitted its five snapshots.
- [x] **ADDRESSED (verified)** — `prove -Iperl
  t/1560-vial-native-uvm-emitter-substrate.t
  t/297-capability-manifest.t t/248-regression-corpus-accounting.t` reports
  `All tests successful` at `Files=3, Tests=7095`. Box-scoped evidence: t1560
  proves exact Accellera identity without library access, ten deterministic
  artifacts, 26 complete line/column source-map entries, typed context/
  component/interface/fixture/top shapes, byte-identical gallery snapshots,
  structural-only positive and missing-role/provider/balance/profile/digest
  negatives, honest per-stage states, identical rerender, atomic same-volume
  publication, collision rejection, and exact cleanup. The five intentional
  generated snapshots are force-tracked at their exact gallery paths, and
  `git ls-files vial/review_gallery` enumerates the README plus all five.
- [x] **NO REGRESSION** — The three new Perl modules and focused test report
  `syntax OK`; the focused native/capability/support suite reports `All tests
  successful` at `Files=3, Tests=7095`; the guarded impacted VIAL/support suite
  reports `Files=16, Tests=7215`; and the documentation/history suite reports
  `Files=16, Tests=128`. All 49 mdBook chapters test, its repository-local
  85-file/16,688,654-byte build passes before exact removal, task integrity and
  Knowledge Map checks pass, Memory is 47 lines, and all 22 live surfaces plus
  2,941/2,941 declared paths pass. Public `fsmgen vial run`, portable AHB
  runtime/parity, HIAL generation, and legacy UVM 1.2 behavior remain
  unchanged; SystemVerilog parse, UVM compile, elaboration, simulation,
  runtime result, parity, and complete native-UVM breadth remain unclaimed.

## Acceptance Checklist (enforced) — `.12` selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12-NATIVE-UVM-CONTRACT-ACTIVATION' --oneline -- doctrine/live_document_size/surfaces.jsonl` identifies clean activation commit `6740bfaa1`, whose authority covers only the six-line frontier update. Selection necessarily adds exact user-facing methodology/profile semantics, while the director's clarifications reject a commercial-simulator dependency and require canonical UVM to remain simulator-neutral; the active contract therefore needed a new exact maintained-reference authority and an architecture decision rather than an invented Xcelium or unavailable PGEN+NEXSIM runtime profile.
- [x] **ADDRESSED (verified)** — Decision `0050`, the canonical audit, task tree, roadmap, fact card, and mdBook now select exact Accellera UVM 2020-3.1 tag `2020.3.1` / commit `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`; require simulator-neutral generated UVM; isolate provider adapters/commands/evidence; decompose full-shaped reviewable emission into `.13.1.1`–`.13.1.5` without a simulator gate; start reusable exact open-tool compile/elaboration probes at the first gallery in `.13.2`; reserve `.13.3` for future PGEN+NEXSIM qualification; permit meaning-preserving generated syntax/strategy iteration under exact emitter identity; preserve inert UVM 1.2 unchanged; and make every implementation/runtime claim explicitly absent. Maintained-reference verification accepts the exact mdBook change 50/47,550/2,521,265 → 50/47,740/2,530,034, or delta 0/+190/+8,769.
- [x] **NO REGRESSION** — The guarded relative-path/reference/Knowledge Map suite reports `All tests successful` at `Files=4, Tests=13`; all 49 mdBook chapters test and the verified repository-local build has 85 files / 16,674,248 bytes before exact removal. Task integrity is three trees / 907 nodes / one segment / one index archive; all 22 live-document surfaces and 2,938/2,938 declared paths pass with zero ceiling increases; `knowledge-map: OK` reports 1,104 facts / 5,593 unique questions / 5,759 answer occurrences; Memory is 46 lines; and final staged `scripts/check_doctrines.sh` reports `[doctrine] all doctrine checks passed` without native implementation or product-behavior change.

## Acceptance Checklist (enforced) — `.12` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'sv_uvm_qualified' --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/decisions/0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md docs/book/src/16d-hial-vial-verification-architecture.md` identifies `2e2f7d25e HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1: select one-source dual-IR architecture`. Completed `.11` exhausts the portable handwritten-oracle parity frontier, while proposed `.12` is the next dependency-closed child and decision `0032` requires the native UVM revision/profile to be selected independently.
- [x] **ADDRESSED (verified)** — clean predecessor `ea1b76dd54` changes `.12` from proposed to active and updates only task/index/book/fact/Memory continuity plus the book's exact aggregate-change authority. `command -v` finds `/opt/homebrew/bin/verilator` and `/opt/homebrew/bin/iverilog` but no `vcs`, `xrun`, `qrun`, `vsim`, `questa`, or `irun`; the active selection must preserve this evidence boundary. The maintained-reference checker accepts the exact book before→after change at 50/47,544/2,520,904 → 50/47,550/2,521,265. No UVM revision/profile/backend/artifact/capability/runtime or product behavior is selected by activation.
- [x] **NO REGRESSION** — relative-path verification reports `All tests successful` at `Files=1, Tests=2`; task integrity remains three trees / 899 nodes / one segment / one index archive, and all 49 mdBook chapters test before the repository-local 85-file / 16,600,519-byte build is removed exactly. Knowledge Map remains 1,104 facts / 5,585 questions, Memory is 46 lines, maintained-reference authority accepts two references / one changed, ceiling authority reports zero increases, and `scripts/check_doctrines.sh` reports `[doctrine] all doctrine checks passed` with no backend or product-behavior change.

## Acceptance Checklist (enforced) — `.3` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation commit `4ab91cc15`,
  `perl -Iperl -e 'require FSM::VIAL::Parser'` reports `Can't locate
  FSM/VIAL/Parser.pm ... at -e line 1.` The selected source/parser/SemanticIR/
  report surface therefore has an exact absent implementation locus rather
  than an ambiguous defect in an existing parser.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1550-vial-semantic-ir.t
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t` passes at
  `Files=3, Tests=7055`. Box-scoped evidence: t1550 loads the checked 4,986-byte
  AHB source through the dedicated parser and builder, checks immutable typed
  intent, stable spans/order, authored-order diagnostic aggregation with
  dependent-cascade suppression, symmetric contextual inference, exact
  resource limits, defensive reports, capabilities, and all explicit
  bridge/plan/output/runtime non-claims.
- [x] **NO REGRESSION** — All four `perl -Iperl -c perl/FSM/VIAL/*.pm` checks
  pass; nine adjacent support/runtime/defensive-copy audits pass at
  `Files=9, Tests=32`; the task/docs/path/mdBook/Knowledge Map/staged-doctrine
  gates pass and repository-local outputs are removed exactly. Box-scoped
  broader-gate evidence: t261's stale unary-expression shapes and t296's PPIF
  pipeline-versus-CLI top-name oracle reproduce outside VIAL and are owned by
  proposed `SUPPORTED-LANGUAGE-FEATURE-RHS-SIMPLIFICATION-EXPECTATION-SYNC`
  and `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT`; this slice changes no
  implicated generator or PPIF source and makes no broad-suite pass claim.

## Acceptance Checklist (enforced) — `.5` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — After activation commit `1928fe238`,
  `git log -S 'package FSM::HIAL::VIALBridge::Builder' --all --
  perl/FSM/HIAL/VIALBridge/Builder.pm` returns no commit and the selected
  package path does not exist. The exact defect is therefore the absent
  review-routed bridge producer and annotation path selected by `.4`, not an
  ambiguity in an existing bridge implementation.
- [x] **ADDRESSED (verified)** — `prove -Iperl
  t/1551-hial-vial-bridge-manifest.t
  t/1475-ial2-ahb-subordinate.t
  t/1260-isf-verification-observation-metadata.t
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t
  t/1112-isf-public-interface-contract.t` passes at `Files=6, Tests=7058`.
  Box-scoped evidence: t1551 exercises every canonical route and selected
  record family; exact source-map coverage, route and PPIF-bypass rejection,
  checked VIAL reference resolution, defensive ownership, exact fixed-limit
  discovery with endpoint-limit enforcement,
  malformed annotations/access/capabilities, deterministic review artifacts,
  preserved HIAL output hashes, and exact private support/non-claims.
- [x] **NO REGRESSION** — Every changed Perl module compiles; generated IAL0
  remains byte-identical and direct HIAL SystemVerilog/VHDL preservation hashes
  pass in t1551. Ten existing annotation/schema audit files pass at `Files=10,
  Tests=10`. A guarded wider AHB batch was stopped by the repository RAM guard
  at 88.1% host use before completing, with no test failure; this slice makes
  the bounded focused and adjacent pass claim above, not an uncompleted broad-
  suite claim. Twenty-eight adjacent capability/support/accounting contract,
  runtime, round-trip, and defensive-copy files pass at `Files=28, Tests=56`;
  that includes the t359 projection gap caused and repaired by this slice.
  Independently stale t370 verification-output discovery
  keys reproduce unchanged at HEAD and are parked under proposed
  `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC`, without
  widening this dirty slice. The task-tree doctrine regression no longer
  hard-codes the pre-HIAL single-active-tree count; it still requires positive
  measured tree/node counts and retains all exact fixture/negative checks.
  Task-tree integrity passes at trees=2/nodes=865; docs pass at Files=4/
  Tests=51; all 37 mdBook chapters and the 73-file/16,965,845-byte build pass;
  Knowledge Map passes at 1,089 facts/5,643 keys; output cleanup is exact.
  Staged acceptance and all eight doctrine gates pass before commit.

## Acceptance Checklist (enforced) — `.7.3` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation commit `97628dc15`,
  `git log -S 'package FSM::VIAL::ExecutionBuilder' --all --
  perl/FSM/VIAL/ExecutionBuilder.pm` returns no commit, and
  `test -e perl/FSM/VIAL/ExecutionBuilder.pm` exits 1. The selected private
  binder/ExecutionIR/random-replay/plan owner is therefore absent at its exact
  contracted package locus; the shipped SemanticIR and bridge objects expose
  only defensive semantic/manifest data and no binding method. The adjacent
  `t/350-support-contract-builder-audit.t` also proves that the already-shipped
  private bridge contract introduced a status outside the generic contract
  audit's closed vocabulary and omitted its mandatory non-empty `guidance`;
  the new private execution contract would otherwise repeat that integration
  defect. Final contract review additionally found that the phase table assigns
  first result production to `.10` and parity comparison to `.11`, while two
  `.7` oracle bullets and the initial capability list incorrectly implied those
  later capabilities were already implemented. Direct `rg -n
  'result-schema builders|malformed .*result/parity|first runtime \.10|runtime
  parity \.11' docs/VIAL_EXECUTION_IR_V1_CONTRACT.md` located the contradictory
  ownership claims; `.7.3` must publish selected future schemas without
  classifying them as shipped capabilities.
- [x] **ADDRESSED (verified)** — `prove -Iperl
  t/1550-vial-semantic-ir.t t/1551-hial-vial-bridge-manifest.t
  t/1552-vial-execution-ir.t t/248-regression-corpus-accounting.t
  t/297-capability-manifest.t t/350-support-contract-builder-audit.t
  t/369-manifest-section-builder-audit.t
  t/381-contract-tested-by-provenance-audit.t
  t/382-contract-module-provenance-audit.t
  t/383-contract-family-map-integrity-audit.t` reports `All tests successful`
  at `Files=10, Tests=7135`. Box-scoped evidence: t1552 proves the exact
  checked AHB binding, all ten directional proofs, 21-operation/four-fiber
  deterministic graph, normalized event adapters, arbitrary-width random
  vectors, strict replay, defensive ownership, exact resource limits, atomic
  diagnostics, private discovery, and future result/parity ownership without
  a satisfied runtime capability.
- [x] **NO REGRESSION** — Nine changed Perl modules report `syntax OK`.
  Broader adjacent semantic/bridge/capability/support/accounting/provenance
  evidence reports `All tests successful` at `Files=10, Tests=7135`.
  Documentation truth reports `All tests successful` at `Files=4, Tests=609`;
  relative paths pass at `Files=1, Tests=2`; all 37 mdBook chapters test and
  the 73-file/17,058,063-byte local build passes. Task integrity is
  trees=2/nodes=868, `knowledge-map: OK` holds at 1,092 facts/5,674 keys,
  Memory is 56 lines, and generated book output is removed exactly.
  Independently stale t370 `verification_outputs` presence-map drift
  reproduces outside this file set and remains owned by proposed
  `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC.1`; this slice
  changes no implicated verification-output contract and makes no t370 pass
  claim. Staged acceptance and `[doctrine] all doctrine checks passed` close
  the commit gate.

## Acceptance Checklist (enforced) — `.10.1` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean decomposition predecessor
  `cf799df07`, `git log -S 'FSM::VIAL::ToolCLI' -- bin/fsmgen` returns no
  commit. `git show cf799df07:bin/fsmgen | rg -n
  'GetOptions|FSM::VIAL::ToolCLI|Subcommands'` finds only the legacy
  `GetOptions` front door and no VIAL dispatch. The selected public source-tool
  command/API, terse normalizer/formatter, and exact discovery/support owner
  were therefore absent at their contracted loci; this was not a defect in the
  already-shipped private semantic builder.
- [x] **ADDRESSED (verified)** — The guarded `prove -Iperl
  t/1550-vial-semantic-ir.t t/1551-hial-vial-bridge-manifest.t
  t/1552-vial-execution-ir.t t/1555-vial-public-source-tooling.t
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t` reports
  `All tests successful` at `Files=6, Tests=7083`. Box-scoped evidence: t1555
  proves deterministic normal/terse formatting, equal semantic digests,
  idempotent round trips, caller-owned imports, exact defensive request/result
  data, CLI/API parity, legacy dispatch, unsafe-path and incompatible-option
  rejection, stable diagnostics, exact capability/support accounting, and no
  HIAL binding, plan, artifact, backend, or runtime.
- [x] **NO REGRESSION** — Every changed/new Perl module and test reports
  `syntax OK`; the guarded semantic/bridge/execution/source-tool/support/
  capability regression reports `All tests successful` at `Files=6,
  Tests=7083`. The first default-88% guarded attempt stopped cleanly after
  t1550 passed when the known conservative macOS metric reached 88.1%; the
  established rerun retained the 4096 MiB descendant limit and completed at a
  100% host threshold. Documentation/live/path/task gates report `All tests
  successful` at `Files=11, Tests=106`; README remains below its predecessor
  line/byte baseline; all 37 mdBook chapters test and the 73-file/16,900-KiB
  repository-local build passes then is removed exactly. Task integrity is
  trees=3/nodes=889, Knowledge Map is current at 1,096 facts/5,735 keys, and
  Memory is 37 lines. `[doctrine] all doctrine checks passed` holds for all
  nine checks, 20 live-document surfaces, and 2,780/2,780 tracked Markdown
  paths.

## Acceptance Checklist (enforced) — `.10.2` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation predecessor
  `07b7622cc`, both `git log -S 'package FSM::VIAL::PlanBuilder' --
  perl/FSM/VIAL/PlanBuilder.pm` and `git log -S 'package
  FSM::VIAL::ArtifactTransaction' -- perl/FSM/VIAL/ArtifactTransaction.pm`
  return no commit, while the predecessor `FSM::VIAL::Tool` returns `action
  'plan' is not available in the public source-tooling slice`. Implementation
  then exposed a second exact contract locus: `SemanticBuilder` required at
  least one transaction binding while the selected direct-IAL0 bridge
  deliberately emits none, making every advertised direct-IAL0 plan
  structurally impossible rather than merely unsupported by one fixture.
- [x] **ADDRESSED (verified)** — The guarded semantic/bridge/execution/tool/
  source-frontend/support/capability regression reports `All tests successful`
  at `Files=11, Tests=7108`. It locks all three canonical HIAL review routes,
  a positive transaction-free direct-IAL0 endpoint/reset plan, checked IAL1
  and IAL2 AHB plans, deterministic defensive public graphs, exact hashes and
  support truth, virtual publication, atomic filesystem publication and
  unchanged replay, plus fail-closed transaction-dependent direct IAL0,
  unsafe-root, collision, symlink, traversal, malformed-option, and unavailable
  runtime cases without partial artifacts.
- [x] **NO REGRESSION** — All changed/new Perl modules and tests report `syntax
  OK`; the guarded broader VIAL/support/frontend suite reports `All tests
  successful` at `Files=11, Tests=7108`, and the documentation/live/path/task
  set reports `All tests successful` at `Files=6, Tests=357`. All 37 mdBook
  chapters test; its repository-local 73-file/16,916-KiB build succeeds and is
  removed exactly. `knowledge-map: OK` holds at 1,096 facts/5,736 keys;
  README is 245 lines/9,913 bytes, below its zero-growth transition baseline;
  Memory is 39 lines; and `[doctrine] all doctrine checks passed` covers all
  nine checks, 20 live-document surfaces, and 2,780/2,780 tracked Markdown
  paths. No VIAL backend, compile, simulation, result, parity, UVM, VHDL,
  mixed-language, or scale claim ships, and the exact `.artifacts` staging,
  `.bin`, and `.log` census is empty.

## Acceptance Checklist (enforced) — `.10.3` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation predecessor
  `2c374299a`, both `git log -S 'package
  FSM::VIAL::Backend::SVPortableVerilator' --
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm` and `git log -S 'package
  FSM::VIAL::Backend::TraceValidator' --
  perl/FSM/VIAL/Backend/TraceValidator.pm` return no commit. The predecessor
  planner also discarded its private immutable ExecutionIR after creating the
  public projection, so the selected backend had neither an executable
  compiler handoff nor its contracted emission/trace-validation owners.
- [x] **ADDRESSED (verified)** — Focused t1557 and the guarded impacted
  semantic/bridge/execution/source-tool/planner/backend/support/capability/
  language-surface suite report `All tests successful` at `Files=27,
  Tests=7190`. Evidence locks exact defensive compiler inputs, date-normalized
  generated DUT text, a byte-deterministic sorted eight-artifact graph, all 21
  operation mappings plus every stateful family, generated declared-probe
  aliases, one inactive-edge scheduler with no target `fork` authority,
  fail-closed negotiation/invocation/limits, closed trace order/count/identity
  validation, and honest not-run/not-produced/not-evaluated stage accounting.
- [x] **NO REGRESSION** — All 13 changed/new Perl modules and test programs
  report `syntax OK`; the guarded impacted regression reports `All tests
  successful` at `Files=27, Tests=7190`, and documentation/live/path/task
  checks report `All tests successful` at `Files=8, Tests=378`. All 37 mdBook
  chapters test and the repository-local 73-file/16,952-KiB build passes before
  exact removal. `knowledge-map: OK`, bounded Memory, README zero growth,
  staged task acceptance, and `[doctrine] all doctrine checks passed` close
  the final gates. The known t296 PPIF expected-top drift reproduces under
  `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT` and touches no changed VIAL,
  support-contract, or language-surface expectation here. No external compile,
  simulation, runtime capture, normalized result, parity, public run, UVM,
  VHDL, mixed-language, or scale claim ships.

## Acceptance Checklist (enforced) — `.10.4` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation predecessor
  `8ba4278d8`, `git log -S 'package FSM::VIAL::Backend::Runner' --
  perl/FSM/VIAL/Backend/Runner.pm` and the equivalent ResultProducer pickaxe
  return no commit. The public parser named `run`, but the request validator
  rejected it and no owner could materialize emitted sources, invoke the exact
  selected tool, capture a trace, produce a result, or publish an executed
  graph. Direct generated-runtime probes then exposed concrete lowering defects
  at the final AHB ready barrier and at raw-integer SV string concatenation.
- [x] **ADDRESSED (verified)** — `t/1558-vial-verilator-run-integration.t`
  executes the exact Verilator 5.046 profile through public API and CLI. Both
  selected scenarios pass; all ten semantic streams are nonempty; the observed
  scoreboard depth is one; the result is content-addressed and byte-sized;
  the 19-artifact API graph repeats byte-identically; filesystem replay returns
  `unchanged`; a same-barrier `parallel any` tie selects the first authored
  child and cancels its sibling; wrong backends/nonempty sinks fail atomically;
  and both execution and publication staging identities are absent after
  return. Runner validates
  complete command digests/argv, bounds process/output resources, and performs
  bounded process-group termination before cleanup.
- [x] **NO REGRESSION** — All 19 changed/new Perl modules and test programs
  report `syntax OK`; the guarded semantic/bridge/execution/tool/backend/
  support/capability suite reports `All tests successful` at `Files=10,
  Tests=7170`; documentation/live/path checks report `All tests successful` at
  `Files=5, Tests=323`; and task integrity remains three trees/889 nodes/one
  segment/one index archive. All 37 mdBook chapters test and its repository-
  local 73-file/16,964-KiB build passes before exact removal. `knowledge-map:
  OK` holds at 1,096 facts/5,736 keys; Memory is 44 lines; README is 245 lines/
  9,917 bytes; DEVELOPMENT_NOTES is below its zero-growth baseline; final
  staged acceptance/doctrines and residue census close the commit. Complete
  four-state observation, parity, UVM, VHDL methodology, mixed-language
  execution, and scale remain explicit non-claims; legacy HIAL and
  verification-output-v1 behavior is unchanged.

## Acceptance Checklist (enforced) — `.11` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation predecessor
  `04f22f689`, `git log -S 'package FSM::VIAL::Parity::AHBBaseOutput' --
  perl/FSM/VIAL/Parity/AHBBaseOutput.pm` returns no commit, while the
  handwritten harness reports only its two aggregate
  `BASE_ASSERT_SUCCESS`/`BASE_ASSERT_ERROR` records and the generated result
  carries ten richer semantic streams. Comparing every generated stream would
  therefore fabricate baseline evidence; the missing owner is a bounded
  projection comparator over only the facts both executions genuinely expose.
- [x] **ADDRESSED (verified)** — `t/1559-vial-ahb-runtime-parity.t` independently
  compiles and runs the checked handwritten harness and public VIAL path under
  exact Verilator 5.046, proves byte-identical DUT source, compares 19 shared
  public/declared-probe outcome paths across both scenarios, and emits one
  deterministic `fsmgen.vial_parity_report.v1`. It locks two explicit
  undeclared-internal exclusions, a semantic storage mismatch with its source
  identity, and fail-closed malformed, duplicate, nonzero, ineligible, and
  different-DUT evidence. The guarded impacted suite reports `All tests
  successful` at `Files=11, Tests=7183`.
- [x] **NO REGRESSION** — All 15 changed/new Perl modules and test programs
  report `syntax OK`; the guarded impacted suite passes at `Files=11,
  Tests=7183`, and documentation/live/path checks pass at `Files=5, Tests=323`.
  Task integrity remains three trees/889 nodes/one segment/one index archive;
  all 37 mdBook chapters test and the repository-local 73-file/16,976-KiB build
  passes before exact removal. `knowledge-map: OK` holds at 1,096 facts/5,736
  keys; Memory is 47 lines and README remains 245 lines/9,917 bytes. Final
  staged acceptance/doctrines and the repository-local artifact census close
  the commit. General cross-backend parity, complete four-state observation,
  UVM, VHDL methodology, mixed-language execution, and scale remain explicit
  non-claims; HIAL generation and legacy verification-output behavior are
  unchanged.

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE` | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE: park dual-intent architecture` | Park the director-approved architecture requirement without activating it or changing IAL2 priority. |
| `.1` | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1: select one-source dual-IR architecture` | Accept decision `0032`, publish the canonical audit and mdBook chapter, decompose `.2`-.18, and select proposed source/semantic-IR contract `.2` without product changes. |
| `.2` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2: activate source semantic IR contract` | Activate only the documentation-only v1 source/semantic-IR contract after clean `.1`; contract findings remain unperformed. |
| `.2` selection | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2: select spanned VIAL semantic contract` | Accept decision `0033`, freeze the complete v1 source/private-IR/report boundary, and select proposed `.3` implementation without product changes. |
| `.3` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3: activate VIAL semantic implementation` | Activate only bounded parser/SemanticIR implementation after clean `.2`; implementation remains unperformed. |
| `.3` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3: implement VIAL semantic intent` | Ship the bounded semantic-only frontend, one checked source, exact reports/capabilities/support, and focused negative/resource coverage without a bridge, plan, backend, or runtime claim. |
| `.4` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.4: activate HIAL VIAL bridge contract` | Activate only the documentation contract for bridge-manifest selection after clean `.3`; selection remains unperformed. |
| `.4` selection | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.4: select review-routed bridge manifest` | Accept decision `0035`, freeze the exact public-data/private-producer bridge boundary, and select proposed `.5` implementation without product changes. |
| `.5` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5: activate bridge manifest implementation` | Activate only private in-process/no-file bridge implementation after clean `.4`; implementation remains unperformed. |
| `.5` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.5: implement review-routed bridge manifest` | Ship the bounded private bridge through canonical HIAL review routes, with additive IAL1 metadata, exact accounting and fail-closed tests; leave VIAL binding, files, public APIs, backends, and runtime unclaimed. |
| `.6` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.6: activate VIAL execution contract` | Activate only documentation selection of the ExecutionIR/logical-time/native-extension/plan/result/parity contract after clean `.5`; selection and product behavior remain unperformed. |
| `.6` selection | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.6: select deterministic VIAL execution contract` | Accept decision `0036`, freeze the target-neutral operational graph, logical-time/random-replay/native/plan/result/parity contract, and select proposed `.7` without product behavior. |
| `.7` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7: activate VIAL execution implementation` | Activate only private no-backend binder/ExecutionIR/random-replay/plan implementation after clean `.6`; implementation remains unperformed. |
| `.7.1` | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.1: confirm transaction type-binding blocker` | Prove the selected exact-equivalence rule cannot bind three checked AHB transaction fields, correct the historical evidence boundary, and split semantic selection `.7.2` from implementation `.7.3` without product changes. |
| `.7.2` | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.2: select directional type binding` | Accept decision `0037`, freeze the closed proof-carrying relation between VIAL semantic types and HIAL carriers, and select proposed `.7.3` without product changes. |
| `.7.3` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.3: activate bounded VIAL execution implementation` | Activate only the selected private no-backend binder/ExecutionIR/random-replay/plan implementation after clean `.7.2`; implementation remains unperformed. |
| `.7.3` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.7.3: implement private VIAL execution plan` | Ship the private exact-class binder, immutable target-neutral ExecutionIR, deterministic random/replay and defensive no-file plan; retain result/parity as selected future `.10`/`.11` schemas rather than false satisfied capabilities. |
| `.8` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.8: activate public VIAL tooling contract` | Activate only documentation selection of the public CLI/API, terse/verbose projection, repository-local artifact, manifest/report, capability/diagnostic/support, and compatibility contract after clean `.7.3`; product behavior remains unchanged. |
| `.8` selection | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.8: select public VIAL tooling contract` | Accept decision `0039`, freeze the public source/CLI/API/artifact/report/discovery/compatibility boundary, and select proposed `.9` without product changes. |
| `.9` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9: activate portable SV backend contract` | Activate only documentation selection of the plain-SystemVerilog/Verilator backend and runtime-library contract after clean `.8`; selection and product behavior remain unperformed. |
| `.9` selection | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9: select portable SV backend contract` | Accept decision `0043`, freeze the exact deterministic known-value plain-SV/Verilator backend contract, and select proposed `.10` without product behavior. |
| `.10` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10: activate portable SV backend implementation` | Activate only the selected public-tool/plain-SV/Verilator/result implementation after clean `.9`; implementation remains unperformed. |
| `.10` decomposition | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10: decompose portable SV implementation` | Split the active parent into independently accepted source-tool, planning/artifact, backend/trace, and runtime/result children; activate `.10.1` alone without product behavior. |
| `.10.1` | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.1: ship public VIAL source tooling` | Ship capabilities/check/canonical normal-terse formatting through a defensive source-only CLI/API, with exact discovery/support and no HIAL binding, artifacts, backend, or runtime. |
| `.10.2` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.2: activate VIAL planning artifacts` | Activate only canonical HIAL review routing, public plan projection, and atomic repository-local/virtual artifact transactions after clean `.10.1`; implementation remains unperformed. |
| `.10.2` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.2: ship VIAL planning artifacts` | Ship all three canonical HIAL plan routes, defensive bridge/plan/tool-manifest graphs, transaction-free direct-IAL0 endpoint planning, and virtual or atomic repository-local publication without a backend/runtime claim. |
| `.10.3` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.3: activate portable SV backend emission` | Activate only deterministic portable-SystemVerilog artifact emission and closed trace projection after clean `.10.2`; implementation remains unperformed. |
| `.10.3` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.3: ship portable SV backend emission` | Ship private deterministic plain-SV emission, complete source maps, one-scheduler known-value lowering, honest non-executed tool records, and pure closed-trace projection without public run/compile/runtime/result/parity claims. |
| `.10.4` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.4: activate Verilator run integration` | Activate only public backend publication, exact Verilator compile/run, trace capture, and normalized result integration after clean `.10.3`; implementation remains unperformed. |
| `.10.4` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.4: ship Verilator run results` | Ship public run, exact bounded Verilator execution, validated traces, normalized results, deterministic virtual/filesystem publication, cleanup, and exact capability/support truth without parity. |
| `.11` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11: activate portable AHB result parity` | Activate only normalized comparison of the shipped generated result with the handwritten AHB oracle after clean `.10.4`; implementation and parity claims remain unperformed. |
| `.11` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11: prove portable AHB result parity` | Ship the private closed AHB oracle comparator, independently execute both harnesses over byte-identical DUT source, compare 19 shared outcomes, exclude undeclared internals, and retain every broader parity/methodology non-claim. |
| `.12` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12: activate native UVM contract selection` | Activate only selection of the native SystemVerilog/UVM revision, intent mapping, existing-skeleton migration, and exact qualified profile after clean `.13` containment completion; implementation and qualification remain unperformed. |
| `.12` selection | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12: select open-source native UVM architecture` | Accept decision `0050`; select simulator-neutral Accellera UVM 2020-3.1 emission, optional experimental evidence, and future exact PGEN+NEXSIM runtime qualification without requiring a commercial simulator or claiming implementation. |
| `.13.1.1` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.1: activate native UVM emitter substrate` | Activate only the selected simulator-neutral emitter foundation, static validators, deterministic atomic artifact graph, and first review gallery after a clean predecessor; implementation remains unperformed. |
| `.13.1.1` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.1: ship native UVM emitter foundation` | Ship the private exact-Accellera native emitter foundation, structural validator, discoverable emission-only contract, ten-artifact deterministic graph, complete source map, first byte-checked review gallery, atomic publication, and exact non-claims. |
| `.13.1.2` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.2: activate complete native UVM structures` | Activate only complete selected component topology, timed interfaces, lifecycle control, and notification/interception emission after a clean predecessor; implementation remains unperformed. |
| `.13.1.2` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.2: ship complete native UVM structures` | Ship complete selected passive topology, strict root-owned lifecycle/logical time, ordered typed notification/interception with bounded queue-or-reject reentrancy, expanded static negative oracles, exact source maps, six-source review gallery, and honest compile/runtime/public-authoring boundaries. |
| `.13.1.3` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.3: activate native UVM stimulus and services` | Activate only representative stimulus/TLM/factory/configuration/RAL/constrained-decision emission after clean completed `.13.1.2`; implementation remains unperformed. |
| `.13.3` provider clarification | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.3: capture NEXSIM semantic-introspection MCP contract` | Record the future versioned NEXSIM semantic API/MCP qualification plane, snapshot/control/query requirements, source-mapped checkpoint correlation, first-divergence localization, and provider-evidence boundary without inventing a release or activating runtime work. |

## Changelog

- `2026-08-01`: Clean cross-tree predecessor `ddfa980a1` activates `.13.1.3`
  alone for representative stimulus/TLM/factory/configuration/RAL/constrained-
  decision emission. Activation changes continuity only; implementation,
  generated artifacts, public capabilities, and every parser-through-parity
  claim remain unchanged.

- `2026-08-01`: `.13.3` now records the director's NEXSIM deep-semantic-
  introspection API/MCP direction. Future qualification selects exact API and
  protocol schemas, stable semantic identities, snapshot-consistent bounded
  queries, explicit inspection/control permissions, source-map correlation,
  and first-divergence localization against applicable IASIM or portable
  checkpoints. NEXSIM remains provider evidence rather than VIAL semantic
  authority; the leaf remains proposed and release-blocked.

- `2026-08-01`: `.13.1.2` expands the simulator-neutral Accellera profile to
  an exact eleven-artifact graph with seven SystemVerilog sources and 42 mapped
  symbols. A shared context now reaches the passive monitor through a typed
  agent base; the generated environment also owns the lifecycle controller and
  result-collector structure, while the root test alone owns one objection
  pair. Six public VIAL event identities receive typed `uvm_event#(T)` channels
  and an exact `uvm_event_callback#(T)` dispatcher with strict compiled
  registration, filters/effects, immutable/effective payload separation,
  cancellation/skipped accounting, and bounded queue-or-reject reentrancy.
  Ten structural checks plus targeted negative mutations and six byte-locked
  gallery sources pass. Interceptor tables remain a private typed preview;
  manual review, parsing, compilation, elaboration, runtime, result, parity,
  and complete native-UVM breadth remain unclaimed. Proposed `.13.1.3` is next.

- `2026-08-01`: Clean predecessor `254806049` activates `.13.1.2` alone for
  complete selected native UVM topology, timed-interface, lifecycle, and
  notification/interception emission. Activation changes continuity only; no
  emitter byte, review artifact, public capability, parser, compile,
  elaboration, runtime, result, or parity behavior changes.

- `2026-08-01`: `.13.1.1` ships the private deterministic
  `sv_uvm_emit.accellera_2020_3_1` foundation. The checked AHB fixture emits
  exact typed logical-time, component-base, timed-interface, fixture, bound-
  top, and deterministic-DUT sources with a complete line/column source map,
  exact methodology profile, structural report, and closed manifest. The five
  UVM-facing files are byte-locked in the first review gallery; atomic
  publication, identical rerender, collision rejection, cleanup, fail-closed
  negative checks, capability discovery, and support accounting pass.
  Ordinary emission fetches or inspects no UVM library bytes. Manual review is
  pending; preprocessing, parse, compile, elaboration, runtime, result, parity,
  complete native-UVM breadth, and a public emitter API remain unclaimed.
  Proposed `.13.1.2` is next for separate clean activation; `.13.2` is now
  dependency-ready but retains separately owned experimental evidence.

- `2026-08-01`: Clean predecessor `6c6b70048` activates `.13.1.1` alone for
  native UVM emitter-substrate implementation. Activation changes only durable
  continuity; no emitter, generated artifact, capability, tool invocation,
  parse, compile, elaboration, simulation, result, or parity behavior ships.

- `2026-08-01`: `.12` accepts decision `0050` and selects simulator-neutral
  IEEE 1800.2-2020 / Accellera UVM 2020-3.1 as the exact native methodology
  source. Deterministic emission, optional experimental open-source evidence,
  and future exact PGEN+NEXSIM runtime qualification are separate children;
  commercial simulators are optional comparisons rather than roadmap gates.
  No native implementation, parse, compile, elaboration, simulation, runtime,
  result, or parity capability ships in this documentation-only selection.
- `2026-08-01`: Clean containment commit `ea1b76dd54` activates `.12` alone
  for native SystemVerilog/UVM contract selection. The local tool census finds
  Verilator and Icarus but no qualified UVM simulator; activation changes only
  continuity and adds no revision, profile, backend, artifact, capability,
  runtime, parity, HIAL, or product-behavior claim.
- `2026-07-31`: `.11` ships bounded AHB handwritten-oracle parity over 19
  normalized shared paths, exact same-DUT identity, deterministic reports,
  explicit undeclared-internal exclusions, semantic mismatch evidence, and
  fail-closed malformed/ineligible gates. General cross-backend parity remains
  unclaimed.
- `2026-07-31`: Clean `.10.4` implementation commit `dfe87f536` activates
  `.11` alone for normalized parity against the handwritten AHB oracle. This
  continuity transition changes no implementation, public capability/support
  claim, HIAL behavior, or product behavior.
- `2026-07-31`: `.10.4` ships public `run`, exact Verilator 5.046
  compile/runtime, closed trace/result/output artifacts, deterministic API/CLI
  reruns, atomic repository-local publication, and exact cleanup. `.11` remains
  proposed for a separate clean parity activation.
- `2026-07-31`: Clean `.10.3` implementation commit `201590d84` activates
  `.10.4` alone for public atomic backend publication, exact Verilator 5.046
  compile/run, runtime-trace capture, and normalized result production. This
  continuity transition changes no implementation, tool invocation, public
  action/capability/support claim, result, parity, or product behavior.

- `2026-07-31`: Clean `.7.3` implementation commit `44dbecd1a` activates only
  public tooling-contract selection `.8`. No VIAL parser/SemanticIR, HIAL
  bridge, binder/ExecutionIR/plan implementation, public command/API/file,
  layout/schema implementation, artifact, backend, compile, simulation,
  runtime result, parity, UVM/VHDL methodology, mixed-language, or product
  behavior changes during activation.
- `2026-07-31`: `.8` accepts decision `0039` and the exact public-tooling
  contract; proposed `.9` alone owns later plain-SV/Verilator backend-contract
  activation, and selection changes no product behavior.

- `2026-07-31`: Clean `.8` selection commit `d34da3254` activates only
  portable-SV/Verilator backend-contract selection `.9`. No backend contract,
  parser, command/API/file, generated SystemVerilog, runtime library, tool
  invocation, compile, elaboration, simulation, result, parity, capability,
  support, or product behavior changes during activation.
- `2026-07-31`: `.9` accepts decision `0043` and the exact portable-SV backend
  contract. Proposed `.10` alone owns implementation after a separate clean
  activation; selection ships no command, artifact, runtime, or result.
- `2026-07-31`: Clean `.9` commit `ab3e73b72` activates `.10` alone. No source,
  parser, command/API, backend artifact, compile/run path, result, capability,
  parity, or product behavior changes during activation.
- `2026-07-31`: Clean activation commit `5fd766600` decomposes `.10` into four
  implementation children and activates `.10.1` alone without behavior.
- `2026-07-31`: `.10.1` ships the public source-only CLI/API, equivalent
  normal/terse projections, exact discovery/support, and fail-closed no-write
  boundaries. `.10.2` is proposed next for separate activation.
- `2026-07-31`: Clean `.10.1` implementation commit `50a0d7d39` activates only
  `.10.2` planning/artifact implementation. The selected contract and all
  product behavior remain unchanged during activation.
- `2026-07-31`: `.10.2` ships public `fsmgen vial plan` and the equivalent
  closed in-memory action. Canonical HIAL review routing, deterministic
  normal/review/bridge/plan/tool-manifest graphs, identical-tree replay,
  collision/path/symlink/cleanup safety, and exact discovery/support truth are
  enforced. A discovered source/public-contract mismatch is corrected by
  allowing zero DUT transaction bindings only for fixtures that use no
  transaction-dependent semantics, enabling honest direct-IAL0 planning.
  `.10.3` remains proposed; no target backend, compile, runtime, result, parity,
  UVM, VHDL, mixed-language, or scale claim ships.
- `2026-07-31`: Clean `.10.2` implementation commit `045629c97` activates only
  `.10.3` portable-SystemVerilog artifact and trace projection. No source,
  plan, target artifact, capability/support, compile/runtime, result, parity,
  UVM, VHDL, mixed-language, scale, or product behavior changes during
  activation.
- `2026-07-31`: `.10.3` ships the private deterministic
  `sv_portable_verilator` emitter and pure closed-trace validator. The planner
  retains exact immutable compiler inputs without changing public projections;
  emission returns the eight selected virtual artifacts with complete source
  maps, one-scheduler plain SV, declared-probe aliases, and honest unexecuted
  command/profile records. Public publication, compile/simulation, runtime
  capture, normalized results, parity, and target-methodology claims remain
  later owners.

- `2026-07-31`: `.7.3` ships the bounded private no-backend execution seam.
  The checked AHB SemanticIR and review-routed bridge now bind into immutable
  target-neutral ExecutionIR and a defensive in-process plan with exact
  directional proofs, logical operation/fiber order, resolved event adapters,
  deterministic arbitrary-width random/replay, resource limits, atomic
  diagnostics, and closed private capability/support accounting. Signoff also
  corrects result/parity ownership: their selected schemas retain explicit
  `.10`/`.11` owners and are not satisfied `.7.3` capabilities. No public
  CLI/API/file, backend artifact, compile, simulation, runtime result, parity
  pass, UVM/VHDL methodology, mixed-language, or scale claim ships.

- `2026-07-31`: Clean `.7.2` selection commit `2a1b3cefc` activates only
  private no-backend implementation `.7.3`. No parser, SemanticIR, bridge,
  binder, ExecutionIR, random/replay, plan/result object or file, scheduler,
  native extension implementation, backend, capability/support surface,
  compile, simulation, runtime, parity, or product behavior changes during
  activation.

- `2026-07-31`: `.7.2` accepts director-approved decision `0037`. VIAL
  semantic types and HIAL hardware carrier types remain independently
  authoritative; the binder must prove one closed directional bit-domain,
  known-value, or enum-encoding relation and record its exact proofs. Sampling
  cannot collapse X/Z, broader coercions and target casts remain forbidden,
  and the probe adapter stays independently required. Proposed `.7.3` owns
  implementation after separate clean activation; no product behavior changes.

- `2026-07-31`: `.7.1` confirms a foundational pre-code contract mismatch:
  VIAL enum/Boolean/unsigned transaction drive types meet three HIAL
  four-state logic carriers, while decision `0036` requires exact identity.
  The canonical audit recommends a closed proof-carrying directional adapter,
  records the exact-identity alternative, narrows `.5`'s overbroad historical
  type-resolution claim, blocks `.7.2` for the director's choice, and routes
  implementation to `.7.3`. No product behavior changes.

- `2026-07-31`: Clean `.6` selection commit `eaf3f95dc` permits a separate
  continuity-only activation of private implementation `.7`. No binding/
  ExecutionIR, random/replay implementation, plan/result object or file,
  scheduler, native extension implementation, backend, CLI/API, runtime,
  parity, or product behavior changes in activation.

- `2026-07-31`: `.6` accepts decision `0036` and the exact target-neutral
  `VIALExecutionIR` v1 contract. Logical drive/sample/react/check ordering,
  plan-time stable randomness/replay, declarative typed native implementations,
  sanitized plan, normalized result/parity, exact AHB oracle, limits,
  diagnostics, and no-backend boundary are frozen. Proposed `.7` is selected
  next for separate clean activation; no product behavior changes in selection.

- `2026-07-31`: Clean `.5` implementation commit `51434a2ae` permits a
  separate continuity-only activation of documentation contract `.6`. No VIAL
  binding/ExecutionIR, plan/result contract or artifact, scheduler, native
  extension, backend, CLI/API, runtime, parity, or product behavior changes in
  activation.

- `2026-07-31`: `.5` ships the private in-process bridge manifest producer
  through canonical direct IAL0, direct IAL1, and IAL2-via-generated/reparsed-
  IAL1 routes. Additive bridge metadata changes no generated IAL0 or HIAL HDL;
  exact t1551/support evidence locks stable IDs, provenance, defensive data,
  limits, diagnostics, capability accounting, and all no-file/no-binding/no-
  runtime claims. Proposed `.6` is selected next for clean activation.
- `2026-07-31`: Adjacent contract audit t359 exposed and this slice repairs its
  missing projection of the new private capability/non-claim fields. Separate
  t370 discovery-map drift is unchanged at HEAD and is durably parked under
  proposed `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-PRESENCE-MAP-SYNC`.
- `2026-07-31`: The live task-tree doctrine oracle now accepts a positive
  measured active-tree count instead of the obsolete pre-HIAL literal one;
  exact fixture counts and all structural negative cases remain unchanged.

- `2026-07-31`: Clean `.4` selection commit `0366dfe30` activates only private
  bridge implementation `.5`; no parser, annotation, bridge object/report,
  artifact, HIAL output, VIAL binding, test runtime, or product behavior
  changes in activation.
- `2026-07-31`: `.4` selects the review-routed bridge v1 contract under
  decision `0035`: generated IAL1 owns additive protocol/event/probe/residue
  annotations, exact IDs match the checked AHB VIAL fixture, PPIF cannot bypass
  IAL1, and proposed `.5` alone owns a private no-file implementation.
- `2026-07-31`: Clean `.3` implementation commit `be9c74163` activates only
  documentation contract `.4`; no bridge schema, producer, artifact, report,
  generated code, test, runtime, or product behavior changes in activation.
- `2026-07-29`: Added the director-agreed portable-Verilator versus
  full-language/SystemVerilog-UVM validation-profile requirement, with separate
  VHDL and mixed-language claim qualification; the tree remains proposed while
  parent selector `.817` selected the smaller adjacent AHB alias.
- `2026-07-29`: Parent selector `.819` keeps the architecture proposed while
  selecting the bounded two-window exact-three AHB readiness audit.
- `2026-07-29`: The bounded child audit/contract/implementation now ships the
  generic two-window exact-three source at 325/366/49. Proposed parent selector
  `.820` retains this architecture boundary and must independently decide
  whether it now outranks the matching alias and other adjacent IAL2 work.
- `2026-07-29`: Clean behavior commit `1a73bc65e` activates parent selector
  `.820`; HIAL/VIAL remains proposed while that selector evaluates it against
  the adjacent matching alias and other exact owners.
- `2026-07-29`: Parent selector `.820` selects the byte-identical two-window
  exact-three `.ahb` alias as the smaller data-only owner. HIAL/VIAL stays
  proposed with its portable-fast/full-language/VHDL/mixed-language profiles
  unchanged.
- `2026-07-29`: Clean selector commit `f3585f98d` activates only alias
  implementation `.821`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-29`: Alias implementation `.821` ships the two-window exact-three
  generic/profile pair at 326/367/50. Proposed `.822` will independently
  select the next roadmap owner; HIAL/VIAL and its portable-fast/full-language/
  VHDL/mixed-language profile boundary remain proposed and unchanged.
- `2026-07-29`: Clean alias behavior commit `db402fd9d` activates parent
  selector `.822`; HIAL/VIAL remains proposed while the selector compares it
  with the remaining exact IAL2 and correctness owners.
- `2026-07-29`: Parent selector `.822` selects the smaller exact-four AHB
  requester counter-width readiness audit. HIAL/VIAL remains proposed with its
  typed bridge, portable/native semantics, full-language simulator, VHDL/
  mixed-language, migration, and large-design requirements unchanged.
- `2026-07-29`: Clean parent selector commit `db0990c9d` activates only the
  exact-four readiness audit `.1`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-29`: Exact-four readiness audit `.1` proves assertion-enabled
  `4 -> 3 -> 2 -> 1 -> 0` runtime and selects proposed no-behavior contract
  `.2`; HIAL/VIAL remains proposed with no architecture or priority change.
- `2026-07-29`: Clean audit commit `74d91347e` activates exact-four
  no-behavior contract `.2`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-29`: Exact-four contract `.2` selects proposed generic
  implementation `.3` at projected 327/368/51; HIAL/VIAL remains proposed with
  no architecture or priority change.
- `2026-07-29`: Clean contract commit `58efc8aff` activates exact-four
  implementation `.3`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-29`: Exact-four implementation `.3` ships the generic source at
  327/368/51 split 26/25 and reserves a separate proposed alias-contract `.4`;
  HIAL/VIAL remains proposed with no architecture or priority change.
- `2026-07-29`: Clean generic behavior commit `95bfb7e4b` activates only
  exact-four alias contract selector `.4`; HIAL/VIAL remains proposed and
  unchanged.
- `2026-07-29`: Exact-four alias contract `.4` selects data-only proposed `.5`
  at projected 328/369/52; HIAL/VIAL remains proposed with no architecture or
  priority change.
- `2026-07-29`: Clean exact-four alias contract commit `3370e15cd` activates
  data-only `.5`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-29`: Exact-four alias implementation `.5` ships the requester
  generic/profile pair at 328/369/52 split 26/26; HIAL/VIAL remains proposed
  with no architecture or priority change.
- `2026-07-29`: Clean exact-four alias behavior commit `ba2d1c01f` activates
  parent selector `.823`; HIAL/VIAL remains proposed while the selector
  compares it with the remaining exact roadmap owners.
- `2026-07-29`: Parent `.823` selects the smaller one-window exact-four paired
  AHB readiness audit; HIAL/VIAL and its full-language simulator, VHDL,
  migration, and large-design requirements remain proposed and unchanged.
- `2026-07-29`: Clean selector commit `d91c5c7c9` activates only exact-four
  paired readiness `.1`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-29`: Exact-four paired audit `.1` passes assertion-enabled
  5/4/1/4/1 runtime plus real MCP and selects generic contract `.2`; HIAL/VIAL
  remains proposed with no architecture or priority change.
- `2026-07-29`: Exact-four paired contract `.2` selects data-only proposed `.3`
  at projected 329/370/53; HIAL/VIAL remains proposed with no architecture or
  priority change.
- `2026-07-30`: Exact-four paired implementation `.3` ships the generic source
  at 329/370/53 with assertion-enabled t1537 and semantic/read-only-MCP parity;
  HIAL/VIAL remains proposed with no architecture or priority change.
- `2026-07-30`: Clean exact-four paired behavior commit `c42347a5e` activates
  parent selector `.824`; HIAL/VIAL remains proposed while `.824` compares it
  with adjacent exact AHB and other roadmap owners.
- `2026-07-30`: Parent `.824` selects the smaller byte-identical exact-four
  paired `.ahb` alias as pending `.825`; HIAL/VIAL remains proposed with its
  portable-fast/full-language/VHDL/mixed-language/scale requirements intact.
- `2026-07-30`: Clean selector commit `5b601fffc` activates only data-only
  alias slice `.825`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Alias slice `.825` ships the exact-four paired generic/profile
  pair at 330/371/54 with t1538 parity and shared t1537 runtime; HIAL/VIAL
  remains proposed for pending post-behavior selector `.826` to compare.
- `2026-07-30`: Clean alias behavior commit `40b8ead71` activates no-behavior
  selector `.826`; HIAL/VIAL remains proposed while `.826` compares it.
- `2026-07-30`: Selector `.826` chooses the smaller adjacent two-subordinate
  exact-four paired AHB readiness audit; HIAL/VIAL remains proposed with its
  portable-fast/full-language/VHDL/mixed-language/scale requirements intact.
- `2026-07-30`: Clean selector commit `4abb0a357` activates only two-window
  exact-four readiness `.1`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Two-window exact-four audit `.1` proves assertion-enabled
  10/8/2/8/2 runtime plus semantic/read-only-MCP parity and selects pending
  generic contract `.2`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Clean audit commit `a5d162d60` activates only two-window
  exact-four contract `.2`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Two-window exact-four contract `.2` selects one generic source,
  t1539 assertion runtime, and pending `.3`; HIAL/VIAL remains proposed and
  unchanged.
- `2026-07-30`: Clean contract commit `4d0cc34bd` activates only data-only
  implementation `.3`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Two-window exact-four implementation `.3` ships generic
  source/support/t1539 at 331/372/55; HIAL/VIAL remains proposed and unchanged
  for the next parent selector to compare.
- `2026-07-30`: Clean child behavior commit `a62ddb705` activates parent
  selector `.827`; HIAL/VIAL remains proposed and unchanged while `.827`
  compares it with smaller adjacent and cross-lane owners.
- `2026-07-30`: Selector `.827` chooses pending data-only exact-four
  two-window `.ahb` alias `.828`; HIAL/VIAL remains proposed with its complete
  portable-fast/full-language/VHDL/mixed-language/scale boundary intact.
- `2026-07-30`: Clean selector commit `bc29c2e49` activates only `.828`;
  HIAL/VIAL remains proposed and unchanged during alias activation.
- `2026-07-30`: Implementation `.828` ships only the byte-identical two-window
  exact-four `.ahb` alias/support/t1540 parity at 332/373/56 split 28/28;
  HIAL/VIAL remains proposed with its portable-fast/full-language/VHDL/
  mixed-language/large-design boundary unchanged.
- `2026-07-30`: Clean `.828` behavior commit `3519cde33` activates parent
  selector `.829`; HIAL/VIAL remains proposed and unchanged while `.829`
  compares it with the remaining roadmap owners.
- `2026-07-30`: Selector `.829` chooses the smaller adjacent no-behavior
  generalized literal AHB BUSY-count readiness audit. HIAL/VIAL remains
  proposed with its typed bridge, portable/native semantics, full-language
  UVM authority, VHDL/mixed-language, migration, and scale gates unchanged.
- `2026-07-30`: Clean selector commit `a2750d8a6` activates only the
  generalized-count audit `.1`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Generalized-count audit `.1` selects bounded literal `2..16`
  contract `.2`; HIAL/VIAL remains proposed with its independent architecture,
  simulator-profile, VHDL/mixed-language, migration, and scale gates intact.
- `2026-07-30`: Clean audit commit `18f63a971` activates only generalized-count
  contract `.2`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Generalized-count contract `.2` selects the smaller
  lowerer/test-only `.3`; HIAL/VIAL remains proposed with its architecture,
  full-language authority, VHDL/mixed-language, migration, and scale gates.
- `2026-07-30`: Clean contract commit `7e2b436cf` activates only `.3`;
  HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Generalized-count implementation `.3` ships canonical decimal
  `2..16` plus t1541 assertion/semantic/MCP/verifier proof at unchanged
  332/373/56 split 28/28. It generates no verification HDL and does not
  activate or narrow HIAL/VIAL; proposed parent selector `.830` must compare
  this architecture independently after the clean behavior commit.
- `2026-07-30`: Clean generalized-count behavior commit `2f64611ca` activates
  parent selector `.830`; HIAL/VIAL remains proposed and unchanged while the
  selector performs its independent comparison.
- `2026-07-30`: Completed selector `.830` chooses the narrower assertion-backed
  transaction-invoked named-drive priority audit. HIAL/VIAL remains proposed
  with its typed bridge, portable/native semantics, full-language UVM
  authority, VHDL/mixed-language, migration, parity, and scale gates intact.
- `2026-07-30`: Clean selector commit `f67705356` activates only that audit
  `.1`; HIAL/VIAL remains proposed and unchanged during activation.
- `2026-07-30`: Named-drive priority audit `.1` selects its narrower
  unique-caller target-local contract `.2`; HIAL/VIAL remains proposed with
  all architecture and validation requirements unchanged.
- `2026-07-30`: Clean audit commit `e715a34c7` activates only that no-behavior
  contract `.2`; HIAL/VIAL remains proposed and unchanged during selection.
- `2026-07-30`: Named-drive priority contract `.2` selects proposed `.3` with
  SV/Verilog executable gates. Its backend probe separately exposes invalid
  direct-VHDL unary-reduction residue under decision `0023`; proposed
  `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING` owns that HIAL backend defect,
  while HIAL/VIAL architecture scope remains proposed and unchanged.
- `2026-07-30`: Named-drive priority implementation `.3` ships through clean
  commit `1dbff8fc6`; parent selector `.831` selects the narrower no-behavior
  direct-VHDL unary-reduction audit. HIAL/VIAL remains proposed with every
  architecture, backend, qualification, parity, migration, and scale
  requirement intact.
- `2026-07-30`: Clean selector commit `5f904d2d2` activates only the selected
  direct-VHDL audit `.1`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Direct-VHDL audit `.1` selects proposed scalar-identity and
  unsupported-reduction fail-closed implementation `.2`. This repairs one
  synthesizable HIAL-to-VHDL correctness seam but neither activates nor
  narrows the broader HIAL/VIAL verification-fixture architecture.
- `2026-07-30`: Clean audit commit `16f6140c4` activates only direct-VHDL
  implementation `.2`; HIAL/VIAL remains proposed and unchanged.
- `2026-07-30`: Direct-VHDL implementation `.2` ships scalar/static-bit
  identity, explicit vector folds, and unsupported-shape rejection. This closes
  one HIAL-to-VHDL correctness seam but does not activate or narrow VIAL;
  proposed parent selector `.832` must compare the architecture independently.
- `2026-07-30`: Parent `.832` compares the architecture and selects the
  smaller shipped AXI concurrent-assertion correctness audit first. HIAL/VIAL
  remains proposed and unchanged for a later clean roadmap selector.
- `2026-07-29`: Created the proposed, inactive HIAL/VIAL architecture tree.
