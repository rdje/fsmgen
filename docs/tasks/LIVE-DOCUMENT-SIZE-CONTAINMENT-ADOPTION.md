# LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION: Bound Every Live Document Family

## Metadata

- Tree ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION`
- Status: `active`
- Roadmap lane: `infra/continuity / project-wide live-document lifecycle`
- Created: `2026-07-31`
- Last updated: `2026-08-01`
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
- Do not migrate a retained ledger or frozen status file outside its selected
  `.4`, `.5`, or `.11` owner.

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
  Children: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.12, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.18, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.19, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.20, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.24, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.25, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.26`

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
  Status: `done`
  Goal: `Consume the four-file lifecycle review and prove the selected rolling-ledger, sealed-segment, and archive-descriptor schema for any retained live ledgers.`
  Acceptance: `Implement decision 0046's common schema for the retained CHANGES and conditional DEVELOPMENT_NOTES ledgers: partition only at whole-entry boundaries, preserve order and identity, use bounded current/index views, record range/revision/line/byte/digest/retrieval metadata, prove exact reconstruction, define aggregate archive transition, and introduce no ledger or frozen-status-file migration yet.`
  Verification: `The neutral core and bounded empty local ledger registry now support opt-in append-only manifests: a bounded current file routes to a bounded complete index; contiguous whole-entry ranges carry sequence/ordinal/revision/dimension/range and endpoint digests; one exact complete-source descriptor plus built-in or executed reconstruction proves original entry bytes; content-addressed live seals obey independent range/line/byte limits before descriptor-backed archival. The wrapper, adapter runner, staged-resulting-tree checker, bootstrap inventory, neutral contract, audit, book, fact, and fail-closed fixtures move together. Focused t1553+t1554 pass at Files=2/Tests=25 and the authority cluster at Files=4/Tests=37; all 37 book chapters and the removed 73-file/17,285,553-byte build pass; Knowledge Map is 1,096 facts/5,761 keys; 22 surfaces cover 2,784 paths; all nine staged doctrines pass. CHANGES.md, DEVELOPMENT_NOTES.md, both frozen status files, existing surface ceilings, and product behavior do not migrate or change.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3: enforce bounded retained-ledger history`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4`
  Status: `done`
  Goal: `Reassess whether historical CHANGES.md still provides unique current value, then implement only the director-selected lifecycle.`
  Acceptance: `Do not presume retention from decision 0046 after the director's 2026-08-01 deferral. First compare the current reader question and unique value against task trees, Git, the mdBook, and bounded live status; select retain, supersede/archive, or another explicit outcome with the director. If retained, every historical entry must be accounted for exactly once, the current/index view must stay below its derived warning budget, sealed/version ranges must pass order/digest/retrieval proof, and a post-cutover append must pass without rewriting the immutable migration source. If superseded, prove consumers, unique-content disposition, deterministic exact retrieval, and planted negative controls before retiring the live path.`
  Verification: `Exact revision 329d7cf1b fixes the former changelog at 32,299 lines / 2,696,664 bytes / 3,282-byte longest line / SHA-256 6a1b0819... . The current-value audit classifies all 64 referring files and finds zero content consumers; the one executable reference is the circular route fixture. Decision 0047 retires the live path and per-slice write obligation without a replacement. An executed archive descriptor retrieves and verifies the exact Git object under fsmgen_required_history; the focused verifier rejects a recreated path, planted policy consumer, wrong digest, and absent revision, while its token probe detects exactly one planted orphan. README/workflow/book/fact/route/surface consumers now use task evidence plus work-unit Git history. Removing 2.7 MB exposed an impossible immutable-baseline/stale-ceiling conjunction, so the authority gate now permits baseline decreases only and still rejects increases or shape changes; root file/per-document-line/aggregate baselines and ceilings ratchet downward with zero ceiling increases. The RAM-guarded authority/neutrality/retirement cluster passes at Files=6/Tests=82; the staged wrapper covers all 2,785 Markdown paths in 21 surfaces, executes exact retrieval, reports maintained-reference delta 0/-3/-251, and passes path/locality/task/Knowledge Map controls. All 37 mdBook chapters test and the repository-local 73-file/17,283,330-byte build passes, then is removed exactly.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4: retire duplicate changelog`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5`
  Status: `done`
  Goal: `Migrate DEVELOPMENT_NOTES.md to the bounded rationale-ledger topology.`
  Acceptance: `Execute only the lifecycle selected by PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1 and schema proved by .3; if retained as a ledger, whole rationale entries retain order and identity, the root current/index view is below its derived warning budget, sealed ranges and archive descriptors pass exact proofs, decision/fact/task routing remains canonical, and no automatic placeholder growth is introduced.`
  Verification: `Activation commit d3c22e003 fixes the exact 34,507-line / 2,494,480-byte source with 2,843 whole entries. The migrated root is a 25-line / 1,420-byte bounded current view and the 36-line / 2,039-byte index addresses one exact version-backed historical range plus one real post-cutover entry. Two descriptors preserve complete-source and entry-body identities under fsmgen_required_history; the manifest proves 2,844 contiguous ordered entries, dimensions, range/endpoint digests, and exact prefix-plus-suffix reconstruction. The executed adapter and focused t1565 negative controls reject source, current, index, descriptor, and first-append drift. Root and rationale ceilings ratchet downward with zero increases; user workflow, facts, roadmap, task frontier, Memory, and the mdBook move together. Final gate evidence is recorded below; compiler/runtime/generated-product behavior is unchanged.`
  Commit: `d3c22e003 (activation); this commit (bounded rationale ledger)`

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
  Status: `done`
  Goal: `Partition the Chapter 14 feature backlog by stable user-facing topic.`
  Acceptance: `All existing user-facing material remains in navigable mdBook chapters exactly once; SUMMARY and reference links are complete; every part and aggregate fall below derived warning budgets; examples and all book gates pass.`
  Verification: `Activation commit b88b37323 fixes the exact 18,697-line / 1,157,040-byte source. A complete 15-range map places every source line exactly once in 13 direct Chapter 14 pages organized by stable language/data, composition, actor, IAL2, verification, AXI, APB, AHB, ISF, backend, validation, and API topics. SUMMARY remains a one-step mandatory read at 51/64 lines; the largest new page is 2,726 lines / 192,166 bytes and the longest Chapter 14 line is 303 bytes. The landing page preserves the existing backend deep-link. Exact-source, example, link, build, maintained-reference, rationale-ledger, and final gate evidence is recorded below; product behavior is unchanged.`
  Commit: `b88b37323 (activation); this commit (partitioned Chapter 14)`
  Blocked by: `none`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9`
  Status: `done`
  Goal: `Separate the bounded live roadmap from shipped chronology.`
  Acceptance: `ROADMAP_V2.md retains current/future direction and concise milestone outcomes; every removed historical claim is proved duplicate in maintained book/task/decision homes or covered by an exact archive descriptor; links and roadmap/task alignment pass; the retained roadmap falls below derived warning budgets.`
  Verification: `Activation commit c44c5b20a fixes the exact dc1c64afb roadmap source at 10,451 lines / 772,074 bytes / longest line 2,297 / SHA-256 6c7e00fe.... A complete six-range disposition retains the product objective, principles, R8-R14 strategy, dependency policy, concise milestone outcomes, and H1-H6 horizon intent in a 317-line / 14,606-byte / longest-line 182 live snapshot. Descriptor roadmap-v2-pre-containment-2026-08-01 preserves the entire source under fsmgen_required_history; an executed adapter and focused negative tests prove descriptor identity, Git retrieval, boundedness, canonical routes, and rejection of revived Current intent chronology. Final evidence is recorded below.`
  Commit: `c44c5b20a (activation); this commit (bounded roadmap and exact chronology)`
  Blocked by: `none`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10`
  Status: `active`
  Goal: `Bound canonical knowledge cards, shard the generated Knowledge Map, and add query-first discovery.`
  Acceptance: `Oversized cards split only on stable fact boundaries without duplicating or losing answers; cards remain canonical; a small root projection plus deterministic prefix/topic shards cover every fact/key exactly once; freshness, per-card, per-shard, aggregate, and query-result parity tests pass; disposable query caches remain repository-local under .artifacts/.`
  Verification: `Activated alone from clean .9 commit a20d38afc. The exact source has 1,097 knowledge-card files / 42,116 lines / 3,214,095 bytes, with one 855-line / 62,994-byte card and a 5,498-byte longest line; the generated map is 15,637 lines / 6,152,312 bytes / longest line 10,275 / SHA-256 aa8fb21b... and covers 1,096 facts / 5,762 question keys. This selection changes only task/index/book/fact/Memory continuity, a byte-identical deterministic projection regeneration, the matching maintained-reference authority, and a two-byte downward root aggregate ratchet; no card split, map topology, generator/config/query/cache behavior, pressure limit increase, or product behavior changes. Final activation evidence is recorded below.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10: activate bounded knowledge discovery`
  Blocked by: `none`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11`
  Status: `done`
  Goal: `Reassess the two frozen status-file values independently, then implement only each director-selected lifecycle.`
  Acceptance: `After .4 commits cleanly, first apply the same provenance/current-question/unique-content/consumer/canonical-overlap/recovery audit to LIVE_ACHIEVEMENT_STATUS.md and ask the director whether its independent present value justifies retention before changing its lifecycle; assess ROADMAP_STATUS.md independently rather than inferring the same answer. For every selected supersession, preserve the distinct exact identity with deterministic retrieval; migrate current workflow, README-route, book, registry, composition-note, and executable consumers; replace t/1332's stale ROADMAP_STATUS.md negative scan with current canonical truth; prove classified-consumer and planted-negative controls; retire each live path only after its independent pre/post identity, retrieval, and resulting-tree proof; leave historical evidence references intact.`
  Verification: `The two independent audits preserve exact identities and consumer classifications before each director selection. Decisions 0048/0049, bounded archive descriptors, and executable verifiers retire both live paths, routes, surfaces, and current consumers without replacement projections while preserving deterministic b4d07fee5 version recovery. The roadmap object remains exact at 15,039 lines / 1,638,574 bytes / longest line 5,716 / SHA-256 0f8db932...; its verifier rejects recreation, identity drift, missing history, and planted consumers, and the ATL/composition consumers now use maintained canonical sources. The RAM-guarded nine-file cluster passes at Files=9/Tests=96; 19 surfaces cover 2,787/2,787 Markdown paths and execute all three retirement adapters; README falls to 245/9,931 and root totals to 17 files / 62,935 lines / 9,540,744 bytes with zero ceiling increases. Knowledge Map passes at 1,096 facts/5,762 keys; relative-path/locality passes Files=2/Tests=22; all 37 mdBook chapters test and the repository-local 73-file/17,288,264-byte build passes and is removed exactly. Final staged acceptance and all doctrines pass.`
  Commit: `a75a60daf3 (achievement audit); d0c0e18309 (achievement retirement); 59b5196d59 (roadmap audit); this commit (roadmap retirement)`
  Blocked by: `none`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.12`
  Status: `pending`
  Goal: `Re-audit the steady state and replace legacy ceilings with derived retained-surface budgets.`
  Acceptance: `Every registered surface is remeasured; all live roots and parts are below warning; aggregate transitions and retrieval/reconstruction probes pass; temporary legacy headroom is reduced through a reviewed local registry update; doctrine/book/fact/task/roadmap/Memory agree; no artifact residue remains.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.7, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.18, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.19, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.20, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.24, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.25, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.26`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.13`
  Status: `pending`
  Goal: `Classify and bound focused root-level and ancillary Markdown collections.`
  Acceptance: `Every docs/*.md and ancillary Markdown surface has an audience/lifecycle owner and bounded complete index; the current 6,254-line focused outlier and any other semantic outliers are partitioned only at stable topic boundaries; unique maintained content remains in an appropriate browsable home; per-part/file-count/aggregate/freshness/link checks pass below warning without changing product behavior.`
  Verification: `pending`
  Commit: `pending`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23, LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.24`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14`
  Status: `done`
  Goal: `Publish a self-contained external review packet for the live-document containment and JSONL architecture.`
  Acceptance: `A tracked Markdown packet explains the problem, goals, terminology, topology, utility-before-containment and retirement outcomes, JSONL-versus-TSV decision, schemas, lifecycle classes, pressure model, route closure, task-tree sealing, exact retrieval, migration evidence, tests, failure modes, limits, portability boundary, and open design questions in sufficient detail for another project to review without reading FSMGen source; it illustrates retain/merge/supersede/archive/delete analysis with measured FSMGen candidates, provides a structured response template, tracks discovered gaps without silently fixing them, and changes no enforcement or product behavior.`
  Verification: `The tracked 1,309-line/54,068-byte packet is self-contained and separates neutral architecture, FSMGen evidence, JSONL schemas, lifecycle/pressure/retrieval mechanics, exact task migration, limitations, portability, 31 questions, and a pasteable response template. It makes utility precede size and illustrates retain/merge/supersede/archive/delete with measured FSMGen candidates without deleting a file. Source inspection confirms the specialized task manifests self-cap while the common surface/route/archive registries do not, and confirms hard_pct is ordering-only while absolute overflow is actual > budget; pending .15 owns those gaps and .16 owns the utility audit. Focused doctrine/route/task tests pass Files=3/Tests=49; path/locality passes Files=2/Tests=22; live coverage is 20 surfaces and 2,777/2,777 paths; Knowledge Map passes at 1,095 facts/5,722 keys; all 37 mdBook chapters test and the repository-local 73-file/17,116,666-byte build passes then is removed; final staged doctrines and cleanup are recorded below. No schema, checker, threshold, archive, README landing content, frozen content, product behavior, or existing document lifecycle changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14: publish external review packet`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15`
  Status: `done`
  Goal: `Make the common JSONL control plane finite, reviewable, and schema-constrained.`
  Acceptance: `The surface, route, and common archive-descriptor registries declare and enforce finite record/byte/maximum-record controls; scalar bytes, identifier domains, and array cardinalities prevent prose or identity-list displacement; Markdown surfaces gain a deterministic maximum-line-byte dimension where applicable; strict parser semantics and the portable negative fixture corpus remain the executable schema; neutrality remains mechanically tested; no threshold is widened.`
  Verification: `Every common registry now starts with exact positive max_records/max_bytes/max_record_bytes metadata under portable 10,000-record/16-MiB/64-KiB fail-safe ceilings; local caps are tighter. Strict scalar byte/identifier/128-item array controls and the sixth line_bytes_each pressure axis reject count/file/record/value/array/line overflow, including exact CRLF content width. The initial census records 10,275-byte Knowledge Map, 7,542-byte mdBook, and 6,264-byte task-evidence high-water lines without widening a predecessor ceiling. Perl/Bash syntax is clean; focused t1549+t1553+t1554+t1560+t1561 passes Files=5/Tests=76; path/locality/task passes Files=3/Tests=63. The real wrapper covers 22 surfaces and 2,784/2,784 Markdown paths, executes adapter/core proofs, accepts exact mdBook delta 0/+15/+1,041, and reports zero ceiling increases. Knowledge Map is 1,096 facts/5,759 keys; Memory is 38 lines; all 37 chapters test and the 73-file/17,284,414-byte repository-local build is removed exactly. Final staged acceptance/doctrines pass; no document lifecycle, frozen identity, README landing content, compiler/runtime artifact, or product behavior changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15: enforce common JSONL bounds`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16`
  Status: `done`
  Goal: `Make current utility and deliberate retirement precede size migration.`
  Acceptance: `Define reviewable retain/merge/supersede/archive/delete/re-form outcomes and require one before migration; audit each governed FSMGen document family for current audience, canonical role, unique value, duplication, staleness, consumers, and historical retention; explicitly assess USER_GUIDE.md, the two frozen status files, CHANGES.md, DEVELOPMENT_NOTES.md, ROADMAP_V2.md, generated KNOWLEDGE_MAP.md, ISF_SPEC.md, and focused readiness/contract collections; define role/canonical-input/replacement/consumer-change triggers; require fresh token/ID, classified-consumer, replacement-pointer, and negative-control proof before deletion; assign separate atomic migrations and delete nothing in this audit leaf.`
  Verification: `The 272-line/18,824-byte utility audit defines six outcomes, classifies all 22 governed surfaces, and records audience/role/value/duplication/currency/consumer/retention evidence for every family plus the named legacy and focused cohorts. Exact activation measurements cover 2,784 paths; the focused cohort census covers all 1,004 files and the USER_GUIDE token probe covers 212 normalized tokens with nine enumerated navigation-only residues. It retains active ISF contracts, selects re-form for structural representations, retains the four reviewed files only under their existing owner boundary, and selects supersession for USER_GUIDE/BOOK_PLAN plus re-form for WARP under new atomic `.24`/`.25` owners. Fresh identity/token/consumer/replacement/negative-control/resulting-tree proof is mandatory before deletion. Focused Files=4/Tests=68 pass; task integrity is trees=3/nodes=898/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces cover 2,785/2,785 paths, with focused files exactly 1,005/1,005; Knowledge Map is 1,096 facts/5,759 keys; Memory is 37 lines; all 37 chapters test and the 73-file/17,283,901-byte repository-local build is removed exactly; maintained-reference delta is 0/-7/-257 and zero ceilings increase; final staged doctrines pass. No file is deleted, moved, archived, reclassified, or content-migrated; no checker, ceiling, frozen identity, README landing content, compiler/runtime artifact, or product behavior changes.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16: audit utility before containment`
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
  Status: `done`
  Goal: `Add lifecycle-scoped currency contracts without a global date heuristic.`
  Acceptance: `The doctrine distinguishes boundedness, currency, and semantic truth; only a surface that declares a currency contract is checked by its calibrated local verifier; frozen and historical records remain correctly exempt; newest-date and distinct-date heuristics are not imposed globally; positive, self-refutation, legitimate-closure-date, frozen-date, and absent-contract fixtures prove low-noise behavior.`
  Verification: `The neutral surface schema now accepts only an optional exact currency object containing a stable contract_id and core:/adapter:/external: verifier. No declaration means no currency check; archive, external-terminal, and frozen lifecycles cannot declare one. Core and registry-derived adapter execution use an independent currency:surface proof namespace, while external contracts remain visible fail-closed degradation. FSMGen opts only active_index into active_task_tree_alignment through scripts/check_task_tree_integrity.pl, proving source/index agreement without date inference. Positive, real self-refutation, legitimate closure-date, frozen-date, absent-contract, prohibited-frozen-contract, missing-adapter-proof, exact-adapter-proof, and undeclared-schema-field fixtures pass in the intended direction. Perl syntax is clean and focused t1553+t1554 pass at Files=2/Tests=17; final combined/path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine evidence is recorded below. No global newest-date, distinct-date, file-age, or semantic-truth heuristic; no pressure value, ceiling, document lifecycle/content, archive, frozen identity, README landing content, compiler/runtime artifact, or product behavior change.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.20: enforce scoped currency contracts`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21`
  Status: `done`
  Goal: `Close typed route, collection-index, and evidence-map completeness.`
  Acceptance: `Path-shaped destinations emitted by enforcers are inventoried and classified as author_overflow or reader_navigation; every candidate resolves to a governed surface while legitimate route-kind differences remain explicit; each collection index proves complete target membership or declares a generated/query contract; the packet/disposition evidence maps reject missing paths; checks are unconditional and staged/resulting-tree aware; fail-closed fixtures cover an undeclared hint, wrong route kind, omitted collection member, and missing evidence path.`
  Verification: `Route rows now require an exact reader_navigation or author_overflow kind plus the actual source_path. The local source-derived scanner matches four emitted README overflow hints to governed surfaces and rejects undeclared or mistyped hints; fifteen README routes remain reader navigation. Every non-null collection index declares membership, generated, or query semantics: book/decision Markdown links cover every member, root/ancillary/task target expansion is the explicit complete query, and knowledge_cards links to the executed fact_index projection. Two fenced evidence-map records resolve all 17 packet and 5 disposition paths. The Git adapter rejects controlled staged/resulting content that differs from the worktree supplied to the neutral core. Focused t1553+t1554 pass at Files=2/Tests=20; final syntax/path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine evidence is recorded below. No pressure value, ceiling, lifecycle, archive/frozen identity, README landing content, compiler/runtime artifact, or product behavior change.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21: close route and index completeness`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22`
  Status: `done`
  Goal: `Make migration completeness, retention guarantees, and review-front-door bounds explicit.`
  Acceptance: `IAL2 migration evidence separately proves exact full-source identity/retrieval, all 844 authoritative task nodes, live working-set dimensions, and any truly omitted-content residue; version_object use declares a retention owner/guarantee and actionable shallow/rewrite failure, while unrecoverable evidence prefers content-addressed repository files; migration records reject false disjoint arithmetic; a bounded architecture/review front door routes the detailed packet to retained evidence under an explicit lifecycle; retrieval, missing-history, mismatch, and loss-residue fixtures fail closed.`
  Verification: `A bounded IAL2 migration manifest independently retrieves the 21,726-line/4,662,385-byte source at SHA-256 8cff8e7b..., checks all 844 sealed nodes, measures the 6,002-line/2,438,733-byte live root/manifest/segment working set, declares overlapping_non_partition products, and records zero loss residue. Task-tree and neutral archive version objects name a bounded owner/guarantee/recovery contract; missing-history output prints the recovery action. A 79-line/3,946-byte front door with 100-line/5-KiB caps routes to the SHA-256-frozen 1,311-line packet. Focused Files=3/Tests=62, task graph, 22-surface complete Markdown coverage, Knowledge Map, Memory, all 37 book chapters, repository-local render/cleanup, staged acceptance, and all-doctrine evidence are recorded below.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22: enforce migration and retention proof`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23`
  Status: `done`
  Goal: `Select the lifecycle contract for maintained product-bounded reference prose.`
  Acceptance: `Decide whether a maintained_reference class is distinct from partitioned_canonical; preserve unique user/specification prose whose aggregate grows with the product while bounding mandatory index/read units, per-part reviewability, navigation depth, and contract-authorized aggregate change; record an auditable classification rationale per affected surface; prove the selected rule on mdBook and ISF-spec examples without deleting content or weakening landing-page, ledger, projection, archive, or frozen controls.`
  Verification: `Decision 0045 makes maintained_reference an information lifecycle distinct from partitioned_canonical topology. The neutral schema requires bounded audience/role/rationale, null fixed aggregate pressure axes, fixed per-part targets/ceilings, one independently capped complete mandatory index, direct membership navigation, and exact aggregate baseline plus signed delta. The Git adapter proves each current aggregate against the prior revision and rejects stale, inexact, reused, banked, or silently removed authority. FSMGen classifies the mdBook at exact prior 38 files/47,377 lines/2,511,665 bytes plus authorized 0/+35/+2,124 delta; SUMMARY remains 39 lines/1,999 bytes with depth one, all prose remains, and Chapter 14 debt is unchanged. The mixed focused collection records docs/ISF_SPEC.md as a candidate while retaining its existing ceilings and .13 migration owner. Final focused, path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine evidence and exact artifact cleanup are recorded below.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23: enforce maintained-reference contracts`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.17`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.24`
  Status: `done`
  Goal: `Prove and execute supersession of the completed guide-migration waypoints.`
  Acceptance: `Against exact staged docs/USER_GUIDE.md and docs/BOOK_PLAN.md identities, run whole-document token/ID sweeps with enumerated residue and planted-orphan negative control; classify every documentation/code/test/script/registry consumer; migrate any unique accurate content to a named mdBook/decision/fact home; replace implementation, test, README, book, roadmap, and planning pointers with current canonical destinations; prove exact historical retention; remove each waypoint only if its independent replacement and resulting-tree gates pass, otherwise retain it with the failed proof recorded.`
  Verification: `Clean activation commit 65c646a12 fixes exact candidate identities. Fresh case-folded five-character token sweeps enumerate USER_GUIDE 212/8 residue and BOOK_PLAN 392/39; planted orphans change them to 9/40. The one unique case-study link and non-obvious-failure quality rule move into the book. All 19 and 7 pre-change consumers are classified; implementation, test, README, book, roadmap, and planning consumers now use canonical book homes, while historical/evidence mentions remain factual. The post-edit classifier reports zero unresolved and one for each planted consumer. Git show reproduces both exact objects under fsmgen_required_history. Focused and final resulting-tree evidence is recorded below.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.24: supersede completed guide waypoints`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.25`
  Status: `done`
  Goal: `Retire the unused WARP harness bootstrap without losing unique project guidance or weakening the remaining tool-neutral authority chain.`
  Acceptance: `Inventory every WARP.md claim and consumer, route any still-unique accurate guidance to README/TOOLBOX/mdBook/fact/decision homes, exercise planted-orphan and unresolved-consumer negative controls, then delete WARP.md and remove it from the required-bootstrap inventory because the director confirms warp.dev is no longer used; AGENTS authority, enforcement of every remaining bootstrap, README landing behavior, and all project workflows remain unchanged.`
  Verification: `Activation commit f02da976f fixes WARP at 183 lines/6,878 bytes/SHA-256 3b2b47e9.... After the director confirmed warp.dev is unused, a fresh 287-token sweep enumerates 53 non-fact residues and a planted orphan produces 54 exactly. The exact activation tree has five referring files: two factual ledgers, two proof records, and the bootstrap checker; there is no content or active harness consumer. Removing the obsolete checker requirement yields zero unresolved consumers, while a planted consumer yields one. WARP is deleted, exact git-show recovery passes, the bootstrap checker enforces absence, its planted-file control fails, and all remaining authority-marker checks pass. Final focused, path/locality, live-size, task, Knowledge Map, Memory, mdBook, staged-acceptance, doctrine, and cleanup evidence is recorded below.`
  Commit: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.25: retire unused WARP bootstrap`
  Blocked by: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16`

