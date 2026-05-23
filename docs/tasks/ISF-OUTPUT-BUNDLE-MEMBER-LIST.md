# ISF-OUTPUT-BUNDLE-MEMBER-LIST: Output Bundle Member List

## Metadata

- Tree ID: `ISF-OUTPUT-BUNDLE-MEMBER-LIST`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Ship explicit `output_bundle` member-list syntax for the already enforced
priority-arbitrated rule-user resource path, so authors and downstream tools
can see which declared output ports the bundle names instead of inferring that
intent only from participating rule assignments.

## Non-Goals

- Do not add output-target users, transaction users, named-drive users, or
  storage-port users.
- Do not add route mux/storage, fan-in/fan-out routing, fairness state,
  hold/release ownership, multi-capacity resources, or `round_robin`
  arbitration.
- Do not accept input ports, internal storage, aggregate paths, pin paths,
  actor-network endpoints, or arbitrary LHS expressions as explicit
  output-bundle members in this tree.
- Do not change the existing rule-DT grant-gating timing for
  `rule_slot` or `output_bundle`.

## Acceptance Criteria

- Resource entries may use `(members output...)` only with
  `(kind output_bundle)`.
- Explicit output-bundle members must be non-empty scalar names, unique, and
  declared actor output ports.
- For an enforced `output_bundle` with members and declared rule users, the
  lowerer fails closed if a bound rule writes a declared output outside the
  member list or if a listed member is not written by any bound rule.
- Successful `output_bundle` arbitration keeps the existing one-cycle
  priority grant model and adds member-list evidence to the bounded schedule
  report/public contract surface.
- Focused parser, lowerer, report, public-contract, spec-index, and book
  audits pass; the broader ISF gate runs when the implementation lands.
- ISF spec, downstream integration handoff, public contract, mdBook,
  roadmap status, task index, MEMORY, CHANGES, DEVELOPMENT_NOTES, and
  LIVE_ACHIEVEMENT_STATUS are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-OUTPUT-BUNDLE-MEMBER-LIST`
  Status: `active`
  Goal: `Add explicit output_bundle member-list syntax and reporting`
  Children: `ISF-OUTPUT-BUNDLE-MEMBER-LIST.1`,
  `ISF-OUTPUT-BUNDLE-MEMBER-LIST.2`

- ID: `ISF-OUTPUT-BUNDLE-MEMBER-LIST.1`
  Status: `done`
  Goal: `Select the bounded output_bundle member-list slice`
  Acceptance: `The roadmap, task index, and live docs identify the active
  slice, document the exact boundary, and confirm no compiler behavior changed`
  Verification: `documentation-only selection review, live-doc audits,
  git diff check`
  Commit: `pending this commit`

- ID: `ISF-OUTPUT-BUNDLE-MEMBER-LIST.2`
  Status: `pending`
  Goal: `Implement output_bundle member-list parsing, validation, reporting,
  and documentation`
  Acceptance: `The parser accepts and validates output_bundle members,
  lowering enforces the selected declared-output boundary for rule users,
  schedule reports expose bounded member evidence, docs are synchronized, and
  focused plus broad checks pass`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-OUTPUT-BUNDLE-MEMBER-LIST.2` | `pending` | Implement the selected bounded feature after the selection leaf is committed. |

## Decisions

- `2026-05-23`: Select explicit output-bundle member lists as the next R14
  resource slice because the previous `output_bundle` enforcement deliberately
  left member syntax deferred.
- `2026-05-23`: Keep the first member-list subset declared-output-only. That
  gives authors a precise reviewable bundle boundary without prematurely
  defining internal-storage ownership, aggregate paths, actor-network endpoint
  routing, output-target users, route mux/storage, or multi-cycle ownership.
- `2026-05-23`: Preserve the existing priority grant timing. Member lists are
  validation and report evidence for the already shipped rule-user
  `output_bundle` grant model; they do not add a new scheduling cycle.

## Open Questions

- None for this bounded slice. Broader member domains and output-target users
  remain explicit backlog.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-MEMBER-LIST.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `passed: Files=2, Tests=25` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-MEMBER-LIST.1` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-OUTPUT-BUNDLE-MEMBER-LIST.1` | `pending this commit: ISF-OUTPUT-BUNDLE-MEMBER-LIST.1: select output bundle members` | `selection slice` |
| `ISF-OUTPUT-BUNDLE-MEMBER-LIST.2` | `pending` | `implementation slice` |

## Changelog

- `2026-05-23`: Created and activated the task tree.
