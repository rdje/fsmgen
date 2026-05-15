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
  Status: `done`
  Goal: `Specify reset ownership for each clock domain.`
  Acceptance: `The model distinguishes synchronous resets per domain from asynchronous reset pins and forbids arbitrary DT glue on async reset trees.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.3: specify domain reset ownership`

- ID: `ISF-CLOCK-DOMAINS.4`
  Status: `done`
  Goal: `Specify cross-domain interaction primitives.`
  Acceptance: `The first shipped CDC surface identifies legal crossings, such as synchronized single-bit events, handshakes, or dual-clock FIFO-like actors, and rejects unowned direct crossings.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.4: specify event crossing primitive`

- ID: `ISF-CLOCK-DOMAINS.5`
  Status: `active`
  Goal: `Lower multi-domain ISF into explicit scheduled artifacts.`
  Children: `ISF-CLOCK-DOMAINS.5.1`, `ISF-CLOCK-DOMAINS.5.2`,
  `ISF-CLOCK-DOMAINS.5.3`, `ISF-CLOCK-DOMAINS.5.4`

- ID: `ISF-CLOCK-DOMAINS.5.1`
  Status: `done`
  Goal: `Specify the multi-domain lowering artifact strategy.`
  Acceptance: `The task tree, spec, and book state how future lowering keeps
  domain-local scheduled .fsm artifacts reviewable while representing
  top-level wiring and CDC primitive artifacts explicitly.`
  Verification: `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.5.1: specify lowering artifacts`

- ID: `ISF-CLOCK-DOMAINS.5.2`
  Status: `pending`
  Goal: `Partition accepted multi-domain actors into domain-local lowering IR.`
  Acceptance: `Parser/scheduler handoff can group ports, storage,
  transactions, rules, and child instances by declared domain while rejecting
  unowned cross-domain references before emission.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.5.3`
  Status: `pending`
  Goal: `Emit domain-specific scheduled .fsm artifacts.`
  Acceptance: `Each domain emits a single-clock scheduled .fsm artifact with
  the domain clock/reset and only domain-local state, rules, transactions,
  and generated helper signals.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CLOCK-DOMAINS.5.4`
  Status: `pending`
  Goal: `Emit the multi-domain top and event-crossing artifact.`
  Acceptance: `The generated top wires domain modules and acknowledged event
  crossing primitives explicitly without hiding two-clock behavior inside a
  normal single-clock scheduled .fsm module.`
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
| 1 | `ISF-CLOCK-DOMAINS.5.2` | `pending` | The artifact strategy is selected; the next executable leaf is the domain-partitioning IR handoff. |

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

This source model deliberately leaves report metadata and lowering artifacts to
`ISF-CLOCK-DOMAINS.5` and `ISF-CLOCK-DOMAINS.6`. Reset ownership and the first
legal crossing primitive are selected below.

## Selected Reset Ownership Model

`ISF-CLOCK-DOMAINS.3` selects the planned reset ownership model without
shipping parser or lowering support yet. Existing `(reset ...)` remains the
only implemented reset syntax today.

The future multi-domain source surface puts reset ownership inside each domain
entry:

```lisp
(clock-domains
  (domain core (clock clk)     (reset rst_n) :default)
  (domain bus  (clock bus_clk) (reset (bus_rst_n async active_low))))
```

Rules for the planned reset syntax:

- Existing actor-level `(clock name)` plus optional actor-level `(reset ...)`
  remains the shorthand for one implicit domain named `default`.
- A future actor using `(clock-domains ...)` must not also use actor-level
  `(clock ...)` or actor-level `(reset ...)`.
- Each domain owns zero or one reset. A domain with no reset clause has no
  generated reset for its clocked state.
- Domain reset payloads reuse the shipped reset value rules: flat
  `(reset name)` is synchronous with inferred polarity, list forms may include
  `async`, `active_low`, or `active_high`, and reset names must be scalar.
- A synchronous domain reset is sampled only on that domain's clock edge.
- An asynchronous domain reset is a direct external reset pin for that domain's
  clocked state. It is not a data signal, handshake, or CDC primitive.
