# ISF Shipped Feature Matrix

This chapter is the book-facing checklist for the `.isf` surface that is
currently shipped. It does not replace the detailed chapters, the live spec,
or the downstream handoff. It gives reviewers one place to confirm which
feature families are supported, where to find examples, and where the explicit
backlog boundary starts.

A feature is "shipped" here only when the source shape, scheduled `.fsm`
lowering, runtime meaning, diagnostics, reports or review artifacts, and
focused regression evidence exist. Parser acceptance alone is not a support
claim.

## Requested Extensions And Current Gaps

SPECFORGE's configuration, verification and phase-membership requests are
owned implementation work; they are not shipped capabilities yet.

| Area | Current boundary | Requested extension |
| --- | --- | --- |
| Parameter-sized ports | Width references resolve to the default; an emitted HDL parameter does not make the port generic. | Preserve width dependencies through HDL and supported instance overrides. |
| Parameter constraints | Scalar parameters carry defaults without declared legal or recommended sets. | Check legal values/ranges at defaults and overrides; report constraints and advisory recommendations. |
| Optional interfaces | Zero widths are rejected; the unsupported `present` option is rejected. | Explicit presence, absent-input values and supported per-instance specialization. |
| Actor invariants | Verification checks are written inside transactions; their existing meaning is always-on. | Actor-level `assert`/`assume`/`cover`, including actors without transactions. |
| Known-value checks | `known` and `isunknown` are unsupported. | Verification-only knownness with independent X/Z behavior evidence. |
| Physical-time durations | Timing bounds use cycle counts; clocks carry signal identity without a declared rate. | Exact duration conversion against a declared frequency/period, authored-duration and derived-cycle reports, and counter-based duration waits while preserving existing cycle-count behavior. Owned by SEM `.60.1`; not shipped. |
| Named timers | Transaction watchdog expiry is an error path; named actor timers and distinct per-await limits are refused. | Concurrent actor-owned timers with start/restart/stop, ordinary expiry conditions and schedule metadata. Cycle limits are required; duration limits follow duration support. Distinct per-await watchdog limits are optional. Owned by SEM `.60.2`; not shipped. |
| Record interface ports | Local/imported packed actor record inputs, live scalar field reads and exact-type input-to-storage copies are admitted. Frontend/generated/domain source, carriers and complete public products are qualified; direct/generated binary behavior passes both emitter options with SystemVerilog parsing. Current ISF Verilog and selected VHDL profiles refuse precisely. Selected input delivery is qualified; full output-dependent consumer delivery remains open. | Record outputs and exact-type whole copies now have bounded source/carrier admission with conservative physical writer checks; bounded public source/profile/corpus products are qualified; generated/execution qualification and output member writes remain open. Root-list ports and variants are optional. The complete request is owned by SEM `.60.4` and is not finished. |
| Transaction phase groups | Membership cannot be carried as checked transaction metadata. | Checked phase/member/role facts without invented values, order or behavior. |

Unknown or malformed interface-port options are rejected in default and strict
modes through native/API/MCP queries. This validation boundary does not add
optional-port support. Declared inputs and outputs now retain their interface
roles even when unused or undriven. Output preservation adds no value assignment.
An explicitly reset output without a data writer now resets and holds under
the module hardware-reset contract. Its semantic drive family has no data-driver
blocks. Inspect realized semantic/HDL interfaces and behavior when evaluating
presence or reset semantics.

The earlier derived-width request depends on genuine generic-width support;
it is distinct from it. Exact request scopes, repair order, current
reproductions and bounded owners are recorded in
[SPECFORGE feedback response](reference-source/docs/SPECFORGE_FEEDBACK_RESPONSE.markdown.source.txt), including
its current delivery status and complete unstated-reset answer. Reset omission
selects the documented legacy default; a clock-only domain means no reset,
without guaranteed initialization. No current form defers reset policy to
instantiation.

## Status Vocabulary

| Status | Meaning |
| --- | --- |
| `shipped` | The listed source shape has documented lowering, runtime behavior, and regression coverage. |
| `shipped bounded surface` | The named subset is shipped; nearby wider forms fail closed or remain backlog. |
| `fail-closed boundary` | FSMGen recognizes the family enough to reject unsupported forms deliberately. It is not a runtime support claim. |
| `source admitted; qualification pending` | Authoring and required value gates are implemented; the named public/carrier/runtime and consumer qualification remains open. |

Anything outside the shipped rows below should be treated as backlog unless a
detailed chapter, [ISF Downstream Integration](13i-downstream-integration.md),
[ISF Types, Enums, And Aggregates](13j-type-enum-aggregate.md), or
[Feature Backlog](14-feature-backlog.md) says otherwise.

## Matrix

