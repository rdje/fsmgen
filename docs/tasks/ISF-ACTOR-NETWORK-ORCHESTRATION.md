# ISF-ACTOR-NETWORK-ORCHESTRATION: Actor Network Orchestration

## Metadata

- Tree ID: `ISF-ACTOR-NETWORK-ORCHESTRATION`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-18`
- Last updated: `2026-05-19`
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
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.4`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5`, `ISF-ACTOR-NETWORK-ORCHESTRATION.6`, `ISF-ACTOR-NETWORK-ORCHESTRATION.7`, `ISF-ACTOR-NETWORK-ORCHESTRATION.8`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9`

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
  Status: `completed`
  Goal: `Ship actor-to-actor data movement bindings.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.5.4`
  Acceptance: `Explicit data channels or port bindings move scalar payloads between actor instances under scheduler-visible timing rules, with storage/report provenance and fail-closed diagnostics for unsupported payload lifetimes.`
  Verification: `completed through child leaves; latest behavior leaf validation: perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t; prove -Iperl t/1193-isf-drive-call-arity-boundary.t t/1194-isf-drive-body-boundary.t t/1198-isf-update-clause-boundary.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.4: lower scalar ATL handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.1`
  Status: `completed`
  Goal: `Select and decompose the first endpoint-aware actor data movement boundary.`
  Acceptance: `Task tree, roadmap, design proposal, spec/downstream/public-contract docs, and mdBook record the first '.5' implementation sequence before code. The selected first code leaf reserves and fails closed qualified actor endpoint drive-body pairs that can currently be mistaken for local aggregate/enum dotted names. Generated actor-to-actor movement, two-instance lowering, route muxes, handoff storage, width inference across actor types, generated ATL child '.fsm' files, generated ATL tops, and HDL routing remain deferred until later '.5' leaves select exact generated artifacts and report keys.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.1: select ATL data movement boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2`
  Status: `completed`
  Goal: `Fail closed reserved endpoint-aware actor movement forms.`
  Acceptance: `Parser/lowering coverage rejects drive-body pairs whose sink or source is a qualified actor endpoint naming a declared static actor instance with targeted ATL data-movement diagnostics, while preserving existing local aggregate/enum dotted-name behavior when the qualifier is not a static actor instance. Multiple static instances remain rejected by the existing static-network boundary until a later leaf selects two-instance metadata/lowering.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1305-isf-book-feature-matrix-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.2: fail closed ATL data movement`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.3`
  Status: `completed`
  Goal: `Select the first generated scalar actor-to-actor handoff subset.`
  Acceptance: `The selected next code subset accepts exactly two direct static actor instances only for one scalar actor-to-actor data movement: one named drive body with exactly one pair '(sink_actor.sink_endpoint source_actor.source_endpoint)' and one top-level transaction drive call that activates it. The sink and source instances must be distinct declared static actor instances; endpoint member names are scalar HDL identifiers; generated parent handoff ports are named 'source_actor_source_endpoint' for the external source input and 'sink_actor_sink_endpoint' for the external sink output; width is one scalar bit in this first subset; route lifetime is the drive-call cycle only; no mux, storage, child '.fsm', ATL top, HDL child wiring, type resolution, pin movement, inline drive movement, expression movement, fan-in, fan-out, groups, CDC, or trigger/await coupling is claimed. Schedule-report metadata is selected as 'actor_network.data_movements[]' with keys 'kind', 'transaction', 'context', 'drive', 'source_instance', 'source_endpoint', 'source_signal', 'sink_instance', 'sink_endpoint', 'sink_signal', 'width', 'width_source', 'route_lifetime', 'storage', 'source', and 'sink'.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.3: select scalar ATL handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.5.4`
  Status: `completed`
  Goal: `Lower the selected scalar actor-to-actor handoff subset.`
  Acceptance: `Parser/lowering accepts only the selected '.5.3' form: one top-level actor with exactly two direct static actor instances, one named drive body with one scalar actor-to-actor endpoint pair, and one top-level transaction drive call. Lowering emits the selected external parent handoff input/output ports, drives the sink handoff output from the source handoff input in the drive-call cycle, records the selected 'actor_network.data_movements[]' metadata, and keeps every unsupported endpoint movement variant fail-closed with targeted ATL diagnostics.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t; prove -Iperl t/1193-isf-drive-call-arity-boundary.t t/1194-isf-drive-body-boundary.t t/1198-isf-update-clause-boundary.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.4: lower scalar ATL handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.6`
  Status: `completed`
  Goal: `Ship top-level pin to actor-network data movement.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.6.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.6.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.6.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.6.4`
  Acceptance: `Network-level input pins can feed selected actor inputs or data channels, actor outputs can drive selected top-level pins, and report metadata distinguishes external pin movement from actor-to-actor movement.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1193-isf-drive-call-arity-boundary.t t/1194-isf-drive-body-boundary.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.4: lower actor-to-pin handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.6.1`
  Status: `completed`
  Goal: `Select the first top-level pin to actor scalar handoff subset.`
  Acceptance: `The selected next code subset accepts exactly one direct static actor instance, one named drive body with exactly one '(actor.endpoint pins.input_pin)' scalar pair, and one top-level transaction drive call. 'pins.input_pin' must name a top-level actor interface input with scalar one-bit width; the sink actor endpoint must be a scalar HDL identifier; lowering will rewrite the sink to generated external parent output 'actor_endpoint' while reading the existing top-level input pin directly. The route lifetime is the drive-call cycle only; no storage, mux, generated child '.fsm', ATL top, HDL child wiring, actor type resolution, actor-to-pin movement, two-instance actor-to-actor movement in the same drive, inline movement, expression movement, fan-in/fan-out, groups, CDC, or trigger/await coupling is claimed. Schedule-report metadata will reuse 'actor_network.data_movements[]' with kind 'scalar_pin_to_actor_handoff', source set to 'top_level_pin', source_instance/source_endpoint naming the pseudo-instance 'pins' and pin name, and sink set to 'external_handoff'.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.1: select pin-to-actor handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.6.2`
  Status: `completed`
  Goal: `Lower the selected scalar top-level input pin to actor handoff subset.`
  Acceptance: `Parser/lowering accepts only the selected '.6.1' form, rewrites the actor sink endpoint to the generated parent handoff output, reads the existing scalar top-level input pin as the source, records the selected actor_network.data_movements[] metadata, and keeps every unsupported pin/actor movement variant fail-closed with targeted ATL diagnostics.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1193-isf-drive-call-arity-boundary.t t/1194-isf-drive-body-boundary.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.2: lower pin-to-actor handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.6.3`
  Status: `completed`
  Goal: `Select the first actor to top-level output pin handoff subset.`
  Acceptance: `The selected next code subset accepts exactly one direct static actor instance, one named drive body with exactly one '(pins.output_pin actor.endpoint)' scalar pair, and one top-level transaction drive call. 'pins.output_pin' must name a top-level actor interface output with scalar one-bit width; the source actor endpoint must be a scalar HDL identifier; lowering will expose the actor endpoint as generated external parent input 'actor_endpoint' while driving the existing top-level output pin directly. The route lifetime is the drive-call cycle only; no storage, mux, generated child '.fsm', ATL top, HDL child wiring, actor type resolution, pin-to-actor movement in the same drive, two-instance actor-to-actor movement in the same drive, inline movement, expression movement, fan-in/fan-out, groups, CDC, or trigger/await coupling is claimed. Schedule-report metadata will reuse 'actor_network.data_movements[]' with kind 'scalar_actor_to_pin_handoff', source set to 'external_handoff', sink set to 'top_level_pin', source_instance/source_endpoint naming the actor endpoint, and sink_instance/sink_endpoint naming the pseudo-instance 'pins' and pin name.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.3: select actor-to-pin handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.6.4`
  Status: `completed`
  Goal: `Lower the selected scalar actor to top-level output pin handoff subset.`
  Acceptance: `Parser/lowering accepts only the selected '.6.3' form, rewrites the actor source endpoint to the generated parent handoff input, drives the existing scalar top-level output pin as the sink, records the selected actor_network.data_movements[] metadata, and keeps every unsupported pin/actor movement variant fail-closed with targeted ATL diagnostics.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1193-isf-drive-call-arity-boundary.t t/1194-isf-drive-body-boundary.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.4: lower actor-to-pin handoff`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.7`
  Status: `completed`
  Goal: `Ship concurrent actor-group scheduling semantics.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.7.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.7.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.7.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.7.4`, `ISF-ACTOR-NETWORK-ORCHESTRATION.7.5`
  Acceptance: `The scheduler can infer a bounded schedule for multiple actor groups that move data/information concurrently, while rejecting ambiguous ordering, unsafe fan-in, or unsupported lifetime overlap with actionable diagnostics.`
  Verification: `same focused and broad checks as '.7.5'; broad ISF gate passes with Files=229, Tests=1353`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.5: lower group trigger batch`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.7.1`
  Status: `completed`
  Goal: `Decompose concurrent actor-group scheduling and select the first group boundary.`
  Acceptance: `The task tree, roadmap, ATL design proposal, spec, downstream handoff, public contract, and mdBook record that '.7' starts conservatively. The selected first code leaf will reserve/fail closed direct actor-body '(group NAME (members ACTOR...) (mode concurrent))' declarations and compact '(concurrent NAME ACTOR...)' aliases with targeted ATL diagnostics before group metadata or scheduling behavior is claimed. The selected later metadata subset is direct actor-body group declarations only, with HDL identifier group names, at least two declared direct static actor members, explicit '(mode concurrent)', no dynamic membership, no nested groups, no group endpoints, no generated child artifacts, no route mux/storage, no CDC, and no scheduling overlap claims until separate leaves ship them.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.1: select group boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.7.2`
  Status: `completed`
  Goal: `Fail closed reserved actor-group declarations and compact aliases.`
  Acceptance: `Parser coverage rejects direct actor-body '(group ...)' and '(concurrent ...)' forms with targeted ATL group diagnostics while preserving existing actor-local behavior. Specs, downstream handoff, public contract, mdBook, tests, and live docs stay transparent that no group metadata or scheduling is implemented by this fail-closed leaf.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; prove -Iperl t/1322-isf-actor-network-static.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.2: fail closed ATL groups`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.7.3`
  Status: `completed`
  Goal: `Ship static concurrent group metadata.`
  Acceptance: `Parser/reporting accepts the selected direct actor-body group declaration against already declared direct static actor instances, records group membership and mode in actor_network group metadata, and keeps group endpoints, generated children, scheduling overlap, storage/mux insertion, CDC, dynamic membership, nested groups, and compact aliases fail-closed.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.3: report static ATL groups`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.7.4`
  Status: `completed`
  Goal: `Select the first group scheduling behavior subset.`
  Acceptance: `The first behavior-bearing group scheduling subset is selected as one same-cycle external trigger batch in one top-level transaction body: a direct static group with at least two members may own a contiguous run of '(trigger actor.transaction)' clauses where every group member appears exactly once, every target transaction name is scalar, there are no payloads/binds/awaits/drives interleaved in the batch, and no generated child wiring, event waits, data movement, storage/mux insertion, CDC, compact aliases, or group endpoints are claimed. The next lowering leaf must emit all generated parent trigger outputs from one state, keep the existing per-trigger transaction_triggers[] report entries, add a group_schedules[] report entry with group, owner_transaction, context, members, target_transactions, signals, schedule, dependency_policy, storage, source, and sink keys, and fail closed every broader group-scheduling form.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.4: select group trigger batch`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.7.5`
  Status: `completed`
  Goal: `Lower the selected same-cycle group trigger batch.`
  Acceptance: `Lowering implements only the selected '.7.4' subset: a contiguous top-level transaction-body batch of qualified triggers to every member of one declared static group lowers to one scheduled parent state that pulses every selected external actor-transaction trigger output in the same cycle; actor_network.group_schedules[] reports the inferred independence evidence; existing transaction_triggers[] entries remain per target; nested, repeated, partial-group, mixed-group, noncontiguous, payload-bearing, event/data-movement-coupled, CDC, compact alias, group endpoint, generated-child, storage/mux, and fan-in/fan-out variants fail closed with targeted ATL diagnostics.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.5: lower group trigger batch`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.8`
  Status: `completed`
  Goal: `Promote multi-actor orchestration fixtures.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.8.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.8.2`
  Acceptance: `A fixture ladder promotes realistic multi-actor ATL examples without overclaiming unsupported combinations. The first fixture uses only already shipped ATL surfaces after the temporary-association clarification: direct static actor instances and a same-cycle external trigger batch inferred from contiguous transaction-body '(trigger actor.transaction)' clauses. It deliberately avoids a permanent '(group ...)' declaration. Later fixture leaves may cover peer event synchronization, data movement, generated ATL child artifacts, generated ATL tops, and richer HDL wiring only after the corresponding behavior-bearing ATL leaves ship those combinations.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1324-isf-atl-fixture-coverage.t t/1322-isf-actor-network-static.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.8.2: add ATL trigger fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.8.1`
  Status: `completed`
  Goal: `Select the first realistic multi-actor ATL fixture.`
  Acceptance: `The first fixture is selected as 'isf/atl_group_trigger_pipeline.isf': a single-clock top-level actor with three direct static actor instances, one verbose '(group pipeline (members reader filter writer) (mode concurrent))' declaration, and one transaction that uses a contiguous '(trigger actor.transaction)' batch to every group member exactly once before completing. The selected fixture is allowed to use only shipped ATL static-instance metadata, static group metadata, and same-cycle external group-trigger scheduling. It will emit only 'atl_group_trigger_pipeline.fsm'; no child '.fsm' artifacts or ATL top are selected. Required report evidence is actor_network.instances[], groups[], transaction_triggers[], and group_schedules[] with empty event_waits[] and data_movements[]. The next implementation leaf must prove strict schedule JSON parity, scheduled '.fsm' structure, plain HDL generation, and strict HDL generation while keeping event waits, endpoint data movement, generated children, group endpoints, compact aliases, CDC, payloads, ready/backpressure, partial/mixed/noncontiguous/repeated group batches, route mux/storage, and trigger/data/event coupling fail-closed.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.8.1: select ATL fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.8.2`
  Status: `completed`
  Goal: `Add the selected realistic ATL temporary trigger-batch fixture.`
  Acceptance: `Pivot the '.8.1' fixture selection to honor the temporal-association clarification: add 'isf/atl_trigger_batch_pipeline.isf' with three direct static actor instances and no permanent '(group ...)' declaration. Lower a contiguous transaction-body trigger batch to distinct static actor instances as one temporary same-cycle trigger-batch state. Add a file-backed regression that proves the in-process lowerer emits only 'atl_trigger_batch_pipeline.fsm', the scheduled parent contains one 'run_atl_trigger_batch_1' state that pulses 'reader_capture_start', 'filter_process_start', and 'writer_emit_start' in the same cycle, strict CLI schedule JSON matches the in-process report, and plain plus strict HDL generation reach SystemVerilog without claiming generated ATL children, generated ATL tops, endpoint data movement, peer events, group endpoints, CDC, payloads, ready/backpressure, route mux/storage, trigger/data/event coupling, or permanent actor grouping. Sync the mdBook, live docs, and fixture-coverage/task evidence.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1324-isf-atl-fixture-coverage.t t/1322-isf-actor-network-static.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=230, Tests=1357); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.8.2: add ATL trigger fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9`
  Status: `active`
  Goal: `Select the next task-scoped ATL association behavior after the trigger-batch fixture.`
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.5`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.6`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.7`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.8`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.9`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.10`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.11`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.13`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.14`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.15`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.16`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.17`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.18`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.19`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.20`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.21`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.22`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.23`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.24`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.25`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.26`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.27`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.28`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.29`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.30`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.31`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.32`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.33`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.34`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.35`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.36`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.37`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.38`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.39`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.40`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.41`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.42`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.43`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.44`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.45`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.46`
  Acceptance: `The next ATL implementation frontier is selected before code. The selection must preserve the clarified model that actor associations are task-scoped, must not rely on permanent groups by default, and must identify one bounded behavior slice with source syntax, report keys, generated artifact expectations, fail-closed boundaries, mdBook impact, and regression scope.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.1`
  Status: `completed`
  Goal: `Choose the next bounded ATL temporary-association slice.`
  Acceptance: `Review the shipped trigger, event, scalar data movement, pin movement, static group metadata, and temporary trigger-batch fixture surfaces; pick one next behavior-bearing ATL slice or one doc-only design clarification needed before code. Candidate directions include coupling a temporary trigger batch with peer event waits, adding a temporary data-movement association fixture, selecting generated child artifact boundaries, or refining report vocabulary away from the legacy group_schedules[] key family. No code changes may begin until this leaf records the selected source shape and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.1: select ATL association reports`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2`
  Status: `completed`
  Goal: `Add canonical task-scoped ATL association schedule report metadata.`
  Acceptance: `Without changing source syntax or generated HDL behavior, add an additive schedule-report family named actor_network.association_schedules[] for temporary task-scoped ATL associations. The first implementation covers the already shipped contiguous transaction-body '(trigger actor.transaction)' batch to distinct static actor instances. Each association_schedules[] entry must use a task-scoped association name, identify kind 'temporary_trigger_batch', lifetime 'task_scoped', owner_transaction, context, members, target_transactions, generated signals, schedule, dependency_policy, storage, source, and sink, and must make clear that a static '(group ...)' declaration is optional review metadata, not required membership. Preserve existing actor_network.group_schedules[] as a schema-version-1 compatibility view for current downstream consumers, with docs, public contract metadata, focused tests, strict CLI JSON parity, and mdBook updates in the same slice. Do not claim generated ATL children, generated ATL tops, peer event coupling, endpoint data movement coupling, route mux/storage, CDC, payloads, ready/backpressure, broader fan-in/fan-out, or permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; prove -Iperl t/1322-isf-actor-network-static.t t/1324-isf-atl-fixture-coverage.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_trigger_batch_pipeline.isf; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.2: add ATL association reports`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.3`
  Status: `completed`
  Goal: `Select the next bounded ATL temporary-association behavior after canonical reports.`
  Acceptance: `Review the now-shipped canonical association_schedules[] report family and choose the next behavior-bearing or design-clarification slice before code. Candidate directions include coupling temporary trigger batches with peer event waits, adding a temporary data-movement association fixture, selecting generated child artifact boundaries, or tightening compatibility/deprecation policy for group_schedules[]. No code changes may begin until this leaf records the selected source shape, report impact, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.3: select ATL data-route fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4`
  Status: `completed`
  Goal: `Promote a realistic ATL scalar data-route fixture.`
  Acceptance: `Add isf/atl_data_route_pipeline.isf as a bounded data-movement fixture using already shipped ATL source syntax: two direct static actor instances, one named drive body with exactly one '(consumer.payload producer.payload)' scalar actor-to-actor endpoint pair, and one top-level transaction drive call. The fixture must emit only atl_data_route_pipeline.fsm, preserve the generated parent handoff ports producer_payload and consumer_payload, report one actor_network.data_movements[] entry with route_lifetime drive_call_cycle and no storage, keep actor_network.association_schedules[] and group_schedules[] empty because this is a drive-activated data route rather than a trigger-batch association, and prove strict schedule JSON parity plus plain/strict HDL reachability. Do not claim generated ATL child artifacts, generated ATL tops, route mux/storage, peer events, trigger/data coupling, wider payloads, fan-in/fan-out, CDC, ready/backpressure, compact aliases, or permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1325-isf-atl-data-route-fixture-coverage.t; prove -Iperl t/1325-isf-atl-data-route-fixture-coverage.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_data_route_pipeline.isf; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=231, Tests=1360); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.4: add ATL data-route fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.5`
  Status: `completed`
  Goal: `Select the next ATL temporary-association behavior after the scalar data-route fixture.`
  Acceptance: `Review the shipped trigger-batch association report, scalar data-route fixture, actor-event wait, actor-transaction trigger, pin movement, and static group surfaces; choose one next bounded behavior-bearing or design-clarification slice before code. Candidate directions include coupling temporary trigger batches with peer event waits, adding fixture coverage for pin movement, selecting generated child artifact boundaries, tightening group_schedules[] compatibility/deprecation policy, or selecting a richer scheduled data-route association. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.5: select ATL pin ingress fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.6`
  Status: `completed`
  Goal: `Promote a realistic ATL top-level input-pin to actor fixture.`
  Acceptance: `Add isf/atl_pin_ingress_pipeline.isf as a bounded network-boundary data-movement fixture using already shipped ATL source syntax: one direct static actor instance, one scalar top-level input pin named payload, one named drive body with exactly one '(consumer.payload pins.payload)' pin-to-actor endpoint pair, and one top-level transaction drive call. The fixture must emit only atl_pin_ingress_pipeline.fsm, preserve payload as the existing top-level input source, expose the generated actor handoff output consumer_payload, report one actor_network.data_movements[] entry with kind scalar_pin_to_actor_handoff, source top_level_pin, sink external_handoff, route_lifetime drive_call_cycle, and storage none, keep actor_network.association_schedules[] and group_schedules[] empty, and prove strict schedule JSON parity plus plain/strict HDL reachability. Do not claim generated ATL child artifacts, generated ATL tops, actor-to-pin egress, bidirectional pin movement, route mux/storage, peer events, trigger/data coupling, wider payloads, fan-in/fan-out, CDC, ready/backpressure, compact aliases, or permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1326-isf-atl-pin-ingress-fixture-coverage.t; prove -Iperl t/1326-isf-atl-pin-ingress-fixture-coverage.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_pin_ingress_pipeline.isf; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=232, Tests=1363); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.6: add ATL pin ingress fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.7`
  Status: `completed`
  Goal: `Select the next ATL network-boundary fixture after pin ingress.`
  Acceptance: `Review the shipped pin-ingress fixture and choose the next bounded ATL network-boundary or association slice before code. Candidate directions include selecting the inverse actor-to-top-level output pin egress fixture, coupling trigger batches with event waits, selecting generated child artifact boundaries, or tightening group_schedules[] compatibility/deprecation policy. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.7: select ATL pin egress fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.8`
  Status: `completed`
  Goal: `Promote a realistic ATL actor to top-level output-pin fixture.`
  Acceptance: `Add isf/atl_pin_egress_pipeline.isf as a bounded network-boundary data-movement fixture using already shipped ATL source syntax: one direct static actor instance, one scalar top-level output pin named result, one named drive body with exactly one '(pins.result producer.payload)' actor-to-pin endpoint pair, and one top-level transaction drive call. The fixture must emit only atl_pin_egress_pipeline.fsm, expose the generated actor source handoff input producer_payload, preserve result as the existing top-level output sink, report one actor_network.data_movements[] entry with kind scalar_actor_to_pin_handoff, source external_handoff, sink top_level_pin, route_lifetime drive_call_cycle, and storage none, keep actor_network.association_schedules[] and group_schedules[] empty, and prove strict schedule JSON parity plus plain/strict HDL reachability. Do not claim generated ATL child artifacts, generated ATL tops, bidirectional pin movement, route mux/storage, peer events, trigger/data coupling, wider payloads, fan-in/fan-out, CDC, ready/backpressure, compact aliases, or permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1327-isf-atl-pin-egress-fixture-coverage.t; prove -Iperl t/1327-isf-atl-pin-egress-fixture-coverage.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_pin_egress_pipeline.isf; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=233, Tests=1366); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.8: add ATL pin egress fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.9`
  Status: `completed`
  Goal: `Select the next ATL behavior after the scalar boundary fixture ladder.`
  Acceptance: `Review the shipped trigger-batch, actor-to-actor data route, pin-ingress, and pin-egress fixture ladder; choose the next bounded ATL behavior-bearing or design-clarification slice before code. Candidate directions include coupling temporary trigger batches with peer event waits, selecting generated child artifact boundaries, tightening group_schedules[] compatibility/deprecation policy, or selecting a richer scheduled data-route association. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.9: select ATL trigger-wait fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.10`
  Status: `completed`
  Goal: `Promote a realistic ATL single-actor trigger/event wait fixture.`
  Acceptance: `Add isf/atl_trigger_wait_pipeline.isf as a bounded orchestration fixture using already shipped ATL source syntax: one direct static actor instance named worker, one top-level transaction that reacts to start, emits exactly one '(trigger worker.process)' one-cycle trigger handoff, then waits on exactly one '(await worker.done)' event handoff before completing done. The fixture must emit only atl_trigger_wait_pipeline.fsm, expose worker_process_start as the generated parent trigger output, expose worker_done as the generated parent event input, report one actor_network.transaction_triggers[] entry and one actor_network.event_waits[] entry, keep actor_network.association_schedules[], group_schedules[], groups[], and data_movements[] empty, and prove strict schedule JSON parity plus plain/strict HDL reachability. Do not claim temporary trigger-batch plus event coupling, multiple waits, multiple triggers, generated ATL child artifacts, generated ATL tops, actor type resolution, HDL child wiring, event payloads, data movement coupling, route mux/storage, fan-in/fan-out, CDC, ready/backpressure, compact aliases, or permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1328-isf-atl-trigger-wait-fixture-coverage.t; prove -Iperl t/1328-isf-atl-trigger-wait-fixture-coverage.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_trigger_wait_pipeline.isf; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=234, Tests=1369); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.10: add ATL trigger-wait fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.11`
  Status: `completed`
  Goal: `Select the next ATL behavior after the single-actor trigger/event wait fixture.`
  Acceptance: `Review the shipped trigger-batch, scalar data-route, pin-ingress, pin-egress, and trigger-wait fixture ladder; choose the next bounded ATL behavior-bearing or design-clarification slice before code. Candidate directions include temporary trigger-batch plus event-wait coupling, generated child artifact boundaries, actor type resolution prerequisites, richer scheduled data-route associations, or group_schedules[] compatibility/deprecation policy. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.11: select ATL trigger-batch wait fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12`
  Status: `completed`
  Goal: `Promote a realistic ATL temporary trigger-batch plus single event-wait fixture.`
  Acceptance: `Add isf/atl_trigger_batch_wait_pipeline.isf as a bounded orchestration fixture using already shipped ATL source syntax: three direct static actor instances, one top-level transaction that reacts to start, emits one contiguous temporary trigger batch with exactly three '(trigger actor.transaction)' clauses to distinct actors, then waits on exactly one '(await writer.done)' event handoff from one triggered actor before completing done. The fixture must emit only atl_trigger_batch_wait_pipeline.fsm, expose reader_capture_start, filter_process_start, writer_emit_start as generated parent trigger outputs, expose writer_done as the generated parent event input, report per-target transaction_triggers[], one association_schedules[] temporary_trigger_batch entry, one group_schedules[] schema-version-1 compatibility entry, one event_waits[] entry, and empty groups[] and data_movements[]. It must prove strict schedule JSON parity plus plain/strict HDL reachability. Do not claim multiple event waits, await_all/await_any actor-event fan-in, generated ATL child artifacts, generated ATL tops, actor type resolution, HDL child wiring, event payloads, endpoint data movement coupling, route mux/storage, CDC, ready/backpressure, compact aliases, or permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t; prove -Iperl t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_trigger_batch_wait_pipeline.isf; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=235, Tests=1372); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.12: add ATL trigger-batch wait fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.13`
  Status: `completed`
  Goal: `Select the next ATL behavior after trigger-batch/event wait coupling.`
  Acceptance: `Review the shipped trigger-batch, scalar data-route, pin-ingress, pin-egress, trigger-wait, and trigger-batch-wait fixture ladder; choose the next bounded ATL behavior-bearing or design-clarification slice before code. Candidate directions include generated child artifact boundaries, actor type resolution prerequisites, multi-event fan-in policy, richer scheduled data-route associations, or group_schedules[] compatibility/deprecation policy. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.13: select ATL multi-wait boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.14`
  Status: `completed`
  Goal: `Prove multi-event fan-in after ATL trigger batches remains fail-closed.`
  Acceptance: `Add focused negative coverage for a top-level transaction that emits one selected temporary trigger batch and then attempts two actor event waits, for example '(await reader.done)' followed by '(await writer.done)'. The parser must fail before scheduled emission with the existing ATL one-event-wait diagnostic, proving that .9.12 did not accidentally claim multi-event fan-in, await-all actor-event aggregation, generated ATL child completion joins, route/storage insertion, or permanent actor grouping. The slice must sync task tree, roadmap/live docs, and mdBook/backlog wording if user-facing deferred behavior text changes. No production behavior should be widened.`
  Verification: `perl -Iperl -c t/1322-isf-actor-network-static.t; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=235, Tests=1372); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.14: prove ATL multi-wait boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.15`
  Status: `completed`
  Goal: `Select the next ATL generated-child or actor type-resolution boundary.`
  Acceptance: `Review the shipped parent-handoff ATL ladder and the now-regression-backed multi-event boundary; choose the next bounded behavior-bearing or design-clarification slice before code. Candidate directions include generated ATL child artifact naming, actor type resolution prerequisites, generated ATL top boundaries, generated child event wiring, or richer scheduled data-route association policy. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.15: select ATL actor-root boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.16`
  Status: `completed`
  Goal: `Fail closed multiple top-level actor roots before ATL type resolution.`
  Acceptance: `Parser coverage rejects sources with more than one top-level '(actor ...)' root using a targeted diagnostic that explains FSMGen currently accepts one compile/report entry actor and that sibling actor roots are not ATL child type definitions until actor type resolution is explicitly selected. Valid one-actor sources and one actor plus '(library ...)' roots remain accepted. Specs, downstream handoff, public contract, mdBook, task tree, tests, and live docs stay synchronized. No generated ATL child '.fsm', generated ATL top, actor type resolution, HDL child wiring, or source lookup behavior is claimed.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c t/1322-isf-actor-network-static.t; prove -Iperl t/1322-isf-actor-network-static.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=235, Tests=1373); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.16: fail closed ATL actor roots`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.17`
  Status: `completed`
  Goal: `Select the explicit ATL actor type-resolution source contract.`
  Acceptance: `Review the shipped one-actor source-root boundary, existing same-source and external '(library ...)' actor export machinery, generated composition artifact naming, and ATL parent-handoff surfaces; choose the next bounded source-resolution contract before code. Candidate directions include resolving '(instance NAME of ACTOR_TYPE)' only through imported library actor exports, selecting same-source library export examples, selecting generated child artifact names, or deferring sibling actor roots permanently. No code changes may begin until this leaf records source syntax, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.17: select ATL type resolution contract`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.18`
  Status: `completed`
  Goal: `Fail closed the selected library-qualified ATL actor type syntax before generated child resolution.`
  Acceptance: `Parser coverage recognizes '(instance NAME of ALIAS.EXPORT)' as the selected future ATL actor type-resolution source shape when ALIAS names an imported library namespace, rejects it with a targeted diagnostic before scheduled '.fsm' emission, and preserves existing unqualified '(instance NAME of ACTOR_TYPE)' metadata plus existing '(use alias.actor as instance ...)' reusable-library behavior. Same-source and external library roots may remain resolver inputs, but no actor type is resolved, no actor_network instance report keys change, no generated ATL child '.fsm', generated ATL top, HDL child wiring, event wiring, route mux/storage, or ready/backpressure behavior is claimed. Specs, downstream handoff, public contract, mdBook, task tree, tests, and live docs must stay transparent that this is a source-contract reservation leaf.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c t/1322-isf-actor-network-static.t; prove -Iperl t/1322-isf-actor-network-static.t t/1230-isf-library-import-resolution.t t/1231-isf-library-generated-top.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=235, Tests=1374); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.18: fail closed ATL type syntax`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.19`
  Status: `completed`
  Goal: `Select the first ATL library-qualified actor type resolution metadata subset.`
  Acceptance: `Review the targeted '.9.18' reservation diagnostics, existing reusable-library generated child artifact machinery, current actor_network instance report key contract, and parent handoff surfaces; choose the next bounded source-resolution or generated-artifact slice before code. Candidate directions include resolving '(instance NAME of ALIAS.EXPORT)' to metadata-only library/export provenance without child emission, selecting child artifact names and generated-top packaging, selecting interface binding inference from existing trigger/event/data handoffs, or adding external-library file coverage for the reserved syntax. No code changes may begin until this leaf records source syntax, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.19: select ATL type metadata`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.20`
  Status: `completed`
  Goal: `Resolve library-qualified ATL actor types to report-visible metadata without generating child artifacts.`
  Acceptance: `Parser/lowering accepts '(instance NAME of ALIAS.EXPORT)' only when ALIAS is an explicit HDL identifier import alias from '(imports (library LIBRARY as ALIAS))' and EXPORT names an actor export in that library, records library/export provenance on the existing actor_network.instances[] entry, and reserves deterministic future child artifact names while still emitting only the parent scheduled '.fsm'. The shipped unqualified '(instance NAME of ACTOR_TYPE)' metadata-only surface and existing '(use alias.actor as instance ...)' reusable-library generated-top path remain unchanged. No generated ATL child '.fsm', generated ATL top, HDL child wiring, inferred event/trigger/data handoff binding, route mux/storage, ready/backpressure, actor-event fan-in, CDC, or permanent actor grouping is claimed.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1322-isf-actor-network-static.t; prove -Iperl t/1322-isf-actor-network-static.t t/1230-isf-library-import-resolution.t t/1231-isf-library-generated-top.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.20: resolve ATL type metadata`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.21`
  Status: `completed`
  Goal: `Select the next ATL generated-child, generated-top, or interface-binding boundary after metadata-only type resolution.`
  Acceptance: `Review the shipped metadata-only library-qualified type resolution, existing reusable-library child artifact machinery, current parent trigger/event/data handoff surfaces, and report-visible reserved child names; choose one bounded next slice before code. Candidate directions include generating resolved child '.fsm' artifacts without an ATL top, selecting generated ATL top packaging, selecting interface binding inference from current parent handoffs, proving conflict/fail-closed boundaries for duplicate reserved child names, or selecting a realistic fixture that consumes resolved type metadata. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.21: select ATL child artifacts`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.22`
  Status: `completed`
  Goal: `Emit resolved ATL child scheduled artifacts without generating an ATL top.`
  Acceptance: `Parser/lowering accepts the already shipped '(instance NAME of ALIAS.EXPORT)' metadata-resolution shape, carries the exported actor shell into lowering, and emits one child scheduled '.fsm' artifact for each resolved ATL static actor instance using the reserved '<parent_actor>__<instance>.fsm' name. The parent scheduled '.fsm' remains unchanged, no generated ATL top is emitted, and existing trigger/event/data handoffs remain external parent handoffs. Existing '(use alias.actor as instance ...)' reusable-library generated-top behavior stays unchanged and remains separate from ATL '(instance ...)' type resolution. The slice must reject or fail closed duplicate generated child names that would collide with generated transaction children, reusable-library uses, or another resolved ATL instance. Schedule JSON keeps the existing resolved actor_network.instances[] metadata without adding a new report family unless the public contract is updated in the same slice. Generated ATL top packaging, HDL child wiring, inferred interface binding, event/trigger/data handoff binding, route mux/storage, ready/backpressure, actor-event fan-in, CDC, recursive actor networks, and permanent actor grouping remain deferred.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c t/1322-isf-actor-network-static.t; prove -Iperl t/1322-isf-actor-network-static.t t/1230-isf-library-import-resolution.t t/1231-isf-library-generated-top.t; prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.22: emit ATL child artifacts`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.23`
  Status: `completed`
  Goal: `Select the next ATL generated-top, interface-binding, or emitted-child fixture boundary.`
  Acceptance: `Review the shipped resolved child artifact emission, existing parent trigger/event/data handoff surfaces, reusable-library generated-top machinery, and current report contract; choose the next bounded slice before code. Candidate directions include selecting generated ATL top packaging, selecting interface binding inference from current parent handoffs, promoting a realistic emitted-child fixture, or proving a fail-closed boundary around attempted handoff wiring before an ATL top exists. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.23: select ATL resolved-child fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.24`
  Status: `completed`
  Goal: `Promote a realistic ATL resolved-child artifact fixture.`
  Acceptance: `Add isf/atl_resolved_child_pipeline.isf as a bounded emitted-child fixture using shipped ATL source syntax: one top-level actor imports a same-source library as an explicit alias, declares one resolved '(instance worker of pkt_lib.packet_worker)', emits one '(trigger worker.process)' parent handoff, waits on one '(await worker.done)' parent handoff, and completes. The fixture must lower to exactly the parent scheduled artifact 'atl_resolved_child_pipeline.fsm' and the resolved child artifact 'atl_resolved_child_pipeline__worker.fsm', emit no generated ATL top, keep trigger/event handoffs external, report resolved actor_network.instances[] metadata plus one transaction_triggers[] entry and one event_waits[] entry, keep data_movements[]/association_schedules[]/group_schedules[] empty, and prove strict schedule JSON parity. It must not claim generated ATL tops, HDL child wiring, inferred interface binding, route mux/storage, actor-event fan-in, CDC, ready/backpressure, recursive actor networks, or permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1139-isf-public-lower-result-metadata-audit.t; perl -Iperl -c t/1142-isf-public-guidance-metadata-audit.t; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t t/1183-ci-regression-tier-selection.t; prove -Iperl t/1139-isf-public-lower-result-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1376); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.24: add ATL resolved-child fixture`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.25`
  Status: `completed`
  Goal: `Select the next ATL generated-top, interface-binding, or fail-closed boundary after resolved-child fixture coverage.`
  Acceptance: `Review the shipped resolved child artifact fixture, existing parent trigger/event/data handoff surfaces, reusable-library generated-top machinery, current lower-result file contract, and public report metadata; choose one bounded next slice before code. Candidate directions include selecting generated ATL top packaging, selecting explicit interface binding inference from current parent handoffs, adding fail-closed coverage for attempted handoff wiring before an ATL top exists, or selecting a richer resolved-child fixture. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.25: select ATL generated top`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.26`
  Status: `completed`
  Goal: `Emit the first generated ATL top with resolved-child trigger/event handoff wiring.`
  Acceptance: `Implement only the selected first generated ATL top subset for the resolved-child fixture shape: one top-level actor, exactly one resolved '(instance NAME of ALIAS.EXPORT)' child, one accepted parent '(trigger instance.transaction)' handoff to that child, one accepted parent '(await instance.event)' handoff from that same child, same clock/reset names and reset policy between parent and child, no ATL data movements, no association/group schedules, and no additional resolved ATL children. Lowering must emit '<parent>_top.fsm' in addition to the parent and child '.fsm' artifacts, instantiate the parent and child, wire top-level public pins to the parent, wire the parent trigger handoff output to the resolved child transaction start input discovered from the child transaction's '(on START_SIGNAL)' source, wire the child event output to the parent event handoff input, and report the generated ATL top through an additive actor_network generated-top metadata family. The implementation must fail closed for missing child target transactions, target transactions without a scalar '(on ...)' start signal, event names that are not child output ports, multiple resolved children, multiple or repeated trigger/event bindings, cross-clock or reset-mismatched parent/child pairs, data-movement coupling, trigger batches, groups, ready/backpressure, payload bindings, route mux/storage, recursive actor networks, and any generated-top name conflict.`
  Verification: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1322-isf-actor-network-static.t; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1116-isf-public-schedule-report-key-family-audit.t t/1131-isf-public-top-level-discovery-audit.t t/1139-isf-public-lower-result-metadata-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1255-isf-schedule-report-golden-matrix.t; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1378); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.26: emit ATL generated top`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.27`
  Status: `completed`
  Goal: `Select the next ATL generated-top, interface-binding, HDL handoff, or fail-closed boundary after the first generated top.`
  Acceptance: `Review the shipped first generated ATL top, actor_network.generated_tops[] report metadata, current fail-closed boundaries, and remaining ATL deferrals; choose one bounded next slice before code. Candidate directions include generated-top HDL promotion, explicit interface-binding widening, richer resolved-child fixtures, data-route integration with generated children, or additional fail-closed coverage for multi-child/top wiring attempts. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.27: select ATL HDL top promotion`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.28`
  Status: `completed`
  Goal: `Promote generated ATL top HDL reachability for the resolved-child fixture.`
  Acceptance: `Implement only the selected HDL promotion for the already shipped resolved-child generated-top shape: one top-level actor, one resolved library-qualified child, one parent trigger handoff wired to the child's scalar transaction start input, one parent event wait wired from the child's scalar output event, matching parent/child clock and reset policy, and no ATL data movements, trigger batches, groups, additional resolved children, payloads, ready/backpressure, CDC, route mux/storage, recursive actor networks, or permanent actor grouping. The focused fixture must prove plain and strict CLI HDL generation for isf/atl_resolved_child_pipeline.isf, assert that the generated SystemVerilog output contains the generated top module plus parent and child modules, and assert that the top-level HDL carries the internal parent/child trigger and event links. If implementation changes are required, they must be limited to selecting the materialized ATL top as the HDL entry for this resolved-child lower result while preserving existing single-file, reusable-library, multi-domain, and schedule-JSON behavior. Documentation must remain transparent that broader ATL HDL wiring remains unshipped.`
  Verification: `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.28: promote ATL top HDL`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.29`
  Status: `completed`
  Goal: `Select the next ATL generated-child integration, interface-binding, or fail-closed boundary after generated-top HDL promotion.`
  Acceptance: `Review the now-shipped generated ATL top '.fsm' and plain/strict HDL proof, current actor_network.generated_tops[] metadata, remaining data-route/generated-child integration gap, multi-child/top fail-closed boundaries, and interface-binding deferrals; choose one bounded next slice before code. Candidate directions include generated-child data-route integration, explicit interface-binding widening, richer resolved-child fixtures, multi-child fail-closed coverage, or CDC/reset-remap boundary hardening. No code changes may begin until this leaf records source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.29: select ATL pin ingress top wiring`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.30`
  Status: `completed`
  Goal: `Wire one scalar top-level input-pin route into one resolved ATL child through the generated top.`
  Acceptance: `Implement only the selected scalar pin-ingress generated-top subset: one top-level actor with one resolved '(instance worker of pkt_lib.packet_worker)', one top-level scalar input pin such as 'payload', one named drive body with exactly one '(worker.payload pins.payload)' pair, one transaction that drives that route, triggers the same child transaction, awaits the same child event, and completes, and matching parent/child clock and reset policy. Lowering must keep the parent and child scheduled '.fsm' artifacts reviewable, emit '<parent>_top.fsm', expose the real top-level public pins on the generated top, wire the top input pin to the parent, wire the parent generated sink handoff output 'worker_payload' to the child's scalar input port 'payload', wire the existing parent trigger/event handoffs as in '.9.26', and report the route through actor_network.data_movements[] while preserving generated-top discovery through actor_network.generated_tops[]. It must fail closed for non-pin sources, actor-to-actor routes, actor-to-pin routes, multiple data movements, width mismatches, missing child input ports, data movement targeting a different instance than the resolved child, data movement in a different transaction than the trigger/event pair, trigger batches, groups, additional resolved children, payload/ready/backpressure protocol assumptions, route mux/storage, CDC/reset remapping, recursive actor networks, and permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm; perl -Iperl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm; perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1383); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.30: wire ATL pin ingress top`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.31`
  Status: `completed`
  Goal: `Select the next bounded ATL generated-child integration or fail-closed boundary after pin-ingress top wiring.`
  Acceptance: `Review the shipped resolved-child generated top with trigger/event wiring and the shipped scalar top-level input-pin route into the child. Select one next bounded behavior-bearing or design-maintenance leaf before code, with exact source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope. Candidate directions include the inverse resolved-child actor-to-top-level output pin route, generated-child actor-to-actor data-route coupling, multi-child generated-top fail-closed coverage, width/interface binding hardening, or CDC/reset-remap boundary hardening.`
  Verification: `passed: mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.31: select ATL pin egress top wiring`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.32`
  Status: `completed`
  Goal: `Wire one scalar resolved-child output route to one top-level output pin through the generated top.`
  Acceptance: `Implement only the selected scalar pin-egress generated-top subset: one top-level actor with one resolved '(instance worker of pkt_lib.packet_worker)', one top-level scalar output pin such as 'result', one named drive body with exactly one '(pins.result worker.payload)' pair, one transaction that triggers the child transaction, awaits the same child event, drives that route after the event wait, and completes, and matching parent/child clock and reset policy. Lowering must keep the parent and child scheduled '.fsm' artifacts reviewable, emit '<parent>_top.fsm', expose the real top-level public pins on the generated top, wire the child scalar output port 'payload' to the parent generated source handoff input 'worker_payload', wire the parent top-level output 'result' to the generated top output, wire the existing parent trigger/event handoffs as in '.9.26', and report the route through actor_network.data_movements[] while preserving generated-top discovery through actor_network.generated_tops[]. It must fail closed for non-pin sinks, pin sources, actor-to-actor routes, multiple data movements, width mismatches, missing child output ports, data movement targeting a different instance than the resolved child, data movement in a different transaction than the trigger/event pair, drive calls before the child event wait, trigger batches, groups, additional resolved children, payload/ready/backpressure protocol assumptions, route mux/storage, CDC/reset remapping, recursive actor networks, and permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm; perl -Iperl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm; perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_resolved_child_pin_egress_pipeline.isf; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1387); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.32: wire ATL pin egress top`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.33`
  Status: `completed`
  Goal: `Select the next bounded ATL generated-child integration or fail-closed boundary after pin-egress top wiring.`
  Acceptance: `Review the shipped generated-child trigger/event top plus scalar pin-ingress and pin-egress generated-top routes. Select one next bounded behavior-bearing or design-maintenance leaf before code, with exact source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope. Candidate directions include generated-child actor-to-actor data-route coupling, multi-child generated-top fail-closed coverage, trigger/event/data ordering hardening, width/interface binding hardening, or CDC/reset-remap boundary hardening.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.33: select ATL multi-child route boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.34`
  Status: `completed`
  Goal: `Fail closed the reserved generated-child actor-to-actor data-route shape before multi-child ATL top wiring is implemented.`
  Acceptance: `Implement only the diagnostic boundary for the selected deferred shape: a top-level actor with two resolved library-backed static child instances such as 'reader' and 'writer', one named drive body with exactly one existing '(sink source)' movement pair '(writer.payload reader.payload)', and one parent transaction that triggers the producer child, awaits the producer event, drives the movement, then attempts to trigger or await the sink child. FSMGen must reject this generated-child actor-to-actor route with a targeted ATL diagnostic before lowering or HDL emission claims multi-child top scheduling. Existing shipped parent-handoff actor-to-actor data routes without resolved generated-child trigger/event coupling must remain accepted. Existing one-child generated-top trigger/event, pin-ingress, and pin-egress fixtures must remain accepted. No new public report family, generated-top schema, storage, route mux, ready/backpressure, CDC/reset remap, recursive actor network, or permanent actor grouping behavior is selected.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1387); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.34: fail closed ATL multi-child route`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.35`
  Status: `completed`
  Goal: `Select the next bounded ATL multi-child generated-top design or fail-closed boundary after the generated-child actor-to-actor route diagnostic.`
  Acceptance: `Review the shipped one-child generated top, pin-ingress and pin-egress generated-top routes, and the generated-child actor-to-actor fail-closed diagnostic. Select one next bounded behavior-bearing or design-maintenance leaf before code, with exact source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, and verification scope. Candidate directions include selecting a multi-child generated-top internal representation, adding multi-child generated-top report-only metadata, selecting positive source/sink child trigger ordering semantics, width/interface binding hardening, or CDC/reset-remap boundary hardening.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.35: select ATL two-child top`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.36`
  Status: `completed`
  Goal: `Emit one generated ATL top that wires two resolved children through sequential trigger/event handoffs without data movement.`
  Acceptance: `Implement only the selected two-child trigger/event generated-top subset: one top-level actor with two resolved library-backed static child instances such as 'reader' and 'writer', no ATL data movements, one transaction that triggers reader.capture, awaits reader.done, triggers writer.emit, awaits writer.done, then completes, and matching parent/child clock/reset policy across both children. Lowering must emit the parent scheduled '.fsm', both resolved child '.fsm' artifacts, and one '<parent>_top.fsm' that instantiates the parent plus both children, exposes only the real top-level public pins, wires each parent trigger handoff to the matching child transaction start input, and wires each child event output to the matching parent event handoff input. Schedule JSON must keep per-child entries under actor_network.instances[], per-trigger evidence under actor_network.transaction_triggers[], per-event evidence under actor_network.event_waits[], and generated-top discovery under actor_network.generated_tops[] without adding a new public report family. It must fail closed for data movement coupling, trigger batches, groups, repeated triggers to one child, event fan-in/fan-out, child clock/reset mismatch, missing child transactions or event ports, route mux/storage, ready/backpressure, CDC, recursive actor networks, and permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_two_child_pipeline.isf; prove -Iperl t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1391); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.36: emit ATL two-child top`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.37`
  Status: `completed`
  Goal: `Select the next bounded ATL widening after the shipped two-child trigger/event generated top.`
  Acceptance: `Review the shipped two-child generated top, the generated_tops[] multi-child children[] metadata, remaining generated-child actor-to-actor data-route deferral, pin-route coupling limits, trigger/event fan-in and fan-out limits, CDC/reset-remap boundaries, temporary association/grouping boundaries, and fixture coverage. Choose exactly one next behavior-bearing or hardening slice before code. The selected leaf must record source shape, report impact, generated artifact expectations, fail-closed boundaries, mdBook impact, downstream-contract impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.37: select ATL child data route`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.38`
  Status: `completed`
  Goal: `Lower one scalar generated-child actor-to-actor data route through the two-child ATL generated top.`
  Acceptance: `Implement only the selected positive generated-child actor-to-actor route: one top-level actor with two resolved library-backed children 'reader' and 'writer', one named drive body containing one '(writer.payload reader.payload)' scalar pair, and one parent transaction that triggers reader.capture, awaits reader.done, calls the drive body, triggers writer.emit, awaits writer.done, then completes. Lowering must emit parent, reader, writer, and generated top '.fsm' artifacts. The parent must expose reader_payload as the generated source handoff input and writer_payload as the generated sink handoff output for the drive-call cycle. The generated top must wire reader.payload to the parent reader_payload handoff, parent writer_payload to writer.payload, and keep the existing reader/writer trigger and event links internal. Schedule JSON must keep the route in actor_network.data_movements[] with existing scalar_actor_handoff keys and keep generated-top discovery under actor_network.generated_tops[] without adding a new public report family. The child scheduled '.fsm' artifacts must preserve generated +interface role metadata for reader payload output and writer payload input. Broader multi-child data wiring, fan-in/fan-out, route mux/storage, CDC/reset remapping, repeated triggers, trigger batches, groups, ready/backpressure, payload protocols, recursive actor networks, permanent actor grouping, and any route that lacks the selected trigger-await-drive-trigger-await order remain fail-closed.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t; ./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_two_child_data_pipeline.isf; prove -Iperl t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1305-isf-book-feature-matrix-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1395); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.38: wire ATL child data route`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.39`
  Status: `completed`
  Goal: `Select the next bounded ATL widening or hardening slice after the shipped two-child generated-child data route.`
  Acceptance: `Review the shipped two-child scalar generated-child actor-to-actor route, route order diagnostics, generated-top data-link internals, generated_tops[] and data_movements[] report ownership, remaining multi-route/fan-in/fan-out/mux/storage deferrals, trigger-batch/group boundaries, CDC/reset-remap limits, repeated-trigger limits, and downstream/mdBook truth. Choose exactly one next behavior-bearing or hardening slice before code, with source shape, report impact, generated artifact expectations, fail-closed boundaries, documentation impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.39: select ATL route hardening`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.40`
  Status: `completed`
  Goal: `Harden generated-child actor-to-actor data-route fail-closed boundaries after the first positive route.`
  Acceptance: `Implement only diagnostic/coverage hardening around the shipped 'atl_two_child_data_pipeline' shape: the source child endpoint must be a scalar child output, the sink child endpoint must be a scalar child input, exactly one ATL data-movement drive body with exactly one endpoint pair may participate, and exactly one top-level transaction drive call may activate it. Existing positive generated-child actor-to-actor, control-only two-child, pin-ingress, pin-egress, and parent-handoff data-route fixtures must remain accepted. If the current implementation already rejects a selected invalid shape, this leaf should add focused regression coverage and keep the diagnostic stable. It must not select route muxes, inserted storage, multi-route wiring, fan-in/fan-out, repeated triggers, trigger batches, groups, CDC/reset remapping, ready/backpressure, payload protocols, recursive actor networks, or permanent actor grouping.`
  Verification: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm; perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm; perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1305-isf-book-feature-matrix-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1395); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.40: harden ATL route boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.41`
  Status: `completed`
  Goal: `Select the next bounded ATL widening or hardening slice after generated-child route boundary hardening.`
  Acceptance: `Review the shipped two-child generated top, the positive generated-child actor-to-actor data route, the newly hardened source/sink port and cardinality diagnostics, remaining multi-route/fan-in/fan-out/mux/storage deferrals, trigger-batch/group boundaries, CDC/reset-remap limits, repeated-trigger limits, and downstream/mdBook truth. Choose exactly one next behavior-bearing or hardening slice before code, with source shape, report impact, generated artifact expectations, fail-closed boundaries, documentation impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.41: select ATL width boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.42`
  Status: `completed`
  Goal: `Harden scalar-width diagnostics for generated-child actor-to-actor route endpoints.`
  Acceptance: `Implement only width-boundary hardening around the shipped 'atl_two_child_data_pipeline' shape: the selected generated-child actor-to-actor route remains scalar one-bit only, so a source child output endpoint wider than one bit and a sink child input endpoint wider than one bit must fail closed with targeted diagnostics before any wider payload protocol, packing, truncation, extension, mux, or storage behavior is claimed. Existing positive generated-child actor-to-actor, control-only two-child, pin-ingress, pin-egress, and parent-handoff data-route fixtures must remain accepted. No source syntax, report key, generated artifact shape, route mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure, payload protocol, recursive actor network, or permanent actor grouping behavior may be widened.`
  Verification: `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1395); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.42: harden ATL width boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.43`
  Status: `completed`
  Goal: `Select the next bounded ATL widening or hardening slice after scalar-width route hardening.`
  Acceptance: `Review the shipped two-child generated top, positive generated-child actor-to-actor data route, source/sink role hardening, route-cardinality hardening, scalar endpoint-width hardening, remaining multi-route/fan-in/fan-out/mux/storage deferrals, trigger-batch/group boundaries, CDC/reset-remap limits, repeated-trigger limits, and downstream/mdBook truth. Choose exactly one next behavior-bearing or hardening slice before code, with source shape, report impact, generated artifact expectations, fail-closed boundaries, documentation impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.43: select ATL clock boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.44`
  Status: `completed`
  Goal: `Harden same-clock/reset-policy diagnostics for generated-child actor-to-actor route wiring.`
  Acceptance: `Implement only fail-closed coverage around the shipped 'atl_two_child_data_pipeline' generated-child actor-to-actor route: a source child with a clock different from the parent, a sink child with a clock different from the parent, a source child with a reset signature different from the parent, and a sink child with a reset signature different from the parent must fail closed before any CDC, reset remapping, generated-top system-port remapping, async bridge, storage, mux, ready/backpressure, or payload protocol behavior is claimed. Existing positive generated-child actor-to-actor, control-only two-child, pin-ingress, pin-egress, and parent-handoff data-route fixtures must remain accepted. No source syntax, report key, generated artifact shape, route mux/storage, fan-in/fan-out, wider payload, recursive actor network, or permanent actor grouping behavior may be widened.`
  Verification: `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; mdbook build docs/book; ./bin/ci-regression isf --no-book (Files=236, Tests=1395); git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.44: harden ATL clock boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.45`
  Status: `completed`
  Goal: `Select the next bounded ATL widening or hardening slice after same-clock/reset-policy route hardening.`
  Acceptance: `Review the shipped two-child generated top, positive generated-child actor-to-actor data route, source/sink role hardening, route-cardinality hardening, scalar endpoint-width hardening, same-clock/reset-policy hardening, remaining multi-route/fan-in/fan-out/mux/storage deferrals, trigger-batch/group boundaries, repeated-trigger limits, CDC/reset-remap limits, and downstream/mdBook truth. Choose exactly one next behavior-bearing or hardening slice before code, with source shape, report impact, generated artifact expectations, fail-closed boundaries, documentation impact, and verification scope.`
  Verification: `mdbook build docs/book; prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t; git diff --check`
  Commit: `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.45: select ATL self-route boundary`

- ID: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.46`
  Status: `active`
  Goal: `Harden distinct-source/sink child diagnostics for generated-child actor-to-actor route wiring.`
  Acceptance: `Implement only fail-closed coverage around the shipped 'atl_two_child_data_pipeline' generated-child actor-to-actor route: a drive-body pair whose source and sink actor qualifiers name the same resolved child instance must fail closed before any loopback, self-route, child-internal bypass, storage, mux, fan-in/fan-out, ready/backpressure, or payload protocol behavior is claimed. Existing positive generated-child actor-to-actor, control-only two-child, pin-ingress, pin-egress, and parent-handoff data-route fixtures must remain accepted. No source syntax, report key, generated artifact shape, CDC/reset remapping, route mux/storage, fan-in/fan-out, wider payload, recursive actor network, or permanent actor grouping behavior may be widened.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.46` | `active` | `.9.45` selected distinct source/sink child hardening before any generated-child self-route, loopback, storage, or bypass behavior. |

