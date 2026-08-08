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
  Children: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1, SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.2, SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.3`
  Acceptance: `The four default/strict pipeline/CLI cohorts execute every selected entry in deterministic isolated batches, worker failures retain actionable TAP diagnostics, and the complete parent test passes under the unchanged 4096-MiB descendant cap.`
  Verification: `A clean-host guarded post-oracle run started at 55.7% host occupancy, ran for eight minutes without assertion output, then the single t296 Perl process reached 5369.8 MiB and was terminated at the unchanged 4096-MiB descendant cutoff. The audit now uses one-entry pipeline and four-entry CLI self-workers with fail-closed surface/suffix and worker-bound validation plus failed-worker TAP replay. A guarded 32-entry conservative pipeline worker passed all 92 assertions before batch tightening; resumable guarded verification then passed every default-pipeline entry through index 113, which includes all 62 divergent PPIF contracts, plus strict AHB/APB/AXI/bundle representatives and default/strict CLI AHB aggregate checks. Entry 114's disabled inventory trace was repaired under .1.2.1. Entry 116 then exposed independent live-usage, classification, and module-inventory scaling defects. Its first bulk-cache repair passed index 116 but the restarted parent exposed false dead-signal classifications at entries 11-14 because temporary parsed RHS AST addresses were deduplicated across assignments. Parsed roots now scan independently; those four workers pass, and index 116 still passes in 660 seconds under the unchanged guard. A subsequent full guarded run completed all 287 default-pipeline workers and default-CLI batches through index 199 before unrelated host occupancy crossed 88% after 194 minutes; exact default-CLI index 202 then passed in 699 seconds from a low-pressure start. `.1.2.3` owns exact-commit checkpoint continuity so a host-pressure interruption cannot discard already-green cohorts. No cutoff was raised or bypassed.`
  Commit: `worker implementation in bfeb6d3ff; disabled inventory repair in 33f926614; index-116 implementation in 10badb9b4; parsed-RHS correction in b76c5f63e; exact-commit checkpoint and complete-parent verification pending under .1.2.3`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1`
  Status: `done`
  Goal: `Make disabled consolidated-intermediate inventory tracing zero-cost before message construction while preserving enabled level-3 diagnostics.`
  Acceptance: `A focused regression proves disabled tracing never calls driving-AST rendering or Data::Dumper, enabled level-3 tracing retains the inventory detail, and isolated pipeline entry 114 completes below 4096 MiB. The complete-parent acceptance remains on parent .1.2 and transfers to .1.2.2 after the independent index-116 CPU outlier discovered by that run.`
  Verification: `Fresh guarded stage isolation on 2026-08-08 measures PPIF lowering at 1.196 s, Lispish parsing at 0.899 s, semantic construction at 0.150 s, flattening at 0.093 s, prescan at 0.004 s, and first-pass factorization at 1.533 s. Direct consolidated collection intermittently reaches 5.0-5.35 GiB, while executing the same merge/normalization flow without trace_fsm_signal_inventory stays between 121.7 and 123.8 MiB across all 1,158 helper records. Source inspection identifies the disabled-path eager Data::Dumper call at ConsolidatedIntermediateSupport.pm:106. The repair gates inventory traversal on enabled debug level 3; focused t1596 passes all six disabled/enabled contract assertions, both changed Perl files are syntax clean, and formerly failing zero-based pipeline entry 114 passes all three assertions in 28 seconds under the unchanged guard. The full guarded parent then progressed to index 116 with its worker bounded near 425 MiB but continuously CPU-bound inside direct SystemVerilog backend emission for more than one hour, proving a separate scaling defect rather than recurrence of entry 114's disabled-trace memory cliff.`
  Commit: `this commit (SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.1: own disabled trace repair)`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.2`
  Status: `done`
  Goal: `Bound the multi-static AXI capacity/status direct-backend CPU path without changing generated HDL.`
  Acceptance: `Exact pipeline index 116 completes within a declared guarded runtime bound without changing its generated HDL contract; its corresponding CLI fixture also completes below the unchanged guard; focused correctness and adjacent backend gates pass.`
  Verification: `Initial isolation identifies intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue_multi_static at zero-based pipeline index 116. PPIF lowering takes 7.754 s and emits the exact active 2,013,530-byte axi0_capacity_status.fsm artifact with SHA-256 29a6d16044b67381c110b4d56e245712272f78ca70c74d5f1df374b25b63b0c5; direct generation owns 18,429 consolidated intermediates. The original full-parent worker eventually reached 9464.2 MiB after roughly 65 minutes, correcting the interim near-425-MiB observation. Stage isolation found four compounding backend defects: scalar live-usage fallback rescanned every final/substitution AST for each intermediate; classification and assignment built full-expression diagnostics while level-3 tracing was disabled; classification recursively re-proved factorization eligibility for 48 enormous low-use logical ASTs even though usage below two makes filtering unconditional; and operand inventory called Data::Dumper on each connected semantic signal object while tracing was disabled. One bulk AST traversal now primes live-usage metadata, low-use logical classification short-circuits after existing live-use keeps, and expensive diagnostic payloads are gated before construction. The first complete-parent restart exposed a correctness flaw in that bulk traversal: string RHS parsing creates temporary AST roots, so retaining only their numeric refaddr in a global seen set allowed a reclaimed address to suppress a distinct later assignment. Parsed RHS roots now use per-root seen sets while owner-retained ASTs keep global deduplication. Deterministic t203 reuse coverage passes; guarded pipeline entries 11-14 pass in 3 and 28 seconds; exact pipeline index 116 passes in 660 seconds; and the same fixture at exact default-CLI index 202 passes in 699 seconds under the unchanged cap. Focused and adjacent correctness gates pass.`
  Commit: `resource implementation in 10badb9b4; parsed-RHS correctness correction in b76c5f63e`

- ID: `SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.1.2.3`
  Status: `active`
  Goal: `Make the complete t296 acceptance matrix interruption-resumable without reducing exact coverage.`
  Acceptance: `An explicit opt-in stores completed worker batches atomically below .artifacts/t296, binds them to the exact clean HEAD and test-contract version, reuses only valid completions after a guard interruption, fails closed on unsafe paths or malformed/mismatched state, leaves default no-checkpoint behavior unchanged, and removes the checkpoint after one final parent pass covers all four current cohorts.`
  Verification: `The latest guarded parent ran 194 minutes with no assertion failure, completing all 287 default-pipeline workers and default-CLI batches through index 199 before unrelated host occupancy crossed the unchanged 88% cutoff during batch 200-203. Exact default-CLI index 202 passes all three assertions in 699 seconds from a low-pressure start, so neither that fixture nor the repaired backend is a reproduced defect. The monolithic parent previously discarded more than three hours of green evidence after any host-pressure interruption. The opt-in checkpoint now validates a clean exact HEAD at startup, after each newly executed worker and before every reuse or final removal; strict schema/path/volume/symlink checks reject unsafe state, and same-directory sync-plus-rename publishes each completion atomically. Focused t1597 passes 18 contract assertions, a dirty-tree integration probe fails before state creation, and an ordinary isolated worker remains green. The implementation commit and complete checkpointed parent remain pending.`
  Commit: `implementation pending in this commit; complete checkpointed parent verification remains pending`

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
- `2026-08-08`: Preserve output semantics while making resource work
  proportional to owned data: prime live-usage evidence in one shared AST
  traversal, trust factorizer usage metadata where it makes a filter outcome
  unconditional, and guard expensive debug payload construction at the call
  site. The mdBook and `DEVELOPMENT_NOTES.md` do not change because public
  syntax, generated HDL policy, and user-visible behavior are unchanged; this
  task and its Knowledge Map card own the backend diagnostic constraint.
- `2026-08-08`: Deduplicate only owner-retained AST roots across the bulk
  live-usage traversal. Parsed string RHS roots are temporary, and a numeric
  `refaddr` does not remain a unique identity after reclamation; scan each such
  root independently so a later assignment can never lose liveness evidence.
- `2026-08-08`: Keep all four t296 cohorts and both resource cutoffs intact,
  but make the long parent gate explicitly resumable through atomic,
  repository-local completion state. Bind reuse to a clean exact HEAD plus a
  test-contract version, reject unsafe or invalid state rather than guessing,
  and delete the checkpoint only after the complete parent succeeds.

## Open Questions

- None requiring director input. `.1.2.3` owns test-run continuity without
  changing coverage, thresholds, product output, or default test behavior.

## Blockers

- No product implementation blocker remains. Active leaf `.1.2.3` has focused
  checkpoint and unchanged-worker proof; its implementation must commit cleanly
  before an exact-HEAD integration probe and the complete resumable parent can
  run. Indices 11-14, 114, pipeline 116, and its exact CLI fixture pass their
  isolated workers below the unchanged cap.

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

## Acceptance Checklist (.1.2.2 index-116 backend containment; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Dumper($signal)' --
  perl/FSM/Synthesis/EnableGraph/ModulePlanningSupport.pm
  perl/FSM/Synthesis/EnableGraph.pm` identifies commits `262e750be` and
  `0660e5e6f` for the eager module-planning diagnostic, while
  `git log -S'resolve_intermediate_signal_live_usage' --
  perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm` identifies
  `d32182686` for the scalar live-usage owner. Exact guarded probes then show
  the original worker at 9464.2 MiB, classification at 423-435 seconds, and
  operand inventory crossing 4.3-4.9 GiB before return; the branch census
  isolates 48 parser-created usage-one logical roots whose recursive policy
  result cannot affect filtering.
