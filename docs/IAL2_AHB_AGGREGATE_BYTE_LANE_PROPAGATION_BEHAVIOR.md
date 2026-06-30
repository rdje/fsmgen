# IAL2 AHB Aggregate Byte-Lane Propagation Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.743`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.743` ships the selected bounded generic
`.ppif` AHB aggregate byte-lane/narrow-transfer propagation sources:

```text
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

They support-account as:

```text
entry_id: intent.ppif_ahb_interconnect_byte_lane
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_byte_lane_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ppif_ahb_interconnect_two_subordinate_byte_lane
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

Matching `.ahb` aliases are not shipped in this slice. The following paths
remain future work:

```text
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

## Public Source Contract

Both sources keep explicit `(profile ahb)` and reuse the shipped aggregate AHB
requester, interconnect, wiring, decode, and address-map vocabulary.

The one-subordinate source embeds:

```text
(ahb-subordinate ahb_lite_subordinate_byte_lane ...)
(subordinate regs ahb_lite_subordinate_byte_lane)
REG_BASE=0
REG_SIZE=4
```

The two-subordinate source embeds:

```text
(ahb-subordinate ahb_status_subordinate_byte_lane ...)
(ahb-subordinate ahb_control_subordinate_byte_lane ...)
(subordinate status ahb_status_subordinate_byte_lane)
(subordinate control ahb_control_subordinate_byte_lane)
STATUS_BASE=0
STATUS_SIZE=4
CONTROL_BASE=4
CONTROL_SIZE=4
```

Every embedded subordinate uses the selected transfer:

```text
ahb_lite_byte_lane_access
```

with byte, halfword, and word `supported-size` clauses, little-endian lane
order, inactive-lane-preserving narrow writes, inactive-lane-zero-filled
narrow reads, and ERROR policy for unaligned and crossing accesses.

## Generated Review Artifacts

The one-subordinate source lowers through:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_lite_subordinate_byte_lane.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The two-subordinate source lowers through:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane.isf
ahb_control_subordinate_byte_lane.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_status_subordinate_byte_lane.fsm
ahb_control_subordinate_byte_lane.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

Both select HDL entry module `ahb_tb`.

## Aggregate Behavior

The aggregate interconnect behavior is unchanged from the selected word-only
aggregate topology:

- fixed `HGRANT=1`;
- active-transfer decode by `HTRANS != IDLE`;
- static 32-bit, 4-byte-aligned address windows;
- selected subordinate local address equals `HADDR - window_base`;
- unselected subordinate selects are low and local addresses are zero;
- selected subordinate `HREADYOUT_*`, `HRDATA_*`, and one-bit `HRESP_*` mux
  back to the requester; and
- unmapped active transfers return the interconnect-owned two-cycle ERROR.

Mapped hits forward `HTRANS`, `HWRITE`, `HSIZE`, `HWDATA`, and `HREADY` to the
selected byte-lane subordinate. The selected subordinate owns byte/halfword/word
acceptance, little-endian active-lane selection, inactive-lane-preserving
writes, inactive-lane-zero-filled reads, and mapped-hit ERROR behavior for
unsupported size, unsupported transfer, unmapped local address, unaligned
access, and crossing access.

## Reports And Residue

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_interconnect.v1
```

The two new generic sources add:

```text
composition.byte_lane_propagation
```

The report block records:

- `mode: subordinate_owned_narrow_transfer_policy`;
- `local_address_policy: subtract_window_base_before_subordinate_lane_policy`;
- `mapped_hit_owner: selected_subordinate`;
- `unmapped_error_owner: interconnect`;
- forwarded request/response signal groups; and
- one subordinate entry per embedded byte-lane endpoint, including
  `supported_size` and the child `narrow_transfer_policy`.

Child reports for embedded byte-lane subordinates now propagate
`narrow_transfer_policy`.

The aggregate byte-lane `.ppif` reports remove byte-lane wording from the
aggregate optional/interconnect residue. Existing word-only aggregate `.ppif`
and `.ahb` reports do not gain `composition.byte_lane_propagation` and still
keep their byte-lane residue. Existing endpoint byte-lane `.ppif` and `.ahb`
behavior remains unchanged.

## Validation

Focused validation:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1484-ial2-ahb-interconnect-byte-lane.t
prove -Iperl t/1484-ial2-ahb-interconnect-byte-lane.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```
