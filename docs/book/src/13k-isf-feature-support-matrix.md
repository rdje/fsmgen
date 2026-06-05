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

## Status Vocabulary

| Status | Meaning |
| --- | --- |
| `shipped` | The listed source shape has documented lowering, runtime behavior, and regression coverage. |
| `shipped bounded surface` | The named subset is shipped; nearby wider forms fail closed or remain backlog. |
| `fail-closed boundary` | FSMGen recognizes the family enough to reject unsupported forms deliberately. It is not a runtime support claim. |

Anything outside the shipped rows below should be treated as backlog unless a
detailed chapter, [ISF Downstream Integration](13i-downstream-integration.md),
[ISF Types, Enums, And Aggregates](13j-type-enum-aggregate.md), or
[Feature Backlog](14-feature-backlog.md) says otherwise.

## Matrix

| Feature family | Status | Accepted authoring surface | Generated and reported behavior |
| --- | --- | --- | --- |
| `.isf` CLI input | shipped | `./bin/fsmgen file.isf`, `--strict file.isf`, `--emit-schedule-json`, and `--outdir DIR` for multi-file lower results. | Single-file actors lower to scheduled `.fsm` before HDL. Multi-file generated-child and accepted multi-domain actors write every scheduled `.fsm` artifact, then use the generated top for HDL generation. |
| Public parser and scheduler facades | shipped bounded surface | `FSM::Adapter::ISF->new(debug => ...)`, `parse_file`, `parse_source`, `FSM::Scheduler::ISF->new(...)`, `lower`, and `report`. | Public methods validate receivers and argument shapes before private parsing/lowering. The capability manifest advertises the live public contract under `embedding.isf_public_interface`. |
| Actor envelope | shipped | `(actor NAME ...)` with singleton `(clock ...)`, `(clock-domains ...)`, `(reset ...)`, `(watchdog ...)`, `(interface ...)`, `(storage ...)`, `(types ...)`, `(enums ...)`, `(imports ...)`, `(constants ...)`, `(params ...)`, `(resources ...)`, and reusable-library `(use ...)` where documented. | The scheduled `.fsm` preserves reviewable system, size, constants, params, type, enum, import, storage, rule, drive, and transaction artifacts. Duplicate singleton clauses fail closed. |
| Actor report metadata and params | shipped bounded surface | Actor-level `(params ...)`, `(phase NAME ...)`, and `(stage NAME ...)` metadata where documented. Actor parameter defaults may use literals, declared actor constants, earlier scalar actor parameter defaults, enum members, qualified imported package scalar constants, and compatible aggregate/list defaults with those scalar leaves. | Parameter defaults preserve source-order report entries in `actor_params[]`; actor-constant-backed, earlier-actor-parameter-backed, and qualified package-constant-backed defaults also carry resolved literals internally for width/count consumers. Forward, self, cyclic, non-scalar actor-parameter references, unqualified package constants, aggregate package constants, package member/item paths, and ambiguous local-enum/package-constant spellings fail closed. Actor-level phase/stage clauses are parser-validated and report-only through `actor_phases[]` and `actor_stages[]`; they do not add generated `.fsm` or HDL runtime scheduling behavior. |
| Static actor-network metadata | shipped bounded surface | Static actor instances through direct actor-body `(instance NAME of ACTOR_TYPE)` clauses or compact `(NAME : ACTOR_TYPE)` aliases, library-qualified type resolution through `(instance NAME of ALIAS.EXPORT)` and compact `(NAME : ALIAS.EXPORT)`, plus report-only static groups through `(group NAME (members ACTOR...) (mode concurrent))` and compact `(concurrent NAME ACTOR...)` aliases. `(network ...)` is not part of the shipped surface. | The parser shell and schedule report preserve `actor_network.kind`, instance `name`, `actor_type`, declaration spelling (`actor` for verbose instances and `instance_alias` for compact instances), resolved instance `type_resolution`/`library`/`alias`/`export`/`module`/`scheduled_fsm` metadata where applicable, `groups[]`, `generated_tops[]`, `association_schedules[]`, `group_schedules[]`, `event_waits[]`, `transaction_triggers[]`, and `data_movements[]`. Static group declarations alone remain metadata and do not schedule groups. Library-qualified actor type resolution emits resolved child `.fsm` files named by `scheduled_fsm` while keeping the parent `.fsm` unchanged. The first generated ATL top is shipped for one resolved child plus one parent trigger handoff and one parent event wait with matching clock/reset policy; the bounded scalar top-level input-pin to resolved-child input route, one exact-width vector top-level input-pin to resolved-child input route, the scalar same-child pin-ingress multi-route extension, the vector same-child pin-ingress multi-route extension, the mixed scalar/vector same-child pin-ingress route-set extension, the scalar resolved-child output to top-level output route, one exact-width vector resolved-child output to top-level output route, the scalar same-child pin-egress multi-route extension, the vector same-child pin-egress multi-route extension, and the mixed scalar/vector same-child pin-egress route-set extension are shipped for that same one-child top; temporary trigger-batch parent handoff now supports sequential multi-event waits to distinct triggered actors; the first control-only two-child generated top is shipped for sequential trigger/event handoffs with no data movement; and same-source/same-sink scalar or exact-width vector generated-child actor-to-actor routes are shipped through that two-child top. Broader multiple-instance scheduling, broader actor events/triggers, fan-in/fan-out data routing, width adaptation, broader generated-child data-route coupling, and broader endpoint-aware movement remain backlog. |
| ATL v0 future contract | selected backlog contract with bounded shipped event, trigger, rule-action trigger, movement-reservation, scalar/vector actor handoffs, group metadata, and first temporary trigger-batch leaf | Future leaves reserve qualified endpoints `pins.name`/`actor.port`/`actor.transaction`/`actor.event`/`group.name`, existing drive-body `(sink source)` movement, `(do actor.transaction)`, `(spawn actor.transaction as NAME)`, `(trigger actor.transaction)`, `(await actor.event)`, compact group aliases are shipped as report-only metadata syntax. `connect`, `transfer`, and `move` are not ATL v0 movement syntax. | A top-level transaction-body `(await actor.event)` lowers to a one-bit parent handoff input named `actor_event` and reports through `actor_network.event_waits[]`; single waits are accepted in the selected single-actor/generated-top contexts, and one temporary trigger batch may be followed by a contiguous source-ordered chain of waits to distinct triggered actor instances. A top-level transaction-body `(trigger actor.transaction)` and one top-level rule action `(trigger actor.transaction)` lower to a one-cycle parent output handoff named `actor_transaction_start` and report through `actor_network.transaction_triggers[]`; rule-action entries use `context: "rule_action"` and do not create local rule-trigger fan-in. One or more named drive bodies with one `(sink_actor.endpoint source_actor.endpoint)` pair each plus one top-level drive call each may target two direct static actor instances only when every route shares the same source child, sink child, parent transaction, contiguous route segment, and matching source/sink endpoint widths; each route lowers to one-cycle external parent source/sink handoff ports and reports through `actor_network.data_movements[]` as `scalar_actor_handoff` for one-bit routes or `vector_actor_handoff` for exact-width vector routes. One or more named drive bodies with one `(actor.endpoint pins.input_pin)` scalar pair each plus one top-level drive call each may target one direct static actor instance only when every route shares the same resolved child, parent transaction, unique top-level input pin, unique child input, and contiguous pre-trigger drive-call segment; each scalar route reads the one-bit top-level input pin, drives a generated actor handoff output for that call cycle, and reports kind `scalar_pin_to_actor_handoff`. The generated-child one-route vector pin-ingress subset uses the same `(actor.endpoint pins.input_pin)` spelling when the top-level input pin and child input endpoint widths match exactly; it reports kind `vector_pin_to_actor_handoff` and `width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`. The generated-child vector pin-ingress multi-route subset keeps the same same-child, same-parent-transaction, unique-pin, unique-child-input, contiguous pre-trigger drive-call rules while allowing each route to carry its own exact matching top-input/child-input width; each route reports kind `vector_pin_to_actor_handoff` with the same width source. The generated-child mixed scalar/vector pin-ingress subset keeps those same same-child, same-parent-transaction, unique-pin, unique-child-input, contiguous pre-trigger drive-call rules while allowing scalar one-bit and exact-width vector routes in one route set; each route preserves route-local `kind`, `width`, and `width_source`. One or more named drive bodies with one `(pins.output_pin actor.endpoint)` scalar pair each plus one top-level drive call each may target one direct static actor instance only when every route shares the same resolved child, parent transaction, unique child output, unique top-level output pin, and contiguous post-event drive-call segment; each scalar route reads a generated actor handoff input, drives the one-bit top-level output pin for the call cycle, and reports kind `scalar_actor_to_pin_handoff`. The generated-child one-route vector pin-egress subset uses the same `(pins.output_pin actor.endpoint)` spelling when the child output endpoint and top-level output pin widths match exactly; it reports kind `vector_actor_to_pin_handoff` and `width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`. The generated-child vector pin-egress multi-route subset keeps the same same-child, same-parent-transaction, unique-child-output, unique-top-output, contiguous post-event drive-call rules while allowing each route to carry its own exact matching child-output/top-output width; each route reports kind `vector_actor_to_pin_handoff` with the same width source. The generated-child mixed scalar/vector pin-egress subset keeps those same same-child, same-parent-transaction, unique-child-output, unique-top-output, contiguous post-event drive-call rules while allowing scalar one-bit and exact-width vector routes in one route set; each route preserves route-local `kind`, `width`, and `width_source`. Static `(group ...)` declarations and compact `(concurrent ...)` aliases report `actor_network.groups[]` with `scheduling: "metadata_only"`; verbose groups use `declaration: "group"`, compact aliases use `declaration: "concurrent_alias"`, and neither form is required for temporary associations. The first shipped multi-actor trigger leaf is a same-cycle external trigger batch over contiguous transaction-body `(trigger actor.transaction)` clauses to distinct static actor instances; it reports canonical task-scoped evidence through `actor_network.association_schedules[]` with `kind: "temporary_trigger_batch"` and `lifetime: "task_scoped"`, while preserving `actor_network.group_schedules[]` as a schema-version-1 compatibility view. The shipped multi-event wait widening keeps waits after that trigger batch as explicit sequential wait states, not hidden same-cycle event joins. The first resolved-child generated-top leaf emits one child `.fsm` and one `<parent>_top.fsm` for exactly one resolved child, one parent trigger handoff, and one parent event wait. The first two-child generated-top leaf emits parent, two resolved children, and one generated top for sequential trigger/event handoffs with no data movement, reporting child wiring through `actor_network.generated_tops[].children[]`. The first scalar generated-child actor-to-actor route `(writer.payload reader.payload)`, the exact-width vector fixture with the same spelling, and the bounded two-route fixture `(writer.payload reader.payload)` plus `(writer.sideband reader.sideband)` are shipped when called after `reader.done` and before `writer.emit`; route provenance uses existing `actor_network.data_movements[]` and top discovery uses existing `actor_network.generated_tops[]`. Nested waits or triggers, repeated triggers to one instance, repeated rule-action qualified triggers, hidden fan-in/fan-out event joins, payload protocols, cross-clock events/triggers, inline/expression movement, broader generated-child data-route coupling, group endpoints, route mux/storage, and broader group scheduling remain fail-closed. No route mux, broader concurrent-group schedule, or broader HDL event/data wiring is promised until a later implementation leaf advertises it. |
| Single-clock timing | shipped | `(clock clk)` plus optional `(reset ...)` and `(watchdog N)`, where `N` is a positive decimal literal, declared actor constant, actor-local scalar parameter default, or qualified imported package scalar constant that resolves to a positive integer. Omitted legacy single-clock timing defaults to `(clock clk)`, `(reset (rst_n async active_low))`, and `(watchdog 65535)`. | The actor has one clock domain. Resets lower to the matching `.fsm` system reset form. Watchdogs create inferred counters for accepted awaits, with omitted watchdogs normalized to `65535` exactly `(2^16 - 1)` and actor-constant, actor-scalar-parameter, or qualified package-scalar-constant watchdogs reported as resolved integers. |
| Multi-clock domains | shipped bounded surface | Actor-level `(clock-domains ...)` with named domains, one default domain, optional per-domain resets, and `(domain NAME)` ownership annotations. | Lowering partitions the actor into one scheduled `.fsm` per domain plus a generated top. Direct cross-domain reads, writes, activations, and bindings fail closed unless a shipped crossing primitive owns the path. |
| Acknowledged event CDC | shipped bounded surface | `(crossings (event NAME (from SRC SRC_REQ) (to DST DST_PULSE) (ready SRC_READY)))`. | The generated top wires a concrete acknowledged-event CDC child. The source side sees `ready`; the destination side receives a one-cycle pulse. No data payload or same-cycle delivery is promised. |
| Cross-domain activation crossing | shipped bounded surface | `(crossings (activation CHILD (from SRC) (to DST)))` owning a blocking `(do CHILD)` — at the transaction top level, directly inside any top-level body (a `(repeat ...)` body or a `when`/`switch`/`while`/`until` branch body), directly inside a `(repeat ...)` nested in a top-level `when` body or top-level `switch` branch, directly inside a nested `when` chain reached from one of those top-level branch bodies, or directly inside a `(repeat ...)` under that nested `when` chain — where `CHILD` is a transaction in domain `DST` and the caller is in `SRC`. | Lowering auto-generates two acknowledged-event CDC children (start `SRC→DST`, done `DST→SRC`). The caller awaits `<child>_start_ready` then pulses a one-cycle `<child>_start` and blocks on `<child>_done`; the callee is gated on the start pulse and pulses `<child>_done` after awaiting `<child>_done_ready`. The same caller restructure applies in every shipped context (the branch/loop entry, nested repeat entry, or inner `when` branch entry is redirected into the start-ready await); inside a top-level repeat, loop, or branch-contained repeat the full handshake re-runs each iteration and the callee returns to idle between iterations. Full HDL emits the two domain modules, both CDC children, and the top. A cross-domain `(do)` with no covering crossing, a declared-but-unused or mis-placed crossing, cross-domain `(spawn)`, and deeper cross-domain `(do)` placements beyond the shipped contexts fail closed. |
| Interface ports | shipped | `(interface (input NAME [(width N\|PARAM\|CONST\|PACKAGE.CONSTANT)|(type T)] [(domain D)]) (output NAME ...))`, where `PARAM` is an actor-local scalar parameter default, `CONST` is a declared actor constant, and `PACKAGE.CONSTANT` is a qualified imported package scalar constant that resolves to a positive integer. | Ports become scheduled `.fsm` `+size` entries and module ports with resolved positive integer widths. Names are unique across input and output directions. Unknown symbolic width names, unknown/unqualified/aggregate/path package constants, runtime interface signals, zero/non-scalar params, zero-valued constants, ambiguous local-enum/package-constant tokens, and arbitrary width expressions fail closed. |
| Actor-owned scalar storage | shipped | `(storage (var NAME (width N\|PARAM\|CONST\|PACKAGE.CONSTANT) [(reset V)]) ...)` and `(variable NAME (width N\|PARAM\|CONST\|PACKAGE.CONSTANT))`, where `PARAM` is an actor-local scalar parameter default, `CONST` is a declared actor constant, and `PACKAGE.CONSTANT` is a qualified imported package scalar constant that resolves to a positive integer. An optional `(reset V)` on a `var` (a non-negative integer literal fitting the width) sets the register's hardware reset value — useful for **register maps / CSRs** that power up at a specified default. | Storage lowers to internal scalar registers with resolved positive integer widths, contributes width evidence, and appears in reports with role `actor_storage`. A `(reset V)` emits the `+size` carrier `(NAME width (reset V))` so the register powers up at `V` (`<sig> <= V` in the HDL reset block), defaulting to all-0s when unspecified (byte-identical to before). Unknown symbolic names, unknown/unqualified/aggregate/path package constants, ambiguous local-enum/package-constant tokens, runtime interface signals, zero/non-scalar params, zero-valued constants, width expressions, a per-element bank `(reset V)`, and an over-width or non-integer reset value fail closed. |
| Actor-owned banks | shipped bounded surface | `(storage (bank NAME (width N\|PARAM\|CONST\|PACKAGE.CONSTANT) (depth N\|PARAM\|CONST\|PACKAGE.CONSTANT)))` with pointer-selected `(store BANK IDX VALUE)` and `(load BANK IDX as TARGET)`, where `PARAM` is an actor-local scalar parameter default, `CONST` is a declared actor constant, and `PACKAGE.CONSTANT` is a qualified imported package scalar constant that resolves to a positive integer width or depth. | Banks lower to deterministic scalarized entries such as `data_0`, `data_1`, and so on, with resolved positive integer element widths and depths. Same-cycle read/write behavior follows the documented scalarized FIFO path. Unknown/unqualified/aggregate/path package constants, ambiguous local-enum/package-constant tokens, runtime signals, zero/non-scalar params, zero-valued constants, arbitrary expressions, dynamic depths, and duplicate scalarized signal names fail closed. |
| Type aliases and package imports | shipped bounded surface | Actor-local `(types ...)`, actor-local `(enums ...)`, `.fsm` package imports, scalar `(type NAME)` declarations, and actor-owned aggregate storage aliases. | Scheduled `.fsm` preserves `+types`, `+enums`, and `+import` review artifacts. Imported package roots are embedded for CLI HDL generation. |
| Enum member values | shipped bounded surface | Local and package enum members in constants, scalar and aggregate/list parameter leaves, activation overrides, reusable-library use-site overrides, generated child transaction parameter defaults, transaction/rule/drive scalar values, scalar expression operands, switch values/selectors, and standalone conditions/guards. Declared actor constants, earlier scalar actor parameters, and qualified imported package scalar constants may also back actor parameter scalar defaults and actor parameter aggregate/list leaves; declared actor constants, earlier scalar actor parameters, and qualified imported package scalar constants may back generated child transaction parameter defaults; qualified imported package scalar constants may back generated activation parameter overrides, reusable-library use-site overrides, actor top-level interface widths, transaction-local port widths, actor-owned scalar storage widths, actor-owned bank storage widths, and actor-owned bank storage depths; earlier scalar transaction parameters may back later generated child transaction parameter defaults and generated child or direct transaction-port width defaults. | Authored enum, actor constant, earlier actor-parameter, qualified package-constant, or earlier transaction-parameter tokens are preserved where scheduled `.fsm` can carry them; generated child transaction defaults literalize actor-static leaves before child/report publication while preserving child-local transaction dependencies, enum tokens, and qualified package-constant tokens, activation and reusable-library static specialization contexts resolve to literals before generated-top emission, package-constant-backed actor interface, transaction port, scalar storage, bank storage widths, and bank storage depths resolve to integer `+size` and HDL declarations, transaction-parameter-backed transaction ports resolve to integer port sizes and generated parent handoff widths where applicable, and actor-constant-backed, actor-parameter-backed, and qualified package-constant-backed actor parameter defaults resolve internally for scalar parameter consumers. Enum targets and operator-position enum members fail closed. |
| Aggregate scalar leaves | shipped bounded surface | Scalar member/item paths from declared actor-owned aggregate storage in documented RHS, target, guard, condition, switch, drive, and drive-call contexts. | Scalar leaves preserve authored paths in scheduled `.fsm` or lower through computed selector syntax when needed. Whole-record/list values, subaggregate writes, aggregate ports, and aggregate banks remain backlog. |
| Transaction entry | shipped | `(transaction NAME (on START ...) body...)`, direct entry samples, transaction ports, and parameter declarations where generated-child behavior owns them. | Entry logic generates start/idle behavior, captures accepted samples, and records transaction order in schedule reports. Unsupported entry-body forms fail closed. |
| Transaction ports and activation bindings | shipped bounded surface | Transaction `(ports ...)` declarations with `(width N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT)` entries, where `TX_PARAM` is a same-transaction scalar parameter default on a generated child or direct/non-generated transaction, `PARAM` is an actor-local scalar parameter default, `CONST` is a declared actor constant, and `PACKAGE.CONSTANT` is a qualified imported package scalar constant that resolves to a positive integer, plus activation-site `(bind ...)` blocks on `do`, `spawn`, and rule `trigger` where documented. Input bindings may add `(timing snapshot)` for current activation/trigger payload capture or `(timing live)` for current generated-top live handoff wiring. | Ports materialize as transaction-local data/control boundaries and generated handoff assignments using resolved positive integer widths. Reports expose bounded `transaction_port_bindings[]` provenance, including `actor_endpoint_kind` values `signal`, `literal`, or `expression`, `binding_timing` values `activation_region`, `generated_live_handoff`, `trigger_payload`, or `done_guarded`, and `authored_timing_mode` as `snapshot`, `live`, or JSON null; generated-child rule-trigger output bindings report the done-observer signal that guards the copy back to the actor target. `TX_PARAM` names resolve before actor constants and actor parameters and may derive from earlier scalar transaction parameter defaults. Cross-transaction parameter names, unknown/unqualified/aggregate/path package constants, ambiguous local-enum/package-constant tokens, runtime signals, zero/non-scalar params, zero-valued constants, arbitrary expressions, direct/local rule-trigger output bindings, behavior-changing snapshot-vs-live timing conversion, and mismatched timing mode/site combinations remain backlog or fail closed. |
| Transaction assignments | shipped | `(set TARGET EXPR)` and `(update VAR EXPR)` with scalar targets and expression payloads in the documented value domain. | Assignments lower to scheduled `.fsm` state assignments with correct flopped/combinational semantics for the form. Scalar aggregate leaves and enum members are accepted only in shipped contexts. |
| Runtime expression divisor safety | shipped bounded surface | Division and modulo in shipped runtime expression contexts such as transaction RHS, wait counts, activation input bindings, rule guards/actions, drive bodies/calls, inline drives, and bank access index/value expressions. | Numeric/exact-width literal-zero, actor-constant-zero, actor-parameter-zero, and same-transaction-parameter-zero divisors fail closed before scheduled `.fsm` emission. Nonzero literal, actor-constant, actor-parameter, same-transaction-parameter, and dynamic scalar divisors lower unchanged; full dynamic nonzero proof and use-site-specialized parameter divisor proof remain backlog. |
| Named and inline drives | shipped | Actor-level `(drive NAME [(PARAM ...)] body...)`; transaction body `(drive NAME actual...)`; inline drive assignments where documented. | A named drive emits a non-state DT. A drive call consumes one state and transfers actuals through generated drive parameter signals. Inline drive assignments become state assignments. |
| Await and latency | shipped | `(await PORT)`, top-level await-local `(watchdog N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT)` overrides where each bound resolves to a positive integer, actor watchdogs using positive decimal literals, declared positive actor constants, actor-local scalar parameter defaults, or qualified imported package scalar constants, and transaction `(latency (min N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT) (max N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT))` where each latency bound resolves to a positive integer. | Awaits lower to wait/test states and watchdog counters when configured. One transaction has one watchdog counter, so distinct per-await limits in one transaction fail closed. Latency counters and schedule-report storage metadata are emitted for the supported shapes. Transaction parameter top-level await-local watchdog limits and latency bounds shadow actor-level static names and remain local lowering inputs. Generated child activation overrides for watchdog/latency timing parameters are accepted only when they preserve the child default value; mismatches fail closed. Runtime signals, arbitrary expressions, unknown symbols, unknown/unqualified/aggregate/path package constants, zero-valued constants, zero-valued or non-scalar actor/transaction parameters, actor-level or nested control-flow transaction watchdog parameters, and cross-transaction parameters fail closed as latency bounds or watchdog limits. |
| Static and dynamic waits | shipped bounded surface | `(wait N)`, `(wait 0)`, actor-constant wait counts, actor-parameter wait counts, same-transaction scalar parameter wait counts, qualified package scalar-constant wait counts, accepted runtime wait count expressions, consecutive runtime waits, bank access predecessors, loop-control false-edge predecessors, and pending-sample runtime waits in documented contexts. | Static waits create explicit wait states unless zero-count bypass semantics apply. Runtime waits use generated counters. Transaction parameter waits shadow actor-level static names in their owning transaction and remain local lowering inputs. Generated child activation overrides for wait-count transaction parameters are accepted only when they preserve the child default value; mismatches fail closed. Bank `load`/`store` predecessors keep their guarded scalarized assignments while splitting the following runtime count edge. `(exit-when ...)` and `(continue-when ...)` loop-control states preserve their true exit/continue edge while splitting only the false fallthrough edge to a following runtime wait. Pending samples use a first active wait state on positive paths and sample-preserving zero-count clones for compatible successors such as drives, awaits, static waits, completion, independent scalar setters, independent shifts, independent assemble states, independent extract states, independent bank loads, independent bank stores, top-level await_all/await_any sync states, top-level spawn states, top-level transaction phase states, top-level ready/valid stages, top-level monitor arm states, and loop decision states. Consecutive top-level runtime waits carry pending samples through zero-count links with generated downstream wait-entry clones when needed. |
| Declared local variables | shipped bounded surface | `(local NAME (width N))` declares an internal register at an explicit width, private to the transaction. | The local is emitted in the module `+size` block at the declared width and is readable/writable in the transaction body (pinning the width vs. an inferred implicit internal scalar). A `(local ...)` whose name collides with an interface port, or whose `(width N)` is missing or non-positive, fails closed. An optional `(default V)` (synonym `(init V)`; a non-negative integer literal fitting the width) initializes the local on transaction entry (a transaction-local is re-initialized each run); an out-of-range or non-integer value fails closed. An optional `(reset V)` sets the local's **hardware reset value** (orthogonal to `(default V)`): it emits the `+size` carrier `(NAME width (reset V))` so the register powers up at `V` out of hardware reset (`<sig> <= V` in the HDL reset block), defaulting to all-0s when unspecified (byte-identical to before); an over-width or non-integer reset value fails closed. `(let NAME EXPR)` names an intermediate value by pure substitution (NAME -> EXPR in the rest of the scoped body; no register, no cycle), failing closed on a redefinition or an interface-port-name collision. |
| Reusable procedures | shipped bounded surface | `(proc NAME (params PARAMSPEC...) BODY...)` defines a reusable parameterized block; a `PARAMSPEC` is `(P (width N))` (an in/value parameter) or `(out P (width N))` (a write-back parameter). `(call NAME actuals...)` calls it INLINE — one positional actual per parameter. | The inline call macro-expands the procedure body at the call site with each parameter replaced by its actual; an in-parameter accepts a signal OR a whole expression, an out-parameter requires a plain signal lvalue the procedure writes into (the caller picks the destination per call). The emitted `.fsm` is identical to the hand-written substituted clauses (no instance, no handshake). Calls work in any clause position, including `when`/`switch`/`while`/`until` bodies. Recursion (direct or transitive), unknown procedure, argument-count mismatch, an expression passed for an out-parameter, and malformed `(proc ...)` fail closed. The handshake call form `(call NAME actuals... as INST)` synthesizes the procedure as a one-shot child transaction (in-params -> input ports, out-params -> output ports) and drives it with the bound `(do)` handshake (the call site binds the arguments, pulses start, blocks on done, reads the out-arguments); the `as INST` suffix picks the handshake convention over inline. A handshake `(call ... as)` missing its instance name, or a handshake procedure whose name collides with an existing transaction, fails closed. |
| Transaction control flow | shipped bounded surface | Body-bearing `(when COND body...)`, `(switch SELECTOR branches...)`, `(while COND body...)`, `(until COND body...)`, and `(repeat COUNT body...)`; repeat `COUNT` may be a non-negative literal, same-transaction scalar parameter default, non-negative actor constant, non-negative actor-local scalar parameter default, qualified package scalar constant, or known-width runtime name. A `(exit-when COND)` mid-loop early exit and a `(continue-when COND)` skip-to-next-iteration are accepted directly inside a `while`/`until` body. A `(for (i N) body...)` indexed counted loop (at the transaction top level, directly nested inside another `(for …)` body for nested loops, or embedded in a `when`/`switch`/`while`/`until`/`repeat` body) exposes a 0-based loop index `i` (counting `0 … N-1`) to its body; `(for (i N) ...)` takes a literal `N >= 1` (auto-sized index), `(for (i (width W) N) ...)` takes an explicit index width `W` with any count the counted `(repeat ...)` accepts (literal, parameter, constant, or runtime scalar), and `(for (i from A to B [step S]) ...)` counts `i = A, A+S, … < B` (literal `A`, `B`, `S` with `B > A`, `S >= 1`; `S` defaults to 1). A `(cond (c body...)... (else body...))` if/else-if/else priority chain runs the first branch whose condition holds (the optional `else` when none do). | Control flow lowers to explicit decision states, branch states, loop counters, and exits. A counted `(repeat N body...)` lowers check-first — the counter is loaded once and the per-iteration check exits when it reaches zero and otherwise decrements and runs the body — so the loop runs exactly `N` times and completes. A `(cond ...)` desugars (before for/let/proc expansion) into a `when`-chain with accumulated negated guards — branch `i` becomes `(when (& (! c1) … (! c(i-1)) ci) body…)` and the `else` gets the all-negated guard — so the first true branch wins; `else`-not-last, a missing condition, or an empty branch body fail closed. A `(for ...)` desugars in the parser (before procedure/`let` expansion) into a declared index `(local i (width W) (default START))` (START is `0`, or `A` for the range form) plus a counted `(repeat COUNT body... (set i (+ i 1)))`; a nested or embedded `(for …)` hoists its index local(s) to the transaction top (resetting the index per enclosing entry) and lowers to a nested counted `(repeat …)` (distinct counters). A zero width, a literal-zero or implicit-width-non-literal count, a non-upward range (`B <= A`) or non-literal range bounds, and an empty body fail closed. A leading runtime `(wait ...)` in a repeat body is supported by the repeat-check loop-back split: repeat-counter zero exits, repeat-counter nonzero plus positive wait count loads and enters the generated wait, and repeat-counter nonzero plus zero wait count bypasses to the following body state or a sample-compatible zero clone. A `(exit-when COND)` lowers to a decision state whose true edge takes the enclosing loop's exit target and whose false edge continues to the next body clause; a `(continue-when COND)` is the same but its true edge takes the loop's tail check (re-evaluate the condition). When a following body clause is a runtime `(wait ...)`, that false edge splits into generated counter load/entry and zero-count bypass paths under `!COND`, while the true edge remains the exit/continue target. Both fail closed outside a `while`/`until` body (top-level, `repeat`, `when`/`switch`). Positive static repeat counts provide counter-width evidence and use the documented load-token policy; known-width runtime scalar repeat counts bypass the body and repeat check when the runtime value is zero. Static zero counts lower as transparent no-op regions with no counter, repeat init/check state, repeat-body state, or `transaction_loops[]` entry; static-zero repeat-body `do` and `spawn` child activations, including syntactically valid parameterized, bound, or domain-annotated variants, are pruned with no generated child/top or local handoff artifact when their targets are not otherwise live. Malformed activation subclause syntax, unsupported count sources, cross-transaction parameters, non-scalar parameter sources, unqualified or aggregate package constants, package member/item paths, package constants inside expressions, and arbitrary expressions fail closed. The shipped repeat-body clause surface is limited to the documented drive, await, sample, update, set, shift, assemble, extract, store/load, wait, local/generated blocking do, generated spawn, same-body sync, source-order sample, static parameter/binding handoff, same-domain metadata, a nested counted `(repeat …)` (each repeat instance gets its own counter — the outermost keeps `<tx>_cnt`, a nested repeat uses a unique `<tx>_cnt_<n>` — so a `(repeat M (repeat N body))` runs the body `M*N` times), and bounded when/switch nested repeat subsets described in the transaction chapter. |
| Transaction stages | shipped bounded surface | Top-level `(stage NAME (ready READY) (valid VALID))` transaction clauses; `(input READY)`/`(output VALID)` remains an alias. | A stage lowers to one ready/valid barrier state that drives `VALID` while active and advances only when `READY` is true. Actor-level phase/stage metadata is report-visible but has no runtime scheduling semantics yet. The valid drive remains subject to same-target conflict checks. |
| Temporal contracts | shipped bounded surface | The bounded-eventually monitor `(assert (monitor (within SIGNAL N)) ["NAME"])` placed in a transaction body: from the cycle control reaches that clause, SIGNAL must hold within N cycles. N may be a positive integer literal, a declared actor constant, an actor-local scalar parameter default, a qualified imported package scalar constant, or a same-transaction scalar parameter default that resolves to a positive integer. (Replaces the former top-level `(contract …)` clause, removed in favor of this unified verification surface.) | Lowering injects an arm state at the clause position plus an arm/pending/age/fail monitor (storage role `temporal_contract_monitor`) in the scheduled `.fsm`, and asserts the negated fail bit as a same-cycle clocked concurrent property — so the temporal bookkeeping is synthesizable hardware and the assertion is verilator-simulable. Direct transaction parameters are local lowering inputs, not actor-level `.fsm` `+params`. SystemVerilog emits the assertion under `` `ifndef SYNTHESIS ``; Verilog output stays assertion-free. Runtime signals, arbitrary expressions, unknown names, unknown/unqualified/aggregate/path package constants, ambiguous local-enum/package-constant tokens, zero-valued constants, and zero-valued or non-scalar actor/transaction parameters fail closed as monitor windows. |
| Immediate verification checks | shipped bounded surface | Transaction-level `(assert COND [message])` / `(assume COND [message])` / `(cover COND [label])` — a clocked check; `COND` is any boolean expression over actor signals, or a temporal **property** — overlapping implication `(=> A B)` → SVA `(A) \|-> (B)`, the delay combinators `(next X)` / `(within X N)` / `(within X MIN MAX)`, the event/named trigger anchors `(after …)` / `(at …)`, the bounded-eventually monitor `(monitor (within S N))`, the SystemVerilog sampled-value predicates `(stable SIG)` / `(changed SIG)` / `(rose SIG)` / `(fell SIG)` → `$stable`/`$changed`/`$rose`/`$fell(SIG)`, and value-returning `(past SIG [N])` inside boolean property expressions such as `(== data (past data))` → `$past(SIG[, N])` — with an optional trailing message/label string. | A pure ISF family that rides the ISF → `.fsm` → SV path as a thin `+assert` carrier (each entry kind-tagged `assert`/`cover`/`assume`): the ISF lowerer emits `(+assert (NAME KIND COND ["msg"]) …)`, FSMGenFull parses it onto the module, `GeneratedModuleInfoBuilder` surfaces it into `module_info`, and `GeneratedModuleEmitter` emits, inside `` `ifndef SYNTHESIS ``, a **clocked concurrent property** per check — `assert property (@(posedge clk) disable iff (reset) (COND)) else $error("message")`, the `assume` mirror, or `cover property (@(posedge clk) disable iff (reset) (COND));` (a name-based default `$error` message for assert/assume when none is given; reset gating and clock-edge sampling are the synchronous-correct semantic; it falls back to an immediate combinational check only when the module has no clock). A `COND` that is a property combinator is parsed (FSMGenFull) into a tagged property tree over boolean leaves and rendered to SVA: `(=> A B)` → `(A) \|-> (B)` (overlapping implication), with a delayed consequent `(next X)` → `##1 (X)` and `(within X N)` → `##[1:N] (X)` (literal `N >= 1`) and `(within X MIN MAX)` → `##[MIN:MAX] (X)` (literal `1 <= MIN <= MAX`, the `min > 1` bounded window; `MIN = 0` fails closed). The SystemVerilog **sampled-value functions** include boolean leaves `(stable SIG)` / `(changed SIG)` / `(rose SIG)` / `(fell SIG)` → `$stable(SIG)` / `$changed(SIG)` / `$rose(SIG)` / `$fell(SIG)` (one signal each, usable standalone or as an `=>`/`after` antecedent/consequent) plus property-expression value calls `(past SIG)` / `(past SIG N)` → `$past(SIG)` / `$past(SIG, N)` (`N` a literal integer >= 1). They are not `##` sequences, so they stay verilator-simulable; they are property-only, so they fail closed in a synthesizable expression position. A check with a delayed (`##`) consequent is **formal-only** — verilator cannot simulate it — so it is emitted under `` `ifdef FORMAL `` (formal tools check it; verilator/yosys skip it, so `--verify-hdl` stays green), while boolean / overlapping-implication checks stay under `` `ifndef SYNTHESIS `` and are verilator-simulable. Signals referenced only by a check, including through `$past`, are kept alive as ports (classified `INPUT` by that reference, not pruned). Verilog (non-SV) output stays assertion-free; `yosys` skips the guarded block. A missing condition, extra operands, non-signal `past` operand, or nonpositive/nonliteral `past` depth fails closed. The bounded-eventually `(assert (monitor (within …)))` monitor rides this same `+assert` path. |
| Data manipulation | shipped bounded surface | `(select DST COND A B)`, `(max DST A B)`, `(min DST A B)`, `(swap A B)`, `(incr NAME [by N])`, `(decr NAME [by N])`, `(set-bit NAME N)`, `(clear-bit NAME N)`, `(toggle-bit NAME N)`, `(set-field NAME (bits HI LO) VALUE)`, `(when-bit NAME N body…)`, `(unless-bit NAME N body…)`, `(when-field NAME (bits HI LO) VALUE body…)`, `(unless-field NAME (bits HI LO) VALUE body…)`, `(shift_left REG BIT [(width N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT)])`, `(shift_right REG BIT [(width N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT)])`, `(rotate-left REG [by N])`, `(rotate-right REG [by N])`, `(assemble PART... as TARGET [(widths N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT...)])`, and `(extract WORD as FIELD... [(widths N\|TX_PARAM\|PARAM\|CONST\|PACKAGE.CONSTANT...)])`. | `(select DST COND A B)` is a pure parser desugar (after the cond/for/let/proc passes) into two mutually-exclusive conditional sets — `(when COND (set DST A)) (when (! COND) (set DST B))` — so `DST` takes `A` on the true path and `B` on the false path (two sequential decision states; `.fsm` has no ternary operator); a missing register name or anything other than exactly four operands fails closed. `(max DST A B)` / `(min DST A B)` desugar onto `(select DST (>= A B) A B)` / `(select DST (<= A B) A B)` (the larger / smaller of two values); a clamp composes as `(max v v lo)` then `(min v v hi)` (sequential writes, each with its own enable); a missing name or other than exactly three operands fails closed. `(swap A B)` desugars into the temp-free XOR swap — `(set A (^ A B)) (set B (^ A B)) (set A (^ A B))` — exchanging two distinct registers (`A`'s two writes get distinct enables); a non-two-register form or `A == B` fails closed. `(incr NAME [by N])` / `(decr NAME [by N])` are a pure parser desugar (after the cond/for/let/proc passes) into `(set NAME (+ NAME N))` / `(set NAME (- NAME N))` with `N` defaulting to `1` (a literal, signal, or expression) — valid anywhere a `(set …)` is, at the top level and in control-flow bodies; a missing name or a malformed `by` fails closed. `(set-bit NAME N)` / `(toggle-bit NAME N)` / `(clear-bit NAME N)` are a pure parser desugar (same staging) into a single-level masked `(set …)` — `(\| NAME 2^N)`, `(^ NAME 2^N)`, and `(& NAME ((2^width-1) ^ 2^N))` respectively — for a literal bit index `0 <= N < width`; set/toggle masks are width-independent, while `clear-bit`'s inverse mask is formed from the register's declared literal width (resolved from a `(local …)`, an interface port, or a `(storage (var …))`). A missing name, a missing / non-integer / out-of-range bit index, or (for `clear-bit`) a non-literal/symbolic width fails closed. `(set-field NAME (bits HI LO) VALUE)` is a pure parser desugar (same staging) into a sized masked read-modify-write `(set NAME (\| (& NAME W'dCLEARMASK) W'dSHIFTED))` — `CLEARMASK = (2^width-1) ^ (((2^(HI-LO+1))-1) << LO)`, `SHIFTED = VALUE << LO` — for literal `HI >= LO`, `HI < width`, and a literal `VALUE` fitting the field; the sized literals require the register's literal width, and a missing name / malformed `(bits …)` selector / non-literal bounds-or-value / reversed bounds / out-of-range `HI` / field overflow / symbolic width fails closed. `(when-bit NAME N body…)` / `(unless-bit NAME N body…)` are a pure parser desugar (before the compound/bit-op passes, so a `(set-bit …)`/`(incr …)` in the body still expands) into a `(when …)` with a width-qualified masked comparison — `(when (!= (& NAME W'dMASK) W'd0) body…)` and `(when (== (& NAME W'dMASK) W'd0) body…)` respectively — for a literal index `0 <= N < width`; the sized mask needs the register's literal width, and a missing name / non-integer or out-of-range index / empty body / symbolic width fails closed. `(when-field NAME (bits HI LO) VALUE body…)` / `(unless-field NAME (bits HI LO) VALUE body…)` generalise the bit test to a multi-bit field, desugaring (same staging) into `(when (== (& NAME W'dFIELDMASK) W'dSHIFTED) body…)` and `(when (!= …) body…)` respectively — `FIELDMASK = ((2^(HI-LO+1))-1) << LO`, `SHIFTED = VALUE << LO` — for literal `HI >= LO`, `HI < width`, and a literal `VALUE` fitting the field; a missing name / malformed `(bits …)` selector / non-literal bounds-or-value / reversed bounds / out-of-range `HI` / field overflow / empty body / symbolic width fails closed. Because they lower to an expression `(set …)`, a register written by two+ expression `(set …)`s across different states of one transaction (e.g. two literal `(incr x)` in a row, or two `(set-bit …)` on the same register) runs as that many sequential states, each driving its own distinct write-enable, so the writes compose in order. Width evidence comes from declarations, samples, operation-local options, and structural derivation. Operation-local width options accept positive integer literals, same-transaction scalar parameter defaults on generated child or direct/non-generated transactions, actor-local scalar parameter defaults, declared actor constants, or qualified imported package scalar constants that resolve to positive integers. `shift_left` can accept optional width evidence without requiring it for plain shifts; `shift_right` uses width evidence for the inserted MSB position. `(rotate-left REG [by N])` / `(rotate-right REG [by N])` are a pure parser desugar into a single masked shift-OR `(set REG (\| (<< REG N) (>> REG (W-N))))` (and the mirror) for a literal amount `0 < N < width` (default 1); the counter-shift amount needs the register's literal width, and a missing name / malformed `by` / out-of-range amount / symbolic width fails closed. `assemble` can accept ordered explicit part widths and can infer exactly one missing part width from a known target and known siblings; `extract` can infer exactly one missing destination field width from a known source and known siblings. Accepted forms avoid placeholder widths in scheduled `.fsm` review artifacts and publish known-width storage metadata; ambiguous, non-positive, unsupported package, runtime, unrelated or cross-transaction parameter, expression, activation-site override-specialized, or contradictory widths fail closed. |
| Rules and trigger fan-in | shipped | Shorthand and long-form `(rule NAME GUARD actions...)`, `(set TARGET EXPR)`, shorthand assignments, and `(trigger TRANSACTION ...)`. | Rules lower to non-state DTs with guarded assignment semantics. Trigger sources feed a generated transaction fan-in or generated-child trigger handoff for parameterized triggers. |
| Rule conflicts and priorities | shipped bounded surface | Same-target/same-value rule writes, conservative mutual-exclusion proofs, rule-local priority, actor-level rule/rule priority, actor-level rule-over-transaction priority, and actor-level transaction-over-rule priority for the covered same-target data case. | Compatible writes are accepted, priority can suppress lower-priority conflicting assignments in the documented cases, and unresolvable conflicts fail closed. Transaction-over-rule uses scheduled `.fsm` `state_active` guards instead of fake state-enable input ports. SystemVerilog gets verification-only selector assertions for analyzed muxes. |
| Resources | shipped bounded surface | `(resources (resource NAME (kind rule_slot\|output_bundle\|transaction_start\|storage_port) (arbiter priority) [(members OUTPUT_OR_STORAGE_SIGNAL...)] (users RULE...)))`, plus `(resource NAME (kind rule_slot\|output_bundle\|transaction_start\|storage_port) (arbiter round_robin) [(members OUTPUT_OR_STORAGE_SIGNAL...)] (users RULE...))`. For `transaction_start`, `NAME` is the target local transaction. `storage_port` requires explicit concrete actor-owned storage members when users are bound. Parser-recognized backlog kinds are documented. | `rule_slot`, `output_bundle`, `transaction_start`, and `storage_port` plus `priority` arbitration gate the whole bound rule DT for one cycle. The same four kinds plus bounded `round_robin` emit a generated pointer counter, grant the first requesting rule at or after that pointer, and advance the pointer from the winning rule DT. Unmembered `output_bundle` resources keep the implicit bound-rule output/LHS-target surface; explicit output-bundle members are declared actor outputs or concrete actor-owned storage signals and keep `resource_arbitration[].members` report evidence under both priority and round-robin. `storage_port` members are concrete actor-owned storage signals only and keep the same mandatory member validation/reporting under both priority and round-robin. Explicit members validate against bound rule writes in those domains. `transaction_start` priority grants suppress lower-priority rule triggers before the generated trigger fan-in DT; bounded round-robin grants gate trigger-source rule DTs before that same fan-in path. Backlog resource kinds, unsupported arbiter/kind combinations, `round_robin` on backlog resource kinds, generated-child transaction starts, generated-child storage arbitration, actor-network trigger resources, bank-root/aggregate/inferred explicit members, output-target users, storage locks, lifetime ownership, and route mux/storage fail closed or remain deferred. |
| Blocking child activation | shipped bounded surface | `(do child)` locally, including the documented top-level repeat-body local do subset, top-level when-body nested repeat local do subset, top-level when-body nested repeat local do while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat local do then generated spawn before same-body await_all drain subset, top-level when-body nested repeat local do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat local do after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat local do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat local do after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated-child do while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated-child do then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated-child do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated-child do after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated do with static params while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated do with static params then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated do with static params before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated-child do subset, top-level when-body nested repeat generated do with static params subset, top-level when-body nested repeat generated do with static params and bind handoffs subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain domain metadata subset, top-level switch-branch nested repeat local do subset, top-level switch-branch nested repeat local do while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat local do then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat local do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat local do after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat local do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat local do after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated-child do after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated-child do before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated-child do subset, top-level switch-branch nested repeat generated do with static params subset, top-level switch-branch nested repeat generated do with static params and bind handoffs subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain domain metadata subset, repeat-body plain `(do child)` targeting already generated children, samples before or after repeat-body do before the repeat check, `(do child (params ...))`, `(do child (params ...) (bind ...))`, and `(do child (params ...) [(bind ...)] (domain NAME))` as the documented top-level repeat-body generated blocking do subset, and `(do child (params ...) (bind ...))` through generated-child activation at top level. | Plain local `do` asserts child start and awaits a fresh child done pulse. Repeat-body local `do` reaches the repeat check only after that done pulse; when that repeat is directly inside a top-level `when` body or top-level `switch` branch, the local do state lives in the branch-owned repeat region and gates the nested repeat check on fresh child done. In the top-level when-body and top-level switch-branch nested repeat local do while generated nested spawn pending subsets, the local do may run before or after a prior multi-pending await_any observation, waits for the local child's fresh done pulse without clearing generated-spawn done handoffs, and a later same-body await_all drain still gates the nested repeat check on every outstanding generated child. In the top-level when-body and top-level switch-branch nested repeat generated-child do while generated nested spawn pending subsets, the generated-child do waits for its deterministic generated do instance's fresh done handoff without clearing generated-spawn done handoffs, and the later same-body await_all drain still gates the nested repeat check on every outstanding generated child; in the top-level when-body and top-level switch-branch subsets, that generated-child do may also appear after a prior multi-pending await_any observation. The documented prior-observation generated-child do-then-spawn subsets wait for that generated do instance before the later spawn, may run a second post-spawn await_any, and then require same-body await_all to drain the pre-do and post-do generated spawns. In the top-level when-body and top-level switch-branch nested repeat generated do with static params while generated nested spawn pending subsets, the generated do preserves static generated-top parameter binding, waits for its deterministic generated do instance's fresh done handoff, and leaves generated-spawn done handoffs live for the later same-body await_all drain. In both top-level branch-contained subsets, that static-parameter generated do may also appear after a prior multi-pending await_any observation. That static-parameter generated do may also complete before one or more later generated spawns, either with no active multi-pending await_any observation before the later spawn or after the generated do follows a prior multi-pending observation; after a prior observation it may run a second post-spawn await_any before the mandatory same-body await_all, and the final await_all drains every pre-do and post-do generated-spawn handoff. In both top-level branch-contained subsets, that static-parameter generated do may also appear before a post-do multi-pending await_any observation; the do completes before the observation, and the later same-body await_all drains the same pending generated-spawn set. In the top-level when-body and top-level switch-branch nested repeat generated do with static params and bind handoffs before post-do multi-pending await_any subsets, the generated do also wires generated-top input/output payload handoffs before the observation while the later same-body await_all drains the same pending generated-spawn set. In the top-level when-body and top-level switch-branch nested repeat generated do with static params and bind handoffs while generated nested spawn pending subsets, the generated do also wires generated-top input/output payload handoffs once for the lexical generated do site while leaving generated-spawn done handoffs live for the later same-body await_all drain. Those bound generated-do subsets may also start one or more later generated spawns before the mandatory same-body await_all drain after the generated do done handoff and generated-top binding handoffs have completed, either when no multi-pending await_any observation is active before the later spawn or after the generated do follows a prior multi-pending observation; in the prior-observation form, a second post-spawn multi-pending await_any may run before the mandatory same-body await_all drain, and both observations leave the pre-do and post-do generated-spawn done set live for that final drain. Those bound generated-do do-then-spawn subsets may also run a post-spawn multi-pending await_any observation before that mandatory same-body await_all drain when no prior multi-pending await_any observation is active before the later spawn; generated-top binding handoffs remain scoped to the generated do instance and the final drain observes both pre-do and post-do generated spawns. In the top-level when-body and top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata while generated nested spawn pending subsets, the generated do records declared ownership metadata without implying CDC and leaves generated-spawn done handoffs live for the later same-body await_all drain. Those same-domain generated-do subsets may also start one or more later generated spawns after the generated do done handoff while preserving declared ownership metadata on the generated do instance, either when no multi-pending await_any observation is active before the later spawn or after the generated do follows a prior multi-pending observation; in the prior-observation form, the same shape may also insert a second post-spawn multi-pending await_any before the mandatory same-body await_all drain, and both await_any observations leave the outstanding generated-spawn done set live for the final drain while retaining declared ownership metadata on the generated do instance. Those same-domain generated-do do-then-spawn subsets may also run a post-spawn multi-pending await_any observation before the mandatory same-body await_all drain when no prior multi-pending await_any observation is active before the later spawn; declared ownership metadata remains scoped to the generated do instance and the final drain observes both pre-do and post-do generated spawns. When a repeat directly inside a top-level `when` body or top-level `switch` branch uses plain `(do child)` for a target already generated elsewhere, or uses `(do child (params ...))`, lowering emits one generated instance named `{parent}_{child}_repeat_do_{ordinal}` for that lexical nested do site and gates the nested repeat check on that instance's done handoff. When-contained and switch-contained `(do child (params ...) (bind ...))` wire generated-top input/output payload handoffs once for the lexical nested do site; when-contained and switch-contained `(do child (params ...) [(bind ...)] (domain NAME))` also record same-domain generated-instance metadata for that lexical nested do site. Repeat-body generated-child blocking do emits the same deterministic generated instance shape for top-level repeat-body generated-child do sites. Samples before repeat-body do materialize before the do state; samples after repeat-body do materialize after the fresh done guard and before the repeat check. Repeat-body generated blocking do with static params, optional bind handoffs, and optional same-domain metadata adds generated-top parameter binding, generated-top input/output payload handoff wiring, and clock-domain child-instance metadata for that lexical do site. Top-level parameterized/bound `do` keeps its broader generated child handoff surface at top level. |
| Spawned generated children | shipped bounded surface | `(spawn child as instance [(params ...)] [(bind ...)] [(domain NAME)])`, `(await_all done)`, `(await_any done)`, the documented top-level repeat-body spawn with optional static params, optional bind handoffs, optional same-domain domain metadata, samples before or after spawn before same-body sync, same-body await_all, single-pending same-body await_any, and multi-pending repeat-body await_any with mandatory same-body await_all drain subset, plus documented top-level when-body and switch-branch nested repeat generated spawns with same-body await_all, single-pending same-body await_any when exactly one generated child is pending, or multi-pending same-body await_any with mandatory same-body await_all drain, top-level when-body nested repeat local do while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat local do then generated spawn before same-body await_all drain subset, top-level when-body nested repeat local do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat local do after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat local do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat local do after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated-child do while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated-child do then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated-child do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated-child do after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated do with static params while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated do with static params then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated do with static params before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat local do while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat local do then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat local do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat local do after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat local do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat local do after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated-child do after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated-child do before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset, and top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset. Static parameter override values may use literals, actor constants, actor-local scalar parameter defaults, enum members, qualified imported package scalar constants, and compatible aggregate/list literals with shipped leaf value sources. | Lowering emits parent, child, and generated top scheduled `.fsm` artifacts. Instance start/done handoffs, named-drive handoffs, parameter overrides, port-binding handoffs, same-domain ownership metadata, and schedule-report generated-composition/clock-domain metadata are bounded public review surfaces. Static parameter override values resolve to literal generated-top bindings before `?fsmc` emission, including qualified imported package scalar constants. Repeat-body spawn reuses one static generated child instance across iterations after await_all, exactly-one-pending await_any, or multi-pending await_any followed by same-body await_all observes fresh done for all outstanding children before the repeat check; sample-before-spawn materializes before the spawn state and sample-after-spawn materializes before the sync state. The branch-contained nested spawn subsets use the same generated-top handoff model and gate the nested repeat check on same-body await_all, on single-pending same-body await_any for exactly one pending generated child, or on multi-pending same-body await_any followed by a mandatory same-body await_all drain. The when-contained and switch-contained local do while generated nested spawn pending subsets keep the generated done set live across the local do until same-body await_all drains it, including when a multi-pending await_any observation occurred before the local do. The when-contained and switch-contained local do then generated spawn before same-body await_all drain subsets wait for the local child done pulse, start the later generated spawn, and drain both pre-do and post-do generated spawns before nested repeat re-entry. Those local-do do-then-spawn subsets may also start the later generated spawn after a prior multi-pending await_any observation, provided the local done pulse is observed first, then run a second post-spawn multi-pending await_any before the mandatory same-body await_all drain; both await_any observations leave the outstanding generated-spawn done set live for that final drain. Those local-do do-then-spawn subsets may also run a post-spawn multi-pending await_any observation before the mandatory same-body await_all drain when no prior multi-pending await_any observation is active before the later spawn; the observation leaves both pre-do and post-do generated-spawn done handoffs live for that final drain. The when-contained and switch-contained generated-child do while generated nested spawn pending subsets keep the same generated done set live across the generated do instance until same-body await_all drains it. The when-contained and switch-contained generated-child do then generated spawn before same-body await_all drain subsets wait for the generated do instance done handoff, start the later generated spawn, and drain both pre-do and post-do generated spawns before nested repeat re-entry. Those plain generated-child do-then-spawn subsets may also start the later generated spawn after a prior multi-pending await_any observation, provided the generated do instance done handoff is observed first, then run a second post-spawn multi-pending await_any before the mandatory same-body await_all drain; both await_any observations leave the outstanding generated-spawn done set live for that final drain. Those plain generated-child do-then-spawn subsets may also run a post-spawn multi-pending await_any observation before the mandatory same-body await_all drain when no prior multi-pending await_any observation is active before the later spawn; the observation leaves both pre-do and post-do generated-spawn done handoffs live for that final drain. The when-contained and switch-contained generated-child subsets also allow a prior multi-pending await_any observation before that generated do, and also allow the generated-child do before a post-do multi-pending await_any observation before the mandatory same-body await_all drain. The when-contained and switch-contained generated do with static params while generated nested spawn pending subsets preserve static parameter binding and keep the same generated done set live across the generated do instance until same-body await_all drains it. Those static-parameter generated-do subsets may also start one or more later generated spawns before the mandatory same-body await_all drain. Without prior multi-pending await_any this covers pre-do and post-do generated spawns. After prior multi-pending await_any, the path may run a second post-spawn multi-pending await_any before the mandatory same-body await_all drain; both observations leave pre-do and post-do generated-spawn done handoffs live for that final drain. Those static-parameter generated-do do-then-spawn subsets may also run the post-spawn multi-pending await_any observation when no prior multi-pending await_any observation is active before the later spawn. Both top-level branch-contained subsets also permit that static-parameter generated do after a prior multi-pending await_any observation. The when-contained and switch-contained static-parameter generated do subsets also permit the generated do before a post-do multi-pending await_any observation; the do completes before the observation and the later same-body await_all drains the same pending generated-spawn set. The when-contained and switch-contained generated do with static params and bind handoffs while generated nested spawn pending subsets also wire generated-top input/output payload handoffs for the generated do instance while keeping the same generated done set live until same-body await_all drains it. Those bound generated-do subsets may also start one or more later generated spawns after the generated do done handoff and generated-top binding handoffs have completed, either when no multi-pending await_any observation is active before the later spawn or after the generated do follows a prior multi-pending observation; in the prior-observation form, a second post-spawn multi-pending await_any may run before the mandatory same-body await_all drain, and both observations leave the pre-do and post-do generated-spawn done set live for that final drain. Both top-level branch-contained subsets also permit that bound generated do before a post-do multi-pending await_any observation. Those bound generated-do do-then-spawn subsets may also run a post-spawn multi-pending await_any observation before the mandatory same-body await_all drain when no prior multi-pending await_any observation is active before the later spawn; generated-top binding handoffs remain scoped to the generated do instance and the final drain observes both pre-do and post-do generated spawns. The when-contained and switch-contained generated do with static params, optional bind handoffs, and same-domain metadata while generated nested spawn pending subsets record declared ownership metadata without changing the later drain requirement. Those same-domain generated-do subsets may also start one or more later generated spawns after the generated do done handoff while preserving declared ownership metadata on the generated do instance, either when no multi-pending await_any observation is active before the later spawn or after the generated do follows a prior multi-pending observation; in the prior-observation form, the same shape may also insert a second post-spawn multi-pending await_any before the mandatory same-body await_all drain, and both await_any observations leave the outstanding generated-spawn done set live for the final drain while retaining declared ownership metadata on the generated do instance. Those same-domain generated-do do-then-spawn subsets may also run a post-spawn multi-pending await_any observation before the mandatory same-body await_all drain when no prior multi-pending await_any observation is active before the later spawn; declared ownership metadata remains scoped to the generated do instance and the final drain observes both pre-do and post-do generated spawns. The when-contained and switch-contained generated do with static params, optional bind handoffs, and same-domain metadata after prior multi-pending await_any subsets record declared ownership metadata while preserving the later drain requirement. The when-contained and switch-contained same-domain generated-do post-do await_any subsets record declared ownership metadata before the observation, require generated do completion first, and preserve the later same-body await_all drain. prior-active-await_any local-do, plain generated-child, static-parameter generated-do, bound generated-do, and same-domain generated-do spawn-after-do with a second post-spawn await_any are shipped for the documented when-body and switch-branch drain subsets; prior-active-await_any same-domain generated-do spawn-after-do is shipped for the documented direct-to-await_all drain subsets; missing same-body await_all drain, cross-domain activation, deeper branch/loop nesting, CDC behavior, and broader outstanding-child lifetime semantics remain fail-closed; plain generated-child prior-active-await_any spawn-after-do, local post-do await_any, and top-level when-body and switch-branch generated-child, static-parameter, static-bound, and same-domain post-do await_any are shipped only for documented subsets. |
| Reusable ISF libraries | shipped bounded surface | `(library NAME (exports (actor A)) (actor A ...))`, actor `(imports (library NAME as ALIAS))`, and `(use ALIAS.actor as INSTANCE (params ...) (bind ...))`. Use-site parameter overrides may use literals, importing-actor constants, importing-actor scalar parameter defaults, enum members, qualified imported package scalar constants, and compatible aggregate/list literals with those scalar leaves. | Library use lowers to generated composition artifacts and report `library_uses[]` metadata with literalized override values, including package-constant-backed use-site overrides. The shipped catalog includes `common.fifo.fifo`; parameter-driven shape elaboration and nested library imports remain backlog. |
| Schedule reports | shipped bounded surface | `--emit-schedule-json` and in-process `report(...)`. | Reports expose actor, transaction, storage, rule, drive, static actor-network, generated-composition, library-use, clock-domain, crossing, issue, schema-version, and public-contract metadata only through bounded documented keys. |
| Schedule report schema and storage roles | shipped bounded surface | Schedule JSON `schema_version: 1`, public `schedule_report_full_schema_stable`, advertised key/value families, and `inferred_storage[].kind`/`role` values. | The version-1 schedule JSON schema is stable through the public contract. Storage roles include dynamic waits, activation handoffs, ATL trigger-start handoffs, scheduler timeout-status latches, rule-trigger sources, transaction ports/bindings, temporal contract monitors, and resource round-robin pointers. Raw parser actor hashes, private `LoweringIR` internals, raw assignment lists, and recursive child report dumps remain private. |
| Diagnostics and downstream issue reporting | shipped | Fail-closed parser/lowering diagnostics, strict-mode compatibility cuts, `--check --json` / `--check-json` failure payloads, and `bin/fsmgen-issue-bundle`. | Unsupported public forms reject before misleading artifacts are emitted. For `.isf` inputs, parser, lowering, report-building, and semantic check failures emit `success: false` JSON in check mode instead of empty stdout. Downstream consumers can provide a reproducible issue bundle without understanding `.fsm` or `.isf` internals. |

