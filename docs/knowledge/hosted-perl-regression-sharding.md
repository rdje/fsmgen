---
id: hosted-perl-regression-sharding
title: Hosted Perl regression uses closed file and dynamic-case partitions
answers:
  - "how is the full Perl regression sharded on GitHub Actions?"
  - "why does hosted CI separate t/1438?"
  - "how many hosted Perl regression shards are there?"
  - "does one GitHub regression failure cancel the other shards?"
  - "how does FSMGEN prevent a six-hour hosted regression timeout?"
  - "does local ci-regression use hosted sharding?"
date: 2026-08-11
status: current
tags: [ci, github-actions, perl, regression, sharding, timeout, continuity]
evidence: .github/workflows/regression.yml; .github/workflows/README.md; bin/ci-regression; t/1183-ci-regression-tier-selection.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/decisions/0063-hosted-regression-uses-closed-non-cancelling-partitions.md; docs/tasks/GITHUB-PUSH-OUTCOME-ASSURANCE.md; docs/book/src/10-errors-strict-mode-and-troubleshooting.md
reverify: prove -Iperl t/1183-ci-regression-tier-selection.t && ./bin/ci-regression full --no-book --hosted-file-shard 0/16 --dry-run && ./bin/ci-regression full --no-book --hosted-dynamic-shard 0/68 --dry-run && rg -n 'fail-fast|timeout-minutes|hosted-file-shard|hosted-dynamic-shard' .github/workflows/regression.yml bin/ci-regression
---

The full hosted Perl regression is a closed union of 16 ordinary-file shards
and 68 dynamic-case shards. The ordinary partition deterministically assigns
every tracked `t/*.t` file except
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t` exactly once. The
dynamic partition runs each of that outlier's 68 canonical cases in its own
process; its four shared checks execute only on shard zero.

Both GitHub matrices set `fail-fast: false` and each long-running job has a
five-hour timeout. Doctrine enforcement and the mdBook build run independently.
The final `build` job always evaluates all four family results and fails unless
each family succeeded, so one red shard cannot cancel or conceal unrelated
coverage.

The split follows measured hosted evidence: cancelled run `31367105225`
observed 10,027 seconds for `t/1436` and 6,561 seconds for `t/1437`, then spent
the remaining job budget inside the 68-case `t/1438`; 1,103 lexically later
test files were never started. The local `./bin/ci-regression` default remains
the original unsharded full suite plus mdBook build. Hosted shard options are
zero-based, full-mode-only plumbing and require `--no-book` because the hosted
workflow owns one separate book job.
