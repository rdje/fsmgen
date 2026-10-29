# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.3.2.1`
- next_action: Implement the separate bounded source bitwise tree schema and current Core holder. Preserve binary two-slot APIs, actual typed order/duplicates, revocation, plain profiles and detached ownership; Parser/backend/target/range integration follow their recorded leaves.
- in_flight_uncommitted: None after the source-holder selection commits; derive paths with git status --short.
- in_flight_background: None.
- blockers: No blocker to source-owned n-ary selection. Required feature/full/publication qualification and owned backend repairs remain open.