Repeat-body activation matrix note: the shipped top-level when-body nested
repeat generated do with static params and bind handoffs after multi-pending
await_any while generated nested spawn pending before same-body await_all
drain subset preserves generated-top input/output binding handoffs and leaves
the pending generated-spawn done set live for the later drain.

The shipped top-level switch-branch nested repeat generated do with static
params and bind handoffs after multi-pending await_any while generated nested
spawn pending before same-body await_all drain subset uses the same
generated-top binding handoff and later drain contract.

The shipped top-level when-body nested repeat generated do with static
params, optional bind handoffs, and same-domain metadata after multi-pending
await_any while generated nested spawn pending before same-body await_all
drain subset records declared ownership metadata for the generated do
instance and generated children without implying CDC or cross-domain
activation.

The shipped top-level switch-branch nested repeat generated do with static
params, optional bind handoffs, and same-domain metadata after multi-pending
await_any while generated nested spawn pending before same-body await_all
drain subset mirrors that ownership metadata and later drain contract.

The shipped top-level when-body nested repeat generated do with static params,
optional bind handoffs, and same-domain metadata after multi-pending
await_any then generated spawn before same-body await_all drain subset records
declared ownership metadata for the generated do instance, waits for that do
handoff, starts the later generated spawn, and advances to the mandatory
same-body await_all drain. The same prior-observation form may also insert a
second post-spawn multi-pending await_any observation before that final
drain; both await_any observations leave the outstanding generated-spawn done
set live for the final drain while retaining declared ownership metadata on
the generated do instance.

