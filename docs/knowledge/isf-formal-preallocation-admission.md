---
id: isf-formal-preallocation-admission
title: Source preparation retains narrowly deferred direct-formal monitor collisions
answers:
  - "why did preparing a direct formal fail on a generated monitor name before allocation?"
  - "does formal preparation bypass production monitor collision checks?"
  - "what does deferred_formal_collisions mean in prepared source?"
date: 2026-09-27
status: current
tags: [isf, formals, scope, monitors, admission, reservations]
evidence: perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1941-isf-formal-preallocation-admission.t; t/1936-isf-formal-source-context.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1941-isf-formal-preallocation-admission.t t/1936-isf-formal-source-context.t t/1935-isf-local-declaration-admission.t t/1413-isf-trigger-anchor.t
---
Current integration: [production formal scope](isf-production-formal-scope.md)
now consumes the qualified preparation products. The producer-specific account
below records its original qualification boundary; pending global integration
statements are historical. Independent-controller and local-call execution
remain separately gated.


prepare_formal_source must obtain real helper names before complete formal
allocation, but _ir_monitor_check rejected a helper matching an unallocated
direct formal. The retained probe derives main_assert_1_age from an actual
monitor, then gives a direct formal that name. Raw preparation and production
both refused it. Explicit detached formal projection instead produces separate
formal and monitor counters with their own declared/generated widths.

Preparation now passes a private context only for direct transactions. It can
defer a monitor collision when the exact signal still has transaction_port role,
belongs to an unprojected explicit formal, and is absent from the fixed actor
signal/static/system names. Generated public formals receive no such context.
Explicit locals, actor storage/interfaces/constants/clock/reset and declarations
already carrying a physical identity retain the strict collision boundary.
Monitor shape, observed-signal/window checks, local declarations and other source
validation still run; a later invalid clause cannot yield a prepared result.

deferred_formal_collisions records source identity, detached formal declaration,
actual generated signal/width, monitor role and monitor state by transaction.
These are unallocated source products, not executable IR or a complete collision
census. Their maps can still overlap under raw names. The actual helper remains
in the conservative identifier inventory. There is no persistent mode on the
source actor or lowerer: build_module always performs the strict physical check.
A projected actor must pass real module/backend validation before emission.

T1941 covers each monitor role with direct input/output formals, raw production
refusal, strict projected carriers, resolved preparation without deferrals,
fixed/local/generated/projected negative controls, remaining source checks and
snapshot isolation. T1936/T1935 and monitor/binding/schedule regressions retain
the surrounding admission contract. This does not enable automatic production
rewriting, independent local controllers or complete namespace reservations.

Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.2. Remaining actual
module/child/domain producers are .3.2.2.2.3; completeness is .3.2.2.3.
