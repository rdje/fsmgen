# IAL2 AHB Byte-Lane In-Word SEQ Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.754`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.754` ships the matching bounded public
AHB profile alias for the byte-lane in-word `SEQ` subordinate:

```text
ppif/ahb_lite_subordinate_byte_lane_seq.ahb
```

The alias mirrors the shipped generic source:

```text
ppif/ahb_lite_subordinate_byte_lane_seq.ppif
```

It support-accounts as:

```text
entry_id: intent.ahb_profile_alias_subordinate_byte_lane_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_subordinate_byte_lane_seq_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane_seq
```

The existing generic byte-lane `SEQ` `.ppif`, word-only `.ppif/.ahb`,
byte-lane `.ppif/.ahb`, requester, interconnect, aggregate, and HDL behavior
remain preserved.

## Public Source Contract

The alias uses the same `protocol-platform-intent` form and keeps explicit
`(profile ahb)`. It accepts exactly one selected subordinate object:

```text
(ahb-subordinate ahb_lite_subordinate_byte_lane_seq ...)
```

The transfer clause keeps the selected byte-lane/narrow-transfer policy and
the selected continuation policy:

```text
(supported-transfer nonseq)
(supported-size byte)
(supported-size halfword)
(supported-size word)
(lane-order little-endian)
(narrow-write preserve-inactive-lanes)
(narrow-read zero-fill-inactive-lanes)
(seq-policy in-word-progressive)
```

Malformed `.ahb` aliases fail closed for the same selected shape errors as the
generic `.ppif` source: missing or non-AHB profile, duplicate `seq-policy`,
unsupported `seq-policy`, or any attempt to widen `supported-transfer` beyond
`nonseq`.

## Generated Review Artifacts

The alias lowers through the same generated artifacts as the generic source:

```text
ahb_lite_subordinate_byte_lane_seq.isf
ahb_lite_subordinate_byte_lane_seq.fsm
```

The generated HDL entry remains:

```text
ahb_lite_subordinate_byte_lane_seq
```

Schedule/report JSON preserves `narrow_transfer_policy` and structured
`transfer.seq_policy`:

```text
selected: true
mode: in_word_progressive
requires_prior_transfer: prior_okay_nonseq_or_seq
supported_sizes: [byte, halfword]
address_progression: previous_address_plus_size_bytes
control_stability: [HWRITE, HSIZE]
clears_on: [reset, idle, busy, error, new_nonseq]
```

## Residue Movement

The generic `.ppif` report keeps source-surface alias residue. Its remaining
`ahb_burst_seq_support_deferred` detail still names `.ahb alias exposure`
because the generic source is not itself an alias.

The `.ahb` alias report removes `ahb_subordinate_profile_alias_deferred` and
also removes `.ahb alias exposure` from the remaining
`ahb_burst_seq_support_deferred` detail. The alias still keeps true future
burst/coverage residue:

- HBURST-driven length and wrap semantics;
- BUSY-in-burst parking;
- multi-word/register-bank progression;
- aggregate propagation;
- full-manager behavior;
- direct backend behavior;
- verification-output generation;
- backend-language variants;
- AXI/APB behavior;
- broader AHB behavior; and
- VHDL behavior.

## Validation

Focused validation for the slice:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t
prove -Iperl t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t
prove -Iperl t/1486-ial2-ahb-subordinate-byte-lane-seq.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

The focused alias test covers adapter parsing, `.ahb` versus `.ppif`
generated artifact parity, strict check JSON, schedule JSON, semantic JSON,
`--outdir` review artifacts, alias-only residue cleanup, generic `.ppif`
source-surface residue preservation, malformed alias diagnostics, and
preservation checks for the existing word-only and byte-lane AHB subordinate
aliases.
