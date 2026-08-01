
## 10. Schedule JSON Report

`--emit-schedule-json` emits the current `Emitter::JSON` surface:

```json
{
  "schema_version": 1,
  "source": "actor_name.isf",
  "scheduled_fsm": "actor_name.fsm",
  "clock": "clk",
  "reset": {
    "name": "rst_n",
    "kind": "async",
    "polarity": "active_low"
  },
  "watchdog": "65535",
  "actor_phases": [],
  "actor_stages": [],
  "actor_params": [],
  "actor_constants": [],
  "port_count": 0,
  "inputs": 0,
  "outputs": 0,
  "state_count": 0,
  "inferred_storage": [],
  "transactions": [],
  "transaction_waits": [],
  "transaction_loops": [],
  "loop_early_exits": [],
  "transaction_stages": [],
  "temporal_contracts": [],
  "bank_accesses": [],
  "transaction_port_bindings": [],
  "dt_blocks": [],
  "actor_network": null,
  "generated_composition": null,
  "library_uses": [],
  "compatible_fanin_groups": [],
  "priority_resolutions": [],
  "resource_arbitration": [],
  "compile_issues": [],
  "clock_domains": [],
  "crossings": []
}
```

This is a machine-readable schedule report generated from the same lowering IR
as `.fsm` output. It now has a bounded public key-family contract through
`embedding.isf_public_interface`, but it is not a frozen full schema. Current
reports carry `schema_version: 1`; that value versions the schedule-report
payload separately from the `embedding.isf_public_interface` contract metadata.
scalar source values such as `watchdog` are preserved as parser-carried strings
in the JSON report. Assigned scheduler counters using the generated `*_wd`,
`*_cc`, and `*_cnt` naming families are reported as `kind: counter` with the
width inferred by `LoweringIR`. Transaction summaries include the generated
state families used by the current scheduler, including control-flow and
data-operation states. DT block summaries follow deterministic lowering order:
transaction/rule-created DTs first in construction order, generated
rule-trigger fan-in DTs by transaction name, then hash-backed drive DTs
lexically by drive name.

The capability-manifest ISF public contract exposes the same policy through
`scheduled_fsm_dt_ordering` and `schedule_report_dt_ordering`.
Those ordering fields are audited as exact paired metadata across direct and
manifest views.
Generated names in schedule reports and generated artifacts are deterministic
for the same source and FSMGen version, and report fields may reference those
names for joins inside the same emitted report or artifact set. They are not a
semantic string grammar for downstream tools to parse. Consumers should prefer
explicit bounded metadata such as `owner`, `owner_kind`, `role`, `kind`,
`instance`, `parent_port`, `child_port`, `trigger_source`, `payload_source`,
storage `role`, and generated-composition summaries. Before the whole schedule
JSON schema is frozen, generated spelling may change in a future
feature-scoped slice, but any such downstream-visible change must update the
public docs, contract metadata where applicable, and tests in the same slice.
Schedule-report evolution is additive by default only for new top-level keys,
new nested optional keys, or new value-family members that are advertised in
the public contract metadata and covered by focused tests and docs in the same
slice. Removing an advertised key, renaming a key, changing a required key to
optional or vice versa, changing a value type, or changing an advertised value's
meaning is breaking and requires a `schema_version` bump plus migration or
deprecation documentation in the same slice. Deprecated fields must remain
documented until the schema version that removes them.
The `actor_constants` array reports actor-level ISF constants in source order.
Each entry contains `name` and stringified `value`. The values are
compile-time constants; they are not runtime ports, not overrideable params,
and not hidden scheduler registers.
The `actor_params` array reports actor-level parameter defaults in source
order. Each entry contains `name` and JSON-safe default `value`; scalar enum
member defaults, actor-constant-backed scalar defaults, and enum or actor
constant leaves inside aggregate/list defaults preserve the authored tokens.
Parameter defaults are static specialization values, not runtime ports;
actor-constant-backed defaults also carry resolved literals internally for
scalar parameter consumers. Activation-site, generated-child,
and reusable-library override bindings remain reported by their existing
generated-composition and library-use summary families. The capability-manifest
ISF public contract advertises this shape through
`schedule_report_actor_param_keys`.
Each `dt_blocks` entry's `assignments` value is a non-negative count of
assignment forms in the matching scheduled `.fsm` DT block, not an assignment
payload list. The capability-manifest ISF public contract advertises this shape
through `schedule_report_dt_assignments_shape`.
Each `dt_blocks` entry's `kind` value is currently `drive`,
`latency_counter`, `rule`, `rule_trigger_fanin`, or
`temporal_contract_monitor`. The capability-manifest ISF public contract
advertises this value family through `schedule_report_dt_kind_values`.
`actor_network` is null for actors without a static ATL actor declaration, or
an object with `kind`, `instances`, `event_waits`, `transaction_triggers`,
`association_schedules`, `group_schedules`, `data_movements`, and
`generated_tops` for the current bounded static actor-network subset.
Unqualified instance entries contain `name`, `actor_type`, and `declaration`.
Resolved library-qualified instance entries also contain `type_resolution`,
`library`, `alias`, `export`, `module`, and `scheduled_fsm`.
Each event-wait entry contains `transaction`, `context`, `instance`, `event`,
`signal`, and `source`. Each transaction-trigger entry contains
`owner_transaction`, `context`, `instance`, `target_transaction`, `signal`,
and `sink`. Each scalar data-movement entry contains `kind`, `transaction`,
`context`, `drive`, source/sink instance, endpoint, generated signal,
`width`, `width_source`, `route_lifetime`, `storage`, `source`, and `sink`.
Each association-schedule entry contains `association`, `kind`, `lifetime`,
`owner_transaction`, `context`, `members`, `target_transactions`, `signals`,
`schedule`, `dependency_policy`, `storage`, `source`, and `sink`.
Each generated-top entry contains `kind`, `top_module`, `top_fsm`,
`parent_module`, `parent_scheduled_fsm`, `instance`, `child_module`,
`child_scheduled_fsm`, `target_transaction`, `trigger_parent_port`,
`trigger_child_port`, `event`, `event_parent_port`, `event_child_port`,
`clock`, and `reset`.
The capability-manifest ISF public contract advertises these families through
`schedule_report_actor_network_keys`,
`schedule_report_actor_network_instance_keys`,
`schedule_report_actor_network_resolved_instance_keys`,
`schedule_report_actor_network_group_keys`,
`schedule_report_actor_network_generated_top_keys`,
`schedule_report_actor_network_association_schedule_keys`,
`schedule_report_actor_network_group_schedule_keys`,
`schedule_report_actor_network_data_movement_keys`,
`schedule_report_actor_network_event_wait_keys`, and
`schedule_report_actor_network_transaction_trigger_keys`.
Each `inferred_storage` entry's `kind` value is currently `counter` or
`register`. Optional `role` values describe stable scheduler purpose when the
lowerer has direct evidence: `activation_done_handoff`,
`activation_start_handoff`, `actor_storage`, `atl_trigger_start_handoff`,
`completion_pulse`, `data_register`, `dynamic_wait_counter`,
`drive_payload`, `drive_request`, `extract_field`, `latency_counter`,
`repeat_counter`,
`resource_round_robin_pointer`, `rule_trigger_payload_source`,
`rule_trigger_source`, `sample_alias`, `scheduler_error_status`,
`temporal_contract_monitor`, `transaction_port`, `transaction_port_binding`,
`trigger_done_observe`, and `watchdog_counter`.
Runtime scalar and runtime expression waits use `dynamic_wait_counter` for the
generated sampled-count storage that backs zero-bypass and decrement-loop
lowering.
Rule-trigger source pulses use `rule_trigger_source`; per-input trigger
payload-source storage uses `rule_trigger_payload_source` before fan-in or
generated activation handoff storage consumes the payload.
Generated activation start/done handoff storage uses
`activation_start_handoff` and `activation_done_handoff` when those one-bit
generated handoff signals appear in `inferred_storage[]`.
Generated activation port-binding handoff storage uses
`transaction_port_binding`; generated rule-trigger completion observation uses
`trigger_done_observe`.
Static actor-network `(trigger INSTANCE.TRANSACTION)` and trigger-batch
lowering use `atl_trigger_start_handoff` for the generated one-cycle parent
start pulses. Await watchdog and latency-maximum timeout terminal states use
`scheduler_error_status` for the global `last_error` latch they write on
timeout.
Transaction-local port storage uses `transaction_port` when a declared
transaction port is materialized in the scheduled `.fsm` review artifact.
Bounded `round_robin` resource arbitration for `rule_slot`, `output_bundle`,
`transaction_start`, or `storage_port` uses `resource_round_robin_pointer`
for the generated pointer counter.
Typed actor-owned storage may additionally report the authored alias in
`type` and the resolved top-level kind in `type_kind`; this is intentionally a
bounded summary, not a raw type-spec dump.
Temporal-contract monitor storage uses that one role for the generated
pending and sticky-fail registers plus the generated age counter; the
`temporal_contracts[]` entry remains the public summary that names each signal
and its specific contract purpose.
Optional `width` values are positive integer bit widths when present and
currently appear on declared actor-owned storage, inferred scheduler counters,
and register storage with known ISF width evidence.
The capability-manifest ISF public contract advertises this through
`schedule_report_storage_kind_values`, `schedule_report_storage_role_values`,
and `schedule_report_storage_width_shape`.
Each `transactions` entry's `states` value is an emitted-order array of
scheduled state names belonging to that transaction, and `count` is a
non-negative integer equal to that array length. The capability-manifest ISF
public contract advertises this through
`schedule_report_transaction_states_shape` and
`schedule_report_transaction_count_shape`.
The `transactions` array is sorted lexically by transaction name, and each
transaction's `states` array keeps scheduled `.fsm` state emission order. The
capability-manifest ISF public contract advertises this through
`schedule_report_transaction_ordering`.
The `transaction_waits` array reports the shipped literal `(wait N)` surface,
actor-constant `(wait NAME)` surface, actor-parameter `(wait NAME)` surface,
same-transaction-parameter `(wait NAME)` surface,
package-constant `(wait PACKAGE.CONSTANT)` surface,
bounded runtime scalar `(wait count_signal)` surface, and bounded runtime
expression `(wait (<op> ...))` surface, including accepted top-level, `when`
body, `repeat` body, `switch` branch, `while` body, and `until` body contexts.
Positive static waits report the authored transaction name, exact resolved
cycle count, count kind/source, entry wait state, exit state after the wait
chain, and null counter metadata. Runtime waits report the authored
transaction name, null `cycles`, `runtime_scalar` or `runtime_expression`
count kind, source signal or normalized expression text, entry/exit states,
and generated counter name/width. `(wait 0)` and symbolic waits that resolve
to zero are transparent no-ops and create no entry. The capability-manifest
ISF public contract advertises the keys through
`schedule_report_transaction_wait_keys` and the count-kind values through
`schedule_report_transaction_wait_count_kind_values`.
The `transaction_loops` array reports the shipped top-level `while`/`until`
loop subset. Each entry contains the authored transaction name, loop `kind`,
normalized `condition`, loop entry state, generated decision states, body
start, generated body states, exit state, and authored body-clause count. The
capability-manifest ISF public contract advertises the keys through
`schedule_report_transaction_loop_keys`.
The `loop_early_exits` array reports each `(exit-when COND)` and
`(continue-when COND)` mid-loop site inside a shipped `while`/`until` body.
Each entry contains the authored `transaction`, the `kind` (`exit_when` or
`continue_when`), the generated decision `state`, the normalized `condition`,
and the true-edge `target` (the loop exit for `exit_when`, the loop tail check
for `continue_when`).
The `actor_phases` and `actor_stages` arrays report parser-validated
actor-level metadata without assigning runtime semantics to it. Each entry has
the authored metadata `name` and a JSON-safe copy of the list-form `body`. The
capability-manifest ISF public contract advertises those keys through
`schedule_report_actor_phase_keys` and
`schedule_report_actor_stage_keys`.
The `verification_observations` array reports parser-validated actor-level
passive observation metadata without assigning runtime semantics to it. Each
entry has the authored observation `name`, `role`, inherited `clock`, `reset`,
and source-ordered `signals`; each signal entry has `name`, `direction`, and
resolved scalar `width`. The only shipped role value is `passive_monitor`.
Actors without observation metadata report an empty array. The
capability-manifest ISF public contract advertises these fields and role
values through `schedule_report_verification_observation_keys`,
`schedule_report_verification_observation_signal_keys`, and
`schedule_report_verification_observation_role_values`.
The `transaction_stages` array reports the shipped ready/valid stage subset.
Each entry has `transaction`, authored stage `name`, `kind =
ready_valid_barrier`, generated `state`, `ready` input, and `valid` output.
The capability-manifest ISF public contract advertises the keys and kind
values through `schedule_report_transaction_stage_keys` and
`schedule_report_transaction_stage_kind_values`.
The `temporal_contracts` array reports the shipped bounded eventual contract
subset. Each entry has `transaction`, authored contract `name`, `kind =
bounded_eventually`, `trigger`, observed `signal`, `within_cycles`,
`pending_signal`, `counter_signal`, `fail_signal`, `overlap_policy`,
`reset_policy`, and `assertion_projection`. The current `overlap_policy` is
`fail`, and the current assertion projection value is
`systemverilog_sticky_fail`; monitor logic exists in scheduled `.fsm`, and
SystemVerilog generation projects the sticky fail bit into verification-only
assertion text. The
capability-manifest ISF public contract advertises the keys, kind values,
overlap values, assertion-projection values, and reset-policy shape through the
matching `schedule_report_temporal_contract_*` metadata fields.
When a contract window is authored with a positive actor constant, actor
scalar parameter, or qualified imported package scalar constant,
`within_cycles` reports the resolved positive integer and no separate
source-token field is public. The actor-local declaration remains visible
through `actor_constants[]` or `actor_params[]`; imported package constants
remain visible through package/import metadata and embedded package
`+constants` entries.
Latency bounds do not have a dedicated public schedule-report entry. When a
positive actor constant, actor scalar parameter, or qualified imported package
scalar constant names `(latency (min ...))` or `(latency (max ...))`, the
report-visible effect is the same as the equivalent literal bound: the
latency counter storage appears in `inferred_storage[]`/`dt_blocks[]` with
its resolved width and storage role, while `actor_constants[]`,
`actor_params[]`, and embedded package/import metadata still report the
authored declarations.
The reset summary's `kind` value is currently `async` or `sync`, and its
`polarity` value is currently `active_high` or `active_low`. The
capability-manifest ISF public contract advertises those value families through
`schedule_report_reset_kind_values` and
`schedule_report_reset_polarity_values`.
Configured and defaulted legacy single-clock reset summaries are hashes with
the advertised reset keys. Reset is JSON null only when the selected
default-domain reset is omitted in a `(clock-domains ...)` actor. The
capability-manifest ISF public contract advertises this through
`schedule_report_reset_shape`.
The `clock_domains` array is empty for legacy one-clock actors. For accepted
`(clock-domains ...)` actors, each entry exposes the domain name, default
marker, clock/reset summary, scheduled domain artifact basename, local
port/storage/transaction/rule/library/child-instance names, crossing endpoint
summaries, and bounded domain state/DT counts. For multi-domain reports, the
top-level report scope is the generated top, so top-level `state_count` is
zero and domain-local counts live in `clock_domains[]`. The `crossings` array
is empty when no crossing primitive is declared. Accepted event crossings
report source/destination domains and signals, the source ready signal,
generated CDC instance/module names, `single_outstanding_acknowledged`
policy, `none` payload policy, and generated top basename. The
capability-manifest ISF public contract advertises these bounded key families
through `schedule_report_clock_domain_*` and `schedule_report_crossing_keys`.
For ordinary single-clock reports, the top-level `inputs` and `outputs`
values count interface ports by direction, and `port_count` equals their sum.
For multi-domain reports, these counts describe the generated top's public
port scope, including domain clocks/resets plus actor interface ports.
`state_count` counts scheduled `.fsm` state blocks in the current report scope;
multi-domain generated tops have no hidden scheduled states, so their
top-level `state_count` is zero. The capability-manifest ISF public contract
advertises this through `schedule_report_interface_count_shape` and
`schedule_report_state_count_shape`.
The top-level `source` and `scheduled_fsm` values are actor-derived `.isf` and
`.fsm` basenames for the current report scope; for multi-domain reports,
`scheduled_fsm` is the generated `<actor>_top.fsm` artifact. `clock` is the
actor clock signal name, or `clk` when a legacy single-clock actor omits
`(clock ...)`; with `clock-domains`, it is the selected default-domain clock.
`watchdog` is always a scalar resolved limit after parser defaults, with
omitted `(watchdog ...)` normalized to `65535` and actor-constant, actor
scalar parameter, or qualified imported package scalar constant watchdogs
reported as the resolved integer. The capability-manifest ISF public contract
advertises this through
`schedule_report_source_shape`,
`schedule_report_scheduled_fsm_shape`, `schedule_report_clock_shape`, and
`schedule_report_watchdog_shape`.
Successful reports keep `compile_issues` present as an array. Reports with no
nonfatal compile issues keep it empty; the capability-manifest ISF public
contract advertises that no-issue success shape through
`schedule_report_compile_issues_success_shape`.
Nonfatal conflict issues are projected into `compile_issues` as bounded objects
with stable `code`, `severity`, `target`, `domain`, `proof_status`,
human-readable `reason`, and capped `sources` summaries. The important current
proof status is `not_doable`, used when the scheduler is explicitly flagging
that a compile-time proof is NOT doable. For rule/drive overlap this applies
when a drive is shared, generated, mixed-source, or unused and no declared
priority requires a unique logical transaction owner. An
exactly-one-local-caller drive instead participates in ordinary
rule/transaction priority resolution or fail-closed conflict diagnostics.
The public contract advertises the bounded issue keys, source-summary keys,
severity values, and proof-status values. Fail-closed conflicts still produce
targeted diagnostics instead of successful schedule reports.
Rejected conflict diagnostics are regression-covered for both in-process
scheduler calls and the CLI schedule-report path. They name the stable code,
target, reason, conflicting owners, source kinds, operators, and values, and
the CLI path does not emit successful schedule JSON for rejected conflicts.
Accepted compatible fan-in metadata is emitted as a top-level
`compatible_fanin_groups` array. Each group is bounded to classifier `kind`,
`domain`, target/value facts, and source summaries; raw
`assignment_provenance`, activation proof context, assignment indexes, and
priority-suppression bookkeeping remain private `LoweringIR` internals.
The public projection reports request and pulse fan-in through their
domain-specific group kinds instead of duplicating them as generic
`same_target_value` groups.
Transaction port binding provenance is emitted as a top-level
`transaction_port_bindings` array. Each entry records the binding site
(`do`, `spawn`, or `rule_trigger`), owner, target transaction, direction role,
transaction port, actor signal when the actor side is a scalar endpoint,
formatted actor expression, `actor_endpoint_kind`, `binding_timing`, width,
`authored_timing_mode`, and the bounded generated signal names that make the
scheduled `.fsm` handoff reviewable.
For generated-child rule-trigger output bindings, `done_signal` names the
per-trigger done-observer signal that guards the copy back into the actor.
`actor_endpoint_kind` is `signal` for scalar actor-side endpoints, `literal`
for numeric or exact-width input operands, and `expression` for non-empty
list-expression input operands. For expression-valued or literal input
bindings, `actor_signal` is JSON null and `actor_expression` carries the
formatted source expression. `binding_timing` is `activation_region` for
same activation-region copies, `generated_live_handoff` for generated-top
handoff wiring, `trigger_payload` for rule-trigger input payload
capture/fan-in, and `done_guarded` for output copies guarded by child
completion or trigger done observation. `authored_timing_mode` is `snapshot`
or `live` when an input binding explicitly spells `(timing snapshot)` or
`(timing live)`, and JSON null when no timing clause was authored, including
output bindings. Non-applicable generated signals are JSON null. This is
provenance and review support; it is not raw assignment provenance and it does
not expose private activation proof state.
Successful priority/resource decisions are emitted as top-level
`priority_resolutions` and `resource_arbitration` arrays. A
`priority_resolutions` entry records the target plus bounded winner/loser owner
names and owner kinds for target-local suppression. A `resource_arbitration`
entry records an enforced resource's name, kind, arbiter, bound rule user,
explicit member list, and the users that can suppress that user's grant. For
`priority` resources, `suppressed_by` names higher-priority bound rule users.
For bounded `round_robin` resources, `suppressed_by` names dynamic peer rule
users that can block that grant for a given pointer position and request set.
The `members` array is empty for resources without an explicit member list and
contains declared actor output or concrete actor-owned storage signal names
for explicit output bundles. These entries describe the lowering decision;
they are not per-cycle runtime grant traces.
Raw assignment provenance remains a private `LoweringIR` implementation
detail. Public reports expose only bounded substitutes: capped source
summaries in `compile_issues[]`, compatible fan-in facts in
`compatible_fanin_groups[]`, priority/resource decision summaries in
`priority_resolutions[]` and `resource_arbitration[]`,
`transaction_port_bindings[]`, and aggregate access summaries such as
`bank_accesses[]`. `dt_blocks[].assignments` is intentionally a count, not a
serialized assignment list, so downstream consumers must not depend on private
assignment indexes or proof internals.
The CLI `--emit-schedule-json` entrypoint is expected to emit the same report as
the in-process scheduler on stdout and keep stderr clean on success.
For single-clock multi-file lowerings, that report currently describes the
parent scheduled module only. For multi-domain lowerings, it describes the
generated top and projects bounded per-domain/crossing summaries.
Parent reports do not recursively embed child schedule reports. Public
multi-file review surfaces are the `lower(...)` files map, the emitted
scheduled `.fsm`/generated-top artifacts, and bounded report summaries such as
`actor_network`, `generated_composition`, `library_uses[]`, and
`clock_domains[]` / `crossings[]`. A downstream consumer that needs child detail should inspect the
named generated artifact or the explicit bounded summary field rather than a
raw child `LoweringIR` or recursive child report dump.