- ID: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.26`
  Status: `pending`
  Goal: `Inventory and reassess agent-era Markdown continuity documents whose original crash/restart role may now be superseded by the durable memory architecture.`
  Acceptance: `Do not infer candidates from age, size, or filename alone. Establish provenance and an explicit candidate inventory; for each document, identify its present reader question, unique accurate content, live code/test/script/doc/registry consumers, canonical overlap with MEMORY.md/task trees/decisions/facts/mdBook/Git, and exact recovery requirement. Propose retain, merge, supersede, archive, delete, or re-form independently; require director selection before any lifecycle change; and apply .16's exact identity, residue, consumer, replacement, planted-negative, retention, and resulting-tree proof to every selected removal.`
  Verification: `pending; the director supplied origin context on 2026-08-01 but intentionally named no exhaustive candidate set and selected no lifecycle.`
  Commit: `pending`
  Blocked by: `director review; do not activate during the current deferral`

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
- `2026-07-31`: The rereferenced PGEN and ANVIL paths are byte-identical to the
  reviews already dispositioned by `.17`: their exact sizes and SHA-256 values
  match the tracked evidence table. They introduce no follow-up finding or new
  scope. Clean `.19` commit `25c815326` therefore activates `.20` next.
- `2026-07-31`: `.20` keeps boundedness, currency, and semantic truth distinct.
  Currency is an opt-in named local oracle; terminal/frozen history cannot
  declare it, undeclared surfaces are not scanned, and FSMGen calibrates the
  active-index contract to task/source alignment rather than date shape.
