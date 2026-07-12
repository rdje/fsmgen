# IAL2 AHB Aggregate HBURST Byte-Lane SEQ Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.772`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.772` ships the matching bounded public
`.ahb` aliases for the selected generic AHB aggregate HBURST-aware byte-lane
`SEQ` sources:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
```

They mirror:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
```

and support-account as:

```text
entry_id: intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 3

entry_id: intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

The implementation is data-only: the two tracked `.ahb` fixtures are
byte-identical copies of the generic `.ppif` sources, plus their
support-accounting, language-surface, test, and docs entries. The shared
suffix-keyed profile-alias residue-suppression machinery (already used by the
requester, subordinate, byte-lane, byte-lane `SEQ`, endpoint HBURST, and
aggregate byte-lane/`SEQ` aliases) applies with no adapter code change.

## Public Alias Contract

Both aliases use the same `protocol-platform-intent` form as the generic
`.ppif` sources and keep explicit `(profile ahb)`. The source object IDs and
intent names remain:

```text
fsmgen-ahb-interconnect-byte-lane-hburst-seq
ahb_interconnect_byte_lane_hburst_seq

fsmgen-ahb-interconnect-two-subordinate-byte-lane-hburst-seq
ahb_interconnect_two_subordinate_byte_lane_hburst_seq
```

The one-subordinate alias embeds `ahb_lite_subordinate_byte_lane_hburst_seq`.
The two-subordinate alias embeds `ahb_status_subordinate_byte_lane_hburst_seq`
and `ahb_control_subordinate_byte_lane_hburst_seq`. Each embedded subordinate
keeps transfer `ahb_lite_byte_lane_hburst_seq_access` with byte/halfword/word
narrow transfers, a `(burst HBURST_* width 3)` child-local binding, and
`(seq-policy hburst-in-word-progressive)`.

## Generated Review Artifacts

The one-subordinate alias lowers through:

```text
amba_requester.isf
ahb_lite_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_lite_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The two-subordinate alias lowers through:

```text
amba_requester.isf
ahb_status_subordinate_byte_lane_hburst_seq.isf
ahb_control_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf
amba_requester.fsm
ahb_status_subordinate_byte_lane_hburst_seq.fsm
ahb_control_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

Both select HDL entry module `ahb_tb`. The embedded HBURST-aware subordinate
FSMs keep the `seq_hburst_q` HBURST-stability state and the
`seq_beats_remaining_q` four-beat state.

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
- `subordinate_owned_hburst_in_word_seq_policy` with `policy`
  `hburst_in_word_progressive` and `base_policy` `in_word_progressive`;
- `length_source: HBURST`;
- `subtract_window_base_before_subordinate_hburst_seq_policy`;
- direct requester/global `HBURST` fanout to child-local `HBURST_REGS`,
  `HBURST_STATUS`, and `HBURST_CONTROL` via
  `request_forwarding.burst.child_names`;
- supported HBURST `SEQ` size `byte` and supported HBURST modes `WRAP4`,
  `INCR4`;
- selected-subordinate ownership for mapped-hit narrow-transfer and HBURST
  `SEQ` behavior; and
- interconnect-owned unmapped ERROR behavior.

Child reports for embedded HBURST-aware byte-lane `SEQ` subordinates carry
`bindings.bus.burst`, `narrow_transfer_policy`, and `transfer.seq_policy`.

Alias report trees remove `ahb_aggregate_profile_alias_deferred`,
`ahb_profile_alias_deferred`, and `ahb_subordinate_profile_alias_deferred`.
They also remove `.ahb alias exposure` wording from embedded HBURST-aware
byte-lane `SEQ` child `ahb_burst_seq_support_deferred` details. The matching
generic `.ppif` reports keep those source-surface residues.

True remaining residue is unchanged: BUSY-in-burst parking, halfword/word
burst `SEQ`, wider or indefinite bursts, multi-word/register-bank `SEQ`
progression, optional/property-gated AHB signals, broader AHB
interconnect/decode, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, and VHDL remain future task-tree-owned work.

## Validation

Focused validation:

```bash
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t
prove -Iperl t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t
prove -Iperl t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t
prove -Iperl t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t
prove -Iperl t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_doctrines.sh
```