| Feature family | Status | Accepted authoring surface | Generated and reported behavior |
| --- | --- | --- | --- |
| `.isf` CLI input | shipped | `./bin/fsmgen file.isf`, `--strict file.isf`, `--emit-schedule-json`, and `--outdir DIR` for durable multi-file lower results. | Single-file actors lower to scheduled `.fsm` before HDL. Multi-file generated-child and accepted multi-domain actors keep implicit handoff files under `.artifacts/tmp/ial1-lowering/`, or write every scheduled `.fsm` artifact to an explicit repository-local `--outdir`, then use the generated top for HDL generation. |
| Public parser and scheduler facades | shipped bounded surface | `FSM::Adapter::ISF->new(debug => ...)`, `parse_file`, `parse_source`, `FSM::Scheduler::ISF->new(...)`, `lower`, and `report`. | Public methods validate receivers and argument shapes before private parsing/lowering. The capability manifest advertises the live public contract under `embedding.isf_public_interface`. |
| Actor envelope | shipped | `(actor NAME ...)` with singleton `(clock ...)`, `(clock-domains ...)`, `(reset ...)`, `(watchdog ...)`, `(interface ...)`, `(storage ...)`, `(types ...)`, `(enums ...)`, `(imports ...)`, `(constants ...)`, `(params ...)`, `(resources ...)`, and reusable-library `(use ...)` where documented. | The scheduled `.fsm` preserves reviewable system, size, constants, params, type, enum, import, storage, rule, drive, and transaction artifacts. Duplicate singleton clauses fail closed. |
| Reset declaration provenance | shipped report metadata | Existing legacy and named-domain reset forms. | Schedule `reset_provenance` and successful ISF check/semantic `source.reset_provenance` distinguish `explicit`, `legacy_default`, and `domain_absent` per domain. No hardware, startup initialization, or deferred reset choice is added. T1978 covers native/API/newline reports and unchanged carriers/HDL. |
| Declared interface metadata | shipped report metadata | Currently admitted scalar and packed record input/output local/imported aliases and widths, including unused/undriven declarations. | Successful ISF check/semantic `source.interface_ports`, schedule `interface_ports` and domain-owned snapshots preserve source order and distinguish unknown from known empty. T2034 qualifies complete bounded native/API/newline record-output source products, recursive types and domain layouts. T2035 qualifies actual unsupported-target native/facade errors and atomic destinations with supported SystemVerilog/sv text controls. T2036 qualifies complete finite predecessor products; T2037 and the sealed corpus receipt qualify the maintained `isf/record_output.isf` representative and complete catalog/cohort/discovery applicability. Root-list ports remain refused. T1984 qualifies declaration ownership and isolation, T1985 qualifies complete native/API/newline products, and T1998 qualifies admitted record-input declarations. Generated output mappings, output fields/runtime and full aggregate consumer qualification remain open. The dedicated `isf/interface_port_metadata.isf` corpus fixture retains a typed unused input and undriven output. |
| Actor report metadata and params | shipped bounded surface | Actor-level `(params ...)`, `(phase NAME ...)`, `(stage NAME ...)`, and passive verification observation metadata `(observe NAME (role passive_monitor) (signals SIG...))` where documented. Actor parameter defaults may use literals, declared actor constants, earlier scalar actor parameter defaults, enum members, qualified imported package scalar constants, and compatible aggregate/list defaults with those scalar leaves. Observation signals must be unique public actor interface signals in a single-clock actor. | Parameter defaults preserve source-order report entries in `actor_params[]`; actor-constant-backed, earlier-actor-parameter-backed, and qualified package-constant-backed defaults also carry resolved literals internally for width/count consumers. Forward, self, cyclic, non-scalar actor-parameter references, unqualified package constants, aggregate package constants, package member/item paths, and ambiguous local-enum/package-constant spellings fail closed. Actor-level phase/stage clauses are parser-validated and report-only through `actor_phases[]` and `actor_stages[]`. Passive observation metadata is parser-validated and report-only through `verification_observations[]`, with source-ordered signal `name`/`direction`/`width` summaries; it does not add generated `.fsm`, HDL, UVM, VHDL, scoreboard, coverage, or VIP behavior. |
| Static actor-network metadata | shipped bounded surface | Static actor instances through direct actor-body `(instance NAME of ACTOR_TYPE)` clauses or compact `(NAME : ACTOR_TYPE)` aliases, library-qualified type resolution through `(instance NAME of ALIAS.EXPORT)` and compact `(NAME : ALIAS.EXPORT)`, plus report-only static groups through `(group NAME (members ACTOR...) (mode concurrent))` and compact `(concurrent NAME ACTOR...)` aliases. `(network ...)` is not part of the shipped surface. | The parser shell and schedule report preserve `actor_network.kind`, instance `name`, `actor_type`, declaration spelling (`actor` for verbose instances and `instance_alias` for compact instances), resolved instance `type_resolution`/`library`/`alias`/`export`/`module`/`scheduled_fsm` metadata where applicable, `groups[]`, `generated_tops[]`, `association_schedules[]`, `group_schedules[]`, `event_waits[]`, `transaction_triggers[]`, and `data_movements[]`. Static group declarations alone remain metadata and do not schedule groups. Library-qualified actor type resolution emits resolved child `.fsm` files named by `scheduled_fsm` while keeping the parent `.fsm` unchanged. The first generated ATL top is shipped for one resolved child plus one parent trigger handoff and one parent event wait with matching clock/reset policy; the bounded scalar top-level input-pin to resolved-child input route, one exact-width vector top-level input-pin to resolved-child input route, the scalar same-child pin-ingress multi-route extension, the vector same-child pin-ingress multi-route extension, the mixed scalar/vector same-child pin-ingress route-set extension, the scalar resolved-child output to top-level output route, one exact-width vector resolved-child output to top-level output route, the scalar same-child pin-egress multi-route extension, the vector same-child pin-egress multi-route extension, and the mixed scalar/vector same-child pin-egress route-set extension are shipped for that same one-child top; temporary trigger-batch parent handoff now supports sequential multi-event waits to distinct triggered actors; the first control-only two-child generated top is shipped for sequential trigger/event handoffs with no data movement; the first resolved-child trigger-batch generated top is shipped for exactly two resolved children with one same-cycle trigger batch, source-ordered waits, no static group declaration, and no ATL data movement; and same-source/same-sink scalar or exact-width vector generated-child actor-to-actor routes are shipped through that two-child top. Broader multiple-instance scheduling, broader actor events/triggers, fan-in/fan-out data routing, width adaptation, broader generated-child data-route coupling, and broader endpoint-aware movement remain backlog. |
| ATL v0 future contract | selected backlog contract with bounded shipped event, trigger, rule-action trigger, movement-reservation, scalar/vector actor handoffs, group metadata, and first temporary trigger-batch leaf | Future leaves reserve qualified endpoints `pins.name`/`actor.port`/`actor.transaction`/`actor.event`/`group.name`, existing drive-body `(sink source)` movement, `(do actor.transaction)`, `(spawn actor.transaction as NAME)`, `(trigger actor.transaction)`, `(await actor.event)`, compact group aliases are shipped as report-only metadata syntax. `connect`, `transfer`, and `move` are not ATL v0 movement syntax. | A top-level transaction-body `(await actor.event)` lowers to a one-bit parent handoff input named `actor_event` and reports through `actor_network.event_waits[]`; single waits are accepted in the selected single-actor/generated-top contexts, and one temporary trigger batch may be followed by a contiguous source-ordered chain of waits to distinct triggered actor instances. A top-level transaction-body `(trigger actor.transaction)` and one top-level rule action `(trigger actor.transaction)` lower to a one-cycle parent output handoff named `actor_transaction_start` and report through `actor_network.transaction_triggers[]`; rule-action entries use `context: "rule_action"` and do not create local rule-trigger fan-in. One or more named drive bodies with one `(sink_actor.endpoint source_actor.endpoint)` pair each plus one top-level drive call each may target two direct static actor instances only when every route shares the same source child, sink child, parent transaction, contiguous route segment, and matching source/sink endpoint widths; each route lowers to one-cycle external parent source/sink handoff ports and reports through `actor_network.data_movements[]` as `scalar_actor_handoff` for one-bit routes or `vector_actor_handoff` for exact-width vector routes. One or more named drive bodies with one `(actor.endpoint pins.input_pin)` scalar pair each plus one top-level drive call each may target one direct static actor instance only when every route shares the same resolved child, parent transaction, unique top-level input pin, unique child input, and contiguous pre-trigger drive-call segment; each scalar route reads the one-bit top-level input pin, drives a generated actor handoff output for that call cycle, and reports kind `scalar_pin_to_actor_handoff`. The generated-child one-route vector pin-ingress subset uses the same `(actor.endpoint pins.input_pin)` spelling when the top-level input pin and child input endpoint widths match exactly; it reports kind `vector_pin_to_actor_handoff` and `width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`. The generated-child vector pin-ingress multi-route subset keeps the same same-child, same-parent-transaction, unique-pin, unique-child-input, contiguous pre-trigger drive-call rules while allowing each route to carry its own exact matching top-input/child-input width; each route reports kind `vector_pin_to_actor_handoff` with the same width source. The generated-child mixed scalar/vector pin-ingress subset keeps those same same-child, same-parent-transaction, unique-pin, unique-child-input, contiguous pre-trigger drive-call rules while allowing scalar one-bit and exact-width vector routes in one route set; each route preserves route-local `kind`, `width`, and `width_source`. One or more named drive bodies with one `(pins.output_pin actor.endpoint)` scalar pair each plus one top-level drive call each may target one direct static actor instance only when every route shares the same resolved child, parent transaction, unique child output, unique top-level output pin, and contiguous post-event drive-call segment; each scalar route reads a generated actor handoff input, drives the one-bit top-level output pin for the call cycle, and reports kind `scalar_actor_to_pin_handoff`. The generated-child one-route vector pin-egress subset uses the same `(pins.output_pin actor.endpoint)` spelling when the child output endpoint and top-level output pin widths match exactly; it reports kind `vector_actor_to_pin_handoff` and `width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`. The generated-child vector pin-egress multi-route subset keeps the same same-child, same-parent-transaction, unique-child-output, unique-top-output, contiguous post-event drive-call rules while allowing each route to carry its own exact matching child-output/top-output width; each route reports kind `vector_actor_to_pin_handoff` with the same width source. The generated-child mixed scalar/vector pin-egress subset keeps those same same-child, same-parent-transaction, unique-child-output, unique-top-output, contiguous post-event drive-call rules while allowing scalar one-bit and exact-width vector routes in one route set; each route preserves route-local `kind`, `width`, and `width_source`. Static `(group ...)` declarations and compact `(concurrent ...)` aliases report `actor_network.groups[]` with `scheduling: "metadata_only"`; verbose groups use `declaration: "group"`, compact aliases use `declaration: "concurrent_alias"`, and neither form is required for temporary associations. The first shipped multi-actor trigger leaf is a same-cycle external trigger batch over contiguous transaction-body `(trigger actor.transaction)` clauses to distinct static actor instances; it reports canonical task-scoped evidence through `actor_network.association_schedules[]` with `kind: "temporary_trigger_batch"` and `lifetime: "task_scoped"`, while preserving `actor_network.group_schedules[]` as a schema-version-1 compatibility view. The shipped multi-event wait widening keeps waits after that trigger batch as explicit sequential wait states, not hidden same-cycle event joins. The first resolved-child generated-top leaf emits one child `.fsm` and one `<parent>_top.fsm` for exactly one resolved child, one parent trigger handoff, and one parent event wait. The first two-child generated-top leaf emits parent, two resolved children, and one generated top for sequential trigger/event handoffs with no data movement, reporting child wiring through `actor_network.generated_tops[].children[]`. The first resolved-child trigger-batch generated-top leaf emits parent, two resolved children, and one generated top for one same-cycle temporary trigger batch followed by source-ordered waits to both triggered children, reporting kind `resolved_children_trigger_batch_event_sequence` plus the existing trigger, wait, association, and compatibility schedule evidence. The first scalar generated-child actor-to-actor route `(writer.payload reader.payload)`, the exact-width vector fixture with the same spelling, and the bounded two-route fixture `(writer.payload reader.payload)` plus `(writer.sideband reader.sideband)` are shipped when called after `reader.done` and before `writer.emit`; route provenance uses existing `actor_network.data_movements[]` and top discovery uses existing `actor_network.generated_tops[]`. Nested waits or triggers, repeated triggers to one instance, repeated rule-action qualified triggers, hidden fan-in/fan-out event joins, payload protocols, cross-clock events/triggers, inline/expression movement, broader generated-child data-route coupling, group endpoints, route mux/storage, and broader group scheduling remain fail-closed. No route mux, broader concurrent-group schedule, or broader HDL event/data wiring is promised until a later implementation leaf advertises it. |
| Single-clock timing | shipped | `(clock clk)` plus optional `(reset ...)` and `(watchdog N)`, where `N` is a positive decimal literal, declared actor constant, actor-local scalar parameter default, or qualified imported package scalar constant that resolves to a positive integer. Omitted legacy single-clock timing defaults to `(clock clk)`, `(reset (rst_n async active_low))`, and `(watchdog 65535)`. | The actor has one clock domain. Resets lower to the matching `.fsm` system reset form. Watchdogs create inferred counters for accepted awaits, with omitted watchdogs normalized to `65535` exactly `(2^16 - 1)` and actor-constant, actor-scalar-parameter, or qualified package-scalar-constant watchdogs reported as resolved integers. |
| Multi-clock domains | shipped bounded surface | Actor-level `(clock-domains ...)` with named domains, one default domain, optional per-domain resets, and `(domain NAME)` ownership annotations. | Lowering partitions the actor into one scheduled `.fsm` per domain plus a generated top. Direct cross-domain reads, writes, activations, and bindings fail closed unless a shipped crossing primitive owns the path. |
| Acknowledged event CDC | shipped bounded surface | `(crossings (event NAME (from SRC SRC_REQ) (to DST DST_PULSE) (ready SRC_READY)))`. | The generated top wires a concrete acknowledged-event CDC child. The source side sees `ready`; the destination side receives a one-cycle pulse. No data payload or same-cycle delivery is promised. |
| Cross-domain activation crossing | shipped bounded surface | `(crossings (activation CHILD (from SRC) (to DST)))` owning a blocking `(do CHILD)` — at the transaction top level, directly inside any top-level body (a `(repeat ...)` body or a `when`/`switch`/`while`/`until` branch body), directly inside a `(repeat ...)` nested in a top-level `when` body or top-level `switch` branch, directly inside a nested `when` chain reached from one of those top-level branch bodies, or directly inside a `(repeat ...)` under that nested `when` chain — where `CHILD` is a transaction in domain `DST` and the caller is in `SRC`. | Lowering auto-generates two acknowledged-event CDC children (start `SRC→DST`, done `DST→SRC`). The caller awaits `<child>_start_ready` then pulses a one-cycle `<child>_start` and blocks on `<child>_done`; the callee is gated on the start pulse and pulses `<child>_done` after awaiting `<child>_done_ready`. The same caller restructure applies in every shipped context (the branch/loop entry, nested repeat entry, or inner `when` branch entry is redirected into the start-ready await); inside a top-level repeat, loop, or branch-contained repeat the full handshake re-runs each iteration and the callee returns to idle between iterations. Full HDL emits the two domain modules, both CDC children, and the top. A cross-domain `(do)` with no covering crossing, a declared-but-unused or mis-placed crossing, cross-domain `(spawn)`, and deeper cross-domain `(do)` placements beyond the shipped contexts fail closed. |
| Interface ports | shipped | `(interface (input NAME [(width N\|PARAM\|CONST\|PACKAGE.CONSTANT)|(type T)] [(domain D)]) (output NAME ...))`, where `PARAM` is an actor-local scalar parameter default, `CONST` is a declared actor constant, and `PACKAGE.CONSTANT` is a qualified imported package scalar constant that resolves to a positive integer. | Ports become scheduled `.fsm` `+size` entries and module ports with resolved positive integer widths. Names are unique across input and output directions. Unknown symbolic width names, unknown/unqualified/aggregate/path package constants, runtime interface signals, zero/non-scalar params, zero-valued constants, ambiguous local-enum/package-constant tokens, and arbitrary width expressions fail closed. |
| Actor-owned scalar storage | shipped | `(storage (var NAME (width N\|PARAM\|CONST\|PACKAGE.CONSTANT) [(reset V)] [(access TOKEN)] [(fields FIELD...)]) ...)` and `(variable NAME (width N\|PARAM\|CONST\|PACKAGE.CONSTANT) [(fields FIELD...)])`, where `PARAM` is an actor-local scalar parameter default, `CONST` is a declared actor constant, and `PACKAGE.CONSTANT` is a qualified imported package scalar constant that resolves to a positive integer. An optional `(reset V)` on a `var` (a non-negative integer literal fitting the width) sets the register's hardware reset value, and optional `(fields (field NAME (bits HI LO) ...))` metadata declares static named bit fields on the parent word. | Storage lowers to internal scalar registers with resolved positive integer widths, contributes width evidence, and appears in reports with role `actor_storage`. A `(reset V)` emits the `+size` carrier `(NAME width (reset V))` so the register resets to `V` (`<sig> <= V` in the HDL reset block), defaulting to all-0s when unspecified. Field metadata is checked and report-only through `inferred_storage[].fields`; optional word access uses the same lowercase vocabulary and is reported independently through `inferred_storage[].access`, without inheritance or access-policy RTL; it does not change scheduled `.fsm`, HDL, access policy, or reset behavior. The support-accounted `isf/storage_fields.isf` fixture covers this surface through pipeline/CLI, check JSON, normalized semantic JSON, and focused schedule JSON report tests. Unknown symbolic names, unknown/unqualified/aggregate/path package constants, ambiguous local-enum/package-constant tokens, runtime interface signals, zero/non-scalar params, zero-valued constants, width expressions, a per-element bank `(reset V)`, over-width or non-integer reset values, malformed/overlapping/out-of-range fields, unsupported field access tokens, field resets without a matching parent reset slice, and enum values outside field width fail closed. |
| Actor-owned banks | shipped bounded surface | `(storage (bank NAME (width N\|PARAM\|CONST\|PACKAGE.CONSTANT) (depth N\|PARAM\|CONST\|PACKAGE.CONSTANT)))` with pointer-selected `(store BANK IDX VALUE)` and `(load BANK IDX as TARGET)`, where `PARAM` is an actor-local scalar parameter default, `CONST` is a declared actor constant, and `PACKAGE.CONSTANT` is a qualified imported package scalar constant that resolves to a positive integer width or depth. | Banks lower to deterministic scalarized entries such as `data_0`, `data_1`, and so on, with resolved positive integer element widths and depths. Same-cycle read/write behavior follows the documented scalarized FIFO path. Unknown/unqualified/aggregate/path package constants, ambiguous local-enum/package-constant tokens, runtime signals, zero/non-scalar params, zero-valued constants, arbitrary expressions, dynamic depths, and duplicate scalarized signal names fail closed. |
| Type aliases and package imports | shipped bounded surface | Actor-local `(types ...)`, actor-local `(enums ...)`, `.fsm` package imports, scalar `(type NAME)` declarations, and actor-owned aggregate storage aliases. Local/imported packed record-input aliases have the separately qualified admission below. | Scheduled `.fsm` preserves `+types`, `+enums`, and `+import` review artifacts. Imported package roots are embedded for CLI HDL generation. |
| Enum member values | shipped bounded surface | Local and package enum members in constants, scalar and aggregate/list parameter leaves, activation overrides, reusable-library use-site overrides, generated child transaction parameter defaults, transaction/rule/drive scalar values, scalar expression operands, switch values/selectors, and standalone conditions/guards. Declared actor constants, earlier scalar actor parameters, and qualified imported package scalar constants may also back actor parameter scalar defaults and actor parameter aggregate/list leaves; declared actor constants, earlier scalar actor parameters, and qualified imported package scalar constants may back generated child transaction parameter defaults; qualified imported package scalar constants may back generated activation parameter overrides, reusable-library use-site overrides, actor top-level interface widths, transaction-local port widths, actor-owned scalar storage widths, actor-owned bank storage widths, and actor-owned bank storage depths; earlier scalar transaction parameters may back later generated child transaction parameter defaults and generated child or direct transaction-port width defaults. | Authored enum, actor constant, earlier actor-parameter, qualified package-constant, or earlier transaction-parameter tokens are preserved where scheduled `.fsm` can carry them; generated child transaction defaults literalize actor-static leaves before child/report publication while preserving child-local transaction dependencies, enum tokens, and qualified package-constant tokens, activation and reusable-library static specialization contexts resolve to literals before generated-top emission, package-constant-backed actor interface, transaction port, scalar storage, bank storage widths, and bank storage depths resolve to integer `+size` and HDL declarations, transaction-parameter-backed transaction ports resolve to integer port sizes and generated parent handoff widths where applicable, and actor-constant-backed, actor-parameter-backed, and qualified package-constant-backed actor parameter defaults resolve internally for scalar parameter consumers. Enum targets and operator-position enum members fail closed. |
| Aggregate scalar leaves | shipped bounded surface | Scalar member/item paths from declared actor-owned aggregate storage in documented RHS, target, guard, condition, switch, drive, and drive-call contexts. | Scalar leaves preserve authored paths in scheduled `.fsm` or lower through computed selector syntax when needed. Packed record-input scalar reads and exact-type input-to-storage copies have the admission below. Whole-record/list conditions or arithmetic, subaggregate writes and aggregate banks remain backlog. |
| Packed record actor inputs | shipped bounded surface | `(input NAME (type T))` for a local or package-qualified packed record alias, supported nested scalar reads/samples, and exact resolved-type copies into owned storage. | T1998 qualifies source admission; T2014/T2015 qualify accepted nested/imported/shadow public sources and imported alias dependencies; T2016/T2017 qualify contextual refusals and frontend closure. T2019/T2021 qualify generated/domain typed carriers and complete accepted/refused public products; current declaration/discovery/prior controls are qualified. Genuine T2024/T2025 observations qualify both emitter options under SystemVerilog parsing; current ISF Verilog requests refuse precisely under T2028; T2027 qualifies precise VHDL profile refusals and retained supported controls. See [types and aggregates](13j-type-enum-aggregate.md), `isf/record_input.isf` and `isf/record_input_children.isf`. Selected R1–R3 input signoff is complete; record outputs and full aggregate consumer delivery remain open; X/Z execution is unclaimed. |
| Transaction entry | shipped | `(transaction NAME (on START ...) body...)`, direct entry samples, transaction ports, and parameter declarations where generated-child behavior owns them. | Entry logic generates start/idle behavior, captures accepted samples, and records transaction order in schedule reports. Unsupported entry-body forms fail closed for both `on` and entry `when`; the latter supports inline samples only. Declarations and zero waits do not establish a preceding branch state. |
| Transaction ports and activation bindings | shipped bounded surface | Transaction `(ports ...)` declarations with `(width N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT)` entries, where `TX_PARAM` is a same-transaction scalar parameter default on a generated child or direct/non-generated transaction, `PARAM` is an actor-local scalar parameter default, `CONST` is a declared actor constant, and `PACKAGE.CONSTANT` is a qualified imported package scalar constant that resolves to a positive integer, plus activation-site `(bind ...)` blocks on `do`, `spawn`, and rule `trigger` where documented. Input bindings may add `(timing snapshot)` for current activation/trigger payload capture or `(timing live)` for current generated-top live handoff wiring. | Direct formals receive private physical storage distinct from actor and sibling declarations; generated ports keep their public names. Ports and handoffs use resolved positive integer widths. Authored binding provenance remains source-facing; independent-controller and local-call execution remain separately gated. Reports expose bounded `transaction_port_bindings[]` provenance, including `actor_endpoint_kind` values `signal`, `literal`, or `expression`, `binding_timing` values `activation_region`, `generated_live_handoff`, `trigger_payload`, or `done_guarded`, and `authored_timing_mode` as `snapshot`, `live`, or JSON null; generated-child rule-trigger output bindings report the done-observer signal that guards the copy back to the actor target. `TX_PARAM` names resolve before actor constants and actor parameters and may derive from earlier scalar transaction parameter defaults. Cross-transaction parameter names, unknown/unqualified/aggregate/path package constants, ambiguous local-enum/package-constant tokens, runtime signals, zero/non-scalar params, zero-valued constants, arbitrary expressions, direct/local rule-trigger output bindings, behavior-changing snapshot-vs-live timing conversion, and mismatched timing mode/site combinations remain backlog or fail closed. |
| Transaction assignments | shipped | `(set TARGET EXPR)` and `(update VAR EXPR)` with scalar targets and expression payloads in the documented value domain. | Assignments lower to scheduled `.fsm` state assignments with correct flopped/combinational semantics for the form. Scalar aggregate leaves and enum members are accepted only in shipped contexts. |
| Runtime expression divisor safety | shipped bounded surface | Division and modulo in shipped runtime expression contexts such as transaction RHS, wait counts, activation input bindings, rule guards/actions, drive bodies/calls, inline drives, and bank access index/value expressions. | Numeric/exact-width literal-zero, actor-constant-zero, actor-parameter-zero, and same-transaction-parameter-zero divisors fail closed before scheduled `.fsm` emission. Nonzero literal, actor-constant, actor-parameter, same-transaction-parameter, and dynamic scalar divisors lower unchanged; full dynamic nonzero proof and use-site-specialized parameter divisor proof remain backlog. |
| Named and inline drives | shipped | Actor-level `(drive NAME [(PARAM ...)] body...)`; transaction body `(drive NAME actual...)`; inline drive assignments where documented. | A named drive emits a non-state DT. A drive call consumes one state and transfers actuals through generated drive parameter signals. Inline drive assignments become state assignments. |
| Await and latency | shipped | `(await PORT)`, top-level await-local `(watchdog N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT)` overrides where each bound resolves to a positive integer, actor watchdogs using positive decimal literals, declared positive actor constants, actor-local scalar parameter defaults, or qualified imported package scalar constants, and transaction `(latency (min N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT) (max N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT))` where each latency bound resolves to a positive integer. | Awaits lower to wait/test states and watchdog counters when configured. One transaction has one watchdog counter, so distinct per-await limits in one transaction fail closed. Latency counters and schedule-report storage metadata are emitted for the supported shapes. Transaction parameter top-level await-local watchdog limits and latency bounds shadow actor-level static names and remain local lowering inputs. Generated child activation overrides for watchdog/latency timing parameters are accepted only when they preserve the child default value; mismatches fail closed. Runtime signals, arbitrary expressions, unknown symbols, unknown/unqualified/aggregate/path package constants, zero-valued constants, zero-valued or non-scalar actor/transaction parameters, actor-level or nested control-flow transaction watchdog parameters, and cross-transaction parameters fail closed as latency bounds or watchdog limits. |
| Static and dynamic waits | shipped bounded surface | `(wait N)`, `(wait 0)`, actor-constant wait counts, actor-parameter wait counts, same-transaction scalar parameter wait counts, qualified package scalar-constant wait counts, accepted runtime wait count expressions, consecutive runtime waits, bank access predecessors, loop-control false-edge predecessors, and pending-sample runtime waits in documented contexts. | Static waits create explicit wait states unless zero-count bypass semantics apply. Runtime waits use generated counters. Transaction parameter waits shadow actor-level static names in their owning transaction and remain local lowering inputs. Generated child activation overrides for wait-count transaction parameters are accepted only when they preserve the child default value; mismatches fail closed. Bank `load`/`store` predecessors keep their guarded scalarized assignments while splitting the following runtime count edge. `(exit-when ...)` and `(continue-when ...)` loop-control states preserve their true exit/continue edge while splitting only the false fallthrough edge to a following runtime wait. Pending samples use a first active wait state on positive paths and sample-preserving zero-count clones for compatible successors such as drives, awaits, static waits, completion, independent scalar setters, independent shifts, independent assemble states, independent extract states, independent bank loads, independent bank stores, top-level await_all/await_any sync states, top-level spawn states, top-level transaction phase states, top-level ready/valid stages, top-level monitor arm states, and loop decision states. Consecutive top-level runtime waits carry pending samples through zero-count links with generated downstream wait-entry clones when needed. |
| Declared local variables | shipped bounded surface | `(local NAME (width N))` declares an internal register at an explicit width. Separate physical ownership for same-named explicit locals in different direct transactions remains under scope qualification. | The local is emitted in the module `+size` block at the declared width and is readable/writable in the transaction body (pinning the width vs. an inferred implicit internal scalar). A `(local ...)` whose name is invalid or collides with an interface port, or whose `(width N)` is missing or non-positive, fails closed. Options must be exact width/default/init/reset pairs, with no duplicates (default/init share one initialization slot); unknown options and missing/extra values fail closed. An optional `(default V)` (synonym `(init V)`; a non-negative integer literal fitting the width) initializes the local on transaction entry (a transaction-local is re-initialized each run); an out-of-range or non-integer value fails closed. An optional `(reset V)` sets the local's **hardware reset value** (orthogonal to `(default V)`): it emits the `+size` carrier `(NAME width (reset V))` so the register resets to `V` through hardware reset (`<sig> <= V` in the HDL reset block), defaulting to all-0s when unspecified (byte-identical to before); an over-width or non-integer reset value fails closed. `(let NAME EXPR)` names an intermediate value by pure substitution (NAME -> EXPR in the rest of the scoped body; no register, no cycle), failing closed on a redefinition or an interface-port-name collision. |
| Reusable procedures | shipped bounded surface | `(proc NAME (params PARAMSPEC...) BODY...)` defines a reusable parameterized block; a `PARAMSPEC` is `(P (width N))` (an in/value parameter) or `(out P (width N))` (a write-back parameter). `(call NAME actuals...)` calls it INLINE — one positional actual per parameter. | The inline call macro-expands the procedure body at the call site with each parameter replaced by its actual; an in-parameter accepts a signal OR a whole expression, an out-parameter requires a plain signal lvalue the procedure writes into (the caller picks the destination per call). The emitted `.fsm` is identical to the hand-written substituted clauses (no instance, no handshake). Calls work in any clause position, including `when`/`switch`/`while`/`until` bodies. Recursion (direct or transitive), unknown procedure, argument-count mismatch, an expression passed for an out-parameter, and malformed `(proc ...)` fail closed. The handshake call form `(call NAME actuals... as INST)` synthesizes the procedure as a one-shot child transaction (in-params -> input ports, out-params -> output ports) and drives it with the bound `(do)` handshake (the call site binds the arguments, pulses start, blocks on done, reads the out-arguments); the `as INST` suffix picks the handshake convention over inline. A handshake `(call ... as)` missing its instance name, or a handshake procedure whose name collides with an existing transaction, fails closed. |
| Transaction control flow | shipped bounded surface | Body-bearing `(when COND body...)`, `(switch SELECTOR branches...)`, `(while COND body...)`, `(until COND body...)`, and `(repeat COUNT body...)`; repeat `COUNT` may be a non-negative literal, same-transaction scalar parameter default, non-negative actor constant, non-negative actor-local scalar parameter default, qualified package scalar constant, or known-width runtime name. A `(exit-when COND)` mid-loop early exit and a `(continue-when COND)` skip-to-next-iteration are accepted directly inside a `while`/`until` body. A `(for (i N) body...)` indexed counted loop (at the transaction top level, directly nested inside another `(for …)` body for nested loops, or embedded in a `when`/`switch`/`while`/`until`/`repeat` body) exposes a 0-based loop index `i` (counting `0 … N-1`) to its body; `(for (i N) ...)` takes a literal `N >= 1` (auto-sized index), `(for (i (width W) N) ...)` takes an explicit index width `W` with any count the counted `(repeat ...)` accepts (literal, parameter, constant, or runtime scalar), and `(for (i from A to B [step S]) ...)` counts `i = A, A+S, … < B` (literal `A`, `B`, `S` with `B > A`, `S >= 1`; `S` defaults to 1). A `(cond (c body...)... (else body...))` if/else-if/else priority chain runs the first branch whose condition holds (the optional `else` when none do). | Control flow lowers to explicit decision states, branch states, loop counters, and exits. A counted `(repeat N body...)` lowers check-first — the counter is loaded once and the per-iteration check exits when it reaches zero and otherwise decrements and runs the body — so the loop runs exactly `N` times and completes. A `(cond ...)` desugars (before for/let/proc expansion) into a `when`-chain with accumulated negated guards — branch `i` becomes `(when (& (! c1) … (! c(i-1)) ci) body…)` and the `else` gets the all-negated guard — so the first true branch wins; `else`-not-last, a missing condition, or an empty branch body fail closed. A `(for ...)` desugars in the parser (before procedure/`let` expansion) into a declared index `(local i (width W) (default START))` (START is `0`, or `A` for the range form) plus a counted `(repeat COUNT body... (set i (+ i 1)))`; a nested or embedded `(for …)` hoists its index local(s) to the transaction top (resetting the index per enclosing entry) and lowers to a nested counted `(repeat …)` (distinct counters). A zero width, a literal-zero or implicit-width-non-literal count, a non-upward range (`B <= A`) or non-literal range bounds, and an empty body fail closed. A leading runtime `(wait ...)` in a repeat body is supported by the repeat-check loop-back split: repeat-counter zero exits, repeat-counter nonzero plus positive wait count loads and enters the generated wait, and repeat-counter nonzero plus zero wait count bypasses to the following body state or a sample-compatible zero clone. A `(exit-when COND)` lowers to a decision state whose true edge takes the enclosing loop's exit target and whose false edge continues to the next body clause; a `(continue-when COND)` is the same but its true edge takes the loop's tail check (re-evaluate the condition). When a following body clause is a runtime `(wait ...)`, that false edge splits into generated counter load/entry and zero-count bypass paths under `!COND`, while the true edge remains the exit/continue target. Both fail closed outside a `while`/`until` body (top-level, `repeat`, `when`/`switch`). Positive static repeat counts provide counter-width evidence and use the documented load-token policy; known-width runtime scalar repeat counts bypass the body and repeat check when the runtime value is zero. Static zero counts lower as transparent no-op regions with no counter, repeat init/check state, repeat-body state, or `transaction_loops[]` entry; static-zero repeat-body `do` and `spawn` child activations, including syntactically valid parameterized, bound, or domain-annotated variants, are pruned with no generated child/top or local handoff artifact when their targets are not otherwise live. Malformed activation subclause syntax, unsupported count sources, cross-transaction parameters, non-scalar parameter sources, unqualified or aggregate package constants, package member/item paths, package constants inside expressions, and arbitrary expressions fail closed. The shipped repeat-body clause surface is limited to the documented drive, await, sample, update, set, shift, assemble, extract, store/load, wait, local/generated blocking do, generated spawn, same-body sync, source-order sample, static parameter/binding handoff, same-domain metadata, a nested counted `(repeat …)` (each repeat instance gets its own counter — the outermost keeps `<tx>_cnt`, a nested repeat uses a unique `<tx>_cnt_<n>` — so a `(repeat M (repeat N body))` runs the body `M*N` times), and bounded when/switch nested repeat subsets described in the transaction chapter. |
| Transaction stages | shipped bounded surface | Top-level `(stage NAME (ready READY) (valid VALID))` transaction clauses; `(input READY)`/`(output VALID)` remains an alias. | A stage lowers to one ready/valid barrier state that drives `VALID` while active and advances only when `READY` is true. Actor-level phase/stage metadata is report-visible but has no runtime scheduling semantics yet. The valid drive remains subject to same-target conflict checks. |
| Temporal contracts | shipped bounded surface | The bounded-eventually monitor `(assert (monitor (within SIGNAL N)) ["NAME"])` placed in a transaction body: from the cycle control reaches that clause, SIGNAL must hold within N cycles. N may be a positive integer literal, a declared actor constant, an actor-local scalar parameter default, a qualified imported package scalar constant, or a same-transaction scalar parameter default that resolves to a positive integer. (Replaces the former top-level `(contract …)` clause, removed in favor of this unified verification surface.) | Lowering injects an arm state at the clause position plus an arm/pending/age/fail monitor (storage role `temporal_contract_monitor`) in the scheduled `.fsm`, and asserts the negated fail bit as a same-cycle clocked concurrent property — so the temporal bookkeeping is synthesizable hardware and the assertion is verilator-simulable. Direct transaction parameters are local lowering inputs, not actor-level `.fsm` `+params`. SystemVerilog emits the assertion under `` `ifndef SYNTHESIS ``; Verilog output stays assertion-free. Runtime signals, arbitrary expressions, unknown names, unknown/unqualified/aggregate/path package constants, ambiguous local-enum/package-constant tokens, zero-valued constants, and zero-valued or non-scalar actor/transaction parameters fail closed as monitor windows. |
| Immediate verification checks | shipped bounded surface | Transaction-level `(assert COND [message])` / `(assume COND [message])` / `(cover COND [label])` — a clocked check; `COND` is any boolean expression over actor signals, or a temporal **property** — overlapping implication `(=> A B)` → SVA `(A) \|-> (B)`, the delay combinators `(next X)` / `(within X N)` / `(within X MIN MAX)`, the event/named trigger anchors `(after …)` / `(at …)`, the bounded-eventually monitor `(monitor (within S N))`, the SystemVerilog sampled-value predicates `(stable SIG)` / `(changed SIG)` / `(rose SIG)` / `(fell SIG)` → `$stable`/`$changed`/`$rose`/`$fell(SIG)`, and value-returning `(past SIG [N])` inside boolean property expressions such as `(== data (past data))` → `$past(SIG[, N])` — with an optional trailing message/label string. | A pure ISF family that rides the ISF → `.fsm` → SV path as a thin `+assert` carrier (each entry kind-tagged `assert`/`cover`/`assume`): the ISF lowerer emits `(+assert (NAME KIND COND ["msg"]) …)`, FSMGenFull parses it onto the module, `GeneratedModuleInfoBuilder` surfaces it into `module_info`, and `GeneratedModuleEmitter` emits, inside `` `ifndef SYNTHESIS ``, a **clocked concurrent property** per check — `assert property (@(posedge clk) disable iff (reset) (COND)) else $error("message")`, the `assume` mirror, or `cover property (@(posedge clk) disable iff (reset) (COND));` (a name-based default `$error` message for assert/assume when none is given; reset gating and clock-edge sampling are the synchronous-correct semantic; it falls back to an immediate combinational check only when the module has no clock). A `COND` that is a property combinator is parsed (FSMGenFull) into a tagged property tree over boolean leaves and rendered to SVA: `(=> A B)` → `(A) \|-> (B)` (overlapping implication), with a delayed consequent `(next X)` → `##1 (X)` and `(within X N)` → `##[1:N] (X)` (literal `N >= 1`) and `(within X MIN MAX)` → `##[MIN:MAX] (X)` (literal `1 <= MIN <= MAX`, the `min > 1` bounded window; `MIN = 0` fails closed). When compiler-generated intermediates are inlined into a check, each replacement remains one explicitly grouped SV subexpression, so nested mixed-precedence expressions such as `high & (bit3 | bit2)` preserve their CoreAST meaning inside direct and temporal leaves. The SystemVerilog **sampled-value functions** include boolean leaves `(stable SIG)` / `(changed SIG)` / `(rose SIG)` / `(fell SIG)` → `$stable(SIG)` / `$changed(SIG)` / `$rose(SIG)` / `$fell(SIG)` (one signal each, usable standalone or as an `=>`/`after` antecedent/consequent) plus property-expression value calls `(past SIG)` / `(past SIG N)` → `$past(SIG)` / `$past(SIG, N)` (`N` a literal integer >= 1). They are not `##` sequences, so they stay verilator-simulable; they are property-only, so they fail closed in a synthesizable expression position. A check with a delayed (`##`) consequent is **formal-only** — verilator cannot simulate it — so it is emitted under `` `ifdef FORMAL `` (formal tools check it; verilator/yosys skip it, so `--verify-hdl` stays green), while boolean / overlapping-implication checks stay under `` `ifndef SYNTHESIS `` and are verilator-simulable. Signals referenced only by a check, including through `$past`, are kept alive as ports (classified `INPUT` by that reference, not pruned). Verilog (non-SV) output stays assertion-free; `yosys` skips the guarded block. A missing condition, extra operands, non-signal `past` operand, or nonpositive/nonliteral `past` depth fails closed. The bounded-eventually `(assert (monitor (within …)))` monitor rides this same `+assert` path. |
| Data manipulation | shipped bounded surface | `(select DST COND A B)`, `(max DST A B)`, `(min DST A B)`, `(swap A B)`, `(incr NAME [by N])`, `(decr NAME [by N])`, `(set-bit NAME N)`, `(clear-bit NAME N)`, `(toggle-bit NAME N)`, `(set-field NAME (bits HI LO) VALUE)`, `(when-bit NAME N body…)`, `(unless-bit NAME N body…)`, `(when-field NAME (bits HI LO) VALUE body…)`, `(unless-field NAME (bits HI LO) VALUE body…)`, `(shift_left REG BIT [(width N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT)])`, `(shift_right REG BIT [(width N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT)])`, `(rotate-left REG [by N])`, `(rotate-right REG [by N])`, `(assemble PART... as TARGET [(widths N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT...)])`, and `(extract WORD as FIELD... [(widths N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT...)])`. | `(select DST COND A B)` is a pure parser desugar (after the cond/for/let/proc passes) into two mutually-exclusive conditional sets — `(when COND (set DST A)) (when (! COND) (set DST B))` — so `DST` takes `A` on the true path and `B` on the false path (two sequential decision states; `.fsm` has no ternary operator). Place a scheduled entry before `select`: a first-operation expansion currently reaches the sample-only entry guard and refuses, with source-intent repair owned by SEM `.60.4.3.3.5.2.1.5`. First sample-only conditional bit/field/cond shorthand can still admit as activation rather than branching; use explicit activation before it. Inline procedure `cond` remains unexpanded and refuses; explicit source intent `.5.2` must precede safe normalization `.5.4.2`, since a standalone candidate newly admits first sample bodies as activation. These are existing ISF/IAL1 parser/scheduler repairs; a missing register name or anything other than exactly four operands fails closed. `(max DST A B)` / `(min DST A B)` desugar onto `(select DST (>= A B) A B)` / `(select DST (<= A B) A B)` (the larger / smaller of two values); a clamp composes as `(max v v lo)` then `(min v v hi)` (sequential writes, each with its own enable); a missing name or other than exactly three operands fails closed. `(swap A B)` desugars into the temp-free XOR swap — `(set A (^ A B)) (set B (^ A B)) (set A (^ A B))` — exchanging two distinct registers (`A`'s two writes get distinct enables); a non-two-register form or `A == B` fails closed. `(incr NAME [by N])` / `(decr NAME [by N])` are a pure parser desugar (after the cond/for/let/proc passes) into `(set NAME (+ NAME N))` / `(set NAME (- NAME N))` with `N` defaulting to `1` (a literal, signal, or expression) — valid anywhere a `(set …)` is, at the top level and in control-flow bodies; a missing name or a malformed `by` fails closed. `(set-bit NAME N)` / `(toggle-bit NAME N)` / `(clear-bit NAME N)` are a pure parser desugar (same staging) into a single-level masked `(set …)` — `(\| NAME 2^N)`, `(^ NAME 2^N)`, and `(& NAME ((2^width-1) ^ 2^N))` respectively — for a literal bit index `0 <= N < width`; set/toggle masks are width-independent, while `clear-bit`'s inverse mask is formed from the register's declared literal width (resolved from a `(local …)`, a transaction formal port, an actor interface port, or a `(storage (var …))`, in that precedence order; unresolved formal/type widths never borrow actor widths or use type placeholders). A missing name, a missing / non-integer / out-of-range bit index, or (for `clear-bit`) a non-literal/symbolic width fails closed. `(set-field NAME (bits HI LO) VALUE)` is a pure parser desugar (same staging) into a sized masked read-modify-write `(set NAME (\| (& NAME W'dCLEARMASK) W'dSHIFTED))` — `CLEARMASK = (2^width-1) ^ (((2^(HI-LO+1))-1) << LO)`, `SHIFTED = VALUE << LO` — for literal `HI >= LO`, `HI < width`, and a literal `VALUE` fitting the field; the sized literals require the register's literal width, and a missing name / malformed `(bits …)` selector / non-literal bounds-or-value / reversed bounds / out-of-range `HI` / field overflow / symbolic width fails closed. `(when-bit NAME N body…)` / `(unless-bit NAME N body…)` are a pure parser desugar (before the compound/bit-op passes, so a `(set-bit …)`/`(incr …)` in the body still expands) into a `(when …)` with a width-qualified masked comparison — `(when (!= (& NAME W'dMASK) W'd0) body…)` and `(when (== (& NAME W'dMASK) W'd0) body…)` respectively — for a literal index `0 <= N < width`; the sized mask needs the register's literal width, and a missing name / non-integer or out-of-range index / empty body / symbolic width fails closed. `(when-field NAME (bits HI LO) VALUE body…)` / `(unless-field NAME (bits HI LO) VALUE body…)` generalise the bit test to a multi-bit field, desugaring (same staging) into `(when (== (& NAME W'dFIELDMASK) W'dSHIFTED) body…)` and `(when (!= …) body…)` respectively — `FIELDMASK = ((2^(HI-LO+1))-1) << LO`, `SHIFTED = VALUE << LO` — for literal `HI >= LO`, `HI < width`, and a literal `VALUE` fitting the field; a missing name / malformed `(bits …)` selector / non-literal bounds-or-value / reversed bounds / out-of-range `HI` / field overflow / empty body / symbolic width fails closed. Because they lower to an expression `(set …)`, a register written by two+ expression `(set …)`s across different states of one transaction (e.g. two literal `(incr x)` in a row, or two `(set-bit …)` on the same register) runs as that many sequential states, each driving its own distinct write-enable, so the writes compose in order. Width evidence comes from declarations, samples, operation-local options, and structural derivation. Operation-local width options accept positive integer literals, same-transaction scalar parameter defaults on generated child or direct/non-generated transactions, actor-local scalar parameter defaults, declared actor constants, or qualified imported package scalar constants that resolve to positive integers. `shift_left` can accept optional width evidence without requiring it for plain shifts; `shift_right` uses width evidence for the inserted MSB position. `(rotate-left REG [by N])` / `(rotate-right REG [by N])` are a pure parser desugar into a single masked shift-OR `(set REG (\| (<< REG N) (>> REG (W-N))))` (and the mirror) for a literal amount `0 < N < width` (default 1); the counter-shift amount needs the register's literal width, and a missing name / malformed `by` / out-of-range amount / symbolic width fails closed. `assemble` can accept ordered explicit part widths and can infer exactly one missing part width from a known target and known siblings; `extract` can infer exactly one missing destination field width from a known source and known siblings. Accepted forms avoid placeholder widths in scheduled `.fsm` review artifacts and publish known-width storage metadata; ambiguous, non-positive, unsupported package, runtime, unrelated or cross-transaction parameter, expression, activation-site override-specialized, or contradictory widths fail closed. |
| Rules and trigger fan-in | shipped | Shorthand and long-form `(rule NAME GUARD actions...)`, `(set TARGET EXPR)`, shorthand assignments, and `(trigger TRANSACTION ...)`. | Rules lower to non-state DTs with guarded assignment semantics. Trigger sources feed a generated transaction fan-in or generated-child trigger handoff for parameterized triggers. |
| Rule conflicts and priorities | shipped bounded surface | Same-target/same-value rule writes, conservative mutual-exclusion proofs, rule-local priority, actor-level rule/rule priority, actor-level rule-over-transaction priority, and actor-level transaction-over-rule priority for the covered same-target data case, including a named drive with exactly one distinct local transaction caller and no generated caller. | Compatible writes are accepted, priority can suppress lower-priority conflicting assignments in the documented cases, and unresolvable conflicts fail closed. Unique-caller named-drive suppression is target-local in both directions; prioritized shared/generated/mixed drive ownership fails closed, while unprioritized ambiguous/unused overlap remains explicitly `not_doable`. Transaction-over-rule uses scheduled `.fsm` `state_active` or named-drive activation guards instead of fake state-enable input ports. SystemVerilog gets verification-only selector assertions for analyzed muxes. |
| Resources | shipped bounded surface | `(resources (resource NAME (kind rule_slot\|output_bundle\|transaction_start\|storage_port) (arbiter priority) [(members OUTPUT_OR_STORAGE_SIGNAL...)] (users RULE...)))`, plus `(resource NAME (kind rule_slot\|output_bundle\|transaction_start\|storage_port) (arbiter round_robin) [(members OUTPUT_OR_STORAGE_SIGNAL...)] (users RULE...))`. For `transaction_start`, `NAME` is the target local transaction. `storage_port` requires explicit concrete actor-owned storage members when users are bound. Parser-recognized backlog kinds are documented. | `rule_slot`, `output_bundle`, `transaction_start`, and `storage_port` plus `priority` arbitration gate the whole bound rule DT for one cycle. The same four kinds plus bounded `round_robin` emit a generated pointer counter, grant the first requesting rule at or after that pointer, and advance the pointer from the winning rule DT. Unmembered `output_bundle` resources keep the implicit bound-rule output/LHS-target surface; explicit output-bundle members are declared actor outputs or concrete actor-owned storage signals and keep `resource_arbitration[].members` report evidence under both priority and round-robin. `storage_port` members are concrete actor-owned storage signals only and keep the same mandatory member validation/reporting under both priority and round-robin. Explicit members validate against bound rule writes in those domains. `transaction_start` priority grants suppress lower-priority rule triggers before the generated trigger fan-in DT; bounded round-robin grants gate trigger-source rule DTs before that same fan-in path. Backlog resource kinds, unsupported arbiter/kind combinations, `round_robin` on backlog resource kinds, generated-child transaction starts, generated-child storage arbitration, actor-network trigger resources, bank-root/aggregate/inferred explicit members, output-target users, storage locks, lifetime ownership, and route mux/storage fail closed or remain deferred. |
| Blocking child activation | shipped bounded surface | `(do child)`, `(spawn child as inst)`, `await_all`, and `await_any` are shipped by construction in the documented top-level, top-level repeat, top-level branch/loop, loop-contained repeat, deeper branch-contained repeat, and top-level `when`/`switch` nested-repeat contexts. Source-order samples before or after repeat-body do before the repeat check stay covered by the same child-lifetime rule. Local `do`, generated-child `do`, static-parameter generated `do`, optional bind handoffs, same-domain metadata, and generated `spawn` may compose in those contexts only when the same-body proof rule owns the child lifetime: local or generated blocking calls must consume their own fresh done handoff, generated instances must have deterministic static top wiring, every pending generated-spawn done set must be observed only by `await_any` and drained by a later exact same-body `await_all`, and repeat/loop/branch re-entry must see no outstanding child completion. | Lowering emits parent, child, and generated top scheduled `.fsm` artifacts as needed. Reports expose instance start/done handoffs, named-drive and binding handoffs, parameter overrides, generated-composition metadata, and clock-domain ownership metadata as bounded review surfaces. Top-level and branch-contained repeat-body spawn reuses static generated instances across iterations after `await_all`, single-pending `await_any`, or multi-pending `await_any` followed by same-body `await_all` proves all outstanding children fresh and drained. Loop-contained local-do fanout has no public child-count cap once exact-set proofs hold. Cross-domain activation without an explicit crossing, missing same-body drains, dynamic child specialization, implicit CDC, generated `do` while spawned children are pending in loop-contained repeats, deeper branch/loop placements beyond the documented contexts, and broader outstanding-child lifetime semantics remain fail-closed. |
| Spawned generated children | shipped bounded surface | `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` is shipped in the documented top-level repeat, top-level branch, loop-contained repeat, deeper branch-contained repeat, and top-level `when`/`switch` nested-repeat contexts when the same-body drain rule owns the generated-child lifetime. Source-order samples before or after a spawn, static parameter overrides, bind handoffs, and same-domain metadata are accepted only in the documented contexts with deterministic generated-top wiring. | Lowering creates static generated child instances and wires start/done plus optional parameter/binding handoffs through the generated top. `await_all` drains the exact outstanding generated-child set; single-pending `await_any` may complete the one-child set; multi-pending `await_any` is observation-only and requires a later same-body `await_all` drain. Missing drains, parent-body sync after repeat exit, cross-domain `spawn`, dynamic per-iteration specialization, implicit CDC, and broader generated-child lifetime semantics remain fail-closed. |
| Reusable ISF libraries | shipped bounded surface | `(library NAME (exports (actor A)) (actor A ...))`, actor `(imports (library NAME as ALIAS))`, and `(use ALIAS.actor as INSTANCE (params ...) (bind ...))`. Use-site parameter overrides may use literals, importing-actor constants, importing-actor scalar parameter defaults, enum members, qualified imported package scalar constants, and compatible aggregate/list literals with those scalar leaves. | Library use lowers to generated composition artifacts and report `library_uses[]` metadata with literalized override values, including package-constant-backed use-site overrides. The shipped catalog includes `common.fifo.fifo`; parameter-driven shape elaboration and nested library imports remain backlog. |
| Schedule reports | shipped bounded surface | `--emit-schedule-json` and in-process `report(...)`. | Reports expose actor, transaction, storage, rule, drive, static actor-network, generated-composition, library-use, clock-domain, crossing, issue, schema-version, and public-contract metadata only through bounded documented keys. |
| Schedule report schema and storage roles | shipped bounded surface | Schedule JSON `schema_version: 1`, public `schedule_report_full_schema_stable`, advertised key/value families, and `inferred_storage[].kind`/`role` values. | The version-1 schedule JSON schema is stable through the public contract. Storage roles include dynamic waits, activation handoffs, ATL trigger-start handoffs, scheduler timeout-status latches, rule-trigger sources, transaction ports/bindings, temporal contract monitors, and resource round-robin pointers. Raw parser actor hashes, private `LoweringIR` internals, raw assignment lists, and recursive child report dumps remain private. |
| Diagnostics and downstream issue reporting | shipped | Fail-closed parser/lowering diagnostics, strict-mode compatibility cuts, `--check --json` / `--check-json` failure payloads, and `bin/fsmgen-issue-bundle`. | Unsupported public forms reject before misleading artifacts are emitted. For `.isf` inputs, parser, lowering, report-building, and semantic check failures emit `success: false` JSON in check mode instead of empty stdout. Downstream consumers can provide a reproducible issue bundle without understanding `.fsm` or `.isf` internals. |

