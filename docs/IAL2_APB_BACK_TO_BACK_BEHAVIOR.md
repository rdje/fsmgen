# IAL2 APB Back-To-Back Timing Policy Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.607`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected APB requester, completer, and fixed-composition timing-policy behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.607` implements the bounded APB
back-to-back timing-policy contract selected by `.606` for exactly six public
sources:

- `ppif/apb_requester_transfer_status_back_to_back.ppif`
- `ppif/apb_requester_transfer_status_back_to_back.apb`
- `ppif/apb_completer_back_to_back.ppif`
- `ppif/apb_completer_back_to_back.apb`
- `ppif/apb_composition_status_back_to_back.ppif`
- `ppif/apb_composition_status_back_to_back.apb`

The source still lowers through generated `.isf` before generated `.fsm`.
Direct IAL2-to-IAL0 lowering, direct backend lowering, verification-output
generation, backend-language variants, AXI behavior, AHB behavior, and VHDL
remain outside this owner.

Update `.609`: the selected 32-bit no-sideband two-peripheral status
multi-peripheral propagation family now ships separately. See
`docs/IAL2_APB_MULTI_PERIPHERAL_BACK_TO_BACK_BEHAVIOR.md`.

## Requester Behavior

The selected requester transfer accepts only:

```text
(timing-policy
  (back-to-back queued)
  (queue-depth 1)
  (overflow reject))
```

and requires response fields `accepted`, `busy`, and `status width 2`.

The generated requester exposes `accepted` and adds one queued request slot:
`queued_valid`, `queued_addr`, `queued_write`, and `queued_wdata`. `accepted`
pulses when `start` is sampled into the active transfer slot or the empty
queued slot. If `start` is asserted while the active APB transfer and queued
slot are both occupied, overflow is rejected: `accepted` does not pulse and
the queued request is not overwritten.

When a queued request exists at the terminal requester state, the generated
FSM drives the queued address, write bit, write data, `PSEL=1`, and
`PENABLE=0`, keeps `busy` and `status` at busy encoding, clears
`queued_valid`, and transitions to the access phase. That avoids an inserted
idle APB bus cycle between the completed transfer and the queued setup phase.

## Completer Behavior

The selected completer transfer accepts only:

```text
(timing-policy
  (setup-admission adjacent))
```

The generated completer already admits setup with the APB detector
`PSEL && !PENABLE`; `.607` makes that policy explicit in source parsing,
reports, support accounting, and diagnostics for the selected 32-bit
one-register no-sideband completer.

## Fixed Composition

The fixed one-requester/one-completer composition propagates the selected
endpoint behavior only when both endpoints carry compatible timing policies:

- requester: back-to-back queued, queue-depth 1, overflow reject;
- completer: setup-admission adjacent.

The composition top exposes the requester `accepted` output and reports an
aggregate `back_to_back_policy` section naming both endpoint policies. A
fixed composition with only one endpoint policy, incompatible endpoint policy,
sideband/data16/protection endpoint, or multi-register completer is rejected
for this owner.

At `.607`, multi-peripheral APB back-to-back propagation stayed deferred until
an exact owner could validate interconnect response muxing and decoded-select
behavior for adjacent accesses. `.609` later shipped the selected no-sideband
two-peripheral status family; broader multi-peripheral variants remain
deferred.

## Report And Support Accounting

Requester reports add:

```json
"timing_policy": {
  "back_to_back": "queued",
  "queue_depth": 1,
  "overflow": "reject",
  "accepted": "accepted"
}
```

Completer reports add:

```json
"timing_policy": {
  "setup_admission": "adjacent"
}
```

Fixed-composition reports add aggregate `back_to_back_policy` metadata and
the requester `requester_accepted_field`. The selected requester, completer,
and fixed-composition samples remove broad `apb_back_to_back_policy_deferred`
and retain narrowed `apb_additional_back_to_back_policies_deferred` residue.

Support-accounting identities added in this slice:

- `intent.ppif_apb_requester_transfer_status_back_to_back`
- `intent.apb_profile_alias_requester_transfer_status_back_to_back`
- `intent.ppif_apb_completer_back_to_back`
- `intent.apb_profile_alias_completer_back_to_back`
- `intent.ppif_apb_composition_status_back_to_back`
- `intent.apb_profile_alias_composition_status_back_to_back`

## Deferred Work

- multi-peripheral APB back-to-back variants beyond the selected 32-bit
  no-sideband two-peripheral status family;
- sideband/data16/protection back-to-back samples;
- queue depths other than 1;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

Focused validation for this slice:

- `prove -Iperl t/1470-ial2-apb-profile-alias.t`
- `prove -Iperl t/1471-ial2-apb-completer.t`
- `prove -Iperl t/1472-ial2-apb-composition.t`
