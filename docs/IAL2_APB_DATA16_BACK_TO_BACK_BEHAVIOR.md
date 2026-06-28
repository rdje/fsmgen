# IAL2 APB Data16 Back-To-Back Behavior

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.625`
- Date: `2026-06-28`
- Status: shipped
- Scope: selected APB sideband-aware data16 requester, standalone
  two-register completer, and fixed-composition back-to-back timing-policy
  behavior

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.625` implements the `.624` selected APB
sideband-aware data16 back-to-back timing-policy contract for exactly six
public sources:

- `ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_requester_transfer_sideband_data16_status_back_to_back.apb`
- `ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_data16_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.apb`

The selected sources keep APB addresses at 32 bits and wait counts at 4 bits,
while widening the shipped sideband-aware timing path to 16-bit `PWDATA` and
`PRDATA` plus `PSTRB width 2`. The source still lowers through generated
`.isf` review artifacts before generated `.fsm` artifacts, then through the
current SystemVerilog backend.

This slice does not widen the APB outstanding model. There is still at most one
active APB transfer and one queued requester-side next transfer.

## Selected Requester Contract

The selected requester is intentionally narrow:

- one `apb-requester apb_requester`;
- request `start`, `req_write`, and 32-bit `req_addr`;
- request `req_wdata width 16`;
- request `req_prot width 3`;
- request `req_wstrb width 2`;
- response fields `accepted`, `busy`, `status width 2`, `done`,
  `last_read_data width 16`, and `last_error`;
- bus `PADDR width 32`;
- bus `PWDATA width 16`;
- bus `PPROT width 3`;
- bus `PSTRB width 2`;
- bus `PRDATA width 16`;
- transfer `(timing-policy (back-to-back queued) (queue-depth 1)
  (overflow reject))`.

The generated requester captures all accepted request payload fields. The
queued slot includes `queued_valid`, `queued_addr`, `queued_write`,
`queued_wdata width 16`, `queued_prot width 3`, and `queued_wstrb width 2`.
Overflow remains reject-only: if `start` arrives while an APB transfer is
active and the queued slot is already full, `accepted` does not pulse and the
queued payload is not overwritten.

When the active transfer completes and a queued request exists, the generated
FSM relaunches the queued setup without an inserted idle APB cycle. A queued
write drives `PWDATA` from `queued_wdata`, `PPROT` from `queued_prot`, and
`PSTRB` from `queued_wstrb` masked by `(concat queued_write queued_write)`.
The current-request write path masks `req_wstrb` by `(concat is_write is_write)`.
Reads drive `PSTRB` to zero through the existing read/done behavior.

## Selected Completer Contract

The selected standalone completer is the data16 no-policy two-register
extension of the `.622` adjacent setup family:

- one `apb-completer apb_completer`;
- bus `PADDR width 32`;
- bus `PWDATA width 16`;
- bus `PPROT width 3`;
- bus `PSTRB width 2`;
- bus `PRDATA width 16`;
- control `wait_cycles width 4`;
- exactly two source-ordered storage registers;
- `reg0` at address `0`, data width `16`, reset `0`;
- `reg1` at address `2`, data width `16`, reset `0`;
- no register-local `access-policy` clauses;
- `(setup-detect (select 1) (enable 0))`;
- `(timing-policy (setup-admission adjacent))`.

The generated completer samples `PADDR`, `PWRITE`, `PWDATA`, `PPROT`,
`PSTRB`, and `wait_cycles` on `PSEL && !PENABLE`. It decodes byte address `0`
to `reg0`, byte address `2` to `reg1`, reports unmapped addresses with
`PSLVERR`, and admits the next setup phase on an adjacent `PSEL && !PENABLE`
cycle without requiring an inter-transfer idle cycle.

Writes preserve the `.594` data16 byte-lane behavior. `PSTRB[0]` updates
bits `[7:0]`, `PSTRB[1]` updates bits `[15:8]`, and `PSTRB=0` is a successful
mapped no-byte write. `PPROT` is sampled and propagated through the report
surface, but this selected no-policy data16 owner does not enforce
register-local protection-policy effects.

## Selected Fixed Composition

The selected fixed composition combines:

- the selected data16 sideband requester above;
- the selected data16 two-register adjacent setup completer above;
- one requester child and one completer child;
- fixed sideband-aware APB wiring with 32-bit address, 16-bit data,
  `PPROT width 3`, and `PSTRB width 2`;
