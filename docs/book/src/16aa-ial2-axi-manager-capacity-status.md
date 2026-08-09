# AXI Manager Capacity and Status

The [AXI IAL2 examples](16a-ial2-axi.md) introduce guided channel monitors and
bounded request/transaction drivers. This chapter is the detailed reference for
the separate AXI manager capacity/status family: 140 checked-in `.ppif` sources
that all elaborate one `(manager-capacity-status ...)` object.

The family is a composable, bounded manager-side bookkeeping core. It can count
pending reads and writes, expose acceptance/status signals, describe transaction
identity, and—when explicitly selected—generate bounded ID lifecycle, ordering,
response-demultiplexing, and read-data behavior. It is not by itself a complete
AXI manager: the foundational shell does not drive AW, W, or AR handshakes,
addresses, write data, strobes, or `WLAST`.

## Read the family as progressive clauses

The 140 sources are executable fixture combinations, not 140 unrelated language
features. Each source retains the same outer object and adds clauses to make one
bounded contract explicit. These six sources form the foundation:

| Source | What it adds |
| --- | --- |
| `ppif/axi_manager_capacity_status.ppif` | Pending limits, abstract submit/completion events, `try` acceptance, and status outputs. |
| `ppif/axi_manager_capacity_status_id_family.ppif` | Read and write request/response ID-family metadata. |
| `ppif/axi_manager_capacity_status_transaction_envelope.ppif` | Named write/read transactions with auto and concrete ID modes. |
| `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif` | Per-transaction request/completion events with direction-level fan-in. |
| `ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif` | An explicit bounded write-ID pool and generated lifecycle behavior. |
| `ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif` | User-owned dynamic ID metadata, without silently generating arbitration. |

All six lower through the same review path:

```text
IAL2 .ppif
  -> generated axi0_capacity_status.isf
  -> generated axi0_capacity_status.fsm
  -> SystemVerilog module axi0_capacity_status
```

There is no direct IAL2-to-IAL0 shortcut.

## Run the foundation review path

From the repository root, select any foundation source and run every public
view before integrating its generated HDL:

```bash
manager_example=ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --quiet --strict --check --json "$manager_example"
./bin/fsmgen --quiet --emit-schedule-json "$manager_example"
./bin/fsmgen --quiet --strict --emit-semantic-json "$manager_example"
./bin/fsmgen --quiet --strict --outdir .artifacts/ial2/axi-manager-foundation "$manager_example"
./bin/fsmgen --verify-hdl "$manager_example"
```

The outdir contains exactly the two intermediate review sources:

```text
.artifacts/ial2/axi-manager-foundation/axi0_capacity_status.isf
.artifacts/ial2/axi-manager-foundation/axi0_capacity_status.fsm
```

The schedule report uses schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`, reports mode
`capacity-status-shell`, and records `direct_ial2_to_ial0: 0`. Strict check JSON
reports module `axi0_capacity_status`; `--verify-hdl` validates the generated
SystemVerilog with Verilator and Yosys.

## Capacity and status: the complete base source

`ppif/axi_manager_capacity_status.ppif` is the smallest runnable source:

```text
(protocol-platform-intent axi_manager_capacity_status
  (profile axi4)
  (source
    (object axi-manager-capacity-status)
    (anchor (document IHI0022_L_2025-08) (section A1.1) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A1.2) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A5.1) (page A5-1)))
  (manager-capacity-status axi0
    (clock clk)
    (reset (rst_n active_low async))
    (read-max-pending 4)
    (write-max-pending 2)
    (submit-policy try)
    (read-submit axi0_read_submit)
    (read-complete axi0_read_complete)
    (write-submit axi0_write_submit)
    (write-complete axi0_write_complete)
    (status
      (read-can-accept axi0_read_can_accept)
      (write-can-accept axi0_write_can_accept)
      (read-full axi0_read_full)
      (write-full axi0_write_full)
      (pending-reads axi0_pending_reads)
      (pending-writes axi0_pending_writes)
      (read-slots-available axi0_read_slots_available)
      (write-slots-available axi0_write_slots_available))))
