# IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT: Two-Subordinate Exact-Three Paired AHB BUSY Readiness

## Metadata

- Tree ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- Status: `done`
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
  Status: `done`
  Goal: `Audit assertion-enabled two-window exact-three requester/BUSY-parking composition before public expansion.`
  Children: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1, IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2, IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Audit generic two-subordinate exact-three paired AHB BUSY readiness and select the next exact owner.`
  Acceptance: `Activate only after clean parent selector .819 commit. Reconcile the shipped exact-three requester and one-window generic/profile paired behavior, generic/profile two-window exact-two paired behavior, assertion-clean interconnect/generated-subordinate/direct-seed repairs, public PPIF/AHB generators, report residue, support/language/capability surfaces, normalized semantic JSON, real read-only MCP, t1525/t1526/t1531/t1532, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, decisions 0004/0008/0020, and the .819 disposable static/HDL evidence. Recreate only a repository-derived same-volume generic candidate with the exact future identity, four children, 29 signals, 4 IAL1/5 IAL0 artifacts, requester before_beat=2/beats=3, both child and propagated parks_on=[busy], one-hot ownership, normalized semantic/MCP parity, and unmatched support. Compile without --no-assert and execute an adapted two-command runtime proving 10 presentations/8 beats/2 BUSY episodes/6 qualified BUSY events/2 resumed SEQ/status 0x44332211/control 0x88776655 with stable selected/unselected endpoint and fabric state. Decide whether a separate generic public-contract leaf can follow, a lower-layer repair is required, or the candidate must fail closed. If ready, freeze projected 325/366/49 split 25 .ppif/24 .ahb and exact future support/test/diagnostic/preservation/cleanup/rollback boundaries. Keep aliases, counts above three, new BUSY policy/status/burst/signal semantics, generic priority, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, and decision 0020 separate. Use authorized host100/process4096, canonical Stats-compatible capacity, separate kernel pressure, repository-local artifacts, exact census, and residue proof.`
  Verification: `Activated only after clean parent selector commit e2109a2ba. Recreated the exact same-volume future generic candidate as the data-only exact-two transform with busy_insert_three/busy-insert-three/(busy-beats 3). Strict check succeeds with zero diagnostics, correctly unmatched support, top ahb_tb, four children, 29 signals, and zero top-local states. Schedule schema fsmgen.ial2.protocol_intent.ahb_interconnect.v1 preserves exact intent/object, two status/control windows, one-hot accepted-subordinate response ownership, 4 IAL1/5 IAL0 artifacts, width-two requester counter loaded to three, before_beat=2/beats=3, and both child/propagated parks_on=[busy]. Normalized semantic JSON reports schema key normalized_semantic_schema_version, module ahb_tb, root top, four children, 29 module signals, and unmatched support; real fsmgen_semantic_introspect agrees on module/root/children/support with query_kind=semantic, read_only=true, shell_access=false, and the repo-relative source id. Generated HDL and review artifacts are clean, public --verify-hdl passes, and Verilator 5.046 compiles with --timing and all selector assertions enabled. The adapted two-command runtime passes exact transfers=10/beats=8/BUSY episodes=2/qualified BUSY=6/resumed SEQ=2/status=0x44332211/control=0x88776655 while checking stable selected/unselected endpoint state, address/control/data/counters, and fabric ownership through BUSY. Current t1525+t1531 pass 2 files/7 top-level tests in 964 seconds; t248+t297 pass 2 files/6,935 tests at 324 protocol/365 supported+strict/48 AHB split 24 .ppif/24 .ahb, projecting 325/366/49 split 25/24 for one new generic path. No lower-layer, generator, semantic/MCP, assertion, simulator, or scheduler repair is required. Selected pending `.2` to freeze the generic public contract; alias and broader BUSY work remain separate. The exact 56-file/57,355,098-byte disposable workspace was removed without residue. Post-preservation canonical Stats-compatible capacity is 67.8% (16.277/24 GiB) and kernel pressure is normal (1); guard occupancy is excluded as capacity truth. Canonical audit record/fact, roadmap, parent/child/HIAL-VIAL trees, mdBook, task index, and Memory are synchronized. Focused t1518+t1256+t1414 pass 3 files/22 tests; Knowledge Map generation/check reaches 1,027 facts/5,237 question keys; mdBook builds 72 files/16,179,728 bytes and its exact generated tree is removed without residue; all doctrine gates pass. Final closeout capacity is 68.5% (16.435/24 GiB) with kernel pressure still normal (1), independently confirming that the guard's 91.9% heuristic is not RAM-capacity truth. No public source/support/test/artifact/API/HDL/runtime/backend/protocol/verification-generation/HIAL/VIAL/VHDL/transaction behavior changed.`
  Commit: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.1: audit two-window exact-three AHB readiness`

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Select the first generic two-subordinate exact-three paired AHB BUSY public contract before implementation.`
  Acceptance: `Activate only after the clean .1 audit commit. Read the .1 audit record/fact, exact disposable strict/schedule/artifact/assertion-runtime/normalized-semantic/real read-only MCP evidence, shipped one-window exact-three and two-window exact-two generic/profile contracts and behavior, current RegressionCorpus/support/capability surfaces, public diagnostics, roadmap, mdBook, Knowledge Map, HIAL/VIAL, generic priority, and decisions 0004/0008/0020. Freeze exactly one future generic source ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif with the selected intent, source object, bounded anchor, embedded requester amba_requester_busy_insert_three, status/control HBURST-aware byte-lane BUSY-parking subordinates, ahb_interconnect fabric, top ahb_tb, exact 4 IAL1/5 IAL0 artifacts, width-two 3 -> 2 -> 1 -> 0 behavior, before_beat=2/beats=3, both child/propagated parks_on=[busy], one-hot accepted-subordinate ownership, two windows, and no duplicate top busy_flow. Select support id intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, coverage ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli, ppif/supported_smoke/strict/module ahb_tb/root top/4-child expectations, and projected 325 protocol / 366 supported+strict / 49 AHB split 25 .ppif/24 .ahb only if reconfirmed. Freeze a future focused test plus assertion-enabled two-command harness owning strict/check/schedule/artifacts/verifier/diagnostics/normalized semantic/real read-only MCP and exact 10/8/2/6/2/0x44332211/0x88776655 runtime, preservation, documentation, same-volume cleanup, rollback, and a separate implementation leaf. Do not add the source, support entry, test, artifact, parser/generator behavior, .ahb alias, counts above three, new policy/status/burst/signal semantics, generic priority, another protocol/backend, HIAL/VIAL activation, VHDL, verification generation, or decision-0020 behavior in this selector.`
  Verification: `Activated only after clean .1 audit commit c2aa63c3e through clean activation commit 4abde8306. Froze exactly one additive generic source ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif as the data-only exact-two transform: topology-first intent/object/bounded anchor, requester amba_requester_busy_insert_three, (busy-before-beat 2)/(busy-beats 3), existing status/control children, static [0,4)/[4,8) windows, interconnect, bindings, ports, wait controls, storage, and ahb_tb unchanged. Froze exact 4 IAL1/5 IAL0 artifacts, width-two 3 -> 2 -> 1 -> 0 behavior, child/propagated parks_on=[busy], one-hot accepted-subordinate owner capture/retire/replacement, no duplicate top busy_flow, and unchanged substantive residue. Selected support id intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park, coverage ial2_ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park_pipeline_cli, ppif/supported_smoke/strict/module ahb_tb/root top/4 children, and projected 325 protocol/366 supported+strict/49 AHB split 25 .ppif/24 .ahb. Selected future t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t plus t/data/ahb_two_subordinate_exact_three_paired_busy_composition_tb.svt to own source delta, strict/support, schedule/report/residue/artifacts, normalized semantic, real read-only shell-disabled MCP, repository-local outdir, public --verify-hdl, diagnostics/preservation, and assertion-enabled exact 10/8/2/6/2/status-44332211/control-88776655 runtime with stable selected/unselected endpoint and fabric state. Selected pending `.3` for data-only implementation. The matching alias, counts above three, new BUSY policy/status/burst/signal semantics, generic priority, other protocols/backends, HIAL/VIAL activation, VHDL, verification generation, and decision 0020 remain separate. Contract selection changes no public source/support/test/artifact/API/HDL/runtime behavior. Contract record/fact, roadmap, parent/child/HIAL-VIAL trees, mdBook, task index, and Memory are synchronized. Focused t1518+t1256+t1414 pass 3 files/22 tests; Knowledge Map reaches 1,028 facts/5,242 question keys; mdBook builds 72 files/16,184,455 bytes and the exact generated tree is removed without residue; all doctrine gates pass. Canonical Stats-compatible capacity is 68.1% (16.342/24 GiB), kernel pressure is separately normal (1), and the guard's 92.1% heuristic is excluded as capacity truth.`
  Commit: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.2: select two-window exact-three contract`

- ID: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3`
  Status: `done`
  Goal: `Ship the selected generic two-subordinate exact-three paired AHB BUSY source through existing generators.`
  Acceptance: `Activate only after clean .2 contract commit. Implement exactly the .2 contract: add ppif/ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park.ppif as the exact data-only extension of the shipped two-window exact-two source, with selected intent/object/anchor, embedded amba_requester_busy_insert_three, busy-before-beat 2, busy-beats 3, existing status/control HBURST-aware byte-lane BUSY-parking subordinates, ahb_interconnect, ahb_tb, ports/windows/storage/wait controls/wiring unchanged. Add RegressionCorpus entry intent.ppif_ahb_interconnect_two_subordinate_requester_busy_insert_three_byte_lane_hburst_seq_busy_park with selected coverage, ppif/supported_smoke/strict/module ahb_tb/root top/4 children; update t248/t297 and public support/language/capability/current-doc inventory surfaces to exact 325 protocol/366 supported+strict/49 AHB split 25 .ppif/24 .ahb. Add t/1533-ial2-ahb-two-subordinate-exact-three-paired-busy-composition.t and t/data/ahb_two_subordinate_exact_three_paired_busy_composition_tb.svt covering source identities/delta, strict/check success and exact support, schedule schema/4 children/29 signals/4 IAL1/5 IAL0 artifacts/two windows/one-hot ownership/requester before_beat=2/beats=3/width-two counter/both child+propagated parks/no top busy_flow, normalized semantic JSON, real repo-relative fsmgen_semantic_introspect read_only=true/shell_access=false, repo-local outdir, --verify-hdl, and Verilator without --no-assert at exact commands=2/transfers=10/beats=8/BUSY episodes=2/qualified BUSY=6/resumed SEQ=2/status=0x44332211/control=0x88776655 plus stable requester/selected/unselected subordinate/fabric ownership and clean completion. Preserve t1525/t1526/t1531/t1532 and existing source/alias bytes; use the smallest warranted focused/broader gates. Add behavior record/fact and sync README, ROADMAP_V2, REGRESSION_CORPUS/support docs, mdBook, task/index, Memory, and Knowledge Map. Use repo-derived same-volume temp/output, authorized host100/process4096, exact Stats-compatible capacity plus separate kernel pressure, exact cleanup census, rollback, and commit. Do not change parser/generator algorithms, existing source bytes, reports/schemas, semantic-MCP API, .ahb alias, counts above three, new policy/status/burst/signal semantics, generic priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, or decision 0020.`
  Verification: `Activated only after clean .2 contract commit 129d52967 through clean activation commit 63de6a6b7. Added only the selected generic source as the exact data-only transform of the shipped two-window exact-two source, plus its exact ppif/supported-smoke+strict/ahb_tb/top/four-child RegressionCorpus identity, t1533, the assertion-enabled harness, and synchronized public behavior surfaces. Existing PPIF/AHB parsing, generator algorithms, reports/schemas, semantic/MCP APIs, and all prior source bytes remain unchanged. t1533 passes 3 top-level tests / 83 nested assertions in 640 seconds: zero strict diagnostics; exact support; schema, four children, 29 signals, two windows, one-hot owner, requester before_beat=2/beats=3 and width-two 3 -> 2 -> 1 -> 0, both child/propagated parks_on=[busy], no top busy_flow, exact 4 IAL1/5 IAL0 artifacts, normalized semantic JSON, real repo-relative fsmgen_semantic_introspect with read_only=true/shell_access=false, repository-local output, public --verify-hdl, and Verilator --timing with every selector assertion enabled. Runtime passes exact commands=2/transfers=10/beats=8/BUSY episodes=2/qualified BUSY=6/resumed SEQ=2/status=44332211/control=88776655 while selected/unselected endpoint and fabric state remain stable. t248+t297 pass 2 files/6,947 tests at 325 protocol/366 supported+strict/49 AHB split 25 .ppif/24 .ahb; t1518 passes all five current-truth groups. t1526+t1532 pass 2 files/8 top-level groups in 1,317 seconds, preserving byte/lowering/strict/schedule/semantic/read-only-MCP/artifact/HDL-verifier identity for the adjacent two-window exact-two and one-window exact-three aliases. t1256+t1414 pass 2 files/17 tests. Knowledge Map generation/check passes at 1,029 facts/5,247 question keys. mdBook builds to exactly 72 files/16,192,778 bytes; build output and six exact task-owned File::Temp directories containing 45 regenerable preservation artifacts are removed with zero residue. Memory is 56 lines; frozen legacy blobs and all prior generic/profile bytes remain unchanged; diff and all six doctrine gates pass. Final canonical Stats-compatible RAM is 67.2% (16.124/24.000 GiB), kernel pressure is separately 1 (normal), and the guard heuristic is excluded as capacity truth.`
  Commit: `IAL2-AHB-TWO-SUBORDINATE-EXACT-THREE-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT.3: ship two-window exact-three composition`

