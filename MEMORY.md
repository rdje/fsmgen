# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.4`
  (`in_progress`; authenticated startup observation)
- next_action: After the observation checkpoint commit, execute sibling `.3.7`
  bounded first-recurrence capture, then verify helper and observed-child cleanup.
- in_flight_uncommitted: documentation checkpoint for the completed unchanged observation.
- in_flight_background: authenticated helper session `session-d6ff2617c99a426db231c3715749ed84`;
  revalidate its native identity before acting on files under
  `.artifacts/logs/fixture-kernel-capture/`.
- blockers: Startup causes remain unknown until the identified native observation;
  observer output will be under `.artifacts/logs/fixture-kernel-observation-20260907/`.
  Startup causes, wire qualification, nested containment, RAM fixture repair,
  complete CI and push remain open; retain configured RAM limits.
