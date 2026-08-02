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
  methodology/library concern, not merely VHDL syntax. Decision `0051`
  selects provider-free VHDL-2008 for the portable core and exact OSVVM
  2026.05 for the advanced tier; audited UVVM 2026.03.20 remains unselected:
  <https://github.com/OSVVM/OsvvmLibraries/releases/tag/2026.05> and
  <https://github.com/UVVM/UVVM/releases/tag/2026.03.20>.
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
| `sv_uvm_emit.accellera_2020_3_1` | complete reviewable simulator-neutral SystemVerilog/UVM environment artifacts | exact UVM reference identity, artifact/source-map/static-review/compatibility gates, explicit per-stage states | no inferred parse, compile, elaboration, simulation, or result claim |
| `sv_uvm_experimental.<tool-and-version>` | same native artifacts under an incomplete open-source tool | exact tool/version and exercised probe matrix | experimental evidence only; cannot qualify product runtime |
| `sv_uvm_qualified` | executable native SystemVerilog/UVM components, sequences, monitors, scoreboards, subscribers/coverage | exact PGEN parser + NEXSIM simulator tuple, handoff, UVM revision, parse/compile/elaborate/simulate/result gates | unavailable until capability-qualified releases exist; no invented version |
| `vhdl_portable_ghdl` | Provider-free VHDL-2008 packages, scheduler, adapters, testbench, closed trace/result | exact GHDL 6.0.0, `--std=08`, analyze/elaborate/run/result/parity, exercised capability list | selected but unavailable locally; GHDL's VHDL/PSL implementation is explicitly partial |
| `vhdl_osvvm_qualified` | Same VIAL semantics plus negotiated advanced OSVVM services | exact OSVVM 2026.05 recursive identity plus GHDL 6.0.0 and provider adapter/result gates | selected but unavailable locally; provider presence alone is not capability |
| `vhdl_*_qualified.<tool-id>` | Portable or OSVVM graph under another VHDL simulator | exact tool/version/build, standard/options, provider where applicable, compile/elaborate/run/result/parity | no broader simulator is inferred from GHDL evidence |
| `mixed_language_qualified` | HIAL and VIAL in different HDLs | named mixed-language tool/version, binding adapter, compile/elaborate/run | never inferred from single-language success |

Plain SystemVerilog is the first implementation target because the AHB
harness already proves the relevant behavioral substrate under Verilator.
The UVM backend is a separate native target, not the portable runtime. Its
full selected emission breadth can progress independently while PGEN's parser
and NEXSIM's simulator progress toward the exact future runtime tuple.
Experimental open-source tools may compile or elaborate the subsets they
support without becoming semantic or qualification authority. Verilog may remain a
synthesizable HIAL compatibility output but is not a selected VIAL fixture
backend.

The current UVM 1.2 skeleton and VHDL observation package stay unchanged. A
native UVM contract selects IEEE 1800.2-2020 / Accellera 2020-3.1 instead of
inheriting `1.2` accidentally. Decision `0051` now selects provider-free
VHDL-2008 plus an OSVVM-qualified advanced tier without promoting the inert
package. GHDL remains unavailable, so no full-language, PSL, methodology, or
mixed-language claim can be derived from this selection or artifact-shape
tests.

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
normalized results, deterministic reruns, and atomic cleanup. Clean `.10.4`
implementation commit `dfe87f536` activates `.11`. Completed `.11` now
qualifies the bounded AHB migration oracle over 19
public/shared result paths using independently executed handwritten and
generated-VIAL harnesses on byte-identical DUT source. Undeclared internal
capture/hold/completion observations are explicit exclusions, and general
cross-backend parity remains unclaimed.

## Native SystemVerilog/UVM Backend Version-1 Contract

Date: 2026-08-01

Owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12`

Status: selected by decision `0050`; implementation and executed qualification
remain owned by `.13`

### Outcome and authority

The methodology source contract is exact, while execution qualification is
deliberately tiered:

```text
near-term emission:       sv_uvm_emit.accellera_2020_3_1
experimental probes:     sv_uvm_experimental.<tool-and-version>
future runtime family:   sv_uvm_qualified
intended runtime tuple:  PGEN parser + NEXSIM simulator
```

The exact methodology identity common to all tiers is:

```text
target language:       SystemVerilog
methodology standard:  IEEE 1800.2-2020
reference library:     Accellera UVM 2020-3.1
upstream tag:          2020.3.1
upstream commit:       78c06547a2a0a29b3dc9dcafae62b75b2ff61544
emission state:        selected topology/lifecycle/notification structures shipped
runtime state:         unqualified; provider versions not yet available
```

Accellera's UVM download page identifies 2020-3.1 as the current reference
implementation for IEEE 1800.2. The official repository says that the kit
matches IEEE 1800.2-2020, records deviations, and is Apache-2.0 licensed. That
primary evidence justifies the exact emission source contract. It does not
justify a simulator claim.

The director's PGEN project owns HDL parsing and the director's NEXSIM project
aims to own open-source commercial-grade HDL simulation. Both are progressing
but remain under development. A future concrete `sv_uvm_qualified` profile is
therefore an exact tuple of PGEN version/content, parser-to-simulator handoff
schema, NEXSIM version/content, semantic-introspection API schema, MCP
protocol/profile, UVM library identity, commands, and exercised capabilities.
Those values are selected only when executable releases exist; inventing them
now would be false precision.

NEXSIM will expose deep semantic introspection through a clean API operated via
MCP. Qualification can therefore inspect structured simulator meaning instead
of treating logs and waveforms as its only evidence. The future provider
adapter may query source-mapped hierarchy, types and four-state objects,
process/event/scheduler state, assertions and coverage, and supported UVM
topology, phase, objection, factory, configuration, TLM, sequence, and RAL
objects. Selected controls may run, step, pause, break, checkpoint, replay, or
cancel an exact session.

That access is trustworthy only when the provider contract versions its
schemas, gives semantic objects stable replay identities, defines snapshot
consistency, orders and bounds every query deterministically, separates
side-effect-free inspection from explicitly authorized control, reports
permissions/capabilities exactly, and sanitizes errors and paths. The adapter
correlates NEXSIM objects through generated source maps to UVM artifacts,
`VIALExecutionIR`, and HIAL/VIAL semantic IDs. NEXSIM remains qualification
evidence rather than the authority over VIAL meaning, and no provider API is
emitted into canonical simulator-neutral SystemVerilog.

Commercial Xcelium, VCS, and Questa may later serve as optional comparison or
user-contributed profiles. They are not required FSMGen roadmap dependencies.
Verilator may serve the experimental tier, but its UVM ecosystem explicitly
says support is still in development; an experimental success cannot be
relabelled as full UVM authority.

Canonical emission is simulator-neutral IEEE SystemVerilog using only the
selected Accellera UVM contract. It contains no simulator-specific source,
`ifdef`, package, pragma, hierarchy API, command option, or workaround. A
provider-specific requirement is isolated in a declared adapter or private
command/evidence record, is capability-negotiated, and cannot alter canonical
source bytes or VIAL meaning.

### Dependency and licensing boundary

Ordinary deterministic emission records the exact UVM tag/commit/API identity
but does not require UVM library bytes, a network fetch, or an installed
simulator. Before any library-dependent parser, compile, elaboration, or
runtime gate, the responsible probe/qualification leaf must obtain the exact
open-source UVM source from the official Accellera repository into a
repository-derived same-volume dependency store such as:

```text
.cache/dependencies/accellera/uvm-core/
  2020.3.1-78c06547a2a0a29b3dc9dcafae62b75b2ff61544/
