# IAL2 AHB Subordinate BUSY-Park Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.778`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.778` ships the matching bounded public AHB
profile alias for the HBURST-aware byte-lane `SEQ` subordinate with BUSY-in-burst
parking:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

The alias mirrors the shipped generic BUSY-park source:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

It support-accounts as:

```text
entry_id: intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
module_name: ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
```

The existing generic BUSY-park `.ppif`, endpoint HBURST-aware `.ppif/.ahb`,
word-only `.ppif/.ahb`, byte-lane `.ppif/.ahb`, byte-lane `SEQ` `.ppif/.ahb`,
requester, aggregate `.ppif/.ahb`, and HDL behavior remain preserved except for
the additive alias fixture, support-accounting entry, language-surface entry,
tests, and docs.

## Public Source Contract

The alias is a byte-identical mirror of the generic BUSY-park `.ppif` source. It
uses the same `protocol-platform-intent` form, keeps explicit `(profile ahb)`,
and accepts exactly one selected subordinate object:

```text
(ahb-subordinate ahb_lite_subordinate_byte_lane_hburst_seq_busy_park ...)
```

The transfer clause keeps the selected byte-lane/narrow-transfer policy, the
selected HBURST-aware continuation policy, and the distinctive BUSY-park
classification:

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
(ignored-transfer idle)
(parked-transfer busy)
```

Malformed `.ahb` aliases fail closed for the same selected-shape errors as the
generic BUSY-park `.ppif` source: missing or non-AHB profile, `(parked-transfer
busy)` without `(seq-policy hburst-in-word-progressive)`, duplicate `burst`,
wrong `burst` width, `hburst-in-word-progressive` without a `bus.burst` binding,
duplicate or unsupported `seq-policy`, or any attempt to widen the selected
shape.

## Generated Review Artifacts

The alias lowers through the same generated artifacts as the generic BUSY-park
source:

```text
ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf
ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm
```

The generated HDL entry remains:

```text
ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
```

Schedule/report JSON preserves `bindings.bus.burst` and the structured
BUSY-park `transfer.seq_policy`:

```text
bindings.bus.burst.name: HBURST
bindings.bus.burst.width: 3
transfer.seq_policy.mode: hburst_in_word_progressive
transfer.seq_policy.length_source: HBURST
transfer.seq_policy.supported_sizes: [byte]
transfer.seq_policy.supported_hburst_modes: [WRAP4, INCR4]
transfer.seq_policy.parks_on: [busy]
transfer.seq_policy.clears_on: [reset, idle, error, new_nonseq, final_beat]
```

`parks_on: [busy]` and the BUSY-free `clears_on` are the distinctive report
shape: a `HTRANS = BUSY` beat holds the in-word burst context (the unassigned
`seq_*` registers retain their values) rather than clearing it, and the
following `SEQ` beat resumes through the existing `seq_ok_base` validation.

## Residue Movement

The generic BUSY-park `.ppif` report keeps source-surface alias residue. Its
remaining `ahb_burst_seq_support_deferred` detail still names `.ahb alias
exposure` because the generic source is not itself an alias.

The `.ahb` alias report removes `ahb_subordinate_profile_alias_deferred` and also
removes `.ahb alias exposure` from the remaining `ahb_burst_seq_support_deferred`
detail through the existing suffix-keyed profile-alias suppression, with no
adapter change. The alias still keeps true future HBURST/broader-AHB residue:

- aggregate BUSY-parking / aggregate HBURST propagation;
- requester-side BUSY insertion;
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
perl -Iperl -c t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t
prove -Iperl t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t
prove -Iperl t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t
prove -Iperl t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

The focused alias test covers adapter parsing, the byte-identical `.ahb`
versus `.ppif` mirror, generated artifact parity, strict check JSON, schedule
JSON, semantic JSON, `--outdir` review artifacts, the distinctive
`parks_on`/`clears_on` BUSY-park report shape, alias-only residue cleanup,
generic `.ppif` source-surface residue preservation, malformed alias
diagnostics (including the parked-busy fail-closed path), and preservation
checks for the generic BUSY-park `.ppif` and the endpoint HBURST-aware `.ahb`
alias surface.
