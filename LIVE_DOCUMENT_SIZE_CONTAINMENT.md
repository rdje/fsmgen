<!-- LIVE-DOCUMENT-SIZE-CONTAINMENT-LOCAL-ADOPTION:BEGIN -->
## Local adoption note — FSMGen

- Authority: FSMGen maintainers, adopted 2026-07-31 under decision 0041.
- Authoritative copy: repository-root `LIVE_DOCUMENT_SIZE_CONTAINMENT.md`.
  Agent and harness bootstrap files may point here, but they are not the
  doctrine's authority.
- Forwardable adoption bridge:
  `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md` explains how a
  memory-architecture adopter applies this doctrine without copying FSMGen's
  local thresholds, paths, debt, migrations, or retention conclusions.
- Independence: the originating doctrine is a template, not an upstream.
  Later revisions require deliberate local review; there is no automatic sync.
- Local pressure milestones: warning at 80% and rollover required at 90% of
  each reviewed health target. The separately named enforcement ceiling is an
  inclusive absolute maximum: equality passes and any excess fails. This
  adoption raises no predecessor ceiling; several legacy ceilings are lower.
- Transition debt: the clean adoption census pins each pre-existing warning or
  rollover breach and its owner. The baseline never moves. A separate bounded
  `transition.max_growth` object may authorize only continuity needed to land
  this containment program before migration. A positive `ratchet_step` bounds
  stale excess headroom after shrinkage. Ownerless growth, excess beyond that
  allowance, baseline widening, stale ceilings, and ceiling overflow remain
  forbidden.
- Locality: durable shards, manifests, and archive descriptors use repository-
  root-relative paths and reside on the repository volume. Regenerable query
  indexes and caches live under `.artifacts/`; they are never the sole copy.
- Serialization: the local data plane uses one named JSON object per line.
  `doctrine/live_document_size/surfaces.jsonl` is the single authority for
  lifecycle, paths, owners, health targets, enforcement ceilings, milestones,
  containment status, debt baselines, and verifiers. The append-only
  `ceiling_increase_authorities.jsonl` carries only exact increase approvals;
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
  until their individual commits land. Leaf `.18` now implements target versus
  ceiling semantics, monotonic non-increasing baselines, banded downward ratchets, and
  separately reviewed increase authority without widening a ceiling. Leaf
  `.19` now executes `core:` verifiers, requires exact execution proofs from
  the unconditional local `adapter:` runner, and reports `external:` contracts
  as fail-closed degradation instead of treating executable presence as proof.
  Leaf `.20` now makes currency opt-in and lifecycle-scoped; FSMGen's active
  task index declares a source-alignment oracle, while terminal/frozen history
  remains exempt and no global date heuristic exists.
  Leaf `.21` now types reader navigation separately from author overflow,
  derives the latter from emitted enforcer hints, closes collection-index
  contracts, and verifies the packet/disposition evidence maps.
  Leaf `.22` independently verifies migration source, semantic closure,
  working-set dimensions, and loss residue; binds version objects to bounded
  owner/guarantee/recovery contracts; and freezes the detailed review packet
  behind a bounded review front door.
  Leaf `.23` adds the distinct `maintained_reference` lifecycle for unique
  product-sized prose: bounded parts and direct mandatory index, exact fresh
  aggregate-change authority, and no decorative fixed aggregate cap. The
  mdBook is the first classified surface. Leaf `.13` now promotes the three
  maintained ISF contracts into a second such surface: bounded landings route
  directly to eleven stable semantic parts, with exact activation-source
  retrieval and fresh aggregate authority.
  Leaf `.15` now makes every common JSONL registry self-bounded by data-record,
  whole-file-byte, and raw-record-byte declarations under tighter portable
  hard caps; scalar byte limits, identifier domains, array cardinalities, and
  maximum Markdown content-line bytes close the remaining displacement paths.
  No predecessor pressure ceiling is widened.
  Leaf `.13` also generates one complete focused/ancillary classification index,
  keeps the live `bin/fsmgen` import map as current architecture reference, and
  returns every focused pressure axis below warning without increasing an
  enforcement ceiling.
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
- independent reviewed health targets and inclusive enforcement ceilings for
  lines, bytes, and maximum content-line bytes, plus file-count and aggregate
  dimensions for collections unless a product-sized maintained-reference
  contract replaces fixed aggregate caps with exact per-change authority;