Schema-freeze readiness is tracked separately from the current bounded public
contract. The report is contractual today through the exact metadata advertised
by `embedding.isf_public_interface`, including top-level keys, nested
key/value families, scalar policies, ordering policies, nullability rules, and
CLI/in-process parity. Schedule JSON schema version `1` is now frozen as a
public schema. New optional keys or new value-family members may be added only
with public-contract metadata, focused tests, and documentation in the same
slice; breaking changes require a `schema_version` bump plus migration or
deprecation documentation.

The executable golden fixture matrix is maintained by
[t/1255-isf-schedule-report-golden-matrix.t](../../t/1255-isf-schedule-report-golden-matrix.t).
It assigns every advertised `schedule_report_*` branch to at least one matrix
case and proves that each case emits the same report through the in-process and
CLI paths. The public contract now advertises
`schedule_report_full_schema_stable = true` for schema version `1`.

## 11. Current Regression Fixtures

Representative shipped fixtures:
- [isf/apb_requester.isf](../../isf/apb_requester.isf)
- [isf/burst_reader.isf](../../isf/burst_reader.isf)
- [isf/full_featured.isf](../../isf/full_featured.isf)
- [isf/i2c_master.isf](../../isf/i2c_master.isf)
- [isf/spawn_parent.isf](../../isf/spawn_parent.isf)
- [isf/rule_resource_arbiter.isf](../../isf/rule_resource_arbiter.isf)
- [isf/stream_stage_contract.isf](../../isf/stream_stage_contract.isf)
- [isf/clock_domain_event_crossing.isf](../../isf/clock_domain_event_crossing.isf)
- [isf/clock_domain_dual_event_crossing.isf](../../isf/clock_domain_dual_event_crossing.isf)
- [isf/clock_domain_no_reset_event_crossing.isf](../../isf/clock_domain_no_reset_event_crossing.isf)
- [isf/spi_master.isf](../../isf/spi_master.isf)
- [isf/uart_tx.isf](../../isf/uart_tx.isf)
- [isf/when_test.isf](../../isf/when_test.isf)
- [isf/switch_test.isf](../../isf/switch_test.isf)
- [isf/common/fifo.isf](../../isf/common/fifo.isf)
- [isf/fifo_library_use.isf](../../isf/fifo_library_use.isf)
- [isf/atl_trigger_batch_pipeline.isf](../../isf/atl_trigger_batch_pipeline.isf)
- [isf/atl_data_route_pipeline.isf](../../isf/atl_data_route_pipeline.isf)
- [isf/atl_pin_ingress_pipeline.isf](../../isf/atl_pin_ingress_pipeline.isf)
- [isf/atl_pin_egress_pipeline.isf](../../isf/atl_pin_egress_pipeline.isf)
- [isf/atl_trigger_wait_pipeline.isf](../../isf/atl_trigger_wait_pipeline.isf)
- [isf/atl_trigger_batch_wait_pipeline.isf](../../isf/atl_trigger_batch_wait_pipeline.isf)
- [isf/atl_trigger_batch_multi_wait_pipeline.isf](../../isf/atl_trigger_batch_multi_wait_pipeline.isf)
- [isf/atl_resolved_child_pipeline.isf](../../isf/atl_resolved_child_pipeline.isf)
- [isf/atl_resolved_child_pin_ingress_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_pipeline.isf)
- [isf/atl_resolved_child_pin_ingress_vector_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_vector_pipeline.isf)
- [isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf)
- [isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf)
- [isf/atl_resolved_child_pin_ingress_multi_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_multi_pipeline.isf)
- [isf/atl_resolved_child_pin_egress_pipeline.isf](../../isf/atl_resolved_child_pin_egress_pipeline.isf)
- [isf/atl_resolved_child_pin_egress_vector_pipeline.isf](../../isf/atl_resolved_child_pin_egress_vector_pipeline.isf)
- [isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf](../../isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf)
- [isf/atl_resolved_child_pin_egress_mixed_pipeline.isf](../../isf/atl_resolved_child_pin_egress_mixed_pipeline.isf)
- [isf/atl_two_child_pipeline.isf](../../isf/atl_two_child_pipeline.isf)
- [isf/atl_two_child_data_pipeline.isf](../../isf/atl_two_child_data_pipeline.isf)
- [isf/atl_two_child_vector_data_pipeline.isf](../../isf/atl_two_child_vector_data_pipeline.isf)
- [isf/atl_two_child_multi_data_pipeline.isf](../../isf/atl_two_child_multi_data_pipeline.isf)

