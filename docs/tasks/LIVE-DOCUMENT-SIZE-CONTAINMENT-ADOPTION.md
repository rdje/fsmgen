# LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION: Bound Every Live Document Family

## Metadata

- Tree ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/continuity / project-wide live-document lifecycle`
- Created: `2026-07-31`
- Last updated: `2026-07-31`
- Owner: repo-local workflow
- Selected by: `README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.2`

## Goal

Implement the project-wide live-document size-containment doctrine: every live
view remains bounded, every retained history stays addressable and provably
retrievable, every collection has aggregate as well as per-part controls, and
no routed destination becomes the next uninstrumented blob.

## Non-Goals

- Do not apply one universal document size or one storage topology to every
  lifecycle.
- Do not move unique user-facing reference material out of the mdBook merely to
  reduce working-tree bytes.
- Do not remove live historical bytes until their canonical duplicate or exact
  archive retrieval has been proved.
- Do not change compiler, runtime, HDL, VIAL, or other product behavior.
- Do not pre-empt the frozen status-file lifecycle review owned by
  `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`.

## Acceptance Criteria

- A data-only registry and one unconditional checker enforce lifecycle class,
  relative/same-volume location, line/byte/file/aggregate budgets,
  warning/rollover/hard milestones, route closure, projection freshness,
  immutable seals, and archive retrieval.
- The high-water and structural outliers recorded in
  `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md` migrate through atomic,
  lossless, independently committed leaves.
- Bounded user-facing views and examples remain accurate in the mdBook.
- Frozen legacy records remain byte-identical unless their existing lifecycle
  owner first selects a replacement.
- All focused fail-closed probes, documentation truth, mdBook, task-tree,
  Knowledge Map, and doctrine gates pass after every leaf.
- Every completed leaf commits through `COMMIT.md`; no leaf raises a legacy
  ceiling to avoid its selected transition.

## Task Tree

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`
  Status: `active`
  Goal: `Bound all live document families over durable, addressable storage.`
  Children: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.12, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.18, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.19, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.20, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1`
  Status: `done`
  Goal: `Activate common enforcement implementation from a clean selection commit.`
  Acceptance: `Only task/index/roadmap/book/fact/Memory/changelog continuity changes; .2 becomes the sole active implementation leaf; no registry, checker, threshold, topology, content, frozen file, or product behavior changes.`
  Verification: `Clean selection commit 139efbf90 activates only the common enforcement implementation frontier. .2 alone becomes active; no registry, checker, test, threshold, topology, document-family content, frozen file, or product behavior changes. All 37 mdBook chapters test and the repository-local 73-file/17,096,423-byte build passes and is removed exactly; Knowledge Map passes at 1,094 facts/5,702 keys; task-tree integrity passes at trees=3/nodes=881; relative paths pass Files=1/Tests=2; Memory is 34 lines; all 15 existing route controls, diff hygiene, and all eight staged doctrine checks pass with docs-only task acceptance.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1: activate common enforcement`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2`
  Status: `done`
  Goal: `Implement the project JSONL data registry and neutral lifecycle checker contract.`
  Acceptance: `Named JSONL records inventory every governed surface without positional sentinels; one unconditional checker rejects malformed/unknown schema and enforces classes, routes, relative/same-volume paths, complete tracked-Markdown coverage, independent budgets and 80/90/100 state, non-worsening exact-baseline transition debt, owned warning debt, frozen/sealed identities, generated freshness, and archive descriptors; positive and fail-closed fixtures cover every class; README remains a first-class GitHub landing interface; existing family topology and limits do not change.`
  Verification: `JSONL surface/route/archive registries and the neutral checker package enforce all 20 local surfaces, 80/90/100 pressure state, immutable baselines plus finite owned transition growth, project-relative same-volume non-symlink targets, complete tracked-Markdown coverage, indexes, route closure/cycles, generated/query/archive/external/frozen terminals, SHA/count/digest archive retrieval, and strict malformed/missing/unknown schema rejection. Focused t1553+t1554 pass at Files=2/Tests=15; docs truth passes Files=4/Tests=310 under the RAM guard; relative-path/locality tests pass Files=2/Tests=22; all 37 mdBook chapters test and the 73-file/17,103,035-byte repository-local build passes then is removed exactly; Knowledge Map passes at 1,094 facts/5,706 keys; task integrity reports trees=3/nodes=882; README remains 246 lines/9,952 bytes; the final staged census covers 2,773/2,773 Markdown paths and all nine doctrines pass. Existing family topology, hard limits, frozen identities, product behavior, and README landing content remain unchanged.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2: enforce live-document containment`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3`
  Status: `pending`
  Goal: `Consume the four-file lifecycle review and prove the selected rolling-ledger, sealed-segment, and archive-descriptor schema for any retained live ledgers.`
  Acceptance: `Blocked until PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 selects each file's role; the resulting schema partitions retained ledgers only at whole-entry boundaries, preserves order and identity, uses bounded current/index views, records range/revision/line/byte/digest/retrieval metadata, proves exact reconstruction, defines aggregate archive transition, and introduces no CHANGES or DEVELOPMENT_NOTES migration yet.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4`
  Status: `pending`
  Goal: `Migrate CHANGES.md to the bounded rolling-ledger topology.`
  Acceptance: `Execute only the lifecycle selected by PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 and schema proved by .3; if retained as a ledger, every historical entry is accounted for exactly once, the root current/index view is below its derived warning budget, sealed ranges and version-archive descriptors pass order/digest/retrieval proofs, and the selected append/user-facing workflow remains accurate.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5`
  Status: `pending`
  Goal: `Migrate DEVELOPMENT_NOTES.md to the bounded rationale-ledger topology.`
  Acceptance: `Execute only the lifecycle selected by PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 and schema proved by .3; if retained as a ledger, whole rationale entries retain order and identity, the root current/index view is below its derived warning budget, sealed ranges and archive descriptors pass exact proofs, decision/fact/task routing remains canonical, and no automatic placeholder growth is introduced.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6`
  Status: `done`
  Goal: `Extend the task-tree schema and checker for sealed subtree segments and compact completed terminals.`
  Acceptance: `The live root retains metadata plus active ancestor/frontier; bounded manifests address immutable node segments; IDs, parent/child closure, status, verification, and commit evidence validate across files; compact completed terminals require exact revision retrieval proofs; existing trees are not migrated in this contract leaf.`
  Verification: `Decision 0042 extends the live task node graph with an optional bounded JSONL segment manifest, content-addressed exact-source terminal subtree files, and exact version-object compact terminals. The registry independently caps its records/bytes, each segment's nodes/lines/bytes, and aggregate segment nodes/lines/bytes. The checker validates locality/non-symlink/same-volume paths, digests, disjoint complete source subtrees, cross-file identity/ancestry/child/status/evidence closure, and compact retrieval/digest/goal/count/terminal/evidence reconstruction. Existing one-file trees remain compatible and the live result is trees=3/nodes=882/segments=0/compact_terminals=0. Both changed Perl files compile; focused t1549 passes Files=1/Tests=27 and the combined task/README/live-size cluster passes Files=3/Tests=42; relative-path/locality passes Files=2/Tests=22; all 37 mdBook chapters test and the repository-local 73-file/17,108,469-byte build passes then is removed; Knowledge Map passes at 1,095 facts/5,714 keys; Memory is 35 lines; the live-document gate covers 20 surfaces and the final staged Markdown inventory. Its first draft rejected docs/TASK_TREE.md at 93.5%; detailed examples moved to the setup guide and the unchanged state/limit now passes at 1,078 lines/89.8%. The RAM guard stopped the broader four-file documentation group before execution on three attempts at 88.6%, 89.0%, and 95.0% host usage versus the required 88% cutoff; no failing test ran. Final staged acceptance and all nine doctrine checks pass. No existing task tree, hard limit, frozen identity, README landing content, compiler/runtime/generated output, or product behavior changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6: enforce bounded task-tree history`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7`
  Status: `done`
  Goal: `Migrate the active IAL2 task outlier, completed task outliers, and cross-tree index.`
  Acceptance: `The active IAL2 root/frontier stays immediately readable; all completed nodes remain uniquely addressable through sealed segments or proved archive terminals; done-tree history becomes query-first; docs/TASK_TREE.md is a bounded active/proposed view; exact node/commit/retrieval and PNT selection tests pass.`
  Verification: `Exact source revision 44b5f159789ba1c31b487c6b047097bb27a9770d supplies all 844 terminal IAL2 child nodes to one 5,914-line/2,366,453-byte SHA-256-named segment; its finite manifest is 35,252 bytes under a derived 40,960-byte bound and exact-caps segment/aggregate nodes, lines, and bytes. The live IAL2 file retains the active root and becomes 85 lines/36,886 bytes. The cross-tree index retains three active and eleven proposed rows and becomes 558 lines/39,851 bytes; a finite 523-byte manifest proves the former 1,078-line/167,249-byte index and its 540 unique terminal rows, exact-revision task paths, digest, dimensions, and live PNT purity. Completed task files remain direct. Task integrity reconstructs three trees/882 nodes/one segment/zero compact terminals/one index archive; focused t1549 passes Files=1/Tests=34 and combined task/README/live-size proof passes Files=3/Tests=49. Both registered task surfaces return from warning debt to normal without a limit increase. Final path/locality, mdBook, Knowledge Map, Memory, staged acceptance, nine-doctrine, and cleanup evidence is recorded below. No frozen identity, README landing content, compiler/runtime/generated output, or product behavior changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7: bound task evidence and index`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8`
  Status: `pending`
  Goal: `Partition the Chapter 14 feature backlog by stable user-facing topic.`
  Acceptance: `All existing user-facing material remains in navigable mdBook chapters exactly once; SUMMARY and reference links are complete; every part and aggregate fall below derived warning budgets; examples and all book gates pass.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9`
  Status: `pending`
  Goal: `Separate the bounded live roadmap from shipped chronology.`
  Acceptance: `ROADMAP_V2.md retains current/future direction and concise milestone outcomes; every removed historical claim is proved duplicate in maintained book/task/decision homes or covered by an exact archive descriptor; links and roadmap/task alignment pass; the retained roadmap falls below derived warning budgets.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10`
  Status: `pending`
  Goal: `Bound canonical knowledge cards, shard the generated Knowledge Map, and add query-first discovery.`
  Acceptance: `Oversized cards split only on stable fact boundaries without duplicating or losing answers; cards remain canonical; a small root projection plus deterministic prefix/topic shards cover every fact/key exactly once; freshness, per-card, per-shard, aggregate, and query-result parity tests pass; disposable query caches remain repository-local under .artifacts/.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11`
  Status: `pending`
  Goal: `Consume the separately owned frozen status-file lifecycle decision if it selects migration.`
  Acceptance: `Blocked until PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 completes; if that decision retains freezing, record no-op closure; if it selects migration, execute only its declared audience/topology with pre/post identity and retrieval proof.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.12`
  Status: `pending`
  Goal: `Re-audit the steady state and replace legacy ceilings with derived retained-surface budgets.`
  Acceptance: `Every registered surface is remeasured; all live roots and parts are below warning; aggregate transitions and retrieval/reconstruction probes pass; temporary legacy headroom is reduced through a reviewed local registry update; doctrine/book/fact/task/roadmap/Memory agree; no artifact residue remains.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.18, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.19, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.20, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13`
  Status: `pending`
  Goal: `Classify and bound focused root-level and ancillary Markdown collections.`
  Acceptance: `Every docs/*.md and ancillary Markdown surface has an audience/lifecycle owner and bounded complete index; the current 6,254-line focused outlier and any other semantic outliers are partitioned only at stable topic boundaries; unique maintained content remains in an appropriate browsable home; per-part/file-count/aggregate/freshness/link checks pass below warning without changing product behavior.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14`
  Status: `done`
  Goal: `Publish a self-contained external review packet for the live-document containment and JSONL architecture.`
  Acceptance: `A tracked Markdown packet explains the problem, goals, terminology, topology, utility-before-containment and retirement outcomes, JSONL-versus-TSV decision, schemas, lifecycle classes, pressure model, route closure, task-tree sealing, exact retrieval, migration evidence, tests, failure modes, limits, portability boundary, and open design questions in sufficient detail for another project to review without reading FSMGen source; it illustrates retain/merge/supersede/archive/delete analysis with measured FSMGen candidates, provides a structured response template, tracks discovered gaps without silently fixing them, and changes no enforcement or product behavior.`
  Verification: `The tracked 1,309-line/54,068-byte packet is self-contained and separates neutral architecture, FSMGen evidence, JSONL schemas, lifecycle/pressure/retrieval mechanics, exact task migration, limitations, portability, 31 questions, and a pasteable response template. It makes utility precede size and illustrates retain/merge/supersede/archive/delete with measured FSMGen candidates without deleting a file. Source inspection confirms the specialized task manifests self-cap while the common surface/route/archive registries do not, and confirms hard_pct is ordering-only while absolute overflow is actual > budget; pending .15 owns those gaps and .16 owns the utility audit. Focused doctrine/route/task tests pass Files=3/Tests=49; path/locality passes Files=2/Tests=22; live coverage is 20 surfaces and 2,777/2,777 paths; Knowledge Map passes at 1,095 facts/5,722 keys; all 37 mdBook chapters test and the repository-local 73-file/17,116,666-byte build passes then is removed; final staged doctrines and cleanup are recorded below. No schema, checker, threshold, archive, README landing content, frozen content, product behavior, or existing document lifecycle changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14: publish external review packet`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15`
  Status: `pending`
  Goal: `Make the common JSONL control plane finite, reviewable, and schema-constrained.`
  Acceptance: `The surface, route, and common archive-descriptor registries declare and enforce finite record/byte/maximum-record controls; scalar bytes, identifier domains, and array cardinalities prevent prose or identity-list displacement; Markdown surfaces gain a deterministic maximum-line-byte dimension where applicable; strict parser semantics and the portable negative fixture corpus remain the executable schema; neutrality remains mechanically tested; no threshold is widened.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16`
  Status: `pending`
  Goal: `Make current utility and deliberate retirement precede size migration.`
  Acceptance: `Define reviewable retain/merge/supersede/archive/delete/re-form outcomes and require one before migration; audit each governed FSMGen document family for current audience, canonical role, unique value, duplication, staleness, consumers, and historical retention; explicitly assess USER_GUIDE.md, the two frozen status files, CHANGES.md, DEVELOPMENT_NOTES.md, ROADMAP_V2.md, generated KNOWLEDGE_MAP.md, ISF_SPEC.md, and focused readiness/contract collections; define role/canonical-input/replacement/consumer-change triggers; require fresh token/ID, classified-consumer, replacement-pointer, and negative-control proof before deletion; assign separate atomic migrations and delete nothing in this audit leaf.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`
  Status: `done`
  Goal: `Reconcile the returned PGEN and ANVIL reviews against current FSMGen evidence and decompose every accepted correction before implementation.`
  Acceptance: `A tracked disposition records every reviewer finding and question as accept, refine, reject, or already satisfied with exact local evidence; it distinguishes misleading migration accounting from actual information loss, publishes measured retained/migrated/pinned pressure, selects portable semantics for targets versus ceilings, verifier execution, currency, retrieval retention, route roles, reviewability, and utility re-form, and assigns each accepted behavior change or retirement to a separate bounded leaf. The reconciliation changes no checker, schema, registry value, document lifecycle, file content under review, frozen identity, README landing content, or product behavior.`
  Verification: `PGEN's 393-line/26,788-byte review and ANVIL's 334-line/44,242-byte review are content-identified by SHA-256 and reconciled in one bounded 333-line/17,165-byte disposition with a 183-byte longest line. Every F1-F8/F1-F9 finding and Q1-Q31 receives accept/refine/reject/already-satisfied treatment plus local evidence and one atomic owner. Decision 0044 distinguishes path coverage from health, explicit health targets from inclusive enforcement ceilings, verifier presence from execution, exact full-source retention from sealed-node closure, and lifecycle-scoped currency from global date heuristics; utility gains re-form. Exact revision 44b5f1597 still retrieves all 21,726 lines/4,662,385 bytes at SHA-256 8cff8e7b..., while the content-addressed segment independently retains all 844 task nodes; the packet's 15,727-line issue is misleading overlap accounting, not demonstrated loss. At clean activation commit 3d83996d6, four pinned/deferred families are 7,775,451/8,955,512 named non-generated candidate bytes (86.8%), while active index/task surfaces are normal at 46.5%/74.0%. Six new leaves plus refined .15/.16 cover pressure, execution, currency, typed route/index/evidence completeness, retention/review view, utility, and maintained reference. All 17 packet evidence paths resolve; t1554 already mechanically proves neutral-package identity. Focused tests pass Files=5/Tests=71; task integrity is trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces cover 2,782/2,782 staged paths; Knowledge Map passes at 1,096 facts/5,741 keys; all 37 mdBook chapters test and the repository-local 73-file/16,984-KiB build passes then is removed. No checker, schema, registry value, threshold, reviewed packet, document lifecycle, frozen identity, README landing content, compiler/runtime artifact, or product behavior changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17: reconcile external containment reviews`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.18`
  Status: `done`
  Goal: `Separate reviewed health targets from inclusive transition enforcement ceilings.`
  Acceptance: `Every measured surface reports actual, health target, and inclusive enforcement ceiling without using one field for both meanings; healthy and debt states have explicit algebra; hard_pct is removed; immutable baseline plus owned allowance cannot exceed the separately authorized ceiling; ceiling increases require a distinct reviewed authority record while reductions are free; a two-sided ratchet rejects overflow and stale excess headroom; migrated versus pinned/deferred pressure is reported; positive, equality, overflow, lowering, stale-ceiling, and unauthorized-increase fixtures pass without raising a current limit.`
  Verification: `The neutral schema now requires separate five-axis health_targets and enforcement_ceilings, removes hard_pct, reports actual/target/ceiling values, and classifies two migrated, nine pinned/deferred, and five steady measured surfaces. Target pressure alone owns 80/90 state; actual equal to the inclusive ceiling passes, overflow fails, and singular 1/1 file count cannot falsely dominate health. Debt proves immutable cross-revision baseline, baseline plus growth <= ceiling, and ceiling <= max(actual,target) + 2*ratchet_step. The local Git-aware authority registry is append-only: an increase needs one exact new authority plus a newly added decision with matching id/surface/dimension/delta; reductions need none, and reused/banked authorities fail. All current ceilings are <= their predecessor budgets, and the staged authority gate reports zero increases. Core/authority Perl syntax is OK; focused Files=3/Tests=20; paths Files=1/Tests=2; task integrity is trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces cover 2,782/2,782 Markdown paths; Knowledge Map is 1,096 facts/5,743 keys; Memory is 42 lines; all 37 mdBook chapters test and the 73-file/16,996-KiB repository-local build passes then is removed; all nine staged doctrines pass. No document lifecycle, frozen identity, README landing content, archive, compiler/runtime artifact, or product behavior changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.18: distinguish health targets from ceilings`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.19`
  Status: `done`
  Goal: `Make verifier execution and doctrine-driver reachability mechanically closed.`
  Acceptance: `Generated freshness and version retrieval declare core, adapter, or external execution; a green result proves execution or prints a fail-closed declared degradation rather than executable presence; every adapter verifier is mechanically reachable through the single unconditional doctrine driver and CI invokes that driver instead of re-enumerating checks; deletion/vacuity and both-direction negative fixtures prove each control observes its intended subject.`
  Verification: `Generated freshness and version-object retrieval now require core:, adapter:, or external: execution. The neutral core forks core programs from the supplied project root with null stdin and rejects missing, non-executable, signaled, or nonzero programs. The registry-driven local runner executes every adapter program before emitting its exact surface/archive proof; missing, duplicate, unused, and declaration-free proofs fail closed. External contracts emit visible degradation and cannot produce green. The wrapper invokes the runner unconditionally, while bootstrap enforcement proves hosted CI invokes scripts/check_doctrines.sh without re-enumerating the live-document check. The real fact-index path executes the Knowledge Map checker. Perl/Bash syntax is clean; focused Files=3/Tests=21 covers success, nonzero, non-executable, adapter execution side effects, exact proof consumption, external degradation, and stale-proof vacuity. Paths pass Files=1/Tests=2; task integrity is trees=3/nodes=896/segments=1/compact=0/index archives=1; Knowledge Map is 1,096 facts/5,745 keys; Memory is 42 lines; all 37 mdBook chapters test and the 73-file/16,996-KiB repository-local build passes then is removed exactly. Final staged acceptance/doctrine evidence is recorded below. No pressure value, ceiling, lifecycle, archive content, frozen identity, README landing content, compiler/runtime artifact, or product behavior changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.19: execute declared verifiers`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.20`
  Status: `pending`
  Goal: `Add lifecycle-scoped currency contracts without a global date heuristic.`
  Acceptance: `The doctrine distinguishes boundedness, currency, and semantic truth; only a surface that declares a currency contract is checked by its calibrated local verifier; frozen and historical records remain correctly exempt; newest-date and distinct-date heuristics are not imposed globally; positive, self-refutation, legitimate-closure-date, frozen-date, and absent-contract fixtures prove low-noise behavior.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21`
  Status: `pending`
  Goal: `Close typed route, collection-index, and evidence-map completeness.`
  Acceptance: `Path-shaped destinations emitted by enforcers are inventoried and classified as author_overflow or reader_navigation; every candidate resolves to a governed surface while legitimate route-kind differences remain explicit; each collection index proves complete target membership or declares a generated/query contract; the packet/disposition evidence maps reject missing paths; checks are unconditional and staged/resulting-tree aware; fail-closed fixtures cover an undeclared hint, wrong route kind, omitted collection member, and missing evidence path.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22`
  Status: `pending`
  Goal: `Make migration completeness, retention guarantees, and review-front-door bounds explicit.`
  Acceptance: `IAL2 migration evidence separately proves exact full-source identity/retrieval, all 844 authoritative task nodes, live working-set dimensions, and any truly omitted-content residue; version_object use declares a retention owner/guarantee and actionable shallow/rewrite failure, while unrecoverable evidence prefers content-addressed repository files; migration records reject false disjoint arithmetic; a bounded architecture/review front door routes the detailed packet to retained evidence under an explicit lifecycle; retrieval, missing-history, mismatch, and loss-residue fixtures fail closed.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23`
  Status: `pending`
  Goal: `Select the lifecycle contract for maintained product-bounded reference prose.`
  Acceptance: `Decide whether a maintained_reference class is distinct from partitioned_canonical; preserve unique user/specification prose whose aggregate grows with the product while bounding mandatory index/read units, per-part reviewability, navigation depth, and contract-authorized aggregate change; record an auditable classification rationale per affected surface; prove the selected rule on mdBook and ISF-spec examples without deleting content or weakening landing-page, ledger, projection, archive, or frozen controls.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

## Decisions

- `2026-07-31`: Use the project-neutral, project-agnostic, harness-neutral
  doctrine selected by decision 0041; keep all FSMGen values in local data.
- `2026-07-31`: Preserve directly browsable user reference in semantic shards,
  but move rarely read exact chronology out of the working set only after
  digest-verified version retrieval exists.
- `2026-07-31`: Treat per-part and aggregate containment as separate
  obligations; sharding cannot be the final answer for an append ledger.
- `2026-07-31`: Keep frozen status lifecycle authority with the existing
  `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` owner.
- `2026-07-31`: Clean decision/doctrine/audit commit `139efbf90` activates `.1`
  continuity only and leaves `.2` as the sole active implementation frontier.
- `2026-07-31`: Use JSONL for the local registry data plane: named objects,
  path/route arrays, typed budget/baseline objects, strict unknown-key failure,
  and line-oriented streaming avoid the 22-column prototype's positional
  ambiguity without making serialization part of the neutral doctrine.
- `2026-07-31`: Keep adoption baselines immutable. Any program-required
  continuity growth uses a separately owned finite `transition.max_growth`
  object; ownerless or excess growth fails rather than refreshing the baseline.
- `2026-07-31`: Treat `README.md` as the rendered GitHub landing interface as
  well as a bounded route source; containment preserves its direct purpose,
  quick start, architecture summary, and navigation.
- `2026-07-31`: The complete 2,772-path inventory adds `.13` for focused and
  ancillary collections and widens `.10` to own oversized canonical knowledge
  cards as well as the generated map.
- `2026-07-31`: Decision 0042 keeps every nonterminal ancestor/frontier live,
  seals only complete terminal subtrees through finite JSONL manifests and
  content-addressed exact-source Markdown, and permits compact terminals only
  with exact version-object digest/count/closure/evidence reconstruction.
  Manifest, per-segment, and aggregate node/line/byte limits independently
  prevent the segment destination from becoming a new unbounded sink.
- `2026-07-31`: The first detailed schema draft pushed `docs/TASK_TREE.md` to
  93.5% of its line budget. The live-document gate rejected it; moving full
  examples to `docs/TASK_TREE_README.md` returns the index to 89.8% without a
  limit/state change. `.7` remains the immediate index-migration owner.
- `2026-07-31`: `.7` seals the 844 terminal IAL2 children from exact revision
  `44b5f159789ba1c31b487c6b047097bb27a9770d`, retains an 85-line live root,
  and converts 540 unique terminal index rows into bounded query-first history.
  The live index is 558 lines with three active and eleven proposed rows; all
  completed task files remain directly browsable.
- `2026-07-31`: `.14` review found that specialized task manifests are bounded
  but the common surface/route/archive JSONL control plane is not yet capped,
  and that `hard_pct` is validated but not executed. `.15` owns both gaps.
- `2026-07-31`: Document size does not prove current utility. `.14` adds
  retain/merge/supersede/archive/delete analysis with measured FSMGen examples;
  `.16` owns the project-wide utility and retirement audit before final limits.
- `2026-07-31`: Returned PGEN and ANVIL reviews are inputs, not self-executing
  requirements. `.17` first reconciles every finding against exact local
  evidence and creates bounded remediation leaves; `.15` and `.16` wait for
  that disposition so implementation cannot silently mix review concerns.
- `2026-07-31`: Decision 0044 accepts both reviews with local refinements:
  distinguish coverage/health, target/ceiling, presence/execution, full-source/
  node-retention, and boundedness/currency; reject a portable global date
  heuristic; add utility `re-form`; decompose corrections through `.15`-`.23`.
- `2026-07-31`: `.17` proves the apparent 15,727-line IAL2 gap is misleading
  overlap accounting rather than demonstrated loss, reports 86.8% pinned/
  deferred candidate bytes, and routes every accepted correction to `.15`-`.23`.
- `2026-07-31`: Clean disposition commit `3b782fc10` activates `.18` alone for
  health-target, inclusive-ceiling, ratchet, increase-authority, and pressure-
  reporting semantics; activation changes no schema, value, limit, or behavior.
- `2026-07-31`: `.19` gives generated freshness and version-object retrieval
  three explicit modes: neutral-core execution, local-adapter execution with an
  exact one-use proof, or visible fail-closed external degradation. The local
  wrapper derives all adapters from the registries and remains reachable only
  through the unconditional doctrine driver used by hosted CI.

## Open Questions

- None for completed `.18` or `.19`. The earlier two reviews are reconciled in
  the bounded disposition. Newly supplied PGEN/ANVIL follow-up reviews will be
  read and dispositioned from the clean `.19` commit before the next activation;
  the existing four-file review retains authority for its named semantic roles.

## Blockers

- `.3`-`.5` and `.11`: `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` must first
  select the four files' long-term roles. `.1`, `.2`, `.6`-`.10`, and `.12`
  remain independently schedulable subject to their ordinary predecessor
  dependencies. `.17` is complete; `.15`-`.23` become selectable after its
  clean commit, and `.8`-`.10`/`.13` wait for their declared utility or
  maintained-reference predecessors.

## Acceptance Checklist (enforced) — `.19`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'freshness:' --oneline -- live-document-size/scripts/check_live_document_size.pl` identifies `18e2dcbc6`; source inspection shows the original generated and version-object paths accepted only an executable pathname, so a never-run, failing program could still support a green result and no declaration-derived adapter proof closed CI reachability.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t` reports `All tests successful` at `Files=3, Tests=21`; side-effect probes prove core freshness, core version retrieval, and wrapper-delegated adapter execution, while nonzero, missing/non-executable, missing-proof, unused-proof, external-degradation, and exact-proof fixtures fail or pass in the intended direction.
- [x] **NO REGRESSION** — staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`; the real Knowledge Map core verifier executes, all 20 live-document surfaces and complete Markdown inventory remain covered, task/README/locality/Memory contracts stay green, and the mdBook tests/build pass with repository-local output removed exactly.

