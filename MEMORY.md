# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: `ef719be52` (`SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.3: own resumable matrix proof`).
- active_work_unit: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.3` owns interruption-resumable complete-parent t296 verification.
- current_state: `.1.2.3` now has opt-in atomic state below `.artifacts/t296`,
  bound to a versioned contract and a clean exact HEAD at startup and every
  completion/reuse boundary. Focused t1597 passes 18 fail-closed persistence
  assertions; a dirty-tree integration probe creates no state; the ordinary
  exact t296 worker remains green.
- next_action: commit the checkpoint implementation, create an exact-HEAD
  near-complete integration checkpoint and prove one execute/remaining reuse/
  final removal cycle, then run/resume the complete guarded parent until all
  four cohorts pass before selecting containment adoption.
- in_flight_uncommitted: `.1.2.3` checkpoint implementation, focused test,
  task evidence, and Knowledge Map fact await doctrine gate and commit; no
  background worker exists.
- blockers: complete exact-HEAD integration and full-parent confirmation must
  run from the clean implementation commit. Containment `.26`, HIAL/VIAL
  provider qualification, and NEXSIM external evidence remain independent.

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
