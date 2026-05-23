# ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS: Bank Storage Actor-Constant Widths

## Metadata

- Tree ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor-owned bank storage `(bank NAME (width CONST) (depth D))`
declarations to use actor-local positive constants for bank element widths
when those constants resolve to positive integer literals.

## Non-Goals

- Do not support actor-constant-backed bank depths or transaction-local port
  widths in this tree.
- Do not change the actor-parameter-backed interface, storage, bank, or
  transaction-port behavior already shipped.
- Do not accept runtime interface signals, transaction parameters, arbitrary
  expressions, unknown names, zero-valued actor constants, aggregate values,
  or use-site override values as bank storage widths.
- Do not specialize bank widths through reusable-library use-site parameter
  overrides or generated-top respecialization.
- Do not change bank scalarization, pointer-index semantics, same-cycle bank
  access policy, memory-array backend emission, or `(type NAME)` alias
  behavior.

## Acceptance Criteria

- Actor-owned storage `(bank NAME (width CONST) (depth D))` declarations parse
  and lower when `CONST` names an actor-local constant whose resolved value is
  positive.
- Accepted actor-constant bank widths lower exactly like equivalent positive
  literal widths in public parser handoff, scheduled `.fsm`, schedule reports,
  bank access metadata, and generated HDL.
- Zero-valued, unknown, runtime-signal, expression-valued, and aggregate-like
  width sources remain fail-closed with targeted diagnostics. Existing
  actor-parameter bank widths and depths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS`
  Status: `done`
  Goal: `Ship actor-constant-backed actor-owned bank storage widths.`
  Children: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1`,
  `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2`

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1`
  Status: `done`
  Goal: `Select bank storage actor-constant widths.`
  Acceptance: `Create the active task tree, record the actor-constant source
  boundary, preserve non-goals, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `this commit`

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document actor-constant bank storage widths.`
  Acceptance: `Positive actor constants lower as actor-owned bank storage
  widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `perl -Iperl -c t/1340-isf-bank-storage-actor-constant-widths.t`;
  `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`;
  focused `prove` with `Files=11, Tests=343`; `mdbook build docs/book`;
  broad `./bin/ci-regression isf --no-book` with `Files=246, Tests=1641`;
  post-closure doc/public audits with `Files=6, Tests=348`;
  `git diff --check`
  Commit: `this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `Actor-constant-backed actor-owned bank storage widths are shipped and the tree is closed.` |

## Decisions

- `2026-05-23`: Select actor-owned bank element widths as the next
  actor-constant static-dimension slice. This follows the shipped
  actor-parameter bank-width slice and the shipped actor-constant scalar
  storage-width slice while keeping bank depth scalarization policy and
  generated-top specialization separate.
- `2026-05-23`: Resolve only the owning actor shell's constant value.
  Use-site overrides and generated-top respecialization remain separate policy
  work.
- `2026-05-23`: Actor constants are accepted only for actor-owned bank element
  widths in this tree. Bank depths, transaction-local ports, runtime
  interface signals, arbitrary expressions, use-site overrides, generated-top
  respecialization, memory-array backend emission, and same-cycle bank policy
  changes remain out of scope.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2` | syntax checks; focused bank/public tests with `Files=11, Tests=343`; `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with `Files=246, Tests=1641`; post-closure doc/public audits with `Files=6, Tests=348`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1` | `ef1b0d06: ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1: select bank storage actor-constant widths` | `selects actor-constant bank storage width support` |
| `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2` | `this commit: ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2: ship bank storage actor-constant widths` | `ships actor-constant bank storage width support and closes the tree` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-constant-backed
  actor-owned bank storage widths as the next bounded static-dimension slice.
- `2026-05-23`: Shipped actor-constant-backed actor-owned bank storage widths.
  Positive declared actor constants, including enum-backed constants, now
  resolve to concrete bank element widths, scalarized bank storage widths,
  scheduled `.fsm` `+size` entries, schedule-report `actor_storage` and
  `bank_accesses[]` widths, and HDL register ranges. Unsupported
  symbolic/runtime/expression/zero width sources and actor-constant bank
  depths still fail closed. Synchronized the ISF spec, downstream integration
  handoff, public contract, mdBook, roadmap status, and live docs.
