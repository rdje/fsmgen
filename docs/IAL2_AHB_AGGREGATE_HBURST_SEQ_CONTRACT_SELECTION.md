# IAL2 AHB Aggregate HBURST SEQ Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.769`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.769` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.770`, direct implementation of the
combined bounded generic `.ppif` AHB aggregate HBURST-aware byte-lane `SEQ`
propagation family.

The selected implementation must add exactly these generic public sources:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
```

Matching aggregate `.ahb` aliases are not part of `.770`. They remain
separate follow-on work after the generic `.ppif` behavior, reports, support
accounting, tests, and docs ship.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Selected Source Family

The selected family reuses the shipped aggregate AHB byte-lane `SEQ`
interconnect topologies and replaces only the embedded subordinate endpoint
objects with selected HBURST-aware byte-lane `SEQ` subordinate objects.

The one-subordinate source is:

```text
path: ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
intent_name: ahb_interconnect_byte_lane_hburst_seq
source object: fsmgen-ahb-interconnect-byte-lane-hburst-seq
anchor: ARM-AMBA-AHB-IHI0033-C-2021-09 / bounded-ahb-interconnect-byte-lane-hburst-seq-propagation / first-public-contract
requester object: amba_requester
subordinate object: ahb_lite_subordinate_byte_lane_hburst_seq
interconnect object: ahb_tb
child binding: (subordinate regs ahb_lite_subordinate_byte_lane_hburst_seq)
subordinate-local burst binding: (burst HBURST_REGS width 3)
window: REG_BASE=0, REG_SIZE=4
```

The two-subordinate source is:

```text
path: ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
intent_name: ahb_interconnect_two_subordinate_byte_lane_hburst_seq
source object: fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq
anchor: FSMGEN-AHB-TWO-SUBORDINATE-BYTE-LANE-HBURST-SEQ-CONTRACT / bounded-two-subordinate-byte-lane-hburst-seq-propagation / first-public-contract
requester object: amba_requester
subordinate objects: ahb_status_subordinate_byte_lane_hburst_seq, ahb_control_subordinate_byte_lane_hburst_seq
interconnect object: ahb_tb
child bindings: (subordinate status ahb_status_subordinate_byte_lane_hburst_seq), (subordinate control ahb_control_subordinate_byte_lane_hburst_seq)
subordinate-local burst bindings: (burst HBURST_STATUS width 3), (burst HBURST_CONTROL width 3)
windows: STATUS_BASE=0/STATUS_SIZE=4, CONTROL_BASE=4/CONTROL_SIZE=4
```

Both sources keep explicit `(profile ahb)` and keep the same AHB requester,
interconnect, address-map, decode, and wiring vocabulary as the shipped
aggregate byte-lane `SEQ` sources.

## Selected Subordinate Policy

Every embedded subordinate in the selected sources uses the shipped
HBURST-aware byte-lane `SEQ` transfer contract:

```text
(burst HBURST_* width 3)
(supported-transfer nonseq)
(supported-size byte)
(supported-size halfword)
(supported-size word)
(lane-order little-endian)
(narrow-write preserve-inactive-lanes)
(narrow-read zero-fill-inactive-lanes)
(unaligned-access error)
(crossing-access error)
(seq-policy hburst-in-word-progressive)
```

The selected transfer name is:

```text
ahb_lite_byte_lane_hburst_seq_access
```

The embedded subordinates keep `supported-transfer nonseq` for compatibility
and add structured `transfer.seq_policy` in reports. Accepted HBURST `SEQ`
completion remains subordinate-owned and bounded to byte-sized `WRAP4` and
`INCR4` bursts inside one local 32-bit register word after prior OKAY
`NONSEQ` or valid `SEQ` history, expected next local address, stable `HBURST`,
stable `HWRITE`, and stable `HSIZE`.

## Selected Aggregate Semantics

The selected aggregate HBURST `SEQ` sources do not add a new interconnect
transfer engine. They propagate the existing aggregate signals to selected
subordinates and leave byte-lane, narrow-transfer, and HBURST `SEQ` acceptance
to the selected subordinate endpoints.

The aggregate decode policy remains:

- exactly one requester;
- exactly one or two subordinate endpoints, matching the selected source;
- static 32-bit, 4-byte-aligned windows;
- fixed `HGRANT=1`;
- active transfer when `HTRANS != IDLE`;
- selected subordinate local address `HADDR_* = HADDR - window_base`;
- unselected subordinate selects low and local addresses zero;
- selected subordinate `HREADYOUT_*`, `HRDATA_*`, and one-bit `HRESP_*`
  muxed back to the requester; and
- interconnect-owned two-cycle ERROR for unmapped active transfers.

Mapped hits forward `HADDR`, `HTRANS`, `HBURST`, `HWRITE`, `HSIZE`, `HWDATA`,
and `HREADY` to the selected HBURST-aware byte-lane `SEQ` subordinate child.
The selected child owns byte/halfword/word narrow-transfer behavior, byte-only
`WRAP4`/`INCR4` HBURST `SEQ` history/progression, mapped-hit ERROR responses,
wait cycles, reads, and writes. The interconnect maps subordinate one-bit
`HRESP=0/1` to requester two-bit `HRESP=2'b00/2'b01`.

The selected child HBURST fanout is direct requester/global fanout:

```text
requester.HBURST -> regs.HBURST_REGS
requester.HBURST -> status.HBURST_STATUS
requester.HBURST -> control.HBURST_CONTROL
```

The fanout is not selected through the generated fabric child and does not add
interconnect HBURST state. Unselected children may receive the same global
HBURST value; their `HSEL_*` remains low and their local address remains zero,
so the selected subordinate policy ignores the transfer.

## Source Syntax And Static Diagnostics

`.770` must not introduce a new top-level wiring clause for child-local
HBURST. Child-local HBURST names are selected by each embedded subordinate
`bus` block, and the aggregate implementation must resolve them from child
reports.

Malformed or unsupported aggregate HBURST shapes must fail closed with
targeted diagnostics when:

- an embedded HBURST-aware subordinate has no `(burst ... width 3)` binding;
- an embedded subordinate burst binding has width other than 3;
- an embedded subordinate uses `(seq-policy hburst-in-word-progressive)` but
  the aggregate requester/global wiring has no `(burst HBURST width 3)`;
- multiple children in one aggregate source reuse the same subordinate-local
  HBURST signal name;
- a child-local HBURST signal collides with another generated local child port
  in the same child instance;
- the implementation cannot wire requester/global `HBURST` to every
  HBURST-aware child-local burst input; or
- a mixed aggregate attempts to report HBURST propagation without all selected
  subordinate children using `ahb_lite_byte_lane_hburst_seq_access`.

Existing endpoint diagnostics for duplicate child `(burst ...)` clauses,
unsupported `seq-policy`, missing byte-lane size policy, unsupported
`supported-transfer`, and unsupported child HBURST width remain in force.

## Generated Artifacts

The selected one-subordinate source must emit generated IAL1 review artifacts:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
```

