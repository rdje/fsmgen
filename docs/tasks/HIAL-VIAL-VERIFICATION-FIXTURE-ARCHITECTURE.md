# HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE: Hardware And Verification Intent Architecture

## Metadata

- Tree ID: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`
- Status: `active`
- Roadmap lane: `Verification code generation / intent architecture`
- Created: `2026-07-29`
- Last updated: `2026-08-31`
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
  Status: `active`
  Goal: `Implement and capability-qualify the selected VHDL verification backend.`
  Acceptance: `The bounded VIAL subset emits deterministic, efficient, readable, source-mapped VHDL artifacts without requiring VHDL knowledge from a VIAL author, analyzes/elaborates/runs under the exact installed profile, matches the portable normalized result oracle, reports exact standard/methodology/PSL capabilities and non-claims, migrates or versions the inert package exactly as contracted, and leaves HIAL VHDL synthesis output distinct.`
  Verification: `Clean decision/selection predecessor e5aa90b7ad4dc0164bbbdffa285b8351158592e5 activates this implementation parent and child .15.1 alone. Children .15.1-.15.4 can complete deterministic provider-free emission and review without an installed analyzer; .15.5 separately owns exact GHDL execution, while .15.6-.15.7 own OSVVM emission and qualification. Activation changes no source, artifact, capability, support, analyzer, elaboration, runtime, result, or parity behavior.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15: activate VHDL backend implementation`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.7`

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
  Status: `active`
  Goal: `Implement and prove explicit architecture resource caps and graceful bounded failure.`
  Acceptance: `Apply the selected caps at the earliest authoritative stages with deterministic diagnostics, atomic no-partial-output behavior, same-volume cleanup, boundary/over-bound tests, and unchanged accepted-profile semantics; host exhaustion and external-tool crashes are not accepted as product limit enforcement.`
  Verification: `Clean predecessor b441e7a8b closes measured-family publication. The activation partitions cap work by authoritative stage under decisions 0056/0059/0072, preserves all selected measurement levels, and changes no product behavior or claim.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4: activate architecture cap hardening`
  Children: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.1, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.2, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.3, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.4, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.5, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.6, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7, HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8`

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
  Status: `active`
  Goal: `Prove cross-family cap consistency, atomic failure, cleanup, and durable closeout before promotion.`
  Acceptance: `Independently enumerate every selected cap and owning stage; require boundary and adjacent excess evidence, stable diagnostic family/path/requested/allowed data where safe, no partial final output, no external-tool invocation behind known excess, exact repository-local cleanup, and unchanged accepted-profile identities. Revalidate all immutable calibration publications or version them explicitly after intentional behavior changes, synchronize task/decision/Knowledge Map/mdBook truth, and close .17.4 without promoting budgets, support, or capacity.`
  Verification: `Clean 5583365cb closes the complete runtime-stream leaf after its guarded closure suite and source census. Decision 0093 assigns this final child the independent cross-family consistency, atomic-failure, cleanup, immutable-publication, and durable-closeout proof. Activation changes no product behavior, cap, publication, support statement, budget, or capacity claim. The first implementation slice must enumerate the live cap policy and every closed child evidence owner before selecting the smallest missing cross-family proof.`
  Commit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.8: activate cross-family cap closeout`
  Inventory: `Clean activation 02768a427 enables the read-only first slice. The live policy exactly joins 50 catalog axes to 23 groups, 19 selected interactions, six non-axis envelopes, four backend profiles, and three runtime profiles; all 70 declared group-evidence references and every interaction/envelope evidence path exist. That establishes selection and declared-value alignment, not final closeout: runtime_stream_envelopes still cites only t1663/t1672/t1676 and t1685 has no runtime-group-specific assertion, so none of the completed t1720-t1749/t1751-t1762 evidence is independently joined. The 256-file immutable calibration store and its b66de5ce6 closure manifest remain internally addressable, but the publication explicitly denies cap_implementation and predates every .17.4 child. Re-derive: build the policy and independently census its catalog join/evidence paths. Falsify: t1685's missing-axis mutation and an existence check over every referenced path reject omissions. Durability: this task, the synchronized book/card frontier, and the work-unit commit retain the result. The next slice adds a caller-sealed cross-family closeout layer; it must consume current policy authority internally, distinguish measurement publication from cap proof, and bind each selected group to boundary/excess, diagnostics, atomicity/no-tool, cleanup, and accepted-identity evidence before any calibration disposition.`
  Foundation: `Executable RED t1763 first fails only because ArchitectureScaleCapConsistency is absent. The exact-class implementation accepts no inputs, rebuilds the current policy internally, and emits all 23 selected groups and 50 axes with the same seven closed evidence dimensions. Every dimension begins pending with no promoted evidence; policy paths remain candidates. Exact schema, invocant, argument, group, axis, authority, candidate-evidence, dimension, defensive-copy, and mutation checks fail closed. The historical calibration authority remains measurement-only, cap_implementation remains a prohibited relabel, and disposition stays blocked until every sealed dimension is independently verified. Focused t1763+t1685 passes Files=2/Tests=84 without executing a product route or external tool. The next slice independently joins the completed runtime-stream leaf.`
  Runtime Join: `The caller-sealed consistency authority now promotes only runtime_stream_envelopes. A one-entry-per-test classification maps the three selected materialization profiles and all 42 completed t1720-t1749/t1751-t1762 hardening leaves across boundary, adjacent excess, diagnostics, atomicity, no-tool, cleanup, and accepted identity; the union is exact and every path exists. T1763 independently reconstructs each ordered evidence array, requires that complete 45-path union, and rejects omitted or foreign runtime evidence. All other groups remain pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute all sealed paths through the RAM-guarded 46-file suite. Falsify: the exact union plus omission/foreign mutations fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the classification. The complete suite reports All tests successful at Files=46/Tests=210 in 417 wallclock seconds. No cap, level, accepted profile, behavior, publication, support, budget, or capacity claim changes. The next slice independently joins backend_artifact_graph. Adjacent doctrine finding: the rationale-ledger manifest is at ordinal 2907 while DEVELOPMENT_NOTES_INDEX.md still advertises 2905; the range-ID-only index check does not catch the mismatch, so a separate clean task-tree slice must reconcile the displayed row and add a numeric-cell falsifier before the next rationale append.`
  Backend Join: `The caller-sealed consistency authority now also promotes backend_artifact_graph. A one-entry-per-test classification maps the four profile foundations t1646-t1649, their cross-profile qualification t1650, and the four t1716-t1719 admission-order hardeners across boundary, adjacent excess, diagnostics, atomicity, no-tool, cleanup, and accepted identity. T1763 independently reconstructs every ordered projection, requires the exact nine-path union, checks path existence, and rejects omitted or foreign backend evidence; its generic defensive-copy check now preserves the selected group's actual sealed state rather than assuming the alphabetically first group is pending. Runtime remains verified and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute all nine evidence paths plus t1763 and t1685 through the repository-local RAM guard. Falsify: t1763's exact projections, union, omission, foreign-evidence, and caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the classification. The complete guarded suite reports All tests successful at Files=11/Tests=241 in 566 wallclock seconds. No cap, level, accepted profile, provider boundary, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews the smallest remaining two-witness group, checking_models.`
  Checking Models Join: `The caller-sealed consistency authority now also promotes checking_models. T1630 owns exact model-instance and scalar-state-cell limit admission, adjacent rejection, provider-free state evaluation, same-volume cleanup, and deterministic construction/evaluation/rerun identities; t1711 independently proves compact count agreement, accepted plan identity, rejection before model normalization, and no partial ExecutionIR or plan. T1763 reconstructs the two-path projections and union, checks both paths, and rejects omitted or foreign evidence. The omission falsifier removes one of two adjacent-excess witnesses so the exact sealed-authority comparison is exercised; removing the sole boundary witness correctly fails earlier at the non-empty verified-evidence shape gate. Runtime/backend remain verified and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1630 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1711, t1763, and t1685 under the repository-local RAM guard. Falsify: exact limit and adjacent cases plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the classification. The guarded suite reports All tests successful at Files=4/Tests=104 in 100 wallclock seconds. No cap, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews checking_faults.`
  Checking Faults Join: `The caller-sealed consistency authority now also promotes checking_faults. T1633 owns exact fault limit admission, adjacent rejection, provider-free lifecycle evaluation, same-volume cleanup, mutation defenses, and deterministic construction/evaluation/rerun identities; t1714 independently proves compact count agreement, accepted plan identity, rejection before fault normalization, and no partial ExecutionIR or plan. T1763 reconstructs the two-path projections and union, checks both paths, and rejects omitted or foreign evidence. Runtime/backend/checking-model remain verified and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1633 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1714, t1763, and t1685 under the repository-local RAM guard. Falsify: the exact 4,096/4,097 boundary pair plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the classification. The guarded suite reports All tests successful at Files=4/Tests=98 in 21 wallclock seconds. No cap, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews checking_randomness.`
  Containment Finding: `The canonical Knowledge Map cards now occupy 46,939 lines/3,464,850 bytes against the older .17.4.7 transition allowance of 46,942 lines/3,464,885 bytes, leaving three lines/35 bytes while remaining far below the hard 65,536-line/4,194,304-byte enforcement ceiling. Re-derive: aggregate tracked docs/knowledge Markdown with wc and add the knowledge_cards baseline to its declared transition max_growth. Falsify: scripts/check_live_document_size.sh rejects transition-budget or hard-ceiling excess. Durability: this task, doctrine/live_document_size/surfaces.jsonl, and the work-unit commit retain the distinction. The next evidence-family sync must compact the canonical card rather than silently increase its allowance.`
  Checking Randomness Join: `The caller-sealed consistency authority now also promotes checking_randomness without pretending that its nominal component cap is canonically reachable. T1634 proves a provider-free accepted 8,440-occurrence route, adjacent 8,441 plan-byte rejection, explicit 65,536-occurrence preflight dominance, 65,537 occurrence rejection, replay identities, mutation defenses, and same-volume cleanup; t1715 independently proves compact occurrence agreement, accepted plan identity, rejection before operation materialization, and no partial ExecutionIR or plan. T1763 reconstructs the two-path projections and union, checks both paths, and rejects omitted or foreign evidence. Every earlier verified group remains sealed and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1634 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1715, t1763, and t1685 under the repository-local RAM guard. Falsify: both route and component boundary/excess pairs plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, decision 0093, and work-unit commit retain the layered classification. The guarded suite reports All tests successful at Files=4/Tests=98 in 411 wallclock seconds. No cap, route boundary, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews checking_scoreboards.`

  Checking Scoreboards Join: `The caller-sealed consistency authority now also promotes checking_scoreboards through three layer-specific witnesses. T1631 owns both exact scoreboard axes, the provider-free complete-transaction FIFO oracle, adjacent rejection, identities, mutation defenses, and same-volume cleanup. T1690 independently proves that the semantic scalar capacity boundary admits before reference resolution and its adjacent excess returns no partial semantic report. T1712 is deliberately not classified as boundary evidence: it owns compact execution preflight agreement, accepted plan identity, both normalized-path adjacent excesses, no scoreboard normalization, and no partial ExecutionIR or plan. T1763 reconstructs every ordered projection and the exact three-path union, checks each path, and rejects omitted or foreign evidence. Every earlier verified group remains sealed and every unaudited group remains pending, so calibration stays historical, incomplete, and blocked. Re-derive: execute t1631 with FSMGEN_VIAL_SCALE_EXACT=1 plus t1690, t1712, t1763, and t1685 under the repository-local RAM guard. Falsify: semantic, execution, and terminal boundary/excess controls plus projection/union/omission/foreign/caller-mutation controls fail closed. Durability: this task, book, Knowledge Map card, consistency source/test, and work-unit commit retain the layer-specific classification. The guarded suite reports All tests successful at Files=5/Tests=119 in 23 wallclock seconds. No cap, level, accepted profile, product behavior, publication, support, budget, or capacity claim changes. The next slice independently reviews checking_coverage.`

  Containment Resolution: `The cap-policy card's long one-path-per-line reverify list is now a shorter equivalent set of numeric brace ranges plus exact outliers; every expansion resolves to an existing tracked test. With checking-randomness evidence added, the card aggregate falls from 46,939 lines/3,464,850 bytes to 46,903 lines/3,462,766 bytes, restoring 39 lines/2,119 bytes below the inherited transition allowance without changing it. Re-derive: expand every compacted pattern and aggregate docs/knowledge Markdown with wc. Falsify: missing paths fail the explicit expansion census, and Knowledge Map/live-document checks reject freshness, answer, transition, or ceiling drift. Durability: this task, the compacted card, generated shard, containment manifest, and work-unit commit retain the resolution.`

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
therefore closes deterministic generation. Measurement parent `.17.3` is
active; completed `.17.3.5.4` supplies the reports now owned for publication/reload by `.17.3.5.5`.

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

