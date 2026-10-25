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
  Children: `PUBLICATION-REGRESSION-REPAIRS.1, PUBLICATION-REGRESSION-REPAIRS.2, PUBLICATION-REGRESSION-REPAIRS.3, PUBLICATION-REGRESSION-REPAIRS.4, PUBLICATION-REGRESSION-REPAIRS.5, PUBLICATION-REGRESSION-REPAIRS.6, PUBLICATION-REGRESSION-REPAIRS.7, PUBLICATION-REGRESSION-REPAIRS.8, PUBLICATION-REGRESSION-REPAIRS.9, PUBLICATION-REGRESSION-REPAIRS.10`

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
  Acceptance: `After .2 commits clean, use the Knowledge Map and actual public CLI fixture inspection genuinely needed for .3 binding diagnosis, with bounded process/UTC/monotonic/trace/stream/settlement evidence. Authenticate any reused helper and invoke only its selected capture function for new needed inputs; never run old native diagnostic mains, original spent sources or invalid startup controls. Preserve the existing sixty-second query bounds and RAM88/4096. Before new audit code/source, record exact inputs, literal expected semantic/route scope and saved-reader verification/control requirements. Retain complete actual products and first failures; saved replay defaults must not relaunch queries. Name the precise original execution-service/host lifecycle/stop/partial-stream authority available or unavailable; a new success cannot attribute the spent intervals. Update SEM .93 and ISF-REDUCTION .16 with current before-publication observation/disposition while retaining original failures and causal gaps. Verify literal binding/route predicates, source/program/trace/settlement identity and meaningful adverse saved-record controls, native book/source and staged/normal gates, then commit before .3 code repair. This satisfies existing qualification requirements, without a new historical startup investigation, host-policy/auth change or feature/corpus/API/MCP expansion.`
  Verification: `Both genuinely required current intakes completed with integer0, no timeout, complete normalized stdout/stderr, actual wrapper/producer traces and absent owned sessions/groups under fixed60 and RAM88/4096. Before capture, contract.json declares the literal Knowledge Map route and exact Git-derived T1388 conditional-do source with the complete authored transaction_port_bindings row from canonical T1243 meanings. No old source/diagnostic main or startup control was replayed. observe.py preserves the actual programme, input/revision/hash, clocks/owned PID/session, products and trace; default saved checks do not launch queries. verify.py proves complete finite case closure and exact original fixture selection; genuine omitted/extra/covaried-fixture and wrong status/type/clock/recipe/settlement/covaried-product controls refuse. authority-disposition.json pins original failures, retains the missing defaults schedule slot and invalid diagnostic-parent outcome, and identifies original provider telemetry unavailable through current exec/session APIs without claiming global host-log absence. Original causes stay open in SEM .93/ISF-REDUCTION .16; their before-publication observed-query and explicit-disposition portion is met. normal-query-intake-focused.json retains saved/current Knowledge Map/locality checks, all status0. Book explains the separate claims and saved-only replay. Native book/POD/source/index and complete staged/normal gates are required before commit. No producer/API/DSL/corpus/MCP behavior change, historical causal repair, raw-root/full-environment or latency-distribution claim.`
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
  Acceptance: `P1 maintenance from clean2b3ca9bbe, before .8 long focused work. Reuse the byte-exact installed census20261020 authenticated against a13376d4ba5f2b89af45b2d1170e5221efdca211; a new artifact-census-20261025 wrapper selects only BASE2b3ca9bbe, this owner and exclusive output. Preserve its independent rg/os.walk membership and existing missing-member/unsafe-path/primitive-size/invented-removal controls; default saved replay must never walk/delete. Read the latest cleanup record, canonical cleanup/locality procedures and relevant book. Census root/project-local generated artifacts and required Rust log/bin locations without crossing Git write boundaries or inspecting submodule implementations. Preserve all original evidence, current source/book, required caches and planned worktrees. Delete only exact provably disposable owned artifacts; a no-removal outcome is valid when authority is absent. Overwrite docs/ARTIFACT_CLEANUP.md with only the current date/one-line result, retain dated evidence with honest metadata-only versus byte/absence scope, run focused docs/book/doctrine checks and commit before .8.`
  Verification: `From clean2b3ca9bbe, the byte-exact installed collector authenticated against a13376d4 performs the due read-only same-volume regular log/bin census in a new exclusive dated slot. Independent rg/os.walk membership, explicit root/six Rust locations and excluded Git/symlink/volume boundaries qualify. Every candidate is retained: no exact disposal authority is established, and no deletion is attempted. Saved replay and existing actual missing-member/unsafe-path/boolean-size/invented-removal controls pass. The latest-only record uses the receipt UTC; book now routes to the dated saved reader. This proves metadata/membership only, not candidate content or reclaimable bytes. Complete receipt and guarded command logs plus unit commit retain durability. First staged gate refuses an unnecessary zero-delta book aggregate authority refresh; retain that failure and restore the prior authority, since the same-length link changes no aggregate counts. Native book/source and fresh staged/normal doctrines gate handoff to .8 focused memory diagnosis.`
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
  Acceptance: `From clean6c07ae16d, declare unfiltered T1437 input/code identities and the exact existing capture_live programme before execution. Select /usr/bin/time -l prove -lv -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t under the unchanged existing88/4096 guard, without native runtime opt-in. Keep complete verbose TAP/resource output, original guard137 and current attribution gaps. Authenticate unchanged input against full3 revision88a0834fdf; profiler smoke check and saved-plan validation qualify only the instrument/preflight, not T1437. Declare passive owned PID/parent/RSS/VSZ and raw host vm_stat/sysctl samples, with observation-time scope and no causal blame from those samples alone. Reuse existing capture_live self-retention and unique journal; no new collector or broad retry. Correct the hosted task-index startup-hold projection using exact history/user authorization and explain the actual local-full/push/hosted sequence in the book. Native book/source and normal gates precede a clean commit and .8.2 execution.`
  Verification: `Exact test/generator/frontend/HDL/guard/capture identities equal the failed full3 revision88a0834fdf; plan.json declares the complete unfiltered command, unchanged bounds, absent native opt-in, normal-result predicates and passive observation limits. Existing /usr/bin/time -l accepts its true smoke command; this qualifies reporting only. Source/plan validation and Knowledge Map pass, as do native book/POD/current source/index checks in t1437-preflight.json/log.gz. git log -S identifies the old live-index wording at0af0842ab1224b208cff8adf1c7cfc62989b52a5, superseded by director authorization54ac5589bc7a18e7e33d676d4f3acf29103b9732. The live hosted row and book now state the real local-full/push/exact-SHA hosted sequence and separate historical causality. No focused run, memory cause/fix, full-suite or push outcome is claimed. Final metadata and staged/normal doctrine gates precede this clean preflight commit and .8.2 launch.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.8.1: qualify focused memory study contract`

