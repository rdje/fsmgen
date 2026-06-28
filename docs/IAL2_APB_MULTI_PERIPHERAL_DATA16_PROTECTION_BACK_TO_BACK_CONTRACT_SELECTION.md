# IAL2 APB Multi-Peripheral Data16 Protection Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.633`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for bounded APB sideband-aware
  multi-peripheral data16-protection back-to-back timing-policy behavior

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.633` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.634` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb`

The selected family is the timing-policy variant of the existing
`apb_composition_multi_peripheral_sideband_data16_protection` source and the
protected data16 extension of the shipped sideband-aware multi-peripheral
status back-to-back family.

No parser behavior, generator behavior, sample file, support-accounting
catalog entry, validation behavior, generated artifact, schedule/check/semantic
JSON behavior, HDL/runtime behavior, suffix acceptance, direct backend
lowering, verification-output generation, backend-language variant, APB
behavior, AXI behavior, AHB behavior, or VHDL behavior changes in this
selector slice.

## Evidence Read

This selection read:

- `.632` post-data16-protection selector;
- `.631` data16-protection fixed-composition timing behavior;
- `.630` data16-protection fixed-composition contract selection;
- `.618` sideband-aware multi-peripheral back-to-back behavior;
- `.617` sideband-aware multi-peripheral back-to-back contract selection;
- `.609` no-sideband multi-peripheral back-to-back behavior;
- `.625` data16 timing behavior;
- `.628` protection timing behavior;
- `.622/.621` sideband multi-register timing records;
- `.620` data16/protection timing readiness audit;
- current multi-peripheral sideband data16-protection samples and reports;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

Live report probes confirmed:

- `ppif/apb_composition_multi_peripheral_sideband_data16_protection.ppif` and
  its `.apb` alias are 16-bit, use `PPROT width 3` and `PSTRB width 2`, expose
  multi-peripheral `protection_policy.enforcement_owner =
  peripheral_completers`, and still have no aggregate `back_to_back_policy`;
- `ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif`
  already reports aggregate multi-peripheral `back_to_back_policy` over a
  32-bit sideband status/control topology;
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif`
  already reports aggregate fixed-composition data16-protection
  `back_to_back_policy`.

## Selected Public Sources

`.634` shall add exactly these public source pairs:

- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb`

The `.apb` profile alias must mirror the `.ppif` source and lower through the
same generated `.isf` review artifacts before generated `.fsm` artifacts.

No standalone requester, standalone completer, fixed-composition, broader
multi-peripheral, AXI, AHB, VHDL, direct-backend, or verification-output source
is selected in `.633`.

## Selected Source Contract

The selected source is intentionally narrow:

- one requester and exactly two peripheral completers;
- requester object `apb_requester`;
- peripheral objects `apb_status_regs` and `apb_control_regs`;
- generated interconnect object `apb_interconnect`;
- 32-bit APB address and address-map widths;
- 16-bit `PWDATA`, `PRDATA`, request write data, requester read-data output,
  and peripheral register data;
- requester request `req_prot width 3` and `req_wstrb width 2`;
- APB bus and every peripheral bus use `PPROT width 3` and `PSTRB width 2`;
- requester response fields include `accepted`, `busy`, `status width 2`,
  `done`, `last_read_data width 16`, and `last_error`;
- requester transfer policy is `(timing-policy (back-to-back queued)
  (queue-depth 1) (overflow reject))`;
- every peripheral completer transfer policy is `(timing-policy
  (setup-admission adjacent))`;
- each peripheral completer keeps the existing two-register data16 protected
  storage shape;
- static non-overlapping address-map/decode keeps the existing
  status/control shape with 2-byte alignment;
- the composition itself has no top-level timing-policy clause.

The selected address map is the current data16-protection multi-peripheral
shape:

- status window base default `0`, size default `258`;
- control window base default `258`, size default `258`;
- overlap policy `reject`;
- priority `source-order`;
- unmapped address policy `error`.

## Selected Peripheral Policy Contract

The selected status peripheral uses:

- `status_reg` at address `0`, data width `16`, reset `0`,
  `(read allow)`, `(write require (privileged 1))`;
- `status_shadow_reg` at address `2`, data width `16`, reset `0`,
  `(read allow)`, `(write require (privileged 1))`.

The selected control peripheral uses:

- `control_reg` at address `0`, data width `16`, reset `0`,
  `(read require (privileged 1))`,
  `(write require (privileged 1))`;
- `control_shadow_reg` at address `2`, data width `16`, reset `0`,
  `(read require (privileged 1))`,
  `(write require (privileged 1))`.

Protection enforcement remains owned by the peripheral completers. The
generated interconnect only forwards `PPROT/PSTRB/PWDATA`, decodes selected
windows, muxes selected responses, and keeps no `prot_q` or policy predicate
state.

The timing policy must preserve the `.631` data16-protection behavior at every
selected peripheral: allowed mapped reads/writes, denied reads/writes,
zero-strobe allowed writes, zero-strobe denied writes, byte-lane writes, and
unmapped accesses keep their existing semantics while adjacent setup admission
is added.

## Interconnect Timing Contract

The generated interconnect remains propagation-only:

- decode the current `PSEL/PADDR` while `PENABLE` is low;
- fan out decoded `PSEL` to the selected status or control peripheral;
- forward `PENABLE`, `PWRITE`, 16-bit `PWDATA`, `PPROT`, and 2-bit `PSTRB`;
- translate `PADDR_CONTROL` by subtracting the selected control base `258`;
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
- `composition.width_policy.data_width = 16`;
- `composition.width_policy.strobe_width = 2`;
- `composition.width_policy.protection_width = 3`;
- `composition.address_map.alignment_bytes = 2`;
- `protection_policy.enforcement_owner = peripheral_completers`;
- `protection_policy.interconnect_role =
  propagate_pprot_pstrb_and_mux_selected_response_only`;
- child protection-policy metadata for both selected peripherals.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` residue. They shall retain
narrowed residue for:

