# AXI Manager Core Backlog

Read-data interleaving queue readiness audit:
[AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.82`, report/static residue
alignment for the covered generated auto-ID multi-beat-by-RID subset. The
current public multi-beat sample already has bounded generated
`multi_beat_by_rid` output-bank behavior through generated same-ID avoidance,
matched-`RID` response demux, independent per-transaction beat counters,
output banks, valid masks, length outputs, and scalar aggregate status state.

The next slice is not new queue behavior. It should remove over-broad
`read_data_interleaving` residue from `response_demux` and
`same_id_ordering` only for that covered generated auto-ID subset, while
preserving `concrete_id_same_id_ordering`, `per_id_issue_order_queues`,
broader `bursts`, queued/blocking policy, profile aliases, full-manager
behavior, verification-code generation, direct backend lowering, and VHDL as
deferred work.

Read-data interleaving residue alignment:
[AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.82`. The public multi-beat sample
now reports:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue: [bursts]
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
  - bursts
```

Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. The report
predicate removes `read_data_interleaving` only when generated read same-ID
avoidance, generated burst-last read response demux, matched-read-beat
counting, `multi_beat_by_rid`, per-transaction output banks, valid masks,
length outputs, and generated multi-beat output-bank behavior are all present.
The follow-up owner was `IAL2-FEATURE-COMPLETENESS-FRONTIER.83`, a selector
for the remaining AXI manager residue owner.

Post-interleaving alignment selector:
[AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.84`, AXI burst payload/output
readiness. After `.82`, `bursts` is the only remaining `response_demux`
residue and is still present in `same_id_ordering`, while the public
multi-beat sample already has burst-last `RLAST` demux, raw ARLEN capture,
beat-count/RLAST runtime validation, per-beat output banks, valid masks,
length outputs, and scalar aggregate `RRESP`.

Burst payload/output readiness audit:
[AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.84`. The selected per-beat
output-bank contract is already the bounded burst payload/output shape for the
covered generated auto-ID multi-beat subset: generated burst-last response
demux, raw ARLEN capture, runtime beat-count/RLAST validation,
per-transaction data/status lanes, valid masks, length outputs, scalar status
output, and generated same-ID avoidance are present.

The selected follow-up owner was `IAL2-FEATURE-COMPLETENESS-FRONTIER.85`,
report/static `bursts` residue alignment for that covered subset. Packed
burst payload outputs, full burst assembly, aggregate-only status shapes,
authored concrete-ID same-ID ordering, per-ID queues, queued/blocking policy,
profile aliases, full-manager behavior, verification-code generation, direct
backend lowering, and VHDL remain deferred.

Burst residue alignment:
[AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE](../../AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.85`. The public multi-beat sample
now reports:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue: []
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. The report
predicate removes `bursts` only when generated read same-ID avoidance,
generated burst-last read response demux, ARLEN-derived expected beats,
runtime beat-count/RLAST validation, matched-read-beat counting,
`multi_beat_by_rid`, per-transaction output banks, full configured
data/status lanes, valid masks, length outputs, and generated multi-beat
output-bank behavior are all present. Scalar `RRESP` aggregation is not
required for this movement because per-beat status lanes are generated.

The selected follow-up owner was `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`, the
next AXI manager feature-completeness selector. It also carried the IAL2 factoring
question: keep common IAL2 constructs to a small semantic core where reuse is
proven across multiple profiles, and keep protocol/platform-specific
vocabulary profile-local until evidence justifies promotion. Packed/full
burst assembly, aggregate-only status shapes, authored concrete-ID same-ID
ordering, per-ID queues, queued/blocking policy, profile aliases,
full-manager behavior, verification-code generation, direct backend lowering,
and VHDL remain deferred.

Post-burst-residue selector:
[AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.87`, AXI concrete-ID same-ID ordering
readiness. The public multi-beat sample now leaves only
`concrete_id_same_id_ordering` and `per_id_issue_order_queues` under
`same_id_ordering.residue`, while concrete-ID samples still keep
`same_id_ordering` under `id_response_rule_engine.residue`.

`.87` was selected to decide whether the next implementation could be a
conservative concrete-ID same-ID constraint, report/static classification,
public same-ID policy, or whether generated per-ID issue-order queue substrate
was required first. The selector also records the IAL2 factoring stance: keep common IAL2
constructs to a small semantic core only when reuse is proven across multiple
profiles. AXI same-ID ordering remains AXI profile vocabulary until another
profile proves the same semantic need.

Concrete-ID same-ID readiness audit:
[AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.87`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.88`, conservative fail-closed static
validation for multiple concrete-ID transactions in the same read or write
response family that use the same concrete ID value. Existing concrete-ID
assertions prove request/response ID equality only; they do not prove same-ID
response issue order without a per-ID issue-order record, queue, scoreboard, or
selected static rejection rule.

Concrete-ID same-ID static validation first slice:
[AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE](../../AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.88`. FSMGen now rejects unsupported
same-family concrete-ID reuse before emitting concrete-ID equality assertions:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue
```

Read and write ID families stay separate, duplicate concrete assertion event
diagnostics keep their previous precedence, generated auto-ID same-ID avoidance
is unchanged, and valid single-concrete-ID samples keep their generated
`.isf`, `.fsm`, SystemVerilog, and schedule-report residue behavior. Accepted
concrete-ID same-ID ordering behavior, per-ID issue-order queues, scoreboards,
public same-ID reuse policy, full-manager behavior, direct backend lowering,
and VHDL remain deferred. This advanced the frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.89`, a selector for the remaining AXI
manager feature-completeness residue after this static validation.

Post concrete-ID static validation selector:
[AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.89`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.90`, AXI per-ID issue-order queue
readiness, before any accepted concrete-ID same-ID reuse behavior or queue
implementation. The selector records that post-`.88` residue is still honest:
the public multi-beat sample still lists `concrete_id_same_id_ordering` and
`per_id_issue_order_queues`, while concrete-ID samples still keep
`same_id_ordering` under `id_response_rule_engine.residue`. Direct queue
behavior remains gated by public same-ID reuse policy, queue/scoreboard
substrate, concrete response-demux prerequisites, report/static residue
refinement, and any smaller IAL1/IAL0/SystemVerilog prerequisites.

Per-ID issue-order queue readiness audit:
[AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.90`. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.91`, AXI same-ID reuse policy contract
selection, before parser/report metadata or generated queue behavior. The
audit finds that existing lower layers can carry bounded scalar or bank state,
guarded rules, pulses, and assertions, so a smaller IAL1/IAL0/SystemVerilog
prerequisite is not the next blocker. The public `.ppif` manager-capacity
surface still lacks a same-ID reuse policy, and concrete-ID response demux
cannot distinguish two same-ID transactions without selected issue-order
state. Current residue remains honest.

Same-ID reuse policy contract selection:
[AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.91`. It selects an optional
AXI-profile-local top-level clause under `manager-capacity-status`:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse reject))
  (write
    (concrete-id-reuse reject)))
```

The first accepted policy is `reject`: it documents that authored concrete-ID
same-ID reuse is intentionally rejected by public source policy and does not
accept same-ID reuse, generate queues, or change HDL behavior for valid
sources. Omitted policy preserves today's fail-closed diagnostic. The selector
advances to `IAL2-FEATURE-COMPLETENESS-FRONTIER.92`, parser/report metadata
and static validation for explicit reject policy before any
`issue-order-queue` or `scoreboard` behavior.

Same-ID reject policy first slice:
[AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.92`. The PPIF adapter now accepts
one optional `same-id-ordering` clause under `manager-capacity-status`; each
selected `read` or `write` family must contain exactly one
`(concrete-id-reuse reject)` policy. Duplicate top-level clauses, duplicate
family arms, duplicate policy clauses, missing policy clauses, unsupported
families, and unsupported values such as `scoreboard` fail closed.

The public sample is
`ppif/axi_manager_capacity_status_same_id_reject_policy.ppif`. It reports the
selected policy without claiming generated queue behavior:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: reject
      enforcement: static_validation
      accepted_same_id_reuse: false
      generated_queue_behavior: false
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

Generated `.isf`, `.fsm`, and SystemVerilog stay unchanged for valid
single-concrete-ID sources. Omitted policy preserves the `.88` diagnostic:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue
```

Explicit `reject` emits a policy-specific static validation diagnostic:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering.read concrete-id-reuse reject policy rejects concrete same-ID reuse
```

This advanced the frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.93`, the next AXI manager selector before
accepted same-ID reuse, generated per-ID issue-order queues, scoreboards,
concrete-ID response demux, queued/blocking policy, full-manager behavior,
direct backend lowering, or VHDL.

Post same-ID reject policy selector:
[AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.93`. Live reports confirm `.92`
is policy-only: the reject-policy sample reports
`same_id_ordering.mode: concrete_id_reuse_policy`,
`generated_behavior: false`, read policy `reject`, and
`generated_queue_behavior: false`; generated auto-ID samples still avoid
same-ID concurrency rather than accepting concrete-ID same-ID reuse.

The selector advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.94`, public AXI same-ID issue-order queue
policy contract selection. `.94` must define the `issue-order-queue` public
source spelling, read/write family scope, queue depth bounds, enqueue/dequeue
semantics, queue-head response-demux behavior, diagnostics, report vocabulary,
validation gates, and rollback boundary before parser/report metadata or
generated queue behavior can ship.

Same-ID issue-order queue contract selection:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.94`. It keeps the existing
AXI-profile-local `same-id-ordering` shape and selects the family-local policy
value:

```lisp
(same-id-ordering
  (read
    (concrete-id-reuse issue-order-queue))
  (write
    (concrete-id-reuse issue-order-queue)))
```

The first queue contract does not add a public `queue-depth` clause. Queue
depth is bounded by the selected family's `max-pending` value and the number
of concrete transactions in that family using the same ID. Later generated
behavior must enqueue admitted transaction requests, keep a per-ID queue head,
dequeue only on queue-head response completion, and route same-ID responses by
queue-head transaction identity rather than ID-only matching. A metadata-only
slice must not claim `accepted_same_id_reuse: true`; that report value is
reserved for generated queue-head behavior.

`.94` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`, AXI same-ID
issue-order queue behavior readiness, because the current generated
response-demux behavior is auto-ID-oriented and accepting duplicate
concrete-ID transactions before queue-head demux exists would be ambiguous.

Same-ID issue-order queue behavior readiness:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`. Generated queue-head behavior
is not the next safe slice: current response demux is auto-ID selected-ID
matching, concrete transactions have no queue-head state, and queue enqueue
needs an admitted per-transaction request boundary.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.96`, metadata-first
parser/report support for `issue-order-queue`. That slice may accept the
spelling and report `implementation_status: selected_not_generated`,
`accepted_same_id_reuse: false`, and `generated_queue_behavior: false`.
Duplicated concrete same-ID transactions must still fail closed until
generated queue-head behavior exists.

Same-ID issue-order queue metadata first slice:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.96`. The PPIF adapter now accepts
`issue-order-queue` in the existing read/write `same-id-ordering`
`concrete-id-reuse` arms while keeping `scoreboard` unsupported.

The runnable sample is
`ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif`. In
the `.96` metadata-first slice it reported selected-not-generated metadata
without changing generated `.isf`, `.fsm`, or SystemVerilog:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: not_generated
      implementation_status: selected_not_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

Selecting `issue-order-queue` is not accepted same-ID reuse yet. If two
concrete read transactions reuse ID value 3 under the selected read family,
FSMGen still rejects the source:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering.read concrete-id-reuse issue-order-queue policy is selected_not_generated, so concrete same-ID reuse remains unsupported until generated issue-order queue behavior ships
```

Generated queue-head behavior still needs admitted per-transaction enqueue
guards, per-ID queue state, queue-head response demux, and queue-specific
assertions before `accepted_same_id_reuse` can become true.

Same-ID issue-order queue admitted enqueue boundary audit:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.97`. Queue state and queue-head
response demux are still too broad for the next slice. The next safe
prerequisite is a named admitted-request boundary per concrete transaction in
selected `issue-order-queue` families.

The audit selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.98`, admitted request
pulse generation. The implementation ships the first generated prerequisite
for future queue state: one internal admitted-request pulse storage target and
one pulse rule per concrete transaction in a selected `issue-order-queue`
family. The pulse guard is derived from the transaction request event, current
direction pending storage, family `max-pending`, and same-cycle completion
fan-in. It does not use the generated `can_accept` status output as the source
of truth for queue enqueue.

Same-ID issue-order queue admitted request pulses first slice:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.98`. For the public sample, the
generated `.isf` now includes the admitted boundary:

```lisp
(var axi0_r0_admitted_request_pulse_q (width 1))

(rule axi0_r0_admitted_request
  (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
  (pulse axi0_r0_admitted_request_pulse_q))
```

The generated `.fsm` lowers the rule through the existing one-cycle delayed
pulse action:

```lisp
(<1 (axi0_r0_admitted_request_pulse_q 1))
```

For a selected family with more than one concrete transaction, FSMGen emits a
same-direction request mutual-exclusion assertion so the direction-level
pending counter cannot admit multiple concrete identities in one cycle:

```lisp
(assert (! (& axi0_r0_request axi0_r1_request))
  "axi0 read same-ID issue-order queue requests are mutually exclusive")
```

Current report metadata stays under `same_id_ordering` and remains explicit
that this is not generated queue behavior:

```yaml
same_id_ordering:
  mode: concrete_id_reuse_policy
  generated_behavior: false
  concrete_id_reuse_policy:
    read:
      policy: issue_order_queue
      enforcement: admitted_request_boundary
      implementation_status: admitted_request_pulses_generated
      accepted_same_id_reuse: false
      generated_queue_behavior: false
      admitted_request_boundary:
        guard_source: capacity_storage_and_completion_fanin
        pending_storage: axi0_pending_reads_q
        max_pending: 4
        completion_fanin: axi0_r0_complete
        selected_request_events:
          - axi0_r0_request
        generated_pulses:
          - transaction: r0
            tag: rd0
            concrete_id: 3
            request_event: axi0_r0_request
            pulse: axi0_r0_admitted_request_pulse_q
            rule: axi0_r0_admitted_request
            guard: (& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))
        generated_assertions: []
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
```

Duplicated concrete same-ID reuse remains fail-closed until per-ID queue
storage, enqueue/dequeue rules, queue-head response demux, and queue-specific
assertions ship. `.98` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.99`, the post-admitted-request-pulse AXI
manager selector.

Post-admitted request pulses next slice selection:
[AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.99`. The selector keeps the next
step as a readiness audit rather than direct queue-state implementation.
Admitted request pulses name the enqueue boundary, but accepted same-ID reuse
still requires bounded per-ID queue storage, enqueue/dequeue semantics,
queue-head response demux, duplicate-ID validation changes, queue assertions,
and report residue movement to be scoped together.

`.99` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.100`, AXI same-ID
issue-order queue state and queue-head demux readiness audit. That audit must
decide whether the next safe owner is queue-state/enqueue/dequeue behavior,
queue-head demux, report/static alignment, or a smaller helper prerequisite
before any generated behavior changes.

Same-ID issue-order queue state and demux readiness audit:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.100`. The audit confirms that
admitted request pulses are only the enqueue boundary. The selected public
same-ID sample still reports `accepted_same_id_reuse: false` and
`generated_queue_behavior: false`, and existing generated response demux
matches auto-ID busy/selected-ID state, including the read burst-last path.

Queue-head response demux cannot ship before queue identity state exists:
`BID` or `RID` selects the concrete ID queue, but the queue head selects the
authored transaction. Direct queue-state behavior is also still too broad
until grouping, bounds, storage shape, transaction identity encoding,
enqueue/dequeue event names, diagnostics, assertions, and report vocabulary
are selected. `.100` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.101`, bounded AXI same-ID issue-order
queue state representation selection. Accepted concrete same-ID reuse,
generated queue behavior, queue-head demux, direct backend lowering, and VHDL
remain deferred.

Same-ID issue-order queue state representation selection:
[AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.101`. The selected future
representation is `compact_onehot_transaction_slots`: each generated queue is
family-local and concrete-ID-value-local, uses compacted explicit slots, keeps
slot `0` as the head, and stores one transaction identity bit per
slot/transaction. Queue depth remains bounded by
`min(max-pending, concrete transaction inventory)`.

This representation stays inside the proven scalar IAL path. It avoids arrays,
dynamic indexed left-hand sides, hidden unbounded queues, and pointer modulo
arithmetic. Enqueue remains sourced only from admitted request pulses; dequeue
is named as a future `queue_dequeue_event` produced by queue-head response
demux. `.101` therefore does not select behavior implementation yet. It
advances the active frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`, AXI
same-ID queue-head response-demux contract selection, because the existing
public `response-demux` syntax and generated behavior are auto-ID-lifecycle
oriented.

Same-ID queue-head response-demux contract selection:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`. The selector reuses the
existing `response-demux` read/write family arms for concrete same-ID
queue-head demux rather than adding a new top-level clause. The queue-head
interpretation is selected only when the same family selects
`concrete-id-reuse issue-order-queue`, has duplicate concrete-ID groups, and
does not also require same-family auto-ID demux in this first contract.

The selected report modes are
`bounded_write_bid_queue_head_demux_contract` and
`bounded_read_rid_queue_head_demux_contract`. They remain
selected-not-generated until later behavior ships generated queue state and
queue-head demux together for the covered group. `.102` advances the active
frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.103`, AXI same-ID queue-head
response-demux metadata/static validation.

Same-ID queue-head response-demux metadata first slice:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.103`. FSMGen now accepts the
selected-not-generated metadata contract when the same family has
`concrete-id-reuse issue-order-queue`, at least one duplicate concrete-ID
group, and no same-family auto-ID demux. The runnable sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

Its report includes `bounded_read_rid_queue_head_demux_contract`,
`implementation_status: selected_not_generated`,
`transaction_completion_source: generated_queue_head_demux`,
`queue_state_representation: compact_onehot_transaction_slots`, and one
`same_id_issue_order_queues` group for concrete ID `3` with transactions
`r0` and `r1`. The same-ID policy also records
`response_demux_strategy: queue_head_issue_order`.

This is still not accepted same-ID runtime behavior:
`accepted_same_id_reuse` and `generated_queue_behavior` remain false, no queue
state or queue-head demux rules are generated, and read-data consumption of
selected-not-generated queue-head demux fails closed. `.103` advances the
active frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.104`, generated
same-ID queue state and queue-head behavior readiness.

Same-ID queue behavior readiness audit:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.104`. The audit confirms the
existing lower layers can already carry the first bounded generated behavior
shape: scalar storage, pulse actions, guarded rules, generated inputs and
outputs, Boolean/equality guards, constants, and generated assertions.

The audit still does not select direct runtime implementation. Queue state and
queue-head demux must be specified and shipped together for any covered group:
queue state needs a dequeue event from queue-head demux, and queue-head demux
needs queue-head transaction identity from queue state. Until that behavior
slice is selected and implemented, the `.103` sample remains
selected-not-generated, with `accepted_same_id_reuse` and
`generated_queue_behavior` false.

`.104` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.105`, first generated AXI same-ID queue
state and queue-head behavior slice selection.

Same-ID queue behavior first-slice selection:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.105`. The first generated behavior
implementation boundary is deliberately narrow: read family only, burst-last
queue-head demux, one duplicate concrete read-ID group, two read transactions,
computed depth `2`, no same-family auto-ID lifecycle, and no read-data
consumption.

The selected `.106` implementation must generate compact one-hot queue slots
and queue-head response-demux completion rules together. Covered read
transaction completion names become generated pulse outputs only for that
shape. Wider shapes remain selected-not-generated or fail closed until later
owners select them.

Same-ID queue behavior first slice:
[AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.106`. FSMGen now generates
runtime behavior for the selected public sample shape:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

For that sample, the generated IAL1 exposes `axi0_r0_complete` and
`axi0_r1_complete` as generated pulse outputs, treats `axi0_read_complete`,
`axi0_rid`, and `axi0_rlast` as generated inputs, declares compact one-hot
depth-2 queue slots for concrete read ID `3`, emits finite enqueue/dequeue and
same-cycle dequeue/enqueue update rules, and emits queue-head response-demux
rules:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r0_q)
  (pulse axi0_r0_complete))
```

The schedule report now marks both `response_demux.generated_behavior` and
`same_id_ordering.generated_behavior` true. The read concrete-ID reuse policy
reports `enforcement: generated_issue_order_queue`,
`implementation_status: generated_read_burst_last_queue_head_demux`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true`.

The same-ID queue report lists the concrete ID, depth, transaction order, slot
storage, enqueue pulses, generated update rules, and generated assertions.
Response-demux residue removes `generated_same_id_queue_head_demux`, and the
ID/response rule-engine residue removes `same_id_ordering` and
`response_demux` for this covered shape.

Post same-ID queue behavior next-slice selection:
[AXI_IAL2_MANAGER_POST_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.107`. The selector keeps the
current read burst-last behavior unchanged and chooses the next implementation
owner as `IAL2-FEATURE-COMPLETENESS-FRONTIER.108`: generated write-family
concrete same-ID queue-head behavior for one duplicate concrete write-ID group,
two write transactions, and computed depth `2`.

The selected write queue-head match is the write analogue of the shipped read
queue-head demux, without `RLAST`:

```text
axi0_write_complete
&& axi0_bid == 4'd3
&& axi0_write_id3_same_id_issue_order_slot0_w0_q
```

The `.108` slice later generated compact one-hot write queue slots, finite
write enqueue/dequeue/same-cycle update rules, generated write completion
pulse outputs, queue-head `BID` demux rules, queue assertions, and
report/residue movement only for that covered shape. `.110` later shipped the
read `single-beat` analogue, and `.124` later shipped multiple independent
read burst-last response-demux-only queue groups. `.140` later shipped
write-family multi-group response-demux-only queue-head behavior. Deeper
queues, read single-beat multiple-group queue-head behavior, same-family mixed
auto-ID, read-data over multiple queue groups, direct backend lowering, and
VHDL remain deferred.

Write same-ID queue-head response-demux behavior:
[AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.108`. The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_write_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif
```

The sample uses two write transactions, `w0` and `w1`, sharing concrete write
ID `3`, selected write `concrete-id-reuse issue-order-queue`, and generated
write response demux. FSMGen now emits admitted write enqueue pulses, compact
one-hot depth-2 queue slots, finite queue update rules, generated write
completion pulse outputs, queue-head `BID` demux rules, and queue/response
assertions for that covered shape.

The generated `w0` demux rule is:

```lisp
(rule axi0_w0_response_demux
  (& axi0_write_complete (== axi0_bid 4'd3)
     axi0_write_id3_same_id_issue_order_slot0_w0_q)
  (pulse axi0_w0_complete))
```

The write response-demux report marks
`generated_queue_behavior_boundary: generated_write_bid_queue_head_demux`.
The write same-ID policy reports
`implementation_status: generated_write_bid_queue_head_demux`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true`.
Check JSON and normalized semantic JSON match support accounting entry
`intent.ppif_axi_manager_capacity_status_write_same_id_queue_head_response_demux`.

The `.108` HDL gate also repaired verification-only assertion emission:
assertion condition rendering now inlines assertion-only intermediate
expressions before appending SVA, so both the read and write queue-head public
samples pass `--verify-hdl`.

The shipped same-ID queue behavior remains intentionally narrow. Read
`single-beat`, deeper or multiple duplicate-ID groups, same-family mixed
auto-ID plus concrete queue-head demux, read-data consumption of concrete
queue-head demux, generalized per-ID queues, direct backend lowering, and VHDL
remain deferred.
After `.108`, the frontier advanced to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.109`, the next same-ID queue behavior
expansion audit/selector before any broader queue-head behavior changes.

Post-write same-ID queue behavior next-slice selection:
[AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.110` as the next bounded behavior
slice. `.110` owns generated read `single-beat` concrete same-ID queue-head
response demux for exactly one duplicate read-ID group of two transactions at
depth 2. The generated head match should use the raw read response event,
concrete `RID`, and compact slot-0 transaction bit, without `RLAST`.
Read-data consumption, deeper or multiple duplicate-ID groups, same-family
mixed auto-ID plus concrete queue-head demux, generalized per-ID queues,
direct backend lowering, and VHDL remain deferred.

Read single-beat same-ID queue-head response-demux behavior:
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.110`. The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_single_beat_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif
```

The sample uses two read transactions, `r0` and `r1`, sharing concrete read ID
`3`, selected read `concrete-id-reuse issue-order-queue`, and generated read
single-beat response demux. FSMGen now emits admitted read enqueue pulses,
compact one-hot depth-2 queue slots, finite queue update rules, generated
read completion pulse outputs, queue-head `RID` demux rules, and
queue/response assertions for that covered shape. No `RLAST` signal is
generated or consumed.

The generated `r0` demux rule is:

```lisp
(rule axi0_r0_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3)
     axi0_read_id3_same_id_issue_order_slot0_r0_q)
  (pulse axi0_r0_complete))
```

The read response-demux report marks
`generated_queue_behavior_boundary: generated_read_single_beat_queue_head_demux`.
The read same-ID policy reports
`implementation_status: generated_read_single_beat_queue_head_demux`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true`.
Check JSON and normalized semantic JSON match support accounting entry
`intent.ppif_axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux`.

After `.110`, read-data consumption of concrete queue-head demux, deeper or
multiple duplicate-ID groups, same-family mixed auto-ID plus concrete
queue-head demux, generalized per-ID queues, direct backend lowering, and VHDL
remain deferred. Selector `.111`
[AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md)
chooses `IAL2-FEATURE-COMPLETENESS-FRONTIER.112`, AXI read-data consumption
of generated concrete same-ID queue-head demux readiness. Existing generated
read-data capture consumes generated auto-ID read response-demux completion
pulses, but current normalization still fail-closes when `read_data` consumes
concrete queue-head read demux. `.112` must decide whether the first safe
behavior slice can be bounded to read single-beat queue-head demux plus
single-beat `RDATA`/`RRESP` capture, or whether metadata/report alignment is
required first. Audit `.112`
[AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.113`, generated single-beat
read-data capture for the bounded read single-beat concrete same-ID
queue-head demux shape. No lowerer prerequisite is evident; `.113` must make
read-data coverage source-aware for generated queue-head completion signals
instead of only auto-ID transaction lists.

Queue-head read-data behavior first slice:
[AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
ships `IAL2-FEATURE-COMPLETENESS-FRONTIER.113`. The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_single_beat_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif
```

The implemented boundary is exactly one generated read single-beat concrete
same-ID queue-head demux with one duplicate read-ID group, two read
transactions, computed queue depth 2, and single-beat `read-data` capture.
FSMGen derives read-data transaction coverage from the generated queue-head
group and `generated_completion_signals`, then emits generated `RDATA` and
`RRESP` inputs plus per-transaction data/status outputs.

The read-data capture rules are ordinary guarded assignments driven by the
generated queue-head completion pulses:

```lisp
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))

(rule axi0_r1_read_data_capture axi0_r1_complete
  (axi0_r1_rdata axi0_rdata)
  (axi0_r1_rresp axi0_rresp))
```

The schedule report distinguishes this queue-head path with:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: true
  read:
    completion_validity: generated_queue_head_response_demux_completion_pulse
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_rdata
      - axi0_r0_rresp
      - axi0_r1_rdata
      - axi0_r1_rresp
```

The existing auto-ID read-data path keeps reporting
`generated_read_response_demux_completion_pulse`. Later queue-head slices
ship bounded burst-last last-beat capture, report-only raw-`ARLEN`
burst-length capture, runtime beat-count/`RLAST` validation, and bounded
multi-beat queue-head read-data output-bank behavior. Audit `.123` selected
`.124`, generated read burst-last response-demux-only queue-head behavior for
two or more duplicate concrete read-ID groups, each exactly two transactions
at computed depth `2`. The selected implementation keeps the existing
family-wide admitted-request onehot boundary. Read-data over multiple groups,
deeper queues, mixed same-family auto-ID plus concrete queue-head demux,
direct backend lowering, and VHDL remain deferred.

Queue-head last-beat read-data behavior:
[AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md)
ships generated last-beat `RDATA`/`RRESP` capture for the bounded read
burst-last concrete same-ID queue-head demux shape:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_last_beat_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif
```

The implementation reuses the generated `RID` plus `RLAST` queue-head demux
from:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif
```

and emits per-transaction last-beat capture rules:

```text
rule axi0_r0_read_data_capture:
  guard: axi0_r0_complete
  assignments:
    axi0_r0_last_rdata <- axi0_rdata
    axi0_r0_last_rresp <- axi0_rresp
```

The queue-head last-beat report value is:

```text
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
```

Existing auto-ID last-beat read-data keeps
`generated_read_response_demux_last_beat_completion_pulse`, and existing
queue-head single-beat read-data keeps
`generated_queue_head_response_demux_completion_pulse`. Queue-head runtime
beat-count/RLAST validation is shipped by `.119` for the bounded
queue-head last-beat burst-length shape. Multi-beat queue-head read-data,
deeper or multiple queue groups, mixed same-family auto-ID plus concrete
queue-head demux, generalized per-ID queues, direct backend lowering, and
VHDL remain deferred.

Post queue-head last-beat read-data selector:
[AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md)
selects generated raw-`ARLEN` burst-length capture for the bounded
queue-head last-beat read-data shape as `.117`.

Queue-head burst-length behavior:
[AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md)
ships that selected report-only raw-`ARLEN` capture behavior for the bounded
read burst-last concrete same-ID queue-head last-beat read-data shape:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_last_beat_same_id_queue_head_burst_length.sv ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif
```

The generated burst-length capture is request-bound:

```text
rule axi0_r0_burst_length_capture:
  guard: axi0_r0_request
  assignments:
    axi0_r0_arlen_q <- axi0_arlen
```

The queue-head last-beat payload capture remains completion-bound:

```text
rule axi0_r0_read_data_capture:
  guard: axi0_r0_complete
  assignments:
    axi0_r0_last_rdata <- axi0_rdata
    axi0_r0_last_rresp <- axi0_rresp
```

The queue-head burst-length report keeps the queue-head last-beat
completion-validity value and adds generated burst-length fields:

```text
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
read_data.read.burst_length_source: arlen_signal
read_data.read.burst_length_signal: axi0_arlen
read_data.read.burst_length_validation: report_only
read_data.read.burst_length_generated_behavior: true
read_data.read.generated_burst_length_storage:
  - axi0_r0_arlen_q
  - axi0_r1_arlen_q
read_data.read.generated_burst_length_rules:
  - axi0_r0_burst_length_capture
  - axi0_r1_burst_length_capture
```

The report-only queue-head burst-length sample does not generate beat-count
state or runtime assertions. The runtime-validation sibling now ships in
queue-head runtime validation behavior:
[AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md).

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.sv ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif
```

For that sample, the report keeps the queue-head last-beat completion validity
and adds generated runtime-validation artifacts:

```text
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
read_data.read.burst_length_validation: runtime_assertion
read_data.read.beat_count_validation_generated_behavior: true
read_data.read.beat_count_match_source:
  response_demux_matched_read_beat
read_data.read.generated_expected_beat_count_storage:
  - axi0_r0_expected_beats_q
  - axi0_r1_expected_beats_q
read_data.read.generated_beat_count_storage:
  - axi0_r0_read_beat_count_q
  - axi0_r1_read_beat_count_q
```

The matched beat source is the raw read response event plus concrete `RID`
plus active queue-head transaction identity. It is intentionally not the
`RLAST`-qualified generated completion pulse, so early/missing `RLAST`
assertions can reason about every matched beat.

Queue-head multi-beat read-data behavior:
[AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md)
ships generated multi-beat read-data output-bank behavior for the bounded
read burst-last concrete same-ID queue-head demux sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_multi_beat_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif
```

The lane capture rules use raw matched queue-head read beats plus the current
beat-count lane index, while queue dequeue and transaction completion remain
owned by the generated `RLAST`-qualified queue-head demux:

```text
rule axi0_r0_read_beat_0_capture:
  guard:
    axi0_read_complete
    and axi0_rid == 3
    and axi0_read_id3_same_id_issue_order_slot0_r0_q
    and not axi0_r0_request
    and axi0_r0_read_beat_count_q == 0
  assignments:
    axi0_r0_beat_rdata_0 <- axi0_rdata
    axi0_r0_beat_rresp_0 <- axi0_rresp
    axi0_r0_beat_valid <- 16'b0000000000000001
    axi0_r0_read_beats <- 5'd1
```

The report distinguishes this bounded queue-head multi-beat path with:

```text
read_data.read.capture_scope: multi_beat
read_data.read.completion_validity:
  generated_queue_head_response_demux_last_beat_completion_pulse
read_data.read.beat_match_source:
  response_demux_matched_read_beat
read_data.read.output_shape: per_beat_output_bank
read_data.read.valid_output: per_transaction_valid_mask
read_data.read.length_output: per_transaction_beat_count
read_data.read.status_aggregation: worst_observed
read_data.residue: []
response_demux.residue: []
```

Read-data over multiple queue groups, deeper queue groups, mixed same-family
auto-ID plus concrete queue-head demux, write-family or read single-beat
multiple-group queue-head behavior, packed burst-vector outputs, alternate
payload assembly, direct backend lowering, and VHDL remain deferred.

Post queue-head multi-beat selector:
[AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.123`, readiness audit for multiple independent read burst-last
depth-2 concrete same-ID queue-head response-demux groups. The selected audit
is response-demux-only: no read-data, no same-family auto-ID, no deeper
queues, no multiple response families, no packed outputs, no direct backend,
and no VHDL.

Multi-group queue-head response-demux readiness audit:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.124`, generated read burst-last response-demux-only queue-head
behavior for multiple duplicate concrete read-ID groups. The audit found the
planner and report paths already carry multiple groups, while the behavior
builder still has a one-group generation guard. `.124` must preserve the
family-wide admitted-request onehot boundary and must not enable read-data over
multiple groups, same-family auto-ID, deeper queues, direct backend lowering,
or VHDL.

Multi-group queue-head response-demux behavior:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.124`, generated read burst-last response-demux-only queue-head
behavior for multiple duplicate concrete read-ID groups. The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_multi_group_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
```

The sample uses two duplicate read-ID groups: `r0`/`r1` share concrete `RID`
`3`, and `r2`/`r3` share concrete `RID` `5`. FSMGen emits concrete-ID-scoped
compact one-hot queue storage, finite depth-2 transition rules, generated
completion pulse outputs, group-local response-state expressions,
`RLAST`-qualified queue-head response-demux rules, queue assertions,
response-demux assertions, and generated queue reports for both groups.

The generated `r2` demux rule is:

```lisp
(rule axi0_r2_response_demux
  (& axi0_read_complete (== axi0_rid 4'd5) axi0_rlast
     axi0_read_id5_same_id_issue_order_slot0_r2_q)
  (pulse axi0_r2_complete))
```

The report marks:

```text
response_demux.read.generated_queue_behavior_boundary:
  generated_read_burst_last_queue_head_demux
response_demux.read.generated_completion_signals:
  axi0_r0_complete
  axi0_r1_complete
  axi0_r2_complete
  axi0_r3_complete
response_demux.read.same_id_issue_order_queues:
  - concrete_id: 3
    transactions: [r0, r1]
    depth: 2
  - concrete_id: 5
    transactions: [r2, r3]
    depth: 2
response_demux.residue:
  read_data_interleaving
  bursts
```

The existing admitted-request boundary remains family-wide: one generated
`axi0_read_issue_order_queue_request_onehot0` assertion covers all selected
read request events. The slice does not claim simultaneous group-local
same-cycle enqueue support. The response-demux-only sample has no `read_data`
section; multi-group read-data support is documented in the later
multi-group queue-head read-data behavior slice. Same-family auto-ID plus
concrete queue-head demux, deeper queues, write-family or read single-beat
multiple-group queue-head behavior, direct backend lowering, and VHDL remain
deferred.

Post multi-group queue-head demux selector:
[AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.126`, readiness audit for read-data coverage over multiple
generated read burst-last concrete same-ID queue-head groups. The selector is
audit-only: generated read-data over multiple queue groups remains deferred
until the audit chooses whether the first behavior should cover last-beat,
multi-beat, or a narrower prerequisite.

Multi-group queue-head read-data readiness audit:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md)
selected `.127`, generated multi-group queue-head multi-beat read-data
output-bank behavior. The audit found the blocker was the exact-one-group
guard in read-data response-demux coverage, while response-state lookup,
matched-read-beat matching, output-bank generation, beat-count/`RLAST`
validation, valid-mask and length outputs, and scalar `RRESP` aggregation
already iterated or named artifacts by transaction.

Multi-group queue-head read-data behavior:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md)
ships `.127` for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`.
The generated path flattens the `RID` `3` `r0`/`r1` group and the `RID` `5`
`r2`/`r3` group into multi-beat read-data coverage, emits per-transaction
output-bank clearing, sixteen `RDATA`/`RRESP` lanes, valid-mask and length
outputs, scalar `RRESP` aggregation, raw `ARLEN` capture, and
beat-count/`RLAST` runtime validation, and reports `capture_scope:
multi_beat`, `completion_validity:
generated_queue_head_response_demux_last_beat_completion_pulse`,
`beat_match_source: response_demux_matched_read_beat`, `output_shape:
per_beat_output_bank`, and empty `read_data`/`response_demux` residue.

Post multi-group queue-head read-data selector:
[AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.129`, readiness audit for last-beat-only read-data over multiple
generated read burst-last concrete same-ID queue-head groups. The selector is
audit-only: the next owner must decide how to isolate scalar last-beat capture
from report-only/raw-`ARLEN`, runtime-validation-only, and multi-beat
output-bank variants before any behavior change. Report-only/runtime-only
multi-group variants outside the selected multi-beat output-bank shape,
deeper queues, same-family auto-ID plus concrete queue-head demux,
write/read-single-beat multi-group queue-head behavior, direct backend
lowering, and VHDL remain deferred.

Multi-group queue-head last-beat read-data readiness:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md)
selects `.130`, generated multi-group queue-head last-beat read-data capture.
That implementation shipped scalar `capture_scope last-beat`, no
`burst_length` metadata, and complete per-transaction `data_output` and
`status_output` bindings over two or more generated read burst-last depth-2
queue-head groups. Report-only raw-`ARLEN` multi-group scalar capture is now
shipped by `.132`; runtime beat-count/`RLAST` multi-group scalar validation
is shipped by `.135`.

Multi-group queue-head last-beat read-data behavior:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md)
ships `.130` for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`.
The generated path flattens the `RID` `3` `r0`/`r1` group and the `RID` `5`
`r2`/`r3` group into scalar last-beat read-data coverage, emits generated
`RDATA`/`RRESP` inputs, per-transaction last-beat data/status outputs, and
scalar capture rules guarded by generated queue-head last-beat completion
pulses. The report records `capture_scope: last_beat`,
`completion_validity:
generated_queue_head_response_demux_last_beat_completion_pulse`,
`burst_length_source: rlast_only`, `burst_length_validation: not_generated`,
transactions `r0`, `r1`, `r2`, `r3`, eight generated scalar outputs, four
generated capture rules, `response_demux.residue: read_data_interleaving,
bursts`, and the scalar last-beat read-data residue set. Report-only
raw-`ARLEN` is shipped by `.132`; the runtime-validation multi-group scalar
sibling is shipped by `.135`.

Post multi-group queue-head last-beat read-data selector:
[AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.132`, generated report-only raw-`ARLEN` burst-length capture for
the multi-group queue-head scalar last-beat read-data shape. That shipped
implementation is limited to `burst_length` metadata with `source arlen`,
signal width `8`, `encoding axlen-plus-one`, `capture request`, and
`validation report-only` over all generated read burst-last depth-2 queue-head
groups. Runtime beat-count/`RLAST` validation for the multi-group scalar shape
remains a separate deferred owner.

Multi-group queue-head burst-length behavior:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md)
ships `.132` for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`.
The generated path keeps the `RID` `3` `r0`/`r1` group and the `RID` `5`
`r2`/`r3` group in scalar last-beat read-data coverage, adds the shared
generated `axi0_arlen` input, and emits per-transaction raw-`ARLEN` storage
and request-guarded capture rules:

```text
axi0_r0_arlen_q, axi0_r1_arlen_q, axi0_r2_arlen_q, axi0_r3_arlen_q
axi0_r0_burst_length_capture, axi0_r1_burst_length_capture,
axi0_r2_burst_length_capture, axi0_r3_burst_length_capture
```

The public source uses a report-only `burst-length` clause:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

The report records `capture_scope: last_beat`,
`burst_length_source: arlen_signal`, `burst_length_validation: report_only`,
transactions `r0`, `r1`, `r2`, `r3`, one generated burst-length input, four
generated raw-`ARLEN` storage elements, and four generated burst-length rules.
Because validation is report-only, expected-beat storage, beat counters, and
beat-count/`RLAST` assertions remain absent from this sample; runtime
validation for the multi-group scalar shape is shipped by `.135`.

Post multi-group queue-head burst-length selector:
[AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md)
selects `.134`, readiness audit for generated runtime-validation multi-group
queue-head scalar last-beat read-data. The audit comes before behavior changes
because the next generated shape would combine scalar final outputs with
expected-beat storage, matched-beat counters, and beat-count/`RLAST`
assertions for every transaction across multiple queue groups. The current
evidence is split across `.132` report-only scalar multi-group capture, `.119`
one-group scalar runtime validation, and `.127` multi-group multi-beat runtime
validation, so `.134` must prove the scalar multi-group composition boundary
before implementation.

Multi-group queue-head runtime-validation readiness:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.135`, generated runtime-validation multi-group queue-head scalar
last-beat read-data. The audit found no new IAL1, IAL0, SystemVerilog,
direct-backend, or VHDL prerequisite. The remaining local implementation
change is the queue-head read-data coverage gate: expected-beat storage,
matched-read-beat counters, request-time raw-`ARLEN` capture, and
beat-count/`RLAST` assertions already iterate by transaction. `.135` must
preserve `.132` report-only raw-`ARLEN` multi-group scalar behavior, `.130`
no-`burst_length` multi-group scalar behavior, `.127` multi-group multi-beat
behavior, `.124` response-demux-only multi-group behavior, and `.119`
one-group scalar runtime-validation behavior.

Multi-group queue-head runtime-validation behavior:
[AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md)
ships `.135` for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`.
The source uses two generated read burst-last depth-2 concrete same-ID
queue-head groups (`RID` `3` for `r0`/`r1`, `RID` `5` for `r2`/`r3`) and a
scalar last-beat `read-data` contract with:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation runtime-assertion))
```

The generated path preserves scalar final `RDATA`/`RRESP` capture guarded by
generated queue-head last-beat completion pulses, and adds runtime-validation
state for every covered transaction: raw-`ARLEN` storage, expected-beat
storage, matched read-beat counters, request-time initialization rules,
matched-beat increment rules, and ARLEN-bound/extra-beat/early-`RLAST`/
missing-final-`RLAST` assertions. The schedule report records
`burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`, generated expected-beat and
beat-count artifacts for `r0`, `r1`, `r2`, and `r3`, and removes
`generated_beat_count_validation` from `read_data.residue`. Remaining
read-data residue is limited to `multi_beat_read_data_reassembly`,
`per_beat_outputs`, and `rresp_aggregation` for this scalar sample.

The `.132` report-only sample remains free of expected-beat storage, counters,
and assertions; the `.130` no-`burst_length` sample still omits `axi0_arlen`;
the `.127` multi-group multi-beat sample remains residue-clean; the `.124`
response-demux-only sample still has no `read_data` section; and the `.119`
one-group runtime-validation sample keeps its existing two-transaction
boundary.

Post multi-group queue-head runtime-validation selector:
[AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md)
selected `.137`, report/static residue cleanup. `.137` is now complete: the
AXI ID/order support detail describes generated runtime-validation multi-group
queue-head scalar last-beat read-data as supported, focused parser
expectations reject the retired unsupported-residue wording, and the `.135`,
`.132`, `.130`, `.127`, `.124`, and `.119` live schedule boundaries are
preserved. Deeper queues, same-family mixed auto-ID,
write/read-single-beat multi-group queue-head behavior, packed outputs,
alternate payload assembly, direct backend lowering, and VHDL remain deferred;
selector `.138` chose `.139`, readiness audit for generated write-family
multi-group queue-head response-demux.

Post support-residue cleanup selector:
[AXI_IAL2_MANAGER_POST_SUPPORT_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_SUPPORT_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md)
selected `.139`.

Write multi-group queue-head response-demux readiness audit:
[AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md)
is complete and selects `.140`, generated write-family multi-group queue-head
response-demux. The one-group write queue-head sample is generated, and a
temporary two-group write probe reported two concrete write-ID groups but
remained metadata-only with `generated_same_id_queue_head_demux` residue
because the local behavior-builder gate admitted only multi-group read
burst-last at that time. The audit found no new parser, support-accounting,
generated-artifact, lowerer, direct-backend, or VHDL prerequisite: once
behavior exists, the queue-state, transition, assertion, response-demux
state/rule, report, and residue helpers already iterate groups for write.
`.140` must preserve the family-wide admitted-request onehot contract and
must not claim group-local simultaneous enqueue widening. Read single-beat
multi-group behavior, deeper queues, same-family mixed auto-ID plus concrete
queue-head demux, packed outputs, direct backend, and VHDL remain deferred.

Write multi-group queue-head response-demux behavior:
[AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.140`, generated write-family multi-group queue-head response-demux.
The public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_write_multi_group_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif
```

The sample uses two duplicate write-ID groups: `w0`/`w1` share concrete `BID`
`3`, and `w2`/`w3` share concrete `BID` `5`. FSMGen emits
concrete-ID-scoped compact one-hot write queue storage, finite depth-2 update
rules, generated completion pulse outputs, queue-head `BID` demux rules,
queue assertions, response-demux assertions, and generated queue reports for
both groups.

The generated `w2` demux rule is:

```lisp
(rule axi0_w2_response_demux
  (& axi0_write_complete (== axi0_bid 4'd5)
     axi0_write_id5_same_id_issue_order_slot0_w2_q)
  (pulse axi0_w2_complete))
```

The report marks `generated_queue_behavior_boundary:
generated_write_bid_queue_head_demux`, lists generated completion signals for
`w0` through `w3`, removes `generated_same_id_queue_head_demux` residue, and
keeps `read_response_demux`, `read_data_interleaving`, and `bursts` as
response-demux residue. The same-ID policy lists both generated write queues
and keeps the existing family-wide admitted-request onehot assertion across
all selected write request events. The slice does not claim group-local
simultaneous same-cycle enqueue support.

Read single-beat multi-group behavior, deeper queues, same-family mixed
auto-ID plus concrete queue-head demux, packed outputs, direct backend, and
VHDL remain deferred. The active frontier advances to `.141`, the next
feature-completeness selector.

Post write multi-group queue-head response-demux selector:
[AXI_IAL2_MANAGER_POST_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_WRITE_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.142`, readiness audit for generated read single-beat multi-group
queue-head response-demux. A temporary read single-beat two-group probe with
`r0`/`r1` sharing `RID` `3` and `r2`/`r3` sharing `RID` `5` reports two
selected queue-head groups but remains generated-false with
`generated_same_id_queue_head_demux` residue. The adjacent read burst-last
multi-group, read single-beat one-group, and write multi-group queue-head
response-demux shapes are generated, so the next owner is an audit before any
behavior widening.

Read single-beat multi-group queue-head response-demux readiness audit:
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.143`, generated read single-beat multi-group queue-head
response-demux. The audit finds no new parser, support-accounting,
generated-artifact, lowerer, direct-backend, or VHDL prerequisite: queue-head
planning, storage, transition, assertion, response-demux rule, report, and
residue helpers already group-iterate for read single-beat once behavior
exists. The implementation boundary stays response-demux-only and leaves
read-data, deeper queues, same-family mixed auto-ID, and group-local
simultaneous enqueue widening deferred.

Read single-beat multi-group queue-head response-demux behavior:
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.143`, generated read single-beat multi-group queue-head response-demux.
The public sample is
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif`:
`r0`/`r1` share `RID` `3`, `r2`/`r3` share `RID` `5`, every generated queue
has depth `2`, generated completion signals cover `r0` through `r3`, and the
response-demux rules match `RID` without `RLAST`. The sample has no
`read_data` clause. Check JSON and semantic JSON match the support-accounting
entry for the sample, so the MCP-facing semantic-introspection surface carries
the same support claim as the public corpus catalog. Selector
[AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
chooses `.145`, readiness audit for generated read-data over read single-beat
multi-group queue-head response-demux. Audit
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md)
found no new parser, IAL1, IAL0/SystemVerilog, direct-backend, or VHDL
prerequisite and selects `.146`, the bounded implementation owner. Behavior
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md)
ships `.146`, generated read-data over read single-beat multi-group
queue-head response-demux. The public sample is
`ppif/axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif`:
`r0`/`r1` share `RID` `3`, `r2`/`r3` share `RID` `5`, generated
`axi0_rdata`/`axi0_rresp` inputs feed scalar `RDATA`/`RRESP` outputs for
all four read transactions, and capture rules are guarded by generated
queue-head completion pulses. The read-data report uses
`completion_validity: generated_queue_head_response_demux_completion_pulse`;
check JSON and semantic JSON support-account the sample under the public
corpus entry. Selector
[AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md)
chooses `.148`, readiness audit for generated concrete same-ID queue-head
groups deeper than two slots. The selector records that all generated
queue-head samples remain depth-2 today and that the queue builder,
transition matrix, state/full helpers, and assertions are specialized around
slots `0` and `1`. Mixed auto-ID, group-local enqueue widening, packed
outputs, direct backend, and VHDL remain deferred.

Deeper queue-head groups readiness audit:
[AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT](../../AXI_IAL2_MANAGER_DEEPER_QUEUE_HEAD_GROUPS_READINESS_AUDIT.md)
selects `.149`, generated read single-beat depth-3 concrete same-ID
queue-head response-demux through generalized shared queue-state helpers.
Temporary depth-3 read single-beat, read burst-last, and write response-demux
probes report selected-not-generated depth-3 queue groups and pass strict
check/semantic without support-accounting matches. Temporary depth-3 read-data
probes fail closed because generated read response-demux metadata does not
exist for depth-3 queue-head groups. The selected first behavior boundary is
one read single-beat group of three transactions at computed depth `3`, with
compact one-hot slots generalized to `slot0` through `slot2`; read-data,
write depth-3, burst-last depth-3, multiple depth-3 groups, mixed auto-ID,
group-local simultaneous enqueue widening, direct backend, and VHDL remain
deferred.

Read single-beat depth-3 queue-head response-demux behavior:
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
ships `.149`, generated read single-beat depth-3 queue-head response-demux for
`ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif`.
The public sample has one duplicate concrete read-ID group: `r0`, `r1`, and
`r2` share `RID` `3`; computed queue depth is `3`; generated state includes
`slot0`, `slot1`, and `slot2`; and generated completion pulse outputs cover
`r0` through `r2` without `RLAST` or `read_data`. The generalized shared queue
state core optionally dequeues the active head on matched `RID`, compacts the
remaining entries toward `slot0`, and appends the one admitted request at the
tail after any shift. Check JSON and semantic JSON support-account the sample,
and `--verify-hdl` emits the generated `RID` input, `r2` completion output,
and third-slot queue state.

Post read single-beat depth-3 queue-head selector:
[AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.151`, focused PPIF support-detail expectation alignment, before the
next depth-3 behavior expansion. The support detail now explicitly names
independent `depth-2` queue-head groups for existing multi-group read-data and
burst behavior, while the depth-3 sample remains response-demux-only with no
`read_data`. `.151` aligned that validation expectation without changing
public behavior. `.152` audited scalar read-data over generated read
single-beat depth-3 queue-head response-demux readiness and selected `.153` as
the direct bounded implementation owner. Write depth-3, burst-last depth-3,
multiple or mixed depth-3 groups, mixed auto-ID, group-local enqueue widening,
direct backend, and VHDL remain separately deferred.

Read single-beat depth-3 queue-head read-data readiness audit:
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md)
records `.152`: the shipped depth-3 response-demux sample has no `read_data`,
a temporary scalar read-data probe fails closed at the explicit depth-2
queue-head read-data coverage gate, and the downstream read-data input, output,
rule, report, `.fsm`, and HDL paths already iterate covered transactions once
coverage admits them. The selected `.153` boundary is one read single-beat
concrete `RID` group of three transactions, scalar `RDATA`/`RRESP` capture, and
generated queue-head completion-pulse validity.

Read single-beat depth-3 queue-head read-data behavior:
[AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md)
ships `.153`, generated scalar read-data over the selected read single-beat
depth-3 queue-head response-demux group. The public sample is
`ppif/axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif`.
It keeps the `r0`/`r1`/`r2` concrete `RID` `3` depth-3 queue-head group,
generates `axi0_rdata` and `axi0_rresp` inputs, emits scalar
`axi0_r*_rdata`/`axi0_r*_rresp` outputs, and guards each capture rule with the
generated queue-head completion pulse. The response-demux-only depth-3 sample
remains separate and generated without `read_data`; read burst-last depth-3,
write depth-3, multiple or mixed depth-3 groups, mixed auto-ID, group-local
enqueue widening, direct backend, and VHDL remain separately deferred.

Post read single-beat depth-3 queue-head read-data selector:
[AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md)
records `.154` and selects `.155`, readiness audit for generated read
burst-last depth-3 queue-head response-demux. The selector confirms the
current depth-3 generated path is still read single-beat only, while existing
read burst-last and write queue-head groups remain generated at depth 2. The
next audit will check whether the `RLAST`-qualified read burst-last path can
safely reuse the generalized depth-3 queue-state core for exactly one
three-transaction concrete `RID` group before any behavior is widened. Write
depth-3, read-data over read burst-last depth-3, multiple or mixed depth-3
groups, mixed auto-ID, group-local enqueue widening, direct backend, and VHDL
remain separately deferred.

Read burst-last depth-3 queue-head response-demux readiness audit:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md)
records `.155` and selects `.156`, generated read burst-last depth-3
queue-head response-demux. The audit's temporary burst-last depth-3 probe
passes schedule parsing, strict check JSON, and semantic JSON, reports one
selected concrete `RID` group with `r0`/`r1`/`r2` at depth 3, and remains
selected-not-generated only because the current behavior builder admits
depth-3 generation for the read single-beat sibling but not yet for the
`RLAST`-qualified burst-last sibling. The selected `.156` implementation
boundary is response-demux only: no read-data, burst-length,
runtime-validation, multi-beat output-bank, write depth-3, multiple/mixed
depth-3 groups, mixed auto-ID, direct backend, or VHDL widening.

Read burst-last depth-3 queue-head response-demux behavior:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
records `.156` and ships generated response-demux-only behavior for one
read burst-last concrete `RID` group at depth 3. The runnable public sample
is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_burst_last_depth3_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif
```

The generated queue covers `r0`, `r1`, and `r2` with concrete `RID` `3`.
Storage spans `slot0` through `slot2`, the report marks
`generated_read_burst_last_queue_head_demux`, and completion pulses fire only
for the active queue head when raw read completion, `RID`, `RLAST`, and slot
identity all match. A generated response-demux rule has this shape:

```lisp
(rule axi0_r2_response_demux
  (& axi0_read_complete (== axi0_rid 4'd3) axi0_rlast
     axi0_read_id3_same_id_issue_order_slot0_r2_q)
  (pulse axi0_r2_complete))
```

Strict check JSON and normalized semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux`.
Read-data over read burst-last depth-3, burst-length/runtime or multi-beat
over read burst-last depth-3, write depth-3, multiple or mixed depth-3
groups, mixed auto-ID, group-local enqueue widening, direct backend, and VHDL
remain separately deferred. `.157` selected `.158`, the focused read-data
readiness audit.

Post read burst-last depth-3 queue-head response-demux selector:
[AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
records `.157` and selects `.158`, readiness audit for generated read-data
over read burst-last depth-3 queue-head response-demux. The selector confirms
that `.156` is generated at depth 3 and remains response-demux-only, while
the existing read burst-last queue-head read-data path is still depth 2. A
temporary last-beat read-data-over-`.156` probe fails closed at the current
coverage gate:

```text
read_data.read queue-head last-beat coverage requires one or more depth-2
concrete same-ID read queue groups
```

The `.158` audit must decide whether the next implementation can safely
support last-beat scalar `RDATA`/`RRESP` capture for exactly one read
burst-last depth-3 concrete `RID` group, or whether a smaller prerequisite
is needed first. Burst-length metadata, runtime validation, multi-beat output
bank behavior, write depth-3, multiple or mixed depth-3 groups, mixed
auto-ID, group-local enqueue widening, direct backend, and VHDL remain
separately deferred.

Read burst-last depth-3 queue-head read-data readiness:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md)
records `.158` and selects `.159`, direct bounded implementation of scalar
last-beat read-data over the generated read burst-last depth-3 queue-head
response-demux. The audit confirms that the `.156` response-demux already
generates the single depth-3 `RID` group and three completion pulses, while
the scalar read-data artifact path already emits inputs, outputs, and capture
rules by iterating the covered transaction list once the local coverage gate
admits the shape.

The selected `.159` boundary is intentionally narrow: read family only,
`response-scope burst-last`, one-bit `RLAST`, exactly one concrete `RID`
group with `r0`, `r1`, and `r2`, queue depth 3, `capture-scope last-beat`,
`completion-source response-demux`, `status-policy last-beat`, and scalar
`RDATA`/`RRESP` outputs. Burst-length metadata, runtime validation,
multi-beat output-bank behavior, write depth-3, multiple or mixed depth-3
groups, mixed auto-ID, group-local enqueue widening, direct backend, and VHDL
remain separately deferred.

Read burst-last depth-3 queue-head read-data behavior:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md)
records `.159` and ships generated scalar last-beat read-data over one read
burst-last concrete `RID` group at depth 3. The runnable public sample is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_read_burst_last_depth3_same_id_queue_head_read_data.sv ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif
```

The generated queue covers `r0`, `r1`, and `r2` with concrete `RID` `3`.
The response-demux remains `generated_read_burst_last_queue_head_demux`, and
the read-data report marks
`generated_queue_head_response_demux_last_beat_completion_pulse`. Generation
adds `axi0_rdata`/`axi0_rresp` inputs, scalar
`axi0_r*_last_rdata`/`axi0_r*_last_rresp` outputs, and read-data capture
rules guarded by each generated `RID`/`RLAST` queue-head completion pulse.

Strict check JSON and normalized semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data`.
Burst-length/runtime or multi-beat behavior over read burst-last depth-3,
write depth-3, multiple or mixed depth-3 groups, mixed auto-ID,
group-local enqueue widening, direct backend, and VHDL remain separately
deferred.

Post read burst-last depth-3 queue-head read-data selector:
[AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md)
records `.160` and selects `.161`, readiness audit for generated report-only
raw-`ARLEN` burst-length capture over the `.159` shape. The selector's live
probes show `.159` is generated at depth 3 but still reports
`arlen_or_beat_count_validation` residue, while the existing depth-2
queue-head burst-length sibling already generates request-bound raw-`ARLEN`
storage and capture rules with `validation report_only`. Runtime validation,
multi-beat output-bank behavior, write depth-3, multiple or mixed depth-3
groups, mixed auto-ID, group-local enqueue widening, direct backend, and VHDL
remain separately deferred.

Read burst-last depth-3 queue-head burst-length readiness:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md)
records `.161` and selects `.162`, direct bounded implementation of generated
report-only raw-`ARLEN` burst-length capture over the same `.159` depth-3
read burst-last queue-head read-data shape. The audit's temporary candidate
failed only at the local queue-head read-data coverage predicate; normalization
and artifact/report helpers already iterate the covered transactions for
raw-`ARLEN` input, storage, and request-bound capture rules. Runtime
validation, multi-beat output-bank behavior, broader depth-3 groups, direct
backend, and VHDL remain separately deferred.

Read burst-last depth-3 queue-head burst-length behavior:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md)
records `.162`, which ships generated report-only raw-`ARLEN` burst-length
capture over the same read burst-last depth-3 queue-head read-data shape. The
public source
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif`
uses one concrete `RID` `3` group with `r0`, `r1`, and `r2` at computed depth
`3`, scalar last-beat `RDATA`/`RRESP` outputs, and this additive
`burst-length` clause:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

Generation adds `axi0_arlen`, raw-`ARLEN` storage
`axi0_r0_arlen_q`, `axi0_r1_arlen_q`, and `axi0_r2_arlen_q`, and
request-guarded capture rules `axi0_r0_burst_length_capture`,
`axi0_r1_burst_length_capture`, and `axi0_r2_burst_length_capture`. The
existing scalar read-data capture remains guarded by
`generated_queue_head_response_demux_last_beat_completion_pulse`. The report
sets `burst_length_validation: report_only`, records generated
burst-length input/storage/rule fields, and keeps `generated_beat_count_validation`,
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` residue. No expected-beat storage, matched-beat counters,
or beat-count/`RLAST` runtime assertions are generated in this report-only
shape.

Strict check JSON and normalized semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length`
with coverage bucket
`ial2_ppif_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_pipeline_cli`.
Runtime validation and multi-beat output-bank behavior over read burst-last
depth-3, write depth-3, multiple or mixed depth-3 groups, mixed auto-ID,
group-local enqueue widening, direct backend, and VHDL remain separately
deferred.

Post read burst-last depth-3 queue-head burst-length selector:
[AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md)
records `.163` and selects `.164`, readiness audit for generated runtime
beat-count/`RLAST` validation over the `.162` read burst-last depth-3
queue-head read-data plus report-only raw-`ARLEN` burst-length shape. The
selector's live probes show the `.162` sample still has
`generated_beat_count_validation` residue and no expected-beat storage,
matched-beat counters, or runtime assertions, while the existing depth-2
one-group and multi-group runtime-validation samples already generate those
artifacts from transaction-list driven helpers. A temporary depth-3
`runtime-assertion` candidate fails closed at the local last-beat queue-head
coverage diagnostic. `.164` must audit whether the next implementation only
widens that admission gate or needs a smaller prerequisite before behavior
changes. Multi-beat output-bank behavior over read burst-last depth-3, write
depth-3, multiple or mixed depth-3 groups, mixed auto-ID, direct backend, and
VHDL remain separately deferred.

Read burst-last depth-3 queue-head runtime-validation readiness:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md)
records `.164` and selects `.165`, direct bounded implementation of generated
runtime beat-count/`RLAST` validation over the `.162` read burst-last
depth-3 queue-head raw-`ARLEN` burst-length shape. The audit's temporary
`runtime-assertion` candidate fails closed only at the local queue-head
last-beat coverage diagnostic. Below that gate, runtime-validation
normalization, expected-beat storage, read-beat counters, beat-count
init/increment rules, four beat-count/`RLAST` assertions per transaction,
generated-artifact reporting, and schedule-report fields already iterate the
covered transaction list. `.165` now ships the support-accounted public
runtime-validation PPIF sample and focused tests, removes
`generated_beat_count_validation` residue for that sample, and keeps
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` residue. Multi-beat output-bank behavior over read
burst-last depth-3, write depth-3, multiple or mixed depth-3 groups, mixed
auto-ID, direct backend, and VHDL remain separately deferred.

Read burst-last depth-3 queue-head runtime-validation behavior:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md)
records `.165`, which ships generated runtime beat-count/`RLAST` validation
over the same read burst-last depth-3 queue-head raw-`ARLEN` burst-length
shape. The public source is
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`.
It uses one concrete `RID` `3` group with `r0`, `r1`, and `r2` at computed
depth `3`, scalar last-beat `RDATA`/`RRESP` outputs, and the same
`burst-length` source as the report-only sibling with `(validation
runtime-assertion)`.

Generation adds `axi0_r0_expected_beats_q`,
`axi0_r1_expected_beats_q`, `axi0_r2_expected_beats_q`,
`axi0_r0_read_beat_count_q`, `axi0_r1_read_beat_count_q`, and
`axi0_r2_read_beat_count_q`, plus request-time beat-count init rules and raw
matched-read-beat increment rules for all three transactions. The matched
read-beat counter is driven by `response_demux_matched_read_beat`, not by the
`RLAST`-qualified completion pulse, so intermediate beats are counted before
the final completion captures scalar data/status. Each transaction gets four
runtime assertions: request-time `ARLEN` bound, extra beat beyond expected
count, early `RLAST`, and missing `RLAST` on the expected final beat.

The schedule report sets `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`,
`beat_count_match_source: response_demux_matched_read_beat`, and
`beat_count_width: 5`. It reports generated expected-beat storage, read-beat
counters, beat-count rules, and beat-count/`RLAST` assertions for `r0`,
`r1`, and `r2`. `read_data.residue` is reduced to
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation`.

Strict check JSON and normalized semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion`
with coverage bucket
`ial2_ppif_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_pipeline_cli`.
Multi-beat output-bank behavior over read burst-last depth-3, write depth-3,
multiple or mixed depth-3 groups, mixed auto-ID, group-local enqueue
widening, packed burst outputs, direct backend, and VHDL remain separately
deferred.

Post read burst-last depth-3 queue-head runtime-validation selector:
[AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md)
records `.166` and selects `.167`, readiness audit for generated multi-beat
output-bank behavior over the shipped read burst-last depth-3 queue-head
runtime-validation shape. The selector keeps `.166` documentation-only: the
`.165` runtime sample is generated at depth `3` and leaves only
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` residue; the existing depth-2 multi-beat queue-head
sample proves the output-bank substrate; an in-memory depth-3 multi-beat
candidate fails closed at the local multi-beat coverage diagnostic. `.167`
must audit whether direct implementation can widen that local admission gate
or needs a smaller prerequisite before behavior changes.

Read burst-last depth-3 queue-head multi-beat readiness:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md)
records `.167` and selects `.168`, direct bounded implementation of
generated multi-beat output-bank behavior over one read burst-last depth-3
queue-head runtime-validation group. The audit found no parser, IAL1, IAL0,
SystemVerilog lowerer, support-accounting, or mdBook prerequisite beyond the
local multi-beat depth-3 admission gate. The selected behavior is limited to
`r0`/`r1`/`r2`, runtime `ARLEN` validation, per-beat output banks, valid
masks, length outputs, and scalar `RRESP` aggregation; write depth-3,
multiple or mixed depth-3 groups, mixed auto-ID, direct backend, verification
output generation, and VHDL remain separate owned work.

Read burst-last depth-3 queue-head multi-beat read-data behavior:
[AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md)
records `.168`, which ships generated multi-beat read-data output-bank
behavior over the same read burst-last depth-3 queue-head runtime-validation
shape. The public source is
`ppif/axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif`.
It covers one concrete `RID` `3` group with `r0`, `r1`, and `r2` at computed
depth `3`, `capture-scope multi-beat`, `status-policy per-beat`,
`status-aggregation (policy worst-observed)`, `interleaving
multi-beat-by-rid`, and runtime-assertion `ARLEN` burst-length metadata.

Generation emits request-time output-bank clearing, 16 `RDATA` lanes and 16
`RRESP` lanes per transaction, 48 total lane capture rules, valid-mask
outputs, read-length outputs, scalar worst-observed `RRESP` aggregate outputs,
raw `ARLEN` capture, expected-beat storage, read-beat counters, beat-count
rules, and beat-count/`RLAST` assertions for all three transactions. The
schedule report sets `output_shape: per_beat_output_bank`, keeps
`beat_count_match_source: response_demux_matched_read_beat`, and reports empty
`read_data` and `response_demux` residue for the covered sample. Strict check
JSON and normalized semantic JSON support-account it as
`intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data`.
Write depth-3, multiple or mixed depth-3 groups, mixed auto-ID, group-local
enqueue widening, packed burst outputs, direct backend, verification-output
generation, VHDL, and backend-language variant work remain separately owned.

Post read burst-last depth-3 queue-head multi-beat selector:
[AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_BURST_LAST_DEPTH3_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
records `.169` and selects `.170`, readiness audit for generated
write-family depth-3 concrete same-ID queue-head response-demux. Existing
write depth-2 one-group and multi-group queue-head response-demux samples are
generated through `generated_write_bid_queue_head_demux`. A temporary write
depth-3 candidate with `w0`/`w1`/`w2` sharing concrete `BID` `3` passes
strict check with no diagnostics, reports one depth-3 write queue group, and
remains selected-not-generated only with `generated_same_id_queue_head_demux`
residue. `.170` must audit whether direct implementation only needs the local
queue-head behavior admission boundary widened or whether a smaller
prerequisite is required. Multiple or mixed depth-3 groups, mixed auto-ID,
group-local enqueue widening, packed outputs, alternate burst assembly,
direct backend, verification-output generation, VHDL, and backend-language
variant work remain separately owned.

Write depth-3 queue-head response-demux readiness:
[AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md)
records `.170` and selects `.171`, direct bounded implementation of
generated write-family depth-3 concrete same-ID queue-head response-demux.
The audit found the write depth-2 one-group and multi-group samples are
generated and support-accounted, and the read depth-3 siblings prove the
shared compact one-hot queue-state machinery for three slots. The temporary
write depth-3 candidate with `w0`/`w1`/`w2` sharing concrete `BID` `3`
strict-checks cleanly and remains selected-not-generated only at
`generated_same_id_queue_head_demux`. `.171` is limited to one write depth-3
public sample, generated completion outputs and response-demux rules for
`w0`/`w1`/`w2`, 9 queue slot storage signals, 54 queue update rules, 14 queue
assertions, 4 write response-demux assertions, support accounting, tests, and
docs. Multiple or mixed depth-3 groups, mixed auto-ID, group-local enqueue
widening, read-data, burst-length, runtime-validation, multi-beat payload,
direct backend, verification-output generation, VHDL, and backend-language
variant work remain separately owned.

Write depth-3 queue-head response-demux behavior:
[AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
records `.171`, which ships generated write-family depth-3 concrete same-ID
queue-head response-demux. The public source is:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl --output .artifacts/sv/fsmgen_write_depth3_same_id_queue_head_response_demux.sv ppif/axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif
```

The sample covers one write group with `w0`, `w1`, and `w2` sharing concrete
`BID` `3`, selected write `concrete-id-reuse issue-order-queue`, queue depth
`3`, and generated write response demux. FSMGen emits generated completion
outputs for all three writes, three queue-head `BID` demux rules, four write
response-demux assertions, 9 compact queue slot storage signals, 54 queue
update rules, and 14 queue assertions.

The generated `w2` demux rule is:

```lisp
(rule axi0_w2_response_demux
  (& axi0_write_complete (== axi0_bid 4'd3)
     axi0_write_id3_same_id_issue_order_slot0_w2_q)
  (pulse axi0_w2_complete))
```

The schedule report marks `generated_queue_behavior_boundary:
generated_write_bid_queue_head_demux`, removes
`generated_same_id_queue_head_demux` from response-demux residue, reduces
same-ID ordering residue to `per_id_issue_order_queues`, and removes
`same_id_ordering` and `response_demux` from ID/response rule-engine residue.
Strict check JSON and normalized semantic JSON support-account the sample as
`intent.ppif_axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux`.

Read-data, burst-length, runtime-validation, multi-beat payload, read
response-demux, `RLAST`, multiple or mixed depth-3 groups, mixed auto-ID,
group-local enqueue widening, packed outputs, direct backend,
verification-output generation, VHDL, and backend-language variant work remain
separately owned. That implementation advanced the active frontier to `.172`,
the selector that selected `.173`; the `.173` audit now selects `.174`.

Post write depth-3 queue-head selector:
[AXI_IAL2_MANAGER_POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_WRITE_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
records `.172`, which selects `.173`, readiness audit for generated multiple
or mixed depth-3 concrete same-ID queue-head response-demux groups. Existing
one-group depth-3 and multi-group depth-2 response-demux samples are
generated, while temporary multi-depth-3 and mixed depth-3/depth-2 write
probes strict-check with no diagnostics but remain selected-not-generated
with `generated_same_id_queue_head_demux` residue. `.173` must audit whether
the next behavior leaf should cover all response-demux-only families or a
smaller first family/scope. Read-data, burst-length, runtime-validation,
multi-beat payload, mixed auto-ID, group-local enqueue widening, packed
outputs, direct backend, verification-output generation, VHDL, and
backend-language variant work remain separately owned.

Multiple/mixed depth-3 queue-head readiness:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md)
records `.173`, which selects `.174`, direct bounded implementation of
generated multiple or mixed depth-3 concrete same-ID queue-head response-demux
for response-demux-only read single-beat, read burst-last, and write
families. The audit found the only direct generation blocker is the local
depth-3 `@$groups == 1` shape predicate in
`_build_same_id_issue_order_queue_behavior`; downstream queue-state,
transition, assertion, response-demux, and report helpers already iterate
generated groups and their local depths. Temporary read single-beat, read
burst-last, and write two-depth-3 and mixed depth-3/depth-2 candidates
strict-check with no diagnostics and remain selected-not-generated with
`generated_same_id_queue_head_demux` residue, while existing one-group
depth-3 and multi-group depth-2 public samples remain generated and
support-accounted.

`.174` should add public support-accounted samples for read single-beat,
read burst-last, and write two-depth-3 and mixed depth-3/depth-2 groups. The
expected generated surface keeps the same family boundaries:
`generated_read_single_beat_queue_head_demux`,
`generated_read_burst_last_queue_head_demux`, and
`generated_write_bid_queue_head_demux`. Read-data over multiple/mixed
depth-3 groups, burst-length, runtime-validation, multi-beat payload, mixed
auto-ID, group-local enqueue widening, packed outputs, direct backend,
verification-output generation, VHDL, and backend-language variant work remain
separately owned.

Multiple/mixed depth-3 queue-head behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md)
records `.174`, which ships generated multiple or mixed depth-3 concrete
same-ID queue-head response-demux for response-demux-only read single-beat,
read burst-last, and write families. FSMGen now accepts duplicate concrete-ID
queue-head groups whose computed depth is `2` or `3` when at least one group
has depth `3`, and keeps the existing family report boundaries:
`generated_read_single_beat_queue_head_demux`,
`generated_read_burst_last_queue_head_demux`, and
`generated_write_bid_queue_head_demux`.

The six public samples cover read single-beat two-depth-3 groups, read
single-beat mixed depth-3/depth-2 groups, read burst-last two-depth-3 groups,
read burst-last mixed depth-3/depth-2 groups, write two-depth-3 groups, and
write mixed depth-3/depth-2 groups. The two-depth-3 samples generate 18 queue
storage signals and 108 queue update rules; the mixed samples generate 13
queue storage signals and 66 queue update rules. Read single-beat and write
samples generate 28 or 25 queue assertions depending on two-depth-3 versus
mixed shape; read burst-last samples generate 30 or 27 queue assertions
because they also guard non-last read response beats. Five-transaction mixed
samples generate 5 response-demux rules and 11 response-demux assertions;
six-transaction two-depth-3 samples generate 6 response-demux rules and 16
response-demux assertions.

Each sample is support-accounted through check JSON and normalized semantic
JSON. The generated response-demux residue removes
`generated_same_id_queue_head_demux` for the covered family, while write-only
samples still preserve `read_response_demux` residue. Read-data over
multiple/mixed depth-3 groups, burst-length, runtime-validation, multi-beat
payload, mixed auto-ID, group-local enqueue widening, packed outputs, direct
backend, verification-output generation, VHDL, and backend-language variant
work remain separately owned.

Post multiple/mixed depth-3 queue-head selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
records `.175`, which selects `.176`, readiness audit for generated read-data
over multiple or mixed depth-3 concrete same-ID queue-head groups. The
selector keeps `.175` documentation-only: the `.174` response-demux-only
samples are generated and support-accounted, while temporary read single-beat
and read burst-last read-data candidates over two depth-3 queue groups fail
closed at the current read-data coverage gate. `.176` must audit whether the
next behavior owner starts with single-beat scalar read-data, scalar
single-beat plus last-beat, or a broader read-data set before any behavior
change.

Multiple/mixed depth-3 queue-head read-data readiness:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md)
records `.176`, which selects `.177`, direct bounded implementation of read
single-beat scalar `RDATA`/`RRESP` over generated multiple or mixed depth-3
queue-head response-demux groups. Existing read single-beat multi-group
depth-2 read-data and one-group depth-3 read-data samples are generated, while
temporary two-depth-3 and mixed depth-3/depth-2 single-beat read-data
candidates fail closed at the current coverage gate. `.177` must stay limited
to scalar single-beat read-data; burst-last read-data, burst-length,
runtime-validation, multi-beat payload, mixed auto-ID, direct backend, VHDL,
and backend-language variants remain separate owned work.

Multiple/mixed depth-3 queue-head read-data behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_BEHAVIOR.md)
ships `.177`. FSMGen now generates scalar single-beat `RDATA`/`RRESP`
capture for generated read single-beat queue-head response-demux groups whose
duplicate concrete `RID` groups have computed depth `2` or `3`, with at least
one depth-3 group. The two public samples cover `r0/r1/r2` plus `r3/r4/r5`
two-depth-3 groups and `r0/r1/r2` plus `r3/r4` mixed depth-3/depth-2 groups.
Each covered transaction gets scalar data/status outputs and a read-data
capture rule guarded by the generated queue-head completion pulse; no `RLAST`,
`ARLEN`, burst-length, runtime-validation, multi-beat output bank, packed
payload vector, or write-family read-data is generated by this slice. The
samples are support-accounted as
`intent.ppif_axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data`
and
`intent.ppif_axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data`.

Post multiple/mixed depth-3 queue-head read-data selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md)
records `.178`, which selects `.179`, readiness audit for generated read
burst-last scalar last-beat read-data over multiple or mixed depth-3 concrete
same-ID queue-head groups. The selector keeps `.178` documentation-only:
`.177` generates the two-depth-3 and mixed depth-3/depth-2 single-beat
read-data shapes, adjacent read burst-last multiple/mixed depth-3 samples
remain response-demux-only, and temporary last-beat read-data candidates over
those queue sets fail closed at the local last-beat coverage gate. Burst-length,
runtime-validation, multi-beat payload, write-family read-data, mixed
auto-ID, group-local enqueue widening, packed outputs, alternate burst
assembly, direct backend, verification-output generation, VHDL, and
backend-language variants remain separately owned.

Multiple/mixed depth-3 queue-head last-beat read-data readiness:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md)
records `.179`, which selects `.180`, direct bounded implementation of
generated read burst-last scalar last-beat `RDATA`/`RRESP` over multiple or
mixed depth-3 concrete same-ID queue-head groups with no `burst_length`
metadata. The audit is behavior-free: the matching `.174` response-demux-only
samples already generate over depth `3,3` and `3,2` queue sets, the one-group
depth-3 read burst-last scalar read-data sibling already generates, downstream
scalar read-data artifacts are transaction-list driven, and temporary
last-beat read-data candidates over those queue sets fail closed only at the
local last-beat coverage gate. Burst-length, runtime-validation, multi-beat
payload, write-family read-data, mixed auto-ID, group-local enqueue widening,
packed outputs, alternate burst assembly, direct backend, verification-output
generation, VHDL, and backend-language variants remain separately owned.

Multiple/mixed depth-3 queue-head last-beat read-data behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md)
ships `.180`. FSMGen now generates read burst-last scalar last-beat
`RDATA`/`RRESP` capture for generated queue-head response-demux groups whose
duplicate concrete `RID` groups have computed depth `2` or `3`, with at least
one depth-3 group, and with no `burst_length` metadata. The two public samples
cover `r0/r1/r2` plus `r3/r4/r5` two-depth-3 groups and `r0/r1/r2` plus
`r3/r4` mixed depth-3/depth-2 groups. Each covered transaction gets scalar
last-beat data/status outputs and a capture rule guarded by the generated
`RID`/`RLAST` queue-head completion pulse; no `ARLEN`, beat-count state,
runtime validation, multi-beat output bank, packed payload vector, or
write-family read-data is generated by this slice. The samples are
support-accounted as
`intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data`
and
`intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data`.

