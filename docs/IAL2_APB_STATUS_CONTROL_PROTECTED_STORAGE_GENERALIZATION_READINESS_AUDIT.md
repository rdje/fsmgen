# IAL2 APB Status/Control Protected-Storage Generalization Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.651`
- Date: `2026-06-28`
- Status: audited
- Scope: APB status/control protected-storage generalization readiness after
  selected data16-protection multi-peripheral multi-register timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.651` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.652`, public contract selection for a
bounded APB status/control protected-storage generalization.

This audit changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Evidence Read

This audit read:

- `.650` post-data16-protection multi-peripheral multi-register selector;
- `.649` data16-protection `reg0`/`reg1` multi-peripheral multi-register
  behavior;
- `.648` data16-protection multi-peripheral multi-register contract;
- `.647` data16-protection readiness audit;
- `.645` data16 no-policy multi-peripheral multi-register behavior;
- `.642` 32-bit no-policy multi-peripheral multi-register behavior;
- `.638` protected status/control multi-peripheral behavior;
- `.634` data16-protection status/control multi-peripheral behavior;
- `.631` data16-protection fixed-composition behavior;
- current `ApbComposition` timing guards and residue text;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused APB tests, README,
  ROADMAP_V2, mdBook, Memory, Knowledge Map, and relevant decisions.

Live schedule-report probes over the shipped status/control and `.649`
sources confirmed:

- 32-bit status/control protected timing reports `data_width = 32`,
  `strobe_width = 4`, control base `256`, peripheral-completer-owned
  protection, queued interconnect propagation, and narrowed timing/protection
  residue;
- data16 status/control protected timing reports `data_width = 16`,
  `strobe_width = 2`, control base `258`, peripheral-completer-owned
  protection, queued interconnect propagation, and narrowed timing/protection
  residue;
- data16 protected `reg0`/`reg1` timing reports the same data16 width,
  protection owner, queued interconnect role, and narrowed residue family.

## Readiness Findings

The implementation has enough selected substrate for a bounded
status/control protected-storage contract, but the contract itself is not yet
explicit.

Already shipped:

- `.638` accepts the selected 32-bit two-peripheral status/control protected
  storage shape: `status_reg/status_shadow_reg` at local addresses `0` and
  `4`, and `control_reg/control_shadow_reg` at local addresses `0` and `4`;
- `.634` accepts the selected data16 two-peripheral status/control protected
  storage shape: the same status/control register names at local addresses
  `0` and `2`;
- both shipped status/control families use requester `accepted/busy/status`,
  queue-depth `1`, overflow `reject`, adjacent setup on both peripheral
  completers, static status/control windows, propagation-only interconnect
  decode, and peripheral-owned privileged `PPROT[0]` enforcement;
- `.649` separately ships the selected data16 protected `reg0`/`reg1`
  multi-peripheral multi-register timing family.

Current `ApbComposition` compatibility remains intentionally exact. The
multi-peripheral timing guard accepts the selected sideband 32-bit no-policy
`reg0`/`reg1` shape, selected 32-bit status/control protected shape, selected
data16 no-policy `reg0`/`reg1` shape, selected data16 protected `reg0`/`reg1`
shape, and selected data16 status/control protected shape. The residue still
names status/control protected storage generalization beyond the selected
family before generalized multi-peripheral multi-register timing.

Direct behavior is therefore not selected in this audit. The next slice must
first decide whether the generalization is:

- a new public source contract that names both selected status/control width
  families explicitly;
- a report/static cleanup that recognizes the already-shipped selected
  status/control families and moves residue without adding source behavior;
- an alias/support-accounting expansion over existing `.638` and `.634`
  sources;
- or an explicit deferral because generalized register shapes should own the
  next behavior-bearing step.

## Selection

`.652` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.652`: select the bounded APB
status/control protected-storage generalization public contract.

The contract-selection slice must settle exact source/report scope, width
families, naming, support accounting, diagnostics, residue movement,
validation, rollback, docs, and Knowledge Map before any behavior change.

## `.652` Contract-Selection Questions

`.652` must select:

- whether the contract covers 32-bit status/control, data16 status/control,
  or both selected width families;
- whether to add new public `.ppif`/`.apb` source pairs, profile-alias
  mirrors, support-accounting identities, and LanguageSurfaceSection text;
- whether the implementation is behavior-bearing, report/static cleanup only,
  or an explicit deferral;
- exact register names and policy matrix:
  `status_reg/status_shadow_reg` read allow and write require privileged
  `PPROT[0]`, and `control_reg/control_shadow_reg` read/write require
  privileged `PPROT[0]`;
- exact address/window requirements: 32-bit local addresses `0`/`4` and
  windows `0`/`256`, data16 local addresses `0`/`2` and windows `0`/`258`;
- requester/interconnect timing requirements: `accepted/busy/status`,
  queue-depth `1`, overflow `reject`, adjacent setup, no idle-cycle
  insertion, selected-response muxing, active-access-only unmapped handling,
  and no interconnect-owned protection predicate;
- report/residue movement for `back_to_back_policy`,
  `apb_additional_back_to_back_policies_deferred`,
  `apb_additional_protection_policies_deferred`, alternate/remaining widths,
  and any stale status/control protected-storage wording;
- malformed-source diagnostics if new sources are selected;
- focused APB/profile-alias/support/capability tests and direct
  schedule/check/semantic JSON gates;
- README, ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map updates.

## Non-Goals

`.651` and `.652` do not select or implement:

- arbitrary register counts, names, addresses, or policy matrices;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- interconnect-owned protection policy;
- bus matrices or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This audit is documentation-only. It used code/doc review plus live
schedule-report probes:

```bash
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif
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
