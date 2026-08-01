# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.12:
  activate native UVM contract selection`).
- active_work_unit: `.12` alone is active from clean commit `ea1b76dd54`.
- current_state: portable Verilator execution and bounded AHB parity remain
  shipped. The local command census finds Verilator and Icarus but no qualified
  UVM simulator; activation creates no UVM revision, backend, or runtime claim.
- next_action: audit the shipped inert UVM 1.2 skeleton, current VIAL contracts,
  available standards/tool evidence, and licensing/CI boundary; then select the
  exact native UVM contract and `sv_uvm_qualified` profile in `.12`.
- in_flight_uncommitted: none after this commit; no background job remains and
  all repository-local verification output is removed.
- blockers: none for active `.13`; `.26` retains the deferred inventory. The
  knowledge-card file ceiling is exactly occupied until `.12` derives budgets,
  so interim facts must supersede/consolidate or obtain explicit authority.

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
  runtime, and normalized results; `.11` now qualifies only the selected AHB
  handwritten-oracle comparison, not general cross-backend parity.
- Decisions `0041`/`0042`/`0044`/`0045` retain containment authority; `.25`
  retires unused WARP and the director resumed containment on `2026-08-01`.
  `.11` retires the former achievement and roadmap-status views under decisions
  `0048`/`0049`. Push only on request (`0005`); PNT runs autonomously (`0003`).
  `.5` bounds the rationale ledger; `.8` completes the Chapter 14 partition;
  `.9` bounds strategic direction and preserves exact chronology; `.10` bounds
  canonical cards and replaces the flat map with checked query-first shards;
  `.13` now bounds the focused/ancillary index and maintained ISF reference;
  clean `ea1b76dd54` activates HIAL/VIAL `.12` contract selection.
