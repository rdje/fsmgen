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
  Verification: `Director-authorized push a28e9adf46b7861ee728703662ad18b64f0325d0 has exact local/upstream/remote equality. Knowledge Map run 31494487149 and Publish mdBook run 31494487147 are completed/success. Regression run 31494487181 instantiated exactly 16 ordinary and 68 dynamic shards plus doctrine/mdBook support jobs; fail-fast remains disabled. The current inventory is 69 successful, 14 failed, and 3 running jobs. Every completed failure is assigned to a repaired child: late ordinary job 93788675496 adds t1508/t1522/t1537, all solely under the existing missing-Verilator/Yosys family proven by .6.2.2.1 and exact child .17 qualification. Remaining jobs continue collecting evidence.`
  Commit: `pending`
  Children: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.1, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.2, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.3, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.4, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.5, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.6, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.7, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.8, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.9, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.10, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.11, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.12, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.13, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.14, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.15, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.16, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.17, GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.18`

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
  Status: `done`
  Goal: `Make t40 accept the canonical semantically equivalent unary-not HDL spelling.`
  Acceptance: `Use history and generated HDL to prove whether parentheses are contractually required; if not, make the test accept only the exact factored intermediate with or without redundant parentheses while retaining all negated AND/OR/XOR checks; pass focused and adjacent language-expression tests.`
  Verification: `Job 93788675553 emits A = !intermediate_and_B_C_1; while t40 required A = !(intermediate_and_B_C_1); and failed solely on that formatting distinction. Git history finds no production contract for the redundant-parenthesis form, and the canonical RegressionCorpus already requires unparenthesized !intermediate_and/or/xor spellings. The one changed assertion now accepts exactly either the parenthesized or unparenthesized named intermediate, without permitting a missing or mismatched parenthesis and without weakening the wire, AND, OR, or XOR assertions. t35-t45 plus t248 pass at Files=12, Tests=7,187. This test-only correction changes no parser, AST, HDL generation, CLI/schema, mdBook, or downstream handoff behavior.`
  Commit: `this commit (accept equivalent unary-not intermediate spelling)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.4`
  Status: `done`
  Goal: `Remove the hosted Node 20 action-runtime deprecation before fallback removal becomes a CI outage.`
  Acceptance: `Audit every action annotation and current upstream action runtime; upgrade affected pinned major versions or record a bounded incompatibility with authoritative evidence; prove checkout, mdBook, Knowledge Map, and regression workflows remain green without enabling the insecure Node fallback.`
  Verification: `The exact pushed run forces actions/checkout@v4 and peaceiris/actions-mdbook@v2 from declared Node 20 onto Node 24. The complete official-manifest audit finds two additional direct Node 20 actions, configure-pages@v5 and deploy-pages@v4, plus upload-pages-artifact@v3's transitive upload-artifact@v4 Node 20 dependency; setup-perl@v1 already declares Node 24. git log -S'actions/checkout@v4' traces the floating checkout family through every workflow. All 13 direct uses are now immutable audited commits: checkout v7.0.1 3d3c42e5 (Node 24), actions-mdbook current main a6f333f62 (Node 24), setup-perl v1.43.1 53e33bb27 (Node 24), configure-pages v6.0.0 45bfe0192 (Node 24), upload-pages-artifact v5.0.0 fc324d354 (composite with immutable upload-artifact v7.0.0 bbbca2dda on Node 24), and deploy-pages v5.0.0 cd2ce8fcb (Node 24). Both book jobs pin official mdBook 0.5.4; Pages v5 explicitly includes hidden files to preserve the prior v3 archive scope; no insecure Node fallback exists. Official tag/commit and action.yml queries verify every SHA/runtime. Ruby parses all three workflows and t1183 locks the exact use counts, 40-hex pins, mdBook version, archive scope, and no-fallback boundary at Files=1, Tests=10. The official mdBook 0.5.4 Darwin arm64 asset matches 4,420,902 bytes and SHA-256 03e8a6d8...; all 53 chapters test, its 88-file/18,340-KiB HTML build passes, and both generated book and disposable tool are removed. Knowledge Map reports knowledge-map: OK. Workflow guidance records the immutable Node 24 family. Product code, generated artifacts, public schemas/reports/CLI, mdBook content, and SPECFORGE-facing handoff behavior are unchanged; this slice changes only hosted execution dependencies.`
  Commit: `this commit (migrate every hosted action dependency off Node 20)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.5`
  Status: `done`
  Goal: `Give every ordinary hosted shard the exact repository history required by history-backed doctrine tests.`
  Acceptance: `Prove the shallow-checkout mechanism from t1553/t1549/t1569 logs; fetch complete history for ordinary shards without widening dynamic or book jobs unnecessarily; lock the workflow contract and pass the three exact tests plus shard-selection coverage.`
  Verification: `Jobs 93788675363, 93788675380, and 93788675477 cannot retrieve retained objects 322d81f, 329d7cf, and 44b5f15 under the ordinary jobs' default depth-one checkout; the doctrine job already succeeds with fetch-depth 0. The ordinary matrix now fetches complete history, while t1183 proves the book and dynamic jobs retain default shallow checkout. Full-history local execution then exposed a second masked t1569 failure: the activation-content registry did not declare either the 19 repository-local command transformations from .6.2.1 or the exact verification-output discovery paragraph from .6.2.2.2; ordinary doctrine checked structural partitions but not t1569's stronger activation-content equality. Five bounded rewrite records now reproduce both intentional downstream transformations from the exact archived sources, and the rewrite validator permits bounded LF-separated replacement text while continuing to reject CR/NUL. Ruby parses the workflow; t1183 passes at Files=1, Tests=9; t1549/t1553/t1569 pass at Files=3, Tests=56; exact activation equality reports 3 sources/11 parts. The downstream handoff files remain byte-identical in this slice, but their retained-source contract is now exact. No CLI, schema, generated HDL, mdBook, or public integration behavior changes.`
  Commit: `this commit (fetch complete ordinary-shard history and restore exact retained-source transforms)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.6`
  Status: `done`
  Goal: `Provision the exact hosted Icarus Verilog revision required by t1542.`
  Acceptance: `Install and verify Ubuntu Noble iverilog=12.0-2build2 beside the already-pinned Verilator/Yosys packages only for ordinary shards; prove the workflow contract and t1542 without changing public backend qualification.`
  Verification: `Job 93788675610 reaches t1542's native-Verilog compile and fails because iverilog is absent. git log -S'iverilog' finds the runtime test introduction at 1dbff8fc6 but no regression-workflow installation. Ubuntu's Noble package authority, https://packages.ubuntu.com/noble/iverilog, currently lists version 12.0-2build2. Ordinary shards now pin that exact revision, install it beside Verilator/Yosys, verify all three dpkg revisions, and print the Icarus version before testing; dynamic shards remain tool-free. Ruby parses the workflow. t1183 passes at Files=1, Tests=9 and locks the exact package plus three package checks. Local installed Icarus 13.0 executes t1542's native-Verilog compile/runtime at Files=1, Tests=7; exact 12.0-2build2 remains subject to the repaired hosted requalification. Existing public contract text already requires installed Icarus for this check and separately says local HDL tools are not selected as public verification-output providers, so mdBook/downstream contracts and public qualification remain unchanged.`
  Commit: `this commit (provision exact hosted Icarus Verilog)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.7`
  Status: `done`
  Goal: `Synchronize the APB selected-adjacent diagnostic oracle with every shipped completer family.`
  Acceptance: `Prove the current diagnostic expansion from production and history; update t1471's one shared exact diagnostic pattern to cover generalized and status/control families; pass focused and adjacent APB diagnostic tests without changing the parser or diagnostic.`
  Verification: `Job 93788675417 and the pre-fix local t1471 fail six malformed selected-adjacent cases because the one shared oracle stops at the older two-register families. Production's exact diagnostic already includes 32-bit/data16 generalized no-policy register sets, protected generalized register sets, and protection status/control peripherals; git log -S traces the original diagnostic through .607/.622/.625/.628/.631 and later generalized/status expansions including 4457eb5cb and 192b50784. The shared regex now requires the current full ordered family list, escaping only literal reg0..regN dots and status/control slashes. Production parser and diagnostic are byte-unchanged. t1470/t1471/t1472 pass at Files=3, Tests=147 in 1,023 wall-clock seconds. This oracle-only correction changes no CLI, schema, generated IAL1/IAL0/HDL, mdBook, or downstream contract; existing public documents already describe the shipped generalized and status/control families.`
  Commit: `this commit (synchronize the selected-adjacent APB diagnostic oracle)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.8`
  Status: `done`
  Goal: `Keep the CLI output-open context test valid after repository-local parent-directory creation shipped.`
  Acceptance: `Use a deterministic repository-local target that reaches the output-file open failure after parent preparation; retain source path, output path, underlying diagnostic, and no-script-redie assertions; pass t250 and adjacent CLI context coverage without changing CLI behavior.`
  Verification: `Job 93788675417 and the pre-fix local t250 use a missing parent as an unwritable target, but git log -S identifies 017153eac as the deliberate introduction of explicit repository-local output-parent creation before open. The fixture now creates its output path itself as a directory: parent preparation succeeds, open '>' deterministically reaches the real output-file error branch, and !-f distinguishes the absent generated file from the retained directory fixture. t250 passes at Files=1, Tests=2; the adjacent source/child/extension diagnostic and project-local artifact-placement band passes at Files=11, Tests=28. bin/fsmgen is byte-unchanged. The mdBook already states that FSMGen creates missing repository-local output parents, and the ISF downstream handoff already uses repository-local output paths, so public behavior and integration contracts require no text change.`
  Commit: `this commit (restore the output-open failure fixture after parent preparation)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.9`
  Status: `done`
  Goal: `Recognize the current qualified private VIAL VHDL contract status in the support-builder audit.`
  Acceptance: `Trace the status to its owning qualification slice; add only the current exact value to the closed audit set; pass all support-contract builders and relevant VIAL contract tests without changing a contract payload.`
  Verification: `Job 93788675417 and the pre-fix local t350 reject only FSM::Support::VIALVHDLEmissionContract: all 54 other contract modules pass, while the closed audit set lacks shipped_private_portable_and_osvvm_qualified_profiles. git log -S traces that exact value to 895ea33bd, whose .15.7 qualification changed the canonical private contract and simultaneously synchronized the two mdBook architecture chapters and durable VIAL task evidence. t350 now admits only that exact additional status. The focused and adjacent capability/support-contract band passes at Files=8, Tests=84; t297 separately proves that the capability manifest embeds the exact canonical VIAL VHDL contract. The contract payload, capability manifest, mdBook, VIAL handoff/audit, schemas, and generated artifacts are byte-unchanged by this oracle-only slice.`
  Commit: `this commit (recognize the qualified private VIAL VHDL status)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.10`
  Status: `done`
  Goal: `Align standalone and state DTE output-enable assertions with canonical true-identity simplification.`
  Acceptance: `Require the exact DTE carrier and target enable while accepting the canonical direct carrier assignment in place of carrier & 1'b1; retain nontrivial transition/guard assertions; pass t48/t82 and adjacent EnableGraph coverage without changing generated HDL.`
  Verification: `Jobs 93788675417 and 93788675550 plus the pre-fix local t48/t82 expose five direct assignments after the width-safe AST simplifier removes boolean & 1'b1. The simplifier shipped in 425f03d1b; git history shows b775355f2 later synchronized the same state/standalone DTE expectations in RegressionCorpus but omitted these direct tests. The five assertions now require the exact carrier-only assignments and clearer direct-gating labels, while idle_next_state_active_en = idle_en & done and all guard/factorization checks remain exact. The DTE/EnableGraph band passes at Files=11, Tests=39; corpus accounting passes at Files=1, Tests=7092. Production and generated HDL are byte-unchanged. The mdBook already documents the exact scalar identity rewrite and vector-width boundary, while the downstream ISF contract specifies semantic DTE gating without depending on redundant syntax, so no public-document edit is required.`
  Commit: `this commit (synchronize direct DTE identity assertions)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.11`
  Status: `done`
  Goal: `Refresh the bounded read-only MCP schema fixture to the current catalog-entry projection.`
  Acceptance: `Prove the live fsmgen_find_examples projection and public contract; replace only stale representative entry keys, retain all mutation/ambient-access exclusions, and pass the focused MCP snapshot plus adjacent MCP contract tests; audit downstream/mdBook impact explicitly.`
  Verification: `Job 93788675536 and the pre-fix local t1445 show the current first composition example has expected_module_name and no expected_hdl_pattern_count. The fixture projection was introduced at a1cc9414a on 2026-06-16, when its representative composition entry carried expected_hdl_patterns; 17445d0c2 added the now-earlier APB composition catalog entry on 2026-06-27 with expected_module_name. The canonical sorted fixture now substitutes expected_module_name in its exact sorted position. The complete adjacent read-only MCP adapter/CLI/protocol/query/schema/framing/root/prompt/resource-change band passes at Files=9, Tests=27; the snapshot's separate mutation/ambient-path exclusions remain green. Production adapter, catalog, public payload, schemas, mdBook, and SPECFORGE handoff are byte-unchanged. Existing mdBook text documents catalog-backed example lookup without freezing one positional sample's exact entry fields, and the downstream handoff requires machine-readable contracts without duplicating this representative key list, so no public-document edit is required.`
  Commit: `this commit (refresh the representative MCP example schema fixture)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.12`
  Status: `done`
  Goal: `Align aggregate AHB byte-lane wiring assertions with the generated fabric instance name.`
  Acceptance: `Trace the instance rename and require exact fabric-to-subordinate address plus subordinate-to-fabric response wiring across one/two-subordinate and SEQ/non-SEQ sources; pass t1484/t1488 and adjacent aggregate tests without changing generation.`
  Verification: `Jobs 93788675536 and 93788675610 plus the pre-fix local t1484/t1488 show current ahb_tb.fsm uses fabric.HADDR_* and *.HRESP_* fabric.HRESP_*. git log -S"'fabric'" identifies 2c9c67499 as the deliberate HDL-safe interconnect-instance rename; that commit synchronized the base t1478 oracle and mdBook but missed eight duplicated byte-lane assertions: four non-SEQ and four SEQ, spanning one-subordinate local-address/response wiring and two-subordinate status/control responses. All eight now require the exact fabric instance. The focused t1484/t1488 pair passes at Files=2, Tests=8; the adjacent base one/two-subordinate and non-SEQ/SEQ profile-alias band passes at Files=4, Tests=16. Both changed files are syntax-clean and a post-fix census finds no pre-rename interconnect.HADDR/HRESP oracle in either. Production, generated IAL0/HDL, reports, schemas, and public behavior are byte-unchanged. The mdBook and AHB behavior contract already explicitly name the HDL-safe fabric instance, while the SPECFORGE handoff does not duplicate a conflicting internal child label, so no public-document edit is required.`
  Commit: `this commit (synchronize aggregate AHB fabric wiring assertions)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.13`
  Status: `done`
  Goal: `Synchronize paired AHB BUSY residue assertions with generalized numeric count wording.`
  Acceptance: `Update every stale exact-one/two/three paired-composition assertion to the exact numeric singular/plural wording emitted by the generalized 2..16 contract; retain count and deferred-bound checks; pass all affected generic and two-subordinate tests plus generalized coverage without changing reports.`
  Verification: `Jobs 93788675536/93788675610 and the pre-fix local t1513/t1531/t1533 expose stale word-form residue prose; a complete census adds t1523/t1525. git log -S'qualified requester HTRANS BUSY' identifies 2f64611ca as the generalized-count change that replaced per-count wording with exactly N plus singular/plural grammar and updated exact-four/generalized tests, but omitted these five paired-composition oracles. Exact-one now requires exactly 1 ... event; exact-two/three require exactly 2/3 ... events, with numeric labels. The complete affected one/two-window band passes at Files=5, Tests=18 in 1,130 seconds; the RAM-guarded exact-four one/two-window plus generalized 2..16 qualification passes at Files=3, Tests=12 in 627 seconds. All five changed files are syntax-clean and a repository-wide census finds no stale one exact/exact-two/exact-three residue regex. Production reports, source schemas, generated HDL, and public behavior are byte-unchanged. Commit 2f64611ca already synchronized the generalized numeric report contract, exact singular/plural wording, mdBook, and AHB behavior/handoff documents; SPECFORGE consumes the unchanged public report surface, so no public-document edit is required.`
  Commit: `this commit (synchronize numeric AHB BUSY residue assertions)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.14`
  Status: `done`
  Goal: `Align direct-VHDL reduction-condition assertions with the emitted valid condition syntax.`
  Acceptance: `Require exact scalar and helper-based vector reduction semantics without redundant nested parentheses; retain helper declaration/collision and unsupported-source checks; pass t1543 plus adjacent direct-VHDL tests without changing emission.`
  Verification: `Job 93788675622 and the pre-fix local t1543 show exact valid conditions if (X = '1') then and if (fsmgen_direct_vhdl_reduce_or(X) = '1') then. git log -S'condition conversion receives declaration context' identifies 2879f22af as the reduction-lowering implementation slice that introduced both the backend behavior and assertions that instead require redundant ((X)) and ((helper(X))) nesting. The two assertions now require the emitted scalar and declaration-aware helper forms exactly. The focused file passes at Files=1, Tests=6; the adjacent direct backend, named-drive reduction, and generator-facade band passes at Files=4, Tests=173. Helper declaration/folding/collision, unsupported operand/source, scalar complement, and foreign-token exclusions remain covered. Production emission, reports, schemas, and artifacts are byte-unchanged. Existing direct-VHDL behavior, scope, and mdBook text already document the live reduction semantics without promising redundant condition parentheses; downstream consumers receive unchanged generated VHDL and no conflicting handoff contract, so no public-document edit is required.`
  Commit: `this commit (synchronize direct-VHDL condition assertions)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.15`
  Status: `done`
  Goal: `Repair the failed dynamic depth-three multi-beat output-bank contract assertions.`
  Acceptance: `Require width-correct zero initialization for valid/count/status outputs and prove the final r2 lane capture plus later valid/count actions without assuming rresp is the last rule action; preserve all report, IAL0, HDL, and CLI checks; pass exact dynamic shard 16 and relevant neighboring coverage without production changes.`
  Verification: `Dynamic job 93788677145 and the pre-fix local oracle expose four mismatches: the three transaction-bank assertions expect unsized zero and the final r2 assertion closes the rule after its RRESP lane. git log -S'beat_valid 0' identifies 7fffd2682 as the depth-three behavior slice; that same commit's direct generator oracle already requires the canonical shared helper's 2'd0 aggregate, 16'b0 valid mask, 5'd0 length, and final-lane RRESP followed by the all-ones valid mask and 5'd16 length. Production history locates typed output initialization at c1eaef474/5dfa64483 and the generic ordered rule formatter at e8bd4f061. t1438 now requires those exact typed/order invariants for all three banks and r2's final lane. The exact RAM-guarded hosted command ./bin/ci-regression full --no-book --hosted-dynamic-shard 16/68 passes at Files=1, Tests=2 in 1,035 seconds, including strict check and semantic JSON. The changed file is syntax-clean, a stale shorthand census is empty, and t1436/t1437 retain matching adapter/direct-generator oracles. Production, PPIF, generated IAL1/IAL0/HDL, reports, schemas, and CLI payloads are byte-unchanged. The depth-three behavior document already publishes the complete final-lane action sequence, the mdBook already documents width-correct output-bank initialization, and the SPECFORGE-facing ISF handoff claims the unchanged generated multi-beat contract without freezing duplicate test regexes, so no public-document edit is required.`
  Commit: `this commit (synchronize dynamic output-bank assertions)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.16`
  Status: `done`
  Goal: `Re-audit mdBook and downstream-consumer contract lockstep across the complete repaired branch before another push.`
  Acceptance: `Classify every commit after completed audit aef4a3342 through the repaired HEAD against the reusable ISF public-contract checklist; prove the implementation, public schemas/reports/artifacts/diagnostics, CLI/API, capability manifest, support accounting, general/SPECFORGE handoff, and mdBook either moved together or remained unchanged. Run the canonical seven-file downstream contract suite and exact hosted mdBook 0.5.4 test/build path, remove generated artifacts, and record any required synchronization before requesting fresh push authorization. Do not fold the independently proposed source.resolved_path compatibility decision into this no-drift audit, and do not push.`
  Verification: `The exact range aef4a3342..466c3096f contains 18 commits: three task/governance commits, four hosted-workflow/doctrine commits, ten test-oracle/fixture repairs, and one public verification-output discovery repair. A path-level diff finds no parser, scheduler, emitter, CLI, generated-artifact, diagnostic, report-source, public-facade, library-catalog, SPECFORGE-response, or support-accounting payload change. The sole public production delta delegates both discovery projections to VerificationOutputsContract's complete top-level key owner; its matching mdBook embedding text and the downstream handoff's maintained part explicitly name guidance and json_safe_when_embedded_in_public_manifest. The canonical public-interface/manifest/live-doc/live-book/discovery suite passes at Files=7, Tests=45, including the four new discovery assertions; adjacent capability-manifest/support-builder coverage passes at Files=2, Tests=59. Project-data locality passes, all 3 retained ISF sources reproduce 11 maintained parts with activation-content equality, and Knowledge Map reports 1,109 facts/5,765 questions/5,931 occurrences/121 shards. The official mdBook 0.5.4 Darwin arm64 asset again matches 4,420,902 bytes and SHA-256 03e8a6d8...; all 53 chapters test and the 88-file/18,340-KiB HTML build passes. The generated book and disposable tool are removed. No additional mdBook, general-consumer, or SPECFORGE contract edit is required; source.resolved_path remains unchanged and separately proposed.`
  Commit: `this commit (consolidated repaired-branch contract lockstep audit)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.17`
  Status: `done`
  Goal: `Consume late-terminal ordinary shard 14/16 and prove its exact failures are covered by the existing hosted HDL-tool repair.`
  Acceptance: `Retrieve job 93788675496 while the parent run remains active; identify every failed file and assertion; prove whether each failure is solely the already-owned missing-Verilator/Yosys mechanism or requires a new production, oracle, workflow, or public-contract change. Run the exact affected files with installed Verilator/Yosys, retain the pinned hosted workflow proof from .6.2.2.1, synchronize terminal inventory and continuity evidence, and do not push.`
  Verification: `The Actions job-log API exposes completed job 93788675496 while its parent remains active: shard 14/16 runs 100 files/590 tests and fails only t1508, t1522, and t1537. Each failure is rooted in the literal HDLExternalValidation diagnostic Missing external HDL validation tool(s): verilator, yosys; t1508's absent PASS markers and Verilator harness, t1522's alias verifier, and t1537's public verifier/assertion harness are downstream consequences, with no independent semantic or oracle mismatch. Existing child .1 already installs and verifies pinned Noble Verilator 5.020-1 and Yosys 0.33-5build2 for every ordinary shard. Under installed local Verilator 5.046/Yosys 0.64, the RAM-guarded exact three-file suite passes at Files=3, Tests=12 in 414 seconds, including Verilator lint/build/runtime, Yosys synthesis, public --verify-hdl, CLI, semantic, MCP, support, and artifacts. t1183 passes at Files=1, Tests=10 and all three workflow YAML files parse. No implementation, workflow, mdBook, or downstream/SPECFORGE contract change is needed; the repaired hosted package revisions still require the next authorized push qualification.`
  Commit: `this commit (late shard-14 missing-tool qualification evidence)`

