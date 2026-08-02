# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.14`: activate VHDL verification contract).
- active_work_unit: `.14` alone is active after clean completed-probe
  predecessor `adc88817e`; `.13.3` remains provider-blocked.
- current_state: `sv_uvm_emit.accellera_2020_3_1` emits 16 artifacts/ten SV
  sources covering the selected native structures, with 75 mapped entries, 14
  structural checks, a 25-row matrix, and deterministic gallery. Experimental
  Verilator 5.046/UVM-2020.3.1-vlt evidence passes library/control preprocess
  through runtime plus fixture preprocessing; ranged SVA is unsupported,
  blackboxing reaches a tool internal fault, and fixture runtime/result/parity
  remain not run. Illegal generated identifier `context` is now `vial_context`.
  Product support stays emission-only. `.14` activation selects no VHDL
  methodology, tool, version, migration, artifact, or capability.
- next_action: complete only `.14` documentation selection: audit the existing
  inert VHDL package and exact current provider/tool evidence, then freeze the
  VHDL-2008 portable/methodology/qualification/migration/non-claim contract.
- in_flight_uncommitted: none after this commit; no background job remains and
  all repository-local verification output is removed.
- blockers: `.13.3` still waits on exact capability-ready PGEN/NEXSIM handoff/
  API/MCP identities; IASIM remains proposed. Live-document `.12` and inventory
  `.26` are deferred.

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
  layers and cannot alter VIAL meaning. Exact emitter identity owns byte
  determinism; neutral syntax/strategy may evolve. Commercial simulators remain optional comparisons.
- Decisions `0041`/`0042`/`0044`/`0045` retain containment authority. Retired views
  remain Git-retrievable under `0048`/`0049`; `.5`/`.8`/`.9`/`.10`/`.13` bound the live layers. Push only on request (`0005`); PNT is autonomous (`0003`).