The current realistic fixture matrix is tracked in
[docs/tasks/ISF-FIXTURE-COVERAGE.md](../tasks/ISF-FIXTURE-COVERAGE.md). That
matrix separates baseline APB quick coverage from broader `isf`-tier fixture
coverage and records which feature families each fixture owns. The
[isf/spi_master.isf](../../isf/spi_master.isf) fixture now has file-backed
schedule/HDL/strict coverage as a compact SPI-like mode-0 serial-transfer
example, not as a complete SPI protocol compliance suite. It stays in the
`isf` regression tier rather than the curated quick/smoke tier.
The [isf/i2c_master.isf](../../isf/i2c_master.isf) fixture now also has
file-backed schedule/HDL/strict coverage as a compact I2C-like
serial-transfer example. It proves switch-branch repeats, read-data shifting,
sampled write-data bit selection from `data[7]`, and no implicit `data_bit`
input, without claiming complete I2C protocol compliance.
The [isf/burst_reader.isf](../../isf/burst_reader.isf) fixture now has
file-backed schedule/HDL/strict coverage for dynamic repeat counts, watchdog
and latency counters, sampled aliases, completion/timeout pulse fan-in, and
strict generated HDL reachability.
The [isf/uart_tx.isf](../../isf/uart_tx.isf) fixture now has file-backed
schedule/HDL/strict coverage as a bounded UART-like transmit example. It
proves sampled-byte LSB drive selection from `byte_data[0]`, known-width
`shift_right`, repeat counter storage, busy drive sequencing, completion pulse
behavior, and strict generated HDL reachability without claiming complete UART
protocol compliance.
The [isf/phase_test.isf](../../isf/phase_test.isf) fixture now has file-backed
schedule/HDL/strict coverage for transaction `(phase ...)` pass-through
states, parser-validated phase body metadata, no reusable `done` drive
storage, delayed completion pulse behavior, and strict generated HDL
reachability. It remains phase-metadata coverage, not a claim that
actor-level phase metadata creates runtime scheduling.
The [isf/switch_test.isf](../../isf/switch_test.isf) fixture now has file-backed
schedule/HDL/strict coverage for sampled selector capture, explicit branch
dispatch, default fallthrough to completion, named-drive branch starts,
delayed completion pulse behavior, and strict generated HDL reachability.
The [isf/when_test.isf](../../isf/when_test.isf) fixture now has file-backed
schedule/HDL/strict coverage for entry drive setup, two conditional decision
states, multi-step true-body drives, false-path fallthrough, compatible
named-drive start fan-in, delayed completion pulse behavior, and strict
generated HDL reachability.
The [isf/spawn_parent.isf](../../isf/spawn_parent.isf) fixture now has
file-backed strict generated-composition coverage for generated top emission,
parent/child scheduled `.fsm` artifacts, start/done handoffs, named-drive
request/payload handoffs, public input fanout, `await_all` synchronization,
strict `--outdir` file emission, and strict HDL generation for the generated
top, parent, and child artifacts. It remains a bounded generated-child
composition fixture, not an external protocol compliance claim.
The [isf/rule_resource_arbiter.isf](../../isf/rule_resource_arbiter.isf)
fixture now has file-backed schedule/HDL/strict coverage for a
rule-over-transaction priority resolution, a `rule_slot`/`priority` resource
with two rule users, lower-priority rule suppression by a higher-priority
rule, bounded `priority_resolutions[]` and `resource_arbitration[]` report
metadata, delayed completion pulse behavior, and strict generated HDL
reachability. Focused resource tests also cover the shipped bounded
`rule_slot`/`round_robin`, `output_bundle`/`round_robin`,
`transaction_start`/`round_robin`, and `storage_port`/`round_robin` subsets,
generated round-robin pointer storage metadata, report projection, and
fail-closed unsupported round-robin combinations. Other resource kinds and
broader arbiter surfaces remain
explicitly deferred.
The [isf/stream_stage_contract.isf](../../isf/stream_stage_contract.isf)
fixture now has file-backed schedule/HDL/strict coverage for a sampled
payload, top-level ready/valid stage, top-level bounded eventual contract,
temporal monitor storage roles, SystemVerilog sticky-fail assertion
projection, delayed completion pulse behavior, and strict generated HDL
reachability. It covers the shipped `ready_valid_barrier` stage and
`bounded_eventually` contract subset only; nested stages, nested contracts,
stage-local compute, expression contracts, and wider temporal operators remain
explicitly deferred.
[isf/clock_domain_dual_event_crossing.isf](../../isf/clock_domain_dual_event_crossing.isf)
hardens the CDC fixture surface by covering two opposite-direction acknowledged
event crossings in one generated top with two concrete CDC child modules and
bounded schedule-report metadata.
[isf/clock_domain_no_reset_event_crossing.isf](../../isf/clock_domain_no_reset_event_crossing.isf)
hardens the CDC fixture surface for domains that intentionally omit reset
declarations. It proves lower/report and CLI schedule-JSON propagation of
absent-reset CDC metadata, clock-only domain HDL, and a generated CDC child
without absent reset ports.
The [isf/fifo_library_use.isf](../../isf/fifo_library_use.isf) fixture now has
file-backed strict reusable-library coverage for importer/child/generated-top
scheduled `.fsm` artifacts, fixed FIFO parameter overrides, use-site bindings,
strict schedule JSON parity, strict `--outdir` emission, and plain plus strict
generated-top HDL reachability.
The [isf/atl_trigger_batch_pipeline.isf](../../isf/atl_trigger_batch_pipeline.isf)
fixture now has file-backed ATL temporary trigger-batch coverage for static
actor instances, per-target trigger handoffs, one scheduled same-cycle
trigger-batch state, canonical `association_schedules[]` report evidence,
compatibility `group_schedules[]` report evidence, strict schedule JSON
parity, scheduled `.fsm` structure, and plain plus strict HDL generation. It
stays inside the shipped
external-handoff subset and does not claim generated ATL child artifacts,
broader actor-network wiring, or permanent actor grouping.
The [isf/atl_data_route_pipeline.isf](../../isf/atl_data_route_pipeline.isf)
fixture now has file-backed ATL scalar data-route coverage for two direct
static actor instances, one drive-body `(consumer.payload producer.payload)`
route, one transaction drive call, generated parent handoff ports,
`actor_network.data_movements[]` metadata, empty association/group schedule
arrays, strict schedule JSON parity, scheduled `.fsm` structure, and plain
plus strict HDL generation. It stays inside the shipped scalar handoff subset
and does not claim generated ATL child artifacts, generated ATL tops, route
mux/storage, trigger/data coupling, wider payloads, fan-in/fan-out, CDC, or
permanent actor grouping.
The [isf/atl_pin_ingress_pipeline.isf](../../isf/atl_pin_ingress_pipeline.isf)
fixture now has file-backed ATL scalar pin-ingress coverage for one direct
static actor instance, one top-level input pin source, one drive-body
`(consumer.payload pins.payload)` route, one transaction drive call, generated
actor handoff output `consumer_payload`, `actor_network.data_movements[]`
metadata, empty association/group schedule arrays, strict schedule JSON parity,
scheduled `.fsm` structure, and plain plus strict HDL generation. It stays
inside the shipped scalar pin-to-actor subset and does not claim generated ATL
child artifacts, generated ATL tops, actor-to-pin egress, route mux/storage,
trigger/data coupling, wider payloads, fan-in/fan-out, CDC, or permanent actor
grouping.
The [isf/atl_pin_egress_pipeline.isf](../../isf/atl_pin_egress_pipeline.isf)
fixture now has file-backed ATL scalar pin-egress coverage for one direct
static actor instance, one generated actor source handoff input, one drive-body
`(pins.result producer.payload)` route, one transaction drive call, existing
top-level output sink `result`, `actor_network.data_movements[]` metadata,
empty association/group schedule arrays, strict schedule JSON parity,
scheduled `.fsm` structure, and plain plus strict HDL generation. It stays
inside the shipped scalar actor-to-pin subset and does not claim generated ATL
child artifacts, generated ATL tops, bidirectional pin movement, route
mux/storage, trigger/data coupling, wider payloads, fan-in/fan-out, CDC, or
permanent actor grouping.
The [isf/atl_trigger_wait_pipeline.isf](../../isf/atl_trigger_wait_pipeline.isf)
fixture now has file-backed ATL trigger-wait coverage for one direct static
actor instance, one `(trigger worker.process)` parent output pulse, one
`(await worker.done)` parent event input wait, one
`actor_network.transaction_triggers[]` entry, one
`actor_network.event_waits[]` entry, empty association/group/data-movement
arrays, strict schedule JSON parity, scheduled `.fsm` structure including the
default await timeout state, and plain plus strict HDL generation. It stays
inside the shipped parent-handoff subset and does not claim generated ATL
child artifacts, generated ATL tops, actor type resolution, HDL child wiring,
temporary trigger-batch plus event coupling, data movement coupling,
fan-in/fan-out, CDC, or permanent actor grouping.
The [isf/atl_trigger_batch_wait_pipeline.isf](../../isf/atl_trigger_batch_wait_pipeline.isf)
fixture now has file-backed ATL trigger-batch wait coverage for three direct
static actor instances, one same-cycle temporary trigger batch, one following
`(await writer.done)` parent event input wait, `association_schedules[]`
temporary-association metadata, `group_schedules[]` compatibility metadata,
one `event_waits[]` entry, empty data movement, strict schedule JSON parity,
scheduled `.fsm` structure including the default await timeout state, and
plain plus strict HDL generation. It stays inside the shipped parent-handoff
subset and does not claim generated ATL child artifacts, generated ATL tops,
actor type resolution, HDL child wiring, hidden multi-event fan-in joins,
data movement coupling, CDC, or permanent actor grouping.
The [isf/atl_trigger_batch_multi_wait_pipeline.isf](../../isf/atl_trigger_batch_multi_wait_pipeline.isf)
fixture now has file-backed ATL trigger-batch multi-event wait coverage for
three direct static actor instances, one same-cycle temporary trigger batch,
three contiguous source-ordered waits on `reader.done`, `filter.done`, and
`writer.done`, three `event_waits[]` entries, strict schedule JSON parity,
scheduled `.fsm` structure with one trigger-batch state followed by three
explicit wait states and the default await timeout state, and plain plus
strict HDL generation. It stays inside the shipped parent-handoff subset and
does not claim hidden actor-event fan-in/fan-out joins, repeated waits to one
triggered actor, payload waits, generated ATL child event wiring, data
movement coupling, CDC, or permanent actor grouping. Repeated trigger-batch
waits fail closed with the event re-arm/lifetime diagnostic.
The [isf/atl_resolved_child_pipeline.isf](../../isf/atl_resolved_child_pipeline.isf)
fixture now has file-backed ATL resolved-child coverage for one same-source
library actor export, one resolved `(instance worker of
pkt_lib.packet_worker)`, one parent `(trigger worker.process)`, one parent
`(await worker.done)`, exactly three lower-result artifacts
`atl_resolved_child_pipeline.fsm` and
`atl_resolved_child_pipeline__worker.fsm`, and
`atl_resolved_child_pipeline_top.fsm`, strict schedule JSON parity,
resolved `actor_network.instances[]` metadata, one
`transaction_triggers[]` entry, one `event_waits[]` entry, one
`actor_network.generated_tops[]` entry, and empty data/association/group
schedule arrays. It stays inside the shipped one-child trigger/event
generated-top subset and does not claim multiple resolved children, trigger
batches, data-route coupling, inferred payload/ready/backpressure binding,
route mux/storage, actor-event fan-in, CDC, recursive actor networks, or
permanent actor grouping.
The [isf/atl_resolved_child_pin_ingress_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_pipeline.isf)
fixture now has file-backed ATL generated-top pin-ingress coverage for one
resolved child, one top-level scalar input pin `payload`, one drive-body
`(worker.payload pins.payload)` route, one transaction drive call, one
trigger handoff, one event wait, parent/child/top `.fsm` artifacts, strict
schedule JSON parity, generated child `+interface` metadata for the selected
child input, internal generated-top wiring from parent `worker_payload` to
child `payload`, and plain plus strict HDL generation. It stays inside the
shipped one-child scalar pin-ingress generated-top subset and does not claim
actor-to-actor generated-child routes, multi-child data wiring,
route mux/storage, CDC/reset remapping, ready/backpressure, payload
protocols, recursive actor networks, or permanent actor grouping.
The [isf/atl_resolved_child_pin_ingress_vector_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_vector_pipeline.isf)
fixture now has file-backed ATL generated-top exact-width vector pin-ingress
coverage for one resolved child, one top-level input pin `payload` declared at
width 8, one child input `payload` declared at width 8, one drive-body
`(worker.payload pins.payload)` route, one transaction drive call before the
child trigger, one trigger handoff, one event wait, parent/child/top `.fsm`
artifacts, strict schedule JSON parity, generated child `+interface` metadata
for the selected child input, internal generated-top wiring from parent
`worker_payload` to child `payload`, strict outdir materialization, plain plus
strict HDL generation, and fail-closed top-pin/child-input width mismatch
coverage. It stays inside the shipped one-route exact-width vector
pin-ingress generated-top subset and does not claim mixed scalar/vector route
sets, width adaptation, packing, truncation, extension, slicing,
route mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure,
payload protocols, recursive actor networks, or permanent actor grouping.
The [isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf)
fixture now has file-backed ATL generated-top exact-width vector pin-ingress
multi-route coverage for one resolved child, two top-level vector input pins
`payload` and `sideband`, matching child input widths 8 and 4, two drive-body
routes `(worker.payload pins.payload)` and `(worker.sideband pins.sideband)`,
adjacent transaction drive calls before the child trigger, one trigger
handoff, one event wait, parent/child/top `.fsm` artifacts, strict schedule
JSON parity, two `vector_pin_to_actor_handoff` report entries, generated child
`+interface` metadata for both selected child inputs, internal generated-top
wiring from parent `worker_payload`/`worker_sideband` to child
`payload`/`sideband`, strict outdir materialization, plain plus strict HDL
generation, and fail-closed route-local top-pin/child-input width mismatch
coverage. It stays inside the shipped same-child vector pin-ingress route-set
subset and does not claim width adaptation, route mux/storage,
fan-in/fan-out, CDC/reset remapping, ready/backpressure, payload protocols,
recursive actor networks, or permanent actor grouping.
The [isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf)
fixture now has file-backed ATL generated-top mixed scalar/vector pin-ingress
route-set coverage for one resolved child, top-level input `payload` declared
at width 8, scalar top-level input `valid`, matching child inputs, drive-body
routes `(worker.payload pins.payload)` and `(worker.valid pins.valid)`,
adjacent transaction drive calls before the child trigger, one trigger
handoff, one event wait, parent/child/top `.fsm` artifacts, strict schedule
JSON parity, `vector_pin_to_actor_handoff` plus
`scalar_pin_to_actor_handoff` report entries, generated child `+interface`
metadata for both selected child inputs, internal generated-top wiring from
parent `worker_payload`/`worker_valid` to child `payload`/`valid`, strict
outdir materialization, plain plus strict HDL generation, and fail-closed
route-local top-pin/child-input width mismatch coverage for the vector route.
It stays inside the shipped one-child same-child mixed pin-ingress route-set
subset and does not claim broader mixed route fabrics, width adaptation,
route mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure,
payload protocols, recursive actor networks, or permanent actor grouping.
The [isf/atl_resolved_child_pin_ingress_multi_pipeline.isf](../../isf/atl_resolved_child_pin_ingress_multi_pipeline.isf)
fixture now has file-backed ATL generated-top pin-ingress multi-route coverage
for one resolved child, two top-level scalar input pins `payload` and
`sideband`, two drive-body routes `(worker.payload pins.payload)` and
`(worker.sideband pins.sideband)`, adjacent transaction drive calls, one trigger
handoff, one event wait, parent/child/top `.fsm` artifacts, strict schedule JSON
parity, generated child `+interface` metadata for both selected child inputs,
internal generated-top wiring from parent `worker_payload`/`worker_sideband` to
child `payload`/`sideband`, strict outdir materialization, plain plus strict HDL
generation, missing child input failure, interleaved-drive-call failure, and
duplicate top-level input pin failure. It stays inside the shipped one-child
same-child scalar pin-ingress route-set subset and does not claim child-to-pin
multi-route egress, actor-to-actor generated-child route widening, multi-child
data wiring, route mux/storage, fan-in/fan-out, CDC/reset remapping,
ready/backpressure, payload protocols, recursive actor networks, or permanent
actor grouping.
The [isf/atl_resolved_child_pin_egress_pipeline.isf](../../isf/atl_resolved_child_pin_egress_pipeline.isf)
fixture now has file-backed ATL generated-top pin-egress coverage for one
resolved child, one top-level scalar output pin `result`, one drive-body
`(pins.result worker.payload)` route after the child event wait, one trigger
handoff, one event wait, parent/child/top `.fsm` artifacts, strict schedule
JSON parity, generated child `+interface` metadata for the selected child
output, internal generated-top wiring from child `payload` to parent
`worker_payload`, public generated-top wiring from parent `result` to top
`result`, and plain plus strict HDL generation. It stays inside the shipped
one-child scalar pin-egress generated-top subset and does not claim
actor-to-actor generated-child routes, multi-child data wiring,
route mux/storage, CDC/reset remapping, ready/backpressure, payload
protocols, recursive actor networks, or permanent actor grouping.
The [isf/atl_resolved_child_pin_egress_vector_pipeline.isf](../../isf/atl_resolved_child_pin_egress_vector_pipeline.isf)
fixture now has file-backed ATL generated-top exact-width vector pin-egress
coverage for one resolved child, one child output `payload` declared at width
8, one top-level output pin `result` declared at width 8, one drive-body
`(pins.result worker.payload)` route after the child event wait, one trigger
handoff, one event wait, parent/child/top `.fsm` artifacts, strict schedule
JSON parity, generated child `+interface` metadata for the selected child
output, internal generated-top wiring from child `payload` to parent
`worker_payload`, public generated-top wiring from parent `result` to top
`result`, strict outdir materialization, plain plus strict HDL generation, and
fail-closed child-output/top-output width mismatch coverage. It stays inside
the shipped one-route exact-width vector pin-egress generated-top subset.
The [isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf](../../isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf)
fixture now has file-backed ATL generated-top exact-width vector pin-egress
multi-route coverage for one resolved child, top-level output pins `result`
and `status` declared at widths 8 and 4, child outputs `payload` and `status`
declared at matching widths, two drive-body routes
`(pins.result worker.payload)` and `(pins.status worker.status)`, adjacent
transaction drive calls after the child event wait, one trigger handoff, one
event wait, parent/child/top `.fsm` artifacts, strict schedule JSON parity,
generated child `+interface` metadata for both selected child outputs,
internal generated-top wiring from child `payload`/`status` to parent
`worker_payload`/`worker_status`, strict outdir materialization, plain plus
strict HDL generation, and route-local width mismatch coverage. It stays
inside the shipped one-child same-child exact-width vector pin-egress route-set
subset and does not claim width adaptation, packing, truncation, extension,
slicing, route mux/storage, fan-in/fan-out, CDC/reset remapping,
ready/backpressure, payload protocols, recursive actor networks, or permanent
actor grouping.
The [isf/atl_resolved_child_pin_egress_mixed_pipeline.isf](../../isf/atl_resolved_child_pin_egress_mixed_pipeline.isf)
fixture now has file-backed ATL generated-top mixed scalar/vector pin-egress
route-set coverage for one resolved child, top-level output `result` declared
at width 8, scalar top-level output `valid`, matching child outputs,
drive-body routes `(pins.result worker.payload)` and
`(pins.valid worker.valid)`, adjacent transaction drive calls after the child
event wait, one trigger handoff, one event wait, parent/child/top `.fsm`
artifacts, strict schedule JSON parity, `vector_actor_to_pin_handoff` plus
`scalar_actor_to_pin_handoff` report entries, generated child `+interface`
metadata for both selected child outputs, internal generated-top wiring from
child `payload`/`valid` to parent `worker_payload`/`worker_valid`, strict
outdir materialization, plain plus strict HDL generation, and fail-closed
route-local child-output/top-output width mismatch coverage for the vector
route. It stays inside the shipped one-child same-child mixed pin-egress
route-set subset and does not claim width adaptation, route mux/storage,
fan-in/fan-out, CDC/reset remapping, ready/backpressure, payload protocols,
recursive actor networks, or permanent actor grouping.
The [isf/atl_resolved_child_pin_egress_multi_pipeline.isf](../../isf/atl_resolved_child_pin_egress_multi_pipeline.isf)
fixture now has file-backed ATL generated-top pin-egress multi-route coverage
for one resolved child, two top-level scalar output pins `result` and `status`,
two drive-body routes `(pins.result worker.payload)` and
`(pins.status worker.status)`, adjacent transaction drive calls after the child
event wait, one trigger handoff, one event wait, parent/child/top `.fsm`
artifacts, strict schedule JSON parity, generated child `+interface` metadata
for both selected child outputs, internal generated-top wiring from child
`payload`/`status` to parent `worker_payload`/`worker_status`, strict outdir
materialization, plain plus strict HDL generation, missing child output
failure, interleaved-drive-call failure, and duplicate top-level output pin
failure. It stays inside the shipped one-child same-child scalar pin-egress
route-set subset and does not claim actor-to-actor generated-child route
widening, multi-child data wiring, route mux/storage, fan-in/fan-out,
CDC/reset remapping, ready/backpressure, payload protocols, recursive actor
networks, or permanent actor grouping.
The [isf/atl_two_child_pipeline.isf](../../isf/atl_two_child_pipeline.isf)
fixture now has file-backed two-child generated-top coverage for sequential
trigger/event handoffs without data movement. It proves parent/reader/writer
and top `.fsm` artifacts, strict schedule JSON parity, nested
`generated_tops[].children[]` child wiring metadata, generated-top wiring,
and plain plus strict HDL generation.
The [isf/atl_two_child_data_pipeline.isf](../../isf/atl_two_child_data_pipeline.isf)
fixture now has file-backed two-child generated-top data-route coverage for
the selected one-bit generated-child actor-to-actor route. It proves
parent/reader/writer/top `.fsm` artifacts, strict schedule JSON parity,
`actor_network.data_movements[]` `scalar_actor_handoff` route metadata,
nested `generated_tops[].children[]` child wiring metadata, reader output and
writer input generated `+interface` metadata, internal generated-top payload
wiring, plain plus strict HDL generation, a missing sink payload diagnostic,
and a fail-closed diagnostic when the drive call does not follow the source
event wait.
The [isf/atl_two_child_vector_data_pipeline.isf](../../isf/atl_two_child_vector_data_pipeline.isf)
fixture now has file-backed exact-width vector route coverage for the same
two-child generated-top shape. It proves 8-bit parent source/sink handoff
ports, 8-bit child payload ports, generated top wiring, strict schedule JSON
parity, strict outdir materialization, plain plus strict HDL generation, and
`actor_network.data_movements[]` metadata with
`kind: "vector_actor_handoff"` and
`width_source: "resolved_child_endpoint_exact_width"`.
The [isf/atl_two_child_multi_data_pipeline.isf](../../isf/atl_two_child_multi_data_pipeline.isf)
fixture now has file-backed bounded multi-route coverage for that same
generated top shape. It proves two same-source/same-sink scalar
`scalar_actor_handoff` route records, separate drive-call states and handoffs,
reader/writer generated `+interface` preservation for both scalar paths,
generated-top wiring for both paths, strict outdir materialization, and plain
plus strict HDL generation.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.40` shipped focused hardening for that
same fixture family: source-child output validation and route-cardinality
fail-closed coverage before any broader generated-child data wiring is
claimed.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.42` shipped scalar endpoint-width
hardening for that same route family. `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2`
then selected the bounded exact-width widening: matching source-output and
sink-input child endpoint widths greater than one lower through the same
drive-call-cycle handoff route, while mismatches still fail closed before any
packing, truncation, extension, storage, muxing, or payload protocol is
inferred.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.68` shipped the next fail-closed
hardening for that route family: route start/completion boundaries remain
parent interface pins with fixed roles. The parser and lowerer now require
the start boundary to name a scalar top-level input and the completion
boundary to name a scalar top-level output before interface remapping,
activation fan-in, completion fan-out, boundary expressions, storage,
muxing, ready/backpressure, or payload protocols are claimed.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.70` shipped generated-handoff collision
hardening for that route family. Parent-declared interface or storage
signals that collide with the selected source/sink trigger, event, data, or
named-drive request handoffs now fail closed before generated-handoff
remapping, route mux/storage, fan-in/fan-out, ready/backpressure, or payload
protocols are claimed.

