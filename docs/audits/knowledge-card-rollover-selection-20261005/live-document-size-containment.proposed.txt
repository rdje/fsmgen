---
id: live-document-size-containment
title: Live documents use bounded views over durable stores
answers:
  - "how are live-document sizes contained project-wide?"
  - "what happens when a live document reaches its size warning?"
  - "where does old changelog or task-tree history go?"
  - "does sharding alone contain documentation growth?"
  - "how is archived document content proved retrievable?"
  - "is the live-document doctrine project neutral?"
  - "is the live-document doctrine harness neutral?"
  - "where are FSMGen live-document measurements recorded?"
  - "what format does the live-document registry use?"
  - "why does the live-document registry use JSONL instead of TSV?"
  - "does the project-wide checker cover README.md itself?"
  - "which tasks own the large roadmap, task, book, changelog, development notes, and knowledge map migrations?"
  - "where is the external review packet for live-document containment?"
  - "should an obsolete live document be partitioned or retired?"
  - "which FSMGen live documents are retirement candidates?"
  - "are the common JSONL control-plane registries independently bounded?"
  - "does hard_pct currently enforce the hard pressure threshold?"
  - "what did PGEN and ANVIL find in the live-document review?"
  - "were 15727 IAL2 task lines lost during task-tree sealing?"
  - "does tracked-document coverage prove that documents are healthy?"
  - "is neutral live-document checker identity mechanically tested?"
  - "how are health targets different from transition ceilings?"
  - "how is an enforcement ceiling increase authorized?"
  - "which live-document families are migrated versus pinned or deferred?"
  - "are declared live-document freshness verifiers actually executed?"
  - "how are adapter live-document verifiers proved reachable from CI?"
  - "does live-document size compliance prove that a document is current?"
  - "how are live-document currency contracts declared?"
  - "does FSMGen use a global newest-date or distinct-date staleness check?"
  - "are author overflow routes different from reader navigation routes?"
  - "how are live-document collection indexes checked for completeness?"
  - "are external review evidence-map paths mechanically checked?"
  - "does the live-document doctrine inspect the staged resulting tree?"
  - "how does a live-document migration prove that no content was lost?"
  - "why are migration products not added as disjoint line counts?"
  - "what retention contract is required for a version object?"
  - "where is the bounded live-document architecture review front door?"
  - "how does maintained_reference bound reads and authorize product-sized mdBook or ISF_SPEC change without a fixed aggregate cap?"
  - "how does a bounded rolling ledger preserve whole-entry history and exact reconstruction?"
  - "how is the Knowledge Map kept bounded?"
  - "how do I query the Knowledge Map?"
  - "where does the Knowledge Map query cache live?"
  - "does a generated projection support deterministic shard collections?"
  - "where is the complete focused and ancillary document index?"
  - "how is the ISF reference partitioned?"
  - "why did T1569 fail after a maintained ISF reference edit?"
  - "how are mechanically exact current-state fields contained?"
  - "when must a live-document value be derived on read?"
  - "how is a deliberately retained derived-state copy verified?"
  - "is immutable task evidence the same as mutable current derived state?"
  - "what is the main downstream entry point for containment doctrine updates?"
  - "how are repeated task-tree acceptance checklists contained?"
  - "should integration tests hard-code the live-document surface count?"
  - "why can T1554 hang in a core verifier before startup?"
date: 2026-10-05
status: current
tags: [documentation, doctrine, continuity, size, derived-state, sharding, rollover, archive, harness-neutral]
evidence: >-
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  LIVE_DOCUMENT_SIZE_CONTAINMENT.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md; live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md; live-document-size/scripts/check_live_document_size.pl; doctrine/live_document_size/surfaces.jsonl; doctrine/live_document_size/derived_state_contracts.jsonl; doctrine/live_document_size/archive_descriptors.jsonl; doctrine/live_document_size/ledger_manifests.jsonl; doctrine/live_document_size/version_retention_contracts.jsonl;
  scripts/check_live_document_size.sh; scripts/run_live_document_adapter_verifiers.pl; scripts/check_live_document_resulting_tree.pl; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md; docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md; docs/decisions/0044-external-live-document-review-corrections-precede-wider-reuse.md; docs/decisions/0045-maintained-reference-bounds-the-read-path-not-product-scope.md; docs/decisions/0054-derived-state-is-derived-on-read-or-authority-verified.md;
  docs/decisions/0046-project-documents-use-two-bounded-ledgers-and-canonical-live-views.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md; docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl; scripts/check_task_tree_integrity.pl; knowledge-map/scripts/knowledge_map.pl; knowledge-map/scripts/query_knowledge_map.sh; scripts/check_knowledge_card_history.pl; t/1549-task-tree-integrity-doctrine.t; t/1554-live-document-size-doctrine.t; t/1567-knowledge-map-shards.t; t/1568-knowledge-card-history.t
  doctrine/live_document_size/isf_reference_partitions.jsonl; scripts/check_isf_reference_partitions.pl; scripts/focused_document_index.pl; docs/index/FOCUSED_DOCUMENTS.md; t/1569-focused-document-containment.t