## Acceptance Checklist (enforced) — `.18`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'hard_pct' --oneline -- live-document-size/scripts/check_live_document_size.pl` identifies `18e2dcbc6`; source inspection then shows that the introduced `budgets` object simultaneously described healthy pressure and the hard stop, while `hard_pct` was validated but never used for rejection and mutable registry edits could widen debt headroom.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t` changes that result to explicit target/ceiling output plus passing equality, overflow, lowering, stale-ratchet, immutable-baseline, exact fresh-authority, reused-authority, and orphan-authority controls (`Files=3, Tests=20`).
- [x] **NO REGRESSION** — staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`; every 20-surface/2,782-path rule, the 1,096-fact/5,743-key Knowledge Map, three-tree/896-node task graph, README landing contract, locality, and 42-line Memory remain green.

## Acceptance Checklist (enforced) — `.7`

- [x] **ROOT CAUSE — WHY + WHERE (current `.7` slice)** — `git log -S'## Completed Task Trees'
  --oneline -- docs/TASK_TREE.md` identifies `9dc0965fa` as the append-table
  introduction. Exact activation revision `44b5f1597` measures 540 unique
  terminal index rows, a 1,078-line/167,249-byte live index, and an IAL2 task
  file at 21,726 lines/4,662,385 bytes even though only its root remains
  nonterminal. The mandatory working set therefore grew with terminal history,
  not current PNT state.
- [x] **ADDRESSED / VERIFIED (current `.7` slice)** — `scripts/check_task_tree_integrity.pl`
  reconstructs `trees=3, nodes=882, segments=1, compact_terminals=0,
  index_archives=1`. All 844 exact-source terminal children match the named
  content digest and exact node/line/byte caps. The exact-index archive proves
  540 unique terminal rows and revision-local task files while the live view
  holds only three active and eleven proposed rows. Both Perl files report
  `syntax OK`; focused t1549 reports `All tests successful` at `Files=1,
  Tests=34`, including schema/bound/nonempty, digest, exact-task retrieval, and PNT-view negative
  fixtures.
- [x] **NO REGRESSION / BROADER PROOF (current `.7` slice)** — the combined task/
  README/live-size cluster reports `All tests successful` at `Files=3,
  Tests=49`; both registered task surfaces pass as `normal`, with the index at
  46.5% and task evidence at 74.0%. Path/locality passes `Files=2, Tests=22`;
  all 37 mdBook chapters test and the repository-local 73-file/17,110,777-byte
  build passes then is removed exactly; Knowledge Map validates 1,095 facts/
  5,717 keys and Memory is 36 lines. The RAM guard stopped the broader four-file
  documentation group before test output at 89.6% host use versus its required
  88% cutoff; no failing test ran and the guard was not weakened. Final staged
  task acceptance, diff hygiene, and all nine doctrines pass as recorded below.
  No task ID/file, limit, frozen identity, README landing content, compiler/
  runtime/generated output, or product behavior is removed or changed.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-07-31` | `.1` activation | clean `139efbf90` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; path/mdBook/Knowledge Map/task/Memory/route/diff/staged-doctrine gates; exact cleanup | `passed`; paths Files=1/Tests=2; 37 chapters; build 73 files/17,096,423 bytes; Knowledge Map 1,094 facts/5,702 keys; trees=3/nodes=881; Memory 34 lines; all eight staged doctrines pass with docs-only task acceptance; `.2` alone active; no implementation, threshold, topology, document-family content, frozen-file, or product change |
