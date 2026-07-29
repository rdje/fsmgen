# IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Exact-Three Paired AHB BUSY Composition Readiness

## Metadata

- Tree ID: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `proposed`
- Roadmap lane: `IAL2 / AHB paired requester-subordinate BUSY composition`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Determine whether the shipped exact-three requester can compose directly with
the shipped byte-lane/HBURST-SEQ/BUSY-parking subordinate and one-window AHB
interconnect, with every generated selector assertion enabled, before any new
public source or behavior is selected.

## Non-Goals

- Do not add a public exact-three paired source, alias, support entry, test, or
  generated artifact during the readiness audit.
- Do not select the two-subordinate topology, `.ahb` aliases, BUSY counts above
  three, runtime/policy/multiple-point insertion, distinct local bus-BUSY
  status, wider or indefinite bursts, optional AHB signals, generic priority
  changes, another protocol/backend, or VHDL behavior in this tree.
- Do not activate HIAL/VIAL or decision 0020 from this tree.

## Acceptance Criteria

- The audit starts only after the parent selector commits cleanly and this
  tree's `.1` leaf is activated in a separate no-behavior commit.
- A repository-derived same-volume disposable candidate composes the existing
  `amba_requester_busy_insert_three`,
  `ahb_lite_subordinate_byte_lane_hburst_seq`, and `ahb_interconnect`
  children under top `ahb_tb` through the public lowering path.
- The candidate is checked strictly, scheduled, lowered to reviewable IAL1 and
  IAL0 artifacts, compiled with every generated selector assertion enabled,
  and run through the exact paired runtime boundary.
- Runtime evidence distinguishes five transfer presentations, four accepted
  data beats, one BUSY episode, three ready-qualified BUSY events, one resumed
  `SEQ`, and final storage `0x44332211`.
- The audit records exact future source/object/anchor/artifact/report/support,
  normalized semantic JSON, read-only MCP, diagnostics, preservation,
  resource, cleanup, rollback, and implementation-handoff boundaries before
  choosing a public contract or behavior change.
- Existing exact-three standalone requester and generic/alias exact-two paired
  one-/two-subordinate behavior remains unchanged and retains its focused
  regression owners.
- Focused validation, mdBook, Knowledge Map, continuity, and doctrine gates
  pass; disposable output is counted and removed with no residue.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
  Status: `proposed`
  Goal: `Audit assertion-enabled exact-three requester/BUSY-parking-subordinate/fabric composition before public expansion.`
  Children: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

- ID: `IAL2-AHB-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `pending`
  Goal: `Audit one-subordinate generic exact-three paired AHB BUSY composition readiness and select the next exact owner.`
  Acceptance: `Activate only after clean parent selector commit IAL2-FEATURE-COMPLETENESS-FRONTIER.816. Reconcile the shipped generic/alias exact-three requester, generic/alias one-/two-subordinate exact-two paired compositions, completed interconnect/generated-subordinate/direct-seed arbitration repairs, public PPIF adapters and AHB generators, report residue, support/language/capability surfaces, normalized semantic JSON, read-only fsmgen_semantic_introspect MCP, focused tests t1520/t1523/t1525/t1528, roadmap, mdBook, Knowledge Map, HIAL/VIAL, and decision 0020. Use only a repository-derived same-volume disposable one-subordinate candidate corresponding to future path ppif/ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif, intent ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, object ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, anchor ahb_interconnect_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_anchor, top ahb_tb, and children amba_requester_busy_insert_three, ahb_lite_subordinate_byte_lane_hburst_seq, and ahb_interconnect. Require strict/check success, exact three IAL1 and four IAL0 review artifacts, assertion-enabled generated HDL, requester report before_beat=2/beats=3, child and propagated parks_on=[busy], one-hot accepted-subordinate ownership, normalized semantic JSON/read-only MCP parity, and runtime 5 presentations/4 beats/1 BUSY episode/3 qualified BUSY events/1 resumed SEQ/storage 0x44332211. Decide whether direct data-only public contract selection can follow, a lower-layer repair is required, or the candidate must fail closed. If ready, freeze projected support accounting 323 protocol / 364 supported+strict / 47 AHB paths split 24 .ppif and 23 .ahb, the exact support id, future focused test owner, diagnostics, preservation, residue, rollback, and separate alias/two-subordinate cadence before behavior changes. Keep counts above three, policy/status/bursts/signals, generic priority, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, and decision 0020 out of scope. Use the director-authorized --host-max-pct 100 --process-max-rss-mb 4096 profile, report exact Stats-compatible capacity separately from kernel pressure, census the disposable workspace, and remove it without residue.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-07-29`: Parent selector `.816` proposes the one-subordinate generic
  readiness audit as the smallest adjacent owner after all audited AHB
  interconnect, generated-endpoint, and direct-seed assertion boundaries became
  clean. This proposal does not activate the tree or change behavior.

## Open Questions

- Whether the disposable exact-three composition proves direct data-only
  implementation readiness or exposes a lower-layer ownership defect. The
  `.1` audit owns the answer and it does not block task-tree creation.

## Blockers

- Parent selector `.816` must commit cleanly before `.1` activation.
