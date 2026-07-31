# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6: enforce bounded task-tree history`).
- active_work_unit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`; `.6` is complete
  and no implementation leaf is active across this commit boundary.
- current_state: decision 0042 and the expanded integrity checker support
  finite JSONL manifests, content-addressed exact-source terminal segments,
  and exact version-object compact terminals. Existing trees remain at three /
  882 nodes / zero segments / zero compact terminals; `docs/TASK_TREE.md` is
  below rollover at 89.8% after detailed examples routed to the setup guide.
- next_action: from this clean commit, activate `.7` only to migrate the active
  IAL2 task outlier, completed outliers, and bounded cross-tree index.
- in_flight_uncommitted: none after this commit; no background job and all
  repository-local mdBook output is removed exactly.
- blockers: none for `.7`-.10 or `.13`; `.3`-.5/.11 wait for the separately
  owned four-file lifecycle review, and final `.12` waits for all migrations.

## Durable context

- Decision `0038` owns README policy authority, template independence,
  duplicate proof, derived 275-line/12,288-byte caps, and unconditional guard.
- Decision `0040` adds routed-destination ownership/lifecycle controls and
  pins frozen legacy records; current large ceilings are debt, not defaults.
- Decision `0041` generalizes containment project-wide while keeping its body
  project-neutral, project-agnostic, and harness-neutral. Local 80/90/100
  milestones, JSONL data, immutable baselines, transition allowances, and
  migration paths remain fenced local state.
- Decisions `0025` freezes legacy status files. Push only on explicit request
  (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map first.