- ID: `GITHUB-PUSH-OUTCOME-ASSURANCE.6.2.2.18`
  Status: `active`
  Goal: `Restore credible hosted ordinary-shard runtime headroom before the repaired revision is pushed.`
  Acceptance: `Consume the final three exact ordinary-job terminal results and logs from run 31494487181; distinguish slow-but-complete execution from five-hour timeout; account for the additional Verilator, Yosys, and Icarus work enabled by the repaired workflow; select a deterministic complete/disjoint ordinary partition whose per-job bound has material headroom below the 300-minute timeout without reducing coverage or changing the unchanged local full gate; lock the exact matrix and aggregate contract in tests and workflow guidance; update decision, continuity, mdBook, and downstream/SPECFORGE surfaces only where their owned contract actually changes; pass focused selection/workflow/doctrine checks and do not push.`
  Verification: `Pending exact terminal logs. At 2026-08-11T17:26:46Z, jobs 93788675385 (1/16), 93788675473 (15/16), and 93788675594 (9/16) remained inside Run full-suite file shard after starting at 13:06:35Z..13:06:43Z. The pushed workflow has timeout-minutes: 300, while the local repair now provisions and exercises three external HDL tools that this failed old run omitted. Near-ceiling completion therefore cannot by itself prove safe repaired-run headroom.`
  Commit: `pending`

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
- `2026-08-11`: Treat parentheses around a single SystemVerilog identifier
  under unary `!` as optional test spelling, while requiring the exact factored
  intermediate either way. Production and RegressionCorpus stay unchanged.
