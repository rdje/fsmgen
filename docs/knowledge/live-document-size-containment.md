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
date: 2026-07-31
status: current
tags: [documentation, doctrine, continuity, size, sharding, rollover, archive, harness-neutral]
evidence: LIVE_DOCUMENT_SIZE_CONTAINMENT.md; live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md; live-document-size/scripts/check_live_document_size.pl; doctrine/live_document_size/surfaces.jsonl; doctrine/live_document_size/ceiling_increase_authorities.jsonl; doctrine/live_document_size/archive_descriptors.jsonl; doctrine/readme_entrypoint/routed_destinations.jsonl; scripts/check_live_document_size.sh; scripts/check_live_document_ceiling_authority.pl; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_DISPOSITION.md; docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md; docs/decisions/0044-external-live-document-review-corrections-precede-wider-reuse.md; docs/tasks/README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md; docs/decisions/0007-memory-architecture-supersedes-blob-narration.md; docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md; docs/decisions/0025-project-document-interim-lifecycle.md; docs/decisions/0040-readme-routing-must-close-destination-pressure.md
reverify: scripts/check_live_document_size.sh && prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t
---

`LIVE_DOCUMENT_SIZE_CONTAINMENT.md` is the project-owned doctrine. Its reusable
body is project-neutral, project-agnostic, and harness-neutral; FSMGen authority,
80/90/100 milestones, same-volume rule, measurements, paths, and migration
owners live only in its fenced adoption note, the local audit, and JSONL data
registries.

The central rule is “bounded live view over an addressable durable store.”
Current state overwrites, maintained user reference stays in navigable semantic
partitions, generated projections shard from small canonical sources, rolling
ledgers rotate and later archive, and exact old evidence uses an immutable
query-first terminal with digest/retrieval proof. Sharding alone is insufficient:
collections also need file-count and aggregate transitions.

Decision 0041 accepts the architecture. The measured revision and exact family
owners are in `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md`. Leaf `.2` uses
JSONL because one named object per line preserves streaming/diff behavior while
replacing a brittle 22-column positional prototype with typed nested pressure,
arrays, `null`, and strict unknown-key failure. The neutral checker inventories
all tracked Markdown, including the GitHub README landing page itself, and
enforces locality, lifecycle, pressure, non-worsening transition baselines,
routes, projections, frozen identities, and archive descriptors before any
family migration. Decision `0042` and `.6` now define optional bounded,
exact-provenance task segments and compact terminals without migrating an
existing tree; `.7` owns the first IAL2/outlier/index migration.
Clean bounded-history commit `78adb81ae` activates `.7` alone; the activation
does not yet move a task node or cross-tree index row.

Implementation `.7` seals all 844 terminal IAL2 children from exact revision
`44b5f159789ba1c31b487c6b047097bb27a9770d`, retaining an 85-line live root and
one exact-capped content-addressed segment. It also replaces 540 unique terminal
index rows with a 523-byte bounded JSONL version-object manifest while keeping
three active and eleven proposed rows live. The index falls from 1,078 to 558
lines; both registered task surfaces are now `normal`, and no completed task
file or README landing content is removed.

User-directed leaf `.14` publishes a self-contained external review packet
covering the doctrine, JSONL data plane, task-tree migration, evidence,
limitations, 31 structured feedback questions, and a response template.
The packet makes utility precede containment: review each surface for
retain/merge/supersede/archive/delete before partitioning it. It illustrates
the distinction with current FSMGen measurements, including the likely
supersession of the mdBook compatibility guide, the frozen status candidates,
the rationale/change ledgers, the generated Knowledge Map, and focused
contract/audit collections. No file is deleted by the review task.

The same review found two mechanical gaps. Specialized task manifests enforce
their own record/byte caps, but the common surface, route, archive, and ceiling-
authority JSONL registries do not yet self-bound; leaf `.15` owns that gap.
Leaf `.16` owns the general utility/retirement audit.

PGEN and ANVIL returned independent reviews of the packet. Completed leaf `.17`
publishes an evidence-backed accept/refine/reject/already-satisfied disposition
and decomposes accepted corrections before `.15`-`.23` change enforcement or
document lifecycle.

Decision `0044` and the bounded disposition accept both reviews with local
refinements. The apparent 15,727-line IAL2 loss is a packet-accounting defect:
the exact 21,726-line former file remains retrievable, the 5,914-line segment
independently preserves all 844 authoritative nodes, and the 85-line live root
is a new overlapping view. Path coverage is only classification; 86.8% of the
named non-generated candidate bytes remain frozen or deferred. Real gaps are
split across `.15`-`.23`: finite/reviewable control data, utility plus `re-form`,
health targets versus inclusive ceilings, executed verifiers, scoped currency,
typed route/index/evidence completeness, retention/migration evidence, and the
maintained-product-reference lifecycle. Neutral checker identity is already
mechanically scanned by `t/1554`.

Leaf `.18` now distinguishes reviewed health targets from inclusive
enforcement ceilings. Warning and rollover use target pressure; only
`actual > ceiling` fails, so equality is valid without implying health.
Debt keeps an immutable baseline, a bounded allowance below its ceiling, and a
two-step ratchet band that forces the ceiling down after one atomic shrinkage
step. Any increase must match one newly appended authority row and a newly
added decision in the same Git change; lowering is free. The implementation
raises no predecessor ceiling. Output names actual/target/ceiling values and
separately summarizes two migrated surfaces, nine pinned/deferred surfaces,
and five steady measured surfaces, avoiding a false claim that complete path
classification means containment is complete.
