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
  Status: `done`
  Goal: `Partition accepted multi-domain actors into domain-local lowering IR.`
  Acceptance: `Parser/scheduler handoff can group ports, storage,
  transactions, rules, and child instances by declared domain while rejecting
  unowned cross-domain references before emission.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1204-isf-child-composition-clause-boundary.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1162-isf-public-actor-shell-interface-shape-audit.t t/1163-isf-public-actor-shell-transaction-shape-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1166-isf-public-actor-shell-rule-shape-audit.t t/1230-isf-library-import-resolution.t t/1215-isf-spawn-parameter-binding.t t/1241-isf-transaction-port-bindings.t t/1232-isf-actor-storage-declarations.t t/1247-isf-clock-domain-partition.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.5.2: partition domain lowering IR`

- ID: `ISF-CLOCK-DOMAINS.5.3`
  Status: `done`
  Goal: `Emit domain-specific scheduled .fsm artifacts.`
  Acceptance: `Each domain emits a single-clock scheduled .fsm artifact with
  the domain clock/reset and only domain-local state, rules, transactions,
  and generated helper signals.`
  Verification: `perl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Scheduler/ISF.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1117-isf-public-lower-result-files-audit.t t/1139-isf-public-lower-result-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1153-isf-public-cli-success-metadata-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1247-isf-clock-domain-partition.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.5.3: emit domain scheduled artifacts`

- ID: `ISF-CLOCK-DOMAINS.5.4`
  Status: `done`
  Goal: `Emit the multi-domain top and event-crossing artifact.`
  Acceptance: `The generated top wires domain modules and acknowledged event
  crossing primitives explicitly without hiding two-clock behavior inside a
  normal single-clock scheduled .fsm module.`
  Verification: `perl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1139-isf-public-lower-result-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1156-isf-public-lower-result-file-shape-audit.t t/1160-isf-public-actor-shell-value-shape-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1247-isf-clock-domain-partition.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-CLOCK-DOMAINS.5.4: emit multi-domain top artifact`

- ID: `ISF-CLOCK-DOMAINS.6`
  Status: `pending`
  Goal: `Add diagnostics, reports, and fixtures for multi-clock behavior.`
  Acceptance: `Schedule JSON exposes bounded domain and crossing metadata, direct unsafe crossings fail closed, and realistic CDC fixtures reach HDL where supported.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CLOCK-DOMAINS.6` | `pending` | Domain artifacts and generated top/CDC interface wiring now emit; the next executable leaf is bounded diagnostics, reports, and fixtures. |

## Selected Source Model

`ISF-CLOCK-DOMAINS.2` selected the source model, and
`ISF-CLOCK-DOMAINS.5.2` ships parser metadata plus the internal scheduler
handoff for that model. Existing `(clock name)` remains the shorthand for one
implicit actor domain named `default`.

The future multi-clock source surface is actor-scoped:

```lisp
(clock-domains
  (domain core (clock clk) :default)
  (domain bus  (clock bus_clk)))
```

Rules for the implemented parser metadata:

- `(clock name)` remains shorthand for one implicit actor domain named
  `default`.
- `(clock-domains ...)` replaces `(clock ...)` when an actor needs named
  domains. A source may not use both forms in the same actor, and
  actor-level `(reset ...)` may not be mixed with `(clock-domains ...)`.
- Domain names are unique non-empty identifiers inside the actor.
- Clock names inside domain entries are scalar signal names. Reusing the same
  clock signal for multiple domain names is rejected unless a later alias
  feature defines that semantics explicitly.
- A single-domain `(clock-domains ...)` block has an implicit default. A
  multi-domain block must mark exactly one domain as `:default`.
- Interface ports, actor-owned storage entries, transactions, rules, reusable
  `use` instances, and generated child activations may reference only
  actor-declared domain names through `(domain NAME)` annotations. Omitted
  domain references inherit the actor default domain when `(clock-domains ...)`
  is present.
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
- A single-domain `(clock-domains ...)` block has an implicit default and can
  still lower through the existing single-clock scheduled `.fsm` path. A
  multi-domain source builds a validated internal domain partition, then
  public `lower(...)` emits one scheduled `.fsm` artifact per declared domain.
  Public `lower(...)` also emits a generated multi-domain top with explicit
  CDC child-interface artifacts for accepted event crossings. Public
  `report(...)` and generated HDL for the multi-domain top/CDC path remain
  blocked until `ISF-CLOCK-DOMAINS.6` ships that leaf.

Malformed combinations fail closed:

