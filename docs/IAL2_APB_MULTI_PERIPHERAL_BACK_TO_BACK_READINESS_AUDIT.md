# IAL2 APB Multi-Peripheral Back-To-Back Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.608`
- Date: `2026-06-28`
- Status: selected next implementation owner
- Scope: APB multi-peripheral back-to-back propagation readiness only

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.608` audits whether the selected APB
back-to-back timing-policy contract can extend from the shipped fixed
one-requester/one-completer composition to generated multi-peripheral
composition.

The result is ready for a direct bounded implementation owner. No new public
timing-policy vocabulary is needed before implementation: `.606` already
selected requester `(timing-policy (back-to-back queued) (queue-depth 1)
(overflow reject))`, requester `accepted`, and completer `(timing-policy
(setup-admission adjacent))`. The next owner should remain narrow: selected
32-bit, no-sideband, two-peripheral composition only. Sideband, data16,
protection, multi-register, deeper queues, alternate overflow policies,
multiple active APB transfers, direct backend lowering, verification-output,
backend-language variants, AXI, AHB, and VHDL stay deferred.

This audit changes no parser behavior, generator behavior, samples,
support-accounting catalog entries, generated artifacts, schedule/check JSON,
semantic JSON, HDL/runtime behavior, suffix acceptance, direct backend
lowering, verification-output generation, backend-language variants, APB
behavior, AXI behavior, AHB behavior, or VHDL behavior.

Implementation result: `.609` later shipped the selected 32-bit no-sideband
two-peripheral status family documented in
`docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`. This audit remains
the pre-code readiness record for that implementation.

## Evidence Read

The audit read:

- `docs/IAL2_APB_BACK_TO_BACK_BEHAVIOR.md`;
- `docs/IAL2_APB_BACK_TO_BACK_CONTRACT_SELECTION.md`;
- `docs/IAL2_APB_BACK_TO_BACK_READINESS_AUDIT.md`;
- `docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md`;
- `docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION.md`;
- APB sideband/data16/protection behavior notes;
- `perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm`;
- `perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm`;
- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm`;
- `perl/FSM/Support/RegressionCorpus.pm`;
- focused APB/profile-alias tests;
- selected multi-peripheral APB `.ppif` samples;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and decisions
  `0015`, `0016`, `0017`, and `0018`.

Live schedule probes reconfirmed that current multi-peripheral reports still
retain `apb_back_to_back_policy_deferred` at the aggregate composition,
generated interconnect, requester child, and peripheral child report surfaces.

## Current Multi-Peripheral Shape

The shipped multi-peripheral APB composition has one requester, two or more
peripheral completers, a static non-overlapping address map, and a generated
`apb_interconnect` review artifact:

```text
apb_requester.isf
apb_status_regs.isf
apb_control_regs.isf
apb_interconnect.isf
apb_requester.fsm
apb_status_regs.fsm
apb_control_regs.fsm
apb_interconnect.fsm
apb_tb.fsm
```

The generated interconnect is combinational in its `idle` state. Its helper
sections fan out current requester control/data to each peripheral, decode
`PSEL` and `PADDR` against static windows, translate local address as
`PADDR - base`, mux selected `PREADY`, `PRDATA`, and `PSLVERR`, and return
`PREADY=1`, `PRDATA=0`, `PSLVERR=1` for an active unmapped access
(`PSEL && PENABLE` with no matching window).

The interconnect does not add a queue, register the selected peripheral, or
insert an idle cycle. That makes it structurally compatible with the `.607`
requester behavior that can drive the queued next setup as `PSEL=1` and
`PENABLE=0`.

## Readiness Findings

The multi-peripheral path is ready for a narrow direct behavior owner.

The requester side is already implemented for the selected policy. A queued
request can drive a new setup with the queued address, write bit, write data,
`PSEL=1`, and `PENABLE=0`. In a multi-peripheral composition, that setup will
feed the generated interconnect immediately, and the interconnect will decode
the queued address for either the same peripheral or a different peripheral.

The completer side is also ready, provided every peripheral endpoint in the
selected composition explicitly carries `(timing-policy (setup-admission
adjacent))`. Each peripheral completer samples setup on `PSEL && !PENABLE`.
The generated interconnect drives decoded `PSEL` to exactly the selected
peripheral and forwards `PENABLE` unchanged, so adjacent setup admission stays
endpoint-local.

