# PUBLICATION-REGRESSION-REPAIRS: Current Publication Qualification Repairs

## Metadata

- Tree ID: `PUBLICATION-REGRESSION-REPAIRS`
- Status: `active`
- Roadmap lane: `R14 / regression qualification`
- Created: `2026-10-25`
- Last updated: `2026-11-03`
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
  Children: `PUBLICATION-REGRESSION-REPAIRS.1, PUBLICATION-REGRESSION-REPAIRS.2, PUBLICATION-REGRESSION-REPAIRS.3, PUBLICATION-REGRESSION-REPAIRS.4, PUBLICATION-REGRESSION-REPAIRS.5, PUBLICATION-REGRESSION-REPAIRS.6, PUBLICATION-REGRESSION-REPAIRS.7, PUBLICATION-REGRESSION-REPAIRS.8, PUBLICATION-REGRESSION-REPAIRS.9, PUBLICATION-REGRESSION-REPAIRS.10, PUBLICATION-REGRESSION-REPAIRS.11, PUBLICATION-REGRESSION-REPAIRS.12, PUBLICATION-REGRESSION-REPAIRS.13, PUBLICATION-REGRESSION-REPAIRS.14, PUBLICATION-REGRESSION-REPAIRS.15, PUBLICATION-REGRESSION-REPAIRS.16, PUBLICATION-REGRESSION-REPAIRS.17, PUBLICATION-REGRESSION-REPAIRS.18, PUBLICATION-REGRESSION-REPAIRS.19, PUBLICATION-REGRESSION-REPAIRS.20, PUBLICATION-REGRESSION-REPAIRS.21, PUBLICATION-REGRESSION-REPAIRS.22, PUBLICATION-REGRESSION-REPAIRS.23, PUBLICATION-REGRESSION-REPAIRS.24, PUBLICATION-REGRESSION-REPAIRS.25, PUBLICATION-REGRESSION-REPAIRS.26, PUBLICATION-REGRESSION-REPAIRS.27, PUBLICATION-REGRESSION-REPAIRS.28, PUBLICATION-REGRESSION-REPAIRS.29, PUBLICATION-REGRESSION-REPAIRS.30, PUBLICATION-REGRESSION-REPAIRS.31, PUBLICATION-REGRESSION-REPAIRS.32, PUBLICATION-REGRESSION-REPAIRS.33`

- ID: `PUBLICATION-REGRESSION-REPAIRS.1`
  Status: `done`
  Goal: `Align aggregate-alias refusal tests with admitted record actor outputs.`
  Acceptance: `Replace only the obsolete T1259 record-output refusal after canonical008e629ced admission, using a still-closed packed-list output control. Preserve aliases/lowering/CLI, local/imported/unused record positives and transaction-record/aggregate-bank refusals. Exact original contract/source remains in 6da362e27 and t1545-git-diagnostic-intake.`
  Verification: `Original1946fd353 RED retains T1259 failures170/171 while T2033 passes. Test25c01f012 predates producer008e629ced. Valid same-width list control preserves every still-closed boundary and precise diagnostics. Actual aggregate-alias-focused tests and native book/POD/source/index/normal gates pass. aggregate-aliases.json preserves complete original/current source, first outcomes and distinct proof legs. No producer/support/API/MCP expansion; full/push remain separate.`
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
  Acceptance: `Preserve authored req/worker.addr separately from physical private carriers, conditional dataflow, width and start/done state-local handshake. Correct only the reproduced stale raw-binding oracle/comment. Exact complete contract/source remains in 6da362e27 and t1545-git-diagnostic-intake.`
  Verification: `Original T1388 equals bff/full2; actual FSM declares private isf_port_worker_addr width8, writes req in parent_do and consumes it in worker_update. Git32642d54c plans scope and57b6495f8 activates FormalLowering; canonical .7 evidence preserves authored names. State-bounded assertions retain private eight-bit storage, req-to-carrier/worker dataflow, exact done identity and independent public projection. T1388/T1243/T1961 pass Files3 Tests14; tightened T1388 separately passes Files1 Tests6. local-do-bindings/native/source/history retain full proof legs. Book/POD/source/index/normal gates pass; producer/DSL/support/corpus/API/MCP unchanged; full CI remains separate.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.3: check private local-do binding dataflow`

