---
id: isf-extract-carrier-replay
title: ISF extract replays scalar slices with inferred widths and captured values
answers:
  - "why does a lowered ISF extract fail strict carrier checking?"
  - "why did the wait extract test pass while public checking failed?"
  - "who owns the ISF extract carrier repair?"
date: 2026-09-27
status: current
tags: [isf, lowering, expressions, verification]
evidence: t/1931-isf-extract-carrier-replay.t; t/1932-isf-extract-runtime.t; perl/FSM/Scheduler/ISF/Emitter/FSM.pm; docs/audits/runtime-wait-book-20260927/fixtures.json; docs/audits/runtime-wait-book-20260927/baseline-drift.json; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm; t/1244-isf-wait-clause-lowering.t; t/1101-isf-extract-slices.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1931-isf-extract-carrier-replay.t t/1932-isf-extract-runtime.t
---

The wait-book baseline found that `_ir_extract` emitted `(slice WORD HI LO)`,
which the active ExpressionBuilder rejected. T1244's extract case checked text
and omitted the frontend/HDL helper; T1101 likewise checked text. Their green
results did not establish replay. The retained baseline and exact fixture own
that history; .53 repairs it rather than introducing a new public operator.

Extract now emits bracketed scalar slices and retains `<=` field captures.
The width collector includes the legal single-field clause, preserving its
whole-source inferred width. Assemble states retain their target/part identities
so the carrier emits their known scalar widths, respecting declarations,
type references and static constants. This prevents inferred concat-list
sources and default-width operands from contradicting the schedule's width
evidence. Only participating scalar names are added, not unused width-map entries.

T1931 compares complete native/API/newline check, semantic and schedule reports
for declared, assembled, explicit, inferred, single-field, scalar-bit,
constant-operand and pending-sample sources. Existing width/parameter and
malformed-clause tests retain their boundaries. T1244 now replays extraction
through the frontend/HDL helper. The wait-book verifier requires successful
strict replay for the formerly failing extract carrier.

T1932 independently checks actual SystemVerilog and VHDL field values, capture,
pending samples, hold and reset, including assembled-word round trips with
changing original inputs. Its bounded walking-bit/complement inputs and wait
variants do not claim exhaustive arbitrary-width coverage. Enable the Darwin
Verilator runtime flag and select a repository-local GHDL provider to run both
backend oracles; otherwise the relevant tool-dependent subtest skips explicitly.
