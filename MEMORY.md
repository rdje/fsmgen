# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.1: ship public VIAL source tooling`).
- active_work_unit: parent `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10`;
  completed `.10.1` ships the bounded public VIAL source-tooling boundary.
- current_state: decision `0043` and the portable-SystemVerilog contract remain
  unchanged. Public `fsmgen vial capabilities|check|format` and the closed
  source-only API now ship normal/terse equivalence with no writes. Proposed
  `.10.2` owns canonical planning and artifact transactions, `.10.3` portable
  SV emission/trace projection, and `.10.4` exact Verilator run/results.
- next_action: from this clean commit, separately activate only `.10.2`; `.11`
  retains handwritten-AHB parity and every native backend stays separate.
- in_flight_uncommitted: none after this commit; no background job and all
  repository-local mdBook output is removed exactly.
- blockers: none for `.10.2` activation; native UVM/VHDL/mixed-language leaves
  retain exact tool prerequisites. PGEN/ANVIL feedback remains pending for the
  independent live-document `.15`/`.16` leaves and is not a VIAL blocker.

## Durable context

- Decision `0034`: full power underneath, simpler intent above; VIAL is not
  synthesis-bounded and target methodology stays compiler-private.
- Decisions `0036`/`0037`: logical drive/sample/react/check time and closed
  directional type-representation proofs remain backend authority.
- Decision `0039`: source-only `fsmgen vial` tooling now ships through `.10.1`;
  atomic repository-local planning/artifacts remain selected for `.10.2`.
- Decision `0043`: Verilator is the first fast known-value runtime profile,
  never the language ceiling or four-state/UVM authority.
- Decision `0041` and the external review packet remain durable for later
  feedback-sensitive containment work. Push only on explicit request (`0005`);
  PNT runs autonomously (`0003`). Consult the Knowledge Map first.
