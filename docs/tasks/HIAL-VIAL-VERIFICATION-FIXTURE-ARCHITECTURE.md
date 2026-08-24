# HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE: Hardware And Verification Intent Architecture

## Metadata

- Tree ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`
- Status: `active`
- Roadmap lane: `Verification code generation / intent architecture`
- Created: `2026-07-29`
- Last updated: `2026-08-23`
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
  Status: `done`
  Goal: `Implement complete reviewable simulator-neutral sv_uvm_emit.accellera_2020_3_1 generation through bounded children without a parser or simulator gate.`
  Acceptance: `Representative typed-IR fixtures and public authorable paths where available emit the full selected UVM environment shape across topology, interfaces, lifecycle, notification/interception, stimulus, TLM, factory/configuration, RAL, constrained decisions, coverage/properties, models/scoreboards/faults/results, with efficient readable deterministic artifacts, complete source maps, an accumulating review gallery, and explicit static/manual-review versus compile/elaboration/run/result states. No child waits for a simulator merely to generate broader UVM; unknown defects remain possible and are tracked when found rather than hidden. Raw SV/UVM knowledge stays absent from authored VIAL, legacy UVM 1.2 remains compatible, and neither visual review nor static shape checks become syntax/runtime/full-VIAL qualification.`
  Verification: `.13.1.1` ships the native emitter foundation, `.13.1.2` ships complete selected topology/lifecycle/notification structures, `.13.1.3` ships stimulus/services, `.13.1.4` ships coverage/properties/models/scoreboards/faults/diagnostics/result collection, and `.13.1.5` closes the exact selected mapping matrix and deterministic review workflow without a simulator prerequisite. The complete selected emission profile remains unqualified and is not full UVM breadth.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.5: close native UVM matrix and review workflow`
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
  Status: `done`
  Goal: `Emit representative stimulus, sequence, TLM, factory/configuration, RAL, and constrained-decision UVM structures without waiting for runtime qualification.`
  Acceptance: `Typed-IR fixtures and public source routes where selected generate efficient readable sequence items/sequences/sequencers/drivers, analysis/TLM wiring, scoped factory/configuration plumbing, RAL objects/adapters/predictors, and controlled native constraint structures with exact semantic ownership, source maps, deterministic galleries, static checks, honest unimplemented/public-authoring boundaries, and no inferred compile or simulation claim.`
  Verification: `Emitter revision 3 produces the exact twelve-artifact/eight-SystemVerilog-source graph with 64 complete source-map entries. A typed six-field AHB write item, sequencer, compiler-selected active driver, two generated public scenario sequences, driven/observed analysis streams, one typed analysis FIFO, subscriber, exact non-wildcard configuration paths, one driver factory override, and a private fixture-specific RAL block/adapter/predictor ship. Portable constrained-decision values are replayed without UVM rerandomization; the isolated bounded native solver preview is never invoked by generated scenarios. Twelve static checks cover the prior foundation plus active topology, services, TLM, factory/configuration, RAL, wildcard rejection, and no-native-solver-execution boundaries. Seven UVM-facing sources are deterministically regenerated and byte-checked. Focused Files=5/Tests=7,110 and syntax checks pass before documentation closure; parse, compile, elaboration, runtime, result, parity, public RAL/factory authoring, coverage/property/model/scoreboard/fault/result breadth, and visual-review completion remain explicitly unclaimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.3: ship native UVM stimulus and services`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.4`
  Status: `done`
  Goal: `Emit representative coverage, property, model, scoreboard, fault, diagnostic, and result UVM structures without waiting for runtime qualification.`
  Acceptance: `Typed-IR fixtures and selected public routes generate covergroups, bound SVA checkers, analysis/model/scoreboard components, declared fault interception, report/result collection, capability/non-claim records, source maps, and deterministic review-gallery artifacts; structural and visual evidence is recorded separately from syntax/compile/runtime truth, and later simulator findings remain ordinary tracked defects rather than a reason to block emission breadth.`
  Verification: `Emitter revision 4 produces the exact fourteen-artifact/ten-SystemVerilog-source graph with 75 complete source-map entries and 14 structural checks. Public stall coverage, two deterministic event-counter instances, one capacity-four in-order scoreboard, exact expected-item construction, one-drive-interval size substitution, property/diagnostic collection, a separately bound SVA checker, and structured result snapshot wiring ship across nine byte-locked UVM-facing gallery sources. Width-aware literal validation repairs preexisting one-/two-bit notification predicate execution. Parse, compile, elaboration, runtime, result-manifest production, parity, probe-backed expectation execution, and visual-review completion remain explicitly unclaimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.4: ship native UVM checking and results`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.5`
  Status: `done`
  Goal: `Close the full native UVM emission matrix, review workflow, examples, and deferred-runtime defect boundary.`
  Acceptance: `Every selected UVM mapping has an emitted representative or exact unsupported reason; normal/terse and typed-IR entry availability is distinguished from private preview fixtures; the checked gallery is easy to regenerate and inspect; automated static findings and director visual-review findings become exact task-tree defects; all emitted artifacts remain simulator-neutral and deterministic; legacy compatibility and docs are complete; and the matrix says emitted/reviewed/unqualified rather than waiting for or pretending full simulation.`
  Verification: `Emitter revision 5 produces the exact sixteen-artifact/ten-SystemVerilog-source graph while retaining 75 complete source-map entries and 14 structural checks. Two canonical JSON artifacts contain a 25-row selected mapping matrix and seven-stage review workflow guarded by five internal invariants. The matrix equals the emitted-foundation set, distinguishes normal/terse public entry, compiler-owned IR, and private previews, and gives every unavailable public route an exact reason. The repository-relative gallery command regenerates nine sources plus two evidence files; --check writes nothing and rejects missing, extra, or byte-drifted snapshots. Visual review remains pending, defects require exact durable task-tree fields, legacy UVM 1.2 remains separate, and parse/compile/elaboration/runtime/result/parity/full-UVM breadth remain explicitly unclaimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.5: close native UVM matrix and review workflow`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.2`
  Status: `done`
  Goal: `Implement the first reusable exact open-source UVM compile/elaboration feasibility probe without converting experimental evidence into product support.`
  Acceptance: `As soon as .13.1.1 publishes the first gallery, select exact available open-source tool/version and immutable UVM source variant identities; separately attempt preprocessing/parsing, library compile, fixture compile, elaboration, and any supported runtime smoke; record argv, deviations/patches/failures and every not-exercised capability; expose a reusable nonblocking probe for later emission children; classify a demonstrated generator defect separately from a tool limitation; keep discovery labelled experimental; preserve qualified/runtime non-claims; and close honestly even when some or all stages are unsupported.`
  Verification: `The exact experimental tuple is Verilator 5.046 plus CHIPS Alliance uvm-verilator uvm-2020-3.1-vlt commit 656f20d087370a7c742e00188d20bbf30fa95339/tree 882930bb7debe79b22234e4a8a53854549046778, with canonical Accellera 2020.3.1 identity retained. A reusable bounded same-volume probe validates identities, records exact argv/deviations/resources/transcript digests, and removes staging. Its UVM library preprocess, parse, compile/elaboration, and zero-error run_phase smoke pass; the generated fixture preprocesses, strict parsing reaches Verilator's unsupported ranged-SVA delay, unsupported-feature blackboxing reaches a Verilator internal fault/exit 139, and fixture runtime/result/parity remain not run. The probe found and this slice repaired the generator's illegal SystemVerilog keyword identifier context to vial_context before the canonical rerun. The checked report deterministically concludes partial_tool_limited with product_support false; ordinary emission remains simulator-neutral and all qualified runtime/breadth nonclaims stay exact. Focused and broader evidence is recorded below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.2: ship exact experimental UVM probe`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.3`
  Status: `deferred`
  Goal: `Select, integrate, and capability-qualify the first exact PGEN parser plus MCP-operated NEXSIM simulator UVM runtime tuple.`
  Acceptance: `Once executable provider releases exist, a documentation selection freezes exact PGEN and NEXSIM versions/content/commands, parser-to-simulator handoff schema, NEXSIM semantic-introspection API schema, MCP protocol/profile, Accellera UVM identity, capability matrix, project-local artifacts, permissions, limits, and failure boundaries before implementation. The selected NEXSIM contract must expose stable source-mapped semantic identities; snapshot-consistent deterministic bounded queries; explicit side-effect-free inspection versus authorized control; hierarchy, types, four-state values, processes/events/scheduler state, assertions/coverage, and UVM topology/phases/objections/factory/configuration/TLM/sequences/RAL state where supported; plus run/step/pause/breakpoint/checkpoint/replay/cancel controls where selected. Implementation then proves parse, UVM/DUT compile, elaboration, four-state timed execution, notification/interception results, semantic checkpoint correlation, first-divergence localization against applicable IASIM/portable normalized oracles, deterministic rerun, cleanup, and every applicable normalized parity oracle without borrowing experimental or commercial-tool evidence. NEXSIM introspection remains provider evidence: it cannot redefine VIAL meaning, leak into canonical generated source, or turn one observed subset into full SystemVerilog/UVM qualification.`
  Verification: `Director-deferred on 2026-08-09 until capability-ready PGEN and NEXSIM releases provide the exact release, API, schema, protocol, handoff, and capability evidence required by this leaf; no placeholder provider work remains PNT-eligible.`
  Commit: `this commit (director deferral)`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14`
  Status: `done`
  Goal: `Select the VHDL-2008 verification backend, methodology-provider mapping, existing-package migration, and GHDL/qualified profiles.`
  Acceptance: `The contract chooses pure VHDL-2008 portable responsibilities and an exact OSVVM/UVVM/no-provider decision for advanced semantics, maps drivers/samplers/scenarios/models/scoreboards/coverage/faults/results without requiring VHDL knowledge from a VIAL author, freezes efficient/readable/source-mapped artifact criteria plus standard/library/options and GHDL and broader qualified profiles, records PSL and language non-claims, and versions/migrates the inert VHDL observation package without inferring analyzer support.`
  Verification: `Decision 0051 and the version-1 contract select provider-free IEEE VHDL-2008 as the portable semantic core, exact GHDL 6.0.0 as its first unexecuted qualification tool, and exact OSVVM 2026.05 as the advanced provider; UVVM 2026.03.20 is audited but not selected. The contract fixes inactive-edge logical scheduling, four-state/std_logic normalization, drivers/samplers/scenarios/models/scoreboards/coverage/faults/results, deterministic source-mapped artifacts, GHDL and broader profile gates, PSL/non-claims, recursive provider locality, and a parallel versioned successor that leaves the inert legacy command unchanged. GHDL/OSVVM are absent locally, so no artifact, analysis, elaboration, runtime, result, parity, or capability ships. Final repository gates are recorded below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14: select VHDL OSVVM architecture`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15`
  Status: `active`
  Goal: `Implement and capability-qualify the selected VHDL verification backend.`
  Acceptance: `The bounded VIAL subset emits deterministic, efficient, readable, source-mapped VHDL artifacts without requiring VHDL knowledge from a VIAL author, analyzes/elaborates/runs under the exact installed profile, matches the portable normalized result oracle, reports exact standard/methodology/PSL capabilities and non-claims, migrates or versions the inert package exactly as contracted, and leaves HIAL VHDL synthesis output distinct.`
  Verification: `Clean decision/selection predecessor e5aa90b7ad4dc0164bbbdffa285b8351158592e5 activates this implementation parent and child .15.1 alone. Children .15.1-.15.4 can complete deterministic provider-free emission and review without an installed analyzer; .15.5 separately owns exact GHDL execution, while .15.6-.15.7 own OSVVM emission and qualification. Activation changes no source, artifact, capability, support, analyzer, elaboration, runtime, result, or parity behavior.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15: activate VHDL backend implementation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.7`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.1`
  Status: `done`
  Goal: `Implement the provider-free VHDL-2008 emitter substrate and first deterministic review gallery without requiring GHDL or OSVVM bytes.`
  Acceptance: `The private emitter consumes exact VIALExecutionIR, bridge, and HIAL DUT identities and publishes the selected vhdl_portable_ghdl graph atomically under repository-derived roots: closed backend manifest, complete source map, standard/tool profile, typed value/time/runtime packages, metadata package, top-level testbench foundation, ordered source list and command evidence shapes. Structural validators, capability/support states, malformed-input and collision negatives, identical rerender, exact cleanup, and first byte-locked gallery ship; the legacy vhdl-observation-package remains byte/schema-compatible and unconsumed; ordinary emission performs no provider fetch; and analyze, elaborate, run, result, parity, PSL, full VHDL-2008, and support remain explicitly not run or unclaimed.`
  Verification: `The private plan handoff now carries exact deterministic HIAL SystemVerilog and VHDL records while public projections stay unchanged. VHDLPortableGHDL emits a sorted thirteen-artifact/five-source provider-free foundation with closed manifest, five-entry source map, typed value/phase and logical-time packages, fixture metadata, direct entity/port-bound testbench, ordered source list, exact unexecuted GHDL 6.0.0 command/tool records, seven-check structural validation, and explicit legacy migration. Focused tests cover malformed inputs, provider leakage, unresolved placeholders, deterministic rerender, atomic first/identical/collision publication, exact cleanup, capability truth, and a byte-locked five-source/eight-evidence gallery. The unchanged legacy target is separately re-proven, ordinary emission fetches no provider, and analysis/elaboration/runtime/result/parity/PSL/full-VHDL/support remain unclaimed. Final repository gates are recorded below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.1: ship portable VHDL foundation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.2`
  Status: `done`
  Goal: `Emit the complete selected portable VHDL drivers, samplers, inactive-edge scheduler, scenarios/fibers, models, and probe adapters for review.`
  Acceptance: `Generated VHDL expresses typed four-state drive/sample normalization with original-symbol evidence, one inactive-edge stable barrier, exact ExecutionIR ranks, bounded scenario/fiber state, deterministic model state, public-port binding and explicit source-mapped probe adapters. Static invariants reject delta-cycle or process-order semantic authority, undeclared hierarchy, unstable/multiple schedulers, unsupported nine-state needs, and multi-clock/asynchronous use; readable gallery artifacts and complete source maps ship without an analyzer prerequisite or runtime claim.`
  Verification: `The provider-free backend now emits an exact fourteen-artifact/six-VHDL-source graph with 52 source-map entries and 13 structural checks. Typed strong drivers, original-symbol-preserving samplers, one falling-edge inactive barrier, exact 21-operation ranks, two bounded scenarios, four fibers, two deterministic event-counter models, and one declared external-name probe adapter ship as reviewable source. Negotiation and structural negatives reject nine-state semantics, multiple domains, asynchronous semantic events, multiple/zero-time schedulers, rank drift, undeclared hierarchy, provider leakage, and malformed inputs. Analysis, elaboration, runtime, checking/results, parity, complete VHDL-2008, and support remain unclaimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.2: ship portable VHDL semantics`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.3`
  Status: `done`
  Goal: `Emit portable VHDL scoreboards, coverage, faults, procedural properties, diagnostics, closed trace, and normalized results.`
  Acceptance: `Generated bounded queues/comparisons, coverage counters, substitution or masking seams, procedural checks, diagnostic records, trace closure, and fsmgen.verification_result_manifest.v1 projection preserve VIAL comparison/bin/fault/property/result meaning. Structural negative oracles cover overflow, unknown-value evidence, trace non-closure, result inconsistency, unsupported PSL/native-provider requests, and probe-backed expectations; deterministic gallery/source-map evidence ships while analyze through parity remain independent states.`
  Verification: `The provider-free graph remains fourteen artifacts/six VHDL sources and now carries 59 complete source-map entries plus 20 structural checks. Generated source contains the exact capacity-four scoreboard, both stall coverage bins, immutable-source one-cycle size substitution, procedural success/ERROR/timeout/unknown checks, bounded stored diagnostics, logical-time header/body/footer trace framing, and the full top-level fsmgen.verification_result_manifest.v1 projection with explicit unproduced identity/parity fields. Mutation oracles reject overflow-evidence removal, unknown-evidence removal, trace non-closure, invalid C-style JSON escaping, result inconsistency, PSL/provider leakage, and undeclared probe hierarchy. The byte-locked gallery, capability/support truth, impacted regression, mdBook, Knowledge Map, staged acceptance, doctrines, and exact cleanup evidence are recorded below; analysis through parity remain unclaimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.3: ship portable VHDL checking`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.4`
  Status: `done`
  Goal: `Close the provider-free VHDL emission matrix, review workflow, examples, migration proof, and deferred-runtime defect boundary.`
  Acceptance: `Every selected portable mapping has an emitted representative or exact unsupported reason; public authoring, compiler-owned IR, and private previews are distinguished; the checked gallery is easy to regenerate and inspect; automated and director visual-review findings route to exact defect leaves; legacy package byte/schema compatibility and HIAL VHDL separation are proven; and the profile reports emitted/reviewed/unqualified without waiting for or implying GHDL execution.`
  Verification: `The provider-free revision-4 graph contains seventeen artifacts while retaining six VHDL sources, 59 complete source-map entries, and 20 structural checks. Three canonical evidence artifacts add a 24-row selected matrix with 20 emitted and four exactly unsupported mappings, a seven-stage repository-relative review workflow, and an exact legacy/HIAL migration-separation proof; seven internal invariants and focused fail-closed mutations protect the closure. Public/derived/compiler/bridge/private-preview boundaries are explicit, visual review remains pending, and the profile says emitted/structurally reviewed/unqualified. The checked inert legacy fixture remains exactly 976 bytes with locked package and path-independent manifest-projection digests; the HIAL DUT is byte-identical and isolated. Final regression, gallery, mdBook, Knowledge Map, staged acceptance, doctrine, and cleanup evidence is recorded below; analysis through support remain unclaimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.4: close portable VHDL review`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.5`
  Status: `done`
  Goal: `Materialize or locate exact GHDL 6.0.0 and capability-qualify the provider-free backend through normalized runtime results.`
  Acceptance: `An exact GHDL 6.0.0 build identity, backend, repository-local work/cache/output roots, and ordered --std=08 analyze/elaborate/run commands are frozen and executed. Independent gates prove library/source analysis, elaboration, bounded four-state timed execution, closed trace, normalized result/outcomes, deterministic rerun, applicable portable-SV parity, resource limits, and exact cleanup; partial VHDL-2008/PSL and every unexercised feature remain explicit, and no other simulator is inferred.`
  Verification: `The exact official macOS ARM64 GHDL 6.0.0 LLVM-JIT archive is repository-local at 37,155,806 bytes/SHA-256 c21312d5a0cc5833e6d8690d8c4343e67f4fc32f070c07343816cd11a31c7769; the selected binary is SHA-256 38a99c1cc18b04dfae128b118c7344910e08b8ba6eeb9c1e67f950a84bca3c3d and reports commit e589c698c with the LLVM JIT backend. The checked qualifier executes ordered --std=08 analysis/elaboration/run commands from the repository root into an exact same-volume staging identity, removes it, and repeats fixture and timed 0/1/X/Z probe output byte-identically. The fixture produces one closed 42-record trace, a passing normalized result, exact success/error outcomes, and equivalence across 19 applicable portable-SV oracle paths. Qualification-driven emitter repairs cover VHDL identifiers/boolean and reduction lowering, left-to-right carrier position, same-returning-ready acceptance/completion, and AHB ERROR settling. The exact LLVM AOT package remains explicitly unqualified because its external-name adapter dereferences null at runtime; PSL, complete VHDL-2008, OSVVM/UVVM, other simulators, mixed language, general parity, and scale remain unclaimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.5: qualify exact GHDL 6.0.0`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.6`
  Status: `done`
  Goal: `Implement the exact OSVVM 2026.05 advanced-methodology adapter and deterministic provider-dependent gallery.`
  Acceptance: `The recursive OSVVM release, every gitlink, license, and notice are verified under a repository-derived dependency root before provider-dependent work. Exact negotiated advanced randomization, coverage, scoreboard, reporting, synchronization, data-structure, and verification-component mappings emit behind a versioned adapter/profile with complete source maps and static negatives; portable pre-resolved randomness, phase order, comparison/coverage meaning, trace, and normalized results remain unchanged; no provider presence or structural evidence becomes a compile/runtime claim.`
  Verification: `The official OSVVM 2026.05 tag resolves to selected commit 2f7c391051dfb11890fa4bdbda9918d1db492250 and is completely materialized under .artifacts/cache/providers/osvvm/2026.05/source. The verifier locks the superproject plus thirteen recursive gitlinks by commit/tree/origin/tracked-entry identity, proves every worktree clean, and locks fourteen tracked Apache-2.0 licence files with zero notice files. The exact Documentation gitlink has no tracked licence or notice file; that absence is durable and no coverage is inferred. Revision-1 advanced emission produces six byte-identical portable VHDL sources plus one OSVVM adapter, seven negotiated RandomPkg/CoveragePkg/ScoreboardGenericPkg/AlertLogPkg/TbUtilPkg/MemoryPkg/AddressBusTransactionPkg mappings, thirteen source-map entries, twelve structural checks, six explicit semantic guards, and a byte-checked fifteen-artifact gallery. Provider materialization/emission remain explicitly narrower than combined GHDL analysis, elaboration, execution, result, parity, or support, which stay in .15.7.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.6: emit exact OSVVM 2026.05 adapter`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.7`
  Status: `done`
  Goal: `Capability-qualify the OSVVM 2026.05 plus GHDL 6.0.0 profile and close VHDL support accounting.`
  Acceptance: `The exact provider/tool tuple independently proves provider compilation order, adapter and generated-fixture analysis, elaboration, bounded execution, closed trace, normalized semantic outcomes, deterministic rerun, applicable portable-result parity, supplementary provider reports, limits, cleanup, manifest/capability/support truth, and honest unsupported breadth. OSVVM qualification cannot imply UVVM, PSL, complete VHDL-2008, another simulator, mixed-language execution, or legacy-package analyzer support.`
  Verification: `The checked exact tuple compiles 44 OSVVM core plus 17 Common sources in the selected GHDL/VHDL-2008 order, then analyzes the seven-source generated graph and dedicated provider probe. Fixture and probe elaboration/execution pass twice with byte-identical stdout; the portable fixture retains one closed 42-record trace, a passing normalized result, and equivalence across 19 applicable portable-SV paths. The supplementary probe runtime-exercises six advanced mappings, analysis-qualifies the Common address-bus type, and produces four byte-identical OSVVM reports: three clean affirmations, one-of-four-bin/25% coverage, and one scoreboard item checked with zero errors. The exact digest-named same-volume staging root is removed, provider trees remain clean, and support claims remain private/bounded. UVVM, PSL, complete VHDL-2008, provider verification-component transactions, another simulator, mixed language, legacy-package analysis, general parity, and scale remain unclaimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.7: qualify exact OSVVM GHDL profile`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.16`
  Status: `proposed`
  Goal: `Select and validate the first mixed-language HIAL/VIAL binding profile.`
  Acceptance: `An exact HIAL HDL plus VIAL verification-language combination, tool/version, bridge binding adapter, compile/elaboration/run sequence, capability/non-claim matrix, result parity oracle, project-local artifacts, licensing/CI policy, and unsupported combinations are selected and executed; no mixed-language claim is inferred from single-language gates.`
  Verification: `The 2026-08-10 eligibility census finds Verilator 5.046 and Icarus 13.0 on PATH plus exact repository-local GHDL 6.0.0 LLVM-JIT, but no vsim/Questa, qrun, xrun/irun, VCS, Riviera, NVC, or other compatible mixed-language execution tool. The Icarus version probe referenced one transient off-volume response path; an exact post-command absence check proves it left no residue. Decisions 0032 and 0051 forbid inferring mixed-language qualification from the separately qualified Verilator and GHDL lanes. This leaf remains proposed and unavailable until the external tool state changes; no adapter, execution, capability, or support claim is selected.`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17`
  Status: `active`
  Goal: `Define and prove architecture-specific large-fixture scalability and bounded failure.`
  Acceptance: `Deterministic workload profiles scale bridge units/endpoints/domains/transactions/probes and VIAL declarations/scenarios/fibers/events/checks/models/scoreboards/coverage/random decisions; stage correctness oracles, wall/CPU time, descendant RSS, artifact/result size, compile/simulation cost, explicit caps, graceful failures, and stable gates are measured without substituting for the separately owned whole-product big/really-big qualification.`
  Verification: `Clean predecessor 6d23b5843 closes the selected AXI/mdBook activity before this task-tree pivot. The 2026-08-10 eligibility census leaves .16 unavailable, while the shipped and independently qualified portable SystemVerilog, VHDL, and OSVVM profiles provide stable concrete inputs for architecture-specific scale measurement. This activation selects .17.1 alone; it changes no parser, IR, bridge, generator, artifact, runtime, capability, support, or scale claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17: activate scale-proof contract`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.8, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.9`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.1`
  Status: `done`
  Goal: `Select the exact architecture-specific scale workloads, correctness oracles, measurements, budgets, and non-claims.`
  Acceptance: `Audit the current SemanticIR, bridge, ExecutionIR, portable-SystemVerilog, portable-VHDL, OSVVM, trace/result, artifact-publication, resource-limit, and RAM-guard contracts. Select deterministic workload dimensions and named profiles; stage-local structural and semantic oracles; wall/CPU/RSS/artifact/compile/run measurements; repository-local staging and cleanup; calibration versus regression budgets; graceful-failure requirements; host/tool normalization; and the boundary from the separately owned whole-product big/really-big qualification. No code, fixture generator, capability, support, or scale claim changes in selection.`
  Verification: `Decisions 0055/0056 and their selected version-1 contracts define six orthogonal workload families, reference/gate-candidate/qualification-candidate/limit/over-limit levels, exact source/bridge/execution/checking axes, one conservative balanced profile, canonical-producer construction, stage-local correctness oracles, a closed measurement record, one-validation-plus-three/five-sample policies, 88%-host/4096-MiB-descendant safety, stage timeouts, immutable evidence-derived pinned-host regression formulas, earliest-cap authority, same-volume staging/cleanup, and explicit whole-product/multi-unit/mixed-language/native-UVM/full-language/general-parity nonclaims. The audit root-causes a support-snapshot drift introduced in dfe87f536: Runner and normative contract enforce 8 MiB compile/64 MiB run capture while support reports 4 MiB/4 MiB; proposed .17.6 owns alignment. The focused index is byte-current at 1,023 members, while pre-existing t/1569 retains 1,022; proposed .17.7 owns authority-derived repair. Decisions remain bounded at 389/244 lines. Focused documentation passes at Files=8/Tests=86; task integrity reports three trees/923 nodes; Knowledge Map is current at 1,105 facts/5,728 questions/5,894 occurrences/118 shards; all 52 mdBook chapters test, the 53-source-file maintained reference grows by exactly 58 lines/3,710 bytes, and the repository-local build contains 88 files/18,336,770 bytes before exact removal. Live-document coverage passes at 2,962 paths, acceptance/doctrines pass, and generated book/scale staging residue is absent. No parser, IR, bridge, generator, artifact, runtime, capability, support, or scale claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.1: select orthogonal scale-proof contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2`
  Status: `done`
  Goal: `Implement deterministic architecture-scale workload generation and stage-local correctness oracles.`
  Acceptance: `Generate bounded named workloads from the selected contract across HIAL/VIAL/bridge/execution dimensions with stable identities and seeded content; prove parse/type/bind/plan/emission invariants and deterministic bytes without requiring external runtime execution; publish no support claim before measurement.`
  Verification: `Clean predecessor 62979adc4 closes transcript-limit decision reconciliation before automation. Completed leaves implement the immutable catalog/staging foundation and canonical semantic, bridge, execution, checking-state, backend-emission, runtime-stream, and balanced revision-2 families. Final .17.2.7.3 derives the closed fifteen-runtime-plus-one-balanced ownership partition, embeds every authoritative child report, reproduces the complete gate independently, and preserves exact applicability and nonclaims. Every generated input, plan, structural artifact graph, report, and repository-volume staging route is deterministic and fail closed. No external runtime, public support, performance, capacity, or reached-boundary claim is added; .17.3 retains measurement ownership.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2: activate deterministic workload generation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.1`
  Status: `done`
  Goal: `Implement the immutable version-1 workload specification, catalog, identity, deterministic payload, and repository-local staging foundation.`
  Acceptance: `Provide one fail-closed public construction boundary for fsmgen.vial_architecture_scale_workload.v1: exact schema fields/enums/counts, fixed seed 1701, stable ordinal naming, existing SHA-256 counter/rejection payload semantics, canonical JSON plus ordered input-digest identity, path-independent deterministic reruns, defensive immutable reports, explicit nonclaims, and repository-derived same-volume staging with exact owned cleanup. Catalog all six orthogonal families, every selected level, balanced_portable_v1, backend/tool selectors, applicable stage oracles, and exact accepted/rejected specifications without forging downstream IR/artifacts or claiming capacity. Add focused positive, mutation, determinism, locality, and cleanup tests plus synced user documentation.`
  Verification: `Clean activation commit 49b6e1ba4 owns the foundation. Decision 0057 closes the selection-time byte-axis gap with cap/16 and cap/4 source candidates, whole-valid-record excess, bounded source-only envelopes, genuine backend-output rules, exact logical tool selectors, and unchanged nonclaims. FSM::VIAL::ArchitectureScaleWorkload ships one closed defensive catalog/construction/staging boundary with exact schema fields, six families plus balanced_portable_v1, all 250 axis/level combinations, fixed seed 1701, shipped SHA-256 counter/rejection payloads, eight-digit names, canonical path-sorted input identity, role/path/size rejection, canonical-construction revalidation, same-volume staging, concurrent collision rejection, and exact success/failure cleanup. The first cleanup regression exposed an incorrect local File::Path error-collector reference; the exact test-owned residue was removed, the implementation was corrected, and reruns leave no vial-scale stage. An independent probe finds the same pre-existing defect in ArtifactTransaction; proposed .17.9 durably owns that separate public-path repair. Module/test syntax passes; focused/adjacent VIAL regression reports All tests successful at Files=5/Tests=38; all 52 mdBook chapters test and the rendered foundation is present in a repository-local 88-file build removed exactly. Maintained-reference authority accepts 0 files/+78 lines/+3,685 bytes. Task/Knowledge Map/Memory/staged acceptance/doctrines pass with no scale staging, mdBook, probe, .bin, or .log residue. No parser, SemanticIR, bridge, ExecutionIR, emitter, runtime, capability, support classification, performance budget, or scale capacity claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.1: build deterministic workload foundation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.2`
  Status: `done`
  Goal: `Generate semantic-catalog workloads through the canonical parser and validator with exact semantic oracles.`
  Acceptance: `Construct every selected semantic_catalog_v1 axis from the shared specification without padding or forged IR; prove exact counts, IDs, spans, references, types, authored ordering, reports, literal-repeat pre-materialization limits, byte boundaries, deterministic source/format reruns, earliest-cap diagnostics, and cleanup.`
  Verification: `FSM::VIAL::ArchitectureScaleSemanticCatalog constructs all 70 semantic axis/level specifications as ordinary source and evaluates them only through Parser/SemanticBuilder. Reusable oracles prove exact semantic counts, globally unambiguous named IDs, in-bounds spans, internal reference/type closure, authored order, independent reports, projection/format determinism, earliest limit diagnostics, and staging cleanup. Width-4096 referenced enum payloads populate exact byte boundaries without comments or blank padding. The exact opt-in RAM-guarded proof passes at Files=1/Tests=4 in 359 seconds. The ID oracle root-caused fixture-only expectation/handle/fiber IDs introduced by be9c741630; decision 0058 and focused t1550 now scope action-local identities correctly. Decision 0059 records the unchanged 65,536 expanded-action cap as earlier authority for repeat qualification/limit levels and routes any repair to .17.4. Deterministic native-UVM, portable-VHDL, OSVVM, and exact GHDL qualification snapshots are regenerated through their canonical workflows after the plan identity changes. The final guarded impacted suite passes at Files=21/Tests=140 in 221 seconds, all 52 mdBook chapters test, the repository-local build contains 88 files/18,392,884 bytes before exact removal, and task/Knowledge Map/Memory/live-document/staged-doctrine gates pass. No capability/support/performance/capacity claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.2: generate canonical semantic scale workloads`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3`
  Status: `done`
  Goal: `Generate bridge-fanout workloads through canonical HIAL routes with exact manifest oracles.`
  Acceptance: `Construct each bridge_fanout_v1 axis through shipped direct-IAL0/direct-IAL1 or reviewed IAL2 routing as selected; prove normalized counts, immutable IDs/data, source/review identity, complete resolution/mapping/bindings, byte-equal manifests/reports, earliest-cap diagnostics, IAL2 bypass rejection, and cleanup.`
  Verification: `Children .17.2.3.1/.2 complete the selected bridge-fanout route. Decision 0060 reconciles the fixed AHB annotation with one closed qualification-only direct-IAL1 profile. ArchitectureScaleBridgeFanout constructs all 65 axis/level inputs as ordinary HIAL/VIAL source, and canonical evaluation proves exact or earliest-cap counts, complete maps/bindings/VIAL references, immutable byte-equal manifests/reports, the unchanged frozen AHB IAL2 route, IAL2 scale-profile rejection, deterministic reruns, and exact staging cleanup. Default and RAM-guarded exact t1602 pass; no protocol/support/performance/capacity claim is promoted.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3: activate canonical bridge-fanout generation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3.1`
  Status: `done`
  Goal: `Reconcile the selected bridge-fanout candidates with the fixed first AHB annotation profile before implementation.`
  Acceptance: `Root-cause the exact unreachable transaction/event/probe/residue axes from implementation, contract, and history; select a closed canonical direct-IAL1 qualification route or reduce the candidates honestly; preserve the exact AHB route and every support/nonclaim boundary; record the decision in the task tree, decision store, Knowledge Map, and mdBook without changing code or product behavior.`
  Verification: `History pins the fixed AHB implementation to 51434a2ae and later candidate selection to 0516f2c66. Exact source audit proves the annotated path projects only the fixed transaction/events/probe/residue family; a real frontend probe separately proves the selected qualification-only annotation parses, appears byte-equally in the scheduler report, and lowers to generated IAL0. Decision 0060 preserves the complete AHB/IAL2 contract and selects one closed direct-IAL1 qualification-only profile for .17.2.3.2, with ordinary parse/report/lower/builder authority, private scale-evidence capability only, earliest-cap truth, no opaque padding or forged input, and unchanged support/performance/capacity nonclaims. Decision index, manifest contract, mdBook, Knowledge Map fact, rationale ledger, containment authority, task/index/Memory, task integrity, documentation, book, and staged doctrines pass. No code or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3.1: select bridge-scale reachability contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3.2`
  Status: `done`
  Goal: `Implement the selected canonical bridge-fanout generator and exact manifest oracles.`
  Acceptance: `Implement only after .17.2.3.1 commits cleanly; exercise every reachable bridge_fanout_v1 axis through ordinary HIAL parsing/lowering and the shipped builder, prove the selected exact or earliest-cap outcomes, retain the AHB and IAL2 route invariants, and add focused/default/exact qualification tests plus synchronized user documentation.`
  Verification: `All 65 closed HIAL/VIAL constructions traverse ordinary parse/report/lower/Builder authority. Oracles prove exact or earliest-cap counts, unique IDs, total maps, closed bindings and checked VIAL references, immutable deterministic reports, review routes, and cleanup. Serialized reports are exactly 1/4/16 MiB; source-map gate is exactly 8,192, with larger valid shapes stopping at the earlier byte cap and 65,537 rejecting. Scale IAL2 fails closed and frozen AHB SHA-256 remains a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca. Default/exact t1602 pass at Files=1/Tests=5 in 17/122 seconds; adjacent t1551/t1600/t1601 pass at Files=3/Tests=17. Synced durable layers and final gates preserve all public support/performance/capacity nonclaims.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.3.2: generate canonical bridge-fanout scale workloads`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4`
  Status: `done`
  Goal: `Generate execution-graph workloads through the shipped binder with exact plan and replay oracles.`
  Acceptance: `Construct every execution_graph_v1 axis from successful generated SemanticIR and bridge inputs; prove topology/counts, stable IDs/ranks/types/maps, drive/sample/react/check and parallel semantics, keyed random decisions/replay, defensive reports, plan hashes, earliest-cap diagnostics, determinism, and cleanup without backend terms.`
  Verification: `Decision 0061 and completed selection child .1 reconcile all 13 nominal axes with canonical source, bridge, binder, random, structural, and 16-MiB plan authorities; decision 0072 and completed implementation child .2 preserve unreachable declared levels as exact envelope_unconstructible results; completed child .3 owns that selection. The caller-sealed generator publishes all 40 selected non-reference, non-scalar shapes across ten variable axes. The 25 catalog shapes outside selection are exactly 13 reference_v1 profiles plus four levels on each of selected_fixtures, selected_units, and selected_domains; focused t/1603 proves every one fails closed rather than presenting an unfinished frontier. The complete RAM-guarded t/1600-t/1628 family passes at Files=29, Tests=135 in 1,114 seconds, with exact cleanup and every public support/performance/capacity nonclaim preserved.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2: qualify complete execution-graph family`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.1`
  Status: `done`
  Goal: `Reconcile every selected execution-graph axis with canonical source, bridge, binder, replay, and earliest-cap reachability before implementation.`
  Acceptance: `Audit all 13 execution_graph_v1 axes and five levels against ordinary VIAL source construction, canonical SemanticIR and bridge production, the shipped ExecutionBuilder and ExecutionRandom APIs, structural and serialized-plan limits, memory-safe construction envelopes, and the fixed AHB reference. Prove representative routes where inspection is insufficient; select exact accepted or earlier-cap outcomes, deterministic random-attempt construction, and any closed qualification-only bridge profile needed; preserve every public support/nonclaim boundary in a decision, Knowledge Map fact, mdBook, and task evidence without changing product behavior.`
  Verification: `Decision 0061 selects the complete 13-axis/five-level route and earliest-cap matrix. History and a real binder probe prove that decision-0060 bridge qualification is correctly rejected by the public execution allow-list, so public planning remains unchanged and .17.2.4.2 must add only a caller-sealed scale-generator admission. Frozen AHB inputs reach exact scenarios, operation, fiber, live-fiber, source-map, random-attempt, and plan-byte representatives; plain direct IAL1 reaches 512 execution types; endpoint-only 2,048 bindings hit the earlier 16-MiB bridge report, selecting the compact scale-event route for that gate. RAM-guarded probes accept 4,096 scenarios, 16,384 live fibers, exactly 1,000,000 attempts, and exact 1/4/16-MiB plans; their one-over forms reject at stable authoritative boundaries. The selected matrix records semantic, VIAL-source, bridge event/type, execution structural, random exhaustion, or serialized-plan dominance without host exhaustion or forged IR. RAM-guarded execution/foundation/bridge regression passes 3 files/18 tests; documentation paths pass 1 file/2 tests; live ceiling/reference authorities pass 2 files/12 tests; Knowledge Map reports 1,107 facts/5,743 questions/5,909 occurrences/119 shards; mdBook test/render, task integrity, live containment, diff, and staged doctrines pass. No product behavior, support, performance, or capacity claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.1: select execution-scale reachability`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2`
  Status: `done`
  Goal: `Implement the selected canonical execution-graph generator and exact plan/replay oracles.`
  Acceptance: `Implement only after .17.2.4.1 commits cleanly; construct every reachable execution_graph_v1 axis through ordinary VIAL parsing, canonical bridge production, and the shipped binder; prove the selected exact or earliest-cap outcomes, structural topology and logical-time invariants, generated/replayed decision equality, immutable byte-equal reports and plan hashes, hostile-input rejection, deterministic reruns, and exact repository-local staging cleanup with default and RAM-guarded qualification tests plus synchronized user documentation.`
  Verification: `ArchitectureScaleExecutionGraph owns all 40 selected shapes across ten variable axes, with every level frozen by t/1603-t/1628 exact source, SemanticIR, bridge, workload, plan, diagnostic, mutation, rerun, caller-seal, and earliest-authority evidence. Four axes reach their nominal cap; earlier semantic, bridge, serialized-plan, construction-envelope, or preflight authorities remain explicit results and never become support or capacity. Decision 0072 governs eight source-free unconstructible levels across bindings, execution types, and source maps, each with exact fixture diagnostics and measured whole-route alternatives routed to .17.4. The exact pre-partition reachability card remains reconstructible with all 47 answer keys preserved once. Final qualification freezes the completed selection boundary: 40 owned shapes, 13 reference_v1 profiles, and 12 fixed-scalar profiles; focused t/1603 passes at Files=1, Tests=3, and the complete RAM-guarded architecture family passes at Files=29, Tests=135 in 1,114 seconds. All project-local cleanup, documentation, Knowledge Map, task, containment, path, staged-acceptance, and doctrine gates pass.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2: qualify complete execution-graph family`
  Blocked by: `none`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.3`
  Status: `done`
  Goal: `Reconcile the decision-0061 binding, execution-type, and source-map authorities that measurement contradicts, and select what their remaining levels mean.`
  Acceptance: `Root-cause, from real construction and canonical evaluation rather than inspection, why every remaining bindings, execution_types, and source_map_records level above its owned frontier is decided by the workload's own 1,114,112-byte construction envelope instead of the product cap decision 0061 named. Measure each axis's genuine product boundary and the representation that reaches it, including whether any compact authoring form exists for event, type, and endpoint declarations as repeat exists for fibers and operations. Select one closed treatment: re-level these axes onto their measured product boundaries, retain the nominal levels as recorded construction-envelope rejections, or change the envelope - and state why the alternatives were rejected. A fixture bound must never be reported as a product limit. Record the choice in a decision record, the Knowledge Map, the mdBook, and this file, keeping every support, performance, and capacity nonclaim unchanged and changing no product behavior.`
  Verification: `Decision 0072 selects the treatment after real construction and canonical evaluation, not inspection. Every remaining level crosses the workload's own 1,114,112-byte envelope before any product stage - 1,933,429/3,866,741/3,866,800 HIAL bytes for bindings at 32,768/65,536/65,537, 2,413,815 for 65,536 types, 3,670,808/14,000,792/14,000,806 VIAL bytes for maps at 262,144/1,000,000/1,000,001 - and no compact form can help because repeat repeats actions while events, types, and endpoints are declarations with no repetition form in either public grammar. Binary search through the canonical route measured each axis's genuine boundary: 2,054 bindings accepted with 2,055 rejected by the bridge's 2,048-event cap at /events, 1,043 execution types accepted with 1,044 rejected by the 16,777,216-byte serialized manifest at /, and 46,294 source-map records accepted at a 16,777,026-byte plan with 46,295 rejected by the 16,777,216-byte plan cap at /plan - 32x, 63x, and 22x below the declared execution caps of 65,536/65,536/1,000,000. The selection keeps both the levels and the envelope unchanged, requires every unreachable level to report its declared cap, its earliest decider, and its measured route boundary, defines the envelope_unconstructible/not_constructed outcome with paired VIAL_SCALE_LIMIT_INTERACTION and VIAL_SCALE_ROUTE_BOUNDARY records, and routes the cross-layer cap inconsistency between VIALExecutionContract and HIALVIALBridgeContract to .17.4. Alternatives are recorded as rejected: re-levelling would delete the finding, and raising the envelope would trade a fixture bound for the product's own 1,048,576-byte parser cap without reaching the declared cap. Decision index, mdBook, fact card, task, and Memory carry the same numbers; .17.2.4.2 alone owns implementation. No product behavior, capability, support, performance, or capacity claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.3: select what an unreachable declared cap means`
  Blocked by: `none`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5`
  Status: `done`
  Goal: `Generate checking-state workloads with exact stateful-service semantic oracles.`
  Acceptance: `Construct every checking_state_v1 axis with conservative execution topology; exercise rather than merely allocate models, scoreboard capacity, coverage, faults, and random decisions; prove final model state, scoreboard depth/drain, hit vectors, fault restoration, replay identity, normalized reruns, earliest-cap diagnostics, and cleanup without undeclared bins, crosses, or tuples outside an explicitly authored cross's static bin domain.`
  Verification: `Completed selection child .1 and decision 0073 define accepted-or-earliest-cap outcomes and a provider-free packed-state proof for all eight axes. Completed implementation child .2 constructs every selected level through ordinary VIAL and canonical SemanticIR, checked-AHB bridge, and ExecutionIR producers, then checks exact model state, complete-transaction scoreboard drain, authored coverage vectors, fault restoration, and keyed generation/replay. Final t/1635 freezes the exact 32-selected/eight-reference partition, byte-equal reports, hostile-caller rejection, explicit product nonclaims, and same-volume cleanup. The guarded default family passes at Files=7/Tests=36 in 166 seconds; the complete opt-in high-count matrix passes at Files=5/Tests=27 in 593 seconds under the 4,096-MiB guard. No parser, IR, backend, runtime, public capability/support, performance, or capacity contract changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.7: qualify complete checking-state family`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.1`
  Status: `done`
  Goal: `Select canonical reachability and an executable proof method for every checking-state axis before generator implementation.`
  Acceptance: `Audit all eight checking_state_v1 axes and five levels against ordinary VIAL source construction, SemanticBuilder and ExecutionBuilder limits, execution-plan representation, stateful model/scoreboard/coverage/fault/random semantics, normalized result authority, construction envelopes, and repository RAM/time guards. Prove representative routes where inspection is insufficient; select exact accepted or earliest-cap outcomes and a bounded executable method for the two one-million-record levels that exercises semantic state rather than merely allocating declarations. Record the selection in a decision, Knowledge Map fact, mdBook, and task evidence without changing product behavior, admitting undeclared bins/crosses/tuples beyond an authored static cross domain, or borrowing backend-runtime or support claims.`
  Verification: `Decision 0073 closes the complete eight-axis/five-level audit. Canonical RAM-guarded probes accept model instances through 4,096, scalar cells through 65,536, scoreboard instances through 4,096, capacity through 1,000,000, coverpoints through the 8,192 qualification, static coverage materialization through 1,000,000, faults through 4,096, and the 1,024 random gate; each adjacent reachable excess returns its exact semantic or execution-resource diagnostic. Coverpoint limit/excess sources are envelope-unconstructible and carry the separately measured 9,524/9,525 parser boundary. Compact random source parses at 32,768/65,536/65,537, while the plan route accepts 8,440 at 16,775,415 bytes and rejects 8,441 at the 16,777,216-byte cap; the full 32,768 route returns the same diagnostic, 65,536 is preflight-dominated by it, and 65,537 reaches its count cap. The selected provider-free evaluator consumes caller-sealed canonical IR, uses a 4,000,000-byte packed payload FIFO to enqueue/match/drain one million complete scoreboarding transactions, and byte-compares a 125,000-byte million-bit coverage vector. A 62,841-byte source proves exact million coverage via an authored 999-by-999 static cross plus one bin; 62,870 bytes reaches 1,000,001 and is rejected at /coverage. Decision 0073 refines 0055's impossible explicit-tuple-list sentence to the older shipped contract: an authored cross's complete static domain is the product of its explicitly authored point bins, and no backend may invent anything outside it. Trace/result/backend machinery remains excluded as a semantic oracle. The decision, fact card, mdBook, task/index, Memory, containment authority, and doctrine evidence agree; temporary probes were removed exactly.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.1: select packed checking-state proof`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2`
  Status: `done`
  Goal: `Implement the selected canonical checking-state generator and exact stateful-service oracles.`
  Acceptance: `Implement only after .17.2.5.1 commits cleanly; construct every selected checking_state_v1 axis through ordinary VIAL parsing and canonical SemanticIR, bridge, and ExecutionIR producers; execute the selected bounded reference semantics; prove exact final model state, scoreboard maximum/final depth and drain, coverage hit vectors, fault activation/restoration, keyed decisions and replay, normalized reruns, earliest-cap diagnostics, hostile-input rejection, determinism, and repository-local cleanup with default and RAM-guarded qualification tests plus synchronized user documentation.`
  Verification: `Decision 0073 closes reachability before code. Foundation .1 supplies the caller-sealed canonical boundary and closed schemas. Model .2, scoreboard .3, coverage .4, fault .5, and random/replay .6 own all 32 selected shapes and execute their exact bounded state semantics, including the one-million-entry FIFO drain and one-million-bit coverage vector. Final qualification .7 proves the complete eight-axis/five-level partition, deterministic construction/evaluation bytes, hostile-input rejection, exact same-volume cleanup, and unchanged product nonclaims. Default t/1629-t/1635 and the full opt-in t/1630-t/1634 matrix pass under the repository RAM guard.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.7: qualify complete checking-state family`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.7`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.1`
  Status: `done`
  Goal: `Implement the caller-sealed checking-state construction and provider-free evaluation foundation.`
  Acceptance: `Add one immutable checking-state generator/evaluator boundary that derives selected specifications from the common workload catalog, accepts only ordinary VIAL source plus the exact checked-AHB anchor, produces SemanticIR/bridge/ExecutionIR only through canonical producers, and validates content-addressed construction/evaluation reports defensively. Define closed packed-state and outcome schemas, deterministic rerun identity, repository-local staging cleanup, reference/non-owned rejection, mutation/unknown-level/caller-seal negatives, and explicit capability/support/performance/capacity nonclaims without owning an axis level yet.`
  Verification: `New FSM::VIAL::ArchitectureScaleCheckingState publishes an empty owned-shape set, rejects reference_v1 and every non-owned/unknown shape, and admits a selected source candidate only from the exact same package. That private boundary accepts only ordinary VIAL text and the frozen 1,326-byte checked-AHB source, derives the selected model_instances/32 candidate specification from ArchitectureScaleWorkload, and regenerates the complete content-addressed construction before every build/evaluation. The canonical Parser, IAL2-via-generated/reparsed-IAL1 bridge, and public ExecutionBuilder independently reproduce exact SemanticIR 00dce649…, bridge a4565d40…, ExecutionIR 5f04ca97…, plan 1a3b97f4…, and rerun ceefc4f3… identities; the 44,467-byte foundation plan is explicitly accepted_not_axis_evaluated, carries no axis evidence, and does not claim the requested count. Closed v1 packed-state, outcome, oracle-evidence, claims, metrics, and stage schemas freeze unknown-state rejection, a complete-transaction uint32 FIFO capped at 1,000,000/4,000,000 bytes, and an independently compared coverage vector capped at 1,000,000/125,000 bytes. Direct/private-bypass, reference/non-owned/unknown-level/key, HIAL/source/construction/evaluation/provider mutation, defensive-copy, and exact successful/failed same-volume staging-cleanup negatives pass in t/1629. Focused and adjacent guarded regression, task/Knowledge Map/book/relative-path/live-reference/staged-doctrine gates, and exact generated-output cleanup pass with no product or support claim change.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.1: establish checking-state evaluation foundation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.2`
  Status: `done`
  Goal: `Implement model-instance and scalar-model-state checking ladders.`
  Acceptance: `Author every selected model instance/cell level, update and read every accepted cell through the provider-free evaluator, prove exact packed initial/final values and event triggers, and return only the exact /models over-limit diagnostic for adjacent excesses with deterministic rerun, mutation, cleanup, and synchronized documentation evidence.`
  Verification: `FSM::VIAL::ArchitectureScaleCheckingState now publishes exactly eight owned shapes across the complete model_instances and scalar_model_state_cells ladders. Ordinary VIAL source reuses one u8 zero-to-one counter definition for 32/1,024/4,096 instances; the scalar ladder uses 32 instances of 16/1,024/2,048 cells, plus one separately defined singleton only for 65,537, keeping every source within the 1,114,112-byte construction envelope. Every accepted level traverses canonical Parser, checked-AHB bridge, and public ExecutionBuilder twice; the provider-free oracle validates the exact event binding and `+ 1` rule, synthesizes one accepted-event occurrence per instance, initializes, commits, and reads every cell, and byte-compares independently derived all-zero/all-one packed vectors. Gate digests are frozen; the guarded 1,024/4,096-instance and 32,768/65,536-cell sweep passes in 136 seconds. Both adjacent excesses return only the complete canonical VIAL_EXECUTION_LIMIT_ERROR at /models, publish no ExecutionIR/plan identity, and validate through deterministic rejection reruns. Source/evaluation/hostile-known-mask mutation, closed-schema, defensive-copy, nonclaim, and same-volume success/failure cleanup proofs pass in t/1629-t/1630. No scoreboard, coverage, fault, random/replay, backend, runtime, capability, support, performance, or capacity behavior is activated.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.2: implement packed model checking ladders`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.3`
  Status: `done`
  Goal: `Implement scoreboard-instance and declared-capacity checking ladders.`
  Acceptance: `Exercise enqueue/match/drain on every selected scoreboard instance and the packed one-million-entry capacity program; prove exact complete-field comparison, maximum/final expected and actual depths, zero pending entries, mismatch/overflow/corruption rejection, semantic capacity excess, deterministic rerun, cleanup, and documentation without representing the million level as one million plan operations.`
  Verification: `Clean activation predecessor f41166cea owns this implementation. FSM::VIAL::ArchitectureScaleCheckingState now publishes all eight scoreboard-instance/declared-capacity shapes as compact ordinary VIAL and traverses canonical Parser, checked-AHB bridge, and public ExecutionBuilder twice for every accepted level. The instance ladder reuses one capacity-one in-order definition at 32/1,024/4,096 instances; the capacity ladder uses one definition/instance at 4,096/262,144/1,000,000. Its provider-free oracle stores exactly four varying payload bytes per entry, reconstructs and compares all six transaction fields, proves ordered enqueue/observe/match/drain, reaches exact maximum expected depths, drains both queues to zero, and rejects deliberate mismatch, overflow, byte corruption, and hostile policy mutation. The one-million limit performs 6,000,000 comparisons over 4,000,000 bytes with frozen digest a515ca39…. Instance 4,097 returns only VIAL_EXECUTION_LIMIT_ERROR at /scoreboards with semantic/bridge identities; capacity 1,000,001 returns only parser VIAL_LIMIT_ERROR at /packages/0/scoreboards/0/capacity with no stage identity. Source/report mutation, deterministic rerun, closed schema, explicit nonclaims, and same-volume success/failure cleanup pass. Default t/1629-t/1631 pass at Files=3/Tests=17; the complete scoreboard sweep passes under the 4,096-MiB RAM guard. No parser, IR, execution-plan, backend, runtime, capability, support, performance, or capacity contract changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.3: implement packed scoreboard checking ladders`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.4`
  Status: `done`
  Goal: `Implement coverpoint and static-bin/cross-tuple checking ladders.`
  Acceptance: `Author every selected reachable coverage level under decision 0073's explicit static-domain contract; byte-compare exact ordered packed hit vectors including the one-million all-hit vector; implement decision-0072 coverpoint envelope results plus the 9,524/9,525 route record; prove illegal/ignore/mutation/order and 1,000,001 resource rejection, deterministic rerun, cleanup, and synchronized documentation.`
  Verification: `ArchitectureScaleCheckingState now owns all eight coverpoint/static-domain shapes. Gate and qualification coverpoints and 4,096/262,144/1,000,000 static entries traverse ordinary Parser, the checked-AHB bridge, and public ExecutionBuilder twice. The oracle independently byte-compares an LSB-first hit vector and streams authored-order identities; the million case is exactly 1,999 bins plus 998,001 tuples in 62,841 source bytes and 125,000 packed bytes. Selected 65,536/65,537 coverpoint sources report source-free envelope_unconstructible outcomes with both decision-0072 records and the exact 9,524/9,525 parser boundary. One additional 29-byte bin returns only the canonical /coverage execution diagnostic. Illegal/ignore/bit/order, hostile structure, source/report mutation, deterministic rerun, and same-volume success/failure cleanup proofs pass. Default t/1629+t/1632 passes at Files=2/Tests=13 in 18 seconds; exact t/1632 passes at Files=1/Tests=7 in 45 seconds under the RAM guard. Fault sibling .5 is now separately active; random/replay and final qualification remain proposed. No product, backend, runtime, support, performance, or capacity claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.4: implement packed coverage checking ladders`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.5`
  Status: `done`
  Goal: `Implement the fault activation/restoration checking ladder.`
  Acceptance: `Arm, apply, expire, and prove restoration for every selected fault with exact target/original/substituted values and stable order; prove reinjection/overlap/mutation and 4,097-resource rejection, deterministic rerun, cleanup, and synchronized documentation without borrowing backend runtime behavior.`
  Verification: `Clean activation predecessor e43ecc2e5 grants this leaf sole implementation ownership. ArchitectureScaleCheckingState now publishes all four fault shapes as ordinary compact VIAL and traverses canonical Parser, checked-AHB bridge, and public ExecutionBuilder twice. Accepted 32/1,024/4,096 levels validate the exact transaction/field/domain target, known three-bit substitution, one-drive-interval lifetime, and stable declaration order; the provider-free oracle arms, applies, expires, and restores every fault while streaming four length-delimited lifecycle records per declaration into independently reconstructed order and transition digests. It retains only digests and endpoint witnesses, rejects armed reinjection, active overlap, substitute mutation, declaration-order mutation, source/report mutation, and proves same-volume cleanup after success and failure. The adjacent 4,097 source returns only the exact VIAL_EXECUTION_LIMIT_ERROR at /faults with semantic/bridge but no downstream identity. Default t/1629-t/1633 passes at Files=5/Tests=29 in 97 seconds; exact t/1633 passes at Files=1/Tests=5 in 21 seconds under the 4,096-MiB RAM guard. Random/replay child .6 is complete; final qualification remains proposed. No parser, IR, backend, runtime, public API, capability/support, performance, or capacity contract changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.5: implement fault lifecycle checking ladder`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.6`
  Status: `done`
  Goal: `Implement random-occurrence, replay, and plan-dominated checking outcomes.`
  Acceptance: `Author the compact Boolean occurrence representation, prove the 1,024 accepted gate's exact keyed values and generated/replayed identity, implement the full 32,768 qualification plan-cap result, the decision-0073 8,440/8,441 opt-in route boundary, preflight-dominated 65,536, and exact 65,537 occurrence-cap rejection; prove mutation/replay/rerun/cleanup and synchronized documentation.`
  Verification: `Clean activation predecessor 7990c13d7 grants this leaf sole implementation ownership. ArchitectureScaleCheckingState now owns all four random-occurrence shapes and emits bounded ordinary VIAL using 128 Boolean choices across real referenced scenario/choice pairs. The accepted 1,024 gate traverses canonical Parser, checked-AHB bridge, and public ExecutionBuilder twice, produces an exact 2,073,805-byte plan, generates every keyed value independently, and strictly replays a canonical manifest; origin-free generated/replayed decisions and plans compare byte-equal, while keyed-value and order mutations fail closed. The 32,768 route returns only the exact /plan diagnostic after all semantic occurrences are counted; 65,536 is explicitly preflight_dominated/not_materialized with no stage identity or selected-count claim; 65,537 returns only the exact /randomness/decisions diagnostic. The opt-in 8,440/8,441 adjacent route proves the 16,775,415-byte accepted plan and the next exact plan-cap rejection. Source/report/replay mutation, deterministic rerun, closed schema, explicit nonclaims, and same-volume success/failure cleanup pass. Default t/1629-t/1634 passes at Files=6/Tests=33 in 127 seconds; exact t/1634 passes at Files=1/Tests=4 in 467 seconds under the 4,096-MiB RAM guard. No parser, IR, backend, runtime, public API, capability/support, performance, or capacity contract changes; final qualification remains proposed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.6: implement random replay checking ladder`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.7`
  Status: `done`
  Goal: `Qualify and close the complete checking-state generator family.`
  Acceptance: `Prove the exact selected-versus-reference ownership partition for all eight axes and five catalog levels; run every default gate plus bounded high-count and opt-in route evidence under the repository RAM guard; prove byte-equal reports, exact same-volume cleanup, hostile caller rejection, Knowledge Map/mdBook/task continuity, and every support/performance/capacity nonclaim before marking .17.2.5.2 and .17.2.5 done.`
  Verification: `New t/1635 derives the common catalog and proves exactly eight axes times five levels partition into 32 owned non-reference shapes and eight rejected reference_v1 records. Every gate independently constructs and evaluates byte-identical canonical reports, selects its exact semantic oracle/count, validates defensively, retains all qualification-only product nonclaims, and removes its content-addressed repository-volume stage after success. Runtime-result injection, mutation on every axis, support-claim report forgery, and failed-consumer residue all fail closed. The complete guarded default t/1629-t/1635 family reports All tests successful at Files=7, Tests=36 in 166 seconds. The full opt-in exact t/1630-t/1634 matrix reports All tests successful at Files=5, Tests=27 in 593 seconds under the 4,096-MiB guard, covering 65,536 cells, one-million-entry scoreboard/coverage state, 4,096 faults, and the 8,440/8,441 plan boundary. Artifact census finds no scale stage or generated book residue; every capability/support/performance/capacity/backend/runtime nonclaim remains explicit.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.7: qualify complete checking-state family`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6`
  Status: `done`
  Goal: `Generate backend-emission workloads through each negotiated canonical emitter with structural artifact oracles.`
  Acceptance: `Consume proved execution graphs for portable SystemVerilog, portable VHDL, OSVVM, and native-UVM emission profiles; prove exact inventory/order/relative paths, source identity and map closure, stable generated identifiers, static checks, byte-equal reruns, earliest-cap diagnostics, atomic no-artifact-before-negotiation behavior, and cleanup without external runtime qualification.`
  Verification: `Decision 0075 selected one checked-AHB anchored operation recipe and profile-local outcomes. Repair parent .2 and generator parent .3 are complete. The terminal family watcher derives all twenty catalog outcomes independently, freezes exactly thirteen emitted graphs and seven atomic rejections, reevaluates one reference plus one adjacent rejection per profile, and preserves every authority, oracle, defensive-report, nonclaim, and same-volume cleanup boundary. CI inventory passes Files=1/Tests=12; the 4,096-MiB guarded t/1640-t/1650 matrix passes Files=11/Tests=98 in 600 seconds; and the native-UVM gallery remains exact at nine source snapshots, two review evidence files, 75 map entries, fourteen static checks, and five review-closure checks. No external runtime, public API, capability/support, performance, capacity, or product claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6: activate backend-emission generation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.1`
  Status: `done`
  Goal: `Select exact upstream execution shapes, structural axes, reachability, and stage-local oracles for every backend-emission profile.`
  Acceptance: `Audit decisions 0055/0056, the common workload catalog, all proved execution-graph shapes, the portable-SystemVerilog, portable-VHDL, OSVVM, and native-UVM emitters and validators, their focused tests/galleries, publication boundaries, and current Knowledge Map/book truth. Execute the reference graph and representative scale routes where inspection is insufficient. For each backend and level, select the exact canonical upstream axis/level or profile-specific recipe, emitted-source/artifact/map/static-check authority, generated-byte meaning, limit and first representable excess, negotiation/provider prerequisites, deterministic identity, atomicity/cleanup proof, and nonclaims. Reconcile ambiguous or false existing authorities in a decision and route every code/config repair to .17.2.6.2 and implementation to .17.2.6.3 without changing behavior in selection.`
  Verification: `Decision 0075 selects the checked-AHB anchored response-expectation operation total T as the exact portable recipe and freezes every accepted or earliest-authority outcome. Fresh canonical probes measure portable SV at T=21/1,024/4,096/6,319 as 164,093/2,803,325/10,910,333/16,776,830 source bytes and 54/1,057/4,129/6,352 maps; T=6,320 rejects atomically. Portable VHDL measures T=21/128/512 at 116,560/174,929/386,897 bytes, 59/166/550 maps, and twenty checks. Unchanged renderer evidence gives adjacent T=29,508/29,509 sizes 16,776,739/16,777,307; actual excess rejection is already exact, while the accepted proof waits on the diagnosed per-operation whole-metadata-scan repair. OSVVM adds one fixed 4,351-byte adapter to six portable sources; its selected complete maps translate every portable entry plus seven adapter entries instead of the defective current six coarse placeholders plus seven adapter entries. Native UVM T=22 proves silent shape loss: fixed 138,345-byte sources contain no added expectation although one coarse map association does, so T=22 becomes the adjacent negotiation rejection and higher levels are preflight-dominated. Exact 128/129 source-identifier probes produce generated maxima 131/142/142/154 under the separate 255-byte backend limit. Four behavior defects and catalog drift are routed as five required .2 repair slices; .3 remains blocked. Focused pre-selection emitters pass Files=4/Tests=30, probes are pure, and no product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.1: select backend-emission scale routes`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2`
  Status: `done`
  Goal: `Repair the selected backend-emission catalog and contract authorities before generator code consumes them.`
  Acceptance: `Implement only after .17.2.6.1 commits cleanly. On activation, decompose five children in this order: linear portable-VHDL validation and accepted-boundary proof; sealed reusable OSVVM provider verification; translated OSVVM source-map closure; native-UVM closed selected-matrix negotiation; then exact catalog/support authority alignment and repair-family qualification. Each child adds RED controls and exact reruns. Align decision, catalog, emitters/validators/manifests, support contracts, tests, Knowledge Map, and mdBook; fail closed on unknown or contradictory authority fields; and close the repair family before .17.2.6.3 activates. Change no runtime path, public API, capability/support, performance, or capacity claim beyond decision 0075's explicitly selected behavior repairs.`
  Verification: `All five ordered repairs are complete. Portable VHDL uses one-pass metadata/source-line indexes through its exact accepted boundary; OSVVM reuses one defensive exact provider result only inside a source-bound callback evaluation; the wrapper validates then translates every portable source-map entry; native UVM admits only its exact selected 21-operation review shape; and one closed authority source now aligns the workload catalog with VHDL/native-UVM discovery. The 4,096-MiB guarded repair-family collection passes Files=18/Tests=7,248 in 124 seconds with exact cleanup and unchanged runtime/support/performance/capacity nonclaims. Generator `.17.2.6.3` may activate only after the clean `.5` commit.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2: activate backend-emission repairs`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.1`
  Status: `done`
  Goal: `Linearize portable-VHDL metadata validation and prove the selected accepted source boundary.`
  Acceptance: `Add focused RED controls for the validator's four fixed whole-metadata census scans plus three whole-text scans per operation and the emitter source map's one full split/line scan per operation anchor. Replace them with bounded single-pass metadata and line-anchor indexes without weakening exact artifact, metadata, map, source-identity, or structural-check rejection, and prove byte-identical T=21/128/512 output plus canonical T=29,508 acceptance at 16,776,739 source bytes/29,546 maps inside the selected ceiling. Preserve exact T=29,509 VIAL_BACKEND_LIMIT_EXCEEDED rejection before partial graph publication, deterministic rerun, identifier/path safety, and all explicit runtime/support/performance/capacity nonclaims.`
  Verification: `Source-shape controls first fail on the validator's operation-loop metadata rescans, the emitter's per-operation _find_line split/scan, and its per-map line-count/column rescans. One metadata index and one line-anchor/end-column index per source make all three controls pass while retaining exact duplicate/missing-anchor rejection. Ordinary Parser/PlanBuilder/emitter reruns preserve exact T=21/128/512 outputs at 116,560/174,929/386,897 source bytes and 59/166/550 maps, with 17 artifacts, six sources, and twenty passing checks each. The 4,096-MiB guarded exact route accepts T=29,508 twice at 16,776,739 source bytes/29,546 maps and rejects T=29,509 with only exact VIAL_VHDL_BACKEND_LIMIT_EXCEEDED at /artifacts and no partial graph; the complete exact test passes in 42 seconds. Focused portable-VHDL suites pass at Files=3/Tests=20, and no runtime, support, performance, or capacity claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.1: linearize portable VHDL emission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.2`
  Status: `done`
  Goal: `Make exact OSVVM provider verification reusable within one sealed backend evaluation.`
  Acceptance: `Add RED evidence for repeated full provider verification, introduce one exact sealed provider-verification result reusable only for the matching provider/source identity within one emission evaluation, reject stale or mismatched evidence, and prove unchanged generated bytes, diagnostics, standalone provider qualification, deterministic rerun, and failure cleanup.`
  Verification: `The focused RED test first bails out because no provider-evaluation boundary exists, while source/origin audit shows every direct emission enters the complete 14-repository/2,122-file verifier. with_provider_evaluation now verifies the exact repository-local root once, stores a defensive provider result plus its canonical source/evidence identity behind one lexical capability, and deletes that capability on callback success or failure. Matching evaluation-local emits receive independent defensive clones; mismatched dependency roots, caller-forged objects, and handles retained after every callback outcome return only VIAL_OSVVM_PROVIDER_EVALUATION_ERROR and no artifacts. Standalone emit still verifies independently. The guarded exact collection passes at Files=3/Tests=48, including fresh byte-identical combined qualification and exact cleanup; after adding the closed-consumer-result cleanup negative, t/1642 independently passes Files=1/Tests=46. An immediate guarded collection rerun is correctly invalidated at 88.2% host occupancy against the fixed 88% ceiling; the read-only process census identifies two concurrent off-scope pgen rustc processes at 2,538,080/2,061,312 KiB and no FSMGen residue. No emitted bytes, provider qualification, runtime, support, performance, or capacity claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.2: seal OSVVM provider evaluation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.3`
  Status: `done`
  Goal: `Translate complete portable-VHDL source maps into the OSVVM wrapper graph.`
  Acceptance: `Add RED evidence for the six coarse whole-file placeholders, preserve every detailed portable source-map entry under its OSVVM artifact identity, retain the seven exact adapter maps, and prove complete ordered closure, byte-identical source reuse, mutation rejection, deterministic rerun, and unchanged structural checks.`
  Verification: `The RED comparison first found six coarse wrapper placeholders against 59 independently emitted portable entries, for defective 13-entry rather than selected 66-entry closure. Revision 3 validates the portable map's closed schema, six source artifacts and digests, every path-derived identity, exact line/column span, unique membership, and complete coverage before translating each entry's path and identity; the seven adapter entries remain first and unchanged. Identity mutation returns only VIAL_OSVVM_SOURCE_MAP_TRANSLATION_ERROR at /portable_foundation/source_map with no artifacts. The regenerated 16-artifact gallery reports seven sources, nine evidence artifacts, seven mappings, 66 maps, and twelve checks. Focused emission passes Files=1/Tests=11; the 4,096-MiB guarded exact OSVVM/GHDL/provider-evaluation collection passes Files=3/Tests=60 in 38 seconds with unchanged compiled VHDL, trace, result, parity, provider reports, and exact cleanup. Runtime, public API, capability/support classification, performance, and capacity claims do not change.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.3: activate OSVVM source-map translation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.4`
  Status: `done`
  Goal: `Close native-UVM negotiation over the selected review matrix.`
  Acceptance: `Add RED evidence for silent T=22 expectation loss, make negotiation admit only the exact selected T=21 reference shape, reject T=22 and every unsupported larger shape before artifact creation with one stable diagnostic, and preserve the selected ten-source/fourteen-check/75-map gallery, deterministic rerun, identifier safety, and native-runtime/support nonclaims.`
  Verification: `The genuine parser/PlanBuilder RED witness first emitted T=22 and T=128 as successful fixed 138,345-byte/75-map graphs, while renaming one selected expectation also passed the coarse 21-operation gate. Negotiation now requires selected_reference_operation_shape_v1 and checks the exact 21-operation sequence, 12/9 scenario partition, four total/three simultaneous fibers, resource count, and ten ordered expectation roles. T=22, T=128, and a different T=21 shape return one VIAL_UVM_BACKEND_UNSUPPORTED diagnostic at /negotiation with the same unsatisfied requirement and no artifacts, operation identity, manifest, source map, or residue. The exact reference remains 16 artifacts/10 SystemVerilog sources/138,345 source bytes/75 maps/14 checks, is byte-identical on rerun, keeps generated identifiers within 255 bytes, and retains every runtime/result/support nonclaim. Focused plus all native-UVM emission/review tests and CI inventory pass at Files=7/Tests=54.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.4: close native-UVM shape negotiation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.5`
  Status: `done`
  Goal: `Align exact backend-emission catalog/support authorities and qualify the repair family.`
  Acceptance: `Correct OSVVM source inventory and portable-foundation cap semantics, record native UVM's enforced source-map cap and exact selected matrix, fail closed on unknown or contradictory authority fields, and qualify all repaired profiles with focused plus guarded family reruns, synchronized Knowledge Map/mdBook/task truth, exact repository-local cleanup, and no new runtime, API, capability/support, performance, or capacity claim.`
  Verification: `The focused RED oracle first fails all four incomplete or ambiguous catalog authorities plus the stale OSVVM and incomplete native-UVM discovery projections. BackendEmissionAuthority now owns one exact defensively cloned four-profile set: portable SV names 3 source/8 total artifacts; portable VHDL names 6/17 plus 59 reference maps/20 checks; OSVVM separates six portable sources, one 4,351-byte adapter, seven total sources, 16 total artifacts, portable-only 16-MiB authority, 66 reference maps, and 12+20 checks; native UVM records 10/16 artifacts, 16-MiB/one-million-map enforced caps, and its exact 21-operation/75-map/14-check/25-mapping selection. Unknown, missing, obsolete, or contradictory fields fail closed. Focused catalog/capability regression passes Files=4/Tests=7,108; the guarded repaired-emitter family plus CI inventory passes Files=18/Tests=7,248 in 124 seconds with no residue. Runtime, API, support classification, performance, and capacity claims remain unchanged.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.2.5: align backend-emission authorities`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3`
  Status: `done`
  Goal: `Implement the selected canonical backend-emission generator and exact structural artifact oracles.`
  Acceptance: `Implement only after .17.2.6.1 and .17.2.6.2 commit cleanly; decompose per shared foundation and backend when required. Consume only caller-sealed proved execution graphs and canonical backend inputs; prove every selected profile/level's exact negotiation outcome, artifact inventory/order/relative paths, source identities and complete map closure, generated identifiers, structural checks, byte-equal reruns, earliest-cap rejection with no partial graph, defensive reports, repository-local staging and exact cleanup. Execute no external runtime and publish no support, performance, or capacity claim.`
  Verification: `The caller-sealed shared foundation, four ordered profile ladders, and terminal family qualification are complete. New t/1650 independently constructs the full four-profile/five-level catalog twice, proves the exact thirteen-emitted/seven-rejected partition, reevaluates one reference and adjacent rejection per profile, freezes applicability and profile-specific structural evidence, and rejects direct-helper bypass, construction/report mutation, support-claim forgery, and staging residue. The guarded t/1640-t/1650 generator/repair matrix passes Files=11/Tests=98 in 600 seconds. This is deterministic structural qualification only: no external runtime, family-level product report, public API, capability/support, performance, or capacity claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3: activate backend-emission generator`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.1`
  Status: `done`
  Goal: `Implement the caller-sealed backend-emission construction, evaluation-report, and repository-local staging foundation.`
  Acceptance: `Add one immutable backend-emission generator boundary that derives only selected catalog specifications, consumes exact checked-AHB inputs and caller-sealed canonical ExecutionIR, owns no backend shape yet, and validates content-addressed construction/evaluation reports defensively. Define closed outcome, artifact-oracle, and nonclaim schemas; deterministic rerun identity; repository-local staging cleanup after success and consumer failure; reference/non-owned/profile/source/report/caller-seal mutation negatives; and no external runtime or product claim.`
  Verification: `ArchitectureScaleBackendEmission accepts only the frozen 1,326-byte PPIF and 4,986-byte VIAL reference pair through a same-package qualification constructor, then independently reruns ordinary Parser and PlanBuilder production. Public construction owns zero of twenty catalog shapes and rejects caller-created ExecutionIR, unknown profiles/levels, external private-constructor calls, source mutations, construction mutations, evaluation mutations, and unknown report/provider fields. The closed report freezes workload b739891c…, evaluation e7d9a4e1…, rerun 172c0419…, all five canonical stage digests, two scenarios/21 operations/four fibers/three live fibers/39 maps, a 44,101-byte plan, and two backend inputs while explicitly denying negotiation, emission, runtime, artifact-graph, support, performance, and capacity claims. Success and intentional consumer failure stage only below .artifacts/tmp/vial-scale and remove the exact content-addressed directory. Focused foundation/workload/authority regression passes Files=3/Tests=15.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.1: seal backend-emission foundation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.2`
  Status: `done`
  Goal: `Implement the portable-SystemVerilog backend-emission ladder and exact structural oracles.`
  Acceptance: `Own selected T=21/1,024/4,096/6,319 portable-SystemVerilog routes and adjacent T=6,320 rejection through the shared foundation; prove exact ordered inventory, relative paths, three source identities, complete maps, generated identifiers, byte-equal reruns, 16-MiB earliest-cap atomicity, defensive evidence, and exact cleanup without external runtime or product claims.`
  Verification: `A RED watcher first found zero owned shapes and public construction rejected reference_v1. The completed caller-sealed PortableSV child now owns exactly five routes, renders the selected checked-AHB scale_response_zero repeat through ordinary Parser/PlanBuilder production, and independently emits each route twice. T=21/1,024/4,096/6,319 return exact 8-artifact/3-source graphs at 164,093/2,803,325/10,910,333/16,776,830 source bytes and 54/1,057/4,129/6,352 complete maps; T=6,320 returns only VIAL_BACKEND_LIMIT_EXCEEDED at /artifacts with no partial identity or graph. The closed oracle freezes all three source identities per accepted level, exact path/order/schema/map/manifest closure, the complete operation-ID set, a 113-byte observed generated-identifier maximum below the separate 255-byte cap, content-addressed reports, byte-equal reruns, defensive mutation rejection, and exact same-volume staging cleanup. The focused five-file collection passes Files=5/Tests=28 with no residue. No external tool/runtime, public API, capability/support, performance, capacity, or product claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.2: qualify portable SV emission ladder`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.3`
  Status: `done`
  Goal: `Implement the portable-VHDL backend-emission ladder and exact structural oracles.`
  Acceptance: `Own selected T=21/128/512/29,508 portable-VHDL routes and adjacent T=29,509 rejection through the shared foundation; prove exact ordered seventeen-artifact/six-source inventory, identities, 59-through-29,546 complete maps, twenty structural checks, generated identifiers, byte-equal reruns, earliest-cap atomicity, defensive evidence, and exact cleanup without external runtime or product claims.`
  Verification: `A RED watcher first found no portable-VHDL owned shape and public reference construction rejected. The completed caller-sealed PortableVHDL child now owns exactly five routes, uses the selected numbered source identity through ordinary Parser/PlanBuilder production, and independently emits each route twice. T=21/128/512/29,508 return exact 17-artifact/6-source graphs at 116,560/174,929/386,897/16,776,739 source bytes with 59/166/550/29,546 complete maps and all twenty static checks; T=29,509 returns only VIAL_VHDL_BACKEND_LIMIT_EXCEEDED at /artifacts with no partial identity or graph. The closed oracle freezes all six source identities per accepted level, exact path/order/schema/map/manifest closure, the complete operation-ID set, a 37-byte selected-ladder generated-identifier maximum below the separate 255-byte cap, content-addressed reports, byte-equal reruns, defensive mutation rejection, and exact same-volume staging cleanup. The guarded nine-file impacted collection passes Files=9/Tests=55 in 253 seconds. No external tool/runtime, public API, capability/support, performance, capacity, or product claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.3: qualify portable VHDL emission ladder`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.4`
  Status: `done`
  Goal: `Implement the OSVVM-qualified backend-emission ladder and exact structural oracles.`
  Acceptance: `Own selected T=21/128/512/29,508 OSVVM routes and adjacent portable-foundation T=29,509 rejection through the shared foundation and one callback-scoped exact provider evaluation; prove six byte-identical portable sources plus one fixed adapter, sixteen ordered artifacts, translated complete maps, structural checks, provider/source identity, byte-equal reruns, earliest-cap atomicity, defensive evidence, and exact cleanup without external runtime or product claims.`
  Verification: `A RED control first found the OSVVM shapes absent from the shared registry and public reference construction rejected. The completed caller-sealed OSVVM child now owns exactly five routes, delegates the selected numbered source recipe to portable VHDL, verifies the exact repository-local provider once per evaluation, and emits both canonical routes through one opaque callback capability. T=21/128/512/29,508 return exact 16-artifact/7-source graphs at 120,911/179,280/391,248/16,781,090 source bytes with 66/173/557/29,553 maps, seven adapter mappings, six byte-identical portable sources, six semantic guards, twelve wrapper checks, and twenty portable prerequisite checks; T=29,509 returns only VIAL_OSVVM_PORTABLE_FOUNDATION_ERROR at /portable_foundation with no partial identity, provider evidence, or graph. The oracle freezes provider commit/tree/manifest identity, all source hashes and ordered paths, adapter-first plus translated portable-map closure, complete operation IDs, generated identifiers, evidence/manifest encoding, byte-equal reruns, defensive mutation rejection, and same-volume staging cleanup. The 4,096-MiB guarded nine-file impacted collection passes Files=9/Tests=86 in 439 seconds. No external runtime, public API, capability/support, performance, capacity, or product claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.4: qualify OSVVM emission ladder`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.5`
  Status: `done`
  Goal: `Implement the native-UVM selected backend-emission route and fail-closed structural oracles.`
  Acceptance: `Own only the exact selected T=21 native-UVM review shape through the shared foundation; prove sixteen ordered artifacts, ten source identities, 75 complete maps, fourteen checks, 25 selected mappings, generated identifiers, byte-equal reruns, T=22/larger/changed-same-count pre-artifact rejection, defensive evidence, and exact cleanup without executing native UVM or publishing product claims.`
  Verification: `A RED control first found native-UVM ownership absent at index 15 and public reference construction rejected. The completed caller-sealed NativeUVM child now owns five public route outcomes while emitting only the exact selected T=21 review graph. Reference emission is independently byte-equal and freezes sixteen ordered artifacts, ten SystemVerilog sources/138,345 bytes, 75 bounded structural maps with six intentional operation associations, fourteen passing static checks, 25 selected mappings, seven review stages/five closure checks, ten source identities, a 49-byte selected generated-symbol maximum below 255, evidence/manifest closure, and unchanged parse/compile/runtime/result/manual-review nonclaims. Gate and all three later non-reference levels execute the same adjacent T=22 negotiation rejection with no partial graph; later levels are explicitly preflight-dominated/not-constructed. Independent T=128 and changed-same-count T=21 witnesses reject identically. Canonical-report mutation and success/rejection/consumer-failure staging fail closed and clean exactly. Native compatibility passes Files=7/Tests=45; the focused implementation passes Files=1/Tests=8; CI inventory passes Files=1/Tests=12; and the 4,096-MiB guarded repaired/generator family passes Files=10/Tests=94 in 467 seconds. No external runtime, public API, capability/support, performance, capacity, or product claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.5: qualify native UVM emission route`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.6`
  Status: `done`
  Goal: `Qualify the complete backend-emission profile family and close deterministic structural generation.`
  Acceptance: `Freeze the exact selected/reference/rejected profile-level partition, independent byte-equal reports, authority/oracle applicability, hostile caller and mutation rejection, same-volume success/failure cleanup, complete default plus guarded high-count matrices, repaired-emitter compatibility, CI inventory, synchronized durable truth, and unchanged runtime, API, capability/support, performance, and capacity claims; then close .17.2.6.3 and parent .17.2.6.`
  Verification: `The missing-family-watcher RED run failed before t/1650 existed. The completed test derives the four profiles and five catalog levels without a shadow family API, constructs all twenty outcomes twice, and freezes exactly thirteen emitted graphs plus seven atomic rejections. It reevaluates portable-SV reference/over, portable-VHDL reference/over, OSVVM reference/over, and native-UVM reference/gate; freezes each applicable oracle, structural metrics, diagnostics, content identity, byte-equal rerun, and nonclaims; rejects direct profile-helper access, injected or mutated reports, construction mutation, and support-claim forgery; and proves repository-volume staging cleanup after success, rejection, and consumer failure. Syntax passes; focused t/1650 passes Files=1/Tests=4 in 119 seconds; CI inventory passes Files=1/Tests=12; the guarded t/1640-t/1650 impacted matrix passes Files=11/Tests=98 in 600 seconds; and the native-UVM gallery check remains exact. No generator/emitter behavior, external runtime, family-level product report, public API, capability/support, performance, capacity, or product claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6.3.6: activate backend-emission family closure`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7`
  Status: `done`
  Goal: `Integrate runtime-stream construction and the balanced portable workload, then close deterministic generation proof.`
  Acceptance: `Construct runtime_stream_v1 inputs and semantic/result expectations without executing external tools; compose balanced_portable_v1 only after every orthogonal gate candidate passes; prove exact interaction counts, path-independent identities, deterministic inputs/stage reports, complete oracle applicability, nonclaims, same-volume cleanup, and a unified provider-free construction gate ready for .17.3 measurement.`
  Verification: `Completed .1 owns all fifteen provider-free runtime input/expectation shapes; completed .2 owns the caller-sealed revision-2 balanced source-to-portable-SystemVerilog structural route. Final .3 adds one closed aggregate that reconstructs those sixteen members from the frozen checked-AHB references, retains each complete child report and its construction/report/rerun/applicability/claim/nonclaim identities, and independently regenerates the whole aggregate. The focused watcher proves exact ownership, fail-fast report/source/caller mutation rejection, defensive results, and simultaneous dual-family repository-volume success/failure cleanup. No provider or external tool executes; runtime, trace, result, public API, support, performance, capacity, and reached-boundary claims remain false. The family is ready for separately activated .17.3 measurement.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7: activate runtime-balanced integration`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.1`
  Status: `done`
  Goal: `Implement caller-sealed provider-free runtime-stream construction and exact expected trace/result oracles.`
  Acceptance: `Consume the existing runtime_stream_v1 catalog for portable SystemVerilog, portable VHDL, and OSVVM across all five levels; derive canonical backend inputs only through completed structural generators; build deterministic compile/run/trace/result expectations without invoking an external tool; freeze reference, 10,000-record gate, 100,000-record qualification, and earliest-authority limit/over-limit specifications without claiming either structural boundary was reached; prove exact profile/tool/limit authority, identities, stage applicability, defensive reports, nonclaims, repository-volume success/failure cleanup, and focused RED-to-GREEN evidence.`
  Verification: `The honest first focused run failed because ArchitectureScaleRuntimeStream did not exist. The completed caller-sealed evaluator owns all fifteen three-profile/five-level catalog shapes, rebuilds the frozen HIAL/VIAL pair and canonical SemanticIR/bridge/ExecutionIR/backend-input/plan route twice, and publishes closed content-addressed compile/run/trace/result expectation reports. Exact Verilator 5.046, GHDL 6.0.0 LLVM-JIT, and OSVVM 2026.05+GHDL selectors, schemas, command authorities, 120/60/30-second limits, 8-MiB/64-MiB transcript limits, 8,000,002-record/64-MiB trace limits, checked reference, 10,000/100,000 semantic candidates, and limit/over-limit earliest-cap specifications are frozen without emitting backend artifacts, opening the OSVVM provider, executing tools/runtime, materializing trace/results, or claiming a reached boundary. Canonical regeneration rejects construction/report/support mutation; success and consumer-failure staging are same-volume and residue-free. Focused t/1651 passes Files=1/Tests=4 in 62 seconds under the 4,096-MiB guard; the guarded CI-inventory/catalog/authority/foundation/family/runtime set passes Files=6/Tests=35 in 242 seconds. No public product API, capability/support, performance, capacity, or product behavior claim changes; balanced composition .2 remains proposed next.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.1: construct provider-free runtime streams`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2`
  Status: `done`
  Goal: `Compose the exact balanced portable workload from completed orthogonal gate constructions.`
  Acceptance: `Consume fresh successful gate-construction reports for every orthogonal family, then generate balanced_portable_v1 only through canonical VIAL/HIAL, SemanticIR, bridge, ExecutionIR, and portable-SystemVerilog emission routes; prove every decision-0055 interaction count, path-independent identities, byte-equal reruns, complete oracle applicability, mutation rejection, nonclaims, and exact same-volume cleanup without external execution or a capacity claim.`
  Verification: `Clean provider-free runtime predecessor 3c1f0b411 and activation commit 33d4e48b3 own this leaf. The honest first focused run reports that t/1652 does not exist. Blocker audit f350553e1 proves the ordinary portable AHB bridge is fixed to one six-field/six-event transaction and architecture_scale_probe revision 1 is fixed to one field plus qualification_only/private_nonportable execution admission. The director authorized the recommended long-term route on 2026-08-22 with explicit SOTA/signoff/production-grade quality requirements. Decision 0077 therefore preserves both existing contracts and selects a distinct caller-sealed revision-2 balanced qualification profile, separately caller-sealed execution and emitter admissions, and exact portable-SystemVerilog negotiation. Children .2.2-.2.4 implement the bridge/binder boundaries, canonical six-family source-to-plan composition, and deterministic structural emission. The final qualifier admits only complete canonical bridge, ExecutionIR, and backend-input evidence; emits eight artifacts/three sources/503,279 source bytes/3,605 maps; maps all 1,024 operations and 2,048 bindings; rejects public bypass and hostile mutations atomically; and cleans repository-volume staging on success and failure. No external compile/runtime, public protocol/planner/capability/support, performance, or capacity claim is added; unified qualification .3 remains proposed next.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2: select balanced portable bridge v2`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.4`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.1`
  Status: `done`
  Goal: `Select and durably specify the revision-2 balanced portable qualification contract.`
  Acceptance: `Record the director-authorized profile as a distinct direct-IAL1 qualification contract; freeze exact caller seals, canonical route, cardinality invariants, portable-emitter negotiation, mutation rejection, nonclaims, and unchanged public AHB/planner/support boundaries before implementation.`
  Verification: `Decision 0077 records the authorized route as a dedicated direct-IAL1 architecture_scale_probe/balanced_portable/revision-2 qualification contract rather than widening either existing bridge. It freezes composer-only bridge and execution entrypoints, exact 128-endpoint/16-alias/109-field-per-alias/128-event/32-probe cardinalities, no-padding 2,048-binding arithmetic, one exact portable-SystemVerilog eligibility boundary, full-shape negotiation, defensive regeneration, and explicit public/runtime/support/performance/capacity nonclaims. Task, decision index, bounded Memory, Knowledge card/map, rationale ledger, mdBook, claim dispositions, and maintained-reference authority agree. Focused documentation/claim tests pass Files=3/Tests=25; all 53 mdBook chapters test; the repository-local 88-file/18,684-KiB render contains the exact contract and was removed. Claim inventory closes 1,431 candidates plus 2,077 current/615 original constants as 842 derived gates/589 reviewed records/zero gaps; the engineering-rationale ledger reconstructs 2,872 entries; task-tree, Knowledge Map, live-document, diff, staged acceptance, doctrines, and zero generated-book residue pass. No production code, test, parser, bridge, binder, emitter, runtime, public API/capability/support, performance, capacity, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.1: select balanced portable bridge v2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.2`
  Status: `done`
  Goal: `Implement the caller-sealed revision-2 HIAL bridge and ExecutionIR admission boundary.`
  Acceptance: `Add one exact direct-IAL1 bridge producer and one exact execution admission for the balanced profile; prove parsed/scheduled/lowered route closure, exact 128-endpoint/16-transaction/109-field/128-event/32-probe shape, 2,048-binding arithmetic, capability classification, public-route rejection, hostile mutation rejection, deterministic reports, and unchanged revision-1/AHB behavior.`
  Verification: `The honest RED watcher failed because build_balanced_portable_qualification did not exist. The completed private bridge now admits only the exact direct-IAL1 balanced_portable/revision-2 actor and constructs a content-addressed manifest with 128 endpoints, sixteen single-active transactions carrying 109 endpoint-backed fields each, 128 events, 32 storage-backed probes, the dedicated qualification capability, and no residue. Independent private ExecutionBuilder admission validates the complete bridge identity/shape before binding and then validates one domain, 126 data endpoints, 32 probes, sixteen transactions, all 1,744 fields, 128 events, zero event-input/adapter-state padding, and exactly 2,048 bindings. Public callers, missing or substituted protocol metadata, one-field near misses, mutated bridge facts, and forged manifest identity fail closed; independent reconstruction is byte-equal. Syntax passes for both modules and t/1652; the guarded eight-file bridge/execution/backend regression passes Files=8/Tests=41, and the strengthened focused rerun passes Files=1/Tests=3. Existing AHB, revision-1 scale, and portable-emission paths remain green and unchanged; canonical composition .2.3 remains proposed next.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.2: implement balanced bridge admission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.3`
  Status: `done`
  Goal: `Compose the canonical balanced VIAL/HIAL source and prove every SemanticIR and ExecutionIR interaction count.`
  Acceptance: `Consume fresh successful gate evidence from all six orthogonal families, construct only ordinary source through canonical producers, prove the complete decision-0055 count vector, identities, logical-time/fiber/checking/random semantics, byte-equal reruns, defensive regeneration, nonclaims, and same-volume cleanup.`
  Verification: `The honest RED watcher failed because ArchitectureScaleBalancedPortable did not exist. The completed caller-sealed composer regenerates ordinary repository-relative HIAL/VIAL, consumes one fresh substantive gate report from each of the six completed families, and traverses Parser, the revision-2 bridge, ExecutionBuilder, and PlanBuilder three times including keyed replay. The exact interaction report proves one unit/domain, 128 endpoints/events/fibers, 16 transactions with 109 fields each, 32 probes/scenarios/live fibers/models/scoreboards/faults, 1,024 operations/random occurrences, 2,048 bindings, 512 execution types/scalar cells, 256 coverpoints, and 4,096 scoreboard capacity/bins. It freezes source/stage/rerun/replay/report identities, logical-time order, per-scenario fiber/operation topology, checking semantics, normalized replay equality, defensive reconstruction, private-seam rejection, explicit nonclaims, and repository-volume success/failure cleanup. Both new files pass syntax; final guarded focused t/1653 passes Files=1/Tests=4 in 282 seconds; and the guarded workload/six-family/admission/composition matrix passes Files=9/Tests=38 in 551 seconds. Portable emission remains separately proposed in .2.4; no external tool/runtime, public API, support, performance, capacity, or reached-boundary claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.3: compose canonical balanced workload`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.4`
  Status: `done`
  Goal: `Qualify balanced portable-SystemVerilog emission and close the balanced profile.`
  Acceptance: `Admit only the exact revision-2 capability through emitter-specific negotiation; prove complete deterministic artifact/source-map/operation/binding coverage, legal identifiers, atomic failure, mutation rejection, cleanup, and explicit no-runtime/no-support/no-performance/no-capacity claims; then close .17.2.7.2.`
  Verification: `Clean canonical-composition commit d2305a59a proves all six fresh prerequisite gates and the complete revision-2 source-to-plan identity before this pivot. The honest RED run failed because FSM::VIAL::ArchitectureScaleBalancedPortableEmission did not exist. The completed qualifier freshly regenerates all six gates, canonical source-to-plan evidence, backend inputs, and two independent emissions. Its backend-only caller seal independently validates the exact bridge manifest, ExecutionIR, backend inputs, relation/value/operation shape, and fifteen negotiated requirements before constructing anything. The exact oracle freezes eight artifacts, three SystemVerilog sources, 503,279 source bytes, 3,605 source maps, every one of 1,024 operation IDs and 2,048 binding IDs, legal identifiers, content identities, and byte-equal reruns. Public bypass, unsealed calls, changed resource counts, changed bridge facts, changed backend input, mutated reports/constructions/invocants, and consumer failures reject without partial artifacts or staging residue. Syntax passes; guarded t/1654 passes Files=1/Tests=4 in 535 seconds; the guarded public-planning/portable-SV/revision-1/revision-2/composer matrix passes Files=5/Tests=26 in 403 seconds. External compilation/runtime/trace/result production, public API/support, performance, capacity, and reached-boundary claims remain false; .2 and .2.4 are closed and unified qualification .3 is proposed next.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.2.4: qualify balanced portable emission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.3`
  Status: `done`
  Goal: `Qualify runtime-stream and balanced construction as one unified provider-free measurement gate.`
  Acceptance: `Freeze the complete runtime-profile/level and balanced ownership partition, independently reproduce construction reports, prove authority/oracle/nonclaim applicability, hostile-caller and mutation rejection, same-volume success/failure cleanup, focused/default/guarded compatibility, CI inventory, and synchronized durable truth; then close .17.2.7 and parent .17.2 before .17.3 measurement activation.`
  Verification: `The honest RED watcher failed only because FSM::VIAL::ArchitectureScaleRuntimeBalancedQualification did not exist. The completed exact-class qualifier accepts only the frozen 1,326-byte HIAL and 4,986-byte VIAL references; derives the runtime owner's exact three-profile/five-level partition plus the one balanced portable member; constructs all sixteen members only through their completed canonical producers; and embeds every complete authoritative report with content-addressed construction, report, rerun, applicability, claim, and nonclaim evidence. Its normalized stage matrix records sixteen completed construct/semantic/bridge/plan/backend-input routes, only the balanced member's completed structural emission, and all external compile/runtime/trace/result work as deferred. Canonical validation independently regenerates the whole gate; caller/source/report/claim mutation rejects before substitution, returned data is defensive, and nested runtime/balanced staging proves repository-volume cleanup after success and intentional consumer failure. Syntax and diff checks pass; the 4,096-MiB guarded focused watcher passes Files=1/Tests=4 in 600 seconds; CI inventory plus adjacent runtime compatibility passes Files=2/Tests=7,098 in 62 seconds. Provider access, external execution, runtime, trace, result, public support, performance, capacity, and reached-boundary claims remain false. This closes .17.2.7 and parent .17.2; .17.3 measurement remains separately proposed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7.3: qualify unified provider-free construction`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3`
  Status: `active`
  Goal: `Measure portable backend generation, compile, execution, result, and artifact scaling.`
  Acceptance: `Run the selected workload profiles under active RAM/time controls for every applicable qualified backend, collect normalized wall/CPU/descendant-RSS/artifact/compile/run/result evidence, prove deterministic reruns and semantic outcomes, and distinguish tool cost from architecture cost without generalizing beyond measured profiles.`
  Verification: `Clean unified provider-free qualification commit 490c35cc5 closes deterministic generation before any measured process or tool execution. Decision 0056 freezes the measurement schema, stage boundaries, raw-sample contract, repetitions, 250-ms sampling interval, exact host/tool identities, smaller-of timeouts, 88%-host/4,096-MiB descendant guard, repository-volume staging/publication, exclusion policy, budget formulas, and nonclaims. Completed foundation .1 implements the closed record, validation-before-measurement controller, fork-isolated stage workers, process-tree sampler, effective timeout enforcement, active-guard evidence handoff, defensive validation, and same-volume publication/cleanup. Completed .2-.4 retain accepted semantic/bridge, execution/checking, and structural-emission matrices. Active .5 begins qualified-Verilator runtime measurement with contract selection before implementation; VHDL/OSVVM execution, balanced measurement, calibration closure, remaining cap repair, and promotion remain separately owned.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3: activate scale measurement foundation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.1`
  Status: `done`
  Goal: `Implement the closed architecture-scale measurement record, stage sampler, controller, and repository-volume lifecycle foundation.`
  Acceptance: `Implement fsmgen.vial_architecture_scale_measurement.v1 without running an external verification tool: exact immutable workload/git/dirty/host/tool/run identities; all twelve decision-0056 stages; monotonic wall, controller/descendant CPU, summed-tree/single-descendant RSS, semantic and file/line/byte/object counters, command/outcome/timeout classification, explicit null-plus-reason unsupported counters, 250-ms raw samples, correctness-before-measurement admission, validation and measured-run classes, defensive canonical reports, content identities that exclude volatile measurement values, smaller-of timeout authority, 88%-host/4,096-MiB guard metadata, same-volume atomic publication, success/failure cleanup, hostile input/report mutation rejection, and explicit nonclaims. Prove the honest missing-foundation RED before implementation and leave family workloads, provider access, external compile/runtime, candidate budgets, support, and capacity to later leaves.`
  Verification: `The implementation commit and enforced checklist retain the missing-foundation RED, exact closed twelve-stage schema, validation-first sampling, isolated workers, process-tree counters, smaller-of timeout authority, guard evidence, hostile artifact/report controls, bounded failure, atomic same-volume publication, cleanup, and nonclaims. Exact guarded foundation/guard tests pass Files=2/Tests=8 and the adjacent workload test passes Files=1/Tests=7.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.1: implement scale measurement foundation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2`
  Status: `done`
  Goal: `Measure semantic-catalog and bridge-fanout construction through their canonical provider-free stages.`
  Acceptance: `Consume only completed selected family constructions; record validation plus three gate and five qualification samples where applicable; re-prove every stage-local semantic, bridge, identity, rerun, failure, and cleanup oracle before retaining a sample; distinguish FSMGen-owned stage cost; preserve exact limit/over-limit dominance; retain every raw sample and justified exclusion; and make no external-tool, performance-budget, support, or capacity claim.`
  Verification: `The three named commits, child .1, verification log, and enforced checklists retain the adapter, mode repair, guarded interruption/resume, exact profile/byte/hash partition, and nonclaims. Clean revision ece87892d seals and separately reloads all 108 profiles, both families, 186 raw records, zero exclusions, and accepted identity semantic-bridge-matrix/81ce1716facb87f12767f5e88a6bfe54738063d9b6a11bed7cc2470df8a71bb3.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2: implement caller-sealed family measurement adapter; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2: implement resumable matrix publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2: complete exact semantic bridge matrix`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2.1`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2.1`
  Status: `done`
  Goal: `Preserve truthful failed-stage evidence and make the exact semantic byte boundary complete inside the selected safety ceiling.`
  Acceptance: `Keep decision 0055's ordinary referenced-declaration workload and decision 0056's 120-second parse_validate ceiling unchanged. Replace the parser lexer's per-character UTF-8 re-encoding hot path with bounded chunk advancement and replace repeated wide four-state arbitrary-precision conversions with exact linear mask/hex normalization, preserving token values, byte/line/column spans, diagnostics, source styles, semantic identities, values, masks, widths, and non-ASCII behavior. Make adapter validation rederive only successfully completed family stages and preserve foundation-owned rejected/not-run evidence without masking its original diagnostic. Add focused ASCII/Unicode/span/diagnostic/value-mask and rejected-stage mutations; prove the exact source_bytes_combined/limit_v1 validation accepts under the real RAM guard with canonical family evidence and exact cleanup; retain no invalid publication and add no timeout, fixture, public-API, support, performance-budget, capacity, or reached-boundary change.`
  Verification: `Commit 514761a4e plus the verification log and enforced checklist retain the truthful rejected-stage repair, lexer/value-normalization mechanism, incompatible-prefix census/removal, exact combined-byte guarded acceptance, cleanup, and nonclaims. The repaired clean revision subsequently participates in parent .17.3.2's complete 108-profile seal.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.2.1: repair truthful semantic boundary measurement`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3`
  Status: `done`
  Goal: `Measure execution-graph and checking-state construction through canonical binding, planning, and oracle stages.`
  Acceptance: `Measure only reachable selected levels under the foundation controller; preserve preflight-dominated and not-materialized outcomes; prove exact execution/checking identities, ranks, semantics, packed-state and replay oracles, deterministic reruns, earliest authoritative failures, raw evidence, and cleanup; separate parse/bridge/bind-plan cost; and make no backend-runtime, performance-budget, support, or capacity claim.`
  Verification: `Commits named below and children .1-.2.3.1 retain the causal repairs and exact gates. Clean revision 9c0209c22 seals and separately reloads all 72 execution/checking profiles, both families, 119 raw records, zero exclusions, and complete identity execution-checking-matrix/0548629720a9f4c8636c912396cfaefff523da92fc800594618db68b788b91d0; the verification log and clean-closure checklist retain the exact partition, byte census, interruption recovery, cleanup, and nonclaims.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3: activate execution and checking measurement; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3: implement execution and checking measurement adapter; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3: implement resumable execution checking matrix; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1: seal clean 72-profile matrix`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.1`
  Status: `done`
  Goal: `Make raw architecture-scale measurement staging safely resumable after controller termination.`
  Acceptance: `Acquire exclusive repository-volume ownership for the exact workload/run-class/ordinal staging identity before inspecting or creating it; reject a concurrently owned identity; reclaim only a fully validated real-directory/regular-file orphan while ownership is held; reject symlink, special-file, cross-volume, or ambiguous residue without deletion; prove ordinary success/failure cleanup and deterministic evidence unchanged; use the retained real guard-interruption residue as a recovery witness; then resume the exact clean-revision 72-profile capture without weakening either guard threshold or manually deleting the orphan.`
  Verification: `Commit c7493e3de and its enforced checklist retain the lock/orphan root cause, hostile filesystem cases, exact real-residue recovery, focused gates, and cleanup. The adapter—not manual deletion—reclaimed the guarded interruption residue, republished its sample, and left zero staging; the later coordinator heap finding is owned by .17.3.3.2.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.1: implement interruption-safe measurement recovery`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2`
  Status: `done`
  Goal: `Bound execution/checking matrix capture and resume memory to one exact profile lifecycle at a time.`
  Acceptance: `Run every profile capture or immutable-publication validation in its own guard-visible child lifecycle; admit only a closed bounded coordinator result; preserve full adapter report validation, atomic publication, common clean-revision/host/tool/guard identity, ordered progress, exact failure propagation, family/full seal withholding, and same-revision profile-boundary resume; prove child failure, signal, malformed/oversized result, publication collision, and large synthetic per-profile allocation fail closed without leaking a child or publication; independently revalidate the retained nineteen revision-c7493e3de profiles through the repaired isolation path, preserve them in a verified revision-keyed same-volume archive rather than relabel or delete them, then seal a fresh full 72-profile matrix at the clean repaired revision under unchanged guards.`
  Verification: `Commits 3ccc4f5b9/b9463c663 and children .1-.3.1 retain allocator isolation, early-cap, and duplicate-random repairs. Clean revision 9c0209c22 seals the 40/32 partition and separately reloads all 72 profiles, both families, 119 raw records, and zero exclusions/diagnostics under unchanged guards; exact census and interruption evidence remain in the verification log and enforced checklists.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2: activate isolated profile coordinator repair; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1: seal clean 72-profile matrix`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.1`
  Status: `done`
  Goal: `Enforce the selected total-operation execution cap before operation-graph materialization so the exact excess rejects inside the fixed qualification guard.`
  Acceptance: `Keep the 1,000,000 expanded_operations_total cap, accepted-profile semantics, compact authored workload, ordinary SemanticIR and bridge construction, exact expected-rejection status, and existing VIAL_EXECUTION_LIMIT_ERROR diagnostic/phase/message/path unchanged. Immediately after exact scenario selection, independently rederive every selected scenario's compact expanded operation count, require equality with SemanticBuilder's validated action_count, aggregate the selected total with bounded arithmetic, and enforce the existing cap before bridge indexing, binding, type, operation, source-map, plan, or partial artifact construction. Retain the existing post-materialization check as defense in depth. Prove the one-million-and-one excess never reaches graph construction, passes under the unchanged 4,096-MiB descendant guard, returns the byte-equal historical diagnostic, leaves no staging/publication residue, and preserves accepted/rejected VIAL execution behavior. Then commit cleanly, revision-archive any incompatible exact prefix, and resume parent .17.3.3.2 from an empty execution/checking publication namespace. This prerequisite advances one concrete .17.4 enforcement obligation without activating or silently closing that broader cross-layer cap-policy task.`
  Verification: `The implementation commit and enforced checklist retain the independent compact-tree preflight, byte-equal historical excess diagnostic, terminal defense, and sentinel proof that one-million-and-one rejects before bridge materialization. Exact and focused suites pass under the unchanged guard; broader .17.4 policy remains proposed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.1: enforce total-operation cap before materialization`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.2`
  Status: `done`
  Goal: `Make the million-attempt execution profile's controller correctness validation exact, diagnosable, and acceptable without weakening its random/replay authority.`
  Acceptance: `Retain the 22 clean-revision atomic publications and absent family/full seals. Under the unchanged real guard, reproduce random_attempts/limit_v1 through the caller-sealed measurement adapter while durably exposing the rejected validation stage and diagnostic; independently compare construction, generated decision, strict replay, evaluation, controller stage plan, output counts, artifacts, cleanup, and identities with t/1614 and the accepted qualification profile. Root-cause the first disagreement before changing product code. Repair only the proven producer, controller, or matrix-admission layer; preserve exactly 1,000,000 attempts, zero-based accepted attempt 999,999, checked-AHB route, deterministic plan/replay identities, validation-first sampling, atomic publication, raw-stage cleanup, 4,096-MiB process guard, and fail-closed exclusions. Add a focused RED/GREEN regression, resume from the immutable 22-profile frontier at one clean revision, and withhold family/full seals until all 72 profiles validate.`
  Verification: `The three named commits and enforced checklists retain the exact timeout reproduction, four-versus-two call-count RED, single-evaluation repair, random-vector gates, and unchanged million-attempt authority. The guarded adapter accepts with zero residue and the subsequent clean capture seals all 40 execution profiles; checking-state plan work remains owned by .17.3.3.2.3.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.2: activate random-attempt correctness repair; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.2: diagnose redundant bind-plan evaluation timeout; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.2: remove redundant bind-plan evaluation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3`
  Status: `done`
  Goal: `Enforce the serialized-plan byte cap before materializing a checking-state plan that is provably over the existing limit.`
  Acceptance: `Keep the 16,777,216-byte serialized_plan_bytes cap, canonical plan schema and bytes, accepted-plan identities, random/replay semantics, checking-state levels, expected-rejection status, and existing VIAL_EXECUTION_LIMIT_ERROR phase/message/path unchanged. Add one general plan-projection preflight at the earliest point where all size-determining compact inputs are authoritative: independently derive the exact canonical serialized byte count with bounded or saturating arithmetic, reject malformed or inconsistent projections, and invoke the existing cap before allocating a known-excess random-decision list, source-map expansion, ExecutionIR, or ExecutionReport. Retain the complete terminal canonical serialization and byte-limit check as defense in depth, and prove preflight equality with terminal bytes for accepted ordinary and exact 8,440-occurrence boundary plans. Prove 8,441 and 32,768 occurrences return the byte-equal historical /plan diagnostic under the unchanged 300-second stage ceiling and 4,096-MiB descendant guard; preserve 65,536 preflight_dominated and 65,537 random-count-cap dominance, deterministic reruns, atomic publication, exact cleanup, and family/full seal withholding. No axis-specific numeric shortcut, cap/timeout/guard increase, workload relabelling, support claim, performance budget, capacity claim, or reached-boundary claim is admissible. Commit cleanly, revision-archive the incompatible 40-execution/17-checking prefix plus execution family seal with exact hashes, and resume the full 72-profile matrix from an empty active execution/checking namespace.`
  Verification: `The named commits, child .1, and enforced checklist retain the general canonical plan projection, unchanged terminal defense, accepted-plan transcript repair, exact 8,440/8,441/32,768/65,536/65,537 outcomes, and byte-equal diagnostic. The clean matrix and separate guarded reload accept all 72 profiles with zero exclusions/diagnostics under unchanged identities, guards, caps, and nonclaims.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3: activate serialized-plan preflight repair; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3: archive revision-e4b95dbd matrix prefix; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3: enforce plan cap before materialization; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1: seal clean 72-profile matrix`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1`
  Status: `done`
  Goal: `Preserve early serialized-plan rejection without regenerating an accepted plan's deterministic random decisions during materialization.`
  Acceptance: `Keep the unchanged one-million random-attempt cap and exact accepted attempt 999,999, random/replay algorithm and identities, canonical plan schema/bytes/identity, 16,777,216-byte serialized-plan cap, 8,440/8,441 and 32,768 occurrence outcomes, controller two-rerun correctness oracle, 300-second stage timeout, 4,096-MiB descendant guard, and every support/performance/capacity nonclaim. Replace the projection/materialization random-generation duplication with one general caller-private bounded transcript or equivalently closed mechanism: stream and validate each generated or replayed decision exactly once while projecting; retain no Perl decision list, random source-map list, ExecutionIR, or report before the cap; bound any reusable representation independently of caller input and the plan cap; discard it on rejection; and on acceptance consume it exactly once to materialize the byte-identical decisions while independently reconstructing expectation order, source maps, scenario links, and terminal canonical byte equality. Prove a product-level RED that one accepted occurrence currently enters ExecutionRandom twice, prove the repaired builder enters it once without trusting caller data, prove malformed/truncated/trailing/internal transcript state fails closed, and preserve random exhaustion plus replay-validation precedence after plan-byte saturation. Revision-archive the clean revision-037e56f09 22-profile prefix with exact reconstruction before product changes, then run the exact random-attempt adapter below the unchanged stage ceiling and restart the complete 72-profile matrix only from the clean repaired revision.`
  Verification: `The four named commits, decision 0079, the verification log, and enforced clean-closure checklist retain the exact archive, call-count RED, bounded sealed transcript, adversarial gates, guard interruption/resume, and nonclaims. Clean revision 9c0209c22 seals and separately reloads the 40/32 matrix, both families, complete identity execution-checking-matrix/0548629720a9f4c8636c912396cfaefff523da92fc800594618db68b788b91d0, 119 raw records, and zero exclusions/diagnostics.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1: activate accepted-plan random transcript repair; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1: archive revision-037e56f09 matrix prefix; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1: reuse bounded random-decision transcript; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.3.2.3.1: seal clean 72-profile matrix`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4`
  Status: `done`
  Goal: `Measure deterministic structural backend emission for every applicable selected profile.`
  Acceptance: `Measure canonical portable-SystemVerilog, portable-VHDL, OSVVM, and native-UVM review-profile construction only where their completed authorities apply; verify exact artifact/source/map/check identities and atomic rejection before retaining wall/CPU/RSS/count samples; distinguish FSMGen emission from provider verification and external execution; preserve native-UVM and over-limit non-applicability; and publish no compile/runtime, promoted budget, support, or capacity claim.`
  Verification: `Clean child-.1 commit 814e0f37e seals guarded per-profile reports. Child .2 commit fdc6e6a1b implements the producer-derived twenty-profile isolated publisher, independently bounded raw/IPC envelopes, immutable same-volume recovery, and common-identity family/complete seals. Exact t/1662 seals and independently reloads all profiles under the real guard; a fresh-process guarded --validate returns the same accepted complete identity and partition. Provider evidence stays read-only and no external-tool, compile/runtime, support, budget, capacity, or boundary claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4: activate structural backend-emission measurement; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.1: measure structural backend emission; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.2: implement structural measurement matrix publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.2: seal clean structural measurement matrix`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.1`
  Status: `done`
  Goal: `Implement caller-sealed structural backend-emission measurement through the common architecture-scale controller.`
  Acceptance: `Admit only repository root, one decision-0075 backend profile, and one owned level; reconstruct the frozen checked-AHB sources, canonical construction, and exact ArchitectureScaleBackendEmission evaluation without caller source, IR, backend input, artifact, provider result, diagnostic, or report injection. Use only the common twelve-stage measurement schema with planned construct/parse_validate/bridge/bind_plan/emit stages; make every stage payload independently deterministic and validate the complete producer authority before retention. Run correctness validation plus exactly three/five measured repetitions only for emitted gate/qualification routes; preserve reference, limit, excess, native-UVM unsupported/preflight-dominated, and any authoritative rejection as validated_not_measured with no fabricated sample. Record exact structural artifact/source/byte/map/check/identifier/identity counts, mark whether the OSVVM emit stage includes its sealed read-only provider verification, and keep that prerequisite distinct from external verification-tool execution. Prove hostile caller/report mutation, stage failure/timeout/signal, missing or contradictory provider/applicability evidence, deterministic reruns, common guard enforcement, bounded capture, same-volume staging, success/failure/consumer-failure cleanup, and defensive returned data. Add no compiler, simulator, runtime, trace, result, public API, support, promoted budget, capacity, reached-boundary, or general-parity claim.`
  Verification: `The exact-class adapter accepts only repository root, one frozen backend profile, and one owned level; it reconstructs repository anchors and consumes one producer-private caller-sealed cumulative stage projection. Canonical construction is double-derived, evaluation passes the producer's independent validator before retention, and every planned construct/parse_validate/bridge/bind_plan/emit payload is rerun twice inside the common twelve-stage controller and regenerated again by report validation. Portable-SystemVerilog gate and OSVVM qualification retain exactly three/five complete raw records; native-UVM gate is validated_not_measured, its larger preflight route runs only construct/emit, and reference/limit/excess remain correctness-only. OSVVM provider verification is explicit, read-only, included in emit, and never classified as an external tool. Default and exact t/1661 pass Files=1/Tests=5; the final real-guard run completes in 724 seconds under unchanged 88%-host/4,096-MiB-descendant limits. Producer watchers t/1645-t/1650, common controller t/1656, and CI inventory t/1183 pass; hostile input, provider/applicability/evaluation mutation, defensive return, forced stage failure, common timeout/signal/consumer failure, and exact cleanup are covered. No `.artifacts/tmp/vial-scale` residue, external-tool/compile/run/trace/result evidence, support, budget, capacity, reached-boundary, parity, or public API claim remains.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.1: measure structural backend emission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.2`
  Status: `done`
  Goal: `Publish and independently reload the exact structural backend-emission measurement matrix.`
  Acceptance: `Freeze producer-owned profile/level order and admit only complete child-.1 reports at one clean revision, host, in-process tool, and enforced-guard identity. Publish every profile atomically in a content-addressed same-volume namespace; resume only from independently regenerated immutable reports; reject missing, extra, reordered, mutated, mixed-identity, collision, malformed, oversized, signal, or stale staging evidence; and withhold the aggregate seal until the complete selected matrix validates. Retain all validation and required raw samples, explicit applicability/rejection/dominance accounting, provider-verification inclusion, zero unjustified exclusions, exact cleanup, and the closed nonclaim set. Complete one guarded clean-revision capture plus a separate guarded canonical reload before closing parent .17.3.4; do not promote budgets, support, capacity, reached boundaries, external-tool, compile/run/trace/result, or public API claims.`
  Verification: `The ordered twenty-member inventory comes only from producer owned_shapes; level and canonical-emission authority route validation versus three/five-sample measurement. Separate close-on-exec children validate and atomically publish complete reports before bounded compact return. A guarded 334,757-byte calibration sets the 524,288-byte file ceiling; IPC/error ceilings are 65,536/4,096. Parent admission regenerates profile/order/sample/provider/dominance/artifact/common-identity invariants; exact staging alone recovers, while process, byte, collision, ambiguity, order, sample, or provider drift rejects. Clean revision fdc6e6a1b seals 20 profiles plus family/complete manifests as 22 files/2,232,452 bytes at backend-emission-matrix/a5bb05a5f4be7fb364fbf52c6750b10e04417d53732f364158e6f143bc71f735. Exact t/1662 passes Files=1/Tests=5 in 12,656 seconds and independently reloads the aggregate; a separate guarded --validate returns the same identity, 13 emitted/seven authoritative non-emission, 24 raw/zero excluded, five provider-verification, and three preflight-dominated profiles. The largest report is 442,009 bytes, manifest hashes match, staging residue is zero, and execution/support/budget/capacity/API nonclaims stay closed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.2: activate structural measurement matrix publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.2: implement structural measurement matrix publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.4.2: seal clean structural measurement matrix`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5`
  Status: `active`
  Goal: `Measure exact portable-SystemVerilog generation, compile, run, trace validation, and result production with qualified Verilator.`
  Acceptance: `Use only the qualified Verilator profile and canonical runtime-stream inputs; perform one validation plus required measured repetitions in fresh owned staging; apply effective qualified compile/run limits and active guards; prove artifact, source-map, command, trace closure, normalized result, deterministic rerun, raw-sample, transcript, publication, and cleanup oracles; reject identity drift or excluded samples explicitly; and make no full-SystemVerilog, UVM, mixed-language, promoted-budget, support, or capacity claim.`
  Verification: `Clean structural-matrix closure 6c76b4c39 permits the pivot. Existing runtime-stream construction owns exact provider-free inputs and expectations but intentionally materializes no scale trace/result; the shipped Verilator Runner owns correct external execution as one atomic transaction rather than independently measurable shared stages. Completed selection child .1 and decision 0083 choose checked-in authored reset-sampling fixtures, exact 10,000/15,000 portable candidates, honest byte-cap dominance, and one content-addressed lifecycle shared by the public Runner and measurement workers. Source-text patching, output padding/truncation, duplicated tool execution, hidden public widening, borrowed support, and unproved record-count reachability remain inadmissible. Active child .2 now owns the versioned materialization/oracle and portable 100,000-to-15,000 candidate repair.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5: activate portable-Verilator runtime measurement`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1`
  Status: `done`
  Goal: `Select the exact runtime-stream materialization, identity, and shared Verilator stage-lifecycle contract.`
  Acceptance: `Audit the canonical runtime construction, portable emitter, Runner, trace validator, result producer, measurement controller, qualified tool/limit authority, and reference runtime evidence. Select a closed workload-to-runtime schedule that proves candidate record-count reachability while preserving semantic truth, binds every repeated activity into trace/result/backend evidence, and classifies reference/limit/excess applicability honestly. Select one caller-sealed staged execution lifecycle reused by the public Runner and measurement workers across process boundaries with exact tool identity, commands, timeouts, transcript bounds, state transitions, same-volume ownership, failure cleanup, and no second execution semantics. Record alternatives and rollback in a decision; change no product behavior.`
  Verification: `The prerequisite repair chain remains exact: .1.1 closes phase rollover, .1.2 direct drive, .1.3 parallel-child admission, and .1.4 portable scale-oracle revision 2. Decision 0083 then derives a genuine runtime-stream ramp from authored reset cycles: the checked reference is 274 records; each extra cycle produces four sampled-value plus one final coverage record; one terminal passing expectation closes records(N)=5N+260. Qualified public execution proves N=1,948 at exactly 10,000 records and N=2,948 at exactly 15,000. Complete-graph probes accept 10,000/15,000/20,000 at 32,096,420/47,502,039/62,914,039 bytes, reject 25,000 at the 67,108,864-byte public cap, and reject the former 100,000 candidate at the Runner output cap. The selected 15,000 level is the largest 5,000-record step retaining at least one-quarter full-graph headroom; final tracked-fixture bytes must be independently reproved by .2. Reference stays correctness-only; gate/qualification use three/five measurements; nominal record limit/excess are byte-preflight dominated and tool-free. The selected private lifecycle uses forward-only admitted/prepared/tool_verified/compiled/ran/trace_validated/result_produced/assembled/cleaned content-addressed state, exact tool/command/capture/deadline authorities, independent predecessor validation, process containment, same-volume sealed storage contexts, atomic cleanup, and one implementation reused by Runner and measurement. Selection changes no product behavior.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1: select authored runtime stream and shared lifecycle`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.4`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.1`
  Status: `done`
  Goal: `Repair portable-SystemVerilog successor scheduling when authored operation order crosses backward in logical phase order.`
  Acceptance: `First preserve an executable RED witness in which a legal root-fiber check-phase operation precedes a react-phase successor and the emitted runtime trace fails only because it regresses from check to react in one cycle. Implement a general backend scheduler rule derived from immutable ExecutionIR operation topology, static-rank/successor dependencies, eligible phases, and the backend's closed action-lowering completion semantics: preserve authored dependency order, retain same-phase static-rank ordering, and advance a backward-phase successor to its first legal phase in the next logical cycle without sorting operations, rewriting source, special-casing the scale fixture, fabricating trace time, or widening the public API. Cover every backward phase boundary accepted by the portable profile, blocking/cycle-advancing predecessors, deterministic reruns, trace/result validation, existing checked-AHB behavior, stable diagnostics, and cleanup. Update the backend contract, mdBook, Knowledge Map, and task evidence; add no scale reachability, performance, capacity, parity, full-SystemVerilog, four-state, or methodology claim.`
  Verification: `Decision 0080 retains static partial evaluation and makes the emitted scenario task track the last logical phase consumed by each closed operation lowering. Same/forward phases call directly; check-to-react uses the qualified inactive-edge barrier, while react/check-to-drive increments the logical cycle once. The start task's former unconditional increment is centralized at the successor boundary. Negotiation independently rejects phase-order or kind/eligible-phase drift before artifacts. The exact public-Runner RED was VIAL_RUN_TRACE_ERROR over a cycle-4 check tuple followed by cycle-4 react; repaired qualified-Verilator execution passes with one genuine expectation and byte-identical rerun artifacts/results. Structural mutations cover every supported backward pair, same-phase order, blocking reset, and phase drift. The review also records direct-drive omission under separate proposed child .1.2 rather than hiding it in this repair.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.1: repair portable-SV phase rollover`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.2`
  Status: `done`
  Goal: `Repair portable-SystemVerilog direct-drive lowering so accepted update-driver intent changes and records the exact bound endpoint value.`
  Acceptance: `Preserve an ordinary VIAL/HIAL RED whose added public input endpoint and (drive ENDPOINT VALUE) action produce immutable ExecutionIR kind=drive, eligible_phase=drive, update_driver effect, endpoint/value typed inputs, and successful portable negotiation, while the generated operation task contains only vial_inactive_barrier() and no endpoint assignment or drive record. Root-cause and repair the missing effect target and renderer path generally: bind only an exactly drive-capable bridge endpoint and recorded representation relation; emit the normalized assignment and drives record at the requested logical drive phase; define zero-duration versus cycle-consuming completion consistently with decision 0036; update successor rollover authority and every affected deterministic identity; reject sample-only/probe/unbound/type-incompatible targets before artifacts; prove same-phase drive ordering/conflicts, drive-to-react/check, backward successors, real qualified-Verilator behavior, result/trace closure, repeated byte determinism, diagnostics, and cleanup. Update contract/book/card/task evidence and capability/support truth as required. Do not special-case checked AHB, forge a bridge name or trace record, weaken direction/type safety, add a public API, or claim scale, full-SystemVerilog, four-state, methodology, performance, capacity, or general parity.`
  Verification: `Decision 0081 and the preserved ordinary-source RED close the direct-drive semantic chain. ExecutionBuilder projects endpoint_id into the update_driver target and discovers action-level drive use; probes and sample-only endpoints fail binding. Portable negotiation independently requires the exact effect, root-fiber/public-input execution and bridge binding, one drive relation, fully known equal normalized scalar, and declared SystemVerilog port; inout/non-root remain explicit nonclaims and live sibling conflicts reject once by scenario/endpoint identity. Emission performs the exact zero-duration port assignment plus drive record, retains same-phase order, traverses one real sample barrier before react/check/finalization, restores each used slot once to safe zero, and source-maps that lifecycle write. TraceValidator independently closes endpoint, null transaction field, value, and logical slot. Guarded t1552/t1557 pass Files=2/Tests=15; the final loaded-host t1558 run passed the complete repeated direct-drive subtest while its unrelated baseline replay alone reached the pre-existing fixed 30-second Runner wall, now durably routed to child .3 without a fabricated root cause. The same audit routes the broader parallel-child admission/rendering defect to proposed .1.3. No scale, four-state, methodology, performance, capacity, or general-parity claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.2: activate portable-SV direct-drive repair; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.2: repair portable-SV direct drive`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.3`
  Status: `done`
  Goal: `Close portable-SystemVerilog admission and lowering for non-await operations nested under parallel fibers.`
  Acceptance: `First preserve an ordinary-source RED whose target-neutral ExecutionIR contains non-await parallel-child operations and whose current portable negotiation/emission either loses, misorders, or fails to invoke their generated behavior. Inventory every operation kind the execution profile permits in child fibers and independently compare that set with the portable renderer's child scheduler. Select and implement either complete deterministic child-operation lowering or exact fail-closed negotiation for every unimplemented topology; preserve authored/static ranks, all/any completion and cancellation, logical phases, conflicts, trace/result identity, deterministic reruns, diagnostics, and cleanup. Reject no legal topology already proved executable without an explicit compatibility decision, and do not special-case direct drive, rewrite source, rely on SystemVerilog fork order, fabricate trace time, widen public APIs, or claim scale, performance, capacity, four-state, methodology, or parity.`
  Verification: `Decision 0082 and the preserved ordinary-source RED close the public revision-1 parallel-child semantic boundary. Before repair, replacing one direct child await with reset still planned and emitted a complete artifact graph, but the property-only scheduler never invoked reset; the RED failed five assertions over success/artifact/manifest/diagnostic truth. Negotiation now reconstructs operation identity, scenario/fiber membership, direct parentage, exact single-operation membership, terminal-await property/effect/deadline shape, unique child roots, and exactly one owner for every non-root fiber. Every other admitted operation kind, two-operation sequence, malformed await, forged parent, duplicate/unowned root, and multiply owned fiber fails atomically with stable parent/child diagnostics; ordinary qualified emission and t1557 remain green at Files=1/Tests=9. The support contract and backend manifest publish the exact nonclaim/limitation. Decision 0077's caller-sealed balanced revision-2 structural profile is excluded explicitly because it has a separate exact-shape renderer and claims no runtime; after that correction, three of four t1654 subtests pass and only its fresh prerequisite composition fails through a source-identity drift reproduced unchanged at clean predecessor 87684237a. The predecessor and current t1650 both report the same portable reference 164,507 bytes against frozen 164,093 plus identity mismatch, proving it predates this child; proposed .1.4 owns complete all-level reconciliation. A final real t1558 attempt again reached the existing fixed 30-second baseline runtime wall and left no process or staging residue; .17.3.5.3 remains the lifecycle owner. No scale, performance, capacity, four-state, methodology, parity, or general child-sequence support claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.3: activate portable-SV parallel-child repair; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.3: close portable-SV parallel-child admission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.4`
  Status: `done`
  Goal: `Reconcile the portable-SystemVerilog architecture-scale emission ladder with the scheduler and direct-drive repairs that changed generated source identity.`
  Acceptance: `Preserve the exact backend-emission RED at clean predecessor 87684237a and locate every output-affecting origin commit. Independently regenerate every selected portable level, derive source bytes and identities from emitted artifacts rather than copying failed expectations, falsify them with byte-equal reruns and mutation, and determine whether conditional zero-overhead emission can preserve the selected ladder without weakening semantics. If correct semantics necessarily change bytes or the 16-MiB adjacent boundary, select and document a versioned count/boundary reconciliation before implementation; update decision 0075 and every backend-emission/runtime-balanced consumer consistently. Prove reference/gate/qualification/limit/over-limit outcomes, balanced revision-2 prerequisites, exact cleanup, and no borrowed runtime, support, performance, or capacity claim. Do not blindly rebaseline a hash, weaken the source cap, hide an earlier rejecting level, or alter the public scheduler/direct-drive semantics.`
  Verification: `The .1.3 compatibility sweep ran t1650 in the current tree and in a repository-local detached worktree at clean predecessor 87684237a. Both independently produced the exact portable reference mismatch: 164,507 generated source bytes versus frozen 164,093, plus source-identity drift. Git history locates the frozen oracle at 5d309b0eb, scheduler rollover repair at 1e9ab0e61, and direct-drive repair at 69384201c. Fresh ordinary Parser/bridge/PlanBuilder/backend paths regenerate all five producer-owned levels twice: T=21/1,024/4,096 emit 164,507/2,803,857/10,910,865 source bytes with 54/1,057/4,129 maps; the new exact T=6,318 limit emits 16,774,723 bytes/6,351 maps and T=6,319 renders 16,777,362 bytes before rejecting atomically at the unchanged 16-MiB cap. Exact fixture hashes are frozen in portable oracle schema revision 2, whose shared discriminator is portable_sv_artifact_graph_v2. Different +414/+532/+532 deltas falsify fixed padding; the renderer already scopes rollover to genuine backward transitions, so semantic removal and cosmetic 146-byte boundary shaving are rejected. Byte-equal reruns, canonical mutation rejection, family partition, balanced revision-2 emission/report prerequisites, runtime construction, measurement adapters, and exact cleanup pass in three guarded runs totaling Files=7/Tests=33. Decision 0075, the book, card, rationale ledger, and every current consumer are synchronized. No runtime, support, performance, capacity, or public-scheduler behavior claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.4: activate portable scale identity reconciliation; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.4: reconcile portable scale oracle revision 2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.2`
  Status: `active`
  Goal: `Implement the selected caller-sealed portable-SystemVerilog runtime-stream materialization and structural oracle.`
  Acceptance: `Implement decision 0083 from canonical child-.1 authority: add checked-in, reviewable gate and qualification VIAL sources with exact N=1,948/2,948 authored reset holds and terminal scale expectation; structurally prove that only the selected reset/timeout/window/expectation deltas differ from the checked reference; version the portable runtime-stream materialization/oracle and replace only sv_portable_verilator's unrepresentable 100,000-record candidate with 15,000 while retaining 10,000 gate and stable role labels. Preserve the ordinary public parse/bridge/plan/emission route; produce deterministic schedule-bound artifacts and exact pre-tool record-family/full-graph projections; independently prove final 15,000 artifacts stay within the three-quarter public byte threshold and 20,000/25,000/100,000 falsifiers remain honestly classified; reject nominal limit/excess and every unrepresentable shape before external execution. Prove source-map, generated-loop, identity, semantic repetition, mutation, atomic failure, and cleanup without runtime source rewriting, padding, truncation, public API widening, or runtime/support/performance/capacity claims.`
  Verification: `Clean decision-0083 selection commit 769df71d5 closes .1 with exact authored workload, full-graph headroom, byte-cap dominance, and shared-lifecycle boundaries. This activation changes only task/index/Memory/book/fact continuity; .2 alone now owns the checked gate/qualification sources, portable candidate repair, structural oracle, deterministic projections, preflight classifications, mutation defenses, and exact cleanup before any Verilator lifecycle implementation or measurement.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.2: activate authored portable runtime materialization`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3`
  Status: `proposed`
  Goal: `Implement the selected shared staged Verilator execution lifecycle without changing the public Runner contract.`
  Acceptance: `Extract one caller-sealed state machine for qualified tool discovery, input preparation, compile, run, trace extraction/validation, result production, final artifact assembly, and cleanup. Persist only closed content-addressed state below an exact repository-owned stage, independently validate every predecessor before transition, preserve process-group termination and capture ceilings, reject skips/replay/mutation/collision/symlink/partial state, and make the existing Runner consume the same transitions with byte-equal success artifacts and stable failure diagnostics.`
  Verification: `The .1.2 signoff supplied lifecycle evidence without changing this proposed implementation owner: repeated guarded t1558 attempts timed out different byte-identical baseline/direct executions at Runner's fixed 30-second run wall while counterparts passed in other attempts and unrelated compiler work was active. Runner currently reports only VIAL_RUN_RUNTIME_ERROR and cannot distinguish executable launch/policy delay from generated-main time. This node must retain stage-local monotonic timing and host/guard context, then preserve or deliberately revise the effective qualified deadline under the selected lifecycle; no root cause, retry policy, or timeout widening is authorized by the observation alone.`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4`
  Status: `proposed`
  Goal: `Measure each applicable portable-Verilator runtime-stream profile through the common controller.`
  Acceptance: `Reconstruct the selected runtime construction, schedule, emission, tool profile, and lifecycle from repository anchors only. Route applicable validation and gate/qualification repetitions through distinct common-controller stages and the shared lifecycle; retain exact raw samples, tool/command/transcript/artifact/trace/result identities, semantic oracles, exclusions, guard evidence, and cleanup. Keep preflight-dominated shapes tool-free and add no promoted budget, support, capacity, reached-boundary, parity, or public API claim.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5`
  Status: `proposed`
  Goal: `Publish and independently reload the exact portable-Verilator runtime measurement matrix.`
  Acceptance: `Derive the complete profile/level order from producer ownership; isolate capture/reload lifecycles; atomically publish bounded immutable reports at one clean revision/host/tool/guard identity; resume only independently regenerated evidence; reject incomplete, reordered, mutated, mixed, collided, oversized, signalled, stale, or ambiguous state; retain every raw/excluded sample and dominance/nonclaim; and complete guarded capture plus fresh-process reload before closing .17.3.5.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6`
  Status: `proposed`
  Goal: `Measure exact provider-free portable-VHDL generation, analysis, elaboration, run, trace validation, and result production with qualified GHDL.`
  Acceptance: `Use only the qualified GHDL profile and canonical runtime-stream inputs; perform one validation plus required measured repetitions in fresh owned staging; apply effective per-source analysis/elaboration/run limits and active guards; prove artifacts, source maps, checks, command identity, trace/result parity, deterministic rerun, raw evidence, publication, failure, and cleanup; and make no OSVVM, mixed-language, promoted-budget, support, or capacity claim.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7`
  Status: `proposed`
  Goal: `Measure exact OSVVM methodology generation, analysis, elaboration, run, trace validation, and result production with the qualified provider and GHDL.`
  Acceptance: `Verify exact provider commit/tree/manifest/licence/notice identity before work; consume only the qualified OSVVM plus GHDL profile and canonical runtime inputs; perform validation and measured repetitions with qualified limits and guards; retain separate provider-verification, FSMGen, and external-tool stages; prove adapter/portable artifacts, mappings, trace/result semantics, raw evidence, deterministic rerun, atomic publication, failure, and cleanup; and make no provider-generality, mixed-language, promoted-budget, support, or capacity claim.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8`
  Status: `proposed`
  Goal: `Measure the caller-sealed revision-2 balanced portable composition without widening any public contract.`
  Acceptance: `Run the exact decision-0077 balanced source-to-portable-SystemVerilog route through the common measurement foundation; prove all six fresh prerequisite gates, bridge/ExecutionIR/binding/operation/artifact/map identities, deterministic bytes, stage-local costs, raw samples, effective guard/timeouts, atomic publication, failure, and cleanup; measure external execution only if its separately qualified route is applicable; and preserve all public AHB/revision-1/support/performance/capacity nonclaims.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9`
  Status: `proposed`
  Goal: `Close the measured family with immutable raw evidence, derived views, and candidate pinned-host/tool budgets.`
  Acceptance: `Independently regenerate every applicable family/profile/level ownership and measurement record; require complete validation/three-run gate or validation/five-run qualification evidence; derive minimum/median/maximum/MAD without discarding raw samples; freeze exact host/tool applicability and decision-0056 candidate formulas from accepted clean samples; distinguish FSMGen/tool/artifact costs; record exclusions, dominant caps, nonclaims, and residue; reject mutation or missing members; and leave cap implementation to .17.4 and public budget/support promotion to .17.5.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4`
  Status: `proposed`
  Goal: `Implement and prove explicit architecture resource caps and graceful bounded failure.`
  Acceptance: `Apply the selected caps at the earliest authoritative stages with deterministic diagnostics, atomic no-partial-output behavior, same-volume cleanup, boundary/over-bound tests, and unchanged accepted-profile semantics; host exhaustion and external-tool crashes are not accepted as product limit enforcement.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5`
  Status: `proposed`
  Goal: `Stabilize architecture-scale regression gates, public documentation, capability truth, and closeout.`
  Acceptance: `Promote representative bounded profiles into stable non-flaky gates; document exact measured envelopes, budgets, commands, variability policy, cleanup, supported claims, and residue; synchronize support/capability/Knowledge Map/task/Memory surfaces without claiming whole-product big/really-big qualification.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.6`
  Status: `done`
  Goal: `Align the public VIAL execution support snapshot with the enforced portable-SystemVerilog transcript limits.`
  Acceptance: `From a separate clean activation, make FSM::Support::VIALExecutionContract report the Runner- and normative-contract-authoritative 8,388,608-byte compile and 67,108,864-byte run capture limits; add exact contract/accounting regression assertions; preserve Runner behavior, artifacts, diagnostics, support capability set, backend qualification, and every scale non-claim. Audit all support consumers before changing the snapshot and update the owning docs/fact surfaces in the same slice.`
  Verification: `Clean activation commit 8279993c0 owns the exact alignment. Consumer and git-history audits isolate the contradictory 4,194,304/4,194,304-byte pair to FSM::Support::VIALExecutionContract and identify dfe87f536 as its origin; Runner enforcement, limit diagnostics, and the normative backend table already use 8,388,608/67,108,864 bytes. The support contract now reports those authoritative values, t/1558 asserts the direct contract, and t/297 asserts the published capability manifest. Impacted contract/capability/exact-Verilator regression reports All tests successful at Files=4/Tests=21. All 52 mdBook chapters test, the rendered aligned-limit paragraph is structurally distinct, the repository-local build contains 88 files/18,336,328 bytes before exact removal, and maintained-reference authority accepts 0 files/-1 line/-82 bytes. Runner source/behavior, diagnostics, artifacts, capability set, support classification, backend qualification, and scale nonclaims are unchanged.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.6: align support transcript limits`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.7`
  Status: `done`
  Goal: `Remove the stale hard-coded focused-document member-count shadow from the containment regression.`
  Acceptance: `From a separate clean activation, apply decision 0054 to t/1569-focused-document-containment.t: consume the focused-document indexer's successful current census rather than storing a second mutable literal count; retain proof that the real index is current and complete, retain all generated-index unclassified/stale/duplicate/escaping/empty-group and semantic-part negative gates, and change no surface membership, ceiling, classifier, product behavior, or scale claim.`
  Verification: `Clean activation commit 44ad589ce owns the repair. git log -S'1022 members' identifies 70ba62f35 as the stale shadow; the assertion now accepts only the indexer's complete successful nonzero current-census record and stores no mutable member count. scripts/focused_document_index.pl check remains byte-current at 1,023 members/1,090 lines/149,801 bytes. Perl syntax passes and the focused containment/reference suite reports All tests successful at Files=4/Tests=36. Every existing stale/unclassified/duplicate/escaping/empty-group and semantic-part negative remains exercised; membership, classifier, ceilings, generation, and product behavior are unchanged.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.7: derive focused-index census`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.8`
  Status: `done`
  Goal: `Reconcile the accepted scale decisions with completed transcript-limit alignment before workload automation consumes them.`
  Acceptance: `From a separate clean activation, append an execution-status correction to decisions 0055/0056 and their index summary: preserve the exact selection-time discrepancy and rationale, record .17.6 commit 5db70fa08 as the completed 8-MiB/64-MiB support-accounting alignment, remove no historical evidence, and change no workload contract, implementation, runtime, capability, support classification, or scale claim. Complete this leaf before activating .17.2.`
  Verification: `Clean activation commit 8201334c4 owns the reconciliation. Decisions 0055/0056 retain their exact selection-time discrepancy, rationale, and proposed-.17.6 text, but now identify it explicitly as historical audit evidence and record completed .17.6 commit 5db70fa08 as current authority for the aligned 8,388,608-byte compile and 67,108,864-byte runtime limits. The index records the same execution state. Decision records remain bounded; relative-path, task-tree, Knowledge Map, Memory, staged acceptance, and doctrine gates pass. No workload contract, implementation, runtime behavior, capability set, support classification, or scale claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.8: record transcript-limit execution`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.9`
  Status: `done`
  Goal: `Repair the public VIAL artifact transaction's failed-stage cleanup error collector and prove exact residue removal.`
  Acceptance: `From a separate clean activation, change only FSM::VIAL::ArtifactTransaction's File::Path remove_tree error collector from the invalid array reference to the required scalar reference; add a focused regression that forces failure after staging creation and proves the exact operation-owned tree is removed with a stable sanitized error. Audit every repository remove_tree error collector, retain successful/unchanged/collision/atomic-publication behavior, and change no artifact graph, target root, parser, plan, backend, runtime, capability, support, or scale claim.`
  Verification: `Clean activation commit 4e9382d8a owns the repair. Git history identifies planning-artifact implementation commit 045629c97 as the origin of the invalid array-reference File::Path error collector. ArtifactTransaction now passes the required scalar reference and checks the returned error array without changing any other transaction logic. The focused public CLI regression injects failure at the first staged artifact write, receives the exact sanitized VIAL_HOST_ERROR, proves both operation staging and target trees absent, then retries the identical operation through successful atomic publication. Repository-wide source audit finds six production remove_tree error collectors and all six now use scalar references; test-only uncollected teardown calls remain semantically separate. Module/test syntax and t1556 pass at Files=1/Tests=6; the public source/planning/real-Verilator/AHB-parity impact suite passes at Files=4/Tests=20. The existing mdBook atomic-publication contract now explicitly records post-staging cleanup/retry behavior. Task/Knowledge Map/Memory/live-reference/staged acceptance/doctrines pass with no VIAL operation/test/mdBook/.bin/.log residue. Successful, unchanged, collision, symlink/traversal, artifact graph, target root, parser, plan, backend, runtime, capability/support, and scale behavior remain unchanged.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.9: repair failed-stage cleanup`

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
Active container `.13` and completed `.13.1` own five full-shaped reviewable emission
leaves that do not wait for simulation. Completed `.13.1.1` ships the private
emitter substrate, structural validator, exact capability truth, and first
byte-checked artifact gallery. Completed `.13.1.2` ships complete topology,
timed interfaces, lifecycle, and notification/interception structures.
Completed `.13.1.3` ships active stimulus, TLM, scoped factory/configuration,
private RAL, and constrained-decision replay/preview structures. Completed
`.13.1.4` ships public coverage/property/model/scoreboard/fault structures,
typed diagnostic/result collection, and a bound SVA review checker in the
revision-4 fourteen-artifact graph. Completed `.13.1.5` ships the revision-5
sixteen-artifact graph, 25-row selected mapping matrix, deterministic gallery
workflow, and exact deferred-runtime defect boundary. Completed `.13.2` ships
the exact reusable Verilator-5.046/UVM-2020.3.1-vlt experimental probe, repairs
the invalid generated `context` identifier, proves the isolated UVM library
through runtime smoke, and classifies the complete generated fixture as
tool-limited before runtime without advertising support. Director-deferred
`.13.3` remains unavailable until capability-ready PGEN and NEXSIM releases
provide exact provider evidence. Clean predecessor
`adc88817e` activates `.14` alone for VHDL-2008 methodology/backend contract
selection; selection and implementation remain unperformed.
Decision `0034` records that
this bounded profile is not VIAL's language ceiling: target SV/UVM/VHDL
machinery is compiler-owned in the same architectural sense that assembly is
compiler-owned beneath C/C++ or Rust.

Completed `.15.5` repository-locally materializes and qualifies the exact
official macOS ARM64 GHDL 6.0.0 LLVM-JIT profile. Analysis, elaboration,
bounded runtime, timed four-state behavior, a closed normalized result,
deterministic rerun, applicable portable-SV parity, resource controls, and
exact same-volume cleanup pass. Completed `.15.6` materializes exact recursive
OSVVM 2026.05 and ships its structurally reviewed advanced adapter/gallery.
Completed `.15.7` qualifies the combined exact tuple through 61-source
provider compilation, generated analysis/elaboration/runtime, unchanged
normalized result and parity, deterministic OSVVM reports, bounded support,
and exact same-volume cleanup.

The 2026-08-10 tool census leaves `.16` proposed: separately available
Verilator, Icarus, and repository-local GHDL are not a mixed-language runtime,
and no compatible mixed-language simulator is installed. Completed `.17.1`
selects decisions `0055`/`0056` and the architecture-scale contracts without claiming
capacity. Its audit finds one pre-existing support-snapshot limit drift;
completed `.17.7` removes the stale focused-document regression shadow without
storing a replacement count. Completed `.17.6` aligns the support snapshot and
completed `.17.8` records that execution in the accepted decisions. Decision
`0057` and completed `.17.2.1` now ship the bounded source-only workload
catalog, identity, payload, and staging foundation without claiming capacity.
Completed `.17.9` then repaired the independently reproduced
`ArtifactTransaction` failed-stage cleanup collector and proved exact residue
removal, unblocking semantic-family generation.

Generation now proceeds family by family. Completed `.17.2.2` ships the
canonical semantic-catalog workloads through the ordinary parser and validator.
Completed `.17.2.3` activated the bridge-fanout family; `.17.2.3.1` selected
decision `0060`'s qualification-only direct-IAL1 profile and `.17.2.3.2`
shipped its canonical workloads. Completed `.17.2.4` now ships the execution-
graph family: `.17.2.4.1` selects decision `0061` and the exact 13-axis
reachability matrix, `.17.2.4.3` selects decision `0072`, and `.17.2.4.2`
implements the 40 selected shapes across the binding, topology, fiber, type, and
map gates, the complete random and serialized-plan ladders, the full scenario
ladder, the complete operations-per-scenario ladder, and both complete fiber
ladders. The operation ladder is the first selected pair whose own nominal cap
never wins: the serialized-plan cap rejects 65,536 operations and the semantic
expanded-action cap rejects 65,537, each recorded as a
`VIAL_SCALE_LIMIT_INTERACTION` discrepancy routed to `.17.4`. The live-fiber
ladder is the first axis to reach its own cap with an accepted plan, at exactly
16,384. The total-fiber ladder closes the pair and is the first whose limit and
over-limit levels answer to *different* authorities: both are authored compactly
with the ordinary `repeat` form because the literal one-record-per-fiber source
saturates at 22,536 fibers, `limit_v1` reaches the structural 65,536 cap and is
then rejected by the 16-MiB plan cap with one discrepancy routed to `.17.4`, and
`over_limit_v1` is rejected by the total-fiber cap itself before any plan is
serialized, with none. The total-operation ladder then closes the family and is
the first whose two levels differ in *proof method* rather than only in
authority. Its literal 32-scenario recipe can author neither: 1,000,000 literal
resets need 14,003,075 source bytes against the 1,048,576-byte parser cap, so
that form saturates at 74,656 operations, and 1,000,001 is not divisible by the
fixed fanout at all. Both levels therefore use the same ordinary `repeat` form,
which puts either count into 4,003 source bytes. Measurement decides the rest:
an operation graph costs about 5.0 KiB of resident state per operation, so
`over_limit_v1` is proved by a real run at a measured 11 seconds and 5,216-MiB
peak descendant RSS, opt-in behind `FSMGEN_VIAL_SCALE_EXACT` at a raised
6,144-MiB cutoff, and rejects at its own cap with no discrepancy; while
`limit_v1` is `preflight_dominated`/`not_materialized` under decision `0061`
clause 8 against the 65,536-operation witness that already serializes
21,511,563 bytes past the 16-MiB cap, recording one
`VIAL_SCALE_LIMIT_INTERACTION` and one `VIAL_SCALE_PREFLIGHT_DOMINANCE` routed
to `.17.4`. The execution-type qualification level closes next and is the first whose
authority moved because the *stage order* was corrected rather than because a
count changed: decision `0061` clause 4 evaluates VIAL source and SemanticIR
before the canonical bridge, the direct-IAL1 route did not, and with that fixed
the ordinary parser's own 4,096-declaration package-section cap rejects 8,192
types at `/packages/0/types` from a source comfortably inside the byte cap. The
route's measured boundary is lower still at 1,043 types, bounded by the 16-MiB
serialized bridge-manifest cap rather than by the 4,096-type or 4,096-endpoint
cap, so this axis also has no nominal operating point above its 512-type gate.
The high `bindings`, `execution_types`, and `source_map_records` levels all
share the same selected-authority mismatch: the generated source
exceeds the workload's own 1,114,112-byte construction envelope before any
product cap is consulted, and unlike fibers and operations, event, type, and
endpoint declarations have no compact `repeat` form to reach the product cap.
Each axis's genuine boundary is measured and far lower than its selected levels
— 2,054 bindings at the bridge's 2,048-event cap, 1,043 execution types at the
16-MiB serialized-manifest cap, and 46,294 source-map records at the 16-MiB
serialized-plan cap. Completed `.17.2.4.3` and accepted decision
`0072` now select the treatment: keep both the levels and the envelope, because
the levels are the execution contract's own declared caps and the envelope is
only the first obstacle, and instead require every unreachable level to report
three numbers — its declared cap, the earliest cap that actually decides, and
its measured route boundary — under an `envelope_unconstructible` /
`not_constructed` outcome carrying paired `VIAL_SCALE_LIMIT_INTERACTION` and
`VIAL_SCALE_ROUTE_BOUNDARY` records. The measured boundaries are 2,054 bindings,
1,043 execution types, and 46,294 source-map records, 32x, 63x, and 22x below
their declared 65,536 / 65,536 / 1,000,000 caps; the cross-layer inconsistency
between `VIALExecutionContract` and `HIALVIALBridgeContract` that causes it is
routed to `.17.4`. `.17.2.4.2` is unblocked and owns implementation, and the
binding ladder is the first axis authored under the new rule: all three levels
above its gate report `envelope_unconstructible` / `not_constructed` with the
constructor's exact diagnostic, no retained source, no stage identity, a refused
build, and both required records — the fixture-bound interaction and the measured
2,054/2,055 boundary at the bridge's 2,048-event cap. The two highest
execution-type levels now report the same selected result with exact
2,413,815/2,413,852-byte HIAL sources and the measured 1,043/1,044 route
boundary. The three source-map levels now complete the treatment with exact
3,670,808 / 14,000,792 / 14,000,806-byte VIAL sources, the input-1 envelope
diagnostic, no retained source or stage identity, refused builds, and the
measured 46,294/46,295 route boundary. The partitioned reachability cards retain
every prior answer key exactly once. Final RAM-guarded qualification passes all
29 architecture-scale files / 135 tests in 1,114 seconds. `t/1603` freezes the
completed selection as 40 owned shapes, 13 deliberately unselected reference
profiles, and 12 deliberately unselected fixed-scalar profiles, all fail-
closed. Completed `.17.2.5` implements and qualifies every checking-state axis:
32 selected non-reference shapes are owned, the eight reference profiles fail
closed, default t/1629-t/1635 passes at Files=7/Tests=36, and the complete exact
matrix passes at Files=5/Tests=27 under the repository RAM guard. Completed
backend-emission selection `.17.2.6.1` and decision `0075` now own the exact
portable operation ladders, native-UVM adjacent negotiation boundary,
profile-local structural oracles, and four diagnosed behavior defects. Completed
repair parent `.17.2.6.2` closes its five ordered leaves: `.17.2.6.2.1` through
`.17.2.6.2.4` provide linear portable-VHDL
validation and source-map anchoring, callback-scoped sealed OSVVM provider
verification, complete wrapper map translation, and fail-closed native-UVM
selected-shape negotiation; `.17.2.6.2.5` aligns one closed exact catalog and
support authority and qualifies the repaired family. Completed generator
`.17.2.6.3` includes shared foundation `.1`, portable-SV `.2`, portable-VHDL
`.3`, OSVVM `.4`, native-UVM `.5`, and family closure `.6`; all six children
are complete and freeze the exact thirteen-emitted/seven-rejected profile
partition. Completed runtime/balanced parent `.17.2.7` owns runtime-stream
construction `.1`, balanced revision-2 composition and portable structural
emission `.2`, and unified provider-free qualification `.3`; parent `.17.2`
therefore closes deterministic generation. Measurement parent `.17.3` is now
active. Completed foundation `.17.3.1` owns the closed record, sampler,
controller, active-guard evidence, and repository-volume lifecycle without an
external verification-tool run. Semantic/bridge measurement `.17.3.2` is now
active and alone owns its family adapter, watcher, and raw evidence before
execution/checking or external-tool measurement can begin.

## Decisions

- `2026-08-22`: Activate unified provider-free construction qualification
  `.17.2.7.3` only after clean balanced-emission commit `ebf98fbbd` completes
  both prerequisite families. Require one closed independent family evaluator
  over the full runtime profile/level and balanced partition, canonical report
  regeneration, applicability/nonclaim authority, hostile mutation rejection,
  and repository-volume cleanup. Add no external execution, runtime result,
  public API, support, performance, capacity, or reached-boundary claim.

- `2026-08-22`: Complete balanced portable-SystemVerilog emission child
  `.17.2.7.2.4` and parent `.17.2.7.2` without activating `.3` in the dirty
  implementation tree. Keep the route private and caller-sealed at composition,
  backend-input, and emitter boundaries; require exact full-shape negotiation,
  complete operation/binding source-map coverage, content-addressed byte-equal
  reruns, atomic mutation rejection, and exact repository-volume cleanup. The
  qualification ends at structural artifacts and adds no compile, runtime,
  trace, result, support, performance, capacity, or reached-boundary claim.

- `2026-08-22`: Activate balanced portable-SystemVerilog emission child
  `.17.2.7.2.4` only after clean canonical-composition commit `d2305a59a`.
  Require emitter-specific negotiation of the complete revision-2 bridge and
  ExecutionIR identities, deterministic structural coverage, atomic failure,
  mutation rejection, and exact cleanup; reject label-only admission and add no
  public, runtime, support, performance, capacity, or reached-boundary claim.

- `2026-08-22`: Complete canonical balanced composition child
  `.17.2.7.2.3` without activating emitter qualification in a dirty tree. Use
  one closed caller-sealed composer to regenerate ordinary HIAL/VIAL, freshly
  evaluate all six prerequisite families, and independently rebuild the
  complete revision-2 source-to-plan route plus keyed replay. Retain portable
  emission, external execution, support, performance, capacity, and reached-
  boundary claims for their separate owners; `.2.4` remains proposed for a
  clean activation slice.

- `2026-08-22`: Activate canonical balanced composition child `.17.2.7.2.3`
  only after clean bridge/binder commit `4b11043ff`. Require fresh evidence from
  all six orthogonal gate constructors and ordinary source-to-ExecutionIR
  production; defer portable-emitter negotiation to `.2.4` and add no runtime,
  support, performance, capacity, or product claim.

- `2026-08-22`: Complete balanced bridge/binder child `.17.2.7.2.2` without
  activating `.2.3` in the dirty implementation tree. Keep revision 2 private,
  direct-IAL1, content-addressed, exact-shape, and independently revalidated at
  ExecutionIR admission; preserve public AHB, revision 1, portable emission,
  support, runtime, performance, and capacity behavior.

- `2026-08-22`: Activate balanced portable composition `.17.2.7.2` after clean
  provider-free runtime commit `3c1f0b411`. Consume the exact decision-`0055`
  interaction profile and fresh successful reports from every completed
  orthogonal constructor; do not create a shadow catalog, execute a provider or
  external tool, or claim runtime, support, performance, or capacity.

- `2026-08-22`: Activate runtime-stream/balanced integration `.17.2.7` after
  clean backend-emission closure commit `86faa137d`. Decompose provider-free
  construction into runtime-stream `.1`, balanced portable `.2`, and unified
  qualification `.3`; activate `.1` alone. Consume decisions `0055`/`0056`
  and existing catalog authorities without executing an external tool or
  claiming a trace boundary, runtime result, performance, support, or capacity.

- `2026-08-22`: Complete backend-emission family closure `.17.2.6.3.6` and
  close generator parent `.17.2.6.3` plus structural-generation parent
  `.17.2.6`. Derive all twenty catalog outcomes without a shadow family API,
  independently reconstruct one reference and adjacent rejection per profile,
  freeze the exact thirteen-emitted/seven-rejected partition, authority/oracle
  applicability, defensive evidence, nonclaims, and same-volume cleanup, then
  retain runtime-stream/balanced integration `.17.2.7` as the next proposed
  slice. Add no external runtime or product claim.

- `2026-08-22`: Activate backend-emission family closure `.17.2.6.3.6` after
  clean native-UVM implementation commit `d8dd1ce82`. Qualify the exact twenty-
  outcome family partition, family-wide authority/oracle applicability,
  defensive reports and cleanup, default/high-count matrices, emitter
  compatibility, and CI inventory before closing `.17.2.6.3` and `.17.2.6`.
  Activation adds no family report, runtime, API, capability/support,
  performance, capacity, or product claim.

- `2026-08-22`: Complete native-UVM route `.17.2.6.3.5` behind the shared
  foundation. Own five profile-level outcomes but construct artifacts only for
  the exact T=21 selected review graph; reuse the adjacent T=22 negotiation
  witness for every non-reference level and label later levels preflight-
  dominated/not-constructed. Freeze exact artifacts, source identities, maps,
  intentional operation associations, checks, mappings, workflow, byte-equal
  reruns, rejection atomicity, defensive evidence, cleanup, and every compile,
  runtime, result, support, performance, capacity, and scale nonclaim. Keep
  family closure proposed until a clean successor activation.

- `2026-08-22`: Activate native-UVM route `.17.2.6.3.5` after clean OSVVM
  implementation commit `b8969b525`. Own only the exact T=21 selected review
  graph plus T=22/larger/changed-same-count pre-artifact rejection; keep family
  closure proposed and retain every compile, runtime, result, support,
  performance, capacity, and native-UVM scale nonclaim.

- `2026-08-21`: Complete OSVVM ladder `.17.2.6.3.4` behind the shared
  foundation with one caller-sealed profile module. Verify the exact provider
  once per evaluation and reuse only its callback-scoped opaque capability for
  both emissions; freeze adapter-first plus complete portable source-map
  translation, provider/source identities, structural checks, semantic guards,
  byte-equal reruns, earliest portable-foundation rejection, and cleanup. Keep
  native UVM and family closure proposed until a clean successor activation.

- `2026-08-21`: Activate OSVVM ladder `.17.2.6.3.4` after clean portable-VHDL
  implementation commit `7199de481`. Keep native UVM and family closure
  proposed and change no generator, emitter, validator, provider, artifact,
  runtime, API, capability/support, performance, or capacity behavior in the
  activation slice.

- `2026-08-21`: Complete portable-VHDL ladder `.17.2.6.3.3` with a
  caller-sealed profile module behind the shared foundation. Own exactly all
  five selected shapes, retain the numbered-source response-expectation
  recipe and adjacent portable 16-MiB rejection, and activate no sibling until
  this slice commits cleanly.

- `2026-08-21`: Activate portable-VHDL ladder `.17.2.6.3.3` after clean
  portable-SystemVerilog implementation commit `5d309b0eb`. Keep OSVVM,
  native-UVM, and family closure proposed and change no generator, emitter,
  artifact, runtime, API, capability/support, performance, or capacity
  behavior in the activation slice.

- `2026-08-21`: Complete portable-SystemVerilog ladder `.17.2.6.3.2` with a
  caller-sealed profile module behind the shared foundation. Own exactly all
  five selected shapes, retain the measured `scale_response_zero` recipe and
  adjacent 16-MiB rejection, and activate no sibling until this slice commits
  cleanly.

- `2026-08-21`: Activate portable-SystemVerilog ladder `.17.2.6.3.2` after
  clean caller-sealed foundation commit `8e9553a3b`. Keep all other profile
  ladders proposed and change no generator, emitter, artifact, runtime, API,
  capability/support, performance, or capacity behavior in the activation
  slice.

- `2026-08-21`: Activate `.17.2.6.3` after clean repair-family commit
  `2d7b3b27e`. Decompose implementation into one caller-sealed foundation,
  four profile-local ladders, and one exact family-qualification closure. Keep
  only foundation `.1` active and leave all emitter/product behavior unchanged.

- `2026-08-21`: Complete `.17.2.6.2.5` and repair parent `.17.2.6.2`.
  Keep every backend-emission structural authority in one closed defensive
  source and project it into workload construction plus VHDL/native-UVM
  discovery. Reject unknown, missing, obsolete, or contradictory fields;
  activate generator `.17.2.6.3` only after this family commits cleanly.

- `2026-08-21`: Activate `.17.2.6.2.5` after clean native-UVM repair
  `9c92b27f9`. Reconcile the exact repaired OSVVM and native-UVM authorities,
  reject contradictory catalog inputs, and qualify the five-leaf repair family
  before generator `.17.2.6.3` can activate. This continuity slice changes no
  implementation or product behavior.

- `2026-08-21`: Complete `.17.2.6.2.4`. Treat the native-UVM review renderer
  as one closed 21-operation capability, including exact operation order,
  scenario partition, fiber bounds, resource count, and expectation roles.
  Reject adjacent, larger, or different same-count shapes before artifact
  construction; activate final catalog/support alignment `.2.5` only after the
  implementation commits cleanly.

- `2026-08-21`: Complete `.17.2.6.2.2`. Verify the exact recursive provider
  once at callback evaluation entry, keep evidence in a lexical registry,
  provide only defensive clones to matching local emissions, and delete the
  capability on callback success or failure. Standalone emission continues to
  verify independently; activate OSVVM source-map translation `.2.3` only after
  this implementation commits cleanly.

- `2026-08-21`: Activate `.17.2.6.2.2` only after clean portable-VHDL repair
  commit `c3810ba8a`. First capture repeated recursive provider verification,
  then seal one exact evaluation-local result against provider/source identity;
  map translation and the later repair siblings remain inactive.

- `2026-08-21`: Complete `.17.2.6.2.1`. Build one exact metadata index and one
  source-line/end-column index per emitted source, preserving all structural
  rejection while accepting `T=29,508` twice and retaining atomic `T=29,509`
  rejection inside the selected ceiling. Activate OSVVM provider-reuse `.2`
  only after this implementation commits cleanly.

- `2026-08-21`: Activate `.17.2.6.2` only after clean selection commit
  `0a3a2a05f`; decompose decision `0075`'s five repairs in dependency order and
  make portable-VHDL validator linearization plus the accepted boundary proof
  the sole active implementation leaf.

- `2026-08-21`: Accept decision `0075`. Use the checked-AHB anchored
  response-expectation operation total as the profile-specific portable scale
  recipe; retain the earliest source, portable-foundation, or negotiation
  authority; and keep native UVM at its explicitly selected review matrix.
  Repair VHDL validator complexity, reusable sealed OSVVM provider preflight,
  OSVVM translated source-map closure, native-UVM fail-closed negotiation, and
  exact catalog/support authority before generator implementation.

- `2026-08-20`: Accept decision `0073`. Keep every `checking_state_v1`
  level, report its exact accepted-or-earliest-cap outcome, and use one
  provider-free packed-state evaluator for canonical stateful semantics. A
  one-million scoreboard stores four packed payload bytes per entry and drains
  exactly; a one-million coverage vector stores one bit per static bin/tuple.
  Refine decision `0055`'s impossible tuple-list wording to the older shipped
  VIAL contract: an explicitly authored cross's static domain is the Cartesian
  product of its explicitly authored point bins, and nothing outside that
  domain may be invented. Keep all backend, runtime, support, performance, and
  capacity nonclaims.

- `2026-08-10`: Accept decisions `0058`/`0059`. Scope scenario-local handles
  and expectations under their named scenario, and scope fibers under both
  their scenario and the structural path of the unnamed parallel action. Keep
  the current repeat and expanded-action caps unchanged in this generation
  leaf; record the earlier 65,536-action rejection and route limit-policy
  repair exclusively to `.17.4` rather than inventing repeat capacity.

- `2026-08-10`: Accept decision `0057`. Derive source-byte correctness
  candidates from their declared caps at one-sixteenth and one-quarter, use
  exact valid bytes at the limit, and cross the limit only with the first
  complete valid referenced record. Bound the shared source-only constructor
  above those product caps, keep backend bytes as genuine measured output,
  reuse fixed seed 1701 plus the shipped counter/rejection algorithm, and
  remove repository-volume staging on every outcome. None is a capacity or
  performance-budget claim.

- `2026-08-10`: The generated focused-document index and its own checker agree
  on 1,023 members, but `t/1569` retains the 1,022-member literal added before
  the registered OSVVM gallery README. Do not update one stale shadow to
  another. Completed `.17.7` applies decision `0054`: the test consumes the
  complete successful nonzero census reported by current indexer authority
  while retaining its complete negative matrix.

- `2026-08-10`: Accept decisions `0055`/`0056` and prove scale with six orthogonal
  workload families plus one conservative balanced candidate. Correctness
  oracles gate every measurement; fixed RAM/time safety applies immediately;
  performance budgets derive immutably from clean pinned-host calibration and
  never self-adjust. Treat the earliest authoritative cap honestly and retain
  whole-product, multi-unit/domain, mixed-language, native-UVM-runtime, full-
  language, synthesis, and general-parity boundaries. The audit finds Runner /
  normative-contract 8-MiB/64-MiB transcript capture but a 4-MiB/4-MiB support
  snapshot from the same implementation commit. Completed `.17.6` aligns the
  snapshot and regression-locks direct and published accounting before scale
  automation consumes it.

- `2026-08-10`: Keep `.16` proposed after an exact availability census finds
  no compatible mixed-language execution tool; never combine independent
  Verilator and GHDL results into a mixed-language claim. Select `.17` because
  the portable SystemVerilog, VHDL, and OSVVM contracts are now stable and
  executable enough to define architecture-specific scale workloads and
  budgets. Decompose scale work into contract, deterministic generation,
  measurement, graceful caps, and stable closeout so calibration evidence is
  never conflated with product support or whole-product qualification.

- `2026-08-09`: Resolve the exact OSVVM project-file order for GHDL
  VHDL-2008 into 44 core and 17 Common sources and compile it without a
  cross-volume project cache. Keep OSVVM reports supplementary: a dedicated
  probe may runtime-exercise six adapter families and analysis-qualify the
  Common address-bus type, while only the unchanged portable trace/result and
  its nineteen applicable parity paths decide semantic success.

- `2026-08-09`: Materialize the complete official OSVVM 2026.05 superproject
  recursively and freeze every repository by commit, tree, origin, and tracked
  entry count before emitting provider-dependent source. Treat tracked
  licence/notice presence as evidence, never as a place to infer missing legal
  coverage: the exact Documentation gitlink contains neither, while the
  code-bearing libraries carry locked Apache-2.0 files. Keep the provider
  adapter additive beside six byte-identical portable sources so OSVVM cannot
  change portable replay, phase order, comparison/coverage meaning, trace, or
  normalized results.

- `2026-08-09`: Qualify only exact GHDL 6.0.0 LLVM-JIT for the selected
  provider-free fixture. The matching LLVM AOT package analyzes and elaborates
  the source but fails its VHDL-2008 external-name adapter at runtime with a
  null access, so backend identity is part of the support claim. A returning-
  ready AHB sample may accept and complete the same transfer; the VHDL
  scheduler must mirror that portable-SV semantic boundary and wait through
  the complete two-cycle ERROR response before advancing.

- `2026-08-09`: Defer every NEXSIM-dependent runtime-qualification action
  represented by `.13.3` until capability-ready PGEN and NEXSIM releases
  provide exact identities and schemas. Activate `.15.5` instead because the
  selected official GHDL 6.0.0 macOS ARM64 artifact is now available; keep
  tool installation and all runtime claims outside this continuity commit.

- `2026-08-01`: Clean completed experimental-probe predecessor
  `adc88817e88fee47f1b1bd568761add02a93f655` permits `.14` to activate
  alone. Activation changes durable continuity only: it does not select
  OSVVM, UVVM, or no provider; inspect or freeze a tool/library version; alter
  the inert VHDL package; emit a new artifact; or claim VHDL analysis,
  elaboration, runtime, result, parity, PSL, or product support.

- `2026-08-01`: Select the exact experimental profile
  `sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0`.
  The repository-local immutable source checkout is CHIPS Alliance
  `uvm-verilator` ref `uvm-2020-3.1-vlt`, commit
  `656f20d087370a7c742e00188d20bbf30fa95339`, tree
  `882930bb7debe79b22234e4a8a53854549046778`; the unmodified comparison and
  canonical Accellera release identities remain recorded. `UVM_NO_DPI` is an
  experiment-wide deviation; `--bbox-unsup` belongs only to the separate
  fixture compile/elaboration attempt. Single-job, single-thread, split,
  unoptimized C++ is a bounded host-resource control, not a semantic change.

- `2026-08-01`: The first full-fixture diagnostic is a demonstrated FSMGen
  generator defect because `context` is a SystemVerilog keyword. Rename the
  emitted field to `vial_context`, regenerate the canonical gallery, and lock
  out the invalid declaration/dereferences. After correction, strict parsing
  reaches only Verilator's unsupported ranged-SVA delay; blackboxing that
  unsupported feature reaches a Verilator internal fault. These are separate
  tool limitations and do not justify provider conditionals in neutral output.

- `2026-08-01`: Experimental workflow completion is independent of every
  inner stage passing. The canonical report records pass, unsupported, failed,
  and not-run states separately, concludes `partial_tool_limited`, and keeps
  `product_support=false`. A control UVM runtime pass cannot qualify the
  generated fixture, produce a native result, prove parity, or change ordinary
  emission's not-run stage claims.

- `2026-08-01`: Clean completed-emission predecessor
  `7725789a44f1f4ccdfaadbde4d867b7610661680` permits `.13.2` to activate
  alone. Activation changes durable continuity only: it does not inspect or
  select a tool/library variant, run a probe, change generated source, or add
  parse, compile, elaboration, runtime, result, parity, or product-support
  evidence.

- `2026-08-01`: Close the selected native-UVM emission scope with a canonical
  matrix and review workflow, not a parser or simulator claim. Each of the 25
  emitted foundations records normal/terse source availability, typed-IR
  ownership, generated roles, realization, and independent maturity states.
  Repository-relative regeneration and non-mutating byte checks own the nine
  sources and two evidence snapshots; visual findings route to this task-tree
  with exact defect fields. Full UVM breadth and every parser-through-parity
  state remain unclaimed.

- `2026-08-01`: Clean implementation predecessor
  `193d170e0f59e837d7671455797ea4d096041c90` permits `.13.1.5` to activate
  alone after completed `.13.1.4`. Activation changes durable continuity only:
  no emitter byte, artifact graph, review gallery, public capability, parser,
  compile, elaboration, runtime, result, parity, or visual-review evidence
  changes.

- `2026-08-01`: Clean implementation predecessor
  `6463779bef0207a69ff95935d6908875b81cbddf` permits `.13.1.4` to activate
  alone after completed `.13.1.3`. Activation changes durable continuity only:
  no emitter byte, artifact graph, review gallery, public capability, parser,
  compile, elaboration, runtime, result, or parity evidence changes.

- `2026-08-01`: Emit portable scenario decisions into native UVM as immutable
  replay selections, not fresh UVM randomization. Revision 3 activates the
  selected agent with typed sequences, sequencer, driver, analysis/TLM wiring,
  exact scoped configuration, and one compiler-selected factory override. A
  fixture-specific RAL path and bounded native solver remain private typed
  previews. They exercise backend structure without claiming public VIAL
  authoring syntax, compile, elaboration, or runtime qualification.

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
- `2026-08-01`: Decision `0051` selects a provider-free VHDL-2008 portable
  core plus an OSVVM 2026.05 advanced tier, with GHDL 6.0.0 as the first exact
  qualification tool. UVVM 2026.03.20 is audited but not selected. Portable
  logical time, values, results, and parity remain VIAL/FSMGen authority;
  provider and simulator APIs are generated implementation/evidence layers.
  GHDL and OSVVM are absent locally, so `.15` may advance reviewable emission
  after activation but cannot publish analysis-through-runtime support yet.

## Open Questions

- Director-deferred `.13.3` must select exact PGEN/NEXSIM versions, handoff
  schema, semantic-introspection API schema, and MCP profile only after
  explicit reactivation against capability-ready releases.
- `.16` must choose the first available mixed-language tool/profile.
- `.17` must select measured architecture-specific capacity budgets; the
  separate whole-product scale tree retains big/really-big qualification.
- `.19` must convert decision `0034` into detailed implementable native-
  verification semantic-family leaves before the architecture closes.
- `.17.4` inherits an exact cross-layer defect from decision `0072`:
  `VIALExecutionContract` declares `bindings` 65,536, `execution_types` 65,536,
  and `source_map_records` 1,000,000 while `HIALVIALBridgeContract` declares
  `events` 2,048, `types` 4,096, `endpoints` 4,096, and a 16,777,216-byte
  serialized manifest, and the plan carries its own 16,777,216-byte cap. The
  measured route boundaries are 2,054 / 1,043 / 46,294, so three declared caps
  are unreachable by 32x, 63x, and 22x. Decide whether the execution caps come
  down to what the stack reaches, the lower layers go up, or the layering is
  documented as deliberate - and do not close `.17` while a declared cap that
  nothing can reach is still presented as an architecture limit.

## Blockers

- `.13.3` runtime qualification is director-deferred until capability-ready
  PGEN and NEXSIM releases exist. Commercial simulator availability is not a
  roadmap prerequisite, and Verilator/Icarus cannot be promoted from
  experimental evidence to `sv_uvm_qualified`.
- `.15.7` is complete: exact GHDL 6.0.0 LLVM-JIT and recursive OSVVM 2026.05
  are repository-local and their bounded combined profile is qualified. The
  pinned Documentation gitlink's absent tracked
  licence/notice metadata remains an explicit non-inferred packaging finding,
  not a code-bearing library or tool-availability blocker.
- Later UVM, VHDL, and mixed-language implementation/qualification leaves
  retain explicit tool availability prerequisites and cannot borrow the
  current Verilator result.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-08-24` | `.17.3.4.2` clean structural measurement matrix closure | producer-derived twenty-profile order and mode routing; isolated child capture and independent reload; calibrated file/IPC/error ceilings; immutable same-volume profile/family/complete publication; common identity; exact profile/sample/provider/dominance/artifact/hash census; hostile process/envelope/collision/recovery negatives; fresh-process guarded canonical reload; task/book/card/claim/containment continuity | `passed closure`; implementation commit `fdc6e6a1b` seals 20 reports plus family/complete manifests as 22 immutable files/2,232,452 bytes at complete identity `backend-emission-matrix/a5bb05a5f4be7fb364fbf52c6750b10e04417d53732f364158e6f143bc71f735`. Exact t/1662 passes Files=1/Tests=5 in 12,656 seconds under unchanged 88%-host/4,096-MiB-per-descendant guards; a separate guarded `--validate` returns the same 13-emitted/seven-non-emission, 24-raw/zero-excluded, five-provider, three-preflight partition. The largest 442,009-byte profile stays below the 524,288-byte ceiling; family/complete hashes are `fc9e43c1...72ea3`/`6c0fbc21...878a`; `.artifacts/tmp/vial-scale` is absent. No external-tool, compile/run/IASIM/trace/result, support, budget, capacity, reached-boundary, parity, or public-API claim is added. |
| `2026-08-24` | `.17.3.4.1` structural backend-emission measurement adapter | exact caller seal; anchored reconstruction; producer validation-before-retention; cumulative five-stage controller route; three/five raw sampling; native-UVM non-emission/dominance; OSVVM provider classification; mutation/defensive-return/failure/cleanup negatives; producer/common-controller/CI watchers; task/book/card/claim/containment continuity | `passed implementation`; default and final real-guard t/1661 pass Files=1/Tests=5, with the exact run completing in 724 seconds below unchanged 88%-host/4,096-MiB-descendant guards. Portable-SV gate retains three records, OSVVM qualification five, native UVM none, and all reports regenerate canonically with zero raw staging residue. External-tool, compile/run/trace/result, support, promoted-budget, capacity, reached-boundary, parity, and public-API nonclaims remain closed; proposed `.17.3.4.2` next owns immutable matrix publication/reload. |
| `2026-08-24` | `.17.3.3.2.3.1` clean 72-profile matrix closure | guarded clean capture, immutable host-cutoff resume, complete seal, separate canonical reload, exact residue/continuity gates | `passed closure`; revision `9c0209c22` seals all 72 profiles, both families, 119 raw records, and zero exclusions as 75 files/7,312,415 bytes at `execution-checking-matrix/0548629720a9f4c8636c912396cfaefff523da92fc800594618db68b788b91d0`. Reload returns the same identity with zero diagnostics; commit `040ab0e55` retains exact evidence and nonclaims. |
| `2026-08-23` | `.17.3.3.2.3.1` revision-037e56f09 prefix archive | exact 22-profile ordinal inventory; regular single-link payloads; clean capture identity; family/complete/raw absence; same-volume move with rollback; canonical manifest; independent file/byte/hash reconstruction; unrelated-active before/after identity | `passed archival checkpoint`; 22 reports/2,609,009 bytes are preserved under the exact revision-keyed archive with profile digest `6dbfa2d02f7eee0332881074628d50d2b454fe94ac241137a11d7c651c162d90`. The archive has 23 files including its canonical manifest; all 111 unrelated active files retain 7,418,437 bytes and digest `5b3e00bd52730b91a404cea009913bc782ceac6b9fe600bb4f21466b7f9a6e69`; active execution, raw-stage, and archive-staging counts are zero. Product code remains unchanged and the duplicate-search RED is next. |
| `2026-08-23` | `.17.3.3.2.3.1` bounded random-transcript implementation | product call-count RED/GREEN; decision-0079 UTF-8 byte framing/seal/bound/lifecycle; corruption and post-saturation authority negatives; exact 8,440/8,441/32,768/65,537 routes; exact one-million limit/exhaustion; isolated profile-23 adapter; staging/background census; task/book/card/claim/Memory continuity | `passed implementation`; accepted builders enter ExecutionRandom once per occurrence, reuse only a private 17,039,360-byte-maximum scalar transcript, reconstruct final records/maps/links independently, and preserve all terminal defenses. Exact adapter acceptance closes the former timeout without changing its 300-second ceiling, guard, attempts, plan identity, reruns, or nonclaims. The revision-037e56f09 prefix remains archived; a clean-revision 72-profile reseal is next. |
| `2026-08-23` | `.17.3.3.2.3` serialized-plan preflight implementation | honest materialization-sentinel RED; shared canonical report projection; streaming decision/scenario-ID/source-map byte deltas; saturating arithmetic; replay validation/indexing; occurrence/source-map/plan cap order; projection/terminal equality; private caller seal; syntax/diff; focused ordinary/random/replay/limit/exhaustion/measurement regressions; exact guarded 8,440/8,441, 32,768, and 65,537 routes; direct guarded former-timeout adapter; staging residue census | `passed implementation`; 8,441 and 32,768 return the byte-equal historical `/plan` diagnostic before random-list, ExecutionIR, or terminal report materialization; 8,440 remains accepted at 16,775,415 canonical bytes; 65,537 remains occurrence-cap dominated. The former adapter blocker exits `expected_rejection` / `validated_not_measured` with no diagnostic, measurement record, or staging residue under unchanged guards/timeouts. The focused guarded suite passes Files=7/Tests=33, exact t/1634 passes Files=1/Tests=5, and the private-seam/core contract passes Files=1/Tests=6. Terminal serialization and cap remain. No product support, performance, capacity, or reached-boundary claim is added; fresh clean-revision matrix capture remains next. |
| `2026-08-23` | `.17.3.3.2.3` revision-e4b95dbd evidence-prefix archival | same-volume device equality; exact 40 execution/17 checking profile admission; accepted 40-profile execution-family seal; per-file regular/single-link census; capture revision and dirty-state checks; independent post-move file/byte/hash/canonical-digest reconstruction; matrix identity; active/raw/staging residue census; unrelated active-evidence before/after digest | `passed`; the atomic archive contains exactly 57 reports/5,662,418 bytes, one 46,735-byte family manifest, and one archive manifest. Independent reconstruction matches profile digest `e8ba27e...25f0f9`, all-payload digest `c9147898...49170`, and matrix identity `execution-checking-matrix/5e99dcc5...e11b6a`. Active execution/checking evidence and raw staging are empty; all 111 unrelated files remain byte-identical at digest `e6538ea1...4125e`. Product code is untouched and preflight implementation remains pending. |
| `2026-08-23` | `.17.3.3.2.3` serialized-plan preflight activation | clean revision-e4b95dbd exact matrix under unchanged real guard; 40 execution and 17 checking atomic profiles; sealed execution family; absent checking-family/complete seals; exact direct guarded adapter disagreement; canonical `/plan` rejection versus bind-plan timeout; ExecutionBuilder construction/serialization/limit order; exact 8,440/8,441 and 32,768 plan boundaries; 65,536/65,537 dominance order; task/index/Memory/book/cards continuity | `passed activation`; canonical checking evaluation expects the existing 16,777,216-byte `/plan` rejection, while the worker times out after materializing all 32,768 random decisions and the complete plan. Active child `.17.3.3.2.3` owns a general independently derived byte-exact plan projection before known-excess allocation, with terminal serialization retained. No threshold shortcut, guard/timeout/cap change, partial publication, support, budget, capacity, or reached-boundary claim is admitted. The revision-bound 57-profile prefix and execution-family seal await verified archival after the activation commit. |
| `2026-08-23` | `.17.3.3.2.2` random-attempt correctness-repair activation | clean revision-14c619367 exact matrix under unchanged real guard; atomic publication stream; former profile-twenty operations-total excess; random-attempt gate/qualification/limit sequence; worker CPU/RSS and guard diagnostics; raw-stage/publication/family/full census; canonical t/1614 authority trace; Memory/task/index/book/card continuity | `passed activation`; the former operations-total blocker now seals, and 22 exact reports persist. Profile 23 `random_attempts/limit_v1` completes its one-million-attempt controller run but exits 75 because the correctness validation record does not accept; no guard termination, raw-stage residue, partial profile publication, or family/full seal occurs. Active child `.17.3.3.2.2` owns nested stage-diagnostic retention, first-disagreement root cause, focused repair, and same-revision resume without weakening the guard or random/replay contract. |
| `2026-08-23` | `.17.3.3.2.1` early total-operation enforcement implementation | compact-tree per-scenario rederivation; canonical positive repeat and nonempty parallel/repeat invariants; saturating bounded add/multiply; semantic action-count equality; inclusive 1,000,000/1,000,001 aggregate boundary; historical diagnostic equality; fatal bridge-index sentinel; real unchanged 88%-host/4,096-MiB-descendant guard; accepted ExecutionIR/topology, adjacent qualification, and measurement adapter; empty active publication/raw staging census; task/decision/Memory/book/card synchronization | `passed`; the exact excess returns `expected_rejection` in one second at Files=1/Tests=9 without entering bridge indexing, while the focused accepted/adjacent suite passes Files=4/Tests=19 in 80 seconds. The unchanged terminal cap remains as defense in depth, and malformed or forged compact counts fail internally. Parent `.17.3.3.2` next owns the fresh clean-revision 72-profile matrix; no guard, cap, diagnostic, support, performance budget, or capacity claim changes. |
| `2026-08-23` | `.17.3.3.2.1` early total-operation enforcement activation | clean repaired-revision exact capture under unchanged 88%-host/4,096-MiB-descendant guard; profiles 1-19 atomic publication; profile-20 isolated-worker 4,869.5-MiB termination/exit 137; ExecutionBuilder post-materialization limit locus; historical exact t1626 6,144-MiB prerequisite; revision-keyed archive manifest rederivation; decision 0078; task/index/Memory/book/card continuity; task integrity; Knowledge Map; all mdBook chapters; documentation-relative paths; syntax/diff checks | `passed activation`; per-profile isolation removes coordinator retention but the product still constructs nearly all 1,000,001 operations before enforcing the existing cap. Active child `.17.3.3.2.1` owns independent compact-count rederivation and identical early rejection before graph allocation. The failed prefix is preserved as 19 reports/1,739,213 bytes with canonical profile digest `a17d49f8...b9dd0`; active execution publications and raw staging are empty. Implementation remains pending and neither guard, cap, diagnostic, accepted behavior, support, performance, nor capacity changes in activation. |
| `2026-08-23` | `.17.3.3.2` isolated-profile coordinator activation | two real unchanged-guard captures; nineteen immutable profile envelopes; original and fresh-resume process RSS cutoff diagnostics; zero raw staging; absent execution family/full seals; exact origin trace to 3ccc4f5b9 `_capture_family`/`_load_report_publication`; clean tracked revision; task/index/Memory/book/fact continuity | `passed activation`; both runs stop before `operations_total/over_limit_v1`: 5,009.4 MiB on the original process and 4,936.7 MiB after independently resuming all nineteen stored reports. The repeated clean-frontier result falsifies simple crash residue and fresh-process explanations. `.17.3.3.2` exclusively owns guard-visible per-profile process isolation; implementation is pending and neither guard threshold nor retained evidence changes. |
| `2026-08-23` | `.17.3.3.1` interruption-safe raw-stage recovery | honest retained-orphan RED; stable per-stage same-volume advisory lock; close-on-exec descriptor; live-contention rejection; recursive real-directory/regular-single-link/device census; symlink/FIFO/hard-link preservation and rejection; validated orphan reclamation; exact parent pruning and ordinary fresh-run cleanup; real interrupted execution-bindings gate/03 recovery witness; shared qualification-namespace rollback correction; exact/default foundation and adjacent adapter/publisher regressions; project-locality and CI-inventory coverage | `passed`; the retained guard-interrupted tree is reclaimed only by the new protocol, and its replacement adapter report accepts three raw samples with zero exclusions/residue. Exact t/1656 passes Files=1/Tests=5 under the real 88%-host/4,096-MiB-descendant guard; t/1657-t/1660 pass Files=4/Tests=17; t/1527 passes Files=1/Tests=20; t/1183 passes Files=1/Tests=12 in 33 seconds. No execution/checking profile, family, or complete publication exists yet; the exact clean-revision capture remains post-commit.` |
| `2026-08-23` | `.17.3.3` resumable execution/checking matrix publisher | honest missing-module RED; exact 72-profile producer-owned inventory; closed report-envelope/profile/family/complete schemas; source-free capture provenance without controller-identity substitution; clean-revision and common host/tool/guard admission; immutable same-volume per-profile publication; family/full seal withholding; collision and ambiguous-staging rejection; canonical guarded reload; runner inventory/capture/validate interface; fast adapter/publisher and CI-inventory regression; task/index/Memory/book/fact/rationale/claim/containment continuity | `passed`; the publisher owns 40 execution and 32 checking profiles across four levels, accepts no caller report list, requires the real 88%-host/4,096-MiB-descendant guard for capture and revalidation, preserves every raw sample/exclusion and all four authoritative outcome classes, and leaves exact capture to the next clean-revision slice. Syntax and diff checks pass; t/1659+t/1660 pass Files=2/Tests=8, and t/1183 passes Files=1/Tests=12 in 50 seconds. All 54 book chapters test; the inspected 89-file/19,188,836-byte same-volume render is removed exactly, and the source remains 51,532 lines/2,737,956 bytes under a zero-line/+947-byte authority. Knowledge Map parity is 1,150 facts/6,071 questions/6,238 occurrences/133 shards; claims close 1,468 candidates plus 2,114 current/615 original constants as 879 gates/589 reviewed/zero gaps. No exact profile, family, complete-matrix, performance-budget, support, capacity, reached-boundary, provider, backend, compile, run, trace, or result claim is added.` |
| `2026-08-23` | `.17.3.3` caller-sealed execution/checking measurement adapter | honest missing-module RED; exact family-authority/report/nonclaim schemas; canonical execution/checking reconstruction; caller-sealed producer handoff; independent construct/parse/bridge/bind-plan payload reruns; validation-before-measurement admission; three/five guarded ordinals; exact parser rejection and preflight stage applicability; source-free outcome without invented workload/controller identity; raw record/exclusion/cleanup preservation; independent report regeneration; hostile caller/report/evidence mutation; forced worker failure; exact guarded and adjacent regression coverage; task/index/Memory/book/fact/claim/containment continuity | `passed`; exact t/1659 passes Files=1/Tests=5 in 252 seconds under the real 88%-host/4,096-MiB-descendant guard, retaining three gate and five qualification records with no exclusions and exact staging cleanup. The six-file focused set passes Files=6/Tests=26 in 61 seconds; CI inventory passes Files=1/Tests=12. The 54-file/51,532-line/2,737,009-byte mdBook tests and its inspected 89-file/19,181,514-byte repository-local render are removed exactly. Task integrity remains three trees/979 nodes; Knowledge Map parity is 1,150 facts/6,070 questions/6,237 occurrences/133 shards; claims close 1,468 candidates plus 2,114 current/615 original constants as 879 gates/589 reviewed/zero gaps. No provider, external tool, backend emission, compile/run/trace/result, public product API, performance-budget, support, capacity, or reached-boundary claim is added. Exact resumable execution/checking matrix publication remains next under `.17.3.3`. |
| `2026-08-22` | `.17.3.3` execution/checking measurement activation | clean semantic/bridge predecessor `9980fe5c1`; decisions `0055`/`0056`; completed execution/checking producer and oracle boundaries; owned-shape and stage-applicability derivation; unchanged guarded execution foundation/binding-boundary/checking qualification; task/index/Memory/book/fact/claim/containment continuity; task-tree, Knowledge Map, project-locality, relative-path, mdBook, claim, live-document, diff, docs-only staged acceptance, and doctrine gates | `passed`; `.17.3.3` alone is active to add caller-sealed provider-free execution/checking measurement through construct, parse/validate, bridge, and bind/plan. The guarded focused family suite passes Files=3/Tests=11 in 55 seconds. The 54-chapter mdBook test and inspected 89-file/19,167,723-byte repository-local render pass before exact removal; its 54-file source changes by zero lines/30 bytes under a fresh authority with no ceiling increase. Task integrity remains three trees/979 nodes; Knowledge Map parity is 1,150 facts/6,068 questions/6,235 occurrences/133 shards; claim inventory/disposition remains closed at 1,467 candidates plus 2,113 current/615 original constants as 878 derived gates/589 reviewed records/zero gaps. Activation changes no code, test, config, fixture, producer, oracle, sampler, artifact, external process, public API, promoted performance budget, support, capacity, reached-boundary, or product behavior. |
| `2026-08-22` | `.17.3.2` exact semantic/bridge matrix completion | clean `ece87892d`; guarded empty-namespace capture plus same-revision profile-boundary resume after external host-memory interruption; 108 report, two family-manifest, and one complete-manifest census; byte/digest derivation; complete/family dominance inspection; separate guarded canonical regeneration; captured exact/default watchers; staging and Git census | `passed`; 111 immutable files total 7,418,437 bytes with combined digest `6e0ac8da...102b`. Accepted identity `semantic-bridge-matrix/81ce1716...71bb3` retains 69 accepted/39 expected-rejection profiles, 48 applicable/six inapplicable measurement profiles, 186 raw/zero excluded records, one clean revision and guard identity, and no staging. Independent regeneration returns the same identity; exact t/1658 passes Files=1/Tests=3 in 2,386 seconds and proves the complete manifest unchanged. `.17.3.2` is done; `.17.3.3` activation is next. |
| `2026-08-22` | `.17.3.2.1` clean-revision closure | clean implementation commit `514761a4e`; exact old-revision 54-file/4,511,776-byte incomplete-publication re-census; absent family/full manifests and staging; exact namespace removal; real 88%/4,096-MiB RAM guard; source_bytes_combined/limit_v1 validation; independent report regeneration; stage/output/artifact/cleanup inspection; empty publication/staging and clean-Git census | `passed`; the exact removed ignored evidence is not file-recoverable, while its census, digest, and failure facts remain durable in task/Git. Clean validation plus independent regeneration completes in 56.893675 seconds with accepted_validation/accepted, parse_validate validated_unmeasured, one 4,514-byte output, eighteen censused artifacts, and exact cleanup. `.17.3.2.1` is done; parent `.17.3.2` resumes the full exact 108-profile capture from an empty namespace. |
| `2026-08-22` | `.17.3.2.1` truthful boundary measurement implementation | bounded-run ASCII lexer with retained Unicode cursor path; linear four-state value/known/Z normalization; successful-stage rederivation plus truthful rejected/not-run validation; injected worker-failure mutation; exact canonical evaluator and guarded profile-55 validation; focused impacted/core/exact family suites; task/index/Memory/book/fact/rationale/claim/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, live-document, diff, staged acceptance, and doctrine gates | `passed`; canonical profile-55 evaluation is 8.113775 seconds and its complete guarded adapter validation is accepted in 42.596013 seconds under the unchanged 120-second ceiling, with one canonical artifact and exact cleanup. Failed controller evidence is preserved rather than masked. This implementation commit changes no fixture, timeout, public API, provider/tool execution, performance budget, support, capacity, or reached-boundary claim; clean-revision proof and old incomplete-publication removal remain post-commit. |
| `2026-08-22` | `.17.3.2.1` truthful boundary measurement diagnosis/ownership | second clean guarded t/1658 capture at `363165d94`; 54-file incomplete-publication census and combined manifest digest; direct guarded foundation diagnostic; per-stage timeout/process/output/cleanup facts; guarded canonical evaluator and component timings; in-memory exact-codepoint-width falsification probe; decisions 0055/0056 and parser/adapter code trace | `active`; the fixed 120-second ceiling and no-padding fixture remain authoritative. The repair must preserve truthful failure evidence and eliminate the lexer hot path with semantic/span/Unicode parity; no invalid profile, family manifest, complete seal, support, capacity, or reached-boundary claim exists. |
| `2026-08-22` | `.17.3.2` exact matrix/adapter mode alignment | first clean guarded t/1658 capture at `b3a03d285`; exact pre-publication failure locus; adapter-level/report vocabulary audit; empty qualification/staging census; exact inventory vocabulary; guarded first-profile admission; focused syntax/default/adjacent coverage; continuity and doctrine gates | `passed`; capture had rejected `gate` versus sealed `gate_measurement` before publishing any profile. The inventory now uses the adapter's exact vocabulary, and the guarded first semantic profile admits all three raw gate samples. The clean 108-profile capture remains the active frontier. |
| `2026-08-22` | `.17.3.2` resumable semantic/bridge matrix publication implementation | honest missing-module RED; immutable 108-profile/four-level/fourteen-semantic/thirteen-bridge partition; clean-revision and active-guard admission; exact per-profile raw-report schema; same-volume atomic publication; byte-identical idempotence; collision and ambiguous-crash fail-closed boundaries; profile-level resume; family and complete census seals; common Git/host/tool/guard identity; dominance summaries; caller injection rejection; repository-root-derived CLI; focused/default/adjacent tests; isolated publication lifecycle probe; task/index/Memory/book/fact/rationale continuity | `passed`; the publisher implementation is complete and `.17.3.2` remains active for the clean guarded 108-profile capture. No matrix-completion, reached-boundary, external-tool, budget, support, or capacity claim is added. |
| `2026-08-22` | `.17.3.2` caller-sealed family measurement adapter implementation | honest missing-module RED; exact family-authority/sample-set schemas; canonical semantic/bridge reconstruction; independent per-stage rerun; validation-before-measurement admission; three/five guarded ordinals; original canonical evaluation artifact plus collision-checked path-safe evidence projection; raw records/exclusions; earliest-family outcomes; aggregate cleanup; defensive report regeneration and hostile mutation; explicit nonclaims; focused exact/common/adjacent tests; task/index/Memory/book/fact/rationale/claim/containment continuity; task-tree, Knowledge Map, project-locality, relative-path, mdBook, claim, live-document, diff, staged implementation acceptance, and doctrine gates | `passed`; the reusable adapter slice is complete while `.17.3.2` remains active for the complete selected profile matrix. No provider, external verification tool, performance budget, support, capacity, reached-boundary, or product behavior claim is added. |
| `2026-08-22` | `.17.3.2` semantic-catalog/bridge-fanout measurement activation | clean measurement-foundation predecessor `3946bf101`; decisions `0055`/`0056`; completed semantic constructor `145d3084a`; completed bridge constructor `97dda148d`; unchanged canonical family suite; exact provider-free stage/repetition/applicability/nonclaim boundary; task/index/Memory/book/fact/claim/containment continuity; task-tree, Knowledge Map, project-locality, relative-path, mdBook, claim, live-document, diff, docs-only staged acceptance, and doctrine gates | `passed`; `.17.3.2` alone is active to add canonical semantic/bridge family measurement through the common controller. Existing family tests pass Files=2/Tests=10. The 54-chapter mdBook test and inspected 89-file/19,133,640-byte repository-local render pass before exact removal; the maintained 54-file book grows by 24 lines/1,518 bytes under a fresh authority with no ceiling increase. Task integrity remains three trees/978 nodes; Knowledge Map parity is 1,150 facts/6,064 questions/6,231 occurrences/133 shards; claim inventory/disposition remains closed at 1,464 candidates plus 2,110 current/615 original constants as 875 derived gates/589 reviewed records/zero gaps. Activation changes no code, test, config, fixture, constructor, parser, SemanticIR, bridge, manifest, sampler, artifact, external execution, public API, performance budget, support, capacity, reached-boundary, or product behavior. |
| `2026-08-22` | `.17.3.1` architecture-scale measurement foundation implementation | honest missing-module RED; exact record/stage/publication schemas; canonical workload/Git/dirty/host/tool/run identities; validation-before-measurement admission; twelve ordered stages; fork-isolated stage ownership; 250-ms monotonic process-tree sampling; wall/controller/descendant CPU and summed-tree/single-descendant RSS; semantic/file/line/byte/object counters; explicit unsupported reasons; smaller-of timeout enforcement; active RAM-guard evidence; stage and aggregate artifact censuses; bounded worker capture; sanitized diagnostics; hostile record mutation; success/exception/timeout cleanup; same-volume atomic publication, idempotence, collision, and injected failure rollback; explicit nonclaims; syntax; guarded focused/adjacent and workload compatibility; task/index/Memory/book/fact/rationale/claim/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, diff, staged acceptance, and doctrine gates | `passed`; Files=2/Tests=8 exact guarded measurement/guard coverage and Files=1/Tests=7 adjacent workload coverage pass. The foundation executes no provider or external verification tool and publishes no family, compile, runtime, trace, result, performance-budget, support, capacity, or reached-boundary claim. `.17.3.1` is done; `.17.3.2` remains the proposed next measurement leaf. |
| `2026-08-22` | `.17.3` architecture-scale measurement activation | clean unified-qualification predecessor `490c35cc5`; decisions `0055`/`0056`/`0077`; absent measurement-schema/stage/run-ordinal implementation audit; nine-leaf decomposition; exact foundation/family/backend/tool/balanced/calibration ownership; task/index/Memory/book/fact/claim/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, live-document, diff, staged docs-only acceptance, and doctrine gates | `passed`; `.17.3` is active and `.17.3.1` alone owns the closed measurement schema/sampler/controller/lifecycle foundation before any external-tool run. Task integrity holds at three trees/978 nodes; Knowledge Map parity is 1,150 facts/6,059 questions/6,226 occurrences/133 shards; all 54 mdBook chapters test and its inspected 89-file/19,089,819-byte repository-local render is removed. The governed claim census remains complete at 1,459 candidates plus 2,105 current/615 original constants as 870 derived gates/589 reviewed records/zero gaps. The maintained book changes by zero lines/+260 bytes without a ceiling increase. Activation changes no code, test, config, fixture, generator, sampler, external execution, artifact, API, capability/support, performance, budget, capacity, reached-boundary, or product behavior. |
| `2026-08-22` | `.17.2.7.3` unified provider-free qualification implementation | missing-module RED witness; exact fifteen-runtime/one-balanced ownership; frozen checked-source identity; canonical child construction/evaluation only; complete embedded child reports and content identities; normalized authority/applicability matrix; independent whole-gate regeneration; closed nonclaims; hostile source/report/claim/invocant/injection rejection; defensive values; simultaneous dual-family repository-volume success/failure cleanup; syntax; guarded focused and adjacent compatibility; CI inventory; task/index/Memory/book/fact/rationale/claim/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, diff, staged acceptance, and doctrine gates | `passed`; the 4,096-MiB guarded t/1655 watcher passes Files=1/Tests=4 in 600 seconds, while CI inventory plus t/1651 compatibility passes Files=2/Tests=7,098 in 62 seconds. All sixteen members qualify without provider or external-tool access; only balanced structural emission is complete. Compile, runtime, trace, result, public support, performance, capacity, and reached-boundary claims remain false. `.17.2.7.3`, `.17.2.7`, and `.17.2` are done; `.17.3` measurement remains proposed for a clean activation. |
| `2026-08-22` | `.17.2.7.3` unified provider-free qualification activation | clean balanced-emission predecessor `ebf98fbbd`; completed runtime-stream and balanced family APIs; decisions `0055`/`0056`/`0077`; exact ownership/nonclaim boundary; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged docs-only acceptance, and doctrine gates | `passed`; `.17.2.7.3` alone is active to independently qualify the complete runtime-profile/level plus balanced construction family before measurement. Activation changes no code, test, config, generator, emitter, artifact, external execution, runtime result, API, capability/support, performance, capacity, reached-boundary, or product behavior. |
| `2026-08-22` | `.17.2.7.2.4` balanced portable-emission implementation | missing-module RED witness; fresh six-family composition; caller-sealed canonical bridge/ExecutionIR/backend-input route; exact fifteen-requirement backend negotiation; deterministic eight-artifact/three-source graph; complete operation and binding source maps; legal identifiers; stage/artifact/report identities; byte-equal rerun; public/unsealed/mutated evidence rejection; repository-volume success/failure cleanup; syntax; guarded focused and impacted compatibility; task/index/Memory/book/fact/rationale/claim/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, diff, staged acceptance, and doctrine gates | `passed`; the qualifier freezes 503,279 source bytes and 3,605 maps covering all 1,024 operations and 2,048 bindings. Final focused t/1654 passes Files=1/Tests=4 in 535 seconds and the guarded five-file public/revision-1/revision-2/composer compatibility matrix passes Files=5/Tests=26 in 403 seconds. Public emission rejects the private profile atomically; compilation, runtime, trace, result, support, performance, capacity, and reached-boundary claims remain false. `.17.2.7.2` is done and `.17.2.7.3` is proposed next. |
| `2026-08-22` | `.17.2.7.2.4` balanced portable-emission activation | clean canonical-composition predecessor `d2305a59a`; decision `0077`; exact revision-2 bridge/ExecutionIR identity boundary; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged docs-only acceptance, and doctrine gates | `passed`; `.17.2.7.2.4` alone is active to add exact portable-SystemVerilog emitter negotiation and structural emission proof. Activation changes no source, test, emitter, artifact, external execution, runtime, public API, capability/support, performance, capacity, or product behavior. |
| `2026-08-22` | `.17.2.7.2.3` canonical balanced composition implementation | missing-module RED witness; closed caller-sealed composer; six freshly evaluated substantive family gates; ordinary repository-relative HIAL/VIAL; canonical Parser/revision-2 bridge/ExecutionBuilder/plan reruns and keyed replay; complete decision-0055 vector; stage/report identities; logical-time/fiber/checking/random oracles; hostile construction/report/private-seam rejection; same-volume success/failure cleanup; syntax; guarded focused and nine-file impacted matrix; task/index/Memory/book/fact/rationale/claim/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, diff, staged acceptance, and doctrine gates | `passed`; the composer derives the exact 1-unit/1-domain, 128-endpoint, 16-transaction, 1,744-field, 128-event, 32-probe, 32-scenario, 1,024-operation, 128-fiber/32-live, 2,048-binding, 512-type, 32-model/512-cell, 32-scoreboard/4,096-capacity, 256-coverpoint/4,096-bin, 32-fault, and 1,024-random-occurrence interaction shape. Final focused t/1653 passes Files=1/Tests=4 in 282 seconds and the guarded nine-file impacted matrix passes Files=9/Tests=38 in 551 seconds. Portable emission, external execution, runtime, public API, support, performance, capacity, and reached-boundary claims remain unchanged; `.17.2.7.2.4` is proposed next. |
| `2026-08-22` | `.17.2.7.2.3` canonical balanced composition activation | clean bridge/binder predecessor `4b11043ff`; decisions `0055`/`0077`; completed six-family constructor and exact revision-2 admission boundaries; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged docs-only acceptance, and doctrine gates | `passed`; `.17.2.7.2.3` alone is active to compose ordinary canonical HIAL/VIAL from fresh orthogonal gate evidence and prove the complete interaction vector. Activation changes no source fixture, composer, parser, bridge, ExecutionIR, emitter, artifact, external execution, runtime, API, capability/support, performance, capacity, or product behavior. |
| `2026-08-22` | `.17.2.7.2.2` balanced bridge/binder implementation | missing-method RED witness; decision `0077`; exact caller-sealed direct-IAL1 bridge and ExecutionIR admission; full-payload content identity; exact endpoint/transaction/field/event/probe/binding shape; byte-equal rerun; public/missing-profile/substituted-profile/near-field/mutated-fact/forged-identity rejection; syntax; guarded focused and impacted compatibility; CI inventory; task/index/Memory/book/fact/claim/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, diff, staged-acceptance, and doctrine gates | `passed`; bridge and execution admission derive 128 bridge endpoints, 16 single-active aliases with 109 fields each, 128 events, 32 probes, and exactly 2,048 genuine bindings without padding. The focused watcher passes Files=1/Tests=3, the guarded eight-file impacted set passes Files=8/Tests=41 in 137 seconds, and the dedicated revision-1 bridge watcher passes Files=1/Tests=6. The 53-file/51,109-line book grows by 182 bytes without a ceiling increase and renders as 88 files/18,970,177 bytes before exact removal. Public AHB, revision 1, portable emission, runtime, support, performance, and capacity behavior remain unchanged; `.17.2.7.2.3` remains proposed next. |
| `2026-08-22` | `.17.2.7.2` balanced portable composition activation | clean runtime-construction predecessor `3c1f0b411`; decisions `0055`/`0056`; exact catalog interaction profile and completed six-family constructor census; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.7.2` alone is active to consume six fresh orthogonal gate reports and compose the one catalog-owned portable-SystemVerilog interaction shape through canonical routes. Activation changes no code, test, config, workload bytes, generator, emitter, external execution, runtime, API, support, performance, capacity, or product behavior. |
| `2026-08-22` | `.17.2.7.1` provider-free runtime-stream construction | missing-module RED witness; exact three-profile/five-level catalog ownership; frozen checked-AHB sources; double canonical SemanticIR/bridge/ExecutionIR/backend-input/plan route; content-addressed handoff and reports; profile/tool/schema/command/timeout/transcript authority; exact reference, 10,000/100,000, and earliest-cap specifications; no provider/tool/runtime/trace/result/reached-boundary claims; hostile invocant/source/tool/construction/report/support mutation rejection; same-volume success/failure cleanup; syntax; focused and guarded impacted compatibility; task/index/Memory/book/fact/claim/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, diff, staged-acceptance, and doctrine gates | `passed`; t/1651 passes Files=1/Tests=4 in 62 seconds and the guarded six-file impacted set passes Files=6/Tests=35 in 242 seconds. All fifteen reports are deterministic and provider-free; the 53-file/51,109-line book grows by 2,353 bytes without a ceiling increase and renders as 88 files/18,964,191 bytes before exact removal. No product API, external runtime, support, performance, capacity, or reached-boundary claim changes; `.17.2.7.2` remains proposed next. |
| `2026-08-22` | `.17.2.7` runtime-stream/balanced activation and decomposition | clean backend-emission predecessor `86faa137d`; complete decisions `0055`/`0056`; current workload catalog/runtime-profile census; three-child task decomposition; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.7` is active as runtime-stream construction `.1`, balanced portable composition `.2`, and unified provider-free qualification `.3`; `.1` alone is active. Activation changes no code, test, config, generator, trace, result, external-tool execution, runtime, API, capability/support, performance, capacity, or product behavior. |
| `2026-08-22` | `.17.2.6.3.6` family-closure implementation | missing-test RED witness; complete four-profile/five-level catalog derivation; exact thirteen-emitted/seven-rejected partition; repeated construction; representative reference/adjacent evaluation per profile; authority/oracle/metric/diagnostic/content/nonclaim closure; direct-helper, construction, report, and support-claim mutation rejection; same-volume success/rejection/consumer-failure cleanup; syntax; focused, CI-inventory, guarded eleven-file impacted matrix, and native-UVM gallery checks; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; t/1650 passes Files=1/Tests=4 in 119 seconds, CI inventory passes Files=1/Tests=12, and the 4,096-MiB guarded t/1640-t/1650 matrix passes Files=11/Tests=98 in 600 seconds. All twenty outcomes are structurally qualified as thirteen emitted graphs and seven atomic rejections; `.17.2.6.3.6`, `.17.2.6.3`, and `.17.2.6` are done. No external runtime, family-level product report, public API, capability/support, performance, capacity, or product claim changes; `.17.2.7` remains proposed next. |
| `2026-08-22` | `.17.2.6.3.6` family-closure activation | clean native-UVM predecessor `d8dd1ce82`; decision `0075`; exact 13-emitted/7-rejected partition; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.6.3.6` alone is active to qualify all twenty profile-level outcomes and close `.17.2.6.3` plus `.17.2.6`. No implementation, family report, or product behavior changes. |
| `2026-08-22` | `.17.2.6.3.5` native-UVM route implementation | RED zero-ownership/public-rejection witness; decision `0075`; caller-sealed shared construction and NativeUVM evaluator; ordinary Parser/PlanBuilder routes; exact artifact/source/map/check/mapping/workflow/identifier/manifest/diagnostic oracles; direct T=128/changed-T=21 falsification; defensive mutation; success/rejection/failure cleanup; syntax; native compatibility/gallery; focused, CI-inventory, and 4,096-MiB guarded ten-file impacted suite; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; five native-UVM profile outcomes join the fifteen portable/OSVVM shapes, but only T=21 emits: 16 artifacts/10 sources/138,345 bytes/75 maps/14 checks/25 mappings/seven review stages/five closure checks, with six intentional operation associations. Every non-reference level rejects the adjacent T=22 witness atomically; later levels are preflight-dominated/not-constructed. The guarded impacted collection passes Files=10/Tests=94 in 467 seconds. Reports and staging are defensive and residue-free. No external runtime, public API, capability/support, performance, capacity, or product claim changes; `.3.6` remains proposed for clean activation next. |
| `2026-08-22` | `.17.2.6.3.5` native-UVM route activation | clean OSVVM predecessor `b8969b525`; decision `0075`; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.6.3.5` alone is active to own exact T=21 review emission plus T=22/larger/changed-same-count pre-artifact rejection through the sealed foundation. Family closure remains proposed. No implementation or product behavior changes. |
| `2026-08-21` | `.17.2.6.3.4` OSVVM ladder implementation | RED zero-ownership/public-rejection witness; decision `0075`; caller-sealed shared construction and OSVVM evaluator; one callback-scoped exact provider verification with two defensive emissions; ordinary Parser/PlanBuilder routes; exact artifact/source/map/check/mapping/provider/semantic-preservation/identifier/manifest/diagnostic oracles; defensive mutation; success/rejection/failure cleanup; syntax; focused and 4,096-MiB guarded nine-file impacted suite; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; exactly five OSVVM shapes join the ten portable shapes. T=21/128/512/29,508 emit 16 artifacts/7 sources at 120,911/179,280/391,248/16,781,090 bytes with 66/173/557/29,553 complete maps, twelve wrapper checks, and twenty portable prerequisite checks; T=29,509 rejects atomically at `/portable_foundation`. The guarded impacted collection passes Files=9/Tests=86 in 439 seconds. Reports and staging are defensive and residue-free. No external runtime, public API, capability/support, performance, capacity, or product claim changes; `.3.5` remains proposed for clean activation next. |
| `2026-08-21` | `.17.2.6.3.4` OSVVM ladder activation | clean portable-VHDL predecessor `7199de481`; decision `0075`; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.6.3.4` alone is active to own T=21/128/512/29,508 acceptance plus adjacent portable-foundation T=29,509 rejection through the sealed foundation and callback-scoped exact provider evaluation. Native UVM and family closure remain proposed. No implementation or product behavior changes. |
| `2026-08-21` | `.17.2.6.3.3` portable-VHDL ladder implementation | RED zero-ownership/public-rejection witness; decision `0075`; caller-sealed shared construction and profile evaluator; ordinary Parser/PlanBuilder routes; exact artifact/source/map/check/identifier/manifest/diagnostic oracles; independent byte-equal reruns; defensive mutation; success/rejection/failure cleanup; syntax; guarded workload/authority/foundation/direct-emitter/portable-SV/portable-VHDL suite; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; exactly five portable-VHDL shapes join the five portable-SV shapes. T=21/128/512/29,508 emit 17 artifacts/6 sources at 116,560/174,929/386,897/16,776,739 bytes with 59/166/550/29,546 complete maps and twenty passing checks; T=29,509 rejects atomically at `/artifacts`. Reports and staging are defensive and residue-free. No external runtime, public API, capability/support, performance, capacity, or product claim changes; `.3.4` remains proposed for clean activation next. |
| `2026-08-21` | `.17.2.6.3.3` portable-VHDL ladder activation | clean portable-SystemVerilog predecessor `5d309b0eb`; decision `0075`; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.6.3.3` alone is active to own T=21/128/512/29,508 acceptance plus adjacent T=29,509 earliest-cap rejection through the sealed foundation. OSVVM, native UVM, and family closure remain proposed. No implementation or product behavior changes. |
| `2026-08-21` | `.17.2.6.3.2` portable-SystemVerilog ladder implementation | RED zero-ownership/public-rejection witness; decision `0075`; caller-sealed shared construction and profile evaluator; ordinary Parser/PlanBuilder routes; exact artifact/source/map/identifier/manifest/diagnostic oracles; independent byte-equal reruns; defensive mutation; success/rejection/failure cleanup; syntax; focused workload/authority/foundation/direct-emitter/profile suite; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; exactly five portable-SV shapes are owned. T=21/1,024/4,096/6,319 emit 8 artifacts/3 sources at 164,093/2,803,325/10,910,333/16,776,830 bytes with 54/1,057/4,129/6,352 complete maps; T=6,320 rejects atomically at `/artifacts`. Reports and staging are defensive and residue-free. No external runtime, public API, capability/support, performance, capacity, or product claim changes; `.3.3` remains proposed for clean activation next. |
| `2026-08-21` | `.17.2.6.3.2` portable-SystemVerilog ladder activation | clean foundation predecessor `8e9553a3b`; decision `0075`; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, claim, containment, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.6.3.2` alone is active to own T=21/1,024/4,096/6,319 acceptance plus adjacent T=6,320 earliest-cap rejection through the sealed foundation. Portable VHDL, OSVVM, native UVM, and family closure remain proposed. No implementation or product behavior changes. |
| `2026-08-21` | `.17.2.6.3.1` caller-sealed backend-emission foundation | missing-module RED; exact checked-AHB source pair; same-package qualification seal; public zero-owned catalog boundary; ordinary Parser/PlanBuilder double rerun; closed stage/outcome/oracle/claim reports; exact content identities and route metrics; construction/evaluation/provider mutation negatives; success/failure same-volume staging cleanup; focused shared-workload/authority regression; task/index/Memory/book/fact/claim/containment continuity; staged acceptance and doctrines | `passed`; no public profile shape is owned and no emitter or runtime executes. The foundation freezes workload `b739891c…`, evaluation `e7d9a4e1…`, rerun `172c0419…`, five stage digests, two scenarios/21 operations/four fibers/three simultaneous fibers/39 maps, a 44,101-byte plan, and two backend inputs. Focused regression passes Files=3/Tests=15 with exact staging cleanup; task integrity remains three trees/962 nodes, Knowledge Map remains 1,150 facts/6,056 questions/6,223 occurrences/133 shards, and all 1,426 claim candidates close. All 53 book chapters test; the inspected 88-file/18,918,049-byte render is removed exactly. Portable-SV `.17.2.6.3.2` remains proposed for separate activation. No API, artifact-graph, capability/support, performance, or capacity claim changes. |
| `2026-08-21` | `.17.2.6.3` backend-emission generator activation/decomposition | clean repair-family predecessor `2d7b3b27e`; decision `0075`; common workload/ExecutionIR and four repaired profile authority census; task/index/Memory/book/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, live-document, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.6.3` is active as a six-child container and only caller-sealed foundation `.1` is active. Four profile ladders and final family closure remain proposed. No code, test, config, artifact, generator, emitter, runtime, API, capability/support, performance, capacity, or product behavior changes. |
| `2026-08-21` | `.17.2.6.2.5` exact authority alignment and repair-family qualification | six-field RED drift witness; one closed four-profile authority source; defensive clone; unknown/missing/obsolete/contradictory negatives; catalog and VHDL/native-UVM discovery projections; exact OSVVM source/cap/map/check partition; exact native-UVM caps/selected matrix; syntax/focused/capability/family/CI inventory reruns; task/index/Memory/decision/book/fact/rationale continuity; repository doctrine gates | `passed`; catalog and discovery consume one exact authority set, t/1644 passes Files=1/Tests=3, focused catalog/capability regression passes Files=4/Tests=7,108, and the 4,096-MiB guarded complete repair collection passes Files=18/Tests=7,248 in 124 seconds. No staging residue or runtime/API/support/performance/capacity claim change remains; `.17.2.6.2` is done and `.17.2.6.3` is next after the clean commit. |
| `2026-08-21` | `.17.2.6.2.5` catalog/support alignment activation | clean predecessor `9c92b27f9`; decision `0075`; current catalog/support/emitter authority census; task/index/Memory continuity; task-tree, relative-path, mdBook, containment, claim, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.6.2.5` alone is active to reconcile exact repaired OSVVM source/cap/map authorities and native-UVM cap/selected-matrix authority, reject unknown or contradictory catalog fields, and qualify the five-repair family. No implementation, artifact, runtime, API, support, performance, or capacity behavior changes. |
| `2026-08-21` | `.17.2.6.2.4` native-UVM selected-shape negotiation | genuine parser/PlanBuilder T=21/22/128 and changed-T=21 witnesses; RED fixed-output loss; exact operation/scenario/fiber/resource/expectation predicate; stable diagnostic and no-output boundary; byte-equal reference rerun; identifier and nonclaim preservation; native-UVM focused regression plus CI inventory; task/index/Memory/decision/book/fact/rationale continuity; repository doctrine gates | `passed`; only the exact selected T=21 shape emits 16 artifacts/10 SystemVerilog sources/138,345 source bytes/75 maps/14 checks. T=22, T=128, and changed T=21 return one VIAL_UVM_BACKEND_UNSUPPORTED diagnostic at /negotiation with no operation identity or graph. Focused plus complete native-UVM emission/review and CI-inventory tests pass at Files=7/Tests=54; runtime/result/support claims remain unchanged. `.2.5` is next after the clean commit. |
| `2026-08-21` | `.17.2.6.2.2` sealed OSVVM provider evaluation | missing-boundary RED; origin/source audit; exact mocked verification count; source/evidence identity seal; defensive clone; mismatch/forgery/stale/callback-failure negatives; real recursive provider rerun; standalone/gallery/qualification compatibility; task/index/Memory/decision/book/fact/rationale continuity; focused and repository doctrine gates | `passed`; one evaluation verifies the exact provider root once and emits twice byte-identically. Mismatched, forged, and stale capabilities return only VIAL_OSVVM_PROVIDER_EVALUATION_ERROR with no artifacts; callback and invalid-result failures delete the capability, mutation of one result cannot affect the next, and standalone emission still verifies independently. The guarded exact collection passes at Files=3/Tests=48; strengthened t/1642 passes Files=1/Tests=46. A subsequent combined rerun is honestly invalidated when unrelated pgen compilation raises host occupancy to 88.2% against the fixed 88% cutoff; no FSMGen residue remains. No generated bytes, provider qualification, runtime, support, performance, or capacity claim changes; `.2.3` is next after the clean commit. |
| `2026-08-21` | `.17.2.6.2.2` sealed OSVVM provider-verification activation | clean portable-VHDL predecessor `c3810ba8a`; decision `0075`; exact current emitter/materialization entrypoint census; task/index/Memory continuity; task-tree, relative-path, containment, diff, and doctrine gates | `passed`; `.17.2.6.2.2` alone is active to capture repeated recursive verification and introduce one exact evaluation-local sealed result bound to provider/source identity. OSVVM map translation, native-UVM negotiation, catalog qualification, and generator work remain proposed. No implementation, artifact, provider, runtime, API, support, performance, or capacity behavior changes. |
| `2026-08-21` | `.17.2.6.2.1` portable-VHDL linearization and exact boundary | source-shape RED/GREEN controls; origin audit; one-pass metadata and generated-line indexes; ordinary Parser/PlanBuilder/emitter T=21/128/512 reruns; 4,096-MiB guarded exact T=29,508/29,509 route; static-mutation and matrix-review regression; task/index/Memory/decision/book/fact/claim/containment continuity; focused, mdBook, diff, staged acceptance, and doctrine gates | `passed`; source-only RED catches all three quadratic patterns before implementation and GREEN excludes them afterward. T=21/128/512 remain byte-identical at 116,560/174,929/386,897 source bytes and 59/166/550 maps, with 17 artifacts, six sources, and twenty passing checks. Guarded T=29,508 accepts twice at 16,776,739 bytes/29,546 maps; adjacent T=29,509 returns only exact VIAL_VHDL_BACKEND_LIMIT_EXCEEDED at /artifacts with no partial graph. The exact test passes in 42 seconds and focused portable-VHDL regression passes at Files=3/Tests=20. No external runtime executes and no support, performance, or capacity claim changes. |
| `2026-08-21` | `.17.2.6.2` repair activation/decomposition | clean selection predecessor `0a3a2a05f`; decision `0075`; exact five-defect dependency order; task/index/Memory continuity; task-tree, relative-path, containment, diff, staged acceptance, and doctrine gates | `passed`; `.17.2.6.2` is active with five children and `.17.2.6.2.1` alone active for portable-VHDL validator linearization plus accepted T=29,508 and rejected T=29,509 proof. Provider reuse, OSVVM map translation, native-UVM closed negotiation, and final catalog/support qualification remain proposed in order. Task integrity reports three trees/955 nodes; no implementation or product behavior changes. |
| `2026-08-21` | `.17.2.6.1` backend-emission route selection | decisions `0055`/`0056`/`0072`; common catalog and all execution shapes; four emitters/validators/support contracts/focused tests/gallery/publication boundaries; canonical anchored reference/candidate/adjacent probes; private unchanged VHDL renderer boundary calculation; 128/129 identifier edge; OSVVM adapter/map/provider source inspection; native-UVM T=21/22 and 48,274/48,275 falsification; Knowledge Map/book/task/Memory/containment continuity; task-tree, relative-path, mdBook, claim, diff, acceptance, and doctrine gates | `passed`; decision `0075` selects exact profile-local outcomes. Portable SV accepts T=21/1,024/4,096/6,319 and rejects 6,320. Portable VHDL and OSVVM select T=21/128/512/29,508 plus adjacent portable-foundation rejection at 29,509. Native UVM selects reference and adjacent T=22 negotiation rejection, with larger levels preflight-dominated. Generated identifiers remain 131/142/142/154 bytes at the 128-byte source edge; 129 rejects. Four behavior defects and exact catalog drift are durably routed to five required `.17.2.6.2` repair slices before generator `.3`; no behavior changes. |
| `2026-08-21` | `.17.2.6` decomposition | clean activation `63655fee2`; decisions `0055`/`0056`; Knowledge Map and current book/task audit; catalog/profile-axis history; four canonical emitter/validator source census; exact reference emission probe; guarded focused emitter matrix; task/index/Memory continuity; task-tree, relative-path, diff, and doctrine gates | `passed`; `.17.2.6` decomposes into active read-only selection `.17.2.6.1`, proposed catalog/contract repair `.17.2.6.2`, and proposed generator/oracle implementation `.17.2.6.3`. Reference emission returns portable SV 8 artifacts/3 sources/164,093 source bytes/54 maps/0 separate static checks, portable VHDL 17/6/116,558/59/20, OSVVM 16/7/120,909/13/12, and native UVM 16/10/138,345/75/14. Guarded focused emission passes at Files=4/Tests=30. History roots the under-specified profile axis and catalog drift in foundation commit `063b990f3`; exact numbered-source inspection rejects the false duplicate-key hypothesis. No product behavior changes. |
| `2026-08-21` | `.17.2.6` backend-emission generation activation | clean claim-adoption closure `0fd653bf0`; decision `0074` resume direction; decisions `0055`/`0056`; workload catalog and four canonical emitter/profile authority census; Knowledge Map absence check; task/index/Memory/book continuity; task-tree, relative-path, mdBook, maintained-reference, claim-inventory, containment, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.6` alone is active and first owns a read-only reconciliation of portable-SystemVerilog, portable-VHDL, OSVVM, and native-UVM input, negotiation, artifact, source-map, structural-check, limit, atomicity, and cleanup authorities before implementation decomposition. Task integrity reports three trees/947 nodes, relative paths pass at Files=1/Tests=2, all 53 mdBook chapters test, the inspected repository-local render contains 88 files/18,604 KiB and is removed exactly, all 22 live-document surfaces accept the exact 0-file/+5-line/+348-byte book authority with no ceiling increase, the refreshed inventory reconciles 10,678 numeric lines/1,415 candidates/2,043 constants/the original 615 constants with zero owners, and all 12 doctrines pass. No generator, emitter, runtime, public API, capability/support, performance, or capacity behavior changes. |
| `2026-08-20` | `.17.2.5.2.7` complete checking-state family qualification | exact eight-axis/five-level catalog partition; 32 selected owned/eight references rejected; independent byte-equal construction/evaluation reports; exact oracle/count selection; defensive validation; hostile source/report/runtime-evidence rejection; same-volume success/failure cleanup; complete default and opt-in high-count matrices under the 4,096-MiB guard; CI inventory, book/fact/task/Memory/containment continuity; staged acceptance and doctrines | `passed`; t/1635 closes the whole-family ownership and nonclaim proof. Guarded default t/1629-t/1635 reports `All tests successful` at `Files=7, Tests=36` in 166 seconds. Complete opt-in t/1630-t/1634 reports `All tests successful` at `Files=5, Tests=27` in 593 seconds, including 65,536 cells, one-million-entry scoreboard/coverage state, 4,096 faults, and 8,440/8,441 random-plan evidence. `.17.2.5.2.7`, `.17.2.5.2`, and `.17.2.5` are done; `.17.2.6` remains proposed next. No product, backend, runtime, public API, support, performance, or capacity claim changes. |
| `2026-08-20` | `.17.2.5.2.7` final checking-state qualification activation | clean random/replay predecessor `0f383a824`; completed 32-shape ownership; decision `0073`; canonical checking-state contract and Knowledge Map fact; exact partition/default/high-count/route/report/hostile-caller/cleanup/nonclaim closure selection; task/index/Memory/book/fact/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, live-document, diff, and doctrine gates | `passed`; `.17.2.5.2.7` alone is active for final checking-state family qualification and parent closure. No code, test, config, generated artifact, parser, IR, evaluator, backend, support, performance, capacity, or product behavior changes. |
| `2026-08-20` | `.17.2.5.2.6` random/replay checking ladder | compact ordinary-VIAL 128-choice renderer; canonical Parser/checked-AHB bridge/public-ExecutionBuilder reruns; independent generation plus strict replay; exact keyed-value/order and normalized-plan equality; 32,768 plan-cap, 65,536 preflight-dominated, 65,537 count-cap, and 8,440/8,441 adjacent-boundary outcomes; replay/source/report mutation; same-volume success/failure cleanup; default and RAM-guarded exact regression; book/fact/task/rationale/Memory/containment continuity; staged acceptance and doctrines | `passed`; all four random-occurrence shapes and therefore all 32 non-reference checking-state shapes are owned. The 1,024 gate contains eight scenarios and 1,024 real Boolean occurrences in an exact 2,073,805-byte plan; strict replay differs only by origin. The full 32,768 route returns only `/plan`; 65,536 makes no materialization/count claim; 65,537 returns only `/randomness/decisions`; 8,440 accepts at 16,775,415 plan bytes and 8,441 rejects. Default t/1629-t/1634 passes at Files=6/Tests=33 in 127 seconds; exact t/1634 passes at Files=1/Tests=4 in 467 seconds under the 4,096-MiB guard. No product, backend, runtime, public API, support, performance, or capacity claim changes; final qualification `.17.2.5.2.7` remains proposed next. |
| `2026-08-20` | `.17.2.5.2.6` random/replay checking activation | clean fault predecessor `be6878984`; decision `0073`; canonical checking-state contract and Knowledge Map fact; exact 1,024 gate, 32,768 plan-cap, 8,440/8,441 adjacent-boundary, preflight-dominated 65,536, and 65,537 count-cap selection; task/index/Memory/book/fact/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, live-document, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.5.2.6` alone is active for compact Boolean random-occurrence construction, keyed generated/replayed equality, exact plan/count outcomes, mutation/rerun negatives, and same-volume cleanup. Final qualification `.17.2.5.2.7` remains proposed. No code, test, config, generated artifact, parser, IR, evaluator, backend, support, performance, capacity, or product behavior changes. |
| `2026-08-20` | `.17.2.5.2.5` fault lifecycle checking ladder | compact ordinary-VIAL fault renderer; canonical Parser/checked-AHB bridge/public-ExecutionBuilder reruns; streamed arm/apply/expire/restore oracle with independent declaration-order and transition identities; exact 4,097 rejection; reinjection/overlap/value/order and hostile-state negatives; source/report mutation; same-volume success/failure cleanup; default and RAM-guarded exact regression; book/fact/task/rationale/Memory/containment continuity; staged acceptance and doctrines | `passed`; all four fault shapes are owned. Accepted 32/1,024/4,096 levels traverse the complete canonical route and stream exactly four lifecycle records per declaration without retaining a 4,096-record report array. The 4,096 limit closes 16,384 transitions with digest `4042b666…`; 4,097 returns only the exact `/faults` diagnostic with no downstream identity. Default t/1629-t/1633 passes at Files=5/Tests=29 in 97 seconds; exact t/1633 passes at Files=1/Tests=5 in 21 seconds under the 4,096-MiB guard. No product, backend, runtime, public API, support, performance, or capacity claim changes; random/replay child `.17.2.5.2.6` remains proposed next. |
| `2026-08-20` | `.17.2.5.2.5` fault checking activation | clean coverage predecessor `4af387042`; decisions `0072`/`0073`; existing checking-state contract, Knowledge Map, and mdBook; task/index/Memory/book/fact/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, live-document, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.5.2.5` alone is active for 32/1,024/4,096 accepted faults, exact 4,097 rejection, arm/apply/expire/restoration, reinjection/overlap/mutation negatives, deterministic rerun, and same-volume cleanup. Random/replay and final qualification siblings remain proposed. No code, test, config, generated artifact, parser, IR, evaluator, backend, support, performance, capacity, or product behavior changes. |
| `2026-08-20` | `.17.2.5.2.4` packed coverage checking ladders | exact linear coverpoint and compact authored-bin/cross renderers; canonical Parser/checked-AHB bridge/public-ExecutionBuilder reruns; LSB-first packed hit-vector plus independently streamed authored-order oracle; decision-0072 source-free envelope outcomes and 9,524/9,525 parser boundary; 1,000,001 execution rejection; illegal/ignore/bit/order and hostile-state negatives; source/report mutation; same-volume success/failure cleanup; default and RAM-guarded qualification; book/fact/task/rationale/Memory/containment continuity; staged acceptance and doctrines | `passed`; all eight coverage shapes are owned. Reachable 256/8,192 coverpoints and 4,096/262,144/1,000,000 static entries traverse the complete canonical route. The million source is exactly 62,841 bytes and its 125,000-byte all-hit vector has digest `ae450c20…`; a separate `696d5310…` ordered-domain digest closes the all-one permutation gap without retaining a million identities. Selected coverpoint limits remain honest envelope results with the real parser boundary, and one further bin returns only the exact `/coverage` diagnostic. Default t/1629+t/1632 pass at Files=2/Tests=13 in 18 seconds; exact t/1632 passes at Files=1/Tests=7 in 45 seconds; complete default t/1629-t/1632 passes at Files=4/Tests=24 in 87 seconds under the 4,096-MiB guard. No product, backend, runtime, support, performance, or capacity claim changes; fault child `.17.2.5.2.5` remains proposed next. |
| `2026-08-20` | `.17.2.5.2.4` coverage checking activation | clean scoreboard predecessor `416c79473`; decisions `0072`/`0073`; existing Knowledge Map and mdBook contract; task/index/Memory/fact continuity; task-tree, Knowledge Map, relative-path, mdBook, live-document, diff, staged acceptance, and doctrine gates | `passed`; `.17.2.5.2.4` alone is active for coverpoint reachability/envelope outcomes and static-bin/cross-tuple packed hit-vector checking. Fault, random/replay, and final qualification siblings remain proposed. No code, test, config, generated artifact, parser, IR, evaluator, backend, support, performance, capacity, or product behavior changes. |
| `2026-08-20` | `.17.2.5.2.3` packed scoreboard checking ladders | compact ordinary-VIAL scoreboard-instance/capacity renderers; canonical Parser/checked-AHB bridge/public-ExecutionBuilder reruns; complete-transaction packed FIFO oracle; exact maximum/final depths and zero pending; mismatch/overflow/corruption and hostile-policy negatives; 4,097 execution and 1,000,001 semantic diagnostics; source/report mutation; same-volume success/failure cleanup; default and RAM-guarded complete qualification; book/fact/task/rationale/Memory/containment continuity; staged acceptance and doctrines | `passed`; all eight scoreboard shapes are owned. Accepted 32/1,024/4,096 instances and 4,096/262,144/1,000,000 declared capacity traverse the complete canonical route, compare every six-field transaction, and drain to zero. The million limit uses exactly 4,000,000 packed bytes and 6,000,000 field comparisons rather than one million plan operations. Adjacent excesses stop at their exact earliest authority with no downstream identity. Default t/1629-t/1631 pass at Files=3/Tests=17; exact t/1631 passes at Files=1/Tests=6 under the 4,096-MiB RAM guard. No product, backend, runtime, support, performance, or capacity claim changes; `.17.2.5.2.4` remains proposed next. |
| `2026-08-20` | `.17.2.5.2.3` scoreboard checking activation | clean model predecessor `48e97f656`; decision `0073`; existing Knowledge Map contract; task/index/Memory/book/fact/containment continuity; task-tree, Knowledge Map, relative-path, mdBook, live-document, diff, staged-acceptance, and doctrine gates | `passed`; `.17.2.5.2.3` alone is active for scoreboard-instance and declared-capacity construction plus complete-transaction packed FIFO checking. Coverage, fault, random/replay, and final qualification siblings remain proposed. No code, test, config, generated artifact, parser, IR, evaluator, backend, support, performance, capacity, or product behavior changes. |
| `2026-08-20` | `.17.2.5.2.2` packed model checking ladders | exact ordinary-VIAL model-instance/scalar-cell renderers; canonical Parser/checked-AHB bridge/public-ExecutionBuilder reruns; packed u8 state transition oracle; exact accepted-event triggers; all-cell initialization/update/read; 4,097/65,537 diagnostics; hostile-known-mask/source/evaluation mutations; same-volume success/failure cleanup; default and RAM-guarded exact qualification; book/fact/task/rationale/Memory/containment continuity; staged acceptance and doctrines | `passed`; all eight model shapes are owned. Accepted 32/1,024/4,096 model instances and 512/32,768/65,536 scalar cells traverse the complete canonical route and produce byte-equal independently derived all-zero/all-one state vectors after exactly one bound accepted-event occurrence per instance. The four high levels pass under the 4,096-MiB RAM guard in 136 seconds; 4,097 instances and 65,537 cells return exactly one `VIAL_EXECUTION_LIMIT_ERROR` at `/models` with no downstream identity. Default t/1629-t/1630 pass at Files=2/Tests=11 in 59 seconds. No product, backend, runtime, support, performance, or capacity claim changes; `.17.2.5.2.3` remains proposed next. |
| `2026-08-20` | `.17.2.5.2.1` checking-state foundation | decision `0073`; zero-owned public boundary; same-package source-candidate seal; exact checked-AHB input; canonical Parser/bridge/public-ExecutionBuilder reruns; closed packed/outcome/oracle/nonclaim schemas; exact content identities; construction/evaluation/provider mutation negatives; same-volume success/failure cleanup; focused/shared regression; book/task/fact/rationale/Memory/containment continuity; staged acceptance and doctrines | `passed`; the foundation route independently reproduces workload `7a125500…`, evaluation `9b674600…`, rerun `ceefc4f3…`, SemanticIR `00dce649…`, bridge `a4565d40…`, ExecutionIR `5f04ca97…`, and 44,467-byte plan `1a3b97f4…` identities while explicitly reporting `accepted_not_axis_evaluated` with no owned level or axis evidence. Guarded shared-foundation regression passes at Files=3/Tests=16; relative paths pass at Files=1/Tests=2; all 52 book chapters test, the standalone example prints the sealed status, and the inspected repository-local 88-file/18,540-KiB render is removed exactly. Task integrity remains three trees/947 nodes; Knowledge Map remains 1,124 facts/5,875 questions/6,042 occurrences/129 shards; all live surfaces, exact rationale reconstruction, maintained-reference authority, CI inventory, staged acceptance, and doctrines pass. Model child `.17.2.5.2.2` alone is active next. No product or support claim changes. |
| `2026-08-20` | `.17.2.5.2` checking-state implementation activation | clean selection predecessor `a4e45b278`; decision `0073` and canonical fact queries; foundation/model/scoreboard/coverage/fault/random/closure decomposition; task/index/Memory/book/containment continuity; task, path, mdBook, live-document, diff, staged-acceptance, and doctrine gates | `passed`; implementation is decomposed into seven bounded children and only caller-sealed construction/evaluation foundation `.17.2.5.2.1` is active. Task integrity reports three trees/947 nodes, relative paths pass at Files=1/Tests=2, all 52 chapters test, the inspected repository-local 88-file book render is removed exactly, all 22 live-document surfaces pass, and staged doctrines pass. No generator, parser, IR, evaluator, result, backend, capability/support, performance, or capacity behavior changes. |
| `2026-08-20` | `.17.2.5.1` checking-state proof selection | source/semantic/execution/result/backend authority audit; exact guarded model/scoreboard/coverage/fault/random probes; coverpoint and random binary-search boundaries; decision `0073`; static-cross contract reconciliation; packed-state proof sizing; decision/index/card/book/task/Memory/containment continuity; exact temporary-probe and book-render cleanup; task, path, mdBook, Knowledge Map, live-document, diff, staged-acceptance, and doctrine gates | `passed`; all eight axes now have selected accepted-or-earliest-cap outcomes. Coverpoints accept 9,524 in 1,048,467 source bytes and reject 9,525 at the 1-MiB parser cap; random occurrences accept 8,440 in a 16,775,415-byte plan and reject 8,441 at the 16-MiB plan cap, while the full compact 32,768 route returns the same diagnostic. Static authored crosses accept exact 4,096 / 262,144 / 1,000,000 resources in 8,820 / 32,585 / 62,841 source bytes and reject 1,000,001 at /coverage. Decision `0073` selects the caller-sealed packed-state evaluator: a 4,000,000-byte million-entry FIFO and 125,000-byte million-bit vector exercise state without million-operation/record transport. Task integrity reports three trees/940 nodes, relative paths pass at Files=1/Tests=2, all 52 chapters test, the inspected 88-file/18,516-KiB render is removed exactly, Knowledge Map is current at 1,124 facts/5,875 questions/6,042 occurrences/129 shards, all 22 live-document surfaces pass, and staged doctrines pass. No product, backend, runtime, support, performance, or capacity behavior changes. |
| `2026-08-20` | `.17.2.5` activation | clean execution-graph predecessor `6250cabad`; decisions `0055`/`0056`/`0057`; Knowledge Map absence check; task open-question and canonical checking-authority source census; task/index/Memory/book continuity; task-tree, relative-path, mdBook, containment, diff, and staged-doctrine gates | `passed`; `.17.2.5.1` alone is active to select reachability and an executable bounded proof method for all eight axes, especially the two one-million-record levels. `.17.2.5.2` remains proposed. Task integrity reports three trees/940 nodes, relative paths pass at Files=1/Tests=2, all 52 chapters test, the repository-local 88-file/18,500-KiB render is inspected and removed exactly, all 22 live-document surfaces pass, and staged doctrines pass. No parser, IR, checking-service, result, backend, capability/support, performance, or capacity behavior changes. |
| `2026-08-20` | `.17.2.4/.17.2.4.2` final execution-graph qualification | complete default t/1600-t/1628 family under RAM guard; exact 40-owned/25-unselected selection partition; focused selection rerun; task/Memory/index/book/card continuity; exact artifact census and cleanup; syntax, Knowledge Map, mdBook, task, path, containment, staged-acceptance, and doctrine gates | `passed`; all 29 architecture-scale files / 135 tests pass in 1,114 seconds. The strengthened foundation oracle proves the completed generator owns exactly 40 selected shapes, while all 13 `reference_v1` profiles and all 12 non-reference profiles of the fixed fixture/unit/domain axes remain deliberately unselected and caller-seal rejected; its corrected focused rerun passes at `Files=1, Tests=3` in 13 seconds. `.17.2.4.2` and parent `.17.2.4` are done, with proposed `.17.2.5` next. No public capability, support, performance, or capacity claim changes. |
| `2026-08-20` | `.17.2.4.2` unconstructible source-map ladder | owned-level history and decision `0072`; exact 262,144/1,000,000/1,000,001 map render sizes, identities, and reset counts; input-1 envelope authority; source-free canonical reconstruction; build/mutation/unknown-level negatives; selected-versus-catalog ownership distinction; default/opt-in/impacted guarded regression; book, Knowledge Map, rationale, task, containment, path, artifact, staged-acceptance, and doctrine gates | `passed`; all three levels now report `envelope_unconstructible` / `not_constructed` with the exact input-1 diagnostic, no retained source or stage identity, refused builds, and both decision-`0072` records carrying the measured 46,294/46,295 whole-route boundary against the declared one-million-map cap. Closing the axis raises selected owned shapes from 37 to 40 while the catalog's 25 deliberately non-selected profiles remain fail-closed. Focused default `t/1607` passes at `Files=1, Tests=8`, its opt-in route proof passes in 40 seconds, and the 13-file impacted matrix passes at `Files=13, Tests=68` in 304 seconds. The book example, all 52 chapters, exact repository-local render/removal, Knowledge Map, live containment, task/path/rationale, artifact census, staged acceptance, and doctrines pass. No public capability, support, performance, or capacity claim changes. |
| `2026-08-20` | `.17.2.4.2` Knowledge Map card partition | exact pre-partition Git identity; descriptor-backed reconstruction; stable route/gate versus per-axis seam; answer-set equality and duplicate rejection; family-explicit IAL2/VHDL/VIAL scoping; current task/book routing; focused verifier regression; Knowledge Map, containment, task, relative-path, mdBook, diff, staged-acceptance, and doctrine gates | `passed`; the exact 383-line / 26,208-byte / `44760f9a…` source at `5514e692c` deterministically reconstructs as a 70-line / 4,250-byte route-and-gate card with 11 questions and a 132-line / 8,973-byte axis-outcome card with 36. All 47 question keys survive exactly once, current task and book routes replace the stale blocked sentence, and the generic history verifier now gives IAL2, VHDL, and VIAL explicit replacement scopes. Focused `t/1568` passes at `Files=1, Tests=3`; Knowledge Map is current at 1,123 facts / 5,867 questions / 6,034 occurrences / 128 shards; all 52 book chapters test and the repository-local 88-file / 18,488-KiB render is removed exactly. No product or user-visible behavior, support, performance, or capacity claim changes. |
| `2026-08-20` | `.17.2.4.2` unconstructible execution-type limits | renderer/envelope history; exact 65,536/65,537 HIAL/VIAL byte and declaration counts; decision-`0072` outcome; canonical reconstruction and build-refusal falsification; adjacent binding/source-map regression; book, fact-card, task, and Memory continuity; focused, opt-in, family, mdBook, Knowledge Map, live-document, diff, staged-acceptance, and doctrine gates | `passed`; both levels now report `envelope_unconstructible` / `not_constructed` with the exact input-0 envelope diagnostic, no retained source, no stage identity, refused raw build, and both decision-`0072` records carrying the measured 1,043/1,044 whole-route boundary against the declared 65,536-type cap. Focused `Files=3, Tests=17` pass in 24 seconds, opt-in `Files=1, Tests=7` pass in 31 seconds, and the guarded architecture-scale family passes at `Files=29, Tests=132` in 1,107 seconds. The standalone book example, mdBook test/build, relative paths, Knowledge Map, live containment, syntax, artifact-residue, staged acceptance, and doctrine gates pass; the repository-local 88-file / 18,488-KiB book render is removed exactly. No public capability, support, performance, or capacity claim changes. |
| `2026-08-20` | `.17.2.4.2` end-to-end route-boundary evidence | signoff re-audit of this ladder's own claims; grammar audit of both public parsers for a declaration-repetition form; end-to-end route proofs for all three axes through the public binder; correction of a self-contradicting frontier paragraph and an activation log row; book, fact-card, reference-authority, task, and Memory continuity; opt-in, default, family, mdBook, Knowledge Map, live-document, diff, and staged-doctrine gates | `passed`; the grammar claim behind decision `0072` holds - `repeat` is statement-only in both public parsers and `(events …)`, `(types …)`, and `(endpoints …)` are flat one-record-per-unit lists - but three published numbers were ahead of their evidence and are now repaired. All three boundaries are whole-route claims with accepted plans at 2,664,611, 1,493,527, and 16,777,026 bytes; the source-map boundary gains the test it never had; and the 65,553 inference is corrected wherever it stood as a measurement. Opt-in `Files=3, Tests=15` in 85 seconds and default `Files=3, Tests=15` in 25 seconds pass; the guarded family passes at `Files=29, Tests=130` in 1,162 seconds. No product behavior changes; this slice adds evidence and corrects claims. |
| `2026-08-19` | `.17.2.4.2` unconstructible binding ladder | envelope root cause and history; linear-growth measurement; canonical 2,054/2,055 boundary search; decision `0072` mechanism; derived-frontier sweep completed in `t/1603` and `t/1605`; book, fact-card, reference-authority, task, and Memory continuity; focused, opt-in, family, mdBook, Knowledge Map, live-document, diff, and staged-doctrine gates | `passed`; all three binding levels above the gate now report `envelope_unconstructible` / `not_constructed` with the constructor's exact `VIAL_SCALE_INPUT_ERROR` at `/inputs/0/content`, no retained source, no stage identity, a refused build, and both records decision `0072` requires. The measured route boundary is 2,054 bindings accepted with exactly 2,048 manifest events and 2,055 rejected at `/events`, 32 times below the declared 65,536-binding execution cap. Focused `Files=3, Tests=13` in 16 seconds and opt-in `Files=1, Tests=5` in 6 seconds pass; the guarded family passes at `Files=29, Tests=129` in 1,113 seconds. No public capability, support, performance, or capacity claim changes. |
| `2026-08-19` | `.17.2.4.3` selection | clean activation predecessor `675cf69c9`; envelope, grammar, and contract-limit audit; canonical binary searches for all three route boundaries; decision `0072`; decision index, mdBook, fact-card, task, and Memory continuity; task-tree, Knowledge Map, documentation, relative-path, diff, and staged-doctrine gates | `passed`; the selection keeps both the nominal levels and the 1,114,112-byte construction envelope and instead requires every unreachable level to report its declared cap, its earliest decider, and its measured route boundary under an `envelope_unconstructible` / `not_constructed` outcome. Measured boundaries are 2,054 bindings (2,055 rejects at bridge `events` 2,048), 1,043 execution types (1,044 rejects at the 16-MiB serialized manifest), and 46,294 source-map records at a 16,777,026-byte plan (46,295 rejects at the 16-MiB plan cap) — 32x, 63x, and 22x below the declared execution caps. `.17.2.4.2` is unblocked and alone owns implementation. No product behavior, capability, support, performance, or capacity claim changes in selection. |
| `2026-08-19` | `.17.2.4.3` activation | clean predecessor `387bbdf56`; measured construction-envelope, bridge-event, serialized-manifest, and expanded-action evidence for the three remaining axes; blocker recorded on `.17.2.4.2`; task/index/Memory continuity; task-tree, relative-path, diff, and staged-doctrine gates | `passed`; `.17.2.4.3` alone is active to select what the remaining `bindings`, `execution_types`, and `source_map_records` levels mean, because every one of them is decided by the workload's own 1,114,112-byte construction envelope before any product cap and their product boundaries are 2,054 bindings, 1,043 execution types, and - as an inference from the 65,536 expanded-action semantic cap that had not yet been measured - 65,553 source maps. The `.17.2.4.3` selection below measured that third boundary through the canonical route and replaced it with 46,294 at the 16-MiB serialized-plan cap; this row is corrected rather than left standing because it presented an inference as a measurement. `.17.2.4.2` is blocked rather than left active so the frontier is unambiguous. No generator, parser, bridge, binder, plan, capability, support, performance, or capacity behavior changes in activation. |
| `2026-08-19` | `.17.2.4.2` execution-type qualification level | direct-IAL1 stage-order root cause and history; corrected `_canonical_inputs` order and structured bridge rejection; frozen HIAL/VIAL/workload identities; exact parser-cap authority; measured 1,043/1,044 route boundary; derived owned-frontier accessor replacing nine restated unowned lists; book, fact-card, reference-authority, task, and Memory continuity; focused, opt-in, family, mdBook, Knowledge Map, live-document, diff, and staged-doctrine gates | `passed`; correcting the stage order changed the reported authority for this level from the bridge type cap to the ordinary parser's 4,096-declaration package-section cap at `/packages/0/types`, from a 1,023,293-byte source inside the 1,048,576-byte source cap. The route's own measured boundary is 1,043 types, bounded by the 16,777,216-byte serialized bridge-manifest cap rather than by the 4,096-type or 4,096-endpoint cap, so this axis has no nominal operating point above its 512-type gate and records one `VIAL_SCALE_LIMIT_INTERACTION` routed to `.17.4`. Focused `Files=3, Tests=12` in 43 seconds and opt-in `Files=1, Tests=5` in 22 seconds pass; the guarded family passes at `Files=28, Tests=124` in 1,187 seconds. No public capability, support, performance, or capacity claim changes. |
| `2026-08-19` | `.17.2.4.2` total-operation limit ladder | literal-saturation and divisibility probes; RAM-guarded graph-stage and plan-stage cost measurement; compact `repeat` recipe; frozen source/workload/SemanticIR/bridge identities; decision `0061` clause-8 preflight record; opt-in raised-cutoff excess proof; advanced boundary assertions in `t/1619`/`t/1621`/`t/1622`; book, fact-card, reference-authority, task, and Memory continuity; focused, family, mdBook, Knowledge Map, live-document, diff, and staged-doctrine gates | `passed`; the ladder closes with its two levels proved by different methods. The literal 32-scenario recipe saturates at 74,656 operations (1,048,227 bytes) and cannot shape 1,000,001 at all, so both levels use the ordinary `repeat` form at 4,003 bytes each. An operation graph costs about 5.0 KiB resident per operation (436/1,442/2,692/3,977 MiB at 65,536/262,144/524,288/786,432), so `over_limit_v1` is opt-in evidence at a measured 11 seconds and 5,216-MiB peak descendant RSS and rejects at `/operation_graph/operations` with no discrepancy, while `limit_v1` is `preflight_dominated`/`not_materialized` against its 21,511,563-byte 65,536-operation witness and records one `VIAL_SCALE_LIMIT_INTERACTION` plus one `VIAL_SCALE_PREFLIGHT_DOMINANCE` routed to `.17.4`. Focused `Files=4, Tests=20` in 128 seconds and opt-in `Files=1, Tests=7` in 11 seconds pass; the guarded 30-file family passes at `Files=30, Tests=123` in 1,151 seconds. No public capability, support, performance, or capacity claim changes. |
| `2026-08-10` | `.17.2.4` activation | clean bridge-fanout predecessor `97dda148d`; decisions `0036`/`0055`/`0056`; workload catalog, semantic limits, ExecutionBuilder/ExecutionRandom/plan-limit source audit; task/index/Memory/book continuity; task-tree, relative-path, diff, and staged-doctrine gates | `passed`; `.17.2.4.1` alone is active to reconcile all 13 execution axes and their earliest reachable caps before implementation. `.17.2.4.2` remains proposed. No parser, IR, bridge, binder, plan, replay, capability/support, performance, or capacity behavior changes. |
| `2026-08-10` | `.17.2.3.2` canonical bridge-fanout generation | closed generated HIAL/VIAL producer; ordinary parse/report/lower/Builder route; 13 axes/five levels; exact count/map/binding/reference/manifest/determinism oracles; exact 1/4/16-MiB reports; earlier-cap truth; frozen AHB/IAL2 invariant and scale-bypass rejection; staging cleanup; default/exact/adjacent regression; contract/book/card/rationale/task/Memory continuity; staged acceptance/doctrines and artifact census | `passed`; default t1602 Files=1/Tests=5 in 17 seconds, final RAM-guarded exact t1602 Files=1/Tests=5 in 122 seconds, and adjacent t1551/t1600/t1601 Files=3/Tests=17. Source-map gate is exactly 8,192; its higher valid profiles stop at the earlier serialized cap; serialized reports are exactly 1,048,576/4,194,304/16,777,216 bytes. The AHB report SHA-256 remains `a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca`; no public support/performance/capacity claim changes. |
| `2026-08-10` | `.17.2.3.2` activation | clean selection predecessor `9c5212cc4`; decision `0060`; exact route/nonclaim boundary; task/index/Memory continuity; task-tree, relative-path, diff, and staged-doctrine gates | `passed`; `.17.2.3.2` alone is active for canonical bridge-fanout implementation. Generator, parser, scheduler, builder, manifest, capability/support, performance, and scale behavior remain unchanged. |
| `2026-08-10` | `.17.2.3.1` bridge-scale reachability selection | exact history `51434a2ae`/`0516f2c66`; parser/builder/contract source audit; real ordinary IAL1 parse/scheduler-report/lower probe; decision `0060`; task/index/contract/book/fact/rationale/Memory/containment continuity; task-tree, Knowledge Map, documentation, mdBook, relative-path, diff, and staged-doctrine gates | `passed`; one closed `qualification_only` direct-IAL1 profile is selected for `.17.2.3.2` implementation, with private scale-evidence capability and earliest-cap authority. Task integrity reports three trees/934 nodes; Knowledge Map reports 1,106 facts/5,733 questions/5,899 occurrences/119 shards; documentation reports Files=8/Tests=89; all 52 chapters test; and the inspected repository-local build contains 88 files/18,396,279 bytes before exact removal. The exact AHB and IAL2 routes, product code, support classification, performance budgets, and all capacity nonclaims remain unchanged. |
| `2026-08-10` | `.17.2.3.1` activation after reachability audit | clean parent activation `4a6e5f6de`; implementation/contract/history audit across decisions `0035`/`0055`, the IAL1 annotation parser, bridge builder, manifest contract, and t1551; task/index/Memory continuity; task-tree, relative-path, diff, and staged-doctrine gates | `passed`; the exact fixed-AHB/candidate mismatch is durably isolated before code. `.17.2.3.1` alone is active to select the repair; `.17.2.3.2` remains proposed. No parser, scheduler, builder, manifest, route, artifact, capability/support, performance-budget, or capacity behavior changes. |
| `2026-08-10` | `.17.2.3` activation | clean `.17.2.2` predecessor `145d3084a`; selected decision-0055 bridge-family route/oracle contract; task/index/fact/Memory continuity; task-tree, Knowledge Map, relative-path, diff, and staged-doctrine gates | `passed`; `.17.2.3` alone is active for canonical bridge-fanout workload generation and exact manifest oracles. Builder, bridge, manifest, route, artifact, capability/support, performance-budget, and capacity behavior remain unchanged. |
| `2026-08-10` | `.17.2.2` canonical semantic generation | canonical 70-spec source construction; exact counts/IDs/spans/references/types/order/reports/formatting/boundaries/diagnostics; success/failure staging cleanup; decisions `0058`/`0059`; semantic-ID regressions; exact opt-in qualification/limit/excess proof; canonical native-UVM/portable-VHDL/OSVVM gallery and exact GHDL qualification refreshes; guarded 21-file impacted suite; task/book/Knowledge Map/Memory/live-reference/staged-acceptance/doctrine gates; repository-local mdBook build and exact artifact cleanup | `passed`; default t1601 reports Files=1/Tests=4 in 17 seconds and exact guarded t1601 reports Files=1/Tests=4 in 359 seconds. Final impacted regression reports Files=21/Tests=140 in 221 seconds, including real Verilator and exact GHDL/OSVVM qualification. Documentation governance reports Files=8/Tests=89, 2,969/2,969 paths, exact book delta 0/+67/+3,225, and one reviewed 1,106→1,107 knowledge-card ceiling change. Knowledge Map is current at 1,106 facts/5,733 questions/5,899 occurrences/119 shards. All 52 chapters test; the rendered repository-local build contains 88 files/18,392,884 bytes before exact removal. The semantic family accepts no IR, checked action-local IDs are globally unambiguous, and the literal-repeat interaction remains an explicit `.17.4` repair input. No support, performance-budget, or capacity claim is made. |
| `2026-08-10` | `.17.2.2` activation | clean `.17.9` repair predecessor `3c948294b`; dependency and ownership boundary; task/index/fact/Memory continuity; task-tree, Knowledge Map, relative-path, diff, staged acceptance, and doctrine gates | `passed`; `.17.2.2` alone is active for canonical semantic-catalog workload generation and semantic oracles. Generator implementation, parser behavior, SemanticIR, artifact, capability/support, performance, and scale claims remain unchanged. |
| `2026-08-10` | `.17.9` failed-stage cleanup repair | git history/blame; all repository remove_tree error collectors; one scalar-reference production repair; public CLI first-write failure, stable diagnostic, exact stage/target absence, identical retry; successful/unchanged/collision/path safety; source/planning/real-Verilator/AHB-parity regression; task/book/Knowledge Map/Memory/live-reference/staged-acceptance/doctrine gates; mdBook test/build/render inspection; artifact census and exact cleanup | `passed`; bad collector originates in `045629c97`; all six production collectors are now correct. Focused t1556 reports Files=1/Tests=6 and the impacted suite reports Files=4/Tests=20. The failure returns exact `VIAL_HOST_ERROR`, leaves neither operation stage nor target, and retries to atomic success. No artifact graph, target root, parser, plan, backend, runtime, capability/support, or scale behavior changes. |
| `2026-08-10` | `.17.9` activation | clean `.17.2.1` predecessor `063b990f3`; exact File::Path error-collector source/probe evidence; task/index/fact/Memory continuity; task-tree, Knowledge Map, relative-path, diff, staged acceptance, and doctrine gates | `passed`; `.17.9` alone is active for the bounded public ArtifactTransaction failed-stage cleanup repair before `.17.2.2`. Implementation, test behavior, artifact graph, target root, parser, plan, backend, runtime, capability/support, and scale claims remain unchanged. |
| `2026-08-10` | `.17.2.1` deterministic workload foundation | decision `0057`; exact workload/catalog/construction/staging schemas; all 250 family/axis/level specifications; backend/tool selectors; stable names and fixed-seed payloads; canonical identity and reordered-input reruns; malformed schema/path/role/size/construction mutations; same-volume success/failure/collision cleanup; syntax and adjacent semantic/execution/public-tool regression; task/book/Knowledge Map/Memory/live-reference/staged-acceptance/doctrine gates; repository-local mdBook test/build/render inspection; artifact census and exact cleanup | `passed`; `FSM::VIAL::ArchitectureScaleWorkload` ships the source-only unmeasured foundation, while parser-through-runtime, capability/support, performance, and capacity remain unchanged. The focused/adjacent suite reports `All tests successful` at Files=5/Tests=38; all 52 chapters test and the rendered section is present in an 88-file/18,367,391-byte repository-local build removed exactly; maintained-reference authority accepts 0 files/+78 lines/+3,685 bytes. An initially incorrect local cleanup collector was corrected and its exact residue removed; no scale-stage residue remains. A separately reproduced pre-existing public ArtifactTransaction cleanup defect is owned by proposed `.17.9` rather than changed in this leaf. |
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
| `2026-08-01` | `.13.1.3` implementation | revision-3 emitter/static-validator/support syntax; typed item/scenarios/sequencer/driver; portable decision replay and isolated non-executed native solver preview; driven/observed analysis and typed TLM; exact scoped config and factory override; private RAL preview; 64-entry map; 12 checks; deterministic seven-source gallery regeneration; focused/support/docs/task/mdBook/Knowledge Map/Memory/staged-doctrine gates | `passed`; focused Files=5/Tests=7,110; guarded semantic/native/support Files=11/Tests=7,153; portable execution Files=1/Tests=5 and parity Files=1/Tests=4; docs/task/live/history/map Files=11/Tests=97 after repairing the exact stale 1,017-versus-1,018 focused-index oracle introduced with `.13.1.1`; all 49 chapters test; removed repository-local build 85 files/16,751,666 bytes; task integrity three trees/907 nodes/one segment/one index archive; exact mdBook delta 0/+35/+1,692; Knowledge Map 1,104 facts/5,630 questions/5,796 occurrences/117 shards; Memory 47 lines; staged acceptance and all nine doctrine checks pass with zero ceiling increases |
| `2026-08-01` | `.13.1.4` activation | clean `.13.1.3` implementation predecessor `6463779be`; task/index/audit/book/fact/Memory continuity; relative paths/task/live-reference/Knowledge Map; mdBook test/build; diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; docs/live/task/Knowledge Map suite reports `All tests successful` at Files=6/Tests=71; all 49 mdBook chapters test and the repository-local build contains 85 files/16,751,669 bytes before exact removal; task integrity remains three trees/907 nodes/one segment/one index archive; exact mdBook delta is 0/0/-9; Knowledge Map remains 1,104 facts/5,630 questions/5,796 occurrences/117 shards; Memory is 47 lines; staged acceptance and all nine doctrine checks pass with zero ceiling increases; implementation, generated artifacts, public capability, parser, compile, elaboration, runtime, result, and parity remain unchanged |
| `2026-08-01` | `.13.1.4` implementation | revision-4 emitter/static-validator/support syntax; public coverage/property/model/scoreboard/fault emission; typed diagnostic/result collection; bound SVA review checker; width-aware notification-predicate repair; 75-entry map; 14 checks; deterministic nine-source gallery; focused/broader VIAL, portable runtime/parity, docs/task/live/Knowledge Map, mdBook, Memory, and staged-doctrine gates | `passed`; focused Files=6/Tests=7,118; guarded semantic/native/support Files=12/Tests=7,161; portable Verilator execution Files=1/Tests=5 and AHB parity Files=1/Tests=4; docs/task/live/history/map Files=12/Tests=111; all 49 chapters test; removed repository-local build 85 files/16,768,599 bytes; task integrity three trees/907 nodes/one segment/one index archive; exact mdBook delta 0/+47/+2,390; Knowledge Map 1,104 facts/5,633 questions/5,799 occurrences/117 shards; Memory 44 lines; staged acceptance and all nine doctrine checks pass with zero ceiling increases; parse, compile, elaboration, native runtime/result/parity, probe-backed expectation execution, and visual-review completion remain unclaimed |
| `2026-08-01` | `.13.1.5` activation | clean `.13.1.4` implementation predecessor `193d170e0`; task/index/audit/book/fact/Memory continuity; relative paths/task/live-reference/Knowledge Map; mdBook test/build; diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; docs/live/task/Knowledge Map suite reports `All tests successful` at Files=6/Tests=76; all 49 mdBook chapters test and the repository-local build contains 85 files/16,768,886 bytes before exact removal; task integrity remains three trees/907 nodes/one segment/one index archive; exact mdBook delta is 0/+1/+51; Knowledge Map remains 1,104 facts/5,633 questions/5,799 occurrences/117 shards; Memory is 45 lines; staged acceptance and all nine doctrine checks pass with zero ceiling increases; implementation, generated artifacts, public capability, visual-review evidence, parser, compile, elaboration, runtime, result, and parity remain unchanged |
| `2026-08-01` | `.13.1.5` implementation | revision-5 emitter/review-closure/support syntax; exact 25-row source/IR/role/state mapping matrix; seven-stage repository-relative review workflow; non-mutating gallery byte check; two canonical JSON evidence snapshots; exact capability/support/non-claims; fail-closed negative oracles; book/task/audit/fact/Memory continuity | `passed`; focused native/support Files=7/Tests=7,125; broader semantic/public/native gates pass in bounded partitions totaling Files=13/Tests=7,168; portable execution Files=1/Tests=5 and parity Files=1/Tests=4; docs/task/live/history/map Files=12/Tests=101; all 49 chapters test; removed repository-local build 85 files/16,787,078 bytes; task integrity three trees/907 nodes/one segment/one index archive; exact mdBook delta 0/+46/+2,327; Knowledge Map 1,104 facts/5,635 questions/5,801 occurrences/117 shards; Memory 47 lines; exact graph is 16 artifacts/10 SystemVerilog sources/75 maps/14 structural checks/25 mappings/7 workflow stages/5 closure invariants/9 source snapshots/2 evidence snapshots; final staged acceptance and all nine doctrine checks pass; visual review and parse through parity remain pending or unclaimed |
| `2026-08-01` | `.13.2` activation | clean completed-emission predecessor `7725789a4`; task/index/audit/book/fact/Memory continuity; docs/live/task/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; docs/live/task/Knowledge Map Files=6/Tests=76; all 49 mdBook chapters test and the repository-local build contains 85 files/16,788,798 bytes before exact removal; task integrity remains three trees/907 nodes/one segment/one index archive; exact mdBook delta is 0/+5/+305; all 22 live surfaces and 2,941/2,941 paths pass with zero ceiling increases; Knowledge Map remains 1,104 facts/5,635 questions/5,801 occurrences/117 shards; Memory is 47 lines; `.13.2` alone is active while tool/library inspection, implementation, and all emission-through-product-support states remain unchanged; final staged acceptance and all nine doctrine checks pass |
| `2026-08-01` | `.13.2` implementation | exact Verilator/UVM source identities and comparison delta; bounded reusable probe module/script; independent preprocess/parse/library compile-elaboration/runtime/fixture compile-elaboration stages; canonical report and byte-check; reserved-keyword generator repair and refreshed gallery; source/support/capability/focused/broader/docs/task/mdBook/Knowledge Map/Memory/staged-doctrine gates; exact staging/build/manual-probe cleanup | `passed`; exact Verilator 5.046 plus uvm-verilator commit/tree frozen; guarded canonical run and independent `--check` deterministically conclude `partial_tool_limited`; UVM control passes through zero-error/fatal runtime, generated fixture preprocesses, ranged SVA is unsupported, blackboxing reaches tool internal fault/139, and fixture runtime/result/parity remain not run; focused native/probe Files=6/Tests=44 and impacted VIAL/support Files=16/Tests=7,183 pass; docs/history Files=12/Tests=70 pass; all 49 mdBook chapters test and its 85-file/16,584-KiB build is removed exactly; final acceptance details are recorded below; product support remains false and `.13.3` remains provider-blocked while `.14` is the next unblocked leaf |
| `2026-08-01` | `.14` activation | clean `.13.2` implementation predecessor `adc88817e`; task/index/audit/book/fact/Memory continuity; docs/live/task/mdBook/Knowledge Map/Memory/diff/staged docs-only acceptance/doctrines; exact cleanup | `passed`; docs/live/task/Knowledge Map Files=6/Tests=76; all 49 mdBook chapters test and the repository-local build contains 85 files/16,588 KiB before exact removal; task integrity remains three trees/907 nodes/one segment/one index archive; exact mdBook delta is 0/+5/+294; all 22 live surfaces and 2,942/2,942 paths pass with zero ceiling increases; Knowledge Map remains 1,104 facts/5,641 questions/5,807 occurrences/117 shards; Memory is 46 lines; `.14` alone is active while every provider/tool/version/migration/artifact/capability/runtime choice remains unchanged; final staged acceptance and all nine doctrine checks pass |
| `2026-08-01` | `.14` selection | official GHDL/OSVVM/UVVM release and exact tag-identity reads; local inert-package/capability audit; decision `0051`; provider-free/OSVVM mapping, profiles, artifacts, scheduling, values, GHDL gates, migration, PSL/non-claims; legacy/focused/docs/task/live/mdBook/Knowledge Map/Memory/diff/staged-acceptance/doctrine gates; exact cleanup | `passed`; provider-free VHDL-2008 plus OSVVM 2026.05 selected, GHDL 6.0.0 and broader families frozen unexecuted, UVVM audited/unselected, and the legacy package unchanged. Legacy Files=2/Tests=6 and focused Files=6/Tests=65 report `All tests successful`; all 49 chapters test; rendered 85-file/16,885,255-byte HTML has distinct paragraphs/table/code blocks and is removed; task integrity remains three trees/907 nodes/one segment/one index archive; live containment covers 22 surfaces/2,942 paths with exact mdBook delta 0/+156/+6,986 and zero ceiling increases; Knowledge Map is current at 1,104 facts/5,656 questions/5,822 occurrences/117 shards; Memory is 47 lines; no backend artifact or VHDL analysis-through-parity capability ships |
| `2026-08-01` | `.15` activation/decomposition | clean selection predecessor `e5aa90b7a`; seven exact implementation children; task/index/audit/book/fact/Memory continuity; focused docs/live/task/Knowledge Map; mdBook test/build/rendered-paragraph inspection; memory/diff/staged acceptance/doctrines; exact cleanup | `passed`; `.15` and `.15.1` alone are active, `.15.1-.15.4` are the unblocked provider-free emission/review path, `.15.5` owns GHDL qualification, and `.15.6-.15.7` own OSVVM emission/qualification. Focused Files=6/Tests=65 report `All tests successful`; all 49 chapters test and rendered HTML separates the activation into distinct paragraphs; the repository-local 85-file/16,888,889-byte build is removed exactly. Task integrity is three trees/914 nodes/one segment/one index archive; all 22 live surfaces and 2,943/2,943 paths pass with exact mdBook delta 0/+12/+718 and zero ceiling increases; Knowledge Map remains 1,104 facts/5,656 questions/5,822 occurrences/117 shards; Memory is 47 lines; final staged acceptance and all nine doctrine checks pass; no source, artifact, capability, runtime, result, parity, or support behavior changes |
| `2026-08-01` | `.15.1` implementation | private HIAL VHDL handoff; provider-free emitter/static validator/support syntax; deterministic thirteen-artifact/five-source graph and five-entry source map; seven structural checks; exact selected/unexecuted GHDL records; atomic publication/collision/cleanup; checked gallery; impacted VIAL/support/capability and documentation-doctrine suites; task/live/Knowledge Map/Memory; mdBook test/build/rendered-paragraph inspection; diff/staged acceptance/doctrines; artifact census and exact cleanup | `passed`; guarded impacted regression reports `All tests successful` at Files=12/Tests=7,164 and guarded documentation doctrines at Files=15/Tests=133; all 49 chapters test; the repository-local 85-file/16,919,119-byte build renders the new VHDL section as 17 distinct paragraphs and five distinct code blocks with a 612-byte longest paragraph before exact removal. The gallery checker reports five VHDL sources/eight evidence artifacts/five maps/seven checks; task integrity is three trees/914 nodes/one segment/one index archive; all 22 live surfaces and 2,944/2,944 paths pass with exact mdBook delta 0/+80/+3,291 and zero ceiling increases; Knowledge Map is current at 1,104 facts/5,662 questions/5,828 occurrences/117 shards; Memory is 47 lines; no `.bin`/`.log`, Rust target `.bin`/`.log`, mdBook build, or VIAL operation staging residue remains; final staged acceptance and all nine doctrine checks pass; VHDL analysis through product support remains explicitly unclaimed |
| `2026-08-02` | `.15.2` implementation | provider-free emitter/validator/support syntax; fourteen-artifact/six-source semantics graph; 52 maps and 13 checks; typed drive/sample, inactive-edge scheduling, exact ranks, bounded scenarios/fibers, deterministic models, declared probe adapter; negotiation/mutation negatives; checked gallery; impacted VIAL/support/capability suite; task/live/Knowledge Map/Memory; mdBook test/build/rendered-paragraph inspection; staged acceptance/doctrines; artifact census and exact cleanup | `passed`; the guarded impacted suite reports `All tests successful` at Files=12/Tests=7,168; six changed Perl/script/test paths report `syntax OK`; the gallery checker reports six VHDL sources/eight evidence artifacts/52 maps/13 checks. All 49 chapters test and the repository-local build contains 85 files/16,928,012 bytes; the changed VHDL prose renders as distinct paragraph and code blocks before exact removal. Task integrity is three trees/914 nodes/one segment/one index archive; all 22 live surfaces and 2,944/2,944 paths pass with exact mdBook delta 0/+24/+1,385 and zero ceiling increases; Knowledge Map is current at 1,104 facts/5,666 questions/5,832 occurrences/117 shards; Memory is 47 lines; final staged acceptance and all nine doctrines pass. Two initially misresolved same-volume mdBook destinations were measured at 85 files/16,696 KiB each, replaced by the verified repository-local build, deleted exactly, and residue-checked absent. No `.bin`/`.log`, mdBook build, or VIAL staging residue remains; analysis through support stays unclaimed. |
| `2026-08-02` | `.15.3` implementation | provider-free checking emitter/validator/support syntax; fourteen-artifact/six-source graph; capacity-four scoreboard, exact stall bins, immutable-source substitution, procedural checks, bounded stored diagnostics, logical-time closed trace, full top-level normalized-result projection; quote-escaping/result/trace/overflow/unknown/PSL/provider/probe mutations; checked gallery; impacted VIAL/support/capability suite; task/live/Knowledge Map/Memory; mdBook test/build/rendered-paragraph inspection; staged acceptance/doctrines; artifact census and exact cleanup | `passed`; the final guarded impacted suite reports `All tests successful` at Files=12/Tests=7,164; five changed Perl/test paths report `syntax OK`; the gallery checker reports six VHDL sources/eight evidence artifacts/59 maps/20 checks. All 50 chapters test and the repository-local build contains 86 files/17,822,884 bytes; rendered VHDL prose preserves distinct paragraphs and the VHDL-quote/full-result boundary before exact removal. Task integrity is four trees/917 nodes/one segment/one index archive; all registered live surfaces and 2,950/2,950 paths pass with exact mdBook delta 0/+17/+1,170 and zero ceiling increases; Knowledge Map is current at 1,105 facts/5,683 questions/5,849 occurrences/118 shards; Memory is 45 lines; final staged acceptance and all nine doctrines pass. No local VHDL analyzer is available, and no `.bin`/`.log`, repository-local verification output, mdBook build, or VIAL staging residue remains; analysis through support stays unclaimed. |
| `2026-08-02` | `.15.4` implementation | revision-4 review-closure/emitter/support/corpus syntax; 24-row selected matrix with public/compiler/bridge/private-preview partition and four exact unsupported reasons; seven-stage repository-relative review/durable-defect workflow; exact inert-legacy bytes/schema and HIAL byte/separation proof; seven closure invariants and fail-closed mutations; 17-artifact checked gallery; focused/impacted VIAL/support/capability suite; task/live/Knowledge Map/Memory; mdBook test/build/rendered structure; staged acceptance/doctrines; artifact census and exact cleanup | `passed`; the guarded impacted suite reports `All tests successful` at Files=13/Tests=7,172; ten changed Perl/script/test paths report `syntax OK`; the gallery checker reports six VHDL sources/11 evidence artifacts/59 maps/20 static checks/24 mappings/seven closure checks. The inert legacy fixture remains 976 bytes with exact package SHA-256 `8d587b8dde4b7659290af6720ed4812079f36479d577dd5a0cf787bef2a22d4f` and path-independent manifest-projection SHA-256 `29789c0b4b7400de45eec2ac1f62178d2e555f9c3d64ad871a1d87c5d39c5835`; HIAL DUT bytes match the private handoff. All 50 chapters test and the repository-local build contains 86 files/17,845,293 bytes; the changed chapter renders 213 paragraphs/11 tables/41 code blocks with the matrix, rejection, workflow, and migration sections present before exact removal. Task integrity remains four trees/917 nodes/one segment/one index archive; Knowledge Map is current at 1,105 facts/5,687 questions/5,853 occurrences/118 shards; Memory is 45 lines; all live surfaces and the final staged acceptance/nine doctrines pass with zero ceiling increases. No exact VHDL analyzer or provider is local, and no `.bin`/`.log`, legacy-proof output, mdBook build, or VIAL staging residue remains; visual review and analysis through support stay pending or unclaimed. |
| `2026-08-09` | `.15.5` activation and NEXSIM deferral | director priority; official GHDL v6.0.0 release metadata and macOS ARM64 package digest; task/index/audit/book/fact/Memory continuity; task integrity; Knowledge Map; mdBook test; diff/staged-doctrine gates | `passed`; NEXSIM-dependent `.13.3` and the separate amendment tree are deferred, exact GHDL asset `ghdl-llvm-6.0.0-macos15-aarch64.tar.gz` is available at 42,445,801 bytes with SHA-256 `69beb5913a490b5971980bd045af6a63b6f52e861b444fa990bffac436587478`, `.15.5` alone becomes active, task integrity reports three active trees/916 nodes, Knowledge Map remains 1,105 facts/5,706 questions/5,872 occurrences/118 shards, all 52 mdBook chapters test, Memory is 40 lines, and final staged doctrines pass; no provider bytes are installed and no product behavior or support claim changes. |
| `2026-08-09` | `.15.5` exact GHDL qualification | exact repository-local GHDL 6.0.0 LLVM-JIT archive/binary identities; provider-free source repairs; ordered `--std=08` analysis/elaboration/run; 42-record trace/result validation; timed `0/1/X/Z` probe; deterministic reruns; 19-path portable-SV parity; resource guard; exact cleanup; support/capability/gallery/docs/task/Knowledge Map/Memory/staged-doctrine gates | `passed`; canonical report `vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json` is qualified, while the exact LLVM AOT external-name runtime failure and every broader language/provider/tool/profile non-claim remain explicit; `.15.6` is next after the clean commit. |
| `2026-08-09` | `.15.6` activation | clean exact-GHDL predecessor `a0e7149d5`; task/index/book/fact/Memory continuity; task integrity; Knowledge Map; mdBook test; live-reference authority; diff/staged-doctrine gates | `passed`; `.15.6` alone is active for exact recursive OSVVM 2026.05 materialization and adapter/gallery emission, `.15.7` remains proposed, task integrity reports three active trees/916 nodes, Knowledge Map reports 1,105 facts/5,709 questions/5,875 occurrences/118 shards, all 52 mdBook chapters test, and the exact maintained-reference delta is 0 files/0 lines/+4 bytes; no provider bytes, source, generated artifact, capability, runtime, result, or support behavior changes. |
| `2026-08-09` | `.15.6` implementation | official tag identity; complete repository-local recursive clone; 14 repository commit/tree/origin/tracked-entry identities; 13 gitlinks; clean-worktree proof; 14 licence/0 notice identities; Documentation metadata absence; revision-1 adapter, mapping matrix, source map, semantic-preservation proof, static negatives, gallery, support/docs/task/Knowledge Map/Memory/staged-doctrine gates | `passed`; exact OSVVM 2026.05 is installed, seven advanced mappings emit in one isolated adapter beside six byte-identical portable sources, and the fifteen-artifact gallery carries 13 maps/12 checks/six unchanged-semantic guards. The Documentation gitlink has no tracked licence/notice file and no coverage is inferred. Guarded impacted Files=6/Tests=36 and the exact gallery check pass; Knowledge Map is current at 1,105 facts/5,713 questions/5,879 occurrences/118 shards; task integrity reports three active trees/916 nodes; all 52 mdBook chapters test and the 87-file/18,073,088-byte repository-local build passes before exact removal. Combined OSVVM/GHDL analysis through parity remains solely `.15.7`. |
| `2026-08-09` | `.15.7` activation | clean `.15.6` predecessor `4f350f29c`; task/index/audit/book/fact/Memory continuity; task integrity; Knowledge Map; mdBook test; live-reference authority; diff/staged-doctrine gates | `passed`; `.15.7` alone is active for combined exact OSVVM 2026.05 plus GHDL 6.0.0 LLVM-JIT qualification. Both inputs remain repository-local; task integrity reports three active trees/916 nodes, Knowledge Map remains 1,105 facts/5,713 questions/5,879 occurrences/118 shards, all 52 mdBook chapters test, and maintained-reference authority accepts the exact 0-file/0-line/+16-byte delta. Activation changes no source, generated artifact, qualification evidence, capability, runtime result, or support behavior. |
| `2026-08-09` | `.15.7` exact combined qualification | exact GHDL archive/binary and recursive OSVVM identities; 44-core/17-Common ordered provider compilation; adapter/generated-fixture/probe analysis; fixture/probe elaboration and double execution; 42-record trace/result validation; 19-path portable parity; four deterministic OSVVM reports; bounded support/capability truth; same-volume cleanup; focused/corpus/capability/gallery/docs/task/Knowledge Map/mdBook/staged-doctrine gates | `passed`; `vhdl_osvvm_qualified` is bounded-qualified under exact OSVVM 2026.05 plus GHDL 6.0.0 LLVM-JIT. Six adapter mappings execute in the probe; the Common address-bus mapping is analysis-only. OSVVM reports record three clean affirmations, 25% one-of-four-bin/25% coverage, and one checked scoreboard item with zero errors, while portable trace/result/parity remain authoritative. Broader provider/language/tool/profile claims remain explicit non-claims. |
| `2026-08-10` | `.17` selection/activation | clean predecessor `6d23b5843`; mixed-language command/provider census; decisions 0032/0051; five-leaf scale decomposition; task/index/book/fact/Memory continuity; task integrity; Knowledge Map; mdBook build; relative paths; live-reference authority; diff/staged-doctrine gates; exact cleanup | `passed`; `.16` remains proposed because no compatible mixed-language runtime is available, and `.17.1` alone is active for documentation-only scale-contract selection. Task integrity reports three active trees/921 nodes; Knowledge Map reports 1,105 facts/5,723 questions/5,889 occurrences/118 shards; the book shrinks by 34 lines/2,676 bytes while replacing stale chronology with current capability and scale boundaries; generated output is removed. No product behavior or scale claim changes. |
| `2026-08-10` | `.17.2.4.2` activation | clean selection predecessor `b82426c85`; decision 0061; caller-sealed admission and canonical route/oracle scope; task/index/Memory continuity; task integrity; Knowledge Map; relative paths; diff/staged-doctrine gates | `passed`; `.17.2.4.1` is done and `.17.2.4.2` alone is active for canonical execution-scale generator implementation. The mdBook and fact card already identify this implementation owner and its exact route/nonclaim contract, so activation adds no status-board prose. No code, test, config, generated artifact, support, or product behavior changes. |
| `2026-08-10` | `.17.2.4.2` binding-gate foundation | caller-sealed binder entry; exact direct-IAL1 qualification metadata; 2,042-event ordinary IAL1/VIAL construction; canonical bridge/SemanticIR/ExecutionIR/plan route; exact 2,048-binding and isolation oracles; public/direct/metadata/construction negatives; deterministic plan; focused/adjacent guarded regressions; task/book/fact/Memory/live/staged-doctrine gates | `passed`; the private gate produces 2,048 bindings, 2,042 events, one type/scenario/reset/root fiber, 2,047 source maps, and a 2,656,823-byte target-neutral plan. Public planning remains closed, and the private capability is qualification-only/nonportable. `.17.2.4.2` remains active for the other axes and levels. |
| `2026-08-10` | `.17.2.4.2` scenario/operation topology gates and source-map repair | exact checked-AHB source; 32x1/1x256/32x32 reset constructions; canonical public bind; source-map path census; Knowledge Map absence query; `git log -S`/blame; global-offset repair; exact semantic/bridge/plan hashes and byte counts; hostile inputs; native-UVM/portable-VHDL/OSVVM gallery refresh; exact GHDL/OSVVM requalification; guarded focused/impacted regression; task/book/fact/rationale/Memory/live/staged-doctrine gates | `passed`; the three gates contain 32/256/1,024 genuine operations, 32/1/32 root fibers, one live fiber, 49/273/1,041 maps, and 59,907/121,163/409,363 plan bytes. The pre-existing `44dbecd1a` source-map writer now adds each scenario's global operation offset, so every flat-plan operation has one map while scenario-local ranks/IDs remain stable. Public/private capability separation holds; committed as `0f9d27611`. |
| `2026-08-10` | `.17.2.4.2` total/live fiber gates | exact checked-AHB source; sequential 31/31/31/31/3 all-join groups; bounded 2-outer/29-nested depth-two all-join tree; exact fiber/operation/live/map/plan/hash identities; parent/child, successor, rank, phase, and source-map closure; public capability isolation; mutation/unfinished-level rejection; focused and adjacent regression; task/book/fact/rationale/Memory/live/staged-doctrine gates | `passed`; total-fiber construction reaches 128 total and 32 live fibers through 132 operations, 149 maps, and a 79,987-byte plan. Live-fiber construction reaches exactly 32 total/live fibers through 32 operations, 49 maps, and a 43,811-byte plan. Both traverse ordinary checked-AHB IAL2/IAL1/IAL0 and the public binder. Final guarded architecture/public-planning regression passes at Files=9/Tests=44; all 52 book chapters test and the 88-file/18,216-KiB render is inspected then removed; Knowledge Map, 936-node task integrity, 2,972-path live containment, rationale reconstruction, relative paths, zero ceiling increases, and staged doctrines pass. No private capability, backend behavior, support, performance, or capacity claim changes. |
| `2026-08-10` | `.17.2.4.2` execution-type gate | ordinary non-annotated direct-IAL1 source; exact widths 1..512; 512 public endpoint relations; canonical public binder; IAL1/IAL0 route and capability closure; exact type/binding/map/bridge-byte/plan/hash identities; null-annotation preservation; mutation/source-injection/unfinished-level rejection; focused and adjacent regression; task/book/fact/rationale/Memory/live/staged-doctrine gates | `passed`; the gate contains 512 distinct four-state unsigned logic shapes, 514 bindings, 514 maps, an exact 8,237,394-byte bridge report, one scenario/reset/root fiber, and a 735,488-byte plan. Generated HIAL/VIAL sources are 17,901/63,780 bytes with frozen identities. The scale helper no longer autovivifies an absent verification bridge while collecting optional probe names. Final verification details are recorded below. No private capability, backend behavior, support, performance, or capacity claim changes. |
| `2026-08-10` | `.17.2.4.2` execution source-map gate | frozen checked-AHB source; exact census of 17 fixed maps; 8,175 genuine resets; public canonical binder; unique plan paths; exact semantic-action and ordered byte-span projection; real bridge facts; closed reset chain; exact source/SemanticIR/bridge/workload/plan identities; mutation/missing-source/unfinished-level rejection; focused and guarded impacted regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; the gate contains exactly 8,192 source maps, 8,175 operations, one scenario/root/live fiber, 22 bindings, seven types, six events, a 508,968-byte unchanged bridge report, and a 2,949,646-byte target-neutral plan. Focused t1607 passes at Files=1/Tests=4; the guarded impact matrix passes at Files=10/Tests=47 in 111 seconds. No private capability, backend behavior, support, performance, or capacity claim changes. |
| `2026-08-10` | `.17.2.4.2` execution random/replay gate | frozen checked-AHB source; one referenced two-state u64 choice over the full unsigned range; exact deterministic attempt-8,191 candidate; check-phase operation; public canonical binder; independent generation; strict replay; decision/plan equality; exact source/SemanticIR/bridge/workload/generated/replayed identities; replay/source mutation and missing-source/unfinished-level rejection; focused and guarded impacted regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; candidate `0x7da2c124f3fb4c11` accepts after exactly 8,192 attempts. Generated/replayed decisions differ only in origin; their plans are 34,295/34,294 bytes. The graph contains one occurrence/scenario/operation/root-live fiber, eight types, 22 bindings, and 19 maps. Focused t1608 passes at Files=1/Tests=4 in 14 seconds; the guarded impact matrix passes at Files=11/Tests=51 in 126 seconds. No private capability, backend behavior, support, performance, or capacity claim changes. |
| `2026-08-10` | `.17.2.4.2` exact one-MiB execution plan gate | frozen checked-AHB source; decision-0061 2,974-reset recipe; referenced 41/2-character scenario/endpoint suffixes; real HREADYOUT coverpoint; public canonical binder; exact source/SemanticIR/bridge/workload/plan identities; unique map/source-span closure; contiguous reset topology; hostile-input and missing-source/unfinished-level rejection; focused and guarded impacted regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; canonical plan is exactly 1,048,576 bytes with ID `plan/ee10e4a5749a4398b9e62d5a1624d24c74e585459afd57f8cb7503306545c035`. It contains 2,974 real resets, one scenario/root-live fiber, seven types, 22 bindings, six events, and 2,991 maps. Focused t1609 passes at Files=1/Tests=4 in 4 seconds; the guarded impact matrix passes at Files=12/Tests=55 in 127 seconds. No private capability, backend behavior, support, performance, or capacity claim changes. |
| `2026-08-10` | `.17.2.4.2` exact four-MiB execution plan qualification | frozen checked-AHB source; decision-0061 12,166-reset recipe; referenced six-/two-character scenario/endpoint suffixes; real HREADYOUT coverpoint; public canonical binder; exact source/SemanticIR/bridge/workload/plan identities; unique map/source-span closure; contiguous reset topology; hostile-input and missing-source/unfinished-level rejection; focused and guarded impacted regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; canonical plan is exactly 4,194,304 bytes with ID `plan/63673374ece891a4234613c00c920ffe60cb4d6d73904ba0be2a2d5799f60d62`. It contains 12,166 real resets, one scenario/root-live fiber, seven types, 22 bindings, six events, and 12,183 maps. Paired t1609/t1610 passes at Files=2/Tests=8 in 17 seconds; the guarded impact matrix passes at Files=13/Tests=59 in 142 seconds. No private capability, backend behavior, support, performance, or capacity claim changes. |
| `2026-08-10` | `.17.2.4.2` exact sixteen-MiB execution plan limit | frozen checked-AHB source; decision-0061 48,850-reset recipe; referenced 106-/two-character scenario/endpoint suffixes; real HREADYOUT coverpoint; public canonical binder; exact source/SemanticIR/bridge/workload/plan identities; unique map/source-span closure; contiguous reset topology; hostile-input and missing-source/unfinished-level rejection; focused and guarded impacted regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; canonical plan is exactly 16,777,216 bytes with ID `plan/0709d0c4d1432a218a0f26d9cce0c2b308d2f6fcf95f008bf6ceb65b15dc1e64`. It contains 48,850 real resets, one scenario/root-live fiber, seven types, 22 bindings, six events, and 48,867 maps. Focused t1609/t1610/t1611 passes at Files=3/Tests=12 in 67 seconds; the guarded impact matrix passes at Files=14/Tests=63 in 191 seconds. No private capability, backend behavior, support, performance, or capacity claim changes. |
| `2026-08-10` | `.17.2.4.2` first complete execution-plan excess | exact limit route/name/timeout reuse; one appended complete reset; ordinary SemanticIR parse; exact source/workload/SemanticIR identities; unchanged public builder; stable plan-cap diagnostic; no partial ExecutionIR/plan; expected-rejection evaluation; deterministic rerun; mutation/missing-source/unowned-level rejection; focused and guarded impacted regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; the 587,434-byte source contains exactly 48,851 resets and differs from the accepted limit source by only the final 12-byte ` (reset b 1)` record. The builder returns only `VIAL_EXECUTION_LIMIT_ERROR`, phase `limit`, message `serialized_plan_bytes exceeds the limit 16777216`, semantic path `/plan`; the evaluator classifies that exact result as `expected_rejection`. Focused t1609-t1612 passes at Files=4/Tests=16; the guarded impact matrix passes at Files=15/Tests=67. No parser, SemanticIR, bridge, public binder, backend behavior, support, performance, or capacity claim changes. |
| `2026-08-11` | `.17.2.4.2` startup import-map measurement refresh | mandatory `bin/fsmgen` source/import-tree comparison; live `Module::ScanDeps` closure and family census; exact source line counts; map/fact/Knowledge Map synchronization; documentation and doctrine gates | `passed`; the live closure remains exactly 254 project files / 253 packages with Support 76, IAL2 19, VIAL 17, and HIAL 3. Architecture topology is unchanged; the maintained map now records the current 1,889-/1,923-line VIAL SemanticBuilder/ExecutionBuilder measurements. Knowledge Map reports 1,108 facts/5,757 questions/5,923 occurrences/120 shards; task integrity, relative paths, live containment, maintained-reference authority, and diff checks pass. The correction does not pivot the tree, change the 262,144-attempt frontier, or alter product behavior. |
| `2026-08-11` | `.17.2.4.2` 262,144-attempt random/replay qualification | decision-0061 exact qualification candidate; caller-sealed level admission; deterministic u64 proposal at zero-based attempt 262,143; ordinary checked-AHB VIAL/bridge/binder route; strict generated/replayed equality; exact identities and mutation negatives; focused and guarded regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; exact candidate `0x00f233516a996304` accepts at attempt 262,143. Generated/replayed decisions differ only in origin and their target-neutral plans are exactly 34,297/34,296 bytes. The graph remains one occurrence/scenario/operation/root-live fiber, eight types, 22 bindings, and 19 maps. Focused t1613 passes at Files=1/Tests=4 in 207 seconds; the guarded impact matrix passes at Files=16/Tests=71 in 459 seconds. All 53 book chapters test; the repository-local 87-file/18,312-KiB render preserves distinct prose/code blocks and is removed exactly. Knowledge Map reports 1,108 facts/5,758 questions/5,924 occurrences/120 shards; task integrity, relative paths, live containment, exact book/fact authority, zero ceiling increases, and artifact residue checks pass. No public binder, capability/support, performance, or capacity claim changes. |
| `2026-08-11` | `.17.2.4.2` one-million random limit/exhaustion | decision-0061 exact limit and adjacent first-unreachable candidates; caller-sealed level admission; ordinary checked-AHB VIAL/bridge/public-binder route; strict replay; exact exhaustion diagnostic and no-partial-output oracle; source/replay mutation negatives; focused and guarded regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; candidate `0xdd7997a868500a54` accepts at zero-based attempt 999,999 and candidate `0xce7d67adbe54da82` exhausts at attempt 1,000,000. Accepted generated/replayed plans are exactly 34,297/34,296 bytes with IDs `plan/02b9207cd9392ba8b0d9e52afe9912f026fc00412ace076ff0fc30a32868b614`/`plan/90660802ee2bbbebdad84f79f66e1f5b6102befdb45de2f4c36f9a0d7f359f90`; the adjacent failure returns only exact `VIAL_RANDOM_EXHAUSTED` and no partial ExecutionIR/plan. Focused t1614 passes at Files=1/Tests=4 in 252 seconds, t1615 at Files=1/Tests=4 in 251 seconds, compatibility t1608/t1613 at Files=2/Tests=8 in 71 seconds, and the uninterrupted guarded impact matrix at Files=18/Tests=79 in 784 seconds. No public binder, capability/support, performance, or capacity claim changes. |
| `2026-08-11` | `.17.2.4.2` scenario qualification/limit/over-limit ladder | decision-0061 exact 512/4,096/4,097 scenarios; caller-sealed level admission; ordinary checked-AHB VIAL/bridge/public-binder route; one real reset/root fiber per scenario; exact source/workload/SemanticIR/bridge/plan identities and topology; stable first-excess diagnostic/no partial output; mutation/missing-source negatives; focused and guarded regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; qualification accepts 512 scenarios/operations/fibers, one live fiber, 529 maps, and a 496,709-byte plan with ID `plan/22aedcf295c44c0a1b411b557cb12c9e5476e19077e57e7efe60ec4d7dc1ebe7`. The exact limit accepts 4,096 scenarios/operations/fibers, one live fiber, 4,113 maps, and a 3,779,103-byte plan with ID `plan/036742cfb80ab0f04cf7a7c8d9be1de833f310f5fde98ca3be9e47d331294cfc`. The adjacent 4,097 source returns only `VIAL_EXECUTION_LIMIT_ERROR`, phase `limit`, message `selected_scenarios exceeds the limit 4096`, semantic path `/scenario_ids`, with no partial IR/plan. Focused t1616-t1618 passes at Files=3/Tests=12 in 20 seconds; the guarded impact matrix passes at Files=21/Tests=91 in 815 seconds. No public binder, capability/support, performance, or capacity claim changes. |
| `2026-08-19` | `.17.2.4.2` 8,192-operations-per-scenario qualification | decision-0061 exact 8,192-operation single-scenario level; caller-sealed level admission; ordinary checked-AHB VIAL/bridge/public-binder route; operation-depth versus scenario/fiber isolation; unique global operation source-map closure; exact source/workload/SemanticIR/bridge/plan identities; sub-cap plan bytes; mutation/missing-source/unowned-level negatives; focused and guarded regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; the 115,716-byte generated source authors one `scenario_00000000` with 8,192 genuine resets and no random decision. The unchanged public binder returns 8,192 total operations, one selected scenario, one root fiber, one simultaneously live fiber, 8,209 source maps, 22 bindings, seven types, and a 2,955,783-byte plan with ID `plan/4c6733ea702479b4c603761d333d491f7a427e9eac24dc37238331aeb624f990`. Every `/operation_graph/operations/N` path occurs once and resolves to its own `/packages/0/fixtures/0/scenarios/0/actions/N` authored action. Focused t1619 passes at Files=1/Tests=4 in 10 seconds; the guarded impact matrix passes at Files=22/Tests=95 in 814 seconds. The unimplemented 65,536/65,537 operation levels still fail closed. No public binder, capability/support, performance, or capacity claim changes. |
| `2026-08-19` | `.17.2.4.2` operation limit/over-limit ladder | decision-0061 exact 65,536/65,537 operation levels; caller-sealed level admission; ordinary checked-AHB VIAL/bridge/public-binder route; semantic-before-bridge stage order; exact source/workload identities and one-record source delta; stable authoritative diagnostics and no partial output; recorded limit-interaction discrepancies; mutation/missing-source/unowned-level negatives; focused and guarded regression; task/book/fact/Memory/live/staged-doctrine gates | `passed`; the 918,533-byte limit source parses into one complete 65,536-action scenario with the frozen `fb82ce2c…` SemanticIR and unchanged 508,968-byte AHB bridge, and the unchanged public binder returns only `VIAL_EXECUTION_LIMIT_ERROR`, phase `limit`, message `serialized_plan_bytes exceeds the limit 16777216`, at `/plan`. Adding exactly one further 14-byte ` (reset bus 1)` record makes the ordinary parser reject first with `VIAL_LIMIT_ERROR`, message `scenario exceeds 65536 expanded actions`, at `/packages/0/fixtures/0/scenarios/0`, and no bridge is built behind it. Both evaluations report `expected_rejection`, empty metrics, and one `VIAL_SCALE_LIMIT_INTERACTION` discrepancy routed to `.17.4`. Focused t1620 passes at Files=1/Tests=4 in 89 seconds and t1621 at Files=1/Tests=4 in 44 seconds; the guarded impact matrix passes at Files=25/Tests=95 in 960 seconds. No public binder, capability/support, performance, or capacity claim changes. |

## Acceptance Checklist (enforced) — `.17.2.6.2.2` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -1 --format='%h %s'` names clean
  completed predecessor `c3810ba8a`; current source inspection confirms
  `VHDLOSVVM2026_05->emit` directly invokes the complete recursive
  `OSVVM2026_05Materialization->verify` path, while decision `0075` and the
  ordered task decomposition require provider reuse before map translation.
- [x] **ADDRESSED (verified)** — `.17.2.6.2.2` alone is active for RED capture
  and an evaluation-local provider/source-bound seal. Task index and bounded
  Memory name the same frontier; `.2.3`-`.2.5` and generator `.3` remain
  proposed, and no implementation path changes.
- [x] **NO REGRESSION** — task-tree, relative-path, Memory, live-document,
  diff, and staged doctrine gates pass. The synchronized mdBook, Knowledge Map,
  decision `0075`, and completed portable-VHDL watcher remain unchanged because
  activation changes ownership state only, not emitted behavior or claims.

## Acceptance Checklist (enforced) — `.17.2.6.2.1` portable-VHDL linearization

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_find_line($metadata_text'
  --oneline -- perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm` and the matching
  validator history root both quadratic paths in portable-VHDL foundation
  commit `ab8b1af24`. Exact source audit finds four fixed metadata census scans
  plus three whole-text lookups per operation, one full metadata split/scan per
  operation source-map anchor, and full line-count/column rescans while
  finalizing every map. The new t1641 source-only control fails on all three
  patterns before implementation.
- [x] **ADDRESSED (verified)** — `VHDLPortableStaticValidator` now indexes
  constants, operation comments, ranks, and fixed censuses in one metadata
  pass; `VHDLPortableGHDL` indexes every required anchor, line count, and end
  column once per source. The same source-only control passes afterward.
  Canonical T=21/128/512 reruns retain exact byte/map/artifact/source/check
  inventories, and guarded T=29,508 accepts twice at 16,776,739 bytes/29,546
  maps before adjacent T=29,509 returns only the exact atomic limit diagnostic.
- [x] **NO REGRESSION** — changed modules and t1641 report `syntax OK`. The
  focused t1593/t1594/t1641 suite reports `All tests successful` at
  `Files=3, Tests=20`, including static mutation,
  negotiation, exact gallery, matrix review, deterministic reruns, and absent
  artifact roots. The final exact t1641 rerun passes at Files=1/Tests=5 in 43 seconds
  under the repository 4,096-MiB RAM guard. Knowledge Map, task-tree,
  relative-path, mdBook, maintained-reference, claim, containment, diff,
  staged acceptance, and all doctrine gates close before commit; no external
  runtime, public API, support, performance, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.6.2` repair activation/decomposition

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -1 --format='%h %s'` names clean
  decision-`0075` selection predecessor `0a3a2a05f`; the selected defects span
  four different implementation authorities and therefore cannot safely share
  one behavior-changing leaf.
- [x] **ADDRESSED (verified)** — `scripts/check_task_tree_integrity.pl` reports
  three trees/955 nodes after `.17.2.6.2` becomes active with five ordered
  children and `.17.2.6.2.1` alone active. Task index and bounded Memory name
  the same portable-VHDL frontier; no implementation path changes.
- [x] **NO REGRESSION** — relative-path, task-tree, live-document containment,
  Memory, diff, staged acceptance, and all doctrine gates pass. The existing
  mdBook and Knowledge Map user-facing contract remains current because this
  slice changes only ownership state, not the selected routes or product
  behavior.

## Acceptance Checklist (enforced) — `.17.2.6.1` backend-emission route selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'upstream_workload_level'
  --oneline -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm` roots the
  under-specified selector; fresh canonical probes plus exact source inspection
  disprove its one-string route. Portable SV reaches its
  source cap at `T=6,319/6,320`; portable VHDL has four fixed metadata census
  scans plus three full metadata scans per operation and cannot validate its renderer-proved `29,508` boundary in the
  selected ceiling; OSVVM replaces detailed portable maps with six whole-file
  placeholders and repeats full provider verification; native UVM accepts
  `T=22` while omitting the added expectation from generated evaluation. The
  existing catalog additionally mislabels OSVVM sources and omits native UVM's
  enforced map cap.
- [x] **ADDRESSED (verified)** — decision `0075` selects every accepted or
  earliest-authority outcome, the exact anchored upstream recipe, structural
  inventory/map/check/identifier oracles, atomicity/staging boundary, and
  nonclaims. Proposed `.17.2.6.2` durably owns five ordered repair slices before
  generator `.3`; the updated canonical architecture-scale fact,
  mdBook, task frontier, decision index, and Memory agree. Selection changes no
  emitter, validator, runtime, public API, support, performance, or capacity
  behavior.
- [x] **NO REGRESSION** — the selected doctrine tests report `All tests
  successful` at `Files=9, Tests=104`; `knowledge-map: OK` reports 1,150
  facts/6,052 questions/6,219 occurrences/133 shards; task integrity reports
  three trees/950 nodes; the claim-disposition join closes all 1,419 candidates
  with four explicit durability gaps owned by active `.17.2.6`; all 53 mdBook
  chapters test; selected relative-path, task, live-size,
  maintained-reference, Knowledge Map, and claim-doctrine tests pass. All 22
  live-document surfaces pass with zero ceiling increases: Chapter 16d stays at
  its existing 3,701-line allowance with exact 0-line/+2,044-byte book growth,
  and the existing canonical card is rewritten in place so the collection
  remains below its 80% warning threshold without changing a ceiling. Final
  diff, staged acceptance, doctrine, and artifact
  residue checks are recorded by the commit workflow.

## Acceptance Checklist (enforced) — `.17.2.6` backend-emission decomposition

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'upstream_workload_level'
  --oneline -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm` and `git log
  -S'generated_provider_sources' --oneline -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm`
  both identify foundation commit `063b990f3`. Exact source and executable
  probes show that one level-only selector cannot identify one of thirteen proved
  execution axes, while the four emitters have distinct graph/map/check
  authorities and the OSVVM/native-UVM catalog fields are incomplete or false.
- [x] **ADDRESSED (verified)** — `.17.2.6` now contains active read-only
  selection `.1`, proposed catalog/contract repair `.2`, and proposed
  generator/oracle implementation `.3`. Each acceptance boundary names its
  exact authority and unchanged-behavior scope; task index and bounded Memory
  activate only `.1`.
- [x] **NO REGRESSION** — the four canonical emitter suites report `All tests
  successful` at Files=4/Tests=30 under the repository RAM guard. The exact
  read-only reference probe returns 8/17/16/16 artifacts and 54/59/13/75 maps,
  creates none of its repository-relative artifact-root identities, and exact
  numbered-source inspection disproves the apparent duplicate-key lead. Task
  integrity, relative paths, diff checks, and all doctrines pass. No generator,
  emitter, runtime, public API, support, performance, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.6` backend-emission generation activation

- [x] **ROOT CAUSE (WHY + WHERE)** — the Knowledge Map query for the
  backend-emission scale leaf returns no canonical fact. The command
  `git log -S'backend_emission_v1' --oneline -- docs perl t` traces the selected family
  to decision commit `0516f2c66` and its catalog to foundation commit
  `063b990f3`, but finds no scale emitter generator. The four negotiated
  canonical profiles already differ in input shape, artifact graph, source-map
  and static-validator contracts, provider negotiation, and qualification
  state, so writing one implementation before reconciling them would conflate
  four independent authorities.
- [x] **ADDRESSED (verified)** — `.17.2.6` is active and owns the read-only
  four-emitter authority audit before implementation decomposition. The active
  index, bounded Memory pointer, task frontier, and mdBook name the same next
  action and unchanged-behavior boundary. The book growth is exactly authorized
  at zero files, five lines, and 348 bytes without increasing a ceiling.
- [x] **NO REGRESSION** — task integrity reports three trees/947 nodes;
  relative-path regression reports `All tests successful` at Files=1/Tests=2;
  all 53 mdBook chapters test, and the inspected 88-file/18,604-KiB
  repository-local render is removed exactly. Claim inventory reconciles
  10,678 numeric lines, 1,415 candidates, 2,043 constants, and the original 615
  constants with zero owners. All 22 live-document surfaces,
  maintained-reference authority, staged task acceptance, diff checks, and
  `[doctrine] all doctrine checks passed`. No generator, emitter, runtime, public API,
  capability/support, performance, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.5.2.7` complete checking-state family qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'final checking-state family qualification'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies clean activation commit `e744aaa60`. It deliberately left the
  implemented 32-shape family open until one independent test froze the exact
  catalog partition, whole-family determinism, hostile-caller boundary, cleanup,
  guarded high-count matrix, and parent closure.
- [x] **ADDRESSED (verified)** — `t/1635-vial-architecture-scale-checking-qualification.t`
  derives all eight axes and five levels from the common catalog, byte-compares
  independent construction/evaluation reports for every gate, rejects all eight
  references and source/report/runtime-evidence forgeries, and proves exact
  same-volume cleanup after successful and failed consumers. The task, index,
  bounded Memory, mdBook, and Knowledge Map now close `.17.2.5.2.7`, `.17.2.5.2`,
  and `.17.2.5` together while leaving `.17.2.6` proposed.
- [x] **NO REGRESSION** — the guarded default family reports `All tests successful`
  at `Files=7, Tests=36` in 166 seconds; the complete opt-in exact matrix reports
  `All tests successful` at `Files=5, Tests=27` in 593 seconds. CI inventory,
  task-tree integrity, `knowledge-map: OK`, relative paths, all 52 mdBook chapter
  tests, exact repository-local render/removal, live-document containment, staged
  acceptance, and `[doctrine] all doctrine checks passed`. No parser, IR, backend,
  runtime, capability/support, performance, capacity, or product contract changes.

## Acceptance Checklist (enforced) — `.17.2.5.2.7` final checking-state qualification activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'all 32 non-reference checking-state shapes'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies implementation commit `0f383a824`. It completes every axis leaf,
  while proposed final child `.17.2.5.2.7` still owns the whole-family partition,
  guarded matrix, report equality, cleanup, hostile-caller, nonclaim, and parent-
  closure proof.
- [x] **ADDRESSED (verified)** — `.17.2.5.2.7` alone is active from that clean
  boundary. Task index, bounded Memory, mdBook, and Knowledge Map fact agree on
  the final qualification frontier; all implementation siblings remain done.
- [x] **NO REGRESSION** — task-tree integrity, `knowledge-map: OK`, documentation-
  relative paths, all 52 mdBook chapter tests, exact repository-local book
  render/removal, live-document/maintained-reference checks with no ceiling
  increase, and `[doctrine] all doctrine checks passed`. Activation changes no
  code, test, config, generated artifact, parser, IR, evaluator, backend,
  capability/support, performance, capacity, or product behavior.

## Acceptance Checklist (enforced) — `.17.2.5.2.6` random/replay checking ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'random/replay checking is active'
  --oneline -- docs/knowledge/vial-checking-state-scale-reachability.md` identifies
  activation commit `7990c13d7`, while
  `FSM::VIAL::ArchitectureScaleCheckingState` still published only 28 shapes,
  kept `random_replay` evidence null, and had no selected random-axis evaluator.
- [x] **ADDRESSED (verified)** — the module now owns all 32 non-reference
  checking-state shapes. Its 128-choice renderer produces real referenced
  scenario/choice occurrences; the 1,024 gate generates, independently reruns,
  and strictly replays every keyed Boolean decision with byte-equal normalized
  decisions and plans. Exact 32,768 plan rejection, non-materialized 65,536
  preflight dominance, 65,537 occurrence rejection, and RAM-guarded 8,440/
  8,441 adjacent plan boundary all stop at their earliest canonical authority.
  Replay/value/order/source/report mutation and both successful and failing
  repository-volume staging paths fail closed or clean up exactly.
- [x] **NO REGRESSION** — module and new test syntax pass; default
  `t/1629`-`t/1634` report `All tests successful` at Files=6, Tests=33 in 127
  seconds; opt-in exact `t/1634` passes at Files=1, Tests=4 in 467 seconds under
  the 4,096-MiB RAM guard; CI regression-tier selection passes at Files=1,
  Tests=12. All 52 book
  chapters test, and the inspected repository-local HTML render contains 88
  files / 18,848,937 bytes before exact removal. Knowledge Map reports 1,124
  facts / 5,878 questions / 6,045 occurrences / 129 shards; the 2,865-entry
  rationale ledger reconstructs; task integrity remains three trees / 947
  nodes; `knowledge-map: OK`, relative paths, and maintained-reference
  authority pass. Staged acceptance and `[doctrine] all doctrine checks passed`
  with no parser, IR, backend, runtime, public API, capability/support,
  performance, or capacity contract change.

## Acceptance Checklist (enforced) — `.17.2.5.2.6` random/replay checking activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'random/replay child'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies clean fault implementation commit `be6878984`. It completed the
  fault ladder but deliberately left random/replay child `.17.2.5.2.6`
  proposed, so implementation still lacked a sole active owner.
- [x] **ADDRESSED (verified)** — `.17.2.5.2.6` alone is active for compact
  Boolean occurrence construction, the exact 1,024 generated/replayed gate,
  full 32,768 plan-cap outcome, opt-in 8,440/8,441 adjacent plan boundary,
  preflight-dominated 65,536 outcome, exact 65,537 occurrence-cap rejection,
  keyed value/replay identity, mutation/rerun negatives, and repository-local
  cleanup. Task index, bounded Memory, mdBook, and Knowledge Map fact identify
  the same frontier; final qualification `.17.2.5.2.7` stays proposed.
- [x] **NO REGRESSION** — task-tree integrity, `knowledge-map: OK`, documentation-
  relative paths, all 52 mdBook chapter tests, exact repository-local 88-file /
  18,841,378-byte render/removal, live-document/maintained-reference checks with exact 0-file /
  0-line / +2-byte book delta and no ceiling increase, staged task acceptance,
  and final `[doctrine] all doctrine checks passed`. No code, test, config,
  generated artifact, parser, IR, evaluator, backend, capability/support,
  performance, capacity, or product behavior changes.

## Acceptance Checklist (enforced) — `.17.2.5.2.5` fault lifecycle checking ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'fault checking ladders'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies clean activation commit `e43ecc2e5`. It granted `.17.2.5.2.5`
  sole ownership, but the public checking-state module still published only 24
  model/scoreboard/coverage shapes, kept fault evidence null, and had no
  executable activation/restoration oracle.
- [x] **ADDRESSED (verified)** — the module now owns all four fault levels.
  Exact ordinary source reaches accepted 32/1,024/4,096 declarations and the
  4,097 source returns only the complete canonical execution diagnostic at
  `/faults`. For every accepted declaration the provider-free oracle validates
  the authored target, known three-bit substitute, and one-interval lifetime,
  then streams arm/apply/expire/restore records into actual and independently
  reconstructed order/transition digests. It proves restoration to the exact
  original value and rejects armed reinjection, active overlap, substitute
  mutation, order mutation, hostile structure, source mutation, and report
  mutation. The 4,096 level closes exactly 16,384 transitions without retaining
  a report array, and common staging removes its exact repository-volume path
  after both successful and failed consumers.
- [x] **NO REGRESSION** — Perl module and test syntax report `syntax OK`.
  Focused/default checking-state regression reports `All tests successful` at
  `Files=5, Tests=29` in 97 seconds, and the opt-in exact fault sweep reports
  `Files=1, Tests=5` in 21 seconds under the 4,096-MiB RAM guard. CI inventory
  passes at `Files=1, Tests=12` with the staged test in the tracked partition.
  all 52 mdBook chapter tests, and the inspected repository-local 88-file /
  18,841,372-byte render pass before exact removal. Task integrity, relative
  paths, `knowledge-map: OK`, rationale reconstruction, and live-document
  authority accept the exact 0-file / 0-line / +612-byte book delta with no
  ceiling increase. The artifact
  census, diff checks, staged acceptance, and `[doctrine] all doctrine checks
  passed`. No existing frozen route identity changed and no parser, SemanticIR,
  bridge, ExecutionIR, backend, runtime, public API, capability/support,
  performance, or capacity behavior changed.

## Acceptance Checklist (enforced) — `.17.2.5.2.5` fault checking activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'Fault child .5 is proposed
  next' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies clean
  coverage implementation commit `4af387042`. It completed all selected
  coverage obligations but deliberately left fault child `.17.2.5.2.5`
  proposed, so fault implementation still lacked a sole active owner.
- [x] **ADDRESSED (verified)** — `.17.2.5.2.5` alone is active for the selected
  32/1,024/4,096 accepted fault sources, exact 4,097 resource rejection,
  arm/apply/expire/restoration oracle, reinjection/overlap/mutation negatives,
  deterministic rerun, and repository-local cleanup. Task index, bounded
  Memory, mdBook, and Knowledge Map fact identify the same frontier;
  random/replay and final qualification siblings stay proposed.
- [x] **NO REGRESSION** — task-tree integrity, `knowledge-map: OK`, documentation-
  relative paths, all 52 mdBook chapter tests, exact repository-local book
  render/removal, live-document/maintained-reference checks with exact 0-line
  / +2-byte book delta and no ceiling increase, staged task acceptance, and
  final `[doctrine] all doctrine checks passed`. No code, test, config,
  generated artifact, parser, IR,
  evaluator, backend, capability/support, performance, capacity, or product
  behavior changes.

## Acceptance Checklist (enforced) — `.17.2.5.2.4` packed coverage checking ladders

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'coverage checking ladders'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies clean activation commit `192945d27`. It granted coverage child
  `.17.2.5.2.4` sole ownership, but the public checking-state module still
  published only sixteen model/scoreboard shapes, kept coverage evidence null,
  and had no source-free coverpoint outcome or executable static-domain oracle.
- [x] **ADDRESSED (verified)** — the module now owns all four levels on both
  coverage axes. Exact ordinary source reaches accepted 256/8,192 coverpoints
  and 4,096/262,144/1,000,000 static entries; limit/over-limit coverpoints
  retain no oversized source and report the exact input-1 envelope diagnostic
  plus paired decision-0072 records naming the separately re-proved
  9,524/9,525 parser boundary; 1,000,001 entries return the sole canonical
  execution diagnostic at `/coverage`. The provider-free oracle reconstructs
  every authored bin and cross tuple from canonical ExecutionIR, sets one
  LSB-first bit per entry, byte-compares the independent all-hit vector,
  streams an independent authored-order identity, and proves illegal, ignore,
  bit, order, hostile-structure, source, and report mutations fail closed. The
  million case is exactly 1,999 bins plus 998,001 tuples, 62,841 source bytes,
  and 125,000 vector bytes; no tuple exists outside the authored cross domain.
- [x] **NO REGRESSION** — focused default t/1629+t/1632 reports `All tests
  successful` at `Files=2, Tests=13` in 18 seconds and opt-in t/1632 reports
  `Files=1, Tests=7` in 45 seconds under the 4,096-MiB RAM guard. The complete
  default checking-state family reports `Files=4, Tests=24` in 87 seconds.
  Perl syntax, CI inventory, mdBook test/render,
  task integrity, relative paths, Knowledge Map, rationale reconstruction,
  live-document/reference authority (exact maintained-reference delta 0 lines
  / +310 bytes with no ceiling increase), artifact census, diff checks, staged
  acceptance, and all doctrines pass; repository-local generated output is
  removed exactly. No parser, SemanticIR, bridge, ExecutionIR, backend,
  runtime, public API, capability/support, performance, or capacity behavior
  changes.

## Acceptance Checklist (enforced) — `.17.2.5.2.4` coverage checking activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Coverage child .4 is
  proposed next' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies clean
  scoreboard implementation commit `416c79473`. It completed every scoreboard
  obligation but deliberately left coverage child `.17.2.5.2.4` proposed, so
  coverage implementation still lacked a sole active owner.
- [x] **ADDRESSED (verified)** — `.17.2.5.2.4` alone is active for the selected
  reachable coverpoint and static-bin/cross-tuple source recipes, packed hit-
  vector oracle, envelope/earliest-cap outcomes, negatives, deterministic
  rerun, and repository-local cleanup. Task index, bounded Memory, mdBook, and
  Knowledge Map fact identify the same frontier; later siblings stay proposed.
- [x] **NO REGRESSION** — task-tree integrity, Knowledge Map, documentation-
  relative paths, all 52 mdBook chapter tests, exact repository-local book
  render/removal, all live-document/maintained-reference checks, staged task
  acceptance, and final doctrines pass. No code, test, config, generated
  artifact, parser, IR, evaluator, backend, capability/support, performance,
  capacity, or product behavior changes.

## Acceptance Checklist (enforced) — `.17.2.5.2.3` packed scoreboard checking ladders

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'complete-transaction packed
  FIFO oracle' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies clean
  activation predecessor `f41166cea`. It deliberately changed only continuity:
  the public checking-state module still owned only model axes, its scoreboard
  evidence compartment remained null, and no selected 32/1,024/4,096-instance
  or 4,096/262,144/1,000,000-capacity level could execute a FIFO oracle or own
  its exact adjacent rejection.
- [x] **ADDRESSED (verified)** — the public generator now owns all eight
  scoreboard shapes and authors compact ordinary VIAL. Accepted levels
  independently reproduce canonical SemanticIR, bridge, ExecutionIR, and plan
  twice, then store only a uint32 payload per selected entry, reconstruct and
  compare all six transaction fields, preserve FIFO order, reach exact
  maximum expected/actual depths, and drain both queues to zero. The oracle
  proves mismatch, at-capacity enqueue, packed-byte corruption, hostile-policy,
  source, and report rejection. One million entries use exactly 4,000,000
  packed bytes and 6,000,000 field comparisons without expanding the plan.
  Adjacent instance and capacity excesses publish only their complete earliest-
  authority diagnostics and no unavailable downstream identities.
- [x] **NO REGRESSION** — default t/1629-t/1631 report `All tests successful`
  at Files=3/Tests=17. Exact RAM-guarded t/1631 reports `All tests successful`
  at Files=1/Tests=6 and exercises every accepted qualification/limit level.
  Syntax, mdBook, Knowledge Map, task, relative-path, locality, live-document,
  rationale-ledger, residue, staged acceptance, and final doctrine evidence is
  recorded by the commit workflow. Coverage, faults, random/replay, backend,
  runtime, capability, support, performance, and capacity claims remain
  unchanged.

## Acceptance Checklist (enforced) — `.17.2.5.2.3` scoreboard checking activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Scoreboard child .3 is the next
  proposed activation' --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-
  ARCHITECTURE.md` identifies clean predecessor `48e97f656`, whose completed
  model ladder leaves scoreboard child `.17.2.5.2.3` proposed even though
  decision `0073` already selects its exact canonical source outcomes and
  bounded packed-state proof. The leaf cannot own implementation until a
  separate clean continuity slice makes it the sole active frontier.
- [x] **ADDRESSED (verified)** — `.17.2.5.2.3` alone is active for the selected
  scoreboard-instance and declared-capacity source recipes, complete canonical
  construction outcomes, complete-field packed FIFO enqueue/match/drain oracle,
  negative cases, deterministic rerun, and repository-local cleanup. Task
  index, bounded Memory, mdBook, and the existing Knowledge Map fact identify
  the same frontier; every later checking-state sibling remains proposed.
- [x] **NO REGRESSION** — task-tree integrity passes; `knowledge-map: OK`
  reports 1,124 facts / 5,877 questions / 6,044 occurrences / 129 shards;
  documentation-relative paths report `All tests successful` at `Files=1,
  Tests=2`; all 52 mdBook chapter tests, exact
  repository-local book render/removal, all live-document and maintained-
  reference checks, staged task acceptance, and final doctrines pass. No code,
  test, config, generated artifact, parser, IR, evaluator, backend, capability/
  support, performance, capacity, or product behavior changes.

## Acceptance Checklist (enforced) — `.17.2.5.2.2` packed model checking ladders

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'null model-evidence
  compartment' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` locates
  foundation commit `e392989d4`: it deliberately published zero owned shapes
  and a null model compartment, so none of the selected 32/1,024/4,096 model
  instances or 512/32,768/65,536 scalar cells had an executable state oracle,
  and neither adjacent `/models` excess had a canonical owned outcome.
- [x] **ADDRESSED (verified)** — the public generator owns exactly the eight
  model shapes and authors them as ordinary checked-AHB VIAL inside the fixed
  construction envelope. Accepted levels independently reproduce canonical
  SemanticIR/bridge/ExecutionIR/plan twice, then validate every u8 zero-to-one
  rule, synthesize one bound `accepted` occurrence per instance, initialize,
  commit, and read every packed cell, and byte-compare independently derived
  all-zero/all-one vectors. Complete hostile-state/source/report mutation and
  cleanup checks pass. The 4,097-instance and 65,537-cell sources return only
  their complete canonical `VIAL_EXECUTION_LIMIT_ERROR` at `/models`, with no
  downstream stage identity and no claim that the state oracle ran.
- [x] **NO REGRESSION** — default t/1629-t/1630 report `All tests successful`
  at Files=2/Tests=11 in 59 seconds. The exact RAM-guarded t/1630 sweep reports
  `All tests successful` at Files=1/Tests=5 in 136 seconds and exercises all
  four accepted qualification/limit levels. Syntax, mdBook, Knowledge Map,
  task, relative-path, locality, live-document, rationale-ledger, residue,
  staged acceptance, and final doctrine evidence is recorded by the commit
  workflow. No scoreboard, coverage, fault, random/replay, backend, runtime,
  capability, support, performance, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.5.2.1` checking-state foundation

- [x] **ROOT CAUSE (WHY + WHERE)** — decision `0073` requires a provider-free
  evaluator that consumes only caller-sealed canonical SemanticIR and
  ExecutionIR. `git log -S'checking_state_v1' --oneline --
  perl/FSM/VIAL/ArchitectureScaleWorkload.pm` identifies `063b990f3` as the
  catalog origin, while `rg -n
  'checking_state_v1|ArchitectureScaleChecking' perl/FSM/VIAL` found that
  shared catalog but no checking-state generator, evaluator, ownership
  boundary, or state report. Reusing
  `TraceValidator`/`ResultProducer` would be circular because they validate and
  project caller records rather than reconstruct state. Publicly owning a gate
  merely to test the plumbing would also contradict this leaf's zero-owned-level
  acceptance, and `reference_v1` is explicitly a catalog record rather than a
  generated shape.
- [x] **ADDRESSED (verified)** — new
  `FSM::VIAL::ArchitectureScaleCheckingState` exposes an empty `owned_shapes`
  projection and rejects reference, every selected/non-owned level, unknown
  axes/levels/keys, caller IR, and direct or bypassed access to its private
  candidate seam. That same-package seam accepts only ordinary VIAL text plus
  the frozen 1,326-byte checked-AHB source and derives the selected specification
  from `ArchitectureScaleWorkload`. Every build/evaluation regenerates the
  content-addressed workload and independently runs the canonical Parser,
  IAL2-via-generated/reparsed-IAL1 bridge, and public ExecutionBuilder. Exact
  identities are workload `7a125500…`, evaluation `9b674600…`, rerun
  `ceefc4f3…`, SemanticIR `00dce649…`, bridge `a4565d40…`, ExecutionIR
  `5f04ca97…`, and plan `1a3b97f4…` at 44,467 bytes. The closed report says
  `accepted_not_axis_evaluated`, reserves null model/scoreboard/coverage/fault/
  random evidence compartments, freezes the selected packed-state bounds, and
  denies axis ownership plus capability/support/performance/capacity/backend/
  runtime authority. `t/1629` proves exact construction/evaluation regeneration,
  defensive copies, hostile mutation, and repository-volume staging cleanup
  after both success and consumer failure.
- [x] **NO REGRESSION** — `scripts/run_with_ram_guard.sh -- prove -Iperl
  t/1600-vial-architecture-scale-workload-foundation.t
  t/1603-vial-architecture-scale-execution-foundation.t
  t/1629-vial-architecture-scale-checking-foundation.t` reports `All tests
  successful` at `Files=3, Tests=16`. Perl syntax, CI inventory, mdBook
  build/test plus the new runnable example, task integrity, relative paths,
  Knowledge Map generation, live-document/reference authority, diff checks,
  and staged doctrines all pass; the inspected repository-local book build and
  every content-addressed test stage are removed exactly. No parser, SemanticIR,
  bridge, ExecutionIR, result provider, backend, runtime, public product API,
  capability/support, performance, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.5.2` checking-state implementation activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Implement the selected
  canonical checking-state generator' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  activation commit `61682f345`, where `.17.2.5.2` was deliberately left as one
  proposed implementation node until proof selection completed. Clean selection
  commit `a4e45b278` now supplies decision `0073`, but one node still combines
  caller sealing, two model axes, two scoreboard axes, two coverage axes, faults,
  random/replay, high-count qualification, docs, and closure—too much behavior
  for one recoverable implementation slice.
- [x] **ADDRESSED (verified)** — `.17.2.5.2` is active only as a container and
  decomposes into seven exact children: shared foundation `.1`, model `.2`,
  scoreboard `.3`, coverage `.4`, faults `.5`, random/replay `.6`, and final
  qualification `.7`. Only `.1` is active; every behavior-bearing sibling stays
  proposed. Task index, bounded Memory, book, and maintained-reference authority
  name the same foundation-first frontier, and no implementation path changes.
- [x] **NO REGRESSION** — docs relative-path audit reports `All tests
  successful` at `Files=1, Tests=2`; task integrity reports three trees/947
  nodes; all 52 mdBook chapters test and the inspected repository-local 88-file
  render is removed exactly. All 22 live-document surfaces and the exact
  maintained-reference delta pass; the final staged driver reports `[doctrine]
  all doctrine checks passed`. No generator, parser, IR, evaluator, result,
  backend, public API, capability/support, performance, or capacity behavior
  changes.

## Acceptance Checklist (enforced) — `.17.2.5.1` checking-state proof selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Crosses enumerate only
  explicitly declared tuples' --oneline --
  docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md`
  names selection commit `0516f2c66`, whose checking-state prose requires
  explicit tuple enumeration even though the older shipped VIAL grammar has no
  tuple-list form and `SemanticBuilder`/`ExecutionBuilder` compute the static
  product of an authored cross's explicitly authored point bins. Direct source,
  plan, and limit probes also falsify the assumption that one general runtime
  path can prove all eight axes: 65,536 coverpoints cross the source envelope,
  32,768 compact random occurrences cross the plan cap, and result/backend
  machinery validates or implements a narrower profile rather than recomputing
  general state semantics.
- [x] **ADDRESSED (verified)** — decision `0073` selects every level's exact
  accepted-or-earliest-cap outcome and reconciles the stale tuple-list sentence
  with the shipped static-cross contract. It selects one caller-sealed,
  provider-free evaluator that exercises rather than allocates checking state:
  a packed million-entry scoreboard reaches depth 1,000,000 and drains to zero,
  while a million-bit coverage vector is byte-compared after one sample hits the
  complete authored static domain. Decision/index, fact card, mdBook, task/index,
  Memory, and maintained-reference authority carry the same contract and exact
  9,524/9,525 coverpoint, 8,440/8,441 random-plan, and 1,000,000/1,000,001
  coverage evidence. Temporary probes and the inspected render are absent.
- [x] **NO REGRESSION** — docs relative-path audit reports `All tests
  successful` at `Files=1, Tests=2`; all 52 mdBook chapters test and the
  repository-local render contains 88 files / 18,516 KiB before exact removal;
  `knowledge-map: OK` reports 1,124 facts / 5,875 questions / 6,042 answer
  occurrences / 129 shards. Task integrity remains three trees/940 nodes; all
  22 live-document surfaces and the exact maintained-reference delta pass; the
  final staged driver reports `[doctrine] all doctrine checks passed`. No parser,
  IR, checking service, result producer, backend, public API, support,
  performance, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.5` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — the Knowledge Map query for
  `checking_state_v1`, scoreboard capacity, coverage cross tuples, and model
  state/fault restoration returns no canonical fact, while the task tree's
  open question explicitly requires proof-method selection before either
  one-million-record level is authored. `git log -S'checking_state_v1'
  --oneline -- docs perl t` traces the contract to selection commit `0516f2c66`
  and the workload catalog to foundation commit `063b990f3`, but finds no
  checking generator; clean predecessor `6250cabad` closes execution only.
- [x] **ADDRESSED (verified)** — `.17.2.5` now decomposes into active read-only
  selection `.17.2.5.1` and proposed implementation `.17.2.5.2`. The task
  index, bounded Memory pointer, mdBook, and maintained-reference authority all
  name the same boundary; no implementation path changes.
- [x] **NO REGRESSION** — `scripts/check_task_tree_integrity.pl` reports three
  trees/940 nodes; relative-path regression reports `All tests successful` at
  `Files=1, Tests=2`; all 52 mdBook chapters test; the inspected 88-file /
  18,500-KiB repository-local render is removed exactly; all 22 live-document
  surfaces, diff checks, and the final staged doctrine gate pass.

## Acceptance Checklist (enforced) — `.17.2.4/.17.2.4.2` final execution-graph qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — the completed implementation had whole-family behavioral evidence but no exact oracle for the selection boundary it was about to claim. `git log -S'the caller-sealed generator still has an unowned frontier' --oneline -- t/1603-vial-architecture-scale-execution-foundation.t` names `6220ad8f1 …: author the unconstructible binding ladder`, whose derived-catalog check proved only `scalar(@unowned) > 0` and that each outside shape rejected. That was safe while levels were landing, but after the last source-map levels it could neither distinguish an accidentally unfinished level from a deliberate non-selected catalog profile nor prove the task's new 40-owned/25-outside statement. The first exact assertion also usefully falsified a naming assumption: the common catalog profile is `reference_v1`, not `empty_baseline`; the test failed on `bindings/reference_v1` before closure prose could preserve the wrong label.
- [x] **ADDRESSED (verified)** — `t/1603-vial-architecture-scale-execution-foundation.t` now derives the catalog and generator sets, requires exactly 40 published owned shapes, and byte-compares the complete outside set with the intended 25: one `reference_v1` profile on each of 13 axes plus gate/qualification/limit/over-limit for the three fixed scalar axes `selected_fixtures`, `selected_units`, and `selected_domains`. It then retains the prior executable proof that none of those 25 passes the caller seal and every rejection names the closed ownership boundary. This freezes “all selected levels implemented” without conflating it with “all catalog records owned.” The parent and implementation child are marked done only after that distinction and the full family pass; the mdBook and axis-outcome card publish the same closure, and `.17.2.5` remains proposed for a separate clean activation.
- [x] **NO REGRESSION** — the complete default architecture-scale family passes under `scripts/run_with_ram_guard.sh` at `Files=29, Tests=135` in 1,114 seconds with no host or 4,096-MiB descendant cutoff; the corrected focused selection rerun passes at `Files=1, Tests=3` in 13 seconds and the changed test reports syntax `OK`. All 52 mdBook chapters test and the inspected repository-local 88-file render is removed exactly. Knowledge Map history/materialization and current generation remain exact at 1,123 facts / 5,867 questions / 6,034 answer occurrences / 128 shards; task integrity, relative paths, all 22 live-document surfaces, maintained-reference authority, rationale reconstruction, project-local artifact census, staged acceptance, and all doctrines pass. Per the CI policy, this important family boundary runs its complete 29-file domain suite but not unrelated full CI, and no push occurs. No public capability, support, performance, or capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` unconstructible source-map ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — the source-map axis still owned only `gate_candidate_v1`; `git log -S'source_map_records => [qw(gate_candidate_v1)]' --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` identifies `387bbdf56 …: reach the execution-type qualification authority` as the exact `%OWNED_LEVELS` state from which these final three selected levels remained outside the caller-sealed generator. Decision `0072` already established why ordinary construction cannot reach them: one genuine reset per requested map above the checked-AHB route's 17 fixed maps produces 3,670,808 / 14,000,792 / 14,000,806 VIAL bytes at 262,144 / 1,000,000 / 1,000,001 maps, so input 1 crosses the 1,114,112-byte fixture envelope before any semantic, bridge, or execution cap. Focused execution then found a second validation-path defect rather than masking it: the rejected workload intentionally retains `inputs => []`, but `_validated_construction` assumed every checked-AHB shape retained exactly one `hial_source` input and died with `construction must contain exactly one hial_source input` before it could validate evaluation or build refusal.
- [x] **ADDRESSED (verified)** — `%UNCONSTRUCTIBLE` and `%OWNED_LEVELS` now carry all three map levels with input index 1, the unchanged one-million declared cap, and the measured 46,294/46,295 route boundary at the 16,777,216-byte serialized-plan cap `/plan`. Construction requires the one exact `VIAL_SCALE_INPUT_ERROR`, retains the catalog-derived specification but neither oversized input nor a workload identity, and fails closed if the envelope ever admits a selected level. Canonical validation reconstructs the exact generic source-free envelope failure from minimal deterministic inputs, then byte-compares it with the returned record; the real checked-AHB text remains constructor-time authority without being retained. Evaluation reports `envelope_unconstructible` / `not_constructed`, no metrics or stage identity, and paired `VIAL_SCALE_LIMIT_INTERACTION` / `VIAL_SCALE_ROUTE_BOUNDARY` records routed to `.17.4`; raw build, mutated records, absent checked source, and unknown levels fail closed. `t/1607` freezes every render byte count, SHA-256 identity, genuine reset count, exact diagnostic, rerun, record, nonclaim, refusal, selected ownership, and opt-in whole-route boundary. A regression attempt that equated selected ownership with the complete 65-shape workload catalog was rejected: the correct projection is 40 implemented selected shapes plus 25 deliberately non-selected fail-closed shapes, now recorded in rationale and task evidence.
- [x] **NO REGRESSION** — module and test syntax report `OK`; default `t/1607` passes at `Files=1, Tests=8`, its opt-in exact boundary proof passes at `Files=1, Tests=8` in 40 seconds, and the guarded 13-file ownership/axis matrix passes at `Files=13, Tests=68` in 304 seconds. The history verifier and `t/1568` prove exact two-card partition and 47-key answer parity; Knowledge Map reports 1,123 facts / 5,867 questions / 6,034 occurrences / 128 shards. The runnable book example prints `book example OK`, all 52 chapters test, and the inspected repository-local render contains 88 files / 18,500 KiB before exact removal. Task integrity remains three trees / 938 nodes; relative paths pass at `Files=1, Tests=2`; the 2,859-entry rationale ledger reconstructs; and all 22 live-document surfaces accept the fresh 0-file / +56-line / +2,630-byte book authority with zero ceiling increase. The artifact census finds only provider-owned OSVVM validated-result logs under the project-local cache, which are retained rather than misclassified as disposable output. Staged `TASK_ACCEPTANCE.md` and `scripts/check_doctrines.sh` pass. Per the CI policy, this ordinary slice runs the focused and impacted matrices rather than repeating full CI; no push occurs. No public capability, support, performance, or capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` Knowledge Map card partition

- [x] **ROOT CAUSE (WHY + WHERE)** — four ladder slices had grown `docs/knowledge/vial-execution-scale-reachability.md` to 383 lines / 26,208 bytes, 78.5% of its 32,768-byte per-card bound, even after two narration-to-signpost compressions. `git log -S'partition it at a stable topic boundary' --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` returns `6220ad8f1`, identifying the binding-ladder slice where compression stopped being a safe continuation strategy and the partition became an explicit prerequisite. The pending source-map ladder needs new question-shaped facts, so another compression would discard useful retrieval detail or immediately recreate the same pressure. `git show 5514e692c:docs/knowledge/vial-execution-scale-reachability.md` pins that complete pre-partition source at SHA-256 `44760f9a4fa3a6ea4c44def18b73eb7ec6cc1344e9b9bd4593663b2bb71ef04b`; its 47 answer keys cover two stable topics already named by the owning Open Question: route/gate construction and per-axis ladder outcomes.
- [x] **ADDRESSED (verified)** — the exact source now has a version-object descriptor and `scripts/check_knowledge_card_history.pl` reconstructs it deterministically into the original `vial-execution-scale-reachability` route/gate card (11 answers; 70 lines / 4,250 bytes) and new `vial-execution-scale-axis-outcomes` card (36 answers; 132 lines / 8,973 bytes). The verifier proves the source dimensions/digest, descriptor fields, byte-equal stable partitions, 47-key answer-set equality, no duplicate replacement answer, bounded dimensions, exact-history retrieval, and current task-tree/mdBook routing. Its comparison API now takes explicit family paths, fixing the latent assumption that every non-IAL2 replacement belonged to VHDL before VIAL became a second partitioned family. `t/1568-knowledge-card-history.t` freezes the new 13-card materialization count and VIAL outcome-card presence. The stale blocked routing is gone; `.17.2.4.2` remains active for source-map implementation.
- [x] **NO REGRESSION** — focused `t/1568` reports `All tests successful` at `Files=1, Tests=3`; the standalone history verifier proves exact sources, stable partitions, answer-set equality, boundedness, and current routing; and Knowledge Map generation/check reports 1,123 facts / 5,867 unique questions / 6,034 answer occurrences / 128 bounded shards, preserving both question and occurrence counts. Relative paths pass at `Files=1, Tests=2`; task integrity remains three trees / 938 nodes; live containment accepts all 22 surfaces with zero ceiling increases. All 52 mdBook chapters test and the unchanged user-facing book renders 88 files / 18,488 KiB before exact removal. Perl syntax, diff, staged acceptance, and the complete doctrine gate pass; the exact preview and book render are absent. No generator, parser, bridge, binder, plan, backend, product, support, performance, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` unconstructible execution-type limits

- [x] **ROOT CAUSE (WHY + WHERE)** — the execution-type `limit_v1` and `over_limit_v1` levels were the last two direct-IAL1 type shapes outside the caller-sealed generator. History separates the three mechanisms: `git log -S'_render_type_hial' --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` names `de9d50a5f …: generate execution type gate` for the one-input/one-type/one-endpoint renderer; `git log -S'MAX_SINGLE_INPUT_BYTES' --oneline -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm` names `063b990f3 …: build deterministic workload foundation` for the 1,114,112-byte per-input envelope; and `git log -S'execution_types => 65_536' --oneline -- perl/FSM/Support/VIALExecutionContract.pm` names `44dbecd1a …: implement private VIAL execution plan` for the unreachable declared cap. Re-derivation from the renderer proves that 65,536 types require 2,413,815 HIAL bytes and 8,246,830 VIAL bytes, while 65,537 require 2,413,852 and 8,246,956. Every source contains exactly one genuine HIAL input, VIAL type declaration, and bound endpoint per type. The 512→1,024 HIAL delta is exactly 17,945 bytes, confirming linear declaration growth; neither public grammar has a declaration-repetition form. The input-0 HIAL source therefore crosses the fixture envelope before the semantic, bridge, or plan stages, while the already-proved whole-route boundary remains 1,043 accepted and 1,044 rejected by the 16,777,216-byte serialized bridge-manifest cap at `/`.
- [x] **ADDRESSED (verified)** — `%UNCONSTRUCTIBLE` now declares both levels with their input index, unchanged 65,536 declared cap, and measured 1,043/1,044 route boundary, and `%OWNED_LEVELS` admits them without widening the envelope or changing any product cap. Construction requires the workload constructor's one exact `VIAL_SCALE_INPUT_ERROR`, `input 0 exceeds the bounded construction envelope`, at `/inputs/0/content`; retains the requested specification but no oversized source or workload identity; and fails closed if the envelope ever admits either shape. Evaluation reports `envelope_unconstructible` / `not_constructed`, no metrics or stage identity, and the paired `VIAL_SCALE_LIMIT_INTERACTION` / `VIAL_SCALE_ROUTE_BOUNDARY` records decision `0072` requires, both routed to `.17.4`; raw build refuses because no source was admitted. `t/1627-vial-architecture-scale-execution-type-qualification.t` re-derives every byte and declaration count, independently reconstructs each rejection, checks all records and nonclaims, forges the construction to prove canonical regeneration rejects it, and retains the opt-in whole-route boundary proof. The mdBook and Knowledge Map card publish the same construction facts without promoting capacity.
- [x] **NO REGRESSION** — the focused type/binding/map set reports `All tests successful` at `Files=3, Tests=17` in 24 seconds; the opt-in exact 1,043/1,044 whole-route proof reports `Files=1, Tests=7` in 31 seconds; and the guarded architecture-scale family reports `Files=29, Tests=132` in 1,107 seconds under the repository's 4,096-MiB descendant cutoff. `perl -Iperl -c` reports `syntax OK` for the changed module and test. The new mdBook example executes directly; `mdbook test docs/book`, the repository-local 88-file / 18,488-KiB render, and `scripts/check_docs_relative_paths.sh` pass, after which the exact render is removed with no residue. `knowledge-map: OK` covers 1,122 facts / 5,867 questions / 6,034 answer occurrences / 128 bounded shards; the reachability card remains below its 80% warning milestone at 26,208 bytes pending its separately routed pre-source-map partition; live-document containment accepts the fresh book authority with no ceiling increase; and staged `TASK_ACCEPTANCE.md` plus `scripts/check_doctrines.sh` pass. The artifact census finds no VIAL scale residue; provider-owned OSVVM validation logs under the project-local cache are retained because they are source-provider data, not disposable output. No public capability, support, performance, or capacity claim changed.

## Acceptance Checklist (enforced) — `.17.2.4.2` end-to-end route-boundary evidence

- [x] **ROOT CAUSE (WHY + WHERE)** — a signoff review of this ladder's own claims found three defects, all of the same kind: a published number ahead of its evidence. First, decision `0072` clause 5 requires each route boundary to be proved through the canonical route, and two of the three were not. `git log -S'_test_direct_ial1_bridge' --oneline -- t/1627-vial-architecture-scale-execution-type-qualification.t` names the commit that introduced the bindings and execution-type boundary probes, and both stopped at `FSM::HIAL::VIALBridge::Builder->build_ial1` — a bridge that accepts is not yet a route that accepts, because the public binder and the 16-MiB serialized-plan cap still run after it. Second, the source-map boundary of 46,294 was published in decision `0072` and the mdBook with no test behind it at all. Third, and worst, the `Current Frontier` section stated two different source-map boundaries four lines apart: `65,553 source maps at the 65,536 expanded-action semantic cap`, inferred before measurement, and `46,294`, measured after — and the `.17.2.4.3` activation verification-log row presented that same inference as a measured product boundary.
- [x] **ADDRESSED (verified)** — every published boundary is now a whole-route claim with a test behind it. `t/1628` and `t/1627` carry their accepted counts past the bridge through the public binder to a real plan, and `t/1607` gains the source-map boundary proof it never had: 2,054 bindings with 2,048 events in a 2,664,611-byte plan, 1,043 execution types with 1,045 bindings in a 1,493,527-byte plan, and 46,294 source-map records in a 16,777,026-byte plan, each rejecting one past it at its own named cap and path. The bindings proof enters the caller-sealed scale binder from inside the generator package, which is the same seal `t/1603` proves a direct caller cannot pass. The self-contradicting frontier paragraph now carries the measured 46,294 alone, and the activation log row is corrected in place to say the 65,553 figure was an inference from the expanded-action cap that the later selection measured and replaced — corrected rather than left standing, because it presented an inference as a measurement. The mdBook table and the fact card now state the accepted plan bytes and say outright that a boundary is carried through semantic, bridge, and binder rather than proved at one stage.
- [x] **NO REGRESSION** — the opt-in boundary proofs report `All tests successful` at `Files=3, Tests=15` in 85 seconds under `FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh`, and the same three files report `All tests successful` at `Files=3, Tests=15` in 25 seconds in default mode, so the added evidence stays opt-in. The complete guarded architecture-scale family passes at `Files=29, Tests=130` in 1,162 seconds. All 52 mdBook chapters test and the repository-local 88-file / 18,754,435-byte build renders the corrected table before exact removal; `knowledge-map: OK` covers 1,122 facts / 5,867 questions / 128 bounded shards with the card at 25,926 bytes / 79.1%; `scripts/check_live_document_size.sh` reports all invariants holding across 22 surfaces with the maintained-reference authority accepting exactly 0 files / +3 lines / +325 bytes; and staged `scripts/check_doctrines.sh` ends with all doctrines passing. No product behavior changed in this slice: it adds evidence and corrects claims. No public capability, support, performance, or capacity claim changed.

## Acceptance Checklist (enforced) — `.17.2.4.2` unconstructible binding ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — the binding axis has no level between its 2,048-binding gate and its 65,536-binding declared cap that any source can express. `git log -S'my $MAX_SINGLE_INPUT_BYTES' --oneline -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm` names `063b990f3 …: build deterministic workload foundation` as the commit that introduced the 1,114,112-byte bounded construction envelope, and `_render_hial` is the locus: it authors one genuine `(event bridge_event_XXXXXXXX predicate sample scale_input)` record per binding above the fixed six, so the direct-IAL1 source is 1,933,429 bytes at 32,768 bindings, 3,866,741 at 65,536, and 3,866,800 at 65,537, each rejected by the workload constructor at `/inputs/0/content` before any product stage runs. The `repeat` escape that rescued the fiber and total-operation ladders does not apply: `repeat` repeats actions, an event is a declaration, and neither the public `.vial` nor the public `.isf` grammar has a declaration-repetition form, which the growth measurement confirms — 2,048 bindings render 120,949 bytes and 4,096 render 241,781, almost exactly double. A canonical binary search then measured what the route does reach: 2,054 bindings accepted with the manifest holding exactly 2,048 events, and 2,055 rejected by `events count 2049 exceeds limit 2048` at `/events`.
- [x] **ADDRESSED (verified)** — decision `0072` is implemented for this axis. One `%UNCONSTRUCTIBLE` declaration carries each axis's levels, envelope input index, declared cap, and measured route boundary; `construct` owns the three levels, requires the constructor's exact `VIAL_SCALE_INPUT_ERROR` and fails closed if the envelope ever accepts one, and returns the rejected record with the specification it cannot derive for itself; `_validated_construction` accepts a rejected construction only for a declared unconstructible shape and still re-derives it canonically; `build` refuses because there is no admitted source; and `evaluate` reports `envelope_unconstructible` / `not_constructed` with no metrics, no workload/SemanticIR/bridge/plan identity, the exact construction diagnostic, and both records decision `0072` clause 3 requires — a `VIAL_SCALE_LIMIT_INTERACTION` stating in as many words that the decider is a fixture bound and not a product limit, and a new `VIAL_SCALE_ROUTE_BOUNDARY` giving the measured 2,054/2,055 alternative against the declared 65,536 cap. Both route to `.17.4`. The rejected record retains no oversized source at all, which the test asserts. New `t/1628-vial-architecture-scale-execution-binding-limits.t` freezes the byte counts, the linear growth, the exact rejection, both records, the refusals, and — behind `FSMGEN_VIAL_SCALE_EXACT` — the 2,054/2,055 boundary through two real canonical bridges. `t/1603` and `t/1605` were the last two files still restating the unowned set as a literal list; both now derive it from `owned_shapes`, completing that sweep across the family.
- [x] **NO REGRESSION** — `scripts/run_with_ram_guard.sh -- prove -Iperl t/1603… t/1605… t/1628…` reports `All tests successful` at `Files=3, Tests=13` in 16 seconds, and the opt-in boundary proof reports `All tests successful` at `Files=1, Tests=5` in 6 seconds. The complete guarded architecture-scale family passes at `Files=29, Tests=129` in 1,113 seconds. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` reports `syntax OK`, all 52 mdBook chapters test and the repository-local 88-file / 18,752,420-byte build renders the new section before exact removal, the new book example runs verbatim and prints `book snippet OK`, `knowledge-map: OK` covers 1,122 facts / 5,867 questions / 128 bounded shards, the maintained-reference authority accepts exactly 0 files / +51 lines / +2,405 bytes, and staged `scripts/check_doctrines.sh` ends with all doctrines passing. The `vial-execution-scale-reachability` card was compressed to 25,719 bytes / 78.5% to stay under its per-file warning milestone, and the Open Questions now route its partitioning before the source-map ladder lands. No public capability, support, performance, or capacity claim changed; a measured route boundary is reported as measured and a fixture bound is never reported as a product limit.

## Acceptance Checklist (enforced) — `.17.2.4.3` unreachable-cap selection

- [x] **ROOT CAUSE (WHY + WHERE)** — decision `0061` predicted a product cap for every remaining `bindings`, `execution_types`, and `source_map_records` level, and measurement contradicts all six. History pins the two independent origins: `git log -S'MAX_SINGLE_INPUT_BYTES' --oneline -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm` names `063b990f3 …: build deterministic workload foundation` for the 1,114,112-byte construction envelope, while `git log -S"bindings => 65_536" --oneline -- perl/FSM/Support/VIALExecutionContract.pm` names `44dbecd1a …: implement private VIAL execution plan` and `git log -S"events => 2048" --oneline -- perl/FSM/Support/HIALVIALBridgeContract.pm` names `51434a2ae …: implement review-routed bridge manifest` for the two cap tables that disagree. Real construction shows the envelope decides every time, at `/inputs/0/content`: 1,933,429 / 3,866,741 / 3,866,800 HIAL bytes for bindings at 32,768 / 65,536 / 65,537, 2,413,815 for 65,536 types, and 3,670,808 / 14,000,792 / 14,000,806 VIAL bytes for maps at 262,144 / 1,000,000 / 1,000,001. No compact form can rescue them the way `repeat` rescued fibers and operations, because `repeat` repeats actions while events, types, and endpoints are declarations with no repetition form in either public grammar. Canonical binary searches then measured each axis's real boundary — 2,054 bindings, 1,043 execution types, 46,294 source-map records — against declared execution caps of 65,536 / 65,536 / 1,000,000, so three declared caps are unreachable by 32x, 63x, and 22x through every shipped route.
- [x] **ADDRESSED (verified)** — decision `0072` selects the treatment and states the rejected alternatives. Levels stay, because they are the execution contract's own declared caps and "no shipped route reaches this cap" is a result rather than a level to edit; the envelope stays, because it is only the first obstacle — 65,536 bindings already need 1,442,356 VIAL bytes against the product's own 1,048,576-byte parser cap — so raising it would trade a fixture bound for a product bound and still miss the declared cap. Every unreachable level must instead report three numbers: its declared cap, the earliest cap that actually decides with its exact diagnostic and path, and its measured route boundary, under an `envelope_unconstructible` / `not_constructed` outcome carrying paired `VIAL_SCALE_LIMIT_INTERACTION` and `VIAL_SCALE_ROUTE_BOUNDARY` records routed to `.17.4`, which also inherits the cross-layer cap inconsistency. Each measured boundary is exact and rejects one past it at a named path: 2,055 bindings at bridge `events` 2,048 at `/events`, 1,044 types at the 16,777,216-byte serialized manifest at `/`, and 46,295 maps at the 16,777,216-byte plan cap at `/plan` after a 16,777,026-byte accepted plan. `.17.2.4.3` is done, `.17.2.4.2` is unblocked as the sole implementation owner, and the decision index, mdBook, fact card, task tree, and Memory carry the same numbers.
- [x] **NO REGRESSION** — this slice changes documentation and one declaration registry, so its gates are the documentation and doctrine oracles rather than a product suite. `scripts/check_docs_relative_paths.sh` reports `Result: PASS` at `Files=1, Tests=2`; `knowledge-map: OK` covers 1,122 facts / 5,865 questions / 6,032 answer occurrences / 128 bounded shards; the `vial-execution-scale-reachability` card crossed its 80% per-file warning milestone at 86.4% while this ladder was written, so its three ladder narrations were compressed to signposts that route to decision `0072`, decision `0061` clause 8, and the mdBook, returning the card to 25,106 bytes / 76.6% without dropping a recorded fact or a question key — `scripts/check_live_document_size.sh` reports all invariants holding across 22 surfaces; all 52 mdBook chapters test and the repository-local 88-file / 18,739,789-byte build renders the new section before exact removal; `scripts/check_task_tree_integrity.pl` reports all invariants holding at trees=3 / nodes=938; the maintained-reference authority accepts exactly 0 files / +52 lines / +3,386 bytes; and staged `scripts/check_doctrines.sh` ends with all doctrines passing. No generator, parser, bridge, binder, plan, backend, runtime, capability, support, performance, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` execution-type qualification level

- [x] **ROOT CAUSE (WHY + WHERE)** — the `execution_types` `qualification_candidate_v1` level was unowned, and probing it exposed a second, larger defect in the route that would own it. `git log -S'my $semantic_ir = FSM::VIAL::Parser->parse_source({' --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` names `bfd85ade9 …: establish sealed execution binding gate` as the commit that introduced the direct-IAL1 branch of `_canonical_inputs`, and that branch is the locus: it built the canonical HIAL bridge *before* parsing its VIAL source, while decision `0061` clause 4 declares the order ordinary VIAL source and SemanticIR, then canonical HIAL bridge, then execution plan — the order the checked-AHB branch already documents and follows. The consequence is not cosmetic. A first probe against the uncorrected order reported `HIAL_VIAL_BRIDGE_LIMIT_ERROR`, `types count 8192 exceeds limit 4096`, at `/types`; with the order corrected the same level is rejected by the ordinary parser's own `VIAL_LIMIT_ERROR`, `package section 'types' exceeds 4096 declarations`, at `/packages/0/types`. The slice would therefore have frozen the wrong authority for this level. A binary search over the same renderer and canonical bridge then measured the route's real boundary: 1,043 types accept with 1,043 manifest types and 1,045 endpoints, and 1,044 returns `serialized manifest exceeds 16777216 bytes` at `/` — so neither the 4,096-type nor the 4,096-endpoint bridge cap bounds this axis, the 16-MiB serialized-manifest cap does.
- [x] **ADDRESSED (verified)** — `_canonical_inputs` now evaluates the direct-IAL1 route in the declared stage order and returns a structured `bridge_rejection` instead of confessing, so a bridge-stage rejection is reported from its own stage rather than raised from behind a later one. The qualification level is owned: 293,894 HIAL bytes / `335b9eb1…`, 1,023,293 VIAL bytes / `c0c8a2cf…`, workload `746705c6…`, authoring exactly 8,192 `(type width_XXXXXXXX_t …)` declarations each bound by one public endpoint. The source is inside the 1,048,576-byte parser source cap, so what rejects is a declaration cap and not a byte cap: `build` and `evaluate` both return exactly one `VIAL_LIMIT_ERROR` at `/packages/0/types` with no partial `execution_ir` or `plan`, the evaluation claims neither SemanticIR nor bridge identity because no bridge is built behind the rejection, and it records one `VIAL_SCALE_LIMIT_INTERACTION` at `/requested_counts/execution_types` routed to `.17.4` naming both the 4,096-declaration cap that decides and the measured 1,043-type route boundary. New `t/1627-vial-architecture-scale-execution-type-qualification.t` freezes the level, the stage-order authority, and — behind `FSMGEN_VIAL_SCALE_EXACT` — the exact 1,043/1,044 boundary through the same canonical bridge. The slice also repairs the recurring source of that churn: owning a level used to break every sibling test that restated the unowned set as a literal list, which happened four times in this ladder alone. The owned frontier now lives in one `%OWNED_LEVELS` declaration that `construct` gates on and a new `owned_shapes` accessor publishes, and all nine sibling tests derive the still-unowned boundary as the catalog minus that frontier — 32 owned and 33 unowned of 65 catalog shapes today — so each proves the boundary without naming a level, and the next level to land cannot make them stale.
- [x] **NO REGRESSION** — `scripts/run_with_ram_guard.sh -- prove -Iperl t/1603-vial-architecture-scale-execution-foundation.t t/1606-vial-architecture-scale-execution-types.t t/1627-vial-architecture-scale-execution-type-qualification.t` reports `All tests successful` at `Files=3, Tests=12` in 43 seconds, covering both routes that share the corrected stage order, and the opt-in boundary proof reports `All tests successful` at `Files=1, Tests=5` in 22 seconds. The nine tests converted to the derived frontier pass in two guarded runs at `Files=6, Tests=27` in 214 seconds and `Files=4, Tests=21` in 77 seconds. The complete guarded architecture-scale family passes at `Files=28, Tests=124` in 1,187 seconds. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` reports `syntax OK`, all 52 mdBook chapters test and the repository-local 88-file / 18,721,755-byte build renders the new section before exact removal, the new book example runs verbatim and prints `book snippet OK`, `knowledge-map: OK` covers 1,122 facts / 5,860 questions / 128 bounded shards, the maintained-reference authority accepts exactly 0 files / +63 lines / +3,206 bytes, and staged `scripts/check_doctrines.sh` ends with all doctrines passing. No public capability, support, performance, or capacity claim changed; a measured route boundary is reported as measured, never as supported capacity.

## Acceptance Checklist (enforced) — `.17.2.4.2` total-operation limit ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — the `operations_total` `limit_v1`/`over_limit_v1` levels were carried forward with a cost note that the total-fiber slice had already invalidated, and direct probes replaced it with measurement. `git log -S'total-operation gate is not divisible by its scenario fanout' --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` names `0f9d27611 …: generate execution topology gates` as the commit that fixed the literal 32-scenario fanout, and that renderer is the locus: rendering 1,000,001 raises `total-operation gate is not divisible by its scenario fanout` at `perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm line 704.`, while 1,000,000 renders 14,003,075 bytes against the parser's 1,048,576-byte `MAX_SOURCE_BYTES`. A binary search over the same renderer pins the literal saturation at exactly 74,656 fanned-out operations (1,048,227 bytes, next 74,688 at 1,048,675) and 74,824 single-scenario resets (1,048,565 bytes, next 74,825 at 1,048,579) — correcting the "74,900" figure this file previously carried. The second, larger cause is execution cost, and it was measured rather than reasoned: a graph-stage probe under `scripts/run_with_ram_guard.sh` reports resident 436 MiB at 65,536 operations, 1,442 MiB at 262,144, 2,692 MiB at 524,288, and 3,977 MiB at 786,432 — about 5.0 KiB per operation — and plan serialization peaks at 2,116 MiB for the same 65,536 operations, so 1,000,000 needs roughly 4.9 GiB of graph and roughly 32 GiB of plan state against the 4,096-MiB descendant cutoff decision `0056` selects. Both selected levels trip that cutoff during graph construction at 4,276 and 4,299 MiB.
- [x] **ADDRESSED (verified)** — both levels are now authored with the ordinary shipped `(repeat COUNT action)` form through `_total_operation_repeat_recipe`, shared by the renderer and the oracle: 32 scenarios each holding one `(repeat 31249 (reset bus 1))`, with any remainder spread one operation at a time over the trailing scenarios. `limit_v1` is 4,003 bytes / `1b7b67a8…`, workload `d9c07156…`, SemanticIR `84b4e5a0…` with 32 action counts of exactly 31,250; `over_limit_v1` is 4,003 bytes / `ee4aca00…`, workload `3aaec35c…`, SemanticIR `f43e81e5…` with 31 counts of 31,250 and one of 31,251; both keep the checked-AHB bridge at `a4565d40…`. Proof method is then selected per level. `over_limit_v1` is proved by a real run — measured at 11 seconds and a 5,216-MiB peak descendant RSS, so it is opt-in behind `FSMGEN_VIAL_SCALE_EXACT` at `--process-max-rss-mb 6144` — and returns the one exact `VIAL_EXECUTION_LIMIT_ERROR`, `expanded_operations_total exceeds the limit 1000000`, at `/operation_graph/operations` with **no** discrepancy, because that cap is its own. `limit_v1` applies decision `0061` clause 8 instead of spending roughly 32 GiB to reach an answer its own 65,536-operation witness already gives: `evaluate` reports `preflight_dominated`/`not_materialized`, claims no SemanticIR, bridge, or plan identity, and records one `VIAL_SCALE_LIMIT_INTERACTION` plus one new `VIAL_SCALE_PREFLIGHT_DOMINANCE` at `/requested_counts/operations_total`, both routed to `.17.4`; `build` refuses it outright rather than starting a run the selected envelope cannot finish. New `t/1626-vial-architecture-scale-execution-total-operation-limit.t` freezes the literal saturation points, the compact recipe, both identities, the preflight record, and the opt-in excess proof; `t/1619`, `t/1621`, and `t/1622` advance their boundary assertions to the still-unowned binding, type, and source-map levels.
- [x] **NO REGRESSION** — `scripts/run_with_ram_guard.sh -- prove -Iperl t/1619… t/1621… t/1622… t/1626…` reports `All tests successful` at `Files=4, Tests=20` in 128 seconds, and the opt-in proof `FSMGEN_VIAL_SCALE_EXACT=1 scripts/run_with_ram_guard.sh --process-max-rss-mb 6144 -- prove -Iperl t/1626…` reports `All tests successful` at `Files=1, Tests=7` in 11 seconds. The complete guarded architecture-scale family plus three adjacent composition-IR files pass at `Files=30, Tests=123` in 1,151 seconds. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` reports `syntax OK`, all 52 mdBook chapters test and the repository-local 88-file / 18,707,187-byte build renders the new section before exact removal, the new book example runs verbatim and prints `book snippet OK`, `knowledge-map: OK` covers 1,122 facts / 5,856 questions / 128 bounded shards, the maintained-reference authority accepts exactly 0 files / +84 lines / +4,368 bytes, and staged `scripts/check_doctrines.sh` ends with all doctrines passing. No public capability, support, performance, or capacity claim changed; a reached structural cap is reported as reached, never as supported capacity.

## Acceptance Checklist (enforced) — `.17.2.4.2` total-fiber limit ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — the `fibers_total` `limit_v1`/`over_limit_v1` levels could not be owned with the recipe the axis already used, and direct probes showed why rather than inference. `git log -S'_total_fiber_actions' --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` names `df04475b4 …: generate execution fiber gates` as the commit that introduced the literal one-record-per-fiber recipe, and `git log -S'MAX_SINGLE_INPUT_BYTES' --oneline -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm` names `063b990f3 …: build deterministic workload foundation` as the commit that bounded the shared constructor. Those two mechanisms are the locus. `_render_ahb_vial('fibers_total', 65_536)` renders 3,047,364 bytes; the ordinary parser returns only `Error [VIAL_LIMIT_ERROR] … /: source exceeds the 1048576-byte limit` against `MAX_SOURCE_BYTES` at `perl/FSM/VIAL/Parser.pm:12`, and `construct` does not even reach the product — it returns `VIAL_SCALE_INPUT_ERROR`, `input 1 exceeds the bounded construction envelope`, at `/inputs/1/content` against the 1,114,112-byte `$MAX_SINGLE_INPUT_BYTES` at `perl/FSM/VIAL/ArchitectureScaleWorkload.pm:27`. A binary search over the same renderer pins the literal form's saturation exactly at 22,536 fibers (1,048,544 bytes) with 22,537 at 1,048,590, so the literal recipe falls short of the axis's own cap by a factor of three, not by a margin.
- [x] **ADDRESSED (verified)** — the two levels are now authored with the ordinary shipped `(repeat COUNT action)` form through `_total_fiber_repeat_recipe`, shared by the renderer and the block arithmetic so no level restates literals: two scenarios, each repeating one `parallel all` group of 31 fibers plus one trailing group when the count does not divide evenly. `limit_v1` is 3,199 bytes / `56d8401f…`, SemanticIR `1fece443…` with expanded action counts `33,825/33,825`, unchanged bridge `a4565d40…`, and is rejected only by the one exact `VIAL_EXECUTION_LIMIT_ERROR`, `serialized_plan_bytes exceeds the limit 16777216`, at `/plan` — so it clears the structural fiber check and the axis's own 65,536 cap is genuinely reached — recording one `VIAL_SCALE_LIMIT_INTERACTION` at `/requested_counts/fibers_total` routed to `.17.4`. `over_limit_v1` is 4,270 bytes / `d7423970…`, SemanticIR `d4c73a6f…` with `33,793/33,858`, same bridge, and is rejected by `total_fibers exceeds the limit 65536` at `/operation_graph/fibers` with **no** discrepancy, because that cap is its own. This corrected a prediction: the two levels answer to different authorities purely through cap order, and neither exposes a partial `execution_ir` or `plan`. New `t/1625-vial-architecture-scale-execution-total-fiber-limit.t` freezes both levels, the literal-form saturation point, and the authority separation; `t/1605`, `t/1623`, and `t/1624` advance their boundary assertions to the still-unowned binding, type, and source-map levels.
- [x] **NO REGRESSION** — `scripts/run_with_ram_guard.sh -- prove -Iperl t/1604-vial-architecture-scale-execution-topology.t t/1605-vial-architecture-scale-execution-fibers.t t/1623-vial-architecture-scale-execution-fiber-qualification.t t/1624-vial-architecture-scale-execution-live-fiber-limit.t t/1625-vial-architecture-scale-execution-total-fiber-limit.t` reports `All tests successful` at `Files=5, Tests=24` in 118 seconds, covering both fiber axes from gate to over-limit. The adjacent generator surface is unaffected: `scripts/run_with_ram_guard.sh -- prove -Iperl t/1603… t/1606… t/1607… t/1616… t/1618… t/1619… t/1622…` reports `All tests successful` at `Files=7, Tests=28` in 132 seconds. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` reports `syntax OK`, `mdbook build docs/book` and `mdbook test` complete with only the pre-existing search-index size warning, the new book example runs verbatim and prints `book example ok`, `knowledge-map: OK` covers 1,122 facts / 5,850 questions / 128 bounded shards, and staged `scripts/check_doctrines.sh` ends with all doctrines passing. No public capability, support, performance, or capacity claim changed; a reached structural cap is reported as reached, never as supported capacity.

## Acceptance Checklist (enforced) — `.17.2.4.2` live-fiber limit ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — `docs/knowledge/vial-execution-scale-reachability.md` asserted that "scenarios and simultaneously live fibers reach their exact 4,096 and 16,384 limits" while `simultaneously_live_fibers` `limit_v1` was still unowned by the caller-sealed generator, so the claim was a prediction standing in a live retrieval surface with no level able to prove it. `git log -S'simultaneously live fibers reach their exact' --oneline -- docs/knowledge/vial-execution-scale-reachability.md` dates the claim; `grep -n 'simultaneous_live_fibers' perl/FSM/Support/VIALExecutionContract.pm perl/FSM/VIAL/ExecutionBuilder.pm` shows the cap it referred to is real — 16,384, enforced at `ExecutionBuilder.pm:1018` — but nothing exercised it. A first repair attempt also proved the need to execute rather than reason: an edit anchored on `if ($axis eq 'scenarios') {`, a string present in both `_expected_rejection_diagnostics` and `_render_ahb_vial`, landed in the renderer and made it return an array ref, which the probe caught as `input 1 content must be a scalar without NUL bytes` before any test or commit.
- [x] **ADDRESSED (verified)** — both levels are now owned and the claim is evidence. `limit_v1` evaluates to `status=accepted` with `simultaneous_live_fibers` and `total_fibers` at exactly 16,384, 16,384 expanded operations, 16,401 source maps, plan `c58feb7f…` at 6,553,464 bytes — under the 16-MiB bound, so the cap reached is the axis's own — and empty `contract_discrepancies`. `over_limit_v1` adds exactly one 45-byte nested fiber record (`738,151 -> 738,196` bytes, verified as an equality in the test), keeps `semantic_rejection` undefined with SemanticIR `3441b80a…` carrying all 16,385 expanded actions and the unchanged bridge `a4565d40…`, and is rejected only at the execution stage with the one exact `VIAL_EXECUTION_LIMIT_ERROR`, `simultaneous_live_fibers exceeds the limit 16384`, at `/operation_graph/maximum_simultaneous_live_fibers`, exposing no `execution_ir` and no `plan`. New `t/1624-vial-architecture-scale-execution-live-fiber-limit.t` freezes all of it, and `t/1623`'s boundary assertion narrows to the still-unowned `fibers_total` levels.
- [x] **NO REGRESSION** — `scripts/run_with_ram_guard.sh -- prove -Iperl t/1604-vial-architecture-scale-execution-topology.t t/1605-vial-architecture-scale-execution-fibers.t t/1623-vial-architecture-scale-execution-fiber-qualification.t t/1624-vial-architecture-scale-execution-live-fiber-limit.t` reports `All tests successful` at `Files=4, Tests=18` in 69 seconds, covering the gate, the qualification, and the new limit ladder on one axis. `perl -Iperl -c` reports `syntax OK` for the changed module and both tests, `mdbook build docs/book` completes with only the pre-existing search-index size warning, staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`, and `knowledge-map: OK` covers 1,122 facts across 128 bounded shards. No public capability, support, performance, or capacity claim changed; the axis's cap is reported as reached, not as supported capacity.

## Acceptance Checklist (enforced) — `.17.2.4.2` fiber qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — both fiber qualification levels construct and build correct plans, and both were rejected by one oracle: evaluating them returns `VIAL_SCALE_EXECUTION_FIBER_ERROR`, `execution fiber gate did not preserve its exact bounded parallel-tree recipe`, at `/operation_graph/fibers`, while the plan itself reports the exactly correct 1,024/1,024 and 8,192/32 fiber widths. `git log -S'qw(31 31 31 31 3)' --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` locates the cause: `_fiber_oracle_errors` compared the plan against the *gate's* typed-in literals — `@parallel == 5`, `@reset == 127`, `qw(31 31 31 31 3)`, `@nested_children == 29` — rather than against the recipe `_total_fiber_actions` and `_live_fiber_action` actually generate, so it could only ever accept the one level it was written for.
- [x] **ADDRESSED (verified)** — the recipe is now one source of truth: `_total_fiber_group_sizes` and `_live_fiber_nested_counts` are extracted from the two renderers and read by the oracle, which recomputes group sizes, reset and operation counts, maximum live width, root successor chain, and parent/child closure from them. Both levels move from `status=oracle_failure` to `status=accepted` with empty diagnostics and no contract discrepancy, and their measurements are frozen in new `t/1623-vial-architecture-scale-execution-fiber-qualification.t`: `simultaneously_live_fibers` at plan `97efa27d…` with 1,024 total and 1,024 live fibers over 432,528 bytes, `fibers_total` at plan `ec7afcce…` with 8,192 total and 32 live fibers over 3,222,659 bytes, both against the unchanged checked-AHB bridge `a4565d40…`. The gate literals are gone, so no level is checked more loosely than the gate was. `t/1605`'s ladder boundary advances from the now-owned qualification level to the still-unowned `limit_v1`.
- [x] **NO REGRESSION** — `scripts/run_with_ram_guard.sh -- prove -Iperl t/1604-vial-architecture-scale-execution-topology.t t/1605-vial-architecture-scale-execution-fibers.t t/1623-vial-architecture-scale-execution-fiber-qualification.t` reports `All tests successful` at `Files=3, Tests=14` in 27 seconds, proving the refactored oracle still accepts both gates exactly. `perl -Iperl -c` reports `syntax OK` for the changed module and test, `mdbook build docs/book` completes with only the pre-existing search-index size warning, staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`, and `knowledge-map: OK` covers 1,122 facts across 128 bounded shards. No public capability, support, performance, or capacity claim changed.

## Acceptance Checklist (enforced) — `.17.2.4.2` total-operation qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — the total-operation axis declares a 65,536-operation `qualification_candidate_v1` level in `perl/FSM/VIAL/ArchitectureScaleWorkload.pm:700`, but no construction can reach it. Admitting the level through the caller-sealed generator and evaluating it returns `status=oracle_failure` with `VIAL_EXECUTION_LIMIT_ERROR`, phase `limit`, message `serialized_plan_bytes exceeds the limit 16777216`, at `/plan` — the identical earlier authority `git log -S'the 16777216-byte serialized-plan cap precedes the selected' --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` shows `.17.2.4.2` already recorded for the operations-per-scenario limit. The mechanism is that the plan cap binds total operations well below the selected qualification count, so this axis — unlike every axis before it — has no nominal operating point above its 1,024-operation gate.
- [x] **ADDRESSED (verified)** — the level is now owned and its authoritative outcome declared. `evaluate` returns `ok=1`, `status=expected_rejection`, exactly one `VIAL_EXECUTION_LIMIT_ERROR` diagnostic, empty `metrics`, and one `VIAL_SCALE_LIMIT_INTERACTION` discrepancy at `/requested_counts/operations_total` naming `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4`, against `status=oracle_failure` with a `VIAL_SCALE_EXECUTION_OUTCOME_ERROR` before the change. New `t/1622-vial-architecture-scale-execution-total-operation-qualification.t` freezes the 920,547-byte source at `sha256 8f9f1fe3…`, workload identity `133663d3…`, 32 authored scenarios, 65,536 authored resets, SemanticIR `3235975f…` with every scenario at exactly 2,048 expanded actions, the unchanged checked-AHB bridge `a4565d40…`, no partial IR or plan, and both higher total-operation levels still unowned. `t/1619`'s ladder boundary advances from the now-owned qualification level to the still-unowned `limit_v1`.
- [x] **NO REGRESSION** — `scripts/run_with_ram_guard.sh -- prove -Iperl t/1619-vial-architecture-scale-execution-operation-qualification.t t/1620-vial-architecture-scale-execution-operation-limit.t t/1621-vial-architecture-scale-execution-operation-over-limit.t t/1622-vial-architecture-scale-execution-total-operation-qualification.t` reports `All tests successful` at `Files=4, Tests=17` in 229 seconds, and `t/1183-ci-regression-tier-selection.t` passes at `Files=1, Tests=12` with the new test file in the tracked inventory. `perl -Iperl -c` reports `syntax OK` for the changed module and both tests, `mdbook build docs/book` completes with only the pre-existing search-index size warning, staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`, and `knowledge-map: OK` covers 1,122 facts across 128 bounded shards. No public capability, support, performance, or capacity claim changed, and the `.17.4` limit-policy owner remains `proposed`.

## Acceptance Checklist (enforced) — `.17.2.4.2` operation limit/over-limit ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S"axis eq 'operations_per_scenario'"
  --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` returns only
  topology commit `0f9d27611` and qualification commit `22387b468`, whose
  caller-sealed constructor admitted `gate_candidate_v1` and
  `qualification_candidate_v1` alone, so both higher levels raised
  `execution-graph gate slice does not own the requested shape`. A RAM-guarded
  probe then proved the exact authorities decision `0061` selects: 65,536
  operations parse cleanly and `FSM::VIAL::ExecutionBuilder->build` returns
  only `serialized_plan_bytes exceeds the limit 16777216` at `/plan`, while
  `FSM::VIAL::Parser->check_source` rejects 65,537 first with `scenario exceeds
  65536 expanded actions` at `/packages/0/fixtures/0/scenarios/0`. Because that
  second authority is the semantic stage, `_canonical_ahb_inputs` was the other
  locus: it built the canonical bridge before parsing, so a semantic rejection
  would have surfaced from behind a later stage, and its `parse_source` entry
  dies with a formatted string instead of returning a structured diagnostic.
- [x] **ADDRESSED (verified)** — the constructor now admits `limit_v1` and
  `over_limit_v1` for that axis; the AHB route parses the ordinary VIAL source
  before any bridge construction and returns the parser's own structured
  diagnostic; and the selected-rejection, expected-diagnostic, and new
  `VIAL_SCALE_LIMIT_INTERACTION` discrepancy tables are keyed by axis and
  level. Before: both levels died with the unowned-shape message. After:
  `prove -Iperl t/1620-vial-architecture-scale-execution-operation-limit.t
  t/1621-vial-architecture-scale-execution-operation-over-limit.t` reports
  `All tests successful` and freezes the 918,533-/918,547-byte sources and
  their exact 14-byte one-record delta, the accepted 65,536-action SemanticIR
  `fb82ce2c…`, the unchanged `a4565d40…` bridge, both exact authoritative
  diagnostics, absent partial ExecutionIR/plan, empty metrics, null SemanticIR
  and bridge identities for the semantic rejection, and one discrepancy per
  level naming `.17.4`. Mutation, missing checked-AHB source, and the
  still-unowned `operations_total` limit fail closed.
- [x] **NO REGRESSION** — all three changed Perl/test paths report `syntax OK`;
  focused t1620 reports `All tests successful` at `Files=1, Tests=4` in 89
  seconds and t1621 at `Files=1, Tests=4` in 44 seconds. The uninterrupted
  RAM-guarded execution/composition impact matrix reports `All tests
  successful` at `Files=25, Tests=95` in 960 seconds. The extracted new mdBook
  example runs clean against the live modules in 31 seconds. All 52 mdBook
  chapters test; the inspected repository-local render contains 88
  files/18,360 KiB and seven references to the two new authoritative
  diagnostics and the discrepancy code before exact removal.
  `knowledge-map: OK` reports 1,109 facts/5,771 questions/5,937
  occurrences/121 shards and resolves the new question to its canonical card,
  and `[doctrine] all doctrine checks passed` closes the staged gate. The
  `docs/knowledge/*.md` rollover-debt surface required compacting superseded
  card chronology and three duplicated freeze sentences; it now ends at exactly
  its owned 42,136-line allowance and 315 bytes below its byte allowance, with
  no exact recorded fact removed.
  Maintained-reference authority, task-tree integrity (936 nodes), relative
  paths, live containment (2,980 paths), bounded Memory, diff hygiene, and
  staged acceptance pass. No parser, SemanticIR, bridge,
  public binder, backend, downstream contract, capability/support,
  performance-budget, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` 8,192-operations-per-scenario qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S"axis eq 'operations_per_scenario'"
  --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` identifies
  only topology-gate commit `0f9d27611`. The clean predecessor's caller-sealed
  constructor admitted `operations_per_scenario` at `gate_candidate_v1` alone,
  so `qualification_candidate_v1` raised `execution-graph gate slice does not
  own the requested shape`. Decision `0061` already selects 8,192 accepted
  operations in one scenario, so missing generator ownership—not a public
  binder or semantic limit defect—was the exact unimplemented boundary.
- [x] **ADDRESSED (verified)** — the caller-sealed helper now admits precisely
  `qualification_candidate_v1` for that axis; `limit_v1` and `over_limit_v1`
  remain unowned. Before: construction died with the unowned-shape message.
  After: `prove -Iperl t/1619-vial-architecture-scale-execution-operation-qualification.t`
  reports `All tests successful` and freezes 8,192 accepted drive-phase resets
  in one `scenario_00000000`, one selected scenario, one root fiber, one
  simultaneously live fiber, 8,209 source maps whose global
  `/operation_graph/operations/N` paths each occur once and resolve to
  `/packages/0/fixtures/0/scenarios/0/actions/N`, 22 bindings, seven types,
  zero random attempts, a 115,716-byte source, a 508,968-byte bridge report,
  and a 2,955,783-byte plan with exact workload/SemanticIR/bridge/plan
  identities. Mutation, missing checked-AHB source, and the still-unowned
  `limit_v1` level fail closed.
- [x] **NO REGRESSION** — both changed Perl/test paths report `syntax OK`;
  focused t1619 reports `All tests successful` at `Files=1, Tests=4` in 10
  seconds. The uninterrupted RAM-guarded execution/bridge impact matrix
  reports `All tests successful` at `Files=22, Tests=95` in 814 seconds. All
  52 mdBook chapters test; the inspected repository-local render
  contains 88 files/18,623,226 bytes and both new byte-exact plan references
  before exact removal. The `docs/knowledge/*.md` rollover-debt surface ends
  4 lines/674 bytes below its owned allowance, and Knowledge Map
  generation/check/query reports 1,109 facts/5,770 questions/5,936
  occurrences/121 shards. Maintained-reference authority,
  task-tree integrity, relative paths, live containment, bounded Memory, diff
  hygiene, artifact residue, staged acceptance, and the full doctrine driver
  pass. No parser, SemanticIR, bridge, public binder, backend, downstream
  contract, capability/support, performance-budget, or capacity behavior
  changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` scenario qualification/limit/over-limit ladder

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S"axis eq 'scenarios'"
  --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` identifies
  only topology-gate commit `0f9d27611`: the caller-sealed constructor admitted
  `gate_candidate_v1` but not the selected qualification, limit, or over-limit
  levels. Decision `0061` already proved the real public builder accepts 4,096
  scenarios and rejects 4,097, so missing generator ownership—not a public
  limit defect—was the exact unimplemented boundary.
- [x] **ADDRESSED (verified)** — the caller-sealed helper now admits precisely
  `qualification_candidate_v1`, `limit_v1`, and `over_limit_v1` for scenarios.
  t1616-t1618 freeze 512/4,096 accepted scenario-operation-root-fiber chains,
  529/4,113 maps, one live fiber, exact 496,709-/3,779,103-byte plans and IDs,
  source/SemanticIR/bridge/workload identities, contiguous scenario IDs,
  deterministic reruns, and hostile inputs. The adjacent 4,097 construction
  requires only the exact unchanged public-binder diagnostic at
  `/scenario_ids` and exposes no partial IR or plan.
- [x] **NO REGRESSION** — all five changed Perl/test paths report `syntax OK`;
  focused t1616-t1618 reports `All tests successful` at `Files=3, Tests=12` in
  20 seconds (fresh final rerun: 21 seconds). The uninterrupted RAM-guarded execution/bridge impact matrix
  reports `All tests successful` at `Files=21, Tests=91` in 815 seconds.
  All 53 mdBook chapters test; the inspected repository-local render contains
  88 files/18,605,978 bytes and the exact scenario table, diagnostic, and
  runnable example before exact removal. Knowledge Map generation/check/query
  reports 1,109 facts/5,764 questions/5,930 occurrences/121 shards. Focused
  task/tree/live/reference/card documentation tests pass at Files=4/Tests=69
  plus Files=3/Tests=11. Bounded Memory, maintained-reference authority,
  artifact cleanup, staged acceptance, and final doctrines complete this
  slice. No parser, SemanticIR, bridge, public binder, backend, downstream
  contract, capability/support, performance-budget, or capacity behavior
  changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` one-million random limit/exhaustion

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S"axis eq 'random_attempts'"
  --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` identifies
  only the 8,192 gate and 262,144 qualification commits `b25efc3df` and
  `17c09f6f1`. The clean predecessor admits only
  `qualification_candidate_v1`, rejects any target above 1,000,000 during
  construction, and treats only serialized-plan excess as an expected
  rejection. Decision `0061` already selects exact one-million acceptance and
  adjacent deterministic exhaustion, but neither level had a canonical source
  route or a closed result oracle.
- [x] **ADDRESSED (verified)** — the caller-sealed generator now admits only
  `limit_v1` and `over_limit_v1` for the random axis while retaining the
  unchanged public binder as the authority that performs and caps attempts.
  Candidate `0xdd7997a868500a54` accepts exactly at attempt 999,999; strict
  replay preserves every keyed decision field except origin and derives exact
  34,297/34,296-byte plans. The adjacent candidate
  `0xce7d67adbe54da82` reaches the unchanged million-attempt cap, returns the one
  exact `VIAL_RANDOM_EXHAUSTED` diagnostic, and exposes no partial ExecutionIR
  or plan. Deterministic construction, identities, metrics, diagnostic bytes,
  missing-source rejection, and post-identity mutation rejection are frozen by
  t1614/t1615.
- [x] **NO REGRESSION** — focused t1614 reports `Files=1, Tests=4` in 252
  seconds, focused t1615 reports `Files=1, Tests=4` in 251 seconds, and legacy
  t1608/t1613 report `Files=2, Tests=8` in 71 seconds. The uninterrupted final
  RAM-guarded bridge/execution matrix reports `All tests successful` at
  `Files=18, Tests=79` in 784 seconds. Changed Perl/test syntax, all 53 mdBook
  chapters, repository-local render inspection/removal, Knowledge Map, task
  integrity, relative paths, live containment, maintained-reference authority,
  zero ceiling increases, artifact residue, diff, staged acceptance, and final
  doctrines pass. No parser, SemanticIR, bridge, public binder, backend,
  capability/support, performance-budget, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` 262,144-attempt random/replay qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'qualification_candidate_v1'
  --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` identifies
  only serialized-plan qualification commits `1e8ddd048`/`24ea9bb4b`:
  `construct` still grants the qualification level solely when the primary
  axis is `serialized_plan_bytes`. Decision `0061` and the workload catalog
  already select 262,144 random attempts, but the canonical execution-scale
  generator therefore rejects that exact requested shape before constructing
  the existing checked-AHB random/replay route.
- [x] **ADDRESSED (verified)** — the caller-sealed generator now admits only
  `qualification_candidate_v1` for `random_attempts`, reusing the unchanged
  checked-AHB/public-binder route. Candidate `0x00f233516a996304` accepts
  exactly at attempt 262,143; strict replay preserves every keyed decision and
  plan field except origin and the derived plan ID. Exact 34,297/34,296-byte
  plan identities, one occurrence/scenario/operation/root-live fiber, eight
  types, 22 bindings, 19 maps, missing-source rejection, replay mutation, and
  the still-unowned one-million level are frozen by t1613.
- [x] **NO REGRESSION** — the final guarded public-binder/architecture-scale
  matrix reports `All tests successful` at `Files=16, Tests=71` in 459 seconds;
  all three changed Perl/test paths report `syntax OK`. All 53 mdBook chapters
  test, and the repository-local 87-file/18,312-KiB HTML render preserves the
  new prose and code as distinct blocks before exact removal. `knowledge-map:
  OK` reports 1,108 facts/5,758 questions/5,924 occurrences/120 shards. Task
  integrity, relative paths, live containment, exact book/fact authority, zero
  ceiling increases, diff checks, and the final staged doctrine gate pass.
  Provider-cache validated-result logs remain project-local dependency data;
  no disposable `.bin`/`.log`, Rust target residue, mdBook build, or VIAL
  staging residue was removed or left behind.

## Acceptance Checklist (enforced) — `.17.2.4.2` first complete plan excess

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'over_limit_v1' --oneline --
  perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` returns no commit. Clean
  predecessor `67d463045` froze the exact 16,777,216-byte plan and decision
  `0061` selected one additional complete reset as the excess witness, but the
  generator still rejected `over_limit_v1` at admission and the evaluator
  classified every builder rejection as unexpected. No canonical excess
  source, adjacency proof, or exact diagnostic oracle existed.
- [x] **ADDRESSED (verified)** — the generator retains the limit source path,
  fixture, scenario, domain, endpoint, coverpoint, bin, and 48,851-cycle
  timeout while appending exactly one 12-byte reset record. Ordinary parsing
  accepts all 48,851 actions with exact SemanticIR identity; the unchanged
  public builder rejects at its shipped 16-MiB cap and returns no partial IR or
  plan. The evaluator accepts only the complete exact limit diagnostic as the
  selected rejection; mutation, missing checked source, and unowned reference
  level fail closed. `prove -Iperl t/1609-vial-architecture-scale-execution-plan-bytes.t
  t/1610-vial-architecture-scale-execution-plan-qualification.t
  t/1611-vial-architecture-scale-execution-plan-limit.t
  t/1612-vial-architecture-scale-execution-plan-over-limit.t` reports
  `All tests successful` at `Files=4, Tests=16`.
- [x] **NO REGRESSION** — all five changed Perl/test paths report `syntax OK`;
  the guarded execution/public-planning matrix reports `All tests successful` at
  `Files=15, Tests=67`. All mdBook chapters test and the inspected repository-
  local render is removed exactly. Knowledge Map, task integrity, all live-
  document surfaces, relative paths, exact book authority, zero ceiling
  increases, and staged doctrines pass. No parser, SemanticIR, bridge, public
  binder, backend semantics, runtime result, capability/support, performance
  budget, or capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` exact sixteen-MiB plan limit

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'limit_v1' --oneline --
  perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` returns no commit: decision
  `0061` selected the exact 48,850-reset/106-/two-character suffix recipe, but
  the generator admitted only gate and qualification plan levels and had no
  limit recipe, source identity, or closed exact-boundary oracle.
- [x] **ADDRESSED (verified)** — the generator now authors 48,850 real resets,
  one referenced 106-character scenario suffix, endpoint `ready_out_q`, and
  coverpoint `ready_sampled` on the real HREADYOUT binding. The unchanged public
  binder emits exactly 16,777,216 canonical bytes with plan ID
  `plan/0709d0c4d1432a218a0f26d9cce0c2b308d2f6fcf95f008bf6ceb65b15dc1e64`,
  one scenario/root-live fiber, seven types, 22 bindings, six events, and
  48,867 unique maps. Focused t1609/t1610/t1611 reports `Files=3, Tests=12`.
- [x] **NO REGRESSION** — changed Perl/test syntax is `OK`; the guarded
  execution/public-planning matrix reports `All tests successful` at
  `Files=14, Tests=63` in 191 seconds. All mdBook chapters test; the inspected
  repository-local render is removed exactly. Knowledge Map, task integrity,
  all live-document surfaces, relative paths, exact book authority, zero
  ceiling increases, and staged doctrines pass. No parser, SemanticIR, bridge,
  public binder, backend semantics, runtime result, capability/support,
  performance budget, or capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` exact four-MiB plan qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'qualification_candidate_v1'
  --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` returns no
  commit: the exact four-MiB request and 12,166-reset recipe existed only in
  the catalog and decision `0061`; the execution generator admitted only the
  one-MiB gate level and hard-coded that recipe's semantic names and oracle.
- [x] **ADDRESSED (verified)** — the generator now selects a closed recipe by
  exact requested bytes and authors 12,166 real resets, scenario `sg_4_mib`,
  endpoint alias `ready_out_q`, and coverpoint `ready_sampled` referencing the
  real HREADYOUT binding. The unchanged public binder emits exactly 4,194,304
  canonical bytes with plan ID
  `plan/63673374ece891a4234613c00c920ffe60cb4d6d73904ba0be2a2d5799f60d62`,
  one scenario/root-live fiber, seven types, 22 bindings, six events, and
  12,183 unique maps. Paired focused t1609/t1610 reports `Files=2, Tests=8`.
- [x] **NO REGRESSION** — changed Perl/test syntax is `OK`; the corrected
  guarded execution/public-planning matrix reports `All tests successful` at
  `Files=13, Tests=59` in 142 seconds. All mdBook chapters test; the inspected
  repository-local render is removed exactly. Knowledge Map, task integrity,
  all live-document surfaces, relative paths, exact book authority, zero
  ceiling increases, and staged doctrines pass. No parser, SemanticIR, bridge,
  public binder, backend semantics, runtime result, capability/support,
  performance budget, or capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` exact one-MiB plan gate

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'serialized_plan_bytes'
  --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` identifies
  `bfd85ade9`, whose implementation reported canonical plan bytes but did not
  admit `serialized_plan_bytes` as a constructible primary axis. Decision `0061`
  already selected a 2,974-reset gate recipe and required every remaining byte
  to come from referenced semantics rather than comments, blank data, caller-
  supplied plans, path inflation, or opaque padding.
- [x] **ADDRESSED (verified)** — the generator now authors exactly 2,974 real
  reset actions, a 41-character semantic scenario suffix, and a two-character
  endpoint suffix referenced by a real HREADYOUT coverpoint. The unchanged
  public binder produces exactly 1,048,576 canonical bytes, one scenario/root-
  live fiber, seven types, 22 bindings, six events, and 2,991 unique maps. Closed
  oracles freeze source spans, reset successors, logical time, public capability
  isolation, exact identities, and hostile-input failure. Focused t1609 reports
  `Files=1, Tests=4`.
- [x] **NO REGRESSION** — changed Perl/test syntax is `OK`; the guarded final
  execution/public-planning matrix reports `All tests successful` at
  `Files=12, Tests=55` in 127 seconds. All mdBook chapters test; the inspected
  repository-local render is removed exactly. Knowledge Map, task integrity,
  all live-document surfaces, relative paths, exact book authority, zero ceiling
  increases, and staged doctrines pass. No parser, SemanticIR, bridge, public
  binder, backend semantics, runtime result, capability/support, performance
  budget, or capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` execution random/replay gate

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'random_attempts' --oneline
  -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` returns no commit: the
  selected count existed in the workload catalog and decision `0061`, but the
  execution generator owned neither that axis nor a strict replay oracle. A
  referenced choice is required because `ExecutionBuilder` creates occurrences
  only for choices reached by real operation inputs.
- [x] **ADDRESSED (verified)** — the generator now computes the deterministic
  64-bit proposal at attempt 8,191 with shipped `ExecutionRandom`, authors it as
  a full-range u64 equality constraint, and references it from one check-phase
  expectation. Evaluation independently regenerates and builds a strict replay
  through the unchanged public binder. Exact decision equality permits only the
  `generated` -> `replayed` origin transition; generated/replayed plan identities,
  34,295/34,294 bytes, one occurrence/operation/fiber, 19 maps, logical time,
  public capability isolation, and replay/source fail-closed edges are frozen.
  Focused t1608 reports `Files=1, Tests=4`.
- [x] **NO REGRESSION** — changed Perl/test syntax is `OK`; the guarded final
  execution/public-planning matrix reports `All tests successful` at
  `Files=11, Tests=51` in 126 seconds. All 52 mdBook chapters test; the inspected
  repository-local render is removed exactly. Knowledge Map, task integrity,
  all live-document surfaces, relative paths, exact book/card authority, zero
  ceiling increases, and staged doctrines pass. No parser, SemanticIR, bridge,
  public binder, backend semantics, runtime result, capability/support,
  performance budget, or capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` execution source-map gate

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'source_map_records' --oneline
  -- perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm` identifies `bfd85ade9`
  as the metric-only introduction: its diff places the token solely in the
  evaluation metric, while `construct` did not own that primary axis. Decision
  `0061` assigns the gate to the frozen checked-AHB route. A canonical public-
  binder census then shows 17 stable non-operation maps—domain, three endpoint
  relations, one probe relation, six transaction fields, and six events—so
  treating the requested 8,192 maps as 8,192 operations would miss the selected
  axis by 17.
- [x] **ADDRESSED (verified)** — the generator now subtracts the exact fixed
  family and authors 8,175 genuine reset actions. Closed oracles freeze all
  8,192 unique plan paths, action-indexed semantic paths, ordered non-empty
  source spans, real fixed bridge facts, one contiguous reset chain, logical
  time, checked-AHB IAL2/IAL1/IAL0 route, public capability isolation,
  deterministic source/SemanticIR/bridge/workload/plan identities, and
  mutation/missing-source/unfinished-level rejection. Focused t1607 passes at
  `Files=1, Tests=4`.
- [x] **NO REGRESSION** — changed Perl/test syntax is `OK`; the final guarded
  architecture/public-planning matrix reports `All tests successful` at
  `Files=10, Tests=47` in 111 seconds. All 52 mdBook chapters test; its exact
  runnable example appears in the inspected 88-file/18,224-KiB repository-
  local render before removal. Knowledge Map is current at 1,108 facts/5,752
  questions/5,918 occurrences/120 shards; task integrity remains 936 nodes;
  all 22 live surfaces and 2,975 paths pass with exact book/card authority and
  zero ceiling increases; the 14-entry rationale ledger reconstructs. Staged
  acceptance and all nine doctrines pass. No parser, SemanticIR, bridge,
  public binder, backend semantics, runtime result, capability/support,
  performance budget, or capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` execution-type gate

- [x] **ROOT CAUSE (WHY + WHERE)** — Decision `0061` assigns execution types
  to ordinary direct IAL1 because the fixed checked-AHB actor exposes only
  seven normalized execution shapes. `ExecutionBuilder::_register_type`
  deduplicates exact semantic shapes reached by real representation proofs, so
  512 declared-but-unused aliases would not exercise the limit. Initial real
  construction also exposed local helper autovivification: `_backend_names`
  dereferenced optional `verification_bridge.probes`, changing an absent
  actor annotation into `{}` after scheduler reporting and causing the bridge's
  actor/report identity check to fail closed as `canonical architecture-scale
  bridge construction failed at perl/FSM/VIAL/ArchitectureScaleExecutionGraph.pm line 225`.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleExecutionGraph` now authors
  one public input and VIAL endpoint for every unsigned four-state width
  `1..512`, lowers the non-annotated actor through canonical IAL1/IAL0, and
  invokes the unchanged public binder. Closed oracles freeze one semantic ID,
  carrier type, and drive relation per shape; exact binding/type/map/topology,
  route/capability isolation, source/semantic/bridge/plan identities,
  deterministic reruns, post-identity mutation, caller-source injection, and
  unfinished-level rejection. Optional probe collection now tests for a bridge
  hash before dereferencing it, preserving explicit absence.
- [x] **NO REGRESSION** — Changed Perl/test syntax is `OK`; focused t1606
  reports `All tests successful` at `Files=1, Tests=4`; adjacent t1603-t1606
  pass, and the final RAM-guarded impact matrix reports `All tests successful`
  at `Files=9, Tests=43`. Relative-path docs pass at `Files=1, Tests=2`; all
  52 mdBook chapters test and the repository-local 88-file/18,220-KiB render
  contains the exact route/count/example before removal. `knowledge-map: OK`
  reports 1,107 facts/5,746 questions/5,912 occurrences/119 shards; task
  integrity is 936 nodes; all 22 live surfaces and 2,972 paths pass with zero
  ceiling increases; the 14-entry rationale reconstructs. Staged acceptance
  and the doctrine driver remain the final commit-workflow rerun. No parser,
  SemanticIR, bridge, public binder, backend semantics, runtime result, public
  capability/support, performance budget, or scale-capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` total/live fiber gates

- [x] **ROOT CAUSE (WHY + WHERE)** — Decision `0061` selects exact 128-total
  and 32-simultaneously-live gate counts but requires different bounded
  parallel shapes so a total-fiber witness does not accidentally exceed the
  live-fiber gate. `SemanticBuilder` caps one parallel at 256 fibers and
  nesting at 16; `ExecutionBuilder::_maximum_live_descendants` counts the root
  plus every structurally concurrent descendant. `git log -S'_maximum_live_descendants'
  --oneline --
  perl/FSM/VIAL/ExecutionBuilder.pm` locates that structural authority at
  `44dbecd1a`. The existing generator owned neither fiber axis, and the
  Knowledge Map routed both to this active leaf.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleExecutionGraph` now emits
  five sequential `all` groups with 31/31/31/31/3 reset-bearing children for
  exactly 128 total and 32 live fibers, plus one depth-two `all` tree with two
  outer and 29 nested reset-bearing children for exactly 32 total/live fibers.
  Closed oracles freeze operations, ranks, phases, successor chains, parent/
  child topology, joins, unique global maps, canonical bytes/hashes,
  deterministic reruns, frozen checked-AHB route, public capability isolation,
  post-identity mutation rejection, and unfinished-level closure.
- [x] **NO REGRESSION** — Changed Perl/test syntax is `OK`; focused t1605
  reports `All tests successful` at `Files=1, Tests=5`; the final RAM-guarded
  architecture/public-planning matrix reports `All tests successful` at
  `Files=9, Tests=44`. Documentation paths pass at `Files=1, Tests=2`; all 52
  mdBook chapters test, and the repository-local 88-file/18,216-KiB render
  preserves the exact table/example before removal. Knowledge Map reports
  1,107 facts/5,745 questions/5,911 occurrences/119 shards; task integrity is
  936 nodes; all 22 live surfaces and 2,972 paths pass with zero ceiling
  increases; the 13-entry current rationale reconstructs; staged acceptance
  and all nine doctrines pass. No backend semantics, runtime result, public
  capability/support, performance budget, or scale-capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` topology gates and source-map repair

- [x] **ROOT CAUSE (WHY + WHERE)** — Canonical 32-scenario construction
  produces 32 real operations but the clean predecessor emits 32 copies of
  `/operation_graph/operations/0`. `git log -S'_add_source_map($ctx,
  "/operation_graph/operations/"' --oneline --
  perl/FSM/VIAL/ExecutionBuilder.pm` and blame locate `44dbecd1a`: `_emit_sequence`
  correctly uses scenario-local operation arrays/ranks but incorrectly reused
  their local index for the flat plan's global source-map path.
- [x] **ADDRESSED (verified)** — `ExecutionBuilder` now records a scenario's
  global operation offset and applies it only to operation source-map paths;
  local ranks, IDs, successor chains, logical time, and semantics remain stable.
  `ArchitectureScaleExecutionGraph` generates checked-AHB 32x1, 1x256, and
  32x32 reset shapes through the public binder, freezes exact 59,907/121,163/
  409,363-byte plans and hashes, and proves every global operation index maps
  exactly once. Byte-locked native-UVM/VHDL/OSVVM galleries and exact GHDL/
  OSVVM qualification reports are refreshed from the corrected identity.
- [x] **NO REGRESSION** — The final RAM-guarded planning/runtime/parity/native-
  UVM/portable-VHDL/GHDL/OSVVM/scale matrix reports `All tests successful` at
  `Files=17, Tests=102`; changed Perl/tests report `syntax OK`. All three
  gallery `--check` modes pass. Documentation paths report `All tests
  successful` at `Files=1, Tests=2`; mdBook test/build/render inspection,
  `knowledge-map: OK`, 936-node task integrity, 2,972-path live containment,
  rationale-ledger reconstruction, zero ceiling increases, diff hygiene, and
  staged doctrines pass. No public capability/support, backend semantics,
  performance budget, or scale-capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.4.2` binding-gate foundation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'hial_vial.bridge_qualification.architecture_scale_v1'
  --oneline -- perl docs t` locates the public execution allow-list before the
  private bridge capability. Canonical inspection proves endpoint fanout reaches
  the 16-MiB bridge cap first, while `bindings - 6` ordinal events preserve the
  selected gate through ordinary source, bridge, semantic, and plan stages.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleExecutionGraph` now authors
  2,042 events and reaches exactly 2,048 bindings through one caller-sealed
  admission that also requires exact direct-IAL1 protocol metadata. The plan
  classifies the capability as qualification-only/private-nonportable; public,
  direct, altered, incomplete, and forged paths fail closed.
- [x] **NO REGRESSION** — focused RAM-guarded t1603 reports
  `All tests successful` at `Files=1, Tests=3`; guarded t1552/t1600/t1602
  report `All tests successful` at `Files=3, Tests=18`; syntax reports
  `syntax OK`; `knowledge-map: OK`, mdBook
  test/render, documentation paths, task integrity, live containment,
  `git diff --check`, and staged doctrines pass. Public execution, planning,
  backends, support accounting, and every capacity/performance nonclaim remain
  unchanged.

## Acceptance Checklist (enforced) — `.17.2.4.2` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -1 --format='%h %s'` identifies
  clean predecessor `b82426c85`, whose decision `0061` closes reachability and
  explicitly assigns implementation to `.17.2.4.2`; the leaf cannot own code
  until its status changes from proposed to active in a separate clean slice.
- [x] **ADDRESSED (verified)** — `.17.2.4.2` alone is active with the exact
  caller-sealed binder, canonical construction routes, earliest-cap matrix,
  deterministic random/replay, exact plan-byte recipes, preflight/resource
  policy, oracle set, and cleanup boundary selected by decision `0061`.
- [x] **NO REGRESSION** — `knowledge-map: OK`, task-tree integrity,
  documentation-relative paths, `git diff --check`, and staged doctrines pass.
  No code, test, config, generated artifact, parser, bridge, binder, plan,
  backend, capability/support, performance-budget, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.4.1` execution-scale reachability

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'hial_vial.bridge_qualification.architecture_scale_v1'
  --oneline -- perl docs t` locates private bridge qualification in
  `9c5212cc4`/`97dda148d`,
  after the public execution allow-list in `44dbecd1a`. Source inspection and
  a real canonical binder probe return `VIAL_CAPABILITY_ERROR` for that exact
  private capability, proving the public binder is correctly closed. Separate
  guarded probes locate plan-byte, bridge-byte, semantic-action, structural,
  and random-exhaustion boundaries rather than assuming the nominal table is
  reachable.
- [x] **ADDRESSED (verified)** — Decision `0061` selects one caller-sealed
  qualification admission for the binding gate while leaving public build and
  planning unchanged. It freezes the AHB/plain-IAL1/private-event routes, all
  13 axes at five levels, exact earliest-cap outcomes, depth-two live-fiber
  construction, deterministic attempt targeting/replay, genuine exact
  1/4/16-MiB plan recipes, preflight/RAM safety, and unchanged nonclaims in the
  task, book, and Knowledge Map.
- [x] **NO REGRESSION** — RAM-guarded `t/1552`, `t/1600`, and `t/1602`
  report `All tests successful` at `Files=3, Tests=18`; documentation paths
  report `Files=1, Tests=2`; ceiling and maintained-reference authorities report
  `Files=2, Tests=12`; `knowledge-map: OK` reports 1,107 facts/5,743 questions/
  5,909 occurrences/119 shards; task-tree integrity reports three active trees/
  936 nodes; live containment, mdBook test/render, `git diff --check`, and staged
  doctrines pass. No parser, SemanticIR, bridge, public binder, plan, replay,
  backend, capability/support, performance-budget, or capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.4` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'execution_graph_v1'
  --oneline -- docs perl t` locates scale-contract selection `0516f2c66`, while
  clean predecessor `97dda148d` completes only bridge-fanout generation.
  Direct inspection of `ArchitectureScaleWorkload`, `SemanticBuilder`,
  `ExecutionBuilder`, `ExecutionRandom`, and their support contracts proves
  that canonical source limits, the fixed one-fixture/unit/domain profile,
  random-attempt semantics, and the 16-MiB plan cap must be reconciled before
  the nominal execution-axis table can safely drive implementation.
- [x] **ADDRESSED (verified)** — `.17.2.4` now owns execution-graph generation
  and decomposes it into active read-only reachability selection `.17.2.4.1`
  plus proposed implementation `.17.2.4.2`. The task frontier, bounded resume
  pointer, mdBook explanation, and exact maintained-reference authority agree;
  no generator or product behavior is changed by activation.
- [x] **NO REGRESSION** — task-tree integrity reports three active trees and
  936 nodes; relative-path tests report `All tests successful` at
  `Files=1, Tests=2`; all 52 mdBook
  chapters test; the verified 87-file repository-local render is removed
  exactly; diff and staging-residue checks pass. The final staged doctrine
  rerun supplies the governing acceptance result; parser, IR, bridge, binder,
  plan, replay, capability/support, performance, and capacity behavior remain
  unchanged.

## Acceptance Checklist (enforced) — `.17.2.3.2` canonical bridge-fanout generation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_validate_ahb_bridge'` locates
  fixed AHB origin `51434a2ae`; `git log -S'bridge_fanout_v1'` locates later
  scale selection `0516f2c66` without a reachable producer. Decision `0060`
  selects the repair. Real-Builder calibration also proves that valid
  49,152/65,536 source-map shapes reach the 16-MiB report cap first.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleBridgeFanout` generates all
  65 axis/level inputs as ordinary HIAL/VIAL source and evaluates them only
  through parse, scheduler report, IAL0 lowering, and Builder. Oracles cover
  exact/earliest-cap counts, unique IDs, total maps, closed bindings and VIAL
  references, immutable byte-equal reports, deterministic reruns, route
  layers, IAL2 rejection, and cleanup. Serialized reports are exactly
  1/4/16 MiB and source-map gate is exactly 8,192 records.
- [x] **NO REGRESSION** — Default t1602 reports `Files=1, Tests=5` in 17
  seconds; the final RAM-guarded exact matrix reports `Files=1, Tests=5` in 122
  seconds; adjacent t1551/t1600/t1601 report `Files=3, Tests=17`. The frozen
  AHB report remains SHA-256
  `a4565d40507f369799adaf199b57a6695b12022d068ff9902cec1bdec1a71aca`.
  Documentation, mdBook, Knowledge Map, task integrity, staged acceptance,
  doctrines, and residue checks complete in the commit workflow; support,
  performance, and capacity claims remain unchanged.

## Acceptance Checklist (enforced) — `.17.2.3.1` reachability selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_validate_ahb_bridge'
  --oneline -- perl/FSM/HIAL/VIALBridge/Builder.pm` identifies fixed-profile
  origin `51434a2ae`; `git log -S'bridge_fanout_v1' --oneline -- docs perl t`
  identifies later candidate selection `0516f2c66`. Builder source proves the
  annotated path cannot currently reach four selected structural axes.
- [x] **ADDRESSED (verified)** — Decision `0060` selects one closed
  `qualification_only` direct-IAL1 profile. A real `perl -Iperl` probe using
  `FSM::Adapter::ISF` and `FSM::Scheduler::ISF` returns actor
  `vial_architecture_scale`, one transaction/probe/residue, profile
  `qualification_only`, and generated `vial_architecture_scale.fsm`.
- [x] **NO REGRESSION** — `scripts/check_doctrines.sh` reports
  `[doctrine] all doctrine checks passed` after documentation tests, all 52
  mdBook chapter tests,
  repository-local build/inspection/cleanup, task integrity, Knowledge Map,
  relative-path, and diff checks. Selection changes no parser, scheduler,
  builder, manifest, route, artifact, capability/support, performance-budget,
  or scale-capacity behavior.

## Acceptance Checklist (enforced) — `.17.2.3.1` activation after reachability audit

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_validate_ahb_bridge'
  --oneline -- perl/FSM/HIAL/VIALBridge/Builder.pm` identifies implementation
  origin `51434a2ae`; `git log -S'bridge_fanout_v1' --oneline -- docs perl t`
  identifies later scale selection `0516f2c66`. The fixed AHB validator and
  annotated-actor projection make four nominal bridge-family caps unreachable.
- [x] **ADDRESSED (verified)** — Parent `.17.2.3` now decomposes into active
  documentation-only reachability selection `.17.2.3.1` and proposed
  implementation `.17.2.3.2`. The exact mismatch is durable before any source
  change, and the selection must preserve the shipped AHB route and nonclaims.
- [x] **NO REGRESSION** — `scripts/check_doctrines.sh` passes all staged
  doctrine gates after task integrity, relative-path, and diff checks. No
  parser, scheduler, builder, manifest, route, artifact, capability/support,
  performance-budget, or scale-capacity behavior changes.

## Acceptance Checklist (enforced) — `.17.2.3` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -1 --oneline` identifies clean
  predecessor `145d3084a`, where `.17.2.2` completed the semantic family and
  left proposed `.17.2.3` as the precise next PNT leaf. Decision `0055` places
  canonical HIAL bridge routes and manifest oracles in that leaf; no bridge
  generator implementation is present or authorized before activation.
- [x] **ADDRESSED (verified)** — This continuity-only slice activates exactly
  `.17.2.3` in the owning tree and synchronizes the bounded task index,
  Knowledge Map fact, and Memory resume pointer. All later `.17.2` leaves
  remain proposed, and no product file or user-facing behavior changes.
- [x] **NO REGRESSION** — `scripts/check_doctrines.sh` passes all staged
  doctrine gates after task integrity, Knowledge Map currency, relative-path,
  and diff checks. No builder, bridge, manifest, source route, artifact,
  capability/support, performance-budget, or scale-capacity claim changes.

## Acceptance Checklist (enforced) — `.17.2.2` canonical semantic generation

- [x] **ROOT CAUSE (WHY + WHERE)** — Completed `.17.2.1` supplied the selected
  source-only workload specification but no canonical semantic-family
  producer/oracle. During implementation, global-ID validation also proved
  that `SemanticBuilder::_action` scoped scenario-local handles/expectations
  and parallel-local fibers only to their fixture. `git log -S'handle_name'
  --oneline -- perl/FSM/VIAL/SemanticBuilder.pm` identifies origin
  `be9c741630`, so legal repeated AHB expectation names mapped distinct
  authored paths to the same ID. Exact probes separately prove that repeat
  65,536 reaches the 65,536 expanded-action cap before the selected higher
  repeat boundary.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleSemanticCatalog` constructs
  all 14 axes/five levels as typed reachable `.vial`, accepts no IR, and uses
  only Parser/SemanticBuilder. Evaluations prove exact counts, unique scoped
  IDs, spans, closed references/types, order, reports, formatting, byte
  boundaries, diagnostics, and cleanup. Decision `0058` scopes action-local
  IDs at their language boundary; decision `0059` records rather than hides
  the repeat/action interaction for `.17.4`. Default t1601 and exact guarded
  t1601 pass; the latter covers every qualification/limit/excess level in
  359 seconds without crossing the 88%-host/4,096-MiB-descendant guards.
- [x] **NO REGRESSION** — Focused t1550/t1590 pass at Files=2/Tests=24, every
  default semantic gate and all 70 construction reruns pass, and exact scale
  staging leaves no repository-local residue. Five changed modules/tests pass
  syntax checks; the final RAM-guarded impact suite reports the exact prove
  summary `All tests successful; Files=21, Tests=140` in 221 seconds,
  including real Verilator, exact GHDL 6.0.0 LLVM-JIT, and exact OSVVM 2026.05
  plus GHDL qualification.
  Canonical refresh workflows close every native-UVM, portable-VHDL, OSVVM,
  and qualification snapshot after the semantic plan identity changes. All 52
  mdBook chapters test and the rendered repository-local build contains 88
  files/18,392,884 bytes before exact removal. Task integrity remains three
  trees/932 nodes/one segment/one index archive; documentation governance
  passes at Files=8/Tests=89 and 2,969/2,969 paths, maintained-reference
  authority accepts exact book delta 0/+67/+3,225, and decision `0059`
  authorizes only the required knowledge-card file ceiling change
  1,106→1,107. Knowledge Map is current at 1,106 facts/5,733 questions/5,899
  occurrences/119 shards.
  Package/declaration/fixture/scenario IDs, syntax, reports, bridge meaning,
  runtime outcomes, capability/support classifications, performance budgets,
  and all scale-capacity nonclaims remain unchanged.

## Acceptance Checklist (enforced) — `.17.9` failed-stage cleanup repair

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation `4e9382d8a`,
  `git log -S'my $cleanup_error = []' --oneline --
  perl/FSM/VIAL/ArtifactTransaction.pm` identifies `045629c97`, where public
  planning publication introduced an array reference for File::Path's `error`
  option. File::Path requires a reference to a scalar that receives the error
  array; the wrong shape throws `Not a SCALAR reference` during cleanup and
  strands the operation-owned stage after any post-creation failure.
- [x] **ADDRESSED (verified)** — ArtifactTransaction now declares an undefined
  scalar, passes its reference to `remove_tree`, and inspects the populated
  array only when present. The public CLI regression overrides only the first
  artifact write, proves staging already began, checks the exact sanitized
  host-error result, proves stage and target absent, and retries the identical
  operation successfully. Repository-wide audit classifies every tracked
  `remove_tree` call and confirms all six production error collectors use the
  scalar-reference form; uncollected test teardown calls are not error
  collectors. The existing atomic-publication mdBook contract now states the
  post-staging cleanup and retry guarantee explicitly.
- [x] **NO REGRESSION** — ArtifactTransaction and t1556 syntax pass. Focused
  t1556 reports `All tests successful` at Files=1/Tests=6; the public source,
  planning, exact-Verilator runtime, and AHB parity impact suite reports `All
  tests successful` at Files=4/Tests=20. Existing successful, unchanged,
  collision, symlink/traversal, tree-identity, publication, runtime, and parity
  paths remain exercised. All 52 mdBook chapters test; the repaired contract
  renders in an 88-file/18,368,361-byte repository-local build removed
  exactly; maintained-reference authority accepts 0 files/+4 lines/+189
  bytes. Task-tree, Knowledge Map, Memory, staged acceptance, doctrine, diff,
  generated-residue, `.bin`, and `.log` checks pass. No artifact graph, target
  root, parser, plan, backend, runtime, capability/support, performance, or
  scale claim changes.

## Acceptance Checklist (enforced) — `.17.9` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — Clean predecessor `063b990f3` completes
  `.17.2.1`. Its source audit and repository-local File::Path probe prove the
  public `FSM::VIAL::ArtifactTransaction` failure cleanup passes an invalid
  array reference where File::Path requires a scalar reference, leaving the
  operation-owned staging tree. The proposed `.17.9` leaf is therefore the
  exact dependency-closed owner before semantic workload generation resumes.
- [x] **ADDRESSED (verified)** — Only durable continuity surfaces activate
  `.17.9`: its task node, task index frontier, fact card, and bounded Memory
  pointer. The acceptance boundary remains the one collector repair, forced
  post-staging failure regression, repository-wide collector audit, and
  preservation of all successful/collision/atomic-publication behavior.
- [x] **NO REGRESSION** — Task-tree, Knowledge Map, Memory, relative-path,
  diff, staged docs-only acceptance, and all doctrine gates pass from the
  clean predecessor. No implementation, test behavior, generated artifact,
  target root, parser, plan, backend, runtime, capability, support, or scale
  claim changes during activation.

## Acceptance Checklist (enforced) — `.17.2.1` deterministic workload foundation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation commit `49b6e1ba4`,
  `git log -S'fsmgen.vial_architecture_scale_workload.v1' --oneline --
  perl/FSM/VIAL scripts t` returns no producer. Decisions `0055`/`0056`
  selected only the scale contract, while source audit finds reusable canonical
  JSON, `ExecutionRandom`, repository-local staging, and cleanup authorities.
  The selection also left source-byte candidates unassigned; decision `0057`
  closes that gap without inventing a capacity claim. A separate source audit
  finds the pre-existing ArtifactTransaction cleanup-collector defect owned by
  proposed `.17.9`, not by this foundation leaf.
- [x] **ADDRESSED (verified)** — `FSM::VIAL::ArchitectureScaleWorkload` now
  provides exact versioned catalog, construction, and staging schemas; six
  orthogonal families plus the balanced profile; all 250 selected
  family/axis/level specifications; four backend profiles and exact logical
  tool selectors; fixed seed 1701; shipped SHA-256 counter/rejection payloads;
  stable names; path-sorted content identity; bounded source-only validation;
  canonical-construction revalidation; and repository-volume staging with
  collision rejection and exact cleanup. Decision `0057`, the mdBook, task
  index, fact card, and bounded Memory state the same shipped boundary.
- [x] **NO REGRESSION** — Module and test syntax pass. The guarded focused and
  adjacent suite reports `All tests successful` at Files=5/Tests=38, including
  every catalog specification, mutation boundaries, deterministic reruns, and
  success/failure cleanup. All 52 mdBook chapters test and the rendered
  foundation appears in an 88-file/18,367,391-byte repository-local build removed exactly;
  maintained-reference authority accepts 0 files/+78 lines/+3,685 bytes. The
  initially exposed local cleanup residue was removed exactly, its collector
  corrected, and repeat execution leaves no scale stage. Task-tree, Knowledge
  Map, Memory, relative-path, staged acceptance, doctrine, diff, `.bin`/`.log`,
  and generated-artifact checks pass. No parser, SemanticIR, bridge,
  ExecutionIR, emitter, runtime, capability, support classification,
  performance budget, or architecture-scale capacity changes.

## Acceptance Checklist (enforced) — `.17.8` decision execution reconciliation

- [x] **ROOT CAUSE (WHY + WHERE)** — on clean activation predecessor
  `8201334c4`, `rg 'currently reports 4,194,304|Proposed leaf .17.6|repair
  the support snapshot' docs/decisions/005{5,6}-*.md` finds selection-time
  present/future wording after implementation commit `5db70fa08` had already
  aligned the public support contract. Git history and the completed `.17.6`
  task evidence prove this is stale decision execution status, not a second
  limit or a product regression.
- [x] **ADDRESSED (verified)** — decisions `0055`/`0056` retain every original
  discrepancy, rationale, and selected rule as audit evidence, add explicit
  execution sections naming commit `5db70fa08` and the exact 8,388,608/
  67,108,864-byte aligned values, and identify that execution as current
  authority. Their index summaries record the same state.
- [x] **NO REGRESSION** — both rationale records remain below the 512-line cap;
  relative-path, task-tree, Knowledge Map, bounded Memory, diff hygiene,
  staged acceptance, and all nine doctrine checks pass. No selected workload
  or measurement contract, implementation, runtime behavior, capability set,
  support classification, or scale claim changes.

## Acceptance Checklist (enforced) — `.17.6` support-limit alignment

- [x] **ROOT CAUSE (WHY + WHERE)** — on clean activation predecessor
  `8279993c0`, `git log -S'compile_transcript_bytes' --
  perl/FSM/Support/VIALExecutionContract.pm` identifies `dfe87f536`, whose
  support snapshot introduced 4,194,304-byte compile and run values while its
  Runner implementation enforced 8,388,608 compile and 67,108,864 runtime
  bytes. A complete consumer scan finds no second contradictory product value;
  the normative backend table already agrees with Runner.
- [x] **ADDRESSED (verified)** — `FSM::Support::VIALExecutionContract` now
  publishes exactly 8,388,608/67,108,864 bytes. `t/1558` independently locks
  the direct contract and exact Runner integration; `t/297` locks the nested
  public capability-manifest accounting. The mdBook replaces the obsolete
  discrepancy with the aligned values and retains the non-scale boundary.
- [x] **NO REGRESSION** — syntax passes for the contract and both edited tests;
  the combined execution/backend/capability/Verilator gate reports `All tests
  successful` at `Files=4, Tests=21`. All 52 mdBook chapters test; its rendered
  aligned-limit paragraph is distinct and the repository-local 88-file/
  18,336,328-byte build is removed exactly. Maintained-reference authority
  accepts 0 files/-1 line/-82 bytes; task integrity, Knowledge Map, staged
  acceptance, and all nine doctrines pass. Runner code/behavior, diagnostic
  text, artifacts, capability set, support classification, backend
  qualification, and every scale nonclaim remain unchanged.

## Acceptance Checklist (enforced) — `.17.7` focused-index authority repair

- [x] **ROOT CAUSE (WHY + WHERE)** — on clean activation predecessor
  `44ad589ce`, `scripts/focused_document_index.pl check` reports the byte-current
  generated projection at 1,023 members, but `git log -S'1022 members' --
  t/1569-focused-document-containment.t` locates the second mutable count at
  `70ba62f35`. The registered OSVVM gallery README legitimately advanced index
  membership after that commit, so replacing 1,022 with 1,023 would reproduce
  the same derived-state defect.
- [x] **ADDRESSED (verified)** — the real-index positive now requires the
  indexer's complete anchored success record with nonzero member, line, and
  byte fields, without embedding any current count. The separate byte-current
  check and every generated-index stale/unclassified/duplicate/escaping/empty-
  group and semantic-part negative remain intact.
- [x] **NO REGRESSION** — `t/1569-focused-document-containment.t` reports
  `syntax OK`; the focused containment/reference suite reports `All tests
  successful` at `Files=4, Tests=36`; and the authority reports
  `focused-document-index: current (1023 members; 1090 lines; 149801 bytes)`.
  Task integrity, Knowledge Map, live-document containment, staged acceptance,
  and all nine doctrines pass. No surface membership, classifier, ceiling,
  generator, product behavior, support state, or scale claim changes.

## Acceptance Checklist (enforced) — `.17.1` scale-contract selection

- [x] **ROOT CAUSE (WHY + WHERE)** — the architecture audit requires scale
  proof across independent HIAL/VIAL/IR/backend/resource dimensions, while the
  separate whole-product tree forbids inventing `big`/`really_big` capacity.
  Exact limit scans cover the shipped source, bridge, execution, portable-SV,
  VHDL, OSVVM, artifact, trace/result, timeout, and RAM-guard authorities.
  `git log -S'compile_transcript_bytes' -- perl/FSM/Support/VIALExecutionContract.pm`
  and `git show dfe87f536` prove that one historical commit added Runner-
  enforced 8,388,608/67,108,864-byte capture and contradictory public support
  values of 4,194,304/4,194,304 bytes.
- [x] **ADDRESSED (verified)** — decisions `0055`/`0056` and their normative
  selected contracts define six orthogonal workload
  families, exact candidate/limit tables, one balanced interaction candidate,
  canonical construction, stage oracles, measurement/repetition records,
  fixed safety, evidence-derived budgets, cap dominance, same-volume cleanup,
  promotion gates, and exact nonclaims. Proposed `.17.6` durably owns support-
  snapshot alignment before `.17.2` automation consumes it; this docs-only
  slice does not edit that product snapshot.
- [x] **NO REGRESSION** — focused checks report `All tests successful` at
  `Files=8, Tests=86`; focused-document index authority, relative-path audit,
  task-tree integrity, mdBook test/build, Knowledge Map generation/check, live-
  document authority, diff hygiene, staged acceptance, and all doctrine checks
  must pass; generated book and scale-staging residue must be absent. The
  focused index itself is byte-current at 1,023 members; the independently
  pre-existing `t/1569` assertion for 1,022 is owned by proposed `.17.7` and is
  not rewritten in this docs-only selection. No parser, IR, bridge, generator,
  artifact, tool, runtime, capability, support, or scale claim changes.

## Acceptance Checklist (enforced) — `.17` selection and activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `command -v` finds Verilator and Icarus
  but no compatible mixed-language simulator; the exact GHDL 6.0.0 LLVM-JIT
  binary is repository-local and independently VHDL-qualified. Decisions 0032
  and 0051 forbid combining those single-language results into `.16` evidence.
  `git log -S'IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.6-BOOK-SYNC' --
  doctrine/live_document_size/surfaces.jsonl` identifies the clean current
  mdBook aggregate authority at 53 files / 49,271 lines / 2,604,665 bytes.
- [x] **ADDRESSED (verified)** — `.16` remains proposed with exact unavailable-
  tool evidence; `.17` and documentation-only `.17.1` are active, and later
  generation, measurement, cap, and closeout work has separate proposed
  children. Authority
  `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17-ACTIVATION-BOOK-SYNC`
  records the exact +0 files / -34 lines / -2,676-byte book delta. The public
  chapter replaces stale commit chronology with current capability and scale
  boundaries; the canonical fact card shrinks while adding two exact queries.
- [x] **NO REGRESSION** — `mdbook build docs/book` and `knowledge-map: OK` must
  pass; both census queries must resolve to the canonical architecture card;
  the generated book output must be removed; and the staged doctrine gate must
  report `[doctrine] all doctrine checks passed`. No parser, IR, bridge,
  generator, fixture, artifact, runtime, capability, support, or scale claim
  changes in activation.

## Acceptance Checklist (enforced) — `.15.5` activation and NEXSIM deferral

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'blocked until exact GHDL
  6.0.0 is available' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  `9729f1f0c`, which records the now-stale availability blocker. The clean
  predecessor has no PNT-eligible leaf because `.13.3` and the NEXSIM
  amendment tree await future releases. The director
  explicitly defers NEXSIM-dependent work. Official GHDL release metadata now
  exposes exact macOS ARM64 LLVM asset
  `ghdl-llvm-6.0.0-macos15-aarch64.tar.gz`, 42,445,801 bytes, SHA-256
  `69beb5913a490b5971980bd045af6a63b6f52e861b444fa990bffac436587478`,
  so the old availability blocker is stale.
- [x] **ADDRESSED (verified)** — `.13.3` and the standalone NEXSIM amendment
  tree are explicitly deferred with reactivation conditions; `.15.5` alone is
  active. The task index, canonical audit, two mdBook views, three fact cards,
  and bounded Memory agree that provider installation and execution remain
  unperformed in this transition. Task integrity reports three active trees
  and 916 nodes; Memory is 40 lines.
- [x] **NO REGRESSION** — `knowledge-map: OK` reports 1,105 facts, 5,706
  unique questions, 5,872 answer occurrences, and 118 shards. All 52 mdBook
  chapters test, `git diff --check` passes, and `scripts/check_doctrines.sh`
  reports `[doctrine] all doctrine checks passed`. No compiler/runtime source,
  generated product
  artifact, installed provider byte, capability state, or support claim
  changes.

## Acceptance Checklist (enforced) — `.15` activation/decomposition

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'pending GHDL or selected
  analyzer/simulator availability' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  architecture commit `2e2f7d25e`, where monolithic `.15` made the whole VHDL
  backend appear to wait on an analyzer. Selection commit `e5aa90b7a` proves
  deterministic provider-free emission/review is independent from unavailable
  GHDL/OSVVM execution and supplies the exact contract to decompose.
- [x] **ADDRESSED (verified)** — `.15` now owns seven bounded children:
  `.15.1-.15.4` cover provider-free emitter foundation, portable execution
  structures, checking/results, and matrix/review closure; `.15.5` owns exact
  GHDL 6.0.0 qualification; `.15.6-.15.7` own OSVVM 2026.05 emission and
  qualification. Only `.15.1` is active. Task index, audit, book, fact card,
  bounded Memory, and exact 50/48,269/2,556,230 book authority agree.
- [x] **NO REGRESSION** — The canonical focused suite reports `All tests
  successful` at `Files=6, Tests=65`; all 49 mdBook chapters test and the
  repository-local 85-file/16,888,889-byte HTML build renders the new prose as
  distinct `<p>` blocks before exact removal. Task integrity is three trees/
  914 nodes/one segment/one index archive; live containment covers 22 surfaces
  and 2,943/2,943 paths with zero ceiling increases; Knowledge Map is current
  at 1,104 facts/5,656 questions/5,822 occurrences/117 shards; Memory is 47
  lines. No implementation, artifact, analyzer, elaboration, runtime, result,
  parity, provider, or product-support behavior changes.

## Acceptance Checklist (enforced) — `.14` selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'vhdl_methodology_qualified'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md
  docs/book/src/16d-hial-vial-verification-architecture.md` identifies
  architecture commit `2e2f7d25e`, whose VHDL profile deliberately left
  OSVVM/UVVM/provider-free selection open. Local inspection confirms the only
  current VHDL verification artifact is an inert metadata package and no
  `ghdl`, `nvc`, or `vsim` command is installed. Separately, `git log
  -S'1018 members' --oneline -- t/1569-focused-document-containment.t`
  identifies `6463779be`; the live generated index already contained 1,019
  members, so the hard-coded census was one behind before this selection.
- [x] **ADDRESSED (verified)** — Decision `0051` and the canonical audit now
  freeze provider-free IEEE 1076-2008, exact GHDL 6.0.0, OSVVM 2026.05,
  audited-unselected UVVM 2026.03.20, semantic-family mappings, inactive-edge
  scheduling, four-state normalization, source-mapped artifacts, exact
  command/gate families, recursive provider locality, PSL limits, broader
  profiles, and parallel legacy migration. The existing bounded VHDL fact card
  is updated instead of increasing card count, and the focused-index oracle now
  matches its preexisting 1,019-member projection. The maintained-reference
  authority accepts exactly 50/48,257/2,555,512 after delta 0/+156/+6,986.
- [x] **NO REGRESSION** — The legacy package/capability suite and focused
  docs/task/containment/Knowledge Map suite both report `All tests successful`
  at `Files=2, Tests=6` and `Files=6, Tests=65`. All 49 mdBook chapters test;
  the repository-local HTML build has 85 files/16,885,255 bytes, with the new
  section rendered into separate headings, `<p>`, table, and code blocks,
  before exact removal. Live containment covers 22 surfaces and 2,942/2,942
  paths, maintained-reference authority accepts one exact change, and ceiling
  authority reports zero increases. Task integrity is three trees/907 nodes/
  one segment/one index archive; `knowledge-map: OK` reports 1,104 facts/5,656
  questions/5,822 occurrences/117 shards; Memory is 47 lines. No generated
  backend, GHDL/OSVVM materialization, analysis, elaboration, run, result,
  parity, PSL, or public support claim exists.

## Acceptance Checklist (enforced) — `.14` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies architecture-selection commit `2e2f7d25e`; `git show
  adc88817e:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` records
  completed `.13.2`, provider-blocked `.13.3`, and proposed dependency-ready
  `.14`. Therefore `.14` is the next unblocked PNT leaf and requires a clean
  continuity-only activation before methodology or tool investigation.
- [x] **ADDRESSED (verified)** — Durable ownership surfaces alone now mark
  `.14` active: task node/frontier/open-question/blocker records, task index,
  canonical audit, mdBook status, fact card/Knowledge Map, bounded Memory,
  commit log, and maintained-reference authority. No methodology, provider,
  version, command, package migration, backend, artifact, or capability is
  selected or implemented.
- [x] **NO REGRESSION** — The focused docs/live/task/Knowledge Map suite reports
  `All tests successful` at `Files=6, Tests=76`; all 49 mdBook chapters test,
  and its repository-local build contains 85 files/16,588 KiB before exact
  removal. Rendered HTML places the activation in its own `<p>` block. Task
  integrity remains three trees/907 nodes/one segment/one index archive; all
  22 live surfaces and 2,942/2,942 paths pass with exact mdBook delta
  0/+5/+294 and zero ceiling increases. Knowledge Map remains current at 1,104
  facts/5,641 questions/5,807 occurrences/117 shards; Memory is 46 lines; the
  book build is absent. Final staged acceptance passes with `root=git_history`
  and `no-regression=prove_summary`; all nine doctrine checks report
  `[doctrine] all doctrine checks passed`. Generated source, review/probe
  evidence, discovery/support truth, and every VHDL analysis-through-parity
  claim remain unchanged.

## Acceptance Checklist (enforced) — `.13.2` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — clean activation predecessor
  `74815a4fd90aa5386b29a8d3f0642792ad33ea85` leaves the first selected native
  UVM gallery intentionally unparsed and uncompiled. Exact Verilator/UVM
  control and full-fixture runs must establish whether each failure is a
  generator defect, selected-tool limitation, host dependency, or unexercised
  stage without promoting experiment evidence into support. The first strict
  generated-fixture run reports `%Error-UNSUPPORTED` at the ranged-SVA delay,
  while the earlier repaired run identified the illegal generated identifier;
  these concrete compiler loci require separate tool and generator ownership.

- [x] **ADDRESSED (verified)** — exact selected profile/source identities,
  immutable-source verification, bounded repository-local process/staging,
  explicit `UVM_NO_DPI` and attempt-local `--bbox-unsup` deviations, independent
  stage records, canonical report/check workflow, legal `vial_context`
  generation, refreshed gallery, capability/support truth, task/fact/book
  explanation, and deterministic cleanup are implemented. The canonical run
  separates five passed UVM-control stages plus fixture preprocessing from the
  unsupported ranged-SVA parser result, Verilator internal fault/139, and
  not-run fixture runtime/result/parity stages.

- [x] **NO REGRESSION** — all changed Perl, script, and test paths report
  syntax OK. The guarded canonical probe and an independent `--check` rerun
  prove byte-identical normalized evidence. Focused native/probe evidence
  reports `All tests successful` at `Files=6, Tests=44`; the impacted
  VIAL/support suite passes at `Files=16, Tests=7,183`; and docs/history passes
  at `Files=12, Tests=70`. All 49 mdBook chapters test, and the rendered prose
  inspection shows separate paragraphs around the new section; its
  repository-local 85-file/16,584-KiB build is removed exactly. Task integrity
  remains three trees/907 nodes/one segment/one index archive. All 22 live
  surfaces and 2,942/2,942 paths pass with exact mdBook delta 0/+65/+3,370 and
  zero ceiling increases. Knowledge Map is current at 1,104 facts/5,641
  questions/5,807 occurrences/117 shards; Memory is 46 lines. The exact probe
  staging tree, manual reports, UVM source cache, and book build are absent.
  Final staged acceptance and all nine doctrine checks pass before commit.

## Acceptance Checklist (enforced) — `.13.2` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.2'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies selection commit `67778a49d`. `git show
  7725789a4:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` records
  completed `.13.1` and proposed dependency-ready `.13.2`; the same clean
  predecessor records that no background job or uncommitted work remains.
  Therefore the exact experimental feasibility-probe leaf is the next
  dependency-closed PNT frontier and requires a continuity-only activation
  before tool/library inspection or implementation.
- [x] **ADDRESSED (verified)** — Durable ownership surfaces alone now mark
  `.13.2` active: the task node/frontier/open-question/blocker records, task
  index, canonical audit, mdBook status, fact card/Knowledge Map, bounded
  Memory, commit log, and exact maintained-reference authority. No tool or UVM
  source variant is selected and no implementation or probe result is added.
- [x] **NO REGRESSION** — Measured docs/live/task/mdBook/Knowledge Map/Memory,
  and repository-local build-cleanup evidence passes. The focused suite reports
  `All tests successful` at `Files=6, Tests=76`; all 49 chapters test; the
  rendered build has 85 files/16,788,798 bytes before removal and its new
  activation prose is a distinct HTML paragraph. Task integrity remains three
  trees/907 nodes/one segment/one index archive; all 22 live surfaces and
  2,941/2,941 paths pass; the first live check correctly rejected a 48-line
  Memory pointer at the 80% warning boundary, then bounded wording restored 47
  lines and the rerun passed. Knowledge Map is current at 1,104 facts/5,635
  questions/5,801 occurrences/117 shards; exact mdBook growth is 0/+5/+305;
  build output is absent. Final staged acceptance passes with
  `root=git_history` and `no-regression=prove_summary`; all nine doctrine checks
  report `[doctrine] all doctrine checks passed`.
  Generated source, gallery bytes, capabilities, visual-review state, and every
  preprocessing-through-parity/product-support claim remain unchanged.

## Acceptance Checklist (enforced) — `.13.1.5` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — Clean activation predecessor
  `e173ae1f4a614a31fa4735e06f4d767b9bfd33e7` records emitter revision 4.
  `git log -S'SVUVMReviewClosure' --oneline --all --
  perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm
  perl/FSM/VIAL/Backend/SVUVMReviewClosure.pm` returns no committed match,
  while the revision-4 pickaxe identifies implementation commit `193d170e0`.
  `git show <predecessor>:perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm`
  contains no selected-mapping-matrix, review-workflow, or review-closure
  implementation, and the corresponding `SVUVMReviewClosure.pm` object does
  not exist in that tree. The emitter advertises 25 selected foundations but
  has no machine-readable one-to-one source/IR/role/state accounting or
  repository command that can reject gallery drift without writing files.
- [x] **ADDRESSED (verified)** — Emitter revision 5 adds an exact closed
  review-closure API and two canonical JSON artifacts. Its 25 rows equal the
  manifest emitted-foundation set; distinguish normal/terse public source,
  compiler-owned IR, and private previews with exact unsupported reasons; and
  retain independent emission, structural, visual, and qualification states.
  The seven-stage workflow gives repository-relative regenerate/check commands,
  nine source and two evidence examples, exact durable defect fields, and
  separate pending visual, experimental compile, and qualified-runtime stages.
  `--check` performs no write and rejects missing, extra, or byte-drifted
  snapshots. Five internal invariants and direct malformed-input oracles fail
  closed. Focused native evidence reports `All tests successful` at
  `Files=5, Tests=38`.
- [x] **NO REGRESSION** — Revision 5 retains ten generated SystemVerilog
  sources, 75 complete source-map entries, and 14 structural checks while
  expanding only the evidence graph from 14 to 16 artifacts. Capability,
  language-surface, regression-corpus, and live-document assertions report
  `All tests successful` in the focused gate at `Files=7, Tests=7,125` and in
  bounded broader partitions totaling `Files=13, Tests=7,168`. Portable
  execution and parity independently pass at `Files=1, Tests=5` and `Files=1,
  Tests=4`. Documentation/task/live/history/Knowledge Map evidence passes at
  `Files=12, Tests=101`; all 49 mdBook chapters test, and the repository-local
  build contains 85 files/16,787,078 bytes before exact removal. Task integrity
  remains three trees/907 nodes/one segment/one index archive; live containment
  accepts all 22 surfaces and 2,941/2,941 paths; the Knowledge Map is current at
  1,104 facts/5,635 questions/5,801 occurrences/117 shards; Memory is 47 lines.
  Canonical workflow evidence
  contains no simulator-provider name; the legacy UVM 1.2 target remains a
  separate unchanged contract. Final staged acceptance passes with
  `root=git_history` and `no-regression=prove_summary`; all nine doctrine checks
  report `[doctrine] all doctrine checks passed`. Visual review, preprocessing, parse,
  library/fixture compile, elaboration, runtime, result, parity, and full UVM
  breadth remain explicitly pending, not run, not produced, or unclaimed.

## Acceptance Checklist (enforced) — `.13.1.5` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.5' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  selection commit `67778a49d`, while `git show
  193d170e0:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` records
  `.13.1.4` done and `.13.1.5` proposed with implementation pending. The clean
  predecessor therefore leaves exactly the selected mapping-matrix, examples,
  review-workflow, compatibility, and deferred-runtime-defect leaf ready for a
  continuity-only activation.
- [x] **ADDRESSED (verified)** — Only durable ownership/continuity surfaces now
  mark `.13.1.5` active: its task node, current-frontier narrative, index,
  canonical audit, mdBook status paragraph, fact card/Knowledge Map, bounded
  Memory, and exact maintained-reference authority. Implementation acceptance,
  visual-review evidence, and all capability/non-claims are unchanged. The
  exact mdBook transition is `50/47,979/2,542,179 ->
  50/47,980/2,542,230`, or `0/+1/+51`.
- [x] **NO REGRESSION** — The focused docs/live/task/Knowledge Map suite reports
  `All tests successful` at `Files=6, Tests=76`; all 49 mdBook chapters test and
  the repository-local build contains 85 files/16,768,886 bytes before exact
  removal. Task integrity remains three trees/907 nodes/one segment/one index
  archive; live containment accepts all 22 surfaces and 2,941/2,941 paths with
  zero ceiling increases; Knowledge Map is current at 1,104 facts/5,633
  questions/5,799 occurrences/117 shards; Memory is 45 lines; the build
  destination is absent. Final staged acceptance and all nine doctrine checks
  pass. No implementation, generated artifact, public capability, visual-
  review evidence, parser, compile, elaboration, runtime, result, or parity
  behavior changes.

## Acceptance Checklist (enforced) — `.13.1.4` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — Clean activation predecessor
  `22d0f6a2e` retained emitter revision 3. `git log -S'class
  base_output_arbitration_write_scoreboard' --oneline --all --
  perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm` returns no commit, proving
  that the native artifact graph had no covergroup, bound checker,
  deterministic model, typed scoreboard, declared fault application,
  diagnostic aggregation, or structured result snapshot. `git log
  -S'_notification_predicate'` locates the helper in `82088adb8`; inspection
  found it accepting only whole-nibble fully-known masks. One- and two-bit
  known masks render as `1` and `3`, not `f`, so their otherwise selected
  notification predicates were silently omitted. The defect belongs to the
  active native-emitter leaf, not to an unavailable simulator.
- [x] **ADDRESSED (verified)** — Emitter revision 4 produces the exact
  fourteen-artifact/ten-SystemVerilog-source graph, 75 complete source-map
  entries, 14 static checks, and nine byte-locked UVM-facing gallery sources.
  Public `stall_seen` coverage, two event-counter models, the capacity-four
  `writes` scoreboard, expected-item construction, one-drive-interval
  `size=3'b111` substitution, property/diagnostic collection, bound SVA, and
  in-memory result snapshots are structurally and negatively checked.
  Width-aware literal validation restores the accepted/held/error predicates.
  Focused support/native evidence reports `All tests successful` at
  `Files=6, Tests=7118`; the exact mdBook change is
  `50/47,932/2,539,789 -> 50/47,979/2,542,179`, or `0/+47/+2,390`.
- [x] **NO REGRESSION** — The RAM-guarded semantic/native/support suite reports
  `All tests successful` at `Files=12, Tests=7161`; separately captured
  portable Verilator execution and AHB parity pass at `Files=1, Tests=5` and
  `Files=1, Tests=4`. Documentation/task/live/history/Knowledge Map tests pass
  at `Files=12, Tests=111`; all 49 mdBook chapters test and the repository-local
  HTML build contains 85 files/16,768,599 bytes before exact removal. Task
  integrity remains three trees/907 nodes/one segment/one index archive; live
  containment accepts all 22 surfaces and 2,941/2,941 declared paths with zero
  ceiling increases; Knowledge Map is current at 1,104 facts/5,633 questions/
  5,799 occurrences/117 shards; Memory is 44 lines. Final staged acceptance
  and all nine doctrine checks pass. Parse, compile, elaboration, native
  runtime/result/parity, probe-backed expectation execution, and visual-review
  completion remain explicitly unclaimed.

## Acceptance Checklist (enforced) — `.13.1.4` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.4' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  selection commit `67778a49d`, while `git show
  6463779be:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` records
  `.13.1.3` done and `.13.1.4` proposed with verification pending after
  `.13.1.3`. The clean implementation predecessor therefore leaves exactly the
  selected coverage/property/model/scoreboard/fault/diagnostic/result leaf
  ready for a continuity-only activation before any implementation.
- [x] **ADDRESSED (verified)** — Only durable ownership/continuity surfaces now
  mark `.13.1.4` active: its task node, current-frontier narrative, index,
  canonical audit, mdBook status paragraph, fact card/Knowledge Map, bounded
  Memory, and exact maintained-reference authority. The implementation
  acceptance and all capability/non-claims are unchanged. The exact mdBook
  transition is `50/47,932/2,539,798 -> 50/47,932/2,539,789`, or `0/0/-9`.
- [x] **NO REGRESSION** — The focused docs/live/task/Knowledge Map suite reports
  `All tests successful` at `Files=6, Tests=71`; all 49 mdBook chapters test and
  the repository-local build contains 85 files/16,751,669 bytes before exact
  removal. Task integrity remains three trees/907 nodes/one segment/one index
  archive; live containment accepts all 22 surfaces and 2,941/2,941 paths with
  zero ceiling increases; Knowledge Map is current at 1,104 facts/5,630
  questions/5,796 occurrences/117 shards; Memory is 47 lines; the build
  destination and operation-staging census are empty. Final staged acceptance
  and all nine doctrine checks pass. No implementation,
  generated artifact, public capability, parser, compile, elaboration, runtime,
  result, or parity behavior changes.

## Acceptance Checklist (enforced) — `.13.1.3` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation predecessor
  `b91c68140`, `git log -S'class
  base_output_arbitration_ahb_write_item' --oneline --all --
  perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm` returns no commit. Emitter
  revision 2 contains only a passive agent and has no sequence item, sequence,
  sequencer, driver, typed analysis/TLM services, factory override, scoped
  service configuration, RAL mapping, or constrained-decision UVM structure.
  During the broader documentation gate, `t/1569` also expected 1,017 focused/
  ancillary members although `scripts/focused_document_index.pl check` and the
  committed index have reported 1,018 since `.13.1.1` commit `5a1805f52`; the
  exact stale one-line oracle, not this slice's document membership, caused the
  isolated failure.
- [x] **ADDRESSED (verified)** — `prove -Iperl
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t
  t/1560-vial-native-uvm-emitter-substrate.t
  t/1570-vial-native-uvm-topology-lifecycle-notification.t
  t/1580-vial-native-uvm-stimulus-services.t` reports `All tests successful`
  at `Files=5, Tests=7110`. Box-scoped evidence: emitter revision 3 produces
  the exact 12-artifact/8-SystemVerilog-source graph and 64-entry source map;
  all 12 static checks pass; seven UVM-facing gallery sources regenerate
  byte-identically; active typed stimulus, portable decision replay, driven/
  observed analysis TLM, exact non-wildcard configuration, a compiler-selected
  driver override, and private RAL/native-solver previews are present. Negative
  oracles reject wildcard configuration, missing service/RAL/TLM wiring, and
  generated native-solver execution. The focused-index count oracle now matches
  the unchanged authoritative 1,018-member projection and passes at
  `Files=1, Tests=6`.
- [x] **NO REGRESSION** — Both changed backend modules report `syntax OK`; the
  deterministic gallery helper reports seven sources, 64 source-map entries,
  and 12 checks. RAM-guarded semantic/bridge/execution/tooling/planning plus
  portable/native/support suites pass in two exact groups totaling
  `Files=11, Tests=7153`. Sequential RAM-guarded portable execution and AHB
  parity pass at `Files=1, Tests=5` and `Files=1, Tests=4`; two earlier tool-
  session yields left overlapping tests alive, their exact collisions were
  root-caused by process census, all processes were consumed, staging became
  empty, and clean sequential reruns passed. Ten documentation/task/live/
  history/Knowledge Map tests pass at `Files=10, Tests=91`, and the corrected
  focused-index test passes at `Files=1, Tests=6`. All 49 mdBook chapters test;
  the repository-local build contains 85 files/16,751,666 bytes before exact
  removal. Task integrity is three trees/907 nodes/one segment/one index
  archive; live containment accepts all 22 surfaces and exact mdBook delta
  `0/+35/+1,692` with zero ceiling increases; Knowledge Map is current at 1,104
  facts/5,630 questions/5,796 occurrences/117 shards; Memory is 47 lines.
  Final staged acceptance and all nine doctrine checks pass with zero ceiling
  increases; the mdBook destination and VIAL operation-staging census are
  empty.
  Parse, compile, elaboration, native runtime/result/parity, visual-review
  completion, public RAL/factory authoring, and later native-UVM breadth remain
  unclaimed.

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

## Acceptance Checklist (enforced) — `.15.1` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean activation predecessor
  `9729f1f0c`, `git log -S 'dut_vhdl' -- perl/FSM/VIAL/PlanBuilder.pm` returns
  no commit. The bridge already published exact VHDL entity and port bindings,
  and the HIAL generator already produced VHDL, but `PlanBuilder` retained only
  `dut_systemverilog`. No private VHDL emitter, structural validator,
  discoverable capability contract, atomic graph, or review gallery existed,
  so the selected `.15.1` foundation had identities but no compiler handoff or
  artifact owner.
- [x] **ADDRESSED (verified)** — `PlanBuilder` now deterministically retains
  both generated HDL families with exact entity/unit/file/hash/byte metadata.
  `VHDLPortableGHDL` and `VHDLPortableStaticValidator` emit and validate the
  thirteen-artifact/five-VHDL-source foundation, five complete source-map
  records, typed value/phase/original-symbol and logical-time/runtime packages,
  fixture metadata, direct named entity/port binding, ordered sources, exact
  selected-but-unexecuted GHDL 6.0.0 commands, seven structural checks, and
  explicit parallel legacy migration. The support contract, regression
  corpus, byte-locked gallery/checker, fail-closed negatives, atomic
  publication/collision behavior, and exact cleanup are exercised by focused
  t1593.
- [x] **NO REGRESSION** — The guarded impacted suite reports `All tests
  successful` at `Files=12, Tests=7164`, and the guarded documentation-doctrine
  suite reports `All tests successful` at `Files=15, Tests=133`. Final syntax,
  task-tree, Knowledge Map, mdBook test/build/render, live-document containment,
  diff, staged acceptance, doctrine, and residue gates are recorded in the
  `.15.1` verification-log row above. The legacy
  `vhdl-observation-package` remains byte/schema-compatible and unconsumed;
  canonical generated VHDL contains no simulator/methodology provider branch;
  ordinary emission fetches no provider; and analysis, elaboration, runtime,
  result, parity, PSL, complete VHDL-2008, OSVVM/UVVM, mixed-language behavior,
  and product support remain explicitly unclaimed.

## Acceptance Checklist (enforced) — `.15.2` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean predecessor `3291217e8`,
  `git log -S'vial_scheduler' --oneline --
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm` returns no commit, while `git show
  3291217e:perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm` names
  `drivers_deferred`, `samplers_deferred`, `scheduler_deferred`,
  `scenarios_deferred`, `models_deferred`, and `probe_adapters_deferred`. The
  provider-free backend was deliberately bounded to the `.15.1` foundation:
  `base_output_arbitration_tb.vhd` had no process, its source map contained
  only five whole-source records, and the seven structural checks did not
  express or police any execution semantics. The selected portable contract
  therefore still lacked typed drivers/samplers, one stable inactive-edge
  authority, scenario/fiber/model state, and a source-mapped declared-probe
  adapter even though the bound `VIALExecutionIR` and bridge already carried
  the required identities.
- [x] **ADDRESSED (verified)** — `VHDLPortableGHDL` now emits an exact
  fourteen-artifact/six-source provider-free graph with 52 source-map entries:
  typed strong four-state drivers, samplers retaining each original
  `std_logic` symbol, one falling-edge inactive barrier, fixed
  sample/react/check/drive phase order, all 21 exact operation ranks, two
  bounded scenarios, four fibers, two deterministic event-counter models, and
  one declared VHDL-2008 external-name probe adapter. Thirteen structural
  checks and negotiation negatives reject zero-time or process-order semantic
  authority, multiple schedulers, rank drift, undeclared hierarchy, nine-state
  requirements, multiple domains, asynchronous semantic events, provider
  leakage, and malformed inputs. The checked gallery regenerates six VHDL
  sources and eight evidence artifacts byte-for-byte.
- [x] **NO REGRESSION** — The focused semantic/accounting/capability suite
  reports `All tests successful` at `Files=3, Tests=7104`; all changed Perl
  modules, the gallery script, and focused test report `syntax OK`; and the
  gallery checker reports six VHDL sources, eight evidence artifacts, 52 maps,
  and 13 checks. Final impacted/doc/mdBook/Knowledge Map/doctrine evidence is
  recorded in the `.15.2` verification-log row. The legacy
  `vhdl-observation-package` remains unchanged and unconsumed, ordinary
  emission remains provider-free, and VHDL analysis, elaboration, runtime,
  checking/result production, parity, PSL, complete VHDL-2008, OSVVM/UVVM,
  mixed-language behavior, and product support remain explicitly unclaimed.

## Acceptance Checklist (enforced) — `.15.3` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — On clean completed `.15.2` predecessor
  `d37b2920e`, `perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm` still declared
  `scoreboards_deferred`, `coverage_deferred`, `faults_deferred`,
  `properties_deferred`, `trace_deferred`, and `results_deferred`; the check
  phase was a comment-only placeholder. The generated unsupported-size
  scenario did not apply its authored injection, and the 13-check validator
  had no overflow, unknown-evidence, closure, or result-consistency oracle.
  Generated-source review of the initial checking implementation also exposed
  C-style `\"` escaping, which is not valid VHDL string syntax, without a
  structural rejection for that form. `git log -S'scoreboards_deferred'
  --oneline -- perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm` locates foundation
  commit `3291217e8` as the deferred-state introduction.
- [x] **ADDRESSED (verified)** — The same provider-free six-source graph now
  emits one capacity-four scoreboard, exact stalled/not-stalled counters, the
  bounded immutable-source size substitution, procedural success/ERROR/
  timeout/unknown checks, bounded stored diagnostics, closed logical-time trace
  framing, and a full top-level `fsmgen.verification_result_manifest.v1`
  projection with explicit unproduced identity/parity fields. JSON is emitted
  with VHDL-native quote doubling. Fifty-nine maps cover
  the seven new semantic regions; twenty structural checks and focused
  mutations reject missing overflow evidence, unknown evidence, trace closure,
  C-style JSON escaping, result consistency, unsupported PSL/provider text,
  and undeclared probes.
  The capability contract and byte-locked gallery carry the same honest
  emission-only boundary.
- [x] **NO REGRESSION** — Focused VHDL, capability-manifest, and regression-
  accounting suites report `All tests successful` at `Files=12, Tests=7164`;
  the gallery checker regenerates six VHDL sources,
  eight evidence artifacts, 59 maps, and 20 checks. Final impacted regression,
  syntax, task-tree, Knowledge Map, mdBook, live-document, staged acceptance,
  doctrine, and residue evidence is recorded in the `.15.3` verification-log
  row. GHDL analysis, elaboration, runtime, produced-result validation, parity,
  PSL, OSVVM/UVVM, mixed-language behavior, and product support remain
  explicitly unclaimed; the legacy inert package remains unchanged.

## Acceptance Checklist (enforced) — `.15.4` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — Clean predecessor `033c72f88` completed
  portable checking but `git show
  033c72f88:perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm` contains no
  `mapping_matrix`, `review_workflow`, or `migration_proof`; its only closure
  state is `emitted_unqualified_portable_checking` plus the declarative
  `legacy_state=unchanged_not_consumed`. `git log -S'emitted_unqualified_portable_checking'
  --oneline --
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm` identifies exact predecessor
  `033c72f88`. Thus selected mappings, entry-point ownership, reproducible
  visual-review/defect routing, and byte/schema/HIAL separation were assertions
  rather than closed machine-readable evidence.
- [x] **ADDRESSED (verified)** — `VHDLPortableReviewClosure` now emits a closed
  24-row matrix (20 emitted representatives and four exact unsupported
  boundaries), distinguishes public normal/terse source, compiler-owned
  ExecutionIR/bridge data, and unavailable private previews, and publishes a
  seven-stage repository-relative workflow with exact task-tree defect fields.
  The third evidence artifact locks the 976-byte inert legacy fixture and its
  path-independent manifest projection, proves the emitted HIAL DUT
  byte-identical to its private handoff and isolated under `src/dut`, and
  rejects legacy imports/artifacts. Seven closure invariants, direct API
  mutations, the 17-artifact byte-locked gallery, capability/support/corpus
  accounting, audit, mdBook, fact card, and continuity all expose the exact
  emitted/structurally-reviewed/visual-pending/unqualified state.
- [x] **NO REGRESSION** — The final guarded focused/impacted suite reports
  `All tests successful` at `Files=13, Tests=7172`; exact gallery, legacy,
  syntax, mdBook, task-tree, Knowledge Map,
  live-document, staged-acceptance, doctrine, and residue evidence are recorded
  in the `.15.4` verification-log row below. The six generated VHDL sources,
  59 source-map entries, and 20 structural checks remain byte/shape checked;
  VHDL analysis, elaboration, runtime, produced-result validation, parity,
  visual-review completion, PSL, OSVVM/UVVM, mixed-language behavior, and
  product support remain explicitly unclaimed.

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
| `.13.1.3` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.3: ship native UVM stimulus and services` | Ship the active typed stimulus path, portable decision replay, typed TLM, exact scoped factory/configuration plumbing, private RAL/native-solver previews, 64-entry source map, 12 static checks, and seven-source gallery without a parser/runtime/public-authoring claim. |
| `.13.1.4` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.4: activate native UVM checking and results` | Activate only representative coverage/property/model/scoreboard/fault/diagnostic/result emission after clean completed `.13.1.3`; implementation remains unperformed. |
| `.13.1.4` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.4: ship native UVM checking and results` | Ship revision-4 coverage, bound SVA, deterministic models, bounded scoreboard, declared fault application, property/diagnostic/result collection, 75-entry source map, 14 static checks, and nine-source gallery without a parser/runtime/result claim. |
| `.13.1.5` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.5: activate native UVM matrix and review closure` | Activate only mapping-matrix, examples, review-workflow, compatibility, and deferred-runtime-defect closure after clean completed `.13.1.4`; implementation and visual-review evidence remain unperformed. |
| `.13.1.5` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.5: close native UVM matrix and review workflow` | Ship revision-5 selected-scope accounting through a 25-row matrix, deterministic seven-stage gallery workflow, non-mutating byte check, exact defect routing, and two canonical evidence snapshots while retaining every visual/parser/runtime/full-breadth non-claim. |
| `.13.2` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.2: activate experimental UVM probe` | Activate only exact open-source tool/library inspection and reusable experimental probe implementation after clean completed `.13.1`; selection, execution, and support evidence remain unperformed. |
| `.13.2` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.2: ship exact experimental UVM probe` | Ship the exact bounded Verilator/UVM probe and deterministic report, repair the generated reserved-keyword identifier, and retain tool-limited fixture/runtime/result/parity nonclaims without product support. |
| `.14` activation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14: activate VHDL verification contract` | Activate only VHDL-2008 methodology-provider, portable/qualified profile, legacy-package migration, and capability/non-claim contract selection after clean `.13.2`; selection and product behavior remain unperformed. |
| `.14` selection | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14: select VHDL OSVVM architecture` | Accept decision `0051`; select provider-free VHDL-2008, exact unexecuted GHDL 6.0.0 and OSVVM 2026.05 tiers, explicit mappings/PSL limits, and a parallel versioned successor to the unchanged inert package without a runtime claim. |
| `.15` activation/decomposition | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15: activate VHDL backend implementation` | Activate `.15` and provider-free emitter/gallery child `.15.1`; separate portable emission/review, exact GHDL execution, and OSVVM emission/qualification into seven evidence-bounded children without changing product behavior. |
| `.15.1` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.1: ship portable VHDL foundation` | Ship deterministic HIAL VHDL handoff, a private thirteen-artifact/five-source provider-free foundation, complete foundation maps, seven structural checks, exact unexecuted GHDL records, atomic publication, honest capability states, and a byte-locked gallery while retaining every runtime/support non-claim. |
| `.15.2` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.2: ship portable VHDL semantics` | Ship typed drivers/samplers, one inactive-edge scheduler, exact operation ranks, bounded scenarios/fibers, deterministic models, a declared probe adapter, 52 complete maps, 13 static checks, and a six-source gallery while retaining every analyzer/runtime/checking/support non-claim. |
| `.15.3` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.3: ship portable VHDL checking` | Ship the capacity-four scoreboard, both coverage bins, bounded substitution fault, procedural checks, diagnostics, closed trace and normalized-result projections, 59 complete maps, 20 static checks, and refreshed six-source gallery while retaining every analysis/runtime/produced-result/support non-claim. |
| `.15.4` implementation | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.4: close portable VHDL review` | Close the provider-free profile with a 24-row selected matrix, seven-stage deterministic review/defect workflow, exact legacy/HIAL migration proof, seven fail-closed invariants, and a 17-artifact gallery while retaining visual-review and analysis-through-support non-claims. |
| `.13.3` provider clarification | `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.3: capture NEXSIM semantic-introspection MCP contract` | Record the future versioned NEXSIM semantic API/MCP qualification plane, snapshot/control/query requirements, source-mapped checkpoint correlation, first-divergence localization, and provider-evidence boundary without inventing a release or activating runtime work. |

## Changelog

- `2026-08-02`: Completed `.15.4` closes provider-free VHDL emission review.
  The 17-artifact graph retains six VHDL sources/59 maps/20 structural checks
  and adds three canonical evidence files: a 24-row matrix with 20 emitted and
  four exactly unsupported boundaries, a seven-stage deterministic review and
  durable-defect workflow, and an exact inert-legacy/HIAL separation proof.
  Seven internal invariants and direct mutations reject role, entry-point,
  reason, workflow, legacy-import, HIAL-identity, and qualification drift.
  Visual review and analysis through support remain pending or unclaimed;
  `.15.5` remains blocked on exact GHDL 6.0.0 and `.15.6` on exact project-local
  OSVVM 2026.05 materialization.

- `2026-08-02`: Completed `.15.3` adds the capacity-four scoreboard, both
  portable coverage bins, one-cycle immutable-source substitution seam,
  procedural success/ERROR/timeout/unknown checks, bounded stored diagnostics,
  closed logical-time trace framing, and the full top-level normalized-result
  projection. The provider-free graph remains fourteen artifacts/six sources
  and expands to 59 maps/20 checks. Structural mutations reject overflow and
  unknown-evidence loss, non-closure, invalid C-style JSON escaping, result
  inconsistency, PSL/provider leakage, and undeclared hierarchy. `.15.4` is
  next for review-matrix closure; analysis through support remains unclaimed.

- `2026-08-02`: Completed `.15.2` expands the provider-free VHDL backend to an
  exact fourteen-artifact/six-source graph with 52 complete source maps and 13
  structural checks. Typed strong drivers, original-symbol samplers, one
  falling-edge inactive barrier, exact ranks, two bounded scenarios, four
  fibers, two deterministic event-counter models, and one source-mapped
  declared external-name probe adapter now ship for review. Negotiation and
  mutation negatives reject nine-state, multi-domain, asynchronous semantic-
  event, multiple/zero-time scheduler, rank-drift, undeclared-hierarchy, and
  provider-leakage requests. `.15.3` is next for checking, results, and closed
  trace; no analysis-through-support claim is inferred.

- `2026-08-01`: Completed `.15.1` ships the private provider-free VHDL-2008
  foundation: deterministic HIAL VHDL handoff, thirteen sorted artifacts, five
  sources/maps, seven structural checks, exact unexecuted GHDL 6.0.0 records,
  atomic publication/collision cleanup, support discovery, and a byte-locked
  gallery. Active `.15.2` next owns drivers, samplers, inactive-edge
  scheduling, scenarios, models, and probe adapters. The inert legacy package
  is unchanged/unconsumed and no analysis-through-support claim is inferred.

- `2026-08-01`: Clean selection predecessor `e5aa90b7a` activates `.15` and
  decomposes seven exact implementation children. `.15.1-.15.4` can ship the
  provider-free emitter and review path without an installed analyzer; `.15.5`
  separately owns GHDL 6.0.0 execution, and `.15.6-.15.7` own OSVVM 2026.05
  emission and qualification. `.15.1` alone is active, with no generated
  artifact, capability, runtime, result, parity, or support change.

- `2026-08-01`: Completed `.14` accepts decision `0051`: portable VHDL is
  provider-free IEEE 1076-2008, OSVVM 2026.05 is the selected advanced
  provider, and GHDL 6.0.0 is the first exact qualification tool. UVVM was
  audited but is not selected. The legacy inert package stays unchanged;
  GHDL/OSVVM absence leaves every analysis-through-runtime claim unshipped and
  proposed `.15` next owns clean activation/decomposition.

- `2026-08-01`: Clean completed experimental-probe predecessor `adc88817e`
  activates `.14` alone for VHDL-2008 methodology/backend contract selection.
  Activation changes only durable continuity; provider, library, tool,
  version, command, legacy-package migration, generated artifacts, and every
  VHDL analysis-through-parity/product-support claim remain unselected or
  unchanged.

- `2026-08-01`: Clean completed-emission predecessor `7725789a4` activates
  `.13.2` alone for exact open-source tool/library inspection and reusable
  experimental UVM feasibility-probe implementation. Activation changes only
  durable continuity; it selects no tool or library, runs nothing, changes no
  generated byte or capability, and preserves every visual-review and parser-
  through-parity/product-support non-claim.

- `2026-08-01`: `.13.1.5` completes the selected native-UVM emission parent.
  Revision 5 retains ten SystemVerilog sources, 75 map entries, and 14 static
  checks while adding a selected-mapping-matrix artifact and deterministic
  review-workflow artifact to form an exact sixteen-artifact graph. Every one
  of 25 emitted foundations has one source/IR/role/state row; nine source and
  two evidence snapshots regenerate or byte-check through repository-relative
  commands. Five closure invariants and negative oracles fail closed. Visual
  review and every parser-through-parity/full-UVM-breadth claim remain pending
  or absent; `.13.2` is next.

- `2026-08-01`: Clean implementation predecessor `193d170e0` activates
  `.13.1.5` alone for the native-UVM mapping matrix, examples, review workflow,
  compatibility, and deferred-runtime defect boundary. Activation changes
  continuity only; implementation, generated artifacts, public capabilities,
  visual-review evidence, and every parser-through-parity claim remain
  unchanged.

- `2026-08-01`: `.13.1.4` ships the revision-4 native-UVM checking/result
  shape. The exact fourteen-artifact graph adds a checking/result package and
  separately bound SVA checker. Public `stall_seen` coverage, two deterministic
  event-counter instances, the capacity-four `writes` scoreboard, exact
  expected-item construction, one-drive-interval `size=3'b111` substitution,
  property/diagnostic collection, and a structured review snapshot are wired
  through typed paths. The width-aware scalar renderer also repairs one- and
  two-bit notification predicates left unexecuted by the former whole-nibble
  mask test. Ten SystemVerilog sources, 75 map entries, 14 checks, and nine
  byte-locked UVM-facing gallery sources ship. Parse through runtime, produced
  results/parity, probe-backed expectation execution, visual-review
  completion, and matrix closure remain unclaimed; `.13.1.5` is next.

- `2026-08-01`: Clean implementation predecessor `6463779be` activates
  `.13.1.4` alone for representative coverage, properties, models,
  scoreboards, faults, diagnostics, and results. Activation changes continuity
  only; implementation, generated artifacts, public capabilities, and every
  parser-through-parity claim remain unchanged.

- `2026-08-01`: `.13.1.3` emits the active native-UVM stimulus and services
  shape. Revision 3 adds a typed write item, two public scenario sequences,
  sequencer/driver, independent driven/observed analysis streams, typed TLM
  FIFOs/subscriber, exact non-wildcard configuration paths, a compiler-selected
  driver override, and a private RAL block/adapter/predictor. Portable decisions
  replay immutable selected values; the bounded native solver preview is never
  invoked by a generated scenario. Twelve artifacts, eight SystemVerilog
  sources, 64 map entries, 12 static checks, and seven byte-locked UVM-facing
  gallery sources now ship. Parse through runtime, visual-review completion,
  public RAL/factory authoring, and remaining native-UVM breadth are unclaimed;
  proposed `.13.1.4` is next but not active.

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

## Acceptance Checklist (enforced) — `.15.5` exact GHDL qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'not_run' --
  perl/FSM/Support/VIALVHDLEmissionContract.pm
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm` locates the structural-only
  predecessor. Exact GHDL execution then exposed VHDL-invalid generated
  identifiers/expressions, reversed positional carriers, a blocked returning-
  ready accept/complete boundary, and an incomplete ERROR settle boundary;
  the exact LLVM AOT backend additionally failed its external-name adapter.
- [x] **ADDRESSED (verified)** — the repository-local LLVM-JIT qualifier
  freezes provider/source/command identities and proves analysis,
  elaboration, bounded runtime, timed `0/1/X/Z`, closed normalized results,
  deterministic reruns, nineteen applicable portable-SV parity paths,
  resource controls, and exact cleanup; capability/support, gallery, mdBook,
  task-tree, Knowledge Map, and Memory are synchronized to that bounded truth.
- [x] **NO REGRESSION** — guarded direct-VHDL regression reports `All tests
  successful` at Files=1/Tests=64. The guarded GHDL/support/parity suite reports
  `All tests successful` at Files=6/Tests=7,119, including a fresh exact
  qualification. Syntax, gallery byte check, `git diff --check`, and exact
  residue checks pass. `knowledge-map: OK` reports 1,105 facts, 5,709 unique
  questions, 5,875 occurrences, and 118 shards; task integrity reports three
  active trees/916 nodes; all 52 mdBook chapters test and the 87-file
  repository-local build passes before exact removal. The final staged
  doctrine result is recorded by the commit workflow.

## Acceptance Checklist (enforced) — `.15.6` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'pending .15.4 and exact
  repository-local OSVVM 2026.05 materialization' --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` locates the
  proposed-only predecessor: completed exact-GHDL `.15.5` left `.15.6` as the
  next clean frontier, so provider materialization could not begin until this
  task/index/book/fact/Memory activation slice made `.15.6` the sole owner.
- [x] **ADDRESSED (verified)** — `.15.6` alone is active for exact recursive
  OSVVM 2026.05 materialization plus bounded adapter/gallery emission;
  `.15.7` remains proposed for combined execution, and this continuity-only
  commit changes no provider bytes, source, generated artifact, capability,
  runtime result, or support behavior.
- [x] **NO REGRESSION** — `knowledge-map: OK` reports 1,105 facts, 5,709
  unique questions, 5,875 occurrences, and 118 shards; task integrity reports
  three active trees/916 nodes; all 52 mdBook chapters test; maintained-
  reference authority accepts the exact 0-file/0-line/+4-byte book delta; and
  the final staged driver reports `[doctrine] all doctrine checks passed`.

## Acceptance Checklist (enforced) — `.15.6` implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'selected_not_materialized_separate_profile' --
  perl/FSM/Support/VIALVHDLEmissionContract.pm` locates the exact predecessor:
  OSVVM 2026.05 was selected but absent, so no recursively verified provider
  identity, advanced adapter, mapping matrix, semantic-preservation proof,
  static negative, gallery, or honest support state could exist.
- [x] **ADDRESSED (verified)** — the official release and all thirteen
  gitlinks are repository-locally installed and locked by commit/tree/origin;
  fourteen licence files, zero notice files, and the Documentation metadata
  absence are exact. Revision-1 emission adds seven advanced mappings beside
  six byte-identical portable sources, thirteen maps, twelve checks, and six
  unchanged-semantic guards without claiming combined execution.
- [x] **NO REGRESSION** — guarded OSVVM/portable/GHDL/parity/support regression
  reports `All tests successful` at Files=6/Tests=36; the non-mutating gallery check
  reports seven VHDL sources, eight evidence artifacts, seven mappings,
  thirteen source-map entries, and twelve static checks. Knowledge Map is
  current at 1,105 facts/5,713 questions/5,879 occurrences/118 shards; task
  integrity reports three active trees/916 nodes; all 52 mdBook chapters test
  and the 87-file/18,073,088-byte repository-local build passes before exact
  removal. Final diff, residue, staged acceptance, and `[doctrine] all doctrine
  checks passed` evidence is recorded by the commit workflow.

## Acceptance Checklist (enforced) — `.15.7` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'pending .15.5 and .15.6' --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` locates the
  proposed-only predecessor. Clean completed commit `4f350f29c` closes both
  prerequisites, so combined qualification still lacked an active owner even
  though both exact inputs were repository-local.
- [x] **ADDRESSED (verified)** — `.15.7` alone is active for exact OSVVM
  2026.05 plus GHDL 6.0.0 LLVM-JIT qualification; this continuity slice
  changes no implementation, generated artifact, qualification evidence,
  capability, runtime result, or support behavior.
- [x] **NO REGRESSION** — `knowledge-map: OK` reports 1,105 facts/5,713
  questions/5,879 occurrences/118 shards; task integrity reports three active
  trees/916 nodes; all 52 mdBook chapters test; maintained-reference authority
  accepts the exact 0-file/0-line/+16-byte delta; diff checks and the final staged
  `[doctrine] all doctrine checks passed` result are recorded by the commit
  workflow.

## Acceptance Checklist (enforced) — `.15.7` exact combined qualification

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'pending .15.5 and .15.6'
  --oneline -- perl/FSM/Support/VIALVHDLEmissionContract.pm` locates selection
  commit `9729f1f0c`; activation commit `03b2f7f76` and the predecessor
  manifest/gallery still marked combined provider compilation, adapter
  analysis, execution, result, parity, reports, and support as not run. Direct
  compilation against the exact installed libraries proved the emitted adapter
  API was sound; the remaining gap was an absent independent tuple qualifier,
  not missing provider bytes or a generated-source defect.
- [x] **ADDRESSED (verified)** —
  guarded `perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check`
  passes and changes the combined tuple from `not_run` to `qualified`.
  `VHDLOSVVMGHDLQualification.pm` freezes exact tool/provider/source identities,
  compiles 44 OSVVM and 17 Common sources, analyzes the generated graph and
  checked probe, elaborates/runs both tops twice, validates the closed 42-record
  trace, passing result, 19 parity paths, and four deterministic OSVVM reports,
  then removes its exact same-volume staging identity. The checked report,
  runner, gallery qualification reference, capability/support accounting, and
  regression-corpus claims all agree on bounded private support and explicit
  non-claims. The rationale ledger and exact focused/ancillary/card/mdBook
  growth authorities are refreshed without increasing an enforcement ceiling.
- [x] **NO REGRESSION** — the final guarded impacted suite reports `All tests successful`
  at `Files=7, Tests=7127`, including fresh standalone and combined
  exact-tool qualification; the combined qualifier subtests contain 42
  assertions. The checked gallery reports seven VHDL sources, nine evidence
  artifacts, seven mappings, thirteen maps, and twelve structural checks.
  Knowledge Map is current at 1,105 facts/5,713 questions/5,879 occurrences/118
  shards; task integrity reports three active trees/916 nodes; all 52 mdBook
  chapters test and the 87-file/18,083,443-byte repository-local build passes
  before exact removal. Final diff, staged acceptance, doctrine, and residue
  results are recorded by the commit workflow.

## Acceptance Checklist (enforced) — `.17.2.6.2.2` sealed provider evaluation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'OSVVM2026_05Materialization->verify'`
  locates origin commit `4f350f29c`: `VHDLOSVVM2026_05->_emit` called the full recursive
  `OSVVM2026_05Materialization->verify` on every valid emission, so two
  emissions rewalked fourteen repositories and 2,122 tracked provider files.
  The focused RED test first bailed out at the absent sealed evaluation
  boundary; no cross-emission authority existed except repeating that call.
- [x] **ADDRESSED (verified)** — `with_provider_evaluation` verifies the exact
  repository-local source once, binds its defensive result and canonical
  provider/source identity to a lexical callback-scoped capability, supplies a
  fresh clone to every matching local emission, and deletes the capability on
  callback success or failure. Exact-count tests prove two local emissions use
  one verification; source mismatch, caller forgery, stale retention, consumer
  failure, and result mutation fail closed without cross-evaluation reuse.
  Standalone `emit` remains independently verified and byte-identical.
- [x] **NO REGRESSION** — syntax checks pass; the 4,096-MiB guarded exact
  t/1598, t/1599, and t/1642 collection reports `All tests successful` at
  `Files=3, Tests=48` in 39 seconds, including a fresh byte-identical combined
  GHDL/OSVVM qualification and exact same-volume cleanup. The subsequently
  strengthened t/1642 passes `Files=1, Tests=46`; its immediate combined guard
  rerun is invalidated before completion at 88.2% host occupancy against the
  fixed 88% cutoff while two unrelated pgen rustc processes hold
  2,538,080/2,061,312 KiB, and no FSMGen residue remains. Knowledge Map reports
  1,150 facts/6,053 questions/6,220 occurrences/133 bounded shards; the compact
  cards remain 127 bytes below their warning milestone. Claim inventory and
  dispositions close all 1,419 candidates with 2,047 governed constants; task
  integrity reports three trees/955 nodes; relative paths and diff checks pass.
  All 53 mdBook chapters test, and the inspected 88-file/18,624-KiB render
  contains the new chapter and print prose before exact removal. The final
  staged acceptance and doctrine gate records the committed-index result. No
  emitted bytes, runtime, public product API, support, performance, or capacity
  claim changes.

## Finding routed after `.17.2.6.2.2` committed cleanly

The first synchronized fact-card wording raised `knowledge_cards` to 3,356,477
bytes, 1,034 bytes beyond its 80% warning milestone while remaining below the
unchanged enforcement ceiling. Declaring the required `warning_debt` state
then made the claim-inventory oracle report 18 new constants inside the
original `surfaces.jsonl` through-line cohort: the baseline reconstructs every
current nested pointer on a pre-existing JSONL line, so it cannot distinguish
new debt fields from original constant identities. Compacting the two existing
cards retains the provider fact at 3,355,316 bytes, 127 bytes below warning,
and removes the immediate state change without widening a bound or deleting a
fact. Clean activation commit `aac2e265c` routes the defect to
`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.30`; completed repair `aa99aad50`
reconstructs the 615-member original cohort from its exact adoption commit and
lets the real 18-field warning-debt declaration remain current-only without
raising an enforcement ceiling.

## Acceptance Checklist (enforced) — `.17.2.6.2.3` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log
  -L 515,555:perl/FSM/VIAL/Backend/VHDLOSVVM2026_05.pm --oneline --no-patch`
  identifies origin commit `4f350f29c`: `_source_map` emits seven exact adapter
  mappings but collapses each of the six reused portable sources to one
  whole-file entry. Completed provider-evaluation repair `189cec95e` and
  containment repair `aa99aad50` leave translation as the ordered clean
  repair-family frontier.
- [x] **ADDRESSED (verified)** — `.17.2.6.2.3` alone is active for complete
  portable-to-OSVVM map translation. This continuity slice changes no emitter,
  generated artifact, validator, runtime, public API, capability/support,
  performance, or capacity behavior; `.17.2.6.2.4` and `.17.2.6.2.5` remain
  proposed.
- [x] **NO REGRESSION** — relative-path audit reports `All tests successful` at
  `Files=1, Tests=2`; task integrity reports three trees/956 nodes; Knowledge
  Map parity reports 1,150 facts/6,053 questions/6,220 occurrences/133 shards;
  claim inventory closes all 1,419 candidates with 2,065 current and 615
  original constants; maintained references report zero changed; and all 53
  mdBook chapters test. Diff, staged acceptance, and the final `[doctrine] all
  doctrine checks passed` result complete the activation commit.

## Acceptance Checklist (enforced) — `.17.2.6.2.3` OSVVM source-map closure

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'portable-' --oneline --
  perl/FSM/VIAL/Backend/VHDLOSVVM2026_05.pm` returns origin commit
  `4f350f29c`: the wrapper added one whole-file map per
  portable VHDL source instead of translating the detailed portable graph. The
  focused independent-comparison RED run found six portable wrapper entries
  against 59 foundation entries and thirteen total entries against the required
  66, then failed at `Files=1, Tests=10`.
- [x] **ADDRESSED (verified)** — emitter revision 3 validates the portable
  source-map schema, exact key sets, plan identity, six-artifact digest/byte
  closure, unique one-to-one path translation, every entry identity and bound,
  positive artifact-bounded spans, evidence arrays, nonempty content, and full
  six-source coverage before publishing anything. It then preserves every
  portable payload/span in order, substitutes the wrapper path, recomputes the
  path-derived identity, and appends all 59 translated entries after the seven
  unchanged adapter entries. A corrupted portable identity returns exact
  `VIAL_OSVVM_SOURCE_MAP_TRANSLATION_ERROR` at
  `/portable_foundation/source_map` with no artifacts.
- [x] **NO REGRESSION** — syntax passes; focused emission reports `All tests
  successful` at `Files=1, Tests=11`. The guarded t/1598+t/1599+t/1642
  collection also reports `All tests successful` at `Files=3, Tests=60` in 38
  seconds, including fresh exact OSVVM 2026.05/GHDL 6.0.0
  qualification and same-volume cleanup. The gallery check reports seven VHDL
  sources, nine evidence artifacts, seven advanced mappings, 66 source-map
  entries, and twelve checks. Knowledge Map parity reports 1,150 facts/6,054
  questions/6,221 occurrences/133 shards; claim verification joins all 1,423
  candidates with 2,069 current and 615 original constants; task integrity
  reports three trees/956 nodes; relative paths, rationale reconstruction,
  live-document containment, maintained-reference authority, zero ceiling
  increases, and diff checks pass. All 53 mdBook chapters test, and the
  inspected 88-file/18,906,350-byte repository-local build contains the 59+7
  closure and fail-closed contract before exact removal. The final staged
  acceptance and `[doctrine] all doctrine checks passed` result complete the
  commit workflow.

## Acceptance Checklist (enforced) — `.17.2.6.2.4` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'silent T=22 expectation loss'
  --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  locates repair-parent activation `829fa2c74`, where `.17.2.6.2.4` was
  deliberately proposed behind the first three repairs. Clean implementation
  commit `14ad19924` completes that predecessor chain, so native-UVM negotiation
  now needs one active owner before its RED control or implementation changes.
- [x] **ADDRESSED (verified)** — `.17.2.6.2.4` alone is active for exact T=21
  admission and fail-closed adjacent T=22/larger negotiation. `.17.2.6.2.5`
  remains proposed, and this continuity slice changes no emitter, validator,
  generated artifact, gallery, runtime, public API, capability/support,
  performance, or capacity behavior.
- [x] **NO REGRESSION** — relative-path verification reports `All tests
  successful` at `Files=1, Tests=2`; task integrity reports three trees/956
  nodes; `knowledge-map: OK` reports 1,150 facts/6,054 questions/6,221
  occurrences/133 shards; all 53 mdBook chapters test; live-document and
  maintained-reference checks report no changed reference, and ceiling
  authority reports zero increases. Diff, final staged acceptance, and
  `[doctrine] all doctrine checks passed` complete the activation commit.

## Acceptance Checklist (enforced) — `.17.2.6.2.4` native-UVM negotiation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'at least one public start
  operation is required by the first services gallery' --oneline --
  perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm` returns origin commit
  `6463779be`: negotiation required only coarse foundation presence. A genuine
  parser/PlanBuilder RED run therefore accepted T=22 and emitted the same
  138,345 source bytes and 75 maps as T=21. The initial three-subtest focused
  watcher failed for T=22/T=128; the strengthened four-subtest watcher also
  locks rejection of a changed same-count shape.
- [x] **ADDRESSED (verified)** — `selected_reference_operation_shape_v1` now
  admits only the exact 21-operation sequence, 12/9 scenario partition, four
  total and three simultaneously live fibers, consistent resource count, and
  ten ordered expectation targets. T=22, T=128, and a renamed-expectation T=21
  plan all return one exact `VIAL_UVM_BACKEND_UNSUPPORTED` diagnostic at
  `/negotiation`, the stable unsatisfied reason, and no artifact, operation
  identity, manifest, source map, or staging residue.
- [x] **NO REGRESSION** — syntax passes; the focused watcher reports `All tests
  successful` at `Files=1, Tests=4`. All native-UVM emitter, topology,
  services, checking, matrix/review, negotiation, and CI-inventory tests pass
  at `Files=7, Tests=54`. The admitted reference remains 16 artifacts, ten
  SystemVerilog sources, 138,345 source bytes, 75 maps, fourteen checks,
  byte-identical reruns, and identifiers within the 255-byte backend bound.
  Runtime, result, public API, capability/support, performance, and capacity
  claims remain unchanged. Task integrity reports three trees/956 nodes;
  relative paths pass at `Files=1, Tests=2`; Knowledge Map parity reports
  1,150 facts/6,056 questions/6,223 occurrences/133 shards; claim verification
  closes all 1,426 candidates with 2,072 current and 615 original constants.
  All 53 mdBook chapters test, and the inspected repository-local build
  contains 88 files/18,912,996 bytes before exact removal. Live-document and
  rationale reconstruction pass with one zero-line-growth book authority and
  no ceiling increase. Diff, staged acceptance, the final doctrine gate, and
  exact cleanup complete the commit workflow.

## Acceptance Checklist (enforced) — `.17.2.6.2.5` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Correct OSVVM source inventory
  and portable-foundation cap semantics' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` locates repair-parent
  activation `829fa2c74`, where final authority alignment was deliberately
  proposed behind four behavior repairs. Clean implementation predecessor
  `9c92b27f9` closes that chain, so catalog/support reconciliation now needs one
  active owner before RED controls or implementation changes.
- [x] **ADDRESSED (verified)** — `.17.2.6.2.5` alone is active to correct exact
  OSVVM source inventory and portable-foundation cap semantics, record native
  UVM's enforced source-map cap and selected matrix, reject unknown or
  contradictory authority fields, and qualify the five-leaf repair family.
  This continuity slice changes no catalog, support contract, emitter,
  validator, artifact, runtime, public API, performance, or capacity behavior.
- [x] **NO REGRESSION** — task-tree integrity reports three active trees/956
  nodes; relative paths pass at `Files=1, Tests=2`; Knowledge Map parity reports
  1,150 facts/6,056 questions/6,223 occurrences/133 shards; claim verification
  closes all 1,426 candidates with 2,072 current and 615 original constants;
  all 53 mdBook chapters test. Live-document, maintained-reference, and ceiling
  authorities pass with no changed reference and zero ceiling increases. Diff,
  staged acceptance, and the final doctrine gate complete the activation commit.

## Acceptance Checklist (enforced) — `.17.2.6.2.5` authority alignment

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'generated_provider_sources'
  --oneline -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm` and `git log
  -S'backend_artifacts_base' --oneline --
  perl/FSM/VIAL/ArchitectureScaleWorkload.pm` locate foundation commit
  `063b990f3`: the workload catalog independently encoded incomplete and
  ambiguous profile facts while support discovery retained a stale thirteen-map
  OSVVM view and no native-UVM selected-matrix detail. The initial focused RED
  run failed both top-level subtests and all six authority comparisons.
- [x] **ADDRESSED (verified)** — `BackendEmissionAuthority` owns one exact,
  closed, defensively cloned four-profile set. Workload construction and
  VHDL/native-UVM discovery consume it directly. Portable SV names three source
  and eight total artifacts; OSVVM separates six portable sources, one fixed
  adapter, seven total sources, provider identity, portable-only byte authority,
  66 maps, and 12+20 checks; native UVM records its enforced byte/map caps and
  exact 21-operation/75-map/14-check/25-mapping selection. Executable negatives
  reject obsolete, unknown, missing, or contradictory fields.
- [x] **NO REGRESSION** — syntax passes for all four changed/new modules and
  t/1644; its exact GREEN oracle passes at `Files=1, Tests=3`. Foundational
  workload, regression-corpus, capability-manifest, and authority regression
  passes at `Files=4, Tests=7,108`. The 4,096-MiB guarded portable-SV,
  portable-VHDL, OSVVM, native-UVM, repair-watcher, support, and CI-inventory
  collection passes at `Files=18, Tests=7,248` in 124 seconds. No staging
  residue remains, and runtime, public API, support classification, performance,
  and capacity claims are unchanged. Task integrity reports three trees/956
  nodes; relative paths pass at `Files=1, Tests=2`; Knowledge Map parity reports
  1,150 facts/6,056 questions/6,223 occurrences/133 shards. Claim verification
  closes all 1,426 candidates and 2,072 current/615 original constants with two
  explicit unrelated gaps and zero open owners. All 53 mdBook chapters test;
  the inspected repository-local build contains 88 files/18,913,828 bytes and
  is removed exactly. Rationale reconstruction retains 28 current entries.
  The book authority records zero line growth/-81 bytes with no ceiling
  increase. Diff, staged acceptance, the final doctrine gate, and exact cleanup
  complete the commit workflow.

## Acceptance Checklist (enforced) — `.17.2.6.3` generator activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Implement the selected
  canonical backend-emission generator' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  decomposition commit `63655fee2`, where `.17.2.6.3` remained one proposed
  implementation node until route selection and five prerequisite repairs
  completed. Clean predecessor `2d7b3b27e` now closes those prerequisites, but
  the node still combines caller sealing, shared reports/staging, four distinct
  profile ladders, high-count proof, family qualification, docs, and closure.
- [x] **ADDRESSED (verified)** — `.17.2.6.3` is active only as a container and
  decomposes into six exact children: caller-sealed foundation `.1`, portable
  SystemVerilog `.2`, portable VHDL `.3`, OSVVM `.4`, native UVM `.5`, and final
  family qualification `.6`. Only `.1` is active; every behavior-bearing
  profile sibling remains proposed. Task index, bounded Memory, Knowledge card,
  and mdBook name the same frontier. No code, test, config, artifact, generator,
  emitter, runtime, API, capability/support, performance, or capacity behavior
  changes.
- [x] **NO REGRESSION** — task-tree integrity reports three trees/962 nodes;
  relative paths pass at `Files=1, Tests=2`; Knowledge Map parity retains 1,150
  facts/6,056 questions/6,223 occurrences/133 shards. All 53 mdBook chapters
  test, and the inspected repository-local render contains 88 files/18,914,431
  bytes before exact removal. The claim inventory/disposition join is current
  with zero open owners. Live-document authority records zero book-line growth
  and +83 bytes with no ceiling increase. Diff, staged acceptance, the final
  doctrine gate, zero artifact residue, and the docs-only implementation
  exemption complete the activation commit.

## Acceptance Checklist (enforced) — `.17.2.6.3.1` backend-emission foundation

- [x] **ROOT CAUSE (WHY + WHERE)** — the focused RED command `prove -Iperl
  t/1645-vial-architecture-scale-backend-emission-foundation.t` stopped with
  `Can't locate FSM/VIAL/ArchitectureScaleBackendEmission.pm at t/1645-vial-architecture-scale-backend-emission-foundation.t line 14`, then
  reported `No subtests run`: the selected profile ladders had no shared
  caller-sealed construction/evaluation/staging producer at all.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleBackendEmission` now keeps
  public ownership empty while its same-package qualification path admits only
  the exact checked-AHB pair. It regenerates the complete Parser/PlanBuilder
  route twice, freezes five stage digests plus closed outcome/oracle/claim
  projections, validates construction and evaluation by canonical
  regeneration, refuses injected ExecutionIR/provider data, and delegates
  success/failure staging to the repository-volume workload boundary. Focused
  negatives prove all twenty public shapes, caller seals, source identities,
  mutations, unknown fields, and exact cleanup fail closed.
- [x] **NO REGRESSION** — syntax reports
  `perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm syntax OK`; the shared
  workload, backend-authority, and foundation collection reports `All tests
  successful` at `Files=3, Tests=15`. The exact foundation watcher freezes the
  21-operation canonical route, five stage identities, workload/evaluation/
  rerun content addresses, 44,101 plan bytes, two backend inputs, zero public
  ownership, zero emitted artifacts, and no repository-local stage residue.
  Task integrity reports three trees/962 nodes; `knowledge-map: OK` retains
  1,150 facts/6,056 questions/6,223 occurrences/133 shards; claim disposition
  closes 1,426/1,426 candidates with zero open owners. All 53 mdBook chapters
  test, and the inspected 88-file/18,918,049-byte repository-local render
  contains the new reproducible contract before exact removal. All 22 live
  document surfaces, one changed maintained reference, and zero ceiling
  increases pass; `[doctrine] all doctrine checks passed` closes the staged
  commit candidate.

## Acceptance Checklist (enforced) — `.17.2.6.3.2` portable-SV activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Implement the portable-SystemVerilog backend-emission ladder' --oneline -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies decomposition commit `6b08d8146`, where `.17.2.6.3.2` remained proposed behind the caller-sealed foundation. Clean commit `8e9553a3b` now completes that predecessor, so the profile ladder requires its own active owner before RED controls or implementation.
- [x] **ADDRESSED (verified)** — `.17.2.6.3.2` alone is active for exact portable-SystemVerilog T=21/1,024/4,096/6,319 acceptance and adjacent T=6,320 earliest-cap rejection. Portable VHDL, OSVVM, native UVM, and family closure remain proposed, and this continuity slice changes no code, test, config, generator, emitter, artifact, runtime, API, capability/support, performance, capacity, or product behavior.
- [x] **NO REGRESSION** — relative-path verification reports `All tests successful` at `Files=1, Tests=2`; task integrity reports three trees/962 nodes; `knowledge-map: OK` retains 1,150 facts/6,056 questions/6,223 occurrences/133 shards. Claim inventory/disposition closes all 1,426 candidates with zero open owners. All 53 mdBook chapters test, and the inspected 88-file/18,918,353-byte repository-local render names the active but zero-owned portable-SV frontier before exact removal. All 22 live-document surfaces, one changed maintained reference, zero ceiling increases, diff, and staged acceptance pass; `[doctrine] all doctrine checks passed` closes the activation commit candidate.

## Acceptance Checklist (enforced) — `.17.2.6.3.2` portable-SV implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'my %OWNED_LEVELS'
  --oneline -- perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm` identifies
  foundation commit `8e9553a3b`, whose deliberately empty ownership catalog
  was the exact implementation boundary. The first `prove -Iperl
  t/1646-vial-architecture-scale-backend-emission-portable-sv.t` RED run failed
  because no owned shape existed and public `reference_v1` construction
  returned `active slices do not own the requested backend shape`.
- [x] **ADDRESSED (verified)** — the shared generator now admits only the five
  portable-SV levels owned by the caller-sealed `PortableSV` child. Each route
  derives from the frozen checked-AHB pair and ordinary Parser/PlanBuilder
  production; independent emissions prove exact ordered eight-artifact/
  three-source identities, complete generated-line and operation-ID maps,
  manifest/source-map encoding closure, stable identifiers, and defensive
  content-addressed reports. T=21/1,024/4,096/6,319 reproduce the selected
  164,093/2,803,325/10,910,333/16,776,830 source bytes and
  54/1,057/4,129/6,352 maps; T=6,320 returns only the exact 16-MiB diagnostic
  at `/artifacts` with no partial backend evidence. Same-volume staging cleans
  success, expected rejection, and consumer failure. No external runtime,
  public API, capability/support, performance, capacity, or product claim is
  added.
- [x] **NO REGRESSION** — both changed/new modules and both focused tests report
  `syntax OK`. The portable-SV ladder passes at `Files=1, Tests=7` in 80
  seconds; the preserved private foundation passes at `Files=1, Tests=5`; and
  workload authority plus the unchanged direct emitter pass at `Files=3,
  Tests=16`. The final 4,096-MiB guarded five-file collection passes at
  `Files=5, Tests=28` in 104 seconds after entering at 64.0% host occupancy,
  with no `.artifacts/tmp/vial-scale` residue. Task integrity reports three
  trees/962 nodes; relative-path verification passes at `Files=1, Tests=2`;
  and Knowledge Map parity reports 1,150 facts/6,056 questions/6,223
  occurrences/133 shards. Claim inventory/disposition closes all 1,426
  candidates and 2,072 current/615 original constants with zero open owners.
  All 53 mdBook chapters test; the inspected repository-local build contains
  88 files/18,923,886 bytes and the exact completed-ladder paragraph before
  removal. All 22 live-document surfaces, one exact 0-line/+632-byte book
  authority, and zero ceiling increases pass. Diff, staged acceptance, the
  final doctrine gate, and exact artifact cleanup complete the workflow.

## Acceptance Checklist (enforced) — `.17.2.6.3.3` portable-VHDL activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Implement the portable-VHDL
  backend-emission ladder' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  decomposition commit `6b08d8146`, where `.17.2.6.3.3` remained proposed
  behind the portable-SystemVerilog profile ladder. Clean commit `5d309b0eb`
  now completes that predecessor, so portable VHDL requires its own active
  owner before RED controls or implementation.
- [x] **ADDRESSED (verified)** — `.17.2.6.3.3` alone is active for exact
  portable-VHDL T=21/128/512/29,508 acceptance and adjacent T=29,509
  earliest-cap rejection through the sealed foundation. OSVVM, native UVM,
  and family closure remain proposed. Task index, bounded Memory, Knowledge
  card, and mdBook name the same frontier, while no code, test, config,
  generator, emitter, validator, artifact, runtime, API, capability/support,
  performance, capacity, or product behavior changes.
- [x] **NO REGRESSION** — task-tree integrity reports three trees/962 nodes;
  relative paths pass at `Files=1, Tests=2`; Knowledge Map parity retains
  1,150 facts/6,056 questions/6,223 occurrences/133 shards. Claim inventory
  and dispositions close all 1,426 candidates and 2,072 current/615 original
  constants with zero open owners. All 53 mdBook chapters test, and the
  inspected repository-local render contains 88 files/18,924,036 bytes and
  the exact active zero-owned portable-VHDL frontier before removal. All 22
  live-document surfaces, one exact 0-line/+52-byte book authority, and zero
  ceiling increases pass. Diff, staged acceptance, the final doctrine gate,
  generated-book removal, and zero scale-stage children complete the
  activation workflow.

## Acceptance Checklist (enforced) — `.17.2.6.3.3` portable-VHDL implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — activation commit `1dbd3de97` deliberately
  left `ArchitectureScaleBackendEmission` with only the portable-SV child and
  no portable-VHDL evaluator. `git log -S'PortableSV' --oneline --
  perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm` locates that sole
  profile integration in commit `5d309b0eb`. The first `prove -Iperl
  t/1647-vial-architecture-scale-backend-emission-portable-vhdl.t` RED run
  found the expected VHDL shapes missing from `owned_shapes` and public
  reference construction still rejected at the zero-owned boundary.
- [x] **ADDRESSED (verified)** — the shared generator now admits only the five
  portable-VHDL levels owned by the caller-sealed `PortableVHDL` child while
  preserving the historical private foundation route. Each selected numbered
  source passes ordinary Parser/PlanBuilder production; independent emissions
  prove exact ordered seventeen-artifact/six-source identities, complete
  generated-line and operation-ID maps, all twenty static checks, manifest/
  source-map encoding closure, legal identifiers, and defensive content-
  addressed reports. T=21/128/512/29,508 reproduce
  116,560/174,929/386,897/16,776,739 source bytes and
  59/166/550/29,546 maps; T=29,509 returns only the exact portable 16-MiB
  diagnostic at `/artifacts` with no partial backend evidence. Same-volume
  staging cleans success, expected rejection, and consumer failure. No
  external runtime, public API, capability/support, performance, capacity, or
  product claim is added.
- [x] **NO REGRESSION** — both changed/new modules and the affected tests
  report `syntax OK`. The focused portable-VHDL ladder passes at `Files=1,
  Tests=7` in 133 seconds; the preserved foundation and direct VHDL checks pass
  at `Files=4, Tests=25` in 37 seconds; and the corrected portable-SV ladder
  passes at `Files=1, Tests=7` in 80 seconds. The final 4,096-MiB guarded
  nine-file collection passes at `Files=9, Tests=55` in 253 seconds, with no
  `.artifacts/tmp/vial-scale` residue. Task integrity reports three trees/962
  nodes; relative-path verification passes at `Files=1, Tests=2`; and
  Knowledge Map parity reports 1,150 facts/6,056 questions/6,223 occurrences/
  133 shards. Claim inventory/disposition closes all 1,426 candidates and
  2,072 current/615 original constants with zero open owners. All 53 mdBook
  chapters test; the inspected repository-local build contains 88 files/
  18,931,009 bytes and the exact completed-ladder paragraph before removal.
  All 22 live-document surfaces, one exact 0-line/+955-byte book authority,
  and zero ceiling increases pass. Diff, staged acceptance, the final doctrine
  gate, and exact artifact cleanup complete the workflow.

## Acceptance Checklist (enforced) — `.17.2.6.3.4` OSVVM activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Implement the OSVVM-qualified
  backend-emission ladder' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  decomposition commit `6b08d8146`, where `.17.2.6.3.4` remained proposed
  behind the portable-VHDL profile ladder. Clean commit `7199de481` now
  completes that predecessor, so OSVVM requires its own active owner before
  RED controls or implementation.
- [x] **ADDRESSED (verified)** — `.17.2.6.3.4` alone is active for exact OSVVM
  T=21/128/512/29,508 acceptance and adjacent portable-foundation T=29,509
  rejection through the sealed foundation and one callback-scoped exact
  provider evaluation. Native UVM and family closure remain proposed. Task
  index, bounded Memory, Knowledge card, and mdBook name the same frontier,
  while no code, test, config, generator, emitter, validator, provider,
  artifact, runtime, API, capability/support, performance, capacity, or
  product behavior changes.
- [x] **NO REGRESSION** — task-tree integrity reports three trees/962 nodes;
  relative paths pass at `Files=1, Tests=2`; Knowledge Map parity retains
  1,150 facts/6,056 questions/6,223 occurrences/133 shards. Claim inventory
  and dispositions close all 1,426 candidates and 2,072 current/615 original
  constants with zero open owners. All 53 mdBook chapters test, and the
  inspected repository-local render contains 88 files/18,931,234 bytes and
  the exact active zero-owned OSVVM frontier before removal. All 22 live-
  document surfaces, one exact 0-line/+63-byte book authority, and zero
  ceiling increases pass. Diff, staged acceptance, the final doctrine gate,
  generated-book removal, and zero scale-stage children complete the
  activation workflow.

## Acceptance Checklist (enforced) — `.17.2.6.3.4` OSVVM implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — activation commit `825f7f031`
  deliberately retained `ArchitectureScaleBackendEmission` with only the two
  portable profile children. The first `prove -Iperl
  t/1648-vial-architecture-scale-backend-emission-osvvm.t` RED run found no
  `vhdl_osvvm_qualified` entry in `owned_shapes`; public reference
  construction returned `active slices do not own the requested backend shape`
  at perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm line 118.
- [x] **ADDRESSED (verified)** — the shared generator now admits exactly the
  five OSVVM levels owned by its caller-sealed `OSVVM` child. The child
  delegates the selected numbered VIAL recipe to portable VHDL, traverses
  ordinary Parser/PlanBuilder production, verifies the exact OSVVM 2026.05
  graph once inside one callback, and defensively emits both independent
  routes through that opaque evaluation. Accepted levels freeze sixteen
  artifact paths, seven source identities, seven adapter-first maps followed
  by every portable map, all canonical operation IDs, seven advanced mapping
  identities/statuses, six byte-identical portable sources and six semantic
  guards, twelve wrapper checks plus twenty portable prerequisite checks, the
  exact provider commit/tree/manifest digest and 14/13/14/0 census, legal
  generated identifiers, encoded evidence/manifest closure, content identity,
  and byte-equal reruns. T=29,509 returns only
  `VIAL_OSVVM_PORTABLE_FOUNDATION_ERROR` at `/portable_foundation`, with no
  partial plan, provider evidence, mapping, validation, manifest, or artifact
  graph. Same-volume staging cleans success, expected rejection, and consumer
  failure. No external runtime, public API, capability/support, performance,
  capacity, or product claim is added.
- [x] **NO REGRESSION** — both changed/new modules and the affected tests
  report `syntax OK`. The focused OSVVM ladder passes at `Files=1, Tests=7` in
  189 seconds. The final 4,096-MiB guarded direct-backend, authority,
  foundation, portable-SV, portable-VHDL, and OSVVM collection passes at
  `Files=9, Tests=86` in 439 seconds after entering at 82.6% host occupancy,
  with no `.artifacts/tmp/vial-scale` residue. Task integrity reports three
  trees/962 nodes; relative paths pass at `Files=1, Tests=2`; and Knowledge Map
  parity retains 1,150 facts/6,056 questions/6,223 occurrences/133 shards.
  Claim inventory/disposition closes all 1,426 candidates and 2,072 current/
  615 original constants with zero open owners. All 53 mdBook chapters test;
  the inspected repository-local render contains 88 files/18,940,861 bytes
  and the exact completed OSVVM paragraph before removal. All 22 live-document
  surfaces, one exact 0-line/+883-byte book authority, and zero ceiling
  increases pass. Diff, staged acceptance, the final doctrine gate, and exact
  artifact cleanup complete the workflow. Native UVM and family closure remain
  proposed; no external runtime, public API, capability/support, performance,
  capacity, or product claim changes.

## Acceptance Checklist (enforced) — `.17.2.6.3.5` native-UVM activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Implement the native-UVM
  selected backend-emission route' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  decomposition commit `6b08d8146`, where `.17.2.6.3.5` remained proposed
  behind the OSVVM profile ladder. Clean commit `b8969b525` now completes that
  predecessor, so native UVM requires its own active owner before RED controls
  or implementation.
- [x] **ADDRESSED (verified)** — `.17.2.6.3.5` alone is active for exact T=21
  selected-review emission plus T=22/larger/changed-same-count pre-artifact
  rejection through the sealed foundation. Family closure remains proposed.
  Task index, bounded Memory, Knowledge cards, and mdBook name the same
  frontier, while no code, test, config, generator, emitter, validator,
  artifact, runtime, API, capability/support, performance, capacity, or
  product behavior changes.
- [x] **NO REGRESSION** — task-tree integrity reports three trees/962 nodes;
  relative paths report `All tests successful` at `Files=1, Tests=2`; and
  Knowledge Map parity retains 1,150 facts/6,056 questions/6,223 occurrences/
  133 shards. Claim inventory/dispositions close all 1,426 candidates and
  2,072 current/615 original constants with zero open owners. All 53 mdBook
  chapters test, and the inspected repository-local render contains 88 files/
  18,941,017 bytes and the exact active native-UVM frontier before removal.
  All 22 live-document surfaces, one exact 0-line/+81-byte book authority, and
  zero ceiling increases pass. Diff, staged acceptance, the final doctrine
  gate, generated-book removal, and zero scale-stage children complete the
  activation workflow.

## Acceptance Checklist (enforced) — `.17.2.6.3.5` native-UVM implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Implement the native-UVM
  selected backend-emission route' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  decomposition commit `6b08d8146`; the first focused RED run then reported
  `$got->[15] = Does not exist` and public construction rejected because the
  central registry contained only the three earlier profile children.
- [x] **ADDRESSED (verified)** — the caller-sealed NativeUVM child owns five
  route outcomes and emits only exact selected T=21 through ordinary Parser,
  PlanBuilder, and the existing native emitter twice. Its closed oracle freezes
  sixteen artifacts, ten source identities/138,345 bytes, 75 bounded maps with
  six intentional operation associations, fourteen passing checks, 25
  mappings, seven review stages/five closure checks, a 49-byte selected symbol
  maximum below 255, evidence/manifest encoding, byte-equal reruns, and false
  parse/compile/runtime/result/manual-review/product claims. Every non-reference
  level validates the adjacent T=22 negotiation rejection without partial
  evidence; later levels are preflight-dominated/not-constructed. Direct T=128
  and changed-same-count T=21 witnesses reject identically. Canonical-report
  mutation and all staging paths fail closed and clean exactly.
- [x] **NO REGRESSION** — both changed/new modules and all affected tests
  report `syntax OK`. Focused native-UVM generation passes at `Files=1,
  Tests=8` in 38 seconds; shared foundation plus native UVM pass at `Files=2,
  Tests=13` in 57 seconds. Existing emitter/negotiation/authority compatibility
  passes at `Files=7, Tests=45`, the gallery remains exact at nine source/two
  evidence snapshots/75 maps/14 static checks/five closure checks, and CI
  inventory passes at `Files=1, Tests=12`. The final 4,096-MiB guarded repaired
  backend/generator collection passes at `Files=10, Tests=94` in 467 seconds.
  Task-tree integrity remains three trees/962 nodes; relative paths pass at
  `Files=1, Tests=2`; and Knowledge Map parity retains 1,150 facts/6,056
  questions/6,223 occurrences/133 shards. Claim inventory/disposition closes
  all 1,426 candidates and 2,072 current/615 original constants with zero open
  owners. All 53 mdBook chapters test; the inspected repository-local render
  contains 88 files/18,944,914 bytes and the exact completed native-UVM
  paragraph before removal. All 22 live-document surfaces, one exact
  0-line/+670-byte book authority, the compacted 45,455-line Knowledge-card
  surface, and zero ceiling increases pass. Diff, staged acceptance, the final
  doctrine gate, and exact artifact cleanup complete the workflow. Family
  closure remains proposed; no external runtime, public API, capability/
  support, performance, capacity, or product claim changes.

## Acceptance Checklist (enforced) — `.17.2.6.3.6` family-closure activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Qualify the complete backend-
  emission profile family' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  decomposition commit `6b08d8146`, where `.17.2.6.3.6` remained proposed
  behind the four profile children. Clean commit `d8dd1ce82` completes the
  native-UVM predecessor, so family qualification requires its own active
  owner before RED controls or implementation.
- [x] **ADDRESSED (verified)** — `.17.2.6.3.6` alone is active to freeze the
  exact 13-emitted/7-rejected family partition, run default and guarded
  high-count matrices, retain authority/oracle/nonclaim/cleanup closure, and
  close `.17.2.6.3` plus `.17.2.6`. Task index, bounded Memory, Knowledge cards,
  and mdBook name the same frontier, while no code, test, config, generator,
  emitter, validator, artifact, runtime, API, capability/support, performance,
  capacity, family-report, or product behavior changes.
- [x] **NO REGRESSION** — task-tree integrity reports three trees/962 nodes;
  relative paths pass at `Files=1, Tests=2`; and Knowledge Map parity retains
  1,150 facts/6,056 questions/6,223 occurrences/133 shards. Claim inventory/
  dispositions close all 1,426 candidates and 2,072 current/615 original
  constants with zero open owners. All 53 mdBook chapters test, and the
  inspected repository-local render contains 88 files/18,945,813 bytes and
  both exact active-family/no-family-report statements before removal. All 22
  live-document surfaces, one exact 0-line/+132-byte book authority, the
  line-neutral 45,455-line Knowledge-card surface, and zero ceiling increases
  pass. Diff, staged acceptance, the final doctrine gate, generated-book
  removal, and zero scale-stage children complete the activation workflow.

## Acceptance Checklist (enforced) — `.17.2.6.3.6` family-closure implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Qualify the complete backend-
  emission profile family' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  decomposition commit `6b08d8146`, while activation commit `b3b97871a` left
  the terminal leaf intentionally without a canonical family watcher. The
  honest first `prove -Iperl
  t/1650-vial-architecture-scale-backend-emission-family-qualification.t`
  RED run reported `Cannot detect source` because that test did not exist.
- [x] **ADDRESSED (verified)** — new t/1650 derives the four profiles and five
  catalog levels directly from closed authorities, constructs every outcome
  twice, and freezes the exact thirteen-emitted/seven-rejected partition. It
  independently evaluates one reference and adjacent rejection per profile,
  checks applicability plus profile-specific artifact/source/map/check/
  diagnostic evidence, byte-equal identities, and structural-only nonclaims,
  rejects direct helper access, construction/report/support-claim mutation,
  and proves repository-volume cleanup after success, rejection, and consumer
  failure. The leaf, generator parent, and backend-emission parent are done;
  task index, bounded Memory, Knowledge card, mdBook, claim dispositions, and
  size authority all select proposed `.17.2.7` next. No generator/emitter,
  external runtime, family-level product API/report, capability/support,
  performance, capacity, or product behavior changes.
- [x] **NO REGRESSION** — t/1650 reports `syntax OK`; its guarded focused run
  reports `All tests successful` at `Files=1, Tests=4` in 119 seconds. CI
  inventory reports `Files=1, Tests=12`; the 4,096-MiB guarded t/1640-t/1650
  repair/generator matrix reports `Files=11, Tests=98` in 600 seconds; and the
  native-UVM gallery remains exact at nine source snapshots/two evidence files/
  75 maps/14 static checks/five closure checks. Task-tree integrity remains
  three trees/962 nodes; relative paths pass at `Files=1, Tests=2`; project
  data locality passes; and Knowledge Map parity retains 1,150 facts/6,056
  questions/6,223 occurrences/133 shards. Claim inventory/disposition closes
  all 1,426 candidates and 2,072 current/615 original constants with 837
  derived gates/589 reviewed records/zero gaps. All 53 mdBook chapters test;
  the inspected repository-local render contains 88 files/18,948,892 bytes and
  the exact closure paragraph before exact removal. All 22 live-document
  surfaces, one exact 0-line/+493-byte book authority, the line-neutral
  45,455-line Knowledge-card surface, zero ceiling increases, diff checks, and
  zero generated-book/scale-stage residue pass.

## Acceptance Checklist (enforced) — `.17.2.7` runtime/balanced activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Integrate runtime-stream
  construction and the balanced portable workload' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies
  deterministic-generation activation commit `49b6e1ba4`, where `.17.2.7`
  remained proposed behind the five orthogonal construction families. Clean
  commit `86faa137d` now completes backend emission, so runtime/balanced work
  needs a separately active owner before RED controls or implementation.
- [x] **ADDRESSED (verified)** — `.17.2.7` is active as three explicit slices:
  provider-free runtime-stream construction `.1`, balanced portable composition
  `.2`, and unified construction qualification `.3`; `.1` alone is active.
  Decisions `0055`/`0056`, the current catalog, task index, bounded Memory,
  Knowledge card, and mdBook name the same scope and preserve earliest-cap,
  stage-oracle, locality, cleanup, and nonclaim boundaries. Activation changes
  no code, test, config, generator, trace, result, external-tool execution,
  runtime, API, capability/support, performance, capacity, or product behavior.
- [x] **NO REGRESSION** — task-tree integrity reports three trees/965 nodes;
  relative paths report `All tests successful` at `Files=1, Tests=2`; Knowledge
  Map parity retains 1,150 facts/6,056 questions/6,223 occurrences/133 shards;
  and claim inventory/disposition closes all 1,426 candidates plus 2,072
  current/615 original constants with 837 derived gates/589 reviewed records/
  zero gaps. All 53 mdBook chapters test; the inspected repository-local render
  contains 88 files/18,949,002 bytes and the exact active-child statement before
  removal. All 22 live-document surfaces, one exact 0-line/+15-byte book
  authority, the compacted 45,455-line/3,363,673-byte Knowledge-card surface,
  zero ceiling increases, diff checks, staged docs-only acceptance, and zero
  generated-book/scale-stage residue pass.

## Acceptance Checklist (enforced) — `.17.2.7.1` runtime-stream implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Implement caller-sealed
  provider-free runtime-stream construction' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies clean
  activation commit `dbc625adf`, which deliberately left the new child without
  an implementation. The honest first `prove -Iperl
  t/1651-vial-architecture-scale-runtime-stream-construction.t` run then failed
  with `Can't locate FSM/VIAL/ArchitectureScaleRuntimeStream.pm` and no tests,
  proving that no constructor or shadow evidence existed.
- [x] **ADDRESSED (verified)** — new caller-sealed
  `ArchitectureScaleRuntimeStream` owns exactly three runtime profiles by five
  levels. It accepts only the frozen checked-AHB HIAL/VIAL pair, derives the
  tool selector from the existing catalog, and rebuilds the ordinary Parser/
  PlanBuilder backend-input route twice through the completed backend-emission
  foundation. Closed content-addressed reports freeze five route identities,
  the exact checked-AHB metrics and structural authority, profile-specific
  schemas/commands/tools/providers, 120/60/30-second and 8-MiB/64-MiB limits,
  reference/10,000/100,000/limit/over-limit trace specifications, normalized
  result expectations, stage applicability, defensive regeneration, and
  same-volume cleanup. Provider access, artifact emission, external execution,
  runtime, materialized trace/result, reached boundary, support, performance,
  and capacity claims remain false. New t/1651 proves every shape plus hostile
  invocant/source/tool/construction/report/support mutations and success/failure
  cleanup; the book and Knowledge Map expose the same bounded contract.
- [x] **NO REGRESSION** — both new files report `syntax OK`. The 4,096-MiB
  guarded focused t/1651 run reports `All tests successful` at `Files=1,
  Tests=4` in 62 seconds; the guarded CI-inventory, workload-catalog, backend-
  authority, backend-input-foundation, backend-family, and runtime-construction
  set reports `Files=6, Tests=35` in 242 seconds. Knowledge Map parity reports
  1,150 facts/6,057 questions/6,224 occurrences/133 shards; claim inventory and
  disposition close 1,427 candidates plus 2,073 current/615 original constants
  as 838 derived gates/589 reviewed records/zero gaps. All 53 book chapters
  test; the inspected repository-local render contains 88 files/18,964,191
  bytes and the exact provider-free contract before removal. The maintained
  book remains 53 files/51,109 lines with one exact +2,353-byte authority and
  zero ceiling increases; Knowledge cards remain within their existing growth
  allowance. Task integrity remains three trees/965 nodes. Relative-path,
  live-document, diff, staged acceptance, final doctrines, and zero generated-
  book/scale-stage residue complete the slice.

## Acceptance Checklist (enforced) — `.17.2.7.2` balanced composition activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Compose the exact balanced
  portable workload' --oneline --
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies clean
  parent activation `dbc625adf`, which deliberately left `.2` proposed while
  runtime-stream construction proceeded. Commit `3c1f0b411` now completes that
  predecessor; the balanced composer still has no implementation and therefore
  needs this sole active owner before a RED control or source change.
- [x] **ADDRESSED (verified)** — `.17.2.7.2` alone is active. Its closed scope is
  the one `balanced_portable_v1` catalog profile, the exact decision-`0055`
  interaction counts, fresh successful reports from all six completed
  orthogonal constructors, and ordinary VIAL/HIAL, SemanticIR, bridge,
  ExecutionIR, and portable-SystemVerilog routes. Task index, bounded Memory,
  Knowledge Map, and mdBook agree; activation changes no code, test, config,
  workload bytes, generator, emitter, provider/tool execution, runtime, API,
  support, performance, capacity, or product behavior.
- [x] **NO REGRESSION** — task-tree integrity reports three trees/965 nodes;
  relative-path tests pass at `Files=1, Tests=2`; Knowledge Map parity retains
  1,150 facts/6,057 questions/6,224 occurrences/133 shards; claim inventory and
  disposition close 1,427 candidates plus 2,073 current/615 original constants
  as 838 derived gates/589 reviewed records/zero gaps. All 53 mdBook chapters
  test; the inspected repository-local render contains 88 files/18,964,313
  bytes and the exact active-leaf statement before removal. The maintained book
  remains 53 files/51,109 lines with one exact 0-line/+40-byte authority and no
  ceiling increase; the Knowledge-card surface remains within its existing
  3,363,688-byte allowance. Live-document, diff, staged docs-only acceptance,
  final doctrines, and zero generated-book/scale-stage residue complete the
  activation.

## Acceptance Checklist (enforced) — `.17.2.7.2` balanced route blocker audit

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_validate_ahb_bridge'`
  identifies commit `51434a2ae` as the ordinary AHB bridge validator's origin;
  `git log -S'_validate_architecture_scale_bridge'` identifies `97dda148d`
  as the scalable direct-IAL1 profile's origin; and `git log
  -S'qualification_only'` identifies `bfd85ade9` as the caller-sealed
  ExecutionIR binding gate. The current validators prove the former is fixed
  to six fields/six events and the latter to one field, while the binding
  ledger classifies the latter `qualification_only`/`private_nonportable` and
  the portable-SystemVerilog backend's closed capability set does not admit it.
  Counting the remaining selected resources leaves 1,744 field bindings, or
  109 fields on each of sixteen aliases, to reach exactly 2,048 bindings.
- [x] **ADDRESSED (verified)** — no unauthorized bridge or emitter contract was
  invented. `.17.2.7.2` is blocked durably in its owning node, task index,
  bounded Memory, canonical Knowledge card and generated map, and mdBook. Each
  surface records the same two resolution paths: select the recommended
  caller-sealed revision-2 balanced qualification bridge with explicit
  portable-emitter qualification, or revise decision `0055`'s selected counts
  or portable-emission requirement. The maintained-reference registry carries
  the exact 0-line/+621-byte blocker-documentation delta under a fresh authority
  ID and raises no ceiling.
- [x] **NO REGRESSION** — the guarded bridge/backend/execution/binding suite
  reports `All tests successful` at `Files=4, Tests=20`. Task integrity remains
  three trees/965 nodes; relative paths pass at Files=1/Tests=2; Knowledge Map
  parity reports 1,150 facts/6,058 questions/6,225 occurrences/133 shards; and
  claim inventory/disposition closes all 1,427 candidates plus 2,073 current/
  615 original constants as 838 derived gates/589 reviewed records/zero gaps.
  All 53 mdBook chapters test; the inspected repository-local render contains
  88 files/18,967,555 bytes and the exact blocker paragraph before removal.
  All 22 live-document surfaces, the fresh maintained-reference authority, zero
  ceiling increases, diff checks, and zero generated-book residue pass. No
  production code, test, protocol, capability, emitter, external execution,
  runtime, support, performance, capacity, or product behavior changed.

## Acceptance Checklist (enforced) — `.17.2.7.2.1` balanced revision-2 contract selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_validate_ahb_bridge'` and the
  focused blocker audit at `f350553e1` prove the public AHB route accepts only one
  six-field/six-event transaction while revision 1 accepts only a one-field
  private-nonportable scale actor. The selected balanced workload instead needs
  1,744 genuine field bindings, distributed as 109 fields across each of sixteen
  aliases, so neither existing contract can carry it. The director authorized
  the recommended separate revision-2 route on 2026-08-22 and required a
  SOTA/signoff/production-grade, long-term design rather than a bypass.
- [x] **ADDRESSED (verified)** — decision `0077` selects one distinct direct-
  IAL1 `architecture_scale_probe`/`balanced_portable`/revision-2 qualification
  contract and preserves both existing bridges unchanged. It freezes exact
  composer-only bridge and execution entrypoints; 128 endpoints including
  clock/reset, sixteen aliases, 109 endpoint-backed fields per alias, 128
  events, 32 probes, and no extra event-input/adapter bindings; full structural
  portable-emitter negotiation; canonical source/regeneration requirements;
  hostile-mutation rejection; same-volume cleanup; and explicit public API,
  planner, runtime, support, performance, capacity, and reached-boundary
  nonclaims. `.2.2` is the sole active implementation owner.
- [x] **NO REGRESSION** — relative-path and claim-verification tests report `All tests successful`;
  the measured focused total is `Files=3, Tests=25`; all 53 mdBook chapters test; and the
  inspected repository-local render contains 88 files/18,684 KiB plus the exact
  decision-`0077` contract before exact removal. Claim inventory/disposition
  closes 1,431 candidates plus 2,077 current/615 original constants as 842
  derived gates/589 reviewed records/zero gaps. The rationale ledger
  reconstructs 2,872 entries; task integrity remains three trees/969 nodes;
  Knowledge Map parity retains 1,150 facts/6,058 questions/6,225 occurrences/
  133 shards. Maintained-reference authority accepts exactly 53 files/51,109
  lines/2,711,880 bytes with a 0-line/+187-byte delta and no ceiling increase.
  Diff, staged acceptance, final doctrines, and zero generated-book residue
  close the docs-only slice; production behavior remains unchanged.

## Acceptance Checklist (enforced) — `.17.2.7.2.2` balanced bridge/binder implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — the honest first `prove -Iperl
  t/1652-vial-balanced-portable-bridge-admission.t` run failed with `Can't
  locate object method "build_balanced_portable_qualification" via package
  "FSM::HIAL::VIALBridge::Builder"`. `git log -S'_validate_ahb_bridge'` and
  `git log -S'_validate_architecture_scale_bridge'` locate the two intentionally
  narrower existing contracts, so decision `0077`'s selected route had no
  producer or execution admission rather than a hidden reusable implementation.
- [x] **ADDRESSED (verified)** — the HIAL bridge has one composer-caller-sealed
  direct-IAL1 revision-2 entrypoint that validates the complete scheduled actor,
  constructs only the exact balanced shape, and content-addresses the canonical
  full manifest payload. ExecutionBuilder has a separate composer-caller-sealed
  entrypoint that independently validates route, protocol, facts, capabilities,
  structure, and content identity before binding, then validates every binding
  family and the exact no-padding total. New t/1652 reconstructs the route twice
  and rejects public invocation, public fallback, missing/substituted metadata,
  a 108-field alias, a mutated fact, and a forged identity. Canonical source
  composition and emitter negotiation remain separately owned by `.2.3`/`.2.4`.
- [x] **NO REGRESSION** — all three changed Perl files report `syntax OK`; the
  strengthened t/1652 run reports `All tests successful` at Files=1/Tests=3,
  the guarded bridge/execution/backend set reports Files=8/Tests=41 in 137
  seconds, and the dedicated revision-1 bridge watcher reports Files=1/Tests=6.
  CI-inventory plus claim inventory/disposition watchers pass at Files=3/
  Tests=35; the governed census closes 1,431 candidates and 2,077 current/615
  original constants as 842 derived gates/589 reviewed records/zero gaps. All
  53 book chapters test; its repository-local 88-file/18,970,177-byte render
  contains the exact boundary and is removed. The maintained book is 53 files/
  51,109 lines/2,712,062 bytes under a fresh 0-line/+182-byte authority with no
  ceiling increase. Task integrity remains three trees/969 nodes; relative paths
  pass Files=1/Tests=2; Knowledge Map parity retains 1,150 facts/6,058 questions/
  6,225 occurrences/133 shards; all 22 live-document surfaces, diff checks, and
  zero generated-book residue pass. Public AHB, revision 1, portable emission,
  runtime, support, performance, and capacity behavior remain unchanged.

## Acceptance Checklist (enforced) — `.17.2.7.2.3` canonical composition activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Compose the canonical balanced
  VIAL/HIAL source' -1 --format='%h %s' -- docs/tasks/HIAL-VIAL-VERIFICATION-
  FIXTURE-ARCHITECTURE.md` identifies selection commit `9b756b78c`; clean
  predecessor `4b11043ff` completes `.17.2.7.2.2` and deliberately leaves
  `.2.3` proposed. Decision `0077` and the parent acceptance require a canonical
  balanced composer before emitter qualification, so implementation needs this
  separate active owner after the clean pivot boundary.
- [x] **ADDRESSED (verified)** — `.17.2.7.2.3` alone is active. Its unchanged
  closed scope consumes fresh successful gate reports from all six orthogonal
  constructor families, emits only ordinary HIAL/VIAL through canonical
  producers, proves the complete decision-`0055` interaction vector and
  deterministic identities, and leaves portable-emitter negotiation to `.2.4`.
  Task index, bounded Memory, Knowledge Map, and mdBook select the same frontier.
- [x] **NO REGRESSION** — this activation changes documentation/frontier state
  only. Task-tree integrity remains three trees/969 nodes; relative paths report
  `All tests successful` at `Files=1, Tests=2`; `knowledge-map: OK` retains
  1,150 facts/6,058 questions/
  6,225 occurrences/133 shards; claim inventory/disposition remains complete at
  1,431 candidates and 2,077 current/615 original constants with 842 derived
  gates/589 reviewed records/zero gaps. All 53 mdBook chapters test, maintained-
  reference authority records the exact aggregate delta without a ceiling
  increase, all 22 live-document surfaces pass, and no generated-book residue
  remains. No code, test, config, source fixture, composer, bridge, binder,
  emitter, external runtime, public API, capability/support, performance,
  capacity, or product behavior changes.

## Acceptance Checklist (enforced) — `.17.2.7.2.3` canonical composition implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — the honest first `prove -Iperl
  t/1653-vial-balanced-portable-composition.t` run stopped with `Can't locate
  FSM/VIAL/ArchitectureScaleBalancedPortable.pm in @INC`. The completed
  `.17.2.7.2.2` bridge and binder intentionally expose only caller-sealed
  revision-2 admission; no source composer, six-family prerequisite consumer,
  full canonical route, or balanced report existed behind that boundary.
  `git log -S'ArchitectureScaleBalancedPortable' --oneline --all` therefore
  finds this implementation slice as the first producer rather than a hidden
  reusable route.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleBalancedPortable` is one
  closed composer, not a public bypass. It regenerates exact ordinary HIAL and
  VIAL from code; evaluates fresh substantive reference gates from semantic,
  bridge, execution, checking, backend, and runtime families; then passes the
  balanced sources through Parser, the caller-sealed revision-2 bridge,
  ExecutionBuilder, and plan production twice plus strict keyed replay. Its
  content-addressed report derives the complete decision-`0055` vector,
  logical phase/tie order, exact per-scenario fiber and operation topology,
  model/scoreboard/coverage/fault structure, all 1,024 keyed occurrences, and
  normalized replay equality. Closed inputs, canonical regeneration, exact
  class/caller seals, hostile mutation rejection, and repository-volume
  staging prevent report injection, route borrowing, or residue. Emission is
  explicitly deferred to `.2.4` and every external-runtime/product claim stays
  false.
- [x] **NO REGRESSION** — both new files report `syntax OK`; the corrected
  4,096-MiB guarded focused watcher reports `All tests successful` at `Files=1,
  Tests=4` in 282 seconds after the first full run isolated an over-broad
  test-only path predicate and the locality doctrine removed forbidden OS-path
  literals; the guarded workload, six-family,
  revision-2 admission, and composer collection reports `Files=9, Tests=38` in
  551 seconds. The implementation proves 128 endpoints/events/fibers, sixteen
  109-field aliases, 1,024 operations/random occurrences, 2,048 bindings, 512
  types/cells, 32 live fibers/models/scoreboards/faults, 256 coverpoints, and
  4,096 scoreboard capacity/bins without padding. The repository-root book
  example runs under the guard and prints the exact 128/16/109/2,048
  projection. All 54 mdBook chapters test; the inspected 89-file/19,042,128-
  byte render contains the new example/output/nonclaim page and is removed
  exactly. The maintained book is 54 files/51,245 lines/2,718,185 bytes under
  a fresh +1-file/+136-line/+6,120-byte authority with no ceiling increase;
  its saturated architecture chapter remains at 3,701 lines. CI inventory and
  claim mutation watchers pass at Files=3/Tests=35; the governed census closes
  1,452 candidates plus 2,098 current/615 original constants as 863 derived
  gates/589 reviewed records/zero gaps. Task integrity remains three trees/969
  nodes; relative paths pass Files=1/Tests=2; Knowledge Map parity retains
  1,150 facts/6,058 questions/6,225 occurrences/133 shards; the rationale
  ledger reconstructs 2,872 entries; and all 22 live-document surfaces/3,052
  paths pass. Staged acceptance and final doctrines close below. No portable
  emission, external execution, runtime, public API, support, performance,
  capacity, or reached-boundary claim changes.

## Acceptance Checklist (enforced) — `.17.2.7.2.4` balanced emission activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Qualify balanced portable-
  SystemVerilog emission' -1 --format='%h %s' -- docs/tasks/HIAL-VIAL-
  VERIFICATION-FIXTURE-ARCHITECTURE.md` identifies contract-selection commit
  `9b756b78c`, where `.2.4` remained proposed behind bridge/binder and canonical-
  composition prerequisites. Clean commit `d2305a59a` now completes those
  prerequisites, so emitter qualification needs its separate active owner
  before a RED watcher or implementation can change the tree.
- [x] **ADDRESSED (verified)** — `.17.2.7.2.4` alone is active. Decision `0077`,
  the task/index frontier, bounded Memory, canonical Knowledge card, and mdBook
  all require exact `sv_portable_verilator` negotiation over the complete
  revision-2 bridge and ExecutionIR identities. Label-only admission, public
  route widening, external execution, and runtime/support/performance/capacity
  claims remain excluded.
- [x] **NO REGRESSION** — this activation changes continuity documentation only.
  Task-tree integrity remains three trees/969 nodes; Knowledge Map parity
  retains 1,150 facts/6,058 questions/6,225 occurrences/133 shards; relative
  paths pass Files=1, Tests=2; all 54 mdBook chapters test; and the claim doctrine,
  inventory, and disposition watchers pass Files=3, Tests=31. The independently
  regenerated census remains complete at 1,452 candidates plus 2,098 current/
  615 original constants as 863 derived gates/589 reviewed records/zero gaps.
  The focused book remains exactly 135 lines/5,952 bytes, so the maintained-book
  aggregate is unchanged. Live-document containment, diff, staged acceptance,
  and final doctrines close below. No source, test, parser, bridge, binder,
  emitter, artifact, external runtime, public API, capability/support,
  performance, capacity, reached-boundary, or product behavior changes.

## Acceptance Checklist (enforced) — `.17.2.7.2.4` balanced emission implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — the honest focused RED command
  `prove -Iperl t/1654-vial-balanced-portable-emission.t` failed with
  `Can't locate FSM/VIAL/ArchitectureScaleBalancedPortableEmission.pm at t/1654-vial-balanced-portable-emission.t line 14`,
  proving that the authorized exact emitter qualifier did not exist. During GREEN, Perl's
  `sort SUBNAME LIST` grammar also exposed ambiguous `sort _unique(...)` calls
  in `SVPortableVerilator.pm`; parenthesized `sort(_unique(...))` now makes the
  intended canonical ordering explicit and keeps undefined evidence fail-closed.
- [x] **ADDRESSED (verified)** — the new closed qualifier freshly evaluates the
  six-family composer, reconstructs bridge/ExecutionIR/backend inputs through
  caller-sealed routes, and invokes a backend-only revision-2 emitter admission.
  Independent validation covers every exact protocol fact, resource, relation,
  known value, operation, backend input, and negotiated requirement before
  artifact construction. The oracle freezes eight artifacts, three sources,
  503,279 source bytes, 3,605 source maps, all 1,024 operation IDs and 2,048
  binding IDs, legal identifiers, content identities, byte-equal reruns, public
  bypass rejection, atomic hostile-mutation failure, and exact same-volume
  success/failure cleanup. It explicitly leaves compile, runtime, trace,
  result, support, performance, capacity, and reached-boundary claims false.
- [x] **NO REGRESSION** — all changed modules and the watcher pass syntax. The
  final 4,096-MiB guarded focused watcher reports `Files=1, Tests=4` in 535
  seconds; the guarded public planning, portable-SV, revision-1 scale,
  revision-2 admission, and composer compatibility set reports `Files=5,
  Tests=26` in 403 seconds. CI inventory passes at `Files=1, Tests=7094`; the
  relative-path/claim suite passes at `Files=4, Tests=33`; task integrity stays
  at three trees/969 nodes; and Knowledge Map parity retains 1,150 facts/6,058
  questions/6,225 occurrences/133 shards. The inventory closes 1,459 candidates
  plus 2,105 current/615 original constants as 870 derived gates/589 reviewed
  records/zero gaps. All 54 mdBook chapters test; its inspected repository-local
  render contains 89 files/19,064,111 bytes and is removed exactly. The focused
  chapter is 185 lines/8,612 bytes, and the maintained-book delta is 0 files/
  +50 lines/+2,757 bytes with no ceiling increase. The rationale ledger
  reconstructs 2,873 entries; all 22 live-document surfaces/3,052 paths pass;
  locality and generated-residue censuses are clean. Staged acceptance and
  final doctrines close below. No existing public emitter, planning, bridge,
  revision-1 scale, backend-support, external-runtime, performance, capacity,
  or product behavior is widened.

## Acceptance Checklist (enforced) — `.17.2.7.3` unified qualification activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Qualify runtime-stream and
  balanced construction as one unified provider-free measurement gate' -1
  --format='%h %s' -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies parent-decomposition commit `dbc625adf`, where `.3` remained
  proposed behind runtime-stream and balanced construction. Clean commit
  `ebf98fbbd` now completes both prerequisites, so unified qualification needs
  its own active owner before a RED watcher or implementation changes the tree.
- [x] **ADDRESSED (verified)** — `.17.2.7.3` alone is active. The task/index,
  bounded Memory, Knowledge card, and mdBook agree that it must independently
  derive the complete runtime profile/level plus balanced ownership partition,
  report regeneration, applicability/nonclaim authority, mutation rejection,
  and repository-volume cleanup. External execution, runtime results, public
  API, support, performance, capacity, and reached-boundary claims remain
  excluded.
- [x] **NO REGRESSION** — this activation changes continuity documentation only.
  Task-tree integrity remains three trees/969 nodes; Knowledge Map parity
  retains 1,150 facts/6,058 questions/6,225 occurrences/133 shards; relative
  paths and claim gates pass `Files=4, Tests=33`; all 54 mdBook chapters test,
  and its inspected repository-local render contains 89 files/19,064,876 bytes
  before exact removal. Claim inventory/disposition remains complete at 1,459 candidates plus 2,105
  current/615 original constants as 870 derived gates/589 reviewed records/
  zero gaps. The maintained book changes by 0 files/+2 lines/+109 bytes with no
  ceiling increase. Live-document containment, diff, staged docs-only
  acceptance, and final doctrines close below. No code, test, config,
  generator, emitter, artifact, external runtime, API, capability/support,
  performance, capacity, reached-boundary, or product behavior changes.

## Acceptance Checklist (enforced) — `.17.2.7.3` unified qualification implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — the honest focused RED command
  `prove -Iperl t/1655-vial-architecture-scale-runtime-balanced-qualification.t`
  failed with `Can't locate FSM/VIAL/ArchitectureScaleRuntimeBalancedQualification.pm`
  at watcher line 14. The two prerequisite families were individually
  qualified but no authority closed their combined ownership or made one
  independently reproducible pre-measurement report.
- [x] **ADDRESSED (verified)** — the new exact-class qualifier derives the
  runtime owner's three-profile/five-level partition and the single balanced
  revision-2 member from frozen checked-source bytes. It constructs all sixteen
  members only through the completed family producers, embeds every full child
  report plus construction/report/rerun/applicability/claim/nonclaim identities,
  and normalizes stage applicability without erasing family-specific authority.
  Full validation regenerates the complete aggregate. Source/report/claim/
  invocant/injected-evidence mutations fail closed; defensive results and
  nested dual-family same-volume success/failure cleanup are proved. Provider,
  external-tool, compile, runtime, trace, result, support, performance,
  capacity, and reached-boundary claims remain false.
- [x] **NO REGRESSION** — module and watcher syntax plus diff checks pass. The
  4,096-MiB guarded focused watcher reports `Files=1, Tests=4` in 600 seconds;
  CI inventory plus adjacent runtime-stream compatibility reports `Files=2,
  Tests=7098` in 62 seconds. The ten-file continuity suite passes 111 tests;
  task integrity remains three trees/969 nodes; Knowledge Map parity is 1,150
  facts/6,059 questions/6,226 occurrences/133 shards; and the rationale ledger
  reconstructs 2,874 entries. Claim inventory remains complete at 1,459
  candidates plus 2,105 current/615 original constants as 870 derived gates/
  589 reviewed records/zero gaps. All 54 mdBook chapters test; its inspected
  repository-local render contains 89 files/19,088,391 bytes before exact
  removal. The maintained book changes by 0 files/+56 lines/+3,050 bytes with
  no ceiling increase. All 22 live-document surfaces/3,052 paths pass.
  Staged acceptance and final doctrines close below. No existing family
  producer, public emitter, planner, bridge, API, support classification,
  external runtime, performance, capacity, or product behavior is widened.

## Acceptance Checklist (enforced) — `.17.3` architecture-scale measurement activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Measure portable backend
  generation, compile, execution, result, and artifact scaling.' -1
  --format='%h %s' -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies selection commit `9de3bf9c8`, where one broad `.17.3` leaf was
  proposed behind deterministic generation. Clean predecessor `490c35cc5` now
  closes `.17.2`, while repository searches for
  `vial_architecture_scale_measurement`, `stage_measurements`, and run ordinals
  find no implementation. The measurement contract therefore needs an active
  foundation owner and independently recoverable family/tool slices before any
  watcher, sampler, process, or artifact can change the tree.
- [x] **ADDRESSED (verified)** — `.17.3` is active and decomposed into nine
  ordered leaves: common record/controller/lifecycle foundation; semantic and
  bridge measurement; execution and checking measurement; structural backend
  emission; exact Verilator, GHDL, and OSVVM+GHDL runs; revision-2 balanced
  measurement; and immutable raw-evidence/candidate-calibration closure.
  `.17.3.1` alone is active. Every leaf freezes correctness-before-measurement,
  raw evidence, guard/timeout, same-volume publication/cleanup, applicability,
  and nonclaim boundaries. `.17.4` still owns cap implementation and `.17.5`
  still owns public promotion.
- [x] **NO REGRESSION** — `scripts/check_task_tree_integrity.pl` reports three
  trees/978 nodes; relative paths pass Files=1/Tests=2; `knowledge-map: OK`
  retains 1,150 facts/6,059 questions/6,226 occurrences/133 shards. Claim
  inventory/disposition closes 1,459 candidates plus 2,105 current/615 original
  constants as 870 derived gates/589 reviewed records/zero gaps. All 54 mdBook
  chapters test; its inspected repository-local render contains 89 files/
  19,089,819 bytes and is removed exactly. The 54-file maintained book remains
  51,353 lines/2,724,361 bytes under a fresh zero-line/+260-byte authority with
  no ceiling increase. All 22 live-document surfaces/3,052 paths pass, as do
  diff, docs-only staged acceptance, and final doctrines. No code, test,
  config, fixture, generator, sampler, external process, artifact, public API,
  capability/support, performance budget, capacity, reached-boundary, or
  product behavior changes.

## Acceptance Checklist (enforced) — `.17.3.1` architecture-scale measurement foundation implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — the honest focused RED command
  `prove -Iperl t/1656-vial-architecture-scale-measurement-foundation.t`
  failed with `Can't locate FSM/VIAL/ArchitectureScaleMeasurement.pm at t/1656-vial-architecture-scale-measurement-foundation.t line 17`. Decision
  `0056` had frozen the evidence contract, but no record schema, stage
  controller, sampler, validation/measured admission, guard handoff, or
  publication lifecycle existed to consume the completed deterministic
  `.17.2` constructions.
- [x] **ADDRESSED (verified)** — the new exact-class foundation implements a
  closed canonical record and all twelve ordered stages without an external
  verification tool. Validation runs retain correctness but no performance;
  measured runs require matching successful validation and the active
  repository guard. Fork-isolated workers own disjoint output roots while the
  controller samples the live process tree every 250 ms, applies smaller-of
  timeouts, validates stage and aggregate artifact censuses, sanitizes bounded
  failure evidence, and removes exact repository-volume staging after success,
  exception, timeout, or rejected output. Publication accepts only successful
  measured records and proves same-volume atomic rename, byte-identical no-op,
  collision rejection, and rollback after injected failure. Closed report
  validation rejects forged schema, timeout, path, identity, counter, oracle,
  artifact, cleanup, diagnostic, and nonclaim evidence.
- [x] **NO REGRESSION** — module/test/shell syntax and `git diff --check` pass.
  The 4,096-MiB guarded exact measurement plus adjacent RAM-guard matrix reports
  `All tests successful` at `Files=2, Tests=8`; adjacent canonical workload
  construction reports `Files=1, Tests=7`; staged CI inventory, rationale,
  containment, and claim-doctrine regressions report `Files=6, Tests=64`.
  Project-data locality passes with read-only Darwin/Linux host observation and
  repository-local project output.
  Task integrity remains three trees/978 nodes; `knowledge-map: OK` covers
  1,150 facts/6,062 questions/6,229 occurrences/133 shards; all 54 mdBook
  chapters test, and its inspected 89-file/19,122,414-byte repository-local
  render is removed exactly. Claim inventory/disposition closes 1,464
  candidates plus 2,110 current/615 original constants as 875 derived gates/
  589 reviewed records/zero gaps. The 54-file maintained book changes by 79
  lines/4,160 bytes under a fresh exact authority with zero ceiling increase;
  all 22 live-document surfaces/3,052 paths pass. Relative-path, diff, staged
  acceptance, and final doctrine gates close in this commit. Family/tool
  execution, calibration, performance budgets, support, capacity, and
  reached-boundary claims remain unchanged and later-owned.

## Acceptance Checklist (enforced) — `.17.3.2` semantic and bridge measurement activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Measure semantic-catalog and
  bridge-fanout construction through their canonical provider-free stages.' -1
  --format='%h %s' -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies decomposition commit `ec94d5d02`, where `.17.3.2` remained
  proposed behind the common controller. Clean predecessor `3946bf101` now
  completes that controller, while the family constructors remain durably
  closed at `145d3084a` and `97dda148d`; no active leaf yet owned the adapter,
  watcher, or raw semantic/bridge measurement records.
- [x] **ADDRESSED (verified)** — `.17.3.2` alone is active. Its contract admits
  only canonical `ArchitectureScaleSemanticCatalog` and
  `ArchitectureScaleBridgeFanout` reconstruction, requires validation before
  three gate or five qualification samples, re-proves the family oracle in
  every retained run, separates FSMGen-owned construct/parse/bridge stages,
  retains earliest-cap and cleanup truth, and marks later stages inapplicable.
  External verification tools, execution/checking families, budget derivation,
  cap repair, support, capacity, and reached-boundary claims remain separately
  owned.
- [x] **NO REGRESSION** — the unchanged semantic/bridge family suite reports
  `All tests successful` at `Files=2, Tests=10`; task integrity remains three
  trees/978 nodes; project-data locality passes; and `knowledge-map: OK` covers
  1,150 facts/6,064 questions/6,231 occurrences/133 shards. Claim inventory and
  disposition remain complete at 1,464 candidates plus 2,110 current/615
  original constants as 875 derived gates/589 reviewed records/zero gaps. All
  54 mdBook chapters test, and its inspected 89-file/19,133,640-byte
  repository-local render is removed exactly. The maintained 54-file book
  grows by 24 lines/1,518 bytes under a fresh authority with zero ceiling
  increase; all 22 live-document surfaces/3,052 paths pass. Relative-path,
  diff, docs-only staged acceptance, and final doctrine gates close in this
  commit. No code, test, config, fixture, constructor, parser, SemanticIR,
  bridge, manifest, sampler, artifact, external process, public API,
  performance budget, support, capacity, reached-boundary, or product behavior
  changes.

## Acceptance Checklist (enforced) — `.17.3.2` caller-sealed family measurement adapter

- [x] **ROOT CAUSE (WHY + WHERE)** — With activation commit `f82645cf8`
  clean, the honest watcher reported
  `Can't locate FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurement.pm at t/1657-vial-architecture-scale-semantic-bridge-measurement.t line 12`.
  The completed common controller therefore had no caller-sealed adapter that
  could reconstruct the two selected provider-free families, map their stages,
  or retain their canonical correctness evidence in measured records.
- [x] **ADDRESSED (verified)** —
  `FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement` now accepts only an
  exact repository root, selected family, catalog level, and primary axis. It
  independently reconstructs and reruns the canonical family stages, delegates
  resource observation and lifecycle to the completed foundation, retains the
  original family evaluation as a content-addressed artifact, and embeds only
  a deterministic path-safe evidence projection. Closed schema, authority,
  applicability, raw-sample, exclusion, diagnostic, cleanup, and nonclaim
  checks reject hostile substitution. Only the construct worker repeats family
  reconstruction; later workers consume the sealed construction so parse and
  bridge measurements do not include construction cost. The guarded exact watcher passes at
  `Files=1, Tests=5`; syntax and `git diff --check` pass. This slice does not
  claim completion of the still-pending full selected profile matrix.
- [x] **NO REGRESSION** — The common exact measurement/guard suite passes at
  `All tests successful` with `Files=2, Tests=8`, and the adjacent
  bridge/adapter suite passes at
  `Files=2, Tests=11`; the unchanged canonical semantic/bridge suite passes at
  `Files=2, Tests=10`, and CI inventory passes at `Files=1, Tests=12`. All 54
  mdBook chapters test, and the inspected 88-file/19,147,173-byte same-volume
  render is removed exactly. Knowledge Map parity covers 1,150 facts/6,065
  questions/6,232 occurrences/133 shards; the claim join closes 1,464
  candidates plus 2,110 current/615 original constants as 875 derived gates,
  589 reviewed records, and zero gaps. Task integrity, project-data locality,
  live-document containment, relative-path, staged implementation acceptance,
  diff, and final doctrine gates pass in this commit. A failed local
  disposition-reorder attempt was
  recovered byte-exact from Git before the intended one-row patch was applied;
  the complete bounded disposition join then passed. No family producer,
  parser, SemanticIR, bridge,
  manifest, sampler, external process, public API, performance budget, support,
  capacity, reached-boundary, or product behavior contract changes.

## Acceptance Checklist (enforced) — `.17.3.2` resumable matrix publication

- [x] **ROOT CAUSE (WHY + WHERE)** — With adapter commit `ae6f346ec` clean,
  the honest focused watcher failed with
  `Can't locate FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurementMatrix.pm in @INC at t/1658-vial-architecture-scale-semantic-bridge-measurement-matrix.t line 13`,
  then reported `No subtests run`. The adapter could return one complete
  profile report, but no closed inventory, interruption-safe publication,
  profile resume, family census, or full-matrix completion seal existed.
- [x] **ADDRESSED (verified)** — the new exact-class matrix owns all 108
  gate/qualification/limit/over-limit profile sets across fourteen semantic
  and thirteen bridge axes without accepting a caller inventory, report, or
  root override. Capture requires a clean Git revision and the real RAM guard.
  Every complete report publishes from fresh same-volume staging by atomic
  directory rename; byte-identical reuse is unchanged, different bytes
  collide, ambiguous crash staging fails closed, and independently revalidated
  same-revision/common-host/tool/guard profile sets resume after interruption.
  Family manifests require their exact child census; the complete manifest
  requires both canonical family manifests and one common identity. The thin
  operator derives the root from its repository location. A same-volume
  isolated probe proves publish/reload/idempotence/collision behavior and
  removes its operation-owned temporary root. The clean guarded full capture
  remains intentionally unclaimed until this implementation commit is clean.
- [x] **NO REGRESSION** — module, watcher, and operator report `syntax OK`;
  inventory mode reports exactly 108 profiles; `git diff --check` passes; and
  the focused matrix watcher plus adjacent adapter report
  `All tests successful` at `Files=2, Tests=8`. The first adjacent invocation
  was blocked only because the sandbox denied read-only Darwin `sysctl`; the
  qualified read-only-host-observation rerun passed. The unchanged canonical
  family suite reports `Files=2, Tests=10`, and CI inventory reports
  `Files=1, Tests=12`. Task integrity remains three trees/978 nodes;
  `knowledge-map: OK` covers 1,150 facts/6,066 questions/6,233 occurrences/133
  shards. Claim inventory/disposition closes 1,466 candidates plus 2,112
  current/615 original constants as 877 derived gates/589 reviewed records/zero
  gaps. All 54 mdBook chapters test; its inspected 89-file/19,159,393-byte
  repository-local render is removed exactly. The 54-file maintained book is
  51,532 lines/2,733,996 bytes, a zero-file/+25-line/+1,693-byte bounded change
  under its refreshed authority. Final containment, relative-path, staged
  implementation acceptance, and doctrine evidence close in this commit. No
  canonical family producer, parser, SemanticIR, bridge manifest, measurement
  sample, external tool, performance budget, support, capacity,
  reached-boundary, or product behavior contract changes.

## Acceptance Checklist (enforced) — `.17.3.2` exact matrix/adapter mode alignment

- [x] **ROOT CAUSE (WHY + WHERE)** — The first clean guarded exact watcher at
  commit `b3a03d285` rejected the first semantic profile with
  `semantic/bridge matrix report profile changed at perl/FSM/VIAL/ArchitectureScaleSemanticBridgeMeasurementMatrix.pm line 396`.
  A guarded one-profile diagnostic then proved the matrix requested shorthand
  `gate` while the caller-sealed adapter report contained its canonical
  `gate_measurement`; no qualification publication or staging directory was
  created.
- [x] **ADDRESSED (verified)** — the matrix inventory now reuses the adapter's
  exact `gate_measurement`, `qualification_measurement`, and `validation`
  values instead of maintaining a shorthand translation. The default watcher
  independently freezes 27 gate, 27 qualification, and 54 validation profile
  modes. A guarded first-profile boundary check reports identical
  `gate_measurement` inventory/report modes, three retained samples, and
  `status=accepted`; the full clean-revision matrix remains the next slice.
- [x] **NO REGRESSION** — module and watcher syntax pass; the focused matrix
  plus adjacent adapter report `All tests successful` at `Files=2, Tests=8`;
  the failed run left no qualification publication or staging residue. Task
  integrity remains three trees/978 nodes; `knowledge-map: OK` covers 1,150
  facts/6,066 questions/6,233 occurrences/133 shards. Claim inventory closes
  all 1,466 candidates and 2,112 current/615 original constants as 877 derived
  gates/589 reviewed records/zero gaps. All 54 mdBook chapters test; the
  inspected 89-file/19,160,997-byte repository-local render is removed exactly,
  while the 54-file source remains 51,532 lines/2,734,218 bytes under a
  zero-file/zero-line/+222-byte authority. Final containment, relative-path,
  staged acceptance, diff, and doctrine gates close in this commit. No
  adapter, family, sampling, support, capacity, reached-boundary, or product
  behavior contract is widened.

## Acceptance Checklist (enforced) — `.17.3.2.1` truthful boundary measurement repair

- [x] **ROOT CAUSE (WHY + WHERE; reverified for implementation)** — The clean guarded matrix at commit
  `363165d94` stopped on semantic profile 55. The common controller correctly
  recorded `VIAL_SCALE_MEASUREMENT_TIMEOUT`, `timed_out=true`, signal 15, and
  zero `parse_validate` outputs after the fixed 120-second ceiling; adapter
  `_validate_record_family_evidence` then masked that record by rederiving and
  demanding a successful stage payload. `git log -S'_validate_record_family_evidence'`
  identifies adapter-introduction commit `ae6f346ec`. Guarded timing independently locates
  two approximately 60-second parser/semantic passes plus 44 seconds of format
  reruns. The parser performs costly Unicode cursor bookkeeping on proven-
  ASCII source, and `SemanticBuilder::_binary_hex` sends three 4,096-bit masks
  per referenced declaration through `Math::BigInt`; these repeated canonical
  costs exceed the worker envelope when the adapter reruns its payload.
- [x] **ADDRESSED (verified)** — The lexer now consumes bounded runs and uses
  byte cursors only after UTF-8 validation proves ASCII, while non-ASCII retains
  Unicode-scalar columns and UTF-8 byte offsets. Four-state value/known/Z masks
  use exact linear translations and binary pack/unpack. Adapter validation
  fully rederives successful stages but validates rejected/not-run stages as
  zero-output failure evidence tied to the original foundation diagnostic.
- [x] **NO REGRESSION** — module and watcher syntax pass. Focused parser,
  semantic, adapter, bridge, and family coverage reports `Files=6, Tests=39`;
  the broader core VIAL chain reports `Files=6, Tests=46`; the guarded exact
  70-profile semantic proof reports `Files=1, Tests=4` in 83 seconds; and the
  guarded exact adapter proof reports `Files=1, Tests=6` in 7 seconds. Direct
  guarded profile-55 validation accepts in 42.596013 seconds below the
  unchanged 120-second ceiling with one 4,514-byte artifact, no timeout or
  signal, and exact staging cleanup. Task integrity is three trees/979 nodes;
  Knowledge Map parity covers 1,150 facts/6,068 questions/6,235 occurrences/
  133 shards. The claim join closes all 1,466 candidates plus 2,112 current/
  615 original constants as 877 derived gates/589 reviewed records/zero gaps.
  Documentation audits pass `Files=3/Tests=308`; all 54 mdBook chapters test,
  and its inspected 89-file/19,167,192-byte repository-local render is removed
  exactly. The maintained book remains 54 files/51,532 lines/2,735,155 bytes:
  zero lines/+937 bytes under exact aggregate authority, with no ceiling
  increase. Rationale-ledger reconstruction closes 2,878 entries; live-
  document containment and diff checks pass. Staged implementation acceptance
  and final doctrines close below. Post-commit closure re-censuses and removes
  the exact old-revision incomplete publication, then accepts profile 55 at
  clean `514761a4e` with independent regeneration and exact cleanup. No invalid
  profile, timeout/fixture/API/budget, provider/tool execution,
  support, capacity, reached-boundary, or product-behavior claim is added.

## Acceptance Checklist (enforced) — `.17.3.2` exact semantic/bridge matrix completion

- [x] **ROOT CAUSE (WHY + WHERE; reverified for completion)** — Implementation
  alone could not satisfy the leaf's evidence contract. At clean `ece87892d`,
  the qualification namespace was empty and no family or complete manifest
  existed; `git log -S'complete matrix'` identifies publisher commit
  `b3a03d285`. A first full attempt was correctly interrupted by the real host-
  memory guard before the bridge/full seals, proving partial profile evidence
  cannot be promoted as matrix completion.
- [x] **ADDRESSED (verified)** — The same-revision resumable capture sealed 108
  immutable profile reports, two exact family manifests, and one complete
  manifest. The 111-file/7,418,437-byte namespace has sorted-manifest digest
  `6e0ac8dad33a95a65d684b23bfc459a6e91aa4cce58cf4525df7ba40ebfb102b`,
  clean revision `ece87892d`, one host/tool/guard identity, and no staging.
  Accepted identity `semantic-bridge-matrix/81ce1716...71bb3` retains 69
  accepted and 39 expected-rejection profiles, 48 applicable and six
  inapplicable measurement profiles, 186 raw records, and zero exclusions.
  Independent guarded regeneration returns the same complete identity.
- [x] **NO REGRESSION** — The captured guarded exact watcher resumes both
  family manifests, reports the complete manifest `unchanged`, and passes
  `All tests successful` at `Files=1, Tests=3` in 2,386 seconds. The default
  watcher also passes `Files=1, Tests=3`; exact census, content digest,
  family/complete schema and dominance inspection, clean Git, and absent
  staging checks pass. Task integrity remains three trees/979 nodes; Knowledge
  Map parity covers 1,150 facts/6,068 questions/6,235 occurrences/133 shards.
  The claim join closes 1,467 candidates as 878 derived gates/589 reviewed
  records/zero gaps with 2,113 current/615 original constants. All 54 mdBook
  chapters test; its inspected 89-file/19,167,376-byte repository-local render
  is removed exactly. The maintained book remains 54 files/51,532 lines/
  2,735,174 bytes: zero lines/+19 bytes under exact aggregate authority with
  no ceiling increase. Project locality, relative paths, memory, containment,
  diff, staged acceptance, and doctrine closeout gates pass. No provider,
  compiler, simulator, external verification tool, public API, promoted
  performance budget, support, capacity, reached-boundary, or product-
  behavior contract changes.

## Acceptance Checklist (enforced) — `.17.3.3` execution/checking measurement activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Measure execution-graph and
  checking-state construction through canonical binding, planning, and oracle
  stages.' -1 --format='%h %s' -- docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`
  identifies decomposition commit `ec94d5d02`, where `.17.3.3` remained
  proposed behind earlier family measurement. Clean predecessor `9980fe5c1`
  now closes the semantic/bridge matrix. Decisions `0055` and `0056` require a
  distinct active owner before the common controller can measure the already-
  completed execution/checking authorities or retain their earlier-dominant,
  source-free, preflight, and not-materialized outcomes.
- [x] **ADDRESSED (verified)** — `.17.3.3` alone is active. Its first
  implementation slice must accept only canonical reconstructions from
  `ArchitectureScaleExecutionGraph` and `ArchitectureScaleCheckingState`,
  separate construct/parse/bridge/bind-plan cost, re-prove every applicable
  identity and semantic oracle before retaining a sample, and preserve each
  authority's exact rejection and non-materialization semantics. Backend
  emission, provider/tool execution, compile/run/trace/result work, budget
  promotion, cap repair, support, capacity, and reached-boundary claims remain
  separately owned.
- [x] **NO REGRESSION** — the unchanged guarded execution foundation,
  unconstructible binding boundary, and checking qualification pass at
  `Files=3, Tests=11` in 55 seconds. Task integrity remains three trees/979
  nodes; Knowledge Map parity covers 1,150 facts/6,068 questions/6,235
  occurrences/133 shards. The claim join closes 1,467 candidates as 878
  derived gates/589 reviewed records/zero gaps with 2,113 current/615 original
  constants. All 54 mdBook chapters test; its inspected 89-file/19,167,723-byte
  repository-local render is removed exactly. The maintained 54-file book is
  51,532 lines/2,735,204 bytes: zero lines/+30 bytes under exact aggregate
  authority with no ceiling increase. Project locality, relative paths,
  memory, containment, diff, docs-only staged acceptance, and doctrine gates
  pass. No code, test, config, fixture, producer, oracle, sampler, artifact,
  external process, public API, promoted performance budget, support,
  capacity, reached-boundary, or product-behavior contract changes.

## Acceptance Checklist (enforced) — `.17.3.3` execution/checking measurement adapter

- [x] **ROOT CAUSE (WHY + WHERE)** — With activation commit `83189611e`
  clean, the honest watcher reported `Can't locate
  FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm in @INC at t/1659-vial-architecture-scale-execution-checking-measurement.t line 12`.
  The completed
  execution/checking producers could construct and evaluate their selected
  shapes, but the common controller had no exact adapter for their canonical
  stage products. Source-free `envelope_unconstructible` outcomes also have no
  workload identity and therefore cannot truthfully satisfy the controller's
  workload-record contract; preflight-dominated shapes have an identity but
  must not materialize parse or bridge work forbidden by the family authority.
- [x] **ADDRESSED (verified)** — The new exact-class adapter accepts only a
  repository root, one of the two selected families, a catalog level, and an
  owned primary axis. Exact-caller private seams in the two family producers
  expose regenerated canonical SemanticIR/bridge inputs without widening the
  public binder. Each planned `construct`, `parse_validate`, `bridge`, or
  `bind_plan` payload is regenerated twice, materialized only below the common
  same-volume staging root, censused, content-addressed, and rederived during
  report validation. Accepted family outcomes retain one validation plus
  exactly three gate or five qualification records. Authoritative rejections
  retain correctness without timing; preflight outcomes plan only construct
  and bind/plan; source-free outcomes retain canonical evaluation evidence but
  no borrowed identity, controller record, sample, or artifact. Closed
  authority, applicability, report, exclusion, cleanup, and nonclaim schemas
  reject family/source/IR/report/evidence substitution. The foundation remains
  sole owner of guard, process observation, timeout, failure, and cleanup.
- [x] **NO REGRESSION** — Module/test syntax, `git diff --check`, and the fast
  watcher pass. The definitive exact watcher passes `Files=1, Tests=5` in 252
  seconds below the real 88%-host/4,096-MiB-descendant guard; all nested stage,
  raw-sample, regeneration, mutation, rejection, failure, and residue checks
  pass. Unchanged execution foundation, binding boundary, and checking
  qualification tests pass; common-controller and semantic/bridge measurement
  regressions pass `Files=2, Tests=10` with required read-only host access.
  CI inventory passes `Files=1, Tests=12`. All 54 mdBook chapters test; the
  inspected 89-file/19,181,514-byte same-volume render is removed exactly, and
  its 54-file source remains 51,532 lines/2,737,009 bytes under a zero-line/
  +1,805-byte authority with no ceiling increase. Task integrity is three
  trees/979 nodes; Knowledge Map parity is 1,150 facts/6,070 questions/6,237
  occurrences/133 shards. Claim inventory/disposition closes 1,468 candidates
  plus 2,114 current/615 original constants as 879 derived gates/589 reviewed
  records/zero gaps. Project locality, relative paths, live-document
  containment, staged acceptance, and final doctrines close in this commit.
  No provider or external verification tool executes; backend emission,
  compile/run/trace/result, public product API, performance budget, support,
  capacity, reached-boundary, and whole-product behavior remain unclaimed.
  Exact clean-revision resumable matrix publication is the next `.17.3.3`
  slice.

## Acceptance Checklist (enforced) — `.17.3.3` resumable execution/checking matrix publisher

- [x] **ROOT CAUSE (WHY + WHERE)** — At clean adapter commit `11eda923e`,
  the honest watcher reported `Can't locate
  FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm in @INC at t/1660-vial-architecture-scale-execution-checking-measurement-matrix.t line 13`.
  The adapter could produce and independently validate one guarded report, but
  there was no immutable inventory, profile-boundary recovery, family census,
  or complete-matrix seal. A source-free report carries no controller record,
  so reusing the semantic/bridge publisher shape would either leave its clean
  revision unbound or falsely borrow a measurement identity.
- [x] **ADDRESSED (verified)** — The exact-class publisher derives only the
  producer-owned 40-profile execution and 32-profile checking partitions and
  rejects caller lists. Each report is regenerated under the real guard and
  atomically published on the repository volume. A closed, content-addressed
  profile envelope binds the clean revision plus host/tool/guard provenance to
  both controller-backed and source-free reports; the latter retain no
  workload, validation, sample, or controller identity. Retry accepts only a
  byte-valid same-revision profile, rejects collisions and ambiguous staging,
  and withholds family/full manifests until exact child censuses share one
  common identity. The runner exposes only immutable inventory, selected-family
  or complete capture, and guarded independent validation.
- [x] **NO REGRESSION** — Module, runner, and watcher syntax pass, as does
  `git diff --check`. Fast t/1659+t/1660 pass `Files=2, Tests=8`; CI tier
  inventory t/1183 passes `Files=1, Tests=12` in 50 seconds. All 54 mdBook
  chapters test; its inspected 89-file/19,188,836-byte repository-local render
  is removed exactly, while its 54-file source remains 51,532 lines/2,737,956
  bytes under a zero-line/+947-byte authority and no ceiling increase.
  Knowledge Map parity is 1,150 facts/6,071 questions/6,238 occurrences/133
  shards. Claim inventory/disposition closes 1,468 candidates plus 2,114
  current/615 original constants as 879 gates/589 reviewed/zero gaps. Task
  integrity remains three trees/979 nodes; project locality, relative paths,
  rationale reconstruction, live containment, staged acceptance, and doctrines
  pass. Exact capture intentionally remains unclaimed until the publisher is
  first committed and can satisfy its own clean-revision contract. No provider,
  external tool, backend emission, compile/run/trace/result, public API,
  performance budget, support, capacity, or reached-boundary claim changes.

## Acceptance Checklist (enforced) — `.17.3.3.1` interruption-recovery activation

- [x] **ROOT CAUSE (WHY + WHERE)** — The first exact clean-revision t/1660
  capture started below the real guard at 63.9% host memory, then
  `ram-guard: host memory 88.4% reached cutoff 88%` terminated the process
  tree while an unrelated pgen release compiler held more than 13 GiB. No
  execution/checking publication exists, but the exact third gate sample
  remains below `.artifacts/tmp/vial-scale/<workload-id>/gate_measurement/03`.
  A direct invocation against that retained exact identity reports
  `measurement staging root already exists at perl/FSM/VIAL/ArchitectureScaleMeasurement.pm line 1910`;
  line 238 enters
  `_create_owned_stage`, whose present implementation rejects every pre-
  existing final run directory without a lock or safe orphan-recovery path.
- [x] **ADDRESSED (verified)** — Active child `.17.3.3.1` now exclusively owns
  concurrency-safe interrupted-stage recovery. Its acceptance requires exact
  same-volume ownership, concurrent-owner rejection, real-directory/regular-
  file validation before reclamation, fail-closed symlink/special/cross-volume
  handling, unchanged evidence, proof against the retained real residue, and
  capture resume with the original 88%/4,096-MiB guard. No residue was manually
  removed and no incomplete evidence was promoted.
- [x] **NO REGRESSION** — `mdbook test docs/book` reports every one of 54
  chapters successful; relative-path and project-locality coverage reports
  `All tests successful` at `Files=2, Tests=22`; task integrity reports three
  trees/980 nodes; Knowledge Map parity remains 1,150 facts/6,071 questions/
  6,238 occurrences/133 shards. Claim inventory/disposition closes 1,468
  candidates as 879 derived gates/589 reviewed records/zero gaps. The
  maintained book remains 54 files/51,532 lines/2,738,111 bytes under an exact
  zero-file/zero-line/+155-byte authority and no ceiling increase; all 22 live-
  document surfaces pass. This activation changes only durable ownership,
  status, retrieval, claim, and containment records; implementation remains
  pending under the new leaf.

## Acceptance Checklist (enforced) — `.17.3.3.1` interruption-safe measurement recovery

- [x] **ROOT CAUSE (WHY + WHERE)** — The real 88% host guard terminated the
  first clean exact matrix process tree during execution-bindings gate sample
  three. The next exact identity remained a regular tree below
  `.artifacts/tmp/vial-scale`, while a direct retry reported
  `measurement staging root already exists at perl/FSM/VIAL/ArchitectureScaleMeasurement.pm line 1910`.
  The old `_create_owned_stage` could neither distinguish that
  orphan from a live controller nor recover it, so profile publication
  resumability stopped below the publisher boundary.
- [x] **ADDRESSED (verified)** — The common controller now derives a stable
  SHA-256 lock identity from the exact repository-relative stage, verifies a
  zero-byte single-link regular lock inode on the repository device and owned
  by the current process user, marks its descriptor close-on-exec, and takes a
  nonblocking exclusive advisory lock before inspecting staging. A held lock
  rejects concurrent reuse. An unlocked tree is removed only after recursively
  proving real directories plus same-volume, single-linked regular files;
  symlinks, FIFOs, hard links, device drift, and malformed lock state reject in
  place. Empty owned parents are pruned before normal fresh creation and exact
  cleanup. The retained real gate/03 tree was recovered through this code path,
  not manually deleted; its replacement report accepted all three samples with
  zero exclusions and residue. Publication rollback now preserves a legitimate
  pre-existing shared qualification namespace while removing its exact failed
  target and only newly created parents.
- [x] **NO REGRESSION** — The honest public-behavior RED reports the former
  `measurement staging root already exists` diagnostic. Default and exact
  guarded t/1656 now report `All tests successful` at `Files=1, Tests=5`,
  including live contention and unsafe symlink/FIFO/hard-link controls.
  Adjacent t/1657-t/1660 pass `Files=4, Tests=17`; relative-path/locality pass
  `Files=2, Tests=22`; CI inventory passes `Files=1, Tests=12` in 33 seconds.
  All 54 mdBook chapters test; the inspected 89-file/19,194,613-byte same-
  volume render documents the recovery contract and is removed exactly. The
  maintained book remains 54 files/51,532 lines/2,738,716 bytes under a zero-
  file/zero-line/+605-byte authority with no ceiling increase. Task integrity
  remains three trees/980 nodes; Knowledge Map parity is 1,150 facts/6,071
  questions/6,238 occurrences/133 shards; claims close 1,468 candidates as 879
  derived gates/589 reviewed records/zero gaps; all 22 live-document surfaces
  pass. The `task_evidence` surface honestly enters `warning_debt` at 80.3% of
  its line target from the exact HEAD baseline and retains one bounded ratchet
  step under unchanged ceilings. Scale staging is absent. Stable
  repository-local lock identities remain
  outside ephemeral staging and are not measurement evidence. No profile,
  family, complete-matrix, provider, backend, compile/run/trace/result,
  performance-budget, support, capacity, or reached-boundary claim is added.

## Acceptance Checklist (enforced) — `.17.3.3.2` isolated-profile activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_capture_family'` identifies
  origin commit `3ccc4f5b9`, which introduced
  `_capture_family` as one coordinator loop. Every resumed
  `_load_report_publication` parses the full report and calls the full adapter
  validator in that same process. Perl releases the logical values but retains
  the high-water heap, so later profiles start above the memory consumed by
  earlier validation.
- [x] **ADDRESSED (verified)** — Active child `.17.3.3.2` alone now owns a
  guard-visible process boundary per profile, a closed bounded coordinator
  result, exact child failure/signal/protocol handling, unchanged publication
  and common-identity semantics, and continuation from the retained nineteen
  profiles. Guard weakening, trusted-without-validation resume, manual evidence
  removal, and caller-created results are outside acceptance.
- [x] **NO REGRESSION** — The original post-repair capture seals nineteen
  profiles before the 4,096-MiB guard stops it at 5,009.4 MiB. A fresh process
  validates all nineteen byte-identical publications, then stops at the same
  unsealed profile at 4,936.7 MiB. Both attempts leave zero raw staging, no
  execution family/full seal, and a clean tracked tree. Activation changes only
  task, resume, book, fact, claim, and containment records; implementation is
  pending. Documentation checks report `Files=2, Tests=22`, and
  `knowledge-map: OK` confirms generated retrieval parity.

## Acceptance Checklist (enforced) — `.17.3.3.2.3` evidence-prefix archival checkpoint

- [x] **ROOT CAUSE (WHY + WHERE)** — Every execution/checking matrix envelope
  is sealed to one clean capture revision. The 57 atomic publications and
  execution-family manifest captured at revision `e4b95dbd` cannot enter a
  future implementation-revision checking-family or complete seal, while
  deletion or relabelling would destroy the exact interruption evidence.
  `git log -S'capture_identity' --oneline --
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm`
  identifies commits `3ccc4f5b9` and `b9463c663` as the revision-sealing and
  isolated-resume origins.
- [x] **ADDRESSED (verified)** — A one-use fail-closed workflow admitted only
  the expected 40 execution reports, 17 checking reports, and accepted
  execution-family manifest; required regular single-link payloads, clean
  capture identities, the exact matrix identity, and same-volume devices; then
  moved them through a private staging directory into
  `.artifacts/qualification/vial-scale/history/e4b95dbda91777b33fef5e392d7c0b42c4d92871/execution-checking-serialized-plan-timeout-profile-58-v1`.
  The final manifest records capture revision `e4b95dbd`, superseding revision
  `9cfe1168a`, the failed profile/stage/diagnostics, per-file hashes, and
  canonical aggregate digests. The one-use workflow was removed afterward.
- [x] **NO REGRESSION** — Independent reconstruction—not the archival
  workflow—finds 59 archive files: 57 reports/5,662,418 bytes, one
  46,735-byte execution-family manifest, and one archive manifest. It
  reproduces profile digest
  `e8ba27e0986646a284505966828f3c4fdd0a78a55c24978b7a15bff82625f0f9`,
  family digest
  `31718f483626abd06d555f66890288f998d536e0577562fd9f1e76029f68a728`,
  and all-payload digest
  `c9147898a109f21eda6bc8ec370f2b15620518cdb1fb3d7171bf83d9fec49170`.
  The active execution/checking file count is zero, raw/staging residue is
  absent, and all 111 unrelated active files retain their before/after digest
  `e6538ea18897af1203fa26393ae4fafa0bafed0aa9b1423cfc630847cdd4125e`.
  Product code, tests, limits, guards, outcomes, identities, and claims are
  unchanged; implementation remains pending. The RAM-guarded focused suite
  reports `All tests successful` at `Files=5, Tests=55`; all 54 mdBook
  chapters test, `knowledge-map: OK` holds, all 22 containment surfaces pass,
  and the staged doctrine driver is rerun after this checklist update.

## Acceptance Checklist (enforced) — `.17.3.3.2.3` serialized-plan preflight activation

- [x] **ROOT CAUSE (WHY + WHERE)** — The clean revision-`e4b95dbd` matrix
  seals all 40 execution profiles plus the execution family and then 17
  checking profiles. Its isolated
  `random_occurrences/qualification_candidate_v1` worker exits 70 because
  correctness admission does not accept. A direct guarded adapter reproduction
  retains the first disagreement: canonical evaluation returns the exact
  `VIAL_EXECUTION_LIMIT_ERROR`, phase `limit`, message
  `serialized_plan_bytes exceeds the limit 16777216`, path `/plan`, while the
  measured bind-plan stage reaches its fixed 300-second ceiling and returns
  `VIAL_SCALE_MEASUREMENT_TIMEOUT`. Source tracing locates the causal seam in
  `ExecutionBuilder::_build`: all 32,768 random decisions, source maps,
  ExecutionIR, ExecutionReport, and canonical plan bytes are materialized
  before the existing serialized-plan limit runs. `git log -S'_limit_bytes'
  --oneline -- perl/FSM/VIAL/ExecutionBuilder.pm` retains the terminal-check
  origin and confirms that no independent earlier plan-byte check exists.
- [x] **ADDRESSED (verified)** — Active child `.17.3.3.2.3` exclusively owns a
  general plan-projection preflight whose byte count is independently derived
  from authoritative compact inputs, bounded during arithmetic, checked
  against terminal canonical bytes for accepted plans, and followed by the
  unchanged terminal limit. Exact 8,440/8,441 and 32,768 random-occurrence
  outcomes, the 65,536/65,537 dominance order, diagnostics, random/replay
  identities, guards, cleanup, and publication semantics are explicit
  acceptance obligations. Axis-specific thresholds, cap/timeout/guard changes,
  evidence relabelling, and support/performance/capacity promotion are outside
  the leaf.
- [x] **NO REGRESSION** — Activation changed task/continuity/documentation
  records only; product code and tests remained untouched. At that commit the
  active ignored evidence namespace contained exactly 57 publications—40
  execution and 17 checking—plus the sealed execution family, all at revision
  `e4b95dbda91777b33fef5e392d7c0b42c4d92871`; no checking-family or complete
  manifest and no raw staging residue existed. The tracked tree was clean
  before activation; the subsequent archival checkpoint above truthfully
  records the committed superseding revision.
  `knowledge-map: OK` reports 1,150 facts/6,076 questions/6,243 occurrences;
  the focused locality/task/containment/reference/Knowledge Map suite and claim
  suite report `All tests successful` at `Files=5, Tests=87` plus
  `Files=3, Tests=31`, and all 54 mdBook chapters test.

## Acceptance Checklist (enforced) — `.17.3.3.2.3.1` revision-037e56f09 prefix archive

- [x] **ROOT CAUSE (WHY + WHERE)** — The 22 clean-capture reports are sealed to
  revision `037e56f09`; a future repaired-revision execution-family or complete
  manifest cannot admit them, while deletion or relabelling would destroy the
  exact interruption evidence. `git log -S'capture_identity' --oneline --
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm`
  identifies `3ccc4f5b9` and `b9463c663` as the revision-sealing and isolated-
  resume origins.
- [x] **ADDRESSED (verified)** — A fail-closed same-volume move accepted exactly
  ordinals one through twenty-two: five complete four-level execution axes and
  random-attempt gate/qualification. Every payload was a regular single-link
  canonical publication with clean capture revision `037e56f09`, exact family,
  axis, and level identity. The rollback-capable move published only after all
  payloads validated and a canonical revision-keyed manifest was complete.
  No family or complete manifest was invented; the observed profile-23 matrix
  exit and every absent publication/raw-residue fact remain explicit.
- [x] **NO REGRESSION** — A separate post-move verifier reconstructs 23 archive
  files: 22 reports/2,609,009 bytes plus the manifest. It recomputes profile and
  payload digest
  `6dbfa2d02f7eee0332881074628d50d2b454fe94ac241137a11d7c651c162d90`,
  validates every ordinal/route/capture/file hash, and proves same-volume
  storage. All 111 unrelated active files retain 7,418,437 bytes and digest
  `5b3e00bd52730b91a404cea009913bc782ceac6b9fe600bb4f21466b7f9a6e69`.
  Active execution, raw-stage, and archive-staging counts are zero. Product
  modules, tests, limits, guards, timeouts, outcomes, identities, support, and
  claims are unchanged. `knowledge-map: OK`, mdBook, task integrity, locality,
  containment, claim inventory, staged acceptance, and all doctrines are required green before commit.

## Acceptance Checklist (enforced) — `.17.3.4.2` structural measurement matrix implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — Clean commit `814e0f37e` closes canonical per-profile measurement, yet no owner froze the producer's full ordered partition or made reports resumable at one clean revision/host/tool/guard identity. `git log -S'_run_profile_process' --oneline -- perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm` identifies the proven child-lifecycle repair: retaining complete reports in a long-lived coordinator accumulates allocator high-water state, while a profile child can publish raw authority first and return only bounded metadata.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleBackendEmissionMeasurementMatrix` derives all 20 profiles from producer `owned_shapes`, routes levels through the sealed adapter, isolates capture/resume/reload in close-on-exec/nonblocking children, binds raw publications and family/complete manifests to one clean common identity, and atomically publishes only canonical same-volume single-file directories. A guarded 334,757-byte largest-report observation calibrates the independently enforced 524,288-byte file ceiling; compact child IPC/error bounds are 65,536/4,096 bytes. Parent validation rederives order, modes, samples, emission/non-emission, preflight, provider, dominance, artifact, and identity partitions. Re-derivation is producer inventory plus `publication_limits`; falsification is t/1662 order/sample/provider/process/envelope/collision/staging mutation; durability is the tracked module/runner/watcher/book/card/claim record/task/Git chain.
- [x] **NO REGRESSION** — Module/runner syntax passes; the default t/1660-t/1662 regression reports `All tests successful`, Files=3, Tests=14, and CI inventory t/1183 passes Files=1/Tests=12. Runner inventory/help, diff/staging censuses, and mdBook pass; hostile coverage includes 64-MiB child-only state, exception, exit, signal, malformed/noncanonical/oversized output, incomplete sample, provider borrowing, immutable collision, oversize-before-stage, exact recovery, and preserved ambiguous staging. Clean revision fdc6e6a1b exact t/1662 passes Files=1/Tests=5 in 12,656 seconds, seals 22 files/2,232,452 bytes with zero staging residue, independently reloads the complete aggregate, and a separate guarded fresh-process `--validate` returns the same accepted identity and dominance partition. Knowledge Map, claims, task integrity, relative paths, containment, staged acceptance, and doctrines must pass before closure commit; no external-tool, compile/run/IASIM/trace/result, support, budget, capacity, reached boundary, parity, or public API claim is added.

## Acceptance Checklist (enforced) — `.17.3.4.1` structural backend-emission measurement adapter

- [x] **ROOT CAUSE (WHY + WHERE)** — Decision `0075` and `ArchitectureScaleBackendEmission` close the exact four-profile structural outcome authority, but the producer exposed only complete evaluation: no decision-`0056` common-controller adapter owned stage-local timing, raw records, guard identity, cleanup, or measurement applicability. `git log -S'backend_emission_v1' --oneline -- perl/FSM/VIAL/ArchitectureScaleBackendEmission.pm` locates the complete-evaluation authority. Caller-provided source/IR/artifact/provider evidence would have created a second unqualified route, and classifying OSVVM's sealed materialization as external execution would have overstated the evidence.
- [x] **ADDRESSED (verified)** — `ArchitectureScaleBackendEmissionMeasurement` admits only repository root, backend profile, and level. One exact-caller private producer seam derives canonical cumulative parse/bridge/bind products; construction is derived twice, the complete evaluation passes `validate_evaluation`, every planned stage payload reruns twice in an isolated common-controller worker, and report validation regenerates construction, evaluation, payloads, counts, oracles, artifacts, applicability, cleanup, and identity. Portable-SV gate retains exactly three samples and OSVVM qualification five; native-UVM gate is `validated_not_measured`, larger native shapes run construct/emit only, and reference/limit/excess routes remain validation-only. OSVVM provider verification is explicit, read-only, included in emit, and external-tool false. Numeric evidence is independently rederived by the producer/report validators, falsified by focused mutations, and durably watched by t/1661, the book, fact card, claim inventory, task evidence, and Git history.
- [x] **NO REGRESSION** — Module/test syntax and default t/1661 pass; final exact t/1661 passes `Files=1, Tests=5` in 724 seconds under unchanged 88%-host/4,096-MiB-descendant guards. Producer t/1645-t/1650, common controller t/1656, and CI-inventory t/1183 pass; controller coverage retains timeout, signal, output/consumer failure, cleanup, and same-volume staging defenses while the adapter adds hostile input/report/provider/applicability mutations, deterministic reruns, forced worker failure, and defensive returns. `.artifacts/tmp/vial-scale` is absent. Book, Knowledge Map, claims, task integrity, containment, locality, staged acceptance, and doctrines must pass without a ceiling increase. No compiler, simulator, external process, runtime, trace/result, support, promoted budget, capacity, reached boundary, parity, native-UVM runtime, or public API claim is added.

## Acceptance Checklist (enforced) — `.17.3.4` structural backend-emission measurement activation

- [x] **ROOT CAUSE (WHY + WHERE)** — Clean predecessor `040ab0e55` explicitly nonclaims backend emission; decision `0075` proves the portable profiles own distinct emitted ladders while native UVM owns only its reference review shape. `git log -S'backend_emission_v1' -- perl/FSM/VIAL/ArchitectureScaleWorkload.pm` locates that profile-specific authority.
- [x] **ADDRESSED (verified)** — Active child `.1` exclusively owns caller-sealed adapter, stage/applicability/oracle/provider classification, guard, hostile boundaries, and cleanup; proposed child `.2` separately owns immutable publication, same-identity resume, aggregate seal, and guarded reload under decisions 0056/0075.
- [x] **NO REGRESSION** — Product modules/tests are unchanged; index and Memory select only `.17.3.4.1`; task, path, Knowledge Map, claim, containment, and doctrine gates must pass. External-tool, compile/run/trace/result, budget, support, capacity, reached-boundary, native-UVM-runtime, and public-API nonclaims remain exact.

## Acceptance Checklist (enforced) — `.17.3.3.2.3.1` clean 72-profile matrix closure

- [x] **ROOT CAUSE (WHY + WHERE)** — Guarded capture exposed long-lived publisher validation plus late total-operation/plan enforcement and duplicate accepted random search; `git log -S'_capture_family' -- perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm` and `git log -S'_project_random_plan_arrays' -- perl/FSM/VIAL/ExecutionBuilder.pm` retain the causal history and repairs.
- [x] **ADDRESSED (verified)** — Revision `9c0209c22cd035fdc4dd55e3938842b79b36b622` seals all 40 execution/32 checking profiles, both families, complete identity `execution-checking-matrix/0548629720a9f4c8636c912396cfaefff523da92fc800594618db68b788b91d0`, the exact dominance partition, 119 raw records, and zero exclusions at one clean host/tool/guard identity.
- [x] **NO REGRESSION** — The 75-file/7,312,415-byte namespace has zero staging; separate guarded reload returns the same identity/partition with zero diagnostics; `knowledge-map: OK` and all doctrine gates passed. No cap, timeout, guard, identity, support, budget, capacity, reached-boundary, backend/external-tool/runtime, or public-API claim changed.

## Acceptance Checklist (enforced) — `.17.3.3.2.3` serialized-plan preflight implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — The new honest regression replaces
  `_build_randomness`, `ExecutionIR::_from_builder`, and
  `ExecutionReport::build` with fatal sentinels around the real 8,441 route.
  Before repair it enters `_build_randomness` and returns an internal `/`
  diagnostic instead of the historical `/plan` limit record. `git log -S
  '_limit_bytes' --oneline -- perl/FSM/VIAL/ExecutionBuilder.pm` identifies
  the terminal-check origin: `_build` first retained every expected and
  generated decision, appended every random source map, resolved the complete
  graph, built ExecutionIR and ExecutionReport, canonicalized the full plan,
  and only then called `_limit_bytes`.
- [x] **ADDRESSED (verified)** — `_build` now counts random occurrences and
  applies their existing cap first, then streams one generated or
  replay-validated decision expectation at a time. The projection adds exact
  canonical byte deltas for random-decision elements, per-scenario occurrence
  ID elements, and random source-map elements to a shared-report base plan;
  arithmetic saturates at the existing plan cap plus one and continues
  validating the stream after saturation so random/replay errors keep
  precedence. `ExecutionReport` exposes only a caller-sealed private projection
  seam and shares one `_build_plan` schema implementation with its public
  ExecutionIR route. The existing serialized-plan cap rejects the projection
  before `_build_randomness`, source-map expansion, ExecutionIR, or terminal
  report construction. Accepted plans then materialize normally, must equal
  the projected byte count, and still pass the original terminal byte cap.
  Replay lookup is indexed by occurrence without changing its closed-schema,
  identity, value, range, constraint, or attempt validation.
- [x] **NO REGRESSION** — `perl -Iperl -c` reports `syntax OK` for both changed
  modules. The unchanged RAM guard reports `All tests successful` for the
  random/execution/limit/exhaustion/measurement focused set at
  `Files=7, Tests=33`. Exact guarded t/1634 reports `All tests successful` at
  `Files=1, Tests=5`: 8,440 remains accepted at 16,775,415 bytes; 8,441 and
  32,768 return the byte-equal historical `/plan` diagnostic; 65,537 returns
  only the occurrence-cap diagnostic. Core report/ExecutionIR coverage,
  including direct rejection of the private projection seam, reports
  `All tests successful` at `Files=1, Tests=6`. The former exact
  `random_occurrences/qualification_candidate_v1` adapter profile exits zero
  under the unchanged 88%-host/4,096-MiB-descendant guard as
  `expected_rejection` / `validated_not_measured`, with no diagnostic,
  measurement record, or `.artifacts/tmp/vial-scale` residue. Frozen random
  generation/replay values, attempts, byte counts, hashes, identities,
  diagnostics, cap dominance, and terminal serialization remain exact. The
  documentation sync also exposed and repairs one pre-existing rationale-index
  drift: `git log -S'2844–2881' -- DEVELOPMENT_NOTES_INDEX.md` identifies
  `b9463c663`, while the later `e4b95dbd` rationale append advanced the ledger
  manifest to entry 39 without advancing the human index from entry 38. The
  index and independently reconstructed manifest now both close through the
  new entry 40. The two-pass accepted-plan cost is the deliberate
  bounded-memory tradeoff; no
  random list or source-map suffix is cached by preflight, and no timeout,
  guard, cap, support, performance budget, capacity, or reached-boundary claim
  changes. The final guarded two-file rerun on the reviewed code reports
  `All tests successful` at `Files=2, Tests=11`. All 54 mdBook chapters test;
  the inspected repository-local render contains 89 files / 19,243,865 bytes
  and the changed chapter retains the exact boundary and nonclaims before the
  render is removed. Relative paths pass at `Files=1, Tests=2`; task integrity
  holds at three trees / 984 nodes; Knowledge Map parity is 1,150 facts / 6,079
  questions / 6,246 occurrences / 133 shards; and the claim join closes all
  1,474 candidates as 887 derived gates / 587 reviewed records / zero gaps.
  All 22 live-document surfaces pass with zero ceiling increases; project data
  remains repository-local with no disposable book, VIAL-scale, `.bin`, or
  `.log` residue; and staged task acceptance plus all 12 doctrines pass.

## Acceptance Checklist (enforced) — `.17.3.3.2.2` bind-plan evaluation implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — The direct guarded report names
  `VIAL_SCALE_MEASUREMENT_TIMEOUT` at `/stage_measurements/bind_plan/timeout`.
  `git log -S'_canonical_evaluation' --oneline --
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm` plus the
  honest call-count RED prove that double stage-payload execution nested two
  canonical producer evaluations per payload: observed four, required two.
- [x] **ADDRESSED (verified)** — `_validated_evaluation_once` now closes oracle
  and schema validation for one producer result. Canonical admission calls it
  twice and compares byte identity; each of the worker's two payloads calls it
  once and compares with admission. `ExecutionRandom` precomputes invariant
  digest input, directly encodes the bounded u64 attempt, and uses the exact
  full-space algebra without changing algorithm input or public results.
- [x] **NO REGRESSION** — The exact adapter returns accepted validation,
  accepted bind-plan, no diagnostic, and complete cleanup under the unchanged
  guard. `All tests successful` at `Files=6, Tests=28` covers narrow, signed,
  rejection, wide, gate, qualification, limit, exhaustion, replay, and adapter
  oracles. Syntax, diff, mdBook, Knowledge Map, claims, task integrity,
  containment, locality, and all doctrines pass with no ceiling increase.

## Acceptance Checklist (enforced) — `.17.3.3.2.2` bind-plan timeout diagnosis

- [x] **ROOT CAUSE (WHY + WHERE)** — A direct guarded adapter reproduction
  retains `VIAL_SCALE_MEASUREMENT_TIMEOUT` at
  `/stage_measurements/bind_plan/timeout`: the preceding family stages accept,
  bind-plan is terminated at its fixed effective ceiling with no output, and
  exact cleanup succeeds. `git log -S'_canonical_evaluation' --oneline --
  perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurement.pm` identifies
  origin `11eda923e`; its stage worker already invokes `_stage_payload` twice,
  but `_bind_plan_payload` independently nests the twice-evaluated
  `_canonical_evaluation`, multiplying the million-attempt work.
- [x] **ADDRESSED (verified)** — The exact diagnostic, first causal code seam,
  retained publication frontier, and unchanged-contract repair direction are
  durable in the task, Memory, task index, mdBook, and Knowledge Map. No code,
  test, timeout, guard, workload, random/replay contract, or evidence changed.
- [x] **NO REGRESSION** — The guarded report preserves successful construct,
  parse/validate, and bridge records, zero bind-plan output, exact cleanup, no
  RAM-guard trip, no failed publication, no family/full seal, and a clean Git
  tree. `knowledge-map: OK` confirms generated retrieval parity; all mdBook
  chapters, claims, containment, task integrity, locality, and doctrines pass.

## Acceptance Checklist (enforced) — `.17.3.3.2.2` random-attempt correctness-repair activation

- [x] **ROOT CAUSE (WHY + WHERE)** — The immediate failure boundary is proven,
  while the deeper causal layer remains deliberately unclassified pending the
  owned diagnostic run. Exact guarded t/1660 at clean revision `14c619367`
  publishes the former profile-twenty blocker and 22 total envelopes, then the
  profile-23 worker exits 75 from
  `ArchitectureScaleExecutionCheckingMeasurementMatrix::_require_acceptable_profile_report`
  with `matrix correctness validation did not accept at perl/FSM/VIAL/ArchitectureScaleExecutionCheckingMeasurementMatrix.pm line 874`.
  The guard does not terminate it; no failed publication, family/full seal, or
  raw residue exists.
- [x] **ADDRESSED (verified)** — Active child `.17.3.3.2.2` now durably owns
  adapter-level diagnostic retention, independent comparison with canonical
  t/1614, first-disagreement root cause, focused repair, and same-revision
  resume. Memory, the task index, task evidence, mdBook, Knowledge Map card,
  claim disposition, and maintained-reference authority all point at that
  exact next action. No product, test, guard, workload, or publication changed
  in this activation slice.
- [x] **NO REGRESSION** — All mdBook chapters test; `knowledge-map: OK` confirms
  generated Knowledge Map parity,
  task-tree integrity, claim inventory/dispositions, documentation-relative
  paths, project-data locality, live-document containment, and diff checks
  pass. The repository-local evidence census retains 22 current-revision
  profile publications, zero raw-stage files, and no execution/checking family
  or complete manifest. No enforcement ceiling increases.

## Acceptance Checklist (enforced) — `.17.3.3.2.1` early total-operation enforcement implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — The real `ram-guard` isolated the
  4,869.5-MiB profile-twenty failure to `ExecutionBuilder::_build_operations`.
  `git log -S'_build_operations' --oneline --
  perl/FSM/VIAL/ExecutionBuilder.pm` identifies its origin, and the predecessor
  source enforced `expanded_operations_total` only after `_emit_sequence`
  created every operation and source map. Historical exact t/1626 therefore
  required a separate 6,144-MiB guard to observe a known product rejection.
- [x] **ADDRESSED (verified)** — `_preflight_expanded_operations_total` now
  independently walks selected compact repeat/parallel trees, validates their
  structure, uses saturating bounded arithmetic, requires exact equality with
  each validated semantic `action_count`, and invokes the existing cap before
  `_index_bridge`. Compact boundary oracles accept 1,000,000 and reject
  1,000,001 with the historical diagnostic; the real exact evaluation passes
  under the unchanged 4,096-MiB guard and a fatal sentinel proves bridge
  indexing is never entered. The post-materialization check remains.
- [x] **NO REGRESSION** — Final syntax and exact t/1626 report `syntax OK` and
  `Files=1, Tests=9` in one second. The focused accepted ExecutionIR, topology,
  adjacent total-operation qualification, and measurement-adapter suite reports
  `Files=4, Tests=19` in 80 seconds. Active execution publications and
  repository-local raw staging are absent. Task, decision, Memory, mdBook,
  Knowledge Map, claim, containment, task-acceptance, and all-doctrine gates
  pass; no guard, cap, diagnostic, support, performance budget, or capacity
  claim changes.

## Acceptance Checklist (enforced) — `.17.3.3.2.1` early total-operation enforcement activation

- [x] **ROOT CAUSE (WHY + WHERE)** — The real `ram-guard` terminates only the
  isolated `operations_total/over_limit_v1` worker at 4,869.5 MiB after the
  repaired coordinator publishes nineteen profiles. `git log -S'_build_operations'
  --oneline -- perl/FSM/VIAL/ExecutionBuilder.pm` identifies the execution
  builder origin, and current source shows `_limit('expanded_operations_total',
  ...)` after `_emit_sequence`, graph concatenation, and source-map creation.
  Exact t/1626 separately requires a 6,144-MiB worker for the same diagnostic.
- [x] **ADDRESSED (verified)** — Active child `.17.3.3.2.1` and decision `0078`
  now own an independently rederived selected-scenario count, equality with the
  validated semantic count, bounded aggregation, unchanged diagnostic, and
  enforcement before any binding/graph/source-map/plan allocation, with the
  terminal limit retained. The failed b9463c663 prefix is revision-archived as
  exactly nineteen reports/1,739,213 bytes and digest
  `a17d49f8bc6b05e5ed476966f6034a8f99cbdfd571a92c3d0c005b48760b9dd0`;
  active execution reports and raw staging are absent. Product code and tests
  remain untouched; the owning claim and containment records are refreshed.
- [x] **NO REGRESSION** — `knowledge-map: OK` reports 1,150 facts/6,076
  questions/6,243 occurrences/133 shards; `task-tree-integrity` reports three
  trees/982 nodes; all 54 `mdbook test` chapters pass; documentation-relative
  paths report `Files=1, Tests=2`; `perl -Iperl -c` and `git diff --check` pass.
  Claim inventory closes 1,469 candidates as 880 derived gates and 589 reviewed
  records with zero gaps. The task-evidence transition advances exactly one
  configured 100-line ratchet step from 143 to 243; the maintained-book
  per-part allowance likewise advances one configured step from 379 to 479,
  and its aggregate authority records +2 lines/+1,220 bytes. No health target
  or enforcement ceiling increases.
  Activation changes no parser, SemanticIR, bridge, ExecutionIR, plan,
  diagnostic, test, guard, publication, support, performance, or capacity
  behavior.

## Acceptance Checklist (enforced) — `.17.3.3.2` isolated-profile coordinator

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_capture_family'` locates
  origin `3ccc4f5b9`: capture and `_validate_family_publication` both loaded and
  fully validated every large report in their long-lived coordinator. Two
  unchanged-guard runs then stopped before profile twenty after validating the
  same nineteen reports. Their envelopes all name clean revision `c7493e3d`,
  while the isolated-worker implementation must be committed at a later clean
  revision; same-revision sealing therefore forbids mixing or relabelling the
  old reports even though they remain valid interruption evidence.
- [x] **ADDRESSED (verified)** — Every capture, immutable resume, and family or
  complete-publication report validation now executes in a forked descendant
  visible to the outer guard. The child retains full adapter regeneration,
  atomic publish/reload, capture-revision, common-identity, and profile-report
  checks, then returns only a canonical closed payload inside a 1,048,576-byte
  close-on-exec pipe envelope. The parent rejects signal/nonzero exit, empty,
  malformed, noncanonical, oversized, unknown-key, wrong-profile, wrong-
  operation, wrong-status, wrong-common-identity, revision, artifact-path,
  digest, size, or sample-count evidence before retaining one compact entry.
  Exceptions are deterministic and bounded to 4,096 bytes. The old nineteen
  reports remain immutable pending guarded isolated revalidation and verified
  revision-keyed archival; a fresh repaired-revision capture remains the exact
  completion gate after this implementation is committed cleanly.
- [x] **NO REGRESSION** — Module and watcher syntax pass. The real guarded
  adapter/matrix suite reports `All tests successful` at `Files=2, Tests=9`.
  Its new adversarial subtest proves a 67,108,864-byte child-only allocation,
  distinct child PID, callback exception, exit 23, signal 9, malformed payload,
  oversized result, noncanonical bytes, immutable-publication collision, and
  exact repository-local fixture cleanup. Locality, rationale-ledger, and
  matrix checks pass at `Files=4, Tests=29`; all 54 mdBook chapters test;
  `knowledge-map: OK`, `git diff --check`, and every doctrine pass. No guard,
  profile schema, report validator, measurement ordinal, publication path,
  common identity, family/full completion rule, performance budget, support,
  capacity, or reached-boundary claim is weakened; exact 72-profile evidence
  remains explicitly pending the clean implementation revision.

## Acceptance Checklist (enforced) — `.17.3.5` portable-Verilator runtime measurement activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_capture_process' --oneline --
  perl/FSM/VIAL/Backend/Runner.pm` identifies origin `dfe87f536`. Current source
  inspection proves that `ArchitectureScaleRuntimeStream` intentionally owns
  only provider-free construction and expectations, while the public Runner
  keeps prepare, compile, run, trace, result, and cleanup inside one private
  atomic transaction. A stage-measurement implementation therefore has neither
  a proved scale-runtime materialization/identity contract nor a shared staged
  lifecycle it can reuse without duplicating external-execution semantics.
- [x] **ADDRESSED (verified)** — Active child `.17.3.5.1` now owns selection of
  the missing runtime-activity, identity, applicability, and reusable lifecycle
  contracts before product changes. Children `.2` through `.5` separately own
  materialization, shared lifecycle implementation, measurement, and immutable
  matrix publication. The task-tree, bounded Memory pointer, Knowledge Map, and
  mdBook state the active boundary, external-Verilator/IASIM distinction, and
  forbidden source rewriting, output padding/truncation, duplicated execution,
  hidden API widening, borrowed support, and unproved reachability shortcuts.
- [x] **NO REGRESSION** — The unchanged provider-free runtime construction and
  real Verilator integration report `All tests successful` at `Files=2,
  Tests=9` under the unchanged 88%-host/4,096-MiB-descendant guard. `mdbook
  test`, Knowledge Map generation/parity, live-document containment, task-tree
  integrity, and `git diff --check` pass. No parser, SemanticIR, bridge,
  ExecutionIR, emission, tool execution, trace, result, diagnostic, support,
  performance, capacity, or public API behavior changes in this activation.

## Acceptance Checklist (enforced) — `.17.3.5.1.1` portable-SV phase-rollover repair activation

- [x] **ROOT CAUSE (WHY + WHERE)** — A real public-Runner reachability probe
  authored a legal check-phase `expect` before a later react-phase
  `scoreboard_expect`. `git log -S'operation_by_scenario' --oneline --
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm` identifies shipped-runtime
  origin `dfe87f536`; `ExecutionBuilder::_emit_sequence` retained the authored
  successor dependency, increasing static ranks, and exact `check`/`react`
  eligibility. `SVPortableVerilator::_render_fixture_module`, introduced with
  the shipped runtime in `dfe87f536`, instead emitted root task calls directly
  in operation-array order with no phase cursor or backward-phase rollover.
  The resulting same-cycle check-to-react record order was rejected by the
  unchanged `TraceValidator::_validate_logical_order`; no resource guard,
  Verilator, parser, bridge, or scale-count failure caused the result.
- [x] **ADDRESSED (verified)** — Active child `.17.3.5.1.1` now exclusively
  owns a general phase-aware successor repair before scale selection continues.
  Its acceptance forbids source/trace rewriting, global phase sorting, legal-
  source rejection, scale special cases, and public widening, and requires
  executable coverage of every supported backward phase boundary plus
  blocking predecessors, deterministic reruns, existing runtime behavior,
  diagnostics, and cleanup.
- [x] **NO REGRESSION** — This activation changes task, resume, Knowledge Map,
  mdBook, and their exact containment authority state only. The shipped-book
  aggregate is re-authorized from the prior committed 56-file/51,707-line/
  2,756,814-byte state by the exact 0-file/24-line/1,282-byte delta, while the
  Knowledge Map allowance is re-declared to measured growth plus one unchanged
  ratchet step; neither enforcement ceiling changes. Product code, generated
  runtime artifacts, contracts, public APIs, support accounting, and runtime
  behavior remain unchanged; the focused RED/GREEN implementation evidence is
  deliberately pending in the active child. `mdbook test` passes all 54
  chapters; `knowledge-map: OK` reports 1,150 facts/6,086 questions/6,253
  answer occurrences; live-document size, task-tree integrity, and
  `git diff --check` pass.

## Acceptance Checklist (enforced) — `.17.3.5.1.1` portable-SV phase-rollover implementation

- [x] **ROOT CAUSE (WHY + WHERE; executable RED)** — The ordinary checked-AHB
  mutation inserted `expect phase_before_scoreboard` before the success
  `scoreboard_expect`. Parser, bridge, and immutable ExecutionIR succeeded and
  retained increasing static ranks with exact check/react eligibility. The
  unmodified public Runner reached qualified Verilator, then returned
  `VIAL_RUN_TRACE_ERROR`; its unchanged validator exposed cycle-4 prior tuple
  phase rank 3/static rank 1 followed by current phase rank 2/static rank 2.
  The structural RED simultaneously found no rollover at check-to-react,
  react-to-drive, or check-to-drive boundaries. `git log -S'operation_by_scenario'
  -1 -- perl/FSM/VIAL/Backend/SVPortableVerilator.pm`
  identifies cursor-free emitter origin `dfe87f536`; the scenario task called
  immutable root operations directly and `start` advanced its cycle privately.
- [x] **ADDRESSED (verified)** — Decision `0080` and the backend's independent
  closed phase table pair every supported operation's ExecutionIR eligible
  phase with the last phase consumed by its generated lowering. The root
  scheduler preserves operation-array/static-rank order, calls same/forward
  phases directly, traverses the real inactive-edge barrier for check-to-react,
  and increments once for react/check-to-drive. `start` no longer increments
  unconditionally. Negotiation rejects phase-order or kind/eligible-phase drift
  before artifacts. Structural and real-Runner tests prove every backward pair,
  same-phase retention, blocking reset, one genuine repaired expectation,
  byte-identical repeated result/artifact graphs, stable failures, and cleanup.
  The same signoff review proved the independent pre-existing direct-drive
  omission and task-owns its complete repair under active `.17.3.5.1.2`
  rather than widening or hiding it in this slice.
- [x] **NO REGRESSION** — The final guarded ExecutionIR/emission/real-Runner/
  parity/runtime-stream suite reports `All tests successful` at `Files=5,
  Tests=27` in 205 seconds under the unchanged 88%-host/4,096-MiB-descendant
  limits. The module and two changed tests report `syntax OK`; all 54 mdBook
  chapters test; `knowledge-map: OK` covers 1,150 facts/6,088 questions/6,255
  occurrences/133 shards; task integrity holds at three trees/994 nodes; the
  claim join closes 1,473 candidates as 884 gates/587 reviewed records/zero
  gaps; all 22 live-document surfaces and maintained-reference authorities
  pass with zero ceiling increases. Relative-path/locality, diff, staged
  implementation acceptance, and all doctrine gates pass. No ExecutionIR,
  public API, support, scale reachability, performance, capacity, parity,
  full-SystemVerilog, four-state, UVM, or methodology claim is added.

## Acceptance Checklist (enforced) — `.17.3.5.1.2` portable-SV direct-drive repair activation

- [x] **ROOT CAUSE (WHY + WHERE)** — The ordinary in-memory VIAL/HIAL probe
  added drive-capable `endpoint/HSEL` and `(drive select #b1)`. Parser and
  PlanBuilder returned a successful immutable `drive` operation with exact
  typed endpoint/value inputs, `eligible_phase=drive`, and `update_driver`, and
  portable negotiation succeeded. The emitted task body was only
  `vial_inactive_barrier();`: no endpoint assignment or drive record.
  `ExecutionBuilder::_action_target` also has no `endpoint_id` branch, so the
  operation effect target is null. The distinct history probe
  `git log -S'_action_target' -1 -- perl/FSM/VIAL/ExecutionBuilder.pm` locates
  that projection at origin commit `44dbecd1a`, proving the defect predates
  this activation. This is a pre-existing direct-action defect,
  not a phase-rollover, Verilator, scale, resource, or source-validity failure.
- [x] **ADDRESSED (verified)** — Clean prerequisite implementation commit
  `1e9ab0e61` permits the pivot. Child `.17.3.5.1.2` alone is active and owns an
  executable ordinary-source RED plus target projection, exact drive-capable
  bridge/relation admission, normalized assignment and trace, completion/
  successor semantics, hostile targets/types, real qualified-Verilator proof,
  deterministic identities/results, diagnostics, cleanup, documentation, and
  support truth. Runtime materialization/lifecycle selection remains paused;
  no product implementation is included in this activation.
- [x] **NO REGRESSION** — The unchanged guarded portable-SV emission watcher
  reports `All tests successful` at `Files=1, Tests=7`; all 54 mdBook chapters
  test; Knowledge Map generation/parity, task integrity, claim inventory/
  disposition, live-document containment, project locality, diff, and all
  doctrine gates pass. No code, test, fixture, parser, SemanticIR, bridge,
  ExecutionIR, emission, runtime, trace, result, API, support, scale,
  performance, capacity, parity, four-state, or methodology behavior changes.

## Acceptance Checklist (enforced) — `.17.3.5.1.2` portable-SV direct-drive implementation

- [x] **ROOT CAUSE (WHY + WHERE; executable RED)** — The preserved ordinary
  source adds public input endpoint `endpoint/HSEL` and `(drive select #b1)`.
  Parser/PlanBuilder produce a successful immutable drive operation with exact
  typed endpoint/value inputs and one `update_driver` effect, but the pre-fix
  effect target is null because `_action_target` omits `endpoint_id`; the
  pre-fix generated task is exactly `vial_inactive_barrier()` with no `HSEL`
  assignment or `drives` record. Binder reference discovery also sees only
  expression references, so direct action use does not independently establish
  drive direction. The executable RED reports four exact focused failures;
  `git log -S'_action_target' -1 -- perl/FSM/VIAL/ExecutionBuilder.pm` locates
  the original target projection at `44dbecd1a`.
- [x] **ADDRESSED (verified)** — Decision `0081` governs one coherent repair.
  Builder target/reference projection and probe rejection close immutable
  intent; backend negotiation re-derives effect, binding, relation, fully known
  normalized value, declared port, input/root-fiber boundary, and live-sibling
  conflict before artifacts. Rendering assigns and records one zero-duration
  drive, preserves same-phase order, crosses one sample barrier before later
  phases/finalization, restores safe zero once, and emits dedicated provenance.
  TraceValidator rechecks endpoint, null transaction field, canonical value,
  and exact logical slot. Inout/non-root direct drive remain explicit support
  nonclaims rather than speculative support.
- [x] **NO REGRESSION (owning boundary; broader lifecycle gap explicit)** — All
  changed modules/tests report `syntax OK`. The final guarded IR/emitter/support
  suite reports `All tests successful` at `Files=3, Tests=7109`; independent
  capability/runtime-construction coverage passes at `Files=2, Tests=8`.
  Qualified-Verilator execution has observed the complete direct-drive
  subtest—including exact HSEL assignment/record, safe-zero finalization,
  result/artifact byte replay, and cleanup—pass. Repeated full `t/1558` runs
  are not claimed green: different unchanged/direct executions reach Runner's
  pre-existing fixed runtime wall under concurrent host work, with no live
  process or staging residue; `.17.3.5.3` owns the missing launch/main timing
  evidence and the test now fails concisely without dereferencing absent
  artifacts. All 54 mdBook chapters test and render; Knowledge Map parity holds
  at 1,150 facts/6,091 questions/6,258 occurrences/133 shards; task integrity
  holds at three trees/995 nodes; the claim join closes 1,474 candidates as 884
  gates/588 reviewed records/zero gaps; all 22 live-document surfaces and both
  maintained references pass with zero ceiling increases. Repository locality,
  exact failed-run cleanup, and diff checks pass. No scale, four-state,
  methodology, performance, capacity, or general-parity claim is added.

## Acceptance Checklist (enforced) — `.17.3.5.1.3` portable-SV parallel-child repair activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `ExecutionBuilder::_emit_sequence`
  recursively admits every recognized action kind beneath `parallel`, while
  the portable backend's parallel branch reads each child root's `property`
  typed input and passes it to `_render_property` instead of invoking the
  child's kind-specific lowering. `git log -S'Child fibers are evaluated by
  this one scheduler' -1 -- perl/FSM/VIAL/Backend/SVPortableVerilator.pm`
  locates the shipped renderer at `201590d84`. Direct drive now fails its own
  non-root boundary, but that narrow guard neither inventories nor closes the
  general admitted-kind/rendered-kind mismatch.
- [x] **ADDRESSED (verified)** — Clean implementation commit `69384201c`
  permits the pivot. Child `.17.3.5.1.3` alone is active and owns an ordinary-
  source RED, the complete child-operation inventory, compatibility selection,
  deterministic all/any scheduling or exact fail-closed admission, runtime and
  trace/result proof, diagnostics, cleanup, support truth, and documentation.
  No product, test, fixture, contract, capability, or support behavior changes
  in this activation.
- [x] **NO REGRESSION** — The unchanged RAM-guarded portable-emitter suite
  reports `All tests successful` at `Files=1, Tests=8`. All 54 mdBook chapters
  test and the book builds; its generated output is then cleaned. Knowledge Map
  parity holds at 1,150 facts/6,091 questions/6,258 occurrences/133 shards;
  task integrity holds at three trees/995 nodes; claim inventory and its 1,474-
  candidate disposition join pass; all 22 live-document surfaces and both
  maintained references pass with zero ceiling increases. Project locality and
  diff checks pass. No code, test, fixture, ExecutionIR, backend, runtime,
  trace, result, capability, support, scale, performance, capacity, four-state,
  methodology, parity, or public-API behavior changes in this activation.

## Acceptance Checklist (enforced) — `.17.3.5.1.3` portable-SV parallel-child implementation

- [x] **ROOT CAUSE (WHY + WHERE)** — The preserved ordinary-source witness
  replaces one checked-AHB parallel child `await` with `reset`. Target-neutral
  planning still succeeds and retains the exact non-root reset, while the
  pre-repair portable backend returned success, eight complete artifacts, and
  a backend manifest without invoking reset semantics; the RED failed five
  assertions over success, artifact, manifest, and exact diagnostic truth.
  `git log -S'Child fibers are evaluated by this one scheduler' -1 --
  perl/FSM/VIAL/Backend/SVPortableVerilator.pm` locates the property-only
  scheduler at `201590d84`. ExecutionBuilder's recursive action admission and
  the renderer's lack of a child program counter are the exact mismatch.
- [x] **ADDRESSED (verified)** — Decision `0082` selects the qualified public
  revision-1 profile rather than inventing a second execution model:
  negotiation admits only unique direct child fibers containing one terminal
  `await` with exact property/effect/deadline shape and one parallel owner.
  Every other recognized kind, multi-operation child, malformed container or
  await, duplicate/unowned root, forged parent, and multiply owned fiber fails
  before artifacts with stable parent/child identity. Qualified `all`/`any`
  composition remains unchanged. The machine contract publishes
  `general_parallel_child_sequences`; the backend manifest and maintained
  contract/book publish the same boundary. Decision `0077`'s caller-sealed
  balanced revision-2 structural renderer remains separately exact and
  runtime-unclaimed, and its public two-capability bypass rejection is retained.
- [x] **NO REGRESSION** — Changed Perl and test files report `syntax OK`; the
  final guarded capability/planning/emission/parity set passes at `Files=6,
  Tests=35`, including the expanded `t/1557` at `Files=1, Tests=9`. Three of
  four balanced `t/1654` subtests pass after profile separation; its sole fresh-
  prerequisite failure is the portable scale source-identity mismatch
  reproduced unchanged by `t/1650` at clean predecessor `87684237a` and routed
  to proposed `.17.3.5.1.4` with explicit rederive/falsify/durability records.
  A real guarded `t/1558` attempt again reached the existing fixed 30-second
  baseline runtime wall, with no live process or staging residue; `.17.3.5.3`
  remains the exact lifecycle owner. All 54 mdBook chapters test; the inspected
  91-file/19,433,403-byte repository-local render is removed. Knowledge Map
  parity holds at 1,150 facts/6,091 questions/6,258 occurrences/133 shards;
  task integrity holds at three trees/996 nodes; the claim join closes 1,477
  candidates as 887 gates/588 reviewed records/zero gaps; all 22 live-document
  surfaces and both maintained references pass with zero ceiling increases.
  Project locality and diff checks pass. Per CI policy, no unrelated full CI
  runs before push, and no scale, performance, capacity, four-state,
  methodology, parity, or general child-sequence support claim is added.

## Acceptance Checklist (enforced) — `.17.3.5.1.4` portable scale identity reconciliation activation

- [x] **ROOT CAUSE (WHY + WHERE)** — Clean commit `f1b79af06` durably closes
  the prerequisite parallel-child repair. Its separately reproduced current
  and clean-predecessor `t/1650` evidence identifies a stale portable scale
  source oracle after the scheduler/direct-drive repairs, while the existing
  386-byte limit margin is smaller than the observed 414-byte reference drift.
  `git log -S'164_093' --oneline -- perl/FSM/VIAL/ArchitectureScaleBackendEmission/PortableSV.pm
  t/1646-vial-architecture-scale-backend-emission-portable-sv.t
  t/1650-vial-architecture-scale-backend-emission-family-qualification.t`
  locates the original freeze at `5d309b0eb` and its family copy at `86faa137d`.
  The owning card and task evidence explicitly withhold any all-level or
  constant-delta inference.
- [x] **ADDRESSED (verified)** — Child `.17.3.5.1.4` alone is active and owns
  producer-derived level discovery, independent all-level regeneration and
  byte-equal replay, conditional-overhead analysis, mutation falsification,
  an explicit versioned boundary decision if required, every affected
  consumer, and cleanup. Task index, bounded Memory, mdBook, and Knowledge Map
  route to that exact frontier. No product or test behavior changes.
- [x] **NO REGRESSION** — Task-tree integrity remains three trees/996 nodes;
  relative-path verification passes at `Files=1, Tests=2`; Knowledge Map parity
  remains 1,150 facts/6,091 questions/6,258 occurrences/133 shards; project
  locality and diff checks pass. Final claim, containment, staged acceptance,
  and doctrine gates run before this activation commit. No scheduler,
  direct-drive, backend, runtime, trace/result, scale, support, performance,
  capacity, four-state, methodology, parity, or public-API claim changes.

## Acceptance Checklist (enforced) — `.17.3.5.1.4` portable scale identity reconciliation implementation

- [x] **ROOT CAUSE (WHY + WHERE; reproduced RED and origin history)** — Current
  and clean-predecessor `t/1650` both emitted a 164,507-byte reference against
  the frozen 164,093-byte identity. `git log -S'164_093' -- perl/FSM/VIAL/ArchitectureScaleBackendEmission/PortableSV.pm` locates that stale freeze at `5d309b0eb`;
  later phase-rollover `1e9ab0e61` and direct-drive `69384201c` correctness
  repairs change generated scheduler/finalization source. All-level regeneration
  disproves a constant offset: reference grows 414 bytes, while gate and
  qualification grow 532 bytes. The former `T=6,319` limit now renders
  16,777,362 bytes, 146 over the unchanged 16-MiB cap, and rejects exactly.
- [x] **ADDRESSED (verified)** — Decision `0075` selects portable artifact-
  oracle revision 2 and records why semantic rollback or cosmetic source
  shaving is inadmissible. The caller-sealed producer and independent watcher
  freeze exact source totals, fixture bytes/hashes, maps, operation IDs, three-
  source inventories, byte-equal reruns, atomic diagnostics, mutation failure,
  and cleanup for reference/gate/qualification/new `T=6,318` limit plus
  adjacent `T=6,319` rejection. `portable_sv_artifact_graph_v2` and the `.v2`
  schema make the compatibility break explicit while common cross-profile role
  labels and the three unaffected backend oracles stay unchanged.
- [x] **NO REGRESSION** — The guarded all-level portable watcher passes at
  `Files=1, Tests=7` in 84 seconds. Family, balanced emission, and balanced
  runtime qualification pass at `Files=3, Tests=12` in 1,481 seconds; runtime-
  stream construction and both structural-measurement adapters pass at
  `Files=3, Tests=14` in 63 seconds. Changed Perl/modules tests report `syntax
  OK`; exact map/source/result mutation and repository-local staging cleanup
  remain covered. Final mdBook, Knowledge Map, task-tree, claim, containment,
  relative-path, diff, staged acceptance, and doctrine results are recorded by
  this commit workflow. Per CI policy no unrelated full CI runs before push,
  and no external runtime, support, performance, capacity, public scheduler,
  direct-drive, four-state, methodology, or parity claim is added.

## Acceptance Checklist (enforced) — `.17.3.5.1` runtime-stream and lifecycle selection

- [x] **ROOT CAUSE (WHY + WHERE)** — `ArchitectureScaleRuntimeStream` sends
  every selected level through the same checked 21-operation reference route
  and explicitly marks trace/result unmaterialized. The public Runner alone
  owns exact Verilator execution, but its `_run` function keeps prepare,
  compile, run, trace, result, assembly, and cleanup in one transaction;
  `ArchitectureScaleMeasurement` isolates stages in separate forked workers
  and admits no external-tool worker yet. `git log -S` independently identifies
  `3c1f0b411` as the provider-free runtime-stream origin and `dfe87f536` as the
  monolithic Runner origin. Exact qualified public probes then
  disprove the old reachability assumption: the 274-record reference scales by
  five genuine records per added reset cycle, 100,000 hits the 64-MiB runtime
  capture, and 25,000 hits the separate 64-MiB complete-artifact cap.
- [x] **ADDRESSED (verified)** — Decision `0083` selects checked-in authored
  qualification sources, `records(N)=5N+260`, exact 10,000/15,000 gate and
  portable qualification candidates, a reproducible three-quarter full-graph
  admission rule, correctness-only reference, and byte-preflight-dominated
  nominal record limit/excess. It selects one caller-sealed content-addressed
  `VerilatorLifecycle` with forward-only state, canonical reconstruction,
  stable workspace-normalized command identity, exact tool/deadline/capture
  contracts, separate sealed public/measurement storage contexts, process
  containment, and atomic cleanup. Proposed child `.17.3.5.2` explicitly owns
  the portable 100,000-to-15,000 versioned contract repair and final-fixture
  proof; `.3` owns lifecycle implementation. No product behavior changes in
  this selection.
- [x] **NO REGRESSION** — Repository-local probes were run only through the
  ordinary qualified public API under the unchanged 88%-host/4,096-MiB guard.
  They accepted exact 10,000/15,000/20,000 traces and complete graphs of
  32,096,420/47,502,039/62,914,039 bytes, rejected 25,000 at the complete-
  graph cap, and rejected 100,000 at runtime capture; every output and runtime
  staging root was removed after its counts/digests were recorded. The final
  tracked-fixture byte oracle remains deliberately unclaimed until child `.2`.
  The focused documentation/claim/limit/runtime-construction suite passes at
  `Files=12, Tests=113` in 97 seconds. All 54 mdBook chapters test; its inspected
  same-volume render contains 91 files/19,224 KiB, preserves the selected
  headings/equation/lifecycle in HTML, and is removed exactly. Task integrity
  remains three trees/996 nodes; Knowledge Map parity is 1,150 facts/6,096
  questions/6,263 occurrences/133 shards; the claim census closes 1,506
  candidates plus 2,172 current/615 original constants as 895 derived gates,
  588 reviewed records, and 21 explicit durability gaps owned by active parent
  `.17.3.5` until `.2` supplies tracked fixtures/watchers. All 22 live surfaces
  accept the exact zero-file/+180-line/+10,026-byte mdBook authority with zero
  ceiling increases. Final diff, staging-residue, staged acceptance, and
  doctrine results are recorded by this commit workflow. No parser,
  SemanticIR, bridge, ExecutionIR, backend, Runner, trace/result, limit,
  support, performance, capacity, parity, or public-API behavior changes.

## Acceptance Checklist (enforced) — `.17.3.5.2` authored runtime materialization activation

- [x] **ROOT CAUSE (WHY + WHERE)** — Clean selection commit `769df71d5`
  closes decision `0083` and leaves `.17.3.5.2` as the sole dependency-ready
  implementation child. `git log -S` identifies `0e2140791` as the commit that
  first introduced the proposed child beneath active portable-Verilator
  measurement; no later commit activated it before this continuity slice.
- [x] **ADDRESSED (verified)** — Only continuity and its exact governance
  projections now mark `.17.3.5.2` active: the owning task node, parent
  frontier, task index, bounded Memory pointer, mdBook status sentence,
  canonical fact card/Knowledge Map, claim inventory, and live-document
  transition authority. Product, source, test, fixture, oracle, emitter,
  Runner, trace, result, and public contract behavior remain unchanged.
- [x] **NO REGRESSION** — The guarded relative-path/task/Knowledge Map suite
  reports `All tests successful` at `Files=3, Tests=47`; all 54 mdBook chapters
  test. Task integrity remains three trees/996 nodes; Knowledge Map parity is
  1,150 facts/6,096 questions/6,263 occurrences/133 shards; claims remain
  closed at 1,506 candidates plus 2,172 current/615 original constants with
  the same 21 explicit implementation-owned durability gaps. Final live-
  document, diff, staged acceptance, and doctrine gates are recorded by this
  commit workflow with zero ceiling increase and no external process,
  runtime, support, performance, capacity, or reached-boundary claim.
