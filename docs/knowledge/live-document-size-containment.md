---
id: live-document-size-containment
title: Live documents use bounded views over durable stores
answers:
  - how are live-document sizes contained project-wide?
  - what happens when a live document reaches its size warning?
  - where does old changelog or task-tree history go?
  - does sharding alone contain documentation growth?
  - how is archived document content proved retrievable?
  - is the live-document doctrine project neutral?
  - is the live-document doctrine harness neutral?
  - where are FSMGen live-document measurements recorded?
  - what format does the live-document registry use?
  - why does the live-document registry use JSONL instead of TSV?
  - does the project-wide checker cover README.md itself?
  - which tasks own the large roadmap, task, book, changelog, development notes, and knowledge map migrations?
  - where is the external review packet for live-document containment?
  - should an obsolete live document be partitioned or retired?
  - which FSMGen live documents are retirement candidates?
  - are the common JSONL control-plane registries independently bounded?
  - does hard_pct currently enforce the hard pressure threshold?
  - what did PGEN and ANVIL find in the live-document review?
  - were 15727 IAL2 task lines lost during task-tree sealing?
  - does tracked-document coverage prove that documents are healthy?
  - is neutral live-document checker identity mechanically tested?
  - how are health targets different from transition ceilings?
  - how is an enforcement ceiling increase authorized?
  - which live-document families are migrated versus pinned or deferred?
  - are declared live-document freshness verifiers actually executed?
  - how are adapter live-document verifiers proved reachable from CI?
  - does live-document size compliance prove that a document is current?
  - how are live-document currency contracts declared?
  - does FSMGen use a global newest-date or distinct-date staleness check?
  - are author overflow routes different from reader navigation routes?
  - how are live-document collection indexes checked for completeness?
  - are external review evidence-map paths mechanically checked?
  - does the live-document doctrine inspect the staged resulting tree?
  - how does a live-document migration prove that no content was lost?
  - why are migration products not added as disjoint line counts?
  - what retention contract is required for a version object?
  - where is the bounded live-document architecture review front door?
  - how does maintained_reference bound reads and authorize product-sized mdBook or ISF_SPEC change without a fixed aggregate cap?
  - how does a bounded rolling ledger preserve whole-entry history and exact reconstruction?
  - how is the Knowledge Map kept bounded?
  - how do I query the Knowledge Map?
  - where does the Knowledge Map query cache live?
  - does a generated projection support deterministic shard collections?
  - where is the complete focused and ancillary document index?
  - how is the ISF reference partitioned?
  - why did T1569 fail after a maintained ISF reference edit?
  - how are mechanically exact current-state fields contained?
  - when must a live-document value be derived on read?
  - how is a deliberately retained derived-state copy verified?
  - is immutable task evidence the same as mutable current derived state?
  - what is the main downstream entry point for containment doctrine updates?
  - how are repeated task-tree acceptance checklists contained?
  - should integration tests hard-code the live-document surface count?
  - why can T1554 hang in a core verifier before startup?
  - how is the ISF focused-test catalog kept synchronized?
  - why did T1250 fail after adding ISF tests?
date: 2026-10-25
status: current
tags: [documentation, doctrine, continuity, size, derived-state, sharding, rollover, archive, harness-neutral]
evidence: >-
  docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md; docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md; docs/audits/isf-focused-index-refresh-20261025/derivation.json; t/1250-isf-spec-focused-test-index-audit.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  LIVE_DOCUMENT_SIZE_CONTAINMENT.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md; live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md; live-document-size/scripts/check_live_document_size.pl; doctrine/live_document_size/surfaces.jsonl; doctrine/live_document_size/derived_state_contracts.jsonl; doctrine/live_document_size/archive_descriptors.jsonl; doctrine/live_document_size/ledger_manifests.jsonl; doctrine/live_document_size/version_retention_contracts.jsonl;
  scripts/check_live_document_size.sh; scripts/run_live_document_adapter_verifiers.pl; scripts/check_live_document_resulting_tree.pl; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md; docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md; docs/decisions/0044-external-live-document-review-corrections-precede-wider-reuse.md; docs/decisions/0045-maintained-reference-bounds-the-read-path-not-product-scope.md; docs/decisions/0054-derived-state-is-derived-on-read-or-authority-verified.md;
  docs/decisions/0046-project-documents-use-two-bounded-ledgers-and-canonical-live-views.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md; docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl; scripts/check_task_tree_integrity.pl; knowledge-map/scripts/knowledge_map.pl; knowledge-map/scripts/query_knowledge_map.sh; scripts/check_knowledge_card_history.pl; t/1549-task-tree-integrity-doctrine.t; t/1554-live-document-size-doctrine.t; t/1567-knowledge-map-shards.t; t/1568-knowledge-card-history.t
  doctrine/live_document_size/isf_reference_partitions.jsonl; scripts/check_isf_reference_partitions.pl; scripts/focused_document_index.pl; docs/index/FOCUSED_DOCUMENTS.md; t/1569-focused-document-containment.t
reverify: >-
  scripts/run_with_ram_guard.sh -- bash -c 'python3 -B docs/audits/knowledge-card-rollover-kinds-20261005/verify.py && scripts/check_live_document_size.sh && prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1569-focused-document-containment.t'
---

`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` is project- and harness-neutral. FSMGen
authority, 80/90/100 milestones, locality, measurements, paths and migration
owners belong in its adoption fence, audit and JSONL registries.

Live views overwrite state, partition references, shard canonical-card
projections, rotate/archive ledgers and retrieve immutable evidence through
query terminals with digest proof. Shards still need file-count/aggregate transitions.

Only the checker owns surface counts. T1553/T1554 require integration tests
to assert stable success/numeric shape; exact counts need fixed synthetic registries.

