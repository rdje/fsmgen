# GITHUB-PUSH-OUTCOME-ASSURANCE: Verify Every Push Through Hosted CI

## Metadata

- Tree ID: `GITHUB-PUSH-OUTCOME-ASSURANCE`
- Status: `active`
- Roadmap lane: `infra/continuity / hosted-CI assurance`
- Created: `2026-08-11`
- Last updated: `2026-08-11`
- Owner: repo-local workflow
- Selected by: director request to audit the prior push and every future result

## Goal

After Git transport, verify the exact remote revision and every required GitHub
Actions result; diagnose and repair or track any non-success. Recover the
incomplete 2026-08-10 signoff before the next normal-cadence push.

## Non-Goals

- Do not treat a successful `git push` process as proof that hosted CI passed.
- Do not push before the standing 200-commit cadence unless the director
  explicitly requests an earlier push.
- Do not weaken product or regression contracts merely to obtain a green run.
- Do not claim the cancelled run covered tests after its six-hour limit.

## Acceptance Criteria

- Every push follow-up proves the local and remote revision relationship and
  records the terminal status and URL of every workflow for the pushed SHA.
- A failure, cancellation, timeout, or missing required workflow remains
  in-flight until its exact cause is diagnosed and repaired, rerun, or assigned
  to an explicit live blocker with recoverable evidence.
- Every observed failure from run `31367105225` is independently owned and
  verified; unexecuted tail coverage is not inferred from the cancelled run.
- The full hosted regression is structured to reach a conclusive terminal
  result within GitHub's job limit without reducing covered tests.
- `COMMIT.md` durably requires post-push GitHub result verification and failure
  remediation while preserving decision `0062`'s push cadence.
