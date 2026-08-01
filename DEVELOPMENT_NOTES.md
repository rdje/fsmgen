# DEVELOPMENT_NOTES

This bounded current view contains only newly appended engineering rationale.
Historical ranges and exact retrieval are indexed in
[DEVELOPMENT_NOTES_INDEX.md](DEVELOPMENT_NOTES_INDEX.md).

Add an entry only for non-obvious implementation rationale, constraints, or
local tradeoffs that have no better decision, fact, task, user-document,
source-comment, or commit home. Never add a placeholder entry for a slice.

## 2026-08-01: The rationale ledger keeps an immutable source anchor while accepting later entries

The migration fixes the 2,843 pre-cutover entries at clean activation commit
`d3c22e003` and represents that exact body as one descriptor-backed historical
range. The bounded root contains only entries appended after that source
anchor. Reconstruction therefore proves that the immutable source body is the
exact prefix of the ordered ledger, rather than requiring every later append
to rewrite or relocate the source object.

This distinction closes the first-append hole in the generic `.3` topology.
The version-backed source and historical range remain recoverable under the
repository's named full-history retention contract, while an executed local
adapter verifies their dimensions, digests, entry endpoints, ordinal closure,
current suffix, and complete reconstruction. Future rotation may seal or
archive later whole-entry ranges without changing the original source anchor.
## 2026-08-01: Chapter 14 partitions by topic while keeping the mandatory read shallow

The partition uses thirteen direct Chapter 14 pages rather than nested or
equal-sized shards. `SUMMARY.md` started at 39 lines, so twelve additional
direct members leave it at 51 of its 64-line ceiling and below the 80% warning
boundary while preserving navigation depth one. Topic boundaries also keep
the largest new page below 2,800 lines and 200 KiB without raising a limit.

The ranges follow language/data, composition, actor orchestration, IAL2,
HIAL/VIAL, AXI, APB, AHB, ISF, backend, validation, and API concerns. Two
chronologically separated HIAL/VIAL and APB ranges are reunited in their
semantic homes; within each range, original order and bytes remain unchanged.
The landing page retains the established backend deep-link as a compatibility
route. This keeps future edits discoverable by subject instead of reviving a
single chronological monolith.
