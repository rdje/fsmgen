# FSMGen Live-Document Size-Containment Audit

- Measurement date: `2026-07-31`
- Measured revision: `b1cebcdcebc1b0e9cbb80bab5c259788be31b75e`
- Doctrine: [LIVE_DOCUMENT_SIZE_CONTAINMENT.md](../LIVE_DOCUMENT_SIZE_CONTAINMENT.md)
- Decision: [0041](decisions/0041-live-documents-use-bounded-views-over-durable-stores.md)
- Owner tree: [LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION](tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md)

This is FSMGen's fenced local adoption evidence, not a reusable threshold
catalog. Percentages compare the clean activation revision with the local
stop-growth limits in
`doctrine/readme_entrypoint/routed_destinations.tsv`. The audit changes no
limit, content topology, frozen file, or product behavior.

## Result

Seven live surfaces have reached at least 80% of one declared limit: the roadmap,
bounded Memory pointer, task index, one task file, one mdBook chapter,
`DEVELOPMENT_NOTES.md`, and `CHANGES.md` (including the two per-file outliers
within otherwise-bounded collections). The Memory pointer is
healthy because it is overwrite-only and carries no required history; it needs
routine trimming, not sharding. Every other high-water surface has an exact
migration owner below.

The generated Knowledge Map is also a structural outlier at 6,130,630 bytes
despite remaining below 80% of its deliberately generous legacy ceiling. Its
canonical fact cards are already small and addressable, so the monolithic map
is unnecessary read pressure. The task collection has the inverse pattern:
its aggregate is below 80%, but one active file is 4,662,385 bytes and holds
hundreds of completed leaves in the same live unit as the frontier.

## Registered-route census

| Route/surface | Clean measurement | Limit utilization | Classification and disposition |
| --- | --- | --- | --- |
| mdBook collection | 38 files; 46,937 lines; 2,485,364 bytes | files 59.4%; aggregate lines 78.2%; aggregate bytes 59.3% | `partitioned_canonical`; aggregate is controlled, but Chapter 14 is a per-part high-water outlier |
| Chapter 14 feature backlog | 18,660 lines; 1,154,263 bytes | per-part lines 93.3%; bytes 88.1% | live debt; split by stable feature topic while preserving all user-facing content in the book |
| capability query | `bin/fsmgen` query terminal | not size-budgeted | acceptable query/generation terminal with contract tests; no authored history sink |
| `ROADMAP_V2.md` | 10,351 lines; 764,316 bytes; 7 level-two and 16 level-three sections | lines 86.3%; bytes 72.9% | live debt; bound current/future direction and prove shipped chronology against book/task/git homes before delete-with-link or archive |
| `MEMORY.md` | 50 lines; 3,132 bytes | lines 83.3%; bytes 38.2% | acceptable `bounded_snapshot`; overwrite and trim current state, never shard or append history |
| `docs/TASK_TREE.md` | 1,054 lines; 165,533 bytes | lines 87.8%; bytes 84.2% | live debt; make the live active/proposed index bounded and derive/query completed-tree history |
| task-tree collection | 566 files; 114,290 lines; 11,495,617 bytes | files 73.7%; aggregate lines 76.2%; bytes 68.5% | controlled collection with one severe per-file outlier and several completed-tree candidates for compact archive terminals |
| active IAL2 feature tree | 21,726 lines; 4,662,385 bytes | per-part lines 86.9%; bytes 88.9% | live debt; introduce a sealed-subtree schema so the live root/frontier is bounded without losing exact node evidence |
| decision collection | 41 files; 2,609 lines; 144,374 bytes; largest line count 117 and largest byte count 6,556 | files 32.0%; aggregate lines 26.1%; bytes 6.9%; largest per-part lines 22.9%; bytes 2.5% | healthy `partitioned_canonical`; retain one decision per file plus bounded index |
| `DEVELOPMENT_NOTES.md` | 34,509 lines; 2,494,512 bytes; 2,842 level-two entries | lines 90.8%; bytes 79.3% | rollover-required live debt; retain a bounded current rationale window and move sealed chronology through verified ledger/archive transitions |
| generated `KNOWLEDGE_MAP.md` | 15,541 lines; 6,130,630 bytes | lines 77.7%; bytes 73.1% | structural outlier; generate bounded prefix/topic shards and a small root/query projection from canonical fact cards |
| `CHANGES.md` | 31,799 lines; 2,663,165 bytes; 174 level-two and 2,946 level-three headings | lines 90.9%; bytes 84.7% | rollover-required live debt; retain a bounded current changelog and archive sealed historical ranges with deterministic retrieval |
| exact history | repository version history | query terminal | acceptable `archive_terminal`; query-first and never a mandatory bootstrap read |
| `TOOLBOX.md` | 309 lines; 11,997 bytes | lines 77.3%; bytes 36.6% | healthy but near warning; keep as a bounded procedure index and partition procedures if it reaches warning |
| `DOCTRINE_ENFORCEMENT.md` | 184 lines; 9,293 bytes | lines 61.3%; bytes 28.4% | healthy bounded doctrine index |
| `ROADMAP_STATUS.md` | 15,039 lines; 1,638,574 bytes | exact frozen identity | acceptable only as `frozen_legacy` under decision 0025; no new route or write is allowed |
| `LIVE_ACHIEVEMENT_STATUS.md` | 16,618 lines; 955,308 bytes | exact frozen identity | acceptable only as `frozen_legacy` under decision 0025; no new route or write is allowed |

