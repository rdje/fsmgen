# IAL2 Post-AHB Aggregate Byte-Lane SEQ PPIF Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.759`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.759` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.760`, direct implementation of the
matching bounded public AHB aggregate byte-lane in-word `SEQ` `.ahb`
profile-alias sources.

The selected future sources are:

```text
ppif/ahb_interconnect_byte_lane_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
```

They must mirror the shipped generic aggregate byte-lane in-word `SEQ`
sources:

```text
ppif/ahb_interconnect_byte_lane_seq.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.758` aggregate `SEQ` behavior record, `.757` public
contract selection, `.756` readiness audit, the shipped AHB requester,
subordinate, interconnect, aggregate byte-lane, endpoint byte-lane `SEQ`, and
aggregate byte-lane `SEQ` `.ppif`/`.ahb` behavior records, current PPIF parser
profile-alias handling, `AhbInterconnect` report behavior, RegressionCorpus,
LanguageSurfaceSection/capability-manifest expectations, focused AHB tests,
README, ROADMAP_V2, mdBook AHB/protocol/backlog chapters, task tree, Memory,
Knowledge Map, and relevant decisions.

Relevant decisions remain:

- `0014`, protocol/platform intent uses layered lowering;
- `0015`, protocol-specific extensions are profile aliases over IAL2;
- `0016`, `.ppif` is the first generic IAL2 container;
- `0018`, IAL contracts and the mdBook are backend-language-neutral; and
- `0006` and `0007`, mdBook synchronization and memory architecture.

## Current Boundary

`.758` ships the generic aggregate byte-lane in-word `SEQ` `.ppif` sources.
They lower through generated `.isf` before generated `.fsm` review artifacts,
select HDL entry `ahb_tb`, preserve `composition.byte_lane_propagation`, add
`composition.seq_policy_propagation`, and propagate child
`narrow_transfer_policy` plus `transfer.seq_policy`.

The matching aggregate `.ahb` aliases are absent from the repository and from
support accounting. The existing `.ahb` profile-alias validator accepts
selected one-subordinate and two-subordinate AHB interconnect contracts by
subordinate count, so no broad parser or generated-IAL1/IAL0 substrate blocker
is visible before alias implementation.

## Current-Code Probe

Two current-code probes parsed the shipped generic `.ppif` source text using
reserved `.ahb` source labels, without adding repository sources.

The one-subordinate probe used the text from
`ppif/ahb_interconnect_byte_lane_seq.ppif` with source label
`ppif/ahb_interconnect_byte_lane_seq.ahb`. It preserved:

```text
kind: protocol_intent.ahb_interconnect
source_object: fsmgen-ahb-interconnect-byte-lane-seq
intent_name: ahb_interconnect_byte_lane_seq
composition_child_count: 3
composition.byte_lane_propagation.selected: true
composition.seq_policy_propagation.selected: true
ahb_aggregate_profile_alias_deferred: removed
```

The two-subordinate probe used the text from
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif` with source label
`ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb`. It preserved:

```text
kind: protocol_intent.ahb_interconnect
source_object: fsmgen-ahb-interconnect-two-subordinate-byte-lane-seq
intent_name: ahb_interconnect_two_subordinate_byte_lane_seq
composition_child_count: 4
composition.byte_lane_propagation.selected: true
composition.seq_policy_propagation.selected: true
ahb_aggregate_profile_alias_deferred: removed
```

Both probes keep the true top-level `ahb_burst_seq_support_deferred` residue
for HBURST length/wrap semantics, BUSY-in-burst handling,
multi-word/register-bank progression, wrapping/incrementing address
progression beyond requester generation, and broader manager/subordinate
behavior.

The probes also exposed the selected alias-only report cleanup: generated
byte-lane `SEQ` subordinate child reports still mention `.ahb alias exposure`
inside `ahb_burst_seq_support_deferred` even under aggregate `.ahb` source
labels. `.760` must remove that alias-exposure wording for aggregate `SEQ`
`.ahb` alias report trees while preserving the generic `.ppif` source-surface
residue.

## Selected `.760` Implementation Owner

`.760` must add exactly the matching aggregate byte-lane in-word `SEQ` `.ahb`
aliases:

```text
ppif/ahb_interconnect_byte_lane_seq.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb
```

The one-subordinate alias must support-account as:

```text
entry_id: intent.ahb_profile_alias_interconnect_byte_lane_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_byte_lane_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 3
```

The two-subordinate alias must support-account as:

```text
entry_id: intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_seq_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

