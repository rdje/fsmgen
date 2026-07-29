# IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Two-Subordinate Exact-Three Paired AHB BUSY Readiness

## Metadata

- Tree ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `proposed`
- Roadmap lane: `IAL2 / AHB paired requester-subordinate BUSY composition`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Determine whether the shipped exact-three requester can compose directly with
both shipped HBURST-aware byte-lane BUSY-parking subordinates and the shipped
two-window AHB fabric, with every generated selector assertion enabled, before
any public two-subordinate exact-three source or contract is selected.

## Non-Goals

- Do not add a public source, `.ahb` alias, support entry, focused test,
  checked-in testbench, or generated artifact during the readiness audit.
- Do not infer assertion-enabled two-command runtime from strict checking,
  semantic export, HDL verification, one-window exact-three runtime, or
  two-window exact-two runtime; execute the combined boundary directly.
- Do not select counts above three, generalized count width,
  runtime/policy/random/multiple-point BUSY insertion, distinct local
  bus-BUSY status, wider/indefinite bursts, optional AHB signals, generic
  rule/transaction priority, another protocol/backend, or VHDL behavior.
- Do not activate HIAL/VIAL or decision `0020` from this tree.

## Acceptance Criteria

- The audit starts only after parent selector `.819` commits cleanly and this
  tree's `.1` leaf is activated in a separate no-behavior commit.
- A repository-derived same-volume disposable candidate uses future generic
  path
  `ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif`,
  intent
  `ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park`,
  the matching source object and bounded anchor, top `ahb_tb`, requester
  `amba_requester_busy_insert_three`, status/control BUSY-parking
  subordinates, and `ahb_interconnect`.
- Strict check succeeds with zero diagnostics, four children and 29 signals;
  schedule lowering emits exactly four IAL1 and five IAL0 review artifacts;
  requester `before_beat=2`/`beats=3`, both subordinate and propagated
  `parks_on=[busy]`, and one-hot accepted-subordinate response ownership are
  preserved.
- Normalized semantic JSON and the real read-only, shell-disabled
  `fsmgen_semantic_introspect` route agree on module `ahb_tb`, semantic root
  `top`, four children, and unmatched disposable support accounting.
- Generated SystemVerilog compiles and verifies without disabling selector
  assertions, then an adapted two-command runtime proves exactly 10 transfer
  presentations, 8 completed data beats, 2 BUSY episodes, 6 qualified BUSY
  events, 2 resumed `SEQ` events, status storage `32'h44332211`, and control
  storage `32'h88776655`, including stable selected/unselected endpoint and
  fabric ownership through every BUSY event.
- If direct readiness is proved, the audit freezes projected support identity
  `intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park`,
  coverage
  `ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli`,
  source kind `ppif`, supported-smoke plus strict status, module `ahb_tb`, root
  `top`, four-child expectations, and projected 325 protocol / 366
  supported+strict / 49 AHB paths split 25 `.ppif` / 24 `.ahb` before a
  separate contract leaf.
- Existing one-/two-window exact-two generic/profile behavior, one-window
  exact-three generic/profile behavior, direct/generated arbitration repairs,
  reports, diagnostics, semantic/MCP APIs, and generated artifacts remain
  unchanged and retain their focused owners.
- Focused validation, mdBook, Knowledge Map, continuity, doctrine, exact
  Stats-compatible RAM, separate kernel pressure, same-volume census, cleanup,
  rollback, and implementation handoff are recorded before completion.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
  Status: `proposed`
  Goal: `Audit assertion-enabled two-window exact-three requester/BUSY-parking composition before public expansion.`
  Children: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `proposed`
  Goal: `Audit generic two-subordinate exact-three paired AHB BUSY readiness and select the next exact owner.`
  Acceptance: `Activate only after clean parent selector .819 commit. Reconcile the shipped exact-three requester and one-window generic/profile paired behavior, generic/profile two-window exact-two paired behavior, assertion-clean interconnect/generated-subordinate/direct-seed repairs, public PPIF/AHB generators, report residue, support/language/capability surfaces, normalized semantic JSON, real read-only MCP, t1525/t1526/t1531/t1532, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, decisions 0004/0008/0020, and the .819 disposable static/HDL evidence. Recreate only a repository-derived same-volume generic candidate with the exact future identity, four children, 29 signals, 4 IAL1/5 IAL0 artifacts, requester before_beat=2/beats=3, both child and propagated parks_on=[busy], one-hot ownership, normalized semantic/MCP parity, and unmatched support. Compile without --no-assert and execute an adapted two-command runtime proving 10 presentations/8 beats/2 BUSY episodes/6 qualified BUSY events/2 resumed SEQ/status 0x44332211/control 0x88776655 with stable selected/unselected endpoint and fabric state. Decide whether a separate generic public-contract leaf can follow, a lower-layer repair is required, or the candidate must fail closed. If ready, freeze projected 325/366/49 split 25 .ppif/24 .ahb and exact future support/test/diagnostic/preservation/cleanup/rollback boundaries. Keep aliases, counts above three, new BUSY policy/status/burst/signal semantics, generic priority, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, and decision 0020 separate. Use authorized host100/process4096, canonical Stats-compatible capacity, separate kernel pressure, repository-local artifacts, exact census, and residue proof.`
  Verification: `Pending activation after the clean .819 selector commit.`
  Commit: `pending activation`

## Current Frontier

This tree is proposed and inactive. Parent selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.819` selects `.1` as the next exact owner;
a separate clean activation commit is required before the audit runs.

## Decisions

- `2026-07-29`: Parent selector `.819` selects the readiness audit, not direct
  implementation. Static lowering, semantic export, and HDL verification pass,
  but the combined two-window exact-three assertion-enabled runtime remains an
  independent correctness obligation.
- `2026-07-29`: Keep HIAL/VIAL proposed with portable-fast Verilator separated
  from full-language/SystemVerilog-UVM authority; the smaller adjacent IAL2
  audit does not change that architecture requirement.

## Open Questions

- Whether exact-three retirement stays independently stable across both mapped
  commands while selected and unselected subordinate state and fabric owner
  retention remain assertion-clean. Leaf `.1` owns the direct answer.

## Blockers

- None before activation.

## Rollback

Before activation, rollback removes only this proposed tree and the `.819`
selector record/fact. After activation, retain any assertion-enabled failing
reproducer until a separate exact repair or fail-closed contract owns it.
