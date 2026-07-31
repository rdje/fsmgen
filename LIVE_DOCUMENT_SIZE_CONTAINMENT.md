<!-- LIVE-DOCUMENT-SIZE-CONTAINMENT-LOCAL-ADOPTION:BEGIN -->
## Local adoption note — FSMGen

- Authority: FSMGen maintainers, adopted 2026-07-31 under decision 0041.
- Authoritative copy: repository-root `LIVE_DOCUMENT_SIZE_CONTAINMENT.md`.
  Agent and harness bootstrap files may point here, but they are not the
  doctrine's authority.
- Independence: the originating doctrine is a template, not an upstream.
  Later revisions require deliberate local review; there is no automatic sync.
- Local pressure milestones: warning at 80%, rollover required at 90%, and a
  hard failure at 100% of each reviewed limit. Existing stop-growth ceilings
  remain unchanged until their owning migration recalibrates them from the
  retained live surface.
- Transition debt: the clean adoption census pins each pre-existing warning or
  rollover breach and its owner. The baseline never moves. A separate bounded
  `transition.max_growth` object may authorize only continuity needed to land
  this containment program before migration; ownerless growth, excess beyond
  that allowance, baseline widening, and any hard-limit breach remain
  forbidden.
- Locality: durable shards, manifests, and archive descriptors use repository-
  root-relative paths and reside on the repository volume. Regenerable query
  indexes and caches live under `.artifacts/`; they are never the sole copy.
- Serialization: the local data plane uses one named JSON object per line.
  `doctrine/live_document_size/surfaces.jsonl` is the single authority for
  lifecycle, paths, owners, budgets, milestones, debt baselines, and verifiers;
  route and archive-descriptor JSONL files carry only their own mappings.
- Landing-page identity: top-level `README.md` is FSMGen's rendered GitHub
  landing page and remains a first-class bounded interface. Its purpose,
  first-use path, architecture summary, and navigation stay directly visible;
  only changing detail, inventory, and chronology route outward.
- Adoption state: decision 0041 and the local audit select the architecture
  and exact migration owners. Common registry/checker leaf
  `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.2` enforces the complete tracked
  Markdown inventory before any family migration. Decision 0042 and leaf `.6`
  additionally define bounded task-tree segment manifests, content-addressed
  exact-source sealed subtrees, and exact version-object compact terminals.
  Leaf `.7` now applies those forms to the 844 terminal IAL2 children and the
  540-row completed cross-tree index: both task surfaces return to `normal`
  without deleting a completed task file or changing README landing content.
- External review: PGEN and ANVIL accepted the architecture with corrections.
  Decision 0044 and the bounded disposition separate coverage from health,
  healthy targets from transition ceilings, verifier presence from execution,
  full-source retention from sealed-node closure, and lifecycle currency from
  global date heuristics. Leaves `.15`-`.23` own the changes; the current
  checker, registry values, thresholds, and document lifecycles remain in force
  until their individual commits land.
<!-- LIVE-DOCUMENT-SIZE-CONTAINMENT-LOCAL-ADOPTION:END -->

---

# Live-Document Size-Containment Doctrine

This project-neutral, project-agnostic, and harness-neutral doctrine keeps
long-lived documentation useful as a bounded working set while preserving
durable information in addressable storage. It applies to human-authored
documents, generated indexes, work records, manuals, ledgers, and historical
archives. It does not prescribe a product domain, authoring tool, agent, build
system, or repository layout.

## Authority and adoption

After adoption, the adopting project owns its copy. Cite the project's owner
and adoption or revision date together with the project-owned doctrine file.
Never cite a vendor-, agent-, or harness-specific bootstrap file as authority.
Bootstrap files may make the doctrine discoverable; they do not make it
binding.

Keep project-specific authority, paths, thresholds, measurements, storage
choices, and migration decisions in a clearly fenced local adoption note or a
separate data registry. Keep them out of this neutral body. The copied doctrine
is authoritative; its origin is a template rather than an upstream, so later
changes are adopted only through explicit local review.

## Core invariant

A bounded live view and a durable history are different products. The live
view answers what a reader needs now; the durable store preserves what must
remain recoverable. No surface may be both an indefinitely growing history and
a mandatory current read.

Every governed surface must declare:

- its stable identifier, owner, audience, and canonical authority;
- its lifecycle and storage topology;
- independent line and byte limits for text, plus file-count and aggregate
  limits for collections when applicable;
- warning, rollover-required, and hard-failure milestones;
- the operation that bounds it: overwrite, partition, regenerate, seal,
  rotate, archive, supersede, or freeze;
- how a reader finds current material and retrieves retained history; and
- the mechanical check that rejects missing, stale, cyclic, or over-limit
  declarations.

Routing is transitive. A bounded file that sends overflow to an unbounded
neighbor has not contained anything.

## Lifecycle classes

| Class | Purpose | Required containment |
| --- | --- | --- |
| `bounded_snapshot` | Current state, resume pointer, or concise landing/index view | Overwrite semantics, no embedded chronology, line/byte limits, and a stale-state check where derivable |
| `partitioned_canonical` | Maintained reference material whose full content must remain directly browsable | Stable semantic partitions, bounded table of contents, per-part/file-count/aggregate limits, and link/reconstruction checks |
| `generated_projection` | Search map, catalog, or index derived from smaller canonical units | Reproducible generation, freshness proof, bounded root view and shards, and no unique facts in generated output |
| `rolling_ledger` | Ordered recent entries with historical value | Bounded current window, deterministic seal/rotation boundary, immutable segments, bounded index, and an archive transition before aggregate growth becomes unbounded |
| `archive_terminal` | Exact historical evidence not needed in ordinary reading | Immutable locator, identity and size proof, tool-neutral retrieval procedure, retention owner, and exclusion from mandatory bootstrap reads |
| `external_terminal` | History retained by an independently managed system | Named authority, retention commitment, stable query/export contract, and a failure policy if that contract disappears |
| `frozen_legacy` | Existing record awaiting an owned lifecycle decision | Exact content identity or equivalent write prohibition; it cannot accept new content or act as an overflow destination |

