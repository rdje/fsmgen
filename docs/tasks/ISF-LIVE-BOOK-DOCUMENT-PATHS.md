# ISF-LIVE-BOOK-DOCUMENT-PATHS: ISF Public Book Document Paths

## Metadata

- Tree ID: `ISF-LIVE-BOOK-DOCUMENT-PATHS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Make the public ISF live-document contract advertise the complete mdBook ISF
chapter set that documents shipped user-visible ISF behavior, so downstream
consumers can discover the same book surface users review.

## Non-Goals

- Do not change ISF source syntax, lowering, schedule-report payload shapes,
  generated `.fsm`, or HDL output.
- Do not freeze every mdBook page as a stable API schema; the contract only
  advertises the current live documentation paths.
- Do not broaden non-ISF documentation contracts in this tree.

## Acceptance Criteria

- `FSM::Support::ISFPublicInterfaceContract` advertises every ISF mdBook
  chapter listed under the Intent Scheduling section of
  `docs/book/src/SUMMARY.md`.
- The contract also advertises the canonical book backlog and reference map
  because they explain public ISF deferrals and navigation.
- Focused tests prove the direct contract and manifest views stay synchronized
  and that the advertised book paths cannot drift from the mdBook summary.
- The ISF spec, downstream handoff, public contract doc, task index, README,
  roadmap status, live docs, and mdBook stay truthful.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-LIVE-BOOK-DOCUMENT-PATHS`
  Status: `done`
  Goal: `Advertise and audit the complete ISF mdBook live-document surface.`
  Children: `ISF-LIVE-BOOK-DOCUMENT-PATHS.1`

- ID: `ISF-LIVE-BOOK-DOCUMENT-PATHS.1`
  Status: `done`
  Goal: `Advertise complete ISF mdBook chapter paths in the public live-document contract.`
  Acceptance: `The public contract live_document_paths list contains the ISF mdBook chapter set from SUMMARY plus the backlog and reference map, and a focused audit prevents drift.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1303-isf-public-live-book-paths-audit.t`; `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1120-isf-public-live-document-path-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check`
  Commit: `ISF-LIVE-BOOK-DOCUMENT-PATHS.1: advertise ISF book live docs`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-LIVE-BOOK-DOCUMENT-PATHS.1` | `done` | The public contract now advertises the full ISF mdBook chapter set and the audit prevents summary/manifest drift. |

## Decisions

- `2026-05-16`: Treat mdBook chapter discovery as public ISF contract metadata.
  The contract is still a live-document pointer list, not a promise that
  documentation prose has schema stability.
- `2026-05-16`: Derive the audited ISF child-page expectation from
  `docs/book/src/SUMMARY.md` so future ISF book pages cannot be added to the
  book without also being discoverable through the public ISF contract.

## Open Questions

- None for the current leaf.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-LIVE-BOOK-DOCUMENT-PATHS.1` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1303-isf-public-live-book-paths-audit.t`; `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1120-isf-public-live-document-path-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `passed; ISF gate Files=209, Tests=722` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-LIVE-BOOK-DOCUMENT-PATHS.1` | `ISF-LIVE-BOOK-DOCUMENT-PATHS.1: advertise ISF book live docs` | Public contract metadata and audit slice. |

## Changelog

- `2026-05-16`: Created task tree and selected the first live-book-path
  contract synchronization leaf.
- `2026-05-16`: Advertised the complete ISF mdBook chapter set, feature
  backlog, and reference map through `live_document_paths`; added a
  summary-derived audit; closed the tree.
