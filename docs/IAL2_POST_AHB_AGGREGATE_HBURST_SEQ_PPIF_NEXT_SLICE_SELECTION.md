# IAL2 Post-AHB Aggregate HBURST SEQ PPIF Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.770`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.770` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.771`, a no-behavior public contract
selection for matching bounded public AHB aggregate HBURST-aware byte-lane
`SEQ` `.ahb` profile aliases.

The candidate future sources are:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
```

They must mirror the shipped generic sources:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Current Boundary

`.770` ships generic aggregate HBURST `.ppif` propagation only. The new
generic sources strict-check, support-account, generate review artifacts, lower
to HDL entry `ahb_tb`, forward requester/global `HBURST` to child-local
`HBURST_REGS`, `HBURST_STATUS`, and `HBURST_CONTROL`, preserve
`composition.byte_lane_propagation`, and reuse
`composition.seq_policy_propagation` with mode
`subordinate_owned_hburst_in_word_seq_policy`.

Matching aggregate `.ahb` alias files are absent from the repository and from
support accounting. The generic `.ppif` reports correctly keep source-surface
alias residue. The next slice must select exact alias paths, support IDs,
coverage keys, source kind, generated artifacts, residue cleanup, tests, and
book/docs updates before alias implementation.

## Selected `.771` Work Owner

`.771` must remain no-behavior unless it explicitly selects a later
implementation owner. It should decide whether the matching aliases are:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
```

and must pin their expected support identities, coverage buckets, report
source kind, alias-only residue cleanup, focused tests, and preservation
matrix. Broader aggregate HBURST behavior, BUSY-in-burst parking,
halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional/property-gated signals, broader
AHB, direct backend, verification-output, backend-language variants, AXI/APB,
and VHDL remain deferred.
