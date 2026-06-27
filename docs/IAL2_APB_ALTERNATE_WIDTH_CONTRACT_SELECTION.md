# IAL2 APB Alternate-Width Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.593`

Date: 2026-06-27

## Summary

`.593` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.594`, direct bounded
implementation of a first APB alternate data/strobe width contract.

The selected contract changes no behavior in `.593`. It records exact source
syntax, width bounds, generated-artifact expectations, report/support shape,
diagnostics, validation, and rollback for `.594`.

## Selected Width Matrix

The first alternate-width implementation widens only the APB data/strobe axis:

- existing 32-bit APB data remains supported unchanged;
- new sideband-aware APB sample variants may use 16-bit write/read/register
  data;
- `PSTRB` and requester `write-strobe` width are derived from data width:
  `PSTRB width = data_width / 8`;
- for the selected 16-bit variants, `PSTRB` and requester write-strobe width
  are 2;
- `PPROT` remains fixed at width 3;
- address width remains fixed at 32;
- address-map base/size parameter widths remain fixed at 32;
- completer `wait_cycles` width remains fixed at 4;
- requester status width remains fixed at 2.

The first behavior owner must not accept 8-bit, 64-bit, non-byte-multiple,
runtime-selected, or mixed-endpoint data widths. It must also keep alternate
address widths and alternate wait-count widths deferred.

## Selected Source Syntax

No new clause spelling is introduced. The selected source syntax reuses the
existing width-bearing APB clauses with a 16-bit data width and 2-bit strobe
width on new sideband-aware variants.

Requester variants use:

```lisp
(request
  (start start)
  (write req_write)
  (address req_addr width 32)
  (write-data req_wdata width 16)
  (protection req_prot width 3)
  (write-strobe req_wstrb width 2))
(response
  ...
  (read-data read_data width 16)
  ...)
(bus
  (address PADDR width 32)
  (write PWRITE)
  (write-data PWDATA width 16)
  (protection PPROT width 3)
  (strobe PSTRB width 2)
  ...
  (read-data PRDATA width 16)
  ...)
```

Completer variants use 16-bit `write-data`, `read-data`, and register data,
while register addresses remain width 32. Register addresses must be aligned
to the selected data byte count, so the 16-bit first slice uses 2-byte
alignment.

Composition wiring must match requester, completer, interconnect, and
peripheral bus widths exactly. Multi-peripheral address-map base/size defaults
remain width 32 and must be aligned to the selected data byte count.

## Selected Behavior

Requester behavior for the selected 16-bit sideband variants:

- samples 16-bit `req_wdata` and 2-bit `req_wstrb`;
- drives 16-bit `PWDATA` and samples 16-bit `PRDATA`;
- drives `PSTRB` from sampled `req_wstrb` only for write transfers;
- drives `PSTRB` as zero for read transfers;
- drives/samples `PPROT` exactly as the current sideband-aware 32-bit contract.

Completer behavior for the selected 16-bit sideband variants:

- samples 16-bit `PWDATA`, 2-bit `PSTRB`, and 3-bit `PPROT` during APB setup;
- applies `PSTRB[0]` to `PWDATA[7:0]`;
- applies `PSTRB[1]` to `PWDATA[15:8]`;
- preserves unselected register bytes;
- treats `PSTRB=2'b00` as a successful no-byte write when the address hits a
  selected register;
- keeps reads, unmapped-address error behavior, and protection propagation
  unchanged.

Composition behavior wires the selected widths end-to-end. Multi-peripheral
composition propagates 16-bit data and 2-bit `PSTRB` through the generated
`apb_interconnect.isf`/`.fsm` while preserving decoded `PSEL`, local `PADDR`
translation, response muxing, and unmapped active-access `PSLVERR`.

## Selected Samples And Support

`.594` shall add sideband-aware 16-bit `.ppif` and `.apb` sample pairs for:

