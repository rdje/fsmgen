# AHB IAL2 Current Boundary

FSMGen ships thirty-six public bounded AHB IAL2 entrypoints today:

```text
ppif/ahb_requester.ppif
ppif/ahb_requester_busy_insert.ppif
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
ppif/ahb_requester.ahb
ppif/ahb_requester_busy_insert.ahb
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
```

The `.ppif` sources are generic Protocol/Platform Intent files. They cover the
bounded AHB requester, the bounded word-only AHB-Lite/common-AHB subordinate,
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
an `HTRANS=BUSY` beat instead of clearing it), plus the first paired aggregate
whose requester inserts that BUSY and whose subordinate parks it.
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
BUSY-parking-subordinate aggregate,
`(ahb-interconnect ahb_tb ...)`.

All public AHB IAL2 sources lower through generated review artifacts before
HDL:

```text
ppif/ahb_requester.ppif          -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
ppif/ahb_requester_busy_insert.ppif -> amba_requester_busy_insert.isf -> amba_requester_busy_insert.fsm -> HDL module amba_requester_busy_insert
ppif/ahb_requester.ahb           -> amba_requester.isf -> amba_requester.fsm -> HDL module amba_requester
ppif/ahb_requester_busy_insert.ahb -> amba_requester_busy_insert.isf -> amba_requester_busy_insert.fsm -> HDL module amba_requester_busy_insert
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
```

FSMGen also keeps direct lower-layer `.fsm` seeds:

```text
fsm/amba_requester.fsm
fsm/ahb_lite_subordinate.fsm
```

These direct seeds remain useful cycle-level coverage, but they are not IAL2
and do not produce generated `.isf` or generated `.fsm` review artifacts.

## Mode Map

| Mode | Current source | Boundary |
| --- | --- | --- |
| Guided mode | The thirty-six public AHB sources listed above, including the paired `.ppif`/`.ahb` source pair | Bounded requester/subordinate/interconnect sources, selected byte-lane and HBURST `SEQ` endpoint/aggregate families, selected BUSY-parking families and aliases, and the paired BUSY-inserting-requester/BUSY-parking-subordinate aggregate through both public source surfaces. |
| More-control mode | The same bounded IAL2 sources plus direct `fsm/amba_requester.fsm` and `fsm/ahb_lite_subordinate.fsm` for cycle-level comparison | Requester knobs are exposed as `local-command`, `local-status`, `bus`, `burst`, `transfer`, and `response` clauses. Subordinate knobs are exposed as `control`, `bus`, one-register `storage`, and `transfer` clauses, including selected byte/halfword/word `supported-size`, `lane-order`, narrow read/write, unaligned/crossing policy clauses, the selected `(seq-policy in-word-progressive)` clause on the generic byte-lane `SEQ` source and matching `.ahb` alias, and the selected `(burst HBURST width 3)` plus `(seq-policy hburst-in-word-progressive)` clauses on the generic and matching `.ahb` HBURST-aware endpoint byte-lane `SEQ` sources and selected generic aggregate HBURST-aware byte-lane `SEQ` sources. Interconnect knobs are exposed as `children`, one or two static `address-map` windows, `decode`, and `wiring` clauses. |
| Raw/full-control mode | Direct `.fsm` seeds and the generated `.isf`/`.fsm` review artifacts emitted from IAL2 | AHB completer behavior, broader AHB interconnect/decode beyond the selected one-requester/one-subordinate static-window `.ppif`/`.ahb` sources and selected one-requester/two-subordinate static-window `.ppif`/`.ahb` sources, matching aggregate HBURST `.ahb` aliases, optional signals beyond the shipped HBURST endpoint binding, wider/indefinite HBURST continuation beyond the bounded byte-only `WRAP4`/`INCR4` endpoint and aggregate sources, full manager behavior, direct backend behavior, verification-output generation, backend-language variants, and VHDL remain future task-tree-owned work. |

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
accesses, and multi-word/register-bank progression. This generic source does
now has a matching endpoint `.ahb` alias. Aggregate HBURST propagation is
shipped through the selected generic aggregate `.ppif` sources later in this
chapter; matching aggregate HBURST `.ahb` aliases remain deferred.

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