The shipped top-level switch-branch nested repeat generated do with static
params, optional bind handoffs, and same-domain metadata after multi-pending
await_any then generated spawn before same-body await_all drain subset mirrors
that same-domain prior-observation do-then-spawn contract.

The shipped top-level when-body nested repeat local do after multi-pending
await_any then generated spawn before second multi-pending await_any and
same-body await_all drain subset waits for the local child done pulse before
the later generated spawn, treats both await_any clauses as observation-only,
and drains pre-do and post-do generated spawns through the final await_all.

The shipped top-level switch-branch nested repeat local do after multi-pending
await_any then generated spawn before second multi-pending await_any and
same-body await_all drain subset mirrors that repeated-observation local-do
contract.

The shipped top-level when-body nested repeat local do before post-do
multi-pending await_any while generated nested spawn pending before same-body
await_all drain subset waits for the local child done pulse before the
observation and leaves the pending generated-spawn done set live for the
later drain.

The shipped top-level switch-branch nested repeat local do before post-do
multi-pending await_any while generated nested spawn pending before same-body
await_all drain subset mirrors that local-child and later-drain contract.

The shipped top-level when-body nested repeat generated-child do before
post-do multi-pending await_any while generated nested spawn pending before
same-body await_all drain subset waits for the generated do instance done
handoff before the observation and leaves the pending generated-spawn done
set live for the later drain.