```

Once materialized, the complete file list, byte lengths, hashes,
`LICENSE.txt`, `NOTICE.txt`, tag, and commit enter a project-local dependency
manifest. Before then, the emission manifest reports `library_materialized:
false` and cannot claim any library-dependent gate. A pre-existing off-volume
checkout may be read only as an explicitly authorized source and must follow
copy/verify/use/delete for project-owned data. A user-home cache, ambient
`UVM_HOME`, network lookup during ordinary execution, mutable branch,
vendor-bundled UVM library, or UVM 1.2 compatibility package cannot silently
substitute for the selected bytes.

All selected near-term dependencies are open source. FSMGen does not make
commercial license availability a gate. If an operator later contributes a
commercial comparison run, tool/license material remains external and secret;
the result records only sanitized factual capability evidence. Ordinary open
CI always runs deterministic emission checks. Experimental open-source probes
run only when their exact tool is available and report `experimental`, while
future PGEN+NEXSIM qualification becomes mandatory for a runtime support claim
only after its integration child is explicitly activated.

### Semantic ownership and negotiation

The backend consumes the exact immutable `VIALExecutionIR`, reviewed
`HIALVIALBridgeManifest`, normalized generated HIAL DUT source, selected
native-extension descriptors, and pre-resolved random decisions. It does not
bind raw `VIALSemanticIR`, reinterpret HIAL names, invent protocol facts, or
make UVM's object graph the source of VIAL meaning.

Negotiation completes before any target artifact is published. It requires:

- the existing execution and bridge schema/profile identities;
- the concrete native backend profile above;
- a satisfied directional representation proof for every DUT binding;
- a closed classification for every portable, paired-native, native-only, and
  residual requirement;
- the exact UVM reference identity plus either a verified library content
  manifest or an explicit `not_materialized` state;
- emission-only status unless an exact experimental or qualified provider
  tuple is selected and available for `run`;
- finite resource bounds and repository-relative output roots; and
- no unknown native family, target fragment, raw hierarchy request, ambient
  callback, or unclassified side effect.

Failure returns an `unsupported` or `error` result envelope as appropriate and
publishes no partial backend graph. The backend cannot weaken a requirement,
switch UVM libraries, drop a source-map obligation, or recast a native-only
effect as portable to obtain a pass.

### Typed native intent record

Decision `0034` requires full target power below a simpler source surface.
Native family records therefore describe verification intent, not UVM APIs.
Every native semantic node refines the existing declarative extension carrier
with these common fields:

```text
semantic_node_id
family
identity
scope_id
lifetime
ordering
typed_inputs[]
typed_outputs[]
capability_ids[]
effects[]
failure_policy
source_location
```

`identity` is stable and source-derived. `scope_id` identifies a fixture,
scenario, component intent, transaction, register model, or declared service;
it is not a UVM hierarchy string. `lifetime` is one of `fixture`, `scenario`,
`transaction`, `notification`, or `operation`. Ordering is an explicit stable
rank plus dependency IDs. Inputs, outputs, effects, diagnostics, source maps,
and normalized results use the already-selected VIAL types and schemas.

The complete family taxonomy selected here is:

| VIAL intent family | Required semantic facts | Compiler-private UVM mapping |
| --- | --- | --- |
| notification/interception | notification and payload identity, registration scope, strict rank, filter, lifetime, reentrancy, cancellation, effects | `uvm_event#(T)`, one generated `uvm_event_callback#(T)` dispatcher, generated callback registry |
| lifecycle control | dependencies, readiness, service start/stop, completion/drain, shutdown, finalization, deadline, failure policy | build/connect/elaboration/start/run/extract/check/report/final phases and root-owned objections |
| stimulus orchestration | transaction/sequence intent, arbitration policy, parallelism, response/timeout/cancellation | generated sequence items, sequences, sequencers, drivers, virtual sequence coordination |
| producer/observer communication | typed publisher/subscriber identity, fanout/order/backpressure/loss policy | analysis ports/exports, TLM FIFOs, blocking/nonblocking TLM connections |
| implementation selection | abstract role, default implementation, scoped substitution, compatibility predicates | generated factory registration and type/instance overrides |
| scoped configuration | typed key, value, scope, precedence, required/default/locked policy | generated configuration objects and `uvm_config_db` set/get/check plumbing |
| register intent | address map, access/reset/volatility/prediction/frontdoor/backdoor policy | generated UVM RAL blocks, maps, adapters, predictors, sequences |
| constrained decisions | stable decision ID, domain, constraints, distribution, seed/replay, accepted value, exhaustion | generated sequence-item constraints and controlled `randomize()` only where selected |
| coverage/properties | sample event, typed expression, bins/crosses/goals/illegal policy, temporal property | covergroups/coverpoints/crosses and generated SVA bindings/checkers |
| timed interface interaction | domain, drive/sample edge and skew, directions, reset behavior, race policy | generated interfaces, modports, virtual interfaces, and clocking blocks |
| transactions/scenarios | typed fields, correlation, lifecycle events, scenario graph, fibers, deadlines | sequence items, sequences, agent topology, and controller services |
| analysis/models/scoreboards | consumed streams, deterministic state transition, matching/key/order/capacity policy | subscribers, analysis imps/FIFOs, generated model and scoreboard components |
| faults | target, activation window, substitution/perturbation, restoration, observability | generated driver/interface/model interception under declared access |
| results/diagnostics | logical identities/time, outcomes, native effects, evidence/exclusions | generated result collector/report catcher plus host-side closed projection |

This table is a mapping contract, not a source grammar. `.13.1` may emit
representative structures for every row from typed-IR fixtures before every
family has public VIAL syntax; `.19` still owns the complete post-first-backend
source taxonomy and leaf decomposition. The emission matrix distinguishes
private preview fixtures, publicly authorable paths, visually/static-reviewed
artifacts, experimental-tool outcomes, and qualified runtime. Broad generated
code therefore neither falsely claims full public VIAL breadth nor lets the
first runnable subset become VIAL's ceiling.