Both aliases must preserve:

- explicit `(profile ahb)`;
- source object ids and intent names from the mirrored generic `.ppif`
  sources;
- generated `.isf` review artifacts before generated `.fsm` review artifacts;
- aggregate `ahb_tb.fsm` and HDL entry module `ahb_tb`;
- `composition.byte_lane_propagation`;
- `composition.seq_policy_propagation`;
- child `narrow_transfer_policy`;
- child `transfer.seq_policy`;
- local-address-before-byte-lane and local-address-before-`SEQ` policies;
- subordinate-owned mapped-hit byte/halfword/word and byte/halfword in-word
  `SEQ` behavior; and
- interconnect-owned unmapped ERROR behavior.

Alias reports must remove `ahb_aggregate_profile_alias_deferred`,
`ahb_profile_alias_deferred`, and `ahb_subordinate_profile_alias_deferred`
from aggregate `.ahb` report trees, and must remove `.ahb alias exposure` from
embedded byte-lane `SEQ` child `ahb_burst_seq_support_deferred` details. The
generic aggregate byte-lane `SEQ` `.ppif` reports must keep those
source-surface alias residues.

## Validation And Rollback

`.760` should add focused profile-alias coverage, expected as:

```text
t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t
```

That coverage should verify both aliases parse, support-account, emit schedule
and semantic JSON with source identity, preserve generated review artifacts,
preserve `composition.byte_lane_propagation` and
`composition.seq_policy_propagation`, preserve child `narrow_transfer_policy`
and `transfer.seq_policy`, remove alias-only residue from aggregate alias
report trees, preserve generic `.ppif` source-surface residue, keep malformed
`.ahb` diagnostics fail-closed, and preserve existing word-only aggregate,
non-`SEQ` aggregate byte-lane, endpoint byte-lane `SEQ`, requester,
interconnect, support-accounting, capability-manifest, generated-artifact, and
HDL behavior.

Rollback is to remove the two `.ahb` alias source samples, their support
accounting entries, focused tests, alias-only child-residue cleanup, and
docs/Knowledge Map/mdBook updates. No broad parser or generator rollback
should be needed unless `.760` discovers a preservation regression not seen in
the selector probes.

## Explicit Deferrals

`.760` must not add HBURST forwarding to subordinates, HBURST-driven
length/wrap validation, BUSY-in-burst parking, multi-word/register-bank
progression, optional/property-gated AHB signals, legacy two-bit subordinate
`HRESP`, broader interconnect/decode, scoreboards, full-manager behavior,
direct backend behavior, verification-output generation, backend-language
variants, AXI/APB behavior, broader AHB behavior, or VHDL behavior.

## Validation

Closeout for `.759` is documentation-only plus targeted current-state probes:

```bash
perl -Iperl -MFSM::Adapter::IAL2::PPIF -MJSON::PP=encode_json -E 'local $/; open my $fh, "<", "ppif/ahb_interconnect_byte_lane_seq.ppif" or die $!; my $src=<$fh>; my $r=FSM::Adapter::IAL2::PPIF->new->parse_source($src, "ppif/ahb_interconnect_byte_lane_seq.ahb"); say encode_json({ok=>1, child_count=>$r->{report}{composition}{child_instance_count}, has_seq=>$r->{report}{composition}{seq_policy_propagation}{selected}?1:0});'
perl -Iperl -MFSM::Adapter::IAL2::PPIF -MJSON::PP=encode_json -E 'local $/; open my $fh, "<", "ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif" or die $!; my $src=<$fh>; my $r=FSM::Adapter::IAL2::PPIF->new->parse_source($src, "ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ahb"); say encode_json({ok=>1, child_count=>$r->{report}{composition}{child_instance_count}, has_seq=>$r->{report}{composition}{seq_policy_propagation}{selected}?1:0});'
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring.
