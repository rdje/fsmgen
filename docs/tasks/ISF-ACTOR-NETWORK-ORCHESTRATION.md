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
  Status: `completed`
  Goal: `Ship actor event trigger and sync semantics.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.4.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4`
  Acceptance: `Select and then ship bounded actor-event slices using the reserved ATL v0 event vocabulary. Actor event waits use '(await actor.event)'; events are one-cycle control pulses with no payloads; fan-in, fan-out, same-cycle ambiguity, generated artifact names, report keys, and fail-closed boundaries are documented and tested before behavior ships.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2: lower actor triggers`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.1`
  Status: `completed`
  Goal: `Select the first actor-event and qualified-trigger boundary slice.`
  Acceptance: `The task tree, roadmap, design proposal, and mdBook record that the first behavior-bearing '.4' implementation will not claim full actor-event scheduling. It will instead reserve and fail closed the qualified ATL orchestration forms that can currently be mistaken for local ISF constructs: '(await actor.event)', transaction-body '(trigger actor.transaction)', and rule-level '(trigger actor.transaction)'. The selected diagnostics must name the ATL boundary, preserve existing unqualified local await/trigger behavior, and leave generated ATL artifacts empty until a later event-lowering leaf ships names and report keys.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.1: select event boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.2`
  Status: `completed`
  Goal: `Fail closed reserved qualified actor-event and actor-transaction trigger forms.`
  Acceptance: `Parser/lowering coverage rejects '(await actor.event)', transaction-body '(trigger actor.transaction)', and rule-level '(trigger actor.transaction)' with targeted ATL diagnostics before scheduled '.fsm' emission or generic enum/unknown-transaction diagnostics. Existing unqualified '(await signal)' and local rule '(trigger transaction)' behavior is unchanged. Specs, downstream handoff, public contract, mdBook, tests, and manifest/audit expectations are synchronized with the precise non-claim.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t t/1271-isf-enum-member-activation-params.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1305-isf-book-feature-matrix-audit.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.2: fail closed ATL events`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3`
  Status: `completed`
  Goal: `Ship the first generated actor-event wait subset.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2`
  Acceptance: `The selected first generated actor-event wait subset accepts exactly one top-level transaction-body '(await actor.event)' against the current single static actor instance, lowers it to a deterministic one-bit parent handoff input named 'actor_event', records the wait in schedule JSON actor_network.event_waits[], and keeps fan-in, fan-out, multiple waits, nested waits, event payloads, cross-clock actor events, generated ATL child artifacts, generated ATL tops, qualified actor transaction triggers, data movement through events, multiple static instances, and concurrent group events fail-closed/deferred.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2: lower actor event waits`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.1`
  Status: `completed`
  Goal: `Select the first generated actor-event wait subset.`
  Acceptance: `Task tree, design proposal, spec, downstream handoff, public contract, and mdBook record the selected first behavior-bearing actor-event subset: one top-level transaction-body '(await actor.event)' against the current single declared static actor instance, with scalar HDL identifier event name, lowered by the next code leaf to a deterministic one-bit parent handoff input named 'actor_event'. The event source is externally supplied until actor type resolution, child generation, and qualified transaction triggers ship. Fan-in, fan-out, multiple event waits, nested event waits, rule-level or transaction-body qualified triggers, generated ATL child '.fsm' files, generated ATL tops, event payloads, cross-clock events, and concurrent group events remain fail-closed/deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.1: select event wait handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2`
  Status: `completed`
  Goal: `Lower the selected single actor-event wait to a generated parent handoff input.`
  Acceptance: `Parser/lowering accepts exactly one top-level transaction-body '(await actor.event)' when 'actor' names the current single static actor instance, normalizes it to the generated one-bit input 'actor_event', emits scheduled '.fsm' await behavior against that input, records the event wait in schedule JSON actor-network metadata, and keeps unsupported ATL event/trigger variants fail-closed with targeted diagnostics. Specs, downstream handoff, public contract, mdBook, task tree, tests, and manifest/audit expectations are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2: lower actor event waits`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4`
  Status: `completed`
  Goal: `Select and ship the first qualified actor-transaction trigger subset.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2`
  Acceptance: `A selection leaf chooses the first bounded '(trigger actor.transaction)' behavior only after defining source/sink ownership, generated artifact names, report keys, fan-in/fan-out policy, interaction with parent event waits, and fail-closed boundaries.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2: lower actor triggers`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.1`
  Status: `completed`
  Goal: `Select the first qualified actor-transaction trigger subset.`
  Acceptance: `Task tree, roadmap, design proposal, spec/downstream/public-contract docs, and mdBook record the first implementation boundary for '(trigger actor.transaction)' before code. The selected subset is exactly one top-level transaction-body '(trigger actor.transaction)' against the current single static actor instance, lowering in the next code leaf to a one-cycle parent output handoff named 'actor_transaction_start'. The trigger sink is external until actor type resolution, generated child artifacts, and generated ATL tops ship. Rule-level qualified triggers, nested triggers, multiple triggers, fan-in/fan-out, trigger payloads or bindings, trigger ready/backpressure, cross-clock triggers, generated ATL child '.fsm' files, generated ATL tops, and HDL event wiring remain fail-closed/deferred.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.1: select actor trigger handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2`
  Status: `completed`
  Goal: `Lower the selected single actor-transaction trigger to a generated parent handoff output.`
  Acceptance: `Parser/lowering accepts exactly one top-level transaction-body '(trigger actor.transaction)' when 'actor' names the current single static actor instance, normalizes it to the generated one-cycle output 'actor_transaction_start', emits scheduled '.fsm' pulse behavior at that transaction point, records the trigger in schedule JSON actor-network metadata, and keeps unsupported ATL trigger variants fail-closed with targeted diagnostics. Specs, downstream handoff, public contract, mdBook, task tree, tests, and manifest/audit expectations are synchronized.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2: lower actor triggers`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5`
  Status: `active`
  Goal: `Ship actor-to-actor data movement bindings.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5.4`
  Acceptance: `Explicit data channels or port bindings move scalar payloads between actor instances under scheduler-visible timing rules, with storage/report provenance and fail-closed diagnostics for unsupported payload lifetimes.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.1`
  Status: `completed`
  Goal: `Select and decompose the first endpoint-aware actor data movement boundary.`
  Acceptance: `Task tree, roadmap, design proposal, spec/downstream/public-contract docs, and mdBook record the first '.5' implementation sequence before code. The selected first code leaf reserves and fails closed qualified actor endpoint drive-body pairs that can currently be mistaken for local aggregate/enum dotted names. Generated actor-to-actor movement, two-instance lowering, route muxes, handoff storage, width inference across actor types, generated ATL child '.fsm' files, generated ATL tops, and HDL routing remain deferred until later '.5' leaves select exact generated artifacts and report keys.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.1: select ATL data movement boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2`
  Status: `active`
  Goal: `Fail closed reserved endpoint-aware actor movement forms.`
  Acceptance: `Parser/lowering coverage rejects drive-body pairs whose sink or source is a qualified actor endpoint naming a declared static actor instance with targeted ATL data-movement diagnostics, while preserving existing local aggregate/enum dotted-name behavior when the qualifier is not a static actor instance. Multiple static instances remain rejected by the existing static-network boundary until a later leaf selects two-instance metadata/lowering.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.3`
  Status: `pending`
  Goal: `Select the first generated scalar actor-to-actor handoff subset.`
  Acceptance: `A selection leaf chooses the first behavior-bearing scalar actor endpoint movement subset only after defining whether two static instances are accepted in that leaf, source/sink endpoint ownership, generated parent ports or storage names, width evidence, fan-in/fan-out policy, route lifetime, schedule-report keys, generated artifact non-claims, and fail-closed boundaries.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.4`
  Status: `pending`
  Goal: `Lower the selected scalar actor-to-actor handoff subset.`
  Acceptance: `Parser/lowering accepts only the selected scalar endpoint movement form, emits the selected parent handoff/storage behavior, records movement provenance in schedule JSON actor-network metadata, and keeps unsupported endpoint movement variants fail-closed with targeted diagnostics.`
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
| 1 | `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2` | `active` | `.5.1` selected the first endpoint-aware actor data movement boundary as fail-closed reservation before generated routing. The next code leaf implements those targeted diagnostics only. |

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
- The first `.4` implementation failed closed qualified event/trigger syntax
  before accepting behavior. That protects downstream emitters from receiving
  generic enum-member, unsupported-clause, or unknown-transaction diagnostics
  for reserved ATL forms.
