# IAL2 AHB Subordinate BUSY-Park `.ahb` Profile Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.777`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.777` selects the public contract for the
matching endpoint AHB subordinate BUSY-in-burst parking `.ahb` profile alias and
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.778`, the direct implementation of
that bounded alias fixture.

The selected future source is:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb
```

It must mirror the shipped generic BUSY-park source:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.776` shipped endpoint BUSY-park behavior, the shipped
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` source, the
endpoint HBURST-aware `.ahb` alias precedent
`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb` (shipped by `.766`, selected
by `.765`), the aggregate HBURST `.ahb` alias precedent (`.771`/`.772`), the PPIF
adapter alias-residue suppression (`perl/FSM/Adapter/IAL2/PPIF.pm:89`–`:96`,
`:146`–`:148`), the `AhbSubordinate` residue and policy report owners, support
accounting (`RegressionCorpus`, `t/248` protocol count `292` / total `333`;
capability manifest via `t/297`), the language surface
(`LanguageSurfaceSection`), focused AHB tests (`t/1491` endpoint HBURST alias,
`t/1494` endpoint BUSY-park), README, ROADMAP_V2, the mdBook AHB chapter
(`docs/book/src/16c-ial2-ahb.md`) and backlog (`docs/book/src/14-feature-backlog.md`),
the task tree, Memory, and Knowledge Map.

Relevant decisions remain:

- `0014`, protocol/platform intent uses layered lowering;
- `0015`, protocol-specific extensions are profile aliases over IAL2;
- `0016`, `.ppif` is the first generic IAL2 container;
- `0018`, IAL contracts and the mdBook are backend-language-neutral; and
- `0003`, `0005`, `0006`, and `0007` for autonomous PNT, push gating,
  mdBook synchronization, and frozen legacy blobs.

## Current Probe Evidence

The shipped generic BUSY-park source is fully support-accounted:

```text
path=ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
success=1
entry_id=intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
source_kind=ppif
coverage=ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
```

Its schedule/report JSON preserves the selected BUSY-park HBURST shape and keeps
source-surface alias residue:

```text
schema=fsmgen.ial2.protocol_intent.ahb_subordinate.v1
ial1=ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf
ial0=ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm
seq_mode=hburst_in_word_progressive
parks_on=[busy]
clears_on=[reset, idle, error, new_nonseq, final_beat]
ahb_subordinate_profile_alias_deferred: present
ahb_burst_seq_support_deferred: ... .ahb alias exposure ...
```

A reserved `.ahb` source-label CLI probe using the same source text (copied to a
scratchpad `*.ahb` file, not a tracked fixture) currently strict-checks and
lowers with the endpoint profile-alias residue removed, while preserving the
BUSY-park policy shape:

```text
label=<scratchpad>/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb
check_success=1
schema=fsmgen.ial2.protocol_intent.ahb_subordinate.v1
ial1=ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf
seq_mode=hburst_in_word_progressive
parks_on=[busy]
clears_on=[reset, idle, error, new_nonseq, final_beat]
ahb_subordinate_profile_alias_deferred: removed
ahb_burst_seq_support_deferred: no ".ahb alias exposure" wording
support_accounting: matched=false (no tracked alias fixture yet)
```

`support_accounting.matched` is `false` only because no tracked alias fixture and
catalog entry exist yet; that is `.778`'s job. The removal of
`ahb_subordinate_profile_alias_deferred` and the `.ahb alias exposure` residue
wording is driven purely by the suffix-keyed suppression
(`_is_ahb_profile_alias_source`, which matches any `*.ahb` label, and
`_remove_ahb_seq_alias_exposure_from_residue`), so **no adapter change is
required** and `.778` is data-only.

## Why The Alias Comes Next

The matching endpoint `.ahb` alias is the narrowest safe follow-on after the
generic BUSY-park endpoint `.ppif` shipment. It matches the established AHB
sequence used for every prior endpoint feature:

```text
generic endpoint .ppif -> matching endpoint .ahb -> aggregate propagation
```

