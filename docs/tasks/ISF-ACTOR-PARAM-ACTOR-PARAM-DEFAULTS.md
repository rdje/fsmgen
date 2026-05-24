# ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS: Ordered Actor Parameter Defaults

## Metadata

- Tree ID: `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS`
- Status: `active`
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
  Status: `active`
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
  Status: `pending`
  Goal: `Implement earlier scalar actor parameters as actor parameter defaults.`
  Acceptance: `Parser and LoweringIR metadata resolve earlier scalar actor
  parameter defaults for scalar and aggregate/list leaves, preserve authored
  tokens in review/report surfaces, reject unsupported dependency shapes, and
  update public docs/tests.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2` | `pending` | This is the selected implementation leaf after the documentation-only tree selection. |

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.1` | `pending this commit: ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.1: select actor param dependency defaults` | Selection commit. |
| `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2` | `pending` | Implementation leaf. |

## Changelog

- `2026-05-24`: Created the active R14 task tree for ordered
  actor-parameter-backed actor parameter defaults.
