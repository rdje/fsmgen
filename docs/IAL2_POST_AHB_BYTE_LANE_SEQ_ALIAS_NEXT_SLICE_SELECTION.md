# IAL2 Post-AHB Byte-Lane SEQ Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.755`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.755` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.756`, a no-behavior readiness audit for
bounded AHB aggregate byte-lane in-word `SEQ` propagation.

The selected next owner must audit whether the already shipped endpoint
`SEQ` policy can be propagated through the selected one-requester/one-
subordinate and one-requester/two-subordinate aggregate AHB topologies before
any aggregate source, report, support-accounting, generated artifact, or HDL
behavior changes.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.754` alias behavior, `.753` selector, `.752` generic
`SEQ` behavior, `.751` contract selection, `.750` readiness audit, shipped AHB
requester/subordinate/interconnect/aggregate `.ppif` and `.ahb` behavior
records, the aggregate byte-lane readiness/contract/behavior records, the
generic and alias byte-lane `SEQ` sources, README, ROADMAP_V2, the AHB mdBook
chapter, the feature backlog, the active task tree, Memory, the Knowledge Map,
the current PPIF parser, RegressionCorpus, LanguageSurfaceSection, and focused
AHB tests.

Relevant decisions remain:

- `0014`, protocol/platform intent uses layered lowering;
- `0015`, protocol-specific extensions are profile aliases over IAL2;
- `0016`, `.ppif` is the first generic IAL2 container;
- `0018`, IAL contracts and the mdBook are backend-language-neutral; and
- `0003`, `0005`, `0006`, and `0007` for autonomous PNT, push gating,
  mdBook synchronization, and frozen legacy blobs.

## Current Probe Evidence

The shipped endpoint alias now exposes the selected `SEQ` policy and support
identity:

```text
path=ppif/ahb_lite_subordinate_byte_lane_seq.ahb
seq_policy=in_word_progressive
entry_id=intent.ahb_profile_alias_subordinate_byte_lane_seq
source_kind=ial2_profile_alias
coverage=ial2_ahb_profile_alias_subordinate_byte_lane_seq_pipeline_cli
```

Its remaining `ahb_burst_seq_support_deferred` detail no longer lists `.ahb`
alias exposure, but still lists true future work including aggregate
propagation, HBURST length/wrap semantics, BUSY-in-burst behavior,
multi-word/register-bank progression, direct backend, verification-output,
backend-language variants, AXI/APB, broader AHB, and VHDL.

The current aggregate byte-lane sources still instantiate the non-`SEQ`
byte-lane subordinate transfer:

```text
ppif/ahb_interconnect_byte_lane.ppif:
  (ahb-subordinate ahb_lite_subordinate_byte_lane ...)
  (transfer ahb_lite_byte_lane_access ...)

ppif/ahb_interconnect_two_subordinate_byte_lane.ppif:
  (ahb-subordinate ahb_status_subordinate_byte_lane ...)
  (transfer ahb_lite_byte_lane_access ...)
  (ahb-subordinate ahb_control_subordinate_byte_lane ...)
  (transfer ahb_lite_byte_lane_access ...)
