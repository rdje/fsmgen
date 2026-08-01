
## Schedule Report

`FSM::Scheduler::ISF->report($actor)` and `--emit-schedule-json` produce a
machine-readable schedule report. On success, the CLI report path is expected
to keep stderr clean and emit the JSON payload on stdout.

The bounded public top-level key family is:

```text
schema_version
source
scheduled_fsm
clock
reset
watchdog
actor_phases
actor_stages
verification_observations
actor_params
actor_constants
port_count
inputs
outputs
state_count
inferred_storage
transactions
transaction_waits
transaction_loops
loop_early_exits
transaction_stages
temporal_contracts
bank_accesses
transaction_port_bindings
dt_blocks
actor_network
generated_composition
library_uses
compatible_fanin_groups
priority_resolutions
resource_arbitration
compile_issues
clock_domains
crossings
```

Current bounded nested and array summary families:

```text
reset: name, kind, polarity
actor_phases entries: name, body
actor_stages entries: name, body
verification_observations entries: name, role, clock, reset, signals
verification_observations signal entries: name, direction, width
actor_params entries: name, value
actor_constants entries: name, value
actor_network: kind, instances, groups, generated_tops, association_schedules, group_schedules, data_movements, event_waits, transaction_triggers
actor_network instances entries: name, actor_type, declaration
actor_network instance declaration values: actor, instance_alias
actor_network groups entries: name, members, mode, declaration, source, scheduling
actor_network generated_tops entries: kind, top_module, top_fsm, parent_module, parent_scheduled_fsm, instance, child_module, child_scheduled_fsm, target_transaction, trigger_parent_port, trigger_child_port, event, event_parent_port, event_child_port, clock, reset
actor_network generated_tops multi-child entries: kind, top_module, top_fsm, parent_module, parent_scheduled_fsm, children, clock, reset
actor_network generated_tops child entries: instance, child_module, child_scheduled_fsm, target_transaction, trigger_parent_port, trigger_child_port, event, event_parent_port, event_child_port
actor_network association_schedules entries: association, kind, lifetime, owner_transaction, context, members, target_transactions, signals, schedule, dependency_policy, storage, source, sink
actor_network group_schedules entries: group, owner_transaction, context, members, target_transactions, signals, schedule, dependency_policy, storage, source, sink
actor_network event_waits entries: transaction, context, instance, event, signal, source
actor_network transaction_triggers entries: owner_transaction, context, instance, target_transaction, signal, sink
inferred_storage entries: name, kind, optional role, optional type, optional type_kind, optional width, optional fields
transactions entries: name, states, count
transaction_waits entries: transaction, cycles, count_kind, count_source, entry_state, exit_state, counter_signal, counter_width
transaction_waits count_kind values: static, runtime_scalar, runtime_expression
transaction_loops entries: transaction, kind, condition, entry_state, decision_states, body_start, body_states, exit_state, body_clause_count
loop_early_exits entries: transaction, kind, state, condition, target
transaction_stages entries: transaction, name, kind, state, ready, valid
temporal_contracts entries: transaction, name, kind, trigger, signal, within_cycles, pending_signal, counter_signal, fail_signal, overlap_policy, reset_policy, assertion_projection
dt_blocks entries: name, kind, assignments
compile_issues entries: code, severity, target, domain, proof_status, reason, sources
compile_issues source entries: owner, owner_kind, source_kind, target, operator, rhs, domain
compile_issues with no nonfatal issues: empty array
compatible_fanin_groups entries: kind, domain, sources, optional target/value keys
compatible_fanin_groups source entries: same bounded source keys as compile_issues
priority_resolutions entries: target, winner, winner_kind, loser, loser_kind
resource_arbitration entries: resource, kind, arbiter, user, user_kind, members, suppressed_by
library_uses entries: library, alias, export, kind, instance, module, scheduled_fsm, parameters, bindings
library_uses parameter entries: name, source, value
library_uses binding entries: role, library_name, parent_name, width
bank_accesses entries: kind, owner, owner_kind, container_kind, container_name, bank, index, width, depth, scalar_entries, same_cycle_policy, value, target
transaction_port_bindings entries: site_kind, owner, owner_kind, target_transaction, role, port, actor_signal, actor_expression, actor_endpoint_kind, binding_timing, authored_timing_mode, width, instance, parent_port, child_port, start_signal, done_signal, trigger_source, payload_source
clock_domains entries: name, default, clock, reset, scheduled_fsm, ports, storage, transactions, rules, library_uses, child_instances, crossings, state_count, dt_block_count
clock_domains child_instances entries: kind, owner, child, instance
clock_domains crossings entries: event, role, signal, ready
crossings entries: name, kind, source_domain, source_signal, destination_domain, destination_signal, ready_signal, instance, module, outstanding_policy, payload, top_fsm
```