Conditional source-intent qualification is private preparation. Separate
source/document/file observers retain authored operations, inline call sites and
selected use/ATL identities while preserving complete ordinary actors. A local
formal observer now follows the actual preparation clones and clause resolver:
`select` and authored `when` can produce identical physical clauses while their
original catalog and call identities remain distinct. It preserves explicit
input/output formal identities through sibling and actor-pin shadows, nested
clauses and inline calls. Complete ordinary preparation, physical actors, plans
and primitive kinds agree; missing associations and forged reloads refuse.
The local formal reload helper and residual constructor assertion compare the
complete declared first cause. Permanent real-producer controls reject unrelated
parser errors that quote a source label and JSON encoding errors that quote an
object's class name. The [complete-cause repair](reference-source/docs/audits/local-formal-helper-cause-repair-20261003/scope.txt.source.txt)
qualifies these boundaries with whole ordinary products and primitive kinds,
the exact prior helper, and an actual source-authentication bypass. Intentional
stack evidence remains separate: Perl stacks can echo caller patterns.
Broader helper and cold consumer qualification remains open. The initial invalid
network fixture falsely passed a full-stack match; a valid instance fixture and
a genuine echoed-regex control now qualify that boundary. Earlier evidence
remains archived as superseded.
The file-origin and library-document helpers now compare complete declared
first causes. Their original actors/proofs, primitive kinds and boundary reasons
are requalified by independent source oracles and genuine caller-echo,
source-label echo and source-comparison controls. Other diagnostic consumers
remain under audit.
The wider review tracks ordinary, delegated and structured assertions;
source discovery alone does not qualify their causes. The private inventory
preserves JSON primitive kinds (`true` cannot replace numeric `1`) and exact
canonical numeric forms.
Actual source-label probes now show why first-line selection is insufficient:
`Error: no (actor ...) root found` quotes the label, which can contain a wanted
refusal phrase. Seven constructor assertion sites now compare their complete independently
declared first causes, with real comment/label echo regression controls. The
library/file helpers now use the same complete-cause predicate and permanent
real-label controls. Actual validator/finalizer probes also reproduce unrelated
argument failures echoed through Carp and earlier parser failures quoting wanted
text in source labels. The original generic origin-category assertion accepted a
Perl type failure quoting that category in its primary message. Those confirmed
validator/finalizer assertions now compare complete causes, including specific
reasons for each generic mutation. Permanent real producer controls reject
argument, comment and label echoes; replaying the exact prior consumers fails
those controls. The historical raw source-origin assertion cohort is reconciled;
other helper/structured/trace sites and wider current/cold consumers remain
under audit. These corrections change verification, not public ISF admission.

The historical named discovery contains 244 lexical spans, including 24 named
span instances across nine distinct function names. Its original “24 prefixes”
label conflated units; that archive remains immutable. At revision `fe8c412a`, the map
binds 2,542 current Perl source files and 57 line-anchored named-definition tokens,
plus same-file identifier occurrences and whole source contexts. All historical
span names have one current definition locator in their respective files.
These are lexical tokens, including possible strings/comments; they do not count
parsed functions or calls and establish no semantic safety. The local-formal
helper delegates its diagnostic predicate and was outside the old filtered named
cohort. Its complete-cause repair is qualified within its declared scope.
The formal source-context helper now compares complete first causes. Its live
binding control uses the documented static parameters and reaches the intended
port check; the earlier static-parameter restriction has a separate exact
refusal. Real parser/source-comment controls, the exact prior consumer and a
genuine binding-validation bypass qualify the
[source-context repair](reference-source/docs/audits/formal-source-context-cause-repair-20261003/scope.txt.source.txt).
Whole ordinary products and primitive kinds are conserved within the prior
source-bound scope; wider internal product semantics remain under cold review.
The caller-formal-binding helper now compares complete declared causes for
caller width precedence, actor restrictions, callee ports and roles, timing,
duplicates and live endpoints. Real earlier binding-shape errors and labels
containing wanted text fail its predicate. The exact prior helper reproduces
false stack matches, and a genuine validation bypass makes the repaired test
fail. The [binding-helper repair](reference-source/docs/audits/caller-formal-binding-cause-repair-20261003/scope.txt.source.txt)
conserves whole ordinary products and primitive kinds within the declared
source and binding-report scope; wider internal semantics remain under cold review.
A [cohort handoff](reference-source/docs/audits/residual-named-helper-cohorts-20261003/scope.txt.source.txt)
assigns review owners for formal/resource, aggregate-record, public-query,
process/governance, producer-role and backend/native review. Formal resource,
reusable and reservation review now closes with the repairs below. The
[aggregate-record review plan](reference-source/docs/audits/aggregate-record-helper-plan-20261003/scope.txt.source.txt)
assigns a bounded source-contract review to every selected record helper before
native probes; actual causes, products, copy kinds and native applicability remain
open. Names do not establish
actual refusal-consumer roles or native applicability.

The [interface-metadata helper contract](reference-source/docs/audits/interface-metadata-helper-contract-20261003/scope.txt.source.txt)
binds its callback sites and adjacent assertions. Its [native profile](reference-source/docs/audits/interface-metadata-runtime-20261004/scope.txt.source.txt)
records complete API, copy, error, warning and assertion streams. A real Storable
error passes the generic context check when the module path contains the wanted
prefix. An adjacent output-writer assertion accepts a different parser error when
the source filename contains its wanted phrase. Both complete-cause repairs below now close these test-assurance defects. Existing public metadata qualification retains its finite scope;
provider behavior and public admission are unchanged.
The [field qualification](reference-source/docs/audits/interface-metadata-fields-20261004/scope.txt.source.txt)
binds every observed width change to declared local/imported types and checks
complete numeric metadata results. Private validation copies may hold decimal
strings before numeric rebuilding. The [actual copy controls](reference-source/docs/audits/interface-metadata-copy-controls-20261004/scope.txt.source.txt)
show that scalar-preserving copies conserve ordinary products. The old test
still passes a caller number-to-string mutation, an aliased fixture copy and a
real numeric-rebuilding bypass. The [copy-assurance repair](reference-source/docs/audits/interface-metadata-copy-repair-20261004/scope.txt.source.txt)
now checks complete fixture kinds, sharing, reference counts and isolation.
Typed graph baselines check caller immutability, and complete metadata products
retain numeric widths, signed flags and packed ranges. The genuine kind,
alias, Storable-restoration and numeric-bypass controls now fail the intended
assertions; ordinary products and primary causes remain the same. The actual
rejected cyclic type also copies without sharing caller references.
The [complete copy join](reference-source/docs/audits/interface-metadata-copy-join-20261004/scope.txt.source.txt)
binds original and repaired copy populations to their source fields and final
products. Preserving numeric test seeds makes some private clones stringify
additional numeric leaves; final numeric metadata and caller graphs remain
the same. Private validation copies remain distinct from product authority.
The [source/product closure](reference-source/docs/audits/interface-metadata-source-product-join-20261004/scope.txt.source.txt)
joins those proofs to the complete authored-field models and preceding pinned
source context. It closes source and copy assurance.
The [metadata cause repair](reference-source/docs/audits/interface-metadata-cause-repair-20261004/scope.txt.source.txt)
now saves native errors immediately and checks complete intended primary causes
for every malformed capture/snapshot case and both malformed-width first reads.
A permanent native probe loads the unchanged provider from a path containing the
wanted prefix: the old helper accepts its earlier Storable error, while the
repaired helper rejects it. Caller/argument echoes retain their real errors;
a genuine name-validation bypass fails both refusal and cause checks.
Complete ordinary products, caller kinds, copies and primary causes conserve.
The [writer cause repair](reference-source/docs/audits/interface-metadata-writer-cause-repair-20261004/scope.txt.source.txt)
saves the parser error immediately and checks the complete record context,
transaction, field target and qualification reason. Real earlier root errors
reject even when the filename contains the wanted phrase; the genuine writer
cause succeeds at that filename. An actual writer-guard bypass fails both
refusal and cause assertions. Complete ordinary metadata/parser products and
copy kinds conserve; the controlled admitted actor binds its authored record.
The [complete diagnostic join](reference-source/docs/audits/interface-metadata-diagnostic-join-20261004/scope.txt.source.txt)
binds both committed repairs to their full source, native context and ordinary
product/copy/kind/caller proofs. Both contextual assurance defects close;
source echoes, private-copy promotion and actual guard bypasses cannot qualify
refusal causes. The [final metadata-helper review](reference-source/docs/audits/interface-metadata-helper-outcome-20261004/scope.txt.source.txt)
now reconciles the original source contracts with complete actual native roles
and all source, field, copy, product and diagnostic repairs. This finite T1983
review closes; public metadata behavior and admission stay unchanged. Other
aggregate helpers and wider cold/backend/native consumers remain under review.
The [record-value helper source plan](reference-source/docs/audits/record-value-helper-contract-20261004/scope.txt.source.txt)
binds T1986's first-line fragment predicate, real operation expressions,
Storable copy expressions and separate artificial stack self-test to its complete
source. Exact recursive record identity remains distinct from payload
compatibility; unresolved/local/formal shadows retain their declared roles.
Actual native causes, copied-field meanings and assurance controls remain owned
before any further test repair.

The [native record-value profile](reference-source/docs/audits/record-value-runtime-20261004/scope.txt.source.txt)
records actual selected APIs, helpers, copies, leaf consumers and complete
local/imported parser products. It retains cyclic input and its unchanged
refusal, and exposes numeric width kinds becoming strings in original test
copies. Source/product models and genuine copy/cause controls remain owned
before assurance repair; observing a passing test does not close those legs.

The [authored record-value layouts](reference-source/docs/audits/record-value-fields-20261004/scope.txt.source.txt)
independently bind local/imported resolved types, aliases, member/list order,
signed/state presence and packed scalar ranges. Original parser type/storage
products match complete numeric models; a private copied fixture cannot stand
in for that authority. Whole actor/API products remain separately owned.

The [copied-field qualification](reference-source/docs/audits/record-value-copy-fields-20261004/scope.txt.source.txt)
covers the complete original copy population and keeps raw numeric/string kinds.
Full types and scalar properties match source-declared candidates; storage and
default-port carriers keep distinct roles. Metadata layouts follow authored
ranges. A compatible private-stage spelling does not establish final numeric
product kinds or safe, isolated copying. Whole actor/API products, copy assurance
and native cause controls remain owned.

The [record-value field join](reference-source/docs/audits/record-value-field-join-20261004/scope.txt.source.txt)
reexecutes both complete source/layout and copied-field readers with their
recorded document boundaries, including their rejecting controls. It joins every
original copied graph and whole field record to the completed source-model
owners. Field qualification is complete; whole actor/API products and native
copy/cause assurance remain separate.

The [whole record-value actors](reference-source/docs/audits/record-value-actors-20261004/scope.txt.source.txt)
match independent source-first local/imported models, including defaults, empty
optional families, transaction clauses, raw type tokens, storage signals, package
roots and metadata. Both original public-source refusals publish no actor product.
The [complete scope proof](reference-source/docs/audits/record-value-scopes-20261004/scope.txt.source.txt)
binds all forty original calls: twenty-seven preparations and thirteen refusals.
Source-only root recipes cover local/formal masks, imported/local aliases, all
malformed facts and the refused output actor's preparatory scopes. Whole inputs,
caller kinds and detached scope products retain. Preparation type facts keep
their exact recorded width/signed spellings; aggregate signed validation is
numeric. A genuine equal-meaning private metadata type has different primitive
kinds and cannot supply the scope product. The [complete reference proof](reference-source/docs/audits/record-value-references-20261004/scope.txt.source.txt)
binds all sixty-eight original calls: fifty-one returned values, three accepted
calls delegated or left unresolved, and fourteen refusals. An independent
packed leaf inventory and scalar index/slice witnesses conserve exact source
properties, nearest roles and numeric widths/ranges. All sixty-five private
root copies and the whole caller graphs retain; returned type facts keep their
recorded preparation spellings. The [complete copy proof](reference-source/docs/audits/record-value-copies-20261004/scope.txt.source.txt)
binds all twenty-two original calls: five successful record copies, three
scalar/storage/literal cases with no record-copy obligation, and fourteen
refusals. All forty-one conditional source/target clone stages and caller kinds
retain. Whole source reference/type/role models independently distinguish
same-width member/order/signed/state/bit/list identity differences, input
targets and the contradictory width descriptor. A genuine narrower payload
operation accepts a signed-type difference that strict record-copy identity
refuses. The [complete value join](reference-source/docs/audits/record-value-api-join-20261004/scope.txt.source.txt)
now binds the three completed owners to all one-hundred-thirty whole original
scope/reference/copy call, source model and product records. All two-hundred-
thirty-three value-private clones join their full native graphs and copied-field
records; membership, source roles and primitive kinds retain. Each complete
child proof and its rejecting controls reexecute in its exact source/document
context. The [complete metadata capture proof](reference-source/docs/audits/record-value-captures-20261004/scope.txt.source.txt)
now qualifies all two-hundred-twenty-seven original captures: two-hundred-twenty
complete numeric products and seven source-owned refusals. Every own detached
stage joins its full copied-field record and declared interface/type source.
Independent reverse packed layouts verify all member/list paths, ranges,
signed defaults and explicit state models. A genuine private width string
cannot become final numeric metadata. Metadata accepts a missing scalar signed
property with its existing unsigned default; the stricter value gate refuses
that same source. Complete caller kinds and prior value semantics retain.
The [complete snapshot proof](reference-source/docs/audits/record-value-snapshots-20261004/scope.txt.source.txt)
binds every two-hundred-twenty original snapshot to its own completed source-built
capture, full handoff and detached stage/field record. All complete ordered
port/field properties and contiguous packed ranges reconstruct independently;
port widths and field widths/ranges/signed facts are numeric in the products.
Capture handoffs keep their raw width spelling, and caller graphs retain.
Genuine missing products/stages, wrong source roles, private width-string
promotion and capture misallocation reject. This profile's snapshots all
succeed; broader snapshot refusals and unknown/empty inputs are covered by their
separate metadata contracts. The [complete range proof](reference-source/docs/audits/record-value-ranges-20261004/scope.txt.source.txt)
binds every four-hundred-thirty-seven original call: four-hundred-seventeen
source-declared metadata leaf paths and twenty source/reference paths. Independent
reverse packed intervals verify four-hundred-thirty-one whole successful products
and six complete returned failure maps, including unknown members, invalid item
and scalar indices, malformed paths and a nearest scalar shadow. Returned range
widths/endpoints are numeric; resolved types keep their exact own clone-input
preparation spellings. Successful subaggregate ranges still meet the separate
value gate's scalar-leaf refusal. One private list-offset calculation promotes
a sibling width from string to number; its whole source/copy/caller relation is
retained, while the original reference caller stays unchanged. Missing calls or
type stages, wrong same-width ranges/failure truths, coercing a prepared type width and
concealing that private change reject. The
[original clone referent proof](reference-source/docs/audits/record-value-clones-20261004/scope.txt.source.txt)
adds joint input/result graphs to every eight-thousand-two-hundred-fifty-one
original recursive clone call. Independent reachable-node sets show detached
results for every two-thousand-six-hundred-twenty-eight container call; all
five-thousand-six-hundred-twenty-three scalar calls carry no referents. A genuine
bad provider executes the complete recursive operation then returns the input
container. Every separate recorded clone value still agrees, and all original
one-hundred-twenty-five assertions pass, while every container result shares its
input referents. Joint evidence rejects this real false green; value snapshots
and original consumers alone cannot establish detachment. Both complete native
runs reexecute from unchanged sources. Complete encoded process errors, the
synthetic trace and generated import nonce remain separately captured. The
observer keeps its original repository-root placeholder encoding; byte-exact
host-native cause equality remains unqualified. At that proof boundary,
clone source/tree semantics still needed the qualifications below. Permanent
consumer assurance and intended native causes remain owned follow-up work. The
[native command repair](reference-source/docs/audits/record-value-clone-paths-20261004/scope.txt.source.txt)
supersedes a command-binding flaw in that proof: Python supplied absolute
reader paths, so replay at another working root refused before semantics. Stored
commands now name the exact reader with repository-relative paths. The complete
ordinary proof and all five rejecting controls run at two actual working roots,
including the unchanged full native ordinary and shared-result profiles. Only
the exact main/imported-module traceback filename coordinates qualify; all
messages, arguments and other root-bearing semantic text remain exact. Complete
project-owned Perl/test-support runtime membership and bytes are watched. Original
evidence and the first missing-dependency fixture failure remain preserved.
The [complete root-source proof](reference-source/docs/audits/record-value-clone-root-20261004/scope.txt.source.txt)
binds every one-thousand-four-hundred-forty-eight original root clone input:
one-hundred-fifteen scope types, forty whole references, and three roots for
each of four-hundred-thirty-one successful paths. Those path roots hold segments,
the selected leaf type and the final range type. Two scope types are unresolved
nulls; failed paths produce no roots. Whole source declarations, masks, properties,
raw preparation kinds and exact private/parent/caller context reconstruct without
actual clone result authority. A separate declared subtree inventory and literal
scalar index/slice witnesses verify source allocation. Missing roots, wrong roles,
an identical type borrowed from a different source call, and promotion of a raw
width string reject. The full repaired native proof and its controls reexecute in
their exact dated context. The
[complete recursive tree proof](reference-source/docs/audits/record-value-clone-tree-20261004/scope.txt.source.txt)
now expands those source-owned roots into every original recursive operation.
All eight-thousand-two-hundred-fifty-one whole input/output products retain:
six-thousand-eight-hundred-three children, with five-thousand-nine-hundred-eleven
hash-child calls and eight-hundred-ninety-two array-child calls. Plain hashes
copy every key; arrays preserve every position; scalar values keep their exact
kinds, including unresolved nulls and raw width strings. A separate breadth-first
source-path inventory reconstructs whole products from the leaves upward and
checks each call's source root, parent, depth-first order and caller. Joint native
graphs establish detachment for every container. Missing operations/keys,
reordered arrays or calls, wrong callers, identical-valued source substitutions,
raw numeric promotion and the genuine alias-returning provider reject. Complete
source-root and native proofs reexecute with all their controls in dated contexts.
This finite observed population has no cyclic clone inputs; cyclic support is
not inferred. Permanent original consumer assurance and full native causes
remain owned follow-ups. The
[complete clone join](reference-source/docs/audits/record-value-clone-join-20261004/scope.txt.source.txt)
now binds the completed native and source/tree owners to every whole original
operation, source path, caller, primitive kind, joint graph and reachable set.
The complete original native profile retains, with its full encoded error and
import-nonce differences explicitly preserved. A permutation of two actually
identical full native records still rejects when their source slots are wrong;
equal values and conserved membership cannot establish allocation. Missing joins,
wrong source roots, raw width promotion and the genuine alias provider also
reject. The complete tree proof and its eight controls reexecute in exact dated
contexts, including all prior root/native proofs. This closes the structured
clone product lane. Strict identity and payload helpers, the whole core/API join,
permanent original consumer assurance and native full causes remain separate.
The [complete identity/payload proof](reference-source/docs/audits/record-value-identities-20261004/scope.txt.source.txt)
now qualifies fourteen original strict comparisons and four original payload
comparisons from full source types and their own private preparations. Five
strict pairs are equivalent; nine conflict despite the same packed width. Full
member names/order, nesting/list positions, signedness, state-model presence and
bit-versus-bits kinds retain. The narrower payload relation accepts the four
sign/state/unit-kind differences. Independent complete property/path and ordered
shape witnesses distinguish those contracts; missing calls, width-only identity,
strict payload checking, identical-argument source substitution and raw width
promotion reject. Eight genuine public payload controls additionally return true
for those properties and false for same-width renamed/reordered/flattened/list-
reordered shapes, with complete caller arguments unchanged. The original whole
input/output/caller/kind/context records and dated clone/native proofs retain.
The whole core/API join, permanent consumers and native full causes stay owned.
The [complete core join](reference-source/docs/audits/record-value-core-join-20261004/scope.txt.source.txt)
binds every original capture, snapshot, range, recursive clone, strict identity
and payload call to its own completed source model and whole native record.
Each metadata private clone and field record, source capture handoff and final
range type stage retains its exact caller, input/output graph and primitive
kinds. A different source model with an actually identical native record still
rejects; missing calls/private links, wrong API families and numeric promotion
also reject. Every completed core proof and its rejecting controls reexecute
in its dated source/document context, including the full inherited native and
source proofs. This closes only the core product lane. The whole actor/API
join, permanent original consumers and full native diagnostic assurance remain
separately owned.
The [complete actor/API product join](reference-source/docs/audits/record-value-products-20261004/scope.txt.source.txt)
now binds all four original actor outcomes and every value/core call to its own
completed source model and full native product. All private preparation clones
and field records retain their API owners; nested calls retain their exact
source parse and operation bounds. Missing actors/calls/private stages, borrowed
models with identical native values, wrong API families or parse owners, numeric
promotion and genuine kind-changing private actor copies reject. Complete actor,
value and core proofs reexecute in dated contexts with every inherited native
and source proof. This closes product semantics only; whole semantic/helper
closure, permanent original consumer assurance and full native causes follow.
The [complete semantic join](reference-source/docs/audits/record-value-semantic-join-20261004/scope.txt.source.txt)
now binds the full authored/source field domain, every original copied field and
actor/API product, and all helper/consumer source and callback relationships.
Each raw caller, primitive kind, model and allocation remains exact, including
native ancestor-cycle boundaries. Omitted fields/products/consumers, wrong source
properties, copied-field assignments or helper ownership reject. The genuine
alias provider still preserves every separate clone value and legacy consumer
pass but fails the full joint-graph allocation check. Dated field/source and
product proofs reexecute with their controls and inherited native proofs. This
closes field/source/product semantics; permanent consumer/baseline-kind repair
and complete intended host-native causes remain open.
The [original semantic replay](reference-source/docs/audits/record-value-original-replay-20261004/scope.txt.source.txt)
now pins complete original source and task authority before permanent test changes.
The original proof and every rejecting control run in that exact dated context;
changed source or completed-owner authority rejects. This preserves the original
comparison boundary while current copy and consumer repairs remain separately owned.
The [complete original copy-input contract](reference-source/docs/audits/record-value-copy-inputs-20261004/scope.txt.source.txt)
now binds every test-copy graph and field to its source and completed semantic owner.
Actual Storable outputs lose primitive-kind information and reject as baseline authority.
These original inputs are trees; sharing, cycles and native-reference boundaries need
separate candidate probes before any permanent copy or consumer repair.
The [finite native probe captures](reference-source/docs/audits/record-value-copy-probes-20261004/scope.txt.source.txt)
now retain ordinary primitive/tree/sharing/cycle observations and genuine bad-provider
failures, including kind loss, aliasing and readonly violations. The [independent finite reader](reference-source/docs/audits/record-value-copy-reader-20261004/scope.txt.source.txt)
now qualifies the complete typed graphs, sharing, cycles, readonly inputs and
detachment against separate source models. Fresh exact-source replay preserves
every native mode and intended failure; altered graph, cause and source authority
controls reject. This qualifies the recorded plain-helper profile only. The [finite qualification join](reference-source/docs/audits/record-value-copy-probe-join-20261004/scope.txt.source.txt)
now closes this probe lane with exact completed owners and whole reexecuted products.
The [original candidate captures](reference-source/docs/audits/record-value-original-candidate-20261004/scope.txt.source.txt)
now retain unchanged-input copy graphs, actual Storable kind failures and alias
isolation failures. The full alias run also preserves downstream mutations and
its real abort; separate bad-provider trials keep every original input intact.
The [independent original copy reader](reference-source/docs/audits/record-value-original-copy-reader-20261004/scope.txt.source.txt)
now qualifies unchanged-input copy kinds, complete graph identity, readonly
inputs and detachment, including the actual bad-provider trials. The
[original source-product reader](reference-source/docs/audits/record-value-original-products-20261005/scope.txt.source.txt)
now qualifies complete API/parser results against their own source models and
conserves private-source allocations. The [source-intervention graph reader](reference-source/docs/audits/record-value-original-input-graphs-20261005/scope.txt.source.txt)
now qualifies complete input/private graphs, typed edges, readonly copies and
detachment. It retains the known private range sibling kind transition while
the outer value caller stays unchanged. The [copied-field source reader](reference-source/docs/audits/record-value-original-fields-20261005/scope.txt.source.txt)
now joins every copied width to its complete source type, carrier role and
ancestor context, preserving raw kinds and compatible-source candidate sets.
The [input/private semantic join](reference-source/docs/audits/record-value-original-input-join-20261005/scope.txt.source.txt)
now binds every own graph and field to the same source/caller context, raw
kinds and detached copy boundary. The [source-context reader](reference-source/docs/audits/record-value-original-contexts-20261005/scope.txt.source.txt)
now qualifies exact helper, consumer and parser source locations, input texts
and operation spans for the recorded finite profile. The [primary-cause reader](reference-source/docs/audits/record-value-original-primary-20261005/scope.txt.source.txt)
now derives API, helper and parser first causes and acceptance from their own
source inputs. The [raw-error inventory](reference-source/docs/audits/record-value-original-raw-20261005/scope.txt.source.txt)
now preserves the complete empty/nonempty population, serialized string bodies,
physical frame annotations and opaque address lexeme spans. This qualifies
lossless capture grammar only. The [source exception contracts](reference-source/docs/audits/record-value-original-class-20261005/scope.txt.source.txt)
now infer unblessed scalar exceptions from the finite literal guards and original
publisher policy. Genuine object exceptions with the same printable message
retain their class and fail that publisher. This is a source/contract inference;
the original capture did not measure class before serialization. The provider
version comes from its runtime accessor because the historical POD label is stale.
The [direct value paths](reference-source/docs/audits/record-value-original-value-frames-20261005/scope.txt.source.txt)
now derive active value-validation function order and source argument roles
from qualified inputs. Captured visible argument footprints agree; exact trace
formatting, unprinted arguments and live reference identity remain open.
The [metadata paths](reference-source/docs/audits/record-value-original-metadata-frames-20261005/scope.txt.source.txt)
now qualify the finite metadata guard and record-member recursion projection from
type inputs, including cyclic traversal. Visible path and argument footprints
agree. The [nested input join](reference-source/docs/audits/record-value-original-nested-inputs-20261005/scope.txt.source.txt)
now links each finite failing Scope/capture pair to its private root and complete
source-constructed typed interface input, preserving kinds, sharing and cycles.
The [nested forwarding reader](reference-source/docs/audits/record-value-original-forwarding-20261005/scope.txt.source.txt)
now binds the capture eval, explicit whole-string rethrow, Value catch and new
outer throw. The entire inner error, including its trace text, is conserved in
the outer message prefix. This proves forwarding of the source variable; full
inner and outer trace interpretation remains open. Current public Perl probes
distinguish explicit rethrow from implicit propagation and show that a die hook
can replace an exception. Original hook state and provider bytes were not captured.
The [inherited API paths](reference-source/docs/audits/record-value-original-inherited-frames-20261005/scope.txt.source.txt)
now join the active Value validation and capture/Scope observer eval, delegate
and wrapper frames in both the inner failure and new outer throw. Source argument
roles agree with visible scalar and reference-kind footprints. The [own API path join](reference-source/docs/audits/record-value-original-api-paths-20261005/scope.txt.source.txt)
now covers every recorded API refusal through a complete partition of direct
Value and nested metadata paths, including both nested throw phases. Complete own
function order and visible argument roles agree with source models. The [observer source inventory](reference-source/docs/audits/record-value-original-observer-sources-20261005/scope.txt.source.txt)
now pins whole own observer/test sources, wrapper and helper roles, subtest markers
and every original callback allocation. The [observer operation boundaries](reference-source/docs/audits/record-value-original-observer-boundaries-20261005/scope.txt.source.txt)
now join original API/parser operations, observer evals and installed wrappers,
including both nested throw phases. Complete source argument roles agree with
visible scalar and reference-kind footprints. The parser receiver has a declared
facade role; its original object identity was not captured. The [named helper paths](reference-source/docs/audits/record-value-original-named-helpers-20261005/scope.txt.source.txt)
now preserve supplied versus default scope/reference/copy arguments and complete
source input graphs. Calls that returned while constructing copy arguments remain
separate from the helper active at the throw. Named helper paths and visible
argument roles agree through both nested throw phases. The [compiled callback paths](reference-source/docs/audits/record-value-original-callback-paths-20261005/scope.txt.source.txt)
now bind the parameterless original callback, refuses eval, compiled helper and
installed helper wrapper. Visible operation-kind, regex-body and label displays
agree with independently authored source roles through both throw phases. The [complete helper join](reference-source/docs/audits/record-value-original-helper-join-20261005/scope.txt.source.txt)
now binds every source helper allocation, supplied/default input and returned
argument-building operation to its compiled callback/refusal path. Complete active
paths and visible argument roles agree through both nested throw phases; returned
helpers are excluded from active paths. Public framework meaning, exact display,
raw coordinates and native address meanings, consumer
operand truth and the full alias run’s downstream causes remain open. The complete semantic join and cold replay
precede the candidate-parent join and permanent test-copy and consumer repairs.