- Unknown domain references.
- Duplicate domain names.
- Missing or duplicate default domain in a multi-domain actor.
- Mixing `(clock ...)` with `(clock-domains ...)`.
- Port, storage, transaction, rule, `use`, or child activation annotations
  that refer to domains not declared by the actor.
- Any direct read, write, trigger, activation, or binding that crosses domains
  without a shipped CDC primitive or protocol actor.
- Reusing one drive body from multiple domains without a safe reuse rule.
- Any attempt to use DT logic as asynchronous reset gating.

This source model deliberately leaves multi-domain report metadata and emitted
artifacts to `ISF-CLOCK-DOMAINS.5.3`, `.5.4`, and `.6`. Reset ownership and
the first legal crossing primitive are selected below.

## Selected Reset Ownership Model

`ISF-CLOCK-DOMAINS.3` selected reset ownership, and
`ISF-CLOCK-DOMAINS.5.2` ships parser validation for domain-owned reset
metadata. Existing actor-level `(reset ...)` remains the single-domain
shorthand.

The multi-domain source surface puts reset ownership inside each domain entry:

```lisp
(clock-domains
  (domain core (clock clk)     (reset rst_n) :default)
  (domain bus  (clock bus_clk) (reset (bus_rst_n async active_low))))
```

Rules for the implemented parser reset metadata:

- Existing actor-level `(clock name)` plus optional actor-level `(reset ...)`
  remains the shorthand for one implicit domain named `default`.
- An actor using `(clock-domains ...)` must not also use actor-level
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

This reset model deliberately leaves multi-domain report metadata and emitted
artifact structure to `ISF-CLOCK-DOMAINS.5.3`, `.5.4`, and `.6`. The first
legal CDC primitive is selected below.

## Selected Crossing Primitive

`ISF-CLOCK-DOMAINS.4` selects the first legal cross-domain interaction
primitive. `ISF-CLOCK-DOMAINS.5.4` ships parser support plus generated top
and CDC child-interface artifacts for that primitive.

The first planned crossing is an acknowledged single-bit event channel:

```lisp
(crossings
  (event rx_done
    (from bus  rx_done_bus)
    (to   core rx_done_core)
    (ready rx_done_ready)))
```

Rules for the accepted event primitive:

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
- The generated top represents the primitive as an explicit CDC child
  interface with source clock/reset, destination clock/reset, request, ready,
  and pulse ports. The concrete synchronizer RTL remains a generated-HDL
  follow-up owned by `ISF-CLOCK-DOMAINS.6`.
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

`ISF-CLOCK-DOMAINS.5.1` selected the future lowering artifact strategy.
`ISF-CLOCK-DOMAINS.5.2` ships the internal domain partition and fail-closed
direct-crossing checks before emission. `ISF-CLOCK-DOMAINS.5.3` emits the
domain-local scheduled `.fsm` artifacts from that partition.
`ISF-CLOCK-DOMAINS.5.4` emits the generated multi-domain top and explicit CDC
child-interface artifacts.

Rules for the current partition and emitted domain artifacts:

- Multi-domain actors are partitioned by declared domain in `LoweringIR`,
  grouping interface endpoints, storage entries, transactions, rules, reusable
  library uses, and generated child activations.
- Direct cross-domain reads, writes, triggers, activations, bindings, and
  multi-domain drive reuse are rejected before emission.
- Public `lower(...)` emits one scheduled `.fsm` artifact per declared domain
  named `<actor>__domain_<domain>.fsm`.
- A domain `.fsm` remains a normal single-clock scheduled module. Its `+system`
  clause uses only the domain clock and that domain's reset policy.
- Domain artifacts contain only domain-owned interface endpoints, storage,
  transactions, rules, child activations, generated helper signals, and
  generated event primitive endpoints for that domain.
- No domain `.fsm` directly reads, writes, triggers, activates, or binds a
  signal owned by another domain.
- Multi-domain structure is represented by a generated top artifact named
  `<actor>_top.fsm`. The top owns wiring only; it does not hide clocked
  behavior in top-level DT logic.
- The acknowledged event primitive is emitted as an explicit CDC child
  interface embedded in the generated top through `?rtl`/`?rtlif`, with source
  clock/reset, destination clock/reset, request, ready, and pulse ports. It is
  not lowered as an ordinary single-domain `.fsm` state chain.
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
- `2026-05-15`: The selected source model is actor-scoped named domains.
  Ports, storage, transactions, rules, and child instances may only reference
  domains declared by the actor; drives inherit the activation-site domain.
  Parser support and the internal partitioning handoff shipped later in
  `ISF-CLOCK-DOMAINS.5.2`.
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
- `2026-05-15`: The parser now accepts `(clock-domains ...)` metadata and
  `(domain NAME)` ownership annotations for ports, storage, transactions,
  rules, reusable `use` instances, and generated child activations.
  `LoweringIR` builds an internal domain partition and rejects unowned direct
  cross-domain access before emission.
