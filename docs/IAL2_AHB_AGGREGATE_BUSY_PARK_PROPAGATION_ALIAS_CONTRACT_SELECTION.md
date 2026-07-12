# IAL2 AHB Aggregate BUSY-Park Propagation Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.783`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.783` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.784`, direct implementation of the matching
bounded public AHB aggregate BUSY-park HBURST-aware byte-lane `SEQ` `.ahb`
profile aliases.

The selected future sources are:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

They must mirror the shipped generic sources:

```text
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.782` aggregate BUSY-park behavior record and its `.781`
contract selection / `.780` readiness audit; the aggregate HBURST-aware `.ahb`
alias lineage (`.771` contract selection / `.772` behavior); the endpoint
BUSY-park `.ahb` alias lineage (`.777` contract selection / `.778` behavior);
the shipped generic aggregate BUSY-park `.ppif` sources; `AhbInterconnect`,
`AhbSubordinate`, and the PPIF adapter; `RegressionCorpus`,
`LanguageSurfaceSection`, and the capability/accounting boundaries; the focused
AHB tests including
`t/1496-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park.t`,
`t/1493-ial2-ahb-interconnect-byte-lane-hburst-seq-profile-alias.t`, and
`t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t`;
README, ROADMAP_V2, the AHB mdBook chapter, the feature backlog, the active task
tree, Memory, Knowledge Map, and relevant decisions.

Relevant decisions remain `0014`, `0015`, `0016`, `0018`, and `0003`/`0005`/
`0006`/`0007`.

## Current Probe Evidence

Both shipped generic aggregate BUSY-park sources are fully support-accounted:

```text
path=ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
success=1
module=ahb_tb
composition_child_count=3
entry_id=intent.ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park
source_kind=ppif
coverage=ial2_ppif_ahb_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli

path=ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif
success=1
module=ahb_tb
composition_child_count=4
entry_id=intent.ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park
source_kind=ppif
coverage=ial2_ppif_ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
```

The generic `.ppif` reports keep aggregate source-surface alias residue
(`ahb_aggregate_profile_alias_deferred` at top level and
`ahb_subordinate_profile_alias_deferred` on each embedded child).

A reserved `.ahb` source-label parser probe using the same source text currently
succeeds, keeps the aggregate topology and the child park, and removes both
profile-alias residues:

```text
label=ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb
kind=protocol_intent.ahb_interconnect
composition_child_count=3
seq_mode=subordinate_owned_hburst_in_word_seq_policy
child seq_policy.parks_on=[busy]
ahb_aggregate_profile_alias_deferred:      removed (top-level report)
ahb_subordinate_profile_alias_deferred:    removed (embedded child report)

label=ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb
kind=protocol_intent.ahb_interconnect
composition_child_count=4
seq_mode=subordinate_owned_hburst_in_word_seq_policy
child seq_policy.parks_on=[busy],[busy]
ahb_aggregate_profile_alias_deferred:      removed (top-level report)
ahb_subordinate_profile_alias_deferred:    removed (embedded child report)
```

This proves the shared `.ahb` profile-alias residue-suppression machinery —
already used by the endpoint HBURST-aware and endpoint BUSY-park aliases and by
the aggregate byte-lane / byte-lane `SEQ` / HBURST-aware `SEQ` aliases —
generalizes to the aggregate BUSY-park sources with no adapter code change and
preserves `parks_on = [busy]` / BUSY-free `clears_on`. The selected
implementation is therefore data-only: two tracked `.ahb` fixtures plus
support-accounting, catalog, test, and docs entries.

## Why The Alias Comes Next

The matching aggregate BUSY-park `.ahb` aliases are the narrowest safe follow-on
after the generic aggregate BUSY-park `.ppif` shipment, matching the established
AHB sequence:

```text
generic endpoint .ppif -> endpoint .ahb -> generic aggregate .ppif -> aggregate .ahb
```

which the byte-lane, byte-lane `SEQ`, HBURST-aware `SEQ`, and endpoint BUSY-park
families all followed. Aggregate alias exposure is smaller than any new behavior
because it adds no parser, generator, report, residue-recognition, or wiring
logic; it only advertises the AHB profile on the shipped aggregate BUSY-park
sources through the tracked suffix. It comes before requester-side BUSY
insertion, halfword/word burst `SEQ`, multi-word/register-bank progression,
wider/indefinite bursts, optional/property-gated signals, broader AHB, direct
backend, verification-output, backend-language variants, AXI/APB, and VHDL work.

## Selected `.784` Scope

`.784` owns direct implementation of exactly the matching aggregate BUSY-park
`.ahb` profile aliases:

- add `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb` mirroring the
  shipped generic
  `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif`;
- add `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb`
  mirroring the shipped generic
  `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`;
- support-account the one-subordinate alias as
  `intent.ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park` with
  coverage
  `ial2_ahb_profile_alias_interconnect_byte_lane_hburst_seq_busy_park_pipeline_cli`,
  module `ahb_tb`, `composition_child_count: 3`;
- support-account the two-subordinate alias as
  `intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park`
  with coverage
  `ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
  module `ahb_tb`, `composition_child_count: 4`;
- report `source_kind: ial2_profile_alias` and
  `expected_semantic_source_root_kind: top` for both aliases;
- keep generated review artifacts identical to the generic sources, keep HDL
  entry `ahb_tb`, `composition.byte_lane_propagation`, and
  `composition.seq_policy_propagation` mode
  `subordinate_owned_hburst_in_word_seq_policy` with each child `seq_policy`
  reporting `parks_on = [busy]` and BUSY-free `clears_on`;
- rely on the existing suffix-keyed suppression so the alias reports remove
  `ahb_aggregate_profile_alias_deferred` (top) and
  `ahb_subordinate_profile_alias_deferred` (embedded child) while the generic
  `.ppif` reports keep both;
- add focused coverage, expected as
  `t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t`,
  covering both one-subordinate and two-subordinate aliases, their generic
  parity, and the preserved `parks_on`/`clears_on` report;
- update `RegressionCorpus`, `LanguageSurfaceSection`, capability-manifest
  expectations, README, ROADMAP_V2, mdBook backlog/AHB chapter, behavior docs,
  Knowledge Map, task tree, and Memory (the aggregate BUSY-park `.ppif` source
  count and the `.ahb` boundary sentence move from "deferred" to "shipped"); and
- run focused syntax/probe/tests plus doctrine closeout, with the slow
  two-subordinate `--check` behind the RAM guard or equivalent monitoring.

`.784` must preserve the existing word-only, byte-lane, byte-lane `SEQ`,
endpoint HBURST-aware, endpoint BUSY-park, aggregate byte-lane, aggregate
byte-lane `SEQ`, aggregate HBURST-aware, and aggregate BUSY-park generic `.ppif`
behavior and their aliases except for the additive alias
fixtures/catalog/language-surface/docs entries and selected alias-only residue
cleanup.

## Explicit Non-Selections

`.784` must not add requester-side BUSY insertion, halfword/word burst `SEQ`,
wider or indefinite bursts, multi-word/register-bank progression,
optional/property-gated AHB signals, legacy two-bit subordinate `HRESP`, broader
interconnect/decode, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, broader AHB behavior, or VHDL behavior. It must not widen
`supported-transfer`, make `seq-policy` or `parked-transfer` valid outside the
selected byte-lane HBURST shape, change standalone/mismatched `SEQ` or drifting
BUSY fail-closed behavior, or change existing alias behavior.

## Validation

Closeout for `.783` is documentation-only plus targeted current-state probes:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...parse_source(..., "ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb")...'
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
`.784` will define its own implementation rollback if it proceeds.
