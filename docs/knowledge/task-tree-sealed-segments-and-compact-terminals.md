---
id: task-tree-sealed-segments-and-compact-terminals
title: Long-running task trees use exact-provenance sealed segments or compact terminals
answers:
  - "where is older semantic-introspection task acceptance evidence?"
  - "how is completed task acceptance history retained?"
  - "can a compact task terminal contain older compact terminals?"
  - "how can a task-tree file be bounded without losing completed nodes?"
  - "what is a task-tree sealed subtree segment?"
  - "what is the task-tree segment manifest format?"
  - "how are sealed task-tree nodes proved immutable?"
  - "what is a compact completed task-tree terminal?"
  - "does PNT need to read archived task-tree history?"
  - "are existing task trees required to migrate to segments?"
  - "where did the completed task-tree index rows go?"
  - "what retention contract does a task-tree version object require?"
  - "how is task-tree migration completeness proved?"
  - "can completed live claim owners become compact task terminals?"
date: 2026-09-27
status: current
tags: [task-tree, continuity, containment, jsonl, segment, archive, provenance]
evidence: docs/tasks/history/SEMANTIC-INTROSPECTION-MCP-FRONTIER/acceptance-history.jsonl; docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl; docs/decisions/0042-task-trees-seal-completed-subtrees-with-exact-provenance.md; docs/TASK_TREE.md; docs/TASK_TREE_README.md; docs/tasks/TEMPLATE.md; scripts/check_task_tree_integrity.pl; scripts/check_claim_verification.pl; t/1549-task-tree-integrity-doctrine.t; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md
reverify: scripts/check_task_tree_integrity.pl && scripts/check_claim_verification.pl
---

Decision `0042` keeps active nodes and frontier ancestry in the live task tree. Sealed segments require exact source equality, disjoint complete terminal roots,
finite per-part/aggregate bounds and one validated combined graph. A compact `version_object` retains its original goal, full revision/path/file digest,
node count, named retention contract, closed verification and commit evidence.
Before compaction, census live registry owners; keep every live `owner_task` ID.

Current compact retrieval validates retrieved leaves as ordinary leaves. Nested compact terminals lack the required Acceptance field and reject. Keep
those terminals live and select a flat completed subtree; the checker remains
unchanged. Exact failed-candidate bytes, diagnostics, restoration and a fresh
flat-owner census: `docs/audits/native-proxy-release-interruption-contract-20260911/compaction-review.json`.

A finite acceptance-history manifest can authenticate an exact committed task suffix by full-source and suffix digests, dimensions, heading and retention contract. Its source revision also retains the previous manifest, preserving the history chain. The live task keeps all node IDs and its precise next action; a changed suffix digest fails the unchanged integrity checker.

The semantic-introspection tree retains its node graph and current controller
sequence in the live file. Its historical suffix beginning at `Decisions` is
bound to the complete `03d65d6428eb4e34f294c6b71ea7bed185c39895` predecessor by
`docs/tasks/history/SEMANTIC-INTROSPECTION-MCP-FRONTIER/acceptance-history.jsonl`.
The live pointer retains active scope/runtime limits and the unresolved native
containment occurrence. The suffix and complete predecessor overlap; this is
exact retrieval, with no discarded historical residue or behavior change.

History: `da27b5cbaf01af7cbe294c8f851c8273dd750856:docs/knowledge/task-tree-sealed-segments-and-compact-terminals.md`.
That source preserves full segment/manifest/migration contracts and initial
migration measurements. Both forms remain optional; ordinary one-file trees
stay valid, and PNT selects current work only from live nodes.
