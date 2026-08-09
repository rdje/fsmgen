# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.28: activate derived-state containment`).
- active_work_unit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.28` is active.
- current_state: the complete supported-smoke matrix is durable at
  `b8df21eda`; the clean tree now owns derived-state containment separately
  from deferred legacy inventory `.26`. The adoption guide is explicitly the
  canonical downstream entry point for every portable doctrine update.
- next_action: read PGEN's `docs/DERIVED_STATE_CONTAINMENT.md` read-only,
  reconcile each proposal against FSMGen doctrine and live surfaces, then
  implement the neutral rule, focused fail-closed checks, local audit, and
  doctrine/guide/mdBook/decision/fact synchronization under `.28`.
- in_flight_uncommitted: only `.28` activation continuity before its commit;
  no background job or build residue.
- blockers: none for `.28`; containment `.12` still waits on director-deferred
  `.26`, while HIAL/VIAL provider qualification and NEXSIM external evidence
  remain independent.

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
