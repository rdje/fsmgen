# IAL2 APB No-Policy Multi-Peripheral Multi-Register Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.642`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected 32-bit sideband-aware no-policy APB multi-peripheral
  multi-register back-to-back timing-policy behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.642` implements the `.641` selected APB
no-policy multi-peripheral multi-register back-to-back timing-policy contract
for exactly two public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.apb`

The selected sources keep the existing one-requester/two-peripheral
status/control topology, 32-bit APB addresses, 32-bit `PWDATA`, `PRDATA`, and
register data, `PPROT width 3`, `PSTRB width 4`, and 4-byte-aligned address
windows. They add requester `accepted/busy/status` depth-1 queued timing,
adjacent setup admission on both two-register no-policy peripheral completers,
aggregate multi-peripheral `back_to_back_policy` reporting, and
propagation-only interconnect decode for queued setup cycles.

Sources still lower through generated `.isf` review artifacts before
generated `.fsm` artifacts, then through the current SystemVerilog backend.
The outstanding execution model is unchanged: at most one active APB bus
transfer and one requester-side queued next transfer.

## Selected Contract

The selected composition uses:

- one `apb-requester apb_requester`;
- one generated `apb_interconnect`;
- one `apb-completer apb_status_regs` peripheral named `status`;
- one `apb-completer apb_control_regs` peripheral named `control`;
- requester `req_wdata width 32`, `req_prot width 3`, and
  `req_wstrb width 4`;
- requester response fields `accepted`, `busy`, `status width 2`, `done`,
  `last_error`, and `last_read_data width 32`;
- requester timing policy `(back-to-back queued)`, `(queue-depth 1)`, and
  `(overflow reject)`;
- status window base `0`, size `256`;
- control window base `256`, size `256`;
- address-map alignment `4`;
- interconnect unmapped policy `active_access_only`;
- adjacent setup admission on both peripheral completers.

Both peripheral completers contain exactly two no-policy 32-bit registers:

- `reg0` at byte address `0`, address width `32`, data width `32`, reset `0`;
- `reg1` at byte address `4`, address width `32`, data width `32`, reset `0`;
- no register-local `access-policy` clauses.

The status peripheral uses `status_reg0_data_q` and `status_reg1_data_q`.
The control peripheral uses `control_reg0_data_q` and
`control_reg1_data_q`. Register names remain local endpoint names
`reg0`/`reg1`.

## Timing And Data Semantics

The requester accepts one active transfer and one queued next transfer. It
pulses `accepted` when a `start` request is sampled into either the active
slot or the empty depth-1 queued slot. When a queued transfer follows a
completed access, the requester drives adjacent setup with `PENABLE=0` and
relaunches queued `PADDR`, `PWRITE`, `PWDATA`, `PPROT`, and 4-bit `PSTRB`.

The interconnect does not insert an idle cycle for selected queued setup
propagation. It decodes the current setup `PSEL/PADDR` with `PENABLE=0`,
forwards 32-bit `PWDATA`, `PPROT`, and 4-bit `PSTRB` to the selected
peripheral window, subtracts the control base `256` for `PADDR_CONTROL`, and
muxes only the selected peripheral response. It remains enforcement-free:
`PPROT` is propagated, but no access-control predicate is evaluated in the
interconnect.

The no-policy peripheral completers preserve existing sideband multi-register
behavior under adjacent setup:

- mapped reads return the selected 32-bit register data;
- mapped writes update only selected byte lanes;
- `PSTRB[0]` updates bits `[7:0]`;
- `PSTRB[1]` updates bits `[15:8]`;
- `PSTRB[2]` updates bits `[23:16]`;
- `PSTRB[3]` updates bits `[31:24]`;
- `PSTRB=0` is a successful no-byte write;
- no mapped read or write is denied by `PPROT`;
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

- `composition.width_policy.data_width = 32`;
- `composition.width_policy.strobe_width = 4`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 4`;
- `children[2].transfer.registers = [reg0, reg1]`;
- `children[3].transfer.registers = [reg0, reg1]`.

The two selected surfaces remove broad `apb_back_to_back_policy_deferred`
residue. They retain:

- `apb_additional_back_to_back_policies_deferred` for unselected timing
  variants;
- `apb_protection_policy_effects_deferred` because `PPROT` is propagated but
  this no-policy family has no register-local access policy;
- `apb_alternate_widths_deferred` for unselected APB widths.

Support-accounting identities added in this slice:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_status_back_to_back_pipeline_cli`

## CLI Examples

Emit schedule JSON for the selected `.ppif` composition:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif
```

Run strict check JSON for the public `.apb` alias:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-mp-mreg-sideband-btb \
  --output /tmp/fsmgen-apb-mp-mreg-sideband-btb/apb_tb.sv \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif
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

- sideband data16 no-policy multi-peripheral multi-register timing;
- data16-protection generalization beyond the selected shipped families;
- generalized multi-peripheral multi-register shapes;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
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
the selected `.ppif` source and strict check JSON plus semantic JSON for the
selected `.apb` alias. Closeout also runs Knowledge Map generation/check,
mdBook build, memory, diff, and doctrine gates.

## Rollback

Rollback removes the two selected public samples, the selected
multi-peripheral no-policy two-register timing guard widening in
`ApbComposition`, the support-accounting entries, focused tests, this behavior
record, its Knowledge Map fact card, README, ROADMAP_V2, mdBook, task tree,
Memory, and generated Knowledge Map updates. Existing one-register
multi-peripheral timing, protected multi-peripheral timing, fixed-composition
multi-register timing, data16/protection behavior, AXI, AHB, and VHDL behavior
remains owned by earlier slices.
