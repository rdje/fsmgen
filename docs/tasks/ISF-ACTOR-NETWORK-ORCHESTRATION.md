# ISF-ACTOR-NETWORK-ORCHESTRATION: Actor Network Orchestration

## Metadata

- Tree ID: `ISF-ACTOR-NETWORK-ORCHESTRATION`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-18`
- Last updated: `2026-05-18`
- Owner: repo-local workflow

## Goal

Track the ISF actor-network abstraction, now framed as Actor Transfer Level
(`ATL`): static hierarchies or networks of actors where actors play the
role that flops/registers play in RTL. Data and control information move
between actors, between concurrent groups of actors, and between actors and
top-level pins. One or more actors can orchestrate system behavior by
triggering peer/sub-actors or their transactions, synchronizing on
scheduler-visible events, and moving data through explicit bindings while
FSMGen owns scheduling and lowering to explicit `.fsm`.

## Non-Goals

- Replacing transactions, rules, stages, resources, or current actor-local
  ISF semantics.
- Inferring a whole system from an informal prose protocol description.
- Dynamic hardware creation or runtime actor instantiation.
- Starting implementation before the source contract, generated-top model,
  event semantics, data movement model, top-level actor/network boundary,
  scheduling ownership, and failure policy are clarified with the user.
- Claiming this as `IAL2` while it remains explicit `.isf` syntax with
  scheduler-visible actors, events, bindings, and constraints.

## Acceptance Criteria

- The actor-network source model is clarified before implementation,
  including the top-level actor-as-network model and the RTL-like ATL mental
  model where actors, rather than flops, are the named transfer endpoints.
- The roadmap and mdBook distinguish this as active IAL1 clarification/design
  work unless a later clarification explicitly moves it to IAL2.
- Static actor hierarchy/network elaboration, actor event ports,
  orchestration triggers, actor-to-actor data movement, top-level pin
  boundary movement, concurrent actor-group scheduling, compact plus verbose
  syntax variants, schedule-report visibility, and fail-closed diagnostics are
  decomposed into reviewable leaves.
- Each implementation leaf has tests, spec/book updates, and public-contract
  synchronization appropriate to its shipped surface.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION`
  Status: `active`
  Goal: `Design and eventually ship static ISF Actor Transfer Level actor-network orchestration.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.4`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5`, `ISF-ACTOR-NETWORK-ORCHESTRATION.6`, `ISF-ACTOR-NETWORK-ORCHESTRATION.7`, `ISF-ACTOR-NETWORK-ORCHESTRATION.8`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.1`
  Status: `in_progress`
  Goal: `Clarify the actor-network source contract with the user.`
  Acceptance: `A design note records whether actors are declared as nested actors, imported/library actors, peer actors in a scoped network clause, or flat top-level ATL clauses; how the whole network acts as a top-level actor; how top-level actor transactions/rules trigger actors or transactions; how one-cycle events are named and synchronized; how data moves between actors, concurrent actor groups, and top-level pins; how scheduling responsibility is split between local actor schedules and network-level orchestration; how compact and verbose syntax variants relate; and which forms must fail closed in the first implementation slice.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending commit for ATL clarification slice`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.2`
  Status: `pending`
  Goal: `Specify the static actor-network/ATL syntax and public contract.`
  Acceptance: `The ISF spec, downstream integration handoff, public contract, and mdBook define the accepted compact and verbose source forms, event/data binding vocabulary, schedule-report shape, generated artifact names, and explicit non-claims.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.3`
  Status: `pending`
  Goal: `Ship the smallest top-level actor-as-network elaboration slice.`
  Acceptance: `A top-level actor can own a static ATL body with one child actor instance, explicit static bindings, generated artifacts remain reviewable, and unsupported dynamic or ambiguous actor graphs fail closed.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4`
  Status: `pending`
  Goal: `Ship actor event trigger and sync semantics.`
  Acceptance: `One actor can emit a named one-cycle event pulse that another actor can use as an activation/sync source through explicit network wiring, with fan-in/fan-out and same-cycle ambiguity policies documented and tested.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5`
  Status: `pending`
  Goal: `Ship actor-to-actor data movement bindings.`
  Acceptance: `Explicit data channels or port bindings move scalar payloads between actor instances under scheduler-visible timing rules, with storage/report provenance and fail-closed diagnostics for unsupported payload lifetimes.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.6`
  Status: `pending`
  Goal: `Ship top-level pin to actor-network data movement.`
  Acceptance: `Network-level input pins can feed selected actor inputs or data channels, actor outputs can drive selected top-level pins, and report metadata distinguishes external pin movement from actor-to-actor movement.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.7`
  Status: `pending`
  Goal: `Ship concurrent actor-group scheduling semantics.`
  Acceptance: `The scheduler can infer a bounded schedule for multiple actor groups that move data/information concurrently, while rejecting ambiguous ordering, unsafe fan-in, or unsupported lifetime overlap with actionable diagnostics.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.8`
  Status: `pending`
  Goal: `Promote multi-actor orchestration fixtures.`
  Acceptance: `At least one realistic multi-actor fixture demonstrates orchestrator-driven behavior, peer event synchronization, data movement, generated `.fsm` artifacts, schedule reports, strict-mode validation, and HDL handoff.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `in_progress` | Clarification is required before any syntax or implementation is safe. |