For each `dt_blocks` entry, `assignments` is a non-negative integer count of
assignment forms in the matching scheduled `.fsm` DT block. It is not an
assignment payload list. The machine-readable contract advertises this through
`schedule_report_dt_assignments_shape`.
For each `dt_blocks` entry, `kind` is currently one of `drive`,
`do_port_binding`, `latency_counter`, `rule`, `rule_trigger_fanin`,
`spawn_port_binding`, `temporal_contract_monitor`, or
`trigger_generated_activation`. The machine-readable contract advertises this
through `schedule_report_dt_kind_values`.

For each `inferred_storage` entry, `kind` is currently one of `counter` or
`register`. Optional `role` values describe the stable scheduler purpose when
the lowerer has direct evidence. The current role family is
`activation_done_handoff`, `activation_start_handoff`, `actor_storage`,
`atl_trigger_start_handoff`, `completion_pulse`, `data_register`,
`dynamic_wait_counter`, `drive_payload`, `drive_request`, `extract_field`,
`latency_counter`, `repeat_counter`, `resource_round_robin_pointer`,
`rule_trigger_payload_source`, `rule_trigger_source`, `sample_alias`,
`scheduler_error_status`, `temporal_contract_monitor`, `transaction_port`,
`transaction_port_binding`, `trigger_done_observe`, and `watchdog_counter`.
Runtime scalar and runtime expression waits use `dynamic_wait_counter` for
their generated sampled-count storage. Rule-trigger source pulses use
`rule_trigger_source`, and per-input trigger payload-source storage uses
`rule_trigger_payload_source`. Generated activation start/done handoff storage
uses `activation_start_handoff` and `activation_done_handoff` when those
one-bit generated handoff signals appear in `inferred_storage[]`. Generated
activation port-binding handoff storage uses `transaction_port_binding`, and
generated rule-trigger completion observation uses `trigger_done_observe`.
Static actor-network transaction triggers use `atl_trigger_start_handoff` for
the one-cycle parent-to-child start handoff pulses emitted by `(trigger
INSTANCE.TRANSACTION)` and trigger-batch lowering. Scheduler timeout terminal
states use `scheduler_error_status` for the global `last_error` latch they
write when an await watchdog or latency maximum trips.
Transaction-local port storage uses `transaction_port` when a declared
transaction port is materialized in the scheduled `.fsm` review artifact.
Bounded `round_robin` resource arbitration for `rule_slot`, `output_bundle`,
`transaction_start`, or `storage_port` uses
`resource_round_robin_pointer` for the generated pointer counter.
Temporal-contract pending/fail registers and age counters use
`temporal_contract_monitor`; use `temporal_contracts[]` to map those signal
names back to the specific bounded-eventual contract. Optional `width` values
are positive integer bit widths when present, and are currently present for
declared actor-owned storage, inferred scheduler counters, and register
storage with known ISF width evidence. Declared typed actor-owned storage may
also report the authored alias in `type` and the resolved top-level kind in
`type_kind`; these are bounded summaries and do not expose raw type-spec
hashes. Declared scalar actor-owned storage may also report optional
`fields[]` metadata entries with `name`, `msb`, `lsb`, `width`, and optional
`access`, `reset`, and inline `enum[]` member metadata. The machine-readable
contract advertises these through
`schedule_report_storage_kind_values`, `schedule_report_storage_role_values`,
`schedule_report_storage_optional_keys`, and
`schedule_report_storage_width_shape`.

