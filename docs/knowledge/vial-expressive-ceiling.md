---
id: vial-expressive-ceiling
title: VIAL expressiveness is not bounded by synthesizable lowering
answers:
  - "is VIAL limited to synthesizable HDL?"
  - "is the portable VIAL profile the whole language?"
  - "can VIAL express full SystemVerilog and UVM verification features?"
  - "will VIAL support uvm_event?"
  - "will VIAL support uvm_event_callback?"
  - "how does VIAL handle UVM callbacks?"
  - "will VIAL have terse and verbose syntax?"
  - "what is VIAL normal form?"
  - "does VIAL recreate SystemVerilog or UVM?"
  - "how do native VIAL features map to VHDL?"
  - "does a VIAL author need to know SystemVerilog UVM or VHDL?"
  - "what does abstraction mean for VIAL?"
  - "are SV UVM and VHDL backend target languages for VIAL?"
date: 2026-07-31
status: current
tags: [vial, expressiveness, systemverilog, uvm, vhdl, events, callbacks, syntax, capabilities]
evidence: docs/decisions/0034-vial-expressiveness-is-not-bounded-by-synthesizability.md; docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md; docs/book/src/16d-hial-vial-verification-architecture.md
reverify: rg -n 'not synthesis-bounded|uvm_event_callback|terse.*normal|expressive-frontier|initial profile.*language ceiling|backend methodology|fsmgen\.vial_native_extension\.v1' docs/decisions/0034-vial-expressiveness-is-not-bounded-by-synthesizability.md docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md docs/VIAL_EXECUTION_IR_V1_CONTRACT.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/HIAL_VIAL_VERIFICATION_FIXTURE_ARCHITECTURE_AUDIT.md docs/book/src/16d-hial-vial-verification-architecture.md ROADMAP_V2.md
---

Decision `0034` separates HIAL's necessary synthesis constraint from VIAL's
verification-language horizon. VIAL is not limited by synthesizability. Its
portable core and `core_directed_single_clock_v1` are initial profiles, not the
language definition or permanent expressive ceiling.

Its director-approved design rule is **full power underneath, simpler intent
above**: cover the expressive use cases enabled by SV/UVM/VHDL without exposing
every target mechanism as VIAL vocabulary.

Abstraction means simplification for the author. Mastering VIAL must not
require prior SystemVerilog, UVM, or VHDL knowledge. Conceptually those are
backend target languages for VIAL, much as assembly languages are compiler
targets for C/C++ or Rust. The compiler and qualified backend own target
syntax, methodology plumbing, scheduling expertise, and efficient artifact
construction; generated code remains readable and source-mapped for diagnosis
and integration. Renaming and exposing a gory target detail is therefore an
abstraction failure, even if the lowering works.

Native VIAL may give typed semantics to the verification intents enabled by
SystemVerilog/UVM or VHDL. Notification/interception intent retains identity,
registration, ordering, filtering, lifecycle, reentrancy/cancellation, and
observable effects; an SV/UVM compiler may implement it through `uvm_event`
and `uvm_event_callback`. Implementation selection/substitution and scoped
configuration stay VIAL intent while UVM factories, config DB calls, TLM
plumbing, and similar methodology mechanisms remain compiler-private.
VIAL likewise describes readiness, stimulus lifetime, background services,
completion/drain, shutdown, finalization, deadlines, and failure policy; the
backend owns UVM phase selection, objections, and phase-transition plumbing.

This is not a goal to reproduce target syntax. Constructs remain typed VIAL
intent with stable source maps, diagnostics, capabilities, and results. Terse
and verbose normal forms lower to one semantic model; terseness removes
ceremony, not meaning. Portable concepts map across backends, while native
concepts require exact capability mappings or fail before output. The bounded
`.3` source/SemanticIR implementation remains the first profile unchanged.
Every later feature must expose, compose, or compress verification intent; a
one-to-one catalog of renamed SV/UVM/VHDL syntax, classes, or methods is
explicitly out of scope. Completed documentation leaf `.6` now selects the
target-neutral execution/native/result contract that preserves this separation
under decision `0036`; it implements no behavior. Active `.7` owns private
no-backend implementation after separate clean activation. Clean selection
commit `eaf3f95dc` now permits that continuity-only activation; implementation
remains unperformed and the expressive boundary is unchanged.
