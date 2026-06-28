# IAL2 APB Sideband Multi-Peripheral Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.618`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected 32-bit APB sideband-aware multi-peripheral status
  back-to-back timing-policy propagation

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.618` implements the `.617` selected bounded
APB sideband-aware multi-peripheral back-to-back contract for exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.apb`

The sources lower through generated `.isf` review artifacts before generated
`.fsm` artifacts. The selected requester behavior is the `.612` sideband queued
path; each selected peripheral completer uses the `.615` sideband adjacent
setup path; the generated `apb_interconnect` remains propagation-only and
continues to decode the current setup address without inserting an idle cycle.

This slice does not widen the APB outstanding model. There is still at most one
active APB bus transfer and one queued requester-side next transfer.

## Selected Source Contract

The selected family is intentionally narrow:

- one requester and exactly two peripheral completers;
- 32-bit APB data with `PPROT width 3` and `PSTRB width 4`;
- the existing static non-overlapping status/control address-map/decode shape;
- requester response fields `accepted`, `busy`, and `status width 2`;
- requester request sidebands `req_prot width 3` and `req_wstrb width 4`;
- requester transfer policy `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- every peripheral completer transfer policy `(timing-policy
  (setup-admission adjacent))`;
- every peripheral completer is the selected one-register 32-bit sideband-aware
  family.

The composition has no top-level timing-policy clause. It derives aggregate
`back_to_back_policy` metadata from compatible endpoint policies and the
generated interconnect propagation contract.

The implementation accepts either the previously shipped no-sideband
multi-peripheral back-to-back family or this selected sideband-aware family.
Data16/protection timing variants, multi-register timing policy, partial
sideband declarations, deeper queues, overflow policies other than `reject`,
accepted-less requesters, multiple active APB transfers, and non-selected
topologies remain rejected or deferred.

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
keeps the `.612` sideband queue state: accepted queued transfers store
`queued_prot` and `queued_wstrb`, then relaunch the queued setup without an
inserted idle cycle.

The generated interconnect decodes the current `PSEL/PADDR` while `PENABLE` is
low, fans out decoded `PSEL` to the selected status or control peripheral, and
forwards `PPROT` and `PSTRB` to both peripheral buses. The selected peripheral
therefore samples queued sideband payload on the adjacent setup cycle and
applies the existing byte-lane write semantics.

The interconnect response mux remains selected-peripheral response muxing.
Unmapped completion remains active-access only: unmapped `PREADY=1`,
`PRDATA=0`, and `PSLVERR=1` are driven only for `PSEL && PENABLE` with no
matching window.

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
timing-policy families. The existing `apb_protection_policy_effects_deferred`
residue remains because this slice propagates `PPROT` sideband values but does
not implement new access-control semantics.

Support-accounting identities added in this slice:

- `intent.ppif_apb_composition_multi_peripheral_sideband_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_sideband_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_composition_multi_peripheral_sideband_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_sideband_status_back_to_back_pipeline_cli`

## CLI Examples

Emit schedule JSON for the `.ppif` source:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif
```

Run strict check JSON for the `.apb` profile alias:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-sideband-multi-btb \
  --output /tmp/fsmgen-apb-sideband-multi-btb/apb_tb.sv \
  ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif
```

## Deferred Work

- data16/protection back-to-back timing variants;
- multi-register timing policy;
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
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
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
temporary-directory generated review artifacts, and generated HDL for the
selected `.ppif` and `.apb` sources. Closeout also runs Knowledge Map
generation/check, mdBook build, docs path, memory, diff, and doctrine gates.

## Rollback

Rollback removes the two selected public samples, the selected sideband-aware
multi-peripheral timing-policy compatibility path, the aggregate/interconnect
report movement, support-accounting entries, focused tests, this behavior
record, its Knowledge Map fact card, README, ROADMAP_V2, mdBook, task tree,
Memory, and generated Knowledge Map updates. Existing no-sideband
multi-peripheral back-to-back behavior, fixed sideband-composition behavior,
sideband requester/completer behavior, sideband strobe/data16/protection
behavior, AXI, AHB, and VHDL behavior remain owned by earlier or future slices.
