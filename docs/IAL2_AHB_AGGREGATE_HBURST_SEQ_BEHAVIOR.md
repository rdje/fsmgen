# IAL2 AHB Aggregate HBURST SEQ Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.770`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.770` ships the selected bounded generic
`.ppif` AHB aggregate HBURST-aware byte-lane `SEQ` propagation sources:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
```

They support-account as:

```text
entry_id: intent.ppif_ahb_interconnect_byte_lane_hburst_seq
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

Matching aggregate `.ahb` aliases are not shipped by `.770`. They are routed
to `IAL2-FEATURE-COMPLETENESS-FRONTIER.771`, a no-behavior public contract
selection owner.

## Public Source Contract

Both sources keep explicit `(profile ahb)` and reuse the shipped aggregate AHB
requester, interconnect, wiring, decode, and static address-map vocabulary.

The one-subordinate source embeds:

```text
(ahb-subordinate ahb_lite_subordinate_byte_lane_hburst_seq ...)
(subordinate regs ahb_lite_subordinate_byte_lane_hburst_seq)
REG_BASE=0
REG_SIZE=4
child-local burst: HBURST_REGS
```

The two-subordinate source embeds:

```text
(ahb-subordinate ahb_status_subordinate_byte_lane_hburst_seq ...)
(ahb-subordinate ahb_control_subordinate_byte_lane_hburst_seq ...)
(subordinate status ahb_status_subordinate_byte_lane_hburst_seq)
(subordinate control ahb_control_subordinate_byte_lane_hburst_seq)
STATUS_BASE=0
STATUS_SIZE=4
CONTROL_BASE=4
CONTROL_SIZE=4
child-local bursts: HBURST_STATUS, HBURST_CONTROL
```

Every embedded subordinate uses transfer
`ahb_lite_byte_lane_hburst_seq_access` with byte, halfword, and word
`supported-size` clauses, little-endian lane order, inactive-lane-preserving
narrow writes, inactive-lane-zero-filled narrow reads, ERROR policy for
unaligned and crossing accesses, a child-local `(burst ... width 3)` binding,
and:

```text
(seq-policy hburst-in-word-progressive)
```

The source still declares `(supported-transfer nonseq)` for compatibility.
The structured `transfer.seq_policy` report remains the selected bounded
subordinate-owned admission of byte-only `WRAP4` and `INCR4` HBURST `SEQ`
inside one local 32-bit register word after prior OKAY HBURST `NONSEQ` or
valid `SEQ` history, expected local address progression, stable `HBURST`,
stable `HWRITE`, and stable `HSIZE`.

## Generated Review Artifacts

The one-subordinate source lowers through:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_lite_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The two-subordinate source lowers through:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane_hburst_seq.isf
ahb_control_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_status_subordinate_byte_lane_hburst_seq.fsm
ahb_control_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

Both select HDL entry module `ahb_tb`.

## Aggregate Behavior

The aggregate interconnect behavior remains the selected static-window AHB
topology:

- fixed `HGRANT=1`;
- active-transfer decode by `HTRANS != IDLE`;
- static 32-bit, 4-byte-aligned address windows;
- selected subordinate local address equals `HADDR - window_base`;
- unselected subordinate selects are low and local addresses are zero;
- selected subordinate `HREADYOUT_*`, `HRDATA_*`, and one-bit `HRESP_*` mux
  back to the requester; and
- unmapped active transfers return the interconnect-owned two-cycle ERROR.

Mapped hits forward `HADDR`, `HTRANS`, `HBURST`, `HWRITE`, `HSIZE`, `HWDATA`,
and `HREADY` to the selected HBURST-aware byte-lane `SEQ` subordinate. The
selected subordinate owns byte/halfword/word narrow-transfer behavior,
byte-only `WRAP4`/`INCR4` HBURST `SEQ` history/progression, mapped-hit ERROR
responses, wait cycles, reads, and writes. The interconnect maps subordinate
one-bit `HRESP=0/1` to requester two-bit `HRESP=2'b00/2'b01`.

Child HBURST fanout is direct requester/global fanout:

```text
requester.HBURST -> regs.HBURST_REGS
requester.HBURST -> status.HBURST_STATUS
requester.HBURST -> control.HBURST_CONTROL
```

The fanout does not add interconnect HBURST state. Unselected children may see
the same global HBURST value; their select remains low and their local address
remains zero.

## Reports And Residue

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The two new generic sources preserve:

```text
composition.byte_lane_propagation
```

and reuse:

```text
composition.seq_policy_propagation
```

The `seq_policy_propagation` block records:

- `mode: subordinate_owned_hburst_in_word_seq_policy`;
- `policy: hburst_in_word_progressive`;
- `base_policy: in_word_progressive`;
- `length_source: HBURST`;
- `local_address_policy:
  subtract_window_base_before_subordinate_hburst_seq_policy`;
- request-forwarding `burst` with global `HBURST`, width `3`, and child names;
- selected-subordinate mapped-hit ownership;
- interconnect-owned unmapped ERROR ownership; and
- one subordinate entry per embedded HBURST-aware byte-lane `SEQ` endpoint,
  including `burst_signal`, `supported_hburst_modes`,
  `fail_closed_hburst_modes`, `supported_seq_size`, and child `seq_policy`.

Child reports for embedded HBURST-aware byte-lane `SEQ` subordinates carry
`bindings.bus.burst`, `narrow_transfer_policy`, and `transfer.seq_policy`.

For these aggregate HBURST sources, top-level residue now states that
selected byte-only `WRAP4`/`INCR4` aggregate HBURST propagation is shipped.
True remaining residue includes matching aggregate `.ahb` aliases,
BUSY-in-burst handling, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional/property-gated AHB signals,
broader AHB behavior, direct backend behavior, verification-output generation,
backend-language variants, AXI/APB behavior, and VHDL.

Existing word-only aggregate, non-SEQ byte-lane aggregate, in-word `SEQ`
aggregate, endpoint HBURST `SEQ`, requester, interconnect, and shipped `.ahb`
alias behavior remain preserved except for additive support for the two
selected generic `.ppif` aggregate HBURST sources.

## Validation

Focused validation:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t
prove -Iperl t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t
prove -Iperl t/1488-ial2-ahb-interconnect-byte-lane-seq.t t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
```
