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
date: 2026-08-19
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
  knowledge-map/scripts/check_knowledge_map.sh &&
  scripts/check_live_document_size.sh 2>&1 | grep 'surface knowledge_cards:'
---

Each card is bounded on its own, not only in aggregate. The Knowledge Map
enforces `card_lines` 512, `card_bytes` 32,768, and `card_line_bytes` 819; the
`knowledge_cards` surface enforces `lines_each` 512, `bytes_each` 32,768, and
`line_bytes_each` 1,024. So the per-file byte bound, not the collection, is
what a large card actually hits.

Because the Knowledge Map rejects any card line wider than 819 bytes while the
surface target is 1,024, `line_bytes_each` is structurally pinned at 79.98% and
can never reach the surface's 80% warning milestone. That dimension is
therefore the standing reported peak — `target peak 80.0%` with state `normal`
is the healthy resting reading for this surface, not an imminent breach.

A card that accretes many topics is the failure mode. It becomes the surface's
binding `bytes_each` value and can drive the whole collection into
`rollover_debt` by itself, after which every unrelated edit must fit inside one
file's remaining bytes. Partition by topic before that happens.

To partition safely: keep the original `id` and path as the core card so
existing links and `[[id]]` references stay valid, move each topic to its own
card with only the evidence and `reverify` it needs, and cross-link both ways.
Prove closure mechanically rather than by reading — the Knowledge Map's
`unique questions` and `answer occurrences` totals must be **unchanged** while
`facts` rises by the number of new cards; a set diff of the `answers:` lists
before and after must be empty. Splitting is not an archive event, so no
archive descriptor is needed while the bytes stay in the live collection.

Related: [[live-document-surface-growth-procedure]],
[[live-document-size-containment]].
