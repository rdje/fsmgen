# IAL2 AHB Current-Surface Alias Truthfulness Repair

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.806`

Date: 2026-07-23

## Outcome

The mdBook's current AHB navigation/mode guidance and the canonical aggregate
HBURST, aggregate BUSY-park, and paired BUSY behavior/fact pairs now agree with
the checked-in public surface: all six selected aggregate/paired `.ahb`
profile aliases ship.

This is a documentation-truthfulness repair. It changes no parser, generator,
public source, support accounting, report/schema, generated artifact, HDL,
runtime behavior, port, diagnostic, backend, protocol, or VHDL contract.

## Shipped Alias Truth

The repaired current surfaces are anchored to:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

Existing parity/runtime ownership remains:

| Surface family | Alias parity | Runtime owner |
| --- | --- | --- |
| Aggregate HBURST, one/two subordinate | t/1493 | t/1492 |
| Aggregate BUSY-park, one/two subordinate | t/1497 | t/1496 |
| Paired BUSY, one subordinate | t/1514 | t/1513 |
| Paired BUSY, two subordinate | t/1516 | t/1515 |

No runtime proof is duplicated in this repair.

## Repaired Current Surfaces

- `docs/book/src/16-ial2-protocol-platform-intent.md` now presents the selected
  aggregate/paired `.ppif`/`.ahb` pairs as shipped and removes aggregate alias
  exposure from the future-work column.
- The current mode map and requester-to-aggregate guidance in
  `docs/book/src/16c-ial2-ahb.md` now agree with the same chapter's
  thirty-eight-source inventory.
- `docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md` and its fact point from the
  `.770` generic behavior to the `.772` shipped alias behavior.
- `docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md` and its fact
  point from `.782` generic behavior to `.784` alias behavior and no longer
  call bounded requester BUSY insertion future work.
- `docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` and its fact now point to
  both later paired aliases, including the two-subordinate `.803` surface.

## History Boundary

Time-local selector, readiness, contract-selection, task-tree, and behavior
statements such as "not shipped by this slice" remain historical evidence.
`.806` updates only files/sections whose contract is current truth. This keeps
git/task history honest while preventing current user guidance from presenting
shipped aliases as missing.

## Regression Lock

`t/1518-ial2-ahb-mdbook-current-surface-truthfulness.t`:

- requires all six alias paths to exist;
- extracts only the mdBook's current protocol-navigation, mode-map, and
  requester-guidance sections;
- requires positive shipped aggregate-alias language and rejects the exact
  stale current deferrals; and
- requires each of the three canonical behavior/fact pairs to link its later
  alias owner and omit its stale current residue claim.

The test intentionally does not scan historical sections globally.

## Remaining AHB Frontier

Policy/runtime or multiple BUSY insertion, distinct local bus-BUSY status,
halfword/word or wider/indefinite burst continuation, multi-word/register-bank
behavior, optional AHB signals, full manager behavior, direct backend,
verification output, backend-language variants, and VHDL remain future work.
The canonical `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT` remains proposed until
a later clean selector chooses it. Decision `0020` remains proposed/inactive.

## Rollback

Rollback removes t/1518 and this repair record/fact and restores only the
current-doc/fact wording changed by `.806`. It must not remove an alias, alter
support accounting, or rewrite historical task records.
