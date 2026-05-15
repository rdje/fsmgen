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
`(var name (width N))` or `(variable name (width N))`.

Historical note: this tree originally kept `(state ...)` accepted during the
transition away from HDL-ish storage words. The later
[ISF-STORAGE-VAR-SURFACE](ISF-STORAGE-VAR-SURFACE.md) tree narrowed the
current source surface so `(state ...)` is no longer accepted.

## Non-Goals

- Do not change `(bank ...)` storage semantics.
- Do not change `(bank ...)` storage semantics or add memory-array backend
  emission.
- Do not add dynamic or parameter-derived storage widths/depths.

## Acceptance Criteria

- `(storage (var name (width N)))` and
  `(storage (variable name (width N)))` parse successfully.
- Both aliases lower to scheduled `.fsm`, schedule report, and HDL behavior
  through the actor-owned scalar storage path.
- Unsupported storage words fail closed with a targeted diagnostic listing the
  accepted scalar and bank forms.
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
  Acceptance: `Parser accepts var/variable aliases, keeps unsupported storage heads rejected, and accepted aliases reach scheduled .fsm, report, and HDL generation.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl t/1232-isf-actor-storage-declarations.t`; `perl t/1192-isf-singleton-actor-clause-boundary.t`; `perl t/1112-isf-public-interface-contract.t`; `perl t/1148-isf-public-storage-metadata-audit.t`; `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-STORAGE-VAR-ALIASES.1: accept scalar storage aliases`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-STORAGE-VAR-ALIASES.1` | `done` | It replaces the HDL-ish scalar storage spelling with the requested variable-oriented authoring vocabulary while preserving existing lowering. |

## Decisions

- `2026-05-15`: Treat `var` and `variable` as source aliases for scalar
  actor-owned storage. This keeps the public schedule report and lowerer
  behavior stable while improving authoring vocabulary.
- `2026-05-15`: The later `ISF-STORAGE-VAR-SURFACE` tree removed `(state ...)`
  from the accepted storage source surface.

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
  `(var ...)` and `(variable ...)` scalar storage aliases.
- `2026-05-15`: Current source behavior is owned by
  `ISF-STORAGE-VAR-SURFACE`; `(state ...)` is no longer an accepted storage
  entry head.
