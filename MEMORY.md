# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5.2.2.1` (`active`; repair exact-capture preflight dispatch)
- next_action: route validation and preflight modes through `validate_profile`,
  add a real-adapter dispatcher regression, and verify the focused matrix seam.
- in_flight_uncommitted: exact failure evidence is retained; repair leaf awaits commit.
- in_flight_background: none; regression 33023589424, Pages 33023589417, and
  Knowledge Map 33023589413 are terminal.
- blockers: none; the profile-4 dispatch defect is locally reproducible and owned.
