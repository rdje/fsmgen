# IAL2 APB Multi-Peripheral Back-To-Back Timing Policy Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.609`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected APB multi-peripheral status back-to-back timing-policy propagation

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.609` implements the bounded
multi-peripheral APB back-to-back propagation owner selected by `.608` for
exactly two public sources:

- `ppif/apb_composition_multi_peripheral_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_status_back_to_back.apb`

The source lowers through generated `.isf` review artifacts before generated
`.fsm` artifacts. The selected requester behavior is the `.607` depth-1 queued
path, and the generated `apb_interconnect` remains propagation-only: it does
not add queueing, does not register the selected peripheral, and does not
insert an idle cycle between a completed access and the next queued setup.

This slice does not widen the APB outstanding model. There is still at most one
active APB bus transfer and one queued requester-side next transfer.

## Selected Source Contract

The selected family is intentionally narrow:

- one requester and exactly two peripheral completers;
- 32-bit APB data with no `PPROT`, `PSTRB`, data16, or protection policy;
- the existing static non-overlapping address-map/decode shape;
- requester response fields `accepted`, `busy`, and `status width 2`;
- requester transfer policy `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- every peripheral completer transfer policy `(timing-policy
  (setup-admission adjacent))`.

The composition itself has no top-level timing-policy clause. It derives the
aggregate policy from compatible endpoint policies and the generated
interconnect propagation contract.

The implementation rejects missing or incompatible endpoint policies, sideband,
data16, protection, queue depths other than 1, overflow policies other than
`reject`, non-selected multi-peripheral topology shapes, and peripheral
completers outside the selected one-register shape.

## Generated Behavior

The generated artifact set matches the existing multi-peripheral composition
review path:

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

The top composition exposes the requester `accepted` output. The requester
keeps the `.607` queue state and adjacent setup behavior: a queued request can
drive `PSEL=1`, `PENABLE=0`, queued `PADDR`, queued write bit, and queued write
data immediately after the previous access completes.

The generated interconnect decodes the current `PSEL/PADDR` during that setup
cycle, forwards `PENABLE` unchanged to the selected peripheral, and fans out
decoded `PSEL` only to the matching address window. A queued setup to the same
peripheral and a queued setup to a different peripheral both use the same
current-address decode path.

The interconnect response mux remains selected-peripheral response muxing.
Unmapped completion remains active-access only: unmapped `PREADY=1`,
`PRDATA=0`, and `PSLVERR=1` are driven only for `PSEL && PENABLE` with no
matching window. An unmapped queued setup with `PENABLE=0` therefore does not
complete early.

## Reports And Support Accounting

The composition report adds aggregate `back_to_back_policy` metadata:

```json
{
  "composition_role": "propagate_endpoint_policy_through_interconnect",
  "requester": {
    "timing_policy": {
      "back_to_back": "queued",
      "queue_depth": 1,
      "overflow": "reject",
      "accepted": "accepted"
    }
  },
  "interconnect": {
    "timing_role": "propagate_queued_setup_without_idle_cycle",
    "setup_decode": "current_psel_paddr_with_penable_low",
    "response_mux": "selected_peripheral_response",
    "unmapped_policy": "active_access_only"
  }
}
```

The selected top/interconnect/requester/peripheral report surfaces remove the
broad `apb_back_to_back_policy_deferred` residue and retain narrowed
`apb_additional_back_to_back_policies_deferred` residue for unselected APB
timing-policy families.

Support-accounting identities added in this slice:

- `intent.ppif_apb_composition_multi_peripheral_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_composition_multi_peripheral_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_status_back_to_back_pipeline_cli`

## CLI Examples

Emit schedule JSON for the `.ppif` source:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_status_back_to_back.ppif
```

Run strict check JSON for the `.apb` profile alias:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/apb_composition_multi_peripheral_status_back_to_back.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-multi-btb \
  --output /tmp/fsmgen-apb-multi-btb/apb_tb.sv \
  ppif/apb_composition_multi_peripheral_status_back_to_back.ppif
```

## Deferred Work

- sideband, data16, and protection back-to-back variants;
- queue depths other than 1;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
- multi-requester interconnects, bus matrices, scoreboards, and backend-owned
  APB arbitration;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

Focused validation for this slice includes:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1472-ial2-apb-composition.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/1472-ial2-apb-composition.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

Direct probes cover schedule JSON, strict check JSON, strict semantic JSON,
generated review artifacts, and generated HDL for the selected `.ppif` and
`.apb` sources.

## Rollback

Rollback removes the two selected public samples, the selected
multi-peripheral timing-policy compatibility path, the aggregate/interconnect
report movement, support-accounting entries, focused tests, and public docs.
Existing `.607` requester/completer/fixed-composition back-to-back behavior and
existing `.585` multi-peripheral interconnect/decode behavior remain intact.
