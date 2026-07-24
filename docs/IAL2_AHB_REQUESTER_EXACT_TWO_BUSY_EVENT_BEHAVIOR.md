# IAL2 AHB Requester Exact-Two BUSY Event Behavior

Task-tree owner:
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.5`

Date: 2026-07-24

## Outcome

FSMGen ships an additive generic AHB requester that inserts exactly two
grant-and-ready-qualified `HTRANS=BUSY` events before one selected pending
`SEQ` transfer:

```text
ppif/ahb_requester_busy_insert_two.ppif
```

The source uses the existing AHB requester generator and the existing
IAL2-to-IAL1-to-IAL0-to-HDL pipeline. It is not a separate generator. Its
distinct public identity is:

```text
intent:        ahb_requester_busy_insert_two
source object: fsmgen-ahb-requester-busy-insert-two
actor/module:  amba_requester_busy_insert_two
IAL1:          amba_requester_busy_insert_two.isf
IAL0:          amba_requester_busy_insert_two.fsm
support id:    intent.ppif_ahb_requester_busy_insert_two
coverage:      ial2_ppif_ahb_requester_busy_insert_two_pipeline_cli
source kind:   ppif
```

The existing exact-one `.ppif`/`.ahb` requester sources and base requester
remain separate and retain their existing generated shape.

## Public Source Contract

The exact-two source adds one optional literal to the existing transfer block:

```text
(transfer
  (idle 2'b00)
  (busy 2'b01)
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready)
  (busy-before-beat 2)
  (busy-beats 2))
```

`busy-before-beat 2` selects the zero-based pending `SEQ` beat. `busy-beats 2`
requires exactly two rising events where:

```text
HGRANT && HREADY && HTRANS == 2'b01
```

Ready-low and grant-low clocks do not consume the count. The address, control,
write data, beat index, and remaining data-beat count stay stable for the whole
BUSY episode. Neither BUSY event completes a data beat or consumes a response.
After the second event, the same pending transfer resumes as `SEQ`.

The parser accepts only literal integer `2`. `busy-beats` requires
`busy-before-beat`, and the existing insertion point requires BUSY encoding
`2'b01`. Zero, one, larger values, symbols, expressions, missing prerequisites,
and duplicate clauses fail closed. Absence of `busy-beats` remains the
canonical exact-one source spelling.

## Generated IAL1 Ownership

Only the exact-two branch adds actor-owned storage:

```text
(var ahb_busy_remaining_q (width 2) (reset 0))
```

Command admission initializes it to zero. At the selected insertion point, the
transaction sets it to two before driving BUSY and sets the existing
`busy_inserted_q` one-shot. Initializing first prevents the first visible BUSY
edge from observing a zero count.

Two qualified-event rules retire the episode:

```text
(priority ahb_busy_accept over ahb_request)
(priority ahb_busy_continue over ahb_request)
(priority ahb_busy_accept over ahb_busy_continue)

(rule ahb_busy_continue
  (& HGRANT HREADY (== HTRANS 2'b01) (> ahb_busy_remaining_q 1))
  (set ahb_busy_remaining_q (- ahb_busy_remaining_q 1)))

(rule ahb_busy_accept
  (& HGRANT HREADY (== HTRANS 2'b01) (== ahb_busy_remaining_q 1))
  (set ahb_busy_remaining_q 0)
  (set ahb_address_pending_q 1)
  (set HTRANS 2'b11))
```

An outer `continue-when (== HTRANS 2'b01)` keeps the requester transaction from
entering its normal transfer/response path during the episode. The non-final
event only decrements the counter. The final event clears it and reuses existing
`ahb_address_pending_q` ownership to resume `SEQ`.

The counter is actor-owned rather than transaction-local because concurrent
rules must observe and update it. The final-over-nonfinal priority is explicit
because the current ISF conflict checker does not prove their `> 1` and `== 1`
guards disjoint. These are lowering details, not additions to the public
contract.

## Reports And Accounting

The new source reports:

```text
transfer.busy_beats                  = 2
busy_insertion.generated_behavior   = true
busy_insertion.htrans_busy_encoding = 2'b01
busy_insertion.before_beat          = 2
busy_insertion.beats                = 2
```

`busy_insertion.beats` is numeric for exact-two. Existing exact-one sources
still report the string `single`. The shared
`ahb_requester_busy_insert_support` residue is source-specific: exact-one names
the additive exact-two source, exact-two says two events ship, and both defer
counts beyond two, multiple insertion points, and policy/runtime/random
throttling.

This source moves the current support corpus to 315 protocol fixtures and 356
supported-smoke/strict-supported fixtures. The public AHB IAL2 inventory is 39
paths: twenty generic `.ppif` sources and nineteen `.ahb` aliases.

## Generated-HDL Proof

Focused `t/1521-ial2-ahb-requester-two-busy-insert.t` keeps generated selector
assertions enabled and compiles one generated requester. It runs three cases:

| Scenario | Held clocks | Qualified BUSY events | Data beats |
|---|---:|---:|---:|
| continuously qualified | 0 | 2 | 4 |
| `HREADY=0` after first visible BUSY | 32 | 2 after release | 4 |
| `HGRANT=0` after first visible BUSY | 32 | 2 after release | 4 |

Every case observes one contiguous BUSY transition episode, exactly two
qualified BUSY events, stable pending fields and counters, no BUSY data
completion, the same resumed `SEQ`, exactly four accepted data beats, and zero
remaining. The test also covers strict check, semantic JSON, schedule JSON,
review artifacts, `--verify-hdl`, support identity, malformed inputs, exact-one
preservation, and base-requester preservation.

## Use It

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert_two.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester_busy_insert_two.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_requester_busy_insert_two.ppif
./bin/fsmgen --quiet --outdir generated/ial2-ahb-requester-busy-insert-two ppif/ahb_requester_busy_insert_two.ppif
./bin/fsmgen --quiet --strict --verify-hdl ppif/ahb_requester_busy_insert_two.ppif
```

No matching exact-two `.ahb` alias ships in this slice. Use the generic `.ppif`
path above. Follow-on selector `.6` now chooses a byte-identical alias contract
at `ppif/ahb_requester_busy_insert_two.ahb`; it remains unshipped until `.7`
implements and support-accounts it. See
`docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md`.

## Explicit Deferrals

Literal counts beyond one/two, generalized count width, multiple insertion
points, runtime-selected count/point, policy/random throttling, distinct local
bus-BUSY status, the still-unimplemented selected exact-two `.ahb` alias,
paired exact-two compositions,
larger/broader bursts, optional AHB signals, managers, queues/outstanding
transfers, direct seeds/backends, verification-output generation, backend
variants, AXI/APB changes, VHDL, the separate interconnect selector repair, the
general ISF output-priority repair, and decision 0020 remain deferred/inactive.

## Rollback

Rollback removes the additive source/support/test and the conditional
`busy_beats` parser/report/counter branch together, restores the previous
support counts and AHB inventory, and leaves the exact-one requester repair and
all base requesters unchanged.