A local adoption may define additional classes, but each must make growth stop
or become predictably partitioned. Renaming an append-only blob is not a new
lifecycle.

## Choose the storage topology from the information role

Do not shard mechanically by arbitrary line count. Classify the information
first:

1. Current state belongs in an overwritten bounded snapshot.
2. Unique maintained material that people browse belongs in semantic,
   navigable canonical partitions.
3. A projection that can be recreated belongs in generated bounded shards; its
   smaller canonical inputs remain authoritative.
4. Exact chronology or evidence that is rarely read belongs in a query-first
   archive after its current window closes.
5. Content already present in a richer canonical source is proved duplicate,
   then removed with a link rather than copied into another store.

Sharding controls per-read and per-file pressure, but it does not by itself
control aggregate storage. A partitioned reference may retain all shards
because direct browsing is part of its contract. A rolling ledger must also
declare when sealed segments leave the live collection for an archive terminal.
The chosen topology must therefore bound both the reader's working set and the
collection's long-term aggregate growth.

## Derive pressure limits from the retained surface

Measure the deliberately reviewed live survivor and set independent line and
byte hard limits with enough explicit headroom to complete one atomic rollover.
For collections, also set per-part, file-count, and aggregate limits. Do not
copy illustrative numbers from another adoption, and do not treat a current
legacy size as healthy merely because it was measured.

Each local registry selects three ordered milestones below or at the hard
limit:

- **warning**: investigation and an owned remediation become mandatory;
- **rollover required**: ordinary appends stop unless the same change performs
  the declared rollover; and
- **hard failure**: the resulting tree is rejected.

The warning must leave enough capacity for the largest normal update plus the
rollover transaction. A limit increase requires a reviewed decision that the
surface's user contract expanded; growth alone is not justification.

At first adoption, a surface already beyond warning or rollover may be entered
as explicit transition debt only with its exact measured baseline, named
remediation owner, deadline or ordered frontier, and unchanged hard limit.
Only records required to complete the containment transition may extend a
rollover-debt surface; ordinary unrelated growth remains prohibited. The debt
exception ends when the migration lands and can never excuse a hard-limit
breach.

## Atomic partition, rollover, and archive protocol

A transition is complete only when one change performs and verifies all
applicable steps:

1. Stop writes to the source at a stable semantic, record, or time boundary.
2. Classify retained information as canonical, derived, duplicate, or archival.
3. Write the new partition, sealed segment, or archive record without altering
   record order or identity.
4. Record source and destination line counts, byte counts, and content digests;
   when exact reconstruction is promised, prove it byte for byte.
5. Update the bounded current view, manifest, table of contents, predecessor/
   successor links, and query route.
6. Run link, freshness, ordering, uniqueness, retrieval, and pressure checks.
7. Only after those checks pass, remove any live duplicate whose retained copy
   or archive retrieval has been proved.
8. Commit the transition atomically so no durable state exposes half a move.

Sealed units are immutable. Corrections create a superseding record or segment
rather than silently editing archived evidence.

## Archive descriptor contract

When bytes leave the live collection, a small tracked descriptor must preserve
at least:

- schema version and stable surface identifier;
- former logical path and covered record, topic, or time range;
- immutable revision or object locator;
- line count, byte count, and content digest before removal;
- a repository-root-relative or otherwise portable retrieval procedure;
- the current-view, manifest, and replacement pointers;
- the sealing reason, date, and verifier identity; and
- an executable proof that retrieval reproduces the declared content.

Retrieval must not depend on a particular AI agent, editor, or harness. An
archive descriptor is a controlled terminal, not permission to route new live
content into an opaque dump.

## Registry and mechanical enforcement

Keep local declarations in a data-only registry consumed by one deterministic
checker. The registry is the local authority for class, paths, limits,
milestones, generation or retrieval checks, and dependency routes. The checker
must run on the resulting tree for every commit and continuous-integration
build, independent of which paths changed.

At minimum, fail on:

- an undeclared live surface or routing destination;
- an absolute, escaping, or otherwise forbidden persisted path;
- a missing owner, lifecycle, limit, or retrieval/freshness control;
- a route cycle or a route ending at an uncontrolled neighbor;
- a stale generated projection or broken current/history link;
- a mutable sealed/frozen unit or failed archive digest/retrieval proof;
- warning without an owned remediation, rollover-required without the atomic
  transition, or any hard-limit breach; and
- an unauthorized limit increase.

Generated caches may accelerate the checker or search, but they are disposable
and never the canonical copy.

## Adoption checklist

1. Add a project-owned copy and fence all local metadata away from this body.
2. Inventory every live document, generated view, collection, route, and
   historical terminal; follow routes transitively.
3. Classify each surface by lifecycle and identify its actual canonical source.
4. Measure lines, bytes, file counts, aggregates, structure, and read path.
5. Derive local warning, rollover, and hard limits from reviewed survivors.
6. Open an owner for every surface already at warning or structurally
   monolithic even if it remains below a numeric threshold.
7. Choose bounded snapshot, semantic partitions, generated shards, rolling
   ledger, archive, external, or frozen topology from the information role.
8. Prove any duplicate before deletion and prove any archive before removing
   its live copy.
9. Add the data registry, unconditional checker, positive/fail-closed tests,
   and commit/CI wiring.
10. Re-audit after each migration and periodically thereafter; lower limits to
    the retained steady-state surface instead of preserving legacy headroom.
