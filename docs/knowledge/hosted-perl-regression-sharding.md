---
id: hosted-perl-regression-sharding
title: Hosted Perl regression uses closed file, dedicated, corpus, and dynamic partitions
answers:
  - "how is the full Perl regression sharded on GitHub Actions?"
  - "why does hosted CI separate t/1438?"
  - "why are t1436 t1437 and t1598 dedicated GitHub jobs?"
  - "how are t296 t301 and t303 sharded on GitHub Actions?"
  - "how many hosted Perl regression shards are there?"
  - "does one GitHub regression failure cancel the other shards?"
  - "how does FSMGEN prevent a six-hour hosted regression timeout?"
  - "does local ci-regression use hosted sharding?"
date: 2026-08-11
status: current
tags: [ci, github-actions, perl, regression, sharding, timeout, continuity]
evidence: .github/workflows/regression.yml; .github/workflows/README.md; bin/ci-regression; t/1183-ci-regression-tier-selection.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/decisions/0063-hosted-regression-uses-closed-non-cancelling-partitions.md; docs/tasks/GITHUB-PUSH-OUTCOME-ASSURANCE.md; docs/book/src/10-errors-strict-mode-and-troubleshooting.md
reverify: prove -Iperl t/1183-ci-regression-tier-selection.t && ./bin/ci-regression full --no-book --hosted-file-shard 0/16 --dry-run && ./bin/ci-regression full --no-book --hosted-dedicated-shard 0/3 --dry-run && ./bin/ci-regression full --no-book --hosted-corpus-shard 296:0/16 --dry-run && ./bin/ci-regression full --no-book --hosted-dynamic-shard 0/68 --dry-run && rg -n 'fail-fast|timeout-minutes|hosted-file-shard|hosted-dedicated-shard|hosted-corpus-shard|hosted-dynamic-shard' .github/workflows/regression.yml bin/ci-regression
---

The full hosted Perl regression is a closed union of 16 ordinary-file shards,
three dedicated outlier/provider coordinates, 48 supported-corpus entry
shards, and 68 dynamic-case shards. Seven tests are excluded from the ordinary
partition and owned exactly once by those other families: dedicated `t/1436`,
`t/1437`, and `t/1598`; corpus `t/296`, `t/301`, and `t/303`; and dynamic
`t/1438`.

Each corpus audit runs as 16 complete/disjoint entry shards. The dynamic
partition runs each of `t/1438`'s 68 canonical cases in its own process, with
four shared checks only on shard zero. Only the `t/1598` coordinate
materializes recursive OSVVM 2026.05 at its exact repository-local dependency
root; only `t/1436` installs its required pinned Verilator/Yosys pair.

All four Perl matrices set `fail-fast: false` and each long-running job has a
five-hour timeout. Doctrine enforcement and the mdBook build run independently.
The final `build` job always evaluates all six family results and fails unless
each family succeeded, so one red shard cannot cancel or conceal unrelated
coverage.

The split follows measured hosted evidence: cancelled run `31367105225`
observed 10,027 seconds for `t/1436` and 6,561 seconds for `t/1437`, then spent
the remaining job budget inside `t/1438`. Follow-up run `31494487181` reached
the five-hour ceiling with monolithic `t/296`, `t/301`, and `t/303` still in
flight; `t/1598` also lacked its exact provider root. The local
`./bin/ci-regression` default remains the original unsharded full suite plus
mdBook build. Hosted shard options are zero-based, full-mode-only plumbing and
require `--no-book` because the hosted workflow owns one separate book job.
