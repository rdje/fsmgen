# AXI IAL2 Manager Auto-ID Request-ID Drive First Slice

Status: shipped for the public `.ppif` AXI manager capacity/status object.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

This slice implements the first behavior-bearing boundary for the explicit
`auto-id-lifecycle` contract selected by
[docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md](AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md)
and parsed/reported by
[docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md](AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md).

## Shipped Behavior

For each family listed under `(auto-id-lifecycle ...)`, FSMGen now emits
bounded first-free request-ID drive through the normal
`IAL2 -> IAL1/.isf -> IAL0/.fsm -> SystemVerilog` path.

The generated IAL1:

- declares the family request ID signal as a generated output, for example
  `(output axi0_awid (width 4))`;
- leaves response ID signals such as `axi0_bid` out of the interface unless a
  concrete response assertion or later response-check slice needs them;
- declares per-auto-transaction selected-ID and busy state such as
  `axi0_w0_auto_id_q` and `axi0_w0_auto_id_busy_q`;
- emits allocation rules in deterministic pool order, for example
  `axi0_w0_auto_id_alloc_0`, `axi0_w0_auto_id_alloc_1`;
- emits completion release rules such as `axi0_w0_auto_id_release`;
- emits generated priority edges so the existing IAL1 rule-conflict checker
  can verify deterministic first-free allocation without a new IAL1 feature;
- emits runtime assertions for no-ID-available, completion while inactive, and
  simultaneous same-family auto-ID requests.

The generated `.fsm` carries the request-ID output width, selected-ID storage,
busy state, allocation/release rule DTs, and `+assert` carriers. The
SystemVerilog backend declares the request ID as an output register, declares
the selected/busy state registers, and emits the runtime assertions through
the existing assertion backend.

Existing `(id auto)` transactions remain structural/report-only when
`auto-id-lifecycle` is absent.

## Report Contract

The report keeps schema:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The `auto_id_lifecycle` section now reports behavior as generated:

```text
auto_id_lifecycle:
  mode: bounded_pool_contract
  generated_behavior: true
  max_pool_entries_per_family: 4
  families:
    - family: write
      request_id_signal: axi0_awid
      request_id_direction: generated_output
      response_id_signal: axi0_bid
      response_id_direction: generated_input
      pool: [0, 1]
      allocator: first_free_pool_order
      transaction_lifetime: single_active
      release: transaction_completion_event
      no_id_available: runtime_assertion
      auto_transactions: [w0, w1]
      transaction_state:
        - transaction: w0
          selected_id_signal: axi0_w0_auto_id_q
          busy_signal: axi0_w0_auto_id_busy_q
          allocation_rules:
            - axi0_w0_auto_id_alloc_0
            - axi0_w0_auto_id_alloc_1
          release_rule: axi0_w0_auto_id_release
  residue:
    - same_id_ordering
    - response_demux
```

`id_response_rule_engine.residue` also removes `auto_id_allocation` and
`id_release` when explicit auto-ID lifecycle behavior is generated. Concrete
read ID assertions still own their own `ARID`/`RID` inputs.

## Runnable Sample

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
```

Support-accounting entry:

```text
intent.ppif_axi_manager_capacity_status_auto_id_lifecycle
```

## Explicit Residue

This slice does not implement same-ID ordering queues, generated `BID`/`RID`
response demux, read-data interleaving/reassembly, burst or last-beat
tracking, address/data/control payload binding, queued/blocking policy,
profile aliases, full AXI manager syntax, `.pif`, `.ppi`, `.axi`, or VHDL
backend/reroute behavior.
