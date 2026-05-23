# ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS: Bank Storage Actor-Constant Depths

## Metadata

- Tree ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Allow actor-owned bank storage `(bank NAME (width W) (depth CONST))`
declarations to use actor-local positive constants for bank depths when those
constants resolve to positive integer literals.

## Non-Goals

- Do not support transaction-local port widths in this tree.
- Do not change the actor-parameter-backed interface, storage, bank, or
  transaction-port behavior already shipped.
- Do not accept runtime interface signals, transaction parameters, arbitrary
  expressions, unknown names, zero-valued actor constants, aggregate values,
  or use-site override values as bank storage depths.
- Do not specialize bank depths through reusable-library use-site parameter
  overrides or generated-top respecialization.
- Do not change pointer-index semantics, same-cycle bank access policy,
  memory-array backend emission, or dynamic storage depth behavior.

## Acceptance Criteria

- Actor-owned storage `(bank NAME (width W) (depth CONST))` declarations parse
  and lower when `CONST` names an actor-local constant whose resolved value is
  positive.
- Accepted actor-constant bank depths lower exactly like equivalent positive
  literal depths in public parser handoff, deterministic scalarized storage
  family generation, scheduled `.fsm`, schedule reports, bank access metadata,
  and generated HDL.
- Zero-valued, unknown, runtime-signal, expression-valued, and aggregate-like
  depth sources remain fail-closed with targeted diagnostics. Existing
  actor-parameter bank widths/depths and actor-constant bank widths keep their
  shipped behavior.
- The ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, and live docs stay synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS`
  Status: `done`
  Goal: `Ship actor-constant-backed actor-owned bank storage depths.`
  Children: `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.1`,
  `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.2`

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.1`
  Status: `done`
  Goal: `Select bank storage actor-constant depths.`
  Acceptance: `Create the active task tree, record the actor-constant source
  boundary, preserve non-goals, and update roadmap/live docs without behavior
  changes.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `d143eebe`

- ID: `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.2`
  Status: `done`
  Goal: `Implement and document actor-constant bank storage depths.`
  Acceptance: `Positive actor constants lower as actor-owned bank storage
  depths; unsupported depth sources fail closed; specs, book, public
  contract, downstream handoff, and focused tests are synchronized.`
  Verification: `syntax checks`; `focused bank/public/spec/book tests`;
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `post-closure doc/public audits with Files=6, Tests=348`; `git diff --check`
  Commit: `this commit`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `Actor-constant bank storage depth support is shipped and the tree is closed.` |

## Decisions

- `2026-05-23`: Select actor-owned bank depths as the next actor-constant
  static-dimension slice. This follows the shipped actor-parameter bank-depth
  slice and the shipped actor-constant bank-width slice while keeping dynamic
  storage depth, memory-array backend emission, and generated-top
  respecialization separate.
- `2026-05-23`: Resolve only the owning actor shell's constant value.
  Use-site overrides and generated-top respecialization remain separate policy
  work.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.1` | `mdbook build docs/book`; `git diff --check` | `selection docs passed; no behavior changed` |
| `2026-05-23` | `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.2` | `syntax checks`; `prove -Iperl t/1341-isf-bank-storage-actor-constant-depths.t t/1337-isf-bank-storage-actor-param-depths.t t/1340-isf-bank-storage-actor-constant-widths.t t/1335-isf-bank-storage-actor-param-widths.t t/1236-isf-bank-access-lowering.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1160-isf-public-actor-shell-value-shape-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `post-closure doc/public audits with Files=6, Tests=348`; `git diff --check` | `actor-constant bank storage depths shipped; broad ISF gate passed with Files=247, Tests=1646` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.1` | `d143eebe: ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.1: select bank storage actor-constant depths` | `selects actor-constant bank storage depth support` |
| `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.2` | `this commit: ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.2: ship bank storage actor-constant depths` | `ships actor-constant bank storage depth support` |

## Changelog

- `2026-05-23`: Created task tree and selected actor-constant-backed
  actor-owned bank storage depths as the next bounded static-dimension slice.
- `2026-05-23`: Shipped actor-constant-backed actor-owned bank storage depths,
  synchronized specs/book/public contract/downstream handoff/live docs, and
  closed the task tree.