- `2026-07-31`: Clean scoped-currency commit `8cf8263a2` activates `.21` alone
  for typed author/reader routes, complete collection indexes, and checked
  review evidence maps. The activation changes no checker or registry.
- `2026-07-31`: `.21` preserves the reviewers' route distinction instead of
  harmonizing it: navigation and author guidance remain separately typed even
  when both legitimately resolve to the exact-history terminal. Index and
  evidence completeness are now explicit resulting-tree contracts.
- `2026-07-31`: Clean `.21` implementation commit `9c63cf76b` activates `.22`
  alone for migration completeness, retention guarantees, and a bounded review
  front door. This selection changes no checker, registry, migration evidence,
  archive contract, or document content.
- `2026-07-31`: Clean `.22` implementation commit `2bfb32c02` activates `.23`
  alone to select the maintained product-reference lifecycle and auditable
  classification contract before affected family migrations.
- `2026-07-31`: Decision 0045 selects `maintained_reference` as a lifecycle,
  not a partitioning synonym. It fixes repeated-read and per-part costs,
  replaces decorative aggregate caps with exact fresh change authority,
  classifies the mdBook, and leaves the ISF specification under existing debt
  until its owned semantic partition lands.
- `2026-07-31`: Clean `.23` implementation commit `425cd7fef` activates `.15`
  alone for finite common JSONL control-plane bounds before utility `.16`.
- `2026-07-31`: `.16` selects utility outcomes for all 22 surfaces before
  migration. Active canonical specifications stay; structural representations
  re-form; the four-file policy owner remains authoritative; USER_GUIDE plus
  BOOK_PLAN supersession moves to `.24`; verbose WARP re-form moves to `.25`.
- `2026-07-31`: Deletion requires exact identity, a fresh whole-document
  token/ID sweep, classified consumers across code/tests/scripts as well as
  docs, named replacement pointers, planted-orphan and planted-consumer
  negative controls, retention where needed, and resulting-tree gates.
- `2026-07-31`: Clean `.16` audit commit `b9f2f266c` activates `.24` alone to
  prove USER_GUIDE/BOOK_PLAN supersession before touching either candidate.
- `2026-07-31`: `.24` independently proves and removes both completed
  waypoints, preserves unique content in the book, redirects live consumers,
  and retains exact Git recovery under `fsmgen_required_history`.
- `2026-07-31`: Clean `.24` commit `984448936` activates `.25` alone to prove
  WARP compaction before changing the harness bootstrap or its enforcement.
- `2026-07-31`: The director confirms warp.dev is no longer used. `.25`
  therefore selects `delete`, not `re-form`: preserve the exact source object
  in Git, remove its sole executable requirement, and make absence a checked
  local invariant after claim/consumer/negative-control proof.
- `2026-08-01`: The director resumes the containment program after clean `.25`
  completion. No blocked containment leaf is activated by this handoff update:
  the next clean selection is `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1`,
  whose selected lifecycle contract is required before `.3` can prove the
  retained-ledger schema and `.4` can migrate `CHANGES.md`.
- `2026-08-01`: Clean commit `8fdd5a22cc` activates prerequisite
  `PROJECT-STATUS-AND-CHANGELOG-POLICY-REVIEW.1` only. Containment `.3` and
  `.4` remain blocked until that audit selects the long-term roles.
- `2026-08-01`: Decision `0046` selects bounded current/index views over
  sealed whole-entry history for the retained changelog and conditional
  rationale ledgers. It supersedes both frozen status files as current views,
  requires distinct exact archive retrieval before retiring their live paths,
  and makes `.3` the next clean selection. No migration occurs in the audit.
- `2026-08-01`: From clean audit commit `b443957c1a`, activate `.3` alone to
  implement the common retained-ledger, sealed-range, reconstruction, and
  archive-descriptor schema. No reviewed document or enforcement changes in
  the activation slice.
- `2026-08-01`: `.3` makes the decision-0046 contract executable without
  opting in a project ledger: every manifest is finite; current/index views,
  whole-entry range order and endpoint identity, exact source reconstruction,
  content-addressed seals, and the descriptor-backed aggregate transition all
  fail closed. `.4` becomes the next clean selection.
- `2026-08-01`: From clean schema commit `e47b509c9`, activate `.4` alone for
  the bounded `CHANGES.md` whole-entry migration. The activation leaves every
  changelog byte at its existing path and does not opt in a ledger manifest.
- `2026-08-01`: Before migration, the director questions whether the historical
  32,299-line changelog retains any current value and defers the lifecycle
  decision. `.4` returns to pending; retain and supersede/archive remain open.
- `2026-08-01`: Pre-migration source/test inspection also finds that `.3` proves
  only a static complete source. A retained design must anchor the immutable
  cutover prefix separately so the next valid append does not fail exact
  reconstruction. No schema correction is selected while lifecycle is open.
- `2026-08-01`: The director explains that `CHANGES.md` is one of several
  Markdown files created early in agent-assisted development to survive
  session crash/loss/restart before the current continuity architecture.
  Pending `.26` owns an evidence-first inventory and per-file value review;
  no candidate list or retain/removal outcome is inferred from this context.
- `2026-08-01`: The director selects deletion for `CHANGES.md` if the exact
  `.4` audit finds no value independent of the current continuity doctrines.
  The audit finds no content or executable consumer: its only live claim is a
  manually curated work-unit summary already answered by task-tree closure,
  Git subjects/diffs, and the user-facing mdBook. `.4` resumes to prove exact
  recovery and retire the obligation, route, surface, and live path atomically;
  `.26` retains the broader agent-era document inventory.
- `2026-08-01`: After `.4` commits cleanly, the director requires the same
  explicit current-value question for `LIVE_ACHIEVEMENT_STATUS.md`. Pending
  `.11` must first present its independent provenance/value/consumer/overlap/
  recovery evidence and obtain the director's lifecycle selection; it may not
  infer deletion from the `CHANGES.md` outcome or silently combine the two.
- `2026-08-01`: The independent audit commit `a75a60daf3` finds no live content
  or executable consumer and identifies direct browsing of a stale partial
  23-day digest as the sole retention case. The director selects retirement.
  Decision `0048` and the `.11` retirement slice preserve exact version
  recovery, remove the current route/surface/live path, and add absence and
  planted-consumer enforcement. This selection does not decide roadmap status.
- `2026-08-01`: The separate roadmap-status audit commit `59b5196d59` finds no
  unique current authority and identifies direct browsing of the March-June
  chronology plus R0-R14 snapshot as its sole distinct value. The director
  independently selects retirement. Decision `0049` preserves exact version
  recovery, removes the current route/surface/live path and stale consumers,
  and forbids a replacement combined status projection. Leaf `.11` is done;
  `.5` is the next clean selection.
- `2026-08-01`: Clean `.11` commit `3084d8c7b` activates `.5` alone. The
  selection fixes the rationale-ledger migration frontier without changing
  `DEVELOPMENT_NOTES.md`, its registry topology, or product behavior.
- `2026-08-01`: `.5` preserves the exact 2,843-entry activation source as a
  descriptor-backed reconstruction prefix and starts a bounded one-entry
  current suffix. The index, manifest, adapter, and focused negative controls
  prove order, identity, retrieval, and the formerly missing first append.
  `.8` is the next clean selection.
- `2026-08-01`: Clean `.5` commit `2e572d9fd` activates `.8` alone. The
  selection fixes the Chapter 14 partition frontier without changing its
  18,697-line source, SUMMARY membership, cross-links, examples, limits, or
  product behavior.
- `2026-08-01`: Clean `.8` commit `dc1c64afb` activates `.9` alone. The
  selection fixes the exact roadmap source and direction/chronology proof
  boundary; only the bounded final frontier sentence changes before migration.
- `2026-08-01`: `.9` replaces the appended status chronology with a bounded
  strategic roadmap. The complete 10,451-line activation source remains exact
  through a descriptor, required-history contract, and executed verifier;
  `.10` becomes the next clean selection.
- `2026-08-01`: Clean `.9` commit `a20d38afc` activates `.10` alone. The
  selection fixes the exact canonical-card and generated-map source before any
  fact-boundary split, projection sharding, query interface, or cache change.

## Open Questions

- Which Markdown files were created primarily as early agent-session continuity
  aids, and what present reader question—if any—does each answer better than
  Memory, task trees, decisions, facts, Git, and maintained user documentation?
  `.26` must establish the candidate set before asking for lifecycle choices.
- None for completed `.15`-`.23`. The rereferenced PGEN/ANVIL files exactly
  match the reviews already reconciled in the bounded disposition. The
  existing four-file review retains authority for its named semantic roles.
- Verification finding already owned by proposed task
  `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT`: on macOS,
  `scripts/run_with_ram_guard.sh` computed 98.3% host use from only free plus
  speculative VM pages while `memory_pressure` simultaneously reported 83%
  system-wide memory free. The guard correctly stopped, but its host metric is
  not a valid macOS pressure measure. The existing safety-task blocker remains
  director approval; this finding does not silently activate or duplicate it.

## Blockers

- None for active `.10`; completed `.16` supplies the evidence-backed
  retain-facts/re-form-projection selection. `.26` still owns the broader
  legacy-continuity inventory and remains deferred.

## Acceptance Checklist (enforced) — `.10` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'| Knowledge cards and map |' --oneline -- docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md` identifies `18e2dcbc6`, and `git log -S'knowledge_cards' --oneline -- docs/LIVE_DOCUMENT_UTILITY_RETIREMENT_AUDIT.md` identifies completed prerequisite `b9f2f266c`. At clean `.9` commit `a20d38afc`, 1,097 canonical-card files total 42,116 lines / 3,214,095 bytes; the largest is 855 lines / 62,994 bytes with a 5,498-byte line. Their generated root projection is a 15,637-line / 6,152,312-byte / 10,275-byte-line monolith at SHA-256 `aa8fb21b...`, over every fact-index health dimension except file count.
- [x] **ADDRESSED (verified)** — clean `.9` commit `a20d38afc` activates `.10` alone and records both exact source boundaries. Only task/index/book/fact/Memory continuity, a byte-identical deterministic projection regeneration, its exact maintained-reference authority, and the required downward root ratchet change; card partitioning, map topology, generator/config/query/cache behavior, pressure limits, and product behavior remain unchanged.
- [x] **NO REGRESSION** — after the first run exposed a redundant question row exceeding the root maximum-byte ceiling by 439 bytes and the corrected run exposed two bytes of stale root aggregate headroom, the row was removed, the generated map returned byte-identical to `a20d38afc`, and the root baseline/ceiling ratcheted downward by two bytes. The final RAM-guarded cluster reports `All tests successful` at `Files=5, Tests=72`. Staged containment covers 19 surfaces and 2,800/2,800 paths, accepts maintained-reference delta `files=0 / lines=+5 / bytes=+304`, and reports zero ceiling increases. Knowledge Map passes at 1,096 facts/5,762 keys; Memory is 41 lines. All 49 chapters test and the repository-local 85-file / 17,701,192-byte build passes and is removed exactly. Final staged acceptance and all doctrines pass; no card split, map topology, generator/config/query/cache behavior, compiler/runtime/HDL/generated-product behavior, or pressure-limit increase occurs.

