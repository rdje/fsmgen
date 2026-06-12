# AXI IAL2 Manager Capacity/Status Generator First Slice

Status: first in-process AXI manager capacity/status generator slice shipped.
Public `.ppif` syntax for this manager object remains a later exact owner.

Task tree:
[docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md](tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md).

Implementation:
`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`.

## Scope

This slice introduces the first behavior-bearing AXI manager IAL2 object after
the Valid-Ready monitor and bundle surfaces. It is intentionally a
capacity/status shell:

- one in-process Perl API,
- one structured contract hash,
- explicit read and write pending depths,
- abstract read/write submit and completion events,
- `try`-policy acceptance/status feedback,
- generated reviewable `.isf` before generated `.fsm`,
- existing `FSM::Adapter::ISF` parse path,
- existing `FSM::Scheduler::ISF` lower/report path,
- existing SystemVerilog generation from the scheduled `.fsm`.

It does not add public `.ppif` syntax, profile aliases, channel expansion, ID
allocation, ordering, response matching, burst/last-beat tracking,
blocking/queued submission policy, or VHDL backend behavior.

## In-Process API

```perl
use FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus;

my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate({
    name              => 'axi0',
    intent_name       => 'axi_manager_capacity_status',
    protocol          => 'axi4',
    submit_policy     => 'try',
    clock             => 'clk',
    reset             => { signal => 'rst_n', active_low => 1, async => 1 },
    read_max_pending  => 4,
    write_max_pending => 2,
    read_submit       => 'axi0_read_submit',
    read_complete     => 'axi0_read_complete',
    write_submit      => 'axi0_write_submit',
    write_complete    => 'axi0_write_complete',
    status            => {
        read_can_accept       => 'axi0_read_can_accept',
        write_can_accept      => 'axi0_write_can_accept',
        read_full             => 'axi0_read_full',
        write_full            => 'axi0_write_full',
        pending_reads         => 'axi0_pending_reads',
        pending_writes        => 'axi0_pending_writes',
        read_slots_available  => 'axi0_read_slots_available',
        write_slots_available => 'axi0_write_slots_available',
    },
    source => {
        object_id => 'axi-manager-capacity-status',
        anchors => [
            { document => 'IHI0022_L_2025-08', section => 'A1.1' },
            { document => 'IHI0022_L_2025-08', section => 'A1.2' },
            { document => 'IHI0022_L_2025-08', section => 'A5.1' },
        ],
    },
});
```

The returned result contains:

- `generated_ial1`: the generated `.isf` artifact name and text,
- `generated_ial0`: the generated `.fsm` file map emitted by
  `FSM::Scheduler::ISF`,
- `generated_ial1_schedule_report`: the existing IAL1 schedule report,
- `report`: the IAL2 capacity/status report.

The generator has no `lower_to_fsm` shortcut. The only lowering path is the
reviewable chain `IAL2 -> generated .isf -> generated .fsm -> SystemVerilog`.

## Contract Fields

Required fields:

| Field | Meaning |
| --- | --- |
| `name` | Manager object name; also seeds generated actor, storage, and default status names. |
| `protocol` | Must be `axi4` in this first slice. |
| `submit_policy` | Must be `try` in this first slice. |
| `clock` | ISF clock signal name. |
| `reset` | Reset binding, either a signal name or `{ signal, active_low, async }`. |
| `read_max_pending` | Positive integer read outstanding-capacity depth. |
| `write_max_pending` | Positive integer write outstanding-capacity depth. |
| `read_submit` / `write_submit` | Abstract submit event inputs. |
| `read_complete` / `write_complete` | Abstract completion event inputs. |

Optional fields:

| Field | Meaning |
| --- | --- |
| `actor_name` | Generated IAL1 actor name; defaults to `${name}_capacity_status`. |
| `intent_name` | Optional report identity for the source intent. |
| `status` | Optional namespaced output-name overrides. |
| `source.object_id` | Stable source-object identity used in the IAL2 report. |
| `source.anchors` | Source anchors, typically PDF section/page references. |

