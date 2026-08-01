# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.13.1.2`:
  ship complete native UVM structures).
- active_work_unit: parent `.13.1` remains active; `.13.1.2` is complete and
  proposed `.13.1.3` is the next clean activation/implementation frontier.
- current_state: private profile `sv_uvm_emit.accellera_2020_3_1` emits an
  exact eleven-artifact/seven-source graph with selected passive topology,
  lifecycle, ordered typed notification/interception, 42 mapped symbols, ten
  structural checks, and six byte-checked gallery sources. Manual review and parse
  through runtime/results/parity remain unclaimed; `.13.2` is separately
  dependency-ready and `.13.3` retains future PGEN+NEXSIM qualification.
- next_action: from this clean implementation commit, durably route the
  director's NEXSIM deep-semantic-introspection API/MCP clarification into its
  `.13.3`/IASIM differential-qualification owners, then separately activate
  `.13.1.3` for stimulus/TLM/factory/configuration/RAL/constrained decisions.
- in_flight_uncommitted: none after this commit; no background job remains and
  all repository-local verification output is removed.
- blockers: `.13.3` waits on capability-ready PGEN/NEXSIM releases and handoff;
  NEXSIM's API/MCP semantic identity/snapshot/control contract needs clean
  follow-on routing. Live-document `.12` and inventory `.26` are deferred.

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
- Decisions `0041`/`0042`/`0044`/`0045` retain containment authority. Retired
  views remain Git-retrievable under `0048`/`0049`; `.5`/`.8`/`.9`/`.10`/`.13`
  bound the live layers. Push only on request (`0005`); PNT is autonomous
  (`0003`).
