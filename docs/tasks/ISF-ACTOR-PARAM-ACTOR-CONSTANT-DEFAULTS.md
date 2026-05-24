# ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS: Actor Constants In Actor Parameter Defaults

## Metadata

- Tree ID: `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS`
- Status: `done`
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
  Status: `done`
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
  Status: `done`
  Goal: `Implement actor constants as actor parameter default values`
  Acceptance: `Actor-level scalar and aggregate/list parameter defaults accept declared actor constants; malformed or runtime-looking names fail closed; focused tests and synchronized public docs pass.`
  Verification: `passed`
  Commit: `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2: ship actor const param defaults`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | All planned leaves are complete. |

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
| `2026-05-24` | `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1345-isf-actor-param-actor-constants.t`; `prove -Iperl t/1345-isf-actor-param-actor-constants.t t/1269-isf-enum-member-actor-params.t t/1277-isf-enum-member-actor-aggregate-params.t t/1333-isf-interface-actor-param-widths.t t/1334-isf-scalar-storage-actor-param-widths.t t/1335-isf-bank-storage-actor-param-widths.t t/1336-isf-transaction-port-actor-param-widths.t t/1337-isf-bank-storage-actor-param-depths.t t/1281-isf-enum-member-library-use-params.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1256-feature-backlog-status-audit.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.1` | `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.1: select actor const param defaults` | `contract-selection slice` |
| `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2` | `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2: ship actor const param defaults` | `implementation slice` |

## Changelog

- `2026-05-24`: Created task tree and selected the actor-constant actor
  parameter default contract.
- `2026-05-24`: Completed the selection leaf and advanced the frontier to
  `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2`.
- `2026-05-24`: Completed the implementation leaf and closed the task tree.
  Actor-level scalar and aggregate/list parameter defaults now accept declared
  actor constants while preserving authored defaults in scheduled `.fsm`
  `+params` and `actor_params[]`.
