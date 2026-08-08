# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1: own disabled trace repair`).
- active_work_unit: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.2` owns the remaining t296 index-116 backend CPU bound.
- current_state: `.1.2.1` makes disabled consolidated inventory tracing
  zero-cost before module/AST traversal. Focused t1596 passes six assertions,
  both Perl files are syntax clean, and formerly failing pipeline index 114
  passes all three assertions in 28 seconds below the unchanged cap. The full
  parent progressed to index 116, whose exact 2,013,530-byte generated FSM is
  memory-bounded near 425 MiB but CPU-bound inside direct SystemVerilog backend
  emission; parsing and semantic/IR construction finish in about 16.4 seconds.
- next_action: isolate index 116's exact direct-backend phase, repair its CPU
  scaling without changing generated HDL, then resume the complete guarded
  t296 parent matrix.
- in_flight_uncommitted: `.1.2.1` source/test/docs are being committed; one
  guarded full-t296 parent remains active at index 116 for `.1.2.2` evidence.
- blockers: no decision blocker; `.1.2.2` must resolve the index-116 backend
  CPU hotspot before complete-parent acceptance can close.
  Containment `.26`, HIAL/VIAL provider qualification, and NEXSIM external
  evidence remain independently blocked.

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
