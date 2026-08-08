# From Bounded Memory to Bounded Live Documents

## Purpose

This is a forwardable adoption bridge for a project that already uses the
Durable Agent Memory Architecture but still struggles with a full or repeatedly
firing `MEMORY.md` size cap, growing live-document destinations, or large files
that every session must read or update.

This guide is not the doctrine. The receiving project adopts a project-owned
copy of `LIVE_DOCUMENT_SIZE_CONTAINMENT.md`; that doctrine is the normative
contract. This guide explains how to adopt it safely and how it complements the
memory architecture.

The desired result is not less durable information. It is a bounded working set
over complete, addressable, mechanically verified history.

## When to use this guide

Use it when one or more of these conditions hold:

- `MEMORY.md` repeatedly approaches or reaches its cap even after obvious
  history and rationale have moved into task trees or decisions;
- authors trim wording merely to pass the cap, rather than removing a scaling
  term or routing information to its canonical layer;
- a bounded entry point routes overflow into an append-only file that grows
  without a rollover or archive transition;
- changelogs, engineering journals, task indexes, roadmaps, manuals, generated
  maps, or evidence ledgers have become expensive mandatory reads;
- splitting one large file creates an ever-growing collection with no file-count
  or aggregate control;
- a gate proves that fields or files exist but cannot prove that current-state
  content agrees with its canonical source;
- project continuity depends on manually maintained copies of facts already
  owned by Git, task trees, decision records, or generated indexes.

Do not use file size alone to decide that a document has no value. First ask
what reader question it answers, whether its content is unique, and which live
consumers depend on it.

## The non-negotiable answer

Do not make `MEMORY.md` unbounded.

The memory architecture deliberately makes `MEMORY.md` a bounded,
overwrite-only resume pointer. Removing that boundary recreates the original
memory blob: current state, chronology, warnings, rationale, and partial indexes
compete in one mandatory read whose cost grows with the project.

When the cap fires, distinguish two cases:

1. **The pointer contains the wrong information.** Move task state, durable
   rationale, facts, history, or indexes to their canonical layers and leave a
   pointer.
2. **The rest of the documentation system has no safe destination.** Adopt the
   live-document containment doctrine so every destination has a lifecycle,
   bounds, an owner, a retrieval path, and enforcement.

A cap can expose a bad write path, but a larger cap does not repair it.

## How the doctrines fit together

| Contract | Responsibility |
| --- | --- |
| `MEMORY_ARCHITECTURE.md` | Defines the resume pointer, task memory, decisions, exact history, and bounded read/write paths. |
| `LIVE_DOCUMENT_SIZE_CONTAINMENT.md` | Defines lifecycle, storage topology, pressure controls, transitions, and retrieval for every long-lived document family. |
| `DOCTRINE_ENFORCEMENT.md` or equivalent | Runs deterministic checks through the commit hook and CI. |
| The project's commit workflow | States when a document genuinely needs an update and prevents ceremonial co-staging. |

The memory doctrine remains authoritative for memory semantics. Live-document
containment generalizes the bounded-view principle to all documents and all
overflow destinations.

## What the receiving project adopts

The receiving project should:

1. Store an authoritative copy of `LIVE_DOCUMENT_SIZE_CONTAINMENT.md` at its
   repository root.
2. Preserve the project-neutral normative body.
3. Replace any donor-specific fenced adoption note with a local note naming the
   receiving project's owner, date, decision, locality rules, and adoption
   frontier.
4. Treat the copied doctrine as locally owned, not as a synchronized upstream.
5. Build its own inventory, classifications, measurements, targets, ceilings,
   transition debt, retention commitments, registry, and checker wiring.

Forward the doctrine together with this guide. Forwarding this guide alone does
not create an enforceable policy.

Do not copy another project's:

- thresholds or current measurements;
- surface identifiers or path patterns;
- task IDs, decisions, migrations, or debt allowances;
- cache locations, external verifiers, or retention guarantees;
- generated indexes or registry records;
- conclusions about which documents should be retained or retired.

Those values are evidence about the donor project, not portable policy.

## Phase 1 — stabilize the resume pointer

Complete this focused repair before beginning a project-wide migration.

### 1. Give the repair an owner

Create or extend a task-tree leaf before changing the pointer, commit workflow,
or gate. Record the exact observed failure: cap pressure, unrelated editorial
tax, stale state, duplicated frontier, or an unsafe overflow destination.

### 2. Measure the scaling terms

Measure at least:

- lines, bytes, and maximum content-line bytes;
- change frequency and direction over a representative commit range;
- which fields grow per commit, task, warning, decision, or project surface;
- whether the gate observes content truth or merely presence;
- whether the prescribed overflow destinations are already canonical and
  pressure-controlled.

