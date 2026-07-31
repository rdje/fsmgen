# HIAL/VIAL Verification-Fixture Architecture Audit

## Metadata

- Owner leaf: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1`
- Date: `2026-07-31`
- Status: `complete`
- Decision: `docs/decisions/0032-vial-uses-one-source-two-private-irs-and-a-versioned-hial-bridge.md`
- Product behavior: unchanged; this is an architecture/decomposition slice

## Outcome

FSMGen will retain the current synthesizable IAL0/IAL1/IAL2 stack under the
architectural name **HIAL** and add one peer verification language, **VIAL**.
VIAL will not mirror the three numbered HIAL source layers. The selected
topology is:

```text
HIAL source/review artifacts                 VIAL source
(.fsm / .isf / .ppif -> .isf -> .fsm)       (.vial)
                |                               |
                v                               v
        HIALVIALBridgeManifest           VIALSemanticIR
                \                               /
                 +---- bind + elaborate -------+
                              |
                              v
                      VIALExecutionIR
                              |
           +------------------+------------------+
           |                  |                  |
           v                  v                  v
   plain SystemVerilog   SystemVerilog/UVM   VHDL verification
   portable profile     qualified profile   qualified profile
```

The public `.vial` source is the reviewable verification-intent boundary.
`VIALSemanticIR` and `VIALExecutionIR` are private immutable compiler
boundaries. `HIALVIALBridgeManifest` is a bounded versioned public projection,
not raw compiler IR. A sanitized `vial-plan.json` and normalized
`verification-result-manifest.json` will provide review and parity surfaces
without exposing either private IR.

## Evidence Read

### HIAL layers and lowerings

- `README.md`, `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and mdBook Chapters 13h, 15, and
  16 establish `IAL2 -> IAL1 -> IAL0 -> HDL`, reviewable generated `.isf` and
  `.fsm`, and no direct IAL2-to-IAL0 route.
- `perl/FSM/Adapter/IAL2/PPIF.pm` parses `.ppif` and selected aliases, selects
  protocol-intent generators, emits generated IAL1 plus IAL0 bundles, and
  reports `direct_ial2_to_ial0 => 0`.