- `2026-08-11`: Fetch complete Git history only for ordinary hosted shards,
  because retained-document tests consume exact objects. Keep book/dynamic jobs
  shallow, and represent every intentional post-partition downstream edit as a
  bounded exact-source rewrite, including bounded LF-separated insertions.
- `2026-08-11`: Pin ordinary hosted shards to Ubuntu Noble
  `iverilog=12.0-2build2` for the already-selected native-Verilog runtime test.
  This CI dependency does not select Icarus as a public output provider or
  change the separately qualified backend contracts.
- `2026-08-11`: Keep APB negative tests exact to the complete ordered
  selected-adjacent family diagnostic. When already-shipped families widen
  that diagnostic, synchronize the shared oracle without weakening it or
  rewriting production merely to preserve stale prose.

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

## Acceptance Checklist — `.6.2.2.3` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788675553` emits `A = !intermediate_and_B_C_1;` while t40 alone requires redundant parentheses; `git log -S'!(intermediate_and_B_C_1)' --oneline --all -- t perl` finds no production contract, and RegressionCorpus already requires the unparenthesized canonical form for all three negated n-ary families.
- [x] **ADDRESSED (verified)** — t40 now accepts exactly `!intermediate_and_B_C_1` or `!(intermediate_and_B_C_1)` and still requires the same factored carrier plus exact AND, OR, and XOR assignments; the focused file passes.
- [x] **NO REGRESSION** — The adjacent t35-t45 language-contract band plus t248 RegressionCorpus accounting reports `All tests successful` at `Files=12, Tests=7187`; the staged doctrine driver reports `[doctrine] all doctrine checks passed`. No product or public-document surface changed.