The dated installed public framework profile now pins complete caller/eval,
Carp and Test::More/Test::Builder documentation plus runtime version and public
documentation-location accessors. These public contracts describe callback
argument forwarding, block-eval/error roles and trace interfaces. Debugger
argument snapshots are best effort and may reflect aliases or later changes;
they do not establish original argument or reference identity.

This dated evidence qualifies the installed public documentation/profile.
The independent public fixtures below now refine current interface roles; the
finite original public-header compatibility below now refines those boundaries.
The original framework/provider version and private implementation, full trace
display, scalar encoding, hidden suffixes, coordinates and addresses remain
unmeasured. Necessary installed toolchain documentation is read-only; all
project captures and scratch stay inside the repository.

Default replay verifies the dated saved profile. Explicit current replay also
reexecutes the pinned public commands and compares every raw output byte:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-framework-profile-20261006/verify.py --current
```

Independent current public fixtures now qualify authored Test::More and
Test::Builder callback bodies and forwarded scalar arguments, own caller edges,
block-eval success/failure roles, isolated do/require loads and configurable
Carp trace argument visibility. Expected roles come from separate own source and
published contracts before native outputs are consumed. Successful mutated
fixture processes separate wrong body, argument, eval, call and trace policies.

The first shared-file fixture exposed a load-cache interaction: this do
invocation registered the identifier before require, so require skipped its
body. Separate own filenames isolate both operators. The first trace also
retained the direct emitting helper as a location rather than a named call;
only the authored outer call and argument-policy difference are qualified.
These are finite current observations, with the complete first refusal retained.

Default replay verifies saved source/native evidence. Explicit current replay
also compares complete raw current fixture output and reruns behavioral controls:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-native-fixtures-20261006/verify.py --current
```

External framework names stay opaque. These fixtures do not measure original
framework/provider versions, private operations, full formatter or hidden
arguments, reference identity, direct-emitter/source coordinates or addresses.
The finite original public-header join below now qualifies source/signature
compatibility; current fact publication is qualified below. All project outputs and scratch stay local;
installed public toolchain access is necessary and read-only.

The complete finite original public boundary join now compares source-selected
named-subtest bodies, own eval/delegate/load boundaries and recorded public
Test::Builder/Test::More headers. Published interfaces and separate current
fixtures select the public symbols and path before original traces are examined.
Across the original cases and throw phases, visible authored-name displays and
CODE kinds agree with the public signatures and body/delegate/entry/load order.
Receiver tokens stay opaque; truncated displays qualify only visible prefixes.

Wrong public names, callback kinds, extra public frames and an early delegate
first pass the prior own-source semantic composite within their intervention
epoch, then fail the new public-header check. That local acceptance never
replaces original ancestry: complete committed roots, actual seal checkers and
every original raw body remain independently authenticated and conserved.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-join-20261006/verify.py
```

This qualifies finite source/header compatibility with the dated exercised
public interfaces. It does not establish the original framework/provider
versions, private delegation or eval purposes, original formatter/settings,
hidden suffixes, scalar encoding, receiver/callback contents or identity,
coordinates or addresses. Private framework frames and eval intervals remain
opaque. The authored load operator remains do despite its displayed require
marker. Current fact publication is qualified below. Class/frame and coordinate/address
joins retain their own next steps; current compatibility never supplies missing
historical identity.

For a narrower replay, authenticate the successful full prerequisite executions
and every declared transitive audit input against committed checkpoint af4999e7,
then execute the current source models, original header join, separating controls
and native guide checks afresh:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-join-20261006/verify.py --checkpoint-prerequisites
```

This option reports saved prerequisite executions explicitly; it does not claim
they ran again. Changed inputs, programmes or saved receipt roles refuse. Both
commands retain the default RAM limits. The earlier broad seal attempt stopped
at the host cutoff and remains failure evidence.

At the draft checkpoint, a source-bound draft for the next fact publication preserves the ordered
questions and authored subtest/do-load section within a non-growing card budget.
The draft check qualifies construction and physical deltas; semantic retention
of removed or re-formed narration remains a separate prerequisite. A coherently
omitted parser-receiver fact still passes the narrow draft check. The publication
slice must reject that loss before changing any live fact or current query route.
The canonical fact card remains unchanged at this draft checkpoint.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-draft-20261006/verify_draft.py
```

The superseding retention proposal has a complete reviewed source-fact and
removal map. It preserves each unique source meaning, including the declared
parser receiver and broader observer/display/frame gaps. Removed helper-input
and joined-status narration maps to the richer retained join; the authored
subtest/do-load section stays byte-exact. The revised whole card does not grow
in encoded bytes or line feeds. Genuine fact, gap, question and review-row loss
refuses, including the coherent receiver deletion accepted by the draft check.

The review map records the engineer's semantic equivalence judgments. Its
checker proves the complete declared source census, target presence and tested
loss rejection; it does not decide unrestricted natural-language equivalence.
Completed public-header source and original-population controls authenticate
separately. Replay the retained proposal from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-retention-20261006/verify.py
```

This command qualifies the retained proposal snapshot. Live publication and
current query/reader qualification use the new command below. `--live-unchanged` additionally
checks that the pre-publication card and its collection authority still match
their committed sources; it must stop accepting after publication. Default
replay preserves the source/proposal snapshot and does not borrow live currency.
Original framework/provider/private/formatter/reference/coordinate/address
meanings and visual QA remain unmeasured or separately owned.

The following observer and tooling guides are retained publication checkpoints.
Their earlier current commands check their exact fact epochs. They do not prove
the newly published class/frame facts; use the complete current reader below.
The old programmes, source contracts, native results and seals remain immutable.

The following observer publication guide records its 2026-10-06 checkpoint.
Its scoped observer command remains valid. The companion repair and complete
current core/observer/tooling route are qualified immediately after that guide.

The public-boundary fact publication now qualifies the finite original
Test::Builder/Test::More header relationship: authored-name prefixes, CODE kinds
and body/delegate/entry/do-load order match at every retained throw phase.
Independent dated public fixtures select the symbols. Original provider/version,
private eval purposes, formatter/settings, hidden arguments, receiver/callback
contents and identity, class/frame joins, coordinates and addresses remain open.

The canonical observer/helper topic retains every reviewed source fact and prior
question, adding one public-boundary question. Its exact admitted body does not
grow in encoded bytes or line feeds. Collection authority remains unchanged;
this publication supplies no new physical card allowance or healthy-collection
claim. The review is an explicit semantic judgment, not a language oracle.

Current replay checks the exact fact, actual direct/cache question ownership,
all physical capacity dimensions, this scoped guide and current source routes:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-public-boundary-publication-20261006/verify.py --current
```

Default replay authenticates committed prerequisites and the saved publication
snapshot; snapshot success cannot supply live currency. Unrelated book progress
does not invalidate this scoped current reader. An optional
`--build repository-relative-output` checks current native source copies and
rendered guidance. Visual QA remains separately pending.

The retained proposal's default replay still authenticates its source snapshot.
Its `--live-unchanged` pre-publication role now refuses the changed live card.
The superseded own-boundary publication also retains its default snapshot replay;
its old whole-card current role refuses this qualified extension. Use the new
current command above for this observer topic. The tooling companion still
advertises the superseded current role; its immediate owned repair remains
pending before the public publication parent can close. Original programmes
and seals remain unchanged.

The tooling companion now uses the qualified current reader below. The
earlier pending-repair statements describe the observer publication checkpoint;
this companion repair completes that dependency. The core and observer cards
remain exact, and every tooling fact and ordered question remains unchanged.
Only the tooling date and current reverify route change. No physical card or
question is added, and the collection authority is unchanged.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-tooling-current-reader-20261006/verify.py --current
```

This current role checks complete core/observer/tooling meanings and actual
direct/cache question ownership, the scoped guides, source selection, relative
endpoints, current bytes, ignore policy, indexed members and exact budgets.
Unrelated book progress is permitted. Default replay authenticates the source
and saved publication snapshot; it cannot establish current currency.
`--current --build repository-relative-output` additionally checks current native
source copies and rendered guidance. The original destination-locality replay
remains part of the tooling reverify command. Historical source-plane replay
uses its snapshot adapter; older current readers retain their exact epochs.
No old programme or seal changes. Visual QA and original/private/formatter,
class/frame/coordinate/address, host-native and broader CI/push gaps remain
separately owned.

Class/frame prerequisite admission now authenticates the complete declared
source-reader and publication audit closure against committed abdf385d. Every
regular member, completed source owner and immutable original capture belongs
to that custody check. Whole empty/nonempty error populations and serialized
bodies regenerate without normalization.

The admission also retains actual fresh class/primary/raw, API and complete
parser/observer/helper/subtest reader executions with their controls. Public
documentation/accessors and authored public fixtures, including native source
mutants, ran again through installed public interfaces. The original capture
and earlier native probes remain retained evidence. The public-header replay
explicitly uses saved transitive prerequisite executions at af4999e7 while
regenerating its source/header/control products. The latest publication and
tooling actual-result reader also reexecuted; its saved native captures remain
saved. Invocation-time source identities, complete commands, statuses and both
streams preserve these distinct roles.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-admission-20261006/verify.py
```

This default command authenticates the committed input domain, regenerates the
whole raw inventory and admission controls, and checks the saved actual replay
results and native guide. It does not rerun those readers or establish live
currency. The sealed admission refuses recapture. Independent result checking
rejects typed status/count substitutions, source/member/owner loss, invented
scope and genuinely borrowed successes.

Admission itself supplies no class/frame semantic join. The independent join
is a separate successor checkpoint, followed by qualified publication. Original native class,
provider/version, hooks, private framework meaning, complete formatter/settings,
hidden arguments, reference identity, coordinates and address/lifetimes remain
unmeasured or separately owned. Current facts, query routes, collection authority
and prior seals remain unchanged. All project output and scratch stay local;
installed public toolchain access is necessary and read-only. Visual QA, HIAL
host-native repair and full CI/push remain separately owned.

The independent class/frame successor joins every original nonempty error to
its qualified source-inferred exception class and complete own throw phases,
functions, visible argument roles, observer operations, helper, authored body,
subtest entry and load boundary. Public framework headers retain their finite
compatibility scope. Every empty allocation, raw body and opaque byte also
remains conserved. Original source, completed owners and whole prerequisite
programmes/results are bound to committed 0373153b.

Nested Metadata refusal and the new outer Value refusal have separate class
and phase roles. The join checks that the outer body preserves the entire
serialized inner operand through the source catch/interpolation/new-throw
sequence. The predecessor model's captured operand is declared opaque retained
evidence; its formatter, addresses and coordinates are not a new source oracle.
The source association contract was qualified before new original intake.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-join-20261006/verify.py
```

The default authenticates complete committed inputs and saved actual admission
execution, regenerates source associations, all original raw/body/phase joins
and genuine separating controls, and checks the saved native guide. It does
not recapture the original run, reexecute the eight prerequisite processes or
establish live currency. Source-association controls corrupt class/family,
phase, function order, argument and case links while the separate predecessor
products pass. A genuine opaque inner-body change passes predecessor own/public
predicates but breaks whole forwarding. Independent actual-result checking
rejects typed status/counts, lost members, widened guard and borrowed successes.

This is source/publisher class inference and finite own/public compatibility.
Original pre-serialization class, provider/version/hooks, private framework
purpose, full formatter/settings, scalar encoding, hidden arguments, reference
identity, coordinates and address/lifetimes remain unmeasured or separately
owned. Final current fact publication is the next slice. Existing facts,
questions, query routes and collection authority remain unchanged. Project
outputs and scratch stay repository-local; public toolchain reads remain
necessary and read-only. Visual QA, HIAL host repair and full CI/push retain
their separate owners.

The publication-admission checkpoint authenticates the complete committed
class/frame source models, semantic controls, actual-result programmes and every
transitive admitted member at 017a8f70. Complete source associations, raw objects,
class/frame/body/phase/operand joins and separating controls are reconstructed
and compared as whole values. Existing committed model/raw corpora remain the
durable evidence; this checkpoint does not duplicate their large representations.

Fresh executions cover the full semantic reader, independent actual-result
reader and pre-publication current-tooling reader. Their commands, complete
streams, integer statuses, roles and invocation-time source/input identities
are retained separately. Original native captures and transitive native results
remain retained evidence, never a new recapture. Existing canonical facts,
ordered questions, query routes, source budgets and collection authority stay
unchanged. Semantic retention and atomic current publication remain pending.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-admission-20261006/verify.py
```

The default authenticates whole committed custody, regenerates complete
semantic products, checks saved scoped executions and genuine member, owner,
kind, native-scope, question, authority and borrowed-result refusals, and checks
the saved native guide. It checks the unchanged pre-publication fact epoch;
a qualified successor owns later fact or route changes. It does not rerun those
prerequisite processes or claim live current class/frame publication.
Independent actual-result qualification
also rejects typed status/counts, omitted members, widened guard and real
borrowed narrower successes. Original native class/provider/hooks, private
frames, formatter, scalar encoding, identity, coordinates and address/lifetimes
remain unmeasured or separately owned. Visual QA, HIAL repair and full CI/push
retain their separate owners. Project outputs and scratch remain repository-local.

The semantic-retention checkpoint prepares the complete core, observer and
tooling fact proposal before changing live cards or reader routes. Every original
sentence or clause maps to reviewed survivor text, with its qualifiers, examples,
identity, ordered questions, evidence and replay obligations retained. Exact code
literals and original front matter stay unchanged. This is engineer-reviewed
prose equivalence; mechanical coverage is not unrestricted natural-language proof.

The additions bind the complete qualified source-class/frame/body/phase/operand
join and its separating controls. Full original physical and logical membership,
global question allocation and every collection-capacity dimension are checked.
Compaction does not grow the complete proposed byte or line-feed population or
widen its collection authority. Actual loss controls cover propositions,
qualifiers, questions, source members, completed owners, kinds and native scope.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-retention-20261006/verify.py
```

The default regenerates the complete frozen proposal and semantic authority,
checks the saved fresh admission execution, retained first failed budgets,
controls and native guide. It does not claim live current fact publication.
The additional `--live-unchanged` check requires the old complete fact epoch;
atomic publication and updated current routes remain a separate successor.
The preparation and fresh replay roles qualify this unchanged pre-publication
epoch; original native captures and transitive native executions are retained,
never recaptured. Private frames, native class/provider/hooks, formatter,
encoding, hidden arguments, identity, coordinates and address/lifetime meanings
remain unmeasured or separately owned. Visual QA, HIAL repair and full CI/push
retain their owners. Project outputs and scratch remain repository-local.

The complete finite class/frame publication now retains every prior core,
observer and tooling proposition, qualifier, example and ordered question, and
adds the qualified source-class/frame/body/phase/operand join. Every original
nonempty error binds source-inferred class and guard family to its complete own
and finite public phase, function order and visible argument roles. Empty
allocations, source contexts and opaque raw bytes retain. Nested Metadata and
new outer Value keep separate class/phase roles while the entire inner operand
passes through catch, interpolation and the new throw. Source associations were
qualified before the new raw intake. Genuine class/family/phase/order/argument/
population/native-promotion controls conserve predecessor meanings; changing
opaque inner-frame bytes passes those local meanings but breaks whole forwarding.

Original own caller and source coordinates now have a separate complete
qualification. Source recipes bind every original error origin, own caller and
inherited inner coordinate without normalizing raw bytes or equivalent labels.
Nested forwarding preserves its inner and outer phases. Genuine line, filename
and source-association controls preserve the complete prior class, frame and
visible-argument meanings before both coordinate procedures reject the changed
association. Independent reconstruction qualifies the whole result and original
custody, including genuine omission and borrowed-result controls. Earlier
construction failures and RAM stops remain non-success evidence.

The maintained reader authenticates that complete admitted qualification and
every original input. It does not recapture original executions or claim a new
semantic reconstruction merely from certificate authentication. Core, helper,
parser and tooling facts retain every prior question, probe and locality rule;
their reviewed working set does not grow. Original private formatting, toolchain
and identity, external framework coordinates and address lifetimes retain their
separate owners. Whole current publication is independently qualified after a fresh complete
semantic replay. Exact source history, all questions, native guidance and
unchanged capacities conserve; broader private and downstream owners stay open.

The current route checks all four complete canonical cards, actual direct and
cached question ownership, every collection-capacity dimension, exact source
budgets and canonical source selection, relative endpoints, current bytes,
ignore policy and indexed members. Its native variant additionally checks every
copied canonical source and the rendered current/retained guide:

```bash
scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py
```

```bash
scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py --build .artifacts/class-frame-current-book
```

The core reverify chain still runs the original helper join, finite copy join
and separate fresh finite copy-probe replay before this current check. Tooling
still runs its original destination-locality replay. The fresh finite probe is
not an original raw-error recapture. Earlier admission and retention guides
describe their checkpoints; explicit old-epoch checks refuse the changed facts.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-20261006/verify.py
```

Default replay authenticates complete committed custody, reconstructs the full
retention and class/frame meanings and controls, and checks the saved publication
snapshot and native guide. It cannot establish current currency. Unrelated book and non-target Knowledge Map progress is permitted. The current
reader derives the complete global question allocation and physical census from
current canonical sources; the saved historical snapshot keeps its exact epoch. The collection allowance is never
widened; every original fact/question retains. This remains reviewed prose
equivalence rather than unrestricted mechanical natural-language proof.
Original native class/provider/hooks, private frames, formatter, encoding,
hidden arguments, identity, external coordinates and address/lifetime meanings remain
unmeasured or separately owned. Visual QA, HIAL repair and full CI/push retain
their owners. Project outputs and scratch remain repository-local.

Original address roles now have a separate complete finite qualification.
Every own visible reference number joins its simultaneous source and holder
domain. Explicit aliases agree; qualified distinctions differ. Active
`main::call_api` retains the saved CODE handle through lexical `$operation`.
CODE/CODE comparisons remain opaque. A consistent renaming can preserve the
finite relation, but still fails the separate original-byte association check.

For example, repeated occurrences of an explicit alias must retain one reference
number within that source domain. Distinct qualified holders must retain distinct
numbers there. Equal-looking CODE displays, regex displays and hidden arguments
provide no missing referent, payload, flag or native identity. The finite join
does not establish cross-call or cross-capture reuse, heap lifetime or cold cost.

The coordinate-era and preparation paragraphs retain their dated checkpoint
roles. Current core, helper, parser and tooling cards now admit the reviewed
address proposal together. Exact beforeimages, every prior question and replay
command remain retrievable under unchanged collection authority. The maintained
reader authenticates the complete admitted preparation, source/holder/numerical
inputs and actual independent results before and after current verification.
Authentication is not a fresh semantic reconstruction or original recapture.

Replay the complete dated raw/source/numerical parent qualification separately:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-parent-acceptance-20261010/verify.py
```

Current verification still derives every canonical source, direct and cached
question allocation, physical capacity and copied source. Its native variant
also checks the rendered current guidance. The original private/provider/
formatter, external/native/CODE/Regexp identity, cross-call/capture reuse, heap,
cold and visual scopes remain separately owned. Full unchanged address-container
acceptance now qualifies through fresh complete semantic readers and independent
whole original/proposed/current reconstruction. Only finite address nodes close;
full raw-stack joining is next. HIAL and full CI/push gates stay open.

Address/lifetime qualification begins with a separate source-only model of
operation boundaries. Qualified typed input graphs retain aliases and cycles
without publishing numeric addresses. Forwarding the same source argument
through the installed wrapper, observer and original operation preserves its
binding. Distinct graph nodes remain distinct while live, even when their
payloads are equal. The observer allocates a fresh caller array while supplied
arguments remain live. A saved operation lookup retains its declared CODE role.
These constraints belong to an active call and throw phase in one capture;
numeric reuse across calls or captures establishes no object identity.