### Notification and interception semantics

Notification intent is more than a target event handle. A notification record
contains:

```text
notification_id
payload_type_id
scope_id
lifetime
persistence: transient | latched
trigger_policy: single | coalesced | queued
reentrancy: reject | queue
interceptor_ids[]
observable_effect_ids[]
source_location
```

An interceptor record contains:

```text
interceptor_id
notification_id
registration_scope_id
rank
filter
effects[]
lifetime
reentrancy
cancellation_policy
source_location
```

Registration is idempotent by interceptor identity. Two different
interceptors cannot share one `(notification_id, rank)`. The compiler sorts by
rank then stable semantic ID, and that order is VIAL meaning. Dynamic target
registration order, UVM callback-pool order, object allocation, and hash order
cannot replace it. Registration starts at the declared logical lifecycle seam
and ends exactly at lifetime finalization; late, duplicate, or stale
registration fails closed.

Filters are typed, side-effect-free predicates over the declared payload,
configuration, model state, and logical time allowed by the node. Effects are
closed instances of `observe`, `cancel`, `transform_declared_value`,
`notify_declared`, `record_coverage`, and `append_diagnostic`. Transformations
compose in strict interceptor order and must preserve the declared output type.
Cancellation stops the notification's trigger effect after all earlier ranked
effects commit; later interceptors are recorded as skipped. It does not
silently cancel a scenario, UVM phase, or unrelated event.

A notification triggered recursively while its dispatcher is live follows its
declared policy. `reject` produces a targeted runtime failure. `queue` appends
one typed occurrence to a bounded FIFO and drains occurrences in trigger order
after the current dispatch completes. There is no target-stack recursion.
Queue depth and total occurrences are bounded before result publication.

Completed `.13.1.2` realizes this contract for the checked AHB fixture through
one typed payload, interceptor record, `uvm_event#(T)` channel, exact
`uvm_event_callback#(T)` dispatcher, and registry. The dispatcher compiles
registration order by rank and semantic ID, freezes before triggering, clones
the immutable occurrence into an effective payload, records cancellation and
skipped successors, and uses exact queue-or-reject policy per generated
channel. Public VIAL v1 events own the six channel identities; the concrete
interceptor table remains a labelled private typed preview until public syntax
is selected.

The UVM backend creates one `uvm_event#(payload_object)` per notification and
one generated dispatcher derived from `uvm_event_callback#(payload_object)`.
The dispatcher owns the ordered VIAL interceptor table; it does not rely on
vendor callback order. `pre_trigger` performs ordered filters/effects and
returns cancellation to the UVM event only when VIAL cancellation requires
it. `post_trigger` records the committed occurrence and declared observation
effects. Generated payload objects are immutable to consumers after dispatch;
transform effects construct a new typed payload rather than permitting an
arbitrary callback to mutate shared state.

The normalized result records original/effective payload identities, each
evaluated interceptor and outcome, cancellation/skipped state, nested queue
depth, logical time, declared effects, diagnostics, and concrete backend
profile. UVM event timestamps, callback object addresses, and vendor trace
names are excluded.

### Lifecycle and logical-time mapping

Only the generated root test owns the run-phase objection. It raises once
after readiness and drops once after every selected scenario has committed a
terminal result and background services satisfy their drain contracts.
Generated child components never use free-form objection counts, automatic
phase objections, phase jumps, or target-specific drain time to define
completion.

The mapping is:

| VIAL lifecycle seam | UVM placement |
| --- | --- |
| elaborate | generated package/interface/top construction before `run_test` plus component `build_phase` |
| configure | typed configuration construction and config-DB publication in `build_phase` |
| connect | compiler-owned component and TLM connections in `connect_phase` |
| readiness | validation in `end_of_elaboration_phase` and `start_of_simulation_phase` |
| drive/sample/react/check | controller, sequences, driver/monitor clocking-block operations during `run_phase` |
| drain/shutdown | root-test completion controller before its single objection drop |
| finalize | `extract_phase`, `check_phase`, `report_phase`, and `final_phase` with no semantic mutation after result seal |

The existing logical tuple `(domain, cycle, phase, ordinal)` remains the only
portable time. The generated interface has separate driver and monitor
clocking blocks whose skews are selected to implement drive-before-edge and
stable post-edge sample behavior. A generated controller commits react/check
effects in static VIAL order. UVM process wake order, simulation regions,
delta counts, and timestamps are recorded only as optional backend evidence.

Portable plan-time decisions remain fixed; the backend may not rerandomize
them. A later native constrained-decision node may use the UVM/SystemVerilog
solver only when its constraints, seed, attempt policy, accepted normalized
value, and replay behavior are selected. Solver identity then enters native
capability evidence, and portable parity requires replaying the accepted value
rather than assuming solver equivalence.

### Component and communication graph

The compiler emits the smallest graph required by selected intent. The maximum
role graph is:

```text
generated test
  generated environment
    one generated agent per timed interface role
      sequencer (only when stimulus is selected)
      driver    (only when stimulus is selected)
      monitor   (only when observation is selected)
    generated reference-model components as selected
    generated scoreboard components as selected
    generated coverage subscribers as selected
    generated result collector
```

Passive intent never creates a sequencer or driver. A fixture with no RAL,
coverage, model, or scoreboard intent emits none of those components. The
backend does not create one UVM class per VIAL operation; it groups stable
typed operations into tables/services to keep compilation and runtime cost
proportional to selected semantic families.

Sequence items mirror VIAL transaction field types and identities but do not
become semantic authority. Drivers translate items through proved HIAL carrier
relations and generated virtual-interface bindings. Monitors sample via
clocking blocks, correlate transactions using bridge rules, and publish
immutable transaction objects. Analysis fanout uses generated TLM connections;
model and scoreboard order remains explicit when VIAL says order matters.

Factories and `uvm_config_db` are compiler plumbing. A VIAL author selects a
typed role substitution or scoped configuration value. The compiler proves
type/scope compatibility, emits the factory/configuration operations, verifies
the selected instance graph during readiness, and reports the semantic IDs.
Authored source never spells a UVM type name, wildcard hierarchy pattern,
factory API, or config-DB precedence rule.

Register intent similarly owns logical maps, fields, access policy, reset
values, volatility, prediction, and frontdoor/backdoor choice. The backend may
emit RAL objects, adapters, predictors, and sequences only for selected facts.
Raw backdoor paths require a declared HIAL probe/native-access capability and
cannot be inferred from generated hierarchy.

### Coverage, properties, faults, and results