- `2026-05-15`: Public multi-domain `lower(...)` now emits one normal
  single-clock scheduled `.fsm` artifact per declared domain from the
  validated partition. Public `report(...)`, generated top wiring, and CDC
  artifacts remain later leaves.
- `2026-05-15`: Public multi-domain `lower(...)` now emits a generated
  `<actor>_top.fsm` that instantiates the domain modules and explicit CDC
  child-interface artifacts for accepted event crossings. Public `report(...)`
  and generated HDL for the multi-domain top/CDC path remain future work.

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
| `2026-05-15` | `ISF-CLOCK-DOMAINS.5.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1204-isf-child-composition-clause-boundary.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1162-isf-public-actor-shell-interface-shape-audit.t t/1163-isf-public-actor-shell-transaction-shape-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1166-isf-public-actor-shell-rule-shape-audit.t t/1230-isf-library-import-resolution.t t/1215-isf-spawn-parameter-binding.t t/1241-isf-transaction-port-bindings.t t/1232-isf-actor-storage-declarations.t t/1247-isf-clock-domain-partition.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.5.3` | `perl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Scheduler/ISF.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1117-isf-public-lower-result-files-audit.t t/1139-isf-public-lower-result-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1153-isf-public-cli-success-metadata-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1247-isf-clock-domain-partition.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-15` | `ISF-CLOCK-DOMAINS.5.4` | `perl -c bin/fsmgen`; `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1139-isf-public-lower-result-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1156-isf-public-lower-result-file-shape-audit.t t/1160-isf-public-actor-shell-value-shape-audit.t t/1165-isf-public-actor-shell-timing-shape-audit.t t/1247-isf-clock-domain-partition.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CLOCK-DOMAINS.1` | `ISF-CLOCK-DOMAINS.1: capture multi-clock backlog` | Documents the shipped single-clock boundary and proposed multi-clock/CDC design tree. |
| `ISF-CLOCK-DOMAINS.2` | `ISF-CLOCK-DOMAINS.2: specify domain source model` | Selects actor-scoped named domains as the future source model without shipping parser/lowering support. |
| `ISF-CLOCK-DOMAINS.3` | `ISF-CLOCK-DOMAINS.3: specify domain reset ownership` | Selects per-domain reset ownership and forbids DT-generated asynchronous reset glue without shipping parser/lowering support. |
| `ISF-CLOCK-DOMAINS.4` | `ISF-CLOCK-DOMAINS.4: specify event crossing primitive` | Selects an acknowledged single-bit event channel as the first legal future crossing primitive. |
| `ISF-CLOCK-DOMAINS.5.1` | `ISF-CLOCK-DOMAINS.5.1: specify lowering artifacts` | Selects per-domain scheduled .fsm artifacts plus explicit generated top and CDC artifacts as the future lowering strategy. |
| `ISF-CLOCK-DOMAINS.5.2` | `ISF-CLOCK-DOMAINS.5.2: partition domain lowering IR` | Adds parser metadata, internal domain partitioning, and fail-closed direct crossing checks while keeping multi-domain public emission/reporting blocked. |
| `ISF-CLOCK-DOMAINS.5.3` | `ISF-CLOCK-DOMAINS.5.3: emit domain scheduled artifacts` | Emits per-domain scheduled .fsm artifacts while keeping report projection and generated multi-domain top/CDC artifacts blocked. |
| `ISF-CLOCK-DOMAINS.5.4` | `ISF-CLOCK-DOMAINS.5.4: emit multi-domain top artifact` | Emits generated multi-domain top wiring plus explicit CDC child-interface artifacts while keeping report projection and HDL implementation blocked. |

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
- `2026-05-15`: Completed `ISF-CLOCK-DOMAINS.5.2`, accepting selected
  domain metadata, building an internal domain partition, and rejecting
  unowned direct cross-domain references before emission; current frontier
  advances to `ISF-CLOCK-DOMAINS.5.3`.
- `2026-05-15`: Completed `ISF-CLOCK-DOMAINS.5.3`, emitting one
  domain-local scheduled `.fsm` artifact per declared domain; current frontier
  advances to `ISF-CLOCK-DOMAINS.5.4`.
- `2026-05-15`: Completed `ISF-CLOCK-DOMAINS.5.4`, emitting the generated
  multi-domain top and explicit CDC child-interface artifacts; current
  frontier advances to `ISF-CLOCK-DOMAINS.6`.
