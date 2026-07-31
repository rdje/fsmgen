# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10: decompose portable SV implementation`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.10.1`; parent
  `.10` is decomposed and the source-tooling child is active alone.
- current_state: decision `0043` and the portable-SystemVerilog contract remain
  unchanged. `.10.1` owns capabilities/check/normal-terse formatting; `.10.2`
  owns canonical planning and artifact transactions, `.10.3` owns portable SV
  emission/trace projection, and `.10.4` owns exact Verilator run/results.
- next_action: implement only bounded `.10.1` with fresh acceptance evidence;
  `.11` retains handwritten-AHB parity and every native backend stays separate.
- in_flight_uncommitted: none after this commit; no background job and all
  repository-local mdBook output is removed exactly.
- blockers: none for active `.10.1`; native UVM/VHDL/mixed-language leaves retain exact
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
