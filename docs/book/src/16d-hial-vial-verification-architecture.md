# HIAL/VIAL Verification Architecture

FSMGen has selected the architecture for a future verification-intent language
and generated executable fixtures. This chapter explains that destination and
the compatibility boundary. It does **not** mean `.vial` input or runnable
VIAL output ships today.

The current shipped verification-output targets remain deliberately narrow:

- `uvm-passive-monitor` emits inert UVM 1.2 snapshot and passive-monitor class
  declarations;
- `vhdl-observation-package` emits an inert VHDL metadata package; and
- neither target drives a DUT, samples a transaction stream, runs a scenario,
  compares expected outcomes, scoreboards, covers behavior, or injects faults.

The selected architecture closes that gap in exact later slices while keeping
the current IAL routes stable.

## Two peer intent systems

**Hardware IAL (HIAL)** is the collective architecture name for FSMGen's
existing synthesizable stack:

```text
IAL2 (.ppif) -> generated IAL1 (.isf) -> generated IAL0 (.fsm) -> HDL
```

IAL0, IAL1, IAL2, their suffixes, commands, diagnostics, and review artifacts
do not change names. HIAL continues to describe hardware behavior and lowers
to synthesizable targets.

**Verification IAL (VIAL)** is the peer system for non-synthesizable fixture
intent. Its job is to describe stimulus, scenarios, observations, expected
outcomes, models, scoreboards, coverage, faults, and deterministic execution
around a HIAL-generated DUT.

The selected topology is:

```text
public .vial source
        |
        v
private immutable VIALSemanticIR
        |
        +---- versioned HIALVIALBridgeManifest <---- HIAL review route
        |
        v
private immutable VIALExecutionIR
        |
        +---- sanitized vial-plan.json
        |
        +---- backend artifacts
        |
        v
normalized verification-result-manifest.json
```

There are not three public VIAL0/VIAL1/VIAL2 languages. HIAL's three layers
are useful hardware authoring levels, whereas verification declarations, DUT
binding, scenarios, concurrency, checking, models, coverage, and methodology
are orthogonal. One `.vial` language keeps those concerns composable; private
compiler phases preserve strict boundaries without forcing users to choose an
artificial source level.

## Selected VIAL version-1 source contract

The source/semantic-IR contract is now selected, but its parser and first
source are not shipped yet. VIAL version 1 uses closed S-expressions and a
dedicated source-span-aware parser. It deliberately does not expose the
repository's legacy raw Lispish arrays: exact byte/line/column provenance,
stable semantic IDs, deterministic diagnostics, and later replay/source maps
are language requirements.

Every file contains one versioned package with explicit sections:

```lisp
(vial
  (version 1)
  (package example
    (imports)
    (types
      (enum state_t (logic 2)
        (idle #b00)
        (busy #b01)))
    (transactions)
    (models)
    (scoreboards)
    (fixtures ...)))
```

Imports are repository-relative and explicitly qualified. The parser receives
their bytes from an in-memory source catalog; it does not search the current
directory, home caches, temporary directories, or the network.

The first profile, `core_directed_single_clock_v1`, selects enough meaning for
one bounded AHB arbitration source:

- `bool`, unsigned/signed two-state vectors, unsigned/signed four-state
  vectors, enums, records, and bounded lists;
- typed transactions and opaque unbound HIAL bridge references with expected
  types and `public_port`/`verification_probe` access assertions;
- deterministic event-driven models and bounded in-order/keyed scoreboards;
- explicit coverpoints/cross caps, bounded transaction-field substitution
  faults, seed plus stable random decision IDs;
- timeout-bounded scenarios, literal-bounded repeats, and deterministic
  `parallel all`/`parallel any` fibers; and
- typed observations, event counts, expectations, and waits.

Four-state `#b` literals normalize to value bits, a known mask, and a Z mask;
target syntax is not semantic truth. There is no implicit truncation,
signedness conversion, overflow wrap, or X/Z-to-two-state coercion. `same`
means exact four-state equality, while `value_eq` requires known numeric or
Boolean operands.

VIAL does not create another property language. Its expectations and waits
reuse the canonical `=>`, `next`, and one-/two-bound `within` operators already
selected for verification properties. New temporal operators must extend the
shared property contract rather than appear only in VIAL.

The planned first checked source is
`vial/ahb_subordinate_base_output_arbitration.vial`. It will represent success
and unsupported-size scenarios, a transaction, event counters, a bounded
scoreboard, stall coverage, one bounded size-substitution fault, and stable
wait-cycle decision identity. In the first implementation it can only parse,
type-check, and produce a sanitized semantic report. Bridge binding, execution
plans, generated fixtures, simulation, and results remain later phases. See
the exact [VIAL source and SemanticIR v1 contract](../../VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md).

