# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. This file is only the
bounded current-state pointer. Git preserves its prior history.

## Resume

- latest_commit: this task-scoped commit,
  `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2: select mutually exclusive arbitration contract`;
  predecessor `22eb4822a`.
- active_work_unit:
  `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.3` (proposed).
- current_state: `.2` is complete and selects complementary per-window plus
  exclusive global response modes; proposed `.3` owns interconnect
  implementation. Paired `--no-assert` removal is excluded because the
  feasibility probe exposed a separate subordinate idle/phase-capture overlap.
- next_action: after this commit is clean, activate `.3` in a docs-only boundary
  commit, then implement the selected interconnect contract and direct-fabric
  assertion-enabled t1530.
- in_flight_uncommitted: none after this commit; no background job remains.
- blockers: none. The fixed guard refused attempts during unrelated external
  compiler pressure and admitted the definitive endpoint probe at 70.9%; never
  raise the cutoff or kill unrelated processes.

## Durable context

- Director authorization (`2026-07-29`): keep the four legacy blobs frozen,
  complete the same-volume adoption tree, then resume roadmap PNT.
- The IAL2 frontier is complete through `.812`; exact-three generic child `.3`
  established `321/362/45`, `.5` ships its matching alias at `322/363/46`, and
  completed parent `.813` selected the AHB interconnect arbitration audit;
  child `.1` is complete and `.2` selects proposed implementation `.3`. The
  independent subordinate `HRDATA_REGS` overlap is durably routed to proposed
  `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1`. Decision `0020`
  remains proposed/inactive.
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