## Version-Retrievable Historical Views

- Acceptance history manifest: `docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl`

The manifest binds the complete predecessor task file and its exact suffix from `## Verification Log` through end of file to revision `6fe704c7b0a8ec45d31f188f235eceeec388499b`. The live task tree above remains authoritative; later acceptance evidence appends after this bounded pointer.

## Acceptance Checklist (enforced) — `.17.4.7` GHDL object-descriptor and file-mode admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the pre-repair `prove -Iperl t/1736-vial-ghdl-object-descriptor-admission.t` RED emitted five exact `Failed test` diagnostics ` at t/1736-vial-ghdl-object-descriptor-admission.t line 126`: foreign kind, numeric-looking string bytes, numeric false executable, non-executable descriptor over `0700`, and executable descriptor over `0600` all admitted; canonical false/`0600`, true/`0700`, and exact same-volume cleanup controls passed.
- [x] **ADDRESSED (verified)** — one `_validate_object` boundary now serves writer and resume, requiring closed scalar kind/digest/path identities, canonical nonnegative numeric bytes, a real `JSON::PP::Boolean`, exact content-addressed repository-relative path, matching same-volume regular-file size/SHA-256, and descriptor-selected `0600` or `0700`; `perl -Iperl -c perl/FSM/VIAL/Backend/GHDLLifecycle.pm` reports `syntax OK` and t1736 turns fully green at `Files=1, Tests=3`.
- [x] **NO REGRESSION** — the final RAM-guarded portable/OSVVM qualification and GHDL admission collection reports `All tests successful` at `Files=9, Tests=35`, including installed exact-provider checked-report reproduction and zero residue. All 58 mdBook chapters test; the inspected 93-file/20,332-KiB repository-local build contains the runnable t1736 control and is removed. Knowledge Map parity is `1,156` facts / `6,183` questions / `6,355` occurrences / `136` shards; claim inventory/disposition closes `1,693` candidates with zero gaps; live containment keeps the knowledge-card line allowance unchanged, installs a fresh exact 14-line/756-byte mdBook authority, and raises no ceiling. Staged task acceptance and all 12 registered doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` GHDL state/owner file admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the pre-repair `prove -Iperl t/1737-vial-ghdl-state-owner-file-admission.t` RED admitted both state-file forgeries at ` at t/1737-vial-ghdl-state-owner-file-admission.t line 191` and failed owner mode, string-version, foreign-field, and oversized-marker controls at lines 93, 101, 107, and 115 respectively; exact canonical `0600` state/owner controls and same-volume cleanup passed, leaving exactly two of three top-level subtests failed.
- [x] **ADDRESSED (verified)** — `_read_state` now admits only same-volume regular exact-`0600` files no larger than 1 MiB before decode; `_owner_matches` admits only a canonical exact-`0600` marker no larger than 4 KiB with the closed four keys, scalar matching identities, and canonical numeric version 1; `_write_atomic` normalizes committed mode to `0600` independently of umask. `perl -Iperl -c perl/FSM/VIAL/Backend/GHDLLifecycle.pm` reports `syntax OK`, and t1737 turns fully green at `Files=1, Tests=3`.
- [x] **NO REGRESSION** — the final RAM-guarded portable/OSVVM qualification and GHDL admission collection reports `All tests successful` at `Files=10, Tests=38`, including installed exact-provider checked-report reproduction and zero residue. All 58 mdBook chapters test; the inspected ignored 93-file/20,336-KiB repository-local build contains the runnable t1737 control and is removed with its empty task-local temporary root. Knowledge Map parity is `1,156` facts / `6,184` questions / `6,356` occurrences / `136` shards; claim inventory/disposition closes `1,695` candidates with `164` claim records, `938` gates, `593` reviewed dispositions, and zero gaps; live containment installs the fresh exact 14-line/718-byte mdBook authority without raising a ceiling.

## Acceptance Checklist (enforced) — `.17.4.7` GHDL handle/state scalar JSON-type admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the valid pre-repair `prove -Iperl t/1738-vial-ghdl-handle-state-scalar-types.t` RED emitted seven exact failures ` at t/1738-vial-ghdl-handle-state-scalar-types.t line 206`: handle schema-version/ordinal strings and booleans plus rehashed state ordinal string, schema-version boolean, and ordinal boolean all resumed. Exact numeric controls and all cleanup passed; state schema-version string rejected only because its earlier coercive comparison changed Perl scalar encoding before identity reconstruction, proving admission depended on evaluation order. Exactly two of four top-level subtests failed.
- [x] **ADDRESSED (verified)** — shared handle/state boundaries now require canonical JSON-integer schema versions and ordinals, scalar schema/lifecycle/state/successor/content/path/predecessor identities, and closed hash storage/authority before semantic equality or digest reconstruction; state ordinal is bound to the closed state name at read time. `perl -Iperl -c perl/FSM/VIAL/Backend/GHDLLifecycle.pm` reports `syntax OK`, and t1738 turns fully green at `Files=1, Tests=4`.
- [x] **NO REGRESSION** — the final RAM-guarded portable/OSVVM qualification and GHDL admission collection reports `All tests successful` at `Files=11, Tests=42`, including installed exact-provider checked-report reproduction and zero residue. All 58 mdBook chapters test; the inspected ignored 93-file/20,340-KiB repository-local build contains the runnable t1738 control and is removed with its empty task-local temp root. Knowledge Map parity is `1,156` facts / `6,185` questions / `6,357` occurrences / `136` shards; claim inventory/disposition closes `1,695` candidates with zero gaps; the rationale ledger reconstructs `2,907` entries, and live containment installs the exact 13-line/687-byte mdBook authority without raising a ceiling.

## Acceptance Checklist (enforced) — `.17.4.7` GHDL request/storage/command-plan scalar JSON-type admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -v t/1739-vial-ghdl-request-scalar-types.t` RED emitted nine exact failures ` at t/1739-vial-ghdl-request-scalar-types.t line 312`: string provider/source bytes, expected record count, observation total width, repetition count, storage version, OSVVM command-plan version, generated-settings bytes, and boolean storage version all admitted. The foreign observation-entry width already rejected as the adjacent falsification control; exact numeric forms and cleanup passed, leaving exactly two of five top-level subtests failed with zero residue.
- [x] **ADDRESSED (verified)** — shared pre-coercion helpers now admit only canonical JSON nonnegative, positive, or exact integers as appropriate. Provider/source bytes, expected record/catalog counts, repetition count, storage version, OSVVM command-plan version, and generated-settings bytes all reject foreign scalar types before filesystem comparison, trace validation, command authority, digest construction, or lifecycle-root creation. `perl -Iperl -c perl/FSM/VIAL/Backend/GHDLLifecycle.pm` reports `syntax OK`, and t1739 turns fully green at `Files=1, Tests=5`.
- [x] **NO REGRESSION** — the final RAM-guarded portable/OSVVM qualification and GHDL admission collection reports `All tests successful` at `Files=12, Tests=47`, including installed exact-provider checked-report reproduction and zero focused staging residue. All 58 mdBook chapters test; the inspected ignored 93-file/20,344-KiB repository-local render contains the runnable t1739 control and is removed. Knowledge Map parity is `1,156` facts / `6,186` questions / `6,358` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim inventory/disposition has zero gaps; live containment installs the exact 13-line/678-byte mdBook authority without raising a ceiling; staged acceptance and all 12 doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` OSVVM persisted-request envelope scalar JSON-type admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -v t/1740-vial-osvvm-persisted-request-scalar-types.t` RED emitted four exact failures ` at t/1740-vial-osvvm-persisted-request-scalar-types.t line 63`: envelope schema-version and nested repetition-count strings and booleans all passed reload. The exact numeric envelope passed, leaving exactly one of two top-level subtests failed without filesystem work.
- [x] **ADDRESSED (verified)** — persisted-envelope reload now requires scalar-exact schema/materialization/plan/source/storage/validation identities and canonical JSON integer envelope version and repetition count before returning a request to predecessor, lifecycle, or tool stages. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMeasurement.pm` reports `syntax OK`, and t1740 turns fully green at `Files=1, Tests=2`.
- [x] **NO REGRESSION** — the final RAM-guarded installed OSVVM qualification, measurement, matrix, GHDL request, and persisted-envelope collection reports `All tests successful` at `Files=5, Tests=26`. All 58 mdBook chapters test; the inspected ignored 93-file/20,348-KiB repository-local render contains the runnable t1740 control and is removed. Knowledge Map parity is `1,156` facts / `6,187` questions / `6,359` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim inventory/disposition has zero gaps; live containment installs the exact 12-line/605-byte mdBook authority without raising a ceiling; staged acceptance and all 12 doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` OSVVM persisted provider-verification admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -v t/1741-vial-osvvm-persisted-provider-admission.t` RED emitted six exact failures ` at t/1741-vial-osvvm-persisted-provider-admission.t line 48`: independently changed provider, version, root commit, root tree, materialization-manifest digest, and provider-source identity all passed persisted-envelope reload. The selected six-field projection passed, leaving exactly one of two top-level subtests failed without predecessor, lifecycle, filesystem, or external-tool work.
- [x] **ADDRESSED (verified)** — `_validated_request_envelope` now compares the canonical persisted provider-verification record with `_provider_projection($raw->{execution_plan})` before returning the request or reading its predecessor handle. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMeasurement.pm` reports `syntax OK`; t1740's exact fixture now carries the canonical plan-derived projection, and t1740+t1741 pass at `Files=2, Tests=4` with all six exact rejection diagnostics.
- [x] **NO REGRESSION** — the final RAM-guarded installed OSVVM qualification, exact eleven-record measurement, matrix, GHDL request, scalar-envelope, and provider-admission collection reports `All tests successful` at `Files=6, Tests=28` in 2,406 wallclock seconds. All 58 mdBook chapters test; the inspected ignored 93-file/20,348-KiB repository-local render contains the runnable t1741 control and is removed. Knowledge Map parity is `1,156` facts / `6,187` questions / `6,359` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim inventory/disposition has zero gaps; live containment installs the exact 12-line/503-byte chained mdBook authority without raising a ceiling; staged acceptance and all 12 doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` OSVVM persisted GHDL-provider admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -v t/1742-vial-osvvm-persisted-ghdl-provider-admission.t` RED emitted seven exact failures ` at t/1742-vial-osvvm-persisted-ghdl-provider-admission.t line 49`: independently changed tool root, archive path/bytes/digest, binary path/digest, and version output all passed persisted-envelope reload. The selected seven-field projection passed, leaving exactly one of two top-level subtests failed without predecessor, lifecycle, filesystem, or external-tool work.
- [x] **ADDRESSED (verified)** — `_validated_request_envelope` now compares the canonical persisted request provider with `_ghdl_provider_projection($raw->{execution_plan})` before source, storage, predecessor, or lifecycle work. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMeasurement.pm` reports `syntax OK`; t1740/t1741 fixtures now carry the plan-derived GHDL authority, and t1740-t1742 pass at `Files=3, Tests=6` with all seven exact rejection diagnostics.
- [x] **NO REGRESSION** — the final RAM-guarded installed OSVVM qualification, default measurement, matrix, GHDL request, scalar-envelope, OSVVM-provider, and GHDL-provider collection reports `All tests successful` at `Files=7, Tests=30` in 69 wallclock seconds. All 58 mdBook chapters test; the inspected ignored 93-file/20,352-KiB repository-local render contains the runnable t1742 control and is removed. Knowledge Map parity is `1,156` facts / `6,187` questions / `6,359` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim inventory/disposition has zero gaps; live containment installs the exact 12-line/494-byte chained mdBook authority without raising a ceiling; staged acceptance and all 12 doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` OSVVM persisted emission-identity admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -v t/1743-vial-osvvm-persisted-emission-identity.t` RED emitted one exact failure ` at t/1743-vial-osvvm-persisted-emission-identity.t line 38`: a foreign well-formed `emission/<sha256>` passed persisted-envelope reload. The independently reconstructed selected composite passed, leaving exactly one of two top-level subtests failed without predecessor, lifecycle, filesystem, or external-tool work.
- [x] **ADDRESSED (verified)** — emit and `_validated_request_envelope` now share `_emission_identity`, binding selected workload/materialization/plan plus persisted source/commands before the request returns. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMeasurement.pm` reports `syntax OK`; t1740-t1742 fixtures now use the exact constructor, and t1740-t1743 pass at `Files=4, Tests=8` with the exact foreign-identity diagnostic.
- [x] **NO REGRESSION** — the final RAM-guarded installed OSVVM qualification, default measurement, matrix, GHDL request, and t1740-t1743 collection reports `All tests successful` at `Files=8, Tests=32` in 69 wallclock seconds. All 58 mdBook chapters test; the inspected ignored 93-file/20,356-KiB repository-local render contains the runnable t1743 control and is removed. Knowledge Map parity is `1,156` facts / `6,187` questions / `6,359` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim inventory/disposition has zero gaps; live containment installs the exact 13-line/572-byte chained mdBook authority without raising a ceiling; staged acceptance and all 12 doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` OSVVM persisted command/source-plan admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -It/lib -v t/1744-vial-osvvm-persisted-command-authority.t` RED emitted one exact failure ` at t/1744-vial-osvvm-persisted-command-authority.t line 40`: swapping the first two provider-analysis commands together with their source-order entries and recomputing both source and emission identities passed persisted reload. The complete selected 68-source/61-provider-command control passed, leaving exactly one of two top-level subtests failed; the reload returned before predecessor, lifecycle, or external-tool work, while public read-only fixture construction created no stage. Final report validation already owned the missing relocated-plan reconstruction but ran too late.
- [x] **ADDRESSED (verified)** — `_validated_request_envelope` now invokes the existing `_validate_runtime_commands` before returning the request, reconstructing the exact relocated plan through `_measurement_plan` and comparing all 68 ordered sources plus commands/settings/libraries/reports/resources without a shadow formula. `perl -Iperl -c perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMeasurement.pm` reports `syntax OK`; final t1740-t1744 use one public-plan-derived complete fixture and pass at `Files=5, Tests=10` in 55 wallclock seconds.
- [x] **NO REGRESSION** — the final RAM-guarded installed qualification, default measurement, matrix, GHDL request, and t1740-t1744 collection reports `All tests successful` at `Files=9, Tests=34` in 133 wallclock seconds; the final strengthened t1744 no-stage control separately passes at `Files=1, Tests=2` in 11 seconds. All 58 mdBook chapters test; the inspected ignored 93-file/20,356-KiB repository-local render contains the runnable t1744 control and is removed. Knowledge Map parity is `1,156` facts / `6,187` questions / `6,359` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim inventory/disposition has zero gaps; live containment installs the exact 11-line/565-byte chained mdBook authority without raising a ceiling; staged acceptance and all 12 doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` OSVVM persisted lifecycle-storage admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -It/lib -v t/1745-vial-osvvm-persisted-lifecycle-storage-admission.t` RED emitted four exact failures ` at t/1745-vial-osvvm-persisted-lifecycle-storage-admission.t line 63`: foreign schema, string/boolean schema version, and an unknown field all passed persisted reload. The exact selected five-field control and every no-stage assertion passed, leaving exactly one of two top-level subtests failed in 10 wallclock seconds before predecessor, lifecycle, filesystem, or external-tool work.
- [x] **ADDRESSED (verified)** — emit and `_validated_request_envelope` now share `_storage_context`; reload closes its five keys and requires JSON-type-preserving canonical equality before returning the request, while the downstream shared GHDL lifecycle remains defense in depth. Product and t1745 syntax are clean; t1740-t1745 pass at `Files=6, Tests=12` in 62 wallclock seconds, and isolated t1745 passes at `Files=1, Tests=2` in 11 seconds.
- [x] **NO REGRESSION** — the selected RAM-guarded installed qualification, default OSVVM measurement/matrix, shared GHDL request, and t1740-t1745 collection reports `All tests successful` at `Files=10, Tests=36` in 134 wallclock seconds. All 58 mdBook chapters test; the inspected ignored 93-file/20,356-KiB repository-local render contains the runnable t1745 control and is removed. Knowledge Map parity remains `1,156` facts / `6,187` questions / `6,359` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim inventory/disposition remains complete at `1,696` candidates with zero gaps; live containment installs the exact 11-line/525-byte mdBook authority without raising a ceiling. Staged task acceptance and all 12 registered doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` OSVVM persisted lifecycle-validation admission

- [x] **ROOT CAUSE (WHY + WHERE)** — after the shared fixture independently reconstructed the nine-field production projection from public construction/materialization plus sealed route authority, the clean pre-repair `prove -Iperl -It/lib -v t/1746-vial-osvvm-persisted-lifecycle-validation-admission.t` RED emitted eight exact failures ` at t/1746-vial-osvvm-persisted-lifecycle-validation-admission.t line 82`: changed record count, diagnostic, domain, fixture, random-decision digest, run order, observation catalog, and unknown field all passed persisted reload. The complete control and every no-stage assertion passed, leaving exactly one of two top-level subtests failed in 29 wallclock seconds before predecessor, lifecycle, filesystem, or tool work.
- [x] **ADDRESSED (verified)** — emit and reload now share `_validation_authority`, deriving all nine fields from public materialization, sealed ExecutionIR, and the checked observation catalog; reload closes the record and requires JSON-type-preserving canonical equality before returning the request, with downstream GHDL lifecycle checks retained as defense in depth. Product/helper/t1740/t1746 syntax is clean; t1740's repetition controls now name the full boundary, isolated t1746 passes at `Files=1, Tests=2` in 29 seconds, and t1740-t1746 pass together at `Files=7, Tests=14` in 182 wallclock seconds.
- [x] **NO REGRESSION** — the selected RAM-guarded installed qualification, default OSVVM measurement/matrix, shared GHDL request, and t1740-t1746 collection reports `All tests successful` at `Files=11, Tests=38` in 253 wallclock seconds. All 58 mdBook chapters test; the inspected ignored 93-file/20,368-KiB repository-local render contains the runnable t1746 control and is removed. Knowledge Map parity remains `1,156` facts / `6,187` questions / `6,359` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim inventory/disposition remains complete at `1,696` candidates with zero gaps; live containment installs the exact 12-line/618-byte mdBook authority without raising a ceiling. Staged task acceptance and all 12 registered doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` OSVVM outer persisted JSON file admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -It/lib -v t/1747-vial-osvvm-outer-persisted-json-file-admission.t` RED emitted ten exact failures: wrong-mode, oversized, symlinked, and simulated-foreign-device request and handle files all passed ` at t/1747-vial-osvvm-outer-persisted-json-file-admission.t line 204` / `line 209`, while both outer artifacts materialized as ambient-umask `0666` rather than exact `0600` at lines 159/161. Canonical sub-limit controls, both non-regular-path rejections, and exact same-volume cleanup passed; exactly three of four top-level subtests failed in 29 wallclock seconds without lifecycle or external-tool work.
- [x] **ADDRESSED (verified)** — request and predecessor-handle readers now walk the exact repository-relative staging chain without symlinks, require one same-volume/current-owner/single-link regular leaf at exact `0600`, bind path and opened-handle device/inode/metadata, perform only a bounded stable read, then apply canonical JSON and existing semantic validation. The request ceiling is 64 KiB and the closed handle ceiling is 4 KiB; exclusive no-follow artifact creation plus final chmod makes `0600` independent of ambient umask. Product/test syntax is clean; strengthened t1747 passes at `Files=1, Tests=4` in 30 seconds, and t1740-t1747 pass at `Files=8, Tests=18` in 238 wallclock seconds.
- [x] **NO REGRESSION** — the final RAM-guarded installed qualification, actual OSVVM measurement/matrix, shared GHDL request, and t1740-t1747 collection reports `All tests successful` at `Files=12, Tests=42` in 308 wallclock seconds; the complete persisted chain separately passes at `Files=8, Tests=18` in 238 seconds with exact cleanup. All 58 mdBook chapters test; the inspected ignored 93-file/20,372-KiB repository-local render contains the three-leg claim and runnable t1747 control and is removed. Knowledge Map parity remains `1,156` facts / `6,187` questions / `6,359` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim verification closes 24 records and all `1,698` candidates through 166 claim-record, 939 gate, and 593 reviewed dispositions with zero gaps; maintained-book authority is exact at 0 files/+23 lines/+2,143 bytes, the Knowledge card is 430 bytes smaller than its committed baseline, and all 22 live-document surfaces pass without a ceiling increase. Staged task acceptance and all 12 registered doctrines pass.

## Acceptance Checklist (enforced) — `.17.4.7` common-controller worker-artifact file admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -It/lib -v t/1748-vial-common-worker-artifact-file-admission.t` RED left the exact 64-MiB boundary and both admitted-mode controls green, but emitted six exact watcher failures ` at t/1748-vial-common-worker-artifact-file-admission.t line 77` / `line 90` / `line 105` / `line 118` / `line 141` / `line 161`: ambient-writable and multiply linked artifacts plus the simulated foreign-device artifact were admitted, cap+1 was fully slurped before a downstream digest rejection, and leaf/parent symlinks reached only generic or post-read staging checks. Exactly two of four top-level subtests failed in under one wallclock second; repository-local cleanup passed.
- [x] **ADDRESSED (verified)** — the common controller now carries the validated repository device into each stage, preflights declared and filesystem bytes at the existing 67,108,864-byte ceiling, walks current-owner/same-volume real parents, admits only a current-owner single-link regular leaf with a safe owner-readable non-executable mode, and binds one no-follow/nonblocking maximum-plus-one read to stable pathname/opened device, inode, mode, link, owner, size, modification, and change metadata before byte/line/digest/census use. Product and watcher syntax are clean; t1748 passes at `Files=1, Tests=4`, and foundation plus portable-SystemVerilog, portable-VHDL, installed-OSVVM, and t1748 consumers all pass (the host-profile foundation rerun is `Files=1, Tests=6`; the other four files are green in the selected five-file run).
- [x] **NO REGRESSION** — the final RAM-guarded common-controller foundation, portable-SystemVerilog runtime, portable-VHDL runtime, installed OSVVM/GHDL qualification, actual OSVVM measurement/matrix, shared GHDL request, complete persisted OSVVM admission chain, and t1748 set reports `All tests successful` at `Files=16, Tests=68` in 331 wallclock seconds; the persisted tail separately passes at `Files=10, Tests=27` in 212 seconds and focused t1748 at `Files=1, Tests=4`. All 58 mdBook chapters test; the inspected ignored 93-file/20,388-KiB repository-local render contains the three-leg claim and runnable t1748 control and is removed. Knowledge Map parity is `1,156` facts / `6,188` questions / `6,360` occurrences / `136` shards; the rationale ledger reconstructs `2,907` entries; claim verification closes 25 records and all `1,702` candidates through 170 claim-record, 939 gate, and 593 reviewed dispositions with zero gaps. Maintained-book authority is exact at 0 files/+27 lines/+2,557 bytes; the cap card uses only its existing +3-line/+542-byte allowance; all 22 live-document surfaces pass with zero ceiling increases. Staged task acceptance and all 12 registered doctrines pass.

