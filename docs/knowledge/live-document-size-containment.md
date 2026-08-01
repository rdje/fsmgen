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
date: 2026-08-01
status: current
tags: [documentation, doctrine, continuity, size, sharding, rollover, archive, harness-neutral]
evidence: >-
  LIVE_DOCUMENT_SIZE_CONTAINMENT.md; live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md; live-document-size/scripts/check_live_document_size.pl; doctrine/live_document_size/surfaces.jsonl; doctrine/live_document_size/archive_descriptors.jsonl; doctrine/live_document_size/ledger_manifests.jsonl; doctrine/live_document_size/version_retention_contracts.jsonl; scripts/check_live_document_size.sh; scripts/run_live_document_adapter_verifiers.pl; scripts/check_live_document_resulting_tree.pl; docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md; docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md; docs/decisions/0044-external-live-document-review-corrections-precede-wider-reuse.md; docs/decisions/0045-maintained-reference-bounds-the-read-path-not-product-scope.md;
  docs/decisions/0046-project-documents-use-two-bounded-ledgers-and-canonical-live-views.md; docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md; knowledge-map/scripts/knowledge_map.pl; knowledge-map/scripts/query_knowledge_map.sh; scripts/check_knowledge_card_history.pl; t/1554-live-document-size-doctrine.t; t/1567-knowledge-map-shards.t; t/1568-knowledge-card-history.t
  doctrine/live_document_size/isf_reference_partitions.jsonl; scripts/check_isf_reference_partitions.pl; scripts/focused_document_index.pl; docs/index/FOCUSED_DOCUMENTS.md; t/1569-focused-document-containment.t
reverify: >-
  scripts/check_live_document_size.sh && knowledge-map/scripts/check_knowledge_map.sh && scripts/check_knowledge_card_history.pl && prove -Iperl t/1553-readme-routed-destination-pressure.t t/1554-live-document-size-doctrine.t t/1560-live-document-ceiling-authority.t t/1561-live-document-reference-authority.t t/1567-knowledge-map-shards.t t/1568-knowledge-card-history.t
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
Debt keeps a baseline that cannot increase but may ratchet down after an atomic
content reduction, a bounded allowance below its ceiling, and a two-step band
that forces the ceiling down after shrinkage. Any ceiling increase must match
one newly appended authority row and a newly added decision in the same Git
change; lowering is free. The implementation
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
mandatory read and all chapters remain direct members. Leaf `.8` maps the exact
18,697-line activation source for Chapter 14 once into thirteen stable-topic
pages. `SUMMARY.md` remains at depth one and 51/64 lines; the largest new page
is 2,726 lines / 192,166 bytes, and the former backend anchor remains a routed
compatibility target. The mixed `docs/*.md` collection carries an auditable
rationale naming `docs/ISF_SPEC.md` as a candidate only; its existing debt and
ceilings remain until `.13` supplies semantic parts and a complete bounded
index.

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

Clean `.16` commit `b9f2f266c` activated `.24` alone. The completed proof
supersedes `docs/USER_GUIDE.md` and `docs/BOOK_PLAN.md`: exact source objects
remain recoverable from activation commit `65c646a12` under
`fsmgen_required_history`, while README, mdBook, manifest, test, and roadmap
consumers now point to canonical book homes. Fresh token sweeps enumerate 8 and
39 residues; planted orphans change those counts to 9 and 40 exactly.

Clean `.24` commit `984448936` and selection commit `f02da976f` activated `.25`
alone for WARP lifecycle resolution. The director subsequently confirmed that
warp.dev is no longer used, so the owned exact claim/consumer/canonical-home/
orphan/workflow proof selects deletion rather than a compact compatibility
pointer. The local bootstrap checker enforces absence while preserving all
remaining tool-neutral bootstrap checks and exact Git recovery.

