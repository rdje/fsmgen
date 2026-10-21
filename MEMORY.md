# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.89`
- next_action: Run and commit the due safe artifact census, then resume preparation-correction metadata repair from the owning task tree.
- in_flight_uncommitted: derive with `git status --short`; commit any owned slice before activating its successor.
- in_flight_background: None; original semantic cohort slots remain unused.
- blockers: Historical native EPERM attribution stays P1-open with HIAL; the SIP boundary is unchanged.
  Knowledge Map rollover debt forbids allowance growth; preserve all facts/questions. No decision or authentication is pending.
  The actual full helper passes AST-input and stops at preparation-correction saved comparison; complete typed diagnosis isolates metadata; repair and native admission precede retry.
  Historical startup/parent qualification and full CI/push remain gated; Push whenever useful is explicitly authorized by user steering on 2026-10-11; required HIAL/full-CI qualifications still gate it. Visual mdBook QA remains pending.
