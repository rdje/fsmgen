---
id: hial-vial-verification-fixture-architecture
title: VIAL uses one public source, two private IRs, and a versioned HIAL bridge
answers:
  - "what do HIAL and VIAL mean in FSMGen?"
  - "does FSMGen plan a Verification IAL?"
  - "where is powerful verification fixture generation tracked?"
  - "should HIAL lower to SystemVerilog and VHDL?"
  - "should VIAL lower to SV UVM and VHDL verification code?"
  - "will VIAL have VIAL0 VIAL1 and VIAL2 layers?"
  - "what is VIALSemanticIR?"
  - "what is VIALExecutionIR?"
  - "what is HIALVIALBridgeManifest?"
  - "how do HIAL designs connect to VIAL fixtures?"
  - "how can VIAL use native SV UVM or VHDL power?"
  - "how is portable VIAL backend parity judged?"
  - "what are VIAL drive sample react check phases?"
  - "what is the first runnable VIAL backend?"
  - "is Verilator enough to validate full SystemVerilog and UVM VIAL output?"
  - "what simulator capability profiles does VIAL require?"
  - "is Verilator a traditional event-driven simulator?"
  - "does Verilator support events with timing enabled?"
  - "is the HIAL VIAL architecture selected now?"
  - "what is the next HIAL VIAL task?"
  - "which UVM revision does native VIAL target?"
  - "will FSMGen require Xcelium VCS or Questa for UVM?"
  - "what is sv_uvm_emit.accellera_2020_3_1?"
  - "what native UVM foundation has FSMGen emitted?"
  - "what native UVM topology lifecycle and notification structures has FSMGen emitted?"
  - "what native UVM stimulus and service structures has FSMGen emitted?"
  - "what native UVM coverage model scoreboard and fault structures has FSMGen emitted?"
  - "does native UVM result collection mean a result was produced?"
  - "how are short known scalar notification predicates emitted?"
  - "does generated native UVM rerandomize portable VIAL decisions?"
  - "are RAL and factory overrides publicly authored VIAL?"
  - "who owns objections in generated VIAL UVM?"
  - "how are generated VIAL UVM interceptors ordered?"
  - "how does generated VIAL UVM handle recursive notifications?"
  - "are native VIAL interceptor tables publicly authorable?"
  - "where is the native UVM review gallery?"
  - "what does the native UVM selected mapping matrix contain?"
  - "how do I regenerate or check the native UVM review gallery?"
  - "has the native VIAL UVM gallery been parsed or compiled?"
  - "how will PGEN and NEXSIM qualify VIAL UVM runtime?"
  - "what can FSMGen do with NEXSIM semantic introspection through MCP?"
  - "how will NEXSIM MCP help compare IASIM and generated UVM?"
  - "does NEXSIM semantic introspection define VIAL meaning?"
  - "can Verilator currently qualify full VIAL UVM support?"
  - "can FSMGen generate full UVM before a full simulator exists?"
  - "can Verilator compile or elaborate early generated UVM?"
  - "what exact open-source native UVM probe has FSMGen run?"
  - "did Verilator compile and run the selected UVM library?"
  - "did Verilator parse the complete generated VIAL UVM fixture?"
  - "what native UVM generator defect did the experimental probe find?"
  - "does the native UVM experimental probe advertise product support?"
  - "how do I rerun the native UVM experimental probe?"
  - "may generated UVM syntax change while VIAL meaning stays stable?"
  - "has FSMGen started emitting native VIAL VHDL?"
  - "what portable VHDL semantics does vhdl_portable_ghdl emit?"
  - "how does portable VHDL preserve original std_logic symbols?"
  - "what is the portable VHDL inactive-edge scheduler?"
  - "how are VIAL scenarios fibers and models emitted in VHDL?"
  - "how are declared HIAL probes accessed from portable VHDL?"
  - "does portable VIAL VHDL emit scoreboards coverage faults and checks?"
  - "does portable VIAL VHDL emit a closed trace and normalized result projection?"
  - "where is the portable VHDL review gallery?"
  - "how do I regenerate or check the portable VHDL review gallery?"
  - "what does the portable VHDL selected mapping matrix contain?"
  - "how are portable VHDL review defects tracked?"
  - "how does portable VHDL prove legacy and HIAL separation?"
  - "is portable VHDL visually reviewed or qualified?"
  - "has the generated VIAL VHDL been analyzed or run?"
  - "is a mixed-language HIAL VIAL simulator available?"
  - "why is mixed-language qualification not active?"
  - "which exact GHDL 6.0.0 backend is qualified?"
  - "how do I rerun the exact portable VHDL GHDL qualification?"
  - "why is GHDL LLVM AOT not qualified for portable VIAL?"
  - "does portable VIAL VHDL consume the legacy observation package?"
  - "is exact OSVVM 2026.05 installed for FSMGen?"
  - "how is the recursive OSVVM provider identity verified?"
  - "where is the OSVVM VHDL adapter gallery?"
  - "has OSVVM 2026.05 plus GHDL 6.0.0 been qualified?"
  - "what is IASIM?"
  - "should FSMGen simulate Intent Abstraction directly?"
  - "can IASIM replace an HDL simulator?"
  - "how would IASIM combine HIAL and VIAL?"
  - "what should IASIM execute?"
  - "how does IASIM avoid common-mode code generation bugs?"
  - "is IASIM constrained by HDL?"
  - "can IASIM run without generating HDL?"
  - "how can IASIM be signoff accurate?"
  - "what does xIAL mean?"
  - "what is the xIAL native development framework?"
  - "is IASIM only a simulator command?"
  - "can all design and verification work happen at xIAL level?"
  - "what ecosystem should surround IASIM?"
  - "how does the xIAL framework relate to IASIM?"
  - "what language should implement IASIM?"
  - "is Perl 5 fast enough for IASIM?"
  - "does IASIM need to be rewritten in Rust?"
  - "how may Rust accelerate IASIM?"
  - "does xIAL intent signoff replace physical design signoff?"
  - "is HDL export optional in the xIAL framework?"
  - "how is xIAL to HDL export signed off?"
  - "must published xIAL HDL meet HDL standards?"
  - "how will VIAL architecture scalability be proved?"
  - "what are the VIAL scale workload families?"
  - "are VIAL scale gate and qualification candidates supported capacity?"
  - "how are VIAL scale performance budgets selected?"
  - "does VIAL architecture scale prove whole product big and really big designs?"