The numeric census came from the unconditional README route checker plus
`wc -l -c`; structural counts came from anchored heading probes. Per-part
ranking confirms that the next-largest book chapter is only 3,501 lines and
the next-largest task file is 4,654 lines, so the two named monoliths are not
normal collection density.

## Selected local topology and owners

| Family | Selected bounded view and durable store | Exact owner |
| --- | --- | --- |
| Common enforcement | One project data registry declares every surface, class, route, warning/rollover/hard limits, topology, and verifier; one unconditional checker consumes it | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2` |
| Change and rationale ledgers | The existing four-file lifecycle review retains authority over their long-term audiences. If change/rationale ledgers remain live, root files become bounded current/index views; records seal on semantic entry boundaries into repository-local range shards, then leave the live collection only through digest-verified version-archive descriptors | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` selects the roles; `.3` consumes that decision and proves the schema; `.4`/`.5` perform only selected migrations |
| Task evidence and index | Each active root keeps metadata plus the live ancestor/frontier; completed node ranges seal into immutable subtree segments with a bounded manifest. Completed trees may become compact terminals only after exact revision retrieval is proved. The cross-tree live index shows active/proposed work; completed history is derived/query-first | `.6` changes the task schema/checker; `.7` migrates the active IAL2 outlier, completed outliers, and cross-tree index |
| User-facing feature backlog | Split Chapter 14 by stable feature topic and retain all material in mdBook navigation; do not send user-facing reference content only to version history | `.8` |
| Roadmap | Keep current/future direction and concise milestone outcomes live; prove old shipped narration against the book, task records, and exact history, then delete-with-link or retain only verified archival descriptors | `.9` |
| Knowledge Map | Keep fact cards canonical; generate a small root index plus deterministic prefix/topic shards and a repository-local query cache under `.artifacts/` | `.10` |
| Frozen status files | Remain identity-pinned and untouched until the already scheduled four-file lifecycle review chooses their audiences and fate | `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`, then `.11` consumes that decision if migration is selected |
| Final steady state | Remeasure all surfaces, prove retrieval/reconstruction, and lower temporary legacy ceilings to derived retained-surface budgets | `.12` |

## Why this is containment rather than displacement

- The root/current views stop growing because they overwrite, rotate, or are
  generated from bounded partitions.
- Repository shards remain only where direct navigation is part of the user or
  maintainer contract.
- Rarely read exact chronology can leave the working tree only after its
  descriptor proves revision, path, digest, size, and reproducible retrieval.
- Generated projections carry no unique information and can always be rebuilt
  from canonical small units.
- Each collection has both per-part and aggregate transitions, so a thousand
  small shards cannot silently replace one large blob.
- All persistent local paths are repository-relative and same-volume; no
  machine-home, temporary-directory, or harness-private store becomes durable
  state.

No migration or deletion is performed by this audit. Each migration begins
from a clean commit, records pre-move identities, and lands atomically under
its named task-tree leaf.
