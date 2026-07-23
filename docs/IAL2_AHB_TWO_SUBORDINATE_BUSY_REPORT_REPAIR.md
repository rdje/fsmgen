# IAL2 AHB Two-Subordinate BUSY Report Repair

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.799`

Date: 2026-07-23

## Outcome

`.799` restores one truthful interpretation across the two shipped
two-subordinate HBURST BUSY-park report residues. Parked generic `.ppif` and
profile-alias `.ahb` reports now say BUSY parking ships in both the broader
interconnect residue and the dedicated burst residue. Non-parking sources keep
their BUSY-continuation deferral.

This is report text only. It does not change parsing, normalized contracts,
IAL1/IAL0 artifacts, SystemVerilog, runtime bus behavior, public sources,
support identities/counts, residue ids/structure, backend behavior, AXI/APB,
or VHDL.

## Root Cause

`AhbInterconnect::_unsupported_residue` already computed:

```text
hburst_seq_policy_selected
hburst_busy_park_selected
```

The dedicated `ahb_burst_seq_support_deferred` detail branched on the BUSY-park
predicate, but the two-subordinate
`ahb_broader_interconnect_decode_deferred` detail branched only on the generic
HBURST predicate. Parked sources therefore exposed these incompatible claims:

```text
broader residue: BUSY-in-burst continuation remains future work
burst residue:   BUSY-in-burst parking ships
```

## Exact Repair

For `subordinate_count == 2`, the broader detail now tests
`hburst_busy_park_selected` first. Its parked branch records:

```text
subordinate-owned byte/halfword/word narrow transfers
byte-only HBURST WRAP4/INCR4 in-word SEQ propagation
with BUSY-in-burst parking
```

The parked deferred list no longer contains `BUSY-in-burst continuation`.
Every other future item remains. The next branch is the unchanged non-parking
HBURST detail, which still contains `BUSY-in-burst continuation`.

One-subordinate sources use `ahb_multi_subordinate_decode_deferred`, not this
two-subordinate detail, and are unchanged.

## Locked Public Cases

| Surface | BUSY policy | Broader report result |
|---|---|---|
| two-subordinate `.ppif` | every child parks BUSY | shipped parking; no BUSY-continuation deferral |
| two-subordinate `.ahb` | every child parks BUSY | same, after alias-only residue cleanup |
| two-subordinate `.ppif` | children clear/ignore BUSY | BUSY continuation remains deferred |
| two-subordinate `.ahb` | children clear/ignore BUSY | BUSY continuation remains deferred |

The matching dedicated burst residue remains unchanged in all four cases.

## Verification

- Perl syntax passed for `AhbInterconnect.pm` and t/1492, t/1493, t/1496,
  and t/1497.
- `prove -j2` passed all four focused files / 20 tests in 867 wall-clock
  seconds.
- t/1496 and t/1497 assert corrected parked generic/alias topology wording.
- t/1492 and t/1493 assert preserved non-parking generic/alias deferral.
- Direct macOS monitoring observed 59-70% free memory and generator RSS below
  1.5 GiB.
- Documentation, Knowledge Map, memory architecture, mdBook, and doctrine gates
  complete the slice closeout.

## Next Frontier

`.800` owns public contract selection for the generation-ready generic
two-subordinate paired AHB BUSY composition. Decision `0020`, its transaction
layer horizon, and proposed audits remain inactive.

## Rollback

Revert the added BUSY-park branch and the four focused wording assertions, then
remove this document/fact and restore `.799` active. No generated artifact or
support catalog rollback is needed.
