# AXI IAL2 Valid-Ready Generator First Slice

Status: first in-process generator slice shipped; no public IAL2 CLI suffix is
shipped.

Task tree:
[docs/tasks/AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.md](tasks/AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.md).

Implementation:
`FSM::IAL2::ProtocolIntent::ValidReadyChannel`.

## Scope

This slice introduces the first behavior-bearing IAL2 protocol-intent entrypoint
for one AXI Valid-Ready channel contract. It is intentionally narrow:

- one in-process Perl API,
- one contract object,
- generated reviewable `.isf` before generated `.fsm`,
- existing `FSM::Adapter::ISF` parse path,
- existing `FSM::Scheduler::ISF` lower/report path,
- source-anchor/residue report returned by the IAL2 generator.

It does not add `.pif`, `.ppi`, `.ppif`, `.axi`, or any other CLI/file suffix.
It does not add a public IAL2 parser and does not implement the full AXI
manager.

## In-Process API

```perl
use FSM::IAL2::ProtocolIntent::ValidReadyChannel;

my $result = FSM::IAL2::ProtocolIntent::ValidReadyChannel->new()->generate({
    name     => 'axi_aw',
    protocol => 'axi4',
    channel  => 'AW',
    role     => 'manager-to-subordinate',
    clock    => 'clk',
    reset    => { signal => 'rst_n', active_low => 1, async => 1 },
    valid    => 'awvalid',
    ready    => 'awready',
    payload  => [
        { name => 'awaddr', width => 32 },
        { name => 'awlen',  width => 8 },
    ],
    source => {
        object_id => 'axi-valid-ready-aw',
        anchors => [
            { document => 'IHI0022_L_2025-08', section => 'A3.2.1', page => 'A3-40' },
        ],
    },
});
```

The returned result contains:

- `generated_ial1`: the generated `.isf` artifact name and text,
- `generated_ial0`: the generated `.fsm` file map emitted by
  `FSM::Scheduler::ISF`,
- `generated_ial1_schedule_report`: the existing IAL1 schedule report,
- `report`: the IAL2 source-anchor/residue report.

## Contract Fields

Required fields:

| Field | Meaning |
| --- | --- |
| `name` | IAL2 source-object name; also seeds the generated actor name. |
| `protocol` | `axi`, `axi3`, `axi4`, or `axi5`. |
| `channel` | One AXI channel family: `AW`, `W`, `B`, `AR`, or `R`. |
| `role` | `manager-to-subordinate` or `subordinate-to-manager`. |
| `clock` | ISF clock signal name. |
| `reset` | Reset binding, either a signal name or `{ signal, active_low, async }`. |
| `valid` | Channel `VALID` signal name. |
| `ready` | Channel `READY` signal name. |
| `payload` | Non-empty payload/control signal list; entries may include `width`. |

Optional source fields:

| Field | Meaning |
| --- | --- |
| `source.object_id` | Stable source object identity used in the IAL2 report. |
| `source.anchors` | Source anchors, typically PDF section/page references. |

All signal names that enter generated `.isf` must be ISF identifiers. Payload
widths must be positive integers. Duplicate `valid`, `ready`, payload, or
generated done endpoint names fail closed before `.isf` generation.

## Generated IAL1 Shape

The example above emits reviewable `.isf` shaped like this:

```text
(actor axi_aw_valid_ready_monitor
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input awvalid)
    (input awready)
    (input awaddr (width 32))
    (input awlen (width 8))
    (output axi_aw_valid_ready_monitor_done)
  )
  (transaction monitor
    (on awvalid)
    (assert (=> (& (past awvalid) (! (past awready))) awvalid) ...)
    (assert (=> (& (past awvalid) (! (past awready))) (== awaddr (past awaddr))) ...)
    (assert (=> (& (past awvalid) (! (past awready))) (== awlen (past awlen))) ...)
    (cover (& awvalid awready))
    (complete axi_aw_valid_ready_monitor_done)))
```

The `cover` records the transfer/fire condition `VALID && READY`. The assertions
check the first owned safety subset:

- if the previous cycle presented `VALID` while `READY` was low, `VALID` remains
  asserted in the current cycle,
- each payload/control signal equals its previous sampled value after a
  previous-cycle stall.

These generated checks use the existing IAL1 assertion/property path:
overlapping implication plus `$past`. They do not use `##` delayed temporal
operators, so the first slice remains on the simulable assertion path.

## IAL2 Report

The IAL2 report includes:

- schema `fsmgen.ial2.protocol_intent.valid_ready_channel.v1`,
- `mode => monitor-only`,
- layering evidence that direct IAL2-to-IAL0 lowering is unavailable,
- source object identity and anchors,
- generated `.isf` and `.fsm` artifact names,
- protocol/channel/role and signal bindings,
- `transfer_fire_condition`,
- generated assertion and cover entries,
- assumptions,
- enforced static rules,
- unsupported residue.

Explicit residue remains for reset-valid behavior during reset, READY
independence, and full AXI manager concurrency. Those are not silently claimed
by this first slice.

## Validation

Focused coverage lives in
[t/1435-axi-ial2-valid-ready-generator.t](../t/1435-axi-ial2-valid-ready-generator.t).
It proves:

- generated `.isf` exists before generated `.fsm`,
- generated `.isf` parses through `FSM::Adapter::ISF`,
- generated `.fsm` is emitted by `FSM::Scheduler::ISF`,
- report anchors, artifacts, bindings, assertions, assumptions, and residue are
  populated,
- generated checks surface through the existing assertion-property backend
  path,
- malformed contract objects fail closed,
- no direct `lower_to_fsm` IAL2 entrypoint is exposed.
