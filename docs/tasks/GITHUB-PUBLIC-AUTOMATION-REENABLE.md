# GITHUB-PUBLIC-AUTOMATION-REENABLE: Public Repository Automation Re-Enablement

## Metadata

- Tree ID: `GITHUB-PUBLIC-AUTOMATION-REENABLE`
- Status: `done`
- Roadmap lane: `project operations`
- Created: `2026-05-18`
- Last updated: `2026-05-18`
- Owner: repo-local workflow

## Goal

Restore repository-discoverable hosted automation now that the GitHub project
is public again and GitHub Actions plus GitHub Pages have been re-enabled.

## Non-Goals

- Do not change compiler, parser, scheduler, HDL generation, or ISF behavior.
- Do not broaden the regression suite itself beyond making the existing
  repo-owned gate discoverable by GitHub Actions.
- Do not require generated mdBook output to be checked into the repository.

## Acceptance Criteria

- The parked regression workflow is restored under `.github/workflows/` so
  GitHub Actions can discover and run it for `main` pushes and pull requests.
- GitHub Pages has a repo-owned workflow that builds `docs/book` and publishes
  the generated mdBook artifact through GitHub Pages.
- Stale documentation that says hosted GitHub Actions are intentionally parked
  is replaced with active automation documentation.
- Live docs and task-tree status are synchronized with the automation state.
- Focused validation proves the workflow syntax is readable, the mdBook builds,
  and the local regression entrypoint still parses.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `GITHUB-PUBLIC-AUTOMATION-REENABLE`
  Status: `done`
  Goal: `Restore hosted CI and Pages automation for the public repository.`
  Children: `GITHUB-PUBLIC-AUTOMATION-REENABLE.1`

- ID: `GITHUB-PUBLIC-AUTOMATION-REENABLE.1`
  Status: `done`
  Goal: `Move the regression workflow back under GitHub discovery, add mdBook
  Pages publishing, and synchronize docs.`
  Acceptance: `Active workflow files exist under .github/workflows, public
  docs no longer describe hosted CI as parked, validation passes, and the
  branch is committed and pushed so GitHub can run the workflows.`
  Verification: `bash -n bin/ci-regression`; `ruby -e 'require "yaml";
  ARGV.each { |path| YAML.load_file(path); puts path }'
  .github/workflows/regression.yml .github/workflows/pages.yml`;
  `mdbook build docs/book`; `./bin/ci-regression quick --no-book`;
  `git diff --check`
  Commit: `Ops: reenable GitHub CI and Pages`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `GITHUB-PUBLIC-AUTOMATION-REENABLE.1` | `done` | The repository was made public and hosted automation was re-enabled in GitHub settings, so the repo-side workflow files must be discoverable again. |

## Decisions

- `2026-05-18`: This is a project-operations tree because it changes hosted
  automation configuration and documentation only; it does not move the active
  R14 compiler frontier.
- `2026-05-18`: The regression workflow should continue to call
  `./bin/ci-regression`, keeping the local and hosted quality gates aligned.
- `2026-05-18`: GitHub Pages should build from source through Actions instead
  of committing generated mdBook output.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-18` | `GITHUB-PUBLIC-AUTOMATION-REENABLE.1` | `bash -n bin/ci-regression`; `ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path); puts path }' .github/workflows/regression.yml .github/workflows/pages.yml`; `mdbook build docs/book`; `./bin/ci-regression quick --no-book`; `git diff --check` | passed; quick gate Files=8, Tests=145 |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `GITHUB-PUBLIC-AUTOMATION-REENABLE.1` | `Ops: reenable GitHub CI and Pages` | Restores hosted regression CI and adds mdBook Pages publishing for the public repository. |

## Changelog

- `2026-05-18`: Created task tree for public repository CI and Pages
  re-enablement.
- `2026-05-18`: Completed the hosted CI and Pages re-enablement slice.