For example, two separately allocated source and target reference records can
contain the same type payload without sharing their root identity. Conversely,
when the qualified graph aliases an input node, repeated source slots must
retain that alias. The model checks complete source slots and graph topology,
plus a separate relation oracle and genuine borrowed-role, split-binding,
wrong-kind, omission and lifetime-domain controls. Replay from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-source-boundaries-20261010/verify.py
```

This is a dated source hypothesis, not a raw-address match. The original parser
observer excludes the receiver from graph publication; its forwarded role does
not supply a receiver census. Nested input topology, core/private/helper and
parser-internal lifetimes remain source-model successors. The original raw
address join, external/framework/provider/formatter identities and current
canonical address publication remain open. Existing coordinate and class/frame
qualifications keep their separate meanings.

The private-copy source foundation separately qualifies the complete original
private graph population. The observer delegates these copies to its saved
Storable handle. A finite memoized clone model supplies independent topology
hypotheses; it does not reconstruct that provider. Whole qualified input/result
and original joint graphs agree through a separate graph-bijection oracle,
including shared nodes and cycles. Each returned node belongs to a detached
result pool while input and result are simultaneously live inside `copy_value`.
Scalar flags and values retain their separate qualified graph evidence.

A copied record may preserve its input payload and internal sharing while every
returned container has a distinct identity from the input containers. Conversely,
a returned copy can cease to be live before a later error. The per-copy model
therefore supplies no cross-copy identity or post-return liveness. Those require
caller and throw-phase source contracts. Genuine alias, split-sharing, kind,
omission, borrowed-domain and false-lifetime controls reject. Replay from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-private-topology-20261010/verify.py
```

This is a dated topology and active-copy lifetime qualification. Original numeric
addresses, native/provider/formatter identity, later Value/Metadata/helper/parser
reference roles, the raw-address join and canonical address publication remain
separately owned. The complete earlier operation-boundary hypotheses remain intact.

Direct Value core frames now have a separate source binding model. An operation's
original argument slots keep the supplied references even after a local variable
is assigned a detached copy. For example, a copy-width refusal passes a detached
source record to `_validate_reference`, while the enclosing copy operation still
exposes its original source and target arguments. Equal payloads do not merge
those bindings. Deep type failures follow the qualified active root and its
record/list descendants; earlier returned roots are not presumed live.

The model also distinguishes fresh named-argument hashes from supplied records,
and fresh required/optional key arrays from type nodes. A separate oracle follows
source argument slots, clone assignment order and closed-type traversal. Genuine
wrong-copy, wrong-node, alias-splitting, kind, omission, borrowed-domain and false
post-return lifetime controls reject. The complete operation/private source
prerequisites remain exact. Replay from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-value-core-20261010/verify.py
```

This is a dated finite source hypothesis. Cross-pool freshness remains a source
hypothesis, not a measurement of original provider identity. Original numeric
addresses, private/provider/formatter identity, cross-call and post-return
lifetimes, Metadata/nested/helper/parser bindings, the raw-address join and
canonical address publication retain their separate owners.

Metadata core source bindings are qualified separately from the surviving
Value ancestors. The public capture argument retains the supplied constructed
interface. Metadata first clones that interface; its recursive type arguments
then refer to nodes in the active detached Metadata copy. Recursive calls share
one scalar-path sink and one active-type hash for the traversal. The source
model records active type nodes symbolically, without publishing address keys.

For the cyclic-member refusal, the recursive `.data` type refers back to the
active root type. Those recursive frames must retain one type binding, one sink
and one active hash. The sink already contains the completed `.flag` path.
A separate encoded-graph walk checks the first guard, complete ancestry, earlier
successful leaves, aliases and active membership. Genuine split-cycle, split-sink,
split-active-hash, broken-cycle, wrong-copy/kind/node, omission, borrowed-domain
and false-lifetime controls reject. Replay from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-metadata-core-20261010/verify.py
```

Every original Metadata source case and nested input pair retains. Metadata
frames embedded in the later caught Value error are inactive; they do not prove
later liveness of the sink, active hash or detached Metadata copy. The immediate
nested-join successor must bind the surviving Value roots and operation domains.
Original numeric/private/provider/formatter identity, helper/parser roles,
the raw-address join and canonical address publication remain open. Cross-pool
detachment remains a finite source hypothesis, not measured provider identity.

The nested source lifetime join now covers the complete Metadata/Value pair
population. Each pair has three views: the capture record at the inner Metadata
throw, the Scope record preserving that same inner throw, and the later new Value
throw after Metadata unwinds. The first two views share one event; an embedded
trace is not a second active invocation.

The constructed interface's `type_spec` is the active Value private root's type
node: `my $checked = $spec` preserves that alias. Metadata clones the interface
and traverses its detached type graph with shared sink and active-path locals.
For example, the cyclic `.data` member returns to the Metadata type root while
the supplied interface still points into the separate Value graph. The join
resolves every previously pending nested operation domain and preserves the
original Scope arguments through both wrappers and saved operation calls.

At the later Value throw, Scope and its Value root remain active. Capture and
both copy delegates have returned. The observer still holds both `[caller]`
arrays in its `@api` records and retains the saved operation lookups in lexical
scope. A returned activation therefore does not imply a dead caller snapshot.
Metadata's sink, active hash and detached result, and the constructed interface
container have no active own source holder in this view; their absolute death
or external retention is not measured. The shared Value type node stays held.

Independent graph bijections, semantic member walks and source-expression
bindings check complete aliases, kinds, recursive cycles and phase lifetimes.
Genuine other-call/copy/phase, alias-split, omission, false-holder and Boolean
domain controls reject. The first oracle's Boolean bridge-phase admission is
retained and reproduced; the corrected bridge comparison checks scalar types.
Replay the full finite source join from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-nested-lifetimes-20261010/verify.py
```

The Metadata/nested source container is closed. Helper, callback, subtest and
parser roles are next. Original numeric/private/provider/formatter identity,
inequality of saved CODE handles, external/global retention, the actual raw
address join and governed canonical address publication remain open. Symbolic
graph carriers and finite clone hypotheses do not establish native allocations.

Helper, callback and own subtest source bindings now cover every qualified
refusal record and throw view. The original parameterless refusal callback is
passed unchanged through the observer helper wrapper into compiled `refuses`.
Its source pattern is also forwarded unchanged. Active named helpers retain
the supplied formal references selected from their complete source graphs.

The authored subtest body and observer callback have separate source roles.
The subtest entry receives the authored body. The observer passes its wrapping
closure to the saved public subtest delegate; that closure later calls the
authored body. A displayed CODE kind alone cannot distinguish those roles.
Source forwarding binds each handle, while native CODE inequality remains open.
The intervening framework frames stay opaque.

For example, `copy($scope, 'packet', 'held')` keeps its Scope formal while the
read and write reference helpers have returned. Their result objects are held
by the active copy's source and target arguments. The observer still retains
the returned operations' caller arrays in `@api`, and the refusal helper's
caller array in `@helpers`. An inactive activation does not establish object
death. `scope_for` separately constructs its outer roots: held and output share
the supplied target type, and the omitted local formal yields a fresh empty
local hash. These are source checkpoint graphs, not later scalar-flag snapshots.

Runtime construction and forwarding agree with separate graph bijections,
named member walks and semantic source-role checks. Actual borrowed calls,
helpers, subtests and phases, lost holders, alias/cycle/kind changes and native
scope promotions reject. Replay the complete source qualification:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-helper-bindings-20261010/verify.py
```

The helper/callback/subtest child is closed. Parser receiver, actor, context and
clause source bindings are qualified below. Original numeric/provider/
formatter/Regexp/CODE identity, external framework/global retention and canonical
publication remain open. Complete source integration and the finite raw-address
join are qualified below.
All existing canonical facts, questions, probes and collection limits retain.

Parser-entry source bindings now qualify the receiver chain for both original
refused inputs in every original mode. One lexical constructor creates the
facade, its contained parser and that parser's normalization adapter. Calls
forward the same facade through the installed wrapper, saved operation and
original facade method; the facade then forwards its contained parser. These
are source construction and forwarding claims, not measured native addresses.

The default constructor checkpoint is `facade(debug=0, parser=P)`, with
`P(debug=0, adapter=N)` and `N(debug=0)`. The parser and adapter entries alias
those contained objects, rather than equal fresh objects. Constructor fields
do not establish a later heap snapshot. A source-field census also checks the
temporary procedure-synthesis state: both refused inputs contain no procedures,
so expansion returns before installing that state. The construction child below
qualifies later actor graphs; original context/source joins are qualified below.

Normalization is checked through the published Lispish input boundary and the
original own normalizer source, without inspecting the provider implementation.
For example, raw `[actor, [refused, body...]]` becomes the canonical
`[actor, refused, body...]` form. The actor selector returns the existing actor
node within the normalized forms array. The complete raw/forms/selected-root
checkpoint graph agrees with an independent normalizer and graph bijection,
including member values, node kinds and aliases. Both normalized actor contents
also agree with their earlier authored form projections. A fresh replay does
not recover the original heap payload, scalar flags or any later AST mutations.

The observer saves the original `parse_source` lookup before installing its
wrapper. Its input snapshot deliberately excludes the facade. Each wrapper
call allocates a caller array; `@parses` retains it after that call ends, including
the earlier refusal's caller during the next refusal. The saved delegate remains
held by the observer. Normalization and root-selection delegates have returned
at either refusal, while parser receiver fields and active parse locals retain
their source referents. Inactive calls do not establish object death.

Independent checks cover every receiver, AST, saved-delegate and caller argument
in the qualified parser core and operation boundary. That entry model explicitly
enumerates actor, interface, clause and local-context arguments for its successor
children. A retained-caller review also repaired an assurance gap: an earlier
caller was listed as retained but omitted from the later held set. The complete
first oracle admission remains reproducible; the repair includes that caller
in held membership and every simultaneous source distinction. A genuine
holder-loss control now rejects. Actual borrowed modes, parse records, receivers,
ASTs and callers, split aliases, missing members/holders and native-scope
promotions reject. Replay:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-parser-entry-20261010/verify.py
```

The receiver/normalization child is closed. Its construction successor is
qualified below. Original context/source and parser/helper bindings are qualified
below too. Original raw/native identity and payload, provider/formatter identity,
canonical publication remain open. Complete source integration is qualified below. Existing canonical facts, questions, probes and every
collection ceiling retain.

Complete partial actor construction is independently qualified at each original
refusal boundary. Fresh public-facade instrumentation checkpoints every reached
expansion and finalization pass, its complete actor/AST graph and receiver fields,
and entry to the aggregate-type predicate. Whole original own dependency sources
match the captured source epoch. That predicate only reads its argument and has
returned before either original refusal. Source checks bridge its probe to the
later guard and keep the intervening record publication explicit. Published type resolver contracts are interpreted from
own source; external Lispish and clone-provider implementations remain opaque.

The two inputs stop at different stages. The rejected list input still has its
initial port width and no published `type_spec`; its active resolver local holds
a detached resolved list type. The record output has already received its
resolved width and a separate cloned record `type_spec` before the field-write
context guard refuses `value.flag`. Neither input reaches final interface
metadata publication or the later timing defaults.

Construction preserves more than equal values. Type declarations are own
recursive copies of normalized AST declarations. Transaction clauses initially
refer to the normalized AST clause nodes. The `let` expansion pass recursively
copies those clauses even when no `let` appears; subsequent ordinary expansion
passes retain the copied clause nodes while replacing their outer list. The
procedure pass returns without changing that list when no procedures exist.
Resolved symbol types, port types and the active admission clone have separately
qualified graph boundaries. Equal payloads do not collapse those source nodes.

An independent construction interpreter checks complete members, scalar kinds,
node aliases and every reached pass entry/return against the fresh graphs.
Original actor, interface-entry and clause reference slots join the conserved
entry model in each original mode. The held sets include all current reachable
source nodes, saved delegates and retained caller arrays, including the earlier
refusal caller. Old clause lists retained by fresh instrumentation are excluded
from original holders. Returned delegates establish call state, not object death.
Genuine borrowed source graphs, types, stages, modes and argument bindings,
erased copies, split/merged aliases, missing members/holders and native-scope
promotions reject. Replay:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-actor-construction-20261010/verify.py
```

The actor/type/transaction construction child is closed. Original context-slot
and private-root source joins and parser/helper bindings are qualified below.
Full source integration and finite original raw-address joins are qualified
below. Native payload and flags, provider/formatter/CODE identity, cold replay
and governed canonical publication remain open. Fresh source
checkpoints are not original native captures. Existing canonical facts,
questions, probes and collection ceilings retain.

The fresh record-context boundary now has complete construction checkpoints and
an independent source interpreter. Context creation copies port roots, validates
resolved types, builds separate aggregate-root maps, prepares transaction samples,
overlays their bindings and resolves the refused write target. The final joint
graph retains arguments for every instrumented context, value-scope, sample and
reference call alongside outputs and copy boundaries;
this retention belongs to the fresh observer, not the original parser.

A public scalar experiment establishes an important representation limit. Two
fresh widths both encode as JSON integer `1` before copying. Validating one with
the own positive-integer pattern followed by a numeric comparison before
published `dclone` makes that copy encode as JSON string `"1"`; the other copy
remains integer `1`. Equal JSON
input kinds therefore do not determine copied JSON kinds. This experiment does
not inspect the provider implementation or recover original Perl scalar flags.
Replay the bounded public experiment:

```bash
scripts/run_with_ram_guard.sh -- perl docs/audits/address-parser-contexts-20261010/scalar_representation.pl
```

The source interpreter checks numeric meaning only at declared finite numeric
properties outside the conserved facade, AST and actor. Width `1` and canonical
numeric string `"1"` may denote the same source property; Boolean values, floats,
leading-zero strings, negative strings and changed numeric values fail. AST
tokens and conserved actor fields remain strictly typed. Separately, fresh replay
must match every retained typed observation exactly. No captured graph is
normalized, and numeric meaning does not establish native flag equality.

The first strict interpreter failed at a copied leaf width. That nonzero result,
its programmes and all first graphs remain retained. After correcting that
boundary, the same first graphs admitted a second assurance defect: an empty
sample-binding map and an equal fresh overlay argument were indistinguishable.
The repaired final graph includes every instrumented call argument and rejects that
well-formed alias split, as well as merged contexts, erased private copies,
missing members or stages, changed values and native-scope promotions.

The actor context, transaction context and returned target reference remain
active at the refusal. The sample lexical block has already ended before clause
validation; its output and intermediate contexts/scopes retained by the probe
are not additional original active holders. Inactive calls establish neither
object death nor a global heap census. Replay the complete boundary qualification:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-parser-contexts-20261010/verify.py
```

The representation/probe boundary child is closed. Original context-slot and
private-protocol source joins and full source integration are qualified below.
Finite original raw-address qualification is documented below. Native
payload/flag/identity qualification, cold replay and governed canonical
publication remain owned successors. Existing canonical facts,
questions, probes and every collection ceiling retain.

The complete original parser/context and helper source join now qualifies.
Every original parser reference operand is assigned once to its source binding,
including the transaction context forwarded through clause, assignment and target
reference validation. The two refusal stages preserve their different actor/type
publication states. Complete receiver, normalization, actor, clause and context
graphs join the conserved helper/callback/subtest source population.

Every successful original context API call is checked against an independent own
source interpreter, including metadata capture/snapshot, packed-range resolution
and each recursive structured-clone invocation. Complete argument graphs before
and after the call, result graphs, source package/site, order and success status
qualify. Every original private input/result joint graph bridges to the qualified
context construction. Typed original witnesses are retained exactly; numeric
permissions for recursive scalar clone operands follow their source numeric
fields, rather than arbitrary scalar argument positions.

The original observer retains each API and private-copy caller array in `@api`
and `@copies` after the call returns. All those context caller holders remain
held during the later list refusal, which runs no context API calls. They join
previous parser holders in the complete held membership and its compact relation
of every unordered source distinction. This is a source allocation relation;
it does not measure original native identity or a global heap census.

The active record context roots and returned target remain distinct from sample
preparation and old scope intermediates. The sample lexical block has ended
before clause validation. Historical outputs and argument arrays kept by fresh
instrumentation do not become original holders. Prior actor/helper/private-call
phase contracts remain conserved, including returned predicates and delegates.

Review found an assurance defect after the first complete join passed: its
returned-delegate list omitted `clone_structured_value` while checking all of
that function's recursive API events. Producer and oracle had duplicated an
incomplete constant list. The complete first admission, programmes and products
retain. Required API delegate names now derive independently from verified event
kinds, and complete successful-return event membership is explicit. Removing the
actual clone delegate or an event rejects, alongside borrowed contexts, API
graphs/sites/domains, lost slots/callers, wrong kinds/values and native promotions.
Replay the full source closure from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-parser-context-closure-20261010/verify.py
```

The context, actor/context, parser and helper/parser source children are closed.
Whole source integration and finite raw-address joins are qualified below.
Original native payload, scalar flags and identity, provider/formatter/CODE identity,
cold replay, visual book QA and governed canonical publication remain open.
All current canonical facts, questions, probes and collection ceilings retain.

Complete observer-retained caller membership is now independently qualified at
every original source refusal view. API and parser wrappers reserve records at
entry. Copy wrappers append after returning, and the helper records the consumer
boundary before evaluating its callback. A separate ordering calculation uses
those original contracts to derive the retained prefix of each caller-bearing
table at the throw. Fresh catcher checkpoints match every complete original
caller header and each independently derived prefix.

The held population includes every earlier API, private-copy, test-copy, helper,
parser and retained assertion caller array. For example, the record-context
refusal retains the earlier API callers starting at entry index zero; the later
list refusal retains them too. Nested metadata and caught outer views use their
qualified source event to select the proper checkpoint. Unwinding to that
observer catcher adds no caller-bearing record. Each prefix member has its own
source allocation domain, and a compact relation covers every unordered pair of
distinct simultaneously retained caller arrays.

The two provider-control trials for a test copy forward the same caller array
already associated with that copy. They add aliases to the held set. Encoded
input/result graph carriers do not hold the original payload referents.
Collections introduced by fresh instrumentation and discarded assertion callers
are excluded. Source allocation and retention establish neither numerical native
identity nor object death or a global heap census.

The first replay runner stopped on the recorded Storable failure because it
incorrectly required every mode to exit zero. Its programme and actual results
remain preserved. The corrected runner conserves each historical status;
provider/control failures remain failures. Complete caller membership qualifies
separately from scalar-copy behavior. Genuine earlier-holder omissions, borrowed
records and phases, wrong kinds, duplicate prefixes, lost inherited caller
bridges, false trial allocations and native-scope promotions reject. Replay the
complete retained qualification from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-observer-holders-20261010/verify.py
```

This observer-holder dependency is closed. Complete simultaneous source graph
and reference-role integration is qualified below. Original raw-address
joins, native payload/flags/identity, opaque provider/framework/formatter/CODE
identity, cold replay, visual book QA and governed canonical publication remain
open. Every existing canonical fact, question, probe and collection ceiling
retains.

Complete source graph, reference-role and lifetime integration now qualifies.
Every original source view joins the conserved operation, private-copy, Value,
Metadata, nested, helper, parser and retained-caller models. Overlapping public
frames appear once in the combined path, with complete provenance for each
original role. Parser operands retain their source-expression grammar; finite
Value and helper operands retain their typed grammar. Neither is rewritten into
native scalar or address evidence.

Graph joins follow explicit source expressions. Active named helper arguments
forward to the public operation, and direct callbacks retain their returned
reference arguments. Private-copy inputs join their selected source variables;
results remain separate copy domains. A second reader constructs full object
correspondences and connected components, independently checking every member,
reference kind, alias and cycle. Equal payloads alone establish no identity.
For example, the first refused copy has equal source and target descriptor
payloads from separate reference constructions; substituting one source role
for the other rejects. Merging its private input and result also rejects.

Private-copy delegates have returned before these guards. Copy validation still
holds both completed source and target copies, reference validation holds its
selected root, and a failing scope iteration holds its current private root.
Earlier scope-copy results acquire no post-iteration private holder merely from
having been observed. Nested metadata roots and recursion locals remain active
at the inner throw and lose their own active holders before the new outer Value
throw. Retained caller arrays persist independently of those payload lifetimes.
Returned calls establish neither object death nor external/provider retention.

Every successful API return reached inside the current helper is recorded as
inactive call state, including recursive clone delegates. Qualified helper
result holders preserve the returned references actually forwarded into active
operations. Complete parser source frames, receiver/context roots, returned
delegates and original protocol bridges remain conserved. Original observer
caller prefixes cover all earlier API, copy, helper, parser and retained
assertion records. Trial records alias their test-copy caller arrays.

Argument and checkpoint carrier arrays are symbolic graph packaging. They do
not become additional original source holders, and encoded payload graphs do
not retain their original referents. The compact distinction relation covers
all qualified simultaneous source members while preserving opaque CODE/CODE
relations. Fresh source allocation/copy hypotheses do not measure native
addresses, scalar flags, provider identity or a global heap census.

The first reader stopped because it applied the Value/helper argument grammar
to parser operands. The failed programme and actual result retain; the corrected
census covers both canonical grammars. Review then reproduced a real assurance
gap: the first successful reader ignored an extra field claiming original native
identity. Complete first admission and programme retain. Exact allowed fields
are now enforced for captures, views, bindings and operands; adding that native
claim rejects. Genuine whole omissions, equal-payload substitutions, borrowed
copies/captures/phases, lost provenance/callers/holders, inactive-root or carrier
promotion, wrong kinds and native-scope claims reject. Replay the complete source
qualification from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-source-integration-20261010/verify.py
```

The complete source integration and remaining-source-role parents are closed.
The next owned child joins original raw reference operands to these qualified
roles inside simultaneous source domains. Original raw/native identity, payload
and flags, opaque provider/framework/formatter/Regexp/CODE identity, cold replay,
visual book QA and governed non-growing canonical publication remain open.
Every existing canonical fact, question, probe and collection ceiling retains.

The original-address join now has a separate whole-input admission checkpoint.
It authenticates every declared original capture and transitive raw, class,
frame, coordinate and source-model audit member against the committed source
frontier. Complete audit namespaces retain, including historical failures and
empty error records. Every nonempty raw body keeps its exact bytes and original
capture association; source views retain their complete throw-phase allocation.

Fresh executions recheck the complete source graph/lifetime reader, the original
class/frame join and the independent hostile coordinate qualification. Their
actual commands, integer statuses, full output and invocation programmes retain.
These are saved-corpus semantic replays; they do not execute the original test
capture again. A second reader uses a separate binary Git transport, reconstructs
error membership directly from complete original captures, checks completed task
owners and qualifies the whole actual results. Lost members, empty records,
phases, programmes, borrowed bodies/successes, Boolean statuses, widened guards
and invented native scope reject.

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-raw-admission-20261010/verify.py
```

This dated admission qualifies input custody and prerequisite replay only.
The complete lossless operand partition is qualified below; original numeric
role/lifetime joins remain the next owned successor. Equal numerical addresses across calls or captures establish no
identity. Original private/native/provider/formatter/CODE/Regexp identity,
cold replay, visual book QA and governed current publication remain open.
Existing canonical facts, questions, probes and collection ceilings retain.

Complete lossless parsing of the original operands is now qualified. Each body
retains its exact UTF-8 bytes, physical segments, frame headers, argument tokens,
separators and coordinates. Empty error records remain in the complete original
allocation. Function calls, block-eval markers and the original load marker have
separate finite grammars; the displayed `require` marker retains its qualified
source `do` operator rather than acquiring a new execution meaning.

Own arguments associate with their complete qualified source throw view and
public-frame positions. The nested Value capture eval has a separate coordinate
contract between the component frame lists and is conserved explicitly. Both
existing source reference-description dialects retain: a blessed class can be
separate from the reference kind or included in its display spelling. Neither
spelling proves native class, payload or object identity.

Every hexadecimal lexeme has a full-body byte span and an operand category.
Own reference displays and opaque framework reference displays remain separate.
Quoted strings retain escapes and truncation, regex displays retain their text,
and a final `...` preserves hidden arguments without inventing their addresses.
For example, a displayed `HASH(0xab)` is a reference token; the synthetic quoted
string `"HASH(0xab)"` is scalar text, and `qr(0xab)` is a regex display. Separate
synthetic Unicode, escaped-quote and embedded-trace challenges check the grammar.
They are explicitly separate from the original capture evidence.

In this finite original corpus every hexadecimal lexeme occurs in a visible
reference display. No original hexadecimal lexeme occurs inside a quoted
scalar, quoted embedded trace, regex display or other opaque text. Nested raw
child exceptions and their new outer throws remain whole, with source messages
and visible truncated quoted arguments conserved. The synthetic challenges do
not establish original observations in the absent categories.

The producer partitions bytes; a separate reader scans character nesting and
quotes directly from the original captures, reconstructs allocation and checks
the complete prior physical segmentation. Whole omissions, borrowed bodies,
frames, phases and hex operands, quoted/reference confusion, hidden-argument
promotion, wrong kinds, lost nested forwarding and invented native claims reject.
Fixed committed inputs, actual failed/corrected runs and complete proofs retain:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-raw-operands-20261010/verify.py
```

This closes the lossless operand-parser child. Original numerical equality and
distinction joins are qualified separately below. Equal numbers across calls
or captures establish no identity. Original private/native payload
and flags, provider/formatter/CODE/Regexp identity, cold replay, visual book QA
and governed current fact publication remain open. Existing canonical facts,
questions, probes and collection ceilings retain.

Before numerical joining, a completeness review found a source-holder gap in
the earlier integrated relation. Some saved-operation CODE arguments in active
`main::call_api` frames were associated with their source roles but absent from
the named-holder union. The original observer assigns that argument to the
lexical `$operation` parameter and invokes it inside `eval`. The parameter
remains active when the invoked operation throws.

For example, a refused copy calls the saved `validate_record_port_copy` handle
through `$operation`. Its active parameter retains that source CODE handle
alongside the source and target roles. A returned operation has no such active
parameter at the later checkpoint. Neither statement measures native CODE
identity or external retention.

A separate source supplement now qualifies this retention. It conserves every
whole earlier source view, graph/role identity, named holder, retained caller
prefix, private lifetime, inactive binding and distinction. Only the missing
explicitly forwarded saved-operation parameters become additional holders.
The complete finite distinction relation is recomputed over the supplemented
source population; CODE/CODE pairs retain their opaque identity boundary.
Counts describe members and relations per source view, never a native heap.

