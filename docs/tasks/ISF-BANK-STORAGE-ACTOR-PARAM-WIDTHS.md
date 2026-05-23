# ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS: Bank Storage Actor-Parameter Widths

## Metadata

- Tree ID: `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor-owned storage bank `(bank NAME (width PARAM) (depth N))`
declarations to use actor-local scalar parameter defaults for bank element
widths when those defaults resolve to positive integer literals.

## Non-Goals

- Do not support actor-parameter-backed bank depths in this tree.
- Do not support actor-parameter-backed transaction-local port widths in this
  tree.
- Do not change the actor top-level interface width behavior already shipped by
  `ISF-INTERFACE-ACTOR-PARAM-WIDTHS`.
- Do not change the actor-owned scalar storage width behavior already shipped
  by `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS`.
- Do not specialize bank widths through reusable-library use-site parameter
  overrides or generated-top respecialization.
- Do not accept actor constants, transaction parameters, runtime signals,
  arbitrary expressions, unknown names, zero-valued actor parameters, or
  non-scalar actor parameters as bank widths.
- Do not change bank depth scalarization counts, memory-array backend emission,
  bank access same-cycle policy, or pointer-index semantics.
- Do not change the shipped `(type NAME)` alias path or allow `(width ...)`
  together with `(type ...)`.

## Acceptance Criteria

- Actor-owned storage bank `(bank NAME (width PARAM) (depth N))` parses and
  lowers when `PARAM` names an actor-local scalar parameter default whose
  resolved value is positive.
- Accepted parameter-backed bank widths lower exactly like equivalent positive
  literal widths in scheduled `.fsm`, schedule reports, bank-access metadata,
  and generated HDL.
- Zero-valued, non-scalar, unknown, actor-constant, transaction-parameter,
  runtime-signal, and expression-valued bank width sources remain fail-closed
  with targeted diagnostics.
- Existing positive literal bank widths/depths, scalar storage widths, omitted
  type-alias storage declarations, bank access lowering, and actor top-level
  interface widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS`
  Status: `done`
  Goal: `Ship actor-parameter-backed actor-owned bank storage widths.`
  Children: `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.1`,
  `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.2`

- ID: `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.1`
  Status: `done`
  Goal: `Select bank storage actor-parameter widths.`
  Acceptance: `Create the active task tree, record the static
  actor-parameter source boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `6efa1164`

- ID: `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.2`
  Status: `done`
  Goal: `Implement and document actor-parameter bank storage widths.`
  Acceptance: `Positive actor scalar parameters lower as actor-owned bank
  element widths; unsupported width sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `perl -Iperl -c t/1335-isf-bank-storage-actor-param-widths.t`;
  `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`;
  `prove -Iperl t/1335-isf-bank-storage-actor-param-widths.t
  t/1334-isf-scalar-storage-actor-param-widths.t
  t/1232-isf-actor-storage-declarations.t
  t/1236-isf-bank-access-lowering.t
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
| _none_ | _none_ | _closed_ | `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.2` completed and the tree is closed. |

## Decisions

- `2026-05-23`: Select bank element widths, not bank depths, as the next
  parameter-driven storage slice. Width parameters reuse the existing
  scalarized bank element count, while depth parameters would change generated
  signal families, bank-access metadata, and memory-array policy.
- `2026-05-23`: Resolve only the owning actor shell's scalar parameter
  default. Use-site override specialization and generated-top
  respecialization remain separate policy work.
- `2026-05-23`: Keep actor constants and runtime interface signals out of the
  bank width symbolic path. This tree is specifically actor-parameter
  elaboration, not a general symbolic dimension system.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1335-isf-bank-storage-actor-param-widths.t`; `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1335-isf-bank-storage-actor-param-widths.t t/1334-isf-scalar-storage-actor-param-widths.t t/1232-isf-actor-storage-declarations.t t/1236-isf-bank-access-lowering.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed; focused Files=9, Tests=335; broad Files=241, Tests=1624; post-doc Files=3, Tests=339; diff clean` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.1` | `6efa1164: ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.1: select bank storage actor-param widths` | `selects static actor-parameter bank element width support` |
| `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.2` | `this commit: ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.2: ship bank storage actor-param widths` | `ships actor-parameter bank element width support` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-parameter-backed
  actor-owned bank storage widths as the next bounded parameter-driven storage
  slice.
- `2026-05-23`: Shipped actor-parameter-backed actor-owned bank storage
  widths, fail-closed unsupported symbolic sources, synchronized specs/book
  and public/downstream contracts, and closed the tree.
