# PUBLICATION-REGRESSION-REPAIRS: Current Publication Qualification Repairs

## Metadata

- Tree ID: `PUBLICATION-REGRESSION-REPAIRS`
- Status: `active`
- Roadmap lane: `R14 / regression qualification`
- Created: `2026-10-25`
- Last updated: `2026-10-25`
- Owner: repo-local workflow

## Goal

Resolve the concrete current regressions found during SEM .69.3 publication
qualification, with a separate verified commit for each causal repair.
SEM .69.3 retains full-CI, exact-SHA push/hosted qualification and subsequent
macOS relevance assessment. The catalog predecessor is committed at1946fd353.

## Non-Goals

- No producer/API/language expansion or weakened semantic assertions.
- No historical native-cause closure or special startup probes.
- No gate bypass, increased resource limit or changed submodule integration.

## Acceptance Criteria

- Retain actual failing output, canonical contract and current code/history evidence.
- Preserve supported cases and still-closed boundaries through focused public tests.
- Synchronize relevant book guidance and live ownership without inventing runtime claims.
- Follow TASK_ACCEPTANCE.md and COMMIT.md for each leaf; normal staged/hook gates pass.
- Return qualification to SEM .69.3 after pre-push repairs; later workflow follow-ups remain scheduled.

## Task Tree

- ID: `PUBLICATION-REGRESSION-REPAIRS`
  Status: `active`
  Goal: `Resolve current publication regressions and owned workflow follow-ups.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.1, PUBLICATION-REGRESSION-REPAIRS.2, PUBLICATION-REGRESSION-REPAIRS.3, PUBLICATION-REGRESSION-REPAIRS.4, PUBLICATION-REGRESSION-REPAIRS.5, PUBLICATION-REGRESSION-REPAIRS.6`

- ID: `PUBLICATION-REGRESSION-REPAIRS.1`
  Status: `done`
  Goal: `Align aggregate-alias refusal tests with admitted record actor outputs.`
  Acceptance: `T1259 currently rejects record outputs admitted by008e629ced1b7d1bd2ff1f56e39ff7e793721179 and expects actor inputs in diagnostics now saying packed record actor ports. Preserve storage alias/lowering/CLI checks; replace the obsolete output refusal with a valid packed-list actor-output refusal, retaining transaction-record and aggregate-bank controls with precise current messages. Confirm current local/imported/unused record-output positives and list/formal refusal through canonical T2033 and adjacent storage/writer tests. Clarify the existing mdBook boundary with no production change, new support claim, corpus/API/MCP expansion or altered source grammar. Verify focused tests, native book/source views, bounded metadata and staged/normal doctrines, then commit before .2.`
  Verification: `Guarded fresh before prove at1946fd353 retains T1259 failures at lines170/171 while independent T2033 passes. Git identifies the test last changed25c01f012 and producer admission/diagnostic changed008e629ced. The same-width valid list alias now supplies the still-closed actor-output control; transaction-record and aggregate-bank checks retain exact diagnostics. Guarded adjacent scalar/storage/writer/source tests report All tests successful in aggregate-alias-focused.json; native mdBook/POD/current copied source/index pass in aggregate-alias-book.json. Book explicitly names existing boundaries, with exact fresh +2-line/+128-byte aggregate authority, no ceiling change and no production/support/corpus/API/MCP change. Distinct re-derivation, falsification and durability legs plus source identities retain in publication-regression-repairs-20261025/aggregate-aliases.json. The catalog predecessor archive/clean duplicate retirement is retained there too. Staged/normal doctrines are mandatory before commit; full CI/push/hosted/macOS outcomes remain owned by SEM .69.3.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.1: retain precise aggregate alias refusal boundaries`