**Tracked adjacent finding:** `_validated_worker_artifacts` and the terminal controller census still call `_tree_files`, whose recursive `readdir` materializes and sorts an undeclared number of entries after the isolated worker and its timeout have ended. The worker-result pipe bounds reported metadata but not an unreported output-tree census. A bounded file/directory/path-depth/path-byte census is therefore the next `.17.4.7` admission audit; it is distinct from this slice's per-file read authority.

## Acceptance Checklist (enforced) — `.17.4.7` bounded common-controller worker-output census admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the clean pre-repair `prove -Iperl -v t/1749-vial-common-worker-output-census-admission.t` RED admitted the exact 1,024-file, 1,024-directory, 64-component, and 262,144-relative-path-byte controls, then emitted four empty-diagnostic failures for each first excess ` at t/1749-vial-common-worker-output-census-admission.t line 101` / lines 107/113/123. A simulated foreign repository device reached only the old one-argument-signature error at line 130. Exactly two of four top-level subtests failed in under one wallclock second, independently proving that post-worker `_tree_files` had neither structural ceilings nor caller-selected volume authority; repository-local cleanup passed.
- [x] **ADDRESSED (verified)** — `_tree_files` now streams `readdir`, binds every root/directory pathname to its opened handle and final metadata, requires the caller-selected repository device/current owner/no symlink or special entry, and stops at 1,024 files, 1,024 directories, 64 components, or 262,144 aggregate bytes across all visited relative file/directory paths before returning a bounded sorted vector. Per-stage unreported-file and terminal whole-staging admission pass the repository device into that one census. Product/watcher syntax is clean; t1749 passes at `Files=1, Tests=4`, and the foundation plus all seven common-controller adapters and t1748/t1749 pass at `Files=10, Tests=60` in 62 wallclock seconds. The first sandboxed foundation attempt was invalidated by denied macOS `sysctl`; its identical host-authorized rerun passed at `Files=1, Tests=6`.
- [x] **NO REGRESSION** — the final foundation, semantic/bridge, execution/checking, backend-emission, portable-SystemVerilog, portable-VHDL, OSVVM, balanced-portable, t1748, and t1749 collection reports `All tests successful` at `Files=10, Tests=60` in 62 wallclock seconds; focused t1748/t1749 separately pass at `Files=2, Tests=8`. All 58 mdBook chapters test; the inspected ignored 93-file/20,392-KiB repository-local render contains the exact census claim and runnable command and is removed. Knowledge Map parity is `1,157` facts / `6,193` questions / `6,365` occurrences / `137` shards. Claim verification retains 25 records (24 published/one fixture) and closes all `1,704` candidates through 172 claim-record, 939 gate, and 593 reviewed dispositions with zero gaps; the registry cap is unchanged. Maintained-book authority is exact at 0 files/+13 lines/+1,179 bytes; the new bounded fact card uses a measured transition allowance; all 22 live-document surfaces pass with zero ceiling increases. The rationale ledger is unchanged because the task, fact card, user chapter, and Git own all new rationale directly. Staged task acceptance and all 12 registered doctrines pass.

