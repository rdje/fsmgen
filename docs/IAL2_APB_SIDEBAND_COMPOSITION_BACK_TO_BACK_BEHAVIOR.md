# IAL2 APB Sideband Composition Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.615`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected 32-bit APB sideband-aware completer and fixed-composition
  timing-policy behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.615` implements the `.614` selected APB
sideband-aware completer and fixed-composition back-to-back contract for exactly
four public sources:

- `ppif/apb_completer_sideband_back_to_back.ppif`
- `ppif/apb_completer_sideband_back_to_back.apb`
- `ppif/apb_composition_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_sideband_status_back_to_back.apb`

The sources lower through generated `.isf` review artifacts before generated
`.fsm` artifacts, matching the existing APB IAL2 review path. The implementation
does not add multi-peripheral sideband timing propagation, data16/protection
timing variants, multi-register timing policy, deeper queues, alternate overflow
policies, direct backend lowering, verification-output generation,
backend-language variants, AXI, AHB, or VHDL behavior.

Update `.618`: the selected 32-bit sideband-aware two-peripheral status
multi-peripheral propagation family now ships separately. See
`docs/IAL2_APB_SIDEBAND_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`.

## Selected Completer Contract

The sideband-aware completer source is the selected one-register extension of
the `.607` adjacent setup completer family:

- one `apb-completer apb_completer`;
- 32-bit `PADDR`, `PWDATA`, `PRDATA`, and register data;
- bus `PPROT width 3`;
- bus `PSTRB width 4`;
- `wait_cycles width 4`;
- one address-0 storage register with reset value `0`;
- `(setup-detect (select 1) (enable 0))`;
- `(timing-policy (setup-admission adjacent))`.

The timing-policy guard accepts only the existing selected 32-bit no-sideband
one-register completer or this selected 32-bit sideband-aware one-register
family. Unsupported APB widths, partial sideband declarations, data16,
multi-register, protection-policy, and broader completer shapes remain rejected
for adjacent setup admission.

## Generated Completer Behavior

The generated sideband-aware completer samples `PADDR`, `PWRITE`, `PWDATA`,
`PPROT`, `PSTRB`, and `wait_cycles` on the APB setup detector
`PSEL && !PENABLE`. It uses the sampled wait count for access latency, applies
`PSTRB` byte enables to address-0 writes, returns address-0 read data, reports
unmapped addresses with `PSLVERR`, and admits the next setup phase on an
adjacent `PSEL && !PENABLE` cycle without requiring an inter-transfer idle
cycle.

Reports add:

```json
"timing_policy": {
  "setup_admission": "adjacent"
}
```

The selected sideband completer removes broad `apb_back_to_back_policy_deferred`
residue and keeps narrowed `apb_additional_back_to_back_policies_deferred`
residue for remaining APB timing-policy families.

## Selected Fixed Composition Contract

The selected fixed composition combines:

- the `.612` sideband requester timing policy:
  `(timing-policy (back-to-back queued) (queue-depth 1) (overflow reject))`;
- response `accepted`, `busy`, and `status width 2`;
- the selected sideband-aware adjacent setup completer above;
- one requester child and one completer child;
- 32-bit sideband-aware fixed wiring with `PPROT width 3` and `PSTRB width 4`.

The composition derives aggregate `back_to_back_policy` metadata from the
compatible endpoint policies. It exposes the requester `accepted` output at the
top level and wires `req_prot/req_wstrb` through requester `PPROT/PSTRB` to the
completer bus.

The fixed-composition compatibility guard now accepts either the existing
selected 32-bit no-sideband wiring family or the selected 32-bit sideband-aware
requester/completer/wiring family. Sideband multi-peripheral timing propagation
remains rejected for this slice.

## Generated Fixed Composition Behavior

The generated composition keeps the `.612` sideband requester queue behavior:
accepted queued transfers store `queued_prot` and `queued_wstrb`, then relaunch
the queued setup without an inserted idle cycle. The generated top-level APB
wiring propagates requester `PPROT/PSTRB` into the selected adjacent completer,
so the completer samples the queued sideband payload on the adjacent setup
cycle and applies byte-lane write semantics.

Selected sideband fixed-composition reports add aggregate back-to-back policy
metadata for both endpoints, remove broad `apb_back_to_back_policy_deferred`,
and retain `apb_additional_back_to_back_policies_deferred` for
data16/protection variants, broader timing-policy families, deeper queues,
alternate overflow policies, multiple active APB transfers, direct backend
lowering, verification-output generation, backend-language variants, AXI, AHB,
and VHDL.

## Support Accounting

Support-accounting identities added in this slice:

- `intent.ppif_apb_completer_sideband_back_to_back`
- `intent.apb_profile_alias_completer_sideband_back_to_back`
- `intent.ppif_apb_composition_sideband_status_back_to_back`
- `intent.apb_profile_alias_composition_sideband_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_completer_sideband_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_completer_sideband_back_to_back_pipeline_cli`
- `ial2_ppif_apb_composition_sideband_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_sideband_status_back_to_back_pipeline_cli`

## Deferred Work

The remaining APB timing-policy frontier is intentionally explicit:

- data16/protection back-to-back variants;
- multi-register timing policy;
- queue depths greater than 1;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

Focused validation for this slice:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1471-ial2-apb-completer.t
perl -Iperl -c t/1472-ial2-apb-composition.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1471-ial2-apb-completer.t
prove -Iperl t/1472-ial2-apb-composition.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
```

Direct schedule JSON, strict check JSON, semantic JSON, and temporary-directory
generation probes passed for all four public sources. Closeout also runs
Knowledge Map generation/check, mdBook build, docs path, memory, diff, and
doctrine gates.

## Rollback

Rollback removes the four sideband completer/fixed-composition back-to-back
sample files, the selected timing-policy guard widening in `ApbCompleter` and
`ApbComposition`, the four support-accounting entries, focused tests, this
behavior record, its Knowledge Map fact card, README, ROADMAP_V2, mdBook, task
tree, Memory, and generated Knowledge Map updates. Existing no-sideband
back-to-back behavior, selected `.612` sideband requester behavior, sideband
strobe/data16/protection behavior, multi-peripheral no-sideband back-to-back
behavior, AXI, AHB, and VHDL behavior remain owned by earlier or future slices.
