# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only — decisions `0067` and `0068`. Evidence: `docs/tasks/`.
Read `README.md` and `MEMORY_ARCHITECTURE.md`; decisions: `docs/decisions/`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.3.5.2`
- next_action: Atomically consume source-tree/computed-source-binary intent in live declarations and guard rank, then compare an independent complete-target proof with every emitted ledger field before returning HDL.
- in_flight_uncommitted: None after the normal commit workflow; derive paths with git status --short.
- in_flight_background: None.
- blockers: No technical blocker to source-tree range consumption. Unsized literal width refusal remains owned by .3.4.3.2.3.4.4.1 after this source family. Required feature/full/publication qualification and owned backend repairs remain open.
