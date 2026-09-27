# 0111 — Same-value selector fan-in is compatible

- Date: 2026-09-28
- Type: backend and semantic report contract
- Status: accepted
- Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.32.1.3.3.1.3.3.2.2.3.2.2.2.2.2.2

## Context

Strict ISF admission accepts equal-value writes with matching timing. The
generated backend groups their source enables into one RHS value family and
ORs those enables. T1974 nevertheless fails a generated SystemVerilog
`$onehot0` assertion when an admitted rule and transaction both select `9`.
The emitted data selection is unambiguous; the assertion imposes exclusivity
that the source and value-family contracts do not require. T1211 previously
checked the assertion text without executing that allowed overlap.

## Decision

An analyzed same-RHS selector family permits concurrent source enables. Its
legacy `same_value_assertion` metadata key remains, with the existing key
shape and source list; `kind => compatible_fanin` identifies that policy.
No source-exclusivity assertion is emitted for this policy. Consumers must
read the policy kind instead of assuming that every legacy assertion field
describes a one-hot obligation.

Distinct RHS value-family enables retain `multi_value_assertion.kind =>
onehot0` and the corresponding SystemVerilog check. Explicit `onehot0`
metadata still renders that obligation. Standalone decision-tree and shared
composition ownership/exclusivity contracts use their separate producers and
are unchanged. Verilog continues to emit no SystemVerilog assertions.

## Consequences

This corrects a metadata value and emitted verification policy without changing
report key families, source admission, data muxes, priority masks or scheduling.
Same-value family entries remain discoverable under `selector_conflict_targets`
for report compatibility; their presence alone does not mean an exclusivity
assertion exists. Different-value checking remains mandatory.

The original executed failure and its public reconstruction stay sealed in
`docs/audits/priority-contributor-repair-20260928/`. Static contract repair
precedes separately owned observed positive/negative execution. That execution
must allow the compatible control and reject a deliberately broken
different-value mask before complete priority runtime signoff. No runtime
assertion flag or process-admission rule is disabled.
