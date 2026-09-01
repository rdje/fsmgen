# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4.7`
  (`active`; runtime-stream cap hardening under decisions `0093`/`0083`)
- next_action: audit and close GHDL lifecycle-authority, selected tool-version,
  and provider-settings object binding in `.17.4.7`.
- in_flight_uncommitted: none; portable-SV terminal admission is closed and the
  next bounded runtime-envelope slice is selected.
- in_flight_background: none; all exact-SHA hosted workflows are terminal green.
- blockers: none; immutable `.17.3` evidence is the selection input.
