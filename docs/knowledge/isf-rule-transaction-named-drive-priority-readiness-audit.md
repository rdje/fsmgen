---
id: isf-rule-transaction-named-drive-priority-readiness-audit
title: Unique-caller target-local masking is ready for the named-drive priority contract
answers:
  - "what did the named-drive rule transaction priority audit prove?"
  - "why does direct rule transaction priority work while a named drive conflicts?"
  - "what does t1542 prove?"
  - "why must named-drive priority masking be target local?"
  - "why are shared multi-caller named drives ambiguous?"
  - "what contract follows ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1?"
date: 2026-07-30
status: current
tags: [isf, rule, transaction, named-drive, priority, selector, assertion, readiness]
evidence: docs/ISF_RULE_TRANSACTION_NAMED_DRIVE_PRIORITY_READINESS_AUDIT.md; docs/tasks/ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.md; t/1542-isf-rule-transaction-named-drive-priority-readiness.t; t/data/isf_rule_transaction_named_drive_priority_probe.isf; t/data/isf_rule_transaction_direct_priority_control.isf; perl/FSM/Scheduler/ISF/LoweringIR.pm
reverify: scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- env TMPDIR=.artifacts/tmp/tests prove -v t/1542-isf-rule-transaction-named-drive-priority-readiness.t
---

Audit `.1` selects proposed no-behavior contract `.2` for unique-caller,
target-local rule/transaction priority propagation through a named drive.

Direct assignments already work: the lower transaction assignment receives an
inverse higher-rule guard, schedule JSON reports the resolution, and
assertion-enabled runtime completes with the higher value. A named drive keeps
transaction provenance only on its `drive_call_start`; the shared output body
has owner kind `drive`, sees aggregate `drive_start`, reports warning
`isf_unproven_rule_drive_overlap`, and fails the generated different-value
selector assertion at runtime. Focused t1542 durably proves both cases.

Whole-drive masking is rejected because it would discard non-conflicting
outputs. A disposable caller-aware candidate instead guarded only the
conflicting drive-body target and passed with `out=1 side=1`. Shared drives are
also ambiguous: two transaction call sites collapse into one aggregate start,
so a priority involving only one caller must not suppress the other.

Contract `.2` must freeze bidirectional, per-target masking for exactly one
local transaction caller and fail closed for zero/multiple/generated-child or
otherwise ambiguous callers. It must preserve direct assignment semantics,
same-value assertions, rule/rule and transaction/transaction conflicts,
storage/resource priorities, reports, semantic surfaces, backends, and all
selector assertions. Audit `.1` changes no lowering or runtime behavior.

Clean audit commit `e715a34c7` activates only contract `.2`; current lowering
and generated behavior remain unchanged during contract selection.

Completed contract `.2` selects exact-one-local-caller bidirectional target-
local implementation `.3` with deterministic ambiguity failure. Clean contract
commit `b44afcc51` activates `.3` continuity-only. Decision `0023` and a
separate proposed task own the direct-VHDL unary-reduction defect discovered
during backend qualification.

Implementation `.3` now ships the selected repair and expands t1542 to both
priority directions, ambiguity/fail-closed boundaries, assertion-enabled
SystemVerilog, native Verilog, and the explicit direct-VHDL non-qualification.
See `isf-rule-transaction-named-drive-priority-behavior` for current behavior;
this card remains the dated readiness evidence.