- ID: `PUBLICATION-REGRESSION-REPAIRS.8.2`
  Status: `pending`
  Goal: `Observe the complete unchanged T1437 focused run under fixed memory guards.`
  Acceptance: `After .8.1 commits clean, inspect the exclusive t1437-focused-1 journal before launching its declared exact command through capture_live.py; never replay a nonterminal run. Retain complete first outcome/TAP/resource report and passive owned-process/host observations with UTC and scope. Every assertion/case remains enabled, no native opt-in or changed limit. Consume command status, distinguish interrupted versus normal test outcome and observed RSS from original full3 allocation attribution. Commit all finished observations before repair or full retry.`
  Verification: `Not launched.`
  Commit: `pending`

- ID: `PUBLICATION-REGRESSION-REPAIRS.8.3`
  Status: `pending`
  Goal: `Resolve a reproduced current memory cause or qualify a safe current retry path.`
  Acceptance: `Use .8.2 evidence before choosing a source fix. A reproduced defect requires exact public contract/history/code diagnosis, an owned small causal repair and meaningful regression checks retaining all existing coverage. If it does not reproduce, retain missing original allocation attribution explicitly, require a safe current path and do not claim a leak fixed. Commit completed units before a new clean full4 with its own journal and t296 checkpoint. Original historical macOS causality remains a post-push review, not a renewed blanket publication hold.`
  Verification: `Awaiting focused observations; no cause/fix/full4 outcome claimed.`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PUBLICATION-REGRESSION-REPAIRS.8.2` | `pending` | After .8.1 commits clean, inspect the declared journal and launch/consume the complete unchanged focused test. |

## Decisions

- `2026-10-25`: Separate each causal regression repair; existing production contracts determine assertions. SEM .69.3 owns publication ordering; macOS history does not impose a renewed blanket hold.
- `2026-10-25`: Full2 was an administratively interrupted failing census, with no T1436 or complete-suite outcome. Qualifying full3 must set FSMGEN_T296_CHECKPOINT before launch.

## Blockers

- Full3 is interrupted by the fixed host-capacity guard; .8 owns the current attribution/fix, after completed cleanup .9 commits clean. Full CI/push/hosted success is unqualified. .6/.10 remain ordered P2 follow-ups; historical native causality imposes no renewed blanket hold.

## Acceptance Checklist — `.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual before output at t/1259-isf-aggregate-storage-type-aliases.t line 170 shows the formerly forbidden record output is accepted; line171 retains obsolete actor-inputs diagnostic expectations. Git source008e629ced explicitly admits record outputs and changes that suffix to actor ports; the unchanged independent T2033 passes supported record sources and still-closed list/formal cases. No current producer defect is inferred from a stale negative assertion.
- [x] **ADDRESSED (verified)** — The obsolete record-output negative now uses a declared packed list with the same packed width, retaining a real unsupported actor-port boundary. All three exact diagnostic suffixes match the current contract; transaction and bank refusals and original storage/parser/lowering/CLI assertions remain. Existing independent record-output positives and overlap refusals pass. The book clarifies those existing kinds, without changing runtime or support.
- [x] **NO REGRESSION** — All tests successful for the guarded eight-file scalar/storage/record-writer/source band, with exact command/status/complete output retained in aggregate-alias-focused.json/log.gz. Native mdBook/POD/current source-byte/index checks pass; git diff --check is clean. Fresh claim/reference/ceiling and complete staged/normal scripts/check_doctrines.sh gates are required before commit. Full CI remains a separate checkpointed publication qualification.

