---
id: hial-vial-verification-fixture-architecture
title: HIAL and VIAL own the future dual-intent verification-fixture architecture
answers:
  - "what do HIAL and VIAL mean in FSMGen?"
  - "does FSMGen plan a Verification IAL?"
  - "where is powerful verification fixture generation tracked?"
  - "should HIAL lower to SystemVerilog and VHDL?"
  - "should VIAL lower to SV/UVM and VHDL verification code?"
  - "will VIAL have VIAL0 VIAL1 and VIAL2 layers?"
  - "how should HIAL designs connect to VIAL fixtures?"
  - "how can VIAL use full SV/UVM or VHDL power without cloning those languages?"
  - "is the HIAL VIAL architecture active now?"
date: 2026-07-29
status: current
tags: [hial, vial, ial0, ial1, ial2, verification, sv-uvm, vhdl, architecture, task-tree]
evidence: docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE|Hardware IAL|Verification IAL|typed, language-neutral HIAL/VIAL bridge|VIAL0/VIAL1/VIAL2|typed native extension' docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/hial-vial-verification-fixture-architecture.md
---

The director established a peer-intent architecture requirement on
`2026-07-29`. Hardware IAL (HIAL) is the architectural name for the current
synthesizable IAL0/IAL1/IAL2 stack and must lower to synthesizable
SystemVerilog or synthesizable VHDL. Verification IAL (VIAL) is a proposed
pure-verification intent system that must lower to native SystemVerilog/UVM or
VHDL verification code for extensive test fixtures around HIAL-generated
designs.

HIAL and VIAL must meet at a typed, language-neutral bridge. Portable VIAL
must cover stimulus, transactions, scenarios, concurrency, expected outcomes,
temporal checks, reference models, scoreboards, coverage, and fault injection.
Typed native extensions preserve backend-specific expressive power without
recreating SystemVerilog/UVM or VHDL inside VIAL. VIAL0/VIAL1/VIAL2 is only a
layering hypothesis; the first architecture audit must select the minimum
useful topology and define parity, mixed-language, readability, traceability,
migration, validation, and large-design scalability contracts.

This requirement is parked under proposed, inactive task tree
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`. It extends the bounded completed
IAL1 verification-output frontier, whose shipped UVM and VHDL artifacts remain
inert skeletons. Parking the architecture does not activate it and does not
change the current IAL2 roadmap priority.