## Acceptance Checklist — `.6.2.2.4` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The exact pushed workflows force checkout v4 and actions-mdbook v2 from their declared Node 20 runtime onto Node 24. `git log -S'actions/checkout@v4' -- .github/workflows` traces the floating checkout dependency across regression, Pages, and Knowledge Map workflows. Official action.yml audits additionally expose configure-pages v5 and deploy-pages v4 as direct Node 20 actions and upload-pages-artifact v3 as a composite delegating to Node 20 upload-artifact v4; the original warning list therefore understated the full dependency chain.
- [x] **ADDRESSED (verified)** — All 13 direct workflow uses now carry immutable 40-hex commits. Checkout v7.0.1, setup-perl v1.43.1, configure-pages v6.0.0, deploy-pages v5.0.0, and actions-mdbook current main declare Node 24; upload-pages-artifact v5 is composite and immutably delegates to Node 24 upload-artifact v7. Both book jobs pin mdBook 0.5.4, Pages retains hidden generated files explicitly, and no `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION` fallback exists. Official GitHub ref, commit, release, and action.yml queries verify every selected identity/runtime.
- [x] **NO REGRESSION** — All three workflow YAML files parse; t1183 reports `All tests successful` at `Files=1, Tests=10` and locks exact pins/counts, shard families, mdBook version, archive scope, and no-fallback policy. The SHA-256-verified official mdBook 0.5.4 binary tests all 53 chapters and builds 88 files/18,340 KiB; exact generated artifacts are removed. `knowledge-map: OK` verifies 1,109 facts/5,765 questions/5,931 occurrences/121 shards. Product code and public integration surfaces are unchanged, so existing mdBook content and SPECFORGE-facing handoff contracts remain lockstep.