## Acceptance Checklist — `.2`

- [x] **ROOT CAUSE (WHY + WHERE)** — Retained full2 reports empty stdout at t/1330-isf-atl-resolved-child-fixture-coverage.t line 1516 while the command explicitly requests --quiet; current source equals that failed source. The intentional8e5dd7f predicate suppresses informational notices, as decision0117 and the CLI book explain. The stale Wrote expectations conflict with that current behavior; no producer defect is inferred.
- [x] **ADDRESSED (verified)** — One existing resolved-child case runs nonquiet and retains its concrete generated-top Wrote assertion; all remaining quiet outdir cases require empty stdout. Every success/stderr/exact generated file-domain and machine-report assertion remains. Exact before/after identities and the complete old assertion domain retain; existing ATL guidance explains the same quiet/nonquiet behavior.
- [x] **NO REGRESSION** — All tests successful, Files=2, Tests=69 for guarded T1330/T2088. The independent quiet/trace suite qualifies both aliases, ISF/single/bundle paths, unchanged products and traced/untraced machine reports. Native mdBook/POD/current source-byte/index checks pass, and git diff --check is clean. Fresh inventory/reference/ceiling plus complete staged/normal scripts/check_doctrines.sh gates precede commit; full CI remains separate.

## Acceptance Checklist — `.7`

