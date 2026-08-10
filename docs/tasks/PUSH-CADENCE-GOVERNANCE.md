# PUSH-CADENCE-GOVERNANCE: Push Cadence Governance

## Metadata

- Tree ID: `PUSH-CADENCE-GOVERNANCE`
- Status: `done`
- Roadmap lane: `infra/continuity`
- Created: `2026-08-10`
- Last updated: `2026-08-10`
- Owner: repo-local workflow

## Goal

Make the director-selected 200-commit push cadence exact, durable, and
recoverable without weakening per-slice local commit discipline.

## Non-Goals

- Change the one-commit-per-completed-slice workflow.
- Push every commit or introduce a shorter automatic push interval.
- Change the active HIAL/VIAL implementation frontier.

## Acceptance Criteria

- A new decision record supersedes decision `0005` and records the normal
  200-commit cadence plus the director-authorized early-push exception.
- `COMMIT.md`, as the normative workflow source, defines how the count is
  derived, when a push occurs, and when the counter resets.
- `MEMORY.md` removes the superseded instruction, derives live push state, and
  preserves the active HIAL/VIAL resume pointer.
- `scripts/check_task_tree_integrity.pl` and `scripts/check_doctrines.sh` pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `PUSH-CADENCE-GOVERNANCE`
  Status: `done`
  Goal: `Make the 200-commit normal push cadence durable and exact.`
  Children: `PUSH-CADENCE-GOVERNANCE.1`

- ID: `PUSH-CADENCE-GOVERNANCE.1`
  Status: `done`
  Goal: `Supersede push-on-request policy and codify the 200-commit cadence.`
  Acceptance: `Decision, normative workflow, and bounded resume state agree on the cadence and pass governance gates.`
  Verification: `PASS — task-tree integrity, Knowledge Map, live-document containment, and all repository doctrines on 2026-08-10.`
  Commit: `PUSH-CADENCE-GOVERNANCE.1: codify 200-commit push cadence`

## Decisions

- `2026-08-10`: The normal cadence is one push after 200 accumulated local
  commits; the director may explicitly authorize an earlier push without
  changing that standing cadence.
- `2026-08-10`: Derive the count from Git's upstream relation; keep no shadow.

## Open Questions

- None.

## Blockers

- None.

## Acceptance Checklist (enforced for implementation changes)

This is a documentation-only governance slice and is exempt from the staged
implementation checklist.