All generated `.isf` signal names must be valid identifiers. Clock, reset,
abstract events, status outputs, and generated pending-counter storage names
must be unique. Bare `can_accept` is rejected because the IAL1 scheduler owns
that reserved acceptance signal internally.

## Generated IAL1 Shape

The example above emits one reviewable `.isf` actor named
`axi0_capacity_status` with:

- abstract read/write submit and completion inputs,
- namespaced read/write `can_accept` outputs,
- read/write full outputs,
- read/write pending-count outputs,
- read/write available-slot outputs,
- actor-owned pending counters,
- explicit rule matrices for idle, submit-only, complete-only, and
  submit+complete cases in each direction.

A representative emitted shape is:

```text
(actor axi0_capacity_status
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input axi0_read_submit)
    (input axi0_read_complete)
    (input axi0_write_submit)
    (input axi0_write_complete)
    (output axi0_read_can_accept)
    (output axi0_write_can_accept)
    (output axi0_read_full)
    (output axi0_write_full)
    (output axi0_pending_reads (width 3))
    (output axi0_pending_writes (width 2))
    (output axi0_read_slots_available (width 3))
    (output axi0_write_slots_available (width 2)))
  (storage
    (var axi0_pending_reads_q (width 3))
    (var axi0_pending_writes_q (width 2)))
  ...)
```

For each direction, submit-only increments until full, complete-only
decrements until empty, idle preserves the counter, and same-cycle
submit+complete preserves the nonzero count while allowing a full slot to be
reused.

## IAL2 Report

The IAL2 report schema is:

```text
fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1
```

The report includes:

- `mode => capacity-status-shell`,
- layering evidence that direct IAL2-to-IAL0 lowering is unavailable,
- source object identity and anchors,
- manager name, actor name, and protocol,
- read/write `max_pending`, counter width, and storage name,
- status output bindings,
- abstract event bindings,
- generated `.isf` and `.fsm` artifact names,
- generated read/write rule summaries,
- report-only capacity blocked-reason vocabulary,
- assumptions,
- enforced static rules,
- unsupported residue.

The blocked-reason vocabulary is report metadata only in this first slice:

- `none`
- `max_pending_reached`
- `unsupported_transaction_kind`

## Validation

Focused coverage lives in
[t/1437-axi-ial2-manager-capacity-status-generator.t](../t/1437-axi-ial2-manager-capacity-status-generator.t).
It proves:

- generated `.isf` exists before generated `.fsm`,
- generated `.isf` parses through `FSM::Adapter::ISF`,
- generated `.fsm` is emitted by `FSM::Scheduler::ISF`,
- generated `.fsm` exposes read/write pending counters and status updates,
- SystemVerilog generation reaches the namespaced status/counter surface,
- report schema, source anchors, artifacts, capacity metadata, assumptions,
  static rules, and residue are populated,
- `max_pending = 1` and larger depths are representable,
- full submit-only attempts block acceptance,
- same-cycle submit+complete at full accepts by reusing freed capacity,
- malformed or unsupported contract objects fail closed,
- no direct `lower_to_fsm` IAL2 entrypoint is exposed.

## Explicit Residue

Still out of scope after this slice:

- public `.ppif` capacity/status syntax,
- `.axi` or other profile suffix aliases,
- public samples and support-accounting entries for capacity/status `.ppif`,
- capacity/status semantic JSON and check JSON public source-identity coverage,
- HDL blocked-reason output encoding,
- `blocking` submission policy,
- `queued` submission policy,
- ID allocation,
- user ID validation,
- same-ID ordering,
- different-ID interleaving,
- response matching through `BID`/`RID`,
- burst length/size/last-beat tracking,
- write-data sequencing,
- channel expansion,
- full Easy/Power/supervised Raw APIs,
- platform placement/resource mapping,
- and VHDL backend/reroute behavior.