Generated IAL0 artifacts:

```text
amba_requester.fsm
ahb_lite_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The selected two-subordinate source must emit generated IAL1 review artifacts:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane_hburst_seq.isf
ahb_control_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
```

Generated IAL0 artifacts:

```text
amba_requester.fsm
ahb_status_subordinate_byte_lane_hburst_seq.fsm
ahb_control_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The HDL entry for both selected sources is:

```text
ahb_tb
```

Direct IAL2-to-IAL0 and direct IAL2-to-HDL lowering remain forbidden.

## Support Accounting

The selected one-subordinate source must support-account as:

```text
entry_id: intent.ppif_ahb_interconnect_byte_lane_hburst_seq
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_pipeline_cli
classification: supported_smoke
strict_supported: true
module_name: ahb_tb
composition_child_count: 3
```

The selected two-subordinate source must support-account as:

```text
entry_id: intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli
classification: supported_smoke
strict_supported: true
module_name: ahb_tb
composition_child_count: 4
```

## Report Contract

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The selected implementation must preserve `composition.byte_lane_propagation`
and reuse `composition.seq_policy_propagation` for the aggregate HBURST-aware
`SEQ` propagation report. A separate aggregate-HBURST report block is not
selected.

The selected `composition.seq_policy_propagation` shape is:

```text
selected: true
mode: subordinate_owned_hburst_in_word_seq_policy
policy: hburst_in_word_progressive
base_policy: in_word_progressive
length_source: HBURST
forwarded_signals: HADDR, HTRANS, HBURST, HWRITE, HSIZE, HWDATA, HRDATA, HREADY, HREADYOUT, HRESP
request_forwarding.burst.global_name: HBURST
request_forwarding.burst.child_names: [HBURST_REGS] or [HBURST_STATUS, HBURST_CONTROL]
local_address_policy: subtract_window_base_before_subordinate_hburst_seq_policy
unmapped_error_owner: interconnect
mapped_error_owner: selected_subordinate
history_owner: selected_subordinate
subordinates: one entry per selected HBURST-aware byte-lane SEQ subordinate child
```

Each subordinate propagation entry must identify:

- child instance name;
- subordinate object name;
- address window;
- local address signal;
- child-local burst signal;
- transfer name `ahb_lite_byte_lane_hburst_seq_access`;
- supported byte-lane sizes `byte`, `halfword`, and `word`;
- supported HBURST `SEQ` size `byte`;
- supported HBURST modes `WRAP4` and `INCR4`;
- fail-closed HBURST modes `INCR`, `WRAP8`, `INCR8`, `WRAP16`, and `INCR16`;
- selected mode `hburst_in_word_progressive`; and
- selected child `transfer.seq_policy` copied from the generated subordinate
  report.

Aggregate child reports must carry `bindings.bus.burst`,
`narrow_transfer_policy`, and `transfer.seq_policy` whenever an embedded
subordinate report provides those blocks. Existing word-only aggregate,
non-`SEQ` byte-lane aggregate, and in-word-only aggregate `SEQ` child reports
remain unchanged.

## Residue Movement

For the two new generic aggregate HBURST `SEQ` `.ppif` reports only:

- keep `ahb_aggregate_profile_alias_deferred`;
- keep topology residue for broader interconnect/decode beyond the selected
  one-subordinate and two-subordinate static-window shapes;
- remove aggregate HBURST propagation wording from top-level
  `ahb_burst_seq_support_deferred`;
- report that byte-only HBURST `WRAP4`/`INCR4` in-word `SEQ` propagation is
  shipped for the selected aggregate sources;
- keep indefinite `INCR`, `WRAP8`/`INCR8`/`WRAP16`/`INCR16`,
  halfword/word burst `SEQ`, BUSY-in-burst parking,
  multi-word/register-bank progression, broader manager/subordinate behavior,
  direct backend, verification-output, backend-language variants, AXI/APB,
  broader AHB, and VHDL as explicit residue;
- copy child `bindings.bus.burst` and `transfer.seq_policy` into generated
  child reports; and
- remove aggregate-propagation wording from generated child
  `ahb_burst_seq_support_deferred` detail while preserving true endpoint and
  generic-source residue, including `.ahb` alias exposure until the aggregate
  alias owner ships.

Existing word-only aggregate `.ppif/.ahb`, byte-lane aggregate `.ppif/.ahb`,
aggregate in-word `SEQ` `.ppif/.ahb`, endpoint HBURST `SEQ` `.ppif/.ahb`,
requester, interconnect, support accounting, capability manifest, generated
artifacts, and HDL behavior must remain unchanged except for additive
catalog/language-surface/docs entries for the new generic aggregate HBURST
`SEQ` sources.

## Alias Sequencing

Matching aggregate HBURST `.ahb` aliases remain separate follow-on work after
`.770`. The reserved likely future alias paths are:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
```