Decision `0046` selected two ledgers; completed `.3` defines generic bounded
current, index, whole-entry, reconstruction, seal, and archive-transition
controls. Decision `0047` supersedes the changelog half after `.4` proved its
manual work-unit summary had no content or executable consumer independent of
task evidence, Git, Memory, facts/decisions, and the mdBook. The exact
32,299-line object remains deterministically retrievable from `329d7cf1b`
under `fsmgen_required_history`; the live path, write obligation, route, and
surface are retired without a replacement changelog. Pending `.26` retains the
broader agent-era document inventory. Completed `.11` independently retires
the two frozen status views. Completed `.5` bounds the rationale ledger: 2,843
entries at `d3c22e003` form its exact prefix, while the current view and index
hold and address later entries; the executed adapter rejects drift. Clean
activation commit `b88b37323` fixes Chapter 14's source, and completed `.8`
partitions it exactly once by stable user-facing topic. Clean `.8` commit
`dc1c64afb` activates `.9` alone and fixes the exact 10,451-line roadmap
activation source before direction/chronology classification. Completed `.9`
retains strategy, dependencies, concise outcomes, and horizons in a 317-line /
14,606-byte live view. Descriptor `roadmap-v2-pre-containment-2026-08-01` and
its executed adapter preserve and verify the complete original object.
Clean `.9` commit `a20d38afc` activates `.10` alone against the exact 1,097-card
/ 42,116-line / 3,214,095-byte canonical collection and its 15,637-line /
6,152,312-byte generated projection at SHA-256 `aa8fb21b...`. The activation
records the pre-migration identity.

Completed `.10` keeps cards canonical while bounding both write and read units.
The three activation cards above their retained limits are deterministically
re-formed as eleven stable cards; exact Git descriptors and
`scripts/check_knowledge_card_history.pl` prove source identity, answer-set
equality, deterministic contents, and bounded replacements. The generated
projection is now a small root plus deterministic two-ID-component topic
shards. Every fact is catalogued exactly once, every unique question is owned
by exactly one shard, and a shared question links all matching facts rather
than being duplicated. The query wrapper performs fixed-substring search,
caches only disposable rows below `.artifacts/knowledge-map/query/`, and has
checked cached/direct parity.

The migration exposed one stale continuity claim: the former
`ial2-feature-completeness-next-slice` card still described `.276` as current
after the active frontier had advanced far beyond it. Historical `.211`–`.276`
answers remain in bounded history cards; the current card now routes to the
task-tree frontier rather than copying a numeric frontier that can rot.

The canonical knowledge-card file ceiling is exactly occupied after the
no-ceiling-increase migration. That is an intentional fail-closed condition,
not growth capacity: until `.12` derives reviewed retained-surface budgets, a
new durable fact must supersede or consolidate an existing card, or carry an
explicit reviewed ceiling authority. Generated shards and query caches can
never own canonical facts or bypass that control.

Clean `.10` commit `3b71cb0b1` activates `.13` alone against 1,005 focused
documents totaling 212,294 lines / 9,400,050 bytes and 12 ancillary documents
totaling 1,558 lines / 79,973 bytes. `docs/ISF_SPEC.md` is the distinct
6,254-line part outlier; `docs/BIN_FSMGEN_IMPORT_TREE.md:82` owns the separate
7,536-byte-line outlier. The activation gate also found that `t/1553` retained
pre-`.10` exact graph counts after the shard surface landed; its three emitted
count expectations are repaired without changing the checker or topology.
Activation changes no document, index, or limit.

Leaf `.13` retains every focused and ancillary document after a complete
audience/lifecycle/owner/role classification. The generated
`docs/index/FOCUSED_DOCUMENTS.md` links all 1,017 members and fails closed on
stale, duplicate, missing, or unclassified membership. Three unique maintained
ISF contracts become bounded landing pages over eleven stable semantic parts;
an executable manifest proves the three exact activation objects, contiguous
source ranges, direct navigation, per-part bounds, and initial transformed
content equality. The focused root collection falls below warning on every
health axis with no enforcement-ceiling increase. The distinct live
`BIN_FSMGEN_IMPORT_TREE.md` architecture role is retained and its pathological
line representation is wrapped rather than deleted.

Leaf `.11` independently retires the former achievement journal under decision
`0048`, exact version retrieval, and live-path/consumer absence enforcement.
Its separate roadmap-status audit found the 15,039-line board 1,786 commits
stale, with no unique current authority, one stale negative test scan, and one
inaccurate active-source link. The director independently selected retirement;
decision `0049` preserves the exact March-June 2026 chronology and R0-R14
snapshot by verified Git retrieval while requiring live-path and consumer
absence. No replacement status projection is created.