Portable coverage keeps its normalized bin/cross identity and hit-count
oracle. Native coverage may add capability-qualified automatic, transition,
wildcard, or implementation-specific collection only when the semantic node
states the exact sampling and result contract. Generated covergroups are
sampled from the VIAL event, not from an arbitrary UVM callback.

Properties retain the shared VIAL/HIAL temporal meaning. The backend may emit
SVA into a bound checker/module and route failures into the result collector.
A simulator assertion pass is separate from UVM scenario success; both gates
must pass. Raw assertion text is never accepted as a native node.

Fault intent names a declared target and finite activation/restoration
contract. The backend may intercept a driver value, model result, register
access, or declared interface/probe only with the corresponding capability.
Force/release, deposit, raw VPI, and hierarchy mutation are native residuals
that require a later typed access contract; they are not inferred from
`native SystemVerilog`.

Every successful execution produces the existing
`fsmgen.verification_result_manifest.v1`. Native event/interceptor records use
the `native_extensions` stream with stable semantic IDs, logical time, typed
original/effective values, effects, cancellation, and shared outcome oracle
where paired portability is claimed. Backend evidence records UVM library,
tool, compile, elaboration, simulation, transcript, assertion, coverage, and
artifact identities. It never places absolute paths, license data, object
handles, or raw vendor diagnostics in the public result.

### Residual-intent taxonomy

Every requested behavior must be classified before emission:

| Class | Meaning | Examples |
| --- | --- | --- |
| `portable_semantic` | already defined by target-neutral ExecutionIR and eligible for ordinary parity | scenarios, logical time, fixed decisions, typed transactions, deterministic scoreboards |
| `native_typed` | VIAL intent with this contract's exact UVM mapping | notification/interception, scoped substitution, RAL, native constraint or coverage family |
| `compiler_plumbing` | generated mechanism with no authored semantic identity of its own | UVM component registration, phase methods, objections, TLM wiring, config-DB calls |
| `typed_external_extension` | separately reviewed content-addressed implementation with declared effects | approved third-party checker/model adapter |
| `qualification_only` | evidence mechanism that cannot alter verification meaning | parser/simulator options, transcript capture, coverage database export, waveform dump |
| `unsupported_residual` | target capability with no selected VIAL intent/access/result contract | arbitrary raw SV, arbitrary callback code, phase jump, DPI/VPI, force/release, unbounded process spawn |

Unknown and unsupported residuals fail capability negotiation. They cannot be
hidden in a generated helper, extension artifact, command option, or vendor
configuration file. `.19` may promote a residual only by selecting a typed
intent, lifecycle/effect/result contract, source form, capability, tests, and
backend mappings.

### Artifact graph and generated-code quality

The shipped `.13.1.3` structures compose with the existing atomic artifact
transaction and emit this exact deterministic twelve-artifact graph:

```text
backends/sv_uvm_emit.accellera_2020_3_1/
  backend-manifest.json
  backend-source-map.json
  evidence/methodology-profile.json
  evidence/static-validation.json
  src/fsmgen_vial_uvm_types_pkg.sv
  src/fsmgen_vial_uvm_components_pkg.sv
  src/<fixture>_if.sv
  src/<fixture>_notifications_pkg.sv
  src/<fixture>_services_pkg.sv
  src/<fixture>_pkg.sv
  src/<fixture>_tb.sv
  src/dut/<generated-hial-dut>.sv
```

The private `FSM::VIAL::Backend::SVUVMAccellera2020_3_1` emitter consumes the
same immutable ExecutionIR, bridge manifest, and deterministic HIAL DUT input
as the portable backend. `FSM::VIAL::Backend::SVUVMStaticValidator` checks the
closed roles, limits, provider neutrality, deterministic text shape, balanced
generated constructs, selected UVM foundation shape, notification/callback
shape and bounds, complete active topology/lifecycle shape, typed stimulus and
service shapes, exact TLM/factory/configuration/RAL wiring, and the single
root-owned objection policy. The native source map uses
`fsmgen.vial_uvm_backend_source_map.v1` and records exact start/end line and
column ranges for the agent, sequencer, driver, monitor, controller, collector,
dispatcher, registry, six event-channel instances, sequences, TLM services,
and private RAL preview. The graph has 64 mapped entries and passes 12 static
checks. The checked gallery under
`vial/review_gallery/sv_uvm_emit.accellera_2020_3_1/ahb_base_output_foundation/`
is byte-compared with every rerender. The graph can publish atomically and
rejects non-identical collisions; focused tests remove the exact graph and
prove no operation-owned staging residue.

There is intentionally no command record, UVM-library byte manifest, or result
artifact in this emission-only graph. Those appear only in a later exact
experimental or qualified library-dependent gate. The methodology profile
records `not_requested_or_inspected`, no network fetch, and the exact point at
which a verified project-local Accellera copy becomes mandatory.

Additional generated package files are split by semantic family only when a
measured size threshold requires it. Stable content and plan identity produce
byte-identical source, source maps, and command records. The backend uses
meaningful semantic-derived identifiers, one class per reusable role rather
than operation, explicit constructors/connections, and restrained macros.
Generated files contain no absolute paths, timestamps, license values,
addresses, random suffixes, or unbounded copied prose.

Quality requirements are:

- every class, interface, package, method, field, connection, generated
  constraint, coverpoint/bin/cross, property, notification/interceptor table,
  RAL element, and result record maps to one or more VIAL semantic IDs;
- compiler-only plumbing maps to a synthetic stable owner and the semantic
  nodes it serves;
- generated spans include artifact path, start/end line, and start/end column;
- lines are at most 240 bytes and generated package/class files are split
  before 2,000/1,000 lines respectively;
- repeated declarations use tables/helpers where that preserves readable
  target code and exact source mapping;
- no field macro, factory macro, or dynamic reflection is emitted merely for
  convenience when explicit code is clearer or measurably cheaper; and
- canonical source contains no simulator-specific conditional, package,
  pragma, API, workaround, or provider spelling; and
- deterministic rerender, compile cost, peak descendant RSS, runtime, source
  bytes, class/component counts, and result bytes enter qualification metrics.

These are review and scale gates, not ceilings on VIAL intent. If a legitimate
fixture exceeds the first backend's safety limits, the result is an explicit
bounded unsupported diagnostic and a later measured limit/architecture owner,
not silent truncation or a claim that VIAL cannot express it.

All compilation objects, dependency copies, command files, logs, transcripts,
waveforms, coverage databases, and staging work remain under repository-
derived `.artifacts/` or `.cache/` roots on the repository volume. Exact owned
staging is removed after publication; persisted artifacts remain declared and
hashed. The backend never defaults to `/tmp`, a user-home cache, or an
off-volume vendor work directory.

