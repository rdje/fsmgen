# IAL2 APB Data16 Generalized Multi-Peripheral Multi-Register Cardinality Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.674`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for the bounded APB sideband-aware
  data16 no-policy five-register generalized register-set cardinality widening

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.674` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.675` to directly implement exactly these
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back.apb`

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-generalized-five-register-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-data16-generalized-five-register-status-back-to-back`.

This selector changes no parser behavior, generator behavior, public source
file, support-accounting catalog entry, validation behavior, generated
artifact, schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB transaction behavior, AXI behavior, AHB
behavior, or VHDL behavior.

## Evidence Read

This selection read the `.673` next-slice selector, `.672` 32-bit no-policy
five-register behavior, `.671` 32-bit no-policy five-register contract,
`.670` cardinality readiness audit, `.668` data16 protected generalized
behavior, `.665` 32-bit protected generalized behavior, `.662` data16
no-policy generalized behavior, `.660` 32-bit no-policy generalized behavior,
current `ApbCompleter` and `ApbComposition` data16 generalized cardinality
predicates and residue, `RegressionCorpus`, `LanguageSurfaceSection`,
focused APB/profile-alias/support/capability tests, README, ROADMAP_V2,
mdBook, Memory, Knowledge Map, and relevant decisions.

The selected cardinality widening stays on the data16 no-policy path because
that path isolates 2-byte stride and 2-bit `PSTRB` behavior from protection
policy side effects.

## Selected Public Source Contract

The `.675` implementation shall keep the existing selected data16
sideband-aware no-policy generalized timing contract and widen only its
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

## Selected Generalized Register Set

The admitted data16 no-policy generalized family after `.675` shall be:

- register count is `2`, `3`, `4`, or `5`;
- register names are exactly `reg0`, `reg1`, ..., `regN` in source order;
- register local byte addresses are exactly `0`, `2`, ..., `2*N`;
- every register address width is `32`;
- every register data width is `16`;
- every reset value is `0`;
- no register has an `access-policy` clause;
- both peripheral completers have the same register count, names, local byte
  addresses, address widths, data widths, resets, and absence of
  access-policy clauses;
- register data signal names remain unique within each peripheral and may use
  peripheral-specific prefixes such as `status_reg4_data_q` and
  `control_reg4_data_q`.

The public representative selected for `.675` shall use five registers per
peripheral:

- `reg0` at local byte address `0`;
- `reg1` at local byte address `2`;
- `reg2` at local byte address `4`;
- `reg3` at local byte address `6`;
- `reg4` at local byte address `8`.

Implementation may widen the current shared data16 no-policy helper bound for
the selected sideband-aware no-policy generalized two-peripheral family from
`maximum_count = 4` to `maximum_count = 5`. It must keep more than five
registers fail-closed until a future task-tree owner selects that boundary.

## Interconnect And Timing Contract

The generated interconnect behavior remains unchanged from the selected
data16 generalized no-policy family:

- decode the current `PSEL/PADDR` while `PENABLE` is low;
- fan out decoded `PSEL` to the selected status or control peripheral;
- forward `PENABLE`, `PWRITE`, 16-bit `PWDATA`, `PPROT`, and 2-bit `PSTRB`;
- translate `PADDR_CONTROL` by subtracting control base `258`;
- mux selected peripheral `PREADY`, `PRDATA`, and `PSLVERR`;
- complete unmapped accesses only on active `PSEL && PENABLE` cycles;
- do not register the selected peripheral;
- do not insert an idle cycle between a completed access and queued setup;
- do not enforce any protection policy.

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
  public representative source.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad cardinality residue for the selected data16 no-policy
five-register family. They shall retain narrowed residue for:

- protected five-register generalized register sets;
- more than five registers;
- more than two peripheral completers;
- unselected APB timing-policy families;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers;
- bus matrices and scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back_pipeline_cli`

## Diagnostics

`.675` must keep diagnostics fail-closed. The selected widening may accept
only the bounded data16 sideband-aware no-policy generalized register-set
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
- selected data16 no-policy generalized storage with fewer than two or more
  than five registers;
- register names not following source-ordered `reg0..regN`;
- local byte addresses not following `0, 2, ..., 2*N`;
- mismatched register sets between the two peripheral completers;
- duplicate register names, addresses, or data signals;
- register reset values other than `0`;
- any register-local `access-policy` clause;
- protected five-register generalized register sets;
- more-than-two-peripheral generalized register sets;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation For The Implementation Owner

`.675` closeout validation must cover:

- syntax checks for touched modules and tests;
- byte-for-byte mirror between the selected `.ppif` source and `.apb` alias;
- direct strict check JSON for both public sources;
- semantic JSON and schedule JSON for the selected `.ppif` source;
- outdir generation for the selected `.ppif` source;
- generated artifact probes for `reg3` and `reg4` storage, read hits, write
  hits, byte-lane writes, and read-data drives;
- status/control windows at `0` and `258`;
- both peripheral completers carrying `reg0/reg1/reg2/reg3/reg4` at local
  addresses `0/2/4/6/8`;
- 16-bit `PWDATA/PRDATA`, `PPROT width 3`, and `PSTRB width 2`;
- queued requester relaunch of `PWDATA`, `PPROT`, and `PSTRB`;
- no interconnect-owned protection predicate;
- support-accounting identities and capability buckets;
- malformed storage diagnostics for wrong `reg4` address, wrong register
  count, duplicate register names, duplicate addresses, duplicate data
  signals, reset values other than `0`, mismatched peripheral registers,
  register-local `access-policy`, protected five-register,
  more-than-five-register, and more-than-two-peripheral variants;
- focused `t/248`, `t/297`, `t/1470`, and `t/1472` coverage under the current
  RAM-guard policy;
- README, ROADMAP_V2, mdBook, task-tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

## Deferred Boundaries

This selection does not implement or select behavior for:

- protected five-register generalized register sets;
- more than five registers;
- more than two peripheral completers;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- alternate protection-policy matrices;
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
