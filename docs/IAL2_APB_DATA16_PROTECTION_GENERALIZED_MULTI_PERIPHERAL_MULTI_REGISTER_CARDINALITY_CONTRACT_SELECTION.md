# IAL2 APB Data16 Protection Generalized Multi-Peripheral Multi-Register Cardinality Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.680`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for bounded APB sideband-aware
  data16 protected five-register generalized `reg0..regN` register-set
  cardinality widening

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.680` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.681` to directly implement exactly these
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.apb`

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-protection-generalized-five-register-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-data16-protection-generalized-five-register-status-back-to-back`.

This selector changes no parser behavior, generator behavior, public source
file, support-accounting catalog entry, validation behavior, generated
artifact, schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB transaction behavior, AXI behavior, AHB
behavior, or VHDL behavior.

## Evidence Read

This selection read `.679` selector, `.678` 32-bit protected five-register
behavior, `.677` 32-bit protected five-register contract, `.675` data16
no-policy five-register behavior, `.674` data16 no-policy five-register
contract, `.668` data16 protected generalized behavior, `.667` data16
protected generalized contract, `.665` 32-bit protected generalized behavior,
`.670` cardinality audit, current `ApbCompleter` and `ApbComposition`
data16 protected generalized predicates and residue, `RegressionCorpus`,
`LanguageSurfaceSection`, focused APB/profile-alias/support/capability tests,
README, ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant decisions.

The selected direction completes the protected five-register pair after the
32-bit protected five-register sibling shipped. Current data16 protected
generalized helpers still use `maximum_count = 4`; the data16 no-policy and
32-bit protected five-register helpers already use `maximum_count = 5`.

## Selected Public Source Contract

The `.681` implementation shall keep the existing selected data16
sideband-aware protected generalized timing contract and widen only its
cardinality boundary from a maximum of four registers to a maximum of five
registers.

The selected source remains intentionally narrow:

- one requester object named `apb_requester`;
- exactly two peripheral completer objects named `apb_status_regs` and
  `apb_control_regs`;
- one generated interconnect object named `apb_interconnect`;
- one generated top object named `apb_tb`;
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
- the composition itself has no top-level timing-policy clause;
- the interconnect remains propagation-only and owns no protection predicate.

The selected address map remains the data16 status/control shape:

- status window base `0`, size `258`;
- control window base `258`, size `258`;
- alignment `2`;
- overlap policy `reject`;
- priority `source-order`;
- unmapped address policy `error`.

## Selected Protected Generalized Register Set

The admitted data16 protected generalized family after `.681` shall be:

- register count is `2`, `3`, `4`, or `5`;
- register names are exactly `reg0`, `reg1`, ..., `regN` in source order;
- register local byte addresses are exactly `0`, `2`, ..., `2*N`;
- every register address width is `32`;
- every register data width is `16`;
- every reset value is `0`;
- every register has an `access-policy` clause matching the selected matrix
  below;
- both peripheral completers have the same register count, names, local byte
  addresses, address widths, data widths, resets, and access-policy matrix;
- register data signal names remain unique within each peripheral and may use
  peripheral-specific prefixes such as `status_reg4_data_q` and
  `control_reg4_data_q`.

The public representative selected for `.681` shall use five registers per
peripheral:

- `reg0` at local byte address `0`;
- `reg1` at local byte address `2`;
- `reg2` at local byte address `4`;
- `reg3` at local byte address `6`;
- `reg4` at local byte address `8`.

Implementation may widen the current shared data16 protected helper bound for
the selected sideband-aware protected generalized two-peripheral family from
`maximum_count = 4` to `maximum_count = 5`. It must keep more than five
registers fail-closed until a future task-tree owner selects that boundary.

## Selected Access-Policy Matrix

The selected policy matrix is inherited from the shipped data16 protected
generalized family:

- `reg0` read: allow;
- `reg0` write: require privileged `PPROT[0] == 1`;
- every `regN` where `N >= 1` read: require privileged `PPROT[0] == 1`;
- every `regN` where `N >= 1` write: require privileged `PPROT[0] == 1`.

The matrix deliberately keeps `reg0` as the only nonprivileged-readable
register. It does not select interconnect-owned policy, window-owned policy,
programmable policy, boolean policy composition, multi-predicate policy,
nonprivileged write policy, or new nonprivileged reads for `reg1..regN`.

## Interconnect And Protection Contract

The generated interconnect behavior remains unchanged from the selected
data16 protected generalized family:

- decode the current `PSEL/PADDR` while `PENABLE` is low;
- fan out decoded `PSEL` to the selected status or control peripheral;
- forward `PENABLE`, `PWRITE`, 16-bit `PWDATA`, `PPROT`, and 2-bit `PSTRB`;
- translate `PADDR_CONTROL` by subtracting control base `258`;
- mux selected peripheral `PREADY`, `PRDATA`, and `PSLVERR`;
- complete unmapped accesses only on active `PSEL && PENABLE` cycles;
- do not register the selected peripheral;
- do not insert an idle cycle between a completed access and queued setup;
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

The outstanding model remains at most one active APB bus transfer and one
requester-side queued next transfer.

## Report And Support Movement

Selected reports shall preserve aggregate multi-peripheral
`back_to_back_policy` metadata with requester, interconnect, and every
peripheral endpoint represented.

Selected reports shall show:

- `composition.topology = multi_peripheral_interconnect`;
- `composition.width_policy.data_width = 16`;
- `composition.width_policy.strobe_width = 2`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 2`;
- `children[2].transfer.registers = [reg0, reg1, reg2, reg3, reg4]` for the
  public representative source;
- `children[3].transfer.registers = [reg0, reg1, reg2, reg3, reg4]` for the
  public representative source;
- `protection_policy.enforcement_owner = peripheral_completers`;
- `protection_policy.interconnect_role =
  propagate_pprot_pstrb_and_mux_selected_response_only`;
- `children[2].protection_policy.registers[]` and
  `children[3].protection_policy.registers[]` preserve the selected policy
  matrix through `reg4`.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad cardinality residue for this selected data16 protected
five-register family. They shall retain narrowed residue for:

- more than five registers;
- more than two peripheral completers;
- unselected APB timing-policy families;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers;
- interconnect-owned, window-owned, programmable, boolean, multi-predicate,
  or nonprivileged protection-policy families;
- bus matrices and scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back_pipeline_cli`

## Diagnostics

`.681` must keep diagnostics fail-closed. The selected widening may accept
only the bounded data16 sideband-aware protected generalized register-set
family, in addition to already shipped exact APB timing families. It must
reject unsupported combinations, including:

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
- selected data16 protected generalized storage with fewer than two or more
  than five registers;
- register names not following source-ordered `reg0..regN`;
- local byte addresses not following `0, 2, ..., 2*N`;
- mismatched register sets between the two peripheral completers;
- duplicate register names, addresses, or data signals;
- register reset values other than `0`;
- missing register-local `access-policy` clauses;
- policy matrices other than the selected matrix, including a
  nonprivileged-readable `reg4`, a missing privileged write requirement, or a
  mixed no-policy/protection register set;
- more-than-two-peripheral generalized register sets;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation For The Implementation Owner

`.681` closeout validation must cover:

- syntax checks for touched modules and tests;
- byte-for-byte mirror between the selected `.ppif` source and `.apb` alias;
- direct strict check JSON for both public sources;
- semantic JSON and schedule JSON for the selected `.ppif` source;
- outdir generation for the selected `.ppif` source using `--outdir`;
- generated artifact probes for `reg3` and `reg4` storage, read hits, write
  hits, byte-lane writes, read-data drives, and access-policy predicates;
- status/control windows at `0` and `258`;
- both peripheral completers carrying `reg0/reg1/reg2/reg3/reg4` at local
  addresses `0/2/4/6/8`;
- selected protected policy matrix on `reg0/reg1/reg2/reg3/reg4`;
- denied `reg4` read and denied `reg4` write behavior using sampled
  `PPROT[0]`;
- 16-bit `PWDATA/PRDATA`, `PPROT width 3`, and `PSTRB width 2`;
- queued requester relaunch of `PWDATA`, `PPROT`, and `PSTRB`;
- peripheral-owned protection metadata and no interconnect-owned predicate;
- support-accounting identities and capability buckets;
- malformed storage diagnostics for wrong `reg4` address, wrong register
  count, duplicate register names, duplicate addresses, duplicate data
  signals, reset values other than `0`, mismatched peripheral registers,
  missing `access-policy`, wrong `reg4` policy, no-policy/protection mix,
  more-than-five-register, and more-than-two-peripheral variants;
- focused `t/248`, `t/297`, `t/1470`, and `t/1472` coverage under the current
  RAM-guard policy;
- README, ROADMAP_V2, mdBook, task-tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

## Deferred Boundaries

This selection does not implement or select behavior for:

- more than five registers;
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

Rollback removes this contract document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this selector.