date: 2026-08-10
status: current
tags: [hial, vial, ial0, ial1, ial2, verification, semantic-ir, execution-ir, bridge, sv-uvm, vhdl, verilator, simulator-profile, architecture, scalability, task-tree]
evidence: >-
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md; docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md; docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md; perl/FSM/VIAL/Backend/SVPortableVerilator.pm; perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/Parity/AHBBaseOutput.pm; t/1557-vial-portable-sv-backend-emission.t; t/1559-vial-ahb-runtime-parity.t;
  docs/decisions/0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md; docs/decisions/0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md; docs/decisions/0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md;
  docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md; docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md; docs/decisions/0039-vial-public-tooling-is-intent-oriented-and-artifact-atomic.md; docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md; docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm; perl/FSM/VIAL/Backend/SVUVMStaticValidator.pm; perl/FSM/VIAL/Backend/SVUVMReviewClosure.pm; perl/FSM/VIAL/Backend/SVUVMExperimentalProbe.pm; perl/FSM/Support/VIALNativeUVMEmissionContract.pm; scripts/refresh_vial_native_uvm_gallery.pl; scripts/run_vial_native_uvm_experimental_probe.pl; t/1560-vial-native-uvm-emitter-substrate.t; t/1570-vial-native-uvm-topology-lifecycle-notification.t; t/1580-vial-native-uvm-stimulus-services.t; t/1590-vial-native-uvm-checking-results.t; t/1591-vial-native-uvm-matrix-review.t; t/1592-vial-native-uvm-experimental-probe.t;
  vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation/README.md; vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation/selected-mapping-matrix.json; vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation/review-workflow.json;
  vial/experimental_probes/sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0/README.md; vial/experimental_probes/sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0/probe-report.json;
  docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md; perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm; perl/FSM/VIAL/Backend/VHDLPortableStaticValidator.pm; perl/FSM/VIAL/Backend/VHDLPortableReviewClosure.pm; perl/FSM/VIAL/Backend/VHDLPortableGHDLQualification.pm; perl/FSM/Support/VIALVHDLEmissionContract.pm; scripts/refresh_vial_vhdl_portable_gallery.pl; scripts/run_vial_vhdl_portable_ghdl_qualification.pl; t/1593-vial-vhdl-portable-semantics.t; t/1594-vial-vhdl-portable-matrix-review.t; t/1595-vial-vhdl-portable-ghdl-qualification.t;
  vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/README.md; vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/evidence/selected-mapping-matrix.json; vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/evidence/review-workflow.json; vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics/evidence/migration-proof.json; vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json;
  perl/FSM/VIAL/Backend/OSVVM2026_05Materialization.pm; perl/FSM/VIAL/Backend/VHDLOSVVM2026_05.pm; perl/FSM/VIAL/Backend/VHDLOSVVMStaticValidator.pm; perl/FSM/VIAL/Backend/VHDLOSVVMGHDLQualification.pm; scripts/refresh_vial_vhdl_osvvm_gallery.pl; scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl; t/1598-vial-vhdl-osvvm-emission.t; t/1599-vial-vhdl-osvvm-ghdl-qualification.t; vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/README.md; vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/provider-materialization.json; vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/advanced-mapping-matrix.json; vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/semantic-preservation.json; vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/qualification-reference.json;
  docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/tasks/IASIM-EXECUTABLE-REFERENCE-SEMANTICS.md; docs/tasks/XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.md; docs/decisions/0004-simulate-to-catch-codegen-bugs.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16d-hial-vial-verification-architecture.md; https://www.accellera.org/downloads/standards/uvm; https://github.com/accellera-official/uvm-core/releases/tag/2020.3.1; https://github.com/chipsalliance/uvm-verilator; https://verilator.org/guide/latest/languages.html;
  https://verilator.org/guide/latest/connecting.html; https://ghdl.github.io/ghdl/using/ImplementationOfVHDL.html; https://osvvm.org/about-os-vvm; https://uvvm.github.io/
