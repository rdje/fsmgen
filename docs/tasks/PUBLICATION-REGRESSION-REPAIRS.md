# PUBLICATION-REGRESSION-REPAIRS: Current Publication Qualification Repairs

## Metadata

- Tree ID: `PUBLICATION-REGRESSION-REPAIRS`
- Status: `active`
- Roadmap lane: `R14 / regression qualification`
- Created: `2026-10-25`
- Last updated: `2026-11-01`
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
  Children: `PUBLICATION-REGRESSION-REPAIRS.1, PUBLICATION-REGRESSION-REPAIRS.2, PUBLICATION-REGRESSION-REPAIRS.3, PUBLICATION-REGRESSION-REPAIRS.4, PUBLICATION-REGRESSION-REPAIRS.5, PUBLICATION-REGRESSION-REPAIRS.6, PUBLICATION-REGRESSION-REPAIRS.7, PUBLICATION-REGRESSION-REPAIRS.8, PUBLICATION-REGRESSION-REPAIRS.9, PUBLICATION-REGRESSION-REPAIRS.10, PUBLICATION-REGRESSION-REPAIRS.11, PUBLICATION-REGRESSION-REPAIRS.12, PUBLICATION-REGRESSION-REPAIRS.13, PUBLICATION-REGRESSION-REPAIRS.14, PUBLICATION-REGRESSION-REPAIRS.15, PUBLICATION-REGRESSION-REPAIRS.16, PUBLICATION-REGRESSION-REPAIRS.17, PUBLICATION-REGRESSION-REPAIRS.18, PUBLICATION-REGRESSION-REPAIRS.19, PUBLICATION-REGRESSION-REPAIRS.20, PUBLICATION-REGRESSION-REPAIRS.21, PUBLICATION-REGRESSION-REPAIRS.22, PUBLICATION-REGRESSION-REPAIRS.23, PUBLICATION-REGRESSION-REPAIRS.24, PUBLICATION-REGRESSION-REPAIRS.25, PUBLICATION-REGRESSION-REPAIRS.26, PUBLICATION-REGRESSION-REPAIRS.27`

- ID: `PUBLICATION-REGRESSION-REPAIRS.1`
  Status: `done`
  Goal: `Align aggregate-alias refusal tests with admitted record actor outputs.`
  Acceptance: `T1259 currently rejects record outputs admitted by008e629ced1b7d1bd2ff1f56e39ff7e793721179 and expects actor inputs in diagnostics now saying packed record actor ports. Preserve storage alias/lowering/CLI checks; replace the obsolete output refusal with a valid packed-list actor-output refusal, retaining transaction-record and aggregate-bank controls with precise current messages. Confirm current local/imported/unused record-output positives and list/formal refusal through canonical T2033 and adjacent storage/writer tests. Clarify the existing mdBook boundary with no production change, new support claim, corpus/API/MCP expansion or altered source grammar. Verify focused tests, native book/source views, bounded metadata and staged/normal doctrines, then commit before .2.`
  Verification: `Guarded fresh before prove at1946fd353 retains T1259 failures at lines170/171 while independent T2033 passes. Git identifies the test last changed25c01f012 and producer admission/diagnostic changed008e629ced. The same-width valid list alias now supplies the still-closed actor-output control; transaction-record and aggregate-bank checks retain exact diagnostics. Guarded adjacent scalar/storage/writer/source tests report All tests successful in aggregate-alias-focused.json; native mdBook/POD/current copied source/index pass in aggregate-alias-book.json. Book explicitly names existing boundaries, with exact fresh +2-line/+128-byte aggregate authority, no ceiling change and no production/support/corpus/API/MCP change. Distinct re-derivation, falsification and durability legs plus source identities retain in publication-regression-repairs-20261025/aggregate-aliases.json. The catalog predecessor archive/clean duplicate retirement is retained there too. Staged/normal doctrines are mandatory before commit; full CI/push/hosted/macOS outcomes remain owned by SEM .69.3.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.1: retain precise aggregate alias refusal boundaries`

- ID: `PUBLICATION-REGRESSION-REPAIRS.2`
  Status: `done`
  Goal: `Repair quiet strict-outdir fixture stdout expectations.`
  Acceptance: `After .1 commits, T1330 quiet fixtures must expect empty stdout while retaining success/stderr/complete file-domain assertions. Keep one existing nonquiet generation case as a positive Wrote control. Follow decision0117 quiet semantics and8e5dd7f34623f8b0dd792628d31a80ff6e36daf9; run T1330 and T2088 plus applicable book/gates. Do not change producer quiet behavior.`
  Verification: `Exact T1330 bytes equal the retained bff84006b full2 source, binding its empty-stdout failures to the current file. Decision0117 and8e5dd7f identify the intentional quiet-output predicate. One existing outdir case now omits quiet and retains its generated-top Wrote positive check; remaining quiet cases assert empty stdout, with every success/stderr/complete file-domain and machine-report assertion preserved. Guarded T1330/T2088 report All tests successful, Files=2 Tests=69, with complete output/status in quiet-fixture-focused.json/log.gz. Native mdBook/POD/current built source/index pass in quiet-fixture-book.json; ATL guidance now explains the existing flag behavior. quiet-expectations.json retains exact source hashes/assertion domain and distinct re-derivation/falsification/durability legs; the book authority records the exact narrow delta with no ceiling change. No producer/API/source grammar or support change. Staged/normal doctrine gates are required before commit. Next .7 observes genuinely required .3 contract intakes under the already-existing SEM .93/ISF-REDUCTION .16 before-publication conditions; no original timeout causality is inferred.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.2: align quiet fixture stdout expectations`

- ID: `PUBLICATION-REGRESSION-REPAIRS.3`
  Status: `done`
  Goal: `Preserve conditional local-do dataflow assertions through physical formal allocation.`
  Acceptance: `After .2 and its required intake observation .7 commit, inspect current public authored binding and emitted artifact contracts for T1388. Preserve req-to-worker.addr dataflow, width and conditional start/done handshake through the allocated physical signal. Replace the stale raw addr literal without dropping the binding assertion or treating private names as authored endpoints; update stale test commentary and qualify focused formal/local-do cases. Bound the do/worker checks to their emitted state blocks; assert internal eight-bit carrier declaration, req-to-carrier assignment, worker consumption, start/done handshake and unchanged authored public binding projection.`
  Verification: `The unchanged original test bytes equal bff full2; its line86 expected (addr req), while the retained actual FSM declares internal isf_port_worker_addr width8, writes req in parent_do and consumes that carrier in worker_update. Git32642d54c plans scoped identities; separate57b6495f8 activates production FormalLowering. Canonical cards and the qualified .7 native binding record preserve authored addr/req separately. The test now bounds each dataflow/handshake assertion to its actual emitted state, requires internal/non-public eight-bit storage, checks worker consumption and exact done-signal identity, and independently verifies the public authored-binding projection. The stale top comment now describes actual local/bound/generated lowering scope without a runtime claim. Guarded T1388/T1243/T1961 pass All tests successful, Files=3 Tests=14; the final tightened T1388 check separately passes Files=1 Tests=6. Native mdBook/POD/source/index pass. local-do-bindings.json and exact history/focused/book receipts retain distinct source re-derivation, original-oracle falsification and durable identities. The book clarifies the existing direct private-carrier example. No producer, DSL, support/corpus/API/MCP change. Final metadata/book-source and complete staged/normal doctrine gates are required before commit; full CI remains separate.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.3: check private local-do binding dataflow`

- ID: `PUBLICATION-REGRESSION-REPAIRS.4`
  Status: `done`
  Goal: `Refresh exact shared-datapath DTO goldens for nullable pulse delay.`
  Acceptance: `After .3 commits, inspect the complete public DTO/schema. Before changing goldens, capture the complete tested candidate metadata and realized-child output-drive families from byte-exact existing fixtures through the public HDLGenerator API; exclude only the same three delegated forward-IR keys as the existing tests, with no new field filtering. Update T139/T140 exact full-object expectations for intentionally added pulse_delay_cycles null, preserving all contributor/binding/drive-intent fields and delayed-pulse sharing exclusion. Verify adjacent structural-binding and defensive-copy consumers. Keep producer fields and strong equality assertions.`
  Verification: `Before golden edits, byte-exact original T139/T140 fixtures produce complete candidate and child-family DTOs through the public HDLGenerator API. The first collector used an unsupported name accessor and failed; its error/recipe remains intact. Public documented instance_name corrects the collector in a separate qualified slot. Actual families carry pulse_delay_cycles null; drive_intent retains its distinct existing shape. Five literal undef additions are the only test delta; no field filtering or equality weakening. Introducing9dca2caa389 and unchanged producer hashes retain the delayed-pulse sharing exclusion without a fresh native runtime claim. Guarded four-file metadata/structural/cache band reports All tests successful, Files=4 Tests=8. Native mdBook/POD/current source/index checks all pass. Exact inputs, failed/qualified observations, recipes, before/after test hashes, unchanged producer identities and distinct re-derivation/falsification/durability legs are in publication-regression-repairs-20261025/shared-dto-repair.json and referenced receipts. Fresh metadata/reference/claim and staged/normal doctrines precede commit; full CI/push remain separate.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.4: retain nullable delay in exact shared DTO goldens`

- ID: `PUBLICATION-REGRESSION-REPAIRS.5`
  Status: `done`
  Goal: `Durably route the completed GitHub log-cache locality migration.`
  Acceptance: `Before next qualifying full CI/push, preserve .artifacts/push-readiness-20261025/gh-log-locality.json operational evidence in tracked data. Route GH XDG cache/state/temp usage through the existing locality card and relevant book guidance inside unchanged limits. Preserve copy/hash/use/delete/exact-residue proof and the after-delete local-cache query; leave ambiguously shared cache entries untouched. Normal docs/claim/doctrine gates and commit required.`
  Verification: `The exact original gh-log-locality.json and complete prior-run job inventory are now retained in tracked data, with hashes and unique rdje/fsmgen/run/revision identity. The original copy/hash/use/delete/exact-residue and successful after-delete local-cache query observations remain intact; no deletion repeats. A fresh read-only check confirms the exact local cache size/SHA/device and old filename absence, without claiming global cache emptiness. Existing locality card questions/facts remain, with the concrete wrapper routed to its existing book section and within unchanged knowledge_cards authority. Focused locality/Knowledge Map checks and native mdBook/POD/current source/index checks pass. gh-locality-routing.json names distinct original/source, separating after-delete use and tracked durability legs plus the external read-only residue/auth boundary. Fresh metadata/reference/claim and complete staged/normal doctrine gates precede commit. The first staged gate retained an omitted generated card-date shard, stale inventory after registry remeasurement and missing fresh checklist; final staging/metadata/checklist correct these under the same leaf without bypass. After clean commit return to SEM .69.3 fresh checkpointed full3; no full-CI/push outcome is claimed.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.5: route GitHub CLI state through local storage`

- ID: `PUBLICATION-REGRESSION-REPAIRS.6`
  Status: `pending`
  Goal: `Align task-tree adoption-guide Memory wording with derive-on-read revision policy.`
  Acceptance: `P2 scheduled after hosted qualification, macOS relevance review and the SEM .69.3 worktree compatibility repair, before saved POD return. Inspect live guide/consumers and decisions0067/0068/COMMIT, then replace stored latest-commit directions with active leaf/next action and exact Git accessor. Preserve historical evidence; qualify focused documentation/book/doctrine checks and commit.`
  Verification: `Read-only discovery at docs/TASK_TREE_README.md lines81/160/270 directs overwriting/naming latest commit in Memory, conflicting with current derive-on-read policy. Reproduce with rg -n latest.commit. Current startup instructions themselves derive revision correctly. This documentation defect does not block push; ownership/schedule are explicit.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.7`
  Status: `done`
  Goal: `Observe the next required binding-contract intakes and preserve explicit historical query dispositions.`
  Acceptance: `Completed genuinely required binding/Knowledge Map query intake under predeclared exact inputs, literal predicates, bounded60-second/88/4096 programme, clocks/traces/streams and authenticated owned settlement. No spent-source/main/startup replay or inferred historical host cause. Saved-only finite-case/adverse checks, authority disposition and book/normal gates qualify the intake. Full original contract remains in2b6dc1a4 task/history.`
  Verification: `Both current intakes finish integer0 without timeout, with complete streams/traces and absent own groups. contract.json binds the literal Knowledge Map route and Git-derived T1388 source/T1243 binding row; observe.py/verify.py retain exact programme/input/source/clocks and finite-case omitted/extra/covaried/status/type/recipe/settlement controls. normal-query-intake-focused statuses are0. authority-disposition.json retains original failures, missing defaults-schedule slot and invalid diagnostic parent; original provider telemetry is unavailable through current exec/session APIs, without claiming global log absence. SEM .93/ISF-REDUCTION .16 original causes stay open; before-publication observation/disposition is met. No historical cause, raw-root/full-environment or latency-distribution claim. Exact original details/routes remain in2b6dc1a4 source/history.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.7: qualify normal publication query observations`