- ID: `PUBLICATION-REGRESSION-REPAIRS.4`
  Status: `done`
  Goal: `Refresh exact shared-datapath DTO goldens for nullable pulse delay.`
  Acceptance: `Refresh only exact T139/T140 DTO goldens for intentionally nullable pulse_delay_cycles. Preserve complete public DTOs, all contributors/bindings/drive intent and delayed-pulse exclusion; exclude only the existing delegated forward-IR keys. Exact original contract/source remains in 6da362e27 and t1545-git-diagnostic-intake.`
  Verification: `Byte-exact original fixtures generate complete metadata through the public HDLGenerator API. First unsupported accessor error/recipe is retained; documented instance_name fixes only the collector. Five undef additions are the only test delta; child families carry null while drive_intent keeps its distinct shape. Introducing9dca2caa389/unchanged producer hashes preserve delayed-pulse exclusion without fresh runtime credit. Metadata/structural/cache controls pass Files4 Tests8; native book/POD/source/index and normal gates pass. shared-dto-repair retains full source/status/proof legs. No filtering/equality weakening or producer change; full CI remains separate.`
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
  Acceptance: `Preserve cause gaps; signal only authenticated own jobs. Keep88/4096, unfiltered programme and fresh checkpoints. Complete native Perl/VIAL/book0 precedes authorized normal push/all exact-SHA hosted/Pages success. Then honor the director pause before macOS or the next roadmap task. .29.1 fixes diagnostic loss/current fixture qualification, .30 repairs phase-control, .31 handles due cleanup, .32 admits fresh full13 after committed repairs; never replay spent slots or use partial passes as full credit.`
  Verification: `Full1-12 remain nonpasses. Clean7e1abc866 full12 has594 independently reconciled passing paths through T1556, including long1436/1437, both1438, repaired1445, APB1472 and AHB/HBURST1490-1493/paired-BUSY aliases. T1545 baseline exec_error and T1548 IAL0 line/byte/hash mismatch are actual failures; causes remain unassigned pending .29/.30. No complete Perl/T296/VIAL/final-book/full/push/hosted/Pages success.`
  Outcome: `After exact native failing summaries and guard PID/birth/source authentication, SIGTERM targets only guard35304; its existing trap settles session35376. Native143/recorder1 consumed; independent old identity/recorder absence and empty former session confirmed. Administrative failure stop, not host cutoff. Complete native/source/history/progress, first monitor/control corrections and all followups retain in full12-outcome-intake. Early overwritten sample durability gap remains explicit. Discussion-only cycle-accurate boundary-wave proposal creates no implementation or priority change. Due cleanup and conditional pause are owned; no user input needed.`
  Commit: `Full12 outcome: this work-unit commit; earlier outcomes remain in exact source/history.`


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
  Acceptance: `Stop literal-data selection at typed scalar comparison/not roots; retain holder priority, physical-child inventory and all proofs. Exact original contract/source: ea1a0a346 and request15-receiver archive.`
  Verification: `T2297/2296/1309/2268 pass Files4 Tests16; exact old selector fails4. Public AHB strict check succeeds. T1645 reaches only three stale identities, separately repaired. Superseded experiment/final executable identities retain in ahb-selector-proof-20261031. No capture/profile/manifest widening; full qualification separate.`
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
  Acceptance: `Repair only reproduced stale checked-AHB bridge references in T1605/T1607/T1608/T1609. Preserve frozen HIAL/source, semantic/plan hashes, counts, maps, limits, replay/adverse checks and disabled opt-in branches. Exact complete contract/source remains in 7e1abc866 and full12-outcome-intake.`
  Verification: `Original RED has five obsolete bridge assertions; independent public-reference import/literal repair preserves every other byte. Final defaults plus T1602 adverse/current-reference controls pass Files5 Tests31. T1607 explicit exact-map route remains skipped/unclaimed; its default adverse records run. execution-small-20261031 retains full native/source and proof legs. First stable-partition-card hook refusal is preserved; exact card restored and client status stays task/book. No production/guard/budget change; normal gates pass; full/hosted remain separate.`
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
  Acceptance: `Retain complete plan/random RED, interrupted proposed GREEN and exact sources; restore all five tests. Preserve capacity-cause gaps and unchanged88/4096, require coordinated fresh admission, and never treat post-stop observations as at-cutoff attribution. Full original/source remains in 7e1abc866 and full12-outcome-intake.`
  Verification: `RED has only obsolete bridge assertions. Proposed substitution preserves other bytes; partial GREEN passes T1610 then stops137 at host88.3/88. All five tests restore exactly to d25c8a23e. Post-stop raw counters/AWK agree on82.18402862548828pct/pressure2 and stopped known PID absence, with no culprit/window/global-census claim. Complete recipes/sources/streams/proof legs retain in execution-plan-random-20261031. Native book/POD/source gates pass; unsupported generator --check status2 is retained, corrected KMap/index checks pass without book replay. Full/push/hosted stay open.`
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
  Acceptance: `Repair only independently reproduced bridge identities in four default oracles; preserve all other bytes, explicit-large guards and safety limits. Exact original contract/source: ea1a0a346 and request15-receiver archive.`
  Verification: `T1623-1626 RED has eight stale identities; exact inverse proves only bridge constants/imports changed. GREEN Files4 Tests26; T1626 opt-in excess remains unrun. execution-fiber-total packets retain full sources/streams and first90pct hook refusal. Existing authenticated history rollover conserves every node/current acceptance without changing any budget or enforcement state.`
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
  Acceptance: `Retain settled full6 and classify unchanged T114 via canonical namespace/history and bounded GHDL analysis; preserve all source/test bytes. Exact original contract/source: ea1a0a346 and request15-receiver archive.`
  Verification: `Native143 full6 has259 complete passing paths; T114 repeats namespace refusal. APB output constant ACCESS fails authenticated GHDL6.0.0; declaration plus two-reference control passes analysis. No runtime/full-profile credit. Normalizer skips reserved basic-shaped names; ISF .22.2 owns actual repair. full6-t114-intake retains complete logs/compiler/source/settlement and proof legs; no broader/full credit.`
  Commit: `This work-unit commit.`

