# HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE: Hardware And Verification Intent Architecture

## Metadata

- Tree ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`
- Status: `active`
- Roadmap lane: `Verification code generation / intent architecture`
- Created: `2026-07-29`
- Last updated: `2026-08-20`
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
  Status: `active`
  Goal: `Implement deterministic architecture-scale workload generation and stage-local correctness oracles.`
  Acceptance: `Generate bounded named workloads from the selected contract across HIAL/VIAL/bridge/execution dimensions with stable identities and seeded content; prove parse/type/bind/plan/emission invariants and deterministic bytes without requiring external runtime execution; publish no support claim before measurement.`
  Verification: `Clean predecessor 62979adc4 closes transcript-limit decision reconciliation before automation. The implementation is decomposed by canonical authority and semantic family: one shared immutable specification/identity/staging foundation, then independent semantic, bridge, execution, checking-state, backend-emission, and runtime-stream/balanced-integration leaves. This activation selects .17.2.1 only and changes no generator, runtime, capability, support record, or scale claim.`
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
  Status: `active`
  Goal: `Generate checking-state workloads with exact stateful-service semantic oracles.`
  Acceptance: `Construct every checking_state_v1 axis with conservative execution topology; exercise rather than merely allocate models, scoreboard capacity, coverage, faults, and random decisions; prove final model state, scoreboard depth/drain, hit vectors, fault restoration, replay identity, normalized reruns, earliest-cap diagnostics, and cleanup without undeclared bins, crosses, or tuples outside an explicitly authored cross's static bin domain.`
  Verification: `Clean execution-graph predecessor 6250cabad closes all 40 selected execution shapes and the complete 29-file architecture family. Completed selection child .17.2.5.1 and decision 0073 choose accepted-or-earliest-cap outcomes for all eight axes, reconcile decision 0055's impossible tuple-list wording with the older shipped static-cross contract, and select a provider-free packed-state evaluator that can exercise one million scoreboard entries and one million coverage bits without a million-operation plan or JSON trace. Implementation parent .17.2.5.2 is now decomposed and active, with only foundation child .1 selected before code. No parser, SemanticIR, bridge, ExecutionIR, checking service, result, backend, capability/support, performance, or capacity behavior changes in either continuity transition.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5: activate checking-state generation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.1`
  Status: `done`
  Goal: `Select canonical reachability and an executable proof method for every checking-state axis before generator implementation.`
  Acceptance: `Audit all eight checking_state_v1 axes and five levels against ordinary VIAL source construction, SemanticBuilder and ExecutionBuilder limits, execution-plan representation, stateful model/scoreboard/coverage/fault/random semantics, normalized result authority, construction envelopes, and repository RAM/time guards. Prove representative routes where inspection is insufficient; select exact accepted or earliest-cap outcomes and a bounded executable method for the two one-million-record levels that exercises semantic state rather than merely allocating declarations. Record the selection in a decision, Knowledge Map fact, mdBook, and task evidence without changing product behavior, admitting undeclared bins/crosses/tuples beyond an authored static cross domain, or borrowing backend-runtime or support claims.`
  Verification: `Decision 0073 closes the complete eight-axis/five-level audit. Canonical RAM-guarded probes accept model instances through 4,096, scalar cells through 65,536, scoreboard instances through 4,096, capacity through 1,000,000, coverpoints through the 8,192 qualification, static coverage materialization through 1,000,000, faults through 4,096, and the 1,024 random gate; each adjacent reachable excess returns its exact semantic or execution-resource diagnostic. Coverpoint limit/excess sources are envelope-unconstructible and carry the separately measured 9,524/9,525 parser boundary. Compact random source parses at 32,768/65,536/65,537, while the plan route accepts 8,440 at 16,775,415 bytes and rejects 8,441 at the 16,777,216-byte cap; the full 32,768 route returns the same diagnostic, 65,536 is preflight-dominated by it, and 65,537 reaches its count cap. The selected provider-free evaluator consumes caller-sealed canonical IR, uses a 4,000,000-byte packed payload FIFO to enqueue/match/drain one million complete scoreboarding transactions, and byte-compares a 125,000-byte million-bit coverage vector. A 62,841-byte source proves exact million coverage via an authored 999-by-999 static cross plus one bin; 62,870 bytes reaches 1,000,001 and is rejected at /coverage. Decision 0073 refines 0055's impossible explicit-tuple-list sentence to the older shipped contract: an authored cross's complete static domain is the product of its explicitly authored point bins, and no backend may invent anything outside it. Trace/result/backend machinery remains excluded as a semantic oracle. The decision, fact card, mdBook, task/index, Memory, containment authority, and doctrine evidence agree; temporary probes were removed exactly.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.1: select packed checking-state proof`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2`
  Status: `active`
  Goal: `Implement the selected canonical checking-state generator and exact stateful-service oracles.`
  Acceptance: `Implement only after .17.2.5.1 commits cleanly; construct every selected checking_state_v1 axis through ordinary VIAL parsing and canonical SemanticIR, bridge, and ExecutionIR producers; execute the selected bounded reference semantics; prove exact final model state, scoreboard maximum/final depth and drain, coverage hit vectors, fault activation/restoration, keyed decisions and replay, normalized reruns, earliest-cap diagnostics, hostile-input rejection, determinism, and repository-local cleanup with default and RAM-guarded qualification tests plus synchronized user documentation.`
  Verification: `Clean selection predecessor a4e45b278 and decision 0073 close reachability and proof architecture before code. Foundation .1 supplies the caller-sealed source/construction/evaluation boundary with frozen canonical stage identities, closed packed/outcome/oracle-evidence schemas, defensive regeneration, and exact same-volume cleanup. Model child .2 owns all eight selected model-instance/scalar-cell shapes and proves every accepted cell through exact packed transitions. Scoreboard child .3 owns all eight selected scoreboard-instance/declared-capacity shapes and proves complete transactions through bounded packed FIFO state, including the exact one-million-entry drain. Coverage child .4 owns all eight coverpoint/static-domain shapes, including source-free decision-0072 envelope results and the exact million-bit all-hit vector. Fault child .5 owns its four selected levels and streams exact arm/apply/expire/restore evidence for every accepted declaration. All completed children retain the checked-AHB foundation as accepted_not_axis_evaluated and keep every capability/support/performance/capacity nonclaim explicit. Random/replay and final qualification remain proposed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2: activate checking-state implementation`
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
  Verification: `Clean activation predecessor e43ecc2e5 grants this leaf sole implementation ownership. ArchitectureScaleCheckingState now publishes all four fault shapes as ordinary compact VIAL and traverses canonical Parser, checked-AHB bridge, and public ExecutionBuilder twice. Accepted 32/1,024/4,096 levels validate the exact transaction/field/domain target, known three-bit substitution, one-drive-interval lifetime, and stable declaration order; the provider-free oracle arms, applies, expires, and restores every fault while streaming four length-delimited lifecycle records per declaration into independently reconstructed order and transition digests. It retains only digests and endpoint witnesses, rejects armed reinjection, active overlap, substitute mutation, declaration-order mutation, source/report mutation, and proves same-volume cleanup after success and failure. The adjacent 4,097 source returns only the exact VIAL_EXECUTION_LIMIT_ERROR at /faults with semantic/bridge but no downstream identity. Default t/1629-t/1633 passes at Files=5/Tests=29 in 97 seconds; exact t/1633 passes at Files=1/Tests=5 in 21 seconds under the 4,096-MiB RAM guard. Random/replay and final qualification remain proposed; no parser, IR, backend, runtime, public API, capability/support, performance, or capacity contract changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.5: implement fault lifecycle checking ladder`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.6`
  Status: `proposed`
  Goal: `Implement random-occurrence, replay, and plan-dominated checking outcomes.`
  Acceptance: `Author the compact Boolean occurrence representation, prove the 1,024 accepted gate's exact keyed values and generated/replayed identity, implement the full 32,768 qualification plan-cap result, the decision-0073 8,440/8,441 opt-in route boundary, preflight-dominated 65,536, and exact 65,537 occurrence-cap rejection; prove mutation/replay/rerun/cleanup and synchronized documentation.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.5.2.7`
  Status: `proposed`
  Goal: `Qualify and close the complete checking-state generator family.`
  Acceptance: `Prove the exact selected-versus-reference ownership partition for all eight axes and five catalog levels; run every default gate plus bounded high-count and opt-in route evidence under the repository RAM guard; prove byte-equal reports, exact same-volume cleanup, hostile caller rejection, Knowledge Map/mdBook/task continuity, and every support/performance/capacity nonclaim before marking .17.2.5.2 and .17.2.5 done.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.6`
  Status: `proposed`
  Goal: `Generate backend-emission workloads through each negotiated canonical emitter with structural artifact oracles.`
  Acceptance: `Consume proved execution graphs for portable SystemVerilog, portable VHDL, OSVVM, and native-UVM emission profiles; prove exact inventory/order/relative paths, source identity and map closure, stable generated identifiers, static checks, byte-equal reruns, earliest-cap diagnostics, atomic no-artifact-before-negotiation behavior, and cleanup without external runtime qualification.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.7`
  Status: `proposed`
  Goal: `Integrate runtime-stream construction and the balanced portable workload, then close deterministic generation proof.`
  Acceptance: `Construct runtime_stream_v1 inputs and semantic/result expectations without executing external tools; compose balanced_portable_v1 only after every orthogonal gate candidate passes; prove exact interaction counts, path-independent identities, deterministic inputs/stage reports, complete oracle applicability, nonclaims, same-volume cleanup, and a unified provider-free construction gate ready for .17.3 measurement.`
  Verification: `pending`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3`
  Status: `proposed`
  Goal: `Measure portable backend generation, compile, execution, result, and artifact scaling.`
  Acceptance: `Run the selected workload profiles under active RAM/time controls for every applicable qualified backend, collect normalized wall/CPU/descendant-RSS/artifact/compile/run/result evidence, prove deterministic reruns and semantic outcomes, and distinguish tool cost from architecture cost without generalizing beyond measured profiles.`
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
closed. Completed `.17.2.5.1` and decision `0073` select every checking-state
accepted-or-earliest-cap outcome plus the provider-free packed-state proof for
the two one-million-state levels. Active implementation parent `.17.2.5.2` now
has its foundation and model children `.1`-`.2` complete and selects scoreboard
child `.3` alone; coverage, fault, random/replay, and final qualification
children `.4`-`.7` follow. Proposed `.17.2.6`/`.17.2.7` and measurement `.17.3`
remain later.

## Decisions

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
