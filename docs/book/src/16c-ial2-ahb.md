# AHB IAL2 Current Boundary

FSMGen ships fifty-two public bounded AHB IAL2 entrypoints today:

```text
ppif/ahb_requester.ppif
ppif/ahb_requester_busy_insert.ppif
ppif/ahb_requester_busy_insert_two.ppif
ppif/ahb_requester_busy_insert_three.ppif
ppif/ahb_requester_busy_insert_four.ppif
ppif/ahb_lite_subordinate.ppif
ppif/ahb_lite_subordinate_byte_lane.ppif
ppif/ahb_lite_subordinate_byte_lane_seq.ppif
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_requester.ahb
ppif/ahb_requester_busy_insert.ahb
ppif/ahb_requester_busy_insert_two.ahb
ppif/ahb_requester_busy_insert_three.ahb
ppif/ahb_requester_busy_insert_four.ahb
ppif/ahb_lite_subordinate.ahb
ppif/ahb_lite_subordinate_byte_lane.ahb
ppif/ahb_lite_subordinate_byte_lane_seq.ahb
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect.ahb
ppif/ahb_interconnect_two_subordinate.ahb
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
ppif/ahb_interconnect_byte_lane_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb
```

The `.ppif` sources are generic Protocol/Platform Intent files. They cover the
bounded AHB requester and exact-one through exact-four generic plus alias
requester BUSY-insertion variants, the bounded word-only
AHB-Lite/common-AHB subordinate,
the bounded AHB-Lite/common-AHB byte-lane/narrow-transfer subordinate, the
bounded AHB-Lite/common-AHB byte-lane in-word `SEQ` subordinate, and the
bounded generic byte-lane HBURST `WRAP4`/`INCR4` `SEQ` subordinate. They also
cover the selected one-requester/one-subordinate and one-requester/two-subordinate
static-window interconnect/decode tops, including the selected generic aggregate
byte-lane propagation variants and the selected generic aggregate byte-lane
in-word `SEQ` propagation variants, the selected generic aggregate
HBURST-aware byte-lane `SEQ` propagation variants, and the selected generic
aggregate HBURST-aware byte-lane `SEQ` propagation variants with BUSY-in-burst
parking (each embedded subordinate holds the in-word `SEQ` burst context across
an `HTRANS=BUSY` beat instead of clearing it), plus paired aggregates whose
requester inserts that BUSY and whose one or two subordinates park it. The
generic one- and two-subordinate families include both exact-one and exact-two
requester insertion with matching `.ahb` aliases, and the one-subordinate
family now also includes exact-three requester insertion and its matching
`.ahb` alias. The two-subordinate family likewise includes the exact-three
generic/profile pair.
The `.ahb` sources are bounded profile aliases over the same IAL2 model. They
use the same `protocol-platform-intent` form, keep explicit `(profile ahb)`,
and support exactly one selected object shape:
`(ahb-requester amba_requester ...)` or
`(ahb-subordinate ahb_lite_subordinate ...)`, or
`(ahb-subordinate ahb_lite_subordinate_byte_lane ...)`, or the selected
byte-lane in-word `SEQ` subordinate
`(ahb-subordinate ahb_lite_subordinate_byte_lane_seq ...)`, or the selected
aggregate one-requester/one-subordinate interconnect shape,
`(ahb-interconnect ahb_tb ...)`, including selected aggregate byte-lane and
aggregate byte-lane in-word `SEQ` propagation variants, or the selected
aggregate one-requester/two-subordinate interconnect shape, including the
selected two-subordinate aggregate byte-lane and aggregate byte-lane in-word
`SEQ` propagation variants, or the selected paired BUSY-inserting-requester/
BUSY-parking-subordinate aggregates with one or two subordinate windows,
`(ahb-interconnect ahb_tb ...)`.

All public AHB IAL2 sources lower through generated review artifacts before
HDL:

```text
ppif/ahb_requester.ppif          -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
ppif/ahb_requester_busy_insert.ppif -> amba_requester_busy_insert.isf -> amba_requester_busy_insert.fsm -> HDL module amba_requester_busy_insert
ppif/ahb_requester_busy_insert_two.ppif -> amba_requester_busy_insert_two.isf -> amba_requester_busy_insert_two.fsm -> HDL module amba_requester_busy_insert_two
ppif/ahb_requester_busy_insert_three.ppif -> amba_requester_busy_insert_three.isf -> amba_requester_busy_insert_three.fsm -> HDL module amba_requester_busy_insert_three
ppif/ahb_requester_busy_insert_four.ppif -> amba_requester_busy_insert_four.isf -> amba_requester_busy_insert_four.fsm -> HDL module amba_requester_busy_insert_four
ppif/ahb_requester_busy_insert_four.ahb -> amba_requester_busy_insert_four.isf -> amba_requester_busy_insert_four.fsm -> HDL module amba_requester_busy_insert_four
ppif/ahb_requester.ahb           -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
ppif/ahb_requester_busy_insert.ahb -> amba_requester_busy_insert.isf -> amba_requester_busy_insert.fsm -> HDL module amba_requester_busy_insert
ppif/ahb_requester_busy_insert_two.ahb -> amba_requester_busy_insert_two.isf -> amba_requester_busy_insert_two.fsm -> HDL module amba_requester_busy_insert_two
ppif/ahb_requester_busy_insert_three.ahb -> amba_requester_busy_insert_three.isf -> amba_requester_busy_insert_three.fsm -> HDL module amba_requester_busy_insert_three
ppif/ahb_lite_subordinate.ppif   -> ahb_lite_subordinate.isf -> ahb_lite_subordinate.fsm -> HDL module ahb_lite_subordinate
ppif/ahb_lite_subordinate_byte_lane.ppif -> ahb_lite_subordinate_byte_lane.isf -> ahb_lite_subordinate_byte_lane.fsm -> HDL module ahb_lite_subordinate_byte_lane
ppif/ahb_lite_subordinate_byte_lane_seq.ppif -> ahb_lite_subordinate_byte_lane_seq.isf -> ahb_lite_subordinate_byte_lane_seq.fsm -> HDL module ahb_lite_subordinate_byte_lane_seq
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif -> ahb_lite_subordinate_byte_lane_hburst_seq.isf -> ahb_lite_subordinate_byte_lane_hburst_seq.fsm -> HDL module ahb_lite_subordinate_byte_lane_hburst_seq
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif -> ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf -> ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm -> HDL module ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
ppif/ahb_lite_subordinate.ahb    -> ahb_lite_subordinate.isf -> ahb_lite_subordinate.fsm -> HDL module ahb_lite_subordinate
ppif/ahb_lite_subordinate_byte_lane.ahb -> ahb_lite_subordinate_byte_lane.isf -> ahb_lite_subordinate_byte_lane.fsm -> HDL module ahb_lite_subordinate_byte_lane
ppif/ahb_lite_subordinate_byte_lane_seq.ahb -> ahb_lite_subordinate_byte_lane_seq.isf -> ahb_lite_subordinate_byte_lane_seq.fsm -> HDL module ahb_lite_subordinate_byte_lane_seq
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb -> ahb_lite_subordinate_byte_lane_hburst_seq.isf -> ahb_lite_subordinate_byte_lane_hburst_seq.fsm -> HDL module ahb_lite_subordinate_byte_lane_hburst_seq
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb -> ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf -> ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm -> HDL module ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
ppif/ahb_interconnect.ppif       -> amba_requester.isf + ahb_lite_subordinate.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate.ppif -> amba_requester.isf + ahb_status_subordinate.isf + ahb_control_subordinate.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate.fsm + ahb_control_subordinate.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_byte_lane.ppif -> amba_requester.isf + ahb_lite_subordinate_byte_lane.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate_byte_lane.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif -> amba_requester.isf + ahb_status_subordinate_byte_lane.isf + ahb_control_subordinate_byte_lane.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate_byte_lane.fsm + ahb_control_subordinate_byte_lane.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_byte_lane_seq.ppif -> amba_requester.isf + ahb_lite_subordinate_byte_lane_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate_byte_lane_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif -> amba_requester.isf + ahb_status_subordinate_byte_lane_seq.isf + ahb_control_subordinate_byte_lane_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate_byte_lane_seq.fsm + ahb_control_subordinate_byte_lane_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_byte_lane_hburst_seq.ppif -> amba_requester.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif -> amba_requester.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif -> amba_requester.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif -> amba_requester.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif -> amba_requester_busy_insert.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif -> amba_requester_busy_insert_two.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert_two.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif -> amba_requester_busy_insert_three.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert_three.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ppif -> amba_requester_busy_insert.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif -> amba_requester_busy_insert_two.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert_two.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif -> amba_requester_busy_insert_three.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert_three.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect.ahb        -> amba_requester.isf + ahb_lite_subordinate.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate.ahb -> amba_requester.isf + ahb_status_subordinate.isf + ahb_control_subordinate.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate.fsm + ahb_control_subordinate.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_byte_lane.ahb -> amba_requester.isf + ahb_lite_subordinate_byte_lane.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate_byte_lane.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb -> amba_requester.isf + ahb_status_subordinate_byte_lane.isf + ahb_control_subordinate_byte_lane.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate_byte_lane.fsm + ahb_control_subordinate_byte_lane.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_byte_lane_seq.ahb -> amba_requester.isf + ahb_lite_subordinate_byte_lane_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate_byte_lane_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb -> amba_requester.isf + ahb_status_subordinate_byte_lane_seq.isf + ahb_control_subordinate_byte_lane_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate_byte_lane_seq.fsm + ahb_control_subordinate_byte_lane_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb -> amba_requester.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb -> amba_requester.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb -> amba_requester.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb -> amba_requester.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb -> amba_requester_busy_insert.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb -> amba_requester_busy_insert_two.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert_two.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb -> amba_requester_busy_insert_three.isf + ahb_lite_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert_three.fsm + ahb_lite_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_requester_busy_insert_two_subordinate_byte_lane_hburst_seq_busy_park.ahb -> amba_requester_busy_insert.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ahb -> amba_requester_busy_insert_two.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert_two.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ahb -> amba_requester_busy_insert_three.isf + ahb_status_subordinate_byte_lane_hburst_seq.isf + ahb_control_subordinate_byte_lane_hburst_seq.isf + ahb_interconnect.isf -> amba_requester_busy_insert_three.fsm + ahb_status_subordinate_byte_lane_hburst_seq.fsm + ahb_control_subordinate_byte_lane_hburst_seq.fsm + ahb_interconnect.fsm + ahb_tb.fsm -> HDL module ahb_tb
```

FSMGen also keeps direct lower-layer `.fsm` seeds:

```text
fsm/amba_requester.fsm
fsm/ahb_lite_subordinate.fsm
```

These direct seeds remain useful cycle-level coverage, but they are not IAL2
and do not produce generated `.isf` or generated `.fsm` review artifacts. The
direct subordinate currently does not share the generated family's repaired
phase bank because it uses a smaller direct-state repair. `.8` now retains
completion-edge active phases through Q-named `<-` loads in its existing four
states, without a pending bank/relaunch. See the direct-seed section below.

## Mode Map

| Mode | Current source | Boundary |
| --- | --- | --- |
| Guided mode | The fifty-two public AHB sources listed above, including generic plus matching `.ahb` exact-one through exact-four requesters and paired exact-one/exact-two/exact-three one- and two-subordinate `.ppif`/`.ahb` source pairs | Bounded requester/subordinate/interconnect sources, exact-one through exact-four requester BUSY insertion across generic and alias surfaces, selected byte-lane and HBURST `SEQ` endpoint/aggregate families, selected BUSY-parking families and aliases, and paired exact-one/exact-two/exact-three BUSY-inserting-requester/BUSY-parking-subordinate aggregates across one or two windows. |
| More-control mode | The same bounded IAL2 sources plus direct `fsm/amba_requester.fsm` and `fsm/ahb_lite_subordinate.fsm` for cycle-level comparison | Requester knobs are exposed as `local-command`, `local-status`, `bus`, `burst`, `transfer`, and `response` clauses. Subordinate knobs cover selected byte/halfword/word lanes, in-word `SEQ`, HBURST `WRAP4`/`INCR4`, and BUSY parking. The selected generic and matching `.ahb` aggregate HBURST-aware byte-lane `SEQ` sources include non-parking and BUSY-park variants, plus paired BUSY-inserting-requester compositions across one or two static windows. Interconnect knobs are exposed as `children`, static `address-map` windows, `decode`, and `wiring` clauses. |
| Raw/full-control mode | Direct `.fsm` seeds and the generated `.isf`/`.fsm` review artifacts emitted from IAL2 | The generated family ships one accepted active address/control slot per subordinate, separated requester address/data ownership, and retained one-hot interconnect data ownership. The separate direct subordinate seed now retains completion-edge active NONSEQ/SEQ through Q-named `<-` loads in its existing four states, without pending/relaunch. AHB completer behavior, broader interconnect/decode beyond selected static-window aggregates, optional signals beyond the shipped HBURST endpoint binding, wider/indefinite HBURST continuation beyond bounded byte-only `WRAP4`/`INCR4`, BUSY counts beyond four, policy/runtime BUSY insertion, distinct bus-BUSY status, general/deeper queues, multiple outstanding transfers, full manager behavior, direct backend behavior, verification-output generation, backend-language variants, and VHDL remain future task-tree-owned work. |

## Guided PPIF Requester

Run the shipped generic IAL2 requester through the standard review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-requester ppif/ahb_requester.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_requester
source_kind: ppif
coverage: ial2_ppif_ahb_requester_pipeline_cli
module_name: amba_requester
```

## Guided PPIF Subordinate

Run the shipped generic IAL2 subordinate through the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-subordinate ppif/ahb_lite_subordinate.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_lite_subordinate
source_kind: ppif
coverage: ial2_ppif_ahb_lite_subordinate_pipeline_cli
module_name: ahb_lite_subordinate
```

The schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, reports target object
`ahb-subordinate`, exposes generated `ahb_lite_subordinate.isf` before
`ahb_lite_subordinate.fsm`, and records output reset/default policy:

```text
HREADYOUT: reset 1, default 1
HRESP:     reset 0, default 0
HRDATA:    reset 0, default 0
```

The generated `.isf` keeps those values as actor-level output metadata, and
the generated `.fsm` keeps them as `+size` reset metadata plus idle output
assignments.

## Guided PPIF Byte-Lane Subordinate

Run the shipped byte-lane/narrow-transfer subordinate through the same review
path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-byte-lane-subordinate ppif/ahb_lite_subordinate_byte_lane.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane
source_kind: ppif
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane
```

The source lowers through generated `ahb_lite_subordinate_byte_lane.isf`
before `ahb_lite_subordinate_byte_lane.fsm`, then emits HDL module
`ahb_lite_subordinate_byte_lane`.

The selected transfer policy is deliberately bounded:

- `HSIZE == 3'b000` is a byte transfer when `HADDR[31:2] == 0`; active byte
  lane is `HADDR[1:0]`;
- `HSIZE == 3'b001` is a halfword transfer when `HADDR[31:2] == 0` and
  `HADDR[0] == 0`; active halfword lane is `HADDR[1]`;
- `HSIZE == 3'b010` is a word transfer when `HADDR == 0`;
- byte lane 0 maps to bits `[7:0]`, lane 1 to `[15:8]`, lane 2 to `[23:16]`,
  and lane 3 to `[31:24]`;
- narrow writes preserve inactive storage lanes;
- narrow reads drive the active stored lanes in place and zero-fill inactive
  `HRDATA` lanes; and
- unsupported size, unsupported transfer, unmapped address, unaligned access,
  and crossing access use the existing two-cycle ERROR response.

The schedule/report JSON includes `narrow_transfer_policy`, with accepted
sizes, little-endian byte-lane masks, inactive-lane write/read policies, and
the selected ERROR policy. The matching byte-lane `.ahb` alias preserves that
report block. The existing word-only subordinate `.ppif` and `.ahb` alias do
not gain it.

## Guided PPIF Byte-Lane In-Word SEQ Subordinate

