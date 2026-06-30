# IAL2 AHB HBURST Length/Wrap SEQ Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.766`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.766` ships the matching bounded public
AHB profile alias for the HBURST-aware byte-lane `SEQ` subordinate:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
```

The alias mirrors the shipped generic source:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
```

It support-accounts as:

```text
entry_id: intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane_hburst_seq
```

The existing generic HBURST-aware `.ppif`, word-only `.ppif/.ahb`,
byte-lane `.ppif/.ahb`, byte-lane `SEQ` `.ppif/.ahb`, requester, aggregate
`.ppif/.ahb`, and HDL behavior remain preserved except for the additive alias
fixture, support-accounting entry, language-surface entry, tests, and docs.

## Public Source Contract

The alias uses the same `protocol-platform-intent` form and keeps explicit
`(profile ahb)`. It accepts exactly one selected subordinate object:

```text
(ahb-subordinate ahb_lite_subordinate_byte_lane_hburst_seq ...)
```

The transfer clause keeps the selected byte-lane/narrow-transfer policy and
the selected HBURST-aware continuation policy:

```text
(burst HBURST width 3)
(supported-transfer nonseq)
(supported-size byte)
(supported-size halfword)
(supported-size word)
(lane-order little-endian)
(narrow-write preserve-inactive-lanes)
(narrow-read zero-fill-inactive-lanes)
(seq-policy hburst-in-word-progressive)
```

Malformed `.ahb` aliases fail closed for the same selected shape errors as the
generic `.ppif` source: missing or non-AHB profile, duplicate `burst`, wrong
`burst` width, `hburst-in-word-progressive` without a `bus.burst` binding,
duplicate or unsupported `seq-policy`, or any attempt to widen the selected
shape.

## Generated Review Artifacts

The alias lowers through the same generated artifacts as the generic source:

```text
ahb_lite_subordinate_byte_lane_hburst_seq.isf
ahb_lite_subordinate_byte_lane_hburst_seq.fsm
```

The generated HDL entry remains:

```text
ahb_lite_subordinate_byte_lane_hburst_seq
```

Schedule/report JSON preserves `bindings.bus.burst` and structured
`transfer.seq_policy`:

```text
bindings.bus.burst.name: HBURST
bindings.bus.burst.width: 3
transfer.seq_policy.mode: hburst_in_word_progressive
transfer.seq_policy.length_source: HBURST
transfer.seq_policy.supported_sizes: [byte]
transfer.seq_policy.supported_hburst_modes: [WRAP4, INCR4]
transfer.seq_policy.fail_closed_hburst_modes: [INCR, WRAP8, INCR8, WRAP16, INCR16]
transfer.seq_policy.address_progression: hburst_incr4_or_wrap4_within_word
transfer.seq_policy.control_stability: [HBURST, HWRITE, HSIZE]
```

## Residue Movement

The generic `.ppif` report keeps source-surface alias residue. Its remaining
`ahb_burst_seq_support_deferred` detail still names `.ahb alias exposure`
because the generic source is not itself an alias.

The `.ahb` alias report removes `ahb_subordinate_profile_alias_deferred` and
also removes `.ahb alias exposure` from the remaining
`ahb_burst_seq_support_deferred` detail. The alias still keeps true future
HBURST/broader-AHB residue:

- aggregate HBURST propagation;
- BUSY-in-burst parking;
- halfword/word burst `SEQ`;
- wider or indefinite bursts;
- multi-word/register-bank progression;
- optional/property-gated signals;
- broader AHB behavior;
- direct backend behavior;
- verification-output generation;
- backend-language variants;
- AXI/APB behavior; and
- VHDL behavior.

## Validation

Focused validation for the slice:

```bash
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t
prove -Iperl t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t
prove -Iperl t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t
prove -Iperl t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

The focused alias test covers adapter parsing, `.ahb` versus `.ppif`
generated artifact parity, strict check JSON, schedule JSON, semantic JSON,
`--outdir` review artifacts, alias-only residue cleanup, generic `.ppif`
source-surface residue preservation, malformed alias diagnostics, and
preservation checks for the existing byte-lane `SEQ` alias and aggregate
byte-lane `SEQ` `.ppif` surface.