### Compile, elaboration, simulation, and capability gates

Near-term `.13.1` is broad emission with honest per-stage maturity. Its
required order is:

1. **identify reference** — exact Accellera tag/commit/API identity and an
   explicit not-materialized or verified local-library state;
2. **negotiate** — exact schemas, typed families, mappings, residual classes,
   limits, and explicit `compile/elaborate/run/result: not_run` states;
3. **emit** — deterministic source, artifact manifest, complete source map,
   and provider-neutral command requirements without pretending an executable
   command exists;
4. **validate shape** — parse-independent closed artifact, identifier,
   package/import, class/topology, no-raw-target-input, and compatibility
   oracles, with no syntax/compile claim;
5. **publish review gallery** — representative full-shaped environments and
   exact public-authoring/private-preview status for human inspection;
6. **rerender** — identical inputs and exact emitter identity produce
   byte-identical native source, source maps, manifests, and requirements;
7. **publish** — atomic repository-local graph and exact failure cleanup; and
8. **census** — no off-volume, temporary, partial, or undeclared residue.

Completed `.13.2` freezes exact Verilator 5.046 plus CHIPS Alliance
`uvm-verilator` `uvm-2020-3.1-vlt` commit
`656f20d087370a7c742e00188d20bbf30fa95339` and tree
`882930bb7debe79b22234e4a8a53854549046778`. Its reusable bounded probe runs
preprocessing, parsing, library compile/elaboration, control runtime,
full-fixture compile/elaboration attempts, and cleanup as independent stages.
Every outcome remains labelled `experimental`; `UVM_NO_DPI`, attempt-local
unsupported-feature blackboxing, unsupported constructs, failures, and stage
skips are first-class evidence. A deterministic checked report records exact
argv and ownership. Product support discovery does not advertise these results
as qualified.

The selected UVM library and minimal test preprocess, parse, compile,
elaborate, and reach `run_phase` with zero UVM errors and fatals. Full generated
fixture preprocessing also passes. The first strict parser run exposed one
FSMGen defect—illegal use of SystemVerilog keyword `context` as an identifier—
which is repaired as `vial_context` in the canonical gallery. After repair,
strict parsing reaches Verilator's unsupported ranged-SVA delay; an explicit
`--bbox-unsup` compile/elaboration attempt reaches a Verilator internal fault
with exit 139. Fixture runtime, result, parity, four-state semantics, and full
UVM breadth remain unexercised. The report therefore concludes
`partial_tool_limited` with `product_support=false`.

This is an architecture-first convergence loop:

```text
typed VIAL meaning and UVM mapping
  -> deterministic full-shaped source
  -> structural checks and visual review
  -> exact open-tool parse/compile/elaboration where supported
  -> later qualified parser/simulator compile/elaboration/runtime
  -> generator syntax/strategy refinement without semantic drift
```

Generated UVM is compiler output, not a hand-authored source-compatibility
surface. FSMGen may revise standards-compliant syntax, helper decomposition,
macro use, class structure, or expression form to incorporate review and tool
feedback. Each artifact records the exact FSMGen/emitter identity, so
determinism is exact-version relative. A representation-only rewrite that
preserves VIAL meaning, public artifact schema, declared capability, and
source-map obligations needs regression evidence but not a new VIAL semantic
version. A semantic, profile, public artifact-schema, or compatibility change
does require explicit versioning.

Future `.13.3` activates only when usable PGEN and NEXSIM releases exist. It
must then select and execute this exact order:

1. **discover tuple** — exact PGEN and NEXSIM version/content/executable
   identities plus the parser-to-simulator handoff, semantic-introspection API,
   and MCP protocol/profile schemas;
2. **parse** — PGEN accepts every selected UVM/library/fixture source and
   produces the exact validated handoff;
3. **compile library and fixture** — NEXSIM consumes the selected UVM bytes and
   generated units without substituting a library;
4. **elaborate** — exactly one selected top and complete component/interface
   graph elaborate;
5. **simulate** — bounded execution exits cleanly with no UVM fatal/error,
   assertion failure, timeout, or trace overflow;
6. **correlate semantic checkpoints** — snapshot-consistent NEXSIM semantic
   objects map through generated source maps to UVM, HIAL, VIAL, and applicable
   IASIM/portable checkpoint identities; the first divergence is localized and
   classified rather than hidden by a final mismatch;
7. **validate result** — closed native trace/result schemas, scenarios,
   notification/interception outcomes, and capability evidence validate;
8. **rerun** — identical inputs reproduce portable/native projections and
   deterministic artifacts; and
9. **cleanup** — exact staging removal and residue census pass.

Compile success does not imply elaboration; elaboration does not imply run;
zero simulator exit does not imply UVM/result success; UVM success does not
imply portable parity; one profile does not imply another simulator; and no
bounded test implies complete IEEE 1800/SystemVerilog or UVM breadth.

The minimum honest capability records are:

```text
vial.backend.sv_uvm_emit.accellera_2020_3_1
vial.backend.sv_uvm.source_map.v1
vial.backend.sv_uvm.notification_interception.emitted
vial.backend.sv_uvm.static_review: passed
vial.backend.sv_uvm.visual_review: pending | reviewed
vial.backend.sv_uvm.compile: not_run
vial.backend.sv_uvm.elaborate: not_run
vial.backend.sv_uvm.run: not_run
vial.backend.sv_uvm.result_manifest: not_produced
vial.backend.sv_uvm_qualified: unavailable
```

Each entry records `emitted`, `reviewed`, `experimental`, `exercised`,
`passed`, `missing`, `unavailable`, `not_run`, or `not_selected` plus evidence
IDs and the exact emitter/tool identity. Capabilities for
PGEN parsing, NEXSIM compilation/runtime, phases/objections, sequences, TLM,
factory/config DB, RAL, constrained randomization, coverage, assertions, and
other families are claimed only when a focused executable oracle actually
uses them. Product discovery cannot advertise a merely documented row as
implemented.

### UVM 1.2 compatibility and migration

The existing command remains a frozen compatibility surface:

```text
./bin/fsmgen --emit-verification-output uvm-passive-monitor \
  --verification-outdir DIR source.isf
```

It continues to emit `uvm/<actor>_observation_uvm_pkg.sv`, manifest target
`uvm_passive_monitor_skeleton`, `uvm_version: 1.2`, inert snapshot/monitor
classes, and explicit `claimed_uvm_compile_support: false`. No native backend
file overwrites or imports that package, and native qualification does not
retroactively change its validation object.

