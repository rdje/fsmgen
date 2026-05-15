# ISF-STORAGE-VAR-SURFACE: Actor Storage Source Vocabulary

## Metadata

- Tree ID: `ISF-STORAGE-VAR-SURFACE`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Make actor-owned scalar storage source vocabulary explicit and small:
`(var name (width N))` is canonical, and `(variable name (width N))` is the
verbose alias.

## Non-Goals

- Do not change fixed-depth `(bank ...)` storage semantics.
- Do not rename schedule-report generated storage class values such as
  `kind: register`; those are report/backend classifications, not source
  storage entry words.
- Do not add parameter-derived widths/depths or memory-array backend emission.

## Acceptance Criteria

- Parser accepts `(var name (width N))` and `(variable name (width N))` for
  scalar actor-owned storage.
- Parser rejects `(state ...)` and `(register ...)` storage entries with a
  targeted diagnostic listing only the accepted source words.
- Repo fixtures, tests, ISF spec, mdBook, public contract, roadmap, task-tree
  index, and live docs no longer describe `(state ...)` as accepted source
  vocabulary.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STORAGE-VAR-SURFACE`
  Status: `done`
  Goal: `Keep actor-owned scalar storage source vocabulary to var/variable.`
  Children: `ISF-STORAGE-VAR-SURFACE.1`

- ID: `ISF-STORAGE-VAR-SURFACE.1`
  Status: `done`
  Goal: `Remove state/register from the accepted storage source surface.`
  Acceptance: `Only var/variable/bank storage entries parse; state/register fail closed; fixtures and docs use the narrowed source vocabulary.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl t/1232-isf-actor-storage-declarations.t`; `perl t/1192-isf-singleton-actor-clause-boundary.t`; `perl t/1234-isf-disjoint-rule-writes.t`; `perl t/1235-isf-fifo-same-cycle-update-matrix.t`; `perl t/1236-isf-bank-access-lowering.t`; `perl t/1112-isf-public-interface-contract.t`; `perl t/1239-isf-library-catalog-contract.t`; `perl t/1148-isf-public-storage-metadata-audit.t`; `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-STORAGE-VAR-SURFACE.1: narrow storage source vocabulary`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-STORAGE-VAR-SURFACE.1` | `done` | It aligns the implementation and book with the requested source vocabulary. |

## Decisions

- `2026-05-15`: Keep `(var ...)` as canonical scalar actor-owned storage.
  Keep `(variable ...)` as the verbose alias. Reject `(state ...)` and
  `(register ...)` as storage entry heads.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-STORAGE-VAR-SURFACE.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl t/1232-isf-actor-storage-declarations.t`; `perl t/1192-isf-singleton-actor-clause-boundary.t`; `perl t/1234-isf-disjoint-rule-writes.t`; `perl t/1235-isf-fifo-same-cycle-update-matrix.t`; `perl t/1236-isf-bank-access-lowering.t`; `perl t/1112-isf-public-interface-contract.t`; `perl t/1239-isf-library-catalog-contract.t`; `perl t/1148-isf-public-storage-metadata-audit.t`; `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STORAGE-VAR-SURFACE.1` | `ISF-STORAGE-VAR-SURFACE.1: narrow storage source vocabulary` | Parser, fixtures, public contract, task tree, mdBook, roadmap, and live docs synchronized. |

## Changelog

- `2026-05-15`: Created task tree and started the first source-vocabulary
  narrowing leaf.
- `2026-05-15`: Completed `ISF-STORAGE-VAR-SURFACE.1`; only
  `(var ...)`, `(variable ...)`, and `(bank ...)` storage entries parse.