## Acceptance Checklist — `.6.2.2.5` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Jobs `93788675363`, `93788675380`, and `93788675477` run ordinary shards after the default depth-one checkout, so t1569/t1553/t1549 cannot retrieve exact retained objects `322d81f`, `329d7cf`, and `44b5f15`. `git log -S'fetch-depth: 0' --oneline -- .github/workflows/regression.yml` finds only the doctrine-job introduction at `70cd867e3`, proving the ordinary job never acquired that requirement. Once full history made those objects available locally, t1569 exposed a masked second cause: `.6.2.1` and `.6.2.2.2` intentionally changed maintained downstream parts without registering their exact archived-source transformations, while ordinary doctrine did not request t1569's stronger `--verify-activation-content` mode.
- [x] **ADDRESSED (verified)** — Only `perl_files` now uses `fetch-depth: 0`; t1183 requires that setting and proves mdBook/dynamic remain shallow. Five exact, counted rewrite records reproduce the 19 repository-local output commands and verification-output discovery paragraph from the retained source objects. The validator now permits bounded LF-separated replacement text while continuing to forbid CR/NUL; direct activation equality reports `3 exact sources map contiguously to 11 bounded semantic parts with activation-content equality`.
- [x] **NO REGRESSION** — Ruby reports `workflow YAML parses`; t1183 reports `All tests successful` at `Files=1, Tests=9`; t1549/t1553/t1569 report `All tests successful` at `Files=3, Tests=56`. The staged doctrine driver reports `[doctrine] all doctrine checks passed`. The book and dynamic jobs remain shallow, downstream handoff text is byte-identical in this slice, and CLI/schema/HDL/mdBook/public integration behavior is unchanged.

