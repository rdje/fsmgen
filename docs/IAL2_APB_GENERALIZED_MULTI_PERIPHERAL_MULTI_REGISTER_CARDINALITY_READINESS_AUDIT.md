# IAL2 APB Generalized Multi-Peripheral Multi-Register Cardinality Readiness Audit

- Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.670`
- Date: `2026-06-28`
- Status: audited
- Scope: broader APB generalized register-set cardinality beyond selected
  two-to-four-register two-peripheral families

## Summary

`IAL2-FEATURE-COMPLETENESS-FRONTIER.670` audits broader APB generalized
register-set cardinality readiness and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.671`, public contract selection for the
first bounded APB sideband-aware 32-bit no-policy five-register generalized
`reg0..regN` register-set multi-peripheral back-to-back timing family.

This audit changes no parser behavior, generator behavior, public samples,
support-accounting catalog, schedule/check/semantic JSON, generated artifacts,
HDL/runtime behavior, suffix acceptance, direct backend lowering,
verification-output generation, backend-language variants, APB behavior, AXI
behavior, AHB behavior, or VHDL behavior.

## Evidence Read

This audit read the `.669` selector, `.668` data16 protected generalized
behavior, `.667` contract, `.665` 32-bit protected generalized behavior,
`.662` data16 no-policy generalized behavior, `.660` 32-bit no-policy
generalized behavior, current `ApbCompleter` and `ApbComposition`
generalized cardinality predicates, report/residue surfaces,
`RegressionCorpus`, `LanguageSurfaceSection`, focused
APB/profile-alias/support/capability tests, README, ROADMAP_V2, mdBook,
Memory, Knowledge Map, and relevant decisions.

## Current State

The selected APB generalized register-set timing support is intentionally
bounded:

- 32-bit sideband-aware no-policy register-set guards pass
  `minimum_count = 2`, `maximum_count = 4`, stride `4`, and data width `32`;
- sideband-aware data16 no-policy register-set guards pass
  `minimum_count = 2`, `maximum_count = 4`, stride `2`, and data width `16`;
- 32-bit sideband-aware protected register-set guards pass
  `minimum_count = 2`, `maximum_count = 4`, stride `4`, and data width `32`;
- sideband-aware data16 protected register-set guards pass
  `minimum_count = 2`, `maximum_count = 4`, stride `2`, and data width `16`.

The multi-peripheral guards also require exactly two peripheral completers and
matching register counts for the selected generalized families.

The public support catalog has one representative source per selected
generalized family. Each representative uses `reg0/reg1/reg2`; no public
source, support-accounting identity, capability-manifest entry, mdBook
example, or focused test currently owns a five-register public shape.

The live residue now names broader cardinality beyond the selected bounded
families as future work.

## Readiness Findings

The code shape is close enough for public contract selection:

- the generalized storage predicates already share count/stride/data-width
  parameters;
- report and generated-artifact tests already assert source-ordered register
  arrays and generated `reg2` storage/read/write behavior;
- selected 32-bit no-policy cardinality widening avoids protection-policy
  matrix changes and data16 stride/strobe changes;
- a five-register representative is the smallest source shape beyond the
  current `maximum_count = 4` boundary and still fits the existing 32-bit
  status/control windows at bases `0` and `256`.

Direct implementation is not ready in `.670` because the public contract still
has to define:

- exact public `.ppif`/`.apb` source names, object id, and source anchor;
- whether the selected family admits exactly five registers or widens the
  existing 32-bit no-policy generalized family to a `maximum_count = 5`;
- report/support identities and capability buckets;
- diagnostic wording for too many registers after the selected widening;
- generated-artifact validation probes for `reg3` and `reg4`;
- rollback and next-owner boundaries.

## Selection

`.671` is the next owner:

`IAL2-FEATURE-COMPLETENESS-FRONTIER.671`: select the bounded APB
sideband-aware 32-bit no-policy five-register generalized register-set
multi-peripheral public contract before implementation.

`.671` must settle the public contract for a first cardinality widening:

- exact public source names for the `.ppif` and `.apb` alias;
- protocol-platform-intent name, source object id, and source anchor;
- one requester and exactly two peripheral completers;
- 32-bit APB/register data, `PPROT width 3`, and `PSTRB width 4`;
- status/control windows at `0` and `256`;
- representative `reg0/reg1/reg2/reg3/reg4` local addresses
  `0/4/8/12/16`;
- no register-local `access-policy` clauses;
- queue-depth `1`, overflow `reject`, adjacent setup on both completers, and
  propagation-only interconnect decode;
- report fields, residue movement, support-accounting identities, capability
  buckets, diagnostics, validation probes, rollback, README, ROADMAP_V2,
  mdBook, task tree, Memory, Knowledge Map, and next owner.

## Deferred Boundaries

This audit does not select implementation for:

- data16 five-register generalized register sets;
- protected five-register generalized register sets;
- more than five registers;
- more than two peripheral completers;
- queue depths other than `1`;
- overflow policies other than `reject`;
- accepted-less requester timing;
- multiple active APB transfers;
- alternate protection-policy matrices;
- bus matrices or scoreboards;
- direct backend lowering;
- verification-output generation;
- backend-language variants, AXI, AHB, or VHDL behavior.

## Validation

This audit closeout uses documentation/continuity validation only:

- Knowledge Map generation/check;
- mdBook build;
- docs path audit;
- memory architecture check;
- whitespace diff check;
- fact-card reverify search;
- `scripts/check_doctrines.sh`.

No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior is changed by this
audit.

## Rollback

Rollback removes this audit document, its Knowledge Map fact card, README,
ROADMAP_V2, mdBook, task-tree, Memory, and generated Knowledge Map updates.
No parser, generator, public source, support-accounting, generated-artifact,
HDL/runtime, APB transaction, AXI, AHB, or VHDL behavior changes are part of
this audit.