- ID: `PUBLICATION-REGRESSION-REPAIRS.8`
  Status: `active`
  Goal: `Diagnose and resolve the current T1437 memory interruption without weakening guards or coverage.`
  Acceptance: `P1 pre-push. Full3 at88a0834fdf records guard137 after occupied host capacity89.2 reaches fixed88 while T1437 is active; original per-process allocation at that instant is missing, so do not blame the test or other apps without evidence. After the full3 outcome commit and due cleanup .9, inspect canonical AXI contracts/code/tests/book and declare exact focused input/programme, progress/memory observations and distinguishing controls before any collector/source change. Use focused checks under unchanged88/4096, retain first outcomes and separate occupied capacity from kernel pressure. Fix a reproduced current cause at the correct production/test boundary, preserving every assertion/case and public behavior; do not mask a leak by dropping coverage. If the cause does not reproduce, retain the original attribution gap and qualify a safe current path explicitly. Commit each completed slice before fresh clean full CI; no broad retry or higher cap merely to seek a pass. Full4 needs its own live journal and explicit t296 checkpoint.`
  Verification: `Owned current resource constraint, distinct from historical native startup. Full3 reports prior repaired test files and T1436 successful, but no T1437/full-suite/VIAL/book/checkpoint outcome. The guard named only the occupied-capacity trigger. No current allocation-cause diagnosis or fix is claimed.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.8.1, PUBLICATION-REGRESSION-REPAIRS.8.2, PUBLICATION-REGRESSION-REPAIRS.8.3`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.9`
  Status: `done`
  Goal: `Complete the due artifact cleanup before another long verification run.`
  Acceptance: `Completed due same-volume artifact census using authenticated installed collector and exclusive20261025 wrapper. Preserve all candidates absent exact disposal authority; saved-only replay and adverse controls, latest-only cleanup record and focused book/source/normal gates. Exact full contract and source remain in1a389cdb task/history.`
  Verification: `Committed due census from2b3ca9bbe. Independent rg/os.walk membership covers root/six Rust paths with Git/symlink/volume exclusions. No deletion attempted; metadata/membership only, no content/reclaimable-byte claim. Saved replay rejects missing-member/unsafe-path/boolean-size/invented-removal. artifact-census evidence retains original programme/source/results; latest-only date and saved-reader book route updated. First zero-delta aggregate-authority refusal retained and prior authority restored. Full detailed evidence remains in1a389cdb and actor-dependent-default-first-gate source.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.9: complete due artifact census`

- ID: `PUBLICATION-REGRESSION-REPAIRS.10`
  Status: `pending`
  Goal: `Verify and repair any main-push commit-subject range gap in CI.`
  Acceptance: `P2 after hosted qualification, macOS review, worktree compatibility and .6 guide repair, before POD return. This is an unverified workflow-range hypothesis, not a publication hold. Inspect actual checkout/event before/head refs through published GitHub contracts and project-owned Git history; verify whether origin/main..HEAD is empty on main pushes and whether PR synthetic merges affect selection. Independently inspect the actual pre-push subject range. If a real gap is confirmed, own a separate causal repair with complete intended range/subject controls, current CI-selection tests, book and normal gates, without rewriting history or writing any other repository. If not confirmed, close the hypothesis with exact evidence.`
  Verification: `Read-only workflow inspection sees origin/main selected as base, followed by git log base..HEAD. Current observation does not prove event checkout behavior; source/next-step note is retained in commit-subject-range-review.json. No guard change, failure classification or new blocker is inferred.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.8.1`
  Status: `done`
  Goal: `Commit the exact focused memory study contract and correct superseded live publication wording.`
  Acceptance: `Completed exact unfiltered T1437 study preflight from clean6c07ae16d, preserving full3 source/input identities, original137 and causal gaps under fixed88/4096. Declare /usr/bin/time -l prove programme, exclusive live journal and passive owned-RSS/host/clock observations before launch. No native opt-in or old-main replay. Correct superseded publication hold from exact authorization history. Full original contract remains in c8d93bc3 task/history.`
  Verification: `Committed exact unfiltered T1437 preflight from6c07ae16d with source hashes/exclusive journal under88/4096; profiler smoke proves reporting only. git log -S authenticates superseded old publication hold and director54ac5589bc7a replacement. Hosted qualification precedes macOS review. No memory-cause/fix/test/full credit. t1437-preflight and exact c8/current history retain complete original evidence and causal gaps.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.8.1: qualify focused memory study contract`

- ID: `PUBLICATION-REGRESSION-REPAIRS.8.2`
  Status: `done`
  Goal: `Observe the complete unchanged T1437 focused run under fixed memory guards.`
  Acceptance: `Completed declared exclusive t1437-focused-1 programme after clean .8.1, preserving full first TAP/resource output and passive owned-process/host clocks under88/4096, without native opt-in, source/case changes or original allocation attribution. Declared read-only lsof FD metadata distinguishes open inputs/stdio, never stack location; no signal/sampling profiler. Full original contract/source and all first outcomes remain in c8d93bc3 task/history.`
  Verification: `Committed unchanged T1437 actual0, Files1 Tests115,739037-byte output and16 passive observations; no guard trip. First137 attribution/kernel-pressure gaps retain. Owned settlement and saved checks qualify focused observation only. FD metadata identifies provider coupling, not stack location; director .12 orders independent provider/obsolete retirement. First size/container refusals and same-card source-preserving curation retain. All detailed evidence/routes remain in c8/current task/history.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.8.2: retain complete focused memory observation`

- ID: `PUBLICATION-REGRESSION-REPAIRS.8.3`
  Status: `done`
  Goal: `Resolve a reproduced current memory cause or qualify a safe current retry path.`
  Acceptance: `Completed resource disposition: do not repair an unreproduced cause. Provider .12.1/.12.2 precedes fresh full4; changed source needs fresh checks. Retirement .12.3/.11 follows publication/macOS/worktree/.6/.10. Full exact contract remains in c8 task/history.`
  Verification: `5ccc32d9d retains unchanged115-case0 T1437/fixed guards/settlement; saved checks never relaunch. Original full3 status137/attribution gaps remain. safe-path-disposition declares exclusive clean full4/checkpoint after provider/fresh compatibility under88/4096; old pass grants no new-source/full credit. Book separates focused/full qualification. Historical macOS causes stay post-push, without blanket hold. Detailed source/evidence remain in c8 history.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.8.3: qualify current path and order parser replacement`

- ID: `PUBLICATION-REGRESSION-REPAIRS.11`
  Status: `pending`
  Goal: `Verify and repair the legacy yes_no negative ARRAY-callback dispatch defect.`
  Acceptance: `P2 after required publication/macOS/worktree and .6/.10 follow-ups, then the director-ordered legacy retirement review .12, before POD return. If the component is verified obsolete and removed, close this issue by verified removal instead of repairing dead code; if retained for a concrete current purpose, reproduce and repair it. The read-only owned-FD intake led to tracked plugin/yesno.plg: its no branch tests ref of the Yes callback at index1 before invoking the No ARRAY callback at index2. First establish the published plugin-loading/callback interface and reproduce No plus an ARRAY callback with an absent/non-ARRAY Yes callback. If reproduced, fix the selector at the correct boundary with meaningful yes/no CODE/ARRAY/absent callback and stdin behavior checks, book and normal gates. Preserve existing behavior outside the defect; inspect no other Git repository implementation. This finding does not explain T1437 allocation or create a new publication hold.`
  Verification: `Source index mismatch is observed; public-interface reproduction and impact verification are pending. Ownership/schedule are explicit; no fix or runtime diagnosis is claimed.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.12`
  Status: `active`
  Goal: `Replace Lispish parser lookup through PPlugin and retire obsolete legacy modules.`
  Acceptance: `Director steering2026-10-25: these old modules should normally be removed; inspection needs a specific current purpose, and retained code needs an explanation of useful for what. The follow-up explicitly requires a robust Lispish parser lookup without the PPlugin layer. Keep .8.2 running and commit its outcome before any task pivot or removal. After .8.3 clean disposition, prioritize parser contract/provider .12.1/.12.2 before the next full4, following the director’s explicit replacement request. General table/plugin retirement .12.3 stays after required publication/macOS/worktree and .6/.10, before applicable callback .11 and saved POD return. Use targeted own tracked callers, public entrypoints/contracts, packaging/tests/book and a bounded dynamic-dispatch review; source age or zero static hits alone is insufficient. Remove obsolete code with meaningful current feature checks and book/docs sync. Retain only evidenced current behavior, naming the concrete feature/caller; do not retain an obsolete cluster merely because its members refer to each other. Current FSM/ISF/PPIF frontends call Lispish::multi, and Lispish::single obtains its parser through PPlugin->_get_parser. Replace that required lookup with an explicit provider independent of PPlugin, with repository-derived paths and no ambient-CWD or legacy discovery dependency. Preserve actual supported syntax, AST values/shapes, diagnostics and file/scalar-reference entrypoints, including current FSM/ISF/PPIF consumers; inspect the grammar and public parser contract before choosing direct grammar compilation versus a replacement reader. Do not implement against guesses or assume LinkedSpec is independent without checking the owned caller chain. Keep input/source identities and meaningful compatibility/error/CWD controls. Do not attribute the original .8 memory interruption to this dependency: the complete unchanged test passed. The director-requested provider change is separately owned and must qualify focused compatibility before the next full CI. Inspect no other repository implementation or submodule internals. Stage each safe inventory/removal/replacement slice and commit normally. Route the newly established dependency fact without increasing Knowledge Map limits. The .8.2 evidence handoff may extend the existing isf-lowering-pipeline card with one parser-provider question and a separately dated fact, funded by semantic compaction of agent-runtime-ram-guard and ram-guard-macos-host-metric-over-reports; preserve their exact front matter, original questions, numeric/datetime facts, policy meanings and verification routes, with whole-collection bytes not increased beyond the existing allowance. No removal has been attempted.`
  Verification: `Specific .8.2 FD intake justified reading PPlugin; TableScript/TableSort were search-result matches, not opened implementation reviews. SourceFrontend.pm uses Lispish::multi for .fsm; ISF/Parser.pm and IAL2/PPIF.pm do so for their current inputs; Lispish.pm line13 requests PPlugin->_get_parser(Lispish), with PPlugin AUTOLOAD dispatch. Thus there is a current parser dependency, not evidence all legacy plugins/table tools are useful. No present product use for TableScript/TableSort has been established; complete caller/contract classification is pending. The director defaults obsolete components to removal, with concrete current-purpose evidence for retention. Legacy no-ARRAY callback .11 is subordinate to this retirement decision.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.12.1, PUBLICATION-REGRESSION-REPAIRS.12.2, PUBLICATION-REGRESSION-REPAIRS.12.3`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.12.1`
  Status: `done`
  Goal: `Establish the bounded current parser contract and legacy caller inventory.`
  Acceptance: `Completed bounded public parser/caller contract inventory before provider edits. Preserve actual syntax/AST/diagnostic/CWD/consumption, first outcomes and discovery/root-stability controls. Full original contract/source/receipts remain byte-exact in b097 task and allocation-residual-history-20261101 witness.`
  Verification: `Five declared unchanged7903e296e witnesses retain expected0/93/0/1/71 outcomes and absent owned sessions. Direct canonical LinkedSpec::Get passes six literal AST fixtures with discovery trapped. Root instability at perl/LinkedSpec.pm line722 is owned/fixed under .12.2. contract.json, inputs.json, five packets, capture-console and inventory.json retain separate evidence legs. No original full3 allocation/history cause or complete-suite credit; original detailed source/observations remain in the exact history witness.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.12.1: qualify explicit parser provider contract`

