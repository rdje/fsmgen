---
id: ial2-ahb-integration-public-sync-claim-evidence
title: AHB integration and public-sync claims separate current book truth from immutable checkpoints
answers:
  - "how are Chapter 14i AHB integration and public synchronization claims verified?"
  - "are the 332 focused tests and 295-file ISF regression current totals?"
  - "are the 36 mdBook chapters and 844 task-tree nodes current totals?"
  - "how is the Chapter 16c AHB exact-one-through-four versus 5 through 16 boundary verified?"
  - "which Chapter 14i integration measurements are historical?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, ahb, integration, public-sync, mdbook, task-tree, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  docs/book/src/14i-ahb-and-integration.md;
  docs/book/src/16c-ial2-ahb.md;
  docs/tasks/PUBLIC-SYNC-TEST-DRIFT-REPAIR.md;
  docs/tasks/MDBOOK-AHB-BUSY-COUNT-RESIDUE-SYNC.md;
  perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm;
  perl/FSM/Support/RegressionCorpus.pm;
  t/1474-ial2-ahb-profile-alias.t;
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t;
  t/248-regression-corpus-accounting.t;
  t/297-capability-manifest.t;
  scripts/check_task_tree_integrity.pl;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh -- prove -Iperl
  t/1474-ial2-ahb-profile-alias.t
  t/1541-ial2-ahb-requester-generalized-busy-count-range.t &&
  prove -Iperl t/248-regression-corpus-accounting.t t/297-capability-manifest.t &&
  scripts/check_task_tree_integrity.pl
---

`CLAIM-VERIFICATION-ADOPTION.5.4.12` reviews the exact 17 inventory
candidates on `docs/book/src/14i-ahb-and-integration.md` lines 1896 through
the end of the file. One candidate states current Chapter 16c numeric
behavior and uses a derived gate. The other 16 are selector or task
identifiers, synchronization-time measurements, diagram locations, or
pre-/post-repair task-ledger censuses and therefore use reviewed-incidental
dispositions.

The live gate distinguishes public catalog coverage from generic behavior.
Chapter 16c names exact-one-through-four generic/profile fixtures and states
that canonical literal counts `5..16` reuse the same requester lowerer without
one public fixture per count. The ordinary lowerer admits canonical `2..16`.
Focused t1541 independently derives candidates 5, 8, and 16 from the tracked
exact-four source, checks minimum widths, semantic/MCP/verifier output, and
seven assertion-enabled runtimes, proves the candidates remain unmatched by
support accounting, and rejects 17 plus noncanonical forms. Corpus accounting
independently retains the exact-one-through-four catalog identities.

The remaining measurements belong to their original clean commits. In
particular, 327/332 and then 332/332 focused-index coverage plus the
295-file/2,037-test ISF run belong to public-sync `.2`; the single-regex and
six-file/36-test values belong to public-sync `.3`; 36 chapters belongs to the
four-fence mdBook repair; and 842/840 followed by 844/844 belongs to the first
IAL2 task-ledger integrity repair. The current repository has intentionally
grown beyond those totals, so treating them as present-day gates would turn
accurate chronology into stale claims.

Current t1474 still exercises the parser-produced diagnostic containing both
shipped aggregate shapes. The focused current collection reports `Files=2,
Tests=9`; this result validates present parser/range behavior without
reclassifying the earlier public-sync regression totals as current.

Key durable commits are `012660f90` (public-sync `.2` activation snapshot),
`4ba108b3d` (focused-index synchronization), `ce891bbd7` (aggregate diagnostic
expectation), `59fcaa99e` (four-fence mdBook repair), `5fb1c0d47` (grouped
assertion expectation), `3fb84b23e` (Chapter 16c residue synchronization),
`bd1ef6765` (pre-repair task-ledger census), and `c21765214` (first task-tree
integrity repair).