reverify: >-
  scripts/check_task_tree_integrity.pl &&
  rg -n 'sv_uvm_emit\.accellera_2020_3_1|sv_uvm_experimental|sv_uvm_qualified|PGEN|NEXSIM|semantic introspection|MCP|snapshot-consistent|first divergence|2020\.3\.1|78c06547a2a0a29b3dc9dcafae62b75b2ff61544' docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16d-hial-vial-verification-architecture.md &&
  rg -n 'native Intent Abstraction|signoff|direct semantic adapters|HDL-independent|kernel/session|Perl 5|versioned C ABI|shared library|differential equivalence' docs/tasks/IASIM-EXECUTABLE-REFERENCE-SEMANTICS.md docs/book/src/16d-hial-vial-verification-architecture.md &&
  rg -n 'complete native framework|xIAL|HIAL IP|VIAL VIP|functional/intent signoff' docs/tasks/XIAL-NATIVE-DEVELOPMENT-FRAMEWORK.md &&
  rg -n 'semantic_catalog_v1|bridge_fanout_v1|execution_graph_v1|checking_state_v1|backend_emission_v1|runtime_stream_v1|big.*really_big' docs/decisions/0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md docs/book/src/16d-hial-vial-verification-architecture.md &&
  rg -n '88%|4,096 MiB|pinned host|earliest authoritative cap|same-volume' docs/decisions/0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md docs/book/src/16d-hial-vial-verification-architecture.md &&
  prove -Iperl t/1555-vial-public-source-tooling.t t/1556-vial-public-planning-artifacts.t t/1557-vial-portable-sv-backend-emission.t t/1558-vial-verilator-run-integration.t t/1559-vial-ahb-runtime-parity.t t/1560-vial-native-uvm-emitter-substrate.t t/1570-vial-native-uvm-topology-lifecycle-notification.t t/1580-vial-native-uvm-stimulus-services.t t/1590-vial-native-uvm-checking-results.t t/1591-vial-native-uvm-matrix-review.t t/1592-vial-native-uvm-experimental-probe.t t/1593-vial-vhdl-portable-semantics.t t/1594-vial-vhdl-portable-matrix-review.t t/1595-vial-vhdl-portable-ghdl-qualification.t t/1598-vial-vhdl-osvvm-emission.t t/1599-vial-vhdl-osvvm-ghdl-qualification.t &&
  perl scripts/refresh_vial_native_uvm_gallery.pl --check &&
  perl scripts/run_vial_native_uvm_experimental_probe.pl --check &&
  perl scripts/refresh_vial_vhdl_portable_gallery.pl --check &&
  perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check &&
  perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check &&
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
---

