# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `HOSTED-VIAL-REGRESSION-GATE-RESULT.28`
- next_action: Repair the blanket local Yosys skip under `HOSTED-VIAL-REGRESSION-GATE-RESULT.28`, with pure environment controls and focused local qualification at the unchanged tool limit.
  HIAL capture sequencing remains pending in its `.6.7.2.2.2` leaf; preserve the spent compiler attempt, original workspace and `docs/audits/native-proxy-receipt-capture-20260923/result/` evidence.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: Director sequencing question pending: qualify nested cleanup before startup, or retain the explicit coordinator launch prerequisite. Historical startup/parent qualification and full CI/push remain gated.
