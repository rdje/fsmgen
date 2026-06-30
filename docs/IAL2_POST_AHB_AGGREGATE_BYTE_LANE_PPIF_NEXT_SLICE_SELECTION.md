# IAL2 Post-AHB Aggregate Byte-Lane PPIF Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.744`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.744` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.745`, direct implementation of the
matching bounded public AHB aggregate byte-lane `.ahb` profile aliases.

The selected future sources are:

```text
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

Both aliases mirror the shipped generic aggregate byte-lane `.ppif` sources:

```text
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

The generic aggregate byte-lane `.ppif` sources now ship with:

- explicit `(profile ahb)`;
- generated requester, byte-lane subordinate, interconnect, and aggregate top
  review artifacts;
- HDL entry module `ahb_tb`;
- `composition.byte_lane_propagation`;
- child `narrow_transfer_policy` propagation; and
- byte-lane wording removed from aggregate residue only for the selected
  byte-lane aggregate sources.

The matching `.ahb` aliases are still absent from the repository and from
support accounting. Existing `.ahb` profile-alias behavior already accepts
selected one-subordinate and two-subordinate AHB aggregate shapes by
subordinate count, not by subordinate object name. That makes the aliases
source/support/test/docs work unless `.745` finds a preservation issue.

## Current-Code Probe

Two current-code probes were run without adding repository sources.

The one-subordinate probe parsed the text from
`ppif/ahb_interconnect_byte_lane.ppif` using source label
`ppif/ahb_interconnect_byte_lane.ahb`. The result kept:

```text
kind: protocol_intent.ahb_interconnect
source_object: fsmgen-ahb-interconnect-byte-lane
topology: one_requester_one_subordinate_static_window_interconnect
composition_child_count: 3
composition.byte_lane_propagation.selected: true
ahb_aggregate_profile_alias_deferred: removed
```

The two-subordinate probe parsed the text from
`ppif/ahb_interconnect_two_subordinate_byte_lane.ppif` using source label
`ppif/ahb_interconnect_two_subordinate_byte_lane.ahb`. The result kept:

```text
kind: protocol_intent.ahb_interconnect
source_object: fsmgen-ahb-interconnect-two-subordinate-byte-lane
topology: one_requester_two_subordinate_static_window_interconnect
composition_child_count: 4
composition.byte_lane_propagation.selected: true
ahb_aggregate_profile_alias_deferred: removed
```

Temporary CLI schedule probes under `/tmp` confirmed that both alias-labeled
sources emit schedule/report JSON with the same generated `.isf`/`.fsm`
artifact chain as their generic `.ppif` sources and without the stale
aggregate profile-alias residue.

## Selected `.745` Implementation Owner

`.745` must add exactly the matching aggregate byte-lane `.ahb` aliases:

```text
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

The one-subordinate alias must support-account as:

```text
entry_id: intent.ahb_profile_alias_interconnect_byte_lane
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_byte_lane_pipeline_cli
module_name: ahb_tb
composition_child_count: 3
```

The two-subordinate alias must support-account as:

```text
entry_id: intent.ahb_profile_alias_interconnect_two_subordinate_byte_lane
source_kind: ial2_profile_alias
coverage: ial2_ahb_profile_alias_interconnect_two_subordinate_byte_lane_pipeline_cli
module_name: ahb_tb
composition_child_count: 4
```

Both aliases must preserve:

- explicit `(profile ahb)`;
- the source object id and intent name from the mirrored `.ppif`;
- generated `.isf` review artifacts before generated `.fsm` review artifacts;
- `ahb_tb.fsm` as the HDL entry;
- `composition.byte_lane_propagation`;
- child `narrow_transfer_policy`;
- local-address-before-byte-lane policy;
- subordinate-owned mapped-hit byte/halfword/word behavior; and
- interconnect-owned unmapped ERROR behavior.

Alias reports must remove only `ahb_aggregate_profile_alias_deferred` from
the alias report and nested child reports. The generic aggregate byte-lane
`.ppif` reports must keep that source-surface residue.

## Validation And Rollback

`.745` should add focused profile-alias coverage, most likely
`t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t`, alongside direct
strict check, schedule, semantic, and outdir probes for both aliases. It must
preserve:

- existing word-only aggregate `.ppif` and `.ahb` behavior;
- existing generic aggregate byte-lane `.ppif` behavior;
- endpoint byte-lane `.ppif` and `.ahb` behavior;
- malformed `.ahb` profile/suffix diagnostics; and
- fail-closed unsupported object breadth.

Rollback is to remove the two `.ahb` alias source samples, their support
accounting entries, focused tests, and docs/Knowledge Map updates. No parser
or generator rollback should be needed unless `.745` discovers a behavior
regression not seen in the selector probes.

## Explicit Deferrals

`.745` must not add optional/property-gated AHB signals, burst `SEQ`
continuation, broader interconnect/decode cardinality, legacy two-bit
subordinate `HRESP`, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, or VHDL behavior.

## Validation

`.744` validates current state only. Useful probes are:

```text
perl -Iperl -MFSM::Adapter::IAL2::PPIF -MJSON::PP -e '...parse_source(..., ".ahb")...'
./bin/fsmgen --quiet --emit-schedule-json /tmp/fsmgen-ahb-interconnect-byte-lane-probe.ahb
./bin/fsmgen --quiet --emit-schedule-json /tmp/fsmgen-ahb-interconnect-two-subordinate-byte-lane-probe.ahb
```

Closeout must run Knowledge Map generation/check, mdBook build, docs path
audit, memory architecture check, diff check, and the doctrine driver. Broad
or potentially heavyweight Perl/`prove`/`fsmgen` commands must remain
RAM-guarded.