## Acceptance Checklist — `.6.2.2.6` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788675610` reaches t1542's native-Verilog runtime path and fails because `iverilog` is absent. `git log -S'iverilog' --oneline -- .github/workflows/regression.yml` returns no commit, while the same pickaxe over t1542 locates its runtime requirement at `1dbff8fc6`: the ordinary shard selected the test but never provisioned its compiler.
- [x] **ADDRESSED (verified)** — The ordinary job pins Ubuntu Noble `iverilog=12.0-2build2`, installs it beside the existing exact Verilator/Yosys packages, verifies all three dpkg revisions, and prints `iverilog -V`. t1183 locks the exact pin, installation order, three revision checks, and the dynamic job's tool-free boundary; Ruby reports `workflow YAML parses`.
- [x] **NO REGRESSION** — t1183 reports `All tests successful` at `Files=1, Tests=9`; local Icarus 13.0 executes t1542's native-Verilog compile/runtime and reports `All tests successful` at `Files=1, Tests=7`. The staged doctrine driver reports `[doctrine] all doctrine checks passed`. Existing downstream contract text already selects the Icarus check and denies local tools public verification-output-provider status, so mdBook, handoff schemas, generated HDL, and public qualification are unchanged.

## Acceptance Checklist — `.6.2.2.7` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788675417` and local t1471 reject six malformed selected-adjacent sources correctly but fail their diagnostic assertions because one shared regex ends at the older two-register families. `git log -S'selected setup-admission adjacent policy supports only' --oneline --all -- perl t` traces that oracle through `.607/.622/.625/.628/.631`, while later production expansions such as `4457eb5cb` and `192b50784` added generalized and status/control families without synchronizing this shared test line.
- [x] **ADDRESSED (verified)** — t1471's single `$selected_adjacent_error` now requires the production diagnostic's complete ordered 32-bit/data16 no-policy, generalized, protected-generalized, and protection status/control family list. Literal `reg0..regN` dots and `status/control` slashes are escaped; no wildcard or alternate diagnostic is accepted, and production is unchanged.
- [x] **NO REGRESSION** — The focused completer plus adjacent APB profile-alias/composition band reports `All tests successful` at `Files=3, Tests=147` in 1,023 wall-clock seconds. The staged doctrine driver reports `[doctrine] all doctrine checks passed`. The change is test-only; CLI/schema, generated IAL1/IAL0/HDL, mdBook, and downstream public integration contracts remain unchanged and already describe the live families.

## Acceptance Checklist — `.6.2.2.8` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788675417` and the pre-fix local t250 succeed unexpectedly because a missing output parent no longer represents an unwritable target. `git log -S'ensure_project_output_directory' --oneline --all -- bin/fsmgen t/250-cli-entrypoint-file-context.t` identifies `017153eac`: `bin/fsmgen` now deliberately prepares the repository-local parent immediately before opening the output file, while the older fixture still relies on missing-parent failure.
- [x] **ADDRESSED (verified)** — t250 now creates the output path itself as a directory, allowing parent preparation to succeed before `open '>'` deterministically fails at the intended branch. The same source path, output path, underlying `Cannot write to output file:` diagnostic, and no-script-redie assertions remain exact; `!-f` correctly proves that no generated file exists while preserving the directory fixture. Production is unchanged.
- [x] **NO REGRESSION** — The focused t250 run reports `All tests successful` at `Files=1, Tests=2`; the adjacent source/child/extension diagnostic plus project-local artifact-placement band reports `All tests successful` at `Files=11, Tests=28`. The staged doctrine driver reports `[doctrine] all doctrine checks passed`. Existing mdBook text already specifies missing repository-local output-parent creation, the ISF downstream handoff already selects repository-local output paths, and CLI/schema/HDL/public integration behavior is unchanged.

## Acceptance Checklist — `.6.2.2.9` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788675417` and the pre-fix local t350 fail only the `FSM::Support::VIALVHDLEmissionContract` status assertion after 54 other support-contract modules pass. `git log -S'shipped_private_portable_and_osvvm_qualified_profiles' --oneline --all -- perl t docs/book docs/isf-spec` identifies `895ea33bd`: exact OSVVM 2026.05 plus GHDL 6.0.0 qualification deliberately advanced the private contract status, while t350's independent closed audit set remained stale.
- [x] **ADDRESSED (verified)** — t350's closed `%allowed_status` set now admits exactly `shipped_private_portable_and_osvvm_qualified_profiles`. The canonical builder, embedded capability-manifest projection, schema version, private/public boundary, capabilities, limits, and nonclaims remain unchanged; no wildcard or weakened status policy is introduced.
- [x] **NO REGRESSION** — The focused and adjacent capability/support-contract suite reports `All tests successful` at `Files=8, Tests=84`; t297 proves the capability manifest still embeds the exact canonical VIAL VHDL contract, and t350 validates all 55 contract builders. The staged doctrine driver reports `[doctrine] all doctrine checks passed`. Commit `895ea33bd` already synchronized the mdBook architecture chapters and durable VIAL handoff/audit with the live contract, so product, public integration, emitted-artifact, and documentation behavior is unchanged.

