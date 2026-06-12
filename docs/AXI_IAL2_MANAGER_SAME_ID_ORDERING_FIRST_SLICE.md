# AXI IAL2 Manager Same-ID Ordering First Slice

This note records the implementation outcome for
`IAL2-FEATURE-COMPLETENESS-FRONTIER.35`.

## Shipped Boundary

FSMGen now formalizes the first bounded AXI same-ID ordering boundary for
generated auto-ID families. The shipped strategy is conservative:

```text
same-ID ordering by avoiding same-ID concurrency
```

The generated auto-ID allocator already treats a pool ID as free only when no
active transaction state is busy with that selected ID. This slice makes that
invariant explicit through generated runtime assertions and machine-readable
report metadata.

For two generated write auto-ID transactions, generated IAL1 now emits a
same-ID ordering assertion such as:

```text
(transaction axi0_same_id_ordering_checks
  (assert
    (=> (& axi0_w0_auto_id_busy_q axi0_w1_auto_id_busy_q)
        (! (== axi0_w0_auto_id_q axi0_w1_auto_id_q)))
    "axi0 write auto ID active selected IDs are unique"))
```

The assertion lowers through existing `.fsm` `+assert` carriers and the
SystemVerilog assertion backend. No public `.ppif` syntax changed.

## Report Contract

The schedule/report surface keeps schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

For the checked-in response-demux sample, `auto_id_lifecycle.residue` is now
empty because generated demux drives release and generated same-ID avoidance
covers the generated auto-ID write-demux subset:

```text
auto_id_lifecycle:
  generated_behavior: true
  residue: []
```

The `response_demux` residue no longer lists `same_id_ordering` for the
covered generated write auto-ID path:

```text
response_demux:
  generated_behavior: true
  residue:
    - read_response_demux
    - read_data_interleaving
    - bursts
```

The new machine-readable section is:

```text
same_id_ordering:
  mode: auto_id_same_id_avoidance
  generated_behavior: true
  strategy: avoid_same_id_concurrency
  families:
    - family: write
      strategy: avoid_same_id_concurrency
      enforcement: allocator_free_id_guard
      assertion_enforcement: runtime_assertion
      response_demux_covered: true
      auto_transactions: [w0, w1]
      selected_id_signals: [axi0_w0_auto_id_q, axi0_w1_auto_id_q]
      busy_signals: [axi0_w0_auto_id_busy_q, axi0_w1_auto_id_busy_q]
      generated_assertions:
        - axi0_w0_w1_auto_id_unique_active_id
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
    - read_response_demux
    - read_data_interleaving
    - bursts
```

`id_response_rule_engine.residue` still includes `same_id_ordering`, because
authored concrete-ID same-ID cases and per-ID issue-order queues are not
implemented by this slice.

## Runnable Sample

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif
```

Focused generator and PPIF/CLI tests cover the generated assertion, report
metadata, residue shape, and SystemVerilog reachability.

## Residue

This slice does not implement per-ID issue-order queues or scoreboards,
authored concrete-ID same-ID ordering, read `RID` response demux, read-data
interleaving/reassembly, bursts, queued/blocking policy, profile aliases, full
AXI manager behavior, or VHDL backend/reroute behavior.
