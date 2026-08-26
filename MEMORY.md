# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2` (`active`; due push and hosted qualification)
- next_action: run the selected pre-push locality, mdBook, doctrine, and exact
  complete-CI evidence gates; push the clean qualified revision; then consume
  every expected GitHub workflow and record its terminal URL and conclusion.
- in_flight_uncommitted: none
- in_flight_background: none
- blockers: none; checkpointed t296 and the independently selected lexical tail
  are green, the checkpoint self-cleared, and no FSMGEN process is stranded.