Post multiple/mixed depth-3 queue-head last-beat read-data selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md)
records `.181`, which selects `.182`, readiness audit for generated
report-only raw-`ARLEN` burst-length capture over the multiple/mixed depth-3
queue-head scalar last-beat read-data shape shipped by `.180`. The selector is
documentation-only. It follows the established sequence used by one-group
depth-3 and multi-group depth-2 queue-head scalar last-beat read-data:
no-`burst_length` scalar last-beat read-data first, report-only raw-`ARLEN`
next, then runtime-validation and multi-beat payload only after separate
owners. Runtime validation, multi-beat output bank, write-family read-data,
same-family mixed auto-ID plus concrete queue-head demux, group-local enqueue
widening, packed payload vectors, alternate burst assembly, direct backend,
verification-output generation, VHDL, and backend-language variants remain
separately owned.

Multiple/mixed depth-3 queue-head burst-length readiness:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md)
records `.182`, which selects `.183`, direct bounded implementation of
generated report-only raw-`ARLEN` burst-length capture over the
multiple/mixed depth-3 queue-head scalar last-beat read-data shape. The audit
is documentation-only. Compact probes show the `.180` samples generate
`rlast_only` scalar last-beat read-data over depth `3,3` and `3,2` queue
sets, while one-group depth-3 and multi-group depth-2 report-only precedents
generate transaction-list-driven raw-`ARLEN` storage and request-guarded
capture rules. Temporary in-memory candidates with inserted report-only
`burst-length` metadata fail closed only at the local last-beat coverage gate.
The selected implementation should add support-accounted public samples
`ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif`
and
`ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif`.
Runtime validation, multi-beat output bank, write-family read-data,
same-family mixed auto-ID plus concrete queue-head demux, group-local enqueue
widening, packed payload vectors, alternate burst assembly, direct backend,
verification-output generation, VHDL, and backend-language variants remain
separately owned.

