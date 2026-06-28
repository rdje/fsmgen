# IAL2 Post APB Multi-Peripheral Data16 Protection Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.635`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB back-to-back timing residue owner after selected
  multi-peripheral data16-protection timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.635` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.636`, a readiness audit for broader APB
multi-peripheral multi-register back-to-back timing propagation.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Current State

The APB back-to-back timing frontier now has these selected behaviors shipped:

- fixed 32-bit no-sideband requester/completer/composition timing;
- selected 32-bit sideband requester/completer/fixed-composition timing;
- selected 32-bit sideband multi-register fixed-composition timing;
- selected 32-bit sideband protection multi-register fixed-composition timing;
- selected sideband data16 requester/completer/fixed-composition timing;
- selected sideband data16-protection fixed-composition timing;
- selected no-sideband two-peripheral multi-peripheral timing;
- selected 32-bit sideband two-peripheral multi-peripheral timing;
- selected sideband data16-protection status/control two-peripheral timing.

The remaining APB timing residue is now concentrated in:

- broader multi-peripheral multi-register timing propagation;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB transfers;
- broader protection-policy families;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Selection

`.636` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.636`: audit broader APB multi-peripheral
multi-register back-to-back timing readiness.

The audit must decide whether the next behavior slice can implement one exact
multi-peripheral multi-register family directly or whether a prerequisite is
needed first. It must compare shipped fixed multi-register timing families
against shipped multi-peripheral timing families and settle the public source
shape, endpoint storage shape, interconnect propagation requirements,
diagnostics, support accounting, validation, rollback, and documentation
boundary before any behavior change.

## Rationale

Broader multi-peripheral multi-register propagation is the next best residue
owner because it is the first explicit remaining composition timing item in
the narrowed APB `apb_additional_back_to_back_policies_deferred` reports. It
can likely reuse the existing depth-1 queued requester model, adjacent
completer setup admission, static address-map decode, selected response mux,
and active-access-only unmapped completion contracts.

The deeper queue, alternate overflow, accepted-less, and multiple-active
families are intentionally not next. They require new requester-admission or
APB outstanding-model contracts before composition propagation can be judged
safe. Broader protection-policy ownership and direct backend or
verification-output work are also downstream of the selected APB behavior
surface.

## Audit Boundary For `.636`

`.636` must read:

- `.634` multi-peripheral data16-protection behavior;
- `.633` data16-protection multi-peripheral contract;
- `.618` sideband multi-peripheral behavior;
- `.609` no-sideband multi-peripheral behavior;
- `.631`, `.628`, `.625`, and `.622` fixed-composition timing behavior;
- current `ApbRequesterTransfer`, `ApbCompleter`, and `ApbComposition`
  back-to-back timing guards and residue;
- current multi-peripheral and fixed multi-register APB `.ppif`/`.apb`
  samples and reports;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused APB/profile-alias
  tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
  relevant decisions.

The audit must not implement behavior. Its output is a precise next leaf:
direct implementation of one exact public-source family, another prerequisite
selector/audit, or explicit deferral with rationale.

## Non-Goals

`.635` and `.636` do not select or implement:

- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- new protection predicates or interconnect-owned protection policy;
- multi-requester interconnects, bus matrices, scoreboards, or backend-owned
  APB arbitration;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This selector is documentation-only. Closeout validation is:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_memory_architecture.sh
scripts/check_doctrines.sh
git --no-pager diff --check
```

## Rollback

Rollback removes this selector document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, sample, support-accounting, schedule/check/semantic
JSON, generated-artifact, HDL/runtime, suffix, direct-backend,
verification-output, backend-language, APB, AXI, AHB, or VHDL behavior is
changed by this selector.