```

Current aggregate byte-lane schedule probes still carry
`ahb_burst_seq_support_deferred` at both top-level and generated child-report
surfaces. The one-subordinate aggregate report says:

```text
The interconnect decodes active transfers by HTRANS != IDLE and leaves burst
SEQ continuation policy, wrapping/incrementing burst address progression
beyond requester generation, and broader manager/subordinate behavior to
future work.
```

The generated child reports still name `ahb_lite_subordinate_byte_lane`,
`ahb_status_subordinate_byte_lane`, and `ahb_control_subordinate_byte_lane`;
no current aggregate source or report names
`ahb_lite_subordinate_byte_lane_seq`,
`ahb_status_subordinate_byte_lane_seq`, or
`ahb_control_subordinate_byte_lane_seq`.

## Why Aggregate SEQ Readiness Comes Next

Aggregate `SEQ` propagation is now the narrowest AHB follow-on after the
endpoint `SEQ` `.ppif` and matching `.ahb` alias have both shipped. It matches
the established AHB ordering:

```text
endpoint .ppif -> endpoint .ahb -> aggregate propagation readiness
```

It is narrower than HBURST length/wrap semantics, BUSY-in-burst parking,
multi-word/register-bank progression, optional/property-gated AHB signals,
legacy two-bit subordinate `HRESP`, broader interconnect/decode, scoreboards,
full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB, broader AHB, or VHDL.

It is still not safe to select direct implementation in this leaf. The
aggregate `SEQ` family has more contract questions than the endpoint alias:

- whether the public generic source names should be
  `ppif/ahb_interconnect_byte_lane_seq.ppif` and
  `ppif/ahb_interconnect_two_subordinate_byte_lane_seq.ppif`;
- whether one-subordinate and two-subordinate aggregate sources should be
  selected together, as with byte-lane propagation;
- whether two-subordinate child object names should become
  `ahb_status_subordinate_byte_lane_seq` and
  `ahb_control_subordinate_byte_lane_seq`;
- whether aggregate reports add a new `composition.seq_policy_propagation`
  block, extend `composition.byte_lane_propagation`, or only copy child
  `transfer.seq_policy`;
- which top-level and child `ahb_burst_seq_support_deferred` wording moves
  from aggregate-propagation residue to true HBURST/BUSY/multi-word residue;
- how matching aggregate `.ahb` aliases should be sequenced after generic
  `.ppif` behavior; and
- which focused tests/probes preserve existing word-only aggregate,
  byte-lane aggregate, endpoint `SEQ`, and alias behavior.

Those questions need a readiness audit before a public contract selector or
implementation slice.

## Selected `.756` Scope

`.756` owns a no-behavior readiness audit for bounded AHB aggregate byte-lane
in-word `SEQ` propagation.

The audit must read the endpoint `SEQ` behavior and alias behavior, aggregate
byte-lane propagation behavior, current aggregate sources and generated
reports, PPIF parser/generator support, support-accounting catalog,
language-surface/capability manifest, focused AHB tests, README, ROADMAP_V2,
mdBook, task tree, Memory, Knowledge Map, and relevant decisions.

The audit must decide whether the current generated-IAL1/IAL0 substrate is
ready for aggregate `SEQ` source families, identify any lower-layer blocker,
and either select the next no-behavior public contract selector or route a
narrow prerequisite. It must record expected source/report/residue questions,
validation strategy, rollback boundary, docs to update, and explicit
deferrals.

## Explicit Non-Selections

`.755` and `.756` must not add aggregate `SEQ` sources or aliases, change
parser/generator behavior, change support-accounting entries, change
capability-manifest output, change existing source samples, change schedule,
check, or semantic JSON behavior, change generated artifacts, change
HDL/runtime behavior, add HBURST forwarding to subordinates, implement
HBURST-driven length/wrap validation, add BUSY-in-burst parking, add
multi-word/register-bank progression, add optional/property-gated AHB signals,
add legacy two-bit subordinate `HRESP`, broaden interconnect/decode, add
scoreboards, add full-manager behavior, direct backend behavior,
verification-output generation, backend-language variants, AXI/APB behavior,
broader AHB behavior, or VHDL behavior.

## Validation

Closeout for `.755` is documentation-only plus targeted current-state probes:

```bash
rg -n 'ahb_lite_subordinate_byte_lane_seq|seq-policy|ahb_lite_byte_lane_seq_access|ahb_lite_byte_lane_access|ahb-subordinate' ppif/ahb_interconnect_byte_lane.ppif ppif/ahb_interconnect_two_subordinate_byte_lane.ppif ppif/ahb_interconnect_byte_lane.ahb ppif/ahb_interconnect_two_subordinate_byte_lane.ahb ppif/ahb_lite_subordinate_byte_lane_seq.ppif ppif/ahb_lite_subordinate_byte_lane_seq.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_seq.ahb
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
