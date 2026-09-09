# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.5.3.2` (`pending`)
- next_action: Recheck .3.1's admitted helper, then execute the fixed Rust daemon sequence once.
- in_flight_uncommitted: none.
- in_flight_background: .3.1's authenticated helper is live; campaign must consume and stop it.
- blockers: Startup/containment and parent qualification remain open; full CI/push gated.