- The first generated actor-event wait subset is intentionally smaller than
  full child orchestration. It accepts one top-level transaction-body
  `(await actor.event)` against the current single static actor instance and
  lowers it to a deterministic one-bit parent handoff input named
  `actor_event`. The event source is external to the parent scheduled `.fsm`
  until actor type resolution, generated ATL child artifacts, and generated
  ATL tops ship. Schedule JSON records accepted waits under
  `actor_network.event_waits[]`.
- The shipped `.4.3.2` implementation keeps fan-in, fan-out, multiple
- The first actor-transaction trigger subset mirrors the event wait
  handoff boundary. It accepts one top-level transaction-body
  `(trigger actor.transaction)` against the current single static actor
  instance and lowers it to a deterministic one-cycle parent output handoff
  named `actor_transaction_start`. The trigger sink is external to the parent
  scheduled `.fsm` until actor type resolution, generated ATL child artifacts,
  and generated ATL tops ship. Schedule JSON records accepted triggers
  under `actor_network.transaction_triggers[]`.
- The shipped `.4.4.2` implementation keeps rule-level qualified
  triggers, nested triggers, multiple triggers, generated handoff signal
  conflicts, fan-in/fan-out, payloads or bindings, ready/backpressure,
  cross-clock actor triggers, generated ATL child `.fsm` files, generated ATL
  tops, HDL event wiring, and concurrent group triggers deferred or
  fail-closed.