## Selected Two-Child Generated Data Route

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.37` selects the next implementation leaf
as `ISF-ACTOR-NETWORK-ORCHESTRATION.9.38`: one scalar generated-child
actor-to-actor data route through the already shipped two-child generated ATL
top.

Selected source shape:

```lisp
(actor atl_two_child_data_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance reader of pkt_lib.packet_reader)
  (instance writer of pkt_lib.packet_writer)
  (drive forward_payload
    (writer.payload reader.payload))
  (transaction run
    (on start)
    (trigger reader.capture)
    (await reader.done)
    (drive forward_payload)
    (trigger writer.emit)
    (await writer.done)
    (complete done)))
```

The selected child interface shape is scalar and one-bit only:

- `reader.capture` uses `(on capture_start)`, produces output `payload`, and
  pulses output `done`.
- `writer.emit` uses `(on emit_start)`, consumes input `payload`, and pulses
  output `done`.

Selected report impact:

- `actor_network.data_movements[]` remains the route provenance owner and
  reuses the existing `scalar_actor_handoff` key family.
- `actor_network.generated_tops[]` remains the generated-top discovery owner
  and keeps per-child wiring under `children[]`.
- No new public report family or schema-version bump is selected.

Selected generated artifact expectations:

- Lowering emits exactly parent, reader child, writer child, and generated
  top `.fsm` artifacts.
- The parent exposes `reader_payload` as the generated scalar source handoff
  input and `writer_payload` as the generated scalar sink handoff output.
- The parent drives `writer_payload` from `reader_payload` only in the
  `forward_payload` drive-call cycle.
- The generated top wires `reader.payload` to parent `reader_payload`, parent
  `writer_payload` to `writer.payload`, parent trigger handoffs to child
  start inputs, and child `done` outputs to parent event handoff inputs.
- The reader child carries generated `+interface` output metadata for
  `payload`; the writer child carries generated `+interface` input metadata
  for `payload`.

Selected fail-closed boundaries:

- Any route that lacks the selected trigger, source-event wait, drive,
  sink-trigger, sink-event wait order remains rejected.
- Multi-route, fan-in, fan-out, mux/storage, CDC/reset remapping,
  ready/backpressure, payload protocols, repeated triggers to one child,
  trigger batches, groups, recursive actor networks, permanent actor
  grouping, and wider payloads remain deferred.

Selected verification scope for `.9.38`:

- Parser/lowering syntax checks for the parser, lowerer, JSON emitter,
  composition top emitter, and public contract.
- A new file-backed fixture plus focused tests in
  `t/1330-isf-atl-resolved-child-fixture-coverage.t`.
- Strict schedule JSON parity, parent/child/top `.fsm` artifact checks,
  generated-top wiring checks, plain and strict HDL generation, missing child
  payload port diagnostics, and order-diagnostic coverage.
- Public contract, tested-by metadata, schedule-report golden/audit tests,
  ISF spec focused-test index, mdBook feature matrix audit, `mdbook build`,
  the ISF regression band, and `git diff --check`.

Implementation outcome for `.9.38`:

- `isf/atl_two_child_data_pipeline.isf` is the positive fixture.
- The parser accepts exactly the selected source/order shape and keeps other
  generated-child data routes fail-closed.
- Lowering emits parent, reader, writer, and generated top `.fsm` artifacts.
- The parent drives `writer_payload` from `reader_payload` in the
  `forward_payload` drive-call cycle.
- The generated top wires reader payload to the parent source handoff and
  parent sink handoff to writer payload.
- Schedule JSON reuses `actor_network.data_movements[]` and
  `actor_network.generated_tops[]`; no new public report family was added.

Selected hardening for `.9.40`:

- Keep the shipped positive route unchanged: one resolved `reader`, one
  resolved `writer`, one `(writer.payload reader.payload)` pair, and one
  transaction drive call between the source event wait and sink trigger.
- Add focused fail-closed coverage for the source child endpoint side: a
  generated-child actor-to-actor route must prove the source endpoint is a
  scalar output port on the source child.
- Add focused fail-closed coverage for route cardinality: multiple endpoint
  pairs in the ATL route drive body, multiple selected actor data-movement
  drive bodies, or repeated drive calls remain outside the current subset.
- Existing generated-top discovery stays under
  `actor_network.generated_tops[]`; route provenance stays under
  `actor_network.data_movements[]`; no report schema change is selected.
- No route mux, storage, fan-in/fan-out, wider payload, CDC/reset-remap,
  ready/backpressure, trigger-batch, group, recursive-network, or permanent
  grouping behavior is selected.

Implementation outcome for `.9.40`:

- Focused coverage now rejects a generated-child actor-to-actor route when
  the source child omits the scalar output endpoint. The diagnostic names the
  source instance role explicitly.
- Focused coverage now rejects a single ATL route drive body containing more
  than one endpoint pair, a second selected actor data-movement drive body,
  and repeated transaction calls to the same route drive.
- The positive `isf/atl_two_child_data_pipeline.isf` fixture and adjacent
  generated-top, pin-ingress, pin-egress, and parent-handoff data-route
  fixtures remain in the focused regression set.
- No source syntax, public report key, generated artifact shape, mux/storage,
  fan-in/fan-out, CDC/reset-remap, ready/backpressure, payload protocol, or
  permanent actor grouping behavior changed.

Selected hardening for `.9.42`:

- Keep the shipped generated-child actor-to-actor route scalar and one-bit.
- Add focused fail-closed coverage for a source child output endpoint whose
  declared interface width is wider than one bit.
- Add focused fail-closed coverage for a sink child input endpoint whose
  declared interface width is wider than one bit.
- Preserve existing `actor_network.data_movements[]` width metadata
  (`width: 1`, `width_source: scalar_one_bit`) and generated-top discovery
  metadata; no report schema change is selected.
- No packing, truncation, extension, payload protocol, route mux/storage,
  fan-in/fan-out, CDC/reset-remap, ready/backpressure, or permanent actor
  grouping behavior is selected.

Implementation outcome for `.9.42`:

- Focused coverage now rejects a generated-child actor-to-actor route when
  the source child output endpoint is wider than one bit.
- Focused coverage now rejects the same route when the sink child input
  endpoint is wider than one bit.
- No production code change was required: the lowerer already enforced the
  scalar endpoint contract after `.9.40` tightened source-instance wording.
- No source syntax, public report key, generated artifact shape, payload
  packing/truncation/extension, mux/storage, fan-in/fan-out, CDC/reset-remap,
  ready/backpressure, or permanent actor grouping behavior changed.

Selected hardening for `.9.44`:

- Keep the shipped generated-child actor-to-actor route in one parent clock
  and reset policy.
- Add focused fail-closed coverage for a source child clock that differs from
  the parent clock.
- Add focused fail-closed coverage for a sink child clock that differs from
  the parent clock.
- Add focused fail-closed coverage for a source child reset signature that
  differs from the parent reset signature.
- Add focused fail-closed coverage for a sink child reset signature that
  differs from the parent reset signature.
- Preserve the existing generated-top system-port contract: matching
  clock/reset names and policies only, with no CDC bridge, reset remapping,
  storage, mux, ready/backpressure, payload, or report schema change selected.

Implementation outcome for `.9.44`:

- Focused coverage now rejects a generated-child actor-to-actor route when
  the source child clock differs from the parent clock.
- Focused coverage now rejects the same route when the sink child clock
  differs from the parent clock.
- Focused coverage now rejects the same route when the source child reset
  signature differs from the parent reset signature.
- Focused coverage now rejects the same route when the sink child reset
  signature differs from the parent reset signature.
- No production code change was required: the generated-top lowerer already
  enforced parent/child clock and reset policy parity before ATL child
  wiring.
- No source syntax, public report key, generated artifact shape, CDC bridge,
  reset remapping, system-port remapping, route mux/storage, fan-in/fan-out,
  ready/backpressure, payload protocol, recursive actor network, or permanent
  actor grouping behavior changed.

Selected hardening for `.9.46`:

- Keep the shipped generated-child actor-to-actor route between two distinct
  resolved child instances.
- Add focused fail-closed coverage for a drive-body pair whose source and
  sink actor qualifiers name the same resolved child instance.
- Preserve the existing generated-top route contract: no generated-child
  self-route, loopback, child-internal bypass, storage, mux, fan-in/fan-out,
  ready/backpressure, payload protocol, or report schema change is selected.

## Selected ATL Actor Type-Resolution Source Contract

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.17` selected the explicit source contract
for ATL actor type resolution before any generated child artifacts are
emitted; `.9.20` now resolves that source shape as metadata only.

