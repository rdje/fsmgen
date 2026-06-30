# IAL2 AHB Aggregate Byte-Lane In-Word SEQ Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.760`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.760` ships the matching bounded public
`.ahb` aliases for the selected generic AHB aggregate byte-lane in-word `SEQ`
sources:

```text
ppif/ahb_interconnect_byte_lane_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
```

They mirror:

```text
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
```

and support-account as:

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

## Public Alias Contract

Both aliases use the same `protocol-platform-intent` form as the generic
`.ppif` sources and keep explicit `(profile ahb)`. The source object IDs and
intent names remain:

```text
fsmgen-ahb-interconnect-byte-lane-seq
ahb_interconnect_byte_lane_seq

fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq
ahb_interconnect_two_subordinate_byte_lane_seq
```

The one-subordinate alias embeds `ahb_lite_subordinate_byte_lane_seq`. The
two-subordinate alias embeds `ahb_status_subordinate_byte_lane_seq` and
`ahb_control_subordinate_byte_lane_seq`. Each embedded subordinate keeps
transfer `ahb_lite_byte_lane_seq_access` with byte/halfword/word narrow
transfers and `(seq-policy in-word-progressive)`.

## Generated Review Artifacts

The one-subordinate alias lowers through:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_lite_subordinate_byte_lane_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The two-subordinate alias lowers through:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane_seq.isf
ahb_control_subordinate_byte_lane_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_status_subordinate_byte_lane_seq.fsm
ahb_control_subordinate_byte_lane_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

Both select HDL entry module `ahb_tb`.

## Reports And Residue

The alias schedule/report JSON preserves:

```text
composition.byte_lane_propagation
composition.seq_policy_propagation
```

The propagation reports keep the same selected policies as the generic `.ppif`
sources:

- `subordinate_owned_narrow_transfer_policy`;
- `subtract_window_base_before_subordinate_lane_policy`;
- `subordinate_owned_in_word_seq_policy`;
- `subtract_window_base_before_subordinate_seq_policy`;
- selected-subordinate ownership for mapped-hit narrow-transfer and `SEQ`
  behavior; and
- interconnect-owned unmapped ERROR behavior.

Child reports for embedded byte-lane `SEQ` subordinates carry both
`narrow_transfer_policy` and `transfer.seq_policy`.

Alias report trees remove `ahb_aggregate_profile_alias_deferred`,
`ahb_profile_alias_deferred`, and `ahb_subordinate_profile_alias_deferred`.
They also remove `.ahb alias exposure` wording from embedded byte-lane `SEQ`
child `ahb_burst_seq_support_deferred` details. The matching generic `.ppif`
reports keep those source-surface residues.

True remaining residue is unchanged: HBURST-driven length/wrap semantics,
BUSY-in-burst handling, multi-word/register-bank `SEQ` progression,
optional/property-gated AHB signals, broader AHB interconnect/decode,
scoreboards, full-manager behavior, direct backend behavior,
verification-output generation, backend-language variants, AXI/APB behavior,
and VHDL remain future task-tree-owned work.

## Validation

Focused validation:

```bash
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t
prove -Iperl t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t
prove -Iperl t/1488-ial2-ahb-interconnect-byte-lane-seq.t
prove -Iperl t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
prove -Iperl t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_doctrines.sh
```