The shipped top-level switch-branch nested repeat generated-child do before
post-do multi-pending await_any while generated nested spawn pending before
same-body await_all drain subset mirrors that generated-child and later-drain
contract.

The shipped top-level when-body nested repeat generated do with static params
before post-do multi-pending await_any while generated nested spawn pending
before same-body await_all drain subset waits for the generated do instance
done handoff before the observation, preserves generated-top parameter
binding, and leaves the pending generated-spawn done set live for the later
drain.

The shipped top-level switch-branch nested repeat generated do with static
params before post-do multi-pending await_any while generated nested spawn
pending before same-body await_all drain subset mirrors that static-parameter
generated do and later-drain contract.

The shipped top-level when-body nested repeat generated-child do then
generated spawn before post-spawn multi-pending await_any and same-body
await_all drain subset waits for the generated do instance done handoff,
starts the later generated spawn, observes either pre-do or post-do generated
spawn with await_any, and drains both generated spawns before nested repeat
re-entry.

The shipped top-level switch-branch nested repeat generated-child do then
generated spawn before post-spawn multi-pending await_any and same-body
await_all drain subset mirrors that generated-child do-then-spawn
post-observation contract.

The shipped top-level when-body nested repeat generated do with static params
then generated spawn before same-body await_all drain subset waits for the
generated do instance done handoff, starts the later generated spawn, and
drains pre-do and post-do generated spawns before nested repeat re-entry.

