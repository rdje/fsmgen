# ISF-CLOCK-DOMAINS: Multi-Clock And CDC Semantics

## Metadata

- Tree ID: `ISF-CLOCK-DOMAINS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-15`
- Last updated: `2026-05-15`
- Owner: repo-local workflow

## Goal

Define and eventually ship a deliberate ISF model for multi-clock,
asynchronous, and interacting clock-domain designs.

## Non-Goals

- Do not treat different clock signal names as different clock domains without
  an explicit source-level domain model.
- Do not infer CDC safety from direct signal reads, direct signal writes, or
  generated-top system-port links.
- Do not add arbitrary combinational logic to asynchronous reset trees.
- Do not change the shipped single-clock actor semantics in this tree without
  a focused compatibility and migration leaf.

## Acceptance Criteria

- The current one-clock-domain ISF boundary is documented in the spec, book,
  roadmap, and task-tree index.
- Future implementation leaves define source syntax, lowering, diagnostics,
  schedule-report projection, and regression fixtures before accepting any
  multi-clock source.
- Cross-domain interaction has explicit runtime semantics. Direct same-cycle
  sampling across domains is rejected unless a shipped CDC primitive or
  protocol construct owns the crossing.
- The completed leaves are committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CLOCK-DOMAINS`
  Status: `active`
  Goal: `Design and ship explicit ISF multi-clock and CDC semantics.`
  Children: `ISF-CLOCK-DOMAINS.1`, `ISF-CLOCK-DOMAINS.2`,
  `ISF-CLOCK-DOMAINS.3`, `ISF-CLOCK-DOMAINS.4`,
  `ISF-CLOCK-DOMAINS.5`, `ISF-CLOCK-DOMAINS.6`

- ID: `ISF-CLOCK-DOMAINS.1`
  Status: `done`
  Goal: `Capture the current single-clock boundary and backlog the multi-clock/CDC work.`
  Acceptance: `Spec, mdBook, roadmap, task-tree index, README, and live docs state that ISF currently has one clock domain per actor/generated top and that multi-clock/CDC semantics remain unshipped.`
  Verification: `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.1: capture multi-clock backlog`

- ID: `ISF-CLOCK-DOMAINS.2`
  Status: `done`
  Goal: `Specify the source model for named clock domains.`
  Acceptance: `The book and spec define whether domains are actor-scoped, port-scoped, transaction-scoped, child-instance-scoped, or a combination, and malformed combinations fail closed.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.2: specify domain source model`

- ID: `ISF-CLOCK-DOMAINS.3`
  Status: `pending`
  Goal: `Specify reset ownership for each clock domain.`
  Acceptance: `The model distinguishes synchronous resets per domain from asynchronous reset pins and forbids arbitrary DT glue on async reset trees.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.4`
  Status: `pending`
  Goal: `Specify cross-domain interaction primitives.`
  Acceptance: `The first shipped CDC surface identifies legal crossings, such as synchronized single-bit events, handshakes, or dual-clock FIFO-like actors, and rejects unowned direct crossings.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.5`
  Status: `pending`
  Goal: `Lower multi-domain ISF into explicit scheduled artifacts.`
  Acceptance: `Lowering emits reviewable domain-specific scheduled .fsm artifacts or a documented multi-domain .fsm structure with clear clock/reset ownership.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.6`
  Status: `pending`
  Goal: `Add diagnostics, reports, and fixtures for multi-clock behavior.`
  Acceptance: `Schedule JSON exposes bounded domain and crossing metadata, direct unsafe crossings fail closed, and realistic CDC fixtures reach HDL where supported.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CLOCK-DOMAINS.3` | `pending` | Reset ownership is part of the selected actor-scoped domain model and must be specified before lowering. |
| 2 | `ISF-CLOCK-DOMAINS.4` | `pending` | Cross-domain behavior needs explicit legal primitives before generated RTL can be considered meaningful. |

## Selected Source Model

`ISF-CLOCK-DOMAINS.2` selects the planned source model without shipping parser
or lowering support yet. Existing `(clock name)` remains the only implemented
clock syntax today.

The future multi-clock source surface is actor-scoped:

```lisp
(clock-domains
  (domain core (clock clk) :default)
  (domain bus  (clock bus_clk)))
