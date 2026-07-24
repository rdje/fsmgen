# IAL2 Post-Current-Surface-Repair Next Owner Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.807`

Date: 2026-07-23

Current resolution: the selected audit proved the generated-family defect and
`.3` repaired it as documented in
`docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md`. The selector below is
time-local pre-repair evidence; the direct lower-layer seed remains distinct
and is audited by `.4`.

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.807` selects the existing canonical
`IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT` as the next exact AHB owner. Its
first leaf must runtime-prove and select the phase-ownership contract for a
selected active address phase that is replaced directly by another active
address phase without an unselected, `IDLE`, or `BUSY` boundary.

This selector does not activate the proposed audit. `.807` must commit cleanly
before the pivot. No parser, generator, public source, support accounting,
test, generated artifact, HDL/runtime behavior, backend, AXI/APB behavior, or
VHDL behavior changes here. Decision `0020` and the protocol-neutral
transaction-layer horizon remain proposed/inactive.

## Evidence Read

The selector reconciled:

- `.805`/`.806`, the corrected thirty-eight-source AHB current book/behavior
  surface, and t/1518 documentation-truthfulness lock;
- `.794` paired BUSY behavior and its requester/subordinate phase prerequisite
  repairs;
- current `AhbRequester` transfer presentation, `AhbSubordinate`
  `ahb_access_active_q` admit/release rules, t/1513 and t/1515 generated-HDL
  paired proofs, and current aggregate residue;
- the complete requester/subordinate/interconnect/BUSY/HBURST lineage,
  support/language/capability surfaces, README, ROADMAP_V2, mdBook, Knowledge
  Map, Memory, canonical proposed audits, and decision `0020`.

The current generated subordinate owns one admitted active transfer with:

```text
admit when:
  !ahb_access_active_q && HSEL && HREADY && HTRANS in {NONSEQ, SEQ}

release when:
  ahb_access_active_q && (!HSEL || HTRANS == IDLE || HTRANS == BUSY)
```

This prevents duplicate admission of one held transfer. It does not release or
recapture when a completed active transfer is followed immediately by a new
`NONSEQ`/`SEQ` address phase. The shipped paired requester intentionally emits
a boundary around completed transfers, and t/1513/t1515 prove that bounded
shape, not boundary-free active-to-active replacement.

## Why The Phase Audit Comes Next

| Candidate | Current evidence | Selection |
| --- | --- | --- |
| Boundary-free active-transfer phase audit | Existing canonical task; concrete admit/release gap established by `.794`; no generated-HDL active-to-active proof | **Selected** |
| Policy/runtime or multiple BUSY insertion | Requires new requester policy/state/public control beyond the complete single-BUSY family | Deferred |
| Distinct local bus-BUSY status | Changes requester status semantics and ports | Deferred |
| Halfword/word or wider/indefinite bursts | Requires broader subordinate/interconnect storage and progression policy | Deferred |
| Optional AHB signals | Orthogonal property/signal contracts | Deferred |
| Another current-truth prerequisite | `.806` plus t/1518 closes the proven alias-truth contradiction | No remaining prerequisite found |

The phase audit is evidence-first and behavior-free. A generated-HDL result can
show that the current ownership already works, select a fail-closed/boundary
contract, or justify one bounded phase-tracking repair. It does not presume
which outcome is correct.

## Selected Audit Contract

After `.807` commits cleanly,
`IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.1` must:

- activate the existing task tree before adding a probe;
- generate a public AHB subordinate source and drive consecutive selected
  `NONSEQ`/`SEQ` address phases with no unselected/IDLE/BUSY boundary;
- record address-phase presentation, data-phase completion, `HREADY`/
  `HREADYOUT`, `HRESP`, `ahb_access_active_q`, accepted-transfer count, and
  storage effects;
- distinguish a held address phase from a genuinely new active phase and prove
  each intended transfer is accepted/completed at most and at least once;
- correlate the result with generated IAL1/IAL0 admit/release states;
- make no behavior change in the audit leaf; select a separate bounded repair
  or explicit fail-closed contract only from runtime evidence;
- preserve requester WRAP4/8/16 repair, SINGLE/INCR4 completion, BUSY insertion,
  endpoint/aggregate BUSY parking, paired one-/two-subordinate compositions,
  aliases, current t/1518 truth surfaces, support/report/artifact identities,
  and decision `0020` inactivity; and
- run the generated-HDL audit under direct memory-pressure and the 4-GiB
  descendant guard, then sync behavior docs, mdBook, Knowledge Map, task tree,
  and Memory.

## Preservation And Rollback

The audit must retain t/1473, t/1475, t/1494, t/1498, t/1511, t/1513, t/1515,
t/1517, and t/1518 as focused preservation authorities, choosing the smallest
runtime subset warranted by any proven result.

`.807` rollback is documentation-only: remove this selector record/fact,
restore `.807` active, and remove the selected activation pointer. No shipped
behavior changes. The audit rollback removes only its new runtime probe and
result record and restores the tree to proposed status.