The shipped top-level switch-branch nested repeat generated do with static
params then generated spawn before same-body await_all drain subset mirrors
that static-parameter generated-do then-spawn contract.

The shipped top-level when-body nested repeat generated do with static params
after multi-pending await_any then generated spawn before second
multi-pending await_any and same-body await_all drain subset preserves the
static parameter override on the generated do instance, waits for that do
handoff, starts the later generated spawn, treats both await_any clauses as
observation-only, and drains pre-do and post-do generated spawns through the
final await_all.

The shipped top-level switch-branch nested repeat generated do with static
params after multi-pending await_any then generated spawn before second
multi-pending await_any and same-body await_all drain subset mirrors that
static-parameter prior-observation repeated-await_any contract.

The shipped top-level when-body nested repeat generated do with static params
and bind handoffs after multi-pending await_any then generated spawn before
second multi-pending await_any and same-body await_all drain subset preserves
the static parameter override and generated-top input/output binding handoffs
on the generated do instance, waits for that do handoff, starts the later
generated spawn, treats both await_any clauses as observation-only, and
drains pre-do and post-do generated spawns through the final await_all.

The shipped top-level switch-branch nested repeat generated do with static
params and bind handoffs after multi-pending await_any then generated spawn
before second multi-pending await_any and same-body await_all drain subset
mirrors that bound generated-do prior-observation repeated-await_any
contract.