- ID: `PUBLICATION-REGRESSION-REPAIRS.12.2`
  Status: `done`
  Goal: `Implement robust Lispish parser lookup independent of PPlugin.`
  Acceptance: `Completed explicit module-origin specs/Lispish.spec provider, independent of PPlugin/recursive discovery, with factory-local compiled root. Preserve grammar/syntax/AST/diagnostic/file/scalar/CWD contracts and actual FSM/ISF/PPIF/PathSearch controls. Original complete contract/evidence remain byte-exact in b097 task/history. General legacy retirement remains .12.3.`
  Verification: `parser-provider-red-2 actual import refusal turns green with complete AST/wire-kind/API/CWD/resource/syntax/root-stability controls. Original guard-only refusal remains separately retained. Grammar unchanged; LinkedSpec legacy dispatch becomes lazy and PathSearch drops unused Global import. Four adjacent files pass. Changed-source T1437 passes all115 outer cases with fixed guards; parser-provider-capacity-outcome/recovery retain complete recipes, initial dirty-to-exact-source qualification, detached first-gate gap and fresh gate. Source2f62e76db/current-factaf9977aa remain distinct. Book/POD/KMap and normal gates pass. Full CI/hosted/history cause and .12.3 remain separate.`
  Currency: `Saved-intake reverify alone does not qualify changed provider. Existing pipeline-card field adds guarded current T2106 while retaining saved reader/scheduler routes; parser-provider-currency passes exact field/KMap checks. Original full questions/facts/recovery narrative retain in b097 source/history; limits unchanged.`
  Commit: `Source2f62e76db; current-factaf9977aa; capacity outcome: this work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.12.3`
  Status: `pending`
  Goal: `Retire PPlugin and specs/pplugin.spec after migrating genuine remaining callers; remove obsolete table code.`
  Acceptance: `Confirmed director target: retire the PPlugin layer and specs/pplugin.spec entirely after migrating any genuine remaining callers to explicit interfaces. Replace T2106 competing-grammar dependency with a small self-contained test grammar before removing the old grammar, preserving the parser-stability regression. The old grammar is a temporary test witness, never grounds for permanent retention. Classify current callers and remove obsolete TableScript/TableSort in bounded verified slices; name the concrete use of anything temporarily retained and schedule its migration/removal. Update packaging/tests/book and close .11 by verified removal when its obsolete component disappears, or repair any genuinely required interim behavior. Commit focused slices; full CI before publication. Current publication/macOS/worktree order is unchanged.`
  Verification: `No removal attempted. Retained-helper candidates are also owned here after current-caller classification: Lispish::grep scalar branch uses \@$mo while its list result is @mo; a minimal future witness compares both contexts over two matching raw nodes, with possible missing-match impact if retained. Runtime behavior is not yet verified. The file-reader refusal also says does not exit rather than exist. Resolve by verified removal of unused helpers or focused repair of retained behavior/wording; neither is blamed for current provider/resource issues.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.13`
  Status: `active`
  Goal: `Complete qualified local/hosted publication without losing first outcomes.`
  Acceptance: `Preserve original cause gaps; signal only authenticated own jobs. Keep88/4096, unfiltered programme and fresh checkpoints. Complete native Perl/VIAL/book0 precedes authorized normal push and every exact-SHA hosted/Pages success; macOS relevance follows. Current .23 repair, .24 incoming request ownership, .25 response wording, .27 due cleanup precede .26 fresh full11 admission/once-only launch.`
  Verification: `Full1-10 remain retained nonpasses. Full10 clean1b94 reports complete long T1436/T1437/T1438 and repaired T1445, APB1470-1472 and ordinary AHB through1489 ok. First new T1490 supported HBURST SEQ strict/check/semantic/outdir refuses current completed source intent;1491/1492 also fail and1493 is partially observed. No recorded RAM trip. .23 owns causal source repair; no test/profile weakening. No later/full/push credit.`
  Outcome: `Authenticated guard70373 receives TERM; existing cleanup settles managed group70444. Recorder finishes native143; independent old PID/birth and group absence holds. Full native output/current sources/history/progress and incoming request15/risk/cleanup queue retain in full10-intake/owned-settlement and incoming-request15. Commit outcome before source changes.`
  Commit: `Full10 outcome: this work-unit commit; earlier details remain in1b94 source/history.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.14`
  Status: `done`
  Goal: `Repair the stale historical AHB metadata-invariance oracle without weakening behavior checks.`
  Acceptance: `Completed AHB bridge metadata-invariance repair with same-revision annotation/no-annotation source comparison, preserved protocol/report/reset/ownership checks and independent changed-reset control. Full original contract remains in e957 task/full9-intake history.`
  Verification: `T1475 proves actual bridge removal and complete current file-map invariance with source immutability; changed ready-reset alters expected output. Initial adjacent failure exposes T1551 and is retained; exact later reverify Files3 Tests17 passes. ahb1475-repair-proof retains full diagnosis, source/recipes and missing full/adjacent scope. Production/grammar unchanged. Book/card/index and normal gates passed after preserving the first index-row-cap refusal. Full detailed source/evidence remains in e957/full9-intake history.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.15`
  Status: `done`
  Goal: `Diagnose and repair the adjacent bridge determinism/behavior historical byte expectations.`
  Acceptance: `Completed causal T1551 old byte-oracle repair while preserving deterministic/immutable/behavior checks and positive/adverse controls. Full original contract and first failures remain in e957 task/full9-intake history.`
  Verification: `Exact own-Git public witnesses reproduce July SV95db and actual Augusta6c VHDLab668; same input stays identical. Current SV differs only by decision0111/69ae assertion removals, VHDL only965b typed size_q inequality. Initial wrong a82 baseline/refusals retain. T1551 now compares current annotation/no-annotation maps and before/after-bridge HDLs, source immutability and changed-reset literals. T1551/T1475/T1211 Files3 Tests12 pass; canonical reverify exposes T1602, owned .16. bridge-byte-stability diagnosis retains complete historical/current products, recipes and separate evidence legs. Production/grammar/seed unchanged; book/card/POD/index/normal gates passed. Exact full detail remains in e957/full9-intake.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.16`
  Status: `done`
  Goal: `Diagnose and repair the architecture-scale frozen AHB report identity check.`
  Acceptance: `Completed T1602 report-identity causal repair with complete typed source/report/provenance comparison and preserved axes/profile/limits/forgery/bypass checks. Full original contract and first failure remain in e957/full9-intake history.`
  Verification: `Public evaluation/captured original Builder calls reproduce current240db972 and historical97dda a4565d40. Exactly four generated-source provenance fields differ through intended +interface; independent Python/Perl canonical bytes agree, remaining contract64946a80 exact. T1602 independently assembles public AHB route, validates raw provenance, freezes all other fields and rejects changed protocol role. Focused T1602/T1551 Files2 Tests12 and exact full canonical reverify pass; default large opt-in stays uncredited. bridge-reference-identity diagnosis retains complete sources/recipes/reports/diffs/three evidence legs. Production/grammar/seed unchanged; book/card/POD/index/normal gates passed. Exact full detail remains in e957/full9-intake.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17`
  Status: `done`
  Goal: `Classify and repair remaining uses of the proven stale AHB byte/report identities before full6.`
  Acceptance: `P1 after .16 clean commit. A targeted exact-literal scan finds remaining uses in VIAL planning/execution/checking tests, so do not spend a fresh full run on known unresolved candidates. Preserve complete command/membership. Classify actual current assertions versus intentional historical/negative data; reproduce each affected public gate under its documented default/explicit flags without native opt-in or guard weakening. Split into bounded children before source changes. Reuse the established exact interface-only source and four-provenance-field report diagnosis where the same public identity is proved; do not blindly replace literals or weaken anchor/profile/limits/forgery/behavior checks. Prefer one explicit test-only current AHB reference authority that preserves the frozen contract and raw provenance, rather than repeating whole historical byte locks; choose only after caller/test contracts are understood. Commit each safe repair/check slice with live docs/book, then return .13 for clean exclusive full6/checkpoint, authorized push and every expected exact-SHA hosted result.`
  Verification: `The original four-literal/23-file scan is preserved in its manifests. Planning .1 and classified downstream .2 repairs now have focused qualification with exact source/contract provenance, historical/adverse controls and complete native receipts. Final .2.4.5 candidate closure leaves only two intentional historical anchors and no unowned original file; explicit large branches remain unqualified. No blanket refresh or complete stale-oracle/full-suite claim. .13 owns new clean exclusive full6/checkpoint and subsequent authorized publication.`
  Commit: `Child work-unit commits .1/.2.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.17.1, PUBLICATION-REGRESSION-REPAIRS.17.2`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.1`
  Status: `done`
  Goal: `Repair the public planning review-artifact historical byte oracle.`
  Acceptance: `First bounded slice: reproduce T1556 default public planning path, compare returned generated review artifacts against an independent current public PPIF generation, preserve exact artifact graph/manifest/determinism/immutability/path/cleanup assertions and meaningful adverse controls. The old 3d8 generated-FSM hash has an established exact interface-only cause, but require this actual public result before repair. Sync public planning book/current fact when applicable, focused checks and ordinary commit before moving to downstream scale identities.`
  Verification: `vial1556-planning-red returns expected1/Files1 Tests6 at line82: actual generated review SHA6f58 differs from historical3d8, the established intended interface-only source change. Only that source-byte oracle changes: compare the exact planner artifact against a fresh public PPIF generation from the same source. The literal IAL1 hash, complete graph, raw digest/byte inventory, three review routes, defensive mutations, repeated determinism, malformed requests and filesystem publication/cleanup checks remain. Syntax and T1556/T1555 return0 with All tests successful Files2 Tests11. All five native book/POD/current-source/index/KMap commands return0. Production modules/grammar/fixtures are unchanged; current public planning book explains raw review bytes/metadata. Exact initial scan, original RED/current GREEN recipes/logs and separate evidence legs are retained. No downstream scale/full CI or hosted qualification is credited.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2`
  Status: `done`
  Goal: `Classify and repair downstream scale content-identity expectations in safe causal slices.`
  Acceptance: `After .17.1 commits, classify all other exact scan matches and reproduce representative default execution/checking/backend-foundation gates before selecting bounded repair children. Existing source also freezes dependent semantic/plan/execution/evaluation/rerun identities, so changing only bridge constants is insufficient without field-level causal diagnosis. Preserve meaningful exact identities and quantitative/resource/profile/negative checks; no wholesale refresh or unsafe large/native flag. Use complete public stage recipes and current/historical comparisons to distinguish legitimate provenance propagation from real producer defects, then own each repair and qualify scope before .13 full6.`
  Verification: `The representative default intake, closed current AHB authority, independently reconstructed checking/backend foundations and19 remaining execution defaults are completed in separate verified commits. Actual producer scalar-guard selection is separately repaired in .3.1; historical DUT/input witnesses and adverse controls distinguish current behavior from old byte oracles. .4.5 proves every original candidate is owned and joins focused successful receipts, preserving the two historical anchors and unrun large branches. Fresh complete local/hosted qualification remains active under .13/SEM .69.3.`
  Commit: `Child work-unit commits.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.17.2.5, PUBLICATION-REGRESSION-REPAIRS.17.2.1, PUBLICATION-REGRESSION-REPAIRS.17.2.2, PUBLICATION-REGRESSION-REPAIRS.17.2.3, PUBLICATION-REGRESSION-REPAIRS.17.2.4`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.5`
  Status: `done`
  Goal: `Preserve the actual representative default failure census and own bounded successors.`
  Acceptance: `Retain exact source/command/status/complete output for default T1604/T1629/T1645 without large/native flags. Separate known stale raw-bridge provenance from unclassified derived checking/backend differences. Name missing causal legs and scheduled owners, update book/Memory and commit before repair code.`
  Verification: `All three commands return1; complete:true is collection only. Topology fails only old bridge SHA in three axes; checking also fails its evaluation/rerun IDs; backend also fails its stage dictionary/evaluation/rerun IDs. No unrelated producer fault, semantic change, resource/native issue or full-suite success is inferred. .17.2.1-.4 own next repairs/remaining19 defaults; no blind update is selected. Intake proof/source seal and full logs survive under push-readiness-20261025. Current canonical bridge/core .16 checks remain green in their own scope. First staged gate rejects the zero-numbered draft intake node as malformed; rename it to positive .17.2.5 under the existing task grammar and retain the refusal before unique staged-2. No product/checker policy is changed.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.1`
  Status: `done`
  Goal: `Provide the checked current AHB reference and preserve topology oracles.`
  Acceptance: `Completed public PPIF/ISF/Builder reference; exact provenance/kind/frozen contract and altered-role controls. Preserve source/caller behavior. Full original contract remains in1b94/full10-intake.`
  Verification: `T1602/T1604/reference focused Files4 Tests18 and book/source/normal gates passed. Immutable fresh reference rejects wrong source/digest and altered kinds; source epoch and initial extraction/gate refusals retain. No complete native/full credit.`
  Commit: `This work-unit commit.`


- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.2`
  Status: `done`
  Goal: `Repair checking-foundation derived provenance identities.`
  Acceptance: `Reconstruct old identities by independently proved bridge provenance only; preserve every other field/kind/metric and adverse control. Exact original remains in1b94/full10-intake.`
  Verification: `Actual RED then tuple/report hash reconstruction and altered-metric control qualify T1629/T1602 Files2 Tests12. Full reports/source/historical oracle and first guessed-path refusal retain in checking-foundation evidence. No producer/semantic/full change.`
  Commit: `This work-unit commit.`


- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.3`
  Status: `done`
  Goal: `Diagnose and repair backend-foundation input and derived identities.`
  Acceptance: `P1 after .2. Capture exact backend inputs/stage tuples/evaluation/rerun and compare current/historical fixture data as needed. Explain every changed field using current contracts; do not infer backend-input drift from the bridge alone. Preserve exact provider/profile/ownership/metrics/refusal/oracle checks, no native opt-in or pin/submodule changes. Small causal repair(s), public book/docs and normal focused commit.`
  Verification: `Current supported AHB generation is restored by .1's precise scalar-family selector. .2 independently reproduces the historical public backend foundation and attributes every actual input artifact delta, then retains current direct generation and the complete frozen historical evaluation/rerun oracles. Both children commit verified. Remaining execution/profile candidates and full CI/hosted publication stay open under .4/.13/.69.3.`
  Commit: `Child .1:55c92474b; child .2:821671418.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.17.2.3.1, PUBLICATION-REGRESSION-REPAIRS.17.2.3.2`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.3.1`
  Status: `done`
  Goal: `Restore supported AHB generation by selecting the actual literal-width family precisely.`
  Acceptance: `Native public PPIF/lowered-IAL0 observations show fixed AHB guards such as (& HREADYOUT (== HRESP 1b1)) and (| (== HTRANS 2b10) (== HTRANS 2b11)), plus logical negation/generated child refs. Comparison and logical-not result widths are scalar and independent of operand/literal widths; those subtrees are outside the literal operand-maximum family. Correct the typed literal requirement selector to stop at those exact scalar operators. Retain holder-presence priority, exhaustive physical helper inventory, bounded cycles/occurrences, recursion through other typed nodes/generated refs, true data-literal missing-policy refusal and every source/target/emission guard. No numeric/equal-width shortcut or new source admission. Prove actual public AHB generation, scalar-versus-operand declaration widths, nested/repeated guards, existing mutable scalar behavior and still-required data-literal policy. Retain I2C/source-literal controls, synchronize API/POD/book/downstream/KMap and commit before backend identity diagnosis.`
  Verification: `The current T1645/public AHB failure is a selector false positive: actual literals lie under typed comparison/logical-not scalar results and cannot set a bitwise data maximum. The final production change stops requirement search at exactly those operators; installed-holder priority, physical child inventory, original source/target preparation and true data-literal guards remain unchanged. Earlier scalar-holder expansion is preserved as superseded experimental source/results without final credit. Native T2297 checks actual scalar/wide-operand declarations, nested/repeated guards, mutable scalar behavior and missing/changed real data-literal intent, including a physical child under negation. The final focused T2297/T2296/T1309/T2268 gate passes0/Files4 Tests16. Exact old-selector control returns4 and reproduces all false-positive groups while existing guards remain live. Public strict AHB check returns0/success:true and no diagnostics. T1645 now reaches only its three historical identity assertions, with complete current graph/evaluation; its remaining RED1 belongs to .2 and is not called green. Complete original/probe/experiment/final streams and tested/final producer identities retain in ahb-selector-proof-20261031.json.gz and the guarded qualification receipt. The sole post-test module delta is POD prose; the executable prefix is byte-identical. Public sync is restoration of supported AHB scalar guards with API/POD/book/downstream conformance; no syntax, source capture, literal profile, manifest/MCP or generic data-width admission changes. KMap preserves every question and exact former source/hash, routing duplicated earlier shape diagnosis to canonical API/task at nonpositive byte growth. Full CI/hosted and backend identity/candidate repairs remain open.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.3.2`
  Status: `done`
  Goal: `Reconcile backend-foundation provenance without changing semantics.`
  Acceptance: `Preserve original complete report/metrics/profile/refusals and derive all changed input/dependent identity fields through actual public source. Exact original remains in1b94/full10-intake.`
  Verification: `821671418 closes the independently reconstructed historical public backend foundation and current direct witness. Full original source/products/first failures/adverse controls retain. External/native and full qualification remain separate.`
  Commit: `This work-unit commit.`


- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.4`
  Status: `done`
  Goal: `Classify and migrate the remaining execution reference checks in small verified groups.`
  Acceptance: `After the common reference and derived-foundation repairs, inventory the19 remaining exact-match execution files, group safe slices before edits and verify each actual default outcome. Adopt current reference only where the same core source/contract is proved; retain all existing semantic/plan identities, counts, limits, source maps, forgery/caller/rerun checks. Document any unrun explicit-large branch rather than enabling unsafe work or claiming coverage. Own any new defect, commit each group, then .13 exclusive full6/current capacity/checkpoint before push.`
  Verification: `All19 original execution candidates are classified and repaired in four committed bounded groups. Each actual default RED is bridge-only; independent checked current reference imports/literals leave every other assertion byte exact. Focused native defaults pass, with original/source/current streams retained. The separate .5 joins the exact original membership, retains unqualified explicit-large scope and declares clean exclusive full6/checkpoint before .13 complete local qualification. No global stale-oracle census, large opt-in or full/hosted success is inferred.`
  Commit: `Child work-unit commits .1/.2.1/.2.2/.3/.4/.5.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.1, PUBLICATION-REGRESSION-REPAIRS.17.2.4.2, PUBLICATION-REGRESSION-REPAIRS.17.2.4.3, PUBLICATION-REGRESSION-REPAIRS.17.2.4.4, PUBLICATION-REGRESSION-REPAIRS.17.2.4.5`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.1`
  Status: `done`
  Goal: `Qualify and repair the four small execution gate bridge-reference oracles.`
  Acceptance: `Census exact prior/current candidates first; select T1605 fibers, T1607 source maps, T1608 random/replay and T1609 plan bytes. Read each complete default/opt-in path and reproduce native defaults under unchanged guards. Change only a reproduced stale checked-AHB bridge expectation to the independent current public reference, with exact same frozen HIAL/source contract proved. Preserve every semantic/plan hash, count, byte, limit, map, rerun, caller/source/adverse assertion and disabled large branch. Complete focused original/current results, source identity and existing reference adverse control; book/KMap/Memory/task/normal commit before next group.`
  Verification: `Exact current/prior census confirms19 pending candidate files plus two intentional historical anchors; membership is not a complete stale-oracle or runtime census. Complete T1605/T1607/T1608/T1609 source/default/opt-in review precedes repair. Native RED1 has exactly five obsolete bridge assertions across four files; semantic/plan/source/count/map/byte/replay/adverse checks pass. Replace only each old bridge literal and add the closed independent current-reference import/local library path. Exact original/current source conservation proves every other byte unchanged. The final four defaults plus T1602 current-reference/changed-role controls pass0/Files5 Tests31. T1607's explicit exact source-map route remains skipped and unclaimed; its default unconstructible higher-level records still run. Source/complete native before-after receipts and prior card/hash retain under execution-small-*-20261031. Re-derivation is actual current public bridge raw-byte provenance plus frozen contract; falsification is the original RED and unchanged changed-role/reference/negative controls; durability is tracked tests, exact code-conservation source and dated receipts. The book describes scoped gate qualification with no new capacity/semantic/production claim; existing canonical KMap/current-reference facts apply unchanged. First hook rejects editing an authenticated stable-partition card; preserve complete log/source, restore its exact original and keep client migration status in task/book. No partition/guard/ceiling or budget changes. Native book/copied-source/claim/staged hook gates precede commit, then .2 continues remaining qualifiers. Full CI/hosted stay open.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.2`
  Status: `done`
  Goal: `Qualify and repair default plan/random qualification and boundary bridge oracles.`
  Acceptance: `After .1 commits clean, read/reproduce exact defaults T1610/T1611/T1613/T1614/T1615. Apply the common current reference only for independently proved bridge-only stale assertions. Preserve source/semantic/plan/byte/count/earliest-cap/replay/negative checks and all original opt-in controls; do not enable unsafe large paths. Retain complete results/identity, explicit unrun scope, synced book/live docs and normal commit.`
  Verification: `Diagnostic .1 preserves complete RED/partial host-cutoff GREEN and restores originals. Director explicitly requests retry; .2 authenticates the exact saved proposal and records current lower occupied capacity with normal pressure. The separate native retry completes0/Files6 Tests28 under unchanged88/4096, including all five defaults and the independent current-reference adverse control. Only imports/local library path and one bridge literal per file differ; every other assertion byte is conserved. No explicit-large/full/hosted result is inferred. .2 commits the focused repair before remaining .3/.4 groups and .5 full6 preflight.`
  Commit: `Diagnostic .1 and qualified repair .2 work-unit commits.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.2.1, PUBLICATION-REGRESSION-REPAIRS.17.2.4.2.2`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.2.1`
  Status: `done`
  Goal: `Retain the complete plan/random RED and interrupted native repair qualification, then hand off clean.`
  Acceptance: `Retain exact original/proposed source bytes, complete RED and partial GREEN streams/statuses, actual guard trigger and explicit missing outcomes. Restore all five active test files, take only bounded current post-stop OS/owned-PID observations without treating them as at-cutoff cause, and commit this diagnosis/book/pointer through normal gates. The existing .13 rule requires specific capacity coordination before expensive replay; neither raise88/4096 nor manipulate unrelated jobs.`
  Verification: `Native RED1 completes all five defaults with only old bridge assertions. The exact proposed import/literal substitution preserves every other byte; partial GREEN passes T1610 and stops137 at host88.3/88 before remaining outcomes. All five active tests are restored byte-for-byte to d25c8a23e; complete original/proposed sources, both native streams/statuses and source identities retain in execution-plan-random-*-20261031. A bounded post-stop VM/physical/pressure/exact guard-PID packet independently reparses the same saved counters with AWK: occupied capacity82.18402862548828, kernel pressure2, known stopped PID absent. This is current intake only, not at-cutoff pressure, a global process census, culprit or future safe-window guarantee. No guard change, unrelated process action, production/test repair or expensive replay follows. Re-derive source identities/native statuses/raw counters; falsify provenance-only diagnosis with complete RED/assertion domain and inverse proposed-source conservation, and distinguish pressure/capacity with the independent saved-counter parser; durability tracked complete packets/task/book/Git. Memory/index select pending .2 after specific capacity coordination under .13. Native mdBook test/build/POD/copied-source checks pass in execution-plan-random-interruption-docs-20261031; its next generator --check invocation is an unsupported-flag2, fully retained. Corrected check_knowledge_map.sh and focused-index checks both pass in execution-plan-random-interruption-indexes-20261031; no native book replay is needed. Claim/staged normal doctrines gate this diagnostic commitment; full6/push/hosted remain open.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.2.2`
  Status: `done`
  Goal: `Apply and qualify the retained plan/random bridge-reference repair after capacity coordination.`
  Acceptance: `After .1 commits clean and the director coordinates shared capacity, inspect existing finished journals before choosing a unique GREEN slot. Reapply only the authenticated proposed test bytes from execution-plan-random-source-20261031.json.gz, recheck baseline/source identities, and qualify the exact five defaults plus current-reference adverse control under unchanged88/4096. Preserve all other assertions and any first outcome. Commit focused success before .3; do not infer full CI, exact large opt-ins or hosted success.`
  Verification: `Director2026-10-31 explicitly instructs try again. Finished original RED/partial GREEN are inspected without replay. Fresh raw OS intake independently reparses occupied capacity50.95971425374349 with normal pressure1; this is admission, not a future guarantee or original cutoff cause. Reapply exactly the authenticated saved proposal: only independent current-reference import/local library path plus one old bridge literal per file change. Every other source/assertion byte remains exact. Native execution-plan-random-retry-20261031 completes0/Files6 Tests28, covering all five defaults plus T1602 current-reference changed-role/argument/type/mutable-state controls. The original RED1 and host137 retain unchanged; T1602 explicit large route remains skipped and unclaimed. Exact tested source/helper identities, admission, whole native streams/statuses, distinct re-derivation/falsification/durability legs retain in the dated packets. No product module, input source, syntax, capability, API/POD contract, guard or resource limit changes. Book extends the same checked-reference explanation to these qualifiers; native book test passes. Final build/copied-source/index/claim and normal staged doctrines gate commitment before .3. Full6/push/hosted remain open.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.3`
  Status: `done`
  Goal: `Qualify and repair default scenario/operation qualification and boundary bridge oracles.`
  Acceptance: `After .2 commits clean, read/reproduce T1616/T1617/T1618/T1619/T1620/T1622 defaults. Require exact bridge-only causality before common-reference use. Preserve topology, source identities, semantic/plan hashes, counts/maps/bytes, earliest authority, negative and opt-in controls. Split any nontrivial actual defect into a new owned safe child; focused results/docs and normal commit before .4.`
  Verification: `Complete exact six-file RED from8a8887776 returns1/Files6 Tests27 with exactly six old bridge assertions; every other original assertion passes. All actual hashes equal the independently checked current240db versus olda456. Change only one bridge literal per file and the existing independent-reference import/local library path; inverse transformation conserves every other byte. Exact six-default GREEN returns0/Files6 Tests27 under unchanged88/4096. Frozen topology/source/semantic/plan identities, byte/count/map/earliest-cap/rejection/mutation/staging checks all remain. No opt-in flags exist in this group, no product module changes, and no full/hosted outcome is inferred. Original/current source seals, complete dated native streams/statuses, independent unchanged helper control qualification and distinct re-derivation/falsification/durability legs retain in execution-scenario-operation-*-20261031. The book names exact qualified scenario/per-scenario/aggregate scope; native book test passes, with final build/copied-source/index/claim and normal staged doctrines before commitment. Then .4 owns the remaining four default fiber/aggregate-operation files before .5 full6 preflight.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.4`
  Status: `done`
  Goal: `Qualify and repair default fiber/total-operation boundary bridge oracles.`
  Acceptance: `After .3 commits clean, read/reproduce T1623/T1624/T1625/T1626 defaults. Keep every compact-source/limit/plan/independence/current-safety/negative contract and explicit-large guard. Only reproduced bridge provenance drift may use the independently checked current reference; own any other cause separately. Retain source/complete results and docs, then normal commit. If its mandatory gate reaches aggregate task-evidence rollover pressure, own a lossless historical-suffix rollover within this same tree before commitment; preserve every live node/current acceptance and authenticate exact predecessor/history through the existing manifest protocol without raising limits.`
  Verification: `Complete four-file RED from0b09ea98a returns1/Files4 Tests26 with exactly eight stale bridge assertions, two per file; every other default assertion passes. All actual hashes match independently checked current240db versus olda456. Replace only each one bridge constant and add the existing checked-reference import/local library path; inverse transformation conserves every remaining byte, including the T1626 explicit-large guard. Exact four-default GREEN returns0/Files4 Tests26 under unchanged88/4096. Source/semantic/plan identities, compact recipes, byte/count/map/orthogonality/earliest-cap/preflight/rejection/mutation checks remain. T1626 exact total-operation excess stays skipped and unclaimed. Complete original/current source seals and native streams/statuses plus distinct re-derivation/falsification/durability legs retain under execution-fiber-total-*-20261031. No production module/source/capability/API/POD or resource-policy change. The book completes the common reference scope and explicitly retains all unrun opt-in qualifications. Native book test passes; final build/copied-source/index/claim and normal staged doctrines precede commitment, then .5 reconciles exact candidates and prepares clean full6 before push. First normal hook refuses task_evidence90.0-percent pressure, with complete staged bytes/log preserved in execution-fiber-total-first-commit-refusal-20261031.json.gz. The same-tree recovery uses the existing authenticated acceptance-history manifest to retain the exact0b09ea98a predecessor and its historical Blockers/acceptance suffix. Current blockers are projected from the retained live node fields; every live node and fresh acceptance remains. The existing .32 owns later collection-level rollover. No ceiling, baseline, allowance, pressure milestone or enforcement state is raised or relaxed; current-tree history rollover returns the collection below the rollover milestone. Complete source, semantic closure, live dimensions and zero-loss residue are independently recorded and verified in execution-fiber-total-history-rollover-20261031.json.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.17.2.4.5`
  Status: `done`
  Goal: `Close the complete owned execution-default repair set.`
  Acceptance: `Conserve every original candidate through actual final-path receipts/current sources; retain historical anchors and unrun large branches. Exact original remains in1b94/full10-intake.`
  Verification: `All remaining default candidates join actual passing focused receipts; no control-path or large/native credit. Source/receipt/identity conservation and historical semantic oracles retain. Fresh full native/hosted qualification remains .13.`
  Commit: `This work-unit commit.`


- ID: `PUBLICATION-REGRESSION-REPAIRS.18`
  Status: `done`
  Goal: `Resolve the generated APB requester VHDL namespace rejection exposed by full6.`
  Acceptance: `P1 before another full qualification/push. Full6 from1ec88efcb reaches T114 and its generated-child C4 scalar generic-map case aborts255 after95 passing assertions: VHDL generic namespace identifier ACCESS is reserved. Record the actual supported-source/target contract before deciding fixture versus producer repair. Preserve the old full/native output and all reserved-word/collision checks. No blind source rename or namespace-guard weakening. Own each intake/repair slice, focused meaningful controls and book/docs, then fresh clean full7/checkpoint under .13 before publication.`
  Verification: `Full6 failure and authenticated settlement retain under .18.1. Canonical .22.2 declared-name, .27 implicit-state-hold and .22.2.2 complete scaffold repairs now commit with focused/native analysis evidence. .18.2 closes required integration and fresh full7 preflight. Complete local qualification stays active under .13, followed by the authorized normal push and exact-SHA hosted/Pages qualification; no full-suite outcome is inferred.`
  Commit: `Completed through child work-unit commits.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.18.1, PUBLICATION-REGRESSION-REPAIRS.18.2`

- ID: `PUBLICATION-REGRESSION-REPAIRS.18.1`
  Status: `done`
  Goal: `Retain settled full6 and reproduce/classify the T114 public generated-child refusal.`
  Acceptance: `Consume final full6 state/status/whole output, authenticate settlement and missing stages, keep exact input/code identities. Reproduce only unchanged T114 under unchanged guards; query/read canonical VHDL parameter/namespace and generated-child contracts and relevant book sections before cause classification. Distinguish current generated identifier handling from historically invalid source; use exact history/public output rather than assuming. Permit exact authenticated GHDL6.0.0 analysis of the newly emitted plain APB artifact and a declaration/reference-only ACCESS replacement control in distinct repo-local workdirs; analysis only, fixed guard, bounded timeout, no old diagnostic main or implementation-source replay. No fixture/production change. Commit complete intake with precise .2 repair frontier before implementing it.`
  Verification: `Full6 from1ec88efcb is deliberately settled143 after T114 actual file255/no-plan following95 passing assertions. Exactly259 reported passing-file rows are retained and independently re-parsed; the complete suite, VIAL, book and T296 checkpoint have no outcome/credit. Guard50530 birth and full command match before SIGTERM; known guard/session/recorder PIDs are absent after cleanup, with no unrelated process changed. The exact unchanged T114 focused run reproduces1 with the same namespace exception. Native plain APB requester generation returns0 but emits constant ACCESS and its references. Authenticated GHDL6.0.0 LLVM-JIT rejects it; a full artifact control replacing only the declaration and two references passes analysis. No elaboration/runtime/full-profile claim. Exact input/code/compiler/producer identities, full original/focused streams, source/old-card witness and distinct re-derivation/falsification/durability legs retain in full6-t114-intake-20261101.json.gz and scoped receipts. Canonical prior .22.1 and current source prove the same normalizer defect: basic-shaped reserved names skip keyword planning. New source-aware generic namespace admission correctly refuses the invalid target; renaming the source fixture or weakening that check would conceal it. Required integration satisfies the existing earlier-activation condition for ISF-REDUCTION-DELIVERY.22.2. Commit this intake clean, then activate that canonical repair; .18.2 coordinates integration before fresh full7. The current card preserves original questions/reverify and all dated OUT/control/scope/grammar facts with nonpositive bytes; the book names the current APB blocker. Source/test/production bytes stay unchanged; native book/source/KMap/claim and normal staged doctrines qualify the intake, not the unresolved generator or publication.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.18.2`
  Status: `done`
  Goal: `Integrate the canonical reserved-identifier repair and restore the APB requester/generic-map qualification.`
  Acceptance: `After .1 commits clean, activate canonical ISF-REDUCTION-DELIVERY.22.2 because required integration now demonstrates its blocker. That existing leaf owns the smallest declaration-aware target naming repair; this leaf owns publication integration rather than duplicating production ownership. Preserve language-neutral source meaning, legal emitted identifiers, complete target-namespace closure, reserved-word/case-collision and generic-map refusals. Qualify original positive case and distinguishing adverse controls through actual public generation plus available HDL validation when relevant. Sync book/live/POD/API contracts as affected, commit normally, then .13 fresh full7/checkpoint; no full/hosted success inferred from focused checks.`
  Verification: `Canonical naming72d343b, state-hold230b685 and complete scaffold6c69fc2 are clean committed repairs. Complete T114/generic/declaration and source/hold adverse controls retain their exact successful receipts; full T1420 passes64 outer subtests with all original fixtures preserved. Current T2154 independently passes after the state-hold repair in full7-dry-run receipt; full dry-run prints every required local stage and exits0. Fresh full7-admission raw counters yield63.92955780029297 percent, kernel pressure1; separate saved-counter awk parsing agrees under unchanged88/4096 guards. This is current admission, not future headroom or original-cutoff attribution. All new full7 journal/log/checkpoint/result slots are absent. full7-launch-plan retains exact current recorder/CI/guard and workflow hashes plus all source-derived required hosted jobs; previous full6 record is not a pass. Commit this immutable preflight before clean full7 under .13, with no tracked/untracked edits during the command because T296 rechecks cleanliness each batch. Native book/source and normal integrity gates qualify preflight only; complete local full, push, hosted/Pages remain pending. No filter, opt-in, guard or workflow change.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.18.2: integrate VHDL repairs for fresh full7`

- ID: `PUBLICATION-REGRESSION-REPAIRS.19`
  Status: `done`
  Goal: `Resolve the dynamic wait/shift literal selected-target refusal exposed by full7.`
  Acceptance: `Completed full7/T1244 source/outcome intake before causal repair. Preserve wait/zero-count/sample/shift and literal source/event/target contracts. Only independently proved invalid target-keyword fixtures may migrate under exact source/lowering/adverse compiler controls. No producer guard bypass. Exact original contract remains in c8 task/history.`
  Verification: `Valid namespace guard rejects source bit. .1 retains exact literal/namespace/compiler diagnosis and settled143 full7 with316 partial file passes, no full credit. .2 changes only four fixture/reference tokens, preserves all other bytes and passes complete T1244 Files1 Tests39. Production/guards unchanged; full8 handoff is declared before clean launch. Complete local/push/exact-SHA hosted qualification stays .13; all detailed old evidence retains in c8 task/history.`
  Commit: `Completed through child work-unit commits.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.19.1, PUBLICATION-REGRESSION-REPAIRS.19.2`

- ID: `PUBLICATION-REGRESSION-REPAIRS.19.1`
  Status: `done`
  Goal: `Preserve full7 and reproduce the actual dynamic wait/shift selected-target refusal.`
  Acceptance: `Before implementation, retain full7 original/native failure, unchanged source/producer identities and authenticated guard settlement. Reproduce T1244 alone under unchanged88/4096; inspect canonical knowledge/actual source, interfaces and relevant book. Use bounded same-volume diagnostics to identify the failing selected intermediate and exact mismatch without relaunching a full suite or altering production guards. Preserve first diagnostic failures, cause and missing proof, schedule .2 precisely, update live/book boundaries and commit the intake clean before repair.`
  Verification: `Isolated original T1244 reproduces final selection refusal. Actual installed holder and prepare_selection succeed for intermediate_or_bit_4 (reg_out << 1 | bit); prepare_target_namespace specifically rejects bit as a SystemVerilog keyword at DirectDeclaredWidthSupport.pm line547. Two-token serial_bit source control generates; its complete lowered FSM inverts byte-exact, preserving state/sample/shift/zero-bypass behavior. Installed Verilator5.050 lint accepts the actual control artifact; inverse keyword-name artifact fails. No compiler runtime/full toolchain-closure claim. The first observer incorrectly expects both names to fail and exits25; preserve it uncredited, then qualified observer succeeds. Git pickaxe identifies source fixture0bc6ad7a, target keyword guardd4544d15 and final ledgerce02b1cb. No production/test change. Authenticated full7 guard-only settlement143 and exact known-process absence retain; independent parsers agree on316 reported passing files with no whole-suite/VIAL/book/checkpoint credit. full7-t1244-intake-20261101.json.gz retains complete original test/producers, public source/report/lowered/typed AST/error products, scripts, tool/version/lint and native receipts. Re-derive: actual target namespace and source/native/lint. Falsify: legal-name source and inverse-FSM/keyword-lint controls. Durability: receipt/card/book/task/Git. Compact current card preserves all questions and canonical routes with nonpositive growth. Adjacent book wording incorrectly still withheld now-supported symbolic VHDL ports and described the repaired reserved-name defect; route it to the bounded current profile and exact qualification instead. Native book/source/discovery and mandatory normal hook gate intake; .2 migrates only the positive fixture and matching assertions before fresh full8.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.19.1: isolate wait fixture reserved keyword refusal`

- ID: `PUBLICATION-REGRESSION-REPAIRS.19.2`
  Status: `done`
  Goal: `Repair the diagnosed dynamic wait/shift literal selection and qualify its actual contracts.`
  Acceptance: `After .1 commits clean, replace only positive wait_dynamic_sample_shift input bit and its DSL/assertion references with serial_bit. Retain original invalid-keyword native/compiler controls and all wait/report/sample/shift/zero-count semantics; prove exact inverse fixture/test conservation and complete T1244 success. Do not change producers, namespace/literal guards or unrelated negative fixtures. Clarify operand metavariables versus actual HDL-compatible names in the related book example. This repaired handoff also owns fresh current admission, exclusive full8 launch plan and conditional Memory before the normal commit; actual full8 begins only from that clean committed state. Complete native book/source and mandatory normal commit before .13 unique full8/push; no full/hosted success from focused checks.`
  Verification: `Only four tokens change in the positive independent-shift subtest: authored input/operand bit become serial_bit, with the two corresponding lowered-source assertions. Complete inverse and outside-subtest byte equality preserve every other fixture/assertion, including negative cases and transaction_waits metadata. The exact repaired ISF source equals the native/linted legal-name control from .1. No producer, selector, target guard, width, wait/sample/shift/zero-count semantics or compiler flags change. Complete guarded T1244 passes All tests successful, Files=1 Tests=39, reaching all previously unexecuted cases. t1244-keyword-repair-evidence retains full original/current source, four-token proof and unchanged producer identities; original native/namespace and inverse keyword/compiler controls remain in .1. Book clarifies that reg/bit are operand metavariables rather than portable declared names. Fresh full8-admission captures61.64404551188151 percent, pressure1 and independently parsed counters under unchanged88/4096; all five unused journal/log/checkpoint/result slots are absent. The first cloned helper retains mixed old slot names and correctly refuses before admission/launch; its source/status retain, followed by corrected fresh collection. full8-launch-plan preserves exact guard/CI/recorder/workflow hashes and all required jobs; it binds the qualified test SHA and requires this committed clean HEAD before one launch. Native book/source/index and mandatory normal hook gate the repaired handoff. Complete full8, normal push and exact-SHA hosted/Pages remain pending under .13/.69.3; no dynamic runtime claim.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.19.2: use a portable wait-shift input name`


- ID: `PUBLICATION-REGRESSION-REPAIRS.20`
  Status: `active`
  Goal: `Resolve full8 source-contract failures and the proved same-input generation cost.`
  Acceptance: `Own every observed full8 failure and the bounded cost diagnosis; causal repair first, then focused contract slices with one normal commit each. Full8 remains partial/non-pass; .13 owns the next complete qualification and publication.`
  Verification: `Full8 has settled143; no owned job remains. Detailed retained intake is .1; no implementation repair is claimed yet.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.20.1, PUBLICATION-REGRESSION-REPAIRS.20.2, PUBLICATION-REGRESSION-REPAIRS.20.3, PUBLICATION-REGRESSION-REPAIRS.20.4, PUBLICATION-REGRESSION-REPAIRS.20.5, PUBLICATION-REGRESSION-REPAIRS.20.6, PUBLICATION-REGRESSION-REPAIRS.20.7, PUBLICATION-REGRESSION-REPAIRS.20.8, PUBLICATION-REGRESSION-REPAIRS.20.9, PUBLICATION-REGRESSION-REPAIRS.20.10, PUBLICATION-REGRESSION-REPAIRS.20.11`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.1`
  Status: `done`
  Goal: `Retain full8 outcome, causal intake and precise repair ownership.`
  Acceptance: `Completed exact full8/source/control/first-refusal intake, parsed ownership/frontier repair and historical retention before causal changes. Complete original contract remains in e86/c8 task and rollover witnesses; no full-suite credit.`
  Verification: `Full8 settles143 with471 reported file passes,23 failures and93 assertion markers; every failure has a .20 owner. full8-intake-20261101 retains complete available streams/sources/first controls, matched carriers/reports and authenticated job absence. Saved reader/corruptions, book/KMap and normal doctrines pass at e86d3ff07. Misplaced .19/.20 nodes are corrected; .20.11 owns the later guard. Exact detailed evidence/recovery wording remains in archived source; no full/runtime/hosted credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.1: retain full8 failures and allocation-cost intake`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.2`
  Status: `done`
  Goal: `Repair unrelated-allocation validation cost without weakening currentness.`
  Acceptance: `P1 first causal repair. In actual parser transition paths, select potentially affected events before expensive full validation. Any cache may accelerate negative membership selection only; retain complete live validation for every candidate, source/holder/registry replacement, object lifetime, matching-write revocation, literal child provenance and role/metadata/width/AST controls. Require a genuine before/current resource-cost counterexample, semantic conservation and focused canonical allocation tests. Qualify the exact original public fixture with native HDL verification; update book/POD/facts and commit. No guard bypass, larger limits, reduced cases or generic-profile expansion.`
  Verification: `Focused negative selection .1 and no-op scalar reuse .2.3 pass fixed genuine resource/currentness/adverse cases. Exact original PPIF now completes native --verify-hdl from6b1632c4ecb6, status0, real64.40, nonempty HDL. Complete carrier/report JSON is unchanged; predecessor HDL differs only in its generation Date. .2.4 retains full source/output/first failures, saved-only corruption controls and known-job settlement. This closes the cost counterexample only; matched timing distribution, whole toolchain/runtime and full/hosted qualification remain absent under .13. Contract/book slices .3-.9 now precede full9.`
  Commit: `child slices`
  Children: `PUBLICATION-REGRESSION-REPAIRS.20.2.1, PUBLICATION-REGRESSION-REPAIRS.20.2.2`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.2.1`
  Status: `done`
  Goal: `Preselect parser allocation dependencies without caching validity.`
  Acceptance: `Completed implementation contract: weak snapshot-bound negative membership only; complete currentness and unchanged original validation/write/barrier behavior for possible dependencies. Fixed RED/GREEN counterexample, related/copy/foreign/nested/lifetime controls and book/facts qualify this focused slice only. Exact original acceptance remains in443 source/history; native qualification stays separate.`
  Verification: `Committed443fff2a70b3. Same genuine T2300 resource RED passes after negative-only weak snapshot selection; full live currentness remains for potential dependencies. Original validation/write/barrier bytes recover exactly by inverse substitution. Directly affected lifecycle/transition/publication cohort passes Files9 Tests45, plus syntax/POD/book freshness. All first sources/refusals and distinct evidence legs retain in allocation-dependencies artifacts and exact443 task/history. Card questions/routes retain with nonpositive bytes; limits/state/milestones unchanged. Original public confirmation remains separately owned, never inferred from focused checks.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.2.1: skip unrelated allocation captures`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.2.2`
  Status: `done`
  Goal: `Qualify the exact original public PPIF generation after the committed cost repair.`
  Acceptance: `Complete original public quiet --verify-hdl qualification after committed causal repairs, preserving first nonpasses and unchanged guards. Actual0/nonempty HDL, complete carrier/report and output conservation are mandatory; retain distribution/toolchain/runtime/full gaps. Exact prior contract remains in6b1632c4 source/history.`
  Verification: `First native timeout124 and separate bounded stacks remain exact under .1/.2. Scoped scalar reuse .3 preserves real writes/currentness/overridden dispatch and passes10 focused files/50 outer cases. .4 completes original native generation0 under unchanged180-second/88/4096, plus complete carrier/report and date-only HDL comparison. Known jobs/groups are absent. This public counterexample closes; complete local/hosted qualification remains .13.`
  Commit: `pending`
  Children: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.1, PUBLICATION-REGRESSION-REPAIRS.20.2.2.2, PUBLICATION-REGRESSION-REPAIRS.20.2.2.3, PUBLICATION-REGRESSION-REPAIRS.20.2.2.4`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.1`
  Status: `done`
  Goal: `Retain first post-repair native timeout and own its residual cost.`
  Acceptance: `Record the declared original public confirmation faithfully, authenticate owned settlement, retain unchanged guards/source/input/tools and qualify no absent output. Commit this nonpass and a bounded diagnostic handoff before further experiments.`
  Verification: `Clean443fff2a70b3 original native confirmation exits124 at180 seconds without HDL; no RAM trip. allocation-public-native/timeout-settlement retain exact programme/result and independent six-job/two-group absence. Collection completeness is not success. The next sampler is separately declared; no original-stack/native-distribution claim. Full original source/history retains.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.1: retain bounded public generation timeout`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.2`
  Status: `done`
  Goal: `Locate residual native allocation cost after negative dependency selection.`
  Acceptance: `P1 next from clean .1. Reuse the authenticated prior deferred-signal observer in a new exclusive repository-local directory, bound to current source/fixture/instrument hashes. Sample one separate native CLI for30 seconds under unchanged88/4096, with16MiB stream caps and authenticated own-group settlement. Retain complete samples, first errors and source locations. Samples guide causal inspection only; no native timing/distribution/full-output credit. Select the smallest genuine counterexample and a separately owned repair before code changes; no blind long retry or higher limits.`
  Verification: `allocation-residual-observation-20261101 retains all120 snapshots from cleanb0974ffc5779; declared30-second stop is-15, not success. Independent census agrees;45 capture routes include scalar parsing. Source inspection binds bare scalar registration at ExpressionBuilder.pm931 through full dependent-tree current/after validation. Same-value registrations still revise allocation state in SignalManager.pm. This selects a genuine no-op-read counterexample next, not an already proven fix. All known jobs/groups are absent; original180-second timeout124 remains nonpassing. Complete source/sample/instrument/first-result and exact older history retain.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.2: locate residual scalar-read validation cost`


