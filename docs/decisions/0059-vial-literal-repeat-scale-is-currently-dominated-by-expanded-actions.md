# 0059 — VIAL literal-repeat scale is currently dominated by expanded actions

- Date: 2026-08-10
- Type: verification architecture/limit interaction
- Status: observed and routed by `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.2`
- Refines: [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md)
- Repair owner: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4`

## Context

The selected semantic catalog has independent 65,536 expanded-action and
1,000,000 literal-repeat limits. The shipped semantic builder counts a repeat
action plus its expanded body actions before enforcing the scenario cap. A
one-action body therefore reaches 65,536 expanded actions at repeat count
65,535 and rejects count 65,536 before the separate repeat-count ceiling.

The selected repeat gate candidate 4,096 succeeds. The 262,144 qualification
candidate and 1,000,000 exact-repeat boundary deterministically reach the
earlier action cap; 1,000,001 rejects directly at the repeat-count validator.
No legal non-empty repeat body can isolate the higher accepted boundary.

## Decision

1. The semantic generator constructs the selected sources without changing
   either cap.
2. Its reusable oracle records qualification and exact-repeat runs as expected
   earliest authoritative rejections plus one closed
   `VIAL_SCALE_LIMIT_INTERACTION` discrepancy.
3. `.17.4`, already selected for missing or incorrect early cap enforcement,
   alone may decide whether to change count semantics or the selected limits.
   Any repair must preserve accepted-profile meaning and rerun the full
   boundary/over-bound proof.
4. Keep the scoped-ID and repeat-limit findings in one dedicated query-first
   Knowledge Map card rather than adding more pressure to the broad HIAL/VIAL
   architecture card, which is already near its per-card rollover target. This
   approves the exact bounded collection change below and no other ceiling.

- Ceiling authority: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.2-KNOWLEDGE-CARD`
- Surface: `knowledge_cards`
- Dimension: `files`
- Change: `1106 -> 1107`
- Transition allowance from the immutable 1,105-card baseline: at most two
  files, 158 aggregate lines, and 11,861 aggregate bytes for this slice.

## Consequences

- `.17.2.2` remains an honest construction/correctness proof and publishes no
  unsupported repeat capacity.
- `.17.3` must not measure the dominated repeat qualification/limit levels as
  accepted workloads.
- The existing diagnostics, parser limits, support classification, and public
  capability set are unchanged by this decision.
- The canonical knowledge collection grows by exactly one card while staying
  below every health target and every non-file enforcement ceiling.
