# IAL2 Post-Requester-WRAP-Repair Next Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.805`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.805` selects `.806`, a bounded current-
surface truthfulness repair, before activating the existing boundary-free AHB
active-transfer audit or adding another bus behavior.

The implementation surface is ahead of several canonical current documents:
all selected aggregate HBURST, aggregate BUSY-park, and paired BUSY `.ahb`
aliases ship and have focused parity coverage, while the mdBook's current AHB
navigation/mode tables and three antecedent behavior/fact pairs still describe
some of those aliases as deferred. This is user-visible documentation drift,
not a generator or runtime defect.

`.805` does **not** repair those surfaces. The pivot rule requires this selector
to commit cleanly first. `.806` may activate only from the clean post-`.805`
repository and must update current truth without rewriting historical
task/contract records that accurately describe what their own earlier slices
did not ship.

No parser, generator, public source, support-accounting entry, production test,
generated artifact, HDL/runtime behavior, backend, AXI/APB behavior, or VHDL
behavior changes in `.805`. Decision `0020` and its transaction-layer horizon
remain proposed/inactive.

## Runtime Truth

The repository contains all six profile aliases at issue:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

Their focused parity owners are t/1493, t/1497, t/1514, and t/1516. The AHB
mdBook inventory already lists the six aliases and reports thirty-eight public
AHB sources, confirming that the stale statements are internally contradictory
with the same chapter's source inventory.

## Drift Footprint And Root Cause

The current-truth footprint is bounded:

- `docs/book/src/16-ial2-protocol-platform-intent.md` says matching selected
  aliases exclude aggregate HBURST/BUSY-park surfaces and repeats aggregate
  HBURST aliases as future work.
- The current mode map and endpoint summary in
  `docs/book/src/16c-ial2-ahb.md` still defer aggregate HBURST aliases even
  though the inventory immediately above includes them.
- `docs/IAL2_AHB_AGGREGATE_HBURST_SEQ_BEHAVIOR.md` and fact
  `ial2-ahb-aggregate-hburst-seq-behavior` retain the `.770`-era alias deferral
  after `.772` shipped the aliases.
- `docs/IAL2_AHB_AGGREGATE_BUSY_PARK_PROPAGATION_BEHAVIOR.md` and fact
  `ial2-ahb-aggregate-busy-park-propagation-behavior` retain the `.782`-era
  alias deferral after `.784` shipped the aliases.
- `docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md` and fact
  `ial2-ahb-paired-busy-composition-behavior` still defer the two-subordinate
  paired alias after `.803` shipped it.

Root cause is later-slice backpatch incompleteness. Dedicated alias behavior
records, inventories, tests, README, roadmap, and task history were updated,
but not every antecedent document that also serves as a current behavior
surface. Historical selector, contract, and task-tree statements such as
"not shipped in this slice" remain accurate history and must not be flattened
into current-tense claims.

## Why Truthfulness Repair Comes First

| Candidate | Current evidence | Selection |
| --- | --- | --- |
| Current AHB book/behavior/fact truthfulness | Direct contradiction between existing alias files/tests/inventory and current user-facing deferrals | **Selected first as `.806`** |
| Boundary-free active-transfer audit | Canonical proposed tree exists and `.794` established its exact phase risk | Next behavior audit after `.806` dries out |
| Policy-driven or multiple BUSY insertion | Requires a new public control/state contract; current single-BUSY family is complete | Deferred |
| Distinct local bus-BUSY status | Changes requester status semantics and ports | Deferred |
| Larger/multi-word/indefinite bursts | Requires broader subordinate/interconnect storage and progression policy | Deferred |
| Optional AHB signals | Orthogonal property/signal contract | Deferred |

The documentation repair is smaller than every behavior-bearing alternative,
restores the director's only review surface, and prevents a later selector from
reasoning from false residue.

## Selected `.806` Contract

After `.805` commits cleanly, `.806` must:

- update the two current mdBook AHB navigation/mode surfaces to match the
  thirty-eight-source inventory and shipped aggregate/paired aliases;
- backpatch the three current behavior records and facts above with links to
  their later alias behavior owners;
- preserve time-local historical selector/contract/task statements;
- add focused t/1518 documentation-truthfulness coverage that ties the six
  checked-in alias paths to positive current-book/current-behavior claims and
  rejects the exact stale current-surface phrases;
- keep code, sources, support accounting, reports, generated artifacts, and
  runtime behavior byte-for-byte unchanged;
- sync README, ROADMAP_V2, mdBook backlog/current chapter, Knowledge Map,
  task tree, and Memory; and
- run t/1518, mdBook build, Knowledge Map, memory, path, diff, and doctrine
  gates before commit.

## Preservation And Rollback

`.806` must not edit generated behavior, public source data, support manifests,
or historical task evidence. Existing t/1493, t/1497, t/1514, and t/1516 remain
the alias parity authorities; t/1518 only locks documentation truthfulness.

`.805` rollback removes this selector record/fact and `.806` node and restores
the `.805` active frontier. `.806` rollback restores only the current-doc/fact
wording and focused truthfulness test; it cannot remove or redefine any shipped
alias. The canonical `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT` remains proposed
until selected from a later clean frontier.
