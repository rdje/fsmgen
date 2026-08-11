# GitHub Workflows

This directory contains the active hosted automation that GitHub discovers for
the public FSMGen repository.

## Regression CI

`regression.yml` runs the repo-owned regression gate on pushes to `main`, pull
requests targeting `main`, and manual `workflow_dispatch` runs.

The hosted workflow runs four independent required families: doctrine
enforcement, the mdBook build, 16 ordinary Perl file shards, and 68 isolated
cases from the exceptionally large dynamic transaction-ID focused test. Both
Perl matrices disable fail-fast, so one failure does not cancel or conceal the
remaining coverage. Every long-running shard has a five-hour job timeout, and
the final `build` result succeeds only after all four families succeed.

The file shards are a deterministic, disjoint partition of every tracked
`t/*.t` file except
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`. The 68 dynamic
shards partition that test's canonical 68 cases one per job; its four shared
checks run only in shard zero. `t/1183-ci-regression-tier-selection.t` audits
both unions, rejects duplicates and omissions, and locks the workflow matrix
coordinates. This preserves the complete suite while preventing a single
six-hour sequential job from hiding the tail.

Hosted jobs call `./bin/ci-regression` with the repository-owned shard options.
The ordinary local `./bin/ci-regression` command remains the unsharded full
pre-push gate and still builds the mdBook by default. Hosted shard invocations
must use `full` mode and `--no-book`; the workflow owns its one separate book
job.

The workflow's Perl setup is intentionally minimal. Runtime code should avoid
undeclared CPAN dependencies in ordinary execution, and CLI paths that are
tested for clean stderr must stay compatible with the hosted Perl version.

## GitHub Pages

`pages.yml` builds the mdBook from `docs/book` and uploads `docs/book/book` as
the Pages artifact. It runs on pushes to `main` and manual
`workflow_dispatch` runs.

The repository's GitHub Pages source must be set to GitHub Actions in the
GitHub repository settings for this workflow to publish the site.