Multiple/mixed depth-3 queue-head burst-length behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md)
records `.183`, which ships generated report-only raw-`ARLEN` burst-length
capture over multiple/mixed depth-3 read burst-last queue-head scalar
last-beat read-data. The public samples are
`ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif`
and
`ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif`.
They cover two depth-3 duplicate-`RID` queue-head groups and mixed
depth-3/depth-2 queue-head groups, respectively.

Generation preserves the `RID`/`RLAST` queue-head response-demux completion
source and scalar last-beat `RDATA`/`RRESP` capture, then adds generated
`axi0_arlen`, per-transaction raw-`ARLEN` storage, and request-guarded
burst-length capture rules. The report sets `burst_length_validation:
report_only`, records generated burst-length input/storage/rule fields, and
keeps `generated_beat_count_validation`, `multi_beat_read_data_reassembly`,
`per_beat_outputs`, and `rresp_aggregation` residue. No expected-beat
storage, read-beat counters, or beat-count/`RLAST` runtime assertions are
generated in this report-only shape.

Strict check JSON and normalized semantic JSON support-account the samples as
`intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length`
and
`intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length`.
Runtime validation, multi-beat output bank, write-family read-data,
same-family mixed auto-ID plus concrete queue-head demux, group-local enqueue
widening, packed payload vectors, alternate burst assembly, direct backend,
verification-output generation, VHDL, and backend-language variants remain
separately owned.