- ID: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.3`
  Status: `done`
  Goal: `Avoid redundant bare scalar registration without caching policy validity.`
  Acceptance: `Completed narrow native no-op reuse contract; actual writes, all unknown/subclass/tied/overridden paths and final source/holder/registry currentness retain. Fixed real scalar-parser RED/GREEN/resource and adverse controls, exact source inverses, book/facts/POD and normal commitment qualify this slice. Full original contract remains in6b1632c4 task/history.`
  Verification: `Committed6b1632c4ecb6. Fixed T2301 removes321 proof reads for three identical bare reads while preserving complete journals/policies/usage/physical source. First T2238 hook-bypass failure retains; native registration-method identity restores unchanged adverse dispatch. Final All tests successful Files10 Tests50. Original registration/currentness/write/barrier bodies recover byte-exactly. All source/probe/refusal epochs, scalar-kind/data-shape controls and normal doctrine results remain in allocation-scalar-read artifacts and exact6b task/history. Native qualification is separately owned by .4.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.3: reuse unchanged bare scalar references`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.4`
  Status: `done`
  Goal: `Confirm the original public PPIF after committed scalar no-op reuse.`
  Acceptance: `Completed clean committed scalar-reuse original PPIF native qualification under unchanged180/88/4096, plus complete carrier/report/HDL conservation and owned settlement. Preserve all causal/timing/toolchain/runtime gaps. Exact full contract remains in book-auxiliary-profile-history and prior committed task source.`
  Verification: `Clean6b1632c4ecb6 original --verify-hdl exits0, real64.40,1144185-byte HDL under unchanged180/88/4096. Complete carrier/report JSON equality preserves kinds; HDL differs only at the unique ScaffoldEmitter localtime Date. allocation-scalar-conservation retains all outputs/source/plans/streams and known-group absence. Saved reader rejects three distinguishing corruptions. Pre-fix current HDL, timing distribution, whole loaded-toolchain/runtime/full/hosted remain absent. Exact detailed source/evidence remain in1a389cdb task/history.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.2.2.4: qualify original public allocation generation`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.3`
  Status: `done`
  Goal: `Align composition child-header diagnostics with admitted parameters.`
  Acceptance: `After .2 commits, update only stale supported-header lists in T129/T131 to include admitted +params. Preserve complete failure DTOs, blocked reasons, valid/invalid headers and every other assertion. Confirm Parser.pm and COMPOSITION_SCOPE contract, focused tests, related book and normal commit.`
  Verification: `Committed2b6dc1a4. T129/T131 actual Files2 Tests146 PASS. Only2+7 supported-list tokens add admitted +params in canonical order; full inverses preserve all fixtures/DTOs/context/reasons/adverse assertions. Parser.pm/FailureReportBuilder match full8 bytes. composition-headers source/native proof retains; book scopes header hints separately from lowering profiles. Normal gates passed. Exact detailed source remains in1a389cdb history and actor-dependent-default-first-gate witness.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.3: align composition supported-header expectations`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.4`
  Status: `done`
  Goal: `Retain actor-parameter widths in legacy carrier and HDL checks.`
  Acceptance: `Update T1333 through T1337 positive width assertions to canonical scoped parameter expressions and eligible HDL ranges. Preserve every source fixture, selected numeric parser/report assertion, dataflow and adverse control. Bank depth stays source-time scalarized; fixed-width depth-only controls remain unchanged. Diagnostic ignored-path controls are not final-path qualification. Sync actor/transaction guidance and commit focused checks.`
  Verification: `Committedc8d93bc3. Actual T1333-T1337 Files5 Tests17 PASS: mutable param DATA_W/STATE_W carriers and eligible SV ranges retain. Full inverses preserve original sources, selected numeric parser/reports, dataflow/adverse and scalarized/depth-only shapes. actor-parameter-widths retains complete source/control/native/first-gate evidence. Book13a/13b/matrix and module-carrier card corrected without changing examples or budgets; all old facts/questions/routes preserved. Obsolete fixed32 claim disposition retired exactly; replacement example reviewed with complete census/join. Normal gates passed. Full original source/evidence remains in1a389cdb history and first-gate witness.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.4: retain actor parameter width expectations`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.5`
  Status: `done`
  Goal: `Retain immutable actor-constant width sources.`
  Acceptance: `Completed immutable actor-constant carrier checks; preserve fixed HDL, numeric reports, all fixtures/negative/dataflow and scalarized depths. Complete original contract remains in f881130a task/history.`
  Verification: `Committedf881130aa. Complete T1338-T1342 pass Files5 Tests17. Nine carrier assertions/labels retain static + DATA_W/STATE_W0 expressions; exact inverses preserve all other bytes, including every HDL assertion. Book/card preserve static context and prior examples/facts/routes within fixed budgets. All original/control/source/gate outcomes remain in actor-constant-widths evidence and exact f881 task/history. No broader generic/depth/override/runtime/full qualification.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.5: retain immutable actor constant width expectations`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.6`
  Status: `done`
  Goal: `Align parameter-default integration with canonical aggregate profiles.`
  Acceptance: `Completed T1345-T1349 default-profile contracts with original metadata/refusals, independently authored immutable counterparts and complete selected-value/kind checks. Exact original contract remains in e96393ffd and package-widths-doc-history witness.`
  Verification: `Children .1-.5 commit focused native tests and source conservation plus canonical book/spec closure. default-profile-doc-closure joins receipts to current sources without replay. No wider runtime/override/full/hosted credit. Exact detailed evidence remains in e96393ffd task/history.`
  Commit: `child slices`
  Children: `PUBLICATION-REGRESSION-REPAIRS.20.6.1, PUBLICATION-REGRESSION-REPAIRS.20.6.2, PUBLICATION-REGRESSION-REPAIRS.20.6.3, PUBLICATION-REGRESSION-REPAIRS.20.6.4, PUBLICATION-REGRESSION-REPAIRS.20.6.5`


