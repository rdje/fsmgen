# 0032 — VIAL uses one source, two private IRs, and a versioned HIAL bridge

- Date: 2026-07-31
- Type: architecture
- Status: accepted by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1`
- Preserves: `0004`, `0008`, `0014`, `0018`, `0022`, `0031`

## Context

FSMGen's current HIAL stack has three public hardware-intent levels:
IAL2/`.ppif` lowers through IAL1/`.isf` to IAL0/`.fsm`, then to HDL. Its
verification-output lane is much narrower: IAL1 `(observe ...)` metadata can
emit inert UVM 1.2 monitor/snapshot class declarations or an inert VHDL
metadata package, but it cannot bind a DUT, drive stimulus, sample transactions,
run scenarios, compare outcomes, scoreboard, cover behavior, or inject faults.

The handwritten AHB arbitration harness proves the missing shape. It combines
clock/reset control, phased driving and sampling, timeout-bounded scenarios,
transaction acceptance, temporal counting, external outcomes, internal probes,
expected storage, diagnostics, and deterministic completion. Treating that
fixture as another IAL1 assertion or cloning HIAL0/HIAL1/HIAL2 into
VIAL0/VIAL1/VIAL2 would mix distinct verification concerns and create three
public languages before one executable verification boundary is proved.

The current backend evidence is also asymmetric. Verilator 5.046 is locally
available and can execute supported timing-aware SystemVerilog, but it is not
the authority for complete SystemVerilog/UVM. No GHDL, NVC, or qualified
full-language/UVM simulator is locally available. Existing VHDL and UVM
artifacts therefore retain explicit compile/simulation non-claims.

## Decision

Select one public, reviewable `.vial` source language rather than numbered
VIAL0/VIAL1/VIAL2 source layers. Reuse through packages, declarations, profiles,
and scenario composition inside that language instead of adding abstraction
levels.

Select two private immutable compiler boundaries:

1. `VIALSemanticIR` owns parsed and type-checked verification meaning before a
   concrete DUT binding.
2. `VIALExecutionIR` owns a fully bound, capability-checked, deterministic
   execution plan after consuming a versioned HIAL/VIAL bridge.

Select `HIALVIALBridgeManifest` as the bounded, versioned, language-neutral
handoff. It exposes sanitized HIAL source identity, units, configuration,
logical types, interfaces/endpoints, clocks/resets, transactions/events,
protocol facts, observation/probe declarations, backend bindings, capability
requirements, and source maps. Raw HIAL or VIAL IR objects are never public.
IAL2-contributed facts must remain reviewable through generated IAL1 before the
bridge consumes them; this decision does not create direct IAL2-to-verification
output generation.

Portable VIAL semantics cover typed stimulus, transactions, scenarios,
deterministic concurrency, expected outcomes, temporal checks, pure/stateful
reference models, scoreboards, functional coverage, and bounded fault
injection. Logical clock phases, stable source identities, and schedule-
independent random-decision keys make execution reproducible across backends.

Native power is supplied through typed external extension contracts, not raw
target-language fragments hidden in portable source. Each extension declares
its backend/profile, lifecycle hook, typed inputs/outputs, capabilities,
repository-relative source, deterministic side effects, source span, content
identity, and required/fallback policy.

Select these distinct validation profiles:

- `sv_portable_verilator`: plain generated SystemVerilog plus
  `verilator --binary --timing`, limited to recorded supported capabilities;
- `sv_uvm_qualified`: native UVM output under a separately named
  full-language/UVM simulator, version, UVM revision, and capability record;
- `vhdl_portable_ghdl`: VHDL-2008 analysis/elaboration/simulation under an
  installed GHDL profile, without inferring complete VHDL-2019 or PSL support;
- `vhdl_methodology_qualified`: a separately selected OSVVM/UVVM-style
  methodology provider and compatible simulator profile; and
- `mixed_language_qualified`: an explicitly qualified tool/profile, never an
  inference from either single-language lane.

The first runnable backend target is the plain-SystemVerilog portable profile,
because it matches the proven AHB harness and the locally available behavioral
oracle without requiring UVM. Existing inert UVM/VHDL targets remain shipped
compatibility surfaces until later migration owners replace or version them.

Backend parity is judged from a normalized result manifest: scenario and
logical event identities, domain-cycle/phase stamps, transaction values,
check and scoreboard outcomes, coverage counts, timeout/termination state,
seed/decision identity, and capability profile. Generated text and waveforms
are evidence, but neither is the cross-backend semantic oracle.

## Consequences

- `.vial` syntax, both IR contracts, the bridge schema, public tooling, and
  each backend still require exact later contract and implementation leaves.
- SourceHIR remains the private source-facing HIAL seam from decision `0031`;
  VIAL does not extend it or expose its private object shapes.
- IAL1 assertions/properties stay on the HIAL path. Shared property meaning
  may later gain a typed projection, but VIAL does not fork the property
  language selected by decision `0008`.
- Public-port behavior is the mandatory portable oracle. Internal HIAL state
  is usable only through explicitly declared verification probes with recorded
  portability/profile limits; raw hierarchy is a native extension, not a
  portable contract.
- UVM 1.2 in the existing skeleton is not silently promoted to the new native
  backend. A later UVM contract must select its revision and simulator profile.
- VHDL-2008, GHDL, PSL, OSVVM/UVVM, and mixed-language capabilities are claimed
  independently and only after runnable gates exist.
- Architecture-specific scale proof must bound units, endpoints, scenarios,
  fibers, transactions, model state, scoreboard queues, coverage bins/crosses,
  random decisions, artifact size, time, and descendant RSS. It does not
  replace the separately proposed whole-product large-design qualification.
- The canonical detailed audit and worked AHB mapping live in
  `docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md`.