- `perl/FSM/Adapter/ISF.pm`, `perl/FSM/Scheduler/ISF.pm`, and
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` own parsed IAL1 and private scheduled
  lowering before `Emitter/FSM.pm` writes reviewable IAL0.
- `perl/FSM/Adapter/FSMGenFull.pm` coordinates IAL0/CoreAST parsing and signal
  analysis before the HDL pipeline.
- The SystemVerilog backend remains the broad reference backend. Direct VHDL
  currently converts the SystemVerilog-first scaffold through
  `perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm`; bounded composition VHDL uses
  `perl/FSM/Backend/VHDL/StructuralRTLIREmitter.pm`. `docs/VHDL_SCOPE.md`
  records the bounded and fail-closed boundary.

### Current verification-output boundary

- IAL1 `(observe NAME (role passive_monitor) (signals ...))` is single-clock,
  public-interface-only, parser-validated metadata. Lowering preserves it in
  `verification_observations[]`; it creates no scheduled state or HDL by
  itself.
- `perl/FSM/VerificationOutput/UVM/PassiveMonitorSkeleton.pm` emits UVM 1.2
  snapshot and monitor declarations plus an analysis port, but no `run_phase`,
  virtual interface, sampling, publication, driver, agent, scoreboard, or
  coverage behavior.
- `perl/FSM/VerificationOutput/VHDL/ObservationPackageSkeleton.pm` emits only
  declaration constants for observation metadata; it has no entity,
  architecture, process, assertion, PSL, sampling, scoreboard, or coverage.
- `perl/FSM/Support/VerificationOutputsSection.pm` and
  `VerificationOutputsContract.pm` publish two bounded targets and explicit
  UVM/VHDL compile, VHDL syntax, and PSL non-claims.
- `bin/fsmgen` accepts the two explicit `.isf`-only
  `--emit-verification-output` targets and keeps them separate from
  synthesizable `--language`, `--output`, and `--verify-hdl` modes.
- `docs/IAL1_DIRECT_IAL2_VERIFICATION_ROUTE_AUDIT.md` requires future IAL2
  protocol verification facts to lower or annotate generated IAL1 before
  verification output consumes them.

### Reference and tool constraints

- The tracked Accellera UVM 1.2 source mirror confirms distinct monitor,
  active/passive agent, sequence-item, analysis-port, and scoreboard roles.
  The existing skeleton has enough truth for class identity and fields, but
  not for executable component topology or sampled transaction flow.
- Accellera now publishes IEEE 1800.2 reference implementations in addition
  to historical UVM 1.2. Existing UVM 1.2 output therefore remains a
  compatibility fact, not an automatic version choice for future native VIAL:
  <https://www.accellera.org/downloads/standards/uvm>.
- Verilator documents that `--timing` supports its implemented delays, event
  controls, waits, and forks and supplies a timing evaluation loop. That makes
  it suitable for a fast event-capable compiled subset, not a complete
  SystemVerilog/UVM authority:
  <https://verilator.org/guide/latest/languages.html> and
  <https://verilator.org/guide/latest/connecting.html>.
- GHDL requires an explicit VHDL standard selection; VHDL-2008 and VHDL-2019
  are partially implemented, and PSL is a documented subset. A successful
  GHDL run must therefore report exact standard/options/capabilities instead
  of implying full VHDL/PSL coverage:
  <https://ghdl.github.io/ghdl/using/ImplementationOfVHDL.html>.
- OSVVM and UVVM both demonstrate that advanced VHDL verification is a
  methodology/library concern, not merely VHDL syntax. Methodology-provider
  selection belongs to a later VHDL backend contract:
  <https://osvvm.org/about-os-vvm> and <https://uvvm.github.io/>.
- Local audit tools: Verilator `5.046` is available; Yosys and Icarus Verilog
  are available; GHDL, NVC, `vcom`/`vsim`, VCS, Xcelium, and Qrun are absent.
  No absent tool is selected as current runnable evidence.

## Why VIAL Is Not VIAL0/VIAL1/VIAL2

HIAL's three source layers correspond to useful hardware authoring levels:
protocol/platform intent, scheduled actors/transactions, and explicit cycles.
Verification intent has different orthogonal axes: reusable type/transaction
declarations, DUT binding, scenarios, concurrency, checking, models,
scoreboards, coverage, and backend methodology. Splitting those axes into
three public source languages would force users to choose an artificial
abstraction level and would multiply migration, syntax, report, and backend
contracts before the first executable fixture exists.

One `.vial` language keeps reusable declarations and scenarios composable.
The necessary compiler separation is private and phase-based:

| Boundary | Phase | Owner | Invariant | Exposure |
| --- | --- | --- | --- | --- |
| `.vial` | authored source | shipped `fsmgen vial` tooling over private `FSM::VIAL::Parser` | complete source identity, normal/terse equivalence, and deterministic order | public/versioned source plus closed check/format/plan API |
| `VIALSemanticIR` | semantic intent | shipped private `FSM::VIAL::SemanticIR` family | typed, validated, immutable, not DUT-bound | private |
| `HIALVIALBridgeManifest` | report/contract projection | shipped private `FSM::HIAL::VIALBridge` family | sanitized HIAL truth with stable logical IDs and source maps | private producer; defensive public plan projection |
| `VIALExecutionIR` | bound execution plan | shipped private `FSM::VIAL::ExecutionBuilder` family | every reference bound, capability checked, deterministic operation graph | private |
| `vial-plan.json` | report projection | shipped `.10.2` public planner | sanitized binding/schedule/capability/source-map view | bounded public/versioned |

`VIALSemanticIR` is distinct from SourceHIR and HIAL IR because it represents
pure verification semantics, not a source route to synthesizable hardware.
`VIALExecutionIR` is distinct because DUT binding, logical clock phases,
scenario fibers, runtime models, and backend capability requirements do not
belong in unbound semantic intent. Both return defensive copies or sanitized
projections at caller boundaries; raw objects are not serialized publicly.

## HIAL/VIAL Bridge Contract

`HIALVIALBridgeManifest` is generated from the canonical HIAL pipeline and is
the only portable DUT-binding authority. Version 1 must contain these logical
families before a backend can claim support:

Decision `0035` now selects that version-1 schema and the initial
`core_single_unit_v1` profile. The exact route, generated-IAL1 annotation,
record shapes, stable IDs, provenance, limits, private first producer, and
non-claims are normative in
`docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md`.

| Family | Required facts |
| --- | --- |
| Identity | schema version; HIAL source kind and repo-relative identity; generated `.isf`/`.fsm` review identities; content/source-map identities |
| Units | stable logical unit IDs; module/entity names per supported HIAL backend; hierarchy/composition identity |
| Configuration | parameters/generics; resolved values; types; provenance |
| Types | two-state/four-state logic, signedness, width/range, enums, records/lists, and portable value encoding |
| Endpoints | logical endpoint IDs; direction; type; owning unit/interface; semantic role; backend port/binding names |
| Time domains | clock endpoint, active edge, reset endpoint, polarity, synchronous/asynchronous policy, and domain identity |
| Transactions/events | transaction ID; fields; request/accept/complete/sample events; ordering/correlation; endpoint mapping |
| Protocol facts | protocol/profile/version; channel/role facts; legal-value or timing facts; explicitly retained unsupported residue |
| Observations/probes | existing IAL1 observations; public-port observation sets; explicit HIAL verification probes; access/portability class |
| Backend bindings | logical ID to SystemVerilog module/path/interface and VHDL entity/port/adapter mapping |
| Capabilities | required backend/profile capabilities and explicit unsupported combinations |
| Source map | every bridge fact back to HIAL source and generated review artifacts |

The bridge distinguishes three access classes:

1. `public_port` is the mandatory cross-backend portable baseline.
2. `verification_probe` is explicitly declared by HIAL and carries a profile
   support matrix; it may be portable only when every claimed backend supplies
   a semantically equivalent adapter.
3. `native_hierarchy` is backend-specific and may appear only through a typed
   native extension. It cannot contribute to a portable parity claim.

For IAL2, the bridge may consume only facts present in or deliberately
annotated onto the generated IAL1 review route. It may retain original IAL2
provenance, but it does not call a verification backend directly from
`PPIF.pm` or create a second protocol truth source.

## Portable VIAL Semantics

The core semantic model includes:

| Family | Portable contract |
| --- | --- |
| Values and types | booleans, integers with selected bounds, two-/four-state scalars/vectors, enums, records, lists, and typed transaction records |
| DUT binding | bridge unit/interface/endpoint/domain/transaction IDs, configuration overrides, and capability requirements |
| Stimulus | typed drives, transactions, reset actions, waits, and bounded fault actions |
| Scenarios | reusable procedures, ordered steps, bounded loops, timeouts, setup/teardown, and deterministic parameters |
| Concurrency | logical fibers with join-all/join-any/cancel policies and deterministic tie-breaking; no host-thread semantics |
| Observation | explicit sample events and logical clock phase; public-port observations plus qualified probes |
| Expectations | immediate predicates, temporal windows, event counts, stable/changed checks, expected transaction streams, and termination contracts |
| Models | pure functions and explicitly declared deterministic state machines with typed state |
| Scoreboards | in-order, keyed, and explicitly bounded unordered matching with typed actual/expected streams |
| Coverage | points, bins, transitions, crosses, illegal/ignore bins, goals, and exact hit/count reporting; no implicit cross explosion |
| Fault injection | bounded value substitution, omission, delay, corruption, and protocol-event faults on declared targets; raw HDL force/release is native only |
| Randomization | explicit seeds, typed domains/distributions/constraints, stable decision IDs, and replay records |
| Diagnostics | source span, scenario/fiber/event identity, logical time, expected/actual values, backend profile, and stable code |

Portable logic distinguishes two-state and four-state values. The VHDL
backend must map additional `std_logic` states through an explicit policy
(normally unknown/error), and the SystemVerilog backend must not silently
coerce four-state checks into two-state UVM fields. Exact mapping is part of
the source/IR contract leaf.

## Logical Time And Determinism

Portable execution uses domain cycles and four logical phases rather than
target-language scheduling regions:

1. `drive`: actions become visible before the selected active edge;
2. `sample`: the backend captures the stable post-edge DUT observation;
3. `react`: scenario/model/scoreboard state consumes the sample; and
4. `check`: expectations, coverage, transcript, and termination commit.

Backend implementations may use clocking blocks, program blocks, processes,
delta cycles, or methodology callbacks, but must implement the same logical
ordering without races. Simultaneous events use stable domain ID, phase, fiber
ID, and source order. Zero-time unbounded loops fail closed.

Random choices are keyed by stable source/scenario/fiber/decision identity,
not by host thread or incidental callback order. A later contract must select
the exact cross-language algorithm and replay encoding before randomness ships.
Every generated artifact uses canonical ordering, stable names, normalized
line endings, and source maps.

## VIAL Expressiveness Is Not Synthesis-Bounded

HIAL's synthesizable lowering boundary does not apply to VIAL. The portable
logical core is the first interoperable profile, not the definition or
permanent expressive ceiling of verification intent. Qualified native profiles
may carry the full selected verification semantics of SystemVerilog/UVM or
VHDL, including methodology-level event and callback behavior.

This power is admitted through semantic compression, not target-language
cloning. A VIAL family must expose or compose verification intent; a one-to-one
renaming of SV/UVM/VHDL syntax, classes, or methods is rejected. UVM event-
callback intent, for example, owns interception, filtering, ordering,
lifecycle, reentrancy/cancellation, transformation, and observation semantics;
`uvm_event`/`uvm_event_callback` are backend mechanisms. The same rule keeps
phases/objections, sequences/sequencers, TLM, factories/config DB, RAL,
randomization/coverage/assertion facilities, and virtual interfaces/clocking
as compiler choices beneath lifecycle, orchestration, communication,
selection/substitution, configuration, register, decision, coverage/property,
and timed-interface intent.

In this architecture, abstraction specifically means simplification for the
author. Someone who has never learned SystemVerilog, UVM, or VHDL must be able
to master VIAL and obtain correct, efficient target implementations. The
compiler and backend own target expertise, methodology plumbing, scheduling
folklore, and artifact construction. Generated artifacts should remain
readable for backend diagnosis, but target knowledge is not a prerequisite for
authoring VIAL. Moving a gory target detail into VIAL under a different name is
an architecture failure, not abstraction.

The intended relationship is analogous to C/C++ or Rust and assembly:
SV/UVM/VHDL are VIAL backend target languages. Their output remains readable
and source-mapped for tool integration and diagnosis, but target idioms do not
define VIAL semantics or its authored vocabulary.

Specifically, VIAL lifecycle intent covers construction/configuration/readiness
dependencies, stimulus start, background-service lifetime, completion/drain,
shutdown, finalization ordering, deadlines, and failure policy. UVM phase
selection, raise/drop objections, and phase-transition calls are compiler-
generated backend plumbing rather than authored VIAL concepts.

Terse and verbose normal source forms must produce the same typed semantic
records. Capability negotiation fails before output when a backend has no
selected equivalent. Decision `0034` records the rule; proposed `.19` owns the
post-first-backend expressive-family taxonomy and detailed task decomposition.

## Typed Native Extensions

Portable `.vial` must not contain anonymous raw SV/UVM or VHDL blocks. A
native extension is an external repository-relative artifact with a typed
contract:

```text
id
backend_profile_ids[]
lifecycle_hook
typed_inputs[] / typed_outputs[]
required_capabilities[]
source_relpath / content_identity / source_span
deterministic_side_effects[]
required_or_fallback_policy
generated_artifacts[]
```

Lifecycle hooks are a closed family such as elaborate, build, drive, sample,
predict, compare, cover, and finalize. Extensions cannot mutate private IR or
undeclared DUT state. Their outputs and diagnostics enter the same result
manifest. Portable parity excludes backend-only extension behavior unless the
fixture supplies paired implementations and a shared logical outcome oracle.

## Backend And Validation Profiles

| Profile | Generated target | Required gate | Honest limit |
| --- | --- | --- | --- |
| `sv_portable_verilator` | plain SystemVerilog fixture, no UVM dependency | exact Verilator version; compile/elaborate/run with `--binary --timing`; transcript/result checks | only exercised Verilator-supported syntax/timing; not full LRM/UVM |
| `sv_uvm_qualified` | native SystemVerilog/UVM components, sequences, monitors, scoreboards, subscribers/coverage | named simulator/version, selected UVM revision, compile/elaborate/simulate, exercised capability list | unavailable locally; no claim until external profile runs |
| `vhdl_portable_ghdl` | VHDL-2008 testbench/packages/processes | installed GHDL/version, `--std=08`, analyze/elaborate/run, exercised capability list | unavailable locally; GHDL's VHDL/PSL implementation is explicitly partial |
| `vhdl_methodology_qualified` | VHDL plus selected methodology provider | provider/revision, compatible simulator/version, compile/elaborate/run, feature list | OSVVM versus UVVM and exact provider mapping remain a later choice |
| `mixed_language_qualified` | HIAL and VIAL in different HDLs | named mixed-language tool/version, binding adapter, compile/elaborate/run | never inferred from single-language success |

Plain SystemVerilog is the first implementation target because the AHB
harness already proves the relevant behavioral substrate under Verilator.
The UVM backend is a separate native target, not the portable runtime. Verilog
may remain a synthesizable HIAL compatibility output but is not a selected VIAL
fixture backend.

The current UVM 1.2 skeleton and VHDL observation package stay unchanged. A
future UVM backend contract must select its UVM revision instead of inheriting
`1.2` accidentally. A future VHDL contract must select pure VHDL-2008 versus
OSVVM/UVVM provider mapping and must first make GHDL or another analyzer
runnable. No full-language, PSL, methodology, or mixed-language claim can be
derived from artifact-shape tests.

Decision `0043` now freezes the exact first profile. It statically partially
evaluates the bound plan into a small runtime package and fixture module rather
than emitting a general interpreter. One scheduler samples at the inactive
clock edge, performs react/check work in plan order, then applies the next
drive before the active DUT edge. This avoids active-edge races without making
SystemVerilog regions or clocking-block folklore part of VIAL.

The reference gate is Verilator 5.046 with `--binary --timing --assert`, one
build/runtime thread, explicit `1ns/1ps` default timescale, deterministic X
concretization, explicit top and repository-local object root, and no blanket
warning suppression. The profile accepts only known-value semantics and
reports that it cannot observe complete four-state X/Z behavior. Declared
probes use generated, source-mapped backend adapters; authored raw hierarchy
remains forbidden. A closed prefixed JSONL trace is validated and projected to
the normalized result without moving VIAL execution semantics into the host.
The canonical detail is in
`docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md`.

## Cross-Backend Parity

Every backend emits `verification-result-manifest.json` with a normalized
logical transcript. Equivalent portable intent must agree on:

- VIAL source, bridge, plan, scenario, and capability-profile identities;
- seed and stable random-decision identities/values;
- logical domain-cycle/phase and event identities;
- driven and sampled portable values;
- transaction identity, fields, ordering, and correlation;
- expectation and temporal-check pass/fail plus expected/actual values;
- model and scoreboard outcomes;
- coverage point/bin/cross hit counts and goals;
- timeout, cancellation, completion, and final status; and
- unsupported/native-only exclusions stated in the manifest.

Backend text need not be byte-identical to another language. Waveforms remain
diagnostic evidence, not the semantic oracle. Parity compares canonical result
projections after target-specific paths, timestamps, and tool chatter are
normalized. A backend cannot claim a portable feature whose manifest contains
an unqualified native-only dependency.

## Worked AHB Arbitration Mapping

The source fixture is
`t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt`. The notation
below is architecture pseudocode, **not accepted `.vial` syntax**:

```text
fixture ahb_base_output_arbitration
  bind dut ahb_lite_subordinate via bridge ahb_base
  clock clk period 10
  reset rst_n active_low for 3 falling_edges

  scenario success timeout 256 cycles
    drive AHB_WRITE(address=0, transfer=NONSEQ, size=WORD,
                    data=0xcafebabe, wait_cycles=2)
    after accept: drive transfer=IDLE
    expect count(accept) == 1
    expect count(ready_low) >= 1
    expect count(completion) == 1
    expect always(response == OKAY and read_data == 0)
    expect storage_after == 0xcafebabe

  scenario unsupported_size timeout 256 cycles
    drive AHB_WRITE(address=0, transfer=NONSEQ, size=7,
                    data=0xffffffff, wait_cycles=1)
    after accept: drive transfer=IDLE
    expect count(accept) == 1
    expect count(error_response) == 2
    expect always(read_data == 0)
    expect storage_after == 0
