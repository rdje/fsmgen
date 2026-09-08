# HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE: Hardware And Verification Intent Architecture
  Verification: `Clean registry commit 6927bfcfb owns the twelve selected family namespaces and clean activation c7685a046 owns this isolated adapter slice. The required Knowledge Map query returned no common v2 backend-adapter answer. Git history traces the independent native-UVM v1 schema guard to 5a1805f52, portable-VHDL capability list to ab8b1af24, and portable-SV registry entry to 6927bfcfb. Decisions 0050/0051 require distinct public portable-SV, review-only native-UVM, private portable-VHDL, and private OSVVM states. FSM::Support::VIALSemanticFamilyBackendAdapter now publishes one closed content-addressed four-route authority for exact emitter, target mechanism, typed ExecutionIR boundary, accepted v1 schema/profile, output/source-map schemas, atomic artifact model, and independent emission/compile/runtime/result/parity/public maturity. The family registry maps every selected family to all four profiles while every mapping remains unavailable. All four emitters preflight the exact typed/version-consistent IR and complete family/revision/capability/effect set before target rendering; OSVVM rejects before portable delegation or provider verification. T1804 covers deterministic/defensive registry shape, exact maturity isolation, target-mechanism absence from ExecutionIR, untyped/inconsistent/unknown-profile rejection, complete hostile v2 requirement reporting, zero provider/delegation calls, and zero artifact output. Existing successful v1 emitter result shapes remain unchanged, and the public tooling JSON remains exact at SHA-256 42db05da519dffd97c3e40ec254c82d09b5f20ef53a849e53025b976f5aded4e. The final RAM-guarded eighteen-file compiler/backend/reader band passes Files=18/Tests=224, with only the two existing explicit Darwin runtime skips. Every mdBook chapter tests; the inspected repository-local build has 98 files/22,088 KiB and is removed exactly. Knowledge Map parity is 1,160/6,300/6,471/138; claim dispositions close 1,896/1,896 candidates with 316 records, 979 gates, 601 reviewed, and zero gaps/open owners. Containment authorizes the exact 63-file/57,778-line/3,150,863-byte book and 3-file/535-line/29,616-byte VIAL reference, adjusts only existing transition allowances by their prescribed ratchet steps, and raises no ceiling. Final task/path/locality/README/claim/Knowledge/containment/staged-acceptance/doctrine gates and task-local residue checks pass. No family implementation, accepted v2 emission, new compile/runtime/result/parity, public v2 tooling, provider access, support promotion, or HIAL behavior ships.`
## Metadata

- Tree ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`
- Status: `active`
- Roadmap lane: `Verification code generation / intent architecture`
- Created: `2026-07-29`
- Last updated: `2026-09-08`
- Owner: repo-local workflow
- Segment manifest: `docs/tasks/segments/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/manifest.jsonl`

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

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13`
  Status: `active`
  Goal: `Implement native SystemVerilog/UVM through independently honest emission, experimental-probe, and PGEN+NEXSIM qualification slices.`
  Acceptance: `The parent closes only when deterministic efficient readable source-mapped emission ships, any experimental open-source probe remains explicitly non-product evidence, and an exact PGEN+NEXSIM tuple parses/compiles/elaborates/runs the selected native subset into normalized results. Notification/interception semantics use UVM event/callback machinery without exposing target classes or requiring SV/UVM knowledge in authored VIAL; factory/config/TLM plumbing stays backend-private; every exercised/missing capability and applicable parity oracle is exact; inert UVM 1.2 compatibility follows the selected contract; and no first subset or tool result becomes full UVM/VIAL breadth.`
  Verification: `pending children .13.1-.13.3`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15`
  Status: `done`
  Goal: `Implement and capability-qualify the selected VHDL verification backend.`
  Acceptance: `The bounded VIAL subset emits deterministic, efficient, readable, source-mapped VHDL artifacts without requiring VHDL knowledge from a VIAL author, analyzes/elaborates/runs under the exact installed profile, matches the portable normalized result oracle, reports exact standard/methodology/PSL capabilities and non-claims, migrates or versions the inert package exactly as contracted, and leaves HIAL VHDL synthesis output distinct.`
  Verification: `Clean decision/selection predecessor e5aa90b7ad4dc0164bbbdffa285b8351158592e5 activates this implementation parent and child .15.1 alone. Children .15.1-.15.4 can complete deterministic provider-free emission and review without an installed analyzer; .15.5 separately owns exact GHDL execution, while .15.6-.15.7 own OSVVM emission and qualification. Activation changes no source, artifact, capability, support, analyzer, elaboration, runtime, result, or parity behavior.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15: activate VHDL backend implementation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.7`
  Closure: `All seven children are complete. The provider-free VHDL-2008 backend emits its exact readable/source-mapped graph, exact GHDL 6.0.0 analysis/elaboration/runtime produces the bounded trace-v2 normalized result with nineteen applicable portable-SystemVerilog parity paths, and the OSVVM 2026.05 tier materializes and qualifies its exact additive provider/tool route. The inert legacy VHDL package remains separate; HIAL synthesis output remains distinct; PSL, complete VHDL/OSVVM breadth, other simulators, mixed language, general parity, public VHDL API, and general support remain unclaimed. Documentation audit .18.1 closes the stale parent status after reproducing every child as done and finding no remaining .15 acceptance item.`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.16`
  Status: `proposed`
  Goal: `Select and validate the first mixed-language HIAL/VIAL binding profile.`
  Acceptance: `An exact HIAL HDL plus VIAL verification-language combination, tool/version, bridge binding adapter, compile/elaboration/run sequence, capability/non-claim matrix, result parity oracle, project-local artifacts, licensing/CI policy, and unsupported combinations are selected and executed; no mixed-language claim is inferred from single-language gates.`
  Verification: `The 2026-08-10 eligibility census finds Verilator 5.046 and Icarus 13.0 on PATH plus exact repository-local GHDL 6.0.0 LLVM-JIT, but no vsim/Questa, qrun, xrun/irun, VCS, Riviera, NVC, or other compatible mixed-language execution tool. The Icarus version probe referenced one transient off-volume response path; an exact post-command absence check proves it left no residue. Decisions 0032 and 0051 forbid inferring mixed-language qualification from the separately qualified Verilator and GHDL lanes. This leaf remains proposed and unavailable until the external tool state changes; no adapter, execution, capability, or support claim is selected.`
  Commit: `pending activation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17`
  Status: `done`
  Goal: `Define and prove architecture-specific large-fixture scalability and bounded failure.`
  Acceptance: `Deterministic workload profiles scale bridge units/endpoints/domains/transactions/probes and VIAL declarations/scenarios/fibers/events/checks/models/scoreboards/coverage/random decisions; stage correctness oracles, wall/CPU time, descendant RSS, artifact/result size, compile/simulation cost, explicit caps, graceful failures, and stable gates are measured without substituting for the separately owned whole-product big/really-big qualification.`
  Verification: `Clean predecessor 6d23b5843 closes the selected AXI/mdBook activity before this task-tree pivot. The 2026-08-10 eligibility census leaves .16 unavailable, while the shipped and independently qualified portable SystemVerilog, VHDL, and OSVVM profiles provide stable concrete inputs for architecture-specific scale measurement. This activation selects .17.1 alone; it changes no parser, IR, bridge, generator, artifact, runtime, capability, support, or scale claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17: activate scale-proof contract`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.8, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.9`
  Closure: `All nine children are complete. The scale contract, deterministic workload and oracle families, current measurements, cap consistency, representative promotion corpus, qualified budgets, exact public gate, support-limit alignment, containment repair, decision reconciliation, and failed-stage cleanup now form one fail-closed architecture-scale proof. The final clean exact observation at revision 840c895f3 independently closes 11 selected profiles, 11 validations, 33 raw records, 44 controller invocations, zero exclusions, exact public/documentation joins, immutable evidence, atomic latest publication, and zero staging/process/receipt residue. This is bounded HIAL/VIAL regression evidence, not whole-product capacity, mixed-language, arbitrary-tool, native-UVM-runtime, full-language, synthesis, support-promotion, or general-parity qualification.`

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
  Status: `done`
  Goal: `Measure portable backend generation, compile, execution, result, and artifact scaling.`
  Acceptance: `Run the selected workload profiles under active RAM/time controls for every applicable qualified backend, collect normalized wall/CPU/descendant-RSS/artifact/compile/run/result evidence, prove deterministic reruns and semantic outcomes, and distinguish tool cost from architecture cost without generalizing beyond measured profiles.`
  Verification: `Clean unified provider-free qualification commit 490c35cc5 closes deterministic generation before any measured process or tool execution. Decision 0056 freezes the measurement schema, stage boundaries, raw-sample contract, repetitions, 250-ms sampling interval, exact host/tool identities, smaller-of timeouts, 88%-host/4,096-MiB descendant guard, repository-volume staging/publication, exclusion policy, budget formulas, and nonclaims. Completed foundation .1 implements the closed record, validation-before-measurement controller, fork-isolated stage workers, process-tree sampler, effective timeout enforcement, active-guard evidence handoff, defensive validation, and same-volume publication/cleanup. Completed .2-.8 retain accepted semantic/bridge, execution/checking, structural-emission, portable-Verilator, portable-VHDL, exact provider-aware OSVVM, and balanced structural matrices. Completed .9 independently derives all seven authorities/nine families/216 profiles and seals the exact two-file closure with a distinct fresh-process reload. Cap repair and promotion remain separately owned by .17.4/.17.5.`
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
  Status: `done`
  Goal: `Measure exact portable-SystemVerilog generation, compile, run, trace validation, and result production with qualified Verilator.`
  Acceptance: `Use only the qualified Verilator profile and canonical runtime-stream inputs; perform one validation plus required measured repetitions in fresh owned staging; apply effective qualified compile/run limits and active guards; prove artifact, source-map, command, trace closure, normalized result, deterministic rerun, raw-sample, transcript, publication, and cleanup oracles; reject identity drift or excluded samples explicitly; and make no full-SystemVerilog, UVM, mixed-language, promoted-budget, support, or capacity claim.`
  Verification: `Decision 0083's authored 274/10,000/15,000-record route uses the sole qualified lifecycle and common controller. Child .4 retains one/three/five validations or repetitions; child .5 seals five profiles plus both manifests from clean 5268f50e2. Child .6 maps every stale gap to its now-durable materialization/measurement evidence, leaving 1,560/1,560 dispositions, zero gaps/open candidates, and unchanged book behavior. Historical failures and all performance/support/capacity/parity/IASIM/API nonclaims remain explicit.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5: activate portable-Verilator runtime measurement; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2: seal clean portable runtime matrix; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.6: close portable runtime claim gaps`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.6`

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
  Verification: `Current/predecessor t1650 proves 164,507 emitted bytes versus frozen 164,093; history locates oracle 5d309b0eb, rollover 1e9ab0e61, and direct drive 69384201c. Fresh ordinary routes freeze revision-2 T=21/1,024/4,096 bytes 164,507/2,803,857/10,910,865 and maps 54/1,057/4,129. Exact T=6,318 accepts 16,774,723 bytes/6,351 maps; T=6,319 atomically rejects 16,777,362 at the unchanged 16-MiB cap. Distinct deltas falsify padding. Rerun/mutation/family/balanced/runtime/measurement/cleanup gates pass Files=7/Tests=33; decision 0075, book, card, rationale, and consumers agree, with no runtime/support/performance/capacity/public-scheduler claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.4: activate portable scale identity reconciliation; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.1.4: reconcile portable scale oracle revision 2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.2`
  Status: `done`
  Goal: `Implement the selected caller-sealed portable-SystemVerilog runtime-stream materialization and structural oracle.`
  Acceptance: `Implement decision 0083 from canonical child-.1 authority: add checked-in, reviewable gate and qualification VIAL sources with exact N=1,948/2,948 authored reset holds and terminal scale expectation; structurally prove that only the selected reset/timeout/window/expectation deltas differ from the checked reference; version the portable runtime-stream materialization/oracle and replace only sv_portable_verilator's unrepresentable 100,000-record candidate with 15,000 while retaining 10,000 gate and stable role labels. Preserve the ordinary public parse/bridge/plan/emission route; produce deterministic schedule-bound artifacts and exact pre-tool record-family/full-graph projections; independently prove final 15,000 artifacts stay within the three-quarter public byte threshold and 20,000/25,000/100,000 falsifiers remain honestly classified; reject nominal limit/excess and every unrepresentable shape before external execution. Prove source-map, generated-loop, identity, semantic repetition, mutation, atomic failure, and cleanup without runtime source rewriting, padding, truncation, public API widening, or runtime/support/performance/capacity claims.`
  Verification: `Decision 0083/769df71d5 selects two tracked 5,064-byte sources (SHA-256 f9a6a3f...18475/569f9ad...75fa), 1,948/2,948 reset cycles, and a 4,096-cycle envelope. The sealed ordinary Parser/bridge/plan/emitter route twice freezes schedule/artifact/map/loop/stage/report identities. Gate/qualification retain 10,000/15,000 records and 32,098,531/47,505,049-byte graphs; only portable qualification changes from 100,000. Limit/excess and 20,000/25,000/100,000 controls remain pre-tool. Default tests are tool-free; guarded Runner parity leaves zero residue and adds no lifecycle/support/performance/capacity/boundary/parity/API claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.2: activate authored portable runtime materialization; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.2: materialize authored portable runtime streams`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3`
  Status: `done`
  Goal: `Implement the selected shared staged Verilator execution lifecycle without changing the public Runner contract.`
  Acceptance: `Extract one caller-sealed state machine for qualified tool discovery, input preparation, compile, run, trace extraction/validation, result production, final artifact assembly, and cleanup. Persist only closed content-addressed state below an exact repository-owned stage, independently validate every predecessor before transition, preserve process-group termination and capture ceilings, reject skips/replay/mutation/collision/symlink/partial state, and make the existing Runner consume the same transitions with byte-equal success artifacts and stable failure diagnostics.`
  Verification: `Commits bd5c0e628/037c962fd install decision 0083's nine-state Runner/measurement lifecycle with sealed state/inputs/roots/commands, bounded supervision/capture/deadlines, process-group containment, and cleanup. Decisions 0084/0085 and completed .3.1/.3.2 retain intermittent macOS pre-main outcomes through explicit Darwin qualification/default evidence, not a backend workaround. t1664 traverses every state, t1559 keeps AHB parity, non-Darwin t1558 is unchanged, and opt-in Darwin keeps first-failure truth.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3: activate shared staged Verilator lifecycle; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3: implement shared Verilator lifecycle`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.1`
  Status: `done`
  Goal: `Qualify macOS pre-main loader-policy stalls for freshly linked portable-Verilator executables without weakening the backend execution contract.`
  Acceptance: `Preserve the exact lifecycle timing and sampled-stack evidence that distinguishes successful process-group/exec handoff from a zero-output stall in dyld startup. Reproduce and falsify only under explicitly recorded host/OS/tool/concurrent-executable conditions; compare a quiet-host run, macOS policy-daemon activity, generated executable identity/mode/signing metadata, first-output timing, and a non-macOS or otherwise unaffected control when available. Determine whether the cause is operating-system policy contention, generated-binary construction, or another pre-main dependency before selecting any project response. If project handling is warranted, choose a portable production-grade diagnostic or qualification prerequisite through a separate decision; do not kill unrelated workloads, disable platform security, ad-hoc-sign binaries, add retries, widen the 30-second run deadline, or classify a failed run as passing without independently reviewed evidence.`
  Verification: `Lifecycle 037c962fd, activation 1cd7310e9, and decision 0084 select explicit Darwin qualification plus bounded default evidence, not a workaround. On the recorded macOS/Verilator/clang host, generated, byte-identical-path, fresh-C++, and /usr/bin/true controls pass; quiet t1558 passes Files=1/Tests=7 in 167 seconds. These controls refute compiler load, policy CPU, provenance/signature, bytes, and path as individually sufficient, but retain three historical 30-second zero-output stalls and the 2,389/2,389 _dyld_start sample. The guard has zero retries, read-only sampling, same-device closed JSON, and no security/deadline/backend/support/performance/capacity/API change. Default t1665+t1666 pass Files=2/Tests=50; hardened guard Files=1/Tests=27.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.1: activate macOS pre-main qualification; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.1: qualify macOS pre-main stalls`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.2`
  Status: `done`
  Goal: `Resolve standard-CI instability from the retained macOS pre-main stall without weakening runtime failure truth.`
  Acceptance: `Retain a fresh failed primary plus byte-identical-path, fresh-C++, and platform controls under an honest host condition. Preserve the 30-second wall, zero retries, failure truth, containment, cleanup, signing/security, and qualified coverage; prove default CI cannot pass the failure and add no support, performance, capacity, parity, or API claim.`
  Verification: `Complete CI and isolated t1558 fail only different first executions; later routes pass. Fresh evidence reaches exec in 3.653 ms, then fails with zero output at 30.058109 seconds and all 895 sampled frames at _dyld_start; byte-identical-path, fresh-C++, and platform controls pass. Decision 0085 makes Darwin t1558 explicit before discovery, leaves non-Darwin unchanged, and retains t1665/t1666 as failed-primary producer/bounded oracle. sample -file repairs the exact copied/verified/deleted 992-byte off-volume report. Focused defaults pass Files=3/Tests=79; runtime and public contracts remain unchanged.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.2: activate pre-main CI recovery; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.2: make Darwin runtime qualification explicit`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4`
  Status: `done`
  Goal: `Measure each applicable portable-Verilator runtime-stream profile through the common controller.`
  Acceptance: `Reconstruct the selected runtime construction, schedule, emission, tool profile, and lifecycle from repository anchors only. Route applicable validation and gate/qualification repetitions through distinct common-controller stages and the shared lifecycle; retain exact raw samples, tool/command/transcript/artifact/trace/result identities, semantic oracles, exclusions, guard evidence, and cleanup. Keep preflight-dominated shapes tool-free and add no promoted budget, support, capacity, reached-boundary, parity, or public API claim.`
  Verification: `Clean 95ef93f0d supplies one private adapter over the ordinary route, common controller, exact 12-artifact graph, and sole 10/120/30-second lifecycle within 900/300-second worker envelopes. Reference validates once; gate/qualification validate plus three/five repetitions; limit/excess stay tool/controller-free. Reports retain typed commands, transcripts, predecessors, raw stages, trace/result, exclusions, and cleanup. Development preserves two pre-main failures, one descriptor repair, one RAM stop, and exact ownerless-root cleanup. Final guarded 274/10,000/15,000 campaign passes Files=1/Tests=8 in 1,947 seconds; default lifecycle/adapter passes Files=2/Tests=23. No retry, timeout, backend, Runner, support, performance, capacity, boundary, parity, or API change.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4: activate portable-Verilator runtime measurement; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.4: measure portable-Verilator runtime streams`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5`
  Status: `done`
  Goal: `Publish and independently reload the exact portable-Verilator runtime measurement matrix.`
  Acceptance: `Derive the complete profile/level order from producer ownership; isolate capture/reload lifecycles; atomically publish bounded immutable reports at one clean revision/host/tool/guard identity; resume only independently regenerated evidence; reject incomplete, reordered, mutated, mixed, collided, oversized, signalled, stale, or ambiguous state; retain every raw/excluded sample and dominance/nonclaim; and complete guarded capture plus fresh-process reload before closing .17.3.5.`
  Verification: `Child .1 implements the closed isolated publisher and hostile watcher. Child .2 retains both falsified captures, the four-MiB bound and dispatcher repairs, then seals the complete clean 5268f50e2 matrix with exact census and guarded reload.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5: activate portable runtime matrix publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.1: implement portable runtime matrix publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2: seal clean portable runtime matrix`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.1`
  Status: `done`
  Goal: `Implement the bounded immutable portable-runtime matrix publisher and its hostile default watcher.`
  Acceptance: `Derive all profiles and mode routes from producer ownership; publish full reports in isolated close-on-exec children before bounded compact return; require one clean revision/host/tool/guard identity; let tool-free preflight inherit but never originate that identity; atomically publish canonical same-volume single-file profile/family/complete records; and reject caller injection, process/envelope failure, mutation, collision, and ambiguous staging without weakening runtime or claims.`
  Verification: `ArchitectureScalePortableRuntimeMeasurementMatrix derives the ordered five-profile inventory, uses separate 1,048,576-byte raw and 65,536-byte compact envelopes, preserves exact validation/eight-repetition identities and cleanup/dominance/nonclaims, and withholds aggregate seals until complete. Default t1667+t1670 pass Files=2/Tests=15; t1670 covers guard/caller closure, 64-MiB child-only state, exception/exit/signal/malformed/noncanonical/oversized results, immutable collision, exact recovery, ambiguous-stage preservation, preflight identity/tool rejection, mixed identity, reorder, missing/duplicate samples, and forged preflight execution. A guarded independent producer probe re-derives the 74,735-byte reference calibration. Exact qualification remains child .2.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.1: implement portable runtime matrix publication`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2`
  Status: `done`
  Goal: `Seal and independently reload the complete clean-revision portable-runtime matrix.`
  Acceptance: `Run the exact guarded watcher from the committed publisher revision; require all five immutable profile reports, family/complete manifests, exact validation/three/five raw repetitions, two tool-free preflight profiles, one common identity, zero exclusions/residue, file/digest/byte census, real-largest-report bound falsification, and a separate fresh-process guarded reload of the same complete identity. Keep any timeout, signal, guard stop, collision, mismatch, or exclusion failed and resumable only at the exact clean identity.`
  Verification: `Clean 9a534bc93 rejects qualification above the provisional one-MiB ceiling; child .1 selects the derived four-MiB envelope. Clean 80b07d6ee fits the real largest report but exposes preflight dispatch; child .2.2 repairs explicit routing and seals all five profiles plus both manifests at clean 5268f50e2. No failed sample is retried or relabelled.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2: seal clean portable runtime matrix`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.1`
  Status: `done`
  Goal: `Repair the exact-capture-falsified portable-runtime publication ceiling without weakening compact IPC or runtime truth.`
  Acceptance: `Retain the failed 1-MiB exact-capture outcome and independently census the accepted 75,883-byte reference and 848,468-byte three-sample gate publications. Derive a conservative qualification envelope from exact gate bytes, the producer-owned three-to-five repetition change, and the 10,000-to-15,000 trace-record change; select a binary containment ceiling above that projection; expose the derivation through the closed API; report actual and allowed bytes on rejection; keep 65,536/4,096-byte compact IPC/error bounds; and update hostile tests plus task/book/card/claim truth before a new clean-revision capture.`
  Verification: `Clean implementation 9a534bc93 exact t1670 runs 1,964 seconds, publishes canonical 75,883-byte reference and 848,468-byte three-sample gate files with hashes 02ffff64...315/f8a645de...844, then rejects qualification before writing an oversized file or aggregate. The repaired publisher scales the entire gate file by five/three repetitions and 15,000/10,000 records to 2,121,170 bytes, rounds to 4,194,304, retains 65,536/4,096 IPC/error bounds, and reports actual/maximum bytes. The independent qualification diagnostic later hits the already qualified 30-second Darwin pre-main boundary and remains failed without retry or timeout change. Syntax and producer/publisher tests pass Files=2/Tests=14; CI tier passes Files=1/Tests=12; all 56 book chapters test; Knowledge Map is 1,153 facts/6,116 questions/6,283 occurrences/136 shards; claim inventory closes 1,558/1,558 with 40 claims/911 gates/590 reviews/17 gaps/zero open. Task/containment/acceptance/doctrine closure is recorded by the commit workflow with no ceiling increase.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.1: repair portable runtime publication bound`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2`
  Status: `done`
  Goal: `Repeat the complete guarded capture at the repaired clean revision and independently reload its exact aggregate identity.`
  Acceptance: `Remove only the exactly identified superseded portable-runtime publications after retaining their bytes/digests, then run one new clean-revision exact campaign. Require all parent .2 acceptance evidence, retain any Darwin pre-main stall as failed without retry or timeout widening, and close only after fresh-process reload and exact file/hash/staging census.`
  Verification: `At 80b07d6ee, reference/gate/qualification publish as 75,883/847,861/1,730,744 bytes before profile 4 exposes preflight misrouting. Child .1 repairs explicit dispatch. Child .2 re-censuses and removes exactly those three files, then seals/reloads the repaired clean matrix with no retry, timeout widening, exclusion, or residue.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2: activate repaired exact matrix capture; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2: seal clean portable runtime matrix`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.1`
  Status: `done`
  Goal: `Repair the exact-capture-exposed tool-free preflight dispatcher and close its missing real-adapter test seam.`
  Acceptance: `Route producer modes explicitly: validation and preflight through validate_profile, gate and qualification through measure_profile, and reject any unhandled mode. Add focused real-adapter regression evidence for both tool-free levels, retain inherited capture identity and zero controller/tool execution, preserve all immutable publication and failure contracts, and change no timeout, retry, support, performance, capacity, parity, or public API.`
  Verification: `Exact guarded t1670 at clean 80b07d6ee runs 1,979 seconds and fails profile 4 at the validation-versus-measurement dispatcher. _produce_profile_report now routes validation/preflight to validate_profile, gate/qualification to measure_profile, and rejects unknown modes. A real-adapter default regression proves both limit levels remain preflight-dominated without guard, controller, validation record, measurement, cleanup record, or residue. Syntax passes; guarded producer+matrix passes Files=2/Tests=15; all 56 book chapters test; Knowledge Map and 1,558/1,558 claim dispositions remain exact.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.1: repair portable-runtime preflight dispatch`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2`
  Status: `done`
  Goal: `Repeat exact capture at the clean dispatcher-repair revision and independently reload the complete aggregate.`
  Acceptance: `Remove only the three exactly censused superseded publications after retaining their bytes/digests; run one guarded exact campaign; require all five profiles, family/complete manifests, fresh-process reload, exact census, zero staging/residue/exclusions, and retain any failure without retry or timeout widening.`
  Verification: `The retained 75,883/847,861/1,730,744-byte files exactly re-match SHA-256 3e572a7f2f628eefa933a3959bc2c809cc3fc9ef9c61865e7b615cadd1138902/6e15ca49731b5ad2fe1dfff16ccbbe1f86cf6f75ff5ae8c5124b5b1b5e92a8bc/ac6a513c0689b19b57cdef6f2b1b6022b5f9cf6315d511794eb307ada2a11def before exact removal. The first sandbox admission refusal starts no test or profile. From clean 5268f50e2, the real guard admits one campaign and exact t1670 passes Files=1/Tests=7 in 2,142 seconds. Ordered profile sizes/hashes are 75,883/469949f701edce8bd5d17ba625ee54e0e692fb47bf9a1f20a1a74dc061398f12, 849,418/d8f4adf7b31cd34583b233a8b47735d0687463ea8de00967cac408ad97eb9570, 1,722,758/27004018dbe61b287211bfa8bbc9df895a862728dd2869c912cbe71666818959, 6,714/19648a89f652c6da9abf7fc057443ef8017d95abc5d02428dd3b0250f4b468d3, and 6,724/4c97d351fa7c16ba3966dab1e6040dd28051217fa1d043caf96934877ff2d566. Family is 9,832 bytes/960772cf4a6c00be4a6403ece6fc29710d1062ad6b3a5265fdf2c0f619b0d370; complete is 2,750 bytes/0f23f52fccc5d1c8d829aa1f35ef078340dcba0607b8552dc22f9a25f7b208d6. Seven files total 2,674,079 bytes at complete identity portable-runtime-matrix/7673f6be149be57d7963c8ba14fb03dba8604ad523c055de5beb0d8717050426 with five profiles, eight raw/zero excluded records, two preflights, 11 cleanup/zero residue. Separate guarded --validate returns the exact identity; staging and Git remain clean.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2: activate clean repaired matrix recapture; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.2: seal clean portable runtime matrix`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.6`
  Status: `done`
  Goal: `Retire the stale published-runtime durability gaps now satisfied by the completed materialization, measurement, and immutable matrix chain.`
  Acceptance: `Independently map every .17.3.5-owned gap candidate to its current source line and exact re-derivation, falsification, and durability evidence. Replace a gap only when tracked producers and watchers now supply its missing leg; retain any genuinely missing leg under a precise live child. Require a regenerated inventory, complete disposition join, zero open migration owner, and task/book/claim/doctrine continuity without weakening or rewording the published behavior.`
  Verification: `All 17 candidates retain their exact source lines: four rationale-ledger candidates use the adjacent established three-leg derived gate; eleven book candidates join the materialization claim and two join the measurement claim. Guarded t1651/t1663/t1667/t1670 pass Files=4/Tests=33; guarded matrix reload returns the clean 5268f50e2 seal. The regenerated 1,560-candidate join has 54 claim records, 916 gates, 590 reviews, zero gaps/open candidates, and no published-text change.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.6: activate stale runtime claim-gap closure; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.6: close portable runtime claim gaps`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6`
  Status: `done`
  Goal: `Measure exact provider-free portable-VHDL generation, analysis, elaboration, run, trace validation, and result production with qualified GHDL.`
  Acceptance: `Use only the qualified GHDL profile and canonical runtime-stream inputs; perform one validation plus required measured repetitions in fresh owned staging; apply effective per-source analysis/elaboration/run limits and active guards; prove artifacts, source maps, checks, command identity, trace/result parity, deterministic rerun, raw evidence, publication, failure, and cleanup; and make no OSVVM, mixed-language, promoted-budget, support, or capacity claim.`
  Verification: `Clean portable-Verilator closure d21089eb6 leaves this as the next roadmap dependency. The provider-free runtime constructor owns all five portable-VHDL/GHDL roles and exact qualified tool/deadline/command expectations. Query-first source/history audit plus guarded GHDL execution prove that the historical v1 trace closes at 42 records but emits no sample record. Selection provisionally counted 34 barriers and chose reset candidates 9,927/99,927; child .1's direct v2 GHDL trace corrects the omitted final unsupported-size settlement barrier, proving 35 samples and therefore 9,926/99,926 candidates. Decision 0090 retains that transparent correction, one shared staged GHDL lifecycle, exact earlier-cap authority, and five ordered implementation children. Children `.17.3.6.1` through `.17.3.6.4` implement and measure the complete route. Final `.17.3.6.5` seals five profile reports plus family/complete manifests at clean d85256aa8, independently reloads the exact aggregate, and closes zero exclusions/residue without promoting a budget, support, capacity, parity, IASIM, OSVVM, or API claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6: activate portable-VHDL runtime measurement; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6: select sampled portable-VHDL runtime architecture`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.1`
  Status: `done`
  Goal: `Version portable-VHDL trace truth so every real inactive-edge sample barrier emits one compact validated observation snapshot.`
  Acceptance: `Implement the decision-0090 v2 trace contract with an exact header observation catalog, one normalized snapshot per real barrier, closed record/order/time/run/catalog/normalization validation, and result projection shared by qualification and later measurement. Refresh portable-VHDL and impacted OSVVM generated evidence through canonical workflows; preserve logical outcomes, qualified tools, deadlines, public support boundaries, and v1 history; prove malformed/missing/duplicate/reordered/unknown-width/unknown-symbol records fail closed. Change no workload target, lifecycle, performance, capacity, support, mixed-language, or public API claim.`
  Verification: `Emitter revision 6 and one dedicated closed validator atomically replace trace v1 with canonical-LF JSONL trace v2. The header authenticates the ordered HRDATA/HREADYOUT/HRESP/reg_data_q catalog at 32/1/1/32 bits; all 35 real SAMPLE barriers emit one normalized 66-bit snapshot before REACT. Caller authority seals plan, ordered run, catalog, family counts, schema, and limits; malformed/noncanonical/prefix/sequence/count/framing/time/phase/plan/run/catalog/digest/width/symbol/footer mutations fail closed. Direct GHDL proves 19 success plus 16 unsupported-size samples and corrects selection's omitted final settlement barrier: the reference is 77 records and records(N)=N+74, so .2 owns 9,926/99,926 resets. Portable and OSVVM reports/galleries refresh through canonical workflows with unchanged two-scenario outcomes, qualified tools, commands, deadlines, and provider evidence. The fixed 1,504-byte emitter growth rederives the exact structural boundary as accepted T=29,506 at 16,777,107 portable bytes/29,544 maps and rejected T=29,507 at 16,777,675 rendered bytes; OSVVM retains its fixed 4,351-byte adapter. Real guarded qualifications and focused trace/emitter/scale/family tests pass. Post-commit audit under Darwin child `.3.2.2.4` found and repaired omitted t1641/t1651, support, gallery, book, card, audit, and claim fanout; executable projection checks now retain the correction and all runtime-capacity/support/performance/IASIM/public-API nonclaims.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.1: implement authenticated portable-VHDL trace v2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.2`
  Status: `done`
  Goal: `Materialize exact authored portable-VHDL runtime-stream candidates through the canonical source-to-emission route.`
  Acceptance: `After .1 commits cleanly, add tracked gate and qualification VIAL sources whose only permitted semantic deltas are success reset count and matching scenario timeout. Require exact 10,000/100,000 v2 trace projections at reset counts 9,926/99,926, twice-rebuilt Parser/bridge/ExecutionIR/plan/emission identity, exact artifact/map/check inventories, byte-equal reruns, structural equivalence, limit/excess preflight, same-volume cleanup, and an honest stop plus superseding decision if the unchanged 64-MiB envelope dominates.`
  Verification: `The two tracked sources differ from the reference only at the success timeout/reset literals: 16,384/9,926 and 131,072/99,926. The caller-sealed materializer rebuilds construction, Parser, bridge, ExecutionIR, backend inputs, plan, and portable-VHDL emission twice; it freezes exact 21-operation/39-ExecutionIR-map and 17-artifact/six-source/59-emission-map/21-check inventories, 10,000/100,000 N+74 family projections, unchanged sibling reset/timeout and await windows, source/emission/report identities, 64-MiB authority without invented runtime bytes, limit/excess tool-free preflight, hostile mutation rejection, relocation, and success/failure cleanup. Focused and impacted checks pass; GHDL execution remains owned by .3/.4.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.2: materialize portable-VHDL runtime candidates`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.3`
  Status: `done`
  Goal: `Implement one caller-sealed staged GHDL lifecycle for exact qualification and architecture-scale measurement.`
  Acceptance: `After .2 commits cleanly, extract one backend process supervisor from the already qualified production mechanism and make both Verilator and GHDL callers use sealed containment policies without result drift. Implement content-addressed admitted/prepared/tool-verified/analyzed/elaborated/ran/trace-validated/result-produced/assembled/cleaned GHDL states; bind exact provider/source/command/tool identities, 10/120/60/30-second deadlines, 64-KiB/8-MiB/8-MiB/64-MiB captures, mutation/collision/resume/failure controls, whole-tree termination, and exact cleanup. Refactor the checked GHDL qualifier to use the shared fixture lifecycle while retaining its separate four-state provider probe and byte-identical report.`
  Verification: `The shared supervisor and ten-state GHDL lifecycle close exact authority, containment, qualifier/probe reuse, hostile controls, byte-identical report, cleanup, and focused tests.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.3: activate shared GHDL lifecycle; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.3: implement shared GHDL lifecycle`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.4`
  Status: `done`
  Goal: `Measure applicable portable-VHDL runtime profiles through the common controller and shared GHDL lifecycle.`
  Acceptance: `After .3 commits cleanly, reconstruct canonical authority in each isolated worker; map analyze, elaborate, run, trace validation, result production, publish, and cleanup to their exact lifecycle successors; retain one validation plus three gate or five qualification repetitions with raw 250-ms samples, effective inner/outer bounds, commands/transcripts/artifact/trace/result identities, exclusions and zero residue. Keep limit/excess tool-free and add no budget, support, capacity, parity, IASIM, or API claim.`
  Verification: `The caller-sealed adapter reconstructs canonical materializer, route, six-source compiler order, provider, common-controller and lifecycle authority in every worker; reference accepts one validation, gate one validation plus three retained 10,000-record repetitions, and qualification one validation plus five retained 100,000-record repetitions. All 11 records bind exact command/transcript/source/emission/predecessor/trace/result identities and lifecycle/controller cleanup; limit/excess remain tool-free. Exact guarded t1674 passes Files=1/Tests=8 in 490 seconds; final guarded impacted qualification/controller/lifecycle/adapter coverage passes Files=10/Tests=72. The shared-lifecycle watcher replaces a Darwin shebang-loader stall and signed-binary relocation control with a repository-local compiled native fixture, preserves primary failure without cascading, and reports empty-output exit/signal evidence. Syntax, mdBook, Knowledge Map, claims, task, containment, locality, cleanup, staged acceptance, and doctrines pass; no full CI or push occurs at this ordinary slice.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.4: activate portable-VHDL runtime measurement; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.4: implement portable-VHDL runtime measurement`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5`
  Status: `done`
  Goal: `Publish and independently reload the complete immutable portable-VHDL runtime measurement set.`
  Acceptance: `After .4 commits cleanly, derive the five-level inventory from producer ownership; atomically publish bounded raw reports plus compact manifests at one clean revision/host/tool/guard identity; reject incomplete, reordered, mutated, mixed, stale, collided, signalled, oversized, or ambiguous state; retain all raw/excluded samples, applicability, earlier-cap dominance, cleanup and nonclaims; complete guarded capture plus separate fresh-process reload before closing .17.3.6.`
  Verification: `Clean predecessor e7203c278 supplies the exact five-shape producer, 11 accepted runtime records across reference/gate/qualification, tool-free limit/excess reports, complete raw evidence and cleanup, and the decision-0090 publication contract. Activation a4ed37ae3, implementation e4f4a295e, exact-trigger repair 07875ea75, and artifact-cardinality repair d85256aa8 close the implementation chain. The final guarded t1675 campaign passes Files=1/Tests=7 in 656 seconds and seals seven immutable files totaling 1,354,895 bytes at clean d85256aa806a8dbdcf89c0e14b6bad9521521168. Ordered reference/gate/qualification/limit/over-limit files are 96,509/444,601/787,082/6,723/6,733 bytes with SHA-256 595fa131eff99fa757a3525b527a9501532f6552267016c72235ddc7a6e3b82f/69645cdaf83b266af90067c0050d9a5ef1defc6660b257f59ae2998b63946e87/9281d49f449373ac957880f1082651838ddaaabcdd6b4166aefae67986682def/95239333b5ea49af1549280d200a1e960844c13f6a553a05c005314dc47ed004/691dad9e2bd7a43f8526f073c9fabf6291eb18ffb6015602556b9c8773394743. Family is 10,201 bytes/51f0dd36a5d2aa39c7f23b4f5e65df3e9580c0feafff2814757dca57949dd835; complete is 3,046 bytes/17963981c274a83c62278065c5a1d704628e63bab97298d584ac9105e0a212b0. A separate guarded `--validate` returns complete identity portable-vhdl-runtime-matrix/cf0844de188b3a07ec7ed8026dcdfd95551cf7202b3df528659456da6e00e329. Independent `find`/`wc`/`shasum`/`jq` confirms five profiles, three validations, eight raw/zero excluded records, two preflights, 11 cleanup/zero residue, 17 artifacts for every executable profile, common GHDL 6.0.0 LLVM-JIT/M4 Pro/APFS/active-guard identity, 66,321,782 bytes below the unchanged file ceiling, and absent staging/log residue with clean Git.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5: activate portable-VHDL measurement publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5: implement portable-VHDL measurement publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5: isolate portable-VHDL exact trigger; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5: repair portable-VHDL artifact cardinality; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.5: seal portable-VHDL measurement publication`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7`
  Status: `done`
  Goal: `Measure exact OSVVM methodology generation, analysis, elaboration, run, trace validation, and result production with the qualified provider and GHDL.`
  Acceptance: `Verify exact provider commit/tree/manifest/licence/notice identity before work; consume only the qualified OSVVM plus GHDL profile and canonical runtime inputs; perform validation and measured repetitions with qualified limits and guards; retain separate provider-verification, FSMGen, and external-tool stages; prove adapter/portable artifacts, mappings, trace/result semantics, raw evidence, deterministic rerun, atomic publication, failure, and cleanup; and make no provider-generality, mixed-language, promoted-budget, support, or capacity claim.`
  Verification: `Clean activation 402ccada5 owns selection. Query-first cards and decisions 0051/0056/0088/0090 bind the exact provider/tool and measurement contracts. Direct live verification accepts OSVVM commit 2f7c391051dfb11890fa4bdbda9918d1db492250, tree bd4fdc594f2c26d564cf8907ff599578b9a39e22, and the checked 14-repository/13-gitlink/14-licence/zero-notice census; a guarded exact OSVVM/GHDL qualifier matches its checked report and its empty parent stage is removed. Source/history audit finds no measurement owner and proves the existing runtime expectations, callback-scoped provider/emission route, monolithic qualifier, and portable single-command lifecycle cannot substitute for one another. Decision 0092 reuses the exact authored VHDL runtime sources, selects a profile-specific materializer, extracts one closed provider/tool execution plan, versions the shared lifecycle by sealed role, and orders five implementation children through measurement and publication without changing any provider/tool/runtime/product claim. All five children are done. Clean implementation revision ef10332d6 seals seven immutable OSVVM publications totaling 6,105,680 bytes; guarded exact t1680 and a distinct guarded reload accept complete identity osvvm-runtime-matrix/5429888419a848d28ff4250833e6bd60e31d583d3054a7929d1df3e21420e219 with three validations, eight raw/zero excluded measurements, two preflights, eleven cleanups, and zero residue. The exact provider/tool/host/guard tuple remains pinned and no budget, support, capacity, provider-generality, parity, mixed-language, or public-API claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7: activate OSVVM runtime measurement; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7: select provider-aware OSVVM runtime measurement`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.1`
  Status: `done`
  Goal: `Materialize the exact OSVVM runtime profiles through the authored VHDL source-to-wrapper route.`
  Acceptance: `Reuse the decision-0090 tracked reference/gate/qualification sources without duplication; construct the OSVVM workload identity; rebuild semantic/bridge/plan authority twice; perform one callback-scoped exact provider verification; prove seven sources, portable byte identity, adapter/mapping/source-map/check/guard closure, trace projections, deterministic emission, mutation rejection, and same-volume cleanup; keep limit/excess provider-free and tool-free.`
  Verification: `Clean selection 40db785ee and activation 004723562 precede one caller-sealed implementation. The exact OSVVM workload reuses the decision-0090 reference/gate/qualification sources and portable semantic/stage/report authority, then one callback verifies the pinned provider once for two byte-identical emissions. Each materialized role retains 21 operations, 39 ExecutionIR maps, 16 artifacts, seven VHDL sources, 66 emitted maps, twelve OSVVM checks, seven advanced mappings, six byte-identical portable sources/guards, and exact 14/13/14/0 provider repository/gitlink/licence/notice census. Reference/gate/qualification source totals are 122,413/122,426/122,438 bytes and complete graph identities are frozen. Limit/excess construct exact OSVVM identities but remain provider-free, route-free, staging-free, and tool-free. Hostile source/report/seam/invocant/relocation/staging controls fail closed; existing portable and OSVVM backend-emission reports remain byte-identical; no external tool, runtime, trace/result, support, performance, capacity, boundary, provider-generality, mixed-language, or API claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.1: activate exact OSVVM runtime materialization; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.1: implement exact OSVVM runtime materialization`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.2`
  Status: `done`
  Goal: `Extract one closed OSVVM/GHDL provider, generated-source, fixture, probe, and report execution-plan authority.`
  Acceptance: `Derive the exact qualified source order, generated settings, libraries, provider/generated analyses, fixture/probe elaboration and run commands, report inventory, normalized identities, deadlines, capture limits, repository-relative paths, and provider/tool/source seals from current authorities; reject caller substitution and retain the checked qualifier as executable oracle without running a second implementation route.`
  Verification: `Clean materialization implementation 90c4d9abd and activation 2a05f70ec own one exact-class, caller-sealed plan authority for reference/gate/qualification only. Each closed in-memory plan binds the exact materialization/workload, pinned OSVVM commit/tree/manifest and 61 provider analysis inputs, GHDL archive/binary/version, seven generated sources plus the checked probe, generated settings, three libraries, 61 ordered provider analyses, generated analysis, separate fixture/probe elaboration and run commands, four supplementary reports, deadlines, capture ceilings, safe repository-relative storage, and zero execution/staging. Exact identities are frozen for all three plans. The live qualifier consumes the same private authority and remains byte-identical to the checked 74,976-byte executable oracle; limit/excess fail before provider/tool access. Focused t1677 passes Files=1/Tests=4, the live qualifier passes Files=1/Tests=3, and the guarded impacted OSVVM suite passes Files=6/Tests=76. Mutation, preflight, unknown-key, direct-seam, subclass, source/tool/oracle, path, report, and cleanup controls fail closed. No lifecycle admission, measurement, runtime, support, performance, capacity, provider-generality, mixed-language, or public-API claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.2: activate exact OSVVM execution-plan extraction; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.2: implement exact OSVVM execution-plan authority`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.3`
  Status: `done`
  Goal: `Add the provider-aware role to the shared GHDL lifecycle and refactor exact OSVVM qualification onto it.`
  Acceptance: `Preserve portable lifecycle/report bytes while admitting only the sealed OSVVM plan; execute ordered provider/generated analysis plus fixture/probe elaboration/run through the shared process supervisor; retain per-command captures, supplementary reports, portable trace/result authority, content-addressed forward states, timeout/signal/capture/mutation/collision controls, pre/post provider identity, and exact cleanup; require the checked qualifier report to remain byte-identical.`
  Verification: `Clean execution-plan implementation 89c33b96e and activation 9fe67ba0d precede one caller-sealed provider-aware implementation. The lifecycle retains the portable v1 authority unchanged and admits the qualifier only through a distinct v2 authority over generated settings, three exact libraries, every ordered provider analysis, generated analysis, separate fixture/probe elaboration and execution, deterministic supplementary report snapshots, portable trace/result truth, and the existing state/object/predecessor/supervisor/cleanup mechanism. Every external-command transition revalidates the exact GHDL provider, ordered source set, and generated settings once, while every command retains its own supervisor capture. The checked OSVVM qualifier now uses only this lifecycle and reproduces its 74,976-byte report byte-for-byte; the checked portable qualifier also remains byte-identical. Focused t1678 proves role/schema sealing, ordered captures, exact policies, setting/plan/report failures, and cleanup; the impacted suite passes Files=7/Tests=37. Measurement, publication, support, performance, capacity, provider-generality, mixed-language, and public-API claims remain deferred.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.3: activate provider-aware GHDL lifecycle role; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.3: implement provider-aware GHDL lifecycle role`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.4`
  Status: `done`
  Goal: `Measure applicable OSVVM runtime profiles through the common controller and provider-aware lifecycle.`
  Acceptance: `Reconstruct canonical source/provider/emission/plan authority in every worker; map all decision-0056 stages to the selected lifecycle; retain reference validation, gate validation plus three records, qualification validation plus five records, exact provider/FSMGen/tool evidence, commands/transcripts/reports/trace/result identities, exclusions, active guards, failure, and both cleanup domains; keep limit/excess preflight-only.`
  Verification: `Clean lifecycle implementation f76431606 and activation c3aba3976 precede one caller-sealed common-controller adapter. The adapter reconstructs canonical authored route/materialization/plan authority in every isolated worker, verifies and emits the provider graph at emit, relocates seven generated sources into the exact 68-source lifecycle plan, and maps provider/generated analysis, dual elaboration, one fixture plus one provider-probe execution, portable trace/result validation, post-provider verification, publication, and both cleanup domains onto the fixed controller stages. Guarded exact t1679 passes Files=1/Tests=8 with 305 guarded sub-assertions in 2,041 seconds: reference accepts one 77-record validation, gate accepts validation plus three 10,000-record measurements, and qualification accepts validation plus five 100,000-record measurements. All eleven records retain 61 provider-analysis captures, two elaboration captures, one fixture/probe capture pair, four reports, exact commands/transcripts/source/provider/trace/result identities, zero exclusions, and zero residue. Limit/excess remain provider/plan/controller/lifecycle/tool-free; hostile caller/guard/selection/report/oracle/failure controls reject. The guarded focused impact passes Files=9/Tests=50 in 254 seconds. No publication, support, performance, capacity, boundary, provider-generality, mixed-language, or public-API claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.4: activate common-controller OSVVM runtime measurement; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.4: implement common-controller OSVVM runtime measurement`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.5`
  Status: `done`
  Goal: `Publish and independently reload the complete immutable OSVVM runtime measurement set.`
  Acceptance: `Derive all five roles from producer ownership; isolate capture and reload; bind one clean revision/host/provider/tool/guard identity; retain raw/excluded samples, provider applicability, dominance, supplementary evidence, cleanup, and nonclaims; reject incomplete/reordered/mixed/stale/collided/signalled/oversized/ambiguous state; repair the impacted Darwin lifecycle watcher's same-volume native fixture if linker-signature execution stalls block focused signoff; complete guarded capture plus distinct fresh-process reload before closing .17.3.7.`
  Verification: `Clean predecessor 03292cd1e supplies the exact five-role producer, eleven accepted runtime records across reference/gate/qualification, provider/plan/controller/tool-free limit and excess reports, complete raw/provider/report/trace/result evidence, and both cleanup domains. Query-first source/history audit finds no OSVVM matrix owner; portable-Verilator origin 9a534bc93 and portable-VHDL origin e4f4a295e are each sealed to their producer, profile, report schema, tool tuple, publication namespace, and aggregate identities. Clean activation 2f48bf26a and implementation ef10332d6 precede one OSVVM-specific publisher that derives producer order, isolates capture/reload children, publishes raw canonical reports before bounded compact entries, and seals family/complete manifests only over one clean revision/host/provider/tool/guard identity. Hostile watcher coverage rejects guard/caller/mode/IPC/signal/collision/recovery/ambiguity/preflight-identity/order/sample/common-identity drift. Focused signoff also root-causes a Darwin external-volume linker-signature stall in t1678's generated fake GHDL and explicitly ad-hoc signs only that test binary; the pinned production GHDL is unchanged. Default t1676-t1680 pass Files=5/Tests=30 in 144 seconds. From an empty OSVVM namespace, guarded exact t1680 passes Files=1/Tests=8 in 2,974 seconds and a distinct guarded `--validate` exits zero. Seven immutable files total 6,105,680 bytes: ordered reference/gate/qualification/limit/over-limit profiles are 482,870/2,196,439/3,398,045/7,497/7,507 bytes; family/complete manifests are 10,173/3,149 bytes. Their exact hashes and complete identity are retained in the book and claim record. Independent `find`/`wc`/`shasum`/`jq` confirms five profiles, three validations, eight raw/zero excluded records, two preflights, eleven cleanup/zero residue records, 16 artifacts per executable profile, exact pinned provider/GHDL/M4 Pro/APFS/active-guard identity, 63,710,819 bytes of publication headroom, absent staging residue, and clean Git. No budget, support, capacity, provider-generality, parity, mixed-language, or public-API claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.5: activate OSVVM measurement publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.5: implement OSVVM measurement publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7.5: seal OSVVM measurement publication`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8`
  Status: `done`
  Goal: `Measure the caller-sealed revision-2 balanced portable composition without widening any public contract.`
  Acceptance: `Run the exact decision-0077 balanced source-to-portable-SystemVerilog route through the common measurement foundation; prove all six fresh prerequisite gates, bridge/ExecutionIR/binding/operation/artifact/map identities, deterministic bytes, stage-local costs, raw samples, effective guard/timeouts, atomic publication, failure, and cleanup; measure external execution only if its separately qualified route is applicable; and preserve all public AHB/revision-1/support/performance/capacity nonclaims.`
  Verification: `Clean OSVVM seal 9fde163ae closes the preceding roadmap leaf before this pivot. Query-first audit of decision 0077, the balanced composer/emitter, unified provider-free qualifier, book, card, and source history finds one exact owned shape and no balanced measurement adapter or publisher. The balanced emitter stops after structural emission and no separate runtime qualification admits its private revision-2 bridge. Child `.1` implementation 91ceaf9eb adds the exact guarded adapter, one validation plus three raw records, producer-sealed stage seams, structural-only applicability, failure evidence, and cleanup. Child `.2` implementation 118b3bfb6 adds isolated immutable publication; guarded exact t1682 then passes from that clean revision in 5,575 seconds and independently reloads the three-file/1,280,699-byte accepted set with zero exclusions/residue and unchanged runtime/product nonclaims.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8: activate balanced portable measurement`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.1`
  Status: `done`
  Goal: `Measure the exact balanced portable structural route through the common controller.`
  Acceptance: `Derive only balanced_portable_v1/sv_portable_verilator/gate_candidate_v1 from the unified qualification owner; reconstruct all six fresh gate reports in one caller-sealed canonical validation authority, then recreate only construct, parse_validate, bridge, bind_plan, or emit work inside its isolated common-controller worker; retain one correctness validation plus three raw measured records, exact checked sources, revision-2 bridge, 2,048 bindings, 1,024 operations, eight artifacts, three sources, 503,279 source bytes, 3,605 maps, deterministic bytes, active guard/timeouts, atomic failure, and cleanup; mark compile_analyze through result_produce inapplicable because no separately qualified private-revision-2 runtime route exists; reject caller evidence and preserve every public/revision-1/support/performance/capacity nonclaim.`
  Verification: `Executable RED t1681 first fails because ArchitectureScaleBalancedPortableMeasurement is absent. The implemented exact adapter derives one member from the unified owner, reads only the checked repository anchors, seals six fresh prerequisite reports before the controller, admits five FSMGen-owned structural stages, retains one validation plus three raw gate records, and validates every record, oracle, artifact, cleanup, applicability, and nonclaim independently. Exact-caller seams in the composer and emitter reject public/caller evidence while preventing prerequisite work from contaminating stage-local costs. The first guarded exact run fails closed at bridge because duplicated prerequisites exceed its 120-second boundary; the second reaches emit then fails closed because the public evaluator repeats composition inside its 300-second boundary. Stage-local producer seams remove both misclassifications without changing public evaluation. The corrected guarded exact t1681 passes Files=1/Tests=5 in 3,545 seconds, including mutations and forced worker failure, with zero staging residue. Focused public composer/emitter/qualifier and doctrine gates complete before commit; external execution and all runtime/support/performance/capacity/public-bridge claims remain absent.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.1: implement balanced portable measurement`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.2`
  Status: `done`
  Goal: `Publish and independently reload the immutable balanced portable measurement set.`
  Acceptance: `Derive the one balanced gate role from producer ownership; isolate capture and reload; atomically retain the complete validation plus three raw reports before bounded coordinator IPC; bind one clean revision/host/internal-tool/guard identity; preserve applicability, exact structural evidence, exclusions, cleanup, and nonclaims; reject incomplete, reordered, mixed, stale, collided, signalled, oversized, symlinked, or ambiguous state; and complete guarded capture plus a distinct fresh-process reload before closing .17.3.8.`
  Verification: `Clean predecessor 91ceaf9eb supplies the sole member, four structural records, closed applicability/nonclaims, failure/cleanup evidence, and zero residue. Knowledge Map and history find no balanced publisher, runner, watcher, or namespace; the three existing publishers are sealed elsewhere. Clean implementation 118b3bfb6 derives the one role, isolates capture/reload, publishes the canonical report before bounded IPC, atomically seals profile/family/complete layers at one clean identity, and rejects caller evidence, drift, collision, child failure, unsafe paths, and ambiguous staging. Guarded exact t1682 passes Files=1/Tests=6 in 5,575 seconds, including a fresh runner identity check. Independent census seals three files/1,280,699 bytes with exact hashes, one validation, three raw/zero excluded samples, four cleanup/zero residue records, external execution inapplicable, absent staging, and clean Git. No runtime, budget, capacity, support, parity, provider, or public-API claim is added.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.2: activate balanced measurement publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.2: implement balanced measurement publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.8.2: seal balanced measurement publication`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9`
  Status: `done`
  Goal: `Close the measured family with immutable raw evidence, derived views, and candidate pinned-host/tool budgets.`
  Acceptance: `Independently regenerate every applicable family/profile/level ownership and measurement record; require complete validation/three-run gate or validation/five-run qualification evidence; derive minimum/median/maximum/MAD without discarding raw samples; freeze exact host/tool applicability and decision-0056 candidate formulas from accepted clean samples; distinguish FSMGen/tool/artifact costs; record exclusions, dominant caps, nonclaims, and residue; reject mutation or missing members; and leave cap implementation to .17.4 and public budget/support promotion to .17.5.`
  Verification: `Clean balanced-publication seal 6c68b4cf9 closes .17.3.8 before this pivot. Knowledge Map/decision-0056 audit plus source/history search found seven independently sealed matrix authorities but no cross-publication owner, statistics or candidate-budget derivation, closure runner, or aggregate namespace. Child .1 closes the exact derivation; child .2 clean revision b66de5ce6 atomically publishes and freshly reloads the exact two-file closure under publication identity calibration-closure-publication/1316d11a6dfa008515fcb23aa132e30a72e7961d9e9e6eeba82ae0bf42546ac8. No cap, performance gate, capability, support, capacity, or public API is promoted.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9: activate measured-family calibration closure`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.1`
  Status: `done`
  Goal: `Implement the independent measured-family derivation and candidate-budget authority.`
  Acceptance: `Derive the complete measured member set from canonical workload and matrix producers; independently reload and validate every immutable profile/family/complete publication; require one validation plus three accepted gate records or five accepted qualification records; preserve raw and excluded records; derive minimum/median/maximum/MAD and decision-0056 wall/CPU/RSS candidates with exact integer rounding; partition FSMGen, external-tool, and artifact cost; retain exact revision/host/tool/guard applicability, dominant caps, cleanup, and nonclaims; and reject missing, duplicated, reordered, mutated, mixed-identity, unsupported, or caller-supplied evidence without promoting a budget.`
  Verification: `RED t1683 rejects stale backend-emission v1 after portable-SV oracle v2; seal 0601fa8aa preserves v1. Guarded exact t1683 passes Files=1/Tests=2 in 14,954 seconds with 7 authorities/9 families/216 profiles/356 raw/0 excluded records under calibration-closure/92ef0a203e18ce8de8b17cf819f36b73fe0889f00fdcb4def8b2b0e9eeb9dcc5; its 1,374,727-byte report SHA is f6cc10c3a4c198d856470783cb7a836ee0d7e84c57a15bf7ae0f1208ef390d7c. Census verifies 232 same-volume artifacts/28,398,586 bytes/hashes. `.2` owns publication, `.17.4` caps, and `.17.5` promotion.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.1: activate measured-family derivation; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.1: implement measured-family derivation; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.1: seal backend-emission v2 prerequisite; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.1: seal measured-family derivation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.2`
  Status: `done`
  Goal: `Atomically publish and independently reload the immutable measured-family closure.`
  Acceptance: `Consume only the caller-sealed derivation authority; isolate capture and reload; publish complete raw-evidence references, derived views, candidate budgets, applicability, exclusions, dominant caps, cleanup, and nonclaims under one repository-local content identity; reject partial, stale, mixed, collided, signalled, oversized, symlinked, or ambiguous state; and prove a distinct fresh process returns the same closure identity before completing .17.3.`
  Verification: `Clean activation 3c226831f precedes implementation. Executable RED t1684 first finds no publication module. The exact-class publisher derives only through the closure authority in an isolated child, atomically publishes a canonical report plus compact manifest, reloads in another child, and rejects caller injection, process/path/identity/size/collision/staging drift. Fast t1683+t1684 pass Files=2/Tests=8. From clean implementation b66de5ce6, guarded exact t1684 passes Files=1/Tests=6 in 7,353 seconds and a distinct process reloads publication identity calibration-closure-publication/1316d11a6dfa008515fcb23aa132e30a72e7961d9e9e6eeba82ae0bf42546ac8. Independent census proves exactly two files/1,376,483 bytes on the repository device: the 1,374,728-byte report SHA-256 is 1a060b166d6b7d88582ee1fec9ae0f255fc3859ef16918227670e095b99e10e0 and the 1,755-byte manifest SHA-256 is ae5c11ac9848f47bfe3f06905f7a059399e07f25c827dd85b900896c14d175ef; no staging residue or Git drift remains.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.2: activate measured-family closure publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.2: implement measured-family closure publication; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.9.2: seal measured-family closure publication`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4`
  Status: `done`
  Goal: `Implement and prove explicit architecture resource caps and graceful bounded failure.`
  Acceptance: `Apply the selected caps at the earliest authoritative stages with deterministic diagnostics, atomic no-partial-output behavior, same-volume cleanup, boundary/over-bound tests, and unchanged accepted-profile semantics; host exhaustion and external-tool crashes are not accepted as product limit enforcement.`
  Verification: `Clean predecessor b441e7a8b closes measured-family publication. The activation partitions cap work by authoritative stage under decisions 0056/0059/0072, preserves all selected measurement levels, and changes no product behavior or claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4: activate architecture cap hardening`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`
  Closure: `All eight children are complete. Current caps retain earliest-stage deterministic admission, diagnostics, atomic no-partial-output behavior, no-tool short-circuiting, same-volume cleanup, accepted identities, and an independent 23-group/161-dimension closeout. Decision 0095 and the caller-sealed disposition preserve the immutable calibration closure as authentic historical evidence across exact bridge and VHDL-derived drift without promoting budgets, support, or capacity. The next clean activation is .17.5.`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.1`
  Status: `done`
  Goal: `Select the reconciled cross-layer architecture resource-cap and bounded-failure contract from immutable evidence before changing enforcement.`
  Acceptance: `Inventory every selected semantic/parser, bridge, execution, checking, backend-emission, runtime-stream, transcript, result, timeout, publication, and cleanup boundary against its declared contract, actual earliest decider, diagnostic/path, construction order, atomicity, and existing boundary proof. Resolve every unreachable or dominated declared cap under decisions 0056 and 0072; choose deliberate layering, a higher lower-layer limit, or a lower public declaration with explicit compatibility and rollback analysis. Preserve selected workload levels and all support/capacity/performance nonclaims. Record the selection in a decision, Knowledge Map, mdBook, task evidence, and focused executable contract tests without changing product behavior.`
  Verification: `Decision 0093 retains component-local ceilings and selected levels while separating earliest route authority and measured boundary. The versioned ArchitectureScaleCapPolicy joins every live catalog axis to one stage owner, validates declared values/profiles/envelopes, and rejects missing-axis or re-levelled mutations in t1685. The mdBook and Knowledge Map carry the same no-capacity/no-behavior-change rule; .17.4.2 remains the next proposed leaf until a clean activation commit.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.1: select layered architecture cap policy`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2`
  Status: `done`
  Goal: `Enforce the selected source, parser, and SemanticIR resource caps at their earliest authoritative stages.`
  Acceptance: `Implement only the .17.4.1-selected semantic/parser contract; reject boundary excess before dependent expansion with stable diagnostics and paths, unchanged accepted SemanticIR, and no partial result or residue. Prove every semantic_catalog_v1 boundary and interaction, including literal-repeat versus expanded-action dominance, with focused default and guarded exact tests.`
  Verification: `Clean selection commit 951720257d727e79f9e0986955655c8d330e0079 closes .17.4.1 before this pivot. Activation commit 93adfbd82 owns only source/parser/SemanticIR earliest-cap hardening under decision 0093. The first implementation slice reserves scenario action capacity before inspecting a next node and admits repeat copies with overflow-safe arithmetic; t1686 proves over-limit and exact-full precedence with no partial report, while t1550/t1601/t1620/t1621 retain accepted and established boundary behavior. The direct-import slice preflights an already-visible 65th edge before recursive imported-source parsing; t1687 proves malformed imported bytes cannot mask the exact diagnostic and pins accepted 64-import projection/report identities. The parallel-fiber slice admits the known 257-fiber excess before join-value resolution; t1688 proves an invalid join cannot mask the exact diagnostic and pins accepted 256-fiber projection/report identities. The declaration slice admits each known section excess before later package-section shape parsing; t1689 proves a malformed later section cannot mask the exact diagnostic and pins accepted 4,096-declaration projection/report identities. The service-scalar slice admits scoreboard capacity before transaction resolution and cross max_bins before coverpoint resolution/product calculation; t1690/t1691 prove hostile references cannot mask either exact limit and pin accepted one-million projection/report identities. The type-shape slice proves existing list length, record field count, and aggregate depth admission before inner-type resolution; t1692 pins hostile-inner precedence and all three exact-boundary identities without a product-code change. The source-byte slice proves per-source and combined bytes are admitted before lexing each affected source; t1693 pins malformed-byte precedence and exact 1-MiB/16-MiB identities without a product-code change. The guarded exact t1601 matrix passes every selected qualification, limit, over-limit, and repeat/action interaction in 84 seconds; focused precedence, docs, claims, containment, and complete doctrines are green. `.17.4.2` is exhausted; bridge and later layers retain their separate proposed owners.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: activate semantic cap hardening; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: enforce action cap before further construction; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: preflight direct import fan-out before recursion; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: admit parallel fiber cap before join resolution; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: admit declaration caps before later sections; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: admit service scalars before reference resolution; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: prove type-shape preflight order; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: prove source-byte admission order; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2: close semantic cap hardening`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4`
  Status: `done`
  Goal: `Enforce the selected execution-graph resource caps before avoidable graph, random, source-map, or plan materialization.`
  Acceptance: `Implement only the .17.4.1-selected execution contract; preserve the existing compact total-operation and serialized-plan preflights, repair remaining late checks, and reconcile binding/type/map limits with lower bridge and byte authorities. Prove deterministic diagnostics, no partial ExecutionIR/plan/replay, unchanged accepted plans, and guarded execution_graph_v1 boundaries.`
  Verification: `The named commits and t1624/t1625/t1705-t1710/t1634 close every selected execution group with early or layered authority, terminal defense, stable accepted identities and diagnostics, atomic failure, and green doctrines.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: activate execution cap hardening; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: preflight execution fiber cardinality; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: preflight execution profile cardinality; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: preflight per-scenario operation cardinality; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: admit execution type before insertion; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: admit source map before insertion; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: preflight execution binding cardinality; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: prove random-attempt authority; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4: prove serialized-plan authority`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.5`
  Status: `done`
  Goal: `Enforce the selected checking-state resource caps before avoidable state-service materialization.`
  Acceptance: `Implement only the .17.4.1-selected checking contract for models, scalar cells, scoreboards and capacity, coverage, faults, and random occurrences. Preserve exact accepted checking semantics and replay while proving earliest deterministic rejection, no partial checking result, bounded construction, and guarded checking_state_v1 boundaries.`
  Verification: `Commit f49dd3e99 completes all selected compact preflights with terminal defenses and stable accepted plans. Guarded exact t1630-t1634 passes every checking boundary at Files=5/Tests=28 in 561 seconds; .17.4.5 is exhausted.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.5: activate checking cap hardening; same work-unit: preflight model, scoreboard, coverage, fault, and random-occurrence cardinality; same work-unit: close checking cap hardening`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.6`
  Status: `done`
  Goal: `Enforce the selected backend-emission resource caps before partial artifact publication.`
  Acceptance: `Implement only the .17.4.1-selected profile-specific generated-byte, artifact, and source-map boundaries for portable SystemVerilog, portable VHDL, OSVVM, and native-UVM emission. Reject before final artifact graphs or provider/tool use when authority is already known; preserve accepted artifact bytes, ordering, identities, provider boundaries, atomic staging, and backend nonclaims.`
  Verification: `Clean df5129126 closes .17.4.5 and activation f6b2f8504 confines this leaf to four profile-local pure emitters. Portable SystemVerilog retains byte-first map-cap preflight; portable VHDL retains byte-first fixed inventory plus map census without a map cap; OSVVM admits its portable foundation and translated map before lazy provider verification; native UVM retains selected-shape negotiation, then byte-first fixed inventory and map-cap preflight. Every accepted map/inventory agrees with materialization and every terminal defense remains. RED-to-green t1716-t1719, policy, shipped regressions, and guarded exact profile oracles preserve diagnostics, accepted identities, provider/tool boundaries, atomicity, and nonclaims. All four profiles are closed; .17.4.7 remains proposed until a clean activation pivot.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.6: activate backend-emission cap hardening; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.6: preflight portable-SV source maps; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.6: preflight portable-VHDL artifact inventory; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.6: admit OSVVM provider after portable foundation; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.6: close native-UVM emission admission`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7`
  Status: `done`
  Goal: `Enforce the selected runtime-stream, transcript, trace, result, timeout, and external-tool envelopes through the shared lifecycle.`
  Acceptance: `Implement only the .17.4.1-selected runtime contract; preflight known structural and complete-graph excess before tool eligibility, bound compile/run capture and time, validate trace/result record and byte ceilings, and withhold partial public graphs. Preserve accepted runtime semantics, qualified tool profiles, shared same-volume lifecycle, stable sanitized diagnostics, and exact success/failure cleanup.`
  Verification: `Clean activation 2a47761a5 assigns the selected portable-SystemVerilog, portable-VHDL, and OSVVM runtime-stream group to this leaf; native UVM remains emission-only. Portable SystemVerilog now preflights structural, trace, result, and final graph envelopes, retains exact phase authority on supervisor failure, and removes only proven-owned staging. Portable VHDL and OSVVM retain phase diagnostics unless cleanup becomes authoritative, use the stable tracked fake provider, distinguish probe timeout, and require exact cleaned/removal/no-residue abort evidence. GHDL admission validates canonical result bytes and closed shape; binds plan, run, scenario, fixture, domain, random-decision, diagnostic, parity, aggregate, and trace-derived timing identities; and emits full per-scenario time reset with CHECK-ranked endings. OSVVM preflights the exact same-volume report inventory before reads and rechecks size drift. Resumed portable/OSVVM state reauthenticates supervisor policy and timing, transcripts, reports, prepared workspace, commands, trace/result/assembly evidence, terminal payload semantics, append-only object history, caller authority, selected version, and generated settings. Object writer/resume admission closes descriptor fields, canonical numeric bytes, JSON-boolean executable authority, content-addressed paths, same-volume bytes/digests, and exact `0600`/`0700` modes. State files are exact `0600` same-volume regular files bounded at 1 MiB; the closed numeric-version owner marker is exact `0600` and bounded at 4 KiB; atomic writes normalize mode independent of umask. t1736-t1747 reject isolated descriptor/state/owner/type/storage/validation/outer-file controls while installed portable and OSVVM qualification remain byte-identical. Handle/state schema versions and ordinals plus caller provider/source bytes, expected counts/catalog widths, repetition count, storage version, OSVVM command-plan version, and generated-settings bytes are canonical JSON integers before semantic, filesystem, trace, or digest work; enum/identity/path fields remain scalar. Persisted OSVVM lifecycle-request reload admits its envelope version and run repetition as canonical JSON integers, re-derives the selected six-field OSVVM and seven-field GHDL provider projections, reconstructs the workload/materialization/plan/source/command emission identity, reuses final-report validation to bind the exact relocated 68-source/61-provider-command plan, admits the closed five-field lifecycle-storage projection, and reconstructs all nine lifecycle-validation fields from materialization, sealed ExecutionIR, and checked observation authority before predecessor, lifecycle, or tool work. The outer request and predecessor handle now require symlink-free same-volume/current-owner/single-link exact-`0600` files, stable opened metadata, 64-KiB/4-KiB bounded reads, and umask-independent exclusive writes before decode or resume. Exact committed verification, checklists, and commit history through `6fe704c7b0a8ec45d31f188f235eceeec388499b` remain independently retrievable through the bounded acceptance-history manifest below. Common-controller worker-artifact reread admission is the next audit.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: activate runtime-stream cap hardening; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: preflight runtime structural artifact graph; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: preflight runtime trace artifact bytes; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: preflight runtime result artifact bytes; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: enforce final lifecycle artifact graph; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: map runtime supervisor failures to phases; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: preserve GHDL cleanup diagnostic authority; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: report GHDL admission cleanup exactly; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: stabilize fake-GHDL host runtime; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: repair GHDL probe timeout authority; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: preserve GHDL probe-abort cleanup authority; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: enforce GHDL result byte canonicality; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: close GHDL result manifest shape; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL result plan identity; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL scenario/run identities; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: close GHDL nested result shape; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: repair GHDL scenario cycle projection; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL parity outcome values; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: close GHDL top-level result values; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL fixture and random decisions; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: close GHDL scenario identity projections; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL scenario domain authority; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL passing diagnostics; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL aggregates to trace counts; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL diagnostics to expectation traces; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind GHDL scenario boundary times; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: preflight OSVVM provider report bytes; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: authenticate GHDL capture evidence; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: reconstruct GHDL state evidence; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: authenticate GHDL terminal payloads; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: authenticate Verilator terminal payloads; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: authenticate GHDL authority objects; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: authenticate GHDL object descriptors; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: authenticate GHDL state and owner files; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: enforce GHDL handle and state JSON types; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: enforce GHDL request JSON types; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: enforce OSVVM persisted request types; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind OSVVM persisted provider authority; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind OSVVM persisted GHDL provider; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind OSVVM persisted emission identity; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind OSVVM persisted command and source plan; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind OSVVM persisted lifecycle storage; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: bind OSVVM persisted lifecycle validation; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7: admit OSVVM outer persisted JSON files`
  Closure: `The terminal sentence in the earlier Verification snapshot is superseded: common worker artifact admission, bounded output/recovery census, process-group and detached-descendant containment, authenticated bounded cleanup, the synchronous selected-tool boundary, bounded host observers, monotonic TERM/KILL and reap, interruption-safe owned-child/observer/containment-pipe polling, and timeout-primary observation precedence are complete across the 15 commits from 156f27788 through 1f3dac39e. Git now retains 59 .17.4.7 work-unit commits. Every appended acceptance checklist is checked; the complete RAM-guarded t1720-t1749/t1751-t1762 leaf passes Files=42, Tests=184 in 258 wallclock seconds; source audit finds no further independent unbounded supervisor retry. The runtime-stream leaf is exhausted. Cross-family closeout .17.4.8 remains proposed until a separate clean activation commit.`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`
  Status: `done`
  Goal: `Prove cross-family cap consistency, atomic failure, cleanup, and durable closeout before promotion.`
  Acceptance: `Independently enumerate every selected cap and owning stage; require boundary and adjacent excess evidence, stable diagnostic family/path/requested/allowed data where safe, no partial final output, no external-tool invocation behind known excess, exact repository-local cleanup, and unchanged accepted-profile identities. Revalidate all immutable calibration publications or version them explicitly after intentional behavior changes, synchronize task/decision/Knowledge Map/mdBook truth, and close .17.4 without promoting budgets, support, or capacity.`
  Verification: `Clean 5583365cb closes the complete runtime-stream leaf after its guarded closure suite and source census. Decision 0093 assigns this final child the independent cross-family consistency, atomic-failure, cleanup, immutable-publication, and durable-closeout proof. Activation changes no product behavior, cap, publication, support statement, budget, or capacity claim. The first implementation slice must enumerate the live cap policy and every closed child evidence owner before selecting the smallest missing cross-family proof.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8: activate cross-family cap closeout; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8: disposition historical calibration`
  Inventory: `Clean activation 02768a427 enables the read-only first slice. The live policy exactly joins 50 catalog axes to 23 groups, 19 selected interactions, six non-axis envelopes, four backend profiles, and three runtime profiles; all 70 declared group-evidence references and every interaction/envelope evidence path exist. That establishes selection and declared-value alignment, not final closeout: runtime_stream_envelopes still cites only t1663/t1672/t1676 and t1685 has no runtime-group-specific assertion, so none of the completed t1720-t1749/t1751-t1762 evidence is independently joined. The 256-file immutable calibration store and its b66de5ce6 closure manifest remain internally addressable, but the publication explicitly denies cap_implementation and predates every .17.4 child. Re-derive: build the policy and independently census its catalog join/evidence paths. Falsify: t1685's missing-axis mutation and an existence check over every referenced path reject omissions. Durability: this task, the synchronized book/card frontier, and the work-unit commit retain the result. The next slice adds a caller-sealed cross-family closeout layer; it must consume current policy authority internally, distinguish measurement publication from cap proof, and bind each selected group to boundary/excess, diagnostics, atomicity/no-tool, cleanup, and accepted-identity evidence before any calibration disposition.`
  Foundation: `Executable RED t1763 first fails only because ArchitectureScaleCapConsistency is absent. The exact-class implementation accepts no inputs, rebuilds the current policy internally, and emits all 23 selected groups and 50 axes with the same seven closed evidence dimensions. Every dimension begins pending with no promoted evidence; policy paths remain candidates. Exact schema, invocant, argument, group, axis, authority, candidate-evidence, dimension, defensive-copy, and mutation checks fail closed. The historical calibration authority remains measurement-only, cap_implementation remains a prohibited relabel, and disposition stays blocked until every sealed dimension is independently verified. Focused t1763+t1685 passes Files=2/Tests=84 without executing a product route or external tool. The next slice independently joins the completed runtime-stream leaf.`
  Runtime Join: `The caller-sealed consistency authority now promotes only runtime_stream_envelopes. A one-entry-per-test classification maps the three selected materialization profiles and all 42 completed t1720-t1749/t1751-t1762 hardening leaves across boundary, adjacent excess, diagnostics, atomicity, no-tool, cleanup, and accepted identity; the union is exact and every path exists. T1763 independently reconstructs each ordered evidence array, requires that complete 45-path union, and rejects omitted or foreign runtime evidence. All other groups remain pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute all sealed paths through the RAM-guarded 46-file suite. Falsify: the exact union plus omission/foreign mutations fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the classification. The complete suite reports All tests successful at Files=46/Tests=210 in 417 wallclock seconds. No cap, level, accepted profile, behavior, publication, support, budget, or capacity claim changes. The next slice independently joins backend_artifact_graph. Adjacent doctrine finding: the rationale-ledger manifest is at ordinal 2907 while DEVELOPMENT_NOTES_INDEX.md still advertises 2905; the range-ID-only index check does not catch the mismatch, so a separate clean task-tree slice must reconcile the displayed row and add a numeric-cell falsifier before the next rationale append.`
  Backend Join: `The caller-sealed consistency authority now also promotes backend_artifact_graph. A one-entry-per-test classification maps the four profile foundations t1646-t1649, their cross-profile qualification t1650, and the four t1716-t1719 admission-order hardeners across boundary, adjacent excess, diagnostics, atomicity, no-tool, cleanup, and accepted identity. T1763 independently reconstructs every ordered projection, requires the exact nine-path union, checks path existence, and rejects omitted or foreign backend evidence; its generic defensive-copy check now preserves the selected group's actual sealed state rather than assuming the alphabetically first group is pending. Runtime remains verified and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute all nine evidence paths plus t1763 and t1685 through the repository-local RAM guard. Falsify: t1763's exact projections, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the classification. The complete guarded suite reports All tests successful at Files=11/Tests=241 in 566 wallclock seconds. No cap, level, accepted profile, provider boundary, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews the smallest remaining two-witness group, checking_models.`
  Checking Models Join: `The caller-sealed consistency authority now also promotes checking_models. T1630 owns exact model-instance and scalar-state-cell limit admission, adjacent rejection, provider-free state evaluation, same-volume cleanup, and deterministic construction/evaluation/rerun identities; t1711 independently proves compact count agreement, accepted plan identity, rejection before model normalization, and no partial ExecutionIR or plan. T1763 reconstructs the two-path projections and union, checks both paths, and rejects omitted or foreign evidence. The omission falsifier removes one of two adjacent-excess witnesses so the exact sealed-authority comparison is exercised; removing the sole boundary witness correctly fails earlier at the non-empty verified-evidence shape gate. Runtime/backend remain verified and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1630 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1711, t1763, and t1685 under the repository-local RAM guard. Falsify: exact limit and adjacent cases plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the classification. The guarded suite reports All tests successful at Files=4/Tests=104 in 100 wallclock seconds. No cap, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews checking_faults.`
  Checking Faults Join: `The caller-sealed consistency authority now also promotes checking_faults. T1633 owns exact fault limit admission, adjacent rejection, provider-free lifecycle evaluation, same-volume cleanup, mutation defenses, and deterministic construction/evaluation/rerun identities; t1714 independently proves compact count agreement, accepted plan identity, rejection before fault normalization, and no partial ExecutionIR or plan. T1763 reconstructs the two-path projections and union, checks both paths, and rejects omitted or foreign evidence. Runtime/backend/checking-model remain verified and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1633 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1714, t1763, and t1685 under the repository-local RAM guard. Falsify: the exact 4,096/4,097 boundary pair plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the classification. The guarded suite reports All tests successful at Files=4/Tests=98 in 21 wallclock seconds. No cap, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews checking_randomness.`
  Containment Finding: `The canonical Knowledge Map cards now occupy 46,939 lines/3,464,850 bytes against the older .17.4.7 transition allowance of 46,942 lines/3,464,885 bytes, leaving three lines/35 bytes while remaining far below the hard 65,536-line/4,194,304-byte enforcement ceiling. Re-derive: aggregate tracked docs/knowledge Markdown with wc and add the knowledge_cards baseline to its declared transition max_growth. Falsify: scripts/check_live_document_size.sh rejects transition-budget or hard-ceiling excess. Durability: this task, doctrine/live_document_size/surfaces.jsonl, and the work-unit commit retain the distinction. The next evidence-family sync must compact the canonical card rather than silently increase its allowance.`
  Checking Randomness Join: `The caller-sealed consistency authority now also promotes checking_randomness without pretending that its nominal component cap is canonically reachable. T1634 proves a provider-free accepted 8,440-occurrence route, adjacent 8,441 plan-byte rejection, explicit 65,536-occurrence preflight dominance, 65,537 occurrence rejection, replay identities, mutation defenses, and same-volume cleanup; t1715 independently proves compact occurrence agreement, accepted plan identity, rejection before operation materialization, and no partial ExecutionIR or plan. T1763 reconstructs the two-path projections and union, checks both paths, and rejects omitted or foreign evidence. Every earlier verified group remains sealed and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1634 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1715, t1763, and t1685 under the repository-local RAM guard. Falsify: both route and component boundary/excess pairs plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, decision 0093, and work-unit commit retain the layered classification. The guarded suite reports All tests successful at Files=4/Tests=98 in 411 wallclock seconds. No cap, route boundary, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews checking_scoreboards.`

  Checking Scoreboards Join: `The caller-sealed consistency authority now also promotes checking_scoreboards through three layer-specific witnesses. T1631 owns both exact scoreboard axes, the provider-free complete-transaction FIFO oracle, adjacent rejection, identities, mutation defenses, and same-volume cleanup. T1690 independently proves that the semantic scalar capacity boundary admits before reference resolution and its adjacent excess returns no partial semantic report. T1712 is deliberately not classified as boundary evidence: it owns compact execution preflight agreement, accepted plan identity, both normalized-path adjacent excesses, no scoreboard normalization, and no partial ExecutionIR or plan. T1763 reconstructs every ordered projection and the exact three-path union, checks each path, and rejects omitted or foreign evidence. Every earlier verified group remains sealed and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1631 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1690, t1712, t1763, and t1685 under the repository-local RAM guard. Falsify: semantic, execution, and terminal boundary/excess controls plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the layer-specific classification. The guarded suite reports All tests successful at Files=5/Tests=119 in 23 wallclock seconds. No cap, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews checking_coverage.`

  Checking Coverage Join: `The caller-sealed consistency authority now also promotes checking_coverage without pretending the nominal coverpoint component cap is canonically reachable. T1632 owns the exact static-domain limit, adjacent rejection, provider-free packed-vector oracle, identities, mutation defenses, same-volume cleanup, and the lower source-byte route boundary that preflight-dominates the nominal coverpoint cap. T1691 independently proves exact semantic cross-scalar boundary/excess order and no partial semantic report. T1713 is deliberately not boundary evidence: it proves compact accepted-count agreement and plan identity plus both normalized-path adjacent excesses before coverage normalization, ExecutionIR, or plan publication. T1763 reconstructs every ordered projection and exact three-path union, checks each path, and rejects omitted or foreign evidence. Every earlier verified group remains sealed and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1632 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1691, t1713, t1763, and t1685 under the repository-local RAM guard. Falsify: fixture-envelope, parser-route, semantic, execution, and terminal boundary/excess controls plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, decision 0093, and work-unit commit retain the layered classification. The guarded suite reports All tests successful at Files=5/Tests=120 in 67 wallclock seconds. No cap, route boundary, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews the one-witness bridge_profile_cardinality group.`

  Bridge Profile Join: `The caller-sealed consistency authority now also promotes bridge_profile_cardinality through its one complete family witness. T1602 already executes selected_units and selected_domains at exact limit and adjacent excess, freezes accepted construction/manifest/report/input/review-route identities, and owns same-volume success/failure cleanup. This slice closes its evidence gap by requiring every construction to retain unset backend/tool selectors and every expected rejection to publish empty metrics plus no manifest/report identity. The exact mode re-executes all thirteen bridge axes at qualification, limit, and excess, so the profile classification is not inferred from a gate-only control. T1763 reconstructs the same single path in every dimension, requires its exact one-path union, rejects empty verified evidence before authority comparison, and rejects foreign evidence through that comparison. Every earlier verified group remains sealed and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1602 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1763 and t1685 under the repository-local RAM guard. Falsify: exact profile boundary/excess, partial-output, no-selector, union, empty-evidence, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, strengthened foundation test, consistency source/test, and work-unit commit retain the classification. The guarded suite reports All tests successful at Files=3/Tests=90 in 128 wallclock seconds. No bridge cap, profile, accepted identity, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews bridge_serialized_manifest.`

  Bridge Serialized Manifest Join: `The caller-sealed consistency authority now also promotes bridge_serialized_manifest through two complementary witnesses. T1602 owns the exact provider-free workload ladder, stable enclosing-route diagnostics and atomicity, repeatable identities, and same-volume cleanup. T1704 independently observes the terminal canonical encoding after structural-limit and semantic-identity validation: 16,777,216 bytes admit with a frozen SHA, while the first complete valid record above the cap encodes to 16,777,219 bytes, returns the stable manifest-root limit diagnostic, and exposes no manifest or report. T1763 reconstructs the exact two-path projections, limits no-tool and cleanup evidence to t1602, requires the complete union, and rejects empty or foreign evidence. Every earlier verified group remains sealed and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1602 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1704, t1763, and t1685 under the repository-local RAM guard. Falsify: exact workload/terminal boundary, complete-record excess, validation-order, diagnostic, atomicity, projection, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, policy decision 0093, and work-unit commit retain the layered classification. The guarded suite reports All tests successful at Files=4/Tests=106 in 139 wallclock seconds. No bridge cap, canonical encoding, accepted identity, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews bridge_normalized_collections.`

  Claim Disposition Finding: `Adding exact serialized-manifest byte results to the closeout chapter caused the producer-derived claim census to emit two open candidates. Root cause was broader than missing per-claim records: the newer 16df closeout chapter was absent from the required-complete verification_architecture disposition group, so it had no candidate routing until its first actionable numeral appeared. This slice registers 16df, dispositions both byte claims through non-aliased producer, terminal-oracle, and watcher legs, and restores zero open owners/gaps. Re-derive: regenerate the inventory and join it through the disposition checker. Falsify: either an ungrouped path or an absent/malformed disposition fails closed. Durability: this task, disposition group, two sorted disposition records, generated inventory, and work-unit commit retain the repair.`

  Bridge Normalized Collections Join: `The caller-sealed consistency authority now also promotes bridge_normalized_collections through eleven deliberately asymmetric witnesses. T1602 alone owns all ten exact collection boundaries, first constructible excesses, provider-free construction, same-volume cleanup, and exact workload identities. T1694 through t1703 each own one collection's first constructible excess, stable normalized path and diagnostic, atomic no-manifest/no-report result, and frozen representative accepted identity; none is upgraded to exact-boundary, no-tool, or cleanup evidence. The backend-binding witness honestly preserves 16,386 as its first constructible shape above the 16,384 cap, and t1703 stops before source-map record 65,537 materialization. T1763 reconstructs the exact per-dimension projections and eleven-path union, checks every path, and rejects empty or foreign evidence. Every earlier verified group remains sealed and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1602 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1694 through t1703, t1763, and t1685 under the repository-local RAM guard. Falsify: all ten exact boundary/excess ladders, ten malformed-last-record precedence controls, source-map materialization spy, projection, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, policy decision 0093, and work-unit commit retain the layered classification. The guarded suite reports All tests successful at Files=13/Tests=221 in 159 wallclock seconds. No bridge cap, collection shape, accepted identity, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews execution_profile_selection.`

  Normalized Collections Containment Resolution: `The Knowledge Map card reached only 20 lines/664 bytes below its inherited transition allowance after the normalized-collection sync. This slice removes one duplicate evidence path and compacts repeated layer summaries plus completed-join prose without changing answers, evidence, reverify routes, cap semantics, or the allowance. Re-derive: aggregate tracked docs/knowledge Markdown and compare it with the declared baseline plus transition growth. Falsify: Knowledge Map and live-document gates reject lost answer parity, missing evidence, or allowance drift. Durability: this task, compacted card, generated shards, containment manifest, and work-unit commit retain the resolution.`

  Execution Profile Selection Audit Finding: `The execution_profile_selection candidate inventory is not complete enough to promote. T1616 proves the 512-scenario qualification point and t1618 proves the 4,097-scenario rejection, but the executable policy omits t1617, the existing exact 4,096-scenario acceptance and identity oracle. It also omits t1603, which freezes the selected_fixtures, selected_units, and selected_domains scalar workload profiles as deliberately unowned and proves every such construction request fails closed at the caller-sealed generator boundary; t1705 separately proves the ordinary accepted one-unit/one-domain route and defensive two-unit/two-domain admission. History shows 951720257 introduced the candidate group with t1616 alone, while 612db31d7 added t1618/t1705 without the two complementary witnesses. This active .17.4.8 slice owns repairing the candidate inventory, strengthening exact scalar/no-tool facts where required, and only then binding independently classified dimensions. Re-derive: inspect the policy group, exact scenario ladder, fixed-scalar catalog frontier, and t1705 admission route, then run the seven-file candidate/policy/consistency baseline under the repository RAM guard. Falsify: removing either omitted witness makes exact-boundary or fixed-scalar route classification impossible without overstating the remaining tests. Durability: this task entry owns the defect before source changes; the completed slice must synchronize policy, consistency authority, tests, book, Knowledge Map, and work-unit history.`

  Execution Profile Selection Join: `The repaired policy now cites the complete five-witness set, and the caller-sealed consistency authority promotes execution_profile_selection without flattening their roles. T1617 plus t1705 own exact boundary admission; t1603, t1618, and t1705 own fixed-scalar/scenario/unit/domain first excess, diagnostics, and atomicity; t1603, t1616, t1618, and t1705 explicitly prove no backend/provider/tool selection; t1616 alone owns same-volume success/failure cleanup; and t1616, t1617, and t1705 freeze accepted identities. T1603 additionally freezes every fixed-scalar workload ladder at 1/1/1/2, while t1705 freezes the accepted resource summary at one fixture, unit, and domain. T1763 reconstructs every projection and the exact five-path union, checks each path, and rejects empty or foreign evidence. The intended RED exposed one policy inventory mismatch, 21 pending status/evidence/rationale assertions, and two inactive mutation controls; the completed guarded suite reports All tests successful at Files=7/Tests=114 in 36 wallclock seconds. Every prior group remains sealed, every unaudited group remains pending, and calibration remains historical/incomplete/blocked. Re-derive: run t1603, t1616 through t1618, t1705, t1763, and t1685 under the repository RAM guard. Falsify: exact ladder, selector, cleanup, resource-summary, boundary/excess, diagnostic, pre-materialization, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, repaired policy, consistency source/test, focused witnesses, book, Knowledge Map, decision 0093, and work-unit commit retain the result. No cap, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews execution_operation_cardinality.`

  Execution Profile Claim Disposition Finding: `The user-facing five-witness explanation produced three new actionable candidates: the 512 qualification point, exact 4,096 scenario limit, and adjacent 4,097 rejection. Each is now a derived-gate disposition with non-aliased generator/contract re-derivation, the three focused scenario oracles as falsifiers, and the repaired policy plus sealed consistency authority as durability watchers. Re-derive: regenerate the producer-derived inventory and join every candidate through the required-complete verification_architecture group. Falsify: removing a disposition, producer, oracle, watcher, or current candidate identity fails closed. Durability: the disposition registry, generated inventory, this task, and work-unit history retain the result at 1,716/1,716 disposed candidates, 944 derived gates, and zero gaps/open owners.`

  Execution Profile Containment Resolution: `The Knowledge Map card had only 31 lines/1,426 bytes of inherited transition headroom after the first execution-profile sync. Compacting repeated stage summaries and coalescing evidence paths, without changing answers, facts, exact numeric claim lines, or the allowance, reduces the aggregate from 46,911 lines/3,463,459 bytes to 46,899 lines/3,462,703 bytes and restores 43 lines/2,182 bytes of headroom. Re-derive: aggregate tracked docs/knowledge Markdown against the declared baseline plus transition growth. Falsify: Knowledge Map and live-document gates reject answer drift, missing evidence, stale derived shards, or allowance drift. Durability: this task, compacted card, generated map, containment manifest, and work-unit commit retain the resolution.`

  Execution Operation Cardinality Audit Finding: `The execution_operation_cardinality candidate inventory is incomplete across both owned axes. It cites t1620's per-scenario nominal-cap/plan-byte dominance, t1626's total-operation exact preflight and adjacent excess, and t1706's compact preflight hardener, but omits t1619's accepted 8,192-operation qualification and exact plan identity, t1621's genuine 65,537-operation semantic excess, and t1622's 65,536-total-operation qualification/plan-byte dominance. The omission dates to 951720257; 9c091a7c5 added the compact hardener without repairing the pre-existing ladder inventory. The complete eight-file policy/candidate/consistency baseline is green at Files=8/Tests=123 in 175 wallclock seconds under the repository RAM guard, so this is evidence-inventory debt rather than a runtime regression. This active .17.4.8 slice owns repairing the exact six-witness policy inventory, adding explicit no-tool and same-volume cleanup proof where the existing ladder is silent, and only then binding independently classified dimensions. Re-derive: run git log -S'execution_operation_cardinality' over the policy, inspect t1619 through t1622 plus t1626/t1706, and run those six witnesses with t1763/t1685 under the RAM guard. Falsify: omitting any ladder member loses the accepted qualification, per-scenario first semantic excess, total qualification, terminal dominance, compact exact boundary, or adjacent aggregate excess required for an honest two-axis join. Durability: this task entry owns the defect before source changes; the completed slice must synchronize policy, consistency authority, tests, book, Knowledge Map, and work-unit history.`

  Execution Operation Cardinality Join: `The repaired policy now cites the complete six-witness set across operations_per_scenario and operations_total, and the caller-sealed consistency authority promotes execution_operation_cardinality without flattening their different route outcomes. T1620, t1626, and t1706 own exact component-boundary admission; t1621, t1626, and t1706 own first excess; t1620 through t1622 plus t1626/t1706 own stable diagnostics and atomicity; all six witnesses now explicitly prove absent backend/provider/tool selection; t1619 alone owns same-volume success/failure cleanup; and t1619, t1620, t1622, t1626, and t1706 freeze accepted plan or stage identities. Later serialized-plan dominance remains a route fact rather than a false component-cap failure. T1763 reconstructs every projection and the exact six-path union, checks each path, and rejects empty or foreign evidence. The intended RED exposed one policy inventory mismatch, 21 pending status/evidence/rationale assertions, and two inactive mutation controls; the completed guarded suite reports All tests successful at Files=8/Tests=125 in 177 wallclock seconds. Every prior group remains sealed, every unaudited group remains pending, and calibration remains historical/incomplete/blocked. Re-derive: run t1619 through t1622, t1626, t1706, t1763, and t1685 under the repository RAM guard. Falsify: qualification identity, semantic boundary/excess, plan-byte dominance, compact per-scenario/aggregate preflight, diagnostic, pre-materialization, no-tool, cleanup, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, repaired policy, consistency source/test, six focused witnesses, book, Knowledge Map, decision 0093, and work-unit commit retain the result. No cap, level, accepted profile, route outcome, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews execution_fiber_cardinality.`

  Execution Operation Containment Resolution: `The Knowledge Map card had only 37 lines/1,469 bytes of inherited transition headroom after the first operation-cardinality sync. Compacting repeated stage and join prose, without changing answers, evidence, reverify routes, exact numeric claim lines, or the allowance, reduces the aggregate from 46,905 lines/3,463,416 bytes to 46,896 lines/3,462,879 bytes and restores 46 lines/2,006 bytes of headroom. Re-derive: aggregate tracked docs/knowledge Markdown against the declared baseline plus transition growth. Falsify: Knowledge Map and live-document gates reject answer drift, missing evidence, stale shards, or allowance drift. Durability: this task, compacted card, generated map, containment manifest, and work-unit commit retain the resolution.`

  Execution Fiber Cardinality Audit Finding: `The execution_fiber_cardinality candidate inventory is incomplete. It cites t1624's exact 16,384-live-fiber boundary/16,385 excess and t1625's 65,536-total-fiber component admission under later serialized-plan dominance/65,537 structural excess, but omits t1623, the dedicated accepted qualification and exact plan-identity witness for both axes. T1605 is a useful lower-scale topology regression but is superseded here by t1623's qualification-scale identity; t1604 does not exercise a fiber axis. History shows 951720257 introduced the two-path inventory and 4c97d16b0 later changed the enforcement wording without repairing it. The complete five-file candidate/policy/consistency baseline is green at Files=5/Tests=100 in 69 wallclock seconds under the repository RAM guard, so this is evidence-inventory debt rather than a runtime regression. This active .17.4.8 slice owns repairing the exact three-witness policy inventory, adding explicit no-tool and same-volume cleanup proof where the ladder is silent, and only then binding independently classified dimensions. Re-derive: inspect t1623 through t1625, t1604/t1605, policy history, and run t1623-t1625 plus t1763/t1685 under the RAM guard. Falsify: omitting t1623 loses accepted qualification identity and cleanup, while omitting either boundary witness loses one axis's exact component admission, first excess, route diagnostic, or atomic failure. Durability: this task entry owns the defect before source changes; the completed slice must synchronize policy, consistency authority, tests, book, Knowledge Map, and work-unit history.`

  Execution Fiber Cardinality Join: `The repaired policy now cites the complete three-witness set across simultaneously_live_fibers and fibers_total, and the caller-sealed consistency authority promotes execution_fiber_cardinality without confusing component admission with complete route success. T1624/t1625 own exact component-boundary admission, first excess, stable route diagnostics, and atomic no-ExecutionIR/no-plan failure; t1623 owns both accepted qualification plans plus same-volume success/failure cleanup. All three explicitly retain unset backend/tool selectors and deterministic accepted plan or semantic-stage identities. T1625 honestly records that 65,536 total fibers clear the component preflight but meet the later serialized-plan cap, while 65,537 rejects at the fiber authority before bridge indexing. T1605 remains a lower-scale topology regression rather than duplicate closeout evidence, and t1604 exercises no fiber axis. T1763 reconstructs every projection and the exact three-path union, checks each path, and rejects empty or foreign evidence. The intentional RED exposed one policy mismatch, 21 pending status/evidence/rationale assertions, and two inactive mutation controls; the completed guarded suite reports All tests successful at Files=5/Tests=102 in 69 wallclock seconds. Every prior group remains sealed, every unaudited group remains pending, and calibration remains historical/incomplete/blocked. Re-derive: run t1623 through t1625, t1763, and t1685 under the repository RAM guard. Falsify: qualification identity, two-axis boundary/excess, plan-byte dominance, diagnostic, pre-materialization, no-tool, cleanup, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, repaired policy, consistency source/test, three focused witnesses, book, Knowledge Map, decision 0093, and work-unit commit retain the result. No cap, level, accepted profile, route outcome, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews execution_route_collections.`

  Execution Fiber Claim Disposition Finding: `The user-facing fiber explanation produced three actionable candidates: the exact live-fiber boundary, its adjacent excess combined with total-fiber component admission, and the total-fiber adjacent excess. Each is now a derived-gate disposition with non-aliased catalog/generator/contract/builder re-derivation, all three focused fiber oracles as falsifiers, and the repaired policy plus sealed consistency authority as durability watchers. Re-derive: regenerate the producer-derived inventory and join every candidate through the required-complete verification_architecture group. Falsify: removing a disposition, producer, oracle, watcher, or current candidate identity fails closed. Durability: the disposition registry, generated inventory, this task, and work-unit history retain the result at 1,719/1,719 disposed candidates, 947 derived gates, and zero gaps/open owners.`

  Execution Route Collections Audit Finding: `The execution_route_collections candidate inventory is incomplete across its three owned axes. T1607/t1627/t1628 plus t1707-t1709 prove the source-map, execution-type, and binding route boundaries and local defenses, but the executable policy omits t1603's accepted binding-gate plan and t1606's accepted execution-type plan; t1607 already supplies the corresponding accepted source-map route identity. History shows 951720257 introduced only t1607/t1627/t1628, while 2892b36ad, 00c68b1fd, and f8c4808cb appended their local hardeners without revisiting accepted-route completeness. The complete ten-file policy/candidate/consistency baseline is green at Files=10/Tests=139 in 54 wallclock seconds under the repository RAM guard, so this is evidence-inventory debt rather than a runtime regression. This active .17.4.8 slice owns repairing the exact eight-witness policy inventory, strengthening explicit no-tool and same-volume cleanup facts where the accepted ladders are silent, and only then binding independently classified dimensions. Re-derive: inspect t1603/t1606/t1607, t1627/t1628, t1707-t1709, exact policy history, and run all eight witnesses plus t1763/t1685 under the RAM guard. Falsify: omitting either accepted gate loses one owned axis's deterministic complete-plan identity and cleanup, while omitting any existing witness loses a route boundary, adjacent excess, diagnostic, or pre-materialization defense. Durability: this task entry owns the defect before source changes; the completed slice must synchronize policy, consistency authority, tests, book, Knowledge Map, and work-unit history.`

  Execution Route Collections Join: `The repaired policy now cites the complete eight-witness set across bindings, execution_types, and source_map_records, and the caller-sealed consistency authority promotes execution_route_collections without flattening component admission into whole-route reachability. T1603/t1606/t1607 own accepted binding/type/map gate plans plus same-volume success/failure cleanup. T1628 admits 2,054 bindings before the 2,055 route crosses the 2,048-event bridge cap; t1627 admits 1,043 types before 1,044 crosses serialized bridge bytes; t1607 admits 46,294 source maps before 46,295 crosses serialized plan bytes. T1707/t1708 independently admit exact type-table/source-map component limits and reject first excess before cloning/insertion; t1709 rejects compactly known binding excess before binding construction. The accepted gate and layered route constructions explicitly select no backend or tool. T1763 reconstructs every projection and the exact eight-path union, checks each path, and rejects omitted or foreign evidence. The intentional RED exposed one policy mismatch, 21 pending status/evidence/rationale assertions, and two inactive mutation controls. The completed default guarded suite reports Files=10/Tests=140 in 55 wallclock seconds; the exact three-route boundary suite reports Files=3/Tests=21 in 77 wallclock seconds. Every prior group remains sealed, every unaudited group remains pending, and calibration remains historical/incomplete/blocked. Re-derive: run t1603/t1606/t1607/t1627/t1628/t1707-t1709 plus t1763/t1685 under the RAM guard, with FSMGEN_VIAL_SCALE_EXACT=1 for the three route-boundary witnesses. Falsify: accepted identity, three different earlier route authorities, local exact-boundary/excess, diagnostic, pre-materialization, no-tool, cleanup, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, repaired policy, consistency source/test, eight focused witnesses, book, Knowledge Map, decision 0093, and work-unit commit retain the result. No cap, route boundary, level, accepted identity, route outcome, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews execution_random_attempts.`

  Execution Route Collections Claim Disposition Finding: `The user-facing three-route explanation produced three actionable candidates: the binding/event route boundary, the execution-type/serialized-bridge boundary, and the source-map/serialized-plan boundary. Each is now a derived-gate disposition with non-aliased contract/generator/bridge/builder re-derivation, all eight route witnesses as falsifiers, and the repaired policy plus sealed consistency authority as durability watchers. Re-derive: regenerate the producer-derived inventory and join every candidate through the required-complete verification_architecture group. Falsify: removing a disposition, producer, oracle, watcher, or current candidate identity fails closed. Durability: the disposition registry, generated inventory, this task, and work-unit history retain the result at 1,722/1,722 disposed candidates, 950 derived gates, and zero gaps/open owners.`

  Execution Random Attempts Audit Finding: `The execution_random_attempts candidate inventory is complete as written. T1614 owns exact acceptance at 1,000,000 attempts with generated/replayed plan identities and closed evaluation metrics; t1615 owns deterministic rejection at 1,000,001 attempts with the exact random diagnostic and no partial ExecutionIR or plan; t1710 independently pins that rejection inside random projection before serialized-plan preflight or any final materializer. T1613's 262,144-attempt qualification is a useful lower-scale regression but is strictly superseded for closeout by t1614's stronger boundary, replay, plan, and evaluation proof, so adding it would inflate the authority without adding a dimension. History shows 951720257 introduced the exact t1614/t1615 pair and c319142a5 appended the distinct terminal-seam witness. The complete six-file policy/candidate/consistency baseline is green at Files=6/Tests=104 in 480 wallclock seconds under the repository RAM guard. The intentional RED leaves the exact policy assertion green while exposing 21 pending status/evidence/rationale assertions and two inactive omission/foreign-evidence controls. This active .17.4.8 slice therefore owns retaining the exact three-witness policy inventory, adding explicit no-tool and same-volume success/failure cleanup proof, and binding only independently classified dimensions. Re-derive: inspect t1613-t1615, t1710, exact policy history, and run the three cited witnesses plus t1685/t1763 under the RAM guard. Falsify: removing t1614 loses exact accepted boundary and identity, removing t1615 loses the public adjacent excess and diagnostic, removing t1710 loses terminal order and forbidden-materializer proof, while adding t1613 changes no seven-dimension projection. Durability: this task entry owns the audit and RED before authority changes; the completed slice must synchronize consistency authority, tests, book, Knowledge Map, and work-unit history.`

  Execution Random Attempts Join: `The exact three-witness policy inventory is retained unchanged and the caller-sealed consistency authority now promotes execution_random_attempts across all seven dimensions. T1614 owns the 1,000,000-attempt accepted boundary at zero-based attempt 999,999, exact construction/decision/generated-plan/replayed-plan/evaluation identities, absent backend/tool selectors, and same-volume success/failure cleanup. T1615 owns the deterministic 1,000,001-attempt public excess, exact random diagnostic, absent selectors, and no partial ExecutionIR, plan, or metrics. T1710 independently pins the same exhaustion inside random projection before serialized-plan preflight and every final materializer. T1613 remains a useful lower-scale regression but adds no closeout dimension beyond t1614. T1763 reconstructs every projection and the exact three-path union, checks each path, and rejects omitted or foreign evidence. The policy/consistency pair passes Files=2/Tests=83; the complete guarded join passes Files=5/Tests=101 in 423 wallclock seconds. Every prior group remains sealed, every unaudited group remains pending, and calibration remains historical/incomplete/blocked. Re-derive: run t1614/t1615/t1710 plus t1763/t1685 under the repository RAM guard. Falsify: exact boundary, adjacent exhaustion, diagnostic, projection/materialization order, no-tool, cleanup, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, unchanged exact policy inventory, consistency source/test, three focused witnesses, book, Knowledge Map, decision 0093, and work-unit commit retain the result. No cap, boundary, level, accepted identity, route outcome, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews execution_serialized_plan.`

  Execution Random Attempts Claim Disposition Finding: `The user-facing random-attempt explanation produced three actionable candidates: the exact 1,000,000-attempt boundary, its 1,000,001-attempt adjacent excess, and the lower 262,144-attempt qualification that is deliberately superseded for closeout. Each is now a derived-gate disposition with non-aliased contract/generator/random-authority/workload/builder re-derivation, all three focused random-attempt oracles as falsifiers, and the exact policy plus sealed consistency authority as durability watchers. Re-derive: regenerate the producer-derived inventory and join every candidate through the required-complete verification_architecture group. Falsify: removing a disposition, producer, oracle, watcher, or current candidate identity fails closed. Durability: the disposition registry, generated inventory, this task, and work-unit history retain the result at 1,725/1,725 disposed candidates, 953 derived gates, and zero gaps/open owners.`

  Execution Serialized Plan Audit Finding: `The execution_serialized_plan candidate inventory is incomplete. T1612 owns the first complete valid plan excess and public diagnostic, while t1634 independently pins plan rejection before random-decision, ExecutionIR, or report materialization and supplies lower-route replay/cleanup evidence; the policy omits t1611, the exact accepted 16,777,216-byte plan, content-derived identity, and closed evaluation witness. T1609's one-MiB gate and t1610's four-MiB qualification are useful lower-scale regressions but are strictly superseded for closeout by t1611's structurally equivalent exact-cap proof. History shows 951720257 introduced t1612 alone and 5b3860fc0 appended t1634's distinct seam defense without restoring the accepted boundary. The complete five-file policy/candidate/consistency baseline is green at Files=5/Tests=96 in 172 wallclock seconds under the repository RAM guard, proving evidence-inventory debt rather than a runtime regression. The intentional RED exposes one exact policy mismatch, 21 pending status/evidence/rationale assertions, and two inactive omission/foreign-evidence controls. This active .17.4.8 slice owns repairing the exact three-witness policy inventory, adding explicit no-tool and exact-boundary same-volume success/failure cleanup proof, and only then binding independently classified dimensions. Re-derive: inspect t1609-t1612, t1634, exact policy history, and run t1611/t1612/t1634 plus t1685/t1763 under the RAM guard. Falsify: omitting t1611 loses exact accepted boundary, identity, and cleanup; omitting t1612 loses first complete excess and the public diagnostic; omitting t1634 loses independent pre-materialization order, replay-route, and cleanup evidence; adding t1609/t1610 changes no seven-dimension projection. Durability: this task entry owns the defect and RED before authority changes; the completed slice must synchronize policy, consistency authority, tests, book, Knowledge Map, and work-unit history.`

  Execution Serialized Plan Join: `The repaired policy now cites the exact t1611/t1612/t1634 witness set, and the caller-sealed consistency authority promotes execution_serialized_plan across all seven dimensions. T1611 owns exact 16,777,216-byte canonical admission, content-derived plan and evaluation identities, absent backend/tool selectors, and same-volume success/failure cleanup. T1612 owns the first complete valid excess, public plan-root diagnostic, absent selectors, and atomic no-ExecutionIR/no-plan rejection. T1634 independently pins the same plan authority before random-decision, ExecutionIR, plan, or report materialization while preserving its accepted replay route and cleanup. T1609/t1610 remain useful one-/four-MiB regressions but add no closeout dimension beyond t1611. T1763 reconstructs every projection and the exact three-path union, checks each path, and rejects omitted or foreign evidence. The completed default guarded join passes Files=5/Tests=97 in 170 wallclock seconds; independent exact replay qualification passes Files=3/Tests=88 in 372 seconds; and the lower-rung disposition witnesses pass Files=2/Tests=8 in 18 seconds. Re-derive: run t1611/t1612/t1634 plus t1763/t1685 under the repository RAM guard, setting FSMGEN_VIAL_SCALE_EXACT=1 for the replay qualification. Falsify: exact boundary, first complete excess, diagnostic, projection/materialization order, no-tool, cleanup, identity, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, repaired policy, consistency source/test, three primary and two superseded witnesses, book, Knowledge Map, decision 0093, and work-unit commit retain the result. No cap, boundary, level, accepted identity, route outcome, product behavior, publication, support, budget, or capacity claim changes.`

  Execution Serialized Plan Claim Disposition Finding: `The user-facing serialized-plan explanation produced two actionable candidates: the exact 16,777,216-byte canonical boundary and the one-/four-MiB lower ladders deliberately superseded for closeout. Each is now a derived-gate disposition with non-aliased contract/generator/workload/builder re-derivation, the boundary/excess/materialization and lower-rung witnesses as falsifiers, and the repaired policy plus sealed consistency authority as durability watchers. Re-derive: regenerate the producer-derived inventory and join every candidate through the required-complete verification_architecture group. Falsify: removing a disposition, producer, oracle, watcher, or current candidate identity fails closed. Durability: the disposition registry, generated inventory, this task, and work-unit history retain the result at 1,727/1,727 disposed candidates, 955 derived gates, and zero gaps/open owners.`

  Execution Serialized Plan Containment Finding: `The synchronized Knowledge Card initially remained legal by only 22 lines/165 bytes under its inherited transition allowance, too little continuity margin for the remaining group joins. Its redundant one-test-per-line evidence copy is now replaced by canonical policy, consistency, parser, semantic, bridge, execution, backend, runtime, task, and book authorities while the executable ranged reverify inventory retains the exact test routes. The aggregate is now 46,870 lines/3,461,231 bytes, restoring 72 lines/3,654 bytes of transition headroom without raising an allowance or dropping a fact, question, route, or runnable check. Re-derive: aggregate docs/knowledge Markdown and expand the reverify patterns. Falsify: Knowledge Map, relative-path, history, and live-document checks reject lost answers, stale generation, bad canonical paths, or ceiling drift. Durability: this task, compacted card, generated shards, containment manifest, and work-unit history retain the resolution.`

  Semantic Parser Admission Audit Finding: `The semantic_parser_admission candidate inventory is complete as written. T1601 owns the closed 14-axis/five-level semantic workload inventory, deterministic construction, accepted gate identities, and same-volume success/failure cleanup; t1687 independently admits exactly 64 direct imports and rejects 65 before recursive parsing; t1693 independently admits the 1,048,576-byte per-source and 16,777,216-byte combined-source boundaries and rejects their first byte excesses before lexing. The latter two witnesses own stable public diagnostics and no-partial-semantic-report atomicity. T1601 constructs every selected level but currently does not explicitly assert the already-null backend/tool selectors, and no caller-sealed consistency projection promotes the group. History shows t1601 was introduced by 145d3084a, the two focused order witnesses by a622325c7 and 273678c6b, and the later 951720257 policy deliberately cited all three; no evidence path is missing or redundant. The complete five-file policy/candidate/consistency baseline is green at Files=5/Tests=105 in 20 wallclock seconds under the repository RAM guard. The intentional RED keeps the exact policy assertion green while exposing 21 pending status/evidence/rationale assertions and two inactive omission/foreign-evidence controls. The active .17.4.8 slice owns retaining the exact three-witness policy inventory, adding explicit no-tool proof to the closed construction matrix, and binding only independently classified dimensions. Re-derive: inspect t1601/t1687/t1693, their exact history, and run them plus t1685/t1763 under the RAM guard. Falsify: removing t1601 loses closed generator coverage, cleanup, and gate identity; removing t1687 loses import boundary/excess and pre-recursion order; removing t1693 loses both byte boundaries/excesses and pre-lex order. Durability: this task entry owns the audit and RED before authority changes; the completed slice must synchronize consistency authority, tests, book, Knowledge Map, and work-unit history.`

  Semantic Parser Admission Join: `The exact three-witness policy inventory is retained unchanged and the caller-sealed consistency authority now promotes semantic_parser_admission across all seven dimensions. T1601 owns the closed 14-axis/five-level construction matrix, explicitly absent backend/tool selectors, accepted gate identities, and same-volume success/failure cleanup. T1687 owns exact 64-import admission, the 65-import first excess, stable public diagnostic, and rejection before recursive parsing without a semantic report. T1693 owns both exact byte boundaries and their first byte excesses, stable public diagnostics, and rejection before lexing without a semantic report. T1763 reconstructs every projection and the exact three-path union, checks each path, and rejects empty or foreign evidence. The policy/consistency pair passes Files=2/Tests=83; the complete guarded join reports All tests successful at Files=5/Tests=105 in 20 wallclock seconds. Re-derive: run t1601/t1687/t1693 plus t1763/t1685 under the repository RAM guard. Falsify: closed generator/no-tool, three exact boundaries/excesses, pre-recursion/pre-lex order, diagnostic, atomicity, cleanup, identity, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, unchanged exact policy inventory, consistency source/test, three focused witnesses, book, Knowledge Map, decision 0093, and work-unit commit retain the result. No cap, boundary, level, accepted identity, route outcome, product behavior, publication, support, budget, or capacity claim changes.`

  Semantic Parser Admission Claim Disposition Finding: `The user-facing parser explanation produced three actionable candidates: accepted direct-import admission, its first excess/pre-recursion order, and the two exact source-byte boundaries/pre-lex order. Each is now a derived-gate disposition with non-aliased catalog/generator/parser re-derivation, the closed catalog and focused import/byte oracles as falsifiers, and the exact policy plus sealed consistency authority as durability watchers. Re-derive: regenerate the producer-derived inventory and join every candidate through the required-complete verification_architecture group. Falsify: removing a disposition, producer, oracle, watcher, or current candidate identity fails closed. Durability: the disposition registry, generated inventory, this task, and work-unit history retain the result at 1,730/1,730 disposed candidates, 958 derived gates, and zero gaps/open owners.`

  Frontier: `All twenty-three groups are independently verified. Explicitly revalidate and disposition the immutable historical calibration publication without relabelling it as cap implementation.`

  Semantic Declaration Cardinality Audit Finding: `The semantic_declaration_cardinality candidate inventory is complete as written and deliberately asymmetric. T1601 is the only closed exact-matrix owner for the distinct 1,024/1,025 fixture axis, and also retains every declaration/fixture construction, no-tool shape, accepted semantic identity, diagnostic oracle, and same-volume success/failure cleanup. T1689 independently admits 4,096 declarations, rejects 4,097 in the types section with the stable public diagnostic, and proves that known excess precedes malformed later-section parsing without a semantic report. T1601's rejection evaluation already emits no semantic projection/report identity or format identities, but the regression only checks its status and diagnostic family; explicit atomicity assertions are therefore still missing for the fixture route. History shows t1601 was introduced by 145d3084a, t1689 by e9679effb, and the earlier 951720257 policy selected their exact complementary pair; adding a third path would invent evidence rather than close a dimension. The complete opt-in exact policy/candidate/consistency baseline is green at Files=4/Tests=102 in 93 wallclock seconds under the repository RAM guard. Before authority promotion, the intentional RED kept the exact policy assertion green and made t1763 fail on all twenty-one pending status/evidence/rationale assertions plus both inactive omission/foreign-evidence controls at Files=2/Tests=84; the remaining union and path checks passed. This active .17.4.8 slice owns retaining the exact two-witness policy inventory, making rejection atomicity explicit in the closed matrix, and binding only independently classified dimensions. Re-derive: run t1601/t1689 plus t1685/t1763 with FSMGEN_VIAL_SCALE_EXACT=1 under the RAM guard and inspect their exact history. Falsify: removing t1601 loses the fixture axis, closed matrix, no-tool, cleanup, and broad identities; removing t1689 loses the independent declaration boundary/excess and later-section order proof. Durability: this task entry owns the audit and exact RED before source changes; the completed slice must synchronize consistency authority, tests, book, Knowledge Map, and work-unit history.`

  Semantic Declaration Cardinality Join: `The exact two-witness policy inventory is now asserted and the consistency authority seals semantic_declaration_cardinality across all seven dimensions. T1601 explicitly proves that every expected rejection emits no semantic projection, semantic report, or format identity; t1689 retains the independent declaration-order proof. T1763 reconstructs the exact t1601/t1689 union, checks both paths, and rejects omitted or foreign evidence. The focused authority gate is green at Files=2/Tests=84, and the exact four-file RAM-guarded join is green at Files=4/Tests=103 in 97 wallclock seconds. Re-derive: run the exact guarded four-file command documented in the book. Falsify: the recorded RED proves all twenty-one dimension records and both mutation controls fail before promotion. Durability: source authority, regressions, this task, the bounded resume pointer, book, Knowledge Map, and the work-unit commit retain the join without changing any cap, accepted outcome, product behavior, support statement, budget, or capacity claim.`

  Semantic Action Cardinality Audit Finding: `The semantic_action_cardinality policy candidate inventory is complete as the complementary t1601/t1686 pair, but their roles are intentionally asymmetric. T1601 alone owns exact 65,536-action admission, the generated 65,537 first excess, closed no-tool construction, same-volume success/failure cleanup, deterministic accepted identities, stable diagnostic oracle, and absence of partial identities on rejection. T1686 independently proves three reservation-order excesses: repeat multiplication, the action after a full boundary, and malformed action syntax after a full boundary all return the stable scenario-root limit before further semantic construction and without a semantic report. T1686 does not independently return an accepted boundary or accepted identity and must not be classified as either. History ties the hardened reservation and focused witness to 6ad4a9292 and the original two-file policy selection to 951720257; a third witness would duplicate rather than complete the group. The exact policy/candidate/consistency baseline is green at Files=4/Tests=109 in 83 wallclock seconds under the repository RAM guard. Re-derive: run t1601/t1686 plus t1685/t1763 with FSMGEN_VIAL_SCALE_EXACT=1 under the RAM guard and inspect git log -S history. Falsify: removing t1601 loses boundary, generated excess, no-tool, cleanup, and identity proof; removing t1686 loses the independent early-reservation and malformed-sibling precedence controls. Durability: this task entry owns the audit before source changes; the completed slice must synchronize consistency authority, regressions, book, Knowledge Map, claims, and work-unit history.`
  Intentional RED: `The exact policy inventory assertion passes while the
  unpromoted consistency authority produces only the expected 21
  status/evidence/rationale failures plus the boundary-omission and foreign
  accepted-identity mutation-control failures at Files=2, Tests=85. This
  isolates the missing semantic-action join before source promotion.`

  Semantic Action Cardinality Join: `The exact two-witness policy inventory is
  now asserted and the consistency authority seals semantic_action_cardinality
  across all seven dimensions without flattening their roles. T1601 alone owns
  exact 65,536-action admission, the generated 65,537 excess, no-tool shape,
  same-volume cleanup, deterministic accepted identities, stable diagnostics,
  and absence of partial semantic or format identities on rejection. T1686
  independently proves three early-reservation excesses before further semantic
  construction and without a semantic report, but is not accepted-boundary,
  no-tool, cleanup, or accepted-identity evidence. T1763 reconstructs the exact
  t1601/t1686 union, checks both paths, and rejects omitted or foreign evidence.
  The focused authority gate is green at Files=2, Tests=85, and the exact
  four-file RAM-guarded join reports All tests successful at Files=4, Tests=110
  in 81 wallclock seconds. Re-derive: run the exact guarded four-file command
  documented in the book. Falsify: the recorded RED proves all twenty-one
  dimension records and both mutation controls fail before promotion.
  Durability: source authority, regressions, this task, the bounded resume
  pointer, book, Knowledge Map, and the work-unit commit retain the join without
  changing any cap, accepted outcome, product behavior, support statement,
  budget, or capacity claim.`

  Semantic Action Cardinality Claim Disposition Finding: `The user-facing
  explanation produces one actionable paired candidate for exact 65,536-action
  admission and its 65,537-action adjacent excess. It is a derived-gate
  disposition with non-aliased catalog/generator/parser/SemanticBuilder
  re-derivation, the closed exact matrix plus independent reservation-order
  oracle as falsifiers, and the exact policy plus caller-sealed consistency
  authority as durability watchers. Re-derive: regenerate the producer-derived
  inventory and join every candidate through the required-complete
  verification_architecture group. Falsify: removing the disposition, producer,
  either oracle, watcher, or current candidate identity fails closed.
  Durability: the disposition registry, generated inventory, this task, and
  work-unit history retain the result at 1,733/1,733 disposed candidates, 961
  derived gates, and zero gaps/open owners.`

  Semantic Action Shape Audit Finding: `The semantic_action_shape policy
  candidate inventory is complete as the deliberately asymmetric t1601/t1688
  pair. T1601 is the sole closed exact-matrix owner for both 16/17 parallel
  depth and 256/257 fibers per parallel, and also owns no-tool construction,
  same-volume success/failure cleanup, deterministic accepted identities,
  stable rejection diagnostics, and absence of partial semantic or format
  identities. T1688 independently covers only the fiber axis: it admits 256,
  rejects 257 with one stable action-path diagnostic, proves the excess wins
  before invalid join-value resolution without a semantic report, and freezes
  accepted projection/report identities. T1688 is therefore direct fiber
  boundary, excess, diagnostic, atomicity, and accepted-identity evidence, but
  not depth, no-tool, or cleanup evidence. A new depth-only witness would
  duplicate t1601 rather than complete a missing dimension. History ties the
  exact matrix to 145d3084a, the original t1601-only policy selection to
  951720257, and the fiber-order repair plus focused witness to 01ddb7be5. The
  exact policy/candidate/consistency baseline reports All tests successful at
  Files=4, Tests=104 in 88 wallclock seconds under the repository RAM guard.
  Re-derive: run t1601/t1688 plus t1685/t1763 with
  FSMGEN_VIAL_SCALE_EXACT=1 under the RAM guard and inspect exact history.
  Falsify: removing t1601 loses the depth axis plus no-tool and cleanup proof;
  removing t1688 loses the independent fiber-order and fixed accepted-identity
  controls. Durability: this task entry owns the audit before source changes;
  the completed slice must synchronize consistency authority, regressions,
  book, Knowledge Map, claims, containment, and work-unit history.`

  Semantic Action Shape Intentional RED: `The exact policy inventory assertion
  passes while the unpromoted consistency authority produces only the expected
  twenty-one status/evidence/rationale failures plus the boundary-omission and
  foreign accepted-identity mutation-control failures at Files=2, Tests=86.
  Exact union and path-existence controls already pass, isolating the missing
  sealed semantic-action-shape join before source promotion.`

  Semantic Action Shape Join: `The exact two-witness policy inventory is now
  asserted and the consistency authority seals semantic_action_shape across all
  seven dimensions without flattening its two axes or witness roles. T1601
  alone owns exact 16/17 parallel depth, exact 256/257 fibers per parallel,
  no-tool shape, same-volume cleanup, deterministic accepted identities, stable
  diagnostics, and absence of partial semantic or format identities on
  rejection. T1688 independently owns the fiber boundary/excess, pre-join
  order, no-semantic-report atomicity, and fixed projection/report identities,
  but is not depth, no-tool, or cleanup evidence. T1763 reconstructs the exact
  t1601/t1688 union, checks both paths, and rejects omitted or foreign evidence.
  The focused authority gate is green at Files=2, Tests=86, and the exact
  four-file RAM-guarded join reports All tests successful at Files=4, Tests=105
  in 85 wallclock seconds. Re-derive: run the exact guarded four-file command
  documented in the book. Falsify: the recorded RED proves all twenty-one
  dimension records and both mutation controls fail before promotion.
  Durability: source authority, regressions, this task, the bounded resume
  pointer, book, Knowledge Map, and the work-unit commit retain the join without
  changing any cap, accepted outcome, product behavior, support statement,
  budget, or capacity claim.`

  Semantic Action Shape Claim Disposition Finding: `The user-facing explanation
  produces one actionable paired candidate for the exact parallel-depth and
  fiber-count boundaries and their first excesses. It is a derived-gate
  disposition with non-aliased catalog/generator/parser/SemanticBuilder
  re-derivation, the closed exact matrix plus independent fiber-order oracle as
  falsifiers, and the exact policy plus caller-sealed consistency authority as
  durability watchers. Re-derive: regenerate the producer-derived inventory and
  join every candidate through the required-complete verification_architecture
  group. Falsify: removing the disposition, producer, either oracle, watcher, or
  current candidate identity fails closed. Durability: the disposition
  registry, generated inventory, this task, and work-unit history retain the
  result at 1,734/1,734 disposed candidates, 962 derived gates, and zero
  gaps/open owners.`

  Semantic Repeat Layering Audit Finding: `The semantic_repeat_layering policy
  correctly retains two distinct enforcement layers, but its current
  executable evidence does not yet freeze the accepted effective boundary.
  T1601 proves the 4,096 gate is accepted with deterministic identities,
  262,144 and 1,000,000 are rejected by the earlier 65,536-expanded-action
  ceiling, and 1,000,001 rejects directly at the intrinsic repeat-count path;
  it also owns closed no-tool construction, rejection atomicity, and
  same-volume success/failure cleanup. T1686 proves repeat multiplication and
  later-action reservation order, but every current assertion is a rejection.
  A read-only construction probe through the same catalog and parser proves
  count 65,535 is accepted with exactly 65,536 expanded actions, count 65,536
  is the first effective excess, count 1,000,000 remains action-dominated, and
  count 1,000,001 reaches the intrinsic count diagnostic. Decision 0059
  already records why the nominal intrinsic ceiling cannot be accepted by any
  legal non-empty repeat body. Exact `git log -S'semantic_repeat_layering' --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` history locates policy selection
  at 951720257, while 145d3084a introduced the catalog/decision and 6ad4a9292
  hardened overflow-safe reservation. The exact four-file guarded baseline is
  green at Files=4, Tests=111 in 82 wallclock seconds. This active .17.4.8
  slice owns extending t1686 with the missing accepted 65,535 boundary and
  deterministic identity witness before any consistency promotion. Re-derive:
  run the four fixed counts through the generated catalog source and public
  parser, then run t1601/t1686/t1685/t1763 with exact scale enabled under the
  repository RAM guard. Falsify: removing the new accepted-boundary assertion
  leaves boundary/identity unproved; removing t1601 loses the intrinsic layer,
  closed matrix, no-tool, cleanup, and rejection identities; removing t1686
  loses effective-boundary ordering. Durability: this task entry owns the gap
  before test or consistency changes; the completed slice must synchronize the
  decision-backed policy, regressions, consistency authority, book, Knowledge
  Map, claims, containment, and work-unit history.`

  Semantic Repeat Layering Witness and Intentional RED: `T1686 now passes all
  29 assertions, including the generated accepted 65,535-count boundary,
  exact 65,536 expanded-action metric, absent backend/tool selectors, and fixed
  semantic projection/report identities. Before consistency source promotion,
  the exact policy evidence assertion passes while t1763 fails only the
  expected twenty-one pending status/evidence/rationale assertions plus the
  inactive boundary-omission and foreign-identity mutation controls at
  Files=2, Tests=87. Its exact t1601/t1686/decision-0059 union and path-existence
  controls already pass. This isolates the unpromoted seven-dimension join
  after closing the accepted-boundary evidence gap.`

  Semantic Repeat Cross-Group Evidence Finding: `The new accepted repeat
  boundary also changes t1686's current direct evidence role for the already
  sealed semantic_action_cardinality group. Before this slice t1686 contained
  only rejection-order controls, so excluding it from boundary, no-tool, and
  accepted-identity dimensions was exact. Its new assertions now admit exactly
  65,536 expanded actions through a repeat route, assert absent backend/tool
  selectors, and freeze both semantic identities. Leaving the earlier
  classification unchanged would make the consistency authority stale even
  though product behavior did not change. This slice therefore owns adding
  only those three newly proved t1686 roles to semantic_action_cardinality,
  retaining t1601's exact generated action-axis boundary/excess and cleanup,
  and synchronizing the book/Knowledge Map explanation.`

  Semantic Repeat Layering Join: `The exact three-path policy inventory now
  seals semantic_repeat_layering across all seven dimensions without treating
  the intrinsic repeat ceiling as an accepted route promise. T1686 admits
  count 65,535 at exactly 65,536 expanded actions with absent backend/tool
  selectors and fixed semantic projection/report identities, then proves count
  65,536 and later malformed actions retain the scenario-root action limit.
  T1601 retains the accepted catalog gate, action-dominated qualification and
  nominal intrinsic-boundary routes, direct 1,000,001 intrinsic excess,
  rejection atomicity, closed no-tool matrix, same-volume cleanup, and
  identities. Decision 0059 directly owns the selected explanation for why a
  legal non-empty body cannot admit the nominal repeat ceiling. T1686's new
  direct proof is also joined to boundary, no-tool, and accepted-identity for
  semantic_action_cardinality; t1601 remains that group's exact generated-axis
  and cleanup owner. T1763 reconstructs both exact projections and their full
  candidate unions, verifies every path, and rejects omission or foreign
  evidence. The focused authority gate passes Files=3, Tests=116; the final
  four-file exact RAM-guarded join reports All tests successful at Files=4,
  Tests=120 in 83 wallclock seconds. Re-derive: run the exact guarded command
  documented in the book. Falsify: the recorded RED proves all twenty-one
  repeat-dimension records and both mutation controls fail before promotion,
  while the accepted-boundary witness fails if either count or identity moves.
  Durability: source authority, policy, decision, regressions, this task, book,
  Knowledge Map, claims, containment, and work-unit history retain the two
  layers without changing either cap or product behavior.`

  Semantic Repeat Layering Claim Disposition Finding: `The user-facing two-
  layer explanation produces one actionable candidate covering the accepted
  effective boundary, its first action-layer excess, and the direct intrinsic
  excess. It is a derived-gate disposition with non-aliased catalog/workload/
  parser/SemanticBuilder re-derivation, t1601/t1686 falsifiers, and the exact
  policy/decision/caller-sealed consistency authority as durability watchers.
  Re-derive: regenerate the producer-derived inventory and join every candidate
  through the required-complete verification_architecture group. Falsify:
  removing the disposition, producer, either oracle, watcher, or current
  candidate identity fails closed. Durability: the disposition registry,
  generated inventory, this task, and work-unit history retain the result at
  1,735/1,735 disposed candidates, 963 derived gates, and zero gaps/open
  owners.`

  Semantic Service Scalar Audit Finding: `The semantic_service_scalar policy
  candidate inventory is complete as the deliberately asymmetric
  t1601/t1690/t1691 set. T1601 owns both exact 1,000,000 scalar admissions,
  both 1,000,001 adjacent excesses, the closed no-backend/no-tool construction
  matrix, absence of partial semantic and format identities on rejection,
  deterministic accepted construction identities, and shared same-volume
  success/failure cleanup. T1690 independently freezes the scoreboard-capacity
  code, phase, message, path, pre-transaction-resolution order, no-report
  atomicity, and fixed accepted projection/report identities; t1691 provides
  the equivalent independent cross-max_bins proof before coverpoint resolution.
  History identifies 145d3084a as the catalog introduction, 543a1baed as both
  focused service-scalar witnesses and admission repair, and 951720257 as the
  exact three-path policy selection. The exact guarded pre-change authority is
  green at Files=5, Tests=121 in 91 wallclock seconds. Re-derive: run t1601,
  t1690, t1691, t1685, and t1763 with FSMGEN_VIAL_SCALE_EXACT=1 under the
  repository RAM guard and inspect their exact history. Falsify: removing
  t1601 loses the closed two-axis matrix, no-tool proof, shared cleanup, and
  broad atomic identities; removing t1690 loses exact scoreboard diagnostic,
  order, and fixed-boundary identity; removing t1691 loses the corresponding
  cross-max_bins authority. Durability: this task entry owns the audit before
  policy-test or consistency-source changes; the completed slice must
  synchronize consistency authority, regressions, book, Knowledge Map, claims,
  containment, and work-unit history.`

  Semantic Service Scalar Intentional RED: `The exact three-path policy
  inventory assertion, reconstructed union, and evidence-path checks pass.
  Before consistency-source promotion, t1763 fails only the expected twenty-one
  pending status/evidence/rationale assertions plus the inactive boundary-
  omission and foreign-accepted-identity mutation controls at Files=2,
  Tests=88. This isolates the unpromoted seven-dimension service-scalar join
  without changing a witness, policy path, cap, or product behavior.`

  Semantic Service Scalar Join: `The exact t1601/t1690/t1691 policy inventory
  now seals semantic_service_scalar across all seven dimensions without
  flattening witness roles. T1601 owns both exact 1,000,000/1,000,001 scalar
  pairs, the closed no-backend/no-tool matrix, rejection identity atomicity,
  broad accepted identities, and shared same-volume success/failure cleanup.
  T1690 independently freezes the scoreboard-capacity diagnostic, admission
  before transaction resolution, no-report failure, and fixed accepted
  projection/report identities; t1691 owns the equivalent cross-max_bins proof
  before coverpoint resolution. Neither focused witness is promoted as cleanup
  or closed no-tool evidence. T1763 reconstructs every projection and the exact
  three-path union, checks every path, and rejects omitted or foreign evidence.
  The focused authority gate passes Files=2, Tests=88; the final five-file exact
  RAM-guarded join reports All tests successful at Files=5, Tests=122 in 91
  wallclock seconds. Re-derive: run the exact guarded command documented in the
  book. Falsify: the recorded RED proves all twenty-one dimension records and
  both mutation controls fail before promotion. Durability: source authority,
  policy, regressions, this task, book, Knowledge Map, claims, containment, and
  work-unit history retain the result without changing a cap or product
  behavior.`

  Semantic Service Scalar Claim Disposition Finding: `The user-facing two-axis
  boundary/excess explanation produces one actionable candidate. It is now a
  derived-gate disposition with non-aliased catalog/workload/parser/
  SemanticBuilder re-derivation, t1601/t1690/t1691 falsifiers, and the exact
  policy/caller-sealed consistency authority as durability watchers. Re-derive:
  regenerate the producer-derived inventory and join every candidate through
  the required-complete verification_architecture group. Falsify: removing the
  disposition, any producer, catalog or focused oracle, watcher, or current
  candidate identity fails closed. Durability: the disposition registry,
  generated inventory, this task, and work-unit history retain the result at
  1,736/1,736 disposed candidates, 964 derived gates, and zero gaps/open
  owners.`

  Semantic Type Shape Audit Finding: `The semantic_type_shape policy candidate
  inventory is complete as the deliberately asymmetric t1601/t1692 pair.
  T1601 owns exact 65,536/65,537 list-length, 256/257 record-field, and 32/33
  aggregate-depth pairs; the closed no-backend/no-tool construction matrix;
  absence of partial semantic and format identities on every rejection;
  deterministic accepted construction identities; and shared same-volume
  success/failure cleanup. T1692 independently freezes each axis's code, phase,
  message, semantic path, admission before invalid inner-type resolution,
  no-report atomicity, and fixed accepted projection/report identities.
  History identifies 145d3084a as the catalog introduction, 52ddb9cf3 as the
  focused three-axis preflight witness, and 951720257 as the exact two-path
  policy selection. The exact guarded pre-change authority is green at Files=4,
  Tests=95 in 94 wallclock seconds. Re-derive: run t1601, t1692, t1685, and
  t1763 with FSMGEN_VIAL_SCALE_EXACT=1 under the repository RAM guard and
  inspect their exact history. Falsify: removing t1601 loses the complete
  three-axis matrix, closed no-tool proof, shared cleanup, and broad atomic
  identities; removing t1692 loses independent per-axis diagnostics,
  pre-inner-resolution order, and fixed-boundary identities. Durability: this
  task entry owns the audit before policy-test or consistency-source changes;
  the completed slice must synchronize consistency authority, regressions,
  book, Knowledge Map, claims, containment, and work-unit history.`

  Semantic Type Shape Intentional RED: `The exact two-path policy inventory
  assertion, reconstructed union, and evidence-path checks pass. Before
  consistency-source promotion, t1763 fails only the expected twenty-one
  pending status/evidence/rationale assertions plus the inactive boundary-
  omission and foreign-accepted-identity mutation controls at Files=2,
  Tests=89. This isolates the unpromoted seven-dimension type-shape join
  without changing a witness, policy path, cap, or product behavior.`

  Calibration Eligibility Transition Finding: `Promoting the twenty-third and
  final policy group makes the consistency report derive
  cap_proof_status=complete and disposition=eligible_for_explicit_revalidation
  from its original all_group_dimensions_verified unlock condition. The first
  post-promotion focused run correctly exposed three stale test expectations
  that still asserted the earlier incomplete/blocked state; every group and
  evidence assertion was already green. Exact `git log -S` history identifies
  caf26e17b as the commit that deliberately introduced this conditional
  transition. Eligibility is not revalidation and cannot relabel the immutable
  publication: evidence_role remains historical_measurement_only and
  prohibited_relabel remains cap_implementation. This slice owns updating only
  the derived calibration-state expectations and documenting the newly
  unlocked, still-explicit revalidation frontier before any publication
  disposition is attempted.`

  Semantic Type Shape Join: `The exact asymmetric t1601/t1692 policy inventory
  is asserted and the caller-sealed consistency authority now promotes
  semantic_type_shape across all seven dimensions. T1601 owns the exact
  65,536/65,537 list-length, 256/257 record-field, and 32/33 aggregate-depth
  pairs plus closed no-tool construction, atomic rejection, shared cleanup,
  and broad accepted identities. T1692 independently owns all three stable
  diagnostics, pre-inner-resolution order, no-report rejection, and fixed
  accepted projection/report identities; it is not promoted as shared cleanup
  or closed no-tool evidence. T1763 reconstructs the exact two-path union,
  checks both paths, and rejects omitted or foreign evidence. The focused
  policy/consistency gate passes Files=2, Tests=89. The complete exact guarded
  authority passes Files=4, Tests=96 in 92 wallclock seconds. Every one of the
  twenty-three groups is now independently verified, so the original
  all_group_dimensions_verified condition makes current-cap proof complete and
  the immutable calibration publication eligible for explicit revalidation.
  It remains historical_measurement_only, has not been revalidated or
  dispositioned, and cannot be relabelled as cap_implementation. Re-derive:
  run the four-file guarded command documented in the book. Falsify: the
  recorded RED proves all twenty-one dimension records and both omission/
  foreign-evidence mutation controls fail before promotion. Durability: the
  policy, caller-sealed consistency authority, regressions, this task, book,
  Knowledge Map, claim disposition, containment authority, and work-unit
  history retain the result without changing any cap, boundary, accepted
  identity, route outcome, product behavior, publication, support, budget, or
  capacity claim.`

  Semantic Type Shape Claim Disposition Finding: `The user-facing three-axis
  boundary/excess sentence produces one actionable candidate. It is a
  derived-gate disposition with non-aliased semantic-catalog, workload,
  parser, and SemanticBuilder re-derivation; t1601/t1692 falsifiers; and the
  exact policy plus caller-sealed consistency authority as durability
  watchers. Re-derive: regenerate the producer-derived inventory and join
  every candidate through the required-complete verification_architecture
  group. Falsify: removing the disposition, a producer, catalog/focused
  oracle, watcher, or current candidate identity fails closed. Durability:
  the disposition registry, generated inventory, this task, and work-unit
  history retain the result at 1,737/1,737 disposed candidates, 965 derived
  gates, and zero gaps/open owners.`

  Semantic Type Shape Book Containment Finding: `The synchronized 59-file
  mdBook is 55,082 lines/2,974,226 bytes, an exact +18 lines/+1,006 bytes from
  the preceding semantic-service-scalar authority. The maintained-reference
  aggregate authority now owns that measured delta, names the complete
  twenty-three-group state and calibration-revalidation eligibility, and
  raises no ceiling. Re-derive: aggregate every docs/book/src Markdown file
  with independent file/line/byte censuses. Falsify: the mdBook, membership,
  relative-path, live-document-size, and doctrine gates reject missing pages,
  drift, unsafe paths, or allowance growth. Durability: the containment
  manifest, book, task, and work-unit history retain the result.`

  Semantic Type Shape Knowledge Containment Finding: `The synchronized
  Knowledge Card aggregate is 46,913 lines/3,464,365 bytes, an exact +7 lines/
  +574 bytes from the preceding 46,906-line/3,463,791-byte authority. The card
  adds the completed type-shape join and explicit calibration-eligibility
  distinction without adding a fact, question, shard, or containment
  allowance. Re-derive: aggregate docs/knowledge Markdown and regenerate the
  Knowledge Map. Falsify: Knowledge Map parity and live-document checks reject
  stale generation, lost answers, missing paths, or transition drift.
  Durability: the card, generated index/shards, task, containment manifest, and
  work-unit history retain the result.`

  Calibration Publication Topology Audit Finding: `The required Knowledge Map
  query returned no answer, and an independent immutable-store census proves
  that the 256 files/32,007,521 bytes are three disjoint sets: the closure's
  232 currently selected source artifacts/28,398,586 bytes, the preserved
  backend-emission-v1 publication's 22 files/2,232,452 bytes, and the closure
  publication's two files/1,376,483 bytes. The closure selects backend-emission
  v2, while commit 0601fa8aa explicitly sealed that non-colliding successor and
  retained v1 as historical evidence. The next authority must therefore
  rederive the selected 232-file lineage through current validators and compare
  it with the immutable closure, authenticate the two closure files, classify
  v1 as explicitly versioned/superseded rather than pretending the v2 producer
  can revalidate it, and require the three-set union to equal the complete
  store with zero residue. Re-derive: extract every repository-relative
  artifact string from the closure report, extract the v1 profile graph plus
  its family/complete manifests, and independently census the full store.
  Falsify: a missing, overlapping, extra, byte-drifted, digest-drifted, or
  wrongly current/legacy-classified path must reject the disposition.
  Durability: this task owns the finding before source changes; the synchronized
  book/Knowledge Map and the completed caller-sealed disposition authority must
  retain the topology without promoting cap_implementation, budgets, support,
  performance enforcement, or capacity.`

  Calibration Topology Claim Disposition Finding: `The four user-facing
  topology lines are four actionable candidates because each publishes a
  separately falsifiable total or partition. All four are derived gates with
  closure/matrix re-derivation, existing t1662/t1683/t1684 byte/digest/identity
  oracles plus the exact-union negative control, and task/book/Knowledge Map
  durability watchers. Re-derive: regenerate the producer-derived inventory
  and join all four current candidate identities. Falsify: removing a
  disposition, producer, oracle, watcher, or current candidate identity fails
  closed. Durability: the disposition registry, generated inventory, this
  task, and work-unit history retain 1,741/1,741 disposed candidates, 969
  derived gates, and zero gaps/open owners.`

  Containment Resolution: `The cap-policy card's long one-path-per-line reverify list is now a shorter equivalent set of numeric brace ranges plus exact outliers; every expansion resolves to an existing tracked test. With checking-randomness evidence added, the card aggregate falls from 46,939 lines/3,464,850 bytes to 46,903 lines/3,462,766 bytes, restoring 39 lines/2,119 bytes below the inherited transition allowance without changing it. Re-derive: expand every compacted pattern and aggregate docs/knowledge Markdown with wc. Falsify: missing paths fail the explicit expansion census, and Knowledge Map/live-document checks reject freshness, answer, transition, or ceiling drift. Durability: this task, the compacted card, generated shard, containment manifest, and work-unit commit retain the resolution.`
  Closure: `The complete cap-consistency authority verifies all 23 groups across all seven required dimensions (161 verified joins) and unlocks explicit calibration revalidation without relabelling measurement as cap implementation. The caller-sealed disposition authenticates the complete immutable publication, versions the atomic 232-file selected lineage as historical after exactly six semantic/bridge current mismatches, derives the separate 239-byte VHDL graph/evaluation drift and portable-VHDL/OSVVM materialization changes, validates the 22-file legacy lineage plus two closure files, and requires their exact 256-file/32,007,521-byte partition. Guarded exact t1764 passes in 785 seconds; focused policy/consistency/disposition passes Files=3/Tests=92 and adjacent closure/publication passes Files=2/Tests=8. Recapture is required before future current-performance use, not cap closeout; immutable bytes remain unchanged and budgets, support, capacity, and reached-boundary claims remain prohibited.`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5`
  Status: `done`
  Goal: `Stabilize architecture-scale regression gates, public documentation, capability truth, and closeout.`
  Acceptance: `Promote representative bounded profiles into stable non-flaky gates; document exact measured envelopes, budgets, commands, variability policy, cleanup, supported claims, and residue; synchronize support/capability/Knowledge Map/task/Memory surfaces without claiming whole-product big/really-big qualification.`
  Verification: `Clean predecessor da26959cf closes all .17.4 cap hardening and atomically versions the immutable calibration closure as authentic historical evidence. Query-first review of decisions 0056/0095, the Knowledge Map, current calibration modules/tests, CI inventory, and Git history finds no promoted architecture-scale regression-gate owner. Decision 0056 requires complete current evidence before promotion, while decision 0095 forbids using the historical candidate budgets as current performance evidence. The activation therefore selects .17.5.1 first and partitions current-evidence capture, budget qualification, gate implementation, public truth, and independent closeout into separate rollback owners. No source, test, artifact, CI, capability, support, budget, performance, capacity, or product behavior changes in activation.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5: activate scale regression closeout`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6`
  Closure: `All six children are complete. A fresh eleven-profile corpus and independent qualification publication feed the exact gate through authenticated materialization, local and hosted CI placement, stable correctness rules, machine and human public truth, and independent closeout. The final production observation is PASS on its exact pinned host/providers, with all 11 profiles accepted, 11 validation records, 33 raw records, 44 controller invocations, zero exclusions, unchanged evidence, atomic result replacement, and no owned residue. Unmatched hosts remain informational, unavailable providers remain non-pass, recalibration remains separate, and no capacity or support claim is inferred.`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.1`
  Status: `done`
  Goal: `Select the exact current-evidence, representative-profile, promotion, regression-gate, and public-truth contract before recapture or gate implementation.`
  Acceptance: `Inventory every candidate profile, current validator/tool/applicability identity, deterministic oracle, raw-sample requirement, candidate budget, CI cost, host-match rule, cleanup proof, support surface, and nonclaim. Compare a complete current closure recapture with a narrower independently versioned representative promotion corpus; select the smallest evidence boundary that satisfies decisions 0056/0095 without borrowing historical measurements, weakening atomic closure identity, or claiming unmeasured capacity. Freeze rollback, recalibration, informational-unmatched-host, CI-placement, and downstream documentation requirements in a decision, focused executable contract, Knowledge Map, mdBook, and task evidence without changing behavior.`
  Verification: `Decision 0096 selects an independently versioned eleven-profile current corpus: semantic actions, bridge backend bindings, execution bindings, checking random occurrences, all three structural backend routes, all three qualified runtime routes, and the balanced structural route. The caller-sealed promotion policy authenticates closure v1, proves its 216-profile/92-candidate/356-raw-record historical scope, requires the eleven coordinates exactly once, and derives 33 historical comparator records versus 356 without treating timing as a budget. Current capture requires eleven validations plus 33 new raw records under a non-colliding v2 publication, exact current identities, zero exclusions, atomic publication, and same-volume cleanup. Exact provider absence is unavailable rather than pass; unmatched hosts retain correctness with informational performance; guarded current capture/gating runs at full pre-push or selected-important-step cadence. Default and RAM-guarded exact t1765 pass Files=1/Tests=8. No historical sample, budget, support, capacity, CI, or product behavior is promoted.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.1: select current regression corpus`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2`
  Status: `done`
  Goal: `Capture and independently publish the .17.5.1-selected current calibration evidence under a new non-colliding version.`
  Acceptance: `Construct only selected canonical profiles through current producers; retain validation plus required raw samples, exact host/tool/guard/applicability identities, deterministic stage oracles, exclusions, cleanup, and nonclaims; atomically publish before bounded IPC; independently reload; and reject stale, partial, mixed, reordered, collided, oversized, symlinked, signalled, or residue-bearing state. Historical v1 bytes remain immutable and cannot satisfy a current-evidence field.`
  Verification: `All five ordered children are complete. The caller-sealed plan, bounded profile/complete stores, isolated capture/resume/coordinator, repository-derived CLI, immutable failed-prefix archive, producer-report coordinate repair, and guarded current capture publish one independently recoverable v2 corpus without borrowing revision-1 bytes. The current seal remains capture revision 155aa22ea with 13 files/6,220,126 bytes, eleven validations, 33 fresh raw measurements, 44 accepted controller invocations, and zero exclusions. Independent census, copied-artifact falsification, canonicalization diagnosis/repairs, revision-separated validation, whole-profile process isolation, guarded production validate/inventory, historical separation, and exact cleanup all agree from clean execution revision 1da11b2e3. Claim, book, Knowledge Map, containment, task, and Git evidence are synchronized. No performance or memory budget, support tier, or capacity claim is promoted; `.17.5.3` owns qualification.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2: activate current corpus publication`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.1`
  Status: `done`
  Goal: `Derive one closed eleven-entry current-capture dispatch plan from the promotion policy and current producer ownership.`
  Acceptance: `Introduce a caller-sealed plan authority that accepts only the repository root, internally derives the .17.5.1 policy, and maps every ordered selection exactly once to its tracked measurement adapter, public measurement method, closed arguments, provider/applicability prerequisite, record count, and v2 publication coordinate. Require eleven profile workers and four common-controller invocations per worker—one validation followed by three measurements—while rejecting caller evidence, private seams, duplicate or missing coordinates, revision-1 paths, and unsupported adapters. Return bounded defensive content-addressed data without invoking a producer, provider, simulator, measurement controller, or publication transaction.`
  Verification: `ArchitectureScaleRegressionPromotionCapturePlan accepts only repository_root, internally authenticates the .17.5.1 policy under the RAM guard, and derives content-addressed plan 0b6a15cea4437d33e86359a7ec01919b122fe16fc70dea8d8d98b75989820c33. Its eleven ordered entries bind all seven current adapters to only measure_profile or measure_member, exact closed arguments, current producer metadata identities, applicability predicates, one worker each, one validation plus three raw records each, and unique ordinal-plus-selection-hash report coordinates below the v2 corpus. Three runtime routes require exact tool profiles; the OSVVM structural route separately requires repository materialization without an external tool; seven routes are provider-free. Fatal producer/controller doubles prove plan derivation runs no work. Missing, duplicate, unknown, revision-1, producer-authority, and provider drift controls fail closed; return data is defensive and deterministic. Default t1766 passes Files=1/Tests=10; guarded authenticated t1765+t1766 passes Files=2/Tests=18. No producer, simulator, measurement, publication, artifact, budget, support, performance, capacity, CI, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.1: derive current capture dispatch`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2`
  Status: `done`
  Goal: `Implement isolated current-profile capture, atomic v2 profile publication, and exact-profile resume.`
  Acceptance: `Consume only one .17.5.2.1 dispatch entry; execute its public current adapter in a separate guard-visible child; require the accepted validation plus three accepted raw records, zero exclusions, canonical workload/report/oracle identities, exact provider/applicability status, cleanup, and current clean revision/common identity; publish the complete canonical profile report atomically beneath the v2 corpus before returning bounded IPC. Resume only a byte-authenticated same-revision/same-identity profile; reject stale, mixed, partial, reordered, collided, oversized, malformed, noncanonical, symlinked, hard-linked, signalled, failed, or residue-bearing state without borrowing any revision-1 byte.`
  Verification: `All four ordered children are complete. The caller-sealed v2 store, isolated heterogeneous dispatch/admission, and fresh-worker exact resume provide the selected current-profile transaction without corpus authority; the final legacy child independently closes both inherited unbounded revision-1 publishers and falsifies a current semantic/bridge coordinator guard failure. Focused default, guarded v2, historical-census, claim, mdBook, Knowledge Map, containment, task, and doctrine evidence is recorded in the child checklists and commits. No revision-1 artifact is rewritten or borrowed into v2, and no simulator, current corpus capture, budget, support, performance, or capacity claim is introduced. `.17.5.2.3` remains a separately activatable complete-corpus owner.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2: partition isolated profile publication`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.4`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.1`
  Status: `done`
  Goal: `Implement the bounded same-volume v2 single-profile publication store without producer execution.`
  Acceptance: `Add one caller-sealed storage authority for only a current dispatch entry's exact v2 report coordinate. Define closed canonical publication/artifact schemas and conservative report/IPC/error ceilings; create and fsync one repository-local staging directory and file, atomically rename only the complete directory, reload by lstat/stat/read/digest/canonical-JSON checks, and reject absolute/escaping/revision-1/unknown paths, extra entries, symlinks, hard links, cross-device state, collisions, oversized or malformed bytes, ambiguous recovery, and cleanup residue. Default tests use bounded synthetic publications and never invoke an adapter, provider, simulator, measurement controller, or real capture.`
  Verification: `Implementation and focused verification are green; final synchronized gate evidence is recorded in the fresh checklist below. The store derives the exact current entry from ordinal rather than accepting a path; wraps only JSON-object reports in a content-addressed plan/policy/profile envelope; fsyncs the repository-local file and staging directory before complete-directory rename; reopens by pathname/handle identity, exact census, one-link/device/owner/size, digest, canonical JSON, and current-plan checks; recovers only one byte-exact stage; and returns bounded closed artifact metadata. Synthetic current-plan tests install fatal producer/controller doubles and leave no fixture residue. Source/history audit also exposed two unbounded legacy revision-1 publishers, now owned by .17.5.2.2.4 rather than silently inherited.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.1: implement bounded v2 profile store`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.1.1`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.1.1`
  Status: `done`
  Goal: `Repair the stale repository-default claim-registry census watcher exposed by the profile-store broader gate.`
  Acceptance: `Reproduce t1750 against the unchanged two-shard registry; prove by Git history and blame that d11fb2a4e added the twenty-seventh/26th-published record while leaving the repository-default watcher at 26/25; update only the exact expected census to 27/26; retain all positive, missing/extra/reordered/duplicate/oversized shard controls; run the focused claim suite plus doctrines; and synchronize the task/frontier without modifying a claim record or hiding future registry growth.`
  Verification: `The pre-change RED failed only t1750's repository-default message match: the checker reported shards=2, records=27, published=26, fixtures=1 while line 230 expected records=26, published=25. Git blame assigns that expectation to 0b6f25fba; git history shows d11fb2a4e subsequently added vial-common-bounded-cleanup-admission-v1 to claims-0002.jsonl without updating the watcher. Updating only that exact census returns the four-file focused claim suite to All tests successful at Files=4, Tests=38; all three claim checkers agree on 1,762/1,762 disposed candidates, 179 claim records, 988 gates, 595 reviewed dispositions, and zero gaps/open owners.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.1.1: repair claim registry census watcher`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.2`
  Status: `done`
  Goal: `Execute and admit one current dispatch entry in an isolated profile worker before atomic publication.`
  Acceptance: `Internally derive the current plan, select only one ordinal, execute only its public adapter/method with its sealed arguments in one guard-visible child, validate through that adapter, and require exact coordinates, accepted validation followed by three accepted gate measurements, zero exclusions/residue, deterministic identities, exact applicability/provider status, clean revision, and one within-profile host/tool/guard/common identity. Publish through .1 before returning bounded metadata-only IPC; reject caller entry/report/callback/private-method injection plus exception, exit, signal, malformed, noncanonical, oversized, mixed, reordered, failed, or mutation controls.`
  Verification: `ArchitectureScaleRegressionPromotionProfileCapture accepts only repository_root plus one numeric plan ordinal, requires the active repository RAM guard and a clean current Git revision, then derives the current plan and executes exactly the sealed public adapter method in one child. Generic admission requires the selected coordinates, one accepted ordinal-zero validation followed by accepted measurement ordinals one through three, zero exclusions/diagnostics, exact JSON scalar types, complete four-record cleanup, one host/tool/guard/revision identity, and the route's exact external tool profile or read-only OSVVM repository materialization. Only admitted reports reach the bounded v2 profile store; canonical metadata crosses the 65,536-byte IPC boundary, while the parent reloads exact artifact bytes, reruns the public validator and admission, and proves revision stability. The all-eleven-route public-method watcher rejects caller injection, mixed/reordered/incomplete/failed/residual state, provider substitution, repository mutation, dirty starts, exception/exit/signal, malformed/noncanonical/cap-plus-one IPC, and leaves repository-local fixtures clean without running a simulator or scale producer. Syntax passes; the guarded focused watcher reports Files=1/Tests=9 and policy/plan/store/capture integration reports Files=4/Tests=37. The source audit also durably routes the semantic/bridge legacy coordinator-isolation asymmetry to .17.5.2.2.4.1 as a risk requiring reproduction, not a current failure.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.2: implement isolated profile dispatch`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.3`
  Status: `done`
  Goal: `Close exact same-profile resume and adversarial v2 profile-publication validation.`
  Acceptance: `Resume without producer execution only when the exact plan, dispatch entry, repository revision, profile common identity, provider/applicability identity, complete report bytes, artifact census, and cleanup state revalidate in a fresh isolated worker. Reject stale revision/plan/tool/host/guard/provider, mixed records, missing/extra/reordered identities, partial/collided/revision-1 substitutions, post-validation mutation, staging or target residue, symlink/hard-link/cross-device aliases, and noncanonical or oversized state; synchronize runnable docs and leave complete-corpus sealing to .17.5.2.3.`
  Verification: `ProfileStore::load now rejects same-profile staging residue before target-byte use. ProfileCapture::resume accepts only repository_root plus numeric ordinal, requires the guard and unchanged clean revision, loads in a fresh child without a producer fallback, reruns the plan-selected public validator and exact report/provider/applicability/common-identity admission, re-derives current host/guard plus foundation-tool identity while exact external routes remain provider-bound, and returns only loaded metadata. The parent independently reloads the same artifact and repeats validation, admission, current identity, artifact metadata, and revision checks. Rehashed stale plan/dispatch publications, revision/host/guard/tool/provider drift, mixed records, target/staging residue, v1 substitution, post-worker mutation, repository mutation, exception, and signal controls reject; the bounded store watcher retains malformed/oversized/symlink/hard-link/cross-device/collision controls. Syntax passes; guarded focused t1769 reports Files=1/Tests=8 and policy/plan/store/capture/resume integration Files=5/Tests=45. The mdBook, compact Knowledge card/Map, claim inventory, and exact containment authority synchronize the producer-free resume boundary without running a producer, simulator, real capture, or complete-corpus seal.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.3: close exact profile resume`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.4`
  Status: `done`
  Goal: `Close the two inherited unbounded revision-1 semantic/execution publication readers and writers.`
  Acceptance: `Independently census current semantic/bridge and execution/checking publication bytes, select and three-leg verify conservative storage ceilings without implying capacity, and add encode-before-write plus stat-before-read enforcement to both legacy publishers. Require canonical newline-terminated JSON, exact single-file census, same-volume regular files with one link, bounded reads, and focused exact-cap/cap-plus-one/malformed/noncanonical/symlink/hard-link controls without changing historical artifact identities or weakening family admission. Keep this remediation separate from v2 evidence and complete it before closing .17.5.2.2.`
  Verification: `Independent t1771 lstat/JSON census authenticates 111 semantic/bridge files totaling 7,418,437 bytes with a 253,882-byte maximum and 75 execution/checking files totaling 7,312,415 bytes with a 759,867-byte maximum; all 186 remain canonical, exact-directory, regular, same-volume, one-link, and admitted through the repaired readers. Semantic/bridge selects the conservative 524,288-byte binary envelope because the current maximum leaves only 8,262 bytes below 256 KiB; execution/checking selects 1,048,576 bytes above its current maximum. Both publishers expose closed limits, reject encoded cap-plus-one before staging, and require a stable opened directory census plus stable no-follow regular one-link file identity while reading no more than ceiling plus one. Exact-cap write/reload passes; cap-plus-one write/read/recovery, malformed, missing-newline, noncanonical, extra/late directory entry, symlink, and hard-link controls reject. Original matrix watchers preserve inventories, admission, child isolation, collision, and no-default-capture behavior; the registered claim, book, Knowledge Map, and doctrine watcher retain the limits and their explicit non-capacity meaning.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.4: bound legacy matrix publications`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.4.1`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.4.1`
  Status: `done`
  Goal: `Resolve the inherited semantic/bridge revision-1 coordinator-isolation asymmetry before legacy hardening closes.`
  Acceptance: `Reproduce current semantic/bridge publication reload under the unchanged repository RAM guard and compare its direct long-lived _capture_family validation loop with one fresh process per immutable profile. Prove whether full adapter regeneration retains coordinator high-water memory across profiles, using the existing clean 108-profile publication and bounded synthetic allocation controls without relabelling evidence. If retention can threaten the selected guard, isolate capture and immutable reload per profile with closed bounded canonical IPC and exact exception/exit/signal/malformed/oversized controls; otherwise retain independently repeatable evidence that direct validation stays bounded. Preserve report bytes, public APIs, common identity, publication paths, cleanup, and all performance/capacity nonclaims.`
  Verification: `Query-first audit and exact history distinguish semantic/bridge's direct revision-1 coordinator from the later b9463c663 execution/checking repair. A new read-only tracked audit traverses the exact immutable publication loader either directly or in one child per profile, pins its six accepted drifts to ArchitectureScaleCalibrationDisposition, emits one closed 108/102/6 census, and offers a capped 67,108,864-byte synthetic control. Under the unchanged 4,096-MiB guard, direct validation completes all 108 profiles at 2,236,547,072-byte maximum RSS and 1,603,422,248-byte coordinator peak, leaving 2,058,420,224 bytes of process-cutoff headroom; isolation reproduces the same census at 1,368,801,280-byte maximum RSS and 106,987,952-byte parent peak. The asymmetry is real, but a current guard failure is falsified; the conditional no-repair branch preserves product code and avoids inventing a performance conclusion from one 541.06/503.44-second run per arm. Focused t1770 and synchronized task/book/Knowledge Map evidence make the audit repeatable without recapture, publication, support, capacity, or budget claims.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.2.4.1: close coordinator isolation audit`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3`
  Status: `done`
  Goal: `Coordinate the ordered eleven-profile corpus and atomically seal one independently reloadable complete publication.`
  Acceptance: `Add a bounded repository-relative CLI and caller-sealed coordinator with inventory, capture, and validate operations. Walk the exact dispatch order, preserve exact profile-boundary resume under one clean revision and complete common host/tool/guard/provider identity, independently reload every profile in a fresh worker, census all eleven validations and 33 raw records with zero exclusions, and withhold the family/complete seal until every profile is present and current. Atomically publish a canonical corpus report plus manifest under the selected v2 path; prove collision, interruption, malformed/oversized IPC, child exception/exit/signal, mixed identity, duplicate/missing/reordered profile, post-validation mutation, staging ambiguity, and cleanup residue fail closed. Default tests use injected bounded workers and do not run real measurement producers or tools.`
  Verification: `All three children are complete. .1 implements the producer-free canonical report-plus-manifest store, .2 implements closed ordered inventory/capture/validate coordination over the existing bounded profile-worker boundary, and .3 supplies an explicit-operation repository-relative CLI with canonical bounded stdout plus fresh-process public-path controls. The final guarded policy/plan/profile-store/capture/resume/corpus-store/coordinator/CLI integration reports Files=8/Tests=65. Synthetic watchers execute no real producer, provider, simulator, controller, measurement, or v2 evidence capture; those remain exclusively owned by .17.5.2.4.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3: activate complete corpus coordination`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.1`
  Status: `done`
  Goal: `Implement the bounded canonical complete-corpus report-plus-manifest store without profile execution.`
  Acceptance: `Derive only the selected v2 complete coordinate from the current plan; define closed report, manifest, artifact, and limit schemas; accept only all eleven ordered admitted profile results with 11 validations, 33 raw records, zero exclusions, one complete identity, and immutable profile artifacts; then atomically publish exactly a canonical report plus compact manifest on the repository volume before returning bounded metadata. Reload through stable no-follow directory/file handles with exact census, byte/hash/schema/identity/current-plan checks and reject collision, partial or ambiguous stage, extra/missing/reordered profile, stale or mixed identity, malformed/noncanonical/oversized bytes, symlink/hard-link/cross-device aliases, post-validation mutation, and cleanup residue. Default tests use synthetic admitted metadata and never invoke a profile worker, producer, provider, simulator, or measurement controller.`
  Verification: `ArchitectureScaleRegressionPromotionCorpusStore accepts only repository_root plus eleven ordered admitted profile results, internally derives the current plan and exact complete coordinate, reloads every immutable profile artifact, requires 11 validations/33 raw records/44 invocations/zero exclusions, and separates globally common revision/host/guard identity from route-specific tool/provider identity. It projects transient profile artifact status out of the corpus hash, then atomically publishes canonical report plus manifest under fixed 1,048,576-byte/65,536-byte containment ceilings and reloads through stable no-follow two-file census and bounded reads. Exact recovery and byte-identical republish pass; missing/duplicate/reordered/mixed/stale/mutated profile, JSON string ordinal/count/version, collision, partial cleanup, ambiguous/residual stage, malformed/noncanonical/cap-plus-one report or manifest, late directory entry, symlink, and hard-link controls reject. Focused guarded t1772 passes Files=1/Tests=8; integrated t1765–t1769+t1772 passes Files=6/Tests=53. The store/test/book/card/claim evidence run no profile worker, producer, provider, simulator, controller, current measurement, or real v2 publication and promote no budget, support, performance, or capacity claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.1: implement complete corpus store`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.2`
  Status: `done`
  Goal: `Coordinate exact ordered profile capture or resume and seal only a fully revalidated current corpus.`
  Acceptance: `Expose caller-sealed inventory, capture, and validate operations over repository_root only. Require the active guard and one unchanged clean revision; walk all eleven plan ordinals exactly once; capture a missing profile or exact-resume an existing one only at profile boundaries; independently reload and re-admit each through a fresh profile worker; enforce one common revision/host/guard identity plus the exact ordered route-specific tool/provider/applicability identities, 11 validations, 33 accepted raw records, zero exclusions and cleanup residue; and publish through .1 only after every profile passes. Return bounded metadata-only IPC and reject caller worker/result injection in production, exception, exit, signal, malformed/noncanonical/oversized IPC, duplicate/missing/reordered profile, mixed identity, repository mutation, and post-worker artifact mutation. Default tests use a sealed bounded test worker and run no real producer or tool.`
  Verification: `ArchitectureScaleRegressionPromotionCorpusCoordinator exposes closed repository_root-only inventory, capture, and validate operations under the active RAM guard and one unchanged clean revision. Inventory performs no worker or producer execution. Capture walks the derived plan exactly once, resumes present profiles and captures only missing profiles through the existing ProfileCapture boundary, reloads the exact artifact again in the coordinator parent, enforces common revision/host/guard identity plus route-specific provider/applicability identity, and publishes through CorpusStore only after complete closure. Validate requires an existing complete seal, producer-free resumes every profile in fresh workers, and loads without republishing. This layering deliberately reuses ProfileCapture's bounded canonical child IPC and failure handling instead of introducing a weaker second fork framework. Numeric-looking JSON strings reject at every coordinator admission boundary. Guarded focused t1773 passes Files=1/Tests=7; policy/plan/store/capture/resume/corpus/coordinator integration passes Files=7/Tests=60. Synthetic adapters exercise all routes without a real producer, provider, simulator, controller, measurement, or v2 evidence publication; CLI closeout remains proposed .3 and real guarded capture remains proposed .17.5.2.4.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.2: implement complete corpus coordinator`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.3`
  Status: `done`
  Goal: `Close the repository-relative corpus CLI and adversarial coordinator/publication contract before real capture.`
  Acceptance: `Add limits, inventory, capture, and validate CLI modes that derive the repository root from the script location, require guarded clean-state authority where applicable, emit only bounded canonical JSON, and document exact resume, unavailable-provider, cleanup, current-evidence, and nonclaim behavior. Exercise the public production paths with deterministic bounded workers and independently falsify interruption, collision, stage ambiguity, report/manifest mutation, stale or mixed common/provider identity, duplicate/missing/reordered profiles and records, malformed/oversized IPC, child exception/exit/signal, repository mutation, symlink/hard-link/cross-device state, and target/staging residue. Synchronize runnable mdBook, Knowledge Map, task, and claim evidence while leaving real capture exclusively to .17.5.2.4.`
  Verification: `The executable run_vial_regression_promotion_corpus.pl derives the repository root from its own tracked location and requires exactly one case-sensitive, unabbreviated --limits, --inventory, --capture, or --validate operation; omitted or ambiguous selection cannot default into expensive capture. Limits is guard-free; all state operations delegate to the coordinator, which retains active-guard and clean-revision authority. The CLI encodes the complete result before output and admits only canonical newline-terminated JSON at or below a fixed 1,048,576-byte envelope, so cap-plus-one emits no partial stdout. Fresh-process t1774 uses a script-local coordinator double to prove exact method/root dispatch, option closure, exact-cap/cap-plus-one, failure propagation, and cleanup without product injection or real work. Both new files pass syntax; guarded focused t1774 passes Files=1/Tests=5 and full .17.5.2.3 integration passes Files=8/Tests=65. Existing t1772/t1773 retain storage, profile, identity, interruption, collision, mutation, worker-failure, and seal-withholding controls.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.3.3: implement corpus CLI closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4`
  Status: `done`
  Goal: `Capture and atomically publish the complete real current corpus at one clean implementation revision.`
  Acceptance: `From the clean .17.5.2.3 implementation revision, run the production capture CLI under the active repository RAM guard and repository-local providers. Capture or exact-resume all eleven selected profiles through their current canonical producers; require one validation and three fresh raw measurements per profile, all 44 controller records, zero exclusions, one common revision/host/guard identity plus exact route-specific tool/provider identities, deterministic stage oracles, complete cleanup, and no revision-1 substitution. Publish the v2 complete seal only after all profiles reload successfully. If a route is unavailable or disagrees, retain honest partial publications, withhold the seal, root-cause the exact producer/provider/admission failure under this owner, and never relax validation, timing, guard, or evidence identity to force acceptance.`
  Verification: `The first guarded production attempt at clean revision 610ed7869 failed closed after four profiles; .1 preserves that exact prefix and failure, and .2 repairs the selection/report-coordinate admission defect without weakening producer truth. Child .3 then ran a fresh guarded production capture from an empty active namespace at clean revision 155aa22ea. All eleven current profile reports were newly published and admitted as eleven validations plus 33 fresh raw measurements and 44 controller invocations with zero exclusions. The complete same-volume report-plus-manifest seal published atomically as corpus ab2df899...e505 and publication 865c5cce...432e; a distinct guarded producer-free process resumed all eleven profiles and reproduced every common, route-specific, report, plan, policy, publication, and file-set identity before inventory reported eleven present and zero missing. Post-publication replay exposed and closed the historical verifier's obsolete permanent-empty assertion: verification schema v2 accepts absent current state or authenticates this exact 13-file/eleven-profile seal separately from the five-file archive, while copied-evidence controls reject current mutation, foreign paths, cross-history hard links, and archive mutation. No revision-610ed7869 profile byte entered the current corpus, staging was empty at completion, and no budget, support, performance, or capacity claim is promoted.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.3: seal repaired current corpus`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.1`
  Status: `done`
  Goal: `Preserve the exact failed clean-revision capture prefix before changing its plan or implementation identity.`
  Acceptance: `Admit only the four immutable ordinal-one-through-four publications under the active v2 profile namespace; require their exact revision 610ed7869, plan/policy identities, selected coordinates, canonical payloads, regular single-link shape, current-owner and same-volume state, individual hashes, 600,036 aggregate bytes, zero ordinal-five publication, absent corpus report/manifest, and no staging residue. Move the complete profile prefix atomically or rollback into a revision-keyed content-addressed same-volume history directory with one canonical manifest that records the ordinal-five primary_axis admission failure and explicit no-seal status. Independently reconstruct every archived byte/hash/identity and prove the active v2 namespace is empty before any source change.`
  Verification: `A rollback-capable same-volume move admitted exactly the four canonical ordinal-one-through-four publications at clean capture revision 610ed7869 and published them under history/610ed7869.../regression-promotion-report-coordinate-failure-ordinal-5-v1 with canonical archive identity f46939aa...e5a4. The tracked repository-relative verifier reconstructs five files/604,539 bytes: four reports/600,036 bytes plus one 4,503-byte manifest; manifest SHA-256 is 06cb9873...2223, profile-inventory digest is 286a4948...0f6d, and whole-archive file digest is ffb9197d...1654. Every report retains its exact individual hash, plan/policy/publication/report/selection identity and four clean accepted controller records. The manifest retains exit 70, failed ordinal five, the exact primary_axis diagnostic, absent failed profile/corpus report/corpus manifest, and no staging. The verifier is syntax-clean and emits the exact canonical census; a repository-local copied-report run_ordinal mutation rejects with archive file identity changed and empty stdout. The active v2 namespace and archive staging are both absent. No evidence was deleted, relabelled, or admitted into a later revision.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.1: archive failed report-coordinate prefix`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.2`
  Status: `done`
  Goal: `Separate policy selection coordinates from producer-report coordinates and close the synthetic-test hole.`
  Acceptance: `Retain decision-0096 selection keys and publication paths unchanged. Add one closed authenticated report-coordinate authority to every capture-plan entry, derive each expected family/level/primary_axis/backend_profile from canonical producer ownership rather than caller data, and make child/parent capture plus resume admission compare reports against that authority. Make synthetic reports reproduce the real producer axes for all eleven routes. Prove every individual coordinate mutation, omission, appearance, plan/identity forgery, and selection/report aliasing rejects while focused plan/capture/resume/coordinator/CLI integration stays green.`
  Verification: `A RED t1766 first proved the capture plan had no report_coordinate_authority, none of the seven adapters exposed canonical report coordinates, and changed/missing/extra producer-coordinate controls were not consumed. Capture-plan schema v2 now adds one closed content-addressed report-coordinate authority per entry while retaining every decision-0096 selection key and publication path. Each adapter derives family/level/primary_axis/backend_profile through its existing canonical ownership validator; eleven pinned digests prevent rehashed plan or identity forgery. ProfileCapture uses only that authority for both child capture and parent resume admission. Synthetic capture/resume/coordinator reports now reproduce all eleven real axes: semantic/bridge and execution/checking retain their selected axes, while backend, runtime, and balanced routes use artifact_graph, runtime_trace_records, and interaction_profile independently of their nullable selection axes. Tests change and omit each of four coordinates, make an inapplicable backend coordinate appear, challenge adapter output and plan/authority identities, and prove selection/report independence. All nine touched modules and four changed watchers are syntax-clean. The guarded plan/store/capture/resume/corpus/coordinator/CLI chain passes Files=7/Tests=58; no producer, provider, simulator, measurement, real capture, publication, budget, performance, support, or capacity work ran.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.2: authenticate producer report coordinates`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.3`
  Status: `done`
  Goal: `Capture the complete repaired current corpus from an empty active namespace.`
  Acceptance: `From the clean report-coordinate repair revision and empty active v2 namespace, run production --capture under the RAM guard. Require all eleven current profiles, eleven validations, 33 fresh raw measurements, 44 accepted controller records, zero exclusions/diagnostics, one admitted common identity, route-specific provider identity, complete cleanup, and an atomic corpus report/manifest seal. Preserve any new honest failure prefix under the same revision-keyed doctrine; do not reuse revision-610ed7869 bytes. After successful current publication, keep the tracked failed-prefix verifier runnable by replacing its obsolete permanent-empty active-namespace assertion with exact read-only separation checks: authenticate the current complete corpus/manifest identity without treating it as archive evidence, reject overlap or aliasing with history, and retain all historical byte/hash/path/device/owner/staging controls.`
  Verification: `From the empty active namespace and clean current revision 155aa22ea, the guarded production --capture newly ran all eleven current adapters, including exact Verilator, GHDL, and GHDL-plus-OSVVM runtime routes. It published eleven atomic profile reports representing eleven validations, 33 fresh raw measurements, 44 accepted controller invocations, and zero exclusions. Common identity is clean revision 155aa22ea on the sealed Apple-M4-Pro/APFS host and repository RAM guard; exact route-specific providers are retained per profile. The complete corpus is regression-promotion-corpus/ab2df899...e505, publication is 865c5cce...432e, plan is fbf69740...9737, policy is 19cf4105...ece, and file-set SHA-256 is dc5b315b...c66f. The 23,288-byte corpus report and 1,280-byte manifest published atomically under the repository-relative complete coordinate with hashes d6139d0f...84a1 and 3de607e3...0273. A distinct guarded --validate process captured nothing, resumed all eleven profiles, reproduced every identity and count, and accepted zero exclusions; guarded --inventory then reported eleven present, zero missing, and the same seal. The post-publication historical verifier initially rejected that legitimate current state because .4.1 had encoded its then-empty active namespace as permanent. Schema v2 now keeps archive-only replay, or authenticates exactly 13 current files/eleven profiles at corpus ab2df899...e505 without using them as history; t1775 rejects current content mutation, a foreign file, cross-history hard-link aliasing, and historical mutation with empty result output. Staging was empty after every observed publication and at completion. Independent artifact census and mutation falsification remain explicitly owned by .17.5.2.5, so this result promotes no performance budget, support, or capacity claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.4.3: seal repaired current corpus`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5`
  Status: `done`
  Goal: `Independently reload, census, falsify, document, and close the current v2 publication for budget qualification.`
  Acceptance: `Validate the sealed publication in a distinct fresh process without capture authority; independently reproduce its exact file/byte/hash/device census, ordered profile/record counts, common identities, applicability/provider outcomes, correctness/oracle closure, exclusions, cleanup, and aggregate statistics. Falsify report, manifest, profile, ordering, identity, provider, count, digest, file-shape, extra-path, and historical-substitution controls; synchronize task/book/Knowledge Map/claim evidence and leave performance budgets entirely unpromoted for .17.5.3. Also root-cause the CPU-bound balanced-profile and corpus canonicalization observed during .4.3: use macOS `sample -file` only with a repository-derived `.artifacts/` destination, distinguish expected evidence-size cost from avoidable hash/array copying, and task-tree own any proven defect before budget work. Close .17.5.2 only when clean Git plus immutable same-volume evidence can recover the complete result without conversation state.`
  Verification: `All four ordered children are complete. The standalone verifier independently reconstructs the exact current namespace and nonclaims; same-volume copied mutations falsify every safe content, semantic, file-shape, namespace, staging, and historical-substitution class; guarded v3 diagnostics located and repaired repeated plan derivation plus balanced-composition reconstruction without changing outputs; revision-separated validation and whole-profile process isolation then made the immutable seal revalidatable from a later clean revision without aggregate parent retention. Final guarded production validate/inventory, independent before/after census, historical separation, adjacent watchers, and cleanup agree exactly. The retained diagnostic samples remain point observations only. No budget, support, performance, memory, capacity, or stable ratio is promoted.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5: activate current corpus closeout`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.1`
  Status: `done`
  Goal: `Implement a producer-independent read-only verifier and exact census for the sealed current publication.`
  Acceptance: `Derive the repository root from the tracked verifier location and import no regression-promotion store, coordinator, capture, measurement, provider, or simulator implementation. Traverse the active v2 namespace read-only; reject symlinks, non-regular or multiply linked files, foreign owner/device, extra or missing files/directories, staging residue, noncanonical JSON, and every manifest/report/profile content mismatch. Independently reproduce the exact 13-file layout, per-file byte/SHA-256 identities, total bytes, eleven ordered profiles, validation/raw/controller/exclusion counts, common revision/host/guard identity, report-coordinate and applicability/provider outcomes, corpus/publication/plan/policy/file-set identities, and explicit nonclaims. Emit one bounded canonical newline JSON result only after the complete census succeeds, with no producer or production reload call.`
  Verification: `The tracked standalone verifier derives the repository from its own location and uses only core Perl filesystem, JSON, byte, and SHA facilities—no FSMGEN production module or library path. It traverses the active namespace read-only; enforces exact owner/device, directory, regular one-link file, canonical JSON, and empty profile/corpus staging state; recomputes corpus, publication, profile-publication, and all eleven family report identities; and binds report coordinates, common revision/host/guard state, applicability, providers, 44 ordered accepted controller records, every successful correctness oracle, cleanup, exclusions, and explicit nonclaims. It reconstructs exactly 13 files/6,220,126 bytes with direct inventory digest 94c11e5c...bb57, including eleven profile reports, 11 validations, 33 raw records, 44 invocations, and zero exclusions. This direct digest is scope-distinct from production file-set dc5b315b...c66f, which hashes report plus manifest and binds profile byte/hashes transitively through the report. Provider status remains seven non-external foundation routes, one repository OSVVM materialization, and three exact external-tool routes. t1775+t1776 pass Files=2/Tests=6 and prove canonical bounded output, closed invocation, absence of production imports, byte/file-identity parity, historical separation, and copied outer-seal controls without a producer or simulator. All 59 mdBook chapters test; the inspected repository-local render contains 94 files/21,204,890 bytes and is removed. Claim inventory/disposition joins report 1,786/1,786 candidates disposed, 193 claim records, 991 gates, 602 reviewed, and zero gaps/open owners. Actual copied-publication mutations remain exclusively owned by .5.2, so the claim's falsification leg remains explicitly missing.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.1: implement independent current corpus census`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.2`
  Status: `done`
  Goal: `Falsify the independent verifier against copied exact real-publication mutations.`
  Acceptance: `Use only repository-local same-volume copies of the exact active publication. Prove baseline acceptance and empty stdout on report, manifest, profile, ordering, identity, provider, count, digest, canonicality, link, owner/device where safely reproducible, file-shape, extra/missing path, staging, and historical-substitution mutations; restore or remove every fixture deterministically and leave the real publication byte-identical.`
  Verification: `The tracked t1777 watcher installs the tracked independent verifier beside one exact repository-local same-volume copy of the 13-file/6,220,126-byte current publication. One baseline plus every restored state re-authenticates. Seventeen actual copied-artifact controls mutate complete report, manifest, profile report, profile order, corpus identity, provider identity, count, digest, canonicality, symlink, hard link, FIFO shape, extra path, missing path, profile staging, corpus staging, and historical-profile substitution; every control exits nonzero with empty stdout and a diagnostic bounded at 65,536 bytes, restores the exact copied path/mode/link/owner/device/size/hash census, and then passes full verification. Foreign-owner mutation is unavailable without privilege and foreign-device mutation is forbidden by same-volume policy, so neither is fabricated; the verifier's direct lstat owner/device comparison and the copied baseline's exact common owner/device are checked. The real publication's pre/post path/inode/mode/link/owner/device/size/hash census is identical, and the fixture is absent after completion. RAM-guarded t1777 passes Files=1/Tests=7 in 110 seconds; final adjacent t1776+t1777 passes Files=2/Tests=10 in 121 seconds. All 59 mdBook chapters test; the inspected repository-local render contains 94 files/21,212,073 bytes and is removed. Knowledge Map parity remains 1,160 facts/6,247 questions/6,419 occurrences/138 shards within the existing allowance after redundant historical watcher paths are compacted; claim joins close 1,787/1,787 candidates, 194 claim records, 991 gates, 602 reviewed, and zero gaps/open owners. No ceiling rises. No production reload, producer, provider, simulator, measurement, budget, support, capacity, or real-publication mutation occurs. This closes the registered claim's formerly missing actual-artifact falsification leg.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.2: falsify copied current corpus mutations`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3`
  Status: `done`
  Goal: `Characterize and, if warranted, repair current-corpus canonicalization cost before budget qualification.`
  Acceptance: `Measure the balanced-profile and complete-corpus phases under the repository RAM guard with project-local `sample -file` output and bounded instrumentation. Attribute CPU, wall, allocation/copying, input/output bytes, and canonicalization multiplicity separately; distinguish inherent evidence-size cost from avoidable repeated whole-graph encoding or hash/array copying. If a defect is proven, add a narrower child owner before source repair and prove byte/identity parity plus focused performance improvement; otherwise retain a measured nondefect rationale. Do not promote a regression budget.`
  Verification: `The tracked v3 runner derives the repository root, requires the active RAM guard and one closed repository-local sample path, instruments each loaded FSM module without extra probe encodes, preserves imported prototypes, times top-level clones, counts recursive nodes separately, emits one bounded canonical result, and independently authenticates the current corpus before/after. Baseline fafe5d88b proves two avoidable authority rebuilds beside required fresh correctness work. Child .3.1 replaces twelve plan/policy derivations with one internally authenticated all-profile load while preserving corpus identity. Child .3.2 passes one already accepted six-gate composition through the exact-caller emission seam while retaining both emission routes, replay, every oracle, foreign-caller rejection, and report identity. The final corpus and balanced point measurements preserve exact outputs while reducing the attributed rebuild work; their timing and sampler observations promote no budget, support, memory, capacity, or stable ratio. Superseded development results are inadmissible.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3: activate canonicalization cost characterization; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3.1: derive corpus profile plan once; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3.2: reuse accepted balanced composition`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3.1`
  Status: `done`
  Goal: `Eliminate repeated capture-plan derivation during complete current-corpus load without accepting caller authority.`
  Acceptance: `Start from the measured 12-full-policy-encode RED. Give ProfileStore one closed repository-root-only all-profile load that derives the current plan once, checks every profile staging coordinate, and loads all eleven exact entries in plan order; make CorpusStore consume that authenticated store result without accepting a caller-supplied plan or weakening any report/profile/artifact validation. Prove synthetic rejection parity, exact current 13-file/corpus/publication/result-byte identity, and a guarded v3 corpus characterization with one—not twelve—full policy encode; retain independent before/after census and no budget claim.`
  Verification: `ProfileStore now exposes only closed `load_all({repository_root})`: it derives the authenticated current plan internally once, requires exactly eleven ordered entries, preflights every profile staging coordinate, reads each exact immutable publication, clones one closed plan/profiles result, and postflights all coordinates again. CorpusStore checks the derived plan, every entry, publication, artifact, count, and order before using that bundle for its unchanged report/profile/reference validation; callers cannot inject a plan, ordinal, or bundle. Hostile synthetic controls reject absent/reordered/string-typed/foreign-plan/changed-report bundles, first-read mutation plus last-coordinate residue, and residue appearing during the ordered read. RAM-guarded t1767+t1772+t1778 pass `Files=3, Tests=23` in 13 seconds; t1778 locally clears inherited guard state so its four negative invocations reject without emitting an artifact. Final guarded v3 result `5e1a9eec...ab6f` plus sample `92cf97b8...98a5` preserve the exact 13-file/6,220,126-byte inventory `94c11e5c...bb57`, corpus/publication identities, empty staging, and exact 25,417-byte output `11e0c755...21e7`. Against baseline fafe5d88b, policy whole-graph encodes fall 12 -> 1 and bytes 16,496,724 -> 1,374,727; total canonical bytes fall 36,790,450 -> 20,186,110, top-level clones 1,091 -> 124, recursive clone nodes 50,256 -> 4,188, clone-encoding bytes 13,558,259 -> 12,567,517, and SHA input bytes 30,407,371 -> 13,981,715. This host point records 23.093509 -> 6.554453 seconds wall and 9.41 -> 5.32 seconds user CPU, while the sampler's rounded phase-start footprint rises 210.2M -> 220.6M; neither timing nor footprint is a budget, support, memory, or capacity claim. The r1 development pair and accidental inherited-guard sample are removed; only final r2 evidence remains.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3.1: derive corpus profile plan once`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3.2`
  Status: `done`
  Goal: `Reuse the already authenticated balanced composition when constructing measurement emission.`
  Acceptance: `After .3.1 is clean, make measurement `_canonical_bundle` use the existing exact-caller `_measurement_evaluate` seam with its independently accepted composition instead of public emission evaluation that rebuilds the same six-gate composition. Retain fresh construction, six-gate composition, two-route determinism, replay, two-route emission, every report/member oracle, foreign-caller rejection, and exact returned report/publication identities. Prove focused v3 reductions against the .3 baseline without setting a performance budget.`
  Verification: `Measurement `_canonical_bundle` now passes its already accepted composition to Emission `_measurement_evaluate`; exact caller authentication, two independent emission routes, byte-equal rerun, replay, every artifact/report/member oracle, and foreign-caller rejection remain intact. Static t1778 proves the canonical bundle contains the private seam plus accepted composition and no public-emitter call. RAM-guarded exact t1681 passes Files=1/Tests=5 in 2,396 seconds and dynamically proves one producer evaluation, zero public-emitter evaluations, one private-seam evaluation, exact report regeneration, hostile report/applicability rejection, five-stage records, and cleanup. Final guarded v3 result b03f7ea7...cf2 plus sample 1a6a9c15...3be preserve the exact 1,244,823-byte input, 1,241,948-byte output 0999d139...edb5, corpus/inventory identities, empty staging, and publication bytes. Against baseline fafe5d88b, canonical bytes fall 1,325,878,982 -> 813,307,147, clone-encoding bytes 121,737,844 -> 70,814,879, hash input 1,044,992,073 -> 640,333,611, top-level clones 946,272 -> 596,715, and recursive clone nodes 68,435,593 -> 42,088,166. Emitter-local operation counts remain exact, localizing the reduction to the removed composition rebuild. This host point records 492.563279 -> 297.920989 seconds wall, 491.72 -> 294.52 seconds user CPU, and sampled reported/peak footprint 299.1M/325.6M -> 296.2M/320.5M; none is a budget, support, memory, capacity, or stable-ratio claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.3.2: reuse accepted balanced composition`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4`
  Status: `done`
  Goal: `Synchronize the independent result and close current-publication evidence for later budget qualification.`
  Acceptance: `After child .1 separates immutable capture revision from current clean execution revision without weakening public single-profile resume, child .2 must re-run the independent verifier and production producer-free validate/inventory from clean state; join their exact identities and counts, retain every falsification and canonicalization conclusion, close the bounded capture claim's missing leg only if earned, synchronize task/book/Knowledge Map/containment/claims, and mark .17.5.2 done without promoting performance budgets, support, or capacity.`
  Verification: `Child .1 preserves public same-revision resume while separating seal-derived capture revision from current clean execution revision through an exact-caller path and coordination schema v2. Child .2 proves the first repaired production validate still retained parent-side validation state across profiles, places each whole ProfileCapture operation in a fresh outer worker without removing nested dual validation, and closes the real immutable corpus from clean execution revision 1da11b2e3. Guarded production validate/inventory, independent census before/after, historical separation, copied mutations, revision/resume and coordinator watchers, canonical bounded outputs, exact identities/counts, empty staging, and cleanup all pass. No recapture, public-resume weakening, guard increase, budget, support, performance, memory, or capacity promotion occurs.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4: own revision-separated closeout`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.1`
  Status: `done`
  Goal: `Separate sealed evidence revision from current execution revision during complete-corpus validation.`
  Acceptance: `Preserve public ProfileCapture capture/resume as exact current-clean-revision operations with all stale-revision controls. For CorpusCoordinator validate only, authenticate the immutable evidence revision from the already complete loaded corpus and pass it through one exact-caller closed ProfileCapture seam; use it solely to admit embedded report/common identity while independently pinning the current clean execution revision before and after every child, parent revalidation, and complete-corpus load. Retain fresh public adapter validation in child and parent, current host/guard/tool checks, plan/policy/report/provider/applicability/artifact identities, producer prohibition, bounded IPC, signal/error handling, and byte-read-only behavior. Expose capture versus execution revision without ambiguity, advancing a schema if the public result shape changes. Prove foreign callers, caller-supplied or malformed revisions, forged corpus/profile revision disagreement, current repository mutation, ordinary stale public resume, and every existing coordinator control reject. Re-run the exact real validate path only after focused synthetic proof; do not recapture, move, relabel, or mutate the sealed publication and do not promote a budget, support, performance, or capacity claim.`
  Verification: `ProfileCapture public capture/resume remain current-clean-revision strict. One exact-CorpusCoordinator-only seam accepts only repository root, ordinal, and the capture revision derived from an already authenticated complete seal; child and parent report validation use that immutable revision while every child, parent reload, complete load, and final comparison pins the separately derived clean execution revision. CorpusCoordinator schema v2 reports both revisions, retains capture revision in common identity, captures zero profiles during validation, and compares the complete corpus before/after. Synthetic two-revision proof admits all eleven sealed profiles and rejects foreign seam callers, public revision injection, malformed seam revision, seal/profile disagreement, complete-load mutation, later execution mutation, and ordinary stale public resume. RAM-guarded adjacent t1768/t1769/t1772/t1773/t1774 passes Files=5, Tests=40 in 59 seconds; t1773 alone passes Files=1, Tests=8 in 29 seconds with sixteen revision-separation assertions. All 59 mdBook chapters test; the inspected repository-local build contains 94 files/21,312,509 bytes and is removed exactly with no off-repository residue. Knowledge Map parity is 1,160 facts/6,251 questions/6,423 occurrences/138 shards; exact claim and disposition joins, maintained-reference authority, containment, staged acceptance, and all doctrines pass. The rationale surface is already rollover debt, so the same durable rationale is retained in this task, book, Knowledge card, claim record, tests, and Git rather than bypassing containment with a redundant decision file. No sealed publication byte, producer, provider, simulator, budget, support, performance, memory, capacity, full CI, or push changes in this repair; child .2 owns the real clean closeout reruns.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.1: separate capture and execution revisions`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2`
  Status: `done`
  Goal: `Close and synchronize the independently authenticated current publication.`
  Acceptance: `After child .1 diagnoses and repairs the guarded aggregate-memory failure without weakening validation, child .2 must re-run the standalone verifier, guarded producer-free production validate, guarded inventory, historical separation verifier, and adjacent exact-publication watchers. Require exact immutable identities/counts, current execution-revision reporting, zero producer/provider/simulator/controller execution, unchanged real-publication census, empty staging, bounded output, and complete cleanup. Join all falsification and canonicalization evidence; synchronize task/book/Knowledge Map/claims/containment/resume pointers; close .17.5.2 only if every leg agrees, without budget, support, performance, memory, or capacity promotion.`
  Verification: `The initial clean a802ec97f run failed at the host guard while preserving every corpus byte; child .1 traced that aggregate lifetime to ProfileCapture's parent-side validation running repeatedly in the long-lived CorpusCoordinator and committed a bounded fresh outer worker per whole profile operation. Child .2 then completed clean guarded production validate from 1da11b2e3 below both unchanged guard boundaries, reproduced the immutable capture revision and all current identities/counts, and independently proved before/after corpus invariance. Guarded inventory, historical separation, copied-mutation and adjacent watchers, canonical bounded output, zero execution, empty staging, exact temporary-output removal, process cleanup, and clean Git all pass. This is a process-lifetime repair and correctness closeout, not a budget, support, performance, memory, or capacity promotion.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2: own guarded validation memory repair`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2.1`
  Status: `done`
  Goal: `Diagnose and repair aggregate-memory failure in complete-corpus validation.`
  Acceptance: `Use the clean failed production run, source call graph, and bounded project-local process sampling or smaller exact controls to distinguish long-lived parent retention from one-profile child demand and unrelated host load. If the coordinator parent is the retained-state owner, execute each whole ProfileCapture operation in a fresh guard-visible coordinator child so ProfileCapture still performs its existing independent child and parent report validations, while the long-lived CorpusCoordinator receives only the existing bounded canonical result. Retain exact-caller revision authority, current clean revision checks around every process/load, closed nonblocking close-on-exec IPC, bounded success/error envelopes, signal/exit/malformed/noncanonical/oversized rejection, post-worker artifact reload, producer prohibition, operation order, and every existing public result/publication identity. Prove fresh process identity and lifetime release by construction, hostile worker controls, exact synthetic result parity, and unchanged synthetic publication bytes. Classify this source repair as process-topology evidence only until child .2, from the required clean committed revision, independently proves real-corpus byte invariance and guarded production validate below both guard boundaries. Do not recapture, republish, weaken public resume or dual validation, increase a guard, or promote a performance, memory, support, or capacity budget.`
  Verification: `The clean a802ec97f production failure, immediate independent reauthentication, and source call graph distinguish retained validator state from corpus corruption: ProfileCapture's inner report-validation child exited per profile, but its independent parent validation ran eleven times in the long-lived CorpusCoordinator. CorpusCoordinator now wraps each entire ProfileCapture operation in a fresh outer process, preserving the nested child plus independent short-lived parent validation; the long-lived coordinator receives only the existing bounded canonical result and still rechecks clean revision, exact result, and published profile afterward. The outer reader is nonblocking and both descriptors are close-on-exec; bounded canonical errors and success metadata cross the pipe. t1773 proves eleven unique outer workers distinct from the coordinator and producer grandchildren, and rejects exception, TERM, zero/nonzero no-result exit, oversized result, malformed JSON, noncanonical JSON, every retained inner-worker failure, and post-worker mutation without sealing. Focused guarded t1773 passes Files=1/Tests=8 in 37 seconds. An adjacent attempt begun under high external pressure was correctly terminated at the 88% host cutoff while an unrelated PGEN rustc was the largest resident process; after that compiler exited, the same exact guarded t1768/t1769/t1772/t1773/t1774 band passed Files=5/Tests=40 in 61 seconds from a 51.9% baseline. All 59 mdBook chapters test; the inspected same-volume render contains 94 files/21,322,531 bytes and is removed exactly. Knowledge Map parity is 1,160 facts/6,252 questions/6,424 occurrences/138 shards; claim inventory/disposition joins 1,819/1,819 with zero gaps/open migrations; maintained-reference authority, task integrity, diff hygiene, staged acceptance, and doctrines pass. No real publication byte, guard, public schema, producer/provider/simulator/controller path, validation count, budget, support, performance, memory, or capacity claim changes; active child .2 owns the clean real-corpus proof.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2.1: isolate profile validation parents`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2.2`
  Status: `done`
  Goal: `Complete final current-publication closeout after the bounded validation repair.`
  Acceptance: `From clean .1, rerun the independent verifier, guarded production validate and inventory, historical separation verifier, adjacent exact-publication watchers, before/after corpus census, and cleanup checks. Join immutable capture and current execution revisions, exact identities/counts/providers, zero producer/provider/simulator/controller execution, bounded output, and all prior falsification/canonicalization evidence; synchronize task/book/Knowledge Map/claims/containment/resume pointers and close .17.5.2 only if every leg agrees. Promote no budget, support, performance, memory, or capacity claim.`
  Verification: `From clean repair commit 1da11b2e3, the standalone verifier passed before and after every production/watcher step with capture revision 155aa22ea, 13 files/6,220,126 bytes, inventory 94c11e5c...bb57, corpus ab2df899...e505, publication 865c5cce...432e, plan fbf69740...9737, policy 19cf4105...ece, file-set dc5b315b...c66f, exact 11/33/44/0 counts, and the seven-foundation/one-materialized/three-external provider partition. Guarded producer-free `--validate` began at 57.1% host occupancy, completed below both unchanged boundaries, and emitted one 16,169-byte canonical newline JSON result (SHA-256 0447cb0a...cd23) reporting capture 155aa22ea, execution 1da11b2e3, zero captured, eleven resumed/validated, and the exact identities/counts. Repeated live snapshots showed fresh outer/inner PID pairs and non-monotonic coordinator RSS; no partial stdout appeared. Guarded `--inventory` emitted 10,567 canonical bytes (SHA-256 73b93594...dd74), reporting eleven present/zero missing and the same seal. The historical verifier separately retained its five-file/604,539-byte archive; guarded t1776+t1777 passed Files=2/Tests=10 in 125 seconds, and guarded t1769+t1773 passed Files=2/Tests=16 in 37 seconds. External PGEN compiler pressure was allowed to finish before the final watchers and did not alter results. All exact temporary captures, mutation fixtures, staging roots, and process trees are absent; Git remains clean. Existing current-corpus and revision-separated claim records remain exact with every re-derive/falsify/durability leg executed. No producer/provider/simulator/controller execution, recapture, republish, guard change, budget, support, performance, memory, or capacity promotion occurred.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.2.5.4.2.2: close current corpus publication`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3`
  Status: `done`
  Goal: `Qualify representative current profiles and freeze exact pinned-host/tool regression budgets.`
  Acceptance: `Consume only the .17.5.2 current publication; independently reproduce complete correctness and repetition evidence; apply the exact decision-0056 wall/CPU/RSS formulas and deterministic count oracles; bind workload, revision, host, tool, guard, provider, and applicability identities; retain recalibration and rollback history; and leave unmatched hosts informational. No budget may derive from historical v1 evidence, failed correctness, excluded samples, or a single slow-run rewrite.`
  Verification: `The completed children derive all eleven current profiles from the authenticated v2 corpus, apply the exact Decision-0056 formulas, seal one immutable two-file qualification from clean publisher 8667f766c, and independently reconstruct every source, correctness, statistic, budget, environment, applicability, profile, qualification, publication, and file-set identity. Same-volume hostile copies reject the complete content/type/formula/identity/path/alias/staging/residue matrix without partial output and restore exactly. Final t1784 joins production validate with the independent result profile-by-profile beneath inode-aware real-artifact censuses; the complete guarded t1779-t1784 band passes at Files=6/Tests=39. Exact-environment later revisions are eligible only after correctness, environment drift is informational, deterministic drift rejects before performance, and recalibration requires separately owned immutable old/new evidence. Publication remains byte-identical and enforcement remains inactive.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3: activate current budget qualification`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1`
  Status: `done`
  Goal: `Derive one authenticated in-memory budget qualification from the current v2 corpus without publishing it.`
  Acceptance: `Accept only the repository root; load and authenticate the complete .17.5.2 corpus; independently reconstruct every accepted run total, aggregate statistic, deterministic count oracle, correctness/repetition/exclusion result, and common/provider/applicability identity; derive each profile's wall/CPU/RSS budget with integer-safe decision-0056 floors, multipliers, and rounding; and return a bounded defensive content-addressed qualification report. Reject caller evidence, historical v1 bytes or budgets, non-current or dirty evidence, failed correctness, exclusions, incomplete/reordered profiles or records, mixed identities, invalid numeric types, overflow, and mutation. Execute no producer, provider, simulator, measurement controller, or publication write.`
  Verification: `Activation audit exposed a prerequisite contract contradiction: decision 0096 required exact common revision identity for later enforcement even though the capture revision necessarily precedes qualification and gate commits. Child .1 repaired applicability semantics without changing a budget. Child .2 now loads only the authenticated current corpus and profile stores, independently validates all 44 accepted records, reconstructs exact non-timing correctness projections, derives three-sample statistics and integer-safe Decision 0056 budgets, and returns one bounded defensive content-addressed in-memory report. No publication or gate is active.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1.1: separate evidence revision from applicability; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1.2: derive current regression budgets`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1.2`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1.1`
  Status: `done`
  Goal: `Repair the performance-applicability identity so a promoted budget can remain enforceable after its own qualification and gate commits.`
  Acceptance: `Reconcile decisions 0056 and 0096 plus the executable policy. Keep the capture Git revision immutable as provenance, but define later performance eligibility from exact host/tool/guard/provider identity and an exact deterministic workload/correctness projection rather than equality with the capture commit. Prove same-behavior later revisions remain eligible, deterministic behavior drift fails correctness rather than borrowing a budget, host/tool/guard/provider drift remains informational, and caller-selected identity cannot weaken the rule. Synchronize decision, policy, tests, mdBook, Knowledge Map, task, and Memory without deriving or publishing any budget.`
  Verification: `Decision 0096's amended contract resolves the contradiction without mutating sealed capture evidence: revision is immutable qualification provenance, while exact host/tool/guard/provider plus selection/workload/correctness-projection identity controls later enforcement. The existing v1 policy derivation remains byte-identical at 19cf4105...5ece; guarded production corpus reload retains capture revision 155aa22ea, all eleven profiles, and the exact seal. The separate closed applicability contract is content-addressed at b5976719...8018, accepts no caller input, returns defensively, and rejects a rehashed revision-as-runtime-dimension control. Matching later revisions are enforcement-eligible only after correctness; deterministic drift rejects before performance; environment drift is informational; unavailable providers do not pass. Syntax and focused t1765 pass; guarded exact t1765+t1766 report All tests successful at Files=2/Tests=19. Decision/book/task/claim evidence and doctrines close in the work-unit commit. No current corpus byte, plan/policy identity, budget, publication, support, performance result, capacity claim, full CI, or push changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1.1: separate evidence revision from applicability`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1.2`
  Status: `done`
  Goal: `Implement the authenticated in-memory budget derivation against the repaired applicability contract.`
  Acceptance: `Satisfy the parent .17.5.3.1 acceptance after .1.1 closes, binding immutable evidence revision separately from the exact deterministic and environment applicability identity used by later gates.`
  Verification: `ArchitectureScaleRegressionPromotionQualification accepts only a repository root below the active RAM guard, invokes the authenticated corpus/profile stores once each, and emits no file. It requires the exact current policy, ordered eleven-profile plan, 11 validations, 33 measured records, 44 total accepted invocations, zero exclusions, clean immutable capture revision, exact common/provider environment, complete oracle/cleanup success, and canonical JSON integer types. For every record it independently verifies stage order, process success, stage count integers, oracle membership/evidence hashes, artifact count/hash rows, and workload/common identity; its bounded correctness projection retains all four records' exact non-timing stage counts, artifact identities, and oracle identities. It reconstructs per-run wall/CPU sums and maximum process-tree RSS, then min/median/max/MAD and the integer-safe Decision 0056 floor/multiplier/ceiling formula. The real corpus derives a 762,664-byte report at d8fb1813...0c97; its eleven per-profile projections are each below 262,144 bytes and its exact first/last budgets are 2,000,000,000/2,000,000,000/268,435,456 and 429,258,000,000/462,510,000,000/4,177,526,784 wall/CPU/RSS units. T1779 proves the closed API, formulas, defensive output, exact projections, and hostile historical/missing/reordered/excluded/failed/mixed/string/unsafe/overflow/rehashed controls. The audit also repairs Policy's JSON-number helper so a rehashed string `"1"` cannot impersonate numeric schema version 1. Focused t1765+t1779 and guarded real derivation pass; broader guarded source/store watchers, book, claims, containment, acceptance, and doctrines close before commit. No artifact, producer, provider, simulator, measurement-controller, publication, gate, support, capacity, full-CI, push, or existing policy/corpus identity changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.1.2: derive current regression budgets`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2`
  Status: `done`
  Goal: `Freeze the authenticated current budget qualification in one bounded versioned atomic publication.`
  Acceptance: `Publish only a .17.5.3.1-accepted report beneath a non-colliding repository-relative same-volume qualification namespace; bind source corpus bytes and identities, formula authority, exact profile budgets, host/tool/guard/provider applicability, deterministic oracles, recalibration predecessor/trigger requirements, rollback, and nonclaims. Use closed canonical schemas, conservative byte ceilings, fsync plus atomic rename, exact reload, and owned cleanup; reject collisions, stale or mixed evidence, historical substitution, malformed/noncanonical/oversized state, file aliases, staging residue, or caller-selected paths and budgets.`
  Verification: `Clean predecessor 8fc4b6e2d supplied the authenticated in-memory qualification but could not safely create immutable evidence from uncommitted publisher code. Child .1 implemented the caller-sealed bounded store, child .2 added the exact publish/validate CLI, and child .3 used their clean commit 8667f766c to atomically create and distinctly reload the real two-file publication. The seal fixes qualification d8fb1813...0c97, report/publication/file-set identities 0da23249...622c / 1c2a3832...945f / 28ba972c...9095, and exact 11/33/44/0 evidence plus all ordered budgets/applicability bindings. Publication does not activate enforcement.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2: partition current budget publication`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.3`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.1`
  Status: `done`
  Goal: `Implement the bounded same-volume current-budget qualification publication store without creating the real publication.`
  Acceptance: `Add one caller-sealed authority that accepts only the repository root, derives and validates the complete .17.5.3.1 qualification internally, records the exact source corpus/file-set/qualification/formula/profile-budget/applicability identities plus predecessor, recalibration trigger, rollback, and nonclaims in closed canonical report/manifest/artifact schemas, and exposes conservative byte ceilings. Fsync files and directories before one non-colliding directory rename; reload through exact census, bounded no-follow reads, owner/device/link/identity checks, digests, canonical JSON, full revalidation, and exact re-derivation. Reject caller evidence, paths, budgets, historical or mixed state, collisions, ambiguous or malformed recovery, oversized/noncanonical bytes, symlink/hard-link/cross-device aliases, post-validation mutation, and staging residue. Synthetic tests execute no real producer, provider, simulator, measurement controller, or publication.`
  Verification: `ArchitectureScaleRegressionPromotionQualificationStore now accepts only a repository root beneath the active RAM guard, requires one clean publisher revision, internally derives and validates the complete current qualification, and fixes a non-colliding v2 report-plus-manifest coordinate. The outer report preserves the exact source qualification without rewriting its derivation-time nonclaims; report and manifest bind publisher/source/formula/profile-budget/environment/provider/applicability/correctness identities plus one closed initial-version/recalibration/rollback contract. The 1-MiB report and 64-KiB manifest ceilings, exact census, bounded no-follow stable reads, owner/device/single-link checks, canonical JSON, digests, fsync, sole-stage recovery, one directory rename, collision refusal, and identity-scoped cleanup are executable. Guarded real in-memory construction rederived qualification d8fb1813...0c97 and produced a 764,010-byte wrapper plus 28,148-byte manifest without writing the real publication. T1780 starts RED on the absent authority, then proves caller sealing, exact schemas, defensive contracts, publication/reload/unchanged status, drift, malformed/noncanonical/cap-plus-one bytes, extra entries, symlink/hard-link aliases, residue, exact/malformed/ambiguous recovery, collision, partial-failure cleanup, and late mutation. Guarded adjacent t1772+t1779+t1780 reports All tests successful at Files=3/Tests=21. No real publication or performance gate exists; .2 owns the CLI and .3 owns clean real publication.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.1: implement current budget publication store`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.2`
  Status: `done`
  Goal: `Expose explicit bounded publish and validate operations for the current-budget qualification store.`
  Acceptance: `Add one repository-relative executable that accepts exactly one explicit publish or validate operation, delegates only to the caller-sealed store under the active guard, emits bounded canonical newline JSON only after complete success, returns stable nonzero failure status with bounded sanitized diagnostics, and rejects defaults, abbreviations, extra arguments, caller paths/evidence/budgets, partial stdout, malformed worker state, or residue. Keep real publication for .3.`
  Verification: `The repository-relative executable derives its root only from its tracked script location and accepts exactly one case-sensitive, unabbreviated --publish or --validate operation; standalone --help is the only non-operation success. It delegates once to the caller-sealed store, validates the store's exact result shape, buffers canonical newline JSON through a 1,048,576-byte ceiling before stdout, and reports usage with status 2 or operational failure with status 1 and one sanitized 4,096-byte diagnostic. T1781 starts RED because the executable is absent, then proves both dispatches with fresh process doubles, exact-cap acceptance, cap-plus-one rejection without partial stdout, malformed state, hostile path/control/oversize diagnostics, closed options/arguments, and exact fixture cleanup. Script/test syntax and t1780+t1781 report All tests successful at Files=2/Tests=11. The real namespace remains absent; no producer, provider, simulator, measurement controller, performance gate, support tier, result, or capacity claim is activated.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.2: add current budget publication CLI`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.3`
  Status: `done`
  Goal: `Create and exactly reload the real current-budget qualification publication from one clean implementation revision.`
  Acceptance: `Run only the completed explicit publish operation from a clean revision under the unchanged RAM guard; authenticate the current corpus and all eleven qualified budgets; publish one bounded non-colliding same-volume namespace; then run a distinct validate operation and exact file census. Record publisher revision, source corpus/file-set/qualification identities, formula authority, ordered profile budgets and applicability identities, publication/file-set identities, byte counts, rollback/recalibration contract, and nonclaims; prove staging and process residue absent. Do not execute a producer, provider, simulator, or measurement controller, and do not activate performance enforcement.`
  Verification: `From clean CLI revision 8667f766c, guarded --publish derived the authenticated current qualification and created exactly two same-volume/current-owner/single-link canonical files by atomic rename: the 764,010-byte report at SHA-256 524fad65...a3fd and 28,148-byte manifest at SHA-256 5eebce24...9c62. They bind publisher 8667f766c, qualification d8fb1813...0c97, source corpus ab2df899...e505, source file set dc5b315b...c66f, Decision 0056, the exact ordered eleven budget/environment/provider/applicability/correctness bindings, report identity 0da23249...622c, publication identity 1c2a3832...945f, and file-set digest 28ba972c...9095. A distinct guarded --validate emitted 793,084 canonical newline JSON bytes at SHA-256 19ac96ed...9d64 and exactly reloaded both stored objects. Independent canonicalization and digest reconstruction reproduced all three content identities; exact census, store/CLI watchers, immutable predecessor/recalibration/rollback/nonclaims, staging/process/temp cleanup, book, claims, and doctrines close before commit. No producer, provider, simulator, measurement controller, recapture, budget change, active gate, support, performance result, or capacity claim occurs.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.2.3: publish current budget qualification`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3`
  Status: `done`
  Goal: `Independently close current budget evidence, hostile admission, identity applicability, recalibration history, and residue.`
  Acceptance: `Re-derive the current corpus and every formula result without trusting the qualification producer; authenticate the published namespace, exact bytes, identities, profile/order/count partition, deterministic oracles, and zero exclusions; prove copied mutations for content, schema, numeric type, formula, budget, host/tool/guard/provider/applicability, stale revision, historical substitution, collision, alias, and residue classes reject. Prove exact common identity is eligible for later performance enforcement while a changed host/tool/provider identity is explicitly informational, and prove recalibration requires separately owned old-versus-new version replacement. Leave publication bytes unchanged and owned staging absent.`
  Verification: `The production-independent verifier reconstructs the exact qualification from the authenticated current corpus; same-volume copied controls reject the full hostile seal and applicability/recalibration matrix with exact restoration; and final t1784 executes both independent and production authorities beneath one inode-aware before/after census, joins every ordered profile identity, verifies exact output and contract evidence, and leaves all staging/process residue absent. The guarded t1779-t1784 band passes at Files=6/Tests=39 in 214 wall-clock seconds. No immutable publication byte or enforcement state changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3: partition independent budget closeout`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.3`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.1`
  Status: `done`
  Goal: `Independently rederive and authenticate the current-budget qualification publication without importing production code.`
  Acceptance: `Add one repository-derived read-only verifier with no FSMGEN production-module import. Independently census and boundedly read the exact two-file namespace; validate closed canonical report, manifest, qualification, formula, summary, source, publication, contract, nonclaim, and ordered profile schemas; reload the authenticated current corpus and every source profile; independently reconstruct exact correctness projections, three-run statistics, Decision-0056 budgets, environment/provider/applicability bindings, and all content/file-set identities. Emit bounded canonical newline JSON only after full success; reject caller input and leave publication/staging bytes unchanged.`
  Verification: `The tracked repository-derived verifier imports no FSMGEN module and exposes no production library path or caller-controlled root, path, evidence, formula, budget, or profile input. It rejects any argument, requires absent qualification staging, and independently authenticates the exact 764,010-byte report plus 28,148-byte manifest, their hashes, canonical schemas, content identities, 28ba972c...9095 file set, publisher 8667f766c, immutable contract, source bindings, counts, order, and nonclaims. It first requires the producer-independent 13-file corpus verifier, then independently reloads every authenticated profile and reconstructs every measurement identity, correctness projection, three-sample statistic, Decision-0056 budget, environment, provider, applicability, profile qualification, whole qualification, outer report, manifest, and both file-set identities. Its canonical result is bounded at 262,144 bytes. T1782 starts RED on the missing executable, then proves no production import/library exposure, exact identity/count/result contract, closed invocation, and before/after byte identity for both real namespaces. Guarded t1776+t1782 reports All tests successful at Files=2/Tests=6; no producer, provider, simulator, measurement controller, publication mutation, gate, support, performance result, or capacity claim occurs.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.1: independently verify current budgets`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.2`
  Status: `done`
  Goal: `Falsify copied publication mutations and close performance-applicability and recalibration boundaries.`
  Acceptance: `Use only same-volume copied fixtures and the independent verifier. Prove exact baseline admission, then reject content, schema, canonicality, numeric type, formula, budget, order/count, host/tool/guard/provider/applicability, publisher/source/stale revision, historical substitution, extra/missing path, symlink/hard-link/special file, collision, staging, and residue mutations with no partial result and exact restoration. Prove exact common identity is eligible for later performance enforcement, environment drift is informational, deterministic drift rejects before performance, and recalibration requires a separately owned old/new immutable version rather than overwrite. Leave the real namespace byte-identical.`
  Verification: `T1783 creates a same-volume copy of the qualification, complete current corpus, and both independent verifiers, then admits the exact baseline. Its complete named mutation matrix changes report/manifest/source content, schema, canonicality, numeric type, formula, budget, order/count, every environment/provider/applicability axis, publisher/source/revision provenance, history, namespace shape, aliases, collision, staging, and residue; every invocation rejects without partial stdout, restores the exact copied census, and the final baseline re-verifies. A separate oracle over the authenticated contract proves later-revision exact identity eligible only after correctness, environment drift informational, deterministic drift rejected before performance, unavailable provider not a pass, and recalibration eligible only as a separately owned immutable new version with distinct old/new evidence. The real qualification and corpus retain exact inode-aware before/after censuses.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.2: falsify current budget qualification`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.3`
  Status: `done`
  Goal: `Close the real current-budget publication from independent and production evidence.`
  Acceptance: `Run the independent verifier and mutation suite, guarded production validate, qualification/store/CLI watchers, exact before/after real-artifact census, identity comparison, and cleanup/process checks. Synchronize task, mdBook, Knowledge Map, claims, containment, and Memory; close .17.5.3 only when every independent and production leg agrees. Leave immutable publication bytes unchanged and do not activate a gate, support tier, performance result, or capacity claim.`
  Verification: `T1784 is a production-independent final join: it imports no FSMGEN module, captures inode-aware qualification and source-corpus censuses, runs the closed independent verifier and guarded production --validate, requires bounded canonical diagnostic-free results, and compares the fixed coordinate, publisher, source, report/publication/qualification/file-set/applicability/formula/count contracts plus every ordered profile's measurements, statistics, budgets, environment, provider, and correctness identities. Production returns the exact 793,084 bytes at SHA-256 19ac96ed...9d64; report and manifest retain one non-overwritable not-activated contract. Both real censuses remain exact, all three owned staging paths and hostile fixtures are absent, and no child process remains. Guarded t1779-t1784 reports All tests successful at Files=6/Tests=39 in 214 wall-clock seconds.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.3.3.3: close current budget qualification`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4`
  Status: `done`
  Goal: `Implement stable architecture-scale regression gates with bounded CI placement and exact host/tool applicability.`
  Acceptance: `Run the .17.5.3-qualified representative profiles through canonical producers and stage-local oracles; enforce frozen performance budgets only on the exact pinned host/tool profile; run correctness, deterministic-output, safety, no-tool/qualified-tool, atomic publication, and cleanup checks everywhere applicable; report unmatched performance informationally; fail closed on evidence or identity drift; and place expensive guarded gates according to the selected CI cadence without making ordinary slice commits run full CI.`
  Verification: `All four children are complete. Decision 0096 and the immutable current corpus/qualification feed the caller-sealed gate contract, fresh isolated execution, correctness-before-performance admission, aggregate coordination, atomic latest-result store, explicit CLI, authenticated evidence transport, and bounded local/hosted CI placement. Child .4 independently closes production execution: clean revision ef59330ab passes all eleven exact-pinned profiles with required/observed 11 validation, 33 raw, and 44 controller records, zero exclusions or residue, and one qualification-distinct canonical result. Synthetic unmatched-host/provider-unavailable routes remain non-pass as designed. No evidence, qualification, budget, support, or capacity boundary changed; `.17.5.5` owns broader public truth publication.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4: partition stable regression gate delivery`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.1`
  Status: `done`
  Goal: `Select and freeze the stable regression-gate execution and applicability contract.`
  Acceptance: `Derive the exact eleven-profile gate plan only from the authenticated current corpus and budget qualification; define fresh canonical-producer execution, stage-local correctness and deterministic oracles, no-tool versus qualified-tool behavior, bounded worker/IPC/guard/output/publication/cleanup rules, and one closed result schema. Performance enforcement must require exact qualified workload, environment, guard, provider, and tool identities after correctness succeeds; unmatched environments remain informational, unavailable required providers remain unavailable rather than pass, deterministic or evidence drift rejects before performance, and caller evidence, historical substitution, budget rewriting, or qualification overwrite is forbidden. Select repository-derived commands and bounded local/hosted cadence without yet wiring CI or activating a performance result.`
  Verification: `The caller-sealed metadata authority authenticates the immutable qualification store, independently derives the current plan, joins all eleven ordered dispatch/evidence/budget bindings, and content-addresses one closed execution/applicability/result/cadence contract. T1785 began RED on the absent module, poisons every producer/controller path, rejects guard/caller/invocant and evidence/applicability/dispatch/budget drift, and proves defensive deterministic output. Its default and exact real-evidence paths both pass at Files=1/Tests=12; the guarded policy/plan/qualification/store/contract band passes at Files=5/Tests=43 in 39 wall-clock seconds. Decision 0097 freezes maximum-per-metric evaluation after correctness, exact-identity enforcement, informational unmatched timing, unavailable-not-pass, no override, one bounded atomically replaceable latest observation, immutable qualification non-aliasing, and focused/full/hosted cadence without executing or wiring the gate.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.1: freeze stable regression gate contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2`
  Status: `done`
  Goal: `Implement the caller-sealed eleven-profile regression gate and its atomic result.`
  Acceptance: `Implement the .1 contract through canonical producers and the common measurement/lifecycle authorities, with fresh isolated profile execution and complete ordered admission. Prove correctness, deterministic outputs, stage-local measurements, exact applicability classification, performance enforcement only for the pinned qualification tuple, informational unmatched performance, unavailable-provider handling, bounded canonical diagnostics/results, signal/error/collision/recovery controls, immutable qualification input, atomic result publication, and exact same-volume cleanup. Add focused hostile watchers for mutation, stale or mixed identity, caller substitution, reordered/missing/extra profiles, threshold boundaries, tool/provider drift, timeouts, IPC failures, and residue without changing qualification bytes or generalizing support/capacity.`
  Verification: `Clean contract predecessor cc1cd18ac separates four implementation fault domains: one fresh profile worker and classifier, eleven-profile ordered coordination and aggregate admission, replaceable latest-result storage, and the explicit public CLI. All four children are complete. Their caller-sealed path requires fresh isolated canonical execution, correctness-before-performance, exact applicability, bounded aggregate admission, qualification-distinct same-volume atomic publication/recovery, producer-free reload, and explicit no-default run/validate command selection. T1786-t1789 jointly falsify caller, evidence, order, threshold, provider, worker, IPC, filesystem, recovery, mutation, output, error, and residue attacks without running a real gate workload; .17.5.4.4 retains that real closeout.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2: partition stable regression gate implementation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.4`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.1`
  Status: `done`
  Goal: `Execute and classify one qualified gate profile through a fresh bounded worker.`
  Acceptance: `Add one caller-sealed profile authority that accepts only repository_root plus ordinal, derives the exact gate contract internally, requires the active guard and unchanged clean execution revision, and invokes the selected canonical adapter once in a fresh child for one validation plus three raw measurements. Revalidate the closed bounded canonical report in the parent; require exact selection/workload/correctness projection before timing; derive provider and host/tool/guard applicability without caller override; reduce each fresh metric by maximum; classify exact-environment budgets at inclusive pass/fail boundaries, unmatched timing as informational, and unavailable exact providers as unavailable rather than pass. Return one bounded defensive profile result with exact evidence identities and sanitized failure; reject caller evidence, stale/mixed identity, reordered records, numeric strings, malformed/oversized IPC, timeout/exception/exit/signal, producer/report mutation, and residue. Default tests use deterministic synthetic adapter reports and run no real provider or simulator.`
  Verification: `ArchitectureScaleRegressionPromotionGateProfile accepts only repository_root plus numeric ordinal, derives the authenticated contract internally, requires the active guard and unchanged clean revision, and runs exactly one selected canonical adapter in a fresh process group. One immediately unlinked same-volume spool carries the complete report outside the 65,536-byte metadata pipe; child and parent independently validate the report, exact qualification selection/workload/correctness bindings, provider/environment applicability, maximum metric reduction, classification, content identity, bounds, and cleanup. Qualification exposes only an exact-caller observation seam that reuses its existing measurement/oracle/statistic authorities; ProcessSupervisor admits only the gate authority's bounded provider-version preflight. T1786 began RED on the absent module, then covers exact-threshold pass, adjacent fail, informational mismatch, unavailable-not-pass, available/missing/drifted provider preflight, correctness-before-timing, caller/guard/type/order/revision/mutation rejection, exception/exit/signal/timeout/IPC/report ceilings, and residue with deterministic synthetic reports. Exact preflight separately reports qualified Verilator, GHDL, and OSVVM/GHDL providers available without running a gate workload. No result is published and no qualification byte changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.1: execute one stable gate profile`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.2`
  Status: `done`
  Goal: `Coordinate all eleven fresh profile workers and admit one complete in-memory gate result.`
  Acceptance: `Add one repository_root-only coordinator that derives the contract once, walks every ordinal exactly once in plan order, delegates only through .1's exact-caller worker seam, and admits the eleven returned profile results under one unchanged clean execution revision. Require complete qualification/contract/file-set identity, 11 validations, 33 fresh raw measurements, 44 controller invocations, zero exclusions, exact correctness and deterministic evidence, ordered per-profile performance classifications, and aggregate fail/unavailable/informational/pass precedence without publishing. Content-address one closed bounded canonical aggregate; reject missing/extra/duplicate/reordered profiles, mixed contract/qualification/revision/environment/provider state, threshold or classification forgery, malformed/oversized worker output, child failure, repository mutation, post-worker evidence mutation, and residue. Default tests remain synthetic and producer-free outside the sealed worker double.`
  Verification: `ArchitectureScaleRegressionPromotionGateCoordinator accepts only repository_root, requires the exact class and active guard, derives the authenticated contract once, snapshots its bytes, and walks ordinals 1-11 once in contract order under one unchanged clean revision. GateProfile now exposes exact-coordinator-only execution and readmission seams while its public root-plus-ordinal API remains unchanged. Every full result is size-bounded, readmitted through the profile validator, snapshotted against later alias mutation, required to preserve exact contract/qualification/file-set/revision/order/content identities and common observed host/guard state, then readmitted again from the completed aggregate. The closed content-addressed result distinguishes fixed required 11/33/44 workload from honest observed counts when an exact provider is unavailable, admits zero exclusions, applies fail/unavailable/informational/pass precedence, and writes no artifact. T1787 began RED on the absent module and uses a synthetic sealed-worker double to prove one derivation, exact order/cardinality, complete pass, all precedence cases, defensive output, and missing/extra/duplicate/reordered/mixed/forged/malformed/oversized/failure/mutation/residue rejection without executing a producer.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.2: coordinate stable gate profiles in memory`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.3`
  Status: `done`
  Goal: `Publish and reload one bounded atomically replaceable latest gate observation.`
  Acceptance: `Implement the fixed result coordinate and same-volume staging from Decision 0097. Accept a complete .2 result only through the exact coordinator path, independently rederive the current contract and validate every aggregate/profile/result identity, encode at or below the 1,048,576-byte ceiling, fsync the file and directories, and atomically replace current only after exact reload. Preserve a preceding valid result on interruption; recover at most one identity-scoped stage; leave staging absent after success/failure/reload; never read a prior result as qualification, calibration, budget, applicability, or execution input. Reject caller-selected paths/results, qualification/result aliasing, stale/mixed evidence, malformed/noncanonical/oversized bytes, collision or ambiguous recovery, symlink/hard-link/cross-device/special-file state, post-validation mutation, and cleanup residue.`
  Verification: `ArchitectureScaleRegressionPromotionGateStore exposes exact-class repository_root-only publish and producer-free load operations under the active guard. It independently derives the current contract, accepts new or reloaded aggregates only through Coordinator's exact-store validator, binds contract/qualification/publication/file-set/execution identities, encodes canonical newline JSON at or below 1,048,576 bytes, and never accepts caller evidence or coordinates. Publication runs the coordinator before reading any prior target, writes one mode-0600 current-owner/one-link same-device content-addressed stage, fsyncs file and directories, reopens and re-admits exact bytes, checks unchanged target/stage identities, and atomically renames over the fixed qualification-distinct latest-result path. A pre-rename failure preserves the exact prior result; one exact current-revision stage recovers without producer execution; successful, failed, recovered, unchanged, and loaded controls leave staging absent. T1788 began RED on the absent module and covers first/unchanged/replaced/recovered results, producer-free load, direct-seam rejection, caller injection, interruption, invalid/ambiguous/digest-mismatched stages, mixed/stale evidence, coordinate aliasing, noncanonical/cap-plus-one data, symlink/hardlink/FIFO/wrong-device identity, post-validation mutation, and cleanup. T1787 additionally proves the real store-to-coordinator admission path for one complete aggregate. No real producer, provider, simulator, gate workload, or qualification mutation runs.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.3: replace latest gate result atomically`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.4`
  Status: `done`
  Goal: `Close the explicit gate CLI and adversarial implementation contract before CI placement.`
  Acceptance: `Add one repository-relative executable with explicit --run and producer-free --validate-result operations, no default expensive execution, no abbreviation/case folding, bounded canonical stdout, stable nonzero failure, and sanitized bounded diagnostics. Exercise the complete public path with deterministic adapters and same-volume copied fixtures; falsify caller substitution, qualification/result aliasing, stale/mixed/reordered/missing/extra evidence, exact and adjacent budget thresholds, host/tool/guard/provider drift, unavailable providers, malformed/noncanonical/cap-plus-one IPC/result/error, timeout/exception/exit/signal, interruption/recovery/collision, file aliases, target/staging mutation, repository mutation, and process/filesystem residue. Synchronize runnable mdBook, Knowledge Map, claims, containment, task, and Memory evidence; leave full real producer execution and CI wiring to `.17.5.4.4` and `.17.5.4.3` respectively.`
  Verification: `The executable repository-relative runner derives its root only from its tracked location and accepts exactly one case-sensitive, unabbreviated --run or producer-free --validate-result operation, with no default. Run publishes then reloads; validate only loads. Both re-admit the exact store envelope/artifact and coordinator result field sets before buffering canonical newline JSON at or below 1,048,576 bytes. Pre-output operational failure returns status 1 with empty stdout and one sanitized diagnostic at or below 4,096 bytes; closed usage returns status 2. T1789 began RED on the absent runner and uses copied fresh-process public store fixtures to cover exact dispatch/root derivation, malformed shapes, limit drift, exact-cap/cap-plus-one output, hostile errors, and cleanup. The complete guarded t1786-t1789 band reports All tests successful at Files=4/Tests=114 in eight wall-clock seconds and retains the full worker, aggregate, store, interruption, recovery, provider, threshold, mutation, and residue matrix without real execution. The runnable mdBook, compact Knowledge card, third claim shard, complete candidate dispositions, containment authority, task/Memory frontier, and doctrine gates close in the same slice.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.2.4: add explicit stable gate CLI`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3`
  Status: `done`
  Goal: `Place the expensive guarded regression gate in bounded local and hosted CI cadence.`
  Acceptance: `Expose exact repository-relative pre-push/selected-important-step and hosted entrypoints around the .2 gate. Keep ordinary slice commits on focused checks, preserve the unsharded local full gate, give hosted execution explicit shard/provider/tool ownership, and require hosted nonmatching environments to run applicable correctness/determinism/safety/publication/cleanup checks while reporting performance informationally. Update CI inventory and workflow documentation so every tracked test remains exactly owned, no matrix tail is hidden, full CI remains reserved for push or selected important steps, and unavailable providers cannot yield a passing performance classification.`
  Verification: `Fresh-checkout audit found that the complete gate could not run in hosted CI: all 15 authenticated corpus/qualification files were beneath ignored .artifacts, git ls-files supplied none, and the exact local census was 7,012,284 bytes. Three completed children now provide the durable non-recalibrating transport and provider selection, authenticated materialization plus selected/unsharded-local driver entrypoints, and one required hosted family with exact provider preflight, guarded canonical-result validation, aggregate ownership, and bounded cleanup. Decision 0098, t1183, t1790-t1792, workflow inventory, mdBook, Knowledge Map, and claim record retain the closed cadence without a real gate run or broader claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3: partition evidence-backed CI placement`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.1`
  Status: `done`
  Goal: `Select a durable current-evidence transport and exact hosted provider contract.`
  Acceptance: `Prove the evidence/files a fresh checkout lacks, their exact current census and identities, and why source-only regeneration, cross-run cache, ambient tools, or caller-supplied evidence cannot authenticate the immutable qualification. Select one bounded repository-owned transport/materialization lifecycle that reproduces the exact fixed corpus and qualification coordinates without recalibration, overwrite, history substitution, or aliasing. Freeze hosted provider ownership: exact structural OSVVM materialization, absent exact runtime providers as unavailable-not-pass, all other available correctness paths, informational unmatched performance, one guarded job, atomic result/cleanup, and no public support/capacity promotion. Record the choice in a decision, task, Knowledge Map, and mdBook before implementation.`
  Verification: `Decision 0098 records the fresh-checkout blocker and closes the transport/provider selection before code. The exact ignored source is 13 corpus plus two qualification files and 7,012,284 bytes; independent verification reproduces corpus/file-set ab2df899...e505/dc5b315b...c66f and qualification/file-set d8fb1813...0c97/28ba972c...9095, while git ls-files returns none. The selected version-1 repository source keeps all fifteen canonical JSON payloads byte-identical under vial/qualification/regression_promotion_gate/evidence-v1 with one closed ordered manifest, 8-MiB payload and 32-KiB manifest transport ceilings, and fixed no-overwrite generated destinations. Materialization will validate/stage both roots, install corpus before qualification as commit point, recover only the exact transaction, and clean only owned paths. Hosted ownership is one guarded Ubuntu 24.04 seventh family: exact OSVVM 2026.05 is materialized, ambient Verilator and fixed GHDL artifacts must be absent, ordinals 1-7/11 execute with informational timing, and exact-runtime ordinals 8-10 produce unavailable rather than pass, for honest 8/24/32 observed versus 11/33/44 required topology. Source regeneration, caches/run artifacts, forced .artifacts tracking, application archives, substitute tools, and caller evidence are rejected. The mdBook and compact existing Knowledge card carry the same choice; the claim record explicitly names the not-yet-tracked payload/materializer durability gap owned by .2. No evidence copy, code, workflow, gate execution, result, support, or capacity changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.1: select authenticated hosted gate evidence`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2`
  Status: `done`
  Goal: `Implement authenticated evidence materialization and bounded local CI gate entrypoints.`
  Acceptance: `Implement the .1-selected repository-owned evidence transport and fail-closed materializer with exact file census/bytes/digests, safe relative paths, no aliases, same-volume atomic destination, immutable-source validation, collision/interruption/recovery/cleanup controls, and byte-exact production load after materialization. Add an explicit selected-important-step driver mode and include the guarded gate exactly once in the unsharded local full pre-push path while quick/smoke/isf and ordinary test execution remain focused. Add hostile tests without running the real gate by default.`
  Verification: `Decision 0098 closes transport/lifecycle selection. Three completed children provide the immutable fifteen-file bundle and producer-independent source watcher, fixed-coordinate transactional materialization/recovery/owned cleanup, and local selected/full driver placement with inventory coverage. Child .1 closes the tracked authenticated source at transport 3b4c486e...2bbc6. Child .2 materializes that exact source through fixed nonblocking-lock, same-volume journal/stage, corpus-first/qualification-last commit, recovery, receipt, and owned-cleanup controls. Child .3 adds the explicit vial-gate mode and one post-regression unsharded full invocation through the same materialize/two-validator/RAM-guarded-run/cleanup lifecycle; all hosted shards and focused modes remain gate-free.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2: partition evidence materialization and local CI`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.1`
  Status: `done`
  Goal: `Import and independently authenticate the immutable current-evidence transport bundle.`
  Acceptance: `Track the exact thirteen corpus and two qualification canonical JSON payloads under Decision 0098's version-1 source root without changing a byte. Add one closed canonical transport manifest with ordered safe source/destination paths, classifications, per-file bytes/digests, exact aggregate census, source seal identities, bounded schema, and content identity. Add a repository-derived production-independent verifier and focused RED/GREEN plus copied hostile tests for manifest/payload schema, order, path, file-set, canonicality, bytes, digest, alias, extra/missing, source-seal, and deterministic identity drift. The verifier must write nothing, accept no caller source/evidence/root, leave generated coordinates untouched, and keep materialization/CI separately owned.`
  Verification: `The version-1 bundle tracks the exact fifteen canonical payloads byte-for-byte at 7,012,284 bytes. Its 8,725-byte manifest binds transport 3b4c486e...2bbc6, manifest SHA-256 d20cae85...94f7, ordered fixed paths/classifications/bytes/digests, and corpus/qualification file sets dc5b315b...c66f/28ba972c...9095. The repository-derived verifier emits deterministic canonical verification ae9c67c9...55b6, imports no production module, accepts no caller evidence, writes nothing, and independently re-derives both source content seals. T1790 began RED at line 18 on the absent verifier, then its copied fixture rejects closed-schema/order/path/byte/digest/identity/source-seal/canonicality/payload-schema/extra/missing/symlink/hardlink/FIFO/caller mutation and restores the exact result; focused prove reports All tests successful, Files=1, Tests=4. Generated corpus and qualification coordinates remain byte-identical. Materialization and CI remain separately owned.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.1: authenticate immutable gate evidence`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.2`
  Status: `done`
  Goal: `Implement transactional fixed-coordinate evidence materialization and owned cleanup.`
  Acceptance: `Build the root-derived explicit materializer around .1's authenticated source. Use one nonblocking process lock, identity-scoped same-volume stage and journal, corpus-first/qualification-last commit, exact-existing idempotence, mismatch no-overwrite, bounded canonical result/diagnostic output, recovery of only the one valid transaction, and a receipt that lets cleanup remove only invocation-owned exact roots. Falsify caller input, concurrent collision, interruption at every install boundary, malformed/stale/mixed journal/receipt/stage, links/aliases/special files, source/destination mutation, partial output, and residue; prove byte-exact production corpus and qualification validation after fresh materialization.`
  Verification: `The root-derived executable accepts only materialize or cleanup, locks the authenticated tracked manifest with one nonblocking exclusive read-only file lock, and accepts no caller root/source/destination/identity/receipt/overwrite coordinate. It reuses the producer-independent transport verifier, rechecks stable ordinary single-link source bytes while copying, and stages the exact 15-file/7,012,284-byte payload under bundle-identity state on the repository volume. One canonical prepared journal and pending receipt survive corpus-first then qualification-last atomic root installation; the committed receipt distinguishes two invocation-created roots from exact pre-existing evidence with zero owned roots. Existing exact evidence is idempotent, mismatches never overwrite, and cleanup validates source, receipt, complete destination trees, device/owner/link identity, byte counts, digests, and closed census before removing qualification then corpus. T1791 began RED at line 18 on the missing materializer. Its copied fresh-checkout matrix passes under the RAM guard at Files=1/Tests=9 in 200 wallclock seconds, drives every journal/install/receipt interruption boundary into exact recovery, passes both production corpus and qualification validators after each recovery, and rejects caller input, lock collision, source/destination drift, partial/mixed/stale/noncanonical journal/receipt/stage state, extra/missing files, symlinks, hardlinks, FIFO nodes, unsafe cleanup, partial output, and residue. The version-retrievable acceptance-history pointer rolls to exact predecessor 7e7dc8158 without changing a ceiling or losing prior evidence. Local/hosted CI and real gate execution remain unchanged; child .3 is active.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.2: materialize authenticated gate evidence`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.3`
  Status: `done`
  Goal: `Add bounded local selected-important-step and full pre-push gate entrypoints.`
  Acceptance: `Extend bin/ci-regression with one explicit selected gate mode and one exact gate invocation in unsharded local full after ordinary regression, both using the common RAM guard and authenticated materializer. Full preserves byte-exact preexisting evidence and the latest local observation; a fresh materialized run cleans only owned evidence after validation. Quick, smoke, ISF, direct test, and every hosted shard option remain gate-free. Extend t1183 or one focused inventory watcher to prove exact command count/order, no double execution, closed options, failure propagation, and unchanged hosted test ownership without running the real gate by default.`
  Verification: `The local driver now accepts exact case-sensitive vial-gate as a selected-important-step mode and runs the same five-step lifecycle once after ordinary regression on only the unsharded full path. Authenticated materialization precedes both production evidence validators; the gate runs once beneath the common RAM guard; receipt cleanup runs once after every successful materialization and preserves adopted exact evidence plus the qualification-distinct latest observation. Primary failures remain primary, simultaneous cleanup failure is diagnosed, and cleanup-only failure propagates. Quick, smoke, ISF, direct tests, and all four existing hosted shard families remain gate-free. T1183 began RED at line 389 because vial-gate was unknown and full selected zero gate commands. Its copied five-stub fault matrix exercises success plus materializer, both validator, guard, gate, and cleanup failures without a real workload; the guarded GREEN run reports All tests successful, Files=1, Tests=16 in 38 wallclock seconds with no copied residue.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.2.3: place the guarded gate in local CI`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.3`
  Status: `done`
  Goal: `Wire and close the hosted regression-gate job, inventory, and cadence documentation.`
  Acceptance: `Add one explicit guarded hosted job that materializes the authenticated current evidence and exact OSVVM 2026.05 provider, leaves exact Verilator/GHDL runtime providers absent rather than drifted, executes the gate through the .2 public command, validates canonical result/qualification identities and unavailable-not-pass plus informational-host outcomes, and cleans materialized evidence/provider/result staging. Extend the final aggregate, workflow action/tool/provider inventory, and focused CI watcher so the seventh family cannot be skipped and every tracked t/*.t still has exactly one ordinary/dedicated/corpus/dynamic owner. Synchronize workflow README, mdBook, Knowledge Map, claims, containment, task, and Memory without running full CI or claiming hosted performance/support/capacity.`
  Verification: `The regression workflow now has one unsharded Ubuntu-24.04/Perl-5.32 VIAL gate family in addition to doctrine, book, ordinary, dedicated, corpus, and dynamic families; terminal build consumes all seven results. The job installs no HDL runtime package, rejects ambient Verilator and both fixed GHDL coordinates, recursively materializes exact OSVVM 2026.05 at 2f7c391051dfb11890fa4bdbda9918d1db492250, and invokes the .2-owned ./bin/ci-regression vial-gate --no-book public command. A guarded argument-free production-independent verifier authenticates the fixed canonical latest-result path, aggregate/profile content identities, exact qualification d8fb1813...0c97/publication 1c2a3832...945f/file-set 28ba972c...9095 references, unavailable aggregate, informational ordinals 1-7/11, unavailable-not-pass ordinals 8-10, required 11/33/44 and observed 8/24/32 topology. Always-cleanup re-enters receipt-bounded evidence cleanup, removes only the preflight-proved OSVVM/result/stage coordinates, and asserts the selected census absent. T1183 began RED at line 841 on the absent hosted job; its extended workflow/action/test-owner inventory plus new copied-result t1792 pass guarded at Files=2/Tests=21 in 40 wallclock seconds. T1792 alone passes Files=1/Tests=5 and rejects rehashed qualification/topology/classification drift, content/canonical/caller/guard/staging attacks without a producer. Workflow YAML parses, all action uses remain immutable, every tracked t/*.t retains exactly one ordinary/dedicated/corpus/dynamic owner, and no real gate, full CI, hosted observation, performance, support, or capacity claim ran in this slice.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.3.3: wire the hosted regression gate`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4`
  Status: `done`
  Goal: `Independently close the real regression gate, applicability, CI ownership, and residue.`
  Acceptance: `From clean committed implementation and CI placement, independently authenticate the immutable qualification, execute production gate entrypoints in exact pinned and safely simulated unmatched/provider-unavailable classifications, and join every profile, correctness, determinism, measurement, budget, applicability, result-publication, CI-inventory, and cleanup identity. Re-run focused hostile watchers plus the warranted bounded regression band; prove qualification/result non-aliasing, no historical substitution or recalibration, exact before/after censuses, zero staging/process residue, and synchronized task/book/Knowledge Map/claims/containment/Memory before closing .17.5.4. Promote no broader support or capacity claim.`
  Verification: `Children .1 and .2 diagnose all three real-gate false rejections, seal Decision 0099's exact process-telemetry boundary, and independently close the repaired production path. From clean ef59330ab, the public gate authenticates the fixed corpus and qualification, passes all eleven exact-environment profiles and budgets, publishes canonical result c7787a02...02f2, and leaves eleven removed spools with no process or staging residue. Independent JSON/identity joins, simulated unmatched/provider-unavailable production routes, and the 12-file/194-test closeout band agree. No recalibration, historical substitution, support promotion, or capacity claim occurs.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4: partition failed real gate closeout`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.1`
  Status: `done`
  Goal: `Diagnose and repair the exact ordinal-10 regression-gate correctness drift without recalibration.`
  Acceptance: `From the clean reproducible ordinal-10 failure, independently capture its current deterministic correctness projection and compare every field with the immutable qualified projection. Locate the first causal producer/oracle divergence, distinguish product regression from an unstable or wrongly scoped correctness field using current authorities and history, and make the smallest signoff-quality repair under the existing qualification semantics. Add a focused RED/GREEN watcher for the exact cause and diagnostic coordinate; preserve all qualification/corpus bytes and identities, provider admission, workload shape, budgets, atomic no-result-on-failure behavior, and zero stage/process residue.`
  Verification: `The clean public gate reproducibly failed only at ordinal 10; an independently isolated ordinal-11 run passed correctness and all three exact budgets. A production projection comparator re-executed ordinal 10 and found equal 165,285-byte fresh/qualified envelopes with raw identities aedd15cc...3010/c41a8f10...74b3 and exactly 116 scalar differences: 29 in each of four records, partitioned as eleven lifecycle-artifact digests, six lifecycle-evidence byte sizes, six lifecycle-oracle evidence identities, and six stage output-byte totals. Inspection traced all four derived sets to fresh monotonic/process timings inside lifecycle evidence; every semantic workload/source/provider/result/status/count field agreed, and history from capture 155aa22ea through HEAD showed no corresponding producer drift. Decision 0099 keeps raw identity as the normal path, authenticates both full projections only after mismatch, and applies one fail-closed exact-schema OSVVM-runtime normalization while retaining every other field. T1793 began RED at line 13 on the absent comparator, then proves the exact 4 x 29 partition, all ten non-target profiles raw-exact, defensive input, and rejection of semantic count, missing/new artifact, duplicate oracle, and invalid-shape drift. T1786 proves stable-only integration, immutable qualified result identity, adjacent semantic rejection with ordinal/selection coordinates, and both caller-sealed seams. The guarded qualification/gate band passes All tests successful at Files=7/Tests=151; the focused pair passes Files=2/Tests=27. Qualification/corpus bytes, identities, workloads, budgets, provider/environment admission, atomic failure behavior, and existing residue are unchanged. Clean real-gate and complete residue closeout remain child .2.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.1: stabilize ordinal-10 correctness admission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2`
  Status: `done`
  Goal: `Complete independent real gate, applicability, CI-ownership, and residue closeout after repairing each exact correctness-admission defect exposed by clean production execution.`
  Acceptance: `Diagnose and repair the clean public gate's exact ordinal-8 correctness rejection without recalibrating immutable evidence, then rerun and independently authenticate the complete exact-pinned result. Exercise production entrypoints in safely simulated unmatched-host and provider-unavailable classifications without changing the host or immutable evidence; join every profile, correctness, determinism, measurement, budget, applicability, publication, non-aliasing, CI-inventory, and cleanup identity. Re-run focused hostile watchers plus the warranted bounded regression band; prove no historical substitution or recalibration, exact before/after censuses, zero staging/process residue, and synchronized task/book/Knowledge Map/claims/containment/Memory before closing .17.5.4, without broader support or capacity claims.`
  Verification: `Children .1 and .2 repair the exact ordinal-8 and ordinal-9 process-telemetry-derived correctness false rejections without changing evidence or qualification, then close the clean public gate. The accepted result c7787a02...02f2 joins all eleven qualified selections and budgets at exact-host pass with complete 11/33/44 topology, zero exclusions, eleven removed spools, and no process/staging residue. Production simulations retain informational unmatched-host and unavailable-not-pass behavior; focused hostile and bounded regression watchers pass.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2: partition ordinal-8 correctness repair`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.1`
  Status: `done`
  Goal: `Diagnose and repair the exact ordinal-8 regression-gate correctness drift without recalibration.`
  Acceptance: `From the clean reproducible ordinal-8 failure, independently compare every field in a fresh canonical portable-Verilator projection with the immutable qualified projection. Trace each of the exact 96 changed leaves to its first causal producer field; distinguish semantic regression from unstable or wrongly scoped correctness data using current authorities and history; then make the smallest fail-closed signoff repair under Decision 0099's raw-first, authenticated-full-projection semantics. Add focused RED/GREEN coverage for the exact schema, profile, stages, kinds, counts, order, uniqueness, and diagnostic coordinate; reject adjacent semantic and hostile topology changes; preserve qualification/corpus bytes and identities, workload shape, budgets, provider/environment admission, publication atomicity, and zero stage/process residue.`
  Verification: `The clean public gate failed ordinal 8 before publication, and an isolated canonical rerun compared equal 77,952-byte full projections at b95c62f1...47cb8/30e1110e...32a2 with exactly 96 differences, partitioned 4 x 24. Source tracing locates the first cause at VerilatorLifecycle::_capture_evidence: eight fresh ProcessSupervisor monotonic/duration values enter compile state evidence, which the portable adapter transitively copies through compile/run/trace/result/publish evidence and the first four handles; emit precedes capture and stays exact. Diffing capture revision 155aa22ea through HEAD finds no relevant adapter/lifecycle change and only GateProfile caller authorization in ProcessSupervisor. T1793's portable case began RED at line 324 with stable equality plus missing/new/duplicate controls failing; t1786 independently aborted at GateProfile.pm line 465 before timing. Decision 0099 now drives one exact table for OSVVM and portable schemas. Portable normalization admits only five evidence sizes/digests, four handle digests, five oracle identities, and five stage-byte totals per record; scalar/digest shapes and topology fail closed, the other nine profiles stay raw-exact, and successful admission retains the qualified identity. Focused GREEN reports All tests successful at Files=2, Tests=29. The guarded qualification/gate band reports All tests successful at Files=7, Tests=153. Production-independent verifiers reproduce the exact 13-file/6,220,126-byte corpus and 2-file/792,158-byte qualification; the regenerated claim inventory and dispositions close 1,887/1,887 candidates with zero open owners; all 58 SUMMARY chapters test and build, and the disposable render is removed. Workloads, budgets, providers, environment, publication, and cleanup are unchanged; child .2 owns clean production closeout.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.1: stabilize ordinal-8 correctness admission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2`
  Status: `done`
  Goal: `Complete independent real gate, applicability, CI-ownership, and residue closeout after all observed correctness-admission repairs.`
  Acceptance: `From the clean committed ordinal-8 repair, rerun the public exact-pinned gate and independently authenticate its complete result. Exercise production entrypoints in safely simulated unmatched-host and provider-unavailable classifications without changing the host or immutable evidence; join every profile, correctness, determinism, measurement, budget, applicability, publication, non-aliasing, CI-inventory, and cleanup identity. Re-run focused hostile watchers plus the warranted bounded regression band; prove no historical substitution or recalibration, exact before/after censuses, zero staging/process residue, and synchronized task/book/Knowledge Map/claims/containment/Memory before closing .17.5.4, without broader support or capacity claims.`
  Verification: `Child .1 repairs ordinal 9's exact telemetry-derived correctness boundary without recalibration. Child .2 then completes the clean public path: all eleven profiles pass the frozen exact environment and budgets; the canonical latest result is independently joined to the immutable corpus, qualification, contract, per-profile correctness, measurements, applicability, topology, publication, and cleanup identities. Simulated unmatched-host and unavailable-provider routes remain honest non-pass classifications, and the complete focused band passes with zero process/staging residue.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2: partition ordinal-9 correctness repair`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2.1`
  Status: `done`
  Goal: `Diagnose and repair the exact ordinal-9 regression-gate correctness drift without recalibration.`
  Acceptance: `From the clean reproducible ordinal-9 failure, independently capture a fresh canonical portable-VHDL/GHDL correctness projection and compare every field with the immutable qualified projection. Locate every changed leaf and its first causal producer; distinguish semantic regression from unstable or wrongly scoped correctness data using current authorities and history; then make the smallest fail-closed signoff repair under Decision 0099's raw-first, authenticated-full-projection semantics. Add focused RED/GREEN coverage for the exact schema, profile, stages, kinds, counts, order, uniqueness, digest/scalar shapes, and diagnostic coordinate; reject adjacent semantic and hostile topology changes; preserve qualification/corpus bytes and identities, workload shape, budgets, provider/environment admission, publication atomicity, and zero stage/process residue.`
  Verification: `The clean public gate failed ordinal 9 before publication. An isolated canonical rerun compared equal 81,709-byte full projections at bc278bd0...004c/4cce3bf9...42e2 with exactly 116 differences, partitioned 4 x 29: six lifecycle-evidence byte sizes/digests, five lifecycle-handle digests, six oracle evidence identities, and six stage output-byte totals per record. Source tracing locates the first cause at GHDLLifecycle::_capture_evidence: fresh ProcessSupervisor monotonic/duration fields enter lifecycle stage evidence, which ArchitectureScalePortableVHDLRuntimeMeasurement transitively copies through compile/elaborate/run/trace/result/publish evidence and the first five handles; emit precedes capture and stays exact. Diffing capture revision 155aa22ea through HEAD finds no portable-VHDL adapter/lifecycle change and only GateProfile caller authorization in ProcessSupervisor. T1793's exact ordinal-9 case began RED at line 490 with seven intended stable/topology/shape failures. Decision 0099's exact table now admits portable-VHDL/GHDL, including its distinct publish evidence kind, while retaining raw-first comparison, authenticated full projections, immutable qualified identity, and fail-closed topology. T1786 proves stable-only integration and adjacent semantic rejection. Focused GREEN reports All tests successful at Files=2, Tests=31; the corrected guarded qualification/gate band reports Files=7, Tests=155. Independent verifiers reproduce the exact 13-file/6,220,126-byte corpus and 2-file/792,158-byte qualification with unchanged identities. Result, gate/transport staging, measurement staging, and child-process residue are absent. Workloads, evidence, qualification, budgets, providers, environment, publication, and cleanup are unchanged; child .2.2 owns complete production closeout.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2.1: stabilize ordinal-9 correctness admission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2.2`
  Status: `done`
  Goal: `Complete independent real gate, applicability, CI-ownership, and residue closeout after the ordinal-9 repair.`
  Acceptance: `From the clean committed ordinal-9 repair, rerun and independently authenticate the complete exact-pinned public result; safely exercise unmatched-host and provider-unavailable classifications; join every profile, correctness, measurement, budget, applicability, publication, non-aliasing, CI-inventory, and cleanup identity; then close the active regression-gate activity with exact censuses and zero residue.`
  Verification: `From clean ordinal-9 repair ef59330ab, `./bin/ci-regression vial-gate --no-book` re-authenticated and adopted the exact 13-file/6,220,126-byte current corpus and 2-file/792,158-byte qualification, then completed all eleven profiles. The canonical mode-0600 one-link 60,097-byte result has file SHA-256 f04fac65...72f4 and gate identity c7787a02...02f2; it binds execution ef59330ab, contract 0150f4b3...e368, qualification d8fb1813...0c97, publication 1c2a3832...945f, and file set 28ba972c...9095. Aggregate and every profile are accepted/pass: required and observed topology is 11 validations/33 raw measurements/44 controller invocations, with zero failed, informational, unavailable, or excluded profiles. A production-module-free JSON::PP/Digest::SHA join rederived canonical file and aggregate/profile identities; exact qualification, selection, workload, correctness, environment, provider, measurement, budget, report, and publication joins; ordinals 1-11; 11 unique validations/reports and 33 unique raw identities; per-profile 1/3/4 topology; all metrics at or below frozen budgets; and zero residue. Producer-free `--validate-result` independently reloaded the publication. T1786+t1787 safely simulate unmatched host and unavailable provider plus aggregate precedence at Files=2/Tests=20. The guarded CI/qualification/gate/materialization/hosted-verifier/correctness band passes `Files=12, Tests=194` in 272 wall-clock seconds. Final census finds eleven spools removed, no worker/gate/GHDL/Verilator process, no evidence receipt or `.artifacts/tmp/vial-scale` tree, and the qualification-distinct latest observation intact; evidence and budgets were neither rewritten nor recalibrated. Synchronized task/book/decision/Knowledge Map/claim/containment/Memory and doctrine checks close `.17.5.4` without broader support or capacity claims.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.4.4.2.2.2: close exact regression gate`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5`
  Status: `done`
  Goal: `Publish exact architecture-scale commands, envelopes, variability policy, support/capability truth, and nonclaims.`
  Acceptance: `Synchronize the mdBook, support/capability surfaces, Knowledge Map, task tree, and bounded resume pointer from executable gate and publication identities. Document runnable repository-relative commands, selected workload and host/tool envelopes, deterministic versus performance checks, unmatched-host behavior, recalibration, cleanup/residue, and exact supported claims. Preserve whole-product big/really-big, multi-unit/domain, mixed-language, native-UVM-runtime, full-language, synthesis, arbitrary-tool-capacity, and general-parity nonclaims.`
  Verification: `Both publication children are complete. Public VIAL JSON/API and the complete manifest expose one artifact-independent eleven-profile contract whose profile, budget, evidence, topology, environment, provider, applicability, result, cleanup, cadence, supported-scope, and nonclaim fields join tracked or executable authorities. The README stays a bounded signpost, while the mdBook publishes the exact operator commands, all eleven workload/provider/budget envelopes, pinned host/tool/guard tuple, correctness-first and environment/provider outcome rules, separately owned recalibration, atomic latest-observation lifecycle, residue rules, bounded claim, and every required nonclaim. Machine and human surfaces remain claim-verified, Knowledge-mapped, containment-authorized, and support/capacity neutral.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5: partition public scale truth`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.1`
  Status: `done`
  Goal: `Publish one bounded machine-readable VIAL architecture-scale regression capability contract.`
  Acceptance: `Add a closed support contract to public VIAL capabilities and the complete capability manifest that identifies the shipped gate command, schemas and immutable qualification bindings, eleven selected profile coordinates, 11/33/44 topology, qualified budget envelopes, exact deterministic and environment applicability fields, fixed guard/provider requirements, atomic latest-result coordinate, cadence, cleanup, and supported regression claim. Cross-check every field against tracked evidence and executable gate authorities without requiring ignored generated artifacts at discovery time. Replace the ambiguous scale nonclaim only at this aggregate capability boundary with explicit architecture-scale-capacity, whole-product big/really-big, multi-unit/domain, mixed-language, native-UVM-runtime, full-language, synthesis, arbitrary-tool-capacity, support-promotion, and general-parity nonclaims. Preserve all source/runtime fixture support classifications and their narrower scale nonclaims.`
  Verification: `The pure argument-free FSM::Support::VIALArchitectureScaleRegressionContract now publishes one closed defensive tracked snapshot through the VIAL capability API, fsmgen vial capabilities --json, and the complete capability manifest. Its eleven ordered rows exactly join every selection/workload/correctness/environment/provider/budget field to the authenticated transport and immutable qualification; topology is exact 11/33/44/0; host, guard, OSVVM, Verilator, GHDL, applicability, cadence, latest-result, cleanup, supported bounded-gate scope, and precise nonclaims join their distinct executable authorities. Discovery reads no ignored evidence or replaceable result. The first T1794 run proved the owner absent; a subsequent public JSON probe exposed and drove repair of the filtered CLI record. Final public JSON reports capability vial.architecture_scale.regression_gate.v1, eleven profiles, and 44 controller invocations. Five modules compile; the impacted capability/language-surface/gate band reports All tests successful at Files=8, Tests=37, with only the existing opt-in Darwin runtime integration skipped. mdBook tests pass; the repository-local HTML build contains 94 files before exact removal, and fresh maintained-reference authority owns its exact 34-line/2,959-byte aggregate delta without raising a ceiling. Knowledge Map generation/check passes at 1,160 facts; claim verification closes 52 records and inventory/dispositions close 1,891/1,891 candidates with no gap. The optional rationale ledger remains unchanged because the root live-document surface is at its line ceiling; the same rationale is durable in this task, the book, Knowledge card, tests, and Git. Existing VIAL fixture support entries retain their narrower scale nonclaim, and no gate execution, evidence, budget, support classification, runtime behavior, human CLI publication, or capacity claim changed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.1: publish scale regression capability`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.2`
  Status: `done`
  Goal: `Publish exact human-facing architecture-scale commands, envelopes, variability policy, cleanup, supported claim, and nonclaims.`
  Acceptance: `From the completed machine-readable contract, synchronize README signposting, the mdBook, Knowledge Map, claim registry, task tree, and bounded resume pointer. Give runnable repository-relative dry-run, selected-gate, full-pre-push, producer-free validation, and evidence-verification commands; tabulate all eleven selected workload/provider/budget envelopes and the pinned host/tool/guard tuple; explain correctness-first deterministic rejection, exact-host inclusive performance enforcement, unmatched-host informational behavior, unavailable-provider non-pass behavior, separately owned recalibration, atomic latest observation, and exact cleanup/residue. State only the supported bounded regression-gate claim and preserve every whole-product, capacity, multi-unit/domain, mixed-language, native-UVM-runtime, full-language, synthesis, arbitrary-tool, support-promotion, and general-parity nonclaim.`
  Verification: `Historical grep proves the completed machine publication had no human "Run the bounded gate" section. The README now links the bounded dry-run command while remaining 240 lines/9,930 bytes under its strict ceiling. The mdBook publishes six runnable repository-relative commands, the exact five-step dry-run transaction, pinned host/guard and four-provider table, all eleven exact selection/provider/budget rows, fixed 11/33/44/0 topology, correctness-first applicability outcomes, separate recalibration, atomic capped result, receipt-owned cleanup, bounded supported claim, and all fourteen precise nonclaims. An independent parser compares every published row to public VIAL JSON exactly; the repaired escaped-pipe table renders with six columns, and the repository-local build contains 94 files before exact removal. T1555/T1794 pass All tests successful at Files=2/Tests=10; dry-run, independent tracked-evidence verification, and producer-free validation of accepted result c7787a02...02f2 all pass. mdBook tests pass; Knowledge Map closes at 1,160 facts/6,284 unique questions; claim inventory/dispositions close 1,908/1,908 candidates with zero gaps; fresh maintained-reference authority owns the 118-line/7,017-byte book delta without raising a ceiling. No command, gate, evidence, budget, applicability, runtime, support classification, or capacity boundary changed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.2: publish human scale regression guide`
- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6`
  Status: `done`
  Goal: `Independently close architecture-scale regression, evidence, public truth, and residue before completing .17.5.`
  Acceptance: `Re-derive the complete selected profile/gate/evidence/budget/support partition from current producers and publications; prove exact pinned-host enforcement, unmatched-host informational behavior, deterministic oracles, qualified tools, graceful boundaries, atomicity, same-volume cleanup, documentation commands, capability truth, and zero unowned residue. Reject missing, extra, stale, historical-substituted, reordered, mutated, mixed-identity, or caller-supplied evidence; then close .17.5 without generalizing to whole-product capacity.`
  Verification: `Clean predecessor b4b93d181 completes machine-readable and human public scale truth with exact eleven-profile envelopes, runnable lifecycle commands, applicability, cleanup, supported scope, and nonclaims. Query-first review resolves the canonical regression-promotion capture card and decisions 0096-0099. The audit finds existing machine/evidence/qualification/gate oracles complete, but no durable cross-surface watcher joins both public machine entrypoints to the new human guide or proves its documented dry run side-effect free. Child .1 owns that watcher and hostile projection cases; child .2 owns clean exact execution, the complete independent hostile band, final public/evidence/result/residue joins, and parent closeout. This partition changes no gate, evidence, budget, result, CI, support, or capacity behavior.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6: activate independent scale regression closeout`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6.2`
  Closure: `Both children are complete. T1795 permanently joins the two public machine entrypoints to the human guide and proves dry-run non-mutation. The final leaf executes the clean exact gate, validates it without producers, authenticates both evidence stores independently, reconstructs every public/result/evidence identity and count, runs all policy-through-public hostile oracles, and proves unchanged evidence plus atomic and residue-free publication.`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6.1`
  Status: `done`
  Goal: `Make public machine and human architecture-scale regression truth one independently watched contract.`
  Acceptance: `Invoke the public VIAL JSON and complete capability-manifest entrypoints and require one exact nested regression contract. Treat that contract as the sole source for all eleven human workload/provider/budget rows, pinned host/guard/providers, result coordinate, topology, applicability, commands, supported scope, and nonclaims. Execute the documented dry run and prove it neither creates nor mutates the latest result. Reject missing or reordered rows, mixed providers, changed budgets or hosts, and capacity-nonclaim inversion without requiring generated evidence or a prior result.`
  Verification: `T1795 invokes both public machine commands in fresh children and requires byte-semantic equality of the nested contract. It joins the README signpost and mdBook commands, all eleven escaped selection keys, providers, exact wall/CPU/RSS budgets, host/guard/provider tokens, 11/33/44/0 topology, applicability, result, recalibration, cleanup, scope, and nonclaims to public JSON. The real documented dry run returns its five ordered steps on stdout, stays quiet on stderr, and preserves the absent or existing latest-result bytes. Six in-memory mutations prove missing/reordered profiles, provider mixing, budget drift, host drift, and capacity-claim inversion reject. The initial watcher runs exposed and corrected command-continuation normalization and an exact combined-provider version omission; the rendered table remains well formed. Focused public capability/closeout regression reports All tests successful at Files=3/Tests=18. No gate execution, evidence, budget, result, CI, support, or capacity behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6.1: lock public scale regression closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6.2`
  Status: `done`
  Goal: `Execute and independently close the exact scale regression gate, hostile evidence band, public truth, and residue.`
  Acceptance: `From the clean committed public watcher, run the selected exact gate and producer-free validation; run the complete regression-promotion policy, capture, corpus, qualification, gate, transport, materialization, hosted-outcome, correctness-stability, capability, and public-closeout oracle band. Independently join the published result to immutable evidence, exact profiles/budgets/applicability, both public machine entrypoints, the human guide, and CI selection; exercise pinned-host pass, unmatched-host informational, unavailable-provider non-pass, and every named hostile evidence class; prove qualification/evidence immutability, atomic latest-result publication, same-volume cleanup, and zero unowned process/staging/receipt residue; then synchronize durable surfaces and close `.17.5.6` and `.17.5` without promoting support or capacity.`
  Verification: `From clean execution revision 840c895f3, the real public vial-gate command completed PASS with gate identity f4b022fa4302ccb944eccf84a179b74c4ef66ad9b83ce72afd947f5bae7f5f97, exact qualification d8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97, all eleven profiles accepted, 11 validation records, 33 raw records, 44 controller invocations, and zero failed, informational, unavailable, or excluded profiles. Its canonical 60,100-byte result has SHA-256 d9d8788c12e7929b588694c7b65bf7854a61a2dbf88fe0cdec9669c503954729 and replaced the prior inode atomically. Producer-free validation, independent transport/corpus/qualification verifiers, and a production-module-free JSON::PP/Digest::SHA join all pass; the latter proves exact profile/result/report/validation/raw-record uniqueness, budgets, evidence/public identities, and semantic equality of both machine entrypoints. The complete guarded policy-through-public band reports All tests successful at Files=33/Tests=332 in 763 wallclock seconds, including pinned pass, unmatched informational, unavailable-provider non-pass, every hostile evidence mutation, CI placement, transport/materialization, hosted outcome, correctness stability, capability, and public closeout. All 15 evidence files retain their pre-run hashes; eleven report spools were removed; process, staging, and adopted-receipt censuses are empty. No executable, evidence, budget, CI, support, capacity, or whole-product claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.6.2: close scale regression promotion`

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
  Status: `done`
  Goal: `Complete user documentation, runnable examples, migration guidance, backend/parity matrix, and architecture closeout.`
  Acceptance: `The mdBook fully documents shipped .vial/bridge/plan/tool/backend/result behavior with runnable examples and honest profile limits; public contracts, capability/support accounting, migration from observe and inert skeletons, AHB example, diagnostics, scale evidence, Knowledge Map, roadmap, task index, bounded Memory, retired-changelog non-reference, and all exact regression/doctrine gates agree before the tree closes.`
  Verification: `Clean predecessor 35d06790a activated this bounded documentation activity. Children .18.1-.18.6 selected and published the stable reader entry, public lifecycle, runnable checked-AHB tutorial, explicit legacy migration guide, and exact capability/support/parity/scale/troubleshooting reference with machine-derived hostile-mutation watchers. Final child .18.7 independently executes every selected reader command and example route, closes the remaining stale activation-era narration, proves links, schemas, results, compatibility states, profile/nonclaim boundaries, parity and scale evidence, containment, and exact residue absence, and leaves R14's directional roadmap outcome aligned without duplicating task status. All seven children are done; public/product behavior and unsupported-profile boundaries remain unchanged.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18: activate documentation and migration closeout; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.7: close documentation and migration activity`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.7`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.1`
  Status: `done`
  Goal: `Audit and select the exact user-documentation, runnable-example, migration, matrix, containment, and closeout work.`
  Acceptance: `Query durable knowledge first, then compare README/SUMMARY, the HIAL/VIAL backlog and shipped chapters, public contracts and capability JSON, runnable source/CLI/gallery routes, legacy observe/UVM/VHDL skeleton surfaces, diagnostics, support matrices, parity, scale, Knowledge Cards, roadmap/task/Memory truth, and retired-document non-reference. Publish one closed retain/merge/repair/supersede matrix with exact owners, examples, tests, claims, containment strategy, rollback, and nonclaims before changing user documentation or behavior.`
  Verification: `Clean activation commit deb88d961 owns the audit. The required Knowledge Map query returned no documentation/migration architecture answer, so the audit inspected README/SUMMARY, all eight HIAL/VIAL book chapters, five root contracts plus the architecture audit, both public capability entrypoints, checked AHB/legacy sources, galleries, regression/support tests, roadmap/task/Memory roles, Knowledge Cards, retired-document references, and live-document containment. The selection-time census is 9,636 HIAL/VIAL book lines and 5,912 root-contract/audit lines; the 4,610-line core chapter mixes stable behavior with chronology, while the 336-line backlog duplicates one .15.7 sentence and calls .15 active after all seven children completed. History and child evidence confirm every .15 acceptance item, so this audit closes that stale parent with an explicit nonclaim boundary. The public manifest independently distinguishes shipped public portable-Verilator execution/result/selected AHB parity, private qualified VHDL/GHDL and OSVVM profiles, native-UVM review-only emission plus an unqualified experiment, unavailable mixed-language/native-UVM runtime, and explicit scale-capacity/support nonclaims. Closed disposition matrix: README is retained with navigation-only repair by .18.2; SUMMARY is repaired and grouped by .18.2; 14e is superseded as shipped chronology and retained as future-only backlog by .18.2; 16d is merged/compacted to stable architecture and current boundaries by .18.2; 16da-16df retain exact specialist evidence with stale-introduction/navigation repair by .18.6; the five root contracts retain normative schemas while .18.3 labels selection-time history and routes mutable status to capabilities; the architecture audit remains historical rationale with a current-guide route from .18.2; both capability entrypoints remain machine authority and .18.6 derives the human matrix from them; the checked AHB pair and galleries remain canonical examples consumed by .18.4 rather than copied; observe/UVM-1.2/VHDL-skeleton/handwritten-oracle surfaces remain unchanged and .18.5 maps retain/parallel-successor/migrate states; .18.3 owns lifecycle diagnostics while .18.6 owns compact support/parity/scale navigation; the existing HIAL/VIAL Knowledge Card gains this reader route rather than adding a rollover-debt member; roadmap remains directional, tasks own status/evidence, Memory remains a pointer, and .18.7 closes alignment; retired documents retain zero live consumers. The reader path is a bounded overview plus selected 16dg lifecycle, 16dh tutorial, 16di migration, and 16dj capability/support chapters. Tests t1796-t1800 are reserved in owner order for entry path, lifecycle, tutorial, migration, and capability/support derivation; .18.7 uses existing independent closeout gates. Exact measurements stay in specialist claim blocks, no containment ceiling or rollover allowance increases, and rollback is work-unit-local Git reversion. The committed live-document baseline independently reports 59 shipped-behavior files, 56,745 lines, 3,108,574 bytes, and the 4,610-line largest part. This task selection, compacted existing card, Memory, generated indexes, relative paths, claims, containment, and doctrines close before commit. No book prose, public contract, command, source, artifact, schema, capability, support, runtime, parity, scale evidence, or product behavior changes in selection.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.1: select task-oriented HIAL/VIAL documentation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.2`
  Status: `done`
  Goal: `Make the mdBook entry path distinguish shipped HIAL/VIAL behavior, qualified profiles, unavailable profiles, and future work without progress-ledger drift.`
  Acceptance: `Implement the .18.1-selected SUMMARY, backlog, overview, and chapter-boundary changes; give a bounded learning path and stable reference routing; remove or historical-label stale implementation narration; preserve exact semantics, links, claims, and containment without hiding unsupported or proposed capabilities.`
  Verification: `Clean activation 0505b8257 owns the selected repair. README now routes directly to the HIAL/VIAL overview while shrinking from 9,930 to 9,914 bytes beneath its unchanged ceiling; SUMMARY stays at 60 lines, labels the backlog as future, and nests all six specialist evidence chapters beneath Start Here. The former 336-line progress ledger is replaced by a 57-line future-only backlog with exact capability-family acceptance and nonclaims. The architecture opening replaces contradictory implementation chronology—including the stale .15-active statement—with one stable five-class availability table, recommended reader path, specialist routing, and compatibility boundaries; all later deep architecture and quantitative evidence remain intact. New t1796 derives public, private-VHDL, native-UVM, experimental, mixed-language, and scale-capacity boundaries from the three machine contracts, checks README/SUMMARY/backlog/overview routing, and rejects removal of every availability class. Historical quantitative duplicates removed from the backlog retire exactly 13 joined dispositions while preserving their canonical producer/oracle evidence elsewhere; regenerated inventory and independent census agree at 1,896 candidates, and dispositions close 1,896/1,896 with zero gaps. Standalone t1796 passes Files=1/Tests=4; the guarded capability/scale/entry-path band passes Files=5/Tests=28. mdbook test covers every chapter and the repository-local HTML build succeeds; the exact 22-MiB build tree and empty test-temp root are removed. The new maintained-reference authority records the exact 59-file/56,452-line/3,089,735-byte result from a 0/-293/-18,839 change and raises no ceiling. Knowledge Map, claims, containment, relative paths, task integrity, staged acceptance, and all doctrines pass. No command, source language, schema, artifact contract, capability, support, runtime, parity, capacity, containment authority, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.2: repair HIAL/VIAL reader entry path`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.3`
  Status: `done`
  Goal: `Publish one exact public VIAL source-to-result lifecycle reference.`
  Acceptance: `Document normal/terse source equivalence; capabilities/check/format/plan/run CLI and portable API; accepted HIAL review routes; semantic/bridge/plan/tool/output/result schemas; virtual and atomic artifacts; diagnostics, collision/failure cleanup, and repository-local paths. Every command is runnable and watched against public machine truth; private IR or backend plumbing is never presented as API.`
  Verification: `Clean activation 9e5576814 owns the lifecycle slice. The mandatory Knowledge Map query had no direct source-to-result answer, and history traced the normative public contract to d34da3254 plus the duplicated architecture-section chronology to dfe87f536. New selected 16dg is one task-oriented source-to-result reference covering machine discovery, all five commands, normal/terse equivalence, all three HIAL review routes, the closed portable request/result API, semantic/bridge/plan/tool/output/result boundaries, virtual and atomic repository artifacts, exact diagnostic vocabulary, collision/failure cleanup, relative same-volume paths, precise run-provider conditions, and nonclaims. The 4,596-line architecture chapter replaces its duplicate workflow with a stable route and falls to 4,459 lines; SUMMARY nests the selected chapter. New t1797 derives actions/styles/schemas/diagnostics from the tooling, bridge, and execution machine contracts; executes capabilities/check/both formats, virtual planning, and atomic repository planning; proves IAL2-through-reparsed-IAL1 review, deterministic unchanged replay, collision/traversal preservation, private-object/path non-leakage, unsupported-run atomicity, exact cleanup, independent runtime-gate linkage, and hostile documentation mutations. Standalone t1797 passes Files=1/Tests=6; the guarded source/planning/emission/runtime-reference/entry/lifecycle band passes Files=6/Tests=30, with the full runtime integration intentionally skipped under its Darwin qualification guard. Every mdBook chapter tests and the repository-local HTML build succeeds; exact build/test roots and watcher artifacts are absent after cleanup. The public-tooling Knowledge Card routes the lifecycle and Knowledge Map closes at 1,160 facts/6,294 questions/6,466 occurrences/138 shards. Claim inventory and dispositions close 1,895/1,895 with zero gaps after retiring the one deleted chronology candidate. The maintained-reference authority records 60 files/56,638 lines/3,097,262 bytes from a +1/+186/+7,527 change, no ceiling rises, and the largest chapter shrinks. No public command, API, source language, schema, artifact, diagnostic, capability, support, runtime, parity, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.3: publish public VIAL lifecycle reference`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.4`
  Status: `done`
  Goal: `Publish a runnable end-to-end AHB HIAL/VIAL tutorial and exact backend/parity walkthrough.`
  Acceptance: `Start from the checked AHB HIAL and .vial sources; run check, normal/terse formatting, plan, supported portable-SystemVerilog execution, and the selected VHDL/OSVVM inspection or qualification routes; explain generated review artifacts, logical time, typed probes, normalized result, the exact bounded parity oracle, expected diagnostics, cleanup, and unavailable paths. Tests execute or byte-check every promised command/output without widening support.`
  Verification: `Clean activation commit b262887e4 owns the slice. Required Knowledge Map queries found the separate public-runtime, handwritten-parity, portable-VHDL, and OSVVM authorities but no direct checked-source tutorial; history traces those families to dfe87f536, c95160d53, ab8b1af24, and 4f350f29c. Selected 16dh now starts from ppif/ahb_lite_subordinate.ppif and vial/ahb_subordinate_base_output_arbitration.vial; gives runnable check, normal/terse format, plan, capabilities, and public portable-SystemVerilog run commands with exact outputs; explains the IAL2-to-generated-IAL1-to-IAL0 review tree, logical drive/sample/react/check time, typed HREADYOUT/HRESP/HRDATA plus probe/reg_data_q observations, atomic artifacts, success and unsupported-size results, the exact nineteen handwritten-oracle paths, and distinct provider-free VHDL and OSVVM inspection/qualification routes; and names unsupported native-UVM/mixed-language paths, stable diagnostics, and cleanup without widening support. T1798 executes the public source/planning paths, exact tree and deterministic replay, binds runtime/result/parity truth to t1558/t1559 and FSM::VIAL::Parity::AHBBaseOutput, byte-checks both VHDL galleries and reports, executes the unavailable backend failure, proves residue absence, and rejects six hostile documentation families. Standalone t1798 passes Files=1/Tests=6; the entry/lifecycle/tutorial band passes Files=3/Tests=16; and the guarded eleven-file source/planning/emission/runtime/parity/VHDL/OSVVM/documentation band passes Files=11/Tests=64, with only the pre-existing exact-provider qualification guards skipped. Both gallery refresh checks pass, every mdBook chapter tests, and the repository-local HTML build succeeds before exact removal. Claim inventory/dispositions close 1,895/1,895 with zero gaps. The Knowledge Card was compacted after the first size gate exposed a 145-byte ratchet excess; final Knowledge Map closes at 1,160 facts/6,294 questions/6,466 occurrences/138 shards, containment accepts 61 book files/57,015 lines/3,111,988 bytes from an authorized +1/+377/+14,726 change, no ceiling or allowance rises, and all scratch/build/runtime residues are absent. Final staged acceptance and doctrines own commit closure. No source language, command, schema, backend, runtime, parity, capability, support, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.4: publish runnable AHB tutorial`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.5`
  Status: `done`
  Goal: `Publish explicit migration guidance from legacy observation skeletons and handwritten fixtures to VIAL.`
  Acceptance: `Map IAL1 observe metadata, legacy UVM 1.2 passive-monitor output, the inert VHDL observation package, and the handwritten AHB harness to retain/parallel-successor/migrate states. Give source and command examples, compatibility guarantees, manifest/schema boundaries, typed bridge/probe replacements, rollback, and precise compile/runtime/parity nonclaims; do not silently deprecate or reinterpret legacy output.`
  Verification: `Clean activation commit 4ca781693 owns the slice. Required Knowledge Map queries found no direct migration answer, while history traces observation selection to f3fa55646, UVM 1.2 output to d867815f3, VHDL observation output to ab06754e7, and handwritten AHB parity to c95160d53. Selected 16di defines exact retain/parallel-successor/migrate states: IAL1 observe remains HIAL schedule/bridge metadata; UVM 1.2 and inert VHDL outputs remain stable beside native-UVM and portable-VHDL/OSVVM successors; the handwritten AHB harness remains the bounded qualification oracle while checked .vial becomes the authoring path. It gives runnable legacy and VIAL commands, artifact/schema/bridge/probe boundaries, side-by-side rollout, rollback, exact cleanup roots, and compile/runtime/parity nonclaims without deprecation or reinterpretation. T1799 derives the legacy capability manifest, executes both retained generators and the typed VIAL plan, proves artifact trees and source preservation, checks the unsupported public native-UVM run atomically, runs all three successor galleries, joins the exact t1559 parity outcomes, and rejects hostile documentation mutations. Standalone t1799 passes Files=1/Tests=5; the guarded legacy/reader band passes Files=7/Tests=28; and the guarded full HIAL/VIAL contract/backend/documentation band passes Files=18/Tests=103, with only the two pre-existing Darwin runtime qualification guards skipped. Every mdBook chapter tests, the repository-local HTML build succeeds before exact removal, and all three gallery checks pass. Claim inventory/dispositions close 1,895/1,895 with zero gaps. The Knowledge Card was compacted after containment exposed a 34-byte ratchet excess; the final Knowledge Map has 1,160 facts/6,294 questions/6,466 occurrences/138 shards. Containment accepts 62 book files/57,345 lines/3,125,843 bytes under the authorized +1/+330/+13,855 delta, with no ceiling or allowance rise. Final staged acceptance and all 12 registered doctrine checks are green. No legacy byte, public command, source, schema, manifest, backend, runtime, parity, capability, support, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.5: publish VIAL migration guidance`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.6`
  Status: `done`
  Goal: `Consolidate backend, capability, parity, scale, and troubleshooting truth into bounded navigable references.`
  Acceptance: `Derive one exact profile matrix for portable SystemVerilog, native UVM emission/experiment/qualified runtime, provider-free VHDL, OSVVM, and mixed-language availability; align capability/support stages, parity scope, regression-scale evidence, provider setup, error interpretation, and residue cleanup with public JSON and current evidence. Link specialist measurements instead of duplicating them, preserve all nonclaims, and raise no documentation ceiling without separate authority.`
  Verification: `Clean activation commit 5ab976934 owns the slice. Required Knowledge Map queries found no direct consolidated backend/capability/parity/scale/troubleshooting answer; history traces public tooling to c95160d53, native-UVM matrix truth to 7725789a4, qualified VHDL truth to 895ea33bd, and scale-regression capability truth to 2d16175c4. Selected 16dj derives an exact seven-row public/private/review/experimental/unavailable matrix from the public capability JSON and private contracts; separates seven support-accounting stages from public availability; preserves compile/runtime/result/parity and scale-capacity nonclaims; gives provider-bound UVM behavior, galleries, diagnostics, decision routes, and exact cleanup. T1800 derives those profiles, support rows, diagnostic codes, gallery/provider/scale behavior, and cleanup coordinates from machine authorities and rejects hostile prose mutations. Standalone t1800 passes Files=1/Tests=5; the reader band passes Files=5/Tests=26; and the guarded full HIAL/VIAL contract/backend/scale/documentation band passes Files=19/Tests=7,189, with only two explicit Darwin runtime qualification guards skipped. Every mdBook chapter tests, the repository-local HTML build succeeds before exact removal, and three gallery checks pass. Knowledge Map is current at 1,160 facts/6,295 questions/6,467 occurrences/138 shards; claim dispositions close 1,895/1,895 with zero gaps. Containment accepts 63 book files/57,616 lines/3,141,413 bytes under the authorized +1/+271/+15,570 delta, with no ceiling or allowance rise. Final staged acceptance and all 12 registered doctrine checks are green. No command, source, schema, artifact, backend, runtime, parity, scale, capability, support, diagnostic, provider, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.6: publish VIAL capability reference`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.7`
  Status: `done`
  Goal: `Independently close documentation, runnable examples, migration, public truth, containment, and architecture continuity.`
  Acceptance: `Re-derive every user-visible command, schema, example result, migration state, profile capability, support/nonclaim, parity boundary, and scale statement from independent executable or tracked authorities. Run all promised examples and focused regressions plus mdBook, claims, Knowledge Map, relative-path, task, containment, and doctrine gates; prove no stale progress wording, broken link, generated book, staging, log, or receipt residue; synchronize roadmap/task/Memory and close .18.`
  Verification: `Clean activation commit 2927d94cf owns the independent closeout. The required Knowledge Map query returned no direct closeout answer. A verbose five-file reader suite independently executes capabilities/check/normal-and-terse-format/plan/run behavior, retained legacy generators, all three galleries, provider-absent experimental-UVM handling, scale dry-run, exact cleanup, and hostile controls at Files=5/Tests=26. A direct reader-path search then found six stale activation-era progress phrases in deep 16d prose; history traces them to 125e4981e, f6b2f8504, 02768a427, 4ee0dc12a, and 897c72532. The strengthened t1796 began RED at its machine/human availability join, then completed-state wording and a six-phrase negative oracle made it green at Files=1/Tests=4. Every selected local Markdown destination and linked anchor resolves. The final guarded 19-file machine/backend/UVM/VHDL/OSVVM/scale/reader band passes Files=19/Tests=7,189, with only two explicit Darwin runtime qualification guards skipped. Every mdBook chapter tests; the HTML build succeeds and its exact repository-local 98-file/22,032-KiB tree is removed. Claim inventory remains 1,895 candidates and dispositions close 1,895/1,895 with zero gaps; Knowledge Map remains current at 1,160 facts/6,295 questions/6,467 occurrences/138 shards. Containment authority records 63 book files/57,619 lines/3,141,463 bytes from a 0/+3/+50 wording-only delta with no ceiling increase. Exact manual/build/staging roots, Rust-target .bin/.log census, Git status, and watcher cleanup show no residue. R14 already states the directional HIAL/VIAL outcome and exact frontier ownership, so no roadmap prose change is needed. Final staged acceptance and all 12 registered doctrine checks are green. No command, source, schema, artifact, backend, runtime, parity, scale, capability, support, diagnostic, provider, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.18.7: close documentation and migration activity`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19`
  Status: `active`
  Goal: `Select and decompose the post-first-backend expressive VIAL frontier without a synthesizability ceiling.`
  Acceptance: `Decision 0034 is converted into detailed task-tree leaves for terse/normal syntax equivalence and the complete selected verification-intent taxonomy: notification/interception, lifecycle control, stimulus orchestration, producer/observer communication, implementation selection/substitution, scoped configuration, register intent, constrained decisions, coverage/properties, timed interface interaction, debugging/introspection, and later justified intent families. Each records semantic compression, native/portable SV/UVM/VHDL mappings, backend-private mechanisms (including factories/config DB/TLM plumbing), fail-closed profiles, tests, docs, and non-claims; each applies the author test that no SV/UVM/VHDL knowledge is required and the backend test that generated artifacts remain efficient, readable, and source-mapped, without cloning raw target syntax or allowing the initial portable/native slices to masquerade as the language ceiling.`
  Verification: `Clean activation commit 48b600a5b owns the selection. The required Knowledge Map query returned no direct taxonomy/decomposition answer, so the audit inspected decision 0034, the closed v1 source/SemanticIR contract, bridge and ExecutionIR contracts, public tooling/capability truth, portable-SystemVerilog and VHDL/OSVVM routes, the private native-UVM contract/emitter/gallery, and the complete architecture taxonomy. Because v1 fixes an exact closed grammar, projection, semantic record, diagnostic, and compatibility boundary while the native-UVM breadth is explicitly private preview rather than public semantics/runtime, the selector preserves v1 and chooses additive v2 growth through vertical intent families. Fourteen active activity containers and 85 proposed executable leaves now cover the common version/profile foundation; lifecycle; notification/interception; timed interaction; transactions/scenarios/stimulus; producer/observer communication/models/scoreboards; implementation substitution; scoped configuration; register intent; constrained decisions; coverage/properties; faults; results/diagnostics/debugging/introspection; and cross-family composition, parity, scale, documentation, later-family admission, and closeout. Every family has target-free source, typed compiler, portable-SystemVerilog, native-UVM, VHDL/OSVVM, and qualification/documentation lanes; the foundation has seven exact compatibility/infrastructure lanes. Task integrity proves 1,205 nodes. A first separate-ADR draft correctly tripped the rationale and Knowledge-Card transition allowances; the duplicate was removed, the refinement was folded into decision 0034 without changing its 113-line size, and the card was compacted to 139 lines before containment passed. Focused relative-path, containment, claim-inventory/disposition, reader-entry, and capability-reference tests pass at Files=6/Tests=40. Every mdBook chapter tests; the repository-local HTML build succeeds with 98 files/22,040 KiB and is removed exactly. Claim inventory remains 1,895 candidates and dispositions close 1,895/1,895 with zero gaps. Knowledge Map remains current at 1,160 facts/6,295 questions/6,467 occurrences/138 shards. Maintained-reference authority records 63 book files/57,646 lines/3,142,988 bytes from a 0/+27/+1,525 delta, no ceiling or allowance rises, and all live-document invariants pass. Final task, relative-path, claims, Knowledge Map, locality, README, staged acceptance, and all 12 doctrine checks are green; generated build and task-local residue are absent. This selection changes no VIAL source acceptance, semantic IR, bridge, plan, backend, artifact, runtime, parity, capability, support, diagnostic, provider, or product behavior.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19: activate expressive VIAL frontier selection; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19: select versioned expressive VIAL programme`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1`
  Status: `done`
  Goal: `Establish the additive VIAL version-2 semantic-family, compatibility, projection, capability, and backend foundation without changing version-1 meaning.`
  Acceptance: `Decision 0034 and the .19 selection are implemented as a closed common envelope and vertical-delivery substrate: v1 stays byte/meaning compatible; v2 normal and terse forms have one typed identity; family/revision, scope, lifetime, order, typed ports, effects, failure, provenance, result, and source-map facts survive every private phase; imports and migration fail closed; backend profiles negotiate before artifacts; usability and generated-code quality are executable gates.`
  Verification: `All seven children are complete. V1 remains byte/meaning compatible while v2 now has distinct source/projection/SemanticIR/common-family/ExecutionIR/plan records, an immutable selected-family registry, fail-closed backend adapters, executable author/artifact-quality gates, and explicit public capabilities/check/format/migration/empty-family planning. No expressive family or v2 backend/compile/runtime/complete-result/parity route is claimed; each remains unavailable before artifacts. Child .19.1.7 supplies the final public-tooling, migration, compatibility, support, documentation, containment, and residue evidence.`
  Commit: `children .19.1.1-.19.1.7 task-scoped activation and implementation commits`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.7`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.1`
  Status: `done`
  Goal: `Select the exact version-2 source, schema, compatibility, import, and migration contract.`
  Acceptance: `Specify roots and sections, immutable v1 behavior, v2 schema identities, same-version import rules, explicit future compatibility adapters, deterministic non-deprecating migration, limits, diagnostics, rollback, and complete nonclaims before parser changes.`
  Verification: `Clean predecessor commit 98d6b69cf selects the complete additive-v2 vertical-family programme; activation commit 4f6fa126d owns this contract-only slice. The required pre-selection Knowledge Map query returned no exact v2 contract, while git history traces the closed v1 root to 08f59167b and additive-v2 choice to 98d6b69cf. The new bounded maintained VIAL reference has a 15-line/715-byte mandatory landing and one 275-line/14,604-byte semantic part. It freezes the normal/terse v2 roots, the sole ordered intents section, registered family/revision grammar boundary, immutable v1 route, source/downstream schema identities, same-version catalog rule, explicit initially-empty adapter registry, opt-in atomic whole-catalog v1 migration and compatibility projection, safety limits, diagnostics, validation, nonclaims, and rollback. Focused v1/tooling, containment, claim, reader, and support evidence passes at Files=7/Tests=60. Every mdBook chapter tests; the repository-local render contains 98 files/22,048 KiB, contains both v2 sections, and is removed exactly. Knowledge Map closes at 1,160 facts/6,296 questions/6,467 occurrences/138 shards and now resolves the exact v2 contract question. Claim inventory/dispositions close 1,896/1,896 candidates with 316 claim records, 979 gates, 601 reviewed incidentals, and zero gaps; maintained-reference authority records the exact 63-file/57,680-line/3,144,793-byte book at 0/+34/+1,805 and the new 2-file/290-line/15,319-byte VIAL reference without raising a ceiling. Focused-document classification, task integrity, relative paths, locality, README, live containment, staged acceptance, and all 12 doctrines pass. No parser, source acceptance, semantic object, public tool, capability/support record, bridge, execution plan, artifact, backend, runtime, result, parity, provider, HIAL, or other product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.1: activate VIAL v2 source contract selection; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.1: select VIAL v2 source compatibility contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.2`
  Status: `done`
  Goal: `Implement version-2 parsing and equivalent normal/terse source projections.`
  Acceptance: `Both projections parse through one normalizer and builder, inserted target-neutral facts retain rule identity and authored provenance, format/reparse identities agree, v1 output is unchanged, mixed/unknown versions reject, and hostile defaults or backend-shaped syntax cannot enter.`
  Verification: `Clean contract-selection commit c43e158e8 owns the exact additive-v2 boundary and clean activation ef4ebfcd0 owns this isolated implementation. Root-version dispatch now preserves the complete v1 path and sends v2 through one shared normalizer plus a separate closed builder. The v2 builder validates the seven-section catalog, reserved adapter form, family/revision shapes and catalog bounds, reuses the unchanged v1 builder only for inherited base forms, then constructs immutable schema/report/projection v2 records with an authored empty intent-family collection. Same-version imports, deterministic v2 diagnostics, normal/terse format-reparse equality, v1/v2 empty-intents compatibility, defensive copies, and explicit v1 public-tool/plan rejection are executable. Five pre-change v1 IR/report/projection/format digests remain exact. The audit also corrected the selected prose after blame to be9c74163/50a0d7d393 proved reachable legacy normal/terse version diagnostics differed from its nominal dead parse-error branch. Focused source/tool/plan tests, portable emission, every mdBook chapter, repository-local build inspection/removal, Knowledge Map, claims, containment, task acceptance, and doctrines pass; Darwin runtime gates retain their existing explicit skips. No non-empty family, registry, public v2 tool, migration, bridge, execution IR, backend, runtime, result, parity, support, provider, or HIAL behavior ships.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.2: activate VIAL v2 parser implementation; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.2: implement VIAL v2 source projections`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.3`
  Status: `done`
  Goal: `Implement the immutable common semantic-family envelope across SemanticIR, bridge binding, ExecutionIR, plan, result, and source maps.`
  Acceptance: `Every common field remains closed, typed, bounded, deterministic, defensively copied, source-derived, and traceable through each phase; versioned v1 paths retain exact projections; incomplete or contradictory nodes fail before downstream allocation.`
  Verification: `Clean parser/projection commit fe480cd24 owns the private base-v2 source boundary and clean activation 32b045d3f owns this isolated implementation. The required Knowledge Map query returned no common-envelope answer. History traces the v1-only ExecutionIR/plan boundary to 44dbecd1a, the temporary v2 planning rejection to fe480cd24, and the v1 result producer to dfe87f536. FSM::Support::VIALSemanticFamilyContract now defines exact closed semantic, binding, execution, plan, result, and content-derived source-map schemas; validates family/revision, scope, lifetime, order, typed ports/bindings, bridge/type proofs, effects, failure/result, phase preservation, repository-relative provenance, defensive JSON data, duplicate identities, and finite collection/depth/value/byte limits; and publishes explicit nonclaims. SemanticIR validates the typed family carrier. The isolated ExecutionBuilderV2 privately carries only empty-family v2 through the unchanged v1 HIAL bridge/base binder into distinct immutable fsmgen.vial_execution_ir.v2 and fsmgen.vial_plan.v2 envelopes with authored-v2 identity, versioned capabilities, deterministic plan identity, and no invented family. V1 ExecutionIR and plan key sets retain exact hashes 7d54be68bc691e3c05c4c94405f0ad278b9206032f8b9cde5dc3d7bf13714509 and eaa8cc70fa25a4382921f40112c0f3f50aec4045caccff2e6a8f98cfbc1c0942 plus plan/e236297c8b434a9b374d1800112841e00327bdbd5d8d9130440bd20681fbed6e. Existing v1 backend negotiation rejects v2 before artifacts, and ResultProducer now rejects it before a mislabeled v1 manifest. The guarded eleven-file source/semantic/bridge/execution/public-tool/plan/backend/reader band passes Files=11/Tests=70 with only the existing opt-in Darwin runtime qualification skip; t1802 separately proves complete and hostile phase chains at Files=1/Tests=5. Every mdBook chapter tests; its repository-local render contains 98 files/22,064 KiB, exposes both new reader sections, and is removed exactly. Knowledge Map closes at 1,160 facts/6,297 questions/6,468 occurrences/138 shards. Claim inventory/dispositions close 1,896/1,896 with zero gaps. Containment authorizes the exact 63-file/57,721-line/3,147,138-byte book and 2-file/422-line/23,011-byte VIAL reference from the prior exact baselines with no ceiling rise; the 138-line Knowledge Card remains below its prior byte size. Final task, path, locality, README, claims, Knowledge Map, containment, staged acceptance, and all 12 doctrines are green, with no generated build, artifact, log, binary, temporary, or brief residue. No nonempty family, registry, backend adapter/emission, compile/runtime/result-manifest/parity, public v2 tool/migration, support, provider, or HIAL behavior ships.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.3: activate common VIAL family envelope; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.3: implement immutable VIAL family envelope`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.4`
  Status: `done`
  Goal: `Implement the semantic-family registry and fail-closed profile capability negotiation.`
  Acceptance: `One registry owns family/revision identities, dependencies, effects, bounds, maturity stages, and backend profile mappings; public capabilities derive from it; parser, planner, emitter, and runner reject the complete unsupported requirement set before partial output without borrowing another profile's support.`
  Verification: `Clean common-envelope commit c246314be owns the complete immutable cross-phase v2 carrier and clean activation f62831b10 owns this isolated registry slice. The required Knowledge Map query initially returned no registry/profile-negotiation answer. Decisions 0039 and 0043 require distinct capability dimensions and profile-local backend support. FSM::Support::VIALSemanticFamilyRegistry now supplies one closed, content-addressed, defensively copied authority for all twelve selected family/revision/task identities, reserved target-neutral effects, dependencies, common bounds, exact stage/backend maturity, three current profiles, and the unchanged v1 public capability set. Every functional family stage remains explicitly unavailable. Parser, planner, portable emitter, and runner negotiate their own profile and report the complete unsupported schema/profile/family/revision/dependency/capability/effect set before SemanticIR, HIAL review artifacts, emitted artifacts, workspace, or process creation; the planner also rejects an empty-family wrong-profile request before invalid HIAL is inspected. The public tooling contract remains byte-exact at SHA-256 42db05da519dffd97c3e40ec254c82d09b5f20ef53a849e53025b976f5aded4e. T1803 passes five top-level subtests and the final RAM-guarded twelve-file v1/v2 compiler/tool/backend/reader band passes Files=12/Tests=75, with only the existing opt-in Darwin runtime qualification skip. Every mdBook chapter tests; the inspected repository-local render has 98 files/22,080 KiB and was removed. The VIAL reference was semantically partitioned into three directly indexed parts after the size checker exposed the source part at 90.2%; the final largest part is 344 lines/18,690 bytes and the exact aggregate is 3 files/492 lines/26,982 bytes, with no debt, allowance, or ceiling increase. The book authority is exact at 63 files/57,751 lines/3,149,097 bytes. Knowledge Map parity is 1,160 facts/6,298 questions/6,469 occurrences/138 shards; claim dispositions close 1,896/1,896 candidates with 316 claim records, 979 gates, 601 reviewed, and zero gaps/open owners. Syntax, diff hygiene, relative paths, task integrity, locality, README, containment, staged acceptance, and all registered doctrines pass; .bin/.log and generated-build residue censuses are empty. No expressive family grammar/implementation, v2 backend adapter/emission/runtime/result/parity, public v2 tooling/migration, support promotion, provider, or changed successful v1 behavior ships.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.4: activate VIAL family registry; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.4: implement VIAL family registry`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.5`
  Status: `done`
  Goal: `Implement common portable-SystemVerilog, native-UVM, and VHDL/OSVVM backend adapter seams.`
  Acceptance: `Adapters consume only typed versioned IR, report exact emitted/compile/run/result/parity maturity, isolate target mechanisms, preserve deterministic source maps and atomic artifacts, and cannot accept an unknown family or silently omit a semantic effect.`
  Verification: `Clean registry commit 6927bfcfb owns the twelve selected family namespaces and clean activation c7685a046 owns this isolated adapter slice. The required Knowledge Map query returned no common v2 backend-adapter answer. Git history traces the independent native-UVM v1 schema guard to 5a1805f52, portable-VHDL capability list to ab8b1af24, and portable-SV registry entry to 6927bfcfb. Decisions 0050/0051 require distinct public portable-SV, review-only native-UVM, private portable-VHDL, and private OSVVM states. FSM::Support::VIALSemanticFamilyBackendAdapter now publishes one closed content-addressed four-route authority for exact emitter, target mechanism, typed ExecutionIR boundary, accepted v1 schema/profile, output/source-map schemas, atomic artifact model, and independent emission/compile/runtime/result/parity/public maturity. The family registry maps every selected family to all four profiles while every mapping remains unavailable. All four emitters preflight the exact typed/version-consistent IR and complete family/revision/capability/effect set before target rendering; OSVVM rejects before portable delegation or provider verification. T1804 covers deterministic/defensive registry shape, exact maturity isolation, target-mechanism absence from ExecutionIR, untyped/inconsistent/unknown-profile rejection, complete hostile v2 requirement reporting, zero provider/delegation calls, and zero artifact output. Existing successful v1 emitter result shapes remain unchanged. Focused adapter/backend preservation passes at Files=13/Tests=212; final compiler/reader, mdBook, Knowledge Map, claims, containment, task acceptance, doctrine, and residue evidence is recorded in the checklist below. No family implementation, accepted v2 emission, new compile/runtime/result/parity, public v2 tooling, provider access, support promotion, or HIAL behavior ships.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.5: activate common VIAL backend adapters; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.5: implement common VIAL backend adapters`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.6`
  Status: `done`
  Goal: `Make target-free author usability and generated-artifact quality executable requirements.`
  Acceptance: `Fixtures and hostile controls prove public examples/diagnostics/normal forms need no SV/UVM/VHDL knowledge; backend checks prove deterministic readable minimally shaped source-mapped output, absence-driven component elision, bounded cost, and zero methodology-plumbing leakage into VIAL semantics.`
  Verification: `Clean backend-adapter commit 94356f175 owns one typed preflight across the four existing routes and clean activation cd0667098 owns this isolated quality slice. The required Knowledge Map query returned no direct target-free-usability/generated-artifact-quality answer. Git history traces the four independent emitter result graphs to 201590d84, 5a1805f52, 3291217e8, and 4f350f29c. FSM::Support::VIALUsabilityArtifactQuality now publishes one closed content-addressed private contract for all maintained public fixtures, v2 normal/terse forms, source diagnostics, v1/v2 SemanticIR, the family carrier, nine witnessed target/methodology exclusions, and four exact backend profiles. Its author evaluator enforces exact maintained-fixture membership. Its backend evaluator checks repeated canonical identity, exact artifact and source-role/language sets, safe sorted paths, unique roles, newline/tab/NUL and 90%-at-160-byte/4,096-byte-hard line bounds, content/length-verified source-map references, complete in-range uniquely identified mappings, exact conditional probe elision, and artifact/source/16-MiB/1,000,000-map-entry budgets. T1805 runs all four actual emitters twice, uses one sealed OSVVM provider evaluation, and carries RED controls for all nine author rules plus determinism, readability, required roles, relabeled source roles, map coverage, bounded inventory, retained absent-feature roles, and valid paired elision. Standalone t1805 passes Files=1/Tests=7; the focused v2 foundation band passes Files=5/Tests=27; and the guarded compiler/backend/reader band passes Files=19/Tests=146 with only the two existing explicit Darwin runtime guards skipped. Every mdBook chapter tests; the inspected 98-file/22,112-KiB repository-local build is removed. Knowledge Map is current at 1,160 facts/6,303 questions/6,474 occurrences/138 shards. Claim inventory/disposition and exact maintained-reference authorities close the book at 63 files/57,842 lines/3,154,862 bytes and the VIAL reference at 3 files/594 lines/33,673 bytes without a ceiling rise. Final syntax, diff, task, relative-path, locality, README, staged acceptance, doctrine, and residue evidence is recorded in the checklist below. No accepted source, semantic meaning, emitter byte, runtime/result/parity evidence, public API, capability, support state, provider access, or HIAL behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.6: activate VIAL usability and artifact quality; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.6: enforce VIAL usability and artifact quality`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.7`
  Status: `done`
  Goal: `Close the version-2 foundation with public tooling, migration guidance, compatibility, containment, and support truth.`
  Acceptance: `Capabilities/check/format/plan expose exact version-aware states, v1 regression remains byte-exact, v2 migration is explicit and reviewable, mdBook examples are runnable, every schema and diagnostic is documented, residues are absent, and no expressive family is falsely advertised by the foundation alone.`
  Verification: `Clean quality-gate commit 714eef6e4 and activation commit 061530478 own this closeout. The required Knowledge Map query returned no prior public-v2 answer; decisions 0034/0039 require additive version isolation and explicit artifact-atomic public records. FSM::Support::VIALToolingContract now publishes one distinct v2 contract while the canonical v1 JSON remains byte-exact at SHA-256 42db05da519dffd97c3e40ec254c82d09b5f20ef53a849e53025b976f5aded4e. The CLI/API select v2 explicitly and expose capabilities, check, format, non-mutating whole-catalog v1-to-v2 migration, and empty-family plan. Migration canonicalizes every reachable source, returns original/output SHA-256 identities and semantic-path maps, reparses the v2 catalog, independently matches one compatibility projection, rejects mixed versions and reverse migration, writes no source/artifact, and leaves ordinary v1 operations unchanged. V2 plans publish distinct plan/tool-manifest schemas atomically while retaining the unchanged HIAL bridge; v2 run rejects before plan or artifacts. Two exact supported-smoke rows and the six-fixture usability gate advertise only shipped source/migration and empty-base planning. T1806 plus strengthened t1797/t1799/t1800 derive runnable docs, schemas, diagnostics, actions, support, and nonclaims. The guarded final VIAL/accounting/reader band passes Files=19/Tests=7,203 with only the two established opt-in Darwin runtime skips; the focused repaired accounting/foundation band passes Files=2/Tests=7,118. All changed Perl files and tests compile. Every mdBook chapter tests; the 98-file/22,188-KiB HTML build succeeds and is removed with exact scratch. The Knowledge Card and generated map are current at 1,160 facts/6,306 questions/6,477 occurrences/138 shards. Claim inventory derives 1,899 candidates, and dispositions close 1,899/1,899 with 316 claim records, 982 gates, 601 reviewed incidentals, and zero gaps/open owners. Containment authorizes the exact 63-file/58,039-line/3,164,374-byte book and 3-file/681-line/38,218-byte VIAL reference, records the latter as bounded warning debt, ratchets its ceilings downward, and raises no ceiling. Task, path, locality, README, diff, staged acceptance, all 12 registered doctrines, and exact build/artifact/log/binary/brief residue gates are green. No expressive family, v2 backend/emission/compile/runtime/complete-result/parity, mixed-language route, support promotion, private IR exposure, provider access, or HIAL behavior ships.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.7: activate VIAL v2 foundation closeout; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.1.7: close VIAL v2 public foundation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2`
  Status: `active`
  Goal: `Deliver lifecycle-control intent end to end.`
  Acceptance: `VIAL expresses readiness dependencies, service start/stop, stimulus start, completion/drain, shutdown/finalization order, deadlines, and failure policy without authored phases or objections; all six child lanes close with exact portable-SV, native-UVM, and VHDL/OSVVM mappings or pre-artifact rejection.`
  Verification: `pending children .19.2.1-.19.2.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.1`
  Status: `done`
  Goal: `Select lifecycle semantics and target-free normal/terse source.`
  Acceptance: `Define dependency, readiness, service, completion/drain, shutdown/finalize, deadline, and failure records with finite bounds, explicit order/defaults, examples, diagnostics, and semantic compression; reject UVM phase/objection vocabulary.`
  Verification: `Clean foundation closeout commit 984271755 completes .19.1 before this pivot, and clean continuity commit 06c331cb7 activates only this selection. The required Knowledge Map query returned no lifecycle-selection answer; decisions 0034/0036 and the common v2 envelope are the normative parents. New bounded lifecycle-control reference selects one fixture/local-domain program, exact dependency/readiness/single fixture-background service/stimulus/completion/drain/shutdown/finalize/deadline/failure grammar, identical normal/terse family spelling, monotone conditions, non-weakenable intrinsic order, exact defaults, typed semantic expansion/result shapes, inclusive C+N-1 logical deadlines, bounded failure finalization, finite family limits, stable diagnostics, backend-private mappings, and explicit nonclaims. T1807 independently checks all nine target/methodology exclusions, grammar/record/default/bound/diagnostic coverage, registry equality, unchanged unavailable maturity, and current atomic VIAL_FAMILY_UNSUPPORTED rejection. The RAM-guarded focused reference/v2 band passes Files=12/Tests=65. All 63 mdBook chapters test; the repository-local 98-file/22,204-KiB HTML build succeeds and is removed exactly. Knowledge Map is current at 1,161 facts/6,315 questions/6,486 occurrences/139 shards. Containment accepts the 63-file/58,099-line/3,167,016-byte book and partitioned 4-file/1,073-line/55,582-byte VIAL reference with no ceiling rise; the new lifecycle part itself is 390 lines/17,260 bytes. Claim, task, relative-path, locality, README, diff, staged acceptance, doctrine, and residue gates close in the checklist below. No accepted source, SemanticIR, bridge, plan, backend, runtime, result, parity, capability, support, provider, HIAL, or product behavior changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.1: activate lifecycle semantic selection; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.1: select target-neutral lifecycle contract`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.2`
  Status: `done`
  Goal: `Implement lifecycle SemanticIR, binding, execution, plan, result, source-map, and capability propagation.`
  Acceptance: `Typed lifecycle dependencies and terminal conditions remain deterministic through every phase, cycles/deadlines are bounded, deadlock and incomplete drain fail closed, and results expose logical seams rather than backend scheduling folklore.`
  Verification: `Clean lifecycle-selection commit e4f37d641 supplies the exact revision-1 contract and clean activation 16ac8564f isolates this compiler slice. FSM::VIAL::LifecycleControl implements the closed grammar, finite admission, acyclic monotone expansion, twelve typed records for the maintained AHB lifecycle, fixture/domain type-proof bindings, execution operations, target-neutral plan records, capability propagation, cumulative content-addressed source maps, and plan-relative normalized-result validation. Result acceptance requires exact lifecycle/fixture/domain identities, record-ID sets, deadline bounds, one preserved source map per planned record, inclusive observed deadline windows, and monotone pass chronology; a pass additionally requires every dependency satisfied, service stopped, lifecycle point reached, deadline met, and no retained failure. Public v2 check/format/plan, discovery, regression accounting, usability authority, maintained references, mdBook, and Knowledge Map reflect that exact compiler frontier while every backend mapping and v2 run/result production/parity/support state remains unavailable. The public fixture check reports VIAL check passed (normal_v2). The final RAM-guarded focused band reports All tests successful at Files=14, Tests=7191. All 63 mdBook chapters test; the repository-local render contains 98 files/22,228 KiB and is removed exactly. Knowledge Map is current at 1,161 facts/6,315 questions/6,486 occurrences/139 shards. Exact claim, containment, task/path/locality/README, staged acceptance, doctrine, and residue evidence closes in the checklist below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.2: activate lifecycle compiler phases; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.2: implement lifecycle compiler phases`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3`
  Status: `active`
  Goal: `Implement and qualify lifecycle control in portable SystemVerilog.`
  Acceptance: `The static scheduler realizes selected readiness, service, completion, drain, shutdown, and finalization semantics with bounded execution and normalized results; emitted control is minimal/readable/source-mapped and runtime failures cleanly publish no false success.`
  Verification: `Clean lifecycle-compiler commit bc137fc2f9 is the sole behavior-bearing predecessor. The required Knowledge Map query returned no existing portable-SystemVerilog lifecycle mapping answer. Decisions 0036/0043 preserve target-neutral logical time above one statically partially evaluated portable scheduler; decisions 0080-0082 retain exact phase rollover, root-owned direct drive, and single-await child admission boundaries. The read-only current-route audit proves that version-2 ExecutionIR preserves the existing scenario graph and adds twelve lifecycle-family records, while the common adapter registry, portable emitter negotiation, trace validator, result producer, runner, and public run route each still fail closed at an explicit version-1 boundary. The generated scenario scheduler already owns target-neutral drive/sample/react/check rollover, whereas VerilatorLifecycle owns repository-local host-process staging and supervision; neither may become the semantic authority for the other. Five children therefore isolate contract selection, static controller emission, lifecycle trace/result normalization, public runtime qualification, and portable-profile closeout before any code change.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3: activate portable-SystemVerilog lifecycle mapping; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3: decompose portable-SystemVerilog lifecycle mapping`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1`
  Status: `active`
  Goal: `Select the exact portable-SystemVerilog lifecycle mapping and versioned backend evidence contract.`
  Acceptance: `Specify the static controller state, record-to-control mapping, scenario-scheduler relationship, logical cycle/phase observation points, inclusive deadline enforcement, failure/finalization policy, lifecycle trace records, normalized result production, schema/version isolation, source-map duties, artifact atomicity, and exact rejection/nonclaim boundaries before behavior changes; preserve the version-1 emitted graph and public result byte-for-byte.`
  Verification: `A direct canonical-plan probe at clean decomposition commit 12e2fe50b found malformed readiness condition data before the mapping contract could be selected: the service-ready condition object was nested inside a dependency-satisfied reference_id. The root cause is an unparenthesized pair of adjacent Perl map expressions in FSM::VIAL::LifecycleControl, which lets the first map consume the second map's result objects as additional input. Existing lifecycle tests proved record count, order, and result chronology but not recursive condition scalar types. Child .1 repaired and independently watches that compiler prerequisite at clean commit 1b25880f8; child .2 is now active to select the backend contract from valid typed input.`
  Commit: `pending implementation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.1`
  Status: `done`
  Goal: `Repair malformed intrinsic readiness conditions before portable-backend mapping.`
  Acceptance: `Every normalized lifecycle condition recursively contains exactly scalar-or-null reference_id/domain_id fields and an array of condition operands; readiness retains separate dependency_satisfied and service_ready operands in deterministic order; SemanticIR, execution, and plan preserve that shape; hostile nested-reference substitutions fail closed; existing lifecycle semantics, v1 behavior, and all backend availability remain unchanged.`
  Verification: `Clean activation commit 3af8b5b34 owns the defect isolated by the pre-contract canonical-plan probe. The required Knowledge Map query returned no prior answer. The added RED oracle failed exactly because readiness operand 2 was dependency_satisfied instead of service_ready and its reference_id was an object. Parenthesized, separately materialized dependency and service map results remove the Perl list-capture ambiguity. A lifecycle-specific recursive validator now admits only the closed four-key condition shape, scalar-or-null IDs, exact leaf kinds, finite all operands/depth/count, and rejects the reproduced object-valued substitution. T1808 proves the corrected dependency/dependency/service-ready operand sequence and byte-equal condition preservation through SemanticIR, ExecutionIR, and plan. Standalone T1808 passes Files=1/Tests=5; the final RAM-guarded v1 emitter plus complete v2 projection/envelope/registry/adapter/usability/foundation/selection/compiler band passes Files=9/Tests=53. Both changed Perl/test files compile, all 63 mdBook chapters test, and Knowledge Map regeneration reports 1,161 facts/6,317 questions/6,488 occurrences/139 shards. The book authority records 63 files/58,163 lines/3,170,330 bytes from an exact 0/+6/+347 clarification with no ceiling rise. Final containment, task/path/locality/README, staged acceptance, doctrine, and residue evidence is recorded below. No v1 behavior, lifecycle source meaning, HIAL binding, backend availability/emission/runtime/result/parity, support, provider, or other family changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.1: activate readiness-condition repair; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.1: repair lifecycle readiness condition shape`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2`
  Status: `active`
  Goal: `Select the exact portable-SystemVerilog lifecycle mapping and versioned backend evidence contract from valid typed lifecycle records.`
  Acceptance: `A decision, bounded VIAL reference part, executable contract watcher, mdBook guidance, and Knowledge Map card close the static controller, trace/result, schema-isolation, source-map, atomicity, rejection, rollback, and nonclaim boundaries while every version-2 backend remains unavailable.`
  Verification: `Clean compiler-repair commit 1b25880f8 supplies recursively valid typed lifecycle conditions. The required Knowledge Map query returned no existing portable-SystemVerilog lifecycle backend mapping answer. Decision 0100 and the bounded normative part select one finite static fixture controller beside the v1-derived scenario scheduler, three compiler-owned check seams, a monotone fixture-wide lifecycle cycle, inclusive milestone-before-expiry checks, irreversible bounded failure cleanup, and distinct v2 backend/source-map/trace/projection/result-manifest schemas. T1809 independently derives all record operations from the maintained typed plan, keeps all v2 maturity unavailable, proves adapter/emitter/runner/result/public rejection with no artifact or host call, and freezes the exact v1 emitted graph and normalized-result digests. It also exposes and characterizes one pre-existing private trace-validator envelope gap; proposed repair child .1 must close that prerequisite before emitter work. The final guarded focused band passes Files=11/Tests=65, all 63 mdBook chapters test, the inspected 98-file/22,260-KiB repository-local render is removed, and exact containment/Knowledge Map/claim/doctrine evidence closes in the checklist below.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2: activate portable-SystemVerilog lifecycle contract selection; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2: select portable-SystemVerilog lifecycle contract`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.1`
  Status: `proposed`
  Goal: `Repair standalone version-1 trace-validator isolation before portable-SystemVerilog lifecycle emission.`
  Acceptance: `FSM::VIAL::Backend::TraceValidator admits only an exact FSM::VIAL::ExecutionIR carrier whose schema, schema_version, and profile are fsmgen.vial_execution_ir.v1, 1, and core_directed_single_clock_execution_v1 and which has no semantic_families member; an unsupported carrier rejects before trace parsing with a stable version-boundary diagnostic and no records or projection; canonical version-1 trace and normalized-result identities remain exact.`
  Verification: `The required Knowledge Map query returned no answer. Read-only source and history audits show that TraceValidator verifies the exact ExecutionIR object type but never its envelope: git log -S traces the validator to 201590d84 and finds no fsmgen.vial_execution_ir.v1 guard. T1809 owns the bounded characterization that a canonical v1-shaped trace is presently accepted against lifecycle ExecutionIR v2, while adapter, emitter, runner, result producer, and public v2 run remain unavailable. Repair is required before child .19.2.3.2 may begin emission.`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2`
  Status: `active`
  Goal: `Repair blockers exposed by the portable-SystemVerilog lifecycle contract selection pre-push qualification.`
  Acceptance: `The full pre-push gate reaches a deterministic terminal result without duplicating the maintained-reference surface count or depending on an arbitrary PATH-selected no-op executable; each independently rooted blocker is repaired and committed in its own child before the full gate is rerun.`
  Verification: `The first full-gate attempt was cleanly RAM-guarded at 88% host memory because unrelated host workloads raised measured pressure to 88.3%. The second clean attempt advanced through T303 and exposed two exact blockers: T1553 expected the common containment checker's obsolete 22-surface success text after the selected VIAL reference became the twenty-third maintained surface, and T313 selected Homebrew GNU true as a test stub; that otherwise valid binary reproducibly remained before main in _dyld_start while /usr/bin/true exited immediately. Required Knowledge Map queries returned no existing answer for either blocker. Child .1 removed the duplicated surface cardinality. Child .2 replaced mutable fixture identity and unbounded HDL launches with repository-local fixtures plus the fixed, contained shared process policy. The third complete RAM-guarded attempt reached T1524 and falsified that fixed policy: a valid large Yosys synthesis exceeded the 8,388,608-byte aggregate capture limit and was rejected as output_limited. Child .3 owns selection and implementation of a bounded policy that admits valid validator output without restoring an unbounded launch.`
  Commit: `pending implementation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.1`
  Status: `done`
  Goal: `Remove T1553's duplicated live-document surface-count authority.`
  Acceptance: `T1553 recognizes the exact common containment checker's success contract without owning its changing registered-surface count; T1553 and T1554 pass together against the authoritative twenty-three-surface registry; no maintained-reference ceiling, registration, or content changes.`
  Verification: `The second clean full-CI attempt failed exactly one T1553 assertion because the test hard-coded all live-document size-containment invariants hold (22 surfaces), while the authoritative common checker correctly reported 23 surfaces after the committed VIAL maintained-reference registration. The required Knowledge Map query returned no answer. git log -S'22 surfaces' traces the copied count to ea1b76dd5, where the same assertion was manually advanced from 20 to 22. T1553 now retains the stable common-checker success phrase and numeric-count shape without owning its live cardinality; T1554 retains exact counts for fixed synthetic registries. The focused pair passes Files=2/Tests=27, T1553 syntax is valid, all 63 mdBook chapters test, and the inspected repository-local render contains 98 files/22,260 KiB before exact removal. The updated adoption guide is rendered into the mdBook, the Knowledge Map validates at 1,161 facts/6,321 questions/6,492 occurrences/139 shards, live-document containment passes at 23 surfaces with zero ceiling increases, and docs-path/task-tree checks are green. Claim inventory regeneration changes only its source census digest while retaining 12,270 numeric lines, 1,899 candidates, and 2,670 constants; its independent census agrees and dispositions remain closed 1,899/1,899 with zero gaps or open owners. DEVELOPMENT_NOTES and its sealed rationale ledger remain byte-unchanged because that root document is exactly at its 1,200-line ceiling; the task, guide, card, generated map, and Git commit own the durable rationale. No registry, ceiling, maintained-reference content, product behavior, VIAL/HIAL behavior, or support claim changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.1: delegate live surface-count authority`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2`
  Status: `done`
  Goal: `Make T313's no-op external-validator stubs deterministic and bounded.`
  Acceptance: `T313 uses explicit known-safe no-op/failing executables rather than arbitrary PATH-selected Homebrew aliases, and external validation steps have a finite timeout that reports one stable bounded failure instead of hanging the full gate; focused contract tests reproduce the former Homebrew-stub exposure and pass without off-volume artifacts.`
  Verification: `During the second clean full-CI attempt, T313's PATH-resolved /opt/homebrew/opt/coreutils/libexec/gnubin/true remained alive for more than seven minutes before main in _dyld_start. A standalone invocation reproduced the stall; /usr/bin/true exited immediately; the binary is native arm64, code-signature-valid, unquarantined, and linked only to libSystem; host memory was 60% free and 678 processes were below the 4,000 soft limit. HDLExternalValidation used IPC::Cmd::run without a timeout, so an external-tool launch stall could block the gate indefinitely. The required Knowledge Map query returned no answer. Decisions 0086 and 0087 independently reject an IPC::Cmd alarm without owned process-group cleanup. Child .1 closes deterministic fixture identity; child .2 moves one reviewed supervision engine behind sealed test/HDL policies and applies fixed wall, capture, cwd, process-group, cleanup, stream, and retry semantics. Focused and widened gates, real Verilator/Yosys validation, mdBook rendering, claim checks, locality, residue, staged acceptance, and the complete doctrine driver are green. The interrupted run and exact sampler artifacts were terminated/removed with residue checks.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.1: make validator fixtures PATH-independent; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.2: contain HDL validator processes`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.1`
  Status: `done`
  Goal: `Remove T313's PATH-selected success and failure fixture executables.`
  Acceptance: `T313 constructs explicit repository-local success and failure programs whose shebang names the canonical already-running Perl interpreter; a hostile PATH containing same-named trap executables cannot change the selected programs or their exit truth; no can_run true/false fallback, host-global fixture, production behavior, or off-volume residue remains.`
  Verification: `The required Knowledge Map query returned no answer. git log -S independently traces the success-fixture PATH lookup to ba8ea7840 and the failure-fixture lookup to 602906bf1; the latter introduced both true and false host-command fallbacks. T313 now resolves the already-running Perl interpreter once, generates explicit executable success/failure programs in its repository-local test temp root, and passes those exact paths to the mocked tool inventory. A hostile PATH exposes same-named exit-97/98 traps while a valid two-step run succeeds, unsupported-top rejection retains its prefix, and the explicit failure fixture retains both the tool-step prefix and its own diagnostic. The source contains no can_run true/false or fixed /usr/bin fallback. Perl syntax is valid and standalone T313 passes Files=1/Tests=4. The updated Knowledge Card preserves the fixture-identity rule; the generated map validates at 1,161 facts/6,322 questions/6,493 occurrences/139 shards. Claim inventory's independent census agrees at 12,270 numeric lines while all 1,899 candidates remain disposed with zero gaps/open owners. No production module, validation contract, public behavior, VIAL/HIAL behavior, support claim, or artifact path changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.1: make validator fixtures PATH-independent`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2`
  Status: `done`
  Goal: `Give HDL external-validation steps one finite, contained process lifecycle.`
  Acceptance: `Replace HDLExternalValidation's direct IPC::Cmd execution with a caller-sealed policy that reuses or extracts one reviewed supervision mechanism, launches shell-free argv from a repository-derived working directory, applies fixed wall and aggregate-capture bounds, preserves separate stdout/stderr and existing success/failure prefixes, owns and verifies process-group TERM/KILL cleanup, never retries, and exposes stable timeout failure evidence; no third drifting process engine or VIAL authority leak is introduced.`
  Verification: `Read-only architecture audit found two reviewed but deliberately separate mechanisms: FSM::Test::ProcessSupervisor owned the split-stream process-group mechanics selected by decisions 0086/0087, while FSM::VIAL::Backend::ProcessSupervisor owns stronger VIAL-specific detached-descendant and outer-worker semantics. Direct reuse of the latter would leak VIAL authority; copying the former would create a third engine. Child .1 selected move-not-copy promotion behind sealed policies. Child .2 implements that selection: the common mechanism now resides in caller-sealed FSM::Support authority, the test API is a thin compatibility wrapper, and HDL validation supplies its own fixed policy without acquiring VIAL lifecycle semantics. Contract, hostile-process, real-tool, documentation, claim, locality, residue, and complete staged-doctrine checks pass.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.1: select shared HDL process supervision; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.2: contain HDL validator processes`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.1`
  Status: `done`
  Goal: `Select the shared-mechanism and sealed-policy boundary for HDL external validation.`
  Acceptance: `An accepted decision selects whether and how to promote the reviewed split-stream test process mechanism for production reuse, preserves test adapter behavior, excludes VIAL-specific lifecycle authority, fixes HDL timeout/capture/cwd/cleanup/no-retry policy, names public contract and mdBook consequences, and supplies distinct re-derivation, falsification, and durability legs before code changes.`
  Verification: `Decision 0101 is accepted. It selects a move-not-copy promotion of FSM::Test::ProcessSupervisor mechanics into caller-sealed internal FSM::Support authority, retains the test module as a thin compatibility/policy wrapper, excludes the specialized VIAL supervisor, and fixes each HDL validation step at a 120-second wall, 8,388,608-byte aggregate capture, repository-derived cwd, one process group, verified TERM/KILL cleanup, separate streams, unchanged success shape/failure prefix, and no retry. Its independent re-derivation, falsification, and durability legs bind implementation and public contract evidence. The bounded Knowledge Map answer routes the selection without adding another card under current containment pressure.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.1: select shared HDL process supervision`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.2`
  Status: `done`
  Goal: `Implement and verify the selected shared supervisor plus sealed HDL-validation policy.`
  Acceptance: `The selected mechanism is moved rather than copied; the test compatibility boundary retains exact behavior; HDLExternalValidation has no IPC::Cmd launch, uses fixed 120-second/8,388,608-byte process-group policy from repository cwd, preserves shell-free argv, separate stdout/stderr, success shape, and failure prefix, maps timeout/overflow/exec/signal/nonzero/cleanup truth without retry, and publishes accurate manifest/book guidance; hostile and real-tool focused gates pass without residue.`
  Verification: `Decision 0101 is committed at 9d3c55290d. The reviewed split-stream/process-group engine is moved to caller-sealed FSM::Support authority; the old test API is a five-function delegating policy wrapper, and T1669 proves that no unsealed or VIAL caller can acquire the common launch authority. HDL validation no longer launches through IPC::Cmd: every step uses repository-root cwd, shell-free argv, separate streams, one 120-second wall, one 8,388,608-byte aggregate-capture limit, verified TERM/KILL process-group cleanup, stable status/diagnostic failure truth, and no retry. During T313, the new wall converted its direct Perl-stub launch from an indefinite hang into status=timed_out. An independent two-second repository-local probe reproduced the hang outside FSMGen's validator; a one-second process sample found /usr/bin/perl stationary at _dyld_start with a 96 KiB footprint, while T1669's explicit interpreter-plus-script argv remained green. Plain Perl tool entrypoints—including installed Verilator—therefore retain exact tool identity but are handed explicitly to the canonical running interpreter. T313 maps all eight failure classes and passes its installed-tool smoke; T1669 proves hostile-tree cleanup. The widened eight-file gate passes Files=8/Tests=30, the final HDL/process band passes Files=3/Tests=17, all seven changed Perl/test files are syntax-clean, all 63 book chapters test, and an inspected repository-local 97-file/22,272-KiB render is removed exactly. Knowledge Map, claim inventory/dispositions, live containment, locality, task integrity/acceptance, docs paths, diff, residue, and the complete staged doctrine driver pass.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.2.2.2: contain HDL validator processes`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3`
  Status: `active`
  Goal: `Repair the validator output-retention policy falsified by a valid large Yosys synthesis.`
  Acceptance: `Select and implement one finite stdout/stderr retention policy that admits the complete-CI Yosys workload, keeps memory and diagnostic volume bounded, preserves split-stream and process-group truth, rejects genuinely excessive output deterministically, and does not weaken timeout, cleanup, cwd, argv, retry, or caller-seal guarantees; rerun the complete RAM-guarded gate from its beginning.`
  Verification: `The third clean complete-CI attempt reached T1524 after T1436/T1437/T1438 and the enabled T1498-T1523 band had passed or taken declared Darwin runtime skips. T1524's generated HDL parsed successfully and entered Yosys synthesis, but the supervised process crossed the fixed 8,388,608-byte aggregate capture limit; HDLExternalValidation rejected it as status=output_limited and the test failed at line 226. The failure diagnostic itself retained roughly 8 MiB and expanded the TAP stream above two million tokens. The required Knowledge Map query returned no existing answer. Child .1 selects native quiet success output plus bounded failure excerpts without changing the supervisor ceiling; child .2 owns implementation.`
  Commit: `pending implementation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.1`
  Status: `done`
  Goal: `Select the finite HDL-validator output-retention and failure-diagnostic contract.`
  Acceptance: `Measure the valid T1524 Yosys stdout/stderr volume without unbounded in-memory capture, identify which output is semantically required on success and failure, compare finite full-capture, repository-local spool, and bounded head/tail retention strategies, and accept one policy with explicit re-derivation, falsification, durability, cleanup, locality, and nonclaim boundaries before code changes.`
  Verification: `Decision 0101 is amended from three independent observations. Re-derivation regenerated the tracked T1524 source and streamed the exact RAM-guarded Yosys 0.68 synthesis output into a byte counter: the valid 999-KiB HDL emitted 46,647,945 bytes without retention. Falsification reran the identical script with native -q and measured zero output at exit 0, then proved an independent quiet absent-source invocation still exited 1 with its precise ERROR diagnostic. The selection therefore keeps the 120-second/8,388,608-byte supervisor policy, adds -q to both Yosys modes, and bounds each rendered failure stream to 65,536 retained tool-output bytes as a first-32,768/last-32,768 excerpt plus a bounded exact omission marker. Raising capture, spooling unused success logs, changing shared capture semantics, and hiding failures are rejected. Decision, task, Knowledge Map, future contract/book metadata, T313/T1524 watchers, and Git are the durability chain; the recorded measurements are one-fixture/tool observations, not performance, capacity, or support claims.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.1: select bounded validator output policy`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.2`
  Status: `blocked`
  Goal: `Implement and qualify the selected finite HDL-validator output-retention policy.`
  Acceptance: `The accepted policy is implemented in the shared supervisor/HDL policy boundary with exact focused RED/GREEN and hostile overflow coverage; T1524 passes without an unbounded memory or diagnostic path, all prior timeout/capture/cleanup/caller-seal contracts remain green, generated residue is removed, and the complete RAM-guarded pre-push gate reaches a deterministic terminal result.`
  Verification: `Implementation is focused-green and committed at a0b7f62d39567cc2e7399b9e43af19af3093670c; complete qualification is blocked. After the reported session crash during T1436, recovery found a clean worktree and no surviving test processes. The from-scratch RAM-guarded ./bin/ci-regression full run launched on 2026-09-06 reports T1436, T1437, both T1438 files, T1524, T296, and T301 ok. Its terminal result is exit 137: the guard reported host memory 88.3% reaching the unchanged 88% cutoff during T303 strict semantic JSON and stopped the exact driver/prove/test/compiler tree. The independent process check found no survivors; the exact owned T303 temporary root was removed. Failed T1467 and interrupted T1554/T1595 remain preserved under .4/.5/.6. T303, the remaining Perl tests, the final TAP summary, the VIAL promotion gate, and the mdBook stage were not completed. No full-CI pass is claimed. Re-derivation is full-ci.log plus full-ci.exit; the independently returned exec status and absent process tree falsify a still-running or successfully completed gate. Durability is this task, Git, and full-ci-terminal.json under .artifacts/logs/session-recovery-20260906/, binding the log SHA-256 6bb445ac29ff811b9821901da541d7294d93448557bb9cf0eab1a7b3edc89d47. The host percentage is one guard-reported observation; an independent host-pressure replay was not performed. Unblocking requires the separately owned startup repairs and a complete fresh guarded gate at safe host pressure, with no cutoff increase; .4 policy selection is the next task. RED T313 aborted at line 25 because the three selected getters were not exported. GREEN adds native -q before -p to default and ABC Yosys argv, keeps the unchanged 120-second/8,388,608-byte supervisor ceiling, publishes additive quiet/excerpt metadata, and renders each failed stream through a shared byte-exact first-32,768/last-32,768 excerpt retaining 65,536 tool-output bytes plus a bounded exact omitted-byte marker. T313 proves the exact boundary, boundary-plus-one, independent stdout/stderr, both argv modes, and installed-tool success at Files=1/Tests=6. Real T308 default/ABC validation passes Files=1/Tests=8 with empty quiet success output. The formerly failing exact T1524 workload passes under the RAM guard at Files=1/Tests=4 in 174 seconds without raising capture. T1669/T313 pass Files=2/Tests=10, and the 17-file manifest/section/JSON-round-trip/defensive-copy band passes Tests=26. All 63 book chapters test; the inspected repository-local render contains 98 files/22,280 KiB and is removed exactly beside the session-owned HDL/lowering residue. Fresh task-owned maintained-reference authority accounts for the exact 12-line/780-byte book delta, the Knowledge Card is compacted inside its prior allowance, and no containment ceiling rises. Knowledge Map is current at 1,161 facts/6,322 questions/6,493 occurrences/139 shards. Claim inventory independently agrees at 12,273 numeric lines/1,900 candidates/2,671 constants, and dispositions close 1,900/1,900 with zero gaps/open owners. Decision 0101, contract POD, capability metadata/tests, mdBook guidance, task, Knowledge Card, and derived projections remain aligned; the consumed recovery result leaves full qualification blocked as recorded above.`
  Commit: `a0b7f62d39567cc2e7399b9e43af19af3093670c; f579a078f; HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.3.2: record recovered T1436 pass`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4`
  Status: `done`
  Goal: `Select, implement, and qualify bounded Rust parity subprocess handling.`
  Acceptance: `Diagnose the T1467 pre-main stall with an independent bounded replay; select exact cargo/build/program command identity, repository-local artifact ownership, finite wall/capture bounds, process-group cleanup, failure preservation, and hostile-test coverage using the existing sealed supervisor architecture; split implementation into a separate child before changing the test or adding a policy adapter. Do not waive Rust parity, retry a failed launch into success, or classify the manually terminated full run as green.`
  Verification: `The 2026-09-06 complete guarded recovery run reports both T1438 files and T1436/T1437 ok, then T1467 waits indefinitely in IPC::Cmd::run at line 52. Its cargo-launched rust/target/debug/fsmgen-portable-api-check-smoke child remains before main: a repository-local one-second /usr/bin/sample capture identifies only _dyld_start, no binary-image map, and an idle startup process. The required Knowledge Map queries found the existing parity contract but no startup-hang answer. Git identifies the unbounded test launch in 07d9df7eb. The verified child alone received TERM; T1467 then reported Failed test Rust portable API check projection command succeeds at line 59 and Failed 1/3 subtests. The later host-memory guard stop preserves that failure; no final TAP summary was produced. Stack evidence is in .artifacts/logs/session-recovery-20260906/t1467-process.sample. A separately contained direct replay of the same executable path exits zero with success=true JSON and an absent process group; rust-direct-probe.json records argv and executable/fixture digests. This falsifies a universal binary-startup failure but does not isolate the cargo/test launch chain or erase the failed gate. Child .1 selected the bounded policy, and child .2 implements it with real parity and hostile controls passing; the original failed complete gate is preserved. Full qualification still requires sibling .5/.6 repairs and a fresh guarded run.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4: own Rust parity startup blocker`

  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4.1`
  Status: `done`
  Goal: `Complete the bounded startup audit and select the Rust parity subprocess policy from independent contained launch evidence.`
  Acceptance: `Record the approved bounded bootstrap scope, compare the selected policy templates, inspect the runtime import closure, independently replay the Cargo/test launch boundary with fixed wall and capture limits, select exact command and artifact identity with failure-preserving cleanup, and leave implementation owned by sibling .2.`
  Verification: `The director confirmed decision 0047 and bounded startup scope. Required policies, roadmap, CLI/facade/source orchestration, Rust crate/projection/T1467, shared supervisor/policy, and relevant mdBook were read. Module::ScanDeps and an independent literal use/require traversal agree on 266 reachable project files; every traversed path is now represented in the refreshed import note. Counts are a dated capture; older line measurements remain explicitly historical. README policy and containment are locally adopted; the current guide includes the committed surface-count delegation update. The selected claim template changed from the local adoption hash; proposed CLAIM-VERIFICATION-TEMPLATE-REVIEW.1 owns deliberate review, without automatic adoption. The task-local policy under decisions 0087/0101 selects sealed tool resolution, offline local build, exact artifact admission, separate oracle/program execution, fixed bounds, and failure preservation. Bounded Cargo run, fresh isolated build, direct Rust, and validated Perl controls pass with absent groups, and their normalized parity fields agree. The diagnostic relative-Perl directory exec_error remains failed; an empty stdin-fed guard invocation produced no replay evidence. The prior T1467 gate failure is not reclassified and the OS startup cause remains unknown. The exact diagnostic build is removed after count/byte/hash capture in .artifacts/logs/rust-parity-policy-20260906/build-cleanup.json. Guarded T1669 passes Files=1/Tests=4; task integrity and diff hygiene pass. The complete staged doctrine driver passes, including Knowledge Map, claim inventory/dispositions, containment, locality, and task integrity; its docs-only acceptance exemption is not an implementation pass. At selection, the adapter and hostile watcher remained an explicit missing implementation/durability leg under sibling .4.2; no product behavior or mdBook support boundary changes.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4.1: select bounded Rust parity stages`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4.2`
  Status: `done`
  Goal: `Implement and qualify the selected sealed Rust parity runtime adapter and T1467 launch path.`
  Acceptance: `After sibling .1 selects the contract, preserve every normalized parity assertion, seal executable identity and repository-local stores, supervise build/oracle/program stages under fixed finite limits, reject hostile path/argument/policy changes, preserve first failure and split-stream signal/cleanup truth, synchronize the mdBook, and pass focused parity plus shared-supervisor regressions without residue.`
  Verification: `The sealed RustParityRuntime reuses the shared test supervisor, resolves validated Perl/Cargo/rustc identities from the initial absolute PATH, unwraps rustup through bounded exact tool queries, restores the caller environment, and fixes offline locked build/oracle/direct-program stages. Each call builds into a fresh owned directory under .artifacts/build/rust-parity, rejects symlink ancestry and stale/outside/ambiguous/decoy artifacts, preserves ordered split-stream status and group-cleanup evidence, and stops at its first failure. Build policy is 120 seconds/8,388,608 bytes; other launched stages use 10 seconds/1,048,576 bytes. These are selected bounds, not capacity measurements. The initial T1810 RED reports missing RustParityRuntime at line 11. T1467's parity_projection and helpers are byte-identical to the previous commit. Final guarded T1467/T1669/T1810 is All tests successful, Files=3/Tests=13, Result: PASS. The hostile controls cover unavailable/directory tools, failing and misleading rustup resolution, PATH mutation, rejected caller arguments, exact local argv/environment, malformed/duplicate/decoy/outside/symlink/non-executable artifacts, nonzero/signal/exec/overflow/timeout truth, and TERM-resistant descendant removal. Every verified build workspace is removed. All changed Perl/test sources are syntax-clean, all 63 book chapters test, and the updated parity guidance renders successfully. The mdBook destination mistake was immediately task-owned and recovered by exact copy/size/hash/use/delete verification; both old and reviewed local outputs are absent. Fresh maintained-reference authority records the 17-line/875-byte book delta without changing ceilings. Claim census independently agrees at 12,274 numeric lines with unchanged 1,900 candidates/2,671 constants; the final staged driver reports [doctrine] all doctrine checks passed, including fresh implementation task acceptance. Prior full-CI failure remains failed; .5/.6 and fresh complete qualification remain open. Commands and supporting logs are under .artifacts/logs/rust-parity-policy-20260906/.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.4.2: bound Rust parity build and execution`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5`
  Status: `active`
  Goal: `Select bounded live-document verifier execution and fixture-launch policies.`
  Acceptance: `Diagnose T1554's repeated pre-main shell stalls and distinguish fixture identity from the neutral checker's unbounded core-verifier wait; select finite process/capture/cleanup and failure-preservation contracts without importing FSMGen policy into the portable checker; split implementation into owned children before source changes. Preserve the interrupted full-run failure and do not retry it into success.`
  Verification: `The 2026-09-06 complete recovery run reached T1554 after T1553 passed. Its repository-local bin/freshness shell stayed before main in _dyld_start; a one-second OS sample shows no loaded binary-image map. TERM to that verified child advanced the same checker to bin/version, which independently stalled at the same sampled boundary. Knowledge Map queries found no startup answer. git log -S traces execute_core_verifier's system plus waitpid without a wall to 25c815326630d49a457d4393909fad8d659c753d; T1554 run_checker also uses open3, sequential stream reads, and unbounded waitpid. The verified T1554 test and its remaining descendants received TERM; a subsequent process check found no survivors. The partial TAP says All 5 subtests passed but has no terminal plan and is not a successful test. The suite continued at T1555, then the later host-memory guard stop prevented a final TAP summary. Samples and exact terminated process identities are retained under .artifacts/logs/session-recovery-20260906/t1554-*. Re-derivation is the first shell sample and launch-source/history inspection; falsification is the independent next verifier stalling after first-child termination, ruling out a freshness-body-only explanation without diagnosing the OS cause. This task, the containment fact card, and Git own durability. No checker/test behavior is repaired.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5: own live-document verifier startup blocker`

  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.1`
  Status: `blocked`
  Goal: `Select portable process-mechanism reuse and sealed core-verifier/fixture policies.`
  Acceptance: `Inspect the neutral contract and exact fork/system/wait/input paths, independently contain the original T1554 test, preserve earlier interrupted evidence, select one physical process engine without project identity in the portable component or a new public runner, and specify fixed bounds, input/path admission, direct fixture interpreter identity, compatibility, migration and hostile checks before implementation.`
  Verification: `The bounded original T1554 replay passes once with all 18 terminal subtests, but independent nested-group falsification proves that an outer timed_out result can report leader_reaped=1/group_gone=1/surviving_descendants=0 while the inner separately grouped child is still alive. Explicit TERM to the exact escaped group succeeds and absence is verified. The portable extraction and fixture/core policies below are provisional, not accepted for implementation. This expands beyond a safe verifier-launch slice: child .5 owns the prerequisite nested-supervision containment design, implementation and hostile qualification. Decisions 0087/0101 remain unchanged. All diagnostic groups are gone; no source implementation changed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.1: record nested supervision containment blocker`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.2`
  Status: `pending`
  Goal: `Extract the existing process mechanics into a private project-neutral component.`
  Acceptance: `Move the shared engine without copying it; preserve the FSM support facade caller seals, repository validation, results and existing test/HDL policy; prove mechanical equivalence and focused regressions, update import architecture and package dependency guidance, and commit before adding neutral checker behavior.`
  Verification: `Pending sibling .1 policy selection and preceding implementation dependency.`
  Commit: `pending`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.3`
  Status: `pending`
  Goal: `Bound T1554 fixture execution and its finite coverage input.`
  Acceptance: `Add the sealed fixture adapter, exact canonical interpreter handoff, finite repository-local input-file transport and fixed test walls/capture; preserve all fixture assertions and coverage/adapter-proof semantics, reject caller policy/path mutation, extend the exclusive-owner and hostile cleanup watchers, and leave standalone checker behavior to sibling .4.`
  Verification: `Pending sibling .1 policy selection and preceding implementation dependency.`
  Commit: `pending`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.4`
  Status: `pending`
  Goal: `Bound standalone neutral core-verifier execution using the selected shared mechanics.`
  Acceptance: `Add a neutral core-verifier policy with fixed finite bounds, root-relative same-volume non-symlink admission, separate bounded output, signal/exit/timeout/cleanup truth and no retry; preserve the existing success and failure contracts, prove relocated neutral-package operation and hostile behavior, synchronize the portable contract/adoption guide/book, and rerun focused containment and process regressions.`
  Verification: `Pending sibling .1 policy selection and preceding implementation dependency.`
  Commit: `pending`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5`
  Status: `active`
  Goal: `Resolve nested process-group containment before introducing supervised neutral core verifiers.`
  Acceptance: `Select an ownership model that cannot lose a separately grouped child when an outer supervisor times out or terminates its inner supervisor; implement the selected design without weakening existing caller, status, bound, locality or cleanup contracts, and prove hostile nested cancellation and current adapters.`
  Verification: `The .1 diagnostic proves a live inner group after outer group cleanup; its exact process was subsequently terminated and verified absent.`
  Commit: `pending`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.4`
  Status: `done`
  Goal: `Reject failed child process-group establishment before command execution.`
  Acceptance: `Inject nonthrowing setpgid failure and false success in the existing hostile watcher; require an exec_error with no command output, exact leader cleanup and no unrelated group signal. Check the POSIX return and actual child group before exec; preserve caller seals, result schemas, fixed bounds and existing adapter behavior. Nested ownership remains separately blocked.`
  Verification: `The direct invalid-PID POSIX oracle returns undef/ESRCH without throwing; git log -S traces the ignored return to b253263c847a2ac641f9cae14603d28d1a755122. T1669 is RED on the unchanged engine: undefined, negative and false-success injections execute the command; the exception control already rejects. The child now requires a defined zero return and its own PGID before exec. Guarded T1669/T1668/T1545 each report ok; that combined invocation then rejects a mistyped T313 filename and is retained as incomplete. The corrected standalone T313 reports All tests successful. The mdBook builds and its rendered admission paragraph is inspected. Source import closure agrees with the existing dated baseline, so the architecture note is unchanged. Logs are under .artifacts/logs/process-group-admission-20260907/. Nested group escape, neutral policy acceptance and complete CI remain open.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.4: reject failed child group admission`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.5`
  Status: `done`
  Goal: `Keep post-KILL leader reaping inside the existing finite cleanup grace.`
  Acceptance: `A controlled oracle must reject blocking waitpid and keep a simulated unreapable leader/group explicitly incomplete; use monotonic nonblocking polling within the existing KILL grace, preserve real signal/exit/cleanup behavior, and pass focused process/adapter regressions before resuming nesting policy.`
  Verification: `git log -S traces the blocking post-KILL wait to b253263c847a2ac641f9cae14603d28d1a755122. The isolated T1669 oracle mocks signals and wait status, advances a monotonic clock and rejects blocking waitpid without creating an unkillable child. It goes RED against the prior source, then GREEN after leader reaping and group disappearance share the existing KILL-grace polling loop. An unreapable leader and surviving group remain explicitly incomplete. The guarded real-process/adapter band T1669/T1668/T1545/T313 reports All tests successful. Book, fact card and exact reference authority are synchronized. Evidence is under .artifacts/logs/process-reap-deadline-20260907/. This bounded-wait repair does not close nested ownership or complete CI.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.5: bound post-KILL leader reaping`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.1`
  Status: `done`
  Goal: `Select compositional ownership and cancellation semantics for nested supervisors.`
  Acceptance: `Compare a single outer group owner, coordinated nested group ownership, and an explicit supported nesting boundary; identify cancellation, signal propagation, forced termination, descendant discovery, race and orphan handling; select a finite independently testable contract under decisions 0087/0101 before source changes.`
  Verification: `The task-local selection compares shared outer groups, intermediate group registration, one root launch coordinator and refusal of nesting against the retained escaped-child counterexample and current Rust/HDL adapter contracts. It selects coordinator-owned launch records and direct child ownership, private cooperating clients, finite admission, explicit logical parentage, failure-preserving results and complete cancellation before success. It names root-owner loss and deliberately unregistered execution as limits, and requires independent process probes rather than internal counters. This expands beyond a safe verifier-wrapper slice; .2 is decomposed into protocol, extraction, coordinator, client and closure leaves, followed by independent .3 qualification. The current nested guarantee remains unimplemented and neutral verifier acceptance stays blocked.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.1: select nested launch ownership`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2`
  Status: `active`
  Goal: `Implement the selected nested-supervision ownership contract.`
  Acceptance: `After sibling .1 selection, preserve the initial failed reproduction, implement the exact selected containment boundary with no new unrestricted test runner, and prove that outer failure cannot report complete cleanup while an owned inner group survives.`
  Verification: `The architecture is selected; the expanded implementation requires the exact child sequence before neutral-verifier integration.`
  Commit: `pending`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.5`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1`
  Status: `done`
  Goal: `Specify the private coordinator wire, resource and lifecycle contract.`
  Acceptance: `Select exact framing, stream/backpressure bounds, run/job/parent identities, inherited-context admission, endpoint locality and long-path handling, spawn publication, cancellation ordering, identity retirement and closed result reconstruction. Define a finite state machine and hostile oracle for every transition before process code changes; preserve existing adapter limits and caller contracts.`
  Verification: `Child .1 qualifies current-host core-Perl identity reservation. Child .2 selects the exact private wire, context, resource, lifecycle and result contract below, with explicit implementation and independent-oracle obligations. No production coordinator or expanded nested guarantee is enabled.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1.2: specify private coordinator protocol`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1.1`
  Status: `done`
  Goal: `Qualify a reserved process-group identity without adding a native binding.`
  Acceptance: `Use an isolated bounded real-kernel oracle to prove that a coordinator-owned child can establish a group, admit a separately forked command, leave that group while retaining its PID, and keep the command group independently signalable until cleanup. Retain both direct children until their last signals, preserve the caller group, reap exact children, and qualify success and cancellation without claiming the production coordinator exists.`
  Verification: `T1669 independently forks a group-reservation child and command as direct children of a bounded oracle. Normal completion and TERM cancellation preserve the actual command wait status, leave the caller group untouched, prove the command group absent while the reservation is still alive, then reap both exact children. An unmoved-reservation control fails at the actual group-absence check and removes both children. Its initial END-block reaping accidentally changed the intended failure exit; direct Perl controls isolate this and local $? repairs the fixture. The guarded T1669/T1668/T1545/T313 band reports All tests successful. Logs are under .artifacts/logs/nested-group-reservation-20260907/. This is current-host design feasibility, not production nesting, Linux qualification or a measured PID-reuse incident. The exact wire/lifecycle contract remains pending under sibling .2.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1.1: qualify reserved group identity`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1.2`
  Status: `done`
  Goal: `Finish exact coordinator framing, inherited execution context, bounded queues and lifecycle transitions.`
  Acceptance: `After the reservation oracle, specify byte-exact argv/environment transport, repository-local long-path-safe IPC, closed identities/messages, fixed finite connections/frames/jobs/depth/queues, monotonic cancellation and result reconstruction. Include oracle obligations for every partial publication, disconnect, identity retirement and cleanup transition before production extraction.`
  Verification: `The task-local private coordinator protocol specifies binary byte framing, run/parent authority, long-path-safe local IPC, bounded snapshots/queues/jobs/descriptors, per-call environment and umask, monotonic admission/cleanup/delivery, reserved group lifetime, closed result reconstruction and independent transition oracles. Inspection covers the shared engine and existing sealed Rust/HDL/test adapters; current book limitations stay accurate. Guarded initial and staged doctrine checks plus diff hygiene validate this design-only slice; logs are under .artifacts/logs/nested-coordinator-protocol-20260907/. Runtime implementation, hostile qualification and Linux evidence remain explicitly missing under following owners.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.1.2: specify private coordinator protocol`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.2`
  Status: `done`
  Goal: `Extract the shared process state machine without changing current callers.`
  Acceptance: `After .2.1, separate launch, bounded stream polling, wait status, termination and result construction into one reusable asynchronous mechanism; retain a synchronous compatibility entrypoint and prove current success/failure/timing/cleanup shapes and both prerequisite fixes before coordinator integration.`
  Verification: `After protocol commit e4dcb66ba, the existing shared owner separates private launch, nonblocking capture, nonblocking TERM/KILL advancement, terminal result construction and synchronous waiting. Public exports, caller sealing, adapter bounds, schemas and result fields remain unchanged; no coordinator routing is enabled. T1669 independently traps sleep and blocking select inside advancement, proves both traps with failed controls, retains binary split output and timeout/escalation truth, and checks actual command/group absence after each oracle. The existing unreapable-leader and failed-admission controls remain green. Syntax and guarded T1669/T1668/T1545/T313 pass; initial and final evidence is under .artifacts/logs/process-async-extraction-20260907/. The book's own-group-only limit remains accurate. Staged doctrine and hook checks gate this slice before commit.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.2: extract asynchronous process advancement`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3`
  Status: `active`
  Goal: `Implement root-owned launch records and bounded private IPC service.`
  Acceptance: `After .2.2, create each supervised child only from the surviving coordinator; record ownership before exec release; enforce the selected finite requests/connections/queues/jobs and repository-local endpoint contract; reject malformed or unauthorized context before launch and prove partial-start cleanup without a public runner.`
  Verification: `Source review after asynchronous extraction 51a3a3914 confirms that _start_supervision still forks and releases exec immediately, while the selected coordinator requires separately qualified byte transport, endpoint/cwd transactions, two-child reservation handoffs and ownership publication before release. These are independent failure domains and exceed one safe implementation slice. Decompose them before process changes; nested routing and end-to-end cancellation qualification remain sibling owners.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3: split coordinator implementation boundaries`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.4`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1`
  Status: `active`
  Goal: `Implement and qualify the private bounded coordinator wire codec and execution snapshot.`
  Acceptance: `Implement the selected closed frame/message grammar, canonical byte scalars, ordered environment, metadata and fixed resource admission without launching a coordinator. Qualify byte-exact argv/environment conversion against an independent direct-exec oracle, not only codec round trips. Reject truncated/oversized/unknown/direction-invalid frames, duplicate or malformed keys, invalid contexts and boundary-plus-one inputs before allocation or command execution. Keep runtime activation and public contracts unchanged.`
  Verification: `The private wire and execution snapshot are implemented under child .1 with independent direct-exec and hostile byte/frame evidence. The final broader run fails the unchanged T1545 docs-only fixture with empty output; run_checker discards the structured supervisor failure, preventing diagnosis from the retained run. Child .2 owns that newly exposed diagnostic defect and qualification prerequisite. Do not promote the failed band or enable coordinator routing.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.1: implement bounded private coordinator wire`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.1`
  Status: `done`
  Goal: `Implement the selected private codec and execution snapshot without runtime activation.`
  Acceptance: `Retain the exact byte grammar and finite admission, prove literal independent frame vectors and direct-exec argv/environment parity, reject malformed and over-bound inputs, preserve caller state and public process paths, and retain any broader qualification failure under an explicit following owner.`
  Verification: `Wire.pm adds no process or socket creation and no public export or production import. T1669 qualifies every message type with independently constructed frames, every truncated prefix, malformed direction/version/field/vector/key/context, scalar/vector/aggregate/integer boundaries, actual producer RESULT metadata and hostile mutations. The existing direct exec independently confirms byte/Unicode arguments, live ENV magic, empty versus absent values and umask; deliberate double encoding changes child-visible bytes and fails that oracle. Syntax and final guarded T1669 pass. T1668 and T313 pass in the final broader run, but T1545 fails its first subtest with empty output; that band remains failed. Source diff proves its test, adapter, wrapper and shared engine are unchanged; git pickaxe identifies the lost-diagnostic projection at d630261e6. Child .2 owns diagnosis and qualification. Logs retain the initial endpoint-fixture off-by-one, corrected focused result, mistaken T313 filename and corrected band without promoting earlier failures. Book nested-cleanup limits and current CLI import architecture remain accurate; startup policy comparisons match the already tracked template revision. Staged doctrines and commit hooks must pass before this implementation checkpoint commits.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.1: implement bounded private coordinator wire`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2`
  Status: `active`
  Goal: `Expose and diagnose T1545 infrastructure failure before closing wire qualification.`
  Acceptance: `Preserve the original failed run, retain complete supervisor diagnostics without altering checker assertions or sealed policy, and qualify the launch boundary only after the unexplained failure has an evidence-backed disposition.`
  Verification: `Child .1 repairs and independently qualifies diagnostic preservation. Its instrumented T1545 run and focused shared-supervisor band pass without reproducing the earlier empty-output failure. The original invocation discarded its structured result and left no retained child identity or process sample; its runtime cause cannot be recovered from final-regression.log. Child .2 owns prospective launch evidence and qualification. The original failure remains failed and parent wire qualification remains open.`
  Commit: `pending child .2 qualification`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.1`
  Status: `done`
  Goal: `Preserve complete T1545 checker failure diagnostics separately from checker-output assertions.`
  Acceptance: `A real deliberately failing bounded checker must expose its complete closed result with empty and nonempty streams; prove the control RED on the discarded-result helper, preserve all original checker assertions and resource bounds, and pass focused supervisor regressions and synchronized documentation gates.`
  Verification: `git log -S locates the discarded-result projection at d630261e6. New real Bash exit-23 controls fail against the old run_checker, then pass after canonical JSON TAP diagnostics and the original structured record are retained. They independently check actual exit/signal, split streams, timings and cleanup while exact decode equality proves complete record preservation. The instrumented T1545 run and guarded T1669/T1668/T1545/T313 band report All tests successful. These fresh observations do not diagnose the earlier invocation. The book and existing fact card state that limit. CLI source/import review agrees with the dated architecture baseline; selected claim-template digests match the already tracked review debt. Evidence: .artifacts/logs/task-acceptance-diagnostics-20260907/. The mdBook builds and its rendered diagnostic paragraph is inspected. The claim inventory and independent census agree; the historical qualification disposition follows its explicitly dated paragraph. Existing Knowledge Map aggregate allowance is renewed by the prescribed ratchet steps under the active parent owner; no enforcement ceiling changes. The guarded staged doctrine driver reports all doctrine checks passed, including fresh task acceptance; hooks recheck the final staged evidence on commit.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.1: preserve checker failure diagnostics`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2`
  Status: `active`
  Goal: `Capture and qualify the unexplained T1545 launch boundary before closing wire qualification.`
  Acceptance: `Keep .artifacts/logs/coordinator-wire-20260907/final-regression.log failed and distinguish unavailable historical evidence from a reproduced runtime cause. Select a bounded observation path for actual checker process identity and startup/main progress before another diagnostic attempt; preserve sealed commands, fixed limits and original fixture assertions. Use captured recurrence to own a concrete runtime repair, or explicitly establish the remaining qualification limit without claiming retry-based recovery. Endpoint implementation remains behind this leaf.`
  Verification: `The original T1545 failure lacks retained structured status, child identity or process samples and remains unexplained. Child .1 independently repairs fabricated handoff timing and documents why control-pipe EOF cannot prove main entry. Child .2 qualifies prospective identity/startup observation but its broader band fails at unchanged Rust and Verilator fixture launches. Child .3 owns those concrete startup failures; no fresh passing run diagnoses the historical invocation or enables endpoint implementation.`
  Commit: `pending`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.1`
  Status: `done`
  Goal: `Qualify and repair inferred exec-handoff timing before using it as launch evidence.`
  Acceptance: `Use an independently controlled real child held before exec to test whether timeout completion fabricates a handoff timestamp. Preserve an unobserved handoff and its dependent durations as unknown; retain observed control-pipe timing on successful commands. Qualify early child death separately from successful exec and document the exact observation boundary. Preserve fixed bounds, sealed commands, schemas, failure and cleanup truth; run focused RED/GREEN and adapter checks, synchronize book/fact evidence, and commit before prospective T1545 observation.`
  Verification: `The independent pre-exec child control goes RED on the prior engine: timeout cleanup invents a handoff and dependent durations. git log -S traces the fallback to b253263c8. Removing completion-time inference leaves absent capture evidence unknown; the successful-output control retains observed timing, while a direct pre-exec exit proves EOF alone cannot establish main entry. Syntax and the corrected guarded T1669/T1668/T1545/T313 band pass with All tests successful. The initial sandbox run could not inspect processes; the first GREEN band completed its existing tests but rejected a mistyped T313 path and remains incomplete. The mdBook builds, its rendered timing paragraph is checked, and the exact build root is removed after identity capture. The book and existing fact card describe the observation limit; literal import traversal finds no unresolved import or source path absent from the current architecture note. Evidence is under .artifacts/logs/handoff-evidence-20260907/. This repairs diagnostic truth, not the historical T1545 cause; sibling .2 retains prospective observation and qualification.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.1: preserve unobserved handoff timing`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.2`
  Status: `done`
  Goal: `Select bounded checker identity and startup observation, then qualify the T1545 launch boundary.`
  Acceptance: `After timing-evidence qualification in sibling .1, select a bounded observation path for actual checker identity and startup/main progress before another diagnostic attempt. Preserve sealed commands, limits, fixture assertions and the original failed log. Capture recurrence under a concrete repair owner or retain the explicit qualification limit without retry-based recovery. Endpoint implementation remains behind this leaf.`
  Verification: `T1545 now retains a separate bounded launch record through test-private read-only state observation. Bash independently reports the same child PID; unmodified checker output establishes native progress; unrelated output and a pre-exec held child falsify invented progress and retries. RED fails on the old helper; the updated T1545 and unchanged T313 pass in the broader band, which remains failed because T1669 Rust proxy and T1668 Verilator fixtures time out. A live one-second sample locates T1668 orphaning-runtime at _dyld_start before main; the OS cause and earlier T1545 cause remain unknown. No shared engine, adapter, command or bounds change. The book builds and its rendered observation/qualification paragraphs are reviewed; exact disposable output is removed after identity capture. Recorded checker/watcher/sampled child PIDs are absent. Logs, source identity proof and sample: .artifacts/logs/checker-launch-observation-20260907/. Sibling .3 owns diagnosis and repair before broader qualification.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.2: retain bounded checker launch observations`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3`
  Status: `active`
  Goal: `Diagnose and repair newly observed Rust and Verilator fixture startup timeouts before qualification.`
  Acceptance: `Retain the failed .2 regression unchanged; inspect available child identity and bounded operating-system startup samples before retrying. Distinguish the direct fixture launch path from fixture body and policy behavior, select a bounded repair with an independent failing control, preserve exact production tool identity and all sealed bounds/assertions, and split any change beyond a safe slice before implementation. A fresh passing run cannot erase the initial failed invocation or establish the missing historical T1545 cause.`
  Verification: `Child .1 completes the bounded historical/source/launch investigation without reproducing the failure or identifying a safe repair. The original failed regression remains failed, and the fresh observed band passes without explaining it. Child .2 owns the unresolved causal startup evidence and approved host-policy experiment. Child .3 selects targeted native kernel/user sampling; child .4 owns administrator-assisted capture before repair selection. Child .5 rejects a thread-state-only substitute after its independent stop control fails. Child .6 prepares the normal-user authenticated sampling session; child .7 captures an AppleSystemPolicy wait, verifies shutdown and returns a permission-experiment decision to child .2. The director-approved iTerm2 permission experiment in child .2 passes its unchanged band but still observes exact-fixture XProtect scanning; no production command, fixture, limit or assertion changes. Parent wire qualification remains open.`
  Commit: `pending causal repair`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.1`
  Status: `done`
  Goal: `Inspect historical startup evidence and challenge the shebang and shared-supervisor hypotheses before selecting a repair.`
  Acceptance: `Read the retained failure and live sample before another attempt; compare shebang and explicit-interpreter startup through shared and independent launchers, observe the unchanged focused band, preserve each invocation outcome, and record evidence limits without promoting a retry or inventing a correction.`
  Verification: `The retained census and startup-7768.sample identify orphaning-runtime at _dyld_start, correcting this node's former nonzero-runtime attribution. A fixed body printing body-entered succeeds through the shared supervisor and Python subprocess, with both script-shebang and explicit /usr/bin/perl invocation. These exploratory arms do not reproduce the failure; they share a body/path and are not independent cold-start oracles. Their ignored instruments are not durability-qualified and support no timing, reliability or root-cause claim. The narrow historical OS query returns no matching records. An external read-only observer runs the unchanged T1545/T1669/T1668/T313 band under the configured RAM guard: All tests successful; the guard also exits zero. No targeted fixture survives long enough for sampling. The initial guard-census selector missed the executable naming and is rejected as evidence; the corrected census and final exact-PID check find no remaining observed process. Evidence and identity manifest: .artifacts/logs/fixture-startup-20260907/. Startup review follows SESSION-READING-SCOPE; literal CLI imports resolve and occur in the architecture note, selected claim-template hashes match existing review debt, and the containment guide already carries the current portability amendment. Product/book behavior is unchanged. The guarded staged doctrine driver reports all doctrine checks passed, with the documentation-only task-acceptance exemption; git diff --cached --check passes. The commit hook rechecks the final evidence. No implementation fix or complete qualification is claimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.1: retain bounded startup investigation and causal blocker`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2`
  Status: `blocked`
  Goal: `Capture a causal fixture-startup failure and select a bounded repair before wire qualification.`
  Acceptance: `Obtain a recurrence with exact live child identity, executable/fixture identity, independent process state and bounded startup sample sufficient to separate fixture-body, supervisor and host-startup causes. Preserve the first failed result. Select and independently falsify a project-correctable repair; split deeper host instrumentation or architecture changes into a reviewed slice before implementation. A later passing run cannot close this leaf.`
  Blocked by: `Startup timeout causal evidence and an independently falsified repair remain missing; permission and fresh shell/Codex prerequisites are satisfied. The director approved inactive endpoint implementation after verified private Wire .3.1.1, recorded by HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.1. This removes only that implementation dependency; parent wire qualification, this incident, runtime activation, complete CI and push remain blocked. No failed result is waived, timeout repair claimed, extra host-security change authorized or repeated passing diagnostic substituted for causal evidence.`
  Verification: `Prior permission/provenance observation is preserved in this exact leaf at c3f6475637db8bfe5d488a19a255101edce81f88: approved iTerm-only permission on, Terminal/Tracing off; unchanged band passes while exact-fixture XProtect scanning persists; TCC query empty; native cleanup consumed; rejected stdin-only query, installed-xattr fallback and unavailable historical fixture metadata retained. The canonical subprocess fact retains exact prior scan/capture identities. Apple process-tree paste inspection and DTS repeat-run cautions do not prove applicability, bypass or a restart requirement. Fresh-launch control: native Codex PID 16937 (1788791393.880957) and shell 37861 (1788791321.503862) differ from old Codex 23425 (1788776699.745556)/shell 31921 (1788653434.708176); login 37767 still descends from the existing iTermServer 10517. This is a new shell/Codex control, not a new app, machine or cold cache. Read-only Settings verification finds iTerm on, Terminal/Tracing off. The single unchanged guarded band reports All tests successful, Files=4, Tests=36; its deliberate pre-exec timeout is a passing negative control. T1668 orphaning-runtime PID 72555 (1788792022.901244), parent 72494, is /usr/bin/perl on .artifacts/tmp/tests/wun0CS39LV/orphaning-runtime with sibling .7's exact digest. Live xattr reports provenance 010200fd5101f2392ba1db and no quarantine; older fixture metadata remains unrecoverable. The invocation-window query (16:39:53 through 16:40:38 +0200) binds exact scan token e0b722d88ddbf34e from queue 16:40:22.923572 through XProtect results 16:40:23.137647 and waiter wakeup 16:40:23.137826; provenance names PID 72555 at 16:40:23.138811. This independently rejects scan-elimination inference after the fresh launch; it does not establish original cause, timing improvement or repair. All observed births are gone, with independent guard 70277 (1788791993.051443)/observer 70276 (1788791993.003798) ESRCH checks. Evidence: .artifacts/logs/fixture-fresh-terminal-20260907/; regression SHA-256 e8b2f5176e445f0560cd133cb3d1dc31806f367405dd3fa75801034ea05c9f49, events 23174cea6fab9e4a447c9d2d823aa5e18cb13bc0c42bda73131ba182b55d25a3, exact policy 1234ac21a296f5620ff527593b5023dc8f33ecd5e163efcd52594ed180193b8a. Native identity/test output re-derive the observation; exact OS records falsify bypass; task/book/fact/Git retain its durable meaning and identities, with ignored raw logs/scratch producers an explicit durability gap. The initial mdBook destination was incorrectly relative to the book instead of the invoking root; its exact generated directory landed outside the repo on the same volume. Copy/verify/use/delete compares file sizes and SHA-256, then the corrected root-relative build and rendered paragraph review succeed and the exact old-directory residue is absent; book-relocation.json retains the census. Book, map/census and corrected staged doctrines pass, including fresh task acceptance; the commit hook rechecks the final evidence. No host setting, fixture, interpreter, assertion or limit changes in this observation. The later independently owned RAM-guard harness repair is committed separately at aacd8d5576449ee0996f462cd2c8f800e162f3be; it does not close this incident. A read-only frontier review finds neutral-verifier implementation behind nested containment, endpoints behind wire qualification, continuity .12 behind director-deferred .26, ISF closure behind complete CI, and IAL2 .844 terminal. The later director approval is recorded in endpoint .3.2.1; causal repair and qualification remain open. This documentation-only handoff passes staged doctrines and diff hygiene; the hook rechecks final evidence. Logs: .artifacts/logs/fixture-endpoint-decision-20260907/. Full CI and push remain blocked.`
  Commit: `28836d8e21abe3151c99cec5ce5786328d1758de permission checkpoint; c3f6475637db8bfe5d488a19a255101edce81f88 provenance handoff; this fresh-launch observation; causal repair pending`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.3`
  Status: `done`
  Goal: `Qualify bounded host wait-state diagnostics before another fixture-startup observation.`
  Acceptance: `Compare the retained user-stack-only failure evidence with native diagnostic capabilities. Probe read-only process/thread state and targeted user/kernel sampling on an exact owned live process, with repository-local output and finite time bounds. Preserve unavailable permissions and unknown causes explicitly. Select only diagnostics that add a discriminator; do not repeat passing regression for qualification, alter host security, change tool identity or widen production limits. Record an executable next investigation or an exact external prerequisite and commit this bounded selection before further implementation.`
  Verification: `The retained orphaning-runtime sample contains only _dyld_start and no kernel wait chain. Native ps succeeds outside the sandbox but reports no named wait channel for the owned control. The installed spindump help advertises user/kernel stacks, onlyTarget, noFile, noBinary and a finite timelimit. A targeted owned-process probe rejects live sampling with exit 77 because root is required; sudo -n rejects with a password-required diagnostic. Neither probe sampled another process or changed host settings. Logs are in .artifacts/logs/fixture-wait-state-20260907/. Startup review follows SESSION-READING-SCOPE; selected claim-template identities match existing review debt, and the containment guide includes the current portability amendment. The existing book accurately retains the unknown cause and open qualification. The guarded staged driver reports all doctrine checks passed, including task integrity and the documentation-only task-acceptance exemption; git diff --cached --check passes. The hook rechecks final evidence before commit. No runtime repair or qualification is claimed.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.3: select targeted kernel wait-state evidence`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.4`
  Status: `done`
  Goal: `Capture targeted native kernel and user wait evidence during a fixture-startup recurrence.`
  Acceptance: `With administrator-assisted sampling available, observe one bounded unchanged focused invocation under the configured RAM guard. Bind the live target to that invocation by ancestry, executable, fixture and fresh identity before sampling only that target. Keep all output repository-local, retain every original result, bound diagnostic duration and verify sampled-child and observer cleanup. Use the kernel/user evidence to distinguish a repairable cause or preserve the remaining unknown explicitly; return causal repair selection to sibling .2. Do not execute tests as root, repeat passing runs for qualification, widen limits or alter host security.`
  Verification: `The unchanged guarded band in checkpoint 0ba272cc3 passes without recurrence. Sibling .7 subsequently captures an identified fixture waiting inside AppleSystemPolicy and correlates its exact path with syspolicyd XProtect/allowed records. The helper stops with authentication_invalidated true; native census finds helper, guards, observers, sampled target and sampler PID absent. Capture selection and cleanup are complete; historical attribution and repair return to sibling .2.`
  Commit: `0ba272cc3 checkpoint; closure in sibling .7 capture commit`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.5`
  Status: `done`
  Goal: `Test whether unprivileged native thread-state inspection adds a startup discriminator while kernel sampling is unavailable.`
  Acceptance: `Read the installed libproc and Mach declarations, probe native thread-state access on an exact owned controlled child, and distinguish a pipe wait from a waitpid-confirmed stop before interpreting any fixture. Bound process lifetime and every poll, preserve native return/error and child identity, and prove cleanup. If this adds a usable discriminator, select a separately owned bounded diagnostic observation; otherwise preserve the administrator prerequisite. Do not rerun qualification, infer a historical cause or alter production behavior.`
  Verification: `The initial probe fails because list-thread handles were passed to the unique-thread-ID flavor. Apple's producer test identifies the correct pairing. The corrected native call works, but the independent waitpid-confirmed SIGSTOP control still reports the same thread waiting state as its pipe wait. BSD process status changes separately; thread state alone is not the proposed discriminator. Both failed probes and successful exact-child cleanup are retained in fixture-thread-state-20260907. The rejected scratch instrument has an explicit durability gap; no fixture is rerun and no historical cause or repair is claimed. Sibling .4 remains the next blocked frontier.`
  Commit: `this commit (negative native calibration; no runtime change)`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.6`
  Status: `done`
  Goal: `Prepare a user-run authenticated sampler so the director has an executable unblocking step.`
  Acceptance: `Keep authentication and the fixed native sampler in the same user-launched diagnostic session. The director rejects repeated manual commands/authentication: allow sequential bounded capture requests within an expiring, stoppable session after one authentication, with non-interactive refresh and fail-closed revocation. Never run the helper or tests as root. Reject stale/reused or foreign identities, non-fixture paths and invalid ancestry before sampling. Keep output and temporary data repository-local, bound session/request count and sampler lifetime, preserve failed outcomes, and test rejection paths before handing over the command. Record that Computer Use refused Terminal access and that authentication in an unrelated terminal does not authorize agent tool sessions. Actual live kernel capture and test/observer cleanup remain sibling .4.`
  Verification: `The helper runs as the normal user under the configured RAM guard, authenticates through the controlling terminal and accepts fixed numbered capture requests during an expiring session. Fresh native child/parent identities, Perl executable identity, exact T1668 parent command and direct canonical orphaning-runtime source are required before root sampling. Focused Python controls pass, including a real Perl parent/fixture, stale/reused/foreign/racing identities, filesystem redirects/FIFOs, bounded TERM-resistant cleanup, repeated requests, non-interactive refresh, STOP and expiry. A planted interactive-refresh mutation fails the independent session control. Shell/Python syntax and the mdBook build pass; rendered command and shutdown guidance are checked, and the exact unused book output is removed. Source, tests, task, book and fact route are tracked; authentication and actual native kernel capture remain unqualified until sibling .4. Evidence: .artifacts/logs/fixture-capture-handoff-20260907/. No original fixture regression or privileged capture has run.`
  Commit: `this commit (manual authenticated diagnostic session)`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.7`
  Status: `done`
  Goal: `Obtain the first natural startup recurrence within a bounded prospective capture experiment.`
  Acceptance: `Use the still-live authenticated helper after the unchanged band does not reproduce the stall. Predeclare a maximum of twenty unchanged T1668 invocations and a cumulative five-minute wall under the configured RAM guard; stop immediately after any failed invocation or admitted capture, whichever comes first. Bind each candidate to its own live invocation with native birth identity and ancestry. Preserve every iteration and capture result. Never retry a failure or interpret passing iterations as repair, reliability or qualification. Consume native output and exact observed process cleanup; stop and verify the authenticated helper when no authorized capture remains. If no recurrence occurs, preserve that causal gap rather than invent a fix.`
  Verification: `The predeclared campaign stops at its first admitted capture during invocation 6; every retained invocation passes, which is not repair or qualification. Native identity binds PID 22778 (1788787261.244839) to T1668 parent 21913 (1788787240.646851), fixture .artifacts/tmp/tests/eyRjEqbQuI/orphaning-runtime and its retained digest. Target-only spindump exits zero without timeout; its stack passes through AppleSystemPolicy. Information/debug OS logs independently identify the exact fixture XProtect result and script allowed result. Default-level and original-failure-window queries are empty; earlier timeouts remain unexplained. Nearest exported kernel symbols are incomplete, and the installed x86_64 collection is rejected for this arm64e report. Every observed test birth is gone; helper STOP publishes authentication_invalidated true, and independent checks find helper, guards, observers, campaign, target and sampler PID absent. A substring residue selector falsely matches its own inspecting shell; exact command-field census is empty. No root sampler birth identity was retained, so no atomic native-launch authority or universal nested cleanup is claimed. Evidence is in .artifacts/logs/fixture-kernel-recurrence-20260907/ and the named capture session; the fact card retains target identity, report digest, stack offsets and exact-path policy results. Ignored scratch producers and full raw logs remain a durability gap. Native launcher ancestry reaches iTerm2 through Codex CLI, bash and login; read-only System Settings shows iTerm2 absent and Terminal off in Developer Tools. Sibling .2 owns the proposed permission experiment; no setting has changed.`
  Commit: `this commit (authenticated native capture and bounded evidence)`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8`
  Status: `active`
  Goal: `Close the latest T1669 recurrence's missing live identity and causal capture path.`
  Acceptance: `Select and qualify exact diagnostic admission and a tracked bounded observer before a fresh instrumented invocation. Preserve the failed service band, normal-user execution, fixed regression bounds, first-failure truth and original causal repair owner .2. No host-security change or runtime qualification follows from preparing diagnostics.`
  Verification: `The service-band recurrence at 5f8be37f1ac107cc486a9e9c435b33871391e796 lacks exact transient paths, birth identities and kernel waits. Source review identifies T1669's direct rust-tool-resolution and legacy-ram-capture wrappers plus their generated Rust proxy and legacy producer children. The existing sampler admits only a direct T1668 orphaning-runtime child. Children separate the closed admission policy, durable observer and actual administrator-assisted capture.`
  Commit: `pending diagnostic children`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.8, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.9, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.10`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.1`
  Status: `done`
  Goal: `Qualify closed T1669 fixture ancestry admission for the existing native sampler.`
  Acceptance: `Retain T1668 compatibility and fixed native sampling command. Admit only exact T1669 wrapper or producer command shapes derived from the generating source, with at most one intermediate parent, matching normal-user native births/interpreters and one direct repository-volume fixture workspace. Retain every inspected source digest and ancestry identity; reject stale, foreign, reparented, redirected, unrelated or cross-workspace candidates before privileged launch. Prove real controlled process admission and independent hostile controls without sudo, wire portable admission controls into the existing hosted doctrine job, sync the book and commit. Authentication and actual capture remain .8.3.`
  Verification: `The committed T1668-only validator independently rejects the new exact T1669 wrapper/producer controls. The extended closed request retains direct compatibility and allows only one fully identified test ancestor; native births, normal-user ownership, canonical Perl, literal commands, common workspace and bounded stable source identities are checked before sampling. Hostile controls reject stale/reparented/foreign/cross-workspace/redirected/changed-exec candidates without launching sudo. Real controlled T1668 and T1669 wrapper/Rust-proxy processes prove positive native admission; legacy producers have literal-command/filesystem controls, with actual incident capture still pending. The guarded Python watcher passes all 18 tests and exact control-group cleanup. Source syntax and workflow YAML pass. A missing hosted watcher is repaired by adding the existing portable control command to the existing doctrine job; hosted execution remains unqualified until the authorized push. The book builds and generated admission paragraphs are inspected; source, tests, book and exact reference aggregate are synchronized; the existing canonical fact still routes to this task and the book. Original T1669 tests, production adapters/supervisor and the fixed native sampling command are unchanged. Logs: .artifacts/logs/t1669-sampler-admission-20260907/. The ignored raw RED/GREEN logs are supplemental; tracked controls, the exact predecessor in Git and this task retain reproducibility. Staged doctrine completion follows the checklist below; original startup repair and qualification remain open.`
  Commit: `this closed T1669 admission slice`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.2`
  Status: `done`
  Goal: `Track a bounded normal-user observer for one unchanged T1669 diagnostic invocation.`
  Acceptance: `After .8.1, attach without launching or signalling tests, bind the observer to its exact guarded test birth; inspect only the selected fixture ancestry, preserve live process/source identities and original TAP/result, exclude an expected legacy stream wait after its independent main-entry marker, submit at most one admitted fixed sampler request, and stop after the first captured candidate or failed invocation. Bound observation storage and lifetime, preserve all failed outcomes, and prove exact observed-process and helper shutdown. Retain the instrument in Git so ignored scratch producers no longer own the next capture's reproducibility. No retry campaign or causal conclusion is authorized by this leaf.`
  Verification: `scripts/observe_fixture_startup.py attaches to an exact normal-user T1669 birth without launching or signalling the caller-owned test. Closed native ancestry admission retains source identities and exact content-addressed source bytes; nested targets take precedence and a native legacy main-entry marker is rechecked before request publication. Observation, census, identities, event/source storage and cleanup have explicit finite bounds; an independent failure.json survives an exhausted event log. One complete request is published exclusively and the helper now publishes result.json by atomic rename. The observer retains failed outcomes without retry, requests helper STOP and verifies authentication invalidation plus disappearance of that helper and observed fixture births; unobserved descendants and the original TAP/exit remain explicitly outside its authority. Re-derivation: inspect the tracked observer/sampler constants and run the guarded Python discovery command from the hosted doctrine job; all 31 local controls pass. Falsification: the exact pre-slice sampler exposes partial JSON under an interrupted-write reader control; forcing main-entry absence wrongly samples an independently written entered marker. Native Darwin libproc child census matches independently forked children and rejects a deliberately undersized census buffer; the installed SDK libproc.h is a necessary read-only OS declaration, located through xcrun --show-sdk-path. Durability: both Python control files, the observer/sampler, existing hosted doctrine job, book and this task carry reproducible producers and explicit limits; the existing Knowledge Map card routes here. Ignored logs in .artifacts/logs/t1669-startup-observer-20260907/ are supplemental. Syntax/YAML checks, help contract and generated book HTML pass; exact disposable build output is hashed, verified and removed. Actual authenticated capture and hosted execution remain unqualified. No original T1669, production runtime or fixed native sampler command changes.`
  Commit: `this tracked T1669 observer slice`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.3`
  Status: `done`
  Goal: `Capture and inspect a contemporaneous T1669 wait chain before selecting a causal repair.`
  Acceptance: `After .8.1 and .8.2, use an authenticated normal-user helper session for one bounded unchanged guarded invocation. Correlate exact target/test/intermediate births, retained fixture bodies, native wait evidence, main-entry markers and exact-window OS records; distinguish fixture-body, supervisor and host-startup explanations, naming unresolved alternatives. Consume every process/helper result and verify shutdown. Return evidence to causal repair .2; no passing run closes the old failure.`
  Verification: `Previous complete attempt evidence is version-retrievable from 81548f056, 222476ec49c6f56f4550c9b6422f0183f1a2aba6 and 5ddc9438c94945dd67323fda4a0650f153e82272 in this task path. After query-race repair 060f8629935d953b1f31d1a7e754a228c30c6233, director READY supplies session-779a75e874334a60ab9b2112e1b57475, helper 74375 (1788843642.255640), UID/RUID 501 and sampler 3ae0843d817587295322d40344b2ea58de576bd19075b7d6a2c8e9a7bfac9845. One unchanged fixed invocation binds test 80994 (1788843942.206676), source 7e55021faab2a1654a9854355b4fd6f4bb44c1f50887b03f00df8b98eeafbe91. Python monotonic ns records ready 195943111897666, child release 195943112801916 and attach 195943132547541. Observer 2d4f6be43f5d79dda70a47f3866b82c26275aa8dff4320468b9a8b34d98e884c admits six fixture births: Rust wrapper 81391 (1788843951.039461), proxy 81392 (1788843951.067657); legacy signal wrapper 81467 (1788843951.544138), producer 81471 (1788843951.557541); streams wrapper 81546 (1788843951.840881), producer 81547 (1788843951.853775). Each wrapper descends from the exact test and each producer from its named wrapper, in .artifacts/tmp/process-supervisor-tests/fsmgen-NBfTqh9G. Source SHA-256: Rust wrapper df525c2166853a62c81b9a5aa70eea9606e3bd96c88c46f1844c1b4c55c7d2b0; proxy dd39d5015afa146af4ecf8ec60573264ca37e38838d4248a395f9e3b2d3dbff7; legacy wrapper bd13191666dff15eefa7b79dbe3835e114efe6ba741ee6b9258547a4b835143c; signal fe7170a36b7d2507de3a9cad45a16307f51014e5eac386189c122995a827cf1f; streams 830742bb577d3a84d25e773e5b29b7b164e870ac4d9101b5e682e589bc336d3c. The independently enumerated declared digest/size set exactly matches retained source files. An initial scratch census incorrectly searched a nonexistent sources/ subdirectory; its empty result is rejected before this claim. The signal wrapper changes identity during inspection and is rejected without aborting later streams observation. Streams main-entry transitions from not_observed to entered; original signal and streams marker assertions pass. No candidate remains eligible for capture; no request or native sample exists. Original TAP completes 1..14 with native wait/exit zero and empty stderr; caller exits zero, explicitly qualification not claimed. Independent libproc census returns ESRCH for all eight recorded test/helper/candidate births. Helper is stopped with authentication_invalidated true; unobserved descendants remain unknown. Exact-window information/debug syspolicyd records name this workspace's Rust proxy, signal and streams XProtect results at 2026-09-08 07:05:51.288518, 07:05:51.781612 and 07:05:52.098358 +0200. These path-correlated passing-run records are neither kernel waits nor historical cause. Re-derivation: retained native identities, original TAP/wait, source-set/hash verification and exact-window OS query. Falsification: positive main-entry evidence and absent capture reject pre-main-stall, causal-repair and complete-transient-coverage claims. Durability: tracked producers/controls, task/book and Git preserve meaning and identities; ignored raw retention remains a named gap under .artifacts/logs/t1669-race-fixed-capture-20260908/ and run-5dca96b725ff49b0bb2e4a78840ab9b2. Digests: events 01c79110bac3dad711c796fac91f3dba6201741fd198a2b92a612b0a2423283a; TAP fda852d55447f17001c0571e79147a216a33639fb77d2a27b33eeeca6eaefc6d; policy 1d320cf67ca54cb72a69be1240bea355aac143ec81aac5bc15a7125283ae0897. Sibling .8.8 completes native T1669 capture and shutdown; original causal repair and runtime qualification stay open. The director asks why authentication repeats: native spindump requires root, while the single-run observer stops and invalidates the reusable helper after every attempt. Existing .3.6 already selects repeated fixed captures after one authentication; .8.7 owns a bounded sequence controller before further capture.`
  Commit: `this successful-observation and no-capture checkpoint`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.4`
  Status: `done`
  Goal: `Remove the external-tool attachment gap with a tracked ready-before-release diagnostic launcher.`
  Acceptance: `Prepare the qualified observer and helper admission in one guarded normal-user invocation before releasing exactly one unchanged T1669 test. Retain an independent readiness/exec-release ordering witness, exact owned native births, original TAP/exit and bounded failure/cleanup outcomes. Preserve attach-only compatibility and the closed sampler policy; test delayed preparation, stale identity, failed readiness and cleanup without privileged sampling. Keep producer and controls tracked, sync the book, commit, and only then return to .8.3 for fresh authenticated capture. No production coordinator, original regression bounds or host setting changes.`
  Verification: `scripts/run_fixture_startup_observation.py preloads the existing attach-only observer and owns one fixed normal-user T1669 child held behind a pipe. Ready helper identity/cursor, writable evidence and exact child identity precede token release. The child returns its own monotonic release witness before exec; that witness is not exec success or main entry. Native exact-exec admission precedes the ordinary observer, with owned nonblocking waitpid preventing a zombie from extending observation. Original split TAP/stderr and native wait status remain separate; preparation, exec observation, whole-test lifetime, inherited regular-file size and final reaping have fixed diagnostic bounds without widening individual fixture walls. Test/helper cleanup are attempted independently even after a reported error; only the owned direct child may be signalled, and unobserved descendants remain unknown. Re-derivation: inspect the tracked caller/observer and run guarded Python discovery with test_fixture_*.py; the final local suite passes all 48 reported tests. Falsification: a deliberately premature token release makes the independently written Perl body appear before readiness and is rejected by the tracked oracle; failed readiness, changed birth/cursor, evidence exhaustion, pre-evidence failure and partial pipe creation prevent exec, while real signal/file-cap and TERM-resistant children prove terminal-status preservation and exact reaping. Initial controls expose a native-exit/reap race and inherited Python-ignored SIGPIPE/SIGXFSZ; the caller now waits within its reap bounds when identity disappears and restores normal exec signal defaults. An initial comparison between Perl CLOCK_MONOTONIC and Python mach_absolute_time is rejected after same-process clock inspection confirms distinct readings; the independent Perl oracle now reads the actual readiness journal instead of comparing unlike clocks. The inspected Python subprocess implementation supplies the read-only toolchain signal-default reference. Durability: caller, independent controls, existing hosted discovery pattern, book and this task are tracked; ignored logs under .artifacts/logs/t1669-observer-readiness-20260907/ are supplemental. Pipe/exec/wait controls are real on both supported OS families; libproc birth qualification is local Darwin, other-host birth metadata is modeled and hosted execution remains unqualified. Syntax/help, generated book and Knowledge Map checks pass; staged doctrine and commit-hook gates close this slice. The original T1669 source, attach-only observer, sampler command and authentication policy are unchanged, and no new original-test invocation or privileged sampling occurs in this repair.`
  Commit: `this fixed diagnostic readiness slice`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.5`
  Status: `done`
  Goal: `Repair T1669 diagnostic workspace admission against its real allocator.`
  Acceptance: `Keep T1668 compatibility and fixed privileged sampling/authentication policy. Admit only T1669 exact commands beneath the actual process-supervisor-tests allocator root, retain every existing ancestry/source/volume boundary, and reject the former wrong root plus hostile alternatives. Use the real Perl allocator and native held wrapper/producer processes as an independent control; prove the pre-repair source rejects them and the repair admits them without sudo. Make the observer coverage failure visible without admitting unrelated targets. Sync book and fact route, consume controls and cleanup, and commit before fresh authenticated capture.`
  Verification: `Checkpoint 222476ec49c6f56f4550c9b6422f0183f1a2aba6 retains the failed original invocation and allocator mismatch. The sampler now derives both its literal prefix and returned workspace from the sealed T1669 process-supervisor-tests purpose; T1668 keeps its distinct tests root. Requests still cannot choose a purpose, command or output. All source, normal-user, interpreter, birth, ancestry and same-volume checks remain. The observer now fails no-fixture coverage after preserving the failure and settling the helper, and reports observed_fixture_count explicitly; a passing test cannot promote that diagnostic failure. Re-derivation: guarded Python discovery with test_fixture_*.py passes all 52 reported tests. The new control executes the original T1669 allocation statement through an unchanged copy of ProjectDataLocality in an isolated repository-shaped root, holds its allocating Perl process, then verifies normal File::Temp removal. Native held Rust and both legacy wrapper/producer families exercise exact admission and bounded group cleanup. Falsification: the pre-repair sampler rejects the real allocator-backed cases and live Rust chain; the old observer fails a separate expected-error control because it silently succeeds with no selected fixture. Former wrong roots, other purposes, sibling-prefix and traversal commands remain rejected. The first GREEN attempt exposes one remaining hardcoded return path, corrected by sharing the parsed directory, and launcher controls whose minimal bodies intentionally create no fixtures: successful-observer status tests now explicitly isolate that result, while a real caller/observer test proves passing TAP still leaves missing coverage failed. Durability: tracked sampler/observer, allocator-backed and hostile controls, existing hosted discovery pattern, Knowledge Card, book and Git carry reproduction; ignored logs under .artifacts/logs/t1669-workspace-admission-20260908/ are supplemental. The fact card preserves its prior facts and stays within its prior byte/line footprint. Native process metadata is qualified on this Darwin host; other-host metadata remains modeled and actual hosted execution unqualified. Syntax/help, generated-book inspection, exact build cleanup, Knowledge Map and staged doctrine checks complete the workflow. No original T1669 invocation, privileged sample, test bound, host setting, production supervisor or fixed native sampling command changes in this repair. Fresh authentication and capture remain .8.3; original startup causal repair stays open.`
  Commit: `this actual-allocator admission and explicit-coverage repair`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.6`
  Status: `done`
  Goal: `Keep an independently confirmed command-query exit race from aborting fixture observation.`
  Acceptance: `Reproduce a real owned child exiting between identity admission and ps query; distinguish native absence from a live/reused PID, unavailable identity, genuine ps error and timeout. Continue observation only for verified disappearance, preserving closed sampling admission and every other failure. Prove later eligible fixtures remain observable, helper cleanup and original test status remain exact, and qualify the full focused fixture band without original-test reruns or privileged sampling. Sync durable evidence/book and commit before fresh authentication.`
  Verification: `Capture checkpoint 5ddc9438c94945dd67323fda4a0650f153e82272 preserves the real wrapper-exit failure and exact observed identities. NativeProcesses.command now rechecks native identity only after the observed ps no-match exit status; only native absence supplies the process-disappearance exception that the observer may skip. A live or reused PID retains its original command error, unavailable native identity remains failed, and timeouts, unexpected query exits and signal termination are not reclassified. Final pre-publication target/source revalidation now skips verified disappearance too, continuing through eligible choices without publishing a request for a gone target. Helper publication and every post-publication capture failure stay outside that recovery; at most one request remains enforced. Re-derivation: guarded Python discovery with test_fixture_*.py passes all 57 reported tests. Falsification: an independently held real Perl child acknowledges main entry, is identified natively, exits under explicit release and is reaped before the actual ps query; pre-repair code raises CalledProcessError, repaired code reports native ESRCH. Independent modeled native-state removal during census initially aborts before a later eligible target, then permits that target after repair. A separate final-revalidation removal reproduces an unhandled native-gone exception before repair and qualifies subsequent wrapper admission afterward. Live/reused identity, denied identity, timeout and live-process command-failure controls retain failure without sampling. A later counterexample proves that unexpected ps exits and signal termination could be hidden when the target was also gone; classification is narrowed to the observed no-match status and those controls pass. The first matrix control had an incorrectly scoped subtest assertion after its expected error; its scope and unconditional pipe consumption are corrected before GREEN. Durability: native query and observer changes, focused real/modeled controls, canonical fact, book and work-unit Git retain reproduction; logs under .artifacts/logs/t1669-query-race-20260908/ are supplemental. Native command/identity qualification is Darwin-local; other-host metadata is modeled and hosted execution remains unqualified. Source syntax, unchanged capture/authentication AST, exact control-workspace cleanup, Knowledge Map and generated-book checks support the final staged-doctrine and commit-hook gates. No original T1669 invocation, privileged sample, regression bound, launcher, host setting or production runtime changes occur in this repair. Original startup causal repair remains open; .8.3 awaits a fresh authenticated session after this commit.`
  Commit: `this native disappearance and pre-publication race repair`


- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.7`
  Status: `done`
  Goal: `Qualify a bounded prospective T1669 sequence with one authenticated helper lifetime.`
  Acceptance: `Preserve the existing single-invocation CLI and fixed unprivileged T1669 command, native admission, regression walls and capture policy. A tracked controller owns at most twenty sequential invocations and a cumulative five-minute experiment budget, with at most one published capture overall. Reserve the existing full invocation and helper-cleanup bounds before starting an iteration; stop early when another complete invocation cannot fit, without shortening original test bounds or interrupting it merely to consume the remaining budget. Report any actual budget overrun as a failed diagnostic. Continue only after a fully consumed successful invocation with no request and exact observed cleanup; stop on the first failed test, observer error, capture attempt, revoked session or exhausted bound. Prepare observer readiness before each release, preserve every original result and verify helper shutdown/authentication invalidation exactly once at sequence exit. Qualify sequencing, deadlines, failure truth and cleanup with independent controls without sudo or rerunning original tests. Sync book and commit before an authenticated experiment; no passing sequence qualifies or repairs the historical failure.`
  Verification: `Checkpoint 1a726136f4d44cf43c1ef7d749d9f46feab69c1e preserves the passing observed invocation without capture and the director's authentication question. The tracked run_fixture_startup_sequence.py controller owns one helper lifetime across a finite prospective sequence. Existing single-invocation and attach-only CLIs still stop their helper; only the sequence passes internal shutdown ownership explicitly. Observer settlement now distinguishes caller-owned helper lifetime from proved shutdown and waits for any published capture result even without STOP. Original result, positive observed-fixture cleanup and capture/result agreement must be retained before continuation. The same session object preserves the global one-request boundary; any original failure, observer error, capture, revocation, missing evidence or exhausted bound stops the sequence without retry. The fixed count and cumulative time budget reserve the complete existing caller allowance plus helper cleanup before each launch, allowing early termination rather than shortened regression walls. Actual observed budget overruns remain failed; no hard real-time scheduling guarantee is claimed. Root history: git log -S 'stop_helper(session)' identifies 58b14d923980bd92f70e81f20e5d903001c8d2f1's single-caller shutdown. Re-derivation: guarded Python discovery with test_fixture_*.py passes all 73 reported tests; exact source syntax, unchanged sampler/original T1669/production-engine bytes, help and absent control-workspace residue are checked. Falsification: independently journal-reading Perl bodies prove readiness before both actual invocations, exact child reaping and a real normal-user held helper surviving between them; forcing the old shutdown ownership rejects the first settlement and prevents another body. Separate modeled controls reject missing capture results, absent cleanup evidence, revocation, failure, interruption, evidence exhaustion and budget overrun; observation with caller-owned shutdown still awaits delayed capture and rejects missing capture. The first GREEN budget control allocated less time than its real helper cleanup; it correctly failed the budget, and its no-launch oracle now reserves cleanup while remaining below a full invocation allowance. Durability: tracked controller, retained standalone compatibility, real/model controls, existing hosted discovery pattern, task, book, canonical fact and Git. Logs in .artifacts/logs/t1669-sequence-20260908/ are supplemental. Native ancestry integration is Darwin-only; portable controls use real held helpers with modeled birth metadata, and actual hosted execution is unqualified. Authentication and actual kernel sampling are not exercised by these unprivileged controls. Generated-book inspection, exact disposable build cleanup, Knowledge Map and staged doctrines complete the commit workflow. The original startup cause, causal repair, wire/runtime qualification, full CI and push remain open; sibling .8.8 owns the next authenticated experiment.`
  Commit: `this bounded sequence and single helper-lifetime qualification`


- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.8`
  Status: `done`
  Goal: `Run one predeclared prospective T1669 capture sequence with one authenticated helper.`
  Acceptance: `After .8.7 is committed, use a fresh READY helper and the fixed guarded sequence CLI. Preserve its at-most-twenty invocation bound, cumulative five-minute budget and complete-invocation time reservation, normal-user execution, original regression assertions and global single-capture limit. Stop at the first failed invocation, observer error or capture; never retry it. Consume every original TAP/wait, observer/sequence result and helper outcome; correlate any capture with exact ancestry, source identity, native progress and narrow OS records. Independently verify recorded process births and authentication shutdown. Return evidence to original causal repair .2 without claiming passing-run qualification; if no capture occurs, retain the missing discriminator explicitly.`
  Verification: `One authenticated unchanged invocation captures a Rust proxy AppleSystemPolicy wait while the original legacy main-entry assertions fail. The first original failure ends the sequence without retry; original wait 256/exit 1 remains authoritative. Independent checks find all recorded test/helper/fixture births gone and helper authentication invalidated. Exact-path Info evidence later becomes unavailable to identical and broader queries, so missing historical records cannot exclude policy activity. Detailed native identities, source/report hashes, raw retention paths, query controls and explicit re-derivation/falsification/durability boundaries are in this task's Captured recurrence evidence .3.8.8 section. Siblings .8.9/.8.10 own legacy selection and prospective retention before another capture; original causal repair remains open.`
  Commit: `this failed-invocation/native-capture and log-availability checkpoint`


- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.9`
  Status: `done`
  Goal: `Qualify closed legacy-only capture selection without weakening standalone admission.`
  Acceptance: `After the .8.8 evidence commit, add an explicit closed legacy-family selection to the tracked caller/observer/sequence while preserving existing all-family behavior. Retain observation and original results, but spend the single capture only on an admitted legacy wrapper/producer before its native main-entry marker. Reject invalid selection before release and fail missing selected-family coverage even when unrelated Rust fixtures were seen. Independently prove excluded Rust cannot consume the request, eligible legacy is reached, main-entered waits remain excluded and all existing ancestry/source/authentication/cleanup boundaries hold. Sync book/fact and commit without privileged sampling or original-test reruns; .8.10 precedes another capture.`
  Verification: `Closed --target-family all|legacy flows through observer, fixed caller and sequence; all remains the default. Legacy selection retains unrelated observations but Rust cannot spend its one request. Readiness/attachment/settlement record the family and selected-fixture count; missing legacy coverage fails despite observed Rust, and the sequence rejects mismatched settlement before another invocation. Legacy wrapper eligibility also consults its admitted producer marker, explicitly scoped to selected_producer; an entered/drained producer excludes its surviving wrapper without claiming wrapper main entry. Final revalidation preserves role/source/main-entry checks. Invalid selection fails before any test fork/release and still closes the owned helper. Re-derivation: source review and guarded fixture discovery report 85 controls passing in .artifacts/logs/t1669-legacy-selection-20260908/controls-final.log. Real Darwin legacy Perl bodies independently read their family-specific readiness before entry across separate invocations and prove selected coverage/helper cleanup. Falsification: the independent mixed-family oracle rejects unfiltered selection with [30] != [60]; modeled native identities and literal source/argv give early Rust then later legacy eligibility. Rust-only coverage, invalid family, mismatched settlement, entered producer with remaining wrapper, wrapper-only eligibility and existing race/admission/storage/authentication/lifecycle/budget controls pass. Syntax, unchanged sampler/original-test/production-engine hashes and zero owned control residue are independently retained in source-checks.json. Durability: tracked producers/controls, book/fact/task and Git own reproducible behavior; ignored local result logs remain a named raw-evidence gap. No original T1669 replay, authenticated sampling, host-setting change, new startup causal attribution or runtime qualification occurs. .8.10 must qualify prospective record retention before actual legacy capture.`
  Commit: `this legacy-family diagnostic selection slice`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.8.10`
  Status: `active`
  Goal: `Preserve selected OS policy evidence prospectively instead of relying on volatile later queries.`
  Acceptance: `After .8.9, select and qualify bounded read-only OS-record collection tied to the same diagnostic invocation and exact project fixture paths. Preserve readiness limits, original outcomes, record identity, storage/lifetime bounds and collection/cleanup failures; do not interpret missing records as proof of no policy activity. Test the loss-of-later-query counterexample independently and retain emitted records before their source becomes unavailable. No OS logging/security configuration changes, unbounded daemon dump or original-test replay for qualification. Keep unresolved native subscription/completeness limits explicit, sync book/fact and commit before a new authenticated capture.`
  Verification: `pending; .8.8 retains an Info-level Rust path record whose exact successful query later returns nothing, including a fixed-prefix query for its known second. Apple's logging documentation supplies memory-only defaults, while root-only subsystem configuration remains unread. The precise local disappearance mechanism is unproved; the repair must remove dependence on later availability, not assert a new OS cause.`
  Commit: `pending prospective policy-evidence qualification`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2`
  Status: `done`
  Goal: `Implement private repository-local endpoints and finite nonblocking connection handling.`
  Acceptance: `Director-approved prerequisite amendment on 2026-09-07: inactive endpoint implementation may follow the verified private Wire implementation .3.1.1 while parent wire qualification remains open. Retain exact run-directory/socket identity, independent run/job authority, close-on-exec descriptors, bounded connections/partial frames/queues and fixed progress walls. Prove actual long-path bind/connect, handle-based cwd restoration on success and failure, exact environment/signal-mask restoration, symlink/foreign/stale endpoint rejection and identity-safe endpoint cleanup. No supervised command launch, public routing or runtime activation is enabled; startup causal repair, complete CI and push remain blocked.`
  Verification: `Director approval db47806a3 authorizes only inactive endpoints after verified private Wire. Filesystem 467a40261, connection mechanics ef450a2e6 and the current service admission slice complete that scope. Independent endpoint watchers pass with retained RED controls, exact cleanup and book/fact evidence. The unchanged T1669 band recurs with startup timeouts; causal repair, parent Wire/runtime qualification, reserved-group launch, full CI and push remain blocked.`
  Commit: `db47806a3 approval; 467a40261 filesystem; ef450a2e6 connection; this service admission slice`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.3`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.1`
  Status: `done`
  Goal: `Record the approved inactive-endpoint prerequisite amendment and bounded implementation sequence.`
  Acceptance: `Change only the endpoint implementation prerequisite from full sibling .1 qualification to the already verified .1.1 private Wire implementation. Preserve the startup incident, all endpoint acceptance requirements, runtime activation, complete-CI and push gates. Establish separate filesystem and connection leaves, synchronize current task/index/Memory pointers, run staged doctrines and commit before source changes.`
  Verification: `The director reply explicitly approves the proposal retained in startup leaf .3.1.2.2.3.2. Read-only review covers the roadmap, Wire, shared process engine, selected private protocol, decisions 0087/0101 and relevant mdBook. No product code or endpoint exists in this selection slice. Logs belong under .artifacts/logs/coordinator-endpoint-approval-20260907/. The staged doctrine driver passes every registered check and explicitly applies the documentation-only task-acceptance exemption; diff hygiene passes. The final commit hook rechecks the checkpoint.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.1: approve inactive endpoint implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.2`
  Status: `done`
  Goal: `Implement inactive endpoint filesystem identity, authority material and long-path-safe socket transactions.`
  Acceptance: `After .2.1 commits, add a private endpoint module with a closed API and fixed repository root. Obtain complete independent OS-random run/job identities; exclusively create the selected private run directory and socket with exact modes, device/owner/type checks, no symlink ancestry or replacement. Seal descriptors, validate inherited context and cached-PID ownership, and bind/connect through the literal local socket name while saving/restoring cwd by handle and the exact catchable-signal mask. Preserve environment and umask. Prove actual kernel long-path connection and byte exchange plus independent hostile identity/mode/foreign/stale/forked-copy/restoration/partial-start cleanup controls. Remove only unchanged owned identities and preserve unexpected entries. No production import, process launch or authentication claim from filesystem validation alone.`
  Verification: `Approval checkpoint db47806a3 precedes this source slice. Endpoint.pm is private and absent from production imports; it owns independent in-memory OS-random authority, exact private directory/socket identity and modes, sealed descriptors, nonblocking connect, handle-based cwd/signal restoration and nonrecursive identity-safe cleanup. Native SIGCHLD disposition and auto-reap flags are admitted before filesystem output. T1812 initially fails because the module is missing. A later real directory replacement during bind independently falsifies the first implementation; the repaired pre/post identity checks reject both bind/connect replacement, preserve unexpected objects and retain the original failure. Real kernel peers exchange raw bytes at an actual pathname longer than sockaddr_un permits, while direct absolute addressing fails. Actual symlink/mode/stale/collision/renamed-cwd/fork-copy/partial-start/umask controls pass; owner/device controls are explicitly model-only. The final endpoint-only run reports Files=1, Tests=11; the earlier endpoint plus unchanged T1669 Wire/mechanism band reports Files=2, Tests=23. All results are retained under .artifacts/logs/coordinator-endpoint-filesystem-20260907/. The book documents the inactive boundary and runnable controls; the canonical fact retains every existing failure/identity fact with tighter prose and adds T1812 to reverify without raising containment allowances. The generated book builds and its new rendered paragraphs/command are inspected; fact/map and claim census regeneration pass. The first staged doctrine run passes every check except the still-unchecked final NO REGRESSION box; that checklist sequencing omission is corrected and the final staged driver passes all doctrines with fresh git_history/prove_summary acceptance. A fresh source census finds no production importer, and the exact endpoint-root census is empty. Connection I/O/authentication, Linux execution, startup repair, runtime activation, complete CI and push remain unqualified.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.2: implement inactive endpoint filesystem`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.3`
  Status: `done`
  Goal: `Implement inactive finite nonblocking connection I/O over the qualified endpoint and Wire.`
  Acceptance: `After .2.2 commits, enforce fixed connection admission, close-on-exec/nonblocking ownership, incremental header/type admission before body storage, one partial frame per connection, separate bounded control/stream queues including unsent headers, finite authentication/framing/progress walls and one operation per ready descriptor per advancement. Preserve message bytes, EOF/EPIPE/failure truth and first failure. Validate run/parent authority through explicit private owner records; reject wrong or revoked authority and duplicate submission without launching commands. Independently exercise raw kernel peers, oversize prefixes, fragmented/slow peers, backpressure, queue boundary-plus-one, disconnects, signal-disposition restoration and identity-safe cleanup. Return no runtime/nested guarantee; activation, startup repair, complete CI and push remain gated.`
  Verification: `Filesystem commit 467a40261 and Connection commit ef450a2e6 precede child .2, which completes inactive authority/admission. Each child owns its exact source/test/book/fact evidence and failing controls. The expanded endpoint watchers pass; unchanged T1669 recurrence remains an explicitly failed broader qualification result owned by startup .3.1.2.2.3.2. No runtime activation is implied.`
  Commit: `ef450a2e6 connection mechanics; this service admission slice`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.3.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.3.1`
  Status: `done`
  Goal: `Implement bounded server-side connection framing, backpressure and deadlines without activation.`
  Acceptance: `After filesystem commit 467a40261, add a private server-side connection object over an owned accepted descriptor. Admit header and type before body storage; preserve one partial frame, separate bounded control/stream queues including unsent headers, exact message bytes, first failure, EOF/EPIPE and fixed framing/write-progress walls clipped to the invocation. Advance at most one read and one write chunk without sleep; preserve SIGPIPE disposition and caller context. Prove raw-peer fragmentation, oversized/malformed prefixes, queue boundary-plus-one, partial-write framing, backpressure/EOF, finite slow-peer expiry, inherited descriptor refusal and cleanup. No command, client-routing or parent-authentication implementation is implied; sibling .2 owns bounded service admission and authority.`
  Verification: `Connection.pm remains inactive and server-side. T1813 starts RED at its missing import; literal raw socket peers then prove fragmented header/type pre-admission, large request bodies, malformed prefix refusal, exact encoded queue ceilings, partial-byte credit, noninterleaved partial frames, separate control/stream backpressure, fixed framing/progress/invocation walls and EOF under real kernel saturation. An intentionally corrupt priority model fails the independent byte oracle; deliberate blocking readiness/sleep controls trip the same traps that actual advancement passes. Native EPIPE and injected write exceptions restore exact SIGPIPE action; an actual fork proves inherited authority refusal and creator survival. Initial focused and final unchanged-supervisor bands pass, including Files=3, Tests=36 in final-regression.log; a harmless one-use test-hook warning is scoped away and the focused watcher is rechecked. Evidence lives under .artifacts/logs/coordinator-connection-io-20260907/. Re-derivation is the literal peer band; falsification uses corrupt framing, real kernel pressure and blocking controls; durability is source/watcher/book/fact/task/Git, while raw logs remain ignored. Authority/admission, Linux execution, runtime routing, startup repair, complete CI and push remain unqualified. Book rendering and claim/map regeneration pass. The first staged gate rejects only ROOT CAUSE evidence punctuation because the signature expects a space before at; quoting the complete retained Perl diagnostic repairs that evidence shape, with no source change. The corrected staged driver passes every doctrine, including fresh Perl-diagnostic/prove-summary acceptance; the commit hook rechecks the final snapshot.`
  Commit: `this connection-I/O slice`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.2.3.2`
  Status: `done`
  Goal: `Integrate finite accepted-connection admission and live-parent authority over the inactive transport.`
  Acceptance: `After sibling .1 commits, enforce the selected accepted-connection limit and fair bounded advancement over the qualified Endpoint and Connection. Admit HELLO against exact run and explicit live parent/token/deadline records, revoke authority before cleanup, reject stale/forged/duplicate context and multiple submissions, preserve original framing/authentication/admission deadlines and snapshot timestamp bounds, and deliver admitted requests to a private owner without command creation. Independently exercise raw peers, saturated connections, invalid/revoked parents, slow authentication, malformed/order-invalid frames and exact descriptor/endpoint cleanup. No daemon, runtime routing, supervised command launch, full-CI qualification or push.`
  Verification: `Sibling .1 is committed at ef450a2e6. Private Service owns finite accepted descriptors, bounded consumed-once outcomes and monotonic live parent authority; distinct one-shot connections may share a parent, while duplicate HELLO/SPAWN fail. Fixed authentication/admission, exact timestamp window, invocation/parent clipping, expiry rechecks, fair nonblocking advancement and revoke-before-close are implemented without command creation or ACCEPT. T1814 raw peers qualify exact bytes, live/wrong/revoked authority, both capacity boundaries, real slow authentication, concurrent healthy-peer progress, native descriptor flags, root/parent expiry and actual forked-copy refusal/reaping. Its first helper callback and Perl precedence failures are retained separately. The corrected oracle then falsifies the first implementation at T1814 lines 267/306: stale snapshot transfer and accepted-descriptor close failure could escape failure truth. Both are repaired; lifetime-cleanup-green.log reports Files=1, Tests=9. The expanded T1814, T1813 and T1812 each report ok in focused-regression.log, but unchanged T1669 fails subtests 9-10 with Rust proxy and legacy producer timeouts: the full Files=4, Tests=48 band is FAILED, not a qualification pass. Source identity and zero production import/residue censuses are checked; syntax passes. The recurrence is owned by startup .3.1.2.2.3.2 and retained in the service-band recurrence section below; no retry or causal repair is claimed. Re-derivation is literal kernel peers and source/history; falsification is real pressure plus stale/cleanup and blocking controls; durability is source/tests/book/fact/task/Git, with ignored raw logs an explicit gap. The book and fact are synchronized without ceiling growth; book build/render inspection, claim/map regeneration and the staged doctrine driver pass, including fresh git_history/prove_summary acceptance. The hook rechecks the final snapshot. Linux, actual job ownership, startup repair and broad runtime qualification remain missing. Logs: .artifacts/logs/coordinator-connection-admission-20260907/.`
  Commit: `this inactive service admission slice`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.3`
  Status: `blocked`
  Goal: `Add asynchronous reserved-group launch gates inside the shared process owner.`
  Acceptance: `After .2, reserve both child slots and record each exact fork before release; qualify reservation group creation, command membership, reservation departure, exec gating and failed partial-start cleanup. Preserve the default synchronous legacy path while internal coordinator launches use the explicit private strategy. Never reap a group reservation before its last signal or infer group authority from an unacknowledged handoff. Prove descriptor closure, actual wait truth and caller-group isolation with independent real-process and model-only retirement controls.`
  Verification: `Pending endpoint/context qualification in sibling .2; existing T1669 reservation feasibility is a prerequisite, not production handoff proof.`
  Commit: `pending`

  Blocked by: `Startup causal repair and full private Wire qualification in sibling .1 remain open. The director amendment in .2.1 admits inactive endpoints only; it does not waive the launch prerequisite. Endpoint completion does not qualify reserved-group command launch.`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.4`
  Status: `pending`
  Goal: `Integrate bounded root ownership records, admission service and fair process advancement.`
  Acceptance: `After .3, compose the qualified codec, endpoints and gated shared engine into the selected private root coordinator. Validate parent/run authority, reserve all resources before fork, publish ACCEPT before exec release and service all job control/stream/deadline work without starvation. Reject lost or malformed admission without unregistered execution, preserve adapter policy and first failure, and prove private service partial-publication cleanup. Do not enable nested caller routing until sibling .5.5.2.4; complete closure and independent end-to-end qualification remain .5.5.2.5 and .5.5.3.`
  Verification: `Pending the gated reserved-group mechanism in sibling .3.`
  Commit: `pending`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.4`
  Status: `pending`
  Goal: `Route nested sealed invocations through the coordinator.`
  Acceptance: `After .2.3, inherit the exact run context, validate logical parents and requests, reconstruct separate streams and closed results, and preserve adapter schemas/limits/caller cwd/environment. Refuse stale or partial client contexts without falling back to an independent group owner; prove current Rust nested controls and standalone calls.`
  Verification: `Pending root coordinator implementation in sibling .3.`
  Commit: `pending`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.5`
  Status: `pending`
  Goal: `Close nested cancellation, result delivery and endpoint cleanup.`
  Acceptance: `After .2.4, close admission before root failure cleanup, cancel subtrees on lost clients, drain finite queued output without starving deadlines, preserve first failure and incomplete cleanup, retire only closed identities, and remove exact owned endpoints. Prove intermediate death before/after spawn publication and during exec/result delivery, then hand off independent qualification to .5.5.3.`
  Verification: `Pending nested routing in sibling .4.`
  Commit: `pending`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.3`
  Status: `pending`
  Goal: `Qualify nested containment and resume neutral verifier policy selection.`
  Acceptance: `Run independent nested timeout/TERM/KILL/overflow/nonzero and orphan-race controls plus existing real-tool and sealed-adapter regressions; synchronize task/book/contract evidence and return to parent .5.1 only after the selected cleanup guarantee is demonstrated.`
  Verification: `Pending selected implementation.`
  Commit: `pending`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6`
  Status: `done`
  Goal: `Select deterministic bounded RAM-guard test-fixture launches.`
  Acceptance: `Select fixed fixture interpreter identity and a sealed bounded run policy for T1595 without weakening metric assertions, changing production RAM thresholds, or retrying failures into success; distinguish fixture startup from metric computation, preserve signal truth and cleanup, and split implementation into an owned child before source changes.`
  Verification: `In the 2026-09-06 recovery full run, T1595's first healthy fixture blocks in fake-bin/uname -s before measurement. A one-second OS sample places /usr/bin/env at _dyld_start before main with no loaded binary-image map; its shebang is env bash. During that diagnostic the outer complete-run RAM guard remained active with unchanged thresholds. Knowledge Map returns the metric and sealed-adapter contracts but no T1595 startup answer. Git traces the fixture to 30885823b54a0677b4396550d9d3cfc2fc7fa3a9. run_guard uses open3, sequential stream reads, unbounded waitpid, and exit-only status projection. The verified T1595 tree received TERM; t1595-process.sample and t1595-terminated-processes.json under .artifacts/logs/session-recovery-20260906/ retain evidence. This is an interrupted test, not a metric assertion failure or successful qualification. Re-derivation is the sample plus fixture/source/history inspection; the independent T1467 and T1554 pre-main samples falsify a RAM-formula-only explanation without establishing the OS cause. Task, subprocess fact card, and Git own durability. Child .1 selects a sealed RAM-guard fixture adapter and bounded independent controls; child .2 implements and qualifies it. The completed native-diagnostic suffix is retained through the exact history manifest before new live policy is added; current startup blockers and coordinator design remain live. This leaf has no dependency on completing wire endpoints or attributing the old timeout. Existing process-group limits remain explicit; no nested supervisor is introduced. Child .2 implements and independently qualifies the selected bounded fixture harness; original OS startup attribution stays under the separate .5.5.2.3.1.2.2.3.2 owner. This closes fixture capture/admission/status/cleanup work, not complete CI.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6: own RAM-guard fixture startup blocker`

  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6.2`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6.1`
  Status: `done`
  Goal: `Select the closed RAM-guard fixture launch policy and independent repair oracles.`
  Acceptance: `Inspect T1595, the guard, shared engine and current adapter contracts; retain original failed evidence; select exact command, interpreter, path, environment, wall, capture and result policy without modifying production thresholds. Split implementation before source edits, preserve the blocked startup/wire frontier and keep completed diagnostic history exactly retrievable. Commit the reviewed selection before implementing.`
  Verification: `git log -S waitpid identifies 30885823b54a0677b4396550d9d3cfc2fc7fa3a9; source confirms sequential open3 reads, unbounded waitpid and shifted-only status. Decisions 0087/0101 require shared mechanics behind a domain-specific adapter. The selected policy below bounds those concrete fixture defects without claiming an OS timeout cure. The history manifest re-derives the full predecessor and exact completed diagnostic suffix at 0ba9d1492fa76a1e6b6bf85f6982dd0ac3610a9c; live coordinator design and current startup evidence are unchanged. The focused task/history checker reports all active task-tree invariants hold, including exact predecessor/suffix retrieval; map regeneration succeeds. The guarded staged doctrine driver reports all doctrine checks passed, including task/history integrity and the documentation-only task-acceptance exemption; the hook rechecks final evidence. Runtime changes belong only to child .2.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6.1: select bounded RAM-guard fixture policy`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6.2`
  Status: `done`
  Goal: `Implement and qualify the sealed RAM-guard test-fixture adapter.`
  Acceptance: `Implement child .1 policy using the shared mechanism, migrate every T1595 metric assertion without weakening it, prove lost-signal and concurrent-output failures against the former launcher, reject caller command/bound/path/environment escape, preserve normal/nonzero/signal/timeout/overflow and complete/incomplete cleanup truth, extend exclusive-owner watching and synchronize the book/facts. All original failures remain failed; no repeat pass or env bypass establishes the macOS root cause. Split any expanded failure domain before proceeding.`
  Verification: `RamGuardFixtureRuntime uses the existing mechanism with pinned Bash/Perl, direct guard argv, a sealed local fixture parent, safe bounded samples, fixed fake inspection roles/scenarios, restored environment, closed results and unchanged production thresholds. T1595 retains every original metric/safety assertion and now rejects infrastructure/cleanup failures explicitly. An independently bounded Python probe of the exact old run_guard records native wait status 15 with projected exit 0; the initial stream timeout lacks independent main progress and is not sufficient causal evidence. The tracked T1669 legacy copy has exact helper SHA-256 cb9a8d6d041b37a50abd7bbcea3740018b1777bd52e5ff26856d96fe014fdebe; its maintained signal and stream controls independently record main entry, expose signal loss and block before drained progress, then prove owned group cleanup. T1811 qualifies exact new concurrent capture and native signal/overflow results through a test-private fixed producer injection at the real engine boundary, with no public command override. Actual guard fixtures separately prove metric behavior, PATH/startup-environment protection, input/path/command rejection, sealed bounds, and TERM-resistant inspection timeout/KILL cleanup; a complete injected failure record qualifies unchanged incomplete-cleanup transport without creating an unkillable process. The initial focused run remains failed: T1595 used ok instead of success, and the watcher expected inspection stderr despite the guard intentionally discarding it. Those test/consumer errors are corrected; a file now proves real inspection progress, while actual capture is probed at its engine boundary. The initial oversized regex quantifier was replaced by a literal byte check. The corrected guarded T1811/T1595/T1669/T1668/T1545/T313 band reports All tests successful; final T1811 after changing reference identity to contract equality also passes. Source review preserves original metric assertion bodies and confirms guard/engine/wrapper are unchanged. Book builds to the correct repo-local destination, and rendered policy/command/limitations are inspected. Evidence and digests: .artifacts/logs/ram-guard-fixture-runtime-20260907/. Re-derivation is source/policy and actual structured results; falsification is the exact legacy counterexample, independent producer markers, boundary-plus-one and hostile controls; durability is tracked adapter/T1595/T1811/T1669, task/book/fact/Git. Initial scratch/raw logs retain a durability gap, but the repair controls are tracked. The book input-ceiling candidate joins its source and independent exact-boundary/plus-one controls through an owned derived-gate disposition. Final staged doctrines report all doctrine checks passed, including fresh task acceptance, claim joins and unchanged containment limits; the hook rechecks the final evidence. Historical OS attribution, wire and nested qualification, complete CI and push remain open; this closes the bounded fixture harness only.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.6.2: bound RAM-guard fixture execution and retain failure truth`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.2`
  Status: `proposed`
  Goal: `Implement deterministic portable-SystemVerilog lifecycle admission and static controller emission.`
  Acceptance: `The common adapter and portable emitter accept only the selected lifecycle-control revision and exact version-2 profile, lower all planned lifecycle records into one finite statically scheduled controller beside the unchanged scenario machinery, enforce bounded readiness/service/stimulus/completion/drain/shutdown/finalization order, emit no target interpreter or UVM mechanism, source-map every lifecycle control seam, remain deterministic/minimal/readable, and claim emission only.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.3`
  Status: `proposed`
  Goal: `Implement version-2 portable lifecycle trace validation and normalized result production.`
  Acceptance: `Additive lifecycle trace records preserve exact plan/run/lifecycle/fixture/domain identities and monotone logical chronology; validators reject malformed, incomplete, late, reordered, or false-pass evidence; result production calls the target-neutral lifecycle validator, publishes one complete normalized lifecycle result with source maps and backend evidence, and leaves version-1 trace/result bytes unchanged.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.4`
  Status: `proposed`
  Goal: `Qualify the exact portable-SystemVerilog lifecycle route through compile, runtime, and public version-2 run.`
  Acceptance: `The runner and shared Verilator host-process lifecycle admit the exact version-2 lifecycle emission without confusing process states with VIAL lifecycle meaning; exact Verilator 5.046 compiles and executes the maintained fixture, public run atomically publishes only validated artifacts/results, nonzero/timeout/truncated/malformed/deadline/finalization failures publish no false success, repository-local staging is removed, and version-1 run remains unchanged.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.5`
  Status: `proposed`
  Goal: `Close portable-SystemVerilog lifecycle capability, documentation, quality, and continuity.`
  Acceptance: `Independent executable gates re-derive the selected mapping, source-map completeness, deterministic artifacts, exact runtime/result behavior, cleanup, and version-1 preservation; public capability/support rows and runnable mdBook examples claim only the qualified portable lifecycle slice; other expressive families, native UVM, VHDL/OSVVM, mixed-language, and general parity remain unavailable; task, claims, Knowledge Map, containment, locality, and doctrine evidence close the child without drift.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.4`
  Status: `proposed`
  Goal: `Implement lifecycle control through compiler-private native-UVM mechanisms.`
  Acceptance: `Generated phases and one root-owned objection realize VIAL lifecycle order; child objections, phase jumps, implicit drain folklore, and authored UVM terms are absent; emission/static evidence and exact runtime qualification retain separate capability states.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.5`
  Status: `proposed`
  Goal: `Implement and qualify lifecycle control in provider-free VHDL and negotiated OSVVM.`
  Acceptance: `Processes/controller services preserve the same logical seams and completion/result policy; provider services are additive only, exact GHDL/OSVVM identities are gated, and absent equivalents reject before output.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.6`
  Status: `proposed`
  Goal: `Close lifecycle parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent tests cover dependency order, drain/deadline/failure, normal/terse identity, profile negotiation, applicable normalized parity, component elision, source maps, cleanup, and runnable docs; no general UVM/VHDL or scheduler claim leaks.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3`
  Status: `active`
  Goal: `Deliver notification and interception intent end to end.`
  Acceptance: `VIAL expresses typed occurrences, registration scope, strict ranks, filters, transformations, observation, cancellation, persistence, trigger policy, and bounded reentrancy without exposing event/callback classes; the existing private UVM preview is audited and migrated rather than treated as public meaning.`
  Verification: `pending children .19.3.1-.19.3.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.1`
  Status: `proposed`
  Goal: `Select notification/interception semantics and normal/terse source.`
  Acceptance: `Specify payloads, lifetimes, ranks, filters, closed effects, transformation typing, cancellation commit point, persistence/trigger/reentrancy policy, queue bounds, examples, and diagnostics without backend callback vocabulary.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.2`
  Status: `proposed`
  Goal: `Implement notification/interception through typed compiler phases.`
  Acceptance: `SemanticIR, ExecutionIR, plans, results, source maps, and capabilities preserve original/effective payload, evaluated/skipped interceptors, bounded nested occurrences, logical time, and deterministic rank-plus-ID ordering; invalid recursion/effects reject early.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog notification/interception.`
  Acceptance: `Static typed dispatch realizes filter/transform/cancel/observe and bounded queue-or-reject behavior without dynamic callback dependence; runtime/result evidence and hostile ordering/reentrancy controls close the exact supported subset.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.4`
  Status: `proposed`
  Goal: `Implement native-UVM notification/interception with compiler-owned event/callback machinery.`
  Acceptance: `Generated typed events and one ordered dispatcher preserve VIAL ranks/effects independently of registration/allocation order; preview fixtures migrate to public semantic IDs; exact emission, compile/runtime maturity, and UVM nonclaims remain distinct.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM notification/interception.`
  Acceptance: `Protected records, queues, alerts, or other selected mechanisms remain backend-private while preserving identical ordering/effects/bounds/results; provider-free and OSVVM capability states are separate and unsupported effects reject before artifacts.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.3.6`
  Status: `proposed`
  Goal: `Close notification parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent definition-oriented, metamorphic, seeded-defect, nested-trigger, cancellation, profile, parity, source-map, elision, cleanup, and runnable-book gates prove intent semantics without promoting target callback APIs or broad methodology support.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4`
  Status: `active`
  Goal: `Deliver timed-interface interaction intent end to end.`
  Acceptance: `VIAL expresses domains, roles, directions, drive/sample edges and skews, reset behavior, race policy, and typed access without authored virtual interfaces, modports, clocking blocks, processes, or delta-cycle folklore.`
  Verification: `pending children .19.4.1-.19.4.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.1`
  Status: `proposed`
  Goal: `Select timed-interface semantics and normal/terse source.`
  Acceptance: `Define domain/role/direction, edge/skew, reset, contention, sampling stability, race resolution, bounds, examples, and diagnostics in logical-time terms, including multi-domain capability boundaries without target syntax.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.2`
  Status: `proposed`
  Goal: `Implement timed-interface binding and execution semantics.`
  Acceptance: `Bridge carrier relations, SemanticIR, ExecutionIR, schedules, plans, results, and source maps preserve typed direction and drive/sample ordering; ambiguous clocks/resets/skews/cross-domain interactions reject before emission.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog timed interfaces.`
  Acceptance: `Generated static adapters implement the selected logical-time contract without races, preserve four-state/known-value profile limits, remain minimal/readable/source-mapped, and produce closed timing/result evidence under the exact tool profile.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.4`
  Status: `proposed`
  Goal: `Implement native-UVM timed interfaces through private interfaces, modports, virtual bindings, and clocking blocks.`
  Acceptance: `Compiler-generated mechanisms reproduce VIAL edge/skew/direction/reset semantics; config lookup and UVM hierarchy remain private; exact static versus runtime maturity and unavailable multi-domain cases are reported.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM timed interfaces.`
  Acceptance: `Selected processes, signal/clock/reset adapters, and provider services implement the same logical phases and race policy; delta cycles remain backend evidence, and unsupported skew or access forms reject before artifacts.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.4.6`
  Status: `proposed`
  Goal: `Close timed-interface parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent race, phase, reset, direction, carrier, profile, parity, source-map, component-elision, cleanup, and runnable-example gates distinguish exact supported domains from multi-domain/full-four-state/mixed-language nonclaims.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5`
  Status: `active`
  Goal: `Deliver transactions, scenarios, and stimulus orchestration end to end.`
  Acceptance: `VIAL composes typed exchanges, correlation, arbitration, parallel scenario graphs, responses, timeouts, cancellation, reusable stimulus, and finite iteration without exposing sequences, sequencers, drivers, processes, or host threads.`
  Verification: `pending children .19.5.1-.19.5.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.1`
  Status: `proposed`
  Goal: `Select transaction/scenario/stimulus semantics and normal/terse source.`
  Acceptance: `Specify typed requests/responses, identity/correlation, arbitration, reusable flows, parallelism, joins/cancellation, deadlines, finite loops, examples, defaults, limits, and diagnostics while retaining v1 scenario compatibility.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.2`
  Status: `proposed`
  Goal: `Implement transaction/scenario/stimulus compiler semantics.`
  Acceptance: `Parser, SemanticIR, HIAL bindings, ExecutionIR graph, scheduling, plan, result, source-map, and capability records preserve typed correlation and deterministic concurrency; cycles, deadlocks, runaway expansion, and unsupported topology fail early.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog stimulus orchestration.`
  Acceptance: `Static tasks/state machines implement the selected graphs and arbitration within bounded scheduler/resource profiles, produce deterministic results, and avoid unnecessary generated services or dynamic target-language machinery.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.4`
  Status: `proposed`
  Goal: `Implement native-UVM stimulus orchestration through private sequence infrastructure.`
  Acceptance: `Generated items, sequences, sequencers, drivers, and virtual coordination preserve VIAL identities/order/cancellation and are emitted only when selected; authors see no UVM types/APIs and runtime qualification remains explicit.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM stimulus orchestration.`
  Acceptance: `Controller processes and selected verification components implement identical typed exchanges, correlation, arbitration, timeouts, and results; provider services cannot perturb pre-resolved logical order or decisions.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.5.6`
  Status: `proposed`
  Goal: `Close stimulus parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent graph, concurrency, timeout, cancellation, deterministic replay, profile, applicable parity, source-map, minimal topology, scale, cleanup, and runnable-example gates retain explicit unsupported dynamic/unbounded/general-UVM boundaries.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6`
  Status: `active`
  Goal: `Deliver producer/observer communication, deterministic models, and scoreboards end to end.`
  Acceptance: `VIAL expresses typed streams, fanout, ordering, backpressure/loss, deterministic model transitions, expected/actual matching, keys, capacity, drain, and mismatch results without authored TLM ports, subscribers, FIFOs, or component classes.`
  Verification: `pending children .19.6.1-.19.6.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.1`
  Status: `proposed`
  Goal: `Select communication/model/scoreboard semantics and normal/terse source.`
  Acceptance: `Define publishers/subscribers, stream type and order, fanout/backpressure/loss, model state/rules, scoreboard matching/key/order/capacity/drain, examples, bounds, and diagnostics as verification intent.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.2`
  Status: `proposed`
  Goal: `Implement communication/model/scoreboard compiler semantics.`
  Acceptance: `Typed immutable channels, deterministic model transitions, bounded queues and matching state propagate through IR/plan/result/source maps/capabilities; cycles, ambiguous fanout, overflow/loss violations, and incomplete drain reject exactly.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog communication, models, and scoreboards.`
  Acceptance: `Static queues/services realize typed fanout and deterministic bounded checking with exact mismatch/overflow results; generated state is compact, readable, source-mapped, and absent when the family is unused.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.4`
  Status: `proposed`
  Goal: `Implement native-UVM communication, models, and scoreboards through private TLM/component machinery.`
  Acceptance: `Generated ports/exports/imps/FIFOs/subscribers preserve VIAL stream and order semantics, component graph is minimal, no TLM API leaks to authors, and static/runtime maturity remains exact per capability.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM communication, models, and scoreboards.`
  Acceptance: `Selected protected queues, records, scoreboards, and provider services preserve identical type/order/capacity/drain/result semantics; unsupported backpressure or matching forms reject before output.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.6.6`
  Status: `proposed`
  Goal: `Close communication/checking parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent fanout/order/loss/overflow/model/matching/drain/profile/parity/source-map/elision/scale/cleanup gates and runnable docs prove selected meaning without claiming arbitrary TLM or unbounded scoreboard breadth.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7`
  Status: `active`
  Goal: `Deliver implementation selection and scoped substitution end to end.`
  Acceptance: `VIAL selects abstract roles, defaults, compatible replacements, scope, precedence, and result evidence without factory classes, registration macros, overrides, target hierarchy, or provider-specific plug-ins.`
  Verification: `pending children .19.7.1-.19.7.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.1`
  Status: `proposed`
  Goal: `Select role/substitution semantics and normal/terse source.`
  Acceptance: `Define abstract roles, implementation declarations, defaults, scopes, precedence, compatibility predicates, conflicts, examples, limits, and diagnostics without UVM factory vocabulary.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.2`
  Status: `proposed`
  Goal: `Implement role/substitution compiler semantics.`
  Acceptance: `IR and planning resolve one compatible implementation per role and scope with stable identities/source maps/capabilities/results; cycles, ambiguity, incompatible shape, and late mutation reject before backend construction.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog role substitution.`
  Acceptance: `Compile-time generated selection realizes the exact role graph without dynamic target factories, emits only chosen implementations, and records deterministic selection evidence in the normalized result.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.4`
  Status: `proposed`
  Goal: `Implement native-UVM role substitution through private factory machinery.`
  Acceptance: `Generated registrations and type/instance overrides preserve VIAL scope/precedence, readiness verifies the realized graph, source maps identify semantic owners, and authors never spell UVM type or factory APIs.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM role substitution.`
  Acceptance: `Static generic/configuration or generated composition mappings realize the same selected role graph; unsupported dynamic/provider substitutions reject before output and cannot be inferred from UVM capability.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.7.6`
  Status: `proposed`
  Goal: `Close substitution parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent scope/precedence/conflict/compatibility/profile/parity/source-map/elision/cleanup and target-free example gates prove role intent while retaining arbitrary plug-in/runtime mutation nonclaims.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8`
  Status: `active`
  Goal: `Deliver scoped typed configuration end to end.`
  Acceptance: `VIAL expresses keys, types, values, ownership scopes, precedence, required/default/locked policy, consumption, and unused/conflict outcomes without config-DB calls, hierarchy wildcards, or target-specific generics.`
  Verification: `pending children .19.8.1-.19.8.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.1`
  Status: `proposed`
  Goal: `Select scoped-configuration semantics and normal/terse source.`
  Acceptance: `Define typed declarations/assignments/reads, lexical semantic scopes, precedence, defaults, required/locked policy, conflicts, unused values, examples, limits, and diagnostics without backend hierarchy patterns.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.2`
  Status: `proposed`
  Goal: `Implement scoped-configuration compiler semantics.`
  Acceptance: `IR/plans resolve every read deterministically with stable scope/value/source/result evidence; missing required, incompatible, ambiguous, late-locked, unused-error, and cyclic-derived configurations fail before emission.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog scoped configuration.`
  Acceptance: `Generated immutable configuration tables/constants realize selected scope and precedence without runtime hierarchy lookup; only consumed state is emitted and results report semantic keys rather than target names.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.4`
  Status: `proposed`
  Goal: `Implement native-UVM scoped configuration through private configuration objects and config DB.`
  Acceptance: `Compiler-owned set/get/check plumbing preserves VIAL resolution, readiness proves required consumption, wildcard target scopes are absent, and UVM paths/APIs do not enter public source or result meaning.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM scoped configuration.`
  Acceptance: `Generated records/constants/generics or provider services preserve typed scope/precedence/lock behavior; static elaboration limitations are explicit and unsupported late configuration rejects before artifacts.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.8.6`
  Status: `proposed`
  Goal: `Close configuration parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent resolution/conflict/required/default/lock/unused/profile/parity/source-map/elision/cleanup and target-free example gates prove exact meaning without claiming arbitrary runtime/hierarchy configuration.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9`
  Status: `active`
  Goal: `Deliver register intent end to end.`
  Acceptance: `VIAL expresses register blocks, maps, fields, address/endianness, access/reset/volatility, prediction, mirror, frontdoor/backdoor choice, and access results without authored UVM RAL, hierarchy paths, or VHDL methodology APIs.`
  Verification: `pending children .19.9.1-.19.9.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.1`
  Status: `proposed`
  Goal: `Select register semantics and normal/terse source.`
  Acceptance: `Define map/block/register/field identities, addresses, widths, access/reset/volatility, mirror/prediction, frontdoor/backdoor policy, sequences, examples, bounds, diagnostics, and HIAL binding requirements target-neutrally.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.2`
  Status: `proposed`
  Goal: `Implement register compiler semantics and HIAL binding.`
  Acceptance: `IR/plans prove address/field non-overlap, carrier/access compatibility, reset/mirror/prediction transitions, adapter identity, source maps, capabilities, and results; undeclared raw backdoors and ambiguous maps fail before emission.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog register intent.`
  Acceptance: `Generated frontdoor transactions, mirror/predictor state, and selected declared-probe access preserve policy and results without UVM; backdoor use requires an exact HIAL capability and all emitted tables/services are bounded and source-mapped.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.4`
  Status: `proposed`
  Goal: `Implement native-UVM register intent through private RAL machinery.`
  Acceptance: `Generated blocks/maps/adapters/predictors/sequences match VIAL IDs and policies, omit unused RAL structures, never infer hierarchy backdoors, and separate source emission/static review from exact executable qualification.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM register intent.`
  Acceptance: `Generated map/access/mirror/prediction services and selected OSVVM transaction facilities preserve identical policy/results; unsupported backdoor/provider semantics reject before output rather than weakening intent.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.9.6`
  Status: `proposed`
  Goal: `Close register parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent layout/access/reset/volatile/predict/frontdoor/backdoor/profile/parity/source-map/elision/scale/cleanup and runnable-example gates retain explicit arbitrary hierarchy and complete-RAL nonclaims.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10`
  Status: `active`
  Goal: `Deliver constrained-decision intent end to end.`
  Acceptance: `VIAL expresses decision identity, typed domains, constraints, distributions, seed/replay, attempt/exhaustion policy, accepted values, and solver evidence without authored randomize calls, solver objects, or backend-specific constraint syntax.`
  Verification: `pending children .19.10.1-.19.10.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.1`
  Status: `proposed`
  Goal: `Select constrained-decision semantics and normal/terse source.`
  Acceptance: `Define types/domains, composable constraints, distributions, dependence, seeds, stable occurrence IDs, attempt/exhaustion, replay, examples, bounds, and diagnostics while preserving fixed v1 decision behavior.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.2`
  Status: `proposed`
  Goal: `Implement constrained-decision compiler and replay semantics.`
  Acceptance: `SemanticIR/ExecutionIR/plans/results carry canonical constraints, dependencies, solver/profile identity, accepted normalized values, attempts, and replay records; unsatisfiable, cyclic, non-replayable, or over-limit decisions fail deterministically.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog constrained decisions.`
  Acceptance: `A selected target-neutral bounded solver or pre-resolved plan produces deterministic values and replay; the backend never silently invokes native randomization, and result evidence distinguishes generation from replay.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.4`
  Status: `proposed`
  Goal: `Implement native-UVM constrained decisions through controlled private randomization.`
  Acceptance: `Generated constraints/randomize calls are used only for selected native nodes, exact solver/tool identity and accepted value enter evidence, portable decisions are never rerandomized, and replay bypasses solver variance.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM constrained decisions.`
  Acceptance: `Provider-free or OSVVM solvers preserve selected domains/distributions/constraints and exact replay; provider algorithm identity is capability evidence, and unavailable constraint classes reject before output.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.10.6`
  Status: `proposed`
  Goal: `Close decision parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent satisfiable/unsatisfiable/distribution/dependency/seed/attempt/replay/profile/parity/source-map/scale/cleanup and runnable-example gates distinguish accepted-value parity from solver-sequence identity and retain statistical nonclaims.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11`
  Status: `active`
  Goal: `Deliver coverage and property intent end to end.`
  Acceptance: `VIAL expresses sample events, typed coverpoints/bins/crosses/goals/illegal policy and temporal assumptions/assertions/covers/results without covergroup, SVA, PSL, callback, or simulator database syntax.`
  Verification: `pending children .19.11.1-.19.11.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.1`
  Status: `proposed`
  Goal: `Select coverage/property semantics and normal/terse source.`
  Acceptance: `Define sampling, typed expressions, bins/transitions/wildcards/crosses/goals/illegal handling, temporal operators/clock/reset/vacuity, outcomes, examples, finite expansion, diagnostics, and shared HIAL property reuse.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.2`
  Status: `proposed`
  Goal: `Implement coverage/property compiler semantics.`
  Acceptance: `IR/plans preserve exact sample identities, normalized bins/crosses/hits/goals, temporal state/outcomes/source maps/capabilities/results; cardinality and monitor state are preflighted and unsupported operators reject early.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog coverage/properties.`
  Acceptance: `Generated counters and procedural/bound-checker mechanisms implement exact selected semantics under the qualified subset, distinguish scenario and assertion success, and avoid raw target text or unbounded bin expansion.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.4`
  Status: `proposed`
  Goal: `Implement native-UVM coverage/properties through private covergroups and bound SVA.`
  Acceptance: `Generated covergroups sample only declared VIAL events, bound checkers preserve shared temporal meaning, result collection separates coverage/assertion/scenario outcomes, and unsupported tool features remain exact capability gaps.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM coverage/properties.`
  Acceptance: `Provider-free monitors plus selected OSVVM coverage and exact PSL subset preserve the same bins/temporal/result contract; supplementary databases/reports cannot replace normalized results and unsupported constructs reject before output.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.11.6`
  Status: `proposed`
  Goal: `Close coverage/property parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent sample/bin/cross/illegal/vacuity/reset/temporal/profile/parity/source-map/elision/scale/cleanup and runnable-example gates preserve exact LRM/PSL/methodology subset and no database-identity claim.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12`
  Status: `active`
  Goal: `Deliver bounded fault intent end to end.`
  Acceptance: `VIAL expresses declared targets, activation windows, substitution/perturbation/omission/delay policies, restoration, composition/conflicts, and observability without raw force/release, deposit, hierarchy mutation, VPI, or simulator commands.`
  Verification: `pending children .19.12.1-.19.12.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.1`
  Status: `proposed`
  Goal: `Select fault semantics and normal/terse source.`
  Acceptance: `Define target/access capabilities, activation/restoration windows, finite fault actions, priority/conflicts, visibility, examples, limits, and diagnostics while preserving bounded v1 transaction substitution.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.2`
  Status: `proposed`
  Goal: `Implement fault compiler and execution semantics.`
  Acceptance: `Binding proves declared access; IR/plans/results preserve original/effective values, activation/restoration/effect identities and source maps; illegal overlap, undeclared target, unbounded duration, and inaccessible native residual reject early.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog faults.`
  Acceptance: `Generated driver/model/interface interception realizes only selected declared access and deterministic restoration, records exact outcomes, and rejects unsupported hierarchy mutation without partial artifacts.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.4`
  Status: `proposed`
  Goal: `Implement native-UVM faults through private driver/interface/model interception.`
  Acceptance: `Generated components apply selected faults at VIAL lifecycle seams, never infer force/VPI/backdoor authority, preserve restoration/result evidence, and keep tool-native access behind explicit capabilities.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM faults.`
  Acceptance: `Selected driver/model/resolution mechanisms preserve activation/effect/restoration semantics; force/deposit/external-name features require exact separate capability and unsupported forms reject before output.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.12.6`
  Status: `proposed`
  Goal: `Close fault parity, usability, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent target/access/window/action/conflict/restoration/profile/parity/source-map/elision/cleanup and runnable-example gates retain explicit raw hierarchy, analog, arbitrary simulator, and destructive native-access nonclaims.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13`
  Status: `active`
  Goal: `Deliver semantic results, diagnostics, debugging, and introspection end to end.`
  Acceptance: `VIAL tooling exposes sanitized semantic state, causality, logical time, break/watch/query intent, replay/checkpoint identity, framework state, evidence, and closed results without raw target hierarchy, object handles, vendor commands, license data, or private compiler objects.`
  Verification: `pending children .19.13.1-.19.13.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.1`
  Status: `proposed`
  Goal: `Select results/debugging/introspection semantics and normal/terse query/control source.`
  Acceptance: `Define observable state/causality/time, watch/break/query/control permissions, checkpoint/replay, framework-state and evidence projections, diagnostics, bounds, security/privacy, examples, and read-only versus mutating operations target-neutrally.`
  Verification: `pending`
  Commit: `pending selection`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.2`
  Status: `proposed`
  Goal: `Implement semantic result, diagnostic, debugging, and introspection compiler/runtime contracts.`
  Acceptance: `Versioned APIs and IR/result projections preserve semantic IDs, logical snapshots, causality, source maps, capability/evidence identities, bounded pagination and control authorization; raw private objects/paths/handles and inconsistent checkpoints fail closed.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.3`
  Status: `proposed`
  Goal: `Implement and qualify portable-SystemVerilog semantic debugging and introspection.`
  Acceptance: `Generated trace/checkpoint hooks and host adapters expose only the selected closed model, preserve deterministic results/replay, remain optional and bounded, and do not perturb scheduler meaning or require target hierarchy knowledge.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.4`
  Status: `proposed`
  Goal: `Implement native-UVM semantic debugging and introspection through private framework/tool adapters.`
  Acceptance: `Generated collectors/projectors translate phases, objections, topology, events, TLM, factory/config/RAL, coverage, and reports into VIAL semantics; raw UVM handles/names remain evidence-only and NEXSIM control requires an exact qualified API.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.5`
  Status: `proposed`
  Goal: `Implement and qualify VHDL/OSVVM semantic debugging and introspection.`
  Acceptance: `Generated trace/checkpoint/report adapters expose identical semantic records, distinguish supplementary provider reports, and fail closed for unavailable live-control or internal-state capabilities.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.13.6`
  Status: `proposed`
  Goal: `Close results/debugging/introspection usability, parity, quality, documentation, support, and nonclaims.`
  Acceptance: `Independent schema/causality/snapshot/replay/control/authentication/pagination/sanitization/profile/parity/source-map/non-perturbation/cleanup and runnable API/MCP examples distinguish inspection from simulator support and retain private/tool-state nonclaims.`
  Verification: `pending`
  Commit: `pending closeout`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14`
  Status: `active`
  Goal: `Close cross-family VIAL version-2 composition and retain an exact admission path beyond the first expressive programme.`
  Acceptance: `All selected families compose under one bounded identity/order/effect/result model; dependencies and conflicting effects fail closed; profile support and applicable parity are exact; representative scale and generated-code quality pass; public docs/migration are complete; later families require the same semantic-compression and vertical-evidence gate rather than a frozen ceiling.`
  Verification: `pending children .19.14.1-.19.14.6`
  Commit: `pending activation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.6`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.1`
  Status: `proposed`
  Goal: `Prove cross-family semantic composition and deterministic conflict resolution.`
  Acceptance: `A closed dependency/effect matrix proves ordering, lifetime nesting, typed communication, cancellation/fault/substitution/configuration interactions, finalization, diagnostic precedence, and result closure; cycles and unselected conflict policies reject before output.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.2`
  Status: `proposed`
  Goal: `Close cross-backend profile capability and applicable semantic parity.`
  Acceptance: `Machine manifests join every family/revision to parse/plan/emit/compile/run/result/parity maturity per exact profile; portable shared meanings compare normalized outcomes, native-only meanings retain explicit oracles/nonclaims, and no single backend defines VIAL breadth.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.3`
  Status: `proposed`
  Goal: `Qualify representative expressive-family scale, limits, and generated-code efficiency.`
  Acceptance: `Orthogonal and balanced workloads measure parser/IR/plan/backend/runtime/result dimensions with stage-local correctness, explicit component ceilings, graceful over-limit failure, minimal topology, repository-local evidence, and no inference of whole-product capacity.`
  Verification: `pending`
  Commit: `pending qualification`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.4`
  Status: `proposed`
  Goal: `Publish complete VIAL version-2 language, profile, migration, and generated-artifact documentation.`
  Acceptance: `The mdBook teaches target-free intent with runnable normal/terse examples, exact capabilities and unavailable paths, v1 coexistence/migration, backend review routes, diagnostics/results, troubleshooting, and cleanup while machine contracts remain mutable truth.`
  Verification: `pending`
  Commit: `pending documentation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.5`
  Status: `proposed`
  Goal: `Implement the admission gate for later expressive VIAL families.`
  Acceptance: `A tracked template/check requires semantic compression, common-envelope fields, bounded behavior, normal/terse equivalence, capability/profile mappings, backend-private mechanisms, at least one executable qualified route before runtime support, tests/docs/nonclaims, source maps, quality, and cleanup; raw target wrappers fail admission.`
  Verification: `pending`
  Commit: `pending implementation`

- ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.14.6`
  Status: `proposed`
  Goal: `Independently close the first expressive VIAL programme and architecture continuity.`
  Acceptance: `Re-derive every family/lane status from code, machine manifests, executable profiles, parity, scale, examples, docs, claims, task/roadmap/Knowledge Map/Memory, containment, locality, cleanup, and doctrines; repair drift, preserve exact nonclaims, close .19 and the parent only if no owned architecture item remains.`
  Verification: `pending`
  Commit: `pending closeout`

## Current Frontier

Current frontier: approved inactive endpoint container `.19.2.3.1.2.2.5.5.2.3.2` is complete. Startup causal repair `.3.1.2.2.3.2` remains blocked, with the new service-band recurrence recorded below. Reserved-group launch `.3.3`, parent wire qualification, runtime activation, complete CI and push remain gated; endpoint approval does not waive them.

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
therefore closes deterministic generation. Architecture-scale activity `.17`
is complete at clean closeout commit `35d06790a`. Documentation and migration
activity `.18` is complete. Child `.18.1` selected the exact public-surface
matrix; `.18.2` through `.18.6` published the stable entry path, lifecycle
reference, runnable AHB tutorial, migration guidance, and capability/support
reference; `.18.7` independently closes their commands, links, truth
boundaries, containment, and continuity. Expressive VIAL activity `.19` is
active. Foundation parent `.19.1` and all seven children are complete: the
additive v2 source/compiler substrate now includes explicit public source
tooling, non-mutating v1-to-v2 migration, empty-family planning, and
target-neutral lifecycle-control compilation. Every other expressive family
and every v2 backend/run/result/parity route remains unavailable.
Lifecycle-control parent `.19.2` is active. Clean foundation closeout commit
`984271755` and activation commit `06c331cb7` permit child `.19.2.1` to select
the target-neutral lifecycle semantic/source contract. Selection child
`.19.2.1` and target-neutral compiler child `.19.2.2` are complete.
Portable-SystemVerilog lifecycle child `.19.2.3` is active. Its contract
selection parent `.19.2.3.1` has completed prerequisite readiness-condition
repair `.19.2.3.1.1` at clean commit `1b25880f8`. Mapping selection
`.19.2.3.1.2` has selected and executable-contract-watched the exact static
controller and backend evidence contract without promoting a version-2
backend. Its proposed repair child `.19.2.3.1.2.1` must close the independently
characterized private v1 trace-validator envelope gap before emission begins.
The selection commit reaches the 300-local-commit cadence, so full pre-push and
hosted qualification precede activation of that child. Output-policy qualification
`.19.2.3.1.2.2.3.2` is blocked after the consumed recovery gate: startup repairs
`.4`/`.5`/`.6` and a complete guarded rerun are required. The next eligible
leaf is `.19.2.3.1.2.2.4`, bounded Rust parity policy selection.

## Decisions

- `2026-09-04`: Map portable-SystemVerilog lifecycle control to one finite
  fixture-level controller invoked at three compiler-owned check seams beside
  the unchanged scenario scheduler. Preserve scenario-local time and use one
  monotone fixture lifecycle cycle; isolate every content-bearing v2 backend
  evidence schema. Keep all v2 maturity unavailable, and require the owned
  private v1 trace-validator envelope repair before emitter work.

- `2026-09-04`: Select lifecycle-control revision 1 as one fixture-scoped,
  coordination-domain program that expands to typed records. Intrinsic order
  and a mandatory full deadline cannot be weakened; optional requirements add
  conjunctions only. Failure always remains failure and receives a separately
  bounded finalization attempt. Normal and terse projections retain one family
  spelling, while backend scheduling and methodology plumbing stay private.

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
- `.19.1.2` is next to implement v2 parsing and equivalent normal/terse
  projections against the closed `.19.1.1` contract without changing v1.
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

- `.19.2.3.1.2.2.3.2` cannot claim complete qualification: the recovery
  gate exited 137 at the host-memory cutoff with T1467 failed and
  T1554/T1595 interrupted. Next is `.19.2.3.1.2.2.4` policy selection;
  `.6` now qualifies its bounded fixture harness; `.5` retains neutral-verifier,
  nested and causal-startup work before a complete fresh guarded run. Preserve
  the configured limits and the failed/interrupted evidence.
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

## Version-Retrievable Historical Views

- Acceptance history manifest: `docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl`

The manifest binds the complete task snapshot at `0ba9d1492fa76a1e6b6bf85f6982dd0ac3610a9c` and its exact completed diagnostic suffix from `## Targeted wait-state diagnostic selection (.19.2.3.1.2.2.5.5.2.3.1.2.2.3.3)` through end of file. That snapshot preserves the earlier history pointer and its versioned manifest; no prior evidence is discarded. Live coordinator design and current startup blockers remain here; the completed capture/permission procedures remain available in source, book, canonical facts and exact Git history.

## Acceptance Checklist (enforced) — `.17.5.4.3.2.2` authenticated evidence materialization

- [x] **ROOT CAUSE (WHY + WHERE; materializer absence)** — the focused watcher began RED with
  `Failed test 'tracked evidence materializer exists' at t/1791-vial-regression-promotion-evidence-materialization.t line 18`.
  The authenticated tracked bundle had no authorized executable that could
  create its ignored fixed coordinates or prove cleanup ownership.
- [x] **ADDRESSED (verified before -> after)** — the absent lifecycle becomes
  one root-derived executable that authenticates
  and stages the exact transport behind one nonblocking read-only manifest
  lock, commits corpus then qualification through a recoverable journal and
  receipt, preserves exact pre-existing roots as unowned, rejects mismatch,
  and cleans only reauthenticated receipt-owned roots. T1791's copied fresh
  checkout passes both production validators after fresh installation and
  each interrupted-boundary recovery, then proves exact residue absence.
- [x] **NO REGRESSION (materialization band)** — the RAM-guarded independent transport plus
  materialization band reports `All tests successful.` and
  `Files=2, Tests=13` in 211 wallclock seconds. Perl syntax, task-tree,
  Knowledge Map, mdBook, claim, containment, staged acceptance, and complete
  doctrine gates are required before commit; local/hosted CI and real gate
  execution remain unchanged.

## Acceptance Checklist (enforced) — `.17.5.4.3.2.3` bounded local CI placement

- [x] **ROOT CAUSE (WHY + WHERE; missing local driver path)** — the focused watcher began RED with
  `Failed test 'selected VIAL gate dry-run succeeds' at t/1183-ci-regression-tier-selection.t line 389`.
  The CI driver accepted no
  selected gate mode, and its unsharded full dry-run contained zero real-gate
  commands after ordinary regression.
- [x] **ADDRESSED (verified before -> after)** — exact `vial-gate` and only
  unsharded `full` now share ordered authenticated materialization, current-
  corpus validation, budget-qualification validation, one common-RAM-guarded
  `--run`, and one receipt cleanup. Copied fixed command stubs prove every
  downstream status propagates while cleanup still runs exactly once; adopted
  evidence and the latest observation remain outside owned cleanup.
- [x] **NO REGRESSION (local CI inventory band)** — the guarded focused watcher
  reports `All tests successful.` and `Files=1, Tests=16` in 38 wallclock
  seconds. It proves quick/smoke/ISF and ordinary direct tests remain focused,
  all file/dedicated/dynamic/corpus hosted shard modes stay gate-free, complete
  hosted test ownership is unchanged, invalid mode/shard mixing rejects, and
  copied fixture residue is absent. Syntax, mdBook, Knowledge Map, claims,
  containment, staged acceptance, and doctrine gates remain required before
  commit; no real gate or hosted workflow runs in this slice.

## Acceptance Checklist (enforced) — `.17.5.4.3.3` hosted gate placement

- [x] **ROOT CAUSE (WHY + WHERE; missing seventh hosted family)** — the guarded
  workflow watcher began RED with `Failed test 'the unsharded VIAL gate pins its hosted platform' at t/1183-ci-regression-tier-selection.t line 841`; it also found no gate
  aggregate dependency/result or the two required immutable action uses.
- [x] **ADDRESSED (verified before -> after)** — one non-matrix Ubuntu-24.04
  job now establishes the exact absent-runtime/OSVVM-present provider state,
  calls public `vial-gate`, independently authenticates the canonical latest
  result and 8-informational/3-unavailable, 11/33/44-to-8/24/32 contract, and
  always cleans exact owned evidence/provider/result/stage coordinates. The
  terminal aggregate consumes its result.
- [x] **NO REGRESSION (hosted workflow and result-verifier band)** — guarded
  t1183+t1792 reports `All tests successful.` and `Files=2, Tests=21` in 40
  wallclock seconds. It retains all four disjoint tracked-test ownership
  families, 17 immutable action uses, every prior shard coordinate, verifier
  hostile closure, and no real workload. Syntax, workflow-YAML, mdBook,
  Knowledge Map, claims, containment, staged acceptance, and complete doctrine
  gates are required before commit; full CI and hosted performance/support/
  capacity claims remain outside this slice.

## Acceptance Checklist (enforced) — `.17.5.4.4.1` ordinal-10 correctness stability

- [x] **ROOT CAUSE (WHY + WHERE; process telemetry in exact correctness)** — the
  focused watcher began RED with
  `Failed test 'gate profile exposes its private stable correctness projection' at t/1793-vial-regression-promotion-gate-correctness-stability.t line 13`.
  The real fresh/qualified comparator then isolated 116 differences to byte
  counts and identities derived from monotonic GHDL lifecycle process telemetry,
  while every semantic field agreed and ordinal 11 independently passed.
- [x] **ADDRESSED (verified before -> after)** — after raw identity mismatch,
  two caller-sealed seams now authenticate the fresh and immutable qualified
  full projections. Only the exact OSVVM-runtime 4 x 29 telemetry-derived
  coordinates normalize; topology fails closed, all other fields remain exact,
  and successful admission retains the immutable qualified identity without
  recalibration or evidence mutation. T1786 and T1793 prove stable-only pass,
  adjacent semantic rejection with ordinal/selection diagnostics, all ten
  non-target projections unchanged, and caller/shape/coordinate closure.
- [x] **NO REGRESSION (qualification/gate correctness band)** — the guarded
  focused band reports `All tests successful.` and `Files=7, Tests=151` across
  t1779/t1780/t1785/t1786/t1787/t1788/t1793; the focused pair independently
  reports Files=2/Tests=27. Perl syntax, mdBook, Knowledge Map, claims,
  containment, staged acceptance, and doctrine gates are required before
  commit. Qualification/corpus bytes and identities, workloads, budgets,
  provider/environment admission, atomic failure behavior, and residue remain
  unchanged; clean production closeout is separately owned by child `.2`.

## Acceptance Checklist (enforced) — `.17.5.4.4.2.1` ordinal-8 correctness stability

- [x] **ROOT CAUSE (WHY + WHERE; portable process telemetry in exact correctness)** —
  the focused watcher began RED with `Failed test 'only portable telemetry-derived lifecycle drift normalizes equal' at t/1793-vial-regression-promotion-gate-correctness-stability.t line 324`; integration independently rejected at GateProfile.pm line 465. The real comparator's 96 changed leaves trace to fresh supervisor timing copied into Verilator lifecycle evidence from compile onward.
- [x] **ADDRESSED (verified before -> after)** — Decision 0099's stable comparator
  now selects two exact schema/backend table entries. Portable admission replaces
  only its 4 x 24 derived fields, retains immutable qualified identity, and
  rejects missing/new/duplicate/reordered or malformed coordinates plus adjacent
  semantic drift. Focused t1786+t1793 is GREEN at Files=2/Tests=29.
- [x] **NO REGRESSION (qualification/gate correctness band)** — the corrected
  guarded band reports `All tests successful.` and `Files=7, Tests=153` across
  t1779/t1780/t1785/t1786/t1787/t1788/t1793. Perl syntax, mdBook, Knowledge Map,
  claim inventory/disposition joins close 1,887/1,887 candidates with zero open
  owners. Containment, staged acceptance, and doctrine gates remain required
  before commit. Qualification/corpus, budgets, providers, publication, and
  cleanup are unchanged; child `.2.2` retains real production closeout.

## Acceptance Checklist (enforced) — `.17.5.4.4.2.2.1` ordinal-9 correctness stability

- [x] **ROOT CAUSE (WHY + WHERE; portable-VHDL process telemetry in exact correctness)** —
  T1793 began RED with `Failed test 'only portable VHDL telemetry-derived lifecycle drift normalizes equal' at t/1793-vial-regression-promotion-gate-correctness-stability.t line 490`. The real comparator's 116 changed leaves trace to fresh supervisor timing copied into GHDL lifecycle evidence from compile onward; every semantic field agrees.
- [x] **ADDRESSED (verified before -> after)** — Decision 0099's exact table now
  selects three schema/backend entries. Portable-VHDL admission replaces only
  its 4 x 29 derived fields, explicitly authenticates the distinct publish
  evidence kind, retains immutable qualified identity, and rejects
  missing/new/duplicate/reordered or malformed coordinates plus adjacent
  semantic drift. Focused t1786+t1793 is GREEN at Files=2/Tests=31.
- [x] **NO REGRESSION (qualification/gate correctness band)** — the corrected
  guarded band reports `All tests successful.` and `Files=7, Tests=155` across
  t1779/t1780/t1785/t1786/t1787/t1788/t1793. Independent corpus and
  qualification verifiers reproduce 13 files/6,220,126 bytes and 2
  files/792,158 bytes with unchanged identities. Perl syntax, mdBook, Knowledge
  Map, claims, containment, staged acceptance, and doctrine gates are required
  before commit; child `.2.2` retains production closeout.

## Acceptance Checklist (enforced) — `.17.5.4.4.2.2.2` exact production gate closeout

- [x] **ROOT CAUSE (WHY + WHERE; no complete accepted production observation)** —
  synthetic gate/CI coverage did not prove the real eleven-profile path, and
  the first three clean public executions correctly stopped before publication
  at ordinals 10, 8, and 9 because sealed process telemetry derivatives were
  still compared as stable correctness. The retained focused diagnostic locates
  rejection ` at perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateProfile.pm line 465`.
  Their owning repair leaves changed no corpus, qualification, budget,
  provider, environment, or support boundary.
- [x] **ADDRESSED (verified before -> after)** — from clean repaired revision
  ef59330ab, `./bin/ci-regression vial-gate --no-book` authenticates the exact
  13-file corpus and two-file qualification, passes all eleven exact-pinned
  profiles, and publishes canonical 60,097-byte result c7787a02...02f2. A
  production-module-free raw-JSON join independently verifies every immutable
  identity, ordinal, 11/33/44 topology, correctness, measurement, budget,
  applicability, publication, uniqueness, and cleanup coordinate.
- [x] **NO REGRESSION (applicability, CI ownership, hostile band, residue)** —
  t1786+t1787 pass Files=2/Tests=20 for unmatched informational,
  unavailable-not-pass, and aggregate precedence. The guarded t1183 plus
  t1779-t1793 closeout band passes `Files=12, Tests=194` in 272 wall-clock
  seconds. Producer-free result validation passes; final census finds eleven
  removed spools, zero child/process/staging/receipt residue, and the canonical
  qualification-distinct latest result intact. mdBook, Knowledge Map, claims,
  containment, staged acceptance, and doctrine gates are required before
  commit; `.17.5.5` remains a separate public-truth publication owner.

## Acceptance Checklist (enforced) — `.17.5.5.1` machine-readable regression capability

- [x] **ROOT CAUSE (WHY + WHERE; no precise public scale-regression record)** —
  aggregate VIAL discovery retained only an ambiguous `scale` nonclaim even
  after the bounded regression gate shipped. T1794 began RED with `Can't locate
  FSM/Support/VIALArchitectureScaleRegressionContract.pm at t/1794-vial-architecture-scale-regression-capability.t line 13`;
  after the
  aggregate contract existed, a direct CLI JSON probe separately found its
  nested record missing because `_capabilities_result` still selected the old
  field subset.
- [x] **ADDRESSED (verified before -> after)** — one pure closed support module
  now owns the complete artifact-independent snapshot and is embedded unchanged
  in the public VIAL API, JSON CLI result, language surface, and complete
  manifest. T1794 independently joins all eleven rows, 11/33/44 topology,
  budgets, evidence identities, host/guard/providers, applicability, cadence,
  latest-result, cleanup, supported bounded-gate scope, and precise nonclaims to
  tracked evidence or executable authorities; T1555 locks the formerly missing
  CLI path and every fixture support row retains its narrower `scale` nonclaim.
- [x] **NO REGRESSION (capabilities, docs, claims, containment)** — five changed
  modules report `syntax OK`; the impacted band reports `All tests successful.`
  and `Files=8, Tests=37`. mdBook tests and the rendered chapter pass; Knowledge
  Map generation/check passes at 1,160 facts; claim registry and inventory joins
  close 1,891/1,891 candidates with zero gaps. Fresh maintained-reference
  authority owns the exact book delta without raising a ceiling, no generated
  book artifact remains, and staged acceptance, containment, task integrity,
  and doctrine gates remain required before commit.

## Acceptance Checklist (enforced) — `.17.5.5.2` human scale-regression publication

- [x] **ROOT CAUSE (WHY + WHERE; machine truth lacked an operator guide)** —
  `git log -S'### Run the bounded gate' --oneline --
  docs/book/src/16df-vial-architecture-scale-cap-closeout.md` returned no
  historical match, while worktree `git grep` locates the new section at line
  1996. The completed machine contract was exact, but readers lacked one
  runnable command path and one complete human envelope/applicability view.
- [x] **ADDRESSED (verified before -> after)** — the README remains a compact
  signpost at 240 lines/9,930 bytes. The mdBook now carries six runnable
  commands, the five-step transaction, pinned environment/providers, eleven
  exact workload/provider/budget rows, 11/33/44/0 topology, applicability,
  result, cleanup, recalibration, supported scope, and fourteen nonclaims. A
  public-JSON-to-Markdown parser proves every row equal; mdBook rendering
  exposed the initial pipe-splitting defect, and the repaired HTML has exactly
  six columns with literal selection keys.
- [x] **NO REGRESSION (public truth, docs, claims, containment)** — T1555/T1794
  report `All tests successful.` at Files=2/Tests=10. The public dry run prints
  all five lifecycle steps; independent tracked-evidence authentication and
  guarded producer-free validation of accepted result c7787a02...02f2 pass.
  mdBook tests pass and the 94-file repository-local render is removed exactly.
  Knowledge Map closes at 1,160 facts/6,284 unique questions; claim joins close
  1,908/1,908 candidates with zero gaps; maintained-reference authority owns
  the 118-line/7,017-byte book delta without raising a ceiling. Staged
  acceptance, task integrity, and doctrine gates remain required before commit.

## Acceptance Checklist (enforced) — `.17.5.6.1` public scale-regression closeout watcher

- [x] **ROOT CAUSE (WHY + WHERE; no durable human/machine join)** —
  `git log -S'architecture-scale regression public closeout' --oneline --
  t/1795-vial-architecture-scale-regression-public-closeout.t` returns no
  watcher. T1794 closes machine truth, but no permanent oracle joined both
  public commands to every human guide row or checked dry-run side effects.
- [x] **ADDRESSED (verified before -> after)** — T1795 invokes public VIAL JSON
  and complete-manifest children, compares their nested contracts, derives all
  eleven human rows and pinned environment/provider fields from that contract,
  validates commands, topology, applicability, result/cleanup, scope, and
  nonclaims, and executes the dry run while preserving latest-result state.
  Six hostile in-memory cases reject missing/reordered rows, provider mixing,
  budget or host drift, and capacity-nonclaim inversion.
- [x] **NO REGRESSION (public capability and guide band)** — Perl syntax is
  clean and t1555/t1794/t1795 report `All tests successful.` at
  Files=3/Tests=18. The first watcher runs exposed command-continuation
  normalization and exact combined-provider version gaps; both are corrected.
  mdBook, Knowledge Map, claims, containment, staged acceptance, task
  integrity, and doctrine gates remain required before commit. No generated
  evidence or prior result is required and no gate/support/capacity behavior
  changes.

## Acceptance Checklist (enforced) — `.17.5.6.2` exact scale-regression closeout

- [x] **ROOT CAUSE (WHY + WHERE; final observation was not independently closed)** —
  clean predecessor `b0f5d74f1` permanently joined public machine and human
  contracts, but the final leaf still required one fresh exact production run,
  producer-free and production-module-free joins, the complete hostile oracle
  band, evidence immutability, atomic result replacement, and residue proof
  before `.17.5.6`, `.17.5`, or `.17` could close. `git log -S'shards=2,
  records=31' --oneline -- t/1750-claim-verification-registry-set.t` separately
  identifies `6702f48e0` as the stale bounded-registry census origin.
- [x] **ADDRESSED (verified)** — before -> after: the public gate at revision
  `840c895f3` publishes PASS identity `f4b022fa...f5f97` in 60,100 canonical
  bytes, with exact 11/33/44/0 topology and all eleven profiles accepted. The
  producer-free validator, three independent evidence verifiers, and a raw
  JSON::PP/Digest::SHA reconstruction agree on every profile, result, report,
  validation, measurement, qualification, transport, budget, and public
  identity. All 15 evidence hashes are unchanged, the result inode changed
  atomically, and report-spool, process, staging, and receipt residue is zero.
- [x] **NO REGRESSION (complete hostile and public band)** — the guarded exact
  policy/capture/store/resume/isolation/corpus/qualification/gate/transport/
  materialization/hosted/correctness/capability/public band reports
  `All tests successful.` at Files=33/Tests=332 in 763 wallclock seconds. It includes
  pinned-host pass, unmatched-host informational behavior, unavailable-provider
  non-pass, CI selection, and every named hostile mutation. T1750/T1794/T1795
  pass at Files=3/Tests=20; all mdBook chapters test and the 94-file render was
  removed exactly. Knowledge Map closes at 1,160 facts/6,286 questions; claim
  inventory/dispositions close 1,909/1,909 with no gap, and live-document
  containment passes after removing duplicated card prose rather than raising
  an allowance. Staged acceptance and doctrines retain final commit ownership;
  no support, capacity, or whole-product claim expands.
  The claim-set regression also exposed a stale repository-default census:
  T1750 last changed at `6702f48e0`, before later tracked records populated the
  third shard, yet still expected two shards and 31 records. The watcher now
  derives the current bounded registry result exactly at three shards, 53
  records, 52 published claims, and one fixture; its hostile finite-set,
  ordering, tracking, duplicate, and cap controls are unchanged.

## Acceptance Checklist (.18.1, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` locates the `.15` parent definition at architecture-selection commit `2e2f7d25e`; all seven later child nodes are `done`, but no later closure changed the parent from `active`. The audit's exact numeric evidence also changed a claim-inventory source, so the derived inventory required regeneration rather than hand-editing.
- [x] **ADDRESSED (verified)** — `.15` is now closed with its exact VHDL/GHDL/OSVVM evidence and nonclaims; `.18.1` carries the complete disposition/owner matrix; the existing HIAL/VIAL card is compacted and rerouted; and the generated Knowledge Map and claim inventory match the staged source tree without a ceiling or allowance increase.
- [x] **NO REGRESSION** — `knowledge-map: OK` reports 1,160 facts, 6,290 unique questions, 6,462 occurrences, and 138 shards; the staged task, Memory, relative-path, claim, containment, locality, README, and `[doctrine] all doctrine checks passed` gates are green.

## Acceptance Checklist (.18.2, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — the reader-facing entrypoints encoded an implementation timeline instead of a current product model: README commit `ecd29b6a4` routed its short manual list to the implementation blueprint; SUMMARY commit `2e2f7d25e` flattened the HIAL/VIAL overview beside specialist evidence; and `git log -S` for the stale `.15`-active sentence traces the contradictory book wording to `9729f1f0c` and its later duplicate to `6a489464d`, after every VHDL child had closed.
- [x] **ADDRESSED (verified)** — README and SUMMARY now route one Start Here overview with nested specialist evidence; the backlog is future-only; the overview opens with public/private/review/unavailable/evidence availability classes and stable navigation; the existing Knowledge Card points at that route; and the 13 removed duplicate quantitative candidates are retired from the exact claim-disposition join rather than left stale.
- [x] **NO REGRESSION (machine truth, book, and containment)** — t1796 and the guarded capability/scale/entry-path band each report `All tests successful.` at `Files=1, Tests=4` and `Files=5, Tests=28`; hostile category removal is covered. Every mdBook chapter tests, the repository-local HTML build succeeds, and the claim inventory/disposition join closes without gaps. The staged Knowledge Map, relative-path, task-integrity, containment, README, locality, and `[doctrine] all doctrine checks passed` gates are green; no product or support claim changes.

## Acceptance Checklist (.18.3, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — the public source-to-result lifecycle was
  implemented but not available as one task-oriented user reference. `git log
  -S'# VIAL Public Tooling Version-1 Contract'` identifies selection commit
  `d34da3254`, while `git log -S'## Shipped public source, planning, and
  execution tooling'` identifies closeout commit `dfe87f536` as the long
  architecture-chapter workflow origin. The required Knowledge Map query
  returned no direct lifecycle answer, confirming the reader still had to
  reconstruct the path across the overview and normative contracts.
- [x] **ADDRESSED (verified)** — selected 16dg now owns the runnable public
  lifecycle; the architecture overview routes to it instead of duplicating
  workflow prose; SUMMARY and the public-tooling Knowledge Card expose the
  route; and t1797 derives and executes its source, review, plan, schema,
  artifact, diagnostic, atomicity, cleanup, private-boundary, and runtime-gate
  claims from current machine contracts. The one deleted chronology candidate
  is retired from the exact claim-disposition join, and maintained-reference
  growth is authorized without raising a ceiling.
- [x] **NO REGRESSION (public contract, book, and residue)** — t1797 and the
  guarded six-file focused band report `All tests successful.` at `Files=1,
  Tests=6` and `Files=6, Tests=30`; the full runtime integration keeps its
  intentional Darwin qualification guard. Every mdBook chapter tests and the
  repository-local HTML build succeeds. Generated book/test roots, public-plan
  targets, collision fixtures, and VIAL staging residue are absent. Knowledge
  Map, claims, containment, relative paths, task integrity, staged acceptance,
  locality, README, and doctrines remain required before commit; no product or
  support claim expands.

## Acceptance Checklist (.18.4, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` locates the public portable
  runtime at commit `dfe87f536`, the handwritten AHB parity closure at
  `c95160d53`, the portable-VHDL gallery at `ab8b1af24`, and the OSVVM gallery
  at `4f350f29c`; required Knowledge Map queries returned those specialist
  authorities but no direct checked-source AHB tutorial. The shipped path was
  therefore executable yet required readers to reconstruct one workflow from
  four separately introduced evidence families.
- [x] **ADDRESSED (verified)** — selected 16dh starts from the checked AHB HIAL
  and `.vial` sources, gives runnable check/normal/terse/plan/public-run
  commands and exact outputs, explains the IAL2-to-IAL1-to-IAL0 review route,
  typed observations and logical time, compares the two normalized outcomes,
  enumerates the exact nineteen handwritten parity paths, and keeps portable
  VHDL and OSVVM inspection/qualification distinct. T1798 executes or
  byte-checks every promised path, checks atomic replay and cleanup, and rejects
  hostile documentation mutations without widening public support.
- [x] **NO REGRESSION (runtime, qualification, book, and residue)** — t1798 and
  the entry/lifecycle/tutorial band report `All tests successful.` at `Files=1,
  Tests=6` and `Files=3, Tests=16`; the guarded eleven-file runtime/parity/VHDL/
  OSVVM/documentation band reports `All tests successful.` at `Files=11,
  Tests=64`, with only the existing exact-provider qualification guards skipped.
  Both VHDL gallery refresh checks pass, every mdBook chapter tests, and the
  repository-local HTML build succeeds before exact removal. Knowledge Map,
  claims, containment, relative paths, task integrity, staged acceptance,
  locality, README, and `[doctrine] all doctrine checks passed` remain required
  before commit; no command, schema, backend, runtime, parity, capability,
  support, or product behavior changes.

## Acceptance Checklist (.18.5, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — required Knowledge Map queries returned no
  direct legacy-to-VIAL migration answer. `git log -S` locates IAL1 observation
  selection at `f3fa55646`, the UVM passive-monitor implementation at
  `d867815f3`, the VHDL observation-package implementation at `ab06754e7`, and
  the handwritten AHB parity closure at `c95160d53`. Those independently stable
  surfaces had exact specialist evidence but no single consumer-safe migration
  policy joining retain, parallel-successor, behavioral migration, and rollback.
- [x] **ADDRESSED (verified)** — selected 16di gives an exact four-row state
  matrix, executes the retained schedule/UVM/VHDL commands, distinguishes the
  native-UVM and portable-VHDL/OSVVM successors, maps legacy observation shapes
  to typed bridge endpoints/probes and logical-time behavior, preserves the
  handwritten AHB oracle, and defines side-by-side rollout, rollback, cleanup,
  and nonclaims. T1799 derives public legacy target/manifest truth, executes the
  typed VIAL plan and unavailable-backend failure, checks all three galleries,
  binds the parity source/producer/watcher, and rejects hostile prose changes.
- [x] **NO REGRESSION (legacy, bridge, reader path, and residue)** — t1799 and
  the guarded seven-file legacy/entry/lifecycle/tutorial/migration band report
  `All tests successful.` at `Files=1, Tests=5` and `Files=7, Tests=28`.
  The guarded full HIAL/VIAL contract/backend/documentation band reports
  `All tests successful.` at `Files=18, Tests=103`; only the two explicit
  Darwin runtime qualification guards skip. Every mdBook chapter tests, the
  repository-local HTML build succeeds before exact removal, and all three
  successor gallery checks pass. Knowledge Map is current, claim dispositions
  close 1,895/1,895 with zero gaps, and containment accepts the authorized book
  delta without a ceiling or allowance rise. Relative-path, task-integrity,
  staged-acceptance, locality, README, and all 12 registered doctrine checks
  are green; no legacy byte, public command, source, schema, manifest,
  backend, runtime, parity, capability, support, or product behavior changes.

## Acceptance Checklist (.18.6, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — required Knowledge Map queries returned no
  direct consolidated VIAL backend/capability/parity/scale/troubleshooting
  answer. `git log -S` traces public tooling to `c95160d53`, native-UVM matrix
  truth to `7725789a4`, qualified VHDL truth to `895ea33bd`, and public
  scale-regression capability truth to `2d16175c4`; no history exists for the
  selected 16dj reference. Readers therefore had exact specialist authorities
  but no bounded support matrix or diagnostic route joining them.
- [x] **ADDRESSED (verified)** — selected 16dj derives seven exact profiles and
  seven support-accounting rows from current machine contracts, distinguishes
  public, private-qualified, review-only, experimental, unavailable, and
  regression evidence, preserves every compile/runtime/result/parity and
  capacity nonclaim, and gives galleries, provider behavior, diagnostic phases,
  decision routes, cleanup, and specialist links. T1800 independently derives
  the profiles, stages, diagnostic vocabulary, gallery/provider/scale behavior,
  and cleanup coordinates, then rejects hostile availability, version, support,
  parity, provider, and residue mutations.
- [x] **NO REGRESSION (machine truth, readers, claims, and containment)** —
  standalone t1800 and the five-file reader band report `All tests successful.`
  at `Files=1, Tests=5` and `Files=5, Tests=26`. The guarded full HIAL/VIAL
  contract/backend/scale/documentation band reports `All tests successful.` at
  `Files=19, Tests=7,189`; only the two explicit Darwin runtime qualification
  guards skip. Every mdBook chapter tests, the repository-local HTML build
  succeeds before exact removal, and all three gallery checks pass. Knowledge
  Map is current, claim dispositions close 1,895/1,895 with zero gaps, and
  containment accepts the authorized book delta without a ceiling or allowance
  rise. Relative-path, task-integrity, staged-acceptance, locality, README, and
  all 12 registered doctrine checks are green; no public or product behavior
  changes.

## Acceptance Checklist (.18.7, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — after the committed five-reader suite
  passed, a separate exact phrase search found six activation-era progress
  claims still presented in deep 16d architecture prose. `git log -S` traces
  them to generator, backend-cap, cross-family-cap, cap-parent, and measurement
  activation commits `125e4981e`, `f6b2f8504`, `02768a427`, `4ee0dc12a`, and
  `897c72532`; the existing entry-path watcher checked only the stale `.15`
  parent sentence. Strengthening t1796 first produced the expected RED at its
  machine/human availability join.
- [x] **ADDRESSED (verified)** — the six sentences now state the completed
  generator, backend/runtime cap, cross-family closeout, and measurement state
  without changing any technical contract or support boundary. T1796 retains
  an exact six-phrase negative oracle. Independent local-destination and anchor
  checks close every selected reader link, while the existing lifecycle,
  tutorial, migration, and capability watchers continue deriving commands,
  schemas, results, profiles, diagnostics, parity, scale, providers, and
  cleanup from machine authorities.
- [x] **NO REGRESSION (independent activity closeout)** — post-repair t1796
  passes at `Files=1, Tests=4`; the final guarded 19-file HIAL/VIAL band reports
  `All tests successful.` at `Files=19, Tests=7,189`, with only two explicit
  Darwin runtime qualification guards skipped. Every mdBook chapter tests and
  the HTML build succeeds before exact removal. Knowledge Map remains current;
  claim dispositions close 1,895/1,895 with zero gaps; containment records only
  the authorized 0/+3/+50 book delta and no ceiling increase; exact manual,
  build, staging, log, binary, Git, and watcher residue checks are clean.
  Relative-path, task-integrity, staged-acceptance, locality, README, and
  all 12 registered doctrine checks are green; no public or product behavior
  changes.

## Acceptance Checklist (.19, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — decision `0034` establishes that VIAL's
  expressive ceiling is verification intent rather than synthesizability, but
  the live tree retained only one undecomposed `.19` selector. The version-1
  source contract fixes a closed grammar and typed projection, while
  `FSM::Support::VIALNativeUVMEmissionContract` labels its broader UVM
  structures private previews with runtime/result/parity unqualified. Thus
  widening v1 or exposing preview records would break compatibility and claim
  backend scaffolding as language meaning. The required Knowledge Map query
  had no direct decomposition answer; `git log -S` traces both the terse/normal
  rule and proposed `.19` owner to semantic implementation commit `be9c74163`;
  t/1796 and t/1800 remain the independent public-boundary watchers.
- [x] **ADDRESSED (verified)** — decision `0034` now preserves v1 and selects
  additive v2 normal/terse growth; `.19` owns 14 active activity containers
  and 85 proposed executable lanes spanning the full selected taxonomy. Each
  family has target-free source, typed compiler, portable-SystemVerilog,
  native-UVM, VHDL/OSVVM, and qualification/documentation ownership, while the
  foundation and closeout own compatibility, capabilities, quality, scale,
  migration, and later-family admission. The first duplicate ADR draft was
  removed after containment rejected it. The existing decision remains 113
  lines; the Knowledge Card is compacted to 139 lines;
  `doctrine/live_document_size/surfaces.jsonl` carries only the exact mdBook
  delta authority; and `doctrine/claim_verification/inventory.jsonl` is the
  fresh producer-derived inventory.
- [x] **NO REGRESSION (independent selection closeout)** — task integrity
  reconstructs 1,205 nodes. The focused relative-path, containment,
  claim-inventory/disposition, reader-entry, and capability suite passes at
  `Files=6, Tests=40`. Every mdBook chapter tests and the HTML build succeeds
  at 98 files/22,040 KiB before exact removal. Knowledge Map is current at
  1,160 facts/6,295 questions/6,467 occurrences/138 shards; claim dispositions
  close 1,895/1,895 with zero gaps; maintained-reference authority closes the
  exact 63-file/57,646-line/3,142,988-byte book with a 0/+27/+1,525 delta and
  no ceiling or allowance rise. Final staged acceptance and all 12 doctrines
  pass with no build, artifact, task-local, or brief residue and no source,
  semantic, bridge, plan, backend, runtime, parity, capability, support,
  diagnostic, provider, or product behavior change.

## Acceptance Checklist (.19.1.1, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — the required Knowledge Map query had no
  exact version-2 source/versioning answer. `git log -S` locates the closed v1
  grammar at contract commit `08f59167b` and the additive-v2 decision at
  `98d6b69cf`; the current parser and projection route accept only version 1.
  Widening those records in place would mutate v1 compatibility, while adding
  a monolithic root contract would consume the focused-doc transition's final
  line allowance.
- [x] **ADDRESSED (verified)** — a bounded maintained VIAL reference selects
  one new `intents` section, normal/terse roots, exact schema names, immutable
  v1 dispatch, same-version imports, explicit initially unavailable adapters,
  deterministic non-mutating whole-catalog migration, compatibility identity,
  limits, diagnostics, validation, nonclaims, and rollback. Its direct landing
  and semantic part are independently registered with exact aggregate-change
  authority; the generated focused index classifies the landing, the mdBook
  publishes the selected/not-shipped boundary, and the Knowledge Card answers
  the durable v2 contract question.
- [x] **NO REGRESSION (v1, references, claims, and residue)** — the focused
  v1/source-tooling/index/claim/reader/support band reports `All tests
  successful.` at `Files=7, Tests=60`. Every mdBook chapter tests and the
  98-file/22,048-KiB repository-local render is inspected and removed. The
  Knowledge Map is current at 1,160 facts/6,296 questions/6,467 occurrences/138
  shards; claims close 1,896/1,896 with zero gaps; live-document authority and
  containment accept both exact references with no ceiling increase. Task,
  paths, locality, README, staged acceptance, all 12 doctrines, and exact
  build/brief cleanup pass; no product behavior or support claim changes.

## Acceptance Checklist (.19.1.2, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean contract commit `c43e158e8`
  requires additive v2 without widening v1, but `FSM::VIAL::Parser`,
  `SourceProjection`, `SemanticBuilder`, `SemanticIR`, and `SemanticReport`
  admitted only version 1. Pre-change executable identities are pinned in
  t1801. `git log -S` plus blame also prove the selected prose misnamed one
  legacy diagnostic: commit `be9c74163` made bounded version validation reject normal non-v1
  imports before its later parse-error branch, while `50a0d7d393` owns the
  terse style error. The first Knowledge Map query had no implementation
  answer; the v2 contract card supplied the selected boundary.
- [x] **ADDRESSED (verified)** — root-version dispatch retains a v1-only
  catalog normalizer and sends v2 to one version-aware projection normalizer
  plus isolated `SemanticBuilderV2`. The new builder validates the closed
  envelope, import adapters, family shapes/revisions, and all selected family
  bounds before reusing the frozen v1 builder for base declarations and
  fixtures. It constructs exact immutable v2 IR/report/diagnostic/projection
  records, authored empty-intents provenance, and a cross-version base
  compatibility projection. Public tool and planning v1 guards reject v2;
  the CLI import helper exposes no v2 path before `.19.1.7`.
- [x] **NO REGRESSION (source, downstream, docs, and containment)** — the
  source/semantic/tool/plan band reports `All tests successful.` at
  `Files=4, Tests=34`; the portable-emission/runtime band reports success at
  `Files=3, Tests=9`, retaining two explicit Darwin qualification skips. The
  five pinned v1 identities remain exact. Every mdBook chapter tests; the
  inspected repository-local build contains 98 files/22,056 KiB and is
  removed exactly. Knowledge Map and claim joins are current; maintained
  references accept the exact book and VIAL deltas with no ceiling increase.
  The saturated 1,200-line rationale ledger correctly rejected another entry,
  so the rationale remains in this task, reference, card, regression, and Git.
  Task integrity, relative paths, locality, README, staged acceptance, and all
  doctrines pass with no generated build, temporary artifact, or brief
  residue and no family/backend/runtime/support promotion.

## Acceptance Checklist (.19.1.3, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean v2 parser commit `fe480cd24`
  stopped before all downstream phases: `git log -S` traces the exact v1-only
  ExecutionIR and plan schemas to `44dbecd1a`, the temporary v2 PlanBuilder
  rejection to `fe480cd24`, and the v1 result producer to `dfe87f536`. The
  required Knowledge Map query returned no common-envelope implementation
  answer. Without a separate versioned carrier and shared validator, accepting
  families next would either widen frozen v1 records or permit phase-specific
  shapes to lose typed meaning and provenance.
- [x] **ADDRESSED (verified)** — the new machine contract closes and bounds
  every common semantic-family record from typed semantic node through bridge
  binding, execution, plan, per-family result, and content-derived source map.
  It rejects missing/duplicate/contradictory meaning, unproved or unmapped
  bindings, parser residue, forged provenance, missing required results/effects,
  and excessive depth/count/bytes. SemanticIR consumes the same family
  validator. A separate v2 execution wrapper carries only empty-family base
  meaning through the unchanged HIAL bridge/v1 binder, then constructs distinct
  v2 ExecutionIR/plan identities and capabilities. Focused tests independently
  pin v1 hashes, exercise the complete synthetic phase chain and hostile
  mutations, prove deterministic defensive v2 carriers, and enforce v1
  backend/result rejection before artifacts or mislabeled manifests.
- [x] **NO REGRESSION (compiler, docs, claims, and containment)** — the final
  RAM-guarded eleven-file frontend/bridge/execution/public-tool/plan/backend/
  reader band reports `All tests successful.` at `Files=11, Tests=70`, with
  only the existing opt-in Darwin runtime qualification skip; standalone t1802
  reports `Files=1, Tests=5`. Every mdBook chapter tests, and the inspected
  repository-local HTML render contains 98 files/22,064 KiB before exact
  removal. V1 ExecutionIR/plan hashes and plan identity remain pinned. Knowledge
  Map, claim inventory/dispositions, exact maintained-reference authorities,
  relative paths, task integrity, locality, README, staged acceptance, and all
  12 doctrines are green with no ceiling rise or generated residue. The
  saturated 1,200-line rationale ledger is unchanged; durable rationale lives
  in this task, the maintained contract, Knowledge Card, regression, and Git.

## Acceptance Checklist (.19.1.4, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean carrier commit `c246314be`
  deliberately stopped at an empty-family v2 envelope. The required Knowledge
  Map query had no registry/profile answer. `git log -S` traces public capability
  ownership to `50a0d7d39` through `2d16175c4`, portable emission support to
  `201590d84`, the first-family-only v2 semantic rejection to `fe480cd24`, and
  runner lifecycle delegation to `037c962fd`. Those separate lists and local
  guards could neither express one selected taxonomy nor prove complete,
  profile-isolated rejection before downstream work.
- [x] **ADDRESSED (verified)** — one immutable content-addressed registry owns
  twelve selected revision-1 family namespaces, task owners, reserved effects,
  dependencies, common bounds, stage/backend maturity, three exact profiles,
  and v1 public capabilities. Functional maturity remains unavailable. Parser,
  planner, portable emitter, and runner consume the same negotiator; complete
  schema/profile/family/revision/dependency/capability/effect failures precede
  SemanticIR, HIAL review, artifact, workspace, and process output. The v1
  tooling JSON hash remains exact. T1803 covers defensive/deterministic shape,
  profile isolation, complete rejection, wrong revisions, wrong profiles,
  hostile phase carriers, and absence of partial or filesystem output.
- [x] **NO REGRESSION (compiler, references, claims, and residue)** — the final
  RAM-guarded v1/v2 compiler/tool/backend/reader band reports `All tests
  successful.` at `Files=12, Tests=75`, with only the existing explicit Darwin
  runtime skip. Every mdBook chapter tests; the inspected 98-file/22,080-KiB
  repository-local render is removed. Semantic partitioning keeps the exact
  three-file VIAL reference at 492 lines/26,982 bytes with its largest part at
  344 lines/18,690 bytes and no debt or ceiling rise. Knowledge Map parity is
  1,160/6,298/6,469/138; claims close 1,896/1,896 with zero gaps. Syntax, diff,
  task, paths, locality, README, containment, staged acceptance, all doctrines,
  and binary/log/build residue checks are green. No family implementation,
  v2 backend/runtime/result/parity, public-v2, support, or v1-success change.

## Acceptance Checklist (.19.1.5, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean registry commit `6927bfcfb`
  intentionally registered only the portable-SV backend, while `git log -S`
  traces native-UVM's local v1 schema admission to `5a1805f52` and portable-
  VHDL's duplicate capability list to `ab8b1af24`. The required Knowledge Map
  query returned no common adapter answer. The four emitters therefore had no
  one typed/version-consistent family preflight or shared place to report exact
  target mechanism and maturity without risking cross-profile inference.
- [x] **ADDRESSED (verified)** — one closed content-addressed adapter registry
  owns all four exact private emitters, target mechanisms, typed ExecutionIR
  boundary, accepted v1 schema/profile, output/source-map schemas, atomic
  artifact model, and independent emission/compile/runtime/result/parity/public
  maturity. Every family maps to all four profiles but remains unavailable on
  each. T1804 proves deterministic defensive data, target-mechanism isolation,
  exact maturity, typed/version consistency, complete unknown-family/effect
  rejection, backend-local diagnostics, zero partial artifacts, and OSVVM
  rejection before portable delegation or provider verification.
- [x] **NO REGRESSION (backend behavior and documentation)** — the final
  RAM-guarded compiler/backend/reader band reports `All tests successful.` at
  `Files=18, Tests=224`, with only the two existing explicit Darwin runtime
  skips. Every mdBook chapter tests; the inspected 98-file/22,088-KiB local
  build is removed. The v1 tooling SHA-256 remains exact. Knowledge Map reports
  1,160 facts/6,300 questions/6,471 occurrences/138 shards; claim dispositions
  close 1,896/1,896 with zero gaps. Exact book/VIAL reference authorities,
  containment, syntax, task/path/locality/README, staged acceptance,
  `[doctrine] all doctrine checks passed`, and task-local residue checks are
  green without a ceiling rise. No successful v1 output shape or byte, family
  implementation, v2 emission/runtime/result/parity, public v2 tooling,
  provider access, support state, or HIAL behavior changes.

## Acceptance Checklist (.19.1.6, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean adapter commit `94356f175`
  deliberately stopped at typed backend seams and unavailable family maturity.
  The required Knowledge Map query returned no usability/generated-artifact
  quality answer. `git log -S 'my @RESULT_KEYS'` traces the four independently
  evolved emitter result shapes to `201590d84`, `5a1805f52`, `3291217e8`, and
  `4f350f29c`; before this slice, no common executable contract checked their
  readability, exact artifact shape, source-map integrity, bounded cost, or
  absence-driven elision, and no finite gate kept public VIAL text and typed
  semantics free of target-language and methodology vocabulary.
- [x] **ADDRESSED (verified)** — one closed content-addressed quality contract
  now owns four author-surface kinds, all maintained public VIAL fixtures,
  target-free semantic carriers, nine witnessed forbidden-vocabulary rules,
  and the four exact backend artifact profiles. Its evaluators report six
  objective backend dimensions, exact role sets, conditional probe elision,
  complete source-map identity/coverage/span checks, readability bounds, and
  source/artifact/map budgets. T1805 applies the contract to real repeated
  emissions from every backend and proves each author rule and backend
  dimension through focused hostile controls without changing an emitter.
- [x] **NO REGRESSION (v1/v2 semantics and all backend routes)** — the
  RAM-guarded t1801–t1805 band reports `All tests successful.` at `Files=5,
  Tests=27`; standalone t1805 reports `Files=1, Tests=7`, and the final
  compiler/backend/reader band reports `Files=19, Tests=146` with only the two
  existing explicit Darwin runtime skips. The quality module and regression
  each report `syntax OK`. Every mdBook chapter tests; its inspected
  repository-local 98-file/22,112-KiB build is removed. Knowledge Map is
  current at 1,160/6,303/6,474/138; claim dispositions close 1,899/1,899 with
  316 claim records, 982 gates, 601 reviewed incidentals, and zero gaps/open
  owners. Containment accepts the exact 63-file/57,842-line/3,154,862-byte book
  and 3-file/594-line/33,673-byte VIAL reference with no ceiling rise. Existing
  v1/v2 projections, the common family envelope, registry, and all four adapter
  seams remain green. Task/path/locality/README, staged acceptance,
  `[doctrine] all doctrine checks passed`, and exact build/artifact/log/brief
  residue checks are green with no accepted-source, semantic, backend-byte,
  runtime, parity, capability, support, provider, or HIAL behavior change.

## Acceptance Checklist (.19.1.7, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean quality commit `714eef6e4`
  deliberately stopped with public tooling at v1. The required Knowledge Map
  query returned no public-v2 closeout answer. `git log -S
  '_v1_tool_version_diagnostic'` traces the intentional v1-only public guard
  to `fe480cd24`; the selected v2 contract already required distinct request,
  result, migration, plan, projection, style, compatibility, and diagnostic
  identities. A hostile mixed-catalog control additionally exposed the v1
  parser's earlier `VIAL_LIMIT_ERROR` ordering at imported version 2.
- [x] **ADDRESSED (verified)** — one explicit v2 CLI/API dispatch now exposes
  capabilities/check/format, non-mutating whole-catalog v1-to-v2 migration,
  and empty-family planning without changing the no-selector v1 route.
  Migration returns canonical bytes, source identities/maps, and an
  independently reproduced compatibility digest; its v2-only preflight
  converts mixed-catalog input to `VIAL_IMPORT_VERSION_MISMATCH` without
  changing the frozen v1 parser. Distinct schemas, action maturity, atomic
  publication, support rows, maintained fixtures, normative/user docs, and
  Knowledge Map truth close the public surface while v2 run, every expressive
  family, backend, compile, runtime, result, and parity remain unavailable.
- [x] **NO REGRESSION (v1/v2, readers, accounting, and residue)** — the final
  RAM-guarded band reports `All tests successful.` at `Files=19, Tests=7203`,
  with only the two established opt-in Darwin runtime qualification skips; the
  focused repaired accounting/foundation band passes at `Files=2, Tests=7118`.
  All changed Perl modules and tests report `syntax OK`. Every mdBook chapter
  tests, and its 98-file/22,188-KiB repository-local HTML build succeeds before
  exact removal with its scratch root. Knowledge Map validation reports
  `knowledge-map: OK` at 1,160 facts/6,306 questions/6,477 occurrences/138
  shards. Claim inventory derives 1,899 candidates; dispositions close
  1,899/1,899 with 316 claim records, 982 gates, 601 reviewed incidentals, and
  zero gaps/open owners. Containment authorizes the exact 63-file/58,039-line/
  3,164,374-byte book and 3-file/681-line/38,218-byte VIAL reference, records
  bounded warning debt, ratchets the latter's ceilings downward, and raises no
  ceiling. Task, path, locality, README, diff, staged acceptance, `[doctrine]
  all doctrine checks passed`, and exact build/artifact/log/binary/brief
  residue gates are green; no successful v1 byte/meaning, expressive family,
  v2 backend,
  runtime/result/parity, mixed-language, provider, support, or HIAL behavior
  changes.

## Acceptance Checklist (.19.2.1, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean foundation closeout `984271755`
  deliberately left every expressive family unavailable, and clean activation
  `06c331cb7` isolated lifecycle selection before any change. The required
  Knowledge Map query returned no lifecycle-source answer. Decisions 0034 and
  0036 state only the architectural intent. `git log -S` traces the rule that
  methodology lifecycle remains backend-private to `be9c74163` and the common
  registry's selection-only lifecycle reservation to `6927bfcfb`; neither
  defines source records, intrinsic order, defaults, logical deadline
  inclusivity, failure cleanup, or result meaning.
- [x] **ADDRESSED (verified)** — `docs/vial-spec/lifecycle-control-v2.md`
  selects one closed revision-1 grammar and typed expansion for dependency,
  readiness, fixture-background service, stimulus, completion, drain,
  shutdown, finalization, deadline, and failure records. Intrinsic ordering is
  non-weakenable; normal and terse retain one target-free family spelling; all
  waits and cleanup are finite logical-cycle intervals. T1807 derives the
  reserved registry effects and current public support independently, applies
  every executable author-vocabulary exclusion, and proves pre-implementation
  rejection returns no partial semantic report.
- [x] **NO REGRESSION (public truth, readers, claims, and residue)** — the
  RAM-guarded v2/reference band passes `Files=12, Tests=65`; all 63 mdBook
  chapters test, and the inspected repository-local 98-file/22,204-KiB HTML
  build is removed. The Knowledge Map validates at 1,161/6,315/6,486/139.
  Maintained-reference authorities accept the exact 63-file/58,099-line/
  3,167,016-byte book and 4-file/1,073-line/55,582-byte VIAL reference with
  zero ceiling increases. Claim inventory/dispositions, task/path/locality/
  README checks, staged acceptance, all registered doctrines, and exact
  build/artifact/log/brief residue checks are green. No v1 byte/meaning or v2
  accepted-source, compiler, backend, result, capability, support, provider,
  or HIAL behavior changes.

## Acceptance Checklist (.19.2.2, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean lifecycle-selection commit
  `e4f37d641` deliberately left the selected family unimplemented, and clean
  activation `16ac8564f` isolated the compiler work. The required Knowledge Map
  query returned no implemented lifecycle compiler-phase answer. The initial
  watcher reproduced `VIAL_FAMILY_UNSUPPORTED: intent family
  'lifecycle_control@1' is selected but has no implemented source stage`.
  `git log -S` traces the parser's selected-but-unimplemented family stop to
  `6927bfcfb` and the empty execution-family placeholder to `c246314be`; neither
  could preserve lifecycle records, order, bindings, operations, result
  completeness, temporal truth, or cumulative provenance.
- [x] **ADDRESSED (verified)** — `FSM::VIAL::LifecycleControl` now parses and
  expands the selected bounded lifecycle grammar, rejects duplicate/unknown/
  cyclic/over-limit meaning atomically, binds every node to reviewed fixture
  and domain facts with two type relations, and carries deterministic operation
  IDs and content-addressed source maps through the public v2 plan. Result
  validation requires the exact typed plan context, exact planned record,
  deadline, and provenance sets, inclusive deadline compliance, and monotone
  passing chronology before accepting a terminal status. T1808
  independently proves the maintained normal/terse fixture's twelve typed
  records, compatibility digest, public plan, capability ledger, support row,
  target/methodology exclusions, bounds, plan-relative result completeness,
  unavailable run, inclusive-deadline and passing-chronology rejection, and all
  three unavailable backend profiles.
- [x] **NO REGRESSION (v1/v2, readers, accounting, docs, and residue)** — the
  final repository-local, RAM-guarded focused band reports `All tests
  successful.` at `Files=14, Tests=7191`; all changed Perl modules and tests
  report `syntax OK`, and the public complete fixture reports `VIAL check passed
  (normal_v2)`. All 63 mdBook chapters test; its inspected 98-file/22,228-KiB
  repository-local render and scratch root are removed. `knowledge-map: OK`
  reports 1,161 facts/6,315 questions/6,486 occurrences/139 shards. Containment
  authorizes the exact 63-file/58,157-line/3,169,983-byte book and
  4-file/1,135-line/59,770-byte VIAL reference with zero ceiling increases.
  Claim dispositions, task/path/locality/README checks, staged acceptance,
  `[doctrine] all doctrine checks passed`, diff hygiene, and the exact
  build/artifact/log/binary/brief residue census are green. No successful v1
  bytes or meaning, v2 backend/emission/compile/runtime/result production/
  parity, non-lifecycle family, mixed-language, provider, support, or HIAL
  behavior changes.

## Acceptance Checklist (.19.2.3.1.1, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — the canonical maintained lifecycle plan
  at clean decomposition commit `12e2fe50b` placed a complete `service_ready`
  condition object inside readiness operand 2's `dependency_satisfied`
  `reference_id`. The new RED assertions failed on both the wrong kind and the
  non-scalar reference. Source inspection localized the defect to adjacent
  unparenthesized `map` expressions in
  `FSM::VIAL::LifecycleControl::_build_lifecycle`: Perl included the second
  map's objects in the first map's input list. `git log -S` independently
  traces both `dependency_satisfied` and `service_ready` construction to
  lifecycle compiler commit `bc137fc2f`. The Knowledge Map had no answer, and
  existing T1808 assertions did not recursively validate condition types.
- [x] **ADDRESSED (verified)** — dependency and service readiness conditions
  are now materialized by separately parenthesized maps before assembly. The
  module validates every normalized payload condition recursively against the
  exact four-key shape, permitted leaf vocabulary, scalar-or-null identities,
  and finite operand/depth/count limits. T1808 proves the exact
  dependency/dependency/service-ready order, rejects a reproduced
  object-valued reference substitution, and compares the corrected condition
  byte-for-byte across SemanticIR, ExecutionIR, and plan. The Knowledge Card
  and mdBook explain the repaired invariant.
- [x] **NO REGRESSION (compiler, backend boundary, docs, and residue)** — both
  changed Perl/test files report `syntax OK`; standalone T1808 passes
  `Files=1, Tests=5`; and the final RAM-guarded T1557/T1801-T1808 band reports
  `All tests successful.` at `Files=9, Tests=53`. Every one of the 63
  mdBook chapters tests. Knowledge Map regeneration reports 1,161 facts, 6,317
  questions, 6,488 occurrences, and 139 shards. Maintained-reference authority
  records the exact 63-file/58,163-line/3,170,330-byte book from a 0/+6/+347
  delta without raising any ceiling. Final task, path, locality, README,
  containment, staged acceptance, doctrine, diff, generated-artifact, log,
  binary, and brief checks are green. No v1 behavior, source grammar, HIAL
  bridge, backend/emission/compile/runtime/result/parity, capability/support,
  provider, or other-family change ships.

## Acceptance Checklist (.19.2.3.1.2, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — clean compiler-repair commit `1b25880f8`
  supplies valid typed lifecycle conditions, while clean activation commit
  `6b7c761d7` isolates backend-contract selection. The required Knowledge Map
  query returned no portable-SystemVerilog lifecycle mapping answer. Decisions
  0036/0043 and source inspection show one existing static scenario scheduler
  with scenario-local cycles plus a separate host-process supervisor, but no
  selected fixture-wide lifecycle clock, check seams, failure policy, or v2
  evidence schemas. The boundary audit additionally found that the private v1
  TraceValidator checks the exact object class but not its execution envelope;
  `git log -S` traces its introduction to `201590d84` and finds no exact v1
  schema guard.
- [x] **ADDRESSED (verified)** — Decision 0100 and the bounded normative VIAL
  part select one finite static fixture controller, three compiler-owned check
  seams, monotone fixture lifecycle time beside unchanged scenario-local time,
  inclusive deadline ordering, irreversible bounded failure cleanup, distinct
  v2 evidence schemas, cumulative source-map duties, atomic publication, and
  explicit nonclaims. T1809 derives the record/operation map from the maintained
  v2 plan, proves every public/backend route remains unavailable and
  artifact-free, proves Runner invokes no host process, and freezes the exact
  v1 emitted graph and normalized-result identities. It honestly characterizes
  the private validator's cross-version admission, which proposed child
  `.19.2.3.1.2.1` must repair before emitter work. The mdBook and Knowledge Map
  expose both the selected architecture and that prerequisite.
- [x] **NO REGRESSION (v1, public boundary, docs, claims, and residue)** — T1809
  syntax is valid and its standalone run passes `Files=1, Tests=6`; the final
  RAM-guarded v1 emitter/public reference plus complete T1801-T1809 band passes
  `Files=11, Tests=65`. Every one of the 63 mdBook chapters tests; the inspected
  repository-local HTML render contains 98 files/22,260 KiB and is removed with
  its empty test scratch root. Knowledge Map is current at 1,161 facts/6,320
  questions/6,491 occurrences/139 shards. Claim inventory derives 1,899
  candidates and dispositions close 1,899/1,899 with zero gaps/open owners.
  Maintained-reference authority accepts the exact 63-file/58,243-line/
  3,174,606-byte book and 5-file/1,496-line/76,666-byte VIAL reference with no
  ceiling increase. The rationale transition allowance is advanced to the
  exact 101-file/9,414-line/554,979-byte measurement plus one unchanged ratchet
  step; health targets and ceilings stay fixed. Task, path, locality, README,
  containment, generated-index, staged acceptance, doctrine, diff, artifact,
  log, binary, and brief checks are green. No v1 byte/meaning, backend behavior,
  v2 emission/compile/runtime/result/parity/public-run maturity, support,
  provider, other-family, or HIAL behavior changes.

## Acceptance Checklist (.19.2.3.1.2.2.1, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — the second clean pre-push gate reported
  `Failed test 'common project-wide checker is delegated' at
  t/1553-readme-routed-destination-pressure.t line 29` because T1553 copied the
  then-current `22 surfaces` output while the authoritative registry/checker
  correctly reported 23 after the selected VIAL reference joined the graph.
  The required Knowledge Map query returned no answer. `git log -S'22
  surfaces'` traces the recurrence to `ea1b76dd5`, where the same integration
  assertion was manually advanced from 20 to 22 instead of delegating the live
  cardinality.
- [x] **ADDRESSED (verified)** — T1553 now matches the stable common-checker
  success phrase and requires a numeric surface count without copying its exact
  value. T1554 deliberately retains exact counts for its fixed synthetic
  registries. The GREEN focused run proves both roles together against the live
  23-surface graph, and the adoption guide, mdBook include, Knowledge Card, and
  generated map record the authority distinction.
- [x] **NO REGRESSION (checker, docs, containment, and residue)** — the focused
  run reports `All tests successful.` at `Files=2, Tests=27`; T1553 reports
  `syntax OK`. All 63 mdBook chapters test, and its repository-local 98-file/
  22,260-KiB render succeeds before exact removal. `knowledge-map: OK` reports
  1,161 facts/6,321 questions/6,492 occurrences/139 shards. Live-document
  containment reports all invariants green at 23 surfaces, unchanged
  1,200-line DEVELOPMENT_NOTES, and zero ceiling increases. Claim inventory's
  independent census agrees at 12,270 numeric lines/1,899 candidates/2,670
  constants, and dispositions close 1,899/1,899 with zero gaps/open owners;
  documentation-path and task-tree gates pass, and the final staged doctrine
  driver reports `[doctrine] all doctrine checks passed`. No registry, ceiling,
  maintained-reference, product, VIAL/HIAL, capability, support, or runtime
  behavior changes.

## Acceptance Checklist (.19.2.3.1.2.2.2.1, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean full-CI run stalled because
  T313 delegated its success fixture to `can_run('true')`; mutable host `PATH`
  selected a Homebrew executable that remained before `main`. The production
  validator then waited without a deadline. The required Knowledge Map query
  returned no answer. Independent `git log -S` searches trace the success
  lookup to `ba8ea7840` and the success/failure pair to `602906bf1`.
- [x] **ADDRESSED (verified)** — T313 resolves the canonical already-running
  Perl interpreter and generates explicit success and failure programs below
  the repository-local test temp root. It passes their exact paths to the
  mocked validator inventory while hostile same-named PATH traps exit 97/98.
  The success route, unsupported-top prefix, tool-failure prefix, and unique
  failure-fixture diagnostic all pass; the source has no true/false lookup or
  fixed host-global fallback. The Knowledge Card makes the rule durable.
- [x] **NO REGRESSION (fixture identity, validation contract, and locality)** —
  T313 reports `syntax OK` and its standalone run reports
  `All tests successful.` at `Files=1, Tests=4`. The real-tool success subtest
  remains conditional on the unchanged validator discovery contract. No
  production module, contract/schema, VIAL/HIAL behavior, support claim, or
  artifact path changes; generated programs remain cleanup-owned under the
  standard repository-local test-temp environment. Knowledge Map validation
  reports 1,161 facts/6,322 questions/6,493 occurrences/139 shards. Claim
  inventory independently agrees at 12,270 numeric lines/1,899 candidates,
  and dispositions close 1,899/1,899 with zero gaps or open owners. Final
  staged task acceptance and the complete doctrine driver pass.

## Acceptance Checklist (.19.2.3.1.2.2.2.2.2, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` traces the unbounded
  `IPC::Cmd qw(can_run run)` validation launch to `51720be7b` and the reviewed
  test supervisor to `d630261e6`. The first post-wiring T313 run changed the
  former indefinite wait into `status=timed_out`; an independent two-second
  direct-script probe reproduced `/usr/bin/perl` stationary at `_dyld_start`,
  while T1669's explicit interpreter-plus-script argv completed. The exact
  off-volume sample was copied to the repository volume, verified byte/hash
  equal, consumed, and removed at both paths with an absent-residue check.
- [x] **ADDRESSED (verified)** — the reviewed engine is moved into
  `FSM::Support::ProcessSupervisor`, the test module is a thin delegating
  boundary, and only it plus HDL external validation can launch through the
  low-level engine. HDL steps use fixed 120-second/8,388,608-byte bounds from
  repository cwd with shell-free argv, split capture, process-group cleanup,
  stable status/diagnostic failure text, and no retry. Plain Perl tool scripts
  use explicit canonical-interpreter argv; T313 completes in under one second
  with five green top-level subtests, including all eight failure classes and
  installed Verilator/Yosys, while T1669 proves real hostile-tree cleanup.
- [x] **NO REGRESSION (real tools, adapters, contracts, docs, and residue)** —
  the widened process/HDL/manifest/JSON/defensive-copy suite reports
  `All tests successful.` at `Files=8, Tests=30`, including the full external
  HDL smoke and unchanged legacy supervisor oracle. All seven changed Perl and
  test files report `syntax OK`. All 63 mdBook chapters test; the inspected
  repository-local render contains 97 files/22,272 KiB and the new policy,
  then is removed exactly. `knowledge-map: OK` remains 1,161 facts/6,322
  questions/6,493 occurrences/139 shards. Claim inventory independently
  agrees at 12,273 numeric lines/1,900 candidates/2,671 constants; the one new
  safety-policy claim has distinct re-derive/falsify/durability evidence and
  zero open owner. Probe, sample, process, render, log, and brief residue is
  absent. Final staged task acceptance reports
  `[task-acceptance] OK` with independent Git-history root-cause and prove-summary
  no-regression evidence; the complete doctrine driver reports
  `[doctrine] all doctrine checks passed`.

## Acceptance Checklist (.19.2.3.1.2.2.3.2 implementation, verification pending; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — the third clean complete-CI run reported
  `Failed test 'generated HDL passes Verilator lint and Yosys synthesis' at
  t/1524-ial2-ahb-exact-two-paired-busy-composition-profile-alias.t line 226`
  after valid Yosys synthesis crossed the aggregate capture ceiling and returned
  `status=output_limited`. The test-first contract then failed at
  `t/313-hdl-external-validation-contract.t line 25` because the selected quiet
  and failure-excerpt policy getters did not yet exist. Exact diagnostic
  signature: `BEGIN failed--compilation aborted at t/313-hdl-external-validation-contract.t line 25`.
- [x] **ADDRESSED (verified)** — HDL validation now uses native quiet Yosys argv
  in both modes and byte-exact bounded per-stream failure excerpts without
  changing supervisor capture, timeout, cwd, cleanup, retry, caller-seal, split
  stream, or success-payload semantics. T313 proves exact-boundary and
  boundary-plus-one stdout/stderr behavior; T1524 now admits the valid large
  synthesis under the unchanged process and RAM guards.
- [x] **NO REGRESSION (focused implementation, complete gate pending)** — the
  focused validator, T1524, supervisor, manifest, backend-section, JSON
  round-trip, and defensive-copy runs each report `All tests successful.`; the
  largest surrounding band reports `Files=17, Tests=26`. All mdBook chapters,
  Knowledge Map, claim inventory/dispositions, diff hygiene, and exact generated
  residue removal are green. Fresh maintained-reference authority accepts the
  exact book delta without any ceiling increase. The implementation commit is
  explicitly
  verification-pending until the complete RAM-guarded pre-push gate reruns from
  its beginning.

## Acceptance Checklist (.19.2.3.1.2.2.4 recovery ownership and inventory sync, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'command => $command'`
  identifies `07d9df7eb` as the unbounded T1467 launch owner. The OS sample
  places its Rust child at `_dyld_start` before application code. After TERM
  to that verified child, T1467 reports the failed command assertion at line
  59. The new Knowledge Map question changes the claim inventory's source
  census digest; leaving the derived inventory unchanged reports inventory drift.
- [x] **ADDRESSED (recovery evidence and derived inventory)** — the pending
  `.4` leaf owns bounded replay and policy selection; the task and resume
  pointer preserve the known failure while the complete run continues. The
  existing parity card retains its facts in shorter prose and removes only
  duplicated landing-page evidence links still present in its reverify command.
  The regenerated inventory changes its source digest while retaining its
  candidate and constant sets. No Rust implementation or test behavior is fixed.
- [x] **NO REGRESSION (knowledge, census, dispositions, and diff)** —
  `knowledge-map: OK` includes cached/direct query parity; the inventory's
  current-surface and independent numeric-line censuses agree, the disposition
  join remains closed, and `git diff --check` passes. The full suite is still
  running with T1467 failed; no complete-CI success is claimed.

## Acceptance Checklist (.19.2.3.1.2.2.5 recovery ownership and inventory sync, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'my $status = system {$absolute} $absolute'`
  identifies `25c815326` as the neutral core's unbounded verifier-launch owner.
  Independent freshness/version OS samples place both children at `_dyld_start`.
  T1554's partial TAP has no terminal plan after verified process-tree termination.
  The added Knowledge Map answer changes the inventory's source census digest.
- [x] **ADDRESSED (recovery evidence and derived inventory)** — pending `.5`
  owns policy selection; task, index, Memory, and the existing containment card
  retain the interrupted failure. The card keeps its answers and authorities
  in shorter prose within its prior byte budget. Regeneration synchronizes the
  derived map and inventory digest; no checker or test behavior is repaired.
- [x] **NO REGRESSION (knowledge, census, and diff)** — `knowledge-map: OK`
  includes cached/direct query parity; current-surface and independent numeric
  censuses agree with unchanged candidate/constant sets, and `git diff --check`
  passes. The full run remains failed/interrupted at T1467/T1554 while later
  tests continue; no complete-CI success is claimed.

## Acceptance Checklist (.19.2.3.1.2.2.6 recovery ownership and inventory sync, enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '#!/usr/bin/env bash'`
  identifies `30885823b` as T1595's fixture-launch owner; the OS sample places
  fake-uname's env process at `_dyld_start` before metric computation. The test
  reports `No subtests run` after its verified process tree receives TERM.
  The new Knowledge Map question changes the inventory source census digest.
- [x] **ADDRESSED (recovery evidence and derived inventory)** — pending `.6`
  owns deterministic bounded fixture-policy selection. Task, index, Memory,
  and the existing subprocess card retain the interrupted failure; the card
  preserves its prior contracts in shorter prose inside its prior byte budget.
  Derived map and inventory are synchronized; no runtime/test behavior changes.
- [x] **NO REGRESSION (knowledge, census, and diff)** — `knowledge-map: OK`
  includes cached/direct query parity, current-surface and independent censuses
  agree with unchanged candidate/constant sets, and `git diff --check` passes.
  Process inspection finds no surviving T1595 descendants; the outer RAM guard
  remains active with its original limits. Full-CI success is not claimed.

## Acceptance Checklist (.19.2.3.1.2.2.4.1 startup and policy selection; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'run('` identifies
  `07d9df7ebefe7618ad4581ee172fe24085a1d1df` as the unbounded T1467
  launch introduction. The retained recovery sample places the Rust child at
  `_dyld_start`; the bounded independent controls pass without diagnosing the
  OS cause. Module::ScanDeps and a separate literal import traversal agree;
  the prior architecture map omitted the newly reachable owners.
- [x] **ADDRESSED (verified)** — The task-local policy under decisions `0087`/`0101` selects the exact sealed
  build/oracle/program policy; implementation is separately owned by `.4.2`.
  Refreshed dated import counts and complete traversal-to-note membership
  agree. The policy-template delta has proposed review ownership. Diagnostic
  controls preserve the failed Perl-directory probe, and the fresh successful
  Rust/Perl payloads agree after T1467's normalized field projection.
- [x] **NO REGRESSION** — Guarded T1669: `All tests successful`,
  `Files=1, Tests=4`, `Result: PASS`; task integrity and diff hygiene pass.
  Generated-index, claim, containment, and staged doctrine gates report
  `[doctrine] all doctrine checks passed` in `doctrines-staged.log` under the
  owned diagnostic log root; the docs-only acceptance exemption is explicit.

## Selected Rust parity policy (.19.2.3.1.2.2.4.1)

This domain adapter applies decisions `0087` and `0101`; it introduces no new
cross-cutting process architecture. Its exact selection belongs to this task.

### Context

T1467 launches both the Perl oracle and Cargo through unbounded `IPC::Cmd`.
The failed recovery run sampled Cargo's Rust child before main at `_dyld_start`.
A separately contained direct replay passed; this does not diagnose the host
cause or erase the failed run. Independent bounded controls now also pass for
Cargo run, a fresh isolated offline build, its executable, and the Perl oracle.

A diagnostic initially resolved relative `$^X = perl` with `abs_path`, which
selected this repository's `perl/` directory. The engine correctly returned
`exec_error` with permission denied and proved cleanup. A separate invocation
of the validated executable passed. Executable identity must therefore be
validated, not inferred from a path-resolution result. Cargo adds another
identity boundary: a rustup proxy must retain its dispatch name or resolve the
selected real tool through a bounded rustup query.

### Selected contract

1. Add one private `FSM::Test::RustParityRuntime` policy adapter. Its public-to-
   tests operation accepts no arbitrary command, path, environment, or budget.
   Keep T1467's complete normalized parity projection unchanged.
2. Reuse `FSM::Test::ProcessSupervisor` and its shared support engine. Do not
   copy a process engine, import VIAL lifecycle authority, or add an alarm-only
   wrapper. Extend the existing exclusive-caller watcher for this adapter.
3. Resolve executable tools once from absolute inherited PATH entries,
   rejecting directories and non-executables. Retain selected identities so
   later PATH changes cannot substitute tools. For a rustup Cargo proxy,
   supervise its exact `which cargo` resolution and select the matching real
   `rustc` beside that Cargo binary. For a direct Cargo installation, resolve
   the selected rustc explicitly. A failed resolution remains failed.
4. Invoke the validated running Perl interpreter explicitly with `bin/fsmgen`,
   `--check-json`, and `t/corpus/direct_sreset_active_high.fsm`. Resolve a
   relative interpreter name through executable PATH entries; never treat
   `abs_path($^X)` alone as executable evidence.
5. Build the exact `fsmgen_portable_api` package and
   `fsmgen-portable-api-check-smoke` binary from `rust/Cargo.toml`, using
   `--offline --locked --message-format=json-render-diagnostics`. Fix its
   target root to `.artifacts/build/rust-parity`; implementation child `.4.2`
   selects a fresh owned directory beneath it for every operation. Use repository cwd,
   repository-local Cargo cache and temporary roots, and the selected rustc.
   Cargo/rustc and installed toolchain files are read-only host dependencies;
   downloads and global cache writes are not admitted.
6. Accept a successful build only with a unique matching compiler-artifact
   record for the exact package target and manifest. Validate the reported
   executable as a regular executable without symlink ancestry under the
   selected repository target directory. Never execute a prior artifact after
   build failure, a decoy record, or an ambiguous/missing artifact.
7. Execute that artifact directly with the exact fixture. Each stage gets one
   attempt, shell-free argv, separate streams, monotonic timing, one owned
   process group, and verified cleanup. Stop the parity operation on its first
   failure; do not use a passing control as a retry or a CI replacement.
8. Fix tool resolution, Perl oracle, and Rust execution at ten seconds and
   1,048,576 aggregate captured bytes per stage. Fix Cargo build at 120 seconds
   and 8,388,608 aggregate bytes. These are selected safety ceilings, not
   performance or capacity claims; callers cannot raise them.
9. Return a closed `fsmgen.test.rust_parity_result.v1` record carrying ordered
   stage results, failure stage, status, separate streams, and cleanup truth.
   Preserve nonzero, signal, timeout, output-limit, exec, descendant, and
   cleanup failures. T1467 must fail its TAP assertion for any failed stage.
10. Verify with the real parity fixture and hostile controls for invalid tool
    identity, PATH mutation, rejected caller options, stale/decoy artifacts,
    split output, timeout, overflow, nonzero/signal/exec failures, and a TERM-
    resistant descendant. Keep the shared mechanism's existing tests green.

### Evidence and limits

- **Re-derive:** the owned bounded replay uses the existing test supervisor
  around exact Cargo run, rustup tool resolution, an isolated offline build,
  its direct executable, and the explicitly selected Perl oracle. The retained
  records are under `.artifacts/logs/rust-parity-policy-20260906/`; T1467 and
  the tracked Rust manifest/projection independently identify the commands.
- **Falsify:** Cargo run and the freshly built direct executable both passed,
  refuting a universal startup failure. The invalid Perl directory failed at
  exec, while the independently validated interpreter passed. Every observed
  launched group was gone at completion. No OS root cause or full-CI pass is
  claimed; these are individual observations, not a reliability estimate.
- **Durability:** this task and decisions `0087`/`0101` preserve selection. The adapter,
  hostile watcher, and re-runnable parity gate are owned by sibling `.4.2` and
  remain an explicit missing implementation leg until that slice lands. The
  diagnostic records are supporting ignored evidence, not the sole authority.

### Consequences

Build and execution failures become attributable to distinct bounded stages.
The Perl reference, Rust smoke semantics, source fixture, parity fields, and
public capabilities remain unchanged. Selection alone closes no CI blocker;
implementation and a fresh complete guarded qualification are still required.

The first staged gate rejected the unnecessary additional decision record and
duplicated card summary against existing rollover-debt allowances. This complete
policy is retained here in its work-unit layer; the card routes to the richer
architecture note. No existing fact or enforcement ceiling is removed or raised.

## Acceptance Checklist (.19.2.3.1.2.2.4.2 sealed Rust parity; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'run('` identifies
  `07d9df7ebefe7618ad4581ee172fe24085a1d1df` as the unbounded T1467 launch
  introduction; the retained recovery sample places its child at `_dyld_start`.
  Initial T1810 RED reports `Can't locate FSM/Test/RustParityRuntime.pm`
  at `t/1810-rust-parity-runtime.t line 11`. This diagnoses the missing
  containment boundary; it does not claim an OS loader root cause.
- [x] **ADDRESSED (verified)** — Guarded T1467/T1669/T1810 GREEN reports
  `All tests successful`, `Files=3, Tests=13`, `Result: PASS` in
  `adapter-final.log`. Sealed tool/build/artifact/runtime controls preserve
  first failure, finite split-stream capture, signal identity, and proved
  TERM/KILL cleanup. Independent comparison with the previous Git version
  proves the entire normalized parity projection and helpers byte-identical.
- [x] **NO REGRESSION** — The shared-process/fixture/real-parity band reports
  `All tests successful`, `Files=3, Tests=13`; all changed Perl sources report
  `syntax OK`. `mdbook test docs/book` and the corrected root-derived HTML
  build exit zero. Exact render copy/hash/residue verification is below.
  Claim inventory independently agrees, and the final staged gate reports
  `[doctrine] all doctrine checks passed`, including fresh evidence-backed
  task acceptance, containment, locality, Knowledge Map, and dispositions.
  Full-CI and push qualification remain blocked by the separately owned work.

### Rust parity implementation artifact-location recovery

The implementation book build passed `--dest-dir ../../.artifacts/build/rust-parity-book-20260906`
assuming mdBook interpreted it from `docs/book`. Its terminal output instead
resolved the path from the repository working directory, creating the exact
build below the caller's `../../.artifacts/build/` on the repository volume.
This leaf owns immediate copy/verify/use/delete recovery into
`.artifacts/build/rust-parity-book-20260906`, a corrected root-derived build,
and an exact-old-path residue census. No parent directory or shared data is
owned for deletion. The successful render is not evidence of correct locality;
recovery completed: the initial copy verified all 98 files and 22,636,617
bytes by per-file SHA-256. The corrected command uses
`--dest-dir .artifacts/build/rust-parity-book-20260906` from the root and
exits zero at the repository-local destination. The rendered parity guidance
was inspected. Both the exact misplaced directory and the reviewed local render
were removed; an explicit residue census proves both absent. The per-file
manifest and terminal results are retained in `book-location-recovery.json`
under the owned log root. Only the exact session-owned leaves were deleted.

## Neutral verifier policy selection (.19.2.3.1.2.2.5.1)

The independent bounded original-T1554 replay completed once: exit zero,
18 terminal subtests, 12,858 stdout bytes, no stderr, and proved leader/group
cleanup. The diagnostic used a sixty-second wall and eight-MiB aggregate
capture. These are one invocation's observation and diagnostic bounds, not
reliability or capacity claims. `original-t1554.json` and its driver log under
`.artifacts/logs/live-document-policy-20260906/` retain the result. It falsifies
a universal fixture failure without erasing the prior interrupted gate or
claiming an operating-system loader cause.

`git log -S` identifies core execution introduction
`25c815326630d49a457d4393909fad8d659c753d`, and the T1554 `open3` introduction
`18e2dcbc65095003207102d1af4f2f7fa63b1ba3`. The current core forks a wrapper,
uses `system` for the declared program, and waits indefinitely; the wrapper
folds a child signal into a synthetic exit code. T1554 writes coverage input,
reads stdout then stderr, and waits without a wall. Therefore changing only
fixture shebangs cannot repair standalone verifier containment or split-stream
backpressure. The existing engine supplies the required process mechanics.

### Provisional boundaries and sequence — blocked before acceptance

- **One private engine:** move mechanics and closed result construction into
  `perl/Process/Supervisor/Engine.pm`, with no exports or public runner. Keep
  repository admission and the existing two-caller seal in
  `FSM::Support::ProcessSupervisor`; keep the test compatibility wrapper and
  all existing domain policies exact. The generic component must contain no
  project/harness identity. A source watcher admits only the existing support
  facade and the new neutral verifier facade as direct engine owners. This
  preserves the public seal; the present engine's private implementation
  routines are already internal rather than a security boundary against
  arbitrary Perl symbol access. Do not expose new low-level test calls.
- **Portable dependency:** the neutral checker resolves its own bundle library
  and the shared `perl/Process/Supervisor/Engine.pm` from runtime-derived paths.
  The portable adoption manifest/guide must enumerate this required neutral
  component; a relocated minimal package must run without any `FSM::` module,
  original checkout, home cache, or absolute persisted path. Do not copy a
  second process engine into the checker bundle.
- **Fixture policy:** add `FSM::Test::LiveDocumentFixtureRuntime` for T1554.
  Admit only immediate owned `fsmgen-*` directories under
  `.artifacts/tmp/live-document-size-tests`, fixed original checker/registry
  argv, validated coverage path lists, and the existing adapter-proof grammar.
  Resolve the executing Perl once, validate it as a regular executable, and
  retain identity after PATH mutation. Generated Perl fixtures use its absolute
  shebang, eliminating `env`; preserve all existing fixture assertions.
  Fix each checker call to thirty seconds and 8,388,608 aggregate bytes.
- **Finite coverage transport:** preserve `--coverage-stdin` and its NUL data
  semantics. The sealed fixture adapter serializes at most 1,048,576 bytes into
  its own regular non-symlink same-volume temporary file. Extend only the private
  mechanism's stdin handoff for that admitted file; absent input retains the
  existing immediate-EOF behavior. No caller-selected arbitrary input path,
  command, environment or budget reaches this adapter. Preserve signal, exec,
  split-stream, timeout and descendant-cleanup truth, and remove the exact input
  file after cleanup. Test admission, exact bytes/EOF and failure cleanup.
- **Standalone verifier policy:** place the project-neutral facade in
  `live-document-size/lib/LiveDocumentSize/VerifierRuntime.pm`. It admits only
  the root supplied to the neutral checker and the declared root-relative
  regular executable, with non-symlink ancestry and same-volume validation.
  Invoke that exact program directly; the neutral production policy does not
  reinterpret arbitrary user shebangs or pick an alternate tool after failure.
  Use root cwd, immediate-EOF stdin, one process group, one 120-second wall,
  and 8,388,608 aggregate captured bytes. Return separate streams and the shared
  exit/signal/exec/timeout/overflow/descendant/cleanup evidence without retry.
  Forward admitted output to its original stream, preserve the existing
  executed-success phrase and nonzero diagnostic phrase, and name signals as
  signals rather than synthesizing exit codes. Timeout/overflow/cleanup must
  make the checker fail. The schema and portable bounds belong in its contract.
- **Commit boundaries:** child .2 is the mechanical extraction and unchanged
  facade verification; .3 is sealed fixture/input containment; .4 is standalone
  neutral policy and portable adoption. Each updates the affected book/import
  guidance and completes COMMIT.md before the next begins. Do not run full CI
  until this repair and the separately owned RAM fixture repair are complete.

### Evidence legs and rejected alternatives

Re-derivation uses the exact source/history boundaries and the successful
contained original test above. Falsification preserves the earlier independent
freshness/version startup stalls; implementation watchers must inject timeout,
TERM resistance, overflow, split streams, nonzero and signal failures, and
prove a relocated neutral package cannot silently import adopting-project
code. The task, amended decision 0101, source-owner watcher, focused tests,
portable contract/adoption guide, book and Git are the durability chain.
Implementation legs are explicitly pending in children .2/.3/.4.

A copied engine would violate decisions 0087/0101 and drift in cleanup. Importing
`FSM::` policy into the neutral checker would violate its portable contract.
An alarm or outer RAM guard alone lacks the selected per-verifier wall,
split-stream and signal/cleanup guarantees. Adding a new public checker input
option solely for test plumbing is unnecessary; keep the existing stdin API.
The provisionally proposed finite values describe safety policy, not measured performance.

### Nested supervision falsification — verified blocker

Policy review identified a possible composition failure: both a sealed T1554
adapter and its future core-verifier adapter would create process groups.
An outer deadline could kill the inner supervisor while its separately grouped
verifier survives. Leaf .5.1 owns a bounded independent reproduction with a
self-expiring child, exact PID/group recording, verified explicit cleanup,
and no later passing result substituted for a failed containment claim.
The provisional sequence above is not accepted for implementation until this
boundary is resolved. No source implementation has changed in this selection.

The reproduction returned `status=timed_out`, outer signal 15,
`leader_reaped=1`, `group_gone=1`, and `surviving_descendants=0`.
An independent `kill(0, PID)` and `kill(0, -PGID)` both found the inner child
still alive. This is not an incorrect outer-group measurement: it falsifies
composing that group-scoped guarantee into whole nested-subtree cleanup.
The inner PID equalled its separately created group id, 32441, in this dated
capture. Exact-group TERM succeeded, followed by an absent-PID observation;
the child also had an independent eight-second self-expiry safeguard.

The bounded reproduction uses the current test wrapper at both levels. The
outer stage has a one-second wall; it launches the running Perl interpreter
with an inner `supervise_process` call. The inner stage has a ten-second wall
and launches a Perl child that records its PID and `getpgrp()` into the owned
local workspace, then sleeps for eight seconds. After the outer result, the
independent driver checks both recorded identities, terminates only that exact
group, and checks disappearance. `nested-group-probe.json` and the driver log
under the owned policy log root retain the closed results. The defect follows
from `_supervise` unconditionally calling `setpgid(0, 0)` for each child while
`_terminate_owned_process` signals only its own leader/group.

Child `.5.5` owns the repair; `.5.5.1` must select the compositional ownership
contract before `.5.2` extraction or `.5.3` fixture containment can proceed.
This is the batch's real scope blocker, not permission to weaken process
cleanup, skip the checker, change memory thresholds, or retry a failure away.
No portable-engine amendment to decision 0101 has been made.

Re-derivation is the nested launch through the current shared implementation.
Falsification is the independent PID/group liveness check after the returned
outer cleanup record, followed by exact cleanup and absence verification.
Durability is this task, the routed Knowledge Map answer, Git, and the owned
future hostile regression under `.5.5.2`/`.5.5.3`; the automated regression leg
is explicitly missing until that implementation lands. Full CI remains blocked.

## Acceptance Checklist (.19.2.3.1.2.2.5.1 blocked policy checkpoint; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'setpgid(0, 0)'`
  traces the shared mechanism to `b253263c847a2ac641f9cae14603d28d1a755122`.
  The bounded nested probe returns outer `timed_out` with `group_gone=1`,
  while independent PID and group probes both report the inner child alive.
  `_supervise` creates each child group; `_terminate_owned_process` signals
  only its own group. Core `system`/`waitpid` and T1554 `open3` history are
  identified above. The group-composition failure is reproduced; no OS loader
  cause is claimed.
- [x] **ADDRESSED (verified checkpoint, repair pending)** — The exact escaped
  group received TERM and its absence was verified. The finite diagnostic
  workspace and inspected book render are removed. The book now states the
  observed nested-cleanup limitation. Children `.5.5.1`/`.5.5.2`/`.5.5.3` own
  policy, implementation and qualification; provisional neutral extraction
  is blocked and existing decisions remain unchanged. This checkpoint
  preserves diagnosis and repair ownership, not a completed defect fix.
- [x] **NO REGRESSION (documentation checkpoint)** — `knowledge-map: OK`
  proves current bounded indexes and query parity. The independently contained
  original T1554 exits zero; a separate TAP census finds every top-level
  assertion and its complete terminal plan. The corrected local mdBook build
  exits zero and the rendered limitation is inspected in the supervision
  section. The final staged driver reports `[doctrine] all doctrine checks passed`,
  including fresh acceptance for the changed registry metadata, containment,
  locality, task integrity and claim dispositions. The initial gate caught and
  rejected a pending status on a new container; it was corrected to active.
  No completed source repair or full-CI success is claimed by this checkpoint.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.4 child group admission; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'unless (eval { setpgid(0, 0); 1 })'`
  identifies the original process engine at `b253263c847a2ac641f9cae14603d28d1a755122`.
  The real POSIX invalid-PID oracle returns `undef`/`ESRCH`, without throwing.
  The old child branch ends its eval with literal true. T1669's new controls
  consequently observe command execution for nonthrowing failure and false
  success, while the exception control rejects. The initial RAM-guard attempt
  refused unavailable sandbox process inspection; the authorized guarded run
  supplies the RED evidence in `red.log` under the task log root.
- [x] **ADDRESSED (verified)** — The child now checks the returned zero and
  actual PGID before descriptor/exec handoff. The unchanged hostile controls
  pass with `exec_error`, no command output, reaped leader, absent child group
  and unchanged caller group. The parent retains its race-closing attempt;
  caller seals, result schemas, budgets and retry policy do not change.
  The fact card and rendered book describe this guarantee separately from
  the still-open nested-group limitation. The task index returns to `.5.5.1`.
- [x] **NO REGRESSION** — Guarded T1669, T1668 and T1545 report `ok` in
  `green.log`; its later invalid T313 filename makes that invocation incomplete,
  not a complete-band pass. Corrected T313 reports `All tests successful` in
  `hdl-validation.log`. The book build succeeds and its rendered paragraph is
  inspected. Import re-derivation matches the existing architecture baseline.
  The staged driver reports `[doctrine] all doctrine checks passed`, including
  fresh acceptance, Knowledge Map, containment, locality, task integrity and
  claim joins. The inspected book render is removed with exact file hashes
  and absent-root evidence retained in `book-cleanup.json` under the log root.

The startup review followed the director's recorded task-directed scope in
`SESSION-READING-SCOPE`: mandatory entrypoints, complete roadmap, task workflow,
active repair nodes and evidence, CLI source and import architecture, shared
engine and relevant tests, book contents and the relevant product/supervision
sections. This is not an exhaustive source/test/book review. The requested
read-only sibling claim-template digest still matches the already-owned
`CLAIM-VERIFICATION-TEMPLATE-REVIEW` discovery; no new template delta is inferred.
The local containment adoption guide includes the current stable-success
contract revision. README policy is already adopted. No new policy adoption,
architecture-note refresh, complete-CI pass or nested cleanup repair is claimed.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.5 finite post-KILL reap; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'my $waited = waitpid($pid, 0);'`
  traces the blocking wait to the original shared-engine ancestor
  `b253263c847a2ac641f9cae14603d28d1a755122`. That wait precedes creation of the
  KILL-grace deadline in `_terminate_owned_process`. The isolated mock oracle
  goes RED with `blocking wait bypasses cleanup deadline`; its clock advances
  while its leader/group remain present. Signal and wait syscalls are mocked
  inside a separate bounded process, so the oracle signals no real PID and
  creates no unkillable child. The earlier process-admission fix stays green.
- [x] **ADDRESSED (verified)** — The existing KILL grace now covers both
  nonblocking leader polling and group disappearance. The unchanged oracle
  returns normally with incomplete leader/group evidence and observes TERM
  then KILL. First-failure status and fixed grace values remain unchanged;
  there is no retry or new process-runner entrypoint. Book and fact-card prose
  distinguish bounded cleanup attempts from proved disappearance.
- [x] **NO REGRESSION** — The guarded T1669/T1668/T1545/T313 band reports
  `All tests successful` in `green.log` under
  `.artifacts/logs/process-reap-deadline-20260907/`. It includes real
  TERM-resistant descendant cleanup, success, signal/exit/exec/overflow and
  sealed-adapter controls, alongside the new deliberately unresolved mock.
  The book builds and the rendered cleanup paragraph is inspected; exact
  cleanup hashes and absent-root evidence are in `book-cleanup.json`. The
  staged driver reports `[doctrine] all doctrine checks passed`, including
  fresh task acceptance, Knowledge Map, containment, locality and claim joins.

## Nested ownership selection (.19.2.3.1.2.2.5.5.1)

This task-local selection remains subject to the exact protocol leaf and
implementation qualification under decisions `0087` and `0101`. The initial
standalone decision candidate was rejected by existing rationale rollover
debt. Its complete substantive selection is retained here before the duplicate
is removed; no new numbered decision, ceiling or debt allowance is adopted.
The existing fact card routes the selection without another representation.

### Context


The retained nested probe returns an outer timeout and absent outer group
while an inner child remains alive in its separately created group. Killing
the intermediate supervisor removes the only process that remembers that
inner launch. The current group-disappearance measurement is accurate; its
composition into complete nested cleanup is false.

The prerequisite admission and reaping repairs now reject failed group
creation before exec and keep post-KILL waiting within the existing grace.
They do not repair ownership across nested supervisors. The standalone neutral
verifier integration must remain blocked until that ownership is qualified.

### Alternatives

| Model | Disposition |
| --- | --- |
| All commands inherit one outer group | Outer cancellation is simple, but independent inner cancellation can kill its supervisor and siblings. Inner success cannot truthfully report its shared group gone under the existing result contract. |
| Each intermediate supervisor registers and owns its groups | Registration must precede group escape, cleanup must close admission atomically, and ownership must survive intermediate KILL. A list discovered after launch or a signal handler alone does not satisfy those conditions. |
| One surviving coordinator creates every supervised group | Selected. The process that records a launch also forks it and retains cleanup responsibility independently of the requesting client's lifetime. |
| Reject nested supervision | A valid temporary refusal boundary, but not the final integration: existing Rust tool-resolution probes already nest, and the proposed fixture/checker/verifier chain requires nesting. |

### Selected contract

1. A top-level shared-engine invocation is the coordinator for its finite run.
   Nested invocations become private clients of that coordinator. They do not
   independently fork supervised commands. Logical parentage remains explicit
   even though the coordinator is the direct operating-system parent of each
   supervised group leader. There is no persistent daemon or public runner.
2. Record each broker-created child and logical parent before releasing the
   child to group establishment and exec. Parent-provided PIDs or group IDs
   never authorize a signal. Failed admission, fork, handoff or publication
   cancels the recorded child; it cannot produce an unregistered execution.
3. Keep domain admission, argv, cwd, schemas, time/capture limits and tool
   identity in their existing sealed adapters. Preserve the compatibility
   facade and one physical process mechanism. Do not reuse VIAL's private
   lifecycle owner or duplicate the engine inside the neutral checker.
4. Use private local IPC with a run-bound inherited context, closed framing,
   explicit job identities and validated parent relationships. A missing,
   stale or malformed inherited context fails before launch; it never falls
   back to an independent nested supervisor. This is cooperative process
   infrastructure, not a security sandbox against arbitrary same-user code.
5. Bound the coordinator to eight live jobs including the root, with depth
   bounded by the same live-job limit. Requests, pending connections, control
   frames and stream queues must have fixed finite admission limits selected
   in the protocol leaf before implementation. Derive each stream's accepted
   total from its unchanged adapter capture ceiling. Stream bounded chunks;
   do not build another unbounded JSON copy of complete captured output.
6. Preserve separate streams, original exit/signal/exec truth, monotonic times
   and first-failure results for every job. Ordinary inner nonzero results may
   be handled by their caller, as existing negative fixtures require. A lost
   client cannot promote a failed job or abandon a still-running child.
7. Client death or disconnection cancels its owned unfinished subtree. Root
   timeout, overflow, cancellation or failure closes launch admission before
   draining and terminating all remaining owned jobs. Service control traffic
   during capture so a busy stream cannot starve cancellation or deadlines.
8. Reap direct leaders and verify their groups within finite cleanup deadlines.
   Retire identities after closure and never signal a released job. Preserve
   incomplete cleanup instead of returning success if any owned job remains
   unresolved. Existing `group_gone` fields keep their actual group meaning;
   do not relabel one group's absence as the complete ownership proof.
9. IPC storage and fixtures are runtime-derived on the repository volume;
   persisted paths remain root-relative. The protocol must prove relocation,
   including long checkout paths, and preserve caller cwd/environment. Close
   client descriptors on exec, bound malformed/incomplete frames and slow
   peers, remove only exact owned endpoints, and retain failure evidence.

The live-job limit is selected safety policy, not a measured capacity claim.
The protocol leaf must finish the remaining wire/resource constants before any
runtime code changes. No current adapter receives a new caller-selected knob.

### Guarantee boundary and sequencing

The coordinator must remain alive to return a cleanup result. Uncatchable loss
of that final owner cannot establish cleanup success. Arbitrary external code
that discards inherited context or deliberately creates unregistered sessions
or groups remains outside the cooperative nesting contract; do not describe
this design as operating-system isolation of hostile programs.

Implementation is deliberately decomposed: exact protocol/resource/lifecycle
contract; asynchronous extraction preserving current behavior; root launch and
IPC ownership; nested client routing; and cancellation/result/endpoint closure.
Each slice has its own acceptance and commit. The existing neutral extraction
and fixture/core policies remain provisional until hostile qualification of
the complete selected nesting boundary succeeds.

### Evidence and missing legs

- **Re-derive:** use the original nested result and independent liveness probe
  retained in the owning task; inspect `_supervise`, `_terminate_owned_process`
  and the existing Rust/HDL sealed adapters. The prerequisite source fixes have
  observed-RED controls and passing real-process regressions.
- **Falsify:** the implementation must survive intermediate timeout, TERM and
  KILL, lost clients, overflow, nonzero exit, registration/exec cancellation
  races, orphaning and malformed IPC. Check recorded process identities from
  an independent driver after returned cleanup, not from broker counters alone.
- **Durability:** this decision and the task decomposition retain the selected
  design. The automated protocol, lifecycle, portability and hostile-cleanup
  watchers are a missing leg owned by `.5.5.2` and `.5.5.3`; no implemented
  nested-containment guarantee is published by this decision.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.1 selection and decomposition; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained independent nested probe in
  `.5.1` observes a live inner group after the returned outer `group_gone`.
  `git log -S 'setpgid(0, 0)'` traces the separate-group mechanism to
  `b253263c847a2ac641f9cae14603d28d1a755122`. The current Rust adapter consults
  each stage's group cleanup before removing its workspace; sharing one group
  cannot silently preserve that meaning. Existing admission and bounded-reap
  controls pass; neither addresses loss of the intermediate group owner.
- [x] **ADDRESSED (architecture selected; runtime repair pending)** — The task-local
  selection compares the alternatives and selects coordinator-owned forks,
  recorded-before-exec ownership, finite private cooperating clients, logical
  parents, failure preservation, cancellation and explicit guarantee limits.
  The implementation container now has independently reviewable child leaves.
  Memory, the active index and the existing fact card route to the
  exact protocol frontier. Automated implementation and qualification remain
  explicitly missing under `.5.5.2` and `.5.5.3`.
- [x] **NO REGRESSION (selection only)** — The preceding focused process band
  reports `All tests successful` at clean source commit `6155096cd`; this slice
  changes no process source, test or public behavior. The final staged driver
  reports `[doctrine] all doctrine checks passed`, including task integrity,
  Knowledge Map, claim joins and fresh acceptance. The initial rollover-debt
  rejection is retained in `initial-doctrines.log`; the final resulting tree
  keeps the original ceilings and allowances and all substantive selection
  content. Logs are under `.artifacts/logs/nested-ownership-selection-20260907/`.

## Group identity refinement (.19.2.3.1.2.2.5.5.2.1.1)

The coordinator selection is refined before production extraction: recording a
numeric group ID is insufficient if its reserving process has already been
reaped and later cancellation may signal that number again. Existing
`_poll_leader` harvests the command before `_terminate_owned_process` may send
later group signals. This is a lifecycle design gap; no unrelated-process
signal or PID-reuse frequency was observed or claimed.

The current Perl rejects `POSIX::waitid`, `POSIX::WNOWAIT` and `POSIX::WEXITED`
as invalid macros. The installed Darwin SDK declares `waitid` and `WNOWAIT`.
This distinguishes a language binding gap from an absent operating-system
facility. SDK headers are a required read-only toolchain dependency outside
the repository volume; locate them at runtime with `xcrun --show-sdk-path`
and inspect `usr/include/sys/wait.h`. No project data is written there. A new
native binding is unnecessary for the independently observed alternative.

The refined candidate keeps the coordinator as the direct parent of both a
reservation child and the actual command:

1. Fork and record a reservation child before allowing it to establish a group
   whose ID is its own PID. Fork and record the command separately, and require
   its acknowledged membership in that reserved group before execution.
2. Move the reservation child back to the coordinator's existing group, and
   acknowledge that departure before releasing command execution. The command
   retains its separate group while the reservation retains the numeric PID.
   Keep both command and reservation roles explicit; they no longer share a
   single PID/PGID field. Neither identity comes from the requesting client.
3. Keep the reservation alive or unreaped through the last possible signal to
   the command group. The coordinator may harvest the command's direct wait
   status without releasing the reserved group number. Never positively signal
   a command whose status has already been harvested.
4. On ordinary completion, prove command-group absence, retire that group from
   further signaling, release the reservation, and reap it within the finite
   cleanup budget. Reservation closure is additional internal cleanup proof;
   existing command `leader_reaped` and `group_gone` fields keep their meanings.
5. Partial admission, premature reservation death, failed departure and forced
   termination require explicit protocol states. A dead reservation must stay
   unreaped until all possible group signals have been issued. If final group
   absence cannot be proved after retirement, retain incomplete cleanup and
   never signal a retired numeric identity. The current oracle does not yet
   qualify those production transitions; sibling `.2` must specify them and
   implementation/hostile leaves must test them.

This refinement adds a bounded control child per admitted job; the existing
selected live-job ceiling must account for both direct-child roles before
implementation. It does not raise any adapter wall, capture or RAM bound. The
reservation must close unrelated job/IPC descriptors, inherit no executable
client authority and remain inside the current run's finite cleanup budget.
Exact descriptor, admission, queue and timing limits remain owned by sibling
`.2`; none is caller-selectable and no coordinator is enabled by this slice.

T1669's fresh interpreter independently exercises normal completion and TERM
cancellation. It observes actual group membership, actual command wait status,
absence of the command group while its reservation remains alive, exact child
reaping and unchanged caller membership without caller-directed TERM. Leaving
the reservation inside the group is a negative control: it fails the real
absence check and cleans up its exact children before returning. Every oracle
has its own alarm plus the existing outer supervisor deadline.

The negative control initially exposed a fixture defect: `waitpid` in `END`
overwrote the intended failure exit. The direct controls
`perl -e 'END { $? = 0 } exit 1'` and
`perl -e 'END { local $?; $? = 0 } exit 1'` return success and failure,
respectively. Localizing that status in the oracle's cleanup retains its
failure. The first failed regression log is preserved; the corrected complete
focused band is green. This is not a repaired production status bug.

Re-derivation is the live kernel handoff and direct wait observations;
falsification is the unmoved-reservation control and independent absence
checks; durability is T1669, this owning task, the existing fact card and Git.
Production coordinator integration, hostile partial-start/owner-loss races and
Linux execution remain missing legs under the following owned leaves. The
mdBook's current nested-cleanup limitation stays accurate and is unchanged.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.2.1.1 reservation oracle; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'waitpid($pid, WNOHANG)'`
  identifies `d630261e61ebd240dd4e9817c362e0ea185629d7` and the shared-engine
  move `d1235212cd7b15d4867edf9f8f08e3937fae6cc6`. The source harvests the
  command identity before later group cleanup. The selected coordinator must
  retain a separate group identity through its last signal; the independent
  kernel oracle supplies that feasibility evidence without claiming a live
  PID-reuse incident. The failed negative-control exit is separately reduced
  to Perl END status clobbering by the direct success/failure controls above.
- [x] **ADDRESSED (design feasibility verified; integration pending)** — T1669
  verifies reservation departure, retained command membership, independent
  normal/cancel wait truth, group absence before reservation release and exact
  cleanup. Its unmoved control fails at group absence; localizing END status
  preserves that failure. The task-local coordinator selection is refined and
  the wire/lifecycle frontier is split explicitly before production changes.
- [x] **NO REGRESSION** — Guarded T1669/T1668/T1545/T313 report
  `All tests successful` in `green.log`; the preceding fixture failure remains
  in `regression.log`. No production process engine, adapter contract or book
  behavior changes. Logs are under
  `.artifacts/logs/nested-group-reservation-20260907/`; `staged-doctrines.log`
  reports `[doctrine] all doctrine checks passed`, including fresh acceptance,
  task integrity, Knowledge Map and unchanged containment limits. Full CI and
  push remain blocked by the active nested and RAM-fixture frontiers.

## Private coordinator protocol (.19.2.3.1.2.2.5.5.2.1.2)

Selection boundary: this is an implementation contract for the following owned
leaves, not a shipped nested-cleanup guarantee. Decisions `0087`/`0101`, the
nested ownership selection above, and its group-reservation refinement remain
binding. The existing synchronous facade and sealed adapters retain their
arguments, schemas, command admission, walls and capture ceilings. VIAL's
separate production lifecycle does not join this private protocol.

### Transport and inherited authority

The outermost invocation runs one coordinator in the calling process until
its root job closes. Each supervised command receives one private environment
variable, `FSMGEN_PROCESS_COORDINATOR_CONTEXT`, identifying this run and its
own logical job. A nested sealed invocation connects as a client; it never
forks its requested command. The coordinator is the direct parent of every
command and every reservation child. There is no daemon, network transport,
public runner, client-supplied signal target, or reconnect-and-replay facility.

Use an AF_UNIX stream socket named `s` inside an exclusively created private
directory below `.artifacts/tmp/process-coordinator/`. Create the directory
with mode 0700 and the socket with mode 0600; reject symlinks, unexpected
entries, different device/owner, and an existing name rather than replacing
it. Run and per-job tokens are independently generated 16-byte and 32-byte
values from the operating system random source. Reading that source is an
explicit read-only OS dependency; no project data leaves the repository.
Failure to obtain a complete token is a host failure before command launch.
Never write tokens, argv, or environment values to diagnostics or task logs.

Long checkout paths must not enter `sockaddr_un`. Bind/connect using the
literal relative name `s` after entering the admitted endpoint directory,
then restore the caller's saved directory before admitting or launching work.
Save a directory handle and use handle-based restoration, including errors;
mask catchable signals during this short cwd transaction and restore their
exact mask afterward. Failure to restore is fatal, never a successful call.
No callbacks, event-loop work or fork occurs during that transaction. This
private engine supports single-threaded Unix callers; concurrent cwd mutation
and arbitrary process-context mutation are outside its contract. The endpoint
implementation must qualify actual long-path bind/connect and restoration on
the supported host before activation, not merely shorten a displayed path.

The context is one ASCII scalar with the exact form
`1:<hex-relative-directory>:<run-hex>:<parent-id>:<token-hex>`. Hex uses lower
case, two digits per byte; IDs are canonical nonzero decimal integers. The
decoded directory must be the exact owned run directory under the fixed local
root, with no empty, dot, parent, NUL, or symlink component. The context is
bounded by the context limit below. Only absence permits a new outer run;
an empty, partial, stale, malformed, foreign-root or unknown-version value
returns `invocation_error` without fallback. A cached in-process coordinator
handle is valid only in its creating PID. Forked copies cannot reuse it.

A client's HELLO must match the run, a live admitted logical parent, and that
parent's token. The token authorizes only submission under that parent; it
never supplies a PID, PGID or alternate parent. Revocation precedes any parent
cleanup. This is a cooperative same-user protocol, not authentication against
arbitrary code that can read another process's memory or environment. A program
that deliberately clears context or creates unregistered sessions/groups is
outside the guarantee. All client/coordinator descriptors are close-on-exec;
only the private context, never a connected socket, is inherited by commands.
A forked client must close inherited connections it does not own.

### Byte grammar and finite admission

Use binary length framing rather than interpreting argv/environment as JSON
text. `u32` is four bytes in network order; `u64` is eight bytes in network
order. `b` is a u32 byte length followed by exactly that many octets. Vectors
begin with a u32 item count. There is no native-endian integer, implicit text
normalization, delimiter escape, trailing field, or optional unknown field.
A frame is `u32(payload length), u8(version=1), u8(type), body`; payload length
includes version/type and must be admitted before allocating or reading its
body. A partial header/body has one fixed deadline from its first byte, never
extended by progress. Each connection carries exactly one submission.

The following are selected safety ceilings, not measured throughput or
capacity claims. They are private constants with boundary-plus-one watchers
required in `.5.5.2.3`/`.5.5.3`; callers cannot raise them.

| Resource | Inclusive bound / rule |
| --- | --- |
| Live jobs and depth | Eight jobs including root; root depth is one; retiring/result-delivery jobs still occupy slots. |
| Direct children | Two per live job, command plus reservation; at most sixteen; fork admission reserves both slots first. |
| Connections | Eight accepted sockets including unauthenticated peers; listen backlog eight; one in-flight submission per socket; no user-space waiting-job queue. |
| Private descriptors | At most 128 simultaneously owned by the coordinator, counting listener, streams, handshakes and accepted sockets; reject before exceeding it. |
| Context / path bytes | 8,192 encoded context bytes; 4,096 decoded cwd bytes; the generated endpoint relative directory is at most 256 bytes. |
| Request frame | 1,048,576 payload bytes; HELLO and all other control frames at most 8,192 bytes. |
| Execution snapshot | At most 4,096 argv elements and 4,096 environment pairs; at most 65,536 bytes per scalar; at most 524,288 total argv/environment bytes. |
| Policy metadata | Schema, stage and containment are nonempty ASCII scalars of at most 256 bytes each; timeout and capture are positive u32 values fixed by the sealed adapter. |
| Stream chunk | At most 16,384 raw bytes per stdout/stderr frame; the unchanged adapter ceiling bounds their combined total. |
| Pending stream output | 65,536 encoded bytes per job; no second complete output copy in the coordinator for nested jobs. |
| Pending control output | 16,384 encoded bytes per connection, separately reserved so cancellation/results do not depend on stream credit. |
| Framing, authentication and admission | Two seconds each, clipped to the requesting invocation's original deadline; there is no deadline renewal on another frame. |
| Socket progress / result delivery | Two seconds without successful queued-byte delivery; terminal delivery/ACK has two seconds total, within the fixed closure envelope. |
| Event-loop fairness | One accept and at most one control/read/write chunk per ready descriptor per pass; rotate job order and inspect signals/deadlines on every pass; idle wait at most 0.05 seconds. |
| Identity space | Monotonic u32 job IDs starting at one; never reuse an ID in a run; exhaustion rejects admission before wrap. |

Input frame storage is at most one partial frame per connection. Decode only
one admitted request at a time and discard its wire buffer after admission;
accepted snapshots remain bounded by the live-job count. Control and stream
queue accounting includes headers and unsent partial frames, not just payload.
Do not allocate a promised size, vector, or string before checking its bound.
Resource exhaustion returns a closed failure, never waits for a slot while
holding the caller's deadline open. Kernel backlog is not an ownership record.

The closed message set is:

| Type | Direction and exact body |
| --- | --- |
| 1 HELLO | Client to coordinator: raw 16-byte run ID, u32 parent ID, raw 32-byte parent token. |
| 2 READY | Coordinator to client: raw run ID, u32 parent ID; confirms HELLO only, not job admission. |
| 3 SPAWN | Client to coordinator: u64 invocation-start monotonic ns; b schema, b stage, b containment, b root-relative cwd; u32 timeout seconds, u32 capture ceiling, u32 umask; argv vector of b; environment vector of ordered b key/b value pairs. |
| 4 ACCEPT | Coordinator to client: u32 allocated job ID; published after the ownership record exists and before exec release. |
| 5 STDOUT / 6 STDERR | Coordinator to client: u32 job ID, u64 byte offset within that stream, b raw chunk. |
| 7 CANCEL | Client to coordinator: u32 accepted job ID; cancellation is irreversible and restricted to this connection's job/subtree. |
| 8 RESULT | Coordinator to client: u32 job ID, b canonical ASCII JSON terminal metadata described below; no embedded streams. |
| 9 ACK | Client to coordinator: u32 job ID; acknowledges validated complete result delivery. |
| 10 REJECT | Coordinator to client before ACCEPT: u8 class (1 invocation, 2 host), b diagnostic capped at 2,048 bytes. |
| 11 STDOUT_END / 12 STDERR_END | Coordinator to client: u32 job ID, u64 final captured byte count. |

Wrong direction, version, order, identity, offset, duplicate message or unknown
field/type fails the connection. CANCEL is idempotent after its first valid
occurrence, but can never reopen a terminal job. A failure before ACCEPT has
no client-visible job ID; any partially created children still belong to the
coordinator and must close. Loss of ACCEPT is cancellation, not authority for
retransmission. Every accepted connection is polled for EOF even when its
stream output is backpressured.

### Execution snapshot and compatibility

The sealed adapter validates argv/cwd and fixes schema/stage/containment/bounds
before entering the engine. Snapshot its current environment for each call,
not the coordinator's original environment: Rust's PATH, CARGO_HOME,
CARGO_TARGET_DIR, RUSTC and temporary-root changes must reach the actual child.
Send the complete environment in strictly increasing byte-key order, with no
duplicate, empty, NUL-containing or equals-containing key and no NUL in a
value. Absence and an empty value differ. Do not merge with coordinator state.
Replace only the private context with the new job's authority. Preserve caller
%ENV and cwd after every return; no snapshot value is persisted on disk.

For each Perl scalar, stringify once into a private copy. Preserve an unflagged
byte string exactly; encode a UTF8-flagged string once with Perl's UTF-8 byte
encoding before framing. Reject NUL after conversion and reject values whose
encoded size exceeds admission. Decode transport to unflagged byte strings
before exec. Qualify this rule against an independent direct-exec oracle for
empty arguments, spaces/newlines, quotes, high bytes, flagged Unicode and empty
versus absent environment values. A codec round trip alone cannot prove exec
compatibility. Schema/stage/containment remain bounded ASCII metadata.

Snapshot umask without changing the caller's effective mask and restore it in
the forked command. STDIN remains EOF; stdout/stderr remain separate captured
pipes. The root invocation establishes the inherited signal dispositions,
signal mask, credentials, resource limits and open-file policy; arbitrary
nested changes to those process attributes are not a supported caller knob.
Do not claim emulation of an unrestricted remote fork. Admission requires the
default SIGCHLD disposition and no competing child reaper; otherwise refuse
before creating a run. The coordinator ignores SIGPIPE only within its private
I/O scope and treats EPIPE as connection loss; commands restore the original
disposition. Existing sealed adapters
change environment and command policy, not those attributes; qualify their
current callsites before enabling routing. The child restores the root's
exec-relevant signal state rather than inheriting coordinator-only handlers.
All run-private and other-job handles must close in both child roles; the
reservation receives no command environment or executable client authority.

A nested invocation records its monotonic start before connecting. Admission,
framing, group establishment and exec consume the adapter's existing wall;
SPAWN timestamps must lie between HELLO receipt minus two seconds and HELLO
receipt, inclusive, and cannot exceed the current coordinator monotonic time.
They cannot extend the parent's remaining lifetime. Root start includes endpoint
setup. Each job's execution deadline is the earlier of its own wall and all
ancestor execution deadlines; a shorter outer deadline remains authoritative.

### Lifecycle, identity and cancellation

The run state moves only `OPEN -> CLOSING -> CLOSED` or `INCOMPLETE`. Job states
move through the following transitions; a failure at any preterminal state
latches its first cause and enters cancellation. Terminal identities never
return to admission.

| State / transition | Required ownership fact and independent oracle obligation |
| --- | --- |
| VALIDATED -> RESERVED | Record job/parent/connection and reserve bounded child/descriptor slots before any fork. Cancel between record insertion and the first fork; no unrecorded child may execute. |
| RESERVED -> GROUP_READY | Fork and immediately record the reservation PID while signals are masked. Only the reservation establishes its own PGID and acknowledges actual membership. Inject fork and each handoff failure; positive-PID cleanup must leave the caller group untouched. |
| GROUP_READY -> COMMAND_READY | Fork and record the command before releasing its join gate. Require actual command membership in the reserved group. Fail before/after join and prove the two direct-child identities independently. |
| COMMAND_READY -> RESERVATION_MOVED | Instruct the reservation to return to the coordinator's group; require its actual departure acknowledgment. Before that acknowledgment never classify group absence as command cleanup; the reservation itself may still be a member. |
| RESERVATION_MOVED -> RUNNING | Publish ACCEPT completely, then release the command's exec gate. Verify cancellation/disconnect after partial ACCEPT and before/after release; no client publication can erase coordinator ownership. |
| RUNNING -> DRAINING | Harvest only the exact command wait status with nonblocking waitpid. Close parent admission immediately on command exit and cancel its unfinished logical descendants. An exited command with remaining descendants is failed, even if its own group is absent. |
| Any active state -> CANCELLING | Revoke affected tokens and close admission first, then TERM all affected owned groups/unjoined direct children without serial per-job grace. Sweep new handoffs before any release. First timeout/overflow/host/exec/signal/nonzero cause remains latched. |
| CANCELLING -> KILLING | After the existing two-second TERM grace, send KILL only to still-owned targets. Poll every affected job under one two-second KILL grace; job count cannot multiply that wall. |
| DRAINING/KILLING -> GROUP_RETIRED | Require command reaping, closed capture, all logical descendants terminal, and actual absence of the reserved command group. Retire the PGID from all future signal paths before releasing its reservation. Unknown wait status or uncertain absence cannot produce success. |
| GROUP_RETIRED -> RESULT_PENDING | Release/terminate and nonblockingly reap the exact reservation within the remaining fixed closure envelope; close all job handles. Serialize terminal metadata only after internal subtree and reservation closure checks. |
| RESULT_PENDING -> RETIRED | Deliver stream endings then RESULT, validate ACK, close the connection and discard its state. Lost/late ACK cannot reopen or rerun the command; failure is retained and the slot closes under the delivery wall. |
| Any cleanup deadline -> INCOMPLETE | Retain false cleanup facts and a failed status; issue no further signal after numeric identity retirement. Release remaining handles/endpoints only under the exact safety rules below. |

The reservation is never reaped before the last possible group signal. EOF on
its control pipe before normal release is a host failure; retain the dead
child as unreaped identity while cancelling the command. Never use a general
`waitpid(-1, ...)` or a SIGCHLD reaper. ECHILD is unknown ownership/status and
fails closed. Never positively signal a harvested command PID. If the
reservation unexpectedly shares the caller group, address it by its owned
positive PID only. Before group establishment is acknowledged, cleanup may
signal known direct children but never infer permission to signal a group.
During cancellation before reservation departure, first stop the gated command
and request the live reservation's departure; do not kill the reservation in
its own group merely to accelerate normal cleanup. If it dies before departure,
its unreaped group membership can prevent an absence proof. Finish the last
owned signals, retire group signalling, reap exact children and retain
INCOMPLETE rather than claiming a pre-release absence that was never observed.

Root failure or a caught INT/TERM/HUP closes the whole run before signalling.
For a nested job, an ordinary completed nonzero result may be handled by its
caller; it cancels that job's descendants, not unrelated siblings. Client EOF,
protocol failure or delivery failure cancels its connection-owned subtree.
Logical parent exit cancels all its unfinished children even if a leaked socket
would otherwise conceal client death. One job cannot cancel an ancestor or
sibling. Cancellation and EOF remain serviced during saturated output.

The closure envelope after an execution stops is at most the existing TERM
and KILL graces plus the selected terminal-delivery interval. Reservation
release/reaping shares that envelope; it does not start another unbounded wait
or another grace for each job. On ordinary completion, lingering command-group
members remain `surviving_descendants`; cleanup does not promote the result.
Signals caught by the coordinator are deferred only for finite cleanup; then
restore and invoke the prior disposition, including re-raising a default
terminating signal. Originally ignored signals stay ignored. Do not turn a
user interrupt into success or permanently replace the caller's handlers.

### Streams, closed results and endpoint retirement

The coordinator counts each raw output byte once against the job's unchanged
aggregate capture limit. Retain the admitted prefix on overflow. Nested jobs
stream bounded chunks to their client, which builds the single complete
stdout/stderr pair required by the existing result facade. Stop reading a
backpressured stream when its queue fills; continue control/EOF/deadline work.
A stalled receiver fails under the socket-progress wall. The root job retains
its own bounded capture directly. No spooling, retry or unbounded transcript
is introduced. Per-stream offsets/end counts must equal received raw bytes.

RESULT metadata is one canonical ASCII JSON object with exactly `result`,
`reservation_reaped`, `subtree_closed` and `delivery_complete` keys. `result`
is the existing `_finish_result` scalar/cleanup record with only `stdout` and
`stderr` omitted; the other keys are integer booleans 0 or 1. Before ACK the
last is false; the client requires the first two, validates all existing closed
keys/types/counts/timestamps and reconstructs streams locally. ACK establishes
delivery completion in coordinator state, not in a forged command result.
Preserve command exit/signal truth independently of infrastructure failure.
`leader_reaped` and `group_gone` continue to describe the command and its actual
group; they do not become aliases for subtree closure. Internal closure failure
forces `ok=0` and `host_error` or `cleanup_failed` while retaining any earlier
failed status. Public result keys and schema versions do not change silently.

Only ESRCH proves group absence; EPERM and unexpected probe errors preserve
uncertainty. The reservation holds the numeric group identity until its last
signal, even after command reaping. If a final group check remains uncertain,
retire signalling before releasing the reservation and return INCOMPLETE; do
not carry a numeric target into a future run. Unreaped children are reported
as incomplete, never invented as reaped to permit success or workspace removal.

On run closure, stop accepting first, cancel/drain owned jobs, close accepted
sockets and listener, then unlink only the recorded socket with its unchanged
file identity and remove only its empty owned directory. Unexpected files or
identity replacement preserve evidence and fail cleanup; do not recursively
remove a caller-supplied directory. A result with failed internal closure must
not permit adapter workspace deletion. Root-owner KILL or kernel-uninterruptible
loss cannot certify cleanup; document this final-owner limit without promising
an external guardian. Ordinary startup cleanup does not delete another run's
endpoint merely because its PID appears absent.

### Required qualification and startup checks

Every transition row above needs a deterministic failure injection plus a
real-process counterexample under `.5.5.2.3` through `.5.5.3`. The independent
observer must retain actual command/reservation identities and verify liveness,
wait status, caller-group isolation and owned endpoint residue after return.
Use model-only signal probes for PID reuse/retirement and unreapable children;
do not signal unrelated processes or create an unkillable host fixture.
Require deliberately RED controls for lost publication, unclosed descendants,
released group identity, stream truncation, malformed framing, forged parent,
slow peers, context loss and cwd/environment drift. Run current T1669, T1668,
T1545 and T313, plus the Rust nested-tool controls, before routing is enabled.
Linux execution remains a separate missing qualification leg until observed.

Re-derive this selection from the shared engine, sealed adapters and retained
escaped-group/reservation evidence. Falsify it with the independently observed
process and direct-exec oracles above. Durability is this task, the existing
fact-card route and Git; automated protocol/queue/lifecycle watchers are still
missing and owned by the following implementation/qualification leaves. This
selection alone does not unblock neutral-verifier acceptance or full CI.

Startup review on 2026-09-07 followed the settled `SESSION-READING-SCOPE`
decision: required doctrines, roadmap, live owner, relevant source/tests and
book, plus CLI routing and its import architecture. The selected PGEN template
was read-only on the repository volume; its digest still matches the changed
input recorded in `CLAIM-VERIFICATION-TEMPLATE-REVIEW`. Local claim authority
is unchanged. The containment adoption guide includes its latest stable-count
integration rule; no new portable policy revision was found in that local
source. The README remains the governed landing page. No project artifact is
deleted while it owns pending failure or verification evidence.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.2.1.2 protocol selection)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'setpgid(0, 0)'`
  identifies the separately owned group mechanism already isolated by the
  escaped-inner-group counterexample. The shared engine and Rust adapter show
  why surviving ownership must retain per-call environment and exact command
  wait truth. The preceding reservation oracle addresses numeric identity;
  it does not supply transport, queue or lifecycle policy.
- [x] **ADDRESSED (contract selected; implementation pending)** — The exact
  task-local grammar, finite resource table, authority/context boundary,
  transition obligations and result/identity retirement rules now constrain
  the existing implementation leaves. The parent protocol node is complete
  and the shared-engine extraction is next. No production source, test, public
  result schema or shipped book behavior changes in this slice.
- [x] **NO REGRESSION (design only)** — The guarded initial doctrine driver
  reports `[doctrine] all doctrine checks passed`; task integrity also passed
  independently. The staged driver and hook must pass before this slice can
  commit. Diff hygiene is clean, the mdBook's nested-cleanup limitation is
  unchanged, and the existing fact card points to this selected contract.
  Evidence: `.artifacts/logs/nested-coordinator-protocol-20260907/`.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.2.2 asynchronous extraction; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'sub _supervise'` locates
  the shared-owner extraction. `_supervise` formerly combined launch, stream
  waiting, polling, termination graces and result construction in one call;
  that prevents a coordinator from servicing other jobs during cleanup.
  Existing admission, reservation and unreapable-child evidence remains
  authoritative; this slice changes scheduling structure, not group ownership.
- [x] **ADDRESSED (verified)** — One shared implementation now exposes private
  start/advance/complete states, with waiting confined to its compatibility
  drivers. T1669's independent oracle rejects sleep or blocking select within
  advancement, observes deliberately broken drivers fail at each trap, and
  proves binary output, separate streams, timeout/escalation and actual child/
  group absence. No IPC, new public runner or nested-cleanup claim is enabled.
- [x] **NO REGRESSION** — `perl -Iperl -c` reports `syntax OK` for the shared
  engine and updated watcher. Both the original and updated guarded
  T1669/T1668/T1545/T313 bands report `All tests successful`; the updated band
  adds the nonblocking oracle. Sealed adapters and public result keys are
  unchanged. The mdBook's current own-group limitation and import architecture
  remain accurate; no behavior-document edit is needed. The staged doctrine
  gate and commit hook must pass before commit. Evidence is retained under
  `.artifacts/logs/process-async-extraction-20260907/`.

## Coordinator safe-slice decomposition (.19.2.3.1.2.2.5.5.2.3)

The post-extraction source exposes a material implementation boundary:
`_start_supervision` still releases its single command directly to exec. The
selected coordinator cannot safely be added merely by calling that function
from a socket loop. It must publish owned records before releasing exec,
retain a separate reservation child, transport each client's execution context
without changing bytes, and preserve caller cwd while binding a local endpoint
under long checkout paths. The preceding synchronous and nonblocking-step
regressions do not qualify any of those new failure domains.

Apply the director's batch stop condition for a task expanding beyond a safe
slice. The live coordinator node is now a container with the exact sequence:
wire/snapshot and independent exec oracle; endpoint/connection lifecycle;
reserved-group launch gates; root admission/service integration. Every child
has explicit acceptance and predecessor evidence before source changes. This
is an early batch stop after the verified protocol and extraction commits,
not completion of the requested default batch or the coordinator repair.
A fresh session resumes directly at `.5.5.2.3.1`; no implementation from that
child is in flight. Existing neutral-verifier, RAM-fixture and full-CI blockers
remain open, and no push is attempted.

Validation for this documentation-only decomposition is the staged task-tree
and doctrine gate plus diff hygiene. The preceding source commit's guarded
T1669/T1668/T1545/T313 band remains its behavioral evidence; this decomposition
changes no process code, book behavior, policy constant, or public result.
Retain the gate and commit output under
`.artifacts/logs/coordinator-safe-slices-20260907/`.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.2.3.1.1 wire implementation; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'sub _start_supervision'`
  identifies asynchronous extraction `51a3a3914`, which has no transport or
  execution snapshot. The selected protocol requires byte-preserving private
  messages before coordinator activation. A separate `git log -S` identifies
  T1545's discarded supervisor diagnostics in `d630261e6`; unchanged source
  paths and the failed final band are retained for child `.1.2`.
- [x] **ADDRESSED (verified)** — The private `ProcessSupervisor::Wire` module
  implements the selected bounded message/context grammar and snapshot without
  sockets, process creation or production imports. Independent literal frames,
  raw hostile frames, boundary-plus-one inputs, actual producer RESULT data,
  and direct exec establish the codec boundary. The direct-exec oracle catches
  deliberate double encoding and distinguishes Perl argv conversion from live
  ENV magic. Syntax and final guarded T1669 pass after the endpoint test's
  independently detected off-by-one was corrected.
- [x] **NO REGRESSION (focused implementation; broader qualification pending)** —
  Final guarded T1669 reports `All tests successful`; T1668 and T313 are also
  `ok` in the final band. T1545 fails its first fixture with empty output, so
  that band is explicitly **failed**, not a qualification pass. Parent `.1`
  stays active and child `.1.2` owns diagnostic repair and qualification before
  endpoints. Book own-group limitations and the CLI import map remain current;
  production callers and result schemas are unchanged. The synchronized staged
  driver reports `[doctrine] all doctrine checks passed`, including fresh task
  acceptance. The hook repeats that gate before the checkpoint commits.

Evidence lives under `.artifacts/logs/coordinator-wire-20260907/`. Re-derivation
is the final focused command and exact frame inputs; falsification is direct
exec plus deliberately corrupted data; durability is the tracked codec,
T1669, task and Knowledge Map route. Nested runtime/Linux qualification and
the failed broader band remain explicit missing legs. No performance or
capacity conclusion is drawn from transient TAP timings or configured bounds.
The initial containment rejection is resolved by proving the added fact-card
paragraph duplicates this task's richer evidence and keeping only its concise
retrieval pointer. No recorded fact or containment ceiling changes. A sandbox
index-write rejection left no lock; authorized sequential staging resolved the
resulting-tree mismatch before the passing gate.

This slice applies the batch stop condition for newly discovered work beyond
a safe slice: T1545 diagnostic repair is distinct from the private codec.
Commit the qualified implementation checkpoint before that repair begins.
The default batch is not complete; no push is authorized by this checkpoint.

## Acceptance Checklist (HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.1 diagnostics; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` identifies
  `run_checker`'s two-value projection at `d630261e6`. The retained original
  `final-regression.log` contains empty checker output without supervisor
  metadata. The new real failed-checker controls go RED against that helper
  in `red.log`; this proves diagnostic loss, not the historical runtime cause.
- [x] **ADDRESSED (verified)** — The same controls go GREEN in
  `instrumented.log`: empty and split streams remain unchanged for checker
  assertions, while canonical JSON diagnostics reconstruct the complete
  structured result, actual shell exit, signal, timing and cleanup facts.
  No resource bound, command admission, retry, or production runtime changes.
- [x] **NO REGRESSION** — Guarded T1669/T1668/T1545/T313 report
  `All tests successful` in `regression.log`. The instrumented launch does not
  reproduce the earlier failure; its original failed status is retained.
  The mdBook builds and its rendered diagnostic paragraph is inspected; the
  existing Knowledge Map card routes to the repaired test. The claim census
  and complete disposition join pass. The guarded staged driver reports
  `[doctrine] all doctrine checks passed`; hooks recheck final staged evidence.

The distinct claim legs are re-derivation through the instrumented checker,
falsification through real failed-shell controls against the unchanged helper,
and durability through the tracked regression, this task, book and fact card.
The historical invocation lacks enough runtime evidence to identify its cause;
child `.1.2.2` retains that missing leg and blocks parent qualification.
Startup used the director-selected task-directed scope in `SESSION-READING-SCOPE`:
mandatory documents, roadmap, full CLI, import architecture, active process
sources/tests, and relevant mdBook sections. The same-volume caller-selected
claim template was read-only and its digest agrees with the already owned
`CLAIM-VERIFICATION-TEMPLATE-REVIEW` record. README and containment adoption
remain in force; their canonical policies and adoption guide were reviewed.

## Acceptance Checklist (HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.1; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` traces completion-time
  handoff inference to `b253263c8`. The real pre-exec timeout oracle in T1669
  fails on the unchanged engine in `red-supervised.log`: the reported handoff
  equals completion even though the command never ran. The separate pre-exec
  exit falsifies EOF as proof of main entry.
- [x] **ADDRESSED (verified)** — `_complete_supervision` no longer supplies
  missing capture evidence. The same held-child oracle is GREEN; successful
  commands retain observed timing and both failure controls prove cleanup.
  Re-derivation uses the tracked T1669 command, falsification fixes the child's
  position independently, and durability is T1669 plus task/book/fact/Git.
- [x] **NO REGRESSION** — The corrected RAM-guarded T1669/T1668/T1545/T313
  band reports `All tests successful`; syntax checks and mdBook build pass.
  The rendered paragraph is checked and the exact disposable build is removed.
  Evidence: `.artifacts/logs/handoff-evidence-20260907/`. The initial missing
  process-inspection run and mistyped-test invocation remain failed/incomplete.
  The staged driver reports `[doctrine] all doctrine checks passed`, including
  fresh task acceptance; commit hooks recheck the final evidence snapshot.

## Selected T1545 observation boundary (HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.2)

Keep observation private to T1545's `run_checker`: scoped read-only wrappers
around the existing start/advance functions retain the actual forked child PID
and parent PID, launch cardinality, and fixed progress flags for observed
control EOF, first output, native checker diagnostic, cleanup, and completion.
The native diagnostic classifier comes from the checker's emitting `printf`
calls: a line beginning `[task-acceptance] OK:` or `[task-acceptance] FAIL:`.
No flag infers pre-main state from absent output or proves exec from EOF.

Publish the bounded observation as a separate canonical JSON TAP diagnostic
on every checker invocation. Keep the complete supervisor result unchanged and
keep both metadata records out of checker-output assertions. Observation adds
no command, callback API, process, file, stream capture, policy override, retry,
fixture-source edit, environment change, or blocking OS sampler. It cannot
recover a past PID/stack sample or promise a future native stack capture.

Qualify PID identity independently with Bash's own `$$`, original checker
progress with its unmodified output producer, and pre-exec timeout with a child
held after actual group admission. The latter must retain unknown output/main
progress and prove cleanup. Preserve the historical failed invocation and use
any captured recurrence for a separately owned repair; a fresh pass alone does
not unblock wire qualification.

## Newly exposed fixture launch failure during checker observation

The broader observation qualification is failed: T1669's unchanged Rust
proxy controls return timeout instead of their scripted outcomes; T1668's
unchanged direct Perl fixture launches also fail. Preserve the active RAM
guard and fixed deadlines. Capture a bounded OS sample only from an identified
live descendant of this invocation, then verify cleanup. Child `.1.2.2.3` owns
root-cause selection and repair after the checker observation checkpoint;
no retry-based recovery or endpoint activation is authorized by the passing
T1545 subtest. This is a separate defect, not evidence for the missing historic
T1545 runtime cause.

## Acceptance Checklist (HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.2; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` traces `run_checker`'s
  direct result projection to `d630261e6`; neither the original helper nor
  the closed result retains child identity. The independent PID and native
  diagnostic controls fail in `red.log` before observation is implemented.
  This diagnoses missing prospective evidence, not the historical timeout.
- [x] **ADDRESSED (verified)** — The same T1545 controls pass in
  `regression.log`: Bash's own PID agrees with the observed fork; unrelated
  output cannot establish native checker progress; an independently held
  pre-exec child reaches the unchanged deadline with unknown output/main
  progress, one launch, and completed cleanup. The separate canonical JSON
  record round-trips exactly without entering checker-output assertions.
- [x] **NO REGRESSION (focused observation; broader band failed)** — T1545
  and T313 report `ok` in the guarded run (`Files=4, Tests=36`, `Result: FAIL`);
  the changed test is syntax clean. T1669 and T1668 fail on unchanged
  fixture-launch paths. The retained
  independent OS sample places an actual T1668 child at `_dyld_start`; source
  identities match HEAD and child `.3` owns repair before qualification.
  No passing-band or full-CI claim is made. The mdBook builds and its rendered
  paragraphs are inspected; exact output is removed after identity capture.
  The corrected staged driver reports `[doctrine] all doctrine checks passed`;
  commit hooks recheck the final evidence snapshot.

Evidence is retained under `.artifacts/logs/checker-launch-observation-20260907/`.
Re-derivation is the guarded tracked test and source/history comparison;
falsification uses independent Bash PID, the held-child oracle and native
output producer; durability is the test, this task, book, fact card and commit.
The fresh broader failure has a native sample but lacks an OS root cause;
the historical T1545 failure still lacks its discarded result and identity.
Both missing legs remain explicit. The sampled PID and recorded observation
PIDs are absent after the terminal run. The read-only host process inspector
and OS sampling tool are required diagnostic dependencies; their outputs stay
on the repository volume. The first reference-authority calculation stopped
at its metadata header before writing; the corrected keyed traversal records
the exact book delta without altering a containment ceiling.

Commit this verified observation checkpoint before modifying either failing
watcher or adapter. Child `.3` is the single next action; the broader band,
wire qualification, nested containment and push remain blocked.

The first staged gate rejects the fresh NO REGRESSION box because its prose
omits the declared prove-summary signature. The corrected box quotes the actual
failed-band summary and retains its explicit failures; no registry, assertion,
or gate behavior changes.

## RAM-guard fixture policy (.19.2.3.1.2.2.6.1)

This selection repairs T1595's fixture harness. It does not change the guard's
production formulas, defaults, safety thresholds or process-tree algorithm,
and it does not establish a cure for the separate Darwin startup failures.
The retained original interrupted T1595 run remains interrupted.

- Add private `FSM::Test::RamGuardFixtureRuntime` behind the existing test
  supervisor wrapper. Resolve the inherited selected Bash and running Perl
  once from absolute executable paths before fixture PATH changes. Use direct
  Bash for the guard and canonical Bash shebangs for its fake inspection tools.
  Installed interpreters and native inspection tools are read-only dependencies.
- Admit only a direct `fsmgen-*` workspace under
  `.artifacts/tmp/ram-guard-tests/`, on the repository volume with no symlink
  ancestry. Admit readable regular sample files directly in that workspace,
  with safe basenames and a fixed 65,536-byte input ceiling before reading.
  Fake tools are the fixed uname/sysctl/vm_stat roles inside its fake-bin;
  their preparation uses fixed bodies and the selected Bash identity.
- Expose only fixture preparation and a closed run operation taking workspace,
  sample and scenario. Scenarios are the existing healthy completion, pressured
  child and child-marker controls; the adapter owns their exact Perl argv.
  No caller argv, executable, cwd, wall, capture, threshold or environment
  override is accepted. Marker paths are derived inside the admitted workspace.
- Launch the exact repository guard through selected Bash. Retain T1595's
  explicit 88-percent / 4096-MiB options, 0.02-second poll and zero grace; these
  are existing inner test controls. The real outer RAM guard remains at its
  configured defaults and uses the real host readings. No safety policy widens.
- Seal each fixture invocation to ten seconds and 1,048,576 aggregate output
  bytes. The adapter locally restores the environment, prepends only its
  admitted fake-bin to the captured absolute tool PATH, fixes the existing
  4,096,000-byte synthetic host capacity and admitted sample path, and clears
  inherited Bash startup injections. All temporary/cache data remains local.
- Return the shared closed result with schema
  `fsmgen.test.ram_guard_fixture_result.v1`, stage `ram_guard_fixture` and
  `ram_guard_fixture_process_group` containment. Retain separate exit/signal,
  output, timeout, overflow, exec and cleanup fields; never collapse signal or
  timeout into an exit-only success. Preserve nonzero results as nonzero even
  when a metric test expects the guard's documented trip or rejection.
- Extend the existing exclusive-owner oracle to admit only this additional
  policy adapter and forbid direct IPC in T1595. Independently demonstrate
  that a signalled child defeats the old shifted-exit projection and that
  stderr-before-stdout pressure defeats its sequential reader under a finite
  outer observer. Preserve RED evidence and exact owned-process cleanup.
  Use engine/adapter controls for timeout, capture, signal and cleanup truth;
  prove hostile caller/path/PATH attempts reject or retain the selected policy.
  Keep all original healthy/pressured/malformed-sample metric assertions.

The guard does not establish a new process group. Its admitted fixture command
stays in the adapter's group, unlike the independently grouped nested supervisor
counterexample. This is a group-cleanup boundary, not a general descendant or
root-owner-loss guarantee; no private coordinator route is activated.
Re-derivation is source/history plus unchanged metric fixtures; falsification
is independently bounded signal/output controls and admission mutations;
durability is this selected contract, following tracked adapter/oracles,
book/facts and work-unit Git. Runtime and negative-control execution remain
missing until child .2. Design-only selection changes no shipped behavior.

## Acceptance Checklist (.19.2.3.1.2.2.6.1 policy and history routing; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'waitpid($pid, 0)'` identifies 30885823b54a0677b4396550d9d3cfc2fc7fa3a9; T1595 reads streams sequentially, waits without a deadline and discards signal bits. Its original pre-main sample remains a separate unknown-cause failure. The current task also needs room for live policy; only its completed diagnostic suffix is routed to exact versioned history.
- [x] **ADDRESSED (policy selected; runtime pending)** — Select one sealed domain adapter over the existing shared engine, exact tool/path/command admission, fixed bounds and full result truth; own implementation and independent RED/GREEN qualification in child .2. Preserve the full predecessor and exact suffix via the existing history manifest, retaining live coordinator design and startup blockers without raising a ceiling.
- [x] **NO REGRESSION** — Focused task/history retrieval reports all active invariants hold, including exact predecessor and suffix hashes; map regeneration succeeds. The staged doctrine driver reports `[doctrine] all doctrine checks passed`, including Knowledge Map/census and the docs-only acceptance exemption; the hook rechecks final evidence. Source, tests and mdBook behavior are unchanged; no runtime repair or complete-CI qualification is claimed.

## Acceptance Checklist (.19.2.3.1.2.2.6.2 RAM-guard fixture implementation; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'waitpid($pid, 0)'` identifies 30885823b54a0677b4396550d9d3cfc2fc7fa3a9. The exact legacy helper independently reports native signal 15 as projected exit zero; its maintained stderr-first producer enters main but cannot record drained progress before the bounded hostile observer times out. The new policy addresses these fixture capture defects without claiming an OS startup cause.
- [x] **ADDRESSED (verified)** — T1595 now uses the sealed RamGuardFixtureRuntime adapter and retains its metric assertions, selected interpreter capability, fixed guard options and complete failure/cleanup truth. T1811 and T1669 qualify rejection, bounds, environment restoration, exact legacy RED controls, actual concurrent capture/signal/overflow and real guard inspection timeout/KILL cleanup. The first run's success-status mismatch and discarded-inspection-stderr assumptions remain recorded and corrected. Book/fact and exact reference aggregate are synchronized; rendered documentation is reviewed.
- [x] **NO REGRESSION** — The corrected guarded six-file band reports `All tests successful`, as does final T1811 after its contract-equality refinement. Original metric assertion bodies remain, and production guard/shared engine/wrapper are unchanged. Syntax and repo-local book build/render review pass; The first claim-data gate rejects Python-escaped Unicode in prior records and unsorted new disposition fields/order; preserve prior record bytes and canonically sort only the added disposition, then regenerate the census. The follow-up gate requires the disposition owner to match the existing verification_architecture review group; retain that group owner while naming this implementation leaf in the evidence. The final staged driver reports `[doctrine] all doctrine checks passed`, including fresh implementation acceptance and the complete claim join; the hook rechecks final evidence. Complete CI and push stay blocked by separate owned work.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.2.3.2.2 inactive endpoint filesystem)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'my $ENDPOINT_ROOT'` identifies `971bc58e5` as the private Wire implementation; it defines context grammar but no endpoint owner. T1812 initially fails loading the missing module. Its independent directory-replacement control then fails `at t/1812-process-coordinator-endpoint.t line 309`, proving the first endpoint implementation could publish a context after the named directory was replaced during bind.
- [x] **ADDRESSED (verified)** — The private Endpoint owns exact filesystem identities, random authority, sealed handles and handle-based cwd/signal restoration. Post-operation directory admission rejects the retained real bind replacement and its connect counterpart. Independent raw socket peers prove actual long-path placement and byte exchange; native filesystem/context and fork-copy controls prove refusal and exact cleanup. Model-only owner/device evidence is named, and Linux qualification remains missing.
- [x] **NO REGRESSION** — Final syntax and T1812 pass; the guarded T1812/T1669 band reports `All tests successful`, `Files=2, Tests=23`, and the final expanded T1812 reports `Files=1, Tests=11`. The production supervisor and original watcher are unchanged. Book rendering and claim/map sync pass; the initial staged driver passes every non-acceptance doctrine and rejects this formerly unchecked box. Fresh source and endpoint-root censuses prove no production importer or endpoint residue. The corrected staged driver passes every doctrine with fresh evidence-backed acceptance; the final hook rechecks the committed snapshot; full CI remains blocked and is not substituted by these checks.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.2.3.2.3.1 inactive connection I/O)

- [x] **ROOT CAUSE (WHY + WHERE)** — The retained initial T1813 load reports `BEGIN failed--compilation aborted at t/1813-process-coordinator-connection.t line 8`: the qualified Endpoint has no framed connection owner. Raw peer tests independently require header/type admission, finite queues and unchanged framing across partial writes before parent admission can use the transport.
- [x] **ADDRESSED (verified)** — The inactive Connection passes literal raw-peer, queue boundary-plus-one, fixed deadline, saturated EOF, native SIGPIPE and inherited-descriptor controls. An intentionally corrupt frame scheduler and blocking readiness/sleep controls fail the independent oracles; actual bounded advancement passes. No production runner imports this module.
- [x] **NO REGRESSION** — Guarded T1813/T1812/T1669 report `All tests successful`, `Files=3, Tests=36`; existing supervisor and Wire sources are unchanged. The harmless single-use test-hook warning is scoped away before final focused recheck. Book behavior and canonical fact are synchronized without raising containment ceilings; rendered book, regenerated claim/map and the corrected staged doctrine driver pass. The initial signature-format rejection and its exact diagnostic repair are retained above. The task retains explicit missing Linux, admission and runtime qualification.

## Acceptance Checklist (.19.2.3.1.2.2.5.5.2.3.2.3.2 inactive service admission)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'sub new_connection'` locates ef450a2e6: framed I/O has no live parent/admission owner. The corrected raw-peer watcher then fails `at t/1814-process-coordinator-service.t line 267` and line 306 because the first Service transfers expired snapshots and returns endpoint cleanup success despite a reported connection-close failure. The earlier callback/precedence fixture errors are separate retained failures.
- [x] **ADDRESSED (verified)** — Service rechecks fixed lifetime at receipt and transfer, revokes authority before closing, retains first failure and combines descriptor/endpoint cleanup truth. The failing lifetime/cleanup controls become GREEN (`All tests successful`, Files=1, Tests=9); expanded raw peers additionally pass real slow authentication, saturated fair progress, exact timestamp boundaries and actual fork-copy cleanup. No production runner imports the new modules.
- [x] **NO REGRESSION (focused endpoint boundary; broader qualification failed)** — Service and T1814 syntax checks report syntax OK. Expanded T1814/T1813/T1812 each report ok; unchanged T1669 fails subtests 9-10 in the same band, so its Files=4, Tests=48 result remains FAILED. The exact source comparison is empty, endpoint residue is absent and the selected normal-user process census is empty. No retry, timeout widening or repaired-startup claim is made. The synchronized rendered book, claim/map projections and staged doctrine driver pass, including fresh evidence-backed acceptance; the hook rechecks the final snapshot. The recurrence remains owned below.

## Service-band startup recurrence — owner `.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2`

The service slice's guarded T1814/T1813/T1812/T1669 invocation fails overall.
The first three watchers are ok; unchanged T1669 fails Rust proxy subtest 9
and legacy RAM-capture subtest 10. Both proxy modes return timed_out instead
of their distinct intended nonzero/admission failures. Legacy signal and
stream producers lack their independent main-entry markers. The signal
wrapper reports timed_out, empty streams, signal 15, observed handoff
158067565197000, start 158067563881000 and finish 158072595410000 ns; its
leader_reaped/group_gone are true. Handoff EOF does not prove main entry.

The full band is Files=4, Tests=48, FAILED, SHA-256
`b39f1e68a52aa72916cc92b4d9fd7b7b4904fbae19a5fc16f67eae58c9ab1428`.
Artifacts: `.artifacts/logs/coordinator-connection-admission-20260907/`.
Exact HEAD comparison finds no change in T1669, shared supervisor, Wire,
RustParityRuntime or RamGuardFixtureRuntime. New modules have no production
importer. Guard/test census after termination is empty and exact endpoint
residue is absent. The bounded syspolicyd query restricted to this repository's
Rust-proxy/legacy fixture paths returns no records; this does not exclude an
OS wait. Live target birth identities, exact transient fixture paths and kernel
wait chains were not captured, so historical causal attribution remains missing.
Raw logs are ignored; tracked source/oracles, this exact result/hash and Git
retain the durable evidence. No rerun turns the failed band into qualification.

The existing startup owner must obtain a contemporaneous causal discriminator
and independently falsify a repair before parent wire/runtime qualification.
The old authenticated helper is stopped and only admits the earlier T1668
target shape; another passing regression or an uninstrumented T1669 retry
would not close that gap. The endpoint approval is fully implemented; launch,
complete CI and push remain blocked.

Diagnostic-selection scope history: retrieve the complete original `.3.8` discriminator/admission rationale from `5d5fa132737989dd3041bb190a19a350e70c0e1d:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`; current parent and child nodes retain the selected contract.

Startup reading and diagnostic-selection gate evidence: retrieve the complete text at `1a726136f4d44cf43c1ef7d749d9f46feab69c1e:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`. The live diagnostic nodes retain their scope and outcome.

Diagnostic admission/observer checklists: retrieve complete checked evidence from `060f8629935d953b1f31d1a7e754a228c30c6233:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`; the live .3.8.1/.3.8.2 nodes retain verification. This exact-version pointer preserves their historical acceptance.

## Acceptance Checklist (legacy capture selection `.3.8.9`)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'choices.append((request, admitted, progress))' -- scripts/observe_fixture_startup.py` identifies 34d84430bfa70b7b2ed2b39d08e8b38edd0df58e's all-family eligible list. Actual .8.8 captures passing Rust while legacy fails. The independent mixed-family oracle rejects that unfiltered mechanism with [30] != [60]; this fixes diagnostic selection, not the legacy startup cause. Prior capture acceptance is retained exactly at e0ab35442ceabdd2414da211b88817f8a2853e2d in this task path.
- [x] **ADDRESSED (verified)** — Explicit legacy selection reaches observer/caller/sequence, preserves all-family default and unrelated evidence, and reserves the request for eligible legacy ancestry. Missing selected coverage and wrong-family settlement fail. Invalid selectors cannot fork/release a test; producer main-entry evidence excludes the producer and its remaining wrapper, with progress scope explicit.
- [x] **NO REGRESSION** — Guarded discovery passes 85 controls, including real native legacy invocation readiness and helper lifetime, independently falsified mixed-family selection and existing admission, races, source identity, original-status, storage, cleanup and budget controls. Syntax and unchanged sampler/original-test/engine hashes pass; owned control residue is absent. The Knowledge Map reports `knowledge-map: OK`; book inspection, exact generated-build cleanup and staged doctrines complete this slice. Actual legacy sampling, prospective OS retention and causal repair remain open.

Readiness `.3.8.4` acceptance: retrieve the complete checked evidence from `58b14d923980bd92f70e81f20e5d903001c8d2f1:docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md`; its live node retains verification above. This exact-version pointer contains historical checklist growth while preserving every assertion.

## Captured recurrence evidence .3.8.8

Director READY supplies session-b175017522fc41849b300985bdc2e564, helper 80960 (1788846139.777481), UID/RUID 501 and unchanged sampler 3ae0843d817587295322d40344b2ea58de576bd19075b7d6a2c8e9a7bfac9845. Committed sequence 5d5fa132737989dd3041bb190a19a350e70c0e1d, producer c5421c2636b82dcb38a3bf883c3c2addcb4ce0d61eb258a3d3c96f9cd242a66d, starts exactly one invocation and stops on its original failure. Test 85445 (1788846210.121831), unchanged source 7e55021faab2a1654a9854355b4fd6f4bb44c1f50887b03f00df8b98eeafbe91, is ready before release (Python monotonic ns 198211226405416 then 198211226684500); attach is 198211246147041. Native admission binds Rust proxy 85889 (1788846218.932484) to wrapper 85888 (1788846218.905307) and that test, in .artifacts/tmp/process-supervisor-tests/fsmgen-NSI_Hqhp. Wrapper source df525c2166853a62c81b9a5aa70eea9606e3bd96c88c46f1844c1b4c55c7d2b0; proxy dd39d5015afa146af4ecf8ec60573264ca37e38838d4248a395f9e3b2d3dbff7 prints resolution-failed to stderr then exits 9. One request is published; target-only spindump returns zero without timeout, retaining 64291 bytes with SHA-256 b7c4dd45faff090568ce164107f7871f2e8fb580e052213a543b84a0bdc30d3c. The report names only Perl 85889, parent 85888, UID 501 and unique PID 23911847. Its 81 reported samples during 2026-09-08 07:43:39.804 through 07:43:40.609 +0200 traverse AppleSystemPolicy offsets 33268, 32024, 27236, 13740, UUID 8474AAC8-5327-3045-A969-9B20DBF588BD; kernel UUID 3F7964F9-C5A6-39D4-942D-02750C0980E0 matches the previous host capture. The unresolved user frame is perl+3393984 at 0x10252c9c0; atos against the installed Perl returns the address unchanged, so no named user-frame or atomic capture-birth authority is claimed. The Rust subtest later passes; its policy wait cannot establish the different legacy failures. Also observed: Rust wrapper 86136 (1788846220.721877); signal wrapper 86145 (1788846220.864968) and producer 86146 (1788846220.877228); streams wrapper 86757 (1788846225.894412) and producer 86758 (1788846225.906345). Each wrapper descends from the same test and each producer from its named wrapper. Legacy source SHA-256: wrapper bd13191666dff15eefa7b79dbe3835e114efe6ba741ee6b9258547a4b835143c; signal c6970d422cfaa6c97402f16b7d367d4e31d15c3568021263428956a2b65fe774; streams f60440e98ca5fcba1833cb5379464acfef4101329f19ce42e3c7abe27ab93242. Both native main-entry markers remain unobserved, and the original marker assertions fail. The signal wrapper's retained result is timed_out at its unchanged five-second wall with empty streams and proved group cleanup; streams timeout remains a passing negative assertion but its missing main marker fails. Original TAP fails subtest 10 in 1..14; native wait 256/exit 1 and sequence exit 1 remain authoritative. The sequence writes failure and helper settlement, launches no second invocation and makes no qualification claim. Independent libproc checks return ESRCH for all nine recorded test/helper/fixture births; the helper is stopped with authentication_invalidated true and last_request 1. Sudo PID 85994 is absent, but its native birth and unobserved descendants remain unknown. The declared source digest/size set exactly matches five retained copies. The first exact-path information/debug query returns Rust XProtect results at 07:43:40.604789 +0200, path token c6efb06d7f80bd64. Later extended token/PID/path queries, the exact original query, a token-only superset and the exact-second fixed-prefix query all return no events. This observed loss of queryability invalidates negative historical-log inference; it does not prove no legacy policy activity. Apple's Generating Log Messages from Your Code documents normally memory-only Info/Debug storage. Subsystem configuration inspection exits 77 because root is required; no setting changes or broader privilege request occur. Exact local eviction/configuration cause remains unproved. Current read-only inspector ancestry reaches Codex 11839 (1788806700.728210), then the previously recorded shell 37861 (1788791321.503862); login 37767 identity is denied. This is current-tool evidence, not reconstructed exited-sequence ancestry, and supplies no new permission-effect claim. Re-derivation: retained raw native report, original TAP/wait, source set and query outputs. Falsification: passing Rust versus failed legacy identities reject cross-fixture causation; the exact query's changed result rejects durable/complete retrospective-log assumptions. Durability: task, book, canonical fact, tracked producers/controls and Git preserve identities and meaning; raw artifacts and scratch post-inspection producers remain an explicit gap under .artifacts/logs/t1669-prospective-sequence-20260908/, sequence run-f3b8666019014a4dab430e36f3501569 and invocation run-49ce54ed1ec24a478e60522a71bedd47. Digests: sequence journal 69d7007e5badfbdd35564255d4bfc2790b3b9ad120f070e7560a7f5928585101; observer journal 7309b9965871a2a1efe7213eafce6e8ff59238b1a955bc489a01b317e9374cfd; TAP 66a9ad50c830875618225fa1e18ec8a50feb77793e76c93ffde46085ee637125; stderr f9a1c99431be31828da8de40c66b55534e1f365467440655e79e00c86b63dafb; first policy result 3f0647190131997cd5a014fdd39218d6d5c45d53314785977cc8e72d7d7bf43f. Sibling .8.9 owns failing-family selection and .8.10 owns prospective OS-record retention before another capture. Causal repair .2, parent qualification, full CI and push remain open.