```text
ppif/apb_requester_transfer_sideband_data16.ppif
ppif/apb_requester_transfer_sideband_data16.apb
ppif/apb_completer_multi_register_sideband_data16.ppif
ppif/apb_completer_multi_register_sideband_data16.apb
ppif/apb_composition_multi_register_sideband_data16.ppif
ppif/apb_composition_multi_register_sideband_data16.apb
ppif/apb_composition_multi_peripheral_sideband_data16.ppif
ppif/apb_composition_multi_peripheral_sideband_data16.apb
```

The selected support-accounting identities mirror those filenames:

```text
intent.ppif_apb_requester_transfer_sideband_data16
intent.apb_profile_alias_requester_transfer_sideband_data16
intent.ppif_apb_completer_multi_register_sideband_data16
intent.apb_profile_alias_completer_multi_register_sideband_data16
intent.ppif_apb_composition_multi_register_sideband_data16
intent.apb_profile_alias_composition_multi_register_sideband_data16
intent.ppif_apb_composition_multi_peripheral_sideband_data16
intent.apb_profile_alias_composition_multi_peripheral_sideband_data16
```

## Reports And Residue

Selected 16-bit reports must expose the selected width policy through existing
binding widths and additive width-policy metadata. They must show:

- data width 16;
- strobe width 2;
- address width 32;
- `PPROT` width 3;
- wait-count width 4;
- register/window alignment of 2 bytes;
- byte-lane mapping for two lanes.

Selected 16-bit reports replace `apb_alternate_widths_deferred` with a
narrower residue for address widths, wait-count widths, and data widths beyond
the selected 16/32-bit boundary. Existing 32-bit samples may keep their current
residue shape unless `.594` explicitly updates their static prose without
changing behavior.

Sideband-aware reports continue to use
`apb_protection_policy_effects_deferred`, because `PPROT` remains propagated
and sampled without access-control effects. Back-to-back transfer policy
remains deferred.

## Diagnostics

`.594` must reject:

- sideband-aware data widths other than 16 or 32 in the first implementation;
- data widths not divisible by 8;
- data width and `PSTRB` width mismatches;
- requester request/bus/response data width mismatches;
- completer bus/register data width mismatches;
- fixed or multi-peripheral composition width mismatches across requester,
  wiring, interconnect, and peripheral completers;
- 16-bit register addresses or address-map windows not aligned to 2 bytes;
- alternate address widths;
- alternate wait-count widths;
- `PPROT` widths other than 3;
- `PSTRB` clauses without the full sideband bundle.

Diagnostics must stay distinct from unsupported object, profile/suffix
mismatch, malformed APB block, duplicate clause, and unknown suffix
diagnostics.

## Validation

The selected implementation owner must run focused syntax checks, direct
schedule/check/semantic/outdir probes for all new sample pairs, preservation
probes for existing APB samples, focused APB prove tests, regression-corpus and
capability-manifest checks, Knowledge Map generation/check, mdBook build,
docs path audit, memory architecture check, diff check, and doctrine gate.

Focused tests should include `t/1470-ial2-apb-profile-alias.t`,
`t/1471-ial2-apb-completer.t`, `t/1472-ial2-apb-composition.t`,
`t/248-regression-corpus-accounting.t`, and
`t/297-capability-manifest.t`.

## Non-Goals

`.593` and the selected `.594` implementation do not add 8-bit data variants,
64-bit or wider data variants, non-byte-multiple data variants, alternate
address widths, alternate wait-count widths, `PPROT` access-control effects,
back-to-back transfer admission, multiple requesters, bus matrices, side
effects beyond byte-lane writes, direct IAL2-to-IAL0 lowering, direct backend
lowering, verification-output generation, backend-language variants, AXI
behavior, AHB behavior, or VHDL behavior.

## Rollback

Rollback of `.593` is doc-only: revert this contract, its fact card,
task-tree frontier updates, README, ROADMAP_V2, mdBook, Memory, and generated
Knowledge Map changes. `.594` rollback, when implemented, must remove the
16-bit samples, parser/generator/report/support-accounting/test changes, and
docs while preserving the current 32-bit APB behavior.
