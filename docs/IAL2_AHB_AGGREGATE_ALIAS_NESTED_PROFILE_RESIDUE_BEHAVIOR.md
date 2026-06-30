# IAL2 AHB Aggregate Alias Nested Profile-Residue Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.748`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.748` ships the selected report-only
cleanup for aggregate AHB `.ahb` aliases.

The affected public sources are:

```text
ppif/ahb_interconnect.ahb
ppif/ahb_interconnect_two_subordinate.ahb
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

For those aggregate alias reports, FSMGen now removes these profile-alias
residue ids recursively from the report tree:

```text
ahb_aggregate_profile_alias_deferred
ahb_profile_alias_deferred
ahb_subordinate_profile_alias_deferred
```

The requester and subordinate residue ids previously appeared in generated
child reports copied from the endpoint requester/subordinate generators. They
are stale for aggregate `.ahb` aliases because the authored aggregate source is
already the public AHB profile-alias surface.

## Preserved Boundaries

The cleanup is report-only. It does not change parser behavior, public source
samples, support accounting, capability-manifest entries, generated `.isf`,
generated `.fsm`, HDL/runtime behavior, direct backend behavior,
verification-output generation, backend-language variants, AXI/APB behavior,
broader AHB behavior, or VHDL behavior.

The matching generic aggregate `.ppif` reports continue to keep source-surface
residue:

```text
ppif/ahb_interconnect.ppif
ppif/ahb_interconnect_two_subordinate.ppif
ppif/ahb_interconnect_byte_lane.ppif
ppif/ahb_interconnect_two_subordinate_byte_lane.ppif
```

Those generic reports keep `ahb_aggregate_profile_alias_deferred`, and their
generated requester/subordinate child reports keep `ahb_profile_alias_deferred`
and `ahb_subordinate_profile_alias_deferred`.

Endpoint `.ppif/.ahb` behavior is unchanged. Endpoint `.ahb` reports still
remove only their own endpoint profile-alias residue, and endpoint `.ppif`
reports keep it.

## Validation

Focused syntax and in-process adapter validation passed:

```text
perl -Iperl -c perl/FSM/Adapter/IAL2/PPIF.pm
perl -Iperl -c t/1479-ial2-ahb-interconnect-profile-alias.t
perl -Iperl -c t/1481-ial2-ahb-interconnect-two-subordinate-profile-alias.t
perl -Iperl -c t/1485-ial2-ahb-interconnect-byte-lane-profile-alias.t
adapter residue probe for four aggregate .ahb aliases and four generic aggregate .ppif sources
```

The RAM-guarded focused `prove` run for the three aggregate alias tests stopped
before TAP because pre-existing host memory was 95.4% against the 88% cutoff.
The cutoff was not bypassed.
