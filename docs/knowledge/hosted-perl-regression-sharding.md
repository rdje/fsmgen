---
id: hosted-perl-regression-sharding
title: Hosted regression uses closed Perl partitions and checksummed mdBook tooling
answers:
  - "how is the full Perl regression sharded on GitHub Actions?"
  - "why does hosted CI separate t/1438?"
  - "why are t1436 t1437 and t1598 dedicated GitHub jobs?"
  - "how are t296 t301 and t303 sharded on GitHub Actions?"
  - "how many hosted Perl regression shards are there?"
  - "does one GitHub regression failure cancel the other shards?"
  - "how does FSMGEN prevent a six-hour hosted regression timeout?"
  - "does local ci-regression use hosted sharding?"
  - "how does hosted CI install and checksum mdBook without actions-mdbook?"
date: 2026-08-11
status: current
tags: [ci, github-actions, perl, regression, sharding, timeout, mdbook, supply-chain, continuity]
evidence: .github/workflows/regression.yml; .github/workflows/pages.yml; .github/workflows/README.md; scripts/install_hosted_mdbook.sh; bin/ci-regression; t/1183-ci-regression-tier-selection.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/decisions/0063-hosted-regression-uses-closed-non-cancelling-partitions.md; docs/tasks/GITHUB-PUSH-OUTCOME-ASSURANCE.md; docs/book/src/10-errors-strict-mode-and-troubleshooting.md
reverify: prove -Iperl t/1183-ci-regression-tier-selection.t && bash -n scripts/install_hosted_mdbook.sh && ./bin/ci-regression full --no-book --hosted-file-shard 0/16 --dry-run && ./bin/ci-regression full --no-book --hosted-dedicated-shard 0/3 --dry-run && ./bin/ci-regression full --no-book --hosted-corpus-shard 296:0/16 --dry-run && ./bin/ci-regression full --no-book --hosted-dynamic-shard 0/68 --dry-run && rg -n 'fail-fast|timeout-minutes|hosted-file-shard|hosted-dedicated-shard|hosted-corpus-shard|hosted-dynamic-shard|install_hosted_mdbook' .github/workflows/regression.yml .github/workflows/pages.yml bin/ci-regression
---

Hosted Perl is a closed union of 16 ordinary, three dedicated, 48 corpus, and
68 dynamic shards. Exact non-ordinary owners are `t/1436`, `t/1437`, `t/1598`,
`t/296`, `t/301`, `t/303`, and `t/1438`.

Each corpus audit has 16 complete/disjoint entry shards; `t/1438` runs 68 cases
one per process with shared checks only on shard zero. Only `t/1598` materializes
OSVVM 2026.05; only `t/1436` installs its pinned Verilator/Yosys pair.

All four Perl matrices disable fail-fast and use five-hour ceilings. Doctrine
and mdBook run independently; the aggregate requires all six families, so one
red shard cannot cancel or conceal unrelated coverage.

Runs `31367105225` and `31494487181` measured the outliers and later corpus
timeouts that justify this split. Local `./bin/ci-regression` stays unsharded
and builds the book; hosted zero-based shard options require `--no-book` because
one separate job owns the book.

Both book owners call `scripts/install_hosted_mdbook.sh`. It accepts Linux
x86-64, downloads official mdBook 0.5.4 under `.artifacts`, requires 4,822,940
bytes and SHA-256 `3f28de05dafca9d0f2eab99c662116b0e37b89b1d96a08f8f430b9eeae958cd7`,
then requires `mdbook v0.5.4`. It replaces `peaceiris/actions-mdbook@a6f333f62`,
whose Node 24 manifest named `lib/index.js` although its tree had no `lib/`.