- Focused checks, the warranted broader regression, task-tree integrity,
  doctrine gates, and project-local artifact cleanup pass per slice.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE`
  Status: `active`
  Goal: `Recover the last pushed SHA's hosted-CI failures and make terminal GitHub result verification mandatory after every future push.`
  Children: `GITHUB-PUSH-OUTCOME-ASSURANCE.1, GITHUB-PUSH-OUTCOME-ASSURANCE.2, GITHUB-PUSH-OUTCOME-ASSURANCE.3, GITHUB-PUSH-OUTCOME-ASSURANCE.4, GITHUB-PUSH-OUTCOME-ASSURANCE.5, GITHUB-PUSH-OUTCOME-ASSURANCE.6, GITHUB-PUSH-OUTCOME-ASSURANCE.7`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.1`
  Status: `done`
  Goal: `Audit the push eight commits behind the original session frontier, enumerate every observed hosted failure, and select exact recovery slices.`
  Acceptance: `Prove the pushed SHA and transport result; enumerate every workflow terminal status and URL; distinguish the successful Knowledge Map and mdBook workflows from the cancelled Perl regression; extract every observed failed test file/subtest from run 31367105225; prove the six-hour cancellation boundary and explicitly mark the unexecuted tail unknown; reproduce at least one platform-sensitive failure locally before selecting the repair leaves.`
  Verification: `origin/main reflog records update-by-push at 2026-08-10 09:44:39 +0200 to de9d50a5fb17074d29615ea866cd3cc6af503a3b (HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.2.4.2: generate execution type gate), proving transport success. Exact-SHA gh run list reports knowledge-map-gate run 31367105202 success, Publish mdBook run 31367105199 success, and Perl FSM Regression run 31367105225 completed/cancelled. The regression started 2026-08-10T07:44:41Z and ended 2026-08-10T13:45:25Z at the six-hour hosted-job boundary. Its logs enumerate observed failures in t/1247 (portable VHDL keyword child name prevents CLI HDL generation), t/1255 (schedule_report_verification_bridge_event_keys lacks a golden-matrix owner), t/132 (stale default-output help expectation), five failed t/1437 top-level subtests spanning mixed runtime ARLEN, mixed/depth-3 multi-beat initialization, RLAST port spelling, and obsolete sequential-pulse spelling, plus two observed t/1438 dynamic RLAST cases. A sorted inventory proves 1,103 test files follow the in-progress t/1438 dynamic test and were never reached. The repository-local filtered t/1438 command reproduced line 1253 RED against generated `input wire axi0_rlast`; it was deliberately interrupted after exact reproduction because the substring filter also selected four unrelated hour-scale fixtures. No production, test, CI, or policy behavior changes in this audit leaf.`
  Commit: `this commit (hosted result audit and recovery decomposition)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.2`
  Status: `done`
  Goal: `Repair the hosted CLI contract failures in t/1247 and t/132 while preserving portable identifiers and repository-relative output policy.`
  Acceptance: `Replace the t/1247 fixture's VHDL-reserved child-instance identifier without weakening portable validation, and align t/132 with the canonical repository-root-relative default output contract rather than a current-working-directory assumption; focused tests pass and no persisted project path depends on an absolute checkout path.`
  Verification: `The pre-fix guarded t/1247/t/132 run reproduced both hosted failures: the file-backed multi-domain fixture generated ?fsmc:bus, which portable HDL validation rejected because bus is VHDL-reserved before the requested output could exist, and t/132 expected obsolete current-working-directory help text instead of the shipped .artifacts/<language>/<fsm_name>.<ext> contract. All three public event-crossing fixtures now use portable domain child name source while retaining their bus-facing clocks and signals; exact generated-artifact, report, wiring, test-description, and mdBook examples agree. t/132 now verifies the canonical repository-local language-specific output. The RAM-guarded t/1247/t/132/t/1463 regression reports All tests successful at Files=3, Tests=20. Every mdBook chapter test passes, the repository-local HTML build succeeds, and its exact ignored 88-file/18-MiB output is removed. The shipped_behavior authority records the exact 0-line/+93-byte book delta with no ceiling increase. No compiler, parser, lowering, generated-HDL, or output-placement behavior changed.`
  Commit: `this commit (portable fixture and current CLI-help contract repair)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.3`
  Status: `done`
  Goal: `Restore complete schedule-report golden-matrix ownership for every advertised branch.`
  Acceptance: `All eight advertised schedule_report_verification_bridge_* key families have one truthful emitted-report matrix owner or are removed from advertising by their canonical owner; the owner exercises the public generated-IAL1 route rather than a synthetic hash, and the focused matrix test plus its relevant schedule-report cluster pass without suppressing discovery. The hosted failure displayed only schedule_report_verification_bridge_event_keys because is_deeply reports the first array difference; a local contract-to-matrix census proves event, fact, field, top-level bridge, probe, protocol, source, and transaction key families are all currently unowned.`
  Verification: `The local RED reproduces the hosted t/1255 failure at line 47 (Files=1, Tests=2), and an exact contract/covers census proves all eight advertised verification-bridge key families lacked owners; Test::More displayed only the lexicographically first event-key difference. The new verification_bridge case obtains generated IAL1 text from the tracked public ppif/ahb_lite_subordinate.ppif through FSM::Adapter::IAL2::PPIF, then compares its in-process schedule report with CLI --emit-schedule-json before checking exact bridge, protocol, fact, transaction, field, source, event, and probe key families. The test is syntax-clean and focused t/1255 passes. The RAM-guarded public contract/JSON/defensive-copy/manifest/key-family/discovery/report/freeze/golden-matrix/ordinary-null/AHB-bridge cluster reports All tests successful at Files=11, Tests=22. No production contract, parser, scheduler, IAL2 generation, public capability, or mdBook behavior changed; the book's existing claim that every advertised branch has an executable owner is now true.`
  Commit: `this commit (complete real verification-bridge matrix ownership)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.4`
  Status: `done`
  Goal: `Reconcile all five failed t/1437 IAL2 generator subtests with current generated IAL1, IAL0, and SystemVerilog behavior.`
  Acceptance: `Root-cause the mixed runtime-ARLEN assertion, mixed and depth-3 multi-beat initialization expectations, and the two dynamic RLAST queue subtests; correct production behavior where the contract is violated and correct tests only where equivalent current lowering is valid; all five red subtests and the warranted IAL2 regression cluster pass.`
  Verification: `The hosted failures were test drift, not production defects: the runtime assertion expected an internal assertion identifier although generated IAL1 exposes its quoted human message; the two output-bank checks expected unsized zeroes in stale order although the generator has always emitted width-correct RDATA/RRESP/valid-mask/read-count zeroes; generated SystemVerilog legally spells the exact RLAST input as input wire; and completion pulses use the canonical one-cycle delay pipe rather than an obsolete direct sequential assignment. Git history dates all five stale expectations to 2026-06-25/26, after the relevant assertion, typed-literal, port, and pulse-delay generator behavior. The repaired checks now require the exact emitted message, typed values and bank ordering, exact RLAST signal with an optional wire token, and the actual delay-pipe enable assignment. A temporary top-level selector was removed after each of the five exact formerly red cases independently reported All tests successful at Files=1, Tests=1 (7s, 10s, 7s, 400s, and 471s); nested IAL1, IAL0, report, and SystemVerilog assertions remained enabled. Monolithic attempts were safely stopped by the 88% host RAM cutoff, first amid unrelated pgen Rust LTO pressure and then from process-lifetime accumulation, so no incomplete run is claimed. The committed-form test is syntax-clean, and the RAM-guarded regression-corpus/capability-manifest pair reports All tests successful at Files=2, Tests=7096. Production and user-visible behavior are unchanged, so the already-accurate mdBook needs no edit.`
  Commit: `this commit (align five stale IAL2 generator expectations)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.5`
  Status: `pending`
  Goal: `Make the two observed t/1438 RLAST port checks accept semantically equivalent SystemVerilog net spelling.`
  Acceptance: `Both depth-2 and depth-3 dynamic RID/RLAST cases accept generated input ports with or without an explicit wire token, still require the exact axi0_rlast input, and pass the focused filtered test plus a broader neighboring contract check.`
  Verification: `pending`
  Commit: `pending`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6`
  Status: `pending`
  Goal: `Make the full Perl regression produce conclusive GitHub results within the hosted job limit without reducing coverage.`
  Acceptance: `Measure the current suite and slow-test distribution; partition or otherwise bound hosted execution so every t/ test is covered exactly as intended, failures surface promptly, artifacts remain repository-local, and all required jobs reach terminal results within configured GitHub limits; do not mask remaining failures behind fail-fast or cancellation.`
  Verification: `pending`
  Commit: `pending`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.7`
  Status: `pending`
  Goal: `Codify mandatory post-push GitHub workflow verification and failure remediation in the authoritative commit workflow.`
  Acceptance: `COMMIT.md requires exact pushed-SHA/upstream verification, terminal inspection of every required GitHub workflow with URLs, continued waiting for queued/in-progress jobs, and diagnosis plus repair or explicit live blocking of every non-success; documentation and enforcement remain consistent with decision 0062 and no early push is introduced.`
  Verification: `pending`
  Commit: `pending`

