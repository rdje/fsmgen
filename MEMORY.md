# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-ADOPTION.3`; the locally authoritative
  standard and bounded discovery routes are installed.
- next_action: implement and register the bounded claim-record checker with
  positive fixtures and deliberately failing RED controls.
- in_flight_uncommitted: none after the `.2` policy/discovery commit.
- in_flight_background: none
- blockers: none.