Run the shipped generic byte-lane `SEQ` subordinate through the same review
path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-byte-lane-seq-subordinate ppif/ahb_lite_subordinate_byte_lane_seq.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane_seq
source_kind: ppif
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_seq_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane_seq
```

The source lowers through generated `ahb_lite_subordinate_byte_lane_seq.isf`
before `ahb_lite_subordinate_byte_lane_seq.fsm`, then emits HDL module
`ahb_lite_subordinate_byte_lane_seq`. The matching
`ppif/ahb_lite_subordinate_byte_lane_seq.ahb` alias ships with the same
generated review artifacts and HDL module. Aggregate propagation is not
shipped for this `SEQ` policy.

The selected source keeps `supported-transfer nonseq` for compatibility and
adds:

```text
(seq-policy in-word-progressive)
```

The schedule/report JSON includes `transfer.seq_policy`:

```text
selected: true
mode: in_word_progressive
requires_prior_transfer: prior_okay_nonseq_or_seq
supported_sizes: [byte, halfword]
address_progression: previous_address_plus_size_bytes
control_stability: [HWRITE, HSIZE]
clears_on: [reset, idle, busy, error, new_nonseq]
```

`SEQ` completes OKAY only for byte or halfword in-word continuation after a
previous accepted active transfer completed OKAY. The current `SEQ` must keep
the same `HWRITE` and `HSIZE`, use the stored expected next address, remain
inside the selected 32-bit register word, and satisfy the normal byte-lane
alignment rule.

Selected OKAY examples:

```text
NONSEQ byte     at HADDR 0 -> SEQ byte     at HADDR 1
NONSEQ byte     at HADDR 1 -> SEQ byte     at HADDR 2
NONSEQ byte     at HADDR 2 -> SEQ byte     at HADDR 3
NONSEQ halfword at HADDR 0 -> SEQ halfword at HADDR 2
```

Standalone `SEQ`, `SEQ` after `IDLE`/`BUSY`/ERROR/reset, `SEQ` after word
access, changed `HWRITE` or `HSIZE`, unexpected address progression, and
crossing out of the selected word use the selected two-cycle ERROR response.
Accepted `IDLE` and `BUSY` transfers keep zero-wait OKAY defaults and clear the
continuation history. Successful `SEQ` reads and writes reuse the shipped
byte-lane policy: active lanes update/read in place, inactive write lanes are
preserved, and inactive read lanes are zero-filled.

## Guided PPIF Byte-Lane HBURST SEQ Subordinate

Run the shipped generic byte-lane HBURST `SEQ` subordinate through the same
review path:

```bash
./bin/fsmgen --quiet --outdir generated/ial2-ahb-byte-lane-hburst-seq-subordinate ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
```

This emits:

```text
generated/ial2-ahb-byte-lane-hburst-seq-subordinate/ahb_lite_subordinate_byte_lane_hburst_seq.isf
generated/ial2-ahb-byte-lane-hburst-seq-subordinate/ahb_lite_subordinate_byte_lane_hburst_seq.fsm
```

The generated HDL entry is:

```text
ahb_lite_subordinate_byte_lane_hburst_seq
```

The source adds `HBURST` as an explicit subordinate bus binding:

```text
(burst HBURST width 3)
```

and selects the HBURST-aware byte-lane policy:

```text
(seq-policy hburst-in-word-progressive)
```

Schedule/report JSON for this source uses schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, includes
`bindings.bus.burst.name = HBURST`, `bindings.bus.burst.width = 3`, preserves
the existing `narrow_transfer_policy`, and reports:

```text
transfer.seq_policy.mode = hburst_in_word_progressive
transfer.seq_policy.base_policy = in_word_progressive
transfer.seq_policy.length_source = HBURST
transfer.seq_policy.supported_sizes = [byte]
transfer.seq_policy.supported_hburst_modes = [WRAP4, INCR4]
transfer.seq_policy.fail_closed_hburst_modes = [INCR, WRAP8, INCR8, WRAP16, INCR16]
transfer.seq_policy.control_stability = [HBURST, HWRITE, HSIZE]
```

`HBURST=SINGLE` keeps independent `NONSEQ` byte, halfword, and word access and
never arms `SEQ` history. `HBURST=INCR4` and `HBURST=WRAP4` arm byte-only
four-beat history inside the selected 32-bit register word. `INCR4` must start
on byte lane 0; `WRAP4` may start on any byte lane and wraps inside the
four-byte window:

```text
INCR4 byte NONSEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3
WRAP4 byte NONSEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3
WRAP4 byte NONSEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3 -> SEQ HADDR 0
WRAP4 byte NONSEQ HADDR 2 -> SEQ HADDR 3 -> SEQ HADDR 0 -> SEQ HADDR 1
WRAP4 byte NONSEQ HADDR 3 -> SEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2
```

Each accepted byte beat uses the shipped byte-lane policy: active lanes update
or read in place, inactive write lanes are preserved, and inactive read lanes
are zero-filled. The fourth accepted beat clears HBURST history; an extra
`SEQ` without a new valid `NONSEQ` returns ERROR.

Fail-closed cases include standalone `SEQ`, `SEQ` after `SINGLE`,
`IDLE`/`BUSY`/reset/ERROR, changed `HBURST`/`HWRITE`/`HSIZE`, unexpected
address progression, non-lane0 `INCR4` starts, unsupported HBURST modes,
halfword/word burst `SEQ`, unsupported sizes, unmapped/unaligned/crossing
accesses, and multi-word/register-bank progression. This generic source now
has a matching endpoint `.ahb` alias. Aggregate HBURST propagation ships
through selected generic aggregate `.ppif` sources later in this chapter, and
matching aggregate HBURST `.ahb` aliases ship through their selected profile
surfaces.

## Guided PPIF Interconnect

Run the shipped generic one-requester/one-subordinate AHB interconnect through
the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect ppif/ahb_interconnect.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_interconnect
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_pipeline_cli
module_name: ahb_tb
composition_child_count: 3
```

The schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, reports target object
`ahb-interconnect`, exposes generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`, and records HDL entry `ahb_tb`.

The selected interconnect behavior is deliberately bounded:

- one requester child named `requester`;
- one subordinate child named `regs`;
- one static address window, `REG_BASE=0` and `REG_SIZE=4`;
- fixed single-requester `HGRANT=1`;
- active transfer decode when `HTRANS != IDLE` and `HADDR` is inside the static
  window;
- decoded `HSEL_REGS` and local `HADDR_REGS = HADDR - REG_BASE` on hits;
- global `HREADY` feedback to the requester and subordinate;
- hit response/data muxing from `HREADYOUT_REGS`, `HRDATA_REGS`, and one-bit
  `HRESP_REGS`;
- requester-side `HRESP=2'b00` for subordinate OKAY and `HRESP=2'b01` for
  subordinate ERROR; and
- interconnect-owned two-cycle unmapped active-transfer ERROR.

The generated aggregate top wires the requester, interconnect, and subordinate
through `ahb_tb.fsm`; the generated HDL entry is module `ahb_tb`.

> **Selector-assertion behavior:** generated interconnect IAL0 now uses
> complementary per-window mapped-hit/not-hit address/select modes and
> exclusive retained-owner, first-cycle-unmapped, or ordinary-default global
> response modes. The ordinary predicate is
> `!any_owner && !unmapped_address`; independent owner blocks still expose an
> impossible multiple-owner state to generic `onehot0` assertions. Direct
> one-/two-window t1530 passes mapped address zero/nonzero, local translation,
> wait, success, subordinate ERROR, same-edge replacement, and two-cycle
> unmapped ERROR with assertions enabled. See the
> [output-arbitration audit](../../IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_AUDIT.md),
> [selected contract](../../IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_CONTRACT_SELECTION.md),
> and
> [shipped behavior](../../IAL2_AHB_INTERCONNECT_DEFAULT_DECODE_OUTPUT_ARBITRATION_BEHAVIOR.md).
> Historical boundary: paired aggregate tests temporarily retained
> `--no-assert` because subordinate idle/`ahb_phase_capture` output overlap
> remained outside this fabric repair. The later generated-subordinate repair
> retired that boundary, and the separately hand-authored direct seed is now
> assertion-clean as well.

## Guided PPIF Two-Subordinate Interconnect

Run the shipped generic one-requester/two-subordinate AHB interconnect through
the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate ppif/ahb_interconnect_two_subordinate.ppif
```

The strict check reports:

```text
entry_id: intent.ppif_ahb_interconnect_two_subordinate
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

The schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, reports topology
`one_requester_two_subordinate_static_window_interconnect`, exposes generated
`amba_requester.isf`, `ahb_status_subordinate.isf`,
`ahb_control_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_status_subordinate.fsm`,
`ahb_control_subordinate.fsm`, `ahb_interconnect.fsm`, and aggregate
`ahb_tb.fsm`, and records HDL entry `ahb_tb`.

The selected two-subordinate behavior is deliberately bounded:

- one requester child named `requester`;
- two subordinate children named `status` and `control`;
- two static non-overlapping address windows, `STATUS_BASE=0`,
  `STATUS_SIZE=4`, `CONTROL_BASE=4`, and `CONTROL_SIZE=4`;
- fixed single-requester `HGRANT=1`;
- active transfer decode when `HTRANS != IDLE` and `HADDR` is inside exactly
  one static window;
- decoded `HSEL_STATUS` and zero-base local `HADDR_STATUS = HADDR` on status
  hits;
- decoded `HSEL_CONTROL` and local `HADDR_CONTROL = HADDR - CONTROL_BASE` on
  control hits;
- unselected subordinate selects low and local addresses zero;
- global `HREADY` feedback to the requester and both subordinates;
- hit response/data muxing from the selected subordinate's `HREADYOUT_*`,
  `HRDATA_*`, and one-bit `HRESP_*`; and
- interconnect-owned two-cycle unmapped active-transfer ERROR.

The two-subordinate interconnect wiring block contains only requester/global
AHB bus names. Per-subordinate select, local address, ready-out, response, and
read-data names come from each subordinate object's `(bus ...)` block. Scalar
`subordinate-select`, `subordinate-ready-out`, `subordinate-response`, and
`subordinate-read-data` wiring clauses remain required for the one-subordinate
source and are rejected for the two-subordinate source.

The generic two-subordinate `.ppif` report keeps
`ahb_aggregate_profile_alias_deferred` as a source-surface distinction, while
the matching `ppif/ahb_interconnect_two_subordinate.ahb` alias removes that
residue. Both reports replace the old multi-subordinate residue with
`ahb_broader_interconnect_decode_deferred` to make the remaining AHB
interconnect/decode backlog explicit.

## Guided PPIF Aggregate Byte-Lane Interconnect

Run the selected generic aggregate byte-lane/narrow-transfer interconnects
through the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-byte-lane ppif/ahb_interconnect_byte_lane.ppif

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-byte-lane ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

The strict checks report:

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

The one-subordinate byte-lane aggregate emits `amba_requester.isf`,
`ahb_lite_subordinate_byte_lane.isf`, and `ahb_interconnect.isf` before
generated `amba_requester.fsm`, `ahb_lite_subordinate_byte_lane.fsm`,
`ahb_interconnect.fsm`, and aggregate `ahb_tb.fsm`.

The two-subordinate byte-lane aggregate emits `amba_requester.isf`,
`ahb_status_subordinate_byte_lane.isf`,
`ahb_control_subordinate_byte_lane.isf`, and `ahb_interconnect.isf` before
generated `amba_requester.fsm`, `ahb_status_subordinate_byte_lane.fsm`,
`ahb_control_subordinate_byte_lane.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`.

Both sources keep the existing aggregate interconnect behavior: fixed
`HGRANT=1`, active-transfer decode by `HTRANS != IDLE`, static window
selection, local address generation by subtracting the selected window base,
selected-subordinate response/data muxing, one-bit subordinate `HRESP_*` to
two-bit requester `HRESP`, and interconnect-owned two-cycle ERROR for
unmapped active transfers.

The difference is the embedded subordinate endpoint. The selected aggregate
byte-lane sources instantiate subordinate objects using
`ahb_lite_byte_lane_access`, so mapped hits forward `HADDR`, `HTRANS`,
`HWRITE`, `HSIZE`, `HWDATA`, and `HREADY` to byte-lane-capable subordinate
children. Those children own byte/halfword/word acceptance, little-endian lane
selection, inactive-lane-preserving writes, inactive-lane-zero-filled reads,
and mapped-hit ERROR responses for unsupported size, unsupported transfer,
unmapped local address, unaligned access, and crossing access.

The schedule/report JSON adds `composition.byte_lane_propagation` for these
two generic sources only. The block records
`subordinate_owned_narrow_transfer_policy`, local-address-before-lane policy,
mapped-hit ownership by the selected subordinate, unmapped ownership by the
interconnect, and one subordinate entry per embedded byte-lane endpoint. Each
subordinate entry carries `supported_size` and the child
`narrow_transfer_policy`.

The existing word-only aggregate `.ppif` and `.ahb` sources do not gain
`composition.byte_lane_propagation`. The matching aggregate byte-lane `.ahb`
aliases are shipped as profile aliases over these two generic sources and are
documented in the profile-alias section below.

## Guided PPIF Aggregate Byte-Lane In-Word SEQ Interconnect

Run the selected generic aggregate byte-lane in-word `SEQ` interconnects
through the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-byte-lane-seq ppif/ahb_interconnect_byte_lane_seq.ppif

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-byte-lane-seq ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
```

The strict checks report:

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

The one-subordinate aggregate `SEQ` source emits `amba_requester.isf`,
`ahb_lite_subordinate_byte_lane_seq.isf`, and `ahb_interconnect.isf` before
generated `amba_requester.fsm`, `ahb_lite_subordinate_byte_lane_seq.fsm`,
`ahb_interconnect.fsm`, and aggregate `ahb_tb.fsm`.

The two-subordinate aggregate `SEQ` source emits `amba_requester.isf`,
`ahb_status_subordinate_byte_lane_seq.isf`,
`ahb_control_subordinate_byte_lane_seq.isf`, and `ahb_interconnect.isf`
before generated `amba_requester.fsm`,
`ahb_status_subordinate_byte_lane_seq.fsm`,
`ahb_control_subordinate_byte_lane_seq.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`.

Both sources keep the existing aggregate interconnect behavior and replace
only the embedded subordinate endpoint contract. Mapped hits forward the
selected aggregate bus signals to byte-lane `SEQ` subordinate children using
local addresses after subtracting the selected window base. Those subordinate
children own byte/halfword/word narrow-transfer behavior and the selected
byte/halfword in-word `SEQ` policy.

The schedule/report JSON preserves `composition.byte_lane_propagation` and
adds `composition.seq_policy_propagation`. The new block records
`subordinate_owned_in_word_seq_policy`,
`subtract_window_base_before_subordinate_seq_policy`, selected-subordinate
mapped-hit ownership, interconnect-owned unmapped ERROR ownership,
`supported_seq_size`, and the child `seq_policy`. Embedded subordinate child
reports carry both `narrow_transfer_policy` and `transfer.seq_policy`.

## Guided PPIF Aggregate HBURST Byte-Lane SEQ Interconnect

Run the selected generic aggregate HBURST-aware byte-lane `SEQ`
interconnects through the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-byte-lane-hburst-seq ppif/ahb_interconnect_byte_lane_hburst_seq.ppif

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-byte-lane-hburst-seq ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
```

The strict checks report:

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

The one-subordinate aggregate HBURST `SEQ` source emits
`amba_requester.isf`, `ahb_lite_subordinate_byte_lane_hburst_seq.isf`, and
`ahb_interconnect.isf` before generated `amba_requester.fsm`,
`ahb_lite_subordinate_byte_lane_hburst_seq.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`.

The two-subordinate aggregate HBURST `SEQ` source emits
`amba_requester.isf`,
`ahb_status_subordinate_byte_lane_hburst_seq.isf`,
`ahb_control_subordinate_byte_lane_hburst_seq.isf`, and
`ahb_interconnect.isf` before generated `amba_requester.fsm`,
`ahb_status_subordinate_byte_lane_hburst_seq.fsm`,
`ahb_control_subordinate_byte_lane_hburst_seq.fsm`,
`ahb_interconnect.fsm`, and aggregate `ahb_tb.fsm`.

Both sources keep the existing aggregate interconnect behavior and replace
only the embedded subordinate endpoint contract. Mapped hits forward the
selected aggregate bus signals to HBURST-aware byte-lane `SEQ` subordinate
children using local addresses after subtracting the selected window base.
Requester/global `HBURST` fans out directly to child-local burst inputs:

```text
requester.HBURST -> regs.HBURST_REGS
requester.HBURST -> status.HBURST_STATUS
requester.HBURST -> control.HBURST_CONTROL
```

Those subordinate children own byte/halfword/word narrow-transfer behavior and
the selected byte-only `WRAP4`/`INCR4` HBURST `SEQ` policy. The fanout does not
add interconnect HBURST state; unselected children keep select low and local
address zero.

The schedule/report JSON preserves `composition.byte_lane_propagation` and
reuses `composition.seq_policy_propagation`. For these HBURST aggregate
sources that block records `subordinate_owned_hburst_in_word_seq_policy`,
`hburst_in_word_progressive`, `length_source: HBURST`,
`subtract_window_base_before_subordinate_hburst_seq_policy`,
request-forwarding `burst`, selected-subordinate mapped-hit ownership,
interconnect-owned unmapped ERROR ownership, `supported_seq_size`,
`supported_hburst_modes`, `fail_closed_hburst_modes`, child `burst_signal`,
and child `seq_policy`. Embedded subordinate child reports carry
`bindings.bus.burst`, `narrow_transfer_policy`, and `transfer.seq_policy`.

The matching aggregate HBURST `.ahb` aliases
`ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb` are shipped as
profile aliases over these same sources. They advertise the AHB profile in the
filename, support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq`
with `source_kind: ial2_profile_alias`, and produce identical generated review
artifacts, HDL, and `composition.seq_policy_propagation` reports, differing only
in that the alias reports drop the `.ahb` profile-alias residue.

The matching aggregate byte-lane `SEQ` `.ahb` aliases are shipped as profile
aliases over those same sources. Run them when the filename should advertise
the AHB profile:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane_seq.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-byte-lane-seq-profile-alias ppif/ahb_interconnect_byte_lane_seq.ahb

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-byte-lane-seq-profile-alias ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias ppif/ahb_interconnect_byte_lane_hburst_seq.ahb

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-byte-lane-hburst-seq-profile-alias ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
```

The aggregate byte-lane `SEQ` `.ahb` strict checks report:

```text
entry_id: intent.ahb_profile_alias_interconnect_byte_lane_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_byte_lane_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

Alias reports preserve `composition.byte_lane_propagation`,
`composition.seq_policy_propagation`, child `narrow_transfer_policy`, and
child `transfer.seq_policy`. They remove aggregate/requester/subordinate
profile-alias residue and remove child `.ahb alias exposure` wording from
remaining `ahb_burst_seq_support_deferred` details, while generic `.ppif`
reports keep those source-surface residues.

## Guided PPIF Aggregate HBURST Byte-Lane SEQ Interconnect with BUSY-in-burst Parking

Run the selected generic aggregate HBURST-aware byte-lane `SEQ` interconnects
that park `HTRANS=BUSY` beats through the same review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-byte-lane-hburst-seq-busy-park ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

The strict checks report:

