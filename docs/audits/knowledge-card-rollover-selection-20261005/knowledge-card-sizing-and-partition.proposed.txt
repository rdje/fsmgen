---
id: knowledge-card-sizing-and-partition
title: One fact card is bounded per file; a multi-topic card becomes the surface's binding constraint
answers:
  - "how big may one knowledge fact card be?"
  - "what are the per-card line byte and length limits for a fact card?"
  - "card line width exceeds 819"
  - "when should I split a knowledge fact card?"
  - "how do I partition an oversized fact card?"
  - "how do I prove a fact card split lost no answer?"
  - "why is the knowledge_cards surface reported at 80.0% but still normal?"
  - "what pins the knowledge_cards line_bytes_each dimension?"
  - "does splitting a fact card break links to its id?"
  - "surface knowledge_cards is at 80.0% and must declare warning_debt"
date: 2026-10-05
status: current
tags: [knowledge-map, live-document-size, doctrine, containment, retrieval]
evidence: >-
  knowledge-map/scripts/knowledge_map.pl;
  knowledge-map/scripts/check_knowledge_map.sh;
  knowledge-map/KNOWLEDGE_MAP_ARCHITECTURE.md;
  doctrine/live_document_size/surfaces.jsonl;
  live-document-size/scripts/check_live_document_size.pl;
  docs/tasks/KNOWLEDGE-CARD-SURFACE-ALLOWANCE-EXHAUSTION.md
reverify: >-
  python3 -B docs/audits/knowledge-card-rollover-20261005/verify.py --current
---

Each card has independent line, original encoded-byte and content-line-byte
limits. The default Knowledge Map profile is 512 logical lines, 32,768 bytes
and 819 content-line bytes. The containment surface separately declares
per-file limits and file-count/aggregate bounds. Its line measurement counts
completed LF bytes; a final unterminated line still counts in the card checker.
Read configuration and both public checkers before assigning a failure cause.

The default card-width limit is below containment's 80% line-width warning
boundary. That says nothing about the other pressure axes or the surface's
health. Maximum-file bytes, aggregate bytes, lines, file count and the owned
transition allowance can bind independently. Splitting a large card can reduce
per-file pressure while increasing aggregate overhead and file count. Do not
infer aggregate growth permission from one card's remaining bytes.

Partition by semantic topic while preserving the original ID/path, all unique
facts, questions and cross-links. Compare complete question-to-ID/path rows,
not only totals: totals alone cannot expose swapped ownership or replaced
questions. A redistribution-only split preserves unique questions and answer
occurrences, and adds only the declared new fact members. New question routes
need their own explicit expected delta. Inspect current authority before
demoting a duplicate; dated history remains exactly retrievable. Live topic
partitioning needs no archive descriptor, but moving bytes out of the live
collection does require one. Aggregate rollover and retrieval must land atomically.

Related: [[live-document-surface-growth-procedure]],
[[live-document-size-containment]].

Retrieve the complete dated predecessor from the repository root:

```sh
python3 -B docs/audits/knowledge-card-rollover-selection-20261005/read_source.py knowledge-card-sizing-and-partition
```
