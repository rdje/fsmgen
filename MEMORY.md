# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.15.2`: ship portable VHDL semantics).
- active_work_unit: `.15`/`.15.3` are active after completed `.15.2`; `.13.3` remains provider-blocked.
- current_state: native UVM emits 16 artifacts/ten SV sources, 75 maps, 14
  checks, a 25-row matrix, and a deterministic gallery. Experimental Verilator
  5.046/UVM evidence passes its control through runtime and fixture preprocessing;
  ranged SVA is unsupported, blackboxing faults internally, and fixture runtime/
  result/parity remain not run. The illegal `context` identifier is repaired.
  Product support stays emission-only. Decision `0051` selects provider-free
  VHDL-2008, exact GHDL 6.0.0, and OSVVM 2026.05 for the advanced tier; UVVM
  is unselected. `.15.2` emits 14 artifacts/six sources, 52 maps, 13 checks,
  typed drivers/samplers, one scheduler, exact ranks, bounded scenarios/fibers,
  deterministic models, a declared-probe adapter, and unexecuted tool records.
  The inert legacy package is unchanged; no VHDL runtime/result/support claim ships.
- next_action: commit the evolving NEXSIM API/MCP consumer-requirements
  task/document, then resume `.15.3` portable VHDL checking/results/closed trace.
- in_flight_uncommitted: none after this commit; no background job remains and
  all repository-local verification output is removed.
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