- ID: `PUBLICATION-REGRESSION-REPAIRS.20.6.1`
  Status: `done`
  Goal: `Retain scalar actor default-source width carriers.`
  Acceptance: `t/1345-isf-actor-param-actor-constants.t and t/1349-isf-actor-param-package-constants.t only: use retained exact controls to preserve actor parameter roots whose defaults use actor/package constants. Keep every fixture/default/parser/report/HDL/refusal assertion. Correct only stale positive carrier expectations and labels; focused two-file check, relevant book and normal commit before mixed-aggregate slices.`
  Verification: `Committed1a389cdb. Complete T1345/T1349 ISF files pass Files2 Tests4; two carrier regexes/labels retain param DATA_W. Exact full inverses preserve every original fixture/default/IR/report/import/CLI/HDL/refusal assertion. Book separates default-source and width-source identity. scalar-default-widths artifacts and1a389cdb task/history retain complete original/current sources and first/gate results. No wider aggregate/full/runtime credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.6.1: retain constant-backed parameter width roots`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.6.2`
  Status: `done`
  Goal: `Preserve actor aggregate default source and static positive counterpart.`
  Acceptance: `Keep full original source/IR/report/adverse cases. Original mutable aggregate refuses HDL; separately authored static counterpart must preserve selected values/kinds and source relationships. Exact original remains in1b94/full10-intake.`
  Verification: `T1346 Files1 Tests2 passes, with exact original aggregate refusal/no partial HDL and independent static counterpart/canonical selected-parameter equality. DATA_W=BASE_W positive HDL alias remains. Actor-dependent-default source/focused packets retain all sources and first size-gate refusal.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.6.2: qualify actor aggregate default profile`


- ID: `PUBLICATION-REGRESSION-REPAIRS.20.6.3`
  Status: `done`
  Goal: `Preserve actor-backed child transaction defaults.`
  Acceptance: `Retain original source, IR/reports/bindings and negatives; distinguish allocated scalar capture from aggregate-only capture. Exact original remains in1b94/full10-intake.`
  Verification: `T1347 Files1 Tests2 passes. Original mutable aggregate refuses/no output; independently authored static LANES retains all authored values/kinds and explicitly removes only aggregate-only capture2. Scalar WIDTH/LIMIT/MODE and original positives preserve. Full transaction-actor-default packets retain.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.6.3: qualify actor-backed transaction defaults`


- ID: `PUBLICATION-REGRESSION-REPAIRS.20.6.4`
  Status: `done`
  Goal: `Preserve transaction-local defaults and the mutable-aggregate refusal.`
  Acceptance: `Keep original source/IR/reports/negatives. Independent static LANES must retain complete selected parameter kinds and immediate alias behavior. Exact original remains in1b94/full10-intake.`
  Verification: `T1348 Files1 Tests2 passes: original BASE/WIDTH aggregate refusal/no output, static counterpart equality, original alias/enum/capture positives and refs remain. Full transaction-local-default source/focused packets retain. No producer/runtime/full promotion.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.6.4: qualify transaction-local aggregate defaults`


- ID: `PUBLICATION-REGRESSION-REPAIRS.20.6.5`
  Status: `done`
  Goal: `Close default-profile documentation against final-path receipts.`
  Acceptance: `Completed saved-receipt/current-source join and canonical book/spec default-profile closure without test replay or wider runtime/override claims. Full exact contract remains in e96393ffd and full9-preflight-history.`
  Verification: `Joined actual T1345-T1349 passing receipts to unchanged final test sources via full-source witness hashes; no test replay. Current book and canonical downstream now distinguish selected IR/report values from scoped child aliases/captures/static support and immutable aggregate HDL admission. Original mutable cases and authored static counterparts remain explicit. default-profile-doc-closure retains join/source evidence. No wider runtime/override/full/hosted credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.6.5: align default-profile reference wording`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.7`
  Status: `done`
  Goal: `Retain imported immutable width expressions.`
  Acceptance: `Update only stale scheduled-source assertions in T1353/T1354/T1355/T1357 to exact imported constant expressions. Keep all fixtures/imports, selected numeric parser/reports, fixed HDL, bank/dataflow and refusal controls. Distinguish mutable actor params whose defaults use constants. Sync downstream/book, actual focused tests and normal commit.`
  Verification: `Committed source/current receipt join covers actual T1353/T1354/T1355/T1357 Files4 Tests8 PASS. Four carrier regexes/labels retain qualified immutable expressions; all other fixture/parser/report/HDL/import/dataflow/adverse bytes preserve. package-widths evidence and current/full9 history retain full details; book/spec and normal gates passed. No production/full/runtime credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.7: retain imported immutable width expressions`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.8`
  Status: `done`
  Goal: `Retain child-local transaction width and alias identity.`
  Acceptance: `T1368 preserves child DATA_W8 and immediate DERIVED_W against distinct actor constant DATA_W5. Update only positive child carrier/eligible HDL range assertions; retain numeric parent handoffs, parser/reports, local/direct scopes, source fixtures and every adverse control. Run actual test, sync transaction guidance and commit.`
  Verification: `Complete actual T1368 Files1 Tests4 PASS. Local child width roots and DERIVED_W=DATA_W alias remain distinct from actor DATA_W5. Full witnesses preserve numeric parent handoffs/reports, direct/unrelated and all adverse controls. transaction-local-widths source/focused/doc-history retains. Book/spec correct child source/range versus parent/direct wording. Normal gates qualify before .9; no production/forwarding/full/runtime credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.8: retain child-local transaction width aliases`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.9`
  Status: `done`
  Goal: `Correct auxiliary-width book example and remaining profile statements.`
  Acceptance: `T1377 book04 block2 must stop claiming independent mutable X/W requirements still generate numeric HDL. Retain that metadata counterexample as explicitly unsupported, with exact refusal, and add the separately authored runnable single-source aux_shared counterpart. Review affected book13a/13b/matrix and canonical downstream statements against current carriers versus numeric reports; preserve actual reusable-formal and broader external/runtime/library boundaries. Keep every positive lisp block generation-clean and commit focused book checks.`
  Verification: `Complete unchanged T1377 Files1 Tests2 PASS with21 standalone fixtures. Native original aux_origin separately exits1 with exact combined mutable next_data refusal/no emitted output. W/X input remains byte-exact as unsupported text; separate aux_shared qualifies. Book04/13a/13b/matrix correct stale scope/default/range claims; separate reusable-formal defect remains byte-exact and matrix shrinks. book-auxiliary source/original/focused/history evidence retains. Normal book/source/claim gates qualify before .10; no full/runtime/hosted credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.9: align auxiliary example and scoped-width guidance`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.10`
  Status: `done`
  Goal: `Close observed full8 repairs and admit full9.`
  Acceptance: `Join every observed failure to current actual-path passing receipts, preserve refusal boundaries and declare clean exclusive full9 under unchanged command/guards/workflows. Exact full contract retains in9c568402/mcp-schema-intake.`
  Verification: `full8-repair-closure conserves the full observed-file set/current sources; ignored controls give no pass credit. Cost production equals6b and saved reader rejects corruptions. Fresh68.0367787679pct/normal-pressure admission, absent exclusive slots and full required-job plan qualify preflight only. Native book/source/normal gates passed. .13 owns first outcome/full qualification/push.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.20.10: close observed repairs and admit full9`

- ID: `PUBLICATION-REGRESSION-REPAIRS.20.11`
  Status: `pending`
  Goal: `Reject accidental task nodes outside the parsed Task Tree section.`
  Acceptance: `P2 after hosted publication, macOS relevance and ordered workflow repairs, before private/POD return. Actual full8-intake-render-20261101 integrity output proves .19/.20 blocks outside Task Tree are invisible to direct-child validation; f149 previously contains .19 outside the section while its root omits that edge. .20.1 moves all actual nodes into the parsed section now. Own a separate checker/fixture repair that rejects misplaced raw node blocks while preserving fenced examples and explicitly historical views. Review only relevant parser/contracts and genuine fixtures, retain original false-accept and corrected-rejection controls, and verify focused integrity checks/book before commitment. No broad audit or publication delay from this later guard task.`
  Verification: `Original rejected task/source/checker and the exact byte-preserving move retain in full8-task-section-refusal-20261101.json.gz. Current ownership is corrected under .20.1; the checker guard remains unimplemented.`
  Commit: `pending`


- ID: `PUBLICATION-REGRESSION-REPAIRS.21`
  Status: `done`
  Goal: `Resolve the first full9 MCP schema mismatch before fresh qualification.`
  Acceptance: `P1 before publication. Preserve original full9/current schema source and classify intended catalog-field evolution versus producer regression through canonical schema/catalog contracts and exact public envelopes. Never blindly refresh or weaken the full snapshot, source kinds, tool/resource envelopes, keys or malformed/refusal controls. Commit focused causal repair, close .22 wording, then declare clean exclusive full10 before .13 once-only launch/push/hosted qualification.`
  Verification: `Full9 remains native143/nonpassing. .21.1 repairs the first-record optional-schema oracle and explicit required vocabulary with actual focused RED/GREEN controls; .22 corrects width prose. .21.2 joins exact final sources/receipts and admits clean exclusive full10. .13 owns actual full local/push/hosted/Pages outcomes.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.21.1, PUBLICATION-REGRESSION-REPAIRS.21.2`
  Commit: `child slices`

- ID: `PUBLICATION-REGRESSION-REPAIRS.21.1`
  Status: `done`
  Goal: `Repair order-dependent MCP full-example schema expectations.`
  Acceptance: `Preserve all envelopes/values/JSON kinds/negative cases; distinguish declared required/optional vocabularies and inspect every returned record. Exact original contract/history retains in4811ce1a/full10-preflight-history.`
  Verification: `Only original projected examples.catalog_entry_keys differed after f9b50f197 changed the first match. No producer change. Full T1445/T1444/T1455/T314 pass Files4 Tests16; explicit declaration-removal follow-up T1445 Files1 Tests5 passes after genuine RED. Both real orders, optional absence, every required removal/unknown insertion and authored leading-record values/kinds retain. mcp-schema intake/source/RED/focused and declaration follow-up retain full witnesses. Book/card current; full10/push remain unqualified.`
  Commit: `cc81a6ab initial repair;1cc3402d explicit required vocabulary.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.21.2`
  Status: `done`
  Goal: `Prepare fresh full10 after MCP repair and book scope clarification.`
  Acceptance: `After .21.1 and .22 commit, join current actual-path focused receipts/source epochs and preserved refusal boundaries. Declare fresh capacity/kernel pressure, unchanged guards/unfiltered command/workflows, unique full10 live journal/checkpoint and clean committed Memory handoff. .13 launches once, consumes first actual result, commits outcome and follows authorized normal push plus all exact-SHA hosted/Pages qualification. No old checkpoint, filtered source set, guard relaxation or partial-native pass credit.`
  Verification: `full9-repair-closure joins23 old actual-path focused/native successes to unchanged current sources and three final MCP/book receipts to exact source witnesses. Fresh full10 admission69.9534098307pct/normal pressure leaves five unique slots absent; command/guard/recorder/workflow hashes and complete required-job inventory unchanged. Preflight only; .13 launches once from the clean committed revision and consumes first full outcome before push. Full9 remains native143/nonpassing.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.21.2: admit fresh full10 after schema and book repairs`

- ID: `PUBLICATION-REGRESSION-REPAIRS.22`
  Status: `done`
  Goal: `Clarify direct own-transaction versus actor-backed width wording.`
  Acceptance: `After .21.1, scope 13b/matrix selected numeric widths to child-local parent handoffs and direct own-TX_PARAM consumers. Preserve actor/child named carriers, examples and separately owned forwarding/library/runtime defects. Exact original contract/draft survives in book-width-scope-source/full9-intake.`
  Verification: `Actual complete full9 T1336/T1368 successes join byte-identical current test sources: actor-backed direct formals retain named DATA_W; child-local roots retain their own aliases, parent handoffs use defaults, direct own-TX_PARAM widths scalarize. Three prose replacements preserve every fence and reusable/ATL defect paragraph byte-exact. T1305 passes Files=1, Tests=285. Source/history/native book/copied-source and normal doctrine gates qualify prose only. .21.2 admits fresh full10; no full/push/hosted credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.22: scope transaction width documentation to its parameter owner`

- ID: `PUBLICATION-REGRESSION-REPAIRS.23`
  Status: `done`
  Goal: `Repair supported AHB HBURST SEQ completed-source-intent refusal.`
  Acceptance: `P1 before fresh full CI/push. Preserve T1490-T1493, every source/positive/negative/report/HDL assertion, all literal/currentness/late-mutation guards and declared AHB support. Diagnose actual first failure at the proper producer/consumer boundary; no blind test refresh, capsule freezing, stale proof acceptance or unsupported-profile relabeling. Split unsafe scope before implementation.`
  Verification: `Arithmetic-containing mask was falsely selected for bitwise-only intent. .23.1 repairs family selection and preserves mandatory installed/published proof. T2297/T2268/T2296 and exact strict public path pass; full AHB semantic/HDL/corpus qualification remains .26/.13. Original public tests/inputs and proof fences remain unchanged.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.23.1`
  Commit: `child .23.1`

- ID: `PUBLICATION-REGRESSION-REPAIRS.23.1`
  Status: `done`
  Goal: `Trace and causally repair the first supported HBURST source refusal.`
  Acceptance: `After outcome commits clean, query canonical currentness/source-width contracts, read actual capture/prepare/required-selection/caller paths, relevant tests/history/book and reproduce the exact public source with distinguishing controls. Identify the specific source object/shape/state and failing predicate before changes. Fix only that mechanism while preserving complete source intent and final guards; add meaningful RED/GREEN/currentness/mutation regression at the actual boundary. Focused failing public path plus directly affected checks/book; commit before widening qualification. If scope grows, create bounded children first.`
  Verification: `Fresh exact strict check RED1 then GREEN0. Diagnostic identifies uncaptured arithmetic-mask intermediate292; selector now scans all operands and rejects that data family without granting proof. Published source_literal_intent remains mandatory despite holder removal/opcode change. Actual native T2297/T2268/T2296 pass Files3 Tests15; both mask orders/targets and real post-publication mutation qualify. Intake/RED/focused/source retain originals, diagnostic and inverse checks. Full paths remain .26/.13.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.23.1: preserve ordinary arithmetic masks and published literal guards`

- ID: `PUBLICATION-REGRESSION-REPAIRS.24`
  Status: `pending`
  Goal: `Commit receiver ownership for SPECFORGE FSMGEN-REQUESTS.15.`
  Acceptance: `P1 after current repair and before full11. incoming-request15 retains all90 files/1282756 bytes with exact decoded/hash verification, clean foreign912f5938 source and read-only same-volume provenance. Create bounded ISF-MINIMUM-HOLD-EVENT-ORDER tree before any implementation; preserve R1 minimum complete-cycle hold, R2 inclusive physical/logical event order, R3 clock/reset/provenance projection and R4 refusals; optional R5 separate. Small own current positive/refusal intake, book/feedback/KMap and commit. Preserve existing required SPECFORGE/publication order and coordinate actor-level SEM .33.6. Record self-reset non-vacuity risk and tests. No foreign script/repository/pin mutation; no feature support claim.`
  Verification: `Provider signoff/request/readme/sources/expected contract read; copied packet and risk note retain. Provider pin54ac/upstreamf149 results remain third-party until own current intake. Implementation not started.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.25`
  Status: `pending`
  Goal: `Correct stale width representation wording in the downstream response.`
  Acceptance: `P1 after .24/before full11. Current SPECFORGE_FEEDBACK_RESPONSE opening request12 and older generic-width paragraphs conflate numeric parser/report defaults with scoped carriers/eligible named HDL ranges. Review canonical carrier card and actual T1336/T1368 source/native witnesses; correct only those current representation claims and identify historical override observations as historical. Preserve open generated-top/library/override/runtime and grouped-request boundaries. Prose-only focused doc/book/normal commit; no broad verification or compiler change.`
  Verification: `Full exact response bytes/hash and both loci retain in incoming-request15/full10-pending-intakes. No correction is claimed yet.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.26`
  Status: `pending`
  Goal: `Prepare fresh full11 after all owned publication repairs/intakes.`
  Acceptance: `After .23-.25 and .27 commit, conserve actual current-source/final-path passing receipts and declared refusal boundaries. Fresh capacity/kernel pressure, unchanged guards/unfiltered programme/workflows and unique full11 journal/checkpoint; clean committed handoff before .13 once-only launch. Complete native0 precedes normal authorized push/all exact-SHA hosted/Pages success. No spent checkpoint or partial-full credit.`
  Verification: `Pending; full10 is controlled native143/nonpassing after actual source-generation failures.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.27`
  Status: `pending`
  Goal: `Perform due cleanup after frozen full10 settles.`
  Acceptance: `P1 before .26. Last cleanup2026-10-31T15:02:31.201454+00:00 becomes due during immutable full10; its pending queue preserves that observation. Use installed authenticated same-volume collector/reviewer and exclusive dated slot, retain all candidates absent exact safe authority, verify independent membership/hostile controls, overwrite latest-only record and sync book reader. Normal commit, no foreign repositories/Git metadata/symlink deletion, current evidence loss or inferred reclamation.`
  Verification: `Due observation retains in full10-pending-intakes; no cleanup during frozen CI or new removal claim.`
  Commit: `pending`

## Current Frontier

Full10 remains nonpassing; .23.1 closes its first causal repair with focused checks.
.24 owns request15 receiver intake,
.25 the stale response wording, .27 due cleanup and .26 fresh full11 readiness.
Publication and saved required feature delivery remain unqualified.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PUBLICATION-REGRESSION-REPAIRS.24` | `pending` | Commit request15 receiver ownership and current public intake. |