## Acceptance Checklist (enforced) — `.9` bounded roadmap

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'## Current intent' --oneline -- ROADMAP_V2.md` identifies `ec89c0cc7`; the exact activation object at `dc1c64afb` is 10,451 lines / 772,074 bytes / longest line 2,297 / SHA-256 `6c7e00fe...`. Its strategic prefix ends at line 1,097, while lines 1,098–10,451 are 9,354 lines of appended leaf/status chronology that duplicate task-tree, mdBook, and Git roles and leave the live roadmap exactly at its 10,451-line ceiling.
- [x] **ADDRESSED (verified)** — a complete six-range disposition retains objective/principles, `R8`–`R14` direction, dependencies, concise milestone outcomes, and `H1`–`H6` horizon intent in 317 lines / 14,606 bytes / longest line 182. Descriptor `roadmap-v2-pre-containment-2026-08-01` covers every activation-source line through exact `dc1c64afb:ROADMAP_V2.md` retrieval. `scripts/check_roadmap_v2_history.pl` binds descriptor fields to the source identity, enforces warning-safe live bounds and canonical Memory/task/book routes, and rejects a revived `Current intent` chronology.
- [x] **NO REGRESSION** — the corrected RAM-guarded focused cluster reports `All tests successful` at `Files=8, Tests=87`; the first run usefully exposed and the final run confirms the explicit four-migrated/six-deferred surface count. Staged containment covers 19 surfaces and 2,800/2,800 document paths, reconstructs 2,846 rationale entries, accepts maintained-reference delta `files=0 / lines=+4 / bytes=+269`, and reports zero ceiling increases. Knowledge Map passes at 1,096 facts/5,762 keys; Memory is 41 lines. All 49 chapters test and the repository-local 85-file / 17,698,695-byte build passes and is removed exactly. Final staged acceptance and all doctrines pass; no compiler/runtime, HDL, generated-product, or shipped feature behavior changes.

## Acceptance Checklist (enforced) — `.9` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'| Roadmap | Keep current/future direction' --oneline -- docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md` identifies `139efbf90`, and `git log -S'Re-form live roadmap direction and separately retain proved chronology' --oneline -- docs/LIVE_DOCUMENT_UTILITY_RETIREMENT_AUDIT.md` identifies completed prerequisite `b9f2f266c`. The byte-identical source at clean `.8` commit `dc1c64afb` is 10,451 lines / 772,074 bytes / longest line 2,297 / SHA-256 `6c7e00fe...`, exactly at its line ceiling and well above its 2,000-line health target.
- [x] **ADDRESSED (verified)** — clean `.8` commit `dc1c64afb` activates `.9` alone and records the exact classification boundary. Only the roadmap's bounded final containment-frontier sentence changes; direction claims, history, heading topology, links, pressure controls, generated artifacts, and product behavior remain unchanged.
- [x] **NO REGRESSION** — the RAM-guarded focused cluster reports `All tests successful` at `Files=5, Tests=72`. Staged containment covers 19 surfaces and 2,800/2,800 document paths, accepts exact maintained-reference delta `files=0 / lines=+5 / bytes=+310`, and reports zero ceiling increases. Knowledge Map passes at 1,096 facts/5,762 keys; Memory is 42 lines. All 49 chapters test and the repository-local 85-file / 17,697,234-byte build passes and is removed exactly. Final staged acceptance and all doctrines pass; no direction claim, history, link, limit, generated-product, compiler/runtime, HDL, or product behavior changes.

## Acceptance Checklist (enforced) — `.8` Chapter 14 partition

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Chapter 14 per-part debt remains owned' --oneline -- docs/book/src/90-reference-map.md` identifies the maintained-reference debt boundary, while `git show b88b37323:docs/book/src/14-feature-backlog.md` fixes the pre-partition source at 18,697 lines / 1,157,040 bytes / SHA-256 `3757214f...`. Its single part exceeds the 5,000-line / 512-KiB health targets while `SUMMARY.md` has room for twelve direct members below its 80% warning boundary.
- [x] **ADDRESSED (verified)** — the exact-source partition proof reports `13 pages, 15 ranges, 18697/18697 source lines exactly once`. Stable topic pages reunite the two non-contiguous HIAL/VIAL and APB histories without changing range bytes; `SUMMARY.md` is 51/64 lines at navigation depth one; the largest new page is 2,726 lines / 192,166 bytes and the longest Chapter 14 line is 303 bytes. The landing page preserves the established `#backends-and-validation` route.
- [x] **NO REGRESSION** — the RAM-guarded focused cluster reports `All tests successful` at `Files=6, Tests=75`; staged containment covers 19 surfaces and 2,800/2,800 document paths, reconstructs 2,845 rationale entries, accepts exact maintained-reference delta `files=+12 / lines=+59 / bytes=+2,498`, and reports zero ceiling increases. All 49 listed chapters test; the repository-local 85-file / 17,695,227-byte build passes and is removed exactly. Knowledge Map remains 1,096 facts / 5,762 keys; Memory is 40 lines. Final staged acceptance and all-doctrine evidence is recorded below; no compiler, runtime, generated-product, HDL, or feature-support behavior changes.

## Acceptance Checklist (enforced) — `.8` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Chapter 14 per-part debt remains owned' --oneline -- docs/book/src/90-reference-map.md` identifies `425cd7fef`; the unchanged `docs/book/src/14-feature-backlog.md` is one 18,697-line / 1,157,040-byte maintained-reference part at SHA-256 `3757214f...`, while completed `.16` and `.23` remove both prerequisite blockers.
- [x] **ADDRESSED (verified)** — clean `.5` commit `2e572d9fd` activates `.8` alone and records the exact partition boundary. Chapter 14, `SUMMARY.md`, its incoming links, examples, maintained-reference topology, limits, and product behavior remain unchanged in this selection slice.
- [x] **NO REGRESSION** — the RAM-guarded path/task/README/reference cluster reports `All tests successful` at `Files=4, Tests=56`. The live-document gate covers 19 surfaces and 2,788/2,788 Markdown paths, accepts exact mdBook delta `files=0 / lines=0 / bytes=+53`, and reports zero ceiling increases. Knowledge Map passes at 1,096 facts/5,762 keys and 6,152,312 bytes; Memory is 39 lines; all 37 chapters test and the removed repository-local build is 73 files/17,292,776 bytes. Final staged acceptance and all doctrines pass without changing Chapter 14, SUMMARY, incoming links, examples, compiler/runtime behavior, generated product artifacts, or HDL.

## Acceptance Checklist (enforced) — `.5` bounded rationale-ledger migration

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'# DEVELOPMENT_NOTES' --oneline -- DEVELOPMENT_NOTES.md` identifies `d44ca14d5`, while `git log -S'engineering rationale' --oneline -- DEVELOPMENT_NOTES.md COMMIT.md AGENTS.md` identifies `0ff590b91` as the conditional-write policy. Exact activation object `d3c22e003:DEVELOPMENT_NOTES.md` is one 34,507-line / 2,494,480-byte rollover-debt file containing 2,843 whole entries. The generic `.3` source-equality proof had no post-cutover fixture, so a first append would either rewrite the immutable source or fail reconstruction.
- [x] **ADDRESSED (verified)** — `scripts/check_engineering_rationale_ledger.pl` proves the exact immutable source body is the prefix of 2,844 ordered entries across descriptor-backed and current ranges, including one independent append. `prove -lv t/1565-engineering-rationale-ledger.t` reports `All tests successful` at `Files=1, Tests=3`; its negative controls reject current mutation, missing append, wrong source descriptor digest, and incomplete range indexing. The current/index files are 25/1,420 and 36/2,039, respectively, and the doctrine gate reports the rationale surface normal at 9.6% of its health/ceiling peak.
- [x] **NO REGRESSION** — the final RAM-guarded lifecycle cluster reports `All tests successful` at `Files=8, Tests=52`, and the path/locality/task cluster at `Files=3, Tests=63`. The live-document gate executes all six version/ledger adapter proofs, reconstructs 2,844 entries, covers 2,788/2,788 Markdown paths, accepts exact mdBook delta `files=0 / lines=+6 / bytes=+442`, and reports zero ceiling increases. Knowledge Map passes at 1,096 facts/5,762 keys and remains exactly 6,152,312 bytes; Memory is 39 lines; all 37 book chapters test and the removed repository-local build is 73 files/17,292,177 bytes. Historical entry bytes remain retrievable under `fsmgen_required_history`; root totals fall to 18 files/28,488 lines/7,049,705 bytes, and no compiler, runtime, generated-product, or HDL behavior changes.

## Acceptance Checklist (enforced) — `.5` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — completed `.11` leaves `.5` as the next clean frontier, while `DEVELOPMENT_NOTES.md` remains one 34,507-line rollover-debt file and decision `0046` requires the conditional rationale role to migrate through the whole-entry schema proved by `.3`.
- [x] **ADDRESSED (verified)** — clean `.11` commit `3084d8c7b` activates `.5` alone and fixes the exact migration boundary; the rationale source, ledger registry, archive descriptors, checker, limits, and product surfaces remain unchanged in this selection slice.
- [x] **NO REGRESSION** — focused path/task/live-size, Knowledge Map, Memory, mdBook, staged acceptance, and all-doctrine results are recorded below; no source entry, generated artifact, compiler/runtime behavior, or product documentation changes.

## Acceptance Checklist (enforced) — `.4` duplicate-changelog retirement

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'Add one concise' --oneline -- AGENTS.md COMMIT.md` identifies `0ff590b91` as the commit that imposed the duplicate per-slice write. Exact object `329d7cf1b:CHANGES.md` is 32,299 lines / 2,696,664 bytes / SHA-256 `6a1b0819...`; the fresh 64-reference census finds no product, build, runtime, reader, or continuity content consumer. Its only executable reference is the `t/1553` fixture for the circular route policy. Task closure plus the work-unit Git subject/diff already answers what changed, while Memory, decisions/facts, and the mdBook own resume/rationale/behavior. Removing those bytes also proves the old cross-revision immutable baseline incompatible with the mandatory stale-headroom ceiling ratchet: the ceiling had to fall below its historical baseline.
- [x] **ADDRESSED (verified)** — decision `0047`, `docs/LEGACY_CONTINUITY_DOCUMENT_VALUE_AUDIT.md`, the archive descriptor, and executable `scripts/check_retired_changes_history.pl` retire the live path/obligation/route/surface without a replacement and preserve exact version recovery. The verifier rejects a recreated path, planted `AGENTS.md` consumer, wrong digest, and missing revision; the token fixture detects one planted orphan exactly. Baselines may now decrease only, while increases/shape changes still fail; the root surface ratchets downward with zero ceiling increases. The RAM-guarded `t/1549`/`t/1553`/`t/1554`/`t/1560`/`t/1561`/`t/1562` cluster passes at `Files=6, Tests=82`.
- [x] **NO REGRESSION** — the final RAM-guarded cluster reports `All tests successful` at `Files=6, Tests=82`. The staged `scripts/check_live_document_size.sh` executes exact recovery and covers all 2,785 tracked Markdown paths in 21 surfaces; maintained-reference authority accepts exact mdBook delta `files=0 / lines=-3 / bytes=-251`, ceiling authority reports zero increases, and task-tree/Knowledge Map/relative-path/project-locality gates pass. All 37 mdBook chapters test and the repository-local 73-file/17,283,330-byte build passes, then is removed exactly. The live file is absent, `DEVELOPMENT_NOTES.md` and both frozen status files remain unchanged, and `.11` explicitly requires an independent `LIVE_ACHIEVEMENT_STATUS.md` value audit plus director selection.

## Acceptance Checklist (enforced) — `.11` independent achievement-status audit

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'latest completed roadmap-aligned slice' -- LIVE_ACHIEVEMENT_STATUS.md` identifies `d4c8d1a92` as the origin of the recovery claim; the exact current census instead finds a 16,618-line historical journal, 1,289 headings plus a headingless continuation, 32 selection headings, and 1,784 commits after its `b4d07fee5` freeze. The 55-reference census finds no executable or content consumer; only policy/navigation and historical evidence references remain.
- [x] **ADDRESSED (verified)** — `docs/audits/LIVE_ACHIEVEMENT_STATUS_VALUE_AUDIT.md` records provenance, exact identity and recovery, actual content, all consumer classes, canonical overlap, the directly browsable digest as the sole distinct retention case, and three explicit lifecycle options. `.11` is active and blocked on the director's independent selection; the frozen file, README route, and surface registry are unchanged.
- [x] **NO REGRESSION** — the RAM-guarded focused cluster reports `All tests successful` across `Files=6, Tests=82`; the initial redundant Knowledge Map key correctly exceeded the ceiling and was removed rather than raising it. Knowledge Map passes at 1,096 facts/5,762 keys; all 37 mdBook chapters test and the repository-local 73-file/17,287,889-byte build passes and is removed exactly. `[doctrine] all doctrine checks passed` for the final staged audit tree, with zero ceiling increases and no code, runtime behavior, frozen content, route, lifecycle, or product artifact change.

## Acceptance Checklist (enforced) — `.11` achievement-journal retirement

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'latest completed roadmap-aligned slice' -- LIVE_ACHIEVEMENT_STATUS.md` identifies `d4c8d1a92` as the origin of the claimed live recovery view; audit commit `a75a60daf3` proves the 16,618-line object froze at `b4d07fee5`, misses 1,784 later commits, mixes selection/completion/obsolete frontier records, and has zero executable/content consumers. The director independently selects retirement after reviewing direct browsing as the sole distinct value.
- [x] **ADDRESSED (verified)** — decision `0048`, descriptor `achievement-status-retired-2026-08-01`, `scripts/check_retired_achievement_history.pl`, and `t/1563-retired-achievement-history.t` preserve exact 16,618-line / 955,308-byte / longest-line 358 / SHA-256 `46c3c8ad...` retrieval while retiring the live path, README route, frozen surface, and current workflow consumers. Positive recovery plus recreated-path, planted-policy-consumer, wrong-digest, missing-revision, and planted-orphan controls all pass; historical evidence remains intact.
- [x] **NO REGRESSION** — the RAM-guarded split cluster reports `All tests successful` across `Files=7, Tests=86`; both exact-history adapters execute and 20 live surfaces cover all 2,786 tracked Markdown paths. Root-document totals fall from 94,596 lines / 12,134,707 bytes / 19 files to 77,980 / 11,179,753 / 18 and their baseline/ceiling ratchets fall with zero increases. Knowledge Map passes at 1,096 facts/5,762 keys; task integrity reports trees=3/nodes=899/segments=1; relative paths pass Files=1/Tests=2; project locality passes; all 37 mdBook chapters test and the repository-local 73-file/17,286,903-byte build passes and is removed exactly. Final staged `[doctrine] all doctrine checks passed` evidence is required without changing roadmap status, rationale policy, compiler/runtime behavior, or generated product artifacts.