- The same reset signal may be named by multiple domains only when kind and
  polarity match exactly. Such fanout describes one external reset pin
  reaching multiple domains; it does not synchronize data between them.
- Child instances do not create reset ownership. A child reset binding connects
  the child local-domain reset pin to a signal in the selected parent domain
  or to an explicitly shared external reset pin under the same kind/polarity
  rules.

Malformed reset combinations fail closed:

- Duplicate reset clauses in one domain.
- Actor-level `(reset ...)` mixed with `(clock-domains ...)`.
- Reset payloads that use expressions, nested domain names, or non-scalar
  reset names.
- Reset signal reuse with conflicting synchronous/asynchronous kind or
  conflicting polarity.
- Any rule, transaction, drive, DT, or assignment that drives, gates, or
  computes an asynchronous reset tree.
- Any attempt to treat reset assertion/deassertion as an ordinary
  cross-domain data event.

This reset model deliberately leaves report metadata and lowering artifact
structure to `ISF-CLOCK-DOMAINS.5` and `ISF-CLOCK-DOMAINS.6`. The first legal
CDC primitive is selected below.

## Selected Crossing Primitive

`ISF-CLOCK-DOMAINS.4` selects the first legal cross-domain interaction
primitive without shipping parser or lowering support yet. Existing ISF still
has no accepted cross-domain source syntax.

The first planned crossing is an acknowledged single-bit event channel:

```lisp
(crossings
  (event rx_done
    (from bus  rx_done_bus)
    (to   core rx_done_core)
    (ready rx_done_ready)))
```

Rules for the planned event primitive:

- `(crossings ...)` is actor-scoped and references only domains declared in
  `(clock-domains ...)`.
- `(event NAME ...)` crosses one control event from a source domain to a
  destination domain. It carries no data payload.
- `(from DOMAIN SIGNAL)` names the source-domain event request signal.
- `(to DOMAIN SIGNAL)` names the generated destination-domain one-cycle event
  pulse.
- `(ready SIGNAL)` names the generated source-domain ready signal. Source
  logic may request a new event only when this ready signal is true.
- The source and destination domains must be different declared domains.
- The primitive has at most one outstanding event. After an accepted source
  event, `ready` deasserts until an acknowledgement returns from the
  destination domain.
- The destination pulse occurs after synchronizer/acknowledgement latency.
  No same-cycle relationship is promised between the source request and
  destination pulse.
- The primitive owns its generated request toggle, destination synchronizer,
  destination pulse, acknowledgement synchronizer, and source ready logic.
- Payload transfer, multi-bit data, level sampling, reset crossing, and
  FIFO-like storage are not part of this first primitive.

Unowned crossings fail closed:

- Reading a signal, storage entry, port, transaction state, or generated helper
  from a different domain without an event primitive or future legal crossing.
- Writing or driving a target owned by another domain.
- Triggering or activating a transaction in another domain without a legal
  crossing.
- Binding a parent and child port across different domains without a crossing
  primitive or future protocol actor owning that path.
- Treating a reset assertion/deassertion as an event primitive.

Future crossing surfaces, such as acknowledged level handshakes, request/data
channels, and dual-clock FIFO-like actors, remain backlog until their source
syntax, runtime semantics, lowering, diagnostics, reports, and fixtures are
specified.

## Selected Lowering Artifact Strategy

`ISF-CLOCK-DOMAINS.5.1` selects the future lowering artifact strategy without
shipping parser or lowering support yet.

Rules for future lowering:

- Multi-domain actors are partitioned into domain-local scheduled artifacts.
- Each declared domain emits one scheduled `.fsm` artifact named
  `<actor>__domain_<domain>.fsm`.
- A domain `.fsm` remains a normal single-clock scheduled module. Its `+system`
  clause uses only the domain clock and that domain's reset policy.
- Domain artifacts contain only domain-owned interface endpoints, storage,
  transactions, rules, child activations, generated helper signals, and
  generated event primitive endpoints for that domain.
- No domain `.fsm` directly reads, writes, triggers, activates, or binds a
  signal owned by another domain.