Post multiple/mixed depth-3 queue-head burst-length selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md)
records `.184`, which selects `.185`, readiness audit for generated
beat-count/`RLAST` runtime validation over the same multiple/mixed depth-3
queue-head scalar last-beat read-data shape. The selector is
documentation-only. It records that the `.183` samples keep
`generated_beat_count_validation` residue, while the one-group depth-3 and
multi-group depth-2 runtime-validation precedents already generate
transaction-list-driven expected-beat storage, read-beat counters, beat-count
rules, and beat-count/`RLAST` assertions once coverage admits the shape.
Multi-beat payload, write-family read-data, same-family mixed auto-ID plus
concrete queue-head demux, group-local enqueue widening, packed outputs,
alternate burst assembly, direct backend, verification-output generation,
VHDL, and backend-language variants remain separately owned.

Multiple/mixed depth-3 queue-head runtime-validation readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md)
records `.185`, which selects `.186`, direct bounded implementation of
generated beat-count/`RLAST` runtime validation over the same
multiple/mixed depth-3 queue-head scalar last-beat read-data shape. The audit
is documentation-only. Compact probes show the `.183` report-only samples
keep `generated_beat_count_validation` residue and have no expected-beat
storage, beat-count rules, or beat-count/`RLAST` assertions, while the
one-group depth-3 and multi-group depth-2 runtime-validation precedents
generate those artifacts from admitted transaction lists. Temporary
runtime-assertion variants of the two `.183` samples fail closed only at the
local last-beat coverage diagnostic.

