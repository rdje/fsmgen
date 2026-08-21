---
id: vial-native-uvm-emission-contract
title: Native VIAL UVM is simulator-neutral Accellera 2020-3.1 emission, not runtime support
answers:
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
  - "may generated UVM syntax change while VIAL meaning stays stable?"
  - "what native UVM operation shape does backend negotiation accept?"
  - "does native UVM emission accept more than 21 operations?"
date: 2026-08-21
status: current
tags: [hial, vial, sv-uvm, accellera, nexsim, pgen, review-gallery, verification]
evidence: >-
  docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md;
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md;
  perl/FSM/VIAL/Backend/SVUVMAccellera2020_3_1.pm;
  perl/FSM/VIAL/Backend/SVUVMStaticValidator.pm;
  perl/FSM/VIAL/Backend/SVUVMReviewClosure.pm; perl/FSM/VIAL/BackendEmissionAuthority.pm;
  perl/FSM/Support/VIALNativeUVMEmissionContract.pm;
  scripts/refresh_vial_native_uvm_gallery.pl;
  t/1560-vial-native-uvm-emitter-substrate.t;
  t/1570-vial-native-uvm-topology-lifecycle-notification.t;
  t/1580-vial-native-uvm-stimulus-services.t;
  t/1590-vial-native-uvm-checking-results.t;
  t/1591-vial-native-uvm-matrix-review.t;
  t/1643-vial-native-uvm-selected-shape-negotiation.t; t/1644-vial-backend-emission-authority-alignment.t;
  vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation/README.md;
  vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation/selected-mapping-matrix.json;
  vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation/review-workflow.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  rg -n 'sv_uvm_emit\.accellera_2020_3_1|sv_uvm_qualified|PGEN|NEXSIM|semantic introspection|MCP|snapshot-consistent|first divergence|2020\.3\.1'
  docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
  docs/book/src/16d-hial-vial-verification-architecture.md &&
  prove -Iperl t/1560-vial-native-uvm-emitter-substrate.t
  t/1570-vial-native-uvm-topology-lifecycle-notification.t
  t/1580-vial-native-uvm-stimulus-services.t
  t/1590-vial-native-uvm-checking-results.t
  t/1591-vial-native-uvm-matrix-review.t
  t/1643-vial-native-uvm-selected-shape-negotiation.t
  t/1644-vial-backend-emission-authority-alignment.t &&
  perl scripts/refresh_vial_native_uvm_gallery.pl --check
---

Decision `0050` and completed `.12` select IEEE 1800.2-2020 with exact
Accellera UVM 2020-3.1 tag/commit as the native methodology source. Commercial
simulators are not a required near-term project dependency. Native work has
three honest tiers: deterministic `sv_uvm_emit.accellera_2020_3_1` artifacts
with compile/run explicitly not run, optional
`sv_uvm_experimental.<tool-and-version>` probes that cannot become product
support, and future `sv_uvm_qualified` runtime through an exact
capability-ready PGEN parser plus NEXSIM simulator tuple. PGEN and NEXSIM are
both progressing external projects; their versions and handoff are not
invented in advance. Verilator's UVM support remains officially in development
and cannot currently qualify the full runtime family.

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
`.13.3` is director-deferred.

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

Decision `0075` also closes the backend's operation-shape negotiation. The
only admitted plan is the selected 21-operation review shape: the exact
operation sequence, 12/9 scenario partition, four total and three
simultaneously live fibers, matching resource count, and ten ordered public
expectation roles. Adding one response expectation (T=22), constructing a
larger T=128 witness, or changing an expectation role while retaining T=21
returns one `VIAL_UVM_BACKEND_UNSUPPORTED` diagnostic at `/negotiation` before
an operation identity, manifest, source map, artifact, or staging residue can
exist. The accepted graph remains ten SystemVerilog sources, 138,345 source
bytes, 75 maps, and 14 structural checks. This is an honest selected-gallery
boundary, not a native-UVM scale, runtime, result, or support claim.

Catalog and capability discovery consume the same closed authority: ten source
artifacts, sixteen total artifacts, the enforced 16-MiB source and one-million-
entry map caps, and the selected 21-operation/75-map/14-check/25-mapping
matrix. Defensive validation rejects unknown, missing, stale, or contradictory
fields. Generator leaf `.17.2.6.3.5` alone is active to consume that selected
review route through the caller-sealed architecture-scale foundation and retain
the adjacent fail-closed boundary; activation changes no emitter or product
behavior. These structural limits add no native-UVM runtime or support claim.

Related: [[hial-vial-verification-fixture-architecture]],
[[vial-native-uvm-experimental-probe]], [[semantic-introspection-mcp-frontier]].