- warning and rollover-required milestones measured against health targets;
- the operation that bounds it: overwrite, partition, regenerate, seal,
  rotate, archive, supersede, or freeze;
- how a reader finds current material and retrieves retained history; and
- the mechanical check that rejects missing, stale, cyclic, or over-limit
  declarations.

Routing is transitive. A bounded file that sends overflow to an unbounded
neighbor has not contained anything.

Reader navigation and author overflow are different route kinds. A reader may
legitimately navigate to immutable history. Author guidance may also identify
exact history already captured by the durable version-history workflow, but it
must not redirect appendable prose into an immutable or frozen terminal.
Inventory both without forcing them to have the same destinations. Derive
author candidates from enforcers' emitted failure guidance as well as
hand-authored route data; an undeclared path-shaped hint is a real pressure
edge and must fail closed.

A collection front door must state what completeness means. A literal table of
contents proves every member, a generated index names its reproducible source,
or an explicit query contract defines the complete target expansion. Presence
of an index file alone proves none of these. Likewise, a human evidence map is
only trustworthy when every fenced repository-relative path resolves
mechanically in the resulting tree.

## Boundedness, currency, and truth

Boundedness does not imply currency, and currency does not imply unrestricted
semantic truth. Size and route checks prove only their declared structural
properties. A current surface may opt into a named, lifecycle-specific
currency contract backed by a calibrated local verifier. Only that declaration
authorizes the currency claim; the verifier must execute in the unconditional
doctrine path and its failure must fail closed.

The neutral doctrine never infers staleness from the newest date, the number of
distinct dates, file age, or a universal threshold. Closure facts legitimately
put old dates in current roadmaps, while archive and frozen dates are expected
to remain old. Historical terminals and frozen records are therefore exempt
from current-state contracts. A local verifier may detect a document's exact
self-contradiction or compare a projection with its canonical source, but its
grammar and false-positive calibration belong to the adopting project.

## Lifecycle classes

| Class | Purpose | Required containment |
| --- | --- | --- |
| `bounded_snapshot` | Current state, resume pointer, or concise landing/index view | Overwrite semantics, no embedded chronology, line/byte limits, and a stale-state check where derivable |
| `partitioned_canonical` | Finite or contract-bounded canonical material whose full content remains directly browsable | Stable semantic partitions, bounded table of contents, per-part/file-count/aggregate limits, and link/reconstruction checks |
| `maintained_reference` | Unique maintained product/specification prose whose aggregate follows legitimate product scope | Auditable audience/role/rationale, stable semantic parts, bounded complete mandatory index and navigation depth, per-part limits, and exact fresh authority for every aggregate change |
| `generated_projection` | Search map, catalog, or index derived from smaller canonical units | Reproducible generation, freshness proof, bounded root view and shards, and no unique facts in generated output |
| `rolling_ledger` | Ordered recent entries with historical value | Bounded current window, deterministic seal/rotation boundary, immutable segments, bounded index, and an archive transition before aggregate growth becomes unbounded |
| `archive_terminal` | Exact historical evidence not needed in ordinary reading | Immutable locator, identity and size proof, tool-neutral retrieval procedure, retention owner, and exclusion from mandatory bootstrap reads |
| `external_terminal` | History retained by an independently managed system | Named authority, retention commitment, stable query/export contract, and a failure policy if that contract disappears |
| `frozen_legacy` | Existing record awaiting an owned lifecycle decision | Exact content identity or equivalent write prohibition; it cannot accept new content or act as an overflow destination |