```

The read and write directions are independent. The generated shell holds a
three-bit read counter for the `0..4` range and a two-bit write counter for the
`0..2` range. Each direction reports four views of that state:

| Output | Meaning |
| --- | --- |
| `*-pending-*` | Current bounded occupancy. |
| `*-slots-available` | Remaining capacity. |
| `*-full` | Occupancy is at its configured maximum. |
| `*-can-accept` | A submit is accepted under `try`, including a same-cycle completion that frees capacity. |

Submit and completion names are abstract events at this level. The shell does
not infer them from AXI channel handshakes or `BID`/`RID`. Its schedule report
therefore describes `boolean_submit` and `boolean_fanin` accounting: at most one
occupancy change of each kind is represented per direction per cycle.

The strict check for this source reports 44 signals and support entry
`intent.ppif_axi_manager_capacity_status`.

## Add request and response ID families

`ppif/axi_manager_capacity_status_id_family.ppif` retains the complete base
source and inserts this exact clause before `(status ...)`:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

An ID family declares the width and the signal names that later clauses may
own or observe. Positive-width families require both request and response names;
width zero rejects those names. Read/write ID signals, event names, status
outputs, clock/reset, and generated storage names must remain unique.

This clause alone is metadata. The schedule report adds `id_families.read` and
`id_families.write`, but the strict check still reports the base shell's 44
signals. The ID signals become HDL ports only when a behavior-bearing clause
uses them—for example a concrete-ID assertion, explicit auto-ID lifecycle, or
supported response-demultiplexing shape.

## Add logical transactions

`ppif/axi_manager_capacity_status_transaction_envelope.ppif` retains both the
base and ID-family clauses and adds:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id (value 3))))
```

Each transaction has a unique name and tag, a read/write kind, request and
completion events, and one ID policy. The normalized report keeps these as
structured `transactions[]` entries rather than raw source strings.

The two ID forms deliberately have different behavior here:

- `(id (value 3))` is a concrete (static) read ID. Value 3 is checked against
  the four-bit read family. The generator adds request-time `ARID == 3` and
  completion-time `RID == 3` verification assertions, so the strict result
  grows from 44 to 46 signals.
- `(id auto)` declares allocation intent, but it does not silently construct an
  allocator. Until an explicit `(auto-id-lifecycle ...)` clause is present, it
  remains structural/report metadata.

The schedule report names the two concrete checks `r0_request_id_matches` and
`r0_response_id_matches`. Its residue still lists auto-ID allocation, release,
same-ID ordering, and response demultiplexing because this source did not select
those behaviors.

## Dispatch distinct transaction events

The transaction-envelope source above reuses the direction-level events. The
complete runnable dispatch variant is
`ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif`; its exact
transaction clause is:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id auto))
  (write w1
    (tag wr1)
    (request axi0_w1_request)
    (completion axi0_w1_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id (value 3))))
```

The schedule report emits `transaction_event_dispatch.mode` as
`per_transaction_event_fanin`. The write side becomes:

```text
request events:    axi0_w0_request, axi0_w1_request
request fan-in:    (| axi0_w0_request axi0_w1_request)
completion events: axi0_w0_complete, axi0_w1_complete
completion fan-in: (| axi0_w0_complete axi0_w1_complete)
```

The read side remains scalar because it has one transaction. Concrete-ID
assertions follow the transaction-local events, so `r0` checks `ARID` on
`axi0_r0_request` and `RID` on `axi0_r0_complete`.

The fan-in contract is Boolean, not a per-cycle population count. Two
same-direction request events asserted in one cycle do not mean “add two” to
the capacity shell. Behavior that admits and counts multiple requests in one
cycle needs an explicitly supported counted request-set shape; it must not be
inferred from this foundational dispatch fixture.

## Make auto IDs behavior-bearing

`ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif` uses the same three
transactions and adds one explicit lifecycle:

```text
(auto-id-lifecycle
  (write (pool 0 1)))
