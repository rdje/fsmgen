# COMMIT-GATE-PERFORMANCE: Faster commit validation with unchanged enforcement

## Metadata

- Tree ID: `COMMIT-GATE-PERFORMANCE`
- Status: `active`
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
  Status: `active`
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
  Status: `pending`
  Goal: `Remove duplicate complete live-document validation from the composed doctrine run.`
  Acceptance: `Keep standalone README validation complete. Compose routing/entrypoint checks with the already required LIVE-DOCUMENT-SIZE result through explicit driver dependency/command semantics. A missing or failed prerequisite must reject the composed gate; no unchecked environment flag or stale receipt may assert success. Preserve project-neutral checker boundaries, bootstrap wiring, full required logical coverage and readable diagnostics. Genuine malformed route/live-document controls and real integration qualify the change; synchronize docs and commit.`
  Verification: `pending .2`
  Commit: `pending`

- ID: `COMMIT-GATE-PERFORMANCE.4`
  Status: `pending`
  Goal: `Qualify the completed workflow and record observed runtime improvement.`
  Acceptance: `After implementation, compare actual baseline and optimized runs with source/input/command identities, per-check timings, complete logical and physical execution inventories, and explicit host/cache/state limits. Independent timing/call-count and genuine bad-input/failure controls must challenge the speed and coverage claims. Do not claim a universal speedup or full CI/publication success. Confirm normal hook validation, clean commits and bounded current docs; close this activity and restore the preserved source-delivery frontier.`
  Verification: `pending implementation`
  Commit: `pending`

## Decisions

- `2026-10-27`: User explicitly authorizes gate streamlining while retaining quality.
  Finish the dirty source slice before pivoting. Use one authoritative hook and
  within-run deduplication; persistent result caching is outside this plan.

## Blockers

- None. Full source/native/API/MCP/external/runtime/hosted qualification remains
  separately owned by the preserved required-delivery tasks.
