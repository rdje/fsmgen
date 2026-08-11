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

The current checkout contains 1,600 tracked `t/*.t` files. The local full gate
must remain one ordinary `prove -I perl t` invocation plus the mdBook build,
while hosted execution needs bounded, independently visible results. A red
matrix member must not cancel unrelated coverage, and branch protection must
retain one stable aggregate result.

## Decision

1. Host the 1,599 ordinary files as 16 deterministic round-robin shards after
   excluding only
   `t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`. Shards 0-14
   contain 100 files and shard 15 contains 99; the measured `t/1436` and
   `t/1437` outliers land separately in shards 14 and 15.
2. Host the excluded test as 68 case shards, one canonical dynamic case per
   process. Its adapter and CLI matrix work remains paired per case, while its
   four shared checks execute once on shard zero. Explicit local filtering and
   the unsharded test remain unchanged.
3. Give both matrices `fail-fast: false` and a 300-minute per-job ceiling.
   Run doctrine enforcement and the mdBook build independently. Preserve the
   required `build` result as an always-run aggregate that succeeds only when
   all four families succeed.
4. Keep hosted options internal to `full` mode, require `--no-book`, reject
   malformed, empty, overlapping, or out-of-range selections, and derive the
   ordinary inventory from tracked repository-relative paths. The workflow
   owns one separate repository-local book build.
5. Do not infer hosted qualification from local structure. At the next push
   authorized by decision `0062` or the director, `.6.2` must prove the exact
   remote SHA, wait for all 87 jobs, record their URLs/conclusions, and repair
   every non-success before closing the parent.

This decision authorizes the exact bounded documentation changes required to
make the design queryable and user-visible:

- Ceiling authority: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.1-KNOWLEDGE-CARD`
- Surface: `knowledge_cards`
- Dimension: `files`
- Change: `1108 -> 1109`
- Knowledge-card transition allowance from the immutable 1,105-card baseline:
  at most four files, 429 aggregate lines, and 29,569 aggregate bytes; no
  per-card or line-width transition allowance increases.
- Focused-document transition allowance from its immutable baseline: at most
  two files, 2,687 aggregate lines, and 118,900 aggregate bytes; all other
  axes retain their current allowances.
- Ancillary-document transition allowance from its immutable baseline: at
  most three files, 233 aggregate lines, and 11,779 aggregate bytes; all other
  axes retain their current allowances.
- Maintained-reference authority:
  `GITHUB-PUSH-OUTCOME-ASSURANCE.6.1-HOSTED-CI-BOOK-SYNC`, exact mdBook
  baseline 53 files / 50,039 lines / 2,641,585 bytes plus delta 0 files / +5
  lines / +373 bytes.

## Consequences

- Every hosted failure identifies one bounded file shard or one exact dynamic
  case, and no red member hides later work through matrix cancellation.
- The known 10,027-second file outlier and 907-second dynamic depth-3 case fit
  below the five-hour ceiling with substantial margin; `.6.2` remains the
  authority for actual hosted terminal qualification of the unmeasured tail.
- CI process count increases deliberately. Aggregate work is not reduced, but
  every shard remains independently visible and has its own configured
  runtime ceiling.
- Parser, generator, HDL, protocol, CLI-result, product-support, and local
  full-regression behavior do not change.
