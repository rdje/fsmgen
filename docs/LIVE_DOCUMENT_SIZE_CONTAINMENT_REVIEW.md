# Live-Document Size-Containment Review

This is the bounded review front door for FSMGen's live-document containment
architecture. It explains the current contract and points to retained evidence;
it is not a changelog, evidence dump, or replacement for the neutral doctrine.

## The design in one page

Live documents are working interfaces. Each one has an audience, a canonical
role, an owner, a lifecycle, a bounded working set, and a verifier. Durable
history belongs in an appropriate retained layer rather than accumulating in
the interface forever. Containment is incomplete if growth merely moves into
an unbounded neighbouring file.

The architecture separates:

1. **Canonical inputs** — maintained facts, decisions, task evidence, or book
   content from which a view is derived.
2. **Bounded views** — small entry points, indexes, current-state snapshots,
   or generated projections used during ordinary work.
3. **Retained evidence** — immutable content-addressed files or exact version
   objects used for uncommon historical retrieval.
4. **Mechanical contracts** — self-bounded JSONL registries and executed checks proving six pressure axes (including maximum line bytes), routes, identity, maintained-reference change authority, claimed currency, and lifecycle rules.

The neutral policy and checker are
[LIVE_DOCUMENT_SIZE_CONTAINMENT.md](../LIVE_DOCUMENT_SIZE_CONTAINMENT.md) and
[`live-document-size/`](../live-document-size/). FSMGen's measured adoption is
recorded in the [audit](LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md); reviewer
findings and accepted corrections are tracked in the
[disposition](LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_DISPOSITION.md).

## Migration proof

A migration must report four independent products:

- exact complete-source identity and retrieval;
- semantic closure of the material moved into maintained structures;
- dimensions of the smaller live working set; and
- any content that is absent from both retained source and semantic closure.

These products overlap. They are not line ranges in a partition, so their
sizes must never be added and compared with the former source size. A
`version_object` is conditional retention: it names a bounded retention
contract with an owner, guarantee, and recovery action. Evidence that cannot
safely depend on history is stored as a content-addressed repository file.

The first enforced record is the IAL2 task-tree re-form. Its migration manifest
retrieves the 21,726-line exact former source, independently checks all 844
sealed task nodes, measures the live root plus manifest and segment, declares
the products as overlapping, and records zero unretained residue.

## Review evidence lifecycle

The detailed external-review packet is now completed retained evidence:

- [LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md](LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md)

Its exact content is frozen by SHA-256 in the surface registry. It remains
directly retrievable but is no longer the page reviewers must scan for current
architecture. New findings go to a new task-tree-owned review artifact and a
bounded disposition; they do not reopen or append to the sealed packet.

## What reviewers should challenge

- Does every live document, including maintained reference, still have a distinct audience and current value?
- Is each overflow destination itself bounded, indexed, or explicitly
  terminal?
- Are health targets distinct from temporary enforcement ceilings?
- Are routes proved from their actual author or reader source?
- Do generated and currency claims execute their declared verifier?
- Does every version-object dependency name an actionable retention contract?
- Does every migration prove identity, semantic closure, working-set size, and
  loss residue separately?
- Can a fresh clone reproduce the checks without a harness-specific authority
  file or an off-volume project cache?

The detailed packet is intentionally retained for forensic review; this page
is intentionally bounded for routine review.
