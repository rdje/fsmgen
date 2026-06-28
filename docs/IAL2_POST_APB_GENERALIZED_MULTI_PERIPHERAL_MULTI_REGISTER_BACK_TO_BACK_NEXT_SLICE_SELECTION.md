# IAL2 Post APB Generalized Multi-Peripheral Multi-Register Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.661`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB timing/register-set residue owner after selected 32-bit
  no-policy generalized register-set timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.661` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.662`, direct implementation of the bounded
APB sideband-aware data16 no-policy generalized `reg0..regN` register-set
multi-peripheral back-to-back timing family.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Current State

`.660` shipped the first bounded generalized APB register-set timing family:
32-bit sideband-aware APB, no register-local access policies, one requester,
exactly two peripheral completers, matching source-ordered `reg0..regN`
register sets, two to four registers per peripheral, 4-byte local stride,
status/control windows at bases `0` and `256`, depth-1 queued requester
timing, adjacent setup on every peripheral, overflow `reject`, and
propagation-only interconnect decode.

The already shipped data16 no-policy multi-peripheral multi-register family
is still exact: `reg0` at local byte address `0` and `reg1` at local byte
address `2`, 16-bit APB/register data, `PPROT width 3`, `PSTRB width 2`, and
status/control windows at bases `0` and `258` with size `258`.

The live `ApbCompleter` and `ApbComposition` code already has a parameterized
no-policy generalized register-set predicate, but the selected data16 timing
branch still admits only the exact data16 `reg0`/`reg1` no-policy and
protection shapes. Protected generalized register sets remain a larger policy
decision because the project has not selected how `reg0..regN` access-policy
matrices map beyond the already shipped exact `reg0`/`reg1` and
status/control protected families.

## Selection

`.662` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.662`: implement the bounded APB
sideband-aware data16 no-policy generalized register-set multi-peripheral
back-to-back timing behavior.

The selected implementation shall add exactly these public sources:

- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.apb`

The selected `.apb` profile alias must mirror the `.ppif` source and lower
through the same generated `.isf` review artifacts before generated `.fsm`
artifacts.

The selected `protocol-platform-intent` name is
`apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back`.
The selected source object is
`fsmgen-apb-composition-multi-peripheral-multi-register-sideband-data16-generalized-status-back-to-back`.
The selected source anchor section is
`requester-multi-peripheral-composition-multi-register-sideband-data16-generalized-status-back-to-back`.

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

## Selected Generalized Register Set

Both selected peripheral completers use the same local no-policy data16
register-set shape:

- register count is `2`, `3`, or `4`;
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
  peripheral-specific prefixes such as `status_reg2_data_q` and
  `control_reg2_data_q`.

The public source selected in `.662` shall use:

- `reg0` at local address `0`;
- `reg1` at local address `2`;
- `reg2` at local address `4`.

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
  representative source.

Selected top, requester, interconnect, and peripheral report surfaces shall
remove broad `apb_back_to_back_policy_deferred` residue for this selected
family. They shall retain narrowed residue for:

- unselected APB timing-policy families;
- protected generalized register sets and unselected protection policy
  matrices;
- broader APB register-set cardinalities beyond four registers;
- more-than-two-peripheral generalized register sets;
- direct backend, verification-output, backend-language variants, AXI, AHB,
  and VHDL.

Selected support-accounting identities:

- `intent.ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back`
- `intent.apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back`

Selected coverage buckets:

- `ial2_ppif_apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_pipeline_cli`
- `ial2_apb_profile_alias_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back_pipeline_cli`

## Rationale

Data16 no-policy generalization is the smallest coherent APB
timing/register-set residue after `.660`.

It extends the same no-policy `reg0..regN` rule that `.660` shipped, with only
the already selected data16 width, strobe, stride, and window values from
`.644/.645`. That avoids choosing a new access-control policy matrix in the
same slice.

Protected generalized register sets are deliberately deferred because the
current protected surface has multiple exact policy families: `reg0`/`reg1`
privileged access and status/control protected storage. Generalizing those
requires an explicit public policy matrix for `reg2..regN` before any timing
guard widening. Broader cardinality, more than two peripherals, deeper queues,
alternate overflow, accepted-less requester timing, multiple active APB bus
transfers, bus matrices, scoreboards, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, and VHDL
are also broader than this selected data16 no-policy implementation.

## Validation

`.662` should use focused validation comparable to `.660`:

- syntax checks for touched APB generator/support/test files;
- strict check JSON for the selected `.ppif` and `.apb` sources;
- generated outdir inspection proving `reg2` data16 storage/read/write
  artifacts;
- focused APB profile-alias, APB composition, support-accounting, and
  capability-manifest tests, RAM-guarded where required;
- Knowledge Map generation/check, mdBook build, memory architecture, diff
  check, and `scripts/check_doctrines.sh`.

This selector closeout runs only documentation/continuity gates because it
does not change behavior.

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this selector.