## Acceptance Checklist — `.6.2.2.10` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted jobs `93788675417`/`93788675550` and the pre-fix local t48/t82 show five generated carrier-only assignments while the direct tests still require redundant `& 1'b1`. `git log -S'_simplify_binary_identity' --oneline --all -- perl/FSM/Synthesis/EnableGraph/ASTSupport.pm` identifies scalar identity simplification commit `425f03d1b`; `git show b775355f2` proves the later simplification-oracle sync changed these same state/standalone DTE patterns in `RegressionCorpus` but omitted t48/t82.
- [x] **ADDRESSED (verified)** — t48 and t82 now require exact `route_en`, `expr_guard_en`, `idle_en`, and `active_en` carrier assignments at all five affected output/transition enables. The nontrivial `idle_next_state_active_en = idle_en & done` transition, top-level DTE guards, shared intermediate, factorization, and non-inlining assertions remain exact; no alternate redundant spelling is accepted and production is unchanged.
- [x] **NO REGRESSION** — The direct DTE plus complete adjacent EnableGraph band reports `All tests successful` at `Files=11, Tests=39`; the broader corpus audit reports `All tests successful` at `Files=1, Tests=7092`. The staged doctrine driver reports `[doctrine] all doctrine checks passed`. Existing mdBook text already documents scalar true-identity simplification and its vector-width limit, while downstream ISF handoff text specifies semantic DTE gating independently of redundant HDL syntax; generated HDL, schemas, and public integration behavior are unchanged.

## Acceptance Checklist — `.6.2.2.11` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788675536` and the pre-fix local t1445 differ at the bounded examples projection because the fixture introduced at `a1cc9414a` still describes its 2026-06-16 first matching composition entry. `git log -S'expected_hdl_patterns' -- perl/FSM/Support/RegressionCorpus.pm` plus line history identifies the catalog evolution: commit `17445d0c2` later inserted the APB composition entry earlier in the catalog with `expected_module_name` and no `expected_hdl_patterns`, so the positional snapshot's stale `expected_hdl_pattern_count` no longer describes the live representative.
- [x] **ADDRESSED (verified)** — The canonical sorted fixture substitutes exactly `expected_module_name` in its correct sorted position after `expected_lane`; every other projected key, payload/envelope shape, mutation exclusion, ambient-root exclusion, adapter method, and production catalog value is unchanged. The focused schema snapshot passes.
- [x] **NO REGRESSION** — The adjacent t1441-t1449 read-only MCP band reports `All tests successful` at `Files=9, Tests=27`. The production adapter, public response, schemas, and catalog are byte-unchanged. Existing mdBook text accurately documents catalog-backed example lookup without freezing a positional entry's exact field set, and the SPECFORGE handoff's machine-readable-contract requirement does not duplicate that fixture list, so downstream integration and mdBook remain in lockstep without text changes.

## Acceptance Checklist — `.6.2.2.12` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted jobs `93788675536`/`93788675610` and the pre-fix local t1484/t1488 show exact `fabric.HADDR_*` and `*.HRESP_* fabric.HRESP_*` generated wiring while eight assertions still name `interconnect`. `git log -S"'fabric'" -- perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm` identifies `2c9c67499`: the intentional HDL-safe instance rename updated production, t1478, behavior docs, and mdBook, but omitted the duplicated non-SEQ/SEQ byte-lane aggregate tests.
- [x] **ADDRESSED (verified)** — All eight stale assertions now require `fabric`: one-subordinate local-address and response wiring plus both two-subordinate response wires in each of t1484 and t1488. A post-fix census finds no `interconnect.HADDR`/`interconnect.HRESP` spelling in those files; production and assertion meaning are otherwise unchanged.
- [x] **NO REGRESSION** — Focused t1484/t1488 reports `All tests successful` at `Files=2, Tests=8`; adjacent t1478/t1480/t1485/t1489 reports `All tests successful` at `Files=4, Tests=16`; both changed files report `syntax OK`. Existing mdBook and AHB behavior text already name the exact HDL-safe `fabric` instance, and the SPECFORGE handoff carries no conflicting internal child-label promise, so generated behavior and downstream contracts remain lockstep.

## Acceptance Checklist — `.6.2.2.13` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted jobs `93788675536`/`93788675610` and pre-fix local paired tests reject live residue that says `exactly N qualified requester HTRANS BUSY event(s)`. `git log -S'qualified requester HTRANS BUSY' -- perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm` identifies `2f64611ca`: generalized canonical counts 2..16 deliberately replaced per-count word forms with one numeric singular/plural template, synchronized exact-four/generalized oracles and public docs, but omitted exact-one t1513, exact-two t1523/t1525, and exact-three t1531/t1533.
- [x] **ADDRESSED (verified)** — The five paired assertions now require exact numeric `exactly 1 ... event`, `exactly 2 ... events`, or `exactly 3 ... events` wording and identify their checks as numeric. Counts, child transfer/busy metadata, deferred bounds, parking, CLI/semantic/MCP/artifact, and assertion-enabled runtime checks remain unchanged; a repository-wide census finds no stale word-form residue regex.
- [x] **NO REGRESSION** — All five affected files report `All tests successful` at `Files=5, Tests=18`; RAM-guarded exact-four and generalized 2..16 coverage reports `All tests successful` at `Files=3, Tests=12`; every changed file reports `syntax OK`. Production reports and generated HDL are byte-unchanged, while the original generalized-count commit already synchronized the public numeric grammar, mdBook, behavior contracts, and downstream-consumed report surface.

