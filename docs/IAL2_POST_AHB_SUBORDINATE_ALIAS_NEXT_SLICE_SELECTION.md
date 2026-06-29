# IAL2 Post-AHB Subordinate Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.719`

Date: 2026-06-29

## Outcome

Select `IAL2-FEATURE-COMPLETENESS-FRONTIER.720`, a no-behavior AHB
interconnect/decode readiness audit, as the next exact IAL2/AHB owner after
the requester and subordinate `.ppif` and `.ahb` public entrypoints have
shipped.

`.720` must decide whether AHB interconnect/decode is ready for public
contract selection or whether a smaller prerequisite is still required. It
must not add parser, generator, source, support-accounting, manifest, test,
schedule/check/semantic JSON, generated-artifact, HDL/runtime, direct-backend,
verification-output, backend-language, AXI, APB, broader AHB, or VHDL
behavior.

## Current AHB Surface

The shipped public AHB IAL2 entrypoints are:

```text
ppif/ahb_requester.ppif
ppif/ahb_requester.ahb
ppif/ahb_lite_subordinate.ppif
ppif/ahb_lite_subordinate.ahb
```

Live schedule probes during this selector showed the remaining AHB residue:

```text
ppif/ahb_requester.ppif
  fsmgen.ial2.protocol_intent.ahb_requester.v1
  ahb_profile_alias_deferred
  ahb_completer_subordinate_deferred
  ahb_interconnect_decode_deferred
  ahb_full_manager_deferred
  ahb_verification_output_deferred

ppif/ahb_requester.ahb
  fsmgen.ial2.protocol_intent.ahb_requester.v1
  ahb_completer_subordinate_deferred
  ahb_interconnect_decode_deferred
  ahb_full_manager_deferred
  ahb_verification_output_deferred

ppif/ahb_lite_subordinate.ppif
  fsmgen.ial2.protocol_intent.ahb_subordinate.v1
  ahb_subordinate_profile_alias_deferred
  ahb_interconnect_generation_deferred
  ahb_subordinate_optional_signal_residue
  ahb_burst_seq_support_deferred
  ahb_verification_output_deferred

ppif/ahb_lite_subordinate.ahb
  fsmgen.ial2.protocol_intent.ahb_subordinate.v1
  ahb_interconnect_generation_deferred
  ahb_subordinate_optional_signal_residue
  ahb_burst_seq_support_deferred
  ahb_verification_output_deferred
```

The requester and subordinate report families both preserve an interconnect
owner, but their residue keys are not yet normalized. `.720` must include that
residue-key reconciliation in the readiness audit before any generated fabric
behavior is selected.

## Source Anchors

The AHB source-fact inventory records the interconnect-relevant facts:

- each subordinate has its own `HSELx`;
- for non-IDLE transfers, `HSELx` is asserted with address and control;
- a newly selected subordinate monitors `HREADY` so it responds only after the
  previous transfer has completed;
- a subordinate cannot extend the address phase, but it can extend the data
  phase by driving `HREADYOUT` low;
- `HREADYOUT` contributes to the overall `HREADY` stall behavior through the
  interconnect.

Source anchors remain the imported Arm AMBA AHB Protocol Specification,
sections `1.3`, `2.4`, and `3.1`, pages `1-18`, `2-24`, and `3-28`, as
recorded in `docs/IAL2_AHB_SUBORDINATE_SOURCE_FACT_INVENTORY.md`.

## Selected `.720` Scope

`.720` should audit, without changing behavior:

- whether the first AHB interconnect/decode owner should target one requester
  and one subordinate, one requester and two or more subordinate endpoints, or
  a smaller prerequisite;
- whether the public object should be a composition/interconnect wrapper,
  endpoint-linked source shape, generated reusable IAL1 review artifact, or
  another bounded source surface;
- address window syntax, decode priority, overlap policy, unmapped-address
  response, response muxing, `HREADY` aggregation, `HSELx` fanout, and local
  address translation expectations;
- generated review artifact names, including whether an `ahb_interconnect.isf`
  and `ahb_interconnect.fsm` pair should exist before any aggregate top;
- report schema, support-accounting identities, focused test names, and
  capability-manifest wording;
- diagnostics for mixed objects, duplicate endpoints, overlapping address
  windows, unsupported burst `SEQ`, optional signals, byte-lane/narrow
  transfers, two-bit `HRESP`, multiple managers, bus matrices, direct backend,
  verification-output, backend-language variants, AXI, APB, and VHDL;
- whether requester and subordinate interconnect residue keys should converge
  on a single AHB interconnect/decode residue family; and
- rollback and preservation probes for the four shipped public AHB entrypoints.

## Rejected Alternatives

Direct AHB interconnect/decode behavior is rejected because source syntax,
topology shape, generated review artifacts, report/support-accounting
contracts, diagnostics, validation, and residue migration are not selected.

Optional AHB signals, burst `SEQ` continuation, byte-lane/narrow-transfer
behavior, and legacy two-bit `HRESP` compatibility are rejected as the next
owner because they widen endpoint protocol behavior before the aggregate
interconnect/decode contract is audited.

AHB completer behavior is rejected because the project has already selected
the source vocabulary `ahb-subordinate` for the first public subordinate
endpoint. A separate completer alias or synonym policy would need its own
selector, but it is not the next critical path after the shipped subordinate
entrypoints.

Verification-output and direct backend behavior are rejected because current
doctrine keeps IAL2 lowering through generated `.isf` before generated `.fsm`
and keeps direct `.ppif`/profile-alias verification-output routes unselected.

AXI, APB, backend-language variants, and VHDL are rejected because the active
frontier is AHB-local and the next AHB residue now has the requester and
subordinate endpoint prerequisites in place.

## Validation

This selector was validated with live schedule probes:

```bash
perl -MJSON::PP=decode_json -e 'for my $p (@ARGV) { my $json = qx(./bin/fsmgen --quiet --emit-schedule-json $p); die "fsmgen failed for $p\n" if $?; my $d = decode_json($json); my @ids = map { $_->{id} } @{ $d->{unsupported_residue} || [] }; print "$p | $d->{schema} | residue=@ids\n"; }' ppif/ahb_requester.ppif ppif/ahb_requester.ahb ppif/ahb_lite_subordinate.ppif ppif/ahb_lite_subordinate.ahb
```

Closeout must also run Knowledge Map generation/check, mdBook build, docs path
audit, memory-architecture check, diff hygiene, and the doctrine driver.

## Non-Changes

`.719` is a selector only. It does not change parser, generator, source
sample, support-accounting catalog, capability manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI, APB, broader AHB behavior, or VHDL behavior.