```

Exact mapping:

| Handwritten fixture construct | Portable VIAL meaning | Native/probe boundary |
| --- | --- | --- |
| `always #5 clk = ~clk` | bridge-bound clock generator with period 10 | generated backend clock process |
| `reset_dut` and three negedges | reusable reset/setup procedure with domain-phase actions | none |
| public AHB signals | typed bridge endpoints and one AHB write transaction | protocol fields must be reviewable through generated IAL1 before bridge publication |
| `@(posedge clk)` counter updates | sample-phase events and counters | none |
| `@(negedge clk)` plus IDLE after accept | drive-phase reaction after sampled accept | none |
| `while (...) && cycles < 256` | timeout-bounded scenario wait/termination | raw hierarchy term must be replaced or qualified |
| bus acceptance predicate | portable event `HSEL && HREADY && HTRANS[1]` | none |
| HREADYOUT-low, HRESP, HRDATA | portable public-port samples and expectations | none |
| `$fatal` | typed expectation failure with code/source/logical time | none |
| `$display BASE_ASSERT_*` | normalized result metrics/transcript | backend text is not the parity oracle |
| `dut.ahb_phase_capture_en`, `hold_en`, `access_done_q` | optional named HIAL verification probes for capture/hold/completion | not portable until equivalent SV and VHDL probe adapters exist |
| `dut.ahb_phase_pending_q` | optional progress/termination probe | portable scenario should prefer externally observable ready/completion; hierarchy is native-only |
| `dut.reg_data_q` | optional storage probe | portable oracle should prefer a bridge-declared architectural-state probe or a follow-up bus read |