`ISF-ACTOR-NETWORK-ORCHESTRATION.9.72` shipped the matching lowerer
defensive backstop for malformed or mutated scheduler-facing actor metadata.
Normal `.isf` source remains parser-diagnosed, and the lowerer now prevents
generated-top wiring from reusing, suppressing, or shadowing those handoff
names if metadata reaches lowering outside the normal parser path. It does
not select new syntax, generated-handoff remapping, route mux/storage,
fan-in/fan-out, ready/backpressure, or payload protocols.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.74` shipped an mdBook audit so the
dedicated generated-child route terminology section remains present and
complete for generated handoffs, remapping, route mux/storage, fan-in/fan-out,
ready/backpressure, payload protocols, parser/lowerer collision ownership,
and the current one-bit drive-call-cycle boundary. This is documentation
truth hardening only.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.75` selected a follow-on mdBook precision
pass for that same section so those terms become a term-by-term support
boundary. The selected work is documentation-only and does not claim new ATL
source syntax, reports, generated artifacts, mux/storage, fan-in/fan-out,
ready/backpressure, payload protocols, remapping, CDC behavior, recursive
actor networks, or permanent actor grouping.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.76` shipped that precision pass: the
mdBook now gives route lifetime/value boundary, generated handoffs, handoff
remapping, diagnostic ownership, route muxing/storage, fan-in/fan-out,
ready/backpressure, and payload protocols their own generated-child route
term subsections.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.80` hardens the generated-child
actor-to-actor route boundary for drive arguments: route drive definitions do
not accept formal parameters, and route drive calls do not accept actual
arguments in this subset. `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2` applies
the same shared boundary to the shipped generated-top pin-ingress and
pin-egress route families. Those shapes remain fail-closed before drive
actual binding, expression movement, route mux/storage, or payload protocols
are inferred.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.91` hardens the source-expression boundary:
the route source side remains one scalar endpoint, and a drive-body source
expression such as `(writer.payload (+ reader.payload 1))` fails closed
before expression movement, value transformation, storage, or payload
protocol behavior is inferred.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.93` hardens the sink-expression boundary:
the route sink side also remains one scalar endpoint, and a drive-body sink
expression such as `((+ writer.payload 1) reader.payload)` fails closed
before expression destinations, route-side transforms, storage, or payload
protocol behavior is inferred.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.95` keeps that sink-expression diagnostic
source-order independent: a drive body written before the matching
`(instance ...)` clauses defers only endpoint-looking malformed sink
expressions until actor instances are known, while ordinary malformed local
drive targets such as `((out) 1)` keep the existing generic scalar-head
diagnostic.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.99` keeps that source-expression
diagnostic source-order independent too: a drive body written before the
matching `(instance ...)` clauses with a malformed source expression such as
`(writer.payload (+ reader.payload 1))` fails with the same targeted ATL
source-expression diagnostic after actor instances are known. This does not
select expression movement, route-side transforms, storage, route
mux/storage, ready/backpressure, or payload protocols.
`ISF-ACTOR-NETWORK-ORCHESTRATION.9.97` proves the accepted actor-to-actor
route is source-order independent as well: the `forward_payload` drive may
appear before the `reader` and `writer` instances and still resolves to the
same generated-child actor-to-actor route, generated ATL top handoffs, and
`actor_network.data_movements[]` report entry.
`ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2` widens only the bounded same-source,
same-sink route cardinality: `isf/atl_two_child_multi_data_pipeline.isf` ships
two scalar actor-to-actor route drives from `reader` to `writer` in one parent
transaction. The scheduler emits separate drive states and handoffs for
`payload` and `sideband`, reports both routes through
`actor_network.data_movements[]`, preserves the same
`generated_tops[].children[]` public top evidence, and keeps route mux/storage,
fan-in/fan-out, width adaptation, CDC/reset remapping, ready/backpressure,
repeated activation, and cross-transaction continuation deferred.
`ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2` widens the payload width only for
same-width generated-child actor-to-actor routes. The source syntax, drive
call timing, same-source/same-sink route topology, and generated-top evidence
stay unchanged; only the route handoff width and public `data_movements[]`
`kind`/`width_source` values distinguish vector routes from one-bit scalar
routes.

