# COMMIT-GATE-PERFORMANCE: Faster commit validation with unchanged enforcement

## Metadata

- Tree ID: `COMMIT-GATE-PERFORMANCE`
- Status: `done`
- Roadmap lane: `infra/continuity; user-requested delivery workflow`
- Created: `2026-10-27`
- Last updated: `2026-10-27`
- Owner: repo-local workflow

## Goal

Reduce repeated validation work and failed-iteration latency while every successful
commit still satisfies all mandatory doctrines against its final staged state.
The director explicitly authorizes this work after asking about gate overhead.
The prior source slice is committed at be4928b7f and clean before activation.
Resume ISF-REDUCTION-DELIVERY.3.3.1.2.2.2 after this task is complete.

## Acceptance Criteria

- Preserve required checks, task evidence, documentation sync, same-volume data,
  per-slice commits and full CI/exact-SHA qualification before publication.
- One authoritative full local gate runs inside the mandatory pre-commit hook;
  optional preflight remains available for diagnostics. No persistent pass cache.
- Equivalent read-only verifier executions may be shared within one invocation;
  distinct roots, commands, states or failures must never acquire false success.
- Add observable timing and retain a full diagnostic mode. Local fail-fast may
  stop on failure, but success requires every registered check to have passed.
- Validate changed/invalid inputs, failed checks, standalone entrypoints,
  registry coverage and actual full-gate integration. Publish only measured,
  narrowly scoped runtime claims with distinct evidence legs and limits.
- Commit every completed slice through COMMIT.md; leave source delivery owned.

## Task Tree

- ID: `COMMIT-GATE-PERFORMANCE`
  Status: `done`
  Goal: `Deliver materially faster mandatory local verification without weakened checks.`
  Children: `COMMIT-GATE-PERFORMANCE.1, COMMIT-GATE-PERFORMANCE.2, COMMIT-GATE-PERFORMANCE.3, COMMIT-GATE-PERFORMANCE.4`

- ID: `COMMIT-GATE-PERFORMANCE.1`
  Status: `done`
  Goal: `Make the final hook authoritative and add timing/local fail-fast feedback.`
  Acceptance: `Inspect the existing driver/hook/COMMIT call chain and record actual baseline execution. Add optional per-check timing and local fail-fast while default full diagnostic behavior and --list remain compatible. A successful timed/fail-fast run still executes every registered check; failures return nonzero and never print all-passed. Amend COMMIT/bootstrap/doctrine/book guidance so the mandatory final-index hook supplies the full gate once; optional preflight is diagnostic, not a cached pass. Keep hooks enabled and normal git commit semantics. Add a durable decision and meaningful orchestration/negative controls, qualify the real driver and commit this transition under the existing double-check workflow before using the new cadence.`
  Verification: `Actual baseline completes every registered doctrine: parent wall78.336s, with separate POSIX time retained; LIVE-DOCUMENT-SIZE32.177s and README-ENTRYPOINT31.289s dominate this observation. Scripts show manual COMMIT step plus normal hook both invoke the full driver and README delegates live validation again. Initial setup add used a wrong focused-index path; the captured run therefore uses workingtree validation with prior index, documented in its input identity record rather than claimed identical-candidate benchmarking. New independent modes test fails against the previous runner. Optional per-check timing uses Bash time; local fail-fast stops after a failed check and explicitly discloses unrun checks. Default CI diagnostics still run the whole registry; any success requires all checks. All tests successful Files=1 Tests=5 for registry/mode/failure/changed-content/unknown/missing-member controls. Changed content with preserved size and whole-second mtime is freshly rejected after a passed preflight. Syntax, bootstrap, task integrity and authenticated decision checks pass; guarded book build and source projection refresh pass. Decision0122 and COMMIT/AGENTS/doctrine/book make the final-index hook authoritative with no persistent cache or hook bypass; this transition still takes the old manual-plus-hook qualification. Re-derive: actual timings and source call graph. Falsify: POSIX/parent timing, expected registry and actual negative controls. Durability: tracked policy/code/test and docs/audits/commit-gate-performance-1-20261027.json.gz. Full comparative speed/coverage qualification remains .4; no full CI or hosted result. The initial staged manual run rejects newly crossed rationale rollover and compatibility-index growth declarations; acknowledge rollover and measure allowed growth within unchanged hard ceilings, then complete staged/manual and normal hook checks before using the new cadence.`
  Commit: `COMMIT-GATE-PERFORMANCE.1: use one authoritative commit gate with timed fail-fast`

  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S scripts/check_doctrines.sh identifies 2cfe9cda3. COMMIT step8 and the hook duplicate full validation; the README checker delegates the already registered live-document suite. The actual baseline trace and source identities retain the execution chain.
  - [x] **ADDRESSED (verified)** — Make the mandatory final-index hook authoritative, keep optional preflight diagnostic, and add per-check timings/local fail-fast with complete success coverage. Record decision0122 and preserve independent CI, task evidence and all publication requirements. No cached pass grants commit permission.
  - [x] **NO REGRESSION** — All tests successful Files=1 Tests=5 for complete registry, default/timed/fail-fast outcomes, changed content, missing executables and unknown flags. Bash syntax, bootstrap, task/decision integrity and guarded book/source checks pass. The transition retains manual staged scripts/check_doctrines.sh plus the normal final hook before adopting the new cadence.