Hardware IAL (HIAL) is the collective architecture name for FSMGen's current
synthesizable IAL0/IAL1/IAL2 stack. Its public names and review route remain
unchanged. Verification IAL (VIAL) is its pure-verification peer.

Decision `0032` selects one public, reviewable `.vial` source language rather
than VIAL0/VIAL1/VIAL2. Private immutable `VIALSemanticIR` owns unbound typed
verification meaning. A bounded versioned `HIALVIALBridgeManifest` supplies
sanitized HIAL units, configuration, types, endpoints, clocks/resets,
transactions/events, protocol facts, observations/probes, backend bindings,
capabilities, source identity, and source maps. Private immutable
`VIALExecutionIR` owns the bound, capability-checked deterministic plan.

Portable VIAL covers typed stimulus, transactions, scenarios, deterministic
fibers, expected outcomes, temporal checks, reference models, scoreboards,
coverage, bounded fault injection, and reproducible randomness. Execution uses
logical `drive`, `sample`, `react`, and `check` phases. Native target power is
provided by typed external repository-relative extensions, never anonymous raw
SV/UVM or VHDL embedded in portable source.

Portable backend parity compares normalized logical result manifests, not
generated source or waveforms. Public ports are the portable access baseline;
declared HIAL verification probes require capability-qualified equivalent
adapters; raw hierarchy is native-only. IAL2 facts must remain reviewable
through generated IAL1 before the bridge consumes them, so there is still no
direct `.ppif` verification-output path.

The first runnable profile is `sv_portable_verilator`, using static plain-
SystemVerilog lowering, inactive-edge scheduling, declared-probe adapters, a
closed result trace, and exact Verilator 5.046 `--binary --timing --assert`
gates. It is explicitly a known-value/two-state runtime profile, not complete
four-state, SystemVerilog, or UVM authority. `sv_uvm_qualified`,
`vhdl_portable_ghdl`, `vhdl_methodology_qualified`, and
`mixed_language_qualified` remain separate claims with exact tools, versions,
providers, and exercised capabilities. The private provider-free VHDL emitter
now includes bounded scoreboards, explicit coverage counters, substitution
faults, procedural checks, diagnostic records, closed trace framing, and a
normalized-result projection with all top-level manifest families, bounded
stored diagnostic details, and VHDL-native quote doubling. C-style JSON string
escaping is rejected structurally. The closed provider-free profile now has 17
artifacts: a 24-row matrix with 20 emitted and four exactly unsupported
boundaries, a seven-stage deterministic review/defect workflow, and exact
inert-legacy/HIAL separation evidence alongside its six sources, 59 maps, and
20 static checks. It is emitted and structurally reviewed; visual review
remains pending. The exact canonical fixture is separately qualified under
repository-local GHDL 6.0.0 LLVM-JIT through analysis, elaboration, bounded
runtime, closed trace, normalized result, timed `0/1/X/Z`, deterministic rerun,
and nineteen applicable portable-SV parity paths. The exact LLVM AOT build is
not inferred because its external-name adapter fails at runtime.
Existing UVM 1.2 and VHDL observation outputs remain inert compatibility
surfaces.

The shipped stack now covers the typed `.vial` frontend, review-routed bridge,
bound deterministic ExecutionIR, public source/planning/run tools, atomic
artifacts, portable-SystemVerilog execution, normalized results, and the
selected 19-path AHB parity oracle. General cross-backend parity remains
unclaimed.

The 2026-08-10 mixed-language census finds Verilator and Icarus on `PATH` and
exact GHDL 6.0.0 LLVM-JIT under the repository-local provider cache, but no
compatible mixed-language simulator. Separate Verilator/GHDL qualifications
cannot satisfy `mixed_language_qualified`; `.16` stays proposed.