| `2026-07-31` | `.2` common enforcement | neutral JSONL contract/core; 20-surface local registry; strict lifecycle/debt/route/archive/coverage/neutrality fixtures; README compatibility; docs/path/locality/mdBook/Knowledge Map/task/Memory/diff/staged-acceptance/nine-doctrine gates; exact cleanup | `passed`; focused Files=2/Tests=15; docs Files=4/Tests=310; paths/locality Files=2/Tests=22; 37 chapters; build 73 files/17,103,035 bytes; Knowledge Map 1,094 facts/5,706 keys; trees=3/nodes=882; final staged coverage 2,773/2,773; README 246 lines/9,952 bytes; all nine doctrines pass; no migration, hard-limit, frozen-file, landing-content, or product change |
| `2026-07-31` | `.6` activation | clean `18e2dcbc6` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; path/task/Knowledge Map/Memory/live-document/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; paths/task Files=2/Tests=13; 37 chapters; build 73 files/17,104,418 bytes; Knowledge Map 1,094 facts/5,706 keys; trees=3/nodes=882; Memory 36 lines; live-document census 20 surfaces and 2,773/2,773 paths; `.6` alone active; no schema, checker, tree migration, threshold, frozen-file, landing-content, or product change |
| `2026-07-31` | `.6` bounded task history | decision 0042; optional finite manifest and exact-source sealed-segment schema; exact version-object compact terminal; legacy/positive/fail-closed Git fixtures; task/route/live-size/path/locality/mdBook/Knowledge Map/Memory/diff/staged-acceptance/nine-doctrine gates; exact cleanup | `passed`; syntax OK; focused Files=1/Tests=27; combined Files=3/Tests=42; paths/locality Files=2/Tests=22; 37 chapters; build 73 files/17,108,469 bytes; Knowledge Map 1,095 facts/5,714 keys; live graph trees=3/nodes=882/segments=0/compact_terminals=0; index draft rejected at 93.5%, corrected to 1,078 lines/89.8%; broad docs group safely stopped pre-execution by 88% RAM guard at 88.6%/89.0%/95.0% with no failing test; all nine staged doctrines pass; no migration, limit/state widening, frozen-file, landing-content, or product change |
| `2026-07-31` | `.7` activation | clean `78adb81ae` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; path/task/Knowledge Map/Memory/live-document/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; paths Files=1/Tests=2; all 37 chapters test; build 73 files/17,110,023 bytes; Knowledge Map 1,095 facts/5,714 keys; trees=3/nodes=882/segments=0/compact terminals=0; Memory 35 lines; live-document census 20 surfaces and 2,775/2,775 paths; `.7` alone active; no node/index migration, schema/checker, threshold, frozen-file, landing-content, or product change |
| `2026-07-31` | `.7` bounded task evidence/index | exact IAL2 source segment; finite exact-index manifest; active/proposed PNT view; syntax/focused/combined/path/locality/mdBook/Knowledge Map/Memory/live-size/diff/staged-acceptance/nine-doctrine gates; exact cleanup | `passed`; 844 sealed nodes; 540 unique terminal rows; index 558 lines/39,851 bytes; live IAL2 85/36,886; segment 5,914/2,366,453; task integrity trees=3/nodes=882/segments=1/compact=0/index archives=1; focused Files=1/Tests=34; combined Files=3/Tests=49; paths/locality Files=2/Tests=22; 37 chapters; removed build 73 files/17,110,777 bytes; Knowledge Map 1,095 facts/5,717 keys; Memory 36 lines; 20 surfaces and 2,776/2,776 paths; all nine staged doctrines pass; broad docs group stopped safely pre-output by RAM guard at 89.6% versus 88% |
| `2026-07-31` | `.14` activation | clean `7f05b41de` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; path/task/Knowledge Map/live-size/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; paths/task Files=2/Tests=36; trees=3/nodes=883/segments=1/compact=0/index archives=1; Knowledge Map 1,095 facts/5,717 keys; 20 surfaces and 2,776/2,776 paths; all 37 chapters test; removed build 73 files/17,111,406 bytes; Memory 36 lines; `.14` alone active; no review packet, schema, checker, threshold, archive, README landing-content, or product change |
| `2026-07-31` | `.14` external review packet | tracked self-contained packet; neutral/local boundary; utility outcomes and measured examples; source-backed JSONL/threshold limitations; focused/path/locality/live-size/Knowledge Map/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; packet 1,309 lines/54,068 bytes and 31 questions; focused Files=3/Tests=49; paths/locality Files=2/Tests=22; 20 surfaces and 2,777/2,777 paths; Knowledge Map 1,095 facts/5,722 keys; all 37 chapters test; removed build 73 files/17,116,666 bytes; trees=3/nodes=885/segments=1/compact=0/index archives=1; Memory 36 lines; all nine staged doctrines pass; `.15`/`.16` tracked; no implementation, threshold, archive, deletion, frozen-content, landing-content, or product change |

