# IAL2 APB Data16-Protection Multi-Peripheral Multi-Register Back-To-Back Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.647`
- Date: `2026-06-28`
- Status: audited
- Scope: APB data16-protection generalization readiness after selected data16
  no-policy multi-peripheral multi-register timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.647` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.648`, public contract selection for a
bounded APB sideband-aware data16-protection multi-peripheral multi-register
back-to-back timing family.

This audit changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Readiness Findings

The implementation has the necessary selected substrates, but not the public
contract for the combined explicit family.

Already shipped inputs:

- fixed data16-protection multi-register timing is shipped through
  `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif`;
- multi-peripheral data16-protection timing is shipped through
  `ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif`;
- 32-bit no-policy multi-peripheral multi-register timing is shipped through
  `ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif`;
- data16 no-policy multi-peripheral multi-register timing is shipped through
  `ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif`.

The fixed data16-protection family uses local `reg0`/`reg1` storage:

- `reg0` at local byte address `0`, with read allow and write require
  privileged;
- `reg1` at local byte address `2`, with read/write require privileged;
- 16-bit data, `PPROT width 3`, `PSTRB width 2`, and adjacent setup.

The selected multi-peripheral data16-protection family uses a status/control
protected storage shape:

- status peripheral: `status_reg` and `status_shadow_reg` at local byte
  addresses `0` and `2`, read allow and write require privileged;
- control peripheral: `control_reg` and `control_shadow_reg` at local byte
  addresses `0` and `2`, read/write require privileged;
- status/control windows at bases `0` and `258`, size `258`, alignment `2`;
- requester `accepted/busy/status`, queue-depth `1`, overflow `reject`;
- propagation-only interconnect decode and peripheral-owned protection
  enforcement.

The current multi-peripheral timing guard already accepts the selected
data16-protection status/control shape, while fixed composition accepts the
selected data16-protection `reg0`/`reg1` shape. No explicit public
`apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back`
source exists yet.

## Selection

`.648` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.648`: select the public APB
sideband-aware data16-protection multi-peripheral multi-register
back-to-back timing contract.

The contract-selection slice must settle source naming, storage shape, policy
shape, report/residue movement, diagnostics, validation, rollback, docs, and
Knowledge Map before implementation.

## Rationale

Direct implementation is not selected in `.647` because the public contract
has an unresolved naming and shape question. The fixed data16-protection
multi-register family uses endpoint-local `reg0`/`reg1`; the selected
multi-peripheral data16-protection family uses semantic status/control
register names. The next slice must decide whether an explicit
multi-peripheral multi-register data16-protection family is:

- a new public source pair in the
  `apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back`
  family;
- a status/control protected family with a clarified multi-register contract;
- a reg0/reg1 protected family with per-peripheral policy symmetry;
- or an explicit deferral because `.634` remains the selected protected
  data16 multi-peripheral boundary.

Explicit deferral is not selected yet because the shipped substrates line up
closely and the residue still names data16-protection generalization before
generalized multi-peripheral multi-register shapes. Generalized register
counts/names/policies, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, bus matrices, scoreboards, direct
backend, verification-output, backend-language variants, AXI, AHB, and VHDL
remain broader downstream owners.

## `.648` Contract-Selection Questions

`.648` must select:

- exact `.ppif` and `.apb` source names;
- source object, source anchor, and profile-alias mirror requirements;
- whether the selected storage is status/control protected storage,
  endpoint-local `reg0`/`reg1` protected storage, or an explicit deferral;
- requester requirements: `accepted/busy/status`, 32-bit address, 16-bit
  write/read data, `PPROT width 3`, `PSTRB width 2`, queue-depth `1`, and
  overflow `reject`;
- peripheral requirements: adjacent setup, 16-bit register data, 2-byte
  register alignment, register-local privileged `PPROT[0]` enforcement, and
  zero-strobe denied/allowed behavior;
- interconnect requirements: propagation-only queued setup decode, no idle
  insertion, status/control window decode, local-address translation, selected
  response muxing, active-access-only unmapped completion, and no
  interconnect-owned protection enforcement;
- report/residue movement for aggregate `back_to_back_policy`,
  `apb_back_to_back_policy_deferred`,
  `apb_additional_back_to_back_policies_deferred`,
  `apb_additional_protection_policies_deferred`, and remaining-width residue;
- support-accounting identities and LanguageSurfaceSection/capability text;
- malformed-shape diagnostics and rollback boundary;
- focused APB/profile-alias/support/capability tests and direct
  schedule/check/semantic JSON gates;
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

## Non-Goals

`.647` and `.648` do not select or implement:

- generalized register counts beyond the selected two-register shape;
- arbitrary register names, addresses, policy matrices, or predicates;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- interconnect-owned protection policy;
- multi-requester interconnects, bus matrices, or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This audit is documentation-only. It used code/doc review plus live
schedule-report probes for the fixed data16-protection composition and the
selected multi-peripheral data16-protection composition:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif
```

Closeout validation also runs Knowledge Map generation/check, mdBook build,
memory architecture, whitespace diff, and doctrine gates.

## Rollback

Rollback removes this audit document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this audit.