The portable pass/fail core uses public AHB behavior: exactly one acceptance,
stall observation, response timing, data behavior, completion/ready return,
and a readback or declared architectural-state probe. Exact internal capture,
hold, and completion counts remain useful diagnostic/coverage evidence, but
they cannot be called cross-backend portable while expressed as raw hierarchy.

The plain-SystemVerilog backend may render tasks, timed clock generation,
edge-controlled processes, counters, `$fatal`, and result emission much like
the current harness. The UVM backend maps the transaction to a sequence item,
driver, passive monitor, analysis stream, and scoreboard. The VHDL backend maps
it to typed records/procedures, clocked processes, assertions/results, and the
later-selected methodology provider. All must emit the same normalized
portable result projection for the shared scenario.

## Migration And Compatibility

1. Keep IAL0/IAL1/IAL2 public names, suffixes, commands, diagnostics, and
   synthesized output unchanged; HIAL is an architectural collective name.
2. Keep IAL1 checks/properties and decision `0008`'s one property language on
   the HIAL path. A later typed projection may reuse them in VIAL plans without
   creating a second grammar.
3. Treat current `(observe ...)` metadata as an initial bridge observation
   source. Do not make it a substitute for VIAL stimulus/scenario semantics.
4. Preserve `uvm_passive_monitor_skeleton` and
   `vhdl_observation_package_skeleton`, their CLI targets, paths, manifest v1,
   support entries, and explicit non-claims until a migration leaf selects a
   compatible replacement/version.