Selected source shape:

```lisp
(actor packet_system
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance reader of pkt_lib.packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (await reader.done)
    (complete done)))
```

Selected contract:

- The enclosing source still has exactly one compile/report `(actor ...)`
  root. There is still no `(network ...)` wrapper.
- A resolved ATL actor type must be qualified as `ALIAS.EXPORT` in
  `(instance NAME of ALIAS.EXPORT)`.
- `ALIAS` must come from the enclosing actor's explicit `(imports (library
  LIBRARY as ALIAS))` clause.
- `EXPORT` must name an actor export from that imported library. Same-source
  `(library ...)` roots and external library files remain the resolver inputs,
  reusing the existing library import model.
- Unqualified `(instance NAME of ACTOR_TYPE)` remains metadata-only external
  intent until a later leaf explicitly changes it. It is not resolved by
  searching sibling actors, local transaction names, package symbols, or the
  filesystem.
- Sibling top-level `(actor ...)` roots remain fail-closed; they are not ATL
  child type definitions for this source contract.
- Existing `(use alias.actor as instance ...)` remains the shipped reusable
  library generated-top path with explicit bindings. ATL `(instance ...)`
  type resolution is a separate actor-network path and does not reuse
  `(use ...)` syntax.

Historical `.9.18` report impact:

- No report schema change is selected for `.9.18`.
- Until a later resolution leaf ships, `actor_network.instances[]` keeps the
  current `name`, `actor_type`, and `declaration` keys.
- A later resolution leaf may add resolved-library provenance keys only after
  the public contract and downstream integration handoff are updated in the
  same slice.

Historical `.9.18` generated artifact expectations:

- `.9.18` emits no generated ATL child `.fsm` and no generated ATL top.
- The eventual generated child naming direction follows the existing reusable
  library convention: specialized child module/file basename
  `<parent_actor>__<instance>`, and a generated top basename
  `<parent_actor>_top` if and only if a later leaf selects actual generated
  ATL composition.
- Parent event, trigger, and scalar data handoff names remain exactly the
  currently shipped external parent-handoff names until child wiring is
  selected.

Selected fail-closed boundaries:

- library-qualified ATL instance types now fail closed with targeted
  diagnostics until the resolution leaf deliberately implements them;
- unqualified actor types do not resolve implicitly;
- sibling actor roots stay rejected;
- generated ATL tops, HDL child wiring, event fan-in,
  trigger ready/backpressure, endpoint route mux/storage, and CDC remain
  deferred.

Verification scope for the next code leaf:

- parser syntax coverage for the qualified `ALIAS.EXPORT` shape;
- negative coverage for missing imports, non-explicit import aliases, unknown
  aliases, and unknown exports when the syntax is reserved;
- preservation coverage for unqualified metadata-only instances;
- preservation coverage for existing `(use alias.actor as instance ...)`
  library generation behavior;
- spec, downstream handoff, public contract, mdBook, and focused-test index
  synchronization.

Shipped `.9.18` / `.9.20` / `.9.22` progression:

- `(instance NAME of ALIAS.EXPORT)` is recognized as the selected future ATL
  library-qualified type syntax.
- Missing imports, non-explicit import aliases, unknown aliases, unknown actor
  exports still fail before scheduled `.fsm` emission with ATL-specific
  diagnostics.
- The `.9.18` reservation leaf also made known actor exports fail closed;
  `.9.20` replaces that known-export failure with metadata resolution, and
  `.9.22` emits the resolved child `.fsm` artifact while still emitting no
  generated ATL top.
- Existing unqualified `(instance NAME of ACTOR_TYPE)` remains metadata-only.
- Existing `(use alias.actor as instance ...)` library generation behavior is
  unchanged.

## Shipped ATL Type-Resolution Metadata Subset

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.19` selected the first behavior-bearing
library-qualified ATL type-resolution slice as metadata-only resolution, and
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.20` ships it.

Selected source shape:

```lisp
(actor packet_system
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance reader of pkt_lib.packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (await reader.done)
    (complete done)))
