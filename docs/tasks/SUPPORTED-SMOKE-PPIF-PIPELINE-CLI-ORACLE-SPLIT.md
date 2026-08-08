# SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT: Separate PPIF Entry And Aggregate HDL Oracles

## Metadata

- Tree ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT`
- Status: `active`
- Roadmap lane: `test integrity / IAL2 PPIF support accounting`
- Created: `2026-07-31`
- Last updated: `2026-08-08`
- Owner: repo-local workflow

## Goal

Make the supported-smoke runtime audit assert the correct generated entry
module for the in-memory PPIF pipeline result and the correct aggregate top for
the public CLI output, instead of applying one incompatible module oracle to
both surfaces.

## Non-Goals

- Do not change PPIF lowering, artifact selection, CLI aggregation, or HDL.
- Do not weaken the public aggregate-top assertion.
- Do not change VIAL or its semantic-only support classification.
- Do not activate this tree while another task tree owns a dirty worktree.

## Acceptance Criteria

- The PPIF support schema distinguishes an in-memory generated entry artifact
  oracle from a CLI aggregate-top oracle wherever they differ.
- `t/296-regression-corpus-supported-behavior.t` asserts each surface against
  its own declared contract and passes its full default/strict matrix.
- Focused PPIF pipeline, CLI, support-accounting, and defensive-copy gates pass
  without generated HDL changes.
- Project-local temporary output is used and removed exactly.
- Disabled backend tracing performs no AST rendering or serialization work;
  enabled level-3 tracing retains its detailed signal inventory.
- Task index and bounded continuity records are synchronized and the slice
  commits through `COMMIT.md`.

## Task Tree

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT`
  Status: `active`
  Goal: `Separate PPIF in-memory entry-module and CLI aggregate-top support oracles.`
  Children: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1`
  Status: `active`
  Goal: `Repair the supported-smoke PPIF runtime audit without changing product output.`
  Children: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.1, SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2`
  Acceptance: `Each PPIF entry declares and proves the in-memory generated entry module plus public CLI aggregate top as applicable; t296 and focused PPIF/support gates pass with unchanged HDL bytes and semantic reports.`
  Verification: `Discovery during HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.3: after semantic-only VIAL is correctly excluded from HDL generation, t296 repeatedly expects module ahb_tb in an in-memory pipeline result whose source_info.generated_hdl_entry_artifact is ahb_interconnect.fsm and whose hdl_code contains module ahb_interconnect. Fresh clean-tree reproduction on 2026-08-07 reconfirmed the same default-pipeline mismatch across distinct AHB interconnect fixtures. A complete guarded adapter/artifact census then proved 62 of 240 strict PPIF smoke entries have distinct pipeline and CLI module contracts: 18 AHB, 37 APB, five AXI composition, and two valid-ready bundle entries. The bundles additionally have aggregate entry-artifact filenames that differ from their emitted monitor module names. t296 _assert_entry_hdl_shape had applied expected_module_name to both surfaces. The exact 240-entry post-fix census reports TOTAL 240 MISMATCHES 0; all 62 divergent entries pass default-pipeline workers, while strict AHB, APB, AXI-composition, and bundle/artifact-override representatives pass. Final t248/t491 pass 7,094 assertions, and focused AXI/AHB alias tests pass 10.`
  Commit: `implementation in this commit (SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1: separate runtime module oracles); complete parent verification remains blocked under .1.2`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.1`
  Status: `done`
  Goal: `Separate CLI-only IAL2 profile aliases from the public in-memory pipeline matrix.`
  Acceptance: `t296 runs .fsm/.isf/.ppif roots through HDLGenerator, runs all HDL-generating entries including .ahb/.apb/.axi aliases through the CLI, and retains exact module checks on both supported surfaces without widening the facade.`
  Verification: `Fresh 2026-08-07 source-kind census found 86 supported-smoke ial2_profile_alias entries in t296's unqualified pipeline set: 28 .ahb, 57 .apb, and one .axi. A direct HDLGenerator call with ppif/ahb_interconnect.ahb fails at its intentional _generation_source_path_arg contract, which accepts only .fsm, .isf, or .ppif roots; focused alias tests prove profile-alias generation through bin/fsmgen. t296 also lacked an ial2_profile_alias HDL-shape branch. This is a test-surface conflation, not a missing product feature.`
  Commit: `this commit (SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1: separate runtime module oracles)`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2`
  Status: `active`
  Goal: `Bound t296's full runtime matrix below the repository descendant-RSS ceiling without dropping coverage.`
  Children: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1, SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.2`
  Acceptance: `The four default/strict pipeline/CLI cohorts execute every selected entry in deterministic isolated batches, worker failures retain actionable TAP diagnostics, and the complete parent test passes under the unchanged 4096-MiB descendant cap.`
  Verification: `A clean-host guarded post-oracle run started at 55.7% host occupancy, ran for eight minutes without assertion output, then the single t296 Perl process reached 5369.8 MiB and was terminated at the unchanged 4096-MiB descendant cutoff. The audit now uses one-entry pipeline and four-entry CLI self-workers with fail-closed surface/suffix and worker-bound validation plus failed-worker TAP replay. A guarded 32-entry conservative pipeline worker passed all 92 assertions before batch tightening; resumable guarded verification then passed every default-pipeline entry through index 113, which includes all 62 divergent PPIF contracts, plus strict AHB/APB/AXI/bundle representatives and default/strict CLI AHB aggregate checks. After the separately owned macOS host metric was corrected, the isolated zero-based pipeline entry 114 still reached 4222.3 MiB, proving a real per-worker backend cliff. Stage probes localize it to disabled signal-inventory tracing in consolidated-intermediate collection: lowering, parsing, semantic construction, flattening, prescan, and factorization remain bounded, while trace_fsm_signal_inventory eagerly Data::Dumper-serializes every driving AST before fsm_debug rejects the disabled messages. Manually bypassing only that trace holds the same 1,158-helper case near 124 MiB. No cutoff was raised or bypassed.`
  Commit: `worker implementation in bfeb6d3ff; memory repair closes in this commit under .1.2.1; bounded CPU/full-matrix closeout continues under .1.2.2`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1`
  Status: `done`
  Goal: `Make disabled consolidated-intermediate inventory tracing zero-cost before message construction while preserving enabled level-3 diagnostics.`
  Acceptance: `A focused regression proves disabled tracing never calls driving-AST rendering or Data::Dumper, enabled level-3 tracing retains the inventory detail, and isolated pipeline entry 114 completes below 4096 MiB. The complete-parent acceptance remains on parent .1.2 and transfers to .1.2.2 after the independent index-116 CPU outlier discovered by that run.`
  Verification: `Fresh guarded stage isolation on 2026-08-08 measures PPIF lowering at 1.196 s, Lispish parsing at 0.899 s, semantic construction at 0.150 s, flattening at 0.093 s, prescan at 0.004 s, and first-pass factorization at 1.533 s. Direct consolidated collection intermittently reaches 5.0-5.35 GiB, while executing the same merge/normalization flow without trace_fsm_signal_inventory stays between 121.7 and 123.8 MiB across all 1,158 helper records. Source inspection identifies the disabled-path eager Data::Dumper call at ConsolidatedIntermediateSupport.pm:106. The repair gates inventory traversal on enabled debug level 3; focused t1596 passes all six disabled/enabled contract assertions, both changed Perl files are syntax clean, and formerly failing zero-based pipeline entry 114 passes all three assertions in 28 seconds under the unchanged guard. The full guarded parent then progressed to index 116 with its worker bounded near 425 MiB but continuously CPU-bound inside direct SystemVerilog backend emission for more than one hour, proving a separate scaling defect rather than recurrence of entry 114's disabled-trace memory cliff.`
  Commit: `this commit (SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1: own disabled trace repair)`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.2`
  Status: `active`
  Goal: `Bound the multi-static AXI capacity/status direct-backend CPU path and complete the guarded t296 matrix.`
  Acceptance: `Exact pipeline index 116 completes within a declared guarded runtime bound without changing its generated HDL contract, and the complete t296 parent passes every default/strict pipeline/CLI cohort under the unchanged host and 4096-MiB descendant limits.`
  Verification: `Initial isolation identifies intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static at zero-based pipeline index 116. PPIF lowering takes 7.754 s and emits the exact active 2,013,530-byte axi0_capacity_status.fsm artifact with SHA-256 29a6d16044b67381c110b4d56e245712272f78ca70c74d5f1df374b25b63b0c5. On that artifact, source parsing takes 14.2 s, semantic construction 2.1 s, IntentHIR 0.05 s, and module-info construction 0.03 s; the hour-scale CPU cost begins inside direct SystemVerilog backend emission while RSS remains near 425 MiB.`
  Commit: `pending`

## Decisions

- `2026-07-31`: Treat the mismatch as an oracle-surface conflation, not a VIAL
  regression and not evidence that the pipeline or CLI should change output.
- `2026-07-31`: Preserve both assertions with separate identities; skipping
  PPIF from the runtime audit is not an acceptable repair.
- `2026-08-07`: Select an explicit independent
  `expected_pipeline_module_name` catalog field only for PPIF entries whose
  in-memory entry module differs from the shared/CLI module oracle. Pipeline
  acceptance must also cross-check the public `generated_hdl_entry_artifact`;
  deriving the entire expectation from that self-report is insufficient.
- `2026-08-07`: The full-matrix census exposed a second t296 surface
  conflation: 86 profile aliases (28 `.ahb`, 57 `.apb`, and one `.axi`) are
  CLI-supported but are not accepted by the public in-memory facade. Track the
  repair under nested task `.1.1`; select pipeline entries by the facade's
  public source suffixes and retain all HDL-generating aliases in both CLI
  passes.
- `2026-08-07`: Replace the initial `_tb`-filtered 55-entry classification
  with the exhaustive 62-entry PPIF census. Keep module and entry-artifact
  expectations separate because both valid-ready bundles intentionally select
  aggregate wrapper filenames that emit named monitor modules.
- `2026-08-07`: Preserve the unchanged 4096-MiB descendant cap. Run the full
  t296 matrix in deterministic isolated workers—one pipeline entry or four CLI
  entries—so Perl allocator and generated-file-cache growth are released
  between batches without omitting any catalog entry or weakening any
  assertion. Single-entry pipeline workers bound the oversized AXI
  manager-capacity family; four-entry CLI workers bound cache growth.
- `2026-08-07`: The slice changes only corpus oracle metadata and its runtime
  audit. Generated HDL, semantic reports, CLI behavior, and user-facing syntax
  are unchanged, so no mdBook or `DEVELOPMENT_NOTES.md` change is warranted;
  the task and Knowledge Map card own the test-contract rationale.
- `2026-08-08`: Startup re-verification recomputed the transitive
  `bin/fsmgen` import closure as 254 files / 253 Perl modules and found the
  architecture map's selected `FSM::Support::RegressionCorpus` measurement
  stale at 6,820 lines versus the current 6,884. Preserve that finding here
  while `.1.2` remains active; synchronize the measured documentation under an
  explicit owning leaf only after `.1.2.1` completes and the tree is clean.
- `2026-08-08`: Preserve the unchanged guard limits and full corpus coverage.
  The corrected guard disproved batching as sufficient for entry 114; the
  backend must not construct expensive level-3 trace payloads while tracing is
  disabled. Track the behavior-preserving repair explicitly under `.1.2.1`.
- `2026-08-08`: Close `.1.2.1` on its independently verified disabled-trace
  contract and formerly failing index-114 worker. Preserve the complete-parent
  gate on `.1.2`, and give the separately reproduced index-116 direct-backend
  CPU scaling defect explicit nested ownership under `.1.2.2`; do not weaken
  corpus coverage or raise either resource cutoff.

## Open Questions

- None requiring director input. `.1.2.2` owns exact backend-phase isolation
  and a behavior-preserving CPU-scaling repair; no threshold, coverage, or
  product-output decision is delegated to the director.

## Blockers

- The complete guarded t296 parent is temporarily blocked by the index-116
  direct-SystemVerilog backend CPU hotspot owned by active leaf `.1.2.2`.
  Index 114's disabled-trace memory cliff and the prior macOS host-metric defect
  are resolved; neither guard threshold will be raised or bypassed.

## Acceptance Checklist (enforced for implementation changes)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_assert_entry_hdl_shape'
  -- t/296-regression-corpus-supported-behavior.t` traces the generic runtime
  audit to `9a41ff708`, where one expected-module field was deliberately wired
  into both the in-memory pipeline and CLI paths before PPIF aggregate outputs
  and IAL2 profile-alias source surfaces existed. A fresh exhaustive strict
  PPIF adapter/artifact census locates the resulting contract mismatch in 62
  of 240 entries, while direct facade reproduction and an exact suffix census
  prove the 86 `.ahb`/`.apb`/`.axi` aliases are CLI roots rather than public
  `HDLGenerator` roots.