- ID: `PUBLICATION-REGRESSION-REPAIRS.2`
  Status: `pending`
  Goal: `Repair quiet strict-outdir fixture stdout expectations.`
  Acceptance: `After .1 commits, T1330 quiet fixtures must expect empty stdout while retaining success/stderr/complete file-domain assertions. Keep one existing nonquiet generation case as a positive Wrote control. Follow decision0117 quiet semantics and8e5dd7f34623f8b0dd792628d31a80ff6e36daf9; run T1330 and T2088 plus applicable book/gates. Do not change producer quiet behavior.`
  Verification: `P1 pre-push; exact failures, canonical references and repair plan are in docs/audits/isf-focused-index-refresh-20261025/publication-followups.json.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.3`
  Status: `pending`
  Goal: `Preserve conditional local-do dataflow assertions through physical formal allocation.`
  Acceptance: `After .2 commits, inspect current public authored binding and emitted artifact contracts for T1388. Preserve req-to-worker.addr dataflow, width and conditional start/done handshake through the allocated physical signal. Replace the stale raw addr literal without dropping the binding assertion or treating private names as authored endpoints; update stale test commentary and qualify focused formal/local-do cases.`
  Verification: `P1 pre-push; actual (= (isf_port_worker_addr req)) and matching worker read conflict with the stale raw-formal regex. Canonical isf-formal-source-binding-reports and isf-production-formal-scope cards plus FormalIdentityPlan own the current boundary; complete queue receipt retains.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.4`
  Status: `pending`
  Goal: `Refresh exact shared-datapath DTO goldens for nullable pulse delay.`
  Acceptance: `After .3 commits, inspect the complete public DTO/schema. Update T139/T140 exact full-object expectations for intentionally added pulse_delay_cycles null, preserving all contributor/binding/drive-intent fields and delayed-pulse sharing exclusion. Verify adjacent structural-binding and defensive-copy consumers. Keep producer fields and strong equality assertions.`
  Verification: `P1 pre-push;9dca2caa38964e07767112ce2765e7b28ab86fea adds nullable drive-family delay. Normalized semantic output-drive schema and generated-child named-completion cards own meaning. Both actual failures are retained in full2 and the queue receipt.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.5`
  Status: `pending`
  Goal: `Durably route the completed GitHub log-cache locality migration.`
  Acceptance: `Before next qualifying full CI/push, preserve .artifacts/push-readiness-20261025/gh-log-locality.json operational evidence in tracked data. Route GH XDG cache/state/temp usage through the existing locality card and relevant book guidance inside unchanged limits. Preserve copy/hash/use/delete/exact-residue proof and the after-delete local-cache query; leave ambiguously shared cache entries untouched. Normal docs/claim/doctrine gates and commit required.`
  Verification: `P1 pre-push durable handoff; operational migration already completed under SEM .69.3. Do not repeat a deletion or treat ignored evidence as committed documentation.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.6`
  Status: `pending`
  Goal: `Align task-tree adoption-guide Memory wording with derive-on-read revision policy.`
  Acceptance: `P2 scheduled after hosted qualification, macOS relevance review and the SEM .69.3 worktree compatibility repair, before saved POD return. Inspect live guide/consumers and decisions0067/0068/COMMIT, then replace stored latest-commit directions with active leaf/next action and exact Git accessor. Preserve historical evidence; qualify focused documentation/book/doctrine checks and commit.`
  Verification: `Read-only discovery at docs/TASK_TREE_README.md lines81/160/270 directs overwriting/naming latest commit in Memory, conflicting with current derive-on-read policy. Reproduce with rg -n latest.commit. Current startup instructions themselves derive revision correctly. This documentation defect does not block push; ownership/schedule are explicit.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PUBLICATION-REGRESSION-REPAIRS.2` | `pending` | After .1 commit, align quiet strict-outdir expectations while retaining a nonquiet progress control. |

## Decisions

- `2026-10-25`: Separate each causal regression repair; existing production contracts determine assertions. SEM .69.3 owns publication ordering; macOS history does not impose a renewed blanket hold.
- `2026-10-25`: Full2 was an administratively interrupted failing census, with no T1436 or complete-suite outcome. Qualifying full3 must set FSMGEN_T296_CHECKPOINT before launch.

## Blockers

- No external blocker for .2 after .1 commits. Full CI/push/hosted qualification remain pending, not successful.

## Acceptance Checklist — `.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual before output at t/1259-isf-aggregate-storage-type-aliases.t line 170 shows the formerly forbidden record output is accepted; line171 retains obsolete actor-inputs diagnostic expectations. Git source008e629ced explicitly admits record outputs and changes that suffix to actor ports; the unchanged independent T2033 passes supported record sources and still-closed list/formal cases. No current producer defect is inferred from a stale negative assertion.
- [x] **ADDRESSED (verified)** — The obsolete record-output negative now uses a declared packed list with the same packed width, retaining a real unsupported actor-port boundary. All three exact diagnostic suffixes match the current contract; transaction and bank refusals and original storage/parser/lowering/CLI assertions remain. Existing independent record-output positives and overlap refusals pass. The book clarifies those existing kinds, without changing runtime or support.
- [x] **NO REGRESSION** — All tests successful for the guarded eight-file scalar/storage/record-writer/source band, with exact command/status/complete output retained in aggregate-alias-focused.json/log.gz. Native mdBook/POD/current source-byte/index checks pass; git diff --check is clean. Fresh claim/reference/ceiling and complete staged/normal scripts/check_doctrines.sh gates are required before commit. Full CI remains a separate checkpointed publication qualification.