Multiple/mixed depth-3 queue-head runtime-validation behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md)
records `.186`, which ships generated beat-count/`RLAST` runtime validation
over multiple/mixed depth-3 read burst-last queue-head scalar last-beat
read-data. The support-accounted public samples are
`ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif`
and
`ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif`.
They cover two depth-3 duplicate-`RID` queue-head groups and mixed
depth-3/depth-2 queue-head groups, respectively.

Generation preserves request-side raw `ARLEN` capture and scalar last-beat
`RDATA`/`RRESP` capture, adds expected-beat storage encoded as `ARLEN+1`,
read-beat counters, request initialization rules, response increment rules,
and generated beat-count/`RLAST` assertions. Reports set
`burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`, and
`beat_count_match_source: response_demux_matched_read_beat`. The shipped
runtime-validation shape removes `generated_beat_count_validation` from
read-data residue while preserving `multi_beat_read_data_reassembly`,
`per_beat_outputs`, and `rresp_aggregation`. Multi-beat output bank,
write-family read-data,
same-family mixed auto-ID plus concrete queue-head demux, group-local enqueue
widening, packed payload vectors, alternate burst assembly, direct backend,
verification-output generation, VHDL, and backend-language variants remain
separately owned.

Post multiple/mixed depth-3 queue-head runtime-validation selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md)
records `.187`, which selected `.188` as report/static support-residue cleanup
after generated runtime beat-count/`RLAST` validation over multiple/mixed
depth-3 queue-head scalar last-beat read-data.