The shipped top-level when-body nested repeat generated do with static params
and bind handoffs then generated spawn before same-body await_all drain subset
wires generated-top input/output binding handoffs for the generated do
instance, waits for that do handoff, starts the later generated spawn, and
drains pre-do and post-do generated spawns before nested repeat re-entry.

The shipped top-level switch-branch nested repeat generated do with static
params and bind handoffs then generated spawn before same-body await_all drain
subset mirrors that bound generated-do then-spawn contract.

The shipped top-level when-body nested repeat generated do with static params
and bind handoffs then generated spawn before post-spawn multi-pending
await_any and same-body await_all drain subset wires generated-top
input/output binding handoffs for the generated do instance, waits for that
do handoff, starts the later generated spawn, observes either pre-do or
post-do generated spawn with await_any, and drains both generated spawns
before nested repeat re-entry.

The shipped top-level switch-branch nested repeat generated do with static
params and bind handoffs then generated spawn before post-spawn multi-pending
await_any and same-body await_all drain subset mirrors that bound
generated-do do-then-spawn post-observation contract.

The shipped top-level when-body nested repeat generated do with static params,
optional bind handoffs, and same-domain metadata then generated spawn before
same-body await_all drain subset preserves declared ownership metadata for the
generated do instance, waits for that do handoff, starts the later generated
spawn, and drains pre-do and post-do generated spawns before nested repeat
re-entry.