## Current Frontier

Complete `.1`-.3: readiness proved the combined boundary, contract selection
froze it, and implementation ships the generic source/support/t1533 at exact
325/366/49 split 25 `.ppif`/24 `.ahb`. Ownership returns to proposed parent
selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.820` only after this behavior
commits cleanly.

## Decisions

- `2026-07-29`: Parent selector `.819` selects the readiness audit, not direct
  implementation. Static lowering, semantic export, and HDL verification pass,
  but the combined two-window exact-three assertion-enabled runtime remains an
  independent correctness obligation.
- `2026-07-29`: Keep HIAL/VIAL proposed with portable-fast Verilator separated
  from full-language/SystemVerilog-UVM authority; the smaller adjacent IAL2
  audit does not change that architecture requirement.
- `2026-07-29`: Audit `.1` proves exact two-window exact-three composition
  through real read-only MCP and assertion-enabled 10/8/2/6/2 runtime, requires
  no lower-layer repair, and selects `.2` for a separate generic public
  contract. No source ships in the audit.
- `2026-07-29`: Clean audit commit `c2aa63c3e` satisfies the `.2` activation
  boundary. Contract selection is active and still changes no behavior.
- `2026-07-29`: Contract `.2` freezes one generic source, exact support and
  semantic/MCP identities, assertion-enabled t1533, projected 325/366/49
  accounting, and selects `.3` data-only implementation. No source ships in
  contract selection.
- `2026-07-29`: Clean contract commit `129d52967` satisfies the `.3`
  activation boundary. Implementation is active but no source or behavior
  changes in activation.
- `2026-07-29`: Implementation `.3` ships the selected generic two-window
  exact-three source through unchanged generators, exact support and
  semantic/read-only-MCP surfaces, and assertion-enabled t1533 runtime at
  325/366/49 split 25/24. The matching alias and broader BUSY/HIAL/VIAL work
  remain separate; proposed parent selector `.820` is the next clean owner.

## Open Questions

- None. The tree is complete.

## Blockers

- None.

## Rollback

Remove the new generic source, RegressionCorpus entry, t1533/harness, behavior
record/fact, and exact accounting/current-truth updates; restore 324/365/48
split 24/24. Existing generators, sources, and semantic/MCP APIs remain intact.
