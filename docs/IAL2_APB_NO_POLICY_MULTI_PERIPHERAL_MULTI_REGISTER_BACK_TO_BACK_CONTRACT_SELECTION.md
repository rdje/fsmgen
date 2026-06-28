# IAL2 APB No-Policy Multi-Peripheral Multi-Register Back-To-Back Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.641`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection only for bounded 32-bit sideband-aware
  no-policy multi-peripheral multi-register back-to-back timing-policy behavior

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.641` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.642` to directly implement exactly two
public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.apb`

The selected family combines the already shipped 32-bit sideband-aware
multi-peripheral no-policy timing contract with the already shipped 32-bit
sideband-aware no-policy two-register endpoint timing contract.

No parser behavior, generator behavior, public source file, support-accounting
catalog entry, validation behavior, generated artifact, schedule/check/semantic
JSON behavior, HDL/runtime behavior, suffix acceptance, direct backend
lowering, verification-output generation, backend-language variant, APB
behavior, AXI behavior, AHB behavior, or VHDL behavior changes in this
selector slice.

## Evidence Read

This selection read:

- `.640` no-policy multi-peripheral multi-register readiness audit;
- `.639` post-protected-multi-peripheral selector;
- `.638/.637/.636` protected multi-peripheral timing records;
- `.622/.621` sideband no-policy multi-register fixed-composition records;
- `.625` sideband data16 no-policy fixed-composition timing behavior;
- `.618` sideband-aware multi-peripheral one-register behavior;
- `.609` no-sideband multi-peripheral behavior;
- current fixed no-policy multi-register and multi-peripheral no-policy
  `.ppif`/`.apb` sources and reports;
- ApbRequesterTransfer, ApbCompleter, ApbComposition, RegressionCorpus,
  LanguageSurfaceSection, focused APB/profile-alias/support tests, README,
  ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and relevant
  decisions.

The current implementation already has a selected sideband-aware 32-bit
no-policy two-register endpoint shape: `reg0` at byte address `0`, `reg1` at
byte address `4`, 32-bit register data, reset `0`, and no register-local
`access-policy` clauses.

An in-memory candidate using the selected source name, the selected
multi-peripheral status/control window shape, and two no-policy `reg0`/`reg1`
registers per peripheral still fails closed at the current multi-peripheral
timing guard:

```text
APB multi-peripheral selected back-to-back timing-policy supports only one-register peripheral completer storage or the selected two-peripheral sideband protection status/control storage shape in this slice
```

That boundary means `.642` can implement directly by widening only the
composition-level multi-peripheral timing compatibility guard and the connected
report/support surfaces for the selected 32-bit no-policy two-register
peripheral shape.

## Selected Public Sources

`.642` shall add exactly these public source pairs:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.apb`

The selected `.apb` profile alias must mirror the `.ppif` source and lower
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-status-back-to-back`.

No standalone requester, standalone completer, fixed-composition, data16,
protection-policy, broader multi-peripheral, AXI, AHB, VHDL, direct-backend,
or verification-output source is selected in `.641`.

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
  window shape;
- the composition itself has no top-level timing-policy clause.

The selected address map is the current 32-bit sideband-aware multi-peripheral
shape:

- status window base default `0`, size default `256`;
- control window base default `256`, size default `256`;
- alignment `4`;
- overlap policy `reject`;
- priority `source-order`;
- unmapped address policy `error`.

## Selected No-Policy Peripheral Storage

Both selected peripheral completers use the same local no-policy register
shape:

- `reg0` at byte address `0`, address width `32`, data width `32`, reset `0`;
- `reg1` at byte address `4`, address width `32`, data width `32`, reset `0`;
- no `access-policy` clause on either register.

The public source should use unique data signal names per peripheral, such as
`status_reg0_data_q`, `status_reg1_data_q`, `control_reg0_data_q`, and
`control_reg1_data_q`. Register names remain local endpoint names and must stay
`reg0`/`reg1` so they match the already selected no-policy multi-register
timing shape.

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
- `composition.address_map.alignment_bytes = 4`.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` residue. They shall retain
narrowed residue for:

- unselected APB timing-policy families;
- APB protection-policy effects, because `PPROT/PSTRB` are propagated but no
  register-local access policy is enforced in this no-policy family;
- alternate APB width families.

They shall not reintroduce fixed-composition-only
`apb_interconnect_multi_peripheral_decode_deferred` on the selected
multi-peripheral surfaces.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_status_back_to_back_pipeline_cli`

## Diagnostics

`.642` must keep diagnostics fail-closed. The selected widening may accept only
the exact public no-policy source family above in addition to already shipped
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
- no-policy peripheral storage with wrong register names, addresses, widths,
  reset values, register count, or register-local access-policy clauses;
- data16 no-policy multi-peripheral multi-register storage;
- broader protected or policy-bearing no-policy-like storage shapes;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requesters;
- multiple active APB transfers;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Validation

`.642` closeout validation must cover:

- syntax checks for touched APB modules/tests;
- direct schedule JSON, strict check JSON, strict semantic JSON, generated
  review artifacts, and generated HDL-shape probes for the two selected public
  sources;
- negative probes for wrong register names, wrong register addresses,
  register-local access policy, data16 no-policy storage, missing sidebands,
  wrong queue depth, wrong overflow policy, and wrong peripheral count;
- focused APB composition, APB profile-alias, support-accounting, and
  capability-manifest tests;
- README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, docs path,
  diff, and doctrine gates.

This `.641` selector itself is documentation-only. Closeout validation is:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
scripts/check_doctrines.sh
git --no-pager diff --check
```

## Deferred Work

This selection does not include sideband data16 no-policy multi-peripheral
multi-register timing, data16-protection generalization beyond the selected
status/control family, generalized register names, generalized register
counts, generalized address widths, generalized wait-count widths, queue depths
greater than `1`, overflow policies other than `reject`, accepted-less
requester surfaces, multiple active APB bus transfers, bus matrices,
scoreboards, direct backend lowering, verification-output generation,
backend-language variants, AXI behavior, AHB behavior, or VHDL behavior.

## Rollback

Rollback of the future `.642` implementation removes only the two selected
public samples, the selected multi-peripheral no-policy two-register timing
guard widening, support-accounting entries, focused tests, behavior docs,
Knowledge Map fact card, README, ROADMAP_V2, mdBook, task tree, Memory, and
generated Knowledge Map updates. Existing one-register multi-peripheral
timing, protected multi-peripheral timing, fixed-composition multi-register
timing, data16/protection behavior, AXI, AHB, and VHDL remain owned by earlier
or future slices.