Native VIAL output uses the separate emission profile graph above. Where an
IAL1 `(observe ...)` declaration and VIAL monitor intent refer to the same
bridge observation, `.13.1` may reuse the stable observation and signal IDs as
input provenance. It must generate a new executable native monitor in the
native package, not mutate, wrap by accidental name, or claim compilation of
the legacy artifact.

Compatibility states are therefore exact:

| Surface | Revision | Behavior | Qualification |
| --- | --- | --- | --- |
| `uvm-passive-monitor` | UVM 1.2 | inert declarations only | shape/inertness tests; no compile/run claim |
| `sv_uvm_emit.accellera_2020_3_1` | IEEE 1800.2-2020 / Accellera 2020-3.1 | deterministic selected topology, lifecycle, notification/interception, stimulus, TLM, scoped factory/configuration, private typed RAL/native-decision previews, coverage, bound SVA, models, scoreboard, fault, diagnostics, and result collection | emission/source-map/static-structure only; compile/run/result explicitly not run |
| future `sv_uvm_qualified` PGEN+NEXSIM tuple | same selected UVM identity unless explicitly revised | executable native intent lowering | unavailable until `.13.3` selects and passes the exact tuple |

A future CLI alias, UVM 1.2 deprecation, upgraded passive-monitor target,
legacy compile gate, or shared package requires a separate compatibility leaf,
new artifact/manifest version where bytes change, mdBook migration examples,
and exact old/new regression fixtures.

### First implementation boundary and non-claims

Completed container `.13.1` owns complete selected reviewable emission through
five bounded children. `.13.1.1` establishes the emitter, artifact graph, source
maps, static validators, and first gallery. `.13.1.2` closes topology,
interfaces, lifecycle, and notification/interception. `.13.1.3` adds
stimulus/sequences/TLM/factory/configuration/RAL/constrained-decision shapes.
Completed `.13.1.4` adds coverage/properties/models/scoreboards/faults,
diagnostics, and result collection. Completed `.13.1.5` closes the selected
mapping matrix, examples, visual-review workflow, and deferred-runtime defect
boundary. None waits for full simulation merely to emit more of the selected
architecture.

An authored construct may name only VIAL intent and types; no
SystemVerilog/UVM class, method, phase, objection, hierarchy pattern, or
command option appears in authored source. Where `.19` has not yet selected a
public source form, `.13.1` may exercise a typed-IR preview fixture but must
label it non-authorable and withhold the corresponding public capability.
`emitted`, `static_reviewed`, `visually_reviewed`, `experimental_compiled`,
`experimental_elaborated`, and `qualified` are separate states.

Broad source emission does not claim a produced normalized runtime result,
full public VIAL source breadth, or error-free SystemVerilog/UVM. It does not
claim PGEN parse, NEXSIM compile/runtime, another simulator, vendor-bundled
UVM, UVM 1.2 runtime, full SystemVerilog LRM conformance, analog/mixed-signal
behavior, or all IEEE 1800.2 optional/deviation behavior. Review or later tool
findings are fixed in the generator or recorded as exact task-tree defects;
they do not retroactively turn early emission into a runtime claim.

Completed `.13.1.1` established the deterministic private emitter, exact
methodology record, initial source map, structural validator, checked gallery,
atomic publication, and cleanup. Completed `.13.1.2` expands that graph to
typed lifecycle/reentrancy/filter/effect records, a context-owning agent base,
passive monitor and agent, lifecycle controller, result-collector structure,
complete environment/test construction, one root-owned objection pair, and
ordered typed notification/interception channels with bounded queue-or-reject
reentrancy.

Completed `.13.1.3` changes the selected agent from passive to active and adds
one typed write item, sequencer and driver, two generated public scenario
sequences, driven and observed analysis streams, typed TLM FIFOs and subscriber,
exact scoped configuration paths, one compiler-selected driver factory
override, and a monitor-connected private RAL block/adapter/predictor preview.
Portable constrained-decision values are replayed without UVM rerandomization;
the isolated bounded native solver preview is not invoked by generated
scenarios. The revision-3 graph contains 12 artifacts, eight SystemVerilog sources,
64 source-map entries, 12 static checks, and seven byte-locked UVM-facing
gallery sources.

Completed `.13.1.4` adds the public two-bin `stall_seen` covergroup, two
deterministic event-counter instances, the capacity-four in-order `writes`
scoreboard, exact public expectation construction, one-drive-interval
`size=3'b111` substitution, public property-outcome collection, a separately
bound 1-to-256-cycle SVA checker, defensively copied diagnostics, and a
structured review snapshot. Driver, monitor, controller, checking components,
and result collector are wired through typed non-wildcard paths. The width-
aware scalar validator now also renders exact one- and two-bit notification
predicates that the revision-3 whole-nibble mask check incorrectly left as
typed-but-unexecuted channels.

Revision 5 now contains 16 artifacts, ten SystemVerilog sources, 75 source-map
entries, 14 static checks, and nine byte-locked UVM-facing gallery sources.
The structured collector remains generated review code: no runtime executes,
no verification-result manifest is produced, and probe-backed expectations
remain source-mapped until a qualified adapter supplies observation.

The two new canonical JSON artifacts close selected-scope accounting without
changing generated SystemVerilog. A 25-row matrix equals the manifest's
emitted-foundation set and separates normal/terse public source, public or
compiler-owned ExecutionIR, and private typed previews. A seven-stage workflow
defines repository-relative regeneration and non-mutating byte checks, pending
director/delegated visual review, exact durable defect fields, and separately
not-run experimental compile and qualified-runtime stages. Five internal
invariants reject incomplete roles, entry-point drift, workflow drift, or an
accidental qualification claim.

Ordinary-emission preprocessing, parse, UVM-library compile, fixture compile,
elaboration, runtime, result, parity, visual-review completion, public
interceptor, RAL, or factory-override authoring, produced results, and full
native UVM breadth remain explicitly unclaimed. Selected mapping-matrix and
deterministic review-workflow closure now ship; visual judgment does not. The
separate `.13.2` experimental report records its partial evidence without
changing those product stage states or blurring emission truth.

Verilator and other available tools can catch whatever they support early.
`.13.3` alone is blocked until PGEN and NEXSIM expose the required exact
releases, handoff, and capabilities. An experimental parse, compile, or
elaboration result cannot discharge that runtime blocker.

## Completed VHDL contract selection

Completed `.14` accepts decision `0051` and selects a two-tier VHDL
architecture. `vhdl_portable_ghdl` is provider-free IEEE 1076-2008 and exact
GHDL 6.0.0 is its first selected qualification tool. The exact release identity
is tag `v6.0.0`, annotated object
`ecfa637741fe259d284dc0b20936acc15bba44df`, peeled commit
`e589c698c351369ac5bcfe7abe1f1152ac5d4727`. The tool is absent locally, so
the profile is selected and unexecuted.

