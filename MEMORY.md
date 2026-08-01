# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3:
  activate retained-ledger schema`).
- active_work_unit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3` is active for
  the common retained-ledger, sealed-range, and archive-descriptor schema.
- current_state: decision `0046` retains bounded `CHANGES.md` and conditional
  `DEVELOPMENT_NOTES.md` ledgers, and selects exact archival plus live-path
  retirement for both frozen status files. Decision `0025` remains the
  operational transition rule until migration.
- next_action: implement and prove `.3`'s neutral schema, core validation, and
  fail-closed fixtures without migrating `CHANGES.md`, `DEVELOPMENT_NOTES.md`,
  or either frozen status file.
- in_flight_uncommitted: none after this commit; no background job and all
  repository-local mdBook output is removed exactly.
- blockers: none for active `.3`; `.4`, `.5`, and `.11` await its schema.

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
  Push only on request (`0005`); PNT runs autonomously (`0003`).
