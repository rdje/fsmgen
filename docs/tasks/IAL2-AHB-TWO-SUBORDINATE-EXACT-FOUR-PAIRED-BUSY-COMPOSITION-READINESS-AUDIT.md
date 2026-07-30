# IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Two-Subordinate Exact-Four Paired AHB BUSY Readiness

## Metadata

- Tree ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `done`
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
  Status: `done`
  Goal: `Audit assertion-enabled two-window exact-four requester/BUSY-parking composition before public expansion.`
  Children: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`, `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`, `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Audit generic two-subordinate exact-four paired AHB BUSY readiness and select the next exact owner.`
  Acceptance: `Activate only after clean parent selector .826 commit. Reconcile the shipped exact-four requester and one-window generic/profile paired behavior, generic/profile two-window exact-three paired behavior, assertion-clean interconnect/generated-subordinate/direct-seed repairs, public generators, report residue, support/language/capability surfaces, normalized semantic JSON, real read-only MCP, t1533/t1534/t1537/t1538, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, scale, and decisions 0004/0008/0020. Recreate only the repository-derived same-volume generic candidate with exact future identity, four children, 29 signals, 4 IAL1/5 IAL0 artifacts, width-three requester load four, before_beat=2/beats=4, both child/propagated parks_on=[busy], two windows, one-hot ownership, no top busy_flow, normalized semantic/MCP parity, and unmatched support. Compile with selector assertions enabled and execute an adapted two-command runtime proving 10 presentations/8 beats/2 BUSY episodes/8 qualified BUSY events/2 resumed SEQ/status 0x44332211/control 0x88776655 with stable selected/unselected endpoint and fabric state. Decide whether a separate generic contract can follow, a lower-layer repair is required, or the candidate must fail closed. If ready, freeze projected 331/372/55 split 28 .ppif/27 .ahb and exact future support/test/diagnostic/preservation/cleanup/rollback boundaries. Keep aliases, counts above four, new BUSY policy/status/burst/signal semantics, generic priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, scale implementation, and decision 0020 separate. Use authorized host100/process4096, canonical Stats-compatible capacity, separate kernel pressure, repository-local artifacts, exact census, and residue proof.`
  Verification: `Activated only after clean parent selector commit 4abb0a357 through clean activation commit df19ed89a. Reconciled shipped exact-four requester and one-window generic/profile paired behavior, generic/profile two-window exact-three behavior, assertion-clean interconnect/generated-subordinate/direct-seed repairs, current 330/371/54 split 27/27 support/language/capability/semantic-MCP surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, scale, and decisions. A repository-derived same-volume future generic candidate changes only exact-three intent/object/anchor/requester identities and busy-beats 3 to 4. Strict check passes at ahb_tb/4 children/29 signals/zero top states with zero diagnostics and unmatched support; schedule preserves exact 4 IAL1/5 IAL0 artifacts, two windows, width-three requester load four, before_beat=2/beats=4, both child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, and no top busy_flow. Normalized semantic schema 1 and real repo-relative fsmgen_semantic_introspect agree on ahb_tb/root top/4 children/unmatched support with query_kind=semantic, read_only=true, shell_access=false. Public --verify-hdl passes. Verilator 5.046 compiles with --timing, -j 1, and all assertions; adapted two-command runtime passes transfers=10/beats=8/BUSY episodes=2/qualified BUSY=8/two internal 4->3->2->1->0 retirements/resumed SEQ=2/status=0x44332211/control=0x88776655 while checking stable requester, selected/unselected subordinate, and fabric state. t1533+t1537 pass 2 files/7 top-level tests in 973 seconds, including 83/72 nested assertions; t248+t297 pass 2 files/7,007 tests at unchanged 330/371/54. No lower-layer repair is required. Selected pending `.2` to freeze one generic source/support/test contract projecting 331/372/55 split 28 .ppif/27 .ahb. Alias, counts above four, new BUSY policy/status/burst/signal behavior, generic priority, HIAL/VIAL, scale, VHDL, verification generation, portability, and decision 0020 remain separate. The exact 47-file/56,921,569-byte audit workspace was removed without residue; only the pre-existing 491-byte xcrun_db cache remains. Canonical audit record/fact and continuity layers are synchronized. Final focused documentation validation passes 3 files/22 tests; the Knowledge Map is valid and synchronized at 1,044 facts/5,340 question keys; mdBook renders 72 files/16,343,761 bytes and its disposable output is removed; MEMORY.md remains bounded at 57 lines and README.md at 2,328 lines; all six doctrine gates pass. The canonical Stats-compatible reading is 19,836,256,256/25,769,803,776 bytes = 18.474/24.000 GiB = 76.97% RAM usage, with separate macOS pressure level 1. No parser, generator, public source, support, test, checked-in artifact, report/semantic/MCP API, shipped HDL/runtime, simulator integration, backend, protocol, verification-generation, HIAL/VIAL, VHDL, portability, scale, decision-0020, or transaction behavior changed.`
  Commit: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1: audit two-window exact-four AHB readiness`

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Select the first generic two-subordinate exact-four paired AHB BUSY public contract before implementation.`
  Acceptance: `Activate only after the clean .1 audit commit. Read the canonical .1 audit record/fact and exact disposable strict/schedule/artifact/normalized-semantic/real read-only MCP/public-verifier/assertion-runtime evidence; reconcile shipped one-window exact-four and two-window exact-three generic/profile contracts, RegressionCorpus/language/capability/current-doc surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, scalability, and decisions 0004/0008/0020. Freeze exactly one future generic source ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif as the identity/requester/cardinality-only transform of the shipped exact-three source, with exact intent/source object/bounded anchor, embedded requester amba_requester_busy_insert_four, status/control ahb_*_subordinate_byte_lane_hburst_seq children, fabric ahb_interconnect, top ahb_tb, exact 4 IAL1/5 IAL0 artifacts, width-three 4->3->2->1->0 requester behavior, before_beat=2/beats=4, child/propagated parks_on=[busy], two [0,4)/[4,8) windows, one-hot accepted-subordinate ownership, and no top busy_flow. Select support id intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park, coverage ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park_pipeline_cli, ppif/supported_smoke/strict/module ahb_tb/root top/4 children, and projected 331 protocol / 372 supported+strict / 55 AHB paths split 28 .ppif/27 .ahb only if reconfirmed. Freeze future t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t plus t/data/ahb_two_subordinate_exact_four_paired_busy_composition_tb.svt for source delta, strict/check/schedule/artifacts/verifier/diagnostics/normalized semantic/real read-only MCP/repository-local output and assertion-enabled 10/8/2/8/2/0x44332211/0x88776655 proof, preservation of t1533/t1534/t1537/t1538, docs/KM/resource/same-volume cleanup/rollback, and a separate implementation leaf. Make no parser, generator, public source, support, test, artifact, report/semantic/MCP API, HDL/runtime, simulator integration, backend, protocol, HIAL/VIAL, VHDL, verification-generation, portability, scale, decision-0020, or transaction behavior change in contract selection. Keep the matching alias, counts above four, policy/status/burst/signal semantics, generic priority, other protocols/backends, and decision 0020 separate/inactive.`
  Verification: `Activated only after clean .1 audit commit a5d162d60 through clean activation commit 93a7f2089. Read the canonical .1 audit record/fact and reconciled the shipped generic/profile two-window exact-three family, generic/profile one-window exact-four family, current RegressionCorpus/capability/doc surfaces, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, scale, and decisions. Selected exactly one future generic source ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif as the identity/requester/cardinality-only exact-three transform, with exact intent/object/anchor, amba_requester_busy_insert_four, status/control subordinates, ahb_interconnect, ahb_tb/top/4 children/29 signals, exact 4 IAL1/5 IAL0 artifacts, width-three 4->3->2->1->0, before_beat=2/beats=4, [0,4)/[4,8) windows, child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, and no top busy_flow. Selected exact support/coverage identity at projected 331 protocol / 372 supported+strict / 55 AHB paths split 28 .ppif/27 .ahb; t248+t297 reconfirm the current 330/371/54 boundary in 2 files/7,007 tests. Selected future t1539 and repository-local testbench for exact source/strict/report/artifact/verifier/diagnostic/semantic/real read-only MCP and all-assertion 10/8/2/8/2/0x44332211/0x88776655 runtime, with t1533/t1534/t1537/t1538 preservation. Proposed `.3` owns data-only implementation and exact rollback. Matching alias, counts above four, new policy/status/burst/signal semantics, generic priority, HIAL/VIAL, VHDL, verification generation, portability, scale, and decision 0020 remain separate. The future source, support entry, t1539, and testbench remain absent in this selection. Focused t1518+t1256+t1414 pass 3 files/22 tests; the Knowledge Map is valid and synchronized at 1,045 facts/5,346 question keys; mdBook renders 72 files/16,351,883 bytes and its disposable output is removed; MEMORY.md remains bounded at 58 lines and README.md at 2,329 lines; all six doctrine gates pass. The only repository-local temp residue is the pre-existing 491-byte xcrun_db cache. Canonical Stats-compatible RAM is 13,940,523,008/25,769,803,776 bytes = 12.983/24.000 GiB = 54.10%, with separate macOS pressure level 1. No parser, generator, public source, support, test, checked-in artifact, report/semantic/MCP API, shipped HDL/runtime, simulator integration, backend, protocol, verification-generation, HIAL/VIAL, VHDL, portability, scale, decision-0020, or transaction behavior changed.`
  Commit: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2: select two-window exact-four AHB contract`

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`
  Status: `done`
  Goal: `Ship the selected generic two-subordinate exact-four paired AHB BUSY source through existing generators.`
  Acceptance: `Activate only after the clean .2 contract commit. Implement exactly the .2 contract: add ppif/ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park.ppif as the identity/requester/cardinality-only transform of the shipped exact-three source, with selected intent/object/anchor, embedded amba_requester_busy_insert_four, busy-before-beat 2, busy-beats 4, existing status/control ahb_*_subordinate_byte_lane_hburst_seq actors, ahb_interconnect, ahb_tb, ports/storage/burst/response/windows/wiring unchanged. Add RegressionCorpus entry intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_four_byte_lane_hburst_seq_busy_park with selected coverage, ppif/supported_smoke/strict/module ahb_tb/root top/4-child expectations; update t248/t297 and public support/language/capability/current-doc inventory surfaces to exact 331 protocol / 372 supported+strict / 55 AHB paths split 28 .ppif/27 .ahb. Add t/1539-ial2-ahb-two-subordinate-exact-four-paired-busy-composition.t and t/data/ahb_two_subordinate_exact_four_paired_busy_composition_tb.svt covering exact source delta, strict/check success and support, diagnostics, schedule schema/4 children/29 signals/exact artifacts/two windows/one-hot ownership/requester before_beat=2/beats=4/width-three counter/both child+propagated parks/no top busy_flow, normalized semantic schema 1/root top, real repo-relative fsmgen_semantic_introspect query_kind=semantic/read_only=true/shell_access=false, repo-local output, --verify-hdl, and Verilator 5.046 --timing/-j1/all-assertion runtime at exact commands=2/presentations=10/beats=8/BUSY episodes=2/qualified BUSY=8/resumed SEQ=2/status=0x44332211/control=0x88776655 plus two 4->3->2->1->0 retirements and stable requester/selected+unselected subordinate/fabric ownership with clean completion. Preserve t1533/t1534/t1537/t1538 and existing source/alias bytes; run exact support/capability/docs/KM/doctrine/resource/locality/cleanup gates. Add behavior record/fact and synchronize README, ROADMAP_V2, REGRESSION_CORPUS/support docs, mdBook, task/index, Memory, and Knowledge Map. Use repository-derived same-volume temp/output, authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, exact census, cleanup, rollback, and commit. Do not change parser/generator algorithms, existing source bytes, report/semantic/MCP APIs, matching .ahb alias, counts above four, policy/status/burst/signal behavior, generic priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, portability, scale implementation, decision 0020, or unrelated transaction behavior.`
  Verification: `Activated only after clean .2 contract commit 4d0cc34bd through clean activation commit cb5a69ef6. Added exactly one 6,645-byte generic source as the frozen six-field identity/requester/cardinality transform of the shipped exact-three two-window authority: intent/object/anchor section, requester declaration, busy-beats 3->4, and requester child identity only. Existing generators emit exact 4 IAL1/5 IAL0 artifacts under ahb_tb/top/4 children/29 signals, width-three 4->3->2->1->0 requester state, before_beat=2/beats=4, [0,4)/[4,8) windows, both child/propagated parks_on=[busy], one-hot retained ownership, and no top busy_flow. Added exact ppif/supported_smoke/strict/top/4-child support/coverage identity and synchronized t248 to 331 protocol / 372 supported+strict / 55 AHB paths split 28 .ppif/27 .ahb; t248+t297 pass 2 files/7,019 tests. t1539 passes 4 top-level subtests in 718 seconds: source delta, explicit unmatched-neighbor success with zero false diagnostics, strict/check, schedule, artifacts, normalized semantic schema 1/root top, real repo-relative MCP query_kind=semantic/read_only=true/shell_access=false, repository-local output, public --verify-hdl, and Verilator 5.046 --timing/-j1/all-assertion runtime commands=2/transfers=10/beats=8/BUSY=2/qualified_busy=8/two internal 4->3->2->1->0 retirements/resumed_seq=2/status=0x44332211/control=0x88776655 with stable requester/selected+unselected subordinate/fabric state. Preservation t1533+t1534+t1537+t1538 passes 4 files/15 top-level tests in 2,113 seconds. t1539 leaves .artifacts/tmp/tests empty; only the pre-existing 491-byte xcrun_db cache remains. Canonical behavior/fact, regression inventory, roadmap, task/index, README, mdBook, HIAL/VIAL deferral, prior current records, and parent handoff are synchronized. The first current-surface closeout caught and repaired the authoritative mdBook opening inventory still naming 54 paths; final t1518+t1256+t1414 pass 3 files/22 tests at the correct 55-path boundary. The Knowledge Map is valid and synchronized at 1,046 facts/5,352 question keys. mdBook renders 72 files/16,363,361 bytes and its disposable output is removed. MEMORY.md remains bounded at 59 lines and README.md at 2,330 lines. All six doctrine gates pass, including project-data locality; no repository-local temp residue exists beyond the pre-existing 491-byte xcrun_db cache. Final canonical Stats-compatible RAM is 12,824,281,088/25,769,803,776 bytes = 11.944/24.000 GiB = 49.76%, with separate macOS kernel pressure level 1 and memory_pressure free percentage 66%. Parser/generator algorithms, existing source/alias bytes, report/semantic/MCP APIs, simulator integration, matching alias, counts above four, broader policy/status/burst/signal behavior, generic priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, portability, scale, decision 0020, and unrelated transactions remain unchanged.`
  Commit: `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3: ship two-window exact-four AHB composition`

## Dependencies

- `IAL2-FEATURE-COMPLETENESS-FRONTIER.826`
- `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- `IAL2-AHB-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- `IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION`
- `IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION`
- `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION`
- decisions `0004`, `0008`, and `0020`

## Rollback

Rollback removes the exact source, support entry, t1539, testbench, behavior
record/fact, and synchronized accounting/docs named by the `.2` contract. It
restores 330/371/54 split 27 `.ppif`/27 `.ahb` and leaves every existing source,
generator, API, runtime, and simulator profile unchanged.

## Decisions

- `2026-07-30`: Clean parent selector commit `4abb0a357` activates `.1`
  without changing public or generated behavior.
- `2026-07-30`: `.1` proves direct assertion-enabled two-window exact-four
  readiness and selects pending no-behavior generic contract `.2`.
- `2026-07-30`: Clean audit commit `a5d162d60` activates `.2` without changing
  public or generated behavior.
- `2026-07-30`: Contract `.2` freezes one generic source/support/t1539 runtime
  boundary and selects pending data-only implementation `.3`.
- `2026-07-30`: Clean contract commit `4d0cc34bd` activates `.3` without
  changing public or generated behavior.
- `2026-07-30`: `.3` ships the selected generic two-window exact-four path,
  t1539 assertion-enabled runtime, exact support, and 331/372/55 current
  accounting. The child tree is complete.

## Blockers

- None after clean `.2` contract commit `4d0cc34bd`.
