---
id: vial-native-uvm-experimental-probe
title: The native UVM Verilator probe is tool-limited evidence, never product support
answers:
  - "can Verilator currently qualify full VIAL UVM support?"
  - "can FSMGen generate full UVM before a full simulator exists?"
  - "can Verilator compile or elaborate early generated UVM?"
  - "what exact open-source native UVM probe has FSMGen run?"
  - "did Verilator compile and run the selected UVM library?"
  - "did Verilator parse the complete generated VIAL UVM fixture?"
  - "what native UVM generator defect did the experimental probe find?"
  - "does the native UVM experimental probe advertise product support?"
  - "how do I rerun the native UVM experimental probe?"
date: 2026-08-10
status: current
tags: [hial, vial, sv-uvm, verilator, experimental-probe, simulator-profile]
evidence: >-
  docs/decisions/0050-vial-native-uvm-is-open-source-first-with-capability-gated-runtime.md;
  perl/FSM/VIAL/Backend/SVUVMExperimentalProbe.pm;
  scripts/run_vial_native_uvm_experimental_probe.pl;
  t/1592-vial-native-uvm-experimental-probe.t;
  vial/experimental_probes/sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0/README.md;
  vial/experimental_probes/sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0/probe-report.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  rg -n 'sv_uvm_experimental|656f20d087370a7c742e00188d20bbf30fa95339|partial_tool_limited|product_support'
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md
  docs/book/src/16d-hial-vial-verification-architecture.md
  vial/experimental_probes/sv_uvm_experimental.verilator_5_046.uvm_verilator_2020_3_1_vlt_656f20d0/probe-report.json &&
  prove -Iperl t/1592-vial-native-uvm-experimental-probe.t &&
  perl scripts/run_vial_native_uvm_experimental_probe.pl --check
---

Completed `.13.2` selects Verilator 5.046 plus CHIPS Alliance `uvm-verilator`
`uvm-2020-3.1-vlt` commit `656f20d087370a7c742e00188d20bbf30fa95339`
and tree `882930bb7debe79b22234e4a8a53854549046778`. The local bounded
probe validates them; its UVM library/control preprocess, parse,
compile/elaboration, and zero-error/fatal `run_phase` smoke pass. The generated
fixture preprocesses.

The probe found illegal use of SystemVerilog keyword `context` as an identifier;
the emitter/gallery now use `vial_context`. Strict fixture parsing then reaches
only unsupported `##[1:256]` SVA; separate `--bbox-unsup` compile/elaboration
reaches a Verilator internal fault/139. `UVM_NO_DPI` is experiment-wide.
Fixture runtime/results/parity/four-state/full breadth remain unexercised, so
the byte-checked report is `partial_tool_limited`, `product_support=false`.

A probe never becomes product support and never lends its parse, compile,
elaboration, or runtime result to ordinary emission; the qualified tier stays
with the future `sv_uvm_qualified` PGEN plus NEXSIM tuple recorded in
[[vial-native-uvm-emission-contract]]. Generation is therefore allowed to run
ahead of any single tool, while a demonstrated generator defect such as the
`context` keyword is fixed or tracked.

Related: [[vial-native-uvm-emission-contract]],
[[hial-vial-verification-fixture-architecture]].
