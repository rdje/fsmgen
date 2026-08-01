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
  - "how will PGEN and NEXSIM qualify VIAL UVM runtime?"
  - "can Verilator currently qualify full VIAL UVM support?"
  - "can FSMGen generate full UVM before a full simulator exists?"
  - "can Verilator compile or elaborate early generated UVM?"
  - "may generated UVM syntax change while VIAL meaning stays stable?"
  - "what is IASIM?"
  - "should FSMGen simulate Intent Abstraction directly?"
  - "can IASIM replace an HDL simulator?"
  - "how would IASIM combine HIAL and VIAL?"
  - "what should IASIM execute?"
  - "how does IASIM avoid common-mode code generation bugs?"
date: 2026-08-01
status: current
tags: [hial, vial, ial0, ial1, ial2, verification, semantic-ir, execution-ir, bridge, sv-uvm, vhdl, verilator, simulator-profile, architecture, task-tree]
evidence: >-
  docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md; perl/FSM/VIAL/Backend/SVPortableVerilator.pm; perl/FSM/VIAL/Backend/TraceValidator.pm; perl/FSM/VIAL/Parity/AHBBaseOutput.pm; t/1557-vial-portable-sv-backend-emission.t; t/1559-vial-ahb-runtime-parity.t;
  docs/decisions/0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md; docs/decisions/0033-vial-v1-uses-spanned-s-expressions-and-typed-semantic-records.md; docs/decisions/0035-hial-vial-bridge-is-produced-from-reviewable-hial-routes.md;
  docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md; docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md; docs/decisions/0039-vial-public-tooling-is-intent-oriented-and-artifact-atomic.md; docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md; docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/tasks/IASIM-EXECUTABLE-REFERENCE-SEMANTICS.md; docs/decisions/0004-simulate-to-catch-codegen-bugs.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16d-hial-vial-verification-architecture.md; https://www.accellera.org/downloads/standards/uvm; https://github.com/accellera-official/uvm-core/releases/tag/2020.3.1; https://github.com/chipsalliance/uvm-verilator; https://verilator.org/guide/latest/languages.html;
  https://verilator.org/guide/latest/connecting.html; https://ghdl.github.io/ghdl/using/ImplementationOfVHDL.html; https://osvvm.org/about-os-vvm; https://uvvm.github.io/
reverify: scripts/check_task_tree_integrity.pl && rg -n 'sv_uvm_emit\.accellera_2020_3_1|sv_uvm_experimental|sv_uvm_qualified|PGEN|NEXSIM|2020\.3\.1|78c06547a2a0a29b3dc9dcafae62b75b2ff61544' docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16d-hial-vial-verification-architecture.md && prove -Iperl t/1555-vial-public-source-tooling.t t/1556-vial-public-planning-artifacts.t t/1557-vial-portable-sv-backend-emission.t t/1558-vial-verilator-run-integration.t t/1559-vial-ahb-runtime-parity.t
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
providers, and exercised capabilities. Existing UVM 1.2 and VHDL observation
outputs remain inert compatibility surfaces until later migration leaves.

The architecture audit is complete and maps the handwritten AHB arbitration
fixture, migration, public artifacts, parity, and scale boundaries. `.3` now
ships the bounded semantic-only `.vial` frontend under decision `0033`.
Completed `.4` selects the exact review-routed bridge v1 contract under
decision `0035`: IAL2 facts must appear in a generated-IAL1
`(verification-bridge ...)` annotation, exact AHB IDs match the checked VIAL
source, and clean contract commit `0366dfe30` activates `.5` alone for private
no-file implementation without changing product behavior. Completed `.5` now
ships that private producer through canonical HIAL review routes, including the
additive generated/reparsed IAL1 annotation for IAL2. It binds no VIAL and
emits no file, plan, target artifact, or runtime behavior. Clean implementation
commit `51434a2ae` permitted the separate `.6` execution-contract selection.

Completed `.6` accepts decision `0036` and the exact target-neutral
ExecutionIR/logical-time/random-replay/native/plan/result/parity contract.
Clean selection commit `eaf3f95dc` permitted `.7` to own private no-backend
work after separate continuity activation. Audit `.7.1` found the
exact-type/carrier mismatch; director-approved decision `0037` and `.7.2`
selected closed directional proof relations without changing VIAL source or
the bridge schema. `.7.3` now ships the private binder, immutable ExecutionIR,
deterministic plan-time random/replay, defensive in-process plan, event/
adapter binding, exact resource accounting, atomic diagnostics, and private
capability discovery. It emits no file or backend and exposes no supported
public API. Completed `.8` now accepts decision `0039` and the exact public-
tooling contract: `fsmgen vial`, equivalent normal/terse source projections,
separate VIAL/HIAL inputs, a portable source-catalog/artifact-sink API, atomic
repository-local artifacts, and explicit manifest compatibility. No command,
API, parser widening, file, backend, or runtime ships in selection. Decision
`0043` and completed `.9` now select the exact portable backend contract;
clean selection commit `ab3e73b72` activates `.10` as the first implementation
owner. Clean activation commit `5fd766600` decomposes it into public source,
planning/artifact, backend/trace, and runtime/result children. Completed
`.10.1` ships the defensive capabilities/check/normal-terse source CLI/API and
exact discovery/support accounting without HIAL binding or writes. Clean
`.10.1` implementation commit `50a0d7d39` activates `.10.2`; completed `.10.2`
ships all three canonical HIAL planning routes plus defensive virtual or
atomic repository-local artifacts. Transaction-free direct-IAL0 endpoint
fixtures are supported without inventing transaction truth. Completed `.10.3`
ships the private deterministic portable-SystemVerilog emitter, complete
operation/state-family source map, one-scheduler known-value fixture, honest
emission-only tool records, and a pure closed-JSONL trace validator. Completed
`.10.4` now ships public run/publication, exact Verilator 5.046 compile/runtime,
validated trace capture, normalized results, deterministic reruns, and atomic
cleanup. Completed `.11` independently executes both harnesses over byte-identical DUT
source and compares 19 public/shared AHB outcomes. Undeclared internal metrics
are explicit exclusions; general cross-backend parity remains unclaimed.

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
`.13.1.1` is next for clean activation; `.13.3` alone retains the future
PGEN+NEXSIM runtime blocker.

`IASIM-EXECUTABLE-REFERENCE-SEMANTICS` now preserves a separate proposed
architecture for an Intent Abstraction Simulator. IASIM would execute HIAL
through a canonical executable semantic boundary and run the existing
`VIALExecutionIR` against it, producing normalized traces and results. The
intended scheduler seam is VIAL drive, HIAL settle/clock/state update, then VIAL
sample, react, and check. It should use exact declared value/time semantics and
an implementation independent from the HDL emitters so a shared bug cannot make
the oracle and generated code agree falsely.

IASIM is therefore an executable intent specification and future differential
oracle, not an HDL simulator. A passing IASIM result can validate HIAL/VIAL
meaning before a full SV/UVM runtime is available, but it cannot prove generated
HDL syntax, elaboration, backend translation, or external simulator scheduling.
The proposed first leaf audits whether the existing HIAL intent/lowered/
structural projections are executable or whether a private
`HIALExecutionIR` is needed. IASIM complements PGEN and NEXSIM: later HDL runs
can compare their normalized results against the IASIM reference.
