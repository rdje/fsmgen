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
  Children: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`, `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`, `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

- ID: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Audit one-subordinate generic exact-four paired AHB BUSY composition readiness and select the next exact owner.`
  Acceptance: `Activate only after clean parent selector commit IAL2-FEATURE-COMPLETENESS-FRONTIER.823. Reconcile shipped exact-four generic/alias requester behavior and t1535/t1536, exact-three one-window generic/alias composition and t1531/t1532, assertion-clean subordinate/interconnect/direct lower layers, current 328 protocol / 369 supported+strict / 52 AHB paths split 26 .ppif/26 .ahb, PPIF/report/residue/language/capability/semantic/read-only-MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, scalability, and decisions 0004/0008/0020. Recreate only a repository-derived same-volume future generic candidate at ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif with intent ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park, object fsmgen-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park, bounded anchor, top ahb_tb, and children amba_requester_busy_insert_four, ahb_lite_subordinate_byte_lane_hburst_seq, and ahb_interconnect. Require strict/check success with unmatched disposable support, exact 3 IAL1/4 IAL0 artifacts, width-three requester state loaded to four, before_beat=2/beats=4, child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, normalized semantic root top/3 children/28 signals, real read-only shell-disabled MCP, public --verify-hdl, and assertion-enabled runtime 5 presentations/4 beats/1 BUSY episode/4 qualified BUSY events/4->3->2->1->0/1 resumed SEQ/storage 0x44332211. Decide whether a direct data-only public contract can follow or the smallest prerequisite is required. If ready, freeze future support intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park / ial2_ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli / ppif / supported_smoke+strict / ahb_tb / root top / 3 children and projected 329/370/53 split 27 .ppif/26 .ahb, plus diagnostics, preservation, separate alias/two-window cadence, cleanup, rollback, and contract handoff. Keep counts above four, policy/status/burst/signal semantics, generic priority, other protocols/backends, HIAL/VIAL activation, scale implementation, VHDL, verification generation, and decision 0020 separate. Use authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, and remove all disposable outputs without residue. Make no public behavior change in audit.`
  Verification: `Activated only after clean parent selector commit d91c5c7c9 through clean activation commit 53b6612d7. Reconciled exact-four requester generic/alias and t1535/t1536, exact-three paired generic/alias and t1531/t1532, assertion-clean subordinate/interconnect/direct lower layers, current 328/369/52 split 26/26 support/language/capability/semantic-MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, scalability, and decisions. A repository-derived same-volume future generic candidate strict-checks at ahb_tb/3 children/28 signals/zero diagnostics with unmatched support; schedule preserves exact 3 IAL1/4 IAL0 artifacts, width-three requester load four, before_beat=2/beats=4, one-hot accepted-subordinate ownership, child/propagated parks_on=[busy], and no top busy_flow. Normalized semantic schema 1 and real fsmgen_semantic_introspect agree on ahb_tb/root top/3 children/28 signals/unmatched support with read_only=true and shell_access=false. Public --verify-hdl passes. Verilator 5.046 compiles with --timing, -j 1, and all assertions; runtime passes transfers=5/beats=4/BUSY episodes=1/qualified BUSY=4/internal 4->3->2->1->0/resumed SEQ=1/storage=0x44332211 while holding requester/subordinate/fabric state. t1531+t1535+t1536 pass 3 files/13 top-level tests in 459 seconds; t248+t297 pass 2 files/6,983 assertions at unchanged 328/369/52. No lower-layer repair is required. Selected pending `.2` to freeze one generic source/support/test contract projecting 329/370/53 split 27 .ppif/26 .ahb. Alias, two-window exact-four, counts above four, new BUSY policy/status/burst/signal behavior, generic priority, HIAL/VIAL, scale implementation, VHDL, verification generation, and decision 0020 remain separate. The exact 55-file/53,570,345-byte audit workspace was removed without residue; only the 491-byte project-local xcrun_db cache remains. Canonical audit record/fact and continuity layers are synchronized. Focused t1518+t1256+t1414 pass 3 files/22 top-level tests including 66 nested current-AHB assertions. Knowledge Map generation/check passes at 1,039 facts/5,309 keys. mdBook builds exactly 72 files/16,288,180 bytes and the exact render is removed. Memory is 60 lines; diff and all six doctrine gates pass. Canonical Stats-compatible RAM is 74.9% (17.968/24.000 GiB; 19,292,684,288 bytes), kernel pressure is separately 1 (normal), and neither guard occupancy nor inverted memory_pressure free percentage is used as capacity truth. No parser, generator, public source, support, test, checked-in artifact, semantic/MCP API, shipped HDL/runtime, simulator integration, backend, protocol, verification-generation, HIAL/VIAL, VHDL, or transaction behavior changed.`
  Commit: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1: audit exact-four paired AHB readiness`

