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

## 2026-08-01: The roadmap archives the whole activation object, not only its chronology suffix

The bounded roadmap rewrites strategic material as well as removing the
9,354-line `Current intent` chronology, so its durable proof names the complete
10,451-line activation object. This avoids pretending that paraphrased
workstream and horizon prose is byte-preserved. One exact Git descriptor covers
every original line, while a six-range disposition states which ideas remain
live and which roles now route to task trees, the mdBook, decisions, and Git.

The live view keeps product objective, principles, `R8`–`R14` direction,
dependencies, concise milestone outcomes, current-state routing, and
`H1`–`H6` horizon intent in 317 lines. Derived 640-line / 64-KiB / 512-byte-line
bounds leave deliberate growth room without restoring the former transition
ceiling. An executed verifier binds the descriptor to exact history and rejects
missing strategic sections, missing canonical routes, pressure regression, or
a revived `Current intent` chronology sink.

## 2026-08-01: Focused-document containment separates browse topology from source membership

The root `docs/*.md` collection remains a fixed membership surface, while its
complete classification index lives at `docs/index/FOCUSED_DOCUMENTS.md` under
a separate generated-projection surface. That avoids making the index count
itself or requiring a thousand-path registry record. One deterministic
generator expands the two registered source collections, assigns every member
exactly once by audience/lifecycle/owner/role, and rejects unknown filenames.

The ISF language, downstream, and public contracts form a distinct
`maintained_reference` over bounded landing pages and eleven semantic parts.
Partition selection considered every pressure axis: the public contract was
below the line target but above the byte warning, while the root collection's
aggregate and file-count warning states remained independent. Exact activation
comparison permits only six declared link rewrites, each replacing a removed
test path with its surviving owning task record; all other source text changes
only by the deterministic one-directory link adjustment.

## 2026-08-01: Native UVM result collection is generated structure, not result evidence

Revision 4 deliberately keeps the checking/result package separate from the
normalized runtime-result artifact. Coverage, models, the scoreboard, fault
application, property checks, and diagnostics can therefore be reviewed as
ordinary generated UVM while the backend manifest still reports
`runtime=not_run` and `result=not_produced`. Sealing the generated collector
creates only an in-memory structural snapshot; it cannot satisfy the portable
result contract or parity gate.

The same boundary applies to observation. Public-port checks may be wired in
the review gallery, but verification-probe-backed expectations remain
source-mapped until a qualified adapter supplies the probe value. The private
RAL preview is not silently promoted into runtime observation authority.

## 2026-08-01: Native UVM matrix closure is selected-scope accounting, not qualification

Revision 5 treats the backend manifest's emitted-foundation list as a set that
must equal the mapping matrix exactly. Each foundation then records three
entry authorities—normal source, terse source, and typed IR—separately from
generated roles and four independent maturity states. This prevents a private
typed preview, compiler-owned topology, public source route, or structural
check from being mistaken for one another.

Review is reproducible but still judgment-bearing. The gallery generator owns
the canonical nine source and two JSON evidence snapshots; `--check` performs
an exact non-mutating comparison and rejects missing, extra, or drifted files.
That automation does not set visual review to passed. Human or delegated
findings remain durable only when they identify the artifact, generated
symbol, source-map ID, observation, severity, reproduction, expected intent,
and disposition in the owning task-tree.