- ID: `COMMIT-GATE-PERFORMANCE.2`
  Status: `done`
  Goal: `Execute equivalent read-only delegated verifiers once per invocation.`
  Acceptance: `Inspect exact root/command/proof contracts before sharing work in adapter and neutral core runners. Preserve every logical proof ID, scope diagnostic and failure, with no cross-run cache or skipped required role. Verify equivalent commands share execution, distinct commands/roots do not, and failed or changed inputs cannot produce success. Retain standalone package behavior and focused existing lifecycle checks; measure actual executions and update the contract/docs before commit. Split only if needed for safe review.`
  Verification: `git log -S execute_core_verifier identifies 25c815326: each role independently executes its declared command despite fixed root/environment/no args/null stdin. Existing doctrine contracts require deterministic read-only checks. Add explicit --share-read-only-verifiers to adapter and neutral runners; the project wrapper selects it, default standalone per-role behavior remains unchanged. Exact executable paths share only process-local results under stable validation inputs; distinct paths stay distinct even with identical bytes. Every proof token remains emitted and every core failure remains attributed to each consuming role; missing/executable checks stay per obligation. All tests successful Files=2 Tests=35 for existing lifecycle and new sharing controls. Fixture physical calls fall from seven to two with all seven proof IDs retained; later same-size/same-whole-second-mtime changed verdicts are freshly rejected, distinct roots really execute, absent/non-executable commands reject, and shared failures never produce green. Perl/Bash syntax, source projection and guarded book build pass. Re-derive: runner control flow and actual marker counts. Falsify: independent expected proof list, separate executable paths and fresh failed inputs. Durability: tests/contracts and docs/audits/commit-gate-performance-2-20261027.json.gz; actual final hook supplies required composed integration. No cross-run cache, generic speedup, full CI or hosted claim.`
  Commit: `COMMIT-GATE-PERFORMANCE.2: share equivalent read-only verifier executions`

  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S execute_core_verifier identifies 25c815326. Adapter/core loops execute the same declared verifier repeatedly with fixed root/environment/arguments/stdin. The exact call graph and original read-only doctrine contract establish the safe sharing boundary.
  - [x] **ADDRESSED (verified)** — Explicit per-invocation read-only sharing preserves every proof token and per-role failed result, while standalone defaults remain per-role and new invocations always execute again. Synchronize neutral contract, local doctrine, fact route and mdBook.
  - [x] **NO REGRESSION** — All tests successful Files=2 Tests=35 for complete lifecycle, literal proof coverage, equivalent/distinct commands, real roots, failures, missing executables and same-size/mtime changed inputs. Syntax, source sync and guarded book build pass; the mandatory normal hook validates the staged integration.