Response muxing remains deterministic for the selected next owner because the
requester samples the completed access response before it enters the terminal
state that drives the queued next setup. During the queued setup cycle,
`PENABLE=0`, so a newly selected peripheral may be decoded without needing to
provide the prior transfer's response. The current interconnect's unmapped
error response is active-access only (`PSEL && PENABLE` with no matching
window), so an unmapped queued setup does not complete early; it becomes an
unmapped error on the following access phase.

The current blocker is intentionally artificial, not structural:
`ApbComposition` rejects any timing-policy clause in multi-peripheral
composition until an exact owner ships. The next owner can remove or narrow
that guard for the selected compatible endpoint policy family while preserving
fail-closed diagnostics for every unselected variant.

## Selected Next Owner

`.609` shall implement the bounded APB multi-peripheral back-to-back
propagation slice.

The next implementation owner should add only the selected public sample
family:

```text
ppif/apb_composition_multi_peripheral_status_back_to_back.ppif
ppif/apb_composition_multi_peripheral_status_back_to_back.apb
```

Selected endpoint policy requirements:

- requester: `accepted`, `busy`, `status width 2`, and `(timing-policy
  (back-to-back queued) (queue-depth 1) (overflow reject))`;
- every peripheral completer: `(timing-policy (setup-admission adjacent))`;
- composition: existing multi-peripheral children/address-map/decode source
  shape; no top-level timing-policy clause.

Selected behavior and report expectations:

- generated requester keeps the `.607` depth-1 queued behavior;
- generated interconnect remains propagation-only and must not insert an idle
  cycle;
- queued setup to the same or a different peripheral must decode through the
  current address map;
- response mux report remains `selected_peripheral_response` with active
  unmapped error on `PSEL && PENABLE`;
- top composition exposes requester `accepted`;
- top, interconnect, requester, and selected peripheral reports remove broad
  `apb_back_to_back_policy_deferred` only for this selected no-sideband family;
- reports retain narrowed `apb_additional_back_to_back_policies_deferred` for
  sideband/data16/protection variants, deeper queues, alternate overflow
  policies, multiple active transfers, and direct/backend/VHDL work.

## Validation Target For `.609`

The implementation owner should cover:

- parser/static diagnostics for unsupported multi-peripheral timing-policy
  shapes, missing peripheral timing policies, sideband/data16/protection
  variants, deeper queues, and alternate overflow policies;
- `.ppif` and `.apb` profile-alias parity for generated `.isf` and `.fsm`;
- schedule JSON, check JSON, semantic JSON, generated review artifacts, and
  HDL shape;
- same-peripheral and cross-peripheral queued setup decode evidence in the
  generated interconnect/top;
- support-accounting and capability-manifest updates;
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map sync; and
- docs/doctrine closeout gates.

## Deferred Work

The next owner must not widen into sideband, data16, protection,
multi-register, queue-depth greater than 1, alternate overflow, accepted-less
requester, multiple active APB bus transfers, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, or VHDL
behavior.

## Validation

Audit validation used documentation/code review plus live probes:

```bash
perl -MJSON::PP=decode_json -e 'for my $path (@ARGV) { my $json = qx(./bin/fsmgen --emit-schedule-json $path); die "fsmgen failed for $path\n" if $?; my $r = decode_json($json); my @top = map { $_->{id} } @{$r->{unsupported_residue} || []}; my @child = map { [$_->{role}, $_->{object_name}, [map { $_->{id} } @{$_->{unsupported_residue} || []}]] } @{$r->{children} || []}; my $mux = $r->{composition}{response_mux} || {}; print "$path\n"; print "  top_residue=@top\n"; print "  response_mux=$mux->{selected_policy}; unmapped=$mux->{unmapped_policy}{active_access}\n"; for my $c (@child) { print "  child=$c->[0]/$c->[1] residue=@{$c->[2]}\n"; } }' ppif/apb_composition_multi_peripheral.ppif ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif
rg -n 'multi-peripheral|interconnect|back-to-back|timing_policy|unsupported_residue|response_mux|PSEL|PENABLE' perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
```

Closeout also runs Knowledge Map, mdBook, diff, memory, and doctrine gates.

## Rollback

Rollback is doc-only: revert this audit, its fact card, task-tree frontier
updates, README, ROADMAP_V2, mdBook, Memory, and generated Knowledge Map
changes. The `.607` fixed-composition behavior and all current
multi-peripheral parser/generator/runtime behavior remain unchanged.
