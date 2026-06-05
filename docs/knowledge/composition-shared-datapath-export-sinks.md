---
id: composition-shared-datapath-export-sinks
title: Generated-child shared-datapath export pins are bound to deterministic sink wires when unused
answers:
  - "what are shared_dp_unused wires?"
  - "why does apb_tb no longer trigger Verilator PINMISSING?"
  - "how are unused shared_datapath export ports bound?"
  - "are generated-child shared_dp_export pins intentionally connected?"
  - "is apb_tb in external validation smoke?"
date: 2026-06-05
status: current
tags: [composition, shared-datapath, validation, systemverilog]
evidence: perl/FSM/Composition/SharedDatapathSupport.pm; t/247-protocol-fixture-regression-smoke.t; t/308-systemverilog-external-validation.t; docs/book/src/09-generated-hdl-debugging-and-inspection.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: prove -Iperl t/247-protocol-fixture-regression-smoke.t t/146-composition-shared-datapath-lifted-register-runtime.t t/147-composition-shared-datapath-internal-lifted-register-runtime.t t/308-systemverilog-external-validation.t
---

Generated `?fsmc` child modules can carry `shared_dp_export_*` output pins so
composition shared-datapath lifting can consume per-value enable metadata. When
a top-level composition does not need a given export, FSMGen now binds that pin
to a deterministic one-bit top-local sink wire named
`shared_dp_unused_<instance>_<export>`. This keeps named child instantiations
warning-clean under Verilator `PINMISSING` without changing the public top
interface or the lifted shared-datapath runtime semantics. The APB composition
fixture `fsm/apb_tb.fsm` is the regression-backed example and is part of the
focused external SystemVerilog validation smoke.