## Acceptance Checklist (enforced) — `.11` independent roadmap-status audit

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'canonical live roadmap status board' -- ROADMAP_STATUS.md` identifies `5b161e0c5` as the origin of the live-board claim; the unchanged 15,039-line object now reports no active tree/frontier despite active task trees and 1,786 later commits. Its 70-reference census finds zero product/runtime/build consumers, one stale negative test scan, and one inaccurate composition-note active-source link.
- [x] **ADDRESSED (verified)** — `docs/audits/ROADMAP_STATUS_VALUE_AUDIT.md` fixes the exact SHA-256 `0f8db932...` identity and `b4d07fee5` recovery, decomposes the mixed chronology/status/workstream content, classifies all consumers and canonical overlap, records direct browsing of the March-June 2026 chronology plus R0-R14 snapshot as the sole distinct retention case, and recommends retirement among three explicit options. The frozen file, route, surface, composition note, and test remain unchanged until the director independently selects a lifecycle.
- [x] **NO REGRESSION** — the monitored focused status/task/route/live-size/reference/ceiling/retired-history cluster reports `All tests successful` at `Files=8, Tests=92`; the default 88% and first 96% host thresholds stop before incomplete runs because the known macOS metric ignores reclaimable memory, while the successful one-run 99.5% profile retains the 4,096-MiB descendant cap after `memory_pressure` reports 81% free. The final staged 100% macOS-host profile retains that descendant cap and lets the required gate consume the new audit path. The real staged wrapper covers 20 surfaces and all 2,787 Markdown paths, executes both retired-history adapters, accepts exact mdBook delta 0/+5/+403, and reports zero ceiling increases. Knowledge Map passes at 1,096 facts/5,762 keys; task integrity reports trees=3/nodes=899/segments=1; relative paths pass Files=1/Tests=2; project locality passes; all 37 mdBook chapters test and the repository-local 73-file/17,290,550-byte build passes and is removed exactly. Final staged acceptance and all doctrines pass without changing the frozen identity, lifecycle, route, executable consumer, compiler/runtime behavior, or generated product artifacts.

## Acceptance Checklist (enforced) — `.11` roadmap-status retirement

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'canonical live roadmap status board' -- ROADMAP_STATUS.md` identifies the original live-board claim; audit commit `59b5196d59` proves the unchanged 15,039-line object misses 1,786 later commits, contradicts the active task frontier, and has no product/runtime/build content consumer. The director independently selects retirement after reviewing direct historical browsing as its sole distinct value.
- [x] **ADDRESSED (verified)** — decision `0049`, descriptor `roadmap-status-retired-2026-08-01`, `scripts/check_retired_roadmap_history.pl`, and `t/1564-retired-roadmap-history.t` preserve exact revision, line, byte, longest-line, and SHA-256 identity while retiring the live path, route, surface, and current consumers. Canonical roadmap/task/Memory/book/Git routes replace the false combined board without introducing another status projection.
- [x] **NO REGRESSION** — the corrected RAM-guarded status/task/route/live-size/authority/history cluster reports `All tests successful` at `Files=9, Tests=96`. All three exact-history adapters execute; 19 surfaces cover 2,787/2,787 staged Markdown paths; the root and README baselines/ceilings ratchet downward with zero ceiling increases; Knowledge Map reports 1,096 facts/5,762 keys; relative-path/locality reports Files=2/Tests=22; all 37 book chapters test and the 73-file/17,288,264-byte repository-local build passes, then is removed exactly. Final staged task acceptance and `[doctrine] all doctrine checks passed` complete the slice without compiler/runtime/generated-product changes.

## Acceptance Checklist (enforced) — `.4`/`.26` director deferral

- [x] **ROOT CAUSE (WHY + WHERE)** — the director identifies `CHANGES.md` as one of several Markdown files created early in agent-assisted development for crash/loss/restart continuity, before the current Memory/task/decision/fact/Git architecture, and explicitly questions present value rather than selecting retention. The clean activation tree fixes CHANGES at 32,299 lines without migration. `git log -S'source_descriptor_id' --oneline -- live-document-size/scripts/check_live_document_size.pl` and the matching `complete-source` pickaxe both identify `.3` commit `e47b509c9`; source/fixture inspection shows that it compares reconstruction with one unchanged complete source but never appends a post-cutover entry, so retention cannot yet claim a durable rolling append workflow.
- [x] **ADDRESSED (verified)** — BEFORE → AFTER: `.4` was activated under a presumed retained-ledger outcome; it is now pending without moved content, while pending `.26` requires a provenance-derived candidate inventory, current-reader/unique-content/consumer/overlap/recovery evidence, independent outcomes, and director selection before lifecycle change. Roadmap, audit, mdBook, fact, task/index, Memory, and the line-neutral changelog state the deferral without guessing candidates. The focused path/task/live/reference/ceiling cluster reports `All tests successful` at `Files=6, Tests=80`; the real wrapper validates 22 surfaces and all 2,784 paths with exact maintained-reference delta 0/0/-8.
- [x] **NO REGRESSION** — the focused cluster reports `All tests successful` at `Files=6, Tests=80`. `CHANGES.md` remains one 32,299-line file; `doctrine/live_document_size/ledger_manifests.jsonl` retains only its empty-registry header; no archive descriptor, threshold, frozen file, compiler/runtime/generated artifact, or product behavior changes. Knowledge Map passes at 1,096 facts/5,761 keys; Memory is 39 lines; all 37 mdBook chapters and the removed 73-file/17,286,533-byte repository-local build pass. Final staged acceptance/doctrine evidence is recorded below.

## Acceptance Checklist (enforced) — `.3` retained-ledger schema

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'rolling_ledger' --oneline -- live-document-size/scripts/check_live_document_size.pl` identifies `18e2dcbc6`; source inspection shows that the original lifecycle only measured one file and validated standalone archive descriptors, so it could not prove a bounded current/index pair, whole-entry segmentation, range order/identity, exact reconstruction, or the point at which sealed history must leave the live collection.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t` reports `All tests successful` at `Files=2, Tests=25`; positive and fail-closed fixtures cover bounded empty/opted-in manifests, complete current/index routing, printable literal entry boundaries, contiguous sequence/ordinals, range and endpoint digests, exact complete-source entry reconstruction, content-addressed seals, descriptor agreement, executed core/adapter proof, and live range/line/byte archive thresholds.
- [x] **NO REGRESSION** — the broader live-document authority cluster reports `All tests successful` at `Files=4, Tests=37`, and staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`; every pre-existing lifecycle, pressure, route, index, evidence, verifier, retention, archive, currency, coverage, neutrality, reference-authority, and ceiling-authority control remains green. No project ledger is opted in or migrated; `CHANGES.md`, `DEVELOPMENT_NOTES.md`, both frozen status identities, existing ceilings, README landing content, compiler/runtime artifacts, and product behavior remain unchanged.

## Acceptance Checklist (enforced) — `.16` utility/retirement audit

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'compatibility waypoint' --oneline -- docs/USER_GUIDE.md` identifies `798aff26b`/`2b47ba40f`, while the 22-surface census and direct inspection show that USER_GUIDE/BOOK_PLAN describe a completed guide migration and WARP duplicates 183 lines below the tool-neutral bootstrap. Conversely, current ISF specifications changed on 2026-07-30 and have implementation/test consumers, so size-only retirement would destroy live contract value.
- [x] **ADDRESSED (verified)** — `docs/LIVE_DOCUMENT_UTILITY_RETIREMENT_AUDIT.md` defines all six outcomes, classifies every surface and required named document/cohort, publishes the 1,004-file focused census and 212-token USER_GUIDE probe, defines utility triggers and seven-part deletion proof, and assigns `.24`/`.25` plus existing migrations without deleting or moving a file.
- [x] **NO REGRESSION** — the focused cluster reports `All tests successful` at `Files=4, Tests=68`; final task/path/live-size, Knowledge Map, Memory, mdBook, staged acceptance, and all-doctrine checks are recorded below. Frozen identities, README landing content, maintained ISF/book prose, ceilings, runtime artifacts, and product behavior remain unchanged.

## Acceptance Checklist (enforced) — `.24` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — completed `.16` classifies `docs/USER_GUIDE.md` and `docs/BOOK_PLAN.md` as probable completed migration waypoints, but its explicit deletion contract forbids acting on the preliminary census without fresh exact-identity, residue, consumer, replacement, negative-control, retention, and resulting-tree proof.
- [x] **ADDRESSED (verified)** — clean `.16` commit `b9f2f266c` activates `.24` alone and names its exact two independent proof subjects; candidate bytes, consumers, replacements, and lifecycle remain untouched in this selection slice.
- [x] **NO REGRESSION** — final path/task/live-size, Knowledge Map, Memory, mdBook, staged-diff, and all-doctrine results are recorded below; no candidate, implementation, test, README landing content, book product prose, registry, ceiling, frozen identity, or product behavior changes.

## Acceptance Checklist (enforced) — `.24` guide-waypoint supersession

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'compatibility waypoint' --oneline -- docs/USER_GUIDE.md` identifies the two commits that converted the guide into pointers, while `git log -S'Status: in progress.' --oneline -- docs/BOOK_PLAN.md` identifies the scaffold plan that never retired. Exact activation objects prove completed migration state, not canonical product prose: USER_GUIDE is 130/5,468 at SHA-256 `18de5df2...`; BOOK_PLAN is 310/9,968 at `dd82c598...`. Fresh scans find 19/7 referring files, including a stale public manifest path and README/book/roadmap language that still represented the finished migration as active.
- [x] **ADDRESSED (verified)** — whole-file probes enumerate USER_GUIDE 212 tokens/8 spelling-navigation residues and BOOK_PLAN 392/39 residues; planted orphans yield 9/40. The AXI intent-capture link and non-obvious-failure example rule move to named book homes. Manifest/test/README/book/roadmap consumers now point at the book, post-edit unresolved consumers are 0/0, planted consumers are 1/1, and `git show 65c646a12:<path>` reproduces both exact identities under `fsmgen_required_history` before the two waypoint files are removed.
- [x] **NO REGRESSION** — `perl -Iperl -c` passes and the RAM-guarded documentation-manifest cluster reports `All tests successful` at `Files=5, Tests=22`; the first default guard attempt stops pre-test on the tracked false macOS 99.5% metric, while the authorized profile retains the 4,096-MiB process cap after fresh 78.4% Stats usage, kernel pressure 1, and 78% system-free evidence. Final path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates and exact artifact cleanup are recorded below.

## Acceptance Checklist (enforced) — `.25` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — completed `.16` identifies 183-line `WARP.md` as a useful harness discovery file whose content below the authority pointers duplicates project overview, commands, architecture, inventory, examples, tests, and design claims; separate `.25` ownership is required before any representation change.
- [x] **ADDRESSED (verified)** — clean `.24` commit `984448936` activates `.25` alone and names the exact content/consumer/replacement/negative-control proof; WARP and its checker remain byte-for-byte untouched in this selection slice.
- [x] **NO REGRESSION** — final path/task/live-size/Knowledge Map/Memory/mdBook/staged-diff and all-doctrine evidence is recorded below; no bootstrap content or enforcement, authority, landing page, product documentation, registry, ceiling, frozen identity, or product behavior changes.

## Acceptance Checklist (enforced) — `.25` WARP retirement

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'## Project Overview' --oneline -- WARP.md` identifies `57563dcaa`, and activation revision `f02da976f` fixes the retired bootstrap at 183 lines/6,878 bytes/SHA-256 `3b2b47e9...`; direct inspection shows duplicated or stale overview, command, architecture, inventory, example, and testing prose. The director confirms warp.dev is no longer used, so the assumed harness-discovery role has ended.
- [x] **ADDRESSED (verified)** — the audit enumerates all 287 normalized source tokens and 53 explained residues; a planted orphan raises residue to 54. All five activation-tree referring files are classified, no content/harness consumer remains, and the post-edit classifier reports zero unresolved consumers versus one planted consumer. `WARP.md` is deleted; `scripts/check_doctrine_bootstrap.sh` removes it from the required set and adds an explicit retired-file absence invariant; `git show f02da976f:WARP.md` reproduces the exact source.
- [x] **NO REGRESSION** — Bash syntax and the real remaining-bootstrap check pass; a transient planted `WARP.md` makes the same checker fail exactly as required. The RAM-guarded focused cluster reports `All tests successful` at `Files=3, Tests=64`; final path/locality, task/live-size, Knowledge Map, Memory, mdBook, staged-acceptance, and all-doctrine gates plus exact artifact cleanup are recorded below. No remaining bootstrap marker, README landing content, mdBook product prose, registry ceiling, frozen identity, compiler/runtime artifact, or product behavior changes.