- no top-level `apb-composition` timing-policy clause.

The generated top exposes the requester `accepted`, `busy`, `status`, `done`,
`last_error`, and `last_read_data` outputs. The fixed composition wires the
requester bus into the completer, so queued requester `PWDATA`, `PPROT`, and
`PSTRB` are sampled by the completer on the adjacent setup cycle. The
composition report derives aggregate `back_to_back_policy` metadata from the
compatible endpoint timing policies.

## Reports And Support Accounting

Selected requester and completer reports add the existing endpoint
`timing_policy` shapes. Selected fixed-composition reports add aggregate
`back_to_back_policy` metadata and preserve the data16 `width_policy` metadata.

The six selected surfaces remove broad `apb_back_to_back_policy_deferred`
residue. They retain:

- `apb_additional_back_to_back_policies_deferred` for unselected APB timing
  families;
- `apb_remaining_widths_deferred` for data widths beyond the selected
  sideband-aware 16/32-bit boundary, alternate address widths, and alternate
  wait-count widths;
- `apb_protection_policy_effects_deferred` because this owner has no
  register-local access-policy clauses.

Support-accounting identities added in this slice:

- `intent.ppif_apb_requester_transfer_sideband_data16_status_back_to_back`
- `intent.apb_profile_alias_requester_transfer_sideband_data16_status_back_to_back`
- `intent.ppif_apb_completer_multi_register_sideband_data16_back_to_back`
- `intent.apb_profile_alias_completer_multi_register_sideband_data16_back_to_back`
- `intent.ppif_apb_composition_multi_register_sideband_data16_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_register_sideband_data16_status_back_to_back`

Coverage buckets added in this slice:

- `ial2_ppif_apb_requester_transfer_sideband_data16_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_requester_transfer_sideband_data16_status_back_to_back_pipeline_cli`
- `ial2_ppif_apb_completer_multi_register_sideband_data16_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_completer_multi_register_sideband_data16_back_to_back_pipeline_cli`
- `ial2_ppif_apb_composition_multi_register_sideband_data16_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_register_sideband_data16_status_back_to_back_pipeline_cli`

## CLI Examples

Emit schedule JSON for the requester:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_requester_transfer_sideband_data16_status_back_to_back.ppif
```

Run strict check JSON for the `.apb` fixed-composition alias:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.apb
```

Generate review artifacts and HDL:

```bash
./bin/fsmgen --quiet --outdir /tmp/fsmgen-apb-data16-btb \
  --output /tmp/fsmgen-apb-data16-btb/apb_tb.sv \
  ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif
```

## Deferred Work

- protection-only timing;
- combined data16-protection timing;
- multi-peripheral multi-register timing propagation;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB bus transfers;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

Focused validation for this slice includes:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -Iperl -c perl/FSM/Support/RegressionCorpus.pm
perl -Iperl -c t/1470-ial2-apb-profile-alias.t
perl -Iperl -c t/1471-ial2-apb-completer.t
perl -Iperl -c t/1472-ial2-apb-composition.t
perl -Iperl -c t/248-regression-corpus-accounting.t
perl -Iperl -c t/297-capability-manifest.t
prove -Iperl t/248-regression-corpus-accounting.t
prove -Iperl t/297-capability-manifest.t
prove -Iperl t/1470-ial2-apb-profile-alias.t
prove -Iperl t/1471-ial2-apb-completer.t
prove -Iperl t/1472-ial2-apb-composition.t
```

Direct probes cover schedule JSON, check JSON, semantic JSON, temporary
generated review artifacts, and generated HDL for all six selected `.ppif` and
`.apb` sources. Closeout also runs Knowledge Map generation/check, mdBook
build, docs path, memory, diff, and doctrine gates.

## Rollback

Rollback removes the six selected public samples, the selected data16 timing
guard widening in `ApbRequesterTransfer`, `ApbCompleter`, and
`ApbComposition`, the support-accounting entries, focused tests, this behavior
record, its Knowledge Map fact card, README, ROADMAP_V2, mdBook, task tree,
Memory, and generated Knowledge Map updates. Existing 32-bit back-to-back
behavior, sideband timing behavior, APB data16 no-policy behavior, APB
protection behavior, AXI, AHB, and VHDL behavior remain owned by earlier or
future slices.