Clean contract commit `08f59167b` activates only the bounded parser/SemanticIR
implementation leaf. Activation itself adds no parser, source, report,
capability, support, test, binding, output, or runtime behavior.

## The two private IR boundaries

`VIALSemanticIR` owns parsed, typed, validated verification meaning before it
is attached to a concrete DUT. It contains reusable types, transactions,
scenarios, models, expectations, coverage definitions, fault definitions, and
source identity. It is not HIAL source, SourceHIR, scheduled hardware, or a
public serialization contract.

`VIALExecutionIR` owns the fully bound and capability-checked execution plan.
Every DUT reference has resolved through the bridge; logical clock phases,
scenario fibers, timeouts, checks, models, scoreboards, coverage state, native
extension hooks, and backend requirements are explicit. It is also private.

Public reports are bounded sanitized projections. Raw IR object structure is
not an API, and callers do not receive mutable compiler-owned data.

## The HIAL/VIAL bridge

`HIALVIALBridgeManifest` is the portable DUT-binding authority. Its versioned
schema must publish stable logical identities and source maps for:

| Family | Bridge facts |
| --- | --- |
| Identity | HIAL source kind, repository-relative source identity, generated `.isf`/`.fsm` review identities, content identities |
| Units | logical unit IDs, module/entity bindings, hierarchy/composition identity |
| Configuration | parameters/generics, resolved values, types, provenance |
| Types | widths/ranges, signedness, enums/records, two-state/four-state value policy |
| Endpoints | direction, type, unit/interface owner, semantic role, target port names |
| Time domains | clocks, edges, resets, polarity, synchronization policy |
| Transactions/events | fields, request/accept/complete/sample events, ordering and correlation |
| Protocol facts | profile/version, channel roles, timing/value facts, retained unsupported residue |
| Observations/probes | IAL1 observations, public-port sets, declared verification probes |
| Bindings/capabilities | SystemVerilog and VHDL target bindings, required profile capabilities |
| Source map | every published fact back to HIAL source and review artifacts |

The bridge has three access classes:

1. `public_port` is the mandatory portable baseline.
2. `verification_probe` is declared by HIAL and carries explicit profile
   support. It is portable only where claimed backends provide equivalent
   semantics.
3. `native_hierarchy` is backend-specific and usable only through a typed
   native extension. It cannot establish a portable parity claim.

For IAL2, protocol facts may enter the bridge only after they are present in
or deliberately annotated onto generated IAL1 review artifacts. VIAL does not
add a direct PPIF-to-verification backend or a second protocol truth source.

## Portable verification meaning

The portable language must cover these semantic families:

| Family | Required meaning |
| --- | --- |
| Values/types | booleans, bounded integers, two-/four-state scalars and vectors, enums, records, lists, transactions |
| Binding | bridge unit, endpoint, domain, transaction, configuration, and capability references |
| Stimulus | typed drives and transactions, reset actions, waits, bounded faults |
| Scenarios | reusable procedures, ordered steps, bounded loops, timeouts, setup/teardown |
| Concurrency | deterministic logical fibers, join policies, cancellation, stable tie-breaking |
| Observation/checking | explicit samples, predicates, temporal windows, counts, stable/changed checks, expected streams |
| Models/scoreboards | pure functions, declared deterministic state, in-order/keyed/bounded-unordered matching |
| Coverage | points, bins, transitions, crosses, illegal/ignore bins, goals, exact counts |
| Randomization | explicit seeds, domains/distributions/constraints, stable decision IDs, replay records |
| Diagnostics | source span, scenario/fiber/event, logical time, expected/actual, profile, stable code |

Coverage crosses and scoreboard queues must be explicitly bounded. Portable
logic distinguishes two-state and four-state values; a backend may not
silently coerce unknowns or target-specific logic states.

## Logical time and reproducibility

Portable execution is defined in four logical phases:

1. `drive`: apply actions before the selected active edge;
2. `sample`: capture stable post-edge DUT observations;
3. `react`: advance scenarios, models, and scoreboards; and
4. `check`: commit expectations, coverage, transcript, and termination.

SystemVerilog scheduling regions, UVM phases, VHDL processes, and delta cycles
may implement these phases differently, but they must preserve the same
logical order. Simultaneous work uses stable domain, phase, fiber, and source
order. Zero-time unbounded loops fail closed.

Random choices are keyed by stable source/scenario/fiber/decision identities,
not host threads or callback order. The exact algorithm and replay encoding
remain for the execution contract; the architecture requires schedule-
independent reproducibility now.

## Native extensions

Portable `.vial` does not embed anonymous raw SystemVerilog/UVM or VHDL
blocks. A native extension is an external repository-relative artifact with a
typed contract containing:

```text
extension identity
backend profile identities
lifecycle hook
typed inputs and outputs
required capabilities
source path, span, and content identity
declared deterministic side effects
required-or-fallback policy
generated artifact identities
```

