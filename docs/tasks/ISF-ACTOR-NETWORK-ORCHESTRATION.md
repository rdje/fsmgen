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
  Status: `completed`
  Goal: `Clarify the actor-network source contract with the user.`
  Acceptance: `A design note records that static actor instances are direct top-level actor-body ATL clauses, how the whole network acts as a top-level actor, how top-level actor transactions/rules trigger actors or transactions, how one-cycle events are named and synchronized, how data moves between actors, concurrent actor groups, and top-level pins, how scheduling responsibility is split between local actor schedules and network-level orchestration, how compact and verbose syntax variants relate, and which forms must fail closed in the first implementation slice.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `ISF-ACTOR-NETWORK-ORCHESTRATION.1: draft ATL v0 proposal`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.2`
  Status: `done`
  Goal: `Specify the static actor-network/ATL syntax and public contract.`
  Acceptance: `The ISF spec, downstream integration handoff, public contract, and mdBook define the accepted direct actor-body static instance source form, the rejected network-wrapper boundary, the eventual compact and verbose source forms, event/data binding vocabulary, schedule-report shape, generated artifact names, and explicit non-claims.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; prove -Iperl t/1322-isf-actor-network-static.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.2: settle ATL v0 public contract`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.3`
  Status: `completed`
  Goal: `Ship the smallest top-level actor-as-network elaboration slice.`
  Acceptance: `A top-level actor can own a static ATL body with one child actor instance, the parser and schedule report preserve the instance identity, unsupported dynamic or ambiguous actor graphs fail closed, and endpoint-aware drive-body movement remains explicitly deferred until the routing-lowering slice.`
  Verification: `focused parser/report tests; mdbook build docs/book; git diff --check`
  Commit: `ISF-ACTOR-NETWORK-ORCHESTRATION.3: ship static actor-network metadata`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4`
  Status: `active`
  Goal: `Ship actor event trigger and sync semantics.`
  Acceptance: `Select and then ship the first bounded actor-event subset using the reserved ATL v0 event vocabulary. Actor event waits use '(await actor.event)'; events are one-cycle control pulses with no payloads; fan-in, fan-out, same-cycle ambiguity, generated artifact names, report keys, and fail-closed boundaries are documented and tested before behavior ships.`
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
| 1 | `ISF-ACTOR-NETWORK-ORCHESTRATION.4` | `active` | ATL v0 public syntax is now selected; the next bounded implementation frontier is actor event trigger/sync semantics using the reserved `(await actor.event)` vocabulary. |

## ATL v0 Proposal

The current concrete proposal is tracked in
[docs/ISF_ATL_DESIGN_PROPOSAL.md](../ISF_ATL_DESIGN_PROPOSAL.md).

Current proposal summary:

- The source root remains `(actor top_name ...)`.
- The top-level actor body is the actor-network boundary. Static ATL
  declarations are direct actor clauses; `(network ...)` is not part of the
  shipped source surface.
- The top-level actor's `interface` declares the external pins, referenced as
  `pins.name`.
- Actor instances are static, named, and explicit.
- Qualified endpoints identify `actor.port`, `actor.transaction`,
  `actor.event`, and `pins.name`.
- Verbose syntax is the normative authoring and downstream-emission target.
- Compact syntax is proposed only as a semantics-preserving alias over the
  verbose ATL IR.
- Top-level `connect` is not part of the ATL v0 movement syntax.
- Actor-to-actor and pin-to-actor movement should be captured as
  existing drive-body assignment pairs plus existing drive-call timing points,
  not as a new `(drive source sink)` action.
- The selected ATL v0 movement source shape keeps the shipped drive-body pair
  order `(sink source)`, where ATL widens `sink` and `source` to include
  qualified actor endpoints and top-level pins.
- FSMGen's scheduler, not a new source keyword, discriminates whether each
  pair side is an actor endpoint, top-level pin, or local value.
- The scheduler also owns dynamic runtime route control: mux selects, enables,
  handoffs, and generated connectivity are inferred from movement intent, not
  hand-authored as routes.
- The rationale is low-friction, uniform ISF syntax: reuse current data
  movement forms where possible instead of adding another movement vocabulary.
- Events are one-cycle scheduler-visible control pulses in the first ATL
  subset; event payloads remain deferred.