- [x] **ADDRESSED (verified)** — live usage is primed for all 18,429
  intermediates in one shared traversal; disabled classification, assignment,
  factorization-policy, and module-planning traces construct no expression or
  `Data::Dumper` payload; usage-one logical roots filter before recursive
  factorization discovery. Counted-payload focused tests pass, the repaired
  inventory returns in 0.041 seconds, and the exact uninstrumented zero-based
  pipeline index 116 completes all three assertions in 668 seconds under the
  unchanged 4096-MiB descendant cap.
- [x] **NO REGRESSION** — the exact guarded t296 worker reports `All tests
  successful` and `Files=1, Tests=3`; focused t204/t210/t216/t222/t226 reports
  `All tests successful` and `Files=5, Tests=9`. The guarded adjacent backend,
  planning, validation, and trace gate reports `All tests successful` and
  `Files=15, Tests=533`; the doctrine driver is run again from the staged
  implementation before commit. The complete guarded t296 parent remains the
  explicit next action, not a weakened or implied pass.

## Acceptance Checklist (.1.2.2 temporary parsed-RHS identity correction; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'prime_intermediate_signal_live_usage' --
  perl/FSM/Synthesis/EnableGraph/FactorizationSupport.pm` identifies
  `10badb9b4` as the bulk-cache introduction. The first complete-parent restart
  then failed consecutive pipeline entries 11-14 because assignment RHS
  references were declared but unassigned. Inspection locates the false
  negative in cross-assignment `refaddr` deduplication of temporary parsed RHS
  roots: Perl may reclaim one root and reuse its numeric address for a distinct
  later parse.
- [x] **ADDRESSED (verified)** — parsed string RHS roots now receive a local
  seen set for their own traversal, while context-owned AST roots retain global
  identity deduplication. A deterministic parser double returns one mutable AST
  object for two different RHS strings; t203 proves both referenced
  intermediates receive final-expression liveness.
- [x] **NO REGRESSION** — guarded t296 zero-based pipeline index 10 reports
  `All tests successful` (`Files=1, Tests=3`) in 3 seconds; indices 11-13 report
  `All tests successful` (`Files=1, Tests=9`) in 28 seconds; exact index 116
  reports `All tests successful` (`Files=1, Tests=3`) in 660 seconds under the
  unchanged cap. Focused t203/t204/t210/t216/t222/t225/t226 reports
  `All tests successful` (`Files=7, Tests=11`); the adjacent backend/planning/
  validation/trace gate reports `All tests successful` (`Files=15, Tests=531`),
  t1466 passes 12 assertions, and the changed Perl file is syntax clean. The
  doctrine driver runs again from the staged correction before commit.

## Acceptance Checklist (.1.2.3 exact-revision checkpoint implementation; enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'_assert_batched_acceptance'
  -- t/296-regression-corpus-supported-behavior.t` identifies `bfeb6d3ff` as
  the isolated-worker loop's introduction. That loop reports one parent TAP
  result per batch but retains no completion state; the 194-minute guarded run
  therefore lost all 287 green default-pipeline workers and 50 completed CLI
  batches when unrelated host occupancy crossed 88%.
- [x] **ADDRESSED (verified)** — `FSM::Test::T296Checkpoint` accepts only a
  safe `.artifacts/t296/*.json` path, exact clean-HEAD fingerprint, versioned
  schema, and same-volume non-symlink directory. It syncs a same-directory
  temporary file before atomic rename, reloads only exact batch keys, rechecks
  revision cleanliness before reuse/commit/removal, and clears state only when
  the parent builder remains green. A dirty-tree t296 probe fails before state
  creation with `t296 checkpointing requires a clean exact repository
  revision`.
- [x] **NO REGRESSION** — the guarded combined focused gate reports `All tests
  successful` and `Files=2, Tests=20`: t1597 proves 18 persistence, mismatch,
  malformed-state, unsafe-path, atomic-residue, symlink, and exact-removal
  contracts; an ordinary t296 default-pipeline worker retains its two passing
  assertions. All three changed Perl files report `syntax OK`; the full
  doctrine driver runs again from the staged implementation before commit.