Hooks come from a closed family such as elaborate, build, drive, sample,
predict, compare, cover, and finalize. Extensions cannot mutate private IR or
undeclared DUT state. Backend-only behavior is excluded from portable parity
unless paired implementations share one logical oracle.

## Backend profiles and honest claims

| Profile | Intended target | Qualification boundary |
| --- | --- | --- |
| `sv_portable_verilator` | plain SystemVerilog fixture without UVM | exact Verilator version; compile, elaborate, and run with `--binary --timing`; only exercised supported capabilities |
| `sv_uvm_qualified` | native UVM components, sequences, monitors, scoreboards, coverage | named simulator/version and selected UVM revision; full compile/elaborate/run evidence |
| `vhdl_portable_ghdl` | VHDL-2008 packages, processes, and testbench | installed GHDL/version with `--std=08`; explicit language/PSL limits |
| `vhdl_methodology_qualified` | VHDL plus a selected methodology provider | exact provider/revision and compatible simulator; OSVVM/UVVM mapping selected later |
| `mixed_language_qualified` | HIAL and VIAL in different HDLs | named mixed-language tool/version and binding adapter; never inferred from single-language success |

Plain SystemVerilog/Verilator is first because the existing AHB fixture proves
the relevant timed behavioral substrate locally without requiring UVM.
Verilator with `--timing` is an event-capable compiled simulator for the
features it supports; it is not evidence of complete SystemVerilog or UVM
support.

The current UVM 1.2 output does not silently choose the future UVM revision.
The VHDL lane does not claim analysis, simulation, complete VHDL-2019, PSL, or
methodology support until its exact profiles run. Mixed-language support is a
separate qualification.

## Cross-backend result parity

Every executable backend will emit a normalized
`verification-result-manifest.json`. Equivalent portable intent must agree on:

- source, bridge, plan, scenario, and profile identities;
- seeds and stable random-decision identities and values;
- logical domain-cycle/phase and event identities;
- driven, sampled, and transaction values;
- check, temporal, model, and scoreboard outcomes;
- coverage hit counts and goals; and
- timeout, cancellation, completion, unsupported exclusions, and final state.

Generated source text can differ across languages. Waveforms and simulator
transcripts remain diagnostics; neither is the portable semantic oracle.

## Mapping the AHB arbitration fixture

The architecture audit uses
`t/data/ahb_generated_subordinate_base_output_arbitration_tb.svt` as its
worked input. The mapping below is conceptual, not accepted `.vial` syntax:

| Handwritten construct | Portable meaning | Boundary |
| --- | --- | --- |
| clock toggle and reset task | bridge-bound clock plus reusable reset procedure | generated backend process |
| public AHB signals | typed endpoints and an AHB write transaction | protocol facts remain reviewable through IAL1 |
| edge-triggered counters | sample-phase events and counters | portable |
| drive IDLE after acceptance | drive-phase reaction to sampled acceptance | portable |
| bounded wait loops | scenario waits with explicit timeout and termination | portable unless raw hierarchy is used |
| HREADYOUT/HRESP/HRDATA checks | public-port expectations | portable |
| `$fatal` and `$display` | typed diagnostics and normalized metrics | backend text is not parity |
| internal capture/hold/completion state | named HIAL verification probes | qualified only where equivalent adapters exist |
| raw pending/storage hierarchy | native hierarchy | prefer public completion/readback or declared architectural-state probes |

The portable oracle uses bus behavior: one acceptance, a visible stall,
response timing, data behavior, completion/ready return, and a follow-up read
or declared state probe. Raw internal counters remain useful diagnostics, but
cannot be called cross-backend portable.

## Migration and current boundary

The migration order is additive:

1. keep all current HIAL names and synthesized behavior unchanged;
2. keep IAL1 checks/properties on the existing HIAL property route;
3. treat `(observe ...)` as an initial bridge observation source, not a VIAL
   scenario language;
4. preserve the current UVM/VHDL target IDs, paths, manifest contract, and
   explicit non-claims until their migration owners act;
5. add versioned bridge, plan, artifact, and result reports without exposing
   raw IR;
6. keep `.ppif` verification output unsupported; and
7. keep native extensions typed, external, capability-qualified, and reported.

The selected implementation order is source/semantic-IR contract and
implementation, bridge contract and implementation, execution/result/parity
contract and implementation, public tooling, plain-SystemVerilog backend, AHB
runtime parity, then separately qualified UVM, VHDL, mixed-language, scale,
and closeout work. Each leaf requires its own clean activation and acceptance
evidence. The canonical architecture record is
[HIAL/VIAL Verification Fixture Architecture Audit](../../HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md),
and the owning [task tree](../../tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md)
tracks the exact frontier.