- Top-level transactions and rules reserve the existing activation vocabulary
  for qualified targets: `(do actor.transaction)`,
  `(spawn actor.transaction as NAME)`, and `(trigger actor.transaction)`.
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
  actor root, static direct actor-body ATL clauses, qualified endpoints,
  verbose and compact syntax candidates, temporal route semantics for
  actor-to-actor and pin-to-actor movement, scheduler-owned data movement
  through existing drive bodies/calls, one-cycle events, top-level
  transaction/rule orchestration, concurrent groups, first implementation
  subset, and fail-closed boundaries.
- `2026-05-18`: User clarified the RTL mux analogy: ATL movement declarations
  must not be permanent wires. Multiple source actors may be able to provide
  information to one sink actor at different cycles, just as mux inputs can
  feed one flop at different times. The scheduler must select or reject those
  movements based on triggers, sink-valid conditions, disjoint timing, and
  generated mux/enable/handoff evidence.
- `2026-05-18`: User pushed the analogy further: the sink actor is like the
  flop/register D input, source actors are like mux data inputs, and selectors
  are scheduler-derived. ATL source should capture movement intent through
  scheduler-visible source/sink relationships, while the scheduler derives
  the needed connectivity/mux/enable/handoff plan. Therefore a top-level
  `connect` movement clause is no longer preferred for ATL v0.
- `2026-05-18`: User considered simpler two-operand movement spellings such
  as `transfer` or `move`, then clarified that the better direction is to
  avoid new user-surface syntax when existing ISF data-movement syntax can
  carry the intent.
- `2026-05-18`: User clarified that the reuse target is the existing drive
  body assignment-pair shape, not a new transaction-local `(drive source
  sink)` action. The proposal keeps drive body pairs as `(sink source)`,
  matching shipped drive semantics, and lets FSMGen infer whether the source,
  sink, or both are anchored at actor interfaces or top-level pins.
- `2026-05-18`: User briefly questioned whether `(sink source)` is too
  RTL-shaped for ATL, then resolved the direction by asking to keep the ISF
  syntax uniform and let the scheduler discriminate endpoint roles.
- `2026-05-18`: User asked to pick one while avoiding a new user-surface
  movement syntax. ATL v0 now selects existing drive-body assignment pairs in
  `(sink source)` order, plus existing drive calls as timing points. The
  scheduler owns endpoint discrimination for actor endpoints, top-level pins,
  and local values. `transfer`/`move` are not planned for ATL v0.
- `2026-05-18`: User emphasized that the reason is to avoid friction in ISF
  and preserve uniform syntax. The design now records uniform ISF movement
  vocabulary as the reason for selecting drive-body reuse.
- `2026-05-18`: User clarified that the scheduler should dynamically control
  information routing between actors so authors do not have to think much
  about route wiring. The design now records that FSMGen owns runtime
  route-select control, mux/enables, handoffs, and generated connectivity.
- `2026-05-18`: User challenged whether `(network ...)` is necessary. The
  design first treated `(network ...)` as a scoping candidate, not a
  requirement, while keeping flat top-level actor ATL clauses as an explicit
  alternative.
