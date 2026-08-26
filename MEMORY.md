# MEMORY — pointer to the frontier (layer A; state only, overwrite-only)

Pointer only, nothing else — decisions `0067` and `0068`. Rationale: `docs/decisions/`.
Status and evidence: `docs/tasks/`. The system itself: `MEMORY_ARCHITECTURE.md`.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `DARWIN-INLINE-VERILATOR-RUNTIME-QUALIFICATION.3.1` (`active`; bound the t1545 fixture checker pre-main failure)
- next_action: migrate/verify/delete the exact off-volume t1545 stack sample,
  audit its command surface, then implement and hostile-test one bounded
  shell-free fixture supervisor before resuming complete CI at `t/1545`.
- in_flight_uncommitted: `.3.1` activation/task evidence only.
- in_flight_background: none
- blockers: complete CI is retained green/skipped through `t/1544`; `t/1545`
  exposed an unbounded `/usr/bin/env bash` pre-main failure owned by `.3.1`.
