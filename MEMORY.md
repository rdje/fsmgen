# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.1: select one-source dual-IR architecture`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2`
  (proposed source/semantic-IR contract; selected, not yet activated).
- current_state: architecture audit `.1` is complete under decision `0032`;
  one `.vial` source, private `VIALSemanticIR`/`VIALExecutionIR`, the versioned
  HIAL/VIAL bridge, portable/native semantics, result parity, profiles,
  migration, AHB mapping, scale constraints, and leaves `.2`-.18 are selected.
- next_action: after this clean commit, activate only proposed `.2` through a
  separate continuity commit; then execute its exact documentation-only
  `.vial`/`VIALSemanticIR` version-1 contract.
- in_flight_uncommitted: none after this commit; no background job.
- blockers: none for `.2`; later UVM/VHDL/mixed-language qualification retains
  explicit external-tool prerequisites.

## Durable context

- Decision `0032` is canonical: VIAL does not mirror HIAL as public
  VIAL0/VIAL1/VIAL2. Plain SystemVerilog/Verilator is first; UVM, VHDL
  methodology, and mixed-language profiles are independently qualified.
- Existing `uvm_passive_monitor_skeleton` (UVM 1.2) and
  `vhdl_observation_package_skeleton` remain inert compatibility surfaces.
  IAL2 verification facts still require generated-IAL1 reviewable annotation;
  direct `.ppif` verification output remains unsupported.
- Audit closeout: task-tree integrity reports two active trees / 864 nodes;
  docs audits pass at `Files=3, Tests=40`; all 37 mdBook chapters and the
  73-file / 16,810,633-byte HTML build pass; Knowledge Map passes at 1,085
  facts / 5,600 keys; exact repository-local output is removed.
- Decisions `0028`-`0031` remain canonical for SourceHIR/IR policy. Public
  builder, whole-product scale, MCP-write, and every director-gated owner
  remain separately proposed/inactive.
- Decision `0025` freezes `ROADMAP_STATUS.md` and
  `LIVE_ACHIEVEMENT_STATUS.md`; update `CHANGES.md` every slice and
  `DEVELOPMENT_NOTES.md` only for durable engineering rationale.
- The live IAL2 ledger is mechanically protected by the eighth doctrine,
  `TASK-TREE-INTEGRITY`; current `.73`, `.705`, and `.758` repairs remain
  canonical.
- Push only on explicit request (decision `0005`). PNT runs autonomously
  (decision `0003`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