The generated IAL1 requester uses an internal completion bit for transaction
completion, so the public `done` status output remains an ordinary status
drive:

```text
(storage
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
- transfer activity is gated by `HGRANT`;
- response advancement is gated by `HREADY`;
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
present one held AHB BUSY transfer before a selected later beat:

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
advancement. The following presentation is the same pending beat as `SEQ`; an
`INCR4` therefore presents `NONSEQ(0) → SEQ(1) → BUSY(2 held) → SEQ(2 resumed)
→ SEQ(3)` while accepting exactly four data beats.

`busy-before-beat` is a literal in `1..15` and requires `(busy 2'b01)`.
Malformed, missing, duplicate, or out-of-range declarations fail closed. The
report's `busy_insertion` block records generated behavior, the BUSY encoding,
the insertion index, and the `single` bound. The source generates
`amba_requester_busy_insert.isf`, then `.fsm`, then HDL module
`amba_requester_busy_insert`; it is support-accounted as
`intent.ppif_ahb_requester_busy_insert`. The base requester and its `.ahb` alias
remain BUSY-insertion free. The matching additive alias
`ppif/ahb_requester_busy_insert.ahb` now ships with identical generated
behavior. Runtime/policy-driven or multi-beat BUSY throttling, a separate local
bus-BUSY status output, and two-subordinate paired behavior remain deferred.
The one-subordinate paired generic source and alias are described below.

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
two-subordinate variants remain deferred.

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
Generic `.ppif` ships first; matching `.ahb` and the two-subordinate sibling
remain deferred.

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

That runtime proof also tightened the common AHB endpoint phase contract. A
requester waits one clock after presenting an active transfer and holds it
until data-phase `HREADY`. A subordinate claims one active presentation in
`ahb_access_active_q`, immediately drives `HREADYOUT=0`, samples it once, and
releases ownership at an unselected, `IDLE`, or `BUSY` boundary. Continuation
clearing is a concurrent `ahb_seq_idle_clear` rule rather than a competing
transaction. Sampled `wait_cycles` use a counted repetition of one-cycle waits,
which preserves zero/nonzero timing and is clean under `--verify-hdl`.

The shipped requester produces the transfer boundary required by that bounded
ownership contract. True boundary-free pipelined active transfers are not yet
claimed. The interconnect child instance is HDL-safe `fabric`; a zero-base
decode emits only its upper bound, while nonzero-base windows retain both
bounds. The two-subordinate paired sibling and broader BUSY/burst policies
remain deferred.

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

The selected subordinate transaction begins only when
`!ahb_access_active_q && HSEL && HREADY` and `HTRANS` is `NONSEQ` or `SEQ`.
A priority admission rule claims that presentation, drives `HREADYOUT=0`, and
prevents the same held transfer from being admitted twice. Ownership releases
at an unselected, `IDLE`, or `BUSY` boundary. `IDLE` and `BUSY` are ignored by
not starting the transaction; the idle/default outputs remain when admission
does not override them:

```text
HREADYOUT = 1
HRESP     = 0
HRDATA    = 0
```

For accepted transfers, the generated `.isf` samples `HADDR`, `HWRITE`,
`HSIZE`, `HTRANS`, and `wait_cycles`, drives the data phase pending state with
`HREADYOUT=0`, repeats a one-cycle wait for the sampled count, then resolves
the transfer. This counted form preserves zero bypass and nonzero delay while
keeping generated HDL lint-clean:

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
  profile alias; aggregate BUSY-parking and additive requester-side single-BUSY
  insertion now ship independently, while broader BUSY policy/throttling
  remains deferred;
- legacy two-bit `HRESP` compatibility for the subordinate;
- AHB scoreboards;
- full AHB manager behavior beyond the bounded requester;
- direct IAL2-to-IAL0 or IAL2-to-HDL lowering;
- verification-output generation;
- backend-language variants;
- VHDL behavior.

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