```text
entry_id: intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park
source_kind: ppif
coverage: ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

These two sources are byte-for-byte copies of the aggregate HBURST-aware
byte-lane `SEQ` sources above, differing only in the embedded child transfer
policy. Each inlined subordinate replaces `(ignored-transfer busy)` with
`(parked-transfer busy)` while keeping `(ignored-transfer idle)`:

```text
(ignored-transfer idle)
(parked-transfer busy)
```

`(ignored-transfer idle)` still clears the in-word `SEQ` burst history on an
accepted `IDLE`, but `(parked-transfer busy)` now *holds* that history across an
accepted `HTRANS=BUSY` beat instead of clearing it, so an armed `WRAP4`/`INCR4`
burst resumes cleanly on the next accepted `SEQ`. The shipped endpoint machinery
already implements this park (see the endpoint
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` source), and the
interconnect composes it verbatim — no new interconnect field is added.

The `composition.seq_policy_propagation` block is identical to the non-parking
aggregate HBURST report except that every child `seq_policy` now records BUSY as
a held (parked) transfer rather than a clearing one:

```text
composition.seq_policy_propagation.mode = subordinate_owned_hburst_in_word_seq_policy
composition.seq_policy_propagation.length_source = HBURST
composition.seq_policy_propagation.subordinates[*].seq_policy.parks_on   = [busy]
composition.seq_policy_propagation.subordinates[*].seq_policy.clears_on  = [reset, idle, error, new_nonseq, final_beat]
```

The one-subordinate source emits `amba_requester.isf`,
`ahb_lite_subordinate_byte_lane_hburst_seq.isf`, and `ahb_interconnect.isf`
before generated `amba_requester.fsm`,
`ahb_lite_subordinate_byte_lane_hburst_seq.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`; the two-subordinate source emits the matching status and
control artifacts. The generated topology and HDL entry module `ahb_tb` are
unchanged from the non-parking aggregate HBURST sources.

For these aggregate BUSY-park sources the top-level
`ahb_burst_seq_support_deferred` residue narrows to record that byte-only
`WRAP4`/`INCR4` aggregate HBURST propagation *with BUSY-in-burst parking* is
shipped. The non-parking aggregate HBURST sources keep BUSY-in-burst handling
deferred. Halfword/word burst `SEQ`, wider or indefinite bursts, and
multi-word/register-bank progression remain deferred. At that aggregate
slice's closeout requester-side BUSY insertion was also deferred; the additive
requester source documented below now ships it independently.

The matching aggregate BUSY-park `.ahb` profile aliases
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb` are
shipped as byte-identical mirrors of these generic sources. Run them when the
filename should advertise the AHB profile:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-byte-lane-hburst-seq-busy-park-profile-alias ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

The aliases support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`
with `source_kind: ial2_profile_alias`, produce identical generated review
artifacts, HDL, and `composition.seq_policy_propagation` reports (each child
`parks_on = [busy]`, BUSY-free `clears_on`), and differ only in that the alias
reports drop the aggregate and embedded profile-alias residue while the generic
`.ppif` reports keep it.

## AHB Profile Alias

Use the `.ahb` aliases when you want the source filename to advertise the AHB
profile while keeping the same IAL2 syntax and generated review artifacts.
The requester alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-profile-alias ppif/ahb_requester.ahb
```

The requester `.ahb` strict check reports the authored alias path and support
identity:

```text
entry_id: intent.ahb_profile_alias_requester
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_requester_pipeline_cli
module_name: amba_requester
```

The `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_requester.v1`, reports target profile `ahb`,
and exposes generated `amba_requester.isf` before `amba_requester.fsm`.

The subordinate alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-subordinate-profile-alias ppif/ahb_lite_subordinate.ahb
```

The subordinate `.ahb` strict check reports:

```text
entry_id: intent.ahb_profile_alias_subordinate
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_subordinate_pipeline_cli
module_name: ahb_lite_subordinate
```

The subordinate `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, reports target object
`ahb-subordinate`, exposes generated `ahb_lite_subordinate.isf` before
`ahb_lite_subordinate.fsm`, and removes
`ahb_subordinate_profile_alias_deferred` from the alias report while preserving
the broader AHB residue.

The byte-lane subordinate alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-byte-lane-profile-alias ppif/ahb_lite_subordinate_byte_lane.ahb
```

The byte-lane subordinate `.ahb` strict check reports:

```text
entry_id: intent.ahb_profile_alias_subordinate_byte_lane
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_subordinate_byte_lane_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane
```

The byte-lane subordinate `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, reports target object
`ahb-subordinate`, exposes generated `ahb_lite_subordinate_byte_lane.isf`
before `ahb_lite_subordinate_byte_lane.fsm`, preserves
`narrow_transfer_policy`, and removes
`ahb_subordinate_profile_alias_deferred` from the alias report while preserving
the broader AHB residue. The generic byte-lane `.ppif` report keeps that
alias-deferred residue.

The byte-lane `SEQ` subordinate alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-byte-lane-seq-profile-alias ppif/ahb_lite_subordinate_byte_lane_seq.ahb
```

The byte-lane `SEQ` subordinate `.ahb` strict check reports:

```text
entry_id: intent.ahb_profile_alias_subordinate_byte_lane_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_subordinate_byte_lane_seq_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane_seq
```

The byte-lane `SEQ` subordinate `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, reports target object
`ahb-subordinate`, exposes generated
`ahb_lite_subordinate_byte_lane_seq.isf` before
`ahb_lite_subordinate_byte_lane_seq.fsm`, preserves
`narrow_transfer_policy` and `transfer.seq_policy`, removes
`ahb_subordinate_profile_alias_deferred`, and no longer lists `.ahb alias
exposure` in the remaining `ahb_burst_seq_support_deferred` detail. The
generic byte-lane `SEQ` `.ppif` report keeps that source-surface alias residue.

The HBURST-aware byte-lane `SEQ` subordinate alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-byte-lane-hburst-seq-profile-alias ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
```

The HBURST-aware byte-lane `SEQ` subordinate `.ahb` strict check reports:

```text
entry_id: intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane_hburst_seq
```

The HBURST-aware byte-lane `SEQ` subordinate `.ahb` schedule/report JSON uses
schema `fsmgen.ial2.protocol_intent.ahb_subordinate.v1`, reports target object
`ahb-subordinate`, exposes generated
`ahb_lite_subordinate_byte_lane_hburst_seq.isf` before
`ahb_lite_subordinate_byte_lane_hburst_seq.fsm`, preserves
`bindings.bus.burst` and `transfer.seq_policy.mode =
hburst_in_word_progressive`, removes `ahb_subordinate_profile_alias_deferred`,
and no longer lists `.ahb alias exposure` in the remaining
`ahb_burst_seq_support_deferred` detail. The generic HBURST-aware `.ppif`
report keeps that source-surface alias residue.

The aggregate interconnect alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-profile-alias ppif/ahb_interconnect.ahb
```

The aggregate `.ahb` strict check reports:

```text
entry_id: intent.ahb_profile_alias_interconnect
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_pipeline_cli
module_name: ahb_tb
composition_child_count: 3
```

The aggregate `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, reports target object
`ahb-interconnect`, exposes generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, and
aggregate `ahb_tb.fsm`, and removes `ahb_aggregate_profile_alias_deferred`,
`ahb_profile_alias_deferred`, and
`ahb_subordinate_profile_alias_deferred` from the alias report tree while
preserving the broader AHB residue.

The two-subordinate aggregate interconnect alias is:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-profile-alias ppif/ahb_interconnect_two_subordinate.ahb
```

The two-subordinate aggregate `.ahb` strict check reports:

```text
entry_id: intent.ahb_profile_alias_interconnect_two_subordinate
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

The two-subordinate aggregate `.ahb` schedule/report JSON uses schema
`fsmgen.ial2.protocol_intent.ahb_interconnect.v1`, reports topology
`one_requester_two_subordinate_static_window_interconnect`, exposes generated
`amba_requester.isf`, `ahb_status_subordinate.isf`,
`ahb_control_subordinate.isf`, and `ahb_interconnect.isf` before generated
`amba_requester.fsm`, `ahb_status_subordinate.fsm`,
`ahb_control_subordinate.fsm`, `ahb_interconnect.fsm`, and aggregate
`ahb_tb.fsm`, and removes `ahb_aggregate_profile_alias_deferred`,
`ahb_profile_alias_deferred`, and
`ahb_subordinate_profile_alias_deferred` from the alias report tree while
preserving the broader AHB residue.

The aggregate byte-lane interconnect aliases are:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-interconnect-byte-lane-profile-alias ppif/ahb_interconnect_byte_lane.ahb

./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --outdir generated/ial2-ahb-two-subordinate-byte-lane-profile-alias ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

The aggregate byte-lane `.ahb` strict checks report:

```text
entry_id: intent.ahb_profile_alias_interconnect_byte_lane
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_byte_lane_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

Both aggregate byte-lane aliases preserve
`composition.byte_lane_propagation`, child `narrow_transfer_policy`,
local-address-before-byte-lane policy, subordinate-owned mapped-hit
byte/halfword/word behavior, and interconnect-owned unmapped ERROR behavior.
They remove `ahb_aggregate_profile_alias_deferred`,
`ahb_profile_alias_deferred`, and
`ahb_subordinate_profile_alias_deferred` from alias report trees while the
generic aggregate byte-lane `.ppif` reports keep those source-surface
residues.

## Requester Source Shape

The public requester sources start with the selected AHB requester shape:

```text
(protocol-platform-intent ahb_requester
  (profile ahb)
  (source
    (object fsmgen-ahb-requester)
    (anchor
      (document FSMGEN-AHB-REQUESTER-CAPTURE-WORKSHEET)
      (section bounded-requester)
      (page stage-1)))
  (ahb-requester amba_requester
    (role requester)
    (clock clk)
    (reset (rst_n active_low async))
    ...))
```

The generated AHB-side HDL ports include `HGRANT`, `HREADY`, `HRESP`,
`HRDATA`, `HBUSREQ`, `HLOCK`, `HADDR`, `HTRANS`, `HWRITE`, `HSIZE`, `HBURST`,
`HPROT`, and `HWDATA`. The local command/status ports include `cmd_valid`,
`cmd_ready`, `cmd_write`, `cmd_addr`, `cmd_wdata`, `cmd_wdata_step`,
`cmd_size`, `cmd_prot`, `cmd_lock`, `cmd_burst`, `cmd_len`, `busy`,
`beat_done`, `done`, `burst_active`, `wrap_active`, `beat_index`,
`beats_remaining`, `active_addr`, `active_hburst`, `last_error`,
`last_retry`, `last_split`, `last_resp`, and `last_read_data`.

The generated IAL1 requester uses separate address, data, and captured-response
ownership plus an internal transaction completion bit, so an accepted address
retires independently of its later data response and public `done` remains an
ordinary status drive:

```text
(storage
  (var ahb_address_pending_q (width 1) (reset 0))
  (var ahb_data_pending_q (width 1) (reset 0))
  (var ahb_response_pending_q (width 1) (reset 0))
  (var ahb_response_q (width 2) (reset 0))
  (var ahb_read_data_q (width 32) (reset 0))
  (var ahb_request_done_q (width 1) (reset 0)))