Realistic fixtures should use documented ISF constructs. If writing a fixture
requires an awkward workaround for ordinary hardware intent, treat that as a
language-expressiveness signal: either rewrite the fixture with a documented
construct or track the missing construct in the task tree/backlog.

ISF arity policy follows the same rule. Constructs with fixed hardware roles
should keep exact arity so malformed intent is rejected early. Examples include
`(sample port as name)`, `(complete port)`, `(spawn child as instance)`, and
known drive calls whose formal list defines positional actuals. Constructs
whose semantics are naturally list-like or associative may be variadic when
that makes the source clearer, but the construct must still have deterministic
lowering, malformed-boundary diagnostics, focused or fixture coverage, and
public documentation in the same slice. Lisp-like syntax alone is not a support
claim for arbitrary argument counts.

Focused tests:
- [t/1091-isf-parser-apb-requester.t](../../t/1091-isf-parser-apb-requester.t)
- [t/1092-isf-lispish-adapter.t](../../t/1092-isf-lispish-adapter.t)
- [t/1093-isf-parser-full-featured.t](../../t/1093-isf-parser-full-featured.t)
- [t/1094-isf-scheduler-module-header.t](../../t/1094-isf-scheduler-module-header.t)
- [t/1095-isf-scheduler-burst-reader.t](../../t/1095-isf-scheduler-burst-reader.t)
- [t/1096-isf-schedule-json-report.t](../../t/1096-isf-schedule-json-report.t)
- [t/1097-isf-start-signal-binding.t](../../t/1097-isf-start-signal-binding.t)
- [t/1098-isf-await-any-sync.t](../../t/1098-isf-await-any-sync.t)
- [t/1099-isf-repeat-data-ops.t](../../t/1099-isf-repeat-data-ops.t)
- [t/1100-isf-sample-piggyback.t](../../t/1100-isf-sample-piggyback.t)
- [t/1101-isf-extract-slices.t](../../t/1101-isf-extract-slices.t)
- [t/1102-isf-repeat-counter-widths.t](../../t/1102-isf-repeat-counter-widths.t)
- [t/1103-isf-switch-branch-exits.t](../../t/1103-isf-switch-branch-exits.t)
- [t/1104-isf-when-branch-exits.t](../../t/1104-isf-when-branch-exits.t)
- [t/1105-isf-size-deduplication.t](../../t/1105-isf-size-deduplication.t)
- [t/1106-isf-schedule-json-counter-storage.t](../../t/1106-isf-schedule-json-counter-storage.t)
- [t/1107-isf-when-body-ops.t](../../t/1107-isf-when-body-ops.t)
- [t/1108-isf-schedule-json-transaction-states.t](../../t/1108-isf-schedule-json-transaction-states.t)
- [t/1109-isf-await-all-sync.t](../../t/1109-isf-await-all-sync.t)
- [t/1110-isf-do-child-entry-rewire.t](../../t/1110-isf-do-child-entry-rewire.t)
- [t/1111-isf-sample-before-data-ops.t](../../t/1111-isf-sample-before-data-ops.t)
- [t/1112-isf-public-interface-contract.t](../../t/1112-isf-public-interface-contract.t)
- [t/1113-isf-public-interface-contract-json-roundtrip-audit.t](../../t/1113-isf-public-interface-contract-json-roundtrip-audit.t)
- [t/1114-isf-public-interface-contract-defensive-copy-audit.t](../../t/1114-isf-public-interface-contract-defensive-copy-audit.t)
- [t/1115-isf-public-interface-cli-manifest-audit.t](../../t/1115-isf-public-interface-cli-manifest-audit.t)
- [t/1116-isf-public-schedule-report-key-family-audit.t](../../t/1116-isf-public-schedule-report-key-family-audit.t)
- [t/1117-isf-public-lower-result-files-audit.t](../../t/1117-isf-public-lower-result-files-audit.t)
- [t/1118-isf-public-parse-source-facade-audit.t](../../t/1118-isf-public-parse-source-facade-audit.t)
- [t/1119-isf-deterministic-dt-block-order.t](../../t/1119-isf-deterministic-dt-block-order.t)
- [t/1120-isf-public-live-document-path-audit.t](../../t/1120-isf-public-live-document-path-audit.t)
- [t/1121-isf-public-cli-schedule-report-audit.t](../../t/1121-isf-public-cli-schedule-report-audit.t)
- [t/1122-isf-public-cli-outdir-lowering-audit.t](../../t/1122-isf-public-cli-outdir-lowering-audit.t)
- [t/1123-isf-public-cli-hdl-generation-audit.t](../../t/1123-isf-public-cli-hdl-generation-audit.t)
- [t/1124-isf-public-cli-strict-mode-audit.t](../../t/1124-isf-public-cli-strict-mode-audit.t)
- [t/1125-isf-public-constructor-boundary-audit.t](../../t/1125-isf-public-constructor-boundary-audit.t)
- [t/1126-isf-public-parser-method-boundary-audit.t](../../t/1126-isf-public-parser-method-boundary-audit.t)
- [t/1127-isf-public-scheduler-method-boundary-audit.t](../../t/1127-isf-public-scheduler-method-boundary-audit.t)
- [t/1128-isf-public-multifile-schedule-report-audit.t](../../t/1128-isf-public-multifile-schedule-report-audit.t)
- [t/1129-isf-public-actor-shell-contract-audit.t](../../t/1129-isf-public-actor-shell-contract-audit.t)
- [t/1130-isf-public-compile-issues-success-audit.t](../../t/1130-isf-public-compile-issues-success-audit.t)
- [t/1131-isf-public-top-level-discovery-audit.t](../../t/1131-isf-public-top-level-discovery-audit.t)
- [t/1132-isf-public-method-receiver-boundary-audit.t](../../t/1132-isf-public-method-receiver-boundary-audit.t)
- [t/1133-isf-public-constructor-receiver-boundary-audit.t](../../t/1133-isf-public-constructor-receiver-boundary-audit.t)
- [t/1134-isf-public-parse-file-path-boundary-audit.t](../../t/1134-isf-public-parse-file-path-boundary-audit.t)
- [t/1135-isf-public-entrypoint-metadata-audit.t](../../t/1135-isf-public-entrypoint-metadata-audit.t)
- [t/1136-isf-public-cli-option-metadata-audit.t](../../t/1136-isf-public-cli-option-metadata-audit.t)
- [t/1137-isf-public-method-name-metadata-audit.t](../../t/1137-isf-public-method-name-metadata-audit.t)
- [t/1138-isf-public-constructor-option-metadata-audit.t](../../t/1138-isf-public-constructor-option-metadata-audit.t)
- [t/1139-isf-public-lower-result-metadata-audit.t](../../t/1139-isf-public-lower-result-metadata-audit.t)
- [t/1140-isf-public-schedule-report-metadata-audit.t](../../t/1140-isf-public-schedule-report-metadata-audit.t)
- [t/1141-isf-public-identity-flags-metadata-audit.t](../../t/1141-isf-public-identity-flags-metadata-audit.t)
- [t/1142-isf-public-guidance-metadata-audit.t](../../t/1142-isf-public-guidance-metadata-audit.t)
- [t/1143-isf-public-facade-shape-metadata-audit.t](../../t/1143-isf-public-facade-shape-metadata-audit.t)
- [t/1144-isf-public-tested-by-metadata-audit.t](../../t/1144-isf-public-tested-by-metadata-audit.t)
- [t/1145-isf-public-scheduled-fsm-metadata-audit.t](../../t/1145-isf-public-scheduled-fsm-metadata-audit.t)
- [t/1146-isf-public-dt-assignment-metadata-audit.t](../../t/1146-isf-public-dt-assignment-metadata-audit.t)
- [t/1147-isf-public-report-dt-assignment-count-audit.t](../../t/1147-isf-public-report-dt-assignment-count-audit.t)
- [t/1148-isf-public-storage-metadata-audit.t](../../t/1148-isf-public-storage-metadata-audit.t)
- [t/1149-isf-public-transaction-metadata-audit.t](../../t/1149-isf-public-transaction-metadata-audit.t)
- [t/1150-isf-public-reset-metadata-audit.t](../../t/1150-isf-public-reset-metadata-audit.t)
- [t/1151-isf-public-report-count-metadata-audit.t](../../t/1151-isf-public-report-count-metadata-audit.t)
- [t/1152-isf-public-report-scalar-metadata-audit.t](../../t/1152-isf-public-report-scalar-metadata-audit.t)
- [t/1153-isf-public-cli-success-metadata-audit.t](../../t/1153-isf-public-cli-success-metadata-audit.t)
- [t/1154-isf-public-facade-return-metadata-audit.t](../../t/1154-isf-public-facade-return-metadata-audit.t)
- [t/1155-isf-public-cli-strict-success-metadata-audit.t](../../t/1155-isf-public-cli-strict-success-metadata-audit.t)
- [t/1156-isf-public-lower-result-file-shape-audit.t](../../t/1156-isf-public-lower-result-file-shape-audit.t)
- [t/1157-isf-public-report-transaction-ordering-audit.t](../../t/1157-isf-public-report-transaction-ordering-audit.t)
- [t/1158-isf-public-report-dt-kind-metadata-audit.t](../../t/1158-isf-public-report-dt-kind-metadata-audit.t)
- [t/1159-isf-public-report-reset-shape-metadata-audit.t](../../t/1159-isf-public-report-reset-shape-metadata-audit.t)
- [t/1160-isf-public-actor-shell-value-shape-audit.t](../../t/1160-isf-public-actor-shell-value-shape-audit.t)
- [t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t](../../t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t)
- [t/1162-isf-public-actor-shell-interface-shape-audit.t](../../t/1162-isf-public-actor-shell-interface-shape-audit.t)
- [t/1163-isf-public-actor-shell-transaction-shape-audit.t](../../t/1163-isf-public-actor-shell-transaction-shape-audit.t)
- [t/1164-isf-public-actor-shell-actor-name-shape-audit.t](../../t/1164-isf-public-actor-shell-actor-name-shape-audit.t)
- [t/1165-isf-public-actor-shell-timing-shape-audit.t](../../t/1165-isf-public-actor-shell-timing-shape-audit.t)
- [t/1166-isf-public-actor-shell-rule-shape-audit.t](../../t/1166-isf-public-actor-shell-rule-shape-audit.t)
- [t/1167-isf-public-actor-shell-drive-shape-audit.t](../../t/1167-isf-public-actor-shell-drive-shape-audit.t)
- [t/1168-isf-rule-guard-factoring.t](../../t/1168-isf-rule-guard-factoring.t)
- [t/1169-isf-rule-shorthand-guard.t](../../t/1169-isf-rule-shorthand-guard.t)
- [t/1171-isf-rule-trigger-fanin.t](../../t/1171-isf-rule-trigger-fanin.t)
- [t/1172-isf-rule-trigger-fanin-schedule-report.t](../../t/1172-isf-rule-trigger-fanin-schedule-report.t)
- [t/1173-isf-shift-right-explicit-width.t](../../t/1173-isf-shift-right-explicit-width.t)
- [t/1174-isf-extract-explicit-widths.t](../../t/1174-isf-extract-explicit-widths.t)
- [t/1176-isf-resource-priority-boundary.t](../../t/1176-isf-resource-priority-boundary.t)
- [t/1177-isf-do-child-done-pulse.t](../../t/1177-isf-do-child-done-pulse.t)
- [t/1178-isf-handshake-compatibility-boundary.t](../../t/1178-isf-handshake-compatibility-boundary.t)
- [t/1179-isf-phase-stage-boundary.t](../../t/1179-isf-phase-stage-boundary.t)
- [t/1180-isf-unsupported-transaction-clause-boundary.t](../../t/1180-isf-unsupported-transaction-clause-boundary.t)
- [t/1181-isf-rule-action-boundary.t](../../t/1181-isf-rule-action-boundary.t)
- [t/1182-isf-rule-trigger-target-boundary.t](../../t/1182-isf-rule-trigger-target-boundary.t)
- [t/1184-isf-child-transaction-target-boundary.t](../../t/1184-isf-child-transaction-target-boundary.t)
- [t/1185-isf-transaction-name-boundary.t](../../t/1185-isf-transaction-name-boundary.t)
- [t/1186-isf-rule-name-boundary.t](../../t/1186-isf-rule-name-boundary.t)
- [t/1187-isf-drive-name-boundary.t](../../t/1187-isf-drive-name-boundary.t)
- [t/1188-isf-interface-port-boundary.t](../../t/1188-isf-interface-port-boundary.t)
- [t/1189-isf-drive-parameter-boundary.t](../../t/1189-isf-drive-parameter-boundary.t)
- [t/1190-isf-rule-priority-target-boundary.t](../../t/1190-isf-rule-priority-target-boundary.t)
- [t/1191-isf-actor-priority-target-boundary.t](../../t/1191-isf-actor-priority-target-boundary.t)
- [t/1192-isf-singleton-actor-clause-boundary.t](../../t/1192-isf-singleton-actor-clause-boundary.t)
- [t/1193-isf-drive-call-arity-boundary.t](../../t/1193-isf-drive-call-arity-boundary.t)
- [t/1194-isf-drive-body-boundary.t](../../t/1194-isf-drive-body-boundary.t)
- [t/1195-isf-sample-clause-boundary.t](../../t/1195-isf-sample-clause-boundary.t)
- [t/1196-isf-complete-clause-boundary.t](../../t/1196-isf-complete-clause-boundary.t)
- [t/1197-isf-latency-clause-boundary.t](../../t/1197-isf-latency-clause-boundary.t)
- [t/1198-isf-update-clause-boundary.t](../../t/1198-isf-update-clause-boundary.t)
- [t/1199-isf-shift-clause-boundary.t](../../t/1199-isf-shift-clause-boundary.t)
- [t/1200-isf-assemble-clause-boundary.t](../../t/1200-isf-assemble-clause-boundary.t)
- [t/1201-isf-extract-clause-boundary.t](../../t/1201-isf-extract-clause-boundary.t)
- [t/1202-isf-repeat-clause-boundary.t](../../t/1202-isf-repeat-clause-boundary.t)
- [t/1203-isf-await-sync-clause-boundary.t](../../t/1203-isf-await-sync-clause-boundary.t)
- [t/1204-isf-child-composition-clause-boundary.t](../../t/1204-isf-child-composition-clause-boundary.t)
- [t/1205-isf-switch-clause-boundary.t](../../t/1205-isf-switch-clause-boundary.t)
- [t/1206-isf-when-clause-boundary.t](../../t/1206-isf-when-clause-boundary.t)
- [t/1207-isf-assignment-provenance-inventory.t](../../t/1207-isf-assignment-provenance-inventory.t)
- [t/1208-isf-compatible-fanin-classification.t](../../t/1208-isf-compatible-fanin-classification.t)
- [t/1209-isf-static-conflict-detection.t](../../t/1209-isf-static-conflict-detection.t)
- [t/1210-isf-priority-conflict-resolution.t](../../t/1210-isf-priority-conflict-resolution.t)
- [t/1211-isf-runtime-selector-conflict-instrumentation.t](../../t/1211-isf-runtime-selector-conflict-instrumentation.t)
- [t/1212-isf-schedule-report-compile-issues-projection.t](../../t/1212-isf-schedule-report-compile-issues-projection.t)
- [t/1213-isf-schedule-report-compatible-fanin-projection.t](../../t/1213-isf-schedule-report-compatible-fanin-projection.t)
- [t/1214-isf-rejected-conflict-diagnostics.t](../../t/1214-isf-rejected-conflict-diagnostics.t)
- [t/1215-isf-spawn-parameter-binding.t](../../t/1215-isf-spawn-parameter-binding.t)
- [t/1216-isf-generated-composition-top.t](../../t/1216-isf-generated-composition-top.t)
- [t/1217-isf-generated-composition-schedule-report.t](../../t/1217-isf-generated-composition-schedule-report.t)
- [t/1218-isf-rule-slot-resource-arbitration.t](../../t/1218-isf-rule-slot-resource-arbitration.t)
- [t/1219-isf-rule-transaction-priority.t](../../t/1219-isf-rule-transaction-priority.t)
- [t/1220-isf-arbitration-schedule-report.t](../../t/1220-isf-arbitration-schedule-report.t)
- [t/1221-isf-rule-expression-assignment.t](../../t/1221-isf-rule-expression-assignment.t)
- [t/1222-isf-rule-expression-conflict-report.t](../../t/1222-isf-rule-expression-conflict-report.t)
- [t/1223-isf-stage-lowering.t](../../t/1223-isf-stage-lowering.t)
- [t/1226-isf-data-width-storage-report.t](../../t/1226-isf-data-width-storage-report.t)
- [t/1227-isf-schedule-report-freeze-boundary.t](../../t/1227-isf-schedule-report-freeze-boundary.t)
- [t/1228-isf-spi-fixture-coverage.t](../../t/1228-isf-spi-fixture-coverage.t)
- [t/1229-isf-compatibility-cli-parity.t](../../t/1229-isf-compatibility-cli-parity.t)
- [t/1230-isf-library-import-resolution.t](../../t/1230-isf-library-import-resolution.t)
- [t/1231-isf-library-generated-top.t](../../t/1231-isf-library-generated-top.t)
- [t/1232-isf-actor-storage-declarations.t](../../t/1232-isf-actor-storage-declarations.t)
- [t/1233-isf-rule-expression-guards.t](../../t/1233-isf-rule-expression-guards.t)
- [t/1234-isf-disjoint-rule-writes.t](../../t/1234-isf-disjoint-rule-writes.t)
- [t/1235-isf-fifo-same-cycle-update-matrix.t](../../t/1235-isf-fifo-same-cycle-update-matrix.t)
- [t/1236-isf-bank-access-lowering.t](../../t/1236-isf-bank-access-lowering.t)
- [t/1237-isf-fifo-library-fixture.t](../../t/1237-isf-fifo-library-fixture.t)
- [t/1238-isf-fifo-library-hdl-generation.t](../../t/1238-isf-fifo-library-hdl-generation.t)
- [t/1239-isf-library-catalog-contract.t](../../t/1239-isf-library-catalog-contract.t)
- [t/1240-isf-transaction-port-declarations.t](../../t/1240-isf-transaction-port-declarations.t)
- [t/1241-isf-transaction-port-bindings.t](../../t/1241-isf-transaction-port-bindings.t)
- [t/1242-isf-port-binding-conflict-semantics.t](../../t/1242-isf-port-binding-conflict-semantics.t)
- [t/1243-isf-port-binding-schedule-report.t](../../t/1243-isf-port-binding-schedule-report.t)
- [t/1244-isf-wait-clause-lowering.t](../../t/1244-isf-wait-clause-lowering.t)
- [t/1245-isf-transaction-loop-lowering.t](../../t/1245-isf-transaction-loop-lowering.t)
- [t/1246-isf-setter-syntax.t](../../t/1246-isf-setter-syntax.t)
- [t/1247-isf-clock-domain-partition.t](../../t/1247-isf-clock-domain-partition.t)
- [t/1248-isf-rule-trigger-parameter-binding.t](../../t/1248-isf-rule-trigger-parameter-binding.t)
- [t/1249-isf-activation-parameter-constants.t](../../t/1249-isf-activation-parameter-constants.t)
- [t/1250-isf-spec-focused-test-index-audit.t](../../t/1250-isf-spec-focused-test-index-audit.t)
- [t/1252-isf-actor-phase-stage-report.t](../../t/1252-isf-actor-phase-stage-report.t)
- [t/1253-isf-actor-param-report.t](../../t/1253-isf-actor-param-report.t)
- [t/1255-isf-schedule-report-golden-matrix.t](../../t/1255-isf-schedule-report-golden-matrix.t)
- [t/1257-isf-scalar-type-aliases.t](../../t/1257-isf-scalar-type-aliases.t)
- [t/1258-isf-enum-member-constants.t](../../t/1258-isf-enum-member-constants.t)
- [t/1259-isf-aggregate-storage-type-aliases.t](../../t/1259-isf-aggregate-storage-type-aliases.t)
- [t/1260-isf-aggregate-storage-leaf-reads.t](../../t/1260-isf-aggregate-storage-leaf-reads.t)
- [t/1260-isf-verification-observation-metadata.t](../../t/1260-isf-verification-observation-metadata.t)
- [t/1261-isf-aggregate-storage-leaf-writes.t](../../t/1261-isf-aggregate-storage-leaf-writes.t)
- [t/1262-isf-aggregate-storage-leaf-expression-reads.t](../../t/1262-isf-aggregate-storage-leaf-expression-reads.t)
- [t/1263-isf-enum-member-set-values.t](../../t/1263-isf-enum-member-set-values.t)
- [t/1264-isf-enum-member-set-expression-values.t](../../t/1264-isf-enum-member-set-expression-values.t)
- [t/1265-isf-enum-member-switch-branch-values.t](../../t/1265-isf-enum-member-switch-branch-values.t)
- [t/1266-isf-enum-member-drive-values.t](../../t/1266-isf-enum-member-drive-values.t)
- [t/1267-isf-enum-member-drive-call-values.t](../../t/1267-isf-enum-member-drive-call-values.t)
- [t/1268-isf-enum-member-drive-call-expression-values.t](../../t/1268-isf-enum-member-drive-call-expression-values.t)
- [t/1269-isf-enum-member-actor-params.t](../../t/1269-isf-enum-member-actor-params.t)
- [t/1270-isf-enum-member-transaction-params.t](../../t/1270-isf-enum-member-transaction-params.t)
- [t/1271-isf-enum-member-activation-params.t](../../t/1271-isf-enum-member-activation-params.t)
- [t/1272-isf-enum-member-rule-values.t](../../t/1272-isf-enum-member-rule-values.t)
- [t/1273-isf-enum-member-rule-expression-values.t](../../t/1273-isf-enum-member-rule-expression-values.t)
- [t/1274-isf-enum-member-rule-guard-values.t](../../t/1274-isf-enum-member-rule-guard-values.t)
- [t/1275-isf-enum-member-condition-values.t](../../t/1275-isf-enum-member-condition-values.t)
- [t/1276-isf-enum-member-activation-aggregate-params.t](../../t/1276-isf-enum-member-activation-aggregate-params.t)
- [t/1277-isf-enum-member-actor-aggregate-params.t](../../t/1277-isf-enum-member-actor-aggregate-params.t)
- [t/1278-isf-enum-member-transaction-aggregate-params.t](../../t/1278-isf-enum-member-transaction-aggregate-params.t)
- [t/1279-isf-enum-member-inline-drive-values.t](../../t/1279-isf-enum-member-inline-drive-values.t)
- [t/1280-isf-enum-member-inline-drive-expression-values.t](../../t/1280-isf-enum-member-inline-drive-expression-values.t)
- [t/1281-isf-enum-member-library-use-params.t](../../t/1281-isf-enum-member-library-use-params.t)
- [t/1282-isf-enum-member-drive-expression-values.t](../../t/1282-isf-enum-member-drive-expression-values.t)
- [t/1283-isf-aggregate-rule-values.t](../../t/1283-isf-aggregate-rule-values.t)
- [t/1284-isf-aggregate-rule-expression-values.t](../../t/1284-isf-aggregate-rule-expression-values.t)
- [t/1285-isf-aggregate-rule-guard-values.t](../../t/1285-isf-aggregate-rule-guard-values.t)
- [t/1286-isf-aggregate-condition-values.t](../../t/1286-isf-aggregate-condition-values.t)
- [t/1287-isf-aggregate-drive-values.t](../../t/1287-isf-aggregate-drive-values.t)
- [t/1288-isf-aggregate-drive-expression-values.t](../../t/1288-isf-aggregate-drive-expression-values.t)
- [t/1289-isf-aggregate-drive-call-values.t](../../t/1289-isf-aggregate-drive-call-values.t)
- [t/1290-isf-aggregate-drive-call-expression-values.t](../../t/1290-isf-aggregate-drive-call-expression-values.t)
- [t/1291-isf-aggregate-inline-drive-values.t](../../t/1291-isf-aggregate-inline-drive-values.t)
- [t/1292-isf-aggregate-inline-drive-expression-values.t](../../t/1292-isf-aggregate-inline-drive-expression-values.t)
- [t/1293-isf-aggregate-switch-branch-values.t](../../t/1293-isf-aggregate-switch-branch-values.t)
- [t/1294-isf-aggregate-switch-selector-values.t](../../t/1294-isf-aggregate-switch-selector-values.t)
- [t/1295-isf-enum-member-switch-selector-values.t](../../t/1295-isf-enum-member-switch-selector-values.t)
- [t/1296-isf-aggregate-rule-target-values.t](../../t/1296-isf-aggregate-rule-target-values.t)
- [t/1297-isf-aggregate-drive-target-values.t](../../t/1297-isf-aggregate-drive-target-values.t)
- [t/1298-isf-aggregate-inline-drive-target-values.t](../../t/1298-isf-aggregate-inline-drive-target-values.t)
- [t/1299-isf-aggregate-standalone-condition-values.t](../../t/1299-isf-aggregate-standalone-condition-values.t)
- [t/1300-isf-enum-member-standalone-condition-values.t](../../t/1300-isf-enum-member-standalone-condition-values.t)
- [t/1301-isf-enum-member-rule-standalone-guard-values.t](../../t/1301-isf-enum-member-rule-standalone-guard-values.t)
- [t/1302-isf-aggregate-rule-standalone-guard-values.t](../../t/1302-isf-aggregate-rule-standalone-guard-values.t)
- [t/1303-isf-public-live-book-paths-audit.t](../../t/1303-isf-public-live-book-paths-audit.t)
- [t/1304-isf-repeat-body-doc-truth-audit.t](../../t/1304-isf-repeat-body-doc-truth-audit.t)
- [t/1305-isf-book-feature-matrix-audit.t](../../t/1305-isf-book-feature-matrix-audit.t)
- [t/1306-isf-rule-guard-doc-truth-audit.t](../../t/1306-isf-rule-guard-doc-truth-audit.t)
- [t/1307-isf-loop-body-doc-truth-audit.t](../../t/1307-isf-loop-body-doc-truth-audit.t)
- [t/1308-isf-dynamic-divisor-safety.t](../../t/1308-isf-dynamic-divisor-safety.t)
- [t/1309-isf-i2c-fixture-coverage.t](../../t/1309-isf-i2c-fixture-coverage.t)
- [t/1310-isf-burst-fixture-coverage.t](../../t/1310-isf-burst-fixture-coverage.t)
- [t/1311-isf-uart-fixture-coverage.t](../../t/1311-isf-uart-fixture-coverage.t)
- [t/1312-isf-phase-fixture-coverage.t](../../t/1312-isf-phase-fixture-coverage.t)
- [t/1313-isf-switch-fixture-coverage.t](../../t/1313-isf-switch-fixture-coverage.t)
- [t/1314-isf-when-fixture-coverage.t](../../t/1314-isf-when-fixture-coverage.t)
- [t/1315-isf-generated-composition-fixture-coverage.t](../../t/1315-isf-generated-composition-fixture-coverage.t)
- [t/1316-isf-rule-resource-fixture-coverage.t](../../t/1316-isf-rule-resource-fixture-coverage.t)
- [t/1318-isf-shift-left-explicit-width.t](../../t/1318-isf-shift-left-explicit-width.t)
- [t/1319-isf-fifo-datapath-fixture-coverage.t](../../t/1319-isf-fifo-datapath-fixture-coverage.t)
- [t/1320-isf-fifo-controller-fixture-coverage.t](../../t/1320-isf-fifo-controller-fixture-coverage.t)
- [t/1321-isf-fifo-library-fixture-coverage.t](../../t/1321-isf-fifo-library-fixture-coverage.t)
- [t/1322-isf-actor-network-static.t](../../t/1322-isf-actor-network-static.t)
- [t/1323-isf-check-json-failure-surface.t](../../t/1323-isf-check-json-failure-surface.t)
- [t/1324-isf-atl-fixture-coverage.t](../../t/1324-isf-atl-fixture-coverage.t)
- [t/1325-isf-atl-data-route-fixture-coverage.t](../../t/1325-isf-atl-data-route-fixture-coverage.t)
- [t/1326-isf-atl-pin-ingress-fixture-coverage.t](../../t/1326-isf-atl-pin-ingress-fixture-coverage.t)
- [t/1327-isf-atl-pin-egress-fixture-coverage.t](../../t/1327-isf-atl-pin-egress-fixture-coverage.t)
- [t/1328-isf-atl-trigger-wait-fixture-coverage.t](../../t/1328-isf-atl-trigger-wait-fixture-coverage.t)
- [t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t](../../t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t)
- [t/1330-isf-atl-resolved-child-fixture-coverage.t](../../t/1330-isf-atl-resolved-child-fixture-coverage.t)
- [t/1331-isf-timing-conventions.t](../../t/1331-isf-timing-conventions.t)
- [t/1332-isf-atl-doc-status-audit.t](../../t/1332-isf-atl-doc-status-audit.t)
- [t/1333-isf-interface-actor-param-widths.t](../../t/1333-isf-interface-actor-param-widths.t)
- [t/1334-isf-scalar-storage-actor-param-widths.t](../../t/1334-isf-scalar-storage-actor-param-widths.t)
- [t/1335-isf-bank-storage-actor-param-widths.t](../../t/1335-isf-bank-storage-actor-param-widths.t)
- [t/1336-isf-transaction-port-actor-param-widths.t](../../t/1336-isf-transaction-port-actor-param-widths.t)
- [t/1337-isf-bank-storage-actor-param-depths.t](../../t/1337-isf-bank-storage-actor-param-depths.t)
- [t/1338-isf-interface-actor-constant-widths.t](../../t/1338-isf-interface-actor-constant-widths.t)
- [t/1339-isf-scalar-storage-actor-constant-widths.t](../../t/1339-isf-scalar-storage-actor-constant-widths.t)
- [t/1340-isf-bank-storage-actor-constant-widths.t](../../t/1340-isf-bank-storage-actor-constant-widths.t)
- [t/1341-isf-bank-storage-actor-constant-depths.t](../../t/1341-isf-bank-storage-actor-constant-depths.t)
- [t/1342-isf-transaction-port-actor-constant-widths.t](../../t/1342-isf-transaction-port-actor-constant-widths.t)
- [t/1343-isf-data-op-static-width-sources.t](../../t/1343-isf-data-op-static-width-sources.t)
- [t/1344-isf-assemble-static-part-widths.t](../../t/1344-isf-assemble-static-part-widths.t)
- [t/1345-isf-actor-param-actor-constants.t](../../t/1345-isf-actor-param-actor-constants.t)
- [t/1346-isf-actor-param-actor-params.t](../../t/1346-isf-actor-param-actor-params.t)
- [t/1347-isf-transaction-param-actor-static-defaults.t](../../t/1347-isf-transaction-param-actor-static-defaults.t)
- [t/1348-isf-transaction-param-transaction-params.t](../../t/1348-isf-transaction-param-transaction-params.t)
- [t/1349-isf-actor-param-package-constants.t](../../t/1349-isf-actor-param-package-constants.t)
- [t/1350-isf-transaction-param-package-constants.t](../../t/1350-isf-transaction-param-package-constants.t)
- [t/1351-isf-activation-param-package-constants.t](../../t/1351-isf-activation-param-package-constants.t)
- [t/1352-isf-library-use-package-constants.t](../../t/1352-isf-library-use-package-constants.t)
- [t/1353-isf-interface-package-constant-widths.t](../../t/1353-isf-interface-package-constant-widths.t)
- [t/1354-isf-scalar-storage-package-constant-widths.t](../../t/1354-isf-scalar-storage-package-constant-widths.t)
- [t/1355-isf-bank-storage-package-constant-widths.t](../../t/1355-isf-bank-storage-package-constant-widths.t)
- [t/1356-isf-bank-storage-package-constant-depths.t](../../t/1356-isf-bank-storage-package-constant-depths.t)
- [t/1357-isf-transaction-port-package-constant-widths.t](../../t/1357-isf-transaction-port-package-constant-widths.t)
- [t/1358-isf-data-op-package-constant-widths.t](../../t/1358-isf-data-op-package-constant-widths.t)
- [t/1359-isf-wait-package-constant-counts.t](../../t/1359-isf-wait-package-constant-counts.t)
- [t/1360-isf-repeat-package-constant-counts.t](../../t/1360-isf-repeat-package-constant-counts.t)
- [t/1361-isf-latency-package-constant-bounds.t](../../t/1361-isf-latency-package-constant-bounds.t)
- [t/1363-isf-watchdog-package-constant-limits.t](../../t/1363-isf-watchdog-package-constant-limits.t)
- [t/1367-isf-data-op-transaction-param-widths.t](../../t/1367-isf-data-op-transaction-param-widths.t)
- [t/1368-isf-transaction-port-transaction-param-widths.t](../../t/1368-isf-transaction-port-transaction-param-widths.t)
- [t/1369-isf-timing-param-activation-override-gates.t](../../t/1369-isf-timing-param-activation-override-gates.t)
- [t/1370-isf-data-op-activation-override-width-gate.t](../../t/1370-isf-data-op-activation-override-width-gate.t)
- [t/1371-isf-transaction-port-activation-override-width-gate.t](../../t/1371-isf-transaction-port-activation-override-width-gate.t)
- [t/1372-isf-cross-domain-repeat-body-do-diagnostic.t](../../t/1372-isf-cross-domain-repeat-body-do-diagnostic.t)
- [t/1373-isf-timing-param-sub-axis-diagnostic.t](../../t/1373-isf-timing-param-sub-axis-diagnostic.t)
- [t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t](../../t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t)
- [t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t](../../t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t)
- [t/1376-isf-book-example-lowering-audit.t](../../t/1376-isf-book-example-lowering-audit.t)
- [t/1378-isf-enum-type-relationship.t](../../t/1378-isf-enum-type-relationship.t)
- [t/1379-isf-loop-contained-repeat-body-local-do.t](../../t/1379-isf-loop-contained-repeat-body-local-do.t)
- [t/1380-isf-loop-contained-repeat-body-generated-do.t](../../t/1380-isf-loop-contained-repeat-body-generated-do.t)
- [t/1381-isf-deeper-nested-repeat-body-local-do.t](../../t/1381-isf-deeper-nested-repeat-body-local-do.t)
- [t/1382-isf-deeper-nested-repeat-body-generated-do.t](../../t/1382-isf-deeper-nested-repeat-body-generated-do.t)
- [t/1383-isf-loop-and-deeper-repeat-body-spawn.t](../../t/1383-isf-loop-and-deeper-repeat-body-spawn.t)
- [t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t](../../t/1384-isf-loop-and-deeper-repeat-body-multi-pending-awaitany.t)
- [t/1385-isf-multi-unknown-width-fail-closed-terminal.t](../../t/1385-isf-multi-unknown-width-fail-closed-terminal.t)
- [t/1386-isf-activation-crossing-declaration.t](../../t/1386-isf-activation-crossing-declaration.t)
- [t/1387-isf-cross-domain-activation-handshake-lowering.t](../../t/1387-isf-cross-domain-activation-handshake-lowering.t)
- [t/1388-isf-when-body-local-do.t](../../t/1388-isf-when-body-local-do.t)
- [t/1389-isf-loop-early-exit.t](../../t/1389-isf-loop-early-exit.t)
- [t/1390-isf-procedures.t](../../t/1390-isf-procedures.t)
- [t/1391-isf-local-variables.t](../../t/1391-isf-local-variables.t)
- [t/1393-isf-loop-continue.t](../../t/1393-isf-loop-continue.t)
- [t/1394-isf-for-loop.t](../../t/1394-isf-for-loop.t)
- [t/1395-isf-nested-counted-repeat.t](../../t/1395-isf-nested-counted-repeat.t)
- [t/1396-isf-cond.t](../../t/1396-isf-cond.t)
- [t/1397-isf-register-reset-value-surface.t](../../t/1397-isf-register-reset-value-surface.t)
- [t/1398-isf-storage-reset-value.t](../../t/1398-isf-storage-reset-value.t)
- [t/1399-isf-compound-assign.t](../../t/1399-isf-compound-assign.t)
- [t/1401-isf-bit-ops.t](../../t/1401-isf-bit-ops.t)
- [t/1402-isf-bit-test.t](../../t/1402-isf-bit-test.t)
- [t/1403-isf-set-field.t](../../t/1403-isf-set-field.t)
- [t/1404-isf-when-field.t](../../t/1404-isf-when-field.t)
- [t/1406-isf-select.t](../../t/1406-isf-select.t)
- [t/1407-isf-minmax.t](../../t/1407-isf-minmax.t)
- [t/1408-isf-rotate.t](../../t/1408-isf-rotate.t)
- [t/1409-isf-swap.t](../../t/1409-isf-swap.t)
- [t/1410-isf-assert-carrier.t](../../t/1410-isf-assert-carrier.t)
- [t/1411-isf-assert-emit.t](../../t/1411-isf-assert-emit.t)
- [t/1412-isf-property-implication.t](../../t/1412-isf-property-implication.t)
- [t/1413-isf-trigger-anchor.t](../../t/1413-isf-trigger-anchor.t)
- [t/1416-isf-trigger-anchor-ref.t](../../t/1416-isf-trigger-anchor-ref.t)
- [t/1417-isf-property-sampled-value.t](../../t/1417-isf-property-sampled-value.t)
- [t/1418-isf-property-window-range.t](../../t/1418-isf-property-window-range.t)
- [t/1419-isf-control-flow-effect-inventory.t](../../t/1419-isf-control-flow-effect-inventory.t)
- [t/1421-isf-control-flow-effect-checks.t](../../t/1421-isf-control-flow-effect-checks.t)
- [t/1422-isf-control-flow-child-plan.t](../../t/1422-isf-control-flow-child-plan.t)
- [t/1423-isf-control-flow-lifetime-checks.t](../../t/1423-isf-control-flow-lifetime-checks.t)
- [t/1424-isf-control-flow-domain-binding-effects.t](../../t/1424-isf-control-flow-domain-binding-effects.t)
- [t/1425-isf-control-flow-validator-effect-migration.t](../../t/1425-isf-control-flow-validator-effect-migration.t)
- [t/1426-isf-control-flow-same-domain-validator-effect-migration.t](../../t/1426-isf-control-flow-same-domain-validator-effect-migration.t)
- [t/1427-isf-control-flow-activation-domain-validator-effect-migration.t](../../t/1427-isf-control-flow-activation-domain-validator-effect-migration.t)
- [t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t](../../t/1428-isf-control-flow-binding-endpoint-validator-effect-migration.t)
- [t/1429-isf-control-flow-binding-expression-validator-effect-migration.t](../../t/1429-isf-control-flow-binding-expression-validator-effect-migration.t)
- [t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t](../../t/1430-isf-control-flow-rule-trigger-validator-effect-migration.t)
- [t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t](../../t/1431-isf-control-flow-rule-trigger-binding-validator-effect-migration.t)
- [t/1432-isf-loop-pending-spawn-local-do-effect-widening.t](../../t/1432-isf-loop-pending-spawn-local-do-effect-widening.t)
- [t/1433-isf-until-pending-spawn-local-do-effect-widening.t](../../t/1433-isf-until-pending-spawn-local-do-effect-widening.t)
- [t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t](../../t/1434-isf-while-pending-spawn-local-do-awaitany-effect-widening.t)
- [t/1453-isf-storage-field-metadata.t](../../t/1453-isf-storage-field-metadata.t)
- [t/1464-isf-verification-output-uvm-passive-monitor.t](../../t/1464-isf-verification-output-uvm-passive-monitor.t)
- [t/1465-isf-verification-output-vhdl-observation-package.t](../../t/1465-isf-verification-output-vhdl-observation-package.t)
- [t/1476-isf-output-default-reset.t](../../t/1476-isf-output-default-reset.t)
- [t/1510-isf-multibit-loop-predicate-truthiness.t](../../t/1510-isf-multibit-loop-predicate-truthiness.t)
- [t/1542-isf-rule-transaction-named-drive-priority-readiness.t](../../t/1542-isf-rule-transaction-named-drive-priority-readiness.t)
- [t/1544-isf-assert-nested-bitwise-precedence-readiness.t](../../t/1544-isf-assert-nested-bitwise-precedence-readiness.t)

