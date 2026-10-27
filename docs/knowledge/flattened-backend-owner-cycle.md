---
id: flattened-backend-owner-cycle
title: Direct backend helper back-references retain released contexts and modules
answers:
  - "does ordinary direct backend generation retain a released Core module?"
  - "why must prepared-plan ownership tests isolate the existing backend owner cycle?"
date: 2026-10-27
status: current
tags: [backend, ownership, defects, memory]
evidence: docs/audits/direct-width-target-plans-20261027.json.gz; perl/FSM/HDL/FlattenedDT.pm; perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm; docs/tasks/ISF-REDUCTION-DELIVERY.md
reverify: python3 -B docs/audits/direct-width-target-plans-20261027.py --self-test
---

Actual params-only parsed modules release after callers leave scope. Ordinary
numeric SystemVerilog backend generation retains both its backend and module,
without invoking any new declared-width plan helper. FlattenedDT owns its
ModulePlanningSupport helper, which stores a strong flattened_dt back-reference.
An isolated context/planner pair retains planner, context and module; weakening
only that isolated back-edge releases all of them. The complete actual probe,
source and products are retained in the evidence packet.

This establishes an existing backend retaining cycle, separate from the earlier
DeclarativeSymbolResolver closure defect under .19. Complete backend graph and
ownership repair is scheduled under ISF-REDUCTION-DELIVERY.25 after required
feature implementation and before .6, earlier if resource-blocking. Do not
weaken every helper field without preserving standalone ownership contracts.
No repaired production release, memory-size/rate or global leak-free claim.

T2173 isolates new-result ownership with a physical Core copy that was never
installed into the numeric backend, retaining actual Signal observations and
actual target namespace/declaration inputs. Its held plan does not retain that
copy or caller target records. Passing this bounded control does not establish
whole numeric backend release; replay the independent packet probe for that.