| `2026-07-31` | `.17` activation | clean `c95160d53` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; focused path/locality/task/live-size, Knowledge Map, Memory, mdBook, diff, staged-doctrine gates; exact cleanup | `passed`; focused Files=4/Tests=65; trees=3/nodes=890/segments=1/compact=0/index archives=1; 20 surfaces and 2,780/2,780 paths; all 37 mdBook chapters test; repository-local build 16,976 KiB and removed exactly; Memory 42 lines; `.17` alone active and `.15`/`.16` wait for its disposition; no disposition file, checker, schema, registry value, threshold, reviewed content, frozen identity, landing content, or product change |
| `2026-07-31` | `.17` external review disposition | 17 findings plus Q1-Q31; review/source identity; IAL2 overlap root cause; pressure census; decision 0044; leaves `.15`-`.23`; evidence-map/neutrality source inspection; focused/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; disposition 333 lines/17,165 bytes/183-byte longest line; PGEN 393/26,788 and ANVIL 334/44,242 review identities; exact IAL2 source 21,726/4,662,385 at SHA-256 8cff8e7b... plus 844-node segment; pinned/deferred candidates 7,775,451/8,955,512 bytes (86.8%); focused Files=5/Tests=71; trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces and 2,782/2,782 staged paths; Knowledge Map 1,096 facts/5,741 keys; 37 chapters; removed 73-file/16,984-KiB build; all 17 evidence paths resolve; no enforcement, registry value, threshold, packet content, lifecycle, frozen identity, landing content, or product change |
| `2026-07-31` | `.18` activation | clean `3b782fc10` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; focused path/task/live-size, Knowledge Map, Memory, mdBook, diff, staged-doctrine gates; exact cleanup | `passed`; focused Files=3/Tests=45; trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces and 2,782/2,782 paths; Knowledge Map 1,096 facts/5,741 keys; all 37 chapters test; removed 73-file/16,984-KiB build; Memory 43 lines; `.18` alone active; no checker, test, schema/value/limit, document lifecycle/content, frozen identity, landing content, or product change |
| `2026-07-31` | `.18` target/ceiling enforcement | explicit target/ceiling schema; inclusive equality; debt ratchet; append-only fresh decision authority; migrated/pinned/steady report; syntax/focused/path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; no predecessor ceiling increase; focused Files=3/Tests=20; paths Files=1/Tests=2; trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces and 2,782/2,782 paths; Knowledge Map 1,096 facts/5,743 keys; Memory 42 lines; 37 chapters; removed 73-file/16,996-KiB build; all nine doctrines pass; no lifecycle, frozen identity, landing content, archive, or product behavior change |
| `2026-07-31` | `.19` activation | clean `9bd081935` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; Files=2/Tests=36; trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces and 2,782/2,782 paths; Knowledge Map 1,096 facts/5,743 keys; Memory 43 lines; all 37 chapters test; removed 73-file/16,996-KiB build; `.19` alone active; no checker, schema, verifier, lifecycle, archive, or product behavior change |
| `2026-07-31` | `.19` verifier execution | core/adapter/external modes; registry-derived adapter runner; exact one-use proofs; CI/driver reachability; syntax/focused/path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-acceptance/doctrine gates; exact cleanup | `passed`; focused Files=3/Tests=21; paths Files=1/Tests=2; trees=3/nodes=896/segments=1/compact=0/index archives=1; Knowledge Map 1,096 facts/5,745 keys; Memory 42 lines; real fact-index verifier executes; all 37 chapters test; removed 73-file/16,996-KiB build; no pressure value, lifecycle, archive content, frozen identity, landing content, or product behavior change |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1: activate common enforcement` | Activate `.2` from the clean doctrine-selection commit without implementing it. |
| `.2` common enforcement | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2: enforce live-document containment` | Ship neutral JSONL checker contract/core plus FSMGen data and unconditional ninth-doctrine coverage; next clean selection is `.6`. |
| `.6` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6: activate task-tree schema contract` | Activate only the sealed-segment/compact-terminal schema frontier from clean commit `18e2dcbc6`; implementation remains pending. |
| `.6` bounded task history | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6: enforce bounded task-tree history` | Ship decision 0042's optional bounded exact-provenance storage forms and checker proofs without migrating an existing tree; `.7` is next. |
| `.7` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7: activate task-tree migration` | Activate only the first IAL2/task/index migration from clean commit `78adb81ae`; migration remains pending. |
| `.7` bounded task evidence/index | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7: bound task evidence and index` | Seal 844 exact-source IAL2 children and 540 unique terminal index rows while keeping current PNT and completed task files direct. |
| `.14` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14: activate external review packet` | Activate only the tracked external-review-packet leaf from clean commit `7f05b41de`; the packet remains pending. |
| `.14` external review packet | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14: publish external review packet` | Publish the self-contained review and response template; track control-plane/hard semantics in `.15` and utility/retirement in `.16`. |