```

Shipped report impact:

- `actor_network.instances[]` remains the instance metadata owner.
- Resolved library-qualified entries add report-visible provenance keys:
  `type_resolution`, `library`, `alias`, `export`, `module`, and
  `scheduled_fsm`.
- `type_resolution` is `library_actor_export`.
- `library` is the imported library namespace, `alias` is the explicit import
  alias, and `export` is the selected actor export name.
- `module` reserves the deterministic future child module basename
  `<parent_actor>__<instance>`.
- `scheduled_fsm` reserves the deterministic future child file basename
  `<parent_actor>__<instance>.fsm`.
- Unqualified `(instance NAME of ACTOR_TYPE)` entries keep only the current
  `name`, `actor_type`, and `declaration` keys in this first resolution
  subset.

Selected generated artifact expectations:

- `.9.20` emits only the parent scheduled `.fsm`.
- No generated ATL child `.fsm` is placed in `lower(...)->{files}`.
- No generated ATL top is emitted.
- The selected child module/file names are metadata reservations only until a
  later child-emission leaf selects generated artifacts and HDL wiring.

Selected fail-closed boundaries:

- Missing imports, non-explicit/dotted aliases, unknown aliases, and unknown
  actor exports keep the targeted `.9.18` ATL diagnostics.
- Resolved actor types do not infer interface bindings yet.
- Trigger, event, and scalar data handoffs remain external parent handoffs.
- Generated child `.fsm` emission, generated ATL top emission, HDL child
  wiring, actor-event fan-in, trigger ready/backpressure, route mux/storage,
  CDC, recursive actor networks, and permanent actor grouping remain
  deferred.

Shipped verification coverage:

- parser/lowering coverage for accepted same-source and imported-file
  library actor exports;
- schedule JSON coverage for the widened resolved
  `actor_network.instances[]` entry;
- preservation coverage for unqualified metadata-only static instances;
- preservation coverage for existing `(use alias.actor as instance ...)`
  reusable-library behavior;
- public-contract, downstream handoff, ISF spec, mdBook, manifest/audit, and
  focused-test index synchronization.

## Shipped ATL Child Artifact Boundary

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.21` selects the next code slice as
child-artifact emission only. The next implementation leaf is
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.22`, and that implementation is now
shipped.

Selected source shape:

- unchanged from the shipped metadata-resolution subset:
  `(instance NAME of ALIAS.EXPORT)`;
- `ALIAS` must still be an explicit library import alias;
- `EXPORT` must still name an actor export from the resolved same-source or
  external library.

Shipped artifact impact:

- Lowering emits the parent scheduled `.fsm` exactly as it did before child
  artifact emission.
- Lowering now additionally emits one resolved ATL child scheduled `.fsm` per
  resolved static actor instance.
- The child file/module name is the already reported reserved name:
  `<parent_actor>__<instance>.fsm` / `<parent_actor>__<instance>`.
- No generated ATL top is emitted in this slice.
- No parent handoff endpoint is rewired to the child artifact in this slice.
  Trigger, event, and scalar data handoffs remain external parent ports.

Shipped report impact:

- No new schedule-report family is selected.
- `actor_network.instances[]` remains the report owner for resolved ATL
  child artifact metadata through `module` and `scheduled_fsm`.
- Existing `library_uses[]` remains reserved for `(use alias.actor as
  instance ...)` and must not report ATL `(instance ...)` children.

Shipped fail-closed boundaries:

- duplicate generated child basenames must fail closed before emission if a
  resolved ATL instance collides with another resolved ATL instance, a
  generated transaction child, or a reusable-library use;
- unqualified `(instance NAME of ACTOR_TYPE)` remains metadata-only and emits
  no child artifact;
- generated ATL top packaging, HDL child wiring, inferred interface binding,
  event/trigger/data handoff binding, actor-event fan-in, route mux/storage,
  ready/backpressure, CDC, recursive actor networks, and permanent actor
  grouping remain deferred.

Shipped verification coverage:

- parser/lowering coverage for child artifact emission from a same-source
  library export and an external library file;
- no-top/no-wiring assertions for the emitted file set and generated parent;
- conflict coverage for a resolved ATL child name against an existing
  generated transaction child namespace;
- preservation coverage for unqualified metadata-only instances and existing
  `(use alias.actor as instance ...)` reusable-library generated-top behavior;
- schedule-report contract coverage showing the resolved instance metadata is
  still the public discovery surface for emitted ATL child artifacts;
- spec, downstream handoff, public contract, mdBook, task tree, and focused
  test index synchronization.

## Selected ATL Resolved-Child Fixture

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.23` selected the emitted-child fixture,
and `ISF-ACTOR-NETWORK-ORCHESTRATION.9.24` now promotes it as a file-backed
regression for the shipped resolved child artifact boundary.

Shipped file:

- `isf/atl_resolved_child_pipeline.isf`

Shipped source shape:

```lisp
(actor atl_resolved_child_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (transaction run
    (on start)
    (trigger worker.process)
    (await worker.done)
    (complete done)))

(library common.packet
  (exports (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (reset (rst_n async active_low))
    (interface
      (input process_start)
      (output done))
    (transaction process
      (on process_start)
      (complete done))))
```

Shipped artifact and report expectations:

- Lowering emits exactly `atl_resolved_child_pipeline.fsm` and
  `atl_resolved_child_pipeline__worker.fsm`.
- No `atl_resolved_child_pipeline_top.fsm` is emitted.
- The parent artifact keeps external handoff ports `worker_process_start` and
  `worker_done`; the child artifact is not wired to them in this slice.
- Schedule JSON reports resolved `actor_network.instances[]` metadata for
  `worker`, one `transaction_triggers[]` entry, one `event_waits[]` entry,
  and empty `data_movements[]`, `association_schedules[]`, and
  `group_schedules[]`.
- The fixture proves strict CLI schedule JSON parity with the in-process
  report through
  `t/1330-isf-atl-resolved-child-fixture-coverage.t` and records the same
  behavior in the mdBook, live specs, downstream handoff, and public
  contract metadata.

Current non-claims after `.9.26`:

- no generated ATL top beyond the selected one-resolved-child trigger/event
  subset;
- no multi-child HDL wiring;
- no inferred data-route interface binding between generated child artifacts;
- no route mux/storage, actor-event fan-in, CDC, ready/backpressure,
  recursive actor networks, or permanent actor grouping.

## Selected ATL Generated Top Subset

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.26` ships the first generated ATL top for
the resolved-child fixture shape selected by `.9.25`.

Shipped source boundary:

- one top-level `(actor ...)`;
- exactly one resolved library-qualified ATL child instance using
  `(instance NAME of ALIAS.EXPORT)`;
- one accepted parent `(trigger instance.transaction)` handoff to that child;
- one accepted parent `(await instance.event)` handoff from that same child;
- parent and child use the same clock name, reset name, reset kind, and reset
  polarity;
- no ATL data movements, no temporary trigger batches, no static group
  schedules, and no additional resolved children.

Shipped generated artifacts:

- emit the existing parent `<parent>.fsm`;
- emit the existing resolved child `<parent>__<instance>.fsm`;
- emit a new generated ATL top `<parent>_top.fsm`;
- instantiate the parent as `(?fsmc:<parent> <parent>)`;
- instantiate the child as `(?fsmc:<instance> <parent>__<instance>)`;
- wire top-level public pins to the parent as the existing composition-top
  path does;
- wire the parent trigger handoff output
  `<instance>_<transaction>_start` to the resolved child's transaction start
  input discovered from the child transaction's authored `(on START_SIGNAL)`;
- wire the resolved child output named by the parent `(await instance.event)`
  to the parent event handoff input `<instance>_<event>`.

Shipped report impact:

- add `actor_network.generated_tops[]` metadata so downstream
  consumers can discover the generated ATL top without overloading
  `library_uses[]`;
- keep resolved child discovery in `actor_network.instances[]`;
- keep `library_uses[]` reserved for explicit `(use alias.actor as instance
  ...)` reusable-library composition.

Explicit fail-closed boundaries for `.9.26`:

- missing child target transaction;
- target transaction without a scalar `(on ...)` start signal;
- event name that is not a scalar child output port;
- multiple resolved ATL children;
- multiple trigger/event bindings or repeated binding to the same handoff;
- cross-clock or reset-mismatched parent/child pairs;
- ATL data movement, trigger batches, static group scheduling, payloads,
  ready/backpressure, route mux/storage, recursive actor networks, and any
  generated-top name conflict.

## Shipped ATL Generated-Top HDL Promotion

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.27` selected generated-top HDL
reachability as the next bounded ATL implementation leaf, and `.9.28` ships
the focused proof without changing production lowering behavior.

Selected source shape:

- unchanged from the shipped generated-top fixture:
  `isf/atl_resolved_child_pipeline.isf`;
- one top-level actor imports one same-source library actor through an
  explicit alias;