5. Add `HIALVIALBridgeManifest` and VIAL reports as new versioned artifacts;
   do not widen raw schedule/semantic hashes ad hoc.
6. Keep `.ppif` verification-output unsupported. IAL2 protocol facts enter the
   bridge only after a generated-IAL1 annotation contract makes them
   reviewable.
7. Keep native extensions external, typed, capability-qualified, and recorded
   in artifact/result manifests.

## Public Artifacts, Reports, And Accounting

Decision `0039` and `docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md` select and future
implementation must regression-lock:

```text
<out>/vial-tool-manifest.json
<out>/source/vial-normal.vial
<out>/review/...
<out>/hial-vial-bridge.json
<out>/vial-plan.json
<out>/verification-output-manifest.json       # run only, schema v2
<out>/backends/<backend-profile>/...          # run only
<out>/results/<run-id>/verification-result-manifest.json
```

The default root is repository-local and content-addressed by fixture plus the
full plan digest. The existing verification manifest v1 filename/schema stays
unchanged for generated `.isf` skeleton artifacts; VIAL runtime output uses an
explicit v2 schema, and migration is schema-selected and compatibility-tested.
The
bridge, plan, and result each need their own schema/contract owner, presence
key families, defensive-copy boundary, capability-manifest discovery,
diagnostics, and source maps. Support accounting distinguishes source/parser,
bridge, plan, backend artifact, compile/elaboration, runtime, parity, and scale
coverage; one source fixture cannot silently satisfy every family.

