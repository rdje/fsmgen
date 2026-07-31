# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.11: activate portable AHB result parity`).
- active_work_unit: parent `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`;
  completed `.10.1`-.10.4 own public source/planning/run, portable-SV
  emission, exact Verilator execution, trace validation, normalized results,
  and atomic publication. Active `.11` owns normalized comparison with the
  handwritten AHB oracle after clean `.10.4` commit `dfe87f536`.
- current_state: decision `0043` and the portable-SystemVerilog contract remain
  unchanged. Public `fsmgen vial capabilities|check|format|plan|run` and the
  closed API ship normal/terse equivalence, all three HIAL review routes,
  deterministic plain-SV emission, exact Verilator 5.046 compile/runtime,
  validated JSONL, normalized result/output manifests, and deterministic
  virtual or atomic repository-local artifacts. Both checked scenarios pass;
  this continuity activation adds no parity report or product behavior.
- next_action: implement `.11` comparison against the handwritten AHB oracle;
  do not infer parity from `.10.4` and do not widen the known-value profile.
- in_flight_uncommitted: none after this activation commit; no background job
  and all repository-local mdBook output is removed exactly.
- blockers: none for `.11` implementation; native UVM/VHDL/mixed-language leaves
  retain exact tool prerequisites. PGEN/ANVIL feedback remains pending for the
  independent live-document `.15`/`.16` leaves and is not a VIAL blocker.

## Durable context

- Decision `0034`: full power underneath, simpler intent above; VIAL is not
  synthesis-bounded and target methodology stays compiler-private.
- Decisions `0036`/`0037`: logical drive/sample/react/check time and closed
  directional type-representation proofs remain backend authority.
- Decision `0039`: source tooling ships through `.10.1`; `.10.2` now ships
  canonical public planning and atomic repository-local/virtual artifacts.
- Direct IAL0 has structural rather than transaction truth, so `.10.2` admits
  transaction-free endpoint/reset fixtures but never infers transaction facts.
- Decision `0043`: Verilator is the first fast known-value runtime profile,
  never the language ceiling or four-state/UVM authority. `.10.3` keeps one
  generated scheduler as semantic authority; `.10.4` now qualifies compile,
  runtime, and normalized results; active `.11` must perform parity explicitly.
- Decision `0041` and the external review packet remain durable for later
  feedback-sensitive containment work. Push only on explicit request (`0005`);
  PNT runs autonomously (`0003`). Consult the Knowledge Map first.
