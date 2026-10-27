---
id: direct-declared-width-consumers
title: Direct declared ranges retain source trees but numeric declaration plans need captured lookup identities
answers:
  - "where do direct symbolic declared-width consumers need integration?"
  - "does a direct parameter-dependent width defaulting to one retain a vector range?"
  - "is the Core module signals map exhaustive for declared assignment targets?"
  - "why must explicit auxiliary width declarations be preserved before copying parent bindings?"
date: 2026-10-27
status: current
tags: [widths, parameters, lowering, declarations]
evidence: docs/audits/auxiliary-width-origin-contract-20261027.json.gz; docs/audits/auxiliary-width-origin-contract-20261027.py; docs/audits/direct-declared-range-split-20261027.json.gz; perl/FSM/Adapter/FSMGenFull/Parser.pm; perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ScaffoldEmitter.pm; perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/InternalDeclarationEmitter.pm; t/2111-ial0-parameter-width-selection.t
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

The direct Parser offers opt-in capture_declared_width_contract with explicit
lexical direct_module scope, preserving the actual constant fast branch and
canonical selected observation walk. Successful source parsing now stages real
Signal associations and publishes primary declared_width_binding records only
after complete module validation; facade failures clear them too. Original
header scope survives physical renaming. Old source/numeric/public products
conserve; literal/type branches acquire no parameter relationship. Auxiliary
origin propagation remains .3.3.1.2.2.3.3, before target range kernels .3.3.2.
Reverify:
`prove -Iperl t/2162-direct-source-width-binding-publication.t t/2161-core-declared-width-binding-lifecycle.t t/2160-direct-declared-width-capture.t t/2111-ial0-parameter-width-selection.t`.

Actual <-=/<=-/<=+ auxiliary copies overwrite an independently declared auxiliary
source record with data(param W), while legacy max-width refinement still retains
both numeric requirements. Equal-default param X and literal-eight declarations
then have identical selected Signal products; opposing W/X defaults demonstrate
the lost constraint still matters numerically. Clean/one-bit/named-type and
renamed late-sizing controls retain their distinct boundaries. This is a P1
provenance defect, not a numeric behavior defect; .3.3.1.2.2.3.3.4 owns private
retention before propagation/range admission. Use immutable event snapshots and
final active actual-object ownership; a later live-source lookup cannot supply
an earlier copy's identity. Reverify:
`python3 -B docs/audits/auxiliary-width-origin-contract-20261027.py --self-test`.