- ID: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Select the first generic exact-four paired AHB BUSY public contract before implementation.`
  Acceptance: `Activate only after clean .1 audit commit. Read the canonical audit record/fact and exact disposable strict/schedule/artifact/normalized-semantic/real read-only MCP/public-verifier/assertion-runtime evidence; reconcile standalone exact-four requester and exact-three paired generic/alias contracts, RegressionCorpus/language/capability/current-doc surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, scalability, and decisions 0004/0008/0020. Freeze exactly one future generic source ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif with intent ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park, source object fsmgen-ahb-interconnect-requester-busy-insert-four-byte-lane-hburst-seq-busy-park, bounded anchor, embedded requester amba_requester_busy_insert_four, subordinate ahb_lite_subordinate_byte_lane_hburst_seq, fabric ahb_interconnect, top ahb_tb, exact 3 IAL1/4 IAL0 artifacts, width-three 4->3->2->1->0 requester behavior, before_beat=2/beats=4, child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, and no top busy_flow. Select support id intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park, coverage ial2_ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli, ppif/supported_smoke/strict/module ahb_tb/root top/3 children, and projected 329 protocol / 370 supported+strict / 53 AHB paths split 27 .ppif/26 .ahb only if reconfirmed. Freeze future t1537 plus t/data/ahb_exact_four_paired_busy_composition_tb.svt for strict/check/schedule/artifact/verifier/diagnostic/normalized-semantic/real read-only MCP and assertion-enabled 5/4/1/4/1/0x44332211 proof, preservation of t1531/t1535/t1536, docs/KM/resource/same-volume cleanup/rollback, separate implementation leaf, and separate matching alias/two-window cadence. Make no parser, generator, public source, support, test, artifact, semantic/MCP API, HDL/runtime, simulator integration, backend, protocol, HIAL/VIAL, VHDL, verification-generation, or transaction behavior change in contract selection. Keep counts above four, policy/status/burst/signal semantics, generic priority, scale implementation, other protocols/backends, and decision 0020 separate/inactive.`
  Verification: `Activated at clean commit 6cbfb8b25, then froze one additive generic public source ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif with exact intent/object/anchor, existing three-child ahb_tb architecture, exact 3 IAL1/4 IAL0 artifacts, width-three 4->3->2->1->0 requester behavior, before_beat=2/beats=4 reports, child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, and no top busy_flow. Selected support id intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park, coverage ial2_ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli, ppif/supported_smoke/strict/module ahb_tb/root top/3-child expectations, projected 329 protocol / 370 supported+strict / 53 AHB paths split 27 .ppif/26 .ahb, and focused t1537 plus t/data/ahb_exact_four_paired_busy_composition_tb.svt. t1537 must own source/report/artifact/strict/output/verifier/normalized-semantic/real read-only MCP parity and assertion-enabled 5/4/1/4/1/0x44332211 runtime, while current diagnostics and preservation owners remain authoritative. t248+t297 pass 2 files/6,983 assertions at the reconfirmed current 328/369/52 boundary; an initial invocation used nonexistent shorthand test names, then rg --files resolved the exact tracked names and the authoritative invocation passed. Focused t1518+t1256+t1414 pass 3 files/22 top-level tests. Knowledge Map generation/check is synchronized at 1,040 facts/5,314 keys. mdBook builds exactly 72 files/16,292,545 bytes; the exact render is removed without residue, leaving only the pre-existing 491-byte xcrun_db cache under project-local temp. Memory is 59 lines; diff and all six doctrine gates pass. Pre-closeout canonical Stats-compatible RAM is 71.8% (17.242/24.000 GiB; 18,513,608,704 bytes); post-gate capacity is 67.9% (16.303/24.000 GiB; 17,504,862,208 bytes). Kernel pressure is separately 1 (normal) at both readings; guard occupancy and inverted memory_pressure free percentage are excluded as capacity truth. Selected pending `.3` for data-only implementation; no parser/generator algorithm, semantic-MCP API, or simulator integration change is expected. Matching alias, two-subordinate exact-four, broader BUSY/protocol/backend/HIAL-VIAL/VHDL/verification-generation/scale/decision-0020 work remains separate. Contract selection changes no public source/support/test/artifact/API/HDL/runtime behavior.`
  Commit: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2: select exact-four paired AHB contract`

