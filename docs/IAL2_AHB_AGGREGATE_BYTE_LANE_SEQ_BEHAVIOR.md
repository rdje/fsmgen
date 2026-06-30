# IAL2 AHB Aggregate Byte-Lane In-Word SEQ Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.758`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.758` ships the selected bounded generic
`.ppif` AHB aggregate byte-lane in-word `SEQ` propagation sources:

```text
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
```

They support-account as:

```text
entry_id: intent.ppif_ahb_interconnect_byte_lane_seq
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_byte_lane_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ppif_ahb_interconnect_two_subordinate_byte_lane_seq
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

Matching aggregate `.ahb` aliases are not shipped by this slice. The reserved
follow-on paths remain:

```text
ppif/ahb_interconnect_byte_lane_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
```

## Public Source Contract

Both sources keep explicit `(profile ahb)` and reuse the shipped aggregate AHB
requester, interconnect, wiring, decode, and static address-map vocabulary.

The one-subordinate source embeds:

```text
(ahb-subordinate ahb_lite_subordinate_byte_lane_seq ...)
(subordinate regs ahb_lite_subordinate_byte_lane_seq)
REG_BASE=0
REG_SIZE=4
```

The two-subordinate source embeds:

```text
(ahb-subordinate ahb_status_subordinate_byte_lane_seq ...)
(ahb-subordinate ahb_control_subordinate_byte_lane_seq ...)
(subordinate status ahb_status_subordinate_byte_lane_seq)
(subordinate control ahb_control_subordinate_byte_lane_seq)
STATUS_BASE=0
STATUS_SIZE=4
CONTROL_BASE=4
CONTROL_SIZE=4
```

Every embedded subordinate uses transfer `ahb_lite_byte_lane_seq_access` with
byte, halfword, and word `supported-size` clauses, little-endian lane order,
inactive-lane-preserving narrow writes, inactive-lane-zero-filled narrow reads,
ERROR policy for unaligned and crossing accesses, and:

```text
(seq-policy in-word-progressive)
```

The source still declares `(supported-transfer nonseq)`. The structured
`transfer.seq_policy` report is the selected bounded admission of byte and
halfword in-word `SEQ` after prior OKAY `NONSEQ` or valid `SEQ` history with
expected local address progression and stable `HWRITE`/`HSIZE`.

## Generated Review Artifacts

The one-subordinate source lowers through:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_lite_subordinate_byte_lane_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The two-subordinate source lowers through:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane_seq.isf
ahb_control_subordinate_byte_lane_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_status_subordinate_byte_lane_seq.fsm
ahb_control_subordinate_byte_lane_seq.fsm
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

Mapped hits forward `HADDR`, `HTRANS`, `HWRITE`, `HSIZE`, `HWDATA`, and
`HREADY` to the selected byte-lane `SEQ` subordinate. The selected subordinate
owns byte/halfword/word narrow-transfer behavior, byte/halfword in-word `SEQ`
history/progression, mapped-hit ERROR responses, wait cycles, reads, and
writes. The interconnect maps subordinate one-bit `HRESP=0/1` to requester
two-bit `HRESP=2'b00/2'b01`.

## Reports And Residue

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The two new generic sources preserve:

```text
composition.byte_lane_propagation
```

and add:

```text
composition.seq_policy_propagation
```

The `seq_policy_propagation` block records:

- `mode: subordinate_owned_in_word_seq_policy`;
- `local_address_policy: subtract_window_base_before_subordinate_seq_policy`;
- `mapped_hit_owner: selected_subordinate`;
- `unmapped_error_owner: interconnect`;
- forwarded request/response signal groups; and
- one subordinate entry per embedded byte-lane `SEQ` endpoint, including
  `supported_size`, `supported_seq_size`, and the child `seq_policy`.

Child reports for embedded byte-lane `SEQ` subordinates carry both
`narrow_transfer_policy` and `transfer.seq_policy`.

The aggregate `SEQ` reports remove stale aggregate-propagation wording from
the top-level and subordinate-child `ahb_burst_seq_support_deferred` details.
They preserve true remaining residue for matching aggregate `.ahb` aliases,
HBURST-driven length/wrap semantics, BUSY-in-burst handling,
multi-word/register-bank progression, optional/property-gated AHB signals,
broader AHB behavior, direct backend behavior, verification-output generation,
backend-language variants, AXI/APB behavior, and VHDL.

Existing word-only aggregate `.ppif/.ahb`, non-SEQ byte-lane aggregate
`.ppif/.ahb`, endpoint byte-lane `SEQ` `.ppif/.ahb`, requester, interconnect,
support-accounting, capability-manifest, schedule/check/semantic JSON,
generated artifacts, and HDL behavior remain preserved except for the focused
test expectation update that now acknowledges the already-shipped aggregate
byte-lane `.ahb` aliases.

## Validation

Focused validation:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1488-ial2-ahb-interconnect-byte-lane-seq.t
prove -Iperl t/1488-ial2-ahb-interconnect-byte-lane-seq.t
prove -Iperl t/1484-ial2-ahb-interconnect-byte-lane.t
prove -Iperl t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
prove -Iperl t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_doctrines.sh
```