- ID: `COMMIT-GATE-PERFORMANCE.3`
  Status: `done`
  Goal: `Remove duplicate complete live-document validation from the composed doctrine run.`
  Acceptance: `Keep standalone README validation complete. Compose routing/entrypoint checks with the already required LIVE-DOCUMENT-SIZE result through explicit driver dependency/command semantics. A missing or failed prerequisite must reject the composed gate; no unchecked environment flag or stale receipt may assert success. Preserve project-neutral checker boundaries, bootstrap wiring, full required logical coverage and readable diagnostics. Genuine malformed route/live-document controls and real integration qualify the change; synchronize docs and commit.`
  Verification: `git log -S LIVE_DOCUMENT_CHECKER identifies 18e2dcbc6: README always delegates the complete suite already registered as LIVE-DOCUMENT-SIZE. Add explicit --routing-only for composed routing/landing-page checks; standalone default remains full. The driver accepts the composed README result only after actual same-invocation LIVE success; its internal prerequisite starts false, no env/receipt can assert it. Collect-all still executes routing diagnostics after prerequisite failure and rejects README; fail-fast rejects sooner. All tests successful Files=2 Tests=16 for real standalone/partial route, excessive pressure, adapter proof, malformed route and staged/worktree controls plus driver modes; after refining collect-all diagnostics, Files=1 Tests=6 pass for complete registry/modes/failed and missing prerequisites. Partial scope is explicit and never prints complete pressure success. CGP-D1 fixed: real Git staged/worktree positive and negative controls use the existing Git directory with separate same-volume fixture index/objects, without init/config/commit or real-index writes. Initial tests expose stale task growth declarations and an incorrect expected diagnostic spelling; correct declarations within unchanged ceilings and the oracle, retain raw failures. Syntax, source projection and final guarded book build pass. Re-derive: call graph and actual standalone/composed outcomes. Falsify: missing/failed prerequisite, actual bad destination/marker and real index disagreement. Durability: code/tests/docs and docs/audits/commit-gate-performance-3-20261027.json.gz; normal final hook qualifies staged integration. Comparative timing remains .4; no full CI/hosted claim.`
  Commit: `COMMIT-GATE-PERFORMANCE.3: compose README routing with verified pressure checks`

  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S LIVE_DOCUMENT_CHECKER identifies 18e2dcbc6. README delegates the entire live-document suite after the driver already registered and executed it. The affected negative test also creates a separate Git repository contrary to the director's boundary.
  - [x] **ADDRESSED (verified)** — Explicit routing-only composition requires actual same-invocation live-document success and preserves collect-all diagnostics, complete standalone validation and visible partial scope. Replace the Git fixture with this repository's isolated alternate index/object store and close CGP-D1.
  - [x] **NO REGRESSION** — All tests successful Files=2 Tests=16, followed by Files=1 Tests=6 for the final collect-all refinement. Real stale markers, excessive destination pressure, missing/failed prerequisites, complete registry modes and actual index/worktree disagreement reject. Source sync and final guarded book build pass; the normal mandatory hook validates the final stage.

- ID: `COMMIT-GATE-PERFORMANCE.4`
  Status: `done`
  Goal: `Qualify reduced execution work and record actual timings with their limits.`
  Children: `COMMIT-GATE-PERFORMANCE.4.1`
  Acceptance: `After implementation, compare actual baseline and optimized runs with source/input/command identities, per-check timings, complete logical and physical execution inventories, and explicit host/cache/state limits. Independent timing/call-count and genuine bad-input/failure controls must challenge the speed and coverage claims. Do not claim a universal speedup or full CI/publication success. Confirm normal hook validation, clean commits and bounded current docs; close this activity and restore the preserved source-delivery frontier.`
  Verification: `All required normal hooks pass through .3, including every registered doctrine and fresh task acceptance. Actual baseline/optimized complete profiles pass all12 registered checks and retain all7 unique core and17 adapter proof roles. Saved raw logs derive live suites2 to1 and physical delegated programs48 to14 per driver invocation; cadence source/transition receipts prove mandatory full local runs2 to1 per commit. Baseline parent wall78.336s agrees with independent POSIX78.33s; optimized120.834s agrees with120.80s. Do not call this an elapsed improvement: baseline used prior index/worktree controls after a setup-add mistake; selected staged states and host load differ. .4.1 finds actual competing work (load34.68 on12 logical CPUs, sibling repo cwd observed read-only), and stage trace locates existing authentication cost; unchanged authentication implementation is independently Git-diff confirmed. The initial wall comparison is invalid evidence of a speedup. No matched quiet-host leg, exact causal partition or general percentage is claimed. Saved reader independently enumerates complete registry/proof roles, validates source hashes and parent/POSIX timing, and rejects four missing-check/missing-proof/altered-source/NaN controls; prior actual production negative controls and marker counts remain retained. The three new book count rows carry derived-gate dispositions under the declared general-book review group, with distinct production/oracle/durability paths. Source projection and guarded book build pass. Re-derive: exact sources/raw timings/physical execution inventory. Falsify: independent timing/literal role list/actual failing inputs and saved-reader controls; retain the slower run. Durability: docs/audits/commit-gate-performance-20261027/{receipt.json.gz,verify.py} and preceding slice receipts. Full CI/hosted/publication qualification stays with required source delivery. Close this workflow activity and restore ISF-REDUCTION-DELIVERY.3.3.1.2.2.2 after the final normal hook/commit.`
  Commit: `COMMIT-GATE-PERFORMANCE.4: qualify reduced work and retain timing limits`

  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S execute_core_verifier identifies 25c815326 and the original repeated execution. Actual complete logs establish the duplication; .4.1 diagnoses the unexpected wall result as an invalid comparison with demonstrated host contention and changed selected states, retaining the missing isolation leg explicitly.
  - [x] **ADDRESSED (verified)** — Qualify the authoritative hook, read-only sharing and explicit README composition with complete raw coverage, exact source identities and independently checked execution inventory. Preserve the slower observation and claim reduced work only; close CGP-D1/CGP-D2 and restore the owned source frontier.
  - [x] **NO REGRESSION** — All tests successful in the retained production focused checks (Files=2 Tests=35 and Files=2 Tests=16 plus final driver Files=1 Tests=6). Production code is unchanged in this qualification slice. The fresh saved reader rejects four actual altered-receipt controls and verifies complete registry/proof coverage, source hashes and independent timing agreement. Book/source checks pass; the final normal hook qualifies final staged documentation and evidence.

