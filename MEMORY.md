# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.4: activate Verilator run integration`).
- active_work_unit: parent `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10`;
  completed `.10.1`/`.10.2`/`.10.3` own source tooling, planning/artifacts,
  and private portable-SV emission/trace validation respectively. Active
  `.10.4` owns public publication, Verilator execution, and result production.
- current_state: decision `0043` and the portable-SystemVerilog contract remain
  unchanged. Public `fsmgen vial capabilities|check|format|plan` and the closed
  API now ship normal/terse equivalence, all three canonical HIAL review routes,
  and virtual or atomic repository-local artifacts. Private `.10.3` now emits
  the deterministic eight-artifact portable-SV graph and validates caller-
  supplied closed traces without simulator execution or result production.
  This continuity commit activates `.10.4` without changing product behavior.
- next_action: implement exact public artifact publication, Verilator 5.046
  compile/run, runtime trace capture, and normalized result production under
  active `.10.4`; `.11` retains parity.
- in_flight_uncommitted: none after this activation commit; no background job
  and all repository-local mdBook output is removed exactly.
- blockers: none for `.10.4` implementation; native UVM/VHDL/mixed-language leaves
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
  generated scheduler as semantic authority, separates backend caps from
  target-neutral plan identity, and reports compile/runtime/result/parity as
  unperformed; `.10.4` is now active to implement the first three only.
- Decision `0041` and the external review packet remain durable for later
  feedback-sensitive containment work. Push only on explicit request (`0005`);
  PNT runs autonomously (`0003`). Consult the Knowledge Map first.
