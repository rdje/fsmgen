# README-POLICY-STORAGE-LOCATION: Define The Policy File's Canonical Home

## Metadata

- Tree ID: `README-POLICY-STORAGE-LOCATION`
- Status: `done`
- Roadmap lane: `infra/continuity / entry-point documentation`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow
- Activation: director-requested on `2026-07-30`.

## Goal

Make the reusable README stability policy explicit about where an adopting
project stores the policy file.

## Non-Goals

- Do not change the README content contract, growth budgets, or exception rule.
- Do not change FSMGen runtime, source, tests, hooks, or CI behavior.
- Do not introduce a user-home, machine-global, or off-repository policy copy.
- Do not modify `README.md`, `TOOLBOX.md`, or `COMMIT.md` unless validation
  discovers a strictly necessary synchronization issue.

## Acceptance Criteria

- `README_POLICY.md` says that an adopting project stores the file as the
  git-tracked `<repository-root>/README_POLICY.md`, alongside `README.md`.
- The policy explains that the repository-root location makes the rule
  discoverable and gives contributors, hooks, and CI one versioned source.
- The policy rules out an untracked user-home or machine-global copy as the
  project's canonical policy.
- The mdBook reference entry stays aligned with the clarified adoption rule.
- Diff hygiene and all doctrine checks pass, and the completed leaf is
  committed through `COMMIT.md`.

## Task Tree

- ID: `README-POLICY-STORAGE-LOCATION`
  Status: `done`
  Goal: `Define the canonical repository-local home of README_POLICY.md.`
  Children: `README-POLICY-STORAGE-LOCATION.1`

- ID: `README-POLICY-STORAGE-LOCATION.1`
  Status: `done`
  Goal: `Document the tracked repository-root storage rule and synchronize its book pointer.`
  Acceptance: `README_POLICY.md and the mdBook reference entry identify <repository-root>/README_POLICY.md beside README.md as the canonical project-owned copy, without changing the existing content or growth policy.`
  Verification: `README_POLICY.md now has an explicit Storage location section and first adoption step naming the tracked <repository-root>/README_POLICY.md beside README.md. It explains the shared discoverability/versioning benefit and limits external copies to templates rather than canonical project policy. The mdBook reference map states the same rule. README_POLICY.md is 71 lines / 2,920 bytes. Exact wording scans and diff hygiene pass. The mdBook renders 72 files / approximately 16 MiB, and generated docs/book/book is removed. All six doctrine gates pass, including bounded Memory, Knowledge Map, relative documentation paths, README limits, and project-data locality. README.md, TOOLBOX.md, COMMIT.md, growth caps, hooks, CI, and runtime behavior are unchanged.`
  Commit: `README-POLICY-STORAGE-LOCATION.1: define canonical policy home`

## Decisions

- `2026-07-30`: Use one tracked policy at the repository root beside
  `README.md`; this is the most direct discoverable location and matches the
  file the policy governs.
- `2026-07-30`: A user-home or machine-global template may help bootstrap a
  project, but it is not the adopting project's canonical policy because it is
  not versioned with that project.

## Blockers

- None. Tree complete; the next clean action returns to the roadmap selector.
