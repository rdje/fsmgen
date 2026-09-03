# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.5.5.1`
  (`done`; clean handoff boundary before human publication)
- next_action: From the committed clean `.17.5.5.1` handoff, activate
  `.17.5.5.2` and publish exact human-facing commands, profile/environment
  envelopes, applicability, cleanup, supported scope, and nonclaims.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
