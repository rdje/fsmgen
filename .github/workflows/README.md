# GitHub Workflows

This directory contains the active hosted automation that GitHub discovers for
the public FSMGen repository.

## Regression CI

`regression.yml` runs the repo-owned regression gate on pushes to `main`, pull
requests targeting `main`, and manual `workflow_dispatch` runs.

The hosted workflow calls `./bin/ci-regression`, the same entrypoint used by
the local pre-push gate. That keeps the local and GitHub quality gates aligned,
including the mdBook build that `bin/ci-regression` runs by default.

## GitHub Pages

`pages.yml` builds the mdBook from `docs/book` and uploads `docs/book/book` as
the Pages artifact. It runs on pushes to `main` and manual
`workflow_dispatch` runs.

The repository's GitHub Pages source must be set to GitHub Actions in the
GitHub repository settings for this workflow to publish the site.