- [x] **ROOT CAUSE (WHY + WHERE)** — SEM .93 retains a sixty-second wrapper-query timeout; ISF-REDUCTION .16 retains the missing defaults schedule product/inner lifecycle and partial pipes. Their explicit before-publication condition requires observed next normal queries and a precise causal/authority disposition, not an invented historical repair. The actual required --trace-log / --emit-schedule-json T1388 intake and literal Knowledge Map question now preserve that current evidence; the complete original packets stay exact.
- [x] **ADDRESSED (verified)** — Both normal intakes return literal current products, complete normalized streams/actual traces, UTC/monotonic method observations and owned-session settlement under unchanged bounds. The fixture is byte-exact from the existing Git test and its complete authored binding oracle was declared before query. Original provider-record access is precisely limited; original missing bytes/cause and the invalid prior parent outcome are preserved. Saved default replay launches no source queries, and covaried product/fixture plus omission/extra/type/settlement controls refuse.
- [x] **NO REGRESSION** — knowledge-map: OK; current locality and saved original query controls pass with the new saved intake/fixture reader, all commands status0 in normal-query-intake-focused.json. Production/query/DSL/API/corpus sources are unchanged. Native mdBook/POD/current source-index/byte views and complete staged/normal scripts/check_doctrines.sh are mandatory delivery gates. Full CI, push and hosted/macOS follow-up remain separately owned.

## Acceptance Checklist — `.3`

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual full2 diagnostic at t/1388-isf-when-body-local-do.t line 86 shows the private carrier assignment where the stale regex expects raw addr. git log -S separates scoped plan32642d54c from production activation57b6495f8; current FormalIdentityPlan/production cards require private executable storage and authored report names. Exact native .7 source/report independently confirms the intended addr<-req row; no current producer fault is inferred.
- [x] **ADDRESSED (verified)** — Bounded parent_do and worker_update state bodies now prove req assignment and worker consumption through this fixture's private carrier. Exact internal/non-public declaration, eight-bit width and start/done handshake assertions remain explicit; public binding provenance stays parent/worker/input/addr/req/8. No assertion is removed to conceal the binding. The comment/book distinguish source lowering/artifact checks from separately qualified runtime and private names from authored endpoints.
- [x] **NO REGRESSION** — All tests successful in guarded T1388/T1243/T1961 (Files=3, Tests=14) and the final T1388 done-signal check (Files=1, Tests=6). Native mdBook/POD/current copied source/index pass; git diff --check is clean. Exact retained receipts and unchanged producer/source hashes scope the result. Fresh claim/reference/ceiling and complete staged/normal scripts/check_doctrines.sh gates precede commit; full CI is not claimed.

## Acceptance Checklist — `.4`

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual full2 mismatch at t/139-composition-shared-datapath-candidate-metadata.t line 84 and t/140-composition-shared-datapath-drive-intent-metadata.t line 95 identifies the additional nullable pulse_delay_cycles family field. git log -S identifies intentional9dca2caa389 producer adoption. Complete public DTO capture from exact unchanged fixtures confirms explicit null in family objects and unchanged separate drive-intent keys; no producer defect is inferred.
- [x] **ADDRESSED (verified)** — Only the five expected family hashes gain literal pulse_delay_cycles => undef. Every original complete-object comparison, contributor/binding/drive-intent field and the three pre-existing forward-IR exclusions remain intact. Qualified captures and exact before/after identities retain the full shape; production timing/admission code is byte-identical. The book explicitly distinguishes contributor family nulls from the existing drive-intent projection. The failed collector accessor is retained and corrected through its public documented accessor in a separate slot.
- [x] **NO REGRESSION** — All tests successful, Files=4 Tests=8 for guarded T139/T140/T168/T551, preserving independent structural leaf binding and cache mutation controls. Native mdBook/POD/current built source/index checks pass. Complete focused/book receipts and saved full DTO/fixture identities retain; git diff --check and fresh metadata/reference/claim plus complete staged/normal scripts/check_doctrines.sh are required before commit. No native runtime or full-suite success is claimed.

