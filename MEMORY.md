# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.2` (`active`; repaired hosted requalification awaits the standing push cadence)
- next_action: on the clean completion commit, activate
  `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.5` for immutable
  portable-Verilator measurement-matrix publication and independent reload.
- in_flight_uncommitted: none; exact-run consumption is complete and commit-owned.
- in_flight_background: none; regression 33023589424, Pages 33023589417, and
  Knowledge Map 33023589413 are terminal.
- blockers: none; both hosted failure roots have committed repairs, and their
  next hosted requalification remains deferred to the standing push cadence.