Decisions `0055` and `0056` select architecture-scale proof without claiming capacity.
Six orthogonal families isolate source/SemanticIR, bridge fanout, execution
graphs, checking state, backend emission, and runtime streams; one conservative
balanced candidate checks interaction. Each axis has reference, gate-candidate,
qualification-candidate, exact-limit, and over-limit levels. Every timing/RSS
sample is invalid unless its stage-local semantic, identity, source-map,
artifact, deterministic-rerun, result, failure, and cleanup oracles pass.
Fixed 88%-host/4,096-MiB-descendant safety applies immediately; performance
budgets derive immutably from clean pinned-host calibration and do not fail on
unmatched hosts. Earliest-cap dominance is reported honestly. These candidates
are not support, multi-unit/domain, mixed-language, native-UVM-runtime, full-
language, whole-product `big`/`really_big`, synthesis, or general-parity claims.
Completed `.17.7` removes `t/1569`'s stale focused-index count shadow by
validating the authority's complete nonzero census instead. Completed `.17.6`
aligns the public support snapshot with the Runner/normative 8-MiB compile and
64-MiB runtime capture limits. Completed `.17.8` records that current authority.
Decision `0057` and completed `.17.2.1` ship a bounded source-only catalog,
identity, seeded payload, and same-volume staging/cleanup foundation without a
capacity claim. Completed `.17.9` repairs cleanup; active `.17.2.2` owns
semantic generation.

Decision `0050` and completed `.12` select IEEE 1800.2-2020 with exact
Accellera UVM 2020-3.1 tag/commit as the native methodology source. Commercial
simulators are not a required near-term project dependency. Native work has
three honest tiers: deterministic
`sv_uvm_emit.accellera_2020_3_1` artifacts with compile/run explicitly not
run, optional `sv_uvm_experimental.<tool-and-version>` probes that cannot
become product support, and future `sv_uvm_qualified` runtime through an exact
capability-ready PGEN parser plus NEXSIM simulator tuple. PGEN and NEXSIM are
both progressing external projects; their versions and handoff are not
invented in advance. Verilator's UVM support remains officially in
development and cannot currently qualify the full runtime family.

NEXSIM will expose deep semantic introspection through a clean API operated by
MCP. Future `.13.3` qualification can use versioned structured queries and
controls to inspect hierarchy, types, four-state values, processes/events,
scheduler state, assertions/coverage, and supported UVM methodology objects;
run or step bounded sessions; take consistent checkpoints; and correlate
stable NEXSIM object identities through generated source maps to UVM,
`VIALExecutionIR`, and HIAL/VIAL semantic IDs. Common checkpoints can be
compared with IASIM or another applicable normalized oracle to identify and
classify the first divergence. Queries must be bounded, deterministic,
snapshot-consistent, and side-effect free, while control permissions remain
explicit. This is strong provider evidence, not authority over VIAL meaning or
permission to put NEXSIM/MCP dependencies into canonical generated source.

The selected contract maps typed notification/interception, lifecycle,
stimulus, TLM communication, substitution/configuration, RAL, constrained
decisions, coverage/properties, timed interfaces, scenarios, models,
scoreboards, faults, and results to compiler-private UVM mechanisms. Active
`.13.1` decomposes full-shaped simulator-neutral emission and review galleries
across five unblocked leaves; typed-IR previews may exercise mappings before
all public VIAL syntax exists. Static checks and director visual review are
emission evidence, not compile/runtime qualification. `.13.2` probes exact
open-tool parsing, compile, elaboration, and any supported smoke runtime as
soon as `.13.1.1` produces the first gallery. Tool limitations do not block
broader generation, while demonstrated generator defects are fixed or tracked.

Generated UVM syntax, expressions, helpers, macros, and class decomposition
may iterate from review and tool diagnostics because they are compiler output.
Exact emitter identity owns byte determinism; VIAL meaning, capability truth,
artifact schemas, and source maps remain stable or are explicitly versioned.
The shipped UVM 1.2 passive-monitor output stays unchanged and unqualified.
Completed `.13.1.1` establishes the private
`sv_uvm_emit.accellera_2020_3_1` foundation. Completed `.13.1.2` expands the
topology/lifecycle/notification foundation. Completed `.13.1.3` adds active
stimulus/services. Completed `.13.1.4` emits an exact fourteen-artifact
graph with ten SystemVerilog sources: deterministic
HIAL DUT; typed logical-time/lifecycle/filter/effect/reentrancy context;
component and agent bases; drive/sample interface; ordered typed notification
package; active sequencer/driver/monitor agent; generated scenario sequences;
typed analysis/TLM services; scoped factory/configuration wiring; private RAL
preview; public two-bin coverage; a bound SVA checker; two event-counter
models; one capacity-four in-order scoreboard; one-drive-interval field
substitution; property/diagnostic/result collection; lifecycle controller;
environment/root test; and bound top. Exactly one test-owned objection pair
encloses execution. Six public
VIAL event identities receive typed channels; the generated interceptor table
remains a private preview. Stable rank then semantic-ID registration,
immutable/effective payload separation, cancellation/skipped accounting, and
bounded queue-or-reject reentrancy are structurally checked.