- one resolved `(instance worker of pkt_lib.packet_worker)`;
- one parent `(trigger worker.process)` handoff;
- one parent `(await worker.done)` handoff;
- matching parent/child clock and reset name, kind, and polarity.

Shipped report impact:

- no new schedule-report family is selected;
- `actor_network.generated_tops[]` remains the generated ATL top discovery
  surface;
- `actor_network.instances[]` remains the resolved child discovery surface;
- strict schedule JSON parity must remain unchanged.

Shipped generated artifact and HDL expectations:

- lowering continues to emit exactly the parent, child, and generated top
  `.fsm` artifacts already shipped by `.9.26`;
- plain and strict CLI HDL generation for the fixture must emit
  SystemVerilog containing the generated top module, scheduled parent module,
  and resolved child module;
- the generated top HDL must include the internal link from parent
  `worker_process_start` to child `process_start` and the internal link from
  child `done` to parent `worker_done`;
- no production code change was required because the existing materialized
  generated-top CLI path already emitted the top, parent, and child HDL.

Shipped fail-closed boundaries:

- no additional resolved ATL children;
- no trigger batches or group schedules in generated ATL tops;
- no generated-child data-route coupling;
- no payload, ready/backpressure, route mux/storage, CDC, recursive actor
  networks, interface auto-fanout, or permanent actor grouping;
- no report-schema widening beyond already shipped generated-top metadata.

Shipped verification scope:

- `t/1330-isf-atl-resolved-child-fixture-coverage.t` now checks plain and
  strict HDL generation;
- the regression asserts generated top, parent, and child modules are present
  in the emitted SystemVerilog;
- the regression asserts top-level HDL includes the selected parent/child
  trigger and event links;
- public-contract, fixture-tier, focused spec/book audits, mdBook build,
  broad ISF gate, and `git diff --check` are the completion checks.

## Shipped ATL Resolved-Child Pin-Ingress Top Wiring

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.30` ships scalar top-level input-pin
movement into one resolved child through the generated ATL top. The
implementation leaf is
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.30`.

Shipped source shape:

```lisp
(actor atl_resolved_child_pin_ingress_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input payload)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (drive feed_worker
    (worker.payload pins.payload))
  (transaction run
    (on start)
    (drive feed_worker)
    (trigger worker.process)
    (await worker.done)
    (complete done)))
```

The resolved child actor must expose scalar input ports `process_start` and
`payload`, plus scalar output event port `done`.

Shipped report impact:

- `actor_network.data_movements[]` remains the data-route report owner and
  records kind `scalar_pin_to_actor_handoff`;
- `actor_network.generated_tops[]` remains the generated ATL top discovery
  owner;
- no new report family is selected for `.9.30`;
- the private generated-top data-link plumbing is not exposed as a new public
  schedule-report family;
- public contract docs stay explicit that the route is generated-top wired
  only for this one pin-ingress shape.

Shipped artifact and HDL behavior:

- lowering emits the parent scheduled `.fsm`, resolved child `.fsm`, and
  generated top `.fsm`;
- the parent scheduled `.fsm` keeps the existing top-level input `payload` and
  generated actor sink handoff output `worker_payload`;
- the resolved child scheduled `.fsm` carries generated `+interface` metadata
  for the selected child input `payload` so the downstream `.fsm` frontend
  preserves that authored child input as an HDL module port even when the
  child transaction does not otherwise read it locally;
- the generated top exposes only clock/reset plus the real public pins
  `start`, `payload`, and `done`;
- generated top wiring links top `payload` to the parent `payload`, parent
  `worker_payload` to child `payload`, parent `worker_process_start` to child
  `process_start`, and child `done` to parent `worker_done`;
- plain and strict CLI HDL generation must show the generated top, parent,
  child, and all selected internal links.

Shipped fail-closed boundaries:

- no non-pin source routes, actor-to-actor routes, or multiple data movements
  in this pin-ingress generated ATL top;
- no width mismatch or missing scalar child input port for the data sink;
- no data movement targeting a different instance than the resolved child;
- no data movement in a different transaction than the trigger/event pair;
- no trigger batches, groups, additional resolved children, payload protocol
  handshakes, ready/backpressure, route mux/storage, CDC/reset remapping,
  recursive actor networks, or permanent actor grouping.

Shipped verification scope:

- `isf/atl_resolved_child_pin_ingress_pipeline.isf` is the file-backed
  resolved-child pin-ingress fixture;
- `t/1330-isf-atl-resolved-child-fixture-coverage.t` proves
  parent/child/top `.fsm` artifacts, strict schedule JSON parity, plain and
  strict CLI HDL generation, and fail-closed missing child input coverage;
- ISF spec, downstream handoff, public contract, mdBook, live docs, focused
  test index, and fixture-tier metadata are synchronized in this slice;
- focused ATL tests, public audits, mdBook build, broad ISF gate, and
  `git diff --check` are the completion checks.

## Shipped ATL Resolved-Child Pin-Egress Top Wiring

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.32` ships the inverse generated-child data
movement slice as scalar resolved-child output movement to one top-level
output pin through the generated ATL top.

Selected source shape:

```lisp
(actor atl_resolved_child_pin_egress_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output result)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (drive publish_result
    (pins.result worker.payload))
  (transaction run
    (on start)
    (trigger worker.process)
    (await worker.done)
    (drive publish_result)
    (complete done)))
```

The resolved child actor must expose scalar input port `process_start`, scalar
output event port `done`, and scalar output data port `payload`.

Shipped report impact:

- `actor_network.data_movements[]` remains the data-route report owner and
  records kind `scalar_actor_to_pin_handoff`;
- `actor_network.generated_tops[]` remains the generated ATL top discovery
  owner;
- no new report family is selected for `.9.32`;
- private generated-top data-link plumbing must remain private.

Shipped artifact and HDL behavior:

- lowering emits the parent scheduled `.fsm`, resolved child `.fsm`, and
  generated top `.fsm`;
- `isf/atl_resolved_child_pin_egress_pipeline.isf` is the file-backed
  review fixture;
- `t/1330-isf-atl-resolved-child-fixture-coverage.t` proves strict schedule
  JSON parity, parent/child/top artifacts, plain HDL generation, strict HDL
  generation, missing child output diagnostics, and pre-event drive-order
  diagnostics;
- the parent scheduled `.fsm` keeps the real top-level output `result` and
  generated actor source handoff input `worker_payload`;
- the resolved child scheduled `.fsm` must preserve the selected scalar
  output port `payload` as an HDL module output;
- the generated top exposes only clock/reset plus the real public pins
  `start`, `result`, and `done`;
- generated top wiring links child `payload` to parent `worker_payload`,
  parent `result` to top `result`, parent `worker_process_start` to child
  `process_start`, and child `done` to parent `worker_done`;
- the selected drive call occurs after the child event wait so the first
  subset does not claim speculative pre-event publication;
- plain and strict CLI HDL generation must show the generated top, parent,
  child, and all selected internal links.

Shipped fail-closed boundaries:

- no non-pin sink routes, pin-source routes, actor-to-actor routes, or
  multiple data movements in the generated ATL top;
- no width mismatch or missing scalar child output port for the data source;
- no data movement targeting a different instance than the resolved child;
- no data movement in a different transaction than the trigger/event pair;
- no drive call before the child event wait in this first pin-egress top
  subset;
- no trigger batches, groups, additional resolved children, payload protocol
  handshakes, ready/backpressure, route mux/storage, CDC/reset remapping,
  recursive actor networks, or permanent actor grouping.

Shipped verification scope:

- parser/lowerer/composition-top syntax checks;
- focused ATL generated-top tests plus adjacent static and scalar pin-egress
  fixture tests;
- schedule JSON CLI parity for
  `isf/atl_resolved_child_pin_egress_pipeline.isf`;
- public audits, mdBook build, broad ISF gate, and `git diff --check`.

## Shipped ATL Generated-Child Actor-To-Actor Route Boundary

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.34` ships negative coverage for the
reserved generated-child actor-to-actor data-route shape. The positive feature
is intentionally still deferred because it needs multi-child ATL top
scheduling, multiple resolved child instances in one generated top, and
ordered trigger/data/event coupling.

Selected reserved source shape:

```lisp
(actor atl_resolved_child_data_route_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance reader of pkt_lib.packet_reader)
  (instance writer of pkt_lib.packet_writer)
  (drive feed_writer
    (writer.payload reader.payload))
  (transaction run
    (on start)
    (trigger reader.capture)
    (await reader.done)
    (drive feed_writer)
    (trigger writer.consume)
    (await writer.done)
    (complete done)))
```

Shipped `.9.34` behavior:

- rejects this generated-child actor-to-actor route with the targeted ATL
  diagnostic `generated-child actor-to-actor data movement drive
  'feed_writer' cannot be combined with actor trigger/event handoffs in the
  current subset; multi-child ATL top scheduling remains deferred`;
- keep existing shipped parent-handoff actor-to-actor routes accepted when
  they do not request resolved generated-child trigger/event coupling;
- keep existing one-child generated-top trigger/event, pin-ingress, and
  pin-egress fixtures accepted;
- makes no public report-schema, generated-top schema, storage, route mux,
  ready/backpressure, CDC/reset remap, recursive-network, or permanent-group
  claim.

Shipped `.9.34` verification scope:

- parser/lowerer syntax checks for the touched boundary;
- focused ATL static and resolved-child fixture tests proving the new
  fail-closed diagnostic and preserving the shipped positive fixtures;
- public docs/audits, mdBook build, and `git diff --check`.

## Shipped ATL Two-Child Trigger/Event Top

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.36` ships the first positive
multi-child generated-top behavior before actor-to-actor data movement:
sequential trigger/event handoffs for two resolved children in one generated
ATL top, with no data route yet.

Selected source shape:

```lisp
(actor atl_two_child_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (imports
    (library common.packet as pkt_lib))
  (instance reader of pkt_lib.packet_reader)
  (instance writer of pkt_lib.packet_writer)
  (transaction run
    (on start)
    (trigger reader.capture)
    (await reader.done)
    (trigger writer.emit)
    (await writer.done)
    (complete done)))
```

Shipped `.9.36` behavior:

- `isf/atl_two_child_pipeline.isf` emits
  `atl_two_child_pipeline.fsm`, `atl_two_child_pipeline__reader.fsm`,
  `atl_two_child_pipeline__writer.fsm`, and
  `atl_two_child_pipeline_top.fsm`;
- the generated top instantiates the parent, `reader`, and `writer`;
- the generated top wires `reader_capture_start` to
  `reader.capture_start`, `reader.done` to `reader_done`,
  `writer_emit_start` to `writer.emit_start`, and `writer.done` to
  `writer_done`;
- schedule JSON keeps resolved child evidence in
  `actor_network.instances[]`, trigger evidence in
  `actor_network.transaction_triggers[]`, event evidence in
  `actor_network.event_waits[]`, and one generated-top discovery entry in
  `actor_network.generated_tops[]`;
- the multi-child generated-top entry uses `children[]` child wiring records,
  and the public contract advertises the multi-child top entry through
  `schedule_report_actor_network_generated_top_multi_child_keys` and each
  child record through
  `schedule_report_actor_network_generated_top_child_keys`;
- this adds no data movement, public route schema, route mux/storage,
  ready/backpressure, CDC, recursive-network, or permanent-group behavior.

Shipped `.9.36` verification scope:

- parser/lowerer/composition-top syntax checks;
- focused resolved-child ATL tests proving parent/child/top artifacts,
  generated-top wiring, strict schedule JSON parity, and plain/strict HDL
  generation for the two-child shape;
- adjacent one-child generated-top and data-route fixtures must remain green;
- public docs/audits, mdBook build, broad ISF gate, and `git diff --check`.

## Shipped ATL Association Report Vocabulary

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.2` ships the report vocabulary cleanup
selected by `.9.1`. This is intentionally a report contract slice, not a new
source syntax slice: users still write contiguous transaction-body
`(trigger actor.transaction)` clauses to distinct static actor instances.

Implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2`

Selected source shape:

- unchanged from the shipped temporary trigger-batch surface;
- no `(network ...)`;
- no required `(group ...)`;
- no `connect`, `transfer`, or `move` syntax.

Shipped report contract:

- `actor_network.association_schedules[]` is the canonical report family
  for task-scoped ATL associations.
- Keep `actor_network.group_schedules[]` as a schema-version-1 compatibility
  view for current downstream consumers.
- The first `association_schedules[]` entries cover the same-cycle external
  trigger batch and include:
  `association`, `kind`, `lifetime`, `owner_transaction`, `context`,
  `members`, `target_transactions`, `signals`, `schedule`,
  `dependency_policy`, `storage`, `source`, and `sink`.
- `kind` is `temporary_trigger_batch` for this first slice.
- `lifetime` is `task_scoped`.
- The association name is transaction-scoped, for example
  `run_trigger_batch`, even when the selected actors also match a static
  report-only group.

Verification scope:

- parser/lowerer/emitter/public-contract syntax checks;
- focused ATL fixture tests for the shipped trigger batch;
- public schedule-report key-family and metadata audits;
- strict CLI schedule JSON parity;
- mdBook build and diff check;
- broad ISF gate when the public report contract changes.

Explicit non-claims:

- no source syntax change;
- no generated ATL child `.fsm`;
- no generated ATL top;
- no peer event or endpoint data-movement coupling;
- no route mux/storage insertion;
- no CDC, payload, ready/backpressure, broader fan-in/fan-out, or permanent
  actor grouping behavior.

## Shipped ATL Data-Route Fixture

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.3` selected the next fixture leaf as a
data-movement fixture rather than another trigger-batch fixture, and
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.4` promoted that fixture. The goal is to
keep moving toward the user's ATL data/information movement model while
staying inside already shipped scalar actor-to-actor handoff semantics.

Implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4`

Shipped file:

- `isf/atl_data_route_pipeline.isf`

Selected source shape:

```lisp
(actor atl_data_route_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
```

Shipped coverage:

- one scheduled parent artifact: `atl_data_route_pipeline.fsm`;
- generated parent handoff ports: `producer_payload` and `consumer_payload`;
- one `actor_network.data_movements[]` route with `route_lifetime:
  drive_call_cycle` and `storage: none`;
- empty `actor_network.association_schedules[]` and `group_schedules[]`
  because this route is drive-activated, not a trigger-batch association;
- strict schedule JSON parity plus plain and strict HDL reachability in
  `t/1325-isf-atl-data-route-fixture-coverage.t`.

Selected report evidence:

- `actor_network.instances[]` contains `producer` and `consumer`.
- `actor_network.data_movements[]` contains one `scalar_actor_handoff` route
  from `producer.payload` to `consumer.payload`.
- The generated parent handoff signals are `producer_payload` and
  `consumer_payload`.
- `route_lifetime` is `drive_call_cycle`; `storage` is `none`.
- `actor_network.association_schedules[]` and `group_schedules[]` remain
  empty because this fixture uses a drive-activated data route, not a
  trigger-batch association.

Explicit non-claims:

- no generated ATL child `.fsm`;
- no generated ATL top;
- no route mux or inserted storage;
- no peer events, trigger/data coupling, fan-in/fan-out, wider payloads, CDC,
  ready/backpressure, compact aliases, or permanent actor grouping.

## Shipped ATL Pin-Ingress Fixture

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.5` selected the next fixture leaf as a
network-boundary data movement fixture, and
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.6` promoted that fixture. The goal is to
demonstrate movement from a top-level actor pin into an actor in the network
while staying inside the already shipped scalar pin-to-actor handoff subset.

Implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.6`

Shipped file:

- `isf/atl_pin_ingress_pipeline.isf`

Shipped source shape:

```lisp
(actor atl_pin_ingress_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input payload)
    (output done))
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload pins.payload))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
```

Shipped coverage:

- one scheduled parent artifact: `atl_pin_ingress_pipeline.fsm`;
- existing top-level input source pin: `payload`;
- generated actor handoff output: `consumer_payload`;
- one `actor_network.data_movements[]` route with kind
  `scalar_pin_to_actor_handoff`, `source: top_level_pin`, `sink:
  external_handoff`, `route_lifetime: drive_call_cycle`, and `storage: none`;
- empty `actor_network.association_schedules[]` and `group_schedules[]`
  because this route is drive-activated, not a trigger-batch association;
- strict schedule JSON parity plus plain and strict HDL reachability.

Shipped report evidence:

- `actor_network.instances[]` contains `consumer`.
- `actor_network.data_movements[]` contains one
  `scalar_pin_to_actor_handoff` route from `pins.payload` to
  `consumer.payload`.
- The source signal remains the authored top-level input pin `payload`.
- The generated actor handoff output is `consumer_payload`.
- `route_lifetime` is `drive_call_cycle`; `storage` is `none`.
- `actor_network.association_schedules[]` and `group_schedules[]` remain
  empty because this fixture uses a drive-activated data route, not a
  trigger-batch association.

Explicit non-claims:

- no generated ATL child `.fsm`;
- no generated ATL top;
- no actor-to-pin egress or bidirectional pin movement in this fixture;
- no route mux/storage, peer event, trigger/data coupling, wider payload,
  fan-in/fan-out, CDC, ready/backpressure, compact alias, or permanent actor
  grouping behavior.

## Shipped ATL Pin-Egress Fixture

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.7` selected the next fixture leaf as the
inverse network-boundary movement fixture, and
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.8` promoted that fixture. The goal is to
demonstrate movement from an actor in the network to a top-level actor output
pin while staying inside the already shipped scalar actor-to-pin handoff
subset.

Implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.8`

Shipped file:

- `isf/atl_pin_egress_pipeline.isf`

Shipped source shape:

```lisp
(actor atl_pin_egress_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output result)
    (output done))
  (instance producer of packet_reader)
  (drive publish_result
    (pins.result producer.payload))
  (transaction run
    (on start)
    (drive publish_result)
    (complete done)))
```

Shipped coverage:

- one scheduled parent artifact: `atl_pin_egress_pipeline.fsm`;
- generated actor source handoff input: `producer_payload`;
- existing top-level output sink pin: `result`;
- one `actor_network.data_movements[]` route with kind
  `scalar_actor_to_pin_handoff`, `source: external_handoff`, `sink:
  top_level_pin`, `route_lifetime: drive_call_cycle`, and `storage: none`;
- empty `actor_network.association_schedules[]` and `group_schedules[]`
  because this route is drive-activated, not a trigger-batch association;
- strict schedule JSON parity plus plain and strict HDL reachability.

Shipped report evidence:

- `actor_network.instances[]` contains `producer`.
- `actor_network.data_movements[]` contains one
  `scalar_actor_to_pin_handoff` route from `producer.payload` to
  `pins.result`.
- The generated actor source handoff input is `producer_payload`.
- The sink signal remains the authored top-level output pin `result`.
- `route_lifetime` is `drive_call_cycle`; `storage` is `none`.
- `actor_network.association_schedules[]` and `group_schedules[]` remain
  empty because this fixture uses a drive-activated data route, not a
  trigger-batch association.

Explicit non-claims:

- no generated ATL child `.fsm`;
- no generated ATL top;
- no bidirectional pin movement in this fixture;
- no route mux/storage, peer event, trigger/data coupling, wider payload,
  fan-in/fan-out, CDC, ready/backpressure, compact alias, or permanent actor
  grouping behavior.

## Shipped ATL Trigger-Wait Fixture

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.9` selected the next fixture leaf as the
smallest actor orchestration round trip, and
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.10` promoted that fixture. A top-level
actor emits one one-cycle trigger handoff to a static actor instance, then
waits for one event handoff from that same instance before completing. This
is intentionally a parent-handoff fixture, not generated child wiring.

Implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.10`

Shipped file:

- `isf/atl_trigger_wait_pipeline.isf`

Shipped source shape:

```lisp
(actor atl_trigger_wait_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (instance worker of packet_worker)
  (transaction run
    (on start)
    (trigger worker.process)
    (await worker.done)
    (complete done)))