## Acceptance Checklist (enforced) — `.21`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'route_id' --oneline -- live-document-size/scripts/check_live_document_size.pl` identifies `18e2dcbc6`; source inspection shows the original four-field route rows validated only remembered file-backed graph edges, accepted index presence without membership/alternate semantics, and had no evidence-map input, so an emitted author hint, incomplete index, or stale packet path could remain green.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t` reports `All tests successful` at `Files=2, Tests=20`; fixtures reject an undeclared emitted hint, wrong author/reader kind, omitted literal collection member, missing evidence path, and controlled staged-result/worktree divergence while the real four author hints, 15 reader routes, six collection contracts, and two evidence maps pass.
- [x] **NO REGRESSION** — staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`; all 20 surfaces and 2,782 tracked Markdown paths remain covered, all 22 review evidence paths resolve, task/README/locality/Memory/Knowledge Map/mdBook contracts stay green, and no route destination, pressure ceiling, lifecycle, or product behavior changes.

## Acceptance Checklist (enforced) — `.22`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'source_revision' --oneline -- scripts/check_task_tree_integrity.pl` identifies `78adb81ae`, while `git log -S'retrieval_kind' --oneline -- live-document-size/scripts/check_live_document_size.pl` identifies `18e2dcbc6`; source inspection shows both mechanisms proved an object only while Git retained it, neither named an owner/guarantee/recovery contract, and the IAL2 packet compared overlapping full-source/semantic/live products without a separately checked migration record or loss-residue dimension.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1549-task-tree-integrity-doctrine.t t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t` reports `All tests successful` at `Files=3, Tests=62`; the live migration retrieves 21,726 lines/4,662,385 bytes, checks 844 semantic nodes and a 6,002-line/2,438,733-byte working set, declares overlapping products and zero residue, while missing contracts/history, source/node/working-set mismatch, false partition arithmetic, and unretained residue fail closed. The 79-line/3,946-byte bounded review front door routes to the exact SHA-256-frozen 1,311-line packet.
- [x] **NO REGRESSION** — `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`; all 22 surfaces and the complete tracked Markdown inventory remain covered, task/README/locality/Memory/Knowledge Map/mdBook contracts stay green, the 73-file/17,004-KiB render is removed exactly, and the frozen packet identity plus exact version-object retrieval remain unchanged.

## Acceptance Checklist (enforced) — `.23` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — ANVIL Q2 shows that unique product-sized reference prose does not fit history-oriented containment: `partitioned_canonical` describes its storage topology but cannot justify a fixed aggregate ceiling that moves whenever the product gains a legitimate feature. The pending `.23` leaf already owns that unresolved lifecycle/classification boundary.
- [x] **ADDRESSED (verified)** — clean commit `2bfb32c02` is the exact predecessor; only task/index/roadmap/book/fact/Memory/audit/changelog continuity selects `.23`, leaving its lifecycle decision and implementation pending.
- [x] **NO REGRESSION** — focused path/task/live-size, Knowledge Map, Memory, mdBook, staged acceptance, and all-doctrine checks pass; `.23` alone is active, and no checker, registry, lifecycle value, pressure limit, maintained prose, frozen identity, README landing content, or product behavior changes.

## Acceptance Checklist (enforced) — `.23` maintained-reference contract

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'partitioned_canonical' --oneline -- live-document-size/scripts/check_live_document_size.pl doctrine/live_document_size/surfaces.jsonl` identifies `18e2dcbc6`; source inspection shows that the original seven-class schema forced unique product-sized book prose into a partition topology with fixed aggregate targets, so legitimate product documentation could only consume a moving decorative cap or eventually be displaced.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t t/1561-live-document-reference-authority.t` reports `All tests successful` at `Files=3, Tests=24`; positive and fail-closed fixtures prove bounded classification/read/parts, exact baseline/delta, fresh one-use authority, unchanged-authority continuity, narrow baseline-shape migration, lifecycle protection, and preserved ceiling-authority semantics. The real wrapper reports one changed maintained reference at exact 38 files/47,412 lines/2,513,789 bytes with a 39-line/1,999-byte mandatory index and navigation depth one.
- [x] **NO REGRESSION** — staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`; task/path/Memory/Knowledge Map/mdBook gates stay green, the review front door is 78 lines and TOOLBOX 315, the 73-file/17,020-KiB book build is removed exactly, and no unique maintained prose, fixed non-reference limit, frozen identity, README landing content, compiler/runtime artifact, or product behavior changes.

## Acceptance Checklist (enforced) — `.15` activation

- [x] **ROOT CAUSE (WHY + WHERE)** — `.14` source inspection and the accepted ANVIL/PGEN disposition show that specialized task manifests self-cap while the common surface, route, archive-descriptor, evidence, retention, and authority JSONL control plane can grow or hide oversized values without its own finite schema pressure contract; existing `.15` owns that boundary.
- [x] **ADDRESSED (verified)** — clean commit `425cd7fef` is the exact predecessor; only task/index/roadmap/book/fact/Memory/audit/changelog continuity activates `.15`, leaving the inventory and enforcement implementation pending.
- [x] **NO REGRESSION** — focused path/task/live-size, Knowledge Map, Memory, mdBook, staged acceptance, and all-doctrine checks pass; `.15` alone is active and no checker, registry, schema, pressure limit, document content/lifecycle, frozen identity, README landing content, or product behavior changes.

## Acceptance Checklist (enforced) — `.15` common JSONL bounds

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'max_records' --oneline -- live-document-size scripts doctrine/live_document_size doctrine/readme_entrypoint` plus direct parser inspection shows only specialized task manifests and the retention registry had partial self-bounds; common surface/route/evidence/archive/authority inputs could grow in records, record width, scalar prose, or arrays. Measuring the governed Markdown also exposes 10,275-byte single generated lines, proving total line and byte axes do not bound row reviewability.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t t/1561-live-document-reference-authority.t` reports `All tests successful` at `Files=4, Tests=35`; positive and fail-closed fixtures cover metadata presence/shape, record/file/line bounds, 128-item arrays, scalar UTF-8 bytes, exact CRLF width, and cross-revision authority compatibility.
- [x] **NO REGRESSION** — `scripts/check_live_document_size.sh` passes 22 surfaces and complete tracked-Markdown coverage, executes the real task/Knowledge Map adapters, accepts the exact fresh mdBook delta, and reports zero ceiling increases; final staged `scripts/check_doctrines.sh` reports `[doctrine] all doctrine checks passed`, with Memory, Knowledge Map, task integrity, path, and mdBook evidence recorded below. No predecessor threshold, lifecycle, frozen identity, landing content, or product behavior changes.