Portable constrained decisions are replayed from immutable selected values;
generated UVM scenarios do not rerandomize them. The bounded native solver,
RAL objects, and compiler-selected factory override are private typed previews,
not claims of new public VIAL authoring syntax. The graph has 75 complete
source-map entries and passes 14 static checks. All nine UVM-facing source
files are byte-checked in the review gallery.

Completed `.13.1.5` advances the private emitter to revision 5 without adding
SystemVerilog source. Its exact sixteen-artifact graph adds
`selected-mapping-matrix.json` and `review-workflow.json`. The 25 matrix rows
equal the backend's emitted-foundation set and distinguish normal/terse public
source, public or compiler-owned IR, and private previews with exact unsupported
reasons. Every row independently records emitted, structural-review, visual-
review, and qualification states.

The seven-stage workflow owns repository-relative regenerate and non-mutating
check commands, nine source and two evidence examples, pending director or
delegated visual review, exact durable task-tree defect fields, and separately
not-run experimental compile and qualified runtime stages. Run `perl
scripts/refresh_vial_native_uvm_gallery.pl` to regenerate or append `--check`
to reject missing, extra, or byte-drifted snapshots without writing files.

The public coverage/model/scoreboard/fault/expectation records own their
generated structures. Exact one- and two-bit notification predicates now use
the width-aware scalar-literal validator instead of the former whole-nibble
known-mask test. The result collector produces only a structured generated
snapshot shape; no runtime or verification-result manifest is claimed, and
verification-probe-backed expectations still require a qualified adapter.

Ordinary-emission capability discovery labels emission, structural validation,
and selected mapping closure passed, while the review workflow is available
and manual review remains pending. Ordinary emission fetches or inspects no UVM
library bytes and does not borrow a parser, compile, elaboration, or runtime
claim from a separate probe. Completed `.13.1` owns the full selected
simulator-neutral emission scope; it does not claim complete UVM breadth.

Completed `.13.2` selects Verilator 5.046 plus CHIPS Alliance `uvm-verilator`
`uvm-2020-3.1-vlt` commit `656f20d087370a7c742e00188d20bbf30fa95339`
and tree `882930bb7debe79b22234e4a8a53854549046778`. The local bounded
probe validates them; its UVM library/control preprocess, parse,
compile/elaboration, and zero-error/fatal `run_phase` smoke pass. The generated
fixture preprocesses.

The probe found illegal use of SystemVerilog keyword `context` as an identifier;
the emitter/gallery now use `vial_context`. Strict fixture parsing then reaches
only unsupported `##[1:256]` SVA; separate `--bbox-unsup` compile/elaboration
reaches a Verilator internal fault/139. `UVM_NO_DPI` is experiment-wide.
Fixture runtime/results/parity/four-state/full breadth remain unexercised, so
the byte-checked report is `partial_tool_limited`, `product_support=false`.
`.13.3` is director-deferred. Completed `.15.5` owns the exact GHDL 6.0.0
LLVM-JIT proof; completed `.15.6` owns exact recursive OSVVM 2026.05
materialization and structurally reviewed adapter/gallery emission. Completed
`.15.7` owns the combined exact provider/tool qualification.