```

Shipped coverage:

- one scheduled parent artifact: `atl_trigger_wait_pipeline.fsm`;
- generated trigger handoff output: `worker_process_start`;
- generated event handoff input: `worker_done`;
- one `actor_network.transaction_triggers[]` entry for `worker.process`;
- one `actor_network.event_waits[]` entry for `worker.done`;
- empty `actor_network.association_schedules[]`, `group_schedules[]`,
  `groups[]`, and `data_movements[]` because this fixture is a single-actor
  trigger/event round trip, not a temporary trigger batch or data route;
- strict schedule JSON parity, scheduled `.fsm` structure including the
  default await timeout state, plus plain and strict HDL reachability.

Explicit non-claims:

- no temporary trigger-batch plus event coupling;
- no multiple waits or multiple triggers;
- no generated ATL child `.fsm`;
- no generated ATL top;
- no actor type resolution or HDL child wiring;
- no event payload, endpoint data movement coupling, route mux/storage,
  fan-in/fan-out, CDC, ready/backpressure, compact alias, or permanent actor
  grouping behavior.

## Shipped ATL Trigger-Batch Wait Fixture

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.11` selected the next fixture leaf as the
first coupling between a task-scoped temporary trigger batch and one actor
event wait, and `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12` promoted that fixture.
A top-level actor emits one same-cycle trigger batch to distinct static actor
instances, then waits for one event handoff from one triggered actor before
completing. This is still parent-handoff orchestration only.

Implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12`

Shipped file:

- `isf/atl_trigger_batch_wait_pipeline.isf`

Shipped source shape:

```lisp
(actor atl_trigger_batch_wait_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (instance filter of packet_filter)
  (instance writer of packet_writer)
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger filter.process)
    (trigger writer.emit)
    (await writer.done)
    (complete done)))
```

Shipped coverage:

- one scheduled parent artifact: `atl_trigger_batch_wait_pipeline.fsm`;
- generated trigger handoff outputs: `reader_capture_start`,
  `filter_process_start`, and `writer_emit_start`;
- generated event handoff input: `writer_done`;
- per-target `actor_network.transaction_triggers[]` entries;
- one canonical `actor_network.association_schedules[]` entry with kind
  `temporary_trigger_batch`;
- one schema-version-1 compatibility `actor_network.group_schedules[]` entry;
- one `actor_network.event_waits[]` entry for `writer.done`;
- empty `actor_network.groups[]` and `data_movements[]`;
- strict schedule JSON parity, scheduled `.fsm` structure including the
  default await timeout state, plus plain and strict HDL reachability.

Explicit non-claims:

- no multiple event waits or actor-event fan-in;
- no generated ATL child `.fsm`;
- no generated ATL top;
- no actor type resolution or HDL child wiring;
- no event payload, endpoint data movement coupling, route mux/storage, CDC,
  ready/backpressure, compact alias, or permanent actor grouping behavior.

## Shipped ATL Multi-Event Fan-In Boundary Coverage

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.13` selected the next slice as negative
coverage for the multi-event fan-in boundary left explicit by `.9.12`, and
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.14` shipped that proof. A parent may not
yet wait on multiple actor events after one temporary trigger batch.

Implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.14`

Rejected source shape:

```lisp
(actor atl_trigger_batch_multi_wait_boundary
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (instance filter of packet_filter)
  (instance writer of packet_writer)
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger filter.process)
    (trigger writer.emit)
    (await reader.done)
    (await writer.done)
    (complete done)))
```

Shipped behavior:

- parsing fails before scheduled `.fsm` emission;
- the diagnostic names the current one-event-wait subset;
- no new source syntax, report keys, generated artifacts, HDL child wiring,
  route mux/storage, CDC, or permanent actor grouping behavior is claimed.
- coverage lives in `t/1322-isf-actor-network-static.t`.

## Shipped ATL Actor-Root Boundary

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.15` selects a source-root safety boundary
before generated ATL child artifacts or actor type resolution, and
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.16` ships it. Current ISF compiles one
entry actor. A sibling top-level actor root is not silently treated as an
inline type definition for `(instance NAME of ACTOR_TYPE)`.

Implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.16`

Rejected source shape:

```lisp
(actor atl_parent
  (clock clk)
  (interface
    (input start)
    (output done))
  (instance worker of packet_worker)
  (transaction run
    (on start)
    (trigger worker.process)
    (complete done)))

(actor packet_worker
  (clock clk)
  (interface
    (input process_start)
    (output done))
  (transaction process
    (on process_start)
    (complete done)))
```

Shipped behavior:

- parsing fails with a targeted multiple-actor-root diagnostic;
- one actor root plus `(library ...)` roots remains accepted;
- no generated ATL child `.fsm`, generated ATL top, actor type resolution,
  HDL child wiring, route mux/storage, or source lookup behavior is claimed.
- coverage lives in `t/1322-isf-actor-network-static.t`.

## Selected First ATL Fixture

`ISF-ACTOR-NETWORK-ORCHESTRATION.8.2` pivots the first realistic ATL fixture
to a bounded temporary trigger-batch orchestration example, not as a claim for
full actor-network execution. The pivot follows the clarified requirement
that actor associations may form for a task and dissolve when the scheduled
work is done; they must not be modeled as permanent groups by default.

Selected file:

- `isf/atl_trigger_batch_pipeline.isf`

Selected source shape:

```lisp
(actor atl_trigger_batch_pipeline
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (instance filter of packet_filter)
  (instance writer of packet_writer)
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger filter.process)
    (trigger writer.emit)
    (complete done)))
```

Selected shipped ATL surfaces:

- direct actor-body static instances;
- same-cycle external trigger-batch scheduling from a contiguous
  transaction-body trigger batch to distinct actor instances.

Selected generated artifact contract:

- Lowering emits `atl_trigger_batch_pipeline.fsm` only.
- The scheduled parent exposes `reader_capture_start`,
  `filter_process_start`, and `writer_emit_start` as generated trigger
  outputs.
- No child `.fsm`, generated ATL top, child instance, route mux, internal
  handoff storage, or HDL child wiring is selected by this fixture.

Selected report evidence:

- `actor_network.instances[]` contains `reader`, `filter`, and `writer`.
- `actor_network.groups[]` is empty because the fixture does not declare a
  permanent static group.
- `actor_network.transaction_triggers[]` contains the three per-target
  external trigger handoffs.
- `actor_network.group_schedules[]` contains one
  `same_cycle_external_trigger_batch` entry named `run_trigger_batch` with
  the same members, target transactions, generated signals,
  `storage: "none"`, and `sink: "external_handoff"`.
- `actor_network.event_waits[]` and `actor_network.data_movements[]` remain
  empty.

Selected `.8.2` checks:

- in-process scheduled `.fsm` structure;
- strict CLI `--emit-schedule-json` parity with the in-process report;
- plain HDL generation;
- strict HDL generation;
- book/live-doc synchronization.

Explicit non-claims:

- no peer event synchronization in the fixture;
- no endpoint data movement in the fixture;
- no generated ATL child `.fsm` artifacts;
- no generated ATL top;
- no permanent `(group ...)` association, group endpoints, or compact
  `(concurrent ...)` aliases;
- no CDC, payloads, ready/backpressure, storage, muxing, fan-in/fan-out, or
  coupling between trigger batches and event waits or data movement.

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
  waits, nested waits, payloads, cross-clock actor events, generated ATL
  child `.fsm` files, generated ATL tops, and HDL event wiring deferred or
  fail-closed.
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
- The first `.5` data-movement implementation sequence starts
  with shipped fail-closed reservation, not generated routing. Qualified actor
  endpoint drive-body pairs such as `(consumer.payload producer.payload)` or
  `(consumer.payload local_value)` can look like local dotted aggregate or
  enum names; `.5.2` rejects endpoints that name declared static actor
  instances with ATL-specific data-movement diagnostics before later leaves
  widen instance counts, generate handoff storage, or emit route artifacts.
- The shipped first generated scalar actor-to-actor handoff subset is one
  named drive body with exactly one `(sink_actor.endpoint source_actor.endpoint)`
  pair, exactly two direct static actor instances, and one top-level
  transaction drive call. The generated parent `.fsm` exposes a scalar
  external source handoff input named `source_actor_source_endpoint` and a
  scalar external sink handoff output named `sink_actor_sink_endpoint`; the
  route is active only for the drive-call cycle, inserts no storage or mux,
  and reports through `actor_network.data_movements[]`.
- The shipped first top-level pin movement subset is one named drive body
  with exactly one `(actor.endpoint pins.input_pin)` pair, exactly one direct
  static actor instance, and one top-level transaction drive call. The source
  is the existing one-bit top-level input pin; the sink is a generated scalar
  external actor handoff output named `actor_endpoint`. It reports through
  `actor_network.data_movements[]` with kind
  `scalar_pin_to_actor_handoff`.
- The shipped inverse top-level pin movement subset is one named drive body
  with exactly one `(pins.output_pin actor.endpoint)` pair, exactly one direct
  static actor instance, and one top-level transaction drive call. The source
  is a generated scalar external actor handoff input named `actor_endpoint`;
  the sink is the existing one-bit top-level output pin. It reports through
  `actor_network.data_movements[]` with kind
  `scalar_actor_to_pin_handoff`. Wider pins, storage/muxing, generated
  children, group scheduling, and CDC remain deferred.
- The shipped first group scheduling behavior is a same-cycle external
  trigger batch: a contiguous run of top-level transaction-body
  `(trigger actor.transaction)` clauses may target every member of one
  declared static group exactly once. The lowering pulses every generated
  parent trigger output from one scheduled state and reports inferred
  independence through `actor_network.group_schedules[]`; it still emits no
  generated children, group endpoints, route mux/storage, event/data coupling,
  CDC, or compact `(concurrent ...)` aliases.

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
- `2026-05-18`: Selected the first group scheduling behavior before code.
  `.7.5` lowers only a same-cycle external trigger batch: consecutive
  top-level transaction-body qualified triggers to every member of one
  declared static group exactly once. The declaration remains metadata; the
  schedule evidence appears in `actor_network.group_schedules[]`.
- `2026-05-18`: Decomposed the `.8` realistic-fixture frontier before code
  into `.8.1` fixture selection and `.8.2` fixture promotion. This prevents a
  broad fixture task from mixing source selection, regression coverage, and
  documentation into one oversized implementation slice.
- `2026-05-18`: Selected the first realistic ATL fixture before code. The
  `.8.2` fixture will be `isf/atl_group_trigger_pipeline.isf`, using three
  direct static actor instances, one verbose static group, and one exact
  same-cycle external group-trigger batch. It will prove the shipped group
  orchestration surface through scheduled `.fsm`, strict schedule JSON, and
  HDL reachability without claiming event synchronization, endpoint data
  movement, generated ATL children, generated ATL tops, or route mux/storage.
- `2026-05-19`: Pivoted `.8.2` after the temporary-association clarification:
  actor associations can form for a task and dissolve when done, so the first
  realistic ATL fixture is now `isf/atl_trigger_batch_pipeline.isf` with no
  permanent `(group ...)` declaration. The contiguous trigger batch itself is
  the scheduled temporary association.
- `2026-05-19`: Selected `.9.2` as an additive schedule-report vocabulary
  cleanup. Task-scoped ATL associations should have canonical
  `actor_network.association_schedules[]` entries; the existing
  `actor_network.group_schedules[]` key remains a schema-version-1
  compatibility view until a later schema migration removes or narrows it.
- `2026-05-19`: Selected `.9.4` as a realistic scalar data-route fixture
  using the already shipped actor-to-actor data movement source shape:
  `(consumer.payload producer.payload)` inside a named drive body activated by
  one top-level transaction drive call.
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
- Which later fixture should combine peer event synchronization, endpoint data
  movement, and generated ATL child artifacts once those ATL combinations are
  shipped?

## Blockers

- No blocker for active `.9.46`. It must add only the selected distinct
  source/sink child hardening coverage around the shipped generated-child
  actor-to-actor route and must not widen loopback, storage, mux, or bypass
  behavior.

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
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `qualified actor endpoint sink/source drive-body forms fail closed with ATL diagnostics; focused checks pass; broad ISF gate passes with Files=229, Tests=1348` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.5.3` | `mdbook build docs/book`; `git diff --check` | `selected the first scalar actor-to-actor handoff subset, generated parent port names, one-bit width evidence, one-cycle lifetime, report keys, and fail-closed boundaries before code` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.5.4` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1305-isf-book-feature-matrix-audit.t t/1250-isf-spec-focused-test-index-audit.t`; `prove -Iperl t/1193-isf-drive-call-arity-boundary.t t/1194-isf-drive-body-boundary.t t/1198-isf-update-clause-boundary.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `selected scalar actor-to-actor handoff lowers to one-cycle parent source/sink ports and actor_network.data_movements[] metadata; focused checks pass; broad ISF gate passes with Files=229, Tests=1349` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.6.1` | `mdbook build docs/book`; `git diff --check` | `selected the first scalar top-level input pin to actor handoff subset before code` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.6.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1193-isf-drive-call-arity-boundary.t t/1194-isf-drive-body-boundary.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `selected scalar top-level input pin to actor handoff lowers to one-cycle parent input-to-actor-output route and data_movements[] metadata; broad ISF gate passes with Files=229, Tests=1350` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.6.3` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected the first scalar actor endpoint to top-level output pin handoff subset before code` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.6.4` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1193-isf-drive-call-arity-boundary.t t/1194-isf-drive-body-boundary.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `selected scalar actor endpoint to top-level output pin handoff lowers to one-cycle parent input-to-pin route and data_movements[] metadata; broad ISF gate passes with Files=229, Tests=1351` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.7.1` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `decomposed concurrent actor groups and selected targeted fail-closed group diagnostics as the next code leaf` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.7.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `reserved group declarations and compact aliases fail closed with ATL diagnostics; broad ISF gate passes with Files=229, Tests=1351` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.7.3` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `direct static concurrent groups report actor_network.groups[] metadata without scheduling behavior; broad ISF gate passes with Files=229, Tests=1352` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.7.4` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected same-cycle external group trigger batches and actor_network.group_schedules[] report evidence before code` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.7.5` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `selected same-cycle group trigger batch lowers to one parent state and actor_network.group_schedules[] metadata; broad ISF gate passes with Files=229, Tests=1353` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.8` | `mdbook build docs/book`; `git diff --check` | `decomposed realistic multi-actor fixture promotion into selection and fixture leaves before code` |
| `2026-05-18` | `ISF-ACTOR-NETWORK-ORCHESTRATION.8.1` | `mdbook build docs/book`; `git diff --check` | `selected isf/atl_group_trigger_pipeline.isf as the first realistic ATL fixture before code` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.8.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1324-isf-atl-fixture-coverage.t t/1322-isf-actor-network-static.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `temporary trigger-batch fixture promoted without permanent group membership; broad ISF gate passes with Files=230, Tests=1357` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.1` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected additive actor_network.association_schedules[] report metadata for task-scoped ATL associations while preserving group_schedules[] compatibility` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `prove -Iperl t/1322-isf-actor-network-static.t t/1324-isf-atl-fixture-coverage.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_trigger_batch_pipeline.isf`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `canonical actor_network.association_schedules[] report metadata shipped for temporary trigger batches while group_schedules[] remains a compatibility view` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.3` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected a realistic scalar actor-to-actor data-route fixture before source/test implementation` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1325-isf-atl-data-route-fixture-coverage.t`; `prove -Iperl t/1325-isf-atl-data-route-fixture-coverage.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_data_route_pipeline.isf`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `realistic scalar actor-to-actor data-route fixture promoted; strict schedule JSON plus HDL coverage prove generated parent handoff ports and data_movements[] metadata; broad ISF gate passes with Files=231, Tests=1360` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.5` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected a top-level input-pin to actor ingress fixture before source/test implementation` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.6` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1326-isf-atl-pin-ingress-fixture-coverage.t`; `prove -Iperl t/1326-isf-atl-pin-ingress-fixture-coverage.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_pin_ingress_pipeline.isf`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `realistic scalar pin-ingress fixture promoted; strict schedule JSON plus HDL coverage prove top-level pin source and scalar_pin_to_actor_handoff metadata; broad ISF gate passes with Files=232, Tests=1363` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.7` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected a scalar actor-to-top-level output pin egress fixture before source/test implementation` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.8` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1327-isf-atl-pin-egress-fixture-coverage.t`; `prove -Iperl t/1327-isf-atl-pin-egress-fixture-coverage.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_pin_egress_pipeline.isf`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `realistic scalar pin-egress fixture promoted; strict schedule JSON plus HDL coverage prove generated actor source handoff and scalar_actor_to_pin_handoff metadata; broad ISF gate passes with Files=233, Tests=1366` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.9` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected a single-actor trigger/event wait fixture to prove parent orchestration handoffs before generated ATL child artifacts or broader trigger-batch/event coupling` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.10` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1328-isf-atl-trigger-wait-fixture-coverage.t`; `prove -Iperl t/1328-isf-atl-trigger-wait-fixture-coverage.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_trigger_wait_pipeline.isf`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `realistic single-actor trigger-wait fixture promoted; strict schedule JSON plus HDL coverage prove generated trigger/event handoffs and parent orchestration metadata; broad ISF gate passes with Files=234, Tests=1369` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.11` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected a temporary trigger-batch plus single actor-event wait fixture before source/test implementation` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t`; `prove -Iperl t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_trigger_batch_wait_pipeline.isf`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `realistic trigger-batch wait fixture promoted; strict schedule JSON plus HDL coverage prove temporary association metadata, compatibility schedule metadata, and one event wait; broad ISF gate passes with Files=235, Tests=1372` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.13` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected negative coverage for the deferred multi-event fan-in boundary after trigger-batch/event wait coupling` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.14` | `perl -Iperl -c t/1322-isf-actor-network-static.t`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book (Files=235, Tests=1372)`; `git diff --check` | `proved one temporary trigger batch followed by two actor event waits remains fail-closed with the one-event-wait diagnostic` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.15` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected multiple actor-root fail-closed coverage before ATL actor type resolution or generated child artifacts` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.16` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c t/1322-isf-actor-network-static.t`; `prove -Iperl t/1322-isf-actor-network-static.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book (Files=235, Tests=1373)`; `git diff --check` | `multiple top-level actor roots now fail closed before ATL type resolution while one actor plus library roots remains accepted` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.17` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected library-qualified (instance NAME of ALIAS.EXPORT) as the ATL actor type-resolution source contract before generated child artifacts` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.18` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c t/1322-isf-actor-network-static.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1230-isf-library-import-resolution.t t/1231-isf-library-generated-top.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book (Files=235, Tests=1374)`; `git diff --check` | `reserved library-qualified ATL type syntax with targeted diagnostics before child resolution` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.19` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected metadata-only ATL type resolution as the next source-resolution slice` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.20` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1322-isf-actor-network-static.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1230-isf-library-import-resolution.t t/1231-isf-library-generated-top.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `resolved library-qualified ATL instances to report-visible metadata and reserved child artifact names without child emission` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.21` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected resolved ATL child scheduled artifact emission without generated top packaging` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.22` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1322-isf-actor-network-static.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1230-isf-library-import-resolution.t t/1231-isf-library-generated-top.t`; `prove -Iperl t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `emitted resolved ATL child scheduled artifacts while keeping parent handoffs external and emitting no ATL top` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.23` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected a realistic resolved-child artifact fixture before generated-top or interface-binding work` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.24` | `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1139-isf-public-lower-result-metadata-audit.t`; `perl -Iperl -c t/1142-isf-public-guidance-metadata-audit.t`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t t/1183-ci-regression-tier-selection.t`; `prove -Iperl t/1139-isf-public-lower-result-metadata-audit.t t/1142-isf-public-guidance-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book (Files=236, Tests=1376)`; `git diff --check` | `promoted the resolved-child fixture with parent plus child .fsm coverage, strict schedule JSON parity, and no generated ATL top` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.25` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected the first generated ATL top subset for one resolved child and existing parent trigger/event handoffs before code` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.26` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `emitted the first generated ATL top for one resolved child and one parent trigger/event handoff pair` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.27` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected generated-top HDL promotion for the resolved-child fixture` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.28` | `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `promoted plain and strict CLI HDL coverage for the resolved-child generated-top fixture` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.29` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t`; `git diff --check` | `selected one scalar top-level input-pin route into one resolved child through the generated ATL top` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.30` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`; `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book`; `git diff --check` | `wired one scalar top-level input-pin route into one resolved child through the generated ATL top; broad ISF gate passes with Files=236, Tests=1383` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.31` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `git diff --check` | `selected one scalar resolved-child output route to one top-level output pin through the generated ATL top before implementation` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.32` | `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/Parser.pm`; `perl -Iperl -c perl/FSM/Adapter/FSMGenFull/SignalAnalyzer.pm`; `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/FSM.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_resolved_child_pin_egress_pipeline.isf`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` (Files=236, Tests=1387); `git diff --check` | `wired one scalar resolved-child output route to one top-level output pin through the generated ATL top` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.33` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `git diff --check` | `selected fail-closed coverage for generated-child actor-to-actor data movement before multi-child ATL top scheduling is widened` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.34` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` (Files=236, Tests=1387); `git diff --check` | `reserved generated-child actor-to-actor data movement now fails closed with a targeted multi-child ATL top diagnostic` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.35` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `git diff --check` | `selected the first positive two-child generated-top slice with sequential trigger/event handoffs and no data movement` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.36` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/JSON.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_two_child_pipeline.isf`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` (Files=236, Tests=1391); `git diff --check` | `shipped one generated ATL top wiring two resolved children through sequential trigger/event handoffs with no data movement` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.37` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `git diff --check` | `selected one scalar generated-child actor-to-actor route through the two-child generated ATL top` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.38` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `perl -Iperl -c perl/FSM/Support/ISFPublicInterfaceContract.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `./bin/fsmgen --strict --quiet --emit-schedule-json isf/atl_two_child_data_pipeline.isf`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1305-isf-book-feature-matrix-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` (Files=236, Tests=1395); `git diff --check` | `shipped one scalar generated-child actor-to-actor route through the two-child generated ATL top` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.39` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `git diff --check` | `selected source-side child port and route-cardinality fail-closed hardening after the first generated-child data route` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.40` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm`; `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1112-isf-public-interface-contract.t t/1144-isf-public-tested-by-metadata-audit.t t/1183-ci-regression-tier-selection.t t/1250-isf-spec-focused-test-index-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1305-isf-book-feature-matrix-audit.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` (Files=236, Tests=1395); `git diff --check` | `hardened generated-child actor-to-actor source-port and route-cardinality diagnostics without widening route behavior` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.41` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `git diff --check` | `selected scalar endpoint-width fail-closed hardening before wider generated-child payload behavior` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.42` | `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` (Files=236, Tests=1395); `git diff --check` | `hardened generated-child actor-to-actor scalar endpoint-width diagnostics without production code changes` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.43` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `git diff --check` | `selected same-clock/reset-policy fail-closed hardening for generated-child actor-to-actor route wiring before CDC or reset remapping` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.44` | `perl -Iperl -c t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1322-isf-actor-network-static.t t/1325-isf-atl-data-route-fixture-coverage.t t/1327-isf-atl-pin-egress-fixture-coverage.t t/1330-isf-atl-resolved-child-fixture-coverage.t`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `mdbook build docs/book`; `./bin/ci-regression isf --no-book` (Files=236, Tests=1395); `git diff --check` | `hardened generated-child actor-to-actor same-clock/reset-policy diagnostics without production code changes` |
| `2026-05-19` | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.45` | `mdbook build docs/book`; `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t`; `git diff --check` | `selected distinct source/sink child fail-closed hardening for generated-child actor-to-actor routes before self-route or loopback behavior` |

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
| `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.2: fail closed ATL data movement` | `rejects reserved qualified actor endpoint sink/source drive-body pairs with ATL data-movement diagnostics` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.5.3` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.3: select scalar ATL handoff` | `selects the first generated scalar actor-to-actor handoff subset before behavior-bearing code` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.5.4` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.5.4: lower scalar ATL handoff` | `lowers the selected scalar actor-to-actor handoff subset to generated parent ports and data_movement report metadata` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.6.1` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.1: select pin-to-actor handoff` | `selects the first scalar top-level input pin to actor handoff subset before behavior-bearing code` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.6.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.2: lower pin-to-actor handoff` | `lowers the selected scalar top-level input pin to actor handoff subset` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.6.3` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.3: select actor-to-pin handoff` | `selects the first scalar actor endpoint to top-level output pin handoff subset before behavior-bearing code` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.6.4` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.6.4: lower actor-to-pin handoff` | `lowers the selected scalar actor endpoint to top-level output pin handoff subset and closes top-level pin movement` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.7.1` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.1: select group boundary` | `decomposes concurrent actor groups and selects fail-closed group diagnostics before metadata or scheduling behavior` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.7.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.2: fail closed ATL groups` | `rejects reserved verbose and compact actor-group forms with targeted ATL diagnostics` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.7.3` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.3: report static ATL groups` | `ships report-only static concurrent group metadata under actor_network.groups[]` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.7.4` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.4: select group trigger batch` | `selects same-cycle external trigger batches for every member of one declared static group` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.7.5` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.7.5: lower group trigger batch` | `lowers the selected same-cycle external group trigger batch and closes the first group scheduling sequence` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.8` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.8: decompose ATL fixture frontier` | `splits realistic multi-actor fixture promotion into selection and implementation leaves` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.8.1` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.8.1: select ATL fixture` | `selects the first realistic ATL group-trigger fixture and exact .8.2 verification contract` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.8.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.8.2: add ATL trigger fixture` | `pivots the first ATL fixture to task-scoped temporary trigger batches and proves strict schedule JSON plus HDL reachability` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.1` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.1: select ATL association reports` | `selects canonical association_schedules[] report metadata as the next temporary-association slice` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.2: add ATL association reports` | `ships canonical association_schedules[] metadata while preserving group_schedules[] compatibility` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.3` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.3: select ATL data-route fixture` | `selects a scalar actor-to-actor data-route fixture using shipped drive-body movement syntax` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.4: add ATL data-route fixture` | `promotes the scalar actor-to-actor data-route fixture with strict schedule JSON and HDL coverage` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.5` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.5: select ATL pin ingress fixture` | `selects the top-level input-pin to actor ingress fixture using shipped pin movement syntax` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.6` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.6: add ATL pin ingress fixture` | `promotes the scalar top-level input-pin to actor fixture with strict schedule JSON and HDL coverage` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.7` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.7: select ATL pin egress fixture` | `selects the actor-to-top-level output pin egress fixture using shipped pin movement syntax` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.8` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.8: add ATL pin egress fixture` | `promotes the scalar actor-to-top-level output pin fixture with strict schedule JSON and HDL coverage` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.9` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.9: select ATL trigger-wait fixture` | `selects the single-actor trigger/event wait fixture using shipped parent handoff syntax` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.10` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.10: add ATL trigger-wait fixture` | `promotes the single-actor trigger/event wait fixture with strict schedule JSON and HDL coverage` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.11` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.11: select ATL trigger-batch wait fixture` | `selects the first temporary trigger-batch plus single event-wait fixture` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.12: add ATL trigger-batch wait fixture` | `promotes the temporary trigger-batch plus single event-wait fixture with strict schedule JSON and HDL coverage` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.13` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.13: select ATL multi-wait boundary` | `selects negative coverage proving multi-event waits after one temporary trigger batch remain outside the shipped subset` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.14` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.14: prove ATL multi-wait boundary` | `adds focused negative coverage for temporary trigger-batch plus multiple event waits and advances to generated-child boundary selection` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.15` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.15: select ATL actor-root boundary` | `selects multiple actor-root fail-closed coverage as the next source-resolution prerequisite` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.16` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.16: fail closed ATL actor roots` | `ships the targeted multiple actor-root diagnostic and advances to actor type-resolution contract selection` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.17` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.17: select ATL type resolution contract` | `selects library-qualified actor type resolution through explicit imports and actor exports` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.18` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.18: fail closed ATL type syntax` | `reserves library-qualified ATL type syntax with targeted diagnostics before generated child behavior` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.19` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.19: select ATL type metadata` | `selects metadata-only resolution for library-qualified ATL instance types` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.20` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.20: resolve ATL type metadata` | `publishes resolved library/export provenance and reserved child artifact names` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.21` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.21: select ATL child artifacts` | `selects resolved child .fsm emission before ATL top wiring` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.22` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.22: emit ATL child artifacts` | `emits resolved ATL child scheduled artifacts without generating an ATL top` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.23` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.23: select ATL resolved-child fixture` | `selects a realistic fixture for parent plus resolved child artifact coverage` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.24` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.24: add ATL resolved-child fixture` | `promotes the resolved-child fixture with strict schedule JSON parity and no-top coverage` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.25` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.25: select ATL generated top` | `selects the first generated ATL top and handoff-wiring subset before implementation` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.26` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.26: emit ATL generated top` | `ships the first generated ATL top for one resolved child and one parent trigger/event handoff pair` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.27` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.27: select ATL HDL top promotion` | `selects plain and strict CLI HDL coverage for the resolved-child generated top` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.28` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.28: promote ATL top HDL` | `proves generated top, parent, child, and trigger/event links in CLI SystemVerilog` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.29` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.29: select ATL pin ingress top wiring` | `selects one scalar top-level input-pin route into one resolved child through the generated ATL top` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.30` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.30: wire ATL pin ingress top` | `ships the bounded generated-top pin-ingress route and child input port preservation` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.31` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.31: select ATL pin egress top wiring` | `selects one scalar resolved-child output route to one top-level output pin through the generated ATL top` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.32` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.32: wire ATL pin egress top` | `ships the bounded generated-top pin-egress route and child output port preservation` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.33` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.33: select ATL multi-child route boundary` | `selects fail-closed coverage for reserved generated-child actor-to-actor data movement before multi-child top scheduling` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.34` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.34: fail closed ATL multi-child route` | `adds the targeted diagnostic and advances the ATL frontier to .9.35` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.35` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.35: select ATL two-child top` | `selects sequential trigger/event handoffs for two resolved children in one generated top` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.36` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.36: emit ATL two-child top` | `ships the two-child generated top and advances the ATL frontier to .9.37` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.37` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.37: select ATL child data route` | `selects one scalar generated-child actor-to-actor data route through the two-child generated top` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.38` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.38: wire ATL child data route` | `ships the selected generated-child actor-to-actor data route through the two-child generated top` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.39` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.39: select ATL route hardening` | `selects source-side child port and route-cardinality fail-closed hardening as the next leaf` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.40` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.40: harden ATL route boundary` | `locks source child output and route-cardinality diagnostics around the generated-child actor-to-actor route` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.41` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.41: select ATL width boundary` | `selects scalar-width fail-closed coverage as the next generated-child route boundary` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.42` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.42: harden ATL width boundary` | `adds focused scalar endpoint-width rejection coverage around the generated-child actor-to-actor route without widening behavior` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.43` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.43: select ATL clock boundary` | `selects same-clock/reset-policy hardening as the next generated-child route boundary before CDC or reset remapping` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.44` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.44: harden ATL clock boundary` | `adds focused source/sink child clock and reset mismatch rejection coverage around the generated-child actor-to-actor route without widening behavior` |
| `ISF-ACTOR-NETWORK-ORCHESTRATION.9.45` | `this commit: ISF-ACTOR-NETWORK-ORCHESTRATION.9.45: select ATL self-route boundary` | `selects distinct source/sink child hardening as the next generated-child route boundary before loopback behavior` |

