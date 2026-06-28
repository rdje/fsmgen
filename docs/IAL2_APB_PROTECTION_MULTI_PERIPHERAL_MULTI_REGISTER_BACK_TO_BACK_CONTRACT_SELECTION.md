# IAL2 APB Protection Multi-Peripheral Multi-Register Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.655`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for bounded APB sideband-aware
  32-bit protected `reg0`/`reg1` multi-peripheral multi-register
  back-to-back timing behavior

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.655` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.656` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.apb`

The selected family is the 32-bit counterpart of the shipped `.649`
data16-protection `reg0`/`reg1` multi-peripheral multi-register family. It
combines the shipped `.628` 32-bit protected `reg0`/`reg1` adjacent-completer
behavior, the shipped `.642` 32-bit no-policy `reg0`/`reg1`
multi-peripheral multi-register topology, and the shipped `.638` 32-bit
multi-peripheral protected timing/interconnect behavior.

No parser behavior, generator behavior, public source file,
support-accounting catalog entry, validation behavior, generated artifact,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this selector slice.

## Evidence Read

This selection read:

- `.654` generalized multi-peripheral multi-register timing readiness audit;
- `.653` status/control protected-storage residue cleanup;
- `.649/.648` data16 protected `reg0`/`reg1`
  multi-peripheral multi-register behavior and contract;
- `.642/.641` 32-bit no-policy `reg0`/`reg1`
  multi-peripheral multi-register behavior and contract;
- `.638/.637` 32-bit status/control protected multi-peripheral behavior and
  contract;
- `.628/.627` 32-bit protected `reg0`/`reg1` fixed-composition behavior and
  contract;
- current `ApbComposition` and `ApbCompleter` shape guards/residue;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused APB/profile-alias,
  support-accounting, and capability tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

The current implementation already recognizes the selected 32-bit protected
`reg0`/`reg1` shape for standalone and fixed-composition adjacent setup in
`ApbCompleter` and fixed-composition `ApbComposition` paths. The
multi-peripheral timing compatibility guard accepts 32-bit no-policy
`reg0`/`reg1` storage and 32-bit status/control protected storage, but does
not yet accept 32-bit protected `reg0`/`reg1` storage on both peripheral
completers.

A temporary exact-name candidate derived from the shipped `.649` data16 source
with 32-bit data/strobe/address/window changes failed closed at the current
multi-peripheral timing guard:

```text
APB multi-peripheral selected back-to-back timing-policy supports only one-register peripheral completer storage, the selected two-peripheral sideband no-policy reg0/reg1 storage shape, or the selected two-peripheral sideband protection status/control storage shape in this slice
```

That fail-closed boundary makes direct implementation appropriate for `.656`,
but only after this public contract selection.

## Selected Public Sources

`.656` shall add exactly these public source pairs:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.apb`

The selected `.apb` profile alias must mirror the `.ppif` source and lower
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-protection-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-protection-status-back-to-back`.

No standalone requester, standalone completer, fixed-composition,
data16-protection, status/control protected-storage, arbitrary register-shape,
AXI, AHB, VHDL, direct-backend, or verification-output source is selected in
`.655`.

## Selected Source Contract

The selected source is intentionally narrow:

- one requester and exactly two peripheral completers;
- requester object `apb_requester`;
- peripheral objects `apb_status_regs` and `apb_control_regs`;
- generated interconnect object `apb_interconnect`;
- 32-bit APB address and address-map widths;
- 32-bit request write data, requester read data, `PWDATA`, `PRDATA`, and
  peripheral register data;
- requester request `req_prot width 3` and `req_wstrb width 4`;
- APB bus and every peripheral bus use `PPROT width 3` and `PSTRB width 4`;
- requester response fields include `accepted`, `busy`, `status width 2`,
  `done`, `last_read_data width 32`, and `last_error`;
- requester transfer policy is `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- every peripheral completer transfer policy is `(timing-policy
  (setup-admission adjacent))`;
- static non-overlapping address-map/decode keeps the current 32-bit
  status/control window shape;
- the composition itself has no top-level timing-policy clause.

The selected address map is the current 32-bit sideband-aware
multi-peripheral shape:

- status window base default `0`, size default `256`;
- control window base default `256`, size default `256`;
- alignment `4`;
- overlap policy `reject`;
- priority `source-order`;
- unmapped address policy `error`.

## Selected Protected Peripheral Storage

Both selected peripheral completers use the same local protected 32-bit
two-register shape:

- `reg0` at byte address `0`, address width `32`, data width `32`, reset `0`;
- `reg1` at byte address `4`, address width `32`, data width `32`, reset `0`;
- `reg0` access policy: read allow, write require privileged `1`;
- `reg1` access policy: read require privileged `1`, write require
  privileged `1`.

The status peripheral should use unique data signal names such as
`status_reg0_data_q` and `status_reg1_data_q`. The control peripheral should
use `control_reg0_data_q` and `control_reg1_data_q`. Register names remain
local endpoint names and must stay `reg0`/`reg1`.

This slice does not select the already-shipped status/control protected
storage names (`status_reg`, `status_shadow_reg`, `control_reg`,
`control_shadow_reg`) as this explicit multi-register family. That topology
remains owned by `.638`.

## Interconnect And Protection Contract

The generated interconnect remains propagation-only:

