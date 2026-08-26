# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.2.1` (`active`; checkpointed t296 recovery)
- next_action: commit the exact host-pressure recovery activation, then restart
  `t/296` under the unchanged RAM guard with its exact-revision repository-local
  checkpoint enabled; current host memory reports 76% free.
- in_flight_uncommitted: `.3.2.1` recovery activation documentation only.
- in_flight_background: none
- blockers: none; no FSMGEN process is stranded, host headroom has returned,
  and checkpointed recovery is owned.
