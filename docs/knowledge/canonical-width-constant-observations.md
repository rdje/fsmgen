---
id: canonical-width-constant-observations
title: Positive scalar width observations preserve the actual constant-only fast path
answers:
  - "how is the direct sizing scalar-constant fast path captured without namespace borrowing?"
  - "why does a width observation use exact integer text instead of target literal formatting?"
date: 2026-10-27
status: current
tags: [widths, constants, source-capture, literals]
evidence: perl/FSM/Adapter/FSMGenFull/SignalManager.pm; perl/FSM/Package/IntegerLiteralSupport.pm; perl/FSM/Package/ScalarWidthSupport.pm; t/2157-positive-scalar-width-observations.t; docs/audits/positive-scalar-width-observations-20261027.json.gz
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2157-positive-scalar-width-observations.t t/2111-ial0-parameter-width-selection.t t/511-signal-manager-literal-symbol-defensive-copy-boundary-audit.t
---

resolve_positive_integer_scalar_observation returns width and a detached static
observation of the actual selected constant. The old numeric accessor shares
that selector. No aggregate/type/parameter namespace can supply a substitute;
the parser's named-type branch still precedes this fast path.

The shared positive-integer literal parser optionally returns exact decimal
text from the same parsed integer through a plain scalar output reference.
That output is cleared on refusal, while the existing native numeric return
stays unchanged. It retains integer digits independently of native conversion.

This is intrinsic width value. Target formatting separately range-checks a
raw legacy Literal's declared bit width, so it cannot reconstruct this selection.
Actual source collisions, legacy competing tables, range-invalid raw literals,
exact-digit/atomic-output and held-record ownership controls qualify the new
record; old captured width/default products remain exact.

This helper publishes no direct Signal binding, source grammar, scope or target
permission. Declared-width capture and Core publication remain successors.
