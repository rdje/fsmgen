---
id: isf-record-input-parser-mode
title: Both record-input emitter observations use the SystemVerilog parser
answers:
  - "do both record-input emitter observations prove Verilog-2005 syntax?"
  - "why did Verilog record-input output retain packed typedefs?"
  - "which parser mode did record-input native behavior qualify?"
date: 2026-10-01
status: current
tags: [isf, record, input, verilog, systemverilog, backend, qualification]
evidence: >-
  docs/audits/record-input-verilog-boundary-20261001/manifest.json;
  docs/audits/record-input-language-profile-20261001/manifest.json;
  docs/book/src/13j-type-enum-aggregate.md;
  docs/isf-spec/02-interface-transactions.md;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2028-isf-record-input-verilog-profile.t
---

The complete direct and generated native observations compile both emitter
options as `.sv` sources without an IEEE 1364 selector. Their captured Verilator
version is 5.050; its published default is SystemVerilog. Current FSMGen-only
emissions retain packed typedefs for direct, named-domain and blocking fixtures.
The compatibility conversion changes procedural block forms without converting
those types. Thus genuine binary behavior is qualified for the recorded
SystemVerilog parser mode; pure Verilog-2005 compatibility is unproved.

SEM `.60.4.3.2.5.5.3.2.1` reconciles the book/spec/feedback claims and inherited
storage walkthrough. Sibling `.2` qualifies current `verilog`/`v` HDL refusal for ISF record inputs,
from validated declarations before lowering/publication. Existing destinations
are preserved; metadata and schedule preview retain their source-level contract.
Complete SystemVerilog RTL equals the predecessor except date banners. SystemVerilog is the qualified record-input
profile; VHDL keeps its contextual refusal and destination guarantees. Record
outputs, root-list inputs and transaction aggregate ports remain deferred.

Exact original argv/results and source objects re-derive the observation scope.
Literal emitted syntax and hostile language-selector, missing-pair and type-erasure
controls provide falsification. Version-matched published documentation, sealed
source/emission/receipt identities and Git provide durability. No spent native
capture is replayed and no pure-mode compiler rejection is claimed.

Related: [[isf-record-input-backend-profiles]],
[[isf-record-input-direct-runtime]], [[isf-record-input-generated-runtime]].
