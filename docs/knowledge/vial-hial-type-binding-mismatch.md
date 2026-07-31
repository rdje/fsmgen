---
id: vial-hial-type-binding-mismatch
title: The checked AHB VIAL fixture is not bindable under exact VIAL/HIAL type identity
answers:
  - "why is VIAL execution implementation blocked?"
  - "do VIAL transaction types exactly match HIAL bridge types?"
  - "why does VIAL bool not match HIAL logic?"
  - "how should a VIAL enum bind to a hardware logic vector?"
  - "should VIAL authors use four-state logic for every hardware field?"
  - "what is a directional VIAL HIAL representation adapter?"
  - "which VIAL AHB transaction fields have type mismatches?"
date: 2026-07-31
status: current
tags: [vial, hial, binding, types, two-state, four-state, enum, blocker]
evidence: docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md; docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; vial/ahb_subordinate_base_output_arbitration.vial; perl/FSM/HIAL/VIALBridge/Builder.pm; t/1551-hial-vial-bridge-manifest.t; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
reverify: rg -n 'confirmed implementation blocker|enum/logic mismatch|state-domain/family mismatch|Closed directional representation adapters|HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE\.7\.2' docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
---

The checked AHB fixture cannot satisfy decision `0036`'s current exact
transaction-field type-equivalence rule. `transfer` is a VIAL enum over
four-state logic while the bridge publishes plain four-state logic; `write` is
VIAL two-state Boolean while the bridge publishes four-state logic; and
`wait_cycles` is VIAL two-state unsigned while the bridge publishes four-state
logic. Address, size, data, sampled public outputs, and the declared probe
match.

The mismatch is architectural, not a parser or manifest defect. VIAL preserves
expressive authored value semantics; HIAL preserves observable hardware logic
semantics. The frozen execution contract omitted the representation relation
between them. Active `.7` is split: audit `.7.1` records the evidence, blocked
`.7.2` owns the director-selected semantic rule, and `.7.3` owns implementation
only after that rule commits cleanly.

The recommended rule is a closed proof-carrying directional adapter: known
two-state values inject into same-width/signed four-state carriers with all
known bits and no Z, and enums inject through their exact base encoding. It
does not permit inverse X/Z collapse, width/sign conversion, implicit
expression coercion, or a target-language cast. Exact identity remains the
alternative if the source or bridge is deliberately aligned without weakening
VIAL abstraction.