The shipped top-level switch-branch nested repeat generated do with static
params, optional bind handoffs, and same-domain metadata then generated spawn
before same-body await_all drain subset mirrors that ownership-metadata
then-spawn contract.

The shipped top-level when-body nested repeat generated do with static params,
optional bind handoffs, and same-domain metadata then generated spawn before
post-spawn multi-pending await_any and same-body await_all drain subset
preserves declared ownership metadata for the generated do instance, waits
for that do handoff, starts the later generated spawn, observes either pre-do
or post-do generated spawn with await_any, and drains both generated spawns
before nested repeat re-entry.

The shipped top-level switch-branch nested repeat generated do with static
params, optional bind handoffs, and same-domain metadata then generated spawn
before post-spawn multi-pending await_any and same-body await_all drain subset
mirrors that same-domain generated-do do-then-spawn post-observation
contract.

The shipped top-level when-body nested repeat generated do with static params
and bind handoffs before post-do multi-pending await_any while generated
nested spawn pending before same-body await_all drain subset additionally
wires generated-top input/output binding handoffs for the generated do
instance before the observation.

The shipped top-level switch-branch nested repeat generated do with static
params and bind handoffs before post-do multi-pending await_any while
generated nested spawn pending before same-body await_all drain subset mirrors
that generated-top binding handoff and later-drain contract.

