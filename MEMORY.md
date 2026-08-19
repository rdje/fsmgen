# MEMORY — resume pointer (layer A; overwrite-only; ≤ 120 lines, ≤ 32,768 bytes)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior history; this file carries only the current bounded resume state.

Decision `0067`: every field below is **state, not narration**, and is capped at 5 lines by
`scripts/check_memory_architecture.sh`. Rationale routes to `docs/decisions/`, lane and leaf
status to `docs/tasks/`. Never summarise a decision or a completed lane here.

## Resume

- repository_revision: derive with `git log -1 --format='%H %s'`; never shadow `HEAD` here.
- active_work_unit: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.3`.
- current_state: `.1`, `.2`, `.4`, and `.5` are done; `.3` is the last open leaf in this tree.
- next_action: run `.3` — sweep every remaining surface for the target-pair defect
  (`enforced_rules`, `engineering_rationale` known) and report each surface's headroom against
  its owned allowance. Then `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2`.
- in_flight_uncommitted: none.
- in_flight_background: none.
- blockers: none.
- push_state: decision `0062` 200-commit cadence; count with
  `git rev-list --count @{upstream}..HEAD`; qualify per `COMMIT.md` after any push.

## Durable context

Cross-cutting rationale is `docs/decisions/INDEX.md` (C); lane status is the owning tree under
`docs/tasks/` (B); query either with `knowledge-map/scripts/query_knowledge_map.sh 'words'`.

Load-bearing for the current frontier only (overwrite, never append):
- `.3`: decisions `0065` target-pair derivation, `0066` resume-pointer criteria.
- `.17.2.4.2`: decisions `0061` sealed binder, `0059` expanded-action cap dominance.
