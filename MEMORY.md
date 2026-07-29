# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. This file is only the
bounded current-state pointer. Git preserves its prior history.

## Resume

- latest_commit: this task-scoped commit,
  `PROJECT-DATA-LOCALITY-SAME-VOLUME-ADOPTION.3: close same-volume adoption`;
  predecessor `017153eac`.
- active_work_unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER` has no selected leaf
  after completed `.811`; same-volume adoption is complete through `.3`.
- current_state: decision 0022 is fully adopted. Runtime/lowering, standard
  tests and gates, tool caches, active public commands, fact reverification,
  Knowledge Map generation, and mdBook guidance use repository-derived local
  storage. The doctrine gate now requires zero active OS-temp paths.
- next_action: resume roadmap PNT from the clean commit: inspect the current
  IAL2 residue/support frontier and select the smallest exact `.812` leaf in
  `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md` before any implementation.
- in_flight_uncommitted: none after this commit; no background job remains.
- blockers: none for task selection. Guarded confirmatory reruns can be stopped
  by the already-tracked macOS metric/external host pressure; never raise the
  cutoff or kill unrelated processes.

## Durable context

- Director authorization (`2026-07-29`): keep the four legacy blobs frozen,
  complete the same-volume adoption tree, then resume roadmap PNT.
- The IAL2 frontier is complete through `.811` at support `320/361/44`; no
  `.812` contract is selected yet. Decision `0020` remains proposed/inactive.
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
