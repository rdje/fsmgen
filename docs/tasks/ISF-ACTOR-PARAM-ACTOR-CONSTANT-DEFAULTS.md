# ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS: Actor Constants In Actor Parameter Defaults

## Metadata

- Tree ID: `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Allow actor-level parameter defaults to use declared actor constants as static
default values, including scalar leaves inside compatible aggregate/list
parameter defaults.

## Non-Goals

- Do not accept actor parameters as actor parameter defaults in this tree.
- Do not accept transaction parameters, runtime interface/storage/transaction
  signals, or arbitrary expressions as actor parameter defaults.
- Do not accept package/imported constants beyond the existing local and
  package enum-member surface.
- Do not change generated child transaction parameter default semantics in
  this tree.
- Do not add parameter dependency ordering, cycles, or expression solving.

## Acceptance Criteria

- The selected contract is documented before implementation.
- Actor-level `(params ...)` defaults may use declared actor constants by name.
- Scalar leaves inside compatible aggregate/list actor parameter defaults may
  use declared actor constants.
- Actor-constant-backed parameter defaults preserve authored defaults in
  scheduled `.fsm` `+params` and `actor_params[]` reports while also recording
  resolved literal values internally for contexts that consume scalar actor
  parameter defaults.
- Unknown names, actor parameter names, transaction parameters, runtime
  signals, arbitrary expressions, and non-scalar constants fail closed with
  targeted diagnostics.
- The mdBook, ISF spec, downstream handoff, public contract, task tree,
  roadmap, and live docs stay synchronized when behavior ships.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS`
  Status: `active`
  Goal: `Track actor constants as actor parameter default values`
  Children: `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.1`,
  `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2`

- ID: `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.1`
  Status: `done`
  Goal: `Select the actor-constant actor-parameter default contract`
  Acceptance: `The task tree, live docs, and mdBook backlog state the selected source shape, resolution point, diagnostics, non-goals, and next implementation leaf before code changes.`
  Verification: `passed`
  Commit: `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.1: select actor const param defaults`

- ID: `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2`
  Status: `in_progress`
  Goal: `Implement actor constants as actor parameter default values`
  Acceptance: `Actor-level scalar and aggregate/list parameter defaults accept declared actor constants; malformed or runtime-looking names fail closed; focused tests and synchronized public docs pass.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2` | `in_progress` | Implement the selected bounded value-domain widening now that `.1` passed selection checks. |

## Decisions

- `2026-05-24`: The selected widening is declared actor constants only.
  Constants already resolve before actor parameter finalization, already have
  unique names distinct from actor parameters, and already carry static
  non-negative literal or enum-resolved values.
- `2026-05-24`: Actor parameter defaults will preserve authored constant names
  in public scheduled `.fsm` and `actor_params[]` views while recording a
  resolved literal value internally for width/count/value consumers.
- `2026-05-24`: Actor-parameter-to-actor-parameter defaults remain deferred to
  avoid adding dependency ordering, cycle diagnostics, or expression solving.

## Open Questions

- None for the selected first implementation leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.1` | `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.1: select actor const param defaults` | `contract-selection slice` |
| `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the actor-constant actor
  parameter default contract.
- `2026-05-24`: Completed the selection leaf and advanced the frontier to
  `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2`.
