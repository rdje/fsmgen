# 0045 — Maintained reference bounds the read path, not product scope

- Date: 2026-07-31
- Type: architecture/convention/feedback
- Status: accepted
- Refines: [0041](0041-live-documents-use-bounded-views-over-durable-stores.md), [0044](0044-external-live-document-review-corrections-precede-wider-reuse.md)
- Evidence owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23`

## Context

ANVIL identified a specification-adjacent class whose size follows legitimate
product scope rather than accumulated history. FSMGen's mdBook has the same
property: it contains unique maintained explanations and examples that have no
richer canonical prose home. Calling that collection `partitioned_canonical`
describes its storage topology but does not define an honest lifecycle.

A fixed aggregate cap is the wrong control for this information. It either
becomes decorative and moves on every product feature, or eventually forces
unique reference prose to be deleted or displaced merely to satisfy an
unrelated number. Omitting aggregate accountability entirely is also unsafe:
unreviewed bulk growth could then hide inside a legitimate product expansion.

## Decision

1. Add `maintained_reference` as an information lifecycle distinct from the
   `partitioned_canonical` storage topology. It is reserved for unique,
   deliberately maintained product or specification prose whose aggregate may
   grow only when the product contract grows.
2. Require an auditable classification containing the audience, a stable role,
   and the rationale for treating the prose as unique product reference.
3. Keep fixed health targets and inclusive ceilings for every individual part.
   The ordinary file-count and aggregate line/byte pressure axes are explicitly
   `null`; they are inapplicable, not silently unlimited or decorative.
4. Bound the repeated reading cost through one complete mandatory index with
   independent line and byte ceilings. Every collection member must be linked
   directly, so the declared maximum navigation depth is mechanically proved.
5. Replace a fixed aggregate cap with exact aggregate change authority. The
   contract records prior files/lines/bytes, the signed current change, one
   owner, one rationale, and one authority id. A Git-aware adapter proves the
   baseline and delta across revisions, rejects unrecorded growth or shrinkage,
   and forbids reused or banked authority. The last aggregate-changing record
   remains immutable across later commits that do not change the collection.
6. Classification does not waive an existing control. `docs/ISF_SPEC.md`
   remains inside its current mixed focused-document debt until leaf `.13`
   provides a bounded semantic index and reviewable parts; only then may an
   owned migration select the maintained-reference lifecycle.
7. Landing pages, ledgers, generated projections, archives, frozen records, and
   ordinary partitioned collections retain their existing controls.

## Consequences

- Product documentation can grow honestly with shipped behavior without
  pretending that product scope has a timeless maximum.
- Every aggregate change remains attributable and reviewable even though it is
  not compared with a fixed aggregate ceiling.
- Authors pay a bounded mandatory-read and per-part cost; direct complete
  navigation prevents semantic partitioning from becoming a maze.
- `maintained_reference` cannot be used as an escape hatch for monoliths,
  chronology, duplicated prose, or unclassified collections.