The byte-based producer binds the entire original observer function. A separate
reader selects its complete named source lines, independently enumerates caller
members and reconstructs all prior and supplemented relations. Lost arguments,
borrowed phases or returned calls, private/inactive roots, symbolic carrier
promotion, wrong kinds and invented native identity reject. Historical source
products retain unchanged; the correction is an explicit additional contract:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-raw-join-20261010/verify.py
```

The holder completeness defect is fixed and independently verified. Original
numerical equality/distinction joins and full raw-parent acceptance are
qualified below. Private/native payload and flags, provider/formatter/CODE/Regexp
identity, cross-call reuse, global heap census, cold replay, visual book QA and
governed current canonical publication remain open. Existing canonical facts,
questions, probes and collection limits retain.

Original numerical joining is now independently qualified for the complete
finite capture corpus. Each own visible reference keeps its full-body UTF-8
span, display spelling, reference kind, source role and provenance. Its hex
lexeme becomes an exact integer key; it never passes through a floating-point
number or becomes a global object identifier.

The join operates separately inside each qualified simultaneous source throw
view, using the complete corrected holder relation. Explicit source aliases
have the same displayed number. Qualified distinct source bindings have
different displayed numbers. Distinct CODE bindings remain opaque even when
their observed numbers agree or differ. Regex displays preserve their text;
hidden arguments preserve their source intervals without invented addresses.
Framework reference operands stay outside the own-source identity relation.

For example, the following synthetic interpretation illustrates the contract:

```text
source role, first slot: HASH(0xab)
source role, forwarded slot: HASH(0xab)
distinct live target role: HASH(0xcd)
```

Changing only the forwarded slot to another actual displayed number breaks
source-alias agreement. Changing every source-role occurrence to the target's
number preserves source aliasing but breaks simultaneous source distinction.
Consistently renaming the whole source alias class to an unused number can
preserve those relations, yet still fails its exact original-byte association.
These are separate checks. The synthetic illustration establishes no original
observation; the retained controls intervene on actual saved display numbers.

The producer exhaustively derives the finite relation. A separate reader starts
from the original capture bytes and qualified source/coordinate views, parses
reference spans and interprets hex with an independent digit accumulator. It
checks source-to-number alias agreement and number-to-source separation before
checking every exact original operand. Genuine whole-product borrowed-number,
collapsed-distinction, wrong-kind and wrong-domain controls reject at their
intended contracts. Numerical controls conserve all earlier input products and
nonnumerical source, holder, slot and domain meanings; no altered original
capture is admitted through the fixed-byte custody gate.

Complete empty/nonempty allocation, raw bodies, nested forwarding, regex and
opaque external operands retain. Whole fixed inputs, complete numerical product,
independent programmes and actual results are replayable:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-numeric-join-20261010/verify.py
```

This closes the numerical-join child only. Full unchanged raw-parent acceptance
is qualified separately below. Provider/formatter/native identity, payload and flags, CODE/CODE and
Regexp identities, numerical reuse across calls or captures, heap census, cold
replay, visual book QA and governed canonical fact publication remain open.
Existing canonical facts, questions, probes and collection limits retain.

Full observer joining remains a prerequisite for complete raw-stack closure.
The earlier finite class/frame join qualifies visible source prefixes and
whole-body custody. Complete observer headers and exact quoting/truncation
remain owned by the still-open original observer join.

A dated diagnosis shortens one actual truncated public subtest-name display
to another proper source prefix. The limited prefix predicates accept it;
the full historical reader rejects the changed body at its custody gate.
Both contracts behave as declared. Neither result qualifies the pending
full-header contract or measures original formatter/settings identity.

Replay the complete dated source, candidate and actual-result diagnosis:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-join-prerequisite-20261010/verify.py
```

Full observer repair and publication precede raw-stack closure. Class/frame
parents and raw-stack acceptance remain open; coordinate/address qualifications
and all separately owned native, cause, consumer, alias and cold scopes retain.

The public display prerequisite now qualifies a complete dated source-neutral
fixture corpus. Source hypotheses precede its fresh native capture; a separate
oracle reconstructs every whole token, source lifetime and raw body. Original
observer headers and original formatter/settings identity remain open.

These examples describe the selected current public fixtures only:

| Source argument and profile | Qualified display |
| --- | --- |
| Scalar `V$W`, default profile | `"V\$W"` |
| Scalar `V@W`, default profile | `"V\@W"` |
| Scalar `V`, newline, `W` | `"V\x{a}W"` |
| Selected nonnumeric 65-character argument, length limit 64 | Quoted first 61 characters followed by `...` |
| Numeric-looking string of 65 digits, length limit 64 | All 65 digits, bare |
| Wide regex longer than the length limit | `qr(prefix)...u` |
| No arguments, count limit -1 | `...` |

The selected limits below 3 leave strings unshortened. Truncation uses source
characters before escaping. Regex display retains its selected constructor
flags and bypasses the general reference formatter in these fixtures; the own
`CARP_TRACE` hook takes priority for its selected object. Plain reference
addresses join only simultaneous held source values, with explicit aliases.
No cross-call or original-capture address identity follows.

The first full corpus rejected incomplete escape, numeric-order and regex
hypotheses. Every failed source/native/result epoch is retained. An earlier
investigation miscounted a saved 65-digit display as 61 digits; whole-source
and display remeasurement withdrew that assertion. Loss metadata records
actual shortening, and hostile controls reject both false loss and promotion
of a genuinely truncated value to a complete source value.

Replay the whole finite qualification, independent controls and source custody:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-display-contract-20261010/verify.py
```

This completes the public prerequisite only. Complete source-generated
original headers, their original-body join and observer publication still
precede full raw-stack closure. All native/provider/private limits retain.

The complete source-header prerequisite census now retains every qualified
observer case, throw phase, ordered group, frame, operand and load role. Its
recursive producer and independent explicit group reconstruction agree on the
whole source model; original trace display supplies no new semantic oracle.

The census exposes source-value obligations before exact header generation.
A failed predicate gives logical false without selecting zero, an empty string
or undef as its displayed token. Context operands explicitly leave scalar
encoding unmeasured. Regex source patterns retain their complete bodies while
constructor flags and encoding require separate qualification. Entire inherited
serialized inner operands remain dated evidence, with their prior scope.

Original display settings, native reference identity, public receiver tokens
and private framework intervals retain their unmeasured boundaries. Source
`do` loading and the diagnostic `require` marker remain distinct roles.
Whole-product omission, borrowing, reordering, role, schema, scope and premature
header-closure controls reject. Replay the complete source-only census:

```sh
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-header-source-census-20261010/verify.py
```

Source-value qualification precedes full source-generated headers, the
original-body join and observer publication. Their unchanged parent acceptance
remains open, together with the separately owned native and visual scopes.

The complete finite raw-address and numerical/source parent acceptance is now
qualified. The audit preserves the full unchanged parent requirements and the
complete previously committed child contracts. It joins every original empty
and nonempty record, whole raw body, source throw phase, lossless operand,
corrected holder and numerical source association to its complete evidence.
Matching endpoint totals alone cannot satisfy this contract.

The admission, operand, holder and numerical readers each execute again. Their
complete commands, integer statuses, output streams, guard settings and
invocation instruments are qualified separately. Historical failures retain
their original results. Older readers still report their own dated successor
boundaries; a successful prerequisite result does not silently widen its scope.
The parent audit establishes the combined finite contract explicitly.

A separate reader enumerates the original captures directly and matches every
body and source phase to the complete parsed, source, holder and numerical
products. Every source occurrence remains in its visible or unaddressed slot;
original reference bytes and source provenance retain. All earlier genuine
semantic controls stay associated with their qualified products. New complete
witness controls reject lost or borrowed bodies, phases, source models,
operands and controls, weakened acceptance, omitted opaque scopes, Boolean or
nonzero statuses, borrowed commands, shortened outputs and widened guards.

For example, borrowing an otherwise valid numerical view from another throw
fails its original body/source/holder association. A success line from the
holder reader cannot stand in for the numerical reader: its full command,
programme identities and expected output belong to a different contract.
None of these checks creates native object identity or merges source domains.

Whole fixed prerequisite namespaces, semantic products, task contracts and
actual results retain with the independent replayable parent witness:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-parent-acceptance-20261010/verify.py
```

Only the raw-join and numerical/source parents close. The address/lifetime
container remains active until governed canonical publication qualifies. Native
payload, flags and identity, provider/formatter/CODE/Regexp identity, numerical
reuse across calls or captures, heap census, cold replay, visual book QA and
HIAL/full-CI/push qualification retain their separate owners. Existing canonical
facts, questions, probes and collection limits remain unchanged.

Retained address preparation checkpoint (before current admission):

Governed address publication now has a retained prospective preparation.
The complete current core, helper, parser and tooling cards remain unchanged.
Their full beforeimages, reader programmes, book sources and capacity authority
are bound to the committed source epoch. The original global source membership
and complete direct and cached question allocation also retain.

The reviewed prospective texts preserve every existing question, replay command,
source obligation and native limit. Their ordered paragraph correspondence keeps
the exact originals alongside the proposed wording. Separately qualified finite
source and numerical address roles update the source-only gaps; native object
identity and address reuse across calls or captures remain unqualified. The
complete proposed card working set shrinks under unchanged collection authority.
Natural-language proposition equivalence is a recorded review, not a universal
automated proof.

Fresh complete integrated-source and raw-parent readers pass. A separate reader
reconstructs all fixed source bytes, original global metadata and query ownership,
prospective question/probe metadata, ordered correspondence and measured working
set. Genuine whole-proposal omissions, borrowed text, native-promotion claims,
Boolean results, lost questions/probes and widened authority reject. Earlier
over-budget drafts remain unadmitted. The first audit import-path failure and
its premature dependent invocation retain their actual nonzero outcomes; the
corrected sequential producer and verifier pass without editing live cards.

Final review also found an independent-reader schema defect. Before any prior
proof existed, the saved reader accepted an extra native-identity field because
it used the proposed input as its own expected schema and value authority. The
complete actual false green, candidate, source and generated proof retain.
Explicit independent declarations and fixed Git member/beforeimage reconstruction
now close that gap. The repaired exact reader rejects unknown fields, native
scope or review changes and borrowed beforeimage locators before any seal, with
no proof write. The original proposal stays unchanged; the final qualification
is separate from the retained first limited proof.

Replay the retained preparation in its explicit snapshot role:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/address-publication-preparation-20261010/verify.py --snapshot
```

This proves prospective source retention and reviewed preparation. It does not
establish current canonical address publication. The next child must admit the
exact beforeimages through governed history and update cards and the maintained
current reader atomically, then qualify complete current source, global queries
and native book delivery. Full unchanged publication/address-container acceptance
follows separately. Existing native/private/provider/formatter/CODE/Regexp,
heap/cold/visual/HIAL/full-CI/push limits retain their owners.

Raw-coordinate qualification first admits the complete predecessor source and
actual-result evidence. Its saved admission checks the dated source epoch; it
does not establish coordinate meanings or later current currency:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-admission-20261007/verify.py
```

The historical publication's independent result qualifier expects its original
fact, book and authority epoch. It rejects later live publication changes.
Admission executes that unchanged qualifier in a disposable same-volume copy of
the committed epoch and checks every source member before and after, preserving
the live sources and removing the fixture. The maintained current reader above
separately checks present currency. Independent coordinate source recipes and
the original-coordinate join remain pending; original private, formatter and
toolchain identities remain unmeasured.

The current reader also independently consumes this committed admission’s complete
historical and native result evidence before checking present source currency.

The own-source coordinate catalog now binds complete guard/call, named function,
observer wrapper, callback and subtest source spans to their exact UTF-8 bytes
and lexical line ranges. It preserves ordered observer generation and the
original fixture-root invocation recipes. Lexical spans do not yet select
runtime call-site lines or qualify original raw coordinates:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-source-catalog-20261007/verify.py
```

Public coordinate hypotheses preserve the source-selected first and closing
line and filename alternatives fixed before observations. Dated executions
retain complete source, command, output, frame and error bytes. For these own
fixtures, multiline calls and block eval boundaries select their opening lines;
when both source alternatives occupy the same line, both labels remain valid.
The readers replay pre-native sources, captured custody and caller/boundary
selection. Their historical scopes remain separate from the native-control qualification below:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-hypotheses-20261007/verify.py
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-capture-20261007/verify.py
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-caller-selection-20261007/verify.py
```

Public origin hypotheses now bind the complete own observer calls, outer
invocations, boundaries and longmess/confess statements to source alternatives
and full public Carp/eval documentation before origin interpretation.
Carp global, internal and formatter settings remain unmeasured.
The source model selects no trace/error origin yet:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-origin-hypotheses-20261007/verify.py
```

For the retained public captures, longmess origin headers join the observer
call sites. Confess headers join the own confess statement inside eval.
These headers qualify only the retained public fixtures. Every raw header and
following trace byte remains intact; private frames and formatter settings
remain unmeasured. The saved origin reader preserves all matching source
alternatives and rejects borrowed source, line, message and scope candidates:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-origin-selection-20261007/verify.py
```

Native control plans now retain complete own fixture variants, exact source
changes and expected caller, line, invocation-root and borrowed-source refusals.
Each fresh control root is valid for capture custody. Root qualification compares
its actual location with the unchanged base invocation; source controls compare
coordinates with the unchanged good declarations. The source-only reader checks
the committed pre-execution plans:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-native-control-plans-20261008/verify.py
```

Dated native executions now retain complete variant sources, raw caller frames,
trace/error bytes, public tool metadata and per-run checkpoints in their declared
fresh roots. The custody reader verifies these saved results without executing
the captures again. Its dated custody scope remains separate from semantics:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-native-control-capture-20261008/verify.py
```

The saved native variants now qualify their precommitted caller, line and borrowed
filename refusals against the unchanged good-source predicates. The source-identical
fresh-root variant passes all caller, boundary and origin checks, then refuses the
unchanged base-root admission. Independent binary-source and whole-wire reconstruction
preserves every actual root, source difference, raw frame, argument and error byte.
This closes finite native falsification; final public recipe/fact publication and
original/private/formatter/toolchain/address identities remain open. Read saved
semantic results without executing any capture:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-native-semantic-20261008/verify.py
```

The complete finite public qualification now authenticates the whole committed
source, caller, boundary, origin and native-control domains and consumes their
fresh independent results. Every selected and coincident source alternative,
raw byte and intended native refusal retains its original dated scope.
The joined reader checks saved data and preserves explicit identity gaps;
the canonical reader below now replays the dated public reference; final public parent closure precedes original-coordinate intake:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-qualification-20261008/verify.py
```

The dated finite public recipe reference exposes every declared call, boundary,
origin alternative and intended native control refusal. Its source statements,
byte identities, invocation roots and selected line labels come from the complete
qualified captures above. The complete raw qualification remains the authority
for every frame, argument and trace byte; this reference links its exact identity.

| Retained public fixture meaning | Source-selected recipe |
| --- | --- |
| Own caller and eval boundary | Select the declared call target, legitimate source filename and opening or closing lexical line. Preserve both labels when the alternatives coincide. |
| Multiline call and block eval | The recorded cases select their opening line. |
| longmess origin | Join the header to the own observer call statement. |
| confess origin | Join the header to the own confess statement inside eval. |
| Native controls | Wrong caller, line and borrowed filename refuse their precommitted coordinate predicate. The source-identical fresh-root case passes coordinates, then refuses unchanged base-root admission. |

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-reference-20261008/verify.py
```

These recipes describe the retained own fixtures. Public configuration/private
formatter state and original/provider/toolchain identities remain unmeasured.
The canonical tooling card now adds a dated public-fixture question and reader
link while preserving its original ordered questions and reviewed propositions.
Its physical byte total decreases; collection authority stays unchanged.
The maintained current reader replays the complete public reference before
checking present canonical source, question and native copied-byte currency.
Final public parent closure remains pending; no original-coordinate intake is
admitted by this reference.

Find the public-fixture route or replay its exact source/question/capacity evidence:

```bash
knowledge-map/scripts/query_knowledge_map.sh 'where are public coordinate recipes verified?'
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-coordinate-public-route-20261008/verify.py
```

The wording review conserves the named old propositions; exact byte, question,
source, census and actual-result controls are separate executable checks.
Original coordinates/identities remain unmeasured; visual QA remains pending.

The own subtest source model now assigns original refusals to their complete
authored named bodies. The observer saves the public subtest delegate, wraps the
callback with its helper observer and forwards callback and extra arguments.
The original authored bodies supply no extra arguments. Recorded headers agree
with empty visible body/callback arguments, the authored subtest name and a CODE
reference kind at the public delegate and own entry. Framework frames between
these own roles remain opaque; a CODE kind does not establish callback identity.

The original observer loads the test with do and captures its return/error state.
The recorded require marker agrees with the exact test file identifier; it does
not change the source operator or establish trace formatting. Captured installed
public POD supports the call/load interfaces for the current toolchain. The
original framework version remains unmeasured. Complete source and recorded-role
qualification is in docs/audits/record-value-own-subtest-boundaries-20261005;
the semantic fact topic now publishes these qualified own source boundaries.
Public framework/display, source-coordinate and native identity gaps remain open.

The original source-plane reader's historical replay also invoked the older
live helper reader. An actual source-qualified card extension exposed that
coupling: a new live fact obstructed replay of unchanged historical evidence.
The qualified adapter preserves the original plane predicates and products,
changing only that call to the helper's existing snapshot mode:

```bash
python3 -B docs/audits/record-value-helper-reader-role-adapter-20261005/adapter.py --snapshot
```

This command authenticates historical evidence. It does not qualify current
cards, queries, source assets or advertised reader guidance, and it rejects a
current-role flag. Current semantic/fact/source qualification uses the
publication reader below; its historical leg remains separate.
Original historical programmes and seals remain unchanged.

The finite-copy core keeps its original fact ID and direct path. Its observer and
helper questions now route to a separate bounded semantic topic, with a return
route to the core. This separates copy-graph qualification from the original
helper allocation, supplied/default inputs, returned argument construction and
callback/refusal paths. The historical publication preserves the original source meaning and question
ownership. Its default snapshot replay remains available below; use the new
observer command above for current facts, queries and source roles:

```bash
python3 -B docs/audits/record-value-own-boundary-publication-20261005/verify.py
```

This topic uses the capacity recovered by the admitted collection rollover.
Existing collection bounds remain in force; rollover debt remains open. The
separately owned subtest/require, framework/display, raw-coordinate and native
address/object-identity gaps remain explicit in both semantic topics.

The superseded helper reader retains its original whole-card current epoch.
Its default replay preserves the historical source census and book authority;
the new observer current command above qualifies this admitted extension.
The tooling companion's old current route still needs its immediate owned repair.
Relevant source, question and route changes require qualification; unrelated
book progress does not invalidate the scoped observer reader.

The superseded publication snapshot preserves the own subtest/do-load source
facts and tooling question routes. It authenticates the historical source-plane
adapter separately. The new current reader above checks canonical source-view selection,
endpoints, bytes, ignore policy, budget and complete staged membership. Snapshot
success does not supply current semantic currency. The original destination
locality replay and explicit native copied-byte check remain required.

The complete own parser context replay
joins the finite parser/API core, observer operation, helper and subtest/load
source roles throughout every retained refusal. Per-phase core order, operation
overlap, wrapper/helper/body/entry/load adjacency and complete own frame coverage
agree. Completed nested API allocations conserve separately; their empty error
footprints supply no active throw frames.

The source-only guides below retain their inventory/model roles. This context
replay adds the finite frame join; full current fact publication is qualified
below. External framework intervals, original formatter/provider versions,
scalar encoding, hidden suffixes, referent contents/identity, coordinates and
addresses remain unmeasured. The source load operator stays do; the recorded
require marker agrees only with its file role. Replay from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-context-join-20261006/verify.py
```

The parser argument-role replay
binds all supplied source argument slots to retained visible header footprints.
Scalar glyphs and proper visible prefixes agree; receiver labels and reference
kinds match their declared source roles. The guard's normalized false value is
compatible with the observed false display, without treating it as native zero.
Whole headers and raw bodies conserve after those comparisons.

These are positional source roles and visible footprints. Same-kind reference
identity, receiver/AST/partial-actor contents, hidden suffixes, scalar flags,
exact truncation and original formatter versions remain unmeasured. The complete
own API/helper context replay above joins these roles. Replay from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-argument-roles-20261006/verify.py
```

The separate parser function-order replay
now binds independently selected own parser/context ancestry to every retained
parser refusal and throw phase. It preserves complete raw bodies and opaque
outer intervals and excludes returned delegates from active own frames.
Genuine raw function/order and complete mode/member/kind controls reject.
This qualifies own function order only. Visible arguments and own API/helper
context have separate qualified replays above. Formatter, coordinates and
reference identity retain separate owners. Replay from the repository root:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-function-order-20261006/verify.py
```

The original parser source inventory binds complete own facade, parser and
record-context source units, lexical declarations, selected whole function bodies,
parameter roles and ordered call/guard statements. Output-field source admission
and aggregate actor-port admission have distinct source boundaries. This inventory
does not establish active failure paths or native argument meanings. The finite
source models below qualify own ancestry and argument roles; complete
own frame joins have their separate replay above.

The initial new-card proposal exceeded the collection file allowance and was
withdrawn. Its complete source proof and candidate publication remain immutable.
The qualified provenance now extends the existing source-context topic while
preserving its prior body, identity, questions and verification command. The
source-model reader preserves its dated publication snapshot:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-path-models-20261006/verify.py
```

The original source reader defaults to historical replay; its withdrawn live
proposal is not current authority. This publication reader separates that source
proof from live fact, query, capacity and guide checks. Framework/display,
coordinates, native identity and broader consumer/alias/cold meanings remain
separately owned. Visual QA is pending.

The finite source models now distinguish active own ancestors from returned
delegates. List actor-port admission stops at the aggregate type guard before
record-context validation. Output-field admission reaches the transaction write
guard before assignment RHS validation or actor publication. Both models retain
every supplied positional and named argument role as a source expression.

Receiver, normalized AST and whole partial-actor payloads remain unmeasured.
The independently evaluated original Perl guards agree with the finite model.
Complete nested API membership reuses the dated qualified source-family models;
it does not establish a new native stack. Own frame joins are qualified above;
public formatter, coordinate and address contracts remain separate work.

The source-model reader preserves its qualified source meanings and dated
publication snapshot. Current finite-join qualification has its own reader
below. Historical replay does not supply current semantic currency. Visual
QA is pending.

The parser source and frame publication below is a retained checkpoint.
It qualifies the original source inventory, source-expression roles, visible
function and argument footprints, complete own operation/helper/subtest phases
and completed nested allocations. False denotes a source predicate, while
reference kinds and prefixes do not establish referents or hidden suffixes.
Its earlier `--current` role checks its dated card, question and book epoch:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-path-publication-20261006/verify.py --current
```

For current parser facts and original own coordinates, use the complete
maintained current reader above. Its native variant checks every current copied
source and the rendered guidance. Default parser replay preserves its original
sources and saved publication snapshot; historical success supplies no current
currency:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-parser-path-publication-20261006/verify.py
```

Framework/provider, formatter, scalar encoding, hidden identity, external
coordinates and addresses remain unmeasured or separately owned. Visual QA
remains pending.

[portable replay repair](reference-source/docs/audits/record-value-replay-portability-20261004/scope.txt.source.txt)
now binds each Python process filename to its exact invoked reader. The original
comparison rejects identical semantic controls at a second working root; the
superseding complete field/actor join passes there while preserving all other
frame, source-line and message bytes. Root paths inside argument/error text stay
exact. All source/typed/native/field/actor meanings and rejecting controls
conserve for the recorded interpreter/input profile; native copy/cause assurance
remains separate.