`vhdl_osvvm_qualified` selects OSVVM 2026.05 at commit
`2f7c391051dfb11890fa4bdbda9918d1db492250` for negotiated advanced
randomization, coverage, scoreboards, reporting, synchronization, data
structures, and verification components. The provider is a recursive
superproject; implementation must verify the top commit, every gitlink,
content/license/notice identity, and repository-local dependency root before a
provider-dependent gate. UVVM 2026.03.20 at commit
`4f1e13bf96dca5571597ca7416b9340e9de94efd` was audited but is not selected;
adding an overlapping second provider would double adapter/qualification
surfaces without a demonstrated version-1 semantic benefit.

The portable core itself owns typed drivers, stable-barrier sampling, static
scenario/fiber scheduling, deterministic models, bounded scoreboards,
functional-coverage counters, substitution faults, procedural properties,
closed trace records, and normalized results. OSVVM can implement only exact
negotiated native/advanced requirements or supplementary reports. It cannot
rerandomize plan-resolved decisions, change drive/sample/react/check ordering,
redefine comparison/bin semantics, or replace the normalized parity oracle.

The portable backend schema is `fsmgen.vial_backend.vhdl_portable.v1`; the
advanced schema is `fsmgen.vial_backend.vhdl_osvvm.v1`. Broader simulator
families are named `vhdl_portable_qualified.<tool-id>` and
`vhdl_osvvm_qualified.<tool-id>`. Every broader profile freezes the exact
tool/version/build, standard/options, provider identity where applicable,
commands, exercised capabilities, normalized result/parity gates, and limits.
GHDL evidence cannot silently qualify another simulator.

| VIAL responsibility | Provider-free mapping | OSVVM-qualified extension |
| --- | --- | --- |
| drive | typed procedures and generated adapter ports | Model Independent Transaction or verification-component adapter only when negotiated |
| sample | one stable-barrier scheduler over declared ports/probes | provider synchronization may coordinate components but cannot move the barrier |
| scenario/fibers | statically evaluated rank/state tables | provider completion projects back into the same ranks |
| model | pure functions/procedures and bounded state | exact negotiated memory/FIFO utility only |
| scoreboard | bounded generated queues and typed comparison | `ScoreboardGenericPkg` for advanced/native requirements |
| coverage | generated VIAL bin/cross counters | `CoveragePkg` plus supplementary provider reports |
| random decisions | consume plan-resolved keyed values | `RandomPkg` only for a distinct native decision with seed/result evidence |
| properties/results | procedural checks and closed normalized trace/result | affirmations/HTML/JUnit/transcripts are supplementary evidence |
| faults | typed generated substitution/masking seams | the provider may carry but cannot redefine the effect |

For a rising-edge DUT, one generated scheduler samples at the falling-edge
barrier, performs react/check in exact plan-rank order, then applies the next
rising-edge drives. VHDL process wake-up order, delta order, and provider
component scheduling never become semantic authority. The standard surface is
`--std=08` plus `std_logic_1164`, `numeric_std`, and `textio`; non-standard
arithmetic packages and VHDL-2019 constructs are excluded.

VIAL `0/1/X/Z` drives strong `std_logic` values. Sampling maps `0/1/Z`
directly, weak `L/H` to known `0/1`, and `U/X/W/-` to VIAL `X`, retaining the
original symbol as representation evidence. This is an explicit four-state
normalization, not a claim that VIAL version 1 distinguishes all nine
`std_logic` values.

Portable properties lower to bounded procedural checks. PSL is not required
or emitted because GHDL documents a restricted subset and comment-form PSL has
its own `-fpsl` requirement. Any future PSL extension must freeze its exact
tool, flags, and exercised subset independently.

Native VIAL uses a new `backends/vhdl_portable_ghdl/` or
`backends/vhdl_osvvm_qualified/` graph with deterministic runtime/metadata
packages, probe adapter where needed, testbench, source map, commands,
evidence, trace, and normalized result. The legacy
`vhdl-observation-package` command, filename, manifest, inert bytes/schema, and
no-analysis/no-PSL/no-runtime claims remain unchanged and unconsumed. The new
metadata package is a parallel versioned successor, not an in-place promotion.

The portable artifact graph is:

```text
backends/vhdl_portable_ghdl/
  backend-manifest.json
  backend-source-map.json
  commands/{analyze,elaborate,run}-command.json
  evidence/{tool-profile,analyze-transcript,elaborate-transcript,run-transcript,runtime-trace}.txt
  src/dut/<unit>.vhd
  src/fsmgen_vial_{types,runtime}_pkg.vhd
  src/<fixture>_metadata_pkg.vhd
  src/<fixture>_probe_adapter.vhd       # omitted when unnecessary
  src/<fixture>_tb.vhd
results/<result-id>/verification-result-manifest.json
```

Every non-boilerplate region maps to VIAL source/span, SemanticIR identity,
ExecutionIR operation/rank, bridge binding where applicable, and generated
file/line/column. Shared compiler helpers have a named runtime origin. Static
partial evaluation and shared packages keep output efficient and readable;
the backend emits neither an opaque interpreter nor a complete helper copy per
scenario. Exact input plus emitter identity must rerender byte-for-byte.

Persisted GHDL commands use the logical executable and repository-relative
paths. The selected representative sequence is:

```text
ghdl -a --std=08 --work=fsmgen_vial --workdir=<repo-local-workdir> <sources>
ghdl -e --std=08 --work=fsmgen_vial --workdir=<repo-local-workdir> <top>
ghdl -r --std=08 --work=fsmgen_vial --workdir=<repo-local-workdir> <top> --assert-level=error --stop-time=<bound>
```

`.15` must confirm exact option placement against the installed 6.0.0 build.
Qualification records source/tool/provider/license identity, deterministic
artifacts/maps, ordered analysis, elaboration, bounded run, trace closure,
normalized result/schema/outcomes, deterministic rerun, applicable parity,
and exact repository-local cleanup as independent gates. Analyze is not
elaboration; elaboration is not runtime; a zero exit without the closed
trace/result is not semantic success.

The portable libraries are exactly `ieee.std_logic_1164`,
`ieee.numeric_std`, and `std.textio` plus generated FSMGen libraries.
Non-standard `std_logic_arith`/`std_logic_unsigned` and VHDL-2019 are excluded.
Project-owned work libraries, provider sources, caches, logs, and staging stay
under repository-derived roots. A required operating-system tool installation
may remain an explicit read-only dependency, but persisted absolute host paths
are forbidden.

The new backend manifest records legacy migration as
`legacy_surface=vhdl_observation_package_skeleton`,
`legacy_state=unchanged_not_consumed`,
`successor_profile=vhdl_portable_ghdl`, and
`migration_kind=parallel_versioned_surface`. Any future conversion,
deprecation, or retirement requires another explicit compatibility owner.

