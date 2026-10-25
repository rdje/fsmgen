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
  Children: `PUBLICATION-REGRESSION-REPAIRS.1, PUBLICATION-REGRESSION-REPAIRS.2, PUBLICATION-REGRESSION-REPAIRS.3, PUBLICATION-REGRESSION-REPAIRS.4, PUBLICATION-REGRESSION-REPAIRS.5, PUBLICATION-REGRESSION-REPAIRS.6, PUBLICATION-REGRESSION-REPAIRS.7`

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

- ID: `PUBLICATION-REGRESSION-REPAIRS.7`
  Status: `done`
  Goal: `Observe the next required binding-contract intakes and preserve explicit historical query dispositions.`
  Acceptance: `After .2 commits clean, use the Knowledge Map and actual public CLI fixture inspection genuinely needed for .3 binding diagnosis, with bounded process/UTC/monotonic/trace/stream/settlement evidence. Authenticate any reused helper and invoke only its selected capture function for new needed inputs; never run old native diagnostic mains, original spent sources or invalid startup controls. Preserve the existing sixty-second query bounds and RAM88/4096. Before new audit code/source, record exact inputs, literal expected semantic/route scope and saved-reader verification/control requirements. Retain complete actual products and first failures; saved replay defaults must not relaunch queries. Name the precise original execution-service/host lifecycle/stop/partial-stream authority available or unavailable; a new success cannot attribute the spent intervals. Update SEM .93 and ISF-REDUCTION .16 with current before-publication observation/disposition while retaining original failures and causal gaps. Verify literal binding/route predicates, source/program/trace/settlement identity and meaningful adverse saved-record controls, native book/source and staged/normal gates, then commit before .3 code repair. This satisfies existing qualification requirements, without a new historical startup investigation, host-policy/auth change or feature/corpus/API/MCP expansion.`
  Verification: `Both genuinely required current intakes completed with integer0, no timeout, complete normalized stdout/stderr, actual wrapper/producer traces and absent owned sessions/groups under fixed60 and RAM88/4096. Before capture, contract.json declares the literal Knowledge Map route and exact Git-derived T1388 conditional-do source with the complete authored transaction_port_bindings row from canonical T1243 meanings. No old source/diagnostic main or startup control was replayed. observe.py preserves the actual programme, input/revision/hash, clocks/owned PID/session, products and trace; default saved checks do not launch queries. verify.py proves complete finite case closure and exact original fixture selection; genuine omitted/extra/covaried-fixture and wrong status/type/clock/recipe/settlement/covaried-product controls refuse. authority-disposition.json pins original failures, retains the missing defaults schedule slot and invalid diagnostic-parent outcome, and identifies original provider telemetry unavailable through current exec/session APIs without claiming global host-log absence. Original causes stay open in SEM .93/ISF-REDUCTION .16; their before-publication observed-query and explicit-disposition portion is met. normal-query-intake-focused.json retains saved/current Knowledge Map/locality checks, all status0. Book explains the separate claims and saved-only replay. Native book/POD/source/index and complete staged/normal gates are required before commit. No producer/API/DSL/corpus/MCP behavior change, historical causal repair, raw-root/full-environment or latency-distribution claim.`
  Commit: `PUBLICATION-REGRESSION-REPAIRS.7: qualify normal publication query observations`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `PUBLICATION-REGRESSION-REPAIRS.5` | `pending` | After .4 commits clean, durably route the already-completed GH cache migration before full CI/push. |

## Decisions

- `2026-10-25`: Separate each causal regression repair; existing production contracts determine assertions. SEM .69.3 owns publication ordering; macOS history does not impose a renewed blanket hold.
- `2026-10-25`: Full2 was an administratively interrupted failing census, with no T1436 or complete-suite outcome. Qualifying full3 must set FSMGEN_T296_CHECKPOINT before launch.

## Blockers

- No external blocker for .5 after .4 commits. Full CI/push/hosted qualification remain pending, not successful.

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
