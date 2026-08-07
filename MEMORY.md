# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`POST-EVOLUTION-AUDIT-ORACLE-SYNC.1: activate audit-oracle synchronization`).
- active_work_unit: `POST-EVOLUTION-AUDIT-ORACLE-SYNC.1` is active.
- current_state: import-map refresh commit `6a489464d` is complete; a dedicated
  two-leaf tree now owns the pre-existing support-status and partitioned-book
  audit-oracle defects.
- next_action: add the two shipped private UVM/VHDL status values to `t/350`,
  retain all existing contract-shape assertions, verify, and commit `.1`.
- in_flight_uncommitted: none after this commit; no background job or build residue.
- blockers: none for the oracle repairs; HIAL/VIAL `.15.5`/`.15.6` remain
  provider-blocked and NEXSIM `.2` awaits concrete input.

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
