---
id: direct-declared-width-consumers
title: Direct declared ranges retain source trees but numeric declaration plans need captured lookup identities
answers:
  - "where do direct symbolic declared-width consumers need integration?"
  - "does a direct parameter-dependent width defaulting to one retain a vector range?"
  - "is the Core module signals map exhaustive for declared assignment targets?"
date: 2026-10-27
status: current
tags: [widths, parameters, lowering, declarations]
evidence: docs/audits/direct-declared-range-split-20261027.json.gz; perl/FSM/Adapter/FSMGenFull/Parser.pm; perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm; t/2111-ial0-parameter-width-selection.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2111-ial0-parameter-width-selection.t
---

Parser retains expression, resolved_width and original signal in the detached
Signal declared_width_source getter. Named types keep their existing type
contract. Complete actual parameter/static lookup provenance is not retained
there; the current numeric plans cannot reconstruct it from equal widths.

The receipt's actual resettable source has WIDTH1, an explicit data_port
parameter selector and an independent literal-width input. The selector tree
survives on its Signal while the independent literal has no authored width
record; both declarations still emit scalar HDL. Module signals alone is not
an exhaustive source for assigned outputs: the actual Signal is also reached
through the canonical adapter registry and assignment AST.

ModulePlanningSupport owns direct port/internal plans. ScaffoldEmitter and
InternalDeclarationEmitter currently render numeric ranges; direct VHDL parses
those generated numeric declarations. CompositionWidthEmitter already has
captured lookup contracts, explicit symbolic ranges and one-bit vector rank.
ISF-REDUCTION-DELIVERY.3.3 owns source provenance, shared target kernels and
direct consumer integration; computed shapes and full qualification stay .3.4/.6.

The direct Parser now offers opt-in capture_declared_width_contract with explicit
lexical direct_module scope. It preserves the actual constant-only fast branch
and reuses canonical expression capture with real selected observations. Fixed
literal/type results and all ordinary contracts remain unchanged. This private
result is not yet published on Core Signals: .3.3.1.2.2.3 owns automatic source
association/invalidation before target kernels may consume it. Reverify:
`prove -Iperl t/2160-direct-declared-width-capture.t t/2128-shared-integer-width-evaluator.t t/2111-ial0-parameter-width-selection.t`.