- ID: `PUBLICATION-REGRESSION-REPAIRS.18.2`
  Status: `done`
  Goal: `Integrate the canonical reserved-identifier repair and restore the APB requester/generic-map qualification.`
  Acceptance: `Integrate canonical declaration-aware reserved naming and restore APB requester/generic-map qualification, preserving language-neutral meaning, target namespace closure and adverse controls. Canonical .22.2 owns production; this leaf owns integration. Complete original/source remains in 7e1abc866 and full12-outcome-intake.`
  Verification: `Naming72d343b, hold230b685 and scaffold6c69fc2 repairs commit clean. T114/generic/declaration/hold controls and complete T1420 pass; current T2154 and full dry-run pass. Fresh full7 admission63.92955780029297pct/pressure1 has independent saved-counter parsing; unused slots and exact unchanged programme/workflow/required jobs retain in full7-launch-plan. No future-headroom, full/hosted credit, filter, opt-in, guard or workflow change. Native book/source and normal gates qualify preflight only; full6 remains nonpass.`
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
  Acceptance: `Retain settled full7 and reproduce unchanged T1244 before repair; distinguish literal selection from target namespace through exact source/native/lint controls. Full original contract/source remains in bf583367 and full11-outcome-intake.`
  Verification: `Original holder/selection succeeds; namespace rejects authored bit as an SV keyword. Two-token serial_bit control generates and inverse FSM is exact; installed Verilator5.050 accepts it and rejects inverse keyword artifact. Full7 native143 has316 complete passing paths and authenticated settlement; no full/runtime credit. First mistaken observer exits25 and remains uncredited. full7-t1244-intake retains full original/native/source/typed/tool/control/history and proof legs. .19.2 fixes only the positive fixture; producers/guards unchanged.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.19.1: isolate wait fixture reserved keyword refusal`

