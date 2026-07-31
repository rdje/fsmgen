# 0043 — VIAL portable SystemVerilog is a deterministic known-value profile

- Date: 2026-07-31
- Type: verification backend and runtime architecture
- Status: accepted
- Extends: `0032`, `0034`, `0036`, `0037`, `0039`
- Evidence owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9`

## Context

VIAL needs a first executable backend before native UVM, VHDL methodology, or
mixed-language profiles can be qualified. The checked execution plan is
already target-neutral and deterministic, while the repository's handwritten
AHB harness proves that locally installed Verilator 5.046 can compile and run
the required timed, non-UVM SystemVerilog substrate.

That evidence has two important limits. Simulator scheduling regions must not
become VIAL semantics, and Verilator's compiled runtime is not an authority for
complete four-state SystemVerilog or UVM. A convenient backend that silently
claimed either would contradict the capability-complete plan and the rule that
the initial portable profile is not VIAL's expressive ceiling.

## Decision

Select backend profile `sv_portable_verilator` version 1 as specified by
`docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md`.

The backend partially evaluates one immutable `VIALExecutionIR` into readable,
non-UVM SystemVerilog: a small stable runtime package, one fixture module, the
HIAL-generated DUT, exact source maps, a private line-delimited runtime trace,
and normalized public manifests. It does not emit a general interpreter or
reconstruct authored VIAL as renamed SystemVerilog statements.

Portable logical time is preserved with one scheduler process. At the inactive
clock edge it samples the state produced by the preceding active edge, performs
react/check work in deterministic plan order, and then applies the next cycle's
drive state. This half-cycle barrier avoids active-edge races without exposing
SystemVerilog regions, clocking blocks, program blocks, or delay folklore to a
VIAL author.

The reference qualification is exact: Verilator 5.046 dated 2026-02-28, timed
binary generation, assertions enabled, one build/runtime thread, deterministic
X concretization, an explicit top, repository-local object directory, and a
fixed default timescale. Compile, executable creation, runtime, trace closure,
result-schema validation, and scenario outcomes are distinct gates.

This is a **known-value portable profile**. It accepts only operations whose
authored constants, decisions, comparisons, model state, scoreboard values,
coverage values, and fault substitutions do not require X/Z identity. Runtime
samples are represented in the normalized result shape, but Verilator cannot
establish complete four-state observability. The profile therefore reports its
two-state/known-trace limit and never claims unknown-sensitive verification,
full SystemVerilog LRM coverage, UVM, or native methodology behavior. A later
qualified four-state backend may expose a mismatch; Verilator success cannot
override it.

Declared HIAL verification probes may be implemented only by generated,
source-mapped adapters selected from bridge bindings. The first profile uses a
compiler-private hierarchical alias for `probe/reg_data_q`, matching the
already-exercised AHB harness. This satisfies the named adapter requirement for
that profile; it does not authorize authored raw hierarchy or infer equivalent
support in another backend.

The SystemVerilog runtime emits a closed prefixed trace stream. The host adapter
only validates, orders, and projects those semantic records into
`fsmgen.verification_result_manifest.v1`; it does not rerun scheduling, models,
scoreboards, coverage, faults, or random choices. Target text, simulator time,
and tool chatter remain evidence rather than parity meaning.

## Consequences

- `.10` may implement only this bounded backend plus the already-selected
  public tooling/result producer; `.11` separately owns AHB runtime parity.
- Known-value runtime support is useful and honest without becoming VIAL's
  global type or expressive ceiling.
- Generated code can use target-private modules, tasks, functions, arrays,
  event controls, delays, file/display system tasks, and hierarchy adapters,
  while authored VIAL remains target-language independent.
- UVM factories, phases, objections, callbacks, TLM, RAL, and related plumbing
  remain outside this backend and outside authored VIAL.
- No source/parser, public command, generated artifact, runtime, capability, or
  product behavior is implemented by this decision.
- The exact artifacts, mapping, trace, commands, diagnostics, limits,
  qualification gates, implementation oracle, non-claims, and rollback are
  canonical in the backend contract.
