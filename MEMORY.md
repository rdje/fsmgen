# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.4`: close portable VHDL review).
- active_work_unit: HIAL/VIAL `.15.4` is complete; `.15.5` is provider-blocked,
  `.15.6` awaits exact project-local OSVVM materialization, and NEXSIM `.2`
  remains proposed for evidence-driven amendments.
- current_state: decision `0052` and the standalone 365-requirement NEXSIM
  contract make the native typed semantic API authoritative and MCP its bounded
  projection without claiming support. Its durable surfaces are synchronized.
  HIAL/VIAL `.15.4` now closes the 17-artifact provider-free VHDL profile:
  six sources/59 maps/20 static checks, 24 selected mappings, seven review
  stages/checks, and exact inert-legacy/HIAL separation. The profile is emitted
  and structurally reviewed, with visual review and analysis through support
  unclaimed.
- next_action: obtain exact GHDL 6.0.0 for `.15.5` or materialize exact
  repository-local OSVVM 2026.05 for `.15.6`; amend NEXSIM only from concrete input.
- in_flight_uncommitted: none after commit; no background/output residue remains.
- blockers: `.13.3` waits on capability-ready PGEN/NEXSIM handoff/API/MCP
  identities; IASIM is proposed, while live-document `.12` and inventory `.26` are deferred.

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
