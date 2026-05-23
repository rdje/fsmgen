# ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS: Transaction Port Actor-Parameter Widths

## Metadata

- Tree ID: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow transaction-local `(ports ...)` declarations to use actor-local scalar
parameter defaults for port widths when those defaults resolve to positive
integer literals.

## Non-Goals

- Do not support transaction-parameter-backed transaction port widths in this
  tree.
- Do not support actor-parameter-backed bank depths in this tree.
- Do not specialize transaction port widths through reusable-library use-site
  parameter overrides or generated-top respecialization.
- Do not accept actor constants, runtime interface signals, unknown names,
  arbitrary expressions, zero-valued actor parameters, or non-scalar actor
  parameters as transaction port widths.
- Do not change activation binding semantics, binding timing, binding
  expression width inference, output binding shapes, generated-top handoff
  naming, or schedule-report `transaction_port_bindings[]` key families.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Transaction-local `(input NAME (width PARAM))` and
  `(output NAME (width PARAM))` declarations parse and lower when `PARAM`
  names an actor-local scalar parameter default whose resolved value is
  positive.
- Accepted parameter-backed transaction port widths lower exactly like
  equivalent positive literal widths in public parser handoff, scheduled
  `.fsm`, activation handoff storage, schedule reports, and generated HDL.
- Zero-valued, non-scalar, unknown, actor-constant, transaction-parameter,
  runtime-signal, and expression-valued width sources remain fail-closed with
  targeted diagnostics.
- Existing positive literal transaction port widths, omitted one-bit widths,
  `(type NAME)` widths, activation binding checks, and transaction port report
  behavior keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS`
  Status: `done`
  Goal: `Ship actor-parameter-backed transaction-local port widths.`
  Children: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1`,
  `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2`

- ID: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1`
  Status: `done`
  Goal: `Select transaction port actor-parameter widths.`
  Acceptance: `Create the active task tree, record the static
  actor-parameter source boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `dcf216d1`

- ID: `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document actor-parameter transaction port widths.`
  Acceptance: `Positive actor scalar parameters lower as transaction-local
  port widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `perl -Iperl -c t/1336-isf-transaction-port-actor-param-widths.t`;
  `perl -Iperl -c t/1240-isf-transaction-port-declarations.t`;
  `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`;
  `prove -Iperl t/1336-isf-transaction-port-actor-param-widths.t
  t/1240-isf-transaction-port-declarations.t
  t/1241-isf-transaction-port-bindings.t
  t/1243-isf-port-binding-schedule-report.t
  t/1144-isf-public-tested-by-metadata-audit.t
  t/1112-isf-public-interface-contract.t
  t/1115-isf-public-interface-cli-manifest-audit.t
  t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t`;
  `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`;
  `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t
  t/1303-isf-public-live-book-paths-audit.t
  t/1305-isf-book-feature-matrix-audit.t`;
  `git diff --check`;
  Commit: `this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| _none_ | _none_ | _closed_ | `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2` completed and the tree is closed. |

## Decisions

- `2026-05-23`: Select transaction-local port widths as the next bounded
  actor-parameter elaboration surface. Actor interface widths, scalar storage
  widths, and bank element widths already accept actor-local scalar parameter
  defaults; transaction ports are the remaining width-bearing surface named in
  the current ISF limitations.
- `2026-05-23`: Resolve only the owning actor shell's scalar parameter
  default. Transaction parameters remain deferred because transaction port
  width specialization would need activation-site/generated-top policy beyond
  this static actor-parameter slice.
- `2026-05-23`: Keep actor constants and runtime interface signals out of the
  symbolic width path. This tree is actor-parameter elaboration, not a general
  symbolic dimension system.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-23` | `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1336-isf-transaction-port-actor-param-widths.t`; `perl -Iperl -c t/1240-isf-transaction-port-declarations.t`; `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1336-isf-transaction-port-actor-param-widths.t t/1240-isf-transaction-port-declarations.t t/1241-isf-transaction-port-bindings.t t/1243-isf-port-binding-schedule-report.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed; focused Files=9, Tests=339; broad Files=242, Tests=1627; post-doc Files=3, Tests=339; diff clean` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1` | `dcf216d1: ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1: select transaction port actor-param widths` | `selects static actor-parameter transaction-local port width support` |
| `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2` | `this commit: ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2: ship transaction port actor-param widths` | `ships actor-parameter transaction-local port width support` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-parameter-backed
  transaction-local port widths as the next bounded parameter-driven
  transaction boundary slice.
- `2026-05-23`: Shipped actor-parameter-backed transaction-local port widths,
  fail-closed unsupported symbolic sources, synchronized specs/book and
  public/downstream contracts, and closed the tree.