The shipped top-level when-body nested repeat generated do with static
params, optional bind handoffs, and same-domain metadata before post-do
multi-pending await_any while generated nested spawn pending before same-body
await_all drain subset records declared ownership metadata for the generated
do instance before the observation and leaves the pending generated-spawn done
set live for the later drain.

The shipped top-level switch-branch nested repeat generated do with static
params, optional bind handoffs, and same-domain metadata before post-do
multi-pending await_any while generated nested spawn pending before same-body
await_all drain subset mirrors that ownership-metadata and later-drain
contract.

prior-active-await_any local-do, plain generated-child, static-parameter
generated-do, bound generated-do, and same-domain generated-do spawn-after-do
with a second post-spawn await_any are shipped for the documented when-body
and switch-branch drain subsets.

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

## Examples By Family

### CLI Entrypoints

```bash
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --strict --outdir /tmp/isf-build isf/spawn_parent.isf
./bin/fsmgen -l sv isf/apb_requester.isf
```

`--emit-schedule-json` reports the scheduled intent view and exits before HDL
generation. `--outdir` is the public path for multi-file lowering, including
generated-child and accepted multi-domain actors. Plain `.isf` HDL generation
lowers through scheduled `.fsm` first, then continues through the existing HDL
pipeline.

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
coupling, CDC, ready/backpressure, or permanent actor grouping.

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
repeated triggers, trigger batches, groups, and permanent actor grouping remain
deferred.

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
repeat-body subset. The basic loop-contained/deeper-nested `spawn` + same-body
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
<summary>Repeat-body audit markers</summary>

These phrases are intentionally kept verbatim so the feature-matrix audit can
detect the shipped branch-contained repeat/activation subsets without relying
on prose wrapping:

```text
top-level repeat-body local blocking do
top-level repeat-body generated-child blocking do
top-level repeat-body generated blocking do with static params, bind handoffs, and same-domain domain metadata
top-level repeat-body spawn with optional static params, optional bind handoffs, optional same-domain domain metadata, samples before or after spawn before same-body sync, same-body await_all, single-pending same-body await_any, and multi-pending repeat-body await_any with mandatory same-body await_all drain subset
top-level when-body nested repeat generated spawns with optional static params, bind handoffs, same-domain domain metadata, source-order samples, same-body await_all, single-pending same-body await_any when exactly one generated child is pending, and multi-pending same-body await_any with mandatory same-body await_all drain
top-level switch-branch nested repeat generated spawns with optional static params, bind handoffs, same-domain domain metadata, source-order samples, same-body await_all, single-pending same-body await_any when exactly one generated child is pending, and multi-pending same-body await_any with mandatory same-body await_all drain
top-level when-body nested repeat local do before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain
top-level when-body nested repeat local do then generated spawn before same-body await_all drain
top-level when-body nested repeat generated-child do before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain
top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn before same-body await_all drain
top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain
top-level when-body nested repeat generated-child do then generated spawn before same-body await_all drain
top-level when-body nested repeat generated-child do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain
top-level when-body nested repeat generated do with static params then generated spawn before same-body await_all drain
top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before same-body await_all drain
top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain
top-level when-body nested repeat generated do with static params and bind handoffs then generated spawn before same-body await_all drain
top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any while generated nested spawn pending before same-body await_all drain
top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any while generated nested spawn pending before same-body await_all drain
top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any then generated spawn before same-body await_all drain
top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain
top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before same-body await_all drain
top-level switch-branch nested repeat local do before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain
top-level switch-branch nested repeat local do then generated spawn before same-body await_all drain
top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn before same-body await_all drain
top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain
top-level switch-branch nested repeat generated-child do then generated spawn before same-body await_all drain
top-level switch-branch nested repeat generated-child do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain
top-level switch-branch nested repeat generated do with static params then generated spawn before same-body await_all drain
top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before same-body await_all drain
top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain
top-level switch-branch nested repeat generated do with static params and bind handoffs then generated spawn before same-body await_all drain
top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any while generated nested spawn pending before same-body await_all drain
top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any while generated nested spawn pending before same-body await_all drain
top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any then generated spawn before same-body await_all drain
top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain
top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before same-body await_all drain
top-level when-body nested repeat local do before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset
top-level when-body nested repeat local do then generated spawn before same-body await_all drain subset
top-level when-body nested repeat generated-child do before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset
top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn before same-body await_all drain subset
top-level when-body nested repeat generated-child do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset
top-level when-body nested repeat generated-child do then generated spawn before same-body await_all drain subset
top-level when-body nested repeat generated-child do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset
top-level when-body nested repeat generated do with static params then generated spawn before same-body await_all drain subset
top-level when-body nested repeat generated do with static params and bind handoffs then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset
top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset
top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset
top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any then generated spawn before same-body await_all drain subset
top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset
top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before same-body await_all drain subset, top-level when-body nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset
top-level switch-branch nested repeat local do before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset
top-level switch-branch nested repeat local do then generated spawn before same-body await_all drain subset
top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn before same-body await_all drain subset
top-level switch-branch nested repeat generated-child do after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset
top-level switch-branch nested repeat generated-child do then generated spawn before same-body await_all drain subset
top-level switch-branch nested repeat generated-child do then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset
top-level switch-branch nested repeat generated do with static params then generated spawn before same-body await_all drain subset
top-level switch-branch nested repeat generated do with static params and bind handoffs before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset
top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any while generated nested spawn pending before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset
top-level switch-branch nested repeat generated do with static params and bind handoffs then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params and bind handoffs then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset
top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before same-body await_all drain subset, top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata then generated spawn before post-spawn multi-pending await_any and same-body await_all drain subset
top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any then generated spawn before same-body await_all drain subset
top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata after multi-pending await_any then generated spawn before second multi-pending await_any and same-body await_all drain subset
top-level switch-branch nested repeat generated do with static params, optional bind handoffs, and same-domain metadata before post-do multi-pending await_any while generated nested spawn pending before same-body await_all drain subset
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
- Aggregate interface ports, transaction-local aggregate ports, aggregate
  banks, subaggregate updates, and whole-record/list truthiness remain backlog.
- Backlog resource kinds are registry names, not runtime arbitration support.
- Actor-level phase and stage metadata is report-only; it does not schedule
  actor-level runtime phases, barriers, generated `.fsm` states, or HDL
  behavior.
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
