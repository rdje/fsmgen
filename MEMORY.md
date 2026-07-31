# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9: select portable SV backend contract`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`; `.9` is
  complete and no implementation leaf is active across this commit boundary.
- current_state: decision `0043` and the portable-SystemVerilog contract select
  static non-UVM SV lowering, inactive-edge deterministic scheduling, declared-
  probe adapters, exact source maps/artifacts, a closed JSONL trace/result
  boundary, and exact Verilator 5.046 gates. The profile is explicitly known-
  value/two-state and cannot imply full four-state SV, UVM, parity, or scale.
- next_action: from this clean commit, activate proposed `.10` alone for the
  bounded public-tool/plain-SV/result implementation; `.11` retains parity.
- in_flight_uncommitted: none after this commit; no background job and all
  repository-local mdBook output is removed exactly.
- blockers: none for `.10`; native UVM/VHDL/mixed-language leaves retain exact
  tool prerequisites. PGEN/ANVIL feedback remains pending for the independent
  live-document `.15`/`.16` leaves and is not a VIAL blocker.

## Durable context

- Decision `0034`: full power underneath, simpler intent above; VIAL is not
  synthesis-bounded and target methodology stays compiler-private.
- Decisions `0036`/`0037`: logical drive/sample/react/check time and closed
  directional type-representation proofs remain backend authority.
- Decision `0039`: `fsmgen vial` public tooling and atomic repository-local
  artifacts are selected but unimplemented until `.10`.
- Decision `0043`: Verilator is the first fast known-value runtime profile,
  never the language ceiling or four-state/UVM authority.
- Decision `0041` and the external review packet remain durable for later
  feedback-sensitive containment work. Push only on explicit request (`0005`);
  PNT runs autonomously (`0003`). Consult the Knowledge Map first.
