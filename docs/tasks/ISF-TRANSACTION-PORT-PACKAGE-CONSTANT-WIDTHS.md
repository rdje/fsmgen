# ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS: Transaction Port Package-Constant Widths

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-25`
- Last updated: `2026-05-25`
- Owner: repo-local workflow

## Goal

Allow transaction-local `(ports ...)` declarations to use qualified imported
package scalar constants for port widths when those constants resolve to
positive integer literals.

## Non-Goals

- Do not allow unqualified package constant lookup.
- Do not allow package aggregate constants or package aggregate scalar-leaf
  paths as transaction-local port widths in this tree.
- Do not support transaction-parameter-backed transaction port widths in this
  tree.
- Do not specialize transaction port widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not accept runtime interface signals, unknown names, arbitrary
  expressions, zero-valued package constants, aggregate values, or use-site
  override values as transaction-local port widths.
- Do not change activation binding semantics, binding timing, binding
  expression width inference, output binding shapes, generated-top handoff
  naming, or schedule-report `transaction_port_bindings[]` key families.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Transaction-local `(input NAME (width PACKAGE.CONSTANT))` and
  `(output NAME (width PACKAGE.CONSTANT))` declarations parse and lower when
  the owning actor imports `PACKAGE`, the package declares `CONSTANT`, and the
  constant resolves to a positive integer scalar literal.
- Accepted package-constant transaction port widths lower exactly like
  equivalent positive literal widths in public parser handoff, scheduled
  `.fsm`, activation handoff storage, schedule reports, and generated HDL.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  and package constants outside this transaction-port-width surface remain
  fail-closed with targeted diagnostics.
- Existing positive literal, actor-constant, actor-parameter, omitted one-bit,
  and `(type NAME)` transaction port widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS`
  Status: `done`
  Goal: `Ship qualified imported package scalar constants as transaction-local port widths.`
  Children: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1`,
    `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2`

- ID: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select transaction port package-constant widths.`
  Acceptance: `Create the active task tree, record the qualified package
  scalar-constant transaction-port width boundary, preserve non-goals, and
  update roadmap/live docs without behavior changes.`
  Verification: `feature-backlog/live-book/book-matrix audits with Files=3,
  Tests=364; mdbook build docs/book; git diff --check`
  Commit: `4fa56986: ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1: select transaction port package widths`

- ID: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document qualified package scalar constants as transaction-local port widths.`
  Acceptance: `Positive imported package scalar constants lower as
  transaction-local port widths; unsupported width sources fail closed; specs,
  book, public contract, downstream handoff, focused tests, and broader ISF
  gate are synchronized.`
  Verification: `syntax checks; focused transaction/package/public tests with
  Files=13, Tests=360; ./bin/ci-regression isf --no-book with Files=263,
  Tests=1711; mdbook build docs/book; post-closure public/spec/book audits
  with Files=6, Tests=359; feature-backlog/live-book/book-matrix audits with
  Files=3, Tests=364; git diff --check`
  Commit: `65f84853 ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2: support transaction port package widths`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | Qualified imported package scalar constants now ship for transaction-local port widths. |

## Decisions

- `2026-05-25`: Select transaction-local port widths as the next bounded
  imported package scalar-constant dimension widening. Actor top-level
  interface widths, actor-owned scalar storage widths, actor-owned bank
  widths, and actor-owned bank depths already accept qualified package scalar
  constants when they resolve to positive integers.
- `2026-05-25`: Resolve only explicitly qualified constants from packages
  imported by the owning actor. Unqualified lookup and package namespace
  pollution remain fail-closed.
- `2026-05-25`: Publish the resolved positive integer width in parser
  handoff, scheduled `.fsm`, activation handoff storage, schedule reports, and
  generated HDL, matching actor-constant and actor-parameter transaction port
  width behavior rather than preserving package tokens in generated width
  fields.
- `2026-05-25`: The implementation reuses the existing actor package-constant
  resolver at transaction-port finalization time, then stores the resolved
  integer width in the public transaction shell so the scheduler, scheduled
  `.fsm`, reports, and HDL do not need a separate package-token width path.

## Open Questions

- None. Wider package-constant dimension/value surfaces are deferred by this
  task tree rather than blocking the selected leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-25` | `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1` | `feature-backlog/live-book/book-matrix audits; mdbook build docs/book; git diff --check` | `passed: Files=3, Tests=364` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -c t/1357-isf-transaction-port-package-constant-widths.t; perl -c t/1144-isf-public-tested-by-metadata-audit.t` | `passed` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` | `prove -Iperl t/1240-isf-transaction-port-declarations.t t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t t/1336-isf-transaction-port-actor-param-widths.t t/1342-isf-transaction-port-actor-constant-widths.t t/1353-isf-interface-package-constant-widths.t t/1356-isf-bank-storage-package-constant-depths.t t/1357-isf-transaction-port-package-constant-widths.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=13, Tests=360` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` | `./bin/ci-regression isf --no-book` | `passed: Files=263, Tests=1711` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` | `mdbook build docs/book; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check` | `passed: audits Files=6, Tests=359` |
| `2026-05-25` | `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` | `prove -Iperl t/1256-feature-backlog-status-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=3, Tests=364` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1` | `4fa56986: ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1: select transaction port package widths` | `selection slice` |
| `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` | `65f84853 ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2: support transaction port package widths` | `implementation slice` |

## Changelog

- `2026-05-25`: Created task tree and selected qualified imported package
  scalar constants in transaction-local port widths as the next bounded
  static-dimension implementation frontier.
- `2026-05-25`: Implemented and documented qualified imported package scalar
  constants in transaction-local port widths, added fail-closed diagnostics and
  focused regression coverage, synchronized the ISF spec, downstream handoff,
  public contract, mdBook, roadmap, task index, and live docs, and closed the
  task tree.
