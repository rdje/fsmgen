# IAL2 Post-AHB Byte-Lane SEQ Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.753`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.753` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.754`, direct implementation of the
matching bounded public AHB byte-lane in-word `SEQ` subordinate `.ahb`
profile alias.

The selected future source is:

```text
ppif/ahb_lite_subordinate_byte_lane_seq.ahb
```

It must mirror the shipped generic source:

```text
ppif/ahb_lite_subordinate_byte_lane_seq.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.752` behavior record, `.751` contract selection, `.750`
readiness audit, shipped AHB requester/subordinate/interconnect/aggregate
`.ppif` and `.ahb` behavior records, the shipped
`ppif/ahb_lite_subordinate_byte_lane_seq.ppif` source, the AHB source-fact
inventory, README, ROADMAP_V2, the AHB mdBook chapter, the feature backlog,
the active task tree, Memory, the Knowledge Map, the current PPIF parser,
AHB subordinate/interconnect generators, RegressionCorpus,
LanguageSurfaceSection, capability-manifest/accounting tests, and focused AHB
tests including `t/1486-ial2-ahb-subordinate-byte-lane-seq.t`.

Relevant decisions remain:

- `0014`, protocol/platform intent uses layered lowering;
- `0015`, protocol-specific extensions are profile aliases over IAL2;
- `0016`, `.ppif` is the first generic IAL2 container;
- `0018`, IAL contracts and the mdBook are backend-language-neutral; and
- `0003`, `0005`, `0006`, and `0007` for autonomous PNT, push gating,
  mdBook synchronization, and frozen legacy blobs.

## Current Probe Evidence

The shipped generic source is fully support-accounted:

```text
path=ppif/ahb_lite_subordinate_byte_lane_seq.ppif
success=1
module=ahb_lite_subordinate_byte_lane_seq
entry_id=intent.ppif_ahb_lite_subordinate_byte_lane_seq
source_kind=ppif
coverage=ial2_ppif_ahb_lite_subordinate_byte_lane_seq_pipeline_cli
```

A temporary `.ahb` copy of that same source currently lowers and reports the
selected `transfer.seq_policy`, which shows there is no broad generated-IAL1 or
generated-IAL0 substrate blocker:

```text
path=/tmp/fsmgen-ahb-lite-subordinate-byte-lane-seq.ahb
success=1
module=ahb_lite_subordinate_byte_lane_seq
entry_id=<none>
source_kind=<none>
coverage=<none>
seq_policy=in_word_progressive
```

That temporary alias is not a shipped public surface. It lacks a
support-accounting entry because no tracked alias fixture exists yet. Its
report also still leaves the `ahb_burst_seq_support_deferred` detail saying
`.ahb alias exposure` remains future work, even though endpoint profile-alias
residue is already removed for `.ahb` source labels. A public alias slice must
therefore add the tracked source and catalog/language-surface entries and
make the alias report residue stop naming `.ahb alias exposure` as deferred
for the alias report.

## Why The Alias Comes Next

The `.ahb` alias is the narrowest safe follow-on after the generic byte-lane
in-word `SEQ` `.ppif` shipment.

It matches the established AHB sequence:

```text
generic endpoint .ppif -> matching endpoint .ahb -> aggregate propagation -> matching aggregate .ahb
```

The same sequence was used for word-only subordinate behavior and byte-lane
narrow-transfer behavior. Endpoint alias exposure is smaller than aggregate
`SEQ` propagation because it does not introduce child-report propagation,
aggregate top wiring, one-subordinate/two-subordinate source families,
aggregate support identities, or nested aggregate residue cleanup.

Aggregate propagation remains important, but it should start after the
endpoint alias report is public, support-accounted, and residue-clean. That
keeps the next aggregate contract from mixing source-surface exposure with
topology/report propagation.

## Selected `.754` Scope

`.754` owns direct implementation of exactly the matching endpoint `.ahb`
profile alias:

- add `ppif/ahb_lite_subordinate_byte_lane_seq.ahb` mirroring the shipped
  generic `.ppif` source;
- support-account it as
  `intent.ahb_profile_alias_subordinate_byte_lane_seq`;
- use coverage key
  `ial2_ahb_profile_alias_subordinate_byte_lane_seq_pipeline_cli`;
- report `source_kind: ial2_profile_alias`;
- keep generated review artifacts
  `ahb_lite_subordinate_byte_lane_seq.isf` and
  `ahb_lite_subordinate_byte_lane_seq.fsm`;
- keep HDL module `ahb_lite_subordinate_byte_lane_seq`;
- preserve `transfer.seq_policy` and `narrow_transfer_policy`;
- remove endpoint profile-alias residue from the alias report;
- narrow the alias report's `ahb_burst_seq_support_deferred` detail so `.ahb`
  alias exposure is no longer listed as future work for the alias report;
- preserve the generic `.ppif` report's source-surface alias residue;
- add focused coverage, expected as
  `t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t`;
- update RegressionCorpus, LanguageSurfaceSection, capability-manifest
  expectations, README, ROADMAP_V2, mdBook backlog/AHB chapter as needed,
  behavior docs, Knowledge Map, task tree, and Memory; and
- run focused syntax/probe/tests plus doctrine closeout.

`.754` must preserve the existing word-only `.ppif/.ahb`, original byte-lane
`.ppif/.ahb`, generic byte-lane `SEQ` `.ppif`, requester, interconnect,
aggregate, support-accounting, generated-artifact, and HDL behavior except for
the additive alias fixture/catalog/language-surface/docs entries and the
selected alias-only residue cleanup.

## Explicit Non-Selections

`.754` must not add aggregate `SEQ` propagation, aggregate `.ahb` aliases for
`SEQ`, HBURST forwarding to subordinates, HBURST-driven length/wrap
validation, BUSY-in-burst parking, multi-word/register-bank progression,
optional/property-gated AHB signals, legacy two-bit subordinate `HRESP`,
broader interconnect/decode, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, broader AHB behavior, or VHDL behavior.

It must also not widen `supported-transfer`, make `seq-policy` valid outside
the selected byte-lane shape, change standalone `SEQ` fail-closed behavior, or
change the existing word-only/byte-lane alias behavior.

## Validation

Closeout for `.753` is documentation-only plus targeted current-state probes:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_seq.ppif
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-ahb-lite-subordinate-byte-lane-seq.ahb
./bin/fsmgen --quiet --emit-schedule-json /tmp/fsmgen-ahb-lite-subordinate-byte-lane-seq.ahb
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
