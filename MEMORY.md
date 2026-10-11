# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.5.2.3.1.2` (blocked)
- next_action: Commit any dirty .5.2.3.1.1 preservation gates, then establish fresh safe host headroom before exact remaining original-reader replay under .5.2.3.1.2. Preserve both cutoffs and all first source/programme epochs. Complete checkpoint acceptance must precede ignored-stream recovery .5.2.3.2 and full parent closure .5.2.3.3.
- in_flight_uncommitted: derive with `git status --short`; commit any owned slice before activating its successor.
- in_flight_background: No original reader runs. Both outer guard attempts are terminal 137; missing killed inner terminals are retained non-success, not live jobs. Derive current preservation gates under docs/audits/raw-semantic-acceptance-20261011/checks.json.
- blockers: Knowledge Map collection rollover debt forbids widening its allowance; preserve all unique facts/questions through governed compaction. Historical native EPERM remains P1-open under HIAL .3.2.10; SIP denies the requested probes. No authentication is pending.
  Historical startup/parent qualification and full CI/push remain gated; One discretionary early push is authorized under SEM .69.3; required HIAL/full-CI qualifications still gate it. Normal cadence resumes afterward. Visual mdBook QA remains pending.