```

Rules for the planned syntax:

- `(clock name)` remains shorthand for one implicit actor domain named
  `default`.
- `(clock-domains ...)` replaces `(clock ...)` when an actor needs named
  domains. A source may not use both forms in the same actor.
- Domain names are unique non-empty identifiers inside the actor.
- Clock names inside domain entries are scalar signal names. Reusing the same
  clock signal for multiple domain names is rejected unless a later alias
  feature defines that semantics explicitly.
- A single-domain `(clock-domains ...)` block has an implicit default. A
  multi-domain block must mark exactly one domain as `:default`.
- Interface ports, actor-owned storage entries, transactions, rules, and
  generated/reusable child instances may reference only actor-declared domain
  names. Omitted domain references inherit the actor default domain.
- Drives do not own clock domains. A drive body inherits the domain of its
  activation site, and sharing a drive across multiple domains remains
  fail-closed until a later leaf defines a safe reuse rule.
- A transaction or rule is wholly in one domain. ISF does not split one
  transaction, rule, or ordered transaction body across multiple domains.
- Interface-port domain annotations describe the port's owning domain at the
  actor boundary. They do not by themselves authorize another domain to sample
  or drive that port.
- Child-instance domain annotations bind the child instance's local domain to
  a parent actor domain. They are not CDC primitives; cross-domain parent/child
  interaction still needs an explicit legal crossing surface.

Malformed combinations fail closed:

- Unknown domain references.
- Duplicate domain names.
- Missing or duplicate default domain in a multi-domain actor.
- Mixing `(clock ...)` with `(clock-domains ...)`.
- Port, storage, transaction, rule, or child annotations that refer to domains
  not declared by the actor.
- Any direct read, write, trigger, activation, or binding that crosses domains
  without a shipped CDC primitive or protocol actor.
- Any attempt to use DT logic as asynchronous reset gating.

This source model deliberately does not select reset ownership details,
crossing primitives, report metadata, or lowering artifacts. Those are owned by
`ISF-CLOCK-DOMAINS.3` through `ISF-CLOCK-DOMAINS.6`.

## Decisions

- `2026-05-15`: Current ISF remains single-clock-domain. A different signal
  name in `(clock ...)` or a library binding is only signal-name remapping
  inside the one-domain model.
- `2026-05-15`: Multi-clock, asynchronous, and interacting clock-domain
  support must be designed as a public feature, not inferred from existing
  composition links or direct signal access.
- `2026-05-15`: Direct cross-domain same-cycle reads/writes are not a safe
  default. A shipped CDC primitive or protocol actor must own the runtime
  crossing semantics.
- `2026-05-15`: The selected future source model is actor-scoped named
  domains. Ports, storage, transactions, rules, and child instances may only
  reference domains declared by the actor; drives inherit the activation-site
  domain. This is not parser support yet.

## Open Questions

- Which CDC primitive ships first: event synchronizer, level handshake,
  request/acknowledge channel, dual-clock FIFO, or another actor-library
  pattern?
- How should schedule reports summarize domains and crossings without exposing
  unstable internal lowering objects?
- How should generated HDL validation distinguish simulation-only assertions
  from synthesizable CDC structure checks?

## Blockers

- No first CDC primitive has been selected. This blocks
  `ISF-CLOCK-DOMAINS.4` but does not block the reset-ownership specification
  leaf.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.1` | `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.2` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CLOCK-DOMAINS.1` | `ISF-CLOCK-DOMAINS.1: capture multi-clock backlog` | Documents the shipped single-clock boundary and proposed multi-clock/CDC design tree. |
| `ISF-CLOCK-DOMAINS.2` | `ISF-CLOCK-DOMAINS.2: specify domain source model` | Selects actor-scoped named domains as the future source model without shipping parser/lowering support. |

## Changelog

- `2026-05-15`: Created proposed tree and completed the first documentation
  leaf that records the current single-clock-domain boundary.
- `2026-05-15`: Activated the tree and completed
  `ISF-CLOCK-DOMAINS.2`, selecting actor-scoped named domains as the future
  source model; current frontier advances to `ISF-CLOCK-DOMAINS.3`.
