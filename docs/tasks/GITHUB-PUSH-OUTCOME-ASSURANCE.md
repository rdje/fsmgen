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
  Status: `done`
  Goal: `Make the two observed t/1438 RLAST port checks accept semantically equivalent SystemVerilog net spelling.`
  Acceptance: `Both depth-2 and depth-3 dynamic RID/RLAST cases accept generated input ports with or without an explicit wire token, still require the exact axi0_rlast input, and pass the focused filtered test plus a broader neighboring contract check.`
  Verification: `Hosted run 31367105225 and the local RED identify strict RLAST regexes at t/1438 lines 1226 and 1253: both required input axi0_rlast even though canonical generated SystemVerilog spells the same scalar input net as input wire axi0_rlast. Git blame traces the expectations to the original depth-2 and depth-3 queue tests on 2026-06-25; adjacent current HDL checks already permit the equivalent optional net token. The two repaired regexes still require the exact axi0_rlast input and accept only an optional wire token before it. The changed test is syntax-clean. Unique full-PPIF filters avoid the earlier broad substring collision: the exact depth-2 case reports All tests successful at Files=1, Tests=6 in 24s, the exact depth-3 case reports All tests successful at Files=1, Tests=6 in 907s, and the adjacent mixed dynamic/static RID/RLAST contract reports All tests successful at Files=1, Tests=6 in 23s. All runs were RAM-guarded. No generator, IAL1, IAL0, SystemVerilog, report, CLI, or user-visible behavior changed, so the already-accurate mdBook needs no edit.`
  Commit: `this commit (accept equivalent RLAST net spelling)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6`
  Status: `active`
  Goal: `Make the full Perl regression produce conclusive GitHub results within the hosted job limit without reducing coverage.`
  Children: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.1, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.1`
  Status: `done`
  Goal: `Implement and locally prove a closed hosted partition that isolates both file-level and in-file runtime outliers.`
  Acceptance: `Measure the current suite and observed slow-test distribution; partition every tracked t/*.t file exactly once except an explicitly isolated in-file outlier; partition every canonical case of that outlier exactly once; keep local full regression unchanged; disable matrix fail-fast; bound every long job below GitHub's six-hour maximum; keep artifacts repository-local; preserve one required aggregate result.`
  Verification: `Cancelled run 31367105225 yields 496 sequential suite-file completions before t/1438: t/1436 consumed 10,027 seconds, t/1437 consumed 6,561 seconds, and the next observed interval was 92 seconds. The current tracked inventory is 1,600 test files. Sixteen deterministic ordinary shards cover the 1,599 non-outlier files exactly once at 100 files for shards 0-14 and 99 for shard 15; the measured t/1436 and t/1437 outliers land separately in shards 14 and 15. Sixty-eight dynamic shards cover the exact 68-case t/1438 inventory one case per process; its four shared non-matrix checks run only on shard zero, while unsharded and explicit-filter behavior remain intact. Both matrices set fail-fast false and five-hour timeouts; doctrine and book jobs are independent, and the always-run build aggregate rejects any non-success family. Focused t/1183 proves both complete/disjoint unions, all 84 matrix coordinates, fail-closed arguments, unchanged local full selection, and aggregate wiring at Files=1/Tests=9 in 28 seconds. A real guarded hosted-style dynamic shard 0/68 passes at Files=1/Tests=6 in 9 seconds; the previously verified depth-3 case completed in 907 seconds, far below the new five-hour per-case ceiling. Decision 0063 owns the architecture, one exact 1108-to-1109 Knowledge-card ceiling authority, finite transition deltas, and the exact 0-file/+5-line/+373-byte mdBook authority. The focused containment/ceiling/reference suite passes at Files=3/Tests=30; live containment covers all 2,979 declared Markdown paths, Memory is 46 lines, and Knowledge Map reports 1,109 facts/5,764 questions/5,930 occurrences/121 shards. Bash/Perl syntax, workflow YAML loading, task integrity, all 53 mdBook chapter tests, and the repository-local 88-file/18,312-KiB build pass; the build output is removed exactly. No parser, generator, HDL, protocol, CLI-result, or local full-gate behavior changes.`
  Commit: `this commit (closed hosted file/case regression partition)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2`
  Status: `active`
  Goal: `Prove downstream-consumer contracts are lockstep with the hosted-CI repairs, then qualify the new partition on GitHub for the exact next pushed revision and remediate every non-success.`
  Acceptance: `Before any push, inventory and audit the canonical integration/handoff contracts used by downstream consumers such as SPECFORGE against every repair since the last pushed SHA; synchronize any real schema, API, artifact, report, diagnostic, capability, support, or compatibility drift with the codebase and mdBook, or record exact evidence that the repairs are private/test/workflow-only and the public contracts remain accurate. Then, at the next cadence-authorized or director-authorized push, prove the exact remote SHA; wait for all doctrine, book, 16 ordinary-file, 68 dynamic-case, and aggregate jobs to become terminal; record every URL and conclusion; repair and requalify any failure, timeout, cancellation, skipped required job, missing shard, or aggregate mismatch before marking .6 done.`
  Verification: `Director clarification on 2026-08-11 defines handoff/contract as the downstream integration surfaces consumers such as SPECFORGE ingest, not merely continuity documents. Child .6.2.1 owns the pre-push contract audit and any required lockstep synchronization; .6.2.2 retains exact hosted qualification. Decision 0062 still forbids an automatic early push below the 200-commit cadence.`
  Commit: `pending children`
  Children: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.1, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.1`
  Status: `done`
  Goal: `Audit and synchronize the canonical downstream-consumer integration contracts before the repaired branch can be pushed.`
  Acceptance: `Derive the canonical SPECFORGE/general-consumer handoff set from maintained docs, capability/support surfaces, tests, Knowledge Map, and history; classify every hosted-CI repair from the last pushed SHA through the current frontier by downstream-visible contract impact; compare the implementation, emitted schemas/reports/artifacts/diagnostics, public API/CLI, capability manifest, support accounting, contract docs, SPECFORGE response, and mdBook. Update every genuinely drifted surface in one lockstep slice, or record an exact no-drift matrix where behavior did not change. Do not turn private qualification or test/workflow behavior into a public promise, and do not push.`
  Verification: `The audit classifies all 19 commits after upstream de9d50a5 through activation commit c053aad7: regression workflow/shard changes are internal CI infrastructure; t/1255, t/1437, and t/1438 are qualification-only corrections; the private VIAL scale helper is not a public API; t/1247's portable fixture rename is already synchronized in the relevant mdBook chapters; and t/132 repairs a stale test without changing shipped help. An exact archived-upstream/current comparison proves byte-identical CLI help (SHA-256 c6db5fd1...) and strict schedule JSON (4210c035...), plus identical capability manifest (3b3e514e...), check JSON (b0899cc8...), and semantic JSON (fab32eab...) after normalizing only documented revision/path provenance. README, the general and SPECFORGE handoff pages, ISF landing/public contracts, bridge/backend contracts, support accounting, and mdBook were otherwise accurate. Nineteen canonical ISF handoff commands nevertheless violated project-data locality by naming /tmp; they now use repository-relative .artifacts/ial1 or .artifacts/sv destinations. The focused downstream contract suite reports All tests successful at Files=7, Tests=41 in 26 seconds. All 53 mdBook chapter tests and the repository-local 88-file/18,336-KiB build pass; the exact build output is removed. Project-data locality passes, and regenerated Knowledge Map checks at 1,109 facts/5,765 questions/5,931 occurrences/121 shards. The director separated the unchanged source.resolved_path question into proposed tree DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT, so it no longer blocks this completed audit or the authorized repaired push.`
  Commit: `aef4a3342 (downstream contract audit and locality synchronization)`
  Children: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.1.1`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.1.1`
  Status: `superseded`
  Goal: `Reconcile public source.resolved_path provenance with the repository-relative path doctrine without surprising downstream consumers.`
  Acceptance: `Select and document either an explicit narrow exemption for read-only ephemeral source provenance or a versioned/backward-compatible migration to a repository-relative representation. If migration is selected, synchronize implementation, schemas, diagnostics, capability/support surfaces, downstream integration contracts, SPECFORGE handoff, mdBook, and tests in one owned compatibility slice. Do not push while the public contract decision is unresolved.`
  Verification: `Current ReportSourceContract, CheckDiagnostics, and NormalizedSemanticReport code emits absolute source.resolved_path; the public docs describe a resolved path, backend parity guidance explicitly normalizes it, and t/299/t/302/t/303/t/304 plus later PPIF/IAL2 tests require rel2abs or abs_path. Exact upstream/current comparison proves this behavior predates and is unchanged by the CI repair. On 2026-08-11 the director authorized the repaired push and assigned this independent compatibility/policy work to proposed top-level tree DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT.`
  Commit: `this commit (transfer provenance policy to independent proposed tree)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2`
  Status: `active`
  Goal: `Qualify the new hosted partition and exact repaired revision on GitHub.`
  Acceptance: `At the next cadence-authorized or director-authorized push, prove the exact remote SHA; wait for all doctrine, book, 16 ordinary-file, 68 dynamic-case, and aggregate jobs to become terminal; record every URL and conclusion; repair and requalify any failure, timeout, cancellation, skipped required job, missing shard, or aggregate mismatch before marking .6 done.`
  Verification: `Director-authorized push a28e9adf46b7861ee728703662ad18b64f0325d0 has exact local/upstream/remote equality. Knowledge Map run 31494487149 and Publish mdBook run 31494487147 are completed/success. Regression run 31494487181 instantiated exactly 16 ordinary and 68 dynamic shards plus doctrine/mdBook support jobs; fail-fast remains disabled. Completed job 93788675553 (Perl files 12/16) failed five test files: t1506/t1520/t1535 because the hosted image lacks Verilator/Yosys, t370 on the already-known two-key verification_outputs discovery drift, and t40 because its regex requires redundant parentheses absent from semantically equivalent current HDL. Remaining jobs continue collecting evidence.`
  Commit: `pending`
  Children: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.1, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.2, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.3, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.4`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.1`
  Status: `done`
  Goal: `Provision the external HDL tools required by hosted ordinary shards.`
  Acceptance: `Reproduce the t1506/t1520/t1535 missing-tool failures from job 93788675553; install deterministic Verilator and Yosys profiles before hosted shard execution without changing local full selection; prove the three exact tests and shard plumbing; update workflow guidance and mdBook only if the supported public tool contract changes.`
  Verification: `GitHub job 93788675553 reports Missing external HDL validation tool(s): verilator, yosys; jobs 93788675417, 93788675536, 93788675550, and 93788675569 independently repeat the same mechanism across other verifier and executable-harness tests. The ordinary matrix now pins ubuntu-24.04 plus exact Ubuntu Noble package revisions verilator=5.020-1 and yosys=0.33-5build2, verifies each installed dpkg revision, and prints both runtime versions before test selection. Canonical package records are https://packages.ubuntu.com/noble/verilator and https://packages.ubuntu.com/noble/yosys. Dynamic shards remain Perl-only because t/1438 contains no Verilator, Yosys, or external-validation invocation. Ruby parses the workflow YAML. Focused t/1183/t1506/t1520/t1535 passes at Files=4, Tests=20 in 95 seconds; t308 exercises generic Verilator lint, ABC-free and ABC-backed Yosys synthesis, 15 MIPI fixtures, historical fixtures, direct/composed protocols, and CLI verification at Files=1, Tests=8. All mdBook chapters test and build successfully; project-data locality passes and the exact generated book is removed. This CI-only repair changes no public CLI, schema, generated HDL, mdBook behavior, downstream handoff contract, or exact Verilator 5.046 VIAL backend qualification.`
  Commit: `this commit (provision pinned hosted HDL validation tools)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.2`
  Status: `done`
  Goal: `Restore exact verification_outputs discovery-map alignment exposed by hosted t370.`
  Acceptance: `Transfer the pre-existing proposed audit into this active recovery leaf; prove whether guidance and json_safe_when_embedded_in_public_manifest belong in the grouped discovery map, synchronize every public manifest projection, and pass t370 plus adjacent contract/round-trip/defensive-copy tests without changing generated verification artifacts.`
  Verification: `Job 93788675553 shows guidance at the first differing index where the discovery owner expects observation_entry_keys, in-process and through both CLI spellings. Commit d867815f3 introduced a VerificationOutputsSection that spreads the full contract, including guidance and json_safe_when_embedded_in_public_manifest, beside two hand-copied top-level discovery lists that omitted those keys. verification_outputs_public_top_level_keys() now includes both live fields and capability_manifest_verification_outputs_keys() delegates to it, leaving one canonical list. t370 additionally requires the section builder plus the in-process, CLI, and CLI-alias payloads to advertise their own exact keys. Thirteen adjacent manifest/discovery/round-trip/defensive-copy tests pass at Files=13, Tests=42; six ISF public-contract, guidance, live-book-path, UVM/VHDL verification-output, and relative-path tests pass at Files=6, Tests=35. The mdBook and downstream handoff now name the exact no-exception discovery rule. Every chapter tests, the HTML build succeeds and is removed, locality passes, and the 14-file ISF reference authority verifies the exact 14,564-line/880,624-byte baseline plus 7-line/405-byte delta without raising a ceiling. Generated verification artifacts, their version-1 manifests, CLI modes, schemas, and backend behavior are unchanged.`
  Commit: `this commit (restore exact verification-output discovery metadata)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.3`
  Status: `pending`
  Goal: `Make t40 accept the canonical semantically equivalent unary-not HDL spelling.`
  Acceptance: `Use history and generated HDL to prove whether parentheses are contractually required; if not, make the test accept only the exact factored intermediate with or without redundant parentheses while retaining all negated AND/OR/XOR checks; pass focused and adjacent language-expression tests.`
  Verification: `Job 93788675553 emits A = !intermediate_and_B_C_1; while t40 requires A = !(intermediate_and_B_C_1); and fails solely on that formatting distinction.`
  Commit: `pending implementation`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.4`
  Status: `pending`
  Goal: `Remove the hosted Node 20 action-runtime deprecation before fallback removal becomes a CI outage.`
  Acceptance: `Audit every action annotation and current upstream action runtime; upgrade affected pinned major versions or record a bounded incompatibility with authoritative evidence; prove checkout, mdBook, Knowledge Map, and regression workflows remain green without enabling the insecure Node fallback.`
  Verification: `All exact-SHA workflows annotate that actions/checkout@v4, and mdBook also peaceiris/actions-mdbook@v2, target deprecated Node 20 and are currently forced onto Node 24 by GitHub.`
  Commit: `pending after blocking test failures`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.7`
  Status: `done`
  Goal: `Codify mandatory post-push GitHub workflow verification and failure remediation in the authoritative commit workflow.`
  Acceptance: `COMMIT.md requires exact pushed-SHA/upstream verification, terminal inspection of every required GitHub workflow with URLs, continued waiting for queued/in-progress jobs, and diagnosis plus repair or explicit live blocking of every non-success; documentation and enforcement remain consistent with decision 0062 and no early push is introduced.`
  Verification: `COMMIT.md now distinguishes transport success from hosted success; requires the local HEAD, configured upstream, and git ls-remote branch SHA to agree; derives the expected push-workflow set rather than trusting only discovered runs; queries GitHub by the full pushed SHA; waits every queued/requested/waiting/pending/in-progress run to terminal; records every workflow name, URL, status, and conclusion; inspects required job/matrix inventories where an aggregate could conceal incomplete work; and accepts only completed/success. Every missing or non-success result now requires failed-log diagnosis plus task-tree-owned repair, authorized rerun, or an explicit live blocker with recoverable URLs. The policy explicitly preserves decision 0062: remediation does not authorize an early push. Local gh run list/watch/view help confirms the documented filters, JSON fields, terminal-status vocabulary, watch command, job inventory, and failed-log interface. Focused text assertions, task-tree integrity, bounded Memory, and the full staged doctrine gate pass; the thin .agents wrapper remains unchanged because it already delegates all policy to COMMIT.md. This governance-only slice changes no product, CI definition, test, or user-facing mdBook behavior.`
  Commit: `this commit (mandatory exact-SHA post-push result qualification)`

## Decisions

- `2026-08-11`: Pin hosted ordinary shards to Ubuntu 24.04 and the repository
  packages Verilator 5.020-1 and Yosys 0.33-5build2. These versions exercise
  the ordinary suite's generic lint/synthesis/harness contract; they do not
  replace the exact Verilator 5.046 public VIAL backend qualification, whose
  exact-version tests remain independently guarded.
- `2026-08-11`: Make `verification_outputs_public_top_level_keys()` the sole
  owner of the verification-output section's top-level discovery family.
  Adding the two already-live omitted names repairs additive discovery
  metadata; it does not widen the payload or require an artifact schema bump.

- `2026-08-11`: Treat the cancelled regression as incomplete and failed
  signoff. Git transport, two green workflows, and an eventual cancellation do
  not erase the test failures already emitted or prove the unexecuted tail.
- `2026-08-11`: Split recovery by failure family so a simple SystemVerilog
  formatting expectation cannot conceal unrelated CLI, coverage-map, IAL2,
  and hosted-runtime defects.
- `2026-08-11`: Preserve the ordinary local full gate, but host it as a closed
  union of 16 deterministic file shards and 68 one-case dynamic outlier
  shards. Disable fail-fast and retain an always-run aggregate so failures are
  isolated without being cancelled or hidden.
- `2026-08-11`: Treat transport success and hosted success as separate
  evidence. Every pushed SHA must be followed to an exact, terminal workflow
  inventory; remediation remains subject to the standing push cadence.
- `2026-08-11`: Define handoff/contract as the public integration surfaces
  consumed by SPECFORGE and other downstreams. Audit those surfaces against
  code and emitted artifacts before every repaired push, not merely the
  repository's session-continuity documents.
- `2026-08-11`: Director-authorize an immediate early repaired push and move
  the unchanged absolute source-provenance compatibility question to proposed
  tree `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT`; it does not block `.6.2.2`.
- `2026-08-11`: Treat regression job 93788675553 as a real failed qualification
  and preserve all five test files under explicit repair leaves while the
  non-cancelling matrix continues to reveal the rest of the hosted result.

## Open Questions

- None for the repaired push. `DOWNSTREAM-SOURCE-PROVENANCE-CONTRACT.1` owns
  the independent migration-versus-exemption compatibility decision.

## Blockers

- Local remediation is unblocked. After verified repairs, a new early repair
  push still requires director authorization under decision `0062`; the
  current authorization was consumed by push `a28e9adf4`.

## Acceptance Checklist — `.6.2.2.1` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788675553` reports `Missing external HDL validation tool(s): verilator, yosys`, then fails t1506/t1520/t1535 at their public verification and executable-harness assertions. `git log -S'apt-get install' -- .github/workflows/regression.yml` returns no commit: the ordinary shard job selected tool-requiring tests but its setup installed only Perl.
- [x] **ADDRESSED (verified)** — The ordinary job now pins `ubuntu-24.04`, installs exact Noble packages `verilator=5.020-1` and `yosys=0.33-5build2`, checks both dpkg revisions, and emits both tool versions before executing its shard. t1183 locks those invariants and proves the unrelated dynamic job has no HDL-tool installation; Ruby reports `workflow YAML parses`.
- [x] **NO REGRESSION** — Focused workflow plus exact hosted reproductions report `All tests successful` at `Files=4, Tests=20`; generic external validation separately reports `All tests successful` at `Files=1, Tests=8`, including `verilator_lint` and `yosys_synthesis`. Every mdBook chapter tests successfully, the HTML build completes, project-data locality reports OK, and the exact generated book is removed. The staged doctrine driver reports `[doctrine] all doctrine checks passed`.

## Acceptance Checklist — `.6.2.2.2` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'json_safe_when_embedded_in_public_manifest' -- perl t docs/book` locates the original verification-output contract introduction at `d867815f3`; the section spread the full contract, while two independent hand-copied discovery lists omitted `guidance` and `json_safe_when_embedded_in_public_manifest`.
- [x] **ADDRESSED (verified)** — One canonical `verification_outputs_public_top_level_keys()` list now owns both projections and includes both live fields. t370 proves the section's self-advertisement plus grouped discovery for the direct builder, in-process manifest, `--capability-manifest`, and `--emit-capability-manifest`; all views are exact.
- [x] **NO REGRESSION** — Adjacent capability discovery, contract, JSON-round-trip, and defensive-copy coverage reports `All tests successful` at `Files=13, Tests=42`; downstream public-interface and verification-output coverage reports `All tests successful` at `Files=6, Tests=35`. All mdBook chapters and the HTML build pass, the build is removed, project locality and ISF partition checks pass, and the staged doctrine driver reports `[doctrine] all doctrine checks passed`.

## Acceptance Checklist — `.6.2.1` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'/tmp/isf-build' --oneline -- docs/isf-spec/01-purpose-source-timing.md docs/isf-spec/10-downstream-readiness-source.md docs/isf-spec/13-downstream-diagnostics-conformance.md` traces the stale examples to containment commit `ea1b76dd5`; a canonical handoff census finds 19 off-volume `/tmp` output commands. Exact archived-upstream/current `--check --json` and `--emit-semantic-json` comparisons separately prove the absolute `source.resolved_path` contract predates the CI repair and therefore cannot be silently folded into this locality correction.
- [x] **ADDRESSED (verified)** — All 19 handoff commands now derive outputs beneath repository-relative `.artifacts/ial1` or `.artifacts/sv`; the ISF maintained-reference authority records the exact 14-file/14,564-line aggregate transition from 880,417 to 880,624 bytes without raising a ceiling. `scripts/check_project_data_locality.sh` reports `[project-data-locality] OK`, and the unresolved public JSON provenance choice is isolated under active child `.6.2.1.1` before push.
- [x] **NO REGRESSION** — The downstream contract suite reports `All tests successful` at `Files=7, Tests=41`; all 53 mdBook chapter tests and the repository-local 88-file/18,336-KiB build pass, and the exact build output is removed. Knowledge Map regeneration/check reports `knowledge-map: OK` at 1,109 facts/5,765 questions/5,931 occurrences/121 shards. The full staged doctrine driver reports `[doctrine] all doctrine checks passed`; emitted public behavior is unchanged by this documentation/config-authority slice.

## Acceptance Checklist — `.7` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Mandatory post-push GitHub qualification' --oneline -- COMMIT.md` returns no commit, and `git show HEAD:COMMIT.md | rg -n 'Push cadence|Required order of operations|gh run|post-push'` finds only the cadence heading and step 12's cadence reference. The authoritative workflow therefore ended after transport/ahead-count handling and neither required exact-SHA GitHub result consumption nor preserved such a rule mechanically.
- [x] **ADDRESSED (verified)** — `scripts/check_doctrine_bootstrap.sh` now checks seven specific COMMIT.md markers covering remote-SHA proof, exact-commit run discovery, terminal waiting, failed-log diagnosis, success-only acceptance, and no implicit early push. The real policy passes; a temporary one-marker mutation fails with `COMMIT.md lacks post-push contract marker` and restoring the marker returns the checker to green. Local `gh run list/watch/view --help` confirms every documented command, filter, JSON field, status, job-inventory, and failed-log interface.
- [x] **NO REGRESSION** — `scripts/check_doctrines.sh` reports `[doctrine] all doctrine checks passed`; task-tree integrity and bounded Memory also pass. Decision `0062`'s 200-commit threshold and explicit early-push exception are unchanged, the thin agent wrapper still delegates to COMMIT.md, and no product, CI definition, regression selection, generated artifact, or mdBook behavior changes.

## Acceptance Checklist — `.6.1` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — `.github/workflows/regression.yml` ran one
  unbounded sequential `./bin/ci-regression` job. Hosted run `31367105225`
  measured 10,027 seconds in `t/1436`, 6,561 seconds in `t/1437`, then entered
  the 68-case `t/1438` until GitHub cancelled the job at six hours, concealing
  1,103 later files. Its diagnostic stream also records
  `# at t/1437-axi-ial2-manager-capacity-status-generator.t line 1254`. File-only
  sharding would leave the in-file outlier intact.
- [x] **ADDRESSED (verified)** — `bin/ci-regression` now exposes zero-based,
  fail-closed hosted file/case shard plumbing while leaving its default full
  command unchanged. The workflow schedules all 16 file coordinates and all
  68 one-case dynamic coordinates with five-hour ceilings and fail-fast
  disabled. Focused `t/1183` proves exact disjoint unions for 1,599 ordinary
  files and 68 dynamic cases; a real guarded `0/68` invocation passes all six
  top-level tests in nine seconds.
- [x] **NO REGRESSION** — The measured `t/1436` and `t/1437` files land in
  distinct ordinary shards, and the known slow depth-3 dynamic case previously
  passed in 907 seconds, below the new 300-minute job ceiling. Bash/Perl syntax,
  workflow YAML loading, the Files=3/Tests=30 containment/authority suite,
  reports `All tests successful` at `Files=3, Tests=30`. Knowledge Map
  generation/check/query, task integrity, bounded Memory, all 53 mdBook chapter
  tests, and the repository-local mdBook build pass; its exact
  88-file/18,312-KiB output is removed. Decision `0063` authorizes the one exact
  Knowledge-card ceiling step and fresh book/transition deltas without changing
  any unrelated ceiling. Product and local full-gate behavior remain unchanged.
  Exact hosted terminal qualification is explicitly retained by `.6.2` for the
  next authorized push rather than inferred locally.

## Acceptance Checklist — `.5` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted run `31367105225` emits the strict
  depth-2 RLAST diagnostic at t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t line 1226 and the equivalent depth-3 diagnostic at line 1253. Both
  2026-06-25 expectations reject canonical `input wire axi0_rlast` solely
  because they omit the legal explicit net token.
- [x] **ADDRESSED (verified)** — Both regexes now accept an optional `wire`
  token while still requiring the exact scalar `axi0_rlast` input. The changed
  test is syntax-clean; unique full-PPIF filters make the exact depth-2 and
  depth-3 cases independently report `All tests successful` at
  `Files=1, Tests=6`.
- [x] **NO REGRESSION** — The separate adjacent mixed dynamic/static RID/RLAST
  case reports `All tests successful` at `Files=1, Tests=6` under the RAM
  guard. Production and user-facing behavior are unchanged, so the
  already-accurate mdBook needs no edit.
