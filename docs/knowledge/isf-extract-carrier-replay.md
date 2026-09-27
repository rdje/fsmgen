---
id: isf-extract-carrier-replay
title: ISF extract emits a slice operator rejected by the active carrier frontend
answers:
  - "why does a lowered ISF extract fail strict carrier checking?"
  - "why did the wait extract test pass while public checking failed?"
  - "who owns the ISF extract carrier repair?"
date: 2026-09-27
status: current
tags: [isf, lowering, expressions, verification]
evidence: docs/audits/runtime-wait-book-20260927/fixtures.json; docs/audits/runtime-wait-book-20260927/baseline-drift.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; t/1244-isf-wait-clause-lowering.t; t/1101-isf-extract-slices.t
reverify: scripts/run_with_ram_guard.sh perl docs/audits/runtime-wait-book-20260927/verify.pl
---

The wait-book audit's `wait-dynamic-sample-extract` source lowers successfully
but its emitted carrier fails public strict checking with `Unsupported
expression operator 'slice'`. `_ir_extract` emits textual `(slice WORD HI LO)`;
the active ExpressionBuilder supports bracketed signal slices, not a `slice`
operator. An isolated direct SourceFrontend replay also rejects that carrier.
This is not a strict-mode-only boundary.

T1244's extract subtest checks emitted assignments and metadata but omits the
frontend/HDL helper invoked by neighboring cases. T1101 likewise checks slice
text. Their passes did not prove carrier replay for extraction.

SEMANTIC-INTROSPECTION-MCP-FRONTIER.53 owns the repair immediately after the
wait-book synchronization and before scoped identity integration. It must
preserve bit ranges, inferred widths and D-input capture timing, qualify native
check/semantic and API/MCP paths, and synchronize the book/spec. Until then,
the audit explicitly requires the exact refusal and the book marks the extract
fragment as intermediate output. No extract runtime or HDL support is earned
by the successful lower-only result.