reverify: >-
  python3 -B docs/audits/knowledge-card-rollover-20261005/verify.py --current
---

`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` owns the doctrine. Its reusable body is
project- and harness-neutral; FSMGen authority, 80/90/100 milestones, locality,
measurements, paths, and migration owners belong in the adoption fence, audit,
and JSONL registries.

Bounded live views address durable stores: overwrite current state, partition
user references by topic, shard projections from canonical cards, rotate and
archive ledgers, and retrieve immutable old evidence through query terminals
with digest proof. Sharded collections still need file-count/aggregate transitions.

The common checker alone owns the registered-surface count. Integration tests
assert its stable success phrase and numeric shape; only fixed synthetic
registries justify exact counts. T1553/T1554 enforce this distinction.

Decision `0054` requires `derive_on_read` to forbid the stored marker and put
the exact accessor in the reader's path. A `verified_copy` needs a named
authority, recomputation, and executed verifier for its contract/baseline/projection.
`doctrine/live_document_size/derived_state_contracts.jsonl` is the bounded
registry; the neutral core neither names project fields nor guesses from dates,
numbers, or prose.

`git log -1 --format='%H %s'` derives revision/subject; neither Memory nor its
template stores HEAD. `scripts/check_task_tree_integrity.pl` verifies the copied
active frontier, and maps check canonical-input freshness. Task/decision
measurements bound to revisions or invocations remain historical evidence.

`docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md` is the downstream
entry point, updated with every portable doctrine revision. It routes to the
doctrine/checker and keeps donor paths, fields, measurements, thresholds, and
migration decisions outside the portable body.

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

Declared `core:` verifiers execute and must succeed. Local `adapter:` verifiers
earn exact registry-derived proofs; missing, duplicate and unused proofs fail.
`external:` contracts expose degradation and cannot produce green. Currency is
lifecycle-specific and opt-in; size compliance does not prove currency or
semantic truth. There is no global age, newest-date or distinct-date heuristic.
The root doctrine's Boundedness, currency, and truth section and the declared
registry contracts own the current behavior.

Author-overflow and reader-navigation routes have different destinations.
Overflow may not append to immutable history. A complete collection front door
uses literal membership, a reproducible generated index, or an explicit target
query. Fenced evidence-map paths and staged/worktree identity are checked.
The root doctrine's Core invariant section and
`scripts/check_live_document_resulting_tree.pl` own these contracts.

Migration evidence separately proves complete-source identity, semantic
closure, live working-set dimensions and unretained residue. These products
may overlap; do not add them as disjoint line counts. Version objects require
a named retention owner, reachability or backup guarantee, and shallow-history
or rewrite recovery. File archives are digest checked. Read the root doctrine's
Atomic partition, rollover, and archive protocol and Archive descriptor contract.

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

Utility review precedes containment. Retention, merge, supersession, archive,
deletion or re-form needs source identity, classified consumers, named current
homes and genuine orphan controls. Decisions 0046-0049 and COMMIT.md own the
retired journals and live authority; no replacement status board is created.
The bounded review front door is `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md`.
Detailed adoption outcomes, external-review dispositions and exact historical
measurements remain in the adoption task tree, decision records and the complete
retained predecessor below.

The predecessor's T1554 `_dyld_start` observations are historical evidence,
not a current OS diagnosis or probe authorization. Current native/startup
qualification and full CI remain owned and gated by the HIAL/VIAL task tree.
Use that tree's live frontier before executing a historical recipe.

Every original question and the complete predecessor, including the adoption
chronology and superseded file-ceiling claim, remain retrievable without Git
history. From the repository root, run:

```sh
python3 -B docs/audits/knowledge-card-rollover-selection-20261005/read_source.py live-document-size-containment
```

The bounded source catalog names the exact captured revision and digest.
The archive-descriptor registry verifies each retained file; the rollover
reader verifies source, question, current-rule, collection and retrieval closure.
Historical statements retain their capture boundary and do not authorize writes.
