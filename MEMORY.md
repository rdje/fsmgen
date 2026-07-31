# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2: activate source semantic IR contract`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.2`
  (active documentation-only `.vial`/`VIALSemanticIR` v1 contract).
- current_state: clean architecture audit commit `2e2f7d25e` selects decision
  `0032`, decomposes `.2`-.18, and activates only `.2` through this separate
  continuity transition; no source/IR contract finding or product behavior
  changes during activation.
- next_action: execute `.2`: select exact `.vial` syntax/topology, types,
  semantic records, ownership/invariants, source maps, parser/report surfaces,
  first bounded fixture, diagnostics/negative boundaries, and `.3` handoff.
- in_flight_uncommitted: none after this activation commit; no background job.
- blockers: none for `.2`; later UVM/VHDL/mixed-language qualification retains
  explicit external-tool prerequisites.

## Durable context

- Decision `0032` is canonical: VIAL uses one public source language, private
  `VIALSemanticIR`/`VIALExecutionIR`, and a bounded versioned HIAL/VIAL bridge;
  it does not mirror HIAL as public VIAL0/VIAL1/VIAL2.
- Plain SystemVerilog/Verilator is first. UVM, VHDL methodology, and mixed-
  language profiles are independently qualified. Existing inert UVM 1.2 and
  VHDL observation outputs remain compatibility surfaces.
- Architecture `.1` closeout: two active trees / 864 nodes; docs
  `Files=3, Tests=40`; 37 mdBook chapters and 73-file / 16,810,633-byte build;
  Knowledge Map 1,085 facts / 5,600 keys; exact output removed.
- `.2` activation closeout: two active trees / 864 nodes; docs
  `Files=3, Tests=40`; 37 chapters and 73-file / 16,812,484-byte build;
  Knowledge Map unchanged at 1,085 / 5,600; Memory 46 lines; output removed.
- IAL2 verification facts still require generated-IAL1 reviewable annotation;
  direct `.ppif` verification output remains unsupported.
- Decisions `0028`-`0031` remain canonical for SourceHIR/IR policy. Public
  builder, whole-product scale, MCP-write, and every director-gated owner
  remain separately proposed/inactive.
- Decision `0025` freezes `ROADMAP_STATUS.md` and
  `LIVE_ACHIEVEMENT_STATUS.md`; update `CHANGES.md` every slice and
  `DEVELOPMENT_NOTES.md` only for durable rationale.
- Push only on explicit request (decision `0005`). PNT runs autonomously
  (decision `0003`). Consult `KNOWLEDGE_MAP.md` before re-deriving durable facts.
