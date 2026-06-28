# IAL2 APB Multi-Peripheral Multi-Register Back-To-Back Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.636`
- Date: `2026-06-28`
- Status: selected
- Scope: broader APB multi-peripheral multi-register back-to-back timing
  readiness after selected multi-peripheral data16-protection timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.636` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.637`, public contract selection for the
bounded 32-bit sideband-aware protection multi-peripheral back-to-back timing
family.

This audit changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Shipped Timing Inputs

Fixed-composition APB timing now covers:

- selected 32-bit no-sideband status back-to-back timing;
- selected 32-bit sideband-aware status back-to-back timing;
- selected 32-bit sideband-aware two-register no-policy timing;
- selected 32-bit sideband-aware two-register protection timing;
- selected sideband-aware data16 timing;
- selected sideband-aware data16-protection timing.

Multi-peripheral APB timing now covers:

- selected 32-bit no-sideband two-peripheral status timing;
- selected 32-bit sideband-aware two-peripheral status timing;
- selected sideband-aware data16-protection status/control timing.

The current multi-peripheral timing guard still rejects broader
multi-register peripheral shapes except for the exact `.634` data16-protection
status/control family.

## Candidate Surface Audit

The best existing non-timing multi-peripheral multi-register candidate is:

- `ppif/apb_composition_multi_peripheral_sideband_protection.ppif`
- `ppif/apb_composition_multi_peripheral_sideband_protection.apb`

That candidate already has a shipped non-timing contract:

- one requester and exactly two peripheral completers;
- generated propagation-only `apb_interconnect`;
- 32-bit APB data and 32-bit address map;
- `PPROT width 3`;
- `PSTRB width 4`;
- status window base `0`, size `256`;
- control window base `256`, size `256`;
- two protected 32-bit registers per peripheral at byte addresses `0` and
  `4`;
- status registers read-allow/write-privileged;
- control registers read/write privileged;
- peripheral-completer-owned register-local `PPROT[0]` enforcement;
- interconnect role
  `propagate_pprot_pstrb_and_mux_selected_response_only`;
- broad `apb_back_to_back_policy_deferred` residue.

This is the most conservative next multi-register target because it combines
already shipped 32-bit sideband-protection fixed-composition timing with the
already shipped 32-bit sideband multi-peripheral interconnect propagation
contract. It avoids the alternate-width hazards of data16 while still
exercising two-register peripheral storage and register-local protection.

Other candidate families are not first:

- sideband data16 multi-peripheral currently has one register per peripheral,
  so it is not the multi-register residue owner;
- data16-protection status/control multi-peripheral timing already shipped in
  `.634`;
- adding a new 32-bit no-policy multi-register multi-peripheral source before
  using the existing protection candidate would create new source shape work
  without reducing the already-supported protection residue;
- generalized register counts, generalized register names, and arbitrary
  access-policy matrices are broader than the current selected APB pattern.

## Selection

`.637` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.637`: select the public APB sideband-aware
protection multi-peripheral back-to-back timing-policy contract before
implementation.

`.637` must settle exact `.ppif` and `.apb` source names, static topology
scope, requester/completer/interconnect timing-policy requirements,
protection timing semantics, queued setup decode, sideband propagation,
report/residue movement, support-accounting identities, diagnostics,
validation, rollback, and implementation boundary before any behavior change.

The likely source family is the status/control form derived from
`ppif/apb_composition_multi_peripheral_sideband_protection.ppif`, but `.637`
owns the final source names and exact public contract.

## Deferred Work

This audit keeps these families deferred:

- direct implementation before `.637` settles the public contract;
- no-policy multi-peripheral multi-register timing;
- sideband data16 no-policy multi-peripheral multi-register timing;
- data16-protection generalization beyond the selected `.634` status/control
  family;
- generalized register counts, register names, and access-policy matrices;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB transfers;
- new protection predicates or interconnect-owned protection policy;
- multi-requester interconnects, bus matrices, scoreboards, or backend-owned
  APB arbitration;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, and VHDL behavior.

## Validation

This audit is documentation-only. Closeout validation is:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
scripts/check_doctrines.sh
git --no-pager diff --check
```

## Rollback

Rollback removes this audit document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this audit.
