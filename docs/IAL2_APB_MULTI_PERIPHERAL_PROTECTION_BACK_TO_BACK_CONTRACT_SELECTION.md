# IAL2 APB Multi-Peripheral Protection Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.637`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for bounded APB sideband-aware
  multi-peripheral protection back-to-back timing-policy behavior

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.637` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.638` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.apb`

The selected family is the timing-policy variant of the existing
`apb_composition_multi_peripheral_sideband_protection` source. It is also the
32-bit protected sibling of the selected `.634` multi-peripheral
data16-protection status/control timing family.

No parser behavior, generator behavior, sample file, support-accounting
catalog entry, validation behavior, generated artifact, schedule/check/semantic
JSON behavior, HDL/runtime behavior, suffix acceptance, direct backend
lowering, verification-output generation, backend-language variant, APB
behavior, AXI behavior, AHB behavior, or VHDL behavior changes in this
selector slice.

## Evidence Read

This selection read:

- `.636` readiness audit;
- `.635` post-multi-peripheral data16-protection selector;
- `.634` multi-peripheral data16-protection timing behavior;
- `.633` multi-peripheral data16-protection contract selection;
- `.628` protection timing behavior;
- `.622/.621` sideband multi-register fixed-composition timing records;
- `.618` sideband-aware multi-peripheral timing behavior;
- `.609` no-sideband multi-peripheral timing behavior;
- `ppif/apb_composition_multi_peripheral_sideband_protection.ppif`;
- `ppif/apb_composition_multi_peripheral_sideband_protection.apb`;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live report probes confirmed:

- the existing `.ppif` and `.apb` candidate pair passes strict check JSON and
  is support-accounted;
- the current candidate report already has 32-bit data/addressing,
  `PPROT width 3`, `PSTRB width 4`, two protected registers per peripheral,
  status/control windows at `0` and `256`, propagation-only interconnect
  decode, and `protection_policy.enforcement_owner =
  peripheral_completers`;
- the current candidate still has no aggregate `back_to_back_policy` and
  retains broad `apb_back_to_back_policy_deferred` residue;
- the current multi-peripheral timing guard accepts one-register
  sideband-aware multi-peripheral timing and the selected data16-protection
  status/control shape, but not the selected 32-bit protected status/control
  multi-register shape yet.

## Selected Public Sources

`.638` shall add exactly these public source pairs:

- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.apb`

The `.apb` profile alias must mirror the `.ppif` source and lower through the
same generated `.isf` review artifacts before generated `.fsm` artifacts.

No standalone requester, standalone completer, fixed-composition, data16,
broader multi-peripheral, AXI, AHB, VHDL, direct-backend, or
verification-output source is selected in `.637`.

## Selected Source Contract

The selected source is intentionally narrow:

- one requester and exactly two peripheral completers;
- requester object `apb_requester`;
- peripheral objects `apb_status_regs` and `apb_control_regs`;
- generated interconnect object `apb_interconnect`;
- 32-bit APB address, address-map, request write data, requester read data,
  `PWDATA`, `PRDATA`, and peripheral register data;
- requester request `req_prot width 3` and `req_wstrb width 4`;
- APB bus and every peripheral bus use `PPROT width 3` and `PSTRB width 4`;
- requester response fields include `accepted`, `busy`, `status width 2`,
  `done`, `last_read_data width 32`, and `last_error`;