- ID: `PUBLICATION-REGRESSION-REPAIRS.19.2`
  Status: `done`
  Goal: `Repair the diagnosed dynamic wait/shift literal selection and qualify its actual contracts.`
  Acceptance: `Change only wait_dynamic_sample_shift input bit and three references to serial_bit; preserve all semantics/negative cases and admit exclusive clean full8 under unchanged guards. Exact contract/source: ea1a0a346 and request15-receiver archive.`
  Verification: `Four-token inverse/outside-subtest equality and .1 native/legal-name lint control qualify full T1244 Files1 Tests39. No producer/guard/runtime change. t1244-keyword-repair-evidence retains originals/current sources. Fresh61.64404551188151pct/pressure1 admission and five absent slots qualify preflight only; first mixed-slot helper refusal retains. Full8 launch plan binds exact guard/CI/recorder/workflows/jobs. .13 owns full/push/hosted.`
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
  Status: `done`
  Goal: `Commit receiver ownership for SPECFORGE FSMGEN-REQUESTS.15.`
  Acceptance: `P1 after current repair and before full11. incoming-request15 retains all90 files/1282756 bytes with exact decoded/hash verification, clean foreign912f5938 source and read-only same-volume provenance. Create bounded ISF-MINIMUM-HOLD-EVENT-ORDER tree before any implementation; preserve R1 minimum complete-cycle hold, R2 inclusive physical/logical event order, R3 clock/reset/provenance projection and R4 refusals; optional R5 separate. Small own current positive/refusal intake, book/feedback/KMap and commit. Preserve existing required SPECFORGE/publication order and coordinate actor-level SEM .33.6. Record self-reset non-vacuity risk and tests. No foreign script/repository/pin mutation; no feature support claim.`
  Verification: `Receiver tree and exact copied actors own required/optional delivery. Fresh public statuses0/1/1/1 and monitor generation0 reproduce current boundary. Reset non-vacuity/repeated-event contract remains .2; implementation awaits prior required delivery/publication. Complete outputs/sources/conservation retain in request15-receiver-intake. Foreign records remain read-only.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.24: own SPECFORGE minimum holds and event ordering`

- ID: `PUBLICATION-REGRESSION-REPAIRS.25`
  Status: `done`
  Goal: `Correct stale width representation wording in the downstream response.`
  Acceptance: `P1 after .24/before full11. Current SPECFORGE_FEEDBACK_RESPONSE opening request12 and older generic-width paragraphs conflate numeric parser/report defaults with scoped carriers/eligible named HDL ranges. Review canonical carrier card and actual T1336/T1368 source/native witnesses; correct only those current representation claims and identify historical override observations as historical. Preserve open generated-top/library/override/runtime and grouped-request boundaries. Prose-only focused doc/book/normal commit; no broad verification or compiler change.`
  Verification: `Response and related card distinguish scoped carriers/eligible SV from numeric parser/report defaults, direct own-TX defaults and child-local parent handoffs. Old default32/override64 observation is explicitly historical. Complete full10 T1336/T1368 success rows join byte-identical current test sources; canonical carrier/book scope agrees. Request15, grouped/open forwarding/library/override/runtime and constructor-defect text remain. Prose-only source/evidence/book gates; no fresh override/full credit.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.25: align downstream width claims with scoped carriers`

- ID: `PUBLICATION-REGRESSION-REPAIRS.26`
  Status: `done`
  Goal: `Prepare fresh full11 after all owned publication repairs/intakes.`
  Acceptance: `After .23-.25/.27, conserve current-source focused results/refusals; require fresh capacity/pressure, unchanged guards/programme/workflows and unused full11 slots. Commit before .13; complete native0 before normal push/all exact-SHA hosted/Pages. No checkpoint reuse or partial credit.`
  Verification: `Readiness only:23 source/focused joins,556 full10 passes and nine current receipts retain refusals/later/full gaps. Admission73.54952494303386pct/pressure1; five unused slots; CI/guard/recorder/workflows/160 jobs unchanged. Wrong full10 T314-row demand, focused-only correction and owned-audit guard recovery are preserved. .13 owns once-only clean launch and complete0 before push/hosted; full original/source remains in 678ee1b4b and phase-control-intake.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.26: admit fresh full11 after owned publication repairs`