- The first `.5` data-movement implementation sequence is selected to start
  with fail-closed reservation, not generated routing. Qualified actor
  endpoint drive-body pairs such as `(consumer.payload producer.payload)` or
  `(consumer.payload local_value)` can currently look like local dotted
  aggregate or enum names; `.5.2` must reject endpoints that name declared
  static actor instances with ATL-specific data-movement diagnostics before
  later leaves widen instance counts, generate handoff storage, or emit route
  artifacts.

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
- `2026-05-18`: Selected the first `.4` event/trigger boundary slice:
  reserve and fail closed qualified `(await actor.event)`, transaction-body
  `(trigger actor.transaction)`, and rule-level
  `(trigger actor.transaction)` with ATL-specific diagnostics before shipping
  generated actor-event behavior. Existing unqualified local await/trigger
  behavior remains in scope and unchanged.
- `2026-05-18`: Selected the first behavior-bearing actor-event wait subset:
  a single top-level transaction-body `(await actor.event)` for the current
  one-instance static actor network, lowered to a one-bit parent handoff input
  named `actor_event`. The event producer is external until later ATL actor
  type resolution, child generation, and qualified transaction trigger leaves
  ship.
- `2026-05-18`: Shipped the first behavior-bearing actor-event wait subset:
  exactly one top-level transaction-body `(await actor.event)` now lowers to a
  generated one-bit parent handoff input named `actor_event` and reports
  through `actor_network.event_waits[]`. Multiple waits, nested waits,
  multi-domain actor events, handoff name conflicts, event payloads,
  fan-in/fan-out, qualified transaction triggers, generated ATL children, and
  generated ATL tops remain deferred or fail-closed.
- `2026-05-18`: Selected the first behavior-bearing actor-transaction trigger
  subset: exactly one top-level transaction-body
  `(trigger actor.transaction)` for the current one-instance static actor
  network, lowered by the next code leaf to a one-cycle parent output handoff
  named `actor_transaction_start`. The trigger sink remains external until
  later actor type resolution, generated child, and generated ATL top leaves
  ship.

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

