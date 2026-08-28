# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2`
  (`active`; exact repair push and hosted requalification)
- next_action: resume and complete the RAM-guarded pre-push regression on the
  committed repair revision, then perform the authorized exceptional push.
- in_flight_uncommitted: none after `.3.2.2.4` commits; its trace-v2 dependent
  truth is the exact pre-push candidate.
- in_flight_background: none; the interrupted t303 parent is uncredited.
- blockers: none.
