# IAL2 APB Multi-Peripheral Data16 Protection Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.634`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected APB sideband-aware multi-peripheral data16-protection
  back-to-back timing-policy behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.634` implements the `.633` selected APB
sideband-aware multi-peripheral data16-protection back-to-back timing-policy
contract for exactly two public sources:

- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb`

The selected sources keep the existing one-requester/two-peripheral
status/control topology, 32-bit APB addresses, 16-bit `PWDATA`, `PRDATA`, and
register data, `PPROT width 3`, `PSTRB width 2`, and 2-byte-aligned address
windows. They add requester `accepted/busy/status` depth-1 queued timing,
adjacent setup admission on both peripheral completers, aggregate
multi-peripheral `back_to_back_policy` reporting, and propagation-only
interconnect decode for queued setup cycles.

Sources still lower through generated `.isf` review artifacts before
generated `.fsm` artifacts, then through the current SystemVerilog backend.
The outstanding execution model is unchanged: there is still at most one
active APB bus transfer and one requester-side queued next transfer.

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

Both peripheral completers contain exactly two protected 16-bit registers at
byte addresses `0` and `2`. The status peripheral allows reads and requires
privileged `PPROT[0] == 1` for writes. The control peripheral requires
privileged `PPROT[0] == 1` for reads and writes. Protection enforcement is
owned by the peripheral completers; the generated interconnect only fans out
`PPROT` and `PSTRB`, performs decoded select/local-address translation, muxes
selected responses, and completes unmapped active accesses with `PSLVERR`.

## Timing And Data Semantics

The requester accepts one active transfer and one queued next transfer. It
pulses `accepted` when a `start` request is sampled into either the active
slot or the empty depth-1 queued slot. When a queued transfer follows a
completed access, the requester drives adjacent setup with `PENABLE=0` and
relaunches queued `PADDR`, `PWRITE`, `PWDATA`, `PPROT`, and 2-bit `PSTRB`.

The interconnect does not insert an idle cycle for selected queued setup
propagation. It decodes the current setup `PSEL/PADDR` with `PENABLE=0`,
forwards 16-bit `PWDATA`, `PPROT`, and 2-bit `PSTRB` to the selected
peripheral window, subtracts the control base for `PADDR_CONTROL`, and muxes
only the selected peripheral response.

The peripheral completers preserve existing data16/protection behavior under
adjacent setup:

- allowed mapped reads return 16-bit register data;
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
- `composition.address_map.alignment_bytes = 2`;
- `protection_policy.enforcement_owner = peripheral_completers`;
- `protection_policy.interconnect_role =
  propagate_pprot_pstrb_and_mux_selected_response_only`.

The two selected surfaces remove broad `apb_back_to_back_policy_deferred`
residue. They retain:

- `apb_additional_back_to_back_policies_deferred` for unselected timing
  variants;
- `apb_additional_protection_policies_deferred` for unsupported protection
  policy families;
- `apb_remaining_widths_deferred` for unselected widths.

Support-accounting identities added in this slice:

- `intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_sideband_data16_protection_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_pipeline_cli`

## CLI Examples

Emit schedule JSON for the selected `.ppif` composition:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif
```

Run strict check JSON for the public `.apb` alias:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-mp-data16-protection-btb \
  --output /tmp/fsmgen-apb-mp-data16-protection-btb/apb_tb.sv \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif
```

## Deferred Work

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
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -c t/1470-ial2-apb-profile-alias.t
perl -c t/1472-ial2-apb-composition.t
prove -Iperl t/1470-ial2-apb-profile-alias.t t/1472-ial2-apb-composition.t
prove -Iperl t/248-regression-corpus-accounting.t t/297-capability-manifest.t
```

Direct probes cover strict check JSON for both selected `.ppif` and `.apb`
sources, schedule JSON for the selected `.ppif`, and semantic JSON for the
selected `.ppif`. Closeout also runs Knowledge Map generation/check, mdBook
build, memory, diff, and doctrine gates.

The grouped RAM-guarded focused test command was attempted, but the guard
stopped before tests because the host baseline was already above the default
88% host-memory cutoff. The same focused tests passed directly.

## Rollback

Rollback removes the two selected public samples, the selected
multi-peripheral data16-protection timing guard widening in `ApbComposition`
and endpoint shape admission in `ApbCompleter`, the support-accounting
entries, focused tests, this behavior record, its Knowledge Map fact card,
README, ROADMAP_V2, mdBook, task tree, Memory, and generated Knowledge Map
updates. Existing no-sideband, sideband, data16, protection, fixed
composition, and non-timing multi-peripheral APB behavior remains owned by
earlier slices.
