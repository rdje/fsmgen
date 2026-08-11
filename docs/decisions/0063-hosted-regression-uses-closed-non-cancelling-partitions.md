# 0063 — Hosted regression uses closed non-cancelling partitions

- Date: 2026-08-11
- Type: CI architecture/continuity
- Status: selected by `GITHUB-PUSH-OUTCOME-ASSURANCE.6.1`
- Implements: [0062](0062-push-cadence-is-200-commits.md)
- Qualification owner: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2`

## Context

Git transport succeeded for revision
`de9d50a5fb17074d29615ea866cd3cc6af503a3b`, but its single sequential Perl
job reached GitHub's six-hour limit. The hosted log completed 496 suite files,
measured `t/1436` at 10,027 seconds and `t/1437` at 6,561 seconds, then entered
the 68-case `t/1438`; 1,103 lexically later test files never started. Merely
splitting files would still leave all 68 expensive dynamic cases coupled in
one job.

The repair checkout initially contained 1,600 tracked `t/*.t` files. The local full gate
must remain one ordinary `prove -I perl t` invocation plus the mdBook build,
while hosted execution needs bounded, independently visible results. A red
matrix member must not cancel unrelated coverage, and branch protection must
retain one stable aggregate result.

The first 16+68 repair exposed the next runtime boundary in exact run
`31494487181`: three ordinary jobs reached their five-hour ceilings inside
monolithic `t/296`, `t/301`, and `t/303`; separately, `t/1598` required its
repository-local recursive OSVVM provider, while measured `t/1436` and `t/1437`
still consumed 10,027 and 6,561 seconds. The repaired checkout now contains
1,605 tracked tests. File sharding alone cannot give these tests credible
headroom or exact dependency ownership.

## Decision

1. Host the 1,598 ordinary files as 16 deterministic round-robin shards after
   excluding exactly seven separately owned tests. Shards 0-13 contain 100
   files and shards 14-15 contain 99.
2. Host `t/1436`, `t/1437`, and provider-dependent `t/1598` as three fixed
   dedicated coordinates. Only the `t/1436` coordinate installs its pinned
   Verilator/Yosys pair. Only the `t/1598` coordinate recursively materializes
   OSVVM 2026.05 at `.artifacts/cache/providers/osvvm/2026.05/source` and
   verifies root commit `2f7c391051dfb11890fa4bdbda9918d1db492250`.
3. Host each of monolithic `t/296`, `t/301`, and `t/303` as 16 deterministic
   complete/disjoint entry shards. Their default unsharded local paths remain
   complete and unchanged.
4. Host `t/1438` as 68 case shards, one canonical dynamic case per
   process. Its adapter and CLI matrix work remains paired per case, while its
   four shared checks execute once on shard zero. Explicit local filtering and
   the unsharded test remain unchanged.
5. Give all four Perl matrices `fail-fast: false` and a 300-minute per-job
   ceiling. Run doctrine enforcement and the mdBook build independently.
   Preserve the required `build` result as an always-run aggregate that
   succeeds only when all six families succeed.
6. Keep hosted options internal to `full` mode, require `--no-book`, reject
   malformed, empty, overlapping, or out-of-range selections, and derive the
   ordinary inventory from tracked repository-relative paths. The workflow
   owns one separate repository-local book build. Ordinary shards retain
   complete main-repository history and pinned Icarus/Verilator/Yosys because
   their remaining tests require those contracts; other matrices stay shallow
   and dependency-minimal unless their exact coordinate says otherwise.
7. Do not infer hosted qualification from local structure. At the next push
   authorized by decision `0062` or the director, `.6.2` must prove the exact
   remote SHA, wait for all 138 jobs, record their URLs/conclusions, and repair
   every non-success before closing the parent.

This decision authorizes the exact bounded documentation changes required to
make the design queryable and user-visible:

- Ceiling authority: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.1-KNOWLEDGE-CARD`
- Surface: `knowledge_cards`
- Dimension: `files`
- Change: `1108 -> 1109`
- Knowledge-card transition allowance from the immutable 1,105-card baseline:
  at most four files, 425 aggregate lines, and 30,031 aggregate bytes; the
  maximum per-card line allowance ratchets from 35 to 33, and no line-width
  transition allowance is added.
- Focused-document transition allowance from its immutable baseline: at most
  two files, 2,687 aggregate lines, and 118,900 aggregate bytes; all other
  axes retain their current allowances.
- Ancillary-document transition allowance from its immutable baseline: at
  most three files, 237 aggregate lines, and 12,104 aggregate bytes; all other
  axes retain their current allowances.
- Maintained-reference authority:
  `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.18.2-HOSTED-CI-RUNTIME-BOOK-SYNC`, exact
  mdBook baseline 53 files / 50,141 lines / 2,645,933 bytes plus delta 0 files /
  +3 lines / +219 bytes.

## Consequences

- Every hosted failure identifies one bounded ordinary file shard, dedicated
  test, supported-corpus entry shard, or exact dynamic case, and no red member
  hides later work through matrix cancellation.
- The known 10,027-second and 6,561-second outliers run alone. Provider data is
  present only where required, while each formerly monolithic corpus audit has
  16 independently visible runtime bounds. `.6.2` remains the authority for
  actual hosted terminal qualification of the repaired revision.
- CI process count increases deliberately. Aggregate work is not reduced, but
  every shard remains independently visible and has its own configured
  runtime ceiling.
- Parser, generator, HDL, protocol, CLI-result, product-support, and local
  full-regression behavior do not change.