- Multi-domain structure is represented by a generated top artifact named
  `<actor>_top.fsm` or by a successor top artifact if the existing `.fsm`
  composition-top form cannot represent all required system ports. The top
  owns wiring only; it does not hide clocked behavior in top-level DT logic.
- The acknowledged event primitive is emitted as an explicit generated CDC
  artifact with source clock/reset, destination clock/reset, request toggle,
  destination synchronizer, destination pulse, acknowledgement synchronizer,
  and source ready logic. It is not lowered as an ordinary single-domain `.fsm`
  state chain.
- Schedule-report metadata for domains, generated top wiring, and crossing
  artifacts is owned by `ISF-CLOCK-DOMAINS.6`.

This strategy keeps the existing `.fsm` scheduled artifact meaning intact:
`.fsm` remains a reviewable single-clock scheduled module unless a future leaf
explicitly defines a new multi-clock `.fsm` structure.

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
- `2026-05-15`: Future multi-domain resets are domain-owned. Synchronous
  resets are sampled on the owning domain clock; asynchronous resets are direct
  external reset pins and must not be generated or gated through ISF DT logic.
- `2026-05-15`: The first future legal CDC primitive is an acknowledged
  single-bit event channel with source-domain ready, destination-domain pulse,
  and no data payload. Ordinary cross-domain reads/writes/triggers/bindings
  remain fail-closed.
- `2026-05-15`: Future lowering keeps domain behavior in one single-clock
  scheduled `.fsm` artifact per domain and represents multi-domain wiring plus
  CDC primitives as explicit generated artifacts. Normal `.fsm` modules are
  not silently widened into multi-clock scheduled modules.

## Open Questions

- How should schedule reports summarize domains and crossings without exposing
  unstable internal lowering objects?
- How should generated HDL validation distinguish simulation-only assertions
  from synthesizable CDC structure checks?

## Blockers

- None for the current frontier.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.1` | `./bin/ci-regression quick`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.2` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.3` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.4` | `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.5.1` | `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CLOCK-DOMAINS.1` | `ISF-CLOCK-DOMAINS.1: capture multi-clock backlog` | Documents the shipped single-clock boundary and proposed multi-clock/CDC design tree. |
| `ISF-CLOCK-DOMAINS.2` | `ISF-CLOCK-DOMAINS.2: specify domain source model` | Selects actor-scoped named domains as the future source model without shipping parser/lowering support. |
| `ISF-CLOCK-DOMAINS.3` | `ISF-CLOCK-DOMAINS.3: specify domain reset ownership` | Selects per-domain reset ownership and forbids DT-generated asynchronous reset glue without shipping parser/lowering support. |
| `ISF-CLOCK-DOMAINS.4` | `ISF-CLOCK-DOMAINS.4: specify event crossing primitive` | Selects an acknowledged single-bit event channel as the first legal future crossing primitive. |
| `ISF-CLOCK-DOMAINS.5.1` | `ISF-CLOCK-DOMAINS.5.1: specify lowering artifacts` | Selects per-domain scheduled .fsm artifacts plus explicit generated top and CDC artifacts as the future lowering strategy. |

## Changelog

- `2026-05-15`: Created proposed tree and completed the first documentation
  leaf that records the current single-clock-domain boundary.
- `2026-05-15`: Activated the tree and completed
  `ISF-CLOCK-DOMAINS.2`, selecting actor-scoped named domains as the future
  source model; current frontier advances to `ISF-CLOCK-DOMAINS.3`.
- `2026-05-15`: Completed `ISF-CLOCK-DOMAINS.3`, selecting per-domain reset
  ownership for the future source model; current frontier advances to
  `ISF-CLOCK-DOMAINS.4`.
- `2026-05-15`: Completed `ISF-CLOCK-DOMAINS.4`, selecting the acknowledged
  single-bit event channel as the first legal future CDC primitive; current
  frontier advances to `ISF-CLOCK-DOMAINS.5`.
- `2026-05-15`: Split `ISF-CLOCK-DOMAINS.5` into executable lowering leaves
  and completed `ISF-CLOCK-DOMAINS.5.1`, selecting the future lowering
  artifact strategy; current frontier advances to `ISF-CLOCK-DOMAINS.5.2`.