- decode the current `PSEL/PADDR` while `PENABLE` is low;
- fan out decoded `PSEL` to the selected status or control peripheral;
- forward `PENABLE`, `PWRITE`, 32-bit `PWDATA`, `PPROT`, and 4-bit `PSTRB`;
- translate `PADDR_CONTROL` by subtracting the selected control base `256`;
- mux selected peripheral `PREADY`, `PRDATA`, and `PSLVERR`;
- complete unmapped accesses only on active `PSEL && PENABLE` cycles;
- do not register the selected peripheral;
- do not insert an idle cycle between a completed access and the queued setup;
- do not enforce any protection policy.

Protection enforcement remains owned by each peripheral completer:

- mapped reads denied by register-local policy return zero data and
  `PSLVERR`;
- mapped writes denied by register-local policy complete with `PSLVERR` and
  no storage update;
- allowed mapped writes update only selected byte lanes;
- `PSTRB=0` is a successful no-byte write when allowed and a
  side-effect-free error when denied;
- unmapped peripheral-local addresses complete with `PSLVERR`.

The outstanding model remains unchanged: at most one active APB bus transfer
and one requester-side queued next transfer.

## Report And Support Movement

Selected reports shall add aggregate `back_to_back_policy` metadata using the
existing multi-peripheral report shape, with requester, interconnect, and
every peripheral endpoint represented.

Selected reports shall preserve:

- `composition.topology = multi_peripheral_interconnect`;
- `composition.width_policy.data_width = 32`;
- `composition.width_policy.strobe_width = 4`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 4`;
- `children[2].transfer.registers = [reg0, reg1]`;
- `children[3].transfer.registers = [reg0, reg1]`;
- `protection_policy.enforcement_owner = peripheral_completers`;
- `protection_policy.interconnect_role =
  propagate_pprot_pstrb_and_mux_selected_response_only`.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` and old
`apb_protection_policy_effects_deferred` residue. They shall retain narrowed
residue for:

- unselected APB timing-policy families;
- broader APB protection-policy effects and ownership models;
- alternate width families beyond the selected 32-bit boundary.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back_pipeline_cli`

## Diagnostics

`.656` must keep diagnostics fail-closed. The selected widening may accept only
the exact new public source family above, in addition to already shipped
multi-peripheral timing families. It must reject unsupported combinations,
including:

- missing requester `accepted/busy/status` timing response;
- requester timing policies other than queued, queue-depth `1`, overflow
  `reject`;
- peripheral transfer policies other than adjacent setup admission;
- peripheral counts other than exactly two;
- partial sideband bundles;
- APB data widths other than `32`;
- `PSTRB` widths other than `4`;
- `PPROT` widths other than `3`;
- address-map shapes outside the selected status/control windows;
- protected peripheral storage with wrong register names, addresses, widths,
  reset values, register count, or register-local access-policy clauses;
- data16-protection `reg0`/`reg1` source movement beyond the already-shipped
  `.649` family;
- status/control protected-storage source movement beyond the already-shipped
  `.638` and `.634` families;
- interconnect-owned or window-level protection policy;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation For `.656`

`.656` must include focused validation covering:

- parser/source existence for the selected `.ppif` and `.apb` alias;
- schedule JSON aggregate `back_to_back_policy`;
- semantic/check JSON support-accounting identities;
- status/control windows at `0` and `256`;
- both peripheral completers carrying `reg0`/`reg1` at local addresses `0`
  and `4`;
- 32-bit `PWDATA/PRDATA`, `PPROT width 3`, and `PSTRB width 4`;
- queued requester relaunch of `PWDATA`, `PPROT`, and `PSTRB`;
- peripheral-owned protection metadata and no interconnect-owned predicate;
- generated review artifacts and HDL shape;
- malformed storage diagnostics for wrong `reg1` address and wrong
  protection policy;
- RegressionCorpus, LanguageSurfaceSection, capability manifest, README,
  ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

Focused commands should include APB module/test syntax checks, focused
`t/1470-ial2-apb-profile-alias.t`, focused `t/1472-ial2-apb-composition.t`,
`t/248-regression-corpus-accounting.t`, `t/297-capability-manifest.t`,
Knowledge Map generation/check, mdBook build, whitespace diff, and
`scripts/check_doctrines.sh`. Broad guarded runs remain subject to the
repository RAM guard policy.

## Deferred Boundaries

This selection does not include:

- arbitrary register counts, names, addresses, reset values, or policy
  matrices;
- more than two peripheral completers;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- interconnect-owned, window-owned, programmable, boolean, multi-predicate, or
  non-privileged protection policy families;
- bus matrices or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation For `.655`

This contract-selection slice used code/doc review plus a temporary exact-name
candidate guard probe. Closeout validation passed Knowledge Map
generation/check, mdBook build, whitespace diff, fact-card reverify, syntax
checks for `ApbComposition.pm`, `ApbCompleter.pm`, `t/1470`,
`t/1472`, `t/248`, and `t/297`, and `scripts/check_doctrines.sh`.

## Rollback

Rollback of the future `.656` implementation removes only the two selected
public samples, the selected multi-peripheral 32-bit protected `reg0`/`reg1`
timing guard widening in `ApbComposition`, support-accounting entries,
focused tests, behavior docs, Knowledge Map fact card, README, ROADMAP_V2,
mdBook, task tree, Memory, and generated Knowledge Map updates. Existing
32-bit/data16 no-policy multi-peripheral multi-register timing, data16
protected `reg0`/`reg1` multi-peripheral multi-register timing, 32-bit/data16
status/control protected multi-peripheral timing, fixed-composition protected
timing, AXI, AHB, and VHDL behavior remains owned by earlier slices.
