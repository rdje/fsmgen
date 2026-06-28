# IAL2 APB sideband data16 behavior

Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.594`

## Implemented public surface

The selected alternate-width APB surface is bounded to sideband-aware 16-bit data
contracts. Existing 32-bit APB requester, completer, fixed composition, and
multi-peripheral composition samples remain unchanged.

Update `.625`: the selected sideband-aware data16 back-to-back timing family
now ships separately. See `docs/IAL2_APB_DATA16_BACK_TO_BACK_BEHAVIOR.md`.

New support-accounted samples:

- `ppif/apb_requester_transfer_sideband_data16.ppif`
- `ppif/apb_completer_multi_register_sideband_data16.ppif`
- `ppif/apb_composition_multi_register_sideband_data16.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_data16.ppif`
- Matching `.apb` aliases for each of those paths.

The selected identities are:

- `intent.ppif_apb_requester_transfer_sideband_data16`
- `intent.ppif_apb_completer_multi_register_sideband_data16`
- `intent.ppif_apb_composition_multi_register_sideband_data16`
- `intent.ppif_apb_composition_multi_peripheral_sideband_data16`
- `intent.apb_profile_alias_requester_transfer_sideband_data16`
- `intent.apb_profile_alias_completer_multi_register_sideband_data16`
- `intent.apb_profile_alias_composition_multi_register_sideband_data16`
- `intent.apb_profile_alias_composition_multi_peripheral_sideband_data16`

## Width contract

The data16 contract keeps APB address and control widths stable:

- `PADDR`, request address, decoded register addresses, and address-map
  base/size parameters remain 32 bits.
- `wait_cycles` remains 4 bits.
- requester response `status` remains 2 bits.
- `PPROT` remains 3 bits when sidebands are present.
- `PWDATA`, `PRDATA`, request write data, response read data, and register data
  are 16 bits for the data16 variants.
- `PSTRB` and request `write-strobe` are derived from data width. The data16
  variants use width 2; the existing 32-bit sideband variants keep width 4.

The generator rejects 16-bit APB data contracts without the complete sideband
bundle because the selected alternate-width slice is sideband-aware only. It also
rejects strobe widths that do not match `data_width / 8`.

## Generated behavior

Requester data16 lowering samples 16-bit request write data and drives 16-bit
`PWDATA`. On writes, it drives `PSTRB` as:

```text
(& wstrb (concat is_write is_write))
```

Reads drive `PSTRB` to zero through the existing done/idle phase behavior.

Completer data16 lowering samples 16-bit `PWDATA`, 2-bit `PSTRB`, and 3-bit
`PPROT` during setup. Byte lane writes use two masks:

- `PSTRB[0]` updates `PWDATA[7:0]` with `16'h00ff` while preserving
  `16'hff00`.
- `PSTRB[1]` updates `PWDATA[15:8]` with `16'hff00` while preserving
  `16'h00ff`.

If `PSTRB` is zero, the mapped write completes without changing any byte lane.
Read, unmapped-address, wait-cycle, and `PSLVERR` behavior remain unchanged.

The fixed data16 composition wires the 16-bit data and 2-bit strobe bus between
the requester and completer. Its second decoded register is at byte address 2.

The multi-peripheral data16 composition propagates 16-bit data and 2-bit strobe
through the generated `apb_interconnect`. Its address map accepts 2-byte-aligned
static 32-bit windows; the shipped sample uses `STATUS_SIZE = 258` and
`CONTROL_BASE = 258` to exercise a 2-byte-aligned, non-4-byte-aligned window
boundary.

## Reports and residue

Generated reports add `width_policy` metadata with the selected data width,
strobe width, address width, wait-count width, register/window alignment, and
the selected `sideband_data16` contract where applicable.

The data16 reports replace the broad `apb_alternate_widths_deferred` residue
with `apb_remaining_widths_deferred`. Remaining future APB width work is limited
to address widths other than 32 bits, wait-count widths other than 4 bits, and
data widths beyond the selected sideband-aware 16/32-bit boundary.

Still deferred: 8-bit data, 64-bit data, non-byte-multiple widths, runtime or
mixed endpoint widths, alternate address widths, alternate wait-count widths,
PPROT access-control effects, back-to-back transfer policy beyond the selected
sideband-aware data16 fixed multi-register status family, direct backend
lowering, verification-output generation, backend-language variants, AXI, AHB,
and VHDL.

## Verification

Focused checks:

```sh
prove -l t/1470-ial2-apb-profile-alias.t
prove -l t/1471-ial2-apb-completer.t
prove -l t/1472-ial2-apb-composition.t
```

Support-accounting checks:

```sh
prove -l t/248-regression-corpus-accounting.t
prove -l t/297-capability-manifest.t
```
