# IAL2 APB Data16 No-Policy Multi-Peripheral Multi-Register Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.644`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for bounded APB sideband-aware data16
  no-policy multi-peripheral multi-register back-to-back timing behavior

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.644` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.645` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.apb`

The selected family combines the already shipped sideband data16 no-policy
fixed multi-register timing contract with the already shipped sideband data16
multi-peripheral interconnect propagation contract, using the no-policy
reg0/reg1 peripheral storage shape selected by `.642` but with data16 widths
and 2-byte register alignment.

No parser behavior, generator behavior, public source file, support-accounting
catalog entry, validation behavior, generated artifact, schedule/check/semantic
JSON behavior, HDL/runtime behavior, suffix acceptance, direct backend
lowering, verification-output generation, backend-language variant, APB
behavior, AXI behavior, AHB behavior, or VHDL behavior changes in this
selector slice.

## Evidence Read

This selection read:

- `.643` post-32-bit no-policy multi-peripheral multi-register selector;
- `.642/.641/.640` no-policy multi-peripheral multi-register behavior,
  contract, and readiness audit;
- `.638` protected multi-peripheral behavior;
- `.634` data16-protection multi-peripheral behavior;
- `.625` data16 no-policy fixed-composition behavior;
- `.622` sideband no-policy fixed-composition behavior;
- `.618` sideband multi-peripheral one-register behavior;
- current data16 no-policy/protection multi-peripheral and fixed
  multi-register `.ppif`/`.apb` sources and reports;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

The current implementation already has the selected pieces:

- sideband data16 requester queueing and relaunch for 16-bit `PWDATA`, 3-bit
  `PPROT`, and 2-bit `PSTRB`;
- sideband data16 no-policy two-register adjacent completer storage, with
  `reg0` at byte address `0` and `reg1` at byte address `2`;
- sideband data16 multi-peripheral windows at bases `0` and `258`, size
  `258`, and alignment `2`;
- sideband data16 multi-peripheral interconnect propagation without idle-cycle
  insertion for the selected protected status/control family;
- 32-bit no-policy reg0/reg1 two-peripheral timing for the selected
  status/control topology.

The current `ApbComposition` multi-peripheral timing guard still routes the
sideband data16 family through the selected data16-protection status/control
storage predicate. That boundary means `.645` can implement directly by
widening only the data16 branch of the multi-peripheral timing compatibility
guard and the connected report/support surfaces for the selected no-policy
reg0/reg1 data16 peripheral shape.

## Selected Public Sources

`.645` shall add exactly these public source pairs:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.apb`

The selected `.apb` profile alias must mirror the `.ppif` source and lower
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-data16-status-back-to-back`.

No standalone requester, standalone completer, fixed-composition, 32-bit,
protection-policy, broader multi-peripheral, AXI, AHB, VHDL, direct-backend,
or verification-output source is selected in `.644`.

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

## Selected No-Policy Peripheral Storage

Both selected peripheral completers use the same local no-policy data16
register shape:

- `reg0` at byte address `0`, address width `32`, data width `16`, reset `0`;
- `reg1` at byte address `2`, address width `32`, data width `16`, reset `0`;
- no `access-policy` clause on either register.

The status peripheral should use unique data signal names such as
`status_reg0_data_q` and `status_reg1_data_q`. The control peripheral should
use `control_reg0_data_q` and `control_reg1_data_q`. Register names remain
local endpoint names and must stay `reg0`/`reg1`.

## Interconnect Timing Contract

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

The outstanding model remains unchanged: at most one active APB bus transfer
and one requester-side queued next transfer.

## Report And Support Movement

Selected reports shall add aggregate `back_to_back_policy` metadata using the
existing multi-peripheral report shape, with requester, interconnect, and every
peripheral endpoint represented.

Selected reports shall preserve:

- `composition.topology = multi_peripheral_interconnect`;
- `composition.width_policy.data_width = 16`;
- `composition.width_policy.strobe_width = 2`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 2`;
- `children[2].transfer.registers = [reg0, reg1]`;
- `children[3].transfer.registers = [reg0, reg1]`.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` residue. They shall retain
narrowed residue for:

- unselected APB timing-policy families;
- APB protection-policy effects, because `PPROT/PSTRB` are propagated but no
  register-local access policy is enforced in this no-policy family;
- alternate width families beyond the selected sideband-aware 16/32-bit
  boundary.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back_pipeline_cli`

## Diagnostics

`.645` must keep diagnostics fail-closed. The selected widening may accept
only the exact public no-policy data16 source family above in addition to
already shipped multi-peripheral timing families. It must reject unsupported
combinations, including:

- missing requester `accepted/busy/status` timing response;
- requester timing policies other than queued, queue-depth `1`, overflow
  `reject`;
- peripheral transfer policies other than adjacent setup admission;
- peripheral counts other than exactly two;
- partial sideband bundles;
- APB data widths other than `16` for this selected family;
- `PSTRB` widths other than `2`;
- `PPROT` widths other than `3`;
- address-map shapes outside the selected data16 status/control windows;
- no-policy peripheral storage with wrong register names, addresses, widths,
  reset values, register count, or register-local access-policy clauses;
- generalized register names/counts or mixed no-policy/protection storage;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation

`.645` closeout validation must cover:

- syntax checks for touched APB modules/tests;
- direct schedule JSON, strict check JSON, strict semantic JSON, generated
  review artifacts, and generated HDL-shape probes for the two selected public
  sources;
- negative probes for wrong register names, wrong register addresses,
  register-local access policy, missing sidebands, wrong queue depth, wrong
  overflow policy, wrong peripheral count, and non-selected window shape;
- focused APB composition, APB profile-alias, support-accounting, and
  capability-manifest tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

This `.644` selector itself is documentation-only. Closeout validation is:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
scripts/check_doctrines.sh
git --no-pager diff --check
```

## Rollback

Rollback removes this contract-selection document, its Knowledge Map fact card,
README, ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map
updates. No parser, generator, sample, support-accounting, validation,
generated-artifact, schedule/check/semantic JSON, HDL/runtime, suffix,
direct-backend, verification-output, backend-language, APB, AXI, AHB, or VHDL
behavior is changed by this selector.