The resource helper and adjacent preparation assertion now compare complete
resource context and reasons. Real earlier unsupported statements, including
primary messages containing wanted codes, reject. The
[resource cause repair](reference-source/docs/audits/formal-resource-cause-repair-20261003/scope.txt.source.txt)
retains exact prior failures and a genuine resource-validation bypass that makes
the repaired test fail. Compiled observer controls keep expectations out of
active eval-source frames. Complete ordinary products are conserved; pointer
records and update rosters have finite independent models, while wider internal
semantics remain under cold review. Aggregate-record and other
named/framework cohorts stay open.
The [reusable-product diagnosis](reference-source/docs/audits/reusable-product-helper-causes-20261003/scope.txt.source.txt)
finds the same cause gap in library/ATL admission helpers and one adjacent
parent-width assertion. The [complete-cause repair](reference-source/docs/audits/reusable-cause-repair-20261003/scope.txt.source.txt)
now rejects real earlier unknown-child causes and primary echoes, while retaining
the full library/ATL and parent-width reasons. Exact prior checks and a genuine
library collision bypass fail; ordinary products are conserved. Its ordinary
products also expose two distinct primitive-kind gaps: the test projection's
Storable copy lost numeric JSON kinds in FIFO indexes/bindings and ATL movement
widths. The [projection-copy repair](reference-source/docs/audits/reusable-projection-kind-repair-20261003/scope.txt.source.txt)
uses a scalar-preserving source copy and first-touch JSON snapshots. Whole
source metadata and reusable-product checks now distinguish strings from numbers;
restoring the exact old copier makes the strengthened checks fail. The private ATL output-width
check now compares a detached scalar, preserving the complete caller on both
accepted and refused routes. The [width-kind repair](reference-source/docs/audits/atl-source-width-kind-repair-20261003/scope.txt.source.txt)
retains identical preparation/module outputs and exact prior failure controls.
The formal resource, reusable and reservation cause/copy repairs are complete;
aggregate-record and remaining cohorts still require review. These repairs
add no composition or HDL runtime support. Whole constructor and child-internal semantic qualification remains open.
The [prepared-reservation diagnosis](reference-source/docs/audits/prepared-reservation-helper-causes-20261003/scope.txt.source.txt)
finds unrelated unsupported-reference causes accepted by the test helper and an
adjacent cycle assertion. Primary paths containing the expected phrase also fool
fragment checks. The production collector rejects those inputs correctly;
the [complete-cause repair](reference-source/docs/audits/prepared-reservation-cause-repair-20261003/scope.txt.source.txt)
now rejects those unrelated causes. Exact old checks and a genuine preparation
membership bypass fail. Ordinary scope products conserve. The
[snapshot diagnosis](reference-source/docs/audits/prepared-reservation-snapshot-diagnosis-20261003/scope.txt.source.txt)
found that the former test clones changed generated child assignment numbers to
strings, while value-only assertions missed a deliberately injected kind-only
input mutation. The [snapshot repair](reference-source/docs/audits/prepared-reservation-snapshot-repair-20261003/scope.txt.source.txt)
preserves those numeric source values in detached fixture copies. For example,
an assignment value `1` stays numeric instead of becoming the string `"1"`.
First-touch comparisons retain complete scalar kinds and plain reference sharing,
including the cycle control. Real Storable and kind-only mutation controls now
fail the strengthened test; the preparation-membership bypass still fails.
The actual collector preserves its complete inputs and ordinary scope products.
The empty native marker control has only an identity/empty-shape contract;
arbitrary unsupported referents remain unqualified. Whole ordinary scope/token
inventories have independent finite models, while wider constructor semantics
and moved-root qualification remain open.
The [bounded coverage profile](reference-source/docs/audits/reservation-coverage-helper-causes-20261003/scope.txt.source.txt)
preserves the actual final-coverage calls and refusal consumers. The verifier
preserves its actual inputs; some test Storable copies change numeric scalars
into strings. For example, a numeric assignment value can become `"1"` in a
detached test copy. The [actor-copy qualification](reference-source/docs/audits/reservation-coverage-source-copies-20261003/scope.txt.source.txt)
binds changed FIFO bank indexes/binding widths and vector ATL route width to
source declarations. Scalar-preserving actor copies retain complete source
kinds and sharing; complete ordinary lowering results, emitted carriers and
coverage scope records agree with the original test. The [module capture](reference-source/docs/audits/reservation-coverage-module-capture-20261003/scope.txt.source.txt)
binds complete module originals and deeply isolated pure copies to the source
and original coverage profile. Ordinary lowering/carrier/scope results agree.
The [generated-field qualification](reference-source/docs/audits/reservation-coverage-generated-module-fields-20261003/scope.txt.source.txt)
checks readiness/request/completion RHS, monitor set/clear/reset constants,
provenance and declared widths. Unused worker width metadata stays separate
from emitted port declarations. The [reusable-field qualification](reference-source/docs/audits/reservation-coverage-reusable-module-fields-20261003/scope.txt.source.txt)
checks storage RHS/widths and FIFO slot indexes, binding widths, selection guards
and provenance carried through preparation. The [ATL-field qualification](reference-source/docs/audits/reservation-coverage-atl-module-fields-20261003/scope.txt.source.txt)
checks trigger/completion/timeout constants, copied fan-in source RHS and vector
endpoint widths through child ports, top links and prepared wiring. The
[module join](reference-source/docs/audits/reservation-coverage-module-join-20261003/scope.txt.source.txt)
reconciles every captured module field and actor-only preparation difference
with those models. The [snapshot capture](reference-source/docs/audits/reservation-coverage-snapshot-capture-20261003/scope.txt.source.txt)
binds every successful/refused snapshot and module/allocation mutation seed to
actual original and pure-copy graphs. [Ordinary snapshot fields](reference-source/docs/audits/reservation-coverage-snapshot-normal-fields-20261003/scope.txt.source.txt)
qualify child pulse/provenance, inherited and vector endpoint widths, and private
formal mutation-seed widths against source and actual carriers. The
[producer-removal fields](reference-source/docs/audits/reservation-coverage-producer-removal-fields-20261003/scope.txt.source.txt)
qualify the rebuilt input: widths, assignment ordinals, declaration membership,
handshake/wait metadata and numeric producers retain distinct meanings. String
completion constants stay strings. The [snapshot field join](reference-source/docs/audits/reservation-coverage-snapshot-field-join-20261003/scope.txt.source.txt)
reconciles every changed field and unchanged-copy control with the completed
models. [Real value-only controls](reference-source/docs/audits/reservation-coverage-value-only-controls-20261003/scope.txt.source.txt)
change numeric `1` to string `"1"` in a caller provenance field after an actual
successful or refused call. The pre-repair test stays green in both cases, so its
value comparison does not prove caller-kind preservation. The prospective
[plain/native helper boundary](reference-source/docs/audits/reservation-coverage-plain-native-boundary-20261003/scope.txt.source.txt)
preserves captured primitive kinds, aliases, cycles and deep copy isolation.
Actual broken-sharing controls reject. Its snapshot distinguishes a replaced
empty native marker by identity and refuses undeclared native classes or shapes.
The [actual native snapshot join](reference-source/docs/audits/reservation-coverage-snapshot-native-join-20261003/scope.txt.source.txt)
replays all intended and wrong-cause cases with their original marker identities,
classes and empty shapes. Replacing one marker after a real refusal fails the
existing identity assertion while complete causes and value graphs stay unchanged.
The [complete coverage qualification](reference-source/docs/audits/reservation-coverage-qualification-join-20261003/scope.txt.source.txt)
now joins every initial/current copy site and observed field with its actor,
module or snapshot semantic owner. Unchanged seeds remain required controls.
The [live coverage copy repair](reference-source/docs/audits/reservation-coverage-copy-repair-20261003/scope.txt.source.txt)
now uses scalar-preserving copies and snapshots. For example, numeric `1` remains
numeric in a copied provenance field, and replacing it with string `"1"` after a
real call fails the read-only assertion. Each copy checks complete kinds/sharing,
reference population and source isolation. Returning an equal aliased module
fails isolation; restoring the lossy copier fails kind preservation. Replacing
an empty native marker fails the helper snapshot and identity assertions while
the intended complete cause stays unchanged. Complete preparations, lowerings,
exported carriers, scope results and refusal causes are conserved against the
qualified prior recipe. The [historical replay context](reference-source/docs/audits/reservation-coverage-historical-context-20261003/scope.txt.source.txt)
keeps this complete qualification bound to its original sources when later test
helpers change; separate native checks qualify the repaired behavior. The
[repaired-source context](reference-source/docs/audits/coverage-repair-historical-context-20261004/scope.txt.source.txt)
also pins the complete repaired coverage proof before unrelated metadata test
edits. A sole projected metadata-test comment fails the original source identity
check. Both complete contexts replay through the primary canonical reader;
future hot changes keep their own validation obligation.
These controls do not establish a production defect.
The [coverage cause diagnosis](reference-source/docs/audits/reservation-coverage-cause-diagnosis-20261003/scope.txt.source.txt)
finds that the test helper accepts unrelated unsupported-reference failures when
the wanted phrase appears in its caller stack or an unrelated failure path. For
example, a path containing `incomplete parent/domain modules` fools the fragment
check even though the actual cause is an unsupported reference. The verifier
rejects those inputs correctly. The [coverage cause repair](reference-source/docs/audits/reservation-coverage-cause-repair-20261003/scope.txt.source.txt)
now saves native errors immediately and compares independently declared complete
causes. Permanent native controls reject both unrelated failure forms. Exact prior
checks still fail the desired safety controls, and the actual declaration guard
bypass fails the repaired test. Complete ordinary inputs/results conserve; the
original test-copy kind drift remains owned. Copy-field and wider constructor
qualification remains separate.
See the [bounded membership record](reference-source/docs/audits/named-helper-membership-20261003/scope.txt.source.txt)
for exact units, source boundaries and remaining review ownership.

This observer preserves the existing first-clause behavior, including current
macro placement defects and inline-procedure `cond` refusals. Imported/reusable
formal propagation, generated specialization, domain construction and production
metadata adoption remain separately owned prerequisites before normalization or
branch integration. No public syntax, report schema or admission changes.

Repeat-body activation matrix note: the shipped nested-repeat activation shapes
under top-level `when` and `switch` branches are described by construction, not
by an exhaustive list of spellings. The accepted context is a repeat directly
inside a top-level branch body. The accepted activation kinds are local `do`,
generated-child `do`, generated `do` with static `(params ...)`, that generated
`do` with `(bind ...)` handoffs, and that generated `do` with optional bind
handoffs plus same-domain metadata.

The lifetime rule is the same for every accepted spelling: a blocking `do` must
observe its own fresh done handoff, generated-top parameter/binding handoffs
stay scoped to that generated `do` instance, declared same-domain metadata
records ownership without adding CDC, and every pending generated-spawn done set
remains live until a later same-body `await_all` drains the exact set before
nested repeat re-entry. `await_any` remains observation-only, including prior
observations before the `do`, post-`do` observations, and second post-spawn
observations; it never replaces the mandatory final `await_all` when more than
one generated child is pending.

Within that rule, an accepted blocking `do` may run while generated spawns are
already pending, may run after a prior multi-pending `await_any` observation,
and may be followed by one or more later generated spawns before the final
drain. The documented top-level `when` and `switch` branch paths mirror each
other. Missing same-body drains, cross-domain activation without an explicit
crossing, deeper branch/loop nesting, implicit CDC, dynamic generated-child
specialization, and broader outstanding-child lifetime semantics remain
fail-closed.

ATL generated-child matrix note: the broad backlog wording for
data-route/generated-child coupling excludes the shipped pin exceptions and
the shipped two-child same-source/same-sink scalar or exact-width vector
actor-to-actor route set.

The current generated-child data-route exceptions are exactly one scalar
top-level input pin routed to one resolved child input through the generated
ATL top, using `(worker.payload pins.payload)` in
`isf/atl_resolved_child_pin_ingress_pipeline.isf`; exactly one exact-width
vector top-level input pin routed to one resolved child input through the
generated ATL top, using the same spelling in
`isf/atl_resolved_child_pin_ingress_vector_pipeline.isf`; the bounded same-child
scalar pin-ingress multi-route fixture
`isf/atl_resolved_child_pin_ingress_multi_pipeline.isf`, using
`(worker.payload pins.payload)` plus `(worker.sideband pins.sideband)`;
the bounded same-child vector pin-ingress multi-route fixture
`isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf`, using the
same spelling with 8-bit payload and 4-bit sideband routes;
the bounded same-child mixed scalar/vector pin-ingress fixture
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf`, using
`(worker.payload pins.payload)` at width 8 and `(worker.valid pins.valid)` as
a scalar route;
exactly one scalar resolved child output routed to one top-level output pin
through the generated ATL top, using `(pins.result worker.payload)` in
`isf/atl_resolved_child_pin_egress_pipeline.isf`; exactly one exact-width
vector resolved child output routed to one top-level output pin through the
generated ATL top, using the same spelling in
`isf/atl_resolved_child_pin_egress_vector_pipeline.isf`; the bounded
same-child scalar pin-egress multi-route fixture
`isf/atl_resolved_child_pin_egress_multi_pipeline.isf`, using
`(pins.result worker.payload)` plus `(pins.status worker.status)`; the bounded
same-child vector pin-egress multi-route fixture
`isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf`, using
`(pins.result worker.payload)` at width 8 plus `(pins.status worker.status)`
at width 4; the bounded same-child mixed scalar/vector pin-egress fixture
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf`, using
`(pins.result worker.payload)` at width 8 and `(pins.valid worker.valid)` as
a scalar route; one one-bit
actor-to-actor route between two resolved children through the generated ATL
top, using `(writer.payload reader.payload)` in
`isf/atl_two_child_data_pipeline.isf`;
one exact-width vector actor-to-actor route with the same spelling in
`isf/atl_two_child_vector_data_pipeline.isf`; and the bounded
same-source/same-sink two-route fixture
`isf/atl_two_child_multi_data_pipeline.isf`, using `(writer.payload
reader.payload)` plus `(writer.sideband reader.sideband)`.

Route evidence remains in `actor_network.data_movements[]`. Generated-top
discovery remains in `actor_network.generated_tops[]`, including
`children[]` wiring evidence for generated-child routes.

Generated-child actor-to-actor and pin route support is intentionally
small. Each route uses one direct source, one direct sink, deterministic
generated handoffs, and one named drive-call cycle. Actor-to-actor route width
is either scalar one-bit or the exact matching child endpoint width. Multiple
actor-to-actor routes are accepted only when they share the same source child,
sink child, parent transaction, contiguous route segment, and matching
endpoint widths per route. Pin-ingress route width is scalar one-bit for the
scalar multi-route subset, one exact matching top-input/child-input vector
width for the one-route vector subset, or route-local exact matching
top-input/child-input widths for the same-child vector multi-route subset.
The same-child mixed pin-ingress subset accepts scalar one-bit routes and
exact-width vector routes together while preserving route-local `kind`,
`width`, and `width_source`.
Pin-egress route width is scalar one-bit for the scalar multi-route subset,
one exact matching child-output/top-output vector width for the one-route
vector subset, or route-local exact matching child-output/top-output widths
for the same-child vector multi-route subset. The same-child mixed pin-egress
subset accepts scalar one-bit routes and exact-width vector routes together
while preserving route-local `kind`, `width`, and `width_source`.
Multiple scalar pin-ingress routes are accepted only when they share one
resolved child, one parent transaction, unique top-level input pins, unique
child input endpoints, and adjacent pre-trigger drive calls; multiple
pin-egress routes are accepted only when they share one resolved child, one
parent transaction, unique child output endpoints, unique top-level output
pins, and adjacent post-event drive calls.
Generated-handoff remapping or reuse, fan-in/fan-out data routing, route
mux/storage, CDC/reset remapping, ready/backpressure, payload protocols,
parameterized route drive definitions, route drive-call actual arguments,
recursive actor networks, and permanent actor grouping remain outside the
shipped subset.

Malformed or width-mismatched generated-child actor-to-actor route shapes
still fail closed with targeted diagnostics before FSMGen infers remapping,
storage, muxing, payload adaptation, fan-in/fan-out, or backpressure behavior.

Current ATL group endpoint boundary: `group.name` is reserved but still
unsupported source syntax. When the qualifier names a declared static group,
transaction-body `(trigger group.name)`, `(await group.name)`,
`(await_all group.name)`, `(await_any group.name)`, and rule-action
`(trigger group.name)` fail closed with the ATL group-endpoint diagnostic.
The missing contract is group-level trigger arbitration/fanout, event
aggregation, storage/lifetime, and generated-child wiring semantics. Dotted
names that do not name a static group keep the existing enum-member
diagnostics.

## Examples By Family

### CLI Entrypoints

```bash
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --strict --outdir .artifacts/ial1/isf-build isf/spawn_parent.isf
./bin/fsmgen -l sv isf/apb_requester.isf
```

`--emit-schedule-json` reports the scheduled intent view and exits before HDL
generation. `--outdir` is the public durable-review path for multi-file
lowering, including generated-child and accepted multi-domain actors. Without
it, those handoff files stay in a repository-local transient workspace. Plain
`.isf` HDL generation lowers through scheduled `.fsm` first, then continues
through the existing HDL pipeline.

The I2C-like fixture is a bounded realistic fixture, not a full I2C protocol
compliance claim. It is file-backed in the `isf` regression tier for strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, switch-branch repeats, read-data shifting, sampled write-data bit
selection from `data[7]`, and absence of an implicit `data_bit` input.

The burst-reader fixture is file-backed in the `isf` regression tier for
strict schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, dynamic repeat counter storage, watchdog and latency counter
roles, sampled aliases, and completion/timeout pulse fan-in.

The UART-like fixture is a bounded transmit example, not a full UART protocol
compliance claim. It is file-backed in the `isf` regression tier for strict
schedule JSON parity, scheduled `.fsm` structure, plain and strict HDL
generation, sampled-byte LSB drive selection from `byte_data[0]`, known-width
`shift_right`, repeat counter storage, busy drive sequencing, and completion
pulse behavior.

The phase fixture is file-backed in the `isf` regression tier for transaction
`(phase ...)` pass-through state coverage, parser-validated phase body
metadata, strict schedule JSON parity, scheduled `.fsm` structure, plain and
strict HDL generation, and delayed completion pulse behavior. It does not
claim executable actor-level phase scheduling; actor-level phase/stage
metadata remains report-only.

The switch fixture is file-backed in the `isf` regression tier for sampled
selector capture, explicit switch branch dispatch, default fallthrough to
completion, named-drive branch starts, strict schedule JSON parity, scheduled
`.fsm` structure, plain and strict HDL generation, and delayed completion
pulse behavior. It does not widen the deferred nested child/await-sync branch
body surface.

The when fixture is file-backed in the `isf` regression tier for
transaction-local conditional body coverage: entry drive setup, two conditional
decision states, multi-step true-body drives, false-path fallthrough,
compatible named-drive start fan-in, strict schedule JSON parity, scheduled
`.fsm` structure, plain and strict HDL generation, and delayed completion
pulse behavior. It does not widen the deferred nested child/await-sync body
surface.

The generated-composition fixture is file-backed in the `isf` regression tier
for spawned generated-child composition coverage: generated top emission,
parent/child scheduled `.fsm` artifacts, start/done handoffs, named-drive
request/payload handoffs, public input fanout, `await_all` synchronization,
strict schedule JSON parity, strict `--outdir` file emission, and strict HDL
generation for the generated top, parent, and child artifacts. It is a bounded
generated-composition fixture, not an external protocol compliance claim.

The rule/resource fixture is file-backed in the `isf` regression tier for
resource arbitration coverage: a rule-over-transaction priority resolution, a
`rule_slot` resource with `priority` arbitration, high-priority rule
ownership, lower-priority rule gating, bounded `priority_resolutions[]` and
`resource_arbitration[]` report metadata, strict schedule JSON parity,
scheduled `.fsm` structure, plain and strict HDL generation, and delayed
completion pulse behavior. Focused resource tests also cover bounded
`rule_slot`/`round_robin`, `output_bundle`/`round_robin`,
`transaction_start`/`round_robin`, and `storage_port`/`round_robin` grants,
generated pointer storage metadata, report projection, and fail-closed
unsupported round-robin combinations. This does not widen the deferred backlog
resource kinds or broader arbiter families.

The stage fixture is file-backed in the `isf` regression tier for a
sampled ready/valid stream handoff with a bounded-eventually monitor:
sampled payload forwarding, top-level ready/valid barrier metadata,
top-level bounded-eventually monitor metadata, temporal monitor storage roles,
SystemVerilog sticky-fail assertion projection, strict schedule JSON parity,
scheduled `.fsm` structure, plain and strict HDL generation, and delayed
completion pulse behavior. It does not widen nested stages, nested monitors,
stage-local compute, expression monitor windows, min/max windows, or broader
temporal operators.

The FIFO datapath fixture is file-backed in the `isf` regression tier for the
shipped actor-owned bank access surface: a depth-4 `data` bank scalarized into
`data_0` through `data_3`, pointer-guarded accepted pushes, pointer-guarded
accepted pops, bounded `bank_accesses[]` report metadata, strict schedule JSON
parity, scheduled `.fsm` structure, and plain plus strict HDL generation. It
does not claim general memory-array HDL emission, write-first collision
behavior, bypassing, or arbitrary-depth parameterized FIFOs.

The FIFO controller fixture is file-backed in the `isf` regression tier for
the shipped controller-only matrix: idle, push-only, pop-only, and simultaneous
push+pop occupancy updates; actor-maintained `full`/`empty`; 2-bit `wr_ptr` and
`rd_ptr` wrap; compatible same-value fan-in metadata; strict schedule JSON
parity; scheduled `.fsm` structure; and plain plus strict HDL generation. It
does not claim data-bank storage or `data_out` datapath transfer behavior.

The FIFO library fixture is file-backed in the `isf` regression tier for the
shipped fixed reusable FIFO path. `isf/fifo_library_use.isf` imports
`common.fifo.fifo`, binds instance `u_fifo`, emits the importing actor,
specialized child, and generated top scheduled `.fsm` artifacts, records fixed
parameter overrides and use-site bindings in `library_uses[]`, and reaches
plain plus strict generated-top HDL generation. It is fixed to
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`; it does not claim
use-site parameter-driven FIFO interface shape, bank-depth specialization, generated-top
respecialization, nested imports, standalone exported transactions or drives,
arbitrary-depth generated FIFOs, memory-array backend emission, or automatic
non-zero reset values.

The ATL temporary trigger-batch fixture is file-backed in the `isf`
regression tier for task-scoped actor orchestration. It uses
`isf/atl_trigger_batch_pipeline.isf` to declare three static actors and a
single transaction that pulses `reader_capture_start`, `filter_process_start`,
and `writer_emit_start` from one scheduled trigger-batch state. It proves
strict schedule JSON parity, scheduled `.fsm` structure, and plain plus strict
HDL generation without declaring a permanent `(group ...)` association.

The ATL scalar data-route fixture is file-backed in the `isf` regression tier
for drive-activated actor-to-actor information movement. It uses
`isf/atl_data_route_pipeline.isf` to declare producer and consumer actors, a
named drive body with `(consumer.payload producer.payload)`, and one
transaction drive call. It proves generated parent handoff ports,
`actor_network.data_movements[]` metadata, empty association/group schedule
arrays, strict schedule JSON parity, scheduled `.fsm` structure, and plain
plus strict HDL generation without claiming generated ATL children, generated
ATL tops, route mux/storage, wider payloads, fan-in/fan-out, CDC,
ready/backpressure, or permanent actor grouping.

The ATL scalar pin-ingress fixture is file-backed in the `isf` regression tier
for moving information from the enclosing actor boundary into an actor in the
network. It uses `isf/atl_pin_ingress_pipeline.isf` to declare one static
consumer actor, a top-level input pin `payload`, a named drive body with
`(consumer.payload pins.payload)`, and one transaction drive call. It proves
the existing top-level pin source, generated actor handoff output,
`actor_network.data_movements[]` metadata, empty association/group schedule
arrays, strict schedule JSON parity, scheduled `.fsm` structure, and plain
plus strict HDL generation without claiming generated ATL children, generated
ATL tops, actor-to-pin egress, bidirectional pin movement, route mux/storage,
fan-in/fan-out, CDC, ready/backpressure, or permanent actor grouping.

The ATL scalar pin-egress fixture is file-backed in the `isf` regression tier
for moving information from an actor in the network to the enclosing actor
boundary. It uses `isf/atl_pin_egress_pipeline.isf` to declare one static
producer actor, a top-level output pin `result`, a named drive body with
`(pins.result producer.payload)`, and one transaction drive call. It proves
the generated actor source handoff input, existing top-level output sink,
`actor_network.data_movements[]` metadata, empty association/group schedule
arrays, strict schedule JSON parity, scheduled `.fsm` structure, and plain
plus strict HDL generation without claiming generated ATL children, generated
ATL tops, bidirectional pin movement, route mux/storage, fan-in/fan-out, CDC,
ready/backpressure, or permanent actor grouping.

The ATL trigger-wait fixture is file-backed in the `isf` regression tier for
single-actor parent orchestration. It uses
`isf/atl_trigger_wait_pipeline.isf` to declare one static worker actor, emit
one `(trigger worker.process)` parent output pulse, wait on one
`(await worker.done)` parent event input, and complete. It proves the
generated trigger/event handoff ports, `actor_network.transaction_triggers[]`,
`actor_network.event_waits[]`, empty association/group/data-movement arrays,
strict schedule JSON parity, scheduled `.fsm` structure including the default
await timeout state, and plain plus strict HDL generation without claiming
generated ATL children, generated ATL tops, child HDL wiring,
library-qualified type usage in the fixture, trigger-batch/event coupling,
data movement coupling, fan-in/fan-out, CDC, ready/backpressure, or permanent
actor grouping.

The ATL trigger-batch wait fixture is file-backed in the `isf` regression tier
for task-scoped trigger-batch/event parent orchestration. It uses
`isf/atl_trigger_batch_wait_pipeline.isf` to declare reader/filter/writer
actors, emit one same-cycle trigger batch, wait on `writer.done`, and
complete. It proves generated trigger/event handoff ports,
`actor_network.association_schedules[]`, compatibility
`actor_network.group_schedules[]`, one `actor_network.event_waits[]` entry,
empty data movement, strict schedule JSON parity, scheduled `.fsm` structure
including the default await timeout state, and plain plus strict HDL
generation without claiming generated ATL children, generated ATL tops, child
HDL wiring, library-qualified type usage in the fixture, hidden multi-event
fan-in joins, data movement coupling, CDC, ready/backpressure, or permanent
actor grouping.

The ATL trigger-batch multi-event wait fixture is file-backed in the `isf`
regression tier for bounded sequential multi-event parent orchestration. It
uses `isf/atl_trigger_batch_multi_wait_pipeline.isf` to declare
reader/filter/writer actors, emit one same-cycle trigger batch, then wait on
`reader.done`, `filter.done`, and `writer.done` as three explicit wait states
before completion. It proves generated trigger/event handoff ports, three
`actor_network.event_waits[]` entries, temporary-association metadata,
compatibility group-schedule metadata, empty data movement, strict schedule
JSON parity, scheduled `.fsm` structure including the default await timeout
state, and plain plus strict HDL generation without claiming hidden
actor-event fan-in joins, repeated waits, payload waits, data movement
coupling, CDC, ready/backpressure, or permanent actor grouping. Repeated
waits to the same triggered actor after a trigger batch fail closed with the
event re-arm/lifetime diagnostic. Sync-clause attempts to join qualified
actor events with `await_all` or `await_any` fail closed with the ATL
event-join diagnostic.

The ATL resolved-child generated-top fixture is file-backed in the `isf`
regression tier for the first parent/child wiring subset. It uses
`isf/atl_resolved_child_pipeline.isf` to import a same-source library actor,
declare `(instance worker of pkt_lib.packet_worker)`, trigger
`worker.process`, wait on `worker.done`, and complete:

```lisp
(transaction run
  (on start)
  (trigger worker.process)
  (await worker.done)
  (complete done))
