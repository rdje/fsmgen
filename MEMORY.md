# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.3.5.1`
- next_action: Prepare separate private source and complete-target proof for computed source binary helper roots, then resume atomic tree/binary range emission and final closure.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None.
- blockers: No technical blocker to source-tree range consumption. Unsized literal width refusal remains owned by .3.4.3.2.3.4.4.1 after this source family. Required feature/full/publication qualification and owned backend repairs remain open.
