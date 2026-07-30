# IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Two-Subordinate Exact-Four Paired AHB BUSY Readiness

## Metadata

- Tree ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `proposed`
- Roadmap lane: `IAL2 / AHB paired requester-subordinate BUSY composition`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Determine whether the shipped exact-four requester composes directly with both
shipped HBURST-aware byte-lane BUSY-parking subordinates and the shipped
two-window AHB fabric, with every generated selector assertion enabled, before
any public two-subordinate exact-four source or contract is selected.

## Non-Goals

- Do not add a public source, `.ahb` alias, support entry, focused test,
  checked-in testbench, or generated artifact during readiness audit `.1`.
- Do not infer assertion-enabled two-command runtime from strict checking,
  semantic export, HDL verification, one-window exact-four runtime, or
  two-window exact-three runtime; execute the combined boundary directly.
- Do not select counts above four, generalized count width, runtime/policy/
  random/multiple-point BUSY insertion, distinct local bus-BUSY status, wider
  or indefinite bursts, optional AHB signals, generic rule/transaction
  priority, another protocol/backend, HIAL/VIAL, VHDL, verification
  generation, scalability implementation, or decision `0020` behavior.

## Acceptance Criteria

- Audit `.1` starts only after parent selector `.826` commits cleanly and this
  tree is activated in a separate no-behavior commit.
- A repository-derived same-volume disposable candidate uses future generic
  path
  `ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif`,
  its matching intent/source object/bounded anchor, top `ahb_tb`, requester
  `amba_requester_busy_insert_four`, status/control BUSY-parking subordinates,
  and `ahb_interconnect`.
- Strict check succeeds with zero diagnostics, four children, and 29 signals;
  lowering emits exactly four IAL1 and five IAL0 review artifacts; requester
  width-three `4 -> 3 -> 2 -> 1 -> 0`, `before_beat=2`/`beats=4`, both child
  and propagated `parks_on=[busy]`, two status/control windows, one-hot
  accepted-subordinate response ownership, and no duplicate top `busy_flow`
  are preserved.
- Normalized semantic JSON and real repo-relative, read-only, shell-disabled
  `fsmgen_semantic_introspect` agree on module `ahb_tb`, semantic root `top`,
  four children, and unmatched disposable support accounting.
- Generated SystemVerilog compiles and verifies without disabling selector
  assertions, then an adapted two-command runtime proves exactly 10 transfer
  presentations, 8 completed data beats, 2 BUSY episodes, 8 qualified BUSY
  events, 2 resumed `SEQ` events, status `32'h44332211`, and control
  `32'h88776655`, including stable selected/unselected endpoint and fabric
  ownership through every BUSY event.
- If direct readiness is proved, audit `.1` may select a separate generic
  public-contract leaf with projected support identity
  `intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park`,
  coverage
  `ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli`,
  source kind `ppif`, supported-smoke plus strict status, module `ahb_tb`, root
  `top`, four-child expectations, and 331 protocol / 372 supported+strict / 55
  AHB paths split 28 `.ppif` / 27 `.ahb`.
- Existing one-/two-window exact-one through exact-three generic/profile
  behavior, one-window exact-four generic/profile behavior, assertion repairs,
  reports, diagnostics, semantic/MCP APIs, and generated artifacts remain
  unchanged.
- Focused validation, mdBook, Knowledge Map, continuity, doctrine, canonical
  Stats-compatible RAM, separate kernel pressure, same-volume census, cleanup,
  rollback, and implementation handoff are recorded before completion.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
  Status: `proposed`
  Goal: `Audit assertion-enabled two-window exact-four requester/BUSY-parking composition before public expansion.`
  Children: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `pending`
  Goal: `Audit generic two-subordinate exact-four paired AHB BUSY readiness and select the next exact owner.`
  Acceptance: `Activate only after clean parent selector .826 commit. Reconcile the shipped exact-four requester and one-window generic/profile paired behavior, generic/profile two-window exact-three paired behavior, assertion-clean interconnect/generated-subordinate/direct-seed repairs, public generators, report residue, support/language/capability surfaces, normalized semantic JSON, real read-only MCP, t1533/t1534/t1537/t1538, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, scale, and decisions 0004/0008/0020. Recreate only the repository-derived same-volume generic candidate with exact future identity, four children, 29 signals, 4 IAL1/5 IAL0 artifacts, width-three requester load four, before_beat=2/beats=4, both child/propagated parks_on=[busy], two windows, one-hot ownership, no top busy_flow, normalized semantic/MCP parity, and unmatched support. Compile with selector assertions enabled and execute an adapted two-command runtime proving 10 presentations/8 beats/2 BUSY episodes/8 qualified BUSY events/2 resumed SEQ/status 0x44332211/control 0x88776655 with stable selected/unselected endpoint and fabric state. Decide whether a separate generic contract can follow, a lower-layer repair is required, or the candidate must fail closed. If ready, freeze projected 331/372/55 split 28 .ppif/27 .ahb and exact future support/test/diagnostic/preservation/cleanup/rollback boundaries. Keep aliases, counts above four, new BUSY policy/status/burst/signal semantics, generic priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, scale implementation, and decision 0020 separate. Use authorized host100/process4096, canonical Stats-compatible capacity, separate kernel pressure, repository-local artifacts, exact census, and residue proof.`
  Verification: `Pending clean activation after parent selector .826 commits.`
  Commit: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1: audit two-window exact-four AHB readiness`

## Dependencies

- `IAL2-FEATURE-COMPLETENESS-FRONTIER.826`
- `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION`
- `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION`
- `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION`
- decisions `0004`, `0008`, and `0020`

## Rollback

Before public implementation, rollback removes this proposed tree and its
selection pointers only. Any later contract or implementation leaf must define
its own exact rollback surface.
