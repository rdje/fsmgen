# IAL2 Post-AHB Aggregate Byte-Lane Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.746`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.746` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.747`, public report-contract selection for
AHB aggregate `.ahb` alias nested profile-alias residue cleanup.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability manifest, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.745` ships:

```text
ppif/ahb_interconnect_byte_lane.ahb
ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

Those aliases remove `ahb_aggregate_profile_alias_deferred`, preserve
`composition.byte_lane_propagation`, preserve child `narrow_transfer_policy`,
and keep the generated `.isf` before generated `.fsm` review chain before HDL
module `ahb_tb`.

The remaining AHB feature backlog still includes optional/property-gated AHB
signals, burst `SEQ` continuation, broader interconnect/decode cardinality,
legacy two-bit subordinate `HRESP`, scoreboards, full-manager behavior, direct
backend behavior, verification-output generation, backend-language variants,
and VHDL behavior.

## Residue Probe

The `.746` selector rechecked representative AHB schedule reports. The top
aggregate alias reports no longer carry `ahb_aggregate_profile_alias_deferred`,
but their nested generated child reports still carry endpoint profile-alias
residue:

```text
ppif/ahb_interconnect_byte_lane.ahb:
  children[0].unsupported_residue: ahb_profile_alias_deferred
  children[2].unsupported_residue: ahb_subordinate_profile_alias_deferred

ppif/ahb_interconnect_two_subordinate_byte_lane.ahb:
  children[0].unsupported_residue: ahb_profile_alias_deferred
  children[2].unsupported_residue: ahb_subordinate_profile_alias_deferred
  children[3].unsupported_residue: ahb_subordinate_profile_alias_deferred
```

These are report-surface residues, not HDL behavior. They are narrower than
optional-signal, burst, broader-topology, direct-backend, verification-output,
or VHDL work, and they affect how downstream consumers interpret an already
shipped `.ahb` alias schedule.

## Selected `.747` Owner

`.747` must select the exact public report contract for aggregate `.ahb`
nested profile-alias residue cleanup before implementation changes.

It must decide:

- whether aggregate `.ahb` alias reports should remove child
  `ahb_profile_alias_deferred` and `ahb_subordinate_profile_alias_deferred`
  residue when the child source is generated from a public aggregate `.ahb`
  alias;
- whether the cleanup applies to word-only aggregate `.ahb` aliases,
  aggregate byte-lane `.ahb` aliases, or both;
- which generic `.ppif` aggregate reports must keep the child endpoint
  profile-alias residue as source-surface distinction;
- whether any nested child report provenance fields must be added instead of
  removing residue;
- which focused tests or direct probes should verify one-subordinate and
  two-subordinate aggregate `.ahb` aliases, generic aggregate `.ppif` sources,
  endpoint `.ppif/.ahb` sources, malformed `.ahb` diagnostics, and support
  accounting; and
- rollback boundaries if the selected cleanup proves misleading.

## Explicit Deferrals

`.747` must not add optional/property-gated AHB signals, burst `SEQ`
continuation, broader interconnect/decode cardinality, legacy two-bit
subordinate `HRESP`, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, or VHDL behavior.

## Validation

`.746` validates current state only. The selector probes were:

```text
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane.ahb
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_two_subordinate_byte_lane.ahb
```

Closeout must run Knowledge Map generation/check, mdBook build, docs path
audit, memory architecture check, diff check, and the doctrine driver. Broad
or potentially heavyweight Perl/`prove`/`fsmgen` commands must remain
RAM-guarded.
