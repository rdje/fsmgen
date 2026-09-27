---
id: isf-rule-transaction-named-drive-priority-behavior
title: Unique-caller named drives honor target-local rule/transaction priority
answers:
  - "does rule transaction priority work through a named drive?"
  - "how does named drive priority preserve non-conflicting outputs?"
  - "what happens when a named drive has multiple callers and priority?"
  - "what is isf_ambiguous_rule_transaction_drive_priority?"
  - "does transaction over rule work for named drives?"
  - "is named drive priority qualified in SystemVerilog Verilog and VHDL?"
date: 2026-09-27
status: current
supersedes: isf-rule-transaction-output-priority-gap
tags: [isf, rule, transaction, named-drive, priority, selector, conflict, backend]
evidence: docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_BEHAVIOR.md; docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_CONTRACT_SELECTION.md; docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1542-isf-rule-transaction-named-drive-priority-readiness.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1542-isf-rule-transaction-named-drive-priority-readiness.t t/1543-direct-vhdl-reduction-expression-readiness.t; T1542 requires the qualified Darwin runtime opt-in on macOS, and a skip is not runtime revalidation.
---

Named drives with exactly one distinct local transaction caller and no
generated source now participate in actor-level rule/transaction priority as
that logical transaction while retaining raw `drive` provenance.

Priority is assignment-local in both directions. A higher rule masks only the
conflicting drive-body target. A higher transaction masks only the conflicting
rule under the drive-body activation. Drive requests, transaction progression,
completion, parameters, and non-conflicting outputs remain active.

Unique unordered different-value conflicts fail through
`isf_conflicting_rule_transaction_writes`. Prioritized shared/generated/mixed
ownership fails through `isf_ambiguous_rule_transaction_drive_priority` with
`ambiguous_drive_caller`; unordered ambiguous ownership keeps the current
warning. Same-value fan-in remains compatible, selector assertions remain,
and public report/semantic schemas do not widen.

SystemVerilog and native Verilog have executable runtime qualification. Direct
VHDL now emits token-free scalar identity/complement expressions after reduction
lowering commit 2879f22af56e1835a9afe52476e2d8cee6147245. T1542/T1543 qualify
generation; external VHDL compile/runtime remains unqualified under decision
`0023`. See `direct-vhdl-reduction-expression-lowering-behavior` for the current
backend boundary. Keep the RAM guard defaults when reverifying; enable the
Darwin runtime opt-in only on a host with current qualification.
