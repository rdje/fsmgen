# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1: own disabled trace repair`).
- active_work_unit: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1` owns the isolated t296 backend-memory repair.
- current_state: guarded stage probes localize entry 114's real memory cliff to
  `trace_fsm_signal_inventory`: it eagerly Data::Dumper-serializes every
  driving AST before disabled level-3 messages are rejected. The same
  1,158-helper consolidation stays near 124 MiB when only that trace is
  bypassed; parsing, semantic construction, flattening, prescan, and
  factorization are bounded.
- next_action: gate expensive inventory construction on enabled level-3
  tracing, add disabled/enabled trace-contract regression coverage, then prove
  isolated entry 114 and the complete t296 parent below the unchanged limits.
- in_flight_uncommitted: none after this commit; no background job or build residue.
- blockers: no decision blocker for `.1.2.1`; complete t296 awaits its repair.
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
