# IAL2 Post APB Multi-Peripheral Protection Back-To-Back Next Slice Selection

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.639`
- Date: `2026-06-28`
- Status: selected
- Scope: next APB back-to-back timing residue owner after selected 32-bit
  protected multi-peripheral timing shipped

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.639` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.640`, a readiness audit for APB
no-policy multi-peripheral multi-register back-to-back timing.

This selector changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Current State

The APB back-to-back timing frontier now has these selected behaviors shipped:

- fixed 32-bit no-sideband requester/completer/composition timing;
- selected 32-bit sideband requester/completer/fixed-composition timing;
- selected 32-bit sideband no-policy multi-register fixed-composition timing;
- selected 32-bit sideband protection multi-register fixed-composition timing;
- selected sideband data16 requester/completer/fixed-composition timing;
- selected sideband data16-protection fixed-composition timing;
- selected no-sideband two-peripheral multi-peripheral timing;
- selected 32-bit sideband two-peripheral one-register multi-peripheral
  timing;
- selected sideband data16-protection status/control two-peripheral timing;
- selected 32-bit sideband protection status/control two-peripheral timing.

The remaining APB timing residue is now concentrated in:

- no-policy multi-peripheral multi-register timing;
- sideband data16 no-policy multi-peripheral multi-register timing;
- data16-protection generalization beyond the selected status/control family;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester surfaces;
- multiple active APB transfers;
- broader protection-policy families;
- direct backend lowering and verification-output generation;
- backend-language variants, AXI, AHB, and VHDL.

## Selection

`.640` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.640`: audit APB no-policy
multi-peripheral multi-register back-to-back timing readiness.

The audit must decide whether the next behavior slice can implement one exact
no-policy multi-peripheral multi-register family directly, whether public
contract/source-shape selection is needed first, or whether the family should
defer explicitly. It must settle source names, endpoint storage shape,
requester/completer/interconnect timing-policy requirements, queued setup
decode, report/residue movement, support accounting, diagnostics, validation,
rollback, and documentation before any behavior change.

## Rationale

No-policy multi-peripheral multi-register timing is now the smallest coherent
APB timing residue. Fixed no-policy multi-register timing is already shipped
for selected 32-bit sideband and sideband data16 fixed-composition families,
and multi-peripheral no-policy timing is already shipped for selected
one-register peripheral families. The missing combination is the
multi-peripheral composition with two-register no-policy peripheral storage.

The current code boundary confirms that gap:

- `ApbCompleter` already accepts selected adjacent setup for sideband
  two-register no-policy completers and sideband data16 two-register
  no-policy completers.
- `ApbComposition` fixed timing already accepts selected sideband and sideband
  data16 two-register no-policy completers.
- `ApbComposition` multi-peripheral timing accepts selected one-register
  peripheral storage and the selected protected status/control shapes, but
  still rejects broader two-register no-policy peripheral storage.

Deeper queues, alternate overflow, accepted-less requesters, and multiple
active APB transfers are not next because they need new requester-admission or
APB outstanding-model contracts before composition propagation can be judged
safe. Broader protection policies, direct backend lowering,
verification-output generation, backend-language variants, AXI, AHB, and VHDL
also remain downstream of the selected APB behavior surface.

## Audit Boundary For `.640`

`.640` must read:

- `.639` selector;
- `.638` protected multi-peripheral behavior;
- `.637` protected multi-peripheral contract;
- `.636` multi-peripheral multi-register readiness audit;
- `.634` and `.633` data16-protection multi-peripheral records;
- `.628`, `.625`, and `.622` fixed multi-register timing behavior;
- `.618` and `.609` multi-peripheral timing behavior;
- current fixed no-policy multi-register `.ppif`/`.apb` sources and reports;
- current multi-peripheral no-policy `.ppif`/`.apb` sources and reports;
- `ApbRequesterTransfer`, `ApbCompleter`, and `ApbComposition` timing guards;
- `RegressionCorpus`, `LanguageSurfaceSection`, focused APB/profile-alias
  tests, README, ROADMAP_V2, mdBook, task tree, Memory, Knowledge Map, and
  relevant decisions.

The audit must not implement behavior. Its output is a precise next leaf:
direct implementation of one exact public-source family, public contract
selection, source-shape prerequisite, or explicit deferral with rationale.

## Non-Goals

`.639` and `.640` do not select or implement:

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
