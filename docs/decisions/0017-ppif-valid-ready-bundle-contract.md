# 0017 — PPIF Valid-Ready bundle contract

- Date: 2026-06-12
- Type: architecture
- Status: accepted
- Builds on: `docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md`

## Context

The first public `.ppif` implementation supports one Valid-Ready channel object
per file. The readiness audit for future multi-channel `.ppif` support found
that parser relaxation alone would be unsafe: the adapter, generator result,
CLI artifact selection, ISF single-actor parser contract, and source-anchor
model all assume one Valid-Ready object.

The next design decision is whether a future multi-channel `.ppif` file should
emit one generated wrapper/top actor, several per-channel artifacts, or stay as
one object per file.

## Decision

Future multi-channel `.ppif` Valid-Ready support shall use an aggregate bundle
contract over per-channel generated artifacts.

Each authored `valid-ready-channel` object remains an independent
channel-level intent object. Each channel emits one reviewable generated `.isf`
actor and its generated `.fsm` artifacts. The PPIF result adds aggregate
`items[]` arrays and an aggregate IAL2 report schema:

```text
fsmgen.ial2.protocol_intent.valid_ready_bundle.v1
```

This decision does not introduce a hidden multi-actor `.isf` file and does not
allow direct `.ppif -> .fsm` lowering. The mandatory chain remains:

```text
IAL2 -> generated IAL1/.isf -> generated IAL0/.fsm -> HDL
```

The first future implementation may leave default HDL generation fail-closed
for multi-channel bundles until a later owner selects a wrapper/top actor or
explicit HDL entry-selection rule. It must not silently pick the first channel
as the HDL or semantic entry.

## Consequences

- The current single-object `.ppif` result and report schema remain stable
  until an explicit compatibility owner changes them.
- Multi-object `.ppif` support uses an aggregate result shape with
  `generated_ial1.items[]`, `generated_ial0.items[]`, `channels[]`, and
  aggregate artifact reporting.
- Channel-local source anchors may refine the required top-level source object;
  omitted channel sources must be reported as inherited, not as
  channel-specific evidence.
- `--emit-schedule-json` can expose the aggregate bundle report before wrapper
  HDL exists.
- Default HDL generation remains a separate future decision unless the
  implementation owner selects it explicitly. Aggregate semantic JSON is now
  selected as an aggregate PPIF bundle semantic root, not as a generated-channel
  root.
- Full AXI manager behavior, transaction IDs, outstanding windows, response
  matching, bursts, and cross-channel dependency rules remain outside this
  Valid-Ready bundle monitor contract.

## Implementation Note

`IAL2-PPIF-VALID-READY-BUNDLE-FIRST-SLICE.1` implements the bounded
report/review-artifact subset of this contract. Multi-channel `.ppif` bundles
now emit `valid_ready_bundle.v1` reports, write per-channel generated `.isf`
and `.fsm` artifacts with `--outdir`, and keep default HDL generation
fail-closed. `IAL2-PPIF-BUNDLE-SEMANTIC-JSON-FIRST-SLICE.1` adds aggregate
semantic JSON under `semantic.protocol_intent_bundle` without selecting wrapper
HDL or one generated `.fsm` root.