## 12. Explicitly Deferred

- Reusable ISF library behavior beyond the shipped resolver/review-artifact,
  generated-top system binding, actor-owned fixed-storage, and expression-valued
  rule-guard/disjoint-rule/FIFO-controller-matrix/bank-access/fixed FIFO
  library fixture/catalog slices:
  standalone transaction/drive exports,
  package/imported constants outside the shipped qualified actor parameter,
  generated-child transaction parameter default, generated activation
  override, reusable-library use-site override, actor interface width,
  transaction-local port width, actor-owned scalar storage width,
  actor-owned bank storage width, and actor-owned bank storage depth
  scalar-constant subsets, transaction latency min/max bound scalar-constant
  subset, derived parameter expressions,
  transaction-port dimensions beyond positive literals, same-transaction
  scalar parameter defaults on generated child or direct/non-generated
  transactions, actor-local scalar parameters, actor constants, qualified
  package scalar constants, and scalar type aliases,
  data-operation width evidence beyond positive literals, actor-local scalar
  parameters, actor constants, qualified package scalar constants, and
  same-transaction scalar parameter defaults on generated child or
  direct/non-generated transactions,
  memory-array backend emission, and
  library actors that import other libraries.
- Unconditional transaction delay beyond the shipped non-negative literal,
  actor-constant, actor-parameter, same-transaction scalar parameter,
  qualified package scalar constant, bounded runtime scalar, and bounded
  runtime expression `(wait N)` shapes:
  unknown-width expressions and any remaining predecessor-edge or
  sample-incompatible successor splits, plus per-activation wait-state
  specialization beyond same-value generated child activation overrides,
  remain deferred until their timing and diagnostics are implemented.
  Mismatched generated child activation overrides for wait-count parameters
  fail closed.
