# IAL2 AHB Requester Single-BUSY Event-Cardinality Repair

Task-tree owner:
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.3`

Date: 2026-07-24

## Outcome

FSMGen now makes the shipped requester report
`busy_insertion.beats=single` exact at the bus-event boundary. A BUSY event
retires once, and only once, on a rising edge where:

```text
HGRANT && HREADY && HTRANS == 2'b01
```

If either qualifier is low, BUSY remains pending with stable address, control,
write data, beat index, and remaining count. When both qualifiers become high,
that one BUSY event retires and the same pending transfer is presented as
`SEQ`. BUSY never completes or consumes a data beat.

The repair changes only generated IAL1 timing for requesters that declare
`busy-before-beat`. Public syntax, ports, sources, report schema and values,
support identities, generated artifact names, module names, and base-requester
behavior are unchanged.

## Generated IAL1 Repair

`perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm` conditionally emits three pieces
for the BUSY-inserting requester:

```text
(priority ahb_busy_accept over ahb_request)

(rule ahb_busy_accept (& HGRANT HREADY (== HTRANS 2'b01))
  (set ahb_address_pending_q 1)
  (set HTRANS 2'b11))

(continue-when (& (! HREADY) (== HTRANS 2'b01)))
```

The existing no-grant loop gate holds the same BUSY presentation while grant is
low. The new ready/BUSY gate does the same while ready is low. On acceptance,
the rule reuses existing `ahb_address_pending_q` ownership to hand the unchanged
transfer to `SEQ`; no counter or other storage is added. Existing
`busy_inserted_q` remains the one-shot insertion marker.

The base requester does not emit `transfer_busy`, `busy_inserted_q`,
`ahb_busy_accept`, or the BUSY hold gate.

## Requester Runtime Proof

`t/1498-ial2-ahb-requester-busy-insert.t` keeps generated selector assertions
enabled and builds one generated HDL binary. The public harness runs three
scenarios:

| Scenario | Held clocks | Qualified BUSY events | Data beats |
|---|---:|---:|---:|
| continuously qualified | 0 | 1 | 4 |
| `HREADY=0` after first visible BUSY | 32 | 1 after release | 4 |
| `HGRANT=0` after first visible BUSY | 32 | 1 after release | 4 |

Every scenario reports five transfer-type episodes, one BUSY episode, exactly
one qualified BUSY event, the same resumed `SEQ`, and zero remaining beats.
The harness also rejects any BUSY data completion or change to the pending
address/control/data/counters.

## Generic, Alias, And Paired Preservation

The requester `.ahb` alias remains byte-identical to its `.ppif` source.
Paired generic and alias runtimes now count the embedded qualified BUSY events
directly:

| Regression | Surface | Commands | Qualified BUSY events | Data beats |
|---|---|---:|---:|---:|
| t/1513 | one-window `.ppif` | 1 | 1 | 4 |
| t/1514 | one-window `.ahb` | 1 | 1 | 4 |
| t/1515 | two-window `.ppif` | 2 | 2 | 8 |
| t/1516 | two-window `.ahb` | 2 | 2 | 8 |

Those proofs retain subordinate BUSY parking, window mapping, selected-child
storage, unselected-child non-interference, OKAY status, and zero remaining
beats. The one-window result remains `32'h44332211`; the two-window result
remains status/control `32'h44332211`/`32'h88776655`.

Requester-only generated HDL runs with assertions enabled. Paired aggregate
tests retain their pre-existing `--no-assert` boundary because assertion
enablement independently exposes overlapping default and mapped-decode output
selectors in the unchanged AHB interconnect. Proposed inactive task
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION` owns that separate
gap. Qualified BUSY cardinality is still checked explicitly in every paired
runtime.

## Preservation And Deferrals

No parser, public source, source kind, report field/value, support/capability
entry, generated artifact name, HDL module name, port, subordinate behavior,
interconnect behavior, AXI/APB behavior, direct seed, backend, or VHDL path
changes in this repair.

Multiple BUSY events, count syntax/reporting/state, runtime-selected insertion,
policy/random throttling, distinct local bus-BUSY status, larger or broader
bursts, optional AHB signals, managers, queues/outstanding transfers, the
separate interconnect selector gap, the separate general ISF output-priority
gap, and decision 0020 remain deferred/inactive.

## Rollback

Rollback removes the conditional `ahb_busy_accept` priority/rule and ready/BUSY
hold gate, restores the former transition-only requester/paired assertions, and
restores current documentation to the historical ten-qualified-edge
limitation. Public sources, reports, support accounting, and artifacts do not
change in either direction.