The selector found that the two `.186` samples generate runtime validation and
leave `read_data` residue limited to `multi_beat_read_data_reassembly`,
`per_beat_outputs`, and `rresp_aggregation`, but the AXI ID/order
unsupported-residue detail still classifies multiple/mixed depth-3 runtime
validation with multi-beat payload as outside the shell. `.188` owns only that
support/report wording cleanup and focused expectation update. Multi-beat
output-bank behavior over the multiple/mixed runtime-validation groups remains
a later exact owner.

Multiple/mixed depth-3 queue-head runtime-validation support residue cleanup:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md)
records `.188`, which cleans stale support/residue wording after `.186`.
Selected multiple/mixed depth-3 read burst-last queue-head scalar last-beat
read-data with runtime-assertion beat-count/`RLAST` validation is now
described as supported in the AXI manager static support detail.

The remaining residue for this shape is the payload/output family:
`read burst-last multi-beat payload over multiple or mixed depth-3 queue-head
groups`. The cleanup does not change parser syntax, queue-head admission,
generated read-data rules, generated assertions, PPIF corpus membership,
support-accounting identity, generated artifacts, strict check/semantic JSON
source identity, or HDL behavior.

Post multiple/mixed depth-3 runtime-validation residue cleanup selector:
[AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_RUNTIME_VALIDATION_RESIDUE_CLEANUP_NEXT_SLICE_SELECTION.md)
records `.189`, which selects `.190` as readiness audit for generated
multi-beat output-bank behavior over the multiple/mixed depth-3
runtime-validation queue-head groups. The selector confirmed the two `.186`
samples generate runtime validation and keep only the multi-beat
payload/output/aggregation residue, while the one-depth-3 and depth-2
multi-group multi-beat precedents are residue-clean. The audit must decide
whether the local multi-beat admission gate can be widened directly or whether
a smaller prerequisite is needed.

