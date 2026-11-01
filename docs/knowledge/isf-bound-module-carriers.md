---
id: isf-bound-module-carriers
title: ISF scoped width/default module carriers
answers:
  - "where are scoped ISF width and default plans emitted into IAL0?"
  - "do bound module carriers establish generic HDL or generated-top forwarding?"
  - "do actor parameter widths retain HDL ranges?"
date: 2026-11-01
status: current
tags: [isf, widths, parameters, lowering]
evidence: perl/FSM/Scheduler/ISF/Emitter/FSM.pm; t/2142-isf-bound-module-carriers.t; docs/book/src/13-intent-scheduling.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/133[3-9]-*.t t/134[0-2]-*.t t/2142-isf-bound-module-carriers.t t/2114-isf-width-symbol-plans.t t/1398-isf-storage-reset-value.t
---

Module emitter `_width_symbols`: selected widths use `(param NAME)`; static
scalar arithmetic avoids type borrowing. Defaults keep scoped aliases/allocated captures/immutable static support.
Numeric caches never replace width/default trees. Literal/type/reset/legacy absent-plan controls preserve.

T2142: ordinary/generated/reusable/physical-domain modules, canonical parsing, caller kinds and wrong-cache controls. Carrier emission proves no
generic HDL/forwarding/specialization/public/runtime closure (manual generated
IAL0 widths; 0119).

T1333-T1337: actor param roots survive +size/eligible SV ranges; parser/reports
numeric; depths scalarize. Full/override/runtime stays open.
