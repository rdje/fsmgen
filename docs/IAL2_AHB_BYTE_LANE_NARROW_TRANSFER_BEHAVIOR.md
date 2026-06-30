# IAL2 AHB Byte-Lane/Narrow-Transfer Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.737`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.737` ships the first bounded public AHB
byte-lane/narrow-transfer subordinate source:

```text
ppif/ahb_lite_subordinate_byte_lane.ppif
```

The source support-accounts as:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane
source_kind: ppif
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane
```

The existing word-only subordinate sources remain unchanged:

```text
ppif/ahb_lite_subordinate.ppif
ppif/ahb_lite_subordinate.ahb
```

The byte-lane source has no `.ahb` profile alias in this slice.

## Public Source Contract

The shipped source uses one `(ahb-subordinate
ahb_lite_subordinate_byte_lane ...)` object under `(profile ahb)`. The source
adds the selected transfer policy clauses:

```text
(supported-size byte)
(supported-size halfword)
(supported-size word)
(lane-order little-endian)
(narrow-write preserve-inactive-lanes)
(narrow-read zero-fill-inactive-lanes)
(unaligned-access error)
(crossing-access error)
```

The generator fails closed for unsupported or partial size-policy clauses. The
word-only subordinate source omits these clauses and keeps the original
word-only behavior and report surface.

## Generated Review Artifacts

The source lowers through generated IAL1 before generated IAL0:

```text
ahb_lite_subordinate_byte_lane.isf
ahb_lite_subordinate_byte_lane.fsm
```

The generated HDL entry is:

```text
ahb_lite_subordinate_byte_lane
```

## Transfer Behavior

The selected behavior remains a single 32-bit register at local address 0.
`IDLE` and `BUSY` transfers are ignored. `NONSEQ` transfers enter the data
phase, honor `wait_cycles`, and then select one of the bounded access paths.
`SEQ` remains unsupported burst continuation and returns the existing two-cycle
ERROR response.

Accepted size and address rules are:

| Size | `HSIZE` | Address rule | Active lane |
| --- | --- | --- | --- |
| byte | `3'b000` | `HADDR[31:2] == 0` | `HADDR[1:0]` |
| halfword | `3'b001` | `HADDR[31:2] == 0 && HADDR[0] == 0` | `HADDR[1]` |
| word | `3'b010` | `HADDR == 0` | all lanes |

Little-endian byte lanes are fixed:

| Lane | Bits | Mask |
| --- | --- | --- |
| 0 | `[7:0]` | `32'h000000ff` |
| 1 | `[15:8]` | `32'h0000ff00` |
| 2 | `[23:16]` | `32'h00ff0000` |
| 3 | `[31:24]` | `32'hff000000` |

Writes update active lanes from `HWDATA` and preserve inactive storage lanes.
Reads drive the active stored lanes in place and zero-fill inactive `HRDATA`
lanes. Word writes still replace the full register directly, and word reads
still return the full register.

Unsupported size, unsupported transfer, unmapped address, unaligned access,
and crossing access use the same two-cycle ERROR response as the word-only
source:

```text
cycle 1: HREADYOUT = 0, HRESP = 1, HRDATA = 0
cycle 2: HREADYOUT = 1, HRESP = 1, HRDATA = 0
```

ERROR paths do not update storage.

## Reports And Residue

The report schema remains:

```text
fsmgen.ial2.protocol_intent.ahb_subordinate.v1
```

For the byte-lane source, `transfer` records the selected supported sizes,
lane order, narrow write/read policies, and unaligned/crossing policies. The
report also includes `narrow_transfer_policy`, which records accepted sizes,
`HSIZE` encodings, address rules, little-endian lane masks, inactive-lane
write/read policy, and ERROR policy.

The byte-lane source removes byte-lane wording from the subordinate
optional-signal residue. Remaining AHB residue includes:

- a `.ahb` alias for the byte-lane subordinate source;
- byte-lane propagation through aggregate interconnects;
- AHB completer behavior;
- optional/property-gated subordinate signals;
- burst `SEQ` continuation;
- broader AHB interconnect/decode;
- legacy two-bit subordinate `HRESP` compatibility;
- scoreboards, full-manager behavior, direct backend behavior,
  verification-output generation, backend-language variants, and VHDL.

## Validation

Focused validation for the slice:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -c t/1482-ial2-ahb-subordinate-byte-lane.t
prove -v t/1482-ial2-ahb-subordinate-byte-lane.t
prove -v t/1475-ial2-ahb-subordinate.t
prove -v t/1477-ial2-ahb-subordinate-profile-alias.t
prove -v t/248-regression-corpus-accounting.t
prove -v t/297-capability-manifest.t
```

The focused byte-lane test also runs direct strict check, schedule JSON,
semantic JSON, and `--outdir` probes for
`ppif/ahb_lite_subordinate_byte_lane.ppif`, and preservation probes for the
existing word-only subordinate `.ppif` and `.ahb` alias.
