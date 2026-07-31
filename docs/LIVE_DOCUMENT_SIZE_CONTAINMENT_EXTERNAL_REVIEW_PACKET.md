# External Review Packet: Live-Document Size Containment

## Review status

- Packet version: 1
- Prepared: 2026-07-31
- Implementation snapshot: commit `7f05b41de71f0fb8a79c3e9ddf3e5d2c292a44e1`
- Packet owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.14`
- Intended reviewers: maintainers of other long-running, agent-assisted or
  human-maintained repositories
- Requested response: use the template at the end of this document

This document is deliberately self-contained. A reviewer should be able to
evaluate the architecture without knowing FSMGen, its product domain, or its
agent harness. Repository links are evidence, not prerequisites for
understanding the proposal.

## What we are asking reviewers to judge

Please review the architecture, not merely the prose or JSON syntax. In
particular, challenge whether it actually prevents documentation pressure from
moving from one file into another unbounded location.

We want evidence-backed feedback on:

1. the bounded-live-view/durable-store model;
2. the lifecycle taxonomy;
3. JSONL as the persisted registry and manifest format;
4. line, byte, file-count, and aggregate pressure controls;
5. warning, rollover, hard-limit, and transition-debt semantics;
6. transitive route closure;
7. archive identity, retrieval, and immutability;
8. lossless task-tree sealing and query-first completed history;
9. project, platform, and harness neutrality;
10. failure modes, usability costs, and missing controls;
11. whether current utility and deliberate retirement are evaluated before
    spending effort to contain a document's size.

Please distinguish blocking correctness findings from improvements of taste.
If your project has contrary measurements, include them.

## Executive summary

The architecture starts from one invariant:

> A bounded live view and durable retained information are different products.

A file needed for ordinary startup, navigation, current work, or maintained
reference must not also serve as an indefinitely growing historical ledger.
The current view remains small and directly readable. Older or wider material
is kept in a storage form chosen from its information role:

- current state is overwritten;
- maintained reference is partitioned by stable semantic topic;
- derived indexes are regenerated from smaller canonical inputs;
- recent ordered history uses a rolling window and sealed segments;
- exact old evidence becomes query-first behind an immutable locator;
- externally retained history names its authority and retrieval contract;
- unresolved legacy material is frozen and cannot accept overflow.

The doctrine is project-neutral and harness-neutral. Each adopting project owns
its copy and records local paths, measurements, owners, limits, and migrations
outside the neutral body.

FSMGen's local enforcement uses JSON Lines (JSONL): one named JSON object per
non-empty line. Markdown remains the human interface. JSONL is only the
machine-readable control plane for surfaces, routes, archive descriptors, and
task-history manifests.

The implementation currently governs 20 surfaces and covers every one of the
repository's 2,776 tracked Markdown paths at the reviewed snapshot. Its first
large migration reduced one live task file from 21,726 lines to 85 lines while
preserving 844 terminal nodes in a content-addressed Markdown segment. It also
reduced the cross-tree task index from 1,078 to 558 lines while preserving 540
terminal rows through an exact Git version object. No completed task file was
deleted.

The design is not presented as finished. This review discovered that the
common control-plane JSONL files are not yet independently record/byte capped,
and that the generic `hard_pct` value is not currently applied as an execution
threshold. Those limitations are described explicitly below and have a
separate remediation owner.

## Origin of the problem

### README growth was only the first symptom

The initial policy bounded `README.md` so it remained a useful repository
landing page instead of becoming a roadmap, changelog, status ledger, and file
inventory simultaneously. Cross-project feedback then exposed a deeper issue:
redirecting README overflow is not containment if the destination is
unbounded.

One measured adopter routed status and completed-work narration from its README
into a neighboring live status file. That file reached 1,547,057 bytes, of
which 94.7% was dated changelog material. The README had become smaller, but
the pressure had merely moved.

The conclusion was project-wide:

> Every live destination needs its own lifecycle, owner, bounds, and terminal
> behavior. Routing must be checked transitively.

### Why one universal file cap is not credible

Different information products have different legitimate shapes:

- a resume pointer may need tens of lines;
- a GitHub README needs enough space for purpose and first use;
- a maintained manual may contain many navigable chapters;
- a generated search index can be large but reproducible;
- an engineering ledger is ordered and historical;
- an exact audit trail may belong in version control;
- a frozen legacy record may be large but must never grow.

Applying the README cap to every one of those surfaces would either destroy
useful information or create performative compliance. Leaving them unbounded
would preserve the original failure. The architecture therefore standardizes
the questions and invariants, not one numeric answer.

## Goals and non-goals

### Goals

- Keep mandatory current reads bounded and useful.
- Preserve unique maintained information in directly navigable form.
- Preserve exact historical evidence when exactness is promised.
- Prevent sharding or routing from hiding aggregate growth.
- Make every limit, exception, owner, and retrieval route machine-checkable.
- Fail closed on malformed or ambiguous declarations.
- Keep project-specific and harness-specific identity out of the neutral
  doctrine and checker core.
- Keep all project-owned data repository-relative and on the repository
  volume.
- Make migrations atomic, lossless, and independently committable.

### Non-goals

- Do not minimize total repository bytes at the cost of usability.
- Do not convert prose documents into JSON.
- Do not make Git the only home for maintained user reference.
- Do not prescribe the same limits or topology to every project.
- Do not infer that an existing large file is healthy because it fits under a
  legacy ceiling.
- Do not make a vendor bootstrap file the source of policy authority.
- Do not treat JSONL as part of the neutral doctrine; it is FSMGen's local
  serialization choice.

## Utility before containment

Size is not the first question. The first question is whether the document
should still exist as a live project surface.

A document may have been valuable during project bootstrap and later lose its
role because stronger structures now exist: task-trees for work state and
evidence, decision records for rationale, Knowledge Map fact cards for durable
answers, an mdBook for user guidance, generated capability reports for shipped
behavior, and Git for exact chronology.

Mechanically partitioning such a document would preserve its obsolete role and
increase navigation burden. The correct order is:

1. identify the current audience and question the document answers;
2. decide whether that question still matters;
3. identify the canonical current answer;
4. classify the document's contents as unique-current, duplicated-current,
   historical-only, stale, or contradictory;
5. migrate unique-current material to its proper maintained home;
6. prove duplicated-current material is present in a richer canonical home;
7. preserve historical-only material through exact archive retrieval when its
   retention has value;
8. delete stale, contradictory, or proved-redundant live material;
9. only then apply size containment to the survivors.

Deletion is therefore a legitimate and sometimes preferable containment
outcome. It is not information loss when all valuable information is either in
its canonical maintained home or preserved through an explicitly selected
archive contract.

### Proposed utility outcomes

Every live-document review should select one of these outcomes before choosing
a storage topology:

| Outcome | Meaning | Required proof |
| --- | --- | --- |
| `retain` | The document still has a distinct current audience and canonical role | Named audience, question answered, and maintenance owner |
| `merge` | Its unique current content belongs in another maintained surface | Itemized migration and link/coverage proof |
| `supersede` | A richer maintained surface already owns the current answer | Duplicate or semantic-coverage proof plus replacement pointer |
| `archive` | It has historical value but no current reading role | Exact identity, retrieval, retention owner, and exclusion from live routes |
| `delete` | It is stale, contradictory, valueless, or proved redundant | Review record showing no unique retained value |

These are lifecycle decisions, not necessarily permanent registry classes. A
successfully retired document leaves the live-surface registry; its archive
descriptor or Git history may remain as durable evidence.

### FSMGen examples and candidates

The following table illustrates the analysis with current FSMGen surfaces. It
does not pre-approve deletion; named reviews must prove each outcome before a
file changes.

| Surface | Current measurement | Present role | Preliminary utility judgment |
| --- | ---: | --- | --- |
| `README.md` | 246 lines / 9,952 bytes | GitHub landing page and stable navigation | **Retain.** Its direct rendered role is not replaced by task-trees or the book. Continue bounding it. |
| `MEMORY.md` | 36 lines / 2,069 bytes | Single current resume pointer | **Retain.** It is an intentionally overwritten view, not history. |
| `docs/USER_GUIDE.md` | 130 lines / 5,468 bytes | Compatibility waypoint to the mdBook | **Strong retirement candidate.** Every listed section says it migrated to named book chapters. After link-consumer and unique-phrase proof, the waypoint can likely be superseded and deleted rather than bounded forever. |
| `ROADMAP_STATUS.md` | 15,039 lines / 1,638,574 bytes | Frozen legacy roadmap/status record | **Retirement/archive candidate.** Current direction is now in `ROADMAP_V2.md`; current work is in task-trees; exact history is in Git. A scheduled review must still prove whether any unique maintained status remains. |
| `LIVE_ACHIEVEMENT_STATUS.md` | 16,618 lines / 955,308 bytes | Frozen dated achievement narrative | **Retirement/archive candidate.** Much of its apparent role overlaps `CHANGES.md`, task evidence, fact cards, and Git, but entry-level coverage must be proved before removal. |
| `DEVELOPMENT_NOTES.md` | 34,509 lines / 2,494,512 bytes | Conditional engineering-rationale ledger | **Merge/retire candidate.** Decisions, fact cards, task evidence, and code now own most durable rationale types. Unique surviving rationale should move to the correct layer; duplicated narration should not be sharded merely to preserve the file. |
| `CHANGES.md` | 31,950 lines / 2,673,013 bytes | Per-slice concise technical changelog | **Role decision required.** A human release/change narrative may still add value, but exact per-slice history overlaps task-trees and Git. Plausible outcomes are a bounded recent/release-oriented window, a generated projection, or retirement after canonical coverage proof. |
| `ROADMAP_V2.md` | 10,376 lines / 766,142 bytes | Direction plus accumulated outcomes | **Retain the role, reduce the history.** Forward direction remains useful; shipped chronology should move to task, release, or archive homes rather than forcing deletion of the roadmap itself. |
| `KNOWLEDGE_MAP.md` | 15,583 lines / 6,143,440 bytes | Generated question-to-fact index | **Retain the capability, not the monolith.** Canonical information is in fact cards, so the projection can be regenerated, sharded, or replaced without migrating unique prose. |
| `docs/ISF_SPEC.md` | 6,254 lines / 392,322 bytes | Detailed ISF contract | **Audit before partition.** It may still be canonical machine-facing specification, or some parts may now be duplicated by the mdBook and public contract files. Size alone cannot decide. |
| `docs/*_READINESS_AUDIT.md` and `docs/*_CONTRACT_SELECTION.md` | Hundreds of focused files | Slice-era analysis and selection evidence | **Collection-level retirement candidates.** Some may remain canonical contracts; others may now be duplicated by task completion evidence, decisions, fact cards, code, and tests. Each family needs a role/coverage census before further sharding. |

This illustrates three importantly different actions:

- retain and bound a still-useful interface such as `README.md`;
- retain a capability while replacing a generated representation such as
  `KNOWLEDGE_MAP.md`;
- retire an obsolete compatibility or status surface after migrating unique
  value and proving durable history, rather than spending engineering effort
  partitioning it.

The existing four-file lifecycle review owns the two status files, changelog,
and development notes. A new general utility/retirement audit is tracked for
the remaining live-document families so later size migrations do not inherit a
preservation bias.

## Terminology and model

### Live view

A live view is an artifact expected in normal reading, startup, navigation,
current planning, or maintained reference. Its size is repeatedly paid by
humans and tools. Examples include a README, current roadmap, resume pointer,
active task index, manual table of contents, or current ledger window.

### Canonical store

A canonical store owns information that may continue to evolve. It can be a
semantic document collection, a set of fact cards, or current task files. A
generated projection is not canonical merely because readers use it.

### Durable store

A durable store preserves information outside the mandatory current working
set. Depending on the contract, it may be a sealed repository file, an exact
version-control object, or a separately governed external system.

### Projection

A projection is a rebuildable view derived from canonical inputs. It may be
deleted and regenerated without information loss. Freshness, input coverage,
and deterministic generation are therefore more important than archival
retention of every generated version.

### Route

A route is an explicit navigation or overflow edge from one governed surface
to another. A route is valid only if both endpoints exist, the source really
contains its declared marker, and the graph terminates without a cycle.

### Transition debt

Transition debt acknowledges that an adopted repository may already contain
oversized or structurally unsuitable files. It is not a refreshed baseline and
not permission for ordinary growth. It pins an exact adoption measurement and
may allow only a finite, owned amount of growth needed to complete migration.

## Architecture at a glance

```text
human or tool enters through a bounded live surface
                         |
                         v
              explicit checked route graph
                         |
          +--------------+----------------+
          |              |                |
          v              v                v
  bounded snapshot  canonical parts  generated projection
          |              |                |
          |              |                +--> canonical inputs
          |              |
          +--------------+----------------+
                         |
              rollover / seal / archive
                         |
          +--------------+----------------+
          |                               |
          v                               v
 content-addressed segment       exact version object
          |                               |
          +---------------+---------------+
                          v
                digest/retrieval proof
```

The architecture has four separable layers:

1. a neutral doctrine describing required invariants;
2. project-local JSONL declarations;
3. a neutral deterministic checker plus project adapters;
4. separately committed migrations for individual document families.

This separation matters. An adopter can change local thresholds without
forking neutral semantics, and the reusable doctrine does not inherit FSMGen
paths or harness names.

## Lifecycle taxonomy

### `bounded_snapshot`

Purpose: current state, a resume pointer, or a concise landing/index view.

Required behavior:

- overwrite instead of append chronology;
- independent line and byte limits;
- one current authority;
- staleness checking where the state is derivable;
- no use as an overflow history sink.

FSMGen examples include `README.md`, `MEMORY.md`, `ROADMAP_V2.md`,
`docs/TASK_TREE.md`, `TOOLBOX.md`, and `DOCTRINE_ENFORCEMENT.md`.

### `partitioned_canonical`

Purpose: maintained material whose full content should remain browsable.

Required behavior:

- partition at stable semantic boundaries, never arbitrary line slices;
- retain a bounded index or table of contents;
- enforce per-file, file-count, and aggregate bounds;
- validate links and, where promised, complete reconstruction;
- preserve one canonical home for each fact or topic.

Examples include a manual, decision records, fact cards, and task evidence.

### `generated_projection`

Purpose: a search map, catalog, capability query, or other derived view.

Required behavior:

- name the smaller canonical inputs;
- provide deterministic regeneration or query behavior;
- prove freshness separately;
- bound the root view and any generated shards;
- contain no unique information.

FSMGen's generated Knowledge Map and capability-manifest query use this class.

### `rolling_ledger`

Purpose: ordered recent entries that retain historical value.

Required behavior:

- keep a bounded current window;
- rotate only at whole-entry boundaries;
- seal immutable ordered segments;
- retain a bounded index;
- define when sealed segments leave the live collection for an archive
  terminal, so aggregate growth also stops.

FSMGen currently classifies its change and engineering-rationale ledgers this
way, but their final migration is intentionally blocked on a separate semantic
lifecycle review.

### `archive_terminal`

Purpose: exact historical evidence not required for normal reading.

Required behavior:

- immutable revision or object locator;
- digest and size identity;
- tool-neutral retrieval procedure;
- named retention owner;
- exclusion from mandatory bootstrap reads.

Git is FSMGen's current exact-history terminal.

### `external_terminal`

Purpose: information retained by an independently managed system.

Required behavior:

- named authority and retention commitment;
- stable query or export contract;
- explicit failure policy if the service disappears;
- no pretense that a URL alone is durable evidence.

FSMGen's neutral checker supports this class, but the local live registry does
not currently use it.

### `frozen_legacy`

Purpose: an existing record awaiting an owned lifecycle decision.

Required behavior:

- pinned content identity or equivalent write prohibition;
- no new content;
- no use as an overflow destination;
- an explicit future decision owner.

This class prevents an unresolved large file from continuing to grow merely
because its long-term role has not yet been selected.

## Why JSONL rather than TSV

The first local prototype was effectively a 22-column positional record. Its
problems were already visible before implementation:

- nested budgets and milestones needed sentinel values;
- lists of targets and routes needed a second delimiter and escaping rules;
- optional transition data shifted or multiplied columns;
- a reader could not identify a value without consulting column order;
- schema extension made silent positional drift plausible.

JSONL retains line-oriented processing while giving each value a name and
type. Arrays represent targets and routes. Nested objects represent budgets,
milestones, baselines, and transition allowances. JSON `null` distinguishes
not-applicable from zero or an empty string. Unknown keys fail closed.

### Format comparison

| Concern | TSV | JSONL |
| --- | --- | --- |
| Small fixed scalar table | Excellent | Adequate but verbose |
| Nested budgets | Positional expansion or encoding convention | Natural object |
| Lists of paths or routes | Secondary delimiter and escaping | Native array |
| Optional structured values | Sentinels or sparse columns | Object or `null` |
| Field names in each record | No | Yes |
| Native scalar types | Convention only | String, number, Boolean, `null` |
| Strict unknown-field rejection | External schema tied to column order | Straightforward key validation |
| Streaming | Yes | Yes, one object at a time |
| Human table scanning | Better | Worse |
| Large arrays on one line | Awkward cell | Valid but poor diff ergonomics |

The rule is intentionally narrow:

> Human knowledge stays Markdown. Persisted structured machine contracts use
> JSONL. Tiny, flat, fixed reports may still use TSV.

JSONL is not being proposed as an authoring format for README files, manuals,
task prose, decisions, or changelogs.

## Surface registry contract

FSMGen's surface registry contains one object per governed surface. A measured
record has the following conceptual shape:

```json
{
  "surface_id": "guide",
  "lifecycle": "partitioned_canonical",
  "locator": "collection",
  "targets": ["guide/*.md"],
  "index": "guide/INDEX.md",
  "canonical_inputs": [],
  "routes_to": [],
  "owner": "guide-maintainers",
  "budgets": {
    "files": 32,
    "lines_each": 1000,
    "bytes_each": 65536,
    "lines_total": 12000,
    "bytes_total": 1048576
  },
  "milestones": {
    "warning_pct": 80,
    "rollover_pct": 90,
    "hard_pct": 100
  },
  "state": "normal",
  "baseline": null,
  "verifier": "builtin:budget"
}
```

The physical file uses compact one-object-per-line JSON. The expanded form
above is only for explanation.

### Required fields

| Field | Meaning |
| --- | --- |
| `surface_id` | Stable lower-case machine identifier |
| `lifecycle` | Information-role class |
| `locator` | How targets are resolved and checked |
| `targets` | One or more repository-relative paths or patterns |
| `index` | Bounded collection index, or `null` when inapplicable/temporarily debt-owned |
| `canonical_inputs` | Input patterns for generated files; empty otherwise |
| `routes_to` | Declared outgoing surface IDs |
| `owner` | Maintainer or tracked remediation owner |
| `budgets` | Five independent positive absolute limits for measured surfaces |
| `milestones` | Ordered warning, rollover, and hard percentages |
| `state` | Current normal, debt, terminal, or frozen state |
| `baseline` | Exact adoption measurements for debt; `null` otherwise |
| `verifier` | Budget, freshness, query, archive, external, or digest verifier |

`transition` is the only optional top-level field. When present, it contains a
non-empty owner plus `max_growth` in the same five dimensions as `budgets`.

### Lifecycle and locator are independent but constrained

The checker accepts these pairs:

| Lifecycle | Locator |
| --- | --- |
| `bounded_snapshot` | `file` |
| `partitioned_canonical` | `collection` |
| `generated_projection` | `generated_file` or `query` |
| `rolling_ledger` | `file` |
| `archive_terminal` | `archive` |
| `external_terminal` | `external` |
| `frozen_legacy` | `frozen` |

A syntactically valid but semantically incompatible pair fails.

### Five budget dimensions

Every measured surface declares:

- `files` — collection member count, or one for a single file;
- `lines_each` — maximum line count of any member;
- `bytes_each` — maximum byte count of any member;
- `lines_total` — aggregate line count;
- `bytes_total` — aggregate byte count.

The checker measures every matched regular file, computes maxima and totals,
and calculates pressure independently in every applicable dimension. Peak
pressure is the largest `actual / budget` ratio.

Line and byte limits are both mandatory because prose density varies. A file
can be comfortably below its line cap and already over its byte cap. Collection
limits prevent a thousand individually small shards from becoming another
unbounded working set.

### State semantics

Measured records use one of:

- `normal`;
- `warning_debt`;
- `rollover_debt`;
- `structural_debt`.

Query, archive, and external records use `terminal`. Frozen records use
`frozen`.

At the local 80/90/100 milestones:

- below 80%, numeric state should be `normal`;
- from 80% through below 90%, `warning_debt` is required;
- from 90% upward, `rollover_debt` is required;
- `structural_debt` records a topology problem independent of current numeric
  pressure.

The present implementation rejects an actual value only when it is greater
than the absolute budget. This exact-boundary behavior is discussed under
known limitations because the doctrine's phrase “hard failure at 100%” can be
read as requiring rejection at equality.

### Immutable baseline and bounded transition growth

For each budget dimension `d`, a debt record must satisfy:

```text
0 < baseline[d] <= budget[d]
0 <= transition.max_growth[d]
baseline[d] + transition.max_growth[d] <= budget[d]
actual[d] <= baseline[d] + transition.max_growth[d]
```

The baseline is never regenerated from a newer, larger tree. Without an
explicit transition object, allowed growth is zero. An allowance has its own
owner and cannot extend beyond the hard budget.

This stops a common failure pattern: updating the “known baseline” after every
append until a temporary exception becomes a moving limit.

The machine checker cannot determine whether allowed bytes are semantically
necessary for the migration. That intent remains reviewable through the
tracked task owner and per-slice acceptance evidence.

## Route registry contract

A route record is intentionally small:

```json
{
  "route_id": "guide",
  "source_surface_id": "entrypoint",
  "marker": "guide/INDEX.md",
  "target_surface_id": "guide"
}
```

For each edge, the checker proves:

- all four required scalar fields exist;
- no unknown key is present;
- the route ID is valid and unique;
- source and target surfaces are declared;
- the source's `routes_to` array contains the edge;
- the route registry contains every declared graph edge;
- a file-backed source actually contains the marker;
- the complete directed graph contains no cycle.

FSMGen adds a README-specific adapter that also requires all intended landing
routes and insists they originate from `readme_entrypoint`. This prevents a
generic valid graph from accidentally dropping a required GitHub landing-page
destination.

## Archive descriptor contract

The common archive registry begins with a durable metadata row:

```json
{"record_type":"registry","schema_version":1}
```

It may then contain descriptor records with:

- stable descriptor and surface IDs;
- the former logical path and covered range;
- immutable revision or object locator;
- declared line and byte counts;
- SHA-256 content identity;
- retrieval kind and locator;
- current-view pointer;
- sealing date;
- verifier.

Supported retrieval kinds are:

- `file`: a repository-relative retained file, checked immediately for path,
  line count, byte count, and digest;
- `version_object`: an exact versioned object plus a project-supplied
  executable verifier;
- `external`: an external locator plus a named external verification contract.

The generic descriptor registry is currently empty except for its metadata
row because no general live-document family has yet completed that migration.
Task-tree history has its own stricter specialized manifests described next.

## Locality and path safety

All persisted project-owned paths are derived from the repository root.
Measured files, collection indexes, canonical inputs, archive retrieval files,
and frozen files must be regular, non-symlink files on the repository volume.
Archive directories must likewise be local, non-symlink directories on the
repository volume.

Absolute paths, parent escapes, missing matches, symlink targets, and
off-volume targets fail. External terminals are the explicit exception and
must declare external verification semantics.

This is both a portability and a safety property. Moving the repository does
not invalidate persisted paths, and a glob cannot silently make a project
write or trust data from a user-home cache or another filesystem.

## Tracked-document coverage

The neutral checker optionally consumes a NUL-separated inventory of document
paths. FSMGen's adapter supplies `git ls-files -z -- '*.md'`, so every tracked
Markdown file—including a newly staged file—must match at least one declared
surface target.

Coverage is deliberately supplied by the adapter rather than hard-coded into
the neutral checker. A non-Git adopter can provide an inventory from another
version-control or build system.

The current coverage claim is about tracked Markdown. Structured JSONL,
scripts, source code, and binaries are governed by their own schemas and
doctrines, not by this Markdown census.

## README remains the GitHub landing page

Containment does not mean replacing `README.md` with a link farm. The top-level
README is rendered by GitHub as the project landing page and therefore has a
direct user contract. It retains:

- project purpose and audience;
- prerequisites and one minimal first-use path;
- stable architecture at a glance;
- canonical navigation;
- essential repository-level notices.

Changing detail, exhaustive inventories, status chronology, and design
rationale route outward. Before deletion, apparent duplication must be proved
against a richer maintained home. Unique material is relocated only when it
still belongs elsewhere.

FSMGen derived its local 275-line and 12,288-byte caps from the deliberately
reviewed 246-line, 9,952-byte survivor. Those numbers are not reusable defaults.
The README guard runs on every commit and CI tree, even when the README is not
among the changed paths.

## Task-tree containment extension

### Why ordinary sharding was insufficient

The active IAL2 task tree had reached 21,726 lines and 4,662,385 bytes, although
only its root remained nonterminal. Merely splitting the file would reduce
per-file size but would not prove that node identity, hierarchy, verification,
or commit evidence survived.

The task-tree extension therefore treats a sealed segment as immutable
evidence copied from an exact source revision, not as another editable task
file.

### What stays live

The live task Markdown file remains the front door and retains:

- task metadata and top-level goal;
- the root node;
- every nonterminal node;
- every ancestor needed to reach the active frontier;
- any terminal node not yet sealed;
- a direct historical retrieval pointer.

PNT selection therefore requires no archive lookup.

### Segment-manifest registry record

Each participating tree may name one JSONL manifest. Its first row caps the
control plane and every storage dimension:

```json
{
  "record_type": "registry",
  "schema_version": 1,
  "tree_id": "EXAMPLE",
  "max_records": 8,
  "max_bytes": 65536,
  "max_segment_nodes": 1000,
  "max_segment_lines": 10000,
  "max_segment_bytes": 1048576,
  "max_total_nodes": 4000,
  "max_total_lines": 40000,
  "max_total_bytes": 4194304
}
```

This is the important anti-displacement property: the manifest, each segment,
and all segments together are independently bounded.

### Segment record

Each following row declares:

- schema version and record type;
- stable segment ID;
- repository-relative segment path;
- exact source revision and source task path;
- SHA-256 digest;
- node count;
- complete list of sealed subtree root IDs.

The segment filename is its SHA-256 digest. The content remains Markdown, so
humans can inspect it without a JSON renderer.

The checker retrieves the source file from the named revision and proves:

- the segment digest matches its filename and declaration;
- every segment node exactly matches the source-revision node;
- root IDs are unique and disjoint;
- each named root includes its complete source subtree;
- all segment nodes are terminal;
- leaf verification and commit evidence are complete;
- live and sealed nodes together preserve unique IDs, ancestry, direct-child
  closure, and valid statuses;
- per-segment and aggregate limits hold.

### Compact `version_object` terminal

A fully completed subtree may alternatively remain in the live task file as a
single compact terminal that names:

- an exact revision and former task path;
- retrieved-file digest;
- archived node count;
- subtree goal;
- verification and commit evidence.

The checker retrieves the exact version object, reconstructs the subtree, and
rejects a missing revision, digest mismatch, wrong count, nonterminal archived
node, broken child closure, or pending leaf evidence.

FSMGen has implemented and tested this form but does not currently use one in
the live trees.

### Completed cross-tree index history

The global task index has a separate bounded JSONL manifest. Its current
version contains:

- a registry row capped at one archive record and 640 bytes;
- one `version_object` record naming the exact former index revision, path,
  digest, line and byte counts, terminal-row count, unique-tree count, allowed
  terminal statuses, current pointer, and seal date.

The checker retrieves that exact index and proves all 540 terminal rows are
unique, have terminal status, and point to task files that exist at the same
revision and still exist currently. It separately proves that the live PNT
tables contain only active and proposed rows.

Completed task files remain directly browsable. Only duplicated cross-tree row
narration moved to query-first history.

## First migration: measured evidence

The first migration was intentionally chosen as a strong test: a multi-megabyte
active task file and a cross-tree index carrying hundreds of terminal rows.

| Surface | Before | After live view | Durable retained form |
| --- | --- | --- | --- |
| IAL2 task file | 21,726 lines / 4,662,385 bytes | 85 lines / 36,886 bytes | One 5,914-line / 2,366,453-byte content-addressed Markdown segment |
| IAL2 terminal nodes | 844 in mandatory live file | Active root remains live | All 844 exact-source nodes in sealed segment |
| Cross-tree task index | 1,078 lines / 167,249 bytes | 558 lines / 39,851 bytes | Exact version object describing 540 unique terminal rows |
| Completed task files | Directly browsable | Directly browsable | None deleted |

The IAL2 manifest is 35,252 bytes under a derived 40,960-byte cap. Its second
JSONL line is large because it explicitly lists 844 root IDs. That is valid and
bounded, but its diff ergonomics are a known tradeoff.

After migration, the task integrity result was:

```text
trees=3, nodes=882, segments=1, compact_terminals=0, index_archives=1
```

The active-index and task-evidence surfaces moved from warning debt to normal
without increasing their existing limits.

## Enforcement chain

The design is checked at multiple levels:

1. a neutral Perl checker parses and validates local JSONL data;
2. a project adapter supplies paths and the tracked Markdown inventory;
3. a README adapter requires the local landing-page routes;
4. a task-tree checker validates live, sealed, compact, and version-object
   task history;
5. the doctrine driver runs every registered check unconditionally;
6. the pre-commit hook runs the doctrine driver;
7. CI runs the same doctrine driver.

The neutral checker has no FSMGen path, owner, threshold, product, or harness
identity. Project-specific values live in local JSONL records.

The generic checker validates that a freshness or version-object verifier
exists and is executable; it does not execute every such verifier itself.
FSMGen registers the corresponding real freshness checker separately in the
same unconditional doctrine driver. This division must be repeated correctly
by another adopter.

## Fail-closed test coverage

The tests include positive fixtures for every lifecycle and negative fixtures
for the following classes of defect:

### JSONL and schema

- malformed JSON;
- blank lines or comments;
- non-object records;
- missing required keys;
- unknown keys;
- duplicate identifiers;
- unknown schema versions;
- invalid state/locator combinations;
- missing durable registry metadata.

### Paths and topology

- absolute or escaping paths;
- symlink targets;
- off-volume targets;
- missing files, directories, queries, or canonical inputs;
- collection without an index outside owned debt;
- generated projection without canonical inputs;
- multiple targets where a singular locator is required.

### Pressure and transition debt

- hard-budget overflow;
- warning pressure without warning debt;
- rollover pressure without rollover debt;
- stale numeric debt after pressure falls;
- baseline above budget;
- actual growth beyond baseline plus allowance;
- allowance that can exceed the budget;
- transition allowance without an owner;
- empty surface owner.

### Routes and terminals

- missing source marker;
- declared edge without route row;
- route row not declared by its source;
- unknown source or target;
- duplicate route ID;
- route cycle;
- missing or non-executable query/freshness verifier;
- missing archive directory;
- malformed external verifier;
- frozen digest drift.

### Archive descriptors

- unsafe former or current paths;
- missing metadata record;
- invalid identifiers, dates, counts, or digests;
- retrieval line, byte, or digest drift;
- missing executable version verifier;
- invalid retrieval kind.

### Task-tree history

- unknown manifest keys;
- manifest record/byte overflow;
- per-segment or aggregate node/line/byte overflow;
- unsafe segment paths;
- segment digest mismatch;
- segment/source revision mismatch;
- nonterminal sealed node;
- pending sealed evidence;
- duplicate or incomplete subtree roots;
- missing compact-terminal revision;
- compact digest/count/goal/closure mismatch;
- missing completed-index archive record;
- completed-index digest mismatch;
- missing revision-local task file;
- terminal row retained in the live PNT view.

## Safety properties claimed

The implementation claims the following properties, subject to the known
limitations below:

1. Every tracked Markdown path belongs to at least one declared surface.
2. Every measured surface has independent per-part and aggregate controls.
3. A README route cannot terminate at an undeclared surface.
4. A declared route graph cannot contain a cycle.
5. A generated projection names canonical inputs and an executable freshness
   verifier.
6. Frozen content cannot change without failing its digest check.
7. Transition-debt baselines cannot silently move forward.
8. Allowed transition growth is finite, owned, and cannot exceed the absolute
   budget.
9. Local persisted paths remain repository-relative and same-volume.
10. Task nodes moved from the mandatory live file remain exactly attributable
    to a source revision and reconstruct into one valid graph.
11. Task segment manifests cannot grow without their own record, byte,
    per-segment, and aggregate limits.
12. Completed-index history remains exactly retrievable while current PNT
    selection remains archive-independent.
13. The checks run on the resulting tree, not only when a named file happens to
    be changed.

## Known limitations and open risks

These are part of the review request, not hidden implementation notes.

### L1 — Common JSONL control-plane files are not yet self-bounded

The specialized task segment and completed-index manifests contain
`max_records` and `max_bytes` metadata that is mechanically enforced.

The common surface registry, route registry, and archive-descriptor registry
are strictly schema-checked, but currently have no independently enforced
record-count or byte caps. Their current sizes are small:

| Registry | Records | Bytes at review |
| --- | ---: | ---: |
| Surface registry | 20 | 11,350 |
| README route registry | 15 | 2,108 |
| Common archive descriptors | 1 metadata record | 46 |

Nevertheless, this is the same class of displacement risk the doctrine is
meant to prevent. A separately tracked remediation will decide whether to add
bounded registry metadata, register the control plane as its own surface, or
use another finite topology.

### L2 — `hard_pct` is not currently an executed threshold

The checker validates:

```text
warning_pct < rollover_pct < hard_pct <= 100
```

But runtime pressure logic uses warning and rollover percentages only. Absolute
hard failure occurs when `actual > budget`; equality with the budget passes if
the record declares rollover debt. Consequently:

- local `hard_pct: 100` behaves as an inclusive maximum, not rejection upon
  reaching exactly 100%;
- a hypothetical `hard_pct: 95` would not reject 96% pressure.

The doctrine wording says “hard failure at 100%,” so either the wording or the
implementation needs an explicit decision and aligned tests. No threshold is
being changed inside this review-packet task.

### L3 — One JSONL record can still be a large diff unit

The IAL2 segment record explicitly lists 844 root IDs and occupies most of a
35,252-byte two-line manifest. This remains finite and immutable, but ordinary
line-oriented diff tools treat it as one large changed line.

Possible alternatives include one root record per line, a separately
content-addressed ID set, or a Merkle-style index. Each would add schema and
reconstruction complexity. Reviewers should judge whether the current bounded
atomic record is the better tradeoff.

### L4 — Exact Git retrieval assumes the object remains available

Version-object retrieval fails closed when the named revision is missing. A
shallow clone, aggressive history rewrite, or retention policy that removes
the object therefore blocks validation. That is safer than silently accepting
loss, but adopters must decide whether Git retention is an adequate archive
contract for their environment.

### L5 — Executable-verifier presence is not execution

The neutral core checks that a declared freshness or version verifier exists
and is executable. It cannot know every project's command semantics. The local
doctrine driver must execute the real verifier independently. An adopter that
copies only the core checker would have a weaker guarantee.

### L6 — Semantic quality is not reducible to size

The checker can prove bytes, structure, identity, and routing. It cannot prove
that a semantic partition is well chosen, that a README remains welcoming, or
that a task summary communicates the right context. Human review and the
mdBook/user contract remain necessary.

### L7 — Transition intent is only partly mechanical

The checker proves that transition growth is finite and owned. It cannot prove
that each added line is genuinely required to perform containment. FSMGen uses
task-tree ownership, per-slice acceptance evidence, code review, and atomic
commits for that semantic control.

### L8 — Current complete coverage is Markdown-specific

Every tracked Markdown path is covered. Non-Markdown policy data, generated
artifacts, logs, and caches require separate inventories and doctrines. The
JSONL self-containment gap in L1 is one consequence of that boundary.

### L9 — Existing ceilings include transition debt

Several FSMGen surfaces were already near or beyond warning at adoption. Their
current caps are stop-growth ceilings, not recommended healthy defaults.
Final migration must remeasure the retained live surface and lower legacy
headroom. Until then, seeing “under hard limit” must not be read as “well
sized.”

### L10 — The current doctrine can bias toward preserving obsolete surfaces

The lifecycle taxonomy explains how to bound retained information, but it does
not yet require a mechanical or reviewable “should this live document still
exist?” decision before migration. Without that gate, a team can spend effort
partitioning a document whose useful role has already moved to task-trees,
fact cards, a manual, generated reports, or Git.

The packet therefore proposes the retain/merge/supersede/archive/delete utility
outcomes above. A tracked follow-up must decide how much of this should become
normative doctrine and mechanical evidence rather than reviewer guidance.

## Portability boundary

### What another project can reuse directly

- the neutral doctrine's live-view/durable-store invariant;
- lifecycle classification questions;
- route-closure requirement;
- independent line/byte/file/aggregate dimensions;
- immutable baseline plus finite transition allowance;
- atomic migration and archive-descriptor requirements;
- the neutral JSONL checker contract, if JSONL suits the adopter;
- fail-closed fixture patterns.

### What another project must derive locally

- authority, owner, and adoption date;
- canonical project-owned policy location;
- which surfaces exist;
- which information is canonical, derived, duplicate, or archival;
- line, byte, file-count, and aggregate limits;
- warning, rollover, and hard semantics;
- route markers and graph;
- verifier commands;
- archive retention guarantees;
- same-volume and external-access policy;
- migration order and task ownership.

### What must not be copied as a default

- FSMGen's 80/90/100 milestones without review;
- FSMGen's numeric budgets;
- FSMGen paths, task IDs, or ownership names;
- the assumption that Git is always a sufficient archive;
- the assumption that JSONL is always preferable to TSV;
- transition-debt allowances measured from FSMGen's legacy files.

## Suggested adoption sequence

1. Inventory entry points and every destination they name.
2. Inventory all live document families, including generated and frozen views.
3. For each document, prove whether a distinct current audience and role still
   exist; select retain, merge, supersede, archive, or delete.
4. Classify retained surfaces by information role before choosing storage
   topology.
5. Identify canonical inputs and prove duplicates before deleting anything.
6. Migrate unique value out of documents selected for retirement, then remove
   their live routes and files atomically.
7. Measure lines, bytes, file counts, aggregates, and largest surviving members.
8. Trim or partition deliberately, then derive local limits from survivors.
9. Record pre-existing debt with an immutable baseline and owner.
10. Implement a data-only registry and strict parser.
11. Add transitive route validation and complete tracked-document coverage.
12. Wire the checker unconditionally into commit and CI gates.
13. Add positive and fail-closed fixtures before migrating large content.
14. Migrate one difficult but well-understood outlier atomically.
15. Prove reconstruction or retrieval before removing live duplication.
16. Remeasure and lower temporary ceilings after each family reaches steady
    state.
17. Periodically re-audit both document utility and the control-plane/archive
    destinations themselves.

## Detailed questions for reviewers

Please answer whichever questions your project can inform. “No evidence” is a
useful answer when clearly stated.

### Architecture

- **Q1:** Does bounded live view over an addressable durable store describe the
  right invariant? What counterexample does it miss?
- **Q2:** Are the seven lifecycle classes complete and mutually understandable?
  Which class would your project's documents not fit?
- **Q3:** Is information role the right way to choose overwrite, semantic
  partition, projection, ledger, archive, external, or frozen topology?
- **Q4:** Does route closure actually prevent pressure displacement, or can an
  unbounded sink still hide behind this graph?

### Data format and schema

- **Q5:** Is JSONL preferable to TSV for these persisted structured contracts?
  Which records would you model differently?
- **Q6:** Should every registry begin with self-bounding metadata such as
  `max_records` and `max_bytes`?
- **Q7:** Is strict unknown-key rejection worth the schema-evolution cost?
- **Q8:** Is a 35 KB JSONL line containing 844 IDs acceptable when immutable and
  capped, or should identity lists use another representation?
- **Q9:** Would a formal JSON Schema improve portability, or duplicate the
  executable strict parser without enough value?

### Pressure semantics

- **Q10:** Should the absolute budget be inclusive (`actual <= budget`) or
  should reaching 100% fail immediately?
- **Q11:** Should `hard_pct` be removed, documented as always 100, or enforced
  independently from the absolute budget?
- **Q12:** Are five dimensions sufficient? Should repositories also measure
  rendered size, token count, parse time, Git object growth, or navigation
  depth?
- **Q13:** Does immutable baseline plus finite owned growth close transition
  debt adequately? What gaming path remains?
- **Q14:** How much headroom is needed for one atomic rollover in your measured
  repositories?

### Durability and task history

- **Q15:** Is exact Git version-object retrieval a sufficient archive contract?
  What should shallow clones or rewritten histories do?
- **Q16:** Does content-addressed Markdown plus exact source revision adequately
  prove a sealed task subtree?
- **Q17:** Should completed task files remain directly browsable, or should more
  of them become query-first?
- **Q18:** What evidence would convince you that a large task-tree migration is
  lossless?

### Enforcement and usability

- **Q19:** Which fail-closed check is likely to create unacceptable false
  positives?
- **Q20:** Which important defect could still pass?
- **Q21:** Is unconditional commit/CI enforcement appropriate, including on
  commits that do not touch documentation?
- **Q22:** Does the neutral-core/local-adapter split create hidden adoption
  hazards?
- **Q23:** What is the smallest useful adoption subset for a less mature
  project?
- **Q24:** Is the maintenance burden proportional to the risk being controlled?

### Overall judgment

- **Q25:** Would you adopt this architecture? Answer yes, no, or only with named
  changes.
- **Q26:** What is the single most important change you recommend before wider
  reuse?

### Utility and retirement

- **Q27:** Should every containment migration begin with an explicit utility
  outcome: retain, merge, supersede, archive, or delete?
- **Q28:** What evidence should be mandatory before deleting a once-useful live
  document?
- **Q29:** Which FSMGen candidate above appears most clearly obsolete, and what
  unique-content probe would you run before retiring it?
- **Q30:** When does a human changelog still add value beyond task-trees, fact
  cards, releases, and Git?
- **Q31:** Should utility/staleness be mechanically re-reviewed on a schedule,
  or only when a document reaches size pressure?

## Requested response template

Please return one tracked or pasteable Markdown document using this structure:

```markdown
# Live-Document Size-Containment Review — <project>

- Project:
- Repository type and primary languages:
- Review date:
- Reviewer role:
- Material inspected:
- Overall verdict: accept / accept with changes / reject

## Executive assessment

<What works, what does not, and why.>

## Findings

### F1 — <short title>

- Severity: blocking / major / moderate / minor / observation
- Applies to: doctrine / JSONL schema / checker / task migration / portability
- Evidence:
- Consequence:
- Recommended change:

<Repeat F2, F3, ... as needed.>

## Question responses

- Q1:
- Q2:
...
- Q31:

## Measurements from this project

<Include document sizes, growth rates, failure examples, or migration results.>

## Proposed wording or schema changes

<Provide exact text or example records where practical.>

## Final recommendation

<State what should happen before adoption or wider publication.>
```

## Evidence map

Reviewers who want to inspect the implementation can follow these
repository-relative sources:

| Concern | Evidence |
| --- | --- |
| Neutral doctrine and local adoption fence | `LIVE_DOCUMENT_SIZE_CONTAINMENT.md` |
| README landing-page policy | `README_POLICY.md` |
| Measured family census and migration owners | `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md` |
| Architecture decision | `docs/decisions/0041-live-documents-use-bounded-views-over-durable-stores.md` |
| Task-tree storage decision | `docs/decisions/0042-task-trees-seal-completed-subtrees-with-exact-provenance.md` |
| Neutral checker contract | `live-document-size/LIVE_DOCUMENT_SIZE_CHECKER.md` |
| Neutral checker implementation | `live-document-size/scripts/check_live_document_size.pl` |
| Local surface declarations | `doctrine/live_document_size/surfaces.jsonl` |
| Local route declarations | `doctrine/readme_entrypoint/routed_destinations.jsonl` |
| Common archive descriptors | `doctrine/live_document_size/archive_descriptors.jsonl` |
| Completed-index manifest | `doctrine/task_tree/index_archives.jsonl` |
| IAL2 task segment manifest | `docs/tasks/segments/IAL2-FEATURE-COMPLETENESS-FRONTIER/manifest.jsonl` |
| Live-document fail-closed tests | `t/1554-live-document-size-doctrine.t` |
| README route tests | `t/1553-readme-routed-destination-pressure.t` |
| Task-history fail-closed tests | `t/1549-task-tree-integrity-doctrine.t` |
| Unconditional doctrine driver | `scripts/check_doctrines.sh` |
| Owning implementation tree | `docs/tasks/LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.md` |

## Closing request

Please be adversarial. We are especially interested in cases where the design
appears compliant while pressure, information loss, stale state, or retrieval
fragility remains hidden. Concrete counterexamples and measurements are more
valuable than general agreement.