Completed `.15.1-.15.5` ship and qualify the private provider-free VHDL
profile. Its 17 artifacts retain six sources, 59 maps, 20 checks, exact HIAL
identity, typed `std_logic` observation, one inactive-edge scheduler, bounded
scenarios/models/checking, declared-probe-only hierarchy, and closed results.
Run `perl scripts/refresh_vial_vhdl_portable_gallery.pl --check` for the
byte-locked gallery and the guarded qualification command in `reverify` for
the exact LLVM-JIT proof. Ordinary portable emission fetches no provider; the
legacy VHDL observation package remains unchanged and unconsumed. The advanced
graph locks 14 repositories, 13 gitlinks, 14 Apache-2.0 licence files, zero
notice files, and clean tree identities. The pinned Documentation repository
has no tracked licence/notice file, so no coverage is inferred. Seven mappings
emit beside the portable graph with 13 maps, 12 checks, and six semantic
guards. The exact tuple compiles 61 OSVVM/Common sources, analyzes the seven
generated sources plus its probe, and double-runs both tops. Portable trace,
result, and 19-path parity remain authoritative while the probe executes
random, coverage, scoreboard, report, memory, and barrier services; the Common
address-bus type is analysis-only. Complete VHDL breadth, PSL, UVVM, another
simulator, mixed-language behavior, general parity, and scale remain unclaimed.

`IASIM-EXECUTABLE-REFERENCE-SEMANTICS` now preserves a separate proposed
architecture for an Intent Abstraction Simulator. IASIM is a first-class,
HDL-independent runtime for the native Intent Abstraction world. Direct
IAL2/IAL1/IAL0 semantic adapters feed one canonical execution model and engine;
production tier lowering remains a separately comparable path. IASIM runs the
existing `VIALExecutionIR` against HIAL and produces normalized traces and
results. The intended scheduler seam is VIAL drive, HIAL settle/domain/state
update, then VIAL sample, react, and check. Its values, time, events, and updates
come from explicit Intent Abstraction semantics rather than inherited HDL event
regions or least-common-denominator simulator behavior.

The definition-oriented IASIM reference kernel is Perl 5 first. Perl remains
the semantic orchestrator and authoritative comparison route; representative
xIAL workloads must demonstrate a real bottleneck before optimization. A
measured bounded hotspot may later be implemented in Rust and exposed as a
shared library through a stable versioned C ABI (`Rust -> shared library ->
Perl`). Such an accelerator must define memory ownership plus error and panic
boundaries explicitly and prove deterministic normalized differential
equivalence against the pure-Perl route. No full IASIM rewrite is implied.

IASIM accuracy is qualified natively, without generating HDL: a precise
versioned semantics, a definition-oriented reference interpreter or equivalent
independent oracle, manually derived conformance vectors, property/metamorphic
tests, bounded exhaustive small cases, direct-versus-lowered cross-level
equivalence, deterministic replay, semantic coverage, and mutation/seeded-defect
detection. A passing IASIM result can therefore carry its own exact signoff
claim, while still not proving generated HDL syntax, elaboration, backend
translation, or external simulator scheduling. The proposed first leaf audits
whether the existing HIAL projections can support that native contract or
whether a private execution model is needed. Optional later HDL runs compare
against IASIM to qualify the lowering, PGEN/NEXSIM, or another simulator; they
do not define IASIM correctness.

`XIAL-NATIVE-DEVELOPMENT-FRAMEWORK` broadens the product direction from an
engine into a complete ecosystem. Here `xIAL` means HIAL or VIAL (`x = H` or
`x = V`), not another language tier. The primary no-HDL loop is author and
compose HIAL plus VIAL, elaborate/check, execute in IASIM, inspect/debug,
measure and close coverage, regress, then issue a scoped native xIAL signoff
manifest. IASIM stays the small independently qualified semantic kernel; a
stable session/query API keeps rich framework policy and clients from changing
execution meaning.

The surrounding framework owns reproducible workspaces and incremental builds,
authoring/introspection, reusable versioned HIAL IP and VIAL VIP/packages,
interactive sessions, typed semantic traces, causal debug and time travel,
verification services, regression/triage, coverage closure and waivers,
visualization, automation/extensions, scale/recovery, and signoff governance.
CLI, TUI, IDE, web, and automation clients share one typed service truth.
Generated HDL and external tools remain unnecessary for operating the native
inner loop, but supported HDL export is not an optional product-quality
obligation. Every advertised
publishable xIAL-to-HDL profile must name exact language/methodology revisions
and pass professional source/packaging, source-map, LRM conformance, lint/
warning, parse/compile/elaboration/runtime, IASIM differential, multi-tool
portability, and applicable synthesis/equivalence gates with a reproducible
conformance manifest. HDL still does not define xIAL meaning. Native xIAL
functional/intent signoff also does not silently claim synthesis, timing,
CDC/RDC, DFT, physical implementation, analog, or silicon signoff; those keep
separate explicit evidence layers.
