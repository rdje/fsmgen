# CI-HOSTED-ISF-REGRESSION-CASCADE: Hosted ISF Regression Cascade

## Metadata

- Tree ID: `CI-HOSTED-ISF-REGRESSION-CASCADE`
- Status: `done`
- Roadmap lane: `project operations`
- Created: `2026-05-19`
- Last updated: `2026-05-19`
- Owner: repo-local workflow

## Goal

Root-cause and repair the hosted `Perl FSM Regression` cascade that appears
after `CI-FULL-REGRESSION-GREEN.1` is pushed and the workflow reaches the
later ISF regression band.

## Non-Goals

- Do not weaken `./bin/ci-regression`, skip the failing ISF tests, or narrow
  hosted CI coverage to hide the cascade.
- Do not change ISF syntax, ATL syntax, schedule JSON, HDL behavior, or public
  downstream contracts unless the hosted failure proves an actual behavioral
  bug rather than an environment/test assumption.
- Do not mix this repair with the next R14/PNT feature slice.

## Acceptance Criteria

- The first hosted failure signature is extracted from GitHub logs and
  reproduced locally, or the local reproduction gap is documented with the
  exact hosted environment difference.
- The shared root cause of the failing ISF band is fixed at the smallest
  appropriate layer.
- Focused failing tests pass locally.
- `./bin/ci-regression quick --no-book` and the relevant broader gate pass.
- `mdbook build docs/book` passes if documentation changes.
- Live docs and task-tree status are synchronized.
- The completed leaf is committed through `COMMIT.md` and pushed promptly for
  hosted validation.

## Task Tree

- ID: `CI-HOSTED-ISF-REGRESSION-CASCADE`
  Status: `done`
  Goal: `Restore hosted ISF regression behavior after the full-gate repair push.`
  Children: `CI-HOSTED-ISF-REGRESSION-CASCADE.1`

- ID: `CI-HOSTED-ISF-REGRESSION-CASCADE.1`
  Status: `done`
  Goal: `Extract, reproduce, and repair the hosted-only ISF regression cascade from run 26091311743.`
  Acceptance: `The hosted failure root cause is understood, fixed without weakening coverage, validated locally, documented, committed, and pushed for a fresh hosted rerun.`
  Verification: `GitHub run log extraction identified Perl deprecated given/when warnings from FSM::Adapter::ISF::Parser; parser syntax, no-given/when grep, focused ISF cluster, quick gate, ISF band, and full local regression passed.`
  Commit: `CI-HOSTED-ISF-REGRESSION-CASCADE.1: silence hosted ISF parser warnings`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Hosted ISF parser warning cascade repaired and ready for fresh hosted validation. |

## Decisions

- `2026-05-19`: Keep this as a separate project-operations task tree because
  `CI-FULL-REGRESSION-GREEN.1` is already committed and pushed, and the hosted
  run now exposes a later failure family.
- `2026-05-19`: Repair the warning at the parser implementation layer instead
  of suppressing hosted diagnostics or relaxing clean-stderr tests. The
  deprecated smartmatch `given` / `when` dispatch is not needed for actor-body
  keyword routing and can be replaced by explicit equality checks.

## Open Questions

- None yet.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-19` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | GitHub run `26091311743` for commit `de04debd` | failed in the shared regression script after reaching the later ISF regression band; root cause extracted in the next verification entry |
| `2026-05-19` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | Extracted `build/5_Run shared regression CI script.txt` from GitHub run `26091311743` | Root cause identified as deprecated `given` / `when` warnings from `perl/FSM/Adapter/ISF/Parser.pm` polluting clean-stderr assertions |
| `2026-05-19` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm` | pass |
| `2026-05-19` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | `rg -n "\bgiven\s*\(|\bwhen\s*\(" perl/FSM/Adapter/ISF/Parser.pm` | no matches |
| `2026-05-19` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | `prove -Iperl -v t/1260-isf-aggregate-storage-leaf-reads.t t/1272-isf-enum-member-rule-values.t t/1273-isf-enum-member-rule-expression-values.t t/1322-isf-actor-network-static.t t/1330-isf-atl-resolved-child-fixture-coverage.t` | pass; 5 files, 39 tests |
| `2026-05-19` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | `./bin/ci-regression quick --no-book` | pass; 8 files, 145 tests |
| `2026-05-19` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | `./bin/ci-regression isf --no-book` | pass; 236 files, 1391 tests |
| `2026-05-19` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | `./bin/ci-regression full --no-book` | pass; 1328 files, 6199 tests |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `CI-HOSTED-ISF-REGRESSION-CASCADE.1` | `CI-HOSTED-ISF-REGRESSION-CASCADE.1: silence hosted ISF parser warnings` | This commit |

## Changelog

- `2026-05-19`: Created task tree for the hosted-only ISF regression cascade
  exposed by the post-push GitHub run.
- `2026-05-19`: Repaired the hosted clean-stderr cascade by replacing the ISF
  actor-body parser's deprecated `given` / `when` dispatch with explicit
  keyword comparisons; task tree closed in the same commit.
