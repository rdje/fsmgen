# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. This file is only the
bounded current-state pointer. Git preserves its prior history.

## Resume

- latest_commit: this task-scoped commit,
  `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.3: ship generic exact-three BUSY`;
  predecessor `08b6e4208`.
- active_work_unit:
  `IAL2-AHB-REQUESTER-EXACT-THREE-BUSY-INSERTION-READINESS-AUDIT.3`.
- current_state: `.3` ships the generic exact-three requester at 321/362/45,
  with bounded literals `2..3`, unchanged width-two lowering, direct
  `3 -> 2 -> 1 -> 0` runtime, and normalized semantic/read-only MCP parity;
  pending `.4` separately owns matching `.ahb` alias contract selection.
- next_action: after this commit is clean, activate `.4` through task/index/
  Memory only; do not add the alias during activation.
- in_flight_uncommitted: none after this commit; no background job remains.
- blockers: none. Guarded runtime can be stopped
  by the already-tracked macOS metric/external host pressure; never raise the
  cutoff or kill unrelated processes.

## Durable context

- Director authorization (`2026-07-29`): keep the four legacy blobs frozen,
  complete the same-volume adoption tree, then resume roadmap PNT.
- The IAL2 frontier is complete through `.812`; exact-three generic child `.3`
  now ships at `321/362/45`, and pending `.4` is the next activation frontier.
  Decision `0020` remains proposed/inactive.
- Proposed startup-alignment owners remain:
  `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH`,
  `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC`, and
  `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC`.
- Other proposed owners remain indexed in `docs/TASK_TREE.md`, including
  priority enforcement, AHB interconnect arbitration, nested assertion
  precedence, t/1436 failures, mdBook rustdoc fences, and guard metric repair.
- Task-tree live truth is the node list + `docs/TASK_TREE.md` + git (decision
  `0019`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
- Push only on explicit request (decision `0005`). PNT runs autonomously without
  mid-flow pauses (decision `0003`). Heavy commands use the unchanged RAM guard.
- Legacy blobs remain frozen by decision `0007`.