## ATL v0 Proposal

The current concrete proposal is tracked in
[docs/ISF_ATL_DESIGN_PROPOSAL.md](../ISF_ATL_DESIGN_PROPOSAL.md).

Current proposal summary:

- The source root remains `(actor top_name ...)`.
- The actor network container spelling remains open: Candidate A scopes ATL
  clauses inside `(network ...)`; Candidate B places `instance`, `connect`,
  `transfer`, and `group` directly under the top-level `(actor ...)`.
- The top-level actor's `interface` declares the external pins, referenced as
  `pins.name`.
- Actor instances are static, named, and explicit.
- Qualified endpoints identify `actor.port`, `actor.transaction`,
  `actor.event`, and `pins.name`.
- Verbose syntax is the normative authoring and downstream-emission target.
- Compact syntax is proposed only as a semantics-preserving alias over the
  verbose ATL IR.
- `connect` means structural pin/port binding.
- `transfer` means scheduler-owned movement of data/information between
  actors.
- Events are one-cycle scheduler-visible control pulses in the first ATL
  subset; event payloads remain deferred.
- Top-level transactions/rules can orchestrate actor transactions through
  qualified targets such as `reader.capture`.
- Concurrent groups express intended parallel actor activity but do not
  override safety; FSMGen may schedule, serialize, insert handoff storage, or
  reject unsafe overlap.

## Decisions

- `2026-05-18`: Created as a proposed R14 task tree after user
  brainstorming about complex systems expressed as actor networks with
  orchestrator actors, event synchronization, and actor-to-actor data
  movement.
- `2026-05-18`: Classified as likely `IAL1` while the model remains explicit
  `.isf` actor/network syntax lowered by FSMGen scheduling. It becomes an
  `IAL2` candidate only if it asks FSMGen to infer actor networks from
  protocol/platform intent beyond explicit ISF source constructs.
- `2026-05-18`: User refined the model as Actor Transfer Level (`ATL`): like
  RTL moves values between flops/registers, ATL moves data, information, and
  activation between actors. The whole actor network should itself be a
  top-level actor whose structure/content is the network. Top-level actor
  transactions and rules can trigger actors and transactions inside the
  network. Data movement must cover actor-to-actor links, concurrent actor
  groups, and movement between the top-level pins and actors in the network.
  FSMGen should infer the needed scheduling from intent-expressive syntax with
  compact and verbose forms.
- `2026-05-18`: Drafted a concrete ATL v0 proposal in
  [docs/ISF_ATL_DESIGN_PROPOSAL.md](../ISF_ATL_DESIGN_PROPOSAL.md): top-level
  actor root, open container spelling between a scoped `(network ...)` clause
  and flat top-level actor ATL clauses, static instances, qualified endpoints,
  verbose and compact syntax candidates, `connect` for structural movement,
  `transfer` for scheduler-owned data movement, one-cycle events, top-level
  transaction/rule orchestration, concurrent groups, first implementation
  subset, and fail-closed boundaries.
- `2026-05-18`: User challenged whether `(network ...)` is necessary. The
  design now treats `(network ...)` as a scoping candidate, not a requirement;
  flat top-level actor ATL clauses remain an explicit alternative.

## Open Questions

- Should ATL v0 use a scoped `(network ...)` clause, flat top-level actor ATL
  clauses, or both as equivalent spellings lowered to the same ATL IR?
- Should the final verbose trigger spelling be `(trigger ...)`,
  `(activate ...)`, or an extension of existing `(do ...)` / `(spawn ...)`?
- Are `connect` and `transfer` the right public names for structural movement
  and scheduler-owned data/information movement?
- Should compact `->` mean only structural `connect`, while compact `=>`
  means scheduled `transfer`?
- Can multiple actors orchestrate the same child/peer actor in the same
  cycle, and if so does the scheduler OR requests, arbitrate them, or reject
  ambiguous fan-in?
- What is the first realistic fixture that proves the abstraction is useful
  without overfitting the syntax?

## Blockers

- Additional user review is required before implementation: the ATL v0
  proposal is concrete enough to discuss, but final syntax, first-slice scope,
  event/data primitive names, and fail-closed boundaries remain unresolved.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed for proposed actor-network orchestration tracking` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `mdbook build docs/book`; `git diff --check` | `ATL/top-level actor clarification captured; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `mdbook build docs/book`; `git diff --check` | `ATL v0 concrete proposal drafted; book and diff checks passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-NETWORK-ORCHESTRATION` | `ISF-ACTOR-NETWORK-ORCHESTRATION: propose actor network orchestration` | `proposed tracking tree only` |

## Changelog

- `2026-05-18`: Created proposed task tree for ISF actor-network orchestration.
- `2026-05-18`: Activated the clarification leaf and recorded the Actor
  Transfer Level model where actors replace flops/registers as the transfer
  endpoints.
- `2026-05-18`: Drafted the concrete ATL v0 source/semantic proposal.
