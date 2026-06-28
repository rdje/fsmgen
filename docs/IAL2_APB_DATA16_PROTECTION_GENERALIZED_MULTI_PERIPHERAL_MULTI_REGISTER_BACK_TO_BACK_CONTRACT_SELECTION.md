# IAL2 APB Data16 Protection Generalized Multi-Peripheral Multi-Register Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.667`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for the bounded APB sideband-aware
  data16 protected generalized `reg0..regN` register-set multi-peripheral
  back-to-back timing family

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.667` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.668` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.apb`

The selected family is the data16 protected counterpart of the shipped `.665`
32-bit protected generalized `reg0..regN` family and the shipped `.662`
data16 no-policy generalized family. It preserves the existing data16
protected `reg0`/`reg1` access-policy semantics and extends them
conservatively to `reg2..regN`: `reg0` remains the only
nonprivileged-readable register, while every selected register write and every
`reg1..regN` read requires privileged `PPROT[0] == 1`.

No parser behavior, generator behavior, public source file,
support-accounting catalog entry, validation behavior, generated artifact,
schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB behavior, AXI behavior, AHB behavior, or VHDL
behavior changes in this selector slice.

## Evidence Read

This selection read:

- `.666` post-32-bit protected generalized selector;
- `.665` 32-bit protected generalized behavior;
- `.664` 32-bit protected generalized contract;
- `.662` data16 no-policy generalized behavior;
- `.649/.648` data16 protected `reg0`/`reg1` behavior and contract;
- shipped 16/32-bit no-policy/protection/status-control records;
- current `ApbCompleter` selected data16 protected/no-policy predicates and
  adjacent-setup residue;
- current `ApbComposition` selected data16 multi-peripheral timing guards and
  residue;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused
  APB/profile-alias/support/capability test surfaces, README, ROADMAP_V2,
  mdBook, task tree, Memory, Knowledge Map, and relevant decisions.

The live implementation now ships generalized register-set timing for 32-bit
no-policy, data16 no-policy, and 32-bit protected families. It also ships
exact data16 protected `reg0`/`reg1` and status/control protected families.
The missing public decision is the data16 policy-bearing generalized matrix
for `reg2..regN`.

## Selected Public Sources

`.668` shall add exactly these public source pairs:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.apb`

The selected `.apb` profile alias must mirror the `.ppif` source and lower
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-protection-generalized-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-data16-protection-generalized-status-back-to-back`.

The representative public source shall use three registers per peripheral so
the behavior proves the contract beyond the already shipped two-register
data16 protected `reg0`/`reg1` family. The implementation may accept two,
three, or four registers when every other selected rule below matches; it
must keep five or more registers fail-closed until a future owner selects a
broader cardinality.

No standalone requester, standalone completer, fixed-composition, 32-bit
protected generalized, no-policy generalized, status/control protected-storage,
more-than-two-peripheral, AXI, AHB, VHDL, direct-backend, or
verification-output source is selected in `.667`.

## Selected Source Contract

The selected source is intentionally narrow:

- one requester and exactly two peripheral completers;
- requester object `apb_requester`;
- peripheral objects `apb_status_regs` and `apb_control_regs`;
- generated interconnect object `apb_interconnect`;
- 32-bit APB address and address-map widths;
- 16-bit request write data, requester read data, `PWDATA`, `PRDATA`, and
  peripheral register data;
- requester request `req_prot width 3` and `req_wstrb width 2`;
- APB bus and every peripheral bus use `PPROT width 3` and `PSTRB width 2`;
- requester response fields include `accepted`, `busy`, `status width 2`,
  `done`, `last_read_data width 16`, and `last_error`;
- requester transfer policy is `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- every peripheral completer transfer policy is `(timing-policy
  (setup-admission adjacent))`;
- static non-overlapping address-map/decode keeps the current sideband data16
  status/control window shape;
- the composition itself has no top-level timing-policy clause.

The selected address map is the current sideband data16 multi-peripheral
shape:

- status window base default `0`, size default `258`;
- control window base default `258`, size default `258`;
- alignment `2`;
- overlap policy `reject`;
- priority `source-order`;
- unmapped address policy `error`.

## Selected Protected Generalized Register Set

Both selected peripheral completers use the same local protected data16
register-set shape:

- register count is `2`, `3`, or `4`;
- register names are exactly `reg0`, `reg1`, ..., `regN` in source order;
- register local byte addresses are exactly `0`, `2`, ..., `2*N`;
- every register address width is `32`;
- every register data width is `16`;
- every reset value is `0`;
- every register has an access-policy clause matching the selected matrix
  below;
- both peripheral completers have the same register count, names, local byte
  addresses, address widths, data widths, resets, and access-policy matrix;
- register data signal names remain unique within each peripheral and may use
  peripheral-specific prefixes such as `status_reg2_data_q` and
  `control_reg2_data_q`.

The public source selected in `.668` shall use:

- `reg0` at local address `0`;
- `reg1` at local address `2`;
- `reg2` at local address `4`.

## Selected Access-Policy Matrix