## Changelog

- `2026-05-19`: Completed `.9.45`: selected `.9.46` as distinct
  source/sink child hardening for the generated-child actor-to-actor data
  route. The next leaf must reject a route pair whose source and sink actor
  qualifiers name the same resolved child before any self-route, loopback,
  child-internal bypass, storage, mux, fan-in/fan-out, ready/backpressure, or
  payload protocol behavior is claimed.
- `2026-05-19`: Completed `.9.44`: added focused fail-closed coverage for
  source child clock mismatch, sink child clock mismatch, source child reset
  signature mismatch, and sink child reset signature mismatch in the
  generated-child actor-to-actor route. No production code change was
  required, and no CDC bridge, reset remapping, generated-top system-port
  remapping, route mux/storage, ready/backpressure, payload protocol, or
  report key behavior widened. The active frontier moves to `.9.45` to
  select the next bounded ATL slice before code.
- `2026-05-19`: Completed `.9.43`: selected `.9.44` as same-clock/reset
  policy hardening for the generated-child actor-to-actor data route. The
  next leaf must reject source and sink children whose clock or reset
  signature differs from the parent before any CDC bridge, reset remapping,
  system-port remapping, mux/storage, ready/backpressure, or payload protocol
  behavior is claimed.
- `2026-05-19`: Completed `.9.42`: added focused fail-closed coverage for
  wider source child output endpoints and wider sink child input endpoints in
  the generated-child actor-to-actor route. No production code change was
  required, and no source syntax, public report key, generated artifact shape,
  route mux/storage, fan-in/fan-out, CDC/reset remap, ready/backpressure, or
  payload protocol behavior widened. The active frontier moves to `.9.43` to
  select the next bounded ATL slice before code.
- `2026-05-19`: Completed `.9.41`: selected `.9.42` as scalar endpoint-width
  hardening for the generated-child actor-to-actor data route. The next leaf
  must reject wider source child outputs and wider sink child inputs before
  any payload packing, truncation, extension, storage, mux, or fan-in/fan-out
  behavior is claimed.
- `2026-05-19`: Completed `.9.40`: added focused fail-closed coverage for
  missing source child output, multiple endpoint pairs in one ATL route drive,
  multiple selected route drives, and repeated route drive calls around
  `isf/atl_two_child_data_pipeline.isf`. The source-side diagnostic now names
  the source instance role. The active frontier moves to `.9.41` to select
  the next bounded widening or hardening slice before code.
- `2026-05-19`: Completed `.9.39`: selected `.9.40` as a focused
  fail-closed hardening slice for the shipped
  `isf/atl_two_child_data_pipeline.isf` route. The next leaf must lock source
  child output validation, sink child input validation, one route drive body,
  one endpoint pair, and one top-level drive call before any wider route
  mux/storage, fan-in/fan-out, CDC, or payload-protocol behavior is claimed.
- `2026-05-19`: Completed `.9.38`: shipped
  `isf/atl_two_child_data_pipeline.isf` with one scalar generated-child
  actor-to-actor route through the two-child generated ATL top. The parent
  drives `writer_payload` from `reader_payload` in the drive-call cycle, the
  generated top wires reader payload to the parent source handoff and parent
  sink handoff to writer payload, and schedule JSON reuses
  `actor_network.data_movements[]` plus `actor_network.generated_tops[]`.
- `2026-05-19`: Completed `.9.37`: selected `.9.38` as one scalar
  generated-child actor-to-actor data route through the shipped two-child
  generated top. The selected source shape is `(writer.payload
  reader.payload)` called after `reader.done` and before `writer.emit`.
- `2026-05-19`: Completed `.9.36`: shipped
  `isf/atl_two_child_pipeline.isf`. Lowering now emits the parent, two
  resolved children, and one generated top; the top wires each parent trigger
  handoff to the matching child start input and each child event output back
  to the parent event handoff. Schedule JSON keeps the same actor-network
  families and adds `children[]` child wiring records to the multi-child
  `generated_tops[]` entry. The active frontier moves to `.9.37` to select
  the next bounded ATL widening before code.
- `2026-05-19`: Completed `.9.35`: selected `.9.36` as the first positive
  multi-child generated-top implementation slice. The selected source shape
  has two resolved children, sequential `reader.capture`/`reader.done` then
  `writer.emit`/`writer.done` handoffs, and no ATL data movement. Existing
  report families remain the selected public surface:
  `actor_network.instances[]`, `transaction_triggers[]`, `event_waits[]`,
  and `generated_tops[]`.
- `2026-05-19`: Completed `.9.34`: reserved generated-child
  actor-to-actor data movement now fails closed with a targeted diagnostic
  when an existing `(sink source)` drive-body route such as
  `(writer.payload reader.payload)` is coupled to qualified actor
  trigger/event handoffs. Focused coverage preserves shipped parent-handoff
  actor-to-actor routes plus the one-child generated-top trigger/event,
  pin-ingress, and pin-egress fixtures. The active frontier moves to `.9.35`
  to select the next bounded multi-child generated-top design or fail-closed
  boundary before code.
- `2026-05-19`: Completed `.9.33`: selected `.9.34` to fail closed the
  reserved generated-child actor-to-actor data-route shape before positive
  multi-child ATL top scheduling is widened. The selected source shape uses
  two resolved child instances, an existing `(sink source)` drive pair
  `(writer.payload reader.payload)`, producer trigger/event sequencing, and
  an attempted sink trigger/event sequence. `.9.34` must add a targeted ATL
  diagnostic while preserving shipped parent-handoff actor-to-actor routes
  and the one-child generated-top trigger/event, pin-ingress, and pin-egress
  fixtures.
- `2026-05-19`: Completed `.9.32`: shipped one scalar resolved-child output
  route to one top-level output pin through the generated ATL top. The new
  `isf/atl_resolved_child_pin_egress_pipeline.isf` fixture lowers to parent,
  child, and top `.fsm` artifacts; wires child `payload` to parent
  `worker_payload`; wires parent `result` to top `result`; keeps the existing
  trigger/event links internal; reports the route through
  `actor_network.data_movements[]`; and preserves generated-top discovery
  through `actor_network.generated_tops[]`. The active frontier moves to
  `.9.33` to select the next bounded generated-child integration or
  fail-closed boundary before code.
- `2026-05-19`: Completed `.9.31`: selected `.9.32` to wire one scalar
  resolved-child output route to one top-level output pin through the
  generated ATL top. The selected source shape uses
  `(pins.result worker.payload)` after the parent transaction triggers
  `worker.process` and awaits `worker.done`, keeps
  `actor_network.data_movements[]` and `actor_network.generated_tops[]` as
  the public report surfaces, and keeps actor-to-actor generated-child
  routes, multi-child data wiring, route mux/storage, CDC/reset remapping,
  ready/backpressure, payload protocols, recursive networks, and permanent
  grouping deferred.
- `2026-05-19`: Completed `.9.30`: shipped one scalar top-level input-pin
  route into one resolved child through the generated ATL top. The new
  `isf/atl_resolved_child_pin_ingress_pipeline.isf` fixture lowers to
  parent, child, and top `.fsm` artifacts; wires top `payload` to the parent;
  wires parent `worker_payload` to child input `payload`; keeps the existing
  trigger/event links internal; reports the route through
  `actor_network.data_movements[]`; and preserves generated-top discovery
  through `actor_network.generated_tops[]`. The active frontier moves to
  `.9.31` to select the next bounded generated-child integration or
  fail-closed boundary before code.
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
- `2026-05-18`: Completed `.5.2`: named drive bodies and inline transaction
  drive assignments now fail closed when a drive-body pair sink or source is a
  qualified actor endpoint naming the current static actor instance. The
  active frontier moves to `.5.3` to select the first generated scalar
  actor-to-actor handoff subset.