## Acceptance Checklist — `.5`

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S 'Tool-specific stores' -- PROJECT_DATA_LOCALITY.md identifies the existing local-store requirement. The retained original GH migration receipt locates the exact previously shared project log-cache record and unique run/revision ownership. The missing concrete GH environment guidance is now routed through the existing card/book. First staged diagnostics independently locate the omitted generated card-date shard, inventory drift after registry remeasurement and missing current-slice checklist; that failed gate remains retained.
- [x] **ADDRESSED (verified)** — Byte-exact original migration proof and full prior-run inventory are tracked; fresh read-only checks confirm local size/SHA/device and exact old-file absence. No deletion repeats or global-cache absence claim is made. The book provides the local cache/state/temp wrapper and read-only authentication boundary; existing card questions/facts remain within unchanged authority. Generated date shard, fresh inventory after final registry update and this leaf's checklist join final staging.
- [x] **NO REGRESSION** — knowledge-map: OK and project-data-locality checks pass, with complete commands/status/output in gh-locality-focused.json/log.gz. Native mdBook/POD/current built source/index checks pass. Exact book aggregate authority changes no ceiling. The original failed staged gate is retained; a fresh final staged scripts/check_doctrines.sh and normal hook must pass before commit. Full CI and hosted qualification remain separate.

## Acceptance Checklist — `.9`

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S of the prior latest-only cleanup summary identifies its Oct24 source record; the current receipt authenticates those exact Git bytes and a UTC interval over24h. Maintenance is due. No artifact is assumed disposable from its suffix or size.
- [x] **ADDRESSED (verified)** — Reuse the authenticated published collector with only the declared new boundary/owner/output wrapper; complete independent regular log/bin membership and root/Rust locations pass. No candidate is removed. Latest-only UTC record and book saved-reader link are refreshed; metadata-only scope and all excluded boundaries remain explicit. The first staged gate rejects a zero-delta reference-authority refresh; restoring the prior unchanged authority corrects that metadata error without changing a ceiling.
- [x] **NO REGRESSION** — Saved census and existing adverse membership/path/type/removal controls pass; knowledge-map: OK and native book/POD/current source/index checks qualify the documentation. Claim/reference/containment metadata and full staged/normal scripts/check_doctrines.sh gates precede commit. No runtime/test/guard or evidence-custody change.

## Acceptance Checklist — `.8.1`

- [x] **ROOT CAUSE (WHY + WHERE)** — Full3 records occupied capacity89.2 reaching88 and guarded status137, without T1437 or full-suite outcome/allocation attribution. git log -S startup/full-CI gates identifies the stale hosted-index projection at0af0842ab1224b208cff8adf1c7cfc62989b52a5; director ordering recorded54ac5589bc7a18e7e33d676d4f3acf29103b9732 supersedes that blanket hold. The remaining resource constraint needs focused observation, not an inferred native-startup cause.
- [x] **ADDRESSED (verified)** — Commit an exact unchanged unfiltered T1437 input/instrument contract, normal-result predicates and observation scope before launch. OS reporter smoke and native source hashes qualify preflight only. Correct the live hosted row and explain local-full/push/hosted sequencing in the book; original interrupted outcome and historical causal gaps remain. No collector, producer, test assertion or memory limit changes.
- [x] **NO REGRESSION** — knowledge-map: OK; exact native source/plan checks and OS reporter smoke pass in t1437-preflight.json/log.gz. Native mdBook/POD/current source/index pass. Fresh claim/reference/containment and complete staged/normal scripts/check_doctrines.sh gates precede commit. T1437 itself remains unrun until the next clean phase.