- `2026-05-18`: User authorized starting coding with the selected movement
  direction and accepted that later slices can adjust the design if code or
  review exposes a mismatch. The active frontier moved to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.3`, bounded first to static network
  parsing/reporting while endpoint-aware movement lowering remains a following
  slice.
- `2026-05-18`: Shipped the first metadata-only static actor-network slice:
  one actor instance can be declared as direct actor-body
  `(instance NAME of ACTOR_TYPE)`, and parser/report metadata preserves
  instance identity without resolving actor types, emitting child artifacts,
  generating ATL tops, moving data, triggering actor transactions, or waiting
  on actor events. The earlier `(network ...)` wrapper was removed from the
  shipped source surface and now fails closed.
- `2026-05-18`: Closed the ATL v0 public-contract clarification. The selected
  public direction is direct actor-body ATL clauses, endpoint-aware drive-body
  `(sink source)` pairs plus drive calls for temporal movement, no
  `connect`/`transfer`/`move` movement clauses, reserved
  `(do actor.transaction)`, `(spawn actor.transaction as NAME)`,
  `(trigger actor.transaction)`, and `(await actor.event)` orchestration
  forms, one-cycle payload-free events, and conservative concurrent groups as
  schedulable intent only. The current generated-artifact contract remains
  empty for ATL scheduling.

## Open Questions

- After ATL v0 ships and is reviewed, is ergonomic sugar above endpoint-aware
  drive-body pairs worth adding, or should drive-body reuse remain the only
  public movement surface?
- Can multiple actors orchestrate the same child/peer actor in the same
  cycle, and if so does the scheduler OR requests, arbitrate them, or reject
  ambiguous fan-in?
- What is the first realistic fixture that proves the abstraction is useful
  without overfitting the syntax?

## Blockers

- No blocker for the completed ATL v0 public-contract slice. The active `.4`
  frontier still must select a bounded event subset before behavior changes:
  event emission source, event wait ownership, fan-in/fan-out policy,
  generated artifact names, and report keys must be pinned down before code.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION` | `mdbook build docs/book`; `git diff --check` | `book and diff checks passed for proposed actor-network orchestration tracking` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `mdbook build docs/book`; `git diff --check` | `ATL/top-level actor clarification captured; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `mdbook build docs/book`; `git diff --check` | `ATL v0 concrete proposal drafted; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `mdbook build docs/book`; `git diff --check` | `ATL temporal route and RTL mux analogy captured; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `mdbook build docs/book`; `git diff --check` | `selected existing drive-body movement reuse; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `mdbook build docs/book`; `git diff --check` | `scheduler-owned dynamic routing clarification captured; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.3` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book` | `static actor-network parser/report slice shipped; focused checks and ISF regression gate passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `git diff --check`; `./bin/ci-regression isf --no-book` | `direct actor-body static instance surface selected; network wrapper rejection and docs/contracts passed focused checks plus ISF regression gate` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `prove -Iperl t/1322-isf-actor-network-static.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `ATL v0 public contract selected across spec, downstream handoff, public contract, mdBook, and design proposal; focused checks pass; broad ISF gate passes with Files=229, Tests=1344` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ACTOR-NETWORK-ORCHESTRATION` | `ISF-ACTOR-NETWORK-ORCHESTRATION: propose actor network orchestration` | `proposed tracking tree only` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1: capture ATL model` | `activated clarification leaf and captured ATL mental model` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1: draft ATL v0 proposal` | `drafted the direct actor-body source shape and endpoint vocabulary` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1: capture ATL temporal routes` | `captures RTL mux analogy and non-permanent movement semantics` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1: select ATL drive-body movement` | `selects existing drive-body pairs and drive calls as the ATL v0 movement surface` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.1` | `ISF-ACTOR-NETWORK-ORCHESTRATION.1: clarify ATL scheduler routing` | `records scheduler-owned dynamic route control` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.3` | `ISF-ACTOR-NETWORK-ORCHESTRATION.3: ship static actor-network metadata` | `ships one-instance static actor-network parsing/reporting metadata` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.2: settle ATL v0 public contract` | `selects the reserved ATL v0 source, movement, event, trigger, group, and artifact contracts before further implementation leaves` |

## Changelog

- `2026-05-18`: Created proposed task tree for ISF actor-network orchestration.
- `2026-05-18`: Activated the clarification leaf and recorded the Actor
  Transfer Level model where actors replace flops/registers as the transfer
  endpoints.
- `2026-05-18`: Drafted the concrete ATL v0 source/semantic proposal.
- `2026-05-18`: Refined ATL data/information movement as temporal
  scheduler-selected routes rather than permanent actor-to-actor wires.
- `2026-05-18`: Selected existing drive-body `(sink source)` pairs plus
  existing drive calls as the ATL v0 movement surface, with the scheduler
  discriminating actor endpoints, top-level pins, and local values.
- `2026-05-18`: Clarified that FSMGen owns dynamic runtime routing control
  between actors, including route selects, mux/enables, handoffs, and
  generated connectivity.
- `2026-05-18`: Activated the first implementation leaf for static
  actor-network parsing/reporting.
- `2026-05-18`: Shipped one-instance static actor-network parsing/reporting
  metadata with the direct actor-body source form, public schedule-report
  keys, contract/docs/book synchronization, and fail-closed unsupported graph
  diagnostics.
- `2026-05-18`: Settled the ATL v0 public contract before the next
  implementation leaf: direct actor-body declarations, endpoint-aware
  drive-body movement reuse, reserved qualified activation/event/group
  vocabulary, explicit no-`connect`/`transfer`/`move` boundary, and no
  generated ATL artifacts until a later leaf ships them.
