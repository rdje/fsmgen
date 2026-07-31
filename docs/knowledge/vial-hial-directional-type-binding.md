---
id: vial-hial-directional-type-binding
title: VIAL semantic types bind to HIAL carriers through directional proof relations
answers:
  - "how do VIAL semantic types bind to HIAL hardware types?"
  - "what is bit_domain_identity_v1?"
  - "what is known_value_injection_v1?"
  - "what is enum_encoding_injection_v1?"
  - "can a VIAL bool drive four-state HIAL logic?"
  - "can four-state HIAL logic be sampled as a two-state VIAL value?"
  - "does VIAL binding use SystemVerilog or VHDL casts?"
  - "why are VIAL types different from HIAL carrier types?"
date: 2026-07-31
status: current
tags: [vial, hial, binding, type-relation, two-state, four-state, enum, decision-0037]
evidence: docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; docs/book/src/16d-hial-vial-verification-architecture.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: rg -n 'bit_domain_identity_v1|known_value_injection_v1|enum_encoding_injection_v1|four-state-to-two-state|vial\.binding\.directional_representation\.v1' docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md docs/VIAL_EXECUTION_IR_V1_CONTRACT.md docs/book/src/16d-hial-vial-verification-architecture.md
---

Decision `0037` keeps VIAL semantic types and HIAL hardware carrier types
independently authoritative. The ExecutionIR binder proves one closed relation
at each directional seam rather than rewriting the VIAL type or applying an
implicit target-language cast.

Version 1 selects three kinds. `bit_domain_identity_v1` requires equal state
domain, width, and signedness and works for drive or sample.
`known_value_injection_v1` maps a two-state VIAL scalar into same-width/signed
four-state HIAL logic with unchanged value bits, all known bits, and no Z;
it is drive-only. `enum_encoding_injection_v1` maps a VIAL enum through its
exact unique base-bit encodings into a HIAL logic carrier; it is also
drive-only.

The asymmetry is mandatory. Arbitrary four-state hardware cannot be sampled
as a two-state VIAL value or enum because one run's known bits do not prove a
total semantic conversion. Width/sign changes, truncation, extension, wrap,
enum decoding, X/Z collapse, aggregate flattening, expression coercion, and
backend-selected casts remain fail-closed.

The checked AHB transaction uses identity for address/size/data, enum encoding
for transfer, and known-value injection for write/wait_cycles. All sampled
public outputs and the declared probe use identity. The probe's separate
equivalent-adapter capability remains required.

Clean selection commit `2a1b3cefc` permitted `.7.3` to implement these records
after separate continuity activation. Completed `.7.3` records them in private
ExecutionIR and the defensive plan; it still emits no backend, runtime, or
public artifact.
