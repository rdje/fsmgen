# HIAL/VIAL Verification Backlog

### Selected HIAL/VIAL architecture

The architecture for full fixture generation is selected and decomposed. Its
bounded semantic frontend, review-routed private bridge, and target-neutral
execution elaborator are shipped. Public source tooling, canonical planning,
and the exact `sv_portable_verilator` run/result path now ship. The selected AHB
fixture has bounded handwritten-oracle parity; this is not general cross-
backend parity. Native-UVM and provider-free portable-VHDL review emission also
ship privately, while their qualified runtime/result profiles remain pending.
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE` names current synthesizable
IAL0/IAL1/IAL2 collectively as **Hardware IAL (HIAL)** and defines a peer
**Verification IAL (VIAL)** for pure verification intent:

| Intent system | Required target family | Contract boundary |
| --- | --- | --- |
| HIAL | synthesizable SystemVerilog and synthesizable VHDL | hardware behavior only |
| VIAL | native SystemVerilog/UVM or VHDL verification code | non-synthesizable fixture behavior |

A single public, reviewable `.vial` language carries declarations and
scenarios. It lowers first to private immutable `VIALSemanticIR`, then binds
through a bounded versioned `HIALVIALBridgeManifest` into private immutable
`VIALExecutionIR`. VIAL deliberately does **not** mirror HIAL as
VIAL0/VIAL1/VIAL2: verification declarations, DUT binding, scenarios,
concurrency, checking, models, scoreboards, coverage, and backend methodology
are orthogonal concerns rather than three useful authoring levels.

The bridge carries sanitized, stable identities for HIAL sources/review
artifacts, units, configuration, types, endpoints, clocks/resets,
transactions/events, protocol facts, observations/probes, backend bindings,
capabilities, and source maps. IAL2 facts must first remain reviewable through
generated IAL1; the architecture does not add a direct `.ppif` verification
output route. Portable VIAL covers typed stimulus, transactions, scenarios,
deterministic fibers, expected outcomes, temporal checks, models,
scoreboards, functional coverage, bounded faults, and reproducible random
decisions. Anonymous raw target-language blocks are excluded; advanced
SV/UVM or VHDL behavior uses typed, scoped, repository-relative native
extensions with explicit profile and fallback contracts.

Implementation `.3` now parses and type-checks the checked
`vial/ahb_subordinate_base_output_arbitration.vial` source into private
immutable `VIALSemanticIR` and exposes a defensive sanitized semantic report
through a private checker. The semantic corpus still claims only parse,
typecheck, and semantic-report phases. Capability discovery additionally
reports the private target-neutral binder and public source/plan/run surfaces.
The public planner publishes only canonical normal source, generated HIAL
review artifacts, defensive bridge/plan projections, and its tool manifest;
that action exposes no target artifact. Public `run` separately composes the
private `.10.3` emitter with exact Verilator 5.046 compile/runtime, closed trace
validation, normalized results, and atomic publication. Complete four-state
behavior, general cross-backend parity, UVM/VHDL execution, mixed-language,
and scale remain unclaimed.

Decision `0034` sets the longer-term rule: **full power underneath, simpler
intent above**. Abstraction means simplification, so mastering VIAL does not
require SV/UVM/VHDL knowledge; those are conceptually backend target languages,
like assembly targets for C/C++ or Rust. Factories, config DB/TLM plumbing,
phases/objections, callbacks, and comparable methodology details remain
compiler choices beneath typed verification intent. Qualified backends must
eventually emit efficient, readable, source-mapped output without defining
VIAL in target-language terms. Proposed `.19` owns the detailed expressive-
family decomposition after concrete backend evidence exists.

Verification is qualified through explicit simulator capability profiles. A
fast portable profile uses Verilator only for the synthesis-oriented
SystemVerilog subset it supports; that profile is not evidence of complete
SystemVerilog LRM or UVM support. Verilator compiles a model that is explicitly
evaluated; `--timing` schedules supported delays, event controls, waits, forks,
and delayed processes. It is therefore event-capable compiled simulation, not
a traditional full-language event-driven authority. Advanced native
SystemVerilog/UVM output requires a separate full-language/UVM simulator
profile with the tool version and exercised capabilities reported. VHDL
portability, full-language qualification, and mixed-language qualification are
distinct profiles as well, so one successful tool run never silently widens
the support claim.

Portable execution uses logical `drive`, `sample`, `react`, and `check` phases
so backend scheduling regions or delta cycles do not change intent. Backend
parity compares a normalized result manifest containing scenario/event
identity, logical cycle/phase, transaction values, checks, scoreboard results,
coverage, timeout/termination, and stable random decisions. It does not
require identical target text or waveforms.

Decision `0032` selects plain SystemVerilog/Verilator as the first runnable
profile. Native UVM, VHDL-2008/GHDL, VHDL methodology, and mixed-language
profiles remain separately qualified claims. The shipped UVM 1.2 passive
monitor and VHDL observation package stay inert compatibility surfaces until
exact migration leaves replace or version them. The architecture audit maps
the handwritten AHB subordinate arbitration fixture, distinguishes portable
public-port outcomes from qualified probes and native hierarchy, and defines
exact source/IR, bridge, execution, tooling, backend, parity, migration, and
scale leaves. See [HIAL/VIAL Verification Architecture](16d-hial-vial-verification-architecture.md)
for the topology, profile matrix, worked mapping, and current boundaries.

Decision `0051` selects provider-free IEEE VHDL-2008 as the portable core,
exact GHDL 6.0.0 as the
first qualification tool, and OSVVM 2026.05 is the advanced methodology
provider. UVVM was audited but is not the version-1 provider. The native VIAL
artifact graph is a parallel versioned successor; it does not promote or
rewrite the inert `vhdl-observation-package`. Reviewable emission may progress
before a tool/library is available. Completed `.15.5` now supplies the first
bounded exact-tool evidence without implying PSL or methodology support.

Implementation parent `.15` is active and split along those evidence
boundaries. Completed `.15.1-.15.4` ship a 17-artifact provider-free VHDL
review profile: six sources, 59 source maps, 20 static checks, a 24-row selected
mapping matrix, deterministic checking/scoreboard/coverage/fault/result
structures, and a seven-stage review/defect workflow.

Completed `.15.5` separately qualifies this exact canonical graph under the
repository-local GHDL 6.0.0 LLVM-JIT backend: analysis, elaboration, bounded
execution, timed `0/1/X/Z`, one closed 42-record trace, a passing normalized
result, deterministic reruns, and nineteen applicable portable-SV parity paths
pass. Completed `.15.6` now installs and recursively verifies exact OSVVM
2026.05, then emits its isolated seven-service adapter beside six
byte-identical portable sources. Active `.15.7` owns the combined exact
provider/tool run. Complete VHDL breadth, PSL, qualified methodology support,
another simulator, mixed-language behavior, general parity, and scale remain
unclaimed.

Inspect or byte-check the six VHDL sources and eleven evidence artifacts with:

```text
perl scripts/refresh_vial_vhdl_portable_gallery.pl --check
```

Rerun the exact checked qualification under the repository RAM guard with:

```text
scripts/run_with_ram_guard.sh --process-max-rss-mb 4096 -- \
  perl scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check