- [x] **ADDRESSED (verified)** — 62 PPIF entries now declare an independent
  pipeline module, the two filename/module-divergent bundles also declare an
  explicit pipeline entry artifact, and t296 asserts those values separately
  from the unchanged CLI oracle. The exhaustive post-fix adapter/artifact run
  reports `TOTAL 240 MISMATCHES 0`; guarded default-pipeline workers pass all
  62 divergent AHB/APB/AXI/bundle entries, and strict representatives pass for
  each distinct module/artifact shape. The 86 profile aliases are structurally
  restricted to CLI workers as 28 `.ahb`, 57 `.apb`, and one `.axi`.
- [x] **NO REGRESSION** — guarded t248/t491 reports `All tests successful`
  (Files=2, Tests=7094); guarded t1469/t1474 reports `All tests successful`
  (Files=2, Tests=10); the conservative 32-entry pipeline worker reports
  `1..92` with every assertion passing. Both changed Perl files are syntax
  clean, the Knowledge Map parity check passes at 1,105 facts / 5,699 questions,
  and `git diff --check` passes. The complete parent-run resource blocker is
  recorded explicitly above rather than weakening or bypassing the guard.

## Acceptance Checklist (.1.2.1 disabled-trace repair; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'trace_fsm_signal_inventory'
  -- perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm`
  identifies extraction commit `f91a4034b`; guarded stage probes then isolate
  the 5.0-5.35-GiB entry-114 cliff to that method's eager
  `Data::Dumper->Dump()` construction before disabled level-3 messages are
  rejected. Bypassing only that trace holds all 1,158 helper records near
  124 MiB.
- [x] **ADDRESSED (verified)** —
  `scripts/run_with_ram_guard.sh --poll-seconds 2 -- prove -Iperl
  t/1596-consolidated-intermediate-debug-trace-gating.t` reports six passing
  assertions: debug levels 0 and 2 touch neither module nor AST, while level 3
  renders once and retains the summary, expression, and Data::Dumper detail.
- [x] **NO REGRESSION** — the exact guarded t296 pipeline worker at zero-based
  entry 114 reports `All tests successful` and `Files=1, Tests=3` in 28 seconds
  under the unchanged 4096-MiB cap. Focused t1596 independently reports
  `All tests successful` and `Files=1, Tests=6`; both changed Perl files report
  `syntax OK`. The full-parent run's independent index-116 CPU outlier is
  explicitly owned by `.1.2.2` rather than hidden or misclassified.
