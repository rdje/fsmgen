# 0040 — README routing must close destination pressure

- Date: 2026-07-31
- Type: convention/feedback
- Status: accepted
- Refines: [0038](0038-readme-policy-is-harness-neutral-and-locally-authoritative.md)
- Evidence owner: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.1`

## Context

PGEN applied the README stability policy and found a fifth cross-project
failure mode. Its README guard redirected family status and Done-bar history
to `LIVE_ACHIEVEMENT_STATUS.md`, but the destination had no cap, staleness
check, partition rule, or lifecycle control. It reached 1,547,057 bytes; 94.7%
of that file was a dated changelog. The landing page was bounded, but its
pressure had merely moved to a neighboring surface.

FSMGen's neutral policy likewise named roadmaps, task systems, changelogs,
decision records, generated indexes, and manuals without requiring adopters to
instrument those destinations. Its local failure guidance routed detail into
task trees, decisions, the book, and git while the checker measured only
`README.md`. The routing advice introduced in `b03d7666e` and `2efd79375`
therefore had no mechanical destination-closure proof.

FSMGen also has concrete evidence that destination classes need different
controls. Its live/task/history surfaces range from a 47-line overwrite-only
`MEMORY.md` to partitioned manuals and task collections, generated indexes,
multi-megabyte append ledgers, query-only git history, and two large frozen
legacy status files. Applying one README-sized cap to all of them would be
dishonest; leaving them unclassified would preserve the policy defect.

## Decision

1. A README route is complete only when every destination has an owner,
   lifecycle class, and pressure control and the route terminates without a
   cycle or another unclassified sink.
2. Hot/live files use line and byte ceilings plus overwrite/review/staleness
   semantics. Partitioned collections use index, per-file, file-count, and
   aggregate ceilings. Generated indexes also retain their canonical freshness
   gate. Append histories are query-first and must shard, rotate, or archive
   before their ceiling. External services require named retention/query
   ownership. Frozen legacy records use pinned identities and cannot receive
   routed content.
3. Legacy measurements establish local stop-growth ceilings, not ideal reusable
   defaults. A route that reaches a threshold must partition, compact, rotate,
   or open separately owned remediation. Threshold increases need an explicit
   reviewed decision.
4. FSMGen declares its actual routes in
   `doctrine/readme_entrypoint/routed_destinations.tsv`. The registered
   `README-ENTRYPOINT` doctrine validates README markers, registry structure,
   repository-relative targets, per-file and aggregate budgets, query/archive
   terminals, and frozen SHA-256 identities on every commit and CI tree.
5. `ROADMAP_STATUS.md` and `LIVE_ACHIEVEMENT_STATUS.md` remain frozen under
   decision 0025. Their exact current identities are pinned; they are never
   overflow destinations.
6. The policy body stays project- and harness-neutral. PGEN's numbers are
   reusable empirical evidence; PGEN-specific paths and FSMGen's local ceilings
   remain outside the neutral requirements.

FSMGen's adoption records these `2026-07-31` measurements and ceilings. They
are local stop-growth controls, not suggested values for another project:

| Route | Current measurement | Declared ceiling/control |
| --- | --- | --- |
| mdBook collection | 38 files; 46,935 lines; 2,485,181 bytes; largest chapter 18,660 lines / 1,154,263 bytes | 64 files; 20,000 lines / 1,310,720 bytes each; 60,000 lines / 4,194,304 bytes total |
| `ROADMAP_V2.md` | 10,348 lines / 764,098 bytes | 12,000 lines / 1,048,576 bytes |
| `MEMORY.md` | 49 lines / 3,076 bytes | 60 lines / 8,192 bytes; overwrite-only |
| `docs/TASK_TREE.md` | 1,054 lines / 165,474 bytes | 1,200 lines / 196,608 bytes |
| task collection | 566 files; 114,274 lines / 11,492,771 bytes; largest file 21,726 lines / 4,662,385 bytes | 768 files; 25,000 lines / 5,242,880 bytes each; 150,000 lines / 16,777,216 bytes total |
| decision collection | 41 files; 2,609 lines / 144,374 bytes | 128 files; 512 lines / 262,144 bytes each; 10,000 lines / 2,097,152 bytes total |
| `DEVELOPMENT_NOTES.md` | 34,509 lines / 2,494,512 bytes | 38,000 lines / 3,145,728 bytes; shard before ceiling |
| generated `KNOWLEDGE_MAP.md` | 15,541 lines / 6,130,630 bytes | 20,000 lines / 8,388,608 bytes plus freshness gate |
| `CHANGES.md` | 31,790 lines / 2,662,667 bytes | 35,000 lines / 3,145,728 bytes; shard before ceiling |
| `TOOLBOX.md` | 309 lines / 11,997 bytes | 400 lines / 32,768 bytes |
| `DOCTRINE_ENFORCEMENT.md` | 184 lines / 9,293 bytes | 300 lines / 32,768 bytes |
| frozen legacy status files | existing 1,638,574-byte and 955,308-byte records | exact SHA-256 identities; no writes or overflow routing |

Several live destinations are already near a ceiling. Leaf
`README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.2` owns the clean follow-up
measurement and exact remediation-owner selection; this decision does not
silently treat their current size as healthy.

## Consequences

- README trimming can no longer report success while silently growing one of
  FSMGen's named neighboring surfaces beyond its declared boundary.
- Large existing destinations are visible debt with finite ceilings. This
  decision does not itself rewrite their history or claim their current size is
  desirable.
- Generated, partitioned, archival, and frozen destinations use meaningful
  lifecycle controls instead of a misleading universal README-sized limit.
- Reverts, merges, and unrelated-path commits still run the closure check, so a
  destination cannot evade enforcement merely because `README.md` is unchanged.