```

Inspect the exact provider identity, additive adapter, mapping matrix, and
semantic-preservation proof without rewriting the checked gallery:

```text
perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check
```

The repository-local provider graph contains the OSVVM superproject plus 13
pinned gitlinks. Its evidence locks 14 Apache-2.0 licence files and finds no
notice file. The pinned `Documentation` gitlink has no tracked licence or
notice file; FSMGen records that absence and infers no legal coverage. The
code-bearing adapter is therefore reviewable and active under `.15.7`, but the
gallery alone is not analysis, elaboration, runtime, result, or parity proof.

The gallery lives at
`vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics`.
Its manifest explicitly records the older `vhdl-observation-package` as an
unchanged, unconsumed parallel compatibility surface.

Clean architecture audit commit `2e2f7d25e` activates only the exact
`.vial`/`VIALSemanticIR` contract leaf `.2` through a separate continuity
transition. Source syntax, semantic records, parser/report behavior, and the
first fixture remain unselected during activation.
Completed `.2` selects `.vial` version 1 as a closed span-aware S-expression
language with a dedicated parser rather than raw Lispish arrays. The initial
`core_directed_single_clock_v1` profile covers explicit packages/imports,
target-neutral two-/four-state types, typed transactions and unresolved DUT
binding assertions, deterministic models and fibers, bounded scoreboards,
coverage, substitution faults, stable random-decision identity, and directed
scenarios. `VIALSemanticIR` is private and immutable; only defensive sanitized
diagnostics/report projections are selected. Properties reuse the shared
`=>`/`next`/`within` vocabulary. Implementation `.3` now ships
`vial/ahb_subordinate_base_output_arbitration.vial`, the private semantic
frontend, defensive report, negative corpus, and bounded semantic-only support
claims. The exact contract is
[VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT](../../VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md).
Implementation `.5` also now ships the private in-process bridge producer.
Direct IAL0 and IAL1 use their canonical review routes; IAL2 emits protocol,
event, probe, and residue truth as an additive generated-IAL1 annotation that
the ordinary IAL1 parser and report validate before bridge consumption. The
result is a defensive JSON-safe 27-key manifest with stable logical IDs,
normalized types, exact review identities, full semantic provenance, backend
logical names, capabilities, limits, and explicit residue. It resolves every
checked AHB VIAL bridge reference without binding VIAL or exposing target
hierarchy. There is still no public CLI/API, bridge file, execution plan,
verification output, compile/simulation, backend-methodology, or parity claim.
Clean bridge-implementation commit `51434a2ae` permits the separate
continuity-only activation of `.6` for execution-contract selection. The
contract itself remains unperformed until activation commits cleanly; no VIAL
binding/ExecutionIR, plan/result artifact, scheduler, native extension,
backend, runtime, parity, or product behavior changes during activation.
Completed `.6` now accepts decision `0036` and selects target-neutral
`fsmgen.vial_execution_ir.v1` with exact bridge binding, drive/sample/react/
check logical time, deterministic fibers/ties/cancellation, plan-time
`sha256_counter_rejection_v1` random/replay values, declarative typed native
implementation manifests, defensive plan, normalized result/parity schemas,
diagnostics, limits, and the exact AHB oracle. The complete contract is
[VIAL_EXECUTION_IR_V1_CONTRACT](../../VIAL_EXECUTION_IR_V1_CONTRACT.md).
Proposed `.7` alone is selected next for separate clean activation of private
no-backend implementation; selection changes no product behavior.
Clean selection commit `eaf3f95dc` permits that continuity-only activation.
The activation committed cleanly at `3ec8eab93`, but pre-code audit `.7.1`
found that VIAL enum/Boolean/unsigned transaction types are not identical to
three HIAL four-state logic carrier types. Director-approved decision `0037`
and `.7.2` now select exact bit-domain identity, known-value injection, and
enum-encoding injection proofs. Clean selection commit `2a1b3cefc` activated
`.7.3`, which now ships the private binder, immutable
`fsmgen.vial_execution_ir.v1`, deterministic
`sha256_counter_rejection_v1` generation and strict replay, defensive in-
process `fsmgen.vial_plan.v1`, exact directional relation evidence, explicit
event/adapter bindings, resource limits, and atomic diagnostics. The checked
AHB plan has 21 operations, four total fibers, a three-fiber simultaneous
maximum, ten type relations, and one shared scenario decision occurrence.
Clean `.7.3` implementation commit `44dbecd1a` activates `.8` continuity-only
for public tooling-contract selection. No plan/result file, backend artifact,
compile, simulation, runtime,
parity pass, or target-methodology behavior ships in `.7.3`. See the
[type-binding mismatch audit](../../VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md).
The already-selected result and parity schema names are recorded as future
contracts with `.10`/`.11` owners, not as satisfied `.7.3` capabilities.


## Public Tooling Progress

Completed audit `.1` accepts decision `0032`: VIAL uses one public `.vial`
language, private `VIALSemanticIR` and `VIALExecutionIR`, and a versioned
`HIALVIALBridgeManifest`, with normalized result parity and independently
qualified backend profiles. Plain SystemVerilog/Verilator is the first
runnable target; current inert UVM/VHDL artifacts remain unchanged. The audit
decomposes exact leaves `.2`-.18 and selects proposed source/semantic-IR
contract `.2` alone for a separate clean activation. See the
[architecture audit](../../HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md)
and [architecture chapter](16d-hial-vial-verification-architecture.md).
Clean audit commit `2e2f7d25e` activates only `.2`; the contract itself and all
user-visible behavior remain unchanged during the continuity transition.
Completed `.2` accepts decision `0033`, freezes the exact spanned source,
typed semantic record, report/diagnostic, first-source, resource-limit, and
negative-boundary contract, and selects proposed implementation `.3` alone for
a separate clean activation. No source or parser ships in contract selection.
Clean contract commit `08f59167b` activates only `.3`; the implementation
remains unperformed until activation commits cleanly.
Completed `.3` ships the dedicated span-aware VIAL parser, semantic builder,
private immutable SemanticIR, defensive report, checked AHB source, exact
diagnostics/resource boundaries, and semantic-only capability/support entries.
It deliberately emits no bridge, execution plan, target artifact, or runtime
result. Director clarification during the slice is durable in decision `0034`:
VIAL is not synthesis-bounded, but it abstracts and simplifies the expressive
verification use cases of SV/UVM/VHDL instead of cloning their mechanisms.
Proposed `.4` is the next architecture leaf and still requires a separate clean
activation.
Clean semantic-frontend commit `be9c74163` activates only documentation
contract `.4`. The bridge schema, HIAL producer route, public reports/artifacts,
capability/support accounting, generated code, runtime, and product behavior
remain unchanged until contract selection commits separately.
Completed `.4` accepts decision `0035` and selects the exact review-routed
`HIALVIALBridgeManifest` v1 contract. Direct IAL0 and IAL1 project only their
validated facts. IAL2 must render protocol/event/probe/residue meaning into a
generated-IAL1 `(verification-bridge ...)` annotation and reparse it; PPIF may
not feed the bridge directly. Exact AHB IDs match the checked `.vial` source,
probes remain adapter-required without raw hierarchy, and `.5` is selected as
the private in-process/no-file implementation after separate clean activation.
No parser, annotation, bridge object, artifact, generated HDL, binding,
runtime, or product behavior changes in contract selection. See
[the bridge v1 contract](../../HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md).
Clean bridge-contract commit `0366dfe30` activates only private in-process/
no-file implementation `.5`. The parser, generated-IAL1 annotation, bridge
object/report, capability/support entries, artifacts, HIAL output, VIAL
binding, runtime, and product behavior remain unchanged until implementation
executes after activation commits cleanly.
Completed `.5` now ships that private producer through canonical HIAL review
routes without writing a bridge file or binding VIAL. Clean implementation
commit `51434a2ae` permits the continuity-only activation of `.6` for exact
`VIALExecutionIR`, deterministic logical-time, native-extension, plan, result,
and parity contract selection. Selection remains unperformed until activation
commits cleanly, and activation changes no product behavior.
Completed `.6` accepts decision `0036` and freezes the exact target-neutral
ExecutionIR/logical-time/random-replay/native/plan/result/parity contract.
SystemVerilog/UVM/VHDL methodology machinery remains backend-private; the
selected plan carries semantic outcomes and explicit target requirements.
The later clean activation and `.7.1`/`.7.2` audit-selection sequence led to
completed `.7.3`, which now ships private no-backend binding, immutable
ExecutionIR, deterministic random/replay, and defensive in-process plan
construction. No file, backend, runtime, parity, or target-methodology behavior
ships. See the
[execution v1 contract](../../VIAL_EXECUTION_IR_V1_CONTRACT.md).
Clean selection commit `eaf3f95dc` activated `.7` continuity only. Audit
`.7.1` then confirmed an exact-rule mismatch between three
expressive VIAL transaction types and their HIAL four-state hardware carriers.
Decision `0037` and `.7.2` select closed directional proof relations; `.7.3`
implements them after clean selection commit `2a1b3cefc` and a separate
continuity activation. Result/parity schema names remain selected future
contracts with explicit `.10`/`.11` owners, not satisfied `.7.3` capabilities.
Completed `.8` then selects the exact public `fsmgen vial` and portable API
contract under decision `0039`; completed `.9` selects the deterministic
known-value `sv_portable_verilator` backend contract under decision `0043`.
After clean activation and decomposition of `.10`, completed `.10.1` now ships
source-only `capabilities`, `check`, and canonical normal/terse `format` through
one defensive JSON-safe API. It adds no DUT binding, plan/artifact write,
generated backend, compile, runtime, result, or parity claim. Clean `.10.1`
commit `50a0d7d39` activates `.10.2` alone for canonical planning and atomic
repository-local or virtual artifacts. Completed `.10.2` now ships that
planner through direct IAL0, direct IAL1, and IAL2-via-generated/reparsed-IAL1
review routes. Transaction-free direct-IAL0 endpoint fixtures are admitted;
transaction-bearing fixtures still require exact reviewed transaction truth.
Clean `.10.2` commit `045629c97` activates `.10.3` alone as the portable
backend/trace implementation owner without changing product behavior.
Completed `.10.3` now ships a private deterministic
`sv_portable_verilator` emitter over the exact immutable ExecutionIR, reviewed
bridge, and normalized generated HIAL DUT source. It returns an eight-artifact
virtual plain-SystemVerilog graph, complete operation/state-family source maps,
one inactive-edge scheduler, generated declared-probe adapters, selected but
unexecuted compile/run command records, and honest emission-only manifests. A
separate pure validator checks closed canonical prefixed JSONL trace bytes and
returns a trace projection without replaying verification semantics. Public
artifact publication, external compile/simulation, runtime trace capture,
normalized result production, and parity do not ship; `.10.4` owns the first
four and `.11` retains parity. Clean `.10.3` implementation commit
`201590d84` activates `.10.4` alone without changing product behavior.
See [the public tooling contract](../../VIAL_PUBLIC_TOOLING_V1_CONTRACT.md) and
the [architecture chapter](16d-hial-vial-verification-architecture.md).
Completed `.10.4` now composes that private emitter/validator through public
`run`: exact Verilator 5.046 compile and execution, bounded repository-local
staging, validated runtime traces, normalized result/output manifests,
deterministic virtual or atomic publication, and exact cleanup all ship for the
selected known-value profile. Completed `.11` independently compares 19
public/shared AHB outcomes from generated VIAL and handwritten harnesses over
byte-identical DUT source. General cross-backend parity remains unclaimed.
