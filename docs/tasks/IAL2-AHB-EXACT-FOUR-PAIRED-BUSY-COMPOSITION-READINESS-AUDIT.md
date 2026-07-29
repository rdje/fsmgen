# IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Exact-Four Paired AHB BUSY Composition Readiness

## Metadata

- Tree ID: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `active`
- Roadmap lane: `IAL2 / AHB paired requester-subordinate BUSY composition`
- Created: `2026-07-29`
- Last updated: `2026-07-29`
- Owner: repo-local workflow

## Goal

Determine whether the shipped exact-four requester composes directly with the
shipped byte-lane/HBURST-SEQ/BUSY-parking subordinate and one-window AHB
interconnect with every generated selector assertion enabled, before selecting
any new public paired source or behavior.

## Non-Goals

- Do not add the public generic source, matching `.ahb` alias, support entry,
  test, or checked-in generated artifact during readiness audit `.1`.
- Do not select two-subordinate exact-four topology, counts above four,
  runtime/random policy, multiple insertion points, local bus-BUSY status,
  wider bursts, optional signals, generic priority changes, another protocol
  or backend, VHDL, or verification generation in this tree.
- Do not activate HIAL/VIAL or decision 0020 from this tree.

## Acceptance Criteria

- Audit `.1` activates only after clean parent selector `.823` commit.
- A repository-derived same-volume candidate uses future path
  `ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif`
  and existing requester/subordinate/interconnect lowering.
- Strict/check, schedule, exact three IAL1/four IAL0 artifacts, generated HDL,
  normalized semantic JSON, real read-only shell-disabled MCP, public verifier,
  diagnostics, and support-unmatched truth are proven.
- Assertion-enabled runtime proves five presentations, four accepted data
  beats, one BUSY episode, four qualified BUSY events, internal
  `4 -> 3 -> 2 -> 1 -> 0`, one resumed `SEQ`, stable ownership, clean status,
  and final storage `0x44332211`.
- t1535/t1536 standalone exact-four and t1531 exact-three paired behavior are
  preserved.
- If ready, `.1` selects a separate generic contract leaf with exact public
  identities, support/test ownership, projected 329/370/53 split 27/26,
  deferrals, cleanup, rollback, and no behavior in selection.
- Focused/broader validation, mdBook, Knowledge Map, continuity, doctrine,
  canonical RAM, separate kernel pressure, and exact cleanup gates pass.
- Each completed leaf commits through `COMMIT.md`.

## Task Tree

- ID: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
  Status: `active`
  Goal: `Audit assertion-enabled exact-four requester/BUSY-parking-subordinate/fabric composition before public expansion.`
  Children: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`

- ID: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `active`
  Goal: `Audit one-subordinate generic exact-four paired AHB BUSY composition readiness and select the next exact owner.`
  Acceptance: `Activate only after clean parent selector commit IAL2-FEATURE-COMPLETENESS-FRONTIER.823. Reconcile shipped exact-four generic/alias requester behavior and t1535/t1536, exact-three one-window generic/alias composition and t1531/t1532, assertion-clean subordinate/interconnect/direct lower layers, current 328 protocol / 369 supported+strict / 52 AHB paths split 26 .ppif/26 .ahb, PPIF/report/residue/language/capability/semantic/read-only-MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, scalability, and decisions 0004/0008/0020. Recreate only a repository-derived same-volume future generic candidate at ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif with intent ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park, object fsmgen-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park, bounded anchor, top ahb_tb, and children amba_requester_busy_insert_four, ahb_lite_subordinate_byte_lane_hburst_seq, and ahb_interconnect. Require strict/check success with unmatched disposable support, exact 3 IAL1/4 IAL0 artifacts, width-three requester state loaded to four, before_beat=2/beats=4, child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, normalized semantic root top/3 children/28 signals, real read-only shell-disabled MCP, public --verify-hdl, and assertion-enabled runtime 5 presentations/4 beats/1 BUSY episode/4 qualified BUSY events/4->3->2->1->0/1 resumed SEQ/storage 0x44332211. Decide whether a direct data-only public contract can follow or the smallest prerequisite is required. If ready, freeze future support intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park / ial2_ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli / ppif / supported_smoke+strict / ahb_tb / root top / 3 children and projected 329/370/53 split 27 .ppif/26 .ahb, plus diagnostics, preservation, separate alias/two-window cadence, cleanup, rollback, and contract handoff. Keep counts above four, policy/status/burst/signal semantics, generic priority, other protocols/backends, HIAL/VIAL activation, scale implementation, VHDL, verification generation, and decision 0020 separate. Use authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, and remove all disposable outputs without residue. Make no public behavior change in audit.`
  Verification: `Activated only after clean parent selector commit d91c5c7c9. Activation changes task/index/Memory/roadmap/mdBook/selection-fact/HIAL-VIAL continuity state only. Public behavior remains 328 protocol / 369 supported+strict / 52 AHB paths split 26 .ppif/26 .ahb; no exact-four paired source/support/test exists. The selector's 9-file feasibility evidence remains strict/schedule/semantic/artifact/public-verifier proof only; assertion-enabled aggregate runtime and real read-only MCP remain pending in this audit. Focused t1518+t1256+t1414 pass 3 files/22 top-level tests including 66 nested current-AHB assertions. Knowledge Map remains synchronized at 1,038 facts/5,303 keys. mdBook builds exactly 72 files/16,282,945 bytes and the exact render tree is removed. Memory is bounded; diff and all six doctrine gates pass. Canonical Stats-compatible RAM is 63.6% (15.264/24.000 GiB; 16,389,996,544 bytes), kernel pressure is separately 1 (normal), and guard occupancy is excluded from capacity truth. No parser, generator, public source, support, test, artifact, semantic/MCP API, HDL/runtime, simulator, backend, protocol, verification-generation, HIAL/VIAL, VHDL, or transaction behavior changed.`
  Commit: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1: activate exact-four paired audit`

## Decisions

- `2026-07-29`: Parent selector `.823` proposes one-subordinate generic
  exact-four paired readiness as the smallest adjacent owner. The 9-file
  feasibility probe strict-checks, lowers, and verifies cleanly, but runtime
  and real MCP evidence remain owned by `.1`.
- `2026-07-29`: Clean parent selector commit `d91c5c7c9` activates `.1`
  without changing public or generated behavior.

## Open Questions

- Whether assertion-enabled combined runtime and read-only MCP confirm direct
  data-only contract readiness or expose a smaller prerequisite.

## Blockers

- None after clean parent selector commit `d91c5c7c9`.