## Decisions

- `2026-10-25`: Separate each causal regression repair; existing production contracts determine assertions. SEM .69.3 owns publication ordering; macOS history does not impose a renewed blanket hold.
- `2026-10-25`: Full2 was an administratively interrupted failing census, with no T1436 or complete-suite outcome. Qualifying full3 must set FSMGEN_T296_CHECKPOINT before launch.

## Blockers

- Fresh complete HBURST/SEQ semantic/HDL/full qualification remains .26/.13.
- .24/.25/.27 precede .26 fresh qualification; no user input is needed.
- Full local, normal push and exact-SHA hosted/Pages outcomes remain .13.

## Version-Retrievable Historical Views

- Acceptance history manifest: `docs/tasks/history/PUBLICATION-REGRESSION-REPAIRS/acceptance-history.jsonl`

Exact prior task/history retain in hburst-selector-source-20261102.

## Acceptance Checklist — arithmetic-mask family and published intent

- [x] **ROOT CAUSE (WHY + WHERE)** — Fresh --check --json exits1; bounded preload identifies an uncaptured arithmetic mask. SourceLiteralWidthAllocationSupport::_core_tree excludes arithmetic; SourceLiteralWidthSupport::requires_emission nevertheless demanded literal proof. Actual T2297 RED also demonstrates published-holder removal/opcode change escaping the old guard. Full sources, diagnostic and original RED are retained.
- [x] **ADDRESSED (verified)** — Inspect all operand families independent of order; unsupported arithmetic stays on its existing width path. Installed holders and actual rows already published as source_literal_intent remain mandatory. Both target languages retain explicit mask width/data/increment. Real publication-boundary mutation refuses HDL and completed capture. No source allocation, numeric width proof, generation fence or original test body changes.
- [x] **NO REGRESSION** — All tests successful; Files=3, Tests=15 for full T2297/T2268/T2296. Exact supported HBURST strict check exits0, success true, diagnostics empty and original support identity. Re-derivation: native focused/public commands; falsification: original selector RED and real installed/published mutation refusals; durability: source/receipt digests, unchanged original tests and committed regressions. Native book/source and normal doctrines qualify the commit. Remaining AHB semantic/HDL/full/push/hosted qualification stays .26/.13.
