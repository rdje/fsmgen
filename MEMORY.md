# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `CLAIM-VERIFICATION-TEMPLATE-REVIEW.2` (done)
- next_action: Select the next eligible PNT leaf from docs/TASK_TREE.md, first checking the parked mdBook paragraph-spacing audit and its activation boundary.
  HIAL sequencing remains pending; preserve the spent compiler workspace and `docs/audits/native-proxy-receipt-capture-20260923/result/` evidence.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Director sequencing question pending: qualify nested cleanup before startup, or retain the explicit coordinator launch prerequisite. Historical startup/parent qualification and full CI/push remain gated.
