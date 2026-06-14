# AXI IAL2 Manager Concrete-ID Same-ID Static Validation First Slice

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.88`

Date: 2026-06-14

## Purpose

This slice implements the conservative static boundary selected by the
concrete-ID same-ID readiness audit.

The shipped concrete-ID assertion path still supports one authored concrete
transaction per read or write ID value. FSMGen now rejects multiple concrete-ID
transactions in the same response family that use the same concrete ID value
until a later owner selects per-ID issue-order queues, scoreboards, or an
explicit same-ID reuse policy.

## Shipped Behavior

For the AXI manager capacity/status IAL2 contract, concrete transaction IDs are
now checked by response family and numeric value before the ID-response rule
engine emits equality assertions.

The fail-closed diagnostic is family-scoped:

```text
AXI manager capacity/status IAL2 contract concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue
```

The same numeric ID may still appear once in the read family and once in the
write family, because AXI read and write responses are separate response
families. The rejection only applies to same-family reuse such as two read
transactions both using `RID` value `3`, or two write transactions both using
`BID` value `3`.

The existing duplicate-event diagnostic remains earlier in the concrete
assertion path. If two concrete transactions share a request or completion
event, FSMGen still reports the existing unique-event diagnostic instead of
the same-ID reuse diagnostic.

## Unchanged Behavior

Valid single-concrete-ID samples keep the same generated artifacts and report
shape:

- `ppif/axi_manager_capacity_status_transaction_envelope.ppif` still emits two
  concrete-ID equality checks and keeps
  `id_response_rule_engine.residue: [auto_id_allocation, id_release,
  same_id_ordering, response_demux]`.
- `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif` still
  emits the per-transaction concrete-ID equality checks for `axi0_r0_request`
  and `axi0_r0_complete`.
- `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif` still reports
  empty `read_data.residue` and `response_demux.residue`, with
  `same_id_ordering.residue: [concrete_id_same_id_ordering,
  per_id_issue_order_queues]`.

Generated auto-ID same-ID avoidance remains unchanged. This slice does not add
per-ID queues, scoreboards, response demux for concrete IDs, new public syntax,
or HDL behavior for previously valid sources.

## Validation

Focused gates:

```bash
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
perl -Iperl -c t/1437-axi-ial2-manager-capacity-status-generator.t
perl -Iperl -c t/1436-ial2-ppif-parser-cli.t
prove -Iperl t/1437-axi-ial2-manager-capacity-status-generator.t
prove -Iperl t/1436-ial2-ppif-parser-cli.t
```

Live probes:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
```

The direct two-read concrete-ID probe that was accepted in `.87` now rejects
with the same-ID reuse diagnostic above.

## Next Frontier

`IAL2-FEATURE-COMPLETENESS-FRONTIER.89` is the next selector. It should choose
the next AXI manager feature-completeness owner after this static validation,
using the remaining same-ID ordering and per-ID issue-order queue residue as
input.