## Decisions

- `2026-08-11`: Treat the cancelled regression as incomplete and failed
  signoff. Git transport, two green workflows, and an eventual cancellation do
  not erase the test failures already emitted or prove the unexecuted tail.
- `2026-08-11`: Split recovery by failure family so a simple SystemVerilog
  formatting expectation cannot conceal unrelated CLI, coverage-map, IAL2,
  and hosted-runtime defects.

## Open Questions

- Which tests remained unexecuted when the hosted regression reached six
  hours? Leaf `.6` must derive this from the ordered test inventory rather than
  infer it from the last visible file.

## Blockers

- None.

## Acceptance Checklist — `.4` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted run `31367105225` emits its first
  concrete Test::More diagnostic at t/1437-axi-ial2-manager-capacity-status-generator.t line 1254 and reports
  the remaining stale expectations at lines 1289, 1413-1414, 1442, and 1566.
  Their 2026-06-25/26 expectations
  postdate the generator's canonical assertion-message, typed-literal,
  explicit-net, and delayed-pulse behavior and therefore describe stale text
  forms rather than contract violations.
- [x] **ADDRESSED (verified)** — The five checks now require the exact emitted
  assertion message, width-correct bank initialization values in generated
  order, the exact RLAST port with equivalent optional `wire`, and the actual
  completion delay-pipe assignment. The changed test is syntax-clean, and each
  formerly red top-level case independently reports `All tests successful` at
  `Files=1, Tests=1` with all nested assertions enabled.
- [x] **NO REGRESSION** — The RAM-guarded regression-corpus and capability-
  manifest pair reports `All tests successful` at `Files=2, Tests=7096`.
  Monolithic attempts stopped safely at the 88% RAM cutoff and are not claimed
  as passes. Production and user-facing behavior are unchanged, so the
  already-accurate mdBook needs no edit.
