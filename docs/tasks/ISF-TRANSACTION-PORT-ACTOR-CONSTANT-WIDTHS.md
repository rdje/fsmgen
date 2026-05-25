# ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS: Transaction Port Actor-Constant Widths

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow transaction-local `(ports ...)` declarations to use actor-local positive
constants for port widths when those constants resolve to positive integer
literals.

## Non-Goals

- Do not support transaction-parameter-backed transaction port widths in this
  tree.
- Do not change the already shipped actor-parameter-backed transaction port
  width behavior.
- Do not change the already shipped actor-interface, actor-owned scalar
  storage, actor-owned bank width, or actor-owned bank depth static-dimension
  behavior.
- Do not specialize transaction port widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not accept runtime interface signals, unknown names, arbitrary
  expressions, zero-valued actor constants, aggregate values, or use-site
  override values as transaction-local port widths.
- Do not change activation binding semantics, binding timing, binding
  expression width inference, output binding shapes, generated-top handoff
  naming, or schedule-report `transaction_port_bindings[]` key families.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Transaction-local `(input NAME (width CONST))` and
  `(output NAME (width CONST))` declarations parse and lower when `CONST`
  names an actor-local constant whose resolved value is positive.
- Accepted actor-constant transaction port widths lower exactly like
  equivalent positive literal widths in public parser handoff, scheduled
  `.fsm`, activation handoff storage, schedule reports, and generated HDL.
- Zero-valued, unknown, runtime-signal, expression-valued, aggregate-like, and
  transaction-parameter-like width sources remain fail-closed with targeted
  diagnostics. Existing positive literal and actor-parameter transaction port
  widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS`
  Status: `done`
  Goal: `Ship actor-constant-backed transaction-local port widths.`
  Children: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1`,
  `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2`

- ID: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select transaction port actor-constant widths.`
  Acceptance: `Create the active task tree, record the actor-constant source
  boundary, preserve non-goals, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `794dbb78`

- ID: `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document actor-constant transaction port widths.`
  Acceptance: `Positive actor constants lower as transaction-local port
  widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `syntax checks`; `focused transaction-port/public/spec/book tests`;
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `post-closure doc/public audits with Files=7, Tests=352`; `git diff --check`
  Commit: `40bc6b66 ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2: ship transaction port actor-constant widths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `Actor-constant transaction-local port width support is shipped and the tree is closed.` |

## Decisions

- `2026-05-23`: Select transaction-local port widths as the next
  actor-constant static-dimension surface. Actor top-level interface widths,
  actor-owned scalar storage widths, actor-owned bank widths, and actor-owned
  bank depths already accept declared actor constants when they resolve to
  positive integers.
- `2026-05-23`: Resolve only the owning actor shell's constant value.
  Transaction parameters, use-site overrides, and generated-top
  respecialization remain separate policy work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-23` | `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2` | `syntax checks`; `prove -Iperl t/1342-isf-transaction-port-actor-constant-widths.t t/1336-isf-transaction-port-actor-param-widths.t t/1240-isf-transaction-port-declarations.t t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1160-isf-public-actor-shell-value-shape-audit.t t/1163-isf-public-actor-shell-transaction-shape-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `post-closure doc/public audits with Files=7, Tests=352`; `git diff --check` | `actor-constant transaction port widths shipped; broad ISF gate passed with Files=248, Tests=1649` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1` | `794dbb78: ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1: select transaction port actor-constant widths` | `selects actor-constant transaction port width support` |
| `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2` | `40bc6b66 ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2: ship transaction port actor-constant widths` | `ships actor-constant transaction port width support` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-constant-backed
  transaction-local port widths as the next bounded static-dimension slice.
- `2026-05-23`: Shipped actor-constant-backed transaction-local port widths,
  synchronized specs/book/public contract/downstream handoff/live docs, and
  closed the task tree.
