---
id: isf-production-formal-scope
title: Production lowering separates direct formal storage and authored reports
answers:
  - "does normal compilation separate direct formals from actor pins and storage?"
  - "how does production formal renaming preserve authored schedule provenance?"
  - "where does normal compilation check final formal reservations?"
  - "why can direct formals work standalone but fail in reusable actors?"
date: 2026-10-22
status: current
tags: [isf, formals, scope, lowering, reports, domains]
evidence: docs/audits/imported-formal-boundary-20261002/probe-final.txt; perl/FSM/Scheduler/ISF/FormalLowering.pm; perl/FSM/Scheduler/ISF.pm; t/1963-isf-production-formal-families.t; t/1962-isf-production-formal-scope.t; t/1961-isf-formal-source-binding-reports.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1963-isf-production-formal-families.t t/1962-isf-production-formal-scope.t t/1961-isf-formal-source-binding-reports.t t/1955-isf-formal-domain-source-products.t t/1956-isf-formal-domain-outer-namespace.t; qualify Verilator runtime through FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 only on the already qualified host path.
---

Scheduler lower/report prepare contexts/reservations, allocate direct-formal
identities and resolve transaction/rule clauses on clones. Parent/domain/child
modules pass FormalReservationCoverage before emission. Raw LoweringIR remains
strict; scheduler source is physical. Private marked callers avoid re-projection;
mixed live marks refuse. No public marker.

Parent/domain direct formals are internal: width/role alone formerly exposed
undriven reads as public inputs (T1368). Coverage requires internal roles; T1963
checks exact semantic/SV/Verilog/VHDL read-only/unused ports. Declarations supply
no driver/initial value. Widths/types/roles stay separate from actor pins/storage/
sibling formals. Generated children keep public names; rules use actor scope. Static
counts, local shielding, zero pruning and source validation remain unchanged,
as does schema.

With record inputs, private input-formal writes refuse; ISF-REDUCTION-DELIVERY.8.

Library/ATL constructors clone/rename then enter raw _build_parent_ir without
child FormalLowering; library preparation uses root/parent producers only.
Pin/storage payload shadows reject library schedules (255), while the same
standalone actor (0) and ordinary/unused controls admit. P2 SEM
`.60.4.3.3.5.2.1.5.2.2.3.1.2.5` owns repair after the invocation census, before
origin qualification. Products/calls are archived; invalid initial actors syntax
proves no ATL admission. No silent corruption/native failure is inferred.

Detached report IR restores original bindings, wait/loop source fields,
temporal operands and bank accesses in exact identity/order; reductions are
re-derived from the selected original preparation actor. Executable IR
stays physical: its wait_count_source/loop_condition drive call/loop wiring,
so in-place report restoration corrupts emission. Storage/helpers stay
physical; source operands/bindings stay authored. Domains use their
original local preparation.

T1962 checks pin/storage shadows, strict carriers and whole native/API/newline
check/semantic/schedule parity. Independent SV/Verilog public-pin oracles observe
private waits, generated reads of unchanged actor storage, reset/repeated
activation without replay. Late declarations reject before FSM emission. Domains
cover different-width same-name formals/strict composition; T1961 separates
physical bindings from authored domain reports.

Production declarations/reports re-derive; shadows, immutability, late
declarations/public-pin runtime falsify; tests/scope guard endure. T1963 covers loop/exit/continue,
bank source versus physical operands, actor stages/monitors, typed sibling
permutations, a real rule-helper name collision, parameter/constant/package widths
and backend selectors. Prior native evidence does not close historical process containment.
Sibling-controller/local-call execution, local physical ownership and SPECFORGE
storage reporting retain separate gates.
Owners: SEM .49.2.2.3.3.2/.49.2.2.3.4; reusable exception .60...3.1.2.5.
