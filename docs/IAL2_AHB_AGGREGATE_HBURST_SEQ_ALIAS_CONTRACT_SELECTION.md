# IAL2 AHB Aggregate HBURST SEQ Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.771`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.771` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.772`, direct implementation of the matching
bounded public AHB aggregate HBURST-aware byte-lane `SEQ` `.ahb` profile
aliases.

The selected future sources are:

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

## Evidence Read

The selector read the `.770` aggregate HBURST-aware behavior record, `.769`
contract selection, `.768` readiness audit, `.767` selector, the endpoint
HBURST-aware `.ppif`/`.ahb` records, the aggregate byte-lane and aggregate
byte-lane `SEQ` `.ppif`/`.ahb` alias records, the shipped generic aggregate
HBURST sources, README, ROADMAP_V2, the AHB mdBook chapter, the feature
backlog, the active task tree, Memory, Knowledge Map, the current PPIF adapter,
`AhbInterconnect`, `RegressionCorpus`, `LanguageSurfaceSection`, the
capability/accounting boundaries, and focused AHB tests including
`t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t` and
`t/1489-ial2-ahb-interconnect-byte-lane-seq-profile-alias.t`.

Relevant decisions remain:

- `0014`, protocol/platform intent uses layered lowering;
- `0015`, protocol-specific extensions are profile aliases over IAL2;
- `0016`, `.ppif` is the first generic IAL2 container;
- `0018`, IAL contracts and the mdBook are backend-language-neutral; and
- `0003`, `0005`, `0006`, and `0007` for autonomous PNT, push gating,
  mdBook synchronization, and frozen legacy blobs.

## Current Probe Evidence

Both shipped generic aggregate sources are fully support-accounted:

```text
path=ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
success=1
module=ahb_tb
composition_child_count=3
entry_id=intent.ppif_ahb_interconnect_byte_lane_hburst_seq
source_kind=ppif
coverage=ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_pipeline_cli

path=ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
success=1
module=ahb_tb
composition_child_count=4
entry_id=intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq
source_kind=ppif
coverage=ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli
```

The generic `.ppif` reports intentionally keep aggregate source-surface alias
residue:

```text
ahb_aggregate_profile_alias_deferred:      present (top-level report)
ahb_subordinate_profile_alias_deferred:    present (embedded child report)
```

A reserved `.ahb` source-label parser probe using the same source text
currently succeeds, keeps the aggregate topology, and removes the aggregate and
embedded profile-alias residue:

```text
label=ppif/ahb_interconnect_byte_lane_hburst_seq.ahb
kind=protocol_intent.ahb_interconnect
composition_child_count=3
seq_mode=subordinate_owned_hburst_in_word_seq_policy
ahb_aggregate_profile_alias_deferred:      removed (top-level report)
ahb_subordinate_profile_alias_deferred:    removed (embedded child report)

label=ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb
kind=protocol_intent.ahb_interconnect
composition_child_count=4
seq_mode=subordinate_owned_hburst_in_word_seq_policy
ahb_aggregate_profile_alias_deferred:      removed (top-level report)
ahb_subordinate_profile_alias_deferred:    removed (embedded child report)
```

A temporary reserved `.ahb` CLI probe under the scratchpad directory also
`--check`-lowered to module `ahb_tb` with the expected child counts and emitted
schedule/report JSON, then was removed so the tree stays clean. Those temporary
aliases are not shipped public surfaces and have no support-accounting entry
because no tracked aggregate HBURST alias fixture exists yet.

This proves the shared `.ahb` profile-alias residue-suppression machinery,
already used by the endpoint HBURST-aware alias and by the aggregate byte-lane
and aggregate byte-lane `SEQ` aliases, generalizes to the aggregate HBURST
sources without any adapter code change. The selected implementation is
therefore data-only: two tracked `.ahb` fixtures plus support-accounting,
catalog, test, and docs entries.

## Why The Alias Comes Next

The matching aggregate `.ahb` aliases are the narrowest safe follow-on after
the generic aggregate HBURST-aware `.ppif` shipment. They match the established
AHB sequence:

```text
generic endpoint .ppif -> endpoint .ahb -> generic aggregate .ppif -> aggregate .ahb
```

