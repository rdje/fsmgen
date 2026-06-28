# IAL2 APB Data16 Protection Multi-Peripheral Multi-Register Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.649`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected sideband-aware data16-protection APB multi-peripheral
  multi-register back-to-back timing-policy behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.649` implements the `.648` selected APB
data16-protection multi-peripheral multi-register back-to-back timing-policy
contract for exactly two public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.apb`

The selected sources keep the existing one-requester/two-peripheral
status/control topology, 32-bit APB addresses, 16-bit `PWDATA`, `PRDATA`, and
register data, `PPROT width 3`, `PSTRB width 2`, and 2-byte-aligned address
windows. They add requester `accepted/busy/status` depth-1 queued timing,
adjacent setup admission on both protected two-register peripheral
completers, aggregate multi-peripheral `back_to_back_policy` reporting, and
propagation-only interconnect decode for queued setup cycles.

Sources still lower through generated `.isf` review artifacts before
generated `.fsm` artifacts, then through the current SystemVerilog backend.
The execution model is unchanged: at most one active APB bus transfer and one
requester-side queued next transfer.

## Selected Contract

The selected composition uses:

- one `apb-requester apb_requester`;
- one generated `apb_interconnect`;
- one `apb-completer apb_status_regs` peripheral named `status`;
- one `apb-completer apb_control_regs` peripheral named `control`;
- requester `req_wdata width 16`, `req_prot width 3`, and
  `req_wstrb width 2`;
- requester response fields `accepted`, `busy`, `status width 2`, `done`,
  `last_error`, and `last_read_data width 16`;
- requester timing policy `(back-to-back queued)`, `(queue-depth 1)`, and
  `(overflow reject)`;
- status window base `0`, size `258`;
- control window base `258`, size `258`;
- address-map alignment `2`;
- interconnect unmapped policy `active_access_only`;
- adjacent setup admission on both peripheral completers.

Both peripheral completers contain exactly two protected 16-bit registers:

- `reg0` at byte address `0`, address width `32`, data width `16`, reset `0`;
- `reg1` at byte address `2`, address width `32`, data width `16`, reset `0`;
- `reg0` reads are allowed;
- `reg0` writes require privileged `PPROT[0] == 1`;
- `reg1` reads require privileged `PPROT[0] == 1`;
- `reg1` writes require privileged `PPROT[0] == 1`.

The status peripheral uses `status_reg0_data_q` and `status_reg1_data_q`.
The control peripheral uses `control_reg0_data_q` and
`control_reg1_data_q`. Register names remain local endpoint names
`reg0`/`reg1`.

## Timing And Protection Semantics

The requester accepts one active transfer and one queued next transfer. It
pulses `accepted` when a `start` request is sampled into either the active
slot or the empty depth-1 queued slot. When a queued transfer follows a
completed access, the requester drives adjacent setup with `PENABLE=0` and
relaunches queued `PADDR`, `PWRITE`, `PWDATA`, `PPROT`, and 2-bit `PSTRB`.

The generated interconnect does not insert an idle cycle for selected queued
setup propagation. It decodes the current setup `PSEL/PADDR` with
`PENABLE=0`, forwards 16-bit `PWDATA`, `PPROT`, and 2-bit `PSTRB` to the
selected peripheral window, subtracts the control base `258` for
`PADDR_CONTROL`, and muxes only the selected peripheral response. It remains
protection-enforcement-free: register-local `PPROT[0]` policy is evaluated
only inside the selected peripheral completers.

The protected data16 peripheral completers preserve existing adjacent setup,
byte-lane, and access-policy behavior:

- allowed mapped reads return the selected 16-bit register data;
- allowed mapped writes update only selected byte lanes;
- `PSTRB[0]` updates bits `[7:0]`;
- `PSTRB[1]` updates bits `[15:8]`;
- `PSTRB=0` is a successful no-byte write when the mapped write is allowed;
- denied reads complete with `PREADY=1`, `PSLVERR=1`, and `PRDATA=0`;
- denied writes complete with `PREADY=1`, `PSLVERR=1`, and no storage update;
- unmapped peripheral-local addresses complete with `PSLVERR`.

## Reports And Support Accounting

Selected reports add aggregate `back_to_back_policy` metadata:

- requester policy: `back_to_back = queued`, `queue_depth = 1`,
  `overflow = reject`, `accepted = accepted`;
- interconnect role: `propagate_queued_setup_without_idle_cycle`;
- interconnect setup decode: `current_psel_paddr_with_penable_low`;
- interconnect response mux: `selected_peripheral_response`;
- interconnect unmapped policy: `active_access_only`;
- both peripherals: `setup_admission = adjacent`.

Selected reports preserve:

- `composition.width_policy.data_width = 16`;
- `composition.width_policy.strobe_width = 2`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 2`;
- `children[2].transfer.registers = [reg0, reg1]`;
- `children[3].transfer.registers = [reg0, reg1]`;
- `protection_policy.enforcement_owner = peripheral_completers`;
- `protection_policy.interconnect_role =
  propagate_pprot_pstrb_and_mux_selected_response_only`.

The two selected surfaces remove broad `apb_back_to_back_policy_deferred` and
old `apb_protection_policy_effects_deferred` residue. They retain:

- `apb_additional_back_to_back_policies_deferred` for unselected timing
  variants;
- `apb_additional_protection_policies_deferred` for unsupported protection
  policy families;
- `apb_remaining_widths_deferred` for unselected APB widths.

Support-accounting identities added in this slice:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back_pipeline_cli`

## CLI Examples

Emit schedule JSON for the selected `.ppif` composition:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif
```

Run strict check JSON for the public `.apb` alias:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-mp-mreg-data16-protection-btb \
  --output /tmp/fsmgen-apb-mp-mreg-data16-protection-btb/apb_tb.sv \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif
```

The generated outdir includes:

- `apb_requester.isf`
- `apb_status_regs.isf`
- `apb_control_regs.isf`
- `apb_interconnect.isf`
- `apb_requester.fsm`
- `apb_status_regs.fsm`
- `apb_control_regs.fsm`
- `apb_interconnect.fsm`
- `apb_tb.fsm`

## Deferred Work

- status/control protected storage generalization beyond the selected shipped
  families;
- generalized multi-peripheral multi-register shapes;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
- bus matrices and scoreboards;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

Focused validation for this slice includes:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -c t/1470-ial2-apb-profile-alias.t
perl -c t/1472-ial2-apb-composition.t
perl -c t/248-regression-corpus-accounting.t
perl -c t/297-capability-manifest.t
prove -Iperl t/1472-ial2-apb-composition.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
```

Direct probes cover schedule JSON, strict check JSON, and semantic JSON for
the selected `.ppif` source and strict check JSON for the selected `.apb`
alias. Closeout also runs Knowledge Map generation/check, mdBook build,
memory, diff, and doctrine gates.

## Rollback

Rollback removes the two selected public samples, the selected
multi-peripheral data16-protection reg0/reg1 timing guard widening in
`ApbComposition`, the support-accounting entries, focused tests, this
behavior record, its Knowledge Map fact card, README, ROADMAP_V2, mdBook,
task tree, Memory, and generated Knowledge Map updates. Existing 32-bit and
data16 no-policy multi-peripheral multi-register timing, data16-protection
status/control multi-peripheral timing, protected multi-peripheral timing,
fixed-composition multi-register timing, AXI, AHB, and VHDL behavior remains
owned by earlier slices.