The selected policy matrix is the data16 counterpart of the shipped `.665`
protected generalized contract:

- `reg0` read: allow;
- `reg0` write: require privileged `PPROT[0] == 1`;
- every `regN` where `N >= 1` read: require privileged `PPROT[0] == 1`;
- every `regN` where `N >= 1` write: require privileged `PPROT[0] == 1`.

The matrix deliberately keeps `reg0` as the only nonprivileged-readable
register. It does not select interconnect-owned policy, window-owned policy,
programmable policy, boolean policy composition, multi-predicate policy,
nonprivileged write policy, or new nonprivileged reads for `reg1..regN`.

## Interconnect And Protection Contract

The generated interconnect remains propagation-only:

- decode the current `PSEL/PADDR` while `PENABLE` is low;
- fan out decoded `PSEL` to the selected status or control peripheral;
- forward `PENABLE`, `PWRITE`, 16-bit `PWDATA`, `PPROT`, and 2-bit `PSTRB`;
- translate `PADDR_CONTROL` by subtracting the selected control base `258`;
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
- `composition.width_policy.data_width = 16`;
- `composition.width_policy.strobe_width = 2`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 2`;
- `children[2].transfer.registers = [reg0, reg1, reg2]` for the public
  representative source;
- `children[3].transfer.registers = [reg0, reg1, reg2]` for the public
  representative source;
- `protection_policy.enforcement_owner = peripheral_completers`;
- `protection_policy.interconnect_role =
  propagate_pprot_pstrb_and_mux_selected_response_only`.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` and broad selected-family
protection residue for this selected family. They shall retain narrowed
residue for:

- unselected APB timing-policy families;
- broader APB register-set cardinalities beyond four registers;
- more-than-two-peripheral generalized register sets;
- deeper queues, alternate overflow, accepted-less requesters, multiple
  active APB transfers, bus matrices, and scoreboards;
- interconnect-owned, window-owned, programmable, boolean, multi-predicate,
  or nonprivileged protection-policy families;
- direct backend, verification-output, backend-language variants, AXI, AHB,
  and VHDL.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back_pipeline_cli`

## Diagnostics

`.668` must keep diagnostics fail-closed. The selected widening may accept
only this bounded data16 protected generalized register-set family, in
addition to already shipped exact and no-policy generalized multi-peripheral
timing families. It must reject unsupported combinations, including:

- missing requester `accepted/busy/status` timing response;
- requester timing policies other than queued, queue-depth `1`, overflow
  `reject`;
- peripheral transfer policies other than adjacent setup admission;
- peripheral counts other than exactly two;
- partial sideband bundles;
- APB data widths other than `16`;
- `PSTRB` widths other than `2`;
- `PPROT` widths other than `3`;
- address-map shapes outside the selected data16 status/control windows;
- protected generalized storage with fewer than two or more than four
  registers;
- register names not following source-ordered `reg0..regN`;
- local byte addresses not following `0, 2, ..., 2*N`;
- mismatched register sets between the two peripheral completers;
- duplicate register names, addresses, or data signals;
- register reset values other than `0`;
- missing access-policy clauses;
- policy matrices other than the selected matrix, including a
  nonprivileged-readable `reg2`, a missing privileged write requirement, or a
  mixed no-policy/protection register set;
- status/control protected-storage names such as `status_reg` or
  `control_shadow_reg` in this explicit `reg0..regN` family;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation For `.668`

`.668` closeout validation must cover:

- parser/source existence for the selected `.ppif` and `.apb` alias;
- schedule JSON aggregate `back_to_back_policy`;
- semantic/check JSON support-accounting identities;
- status/control windows at `0` and `258`;
- both peripheral completers carrying `reg0/reg1/reg2` at local addresses
  `0/2/4`;
- selected protected policy matrix on `reg0/reg1/reg2`;
- 16-bit `PWDATA/PRDATA`, `PPROT width 3`, and `PSTRB width 2`;
- queued requester relaunch of `PWDATA`, `PPROT`, and `PSTRB`;
- peripheral-owned protection metadata and no interconnect-owned predicate;
- generated review artifacts and HDL shape;
- generated inspection for `reg2` storage, read, write, and access-policy
  predicates;
- malformed storage diagnostics for wrong `reg2` address, wrong register
  count, mismatched peripheries, missing access-policy clauses, and a
  nonprivileged-readable `reg2`;
- RegressionCorpus, LanguageSurfaceSection, capability manifest, README,
  ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

Focused commands should include syntax checks for touched APB modules and
focused tests, direct strict check JSON/semantic JSON/schedule JSON/outdir
probes for the selected `.ppif` and `.apb`, focused
`t/1470-ial2-apb-profile-alias.t`, focused
`t/1472-ial2-apb-composition.t`,
`t/248-regression-corpus-accounting.t`,
`t/297-capability-manifest.t`, Knowledge Map generation/check, mdBook build,
docs path audit, memory architecture check, whitespace diff, and
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
- multiple active APB bus transfers;
- interconnect-owned, window-owned, programmable, boolean, multi-predicate,
  or nonprivileged protection-policy families;
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