- Transaction repeat counts beyond the shipped non-negative decimal literal,
  non-negative actor-constant, non-negative actor-scalar-parameter,
  non-negative same-transaction scalar-parameter, non-negative qualified
  package scalar constant, and known-width runtime scalar shapes:
  cross-transaction parameters, non-scalar actor/transaction parameters,
  arbitrary expressions, aggregate or path package constants, use-site
  parameter-specialized counter sizing beyond same-value generated child
  activation overrides, generated-top respecialization, static zero repeat
  bodies that contain child activation before artifact pruning is specified,
  and repeat-body widening remain deferred. Mismatched generated child
  activation overrides for repeat-count parameters fail closed.
- Transaction latency bounds beyond the shipped positive decimal literal,
  same-transaction scalar-parameter, positive actor-constant, positive
  actor-scalar-parameter, and qualified package scalar-constant
  `(min ...)`/`(max ...)` shapes: cross-transaction parameters, runtime
  signals, arbitrary expressions, aggregate or path package constants,
  stage-local latency, non-scalar actor/transaction parameters, and use-site
  parameter-specialized counter sizing beyond same-value generated child
  activation overrides remain deferred until a separate
  specialization/scheduling policy is selected. Mismatched generated child
  activation overrides for latency-bound parameters fail closed.
