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
  Children: `ISF-ACTOR-NETWORK-ORCHESTRATION.9.1`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.3`, `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4`
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
  Status: `active`
  Goal: `Promote a realistic ATL scalar data-route fixture.`
  Acceptance: `Add isf/atl_data_route_pipeline.isf as a bounded data-movement fixture using already shipped ATL source syntax: two direct static actor instances, one named drive body with exactly one '(consumer.payload producer.payload)' scalar actor-to-actor endpoint pair, and one top-level transaction drive call. The fixture must emit only atl_data_route_pipeline.fsm, preserve the generated parent handoff ports producer_payload and consumer_payload, report one actor_network.data_movements[] entry with route_lifetime drive_call_cycle and no storage, keep actor_network.association_schedules[] and group_schedules[] empty because this is a drive-activated data route rather than a trigger-batch association, and prove strict schedule JSON parity plus plain/strict HDL reachability. Do not claim generated ATL child artifacts, generated ATL tops, route mux/storage, peer events, trigger/data coupling, wider payloads, fan-in/fan-out, CDC, ready/backpressure, compact aliases, or permanent actor grouping.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4` | `active` | `.9.3` selected a realistic scalar data-route fixture using shipped ATL data movement before adding fixture source or tests. |

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

## Selected Next ATL Data-Route Fixture

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.3` selects the next fixture leaf as a
data-movement fixture rather than another trigger-batch fixture. The goal is
to keep moving toward the user's ATL data/information movement model while
staying inside already shipped scalar actor-to-actor handoff semantics.

Selected next implementation leaf:

- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4`

Selected file:

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

- No blocker for active `.8.2`. It must add only the selected
  `isf/atl_trigger_batch_pipeline.isf` fixture and must not widen syntax or
  scheduling beyond the temporary trigger-batch behavior documented in this
  leaf.

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