Generated names in schedule reports and generated artifacts are deterministic
for the same source and FSMGen version, and bounded report fields may use them
as report-local or artifact-local identifiers. They are not a public semantic
string grammar. Downstream consumers should use explicit bounded fields such
as `owner`, `owner_kind`, `role`, `kind`, `instance`, `parent_port`,
`child_port`, `trigger_source`, `payload_source`, storage `role`, and
generated-composition summaries instead of deriving semantics from generated
name spelling. Before full schema freeze, a feature-scoped slice may change a
generated spelling only with synchronized docs, contract metadata where
applicable, and tests.
Schedule-report evolution is additive by default only for new top-level keys,
new nested optional keys, or new value-family members that are advertised in
the public contract metadata and covered by focused tests and docs in the same
slice. Removing an advertised key, renaming a key, changing a required key to
optional or vice versa, changing a value type, or changing an advertised
value's meaning is breaking and requires a `schema_version` bump plus
migration or deprecation documentation in the same slice. Deprecated fields
must remain documented until the schema version that removes them.

For each `bank_accesses` entry, `kind` is `store` or `load`;
`same_cycle_policy` is currently `read_before_write`; `scalar_entries` lists
the deterministic scalarized storage entries used in the scheduled `.fsm`;
`value` is populated for stores and JSON null for loads; `target` is populated
for loads and JSON null for stores. The machine-readable contract advertises
the exact key set and value families through
`schedule_report_bank_access_keys`,
`schedule_report_bank_access_kind_values`, and
`schedule_report_bank_access_policy_values`.

For each `transactions` entry, `states` is an array of scheduled state names
belonging to that transaction in emitted order, and `count` is a non-negative
integer equal to the `states` array length. The machine-readable contract
advertises this through `schedule_report_transaction_states_shape` and
`schedule_report_transaction_count_shape`.
The `transactions` array itself is sorted lexically by transaction name. Each
entry's `states` array keeps scheduled `.fsm` state emission order for that
transaction. The machine-readable contract advertises this through
`schedule_report_transaction_ordering`.

For each `actor_constants` entry, `name` is the actor-local constant name and
`value` is the stringified compile-time value emitted into scheduled `.fsm`
`+constants`. These constants are compile-time scheduler/source symbols, not
runtime ports, not overrideable params, and not inferred storage.

For each `actor_params` entry, `name` is the actor-level parameter name and
`value` is the JSON-safe default value emitted into scheduled `.fsm`
`+params`; scalar enum member defaults, actor-constant-backed scalar defaults,
actor-parameter-backed scalar defaults, qualified package-constant-backed
scalar defaults, and enum, actor-constant, earlier actor-parameter, or
qualified package-constant leaves inside aggregate/list defaults preserve the
authored tokens. Actor-static-backed defaults carry resolved literals
internally for scalar actor-parameter consumers such as widths and counts.
These are static specialization defaults, not runtime ports, and do not
replace the generated-composition or reusable-library parameter binding
reports for use sites. The
machine-readable contract advertises these through
`schedule_report_actor_param_keys`.

Generated-composition child `parameters[]` and instance
`parameter_bindings[]` entries preserve authored scalar enum member tokens and
aggregate/list enum leaves for generated child transaction parameter defaults,
and they preserve earlier scalar transaction-parameter dependency tokens
because those names are child-local. Qualified package-constant tokens and
leaves are also preserved in those child review surfaces because generated
child artifacts carry package imports and embedded package roots; resolved
scalar literals remain internal.
Actor constants and actor-local scalar parameter defaults used by generated
child transaction parameter defaults are literalized before child `+params`
emission and report publication, so generated-composition child defaults and
default instance bindings stay self-contained. Actor constants, actor-local
scalar parameter defaults, scalar enum member values, qualified package scalar
constants, and matching leaves inside activation aggregate/list override
values are resolved to literal values before generated-top emission, so
generated-composition instance `parameter_bindings[]` entries carry the
emitted literal override value for those use sites.

For each `actor_phases` or `actor_stages` entry, `name` is the authored
actor-level metadata name and `body` is the JSON-safe copy of the
parser-validated list-form body. These arrays are informational report
metadata only; actor-level phases and stages still do not add scheduler,
generated `.fsm`, generated-top, or HDL runtime behavior. The
machine-readable contract advertises these through
`schedule_report_actor_phase_keys` and
`schedule_report_actor_stage_keys`.

