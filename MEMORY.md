# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: `b76c5f63e` (`SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.2: preserve parsed RHS liveness`).
- active_work_unit: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.3` owns interruption-resumable complete-parent t296 verification.
- current_state: `.1.2.2` is complete: guarded pipeline entries 11-14 pass,
  exact pipeline index 116 passes in 660 seconds, and its exact CLI fixture
  passes in 699 seconds below the unchanged cap. A 194-minute parent run had
  completed all 287 default-pipeline entries and default-CLI through index 199
  without assertion failure when unrelated host pressure crossed 88%.
- next_action: commit `.1.2.3` task ownership, implement fail-closed atomic
  checkpointing below `.artifacts/t296`, then resume the complete guarded
  parent until all four cohorts pass before selecting containment adoption.
- in_flight_uncommitted: task-tree-only `.1.2.3` activation; no code change or
  background worker exists.
- blockers: the monolithic parent lacks durable exact-commit progress across
  host-pressure interruptions. Containment `.26`, HIAL/VIAL provider
  qualification, and NEXSIM external evidence remain independently blocked.

## Durable context
- Decision `0034`: full power underneath, simpler intent above; VIAL is not
  synthesis-bounded and target methodology stays compiler-private.
- Decisions `0036`/`0037`: logical drive/sample/react/check time and closed
  directional type-representation proofs remain backend authority.
- Decision `0039`: `.10.1`/`.10.2` ship source tooling and atomic planning;
  transaction-free direct IAL0 never infers transaction facts.
- Decision `0043`: Verilator is the first fast known-value runtime profile,
  never the language ceiling or four-state/UVM authority. `.10.3` keeps one
  generated scheduler as semantic authority; `.10.4` now qualifies compile,
  runtime, and normalized results; `.11` now qualifies only the selected AHB
  handwritten-oracle comparison, not general cross-backend parity.
- Decision `0050`: canonical native output is simulator-neutral Accellera UVM;
  provider-specific requirements stay in isolated adapter/command/evidence
  layers and cannot alter VIAL meaning; commercial simulators remain optional.
- Decision `0051`: portable VHDL is provider-free IEEE 1076-2008; OSVVM is the
  selected advanced provider and GHDL 6.0.0 is the first exact tool profile.
  Provider/tool behavior cannot redefine logical time, values, or results.
- `.15.1-.15.4` own unblocked portable emission/review; `.15.5-.15.7` own GHDL/OSVVM qualification.
- Decisions `0041`/`0042`/`0044`/`0045` retain containment authority; retired views are Git-retrievable. Push only on request; PNT is autonomous.
