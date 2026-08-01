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
