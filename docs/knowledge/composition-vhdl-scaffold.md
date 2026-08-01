---
id: composition-vhdl-scaffold
title: Composition VHDL generation has a separately scoped shipped subset
answers:
  - "does --language vhdl work for composition tops?"
  - "does target_language vhdl work for composition roots?"
  - "which composition VHDL subset is shipped?"
  - "does composition VHDL support standalone-DT children?"
  - "does composition VHDL support standalone-DT generic maps?"
  - "does composition VHDL support standalone-DT scalar generic maps?"
  - "does composition VHDL support standalone-DT scalar expression generic maps?"
  - "does composition VHDL support standalone-DT one-bit generic maps?"
  - "does composition VHDL support one-bit standalone-DT generic maps?"
  - "does composition VHDL support standalone-DT multi-bit generic maps?"
  - "does composition VHDL support multi-bit standalone-DT generic maps?"
  - "does composition VHDL support standalone-DT bitstring generic maps?"
  - "does composition VHDL support standalone-DT list generic maps?"
  - "does composition VHDL support standalone-DT packed-list generic maps?"
  - "does composition VHDL support standalone-DT map generic maps?"
  - "does composition VHDL support standalone-DT packed-map generic maps?"
  - "does composition VHDL support standalone-DT non-packed aggregate generic maps?"
  - "does composition VHDL support standalone non-packed aggregate generic maps?"
  - "does composition VHDL support generated-FSM children?"
  - "does composition VHDL support C2 generated-FSM children?"
  - "does composition VHDL support APB/C4 generated-FSM children?"
  - "does composition VHDL support APB composition tops?"
  - "does composition VHDL support APB/C4 composition tops?"
  - "does composition VHDL support APB/C4 scalar generic maps?"
  - "does composition VHDL support APB/C4 scalar expression generic maps?"
  - "does composition VHDL support APB/C4 one-bit generic maps?"
  - "does composition VHDL support APB/C4 multi-bit generic maps?"
  - "does composition VHDL support APB/C4 bitstring generic maps?"
  - "does composition VHDL support APB/C4 aggregate generic maps?"
  - "does composition VHDL support APB/C4 packed aggregate generic maps?"
  - "does composition VHDL support APB/C4 non-packed aggregate generic maps?"
  - "does composition VHDL support non-packed aggregate generic maps?"
  - "does composition VHDL support APB/C4 package-backed generic maps?"
  - "does composition VHDL resolve APB/C4 package constants in generic maps?"
  - "does --language vhdl work for standalone-DT composition tops?"
  - "does --language vhdl work for C2 generated-FSM composition tops?"
  - "does --language vhdl work for APB/C4 composition tops?"
  - "does target_language vhdl work for standalone-DT composition roots?"
  - "does target_language vhdl work for C2 generated-FSM composition roots?"
  - "does target_language vhdl work for APB/C4 composition roots?"
  - "does composition VHDL support generic maps?"
  - "does composition VHDL support external RTL generic maps?"
  - "does composition VHDL support generated-FSM generic maps?"
  - "does composition VHDL support generated-child generic maps?"
  - "does composition VHDL support generated-FSM one-bit generic maps?"
  - "does composition VHDL support one-bit generated-FSM generic maps?"
  - "does composition VHDL support generated-FSM non-packed aggregate generic maps?"
  - "does composition VHDL support C2 generated-FSM non-packed aggregate generic maps?"
  - "does composition VHDL support bitstring generic maps?"
  - "does composition VHDL support sized bitstring generic actuals?"
  - "does composition VHDL support scalar expression generic maps?"
  - "does composition VHDL support expression generic actuals?"
  - "does composition VHDL support aggregate generic maps?"
  - "does composition VHDL support aggregate generic actuals?"
  - "does composition VHDL support declared aggregate structural types?"
  - "does composition VHDL support declared aggregate top ports?"
  - "does composition VHDL emit VHDL record/array declarations?"
  - "does composition VHDL support VHDL records or arrays?"
  - "does composition VHDL support list generic actuals?"
  - "does composition VHDL support record generic actuals?"
  - "does composition VHDL support external-RTL non-packed aggregate generic maps?"
  - "does composition VHDL support external non-packed aggregate generic maps?"
  - "does composition VHDL support package-backed generic maps?"
  - "does composition VHDL support package-backed generic actuals?"
  - "does composition VHDL emit package constants in generic maps?"
  - "does composition VHDL support external RTL one-bit generic maps?"
  - "does composition VHDL support one-bit external RTL generic maps?"
  - "is composition VHDL supported?"
date: 2026-08-01
status: current
tags: [vhdl, backend, composition, generics]
evidence: >-
  docs/VHDL_SCOPE.md; docs/book/src/14l-backends-validation-and-apis.md;
  docs/book/src/10-errors-strict-mode-and-troubleshooting.md;
  docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md
reverify: >-
  prove -Iperl t/1420-vhdl-direct-backend-scaffold.t
  t/386-hdl-generator-facade-target-language-boundary-audit.t
  t/114-composition-target-support-diagnostics.t t/313-hdl-external-validation-contract.t
---

Composition roots have a separately bounded VHDL contract covering the shipped child, generic-map, and structural-type shapes. Read `docs/VHDL_SCOPE.md` and the mdBook for the complete current boundary.

Exact pre-containment combined prose is retrievable with `git show aadbd14a5:docs/knowledge/direct-vhdl-scaffold.md`.
