---
id: core-expression-width-inference
title: Core exact width inference has an explicit target-owned unsized literal boundary
answers:
  - "where is the shared Core expression width inference kernel?"
  - "how can a target supply unsized literal widths without changing Core defaults?"
  - "does exact width inference prove a generated helper placeholder or symbolic ancestry?"
  - "why can nested unsized literal helpers truncate a guards high bit?"
date: 2026-10-29
status: current
tags: [widths, literals, core, expression, source-capture]
evidence: >-
  perl/FSM/CoreExpressionWidthSupport.pm; perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm;
  t/2250-core-expression-width-contract.t; docs/audits/core-expression-width-contract-20261029.json.gz;
  docs/audits/literal-width-ownership-20261029/receipt.json.gz;
  perl/FSM/SourceLiteralWidthAllocationSupport.pm; t/2251-source-literal-width-holder.t;
  docs/audits/source-literal-holder-20261029.json.gz
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2250-core-expression-width-contract.t t/2251-source-literal-width-holder.t
---

CoreExpressionWidthSupport::infer_width is the bounded direct builder exact-width
walk. Its ordinary call leaves unsized literal widths unknown. An explicit
unsized_literal_width callback receives detached raw literal value/radix/width
with source JSON kinds intact; it supplies a validated width without changing
Core. Explicit literal widths bypass it. Unknown future classes cannot borrow it.
Scalar wrappers keep their results; cycles and over-bound walks remain unknown.
References read selected widths and do not expand other Signals' definitions.

Selected widths alone prove neither allocation ancestry nor that a helper's
compatibility placeholder is exact. This preparatory API does not yet alter the
backend consumer or symbolic floors. Required repair continues under
ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.4.1.2. Actual mutable literal sources retain the
final source/target disagreement; fixed sources currently generate without that
same final check. Full qualification remains .6.

T2250 distinguishes actual unknown widths, explicit floors, raw kinds, callbacks,
scalar results and bounded walks with fixed/mutable source controls. A resolver
variant replacing explicit widths fails the independent explicit-floor tests.
T2192 now asserts current symbolic ranges and whole-value gating; the exact
committed builder reproduced its stale numeric expectations before this repair.
Retained first failures, exact source/variant/logs and replay instructions are in
the evidence receipt. This records the qualified scope, not feature completion.

Revision-bound ownership diagnosis at the preparation commit: an unknown literal
helper retains nominal Core width. A nested parent reads that width as exact and
can emit a narrow destination that discards the literal high bit. Strict CLI and
debug trace reproduce the ordinary fixed artifact. Injected declaration capture
instead refuses; preserve those separate conditions. Source birth/unknown
propagation .1.2.2 and target/final agreement .1.2.3 own the immediate P1 repair.
The adjacent audit verify.py --current --qualify authenticates producer bytes,
source/target products and independent mask algebra while rejecting hostile
saved variants. It is manual, revision-bound diagnosis, not an unconditional
current-state watcher or external HDL runtime proof.

SourceLiteralWidthAllocationSupport now validates detached direct bitwise literal
allocation holders with nullable exact width and raw literal value/radix/size.
Actual identities, weak lifetime tokens, tracked revisions and a complete raw
capture barrier reject matching writes and late mutation. T2251 distinguishes
explicit floors and JSON kinds; an isolated omitted-barrier variant fails its
late-write control. This validator publishes no live source policy. Actual source
birth/completion and nested unknown propagation remain the next owned consumers.
