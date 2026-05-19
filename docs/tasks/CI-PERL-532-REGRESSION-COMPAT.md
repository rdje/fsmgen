# CI-PERL-532-REGRESSION-COMPAT: Hosted Perl 5.32 Regression Compatibility

## Metadata

- Tree ID: `CI-PERL-532-REGRESSION-COMPAT`
- Status: `done`
- Roadmap lane: `project operations`
- Created: `2026-05-19`
- Last updated: `2026-05-19`
- Owner: repo-local workflow

## Goal

Restore the hosted `Perl FSM Regression` workflow by making the repository's
runtime surface compatible with the workflow's Perl 5.32 environment without
depending on undeclared local CPAN modules or stderr-only warnings.

## Non-Goals

- Do not change ISF source syntax, scheduler semantics, HDL generation, or
  schedule-report behavior.
- Do not broaden the GitHub workflow beyond the existing repo-owned
  `./bin/ci-regression` entrypoint.
- Do not add a new dependency manager or require generated artifacts to be
  committed.

## Acceptance Criteria

- `perl/FSM/Adapter/ISF/Parser.pm` no longer requires `File::Slurp` at load
  time for ordinary repository execution.
- `perl/FSM/Composition/InterfacePortBuilder.pm` no longer emits the
  Perl-5.32 experimental `@_` warning from its signatured subroutine.
- Focused tests cover the previously failing surfaces: ISF parser load,
  capability-manifest clean stderr, and hosted-regression workflow syntax.
- The local regression entrypoint remains the single hosted CI command.
- Live docs and task-tree status are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `CI-PERL-532-REGRESSION-COMPAT`
  Status: `done`
  Goal: `Restore hosted Perl 5.32 regression compatibility.`
  Children: `CI-PERL-532-REGRESSION-COMPAT.1`

- ID: `CI-PERL-532-REGRESSION-COMPAT.1`
  Status: `done`
  Goal: `Remove the undeclared File::Slurp runtime dependency and eliminate the Perl-5.32 signature warning that pollutes CLI stderr.`
  Acceptance: `The hosted CI failure signatures are addressed with source-level compatibility fixes, focused local gates pass, live docs are updated, and the fix is committed and pushed so GitHub can rerun the workflow.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Composition/InterfacePortBuilder.pm`; `bash -n bin/ci-regression`; workflow YAML parse; focused capability-manifest and ISF parser/report tests; `File::Slurp` load probe; `./bin/ci-regression quick --no-book`; `./bin/ci-regression isf --no-book`; `./bin/ci-regression full --no-book` reached only five pre-existing unrelated failures reproduced on clean pre-fix `HEAD`; `mdbook build docs/book`; `git diff --check`
  Commit: `CI-PERL-532-REGRESSION-COMPAT.1: restore Perl 5.32 CI compatibility`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `CI-PERL-532-REGRESSION-COMPAT.1` | `done` | GitHub Actions was failing on every pushed `Perl FSM Regression` run because the hosted Perl 5.32 environment exposed two compatibility problems. |

## Decisions

- `2026-05-19`: Prefer source-level compatibility over installing a hidden
  CPAN dependency in CI: the parser only needs small file reads, and removing
  the undeclared module makes downstream use more portable.
- `2026-05-19`: Keep the hosted workflow pointed at `./bin/ci-regression` so
  local and hosted quality gates remain aligned.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-19` | `CI-PERL-532-REGRESSION-COMPAT.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Composition/InterfacePortBuilder.pm`; `bash -n bin/ci-regression`; workflow YAML parse; focused capability-manifest and ISF parser/report tests; `File::Slurp` load probe; `./bin/ci-regression quick --no-book`; `./bin/ci-regression isf --no-book` | passed |
| `2026-05-19` | `CI-PERL-532-REGRESSION-COMPAT.1` | `./bin/ci-regression full --no-book`; baseline replay in detached clean worktree at pre-fix `HEAD` for `t/214-factorization-fixpoint-pass-support.t t/217-factorization-fixpoint-pass-execution-support.t t/25-composition-legacy-scope-errors.t t/310-systemverilog-implicit-width-and-truthiness-hardening.t t/44-language-contract-relational-operators.t` | full local gate still fails those five tests; baseline replay fails the same five tests, proving they are pre-existing and outside this compatibility slice |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-PERL-532-REGRESSION-COMPAT.1` | `CI-PERL-532-REGRESSION-COMPAT.1: restore Perl 5.32 CI compatibility` | Restores the hosted Perl 5.32 dependency and clean-stderr compatibility surfaces; remaining full-gate failures are pre-existing and require a separate slice. |

## Changelog

- `2026-05-19`: Created task tree for hosted Perl 5.32 regression compatibility.
- `2026-05-19`: Removed the undeclared parser dependency, eliminated the
  Perl-5.32 signature warning, and closed the task tree.
