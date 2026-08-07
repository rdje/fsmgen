# POST-EVOLUTION-AUDIT-ORACLE-SYNC: Synchronize Post-Evolution Audit Oracles

## Metadata

- Tree ID: `POST-EVOLUTION-AUDIT-ORACLE-SYNC`
- Status: `active`
- Roadmap lane: `test integrity / support contracts and mdBook audits`
- Created: `2026-08-07`
- Last updated: `2026-08-07`
- Owner: repo-local workflow

## Goal

Restore three audit tests whose static discovery vocabularies or document paths
did not follow already-shipped contract-status and Chapter 14 topology changes.

## Non-Goals

- Do not change support-contract semantics, advertised support, or book prose.
- Do not combine the independent status-vocabulary and document-topology fixes
  into one implementation slice.

## Acceptance Criteria

- The support-contract audit accepts every current contract status and still
  rejects undeclared values.
- Feature-backlog and ATL status audits read the canonical partitioned Chapter
  14 pages that own their queried headings.
- Focused audits pass with their existing assertion strength intact.
- Broader documentation, task, path, locality, and doctrine gates pass.
- Each leaf is committed separately through `COMMIT.md`.

## Task Tree

- ID: `POST-EVOLUTION-AUDIT-ORACLE-SYNC`
  Status: `active`
  Goal: `Synchronize static audit oracles with shipped contract and book topology changes.`
  Children: `POST-EVOLUTION-AUDIT-ORACLE-SYNC.1, POST-EVOLUTION-AUDIT-ORACLE-SYNC.2`

- ID: `POST-EVOLUTION-AUDIT-ORACLE-SYNC.1`
  Status: `active`
  Goal: `Synchronize the support-contract audit's allowed status vocabulary.`
  Acceptance: `t/350 accepts all current contract builders without weakening their schema, source, or guidance assertions.`
  Verification: `pending`
  Commit: `pending`

- ID: `POST-EVOLUTION-AUDIT-ORACLE-SYNC.2`
  Status: `pending`
  Goal: `Route feature-backlog and ATL audits to canonical partitioned Chapter 14 pages.`
  Acceptance: `t/1256 and t/1332 locate every governed heading and retain their exact current-status and stale-wording assertions.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-08-07`: The failures are stale test oracles, not product regressions.
  `git log -S` locates the two unrecognized support statuses at commits
  `7725789a4` and `0074b369e`; neither updated `t/350`. Chapter 14 partition
  commit `dc1c64afb` moved the governed headings into topic pages without
  updating `t/1256` or `t/1332`.
- `2026-08-07`: Preserve the existing assertions and repair only their finite
  vocabulary or canonical input path. No user-facing behavior or prose change
  is warranted.

## Blockers

- None.