## Acceptance Checklist — `.6.2.2.14` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788675622` and the pre-fix local t1543 show valid `if (X = '1') then` and `if (fsmgen_direct_vhdl_reduce_or(X) = '1') then` output while two assertions alone require redundant nested parentheses. `git log -S'condition conversion receives declaration context' -- t/1543-direct-vhdl-reduction-expression-readiness.t` identifies `2879f22af` as the implementation slice that introduced both the declaration-aware condition lowering and those mismatched assertions.
- [x] **ADDRESSED (verified)** — The scalar assertion now requires exactly `if (X = '1') then`; the vector assertion requires exactly `if (fsmgen_direct_vhdl_reduce_or(X) = '1') then`. Helper declaration/folding/collision, unsupported operand and public-source rejection, scalar complement behavior, and foreign-token exclusions remain exact; production is unchanged.
- [x] **NO REGRESSION** — The focused test reports `All tests successful` at `Files=1, Tests=6`; the adjacent direct-backend, named-drive reduction, and generator-facade suite reports `All tests successful` at `Files=4, Tests=173`; the changed file reports `syntax OK`. Existing mdBook/direct-VHDL behavior text already describes the live semantics, and downstream consumers receive unchanged generated VHDL with no conflicting handoff promise, so code, book, and integration contracts remain lockstep.

## Acceptance Checklist — `.6.2.2.15` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Hosted job `93788677145` rejects the depth-three output banks only because t1438 expects unsized `0` and treats final-lane RRESP as the rule terminator. `git log -S'beat_valid 0' -- t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm` identifies `7fffd2682`, whose parallel direct-generator oracle already carries the correct typed initialization and full action tail; production history attributes the shared typed/order behavior to `c1eaef474`, `5dfa64483`, and `e8bd4f061`.
- [x] **ADDRESSED (verified)** — All three output-bank assertions now require aggregate `2'd0`, valid mask `16'b0`, and length `5'd0` in canonical order. The r2 final-lane assertion now requires the RRESP capture followed by valid mask `16'b1111111111111111` and length `5'd16` before rule close. A census finds no remaining unsized beat-valid/read-beats shorthand, and the unchanged t1436/t1437 oracles require the same full final-lane sequence.
- [x] **NO REGRESSION** — The exact RAM-guarded hosted dynamic command reports `All tests successful` at `Files=1, Tests=2` in 1,035 wall-clock seconds, including the adapter pipeline plus strict check and semantic JSON; the changed file reports `syntax OK`. Production, fixtures, generated artifacts, reports, schemas, and CLI payloads are unchanged. Existing behavior/mdBook text already publishes the typed initialization and complete action order, while the SPECFORGE-facing handoff accurately claims the unchanged generated multi-beat surface, so code, book, and downstream contracts remain lockstep.

## Acceptance Checklist — `.6.2.2.16` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — The completed downstream audit ended at `aef4a3342`, while `git log --reverse aef4a3342..466c3096f` identifies 18 later commits that would otherwise reach the next push without one consolidated public-surface review. `git diff --name-only` and the reusable ISF synchronization checklist reduce the only production/public delta to `VerificationOutputsContract` plus `CapabilityManifestContract`; every other repair is task/governance, hosted infrastructure, or a test oracle/fixture.
- [x] **ADDRESSED (verified)** — The 18-commit matrix is classified as 3 task/governance, 4 hosted-workflow/doctrine, 10 test-oracle/fixture, and 1 public discovery repair. The public repair has one canonical complete top-level key owner and synchronized mdBook embedding text plus downstream maintained-reference text for `guidance` and `json_safe_when_embedded_in_public_manifest`; public CLI/API, schemas/reports/artifacts/diagnostics, SPECFORGE response, library catalog, and support-accounting payloads have no additional delta. Exact retained-source activation equality, project locality, and Knowledge Map checks pass. The independent `source.resolved_path` policy remains unchanged under its proposed tree.
- [x] **NO REGRESSION** — The canonical downstream contract suite reports `All tests successful` at `Files=7, Tests=45`; adjacent capability-manifest/support-builder coverage reports `Files=2, Tests=59`. The SHA-256-verified official mdBook 0.5.4 binary tests all 53 chapters and builds 88 files/18,340 KiB; both generated book and disposable tool are removed. Code, mdBook, and general/SPECFORGE-facing downstream contracts are lockstep with no further public edit required.

## Acceptance Checklist — `.6.2.2.17` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Completed job `93788675496` runs `Files=100, Tests=590` and fails only t1508/t1522/t1537. Direct Actions API logs attach every failed assertion to `[HDLExternalValidation.pm][validate_systemverilog_file()] Missing external HDL validation tool(s): verilator, yosys`; the absent Verilator/Yosys PASS markers and executable harnesses are consequences of that one setup omission, not separate product or oracle defects.
- [x] **ADDRESSED (verified)** — Existing child `.6.2.2.1` already installs exact Noble `verilator=5.020-1` and `yosys=0.33-5build2` for every ordinary shard and verifies both revisions before selection. t1183 passes at `Files=1, Tests=10`, locks those packages and their ordinary-only scope, and all workflow YAML parses. No duplicate workflow change is introduced.
- [x] **NO REGRESSION** — Under installed Verilator 5.046 and Yosys 0.64, the RAM-guarded exact t1508/t1522/t1537 suite reports `All tests successful` at `Files=3, Tests=12` in 414 seconds. Formerly failing lint, synthesis, public verifier, assertion-disabled/enabled build, and runtime checks pass alongside CLI, semantic, MCP, support, and artifact contracts. Product code, public behavior, mdBook, and downstream/SPECFORGE contracts are unchanged; exact hosted package proof remains part of the repaired-push qualification.

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