...
(complete ahb_request_done_q)
```

## Requester Clauses

The public requester intentionally models a bounded requester rather than a
full AMBA manager. The accepted object is exactly one
`(ahb-requester amba_requester ...)` under `(profile ahb)`.

Required blocks:

- `clock` and `reset`;
- `local-command` for `cmd_*` request fields;
- `local-status` for status outputs and last-response capture;
- `bus` for AHB request/response signal bindings;
- `burst` for the selected AHB burst encodings;
- `transfer` for IDLE/NONSEQ/SEQ transfer behavior;
- `response` for OKAY/ERROR/RETRY/SPLIT actions.

Selected widths are fixed in this slice: 32-bit address/data, 3-bit AHB size
and burst, 4-bit protection, 5-bit local length/index/count, and 2-bit transfer
and response. Unsupported widths, missing required blocks, duplicate blocks,
duplicate fields, unsupported fields, and non-AHB profiles fail closed.

The selected requester transfer behavior is:

- first accepted beat uses `HTRANS=NONSEQ`;
- later accepted beats use `HTRANS=SEQ`;
- new address presentation is gated by `HGRANT`;
- `HGRANT && HREADY` accepts the address phase, moves ownership to the data
  phase, and immediately retires `HTRANS` to `IDLE`;
- the later ready edge captures `HRESP` and `HRDATA` before response handling;
- `OKAY` advances or completes;
- `ERROR` completes with error status;
- `RETRY` and `SPLIT` keep the request active for re-request behavior.

On an accepted `OKAY` beat, remaining count `1` is the terminal path: the
requester writes the count to zero and leaves the active burst. Only a count
strictly greater than `1` takes the non-terminal path that decrements the
count and advances the beat index, address, and stepped write data. Keeping
those guards structurally exclusive is important after lowering because the
two clauses execute as sequential FSM states. The generated-HDL regression
therefore proves both ends of the bounded contract: `SINGLE` produces exactly
one accepted beat, while `INCR4` produces exactly four at indices `0..3`,
finishes with zero remaining, and never underflows to the five-bit value `31`.

## Requester BUSY Insertion

Use the additive requester BUSY-insertion source when a bounded burst should
request one held AHB BUSY episode before a selected later beat:

```text
(protocol-platform-intent ahb_requester_busy_insert
  (profile ahb)
  ...
  (ahb-requester amba_requester_busy_insert
    ...
    (transfer
      (idle 2'b00)
      (busy 2'b01)
      (nonseq 2'b10)
      (seq 2'b11)
      (first-beat nonseq)
      (later-beats seq)
      (advance-on ready)
      (busy-before-beat 2))
    ...))
```

Run the checked-in example:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-requester-busy-insert ppif/ahb_requester_busy_insert.ppif
```

The source keeps the base requester command/status/bus interface. At beat index
two it presents the pending address, control, and write data with
`HTRANS = 2'b01`, holds the beat index and remaining count, and skips response
advancement. The following transfer-type transition is the same pending beat as
`SEQ`; an `INCR4` therefore shows `NONSEQ(0) → SEQ(1) → BUSY(2 held) → SEQ(2
resumed) → SEQ(3)` while accepting exactly four data beats.

`busy-before-beat` is a literal in `1..15` and requires `(busy 2'b01)`.
Malformed, missing, duplicate, or out-of-range declarations fail closed. The
report's `busy_insertion` block records generated behavior, the BUSY encoding,
the insertion index, and the `single` bound. The source generates
`amba_requester_busy_insert.isf`, then `.fsm`, then HDL module
`amba_requester_busy_insert`; it is support-accounted as
`intent.ppif_ahb_requester_busy_insert`. The base requester and its `.ahb` alias
remain BUSY-insertion free. The matching additive alias
`ppif/ahb_requester_busy_insert.ahb` now ships with identical generated
behavior. Runtime/policy-driven or multi-beat BUSY throttling and a separate
local bus-BUSY status output remain deferred. The one-subordinate paired
generic/alias and two-subordinate paired generic sources are described below.

> **Generated endpoint assertion boundary:** the subordinate arbitration audit
> maps the idle/capture, idle/hold, and ERROR-retire/capture overlaps. Its
> selected contract removes only capture/hold HRESP+HRDATA and retirement
> HRDATA writes; all ready ownership, functional drive values, priorities, and
> generic assertions stay fixed. The richest disposable candidate passes the
> full direct phase-pipeline runtime with assertions enabled. Implementation
> `.3` now ships exactly those five removals. Base and richest direct t1519 and
> paired t1513-t1516/t1523/t1525 all pass with requester, fabric, generated
> endpoint, and internal selector assertions enabled. The separately
> hand-authored direct IAL0 seed later received its own four-write
> assertion-clean repair. See the
> [shipped behavior](../../IAL2_AHB_SUBORDINATE_DEFAULT_PHASE_OUTPUT_ARBITRATION_BEHAVIOR.md).

> **Exact single-event cardinality:** `busy_insertion.beats=single` now means
> exactly one rising edge with `HGRANT && HREADY && HTRANS == BUSY`. BUSY
> remains a pending presentation while either qualifier is low; its address,
> control, write data, beat index, and remaining count stay stable. A
> conditional acceptance rule then reuses existing address-pending ownership
> to present the same transfer as `SEQ`, without new syntax, report fields,
> storage, or a counter. Assertion-enabled t/1498 proves continuously-qualified,
> 32-clock ready-low, and 32-clock grant-low cases, each with one qualified BUSY
> event and four data beats. Generic and `.ahb` paired tests t/1513-t/1516 count
> one qualified event per command. The historical
> [multiple-BUSY readiness audit](../../IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md)
> records the former ten-edge mismatch; the
> [single-event repair](../../IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md)
> records the shipped correction. Paired aggregate tests now run with all
> requester, repaired-fabric, generated-endpoint, and internal selector
> assertions enabled. Their qualified BUSY counts remain explicit.

The additive exact-two extension now ships as the generic source
`ppif/ahb_requester_busy_insert_two.ppif`:

```text
(protocol-platform-intent ahb_requester_busy_insert_two
  (profile ahb)
  ...
  (ahb-requester amba_requester_busy_insert_two
    ...
    (transfer
      (idle 2'b00)
      (busy 2'b01)
      (nonseq 2'b10)
      (seq 2'b11)
      (first-beat nonseq)
      (later-beats seq)
      (advance-on ready)
      (busy-before-beat 2)
      (busy-beats 2))
    ...))
```

Run its complete public review path:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_two.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_two.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_two.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-requester-busy-insert-two ppif/ahb_requester_busy_insert_two.ppif
./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_two.ppif
```

`busy-before-beat 2` still selects the pending beat; literal `busy-beats 2`
selects exactly two events with
`HGRANT && HREADY && HTRANS == BUSY`. Ready-low and grant-low clocks consume no
count. A width-two actor-owned counter initializes before BUSY becomes visible,
decrements on the first qualified event, and on the second event clears and
hands the unchanged pending transfer to existing address-pending `SEQ`
ownership. BUSY completes no data beat or response.

The schedule/report surface is intentionally asymmetric for compatibility:

```text
exact-one: busy_insertion.beats = single
exact-two: busy_insertion.beats = 2
```

The exact-two source generates `amba_requester_busy_insert_two.isf`, then
`.fsm`, then HDL module `amba_requester_busy_insert_two`; support identity is
`intent.ppif_ahb_requester_busy_insert_two`. Assertion-enabled t/1521 proves
continuous, 32-clock ready-low, and 32-clock grant-low cases with one BUSY
episode, exactly two qualified BUSY events, the same resumed `SEQ`, and four
data beats. Existing exact-one and base requesters retain their generated
shape. This source reuses the current AHB requester generator; it is not a new
generator.

Literal values two through four are now accepted by the bounded count clause.
Absence remains the canonical exact-one form; zero, one, values above four,
non-literals, missing prerequisites, and duplicates fail closed. The exact-two `.ahb` requester alias
now ships through `.7`, and the first generic one-subordinate exact-two paired
composition now ships through the paired tree's `.3`; its matching aggregate
alias now ships through `.5`. The generic two-subordinate exact-two sibling and
its matching `.ahb` alias now ship through `.8`/`.811`. See the
[selected contract](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_CONTRACT_SELECTION.md)
and [shipped behavior](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_BEHAVIOR.md).

The matching alias now ships at `ppif/ahb_requester_busy_insert_two.ahb`. It is
byte-identical to the generic source and reuses the same requester generator
and IAL2 -> IAL1 -> IAL0 -> HDL route. Existing `.ahb` suffix handling
preserves numeric `busy_insertion.beats=2` and generated artifacts while
removing only `ahb_profile_alias_deferred`. Its support identity is
`intent.ahb_profile_alias_requester_busy_insert_two`, source kind is
`ial2_profile_alias`, and semantic root is `fsm`. Focused t/1522 proves strict
check, schedule, semantic JSON, artifacts, HDL verification, and a real
read-only `fsmgen_semantic_introspect` MCP call; t/1521 remains the shared
runtime proof. The requester-only inventory checkpoint was forty paths evenly
split between `.ppif` and `.ahb`; the generic paired exact-two source moved the
next checkpoint to forty-one paths, and its alias now moves the current
inventory to forty-two paths; the generic two-subordinate exact-two source
established forty-three paths, and its matching alias now moves the current
inventory to forty-four paths: twenty-two `.ppif` and twenty-two `.ahb`. The
generic exact-three requester established forty-five paths and its matching
alias established forty-six paths. The generic exact-three paired source
established forty-seven paths, and its matching alias now moves the current
inventory to forty-eight paths. The generic two-subordinate exact-three paired
source established forty-nine paths; its matching alias now establishes fifty
paths: twenty-five `.ppif` and twenty-five `.ahb`.
See the
[selected alias contract](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md)
and [shipped alias behavior](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md).

### Exact-three generic requester

The additive generic exact-three source now ships at
`ppif/ahb_requester_busy_insert_three.ppif`:

```text
(transfer
  (idle 2'b00)
  (busy 2'b01)
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready)
  (busy-before-beat 2)
  (busy-beats 3))
```

Use the guarded public review path:

```bash
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_three.ppif
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_three.ppif
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_three.ppif
scripts/run_with_ram_guard.sh -- ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_three.ppif
```

Its module and artifacts are `amba_requester_busy_insert_three`,
`amba_requester_busy_insert_three.isf`, and
`amba_requester_busy_insert_three.fsm`; support ID is
`intent.ppif_ahb_requester_busy_insert_three`. The report uses numeric
`busy_insertion.beats=3`.

The existing width-two actor counter and qualified rules are unchanged.
Assertion-enabled t/1528 directly observes `3 -> 2 -> 1 -> 0` in continuous,
32-clock ready-low, and 32-clock grant-low cases. Each has one BUSY episode,
three qualified BUSY events, stable pending ownership, no BUSY data/response
completion, one resumed `SEQ`, four accepted byte `INCR4` data beats, and zero
final count. Strict, schedule, exact artifacts, verifier, normalized semantic
JSON, and real read-only shell-disabled MCP parity also pass. Strengthened
t/1521 directly retains exact-two `2 -> 1 -> 0` proof.

The matching exact-three `.ahb` alias established 322 protocol fixtures, 363
supported-smoke plus strict fixtures, and 46 AHB paths split 23 `.ppif` / 23
`.ahb`; the later generic exact-three paired source established 323/364/47
split 24/23, and its matching alias established 324/365/48
split 24/24. The requester alias ships byte-identically through
existing suffix handling. It uses support ID
`intent.ahb_profile_alias_requester_busy_insert_three`, source kind
`ial2_profile_alias`, the same `amba_requester_busy_insert_three` artifacts and
HDL module, numeric `beats=3`, and semantic root `fsm`. Focused t1529 proves
parity without a second runtime, and t1528 remains shared. See the
[contract](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_CONTRACT_SELECTION.md)
and [shipped behavior](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_BEHAVIOR.md),
plus the
[selected alias contract](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md).
See also the
[shipped alias behavior](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md).

### Exact-four generic and profile-alias requester

The additive exact-four source ships byte-identically at
`ppif/ahb_requester_busy_insert_four.ppif` and
`ppif/ahb_requester_busy_insert_four.ahb`:

```text
(transfer
  (idle 2'b00)
  (busy 2'b01)
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready)
  (busy-before-beat 2)
  (busy-beats 4))
```

Run its guarded review path:

```bash
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_four.ppif
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_four.ppif
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_four.ppif
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- ./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_four.ppif
```

The existing requester generator emits
`amba_requester_busy_insert_four.isf`, then `.fsm`, then HDL module
`amba_requester_busy_insert_four`. Support identity is
`intent.ppif_ahb_requester_busy_insert_four`; reports use numeric
`busy_insertion.beats=4`.

Multiple-BUSY counters now use minimum unsigned width equivalent to
`ceil(log2(busy_beats + 1))`. Exact-two and exact-three remain width two;
exact-four is width three. Existing qualified rules retire
`4 -> 3 -> 2 -> 1 -> 0` without changing priorities, owners, or IAL1 syntax.
Assertion-enabled t/1535 proves continuous, 32-clock ready-low, and 32-clock
grant-low cases with one BUSY episode, four qualified BUSY events, stable
pending ownership, no BUSY data/response completion, one resumed `SEQ`, four
byte `INCR4` data beats, and zero final count. The same test covers strict,
schedule, artifacts, public HDL verification, normalized semantic JSON, real
read-only shell-disabled MCP, diagnostics, and exact-one/two/three
preservation.

The alias uses support identity
`intent.ahb_profile_alias_requester_busy_insert_four`, coverage
`ial2_ahb_profile_alias_requester_busy_insert_four_pipeline_cli`, source kind
`ial2_profile_alias`, and semantic root `fsm`. Existing suffix handling removes
only `ahb_profile_alias_deferred`; numeric `beats=4`, width-three IAL1/IAL0,
HDL, artifacts, and semantics are identical. Focused t/1536 proves strict,
schedule, artifact, normalized semantic, real read-only shell-disabled MCP,
verifier, diagnostic, requester, and paired-source parity without simulation;
t1535 remains shared runtime.

Current accounting is 328 protocol fixtures, 369 supported-smoke plus strict
fixtures, and 52 AHB paths split 26 `.ppif` / 26 `.ahb`. See the
[generic behavior](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md)
and [profile-alias behavior](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md).

`IAL2-FEATURE-COMPLETENESS-FRONTIER.789` selected `.790`, which now ships the
matching `ppif/ahb_requester_busy_insert.ahb` profile alias. It mirrors the
generic source byte-for-byte, preserves the `busy_insertion` report and generated
`amba_requester_busy_insert.isf`/`.fsm`/HDL module, and uses existing `.ahb`
suffix handling to remove only `ahb_profile_alias_deferred`. Its support
identity is `intent.ahb_profile_alias_requester_busy_insert` with coverage
`ial2_ahb_profile_alias_requester_busy_insert_pipeline_cli`; no parser or
generator changed. Use the alias by substituting the `.ahb` path in the commands
above. Focused t/1512 proves source/artifact/report/CLI/support parity, and
t/1498 retains generated-HDL runtime proof.

The next bounded step is an end-to-end composition, not a broader BUSY policy.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.791` selects `.792`, a no-behavior
readiness audit for one aggregate that combines the BUSY-inserting requester
with the HBURST-aware byte-lane subordinate that parks BUSY. The current
aggregate generator already accepts that endpoint combination and emits the
requester, subordinate, interconnect, and top review artifacts. Its subordinate
and propagation reports preserve `parks_on = [busy]`.

The audit comes before implementation because aggregate requester-child JSON is
not yet complete for this behavior: the standalone requester exposes
`busy_insertion`, while `AhbInterconnect::_child_report` currently copies the
child's `transfer`, artifacts, and residue but not that optional block. `.792`
must settle whether and how to propagate it and freeze the exact generated-HDL
proof that BUSY consumes no data beat, the subordinate retains burst context,
the same `SEQ` beat resumes, and exactly four data beats complete.

`.792` confirms there is no deeper substrate gap and selects `.793`, a
no-behavior public contract selection. The source can reuse the existing
one-subordinate aggregate shape; endpoint generation, bus wiring, and the
`ahb_tb` structural top already compose. The required report change is a
conditional clone of requester `busy_insertion` in the aggregate child view,
which leaves base-requester aggregates unchanged. A generated-HDL harness can
drive the top's existing command ports and observe its deterministic internal
requester bus plus subordinate continuation/storage state, without adding
public debug ports. `.793` must name and freeze that one-`.ppif`,
one-subordinate contract before implementation; matching alias and
two-subordinate variants were deferred by that selector and ship later below.

`.793` freezes that contract for `.794`. The new generic source will be
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif`,
generating the existing `ahb_tb` top from the BUSY requester, BUSY-parking
subordinate, and interconnect artifacts. Aggregate requester-child JSON gains
the endpoint's `busy_insertion` block; together with existing
`composition.seq_policy_propagation.*.parks_on = [busy]`, that is the complete
paired report—there is no redundant top summary. Focused t/1513 and its
Verilator harness must prove the five transfer presentations, held requester
and subordinate state/storage on BUSY, resumed `SEQ`, four accepted data beats,
OKAY completion, zero remaining, and final register value `32'h44332211`.
Generic `.ppif` ships first; the matching `.ahb` and generic two-subordinate
sibling ship in the later slices below.

## Paired Requester BUSY Insertion and Subordinate Parking

`.794` now ships the selected generic pair:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
```

The generated aggregate is still `ahb_tb`. The requester child exposes
`busy_insertion` with encoding `2'b01`, insertion index two, and a single
presentation. The subordinate child and aggregate SEQ-policy propagation expose
`parks_on = [busy]`. These are the canonical paired facts; there is no duplicate
top-level `busy_flow` summary.

Generated-HDL t/1513 proves:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)
```

The requester holds address/control/data and counters from BUSY to resumed
`SEQ`; the subordinate holds its expected address, burst-remaining state, and
register storage; exactly four byte data beats complete with OKAY; final
remaining count is zero; and the register becomes `32'h44332211`.

The current shared generated phase contract is coupled across all three AHB
roles. The requester retires accepted `HTRANS` to IDLE while retaining the data
phase and captures HRESP/HRDATA on completion. The subordinate banks one
accepted address/control phase in `ahb_phase_pending_q`, drives ready low while
pending, and does not bank data-phase HWDATA. The interconnect retains a
one-hot `ahb_data_owner_N_q` and muxes HREADY/HRESP/HRDATA from that owner
through data completion; a mapped acceptance on the same completion edge
replaces the owner atomically. Continuation clearing is a concurrent
`ahb_seq_idle_clear` rule, and sampled `wait_cycles` use a lint-clean counted
repetition.

Generated-HDL t/1519 proves boundary-free active-phase retention directly at
the subordinate. The interconnect child instance remains HDL-safe `fabric`; a
zero-base decode emits only its upper bound, while nonzero-base windows retain
both bounds. General queues/multiple outstanding transfers and broader BUSY/
burst policies remain deferred.

`.795` selected `.796`; `.796` now ships the matching paired `.ahb` profile
alias. The tracked alias is byte-identical to the generic source and preserves the same generated
requester, subordinate, `fabric`, top, requester-child `busy_insertion`, and
subordinate/aggregate `parks_on = [busy]`. Existing suffix handling removes
only alias-specific residue. The `.ahb` file does not create a new generator or
behavior; it is a second public entrypoint into the same
IAL2-to-IAL1-to-IAL0-to-HDL architecture. Focused t/1514 proves alias parity,
CLI/report/artifact/support surfaces, diagnostics, and `--verify-hdl`; t/1513
retains the shared runtime proof. See
[IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md).

`.797` now selects `.798`, a no-behavior readiness audit for the
two-subordinate paired sibling. A current in-memory candidate replaces the
shipped two-subordinate BUSY-park aggregate's requester with
`amba_requester_busy_insert` and already reports four children, requester
`busy_insertion`, and `parks_on=[busy]` for both status/control child policies
and both aggregate-propagated policies. It generates the expected requester,
status, control, interconnect, and `ahb_tb` review artifacts.

The audit comes before implementation for two reasons. First, generated-HDL
proof must cover both the zero-base status window and the control window whose
local address is `HADDR - 4`, including selected-child parking and unselected-
child non-interference. Second, the live shipped two-subordinate BUSY-park
report is contradictory: `ahb_broader_interconnect_decode_deferred` still lists
BUSY-in-burst continuation as future work while
`ahb_burst_seq_support_deferred` correctly says BUSY parking ships. `.798` must
select a report-only repair that preserves BUSY deferral on non-parking sources
before choosing the public paired source contract. See
[IAL2_POST_AHB_PAIRED_BUSY_FAMILY_NEXT_SLICE_SELECTION](../../IAL2_POST_AHB_PAIRED_BUSY_FAMILY_NEXT_SLICE_SELECTION.md).

`.798` confirms the candidate across public check, schedule, semantic,
review-artifact, SystemVerilog, and Yosys surfaces. It reports module `ahb_tb`,
four children, 29 signals, status `[0,4)`, control `[4,8)`, four IAL1/five IAL0
artifacts, requester `busy_insertion`, both child/propagated
`parks_on=[busy]`, semantic root `top`, and clean 21,656-line generated HDL.
The top exposes status/control select and local-address signals plus each
child's `seq_*` state and storage, so a future two-command harness can prove
status-base-0 and control-base-4 BUSY parking, non-interference, local address
subtraction, completion, and distinct storage results without new ports.

Before that public contract, `.799` repairs the already-shipped report
contradiction. The two-subordinate broader residue must use the existing
BUSY-park predicate: parked sources say BUSY parking ships and no longer defer
BUSY continuation; non-parking sources keep the deferral. This is report text
only—no transfer behavior or support count changes. `.800` then owns the paired
source contract. See
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_READINESS_AUDIT](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_READINESS_AUDIT.md).

`.799` now ships that report-only repair. On two-subordinate HBURST sources
whose children all park BUSY, `ahb_broader_interconnect_decode_deferred`
records byte-only `WRAP4`/`INCR4` in-word `SEQ` propagation with BUSY-in-burst
parking as shipped and no longer lists BUSY continuation as deferred. The
non-parking generic and alias sources still defer BUSY continuation. Report ids
and structure, sources, generated artifacts, support accounting, and HDL/runtime
behavior are unchanged; focused t/1492, t/1493, t/1496, and t/1497 pass. `.800`
now owns the paired public contract. See
[IAL2_AHB_TWO_SUBORDINATE_BUSY_REPORT_REPAIR](../../IAL2_AHB_TWO_SUBORDINATE_BUSY_REPORT_REPAIR.md).

`.800` selects `.801`, the generic two-subordinate paired source. It is an
additive copy of the shipped two-subordinate BUSY-park aggregate with only
identity/anchor changes and the requester replaced by
`amba_requester_busy_insert`. The frozen surface is module `ahb_tb`, four
children, 29 signals, status `[0,4)`, control `[4,8)`, four IAL1/five IAL0
artifacts, and one support entry taking accounting to 313 protocol / 354
supported-smoke+strict.

The decisive generated-HDL example runs two byte `INCR4` writes. Status at base
0 must finish as `32'h44332211`; control at base 4 must see local addresses
`0,1,2,2,3` across `NONSEQ,SEQ,BUSY,SEQ,SEQ` and finish as
`32'h88776655`, while status remains unchanged. Each command proves selected-
child BUSY parking and unselected-child non-interference. The matching `.ahb`
alias remains a later slice. See
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_CONTRACT_SELECTION](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_CONTRACT_SELECTION.md).

`.801` now ships that generic two-subordinate paired source. It is a new
public IAL2 description over the existing generator pipeline, not a new
generator: four generated IAL1 artifacts lower to the requester, status,
control, interconnect, and `ahb_tb` IAL0 artifacts, then to SystemVerilog.
Strict check reports `ahb_tb`, four children, 29 signals, and semantic root
`top`; schedule JSON exposes requester `busy_insertion`, both child and
propagated `parks_on=[busy]` policies, and the unchanged `[0,4)` status and
`[4,8)` control windows. Accounting is now 313 protocol fixtures and 354
supported-smoke/strict entries.

Focused t/1515 generates and verifies the HDL, builds it with Verilator, then
runs status-base-0 and control-base-4 byte `INCR4` commands. Each observes
`NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, one BUSY,
four accepted data beats, selected-child state/storage parking, unselected-
child non-interference, and clean completion. The control command additionally
proves global `4,5,6,6,7` maps to local `0,1,2,2,3`. Final status/control
storage is `32'h44332211`/`32'h88776655`. No parser or generator algorithm
changed; the matching `.ahb` alias remains a separate later slice. See
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md).

`.802` selects `.803`, the matching two-subordinate paired `.ahb` profile
alias. A current in-memory adapter probe parses the `.801` source under the
reserved future `.ahb` label and preserves four children, the exact four
IAL1/five IAL0 artifacts, requester `busy_insertion`, and both status/control
`parks_on=[busy]` policies. Existing suffix handling removes only aggregate,
requester, and both subordinate alias residue families plus alias-exposure
wording. Therefore `.803` is a byte-identical source/support/parity-test
slice, not another generator or behavior implementation. It targets 314
protocol fixtures and 355 supported-smoke/strict entries; t/1516 will prove
alias parity and public surfaces while t/1515 remains the shared generated-HDL
runtime proof. See
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md).

`.803` now ships that matching alias as a byte-identical mirror of the generic
source. The `.ppif` and `.ahb` paths are two public IAL2 surfaces over one
four-child generator architecture. The alias preserves requester
`busy_insertion`, both status/control child and propagated
`parks_on=[busy]`, exact artifacts/windows, and t/1515 runtime behavior;
existing suffix handling removes only aggregate/requester/both-subordinate
alias residue plus alias-exposure wording. t/1516 proves parity, public
check/schedule/semantic/artifact/HDL/support/report surfaces, malformed-profile
diagnostics, and clean `--verify-hdl`. Accounting is now 314 protocol fixtures
and 355 supported-smoke/strict entries. See
[IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR](../../IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md).

`.804` selects the existing
`IAL2-AHB-REQUESTER-WRAP-PROGRESSION-AUDIT` as the next exact AHB owner. This
is a correctness audit, not another generator or feature implementation. The
requester generator and emitted IAL0 FSM currently express wrapping progression
as two sequential clauses:

```text
when next address reaches wrap_high_q: addr_q = wrap_base_q
when next address does not reach wrap_high_q: addr_q = addr_q + addr_step_q
```

Because the second predicate may observe the first clause's write, the
wrap-to-base result may be overwritten by base-plus-step. No current public
requester generated-HDL test records accepted `WRAP4` addresses through the
boundary, so this is a source/FSM risk, not yet a runtime-proven defect. After
`.804` commits cleanly, the selected audit must record a deterministic
four-beat address sequence, correlate it with generated IAL1/IAL0 states, and
either close the concern or select a separate bounded repair leaf. Broader BUSY
policy/status, larger bursts, boundary-free pipelining, optional signals,
decision 0020, and the transaction-layer horizon remain deferred or inactive.
See
[IAL2_POST_TWO_SUBORDINATE_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION](../../IAL2_POST_TWO_SUBORDINATE_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md).

> **Requester WRAP defect resolved in `.2`:** the pre-repair requester
> presented byte `WRAP4` addresses `3,1,2,3` for a command starting at `3`,
> instead of required `3,0,1,2`. The generated requester and direct seed now
> increment first and wrap the incremented high-boundary value to the base
> before the next transfer.

At audit commit `ec9fa2ee3`, focused t/1517 proved both the generated-state
cause and the historical bad bus sequence. The pre-repair IAL1/IAL0 path first
wrote `addr_q = wrap_base_q`, then a following numbered state re-evaluated the
negated comparison against the mutated address and overwrote it with
base-plus-step. `WRAP4`, `WRAP8`, and `WRAP16` shared this path. Incrementing
modes and the paired BUSY `INCR4` runtime proofs were not affected by this
specific defect.

`.2` implements that repair while keeping public sources, ports, reports,
support counts, artifact names, and non-wrap behavior stable. Generated-HDL
t/1517 proves these representative accepted-address sequences:

```text
WRAP4 byte, start 3:      3, 0, 1, 2
WRAP4 halfword, start 6:  6, 0, 2, 4
WRAP4 word, start 12:    12, 0, 4, 8
WRAP8 byte, start 7:      7, 0, 1, 2, 3, 4, 5, 6
WRAP16 byte, start 15:   15, 0, 1, ..., 14
```

Each command uses one `NONSEQ` followed by the required `SEQ` transfers and
completes cleanly. See the historical
[runtime audit](../../IAL2_AHB_REQUESTER_WRAP_PROGRESSION_RUNTIME_AUDIT.md)
and the current
[repair record](../../IAL2_AHB_REQUESTER_WRAP_PROGRESSION_REPAIR.md).

`.805` next found a current-documentation contradiction before selecting more
AHB behavior: all six selected aggregate/paired `.ahb` aliases exist and have
focused parity tests, and the inventory above lists them, but the protocol
navigation/current mode text and three canonical behavior/fact pairs still
defer one or more aliases. `.806` is selected to repair those current surfaces,
preserve historical time-local records, and add t/1518 drift coverage. The
boundary-free active-transfer audit remains proposed behind that prerequisite.
See
[IAL2_POST_REQUESTER_WRAP_REPAIR_NEXT_OWNER_SELECTION](../../IAL2_POST_REQUESTER_WRAP_REPAIR_NEXT_OWNER_SELECTION.md).

`.806` now completes that repair. Current navigation/mode text and the three
canonical behavior/fact pairs link the later alias owners, while historical
"not shipped in this slice" records remain intact. Focused t/1518 requires all
six alias paths and the positive current claims and rejects the stale current
deferrals. No generated or runtime behavior changes. See
[IAL2_AHB_CURRENT_SURFACE_ALIAS_TRUTHFULNESS_REPAIR](../../IAL2_AHB_CURRENT_SURFACE_ALIAS_TRUTHFULNESS_REPAIR.md).

`.807` now selects the canonical boundary-free active-transfer audit. Current
subordinate ownership admits only when `ahb_access_active_q` is clear and
releases on unselected/`IDLE`/`BUSY`; the shipped paired requester and its
runtime proofs intentionally provide that boundary. Audit `.1` will drive
generated public subordinate HDL with consecutive selected active phases and
record address/data phase, ready/response, ownership, acceptance, and storage
before any behavior decision. See
[IAL2_POST_CURRENT_SURFACE_REPAIR_NEXT_OWNER_SELECTION](../../IAL2_POST_CURRENT_SURFACE_REPAIR_NEXT_OWNER_SELECTION.md).

> **Boundary-free active-transfer defect confirmed by `.1`:** generated-HDL
> t/1519 presents `NONSEQ` address 0 followed directly by held `SEQ` address 1.
> `HREADY/HREADYOUT` stalls then accepts both active address phases with OKAY,
> but the subordinate records only one admission/completion, retains sampled
> address 0/`NONSEQ`, and leaves storage at `32'h00000011` instead of applying
> the second lane-one write (`32'h00002211`).

The ownership bit correctly suppresses duplicate sampling of one held phase,
but it cannot distinguish that phase from the distinct phase accepted when the
current data phase raises ready. Requiring the requester to insert an
`IDLE`/`BUSY` boundary is not a safe endpoint fail-closed rule: holding ready
low deadlocks the next stable address phase, while raising ready accepts it.
`.1` therefore selects `.2`, no-behavior contract selection for atomic
completion-boundary recapture of exactly one next active phase. General
outstanding queues, multi-manager behavior, and decision 0020 remain outside
this boundary. See the
[runtime audit](../../IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md).

`.2` selected the depth-one accepted address/control bank at the bus-visible
ready edge. `.3` now implements it and the paired generated-role prerequisites:
requester address/data ownership separation with response-edge capture,
subordinate one-slot phase retention, and interconnect retained data-phase
ownership. Current t/1519 proves exact two-acceptance/two-completion
NONSEQ-to-SEQ behavior plus final-ERROR active-capture versus IDLE cancel;
t/1513 and t/1515 preserve exact one- and two-window paired results. See the
[repair record](../../IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md).

## Subordinate Source Shape

The public subordinate source starts with the selected AHB-Lite/common-AHB
single-register shape:

```text
(protocol-platform-intent ahb_lite_subordinate
  (profile ahb)
  (source
    (object fsmgen-ahb-lite-subordinate)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-subordinate)
      (page first-public-contract)))
  (ahb-subordinate ahb_lite_subordinate
    (role subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    ...))
```

The generated HDL ports are `HSEL`, `HREADY`, `HADDR`, `HTRANS`, `HWRITE`,
`HSIZE`, `HWDATA`, fixture-local `wait_cycles`, `HREADYOUT`, one-bit `HRESP`,
and `HRDATA`.

Required blocks:

- `clock` and `reset`;
- `control` with `(wait-cycles wait_cycles width 4)`;
- `bus` with the selected AHB-Lite/common-AHB signal bindings;
- `storage` with exactly one register at address `0`;
- `transfer` with selected encodings and response policy.

Selected subordinate widths are fixed in this slice: 32-bit address/write-data
/read-data/register data, 2-bit `HTRANS`, 3-bit `HSIZE`, 4-bit `wait_cycles`,
and one-bit `HRESP`. Unsupported widths, missing required blocks, duplicate
blocks, duplicate names, unsupported fields, and non-AHB profiles fail closed.

## Subordinate Behavior

The selected subordinate accepts an active address phase only when
`!ahb_phase_pending_q && HSEL && HREADY` and `HTRANS` is `NONSEQ` or `SEQ`.
`ahb_phase_capture` banks HADDR, HTRANS, optional HBURST, HWRITE, HSIZE, and
wait_cycles, drives `HREADYOUT=0`, and prevents another acceptance while the
bank is pending. `ahb_phase_hold` preserves not-ready/OKAY/neutral-read-data
until the scheduled transaction consumes the bank once. `IDLE` and `BUSY` are
not captured; the idle/default outputs remain when no rule overrides them:

```text
HREADYOUT = 1
HRESP     = 0
HRDATA    = 0
```

For accepted transfers, the generated `.isf` samples the pending bank into the
transaction, clears its valid bit, repeats a one-cycle wait for the sampled
count, then resolves the transfer. HWDATA is deliberately live data-phase state
rather than an address/control-bank field. This counted form preserves zero
bypass and nonzero delay while keeping generated HDL lint-clean:

- `NONSEQ`, word size, address `0`, and `HWRITE=1` writes `reg_data_q` from
  `HWDATA` and completes with OKAY;
- `NONSEQ`, word size, address `0`, and `HWRITE=0` drives `HRDATA` from
  `reg_data_q` and completes with OKAY;
- the word-only and original byte-lane subordinate sources treat `SEQ` as
  unsupported burst continuation and return ERROR; use
  `ppif/ahb_lite_subordinate_byte_lane_seq.ppif` or
  `ppif/ahb_lite_subordinate_byte_lane_seq.ahb` for the bounded in-word
  byte/halfword `SEQ` policy;
- unsupported sizes return ERROR;
- unmapped addresses return ERROR.

ERROR completion is the selected source-backed two-cycle policy:

```text
cycle 1: HREADYOUT = 0, HRESP = 1, HRDATA = 0
cycle 2: HREADYOUT = 1, HRESP = 1, HRDATA = 0
```

The generated behavior performs no write update on ERROR.

## Alias Diagnostics

`.ahb` is accepted only as the bounded AHB requester, word-only subordinate,
byte-lane/narrow-transfer subordinate, byte-lane in-word `SEQ` subordinate, or
selected aggregate interconnect profile alias, including the selected
aggregate byte-lane variants:

- missing `(profile ...)` is rejected;
- any profile other than `ahb` is rejected as a suffix/profile mismatch;
- any object other than exactly one `(ahb-requester amba_requester ...)`,
  exactly one word-only `(ahb-subordinate ahb_lite_subordinate ...)`, exactly
  one byte-lane/narrow-transfer
  `(ahb-subordinate ahb_lite_subordinate_byte_lane ...)`, exactly one
  byte-lane in-word `SEQ`
  `(ahb-subordinate ahb_lite_subordinate_byte_lane_seq ...)`, or the selected
  aggregate one-requester/one-subordinate or one-requester/two-subordinate
  `(ahb-interconnect ahb_tb ...)` shapes is rejected for this slice;
- mixed endpoint objects outside the selected aggregate shape are rejected;
- duplicate requester, subordinate, or interconnect objects are rejected;
- malformed AHB requester, subordinate, and interconnect fields still use the
  same focused diagnostics as the equivalent `.ppif` source.

Known aliases that have not shipped yet still fail closed. For example, a
temporary `.chi` copy reports a known unsupported alias, while an unrelated
`.foo` suffix reports an unknown source suffix.

## Direct FSM Seeds

The direct requester seed remains available for the lower-level `.fsm` path:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/amba_requester.fsm
./bin/fsmgen --quiet -o generated/amba_requester.sv fsm/amba_requester.fsm
```

It is support-accounted separately:

```text
entry_id: protocol.amba_requester
source_kind: fsm
coverage: direct_root_pipeline_cli
module_name: amba_requester
```

The direct subordinate seed remains available for cycle-level comparison:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
./bin/fsmgen --quiet -o generated/ahb_lite_subordinate.sv fsm/ahb_lite_subordinate.fsm
```

It is support-accounted separately:

```text
entry_id: protocol.ahb_lite_subordinate
source_kind: fsm
coverage: direct_root_pipeline_cli
module_name: ahb_lite_subordinate
```

Before the Q-named `.8` completion-edge repair, this direct seed sampled new
address/control only in `IDLE`. Historical generated-HDL t/1520 presented a
distinct active phase through a not-ready data phase and observed its
acceptance on both kinds of ready completion edge:

```text
successful completion: bus accepts 2, seed captures/completes 1,
                       storage = 0x11111111
final ERROR:           bus accepts 2, seed captures/completes 1,
                       ERROR cycles = 2, storage = 0
```

Before `.8`, `ACCESS` and `ERROR_COMPLETE` returned to `IDLE` without sampling
the phase accepted on that edge. The historical runtime evidence is
[IAL2 AHB Direct Subordinate Pipelined Active-Transfer Runtime Audit](../../IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_RUNTIME_AUDIT.md).

`.5` originally selected direct dispatch through the existing phase registers:

```text
selected NONSEQ -> capture HADDR/HWRITE/HSIZE/wait_cycles -> ACCESS
selected SEQ    -> capture wait_cycles                    -> UNSUPPORTED
IDLE/BUSY/unselected                                      -> IDLE
```

The completing write still consumes live HWDATA from its own data phase; the
next write's HWDATA is presented after the edge. However, `.6` proved that this
internal realization is unsafe: `write_q` is a combinational register-input
mux and the current write enable reads it. Enabling capture of the following
read's `HWRITE=0` immediately changed the current predicate and suppressed the
write, producing `sampled_write=0 storage=00000000`.

The failed D-input dispatcher was fully restored before `.7` selected the smaller correction:
change persistent phase/storage loads to Q-named `<-`. Current completion then
reads the registered Q value while same-edge capture writes a separate
generated `*_next` value. The existing four states dispatch directly with no
pending bank, relaunch state, or extra stall.

A disposable candidate passed success+NONSEQ, final-ERROR+NONSEQ, success+SEQ,
and final-ERROR+IDLE exactly and emitted no Verilator warning. The first D-input-
named bank/relaunch candidate was rejected for cross-state `UNOPTFLAT` and one
avoidable ready-low cycle. `.8` now ships the Q-named contract. Current t/1520
proves:

```text
success + active NONSEQ: accepts/captures/completes = 2/2/2, storage 0x11111111
final ERROR + NONSEQ:    accepts/captures/completes = 2/2/2, errors 2, storage 0xaaaaaaaa
success + active SEQ:    accepts/captures/completes = 2/2/2, errors 2, storage 0x55555555
final ERROR + IDLE:      accepts/captures/completes = 1/1/1, errors 2, storage 0
```

See the historical
[direct contract selection](../../IAL2_AHB_DIRECT_SUBORDINATE_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md),
the [lowering-substrate audit](../../IAL2_AHB_DIRECT_SUBORDINATE_COMPLETION_CAPTURE_SUBSTRATE_AUDIT.md),
the [Q-named contract](../../IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_CONTRACT_SELECTION.md),
and the current [repair record](../../IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_REPAIR.md).

### Direct subordinate output arbitration

The direct seed is now assertion-clean. The bounded repair removes only
access HREADYOUT/HRESP/HRDATA zero writes and unsupported HRESP zero. Emitted
SystemVerilog already initializes all three output muxes to zero, so access
wait/OKAY/zero-data behavior and unsupported wait-cycle OKAY behavior are
unchanged. Unsupported retains explicit HREADYOUT-zero and HRDATA-zero owners;
idle and final ERROR remain fully explicit.

t1520 structurally checks the exact removals, retained owners, zero mux
baselines, and emitted selector identities, then compiles without
`--no-assert`. All four exact Q-named completion-edge scenarios above pass with
every generated selector assertion enabled. The `.svt` harness remains
handwritten regression infrastructure; this repair does not claim generated
VIAL output. See the
[direct-seed arbitration behavior](../../IAL0_AHB_DIRECT_SUBORDINATE_OUTPUT_ARBITRATION_BEHAVIOR.md).

With the fabric, generated endpoint, and direct seed now assertion-clean,
parent selector `.816` selects the now-active generic one-subordinate
[exact-three paired readiness audit](../../tasks/IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.md).
A same-volume disposable candidate passes with all selector assertions and
exact runtime totals 5 presentations / 4 accepted beats / 1 BUSY episode / 3
qualified BUSY events / 1 resumed `SEQ` / storage `0x44332211`. This is audit
feasibility only: no exact-three paired public source ships until a later
contract and implementation are selected. See the
[post-direct selector](../../IAL2_POST_DIRECT_ARBITRATION_NEXT_OWNER_SELECTION.md).

Active audit `.1` now proves that composition directly. The future generic
candidate retains the existing three-child `ahb_tb`, exact three IAL1/four IAL0
artifacts, width-two `3 -> 2 -> 1 -> 0` requester retirement,
subordinate/aggregate `parks_on=[busy]`, and one-hot fabric ownership. Strict
check, normalized semantics, and real read-only MCP agree; assertion-enabled
runtime passes 5 presentations / 4 beats / 1 BUSY episode / 3 qualified BUSY
events / 1 resumed `SEQ` / storage `0x44332211`. Pending `.2` must freeze the
public generic contract and projected 323/364/47 accounting before a separate
implementation. See the
[readiness result](../../IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md).
Clean audit commit `c1f3232f9` now activates that contract selector only; the
generic exact-three paired source remains unshipped during selection.
Contract `.2` now freezes the future generic path
`ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`,
existing 3 IAL1/4 IAL0 architecture, exact support/semantic/read-only-MCP
identity, and assertion-enabled t1531 5/4/1/3/1/`44332211` runtime at projected
323/364/47. Pending `.3` owns implementation, so the path still does not ship
at this checkpoint. See the
[selected contract](../../IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md).
Clean contract commit `547d8102f` now activates `.3` only; the selected generic
path still does not ship during activation.

Implementation `.3` now ships that generic path as a data-only composition
through the existing three-child architecture. It produces exact-three
requester, subordinate, interconnect, and top review artifacts; reports
`before_beat=2`, `beats=3`, child and propagated `parks_on=[busy]`, and one-hot
accepted-subordinate response ownership; and preserves normalized semantic
JSON plus real read-only, shell-disabled MCP parity. Assertion-enabled t/1531
passes five presentations, four completed beats, one BUSY episode, three
qualified BUSY events, one resumed `SEQ`, and final storage `44332211` while
directly checking requester `3 -> 2 -> 1 -> 0` retirement and stable requester,
subordinate, and fabric ownership.

That paired-family checkpoint was 326 protocol fixtures, 367 supported-smoke
plus strict fixtures, and 50 AHB paths split 25 `.ppif` / 25 `.ahb`. The later
generic exact-four requester established 327/368/51 split 26 `.ppif` / 25
`.ahb`; its matching alias now moves current accounting to 328/369/52 split
26/26. The matching
exact-three paired `.ahb` alias ships byte-identically through existing
suffix/lowering machinery; the generic two-subordinate exact-three topology
also ships through existing generators. Focused t/1532 proves alias strict,
schedule, artifact, normalized
semantic, read-only MCP, repository-local output, and HDL-verifier parity
without duplicating t/1531 runtime; t/1533 proves the two-window generic
source and assertion-enabled 10/8/2/6/2 runtime, while t/1534 proves its
byte-identical alias parity without a second simulation. See the
[shipped behavior](../../IAL2_AHB_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md).

Clean behavior commit `00d71114d` returns ownership to the parent frontier and
activates no-behavior selector `.817`. The selector now chooses `.818`,
the byte-identical matching `.ahb` profile alias through existing machinery.
A same-volume candidate preserves exact artifacts, exact-three metadata, BUSY
parking, response ownership, and normalized semantics while removing only
alias-specific residue. Projected accounting is 324/365/48 split 24/24; t1532
will prove alias surfaces and reuse t1531 runtime. Two-subordinate exact-three,
broader BUSY/count/burst/signal work, generic priority, and HIAL/VIAL remain
separate. See the
[post-generic selector](../../IAL2_POST_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md).
Clean selector commit `c70fe528f` activated `.818` only. Implementation `.818`
now ships the alias, support identity, and t/1532 proof at 324/365/48 split
24/24 while preserving the shared t/1531 runtime.
Clean behavior commit `d94f303d8` activates only no-behavior parent selector
`.819` for the next exact roadmap-aligned owner.
Selector `.819` now chooses the proposed two-subordinate exact-three paired
readiness audit. Static, schedule, normalized-semantic, and HDL-verifier probes
pass for a disposable four-child candidate, but the audit must directly prove
real read-only MCP plus assertion-enabled two-command runtime at 10
presentations, 8 beats, 2 BUSY episodes, 6 qualified BUSY events, 2 resumed
`SEQ` events, and final status/control `44332211`/`88776655`. Only then may a
separate contract project 325/366/49 split 25 `.ppif`/24 `.ahb`. See the
[selection record](../../IAL2_POST_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md).
Clean selector commit `e2109a2ba` activates only the selected audit `.1`; the
candidate and projected 325/366/49 boundary remain unshipped during activation.

Audit `.1` now proves the combined boundary directly. Strict check, schedule,
exact 4 IAL1/5 IAL0 artifacts, normalized semantic JSON, real read-only
shell-disabled MCP, and public `--verify-hdl` pass. Verilator compiles with
`--timing` and all generated selector assertions enabled; two mapped `INCR4`
commands complete at exact 10 presentations / 8 beats / 2 BUSY episodes / 6
qualified BUSY events / 2 resumed `SEQ` events / status `44332211` / control
`88776655`, while selected/unselected endpoint state and fabric ownership stay
stable through BUSY. This is a supported-event compiled-model proof, not a
full-SystemVerilog/UVM runtime claim. No lower-layer repair is required.
Proposed contract `.2` remains inactive and the source remains unshipped until
a clean activation. See the
[readiness audit](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md).
Clean audit commit `c2aa63c3e` activates only contract `.2`; the source,
support identity, focused test, and projected 325/366/49 boundary remain
unshipped during activation.
Contract `.2` now freezes the topology-first generic source, existing four-child
architecture, exact 4 IAL1/5 IAL0 artifacts, width-two `3 -> 2 -> 1 -> 0`,
both BUSY-parking contexts, one-hot ownership, exact support identity, and
assertion-enabled t1533 at projected 325/366/49 split 25/24. Proposed `.3`
owns data-only implementation and remains inactive; no source ships in
contract selection. See the
[contract](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md).
Clean contract commit `129d52967` activates only data-only implementation
`.3`; the source, support identity, t1533, and projected 325/366/49 boundary
remain unshipped during activation.
Implementation `.3` now ships the selected generic source and exact support
identity at 325/366/49 split 25 `.ppif`/24 `.ahb`. t1533 proves exact source
delta, 4 IAL1/5 IAL0 artifacts, normalized semantic/read-only MCP parity,
public `--verify-hdl`, and assertion-enabled 10/8/2/6/2 runtime with final
status/control `44332211`/`88776655`. See the
[two-window behavior](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md).
The matching `.ahb` alias is still separate. Proposed parent selector `.820`
may activate only after this implementation commits cleanly and must choose
the next exact roadmap-aligned owner before any further behavior change.
Clean behavior commit `1a73bc65e` activates only `.820`; activation changes
continuity documentation and no public behavior.
Selector `.820` now chooses proposed `.821`, the byte-identical matching
two-window exact-three `.ahb` alias. The exact candidate preserves 4 IAL1/5
IAL0 artifacts, four-child `ahb_tb`, semantic/read-only MCP parity, and public
HDL verification through existing machinery. Projected accounting is
326/367/50 split 25 `.ppif`/25 `.ahb`; focused t1534 will prove alias parity
while t1533 remains shared assertion-enabled runtime. See the
[selection record](../../IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_COMPOSITION_NEXT_OWNER_SELECTION.md).
Clean selector commit `f3585f98d` activates only `.821`; the projected alias,
support identity, t1534, and 326/367/50 boundary remain unshipped in activation.
Implementation `.821` now ships the selected byte-identical alias and exact
support identity at 326/367/50 split 25 `.ppif`/25 `.ahb`. Focused t1534 proves
byte/report/strict/schedule/artifact/normalized-semantic/read-only-MCP/
repository-local-output/HDL-verifier/diagnostic/preservation parity; t1533
remains the shared assertion-enabled 10/8/2/6/2 runtime. See the
[alias behavior](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_THREE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md).
Clean behavior commit `db402fd9d` activates only no-behavior selector `.822`;
activation changes continuity documentation and no public behavior.
Selector `.822` now chooses proposed exact-four requester BUSY counter-width
readiness. The current public normalizer intentionally rejects literal four at
the `2..3` boundary, and the generated requester uses width-two
`ahb_busy_remaining_q`. A separate audit must decide bounded width three versus
reusable minimum-width derivation and prove internal `4 -> 3 -> 2 -> 1 -> 0`,
four qualified BUSY events, stall preservation, and resumed `SEQ` before any
public range or source change. See the
[selection record](../../IAL2_POST_TWO_SUBORDINATE_EXACT_THREE_PAIRED_ALIAS_NEXT_OWNER_SELECTION.md).
Clean selector commit `db0990c9d` activates only exact-four readiness audit
`.1`; activation changes continuity documentation and no public behavior.
The audit now proves the lower layers are ready. A disposable IAL1 variant
changes only actor identity, `ahb_busy_remaining_q` width `2 -> 3`, and its
initializer `3 -> 4`; the existing `>1` decrement and `==1` final handoff lower
and verify unchanged. One assertion-enabled Verilator binary passes
continuous, 32-clock ready-low, and 32-clock grant-low runs, directly observing
`4 -> 3 -> 2 -> 1 -> 0`, four qualified BUSY events, stable stalls, one resumed
pending `SEQ`, four data beats, and zero final counter. Proposed no-behavior
contract `.2` must select minimum unsigned width
`ceil(log2(busy_beats + 1))`, preserving width two for exact two/three and
using width three for exact four, before any public literal-`2..4` source or
normalizer change. See the
[readiness audit](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_INSERTION_READINESS_AUDIT.md).
Clean audit commit `74d91347e` activates only no-behavior contract `.2`;
activation changes continuity documentation and no public behavior.
Contract `.2` selects proposed generic implementation `.3`. The future source
is `ppif/ahb_requester_busy_insert_four.ppif`; normalization accepts only
literal `2..4`, and integer-loop minimum-width lowering keeps exact two/three
at width two while exact four uses width three. The selected t1535 fixture owns
one assertion-enabled binary proving continuous/32-ready-low/32-grant-low
`4 -> 3 -> 2 -> 1 -> 0` plus strict/schedule/artifact/normalized-semantic/real
read-only-MCP/outdir/verifier/preservation parity. Projected accounting is
327 protocol / 368 supported+strict / 51 AHB paths split 26 `.ppif` / 25
`.ahb`. The matching alias remains separate. See the
[contract selection](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_CONTRACT_SELECTION.md).
Clean contract commit `58efc8aff` activates only implementation `.3`;
activation changes continuity documentation and no public behavior.
Implementation `.3` now ships the selected generic exact-four source. Public
normalization accepts literals `2..4`; integer-loop minimum-width lowering
keeps exact-two/three counters at width two and emits width three for
exact-four. Assertion-enabled t1535 proves strict/schedule/artifact/normalized-
semantic/read-only-MCP/verifier parity and continuous/32-ready-low/32-grant-low
exact `4 -> 3 -> 2 -> 1 -> 0` runtime. Current accounting is 327/368/51 split
26 `.ppif` / 25 `.ahb`; the matching exact-four alias remains separate. See
the [shipped behavior](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_BEHAVIOR.md).
Clean generic behavior commit `95bfb7e4b` activates only no-behavior alias
contract selector `.4`. The exact-four `.ahb` alias, support identity, focused
parity test, and projected 328/369/52 boundary remain unshipped during
activation; generic behavior stays fixed at 327/368/51.
Contract `.4` now selects proposed data-only alias implementation `.5`. The
future `ppif/ahb_requester_busy_insert_four.ahb` must be byte-identical, reuse
width-three IAL1/IAL0 and numeric `beats=4`, remove only alias-deferred residue,
and support-account at projected 328/369/52 split 26/26. Focused t1536 owns
strict/schedule/artifact/normalized-semantic/read-only-MCP/verifier parity
without simulation; t1535 remains shared runtime. See the
[alias contract](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md).
Clean contract commit `3370e15cd` activates only data-only alias
implementation `.5`. The alias, support entry, t1536, and 328/369/52 boundary
remain unshipped during activation; generic behavior stays at 327/368/51.
Implementation `.5` now ships the byte-identical exact-four `.ahb` alias.
Focused t1536 proves exact support/report/artifact/normalized-semantic/read-only-
MCP/verifier/diagnostic/preservation parity without a second simulation;
assertion-enabled t1535 remains shared runtime. Current accounting is
328/369/52 split 26 `.ppif` / 26 `.ahb`. See the
[shipped alias behavior](../../IAL2_AHB_REQUESTER_EXACT_FOUR_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md).
The exact-four child tree is complete. Pending parent selector `.823` may
activate only after the clean `.5` behavior commit.
Clean exact-four alias behavior commit `ba2d1c01f` activates parent selector
`.823` without changing behavior. The generic/profile pair remains byte-
identical at 328/369/52 split 26/26; t1536 remains alias parity and t1535
remains the shared assertion-enabled runtime while `.823` selects one next
roadmap owner.
Selector `.823` now chooses proposed one-window exact-four paired-BUSY
readiness audit `.1`. A same-volume candidate strict-checks with unmatched
support, lowers to exact 3 IAL1/4 IAL0 artifacts under `ahb_tb`, preserves
width-three literal-four requester state, one-hot response ownership, and
child/propagated BUSY parking, and passes public `--verify-hdl`. Assertion-
enabled 5 presentations / 4 beats / 1 BUSY episode / 4 qualified BUSY events /
1 resumed `SEQ` / storage `0x44332211` plus real read-only MCP remain for the
audit before any projected 329/370/53 public contract. See the
[selection record](../../IAL2_POST_EXACT_FOUR_REQUESTER_ALIAS_NEXT_OWNER_SELECTION.md).
Clean selector commit `d91c5c7c9` activates only readiness audit `.1` with no
public behavior change. The exact-four paired source remains absent while the
audit owns assertion-enabled aggregate runtime and real read-only MCP proof.
Audit `.1` now proves direct exact-four pairing through strict/artifact/
normalized-semantic/real read-only-MCP/public-verifier surfaces and Verilator
5.046 `--timing` with all assertions. Runtime observes 5 presentations / 4
data beats / 1 BUSY episode / 4 qualified BUSY events / internal
`4->3->2->1->0` / 1 resumed `SEQ` / storage `0x44332211`. No lower-layer
repair is required; pending `.2` owns a separate generic contract projecting
329/370/53 split 27 `.ppif`/26 `.ahb`. See the
[readiness audit](../../IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md).
Clean audit commit `19772adec1` now activates that contract selector only; the
generic exact-four paired source remains unshipped during selection.
Contract `.2` now freezes the future generic path
`ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif`,
existing 3 IAL1/4 IAL0 architecture, exact support/semantic/read-only-MCP
identity, and assertion-enabled t1537 5/4/1/4/1/`44332211` runtime at projected
329/370/53. Pending `.3` owns implementation, so the path still does not ship
at this checkpoint. See the
[selected contract](../../IAL2_AHB_EXACT_FOUR_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md).

After both generated and direct phase repairs, `.808` selected the
[`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT`](../../tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md).
`.1` proved that the pre-repair one-bit procedural flag yielded ten
ready-qualified BUSY edges under continuously-ready operation despite report
`busy_insertion.beats=single`; the prior tests counted only one transition
episode. The repo-local Arm specification also corrected the ready-low premise:
fixed-length BUSY may change to SEQ while ready is low, provided SEQ then holds.
Assertion-enabled disposable candidates prove exact one- and two-event
ownership, including a 32-clock ready-low stretch, with unchanged fields and
four data beats. `.2` now selects exact one-event retirement on
`HGRANT && HREADY && HTRANS == BUSY`, stable pending BUSY through ready/grant
stalls, an `ahb_busy_accept` handoff into existing address-pending ownership,
and no new public syntax or counter. Assertion-enabled public 32-clock
ready-low and grant-low probes both complete with one qualified BUSY event and
four data beats. `.3` now ships that rule/gate repair. t/1498 preserves all
three assertion-enabled requester scenarios, and t/1513-t/1516 count one
qualified BUSY event per generic/alias paired command. See the
[selector record](../../IAL2_POST_AHB_PHASE_REPAIR_NEXT_OWNER_SELECTION.md) and
the [runtime audit](../../IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md),
then the
[selected repair contract](../../IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR_CONTRACT_SELECTION.md)
and [shipped repair](../../IAL2_AHB_REQUESTER_SINGLE_BUSY_EVENT_CARDINALITY_REPAIR.md).
The subsequent
[exact-two contract](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_CONTRACT_SELECTION.md)
selected additive `(busy-beats 2)` behavior, and the
[exact-two behavior record](../../IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_BEHAVIOR.md)
documents its now-shipped generic source and t/1521 runtime proof.

Use the direct seeds when you need to inspect explicit cycle-level state
transitions. Use the public IAL2 sources when you need source identity, source
anchors, generated `.isf` review artifacts, generated `.fsm` review artifacts,
protocol-intent reports, support accounting, and IAL2 diagnostics.

## Residue

The following are not shipped by the current AHB IAL2 surface:

- AHB completer behavior;
- broader multi-subordinate fabrics, multiple requesters/managers,
  arbitration fabrics, bus matrices, programmable/dynamic windows, and broader
  AHB interconnect/decode beyond the selected one-requester/one-subordinate
  static-window `ppif/ahb_interconnect.ppif` /
  `ppif/ahb_interconnect.ahb` source and selected
  one-requester/two-subordinate static-window
  `ppif/ahb_interconnect_two_subordinate.ppif` /
  `ppif/ahb_interconnect_two_subordinate.ahb` source;
- optional/property-gated AHB signals such as `HPROT`, `HMASTLOCK`, and AHB5
  additions on the subordinate side; `HBURST` is shipped only for the selected
  endpoint and aggregate byte-lane HBURST `SEQ` sources;
- HBURST-driven `SEQ` continuation beyond the bounded endpoint and aggregate
  byte-only `WRAP4`/`INCR4` sources and their matching `.ahb` aliases, including
  halfword/word burst `SEQ`, indefinite `INCR`, wider fixed bursts, and
  multi-word/register-bank progression; BUSY-in-burst parking is shipped for the
  `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` endpoint source
  and its matching `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`
  profile alias; aggregate BUSY-parking and additive requester-side exact-one
  plus generic and matching `.ahb` exact-two BUSY insertion now ship. The
  generic and matching `.ahb` one- and two-subordinate exact-two pairings also
  ship. Generic exact-three requester BUSY insertion ships on `.ppif` and its
  matching `.ahb` alias; generic exact-four requester BUSY insertion also
  ships, while its matching alias remains separate. The one- and
  two-subordinate exact-three paired generic/profile forms ship. Counts beyond four,
  policy/runtime/random throttling, and multiple insertion points remain
  outside the shipped surface;
- legacy two-bit `HRESP` compatibility for the subordinate;
- AHB scoreboards;
- full AHB manager behavior beyond the bounded requester;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

The smallest paired exact-two composition now ships: one exact-two requester
plus one HBURST-aware byte-lane subordinate that parks BUSY. The
[runtime readiness audit](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md)
first proved the generated-HDL composition: one BUSY episode retires exactly two
qualified BUSY events while requester pending fields/beat counters,
subordinate continuation/phase/storage, and interconnect ownership remain
stable; the same pending `SEQ` resumes once, four byte data beats complete with
clean status, and final storage is `32'h44332211`. No generator or lower-layer
repair is required. The
[selected public contract](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md)
froze generic source
`ppif/ahb_interconnect_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif`,
the existing three-child artifacts, numeric requester-child `beats=2`,
subordinate/aggregate `parks_on=[busy]`, t1523 runtime, normalized semantic JSON
and real read-only MCP parity. `.3` shipped that source at 317 protocol / 358
supported+strict / 41 AHB paths, reusing the existing generators and normalized
read-only `fsmgen_semantic_introspect` API. The generic two-subordinate
exact-two sibling now also ships through `.8`. See the
[shipped behavior](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md)
and the
[post-requester-multiple-BUSY selection](../../IAL2_POST_REQUESTER_MULTI_BUSY_NEXT_OWNER_SELECTION.md).
Follow-on `.4` selected and `.5` now ships the byte-identical matching `.ahb`
alias. It preserves the same three children, exact review artifacts, numeric
requester `beats=2`, both BUSY-parking projections, and normalized semantic
root `top` through existing alias-only residue cleanup. That alias checkpoint
was 318/359/42, evenly split across twenty-one `.ppif` and twenty-one `.ahb`
sources. Focused t1524 proves strict check, schedule, normalized semantic JSON,
real read-only MCP, artifact, verifier, diagnostic, and preservation parity;
t1523 remains the shared runtime. See the
[selected alias contract](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md)
and [shipped alias behavior](../../IAL2_AHB_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md).

The follow-on
[two-subordinate exact-two readiness audit](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_READINESS_AUDIT.md)
changes no public source or behavior. It substitutes the existing exact-two
requester into the shipped two-subordinate exact-one aggregate and proves the
unchanged four-child `ahb_tb`, status `[0,4)` and control `[4,8)` windows, exact
IAL1/IAL0 artifacts, numeric requester `beats=2`, both child and propagated
`parks_on=[busy]`, and retained one-hot response ownership. Strict check,
normalized semantic JSON, and real read-only MCP introspection agree on module
`ahb_tb`, semantic root `top`, and four children; the disposable source
truthfully reports unmatched support.

Generated HDL runs one `INCR4` byte command through each window. Each command
has exactly two qualified BUSY events, one resumed pending `SEQ`, four data
beats, stable selected and unselected subordinate continuation/storage, stable
interconnect owner bits, no BUSY data completion, and clean status. Final
status/control storage is `32'h44332211`/`32'h88776655`. No generator or
semantic/MCP repair is needed. `.7` selected the public contract and `.8` now
ships it.

Contract leaf `.7` selected the topology-first generic path
`ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif`.
The ordering makes `two_subordinate` the topology and `busy_insert_two` the
requester policy, avoiding a visually ambiguous double-`two`. It reuses the
same four-child architecture and exact `.6` runtime invariants. `.8` now ships
the source through the existing generators. Focused t1525 proves strict check,
schedule/report/residue, exact artifacts, normalized semantic JSON, the real
read-only MCP adapter, HDL verification, and one status/control runtime:
two commands, four qualified BUSY events, two resumed `SEQ` events, eight data
beats, and final `44332211`/`88776655` storage. The generic checkpoint was
319/360/43. Its matching alias established 320/361/44, split twenty-two generic
`.ppif` and twenty-two `.ahb`; the later generic exact-three requester
established 321/362/45 split 23/22, and its alias now moves current support
accounting to 322/363/46 split 23/23. See the
[selected contract](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md)
and [shipped behavior](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_BEHAVIOR.md).

Run the public source through the same semantic and review path as every other
support-accounted IAL2 source:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --outdir generated/ial2-ahb-two-subordinate-exact-two \
  ppif/ahb_interconnect_two_subordinate_requester_busy_insert_two_byte_lane_hburst_seq_busy_park.ppif
```

The MCP tool `fsmgen_semantic_introspect` exposes the same normalized report
through its stable read-only, shell-disabled adapter. This parity is ongoing:
new support-accounted semantics extend the common introspection model instead
of adding feature-specific MCP methods or exposing raw private internals.
`.811` now ships the byte-identical matching `.ahb` alias. Existing suffix
handling preserves the four-child artifacts, windows, exact-two requester,
both BUSY parks, retained owner, normalized semantic root `top`, and
substantive residue while removing only profile-alias residue. Focused t1526
passes strict/schedule/normalized-semantic/real read-only MCP/outdir/verifier/
diagnostic and preservation parity without a second runtime; t1525 remains
shared. See the
[selected alias contract](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_CONTRACT_SELECTION.md)
and [shipped alias behavior](../../IAL2_AHB_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md).

The next-owner
[selector](../../IAL2_POST_TWO_SUBORDINATE_EXACT_TWO_PAIRED_BUSY_ALIAS_NEXT_OWNER_SELECTION.md)
changes no public behavior. Literal `(busy-beats 3)` fits the shipped width-two
requester counter, whose existing qualified rules would retire
`3 -> 2 -> 1 -> 0` and reuse the same pending `SEQ` handoff. Runtime proof is
not inferred from that static fit: proposed
`IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.1` must use a
repo-local disposable candidate and assertion-enabled continuously-ready,
32-clock ready-low, and 32-clock grant-low generated-HDL scenarios. Public
syntax, source/support identities, report wording, alias and composition
cadence, counts above three, policy/runtime/multiple-point insertion, distinct
bus-BUSY status, and broader bursts/signals remain unselected.

The follow-on
[exact-three readiness audit](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_INSERTION_READINESS_AUDIT.md)
now supplies that runtime proof without changing shipped behavior. One
assertion-enabled generated-HDL binary covers continuously-qualified,
32-clock ready-low, and 32-clock grant-low operation. Every run observes one
BUSY episode, exactly three qualified BUSY events, internal counter
`3 -> 2 -> 1 -> 0`, no stall-time count consumption or BUSY data completion,
stable address/control/data/beat ownership, one resumed pending `SEQ`, four
accepted byte `INCR4` beats, and zero final count.

The disposable source also strict-checks, emits the exact candidate IAL1/IAL0
artifacts, reports numeric `busy_insertion.beats=3`, and passes normalized
semantic JSON plus the common read-only shell-disabled MCP adapter. Exact-one,
exact-two, base, and malformed boundaries stay distinct. No lower-layer repair
is required. At that audit checkpoint exact-three was still not public, so
contract leaf `.2` had to freeze syntax, identities, report/residue truth,
support accounting, validation, and generic-before-alias sequencing before
implementation.

The resulting
[exact-three contract](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_CONTRACT_SELECTION.md)
selected `.3`, a generic-first additive source that now ships. Absence of
`busy-beats` remains exact-one; literal values 2 and 3 are the only selected
multiple-event forms, with 0/1/4+/non-literals rejected. The exact-three
source reports numeric `beats=3` and reuses the existing width-two counter,
qualified retirement rules, checker priorities, and pending `SEQ` handoff
unchanged. Its generic checkpoint was 321 protocol / 362 supported+strict /
45 AHB paths split 23 `.ppif`/22 `.ahb`. Focused t1528 directly observes
`3 -> 2 -> 1 -> 0` through continuous, 32-clock ready-low, and 32-clock
grant-low runtime; t1521 directly locks exact-two `2 -> 1 -> 0`. The
matching exact-three `.ahb` alias now ships through `.5`, establishing the
322/363/46 checkpoint split 23/23. Focused t1529 proves exact support, numeric
`beats=3`, existing
suffix-only residue cleanup, artifacts, normalized semantic/read-only MCP, and
verifier parity without a second simulation; t1528 remains the sole runtime
proof. See the
[shipped alias behavior](../../IAL2_AHB_REQUESTER_EXACT_THREE_BUSY_EVENT_PROFILE_ALIAS_BEHAVIOR.md).

The generic AHB requester `.ppif` report keeps historical `.ahb`
profile-alias residue, and the shipped requester `.ahb` alias removes that
stale residue from alias reports. The generic subordinate `.ppif` report keeps
its historical `ahb_subordinate_profile_alias_deferred` residue, and the
shipped subordinate `.ahb` alias removes that stale residue from alias reports.
The generic aggregate interconnect `.ppif` report keeps
`ahb_aggregate_profile_alias_deferred` for source-surface distinction, and its
generated endpoint child reports keep `ahb_profile_alias_deferred` and
`ahb_subordinate_profile_alias_deferred`. The shipped aggregate `.ahb` alias
removes all three stale profile-alias residues from alias report trees.
The generic two-subordinate aggregate `.ppif` report also keeps
`ahb_aggregate_profile_alias_deferred` for source-surface distinction, and its
generated endpoint child reports keep `ahb_profile_alias_deferred` and
`ahb_subordinate_profile_alias_deferred`. The shipped two-subordinate
aggregate `.ahb` alias removes all three stale profile-alias residues from
alias report trees. Both use `ahb_broader_interconnect_decode_deferred` for
the remaining AHB interconnect/decode backlog.
The generic aggregate byte-lane `.ppif` reports keep
`ahb_aggregate_profile_alias_deferred` as a source-surface distinction, and
their generated endpoint child reports keep `ahb_profile_alias_deferred` and
`ahb_subordinate_profile_alias_deferred`. The shipped aggregate byte-lane
`.ahb` aliases remove all three stale profile-alias residues from alias report
trees. The generic aggregate byte-lane `.ppif` reports also remove byte-lane
wording from their optional/interconnect residue because byte/halfword/word
subordinate-owned narrow transfers are now selected through the aggregate.
The generic byte-lane in-word `SEQ` `.ppif` report keeps `.ahb alias exposure`
as a source-surface residue, while the shipped byte-lane in-word `SEQ` `.ahb`
alias removes that wording from its remaining
`ahb_burst_seq_support_deferred` detail.
The generic aggregate byte-lane in-word `SEQ` `.ppif` reports preserve
`composition.byte_lane_propagation`, add `composition.seq_policy_propagation`,
remove aggregate-propagation wording from remaining top-level and child
`ahb_burst_seq_support_deferred` details, and keep matching aggregate `.ahb`
alias exposure as source-surface residue. The shipped aggregate byte-lane
`SEQ` `.ahb` aliases remove aggregate/requester/subordinate profile-alias
residue and child `.ahb alias exposure` wording from alias report trees while
preserving HBURST length/wrap, BUSY-in-burst, multi-word/register-bank,
broader backend/protocol, and VHDL residue explicitly.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.762` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.763`, a no-behavior public contract
selection for a new endpoint-only HBURST-aware byte-lane `SEQ` source family.
The requester already emits HBURST and wrap/increment progression, but the
selected byte-lane `SEQ` subordinate bus has no HBURST binding and candidate
`(burst HBURST width 3)` subordinate syntax failed before `.764`. Aggregate
byte-lane `SEQ` interconnects still have no subordinate-local HBURST
forwarding, so aggregate propagation and matching `.ahb` alias exposure remain
later owners.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.763` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.764`, direct implementation of
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`. The selected generic
endpoint contract adds subordinate `(burst HBURST width 3)` binding and
`(seq-policy hburst-in-word-progressive)`, then supports byte-only `WRAP4` and
`INCR4` `SEQ` inside one 32-bit register word. `SINGLE` remains non-SEQ only,
and wider/indefinite bursts, halfword/word burst `SEQ`, BUSY parking,
aggregate propagation, matching `.ahb` aliases, broader AHB, backend variants,
AXI/APB, and VHDL remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.764` shipped that source as generic
`.ppif` only. Generated review artifacts and HDL now expose `HBURST`, reports
include `bindings.bus.burst` and
`transfer.seq_policy.mode = hburst_in_word_progressive`, and the remaining
`ahb_burst_seq_support_deferred` text is narrowed to unsupported burst shapes,
BUSY parking, aggregate propagation, matching `.ahb` alias exposure, broader
backend/protocol behavior, and VHDL.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.765` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.766`, direct implementation of the
matching public
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb` profile alias.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.766` shipped that alias with the same
generated review artifacts and HBURST/SEQ report metadata, support identity
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq`, source kind
`ial2_profile_alias`, and alias-only removal of `.ahb alias exposure` from the
remaining `ahb_burst_seq_support_deferred` detail. Aggregate HBURST
propagation, BUSY parking, halfword/word burst `SEQ`, wider or indefinite
bursts, multi-word/register-bank progression, optional signals, broader AHB,
backend variants, AXI/APB, and VHDL remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.767` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.768`, a no-behavior readiness audit for
bounded aggregate AHB HBURST propagation. Current aggregate byte-lane `SEQ`
interconnect sources strict-check as shipped and expose requester/global
`HBURST`, but their child subordinates remain on the older
`in_word_progressive` endpoint contract with no subordinate-local burst
binding. Temporary one- and two-subordinate HBURST aggregate candidates lowered
far enough to show child `hburst_in_word_progressive` reports, then failed
strict checks closed because `regs.HBURST_REGS` or `status.HBURST_STATUS`
was left unconnected by the composition top. Aggregate HBURST forwarding,
matching aggregate aliases, BUSY parking, halfword/word burst `SEQ`, wider or
indefinite bursts, multi-word/register-bank progression, optional signals,
broader AHB, backend variants, AXI/APB, and VHDL remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.768` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.769`, a no-behavior public contract
selection for a combined bounded generic `.ppif` aggregate HBURST-aware
byte-lane `SEQ` propagation family. Likely source names are
`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`. `.769`
must pin exact paths, child object names, subordinate-local HBURST names,
support identities, coverage keys, child HBURST fanout policy, aggregate
report schema, residue movement, tests, docs, and later matching aggregate
`.ahb` alias sequencing before implementation.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.769` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.770`, direct implementation of the
combined bounded generic `.ppif` aggregate HBURST-aware byte-lane `SEQ`
propagation family. The selected sources are
`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`,
support-accounted as `intent.ppif_ahb_interconnect_byte_lane_hburst_seq` and
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq`.
Requester/global `HBURST` must fan out directly to child-local
`HBURST_REGS`, `HBURST_STATUS`, and `HBURST_CONTROL` as applicable, while the
aggregate report reuses `composition.seq_policy_propagation` with mode
`subordinate_owned_hburst_in_word_seq_policy`. Matching aggregate `.ahb`
aliases, BUSY parking, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, broader AHB, backend variants, AXI/APB,
and VHDL remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.770` shipped
`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`. They
support-account as `intent.ppif_ahb_interconnect_byte_lane_hburst_seq` and
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq`, lower
through generated HBURST-aware subordinate review artifacts, select HDL entry
`ahb_tb`, forward requester/global `HBURST` directly to child-local
`HBURST_REGS`, `HBURST_STATUS`, and `HBURST_CONTROL`, preserve
`composition.byte_lane_propagation`, and reuse
`composition.seq_policy_propagation` with
`subordinate_owned_hburst_in_word_seq_policy`. The same slice selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.771`, a no-behavior public contract
selection for matching aggregate HBURST-aware `.ahb` aliases. Matching
aggregate `.ahb` aliases, BUSY parking, halfword/word burst `SEQ`, wider or
indefinite bursts, multi-word/register-bank progression, broader AHB, backend
variants, AXI/APB, and VHDL remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.771` then selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.772`, direct implementation of the matching
aggregate HBURST-aware `.ahb` profile aliases
`ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`. They must
mirror the shipped generic `.ppif` sources and support-account as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq`
with source kind `ial2_profile_alias`, preserving HDL entry `ahb_tb`,
`composition.byte_lane_propagation`, and `composition.seq_policy_propagation`
mode `subordinate_owned_hburst_in_word_seq_policy`. Reserved `.ahb` label
probes confirm the existing suffix-keyed profile-alias suppression removes the
aggregate and embedded-child alias residue with no adapter change, so `.772` is
data-only. BUSY parking, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, broader AHB, backend variants, AXI/APB,
and VHDL remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.772` shipped
`ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` and
`ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`,
support-accounted as
`intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq`
with `source_kind: ial2_profile_alias`. The aliases are byte-identical mirrors
of the generic `.ppif` sources, keep HDL entry `ahb_tb`,
`composition.byte_lane_propagation`, and
`composition.seq_policy_propagation` mode
`subordinate_owned_hburst_in_word_seq_policy`, and drop the aggregate and
embedded-child profile-alias residue while the generic `.ppif` reports keep it.
Focused coverage is `t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t`.
BUSY parking, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, broader AHB, backend variants, AXI/APB,
and VHDL remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.773` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.774`, a no-behavior readiness audit for
bounded AHB subordinate **BUSY-in-burst parking** — holding the in-word `SEQ`
burst context across an `HTRANS = BUSY` beat rather than clearing it. This is the
smallest next burst-`SEQ` increment after the byte-only `WRAP4`/`INCR4` in-word
HBURST `SEQ` endpoint and aggregate `.ppif`/`.ahb` family: the endpoint
burst-context registers already exist for the shipped path, BUSY is currently
folded into the burst-history clear alongside IDLE (the `ahb_seq_idle_clear`
concurrent rule fires on `(| (== HTRANS idle) (== HTRANS busy))`, and the endpoint
`SEQ`-policy report lists `busy` under `clears_on`), and the endpoint/aggregate
residue already defer BUSY-in-burst continuation/handling. `.774` audits the
clear-versus-park decode change, fail-closed behavior for a drifting BUSY beat,
report/residue narrowing, source-stem/`.ahb`-alias sequencing, and tests before
any behavior changes. Halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, and optional/property-gated
`HPROT`/`HMASTLOCK` signals were weighed as larger increments and remain
deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.774` audited BUSY-parking readiness and
selected `IAL2-FEATURE-COMPLETENESS-FRONTIER.775`, a public contract selection
for the endpoint BUSY-parking source. The burst-context registers already exist,
so the minimal behavior delta is stopping the `ahb_seq_idle_clear` rule
from firing on BUSY — because unassigned registers hold their value, the burst
context is preserved across the parked beat and the following `SEQ` beat resumes
from the parked address/beat count. The endpoint source declares
`(ignored-transfer busy)`, so a distinct "busy parks" declaration is needed. The
shipped requester never drives `HTRANS = BUSY` on the bus (its
`local_status.busy` output is an internal "transaction in progress" flag, not
the AHB bus code), so BUSY-parking is a subordinate-side capability verified by
driving `HTRANS = BUSY` stimulus into the standalone subordinate; requester-side
BUSY insertion stays deferred. `.775` pins the source path/identity, in-place
widening versus a new additive `*_busy_park` source stem, the `.ppif` "busy
parks" keyword, the fail-closed policy for a drifting BUSY beat, and the
report/residue changes before any behavior changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.775` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.776` and pinned the contract. The
BUSY-parking behavior ships as a **new additive source stem**
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`, preserving the
shipped `ahb_lite_subordinate_byte_lane_hburst_seq` source and its tests. The
source replaces `(ignored-transfer busy)` with the new `(parked-transfer busy)`
vocabulary, parallel to `(ignored-transfer idle)`. Gated on that parked-BUSY
flag, the generated subordinate holds the burst context across a BUSY beat (the
`ahb_seq_idle_clear` concurrent rule fires only on IDLE, so the unassigned `seq_*`
registers keep their values), the `SEQ`-policy report drops `busy` from
`clears_on` and adds `parks_on: [busy]`, and the burst-`SEQ` residue drops
BUSY-in-burst continuation. No BUSY-beat drift check is added: the existing
`SEQ`-beat validation already fail-closes a resume whose address, size, write,
or burst mode does not match the armed burst. `.776` ships the source,
parser/generator/report/residue changes, support accounting, and a focused
`NONSEQ → SEQ → BUSY → SEQ` test before any further behavior changes.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.776` shipped
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`, the bounded
endpoint AHB subordinate byte-lane HBURST `WRAP4`/`INCR4` in-word `SEQ` source
with BUSY-in-burst parking, support-accounted as
`intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park` with coverage
`ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`
(`source_kind: ppif`). The source declares `(ignored-transfer idle)` and
`(parked-transfer busy)`; the new `parked-transfer` clause makes the generator
gate BUSY out of the `ahb_seq_idle_clear` rule so it fires on IDLE only.
Because the generated FSM leaves the `seq_*` registers unassigned during a BUSY
beat, the in-word burst context (`seq_valid_q`, `seq_expected_addr_q`,
`seq_size_q`, `seq_write_q`, `seq_hburst_q`, `seq_beats_remaining_q`) holds
across the BUSY beat, and the following `SEQ` beat resumes through the same
`seq_ok_base` validation that fail-closes a resume whose address, size, write, or
burst mode drifts from the armed burst. The generated `SEQ`-policy report drops
`busy` from `clears_on` and adds `parks_on: [busy]`, and the burst-`SEQ` residue
records shipped BUSY-in-burst parking while keeping halfword/word burst `SEQ`,
wider or indefinite bursts, multi-word/register-bank progression, the matching
`.ahb` alias, aggregate BUSY-parking, and requester-side BUSY insertion deferred
at that slice's closeout. The independent requester BUSY-insertion source now
ships as described above.
The shipped `ahb_lite_subordinate_byte_lane_hburst_seq` source is unchanged (it
still clears the burst history on BUSY). Focused coverage is
`t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t`.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.777` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.778`, direct implementation of the matching
endpoint BUSY-park `.ahb` profile alias
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`. It mirrors the
shipped generic BUSY-park `.ppif` source and will support-account as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park` (coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
`source_kind: ial2_profile_alias`), preserving the generated
`ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf`/`.fsm` review
artifacts, the HDL module, and the `parks_on: [busy]` / `clears_on` BUSY-park
report shape. A reserved `.ahb`-label probe confirms the alias strict-checks and
drops `ahb_subordinate_profile_alias_deferred` plus the `.ahb alias exposure`
residue wording through the existing suffix-keyed profile-alias suppression with
no adapter change, so `.778` is data-only: it adds the alias fixture, its
`RegressionCorpus` entry, focused
`t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t`, the
`t/248` corpus bump, the `t/297` manifest, and docs.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.778` shipped
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb`, a byte-identical
mirror of the generic BUSY-park `.ppif` source, support-accounted as
`intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park` with
coverage
`ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`
(`source_kind: ial2_profile_alias`). The alias strict-checks, generates the same
`ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf`/`.fsm` review artifacts
and HDL module as the generic source, and preserves the distinctive BUSY-park
report (`transfer.seq_policy.parks_on: [busy]` and the BUSY-free `clears_on`). The
alias report removes `ahb_subordinate_profile_alias_deferred` and the `.ahb alias
exposure` residue wording through the existing suffix-keyed profile-alias
suppression (no adapter change), while the generic `.ppif` report keeps that
source-surface residue. Focused coverage is
`t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t`;
`t/248` moves to 293 protocol / 334 total supported-smoke entries. Aggregate
BUSY-parking, requester-side BUSY insertion, and larger burst work were deferred
at that slice's closeout; the additive requester source now ships the bounded
single-BUSY subset independently.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.779` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.780`, a no-behavior readiness audit for
bounded aggregate AHB BUSY-parking propagation — holding a child subordinate's
in-word HBURST `SEQ` burst context across an `HTRANS = BUSY` beat inside the
interconnect aggregate propagation, mirroring the shipped endpoint BUSY-park.
This is the next step in the endpoint → aggregate cadence that already shipped
byte-lane, byte-lane `SEQ`, and HBURST-aware byte-lane `SEQ` propagation: the
endpoint BUSY-park residue now defers `aggregate propagation`, while the
aggregate residue still lists `BUSY-in-burst handling` first among its remaining
burst work. The mechanism is bounded — the interconnect
`_seq_policy_propagation_report` clones each child's `seq_policy` verbatim, so a
child subordinate declared with `(parked-transfer busy)` automatically forwards
its `transfer.seq_policy.parks_on: [busy]` and BUSY-free `clears_on` into the
aggregate `composition.seq_policy_propagation` report; the behavior delta is new
aggregate stems (`ahb_interconnect_byte_lane_hburst_seq_busy_park` and its
two-subordinate sibling) whose child transfer uses `(parked-transfer busy)`,
plus narrowing the aggregate residue. `.780` audits whether that owner can
implement directly or needs a public contract selection first. Requester-side
BUSY insertion (the requester never drives bus `HTRANS = BUSY`), halfword/word
burst `SEQ`, wider or indefinite bursts, multi-word/register-bank progression,
and optional/property-gated AHB signals are larger and remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.780` audits that aggregate BUSY-park
propagation is ready and selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.781`, a
public contract selection. The aggregate is more ready than the endpoint was
before its own contract selection: the interconnect composes child subordinate
FSMs by calling `AhbSubordinate->generate` per child and composing the results
into an `(?fsmc:...)` top, and `_seq_policy_propagation_report` clones each child
`seq_policy` verbatim. So a child subordinate declared with `(parked-transfer
busy)` parks BUSY through the shipped endpoint machinery with no interconnect
generator, parser, or report change, its `transfer.seq_policy.parks_on: [busy]`
and BUSY-free `clears_on` surface on `composition.seq_policy_propagation`
unchanged, and the child `seq_ok_base` fail-closed path carries through the
composition. The bounded behavior delta is new aggregate stems
(`ahb_interconnect_byte_lane_hburst_seq_busy_park` and, if included, its
two-subordinate sibling) whose child transfer uses `(parked-transfer busy)`, plus
narrowing the aggregate residue. `.781` settles the stem name(s), whether one or
both ship first, per-stem support identity / coverage key / source kind /
generated artifact names, residue-narrowing scope, focused test shape, and the
later matching aggregate `.ahb` alias. Requester-side BUSY insertion,
halfword/word burst `SEQ`, wider or indefinite bursts, multi-word/register-bank
progression, and optional/property-gated AHB signals remain deferred.

`IAL2-FEATURE-COMPLETENESS-FRONTIER.781` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.782` and pins the aggregate BUSY-park
contract. `.782` ships both stems (mirroring `.770`):
`ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif` (support identity
`intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park`, three composed
children) and `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`
(four composed children), each a copy of the shipped aggregate HBURST `SEQ`
source with the inlined child subordinate transfer `(ignored-transfer busy)`
replaced by `(parked-transfer busy)`. The behavior delta is source data plus
residue narrowing only — no interconnect generator, parser, or report change,
because the `(parked-transfer busy)` vocabulary is child-role-shared and
`_seq_policy_propagation_report` clones each child `seq_policy` verbatim, so each
child entry and `composition.seq_policy_propagation` report
`transfer.seq_policy.parks_on: [busy]` and the BUSY-free `clears_on`
automatically. `.782` narrows only the aggregate HBURST residue (drops
`BUSY-in-burst handling`), adds focused
`t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t`, moves `t/248` to
295 protocol / 336 total, and preserves the shipped aggregate HBURST `SEQ`
sources and `t/1492`/`t/1493`. The matching aggregate `.ahb` aliases,
requester-side BUSY insertion, and larger burst work were deferred at that
slice's closeout; both the aliases and the additive bounded requester
single-BUSY source now ship independently.

## Boundary-Free Active Address Phases

The generated AHB family now supports a deliberately bounded, depth-one active
address-phase pipeline. The subordinate holds exactly one bus-accepted
address/control phase:

```text
empty bank + HSEL && HREADY && active HTRANS
  -> capture HADDR/HTRANS/(HBURST)/HWRITE/HSIZE/wait_cycles
  -> drive HREADYOUT low for that phase's data cycle
  -> consume the bank once through the existing access policy
  -> stall before another address acceptance while occupied
```

`HWDATA` is not captured with address/control; it is live data-phase state and
is held while ready is low. A final ERROR ready edge captures a selected active
phase for later independent evaluation, while `IDLE` cancels it. The schedule
report advertises `phase_pipeline.mode =
one_accepted_next_address_control`, capacity one, and overflow policy
`stall_before_another_acceptance`.

The generated requester separately owns address, data, and captured response:
address acceptance retires HTRANS to IDLE, and the later data-completion edge
captures HRESP/HRDATA. The generated interconnect retains one one-hot accepted
subordinate as HREADY/HRESP/HRDATA owner until completion; a mapped acceptance
on the same edge replaces that owner atomically. Without those paired roles,
correct requester retirement would make the interconnect mux the response from
the wrong current address phase.

Generated-HDL t/1519 proves two acceptances, captures, and completions for
boundary-free `NONSEQ(0) -> SEQ(1)`, producing storage `32'h00002211`. It also
proves exactly two ERROR cycles and active-continuation capture after final
ERROR, plus exactly two ERROR cycles and no continuation/storage effect for
final ERROR followed by IDLE. t/1513 and t/1515 preserve the one- and
two-subordinate paired results.

See the [repair record](../../IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md) and
the preceding [contract selection](../../IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_CONTRACT_SELECTION.md).
This is protocol bookkeeping with capacity one, not a general outstanding
queue, multi-manager fabric, or activation of the protocol-neutral
transaction-layer horizon.

That repaired contract applies to generated public IAL2 roles. The separate
direct `fsm/ahb_lite_subordinate.fsm` seed uses a different but equivalent
capacity-one realization: `.8` ships Q-named `<-` loads and direct four-state
completion dispatch without pending/relaunch. t/1520 proves exact retention.

## Validation Used For This Chapter

This chapter was validated with:

```bash
prove -v t/1473-ial2-ahb-requester.t
prove -v t/1474-ial2-ahb-profile-alias.t
prove -v t/1475-ial2-ahb-subordinate.t
prove -v t/1476-isf-output-default-reset.t
prove -v t/1477-ial2-ahb-subordinate-profile-alias.t
prove -v t/1478-ial2-ahb-interconnect.t
prove -v t/1479-ial2-ahb-interconnect-profile-alias.t
prove -v t/1480-ial2-ahb-interconnect-two-subordinate.t
prove -v t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t
prove -v t/1482-ial2-ahb-subordinate-byte-lane.t
prove -v t/1483-ial2-ahb-subordinate-byte-lane-profile-alias.t
prove -v t/1484-ial2-ahb-interconnect-byte-lane.t
prove -v t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
prove -v t/1486-ial2-ahb-subordinate-byte-lane-seq.t
prove -v t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t
prove -v t/1488-ial2-ahb-interconnect-byte-lane-seq.t
prove -v t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t
prove -v t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t
prove -v t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t
prove -v t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t
prove -v t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t
prove -v t/1519-ial2-ahb-pipelined-active-transfer-audit.t
prove -v t/1520-ahb-direct-subordinate-pipelined-active-transfer-audit.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --strict --check --json fsm/ahb_lite_subordinate.fsm
```

The requester `.ppif` and `.ahb` probes passed and generated
`amba_requester.isf`, `amba_requester.fsm`, and HDL module `amba_requester`.
The subordinate `.ppif` and `.ahb` probes passed and generated
`ahb_lite_subordinate.isf`, `ahb_lite_subordinate.fsm`, and HDL module
`ahb_lite_subordinate`. The generated subordinate artifacts preserve
`HREADYOUT`/`HRESP`/`HRDATA` reset/default metadata, selected register read
and write behavior, unsupported `SEQ` routing, unsupported size/address
ERROR routing, support accounting as `intent.ppif_ahb_lite_subordinate` for
the generic source, and support accounting as
`intent.ahb_profile_alias_subordinate` for the alias source. The interconnect
`.ppif` and `.ahb` probes passed and generated `amba_requester.isf`,
`ahb_lite_subordinate.isf`, `ahb_interconnect.isf`, `amba_requester.fsm`,
`ahb_lite_subordinate.fsm`, `ahb_interconnect.fsm`, aggregate `ahb_tb.fsm`,
and HDL module `ahb_tb`, support-accounted as `intent.ppif_ahb_interconnect`
for the generic source and `intent.ahb_profile_alias_interconnect` for the
alias source.
The two-subordinate `.ppif` probe passed and generated `amba_requester.isf`,
`ahb_status_subordinate.isf`, `ahb_control_subordinate.isf`,
`ahb_interconnect.isf`, `amba_requester.fsm`, `ahb_status_subordinate.fsm`,
`ahb_control_subordinate.fsm`, `ahb_interconnect.fsm`, aggregate
`ahb_tb.fsm`, and HDL module `ahb_tb`, support-accounted as
`intent.ppif_ahb_interconnect_two_subordinate`.
The matching two-subordinate `.ahb` alias probe passed with the same generated
review artifacts and HDL module, support-accounted as
`intent.ahb_profile_alias_interconnect_two_subordinate`.
The aggregate byte-lane `.ppif` probes passed and generated the same aggregate
top with byte-lane subordinate review artifacts: the one-subordinate source
emits `ahb_lite_subordinate_byte_lane.isf` /
`ahb_lite_subordinate_byte_lane.fsm`, and the two-subordinate source emits
`ahb_status_subordinate_byte_lane.isf`,
`ahb_control_subordinate_byte_lane.isf`,
`ahb_status_subordinate_byte_lane.fsm`, and
`ahb_control_subordinate_byte_lane.fsm`. Both schedules report
`composition.byte_lane_propagation` and keep the selected HDL module
`ahb_tb`.
The matching aggregate byte-lane `.ahb` alias probes passed with the same
generated review artifacts and HDL module, support-accounted as
`intent.ahb_profile_alias_interconnect_byte_lane` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane`, preserving
`composition.byte_lane_propagation` while removing
`ahb_aggregate_profile_alias_deferred`, `ahb_profile_alias_deferred`, and
`ahb_subordinate_profile_alias_deferred` from alias report trees.
The generic byte-lane in-word `SEQ` `.ppif` and matching `.ahb` alias probes
passed and generated `ahb_lite_subordinate_byte_lane_seq.isf`,
`ahb_lite_subordinate_byte_lane_seq.fsm`, and HDL module
`ahb_lite_subordinate_byte_lane_seq`. The generic source support-accounts as
`intent.ppif_ahb_lite_subordinate_byte_lane_seq`; the alias support-accounts
as `intent.ahb_profile_alias_subordinate_byte_lane_seq`, preserves
`narrow_transfer_policy` and `transfer.seq_policy`, removes endpoint
profile-alias residue, and no longer lists `.ahb alias exposure` in the
remaining `ahb_burst_seq_support_deferred` detail.
The generic aggregate byte-lane in-word `SEQ` `.ppif` and matching `.ahb`
alias probes passed and generated aggregate `ahb_tb` review artifacts with
byte-lane `SEQ` subordinate children. The generic sources support-account as
`intent.ppif_ahb_interconnect_byte_lane_seq` and
`intent.ppif_ahb_interconnect_two_subordinate_byte_lane_seq`; the aliases
support-account as `intent.ahb_profile_alias_interconnect_byte_lane_seq` and
`intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq`.
Both source surfaces preserve `composition.byte_lane_propagation` and
`composition.seq_policy_propagation`; the aliases additionally remove child
`.ahb alias exposure` wording while generic `.ppif` reports keep it as
source-surface residue.