Decision `0054`: `derive_on_read` forbids stored markers and puts the exact
accessor in the reader path; `verified_copy` needs authority, recomputation and
an executed contract/baseline/projection verifier. The bounded registry is
`doctrine/live_document_size/derived_state_contracts.jsonl`; neutral core
names no project fields and infers nothing from dates/numbers/prose.

`git log -1 --format='%H %s'` derives revision/subject; Memory/template store no
HEAD. `scripts/check_task_tree_integrity.pl` verifies copied active frontier;
maps check canonical-input freshness. Revision/invocation-bound task/decision
measurements remain historical evidence.

`docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md` routes downstream to
doctrine/checker, updating with each portable revision. Donor paths, fields,
measurements, thresholds and migration decisions stay outside portable prose.

## Current enforcement and reader contracts

Health targets measure warning and rollover pressure; inclusive ceilings reject
only excess and do not establish health. Transition debt also has a separate
baseline-plus-allowance bound. Decision 0064 supersedes the adoption-era claim
that the knowledge-card file ceiling is occupied; decision 0070 requires the
declared rollover at rollover debt. Read current measurements with
`scripts/check_live_document_size.sh`, and use
[[live-document-surface-growth-procedure]],
[[live-document-transition-allowance-headroom]] and
[[knowledge-card-sizing-and-partition]] for the current write procedure.

The bounded JSONL control plane uses typed records, finite registries, scalar
and array bounds, unknown-key refusal, and an independent content-line-byte
axis. Source inventory includes the README landing page. Coverage proves
classification, not health. The root doctrine's Registry and mechanical
enforcement section and the public checker contract own these rules.

`core:` verifiers execute successfully; `adapter:` verifiers earn exact
registry-derived proofs (missing/duplicate/unused fail). `external:` exposes
degradation, never green. Currency is lifecycle-specific/opt-in; size proves
neither currency nor truth. No global age/newest-date/distinct-date heuristic.
Root doctrine: Boundedness, currency, and truth; declared registry contracts.

Author-overflow and reader-navigation routes have different destinations.
Overflow may not append to immutable history. A complete collection front door
uses literal membership, a reproducible generated index, or an explicit target
query. Fenced evidence-map paths and staged/worktree identity are checked.
The root doctrine's Core invariant section and
`scripts/check_live_document_resulting_tree.pl` own these contracts.

Migration proves complete-source identity, semantic closure, live dimensions
and unretained residue separately; overlapping products are not disjoint line
counts. Version objects need a retention owner, reachability/backup and shallow-
history/rewrite recovery; file archives need digest checks. Root doctrine:
Atomic partition, rollover, and archive protocol; Archive descriptor contract.

`maintained_reference` governs unique maintained product prose with semantic
parts, bounded complete mandatory navigation, per-part limits and exact fresh
aggregate-change authority; aggregate pressure caps are explicitly inapplicable.
Decision 0045 owns that distinction. Rolling ledgers instead preserve whole
entries, ordered sealed ranges and exact source reconstruction under declared
live-window and archive-transition bounds. Repeated task acceptance narration
uses finite authenticated history pointers while preserving the full node graph.
The root doctrine, ledger manifests and task-history manifests own these rules.

## Canonical views and historical evidence

The Knowledge Map keeps fact cards canonical, generates deterministic topic
shards, catalogues each fact once and assigns each question to one shard.
Shared questions link every matching fact. Its fixed-substring query wrapper
caches only disposable rows under `.artifacts/knowledge-map/query/` and checks
direct/cache parity. Query with
`knowledge-map/scripts/query_knowledge_map.sh 'question words'`; generated
shards and caches never own unique facts. The architecture and public checker
own the complete contract.

`docs/index/FOCUSED_DOCUMENTS.md` is the generated complete focused/ancillary
index. `doctrine/live_document_size/isf_reference_partitions.jsonl` and
`scripts/check_isf_reference_partitions.pl` own exact historical ISF sources
and current topic/navigation contracts. T1569 checks current structure;
activation reconstruction is a separate historical property. Current task
owners and family lifecycle state are read from `docs/TASK_TREE.md` and the
adoption tree, rather than copied completion counts.

T1250 compares `docs/isf-spec/04-reports-fixtures-deferrals.md` focused tests
with exact lexical `t/*-isf-*.t` membership. The reusable ISF checklist requires
sync on additions/renames/removals, preserving attached annotations.
`ISF-SPEC-TEST-INDEX-SYNC.4` retains omission/duplicate/order controls.

Utility review precedes containment: retention/merge/supersession/archive/
deletion/re-form needs source identity, classified consumers, current homes
and genuine orphan controls. Decisions0046-0049/COMMIT.md own retired journals
and live authority; no replacement board. Bounded review front door:
`docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md`. Adoption outcomes, external
review and historical measurements remain in the adoption tree, decisions
and complete predecessor below.

Historical T1554 `_dyld_start` observations neither diagnose the current OS
nor authorize probes; HIAL/VIAL owns their cause. Director-ordered SEM .69.3
CI/push/exact-SHA hosted qualification precedes macOS relevance review,
superseding the old blanket hold. Read its live owner before historical recipes.

Original questions and the complete predecessor (adoption chronology and
superseded file-ceiling claim included) remain retrievable without Git history:

```sh
python3 -B docs/audits/knowledge-card-rollover-selection-20261005/read_source.py live-document-size-containment
```

The bounded catalog names capture revision/digest. Archive descriptors verify
retained files; the rollover reader checks source/question/current-rule/collection/
retrieval closure. Historical statements retain capture boundaries, authorizing no writes.
The reverify command preserves the original rollover proof in historical mode;
normal containment and focused audits qualify current live evolution.