```

This clause changes the two write transactions from metadata into a bounded
generated allocator contract:

- pool entries are unique, fit the declared ID width, and are bounded to one
  through four values per family;
- allocation is deterministic first-free in authored pool order;
- `axi0_awid` becomes a generated output and `axi0_bid` remains an input;
- each auto transaction receives busy state and selected-ID storage;
- its completion event releases the selected ID;
- runtime assertions reject a request with no ID available, completion of an
  inactive transaction, simultaneous same-family requests, and duplicate
  active selected IDs.

The schedule report names mode `bounded_pool_contract`, reports
`generated_behavior: true`, and records `transaction_lifetime: single_active`.
The strict result contains 142 signals because allocator state, guards, ID
drive, and assertions are now present.

This source still does not derive `axi0_w0_complete` or `axi0_w1_complete` from
`BID`. Those completion events are inputs supplied by the surrounding design.
Generated response matching requires an explicit supported `(response-demux
...)` clause; the lifecycle report correctly keeps `response_demux` as residue.

## Describe user-owned dynamic IDs

`ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif` uses the base
ID families and this transaction clause:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id dynamic))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id dynamic)))
```

For this foundational source, `dynamic` means the request ID is supplied by the
user through the matching request-ID signal. The schedule report preserves the
family, width, request source, response signal, `ownership: user_supplied`, and
`implementation_status: selected_not_generated`. Consequently, this source's
strict result remains the 44-signal base shell: the ID names are report metadata
and no capture, response matching, arbitration, or ordering is invented.

This is a local statement about the simple metadata fixture, not a claim that
every dynamic-ID source is report-only. Other checked-in family members select
specific bounded dynamic response-demux, issue-order-queue, and read-data
contracts explicitly. Their behavior comes from those additional clauses.

## ID modes at a glance

| Authored form | Owner in the foundation | Generated effect |
| --- | --- | --- |
| `(id (value N))` | Author fixes one ID value. | Validates width/range and generates request/response ID assertions when the concrete transaction is used. |
| `(id auto)` | Generator only after explicit lifecycle selection. | Metadata alone; with `(auto-id-lifecycle ...)`, generates bounded first-free allocation, drive, state, release, and assertions. |
| `(id dynamic)` | User supplies the request ID. | The simple fixture reports `selected_not_generated`; supported behavior requires an additional explicit dynamic matching/ordering/data clause. |

The explicit clauses prevent an authoring convenience from silently becoming a
different hardware ownership model.

## Select a same-ID policy explicitly

Same-ID ordering is a per-direction contract. The policy names both the ID
ownership model and the permitted reuse behavior:

```text
(same-id-ordering
  (read (concrete-id-reuse reject)))

(same-id-ordering
  (read (dynamic-id-reuse reject)))

(same-id-ordering
  (read (concrete-id-reuse issue-order-queue)))

(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

Accepted syntax does not by itself promise generated hardware. The schedule
report is authoritative for the selected source:

| Policy-only source | Enforcement in that source | Generated queue |
| --- | --- | --- |
| `ppif/axi_manager_capacity_status_same_id_reject_policy.ppif` | `static_validation`: duplicate authored concrete IDs fail closed. | No |
| `ppif/axi_manager_capacity_status_dynamic_same_id_reject_policy.ppif` | `selected_not_generated`: the user-owned runtime ID cannot be rejected by metadata alone. | No |
| `ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif` | Generates one capacity-guarded admitted-request pulse, but its single concrete transaction does not reuse an ID. | No |
| `ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif` | `selected_not_generated` until a supported bounded response-demux shape supplies the runtime matching contract. | No |

The `reject` forms therefore have different proof boundaries. Concrete values
can be compared while the source is validated. A dynamic value exists only at
runtime; the policy-only fixture records `request_conflict_policy:
no_active_same_id`, but reports `enforcement: not_generated`. Integrators must
not treat that metadata as a generated exclusion circuit.

Likewise, `issue-order-queue` becomes behavior-bearing only for an explicitly
supported transaction population plus response-demux clause. Policy-only
metadata does not imply a queue, a scoreboard, or acceptance of duplicate IDs.

## Queue-head ordering and generated completion

For a generated concrete queue-head contract, FSMGen groups transactions by
their authored concrete ID. An admitted request appends its transaction to that
ID group's compact one-hot slot queue. A matching response may complete only
the transaction at the queue head:

```text
admitted request -> append transaction to its concrete-ID queue
accepted B + matching BID -> pulse the matching write queue head
accepted R + matching RID + RLAST -> pulse the matching burst-read queue head
```

The request boundary is capacity-aware and includes same-cycle completion when
deciding whether the request set fits. In a multi-group fixture, request events
are OR-reduced within each concrete-ID group, asserted one-hot-or-zero within
that group, and counted across groups. Thus ID 3 and ID 5 may each admit one
request in the same cycle when capacity permits; two transactions in the same
ID group may not both be admitted in that cycle.

Generated state covers empty enqueue, append, dequeue, and same-cycle
dequeue/enqueue transitions. Assertions cover compact slots, queue capacity,
nonempty response/dequeue, unique head matching, and transaction uniqueness.
This is finite queue-head routing for declared groups, not a general AXI
scoreboard.

The response clause changes completion ownership:

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))

(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The direction-level response event and `BID`/`RID` remain inputs representing
an accepted response supplied by the surrounding design. Transaction-local
completion names become generated pulse outputs. Write demux matches `BID`;
single-beat read demux matches `RID`; burst-last read demux additionally
requires `RLAST`. A response-demux-only read source does not capture `RDATA` or
`RRESP`; read-data capture is a separate explicit contract, not implied here.

## Run the concrete multi-group write/read pair

These two complete sources exercise the same two independent depth-2 groups in
opposite directions:

| Source | Groups | Generated completion rule |
| --- | --- | --- |
| `ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif` | `w0/w1` use `BID=3`; `w2/w3` use `BID=5`. | Matching `BID` plus that group's queue head. |
| `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif` | `r0/r1` use `RID=3`; `r2/r3` use `RID=5`. | Matching `RID`, asserted `RLAST`, and that group's queue head. |

Both author:

```text
(same-id-ordering
  (<direction> (concrete-id-reuse issue-order-queue)))