- ID: `PUBLICATION-REGRESSION-REPAIRS.27`
  Status: `done`
  Goal: `Perform due cleanup after frozen full10 settles.`
  Acceptance: `P1 before .26. Last cleanup2026-10-31T15:02:31.201454+00:00 becomes due during immutable full10; its pending queue preserves that observation. Use installed authenticated same-volume collector/reviewer and exclusive dated slot, retain all candidates absent exact safe authority, verify independent membership/hostile controls, overwrite latest-only record and sync book reader. Normal commit, no foreign repositories/Git metadata/symlink deletion, current evidence loss or inferred reclamation.`
  Verification: `Fresh exclusive 20261102 wrapper authenticates installed collector against native8647e2524; actual interval exceeds24h. Same-volume regular log/bin and root/Rust metadata agree with independent rg membership; every candidate retained, removed empty. Saved missing-member/unsafe-path/Boolean-size/invented-removal controls pass. Complete census/prior/source/receipt retains; latest-only record and same-size book reader advance. No content/reclamation/future-absence or workload replay claim.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.27: record due safe artifact census`

- ID: `PUBLICATION-REGRESSION-REPAIRS.28`
  Status: `done`
  Goal: `Refresh capacity and admit fresh full12 after the director resume.`
  Acceptance: `After settled full11, preserve current repair/source/receipt joins and late-path gaps; require fresh raw capacity/pressure with independent parsing, unchanged88/4096 and programme/workflows, unused full12 slots and a clean committed readiness boundary before .13. No reuse/filter/attribution or headroom promise. Full original/source remains in 4256f3431 and audit-source-paths-intake.`
  Verification: `After three projects pause, new admission63.57549031575521pct/pressure1 independently passes; all five full12 native slots are unused. Closure retains prior focused sources and536 independently extracted unchanged full11 passing paths, with partial1472/later stages still open at that boundary. CI/guard/recorder/workflow hashes and required-job inventory match. Book/source/normal gates qualify readiness only; actual subsequent full12 nonpass is retained by .13.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.28: admit fresh full12 after capacity coordination`