Multiple/mixed depth-3 multi-beat readiness audit:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md)
records `.190`, which selects `.191` as direct bounded implementation of
generated multi-beat output-bank behavior over the two existing `.186`
depth `3,3` and mixed depth `3,2` runtime-validation queue-head shapes. The
audit found no lower-layer prerequisite: the runtime-validation substrate,
one-depth-3 multi-beat precedent, and depth-2 multi-group multi-beat precedent
are transaction-list driven after coverage admission. The remaining boundary
is the local multi-beat coverage gate plus the two public support-accounted
samples and expectations.

Multiple/mixed depth-3 multi-beat read-data behavior:
[AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MULTIPLE_MIXED_DEPTH3_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md)
records `.191`, which ships generated multi-beat output-bank behavior over
the selected multiple/mixed depth-3 runtime-validation queue-head groups. The
public samples are:

```text
ppif/axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif
```

The first sample reports queue depths `3,3` and transactions `r0` through
`r5`; the second reports queue depths `3,2` and transactions `r0` through
`r4`. Both generate per-transaction `RDATA`/`RRESP` output banks, valid masks,
length outputs, scalar worst-observed `RRESP` aggregates, raw `ARLEN`
storage, expected/read beat counters, beat-count/`RLAST` assertions, empty
`read_data` residue, and empty `response_demux` residue. Selector `.192`
selected `.193`, readiness audit for same-family mixed auto-ID lifecycle plus
concrete same-ID queue-head response-demux before any behavior change. Audit
`.193` selected `.194`, direct bounded response-demux-only implementation of
that mixed family boundary. Implementation `.194` now ships that behavior for
public read single-beat, read burst-last, and write response-demux-only
fixtures. Mixed reports combine auto-ID and concrete queue-head completion
outputs/rules/assertions under one selected response family, keep the
request-ID bus as the auto-ID lifecycle generated output, and add concrete
request-ID drive rules for same-family concrete transactions. Selector `.195`
selected `.196`, readiness audit for mixed read-data consumption over
same-family mixed auto-ID plus concrete same-ID queue-head response-demux.
Audit `.196` selected `.197`, direct bounded implementation of scalar
read-data consumption for the read single-beat and read burst-last mixed
families. Implementation `.197` now ships that bounded scalar read-data
behavior for the read single-beat and read burst-last same-family mixed
auto-ID plus concrete same-ID queue-head response-demux shapes. The public
examples are:

