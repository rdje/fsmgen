# IAL2 AHB Byte-Lane/Narrow-Transfer Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.736`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.736` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.737`, direct implementation of the first
bounded public AHB byte-lane/narrow-transfer subordinate source.

The selected source path is:

```text
ppif/ahb_lite_subordinate_byte_lane.ppif
```

The selected implementation must preserve the existing word-only subordinate
sources:

```text
ppif/ahb_lite_subordinate.ppif
ppif/ahb_lite_subordinate.ahb
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Selected Public Source

The future source is a new generic `.ppif` subordinate source:

```text
(protocol-platform-intent ahb_lite_subordinate_byte_lane
  (profile ahb)
  (source
    (object fsmgen-ahb-lite-subordinate-byte-lane)
    (anchor
      (document ARM-AMBA-AHB-IHI0033-C-2021-09)
      (section bounded-ahb-lite-subordinate-byte-lane)
      (page first-public-contract)))
  (ahb-subordinate ahb_lite_subordinate_byte_lane
    (role subordinate)
    (clock clk)
    (reset (rst_n active_low async))
    (control
      (wait-cycles wait_cycles width 4))
    (bus
      (select HSEL)
      (ready-in HREADY)
      (address HADDR width 32)
      (transfer HTRANS width 2)
      (write HWRITE)
      (size HSIZE width 3)
      (write-data HWDATA width 32)
      (ready-out HREADYOUT)
      (response HRESP width 1)
      (read-data HRDATA width 32))
    (storage
      (register reg0
        (address 0 width 32)
        (data reg_data_q width 32 reset 0)))
    (transfer ahb_lite_byte_lane_access
      (accept-when (select 1) (ready-in 1))
      (idle 2'b00)
      (busy 2'b01)
      (nonseq 2'b10)
      (seq 2'b11)
      (supported-transfer nonseq)
      (ignored-transfer idle)
      (ignored-transfer busy)
      (supported-size byte)
      (supported-size halfword)
      (supported-size word)
      (lane-order little-endian)
      (narrow-write preserve-inactive-lanes)
      (narrow-read zero-fill-inactive-lanes)
      (unaligned-access error)
      (crossing-access error)
      (wait-cycles wait_cycles)
      (read register)
      (write register)
      (unmapped-address error)
      (unsupported-size error)
      (unsupported-transfer error)
      (response (okay 1'b0) (error 1'b1))
      (error-completion two-cycle))))
```

The implementation owner may add only the syntax needed for that selected
source. It must fail closed for unsupported `supported-size`, `lane-order`,
`narrow-write`, `narrow-read`, `unaligned-access`, and `crossing-access`
values.

## Selected Semantics

The selected contract stays on the 32-bit, single-register AHB-Lite/common-AHB
subordinate shape.

Accepted `HSIZE` encodings are:

| Size | `HSIZE` | Bytes | Address rule |
| --- | --- | --- | --- |
| byte | `3'b000` | 1 | `HADDR[31:2] == 0`; byte lane is `HADDR[1:0]`. |
| halfword | `3'b001` | 2 | `HADDR[31:2] == 0` and `HADDR[0] == 0`; halfword lane is `HADDR[1]`. |
| word | `3'b010` | 4 | `HADDR[31:2] == 0` and `HADDR[1:0] == 0`. |

Every other `HSIZE` encoding returns the existing two-cycle ERROR response.

The selected lane order is little-endian:

- byte lane `0` maps to `reg_data_q[7:0]` and `HWDATA[7:0]`;
- byte lane `1` maps to `reg_data_q[15:8]` and `HWDATA[15:8]`;
- byte lane `2` maps to `reg_data_q[23:16]` and `HWDATA[23:16]`;
- byte lane `3` maps to `reg_data_q[31:24]` and `HWDATA[31:24]`.

Writes update only active lanes:

- byte writes replace one byte and preserve the other three bytes;
- halfword writes replace either bits `[15:0]` or `[31:16]` and preserve the
  inactive halfword;
- word writes replace all 32 bits.

Reads drive only selected lanes with stored data and zero-fill inactive lanes:

- byte reads drive the selected byte lane from `reg_data_q` and drive all
  inactive `HRDATA` lanes to zero;
- halfword reads drive the selected halfword lane from `reg_data_q` and drive
  the inactive halfword to zero;
- word reads drive the full `reg_data_q`.

The active-byte-lane requirement is source-backed; the zero-fill inactive-lane
projection is an FSMGen fixture policy chosen to make the public sample
deterministic.

## Error And Wait-State Policy

The selected contract preserves the current subordinate timing policy:

- `IDLE` and `BUSY` are ignored with zero-wait OKAY defaults;
- selected `NONSEQ` transfers enter the data phase and honor `wait_cycles`;
- `SEQ` remains unsupported burst continuation and returns ERROR;
- unsupported sizes return ERROR;
- unmapped addresses return ERROR;
- unaligned halfword accesses return ERROR;
- unaligned word accesses return ERROR;
- accesses outside the selected 32-bit storage word return ERROR;
- any crossing access returns ERROR;
- ERROR completion keeps `HRDATA` at zero and performs no write update.

The selected ERROR response remains the existing two-cycle policy:

```text
cycle 1: HREADYOUT = 0, HRESP = 1, HRDATA = 0
cycle 2: HREADYOUT = 1, HRESP = 1, HRDATA = 0
```

## Reports And Support Accounting

The selected report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
```

The selected support-accounting identity is:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_pipeline_cli
source_kind: ppif
module_name: ahb_lite_subordinate_byte_lane
```

The selected generated review artifacts are:

```text
ahb_lite_subordinate_byte_lane.isf
ahb_lite_subordinate_byte_lane.fsm
```

The selected HDL module is:

```text
ahb_lite_subordinate_byte_lane
```

The report must add a narrow-transfer policy block covering:

- accepted sizes and `HSIZE` encodings;
- little-endian lane order;
- address alignment and selected storage-word rules;
- narrow-write inactive-lane preservation;
- narrow-read inactive-lane zero-fill;
- ERROR policy for unsupported size, unsupported transfer, unmapped,
  unaligned, and crossing accesses.

For the new selected source, byte-lane/narrow-transfer residue should be
removed from the subordinate optional-signal residue detail. Existing word-only
subordinate sources keep their current residue and behavior.

## Implementation Owner

`.737` owns implementation of exactly this contract:

- add `ppif/ahb_lite_subordinate_byte_lane.ppif`;
- extend the AHB subordinate parser/generator only for the selected
  byte/halfword/word subordinate contract;
- add the selected support-accounting entry and any capability-manifest text
  needed for the new public source;
- add focused coverage in
  `t/1482-ial2-ahb-subordinate-byte-lane.t`;
- preserve existing `t/1475-ial2-ahb-subordinate.t` and
  `t/1477-ial2-ahb-subordinate-profile-alias.t` behavior;
- add direct strict-check, schedule JSON, semantic JSON, and generated-artifact
  probes for the new source; and
- sync README, ROADMAP_V2, mdBook, task tree, MEMORY, Knowledge Map, and
  doctrine gates.

`.737` must not add `.ahb` alias support for the new byte-lane source, mutate
the existing word-only subordinate sources, add aggregate/interconnect
byte-lane propagation, add optional/property-gated signals, add burst `SEQ`,
add broader interconnect/decode, add legacy two-bit subordinate `HRESP`, add
scoreboards, add full-manager behavior, add direct backend behavior, add
verification-output generation, add backend-language variants, add AXI/APB
behavior, or add VHDL behavior.

## Validation

The implementation leaf must run at least:

```text
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1482-ial2-ahb-subordinate-byte-lane.t
prove -v t/1482-ial2-ahb-subordinate-byte-lane.t
prove -v t/1475-ial2-ahb-subordinate.t
prove -v t/1477-ial2-ahb-subordinate-profile-alias.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --outdir /tmp/fsmgen-ahb-byte-lane-subordinate ppif/ahb_lite_subordinate_byte_lane.ppif
```

When support-accounting or capability-manifest files change, `.737` must also
run the focused support-accounting and manifest tests. Closeout must run
Knowledge Map generation/check, mdBook build, docs path audit, memory
architecture check, diff check, and the doctrine driver. Broad or potentially
heavyweight Perl/`prove`/`fsmgen` commands must remain RAM-guarded.
