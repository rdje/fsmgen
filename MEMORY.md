# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. This file is only the
bounded current-state pointer. Git preserves its prior history.

## Resume

- latest_commit: this task-scoped commit,
  `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1: audit interconnect selector overlap`;
  predecessor `70eeeab70`.
- active_work_unit:
  `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.1`.
- current_state: audit `.1` is complete. Fresh assertion-enabled base runs at
  mapped addresses zero and two both fail first on `HADDR_REGS`; metadata maps
  five conflicting one-window outputs and seven two-window outputs. Generated
  `AhbInterconnect` IAL0 owns the defect; generic assertions stay unchanged.
- next_action: from this clean audit commit, activate proposed `.2` and freeze
  the exact mutually exclusive generated-IAL0 repair contract and gates before
  implementation.
- in_flight_uncommitted: none after this commit; no background job remains.
- blockers: none. The fixed guard correctly refused work at 97.3% during an
  unrelated external compiler and later admitted all audit commands at
  65.6%-85.5%; never raise the cutoff or kill unrelated processes.

## Durable context

- Director authorization (`2026-07-29`): keep the four legacy blobs frozen,
  complete the same-volume adoption tree, then resume roadmap PNT.
- The IAL2 frontier is complete through `.812`; exact-three generic child `.3`
  established `321/362/45`, `.5` ships its matching alias at `322/363/46`, and
  completed parent `.813` selected the AHB interconnect arbitration audit;
  child `.1` is complete and proposed `.2` is the next clean-boundary contract
  owner. Decision `0020` remains proposed/inactive.
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
