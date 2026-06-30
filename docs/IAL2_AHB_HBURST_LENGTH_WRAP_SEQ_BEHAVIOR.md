# IAL2 AHB HBURST Length/Wrap SEQ Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.764`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.764` ships the first bounded public AHB
HBURST-aware subordinate-side `SEQ` source:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
```

The source support-accounts as:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq
source_kind: ppif
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane_hburst_seq
```

The source shipped as generic `.ppif` only in `.764`. The matching `.ahb`
profile alias is tracked separately in
`docs/IAL2_AHB_HBURST_LENGTH_WRAP_SEQ_PROFILE_ALIAS_BEHAVIOR.md`.
Existing word-only, byte-lane, byte-lane in-word `SEQ`, `.ahb` alias,
requester, and aggregate AHB sources remain unchanged by the generic `.ppif`
slice.

## Public Source Contract

The source uses one
`(ahb-subordinate ahb_lite_subordinate_byte_lane_hburst_seq ...)` object under
`(profile ahb)`. It keeps the shipped byte-lane/narrow-transfer clauses and
adds the selected HBURST binding and continuation policy:

```text
(burst HBURST width 3)
(seq-policy hburst-in-word-progressive)
```

The transfer still reports `supported_transfer: nonseq` for compatibility.
The report adds structured `bindings.bus.burst` and `transfer.seq_policy`:

```text
bindings.bus.burst.name: HBURST
bindings.bus.burst.width: 3
transfer.seq_policy.selected: true
transfer.seq_policy.mode: hburst_in_word_progressive
transfer.seq_policy.base_policy: in_word_progressive
transfer.seq_policy.length_source: HBURST
transfer.seq_policy.requires_prior_transfer: prior_okay_hburst_nonseq_or_seq
transfer.seq_policy.supported_sizes: [byte]
transfer.seq_policy.supported_hburst_modes: [WRAP4, INCR4]
transfer.seq_policy.fail_closed_hburst_modes: [INCR, WRAP8, INCR8, WRAP16, INCR16]
transfer.seq_policy.single_policy: nonseq_only_no_seq_history
transfer.seq_policy.beats_per_burst: 4
transfer.seq_policy.window_bytes: 4
transfer.seq_policy.address_progression: hburst_incr4_or_wrap4_within_word
transfer.seq_policy.control_stability: [HBURST, HWRITE, HSIZE]
transfer.seq_policy.clears_on: [reset, idle, busy, error, new_nonseq, final_beat]
```

Malformed sources fail closed if the subordinate `burst` binding is duplicated,
uses a width other than 3, or is missing when
`hburst-in-word-progressive` is selected. Malformed sources also fail closed if
`seq-policy` is duplicated, has any value other than `in-word-progressive` or
`hburst-in-word-progressive`, appears without the selected byte/halfword/word
size policy, or attempts to widen `supported-transfer` beyond `nonseq`.

## Generated Review Artifacts

The source lowers through generated IAL1 before generated IAL0:

```text
ahb_lite_subordinate_byte_lane_hburst_seq.isf
ahb_lite_subordinate_byte_lane_hburst_seq.fsm
```

The generated HDL entry is:

```text
ahb_lite_subordinate_byte_lane_hburst_seq
```

The generated IAL1 exposes `HBURST`, samples it as `burst_q`, and carries
persistent HBURST continuation state:

```text
seq_valid_q
seq_expected_addr_q
seq_size_q
seq_write_q
seq_hburst_q
seq_beats_remaining_q
```

An accepted `IDLE` or `BUSY` transfer clears that continuation state while
leaving output defaults at zero-wait OKAY.

## Transfer Behavior

`HBURST=SINGLE` keeps independent `NONSEQ` byte, halfword, and word behavior
from the shipped byte-lane source and never arms `SEQ` history.

`HBURST=WRAP4` and `HBURST=INCR4` arm byte-only four-beat history. `INCR4`
must start at byte lane 0 so all four beats stay inside `reg0`; `WRAP4` may
start at any byte lane and wraps inside the four-byte word window.

Accepted examples:

```text
INCR4 byte NONSEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3
WRAP4 byte NONSEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3
WRAP4 byte NONSEQ HADDR 1 -> SEQ HADDR 2 -> SEQ HADDR 3 -> SEQ HADDR 0
WRAP4 byte NONSEQ HADDR 2 -> SEQ HADDR 3 -> SEQ HADDR 0 -> SEQ HADDR 1
WRAP4 byte NONSEQ HADDR 3 -> SEQ HADDR 0 -> SEQ HADDR 1 -> SEQ HADDR 2
```

Each successful byte beat uses the existing narrow-transfer lane policy:
writes update active lanes and preserve inactive storage lanes; reads drive
active stored lanes in place and zero-fill inactive `HRDATA` lanes. After the
fourth accepted beat, continuation state clears. A further `SEQ` without a new
valid `NONSEQ` returns ERROR.

## Fail-Closed Shapes

The selected two-cycle ERROR response is used for:

- standalone `SEQ`;
- `SEQ` after `SINGLE`, `IDLE`, `BUSY`, reset, or ERROR;
- `SEQ` after a successful halfword or word transfer;
- changed `HBURST`, `HWRITE`, or `HSIZE` inside an armed sequence;
- unexpected `HADDR` progression;
- `INCR4` byte bursts whose first address is not word aligned;
- `INCR`, `WRAP8`, `INCR8`, `WRAP16`, and `INCR16`;
- `INCR4` or `WRAP4` with halfword or word size;
- unsupported size, unmapped address, unaligned access, or crossing access; and
- any multi-word/register-bank progression.

BUSY-in-burst parking, halfword/word burst `SEQ`, indefinite `INCR`, wider
fixed bursts, aggregate propagation, full manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI, APB,
broader AHB behavior, and VHDL remain deferred. The matching endpoint `.ahb`
alias exposure is shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.766`.

For this HBURST-aware source only,
`ahb_subordinate_optional_signal_residue` no longer lists `HBURST` as
deferred. The remaining `ahb_burst_seq_support_deferred` detail is narrowed to
the unsupported burst shapes and follow-on source surfaces above.

## Validation

Focused validation for the slice:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t
prove -Iperl t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t
prove -Iperl t/1486-ial2-ahb-subordinate-byte-lane-seq.t t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t t/1488-ial2-ahb-interconnect-byte-lane-seq.t t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t
prove -Iperl t/297-capability-manifest.t
```

The focused HBURST test covers adapter parsing, malformed `burst` and
`seq-policy` diagnostics, generated IAL1/FSM review text, strict check JSON,
schedule JSON, semantic JSON, `--outdir` review artifacts, HDL output, and
preservation checks for the existing byte-lane `SEQ` `.ppif`, byte-lane
`.ppif`, endpoint `.ahb` alias, and aggregate byte-lane `SEQ` `.ppif`.
