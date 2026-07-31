---
id: vial-hial-type-binding-mismatch
title: Exact VIAL/HIAL type identity failed and directional proof binding resolves it
answers:
  - "why was VIAL execution implementation blocked?"
  - "do VIAL transaction types exactly match HIAL bridge types?"
  - "why does VIAL bool not match HIAL logic?"
  - "how should a VIAL enum bind to a hardware logic vector?"
  - "should VIAL authors use four-state logic for every hardware field?"
  - "what is a directional VIAL HIAL representation adapter?"
  - "which VIAL AHB transaction fields have type mismatches?"
date: 2026-07-31
status: current
tags: [vial, hial, binding, types, two-state, four-state, enum, resolved-blocker]
evidence: docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md; docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; vial/ahb_subordinate_base_output_arbitration.vial; perl/FSM/HIAL/VIALBridge/Builder.pm; t/1551-hial-vial-bridge-manifest.t; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: rg -n 'resolved by director-approved decision `0037`|bit_domain_identity_v1|known_value_injection_v1|enum_encoding_injection_v1|HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE\.7\.2' docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md docs/VIAL_EXECUTION_IR_V1_CONTRACT.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
---

The checked AHB fixture could not satisfy decision `0036`'s former exact
transaction-field type-equivalence rule. `transfer` is a VIAL enum over
four-state logic while the bridge publishes plain four-state logic; `write` is
VIAL two-state Boolean while the bridge publishes four-state logic; and
`wait_cycles` is VIAL two-state unsigned while the bridge publishes four-state
logic. Address, size, data, sampled public outputs, and the declared probe
match.

The mismatch is architectural, not a parser or manifest defect. VIAL preserves
expressive authored value semantics; HIAL preserves observable hardware logic
semantics. The frozen execution contract omitted the representation relation
between them. Active `.7` is split: audit `.7.1` records the evidence,
director-approved `.7.2` selects the semantic rule through decision `0037`,
and clean selection commit `2a1b3cefc` permits active `.7.3` to own
implementation after separate continuity activation.

The selected rule is a closed proof-carrying directional relation: known
two-state values inject into same-width/signed four-state carriers with all
known bits and no Z, and enums inject through their exact base encoding. It
does not permit inverse X/Z collapse, width/sign conversion, implicit
expression coercion, or a target-language cast. This resolves the contract
blocker without changing VIAL source or the HIAL bridge schema.