- requester transfer policy is `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- every peripheral completer transfer policy is `(timing-policy
  (setup-admission adjacent))`;
- static non-overlapping address-map/decode keeps the existing status/control
  shape;
- the composition itself has no top-level timing-policy clause.

The selected address map is the current 32-bit protection multi-peripheral
shape:

- status window base default `0`, size default `256`;
- control window base default `256`, size default `256`;
- alignment `4`;
- overlap policy `reject`;
- priority `source-order`;
- unmapped address policy `error`.

## Selected Peripheral Policy Contract

The selected status peripheral uses:

- `status_reg` at address `0`, data width `32`, reset `0`,
  `(read allow)`, `(write require (privileged 1))`;
- `status_shadow_reg` at address `4`, data width `32`, reset `0`,
  `(read allow)`, `(write require (privileged 1))`.

The selected control peripheral uses:

- `control_reg` at address `0`, data width `32`, reset `0`,
  `(read require (privileged 1))`,
  `(write require (privileged 1))`;
- `control_shadow_reg` at address `4`, data width `32`, reset `0`,
  `(read require (privileged 1))`,
  `(write require (privileged 1))`.

Protection enforcement remains owned by the peripheral completers. The
generated interconnect only forwards `PPROT/PSTRB/PWDATA`, decodes selected
windows, muxes selected responses, and keeps no `prot_q` or policy predicate
state.

The timing policy must preserve the `.628` protected 32-bit behavior at every
selected peripheral: allowed mapped reads/writes, denied reads/writes,
zero-strobe allowed writes, zero-strobe denied writes, byte-lane writes, and
unmapped accesses keep their existing semantics while adjacent setup admission
is added.

## Interconnect Timing Contract

The generated interconnect remains propagation-only:

- decode the current `PSEL/PADDR` while `PENABLE` is low;
- fan out decoded `PSEL` to the selected status or control peripheral;
- forward `PENABLE`, `PWRITE`, 32-bit `PWDATA`, `PPROT`, and 4-bit `PSTRB`;
- translate `PADDR_CONTROL` by subtracting the selected control base `256`;
- mux selected peripheral `PREADY`, `PRDATA`, and `PSLVERR`;
- complete unmapped accesses only on active `PSEL && PENABLE` cycles;
- do not register the selected peripheral;
- do not insert an idle cycle between a completed access and the queued setup.

The outstanding model remains unchanged: at most one active APB bus transfer
and one requester-side queued next transfer.

## Report And Support Movement

Selected reports shall add aggregate `back_to_back_policy` metadata using the
existing multi-peripheral report shape, with requester, interconnect, and every
peripheral endpoint represented.

Selected reports shall preserve:

- `composition.topology = multi_peripheral_interconnect`;
- `composition.width_policy.data_width = 32`;
- `composition.width_policy.strobe_width = 4`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 4`;
- `protection_policy.enforcement_owner = peripheral_completers`;
- `protection_policy.interconnect_role =
  propagate_pprot_pstrb_and_mux_selected_response_only`;
- child protection-policy metadata for both selected peripherals.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` residue. They shall retain
narrowed residue for:

- unselected APB timing-policy families;
- broader protection-policy predicates and ownership models;
- alternate APB width families.

They shall not reintroduce `apb_protection_policy_effects_deferred` because
the selected protection family already enforces register-local privileged
`PPROT[0]` policy in the peripheral completers. They shall not reintroduce
fixed-composition-only `apb_interconnect_multi_peripheral_decode_deferred` on
the selected multi-peripheral surfaces.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_sideband_protection_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_sideband_protection_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_sideband_protection_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_sideband_protection_status_back_to_back_pipeline_cli`

## Diagnostics

`.638` must keep diagnostics fail-closed. The selected widening may accept only
the exact public source family above. It must reject unsupported combinations,
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
- protected 32-bit peripheral storage with wrong register names, addresses,
  widths, reset values, or access-policy clauses;
- interconnect-owned or window-level protection policy;
- broader multi-peripheral multi-register timing shapes;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers.

## Validation Target For `.638`

The implementation owner should cover:

- syntax checks for touched APB modules/tests;
- direct schedule JSON, strict check JSON, semantic JSON, generated review
  artifact, and HDL-shape probes for both selected public sources;
- report assertions for aggregate `back_to_back_policy`, 32-bit width policy,
  `PSTRB width 4`, protection owner, and narrowed residue;
- generated interconnect assertions for queued setup decode, `PPROT/PSTRB`
  fanout, control-base subtraction by `256`, active-access-only unmapped
  completion, and no protection predicate state in the interconnect;
- generated top/HDL assertions for requester `accepted`, 32-bit data, 4-bit
  strobe, status/control protected register behavior, and adjacent setup;
- `.apb` alias parity and support-accounting coverage;
- malformed contract diagnostics for wrong width, wrong strobe, missing
  accepted, wrong register policy, wrong peripheral count, and unsupported
  address-map shapes;
- focused APB profile-alias, composition, support-accounting, and
  capability-manifest tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

## Deferred Work

This selection does not include:

- no-policy multi-peripheral multi-register timing;
- sideband data16 no-policy multi-peripheral multi-register timing;
- data16-protection timing generalization beyond the selected `.634`
  status/control shape;
- generalized register counts, register names, and access-policy matrices;
- queue depths greater than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB transfers;
- additional `PPROT` predicates;
- global, window-level, interconnect-owned, programmable, boolean,
  multi-predicate, or non-privileged protection-policy families;
- direct backend lowering;
- verification-output generation;
- backend-language variants;
- AXI, AHB, and VHDL behavior.

## Rollback

Rollback removes this contract-selection document, its Knowledge Map fact
card, README, ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge
Map updates. No parser, generator, sample, support-accounting, validation,
generated-artifact, schedule/check/semantic JSON, HDL/runtime, suffix,
direct-backend, verification-output, backend-language, APB, AXI, AHB, or VHDL
behavior is changed by this selector.
