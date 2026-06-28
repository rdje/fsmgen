# IAL2 APB Status/Control Protected-Storage Residue Cleanup

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.653`
- Date: `2026-06-28`
- Status: shipped
- Scope: APB report/static residue cleanup for already-shipped
  status/control protected-storage families

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.653` implements the `.652` selected
report/static cleanup. The common
`apb_additional_back_to_back_policies_deferred` residue no longer names
status/control protected storage generalization as live future work.

The residue now explicitly records that selected status/control protected
storage is complete for the bounded 32-bit and data16 two-peripheral families.
Generalized multi-peripheral multi-register timing, deeper queues, alternate
overflow policies, accepted-less requester timing, multiple active APB
transfers, bus matrices, scoreboards, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, and VHDL
remain future work.

## Changed Surfaces

The cleanup changes only report/static text:

- `perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm` residue detail for
  `apb_additional_back_to_back_policies_deferred`;
- `perl/FSM/Support/LanguageSurfaceSection.pm` static deferred-surface prose
  that previously implied selected status/control generalization was pending;
- focused APB composition assertions that the stale status/control wording is
  absent from representative schedule reports.

No public `.ppif` or `.apb` source, support-accounting identity, capability
bucket, parser branch, timing compatibility branch, generated `.isf`/`.fsm`
behavior, HDL behavior, APB transaction behavior, direct backend behavior,
verification-output behavior, backend-language variant, AXI behavior, AHB
behavior, or VHDL behavior changes in this slice.

## Selected Public Contract After Cleanup

The already-shipped bounded status/control protected-storage families remain:

- `ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif`
  and `.apb` for the 32-bit two-peripheral status/control protected family;
- `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`
  and `.apb` for the data16 two-peripheral status/control protected family.

The `.649` selected data16 protected `reg0`/`reg1` multi-register family is
unchanged and continues to share the same narrowed timing residue id.

## Validation

Syntax checks passed:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm
perl -Iperl -c perl/FSM/Support/LanguageSurfaceSection.pm
perl -c t/1472-ial2-apb-composition.t
```

Direct schedule-report probes passed for:

```bash
ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif
ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif
ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif
```

The probes verified that the residue no longer contains
`status/control protected storage generalization` and does contain the selected
status/control completion wording.

A RAM-guarded focused `prove -Iperl t/1472-ial2-apb-composition.t` attempt
stopped before executing tests because host memory was already `98.2%` against
the default `88%` cutoff. The cutoff was not bypassed.

Closeout also runs Knowledge Map generation/check, mdBook build, whitespace
diff, and doctrine gates.

## Next Owner

`.653` selects `.654`, readiness audit for generalized APB multi-peripheral
multi-register timing after the status/control residue wording is retired.

## Rollback

Rollback restores the previous residue/static text in `ApbComposition`,
`LanguageSurfaceSection`, and the focused assertions, then removes this
behavior record, its Knowledge Map fact card, README, ROADMAP_V2, mdBook,
task-tree, Memory, and generated Knowledge Map updates. There are no public
source, support-accounting, generated-artifact, HDL/runtime, APB transaction,
AXI, AHB, or VHDL behavior changes to revert.