## Acceptance Checklist (enforced) — `.20`

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S'baseline verifier' --oneline -- live-document-size/scripts/check_live_document_size.pl` identifies `18e2dcbc6`; source inspection shows that the introduced exact surface schema had no currency contract or execution path, so bounded/route-closed output could not make or refute a scoped current-state claim and any date scan would have lived outside lifecycle ownership.
- [x] **ADDRESSED (verified)** — `prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t` reports `All tests successful` at `Files=2, Tests=17`; executed side effects and negative cases cover positive/local currency, real self-refutation, legitimate closure dates, frozen dates, absent contracts, forbidden frozen contracts, strict schema, delegated adapter reachability, missing proofs, and exact proofs.
- [x] **NO REGRESSION** — staged `scripts/check_doctrines.sh` ends with `[doctrine] all doctrine checks passed`; all 20 surfaces and 2,782 tracked Markdown paths remain covered, `active_task_tree_alignment` executes successfully, and task/README/locality/Memory/Knowledge Map/mdBook contracts stay green without a global date heuristic.

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
| `2026-07-31` | `.20` activation | exact rereferenced-review identity; clean `25c815326` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; PGEN 393/26,788 at SHA-256 5057b147... and ANVIL 334/44,242 at 9dac9f1f... exactly match `.17`; paths Files=1/Tests=2; trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces and 2,782/2,782 paths; Knowledge Map 1,096 facts/5,745 keys; Memory 43 lines; all 37 chapters test; removed 73-file/16,996-KiB build; all nine doctrines pass; `.20` alone active; no checker, registry, currency contract, lifecycle, archive, document-family content, frozen identity, landing content, or product behavior change |
| `2026-07-31` | `.20` scoped currency | optional exact currency schema; lifecycle exemptions; independent proof namespace; real active-index oracle; syntax/focused/path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-acceptance/doctrine gates; exact cleanup | `passed`; focused Files=2/Tests=17; paths Files=1/Tests=2; trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces and 2,782/2,782 paths; Knowledge Map 1,096 facts/5,748 keys; Memory 42 lines; all 37 chapters test; removed 73-file/17,000-KiB build; real self-refutation and low-noise date fixtures pass in both directions; no global date heuristic, lifecycle/content, archive, frozen identity, landing content, or product behavior change |
| `2026-07-31` | `.21` activation | clean `8cf8263a2` predecessor; task/index/roadmap/book/fact/Memory/changelog sync; path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; paths Files=1/Tests=2; trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces and 2,782/2,782 paths; Knowledge Map 1,096 facts/5,748 keys; Memory 42 lines; all 37 chapters test; removed 73-file/17,000-KiB build; all nine doctrines pass; `.21` alone active; no checker, registry, route kind, index/evidence contract, document lifecycle/content, frozen identity, landing content, or product behavior change |
| `2026-07-31` | `.21` route/index/evidence completeness | exact route kinds/source paths; source-derived author hints; membership/query/generated index contracts; two fenced evidence maps; staged-result agreement; syntax/focused/path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-acceptance/doctrine gates; exact cleanup | `passed`; focused Files=3/Tests=25; paths Files=1/Tests=2; trees=3/nodes=896/segments=1/compact=0/index archives=1; 4 author hints and 15 reader routes; 6 indexed collection contracts; packet/disposition paths 17+5; 20 surfaces and 2,782/2,782 paths; Knowledge Map 1,096 facts/5,752 keys; Memory 42 lines; all 37 chapters test; removed 73-file/17,000-KiB build; all declared negative controls and nine doctrines pass; the default RAM guard stopped safely on a false macOS 98.3%-used estimate while `memory_pressure` reported 83% free, so the successful retry retained process-tree/RSS monitoring and manually checked actual pressure under a recorded one-run host override; no pressure value, lifecycle, archive, frozen identity, landing content, or product behavior change |
| `2026-07-31` | `.22` activation | clean `9c63cf76b` predecessor; existing RAM-guard fact/task reuse; task/index/roadmap/book/fact/Memory/changelog sync; path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; paths Files=1/Tests=2; trees=3/nodes=896/segments=1/compact=0/index archives=1; 20 surfaces and 2,782/2,782 paths; Knowledge Map 1,096 facts/5,752 keys; Memory 40 lines; all 37 chapters test; removed 73-file/17,004-KiB build; all nine doctrines pass; `.22` alone active; no checker, registry, migration evidence, archive contract, review artifact content, lifecycle, frozen identity, landing content, or product behavior change |
| `2026-07-31` | `.22` migration/retention proof | exact IAL2 source/node/working-set/residue manifest; bounded retention contracts; actionable missing-history diagnostics; frozen packet plus bounded routed front door; focused/path/task/live-size/Knowledge Map/Memory/mdBook/staged-doctrine gates; exact cleanup | `passed`; source 21,726 lines/4,662,385 bytes/SHA-256 8cff8e7b...; 844 nodes; working set 6,002/2,438,733; zero residue; focused Files=3/Tests=62; trees=3/nodes=896/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces; Knowledge Map 1,096 facts/5,758 keys; 37 chapters; removed 73-file/17,004-KiB build; packet frozen at SHA-256 49351a2a...; no README or product behavior change |
| `2026-07-31` | `.23` activation | clean `2bfb32c02` predecessor; task/index/roadmap/book/fact/Memory/audit/changelog sync; path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; focused Files=3/Tests=55; trees=3/nodes=896/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces and complete Markdown coverage; Knowledge Map 1,096 facts/5,758 keys; Memory 40 lines; all 37 chapters test; removed 73-file/17,012-KiB repository-local build; `.23` alone active; no checker, registry, lifecycle value, limit, maintained content, frozen identity, landing content, or product behavior change |
| `2026-07-31` | `.23` maintained-reference contract | decision 0045; neutral lifecycle/schema/core; Git aggregate authority; mdBook and ISF classification; UTF-8 byte bounds; focused/path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-acceptance/doctrine gates; exact cleanup | `passed`; focused Files=3/Tests=24; maintained mdBook exact prior 38/47,377/2,511,665 plus delta 0/+35/+2,124; mandatory index 39/1,999/depth 1; trees=3/nodes=896/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces/2,784 paths; Knowledge Map 1,096 facts/5,759 keys; Memory 38 lines; review front door 78 and TOOLBOX 315 lines; all 37 chapters test; removed 73-file/17,020-KiB build; all nine doctrines pass; no unique prose deletion, non-reference limit/frozen/landing/product change |
| `2026-07-31` | `.15` activation | clean `425cd7fef` predecessor; task/index/roadmap/fact/Memory/audit/changelog sync; focused path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; Files=2/Tests=43; trees=3/nodes=896/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces/2,784 paths; Knowledge Map 1,096 facts/5,759 keys; Memory 38 lines; all 37 chapters test; removed 73-file/17,020-KiB build; `.15` alone active; no checker, registry, schema/value/limit, lifecycle/content, frozen identity, landing content, or product behavior change |
| `2026-07-31` | `.15` common JSONL bounds | bounded headers/scalars/arrays; six-axis pressure and CRLF semantics; Git authority compatibility; neutral/local docs; syntax/focused/path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-acceptance/doctrine gates; exact cleanup | `passed`; portable 10,000-record/16-MiB/64-KiB hard stops plus tighter local declarations; focused Files=5/Tests=76; paths/locality/task Files=3/Tests=63; 22 surfaces/2,784 paths; exact reference delta 0/+15/+1,041; Knowledge Map 1,096/5,759; Memory 38; all 37 chapters; removed build 73 files/17,284,414 bytes; zero ceiling increases; all doctrines pass; no predecessor threshold, lifecycle, frozen identity, landing content, or product behavior change |
| `2026-07-31` | `.16` activation | clean `2e10cc605` predecessor; task/index/roadmap/fact/audit/Memory/changelog sync; focused path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; focused Files=2/Tests=43; trees=3/nodes=896/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces/2,784 paths; Knowledge Map 1,096/5,759; Memory 38; all 37 chapters; removed build 73 files/17,284,414 bytes; all doctrines pass; `.16` alone active; no audit outcome, migration, retirement, deletion, checker, registry, threshold, lifecycle/content, frozen identity, landing content, mdBook product prose, or product behavior change |
| `2026-07-31` | `.16` utility/retirement audit | 22-family utility classification; named guide/status/ledger/roadmap/map/ISF/focused cohort evidence; exact external-review identity; token and consumer probes; outcome/trigger/deletion-proof contract; `.24`/`.25` decomposition; focused/task/path/live-size/Knowledge Map/Memory/mdBook/staged-doctrine gates; exact cleanup | `passed`; audit 272 lines/18,824 bytes; focused Files=4/Tests=68; trees=3/nodes=898/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces/2,785 paths; focused collection exactly 1,005 files; Knowledge Map 1,096/5,759; Memory 37; all 37 chapters; removed build 73 files/17,283,901 bytes; reference delta 0/-7/-257; zero ceiling increases; all doctrines pass; no deletion, movement, archive, lifecycle/ceiling/frozen/landing/product change |
| `2026-07-31` | `.24` activation | clean `b9f2f266c` predecessor; task/index/roadmap/audit/fact/Memory/changelog sync; path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; paths Files=1/Tests=2; trees=3/nodes=898/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces/2,785 paths; maintained reference unchanged at 38/47,420/2,514,573; Knowledge Map 1,096/5,759; Memory 37; all 37 chapters; removed build 73 files/17,283,901 bytes; all doctrines pass; `.24` alone active; candidate and consumer bytes unchanged |
| `2026-07-31` | `.24` guide-waypoint supersession | two exact source identities; 212/8 and 392/39 token/residue sweeps; 19/7 classified consumers; planted orphan and consumer controls; Git recovery; manifest/source/test/README/book/roadmap/audit sync; focused/path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; manifest Files=5/Tests=22; live-document Files=3/Tests=27; zero unresolved and one planted consumer per candidate; paths Files=1/Tests=2; trees=3/nodes=898/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces/2,783 paths; focused collection 1,003 files/211,931 lines/9,376,208 bytes; reference delta 0/-2/-150 to 38/47,418/2,514,423; README 245/9,921; Knowledge Map 1,096/5,759; Memory 37; all 37 chapters; removed build 73 files/17,282,858 bytes; staged acceptance root=git_history/no-regression=prove_summary; all doctrines pass; both exact historical objects recoverable |
| `2026-07-31` | `.25` activation | clean `984448936` predecessor; task/index/roadmap/audit/fact/Memory/changelog sync; path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; paths Files=1/Tests=2; trees=3/nodes=898/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces/2,783 paths; Knowledge Map 1,096/5,759; Memory 36; all 37 chapters; removed build 73 files/17,282,858 bytes; all doctrines pass; `.25` alone active; WARP remains exact 183 lines/6,878 bytes and bootstrap enforcement is unchanged |
| `2026-07-31` | `.25` WARP retirement | exact source identity/recovery; 287-token/53-residue sweep; planted orphan and consumer; five-consumer classification; bootstrap absence positive/negative controls; focused/path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; source 183/6,878/SHA-256 3b2b47e9...; planted residue 54; unresolved consumers 0/1 planted; focused Files=3/Tests=64; paths Files=1/Tests=2; locality passes; trees=3/nodes=898/segments=1/compact=0/index archives=1/migrations=1; 22 surfaces/2,782 paths; Knowledge Map 1,096/5,759; Memory 37; all 37 book chapters test; removed build 73 files/17,282,858 bytes; zero ceiling increases; no remaining bootstrap, landing, product documentation, ceiling, frozen identity, or product behavior change |
| `2026-08-01` | `.3` activation | clean `b443957c1a` predecessor; task/index/Memory/changelog sync; path/task/live-size/Knowledge Map/Memory/diff/staged-doctrine gates | `passed`; trees=3/nodes=898/segments=1/index archives=1/migrations=1; 22 surfaces and 2,784 document paths; Knowledge Map 1,096/5,760; Memory 40 lines; CHANGES held at 32,299 lines; all nine staged doctrines pass with docs-only acceptance; `.3` alone active; no schema, checker, registry, test, migration, reviewed-document topology, frozen identity, threshold, generated artifact, or product behavior change |
| `2026-08-01` | `.3` retained-ledger schema | finite empty/opt-in ledger registry; whole-entry current/sealed/archive ranges; exact source reconstruction; wrapper/adapter/resulting-tree/bootstrap wiring; syntax/focused/authority/live-size/task/path/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; focused Files=2/Tests=25 and authority cluster Files=4/Tests=37; trees=3/nodes=898/segments=1/index archives=1/migrations=1; 22 surfaces/2,784 paths; Knowledge Map 1,096/5,761; Memory 39; all 37 chapters; removed build 73 files/17,285,553 bytes; zero ceiling increases; all nine doctrines pass; default RAM guard stopped pre-test on the tracked macOS metric while the documented one-run override retained the 4,096-MiB descendant cap with 82% system-free evidence; no ledger/status migration, frozen/ceiling/landing/product change |
| `2026-08-01` | `.4` activation | clean `e47b509c9` predecessor; task/index/Memory/changelog sync; path/task/live-size/Knowledge Map/Memory/mdBook/diff/staged-doctrine gates; exact cleanup | `passed`; focused paths/task/routes Files=3/Tests=52 and ledger-doctrine Files=1/Tests=16; trees=3/nodes=898/segments=1/index archives=1/migrations=1; 22 surfaces/2,784 paths; Knowledge Map 1,096/5,761; Memory 39; CHANGES held at 32,299 lines; all 37 chapters and removed build 73 files/17,285,553 bytes; all nine staged doctrines pass with docs-only acceptance; `.4` alone active; no changelog movement, ledger opt-in, index/seal/archive, enforcement, threshold, frozen identity, generated artifact, or product behavior change |
| `2026-08-01` | `.4`/`.26` director deferral | director questions changelog value and identifies a broader agent-era continuity-document cohort; static-source/post-cutover-append root-cause inspection; deferred inventory task; roadmap/audit/book/fact/task/index/Memory/changelog sync; focused/live-size/Knowledge Map/Memory/mdBook/staged-doctrine gates; exact cleanup | `passed`; focused Files=6/Tests=80; trees=3/nodes=899/segments=1/index archives=1/migrations=1; 22 surfaces/2,784 paths; maintained reference exact delta 0 files/0 lines/-8 bytes to 38/47,426/2,515,044; Knowledge Map 1,096/5,761; Memory 39; CHANGES held at 32,299 lines; all 37 chapters and removed build 73 files/17,286,533 bytes; staged acceptance root=git_history/no-regression=prove_summary and all nine doctrines pass; no candidate set inferred and no changelog movement, ledger opt-in, lifecycle selection, ceiling increase, frozen identity, schema/enforcement, or product behavior change |
| `2026-08-01` | `.11` independent roadmap-status audit | exact identity/provenance/content partition; 70-consumer and canonical-overlap classification; three lifecycle options; audit/book/fact/decision/task/index/Memory sync; focused/live-size/Knowledge Map/path/locality/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; source 15,039/1,638,574/SHA-256 0f8db932... and 1,786 post-freeze commits; focused Files=8/Tests=92; trees=3/nodes=899/segments=1/index archives=1/migrations=1; 20 surfaces/2,787 staged paths; maintained-reference delta 0/+5/+403; Knowledge Map 1,096/5,762; Memory 42; all 37 chapters; removed build 73 files/17,290,550 bytes; zero ceiling increases; all doctrines pass; no frozen-content, lifecycle, route, consumer, compiler/runtime, or product-artifact change; director selection pending |
| `2026-08-01` | `.11` roadmap-status retirement | decision 0049; exact version identity/retrieval; live-path/route/surface/consumer absence; canonical ATL/composition routes; planted recreation/consumer/identity/history/orphan negatives; focused/path/locality/live-size/Knowledge Map/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; source 15,039/1,638,574/longest 5,716/SHA-256 0f8db932...; focused Files=9/Tests=96; 19 surfaces/2,787 staged paths; root 17 files/62,935 lines/9,540,744 bytes; README 245/9,931; reference delta 0/-5/-347; Knowledge Map 1,096/5,762; paths/locality Files=2/Tests=22; all 37 chapters; removed build 73 files/17,288,264 bytes; zero ceiling increases; all doctrines pass; no replacement projection or compiler/runtime/generated-product change; `.11` done and `.5` next |
| `2026-08-01` | `.5` activation | clean `3084d8c7b` predecessor; task/index/roadmap/fact/Memory sync; path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates | `passed`; paths Files=1/Tests=2; trees=3/nodes=899/segments=1/index archives=1/migrations=1; 19 surfaces/2,787 paths; Knowledge Map current; Memory 40 lines; all 37 chapters test; zero ceiling increases; `.5` alone active; rationale source and registry topology unchanged |
| `2026-08-01` | `.5` bounded rationale ledger | exact 2,843-entry activation source; descriptor-backed prefix plus real current append; bounded current/index; adapter and negative controls; root/rationale ratchet; focused/path/locality/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; focused Files=8/Tests=52; paths/locality/task Files=3/Tests=63; source 34,507/2,494,480 at SHA-256 bf5a03fd...; current 25/1,420; index 36/2,039; ordered ledger 2,844 entries/34,520 lines/2,495,325 bytes; root 18/28,488/7,049,705; 19 surfaces/2,788 paths; reference delta 0/+6/+442; Knowledge Map 1,096/5,762 and 6,152,312 bytes; Memory 39; all 37 chapters; removed build 73/17,292,177; zero ceiling increases; all doctrines pass; product behavior unchanged |
| `2026-08-01` | `.8` activation | clean `2e572d9fd` predecessor; exact Chapter 14 identity; task/index/roadmap/book/fact/Memory sync; path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; focused Files=4/Tests=56; trees=3/nodes=899/segments=1/index archives=1/migrations=1; 19 surfaces/2,788 paths; Chapter 14 unchanged at 18,697/1,157,040 and SHA-256 3757214f...; reference delta 0/0/+53; Knowledge Map 1,096/5,762 and 6,152,312 bytes; Memory 39; all 37 chapters; removed build 73/17,292,776; zero ceiling increases; `.8` alone active; content, navigation, examples, limits, and product behavior unchanged |
| `2026-08-01` | `.8` Chapter 14 partition | exact activation-source/range coverage; stable direct topic navigation and backend compatibility anchor; rationale-ledger append; per-part ratchet; focused/path/task/live-size/reference/ceiling/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; 13 pages/15 ranges/18,697 of 18,697 source lines exactly once at SHA-256 3757214f...; largest Chapter 14 part 2,726/192,166/303-byte line; SUMMARY 51/2,765/depth 1; book aggregate 50/47,492/2,518,178 with exact delta +12/+59/+2,498; focused Files=6/Tests=75; trees=3/nodes=899/segments=1/index archives=1/migrations=1; 19 surfaces/2,800 paths; rationale 2,845 entries; Knowledge Map 1,096/5,762; Memory 40; all 49 chapters; removed build 85/17,695,227; line/byte ceilings ratchet to targets with zero increases; product behavior unchanged; `.9` next |
| `2026-08-01` | `.9` activation | clean `dc1c64afb` predecessor; exact roadmap identity; task/index/roadmap/book/fact/Memory sync; path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; activation source 10,451/772,074/longest 2,297/SHA-256 6c7e00fe...; focused Files=5/Tests=72; trees=3/nodes=899/segments=1/index archives=1/migrations=1; 19 surfaces/2,800 paths; reference delta 0/+5/+310; Knowledge Map 1,096/5,762; Memory 42; all 49 chapters; removed build 85/17,697,234; zero ceiling increases; only the bounded final frontier sentence changes; `.9` alone active; no direction claim, history, link, limit, generated artifact, or product behavior change |
| `2026-08-01` | `.9` bounded roadmap | complete six-range disposition; exact activation-source descriptor; required-history retrieval adapter; bounded strategic view; negative chronology/route/identity/pressure controls; root/roadmap ratchet; rationale append; focused/path/task/live-size/reference/ceiling/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; source 10,451/772,074/longest 2,297/SHA-256 6c7e00fe...; live 317/14,606/longest 182 at 49.5% derived peak; root 18/18,387/6,294,386 with ceiling lowered to 6,556,530; focused Files=8/Tests=87; trees=3/nodes=899/segments=1/index archives=1/migrations=1; 19 surfaces/2,800 paths split 4 migrated/6 deferred/6 steady; rationale 2,846 entries; reference delta 0/+4/+269; Knowledge Map 1,096/5,762; Memory 41; all 49 chapters; removed build 85/17,698,695; zero ceiling increases; product behavior unchanged; `.10` next |
| `2026-08-01` | `.10` activation | clean `a20d38afc` predecessor; exact canonical-card and generated-map identities; task/index/book/fact/Memory continuity; redundant-row and stale-headroom correction; path/task/live-size/Knowledge Map/Memory/mdBook/staged-acceptance/doctrine gates; exact cleanup | `passed`; source cards 1,097/42,116/3,214,095 with max 855/62,994/5,498-byte line; map byte-identical at 15,637/6,152,312/10,275-byte line/SHA-256 aa8fb21b... and 1,096 facts/5,762 keys; focused Files=5/Tests=72; trees=3/nodes=899/segments=1/index archives=1/migrations=1; 19 surfaces/2,800 paths; reference delta 0/+5/+304; Memory 41; all 49 chapters; removed build 85/17,701,192; root baseline/ceiling -2 bytes and zero ceiling increases; no card split, topology/query/cache/limit increase, or product behavior change |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.1: activate common enforcement` | Activate `.2` from the clean doctrine-selection commit without implementing it. |
| `.2` common enforcement | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2: enforce live-document containment` | Ship neutral JSONL checker contract/core plus FSMGen data and unconditional ninth-doctrine coverage; next clean selection is `.6`. |
| `.3` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3: activate retained-ledger schema` | Activate only the decision-0046 common schema from clean audit commit `b443957c1a`; implementation remains pending. |
| `.3` retained-ledger schema | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.3: enforce bounded retained-ledger history` | Ship the finite opt-in whole-entry/current-index/reconstruction/archive-transition contract without migrating either selected ledger; `.4` is next. |
| `.4` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4: activate changelog migration` | Activate only the bounded CHANGES.md whole-entry migration from clean schema commit `e47b509c9`; content movement remains pending. |
| `.4` director deferral | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.4: defer changelog lifecycle decision` | Reopen present value before migration and preserve the append-anchor flaw for a later retain-versus-supersede decision; no lifecycle is selected. |
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
| `.20` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.20: activate scoped currency contracts` | Confirm the supplied paths exactly match the disposed reviews and activate only opt-in lifecycle currency from clean `.19`. |
| `.20` scoped currency | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.20: enforce scoped currency contracts` | Add opt-in named local currency oracles, exempt terminal/frozen history, and calibrate FSMGen's active index to source alignment rather than date shape. |
| `.21` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21: activate route and index completeness` | Activate only typed routes, complete collection indexes, and evidence-map checking from clean `.20` commit `8cf8263a2`; implementation remains pending. |
| `.21` route/index/evidence completeness | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.21: close route and index completeness` | Derive typed author hints, retain distinct reader routes, prove collection index/query/generated contracts and both evidence maps, and reject staged-result divergence. |
| `.22` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22: activate migration and retention proof` | Activate only migration completeness, retention guarantees, and bounded review-front-door enforcement from clean `.21` commit `9c63cf76b`; implementation remains pending. |
| `.22` migration/retention proof | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.22: enforce migration and retention proof` | Prove four independent migration products, bind version objects to bounded recovery contracts, and freeze the detailed packet behind a bounded routed front door. |
| `.23` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23: activate maintained-reference selection` | Activate only the maintained product-reference lifecycle and classification contract from clean `.22` commit `2bfb32c02`; implementation remains pending. |
| `.23` maintained-reference contract | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.23: enforce maintained-reference contracts` | Bound the mandatory read and every part, authorize exact aggregate change, classify the mdBook, and preserve ISF-spec debt without deleting unique prose. |
| `.15` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15: activate common JSONL bounds` | Activate only common-control-plane inventory and finite schema pressure from clean `.23` commit `425cd7fef`; implementation remains pending. |
| `.15` common JSONL bounds | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.15: enforce common JSONL bounds` | Self-bound every common registry, cap fields/arrays, and add deterministic maximum-content-line-byte pressure without widening a predecessor ceiling. |
| `.16` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16: activate utility and retirement audit` | Activate only the evidence-backed retain/merge/supersede/archive/delete/re-form audit from clean `.15`; audit remains pending. |
| `.16` utility/retirement audit | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16: audit utility before containment` | Select evidence-backed outcomes for every family, assign guide/WARP follow-ups, and require fail-closed deletion proof without deleting a file. |
| `.24` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.24: activate guide-waypoint supersession` | Activate only the independent USER_GUIDE/BOOK_PLAN proof from clean `.16`; candidate and consumer changes remain pending. |
| `.24` guide-waypoint supersession | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.24: supersede completed guide waypoints` | Preserve unique book content, redirect all live consumers, remove both completed waypoints, and retain exact Git recovery. |
| `.25` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.25: activate WARP bootstrap re-form` | Activate only WARP claim/consumer/replacement proof from clean `.24`; bootstrap changes remain pending. |
| `.25` WARP retirement | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.25: retire unused WARP bootstrap` | Delete the unused harness bootstrap after exact content/consumer proof, enforce its absence, and retain exact Git recovery. |
| `.11` roadmap-status audit | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11: audit roadmap-status value` | Preserve the frozen object, classify present value and every consumer independently, recommend retirement, and await the director's retain/retire/re-form selection. |
| `.11` roadmap-status retirement | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.11: retire roadmap-status board` | Preserve exact Git recovery, retire the false combined live board and its consumers without replacement, close `.11`, and leave `.5` as the next clean selection. |
| `.5` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5: activate rationale-ledger migration` | Activate only the bounded conditional-rationale migration from clean `.11`; source entries and ledger topology remain unchanged. |
| `.5` bounded rationale ledger | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.5: bound engineering rationale ledger` | Preserve the exact immutable source as the ledger prefix, prove a real first append, and keep the root current/index views bounded. |
| `.8` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8: activate Chapter 14 partition` | Activate only stable-topic partitioning from the clean `.5` commit; chapter content and navigation remain unchanged. |
| `.8` Chapter 14 partition | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.8: partition Chapter 14 by topic` | Preserve all 18,697 source lines exactly once across 13 direct stable-topic pages, retain compatibility links, and return the former monolith below per-part warning budgets. |
| `.9` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9: activate roadmap/chronology separation` | Activate only the exact roadmap classification and disposition proof from clean `.8`; roadmap content and topology remain unchanged. |
| `.9` bounded roadmap | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.9: bound roadmap and retain chronology` | Retain strategy in a 317-line live view and preserve the exact 10,451-line activation object through a descriptor-backed, executed Git recovery contract. |
| `.10` activation | `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.10: activate bounded knowledge discovery` | Activate only canonical-card fact-boundary containment and sharded query-first projection work from clean `.9`; topology and lookup behavior remain pending. |

## Changelog

- `2026-08-01`: Clean `.9` commit `a20d38afc` activates `.10` alone and fixes
  the exact 1,097-card / 15,637-line generated-map source. No card split,
  projection shard, query/cache behavior, pressure limit, or product behavior
  changes in this selection slice.

- `2026-08-01`: `.9` separates strategic direction from exact chronology. The
  live roadmap becomes 317 lines with `R8`–`R14`, dependencies, concise
  outcomes, and `H1`–`H6`; a fail-closed descriptor/verifier preserves the
  complete 10,451-line source. `.10` is the next clean selection.

- `2026-08-01`: Clean `.8` commit `dc1c64afb` activates `.9` alone for bounded
  live-roadmap direction versus separately proved chronology. The exact source
  stays addressable and only the bounded frontier sentence changes; migration
  remains pending.

- `2026-08-01`: `.8` partitions the exact activation-source Chapter 14 into
  thirteen direct stable-topic pages. A 15-range proof accounts for every
  source line once, SUMMARY remains below its warning boundary at 51/64 lines,
  and the established backend deep-link remains valid. `.9` is the next clean
  selection.

- `2026-08-01`: Clean `.5` commit `2e572d9fd` activates `.8` alone for stable-
  topic partitioning of Chapter 14. The selection changes only continuity;
  implementation and user-facing navigation remain pending.

- `2026-08-01`: `.5` migrates the retained conditional rationale history to an
  exact descriptor-backed source prefix, bounded current/index views, and an
  executed first-append reconstruction proof. The 2,843 historical entries
  remain version-retrievable; only durable rationale without a better home may
  grow the current suffix. `.8` is the next clean PNT selection.

- `2026-08-01`: Clean `.11` commit `3084d8c7b` activates `.5` alone for the
  bounded conditional rationale-ledger migration. The selection changes no
  rationale entry, registry topology, checker, limit, or product behavior.

- `2026-08-01`: `.11` independently retires the former roadmap-status board
  under decision `0049`. Exact historical prose remains verifier-protected in
  Git; maintained roadmap, task, Memory, book, and Git authorities replace its
  current claims without another generated or hand-maintained status view.

- `2026-08-01`: `.11` independently audits `ROADMAP_STATUS.md` after the
  achievement-journal retirement. The exact frozen object and every lifecycle
  consumer remain unchanged; the audit recommends retirement, records direct
  historical browsing as the sole distinct value, and awaits the director's
  retain/retire/re-form selection.

- `2026-07-31`: Clean selection commit `139efbf90` activates `.1` continuity;
  `.2` becomes the sole active common-registry/checker implementation leaf.
- `2026-07-31`: `.2` ships strict JSONL common enforcement over 20 surfaces
  and the complete tracked-Markdown inventory while preserving README's
  landing content, all existing hard limits/topologies, frozen identities, and
  product behavior; `.6` is the next clean selection frontier.
- `2026-08-01`: `.3` adds finite opt-in ledger manifests with bounded current
  and index views, contiguous whole-entry range identity, exact source-entry
  reconstruction, content-addressed seals, and descriptor-backed live-history
  transition limits. Neither project ledger nor frozen status file migrates.
- `2026-07-31`: `.15` self-bounds every common JSONL registry and adds the
  sixth maximum-content-line-byte pressure axis; all predecessor ceilings,
  document lifecycles, frozen identities, landing content, and product behavior
  remain unchanged, and `.16` is the next clean selection frontier.
- `2026-07-31`: clean `.15` commit `2e10cc605` activates `.16` alone for the
  utility/retirement audit; no outcome, migration, retirement, deletion,
  enforcement, document lifecycle/content, or product behavior changes.
- `2026-07-31`: `.16` publishes the family-by-family utility audit, preserves
  current ISF/book/doctrine roles, selects structural re-forms, and assigns
  guide-waypoint supersession plus WARP compaction to `.24`/`.25`; the audit
  itself deletes or moves nothing.
- `2026-07-31`: Clean `.16` commit `b9f2f266c` activates `.24` alone; neither
  guide waypoint nor any consumer/replacement changes in this selection slice.
- `2026-07-31`: `.24` proves both completed guide waypoints independently,
  moves the only unique link/rule into the book, redirects all live consumers,
  removes the obsolete files, and preserves exact Git recovery.
- `2026-07-31`: Clean `.24` commit `984448936` activates `.25` alone; WARP,
  bootstrap enforcement, tool-neutral authority, and workflows stay unchanged.
- `2026-07-31`: `.25` confirms no unique WARP guidance or active consumer,
  deletes the unused harness bootstrap at the director's instruction, enforces
  its absence, and preserves the exact source object in Git history.
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
- `2026-07-31`: The supplied review paths reproduce the exact `.17` PGEN/ANVIL
  hashes, so no disposition changes. Clean `.19` commit `25c815326` activates
  `.20` alone; currency schema, verifier, lifecycle, and behavior remain pending.
- `2026-07-31`: `.20` adds optional named currency oracles with executed core/
  adapter proofs, bans current-state claims on terminal/frozen history, and
  applies one real task-index/source-alignment contract without globally
  scanning dates or claiming semantic truth from boundedness.
- `2026-07-31`: Clean `.20` commit `8cf8263a2` activates `.21` alone for typed
  author/reader routes plus index/evidence-map completeness; activation changes
  no checker, registry, document, frozen identity, or product behavior.
- `2026-07-31`: `.21` derives four author-overflow hints from the enforcer,
  retains 15 reader routes, proves six indexed collection contracts and 22
  review-evidence paths, and closes staged-result/worktree divergence.
- `2026-07-31`: The first staged broad gate stopped at the default RAM guard as
  required. Root-cause evidence shows its macOS host formula ignores reclaimable
  inactive memory (98.3% computed use versus 83% free from `memory_pressure`);
  the proposed `AGENT-RUNTIME-RAM-GUARD-MACOS-METRIC-REFINEMENT` task already
  owns the correction and retains its explicit director-approval blocker.
- `2026-07-31`: Clean `.21` commit `9c63cf76b` activates `.22` alone; no
  implementation or behavior changes in this selection slice.
- `2026-07-31`: `.22` proves exact source, semantic closure, working-set size,
  and zero unretained residue independently; history-backed objects name
  actionable retention contracts, and the frozen packet now sits behind a
  bounded review front door. `.23` is the next clean selection frontier.
- `2026-07-31`: Clean `.22` commit `2bfb32c02` activates `.23` alone; no
  lifecycle selection, enforcement, document content, or product behavior
  changes in this selection slice.
- `2026-07-31`: Decision 0045 and `.23` add maintained-reference classification,
  bounded mandatory/direct/per-part reading, exact persistent aggregate-change
  authority, and mdBook/ISF examples; `.15` is the next clean frontier.
- `2026-07-31`: Clean `.23` commit `425cd7fef` activates `.15` alone; common
  JSONL inventory, schema, and enforcement remain pending.
- `2026-07-31`: An initial mdBook destination argument resolved outside the
  repository. The exact 73-file/17,012-KiB output and its newly created empty
  parent were removed; the corrected repository-local build passed and was
  also removed, with residue checks for both paths.