This selection claims no generated backend, local GHDL/OSVVM installation,
analysis, elaboration, runtime, result, parity, complete IEEE 1076-2008, PSL,
formal, mixed-language, VHDL-2019, UVVM, provider-component breadth, or legacy
package analyzer support.

Clean selection commit `e5aa90b7a` activates `.15` and decomposes seven
children. Completed `.15.1` owns the provider-free emitter substrate,
deterministic artifact/source-map/command-evidence shapes, structural checks,
capability non-claims, and the first byte-locked review gallery. Completed
`.15.2` adds the portable driver, sampler, scheduler, scenario, model, and
probe-adapter semantics described below. Completed `.15.3` adds portable
scoreboards, coverage, faults, procedural checks, diagnostics, trace closure,
and normalized-result projection. `.15.4` closes portable review; `.15.5` owns exact GHDL 6.0.0 execution;
`.15.6-.15.7` own OSVVM 2026.05 adapter emission and qualification. Unavailable
tools do not block reviewable generation.

Completed `.15.1` now ships that foundation. `PlanBuilder` preserves one
deterministic generated HIAL VHDL source beside its existing SystemVerilog
source in the private backend handoff, with exact entity, unit, filename,
digest, and byte identities. Existing public plan projections do not change,
and SystemVerilog and UVM consumers continue to select only their own language
family.

The private `FSM::VIAL::Backend::VHDLPortableGHDL` emitter consumes the exact
ExecutionIR, bridge manifest, and VHDL DUT record. After `.15.3` it emits
fourteen sorted artifacts: six provider-free VHDL sources, a closed manifest
and source map, three unexecuted command records, and tool-profile,
source-order, and structural-validation evidence. Fifty-nine mappings cover
the generated HIAL DUT, typed value/phase package, logical-time/runtime
package, operation/scenario/fiber/model metadata, testbench semantics, and the
declared probe adapter.

The types package implements the selected `std_logic` normalization, retains
the original symbol in every observation, and exposes typed strong drivers.
The testbench contains typed endpoint signals, an explicit named DUT port map,
one clock generator, and one semantic scheduler. A single nested procedure
waits for the selected falling inactive edge, samples the state settled after
the preceding active edge, applies react and check in the fixed phase order,
then drives the next logical interval. No zero-time wait, delta count, or
concurrent-process ordering is semantic authority.

All 21 `VIALExecutionIR` operation identities and ranks are emitted as metadata.
The two scenarios retain their 256-cycle bounds, four fibers have explicit
lifecycle state, and two event-counter model instances update deterministically
from the selected accepted/completed transaction events. The source-mapped
probe adapter contains the only generated hierarchical external name and may
reference only the bridge-declared `reg_data_q` probe. Public DUT connectivity
continues to use named ports.

The capacity-four in-order scoreboard checks overflow, pairs queued expected
and actual items, and requires empty queues in the result predicate. Explicit
coverage counters preserve both authored stall bins. The unsupported-size
scenario applies its one-cycle field substitution through an explicit seam
without mutating the authored transaction value. Procedural checks record
success, ERROR, timeout, declared-probe, and unknown-value evidence into a
bounded diagnostic family. One provider-free `textio` path emits header/body/
footer trace framing and a normalized-result projection with every top-level
result family, per-scenario status/time records, aggregate checking metrics,
and explicit unproduced identity/parity fields. The bounded diagnostic store
retains each code, outcome, and logical time. JSON uses VHDL quote doubling;
C-style escaping is a structural failure. Exact closure and trace/result
consistency are generated invariants. These are reviewable emission semantics,
not a produced runtime result. The manifest records the legacy observation
package as an unchanged, unconsumed parallel surface.

Twenty fail-closed structural checks cover the closed safe graph, required
roles, bounded input, deterministic text, provider neutrality, selected source
shapes and normalization, typed drivers/samplers, one inactive-edge authority,
fixed phase order, exact rank/scenario/fiber metadata, deterministic model
updates, declared-probe-only hierarchy, bounded scoreboards, exact coverage
bins, substitution faults, procedural-only checks, unknown-value diagnostics,
trace closure, and normalized-result consistency. Capability negotiation additionally
rejects nine-state requirements, multiple domains, asynchronous semantic
events, and malformed or unsupported binding shapes.

Atomic publication distinguishes first creation, identical replay, and
byte-different collision, and exact cleanup leaves no staging residue. The
checked gallery is at
`vial/review_gallery/vhdl_portable_ghdl/ahb_base_output_portable_semantics` and
is regenerated or checked with
`perl scripts/refresh_vial_vhdl_portable_gallery.pl [--check]`.

This completion advances the honest capability state to private, unqualified
portable-checking emission. Exact GHDL 6.0.0 remains unavailable and
unexecuted. VHDL analysis, elaboration, runtime, produced-result
validation, parity, PSL, complete VHDL-2008, OSVVM/UVVM, mixed-language
behavior, and product support remain explicitly unclaimed.

### Primary evidence

- Accellera UVM downloads:
  `https://www.accellera.org/downloads/standards/uvm`
- Accellera official UVM 2020-3.1 release:
  `https://github.com/accellera-official/uvm-core/releases/tag/2020.3.1`
- Accellera official UVM repository/license/migration notes:
  `https://github.com/accellera-official/uvm-core`
- Verilator-targeted UVM fork and its explicit development-status boundary:
  `https://github.com/chipsalliance/uvm-verilator`
- GHDL VHDL/PSL implementation boundary and exact 6.0.0 release:
  `https://ghdl.github.io/ghdl/using/ImplementationOfVHDL.html` and
  `https://github.com/ghdl/ghdl/releases/tag/v6.0.0`
- OSVVM selected provider repository/release and utility mapping:
  `https://github.com/OSVVM/OsvvmLibraries`,
  `https://github.com/OSVVM/OsvvmLibraries/releases/tag/2026.05`, and
  `https://osvvm.github.io/Overview/Osvvm5UtilityLibrary.html`
- UVVM audited comparison release:
  `https://github.com/UVVM/UVVM/releases/tag/2026.03.20`
- PGEN and NEXSIM provider roles/status: director clarification recorded in
  decision `0050`; exact external versions and handoff remain unselected
- local legacy references:
  `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf` and
  `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf`

## Rollback

Rollback of this audit removes decision `0032`, this record, the selected
topology/book/fact continuity, and the proposed child decomposition, then
returns `.1` to active. It does not touch current IAL names, parsers, lowerings,
HDL backends, verification skeletons, CLI, manifests, support accounting,
tests, runtime behavior, or generated artifacts.