A local adoption may define additional classes, but each must make growth stop,
become predictably partitioned under fixed bounds, or govern product-scope
change through exact fresh authority. Renaming an append-only blob is not a new
lifecycle.

## Choose the storage topology from the information role

Do not shard mechanically by arbitrary line count. Classify the information
first:

1. Current state belongs in an overwritten bounded snapshot.
2. Unique maintained material that people browse belongs in semantic,
   navigable partitions. If its aggregate follows legitimate product scope,
   classify it as maintained reference and bound the read path plus each part
   while authorizing every aggregate change exactly.
3. A projection that can be recreated belongs in generated bounded shards; its
   smaller canonical inputs remain authoritative.
4. Exact chronology or evidence that is rarely read belongs in a query-first
   archive after its current window closes.
5. Content already present in a richer canonical source is proved duplicate,
   then removed with a link rather than copied into another store.

Sharding controls per-read and per-file pressure, but it does not by itself
control aggregate storage. An ordinary partitioned collection keeps aggregate
limits. A maintained product reference instead measures aggregate files/lines/
bytes and requires an exact, newly owned change record whenever they move;
fixed aggregate targets are explicitly inapplicable rather than silently
unlimited. A rolling ledger must still declare when sealed segments leave the
live collection for an archive terminal. The chosen topology must therefore
bound the reader's working set and either bound or exactly govern the
collection's long-term aggregate change according to information role.

## Derive pressure limits from the retained surface

Measure the deliberately reviewed live survivor and set independent line,
byte, and maximum content-line-byte health targets. For collections, also set
per-part, file-count, and aggregate targets. Maximum line width is a separate
pressure axis: a generated table or dense record can remain pathological while
the file still passes total-line and total-byte limits. Measure raw content
bytes deterministically, excluding LF and an optional preceding CR. Do not copy
illustrative numbers from another adoption, and do not treat a current legacy
size as healthy merely because it was measured.

The exception is unique maintained product/specification prose. A fixed
aggregate target there is dishonest because legitimate scope changes with the
product. Require fixed per-part limits, a complete mandatory index with its own
line/byte bounds, bounded direct navigation, and exact aggregate baseline plus
signed per-change delta. A revision-aware adapter must reject stale, inexact,
reused, or banked authority. Classification alone never waives a monolith's
existing debt; semantic partition and complete navigation land first.

For every measured dimension, declare two different values:

- the **health target** describes the reviewed steady-state working set and is
  the denominator for warning and rollover pressure; and
- the **inclusive enforcement ceiling** rejects only `actual > ceiling`. It is
  a quarantine boundary, not evidence that content below it is healthy.

Each local registry selects two ordered milestones against the health target:

- **warning**: investigation and an owned remediation become mandatory;
- **rollover required**: ordinary appends stop unless the same change performs
  the declared rollover.

The warning must leave enough capacity for the largest normal update plus the
rollover transaction. A ceiling increase requires a new, separate, reviewed
authority record proving that the surface's user contract expanded; editing
the surface declaration alone cannot authorize itself. Lowering is free.

At first adoption, a surface already beyond warning or rollover may be entered
as explicit transition debt only with its exact measured baseline, named
remediation owner, deadline or ordered frontier, and unchanged ceiling.
Only records required to complete the containment transition may extend a
rollover-debt surface; ordinary unrelated growth remains prohibited. The debt
exception ends when the migration lands and can never excuse ceiling overflow.
Its baseline cannot increase across revisions, but an atomic content reduction
may lower it so the ceiling can ratchet down. The current baseline plus owned
allowance must fit below the ceiling. A
declared ratchet band must also reject a ceiling that remains materially above
both actual use and the health target after pressure falls.

## Atomic partition, rollover, and archive protocol

A transition is complete only when one change performs and verifies all
applicable steps:

1. Stop writes to the source at a stable semantic, record, or time boundary.
2. Classify retained information as canonical, derived, duplicate, or archival.
3. Write the new partition, sealed segment, or archive record without altering
   record order or identity.
4. Record source and destination line counts, byte counts, and content digests;
   when exact reconstruction is promised, prove it byte for byte.
   Report complete-source identity, semantic closure, the live working-set
   dimensions, and any truly unretained residue as four independent products.
   Declare whether products overlap; never force disjoint arithmetic onto
   retained source, semantic extracts, and live navigation views.
5. Update the bounded current view, manifest, table of contents, predecessor/
   successor links, and query route.
6. Run link, freshness, ordering, uniqueness, retrieval, and pressure checks;
   a declared executable must actually run successfully, not merely exist.
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

A version object is a conditional retention mechanism, not a self-proving
archive. Every version-object use must name a bounded retention contract with
an owner, an explicit reachability/backup guarantee, and an actionable
recovery procedure for shallow history or rewritten objects. If evidence must
remain recoverable without that condition, prefer a content-addressed file on
the repository volume.

Retrieval must not depend on a particular AI agent, editor, or harness. An
archive descriptor is a controlled terminal, not permission to route new live
content into an opaque dump.

## Registry and mechanical enforcement

Keep local declarations in data-only registries consumed by one deterministic
checker. Each registry must itself be finite: begin with schema-versioned
metadata declaring positive maximum data-record count, total file bytes, and
raw JSON bytes per record; impose portable fail-safe ceilings as well as the
adopter's tighter limits. Arrays need finite cardinalities, scalar fields need
byte limits, identifiers need closed domains, and unknown fields fail closed.
The registries are the local authority for class, paths, limits, milestones,
generation or retrieval checks, and dependency routes. The checker must run
on the resulting tree for every commit and continuous-integration build,
independent of which paths changed.

At minimum, fail on:

- an undeclared live surface or routing destination;
- missing, malformed, oversized, or over-populated control-plane registry
  metadata, record, scalar, or array;
- an absolute, escaping, or otherwise forbidden persisted path;
- a missing owner, lifecycle, limit, or retrieval/freshness control;
- a route cycle or a route ending at an uncontrolled neighbor;
- a stale generated projection or broken current/history link;
- a mutable sealed/frozen unit or failed archive digest/retrieval proof;
- a version object without a named retention owner, guarantee, and recovery
  action, or migration evidence that conflates overlapping products;
- warning without an owned remediation, rollover-required without the atomic
  transition, actual usage above an inclusive ceiling, or stale debt headroom;
- an unauthorized ceiling increase or rewritten debt baseline; and
- an unclassified maintained reference, oversized part or mandatory index,
  incomplete direct navigation, aggregate mismatch, or stale/reused/banked
  aggregate-change authority.

Generated caches may accelerate the checker or search, but they are disposable
and never the canonical copy.

## Adoption checklist

1. Add a project-owned copy and fence all local metadata away from this body.
2. Inventory every live document, generated view, collection, route, and
   historical terminal; follow routes transitively.
3. Classify each surface by lifecycle and identify its actual canonical source.
4. Measure lines, bytes, maximum content-line bytes, file counts, aggregates,
   structure, and read path.
5. Derive health targets from reviewed survivors and set separate inclusive
   ceilings with only transaction-sized headroom.
6. Open an owner for every surface already at warning or structurally
   monolithic even if it remains below a numeric threshold.
7. Choose bounded snapshot, semantic partitions, maintained reference,
   generated shards, rolling ledger, archive, external, or frozen topology
   from the information role.
8. Prove any duplicate before deletion and prove any archive before removing
   its live copy.
9. Add the data registry, unconditional checker, positive/fail-closed tests,
   and commit/CI wiring.
10. Re-audit after each migration and periodically thereafter; lower limits to
    the retained steady-state surface instead of preserving legacy headroom.