**Tracked adjacent foundational finding:** the slice-start `wc -c doctrine/claim_verification/claims.jsonl` reported 64,872 bytes against the registry's unchanged 65,536-byte self-cap, leaving 664 bytes; extending the already-owned common-controller record brings the canonical file to 65,381 bytes and leaves only 155, so an ordinary independent three-leg claim cannot fit. No cap was raised. Once this slice is clean, the claim-verification task-tree must own a bounded partition/rollover repair before another independent quantitative claim is published. Re-derive with the tracked registry checker plus `wc`; falsify by canonically encoding the smallest complete available-leg record under the current schema and comparing its bytes with the residue; durability is this task evidence, the registered claim/live-document gates, and the forthcoming separately committed repair leaf.

**Tracked adjacent finding after the clean registry repair:** `_recover_interrupted_stage` still calls a separate `_validate_recoverable_stage` walker that recursively materializes and sorts every directory without the common 1,024-file, 1,024-directory, 64-component, 262,144-relative-path-byte, or current-owner admission. This runs after the stage lock but before any fresh worker or timeout. `_cleanup_residue` also invokes `_tree_files` without the caller-sealed repository device. The next `.17.4.7` sub-slice owns reuse of the common bounded census for interrupted recovery plus exact device-bound residue reporting; destructive cleanup mechanics remain a distinct follow-on audit unless the RED requires them.

## Acceptance Checklist (enforced) — `.17.4.7` interrupted-stage recovery census admission

- [x] **Integration defect owned before repair** — the new shard-2 recovery
  claim proved that `scripts/check_claim_verification_dispositions.pl` still
  reads only `claims.jsonl`, although the production claim verifier and
  `claim_registries.jsonl` admit the bounded registry set. Repair the
  disposition consumer and freeze a claim that exists only in shard 2 before
  this slice can pass doctrine enforcement. Before repair, the production join
  rejected each of the three new dispositions because
  `vial-common-interrupted-stage-recovery-admission-v1` was absent from its
  single-file view. The repaired t1638 fixture stores its only claim in
  `claims-0002.jsonl`; all ten positive and mutation subtests pass, and the
  production join now closes 1,707/1,707 candidates across both shards.
- [x] **ROOT CAUSE (WHY + WHERE)** — t1751's executable RED accepted the exact
  1,024-file interrupted tree but also accepted file 1,025, never reached the
  substituted common-census sentinel, and proved `_cleanup_residue` accepted
  only two arguments rather than the caller-sealed device; three of five
  top-level tests failed. The first boundary failure was reported at t/1751-vial-common-interrupted-stage-census-admission.t line 59,
  while the missing device argument reported line 88. `_validate_recoverable_stage`
  recursively sorted an
  unbounded private walk before fresh work, while cleanup-residue census called
  `_tree_files` without `root_device`. The same slice's new claim then exposed
  the downstream disposition consumer's stale single-shard default. The
  invalid exploratory broad invocation with `--host-max-pct 100` was discarded
  because the product correctly rejects that threshold; the valid default-88%
  guarded rerun is the regression evidence below.
- [x] **ADDRESSED (verified)** — `_validate_recoverable_stage` now delegates to
  the common `_tree_files($path, $root_device)` admission and preserves the
  interrupted-stage symlink/special and hard-link diagnostics; `_tree_files`
  itself enforces the previously private single-link rule for every consumer.
  `_cleanup_residue` requires and receives the sealed repository device.
  Focused t1751+t1749 pass at `Files=2, Tests=9`; host-authorized t1656 passes at
  `Files=1, Tests=6`, preserving recovery, lock, symlink, FIFO, hard-link, and
  cleanup behavior. The disposition checker now validates the finite registry
  set, shard naming/census, per-shard bounds, aggregate bounds, and cross-shard
  claim-ID uniqueness while retaining explicit `--claims` fixture operation;
  t1638 passes all ten subtests and the production checker reports 175 claim
  records, 939 derived gates, 593 reviewed items, zero gaps, and zero open.
- [x] **NO REGRESSION** — the valid default-88% guarded common-controller set
  passes `Files=11, Tests=65` in 64 wallclock seconds across t1656, t1657,
  t1659, t1661, t1667, t1674, t1679, t1681, t1748, t1749, and t1751. Claim
  verification reports two shards / 26 records / 25 published / one fixture;
  inventory independently agrees at 11,390 numeric lines and 1,707 candidates,
  all disposed. All 58 mdBook chapters test; the inspected 93-file/20,408-KiB
  local render contains the exact claim and command and is removed. Knowledge
  Map parity is 1,158 facts / 6,200 questions / 6,372 answer occurrences / 137
  shards. The maintained-book authority is exact at 58 files / 54,324 lines /
  2,933,475 bytes; the knowledge-card transition retains one ratchet step; all
  22 live-document surfaces pass with zero ceiling increases. Staged task
  acceptance and all registered doctrines are required green immediately before
  commit.

**Tracked adjacent destructive-cleanup finding:** the clean post-recovery audit
found that `_run_stage` gives the worker a process group but calls
`_terminate_process_group` only on timeout. A leader can therefore return a
plausible successful result, exit zero, and leave a same-group descendant alive
while the controller validates and later recursively deletes the shared staging
tree. The established `FSM::VIAL::Backend::ProcessSupervisor` contract already
classifies the equivalent state as surviving-descendant residue and performs
bounded TERM/KILL containment. The next `.17.4.7` slice owns an exact normal-exit
descendant RED and parity repair in the common controller. The separate
post-census pathname-identity/delete audit remains next after that clean commit.

## Acceptance Checklist (enforced) — `.17.4.7` normal-exit worker-group containment

- [x] **ROOT CAUSE (WHY + WHERE)** — the executable t1752 RED supplied a
  plausible successful canonical worker result from a zero-exit leader that
  forked a live same-group descendant. `_run_stage` accepted the stage, emitted
  no residue diagnostic, and returned while the group was alive: the three
  safety assertions failed at t/1752-vial-common-worker-process-group-containment.t line 115
  and the adjacent lines, while exact repository-local cleanup passed. The
  parent called `_terminate_process_group` only on timeout, and both parent and
  child treated `setpgid` as best-effort rather than authenticating the child's
  exact group identity.
- [x] **ADDRESSED (verified)** — the child now requires
  `_worker_process_group_ready` before invoking its selected callback. After
  reaping a non-timeout leader, the parent checks the complete negative-PID
  group domain, performs bounded TERM then KILL escalation through
  `_terminate_residual_process_group`, requires group absence, and returns
  `VIAL_SCALE_MEASUREMENT_PROCESS_RESIDUE_ERROR` before decoding or validating
  the plausible worker result. If containment cannot prove absence, an internal
  cleanup-safety bit suppresses terminal census and recursive deletion and
  retains the exact staging identity. Final t1752 passes `Files=1, Tests=11`: its
  TERM-ignoring descendant proves KILL escalation and pre-return absence, while
  forced termination failure proves cleanup remains sealed and a forced
  group-identity failure proves the worker callback is never entered.
- [x] **NO REGRESSION** — the unchanged default-88%/4,096-MiB guarded set passes
  `Files=12, Tests=76` in 65 wallclock seconds across the foundation, every
  executable common-controller consumer, t1748/t1749/t1751, and t1752. Perl
  product/test syntax is clean. All 58 mdBook chapters test; the inspected
  93-file/20,412-KiB repository-local render contains the exact process-group
  contract and runnable proof and is removed. Knowledge Map parity is 1,158
  facts / 6,202 questions / 6,374 answer occurrences / 137 shards. Claim
  inventory independently agrees at 11,391 numeric lines and 1,707 fully
  disposed candidates, so no new quantitative claim or disposition is hidden.
  Maintained-book authority is exact at 58 files / 54,342 lines / 2,934,417
  bytes; the updated fact-card transition retains one ratchet step; all 22
  live-document surfaces pass with zero ceiling increases. Staged task
  acceptance and all registered doctrines are required green immediately before
  commit.

**Tracked destructive-cleanup finding resolved:** after worker-group
containment, the controller still remembered only the staging pathname.
A worker could rename the controller-created root aside, install a different
same-owner/same-volume directory at that pathname, return plausibly, and let
terminal validation fail while `_remove_owned_stage` recursively deleted the
replacement. Moving the root away without replacement also let cleanup claim
success while the displaced tree remained. Independently, the terminal census
was not repeated at cleanup, so 1,025 files introduced after that census were
recursively reclaimed without the common structural bound. This slice owns all
three forms as one destructive-admission defect.

## Acceptance Checklist (enforced) — `.17.4.7` bounded authenticated cleanup admission

- [x] **ROOT CAUSE (WHY + WHERE)** — the corrected host-authorized t1753 RED
  used a canonical zero-exit worker to replace the created root and a
  cleanup-entry hook to add file 1,025 after terminal census. Six of eleven
  assertions failed at t/1753-vial-common-bounded-cleanup-admission.t line 68:
  cleanup reported success, deleted the unauthenticated marker, admitted the
  first excess, emitted neither identity nor census diagnostic, and retained no
  excess residue; the 1,024-file control and exact fixture cleanup passed. The
  signoff extension then moved the root away without replacement and failed the
  cleanup-success assertion at line 83 while retaining the displaced tree.
  `_create_owned_stage` returned no durable root identity, result/terminal
  admission authenticated only the current pathname tree, `_remove_owned_stage`
  treated absence as success, and destructive cleanup called `remove_tree`
  without a cleanup-local bounded census.
- [x] **ADDRESSED (verified)** — stage creation now seals the root's repository
  device, inode, and owner. The parent reauthenticates that identity before
  worker-result validation, at terminal artifact admission, and twice around a
  cleanup-local common census. Cleanup requires the root to remain present and
  exact, rejects replacement or disappearance without recursive deletion,
  admits the existing 1,024-file boundary, and rejects file 1,025 while
  retaining the exact staging identity as residue. Interrupted recovery
  captures its pre-validation root identity and delegates removal through the
  same cleanup gate, so growth from 1,024 to 1,025 between recovery validation
  and deletion also rejects. Final t1753 passes `Files=1, Tests=16`, including
  unauthenticated-marker retention, missing-root residue, both cleanup
  boundaries, recovery re-bounding, and exact repository-local teardown.
- [x] **NO REGRESSION** — Perl product/test syntax is clean; t1751+t1752 retain
  `Files=2, Tests=16`; host-authorized t1656 retains `Files=1, Tests=6`; and the
  unchanged default-88%/4,096-MiB guarded foundation, every executable
  common-controller consumer, t1748/t1749/t1751/t1752, and t1753 pass
  `Files=13, Tests=92` in 68 wallclock seconds. All 58 mdBook chapters test; the
  inspected 93-file/20,428-KiB repository-local render contains the exact claim
  and is removed. Knowledge Map parity is 1,158 facts / 6,204 questions / 6,376
  answer occurrences / 137 shards. Two claim shards retain 27 records / 26
  published / one fixture; inventory and dispositions close 1,711/1,711
  candidates through 179 claim records, 939 gates, and 593 reviewed outcomes
  with zero gaps/open. Maintained-book authority is exact at 58 files / 54,371
  lines / 2,937,015 bytes; the existing knowledge-card transition admits 1,157
  files / 46,761 lines / 3,454,004 bytes; all 22 live-document surfaces pass
  with zero ceiling increases. Staged task acceptance and all registered
  doctrines are required green immediately before commit.

**Tracked adjacent audit:** process-group absence is now followed by exact
root and bounded cleanup admission, but the group model itself has not yet been
falsified against a callback that creates a new session/process group before
its leader exits. The next `.17.4.7` slice must prove whether such a detached
descendant can survive the negative-PID containment domain and mutate the stage
after cleanup admission; if so, it owns the containment repair before any
further destructive-path audit.

## Acceptance Checklist (enforced) — `.17.4.7` detached common-worker descendant containment

