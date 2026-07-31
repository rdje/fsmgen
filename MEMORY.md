# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit
  (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.9: activate portable SV backend contract`).
- active_work_unit: `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE`; `.8` is
  complete as contract selection and `.9` is active continuity-only.
- current_state: decision `0039` selects `fsmgen vial`, equivalent normal/
  terse projections, separate VIAL/HIAL inputs, portable request/result hosts,
  atomic repository-local artifacts, and manifest compatibility. It ships no
  command, parser widening, file, backend, or runtime.
- next_action: select the exact `sv_portable_verilator` backend/runtime-library
  contract in active `.9`, without implementation.
- in_flight_uncommitted: none after this commit; no background job and
  repository-local mdBook output is removed exactly.
- blockers: none for `.9`. Proposed `CAPABILITY-MANIFEST-VERIFICATION-OUTPUTS-
  PRESENCE-MAP-SYNC.1` separately owns pre-existing t370 discovery-map drift.

## Durable context

- `.7.3` ships a private immutable, defensive, no-file ExecutionIR/plan from
  checked VIAL SemanticIR plus the review-routed HIAL bridge. No public
  embedding API, backend, simulator runtime, result, or parity capability ships.
- The checked AHB plan has 21 operations, four fibers, three maximum
  simultaneous fibers, ten directional relations, 22 bindings, two scalar
  state cells, scoreboard capacity four, and two coverage bins.
- Version 1 admits exact bit-domain identity plus drive-only known-value and
  enum-encoding injection. Inverse X/Z collapse, width/sign changes, implicit
  enum decode, and broader coercion fail before plan construction.
- Events bind through logical transaction-adapter inputs and opaque adapter
  state; randomness uses arbitrary-width SHA-256 counter/rejection selection
  with strict replay. Raw actor storage/HDL spelling never enters ExecutionIR.
- Result-manifest/parity schemas remain selected future `.10`/`.11` contracts,
  not satisfied `.7.3` capabilities.
- Decisions `0034`-`0037` own VIAL expressiveness, the private review-routed
  bridge, deterministic logical-time execution, and directional type proofs.
- Decision `0039` owns public VIAL source views, command/API, HIAL input route,
  artifact/report/discovery/diagnostic/compatibility boundaries; `.10` is the
  first implementation owner after active `.9` selects the backend contract.
- Decision `0038` owns README policy authority, template independence,
  duplicate proof, derived 275-line/12,288-byte caps, and unconditional guard.
- Decisions `0025` freezes legacy status files. Push only on explicit request
  (`0005`); PNT runs autonomously (`0003`). Consult the Knowledge Map first.
