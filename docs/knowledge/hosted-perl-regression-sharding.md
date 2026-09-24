---
id: hosted-perl-regression-sharding
title: Closed hosted Perl partitions and checksummed mdBook
answers:
  - "how is the full Perl regression sharded on GitHub Actions?"
  - "why does hosted CI separate t/1438?"
  - "why are t1436 t1437 t1598 t1648 and t1650 dedicated GitHub jobs?"
  - "which hosted tests materialize OSVVM 2026.05?"
  - "how are t296 t301 t303 and t1884 sharded on GitHub Actions?"
  - "how many hosted Perl regression shards are there?"
  - "does one GitHub regression failure cancel the other shards?"
  - "how does FSMGEN prevent a six-hour hosted regression timeout?"
  - "does local ci-regression use hosted sharding?"
  - "how does hosted CI install and checksum mdBook without actions-mdbook?"
date: 2026-09-24
status: current
tags: [ci, github-actions, perl, regression, sharding, timeout, mdbook, supply-chain, continuity]
evidence: .github/workflows/regression.yml; .github/workflows/pages.yml; .github/workflows/README.md; scripts/install_hosted_mdbook.sh; bin/ci-regression; t/1183-ci-regression-tier-selection.t; t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t; docs/decisions/0063-hosted-regression-uses-closed-non-cancelling-partitions.md; docs/decisions/0088-provider-backed-hosted-tests-use-explicit-dedicated-coordinates.md; docs/tasks/DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.md; docs/book/src/10-errors-strict-mode-and-troubleshooting.md
reverify: prove -Iperl t/1183-ci-regression-tier-selection.t && bash -n scripts/install_hosted_mdbook.sh && ./bin/ci-regression full --no-book --hosted-file-shard 0/16 --dry-run && ./bin/ci-regression full --no-book --hosted-dedicated-shard 0/5 --dry-run && ./bin/ci-regression full --no-book --hosted-corpus-shard 1884:0/16 --dry-run && ./bin/ci-regression full --no-book --hosted-dynamic-shard 0/68 --dry-run && rg -n 'fail-fast|timeout-minutes|hosted-file-shard|hosted-dedicated-shard|hosted-corpus-shard|hosted-dynamic-shard|install_hosted_mdbook' .github/workflows/regression.yml .github/workflows/pages.yml bin/ci-regression
---

Hosted Perl partitions into 16 ordinary, five dedicated, 64 corpus and 68
dynamic shards. Non-ordinary owners: `t/1436`, `t/1437`, `t/1598`, `t/1648`,
`t/1650`, `t/296`, `t/301`, `t/303`, `t/1884` and `t/1438`.

Each corpus audit has 16 disjoint complete shards. T1438 runs 68 isolated
cases, shared checks only on shard zero. Only T1598/T1648/T1650 materialize
OSVVM 2026.05; only T1436 installs its pinned Verilator/Yosys pair.
Decision `0088` requires explicit Boolean provider matrix data to avoid
ambient ordinary-shard prerequisites.

All four matrices disable fail-fast with five-hour ceilings. The aggregate
requires all seven families, including doctrine, mdBook and the VIAL gate.
Full/local and hosted T1884 force all-source queries and reject ambient narrowing;
T1885 keeps bounded semantic/refusal controls in ordinary regression.

Runs `31367105225` and `31494487181` measured outliers and corpus timeouts.
Local `./bin/ci-regression` stays unsharded with the book; hosted zero-based
shards require `--no-book` because a separate job owns it.

Both book owners call `scripts/install_hosted_mdbook.sh`. It accepts Linux
x86-64, downloads official mdBook 0.5.4 under `.artifacts`, requires 4,822,940
bytes and SHA-256 `3f28de05dafca9d0f2eab99c662116b0e37b89b1d96a08f8f430b9eeae958cd7`,
then requires `mdbook v0.5.4`. It replaces `peaceiris/actions-mdbook@a6f333f62`,
whose Node 24 manifest named `lib/index.js` although its tree had no `lib/`.