For each `verification_observations` entry, `name` is the authored
observation name, `role` is the selected passive role, `clock` is the actor
default-domain clock, `reset` is the same reset summary shape used by the
top-level report, and `signals` is the source-ordered public actor interface
signal list. Each signal entry reports `name`, `direction`, and resolved
scalar `width`. Observation metadata is informational report metadata only; it
does not add scheduler, generated `.fsm`, generated-top, HDL, VHDL,
scoreboard, coverage, or VIP runtime behavior, and schedule-report consumers
must not infer generated artifacts from it. The explicit verification-output
mode `--emit-verification-output uvm-passive-monitor --verification-outdir DIR`
consumes this metadata to emit an inert UVM passive-monitor skeleton plus
`verification-output-manifest.json`; it is not part of the schedule-report
schema and does not claim UVM compile support. The sibling
`--emit-verification-output vhdl-observation-package --verification-outdir DIR`
mode consumes the same metadata to emit an inert VHDL observation metadata
package plus the same manifest; it does not imply VHDL compile, VHDL syntax,
PSL, testbench, monitor process, scoreboard, coverage, reusable VIP, or direct
IAL2 behavior. The
machine-readable schedule-report contract advertises these metadata keys
through
`schedule_report_verification_observation_keys`,
`schedule_report_verification_observation_signal_keys`, and
`schedule_report_verification_observation_role_values`; the only shipped role
value is `passive_monitor`.

For each `transaction_waits` entry, `transaction` is the authored transaction
name, `cycles` is the exact positive resolved static wait count or JSON null
for runtime waits, `count_kind` is `static`, `runtime_scalar`, or
`runtime_expression`, `count_source` is the literal, actor constant name,
actor parameter name, transaction parameter name, qualified package constant
token, runtime scalar source signal, or normalized runtime expression text,
`entry_state` is the generated wait state, and `exit_state` is the following
scheduled state after the wait. For consecutive runtime waits, that following
scheduled state can be the next generated wait entry; the generated edge split
may still bypass farther when the next runtime count is zero. Static waits
report `counter_signal` and `counter_width` as JSON null. Runtime waits report
the generated sampled counter name and width through those fields. `(wait 0)`
and symbolic waits that resolve to zero are no-ops and do not create report
entries. Actor-local constants used by symbolic waits are reported separately
through `actor_constants[]`. The machine-readable contract advertises these
through `schedule_report_transaction_wait_keys` and the count-kind value list
through `schedule_report_transaction_wait_count_kind_values`.

For each `transaction_loops` entry, `transaction` is the authored transaction
name, `kind` is `while` or `until`, `condition` is the normalized guard text
used in the scheduled `.fsm`, `entry_state` names the first state associated
with the loop, `decision_states` lists generated condition-sampling states,
`body_start` names the first body state, `body_states` lists generated body
states, `exit_state` names the state reached after the loop, and
`body_clause_count` is the authored body clause count. The machine-readable
contract advertises these through `schedule_report_transaction_loop_keys`.

For each `transaction_stages` entry, `kind` is currently
`ready_valid_barrier`. The entry preserves the authored transaction/stage
names and reports the generated stage state plus the ready input and valid
output. The machine-readable contract advertises these through
`schedule_report_transaction_stage_keys` and
`schedule_report_transaction_stage_kind_values`.