| `.17` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17: activate external review reconciliation` | Activate only evidence-backed PGEN/ANVIL disposition from clean commit `c95160d53`; implementation and the disposition document remain pending. |
| `.17` external review disposition | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17: reconcile external containment reviews` | Publish decision 0044, corrected evidence, all finding/question dispositions, and atomic `.15`-`.23` remediation ownership without changing behavior. |
| `.18` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.18: activate health-target and ceiling semantics` | Activate only target/ceiling/ratchet/increase-authority implementation from clean disposition commit `3b782fc10`; implementation remains pending. |
| `.18` target/ceiling enforcement | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.18: distinguish health targets from ceilings` | Separate health from quarantine, ratchet debt downward, and require fresh reviewed authority for widening without raising a predecessor ceiling. |
| `.19` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.19: activate verifier execution closure` | Activate only executed-verifier and unconditional-driver-reachability implementation from clean `.18` commit `9bd081935`; implementation remains pending. |
| `.19` verifier execution | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.19: execute declared verifiers` | Execute core and delegated adapter programs, consume exact one-use proofs, fail closed on external contracts, and prove the wrapper remains on the single CI doctrine path. |

## Changelog

- `2026-07-31`: Clean selection commit `139efbf90` activates `.1` continuity;
  `.2` becomes the sole active common-registry/checker implementation leaf.
