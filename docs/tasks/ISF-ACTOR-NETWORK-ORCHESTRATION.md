# ISF-ACTOR-NETWORK-ORCHESTRATION: Actor Network Orchestration

## Metadata

- Tree ID: `ISF-ACTOR-NETWORK-ORCHESTRATION`
- Status: `proposed`
- Roadmap lane: `R14`
- Created: `2026-05-18`
- Last updated: `2026-05-18`
- Owner: repo-local workflow

## Goal

Track the proposed ISF actor-network abstraction: static hierarchies or
networks of actors where one or more actors orchestrate system behavior by
triggering peer/sub-actors, synchronizing on one-cycle event pulses, and
moving data through explicit bindings while FSMGen owns the scheduling and
lowering to explicit `.fsm`.

## Non-Goals

- Replacing transactions, rules, stages, resources, or current actor-local
  ISF semantics.
- Inferring a whole system from an informal prose protocol description.
- Dynamic hardware creation or runtime actor instantiation.
- Starting implementation before the source contract, generated-top model,
  event semantics, data movement model, scheduling ownership, and failure
  policy are clarified with the user.
- Claiming this as `IAL2` while it remains explicit `.isf` syntax with
  scheduler-visible actors, events, bindings, and constraints.

## Acceptance Criteria

- The actor-network source model is clarified before implementation.
- The roadmap and mdBook distinguish this as proposed IAL1 ISF work unless a
  later clarification explicitly moves it to IAL2.
- Static actor hierarchy/network elaboration, actor event ports, orchestration
  triggers, actor-to-actor data movement, schedule-report visibility, and
  fail-closed diagnostics are decomposed into reviewable leaves.
- Each implementation leaf has tests, spec/book updates, and public-contract
  synchronization appropriate to its shipped surface.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION`
  Status: `proposed`
  Goal: `Design and eventually ship static ISF actor-network orchestration.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.4`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5`, `ISF-ACTOR-NETWORK-ORCHESTRATION.6`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.1`
  Status: `pending`
  Goal: `Clarify the actor-network source contract with the user.`
  Acceptance: `A design note records whether actors are declared as nested actors, imported/library actors, or peer actors in a network clause; how orchestrator actors trigger other actors; how one-cycle events are named and synchronized; how data moves between actors; how scheduling responsibility is split between local actor schedules and network-level orchestration; and which forms must fail closed in the first implementation slice.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.2`
  Status: `pending`
  Goal: `Specify the static actor-network syntax and public contract.`
  Acceptance: `The ISF spec, downstream integration handoff, public contract, and mdBook define the accepted source forms, event/data binding vocabulary, schedule-report shape, generated artifact names, and explicit non-claims.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.3`
  Status: `pending`
  Goal: `Ship the smallest static actor hierarchy elaboration slice.`
  Acceptance: `A parent/network actor can instantiate one child actor with explicit static bindings, generated artifacts remain reviewable, and unsupported dynamic or ambiguous actor graphs fail closed.`
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
  Goal: `Promote multi-actor orchestration fixtures.`
  Acceptance: `At least one realistic multi-actor fixture demonstrates orchestrator-driven behavior, peer event synchronization, data movement, generated `.fsm` artifacts, schedule reports, strict-mode validation, and HDL handoff.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `pending` | Clarification is required before any syntax or implementation is safe. |

## Decisions

- `2026-05-18`: Created as a proposed R14 task tree after user
  brainstorming about complex systems expressed as actor networks with
  orchestrator actors, event synchronization, and actor-to-actor data
  movement.
- `2026-05-18`: Classified as likely `IAL1` while the model remains explicit
  `.isf` actor/network syntax lowered by FSMGen scheduling. It becomes an
  `IAL2` candidate only if it asks FSMGen to infer actor networks from
  protocol/platform intent beyond explicit ISF source constructs.

## Open Questions

- What source shape is preferred: nested actor declarations, a top-level
  `(network ...)` clause, reusable-library actor instances, or peer actors
  connected by explicit topology?
- Are orchestrator triggers just named one-cycle event pulses, transaction
  activations, actor-level activations, or a new event abstraction?
- Should actor-to-actor data movement be modeled as port bindings, channels,
  named event payloads, storage references, or a narrower first-slice subset?
- Can multiple actors orchestrate the same child/peer actor in the same
  cycle, and if so does the scheduler OR requests, arbitrate them, or reject
  ambiguous fan-in?
- How much scheduling is local to each actor versus global across the actor
  network?
- What is the first realistic fixture that proves the abstraction is useful
  without overfitting the syntax?

## Blockers

- User clarification is required before implementation.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed for proposed actor-network orchestration tracking` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-NETWORK-ORCHESTRATION` | `ISF-ACTOR-NETWORK-ORCHESTRATION: propose actor network orchestration` | `proposed tracking tree only` |

## Changelog

- `2026-05-18`: Created proposed task tree for ISF actor-network orchestration.