- [x] **ROOT CAUSE (WHY + WHERE)** — the corrected host-authorized t1754 RED
  supplied a canonical successful callback whose child called `setsid`, moved
  outside the worker's negative-PID process-group domain, waited for the
  controller to remove staging, recreated that pathname, wrote a late marker,
  and remained alive. The pre-repair controller accepted the measurement, left
  the detached child alive, and admitted the post-cleanup mutation: three of
  five assertions failed at t/1754-vial-common-detached-descendant-containment.t line 79,
  line 83, and line 85. The cleanup-success control and exact fixture cleanup
  passed. `_run_stage` observed only the original group after the worker leader
  exited; session creation changes group identity without changing the live
  child's parentage while that leader remains available to contain it.
- [x] **ADDRESSED (verified)** — the worker now starts from an authenticated
  empty child tree, performs a bounded `ps` parentage census after its callback
  and on TERM, stops newly observed descendants to stabilize that tree, kills
  every exact observed PID, reaps direct children, and requires absence before
  publishing its result. Any observed descendant replaces plausible success
  with `VIAL_SCALE_MEASUREMENT_PROCESS_RESIDUE_ERROR`. A separate one-byte
  status channel must contain exactly `S` and reach EOF; a surviving fork that
  retains its inherited writer therefore cannot authorize cleanup. The parent
  retains its original process-group fallback and admits recursive cleanup only
  when both worker-side and parent-side containment proofs succeed. Final t1754
  passes `Files=1, Tests=5`; t1752 retains `Files=1, Tests=11`; and exact
  RAM-guarded t1656 retains all six top-level subtests including timeout cleanup.
- [x] **NO REGRESSION** — Perl product/test syntax and `git diff --check` are
  clean. The valid default-88%/4,096-MiB guarded foundation, every executable
  common-controller consumer, t1748/t1749/t1751/t1752/t1753, and t1754 pass
  `Files=14, Tests=97` in 65 wallclock seconds. The earlier broad invocation
  with a nonexistent t1659 filename is invalidated and contributes no evidence.
  All 58 mdBook chapters test; the inspected 93-file/20,432-KiB local render
  contains the exact contract and command and is removed. Knowledge Map parity
  is 1,158 facts / 6,206 questions / 6,378 answer occurrences / 137 shards.
  Claim inventory independently agrees at 11,401 numeric lines and 1,711
  candidates; 27 registry records plus 179 claim-record, 939 gate, and 593
  reviewed dispositions retain zero gaps/open. Maintained-book authority is
  exact at 58 files / 54,390 lines / 2,938,088 bytes; the card transition
  admits 1,157 files / 46,772 lines / 3,454,639 bytes; all 22 live-document
  surfaces pass with zero ceiling increases. Staged acceptance and every
  registered doctrine are required green immediately before commit. This
  private repair changes no artifact, support, performance, capacity,
  reached-boundary, or public API claim.

**Tracked adjacent selected-tool finding:** the common worker now contains a
direct child even after that child creates a new session, but
`FSM::VIAL::Backend::ProcessSupervisor` remains a distinct exec boundary. Its
normal-exit and timeout paths test and terminate only the original
negative-PID process group. A selected-tool descendant that calls `setsid`
would leave that domain before the tool leader exits. The next `.17.4.7` slice
must supply an executable detached selected-tool RED, prove result/cleanup
behavior through the shared Verilator/GHDL supervisor contract, and repair the
supervisor before returning to any other admission audit.

## Acceptance Checklist (enforced) — `.17.4.7` detached selected-tool descendant containment

**In-slice signoff extension:** the inherited writer is an untrusted selected-tool
descriptor, so the completion proof must remain cleanup-safe if a descendant
writes to it. The focused watcher must make that case executable before this
leaf commits; pipe payload may invalidate success, but it may not short-circuit
exact holder containment.

- [x] **ROOT CAUSE (WHY + WHERE)** — the host-authorized t1755 RED crossed the
  real supervisor fork/exec boundary. Its selected-tool leader forked a child
  that called `setsid`, closed captured stdout/stderr, published its detached
  PID/group, returned zero, and let the child recreate staging after simulated
  lifecycle cleanup. The pre-repair supervisor returned accepted success, left
  the PID alive, and admitted the late marker: four of five assertions failed
  at t/1755-vial-selected-tool-detached-descendant-containment.t line 70,
  line 73, line 74, and line 80; exact fixture teardown passed. The first
  parentage-sampling repair passed a sustained-child control but failed the
  signoff zero-dwell extension in both normal-exit policies at the later line
  98/107/108/114 assertions: two of four top-level subtests failed while both
  timeout controls passed. This proved that interval sampling cannot itself
  authenticate a child that forks, changes session, and loses its leader
  between observations. The signoff payload extension then wrote through the
  inherited writer: both normal cases again left the child alive and admitted
  the late marker at the final line 108/114 assertions, while both timeout
  cases lost their primary result at line 104. All four top-level cases failed
  because the reader raised before exact-holder cleanup.
- [x] **ADDRESSED (verified)** — both admitted supervisor policies now sample a
  bounded PID/PPID/start-time tree while the selected leader is live and retain
  recorded observed identities. Independently, one hidden containment-pipe writer
  is deliberately inherited across exec; leader exit authorizes return only at
  EOF. If a zero-dwell descendant retains that writer, Darwin resolves exact
  current-user holders through the writer endpoint's `lsof` identity and Linux
  through the pipe inode under `/proc/*/fd`; holder discovery runs only on the
  residue path. The reader drains structurally bounded untrusted payload while
  preserving EOF/live-writer meaning, so payload cannot bypass holder cleanup.
  Exact holders are stopped, killed, and required absent before return.
  `lifecycle_process_group` additionally owns whole-group TERM/KILL;
  `outer_worker_process_group` never kills its borrowed group and uses only the
  exact detached-PID layers. Normal exit reports
  `VIAL_PROCESS_RESIDUE_ERROR`; timeout remains the primary returned result only
  after all owned domains are absent. Final t1755 passes four top-level/four
  five-assertion cases covering normal exit and timeout under both policies,
  including zero dwell, closed stdout/stderr, pre-return PID absence, no late
  staging mutation, and exact fixture teardown.
- [x] **NO REGRESSION** — product/test syntax and `git diff --check` are clean.
  The default-guarded capture-limit, shared Verilator lifecycle, shared and
  provider-aware GHDL lifecycles, injected runtime-process envelope, and t1755
  collection passes `Files=6, Tests=52` in 28 wallclock seconds. Existing
  exec-control, same-group TERM/KILL, output limit, timeout, signal, lifecycle
  phase attribution, both containment labels, and exact cleanup assertions stay
  green. All 58 mdBook chapters test; the inspected 93-file/20,440-KiB local
  render contains the exact contract and command and is removed. Knowledge Map
  parity is 1,159 facts / 6,212 questions / 6,384 answer occurrences / 138
  shards. Claim inventory independently agrees at 11,403 numeric lines and
  1,711 candidates; 27 registry records plus 179 claim-record, 939 gate, and
  593 reviewed dispositions retain zero gaps/open. Maintained-book authority
  is exact at 58 files / 54,414 lines / 2,939,445 bytes; the card transition
  admits 1,158 files / 46,837 lines / 3,458,145 bytes; all 22 live-document
  surfaces pass with zero ceiling increases. Staged acceptance and every
  registered doctrine are required green immediately before commit. The repair
  changes no selected command, lifecycle phase, deadline, output cap, artifact
  graph, provider/support, performance, capacity, reached-boundary, or public
  API claim.

**Resolved descriptor-escape boundary:** the non-sampled proof depends on the
selected tool and its descendants retaining the supervisor-owned hidden writer
they inherit. The exact `closefrom`-style control below proves that a zero-dwell
child can cross writer, sampling, and process-group evidence together. Because
the admitted selected tools are synchronous caller-sealed profiles rather than
arbitrary daemons, this slice narrows that contract explicitly; polling faster
is not an admissible substitute for kernel containment.

## Acceptance Checklist (enforced) — `.17.4.7` explicit selected-tool descriptor closure

