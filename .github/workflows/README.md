# GitHub Workflows

This directory documents the public FSMGen repository's hosted automation.

## Regression CI

`regression.yml` runs the repository gate on `main` pushes, pull requests, and
manual `workflow_dispatch` requests.

Six required families cover doctrine, mdBook, 16 ordinary Perl shards, five
dedicated tests, 48 corpus-entry shards, and 68 dynamic cases. All four Perl
matrices disable fail-fast, each long shard has a five-hour timeout, and final
`build` succeeds only when every family succeeds.

File shards partition every tracked `t/*.t` except nine separately owned tests.
`t/1436`, `t/1437`, `t/1598`, `t/1648`, and `t/1650` run as dedicated
coordinates. Each of `t/296`, `t/301`, and `t/303` has 16 complete/disjoint
entry shards. `t/1438` runs its 68 canonical cases one per job, with four shared
checks only in shard zero. `t/1183` locks the complete file inventory and every
matrix coordinate so no tail is hidden.

Ordinary shards pin `ubuntu-24.04`, `iverilog=12.0-2build2`,
`verilator=5.020-1`, and `yosys=0.33-5build2`; they verify all three package
revisions and print tool versions before compile/runtime, lint, synthesis, and
harness tests. They also fetch complete repository history because
retained-document and doctrine tests verify exact historical objects. The
dedicated `t/1436` retains its exact Verilator/Yosys pair. Dedicated `t/1598`,
`t/1648`, and `t/1650` recursively materialize OSVVM 2026.05 in isolated local
provider caches and verify root commit
`2f7c391051dfb11890fa4bdbda9918d1db492250`. Corpus and dynamic shards stay
Perl-only with shallow checkouts. The OS packages are ephemeral runner
dependencies; provider bytes remain repository-local project data for that
job. Neither changes FSMGen's separately qualified public backends.

Hosted jobs call `./bin/ci-regression full --no-book` with repository-owned
shard options; one separate job owns the book. Local `./bin/ci-regression`
remains the unsharded full pre-push gate and builds the book by default.

Perl setup stays minimal. Actions use immutable Node 24 pins; book jobs use the
checksummed local mdBook 0.5.4 installer. No insecure Node fallback is enabled.

## GitHub Pages

`pages.yml` builds `docs/book`, uploads `docs/book/book`, and runs on `main`
pushes or manual dispatch.

Repository settings must select GitHub Actions as the Pages source.
