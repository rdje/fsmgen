# GitHub Workflows

This directory documents the public FSMGen repository's hosted automation.

## Regression CI

`regression.yml` runs the repository gate on `main` pushes, pull requests, and
manual `workflow_dispatch` requests.

Four families are required: doctrine enforcement, mdBook, 16 ordinary Perl file
shards, and 68 cases from the large dynamic transaction-ID test. Both matrices
disable fail-fast, each long shard has a five-hour timeout, and final `build`
succeeds only when every family succeeds.

File shards partition every tracked `t/*.t` except the separately case-sharded
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`. Its 68 canonical
cases run one per job, with four shared checks only in shard zero. `t/1183` locks
both disjoint unions and all matrix coordinates so no tail is hidden.

Ordinary shards pin `ubuntu-24.04`, `iverilog=12.0-2build2`,
`verilator=5.020-1`, and `yosys=0.33-5build2`; they verify all three package
revisions and print tool versions before compile/runtime, lint, synthesis, and
harness tests. They also fetch complete repository history because
retained-document and doctrine tests verify exact historical objects. The
dynamic test invokes none of these tools, does not inspect repository history,
and stays Perl-only with the default shallow checkout. These ephemeral OS
dependencies are not project data and do not alter FSMGen's separately
qualified public Verilator backend.

Hosted jobs call `./bin/ci-regression full --no-book` with repository-owned
shard options; one separate job owns the book. Local `./bin/ci-regression`
remains the unsharded full pre-push gate and builds the book by default.

Perl setup stays minimal and clean-stderr compatible. Direct actions use
immutable Node 24-compatible pins, book jobs pin mdBook 0.5.4, and no insecure Node fallback is enabled.

## GitHub Pages

`pages.yml` builds `docs/book`, uploads `docs/book/book`, and runs on `main`
pushes or manual dispatch.

Repository settings must select GitHub Actions as the Pages source.
