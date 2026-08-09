# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- repository_revision: derive the current commit and subject with
  `git log -1 --format='%H %s'`; do not store a shadow of `HEAD` here.
- active_work_unit: `STARTUP-INTEGRITY-REPAIR-AUG09.2`.
- current_state: the full August 9 startup audit found a stale HIAL VHDL hash,
  canonical-wiring cookbook drift, and stale import-map measurements.
- next_action: repair only the stale `t/1551` direct-VHDL SHA-256 lock and
  prove the intentional pre/post output difference; commit `.2` next.
- in_flight_uncommitted: activation docs only; no job or build residue.
- blockers: none; after `.4`, HIAL `.16+` need director/tool selection.

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
- `.15.1-.15.4` ship portable emission/review; `.15.5` qualifies exact GHDL
  6.0.0 LLVM-JIT; `.15.6` ships exact OSVVM materialization/emission; `.15.7`
  qualifies their bounded combined profile with portable semantics unchanged.
- Decisions `0041`/`0042`/`0044`/`0045` retain containment authority; retired views are Git-retrievable. Push only on request; PNT is autonomous.
