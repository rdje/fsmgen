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
  - "is Verilator enough to validate full SystemVerilog and UVM VIAL output?"
  - "what simulator capability profiles does VIAL require?"
  - "is Verilator the only planned VIAL simulator?"
  - "is Verilator a traditional event-driven simulator?"
  - "does Verilator support events with timing enabled?"
  - "is the HIAL VIAL architecture active now?"
date: 2026-07-30
status: current
tags: [hial, vial, ial0, ial1, ial2, verification, sv-uvm, vhdl, verilator, simulator-profile, architecture, task-tree]
evidence: docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/tasks/IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.md; docs/decisions/0004-simulate-to-catch-codegen-bugs.md; docs/TASK_TREE.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; https://verilator.org/guide/latest/overview.html; https://verilator.org/guide/latest/languages.html; https://verilator.org/guide/latest/connecting.html
reverify: rg -n 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE|Hardware IAL|Verification IAL|typed, language-neutral HIAL/VIAL bridge|VIAL0/VIAL1/VIAL2|typed native extension|portable SystemVerilog|full-language.SystemVerilog-UVM|full-LRM|capability profiles|event-capable compiled|traditional full-language event-driven' docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/TASK_TREE.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/hial-vial-verification-fixture-architecture.md
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

Validation is explicitly multi-profile. Verilator is the fast, portable
SystemVerilog execution tier for the synthesis-oriented language subset it
supports; it is not evidence that generated native VIAL exercises the complete
SystemVerilog LRM or UVM. Advanced SystemVerilog/UVM output therefore requires
a separate, capability-qualified full-language/UVM simulator profile, with the
tool version and exercised capabilities recorded. VHDL and mixed-language
verification use the same claim-by-capability discipline: portable,
full-language, and mixed-language validation are distinct gates.

Verilator is not a traditional full-language event-driven simulator. It
compiles the design into a model that is explicitly evaluated. With
`--timing`, supported delays, event controls, waits, forks, and delayed
processes participate in a timing-aware evaluation loop, so "event-capable
compiled simulation" is the useful precise description. Those scheduling
capabilities do not widen Verilator into the authoritative full-LRM/UVM tier.

This requirement is parked under proposed, inactive task tree
`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`. It extends the bounded completed
IAL1 verification-output frontier, whose shipped UVM and VHDL artifacts remain
inert skeletons. Parking the architecture does not activate it or change
current product behavior. Completed parent selector `.830` chooses the
narrower assertion-backed transaction-invoked named-drive priority audit;
HIAL/VIAL remains proposed and independently gated.
