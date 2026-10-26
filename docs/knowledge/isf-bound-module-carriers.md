---
id: isf-bound-module-carriers
title: ISF module carriers render scoped width and default plans
answers:
  - "where are scoped ISF width and default plans emitted into IAL0?"
  - "do bound module carriers establish generic HDL or generated-top forwarding?"
date: 2026-10-26
status: current
tags: [isf, widths, parameters, lowering]
evidence: perl/FSM/Scheduler/ISF/Emitter/FSM.pm; t/2142-isf-bound-module-carriers.t; docs/book/src/13-intent-scheduling.md
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2142-isf-bound-module-carriers.t t/2114-isf-width-symbol-plans.t t/1398-isf-storage-reset-value.t
---

The shared module emitter consumes `_width_symbols`: selected parameter
widths use `(param NAME)`, static widths use scalar arithmetic to avoid type
namespace borrowing, and defaults retain scoped aliases, allocated captures
and immutable static support. Numeric width/default caches do not replace
these trees. Literal/type/reset and legacy absent-plan controls stay unchanged.

T2142 exercises ordinary, generated, reusable and physical-domain modules
through canonical source parsing, caller-kind preservation and wrong-cache
controls. Generated-top forwarding, generic HDL, specialization and complete
public/runtime qualification remain separately owned. See the manual's
generated IAL0 width section and decision 0119 for the complete boundary.
