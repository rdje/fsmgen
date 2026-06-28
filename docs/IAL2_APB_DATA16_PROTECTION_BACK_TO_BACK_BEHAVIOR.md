# IAL2 APB Data16 Protection Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.631`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected APB sideband-aware data16 protection standalone-completer
  and fixed-composition back-to-back timing-policy behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.631` implements the `.630` selected APB
sideband-aware data16-protection back-to-back timing-policy contract for
exactly four public sources:

- `ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.apb`

The selected sources keep APB addresses at 32 bits, use 16-bit `PWDATA`,
`PRDATA`, and register data, use `PPROT width 3` and `PSTRB width 2`, and
combine the existing data16 byte-lane behavior with register-local
privileged `PPROT[0]` protection and adjacent setup admission.

Sources still lower through generated `.isf` review artifacts before
generated `.fsm` artifacts, then through the current SystemVerilog backend.
The outstanding model is unchanged: there is still at most one active APB
transfer and, for the fixed composition, one requester-side queued next
transfer.

Update `.634`: the selected multi-peripheral data16-protection back-to-back
composition is now shipped separately in
`docs/IAL2_APB_MULTI_PERIPHERAL_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md`.
The `.631` behavior here remains the standalone-completer and fixed-composition
scope.

## Selected Completer Contract

The selected standalone completer is the protected data16 two-register
extension of the `.625` data16 adjacent setup family and the `.628` protected
adjacent setup family:

- one `apb-completer apb_completer`;
- bus `PADDR width 32`;
- bus `PWDATA width 16`;
- bus `PPROT width 3`;
- bus `PSTRB width 2`;
- bus `PRDATA width 16`;
- control `wait_cycles width 4`;
- exactly two source-ordered storage registers;
- `reg0` at address `0`, data width `16`, reset `0`;
- `reg0` access policy `(read allow)` and `(write require (privileged 1))`;
- `reg1` at address `2`, data width `16`, reset `0`;
- `reg1` access policy `(read require (privileged 1))` and
  `(write require (privileged 1))`;
- `(setup-detect (select 1) (enable 0))`;
- `(timing-policy (setup-admission adjacent))`.

The generated completer samples `PADDR`, `PWRITE`, `PWDATA`, `PPROT`,
`PSTRB`, and `wait_cycles` on every admitted setup phase, including an
adjacent setup after the prior access response. It decodes byte address `0`
to `reg0`, byte address `2` to `reg1`, and reports unmapped addresses with
`PSLVERR`.

The timing policy does not weaken data16 byte-lane behavior or protection
behavior. Allowed mapped reads return 16-bit register data. Allowed mapped
writes update only selected byte lanes: `PSTRB[0]` updates bits `[7:0]` and
`PSTRB[1]` updates bits `[15:8]`. `PSTRB=0` remains a successful no-byte
write when the mapped write is allowed.

Denied reads complete with `PREADY=1`, `PSLVERR=1`, and `PRDATA=0`. Denied
writes complete with `PREADY=1`, `PSLVERR=1`, and no storage update,
including denied writes with `PSTRB=0`.

## Selected Fixed Composition

The selected fixed composition combines:

- the `.625` sideband data16 requester with `accepted`, `busy`,
  `status width 2`, `done`, `last_error`, and `last_read_data width 16`;
- requester `req_wdata width 16`, `req_prot width 3`, and
  `req_wstrb width 2`;
- requester timing policy `(back-to-back queued)`, `(queue-depth 1)`, and
  `(overflow reject)`;
- the selected protected data16 two-register adjacent setup completer above;
- one requester child and one completer child;
- fixed sideband-aware APB wiring with 32-bit address, 16-bit data,
  `PPROT width 3`, and `PSTRB width 2`;
- no top-level `apb-composition` timing-policy clause.

The generated top exposes requester `accepted`, `busy`, `status`, `done`,
`last_error`, and `last_read_data` outputs. The fixed composition wires
requester `PPROT`, `PSTRB`, and `PWDATA` into the protected data16 completer,
so a queued requester transfer can be sampled by the completer on the
adjacent setup cycle. Protection enforcement remains owned by the completer.

## Reports And Support Accounting

Selected standalone reports add the existing endpoint `timing_policy` shape
and preserve both `width_policy` and `protection_policy` metadata. Selected
fixed-composition reports add aggregate `back_to_back_policy` metadata and
preserve `protection_policy.enforcement_owner = completer`.

The four selected surfaces remove broad `apb_back_to_back_policy_deferred`
residue. They retain:

- `apb_additional_back_to_back_policies_deferred` for unselected APB timing
  families;
- `apb_additional_protection_policies_deferred` for unsupported `PPROT`
  predicates, global/window/interconnect-owned policy, runtime policy, and
  broader protection-policy semantics;
- `apb_remaining_widths_deferred` for data widths beyond the selected
  sideband-aware 16/32-bit boundary, alternate address widths, and alternate
  wait-count widths;
- `apb_interconnect_multi_peripheral_decode_deferred` for unselected
  multi-peripheral timing/decode propagation on standalone and fixed
  surfaces.

Support-accounting identities added in this slice:

- `intent.ppif_apb_completer_multi_register_sideband_data16_protection_back_to_back`
- `intent.apb_profile_alias_completer_multi_register_sideband_data16_protection_back_to_back`
- `intent.ppif_apb_composition_multi_register_sideband_data16_protection_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_register_sideband_data16_protection_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_completer_multi_register_sideband_data16_protection_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_completer_multi_register_sideband_data16_protection_back_to_back_pipeline_cli`
- `ial2_ppif_apb_composition_multi_register_sideband_data16_protection_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_register_sideband_data16_protection_status_back_to_back_pipeline_cli`

## CLI Examples

Emit schedule JSON for the protected data16 standalone completer:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif
```

Run strict check JSON for the `.apb` fixed-composition alias:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-data16-protection-btb \
  --output /tmp/fsmgen-apb-data16-protection-btb/apb_tb.sv \
  ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif
```

## Deferred Work

- broader multi-peripheral multi-register timing beyond the `.634` selected
  status/control data16-protection composition;
- broader multi-peripheral multi-register timing propagation;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
- additional `PPROT` predicates and broader protection-policy ownership;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

Focused validation for this slice includes:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1471-ial2-apb-completer.t
perl -Iperl -c t/1472-ial2-apb-composition.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/1471-ial2-apb-completer.t
prove -Iperl t/1472-ial2-apb-composition.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

Direct probes cover strict check JSON for all four selected `.ppif` and
`.apb` sources. Closeout also runs Knowledge Map generation/check, mdBook
build, memory, diff, and doctrine gates.

## Rollback

Rollback removes the four selected public samples, the selected protected
data16 timing guard widening in `ApbCompleter` and `ApbComposition`, the
support-accounting entries, focused tests, this behavior record, its
Knowledge Map fact card, README, ROADMAP_V2, mdBook, task tree, Memory, and
generated Knowledge Map updates. Existing 32-bit timing, sideband timing,
data16 no-policy timing, 32-bit protection timing, APB data16/protection
behavior without timing, AXI, AHB, and VHDL behavior remain owned by earlier
or future slices.
