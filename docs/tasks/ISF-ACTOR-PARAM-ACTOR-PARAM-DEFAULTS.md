# ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS: Ordered Actor Parameter Defaults

## Metadata

- Tree ID: `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow actor-level parameter defaults to reuse earlier scalar actor parameter
defaults without introducing a general expression solver or cyclic dependency
graph.

## Non-Goals

- Do not allow forward references, self references, cycles, or dependency
  solving across unordered actor parameters.
- Do not allow non-scalar aggregate/list actor parameters as scalar values.
- Do not allow transaction parameters, runtime interface signals, arbitrary
  expressions, package/imported constants beyond shipped enum members, or
  generated-child transaction parameter defaults in this tree.
- Do not change scheduled `.fsm` review artifacts to literalize authored
  actor-parameter tokens.

## Acceptance Criteria

- The selected source shape is bounded to earlier actor-local scalar parameter
  defaults used by name as scalar actor parameter defaults or scalar leaves
  inside compatible aggregate/list actor parameter defaults.
- Referenced actor parameters must already have a scalar numeric or exact-width
  resolved value at the point they are referenced.
- Authored actor parameter tokens stay visible in scheduled `.fsm` `+params`
  and `actor_params[]`, while resolved literals are recorded internally for
  scalar parameter consumers.
- Forward, self, later, non-scalar, transaction-parameter, runtime-signal,
  unknown-symbol, and expression-like shapes fail closed with targeted
  diagnostics.
- The ISF spec, downstream integration handoff, public contract, mdBook, task
  tree, README index, roadmap, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS`
  Status: `done`
  Goal: `Ship ordered actor-parameter-backed actor parameter defaults.`
  Children: `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.1`,
  `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2`

- ID: `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.1`
  Status: `done`
  Goal: `Select the bounded actor-parameter dependency default tree.`
  Acceptance: `The task-tree owner, implementation frontier, value-domain
  boundary, non-goals, and validation scope are recorded before code changes.`
  Verification: `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

- ID: `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2`
  Status: `done`
  Goal: `Implement earlier scalar actor parameters as actor parameter defaults.`
  Acceptance: `Parser and LoweringIR metadata resolve earlier scalar actor
  parameter defaults for scalar and aggregate/list leaves, preserve authored
  tokens in review/report surfaces, reject unsupported dependency shapes, and
  update public docs/tests.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1345-isf-actor-param-actor-constants.t`; `perl -Iperl -c t/1346-isf-actor-param-actor-params.t`; focused actor-param/static-value tests with `Files=11, Tests=35`; public/spec/book/backlog audits with `Files=6, Tests=351`; `./bin/ci-regression isf --no-book` with `Files=252, Tests=1688`; `mdbook build docs/book`; `git diff --check`
  Commit: `pending this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| - | - | `closed` | `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2` shipped the bounded ordered actor-parameter default value domain. |

## Decisions

- `2026-05-24`: Use source order as the only dependency model. Earlier
  scalar actor parameter defaults may be referenced; later, self, cyclic, and
  non-scalar dependencies remain fail-closed.
- `2026-05-24`: Preserve authored tokens in scheduled `.fsm` and
  `actor_params[]` so review artifacts stay transparent. Resolved literals are
  internal support metadata for existing scalar parameter consumers.

## Open Questions

- None for the selected bounded implementation leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-24` | `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2` | Syntax checks; focused actor-param/static-value tests; public/spec/book/backlog audits; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.1` | `91ed9079 ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.1: select actor param dependency defaults` | Selection commit. |
| `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2` | `pending this commit: ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2: ship ordered actor param defaults` | Implementation commit. |

## Changelog

- `2026-05-24`: Created the active R14 task tree for ordered
  actor-parameter-backed actor parameter defaults.
- `2026-05-24`: Shipped the bounded ordered actor-parameter-backed actor
  parameter default value domain and closed the task tree.