No output path may escape repository-derived same-volume policy in project
tests or default examples. External simulator libraries/licenses are exact
toolchain dependencies, not locations for project-owned outputs.

## Scalability Contract

Before claiming large VIAL designs, measure at least:

- HIAL units, bridge endpoints/types/domains/transactions/probes;
- VIAL declarations, scenarios, fibers, events, checks, model state, and
  transaction streams;
- scoreboard queue depth and match policy;
- coverage points, bins, explicit crosses, and hit-state size;
- random decisions and replay-log size;
- VIALSemanticIR/VIALExecutionIR nodes and source-map entries;
- generated files, lines, and bytes per backend;
- parse/type/bind/elaborate/emit/compile/simulate wall and CPU time;
- peak descendant RSS and external-tool resource use; and
- diagnostic completeness and bounded failure beyond qualified capacity.

Implementation must avoid implicit coverage-cross expansion, unbounded
scoreboards, schedule-order-dependent randomness, and one monolithic generated
file. Immutable shared IR, per-unit/package emission, streaming result events,
explicit caps, and deterministic failure are required design constraints.
Budgets and `big`/`really_big` workloads remain for exact scale leaves and the
separate `FSMGEN-END-TO-END-LARGE-DESIGN-SCALABILITY` tree; this audit does not
invent capacity numbers.

