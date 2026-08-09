# MEMORY — resume pointer (layer A; overwrite-only, keep ≤ ~60 lines)

See `MEMORY_ARCHITECTURE.md` for the four-layer system. Git preserves prior
history; this file carries only the current bounded resume state.

## Resume

- latest_commit: this commit (`SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.3: close complete resumable matrix`).
- active_work_unit: none; the supported-smoke PPIF pipeline/CLI oracle-split tree is complete.
- current_state: exact-revision checkpointing at `c990583ac` preserved all
  progress across four RAM-guard interruptions and the final guarded t296
  parent passed all 762 batches (`Files=1, Tests=10`, `Result: PASS`). The
  checkpoint auto-cleared, exact run-owned scratch paths are absent, and no
  coverage or resource cutoff was weakened.
- next_action: from the clean tree, add and activate the smallest honest
  `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION` leaf for derived-state containment;
  use `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md` as the canonical
  downstream entry point and read PGEN's `docs/DERIVED_STATE_CONTAINMENT.md`
  read-only as the proposed source before changing the doctrine.
- in_flight_uncommitted: none after this commit; no background job or build residue.
- blockers: none for supported-smoke. Containment `.26`, HIAL/VIAL provider
  qualification, and NEXSIM external evidence remain independent.

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
  layers and cannot alter VIAL meaning; commercial simulators remain optional.
- Decision `0051`: portable VHDL is provider-free IEEE 1076-2008; OSVVM is the
  selected advanced provider and GHDL 6.0.0 is the first exact tool profile.
  Provider/tool behavior cannot redefine logical time, values, or results.
- `.15.1-.15.4` own unblocked portable emission/review; `.15.5-.15.7` own GHDL/OSVVM qualification.
- Decisions `0041`/`0042`/`0044`/`0045` retain containment authority; retired views are Git-retrievable. Push only on request; PNT is autonomous.
