# ISF-GENERATED-NAME-POLICY: Generated Name Stability Policy

## Metadata

- Tree ID: `ISF-GENERATED-NAME-POLICY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-16`
- Last updated: `2026-05-16`
- Owner: repo-local workflow

## Goal

Define the downstream-visible generated-name stability policy for ISF schedule
reports and generated artifacts.

## Non-Goals

- Do not change generated names, generated `.fsm`, schedule JSON payloads, or
  HDL output.
- Do not freeze the whole schedule JSON schema.
- Do not expose raw lowering IR internals as public API.

## Acceptance Criteria

- ISF spec, downstream handoff, public interface contract doc, and mdBook state
  that generated names are deterministic for a given source and FSMGen version
  but are not semantic APIs to parse.
- The docs state that downstream consumers should use explicit report fields
  such as owner, role, kind, instance, and binding summaries instead of
  reverse-engineering generated name grammar.
- Schedule-report freeze blockers remove generated-name policy as an open
  decision while keeping unrelated blockers intact.
- mdBook and diff hygiene validation pass.
- Live docs, task tree, changes, and development notes are synchronized.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-GENERATED-NAME-POLICY`
  Status: `done`
  Goal: `Define generated-name stability for downstream schedule-report consumers.`
  Children: `ISF-GENERATED-NAME-POLICY.1`

- ID: `ISF-GENERATED-NAME-POLICY.1`
  Status: `done`
  Goal: `Document generated-name stability policy.`
  Acceptance: `Generated-name policy is explicit in the spec, downstream handoff, public contract doc, and book, and the freeze-blocker list is updated.`
  Verification: `mdBook build and diff hygiene passed.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-GENERATED-NAME-POLICY.1` | `done` | Completed; tree closed. |

## Decisions

- `2026-05-16`: Generated names are deterministic report-local/artifact-local
  identifiers for a given source and FSMGen version. They can be used where
  reports explicitly reference them, but downstream tools must not parse name
  grammar as the semantic contract.

## Open Questions

- None.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-16` | `ISF-GENERATED-NAME-POLICY.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-GENERATED-NAME-POLICY.1` | `ISF-GENERATED-NAME-POLICY.1: document generated name stability` | `pending commit` |

## Changelog

- `2026-05-16`: Created task tree and opened the first documentation leaf.
- `2026-05-16`: Completed the first leaf and closed the tree.
