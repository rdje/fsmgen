# IAL2 APB Generalized Multi-Peripheral Multi-Register Six-Register Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.684`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for the bounded APB sideband-aware
  32-bit no-policy six-register generalized register-set cardinality widening

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.684` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.685` to directly implement exactly these
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.apb`

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-generalized-six-register-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-generalized-six-register-status-back-to-back`.

This selector changes no parser behavior, generator behavior, public source
file, support-accounting catalog entry, validation behavior, generated
artifact, schedule/check/semantic JSON behavior, HDL/runtime behavior, suffix
acceptance, direct backend lowering, verification-output generation,
backend-language variant, APB transaction behavior, AXI behavior, AHB
behavior, or VHDL behavior.

## Evidence Read

This selection read the `.683` broader-cardinality audit, `.682` selector,
`.681` data16 protected five-register behavior, `.678` 32-bit protected
five-register behavior, `.675` data16 no-policy five-register behavior,
`.672` 32-bit no-policy five-register behavior, current `ApbCompleter` and
`ApbComposition` 32-bit no-policy generalized guards and residue,
`RegressionCorpus`, `LanguageSurfaceSection`, focused
APB/profile-alias/support/capability tests, README, ROADMAP_V2, mdBook,
Memory, Knowledge Map, and relevant decisions.

The selected first post-five-register widening stays on the 32-bit no-policy
path because that path isolates register count from data16 stride/strobe
changes and protection-policy matrix changes.

## Selected Public Source Contract

The `.685` implementation shall keep the existing selected 32-bit
sideband-aware no-policy generalized timing contract and widen only its
cardinality boundary from a maximum of five registers to a maximum of six
registers.

The selected source remains intentionally narrow:

- one requester object named `apb_requester`;
- exactly two peripheral completer objects named `apb_status_regs` and
  `apb_control_regs`;
- one generated interconnect object named `apb_interconnect`;
- one generated top object named `apb_tb`;
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
- the composition itself has no top-level timing-policy clause;
- the interconnect remains propagation-only and owns no protection predicate.

The selected address map remains the 32-bit status/control shape:

- status window base `0`, size `256`;
- control window base `256`, size `256`;
- alignment `4`;
- overlap policy `reject`;
- priority `source-order`;
- unmapped address policy `error`.

## Selected Generalized Register Set

The admitted 32-bit no-policy generalized family after `.685` shall be:

- register count is `2`, `3`, `4`, `5`, or `6`;
- register names are exactly `reg0`, `reg1`, ..., `regN` in source order;
- register local byte addresses are exactly `0`, `4`, ..., `4*N`;
- every register address width is `32`;
- every register data width is `32`;
- every reset value is `0`;
- no register has an `access-policy` clause;
- both peripheral completers have the same register count, names, local byte
  addresses, address widths, data widths, resets, and absence of
  `access-policy` clauses;
- register data signal names remain unique within each peripheral and may use
  peripheral-specific prefixes such as `status_reg5_data_q` and
  `control_reg5_data_q`.

The public representative selected for `.685` shall use six registers per
peripheral:

- `reg0` at local byte address `0`;
- `reg1` at local byte address `4`;
- `reg2` at local byte address `8`;
- `reg3` at local byte address `12`;
- `reg4` at local byte address `16`;
- `reg5` at local byte address `20`.

Implementation may widen the current shared helper bound for the selected
32-bit sideband-aware no-policy generalized two-peripheral family from
`maximum_count = 5` to `maximum_count = 6`. It must keep more than six
registers fail-closed until a future task-tree owner selects that boundary.

## Interconnect And Timing Contract

The generated interconnect behavior remains unchanged from the selected
generalized no-policy family:

- decode the current `PSEL/PADDR` while `PENABLE` is low;
- fan out decoded `PSEL` to the selected status or control peripheral;
- forward `PENABLE`, `PWRITE`, 32-bit `PWDATA`, `PPROT`, and 4-bit `PSTRB`;
- translate `PADDR_CONTROL` by subtracting control base `256`;
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
- `composition.width_policy.data_width = 32`;
- `composition.width_policy.strobe_width = 4`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 4`;
- `children[2].transfer.registers = [reg0, reg1, reg2, reg3, reg4, reg5]`
  for the public representative source;
- `children[3].transfer.registers = [reg0, reg1, reg2, reg3, reg4, reg5]`
  for the public representative source.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad cardinality residue for the selected 32-bit no-policy
six-register family. They shall retain narrowed residue for:

- data16 six-register generalized register sets;
- protected six-register generalized register sets;
- more than six registers;
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

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back_pipeline_cli`

## Diagnostics

`.685` must keep diagnostics fail-closed. The selected widening may accept
only the bounded 32-bit sideband-aware no-policy generalized register-set
family, in addition to already shipped exact APB timing families. It must
reject unsupported combinations, including:

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
- selected 32-bit no-policy generalized storage with fewer than two or more
  than six registers;
- register names not following source-ordered `reg0..regN`;
- local byte addresses not following `0, 4, ..., 4*N`;
- mismatched register sets between the two peripheral completers;
- duplicate register names, addresses, or data signals;
- register reset values other than `0`;
- any register-local `access-policy` clause;
- data16 six-register generalized register sets;
- protected six-register generalized register sets;
- more-than-two-peripheral generalized register sets;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation For The Implementation Owner

`.685` closeout validation must cover:

- syntax checks for touched modules and tests;
- byte-for-byte mirror between the selected `.ppif` source and `.apb` alias;
- direct strict check JSON for both public sources;
- semantic JSON and schedule JSON for the selected `.ppif` source;
- outdir generation for the selected `.ppif` source;
- generated artifact probes for `reg3`, `reg4`, and `reg5` storage, read
  hits, write hits, byte-lane writes, and read-data drives;
- status/control windows at `0` and `256`;
- both peripheral completers carrying `reg0/reg1/reg2/reg3/reg4/reg5` at
  local addresses `0/4/8/12/16/20`;
- 32-bit `PWDATA/PRDATA`, `PPROT width 3`, and `PSTRB width 4`;
- queued requester relaunch of `PWDATA`, `PPROT`, and `PSTRB`;
- no interconnect-owned protection predicate;
- support-accounting identities and capability buckets;
- malformed storage diagnostics for wrong `reg5` address, wrong register
  count, duplicate register names, duplicate addresses, duplicate data
  signals, reset values other than `0`, mismatched peripheral registers,
  register-local `access-policy`, data16 six-register, protected
  six-register, more-than-six-register, and more-than-two-peripheral
  variants;
- focused `t/248`, `t/297`, `t/1470`, and `t/1472` coverage under the current
  RAM-guard policy;
- README, ROADMAP_V2, mdBook, task-tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

## Deferred Boundaries

This selection does not implement or select behavior for:

- data16 six-register generalized register sets;
- protected six-register generalized register sets;
- more than six registers;
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
Because this selector changes no implementation, no parser/generator/source
rollback is required here. The `.685` implementation rollback, once executed,
must remove the two public source files, restore the selected 32-bit
no-policy generalized cardinality bound to five registers, remove the new
support-accounting identities and capability entries, remove focused tests,
regenerate the Knowledge Map, and return the active frontier to an owner that
re-selects any future six-register or broader cardinality behavior before
implementation.
