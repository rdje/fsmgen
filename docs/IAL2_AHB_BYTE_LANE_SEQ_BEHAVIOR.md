# IAL2 AHB Byte-Lane In-Word SEQ Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.752`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.752` ships the first bounded public AHB
subordinate-side `SEQ` continuation source:

```text
ppif/ahb_lite_subordinate_byte_lane_seq.ppif
```

The source support-accounts as:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane_seq
source_kind: ppif
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_seq_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane_seq
```

The existing word-only, byte-lane, `.ahb` alias, requester, and aggregate AHB
sources remain unchanged.

## Public Source Contract

The source uses one `(ahb-subordinate ahb_lite_subordinate_byte_lane_seq ...)`
object under `(profile ahb)`. It keeps the shipped byte-lane/narrow-transfer
clauses and adds the selected continuation clause:

```text
(seq-policy in-word-progressive)
```

The transfer still reports `supported_transfer: nonseq` for compatibility.
The report adds structured `transfer.seq_policy` with:

```text
selected: true
mode: in_word_progressive
requires_prior_transfer: prior_okay_nonseq_or_seq
supported_sizes: [byte, halfword]
address_progression: previous_address_plus_size_bytes
control_stability: [HWRITE, HSIZE]
clears_on: [reset, idle, busy, error, new_nonseq]
```

Malformed sources fail closed if `seq-policy` has any value other than
`in-word-progressive`, appears more than once, appears without the selected
byte/halfword/word size policy, or attempts to widen `supported-transfer`
beyond `nonseq`.

## Generated Review Artifacts

The source lowers through generated IAL1 before generated IAL0:

```text
ahb_lite_subordinate_byte_lane_seq.isf
ahb_lite_subordinate_byte_lane_seq.fsm
```

The generated HDL entry is:

```text
ahb_lite_subordinate_byte_lane_seq
```

The generated IAL1 carries persistent continuation state:

```text
seq_valid_q
seq_expected_addr_q
seq_size_q
seq_write_q
```

An accepted `IDLE` or `BUSY` transfer clears that continuation state while
leaving output defaults at zero-wait OKAY.

## Transfer Behavior

`NONSEQ` byte, halfword, and word accesses preserve the shipped byte-lane
source behavior. `SEQ` can complete OKAY only when all selected continuation
checks pass:

- the previous accepted active transfer completed OKAY;
- the previous accepted active transfer was `NONSEQ` or a valid `SEQ`;
- the previous and current sizes are byte or halfword;
- current `HWRITE` and `HSIZE` match the stored prior values;
- current `HADDR` equals the stored expected next address;
- the current transfer remains inside the selected 32-bit storage word; and
- the usual byte-lane address/alignment rule for that size holds.

Selected address progression is:

```text
byte:     expected_next = previous_addr + 1
halfword: expected_next = previous_addr + 2
```

Accepted examples:

```text
NONSEQ byte     at HADDR 0 -> SEQ byte     at HADDR 1
NONSEQ byte     at HADDR 1 -> SEQ byte     at HADDR 2
NONSEQ byte     at HADDR 2 -> SEQ byte     at HADDR 3
NONSEQ halfword at HADDR 0 -> SEQ halfword at HADDR 2
```

After byte lane 3 or halfword lane 1, the in-word continuation is exhausted
and the generated state clears. A further `SEQ` without a new valid `NONSEQ`
returns ERROR. Word `NONSEQ` remains supported but does not arm `SEQ`
continuation.

Successful `SEQ` reads and writes reuse the existing narrow-transfer lane
policy: writes update active lanes and preserve inactive storage lanes; reads
drive active stored lanes in place and zero-fill inactive `HRDATA` lanes.

## Fail-Closed Shapes

The selected two-cycle ERROR response is used for:

- standalone `SEQ`;
- `SEQ` after `IDLE`, `BUSY`, reset, or ERROR;
- `SEQ` after a word access;
- byte or halfword `SEQ` that crosses out of the selected word;
- changed `HWRITE` or `HSIZE`;
- unexpected address progression;
- unsupported size, unmapped address, unaligned access, or crossing access.

`HBURST`-driven length/wrap semantics, BUSY-as-burst-parking continuation,
multi-word/register-bank progression, `.ahb` alias exposure, aggregate
propagation, full-manager behavior, direct backend behavior,
verification-output generation, backend-language variants, AXI, APB, broader
AHB behavior, and VHDL remain deferred.

## Validation

Focused validation for the slice:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
prove -Iperl t/1486-ial2-ahb-subordinate-byte-lane-seq.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

The focused test covers adapter parsing, malformed `seq-policy` diagnostics,
generated IAL1/FSM review text, strict check JSON, schedule JSON, semantic
JSON, `--outdir` review artifacts, HDL output, and preservation checks for the
existing byte-lane `.ppif`, word-only `.ppif`, and byte-lane `.ahb` alias.