(response-demux
  (<direction>
    (response-event <accepted-response-event>)
    ...
    (transaction-completion generated)))
```

Their schedule reports make the bounded implementation measurable:

| Report fact | Write pair | Read pair |
| --- | ---: | ---: |
| Concrete-ID groups | 2 | 2 |
| Queue depth per group | 2 | 2 |
| Admitted-request pulses | 4 | 4 |
| Queue slot signals | 8 | 8 |
| Queue update rules | 24 | 24 |
| Queue assertions | 22 | 24 |
| Completion outputs / demux rules | 4 / 4 | 4 / 4 |
| Response-demux assertions | 7 | 7 |

Run the sources from the repository root:

```bash
for manager_example in \
  ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif \
  ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif
do
  ./bin/fsmgen --quiet --strict --check --json "$manager_example"
  ./bin/fsmgen --quiet --emit-schedule-json "$manager_example"
  ./bin/fsmgen --quiet --verify-hdl "$manager_example"
done
```

Depth-3, multiple-depth-3, and mixed depth-3/depth-2 checked-in sources extend
the same finite model. The filename identifies the selected cardinality; it is
not a request for an arbitrary queue depth.

## Mix dynamic and concrete IDs within a bounded contract

`ppif/axi_manager_capacity_status_write_mixed_dynamic_static_same_id_issue_order_queue.ppif`
is the compact behavior-bearing mixed example. Its two write transactions and
additive clauses are:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id dynamic))
  (write w1
    (tag wr1)
    (request axi0_w1_request)
    (completion axi0_w1_complete)
    (id (value 3))))
(same-id-ordering
  (write (dynamic-id-reuse issue-order-queue)))
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

An admitted `w0` request captures the user-supplied `AWID`; `w1` contributes
the literal ID 3. The generated depth-2 queue stores both transaction identity
and the captured-or-static runtime ID. An accepted `BID` completes the earliest
matching slot, so a dynamic `w0` request using ID 3 is ordered with `w1` rather
than treated as a distinct population. The report exposes six slot signals, 18
update rules, 15 queue assertions, two demux rules, two demux assertions, and
two generated completion outputs. It explicitly reports
`generated_scoreboard_behavior: false`.

Current public sources intentionally enumerate bounded combinations:

| Population family | Checked-in bounds |
| --- | --- |
| Concrete queue-head | Depth 2 or 3; single, multiple independent, and mixed depth-3/depth-2 groups for selected write, read single-beat, and read burst-last shapes. |
| All-dynamic issue-order queue | Two or three same-direction transactions for selected write `BID`, read single-beat `RID`, and read burst-last `RID/RLAST` shapes. |
| Mixed dynamic/static issue-order queue | One dynamic plus one concrete transaction for selected write and read shapes. |
| Mixed dynamic/static response matching | One dynamic plus one, two, or three concrete transactions, and selected two-dynamic-plus-one-concrete shapes. |

These rows describe fixture populations, not four orthogonal language switches.
Support for one clause in one row does not authorize a new cardinality or a
different cross-row composition. Use a checked-in source with the desired shape
and confirm its schedule report; absent combinations fail closed.

The remaining boundary is deliberate: there is no arbitrary transaction
cardinality, arbitrary-depth per-ID queue, generalized scoreboard policy, or
general different-ID interleaving beyond the selected auto-ID, dynamic, mixed,
and concrete queue-head fixtures. This chapter also does not turn the
capacity/status object into a bus-driving AXI manager.

## Reports, artifacts, and support identity

The six foundation sources are independently support-accounted:

| Source suffix | Strict-check entry ID | Signals |
| --- | --- | ---: |
| `capacity_status` | `intent.ppif_axi_manager_capacity_status` | 44 |
| `capacity_status_id_family` | `intent.ppif_axi_manager_capacity_status_id_family` | 44 |
| `capacity_status_transaction_envelope` | `intent.ppif_axi_manager_capacity_status_transaction_envelope` | 46 |
| `capacity_status_transaction_event_dispatch` | `intent.ppif_axi_manager_capacity_status_transaction_event_dispatch` | 72 |
| `capacity_status_auto_id_lifecycle` | `intent.ppif_axi_manager_capacity_status_auto_id_lifecycle` | 142 |
| `capacity_status_dynamic_transaction_id` | `intent.ppif_axi_manager_capacity_status_dynamic_transaction_id` | 44 |

Use each report for a different review question:

- strict check JSON proves source acceptance, support accounting, module name,
  diagnostic absence, and the resulting signal count;
- schedule JSON is the authoritative IAL2 contract view for capacities,
  transaction identity, generated rules, layering, and residue;
- semantic JSON shows the normalized scheduled structure that reaches the HDL
  renderer;
- the outdir preserves the generated IAL1 and IAL0 sources for human review;
- `--verify-hdl` checks the final SystemVerilog with external tools.

## Supported family and explicit residue

Every one of the 140 manager sources includes the capacity/status shell. The
remaining clauses overlap: 139 sources declare ID families, 138 declare
transactions, 17 select auto-ID lifecycle, 78 select same-ID ordering, 130
select response demultiplexing, 79 select read-data behavior, and 48 select
burst-length behavior. Those counts describe a composition matrix; they must
not be added together or interpreted as independent feature totals.

This bounded manager family does not claim:

- a bus-driving AXI manager or automatic derivation of submits/completions from
  AW/W/B/AR/R handshakes;
- queued or blocking submit policy beyond the shipped `try` shell;
- implicit allocation for `(id auto)` or implicit matching for `(id dynamic)`;
- arbitrary transaction cardinality, arbitrary same-ID queue depth, a general
  scoreboard, or general different-ID interleaving;
- packed whole-burst outputs or an unbounded payload reassembler;
- a manager-capacity/status `.axi` alias, direct IAL2-to-IAL0 lowering, direct
  IAL2-to-HDL lowering, VHDL behavior, or backend rerouting.

Treat the checked-in source and its schedule report as the exact contract for a
selected combination. If a desired combination is absent or fails closed, it
is not supported merely because its individual clauses appear elsewhere.

## Validation set

Parser/CLI, generator, dynamic-ID, and corpus-accounting coverage lives in
`t/1436-ial2-ppif-parser-cli.t`,
`t/1437-axi-ial2-manager-capacity-status-generator.t`,
`t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t`, and
`t/248-regression-corpus-accounting.t`, respectively.

For a bounded review of this chapter, run strict check JSON and `--verify-hdl`
on all six foundation sources listed at the start, the four policy-only sources
in the same-ID table, the mixed dynamic/static write example, and the concrete
multi-group write/read pair. Then build the book with `mdbook build docs/book`.
That bounds the review to the documented public shapes.