The `.770` implementation must not add those aliases, their support
identities, or alias-only residue cleanup.

## Validation

The selected implementation should add focused coverage, expected as:

```text
t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t
```

That coverage must prove:

- both new generic `.ppif` sources parse and support-account;
- generated IAL1 and IAL0 artifacts match the selected names;
- HDL entry remains `ahb_tb`;
- generated top wiring includes requester/global `HBURST` fanout to
  `HBURST_REGS`, `HBURST_STATUS`, and `HBURST_CONTROL` as applicable;
- embedded generated child artifacts keep `HBURST`, `seq_hburst_q`, and
  `seq_beats_remaining_q`;
- schedule JSON carries `composition.byte_lane_propagation` and
  `composition.seq_policy_propagation`;
- `composition.seq_policy_propagation` records the selected HBURST-aware mode,
  `length_source: HBURST`, request-forwarding `burst`, child-local burst
  signals, supported HBURST modes, and child `seq_policy`;
- generated child reports carry `bindings.bus.burst`, `narrow_transfer_policy`,
  and `transfer.seq_policy`;
- top-level and child residue movement matches this contract;
- check JSON and semantic JSON preserve public source identity;
- `--outdir` writes the expected generated review artifacts;
- existing word-only aggregate, non-`SEQ` byte-lane aggregate, in-word-only
  aggregate `SEQ`, endpoint HBURST `SEQ`, and endpoint/aggregate `.ahb` alias
  behavior remain preserved; and
- malformed aggregate HBURST `SEQ` source shapes fail closed.

Closeout must also update RegressionCorpus, LanguageSurfaceSection/capability
manifest expectations, README, ROADMAP_V2, mdBook, behavior docs, Knowledge
Map, task tree, and Memory, then run focused syntax/probe/tests plus doctrine
closeout.

## Explicit Non-Selections

`.769` and `.770` must not add matching aggregate `.ahb` aliases,
BUSY-in-burst parking, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional/property-gated AHB signals,
legacy two-bit subordinate `HRESP`, broader interconnect/decode, scoreboards,
full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, broader AHB behavior,
or VHDL behavior.

## Rollback

Rollback for `.769` is documentation-only: remove this selector, its Knowledge
Map fact card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory
pointer update, and regenerated Knowledge Map entries. `.770` will define its
own implementation rollback if it proceeds.
