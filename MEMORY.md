# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.4`
  (`blocked`; administrator-assisted targeted startup sampling)
- next_action: Obtain administrator-assisted native kernel sampling for an identified
  fixture-startup recurrence under the owning node's bounded capture contract.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Native live kernel sampling requires administrator authentication;
  non-interactive sudo cannot authenticate. Evidence and exact capture scope:
  owning task and its retained native capability/calibration evidence.
  Startup causes, wire qualification, nested containment, RAM fixture repair,
  complete CI and push remain open; retain configured RAM limits.