```text
ppif/axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data.ppif
ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data.ppif
```

Both examples keep existing PPIF syntax, bind `RDATA`/`RRESP` outputs for
`r0`, `r1`, and `r2`, reuse the combined generated response-demux completion
pulses, and HDL-verify through the current validation lane. Single-beat
read-data reports
`generated_mixed_auto_id_queue_head_response_demux_completion_pulse`; the
burst-last last-beat shape reports
`generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`.
Selector `.198` selected `.199`, readiness audit for generated report-only
raw-`ARLEN` burst-length capture over the read burst-last same-family mixed
auto-ID plus concrete queue-head scalar last-beat read-data shape. Audit
`.199` found temporary report-only and runtime-assertion probes both generate
through existing helpers, selected `.200` to publish/support-account the
report-only boundary first, and requires `.200` to preserve or lock runtime
validation as separately owned. Implementation `.200` now ships that
support-accounted report-only raw-`ARLEN` burst-length boundary through:

```text
ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif
```

The generated behavior adds width-8 `axi0_arlen`, request-captured raw
`ARLEN` storage for `r0`, `r1`, and `r2`, and the burst-length capture rules
`axi0_r0_burst_length_capture`, `axi0_r1_burst_length_capture`, and
`axi0_r2_burst_length_capture` while preserving scalar last-beat
`RDATA`/`RRESP` capture through
`generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse`.
Schedule, check, and semantic JSON report the support-accounting entry
`intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length`.
Implementation `.202` now ships the runtime-assertion sibling:

```text
ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif
```

That sample reports `burst_length_validation: runtime_assertion`,
`beat_count_match_source: response_demux_matched_read_beat`, expected-beat
storage, read-beat counters, six beat-count rules, twelve beat-count/`RLAST`
assertions, strict support accounting, semantic JSON support, and HDL; it
removes `generated_beat_count_validation` from `read_data.residue`. Mixed
multi-beat read-data, group-local enqueue widening, packed burst-vector
outputs, alternate payload assembly, direct backend, verification-output
generation, VHDL, and backend-language variants remain separately owned.

Post mixed response-demux selector:
[AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RESPONSE_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.196`, the mixed read-data consumption readiness audit.
Mixed read-data readiness audit:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md)
selects `.197`, the direct bounded scalar read-data implementation owner.
Mixed read-data behavior:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_BEHAVIOR.md)
ships `.197`, bounded scalar read-data over same-family mixed auto-ID plus
concrete queue-head response-demux for the read single-beat and read
burst-last public examples.
Post mixed read-data selector:
[AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md)
selects `.199`, the mixed report-only raw-`ARLEN` burst-length readiness
audit.
Mixed burst-length readiness audit:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_READINESS_AUDIT.md)
selects `.200`, the direct support/publication owner for report-only mixed
raw-`ARLEN` burst-length.
Mixed burst-length behavior:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md)
ships `.200`, support-accounted report-only mixed raw-`ARLEN` burst-length
capture, and records the historical pre-`.202` runtime boundary.
Mixed runtime-validation readiness audit:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_READINESS_AUDIT.md)
selects `.202`, the direct bounded implementation owner for generated runtime
beat-count/`RLAST` validation over the same mixed auto-ID plus concrete
queue-head read burst-last scalar last-beat shape.
Mixed runtime-validation behavior:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md)
ships `.202`, support-accounted generated runtime beat-count/`RLAST`
validation over that same mixed burst-last scalar shape.
Post mixed runtime-validation selector:
[AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md)
selects `.204`, support/static and public-contract residue cleanup before
the next mixed behavior expansion.
Mixed runtime-validation support cleanup:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_RESIDUE_CLEANUP.md)
ships `.204`, aligning public/static support wording after the `.202`
runtime-validation behavior.
Post mixed runtime cleanup selector:
[AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_CLEANUP_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_RUNTIME_VALIDATION_SUPPORT_CLEANUP_NEXT_SLICE_SELECTION.md)
selects `.206`, the mixed multi-beat output-bank readiness audit.
Mixed multi-beat readiness audit:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READINESS_AUDIT.md)
selects `.207`, the direct bounded implementation owner for generated
multi-beat output-bank behavior over the `.202` same-family mixed auto-ID
plus depth-2 concrete same-ID queue-head runtime-validation shape. The audit
found the current blocker is local to the mixed read-data coverage predicate;
transaction-list output-bank, aggregate, burst-length, beat-count, assertion,
and report helpers are already ready after admission.
Mixed multi-beat behavior:
[AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR](../../AXI_IAL2_MANAGER_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md)
ships `.207`, generated mixed multi-beat output-bank behavior over that
same-family mixed auto-ID plus depth-2 concrete same-ID queue-head
runtime-validation shape. The support-accounted sample is
`ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif`;
it reports the mixed last-beat completion validity, three covered read
transactions, 48 generated RDATA lane outputs, 48 generated RRESP lane
outputs, three valid masks, three length outputs, three scalar `RRESP`
aggregate outputs, 48 lane capture rules, runtime beat-count/`RLAST`
assertions, strict support accounting, semantic JSON, HDL, and empty read-data
residue.
Post mixed multi-beat selector:
[AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MIXED_AUTO_ID_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md)
selects `.209`, readiness audit for group-local simultaneous enqueue widening
across generated concrete same-ID queue-head families. Representative read
multi-group, write multi-group, and `.207` mixed multi-beat samples still use
a family-wide request onehot assertion, so `.209` must audit admission,
direction-level capacity accounting, transition generation, and preservation
before any behavior change.
Group-local enqueue audit:
[AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_GROUP_LOCAL_SAME_ID_ENQUEUE_READINESS_AUDIT.md)
selects `.210`, counted admission/capacity prerequisite audit. The live
generator still reports one Boolean request fan-in per direction and one
family-wide same-ID request onehot assertion, while generated queue transition
rules are already per concrete-ID group. Group-local enqueue widening therefore
must first own counted request admission and pending/status accounting.
Counted admission/capacity audit:
[AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT](../../AXI_IAL2_MANAGER_COUNTED_ADMISSION_CAPACITY_READINESS_AUDIT.md)
selects `.211`, the bounded implementation owner for counted same-ID request
capacity substrate while preserving family-wide request onehot behavior. The
audit places counted admission in the shared capacity/status matrix, rejects a
separate same-ID-only overlay, defines additive `request_accounting` and
`generated_scheduler_or_status_rules` report fields, and keeps group-local
simultaneous enqueue acceptance deferred until the counted substrate is proven.
Counted capacity substrate behavior:
[AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR](../../AXI_IAL2_MANAGER_COUNTED_SAME_ID_CAPACITY_SUBSTRATE_BEHAVIOR.md)
ships `.211` for generated same-ID queue-head families with multiple
concrete-ID groups. The generated read/write multi-group reports now expose
`counted_same_id_selected_requests`, counted request groups, additive request
count expressions, `counted_submit` capacity matrices, Boolean completion
accounting, and `reject_current_request_set` over-capacity behavior while the
family-wide request onehot assertions remain in force.
Post counted-capacity selector:
[AXI_IAL2_MANAGER_POST_COUNTED_CAPACITY_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_COUNTED_CAPACITY_NEXT_SLICE_SELECTION.md)
selects `.213`, readiness audit for admitted-request guard alignment before
group-local same-ID enqueue behavior. The counted matrix can reject an
over-capacity current request set, but admitted-request pulses still use
scalar pending storage plus Boolean completion fan-in, so direct group-local
onehot narrowing is not safe until those guards are owned.
Counted admitted-request guard audit:
[AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT](../../AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_READINESS_AUDIT.md)
selects `.214`, direct bounded implementation of counted admitted-request
guard alignment and group-local request assertions for generated multi-group
queue-head families. The implementation should derive the admitted-request
fit guard from the counted capacity/status matrix semantics and preserve
Boolean admission plus family-wide assertions for non-counted directions and
mixed auto-ID single concrete-group directions.
Counted admitted-request guard behavior:
[AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR](../../AXI_IAL2_MANAGER_COUNTED_ADMITTED_REQUEST_GUARD_BEHAVIOR.md)
ships `.214`. Counted multi-group queue-head families now gate
admitted-request pulses with a request-set fit expression derived from the
counted capacity/status matrix, replace the family-wide request onehot with
per-concrete-ID group request assertions, and preserve Boolean admission plus
family-wide assertions for non-counted directions and mixed auto-ID single
concrete-group directions. The counted report surface now also carries
`request_count_evaluation_terms`, `request_count_evaluation_expression`, and
`request_count_evaluation_width` so generated guards and equality checks use
exact-width zero-extended request-count expressions.
Post counted group-local enqueue selector:
[AXI_IAL2_MANAGER_POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_COUNTED_GROUP_LOCAL_ENQUEUE_NEXT_SLICE_SELECTION.md)
selects `.216`, readiness audit for dynamic same-ID issue-order queues beyond
selected counted concrete-ID queue-head groups. The selector found no cleanup
prerequisite after `.214`; the next local ordering residue is dynamic/per-ID
issue-order behavior rather than another concrete queue-head sibling.