- `2026-07-31`: `.2` ships strict JSONL common enforcement over 20 surfaces
  and the complete tracked-Markdown inventory while preserving README's
  landing content, all existing hard limits/topologies, frozen identities, and
  product behavior; `.6` is the next clean selection frontier.
- `2026-07-31`: Clean commit `18e2dcbc6` activates `.6` alone to extend the
  task-tree schema and checker; no schema, checker, tree topology, threshold,
  document-family content, frozen identity, or product behavior changes in
  the activation commit.
- `2026-07-31`: Clean bounded-history commit `78adb81ae` activates `.7` alone;
  no task node, task index row, storage manifest, threshold, frozen identity,
  README landing content, or product behavior changes in this activation.
- `2026-07-31`: `.6` ships bounded manifest/segment/compact-terminal support,
  exact Git-backed retrieval proofs, and 27 focused subtests while leaving all
  existing trees unmigrated; `.7` is the next clean selection frontier.
- `2026-07-31`: `.7` applies the contract without deleting or renaming a node:
  844 IAL2 children reconstruct from one content-addressed segment, 540 unique
  terminal index rows become exact-version query history, and the live index
  retains only three active plus eleven proposed rows. Both task surfaces are
  normal; `.8` is the next clean selection frontier.
- `2026-07-31`: User-directed clean pivot from `7f05b41de` activates `.14`
  alone to publish the external review packet; the activation creates no packet
  and changes no enforcement, threshold, archive, landing content, or product.