## Selected Follow-On Order

The owning task tree now decomposes exact leaves for:

1. `.vial` and `VIALSemanticIR` contract, then implementation;
2. `HIALVIALBridgeManifest` contract, then implementation;
3. `VIALExecutionIR`, deterministic execution, native extension, result, and
   parity contract, then implementation;
4. public CLI/artifact/report/capability/support-accounting selection;
5. plain-SystemVerilog/Verilator contract and implementation;
6. AHB fixture migration and portable runtime parity;
7. UVM contract/migration and qualified implementation;
8. VHDL/provider contract/migration and qualified implementation;
9. mixed-language qualification;
10. architecture-specific large-fixture scale proof; and
11. full user documentation and end-to-end matrix closeout.

The first source/IR contract and bounded implementation are complete. Bridge
contract `.4` selects decision `0035`, and completed `.5` now ships the private
in-process producer through direct IAL0, direct IAL1, and IAL2 only through an
additive generated/reparsed IAL1 annotation. The bridge exposes stable logical
IDs, normalized types and facts, source/review identities, full provenance,
defensive data, exact capabilities/limits, and explicit residue without a
bridge file, public API, VIAL binding, execution plan, backend artifact, or
runtime claim. Generated IAL0 and HIAL SV/VHDL behavior remain preserved.
Clean bridge-implementation commit `51434a2ae` permits a separate continuity-
only activation of `.6` for selection of the exact `VIALExecutionIR`, logical-
time, native-extension, plan, result, and parity contract. Activation changes
no compiler, schema, artifact, tool, runtime, parity, or product behavior;
activation commit `bf1e25274` then permits completed `.6` to accept decision
`0036` and `docs/VIAL_EXECUTION_IR_V1_CONTRACT.md`. The selection freezes one
target-neutral operational graph, drive/sample/react/check logical time,
deterministic action/fiber/model/scoreboard/coverage/fault behavior, plan-time
keyed randomness/replay, declarative typed native manifests, sanitized plan,
normalized result/parity, diagnostics, limits, and the exact AHB binding oracle.
Clean selection commit `eaf3f95dc` permitted the continuity-only `.7`
activation. Implementation audit `.7.1` then proved the
checked transaction is not bindable under the selected exact type-identity
rule. VIAL enum/Boolean/unsigned fields meet HIAL four-state logic carriers at
three field boundaries. `docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md` records
the direct evidence. Director-approved decision `0037` and `.7.2` select
closed bit-domain identity, known-value injection, and enum-encoding injection
proof relations. Clean selection commit `2a1b3cefc` permitted `.7.3` to own
implementation after separate continuity activation. Completed `.7.3` ships the
private immutable ExecutionIR, deterministic plan-time random/replay,
defensive in-process plan, closed event/adapter bindings, exact resource
accounting, atomic diagnostics, and private capability/support discovery.
The result/parity schema names remain selected future contracts with explicit
`.10`/`.11` owners rather than satisfied `.7.3` capabilities.
Clean `.7.3` implementation commit `44dbecd1a` permitted `.8` to select
decision `0039` and the public tooling contract after a separate continuity-
only activation. The selected `fsmgen vial` capabilities/check/format/plan/run
family uses equivalent normal/terse projections, separate VIAL/HIAL inputs,
portable source-catalog/artifact-sink requests, repository-local atomic output,
and explicit manifest-v1/v2 compatibility. No command/API/parser widening,
plan/result file, generated backend artifact, compile, simulation, runtime,
parity pass, or target-methodology behavior is shipped by selection. Clean
`.8` selection commit `d34da3254` activated `.9` alone for separate plain-
SystemVerilog/Verilator backend-contract selection. Completed `.9` now accepts
decision `0043` and the exact known-value backend/runtime contract. Clean `.9`
commit `ab3e73b72` activates `.10` alone for implementation; clean activation
commit `5fd766600` decomposes it into `.10.1` source tooling, `.10.2` planning,
`.10.3` backend/trace projection, and `.10.4` runtime/results. Completed `.10.1`
now ships capabilities/check/normal-terse formatting through the closed
source-only CLI/API with exact discovery and support accounting. Clean commit
`50a0d7d39` activates `.10.2` alone. Completed `.10.2` now composes all three
canonical HIAL review routes with the private binder, publishes canonical
normal source/review/bridge/plan/tool-manifest graphs virtually or through an
atomic repository-local transaction, and admits transaction-free endpoint
fixtures for direct IAL0 without inventing transaction meaning. Clean `.10.2`
commit `045629c97` activates `.10.3` alone for backend/trace emission without
runtime execution. Completed `.10.3` now ships the private deterministic
portable-SV emitter, eight-artifact virtual graph, full operation/state-family
source map, one-scheduler lowering, selected-but-unexecuted command records,
and pure closed-trace validator. Completed `.10.4` now ships public
publication, exact Verilator compile/run, validated runtime capture,
normalized results, deterministic reruns, and atomic cleanup. `.11` retains
cross-backend parity.

## Rollback

Rollback of this audit removes decision `0032`, this record, the selected
topology/book/fact continuity, and the proposed child decomposition, then
returns `.1` to active. It does not touch current IAL names, parsers, lowerings,
HDL backends, verification skeletons, CLI, manifests, support accounting,
tests, runtime behavior, or generated artifacts.
