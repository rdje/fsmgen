# IAL2 Post-AHB HBURST SEQ PPIF Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.765`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.765` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.766`, direct implementation of the
matching bounded public AHB HBURST-aware byte-lane `SEQ` subordinate `.ahb`
profile alias.

The selected future source is:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
```

It must mirror the shipped generic source:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.764` HBURST-aware behavior record, `.763` contract
selection, `.762` readiness audit, `.761` previous selector, endpoint byte-lane
`SEQ` `.ppif` and `.ahb` alias records, aggregate byte-lane `SEQ` `.ppif` and
`.ahb` alias records, the shipped HBURST source, README, ROADMAP_V2, the AHB
mdBook chapter, the feature backlog, the active task tree, Memory, Knowledge
Map, the current PPIF parser, `AhbSubordinate`, RegressionCorpus,
LanguageSurfaceSection, capability/accounting boundaries, and focused AHB
tests including `t/1490-ial2-ahb-subordinate-byte-lane-hburst-seq.t` and
`t/1487-ial2-ahb-subordinate-byte-lane-seq-profile-alias.t`.

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
path=ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
success=1
module=ahb_lite_subordinate_byte_lane_hburst_seq
entry_id=intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq
source_kind=ppif
coverage=ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_pipeline_cli
```

Its schedule/report JSON preserves the selected HBURST-aware shape:

```text
schema=fsmgen.ial2.protocol_intent.ahb_subordinate.v1
ial1=ahb_lite_subordinate_byte_lane_hburst_seq.isf
ial0=ahb_lite_subordinate_byte_lane_hburst_seq.fsm
burst=HBURST/3
seq_mode=hburst_in_word_progressive
supported_hburst=WRAP4,INCR4
```

The generic `.ppif` report intentionally keeps source-surface alias residue:

```text
ahb_subordinate_profile_alias_deferred: present
ahb_burst_seq_support_deferred: ... .ahb alias exposure, aggregate propagation ...
```

A reserved `.ahb` source-label parser probe using the same source text
currently succeeds and removes the endpoint profile-alias residue:

```text
label=ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb
kind=protocol_intent.ahb_subordinate
mode=subordinate
ial1=ahb_lite_subordinate_byte_lane_hburst_seq.isf
schema=fsmgen.ial2.protocol_intent.ahb_subordinate.v1
profile=ahb
ahb_subordinate_profile_alias_deferred: removed
ahb_burst_seq_support_deferred: no ".ahb alias exposure" wording
```

A temporary CLI `.ahb` probe under `/tmp` also strict-checked and emitted
schedule/report JSON successfully:

```text
check_success=1
module=ahb_lite_subordinate_byte_lane_hburst_seq
schedule_schema=fsmgen.ial2.protocol_intent.ahb_subordinate.v1
ahb_subordinate_profile_alias_deferred: removed
ahb_burst_seq_support_deferred: no ".ahb alias exposure" wording
```

That temporary alias is not a shipped public surface and has no
support-accounting entry because no tracked alias fixture exists yet.

## Why The Alias Comes Next

The matching `.ahb` alias is the narrowest safe follow-on after the generic
HBURST-aware endpoint `.ppif` shipment. It matches the established AHB
sequence:

```text
generic endpoint .ppif -> matching endpoint .ahb -> aggregate propagation
```

Endpoint alias exposure is smaller than aggregate HBURST propagation because
it does not add subordinate-local HBURST forwarding through interconnects,
aggregate source families, aggregate support identities, top-level/child
report propagation, or aggregate residue movement. It also comes before
BUSY-in-burst parking, halfword/word burst `SEQ`, multi-word/register-bank
progression, wider/indefinite bursts, optional/property-gated signals,
broader AHB, direct backend, verification-output, backend-language variants,
AXI/APB, and VHDL work.

## Selected `.766` Scope

`.766` owns direct implementation of exactly the matching endpoint `.ahb`
profile alias:

- add `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb` mirroring the
  shipped generic `.ppif` source;
- support-account it as
  `intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq`;
- use coverage key
  `ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_pipeline_cli`;
- report `source_kind: ial2_profile_alias`;
- keep generated review artifacts
  `ahb_lite_subordinate_byte_lane_hburst_seq.isf` and
  `ahb_lite_subordinate_byte_lane_hburst_seq.fsm`;
- keep HDL module `ahb_lite_subordinate_byte_lane_hburst_seq`;
- preserve `bindings.bus.burst`, `transfer.seq_policy.mode =
  hburst_in_word_progressive`, supported `WRAP4`/`INCR4` metadata, and the
  selected byte-lane policy;
- remove endpoint profile-alias residue from the alias report;
- narrow the alias report's `ahb_burst_seq_support_deferred` detail so `.ahb`
  alias exposure is no longer listed as future work for the alias report;
- preserve the generic `.ppif` report's source-surface alias residue;
- add focused coverage, expected as
  `t/1491-ial2-ahb-subordinate-byte-lane-hburst-seq-profile-alias.t`;
- update RegressionCorpus, LanguageSurfaceSection, capability-manifest
  expectations, README, ROADMAP_V2, mdBook backlog/AHB chapter as needed,
  behavior docs, Knowledge Map, task tree, and Memory; and
- run focused syntax/probe/tests plus doctrine closeout.

`.766` must preserve the existing word-only `.ppif/.ahb`, byte-lane
`.ppif/.ahb`, byte-lane `SEQ` `.ppif/.ahb`, generic HBURST-aware `.ppif`,
requester, aggregate `.ppif/.ahb`, support-accounting, generated-artifact,
and HDL behavior except for the additive alias fixture/catalog/language-surface
docs entries and selected alias-only residue cleanup.

## Explicit Non-Selections

`.766` must not add aggregate HBURST forwarding, aggregate HBURST propagation,
BUSY-in-burst parking, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional/property-gated AHB signals,
legacy two-bit subordinate `HRESP`, broader interconnect/decode, scoreboards,
full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, broader AHB behavior,
or VHDL behavior.

It must also not widen `supported-transfer`, make `seq-policy` valid outside
the selected byte-lane shape, change standalone/mismatched `SEQ` fail-closed
behavior, or change existing word-only/byte-lane/SEQ alias behavior.

## Validation

Closeout for `.765` is documentation-only plus targeted current-state probes:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
perl -Iperl -MFSM::Adapter::IAL2::PPIF -e '...parse_source(..., "ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb")...'
./bin/fsmgen --quiet --strict --check --json /tmp/fsmgen-hburst-alias-probe.ahb
./bin/fsmgen --quiet --emit-schedule-json /tmp/fsmgen-hburst-alias-probe.ahb
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