- No blocker for the active `.4.4.1` selection leaf. Qualified
  actor-transaction trigger behavior must still be selected before any trigger
  code ships.

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
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.4.1` | `mdbook build docs/book`; `git diff --check` | `selected the first event/trigger boundary as targeted fail-closed diagnostics before generated ATL event behavior; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.4.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t t/1271-isf-enum-member-activation-params.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `reserved qualified ATL event/trigger forms fail closed with instance-aware diagnostics; focused checks pass; broad ISF gate passes with Files=229, Tests=1345` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.1` | `mdbook build docs/book`; `git diff --check` | `selected the first generated actor-event wait subset as a single parent-handoff input wait; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `selected actor-event wait lowers to a parent handoff input and report metadata; focused checks pass; broad ISF gate passes with Files=229, Tests=1346` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.1` | `mdbook build docs/book`; `git diff --check` | `selected the first qualified actor-transaction trigger subset as a single parent output handoff; book and diff checks passed` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `selected actor-transaction trigger lowers to a parent handoff output and report metadata; focused checks pass; broad ISF gate passes with Files=229, Tests=1347` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.5.1` | `mdbook build docs/book`; `git diff --check` | `selected the first actor data movement boundary as fail-closed endpoint drive reservation; book and diff checks passed` |

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
| `ISF-ACTOR-NETWORK-ORCHESTRATION.4.1` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.1: select event boundary` | `selects targeted fail-closed diagnostics as the first actor-event and qualified-trigger boundary slice` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.4.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.2: fail closed ATL events` | `ships instance-aware targeted diagnostics for reserved qualified event waits and actor transaction triggers` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.1` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.1: select event wait handoff` | `selects the first generated actor-event wait subset as one top-level transaction wait lowered to a parent handoff input` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2: lower actor event waits` | `lowers the selected single actor-event wait to a generated parent handoff input and actor-network report metadata` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.1` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.1: select actor trigger handoff` | `selects the first qualified actor-transaction trigger subset as one top-level transaction trigger lowered to a parent output handoff` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2: lower actor triggers` | `lowers the selected single actor-transaction trigger to a generated parent handoff output and actor-network report metadata` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.5.1` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.1: select ATL data movement boundary` | `selects fail-closed reservation for qualified actor endpoint drive-body pairs as the first data movement boundary` |

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
- `2026-05-18`: Selected the first `.4` event/trigger boundary slice:
  targeted fail-closed diagnostics for reserved qualified event and trigger
  forms before any generated actor-event scheduling behavior ships.
- `2026-05-18`: Shipped `.4.2`: qualified `(await actor.event)`,
  transaction-body `(trigger actor.transaction)`, and rule-level
  `(trigger actor.transaction)` now fail closed with ATL-specific diagnostics
  only when the qualifier names a declared static actor instance. Enum-looking
  dotted names outside actor-network instances keep their prior diagnostics.
- `2026-05-18`: Completed `.4.3.1`: selected a narrow generated actor-event
  wait subset before code. The next leaf, `.4.3.2`, lowers one top-level
  transaction-body `(await actor.event)` to a deterministic one-bit parent
  handoff input and records it in actor-network report metadata while keeping
  broader ATL event and trigger behavior deferred.
- `2026-05-18`: Completed `.4.3.2`: one top-level transaction-body
  `(await actor.event)` now lowers to a generated parent handoff input and
  schedule-report `actor_network.event_waits[]` metadata. The active frontier
  moves to `.4.4.1` to select the first qualified actor-transaction trigger
  boundary.
- `2026-05-18`: Completed `.4.4.1`: selected a narrow qualified
  actor-transaction trigger subset before code. The next leaf, `.4.4.2`,
  lowers one top-level transaction-body `(trigger actor.transaction)` to a
  deterministic one-cycle parent output handoff and records it in actor-network
  report metadata while keeping broader ATL trigger behavior deferred.
- `2026-05-18`: Completed `.4.4.2`: one top-level transaction-body
  `(trigger actor.transaction)` now lowers to a generated parent handoff
  output and schedule-report `actor_network.transaction_triggers[]` metadata.
  The active frontier moves to `.5` for actor-to-actor data movement
  selection/decomposition before any further behavior-bearing code.
- `2026-05-18`: Completed `.5.1`: selected the first actor data movement
  implementation boundary as fail-closed reservation for qualified actor
  endpoint drive-body pairs before generated routing. The active frontier
  moves to `.5.2` for targeted ATL data-movement diagnostics.