- Watchdog limits beyond the shipped positive decimal literal, positive
  actor-constant, positive actor-scalar-parameter, qualified package
  scalar-constant actor-level/await-local shapes, and same-transaction scalar
  parameter top-level await-local shapes: actor-level transaction parameters,
  nested control-flow transaction parameter watchdog limits, runtime signals,
  arbitrary expressions, aggregate or path package constants, distinct
  per-await limits in one transaction, cross-domain watchdog policy, dynamic
  watchdog limits, and parameter-specialized watchdog counter sizing beyond
  same-value generated child activation overrides remain deferred. Mismatched
  generated child activation overrides for top-level await-local watchdog
  parameters fail closed.
- Runtime division/modulo safety beyond literal-zero, actor-constant-zero,
  actor-parameter-zero, and same-transaction-parameter-zero divisor
  rejection: proving arbitrary dynamic scalar divisor expressions or
  use-site-specialized parameter divisors nonzero remains deferred until
  range/dataflow or specialization evidence is specified.
- Transaction binding surfaces beyond scalar and expression-valued `do`,
  `spawn`, rule-trigger input bindings, and generated-child rule-trigger
  output bindings. Direct/local rule-trigger output bindings, explicit
  behavior-changing snapshot-vs-live timing conversion, broader static
  conflict diagnostics, richer report metadata beyond the shipped
  endpoint-kind, binding-timing, and authored timing-mode fields, and full
  expression width inference remain under `ISF-PORT-BINDING` and
  `ISF-ACTIVATION-BIND-EXPRESSIONS`.
- Transaction-local loop combinations beyond the shipped top-level
  `while`/`until` subset, the top-level repeat-body local `(do child)` subset,
  the top-level when-body nested repeat local/generated-child `(do child)`
  and static-parameter generated `(do child (params ...) [(bind ...)])`
  subset, the top-level switch-branch nested repeat local/generated-child
  `(do child)` and static-parameter generated
  `(do child (params ...) [(bind ...)])` subset,
  the top-level repeat-body generated-child `(do child)` subset, the top-level
  repeat-body generated
  `(do child (params ...) [(bind ...)] [(domain NAME)])` subset, and the
  top-level repeat-body spawn plus same-body `await_all`, single-pending
  `await_any`, or multi-pending `await_any` followed by same-body `await_all`
  drain subset with optional static `(params ...)`, optional `(bind ...)`, and
  optional declared same-domain `(domain NAME)` metadata, plus the top-level
  when-body nested repeat local `(do child)` or plain generated-child
  `(do child)` while generated nested spawns are pending before or after a
  prior multi-pending `await_any` observation, or static-parameter generated
  `(do child (params ...))` while generated nested spawns are pending before
  or after a prior multi-pending `await_any` observation, or static-parameter generated
  `(do child (params ...) (bind ...))` while generated nested spawns are
  pending, or static-parameter same-domain generated
  `(do child (params ...) [(bind ...)] (domain NAME))` while generated nested
  spawns are pending, before a later same-body `await_all` drain subset and
  the top-level switch-branch
  nested repeat local `(do child)` or plain generated-child `(do child)` while
  generated nested spawns are pending before or after a prior multi-pending
  `await_any` observation, or static-parameter generated
  `(do child (params ...))` while generated nested spawns are pending before
  or after a prior multi-pending `await_any` observation, or
  static-parameter generated `(do child (params ...) (bind ...))` while
  generated nested spawns are pending, or static-parameter same-domain
  generated `(do child (params ...) [(bind ...)] (domain NAME))` while
  generated nested spawns are pending, before a later same-body `await_all`
  drain subset: nested loops, loops under
  `when`/`switch`/`repeat`, cross-domain repeat-body `do`, and
  `while`/`until` loop bodies containing `do`,
  `spawn`, `await_all`, `await_any`, `stage`, or `contract` remain deferred
  until re-entry, child lifetime, and report semantics are specified.
- Old `(handshake ...)` semantics beyond validated ignored compatibility
  parsing.
- The removed `(assign ...)` action keyword; authored transaction uses fail
  closed with a migration-specific unsupported-clause diagnostic. It is not
  auto-mapped to `(set ...)`, `(update ...)`, `(drive ...)`, rule actions, or
  `(complete ...)` because the old keyword does not carry enough timing intent.
- Broader generated-child top instantiation surfaces beyond the covered ISF
  spawn and parameterized blocking `do` patterns. The current generated top
  covers scheduled parent/child wiring, start/done handoff, explicit
  port-binding handoffs, named-drive handoff, and spawn/generated-`do`
  parameter overrides for the shipped fixture set.
- Enforced resource arbitration beyond the shipped priority-arbitrated
  `rule_slot`, `output_bundle`, `transaction_start`, and `storage_port`
  rule-user cases plus bounded `rule_slot`/`round_robin`,
  `output_bundle`/`round_robin`, `transaction_start`/`round_robin`, and
  `storage_port`/`round_robin`: backlog resource kinds,
  `interface_bundle`,
  `named_drive`, `child_instance`, generated-child transaction starts,
  generated-child storage arbitration, actor-network trigger resources,
  actor-network endpoint users, output-target users, bank-root or aggregate
  output-bundle/storage-port member domains, inferred undeclared member
  targets, multi-capacity resources, dynamic resource names, and
  transaction/storage lifetime ownership remain deferred.
- Priority resolution beyond the currently shipped same-target rule/rule,
  rule-over-transaction, and transaction-over-rule data-conflict cases, plus
  the resource-level bound-rule grant case.
- Alternate rule assignment operators beyond the shipped flopped rule
  `set`/shorthand assignment family.
- Transaction `(stage ...)` forms beyond the shipped top-level ready/valid
  barrier: nested stages, stage-local latency/compute bodies, multiple
  endpoints, registered-valid variants, and skid buffers remain deferred.
- Temporal monitor forms beyond the shipped top-level bounded-eventually
  `(assert (monitor (within signal N)))` subset with positive decimal literal, positive actor-constant,
  positive actor-scalar-parameter, qualified package scalar-constant,
  generated-child or direct same-transaction scalar-parameter windows, and
  same-value generated child activation-site overrides for those
  contract-window parameters. Mismatched activation-site overrides still fail
  closed; override-specialized contract-window lowering remains deferred.
- Rich storage-class optimization in schedule reports.
- ISF enum/type/aggregate parity beyond the shipped scalar type-alias subset,
  actor-constant enum member references, direct transaction `set` RHS enum
  member values and expression operands, transaction `switch` branch enum
  values, transaction `when`/`while`/`until` condition expression enum member
  operands, standalone transaction `when`/`while`/`until` enum member
  conditions, transaction `switch` selector enum member values, rule guard
  expression enum member operands, standalone rule guard enum member values,
  scalar rule assignment RHS enum member values and expression operands,
  scalar drive body RHS enum member values and expression operands,
  scalar drive-call actual enum member values,
  drive-call actual expression enum member operands, actor scalar
  parameter default enum member values, actor aggregate/list parameter default
  enum member leaves, actor parameter default scalar and aggregate/list leaves
  backed by declared actor constants, actor parameter default scalar and
  aggregate/list leaves backed by earlier scalar actor parameters, generated
  child transaction scalar parameter default enum member values, generated
  child transaction aggregate/list parameter default enum member leaves,
  generated child transaction parameter default scalar and aggregate/list
  leaves backed by declared actor constants, actor-local scalar parameter
  defaults, earlier scalar transaction parameter defaults, or qualified
  imported package scalar constants, scalar
  activation parameter override enum member values, activation aggregate/list
  override enum member leaves, activation parameter override scalar and
  aggregate/list leaves backed by qualified imported package scalar constants,
  reusable-library use-site parameter override
  enum member values and leaves plus importing-actor constant/scalar-parameter
  values and leaves and qualified imported package scalar constants, inline
  drive assignment RHS enum member
  values and expression operands, actor-owned aggregate storage variable carriers,
  transaction `set` RHS aggregate leaf reads, transaction `set` RHS expression
  aggregate leaf operands, transaction condition aggregate leaf values and
  expression operands, transaction `switch` branch aggregate leaf values, transaction
  `set` target aggregate leaf writes,
  rule assignment target aggregate leaf writes, rule assignment RHS aggregate
  leaf values and expression operands, rule guard expression aggregate leaf
  operands, standalone rule guard aggregate leaf values, drive target aggregate
  leaf writes, drive body RHS aggregate leaf values and expression operands,
  inline drive assignment RHS aggregate leaf values and expression operands,
  inline drive target aggregate leaf writes, drive-call actual aggregate leaf
  values and expression operands,
  aggregate/list parameter-literal, and data-operation evidence model. Enum
  member references in contexts not explicitly listed above as shipped remain
  deferred.
  Aggregate interface/transaction/bank carriers, aggregate member paths outside
  direct transaction `set` RHS values, direct transaction `set` target tokens,
  transaction condition scalar values or expression operands, transaction
  `switch` selectors or branch values, rule assignment target tokens, rule assignment RHS
  values/expression operands, rule guard scalar values/expression operands, drive target
  tokens, drive body RHS scalar values/expression operands, inline drive
  target tokens, inline drive assignment RHS scalar values/expression operands,
  or drive-call actual scalar values/expression operands,
  aggregate paths in transaction condition expression operator position, rule
  assignment RHS, rule guard, drive body RHS expression, inline drive RHS
  expression, or drive-call actual expression operator position,
  subaggregate updates/operands, aggregate field/slice/update lowering, and broad
  aggregate/record width inference remain deferred to future task-tree
  ownership.
- Treating the schedule JSON as a fully frozen public schema beyond the bounded
  key families advertised by `embedding.isf_public_interface`.
