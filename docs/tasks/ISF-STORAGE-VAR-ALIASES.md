# ISF-STORAGE-VAR-ALIASES: Actor Storage Variable Aliases

## Metadata

- Tree ID: `ISF-STORAGE-VAR-ALIASES`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Let authors declare actor-owned scalar storage with the ISF vocabulary
`(var name (width N))` or `(variable name (width N))` as aliases for the
existing `(state name (width N))` form.

## Non-Goals

- Do not rename the normalized parser/lowerer storage kind in this slice.
  Aliases normalize to the existing `state` storage kind so downstream
  scheduler/report paths do not fork.
- Do not change `(bank ...)` storage semantics or add memory-array backend
  emission.
- Do not add dynamic or parameter-derived storage widths/depths.

## Acceptance Criteria

- `(storage (var name (width N)))` and
  `(storage (variable name (width N)))` parse successfully.
- Both aliases lower to the same scheduled `.fsm`, schedule report, and HDL
  behavior as scalar `(state ...)` storage.
- Unsupported storage words such as `(register ...)` still fail closed with a
  targeted diagnostic listing the accepted scalar and bank forms.
- The mdBook, ISF spec, roadmap, task tree, and live docs describe the
  canonical user-facing vocabulary.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-STORAGE-VAR-ALIASES`
  Status: `done`
  Goal: `Ship var/variable aliases for actor-owned scalar storage.`
  Children: `ISF-STORAGE-VAR-ALIASES.1`

- ID: `ISF-STORAGE-VAR-ALIASES.1`
  Status: `done`
  Goal: `Parse, lower, document, and test scalar storage aliases.`
  Acceptance: `Parser accepts var/variable aliases, normalizes them to state storage, keeps register rejected, and accepted aliases reach scheduled .fsm, report, and HDL generation.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl t/1232-isf-actor-storage-declarations.t`; `perl t/1192-isf-singleton-actor-clause-boundary.t`; `perl t/1112-isf-public-interface-contract.t`; `perl t/1148-isf-public-storage-metadata-audit.t`; `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-STORAGE-VAR-ALIASES.1: accept scalar storage aliases`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-STORAGE-VAR-ALIASES.1` | `done` | It replaces the HDL-ish scalar storage spelling with the requested variable-oriented authoring vocabulary while preserving existing lowering. |

## Decisions

- `2026-05-15`: Treat `var` and `variable` as source aliases for scalar
  actor-owned storage, normalized to the existing internal `state` kind. This
  keeps the public schedule report and lowerer behavior stable while improving
  authoring vocabulary.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-STORAGE-VAR-ALIASES.1` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl t/1232-isf-actor-storage-declarations.t`; `perl t/1192-isf-singleton-actor-clause-boundary.t`; `perl t/1112-isf-public-interface-contract.t`; `perl t/1148-isf-public-storage-metadata-audit.t`; `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-STORAGE-VAR-ALIASES.1` | `ISF-STORAGE-VAR-ALIASES.1: accept scalar storage aliases` | Parser aliases, public contract text, task tree, live docs, mdBook, and focused/broad gates synchronized. |

## Changelog

- `2026-05-15`: Created task tree and started the first alias implementation leaf.
- `2026-05-15`: Completed `ISF-STORAGE-VAR-ALIASES.1` by accepting
  `(var ...)` and `(variable ...)` scalar storage aliases, keeping
  `(state ...)` accepted, and preserving fail-closed `(register ...)`
  diagnostics.
