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
  Acceptance: `The four default/strict pipeline/CLI cohorts execute every selected entry in deterministic isolated batches, worker failures retain actionable TAP diagnostics, and the complete parent test passes under the unchanged 4096-MiB descendant cap.`
  Verification: `A clean-host guarded post-oracle run started at 55.7% host occupancy, ran for eight minutes without assertion output, then the single t296 Perl process reached 5369.8 MiB and was terminated at the unchanged 4096-MiB descendant cutoff. The audit now uses one-entry pipeline and four-entry CLI self-workers with fail-closed surface/suffix and worker-bound validation plus failed-worker TAP replay. A guarded 32-entry conservative pipeline worker passed all 92 assertions before batch tightening; resumable guarded verification then passed every default-pipeline entry through index 113, which includes all 62 divergent PPIF contracts, plus strict AHB/APB/AXI/bundle representatives and default/strict CLI AHB aggregate checks. The complete parent remains blocked by the separately owned macOS host-metric defect: with memory_pressure reporting 81-82% free and no large process, the unchanged guard reports 88-92% used after one to four workers and terminates the tree. No cutoff was raised or bypassed.`
  Commit: `worker implementation in this commit; complete guarded parent verification pending director direction on the existing guard-metric blocker`

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
  explicit owning leaf only after the director resolves this slice's RAM-guard
  closeout decision.

## Open Questions

- Director decision: authorize the already-proposed
  `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` safety-metric correction
  and then rerun the complete t296 parent, or accept the exact 240-entry census,
  all-62 default-pipeline proof, strict shape representatives, and focused
  no-regression gates as sufficient closeout evidence for this test-only task.

## Blockers

- The complete guarded t296 parent cannot currently finish because the known
  macOS host metric excludes reclaimable inactive/purgeable memory. Guarded
  attempts were stopped at reported 88-92% use while `memory_pressure`
  reported 81-82% free. Changing that safety mechanism requires director
  approval under the proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT`
  task; this slice did not raise or bypass either guard threshold.

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
