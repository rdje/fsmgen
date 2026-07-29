# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. This file is only the
bounded current-state pointer. Git preserves its prior history.

## Resume

- latest_commit: this task-scoped audit commit,
  `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION.1: audit endpoint selector ownership`;
  predecessor `7c74c9200`.
- active_work_unit: none after this commit; audit `.1` is done.
- current_state: `.1` independently reproduces and maps the generated endpoint
  output overlaps, keeps generic assertions authoritative, and selects
  proposed generated-local contract `.2`; no shipped behavior changed.
- next_action: from the clean audit commit, activate contract-selection leaf
  `.2` without starting implementation.
- in_flight_uncommitted: none after this commit; no background job remains.
- blockers: none. The director authorized canonical macOS host-max 100 plus
  the correct 4096-MiB descendant cap. Report capacity with the exact
  Stats-compatible Mach formula and safety with kernel pressure state
  separately; never use the faulty guard percentage or inactive-cache
  approximation as RAM usage.

## Durable context

- Director authorization (`2026-07-29`): keep the four legacy blobs frozen,
  complete the same-volume adoption tree, then resume roadmap PNT.
- The IAL2 frontier is complete through `.812`; exact-three generic child `.3`
  established `321/362/45`, `.5` ships its matching alias at `322/363/46`, and
  completed parent `.813` selected the AHB interconnect arbitration audit;
  child `.1`-.3 tree is complete and parent selector `.814` selected the
  subordinate arbitration tree. Its audit `.1` selects proposed generated
  endpoint contract `.2`. The distinct direct IAL0 seed override gap is parked
  under proposed `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION`; decision
  `0020` remains proposed/inactive.
- Proposed startup-alignment owners remain:
  `BIN-FSMGEN-IMPORT-TREE-JUL29-REFRESH`,
  `MDBOOK-VHDL-INTRODUCTION-BOUNDARY-SYNC`, and
  `TASK-TREE-FROZEN-LEGACY-DOC-WORKFLOW-SYNC`.
- Other proposed owners remain indexed in `docs/TASK_TREE.md`, including
  priority enforcement, direct AHB seed arbitration, end-to-end big-design
  scalability, nested assertion precedence, t/1436 failures, mdBook rustdoc
  fences, and guard metric repair. Parked findings do not pivot active AHB
  priority.
- Task-tree live truth is the node list + `docs/TASK_TREE.md` + git (decision
  `0019`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
- Push only on explicit request (decision `0005`). PNT runs autonomously without
  mid-flow pauses (decision `0003`). Heavy commands use the unchanged RAM guard.
- Legacy blobs remain frozen by decision `0007`.