Endpoint alias exposure is smaller than aggregate BUSY-parking propagation
because it adds no subordinate-local parking forwarding through interconnects,
no aggregate source families, no aggregate support identities, no top-level/child
report propagation, and no aggregate residue movement. It also comes before
aggregate BUSY-parking, requester-side BUSY insertion, halfword/word burst
`SEQ`, multi-word/register-bank progression, wider/indefinite bursts,
optional/property-gated signals, broader AHB, direct backend,
verification-output, backend-language variants, AXI/APB, and VHDL work.

## Selected `.778` Scope

`.778` owns direct implementation of exactly the matching endpoint BUSY-park
`.ahb` profile alias:

```text
alias path:       ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb
support identity:  intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park
coverage key:      ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:       ial2_profile_alias
expected module:   ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
```

- add `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb` as a
  byte-identical mirror of the shipped generic BUSY-park `.ppif` source;
- support-account it in `RegressionCorpus` as
  `intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park` with
  coverage key
  `ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`,
  `family: protocol_fixture`, `classification: supported_smoke`, `source_kind:
  ial2_profile_alias`, `expected_module_name:
  ahb_lite_subordinate_byte_lane_hburst_seq_busy_park`,
  `expected_semantic_source_root_kind: fsm`;
- keep generated review artifacts
  `ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf` and
  `ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm`;
- keep HDL module `ahb_lite_subordinate_byte_lane_hburst_seq_busy_park`;
- preserve `transfer.seq_policy.mode = hburst_in_word_progressive`,
  `parks_on = [busy]`, `clears_on = [reset, idle, error, new_nonseq,
  final_beat]`, supported `WRAP4`/`INCR4` metadata, and the selected byte-lane
  policy;
- rely on the existing suffix-keyed suppression to remove
  `ahb_subordinate_profile_alias_deferred` and the `.ahb alias exposure` wording
  from the alias report while the generic `.ppif` report keeps them (no adapter
  change);
- add focused coverage
  `t/1495-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park-profile-alias.t`,
  asserting the alias parses, strict-checks, generates the expected module and
  review artifacts, preserves the `parks_on`/`clears_on` BUSY-park report shape,
  drops the endpoint profile-alias residue, and matches the generic BUSY-park
  `.ppif` behavior byte-for-byte except for the alias-only residue cleanup;
- extend `t/248` corpus accounting (protocol entries `292 → 293`, total
  `333 → 334`) and the `t/297` capability manifest;
- update `LanguageSurfaceSection`, README, ROADMAP_V2, mdBook backlog/AHB
  chapter, a behavior doc
  (`docs/IAL2_AHB_SUBORDINATE_BUSY_PARK_PROFILE_ALIAS_BEHAVIOR.md`), Knowledge
  Map, task tree, and Memory; and
- run focused syntax/probe/tests plus doctrine closeout.

`.778` must preserve the existing word-only `.ppif/.ahb`, byte-lane
`.ppif/.ahb`, byte-lane `SEQ` `.ppif/.ahb`, endpoint HBURST `.ppif/.ahb`,
generic BUSY-park `.ppif`, requester, aggregate `.ppif/.ahb`,
support-accounting, generated-artifact, and HDL behavior except for the additive
alias fixture/catalog/language-surface/docs entries and the selected alias-only
residue cleanup.

## Explicit Non-Selections

`.778` must not add aggregate BUSY-parking, requester-side BUSY insertion,
aggregate HBURST BUSY-park propagation, halfword/word burst `SEQ`, wider or
indefinite bursts, multi-word/register-bank progression, optional/property-gated
AHB signals, legacy two-bit subordinate `HRESP`, broader interconnect/decode,
scoreboards, full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, broader AHB behavior,
or VHDL behavior.

It must also not widen `supported-transfer`, change the `parked-transfer`
classification, make `seq-policy` valid outside the selected byte-lane shape,
change standalone/mismatched `SEQ` fail-closed behavior, or change existing
word-only/byte-lane/SEQ/HBURST alias behavior.

## Validation

Closeout for `.777` is documentation-only plus targeted current-state probes:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
# reserved .ahb-label probe (scratchpad copy, not a tracked fixture)
./bin/fsmgen --quiet --strict --check --json <scratchpad>/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --emit-schedule-json <scratchpad>/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb
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