Aggregate alias exposure is smaller than any new behavior because it adds no
parser, generator, report, residue-recognition, or wiring logic. It only
advertises the AHB profile on the aggregate HBURST sources through the tracked
suffix. It also comes before BUSY-in-burst parking, halfword/word burst `SEQ`,
multi-word/register-bank progression, wider/indefinite bursts,
optional/property-gated signals, broader AHB, direct backend,
verification-output, backend-language variants, AXI/APB, and VHDL work.

## Selected `.772` Scope

`.772` owns direct implementation of exactly the matching aggregate `.ahb`
profile aliases:

- add `ppif/ahb_interconnect_byte_lane_hburst_seq.ahb` mirroring the shipped
  generic `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif`;
- add `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb`
  mirroring the shipped generic
  `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif`;
- support-account the one-subordinate alias as
  `intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq` with coverage
  `ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_pipeline_cli`,
  module `ahb_tb`, `composition_child_count: 3`;
- support-account the two-subordinate alias as
  `intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq`
  with coverage
  `ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_pipeline_cli`,
  module `ahb_tb`, `composition_child_count: 4`;
- report `source_kind: ial2_profile_alias` and
  `expected_semantic_source_root_kind: top` for both aliases;
- keep generated review artifacts identical to the generic sources
  (`amba_requester.isf`/`.fsm`,
  `ahb_lite_subordinate_byte_lane_hburst_seq.isf`/`.fsm` or the
  status/control subordinate pair,
  `ahb_interconnect.isf`/`.fsm`, and aggregate `ahb_tb.fsm`);
- keep HDL entry `ahb_tb`, `composition.byte_lane_propagation`, and
  `composition.seq_policy_propagation` mode
  `subordinate_owned_hburst_in_word_seq_policy`, request-forwarding `burst`,
  child-local `HBURST_REGS`/`HBURST_STATUS`/`HBURST_CONTROL` fanout, child
  `bindings.bus.burst`, and child `transfer.seq_policy`;
- rely on the existing suffix-keyed suppression so the alias reports remove
  `ahb_aggregate_profile_alias_deferred` (top) and
  `ahb_subordinate_profile_alias_deferred` (embedded child) while the generic
  `.ppif` reports keep both;
- add focused coverage, expected as
  `t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t`, covering
  both one-subordinate and two-subordinate aliases and their generic parity;
- flip the two `.770` deferred-alias assertions in
  `t/1492-ial2-ahb-interconnect-byte-lane-hburst-seq.t` so they assert the
  shipped aliases exist rather than remain deferred;
- update `RegressionCorpus`, `LanguageSurfaceSection`, capability-manifest
  expectations, README, ROADMAP_V2, mdBook backlog/AHB chapter, behavior docs,
  Knowledge Map, task tree, and Memory; and
- run focused syntax/probe/tests plus doctrine closeout.

`.772` must preserve the existing word-only `.ppif/.ahb`, byte-lane
`.ppif/.ahb`, byte-lane `SEQ` `.ppif/.ahb`, endpoint HBURST-aware `.ppif/.ahb`,
generic aggregate HBURST-aware `.ppif`, requester, support-accounting,
generated-artifact, and HDL behavior except for the additive alias
fixtures/catalog/language-surface/docs entries and selected alias-only residue
cleanup.

## Explicit Non-Selections

`.772` must not add BUSY-in-burst parking, halfword/word burst `SEQ`, wider or
indefinite bursts, multi-word/register-bank progression, optional/property-gated
AHB signals, legacy two-bit subordinate `HRESP`, broader interconnect/decode,
scoreboards, full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, broader AHB behavior,
or VHDL behavior.

It must also not widen `supported-transfer`, make `seq-policy` valid outside the
selected byte-lane shape, change standalone/mismatched `SEQ` fail-closed
behavior, or change existing word-only/byte-lane/`SEQ`/endpoint-HBURST alias
behavior.

## Validation

Closeout for `.771` is documentation-only plus targeted current-state probes:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...parse_source(..., "ppif/ahb_interconnect_byte_lane_hburst_seq.ahb")...'
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring.

## Rollback

Rollback is documentation-only: remove this selector, its Knowledge Map fact
card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer
update, and regenerated Knowledge Map entries. No runtime behavior is affected.
`.772` will define its own implementation rollback if it proceeds.
