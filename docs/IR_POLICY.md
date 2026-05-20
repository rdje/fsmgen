# FSMGen IR Policy

This document defines the repo-local policy for adding, extending, exposing,
or retiring compiler IR and IR-like structures in FSMGen.

The goal is not to reduce FSMGen to one universal IR. The goal is to keep each
phase boundary explicit enough that future work can be reviewed, recovered
after a crash, and integrated without accidental IR sprawl.

## Scope

This policy applies when work creates or changes any durable structured
compiler surface that one phase hands to another phase, stores for later
emission/reporting, or exposes through public metadata.

Examples that are in scope:

- parser semantic models such as direct-root `CoreAST`;
- scheduler or planner IR such as ISF `LoweringIR` and `Composition::Plan`;
- forward IR layers such as `IntentHIR`, `LoweredRTLIR`, and
  `StructuralRTLIR`;
- public report projections such as schedule JSON, normalized semantic JSON,
  public contract metadata, and composition provenance;
- compatibility mirrors such as `module_info` when they gain new durable
  fields.

Examples that are not automatically in scope:

- a short-lived local hash inside one function;
- a temporary loop variable or helper return value that is consumed
  immediately by the same owner;
- rendered HDL text after all structured decisions have already been made.

If a helper starts gaining named consumers, public report fields, persistence,
or cross-phase meaning, it becomes in scope and must be classified.

## Current Boundaries

Current canonical in-process boundaries are:

- direct `.fsm` / `.dt` semantic `CoreAST` for direct-root source semantics;
- private ISF parser actor metadata and ISF scheduler `LoweringIR` for the
  `.isf` path;
- `Composition::Plan` for composition connectivity and planning truth;
- `IntentHIR` for forward semantic intent;
- `LoweredRTLIR` for lowered grouped behavior facts;
- `StructuralRTLIR` for structural/connectivity facts and backend-facing
  structure.

Current canonical public downstream truth is bounded projection, not raw IR:

- emitted `.fsm`, generated HDL, and generated composition artifacts;
- schedule JSON and its advertised schema/version metadata;
- normalized semantic JSON and its advertised schema/version metadata;
- public interface contract metadata;
- composition provenance and serializable snapshots where explicitly exposed.

`module_info` remains a compatibility/result surface. It may mirror useful
facts, but it must not become a second canonical compiler IR beside the named
phase boundaries.

## Required IR Record

Before a new IR, phase boundary, or durable IR-like surface lands, the owning
task-tree leaf must document:

- **Name:** the exact IR/surface name and the package/file that owns it.
- **Phase:** one of parsed syntax, semantic intent, scheduling, lowered
  behavior, structural/connectivity, backend/emission, composition planning,
  or report/contract projection.
- **Owner:** the module or small owner family allowed to build and mutate it.
- **Producers:** every path that constructs it.
- **Consumers:** every path that reads it, emits from it, or reports it.
- **Invariants:** the facts that must be true after construction and before
  consumption.
- **Mutation policy:** whether callers receive a live object, cloned data, or
  a sanitized projection.
- **Public/private status:** whether the raw surface is private, bounded
  public metadata, or a versioned public schema.
- **Serialization/report contract:** every public key family, schema version,
  artifact shape, or contract metadata field it changes.
- **Validation:** focused checks for construction invariants and public
  contract shape; broader gates when the surface feeds generated output.
- **Documentation impact:** book/spec/downstream/live-doc updates required by
  any user-visible or downstream-visible behavior.
- **Migration/retirement plan:** required when the new surface overlaps an
  older one or is temporary.

Documentation-only policy or classification work still needs task-tree
ownership. Behavior-bearing code, tests, source, config, or generated-artifact
changes may not begin without task-tree ownership first.

## Reuse And Creation Rules

Prefer reuse when the new facts belong to an existing phase boundary and can
respect that boundary's invariants.

Extend an existing IR when:

- the producer and consumer set already belong to that phase;
- the new data is required by multiple consumers or a public report projection;
- the extension can be documented with a clear invariant and validation;
- public projections can remain bounded and schema-compatible.

Create a new IR only when:

- the new structure represents a distinct compiler phase boundary;
- reusing an existing IR would mix parsed syntax, semantic intent, scheduling,
  lowered behavior, structural connectivity, backend emission, composition
  planning, or report projection in a misleading way;
- at least two owners or phases need a stable handoff that a local helper
  cannot safely provide;
- the task-tree leaf records the required IR record above.

Use a textual handoff only when the text is deliberately the reviewable or
debuggable phase boundary. The current `.isf -> scheduled .fsm -> normal .fsm
pipeline` handoff is allowed because the scheduled `.fsm` artifact is a
concrete inspectable output. A textual handoff still needs tests and docs for
its artifact contract.

Keep a structure private when it is an implementation detail. Private
structures may have focused tests, but downstream consumers must see only
bounded projections, public contract metadata, or emitted artifacts.

## Public Contract Rules

Raw private compiler objects must not be exported as downstream APIs.

If a public report or metadata surface changes, the same slice must update:

- the contract owner module or manifest metadata when one exists;
- focused contract tests or golden fixtures;
- live docs and task-tree evidence;
- the mdBook and downstream integration docs when users or downstream tools
  are affected.

Public schemas may evolve additively when the evolution policy for that schema
allows it. Removing, renaming, or changing the meaning of public keys requires
an explicit compatibility plan and task-tree ownership.

## Defensive Copy Rule

IR and projection owners must state whether returned data is live, cloned, or
sanitized.

Caller-facing result hashes and JSON-like projections should be fresh or
defensively copied unless sharing is an intentional, documented contract. A
caller mutating a returned report or `module_info` branch must not rewrite the
canonical in-process IR, another projection branch, or a later generation
result.

## Temporary And Retired Surfaces

A temporary IR or compatibility mirror is allowed only with:

- the reason it exists;
- the owner responsible for retiring or stabilizing it;
- the consumers that still need it;
- the public/private status during the transition;
- a task-tree follow-up or explicit decision that retirement is not planned.

Retirement must be as deliberate as creation. Removing or demoting a surface
requires proof that its producers, consumers, public report keys, docs, and
tests have been migrated or intentionally removed.

## Review Checklist

Before merging an IR-affecting slice, verify:

- the owning task-tree leaf names the IR/surface and phase;
- no private raw object is accidentally promoted to public API;
- public projections have a bounded contract and tests;
- live docs and book/spec/downstream docs are updated when visible behavior or
  downstream surfaces change;
- `module_info` remains a compatibility mirror rather than compiler truth;
- generated artifacts still come from the intended canonical phase boundary;
- temporary overlap has a migration or retirement note.