- ID: `PUBLICATION-REGRESSION-REPAIRS.29`
  Status: `active`
  Goal: `Restore current T1545 fixture qualification and retain complete native Git failure evidence.`
  Acceptance: `P1 .1 fixes the observed diagnostic loss with an actual native exec_error control and unchanged fixture/checker/policy contracts. Original full12 Git launch cause is unknown because its structured result was discarded; P2 .2 owns that historical cause rather than crediting a later pass as a fix. Any fresh recurrence activates .2 immediately before further qualification. After .1 commits, .30 and due maintenance precede fresh full13; no full-success credit from focused checks.`
  Verification: `Unchanged focused T1545 returns0, while the collector expecting the original1 rejects the mismatch and preserves both statuses. command_ok reports only status/stdout/stderr and drops diagnostic/exec_error/cleanup; this is an independently identified retention defect. t1545-git-diagnostic-intake retains exact original sources and native replay. No original launch cause is inferred.`
  Children: `PUBLICATION-REGRESSION-REPAIRS.29.1, PUBLICATION-REGRESSION-REPAIRS.29.2`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.29.1`
  Status: `done`
  Goal: `Preserve complete failed fixture-Git supervisor diagnostics in T1545.`
  Acceptance: `Add one canonical JSON TAP diagnostic for failed command_ok results, preserving existing die label/streams, fixed Git arguments, environment, timeouts, capture and cleanup. A genuine native session-leader setpgid refusal must supply the complete real result; independent error/status/PID/group evidence and equality prove retention with empty streams. Retain original RED/current GREEN and all original T1545 assertions. Update book/fact routing, run the smallest focused native check and normal commit, then .30.`
  Verification: `Unchanged original focused replay passes0, preserving the expected1 collector mismatch. Genuine session-leader/setpgid refusal supplies actual exec_error and empty streams; retention RED1 fails only missing JSON. One diagnostic line makes complete T1545 pass0/Files1 Tests12, including native status/PID/group absence, full-record equality, original checker failures and held pre-exec timeout. Exact inverse removes only the new control/diagnostic and restores every original test byte. Helper/supervisor/limits/arguments unchanged. Native/source/proof and book/KMap/normal gates qualify this retention/current-fixture slice; original full12 launch cause stays .29.2.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.29.1: retain complete failed fixture Git results`

- ID: `PUBLICATION-REGRESSION-REPAIRS.29.2`
  Status: `pending`
  Goal: `Resolve the original full12 fixture-Git launch cause if current evidence can establish it.`
  Acceptance: `P2 first macOS relevance followup after qualified push and director resume; activate immediately on any new native recurrence. Retain full12 source/status and explicit missing exec_error detail, join only authenticated current native failures to tool/kernel/cwd/containment evidence, and repair only an established cause with focused adverse controls. No blind retry, culprit attribution, retrospective cause or closure from passing replay. Keep owned until cause is resolved or a specific access/evidence blocker is recorded.`
  Verification: `Original full12 baseline stage returns exec_error with discarded detail. First byte-identical focused replay passes; historical cause remains unqualified. .1 closes the diagnostic gap for future actual results.`
  Commit: `pending`


- ID: `PUBLICATION-REGRESSION-REPAIRS.30`
  Status: `done`
  Goal: `Diagnose and repair the native T1548 phase-control IAL0 golden mismatch.`
  Acceptance: `P1 publication blocker after .29: reproduce prove -Iperl t/1548-source-hir-phase-control.t. Read SourceHIR renderer, public ISF scheduling contract, fixture, relevant book and introducing history. Native actual51lines/558bytes/hash92c497ec differs from expected45/484/hash8b82ddb3 while generated/manual actors, files and reports match. Establish intended source delta before changing any oracle or producer; preserve exact output equality, independent semantic/state-order and changed-input controls. Focused checks/book/live docs/normal commit precede maintenance and fresh qualification.`
  Verification: `Original T1548 and phase fixture still equal8876adb0b. Public scheduler/strict-check output is51lines/558bytes/hash92c497ec; removing only the exact six-line/74-byte authored input/output interface restores the old45/484/hash8b82ddb3. Parent input a7bf398ac3/output876b2c1d1d history and current LoweringIR/emitter establish intent. Only three golden values/labels change; exact inverse restores every old test byte and all fixtures/producer/private-package hashes stay unchanged. Canonical four-file HIR/phase checks pass0/Files4 Tests25. Live contract/cards/book reflect current bytes; July promotion audit stays explicitly dated. Native/source/proof and normal gates qualify this focused repair only; full publication remains .13. First hook's focused-doc line excess is funded in phase-control-containment.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.30: align phase-control golden with declared ports`

- ID: `PUBLICATION-REGRESSION-REPAIRS.31`
  Status: `pending`
  Goal: `Complete the due daily artifact census and safe cleanup after source-freeze settlement.`
  Acceptance: `After .29.1/.30 commit clean, adopt the current repository-local cleanup collector and same-volume conventions. Preserve active evidence and ambiguously shared data; delete only exactly proven disposable project artifacts. Retain native census/independent controls, overwrite docs/ARTIFACT_CLEANUP.md with latest date/one-line summary, sync relevant reader/book/live records and commit before .32. No cross-repository writes or unproven deletion.`
  Verification: `Latest committed cleanup2026-11-01T23:33:29.580422+00:00 became due during full12. Runtime due record retained in full12-outcome-intake; no cleanup/deletion was performed during the clean-source gate.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.32`
  Status: `pending`
  Goal: `Admit exclusive full13 readiness after the causal full12 repairs and due maintenance.`
  Acceptance: `After .29.1/.33/.30/.31 commit clean, adopt corrected .33 snapshot helpers and join actual native/focused repairs and exact current production/test/programme/workflow hashes. Refresh raw capacity/pressure and independent adopted-formula parser under unchanged88/4096. Declare unused full13 journal/log/results/T296 checkpoint, preserve full12 settlement and all missing stages, commit readiness before .13 once-only unfiltered Perl/VIAL/book. Complete0 precedes authorized normal push/all exact-SHA hosted/Pages, then director pause. No spent-slot reuse, filters, opt-ins or future-headroom promise.`
  Verification: `Pending causal repairs/maintenance and fresh source/capacity qualification. Full12 administrative143 after actual test failures is not full success.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.33`
  Status: `done`
  Goal: `Remove project-absolute producer path metadata from publication source packets.`
  Acceptance: `P1 before .30/fresh publication: full12-outcome-source retains an absolute project-owned instrument.path because Python resolves __file__. Inspect structured path metadata in the relevant recent publication packets/producers, preserve exact originals and source identities, normalize only proven project-root path fields to repository-relative values and prevent recurrence in current snapshot helpers. Do not rewrite original source/native payloads or OS/toolchain dependencies. Verify complete field conservation, relocation-safe retrieval and negative controls; sync docs/task and commit separately.`
  Verification: `Five producer path fields across the finite full11/full12 source packets normalize to literal relative addresses; all other JSON fields and embedded producer source identities are exact. Complete original compressed bytes retain in audit-source-paths-intake. Original reader RED1 becomes GREEN0 with invalid-address controls and same-volume relocated source/hash readback. Current five template helpers independently return relative metadata from actual absolute __file__ inputs; no spent programme executes. Proof/current helper sources preserve the repairs for fresh-session reuse. Book/fact/task and normal gates qualify metadata only; native CI/production inputs unchanged.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.33: make audit producer addresses portable`

