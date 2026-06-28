# IAL2 APB Status/Control Protected-Storage Generalization Contract Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.652`
- Date: `2026-06-28`
- Status: selected
- Scope: public contract selection for bounded APB status/control
  protected-storage generalization

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.652` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.653`, a report/static residue cleanup for
the already-shipped bounded APB status/control protected-storage
generalization.

The selected contract covers both shipped two-peripheral status/control
protected-storage width families:

- 32-bit sideband-aware protection status/control timing from `.638`;
- data16 sideband-aware data16-protection status/control timing from `.634`.

No new public `.ppif` source pair, `.apb` profile alias, support-accounting
identity, or LanguageSurfaceSection coverage bucket is selected. The existing
public sources are the public contract:

- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.apb`
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.apb`

No parser behavior, generator behavior, public sample, support-accounting
catalog, generated artifact, HDL/runtime behavior, suffix acceptance, direct
backend lowering, verification-output generation, backend-language variant,
APB transaction behavior, AXI behavior, AHB behavior, or VHDL behavior changes
in this selector slice.

## Rationale

Direct behavior is not selected because `.638` and `.634` already shipped the
bounded status/control behavior:

- requester `accepted/busy/status`;
- queue-depth `1` and overflow `reject`;
- adjacent setup on both peripheral completers;
- status/control windows at `0`/`256` for 32-bit and `0`/`258` for data16;
- propagation-only interconnect queued setup decode;
- peripheral-owned privileged `PPROT[0]` enforcement.

Adding duplicate source names or support-accounting identities would create a
second public surface for the same semantics. The real remaining issue is
report/static drift: `apb_additional_back_to_back_policies_deferred` still
mentions "status/control protected storage generalization beyond the selected
family" even though the selected bounded status/control families are now
shipped and should be treated as closed for this exact scope.

## Selected `.653` Implementation Contract

`.653` shall update only report/static documentation surfaces:

- refine `_apb_additional_back_to_back_policies_residue()` so it no longer
  names status/control protected storage generalization as live residue;
- keep the residue id `apb_additional_back_to_back_policies_deferred`;
- keep future timing residue for generalized multi-peripheral multi-register
  timing, deeper queues, alternate overflow policies, accepted-less requester
  timing, multiple active APB transfers, bus matrices, scoreboards, direct
  backend lowering, verification-output generation, backend-language variants,
  AXI, AHB, and VHDL;
- leave `apb_additional_protection_policies_deferred` as the owner for
  broader protection policy families;
- leave width residue as `apb_alternate_widths_deferred` or
  `apb_remaining_widths_deferred` according to the existing width family;
- update LanguageSurfaceSection/static prose only where it implies selected
  status/control generalization is still pending;
- update focused tests only for residue/static text expectations;
- update README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map.

`.653` must not add public sources, support-accounting identities, capability
buckets, profile aliases, parser branches, timing compatibility branches,
generated `.isf`/`.fsm` behavior, HDL behavior, direct backend behavior,
verification-output behavior, or backend-language variants.

## Selected Public Semantics

The bounded status/control protected-storage contract remains exactly:

- status peripheral registers:
  - `status_reg` at local address `0`;
  - `status_shadow_reg` at local address `4` for 32-bit and `2` for data16;
  - reads allowed;
  - writes require privileged `PPROT[0] == 1`;
- control peripheral registers:
  - `control_reg` at local address `0`;
  - `control_shadow_reg` at local address `4` for 32-bit and `2` for data16;
  - reads and writes require privileged `PPROT[0] == 1`;
- APB width families:
  - 32-bit `PWDATA/PRDATA`, `PSTRB width 4`, control window base `256`;
  - 16-bit `PWDATA/PRDATA`, `PSTRB width 2`, control window base `258`;
- `PPROT width 3`;
- address-map alignment equal to the data-byte width;
- requester `accepted/busy/status`, queue-depth `1`, overflow `reject`;
- adjacent setup on both peripheral completers;
- interconnect propagation without idle-cycle insertion;
- no interconnect-owned protection predicate.

## Deferred Boundaries

The selected cleanup does not close:

- arbitrary status/control register counts, names, addresses, reset values, or
  policy matrices;
- 32-bit protected `reg0`/`reg1` multi-peripheral behavior if separately
  selected later;
- generalized multi-peripheral multi-register timing;
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

## Validation For `.653`

`.653` must include focused validation:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -c t/1472-ial2-apb-composition.t
prove -Iperl t/1472-ial2-apb-composition.t
```

It must also run direct schedule-report probes for the existing 32-bit and
data16 status/control protected sources and the `.649` data16 protected
`reg0`/`reg1` source, then close with Knowledge Map generation/check, mdBook
build, whitespace diff, and doctrine gates.

## Rollback

Rollback removes this contract-selection document, its Knowledge Map fact
card, README, ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge
Map updates. Since this selector changes no behavior, there are no parser,
sample, support-accounting, generated-artifact, HDL/runtime, APB, AXI, AHB, or
VHDL changes to revert.