- ID: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`
  Status: `active`
  Goal: `Ship the selected generic one-subordinate exact-four paired AHB BUSY source through existing generators.`
  Acceptance: `Activate only after clean .2 contract commit. Implement exactly the .2 contract: add ppif/ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif as the exact data-only extension of the exact-three paired source, with selected intent/object/anchor, embedded amba_requester_busy_insert_four, busy-before-beat 2, busy-beats 4, existing ahb_lite_subordinate_byte_lane_hburst_seq, ahb_interconnect, ahb_tb, ports/storage/burst/response/window/wiring unchanged. Add RegressionCorpus entry intent.ppif_ahb_interconnect_requester_busy_insert_four_byte_lane_hburst_seq_busy_park with selected coverage, ppif/supported_smoke/strict/module ahb_tb/root top/3-child expectations; update t248/t297 and public support/language/capability/current-doc inventory surfaces to exact 329 protocol / 370 supported+strict / 53 AHB paths split 27 .ppif/26 .ahb. Add t/1537-ial2-ahb-exact-four-paired-busy-composition.t and t/data/ahb_exact_four_paired_busy_composition_tb.svt covering source identities, strict/check success and exact support, schedule schema/3 children/artifacts/one-hot ownership/requester before_beat=2/beats=4/width-three counter/child+propagated parks/no top busy_flow, normalized semantic JSON, real repo-relative fsmgen_semantic_introspect read_only=true/shell_access=false, repo-local output, --verify-hdl, and Verilator 5.046 --timing without --no-assert at exact transfers=5/beats=4/BUSY episodes=1/qualified BUSY=4/resumed SEQ=1/storage=0x44332211 plus 4->3->2->1->0 and stable requester/subordinate/fabric ownership with clean completion. Preserve t1531/t1535/t1536 and existing source/alias bytes; use the smallest warranted focused/broader gates. Add behavior record/fact and sync README, ROADMAP_V2, REGRESSION_CORPUS/support docs, mdBook, task/index, Memory, and Knowledge Map. Use repo-derived same-volume temp/output, authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, exact cleanup census, rollback, and commit. Do not change parser/generator algorithms, existing source bytes, report schema/API, matching .ahb alias, two-subordinate topology, counts above four, policy/status/burst/signal behavior, generic priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, scale implementation, or decision 0020.`
  Verification: `Activated only after clean .2 contract commit d54dc8afb. Activation changes task/index/Memory/roadmap/mdBook/fact continuity only; no parser, generator, public source, support entry, test, testbench, checked-in generated artifact, semantic/MCP API, HDL/runtime, simulator integration, backend, protocol, verification-generation, HIAL/VIAL, scale, VHDL, or transaction behavior changes. Focused t1518+t1256+t1414 pass 3 files/22 top-level tests. Knowledge Map generation/check remains synchronized at 1,040 facts/5,314 keys. mdBook builds exactly 72 files/16,293,829 bytes and its exact repository-local render is removed without residue. Memory remains 59 lines; diff and all six doctrine gates pass. Pre-gate canonical Stats-compatible RAM is 68.5% (16.432/24.000 GiB; 17,644,027,904 bytes); post-gate capacity is 68.2% (16.380/24.000 GiB; 17,587,453,952 bytes). Kernel pressure is separately 1 (normal) at both readings; guard occupancy and inverted memory_pressure free percentage are excluded as capacity truth.`
  Commit: `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3: activate exact-four paired AHB implementation`

## Decisions

- `2026-07-29`: Parent selector `.823` proposes one-subordinate generic
  exact-four paired readiness as the smallest adjacent owner. The 9-file
  feasibility probe strict-checks, lowers, and verifies cleanly, but runtime
  and real MCP evidence remain owned by `.1`.
- `2026-07-29`: Clean parent selector commit `d91c5c7c9` activates `.1`
  without changing public or generated behavior.
- `2026-07-29`: `.1` proves direct assertion-enabled exact-four paired
  readiness and selects pending no-behavior generic contract `.2`.
- `2026-07-29`: Clean audit commit `19772adec1` satisfies the `.2` activation
  boundary; contract selection is active and still changes no behavior.
- `2026-07-29`: Contract `.2` freezes one generic source, support identity,
  t1537 assertion-enabled runtime, and `.3` data-only implementation; aliases
  and the two-subordinate topology remain separately owned.
- `2026-07-29`: Clean contract commit `d54dc8afb` satisfies the `.3` activation
  boundary; implementation is active but no source or behavior changes in
  activation.

## Open Questions

- None for readiness or contract. Pending `.3` owns implementation.

## Blockers

- None.
