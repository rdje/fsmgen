# IAL2 AHB Aggregate Alias Nested Profile-Residue Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.747`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.747` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.748`, direct implementation of the
bounded AHB aggregate `.ahb` alias nested profile-residue cleanup.

The selected implementation changes report JSON only. It must not change
parser behavior, public source samples, support-accounting catalog entries,
capability-manifest entries, generated `.isf`, generated `.fsm`, HDL/runtime
behavior, direct backend behavior, verification-output generation,
backend-language variants, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Current Boundary

The shipped aggregate `.ahb` aliases are:

```text
ppif/ahb_interconnect.ahb
ppif/ahb_interconnect_two_subordinate.ahb
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

Their top-level reports already remove:

```text
ahb_aggregate_profile_alias_deferred
```

The generated endpoint child reports still carry endpoint profile-alias
residue copied from the generic requester/subordinate generators:

```text
children[* requester].unsupported_residue: ahb_profile_alias_deferred
children[* subordinate].unsupported_residue: ahb_subordinate_profile_alias_deferred
```

Standalone endpoint `.ahb` reports already remove those endpoint residues at
top level:

```text
ppif/ahb_requester.ahb
ppif/ahb_lite_subordinate.ahb
ppif/ahb_lite_subordinate_byte_lane.ahb
```

## Probe Evidence

Focused schedule probes over all shipped aggregate and endpoint AHB surfaces
confirmed the current report split:

```text
ppif/ahb_interconnect.ahb:
  top: no ahb_aggregate_profile_alias_deferred
  child requester: ahb_profile_alias_deferred
  child subordinate: ahb_subordinate_profile_alias_deferred

ppif/ahb_interconnect_two_subordinate.ahb:
  top: no ahb_aggregate_profile_alias_deferred
  child requester: ahb_profile_alias_deferred
  child subordinates: ahb_subordinate_profile_alias_deferred

ppif/ahb_interconnect_byte_lane.ahb:
  top: no ahb_aggregate_profile_alias_deferred
  child requester: ahb_profile_alias_deferred
  child subordinate: ahb_subordinate_profile_alias_deferred

ppif/ahb_interconnect_two_subordinate_byte_lane.ahb:
  top: no ahb_aggregate_profile_alias_deferred
  child requester: ahb_profile_alias_deferred
  child subordinates: ahb_subordinate_profile_alias_deferred
```

The matching generic aggregate `.ppif` reports still carry the aggregate
source-surface residue and the copied endpoint child residues. Endpoint `.ppif`
reports still carry their endpoint profile-alias residues, while endpoint
`.ahb` reports remove them.

## Selected Report Contract

For shipped aggregate `.ahb` aliases only, `.748` must remove these residue IDs
recursively from the public schedule/check/semantic report tree:

```text
ahb_aggregate_profile_alias_deferred
ahb_profile_alias_deferred
ahb_subordinate_profile_alias_deferred
```

The selected cleanup applies to both aggregate families:

```text
word-only one-subordinate aggregate .ahb
word-only two-subordinate aggregate .ahb
byte-lane one-subordinate aggregate .ahb
byte-lane two-subordinate aggregate .ahb
```

The cleanup is intentionally report-scoped. It must preserve all other AHB
residue, including:

```text
ahb_multi_subordinate_decode_deferred
ahb_broader_interconnect_decode_deferred
ahb_completer_subordinate_deferred
ahb_interconnect_decode_deferred
ahb_full_manager_deferred
ahb_interconnect_generation_deferred
ahb_optional_signal_residue
ahb_subordinate_optional_signal_residue
ahb_burst_seq_support_deferred
ahb_direct_backend_deferred
ahb_verification_output_deferred
```

No new nested child provenance fields are selected. The aggregate source path,
top-level `source_object`, and support accounting
`source_kind: ial2_profile_alias` already identify the public alias surface.
Adding a new provenance schema would be broader than the stale-residue cleanup
needed here.

## Preservation Contract

The matching generic aggregate `.ppif` reports must keep source-surface residue:

```text
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

For those generic sources:

- top/interconnect reports keep `ahb_aggregate_profile_alias_deferred`;
- requester child reports keep `ahb_profile_alias_deferred`;
- subordinate child reports keep `ahb_subordinate_profile_alias_deferred`;
- byte-lane aggregate `.ppif` sources keep `composition.byte_lane_propagation`
  and child `narrow_transfer_policy`; and
- word-only aggregate `.ppif` sources do not gain byte-lane reports.

Endpoint `.ppif/.ahb` behavior remains unchanged. Endpoint `.ahb` reports
continue to remove only their own endpoint profile-alias residue, and endpoint
`.ppif` reports continue to keep it.

## Implementation Owner

`.748` owns implementation of exactly this contract:

- extend only the AHB aggregate `.ahb` result cleanup in
  `FSM::Adapter::IAL2::PPIF`;
- reuse the existing recursive residue-removal helper rather than adding a new
  report schema;
- add focused assertions for word-only aggregate `.ahb`, two-subordinate
  aggregate `.ahb`, and aggregate byte-lane `.ahb` reports;
- assert matching generic aggregate `.ppif` reports still keep the source-
  surface residues;
- keep malformed `.ahb` diagnostics and support accounting unchanged;
- update behavior docs, mdBook, README, ROADMAP_V2, task tree, MEMORY,
  Knowledge Map, and doctrine gates.

`.748` must not add optional/property-gated AHB signals, burst `SEQ`
continuation, broader interconnect/decode cardinality, legacy two-bit
subordinate `HRESP`, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, or VHDL behavior.

## Validation

The implementation leaf must run at least:

```text
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c t/1479-ial2-ahb-interconnect-profile-alias.t
perl -Iperl -c t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t
perl -Iperl -c t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
prove -Iperl t/1479-ial2-ahb-interconnect-profile-alias.t
prove -Iperl t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t
prove -Iperl t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

Closeout must run Knowledge Map generation/check, mdBook build, docs path
audit, memory architecture check, diff check, and the doctrine driver. Broad
or potentially heavyweight Perl/`prove`/`fsmgen` commands must remain
RAM-guarded.

## Rollback

Rollback is limited to the `.748` report cleanup and focused assertions. Since
no public source syntax, support accounting identity, generated artifact, or
HDL behavior is selected for change, reverting the implementation would restore
only the previous nested child residue report surface for aggregate `.ahb`
aliases.