- [x] **ROOT CAUSE (WHY + WHERE)** — the extended t1755 control ran a
  zero-dwell child that closes every inherited nonstandard descriptor before
  `setsid`. Both explicit-close normal-exit cases accepted the zero-exit leader,
  left the detached PID alive, and admitted its late staging mutation: four of
  five assertions failed; Prove's first concrete diagnostic was `Failed test
  at t/1755-vial-selected-tool-detached-descendant-containment.t line 101`,
  followed by line 110, line 111, and line 117 under each containment policy,
  while exact fixture cleanup passed. The retained
  writer normal/timeout matrix remained green; overall, two of six top-level
  subtests failed in 14 wallclock seconds. The required macOS SDK
  `sys/event.h` was inspected read-only through the system toolchain: its
  current contract says `NOTE_TRACK` child following has been unsupported since
  macOS 10.5, while `NOTE_FORK` reports only that a fork occurred and does not
  deliver the child PID. `EVFILT_PROC` is therefore not sufficient kernel
  authority for exact detached-child cleanup.
- [x] **ADDRESSED (verified)** — the supported contract is now explicitly
  narrow: `ProcessSupervisor->capture` remains caller-sealed to the exact
  GHDL/Verilator lifecycle and qualification classes, whose command validators
  admit synchronous qualified profiles rather than arbitrary daemon commands.
  The mdBook and canonical Knowledge Map card now state that group, recorded
  process-tree, and inherited-writer containment is not a generic job object;
  deliberate close-all-plus-detach behavior is unsupported and must not be
  selected. Any future daemonizing profile requires a supported
  non-cooperative host authority before admission. Faster polling and
  unconditional inherited-descriptor claims are explicitly rejected.
- [x] **NO REGRESSION** — the executable close-descriptor falsification is
  recorded above; the shipped watcher remains the supported retained-writer
  normal/timeout matrix rather than canonizing unsafe behavior. The
  default-guarded capture-limit, exact Verilator/GHDL lifecycle and caller-seal
  controls, runtime-process envelope, and t1755 pass `Files=6, Tests=52` in 28
  wallclock seconds. All 58 mdBook chapters test; the inspected
  93-file/20,444-KiB render contains the narrowed contract and is removed.
  Knowledge Map parity is 1,159 facts / 6,213 questions / 6,385 answer
  occurrences / 138 shards. Claim inventory independently agrees at 11,403
  numeric lines and 1,711 candidates; 27 registry records plus 179 claim-record,
  939 gate, and 593 reviewed dispositions retain zero gaps/open.
  Maintained-book authority is exact at 58 files / 54,424 lines / 2,940,120
  bytes; the card transition admits 1,158 files / 46,848 lines / 3,458,904
  bytes. All 22 live-document surfaces, staged acceptance, and every registered
  doctrine are required green immediately before commit, with zero ceiling
  increases. Final source and executable test bytes remain identical to the
  preceding detached-selected-tool commit; this slice corrects the supported
  contract rather than weakening the implemented retained-writer containment.

**Tracked adjacent host-observer liveness audit:** the new `ps` and `lsof`
censuses are structurally bounded by rows and bytes, but their subprocess
completion is not yet bounded by monotonic elapsed time. A stalled host helper
could therefore suspend the selected-tool deadline while supervision waits for
observation. After the descriptor-escape control, `.17.4.7` must inject a
non-terminating observer, prove the deadline failure, and give observer startup,
read, termination, and reap their own bounded containment path.

## Acceptance Checklist (enforced) — `.17.4.7` bounded selected-tool host observers

- [x] **ROOT CAUSE (WHY + WHERE)** — t1756 replaced `ps` and `lsof`
  independently through a repository-local PATH fixture with a non-terminating
  helper and ran `_capture` inside an isolated process group. Both helpers
  outlived the seven-second outer watchdog. Prove emitted
  `Failed test at t/1756-vial-selected-tool-host-observer-deadline.t line 92`
  for bounded return and line 104 for the missing explicit failure under each
  observer.
  The watchdog then terminated each exact group; probe/fixture cleanup passed.
  Overall, both of two top-level subtests failed in 14 wallclock seconds.
- [x] **ADDRESSED (verified)** — every exact `ps`/`lsof` helper now runs through
  an owned pipe/fork/exec path with nonblocking structurally bounded output,
  explicit monotonic completion, exact-PID TERM/KILL, and bounded reap. Setup
  authentication has its own one-second deadline, live observations consume
  the selected-tool deadline rather than extending it, and timeout/residue
  cleanup receives a fresh two-second observer deadline. Each helper remains
  inside the supervisor's existing containment domain so an outer-worker kill
  cannot strand a freshly detached helper group. A failed setup authentication
  closes all eight pre-fork pipe handles before returning the explicit host
  error. The repaired t1756 returns the exact host/residue failure for both
  injected stalls inside five wallclock seconds and proves no helper group
  residue remains.
- [x] **NO REGRESSION** — the focused injected-stall proof passes both top-level
  subtests and all ten inner assertions in five wallclock seconds, including
  explicit host/residue failures, clean probe exit, exact fixture deletion,
  and no helper-group residue. The final RAM-guarded capture-limit, exact
  Verilator/GHDL lifecycle, provider-aware GHDL, runtime-process envelope,
  retained-writer containment, and t1756 collection passes `Files=7, Tests=54`
  in 33 wallclock seconds. All 58 mdBook chapters test; the inspected
  93-file/20,452-KiB repository-local render contains the executable t1756
  command and bounded-observer contract and is removed. Knowledge Map parity
  is 1,159 facts / 6,215 questions / 6,387 answer occurrences / 138 shards.
  Claim verification retains 27 records and closes all 1,711 candidates
  through 179 claim-record, 939 gate, and 593 reviewed dispositions with zero
  gaps/open; the independent inventory census agrees at 11,404 numeric lines.
  Maintained-book authority is exact at 58 files / 54,439 lines / 2,940,898
  bytes; the existing Knowledge-card transition contains 1,158 files / 46,861
  lines / 3,459,740 bytes. All 22 live-document surfaces pass with zero ceiling
  increases. Staged acceptance and every registered doctrine are required
  green immediately before commit.

**Tracked adjacent monotonic-containment finding:** selected-tool execution and
host-observer deadlines use `CLOCK_MONOTONIC`, but `_terminate_process`,
`_terminate_residual_group`, containment-holder absence, and observed-descendant
absence still bound their TERM/KILL loops with adjustable wall time. A backward
wall-clock step can prolong containment beyond its declared interval; a forward
step can truncate the intended grace period. The next `.17.4.7` slice must
inject a wall-time discontinuity, prove the split clock domain, and put every
selected-tool containment deadline on one monotonic authority without changing
the admitted timeout or cleanup intervals.

## Acceptance Checklist (enforced) — `.17.4.7` monotonic selected-tool containment

- [x] **ROOT CAUSE (WHY + WHERE)** — t1757 injected backward and forward
  replacements for the imported `Time::HiRes::time` while independently timing
  `_terminate_process` with `CLOCK_MONOTONIC`. The backward step exceeded the
  seven-second outer watchdog
  (`Failed test at t/1757-vial-selected-tool-monotonic-containment.t line 98`)
  and returned no result. The forward step returned immediately with `F`,
  failed the grace assertion at line 107, and made its probe exit nonzero at
  line 109. Both of two top-level subtests failed in seven wallclock seconds,
  while exact watchdog cleanup and both process-group absence controls passed.
  Source census located the same adjustable-wall-time comparisons in
  `_terminate_process`, `_terminate_residual_group`, containment-holder
  absence, and observed-descendant absence.
- [x] **ADDRESSED (verified)** — every selected-tool TERM/KILL grace and
  descendant/holder absence loop now derives and compares its deadline through
  `clock_gettime(CLOCK_MONOTONIC)`; the adjustable `time` import and all
  `time()` comparisons are absent. Existing intervals, exact PID/group
  identities, escalation order, wait status, and residue-error precedence are
  unchanged. The repaired t1757 completes both injected discontinuities in
  four wallclock seconds, preserves the monotonic TERM grace, contains the
  exact tool, proves the fake wall clock was called zero times, and leaves no
  process-group residue.
- [x] **NO REGRESSION** — the strengthened discontinuity proof passes both
  top-level subtests and all eight inner assertions at `Files=1, Tests=2` in
  four wallclock seconds, including zero calls to the injected wall clock and
  exact group absence. The final RAM-guarded capture-limit, exact
  Verilator/GHDL lifecycle, provider-aware GHDL, runtime-process envelope,
  retained-writer, stalled-observer, and monotonic-containment collection
  passes `Files=8, Tests=56` in 38 wallclock seconds. All 58 mdBook chapters
  test; the inspected 93-file/20,452-KiB repository-local render contains the
  executable t1757 command and is removed. Knowledge Map parity is 1,159 facts
  / 6,217 questions / 6,389 answer occurrences / 138 shards. Claim
  verification retains 27 records and closes all 1,711 candidates through 179
  claim-record, 939 gate, and 593 reviewed dispositions with zero gaps/open;
  the independent inventory agrees at 11,405 numeric lines. Maintained-book
  authority is exact at 58 files / 54,451 lines / 2,941,432 bytes; the existing
  Knowledge-card transition contains 1,158 files / 46,872 lines / 3,460,419
  bytes. All 22 live-document surfaces pass with zero ceiling increases.
  Staged acceptance and every registered doctrine are required green
  immediately before commit.

**Tracked adjacent blocking-reap finding:** `_terminate_process` now bounds all
TERM/KILL decisions monotonically, but after SIGKILL its sole remaining
`waitpid($pid, 0)` can still block supervision on kernel reap completion. The
host-observer path already uses bounded `WNOHANG` reap, so the contracts are
inconsistent. The next `.17.4.7` slice must inject a non-completing selected-tool
reap, prove whether timeout can still be suspended, and make exact-leader reap
bounded without weakening process-group absence or wait-status authority.

## Acceptance Checklist (enforced) — `.17.4.7` bounded selected-tool leader reap

- [x] **ROOT CAUSE (WHY + WHERE)** — t1758 installed a compile-time
  `CORE::GLOBAL::waitpid` injection that delegates every operation except the
  exact selected-tool leader's blocking post-SIGKILL wait. `_terminate_process`
  completed its TERM grace and issued SIGKILL, then the injected wait suspended
  past the seven-second outer watchdog. Prove emitted
  `Failed test at t/1758-vial-selected-tool-bounded-leader-reap.t line 95` for
  bounded return and line 103 for the missing status result; one of one
  top-level subtests failed in eight wallclock seconds. Exact watchdog cleanup
  and process-group absence passed, isolating the unbounded `waitpid($pid, 0)`
  rather than signal delivery or group containment.
- [x] **ADDRESSED (verified)** — the sole blocking selected-tool
  `waitpid($pid, 0)` is absent. After SIGKILL, `_terminate_process` polls the
  exact owned leader with `WNOHANG` under a fresh monotonic two-second reap
  deadline, retains the exact wait status on success, and records an unreaped
  leader without skipping the existing bounded process-group absence check.
  Only after that domain check may it raise the explicit residue failure. The
  repaired t1758 returns in two wallclock seconds, proves the injected blocking
  wait was called zero times, preserves signal-nine status, exits cleanly, and
  leaves no process-group residue.
- [x] **NO REGRESSION** — the strengthened blocking-reap injection passes its
  top-level subtest and all four inner assertions at `Files=1, Tests=1` in two
  wallclock seconds, including exact signal status, zero blocking-wait calls,
  clean probe exit, and group absence. The final RAM-guarded capture-limit,
  exact Verilator/GHDL lifecycle, provider-aware GHDL, runtime-process
  envelope, retained-writer, stalled-observer, monotonic-clock, and
  bounded-reap collection passes `Files=9, Tests=57` in 40 wallclock seconds.
  All 58 mdBook chapters test; the inspected 93-file/20,456-KiB
  repository-local render contains the executable t1758 command and is
  removed. Knowledge Map parity is 1,159 facts / 6,219 questions / 6,391
  answer occurrences / 138 shards. Claim verification retains 27 records and
  closes all 1,711 candidates through 179 claim-record, 939 gate, and 593
  reviewed dispositions with zero gaps/open; the independent inventory agrees
  at 11,406 numeric lines. Maintained-book authority is exact at 58 files /
  54,463 lines / 2,941,965 bytes; the existing Knowledge-card transition
  contains 1,158 files / 46,883 lines / 3,461,085 bytes. All 22 live-document
  surfaces pass with zero ceiling increases. Staged acceptance and every
  registered doctrine are required green immediately before commit.

**Tracked adjacent interrupted-wait finding:** every selected-tool and host
observer `waitpid(..., WNOHANG)` path currently treats `-1` as completed. That
conflates `ECHILD` with `EINTR`; in `_terminate_process`, one interrupted poll
can mark an ignoring leader reaped, suppress exact-PID liveness, and return
before TERM/KILL containment. The next `.17.4.7` slice must inject `EINTR` at
each wait phase, prove the live-leader escape, retry interruptions, and retain
the existing no-child, exact-status, deadline, and residue semantics.

## Acceptance Checklist (enforced) — `.17.4.7` interrupted owned-child polls

- [x] **ROOT CAUSE (WHY + WHERE)** — t1759 injects `EINTR` independently into
  the selected-tool exit poll, selected-tool TERM poll, selected-tool
  post-KILL reap poll, host-observer cleanup poll, and bounded host-command
  poll. The first four containment/helper controls each returned `F`, exited
  nonzero, and failed exact-completion assertions while their watchdog and
  group-residue controls passed. After correcting the exit-poll selector, a
  controlled restoration of only that old call site injected exactly once and
  changed a real `exit 42` into admitted `exit_code=0`; only the exit-poll
  exact-completion and clean-probe assertions failed. Its diagnostic was
  `Failed test at t/1759-vial-selected-tool-interrupted-wait.t line 226` while
  the other four repaired phases stayed green. This isolates false
  `-1/EINTR` completion rather than child behavior, signaling, deadline, or
  cleanup.
- [x] **ADDRESSED (verified)** — all five nonblocking owned-child wait sites
  call `_poll_owned_child`. It performs exactly one `waitpid(..., WNOHANG)`;
  `EINTR` returns pending to the enclosing monotonic loop, while exact PID and
  existing genuine-no-child results retain their captured wait/no-child
  semantics. There is no internal retry loop that can hide the caller's
  deadline. The final focused t1759 passes all five top-level subtests and 20
  inner assertions in five wallclock seconds, preserving `exit 42`,
  signal-nine status, explicit helper-command failure, clean probe exits, and
  zero process-group residue.
- [x] **NO REGRESSION** — the final focused injection proof passes five
  top-level subtests and all 20 inner assertions in five wallclock seconds.
  The RAM-guarded capture-limit, exact Verilator/GHDL lifecycle,
  provider-aware GHDL, runtime-process envelope, retained-writer,
  stalled-observer, monotonic-clock, bounded-reap, and interrupted-wait
  collection passes `Files=10, Tests=62` in 46 wallclock seconds. All 58
  mdBook chapters test; the inspected 93-file/20,460-KiB repository-local
  render contains the executable t1759 command and `exit 42` falsification and
  is removed exactly. Knowledge Map parity is 1,159 facts / 6,222 questions /
  6,394 answer occurrences / 138 shards. Claim verification retains 27
  records and closes all 1,711 candidates through 179 claim-record, 939 gate,
  and 593 reviewed dispositions with zero gaps/open; the independent inventory
  agrees at 11,408 numeric lines. Maintained-book authority is exact at 58
  files / 54,484 lines / 2,943,098 bytes; the Knowledge-card transition is
  exact at 1,158 files / 46,900 lines / 3,462,178 bytes. All 22 live-document
  surfaces pass with zero ceiling increases. Staged acceptance and every
  registered doctrine are required green immediately before commit.

**Tracked adjacent interrupted-read finding:** `_bounded_host_command` checks
its monotonic deadline only after the inner nonblocking `sysread` loop yields,
but that inner loop immediately retries `EINTR` without progress or a deadline
check. A sustained interruption stream can therefore suspend `ps`/`lsof`
observation beyond the bound that t1756 established. The next `.17.4.7` slice
must inject repeated `EINTR`, prove the deadline escape under an outer
watchdog, and return interrupted reads to the enclosing deadline authority
without weakening bounded output, exact helper cleanup, or diagnostics.

## Acceptance Checklist (enforced) — `.17.4.7` interrupted observer reads

- [x] **ROOT CAUSE (WHY + WHERE)** — t1760 replaces the exact bounded
  host-command `sysread` with sustained `EINTR`. The unthrottled RED first
  proved the tight retry was also resource-unbounded: the RAM guard measured
  the probe at 5,307.7 MiB RSS, stopped it at the 4,096-MiB cutoff, terminated
  all four PIDs, and a post-run process census proved zero residue. The safely
  throttled RED then exceeded the five-second outer watchdog and emitted
  `Failed test at t/1760-vial-selected-tool-interrupted-observer-read.t line 83`
  plus the missing exact-deadline result at line 91. Clean probe cleanup and
  process-group absence passed, isolating the inner `next if EINTR` rather
  than helper signaling, reap, or outer-watchdog mechanics.
- [x] **ADDRESSED (verified)** — an interrupted host-observer read now exits
  only the current inner drain attempt and returns to the existing outer loop,
  which polls the exact owned helper, checks the monotonic deadline, and sleeps
  between attempts. EAGAIN/EWOULDBLOCK, successful reads, the four-MiB output
  cap, exact diagnostic, and helper TERM/reap behavior are unchanged. The
  repaired t1760 accepts more than one injected interruption, returns the
  exact deadline error in one wallclock second, exits cleanly, and leaves no
  process-group residue.
- [x] **NO REGRESSION** — focused t1760 passes its top-level subtest and all
  four inner assertions at `Files=1, Tests=1` in one wallclock second. The
  first broader collection exposed the separately tracked load-sensitive t1755
  timeout-precedence failure; two isolated t1755 executions then passed all
  four top-level subtests in 15 and 14 wallclock seconds, and the final
  RAM-guarded capture-limit, exact Verilator/GHDL lifecycle, provider-aware
  GHDL, runtime-process envelope, retained-writer, stalled-observer,
  monotonic-clock, bounded-reap, interrupted-wait, and interrupted-read
  collection passes `Files=11, Tests=63` in 47 wallclock seconds. All 58
  mdBook chapters test; the inspected 93-file/20,464-KiB repository-local
  render contains the executable t1760 command and is removed exactly.
  Knowledge Map parity is 1,159 facts / 6,224 questions / 6,396 answer
  occurrences / 138 shards. Claim verification retains 27 records and closes
  all 1,711 candidates through 179 claim-record, 939 gate, and 593 reviewed
  dispositions with zero gaps/open; the independent inventory agrees at
  11,409 numeric lines. Maintained-book authority is exact at 58 files /
  54,499 lines / 2,943,812 bytes; the Knowledge-card transition is exact at
  1,158 files / 46,914 lines / 3,463,063 bytes. All 22 live-document surfaces
  pass with zero ceiling increases. Staged acceptance and every registered
  doctrine are required green immediately before commit.

**Resolved adjacent containment-pipe-read finding:**
`_containment_pipe_has_writer` independently retries `sysread` on `EINTR`
inside an unbounded loop and accepts no deadline parameter. That path runs
before holder attribution and again inside the two-second post-kill absence
loop, so sustained interruption suspended both residue discovery and the
declared holder-cleanup deadline. T1762 now injects both phases and the shared
reader receives the appropriate cleanup or absence deadline without changing
EOF, EAGAIN/live-writer, bounded-drain, holder-attribution, or residue branches.

**Resolved adjacent observed timeout-precedence finding:** the
first eleven-file regression collection, at a RAM-guard host reading of 80.7%,
failed only t1755's lifecycle-process-group timeout-primary assertion. Two
isolated t1755 executions and the complete eleven-file rerun were green, so the
failure was load-sensitive. Static inspection identified the mechanism:
`_capture` could begin descendant observation just before the selected-tool
deadline, then let the observer's same-deadline failure reach host-error
handling before classifying selected-tool timeout. T1761 now reproduces both
live-stream and post-EOF forms independent of host load; the repaired boundary
keeps timeout primary while its early-failure control retains host-error
authority. The queued containment-pipe interrupted-read audit resumes next.

## Acceptance Checklist (enforced) — `.17.4.7` observation-timeout precedence

- [x] **ROOT CAUSE (WHY + WHERE)** — t1761 deterministically expired the
  selected-tool deadline inside descendant observation in both live-stream and
  post-EOF phases. Both RED deadline cases returned host error `H` instead of
  timeout `T`. The RED emitted `Failed test at t/1761-vial-selected-tool-observation-timeout-precedence.t line 135`; the
  independently early observer-failure control correctly returned `H`, and all
  watchdog, clean-exit, and process-group-absence controls passed. This proves
  the load-sensitive t1755 gate mechanism without depending on host load:
  observation error handling ran before the selected-tool deadline result was
  classified.
- [x] **ADDRESSED (verified)** — both observation phases now capture the
  monotonic observation-failure timestamp before cleanup. A failure detected
  at/after the selected-tool deadline enters the existing supervised-domain
  timeout containment path and retains timeout-primary result authority; an
  independently earlier observation failure retains the exact host error and
  full domain containment. Repaired t1761 returns exact `T`, `T`, and `H`
  precedence for the live-stream deadline, post-EOF deadline, and early-error
  cases, respectively, inside their outer watchdogs with clean probe exits and
  zero process-group residue.
- [x] **NO REGRESSION** — focused t1761 passes all three top-level cases and
  their twelve inner assertions at `Files=1, Tests=3` in three wallclock
  seconds. The RAM-guarded capture-limit, exact Verilator/GHDL lifecycle,
  provider-aware GHDL, runtime-process envelope, retained-writer,
  stalled-observer, monotonic-clock, bounded-reap, interrupted-wait,
  interrupted-read, and timeout-precedence collection passes
  `Files=12, Tests=66` in 49 wallclock seconds. All 58 mdBook chapters test;
  the inspected 93-file/20,472-KiB repository-local render contains the
  executable t1761 command and is removed exactly. Knowledge Map parity is
  1,159 facts / 6,227 questions / 6,399 answer occurrences / 138 shards.
  Claim verification retains 27 records and closes all 1,711 candidates
  through 179 claim-record, 939 gate, and 593 reviewed dispositions with zero
  gaps/open; the independent inventory agrees at 11,410 numeric lines.
  Maintained-book authority is exact at 58 files / 54,514 lines / 2,944,585
  bytes; the Knowledge-card transition is exact at 1,158 files / 46,928 lines
  / 3,463,951 bytes. All 22 live-document surfaces pass with zero ceiling
  increases. Staged acceptance and every registered doctrine are required
  green immediately before commit.

## Acceptance Checklist (enforced) — `.17.4.7` interrupted containment-pipe reads

- [x] **ROOT CAUSE (WHY + WHERE)** — t1762 injects sustained `EINTR` before
  holder attribution and again after one real holder is attributed and killed.
  Both RED phases exceeded their five-second outer watchdog and emitted
  `Failed test at t/1762-vial-selected-tool-interrupted-containment-pipe-read.t line 96`; both exact-result assertions also failed at line 103. The harness
  terminated each full process group and proved zero residue, isolating the
  unbounded retry inside `_containment_pipe_has_writer` from attribution,
  holder kill, and watchdog cleanup.
- [x] **ADDRESSED (verified)** — `_containment_pipe_has_writer` now accepts and
  checks an explicit monotonic deadline before every read attempt. `EINTR`
  yields briefly and returns to that check; the pre-attribution call receives
  the caller's cleanup deadline and the post-kill call receives its existing
  two-second absence deadline. Repaired t1762 completes both phases in four
  wallclock seconds with the exact bounded observation result, the expected
  zero/one holder-attribution call split, clean probe exits, and zero
  process-group residue. EOF, EAGAIN/live-writer, structural drain, holder
  attribution, and residue classification retain their existing branches.
- [x] **NO REGRESSION** — focused t1762 passes both top-level phases and their
  eight inner assertions at `Files=1, Tests=2` in four wallclock seconds. The
  RAM-guarded capture-limit, exact Verilator/GHDL lifecycle, provider-aware
  GHDL, runtime-process envelope, retained-writer, stalled-observer,
  monotonic-clock, bounded-reap, interrupted-wait, interrupted observer-read,
  timeout-precedence, and interrupted containment-read collection passes
  `Files=13, Tests=68` in 51 wallclock seconds. All 58 mdBook chapters test;
  the inspected 93-file/20,472-KiB repository-local render contains the
  executable t1762 command and is removed exactly. Knowledge Map parity is
  1,159 facts / 6,230 questions / 6,402 answer occurrences / 138 shards.
  Claim verification retains 27 records and closes all 1,711 candidates
  through 179 claim-record, 939 gate, and 593 reviewed dispositions with zero
  gaps/open; the independent inventory agrees at 11,411 numeric lines.
  Maintained-book authority is exact at 58 files / 54,529 lines / 2,945,322
  bytes; the Knowledge-card transition is exact at 1,158 files / 46,942 lines
  / 3,464,885 bytes. All 22 live-document surfaces pass with zero ceiling
  increases. Staged acceptance and every registered doctrine are required
  green immediately before commit.

**Post-repair interrupt-path audit:** the only other explicit `EINTR` retry in
`ProcessSupervisor` is the bounded 2,048-byte child-control write performed by
the already supervised selected-tool child. It cannot suspend the supervisor:
the parent retains its monotonic selected-tool deadline and terminates that
exact child/domain. Capture reads and host-observer reads already return to
their enclosing deadline loops, and every owned-child poll now treats `EINTR`
as pending. No further independent unbounded supervisor retry is present. The
next slice must audit complete `.17.4.7` acceptance/evidence for exhaustion;
only a clean closure may activate proposed cross-family closeout `.17.4.8`.

## Acceptance Checklist (enforced) — `.17.4.7` exhaustion and durable closure

- [x] **ROOT CAUSE (WHY + WHERE)** — reconciliation found 59
  work-unit commits, 42 focused leaf tests, every appended acceptance box, the
  current book/Knowledge Map, and source interrupt-path census. The compact
  node currently stops at outer-JSON admission and names completed
  common-controller reread work as next; prove whether this is only stale
  continuity projection introduced at `05a2ebe27`: `git log -S` identifies
  that exact origin, while `rg` found no
  unchecked leaf box and Git/test/source censuses cover the later work.
- [x] **ADDRESSED (verified)** — `.17.4.7` is now `done`; a closure projection
  and acceptance census prove exhaustion; replace the stale compact
  verification/commit summary with the complete controller/process closure and
  leaves `.17.4.8` proposed until a separate clean activation commit.
- [x] **NO REGRESSION** — the complete RAM-guarded leaf reports
  `Files=42, Tests=184` in 258 wallclock seconds. Task-tree
  integrity, mdBook test/render inspection, Knowledge Map parity, claim
  verification, live-document ceilings, and all registered doctrines are green
  at commit with no code or product-behavior change.

## Acceptance Checklist (enforced) — `.17.4.8` bounded activation

- [x] **ROOT CAUSE (WHY + WHERE)** — query-first Knowledge Map inspection,
  decision `0093`'s ordered implementation, and clean closure commit
  `5583365cb` establish that `.17.4.8` is the sole remaining `.17.4` child and
  owns the independent cross-family proof after every component leaf. Exact
  `git log -S'runtime_stream_envelopes' --oneline --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` identifies selection commit
  `951720257`.
- [x] **ADDRESSED (verified)** — activate only `.17.4.8`; synchronize the live
  task/index/Memory/mdBook frontier on an evidence-inventory first slice; and
  change no product behavior, cap, publication, support statement, budget, or
  capacity claim.
- [x] **NO REGRESSION** — task-tree integrity and every mdBook chapter test are
  green; Knowledge Map query parity, claim-inventory regeneration, and all
  live-document surfaces pass with a fresh maintained-book authority and no
  ceiling increase. The canonical result is `knowledge-map: OK`; staged
  acceptance and every registered doctrine are required green immediately
  before commit. Full CI and push remain deferred by policy.

## Acceptance Checklist (enforced) — `.17.4.8` cross-family evidence inventory

- [x] **ROOT CAUSE (WHY + WHERE)** — exact
  `git log -S'runtime_stream_envelopes' --oneline --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` identifies selection commit
  `951720257`; a fresh policy/catalog/evidence census proves complete declared
  alignment but finds the runtime group still stops at the three pre-hardening
  materialization witnesses. The existing calibration manifest names publisher
  revision `b66de5ce6`, and t1684/source explicitly retain `cap_implementation`
  as a nonclaim.
- [x] **ADDRESSED (verified)** — record the independently re-derived inventory,
  its falsification and durability legs, and the exact distinction between
  measurement publication and cap-closeout proof. Select one separate
  caller-sealed consistency layer as the next implementation slice; change no
  source, test, cap, publication, behavior, support statement, budget, or
  capacity claim in this audit slice.
- [x] **NO REGRESSION** — task-tree integrity holds across 4 trees and 1,031
  nodes; all 59 mdBook chapters pass; `knowledge-map: OK` reports 1,159 facts,
  6,230 unique questions, and 6,402 answer occurrences; the claim inventory is
  regenerated with no open migration owner or untracked producer; and all 22
  live-document surfaces pass with no ceiling increase. Staged acceptance and
  every registered doctrine are required green immediately before commit. No
  behavior changed, so full CI and push remain deferred by policy.

## Acceptance Checklist (enforced) — `.17.4.8` sealed consistency foundation

- [x] **ROOT CAUSE (WHY + WHERE)** — the current
  `ArchitectureScaleCapPolicy` validates catalog membership, declared values,
  selected authorities, and undifferentiated evidence paths, but it has no
  machine field for boundary, adjacent excess, diagnostics, atomicity,
  no-tool, cleanup, or accepted identity. Its runtime group consequently still
  validates while citing only the pre-hardening materialization witnesses, and
  no separate consistency module or focused test exists. Exact
  `git log -S'runtime_stream_envelopes' --oneline --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` traces that undifferentiated
  selection to `951720257`.
- [x] **ADDRESSED (verified)** — executable RED t1763 first fails only for the
  absent module. The exact-class, no-input builder now derives the live policy
  internally; emits every group, axis, implementation leaf, and candidate
  path; assigns all seven dimensions an explicit pending record; defensively
  copies results; and rejects caller arguments, subclasses, shape drift,
  caller-promoted dimensions, mutation, or premature calibration disposition.
  It executes no product route or tool.
- [x] **NO REGRESSION** — focused t1763+t1685 reports `All tests successful`
  at Files=2/Tests=84; all 59 mdBook chapters test; task integrity and
  `knowledge-map: OK` pass; the regenerated claim inventory has no open
  migration owner or untracked producer; and all 22 live-document surfaces
  pass with zero ceiling increase after line-and-byte-neutral Knowledge Map
  containment. Staged acceptance and all registered doctrines are required
  green immediately before commit. No cap, level, accepted profile,
  publication, support statement, budget, capacity claim, or product behavior
  changes; full CI and push remain deferred by policy.

## Acceptance Checklist (enforced) — `.17.4.8` runtime-stream evidence join

- [x] **ROOT CAUSE (WHY + WHERE)** — the sealed consistency foundation leaves
  every runtime-stream dimension pending because the live policy exposes only
  three undifferentiated pre-hardening materialization witnesses. Exact
  `git log -S'runtime_stream_envelopes' --oneline --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` traces that candidate-only
  selection to `951720257`, while the completed `.17.4.7` closure proves 42
  later focused leaf tests that are not joined to any dimension.
- [x] **ADDRESSED (verified)** — independently classify all three selected
  runtime profiles and every completed `.17.4.7` leaf test across boundary,
  adjacent excess, diagnostics, atomicity, no-tool, cleanup, and accepted
  identity; seal the exact evidence paths and rationales inside the no-input
  consistency authority; reject omitted, foreign, or caller-promoted evidence;
  and keep historical calibration blocked while any other group is pending.
- [x] **NO REGRESSION** — the RAM-guarded three-profile, 42-leaf, and
  consistency collection reports `All tests successful` at Files=46/Tests=210
  in 417 wallclock seconds. Task integrity passes across 4 trees/1,031 nodes;
  all 59 mdBook chapters test, and the inspected 94-file/20,548-KiB
  repository-local render is removed exactly. `knowledge-map: OK` reports
  1,159 facts/6,231 questions/6,403 answer occurrences/138 shards. Claim
  inventory independently agrees at 11,426 numeric lines with zero open
  migration owner or untracked producer. All 22 live-document surfaces and
  the exact 59-file/54,653-line/2,951,483-byte book authority pass with zero
  ceiling increase. Staged acceptance and every registered doctrine are
  required green immediately before commit with no cap, selected level,
  accepted profile, publication, support, budget, capacity, or
  product-behavior change. Full CI and push remain deferred by policy.

## Acceptance Checklist (enforced) — `.17.4.8` backend-artifact evidence join

- [x] **ROOT CAUSE (WHY + WHERE)** — the sealed consistency report leaves
  backend_artifact_graph pending because its policy candidates do not classify
  dimension ownership: t1650 consolidates the selected profiles, t1646–t1649
  retain their exact profile boundaries/identities/cleanup, and t1716–t1719
  retain the later cap-order, atomicity, and provider-no-touch hardening. Exact
  `git log -S'backend_artifact_graph' --oneline --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` traces the undifferentiated
  policy group to its selection history.
- [x] **ADDRESSED (verified)** — independently classify the complete nine-test
  backend set across boundary, adjacent excess, diagnostics, atomicity,
  no-tool, cleanup, and accepted identity; seal exact paths and rationales in
  the no-input consistency authority; reject omission or foreign evidence;
  retain the verified runtime join; and keep calibration blocked while any
  other group remains pending.
- [x] **NO REGRESSION** — the complete nine-path backend evidence plus
  consistency and policy collection reports `All tests successful` at
  Files=11/Tests=241 in 566 wallclock seconds. Task integrity passes across
  4 trees/1,031 nodes; all 59 mdBook chapters test, and the inspected
  94-file/20,552-KiB repository-local render is removed exactly.
  `knowledge-map: OK` reports 1,159 facts/6,231 questions/6,403 answer
  occurrences/138 shards. Claim inventory independently agrees at 11,438
  numeric lines with zero open migration owner or untracked producer. All 22
  live-document surfaces and the exact 59-file/54,673-line/2,952,444-byte
  book authority pass with zero ceiling increase. Staged acceptance and every
  registered doctrine are required green immediately before commit with no cap, level,
  accepted profile, provider boundary, product behavior, publication, support,
  budget, or capacity change. Full CI and push remain deferred by policy.

## Acceptance Checklist (enforced) — `.17.4.8` checking-model evidence join

- [x] **ROOT CAUSE (WHY + WHERE)** — the sealed consistency report leaves
  checking_models pending because its two policy witnesses remain
  undifferentiated candidates: t1630 owns both exact checking-model boundaries,
  their adjacent excess, provider-free state oracle, identities, and cleanup;
  t1711 independently owns compact-preflight ordering and absence of partial
  ExecutionIR or plan. Exact `git log -S'checking_models' --oneline --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` traces that candidate-only group
  to `951720257`.
- [x] **ADDRESSED (verified)** — independently classify both checking-model
  witnesses across boundary, adjacent excess, diagnostics, atomicity,
  no-tool, cleanup, and accepted identity; run t1630's exact qualification and
  limit ladder under the RAM guard; seal exact paths and rationales in the
  no-input consistency authority; reject omitted or foreign evidence; retain
  the verified runtime/backend joins; and keep calibration blocked while any
  other group remains pending.
- [x] **NO REGRESSION** — the exact checking-model evidence plus consistency
  and policy collection reports `All tests successful` at Files=4/Tests=104 in
  100 wallclock seconds. Task integrity passes across 4 trees/1,031 nodes; all
  59 mdBook chapters test, and the inspected 94-file/20,552-KiB
  repository-local render is removed exactly. `knowledge-map: OK` reports
  1,159 facts/6,231 questions/6,403 answer occurrences/138 shards. Claim
  inventory independently agrees at 11,444 numeric lines with zero open
  migration owner or untracked producer. All 22 live-document surfaces and the
  exact 59-file/54,686-line/2,952,881-byte book authority pass with zero ceiling
  increase. Staged acceptance and every registered doctrine are required green
  immediately before commit with no cap, level,
  accepted profile, product behavior, publication, support, budget, or capacity
  change. Full CI and push remain deferred by policy.

## Acceptance Checklist (enforced) — `.17.4.8` checking-randomness evidence join

- [x] **ROOT CAUSE (WHY + WHERE)** — the sealed consistency report leaves
  checking_randomness pending because its two policy witnesses remain
  undifferentiated candidates. Unlike admitted model/fault limits, t1634 proves
  the nominal 65,536-occurrence component cap is preflight-dominated by the
  serialized-plan ceiling while the real selected route admits 8,440 and
  rejects 8,441; it also owns replay identity, mutation defenses, and cleanup.
  T1715 independently owns 65,537-occurrence compact-preflight ordering and no
  partial ExecutionIR or plan. Exact `git log -S'checking_randomness' --oneline
  -- perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` traces that candidate-only
  group to `951720257`.
- [x] **ADDRESSED (verified)** — independently classify both randomness
  witnesses across boundary/preflight dominance, adjacent excess, diagnostics,
  atomicity, no-tool, cleanup, and accepted identity; run t1634's exact
  high-count and route-boundary cases under the RAM guard; seal exact paths and
  honest rationales in the no-input consistency authority; reject omitted or
  foreign evidence; retain all prior verified joins; compact the Knowledge Map
  card under its inherited transition allowance; and keep calibration blocked
  while any other group remains pending.
- [x] **NO REGRESSION** — the exact checking-randomness evidence plus
  consistency and policy collection reports `All tests successful` at
  Files=4/Tests=98 in 411 wallclock seconds. Task integrity passes across 4
  trees/1,031 nodes; all 59 mdBook chapters test, and the inspected
  94-file/20,560-KiB repository-local render is removed exactly.
  `knowledge-map: OK` reports 1,159 facts/6,231 questions/6,403 answer
  occurrences/138 shards. Claim inventory independently agrees at 11,457
  numeric lines with 1,711/1,711 candidates dispositioned and zero open owner
  or untracked producer. All 22 live-document surfaces and the exact
  59-file/54,713-line/2,954,145-byte book authority pass with zero ceiling
  increase; the compacted Knowledge Map cards are 36 lines/2,084 bytes smaller
  than the prior commit. Staged acceptance and every registered doctrine are
  required green immediately before commit with no cap,
  route boundary, level, accepted profile, product behavior, publication,
  support, budget, or capacity change. Full CI and push remain deferred by
  policy.

## Acceptance Checklist (enforced) — `.17.4.8` checking-fault evidence join

- [x] **ROOT CAUSE (WHY + WHERE)** — the sealed consistency report leaves
  checking_faults pending because its two policy witnesses remain
  undifferentiated candidates: t1633 owns the exact fault boundary, adjacent
  excess, provider-free lifecycle oracle, mutation defenses, identities, and
  cleanup; t1714 independently owns compact-preflight ordering and absence of
  partial ExecutionIR or plan. Exact `git log -S'checking_faults' --oneline --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` traces that candidate-only group
  to `951720257`.
- [x] **ADDRESSED (verified)** — independently classify both checking-fault
  witnesses across boundary, adjacent excess, diagnostics, atomicity, no-tool,
  cleanup, and accepted identity; run t1633's exact qualification and limit
  ladder under the RAM guard; seal exact paths and rationales in the no-input
  consistency authority; reject omitted or foreign evidence; retain all prior
  verified joins; and keep calibration blocked while any other group remains
  pending.
- [x] **NO REGRESSION** — the exact checking-fault evidence plus consistency
  and policy collection reports `All tests successful` at Files=4/Tests=98 in
  21 wallclock seconds. Task integrity passes across 4 trees/1,031 nodes; all
  59 mdBook chapters test, and the inspected 94-file/20,556-KiB
  repository-local render is removed exactly. `knowledge-map: OK` reports
  1,159 facts/6,231 questions/6,403 answer occurrences/138 shards. Claim
  inventory independently agrees at 11,451 numeric lines with zero open
  migration owner or untracked producer. All 22 live-document surfaces and the
  exact 59-file/54,699-line/2,953,478-byte book authority pass with zero ceiling
  increase. Staged acceptance and every registered doctrine are required green
  immediately before commit with no cap, level,
  accepted profile, product behavior, publication, support, budget, or capacity
  change. Full CI and push remain deferred by policy.

## Acceptance Checklist (enforced) — `.17.4.8` checking-scoreboard evidence join

- [x] **ROOT CAUSE (WHY + WHERE)** — the sealed consistency report leaves
  `checking_scoreboards` pending because its three policy witnesses remain
  undifferentiated candidates: t1631 owns both checking-scoreboard axes,
  exact provider-free FIFO-oracle limits, adjacent excesses, diagnostics,
  mutation defenses, identities, and same-volume cleanup; t1690 independently
  owns semantic scalar boundary/excess order and atomic failure; t1712 owns
  compact execution preflight, normalization avoidance, and absence of partial
  ExecutionIR or plan. Exact `git log -S'checking_scoreboards' --oneline --
  perl/FSM/VIAL/ArchitectureScaleCapPolicy.pm` traces that candidate-only group
  to `951720257`.
- [x] **ADDRESSED (verified)** — independently classify all three scoreboard
  witnesses across boundary, adjacent excess, diagnostics, atomicity, no-tool,
  cleanup, and accepted identity; run t1631's exact qualification and limit
  ladder under the repository-local RAM guard; seal exact paths and rationales
  in the no-input consistency authority; reject omitted or foreign evidence;
  retain all prior verified joins; and keep calibration blocked while any
  other group remains pending. The pre-implementation t1763 RED reports the
  exact 21 missing status/evidence/rationale assertions and no unrelated
  failure; the sealed projection plus omission/foreign controls then pass.
- [x] **NO REGRESSION** — the exact three-witness scoreboard evidence plus
  consistency and policy collection reports `All tests successful` at
  Files=5/Tests=119 in 23 wallclock seconds. Task integrity passes across 4
  trees/1,031 nodes; all 59 mdBook chapters test, and the inspected
  94-file/20,564-KiB repository-local render is removed exactly.
  `knowledge-map: OK` reports 1,159 facts/6,231 questions/6,403 answer
  occurrences/138 shards. Claim inventory independently agrees at 11,467
  numeric lines with 1,711/1,711 candidates dispositioned and zero open owner
  or untracked producer. All 22 live-document surfaces and the exact
  59-file/54,731-line/2,955,108-byte book authority pass with zero ceiling
  increase; Knowledge Map cards retain 37 lines/1,957 bytes of transition
  headroom. Staged acceptance and every registered doctrine are required green
  immediately before commit with no cap, level, accepted profile, product
  behavior, publication, support, budget, or capacity claim change. Full CI
  and push remain deferred by policy.