Repeated gate firing by itself does not prove that the cap is wrong. A field
that grows with the number of tasks or commits does prove a scaling term.

### 3. Restore pointer semantics

The current block should contain only:

- one active work unit;
- a concise current-state statement that does not repeat chronology or a
  canonical task/index projection;
- one concrete next action;
- in-flight uncommitted state;
- blockers that affect resumption.

Keep wider task rosters, task frontiers, priority queues, durable warnings, and
history in their canonical task, decision, fact, or Git homes. If another
source already owns a fact, point to it rather than copying it.

Avoid a hand-maintained `latest_commit` field that claims to equal `HEAD`.
Obtain the current commit from Git when resuming, or explicitly name a different
semantic such as the last commit that changed resume state. Do not label a
lagging historical pointer as the latest commit.

### 4. Remove ceremonial commit coupling

Require a `MEMORY.md` update when resumable state changes: a work unit completes,
the next action changes, work remains uncommitted, or a blocker appears or
clears. Do not require an edit solely so every commit touches the file.

Co-staging proves that a path changed. It does not prove that the new content is
true. Prefer eliminating shadow state, deriving mechanical facts, and checking
the remaining resolvable pointers against canonical sources.

### 5. Keep the existing cap

Do not raise or remove the cap as part of stabilization. If the pointer cannot
fit after its scaling terms and misplaced content are removed, stop and record
which essential resume question lacks another canonical home. That is evidence
for the containment inventory, not permission for an unbounded pointer.

## Phase 2 — adopt live-document containment

Perform the following as task-owned, separately committable slices.

### 1. Inventory the complete graph

Enumerate every live document, generated view, collection, mandatory read,
overflow hint, route destination, and historical terminal. Follow routes
transitively: a bounded source pointing to an uncontrolled destination is not
contained.

Inventory both reader navigation and author overflow. They answer different
questions and need not have identical destinations.

### 2. Establish present utility before choosing topology

For each surface, record:

- its audience and current reader question;
- its canonical authority;
- unique accurate content;
- code, test, script, documentation, registry, and bootstrap consumers;
- overlap with task trees, decisions, facts, maintained manuals, and Git;
- the retention and retrieval requirement if its live representation changes.

Select `retain`, `merge`, `supersede`, `archive`, `delete`, or `re-form` from
that evidence. Do not preserve a file merely because it already exists, and do
not delete it merely because it is large.

### 3. Assign a lifecycle

| Information role | Typical lifecycle |
| --- | --- |
| Current state, resume pointer, concise landing page | `bounded_snapshot` |
| Finite canonical material browsed by stable topic | `partitioned_canonical` |
| Unique maintained product or specification prose | `maintained_reference` |
| Reproducible map, catalog, or search projection | `generated_projection` |
| Recent ordered entries plus older chronology | `rolling_ledger` |
| Exact rarely read historical evidence | `archive_terminal` |
| History retained by another managed system | `external_terminal` |
| Existing record awaiting an owned decision | `frozen_legacy` |

Renaming an append-only blob is not a lifecycle. Each selected class must stop
growth, partition it under explicit controls, or authorize legitimate
product-scope change exactly.

### 4. Measure independent pressure axes

Measure lines, bytes, and maximum content-line bytes independently. For
collections also measure file count, per-part maxima, aggregate lines and
bytes, and navigation depth where relevant.

Derive health targets from the deliberately reviewed survivor. Define separate
inclusive enforcement ceilings with only transaction-sized headroom. Do not
copy illustrative numbers, fit targets to current bloat, or call a quarantine
ceiling healthy.

### 5. Record transition debt honestly

If a surface already exceeds warning or rollover at adoption, preserve its
exact baseline. Name the remediation owner and ordered frontier. Permit only
finite growth needed to complete the containment transition, never unrelated
ordinary appends. Baselines do not widen; ceilings do not increase without a
separate reviewed authority proving that the surface's contract expanded.

### 6. Choose storage from information role

- Overwrite current state.
- Partition unique maintained material by stable semantics, not arbitrary line
  counts.
- Generate projections from smaller canonical units and prove freshness.
- Rotate ordered ledgers at whole-record boundaries, then move sealed history
  to a declared archive terminal.
- Remove duplicated prose only after proving its richer canonical source.
- Keep exact evidence in an immutable, retrievable store with an owner and a
  failure policy.

Sharding lowers per-read cost but does not control aggregate growth. Every
ordinary collection needs per-part, file-count, and aggregate controls. A
maintained-reference exception replaces decorative aggregate caps with exact
fresh authority for legitimate aggregate change; it does not make monoliths or
unindexed growth acceptable.

### 7. Migrate atomically and losslessly

One migration change should:

1. freeze the exact source boundary;
2. classify retained content as canonical, derived, duplicate, or archival;
3. create the new current view, semantic parts, sealed range, or archive;
4. record line counts, byte counts, and content digests;
5. prove semantic coverage and exact reconstruction where promised;
6. update indexes, routes, predecessor/successor links, and bootstrap pointers;
7. execute freshness, retrieval, ordering, uniqueness, link, and pressure
   checks;
8. remove a live duplicate only after its replacement or retrieval proof
   passes;
9. commit the transition as one recoverable unit.

If the project cannot prove what will be retained, stop before deletion.

### 8. Enforce the resulting tree

Use one bounded data plane of data-only local registries and one deterministic
checker path. The checker should run on every commit and in CI and fail on at
least:

- an unclassified live surface or route destination;
- missing owner, lifecycle, bounds, index, or retrieval contract;
- absolute, escaping, off-volume, or otherwise forbidden stored paths;
- line, byte, line-width, file-count, per-part, or aggregate overflow;
- unauthorized ceiling increases or widened transition baselines;
- stale generated projections or broken current/history links;
- mutable sealed or frozen units;
- archive identity or retrieval failures;
- incomplete collection indexes or cyclic routes;
- declared verifiers that were not actually executed.

Size checks prove boundedness, not semantic truth. A surface claiming currency
needs a separate, lifecycle-specific verifier calibrated against its canonical
source. Do not infer staleness globally from dates or file age.

### 9. Wire discovery without duplicating authority

Point every harness bootstrap at the receiving project's root doctrine files.
Update the commit workflow, doctrine registry, contributor navigation, and
user-facing manual only where their contracts genuinely change. Bootstrap
files discover the doctrine; they do not become its authority.

## Minimum adoption deliverables

A complete adoption produces:

- a project-owned `LIVE_DOCUMENT_SIZE_CONTAINMENT.md` with a local authority
  note separated from the neutral body;
- one task-tree and decision trail for adoption and each migration;
- a complete surface and route inventory;
- lifecycle, owner, authority, health target, enforcement ceiling, and verifier
  declarations for every governed surface;
- explicit transition-debt records for existing pressure;
- a deterministic checker plus fail-closed tests;
- unconditional commit-hook and CI wiring;
- bounded indexes and executable retrieval for retained history;
- synchronized bootstrap, commit workflow, maintained documentation, and
  resume state;
- a clean final census with no undeclared destination or project-owned artifact
  outside the repository-derived storage policy.

## Stop conditions

Stop and request direction when:

- two sources plausibly claim canonical authority for the same information;
- a lifecycle choice would change what users can directly browse;
- unique content or live consumers cannot be classified confidently;
- archival retention depends on an unverified or externally mutable system;
- exact reconstruction is promised but cannot be reproduced;
- a proposed ceiling increase has no demonstrated contract expansion;
- a migration would mix unrelated document families or cross task-tree owners;
- current work from another slice makes the repository non-handoff-ready.

A size warning is not itself a reason to delete, compress, or widen. It is a
reason to investigate under an owner.

## Anti-patterns

- Allowing `MEMORY.md` to grow without a hard bound.
- Trimming prose repeatedly while leaving the scaling field intact.
- Requiring `MEMORY.md` to change on every commit regardless of resume state.
- Routing a bounded file into an unbounded append-only neighbor.
- Splitting a monolith without bounding the resulting collection.
- Copying donor-project thresholds, paths, debt, or conclusions.
- Treating a generated index as canonical or allowing unique facts in it.
- Declaring a verifier without executing it in the unconditional gate.
- Treating file presence, co-staging, dates, or self-ticked boxes as freshness.
- Deleting live history before proving identity, retrieval, consumers, and
  replacement routes.
- Making bootstrap files the policy authority.

## Ready-to-forward director instruction

The following text can accompany this guide and the neutral doctrine:

> Adopt the project-owned Live-Document Size-Containment Doctrine because this
> repository already uses the Durable Agent Memory Architecture but still has
> bounded-pointer or routed-destination pressure. Do not unbound `MEMORY.md` and
> do not copy another project's thresholds, registry values, paths, or lifecycle
> decisions. Create task-tree ownership first; stabilize the resume pointer by
> removing scaling shadows and ceremonial commit coupling; then inventory every
> live document and route, classify utility and lifecycle, derive local health
> targets and inclusive ceilings, record exact transition debt, and implement
> lossless bounded views over mechanically retrievable durable stores. Wire one
> deterministic resulting-tree checker into the commit hook and CI. Commit each
> independently verified slice and stop before any deletion, authority conflict,
> unproved archive, or unauthorized ceiling increase.

## Completion test

The adoption is complete when a fresh session can load a small bounded current
view, follow one exact pointer to the relevant unit, retrieve any retained
history deterministically, and run one unconditional gate that rejects every
undeclared or over-limit live-document path—without requiring the reader to
load an ever-growing monolith.