- unselected APB timing-policy families;
- broader protection-policy predicates and ownership models;
- remaining APB width families.

They shall not reintroduce `apb_protection_policy_effects_deferred` because
the selected data16-protection family already enforces register-local
privileged `PPROT[0]` policy in the peripheral completers. They shall not
reintroduce fixed-composition-only `apb_interconnect_multi_peripheral_decode_deferred`
on the selected multi-peripheral surfaces.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_sideband_data16_protection_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_sideband_data16_protection_status_back_to_back_pipeline_cli`

## Diagnostics

`.634` must keep diagnostics fail-closed. The selected widening may accept only
the exact public source family above. It must reject unsupported combinations,
including:

- missing requester `accepted/busy/status` timing response;
- requester timing policies other than queued, queue-depth 1, overflow reject;
- peripheral transfer policies other than adjacent setup admission;
- peripheral counts other than exactly two;
- partial sideband bundles;
- APB data widths other than `16`;
- `PSTRB` widths other than `2`;
- `PPROT` widths other than `3`;
- address-map shapes outside the selected status/control windows;
- protected data16 peripheral storage with wrong register names, addresses,
  widths, reset values, or access-policy clauses;
- interconnect-owned or window-level protection policy;
- broader multi-peripheral multi-register timing shapes;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers.

## Validation Target For `.634`

The implementation owner should cover:

- syntax checks for touched APB modules/tests;
- direct schedule JSON, strict check JSON, semantic JSON, generated review
  artifact, and HDL-shape probes for both selected public sources;
- report assertions for aggregate `back_to_back_policy`, 16-bit width policy,
  `PSTRB width 2`, protection owner, and narrowed residue;
- generated interconnect assertions for queued setup decode, `PPROT/PSTRB`
  fanout, control-base subtraction by `258`, active-access-only unmapped
  completion, and no protection predicate state in the interconnect;
- generated top/HDL assertions for requester `accepted`, 16-bit data, 2-bit
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

- broader multi-peripheral multi-register timing beyond the exact selected
  status/control data16-protection topology;
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
- AXI;
- AHB;
- VHDL.

## Rollback

Rollback of the future `.634` implementation removes only the two selected
public samples, selected multi-peripheral data16-protection timing-policy guard
widening, support-accounting entries, focused tests, behavior docs, Knowledge
Map fact card, README, ROADMAP_V2, mdBook, task tree, Memory, and generated
Knowledge Map updates. Existing no-sideband timing, 32-bit sideband timing,
fixed data16-protection timing, APB data16/protection behavior without
multi-peripheral timing, AXI, AHB, and VHDL behavior remain owned by earlier
or future slices.