- `2026-07-31`: `.14` publishes the 31-question external review packet, makes
  utility precede size containment, illustrates deliberate retirement with
  measured FSMGen candidates, and tracks the common JSONL/hard-threshold gaps
  in `.15` plus the general utility audit in `.16` without changing behavior.
- `2026-07-31`: Clean VIAL parity commit `c95160d53` activates `.17` alone to
  reconcile the returned PGEN and ANVIL reviews against exact local evidence;
  `.15` and `.16` wait for its disposition, and activation changes no behavior.
- `2026-07-31`: `.17` publishes the bounded disposition and decision 0044,
  proves the IAL2 gap was overlapping-retention accounting rather than
  demonstrated loss, reports residual pressure, and decomposes `.15`-`.23`.
- `2026-07-31`: Clean disposition commit `3b782fc10` activates `.18` alone;
  no checker, schema, registry value, limit, document, or product changes in
  the activation.
- `2026-07-31`: `.18` replaces ambiguous budgets/inert `hard_pct` with explicit
  health targets and inclusive ceilings, immutable debt baselines, banded
  ratchets, and exact fresh increase authority. No predecessor ceiling rises;
  `.19` is the next clean activation frontier.
- `2026-07-31`: Clean `.18` commit `9bd081935` activates `.19` alone for
  verifier execution, driver reachability, and vacuity controls; activation
  changes no checker, schema, verifier, document lifecycle, or product behavior.
- `2026-07-31`: `.19` executes core freshness/retrieval programs, derives exact
  adapter proofs only after registry-driven execution, rejects stale proofs and
  external degradation, and mechanically keeps the path under the single
  unconditional doctrine driver used by hosted CI.
