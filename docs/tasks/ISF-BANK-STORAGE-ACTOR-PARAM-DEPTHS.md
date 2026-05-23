# ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS: Bank Storage Actor-Parameter Depths

## Metadata

- Tree ID: `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor-owned storage bank `(bank NAME (width W) (depth PARAM))`
declarations to use actor-local scalar parameter defaults for bank depths when
those defaults resolve to positive integer literals.

## Non-Goals

- Do not support transaction-parameter-backed bank depths in this tree.
- Do not support actor constants, runtime interface signals, arbitrary
  expressions, unknown names, zero-valued actor parameters, or non-scalar actor
  parameters as bank depths.
- Do not change the actor-owned bank element width behavior already shipped by
  `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS`.
- Do not change the actor-owned scalar storage width behavior already shipped
  by `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS`.
- Do not specialize bank depths through reusable-library use-site parameter
  overrides or generated-top respecialization.
- Do not add memory-array backend emission, dynamic storage depth, route
  storage, ready/backpressure, payload protocols, or ATL route muxing.
- Do not change bank access same-cycle policy, pointer-index semantics,
  storage role names, or actor-network scheduling semantics.
- Do not change the shipped `(type NAME)` alias path or allow `(depth ...)`
  together with unsupported storage shapes.

## Acceptance Criteria

- Actor-owned storage bank `(bank NAME (width W) (depth PARAM))` parses and
  lowers when `PARAM` names an actor-local scalar parameter default whose
  resolved value is positive.
- Accepted parameter-backed bank depths lower exactly like equivalent positive
  literal depths in public parser handoff, scheduled `.fsm`, schedule reports,
  bank-access metadata, and generated HDL.
- Bank signal scalarization remains deterministic: accepted depths create the
  same `NAME_0` through `NAME_N-1` scalar storage family as literal depths,
  and duplicate lowered signal names continue to fail closed.
- Zero-valued, non-scalar, unknown, actor-constant, runtime-signal, and
  expression-valued bank depth sources remain fail-closed with targeted
  diagnostics.
- Existing positive literal bank depths, actor-parameter bank widths, scalar
  storage widths, omitted type-alias storage declarations, bank access
  lowering, and transaction-local port widths keep their shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS`
  Status: `done`
  Goal: `Ship actor-parameter-backed actor-owned bank storage depths.`
  Children: `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.1`,
  `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.2`

- ID: `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.1`
  Status: `done`
  Goal: `Select bank storage actor-parameter depths.`
  Acceptance: `Create the active task tree, record the static
  actor-parameter source boundary, preserve non-goals, and update
  roadmap/live docs without behavior changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `eafafdb1`

- ID: `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.2`
  Status: `done`
  Goal: `Implement and document actor-parameter bank storage depths.`
  Acceptance: `Positive actor scalar parameters lower as actor-owned bank
  depths; unsupported depth sources fail closed; duplicate scalarized bank
  signal names remain rejected; specs, book, public contract, downstream
  handoff, and focused tests are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`;
  `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`;
  `perl -Iperl -c t/1337-isf-bank-storage-actor-param-depths.t`;
  `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`;
  `prove -Iperl t/1337-isf-bank-storage-actor-param-depths.t
  t/1335-isf-bank-storage-actor-param-widths.t
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
| _none_ | _none_ | _closed_ | `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.2` completed and the tree is closed. |

## Decisions

- `2026-05-23`: Select bank depths as the next bounded actor-parameter storage
  slice after actor interface widths, scalar storage widths, bank element
  widths, and transaction-local port widths shipped.
- `2026-05-23`: Resolve only the owning actor shell's scalar parameter
  default. Use-site override specialization and generated-top
  respecialization remain separate policy work because they can change the
  effective scalarized storage family.
- `2026-05-23`: Keep actor constants and runtime interface signals out of the
  bank depth symbolic path. This tree is specifically actor-parameter
  elaboration, not a general symbolic dimension system.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1337-isf-bank-storage-actor-param-depths.t`; `perl -Iperl -c t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1337-isf-bank-storage-actor-param-depths.t t/1335-isf-bank-storage-actor-param-widths.t t/1334-isf-scalar-storage-actor-param-widths.t t/1232-isf-actor-storage-declarations.t t/1236-isf-bank-access-lowering.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `passed; focused Files=10, Tests=340; broad Files=243, Tests=1632; post-doc Files=3, Tests=339; diff clean` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.1` | `eafafdb1: ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.1: select bank storage actor-param depths` | `selects static actor-parameter bank depth support` |
| `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.2` | `this commit: ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.2: ship bank storage actor-param depths` | `ships actor-parameter bank depth support` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-parameter-backed
  actor-owned bank storage depths as the next bounded parameter-driven storage
  slice.
- `2026-05-23`: Shipped actor-parameter-backed actor-owned bank storage
  depths, fail-closed unsupported symbolic depth sources, duplicate
  scalarized-signal rejection after depth resolution, synchronized specs/book
  and public/downstream contracts, and closed the tree.
