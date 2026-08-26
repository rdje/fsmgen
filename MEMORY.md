# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.1` (`done`; bounded task-acceptance fixture processes)
- next_action: commit the verified `.3.1` implementation from its staged
  acceptance evidence, then activate `.3.2` only from the clean repository and
  resume the authoritative complete-CI suffix at `t/1545`.
- in_flight_uncommitted: `.3.1` implementation, tests, decision, card, book,
  rationale, and completion evidence.
- in_flight_background: none
- blockers: none; retained complete-CI evidence remains green/skipped through
  `t/1544`, and `.3.2` must restart exactly at the repaired `t/1545` frontier.
