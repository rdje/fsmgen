---
id: task-tree-sealed-segments-and-compact-terminals
title: Long-running task trees use exact-provenance sealed segments or compact terminals
answers:
  - "how can a task-tree file be bounded without losing completed nodes?"
  - "what is a task-tree sealed subtree segment?"
  - "what is the task-tree segment manifest format?"
  - "how are sealed task-tree nodes proved immutable?"
  - "what is a compact completed task-tree terminal?"
  - "does PNT need to read archived task-tree history?"
  - "are existing task trees required to migrate to segments?"
  - "where did the completed task-tree index rows go?"
date: 2026-07-31
status: current
tags: [task-tree, continuity, containment, jsonl, segment, archive, provenance]
evidence: docs/decisions/0042-task-trees-seal-completed-subtrees-with-exact-provenance.md; docs/TASK_TREE.md; docs/TASK_TREE_README.md; docs/tasks/TEMPLATE.md; scripts/check_task_tree_integrity.pl; t/1549-task-tree-integrity-doctrine.t; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md
reverify: prove -Iperl t/1549-task-tree-integrity-doctrine.t && scripts/check_task_tree_integrity.pl
---

Decision `0042` keeps the live task Markdown file as the readable front door:
metadata, the top-level root, every nonterminal node, and every ancestor needed
to reach the frontier stay live. PNT therefore never consults archived history.

When a long-running tree approaches its local pressure budget, one optional
repository-relative JSONL manifest may address content-named Markdown segments.
The manifest declares finite record/byte bounds for itself plus independent
per-segment and aggregate node/line/byte bounds, so sharding cannot merely move
the pressure. Every segment record carries disjoint completed-subtree roots,
node count, SHA-256, and the exact source revision/path. The checker requires
the segment filename to equal its digest, proves every node matches its exact-
source node, requires each named root's full source subtree, then validates one
combined ID/ancestry/child/status/evidence graph across the live file and
segments.

A fully completed subtree can instead remain as one compact `version_object`
terminal. Its exact revision/path, retrieved-file digest, archived-node count,
goal, verification, and commit reference let the checker reload and validate
the whole terminal subtree through git. Missing revisions, digest or count
drift, nonterminal archived nodes, broken child closure, and pending leaf
evidence all fail closed.

Both forms are optional. Existing one-file trees remain valid. `.7` performs
the first migration: one exact-source segment now holds all 844 terminal IAL2
children while the 85-line live task file retains its active root. A separate
bounded JSONL version-object manifest seals 540 unique terminal index rows;
the live 558-line index contains only active/proposed selection plus retrieval
instructions. The checker reconstructs 882 nodes and proves one segment plus
one completed-index archive. Completed task files remain directly browsable.
