# IAL2 APB Generalized Multi-Peripheral Multi-Register Source-Shape Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.659`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for the first bounded generalized APB
  multi-peripheral multi-register source-shape family

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.659` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.660` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.apb`

The selected family is the first generalized source-shape step after the
exact `reg0`/`reg1` 16/32-bit no-policy/protection and status/control
protected two-peripheral timing families shipped. It remains intentionally
bounded: 32-bit sideband-aware APB, one requester, exactly two peripheral
completers, no register-local access policies, source-ordered `reg0..regN`
storage, two to four registers per peripheral, identical register sets across
both peripherals, depth-1 queued requester timing, adjacent setup on every
peripheral, overflow `reject`, and propagation-only interconnect decode.

No parser behavior, generator behavior, public source file,
support-accounting catalog entry, validation behavior, generated artifact,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this selector slice.

## Evidence Read

This selection read:

- `.658` generalized source-shape readiness audit;
- `.657` generalized timing/source-shape selector;
- `.656/.655` 32-bit protected `reg0`/`reg1` behavior and contract;
- `.654` generalized timing readiness audit;
- shipped 16/32-bit no-policy/protection/status-control multi-peripheral
  records;
- current `ApbCompleter` storage normalization, storage reporting, and
  multi-register IAL1 emission;
- current `ApbComposition` fixed and multi-peripheral timing guards and
  residue text;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused APB/profile-alias
  support surfaces, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge
  Map, and relevant decisions.

`ApbCompleter` already normalizes source-ordered multi-register storage,
enforces unique register names, unique addresses, unique data signals,
32-bit addresses, data-width-matched registers, data-derived alignment, reset
`0`, and optional register-local access policies. Its generated IAL1 emission
iterates all normalized registers for storage, read drives, writes, address
hit detection, byte-lane updates, and report data.

The remaining boundary is the selected timing guard. `ApbCompleter` and
`ApbComposition` intentionally accept adjacent/back-to-back timing only for
exact selected families today. `.660` must widen that guard only for this
contract's bounded 32-bit no-policy register-set family and keep all other
generalized shapes fail-closed.

## Selected Public Sources

`.660` shall add exactly these public source pairs:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.apb`

The selected `.apb` profile alias must mirror the `.ppif` source and lower
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-generalized-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-generalized-status-back-to-back`.

The representative public source shall use three registers per peripheral so
the behavior proves the contract is beyond the already shipped two-register
`reg0`/`reg1` exact families. The implementation may accept two, three, or
four registers when every other selected rule below matches; it must keep five
or more registers fail-closed until a future owner selects a broader
cardinality.

No standalone requester, standalone completer, fixed-composition, data16,
protection-policy, status/control protected-storage, more-than-two-peripheral,
AXI, AHB, VHDL, direct-backend, or verification-output source is selected in
`.659`.

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

## Selected Generalized Register Set

Both selected peripheral completers use the same local no-policy register-set
shape:

- register count is `2`, `3`, or `4`;
- register names are exactly `reg0`, `reg1`, ..., `regN` in source order;
- register local byte addresses are exactly `0`, `4`, ..., `4*N`;
- every register address width is `32`;
- every register data width is `32`;
- every reset value is `0`;
- no register has an `access-policy` clause;
- both peripheral completers have the same register count, names, local byte
  addresses, address widths, data widths, resets, and absence of
  access-policy clauses;
- register data signal names remain unique within each peripheral and may use
  peripheral-specific prefixes such as `status_reg2_data_q` and
  `control_reg2_data_q`.

The public source selected in `.660` shall use:

- `reg0` at local address `0`;
- `reg1` at local address `4`;
- `reg2` at local address `8`.

## Interconnect Timing Contract

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
- `children[2].transfer.registers = [reg0, reg1, reg2]` for the public
  representative source;
- `children[3].transfer.registers = [reg0, reg1, reg2]` for the public
  representative source.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` residue for this selected
family. They shall retain narrowed residue for:

- unselected APB timing-policy families;
- broader APB register-set cardinalities beyond four registers;
- APB protection-policy effects, because `PPROT/PSTRB` are propagated but no
  register-local access policy is enforced in this no-policy family;
- data16 generalized register sets;
- more-than-two-peripheral generalized register sets;
- direct backend, verification-output, backend-language variants, AXI, AHB,
  and VHDL.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back_pipeline_cli`

## Diagnostics

`.660` must keep diagnostics fail-closed. The selected widening may accept
only this bounded generalized no-policy register-set family, in addition to
already shipped exact multi-peripheral timing families. It must reject
unsupported combinations, including:

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
- generalized register-set storage with fewer than two or more than four
  registers;
- register names not following source-ordered `reg0..regN`;
- local byte addresses not following `0, 4, ..., 4*N`;
- mismatched register sets between the two peripheral completers;
- duplicate register names, addresses, or data signals;
- register reset values other than `0`;
- any register-local `access-policy` clause;
- data16 generalized register sets;
- broader protected or policy-bearing storage shapes;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation

`.660` closeout validation must cover:

- parser/source existence for the selected `.ppif` and `.apb` alias;
- schedule JSON aggregate `back_to_back_policy`;
- semantic/check JSON support-accounting identities;
- status/control windows at `0` and `256`;
- both peripheral completers carrying `reg0/reg1/reg2` at local addresses
  `0/4/8`;
- 32-bit `PWDATA/PRDATA`, `PPROT width 3`, and `PSTRB width 4`;
- queued requester relaunch of `PWDATA`, `PPROT`, and `PSTRB`;
- no interconnect-owned protection predicate;
- generated review artifacts and HDL shape;
- malformed storage diagnostics for wrong `reg2` address, wrong register
  count, mismatched peripheral register sets, and accidental access-policy
  clauses;
- RegressionCorpus, LanguageSurfaceSection, capability manifest, README,
  ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

## Deferred Boundaries

This contract does not select:

- data16 generalized register sets;
- protected generalized register sets;
- more than four registers;
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

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this selector.