```

Lowering emits `atl_resolved_child_pipeline.fsm`,
`atl_resolved_child_pipeline__worker.fsm`, and
`atl_resolved_child_pipeline_top.fsm`. The generated top exposes only the
public parent pins plus clock/reset, instantiates the parent and `worker`,
wires the parent trigger handoff `worker_process_start` to the child's
authored transaction start input `process_start`, and wires child `done` back
to parent `worker_done`. Schedule JSON records the resolved child under
`actor_network.instances[]` and the generated top under
`actor_network.generated_tops[]`. This does not claim multiple resolved
children, trigger batches, generated-child data routes, route mux/storage,
CDC, ready/backpressure, payload binding, recursive actor networks, or
permanent actor grouping.

The generated-top HDL promotion fixture extension is shipped for the same
source: plain and strict CLI SystemVerilog includes the generated top,
scheduled parent, resolved child, and selected internal trigger/event links
without adding new ATL syntax or report keys.

The generated-child pin-ingress fixture is shipped as
`isf/atl_resolved_child_pin_ingress_pipeline.isf`: one scalar top-level input
pin routes to one resolved child input through the generated top, using a
named drive body with `(worker.payload pins.payload)`. The same focused
coverage proves route metadata, child input port preservation, generated top
wiring, and plain plus strict HDL generation for that bounded shape.

The generated-child pin-ingress multi-route fixture is shipped as
`isf/atl_resolved_child_pin_ingress_multi_pipeline.isf`: two scalar top-level
input pins route to two scalar inputs on the same resolved child through
adjacent drive calls before the child trigger, using `(worker.payload
pins.payload)` and `(worker.sideband pins.sideband)`. The same focused coverage
proves separate route metadata, child input port preservation for both routed
signals, generated top wiring, strict outdir materialization, plain plus strict
HDL generation, and fail-closed malformed route-set diagnostics.

The generated-child mixed scalar/vector pin-ingress fixture is shipped as
`isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf`: one exact-width vector
top-level input pin and one scalar top-level input pin route to matching inputs
on the same resolved child through adjacent drive calls before the child
trigger, using `(worker.payload pins.payload)` and
`(worker.valid pins.valid)`. The same focused coverage proves route-local
metadata, child input port preservation for both routed signals, generated top
wiring, strict outdir materialization, plain plus strict HDL generation, and a
fail-closed route-local vector width mismatch diagnostic.

The generated-child pin-egress fixture is shipped as
`isf/atl_resolved_child_pin_egress_pipeline.isf`: one scalar resolved-child
output routes to one top-level output pin through the generated top, using a
named drive body with `(pins.result worker.payload)` after the child event
wait. The same focused coverage proves route metadata, child output port
preservation, generated top wiring, plain plus strict HDL generation, missing
child output failure, and pre-event drive-order failure for that bounded
shape.

The generated-child pin-egress multi-route fixture is shipped as
`isf/atl_resolved_child_pin_egress_multi_pipeline.isf`: two scalar outputs from
one resolved child route to two top-level output pins through the generated top,
using `(pins.result worker.payload)` and `(pins.status worker.status)` in
adjacent post-event drive calls. The same focused coverage proves route
metadata for both paths, child output port preservation for both routed
signals, generated top wiring, strict outdir materialization, plain plus strict
HDL generation, missing child output failure, interleaved-drive-call failure,
and duplicate top-level output pin failure for that bounded shape.

The generated-child mixed scalar/vector pin-egress fixture is shipped as
`isf/atl_resolved_child_pin_egress_mixed_pipeline.isf`: one exact-width vector
resolved-child output and one scalar resolved-child output route to matching
top-level output pins on the same generated top through adjacent drive calls
after the child event wait, using `(pins.result worker.payload)` and
`(pins.valid worker.valid)`. The same focused coverage proves route-local
metadata, child output port preservation for both routed signals, generated
top wiring, strict outdir materialization, plain plus strict HDL generation,
and a fail-closed route-local vector width mismatch diagnostic.

Generated-child actor-to-actor data movement across two resolved children is
now shipped only for the selected same-source/same-sink,
one-drive-call-per-route, trigger/event-ordered shape below. Widths may be
one-bit scalar or exact-width vector when the source child output and sink
child input declarations match. Mismatched widths still fail closed before
broader multi-child routing or scheduling is inferred.

The first positive two-child generated top is shipped as
`isf/atl_two_child_pipeline.isf`: two resolved children, sequential
`reader.capture`/`reader.done` then `writer.emit`/`writer.done` handoffs,
no ATL data movement, and one generated top that instantiates the parent plus
both children. Schedule JSON records one generated top with `children[]`
entries for reader and writer wiring, while keeping the existing
`actor_network.instances[]`, `transaction_triggers[]`, and `event_waits[]`
evidence.

The first resolved-child trigger-batch generated top is shipped as
`isf/atl_two_child_trigger_batch_pipeline.isf`: two resolved children, one
contiguous same-cycle trigger batch, source-ordered waits to both triggered
children, no static group declaration, no ATL data movement, and one generated
top that instantiates the parent plus both children. Schedule JSON keeps
individual `transaction_triggers[]` and `event_waits[]` records, adds the
task-scoped trigger-batch evidence in `association_schedules[]` plus
`group_schedules[]`, and records the generated top with kind
`resolved_children_trigger_batch_event_sequence`.

The first one-bit generated-child actor-to-actor route through that top is
shipped as `isf/atl_two_child_data_pipeline.isf`: `(writer.payload
reader.payload)` is called after `reader.done` and before `writer.emit`.

The exact-width vector route through that same top is shipped as
`isf/atl_two_child_vector_data_pipeline.isf`: the same
`(writer.payload reader.payload)` route lowers through 8-bit parent handoff
ports, child payload ports, generated-top links, and generated HDL links when
both child endpoints declare width 8.

The bounded multi-route extension of the same shape is shipped as
`isf/atl_two_child_multi_data_pipeline.isf`: `(writer.payload reader.payload)`
and `(writer.sideband reader.sideband)` are called in adjacent drive states
after `reader.done` and before `writer.emit`.

Schedule JSON reports each route through
`actor_network.data_movements[]`. One-bit routes use
`kind: "scalar_actor_handoff"`; exact-width vector routes use
`kind: "vector_actor_handoff"` and
`width_source: "resolved_child_endpoint_exact_width"`. Generated top discovery
uses
`actor_network.generated_tops[]` with `children[]`. Event fan-in/fan-out,
fan-in/fan-out data routing, route mux/storage, CDC/reset remapping,
ready/backpressure, payload protocols beyond exact-width handoff wiring,
repeated triggers, trigger-batch plus data movement coupling, groups, and
permanent actor grouping remain deferred.

The shipped hardening leaf keeps that surface unchanged and adds focused
fail-closed coverage for source child output validation, sink child input
validation, and the one-drive/one-pair/one-call cardinality boundary.

The shipped width hardening accepts matching generated-child actor-to-actor
endpoint widths and targets mismatched source/sink child payload ports as
fail-closed coverage, without payload conversion semantics.

The shipped clock/reset hardening keeps that route same-domain only: source
or sink child clock/reset mismatches fail closed before any CDC bridge, reset
remap, generated-top system-port remap, storage, mux, or backpressure
contract.

The shipped self-route hardening keeps that route between two distinct
resolved children: same-child source/sink route pairs fail closed before any
self-route, loopback, child-internal bypass, storage, mux, fan-in/fan-out, or
payload contract.

The shipped repeated-trigger hardening keeps the route to one source-child
trigger and one sink-child trigger: extra route-child triggers fail closed
before any repeated activation, restart, pending-request merging, trigger
fan-in/fan-out, or multi-activation scheduling contract.

The shipped repeated-wait hardening keeps the same route to one source-child
event wait and one sink-child event wait: extra route-child waits fail closed
before any event fan-in/fan-out, repeated wait sequencing, route-level wait
storage, muxing, backpressure, or payload contract.

The shipped same-parent-transaction hardening keeps that route inside one
parent transaction: split route clauses remain fail-closed before any route
continuation, pending handoff storage, transaction rendezvous,
cross-transaction scheduling, muxing, backpressure, or payload contract.

The shipped sink-trigger ordering hardening keeps the data drive call before
the sink child trigger: sink-before-drive route clauses remain fail-closed
before any speculative sink activation, delayed payload delivery, route
storage, muxing, backpressure, or payload contract.

The shipped sink-event-wait ordering hardening keeps the sink child event
wait after the sink child trigger: sink-wait-before-trigger route clauses
remain fail-closed before any pre-trigger acknowledgement, sticky event
sampling, event replay, route storage, muxing, backpressure, or payload
contract.

The shipped source-event-wait ordering hardening keeps the source child
event wait after the source child trigger: source-wait-before-trigger route
clauses remain fail-closed before any pre-trigger acknowledgement, sticky
event sampling, event replay, route storage, muxing, backpressure, or payload
contract.

The shipped route-contiguity hardening keeps that same route as one
contiguous transaction-body segment: interleaved parent clauses remain
fail-closed before any interleaved parent work, local side effects,
pre/post route sampling, route continuation, storage, muxing, backpressure,
or payload contract.

The shipped route-isolation hardening keeps that contiguous route segment
as the only executable parent transaction-body work between the transaction
start condition and completion: pre-route and post-route parent clauses
remain fail-closed before any local side effects, setup/cleanup work,
continuation, storage, muxing, backpressure, or payload contract.

The shipped route-boundary cardinality hardening keeps that isolated route
bounded by one simple start boundary and one simple completion boundary:
extra start or completion boundaries remain fail-closed before any
activation fan-in, completion fan-out, start-condition arbitration,
setup/cleanup work, continuation, storage, muxing, backpressure, or payload
contract.

The shipped boundary-simplicity hardening keeps those boundaries body-free:
activation-body samples in `(on ...)` and extra payload operands in
`(complete ...)` remain fail-closed before any activation-body sampling,
completion payload/fan-out, setup/cleanup work, continuation, storage,
muxing, backpressure, or payload contract.

The shipped boundary-role hardening keeps those boundaries tied to parent
interface roles: the route start boundary remains a scalar top-level input,
and the route completion boundary remains a scalar top-level output.
Output-as-start, input-as-completion, undeclared, and wider boundary pins
fail closed before any interface remapping, activation fan-in, completion
fan-out, boundary expression, storage, muxing, backpressure, or payload
contract.

The shipped generated-handoff collision hardening keeps deterministic route
handoff names owned by FSMGen. Parent declarations that collide with selected
trigger, event, data, or named-drive request handoffs fail closed in parser
coverage for normal `.isf` source and lowerer coverage for malformed
scheduler-facing metadata.

The shipped route drive argument hardening keeps each selected ATL
data-movement route drive unparameterized across actor-to-actor,
pin-ingress, and pin-egress route families. The route drive call remains
argument-free: `(drive (forward_payload value) ...)` and
`(drive forward_payload value)` remain outside this subset before drive
actual binding, expression movement, payload protocols, storage, muxing,
fan-in/fan-out, or backpressure behavior is inferred.

The shipped route endpoint-expression hardening keeps the generated-child
actor-to-actor route source and sink as scalar endpoints. A route drive body
such as `(writer.payload (+ reader.payload 1))` remains outside this subset
before source expression movement, value transformation, payload protocols,
storage, muxing, fan-in/fan-out, or backpressure behavior is inferred. A
route drive body such as `((+ writer.payload 1) reader.payload)` also remains
outside this subset before sink expression movement, route-side transforms,
payload protocols, storage, muxing, fan-in/fan-out, or backpressure behavior
is inferred. The sink-expression diagnostic is source-order independent for
endpoint-looking malformed route sinks, while non-ATL malformed local drive
targets such as `((out) 1)` keep the generic drive-body scalar-head
diagnostic. The source-expression diagnostic is source-order independent too
and uses the same targeted ATL source-expression diagnostic. The accepted
scalar route is source-order independent too:
placing the named `forward_payload` route drive before the `reader` and
`writer` instances still emits the same generated ATL top handoffs and
`actor_network.data_movements[]` metadata.

### Actor, Interface, Storage, And Timing

```lisp
(actor apb_requester
  (clock clk)
  (reset (rst_n async active_low))
  (watchdog 65535)
  (interface
    (input start)
    (input req_addr (width 32))
    (output done)
    (output PADDR (width 32)))
  (storage
    (var captured_addr (width 32))))
```

This is the ordinary single-clock shape. For multi-clock actors, use
`(clock-domains ...)` instead of mixing it with `(clock ...)`:

```lisp
(clock-domains
  (domain bus  (clock bus_clk) (reset bus_rst_n))
  (domain core (clock clk)     (reset rst_n) :default))
```

### Acknowledged Event CDC

```lisp
(crossings
  (event rx_done
    (from bus  rx_done_req)
    (to   core rx_done_pulse)
    (ready rx_done_ready)))
```

The source domain may request only while `rx_done_ready` is true. The
destination domain receives a pulse later, after the generated CDC child moves
the event safely across the domain boundary.

`isf/clock_domain_no_reset_event_crossing.isf` covers the acknowledged-event
schedule/report surface when both domains omit resets. The generated CDC
metadata records `SOURCE_RESET_PRESENT 0d0` and `DEST_RESET_PRESENT 0d0`, and
the HDL path emits clock-only domain modules plus a generated CDC child without
absent reset ports.

### Transaction Body

```lisp
(transaction apb_transfer
  (on start
    (sample req_addr as addr))
  (set PADDR addr)
  (drive setup)
  (await PREADY)
  (complete done)
  (latency (min 2) (max 16)))
```

The scheduled `.fsm` review artifact owns the exact cycle placement: samples
materialize at the accepted entry boundary, drive calls consume states, awaits
test the selected port, and completion pulses the authored done output.

### Transaction Ports And Bindings

```lisp
(transaction read_word
  (ports
    (input addr (width 32))
    (output data (width 32)))
  ...)

(do read_word
  (bind
    (input addr req_addr)
    (output data read_data)))

(rule launch_read ready
  (trigger read_word
    (bind
      (input addr (+ base_addr offset)))))
```

Input bindings accept scalar signals, numeric literals, exact-width literals,
and non-empty list expressions. `do` and `spawn` support input and output
bindings; rule `trigger` supports input bindings only. Successful schedule
reports expose bounded `transaction_port_bindings[]` entries rather than raw
binding internals, with `actor_endpoint_kind` classifying the authored actor
side as `signal`, `literal`, or `expression` and `binding_timing` classifying
the transfer timing as `activation_region`, `generated_live_handoff`,
`trigger_payload`, or `done_guarded`. `authored_timing_mode` reports
`snapshot`, `live`, or JSON null for no explicit timing clause.

### Stage And Bounded-Eventually Monitor

```lisp
(transaction stream_word
  (on start)
  (stage wait_ready
    (ready ready)
    (valid valid))
  (assert (monitor (within done 8)) "finish_seen")
  (complete done))
```

The shipped stage surface is a top-level ready/valid barrier. The shipped
bounded-eventually surface is the `(assert (monitor (within SIGNAL N)) ["NAME"])`
monitor, which replaced the former top-level `(contract …)` clause. The older
`(input ready)`/`(output valid)` stage spelling remains accepted as an alias,
and the valid endpoint still participates in same-target conflict checks.
Monitor windows may use positive literals, declared positive actor constants,
actor-local scalar parameter defaults, qualified imported package scalar
constants, or same-transaction scalar parameter defaults on generated child or
direct/non-generated transactions when those sources resolve to positive
integers. Direct transaction parameters are local lowering inputs for this
monitor-window value domain and are not emitted as actor-level `.fsm`
`+params`.

Broader stage-local compute, nested stages, registered-valid/skid-buffer
variants, runtime-signal or expression monitor windows, min/max windows, and
global implication forms remain backlog.

### Waits And Repeat Bodies

```lisp
(params
  (WAIT_PARAM 2))

(transaction pulse_train
  (on start)
  (repeat count
    (drive pulse 1)
    (wait WAIT_PARAM)
    (drive pulse 0)
    (update count_seen (+ count_seen 1)))
  (complete done))
```

The repeat body may use the shipped inline body clauses documented in
[Transactions](13b-transactions.md) and [Control Flow](13d-control-flow.md).

`WAIT_PARAM` is an actor parameter wait count: scalar actor parameter defaults
that resolve to non-negative integer literals lower through the same static
wait contract as literals and actor constants. Same-transaction scalar
parameter defaults use that same static wait contract in their owning
transaction and shadow actor-level static names. Qualified package scalar
constants such as `shared.WAIT_PARAM` are accepted by that same static wait
contract when they resolve to non-negative integer literals.

A plain local `(do child)` and a same-domain generated `(do child (params ...))`
(with `(bind ...)`/`(domain NAME)` when static params are present) inside a
`(repeat ...)` that sits directly in a single `(while ...)` or `(until ...)`
body, plus the same plain-local and same-domain-generated `do` at deeper branch
nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`), are part of the shipped
repeat-body subset. The first loop-plus-branch repeat-body activation is also
shipped for plain local `while -> when -> repeat -> do`; generated `do`,
spawn, `until -> when`, nested `switch`, and extra loop nesting in that family
remain deferred. The basic loop-contained/deeper-nested `spawn` + same-body
drain subset and multi-pending `await_any` with a later same-body `await_all`
drain are also shipped at lowering + composition-planning level. Deeper-nested
cross-domain repeat-body `do`, cross-domain `spawn`, undrained spawn forms,
repeats reached through an additional loop ancestor, and nested `stage` or
`contract` clauses remain outside the shipped repeat-body subset. Cross-domain
generated `do`, loop-contained/deeper-nested undrained `spawn`, and
extra-loop-ancestor repeat-body `do` each emit targeted diagnostics so authors
can identify which deferred lane is
blocking their specific case; the original generic "supported only for
top-level..." message remains as a safety-net fallback.

<details>
<summary>Repeat-body construction-rule audit markers</summary>

These short markers let the feature-matrix audit detect the shipped
repeat-body activation families without restoring the old exhaustive list of
individual spelling combinations:

```text
top-level repeat-body local blocking do
samples before or after spawn before same-body sync
samples before or after repeat-body do before the repeat check
multi-pending repeat-body await_any with mandatory same-body await_all drain
documented top-level when/switch nested-repeat activation construction rule
local do, generated-child do, static params, bind handoffs, same-domain metadata
await_any observation-only plus same-body await_all exact drain
```

</details>

### Types, Enums, And Aggregate Leaves

```lisp
(types
  (type mode_bits (bits 2))
  (type frame_t (record (mode (bits 2)) (valid bit))))
(enums
  (mode (IDLE 0) (BUSY 1)))
(storage
  (var frame (type frame_t)))

(transaction publish
  (on start)
  (set frame.mode mode.BUSY)
  (when frame.valid
    (set out_mode frame.mode)))
```

The shipped aggregate path is scalar-leaf based. `frame.mode` and
`frame.valid` are accepted because `frame` is declared actor-owned aggregate
storage and the paths resolve to scalar leaves.

Runtime expression divisor safety is fail-closed for literal zero, fixed actor
constants that resolve to zero, actor scalar parameters whose defaults resolve
to zero, and same-transaction scalar parameters whose defaults resolve to
zero:

```lisp
(constants (ZERO 0) (DEN 2))
(params (ZERO_P 0) (DEN_P 2))
;; inside a transaction: (params (TX_ZERO 0) (TX_DEN 2))
(set out (/ numerator divisor))  ;; accepted: dynamic divisor, no proof yet
(set out (/ numerator 8'd2))     ;; accepted: nonzero literal divisor
(set out (/ numerator DEN))      ;; accepted: nonzero actor constant divisor
(set out (/ numerator DEN_P))    ;; accepted: nonzero actor parameter divisor
(set out (/ numerator TX_DEN))   ;; accepted when TX_DEN is a nonzero same-transaction parameter
(set out (/ numerator 0))        ;; rejected before scheduled .fsm emission
(set out (/ numerator ZERO))     ;; rejected before scheduled .fsm emission
(set out (/ numerator ZERO_P))   ;; rejected before scheduled .fsm emission
(set out (/ numerator TX_ZERO))  ;; rejected when TX_ZERO resolves to zero
```

### Bank Store And Load

```lisp
(storage
  (bank data (width 8) (depth 4))
  (var wr_ptr (width 2))
  (var rd_ptr (width 2)))

(transaction fifo_step
  (on push)
  (store data wr_ptr data_in)
  (load data rd_ptr as data_out)
  (complete done))
```

The bank is scalarized in scheduled `.fsm` review text. Pointer-selected
access remains explicit through `store` and `load`; memory-array backend
emission is not a current support claim.

### Rules, Priority, And Resources

```lisp
(rule high write_req
  (set valid 1))

(rule low read_req
  (priority over high)
  (set valid 0))

(resources
  (resource rule_exec
    (kind rule_slot)
    (arbiter priority)
    (users high low)))
```

The shipped `rule_slot`/`priority`, `output_bundle`/`priority`,
`transaction_start`/`priority`, `storage_port`/`priority`, bounded
`rule_slot`/`round_robin`, bounded `output_bundle`/`round_robin`, bounded
`transaction_start`/`round_robin`, and bounded
`storage_port`/`round_robin` subsets can gate a whole bound rule DT for
one active cycle. Remaining resource kinds are documented names, not supported
runtime arbitration behavior yet.

### Generated Children

```lisp
(transaction worker
  (params
    (WIDTH 8))
  ...)

(transaction parent
  (on start)
  (spawn worker as w0
    (params
      (WIDTH 16)))
  (await_all done)
  (complete done))
```

The lowerer emits a scheduled parent `.fsm`, scheduled child `.fsm`, and a
generated top `.fsm`. The generated top applies static parameter overrides and
wires start/done handoffs.

### Reusable Library Use

```lisp
(imports
  (library common.fifo as fifo_lib))

(use fifo_lib.fifo as u_fifo
  (params
    (DATA_WIDTH 8)
    (DEPTH 4)
    (PTR_WIDTH 2)
    (OCC_WIDTH 3))
  (bind
    (clock clk)
    (reset rst_n)
    (input write_req write_req)
    (input data_in data_in)
    (output full full)
    (output data_out data_out)))
```

The cataloged `common.fifo.fifo` actor is a shipped reusable ISF library
definition. Library imports are semantic roots that still lower to scheduled
`.fsm`; they are not textual includes.

### Schedule JSON And Manifest Discovery

```bash
./bin/fsmgen --emit-schedule-json isf/apb_requester.isf
./bin/fsmgen --capability-manifest
./bin/fsmgen --emit-capability-manifest
```

The schedule report is the machine-readable companion to the scheduled `.fsm`
review artifact. The capability manifest advertises the live ISF public
contract, including this book chapter through `live_document_paths`.

```json
{
  "schema_version": 1,
  "actor_params": [
    { "name": "WIDTH", "value": 8 }
  ],
  "actor_phases": [
    { "name": "capture", "body": [["note", "metadata"]] }
  ],
  "actor_stages": [],
  "verification_observations": [
    {
      "name": "link_rx",
      "role": "passive_monitor",
      "clock": "clk",
      "reset": { "name": "rst_n", "kind": "async", "polarity": "active_low" },
      "signals": [
        { "name": "valid", "direction": "input", "width": 1 },
        { "name": "ready", "direction": "output", "width": 1 },
        { "name": "data", "direction": "input", "width": 8 }
      ]
    }
  ],
  "inferred_storage": [
    {
      "name": "wait_count",
      "kind": "counter",
      "role": "dynamic_wait_counter",
      "width": 4
    },
    {
      "name": "done_fail",
      "kind": "register",
      "role": "temporal_contract_monitor"
    },
    {
      "name": "worker_process_start",
      "kind": "register",
      "role": "atl_trigger_start_handoff"
    },
    {
      "name": "last_error",
      "kind": "register",
      "role": "scheduler_error_status",
      "width": 1
    }
  ]
}
```

The manifest flag `schedule_report_full_schema_stable` is true for
`schema_version: 1`. Consumers should still prefer advertised keys, value
families, and explicit role fields over parsing generated signal names as
semantic API.

### Downstream Issue Bundles

```bash
./bin/fsmgen-issue-bundle \
  --case path/to/fsmgen-facing-artifact \
  --issue-id sf-0001 \
  --speforge-version "SPECFORGE_COMMIT" \
  --failure-class unknown \
  --expected "FSMGen should accept this generated artifact" \
  --observed "FSMGen rejects it" \
  -- --strict --check --json
```

Downstream tools do not need to decide whether the root cause is `.fsm`,
`.isf`, parser, lowering, HDL, or API-specific before filing. The bundle
captures the FSMGen-facing artifact, exact command, environment, observed
stdout/stderr/status, JSON probes, generated artifacts, and a rerunnable
`commands.sh` so the issue can be reproduced from the FSMGen repository root.

## Explicit Non-Claims

These are important because they prevent the matrix from implying support that
does not exist:

- Multi-bit CDC payloads, FIFO CDC, reset-as-event semantics, and direct
  cross-domain data access are not shipped.
- A cross-domain `(do CHILD)` directly inside any TOP-LEVEL body — a `(repeat ...)`
  body or a `when`/`switch`/`while`/`until` branch body — and directly inside a
  `(repeat ...)` nested in a top-level `when` body or top-level `switch` branch,
  plus directly inside supported nested `when` chains reached from those top-level
  branch bodies and repeats under those chains, IS shipped (the dual-CDC handshake
  runs when the branch is taken and re-runs each iteration inside a repeat/loop; see
  the cross-domain activation crossing row).
  Generated or spawned nested activation beyond the documented top-level
  branch-contained generated do
  cases and top-level branch-contained spawned cases, broader outstanding-child
  semantics, deeper branch repeat activation beyond the shipped top-level
  `when`/`switch` branch-contained repeat crossing, nested
  nested switch, repeat-contained branch, nested `while`, nested `until`, `stage`,
  `contract`, and DEEPER-nested cross-domain
  activation (a cross-domain `(do)` whose container is itself nested inside another
  body rather than a direct transaction-body clause) remain outside the
  shipped repeat-body subset.
- Dynamic division/modulo nonzero proof is not shipped. Literal-zero,
  actor-constant-zero, actor-parameter-zero, and
  same-transaction-parameter-zero divisors are rejected, but arbitrary runtime
  scalar divisors and nonzero use-site-specialized parameter divisors are
  emitted unchanged.
- Enum members are not writable targets, and enum members in expression
  operator position fail closed.
- Record output member writes, root-list interface ports, transaction-local aggregate
  ports, aggregate banks, subaggregate updates, and whole-record/list truthiness
  remain backlog. Whole record outputs/copies have bounded source/carrier admission
  above; packed record actor inputs have the qualified bounded admission above;
  this does not complete broader generated/domain/native or consumer delivery.
- Backlog resource kinds are registry names, not runtime arbitration support.
- Actor-level phase and stage metadata is report-only; it does not schedule
  actor-level runtime phases, barriers, generated `.fsm` states, or HDL
  behavior.
- Actor-level passive observation metadata is report-only; it does not emit
  generated `.fsm`, HDL, UVM, VHDL, scoreboard, coverage, or VIP artifacts.
  The shipped form is `(observe NAME (role passive_monitor) (signals SIG...))`
  over unique public actor interface signals in a single-clock actor.
- ATL generated-child actor-to-actor routes do not support generated-handoff
  remapping or reuse. Parent-declared collisions with selected trigger,
  event, data, or named-drive request handoff names fail closed with focused
  parser-owned coverage for normal `.isf` source and lowerer-owned coverage
  for malformed or mutated scheduler-facing actor metadata. This is not a new
  source feature. Route mux/storage, fan-in/fan-out, CDC/reset remapping,
  ready/backpressure, payload protocols, route drive parameters, route
  drive-call actual arguments, recursive actor networks, and permanent actor
  grouping also remain outside the shipped generated-child actor-to-actor
  route subset.
- Direct `(on ...)` activation-site `(params ...)` is unsupported and fails
  with an entry-guard/generated-activation diagnostic; static specialization
  belongs to spawn, generated blocking `do`, and rule-trigger generated
  activation sites.
- Rule-trigger output bindings for direct/local targets, explicit
  behavior-changing snapshot-vs-live binding timing selection/conversion,
  additional future binding-report expansions beyond the shipped bounded
  `transaction_port_bindings[]` summary fields, and broader static binding
  conflict diagnostics are not shipped. The shipped summary fields include
  `actor_signal`, `actor_expression`, endpoint kind, binding timing, and
  authored timing mode. The direct/local rule-trigger output-binding
  diagnostic names the missing generated-child completion identity. Duplicate
  output actor targets inside one bind block, and duplicate generated
  rule-trigger output actor targets inside one rule, fail closed before
  broader assignment conflict handling.
- Nested stages, stage-local compute/action bodies, multiple ready/valid
  endpoints, registered-valid variants, and skid buffers are not shipped.
- Temporal contracts beyond the top-level bounded eventual subset, including
  runtime-signal or expression windows, global implication forms, dynamic
  bounds, expression operands, and multiple outstanding obligations, are not
  shipped.
- Raw parser actor hashes, private `LoweringIR` internals, raw assignment
  provenance lists, and recursive child report dumps are not public schedule
  JSON API.
- VHDL is recognized as a target family, but the full VHDL backend is not
  shipped.

When a future slice widens any row above, update the detailed chapter, this
matrix, the live spec, the downstream handoff, the public contract or manifest
metadata when applicable, focused tests, and the feature backlog in the same
task-scoped commit.