## Current Frontier

.29.1 diagnostic/current-fixture and .30 phase-control repairs pass focused
checks; .33 portable audit metadata is qualified. The omitted original full12
Git launch cause remains .29.2, first at macOS relevance after qualified push/
director resume or immediately on recurrence. .31 due maintenance and .32 fresh
full13 readiness precede .13 complete native/push/hosted/Pages and the pause.

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PUBLICATION-REGRESSION-REPAIRS.31` | `pending` | Complete due safe artifact maintenance. |
| 2 | `PUBLICATION-REGRESSION-REPAIRS.32` | `pending` | Qualify exclusive fresh full13 readiness using corrected snapshot helpers. |

## Decisions

- `2026-10-25`: Separate each causal regression repair; existing production contracts determine assertions. SEM .69.3 owns publication ordering; macOS history does not impose a renewed blanket hold.
- `2026-10-25`: Full2 was an administratively interrupted failing census, with no T1436 or complete-suite outcome. Qualifying full3 must set FSMGEN_T296_CHECKPOINT before launch.

## Blockers

- Due maintenance/readiness and complete fresh qualification precede publication.
- .29.2 owns missing historical launch cause; any actual recurrence blocks further qualification.
- Full12 is settled; no background result or user permission is outstanding.
- Complete local/push/hosted/Pages remain .13; honor the conditional pause afterward.

## Version-Retrievable Historical Views

- Acceptance history manifest: `docs/tasks/history/PUBLICATION-REGRESSION-REPAIRS/acceptance-history.jsonl`

Exact prior task/history/cards and original phase sources retain in phase-control-intake-20261103.

## Acceptance Checklist — current phase-control source golden

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S explicit_interface_ports identifies a7bf398ac3 parent input preservation; 876b2c1d1d adds outputs to that LoweringIR carrier. The existing emitter writes the exact interface block. Current native RED/current public output and unchanged July fixture/test show the old checksum omits that six-line/74-byte block; removing only it restores the old checksum exactly.
- [x] **ADDRESSED (verified)** — Refresh only the current line/byte/hash golden and labels. Exact inverse restores every original test byte; fixtures, SourceHIR packages, parser/scheduler/emitter and public scope stay unchanged. Current contract/cards/book use the native snapshot; the original promotion audit is explicitly dated, with complete old source retained. All equality, malformed-input, provenance, ordered-variant and private-surface controls remain.
- [x] **NO REGRESSION** — All tests successful; Files=4, Tests=25 in phase-control-focused-20261103, plus independent public generated-IAL0 strict-check0. Re-derive current output/metrics and source/history; falsify exact original-checksum inverse and unchanged fixtures/test controls; durability is complete native/source/intake/proof and committed book/fact/task/Git. Native book/KMap/staged/normal gates qualify this focused slice only; complete full local/push/hosted remain pending.