- ID: `COMMIT-GATE-PERFORMANCE.4.1`
  Status: `done`
  Goal: `Root-cause unexpectedly slow optimized live-document validation before claiming speed improvement.`
  Acceptance: `The first optimized complete run passes but takes 120.834s, with 100.442s inside LIVE-DOCUMENT-SIZE despite fewer physical calls. Profile actual child stages with independent elapsed timing and inspect exact process/input identities. Resolve a code regression if present; if host or input workload explains it, demonstrate that cause and limit the comparison honestly. Preserve all checks and own any new defect before closing.`
  Verification: `Targeted timestamped Bash execution passes and locates8.05s adapter dispatch,35.50s neutral core,6.11s reference authority and25.73s ceiling authentication. Read-only process/load evidence demonstrates external CPU contention (load34.68,12 logical CPUs, concurrent sibling-repository jobs); no external work is stopped or changed. Git diff confirms all authentication implementation unchanged since baseline. POSIX CPU work is63.93s optimized versus73.16s baseline while wall grows, consistent with contention/wait and input-state confounding. Exact causal partition is not isolated: close the invalid-comparison defect by narrowing claims to verified work reduction, preserve all evidence, and explicitly withhold elapsed-speedup claims. No software regression is established by the unmatched timings.`
  Commit: `owned by .4 qualification`

## Decisions

- `2026-10-27`: User explicitly authorizes gate streamlining while retaining quality.
  Finish the dirty source slice before pivoting. Use one authoritative hook and
  within-run deduplication; persistent result caching is outside this plan.

## Blockers

- None. Full source/native/API/MCP/external/runtime/hosted qualification remains
  separately owned by the preserved required-delivery tasks.

## Owned defects

- `CGP-D1` — fixed and verified in .3, P1 policy compliance in the directly affected README test.
  Reproduce by reading the staged-result subtest in
  `t/1553-readme-routed-destination-pressure.t`: it calls git init/config/add/commit
  in a new fixture repository. That conflicts with the director's write boundary.
  Own and repair in .3 before running it: retain genuine Git staged/worktree
  rejection using this repository's Git directory with an isolated same-volume
  alternate index/object store; no other repository or real index writes.

- `CGP-D2` — resolved in .4.1 as invalid benchmark interpretation, P1 performance qualification. Reproduce with the saved
  optimized profile command/report: all doctrines pass but wall120.834s exceeds
  the earlier observed78.336s; live validation takes100.442s. Do not attribute
  improvement from call counts alone. .4.1 retains source/stage/host evidence and
  the missing isolation leg; signoff asserts reduced execution work only.