For each `temporal_contracts` entry, `kind` is currently
`bounded_eventually`, `overlap_policy` is currently `fail`, and
`assertion_projection` is currently `systemverilog_sticky_fail`. The entry
reports the generated trigger state, observed signal, positive cycle bound,
generated pending, counter, and fail signal names, and reset policy.
`reset_policy` uses the same bounded shape as the top-level reset summary when
reset is configured or defaulted and is null only when the selected
default-domain reset is omitted. For
SystemVerilog-family generation, FSMGen projects the generated sticky fail bit
into a verification-only assertion under `` `ifndef SYNTHESIS``; Verilog
output remains assertion-free. The machine-readable contract advertises these
through `schedule_report_temporal_contract_keys`,
`schedule_report_temporal_contract_kind_values`,
`schedule_report_temporal_contract_overlap_policy_values`,
`schedule_report_temporal_contract_assertion_projection_values`, and
`schedule_report_temporal_contract_reset_policy_shape`.
Raw monitor equations, internal arm request names, and backend assertion text
are not part of the public temporal-contract report entry.

For the `reset` summary, `kind` is currently `async` or `sync`, and `polarity`
is currently `active_high` or `active_low`. The machine-readable contract
advertises those value families through `schedule_report_reset_kind_values` and
`schedule_report_reset_polarity_values`.
When reset is configured or defaulted for a legacy single-clock actor, `reset`
is a hash reference with `schedule_report_reset_keys`. When the selected
default clock-domain reset is omitted, `reset` is null. The machine-readable
contract advertises this through `schedule_report_reset_shape`.

The top-level `inputs` and `outputs` values are non-negative integer counts.
Single-clock reports count interface ports by direction. Multi-domain reports
count generated-top public ports, including domain clocks/resets and actor
interface ports. `port_count` equals their sum. The top-level `state_count`
value is a non-negative integer count of scheduled `.fsm` state blocks in the
current report scope; multi-domain generated-top reports use zero and expose
domain-local counts in `clock_domains[]`. The machine-readable contract
advertises this through `schedule_report_interface_count_shape` and
`schedule_report_state_count_shape`.

The top-level `schema_version` value is integer `1` for the current
schedule-report payload shape and is separate from the
`embedding.isf_public_interface` contract metadata `schema_version`.
The top-level `source` value is an actor-derived `.isf` basename, and
`scheduled_fsm` is the scheduled `.fsm` basename for the current report scope.
Multi-domain reports use the generated `<actor>_top.fsm` artifact. `clock` is
the scalar clock signal name from the actor declaration, `clk` for omitted
legacy single-clock actor clocks, or the selected default-domain clock when
`clock_domains` is present. `watchdog` is a scalar resolved limit, with omitted
watchdog clauses normalized to `65535` and actor-constant, actor-parameter, or
qualified package-scalar-constant actor watchdogs reported as the resolved
integer. The machine-readable contract
advertises these through
`schedule_report_source_shape`, `schedule_report_scheduled_fsm_shape`,
`schedule_report_clock_shape`, and `schedule_report_watchdog_shape`.

The current lowerer emits DT summaries in deterministic lowering order:
transaction/rule-created DTs retain their construction order, generated
rule-trigger fan-in DTs follow rule DTs by transaction name, and hash-backed
drive DTs are emitted lexically by drive name. This is a bounded
review-artifact and schedule-report stability promise, not a promise that raw
`LoweringIR` hashes are public. The machine-readable contract advertises the
same policy in `scheduled_fsm_dt_ordering` and `schedule_report_dt_ordering`.
Those ordering fields are exact shared-policy metadata for the current
scheduled `.fsm` review artifact and schedule report.

For single-clock multi-file lowerings, the current schedule report describes
the parent scheduled module only. Child scheduled `.fsm` text remains
available through the lower-result `files` map. For multi-domain lowerings,
the current schedule report describes the generated top at the top level and
projects domain-local artifact metadata through `clock_domains[]` plus
crossing metadata through `crossings[]`. The machine-readable contract
advertises this current scope in `schedule_report_multi_file_scope`.
For successful schedule reports, `compile_issues` is present as an array. It is
empty when the successful report has no nonfatal compile issues. The
machine-readable contract advertises that no-issue success shape in
`schedule_report_compile_issues_success_shape`.
Nonfatal conflict issue entries in `compile_issues` are bounded to stable
`code`, `severity`, `target`, `domain`, `proof_status`, diagnostic `reason`,
and capped `sources` summaries. The machine-readable contract advertises the
bounded issue keys in `schedule_report_compile_issue_keys`, source-summary keys
in `schedule_report_compile_issue_source_keys`, current severity values in
`schedule_report_compile_issue_severity_values`, and current proof-status
values in `schedule_report_compile_issue_proof_status_values`.
The current proof-status value that matters for nonfatal conflict reporting is
`not_doable`: it means the lowerer is explicitly flagging that compile-time
proof is NOT doable for that case, instead of silently treating the design as
conflict-free. Fail-closed conflict cases remain targeted diagnostics, not
successful schedule-report entries.
Those rejected diagnostics name the stable code, target, reason, conflicting
owners, source kinds, operators, and values. The CLI `--emit-schedule-json`
path does not emit successful JSON for those rejected conflicts.
Accepted fan-in metadata uses a top-level
`compatible_fanin_groups` array with bounded `kind`, `domain`, target/value
facts, and the same capped source summaries. The machine-readable contract
advertises required group keys in `schedule_report_fanin_group_required_keys`,
optional group keys in `schedule_report_fanin_group_optional_keys`, and current
group kinds in `schedule_report_fanin_group_kind_values`.
The public fan-in projection is narrower than internal classification: request
and pulse fan-in are reported through `request` and `pulse` groups rather than
duplicated as generic `same_target_value` groups.
Transaction port binding provenance uses a top-level
`transaction_port_bindings` array. Each entry is bounded to the advertised key
set and records the binding site kind (`do`, `spawn`, or `rule_trigger`),
owner, target transaction, port role/name, actor signal when the actor side is
a scalar endpoint, formatted actor expression, `actor_endpoint_kind`,
`binding_timing`, `authored_timing_mode`, width, and generated handoff signal
names where applicable.
Parameterized
rule-trigger entries use the generated trigger instance handoff names and
preserve the per-rule trigger and payload source names; generated-child
rule-trigger output entries also report the done-observer signal that guards
the output copy in `done_signal`. Within one rule, multiple generated-child
rule-trigger output bindings may not target the same actor signal because no
rule-local output selection policy is shipped. For expression-valued or
literal input bindings, `actor_signal` is JSON null and
`actor_expression` carries the formatted source expression.
`actor_endpoint_kind` is `signal`, `literal`, or `expression`.
`binding_timing` is `activation_region`, `generated_live_handoff`,
`trigger_payload`, or `done_guarded`. JSON null is used for non-applicable
handoff fields. `authored_timing_mode` is `snapshot` or `live` when the source
binding includes an explicit timing clause, and JSON null otherwise. The
machine-readable contract advertises the entry key set in
`schedule_report_transaction_port_binding_keys`, the endpoint-kind value
family in
`schedule_report_transaction_port_binding_actor_endpoint_kind_values`, the
timing value family in
`schedule_report_transaction_port_binding_timing_values`, the authored timing
mode value family in
`schedule_report_transaction_port_binding_authored_timing_mode_values`, and
the current site-kind values in
`schedule_report_transaction_port_binding_site_kind_values`.
Successful arbitration metadata uses top-level `priority_resolutions` and
`resource_arbitration` arrays. `priority_resolutions` records static
target-local suppressions with bounded winner/loser owner names and owner
kinds. `resource_arbitration` records bounded resource grant-shaping decisions
for enforced resources, including the resource name, resource kind, arbiter,
rule user, explicit member list, and users that can suppress that user's
grant. For `priority`, `suppressed_by` names higher-priority bound rule users.
For bounded `round_robin`, `suppressed_by` names dynamic peer rule users that
can block that grant for a given pointer position and request set. `members`
is an array; it is empty when the resource has no explicit member list and
contains declared actor output or concrete actor-owned storage signal names
for explicit output-bundle members. These entries describe the lowering
decision, not per-cycle runtime grant values.
Raw `assignment_provenance`, activation context, assignment indexes, and
priority/resource suppression bookkeeping remain non-public `LoweringIR`
internals unless a later slice deliberately advertises a narrower field.

Multi-domain schedule reports add two bounded top-level arrays.
`clock_domains[]` is empty for legacy one-clock actors. For accepted
`(clock-domains ...)` actors, each entry records the declared domain name,
default marker, clock/reset summary, scheduled domain artifact basename, local
port/storage/transaction/rule/library/child-instance names, local crossing
endpoints, and bounded domain report counts. Multi-domain reports describe the
generated top as the top-level report scope, so top-level `state_count` is
zero and domain-local scheduled state counts live in `clock_domains[]`.
`crossings[]` is empty when no crossing primitive is declared. For accepted
event crossings, each entry records the source domain/signal, destination
domain/pulse signal, ready signal, generated CDC instance/module names,
single-outstanding acknowledgement policy, no-payload policy, and generated
top basename. Plain SystemVerilog/Verilog-family HDL generation for accepted
event-crossing actors emits the generated top and concrete acknowledged-event
CDC child modules.
When a crossing's source or destination domain omits reset ownership, generated
CDC interface metadata marks the corresponding reset as absent. Schedule
reports and `--emit-schedule-json` preserve that no-reset crossing metadata,
and plain HDL generation omits the absent reset ports from both the domain
modules and generated CDC child.

The schedule report is not yet a frozen full schema. Downstream consumers should
use the advertised contract metadata instead of assuming every current field,
generated state name, or private lowering decision is permanent.
The advertised schedule-report metadata fields are exact for the bounded public
key families and policy strings they name.

### Schedule-Report Freeze Readiness

`schedule_report_full_schema_stable` is currently true. Schedule JSON payload
schema version `1` is a public, stable schema under the evolution rules below.
Raw parser actor hashes and `LoweringIR` objects remain non-public.

Contractual now:

- The in-process `report(...)` path and `--emit-schedule-json` CLI path emit
  the same successful schedule report for accepted sources.
- `schedule_report_top_level_keys` and the advertised nested key/value
  families define the stable schema-version-1 public shape.
- Scalar count, reset/nullability, transaction ordering, DT ordering, storage
  kind/role/width, and feature-owned summary arrays are public to the extent
  described by their advertised metadata fields.

Stable, versioned evolution:

- New optional keys or value-family members may be added when the same slice
  updates this contract, the mdBook/spec, and focused regressions.
- `inferred_storage[].role`, `compile_issues[]`,
  `compatible_fanin_groups[]`, `priority_resolutions[]`,
  `resource_arbitration[]`, `actor_constants[]`, `actor_phases[]`,
  `actor_stages[]`, `verification_observations[]`, `actor_params[]`,
  `transaction_waits[]`,
  `transaction_stages[]`, `transaction_loops[]`, `loop_early_exits[]`,
  `temporal_contracts[]`, `transaction_port_bindings[]`, `actor_network`,
  `library_uses[]`, and `generated_composition` are bounded summaries, not raw
  IR exports.
- Raw assignment provenance, private assignment indexes, and activation proof
  internals remain private. Public substitutes are the bounded summary arrays
  advertised above plus aggregate fields such as `dt_blocks[].assignments`,
  which is a count rather than a serialized assignment list.
- Parent schedule reports do not recursively embed child schedule reports.
  Multi-file public detail is bounded to `actor_network`,
  `generated_composition`, `library_uses[]`, `clock_domains[]` /
  `crossings[]`, and the public `lower(...)` files map.

- Breaking schedule-report changes require a `schema_version` bump plus
  migration or deprecation documentation. The executable golden matrix in
  [t/1255-isf-schedule-report-golden-matrix.t](../../t/1255-isf-schedule-report-golden-matrix.t)
  assigns every advertised `schedule_report_*` branch to at least one
  in-process/CLI parity case.

## Non-Public Internals

These are not stable public interfaces yet:

- The raw actor hash returned by the parser as a whole.
- Actor fields beyond the advertised `actor_shell_required_keys`.
- Raw library resolver state and raw exported library actor hashes.
- Transaction port behavior beyond parser-shell `ports.inputs[]` /
  `ports.outputs[]` `name`/`width` metadata, scalar/literal/list-expression
  input-binding lowering for `do`, `spawn`, and rule-trigger activation sites,
  explicit current-timing `(timing snapshot|live)` assertions on input
  bindings, generated-child rule-trigger scalar output bindings, plus the
  first conflict/runtime coverage for binding-generated assignments, bounded
  `binding_timing` report metadata, and `authored_timing_mode` report
  metadata. Direct/local rule-trigger output bindings, behavior-changing
  snapshot-vs-live timing conversion, broader static conflict diagnostics,
  additional future report expansions beyond the bounded
  `transaction_port_bindings[]` summary fields listed above, and full
  expression width inference remain deferred follow-on port-binding work.
- Transaction control-flow behavior beyond shipped static/symbolic actor
  constant, actor parameter, same-transaction scalar parameter, qualified
  package scalar constant, runtime scalar, and runtime expression `(wait N)`,
  sample-compatible runtime wait pending
  samples, and top-level transaction `(while cond body...)` /
  `(until cond body...)` remains non-public except for the documented
  top-level repeat-body local `(do child)` subset, top-level repeat-body
  generated-child `(do child)` subset, top-level repeat-body generated
  `(do child (params ...) [(bind ...)] [(domain NAME)])` subset, repeat-body
  samples before or after shipped do states, and top-level
  repeat-body spawn
  plus optional static `(params ...)`, optional `(bind ...)` port handoffs,
  optional declared same-domain `(domain NAME)` metadata, same-body
  `await_all`, single-pending same-body `await_any`, and multi-pending
  same-body `await_any` followed by same-body `await_all` drain subset.
  Top-level when-body and switch-branch nested repeat generated spawns also
  support same-body `await_all`, single-pending same-body `await_any` when
  exactly one generated child is pending, or multi-pending same-body
  `await_any` followed by a mandatory same-body `await_all` drain. Top-level
  when-body and switch-branch nested repeats also support local `(do child)`
  while generated nested spawns are pending before or after a prior
  multi-pending `await_any` observation and before a later same-body
  `await_all` drain. When no multi-pending `await_any` observation is active,
  both top-level branch subsets also support local `(do child)` followed by
  additional generated nested `spawn` sites before that same later
  `await_all` drain. Both top-level branch subsets
  support plain generated-child `(do child)` while generated nested spawns are
  pending before or after a prior multi-pending `await_any` observation and
  before that same later drain. When no multi-pending `await_any` observation
  is active, both top-level branch subsets also support plain generated-child
  `(do child)` followed by additional generated nested `spawn` sites before
  that same later drain. Both top-level branch subsets support
  static-parameter generated
  `(do child (params ...))` while generated nested spawns are pending before
  that same later drain, and both top-level branch-contained subsets also
  support that static-parameter generated do after a prior multi-pending
  `await_any` observation. Both
  top-level branch subsets additionally support static-parameter generated
  `(do child (params ...) (bind ...))` while generated nested spawns are
  pending before that same later drain.
  Generated child activation overrides for wait-count transaction parameters
  are accepted only when they resolve to the same non-negative integer as the
  child default; mismatches fail closed until per-activation wait-state
  specialization is shipped.
  Unsupported non-scalar or cross-transaction parameter wait counts,
  non-scalar actor parameter wait counts, unqualified or aggregate package constants, package member/item
  paths, package constants inside wait-count expressions,
  sample-incompatible runtime wait successors, nested loops, and loop bodies
  containing broader child activation, stages, or contracts need parser,
  lowering, report, and regression-backed contracts before downstream users
  can rely on them.
- `FSM::Scheduler::ISF::LoweringIR` internals.
- Emitter-private state objects.
- Any unadvertised keys in the lower-result hash or schedule report.

## Evolution Rule

This contract evolves with R14 implementation work.

When an ISF or PPIF slice changes a downstream-visible behavior, update
together:

- [docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](../ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [docs/ISF_SPEC.md](../ISF_SPEC.md)
- [docs/DOWNSTREAM_ISSUE_REPORTING.md](../DOWNSTREAM_ISSUE_REPORTING.md) when the
  change affects downstream issue reproduction guidance
- [docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](../ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
- [docs/book/src/13-intent-scheduling.md](../book/src/13-intent-scheduling.md)
- [docs/book/src/13k-isf-feature-support-matrix.md](../book/src/13k-isf-feature-support-matrix.md)
- [docs/book/src/11-extensions-and-embedding.md](../book/src/11-extensions-and-embedding.md)
  when the manifest/file-surface boundary changes
- [perl/FSM/Support/ISFPublicInterfaceContract.pm](../../perl/FSM/Support/ISFPublicInterfaceContract.pm)
- [perl/FSM/Support/LanguageSurfaceSection.pm](../../perl/FSM/Support/LanguageSurfaceSection.pm)
  when `language_surface.file_surfaces` changes
- support-accounting catalog/docs and focused tests when supported source
  coverage changes
- focused regression tests for the changed public surface

The goal is not to freeze ISF prematurely. The goal is to make every public
promise explicit, discoverable, and regression-backed as the ISF compiler grows.
