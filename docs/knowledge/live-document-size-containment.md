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
date: 2026-07-31
status: current
tags: [documentation, doctrine, continuity, size, sharding, rollover, archive, harness-neutral]
evidence: LIVE_DOCUMENT_SIZE_CONTAINMENT.md; live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md; live-document-size/scripts/check_live_document_size.pl; doctrine/live_document_size/surfaces.jsonl; doctrine/live_document_size/ceiling_increase_authorities.jsonl; doctrine/live_document_size/archive_descriptors.jsonl; doctrine/live_document_size/evidence_maps.jsonl; doctrine/live_document_size/version_retention_contracts.jsonl; doctrine/readme_entrypoint/routed_destinations.jsonl; scripts/check_live_document_size.sh; scripts/run_live_document_adapter_verifiers.pl; scripts/check_live_document_route_candidates.pl; scripts/check_live_document_resulting_tree.pl; scripts/check_live_document_ceiling_authority.pl; scripts/check_live_document_reference_authority.pl; scripts/check_doctrine_bootstrap.sh; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_REVIEW.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_DISPOSITION.md; docs/tasks/segments/IAL2-FEATURE-COMPLETENESS-FRONTIER/migration.jsonl; docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md; docs/decisions/0044-external-live-document-review-corrections-precede-wider-reuse.md; docs/decisions/0045-maintained-reference-bounds-the-read-path-not-product-scope.md; docs/tasks/README-POLICY-ROUTED-DESTINATION-PRESSURE-CLOSURE.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md; docs/decisions/0007-memory-architecture-supersedes-blob-narration.md; docs/decisions/0019-task-tree-in-file-secondary-views-are-historical.md; docs/decisions/0025-project-document-interim-lifecycle.md; docs/decisions/0040-readme-routing-must-close-destination-pressure.md; t/1561-live-document-reference-authority.t
reverify: scripts/check_live_document_size.sh && prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t t/1561-live-document-reference-authority.t
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

The same review found two mechanical gaps. Completed leaf `.15` now gives every
common registry a bounded schema-versioned metadata row, finite record/file/
record-byte limits, field-specific scalar byte limits, identifier domains, and
array cardinalities. It also adds maximum Markdown content-line bytes as a
sixth pressure axis. Leaf `.16` owns the remaining general utility/retirement
audit.

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

Leaf `.19` replaces executable-presence checks with three explicit execution
modes. A `core:` program executes from the repository root and must return
zero. A registry-derived local `adapter:` program executes before the neutral
checker and earns one exact `surface:ID` or `archive:ID` proof; missing,
duplicate, and unused proofs fail closed. An `external:` contract is reported
as visible degradation and cannot yield green. The local wrapper invokes the
adapter runner unconditionally, while the bootstrap gate proves hosted CI
invokes the single doctrine driver rather than re-enumerating this check.

The rereferenced PGEN and ANVIL paths reproduce the exact sizes and SHA-256
identities already recorded by `.17`; they are not follow-up revisions. Leaf
`.20` now makes currency lifecycle-scoped and opt-in. A declared object names a
stable local contract plus a `core:`, `adapter:`, or fail-closed `external:`
verifier. FSMGen's active task index declares `active_task_tree_alignment` and
executes the existing task integrity oracle. Undeclared surfaces are not
scanned; archive/external/frozen terminals cannot claim current-state currency;
and no global newest-date, distinct-date, file-age, or semantic-truth inference
is made from size compliance.

Clean `.20` commit `8cf8263a2` activates `.21` alone for typed author-overflow
and reader-navigation routes, complete collection indexes, and mechanically
checked review evidence maps. Activation changes no enforcement or lifecycle.

Leaf `.21` now makes the distinctions executable. Route records carry an exact
kind and source path; the local scanner derives four author-overflow candidates
from the README guard's emitted messages, while 15 README destinations remain
reader navigation. Book and decision indexes prove literal membership; root,
ancillary, and task collections name registry-target queries; the Knowledge
Map names its executed generated surface. Fenced packet and disposition maps
resolve all 17 and 5 evidence paths. The Git adapter also rejects controlled
staged content that differs from the worktree supplied to the neutral core.

Leaf `.22` independently proves complete-source identity, semantic closure,
live working-set dimensions, and unretained residue. The IAL2 manifest verifies
the exact 21,726-line source, all 844 sealed nodes, a 6,002-line working set,
overlapping rather than partitioned products, and zero loss residue. Every
task-tree or generic archive version object now names a bounded contract whose
owner guarantees reachability/backup and supplies shallow/rewrite recovery;
missing history reports that recovery action. The 79-line review front door is
capped at 100 lines / 5 KiB and routes to the detailed 1,311-line packet, whose
SHA-256 is frozen as retained evidence.

Clean `.23` commit `425cd7fef` activated `.15` alone. The completed
implementation self-bounds common surface, route, evidence, retention,
archive, and ceiling-authority registries. Portable hard limits are 10,000 data
records, 16 MiB per registry, and 64 KiB per raw record; FSMGen declares tighter
local caps. All measured Markdown surfaces now report maximum content-line
bytes excluding LF and optional CR. The initial census found 10,275-byte
Knowledge Map, 7,542-byte mdBook, and 6,264-byte task-evidence rows, proving this
axis is independent from total lines and bytes. No predecessor ceiling rises.

Decision `0045` and `.23` now make `maintained_reference` distinct from
`partitioned_canonical`. Unique product/specification prose keeps fixed
per-part line/byte targets and ceilings, a complete mandatory index with
independent line/byte caps, and direct navigation. Fixed aggregate pressure
keys are explicit JSON `null` because legitimate scope follows the product;
exact aggregate files/lines/bytes remain governed by prior baseline plus a
signed current-work-unit delta. The Git adapter rejects missing, stale,
inexact, reused, or banked authority and silent lifecycle removal.

FSMGen applies the class to `docs/book/src/*.md`: `SUMMARY.md` is the bounded
mandatory read and all chapters remain direct members. Existing Chapter 14
per-part debt remains unchanged. The mixed `docs/*.md` collection carries an
auditable rationale naming `docs/ISF_SPEC.md` as a candidate only; its existing
debt and ceilings remain until `.13` supplies semantic parts and a complete
bounded index.

Clean `.15` commit `2e10cc605` activates `.16` alone for the project-wide
utility/retirement audit. No retain/merge/supersede/archive/delete/re-form
outcome, lifecycle, migration, retirement, deletion, or product behavior
changes in activation.

Completed `.16` now classifies all 22 governed surfaces before migration. It
retains current canonical ISF/book/task/decision/doctrine roles, selects
`re-form` for structural roadmap/map/spec/focused representations, preserves
the four-file lifecycle owner's authority, and assigns USER_GUIDE/BOOK_PLAN
supersession plus verbose WARP re-form to separate `.24`/`.25` leaves. Removal
requires fresh identity, whole-document token/ID residue, classified consumers
including code/tests/scripts, named replacements, planted negative controls,
retention where needed, and staged resulting-tree proof. The audit deletes and
migrates nothing.