- `2026-05-18`: Completed `.5.3`: selected the first generated scalar
  actor-to-actor handoff subset as exactly two direct static actor instances,
  one named drive body with one scalar endpoint pair, one top-level
  transaction drive call, one-cycle external parent handoff ports, explicit
  report keys, and fail-closed boundaries for every broader ATL movement form.
  The active frontier moves to `.5.4` for lowering only that selected subset.
- `2026-05-18`: Completed `.5.4`: the selected scalar actor-to-actor handoff
  now lowers. Parser validation accepts exactly two direct static actor
  instances only for one named drive body with one scalar endpoint pair and
  one top-level drive call, rewrites the pair to generated parent handoff
  signals, emits one-bit source input and sink output ports in the parent
  scheduled `.fsm`, records `actor_network.data_movements[]`, and keeps
  broader movement forms fail-closed. The `.5` actor-to-actor data movement
  group is complete; the active frontier moves to `.6` for top-level pin to
  actor-network movement.
- `2026-05-18`: Completed `.6.1`: selected scalar top-level input pin to
  actor handoff as the first pin movement subset. The next leaf, `.6.2`,
  lowers only one `(actor.endpoint pins.input_pin)` drive-body pair activated
  by one top-level drive call while broader pin movement remains deferred.
- `2026-05-18`: Completed `.6.2`: the selected pin-to-actor handoff now
  lowers. Parser validation accepts one direct static actor instance, one
  named drive body with one `(actor.endpoint pins.input_pin)` scalar pair,
  and one top-level drive call; lowering rewrites the sink to a generated
  actor handoff output while reading the existing top-level input pin as the
  source and records `scalar_pin_to_actor_handoff` metadata. The active
  frontier moves to `.6.3` to select actor-to-pin output movement.
- `2026-05-18`: Completed `.6.3`: selected scalar actor-to-top-level output
  pin handoff as exactly one direct static actor instance, one named drive
  body with one `(pins.output_pin actor.endpoint)` scalar pair, and one
  top-level transaction drive call. The next leaf, `.6.4`, lowers only that
  selected form while broader pin movement remains deferred or fail-closed.
- `2026-05-18`: Completed `.6.4`: the selected actor-to-pin handoff now
  lowers. Parser validation accepts one direct static actor instance, one
  named drive body with one `(pins.output_pin actor.endpoint)` scalar pair,
  and one top-level drive call; lowering rewrites the source to a generated
  actor handoff input while driving the existing top-level output pin as the
  sink and records `scalar_actor_to_pin_handoff` metadata. The `.6` top-level
  pin movement group is complete; the active frontier moves to `.7` for
  concurrent actor-group scheduling selection/decomposition.
- `2026-05-18`: Completed `.7.1`: decomposed concurrent actor-group
  scheduling into targeted fail-closed group diagnostics, static group
  metadata, first scheduling selection, and first scheduling lowering leaves.
  The active frontier moves to `.7.2` to reject reserved group declarations
  and compact aliases with targeted ATL diagnostics before group metadata or
  scheduling behavior is claimed.
- `2026-05-18`: Completed `.7.2`: direct actor-body `(group ...)`
  declarations and compact `(concurrent ...)` aliases now fail closed with
  targeted ATL group diagnostics. No group metadata or scheduling behavior is
  claimed. The active frontier moves to `.7.3` for static group metadata.
- `2026-05-18`: Completed `.7.3`: direct actor-body
  `(group NAME (members ACTOR...) (mode concurrent))` declarations now report
  static `actor_network.groups[]` metadata for already declared direct static
  actor instances. The metadata is report-only: no group endpoints,
  scheduling overlap, generated child artifacts, route mux/storage, CDC, or
  compact aliases are claimed. The active frontier moves to `.7.4` to select
  the first group scheduling behavior before code.
- `2026-05-18`: Completed `.7.4`: selected the first group scheduling
  behavior as one same-cycle external trigger batch in a top-level
  transaction body. The selected source remains existing
  `(trigger actor.transaction)` clauses, requires every member of one declared
  static group exactly once, emits no child/group endpoint/mux/storage/CDC
  behavior, and reports scheduling evidence through
  `actor_network.group_schedules[]`. The active frontier moves to `.7.5`
  for lowering only this selected subset.
- `2026-05-18`: Completed `.7.5`: the selected group trigger batch now
  lowers. A contiguous top-level transaction-body run of
  `(trigger actor.transaction)` clauses may target every member of one
  declared static group exactly once; FSMGen rewrites the run to one internal
  grouped trigger state, pulses all generated external trigger outputs in the
  same cycle, preserves per-target `actor_network.transaction_triggers[]`,
  reports `actor_network.group_schedules[]`, and keeps broader group
  scheduling fail-closed. The `.7` concurrent group sequence is complete and
  the active frontier moves to `.8` for realistic multi-actor orchestration
  fixtures.
- `2026-05-18`: Decomposed `.8` before code into `.8.1` fixture selection and
  `.8.2` fixture promotion. The active frontier moves to `.8.1` so the first
  realistic ATL fixture source, checks, and book updates are selected before
  implementation.
- `2026-05-18`: Completed `.8.1`: selected
  `isf/atl_group_trigger_pipeline.isf` as the first realistic ATL fixture.
  The selected fixture uses three direct static actors, one verbose static
  group, and one exact same-cycle external group-trigger batch. It will emit
  only the scheduled parent `.fsm`, report instances/groups/per-target
  triggers/group schedule evidence, and prove strict schedule JSON plus HDL
  reachability without claiming event/data/generated-child ATL behavior. The
  active frontier moves to `.8.2`.
- `2026-05-19`: Completed `.8.2`: pivoted the first realistic ATL fixture to
  `isf/atl_trigger_batch_pipeline.isf` after clarifying that actor
  associations are task-scoped and should dissolve when the scheduled task is
  done. The parser now accepts a contiguous top-level trigger batch to
  distinct static actor instances without a permanent `(group ...)`
  declaration, lowering emits one `run_atl_trigger_batch_1` state, schedule
  JSON reports synthetic `run_trigger_batch` evidence, and the fixture proves
  strict schedule JSON plus plain/strict HDL reachability. The active frontier
  moves to `.9.1` to select the next ATL temporary-association slice before
  code.
- `2026-05-19`: Completed `.9.1`: selected `.9.2` as the next
  temporary-association report-contract slice. `.9.2` will add canonical
  `actor_network.association_schedules[]` entries for task-scoped ATL
  associations, preserve `actor_network.group_schedules[]` as a
  schema-version-1 compatibility view, and avoid new source syntax or broader
  ATL behavior claims.
- `2026-05-19`: Completed `.9.2`: canonical
  `actor_network.association_schedules[]` metadata now reports task-scoped
  temporary trigger batches with `kind: temporary_trigger_batch` and
  `lifetime: task_scoped`. Existing `actor_network.group_schedules[]`
  remains as a schema-version-1 compatibility view. The active frontier moves
  to `.9.3` to select the next ATL temporary-association behavior before
  code.
- `2026-05-19`: Completed `.9.3`: selected `.9.4` to promote
  `isf/atl_data_route_pipeline.isf`, a realistic scalar actor-to-actor
  data-route fixture using a named drive body and one transaction drive call.
  The fixture will prove generated parent handoff ports, `data_movements[]`
  metadata, strict schedule JSON, and plain/strict HDL reachability without
  claiming generated ATL children, ATL tops, route mux/storage, trigger/data
  coupling, or permanent grouping.
- `2026-05-19`: Completed `.9.4`: promoted
  `isf/atl_data_route_pipeline.isf` with file-backed strict schedule JSON
  parity, scheduled `.fsm` structure, generated parent source/sink handoff
  ports, `actor_network.data_movements[]` metadata, empty
  association/group schedule arrays, and plain/strict HDL reachability. The
  broad ISF gate passed with `Files=231, Tests=1360`. The active frontier
  moves to `.9.5` to select the next ATL behavior before code.
- `2026-05-19`: Completed `.9.5`: selected `.9.6` to promote
  `isf/atl_pin_ingress_pipeline.isf`, a realistic top-level input-pin to
  actor ingress fixture using a named drive body and one transaction drive
  call. The selected fixture will prove `payload` as the existing top-level
  input source, generated actor handoff output `consumer_payload`,
  `scalar_pin_to_actor_handoff` metadata, strict schedule JSON, and
  plain/strict HDL reachability without claiming actor-to-pin egress,
  generated ATL children, ATL tops, route mux/storage, or broader pin routing.
- `2026-05-19`: Completed `.9.6`: promoted
  `isf/atl_pin_ingress_pipeline.isf` with file-backed strict schedule JSON
  parity, scheduled `.fsm` structure, existing top-level source input
  `payload`, generated actor handoff output `consumer_payload`,
  `scalar_pin_to_actor_handoff` metadata, empty association/group schedule
  arrays, and plain/strict HDL reachability. The broad ISF gate passed with
  `Files=232, Tests=1363`. The active frontier moves to `.9.7` to select the
  next ATL network-boundary or association behavior before code.
- `2026-05-19`: Completed `.9.7`: selected `.9.8` to promote
  `isf/atl_pin_egress_pipeline.isf`, a realistic actor-to-top-level output
  pin egress fixture using a named drive body and one transaction drive call.
  The selected fixture will prove generated actor source handoff input
  `producer_payload`, existing top-level output sink `result`,
  `scalar_actor_to_pin_handoff` metadata, strict schedule JSON, and
  plain/strict HDL reachability without claiming generated ATL children, ATL
  tops, bidirectional pin movement, route mux/storage, or broader pin routing.
- `2026-05-19`: Completed `.9.8`: promoted
  `isf/atl_pin_egress_pipeline.isf` with file-backed strict schedule JSON
  parity, scheduled `.fsm` structure, generated actor source handoff input
  `producer_payload`, existing top-level output sink `result`,
  `scalar_actor_to_pin_handoff` metadata, empty association/group schedule
  arrays, and plain/strict HDL reachability. The active frontier moves to
  `.9.9` to select the next ATL behavior after the scalar boundary fixture
  ladder.
- `2026-05-19`: Completed `.9.9`: selected `.9.10` to promote
  `isf/atl_trigger_wait_pipeline.isf`, a realistic single-actor orchestration
  fixture that emits one trigger handoff `worker_process_start`, waits on one
  event handoff `worker_done`, and completes without claiming temporary
  trigger-batch/event coupling, generated ATL children, generated ATL tops,
  actor type resolution, child wiring, data movement coupling, or broader
  fan-in/fan-out behavior.
- `2026-05-19`: Completed `.9.10`: promoted
  `isf/atl_trigger_wait_pipeline.isf` with file-backed strict schedule JSON
  parity, scheduled `.fsm` structure including the default await timeout
  state, generated trigger handoff output `worker_process_start`, generated
  event handoff input `worker_done`, one `transaction_triggers[]` entry, one
  `event_waits[]` entry, empty association/group/data-movement arrays, and
  plain/strict HDL reachability. The active frontier moves to `.9.11` to
  select the next ATL behavior after the trigger-wait fixture before code.
- `2026-05-19`: Completed `.9.11`: selected `.9.12` to promote
  `isf/atl_trigger_batch_wait_pipeline.isf`, a realistic temporary
  trigger-batch plus single event-wait fixture. The selected fixture will
  prove same-cycle trigger batch handoffs, one `writer_done` event wait,
  `association_schedules[]` temporary-association evidence,
  `group_schedules[]` compatibility evidence, strict schedule JSON, and
  plain/strict HDL reachability without claiming generated ATL children, ATL
  tops, actor type resolution, child wiring, event fan-in, or permanent actor
  grouping.
- `2026-05-19`: Completed `.9.12`: promoted
  `isf/atl_trigger_batch_wait_pipeline.isf` with file-backed strict schedule
  JSON parity, scheduled `.fsm` structure including the default await timeout
  state, generated trigger-batch outputs, generated `writer_done` event input,
  `association_schedules[]` temporary-association metadata,
  `group_schedules[]` compatibility metadata, one `event_waits[]` entry,
  empty data movement, and plain/strict HDL reachability. The active frontier
  moves to `.9.13` to select the next ATL behavior after trigger-batch/event
  wait coupling before code.
- `2026-05-19`: Completed `.9.13`: selected `.9.14` as negative boundary
  coverage for deferred multi-event actor fan-in after a temporary trigger
  batch. The selected rejected shape triggers reader/filter/writer, then
  attempts `(await reader.done)` and `(await writer.done)` before completion;
  it must fail before scheduled `.fsm` emission with the one-event-wait
  diagnostic and without widening production ATL behavior.
- `2026-05-19`: Completed `.9.14`: added focused negative coverage proving
  one temporary trigger batch followed by `(await reader.done)` and
  `(await writer.done)` fails before scheduled `.fsm` emission with the
  one-event-wait diagnostic. The broad ISF gate passed with `Files=235,
  Tests=1372`. No production behavior changed. The active frontier moves to
  `.9.15` to select generated-child artifact or actor type-resolution
  boundaries before code.
- `2026-05-19`: Completed `.9.15`: selected `.9.16` to fail closed multiple
  top-level `(actor ...)` roots before sibling actor roots can be mistaken for
  resolved ATL child type definitions. The next code leaf will preserve one
  actor root plus `(library ...)` roots and will not claim generated child
  artifacts, generated ATL tops, actor type resolution, or HDL child wiring.
- `2026-05-19`: Completed `.9.16`: multiple top-level `(actor ...)` roots now
  fail closed with a targeted diagnostic before ATL actor type resolution.
  Focused coverage also proves one actor root plus a same-source `(library
  ...)` root remains accepted. The broad ISF gate passed with `Files=235,
  Tests=1373`. The active frontier moves to `.9.17` to select the explicit
  ATL actor type-resolution source contract before generated child artifacts.
- `2026-05-19`: Completed `.9.17`: selected library-qualified
  `(instance NAME of ALIAS.EXPORT)` as the future ATL actor type-resolution
  source contract, with `ALIAS` coming from explicit library imports and
  `EXPORT` naming a library actor export. Unqualified actor types remain
  metadata-only external intent, sibling actor roots stay fail-closed, and
  no generated child artifacts or report schema changes are claimed. The
  active frontier moves to `.9.18` to reserve the selected qualified syntax
  with targeted diagnostics before generated ATL child resolution.
- `2026-05-19`: Completed `.9.18`: the parser now recognizes
  `(instance NAME of ALIAS.EXPORT)` as the selected future ATL
  library-qualified type syntax and fails closed with targeted diagnostics for
  missing imports, non-explicit import aliases, unknown aliases, unknown actor
  exports, and known exports before scheduled `.fsm` emission. No actor type
  is resolved, no
  `actor_network.instances[]` keys change, existing unqualified metadata-only
  instances and `(use alias.actor as instance ...)` library behavior are
  preserved. The active frontier moves to `.9.19` to select the first
  resolution metadata or generated-artifact slice before code.
- `2026-05-19`: Completed `.9.19`: selected metadata-only resolution for
  library-qualified ATL static actor instances. The selected `.9.20` slice
  must resolve `(instance NAME of ALIAS.EXPORT)` through explicit imports and
  actor exports, then publish library/export provenance and reserved child
  names without emitting child artifacts or generated ATL tops.
- `2026-05-19`: Completed `.9.20`: valid library-qualified ATL instances now
  report `type_resolution`, `library`, `alias`, `export`, `module`, and
  `scheduled_fsm` metadata while lowering still emits only the parent
  scheduled `.fsm`. The active frontier moves to `.9.21` to select child
  artifact, generated-top, or interface-binding behavior before code.
- `2026-05-19`: Completed `.9.21`: selected `.9.22` to emit resolved child
  scheduled `.fsm` artifacts using the already reported
  `<parent_actor>__<instance>.fsm` names while keeping generated ATL tops and
  handoff wiring deferred.
- `2026-05-19`: Completed `.9.22`: resolved ATL instances now emit child
  scheduled `.fsm` artifacts alongside the parent `.fsm`, keep ATL
  `(instance ...)` children out of `library_uses[]`, and fail closed on child
  artifact name conflicts. No ATL top, HDL child wiring, interface binding,
  event fan-in, route mux/storage, CDC, or ready/backpressure is claimed. The
  active frontier moves to `.9.23`.
- `2026-05-19`: Completed `.9.23`: selected `.9.24` to add
  `isf/atl_resolved_child_pipeline.isf`, a realistic emitted-child fixture
  that combines one resolved child artifact with one parent trigger handoff
  and one parent event wait while preserving the no-top/no-child-wiring
  boundary.
- `2026-05-19`: Completed `.9.24`: promoted
  `isf/atl_resolved_child_pipeline.isf` with file-backed strict schedule JSON
  parity, exactly two lower-result artifacts
  `atl_resolved_child_pipeline.fsm` and
  `atl_resolved_child_pipeline__worker.fsm`, resolved
  `actor_network.instances[]` metadata, one `transaction_triggers[]` entry,
  one `event_waits[]` entry, and empty data/association/group schedule
  arrays. The active frontier moves to `.9.25` to select generated ATL top,
  interface-binding, or fail-closed behavior before code.
- `2026-05-19`: Completed `.9.25`: selected `.9.26` as the first generated
  ATL top implementation leaf. The selected subset is one resolved child,
  one parent trigger handoff, one parent event wait, matching parent/child
  clock and reset names/policies, generated `<parent>_top.fsm`, inferred
  trigger wiring from the child transaction's authored `(on START_SIGNAL)`,
  inferred event wiring from the child output port, and additive
  `actor_network` generated-top metadata. Broader wiring, data movement,
  trigger batches, groups, CDC, ready/backpressure, payloads, route
  mux/storage, recursive actor networks, and generated-top conflicts remain
  fail-closed for the next implementation leaf.
- `2026-05-19`: Completed `.9.26`: emitted the first generated ATL top for
  `isf/atl_resolved_child_pipeline.isf`. The lowerer now emits the parent,
  resolved child, and `atl_resolved_child_pipeline_top.fsm`, wires parent
  `worker_process_start` to child `process_start`, wires child `done` to
  parent `worker_done`, reports `actor_network.generated_tops[]`, and proves
  strict schedule JSON parity plus strict `--outdir` top emission. Focused
  fail-closed coverage rejects missing child target transactions, non-scalar
  child activation, missing child event outputs, and parent/child clock
  mismatches. The active frontier moves to `.9.27` to select the next ATL
  generated-top, interface-binding, HDL handoff, or fail-closed boundary
  before code.
- `2026-05-19`: Completed `.9.27`: selected `.9.28` as generated-top HDL
  promotion for `isf/atl_resolved_child_pipeline.isf`. The source and report
  schema stay unchanged; the next leaf must prove plain and strict CLI
  SystemVerilog generation includes the generated top, scheduled parent,
  resolved child, and selected internal trigger/event links without widening
  ATL source syntax or report keys.
- `2026-05-19`: Completed `.9.28`: promoted the resolved-child generated top
  through plain and strict CLI HDL coverage in
  `t/1330-isf-atl-resolved-child-fixture-coverage.t`. The existing CLI path
  already emits SystemVerilog containing the generated top, parent, child, and
  selected internal trigger/event links, so no production code change was
  required. The active frontier moves to `.9.29` to select the next ATL
  generated-child integration, interface-binding, or fail-closed boundary
  before code.
- `2026-05-19`: Completed `.9.29`: selected `.9.30` as one scalar
  top-level input-pin to resolved-child input route through the generated ATL
  top. The selected shape adds one `(worker.payload pins.payload)` drive to
  the existing one-child trigger/event top, preserves `data_movements[]` as
  route metadata and `generated_tops[]` as top discovery metadata, and keeps
  multi-route, actor-to-actor, actor-to-pin, multi-child, route mux/storage,
  CDC, ready/backpressure, payload protocol, recursive-network, and permanent
  grouping behavior deferred.
